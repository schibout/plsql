"""Analyse des logs de demandes concurrentes Oracle EBS : l<request_id>.req (journal) et o<request_id>.out (sortie).

- Découpe le .req en blocs (séparateur "+----+"), extrait programme, dates, compteurs "Libellé : valeur",
  messages FND_FILE, codes d'erreur ("Erreur 025 : …", "ORA-01234: …", "APP-FND-01234: …").
- Le .out est parcouru pour les mêmes codes d'erreur (comptés) + un extrait des premières lignes.
- Un dictionnaire de diagnostics (diagnostics.json, éditable) associe code → explication + action.
- Les résultats sont stockés dans ora_request_logs et rattachés à ora_requests par request_id.

Usage :
    python logs.py                    # scanne les dossiers de config.ini [logs] dossiers
    python logs.py chemin1 chemin2    # scanne fichiers ou dossiers donnés
    python logs.py --liste            # écrit list.txt (chemins .req/.out des demandes en erreur sans log local)
"""
from __future__ import annotations
import json
import re
import sys
from collections import Counter, OrderedDict
from datetime import datetime
from pathlib import Path

from db import connect, BASE_DIR

DIAG_PATH = BASE_DIR / "diagnostics.json"
FILE_RE = re.compile(r"^([lo])(\d+)\.(req|out)$", re.I)
SEP_RE = re.compile(r"^\+-{10,}\+\s*$")
ERR_RES = [
    re.compile(r"\b(Erreur\s+\d{3})\s*:\s*(.+?)\s*$", re.I),
    re.compile(r"\b(ORA-\d{5})\s*:?\s*(.*?)\s*$"),
    re.compile(r"\b(APP-[A-Z]+-\d{5})\s*:?\s*(.*?)\s*$"),
    re.compile(r"\b(PLS-\d{5})\s*:?\s*(.*?)\s*$"),
    re.compile(r"\b(SQL\*Loader-\d+)\s*:?\s*(.*?)\s*$"),
    re.compile(r"^\s*(ERROR|ERREUR|FATAL)\b\s*:?\s*(.+?)\s*$", re.I),
]
COMPTEUR_RE = re.compile(r"^\s*(Nombre[^:]{3,60}?|Total[^:]{3,60}?|Nb[^:]{3,60}?)\s*:\s*(\d[\d\s.,]*)\s*$", re.I)
INFO_RE = re.compile(r"^\s*([A-Za-zÀ-ÿ'’ ()/_-]{4,60}?)\s{2,}:\s*(\S.*?)\s*$")
DATE_RE = re.compile(r"Date et heure syst[èe]me\s*:\s*(\d{2}-[A-Z]{3}-\d{4} \d{2}:\d{2}:\d{2})", re.I)
PROG_RE = re.compile(r"^([A-Z][A-Z0-9_]{2,}):\s+(.+?)\s*$")
FND_START = re.compile(r"D[ée]but des messages de journalisation|Start of log messages", re.I)
FND_END = re.compile(r"Fin des messages de journalisation|End of log messages", re.I)
END_MARK = re.compile(r"Traitement simultan[ée] termin[ée]|Concurrent request completed", re.I)


def lire(path: Path) -> str:
    raw = path.read_bytes()
    for enc in ("utf-8", "cp1252", "latin-1"):
        try:
            return raw.decode(enc)
        except UnicodeDecodeError:
            continue
    return raw.decode("latin-1", errors="replace")


def _erreurs(lines: list[str]) -> list[dict]:
    c: Counter = Counter()
    msg: dict[str, str] = {}
    for l in lines:
        for rx in ERR_RES:
            m = rx.search(l)
            if m:
                code = m.group(1).strip()
                code_n = re.sub(r"\s+", " ", code).title() if code.lower().startswith("erreur") else code
                c[code_n] += 1
                msg.setdefault(code_n, m.group(2).strip()[:200])
                break
    return [dict(code=k, message=msg[k], nb=n) for k, n in c.most_common()]


def parse_req(text: str) -> dict:
    lines = text.splitlines()
    blocs, cur = [], []
    for l in lines:
        if SEP_RE.match(l):
            if cur:
                blocs.append(cur)
            cur = []
        else:
            cur.append(l)
    if cur:
        blocs.append(cur)

    programme, started, ended = None, None, None
    compteurs: "OrderedDict[str, str]" = OrderedDict()
    infos: "OrderedDict[str, str]" = OrderedDict()
    fnd, in_fnd = [], False
    for l in lines:
        if FND_START.search(l):
            in_fnd = True
            continue
        if FND_END.search(l):
            in_fnd = False
            continue
        if in_fnd and l.strip() and not SEP_RE.match(l):
            fnd.append(l.rstrip())
        m = PROG_RE.match(l.strip())
        if m and not programme and not l.lower().startswith(("copyright", "request id")):
            programme = f"{m.group(1)} — {m.group(2)}"
        m = DATE_RE.search(l)
        if m:
            if not started:
                started = m.group(1)
            else:
                ended = m.group(1)
        m = COMPTEUR_RE.match(l)
        if m:
            compteurs[m.group(1).strip()] = m.group(2).strip()
            continue
        m = INFO_RE.match(l)
        if m and len(infos) < 20 and not in_fnd:
            infos[m.group(1).strip()] = m.group(2)
    err = _erreurs(lines)
    termine = any(END_MARK.search(l) for l in lines)
    return dict(programme=programme, started=started, ended=ended, compteurs=dict(compteurs),
                infos=dict(infos), fnd_messages="\n".join(fnd[-60:]), erreurs=err, termine=termine,
                nb_blocs=len(blocs))


def parse_out(text: str) -> dict:
    lines = text.splitlines()
    return dict(erreurs=_erreurs(lines), nb_lignes=len(lines),
                extrait="\n".join(l.rstrip() for l in lines[:40]))


# ---------------------------------------------------------------- diagnostics
def charger_diagnostics() -> dict:
    if DIAG_PATH.exists():
        return json.loads(DIAG_PATH.read_text(encoding="utf-8"))
    return {}


def diagnostiquer(erreurs: list[dict], programme: str | None, diags: dict | None = None) -> list[dict]:
    diags = diags if diags is not None else charger_diagnostics()
    out = []
    for e in erreurs:
        code = e["code"]
        d = diags.get(code)
        if not d:
            for k, v in diags.items():
                if k.endswith("*") and code.upper().startswith(k[:-1].upper()):
                    d = v
                    break
        if d:
            out.append(dict(code=code, nb=e["nb"], explication=d.get("explication", ""),
                            action=d.get("action", ""), gravite=d.get("gravite", "à qualifier"),
                            programmes=d.get("programmes", [])))
        else:
            out.append(dict(code=code, nb=e["nb"], explication="Code non répertorié dans diagnostics.json.",
                            action="Qualifier l'erreur puis l'ajouter au dictionnaire.", gravite="à qualifier",
                            programmes=[]))
    return out


# ---------------------------------------------------------------- chargement
def charger_fichier(con, path: Path, diags: dict) -> str | None:
    m = FILE_RE.match(path.name)
    if not m:
        return None
    kind = "req" if m.group(1).lower() == "l" else "out"
    rid = int(m.group(2))
    st = path.stat()
    row = con.execute("SELECT size, loaded_at FROM ora_request_logs WHERE request_id=? AND kind=?", (rid, kind)).fetchone()
    if row and row["size"] == st.st_size:
        return None
    text = lire(path)
    if kind == "req":
        p = parse_req(text)
        prog = p["programme"]
        started, ended = p["started"], p["ended"]
        compteurs = {**p["compteurs"], **{k: v for k, v in p["infos"].items() if k not in p["compteurs"]}}
        fnd = p["fnd_messages"]
    else:
        p = parse_out(text)
        prog, started, ended, compteurs, fnd = None, None, None, {"lignes": p["nb_lignes"]}, p["extrait"]
    diag = diagnostiquer(p["erreurs"], prog, diags)
    con.execute(
        "INSERT OR REPLACE INTO ora_request_logs(request_id, kind, path, size, loaded_at, program, started, ended, "
        "compteurs, erreurs, fnd_messages, diagnostic) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
        (rid, kind, str(path), st.st_size, datetime.now().strftime("%Y-%m-%d %H:%M:%S"), prog, started, ended,
         json.dumps(compteurs, ensure_ascii=False), json.dumps(p["erreurs"], ensure_ascii=False), fnd,
         json.dumps(diag, ensure_ascii=False)))
    return f"{path.name}: {len(p['erreurs'])} type(s) d'erreur" + (f", {prog}" if prog else "")


def dossiers_config() -> list[Path]:
    import configparser
    cfg = configparser.ConfigParser(inline_comment_prefixes=(";", "#"))
    cfg.read(BASE_DIR / "config.ini", encoding="utf-8")
    raw = cfg.get("logs", "dossiers", fallback="logs_ebs")
    out = []
    for d in raw.split(";"):
        d = d.strip()
        if d:
            p = Path(d)
            out.append(p if p.is_absolute() else (BASE_DIR / p))
    return out


def run(roots: list[Path] | None = None) -> list[str]:
    roots = roots or dossiers_config()
    con = connect()
    diags = charger_diagnostics()
    logs, n = [], 0
    for root in roots:
        files = [root] if root.is_file() else sorted(root.rglob("*")) if root.is_dir() else []
        for f in files:
            if f.is_file() and FILE_RE.match(f.name):
                r = charger_fichier(con, f, diags)
                if r:
                    logs.append(r)
                    n += 1
    con.commit()
    total = con.execute("SELECT COUNT(*) FROM ora_request_logs").fetchone()[0]
    con.close()
    logs.append(f"{n} fichier(s) analysé(s), {total} logs en base.")
    return logs


def ecrire_liste(dest: Path | None = None) -> str:
    """list.txt pour copy_ebs_logs.sh : demandes en erreur/avertissement sans log local."""
    con = connect()
    rows = con.execute("""
        SELECT r.request_id, r.logfile_name, r.outfile_name
        FROM ora_requests r
        WHERE r.phase_code='C' AND r.status_code IN ('E','G','X')
          AND r.source='oracle'
          AND NOT EXISTS (SELECT 1 FROM ora_request_logs l WHERE l.request_id=r.request_id AND l.kind='req')
        ORDER BY r.actual_completion DESC""").fetchall()
    con.close()
    dest = dest or (BASE_DIR / "list.txt")
    lignes = [f"{r['logfile_name'] or ''} {r['outfile_name'] or ''}".strip() for r in rows if r["logfile_name"]]
    dest.write_text("\n".join(lignes) + "\n", encoding="utf-8", newline="\n")
    return f"{len(lignes)} ligne(s) écrite(s) dans {dest} (à passer à copy_ebs_logs.sh sur le serveur EBS)."


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--liste":
        print(ecrire_liste())
    else:
        print("\n".join(run([Path(a) for a in args] or None)))
