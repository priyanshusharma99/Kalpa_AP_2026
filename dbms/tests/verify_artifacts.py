#!/usr/bin/env python3
"""Check that CP4 report/SQL/plans and CP2 diagram/source agree (no DB needed)."""
from decimal import Decimal, ROUND_HALF_UP
import hashlib
import importlib.util
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('benchmark', ROOT / 'benchmark.py')
benchmark = importlib.util.module_from_spec(spec)
spec.loader.exec_module(benchmark)
report = (ROOT / '05_query_timings.md').read_text()
rows = {}
for line in report.splitlines():
    cells = [c.strip() for c in line.split('|')][1:-1]
    if cells and re.fullmatch(r'[RAW]\d{2}(?: update)?', cells[0]):
        rows[cells[0]] = cells


def normalise(sql):
    return re.sub(r'\s+', ' ', re.sub(r'--[^\n]*', '', sql)).strip().rstrip(';')


for qid, description, sql in benchmark.workloads():
    text = (ROOT / 'plans' / f'{qid}.txt').read_text()
    captured_sql = text.split('SQL:\n', 1)[1].split('--- RUN', 1)[0]
    assert normalise(sql) == normalise(captured_sql), qid + ' SQL mismatch'
    sections = text.split('=== SUPPLEMENTAL CONFLICT UPDATE PATH ===')
    for i, section in enumerate(sections):
        key = qid + (' update' if i else '')
        times = [Decimal(t) for t in re.findall(r'Execution Time:\s*([\d.]+) ms', section)]
        row = rows[key]
        assert times == list(map(Decimal, row[2:-2])), key + ' timings mismatch'
        assert len(times) >= 1
        avg = (sum(times) / len(times)).quantize(Decimal('.001'), rounding=ROUND_HALF_UP)
        assert avg == Decimal(row[-2]), key + ' average mismatch'
        if i:
            assert len(re.findall(r'Conflicting Tuples: 1', section)) == len(times), key + ' missing conflicts'
    assert len(sections) == (2 if qid in ('W03','W09') else 1)
assert len(rows) == 34
for filename in ('03_schema.sql','03_seed_data.sql','04_queries.sql','benchmark.py'):
    digest = hashlib.sha256((ROOT / filename).read_bytes()).hexdigest()
    assert f'`{filename}`: `{digest}`' in report, filename + ' stale source hash'

svg = (ROOT / '02_er_diagram.svg').read_text()
ET.fromstring(svg)
for table, body in re.findall(r'CREATE TABLE (\w+) \((.*?)\n\);', (ROOT / '03_schema.sql').read_text(), re.S):
    assert f'>{table}</text>' in svg, table + ' missing from ER diagram'
    for col in re.findall(r'^\s*(\w+) (?:VARCHAR|NUMERIC|TIMESTAMPTZ|BOOLEAN|JSONB|TEXT|INT)', body, re.M):
        assert f'>{col}</text>' in svg, col + ' missing from ER diagram'
for n in range(1,11):
    assert f'>L{n}</text>' in svg, 'Missing relationship'
assert len(list((ROOT / 'plans').glob('*.txt'))) == 32
print('PASS: 32 workload SQL blocks, 34 timing rows, all averages/source hashes and 7-entity/10-FK SVG structure agree.')
