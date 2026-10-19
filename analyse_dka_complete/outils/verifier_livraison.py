"""Vérification documentaire et d'intégrité, sans exécution des traitements DKA."""
from pathlib import Path
import json,re,hashlib,urllib.parse
OUT=Path(__file__).resolve().parents[1];ROOT=OUT.parent
files=json.loads((OUT/'inventaire_complet.json').read_text(encoding='utf-8'))
actual={p.relative_to(ROOT).as_posix() for p in (ROOT/'dka').rglob('*') if p.is_file()}
listed={r['fichier'] for r in files}
changes=[r['fichier'] for r in files if hashlib.sha256((ROOT/r['fichier']).read_bytes()).hexdigest()!=r['sha256']]
broken=[];links=0
for p in OUT.rglob('*.md'):
    for dest in re.findall(r'\]\(([^)]+)\)',p.read_text(encoding='utf-8-sig')):
        if dest.startswith(('http:','https:','mailto:','#')):continue
        target=urllib.parse.unquote(dest.split('#')[0].strip('<>'))
        if not target:continue
        links+=1
        if not (p.parent/target).resolve().exists():broken.append({'document':p.relative_to(OUT).as_posix(),'cible':dest})
invalid_json=[]
for p in OUT.rglob('*.json'):
    try:json.loads(p.read_text(encoding='utf-8-sig'))
    except Exception as e:invalid_json.append({'fichier':str(p),'erreur':str(e)})
wf=json.loads((OUT/'workflow_structure.json').read_text(encoding='utf-8'))
workflow_counts={'exports':len(wf),'activites':0,'processus':0,'instances':0,'transitions':0};bad_transitions=[]
for f in wf:
    acts=[o for o in f['objects'] if o['kind']=='ACTIVITY'];workflow_counts['activites']+=len(acts)
    for a in acts:
        if a['props'].get('TYPE')!='PROCESS':continue
        workflow_counts['processus']+=1
        ins=[x for x in a['children'] if x['kind']=='PROCESS_ACTIVITY'];keys={x['keys'][0] for x in ins};workflow_counts['instances']+=len(ins)
        for x in ins:
            for tr in [c for c in x['children'] if c['kind']=='ACTIVITY_TRANSITION']:
                workflow_counts['transitions']+=1
                if len(tr['keys'])>1 and tr['keys'][1] not in keys:bad_transitions.append({'source':f['path'],'ligne':tr['line'],'cles':tr['keys']})
stats=json.loads((OUT/'statistiques.json').read_text(encoding='utf-8'))
body=[r for r in files if r['extension']=='.pkb'];missing_notes=[]
notes='\n'.join(p.read_text(encoding='utf-8-sig') for p in OUT.glob('0[234]*.md')).upper()
for r in body:
    if Path(r['fichier']).stem.upper() not in notes:missing_notes.append(r['fichier'])
summary={'date':'2026-10-17','fichiers_inventories':len(files),'fichiers_non_inventories':sorted(actual-listed),'fichiers_disparus':sorted(listed-actual),'sources_modifiees_depuis_inventaire':changes,'fiches':len(list((OUT/'fiches').glob('*.md'))),'liens_locaux_verifies':links,'liens_casses':broken,'json_invalides':invalid_json,'workflow':workflow_counts,'transitions_cibles_absentes':bad_transitions,'corps_non_nommes_dans_notes_domaine':missing_notes,'execution_traitements_metier':False}
summary['validation_reussie']=not any([actual!=listed,changes,broken,invalid_json,bad_transitions,missing_notes,summary['fiches']!=stats['fiches']])
(OUT/'verification_livraison.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(summary,ensure_ascii=True,indent=2))
if not summary['validation_reussie']:raise SystemExit(1)
