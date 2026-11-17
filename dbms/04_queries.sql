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


-- ============================================================
-- R15: READ
-- Project status header — count unresolved active comments
-- Scenario: Top bar notification badge showing remaining unresolved
-- review comments for a design project.
-- ============================================================
SELECT COUNT(*) AS open_comment_count
FROM comment_pins
WHERE project_id = 'proj_001' AND status = 'open';

-- ============================================================
-- R16: READ
-- Dashboard search — filter accessible projects by title substring
-- Scenario: Dashboard global search filter matching project titles
-- accessible to the current user.
-- ============================================================
SELECT p.project_id, p.project_title, p.canvas_width, p.canvas_height,
       u.user_name AS owner_name, pc.role_name
FROM projects p
JOIN project_collaborators pc ON p.project_id = pc.project_id
JOIN users u ON p.owner_id = u.user_id
WHERE pc.user_id = 'usr_001'
  AND p.project_title ILIKE '%Project%'
ORDER BY p.updated_at DESC;

-- ============================================================
-- R17: READ
-- Project analytics — aggregate elements by shape type and dimension stats
-- Scenario: Project statistics modal computing element distribution,
-- average dimensions, and min/max z-index stacking bounds.
-- ============================================================
SELECT e.shape_type,
       COUNT(*) AS total_elements,
       ROUND(AVG(e.width), 2) AS avg_width,
       ROUND(AVG(e.height), 2) AS avg_height,
       MIN(e.z_index) AS min_z,
       MAX(e.z_index) AS max_z
FROM canvas_elements e
WHERE e.project_id = 'proj_001'
GROUP BY e.shape_type
ORDER BY total_elements DESC;

-- ============================================================
-- R18: READ
-- Audit trail — recent canvas modifications and editor details
-- Scenario: Activity log side panel displaying the 20 most recent
-- canvas shape additions and modifications with editor metadata.
-- ============================================================
SELECT e.element_id, e.shape_type, e.updated_at,
       u.user_name AS modifier_name, u.avatar_url
FROM canvas_elements e
LEFT JOIN users u ON e.creator_id = u.user_id
WHERE e.project_id = 'proj_001'
ORDER BY e.updated_at DESC
LIMIT 20;

-- ============================================================
-- A01: ADVANCED READ
-- Spatial Viewport Culling (2D Bounding Box Intersection)
-- Scenario: Viewport rendering culling. Fetches only elements intersecting
-- the active client camera window [view_min_x, view_min_y] to [view_max_x, view_max_y].
-- ============================================================
SELECT e.element_id, e.shape_type, e.pos_x, e.pos_y, e.width, e.height, e.z_index
FROM canvas_elements e
WHERE e.project_id = 'proj_001'
  AND e.pos_x <= 1920.00                    -- viewport_max_x
  AND (e.pos_x + e.width) >= 0.00           -- viewport_min_x
  AND e.pos_y <= 1080.00                    -- viewport_max_y
  AND (e.pos_y + e.height) >= 0.00          -- viewport_min_y
ORDER BY e.z_index ASC;

-- ============================================================
-- A02: ADVANCED READ
-- Contributor Leaderboard using Window Function (DENSE_RANK)
-- Scenario: Sprint velocity leaderboard ranking collaborators by
-- total shapes authored across the design project.
-- ============================================================
SELECT 
    e.project_id,
    p.project_title,
    u.user_id,
    u.user_name,
    COUNT(e.element_id) AS elements_created,
    DENSE_RANK() OVER (
        PARTITION BY e.project_id 
        ORDER BY COUNT(e.element_id) DESC
    ) AS contribution_rank
FROM canvas_elements e
JOIN projects p ON e.project_id = p.project_id
JOIN users u ON e.creator_id = u.user_id
WHERE e.project_id = 'proj_001'
GROUP BY e.project_id, p.project_title, u.user_id, u.user_name
ORDER BY contribution_rank ASC;

-- ============================================================
-- A03: ADVANCED READ
-- Canvas Layering Gap Analysis using LAG() / LEAD()
-- Scenario: Layer defragmentation check inspecting gaps between
-- consecutive z-index layers on canvas.
-- ============================================================
WITH layer_sequence AS (
    SELECT 
        element_id,
        shape_type,
        z_index,
        LAG(z_index) OVER (ORDER BY z_index ASC) AS prev_z,
        LEAD(z_index) OVER (ORDER BY z_index ASC) AS next_z
    FROM canvas_elements
    WHERE project_id = 'proj_001'
)
SELECT 
    element_id,
    shape_type,
    z_index,
    prev_z,
    next_z,
    (z_index - prev_z) AS gap_with_previous
FROM layer_sequence
ORDER BY z_index ASC;

-- ============================================================
-- A04: ADVANCED READ
-- Thread Discussion Hierarchy using JSON Aggregation
-- Scenario: Single-roundtrip API payload returning comment pins with
-- all discussion replies formatted as nested JSON objects.
-- ============================================================
SELECT 
    cp.comment_id,
    cp.pin_x,
    cp.pin_y,
    cp.status,
    u.user_name AS creator_name,
    COALESCE(
        json_agg(
            json_build_object(
                'reply_id', cr.reply_id,
                'author_name', ru.user_name,
                'message_text', cr.message_text,
                'created_at', cr.created_at
            ) ORDER BY cr.created_at ASC
        ) FILTER (WHERE cr.reply_id IS NOT NULL),
        '[]'::json
    ) AS replies_json
FROM comment_pins cp
JOIN users u ON cp.creator_id = u.user_id
LEFT JOIN comment_replies cr ON cp.comment_id = cr.comment_id
LEFT JOIN users ru ON cr.author_id = ru.user_id
WHERE cp.project_id = 'proj_001'
GROUP BY cp.comment_id, cp.pin_x, cp.pin_y, cp.status, u.user_name
ORDER BY cp.created_at ASC;


-- ============================================================
-- W01: WRITE
-- Register / create new user account
-- Scenario: User onboarding flow via Google OAuth or credentials.
-- ============================================================
INSERT INTO users (user_id, user_name, user_email, avatar_url)
VALUES ('usr_benchmark', 'Bench User', 'benchmark@kalpa.app', 'https://avatar.iran.liara.run/public/99')
ON CONFLICT (user_email) DO NOTHING;

-- ============================================================
-- W02: WRITE
-- Create new canvas project with owner synchronization
-- Scenario: Invoked when a user clicks "New Project" in workspace.
-- trg_projects_owner_sync automatically registers owner collaborator.
-- ============================================================
INSERT INTO projects (project_id, project_title, canvas_width, canvas_height, canvas_bg_color, owner_id)
VALUES ('proj_benchmark', 'Benchmark Mockup Canvas', 1920, 1080, '#1E1E1E', 'usr_001');

-- ============================================================
-- W03: WRITE
-- Add or update collaborator role on project
-- Scenario: Invoked when a project owner invites or adjusts permissions
-- for a collaborator in the Share modal.
-- ============================================================
INSERT INTO project_collaborators (project_id, user_id, role_name, joined_at)
VALUES ('proj_001', 'usr_045', 'editor', CURRENT_TIMESTAMP)
ON CONFLICT (project_id, user_id)
DO UPDATE SET role_name = EXCLUDED.role_name;

-- ============================================================
-- W04: WRITE
-- Persist newly drawn canvas element
-- Scenario: Flush newly created shape from Liveblocks room state
-- into PostgreSQL authoritative storage.
-- ============================================================
INSERT INTO canvas_elements (
    element_id, project_id, shape_type, pos_x, pos_y, width, height,
    scale_x, scale_y, rotation, opacity, fill_color, stroke_color,
    stroke_width, z_index, text_content, custom_properties, creator_id
) VALUES (
    'elem_benchmark', 'proj_001', 'rect', 250.00, 350.00, 180.00, 120.00,
    1.00, 1.00, 0.00, 1.00, '#3B82F6', '#1D4ED8',
    1.00, 25, NULL, '{"isLocked": false, "name": "BenchRect"}'::jsonb, 'usr_001'
);

-- ============================================================
-- W05: WRITE
-- Update element position, dimensions & style (drag flush)
-- Scenario: Real-time debounce flush when user finishes dragging or
-- resizing a shape on the collaborative canvas.
-- ============================================================
UPDATE canvas_elements
SET pos_x = 310.50,
    pos_y = 420.00,
    width = 220.00,
    height = 150.00,
    fill_color = '#10B981',
    z_index = 30,
    updated_at = CURRENT_TIMESTAMP
WHERE element_id = 'elem_0026' AND project_id = 'proj_001';

-- ============================================================
-- W06: WRITE
-- Delete canvas element by ID
-- Scenario: User deletes a selected element using the Delete key or context menu.
-- ============================================================
DELETE FROM canvas_elements
WHERE element_id = 'elem_0050' AND project_id = 'proj_001';

-- ============================================================
-- W07: WRITE
-- Create new pinned comment thread
-- Scenario: User selects the Comment tool and places a pin on canvas coordinates.
-- ============================================================
INSERT INTO comment_pins (comment_id, project_id, pin_x, pin_y, status, creator_id)
VALUES ('comm_benchmark', 'proj_001', 320.00, 150.00, 'open', 'usr_001');

-- ============================================================
-- W08: WRITE
-- Update comment pin status (resolve discussion pin)
-- Scenario: Reviewer marks a discussion thread as resolved.
-- ============================================================
UPDATE comment_pins
SET status = 'resolved'
WHERE comment_id = 'comm_001' AND project_id = 'proj_001';

-- ============================================================
-- W09: WRITE
-- Real-time Liveblocks Debounce Upsert
-- Scenario: Handles both creation and edits in a single idempotent statement.
-- ============================================================
INSERT INTO canvas_elements (
    element_id, project_id, shape_type, pos_x, pos_y, width, height,
    scale_x, scale_y, rotation, opacity, fill_color, stroke_color,
    stroke_width, z_index, custom_properties, creator_id
) VALUES (
    'elem_upsert_01', 'proj_001', 'rect', 400.00, 200.00, 150.00, 100.00,
    1.00, 1.00, 0.00, 1.00, '#6366F1', '#4F46E5',
    1.50, 15, '{"borderRadius": "4px"}'::jsonb, 'usr_001'
)
ON CONFLICT (element_id) DO UPDATE SET
    pos_x = EXCLUDED.pos_x,
    pos_y = EXCLUDED.pos_y,
    width = EXCLUDED.width,
    height = EXCLUDED.height,
    fill_color = EXCLUDED.fill_color,
    updated_at = CURRENT_TIMESTAMP;

-- ============================================================
-- W10: WRITE
-- Atomic Project Ownership Transfer Transaction
-- Scenario: Reassigns project owner while trg_projects_owner_sync
-- demotes prior owner to editor and promotes new owner.
-- ============================================================
BEGIN;
UPDATE projects
SET owner_id = 'usr_002', updated_at = CURRENT_TIMESTAMP
WHERE project_id = 'proj_001' AND owner_id = 'usr_001';
COMMIT;
