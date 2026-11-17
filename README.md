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
| **CP1** | Completed | [`dbms/01_normalization.md`](file:///Users/sharma/Downloads/Priyanshu's%20Space/AP/Kalpa_AP_2026/dbms/01_normalization.md) | Formal normalization process: UNF &rarr; 1NF &rarr; 2NF &rarr; 3NF &rarr; BCNF with functional dependency proofs. |
| **CP2** | Completed | [`dbms/02_er_diagram.png`](file:///Users/sharma/Downloads/Priyanshu's%20Space/AP/Kalpa_AP_2026/dbms/02_er_diagram.png)<br>[`dbms/03_schema.sql`](file:///Users/sharma/Downloads/Priyanshu's%20Space/AP/Kalpa_AP_2026/dbms/03_schema.sql) | Relational ER diagram, PostgreSQL DDL schema, tables, foreign keys, constraints, and trigger-enforced owner invariants. |
| **CP3** | Completed | [`dbms/04_queries.sql`](file:///Users/sharma/Downloads/Priyanshu's%20Space/AP/Kalpa_AP_2026/dbms/04_queries.sql)<br>[`dbms/queries.sql`](file:///Users/sharma/Downloads/Priyanshu's%20Space/AP/Kalpa_AP_2026/dbms/queries.sql)<br>[`queries.sql`](file:///Users/sharma/Downloads/Priyanshu's%20Space/AP/Kalpa_AP_2026/queries.sql) | Comprehensive SQL queries covering authentication, projects, RBAC, spatial viewport culling, comments, analytics, and DML state flushes. |
| **CP4** | Completed | [`dbms/05_query_timings.md`](file:///Users/sharma/Downloads/Priyanshu's%20Space/AP/Kalpa_AP_2026/dbms/05_query_timings.md)<br>[`dbms/plans/`](file:///Users/sharma/Downloads/Priyanshu's%20Space/AP/Kalpa_AP_2026/dbms/plans/) | Query execution timings (3-iteration benchmark averages) and raw PostgreSQL query plan logs (`EXPLAIN (ANALYZE, BUFFERS)`). |

---

## 3. Workload Queries Catalog (`dbms/04_queries.sql`)

### Read Workloads (R01 – R18)
| ID | Category | Query Description | Execution Scan |
|:---|:---|:---|:---|
| **R01** | Auth | User authentication & profile lookup by email | Seq Scan |
| **R02** | Profile | User profile & account details lookup by ID | Seq Scan |
| **R03** | Dashboard | User dashboard — owned projects with collaborator count | Seq Scan |
| **R04** | Dashboard | User dashboard — shared projects with role and owner details | Hash Join |
| **R05** | Workspace | Active canvas initialization — project settings & owner metadata | Hash Join |
| **R06** | Security | Access control check — verify user role & permissions on canvas | Nested Loop |
| **R07** | Team | Collaborator roster — list project members with role descriptions | Hash Join |
| **R08** | Canvas | Canvas load — fetch elements sorted by z-index for rendering | Index Scan |
| **R09** | Inspector | Element inspector — retrieve single canvas shape by ID | Index Scan |
| **R10** | Stacking | Layer management — fetch maximum z-index for new element stacking | Index Only Scan |
| **R11** | Filter | Filter canvas elements by shape type category | Index Scan |
| **R12** | JSONB | Search custom attributes in JSONB (locked canvas shapes) | Index Scan |
| **R13** | Review | Pinned comments overlay — fetch pins with reply counts | Seq Scan |
| **R14** | Thread | Comment thread history — fetch replies for thread chronologically | Seq Scan |
| **R15** | Status | Project status header — count unresolved active comments | Seq Scan |
| **R16** | Search | Dashboard search — filter accessible projects by title substring | Hash Join |
| **R17** | Analytics | Project analytics — aggregate elements by shape type and dimension stats | Index Scan |
| **R18** | Audit | Audit trail — recent canvas modifications and editor details | Index Scan |

### Advanced Analytical & Spatial Workloads (A01 – A04)
| ID | Category | Query Description |
|:---|:---|:---|
| **A01** | Spatial | Viewport Culling — 2D Axis-Aligned Bounding Box (AABB) intersection query |
| **A02** | Analytics | Contributor Leaderboard using Window Function (`DENSE_RANK()`) |
| **A03** | Layering | Canvas Layering Gap Analysis using `LAG()` / `LEAD()` |
| **A04** | Hierarchy | Thread Discussion Hierarchy formatted with JSON Aggregation (`json_agg`) |

### Write Workloads (W01 – W10)
| ID | Operation | Description | Target |
|:---|:---|:---|:---|
| **W01** | INSERT | Register / create new user account | `users` |
| **W02** | INSERT | Create new canvas project with owner synchronization trigger | `projects` |
| **W03** | UPSERT | Add or update collaborator role on project | `project_collaborators` |
| **W04** | INSERT | Persist newly drawn canvas element | `canvas_elements` |
| **W05** | UPDATE | Update element position, dimensions & style (drag flush) | `canvas_elements` |
| **W06** | DELETE | Delete canvas element by ID | `canvas_elements` |
| **W07** | INSERT | Create new pinned comment thread | `comment_pins` |
| **W08** | UPDATE | Update comment pin status (resolve discussion pin) | `comment_pins` |
| **W09** | UPSERT | Real-time Liveblocks debounce upsert (`ON CONFLICT DO UPDATE`) | `canvas_elements` |
| **W10** | TRANSACTION | Atomic project ownership transfer transaction | `projects` |

---

## 4. Query Execution Guide

To run the complete query suite against PostgreSQL:

```bash
# 1. Execute database schema
psql -U <username> -d kalpa_db -f dbms/03_schema.sql

# 2. Execute application queries
psql -U <username> -d kalpa_db -f dbms/04_queries.sql
```

To run execution plan analysis with buffers:
```sql
EXPLAIN (ANALYZE, BUFFERS, COSTS, VERBOSE)
SELECT e.element_id, e.shape_type, e.pos_x, e.pos_y, e.width, e.height, e.z_index
FROM canvas_elements e
WHERE e.project_id = 'proj_001'
ORDER BY e.z_index ASC;
```
