# Query Execution Timings & Plan Analysis

PostgreSQL database benchmark results for the **Kalpa** collaborative design platform. Every query from `dbms/04_queries.sql` was executed with `EXPLAIN (ANALYZE, BUFFERS)` for 3 consecutive iterations. Write operations were wrapped within `BEGIN; ... ROLLBACK;` transaction blocks to maintain consistent database state across iterations.

## Summary Timings Table (based on mock data).

| Query | Type | What it does | Run 1 (ms) | Run 2 (ms) | Run 3 (ms) | Average (ms) | Scan / Execution Node |
|:---|:---|:---|---:|---:|---:|---:|:---|
| R01 | READ | User authentication & profile lookup by email | 0.079 | 0.072 | 0.040 | 0.064 | Seq Scan |
| R02 | READ | User profile & account details lookup by ID | 0.063 | 0.052 | 0.066 | 0.060 | Seq Scan |
| R03 | READ | User dashboard — owned projects with collaborator count | 0.232 | 0.191 | 0.189 | 0.204 | Seq Scan |
| R04 | READ | User dashboard — shared projects with role and owner details | 0.204 | 0.169 | 0.205 | 0.193 | Hash Join |
| R05 | READ | Active canvas initialization — project settings & owner metadata | 0.097 | 0.082 | 0.104 | 0.094 | Hash Join |
| R06 | READ | Access control check — verify user role & permissions on canvas | 0.055 | 0.071 | 0.065 | 0.064 | Nested Loop |
| R07 | READ | Collaborator roster — list project members with role descriptions | 0.192 | 0.196 | 0.167 | 0.185 | Hash Join |
| R08 | READ | Canvas load — fetch elements sorted by z-index for rendering | 0.245 | 0.231 | 0.235 | 0.237 | Index Scan |
| R09 | READ | Element inspector — retrieve single canvas shape by ID | 0.076 | 0.061 | 0.075 | 0.071 | Index Scan |
| R10 | READ | Layer management — fetch maximum z-index for new element stacking | 0.125 | 0.103 | 0.103 | 0.110 | Index Only Scan |
| R11 | READ | Filter canvas elements by shape type category | 0.219 | 0.219 | 0.183 | 0.207 | Index Scan |
| R12 | READ | Search custom attributes in JSONB (locked canvas shapes) | 0.188 | 0.194 | 0.149 | 0.177 | Index Scan |
| R13 | READ | Pinned comments overlay — fetch pins with reply counts | 0.264 | 0.248 | 0.125 | 0.212 | Seq Scan |
| R14 | READ | Comment thread history — fetch replies for thread chronologically | 0.139 | 0.113 | 0.154 | 0.135 | Seq Scan |
| R15 | READ | Project status header — count unresolved active comments | 0.080 | 0.061 | 0.070 | 0.070 | Seq Scan |
| R16 | READ | Dashboard search — filter accessible projects by title substring | 0.250 | 0.174 | 0.154 | 0.193 | Hash Join |
| R17 | READ | Project analytics — aggregate elements by shape type and dimension stats | 0.225 | 0.227 | 0.194 | 0.215 | Index Scan |
| R18 | READ | Audit trail — recent canvas modifications and editor details | 0.231 | 0.194 | 0.199 | 0.208 | Index Scan |
| A01 | READ | Spatial Viewport Culling (2D Bounding Box Intersection) | 0.041 | 0.031 | 0.074 | 0.049 | Index Scan |
| A02 | READ | Contributor Leaderboard using Window Function (DENSE_RANK) | 0.120 | 0.121 | 0.228 | 0.156 | WindowAgg / Index Scan |
| A03 | READ | Canvas Layering Gap Analysis using LAG() / LEAD() | 0.053 | 0.086 | 0.081 | 0.073 | WindowAgg / Index Scan |
| A04 | READ | Thread Discussion Hierarchy using JSON Aggregation | 0.119 | 0.200 | 0.111 | 0.143 | GroupAggregate / Index Scan |
| W01 | WRITE | Register / create new user account | 0.472 | 0.411 | 0.373 | 0.419 | Insert |
| W02 | WRITE | Create new canvas project with owner synchronization | 5.009 | 5.244 | 4.265 | 4.839 | Insert |
| W03 | WRITE | Add or update collaborator role on project | 2.051 | 2.891 | 2.489 | 2.477 | Insert |
| W04 | WRITE | Persist newly drawn canvas element | 1.257 | 1.056 | 0.494 | 0.936 | Insert |
| W05 | WRITE | Update element position, dimensions & style (drag flush) | 0.156 | 0.128 | 0.148 | 0.144 | Index Scan |
| W06 | WRITE | Delete canvas element by ID | 0.295 | 0.150 | 0.197 | 0.214 | Index Scan |
| W07 | WRITE | Create new pinned comment thread | 0.982 | 0.993 | 0.646 | 0.874 | Insert |
| W08 | WRITE | Update comment pin status (resolve discussion pin) | 0.088 | 0.166 | 0.081 | 0.112 | Seq Scan |
| W09 | WRITE | Real-time Liveblocks Debounce Upsert | 0.555 | 0.443 | 0.441 | 0.480 | Insert (Upsert) |
| W10 | WRITE | Atomic Project Ownership Transfer Transaction | 1.280 | 1.143 | 1.630 | 1.351 | Index Scan (Trigger Sync) |

---

## Performance & Execution Plan Observations

1. **Direct Point Lookups (R01, R02, R06, R09):**
   - Single-row lookups on `users`, `projects`, and `canvas_elements` execute in under **0.08 ms**. With the table data fitting into memory pages, PostgreSQL retrieves records with minimal shared buffer hits (`shared hit=1` to `4`).

2. **Canvas Rendering Pipeline (R08, R10, R11):**
   - The canvas loading queries (`R08`, `R11`) use the `idx_elements_z_index` index to filter elements by project and order them by stacking order for Fabric.js rendering, finishing in ~**0.20 – 0.25 ms**.

3. **Custom Attributes & JSONB Search (R12):**
   - Filtering on canvas shape metadata in `custom_properties` (e.g. checking for locked objects) executes in ~**0.18 ms**, leveraging index scans and fast JSON containment evaluation.

4. **Dashboard Aggregations & Joins (R03, R04, R07, R13, R16):**
   - Queries joining `projects`, `project_collaborators`, `users`, and `role_permissions` execute in **0.15 – 0.25 ms** using `Hash Join` and `Nested Loop` execution paths.

5. **Advanced Analytical & Spatial Workloads (A01 – A04):**
   - **Spatial Viewport Culling (`A01`):** Uses `idx_elements_z_index` to cull off-screen shapes with 2D axis-aligned bounding box checks in **0.049 ms**, eliminating unnecessary DOM/Canvas rendering overhead.
   - **Leaderboard Window Aggregation (`A02`):** Computes per-contributor element creation ranks via `DENSE_RANK() OVER (PARTITION BY ...)` in **0.156 ms**, combining index scans and `WindowAgg`.
   - **Layering Gap Analysis (`A03`):** Uses `LAG()` and `LEAD()` to inspect z-index defragmentation in **0.073 ms**, scanning the composite z-index index directly.
   - **Thread Discussion Hierarchy (`A04`):** Aggregates comment pins and chronological reply trees into nested JSON payloads in a single roundtrip (**0.143 ms**) using `json_agg` and `json_build_object`.

6. **Write Operations & Constraints (W01 – W10):**
   - Coordinate updates (`W05`), comment status updates (`W08`), and shape deletions (`W06`) execute rapidly in **0.10 – 0.25 ms**.
   - Creating a project (`W02`) and adding collaborators (`W03`) take ~**2.5 – 5.0 ms** due to foreign key validations and trigger execution (`sync_project_owner_collaborator`) which enforces single-owner invariants.
   - Inserting new canvas elements (`W04`) takes ~**0.9 ms**, validating coordinate, dimension, and opacity check constraints.
   - Real-time Liveblocks debounce upsert (`W09`) handles concurrent insert/update conflict resolution idempotently via `ON CONFLICT (element_id) DO UPDATE` in **0.480 ms**.
   - Atomic ownership transfer (`W10`) updates the project owner and automatically triggers demotion of the prior owner to editor within a single transaction in **1.351 ms**.

---

*Raw plans for all 32 queries are located in [`dbms/plans/`](./plans/).*
