"""Graphe documentaire statique à partir du catalogue, sans exécution du corpus."""
from pathlib import Path
from collections import defaultdict
import json, re, hashlib
from graphify.build import build_from_json
from graphify.cluster import cluster, score_all
from graphify.analyze import god_nodes, surprising_connections, suggest_questions
from graphify.export import to_json, to_html
from graphify.report import generate

OUT=Path(__file__).resolve().parents[1]
DEST=OUT/'graphify-out';DEST.mkdir(exist_ok=True)
files=json.loads((OUT/'inventaire_complet.json').read_text(encoding='utf-8'))
programs=json.loads((OUT/'programmes_concurrents.json').read_text(encoding='utf-8'))
nodes={}; edges={}
def node(key,label,file,kind='code',line=None):
    if key not in nodes:nodes[key]={'id':key,'label':label,'source_file':file,'source_location':f'{file}:{line}' if line else file,'file_type':kind}
    return key
def fid(path):return 'file_'+hashlib.sha256(path.encode()).hexdigest()[:20]
def pid(name):return 'pkg_'+re.sub('[^a-z0-9_]','_',name.lower())
def edge(a,b,relation,file,line):
    key=(a,b,relation)
    if key not in edges:edges[key]={'source':a,'target':b,'relation':relation,'source_file':file,'source_location':f'{file}:{line}','confidence':'EXTRACTED','confidence_score':1.0,'weight':1.0}
for r in files:
    f=r['fichier'];a=node(fid(f),Path(f).name,f)
    for decl in r.get('declarations_package',[]):
        b=node(pid(decl['valeur']),decl['valeur'].upper(),f,line=decl['ligne']);edge(a,b,'declares',f,decl['ligne'])
    for ref in r.get('references_packages',[]):
        name=ref['valeur'].split('.')[0].upper();b=node(pid(name),name,f,line=ref['ligne']);edge(a,b,'references',f,ref['ligne'])
for p in programs:
    short=' / '.join(p['cles']);key='program_'+hashlib.sha256(short.encode()).hexdigest()[:20]
    a=node(key,short,p['fichier'],line=p['ligne']);edge(fid(p['fichier']),a,'defines',p['fichier'],p['ligne'])
    for ex in p['executables_resolus']:
        val=ex['proprietes'].get('EXECUTION_FILE_NAME','');name=val.split('.')[0].upper()
        if '.' in val and name.startswith(('DKA_','XXEAI_','FND_','AP_','AR_','GL_','PA_','PO_','WF_')):
            b=node(pid(name),name,ex['fichier'],line=ex['ligne']);edge(a,b,'configured_entrypoint',ex['fichier'],ex['ligne'])
# Les transitions détaillées sont conservées dans workflow_structure.json, hors graphe agrégé.
data={'nodes':list(nodes.values()),'edges':list(edges.values()),'hyperedges':[]}
(DEST/'extraction.json').write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
G=build_from_json(data);cs=cluster(G);scores=score_all(G,cs)
labels={cid:' / '.join(G.nodes[x].get('label',x) for x in sorted(ids,key=lambda n:G.degree(n),reverse=True)[:2]) for cid,ids in cs.items()}
gods=god_nodes(G);surprises=surprising_connections(G,cs);questions=suggest_questions(G,cs,labels)
total_words=sum(len((OUT.parent/r['fichier']).read_bytes().split()) for r in files if r['lecture'].startswith('texte'))
detection={'total_files':len(files),'total_words':total_words,'files':{},'skipped_sensitive':[]}
report=generate(G,cs,scores,labels,gods,surprises,detection,{'input':0,'output':0},str(OUT.parent),suggested_questions=questions)
note='''# Graphe documentaire DKA — conditions de lecture

Relations extraites lexicalement ou à partir des propriétés FND exportées. « references » ne prouve ni exécution ni appel direct ; « configured_entrypoint » décrit la configuration locale, sans attester son déploiement. Les corps absents sont des dépendances externes possibles, pas des anomalies prouvées. Les déclarations restent liées aux fichiers pour conserver les variantes. Les transitions détaillées Workflow sont disponibles dans les annexes séparées.

Coûts : extraction déterministe locale ; consommation de tokens des revues assistées non exposée par les outils, donc non mesurée. Les zéros affichés par le générateur ci-dessous sont des valeurs techniques, pas un coût de session nul.

'''
(DEST/'GRAPH_REPORT.md').write_text(note+report,encoding='utf-8')
to_json(G,cs,str(DEST/'graph.json'),community_labels=labels)
if len(G)>5000:print('WARNING: graph exceeds 5000 nodes; HTML skipped; use community aggregation.')
else:to_html(G,cs,str(DEST/'graph.html'),community_labels=labels)
(DEST/'statistiques.json').write_text(json.dumps({'nodes':len(G),'edges':G.number_of_edges(),'communities':len(cs),'tokens_host':None,'god_nodes':gods,'surprising_connections':surprises,'suggested_questions':questions},ensure_ascii=False,indent=2),encoding='utf-8')
print('Graph:',len(G),'nodes;',G.number_of_edges(),'edges;',len(cs),'communities')
