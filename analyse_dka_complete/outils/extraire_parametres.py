"""Annexe de paramétrage présente dans les exports, sans exécution métier."""
from pathlib import Path
import re,json,urllib.parse
OUT=Path(__file__).resolve().parents[1];ROOT=OUT.parent
rows=[]
for p in sorted((ROOT/'dka').rglob('*')):
    if not p.is_file() or p.suffix.lower() not in ('.prt','.dpt','.ldt'):continue
    text=p.read_bytes().decode('cp1252',errors='replace');stack=[]
    for num,line in enumerate(text.splitlines(),1):
        m=re.match(r'\s*BEGIN\s+(\w+)\s+(.*)',line)
        if m:
            b={'type':m[1],'cles':re.findall(r'"([^"\n]*)"',m[2]),'fichier':p.relative_to(ROOT).as_posix(),'ligne':num,'proprietes':{},'contexte':[x['cles'] for x in stack]};stack.append(b)
            if b['type'] in ('DKA_PARAMETER','DFF_SEGMENT'):rows.append(b)
        elif re.match(r'\s*END\s+\w+',line):
            if stack:stack.pop()
        elif stack:
            m=re.match(r'\s*(\w+)\s*=\s*(.*)',line)
            if m:stack[-1]['proprietes'][m[1]]=m[2].strip().strip('"')
(OUT/'parametres.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf-8')
lines=['# Paramètres spécifiques et paramètres SRS','','Valeurs présentes dans les exports locaux, pas valeurs de production vérifiées. Les segments sont rattachés au contexte exporté ; plusieurs langues/versions peuvent répéter une définition. Les signatures PL/SQL et leurs paramètres sont accessibles dans les spécifications du catalogue.','','| Type | Contexte / clé | Description / libellé | Type / obligatoire | Défaut ou valeur | Source |','|---|---|---|---|---|---|']
def c(x):return str(x).replace('|','\\|').replace('\n',' ')[:500]
for r in rows:
    p=r['proprietes'];label=p.get('DESCRIPTION',p.get('FORM_LEFT_PROMPT',p.get('END_USER_COLUMN_NAME','')));value=' ; '.join(k+'='+v for k,v in p.items() if k in ('DEFAULT_VALUE','VARCHAR2_VALUE','NUMBER_VALUE','DATE_VALUE','BOOLEAN_VALUE','FLEX_VALUE_SET_NAME','COLUMN_SEQ_NUM','DEFAULT_TYPE'))
    context=' / '.join(' / '.join(x) for x in r['contexte'])+' / '+' / '.join(r['cles'])
    lines.append(f"| {r['type']} | {c(context)} | {c(label)} | {c(p.get('DATA_TYPE',''))} / {c(p.get('REQUIRED_FLAG',''))} | {c(value)} | [{r['fichier']}:{r['ligne']}](../{urllib.parse.quote(r['fichier'],safe='/')}) |")
(OUT/'05a_parametres.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
print('Parameter definitions:',len(rows))
