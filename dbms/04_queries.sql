-- ============================================================
-- Kalpa — Application SQL Queries (CP3 / CP4)
-- System of Record: PostgreSQL
-- Real-time Sync Engine: Liveblocks
-- Every query marked as -- READ or -- WRITE with JOINs where appropriate.
-- ============================================================

-- ============================================================
-- R01: READ
-- User authentication & profile lookup by email
-- ============================================================
SELECT user_id, user_name, user_email, avatar_url, created_at
FROM users
WHERE user_email = 'user1@kalpa.app';

-- ============================================================
-- R02: READ
-- User profile & account details lookup by ID
-- ============================================================
SELECT user_id, user_name, user_email, avatar_url, created_at, updated_at
FROM users
WHERE user_id = 'usr_001';

-- ============================================================
-- R03: READ
-- User dashboard — owned projects with collaborator count
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
-- ============================================================
SELECT p.project_id, p.project_title, p.canvas_width, p.canvas_height, p.canvas_bg_color,
       p.owner_id, u.user_name AS owner_name, u.user_email AS owner_email, p.created_at, p.updated_at
FROM projects p
JOIN users u ON p.owner_id = u.user_id
WHERE p.project_id = 'proj_001';

-- ============================================================
-- R06: READ
-- Access control check — verify user role & permissions on canvas
-- ============================================================
SELECT pc.project_id, pc.user_id, pc.role_name,
       rp.can_edit, rp.can_comment, rp.can_share
FROM project_collaborators pc
JOIN role_permissions rp ON pc.role_name = rp.role_name
WHERE pc.project_id = 'proj_001' AND pc.user_id = 'usr_001';

-- ============================================================
-- R07: READ
-- Collaborator roster — list project members with role descriptions
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
-- ============================================================
SELECT COALESCE(MAX(z_index), 0) AS max_z_index
FROM canvas_elements
WHERE project_id = 'proj_001';

-- ============================================================
-- R11: READ
-- Filter canvas elements by shape type category
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
-- ============================================================
SELECT e.element_id, e.shape_type, e.custom_properties, u.user_name AS creator_name
FROM canvas_elements e
JOIN users u ON e.creator_id = u.user_id
WHERE e.project_id = 'proj_001'
  AND e.custom_properties @> '{"isLocked": true}'::jsonb;

-- ============================================================
-- R13: READ
-- Pinned comments overlay — fetch pins with reply counts
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
-- ============================================================
SELECT COUNT(*) AS open_comment_count
FROM comment_pins
WHERE project_id = 'proj_001' AND status = 'open';

-- ============================================================
-- R16: READ
-- Dashboard search — filter accessible projects by title substring
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
-- ============================================================
SELECT e.element_id, e.shape_type, e.updated_at,
       u.user_name AS modifier_name, u.avatar_url
FROM canvas_elements e
LEFT JOIN users u ON e.creator_id = u.user_id
WHERE e.project_id = 'proj_001'
ORDER BY e.updated_at DESC
LIMIT 20;

-- ============================================================
-- W01: WRITE
-- Register / create new user account
-- ============================================================
INSERT INTO users (user_id, user_name, user_email, avatar_url)
VALUES ('usr_benchmark', 'Bench User', 'benchmark@kalpa.app', 'https://avatar.iran.liara.run/public/99')
ON CONFLICT (user_email) DO NOTHING;

-- ============================================================
-- W02: WRITE
-- Create new canvas project with owner synchronization
-- ============================================================
INSERT INTO projects (project_id, project_title, canvas_width, canvas_height, canvas_bg_color, owner_id)
VALUES ('proj_benchmark', 'Benchmark Mockup Canvas', 1920, 1080, '#1E1E1E', 'usr_001');

-- ============================================================
-- W03: WRITE
-- Add or update collaborator role on project
-- ============================================================
INSERT INTO project_collaborators (project_id, user_id, role_name, joined_at)
VALUES ('proj_001', 'usr_045', 'editor', CURRENT_TIMESTAMP)
ON CONFLICT (project_id, user_id)
DO UPDATE SET role_name = EXCLUDED.role_name;

-- ============================================================
-- W04: WRITE
-- Persist newly drawn canvas element
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
-- ============================================================
DELETE FROM canvas_elements
WHERE element_id = 'elem_0050' AND project_id = 'proj_001';

-- ============================================================
-- W07: WRITE
-- Create new pinned comment thread
-- ============================================================
INSERT INTO comment_pins (comment_id, project_id, pin_x, pin_y, status, creator_id)
VALUES ('comm_benchmark', 'proj_001', 320.00, 150.00, 'open', 'usr_001');

-- ============================================================
-- W08: WRITE
-- Update comment pin status (resolve discussion pin)
-- ============================================================
UPDATE comment_pins
SET status = 'resolved'
WHERE comment_id = 'comm_001' AND project_id = 'proj_001';

