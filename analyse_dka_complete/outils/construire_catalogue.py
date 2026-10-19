"""Analyse statique locale DKA : ne lance aucun fichier du corpus."""
from pathlib import Path
from collections import Counter, defaultdict
import re, json, hashlib, csv, html, urllib.parse, bisect

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'analyse_dka_complete'
SRC = ROOT / 'dka'
OUT.mkdir(exist_ok=True)
(OUT / 'fiches').mkdir(exist_ok=True)
def write(path, text):
    (OUT / path).write_text(text, encoding='utf-8')
def slug(text):
    return re.sub('[^a-z0-9_]+', '_', text.lower()).strip('_')
def link(path, base=OUT):
    import os
    return urllib.parse.quote(os.path.relpath(ROOT / path, base).replace('\\', '/'), safe='/')
def clean(text):
    return str(text).replace('|', '\\|').replace('\n', ' ')[:600]
def decode(raw):
    try: return raw.decode('utf-8-sig'), 'utf-8'
    except UnicodeDecodeError: return raw.decode('cp1252', errors='replace'), 'cp1252 (repli)'
def no_comments(text):
    # Conserve les positions de lignes ; chaînes SQL conservées pour les noms de programmes.
    return re.sub(r'/\*.*?\*/|--[^\n]*', lambda m: ''.join('\n' if c=='\n' else ' ' for c in m[0]), text, flags=re.S)
def line_offsets(text):
    return [m.start() for m in re.finditer('\n',text)]
def occurrences(pattern, text, flags=re.I):
    offsets=line_offsets(text)
    return [{'valeur':m.group(1), 'ligne':bisect.bisect_left(offsets,m.start())+1} for m in re.finditer(pattern,text,flags)]
def blocks(text):
    stack=[]; result=[]
    for line_no,line in enumerate(text.splitlines(),1):
        m=re.match(r'\s*BEGIN\s+(\w+)\s+(.*)',line)
        if m:
            b={'type':m[1], 'cles':re.findall(r'"([^"\n]*)"',m[2]), 'ligne':line_no,'proprietes':{}}
            stack.append(b);result.append(b)
        elif re.match(r'\s*END\s+\w+',line):
            if stack:stack.pop()
        elif stack:
            m=re.match(r'\s*(\w+)\s*=\s*(.*)',line)
            if m and len(m[2])<1000:stack[-1]['proprietes'][m[1]]=m[2].strip().strip('"')
    return result
def family(name):
    n=name.upper()
    rules=[('AP / fournisseurs',r'(?:IAP|SAP|REPAP|AP_|APFRS|OPEN_INTERFACE_AP)'),('AR / clients',r'(?:IAR|SAR|REPAR|AR_)'),('GL / comptabilité',r'(?:IGL|SGL|REPGL|GL_)'),('PO / achats',r'(?:IPO|SPO|REPPO|FUSPO|PO_)'),('PA / projets',r'(?:SPA|REPPA|PA_)'),('FA / immobilisations',r'(?:IFA|SFA|REPFA|FA_|AMOR)'),('RH / employés',r'(?:IHREMP|IAPEMPL|EM P|EMPJOBS|XXEAI_HR)'),('Banques / trésorerie',r'(?:SRB|ICE_BANK|RAPCTRLPRLVT)'),('FND / administration',r'(?:SFND|REPFND|FND_)'),('Contrôles transversaux',r'(?:SCTL|SCTRL|STRANSCO|TRANSCO|TOOLS|LOADER|XLA|MAIL|NOTIF)'),('Fusion / reprise',r'(?:FUSION|FUS|REP_)')]
    return next((label for label,pat in rules if re.search(pat,n)), 'Autres / à qualifier')

files=[]; records=[]; workflows=[]; packages={}; refs=[]; graph_nodes={}; graph_edges=[]
excluded_binary={'.xls','.xlsx','.zip','.png','.jpg','.gif','.pdf','.rtf'}
all_paths=sorted(p for p in SRC.rglob('*') if p.is_file())
for p in all_paths:
    raw=p.read_bytes(); rel=p.relative_to(ROOT).as_posix(); ext=p.suffix.lower()
    is_text=ext not in excluded_binary and b'\x00' not in raw[:8192]
    row={'fichier':rel,'extension':ext or '(sans extension)','octets':len(raw),'sha256':hashlib.sha256(raw).hexdigest(),'lecture':'texte intégral statique' if is_text else 'métadonnées seulement (binaire/archive)','famille_proposee':family(p.stem)}
    if not is_text: files.append(row);continue
    text,enc=decode(raw); code=no_comments(text);row.update(encodage=enc,lignes=len(text.splitlines()))
    decl=occurrences(r'\b(?:create\s+or\s+replace\s+)?package\s+(?:body\s+)?(?:apps\.)?([a-z][\w$#]*)',code)
    row['declarations_package']=decl[:3] if ext in ('.pkb','.pks') else []
    row['sous_programmes']=occurrences(r'\b(?:procedure|function)\s+([a-z][\w$#]*)',code) if ext in ('.pkb','.pks','.sql','.prc','.fct','.trg') else []
    row['triggers']=occurrences(r'\btrigger\s+((?:apps\.)?[a-z][\w$#]*)',code) if ext=='.trg' else []
    row['objets_sql']=occurrences(r'\b(?:from|join|update|insert\s+into|merge\s+into|delete\s+from)\s+([a-z][\w$#]*(?:\.[a-z][\w$#]*)?)',code)
    row['references_packages']=occurrences(r'\b((?:DKA_|XXEAI_|FND_|WF_|AP_|AR_|PO_|GL_|PA_|IBY_|HZ_)[a-z0-9_$#]+\.[a-z][\w$#]*)\s*\(',code)
    offsets=line_offsets(code)
    row['marqueurs']={k:[bisect.bisect_left(offsets,m.start())+1 for m in re.finditer(pat,code,re.I)] for k,pat in {'commit':r'\bcommit\b','rollback':r'\brollback\b','transaction_autonome':r'\bpragma\s+autonomous_transaction\b','when_others':r'\bwhen\s+others\b','suppression':r'\bdelete\s+from\b','truncate':r'\btruncate\s+table\b','sqlplus':r'\bsqlplus\b','sqlldr':r'\bsqlldr\b','concsub':r'\bconcsub\b','soumission':r'\bfnd_request\.submit_request\b','workflow':r'\bwf_engine\.\w+\b'}.items()}
    row['programmes_soumis']=occurrences(r"\bsubmit_request\s*\(\s*(?:application\s*=>\s*)?'[\w]+'\s*,\s*(?:program\s*=>\s*)?'([^']+)'",code,re.I|re.S)
    row['fichiers_references']=occurrences(r'((?:\$\{?DKA_TOP\}?/|@\$DKA_TOP/|@)[\w./${}_-]+\.(?:sql|sh|ctl))',text)
    if ext in ('.prt','.ldt','.dpt','.wft','.grp','.resp'):
        bs=blocks(text)
        for b in bs:
            if b['type'] in ('PROGRAM','EXECUTABLE','DFF_CONTEXT','DFF_SEGMENT','DKA_PARAMETER','DESC_FLEX','VALUE_SET','REQUEST_SET','REQUEST_SET_STAGE','STAGE_PROGRAM'):
                records.append(dict(b,fichier=rel))
        if ext=='.wft':
            workflows.append({'fichier':rel,'entites':bs,'comptages':dict(Counter(b['type'] for b in bs))})
    if ext=='.pkb':
        key=(row['declarations_package'][0]['valeur'] if row['declarations_package'] else p.stem).upper(); packages[key]=row
    files.append(row)

executables=defaultdict(list)
for r in records:
    if r['type']=='EXECUTABLE' and r['cles']:executables[r['cles'][0].upper()].append(r)
programs=[]
for r in records:
    if r['type']!='PROGRAM':continue
    e=r['proprietes'].get('EXEC','').split('"')[0].strip(); ex=executables.get(e.upper(),[])
    programs.append(dict(r,executables_resolus=ex))
for r in files:
    for x in r.get('references_packages',[]):
        target=x['valeur'].split('.')[0].upper()
        refs.append({'source':r['fichier'],'cible':target,'symbole':x['valeur'],'ligne':x['ligne'],'nature':'référence lexicale de forme appel','corps_present':target in packages})

def dump(name,obj):write(name,json.dumps(obj,ensure_ascii=False,indent=2))
dump('inventaire_complet.json',files);dump('programmes_concurrents.json',programs);dump('definitions_fnd.json',records);dump('workflows.json',workflows);dump('dependances.json',refs)
with (OUT/'inventaire_complet.csv').open('w',encoding='utf-8-sig',newline='') as f:
    w=csv.DictWriter(f,fieldnames=['fichier','extension','octets','lignes','encodage','lecture','famille_proposee','sha256'],extrasaction='ignore',delimiter=';');w.writeheader();w.writerows(files)

detail=[]
for r in files:
    p=Path(r['fichier']);ext=p.suffix.lower()
    if ext not in {'.pkb','.pks','.sh','.sql','.wft','.ctl','.trg','.vue','.prc','.fct','.prog','.java'} and not ext.startswith('.sh_') and ext!='.shv0':continue
    fname=slug(r['fichier'])+'.md';r['fiche']='fiches/'+fname
    content=[f'# {p.name}','',f"Source : [{r['fichier']}]({link(r['fichier'],OUT/'fiches')}).",'',f"Famille proposée par convention de nommage : **{r['famille_proposee']}**. Cette étiquette nécessite la lecture fonctionnelle du traitement.",'', '**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.', '',f"Lignes : {r.get('lignes',0)} ; encodage : {r.get('encodage','non texte')}. SHA-256 : `{r['sha256']}`."]
    for title,key in [('Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)','sous_programmes'),('Triggers déclarés','triggers'),('Objets SQL candidats (CTE et alias possibles)','objets_sql'),('Références de forme appel package.membre','references_packages'),('Programmes soumis, littéraux détectés','programmes_soumis'),('Fichiers référencés','fichiers_references')]:
        vals=r.get(key,[])
        content+=['',f'## {title}','']
        if not vals:content+=['Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.'];continue
        seen=set();content+=['| Élément | Ligne source |','|---|---:|']
        for v in vals:
            ident=(v['valeur'].upper(),v['ligne'])
            if ident not in seen:content.append(f"| `{clean(v['valeur'])}` | {v['ligne']} |");seen.add(ident)
    content+=['','## Transactions, erreurs et orchestration','','| Marqueur | Lignes |','|---|---|']
    for k,vs in r.get('marqueurs',{}).items():
        if vs:content.append(f"| {k} | {', '.join(map(str,vs))} |")
    # Rattachement des programmes au package sur la valeur EXECUTION_FILE_NAME.
    associated=[]
    for pr in programs:
        for ex in pr['executables_resolus']:
            val=ex['proprietes'].get('EXECUTION_FILE_NAME','')
            if val.split('.')[0].upper()==p.stem.upper():associated.append((pr,val))
    if associated:
        content+=['','## Programmes concurrents reliés par définition FND','','| Programme | Point d’entrée | Définition |','|---|---|---|']
        for pr,val in associated:content.append(f"| {clean(' / '.join(pr['cles']))} | `{clean(val)}` | {pr['fichier']}:{pr['ligne']} |")
    content+=['','## À établir par recette / analyse métier','','Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.']
    write('fiches/'+fname,'\n'.join(content)+'\n');detail.append(r)

dump('inventaire_complet.json',files)
index=['# Catalogue exhaustif des composants DKA','','Chaque fichier est inventorié. Les fiches détaillées sont automatiques ; les analyses métier par domaine les complètent. Familles proposées par noms, sans garantie fonctionnelle.','','| Fichier | Format | Famille proposée | Lignes | Lecture | Fiche |','|---|---|---|---:|---|---|']
for r in files:index.append(f"| [{clean(r['fichier'])}]({link(r['fichier'])}) | {r['extension']} | {r['famille_proposee']} | {r.get('lignes','—')} | {r['lecture']} | "+(f"[Fiche]({r['fiche']})" if 'fiche' in r else 'Inventaire')+' |')
write('01_catalogue_complet.md','\n'.join(index)+'\n')
ps=['# Programmes concurrents et exécutables','','Définitions FNDLOAD locales. Une définition exportée ne prouve ni activation actuelle ni planification Control-M. Les variantes de langue et fichiers peuvent répéter un programme. Résolution par nom court d’exécutable : les collisions d’application restent à arbitrer.','','| Programme / application | Libellé | Exécutable / méthode | Cible | Source |','|---|---|---|---|---|']
for p in programs:
    targets=' ; '.join(x['proprietes'].get('EXECUTION_FILE_NAME','') for x in p['executables_resolus'])
    ps.append(f"| {clean(' / '.join(p['cles']))} | {clean(p['proprietes'].get('USER_CONCURRENT_PROGRAM_NAME',''))} | {clean(p['proprietes'].get('EXEC',''))} / {clean(p['proprietes'].get('EXECUTION_METHOD_CODE',''))} | `{clean(targets)}` | [{p['fichier']}:{p['ligne']}]({link(p['fichier'])}) |")
write('05_programmes_et_orchestration.md','\n'.join(ps)+'\n')
stats={'fichiers':len(files),'octets':sum(r['octets'] for r in files),'texte':sum(r['lecture'].startswith('texte') for r in files),'metadonnees_seulement':sum(not r['lecture'].startswith('texte') for r in files),'extensions':dict(Counter(r['extension'] for r in files)),'fiches':len(detail),'corps_packages':len(packages),'definitions_programme':len(programs),'programmes_distincts':len(set(tuple(p['cles']) for p in programs)),'workflows':len(workflows),'references_packages':len(refs),'lignes_texte':sum(r.get('lignes',0) for r in files)}
dump('statistiques.json',stats)
print(json.dumps(stats,ensure_ascii=True))
