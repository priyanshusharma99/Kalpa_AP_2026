#!/usr/bin/env python3
"""Rollback-only regression checks. Run on an isolated, freshly seeded database.
Requires psycopg2; accepts a database name/connection string, honours PG* env.
"""
import importlib.util
from pathlib import Path
import random
import math
import sys

try:
    import psycopg2
except ImportError:
    raise SystemExit('Install psycopg2 in your Python environment before running these checks.')

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('benchmark', ROOT / 'benchmark.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
QUERIES = {qid: sql for qid, _, sql in module.workloads()}
database = sys.argv[1] if len(sys.argv) > 1 else 'kalpa_db'
connection = psycopg2.connect(database if '=' in database else '', **({} if '=' in database else {'dbname': database}))
passed = 0


def execute(sql, params=None):
    with connection.cursor() as cursor:
        cursor.execute(sql, params)
        return cursor.fetchall() if cursor.description else cursor.rowcount


def invariant():
    assert execute("""SELECT p.project_id FROM projects p
        LEFT JOIN project_collaborators pc ON p.project_id=pc.project_id AND pc.role_name='owner'
        GROUP BY p.project_id HAVING COUNT(pc.user_id) <> 1 OR MIN(pc.user_id) <> MIN(p.owner_id);""") == []


def rejected(sql, fragment):
    execute('SAVEPOINT expected_failure')
    try:
        execute(sql)
    except psycopg2.Error as error:
        execute('ROLLBACK TO SAVEPOINT expected_failure')
        assert fragment in str(error), str(error)
    else:
        raise AssertionError('Statement unexpectedly succeeded: ' + sql)


def check(label, fn):
    global passed
    connection.rollback()
    try:
        fn()
        invariant()
        passed += 1
        print('PASS:', label, flush=True)
    finally:
        connection.rollback()


def owner_protection():
    rejected("DELETE FROM project_collaborators WHERE project_id='proj_001' AND user_id='usr_001'", 'Cannot remove')
    rejected("UPDATE project_collaborators SET role_name='editor' WHERE project_id='proj_001' AND user_id='usr_001'", 'Cannot demote')
    rejected("UPDATE project_collaborators SET user_id='usr_045' WHERE project_id='proj_001' AND user_id='usr_001'", 'non-owner')
    rejected("UPDATE project_collaborators SET role_name='owner' WHERE project_id='proj_001' AND user_id='usr_003'", 'non-owner')
    execute("INSERT INTO projects(project_id,owner_id) VALUES ('test_destination','usr_003')")
    for role in ('editor', 'viewer', 'owner'):
        rejected(f"UPDATE project_collaborators SET project_id='test_destination',role_name='{role}' WHERE project_id='proj_001' AND user_id='usr_001'", 'Cannot change project_id')
    execute("INSERT INTO project_collaborators(project_id,user_id,role_name) VALUES('proj_001','usr_045','viewer')")
    assert execute("UPDATE project_collaborators SET project_id='test_destination' WHERE project_id='proj_001' AND user_id='usr_045'") == 1


def owner_transfer():
    assert execute(QUERIES['W10']) == 1
    assert execute("SELECT owner_id FROM projects WHERE project_id='proj_001'") == [('usr_002',)]
    assert execute("SELECT user_id,role_name FROM project_collaborators WHERE project_id='proj_001' AND user_id IN ('usr_001','usr_002') ORDER BY user_id") == [('usr_001','editor'),('usr_002','owner')]
    execute("UPDATE projects SET owner_id='usr_045' WHERE project_id='proj_001'")
    assert execute("SELECT role_name FROM project_collaborators WHERE project_id='proj_001' AND user_id='usr_045'") == [('owner',)]


def cascade_project():
    execute("DELETE FROM projects WHERE project_id='proj_001'")
    for table in ('project_collaborators','canvas_elements','comment_pins'):
        assert execute(f"SELECT COUNT(*) FROM {table} WHERE project_id='proj_001'") == [(0,)]
    assert execute("SELECT COUNT(*) FROM comment_replies WHERE comment_id='comm_001'") == [(0,)]


def cascade_owner():
    execute("DELETE FROM users WHERE user_id='usr_001'")
    assert execute("SELECT COUNT(*) FROM projects WHERE owner_id='usr_001'") == [(0,)]


def deleted_authors():
    before = {qid: execute(QUERIES[qid]) for qid in ('R08','R11','R12','R13','R14','A04')}
    execute("DELETE FROM users WHERE user_id='usr_004'")
    for qid, rows in before.items():
        after = execute(QUERIES[qid])
        assert {r[0] for r in after} == {r[0] for r in rows}, qid + ' lost content'
    assert execute("SELECT creator_id FROM comment_pins WHERE comment_id='comm_004'") == [(None,)]
    assert execute("SELECT author_id FROM comment_replies WHERE reply_id='reply_006'") == [(None,)]


def full_snapshot():
    sql = QUERIES['W09']
    assert execute(sql) == 1
    fields = 'project_id,shape_type,pos_x,pos_y,width,height,scale_x,scale_y,rotation,opacity,fill_color,stroke_color,stroke_width,z_index,text_content,image_url,custom_properties,creator_id,created_at'
    expected = execute(f"SELECT {fields} FROM canvas_elements WHERE element_id='elem_upsert_01'")
    execute("""UPDATE canvas_elements SET shape_type='text',pos_x=1,pos_y=2,width=3,height=4,
        scale_x=2,scale_y=3,rotation=90,opacity=0.1,fill_color='#FFFFFF',stroke_color='#FFFFFF',
        stroke_width=9,z_index=99,text_content='old',image_url='https://example.com/old.png',
        custom_properties='{"old":true}'::jsonb WHERE element_id='elem_upsert_01'""")
    assert execute(sql) == 1
    assert execute(f"SELECT {fields} FROM canvas_elements WHERE element_id='elem_upsert_01'") == expected
    execute("UPDATE canvas_elements SET project_id='proj_002' WHERE element_id='elem_upsert_01'")
    assert execute(sql) == 0, 'Cross-project collision was accepted'
    assert execute("SELECT project_id FROM canvas_elements WHERE element_id='elem_upsert_01'") == [('proj_002',)]


def viewport():
    # Independent oracle: rotate all four scaled, stroke-expanded corners.
    fixtures = [(-150,500,100,100,4,1,0,0),(-40,500,20,200,1,1,90,0),
                (-150,500,100,100,1,1,0,0),(-11,500,20,20,1,1,0,4),
                (-50,500,100,100,1,1,0,0),(2200,500,100,100,1,1,0,0)]
    rng = random.Random(13)
    for _ in range(75):
        fixtures.append((rng.randint(-500,2400),rng.randint(-500,1500),rng.randint(0,400),rng.randint(0,400),rng.choice([0.5,1,2,4]),rng.choice([0.5,1,2,4]),rng.choice([0,15,45,90,135,180,270,359]),rng.choice([0,1,8])))
    expected = set()
    for i,(px,py,w,h,sx,sy,angle,stroke) in enumerate(fixtures):
        id = f'test_bounds_{i:03}'
        execute("""INSERT INTO canvas_elements(element_id,project_id,shape_type,pos_x,pos_y,width,height,scale_x,scale_y,rotation,stroke_width)
            VALUES (%s,'proj_001','rect',%s,%s,%s,%s,%s,%s,%s,%s)""", (id,px,py,w,h,sx,sy,angle,stroke))
        a=math.radians(angle)
        corners=[(px+x*math.cos(a)-y*math.sin(a),py+x*math.sin(a)+y*math.cos(a))
                 for x in (-(w+stroke)*sx/2,(w+stroke)*sx/2)
                 for y in (-(h+stroke)*sy/2,(h+stroke)*sy/2)]
        if min(x for x,y in corners)<=1920+1e-8 and max(x for x,y in corners)>=-1e-8 and min(y for x,y in corners)<=1080+1e-8 and max(y for x,y in corners)>=-1e-8:
            expected.add(id)
    actual = {row[0] for row in execute(QUERIES['A01']) if row[0].startswith('test_bounds_')}
    assert actual == expected, (actual ^ expected)


def membership_serialization():
    # A membership write locks its project; a concurrent owner transfer must wait.
    execute("INSERT INTO project_collaborators(project_id,user_id) VALUES('proj_001','usr_045')")
    other = psycopg2.connect(database if '=' in database else '', **({} if '=' in database else {'dbname': database}))
    try:
        with other.cursor() as c:
            c.execute("SET LOCAL lock_timeout='250ms'")
            try:
                c.execute(QUERIES['W10'])
            except psycopg2.errors.LockNotAvailable:
                other.rollback()
            else:
                raise AssertionError('Ownership update bypassed membership parent lock')
        connection.rollback()
        with other.cursor() as c:
            c.execute(QUERIES['W10'])
            assert c.rowcount == 1
    finally:
        other.rollback()
        other.close()


try:
    check('seed ownership invariant', invariant)
    check('owner removal/demotion/reassignment and cross-project move protection', owner_protection)
    check('ownership transfer to existing and new collaborator', owner_transfer)
    check('project deletion cascades through comments and replies', cascade_project)
    check('owner-account deletion cascades without trigger failure', cascade_owner)
    check('deleted authors retain shapes, pins and replies in display queries', deleted_authors)
    check('complete snapshot update and cross-project collision guard', full_snapshot)
    check('81 viewport fixtures against independent transformed-corner oracle', viewport)
    check('concurrent membership writes serialize with owner transfer', membership_serialization)
    print(f'{passed} regression groups passed; test writes rolled back.')
finally:
    connection.rollback()
    connection.close()
