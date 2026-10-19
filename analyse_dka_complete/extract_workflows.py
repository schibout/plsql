"""Read-only extraction of Oracle Workflow text exports; no corpus code execution."""
from pathlib import Path
import re,json
root=Path('dka/12.0.0/admin/import')
out=Path('analyse_dka_complete');out.mkdir(exist_ok=True)
files=[]
for p in sorted(root.glob('*.wft')):
    stack=[];top=[]
    physical=p.read_text(encoding='cp1252',errors='replace').splitlines()
    logical=[];acc='';start=1
    for n,line in enumerate(physical,1):
        if not acc:start=n
        acc+=line[:-1] if line.endswith('\\') else line
        if not line.endswith('\\'):
            logical.append((start,acc));acc=''
    for n,line in logical:
        m=re.match(r'\s*BEGIN (\w+)\s*(.*)',line)
        if m:
            obj={'kind':m[1],'keys':re.findall(r'"([^"]*)"',m[2]),'line':n,'props':{},'children':[]}
            if stack:stack[-1]['children'].append(obj)
            else:top.append(obj)
            stack.append(obj)
        elif re.match(r'\s*END \w+',line):
            if stack:stack.pop()
        elif stack:
            m=re.match(r'\s*(\w+)\s*=\s*"(.*)"',line)
            if m:stack[-1]['props'][m[1]]=m[2]
    files.append({'path':p.as_posix(),'objects':top})
(out/'workflow_structure.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# Annexe — transitions et callbacks des 12 exports Workflow','',
       'Extraction statique des blocs `BEGIN/END`. Chaque ligne indique son emplacement dans la source. Les activités de bibliothèque présentes dans les exports sont conservées ; leur présence ne prouve pas leur exécution. `*`, `#DEFAULT`, `#TIMEOUT` sont reproduits littéralement. Les propriétés absentes sont laissées vides. Les corps multilignes des messages ne sont pas reconstitués par cet extracteur.','']
for f in files:
    p=f['path'];acts=[o for o in f['objects'] if o['kind']=='ACTIVITY'];procs=[a for a in acts if a['props'].get('TYPE')=='PROCESS']
    items=[o for o in f['objects'] if o['kind']=='ITEM_TYPE']
    lines+=['## '+Path(p).name,'',f"Source : `{p}`. Types : "+', '.join('`'+':'.join(i['keys'])+'`' for i in items)+'.',
            f"{len(acts)} définitions d’activité ; {len(procs)} processus exportés.",'']
    for a in procs:
        ap=a['props'];lines += ['### '+'.'.join(a['keys']), '',f"`{p}:{a['line']}` — {ap.get('DISPLAY_NAME','')} ; RUNNABLE={ap.get('RUNNABLE','')} ; RERUN={ap.get('RERUN','')} ; erreur={ap.get('ERROR_ITEM_TYPE','')}.{ap.get('ERROR_PROCESS','')}", '', '| Instance | Référence activité | Départ/fin ; rôle ; délai | Transitions résultat → cible (ligne) |','|---|---|---|---|']
        for c in a['children']:
            if c['kind']!='PROCESS_ACTIVITY':continue
            q=c['props'];attrs=[x for x in c['children'] if x['kind']=='ACTIVITY_ATTRIBUTE_VALUE'];tr=[x for x in c['children'] if x['kind']=='ACTIVITY_TRANSITION']
            special=' ; '.join(k+'='+v for k,v in q.items() if k in ('START_END','PERFORM_ROLE','PERFORM_ROLE_TYPE'))
            special+=' ; '+' ; '.join(':'.join(x['keys'])+'='+x['props'].get('VALUE','') for x in attrs if x['keys'] and ('TIMEOUT' in x['keys'][0] or 'CONTINUATION' in x['keys'][0] or 'PROGRAM' in x['keys'][0]))
            trans=' ; '.join(' → '.join(x['keys'])+f" ({x['line']})" for x in tr)
            lines.append('| '+c['keys'][0]+f" ({c['line']}) | "+q.get('ACTIVITY_ITEM_TYPE','')+'.'+q.get('ACTIVITY_NAME','')+' | '+special+' | '+trans+' |')
        lines.append('')
    lines += ['### Fonctions, notifications et événements exportés','','| Activité (ligne) | Type | Callback / message / événement | Résultat ; reprise ; erreur |','|---|---|---|---|']
    for a in acts:
        q=a['props']
        if q.get('TYPE')=='PROCESS':continue
        target=' ; '.join(k+'='+q[k] for k in ('FUNCTION','FUNCTION_TYPE','MESSAGE','EVENT_FILTER','EVENT_TYPE') if k in q)
        lines.append('| '+'.'.join(a['keys'])+f" ({a['line']}) | "+q.get('TYPE','')+' | '+target+' | '+' ; '.join(k+'='+q[k] for k in ('RESULT_TYPE','RERUN','ERROR_ITEM_TYPE','ERROR_PROCESS') if k in q)+' |')
    lines.append('')
(out/'03a_workflows_transitions.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
for f in files:
    acts=[o for o in f['objects'] if o['kind']=='ACTIVITY'];ps=[a for a in acts if a['props'].get('TYPE')=='PROCESS']
    print(Path(f['path']).name,len(acts),'activities',len(ps),'processes',sum(len([c for c in a['children'] if c['kind']=='PROCESS_ACTIVITY']) for a in ps),'instances')
    for a in ps:
        if a['keys'][0] not in ('WFSTD','FNDCMSTD'):
            print(' ','.'.join(a['keys']),a['line'],a['props'].get('RUNNABLE'),len(a['children']))
