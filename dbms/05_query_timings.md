# Query Execution Timings & Plan Analysis

Measured locally for Kalpa CP4 using the local schema and seed dataset. These are small-fixture execution times, not production capacity or end-to-end application latency.

## Environment and method

- Captured: 2026-11-21T10:32:49+05:30
- Server: `PostgreSQL 18.6 (Homebrew) on aarch64-apple-darwin27.0.0, compiled by Apple clang version 21.0.0 (clang-2100.3.34.2), 64-bit`
- Client: `psql (PostgreSQL) 18.6 (Homebrew)`
- OS: Darwin 27.0.0; macOS 27.0.1; architecture arm64
- Hardware: Mac16,1; CPU Apple M4; logical CPUs 10; RAM 16 GiB
- PostgreSQL settings: `jit=on; max_parallel_workers_per_gather=2; shared_buffers=16384 × 8kB; work_mem=4096 × kB`
- SHA-256 `03_schema.sql`: `acc91063aff409e977c8fece3321ff12c3631a1c828d0a0e85ce9686fb1bdcb0`
- SHA-256 `03_seed_data.sql`: `f4c43f761d503aa4d414286466bd6ca5c08fb25d0deea2f1febbbfbad165d01d`
- SHA-256 `04_queries.sql`: `bfc68b5add2386e7ca47d1d37232864faee4cb72e122a3e0055cef3c850530b1`
- SHA-256 `benchmark.py`: `531d86cae0527a97992536718f1ea22077defbc367fdf35035b352dc23e386ce`
- Reproduce: `./dbms/run_benchmark.sh <database> 3`; connection via normal `PGHOST`, `PGPORT`, `PGUSER` settings. Initialise a fresh database first; the runner never seeds or resets data.
- 3 sequential samples per workload, one new psql connection per sample; no artificial warm-up, forced index scans, or planner overrides. Cache warmth can vary. Planning and connection overhead are excluded from the reported PostgreSQL **Execution Time**.
- Every sample uses `BEGIN; EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE); ROLLBACK;`. W10 benchmarks its UPDATE and trigger work inside this transaction; COMMIT latency is excluded.
- W03/W09 primary runs measure insert paths; supplemental runs prepare an existing row inside each transaction, then measure the conflict-update path. Setup time is excluded.
- Row counts and ordered content digests of all seven tables matched before and after. Run against an isolated database without concurrent writers.

| Table | Rows |
|:---|---:|
| `users` | 50 |
| `role_permissions` | 3 |
| `projects` | 8 |
| `project_collaborators` | 25 |
| `canvas_elements` | 41 |
| `comment_pins` | 7 |
| `comment_replies` | 8 |

## Primary workload timings

| Query | Description | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Observed nodes (run 1) |
|:---|:---|---:|---:|---:|---:|:---|
| R01 | User authentication & profile lookup by email | 0.015 | 0.016 | 0.015 | 0.015 | Index Scan |
| R02 | User profile & account details lookup by ID | 0.013 | 0.014 | 0.013 | 0.013 | Index Scan |
| R03 | User dashboard — owned projects with collaborator count | 0.058 | 0.055 | 0.056 | 0.056 | Sort / GroupAggregate / Nested Loop Left Join / Index Scan / Bitmap Heap Scan / Bitmap Index Scan |
| R04 | User dashboard — shared projects with role and owner details | 0.061 | 0.053 | 0.060 | 0.058 | Sort / Nested Loop / Hash Join / Seq Scan / Bitmap Heap Scan / Bitmap Index Scan / Index Scan |
| R05 | Active canvas initialization — project settings & owner metadata | 0.023 | 0.024 | 0.022 | 0.023 | Nested Loop / Index Scan |
| R06 | Access control check — verify user role & permissions on canvas | 0.022 | 0.020 | 0.020 | 0.021 | Nested Loop / Index Scan |
| R07 | Collaborator roster — list project members with role descriptions | 0.059 | 0.052 | 0.058 | 0.056 | Sort / Nested Loop / Hash Join / Seq Scan / Bitmap Heap Scan / Bitmap Index Scan / Index Scan |
| R08 | Canvas load — fetch elements sorted by z-index for rendering | 0.058 | 0.057 | 0.054 | 0.056 | Sort / Nested Loop Left Join / Seq Scan / Index Scan |
| R09 | Element inspector — retrieve single canvas shape by ID | 0.024 | 0.024 | 0.027 | 0.025 | Nested Loop Left Join / Seq Scan / Index Scan |
| R10 | Layer management — fetch maximum z-index for new element stacking | 0.028 | 0.024 | 0.023 | 0.025 | Aggregate / Seq Scan |
| R11 | Filter canvas elements by shape type category | 0.043 | 0.040 | 0.043 | 0.042 | Sort / Nested Loop Left Join / Seq Scan / Index Scan |
| R12 | Search custom attributes in JSONB (locked canvas shapes) | 0.030 | 0.028 | 0.028 | 0.029 | Nested Loop Left Join / Seq Scan / Index Scan |
| R13 | Pinned comments overlay — fetch pins with reply counts | 0.080 | 0.077 | 0.076 | 0.078 | Sort / GroupAggregate / Hash Right Join / Seq Scan / Bitmap Heap Scan / Bitmap Index Scan |
| R14 | Comment thread history — fetch replies for thread chronologically | 0.047 | 0.044 | 0.047 | 0.046 | Sort / Hash Right Join / Seq Scan / Bitmap Heap Scan / Bitmap Index Scan |
| R15 | Project status header — count unresolved active comments | 0.027 | 0.024 | 0.026 | 0.026 | Aggregate / Bitmap Heap Scan / Bitmap Index Scan |
| R16 | Dashboard search — filter accessible projects by title substring | 0.053 | 0.049 | 0.045 | 0.049 | Sort / Nested Loop / Seq Scan / Bitmap Heap Scan / Bitmap Index Scan / Index Scan |
| R17 | Project analytics — aggregate elements by shape type and dimension stats | 0.060 | 0.055 | 0.062 | 0.059 | Sort / GroupAggregate / Seq Scan |
| R18 | Recent canvas elements with original creator details | 0.048 | 0.049 | 0.047 | 0.048 | Sort / Nested Loop Left Join / Seq Scan / Index Scan |
| A01 | Spatial Viewport Culling (transformed axis-aligned bounds) | 0.100 | 0.102 | 0.099 | 0.100 | Sort / Index Scan |
| A02 | Contributor Leaderboard using Window Function (DENSE_RANK) | 0.104 | 0.096 | 0.099 | 0.100 | Sort / WindowAgg / GroupAggregate / Nested Loop / Seq Scan / Index Scan |
| A03 | Canvas Layering Gap Analysis using LAG() / LEAD() | 0.051 | 0.056 | 0.050 | 0.052 | WindowAgg / Sort / Seq Scan |
| A04 | Thread Discussion Hierarchy using JSON Aggregation | 0.113 | 0.103 | 0.109 | 0.108 | Sort / GroupAggregate / Nested Loop Left Join / Hash Right Join / Seq Scan / Bitmap Heap Scan / Bitmap Index Scan / Index Scan |
| W01 | Register / create new user account | 0.125 | 0.100 | 0.106 | 0.110 | Insert |
| W02 | Create new canvas project with owner synchronization | 1.688 | 1.261 | 1.295 | 1.415 | Insert |
| W03 | Add or update collaborator role on project | 1.161 | 1.148 | 1.029 | 1.113 | Insert |
| W04 | Persist newly drawn canvas element | 0.761 | 0.444 | 0.380 | 0.528 | Insert |
| W05 | Update element position, dimensions & style (drag flush) | 0.647 | 0.597 | 0.638 | 0.627 | Update / Seq Scan |
| W06 | Delete canvas element by ID | 0.055 | 0.050 | 0.048 | 0.051 | Delete / Seq Scan |
| W07 | Create new pinned comment thread | 0.373 | 0.362 | 0.346 | 0.360 | Insert |
| W08 | Update comment pin status (resolve discussion pin) | 0.080 | 0.073 | 0.097 | 0.083 | Update / Index Scan |
| W09 | Real-time Liveblocks Debounce Upsert | 0.437 | 0.461 | 0.424 | 0.441 | Insert |
| W10 | Atomic Project Ownership Transfer Transaction | 1.278 | 1.219 | 1.928 | 1.475 | Update / Index Scan |

## Supplemental conflict-update timings

| Query | Description | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Observed nodes (run 1) |
|:---|:---|---:|---:|---:|---:|:---|
| W03 update | Existing-row conflict update (setup excluded) | 0.059 | 0.055 | 0.055 | 0.056 | Insert |
| W09 update | Existing-row conflict update (setup excluded) | 0.065 | 0.057 | 0.079 | 0.067 | Insert |

## Interpretation and limits

- Scan choices are observed from the actual plans; sequential scans are reasonable for these small tables. An available index is not evidence that the planner used it.
- A01 filters conservative, transformed bounding rectangles including scaling strokes. Bounding-box intersection may include empty corners around rotated shapes. It is not a spatial index or exact path hit test.
- R18 lists current element state and original creators, not historical edits or last-editor identity.
- W03 invokes the collaborator protection trigger; W02/W10 invoke owner synchronization. Raw plans include trigger timing where applicable.
- These measurements include constraints and executed triggers, but do not establish concurrent application correctness, network performance, Liveblocks synchronization, or production scalability.
- Raw plans: [plans/](plans/). W03/W09 files also contain the supplemental update runs. Re-run the benchmark after schema/query changes.
