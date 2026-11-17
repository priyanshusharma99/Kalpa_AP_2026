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


-- ============================================================
-- R08: READ
-- Canvas load — fetch elements sorted by z-index for rendering
-- Scenario: Real-time canvas hydration for Fabric.js / canvas renderer.
-- Elements are fetched in ascending z-index layer order.
-- ============================================================
SELECT e.element_id, e.shape_type, e.pos_x, e.pos_y, e.width, e.height,
       e.scale_x, e.scale_y, e.rotation, e.opacity, e.fill_color, e.stroke_color,
       e.stroke_width, e.z_index, e.text_content, e.image_url, e.custom_properties,
       e.creator_id, u.user_name AS creator_name
FROM canvas_elements e
LEFT JOIN users u ON e.creator_id = u.user_id
WHERE e.project_id = 'proj_001'
ORDER BY e.z_index ASC;

-- ============================================================
-- R09: READ
-- Element inspector — retrieve single canvas shape by ID
-- Scenario: Invoked when a user selects a shape on the canvas
-- to populate the right-hand property inspector panel.
-- ============================================================
SELECT e.element_id, e.project_id, e.shape_type, e.pos_x, e.pos_y, e.width, e.height,
       e.scale_x, e.scale_y, e.rotation, e.opacity, e.fill_color, e.stroke_color,
       e.stroke_width, e.z_index, e.text_content, e.image_url, e.custom_properties,
       e.created_at, e.updated_at, u.user_name AS creator_name
FROM canvas_elements e
LEFT JOIN users u ON e.creator_id = u.user_id
WHERE e.project_id = 'proj_001' AND e.element_id = 'elem_0026';

-- ============================================================
-- R10: READ
-- Layer management — fetch maximum z-index for new element stacking
-- Scenario: Determines the top layer index when a user draws a new
-- vector shape, ensuring it renders above all existing elements.
-- ============================================================
SELECT COALESCE(MAX(z_index), 0) AS max_z_index
FROM canvas_elements
WHERE project_id = 'proj_001';

-- ============================================================
-- R11: READ
-- Filter canvas elements by shape type category
-- Scenario: Canvas element filter in layers panel (e.g. geometric shapes).
-- ============================================================
SELECT e.element_id, e.shape_type, e.pos_x, e.pos_y, e.width, e.height,
       e.fill_color, e.stroke_color, e.z_index, u.user_name AS creator_name
FROM canvas_elements e
JOIN users u ON e.creator_id = u.user_id
WHERE e.project_id = 'proj_001' AND e.shape_type IN ('rect', 'circle', 'triangle')
ORDER BY e.z_index ASC;

-- ============================================================
-- R12: READ
-- Search custom attributes in JSONB (locked canvas shapes)
-- Scenario: Queries PostgreSQL JSONB custom_properties column using
-- containment operator (@>) to identify locked elements on canvas.
-- ============================================================
SELECT e.element_id, e.shape_type, e.custom_properties, u.user_name AS creator_name
FROM canvas_elements e
JOIN users u ON e.creator_id = u.user_id
WHERE e.project_id = 'proj_001'
  AND e.custom_properties @> '{"isLocked": true}'::jsonb;

-- ============================================================
-- R13: READ
-- Pinned comments overlay — fetch pins with reply counts
-- Scenario: Renders comment pin badges across the 2D canvas coordinates
-- along with creator profile details and total message replies.
-- ============================================================
SELECT cp.comment_id, cp.pin_x, cp.pin_y, cp.status, cp.created_at,
       u.user_id AS creator_id, u.user_name AS creator_name, u.avatar_url AS creator_avatar,
       COUNT(cr.reply_id) AS reply_count
FROM comment_pins cp
LEFT JOIN users u ON cp.creator_id = u.user_id
LEFT JOIN comment_replies cr ON cp.comment_id = cr.comment_id
WHERE cp.project_id = 'proj_001'
GROUP BY cp.comment_id, u.user_id
ORDER BY cp.created_at ASC;

-- ============================================================
-- R14: READ
-- Comment thread history — fetch replies for thread chronologically
-- Scenario: Invoked when user expands a comment pin to view discussion
-- history and conversation replies.
-- ============================================================
SELECT cr.reply_id, cr.comment_id, cr.message_text, cr.created_at,
       u.user_id AS author_id, u.user_name AS author_name, u.avatar_url AS author_avatar
FROM comment_replies cr
LEFT JOIN users u ON cr.author_id = u.user_id
WHERE cr.comment_id = 'comm_001'
ORDER BY cr.created_at ASC;
