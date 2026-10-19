"""Static, read-only source extraction for the AP analysis; never executes SQL."""
import hashlib
import json
import pathlib
import re
import unicodedata

ROOT = pathlib.Path('C:/Projects/plsql')
files = json.loads((ROOT / 'graphify-out/perimetre_0.json').read_text(encoding='utf-8-sig'))
nodes, edges, inventory = [], [], []
seen_nodes, seen_edges, tables = set(), set(), {}

def snake(value):
    value = unicodedata.normalize('NFKD', value).encode('ascii', 'ignore').decode().lower()
    return re.sub('[^a-z0-9_]', '_', value)

def stem(f):
    p = pathlib.PurePosixPath(f)
    return snake((p.parent.name + '_' if p.parent.name else '') + p.stem)

def node(f, label, line=1, kind='code'):
    ident = stem(f) + '_' + snake(label)
    if ident not in seen_nodes:
        nodes.append(dict(id=ident, label=label, file_type=kind, source_file=f,
                          source_location='L' + str(line), source_url=None,
                          captured_at=None, author=None, contributor=None))
        seen_nodes.add(ident)
    return ident

def edge(source, target, relation, f, line):
    key = (source, target, relation, f, line)
    if key not in seen_edges:
        edges.append(dict(source=source, target=target, relation=relation,
                          confidence='EXTRACTED', confidence_score=1.0,
                          source_file=f, source_location='L' + str(line), weight=1.0))
        seen_edges.add(key)

texts = {}
for f in files:
    raw = (ROOT / f).read_bytes()
    content = raw.decode('utf-8-sig', errors='replace')
    texts[f] = content
    inventory.append(dict(file=f, lines=len(content.splitlines()), bytes=len(raw),
                          sha256=hashlib.sha256(raw).hexdigest(),
                          method='Full file read; static object extraction, targeted semantic review. No SQL execution.'))
    src = node(f, pathlib.PurePosixPath(f).name, kind='document' if f.lower().endswith('.md') else 'code')
    if f.lower().endswith('.md'):
        continue
    # Mask comments and literals while preserving source offsets and line numbers.
    def mask(m):
        return ''.join('\n' if c == '\n' else ' ' for c in m.group())
    code = re.sub(r"--[^\n]*|/\*[\s\S]*?\*/|'(?:''|[^'])*'", mask, content)
    for match in re.finditer(r'\b(?:from|join|update|insert\s+into|delete\s+from)\s+([a-zA-Z][\w$#]*(?:\.[a-zA-Z][\w$#]*)?)', code, re.I):
        label = match.group(1).upper()
        if label in {'DUAL', 'SET', 'INTO', 'OF', 'TABLE'}:
            continue
        # Restrict references to explicit database objects in this corpus.
        unqualified = label.split('.')[-1]
        if not unqualified.startswith(('AP_', 'DKA_', 'FND_', 'GL_', 'PA_', 'PO_', 'RCV_', 'HR_', 'HZ_', 'IBY_', 'ZX_', 'PER_', 'XXEAI_', 'EXTRACTION_')):
            continue
        line = code.count('\n', 0, match.start()) + 1
        if label not in tables:
            tables[label] = node(f, label, line, 'concept')
        edge(src, tables[label], 'references', f, line)

# Hand-checked PL/SQL call edges: actual callers to actual callees.
base = files[3]
for f in (files[3], files[4], files[5]):
    content = texts[f]
    def first_line(pattern):
        m = re.search(pattern, content, re.I | re.M)
        return content.count('\n', 0, m.start()) + 1 if m else None
    for caller, callee, pattern in [
        ('import', 'control_double', r'^\s+control_double\(gn_org_id'),
        ('import', 'child_import', r'^\s+child_import\('),
        ('import', 'delete_processed_lines', r'^\s+vn_interface_count\s*:=\s*delete_processed_lines'),
        ('child_import', 'insert_header', r'^\s+vn_invoice_id\s*:=\s*insert_header'),
        ('child_import', 'insert_line', r'^\s+insert_line\('),
        ('child_import', 'reporte_erreur', r'^\s+reporte_erreur\(rec_fact.rowid'),
        ('child_import', 'FND_REQUEST.SUBMIT_REQUEST', r'^\s+vn_request_id\s*:=\s*fnd_request.submit_request'),
        ('child_import', 'DKA_AP_TOOLS_PKG.APPLY_FONCTION', r'^\s+DKA_AP_TOOLS_PKG.apply_fonction'),
        ('transaction_type', 'DKA_SARREFAC_PKG.IS_TRANSACTION_TYPE_REFAC', r'^\s+IF dka_sarrefac_pkg.is_transaction_type_refac'),
        ('get_source_from_filename', 'get_prefix_from_filename', r'^\s+vv_prefix\s*:=\s*get_prefix_from_filename'),
        ('child_import', 'get_source_from_filename', r'^\s+vv_source\s*:=\s*get_source_from_filename'),
        ('child_import', 'get_folio_from_filename', r'^\s+vv_attribute9\s*:=\s*get_folio_from_filename'),
    ]:
        line = first_line(pattern)
        if line:
            edge(node(f, caller, first_line(r'^\s*(?:procedure|function)\s+' + re.escape(caller) + r'\b') or line),
                 node(f, callee, line), 'calls', f, line)

result = dict(nodes=nodes, edges=edges, hyperedges=[], input_tokens=0, output_tokens=0)
(ROOT / 'graphify-out/.graphify_chunk_00.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
(ROOT / 'graphify-out/couverture_chunk_00.json').write_text(json.dumps(inventory, ensure_ascii=False, indent=2), encoding='utf-8')
assert all(e['source'] in seen_nodes and e['target'] in seen_nodes for e in edges)
assert all(re.fullmatch('[a-z0-9_]+', n['id']) for n in nodes)
print(json.dumps(dict(files=len(files), lines=sum(x['lines'] for x in inventory), nodes=len(nodes), edges=len(edges))))
