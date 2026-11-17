-- ============================================================
-- Kalpa — Application SQL Queries (CP3 / CP4)
-- Project: Kalpa (Real-Time Collaborative Design Platform / Figma Clone)
-- Target RDBMS: PostgreSQL 14+
-- Author: Priyanshu Sharma (Lead, Team T0013 - Kalpa)
-- Main Repo: https://github.com/priyanshusharma99/Kalpa.git
-- Milestone: CP3 (04_queries.sql)
--
-- Architecture:
--   - PostgreSQL: Authoritative persistent system of record (ACID)
--   - Liveblocks: Real-time ephemeral WebSocket collaboration engine
--
-- Classification:
--   Every query is classified as READ (R01..R18, A01..A04) or WRITE (W01..W08, W09..W10).
-- ============================================================

-- ============================================================
-- R01: READ
-- User authentication & profile lookup by email
-- Scenario: Invoked during OAuth/session handshake to authenticate
-- user and retrieve user profile attributes.
-- ============================================================
SELECT user_id, user_name, user_email, avatar_url, created_at
FROM users
WHERE user_email = 'user1@kalpa.app';

-- ============================================================
-- R02: READ
-- User profile & account details lookup by ID
-- Scenario: Invoked by client user profile modal / settings pane.
-- ============================================================
SELECT user_id, user_name, user_email, avatar_url, created_at, updated_at
FROM users
WHERE user_id = 'usr_001';

-- ============================================================
-- R03: READ
-- User dashboard — owned projects with collaborator count
-- Scenario: Renders the "Owned by me" tab on user dashboard.
-- Aggregates collaborator count per project.
-- ============================================================
SELECT p.project_id, p.project_title, p.canvas_width, p.canvas_height, p.canvas_bg_color,
       p.created_at, p.updated_at,
       COUNT(pc.user_id) AS total_collaborators
FROM projects p
LEFT JOIN project_collaborators pc ON p.project_id = pc.project_id
WHERE p.owner_id = 'usr_001'
GROUP BY p.project_id
ORDER BY p.updated_at DESC;

-- ============================================================
-- R04: READ
-- User dashboard — shared projects with role and owner details
-- Scenario: Renders the "Shared with me" section on user dashboard,
-- joining projects, users (owner), and role permissions.
-- ============================================================
SELECT p.project_id, p.project_title, pc.role_name, rp.can_edit, rp.can_share,
       u.user_name AS owner_name, u.avatar_url AS owner_avatar, pc.joined_at
FROM project_collaborators pc
JOIN projects p ON pc.project_id = p.project_id
JOIN users u ON p.owner_id = u.user_id
JOIN role_permissions rp ON pc.role_name = rp.role_name
WHERE pc.user_id = 'usr_003' AND pc.role_name <> 'owner'
ORDER BY pc.joined_at DESC;

-- ============================================================
-- R05: READ
-- Active canvas initialization — project settings & owner metadata
-- Scenario: Invoked when a client loads a canvas workspace,
-- fetching project dimensions, background color, and owner identity.
-- ============================================================
SELECT p.project_id, p.project_title, p.canvas_width, p.canvas_height, p.canvas_bg_color,
       p.owner_id, u.user_name AS owner_name, u.user_email AS owner_email, p.created_at, p.updated_at
FROM projects p
JOIN users u ON p.owner_id = u.user_id
WHERE p.project_id = 'proj_001';

-- ============================================================
-- R06: READ
-- Access control check — verify user role & permissions on canvas
-- Scenario: Security middleware execution prior to WebSocket room
-- connection to authorize editing/commenting permissions.
-- ============================================================
SELECT pc.project_id, pc.user_id, pc.role_name,
       rp.can_edit, rp.can_comment, rp.can_share
FROM project_collaborators pc
JOIN role_permissions rp ON pc.role_name = rp.role_name
WHERE pc.project_id = 'proj_001' AND pc.user_id = 'usr_001';

-- ============================================================
-- R07: READ
-- Collaborator roster — list project members with role descriptions
-- Scenario: Populates the "Share & Collaborators" project modal with
-- user details, permission descriptions, and member joined dates.
-- ============================================================
SELECT pc.user_id, u.user_name, u.user_email, u.avatar_url,
       pc.role_name, rp.access_level_desc, pc.joined_at
FROM project_collaborators pc
JOIN users u ON pc.user_id = u.user_id
JOIN role_permissions rp ON pc.role_name = rp.role_name
WHERE pc.project_id = 'proj_001'
ORDER BY pc.role_name ASC, u.user_name ASC;
