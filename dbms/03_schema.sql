-- Kalpa database schema (PostgreSQL)

-- Users
CREATE TABLE users (
    user_id VARCHAR(64) PRIMARY KEY,
    user_name VARCHAR(100) NOT NULL CHECK (char_length(trim(user_name)) >= 2),
    user_email VARCHAR(255) UNIQUE NOT NULL CHECK (user_email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),
    avatar_url TEXT CHECK (avatar_url IS NULL OR avatar_url ~* '^https?://.*'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Role permissions (lookup)
CREATE TABLE role_permissions (
    role_name VARCHAR(32) PRIMARY KEY CHECK (role_name IN ('owner', 'editor', 'viewer')),
    access_level_desc TEXT NOT NULL,
    can_edit BOOLEAN NOT NULL DEFAULT FALSE,
    can_comment BOOLEAN NOT NULL DEFAULT TRUE,
    can_share BOOLEAN NOT NULL DEFAULT FALSE
);

INSERT INTO role_permissions (role_name, access_level_desc, can_edit, can_comment, can_share) VALUES
    ('owner', 'Full administrative control', TRUE, TRUE, TRUE),
    ('editor', 'Can edit canvas and resolve comments', TRUE, TRUE, FALSE),
    ('viewer', 'View and comment only', FALSE, TRUE, FALSE);

-- Projects
CREATE TABLE projects (
    project_id VARCHAR(64) PRIMARY KEY,
    project_title VARCHAR(255) NOT NULL DEFAULT 'Untitled Document' CHECK (char_length(trim(project_title)) > 0),
    canvas_width INT NOT NULL DEFAULT 1920 CHECK (canvas_width >= 100 AND canvas_width <= 10000),
    canvas_height INT NOT NULL DEFAULT 1080 CHECK (canvas_height >= 100 AND canvas_height <= 10000),
    canvas_bg_color VARCHAR(16) NOT NULL DEFAULT '#1E1E1E' CHECK (canvas_bg_color ~* '^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3}|[A-Fa-f0-9]{8})$'),
    owner_id VARCHAR(64) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_projects_owner
        FOREIGN KEY (owner_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE
);

-- Collaborators (M:N)
CREATE TABLE project_collaborators (
    project_id VARCHAR(64) NOT NULL,
    user_id VARCHAR(64) NOT NULL,
    role_name VARCHAR(32) NOT NULL DEFAULT 'viewer',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (project_id, user_id),
    CONSTRAINT fk_collab_project
        FOREIGN KEY (project_id) 
        REFERENCES projects(project_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_collab_user
        FOREIGN KEY (user_id) 
        REFERENCES users(user_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_collab_role
        FOREIGN KEY (role_name) 
        REFERENCES role_permissions(role_name) 
        ON UPDATE CASCADE 
        ON DELETE RESTRICT
);

-- Exactly one owner collaborator per project
CREATE UNIQUE INDEX uq_project_single_owner 
ON project_collaborators (project_id) 
WHERE role_name = 'owner';

-- Canvas shapes and elements
CREATE TABLE canvas_elements (
    element_id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) NOT NULL,
    shape_type VARCHAR(32) NOT NULL CHECK (shape_type IN ('rect', 'circle', 'triangle', 'path', 'text', 'image')),
    pos_x NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    pos_y NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    width NUMERIC(10, 2) NOT NULL DEFAULT 100.00 CHECK (width >= 0.00),
    height NUMERIC(10, 2) NOT NULL DEFAULT 100.00 CHECK (height >= 0.00),
    scale_x NUMERIC(5, 2) NOT NULL DEFAULT 1.00 CHECK (scale_x > 0.00),
    scale_y NUMERIC(5, 2) NOT NULL DEFAULT 1.00 CHECK (scale_y > 0.00),
    rotation NUMERIC(6, 2) NOT NULL DEFAULT 0.00 CHECK (rotation >= 0.00 AND rotation < 360.00),
    opacity NUMERIC(3, 2) NOT NULL DEFAULT 1.00 CHECK (opacity >= 0.00 AND opacity <= 1.00),
    fill_color VARCHAR(32) DEFAULT '#CCCCCC',
    stroke_color VARCHAR(32) DEFAULT '#000000',
    stroke_width NUMERIC(5, 2) NOT NULL DEFAULT 1.00 CHECK (stroke_width >= 0.00),
    z_index INT NOT NULL DEFAULT 0,
    text_content TEXT,
    image_url TEXT,
    custom_properties JSONB DEFAULT '{}'::jsonb,
    creator_id VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_elements_project
        FOREIGN KEY (project_id) 
        REFERENCES projects(project_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_elements_creator
        FOREIGN KEY (creator_id) 
        REFERENCES users(user_id) 
        ON DELETE SET NULL
);

-- Pinned comments
CREATE TABLE comment_pins (
    comment_id VARCHAR(64) PRIMARY KEY,
    project_id VARCHAR(64) NOT NULL,
    pin_x NUMERIC(10, 2) NOT NULL,
    pin_y NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved')),
    creator_id VARCHAR(64),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_comments_project
        FOREIGN KEY (project_id) 
        REFERENCES projects(project_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_comments_creator
        FOREIGN KEY (creator_id) 
        REFERENCES users(user_id) 
        ON DELETE SET NULL
);

-- Thread replies
CREATE TABLE comment_replies (
    reply_id VARCHAR(64) PRIMARY KEY,
    comment_id VARCHAR(64) NOT NULL,
    author_id VARCHAR(64),
    message_text TEXT NOT NULL CHECK (char_length(trim(message_text)) > 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_replies_comment
        FOREIGN KEY (comment_id) 
        REFERENCES comment_pins(comment_id) 
        ON DELETE CASCADE,
    CONSTRAINT fk_replies_author
        FOREIGN KEY (author_id) 
        REFERENCES users(user_id) 
        ON DELETE SET NULL
);

-- Indexes
CREATE INDEX idx_projects_owner ON projects(owner_id);
CREATE INDEX idx_collab_user ON project_collaborators(user_id);
CREATE INDEX idx_elements_project ON canvas_elements(project_id);
CREATE INDEX idx_elements_creator ON canvas_elements(creator_id);
CREATE INDEX idx_elements_z_index ON canvas_elements(project_id, z_index);
CREATE INDEX idx_comments_project ON comment_pins(project_id);
CREATE INDEX idx_replies_comment ON comment_replies(comment_id);
CREATE INDEX idx_elements_custom_properties ON canvas_elements USING gin(custom_properties);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_projects_updated_at
BEFORE UPDATE ON projects
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_canvas_elements_updated_at
BEFORE UPDATE ON canvas_elements
FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Sync owner to collaborators and handle ownership transfer
CREATE OR REPLACE FUNCTION sync_project_owner_collaborator()
RETURNS TRIGGER AS $$
BEGIN
    -- On ownership transfer, demote previous owner to editor
    IF (TG_OP = 'UPDATE' AND OLD.owner_id IS DISTINCT FROM NEW.owner_id) THEN
        UPDATE project_collaborators
        SET role_name = 'editor'
        WHERE project_id = OLD.project_id AND user_id = OLD.owner_id;
    END IF;

    -- Add or update new owner with owner role
    INSERT INTO project_collaborators (project_id, user_id, role_name, joined_at)
    VALUES (NEW.project_id, NEW.owner_id, 'owner', CURRENT_TIMESTAMP)
    ON CONFLICT (project_id, user_id) 
    DO UPDATE SET role_name = 'owner';

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_projects_owner_sync
AFTER INSERT OR UPDATE OF owner_id ON projects
FOR EACH ROW EXECUTE FUNCTION sync_project_owner_collaborator();

-- Enforce owner collaborator invariant
CREATE OR REPLACE FUNCTION enforce_owner_collaborator_invariant()
RETURNS TRIGGER AS $$
DECLARE
    current_project_owner VARCHAR(64);
BEGIN
    -- Allow cascade delete when project is already being deleted
    IF (TG_OP = 'DELETE') THEN
        SELECT owner_id INTO current_project_owner 
        FROM projects 
        WHERE project_id = OLD.project_id;

        -- If project still exists and this user is its owner, prevent removal
        IF (FOUND AND OLD.user_id = current_project_owner) THEN
            RAISE EXCEPTION 'Cannot remove project owner from collaborators. Transfer project ownership first.';
        END IF;

        RETURN OLD;
    END IF;

    -- Look up current project owner for validation
    SELECT owner_id INTO current_project_owner 
    FROM projects 
    WHERE project_id = NEW.project_id;

    -- Only the current projects.owner_id may have role_name = 'owner'
    IF (NEW.role_name = 'owner' AND (current_project_owner IS NULL OR NEW.user_id <> current_project_owner)) THEN
        RAISE EXCEPTION 'Cannot assign owner role to non-owner user. Transfer project ownership first.';
    END IF;

    -- On UPDATE, prevent direct demotion or reassignment of active owner
    IF (TG_OP = 'UPDATE') THEN
        IF (OLD.user_id = current_project_owner) THEN
            IF (NEW.role_name <> 'owner') THEN
                RAISE EXCEPTION 'Cannot demote project owner in collaborators. Transfer project ownership first.';
            END IF;
            IF (NEW.user_id <> OLD.user_id) THEN
                RAISE EXCEPTION 'Cannot change user_id of project owner row. Transfer project ownership first.';
            END IF;
            IF (NEW.project_id <> OLD.project_id) THEN
                RAISE EXCEPTION 'Cannot change project_id of project owner row.';
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_protect_project_owner
BEFORE INSERT OR UPDATE OR DELETE ON project_collaborators
FOR EACH ROW EXECUTE FUNCTION enforce_owner_collaborator_invariant();
