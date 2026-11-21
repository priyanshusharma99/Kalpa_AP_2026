#!/usr/bin/env python3
"""Generate the editable ER SVG directly from 03_schema.sql (standard library)."""
from html import escape
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent
schema = (ROOT / '03_schema.sql').read_text()
tables = {}
for name, body in re.findall(r'CREATE TABLE (\w+) \((.*?)\n\);', schema, re.S):
    columns = []
    for line in body.splitlines():
        m = re.match(r'\s*(\w+) (VARCHAR\(\d+\)|NUMERIC\(\d+,\s*\d+\)|TIMESTAMPTZ|BOOLEAN|JSONB|TEXT|INT)(.*)', line)
        if m:
            col, typ, rest = m.groups()
            columns.append((col, typ, rest))
    tables[name] = columns

positions = {
    'role_permissions': (50, 110, 550), 'users': (850, 110, 540),
    'project_collaborators': (50, 560, 600), 'projects': (850, 560, 540),
    'canvas_elements': (1750, 110, 600), 'comment_pins': (850, 1160, 540),
    'comment_replies': (1750, 1160, 600),
}
foreign = {('projects','owner_id'), ('project_collaborators','project_id'), ('project_collaborators','user_id'), ('project_collaborators','role_name'), ('canvas_elements','project_id'), ('canvas_elements','creator_id'), ('comment_pins','project_id'), ('comment_pins','creator_id'), ('comment_replies','comment_id'), ('comment_replies','author_id')}
svg = ['<svg xmlns="http://www.w3.org/2000/svg" width="2400" height="1960" viewBox="0 0 2400 1960">',
       '<rect width="2400" height="1960" fill="#0f172a"/>',
       '<style>text{font-family:Arial,sans-serif;fill:#e2e8f0}.title{font-size:32px;font-weight:bold}.small{font-size:17px}.col{font-size:19px}.type{font-size:17px;fill:#cbd5e1}.edge{fill:none;stroke:#38bdf8;stroke-width:3}.tag{font-size:19px;font-weight:bold;fill:#7dd3fc;paint-order:stroke;stroke:#0f172a;stroke-width:6px}</style>',
       '<text x="50" y="54" class="title">Kalpa — Relational ER Diagram</text>',
       '<text x="50" y="85" class="small">PostgreSQL • 7 entities • 10 foreign keys • columns generated from 03_schema.sql</text>']

def text(x,y,value,cls='small'):
    svg.append(f'<text x="{x}" y="{y}" class="{cls}">{escape(value)}</text>')

def edge(path, x, y, label, optional=False):
    svg.append(f'<path class="edge" d="{path}"' + (' stroke-dasharray="9 6"' if optional else '') + '/>')
    text(x,y,label,'tag')

# Edges connect table boundaries; exact columns, optionality and FK actions are
# enumerated below so crossings never imply a relationship or hide an FK.
edge('M850 210 H700 V610 H650',680,400,'L1')
edge('M325 356 V560',340,475,'L2')
edge('M850 680 H650',718,666,'L3')
edge('M1100 392 V560',1115,490,'L4')
edge('M1390 200 H1750',1555,185,'L5',True)
edge('M1390 760 H1550 V850 H1750',1570,835,'L6')
edge('M1390 300 H1630 V1220 H1750',1645,1080,'L7',True)
edge('M1250 392 V455 H1460 V1080 H1250 V1160',1475,1030,'L8',True)
edge('M1100 914 V1160',1115,1125,'L9')
edge('M1390 1330 H1750',1555,1315,'L10')

for name, columns in tables.items():
    x,y,w = positions[name]
    height = 66 + 36*len(columns)
    svg.append(f'<rect x="{x}" y="{y}" width="{w}" height="{height}" rx="12" fill="#1e293b" stroke="#475569" stroke-width="2"/>')
    svg.append(f'<path d="M{x+12} {y} H{x+w-12} Q{x+w} {y} {x+w} {y+12} V{y+48} H{x} V{y+12} Q{x} {y} {x+12} {y}" fill="#1d4ed8"/>')
    text(x+18,y+32,name,'col')
    for i,(col,typ,rest) in enumerate(columns):
        yy=y+77+i*36
        if i%2==0:
            svg.append(f'<rect x="{x+2}" y="{yy-25}" width="{w-4}" height="35" fill="#24344c"/>')
        pk = 'PRIMARY KEY' in rest or (name=='project_collaborators' and col in ('project_id','user_id'))
        fk = (name,col) in foreign
        nullable = 'NOT NULL' not in rest and not pk
        key='/'.join(v for v,yes in [('PK',pk),('FK',fk),('UQ','UNIQUE' in rest)] if yes)
        text(x+12,yy,key,'type')
        text(x+100,yy,col,'col')
        # Type on its own small second line would increase height; concise right label.
        svg.append(f'<text x="{x+w-12}" y="{yy}" text-anchor="end" class="type">{escape(typ.replace(" ",""))}{" ?" if nullable else ""}</text>')

# Explanatory card in the open left column.
svg.append('<rect x="50" y="900" width="650" height="580" rx="12" fill="#1e293b" stroke="#475569"/>')
text(75,940,'Notation and invariants','col')
lines = [
    '? = nullable; PK = primary key; FK = foreign key.',
    'UQ = unique. Dashed links have nullable user FKs.',
    'Line crossings are not junctions; use L1–L10 below.',
    '',
    'A project always has exactly one owner membership.',
    'Partial unique index permits at most one owner;',
    'sync/protection triggers maintain the matching owner.',
    'Owner transfer demotes the prior owner to editor.',
    '',
    'Content survives author deletion with a NULL author.',
    'Deleting a project cascades to its content/members.',
    '',
    'Element positions are centres; A01 includes scale,',
    'rotation and a centred scaling stroke in its bounds.',
]
for i,line in enumerate(lines): text(75,980+i*33,line)

svg.append('<rect x="50" y="1530" width="2300" height="390" rx="12" fill="#1e293b" stroke="#475569"/>')
text(75,1570,'Foreign-key relationships and cardinality (per row at each end)','col')
relationships = [
 ('L1','users → project_collaborators.user_id','1 user per membership; 0..N memberships per user','CASCADE'),
 ('L2','role_permissions → project_collaborators.role_name','1 role per membership; 0..N memberships per role','RESTRICT; UPDATE CASCADE'),
 ('L3','projects → project_collaborators.project_id','1 project per membership; 1..N memberships per project','CASCADE'),
 ('L4','users → projects.owner_id','1 owner per project; 0..N owned projects per user','CASCADE'),
 ('L5','users → canvas_elements.creator_id','0..1 creator per element; 0..N elements per user','SET NULL'),
 ('L6','projects → canvas_elements.project_id','1 project per element; 0..N elements per project','CASCADE'),
 ('L7','users → comment_replies.author_id','0..1 author per reply; 0..N replies per user','SET NULL'),
 ('L8','users → comment_pins.creator_id','0..1 creator per pin; 0..N pins per user','SET NULL'),
 ('L9','projects → comment_pins.project_id','1 project per pin; 0..N pins per project','CASCADE'),
 ('L10','comment_pins → comment_replies.comment_id','1 pin per reply; 0..N replies per pin','CASCADE'),
]
for i,(label,rel,card,action) in enumerate(relationships):
    yy=1607+i*29
    text(75,yy,label,'tag'); text(145,yy,rel); text(820,yy,card); text(1740,yy,'DELETE '+action)
text(75,1900,'All other FK updates: NO ACTION. Nullable author/creator relations preserve content; timestamps describe current state, not audit history.')
svg.append('</svg>')
(ROOT / '02_er_diagram.svg').write_text('\n'.join(svg))
print('Generated 02_er_diagram.svg from',len(tables),'tables')
