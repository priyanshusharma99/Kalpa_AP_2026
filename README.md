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
- **PostgreSQL (Authoritative Relational Store):** Stores persistent records including users, projects, role-based access control, canvas shapes, comment pins, discussion replies, and audit history. Enforces strict relational integrity, check constraints, and trigger-based invariants.
- **Liveblocks (Ephemeral Real-Time Engine):** Coordinates low-latency WebSocket synchronization for live user cursors, active dragging states, and floating emoji reactions. Periodic debounce flushes sync live room state into PostgreSQL.

---

## 2. Checkpoints & Milestones

| Checkpoint | Status | File Deliverables | Description |
| :--- | :---: | :--- | :--- |
| **CP1** | Completed | [`dbms/01_normalization.md`](dbms/01_normalization.md) | Formal normalization process: UNF &rarr; 1NF &rarr; 2NF &rarr; 3NF &rarr; BCNF with functional dependency proofs. |
| **CP2** | Completed | [`dbms/02_er_diagram.png`](dbms/02_er_diagram.png)<br>[`dbms/03_schema.sql`](dbms/03_schema.sql)<br>[`dbms/03_seed_data.sql`](dbms/03_seed_data.sql) | Relational ER diagram, PostgreSQL DDL schema, tables, foreign keys, constraints, triggers, and comprehensive seed data for 50 users. |
| **CP3** | Completed | [`dbms/04_queries.sql`](dbms/04_queries.sql)<br>[`dbms/queries.sql`](dbms/queries.sql)<br>[`queries.sql`](queries.sql) | Comprehensive SQL queries covering authentication, projects, RBAC, spatial viewport culling, comments, analytics, and DML state flushes. |
| **CP4** | Completed | [`dbms/05_query_timings.md`](dbms/05_query_timings.md)<br>[`dbms/plans/`](dbms/plans/)<br>[`dbms/run_benchmark.sh`](dbms/run_benchmark.sh) | Query execution timings (3-iteration benchmark averages across all 32 queries), raw PostgreSQL plan logs (`EXPLAIN (ANALYZE, BUFFERS)`), and benchmark runner. |

---

## 3. Workload Queries Catalog (`dbms/04_queries.sql`)

### Read Workloads (R01 – R18)
| ID | Category | Query Description | Execution Scan | Avg Time |
|:---|:---|:---|:---|---:|
| **R01** | Auth | User authentication & profile lookup by email | Seq Scan | 0.064 ms |
| **R02** | Profile | User profile & account details lookup by ID | Seq Scan | 0.060 ms |
| **R03** | Dashboard | User dashboard — owned projects with collaborator count | Seq Scan | 0.204 ms |
| **R04** | Dashboard | User dashboard — shared projects with role and owner details | Hash Join | 0.193 ms |
| **R05** | Workspace | Active canvas initialization — project settings & owner metadata | Hash Join | 0.094 ms |
| **R06** | Security | Access control check — verify user role & permissions on canvas | Nested Loop | 0.064 ms |
| **R07** | Team | Collaborator roster — list project members with role descriptions | Hash Join | 0.185 ms |
| **R08** | Canvas | Canvas load — fetch elements sorted by z-index for rendering | Index Scan | 0.237 ms |
| **R09** | Inspector | Element inspector — retrieve single canvas shape by ID | Index Scan | 0.071 ms |
| **R10** | Stacking | Layer management — fetch maximum z-index for new element stacking | Index Only Scan | 0.110 ms |
| **R11** | Filter | Filter canvas elements by shape type category | Index Scan | 0.207 ms |
| **R12** | JSONB | Search custom attributes in JSONB (locked canvas shapes) | Index Scan | 0.177 ms |
| **R13** | Review | Pinned comments overlay — fetch pins with reply counts | Seq Scan | 0.212 ms |
| **R14** | Thread | Comment thread history — fetch replies for thread chronologically | Seq Scan | 0.135 ms |
| **R15** | Status | Project status header — count unresolved active comments | Seq Scan | 0.070 ms |
| **R16** | Search | Dashboard search — filter accessible projects by title substring | Hash Join | 0.193 ms |
| **R17** | Analytics | Project analytics — aggregate elements by shape type and dimension stats | Index Scan | 0.215 ms |
| **R18** | Audit | Audit trail — recent canvas modifications and editor details | Index Scan | 0.208 ms |

### Advanced Analytical & Spatial Workloads (A01 – A04)
| ID | Category | Query Description | Execution Scan | Avg Time |
|:---|:---|:---|:---|---:|
| **A01** | Spatial | Viewport Culling — 2D Axis-Aligned Bounding Box (AABB) intersection query | Index Scan | 0.049 ms |
| **A02** | Analytics | Contributor Leaderboard using Window Function (`DENSE_RANK()`) | WindowAgg / Index Scan | 0.156 ms |
| **A03** | Layering | Canvas Layering Gap Analysis using `LAG()` / `LEAD()` | WindowAgg / Index Scan | 0.073 ms |
| **A04** | Hierarchy | Thread Discussion Hierarchy formatted with JSON Aggregation (`json_agg`) | GroupAggregate / Index Scan | 0.143 ms |

### Write Workloads (W01 – W10)
| ID | Operation | Description | Target | Execution Node | Avg Time |
|:---|:---|:---|:---|:---|---:|
| **W01** | INSERT | Register / create new user account | `users` | Insert | 0.419 ms |
| **W02** | INSERT | Create new canvas project with owner synchronization trigger | `projects` | Insert | 4.839 ms |
| **W03** | UPSERT | Add or update collaborator role on project | `project_collaborators` | Insert | 2.477 ms |
| **W04** | INSERT | Persist newly drawn canvas element | `canvas_elements` | Insert | 0.936 ms |
| **W05** | UPDATE | Update element position, dimensions & style (drag flush) | `canvas_elements` | Index Scan | 0.144 ms |
| **W06** | DELETE | Delete canvas element by ID | `canvas_elements` | Index Scan | 0.214 ms |
| **W07** | INSERT | Create new pinned comment thread | `comment_pins` | Insert | 0.874 ms |
| **W08** | UPDATE | Update comment pin status (resolve discussion pin) | `comment_pins` | Seq Scan | 0.112 ms |
| **W09** | UPSERT | Real-time Liveblocks debounce upsert (`ON CONFLICT DO UPDATE`) | `canvas_elements` | Insert (Upsert) | 0.480 ms |
| **W10** | TRANSACTION | Atomic project ownership transfer transaction | `projects` | Index Scan (Trigger Sync) | 1.351 ms |

---

## 4. Query Execution Guide

To initialize the database and run the complete query suite against PostgreSQL:

```bash
# 1. Execute database schema DDL
psql -U <username> -d kalpa_db -f dbms/03_schema.sql

# 2. Seed realistic mock data (50 users, projects, shapes, comments, replies)
psql -U <username> -d kalpa_db -f dbms/03_seed_data.sql

# 3. Execute application queries (R01..R18, A01..A04, W01..W10)
psql -U <username> -d kalpa_db -f dbms/04_queries.sql
```

To run the automated benchmark runner:
```bash
./dbms/run_benchmark.sh kalpa_db 3
```

To run execution plan analysis with buffers for an individual query:
```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT e.element_id, e.shape_type, e.pos_x, e.pos_y, e.width, e.height, e.z_index
FROM canvas_elements e
WHERE e.project_id = 'proj_001'
ORDER BY e.z_index ASC;
```
