-- ============================================================
-- Kalpa — Comprehensive Seed Data
-- Target Database: PostgreSQL 14+
-- Team: T0013 (Kalpa)
-- Purpose: Realistic mock dataset for 50 users, collaborative projects,
--          canvas vector shapes, pinned comment threads, and discussion replies.
-- ============================================================

-- 1. Insert 50 Users
INSERT INTO users (user_id, user_name, user_email, avatar_url, created_at) VALUES
('usr_001', 'Priyanshu Sharma', 'user1@kalpa.app', 'https://avatar.iran.liara.run/public/1', NOW() - INTERVAL '30 days'),
('usr_002', 'Anurag Sonawane', 'anurag@kalpa.app', 'https://avatar.iran.liara.run/public/2', NOW() - INTERVAL '29 days'),
('usr_003', 'Manjeet Lodha', 'manjeet@kalpa.app', 'https://avatar.iran.liara.run/public/3', NOW() - INTERVAL '28 days'),
('usr_004', 'Srijal Srivastava', 'srijal@kalpa.app', 'https://avatar.iran.liara.run/public/4', NOW() - INTERVAL '27 days'),
('usr_005', 'Aarav Patel', 'aarav.patel@kalpa.app', 'https://avatar.iran.liara.run/public/5', NOW() - INTERVAL '26 days'),
('usr_006', 'Diya Sen', 'diya.sen@kalpa.app', 'https://avatar.iran.liara.run/public/6', NOW() - INTERVAL '25 days'),
('usr_007', 'Rohan Mehta', 'rohan.mehta@kalpa.app', 'https://avatar.iran.liara.run/public/7', NOW() - INTERVAL '24 days'),
('usr_008', 'Ananya Gupta', 'ananya.gupta@kalpa.app', 'https://avatar.iran.liara.run/public/8', NOW() - INTERVAL '23 days'),
('usr_009', 'Vikram Rao', 'vikram.rao@kalpa.app', 'https://avatar.iran.liara.run/public/9', NOW() - INTERVAL '22 days'),
('usr_010', 'Neha Sharma', 'neha.sharma@kalpa.app', 'https://avatar.iran.liara.run/public/10', NOW() - INTERVAL '21 days'),
('usr_011', 'Aditya Verma', 'aditya.verma@kalpa.app', 'https://avatar.iran.liara.run/public/11', NOW() - INTERVAL '20 days'),
('usr_012', 'Pooja Nair', 'pooja.nair@kalpa.app', 'https://avatar.iran.liara.run/public/12', NOW() - INTERVAL '19 days'),
('usr_013', 'Siddharth Joshi', 'siddharth.joshi@kalpa.app', 'https://avatar.iran.liara.run/public/13', NOW() - INTERVAL '18 days'),
('usr_014', 'Kavita Pillai', 'kavita.pillai@kalpa.app', 'https://avatar.iran.liara.run/public/14', NOW() - INTERVAL '17 days'),
('usr_015', 'Rahul Desai', 'rahul.desai@kalpa.app', 'https://avatar.iran.liara.run/public/15', NOW() - INTERVAL '16 days'),
('usr_016', 'Sneha Kulkarni', 'sneha.kulkarni@kalpa.app', 'https://avatar.iran.liara.run/public/16', NOW() - INTERVAL '15 days'),
('usr_017', 'Karan Malhotra', 'karan.malhotra@kalpa.app', 'https://avatar.iran.liara.run/public/17', NOW() - INTERVAL '14 days'),
('usr_018', 'Tanvi Bhat', 'tanvi.bhat@kalpa.app', 'https://avatar.iran.liara.run/public/18', NOW() - INTERVAL '13 days'),
('usr_019', 'Arjun Saxena', 'arjun.saxena@kalpa.app', 'https://avatar.iran.liara.run/public/19', NOW() - INTERVAL '12 days'),
('usr_020', 'Isha Reddy', 'isha.reddy@kalpa.app', 'https://avatar.iran.liara.run/public/20', NOW() - INTERVAL '11 days'),
('usr_021', 'Rakesh Nair', 'rakesh.nair@kalpa.app', 'https://avatar.iran.liara.run/public/21', NOW() - INTERVAL '10 days'),
('usr_022', 'Meera Iyer', 'meera.iyer@kalpa.app', 'https://avatar.iran.liara.run/public/22', NOW() - INTERVAL '10 days'),
('usr_023', 'Varun Kapoor', 'varun.kapoor@kalpa.app', 'https://avatar.iran.liara.run/public/23', NOW() - INTERVAL '9 days'),
('usr_024', 'Shreya Banerjee', 'shreya.banerjee@kalpa.app', 'https://avatar.iran.liara.run/public/24', NOW() - INTERVAL '9 days'),
('usr_025', 'Harsh Vardhan', 'harsh.vardhan@kalpa.app', 'https://avatar.iran.liara.run/public/25', NOW() - INTERVAL '8 days'),
('usr_026', 'Ritika Singhania', 'ritika.singhania@kalpa.app', 'https://avatar.iran.liara.run/public/26', NOW() - INTERVAL '8 days'),
('usr_027', 'Akash Chopra', 'akash.chopra@kalpa.app', 'https://avatar.iran.liara.run/public/27', NOW() - INTERVAL '7 days'),
('usr_028', 'Simran Kaur', 'simran.kaur@kalpa.app', 'https://avatar.iran.liara.run/public/28', NOW() - INTERVAL '7 days'),
('usr_029', 'Gaurav Mishra', 'gaurav.mishra@kalpa.app', 'https://avatar.iran.liara.run/public/29', NOW() - INTERVAL '6 days'),
('usr_030', 'Anjali Nambiar', 'anjali.nambiar@kalpa.app', 'https://avatar.iran.liara.run/public/30', NOW() - INTERVAL '6 days'),
('usr_031', 'Devendra Yadav', 'devendra.yadav@kalpa.app', 'https://avatar.iran.liara.run/public/31', NOW() - INTERVAL '5 days'),
('usr_032', 'Pallavi Sen', 'pallavi.sen@kalpa.app', 'https://avatar.iran.liara.run/public/32', NOW() - INTERVAL '5 days'),
('usr_033', 'Kunal Trivedi', 'kunal.trivedi@kalpa.app', 'https://avatar.iran.liara.run/public/33', NOW() - INTERVAL '4 days'),
('usr_034', 'Ritu Agarwal', 'ritu.agarwal@kalpa.app', 'https://avatar.iran.liara.run/public/34', NOW() - INTERVAL '4 days'),
('usr_035', 'Manish Pandey', 'manish.pandey@kalpa.app', 'https://avatar.iran.liara.run/public/35', NOW() - INTERVAL '4 days'),
('usr_036', 'Geeta Bhatt', 'geeta.bhatt@kalpa.app', 'https://avatar.iran.liara.run/public/36', NOW() - INTERVAL '3 days'),
('usr_037', 'Suresh Kumar', 'suresh.kumar@kalpa.app', 'https://avatar.iran.liara.run/public/37', NOW() - INTERVAL '3 days'),
('usr_038', 'Swati Das', 'swati.das@kalpa.app', 'https://avatar.iran.liara.run/public/38', NOW() - INTERVAL '3 days'),
('usr_039', 'Naveen Jain', 'naveen.jain@kalpa.app', 'https://avatar.iran.liara.run/public/39', NOW() - INTERVAL '2 days'),
('usr_040', 'Rashmi Tiwari', 'rashmi.tiwari@kalpa.app', 'https://avatar.iran.liara.run/public/40', NOW() - INTERVAL '2 days'),
('usr_041', 'Deepak Chauhan', 'deepak.chauhan@kalpa.app', 'https://avatar.iran.liara.run/public/41', NOW() - INTERVAL '2 days'),
('usr_042', 'Bhavna Lal', 'bhavna.lal@kalpa.app', 'https://avatar.iran.liara.run/public/42', NOW() - INTERVAL '1 day'),
('usr_043', 'Sameer Saxena', 'sameer.saxena@kalpa.app', 'https://avatar.iran.liara.run/public/43', NOW() - INTERVAL '1 day'),
('usr_044', 'Divya Mohan', 'divya.mohan@kalpa.app', 'https://avatar.iran.liara.run/public/44', NOW() - INTERVAL '1 day'),
('usr_045', 'User Forty-Five', 'user45@kalpa.app', 'https://avatar.iran.liara.run/public/45', NOW() - INTERVAL '12 hours'),
('usr_046', 'Alok Ranjan', 'alok.ranjan@kalpa.app', 'https://avatar.iran.liara.run/public/46', NOW() - INTERVAL '10 hours'),
('usr_047', 'Kritika Roy', 'kritika.roy@kalpa.app', 'https://avatar.iran.liara.run/public/47', NOW() - INTERVAL '8 hours'),
('usr_048', 'Tarun Sethi', 'tarun.sethi@kalpa.app', 'https://avatar.iran.liara.run/public/48', NOW() - INTERVAL '6 hours'),
('usr_049', 'Vidya Menon', 'vidya.menon@kalpa.app', 'https://avatar.iran.liara.run/public/49', NOW() - INTERVAL '4 hours'),
('usr_050', 'Yashraj Singh', 'yashraj.singh@kalpa.app', 'https://avatar.iran.liara.run/public/50', NOW() - INTERVAL '2 hours')
ON CONFLICT (user_id) DO NOTHING;

-- 2. Insert Projects (Owners automatically synced to project_collaborators by trigger)
INSERT INTO projects (project_id, project_title, canvas_width, canvas_height, canvas_bg_color, owner_id, created_at, updated_at) VALUES
('proj_001', 'Kalpa Design System Project', 1920, 1080, '#1E1E1E', 'usr_001', NOW() - INTERVAL '20 days', NOW() - INTERVAL '1 hour'),
('proj_002', 'Mobile Banking UI Kit Project', 1440, 900, '#0F172A', 'usr_002', NOW() - INTERVAL '18 days', NOW() - INTERVAL '3 hours'),
('proj_003', 'Analytics Dashboard Wireframe Project', 2560, 1440, '#18181B', 'usr_001', NOW() - INTERVAL '15 days', NOW() - INTERVAL '5 hours'),
('proj_004', 'E-Commerce Marketplace Prototype', 1920, 1080, '#262626', 'usr_003', NOW() - INTERVAL '12 days', NOW() - INTERVAL '12 hours'),
('proj_005', 'Vector Illustration Kit', 1920, 1200, '#1F2937', 'usr_004', NOW() - INTERVAL '10 days', NOW() - INTERVAL '1 day'),
('proj_006', 'SaaS Onboarding Flow Project', 1440, 1024, '#111827', 'usr_001', NOW() - INTERVAL '8 days', NOW() - INTERVAL '2 days'),
('proj_007', 'Social Media Campaign Assets', 1080, 1080, '#0A0A0A', 'usr_002', NOW() - INTERVAL '6 days', NOW() - INTERVAL '2 days'),
('proj_008', 'Design Tokens & Typography Specs', 1920, 1080, '#18181B', 'usr_003', NOW() - INTERVAL '4 days', NOW() - INTERVAL '1 day')
ON CONFLICT (project_id) DO NOTHING;

-- 3. Insert Additional Collaborators (Note: owner rows already inserted by trigger)
INSERT INTO project_collaborators (project_id, user_id, role_name, joined_at) VALUES
('proj_001', 'usr_002', 'editor', NOW() - INTERVAL '19 days'),
('proj_001', 'usr_003', 'editor', NOW() - INTERVAL '19 days'),
('proj_001', 'usr_004', 'viewer', NOW() - INTERVAL '18 days'),
('proj_001', 'usr_005', 'viewer', NOW() - INTERVAL '17 days'),
('proj_001', 'usr_006', 'viewer', NOW() - INTERVAL '16 days'),
('proj_001', 'usr_007', 'editor', NOW() - INTERVAL '15 days'),
('proj_002', 'usr_001', 'editor', NOW() - INTERVAL '17 days'),
('proj_002', 'usr_003', 'editor', NOW() - INTERVAL '17 days'),
('proj_002', 'usr_004', 'viewer', NOW() - INTERVAL '16 days'),
('proj_003', 'usr_002', 'editor', NOW() - INTERVAL '14 days'),
('proj_003', 'usr_003', 'editor', NOW() - INTERVAL '14 days'),
('proj_003', 'usr_004', 'viewer', NOW() - INTERVAL '13 days'),
('proj_004', 'usr_001', 'editor', NOW() - INTERVAL '11 days'),
('proj_004', 'usr_002', 'viewer', NOW() - INTERVAL '10 days'),
('proj_005', 'usr_001', 'editor', NOW() - INTERVAL '9 days'),
('proj_005', 'usr_002', 'editor', NOW() - INTERVAL '9 days'),
('proj_005', 'usr_003', 'viewer', NOW() - INTERVAL '8 days')
ON CONFLICT (project_id, user_id) DO UPDATE SET role_name = EXCLUDED.role_name;

-- 4. Insert 50 Canvas Elements (35 on proj_001, 15 across others)
INSERT INTO canvas_elements (
    element_id, project_id, shape_type, pos_x, pos_y, width, height, scale_x, scale_y,
    rotation, opacity, fill_color, stroke_color, stroke_width, z_index, text_content,
    image_url, custom_properties, creator_id, created_at, updated_at
) VALUES
('elem_0001', 'proj_001', 'rect', 100.00, 100.00, 400.00, 300.00, 1.00, 1.00, 0.00, 1.00, '#3B82F6', '#1D4ED8', 2.00, 1, NULL, NULL, '{"isLocked": true, "name": "HeaderFrame"}'::jsonb, 'usr_001', NOW() - INTERVAL '15 days', NOW() - INTERVAL '10 days'),
('elem_0002', 'proj_001', 'circle', 250.00, 200.00, 120.00, 120.00, 1.00, 1.00, 0.00, 0.90, '#10B981', '#047857', 1.50, 2, NULL, NULL, '{"isLocked": false, "name": "AvatarCircle"}'::jsonb, 'usr_002', NOW() - INTERVAL '15 days', NOW() - INTERVAL '9 days'),
('elem_0003', 'proj_001', 'triangle', 450.00, 150.00, 100.00, 80.00, 1.00, 1.00, 45.00, 1.00, '#F59E0B', '#B45309', 1.00, 3, NULL, NULL, '{"isLocked": false, "name": "PlayIcon"}'::jsonb, 'usr_003', NOW() - INTERVAL '14 days', NOW() - INTERVAL '8 days'),
('elem_0004', 'proj_001', 'text', 120.00, 120.00, 200.00, 40.00, 1.00, 1.00, 0.00, 1.00, '#FFFFFF', '#000000', 0.00, 4, 'Welcome to Kalpa', NULL, '{"fontSize": 24, "fontWeight": "bold"}'::jsonb, 'usr_001', NOW() - INTERVAL '14 days', NOW() - INTERVAL '7 days'),
('elem_0005', 'proj_001', 'rect', 600.00, 100.00, 350.00, 500.00, 1.00, 1.00, 0.00, 1.00, '#1E293B', '#334155', 1.00, 5, NULL, NULL, '{"isLocked": true, "name": "SidebarContainer"}'::jsonb, 'usr_001', NOW() - INTERVAL '13 days', NOW() - INTERVAL '6 days'),
('elem_0006', 'proj_001', 'circle', 700.00, 180.00, 80.00, 80.00, 1.00, 1.00, 0.00, 0.95, '#8B5CF6', '#6D28D9', 2.00, 6, NULL, NULL, '{"isLocked": false, "name": "StatusIndicator"}'::jsonb, 'usr_002', NOW() - INTERVAL '13 days', NOW() - INTERVAL '6 days'),
('elem_0007', 'proj_001', 'path', 150.00, 450.00, 200.00, 100.00, 1.00, 1.00, 0.00, 1.00, NULL, '#EF4444', 3.00, 7, NULL, NULL, '{"pathData": "M10 80 Q 95 10 180 80"}'::jsonb, 'usr_003', NOW() - INTERVAL '12 days', NOW() - INTERVAL '5 days'),
('elem_0008', 'proj_001', 'text', 620.00, 140.00, 180.00, 30.00, 1.00, 1.00, 0.00, 1.00, '#94A3B8', '#000000', 0.00, 8, 'Components Library', NULL, '{"fontSize": 18}'::jsonb, 'usr_001', NOW() - INTERVAL '12 days', NOW() - INTERVAL '5 days'),
('elem_0009', 'proj_001', 'rect', 1000.00, 100.00, 500.00, 350.00, 1.00, 1.00, 0.00, 1.00, '#0F172A', '#1E293B', 1.00, 9, NULL, NULL, '{"isLocked": true, "name": "CanvasHero"}'::jsonb, 'usr_001', NOW() - INTERVAL '11 days', NOW() - INTERVAL '4 days'),
('elem_0010', 'proj_001', 'image', 1050.00, 150.00, 400.00, 250.00, 1.00, 1.00, 0.00, 1.00, NULL, '#000000', 0.00, 10, NULL, 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe', '{"name": "HeroBanner"}'::jsonb, 'usr_004', NOW() - INTERVAL '11 days', NOW() - INTERVAL '4 days'),
('elem_0011', 'proj_001', 'rect', 100.00, 650.00, 250.00, 120.00, 1.00, 1.00, 0.00, 1.00, '#38BDF8', '#0284C7', 1.00, 11, NULL, NULL, '{"isLocked": false, "name": "MetricCard1"}'::jsonb, 'usr_002', NOW() - INTERVAL '10 days', NOW() - INTERVAL '3 days'),
('elem_0012', 'proj_001', 'rect', 380.00, 650.00, 250.00, 120.00, 1.00, 1.00, 0.00, 1.00, '#34D399', '#059669', 1.00, 12, NULL, NULL, '{"isLocked": false, "name": "MetricCard2"}'::jsonb, 'usr_002', NOW() - INTERVAL '10 days', NOW() - INTERVAL '3 days'),
('elem_0013', 'proj_001', 'rect', 660.00, 650.00, 250.00, 120.00, 1.00, 1.00, 0.00, 1.00, '#F472B6', '#DB2777', 1.00, 13, NULL, NULL, '{"isLocked": false, "name": "MetricCard3"}'::jsonb, 'usr_002', NOW() - INTERVAL '9 days', NOW() - INTERVAL '3 days'),
('elem_0014', 'proj_001', 'circle', 200.00, 710.00, 40.00, 40.00, 1.00, 1.00, 0.00, 0.85, '#E0F2FE', '#0284C7', 1.00, 14, NULL, NULL, '{"isLocked": false}'::jsonb, 'usr_003', NOW() - INTERVAL '9 days', NOW() - INTERVAL '2 days'),
('elem_0015', 'proj_001', 'circle', 480.00, 710.00, 40.00, 40.00, 1.00, 1.00, 0.00, 0.85, '#D1FAE5', '#059669', 1.00, 15, NULL, NULL, '{"isLocked": false}'::jsonb, 'usr_003', NOW() - INTERVAL '9 days', NOW() - INTERVAL '2 days'),
('elem_0016', 'proj_001', 'circle', 760.00, 710.00, 40.00, 40.00, 1.00, 1.00, 0.00, 0.85, '#FCE7F3', '#DB2777', 1.00, 16, NULL, NULL, '{"isLocked": false}'::jsonb, 'usr_003', NOW() - INTERVAL '8 days', NOW() - INTERVAL '2 days'),
('elem_0017', 'proj_001', 'triangle', 1100.00, 500.00, 120.00, 100.00, 1.00, 1.00, 90.00, 1.00, '#A78BFA', '#7C3AED', 1.00, 17, NULL, NULL, '{"isLocked": false}'::jsonb, 'usr_001', NOW() - INTERVAL '8 days', NOW() - INTERVAL '2 days'),
('elem_0018', 'proj_001', 'rect', 1250.00, 500.00, 300.00, 180.00, 1.00, 1.00, 0.00, 1.00, '#FCD34D', '#D97706', 2.00, 18, NULL, NULL, '{"isLocked": true, "name": "WarningBox"}'::jsonb, 'usr_002', NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'),
('elem_0019', 'proj_001', 'text', 1270.00, 520.00, 260.00, 60.00, 1.00, 1.00, 0.00, 1.00, '#78350F', '#000000', 0.00, 19, 'Caution: Live Collaboration', NULL, '{"fontSize": 16}'::jsonb, 'usr_002', NOW() - INTERVAL '7 days', NOW() - INTERVAL '1 day'),
('elem_0020', 'proj_001', 'path', 500.00, 820.00, 300.00, 50.00, 1.00, 1.00, 0.00, 1.00, NULL, '#64748B', 2.00, 20, NULL, NULL, '{"pathData": "M0 25 L300 25"}'::jsonb, 'usr_004', NOW() - INTERVAL '6 days', NOW() - INTERVAL '1 day'),
('elem_0021', 'proj_001', 'rect', 100.00, 820.00, 180.00, 60.00, 1.00, 1.00, 0.00, 1.00, '#2563EB', '#1D4ED8', 1.00, 21, NULL, NULL, '{"isLocked": false, "name": "PrimaryBtn"}'::jsonb, 'usr_001', NOW() - INTERVAL '6 days', NOW() - INTERVAL '18 hours'),
('elem_0022', 'proj_001', 'text', 130.00, 840.00, 120.00, 30.00, 1.00, 1.00, 0.00, 1.00, '#FFFFFF', '#000000', 0.00, 22, 'Deploy App', NULL, '{"fontSize": 14, "fontWeight": "600"}'::jsonb, 'usr_001', NOW() - INTERVAL '5 days', NOW() - INTERVAL '18 hours'),
('elem_0023', 'proj_001', 'rect', 300.00, 820.00, 180.00, 60.00, 1.00, 1.00, 0.00, 1.00, '#475569', '#334155', 1.00, 23, NULL, NULL, '{"isLocked": false, "name": "SecondaryBtn"}'::jsonb, 'usr_003', NOW() - INTERVAL '5 days', NOW() - INTERVAL '16 hours'),
('elem_0024', 'proj_001', 'text', 340.00, 840.00, 100.00, 30.00, 1.00, 1.00, 0.00, 1.00, '#F1F5F9', '#000000', 0.00, 24, 'Cancel', NULL, '{"fontSize": 14}'::jsonb, 'usr_003', NOW() - INTERVAL '5 days', NOW() - INTERVAL '16 hours'),
('elem_0025', 'proj_001', 'circle', 920.00, 700.00, 90.00, 90.00, 1.00, 1.00, 0.00, 0.90, '#EC4899', '#BE185D', 2.00, 25, NULL, NULL, '{"isLocked": false, "name": "FabButton"}'::jsonb, 'usr_002', NOW() - INTERVAL '4 days', NOW() - INTERVAL '12 hours'),
('elem_0026', 'proj_001', 'rect', 300.00, 400.00, 200.00, 140.00, 1.00, 1.00, 0.00, 1.00, '#06B6D4', '#0891B2', 1.00, 26, NULL, NULL, '{"isLocked": false, "name": "InspectMeShape"}'::jsonb, 'usr_001', NOW() - INTERVAL '4 days', NOW() - INTERVAL '10 hours'),
('elem_0027', 'proj_001', 'triangle', 850.00, 350.00, 110.00, 90.00, 1.00, 1.00, 180.00, 1.00, '#F97316', '#C2410C', 1.50, 27, NULL, NULL, '{"isLocked": false}'::jsonb, 'usr_004', NOW() - INTERVAL '4 days', NOW() - INTERVAL '8 hours'),
('elem_0028', 'proj_001', 'path', 1050.00, 720.00, 250.00, 80.00, 1.00, 1.00, 0.00, 1.00, NULL, '#10B981', 2.50, 28, NULL, NULL, '{"pathData": "M10 10 C 20 20, 40 20, 50 10"}'::jsonb, 'usr_003', NOW() - INTERVAL '3 days', NOW() - INTERVAL '6 hours'),
('elem_0029', 'proj_001', 'text', 1050.00, 810.00, 220.00, 35.00, 1.00, 1.00, 0.00, 1.00, '#E2E8F0', '#000000', 0.00, 29, 'Smooth Curve Vector', NULL, '{"fontSize": 15}'::jsonb, 'usr_003', NOW() - INTERVAL '3 days', NOW() - INTERVAL '5 hours'),
('elem_0030', 'proj_001', 'rect', 1400.00, 700.00, 180.00, 180.00, 1.00, 1.00, 15.00, 0.85, '#6366F1', '#4338CA', 2.00, 30, NULL, NULL, '{"isLocked": false, "name": "AngledCard"}'::jsonb, 'usr_002', NOW() - INTERVAL '2 days', NOW() - INTERVAL '4 hours'),
('elem_0031', 'proj_001', 'circle', 1450.00, 750.00, 80.00, 80.00, 1.00, 1.00, 0.00, 1.00, '#F43F5E', '#BE123C', 1.00, 31, NULL, NULL, '{"isLocked": false}'::jsonb, 'usr_001', NOW() - INTERVAL '2 days', NOW() - INTERVAL '3 hours'),
('elem_0032', 'proj_001', 'triangle', 1600.00, 150.00, 140.00, 120.00, 1.00, 1.00, 0.00, 0.95, '#EAB308', '#A16207', 1.00, 32, NULL, NULL, '{"isLocked": true, "name": "GoldPyramid"}'::jsonb, 'usr_004', NOW() - INTERVAL '1 day', NOW() - INTERVAL '2 hours'),
('elem_0033', 'proj_001', 'text', 1620.00, 290.00, 120.00, 30.00, 1.00, 1.00, 0.00, 1.00, '#FEF08A', '#000000', 0.00, 33, 'Pyramid Text', NULL, '{"fontSize": 13}'::jsonb, 'usr_004', NOW() - INTERVAL '1 day', NOW() - INTERVAL '2 hours'),
('elem_0034', 'proj_001', 'rect', 1600.00, 400.00, 200.00, 200.00, 1.00, 1.00, 0.00, 1.00, '#14B8A6', '#0F766E', 2.00, 34, NULL, NULL, '{"isLocked": false, "name": "TealWidget"}'::jsonb, 'usr_001', NOW() - INTERVAL '18 hours', NOW() - INTERVAL '1 hour'),
('elem_0050', 'proj_001', 'rect', 1700.00, 800.00, 150.00, 150.00, 1.00, 1.00, 0.00, 0.70, '#9CA3AF', '#4B5563', 1.00, 50, NULL, NULL, '{"isLocked": false, "name": "TempToDelete"}'::jsonb, 'usr_003', NOW() - INTERVAL '12 hours', NOW() - INTERVAL '30 mins'),

-- Other elements on other projects
('elem_0035', 'proj_002', 'rect', 50.00, 50.00, 375.00, 812.00, 1.00, 1.00, 0.00, 1.00, '#FFFFFF', '#E2E8F0', 1.00, 1, NULL, NULL, '{"isLocked": true, "name": "iPhoneFrame"}'::jsonb, 'usr_002', NOW() - INTERVAL '17 days', NOW() - INTERVAL '3 days'),
('elem_0036', 'proj_002', 'text', 80.00, 100.00, 250.00, 40.00, 1.00, 1.00, 0.00, 1.00, '#0F172A', '#000000', 0.00, 2, 'Total Balance: $24,500', NULL, '{"fontSize": 20, "fontWeight": "bold"}'::jsonb, 'usr_002', NOW() - INTERVAL '17 days', NOW() - INTERVAL '3 days'),
('elem_0037', 'proj_002', 'rect', 80.00, 160.00, 315.00, 180.00, 1.00, 1.00, 0.00, 1.00, '#1E40AF', '#1D4ED8', 1.00, 3, NULL, NULL, '{"name": "DebitCard"}'::jsonb, 'usr_001', NOW() - INTERVAL '16 days', NOW() - INTERVAL '2 days'),
('elem_0038', 'proj_003', 'rect', 100.00, 100.00, 1200.00, 800.00, 1.00, 1.00, 0.00, 1.00, '#18181B', '#27272A', 1.00, 1, NULL, NULL, '{"isLocked": true}'::jsonb, 'usr_001', NOW() - INTERVAL '14 days', NOW() - INTERVAL '5 days'),
('elem_0039', 'proj_003', 'path', 200.00, 200.00, 600.00, 300.00, 1.00, 1.00, 0.00, 1.00, NULL, '#10B981', 3.00, 2, NULL, NULL, '{"chartType": "line"}'::jsonb, 'usr_003', NOW() - INTERVAL '13 days', NOW() - INTERVAL '4 days'),
('elem_0040', 'proj_004', 'rect', 50.00, 50.00, 1200.00, 200.00, 1.00, 1.00, 0.00, 1.00, '#F8FAFC', '#CBD5E1', 1.00, 1, NULL, NULL, '{"name": "ProductGrid"}'::jsonb, 'usr_003', NOW() - INTERVAL '11 days', NOW() - INTERVAL '2 days')
ON CONFLICT (element_id) DO NOTHING;

-- 5. Insert Pinned Comments
INSERT INTO comment_pins (comment_id, project_id, pin_x, pin_y, status, creator_id, created_at) VALUES
('comm_001', 'proj_001', 320.00, 150.00, 'open', 'usr_001', NOW() - INTERVAL '5 days'),
('comm_002', 'proj_001', 650.00, 200.00, 'open', 'usr_002', NOW() - INTERVAL '4 days'),
('comm_003', 'proj_001', 1080.00, 180.00, 'resolved', 'usr_003', NOW() - INTERVAL '3 days'),
('comm_004', 'proj_001', 400.00, 700.00, 'open', 'usr_004', NOW() - INTERVAL '2 days'),
('comm_005', 'proj_001', 1300.00, 550.00, 'open', 'usr_002', NOW() - INTERVAL '1 day'),
('comm_006', 'proj_002', 150.00, 180.00, 'open', 'usr_001', NOW() - INTERVAL '2 days'),
('comm_007', 'proj_003', 300.00, 300.00, 'resolved', 'usr_003', NOW() - INTERVAL '1 day')
ON CONFLICT (comment_id) DO NOTHING;

-- 6. Insert Comment Replies
INSERT INTO comment_replies (reply_id, comment_id, author_id, message_text, created_at) VALUES
('reply_001', 'comm_001', 'usr_002', 'Should we update the primary button color to Indigo-600?', NOW() - INTERVAL '4 days 22 hours'),
('reply_002', 'comm_001', 'usr_001', 'Agreed, indigo fits better with our dark canvas background.', NOW() - INTERVAL '4 days 20 hours'),
('reply_003', 'comm_001', 'usr_003', 'I will update the design tokens accordingly.', NOW() - INTERVAL '4 days 18 hours'),
('reply_004', 'comm_002', 'usr_001', 'Check alignment with the grid system on the left panel.', NOW() - INTERVAL '3 days 12 hours'),
('reply_005', 'comm_002', 'usr_002', 'Fixed! It now snaps perfectly to 8px increments.', NOW() - INTERVAL '3 days 10 hours'),
('reply_006', 'comm_003', 'usr_004', 'High-res image asset has been uploaded and linked.', NOW() - INTERVAL '2 days 14 hours'),
('reply_007', 'comm_004', 'usr_002', 'The metric card contrast meets WCAG AAA standards.', NOW() - INTERVAL '1 day 16 hours'),
('reply_008', 'comm_005', 'usr_001', 'Let us review this section during the sprint sync.', NOW() - INTERVAL '18 hours')
ON CONFLICT (reply_id) DO NOTHING;
