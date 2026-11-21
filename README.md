# Kalpa — Advanced Programming DBMS Project (2026)

**Project Name:** Kalpa (Real-Time Collaborative Design Platform / Figma Clone)  
**Main Repository:** [priyanshusharma99/Kalpa](https://github.com/priyanshusharma99/Kalpa.git)  
**AP Milestone Repository:** [priyanshusharma99/Kalpa_AP_2026](https://github.com/priyanshusharma99/Kalpa_AP_2026.git)  
**Team ID:** T0013  
**Team Members:**
- **Priyanshu Sharma (Lead)** — `2501010358`
- **Manjeet Lodha** — `2501010259`
- **Anurag Sonawane** — `2501010561`
- **Srijal Srivastava** — `2501010457`

**Mentor:** Satyaki

---

## 1. System Overview & Architecture

**Kalpa** is a real-time collaborative vector graphics and design tool inspired by Figma. Multiple team members can concurrently work on shared design canvases, create and manipulate vector shapes, draw freehand, upload images, leave pinned comments on canvas coordinates, and manage granular team permissions.

### Dual Storage Architecture
- **PostgreSQL (Authoritative Relational Store):** Stores persistent records including users, projects, role-based access control, canvas shapes, comment pins, discussion replies, and current element timestamps. Enforces strict relational integrity, check constraints, and trigger-based invariants.
- **Liveblocks (Ephemeral Real-Time Engine):** Coordinates low-latency WebSocket synchronization for live user cursors, active dragging states, and floating emoji reactions. The persistence design uses save/debounce flushes into PostgreSQL; this milestone repository provides SQL deliverables, not an implemented application-to-PostgreSQL adapter.

---

## 2. Checkpoints & Milestones

| Checkpoint | Status | File Deliverables | Description |
| :--- | :---: | :--- | :--- |
| **CP1** | Completed | [`dbms/01_normalization.md`](dbms/01_normalization.md) | Normalization from UNF through BCNF, stated functional dependencies and a short lossless-join/dependency-preservation proof. |
| **CP2** | Completed | [`dbms/02_er_diagram.png`](dbms/02_er_diagram.png)<br>[`dbms/03_schema.sql`](dbms/03_schema.sql)<br>[`dbms/03_seed_data.sql`](dbms/03_seed_data.sql) | Relational ER diagram, PostgreSQL DDL schema, tables, foreign keys, constraints, triggers, and comprehensive seed data for 50 users. |
| **CP3** | Completed | [`dbms/04_queries.sql`](dbms/04_queries.sql)<br>[`dbms/queries.sql`](dbms/queries.sql)<br>[`queries.sql`](queries.sql) | Comprehensive SQL queries covering authentication, projects, RBAC, spatial viewport culling, comments, analytics, and DML state flushes. |
| **CP4** | Completed | [`dbms/05_query_timings.md`](dbms/05_query_timings.md)<br>[`dbms/plans/`](dbms/plans/)<br>[`dbms/run_benchmark.sh`](dbms/run_benchmark.sh) | Query execution timings (3-iteration benchmark averages across all 32 queries), raw PostgreSQL plan logs (`EXPLAIN (ANALYZE, BUFFERS)`), and benchmark runner. |

---

## 3. Workload Queries Catalog (`dbms/04_queries.sql`)

The suite contains **32 workloads**: R01–R18 (reads), A01–A04 (advanced reads), and W01–W10 (writes). It covers profiles, dashboards, permissions, canvas hydration/filtering, comments, current element activity, transformed viewport bounds, window functions, JSON aggregation, complete element snapshots and ownership transfers.

Current measured timings, hardware, server settings, source hashes and per-run results are generated in [`dbms/05_query_timings.md`](dbms/05_query_timings.md). Each of the 32 raw plan files in [`dbms/plans/`](dbms/plans/) corresponds to the current workload SQL. W03 and W09 also include separate conflict-update measurements.

R18 reports original creators and current timestamps; no historical audit log is implemented. Geometry and persistence assumptions are documented in [CP1](dbms/01_normalization.md#jsonb-and-geometry-scope).

---

## 4. Query Execution Guide

To initialize the database and run the complete query suite against PostgreSQL:

Use an empty database for initialisation. Set `PGHOST`, `PGPORT` and `PGUSER` as needed. `ON_ERROR_STOP` prevents later statements from masking a failure.

```bash
# 0. Create a fresh database (once)
createdb -U <username> kalpa_db

# 1. Execute database schema DDL
psql -X -v ON_ERROR_STOP=1 -U <username> -d kalpa_db -f dbms/03_schema.sql

# 2. Seed realistic mock data (50 users, projects, shapes, comments, replies)
psql -X -v ON_ERROR_STOP=1 -U <username> -d kalpa_db -f dbms/03_seed_data.sql

# 3. Benchmark application queries with automatic rollback of every sample
PGUSER=<username> ./dbms/run_benchmark.sh kalpa_db 3
```

The benchmark requires the fresh seeded fixture, never resets user data, and writes updated plans/report only after every measurement and the before/after data checks pass. Running `04_queries.sql` directly executes and commits its example writes, so do that only in a disposable database; a repeated direct run can encounter duplicate IDs.

To run the rollback-only integrity regression checks (requires Python `psycopg2`):

```bash
PGUSER=<username> python3 dbms/tests/verify_database.py kalpa_db
```

The ER diagram has an editable source, [`dbms/02_er_diagram.svg`](dbms/02_er_diagram.svg), generated from the schema with `python3 dbms/render_er.py`. The PNG is rendered from that source for submission. To regenerate the PNG with Node.js and `sharp` installed in your environment:

```bash
node -e 'require("sharp")("dbms/02_er_diagram.svg").png().toFile("dbms/02_er_diagram.png")'
```

Check plan/report consistency without a database:

```bash
python3 dbms/tests/verify_artifacts.py
```

To run execution plan analysis with buffers for an individual query:

```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT e.element_id, e.shape_type, e.pos_x, e.pos_y, e.width, e.height, e.z_index
FROM canvas_elements e
WHERE e.project_id = 'proj_001'
ORDER BY e.z_index ASC;
```
