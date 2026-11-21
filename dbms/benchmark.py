#!/usr/bin/env python3
"""Reproduce CP4 plans and report. All workload writes are rolled back."""
import argparse
from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP
import hashlib
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import tempfile
from zoneinfo import ZoneInfo

ROOT = Path(__file__).resolve().parent
TABLES = {
    'users': 'user_id', 'role_permissions': 'role_name', 'projects': 'project_id',
    'project_collaborators': 'project_id, user_id', 'canvas_elements': 'element_id',
    'comment_pins': 'comment_id', 'comment_replies': 'reply_id',
}


def workloads():
    source = (ROOT / '04_queries.sql').read_text()
    matches = list(re.finditer(r'^-- ([RAW]\d{2}):[^\n]*\n', source, re.M))
    result = []
    for i, match in enumerate(matches):
        block = source[match.end():matches[i + 1].start() if i + 1 < len(matches) else len(source)]
        description = next(line[3:] for line in block.splitlines() if line.startswith('-- ') and '=' not in line)
        sql = re.sub(r'--[^\n]*', '', block).strip()
        if match[1] == 'W10':
            sql = re.sub(r'^BEGIN;\s*', '', sql)
            sql = re.sub(r'\s*COMMIT;\s*$', '', sql)
        result.append((match[1], description, sql))
    expected = {f'R{i:02}' for i in range(1, 19)} | {f'A{i:02}' for i in range(1, 5)} | {f'W{i:02}' for i in range(1, 11)}
    if {q[0] for q in result} != expected or len(result) != 32:
        raise ValueError('Expected exactly the 32 documented workloads')
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('database', nargs='?', default='kalpa_db')
    parser.add_argument('runs', nargs='?', type=int, default=3)
    args = parser.parse_args()
    if args.runs < 1:
        parser.error('runs must be a positive integer')
    psql = shutil.which('psql')
    if not psql:
        parser.error('psql is required in PATH')

    def execute(sql):
        run = subprocess.run([psql, '-X', '-q', '-A', '-t', '-v', 'ON_ERROR_STOP=1',
                              '--dbname', args.database], input=sql, text=True, capture_output=True)
        if run.returncode:
            raise RuntimeError(run.stderr.strip())
        return run.stdout.strip()

    def snapshot():
        return {table: json.loads(execute(
            f"SELECT json_build_object('rows', COUNT(*), 'digest', "
            f"md5(COALESCE(json_agg(t ORDER BY {key})::text, '[]'))) FROM {table} t;"))
            for table, key in TABLES.items()}

    queries = workloads()
    before = snapshot()  # Also fails immediately if schema/connection is missing.
    checks = execute("""SELECT
        EXISTS(SELECT 1 FROM projects WHERE project_id='proj_001' AND owner_id='usr_001')
        AND EXISTS(SELECT 1 FROM canvas_elements WHERE element_id='elem_0026')
        AND EXISTS(SELECT 1 FROM canvas_elements WHERE element_id='elem_0050')
        AND EXISTS(SELECT 1 FROM users WHERE user_id='usr_045')
        AND EXISTS(SELECT 1 FROM comment_pins WHERE comment_id='comm_001' AND status='open')
        AND NOT EXISTS(SELECT 1 FROM users WHERE user_id='usr_benchmark' OR user_email='benchmark@kalpa.app')
        AND NOT EXISTS(SELECT 1 FROM projects WHERE project_id='proj_benchmark')
        AND NOT EXISTS(SELECT 1 FROM project_collaborators WHERE project_id='proj_001' AND user_id='usr_045')
        AND NOT EXISTS(SELECT 1 FROM canvas_elements WHERE element_id IN ('elem_benchmark','elem_upsert_01'))
        AND NOT EXISTS(SELECT 1 FROM comment_pins WHERE comment_id='comm_benchmark');""")
    if checks != 't':
        raise ValueError('Benchmark fixtures changed. Use a fresh database with 03_schema.sql + 03_seed_data.sql; no data was reset.')
    version = execute('SELECT version();')
    settings = execute("SELECT name || '=' || setting || CASE WHEN unit IS NULL THEN '' ELSE ' × ' || unit END FROM pg_settings WHERE name IN ('shared_buffers','work_mem','jit','max_parallel_workers_per_gather') ORDER BY name;")

    def measure(sql, setup=''):
        plans, times = [], []
        for _ in range(args.runs):
            plan = execute('BEGIN;\nSET LOCAL statement_timeout = \'30s\';\n' + setup +
                           '\nEXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE, FORMAT TEXT)\n' + sql + '\nROLLBACK;')
            values = re.findall(r'Execution Time:\s*([\d.]+) ms', plan)
            if len(values) != 1:
                raise ValueError('Expected one successful EXPLAIN execution')
            plans.append(plan)
            times.append(Decimal(values[0]))
        return plans, times

    def nodes(plan):
        found = re.findall(r'^\s*(?:->\s*)?((?:Parallel )?(?:Index Only Scan|Index Scan|Seq Scan|Bitmap Heap Scan|Bitmap Index Scan|Hash Join|Hash Left Join|Hash Right Join|Nested Loop(?: Left Join)?|Merge Join|Merge Left Join|WindowAgg|GroupAggregate|HashAggregate|Aggregate|Sort|Insert on|Update on|Delete on))\b', plan, re.M)
        return ' / '.join(dict.fromkeys(node.removesuffix(' on') for node in found)) or 'See raw plan'

    def avg(times):
        return (sum(times) / len(times)).quantize(Decimal('.001'), rounding=ROUND_HALF_UP)

    results, extra = [], []
    # Stage output: a failed run must not replace the existing report or plans.
    with tempfile.TemporaryDirectory(prefix='kalpa-benchmark-') as temporary:
        staged = Path(temporary)
        for qid, description, sql in queries:
            plans, times = measure(sql)
            text = f'Query ID: {qid}\nType: {"WRITE" if qid.startswith("W") else "READ"}\nDescription: {description}\n\nSQL:\n{sql}\n\n'
            for i, plan in enumerate(plans, 1):
                text += f'--- RUN {i} ---\nBEGIN (rolled back after EXPLAIN)\n{plan}\nROLLBACK\n\n'
            results.append((qid, description, times, nodes(plans[0])))
            if qid in ('W03', 'W09'):
                # Insert a deliberately different old state inside the SAME transaction.
                setup = sql
                if qid == 'W03':
                    setup += "\nUPDATE project_collaborators SET role_name='viewer' WHERE project_id='proj_001' AND user_id='usr_045';"
                else:
                    setup += "\nUPDATE canvas_elements SET shape_type='text', rotation=45, scale_x=2, opacity=0.5, stroke_color='#FFFFFF', z_index=99, text_content='old', custom_properties='{}'::jsonb WHERE element_id='elem_upsert_01';"
                update_plans, update_times = measure(sql, setup)
                text += '=== SUPPLEMENTAL CONFLICT UPDATE PATH ===\nSetup (inside each rolled-back transaction):\n' + setup + '\n\n'
                for i, plan in enumerate(update_plans, 1):
                    text += f'--- UPDATE RUN {i} ---\n{plan}\nROLLBACK\n\n'
                if not all('Conflicting Tuples: 1' in p for p in update_plans):
                    raise ValueError(f'{qid}: conflict branch was not exercised')
                extra.append((qid + ' update', 'Existing-row conflict update (setup excluded)', update_times, nodes(update_plans[0])))
            (staged / f'{qid}.txt').write_text(text.rstrip() + '\n')
            print(f'{qid}: {avg(times)} ms | {nodes(plans[0])}', flush=True)
        after = snapshot()
        if before != after:
            raise RuntimeError('Database contents changed during benchmark; output not published')

        def sysinfo(key):
            try:
                value = subprocess.check_output(['sysctl', '-n', key], text=True, stderr=subprocess.DEVNULL).strip()
                return value or 'unavailable'
            except (OSError, subprocess.CalledProcessError):
                return 'unavailable'

        memory = sysinfo('hw.memsize')
        if memory.isdigit():
            memory = f'{int(memory) / 1024**3:g} GiB'
        report = '# Query Execution Timings & Plan Analysis\n\n'
        report += 'Measured locally for Kalpa CP4 using the local schema and seed dataset. These are small-fixture execution times, not production capacity or end-to-end application latency.\n\n'
        report += '## Environment and method\n\n'
        report += f'- Captured: {datetime.now(ZoneInfo("Asia/Kolkata")).isoformat(timespec="seconds")}\n'
        report += f'- Server: `{version}`\n- Client: `{subprocess.check_output([psql, "--version"], text=True).strip()}`\n'
        report += f'- OS: {platform.system()} {platform.release()}; macOS {platform.mac_ver()[0] or "n/a"}; architecture {platform.machine()}\n'
        report += f'- Hardware: {sysinfo("hw.model")}; CPU {sysinfo("machdep.cpu.brand_string")}; logical CPUs {os.cpu_count()}; RAM {memory}\n'
        report += f'- PostgreSQL settings: `{settings.replace(chr(10), "; ")}`\n'
        for filename in ('03_schema.sql', '03_seed_data.sql', '04_queries.sql', 'benchmark.py'):
            report += f'- SHA-256 `{filename}`: `{hashlib.sha256((ROOT / filename).read_bytes()).hexdigest()}`\n'
        report += f'- Reproduce: `./dbms/run_benchmark.sh <database> {args.runs}`; connection via normal `PGHOST`, `PGPORT`, `PGUSER` settings. Initialise a fresh database first; the runner never seeds or resets data.\n'
        report += f'- {args.runs} sequential samples per workload, one new psql connection per sample; no artificial warm-up, forced index scans, or planner overrides. Cache warmth can vary. Planning and connection overhead are excluded from the reported PostgreSQL **Execution Time**.\n'
        report += '- Every sample uses `BEGIN; EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE); ROLLBACK;`. W10 benchmarks its UPDATE and trigger work inside this transaction; COMMIT latency is excluded.\n'
        report += '- W03/W09 primary runs measure insert paths; supplemental runs prepare an existing row inside each transaction, then measure the conflict-update path. Setup time is excluded.\n'
        report += '- Row counts and ordered content digests of all seven tables matched before and after. Run against an isolated database without concurrent writers.\n\n'
        report += '| Table | Rows |\n|:---|---:|\n'
        for table, value in before.items():
            report += f'| `{table}` | {value["rows"]} |\n'

        def table(rows):
            header = '| Query | Description | ' + ' | '.join(f'Run {i} (ms)' for i in range(1, args.runs + 1)) + ' | Average (ms) | Observed nodes (run 1) |\n'
            header += '|:---|:---|' + '---:|' * (args.runs + 1) + ':---|\n'
            for qid, description, times, node in rows:
                header += f'| {qid} | {description} | ' + ' | '.join(map(str, times)) + f' | {avg(times)} | {node} |\n'
            return header
        report += '\n## Primary workload timings\n\n' + table(results)
        report += '\n## Supplemental conflict-update timings\n\n' + table(extra)
        report += '\n## Interpretation and limits\n\n'
        report += '- Scan choices are observed from the actual plans; sequential scans are reasonable for these small tables. An available index is not evidence that the planner used it.\n'
        report += '- A01 filters conservative, transformed bounding rectangles including scaling strokes. Bounding-box intersection may include empty corners around rotated shapes. It is not a spatial index or exact path hit test.\n'
        report += '- R18 lists current element state and original creators, not historical edits or last-editor identity.\n'
        report += '- W03 invokes the collaborator protection trigger; W02/W10 invoke owner synchronization. Raw plans include trigger timing where applicable.\n'
        report += '- These measurements include constraints and executed triggers, but do not establish concurrent application correctness, network performance, Liveblocks synchronization, or production scalability.\n'
        report += '- Raw plans: [plans/](plans/). W03/W09 files also contain the supplemental update runs. Re-run the benchmark after schema/query changes.\n'
        (staged / 'report.md').write_text(report)
        (ROOT / 'plans').mkdir(exist_ok=True)
        for qid, *_ in queries:
            os.replace(staged / f'{qid}.txt', ROOT / 'plans' / f'{qid}.txt')
        os.replace(staged / 'report.md', ROOT / '05_query_timings.md')
    print(f'Completed {len(results)} workloads + {len(extra)} conflict paths; all table contents unchanged.')


if __name__ == '__main__':
    try:
        main()
    except (ValueError, RuntimeError) as error:
        raise SystemExit(f'Benchmark failed: {error}') from error
