"""Brique Oracle Apps : charge FND_CONCURRENT_PROGRAMS et FND_CONCURRENT_REQUESTS dans SQLite.

Récupère :
  - le référentiel des programmes concurrents (ora_programs), option --programmes
  - les demandes des N dernières heures (config heures_historique, défaut 48) + toutes les demandes
    en attente (PHASE_CODE = 'P', donc planifiées pour ce soir / demain)          (ora_requests)
La DESCRIPTION des demandes lancées par Control-M via DKA_SLAUNCHER contient le nom du job Control-M
("FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh") : elle alimente job_name et job_mapping.
Les demandes filles (PARENT_REQUEST_ID) héritent du job_name de leur parent.

Usage :
    python oracle_refresh.py                 # demandes des 48 dernières heures + en attente
    python oracle_refresh.py --jours 90      # chargement initial long
    python oracle_refresh.py --programmes    # rafraîchit aussi le référentiel des programmes
    python oracle_refresh.py --test          # teste seulement la connexion
"""
from __future__ import annotations
import argparse
import configparser
import re
from datetime import datetime

from db import connect, BASE_DIR

CONFIG = BASE_DIR / "config.ini"
JOB_RE = re.compile(r"^([A-Z]{3}[A-Z0-9]{3}_[A-Z0-9]{6,}_\d{2}(?:_[A-Z0-9]+)?_[QHMJ])\b")

SQL_PROGRAMS = """
SELECT fcp.concurrent_program_name, fcpt.user_concurrent_program_name,
       fa.application_short_name, fat.application_name,
       fe.executable_name, fl.meaning AS execution_method, fe.execution_file_name,
       fcp.enabled_flag, fcpt.description
FROM   {s}fnd_concurrent_programs fcp
JOIN   {s}fnd_concurrent_programs_tl fcpt
       ON fcpt.concurrent_program_id = fcp.concurrent_program_id
      AND fcpt.application_id = fcp.application_id AND fcpt.language = USERENV('LANG')
JOIN   {s}fnd_application fa ON fa.application_id = fcp.application_id
JOIN   {s}fnd_application_tl fat ON fat.application_id = fa.application_id AND fat.language = USERENV('LANG')
LEFT JOIN {s}fnd_executables fe
       ON fe.executable_id = fcp.executable_id AND fe.application_id = fcp.executable_application_id
LEFT JOIN {s}fnd_lookups fl ON fl.lookup_type = 'CP_EXECUTION_METHOD_CODE' AND fl.lookup_code = fe.execution_method_code
WHERE  fcp.enabled_flag = 'Y'
  AND  (fa.application_short_name IN ('DKA','XXRB','RB','SQLAP','SQLGL','AR','PA','PO','CE','FA','XLA','ZX')
        OR fcp.concurrent_program_name LIKE 'DKA%' OR fcp.concurrent_program_name LIKE 'XX%'
        OR fcp.concurrent_program_name LIKE 'RB%')
"""

SQL_REQUESTS = """
SELECT fcr.request_id,
       fcp.concurrent_program_name, fcpt.user_concurrent_program_name, fa.application_short_name,
       fcr.phase_code, fcr.status_code,
       fl1.meaning AS phase, fl2.meaning AS status,
       TO_CHAR(fcr.request_date,           'YYYY-MM-DD HH24:MI:SS'),
       TO_CHAR(fcr.requested_start_date,   'YYYY-MM-DD HH24:MI:SS'),
       TO_CHAR(fcr.actual_start_date,      'YYYY-MM-DD HH24:MI:SS'),
       TO_CHAR(fcr.actual_completion_date, 'YYYY-MM-DD HH24:MI:SS'),
       fu.user_name, frt.responsibility_name,
       fcr.parent_request_id, fcr.resubmit_interval, fcr.resubmit_interval_unit_code,
       fcr.argument_text, fcr.description, fcr.completion_text,
       fcr.logfile_name, fcr.outfile_name
FROM   {s}fnd_concurrent_requests fcr
JOIN   {s}fnd_concurrent_programs fcp
       ON fcp.concurrent_program_id = fcr.concurrent_program_id
      AND fcp.application_id = fcr.program_application_id
JOIN   {s}fnd_concurrent_programs_tl fcpt
       ON fcpt.concurrent_program_id = fcp.concurrent_program_id
      AND fcpt.application_id = fcp.application_id AND fcpt.language = USERENV('LANG')
JOIN   {s}fnd_application fa ON fa.application_id = fcp.application_id
LEFT JOIN {s}fnd_user fu ON fu.user_id = fcr.requested_by
LEFT JOIN {s}fnd_responsibility_tl frt
       ON frt.responsibility_id = fcr.responsibility_id
      AND frt.application_id = fcr.responsibility_application_id AND frt.language = USERENV('LANG')
LEFT JOIN {s}fnd_lookups fl1 ON fl1.lookup_type = 'CP_PHASE_CODE'  AND fl1.lookup_code = fcr.phase_code
LEFT JOIN {s}fnd_lookups fl2 ON fl2.lookup_type = 'CP_STATUS_CODE' AND fl2.lookup_code = fcr.status_code
WHERE  (fcr.request_date >= SYSDATE - :heures / 24 OR fcr.phase_code IN ('P', 'R'))
  AND  (   :filtre IS NULL
        OR fcr.description LIKE :filtre
        OR fcp.concurrent_program_name IN ({progs})
        OR fcr.parent_request_id IN (SELECT p.request_id FROM {s}fnd_concurrent_requests p
                                     WHERE p.description LIKE :filtre
                                       AND p.request_date >= SYSDATE - :heures / 24 - 2))
"""

UPSERT_REQ = """
INSERT INTO ora_requests(request_id, program_short, program_name, application_short,
    phase_code, status_code, phase, status, request_date, requested_start, actual_start,
    actual_completion, requestor, responsibility, parent_request_id, resubmit_interval,
    resubmit_unit, argument_text, description, completion_text, logfile_name, outfile_name,
    job_name, refreshed_at)
VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
ON CONFLICT(request_id) DO UPDATE SET
    phase_code=excluded.phase_code, status_code=excluded.status_code,
    phase=excluded.phase, status=excluded.status,
    requested_start=excluded.requested_start, actual_start=excluded.actual_start,
    actual_completion=excluded.actual_completion, completion_text=excluded.completion_text,
    logfile_name=excluded.logfile_name, outfile_name=excluded.outfile_name,
    job_name=COALESCE(excluded.job_name, ora_requests.job_name),
    refreshed_at=excluded.refreshed_at
"""

UPSERT_PROG = """
INSERT INTO ora_programs(program_short, program_name, application_short, application_name,
    executable_name, execution_method, execution_file, enabled, description, refreshed_at)
VALUES (?,?,?,?,?,?,?,?,?,?)
ON CONFLICT(program_short) DO UPDATE SET
    program_name=excluded.program_name, application_short=excluded.application_short,
    application_name=excluded.application_name, executable_name=excluded.executable_name,
    execution_method=excluded.execution_method, execution_file=excluded.execution_file,
    enabled=excluded.enabled, description=excluded.description, refreshed_at=excluded.refreshed_at
"""


def load_config() -> configparser.ConfigParser:
    if not CONFIG.exists():
        raise SystemExit(f"Fichier {CONFIG} absent : copier config.ini.exemple en config.ini et le renseigner.")
    cfg = configparser.ConfigParser(inline_comment_prefixes=(";", "#"))
    cfg.read(CONFIG, encoding="utf-8")
    return cfg


_THICK_DONE = False


def _init_thick(cfg) -> None:
    """Active le mode thick (client Oracle) si demandé ou si un Instant Client est configuré.

    Nécessaire quand le compte a un vérificateur de mot de passe 10g (erreur DPY-3015) : le mode
    thin ne le supporte pas. Le client doit être un Instant Client 64 bits (19c ou plus), dézippé
    par exemple dans C:\\oracle\\instantclient_21_13 et renseigné dans config.ini [database] client_dir.
    """
    global _THICK_DONE
    if _THICK_DONE:
        return
    import oracledb
    db = cfg["database"]
    client_dir = (db.get("client_dir", "") or "").strip()
    mode = (db.get("mode", "auto") or "auto").strip().lower()
    if mode == "thin":
        return
    if client_dir:
        try:
            oracledb.init_oracle_client(lib_dir=client_dir)
            _THICK_DONE = True
        except Exception as e:  # noqa: BLE001
            raise SystemExit(f"Client Oracle introuvable ou incompatible dans {client_dir} : {e}\n"
                             "Il faut un Instant Client 64 bits (Basic ou Basic Light, 19c+), "
                             "voir https://www.oracle.com/database/technologies/instant-client/downloads.html")
    elif mode == "thick":
        oracledb.init_oracle_client()  # cherche dans le PATH
        _THICK_DONE = True


def _connect_oracle(cfg):
    try:
        import oracledb
    except ImportError:
        raise SystemExit("Module oracledb absent : pip install oracledb")
    _init_thick(cfg)
    db = cfg["database"]
    try:
        return oracledb.connect(user=db["user"], password=db["password"], dsn=db["dsn"])
    except oracledb.NotSupportedError as e:
        if "DPY-3015" in str(e):
            raise SystemExit(
                "DPY-3015 : le mot de passe de ce compte utilise un vérificateur 10g, non supporté en mode thin.\n"
                "Deux solutions :\n"
                "  1) Mode thick : dézipper un Instant Client 64 bits (Basic Light suffit) et renseigner\n"
                "     client_dir = C:\\oracle\\instantclient_21_13 dans config.ini [database].\n"
                "  2) Demander au DBA de régénérer le mot de passe du compte (ALTER USER ... IDENTIFIED BY)\n"
                "     avec SQLNET.ALLOWED_LOGON_VERSION_SERVER >= 11, ce qui crée un vérificateur 11g/12c.")
        raise


def _schema(cfg) -> str:
    s = (cfg["database"].get("schema", "") or "").strip()
    return f"{s}." if s else ""


def job_from_description(desc: str | None) -> str | None:
    m = JOB_RE.match((desc or "").strip())
    return m.group(1) if m else None


def test_connexion() -> str:
    cfg = load_config()
    with _connect_oracle(cfg) as ocon:
        cur = ocon.cursor()
        cur.execute(f"SELECT COUNT(*), MAX(request_date) FROM {_schema(cfg)}fnd_concurrent_requests "
                    "WHERE request_date >= SYSDATE - 1")
        n, d = cur.fetchone()
    return f"Connexion OK. {n} demandes sur 24 h, dernière à {d:%d/%m %H:%M}."


def refresh_programs() -> str:
    cfg = load_config()
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with _connect_oracle(cfg) as ocon:
        cur = ocon.cursor()
        cur.arraysize = 5000
        cur.execute(SQL_PROGRAMS.format(s=_schema(cfg)))
        rows = cur.fetchall()
    con = connect()
    con.executemany(UPSERT_PROG, [(*r, now) for r in rows])
    con.commit()
    con.close()
    return f"{len(rows)} programmes concurrents chargés."


def refresh_requests(heures: float | None = None) -> str:
    cfg = load_config()
    ora = cfg["oracle"] if cfg.has_section("oracle") else {}
    heures = heures or float(ora.get("heures_historique", 48))
    filtre = (ora.get("filtre_description", "") or "").strip() or None
    progs = [p.strip() for p in (ora.get("programmes_suivis", "") or "").split(",") if p.strip()]
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    binds = {"heures": heures, "filtre": filtre}
    if progs:
        names = ", ".join(f":p{i}" for i in range(len(progs)))
        binds.update({f"p{i}": p for i, p in enumerate(progs)})
    else:
        names = "NULL"
    sql = SQL_REQUESTS.format(s=_schema(cfg), progs=names)

    with _connect_oracle(cfg) as ocon:
        cur = ocon.cursor()
        cur.arraysize = 5000
        cur.execute(sql, binds)
        rows = cur.fetchall()

    # job Control-M : depuis la description, sinon hérité du parent (même lot ou déjà en base)
    con = connect()
    connus = {r[0]: r[1] for r in con.execute("SELECT request_id, job_name FROM ora_requests WHERE job_name IS NOT NULL")}
    by_id = {r[0]: r for r in rows}
    jobs: dict[int, str | None] = {}
    for r in rows:
        jobs[r[0]] = job_from_description(r[18])
    for r in rows:
        rid, parent = r[0], r[14]
        if not jobs[rid] and parent:
            jobs[rid] = jobs.get(parent) or connus.get(parent) or (
                job_from_description(by_id[parent][18]) if parent in by_id else None)

    payload = []
    mapping: dict[str, tuple[str, str]] = {}
    for r in rows:
        (rid, pshort, pname, app, ph, st, phase, status, rdate, rstart, astart, acomp,
         user, resp, parent, rint, runit, args, desc, ctext, logf, outf) = r
        payload.append((rid, pshort, pname, app, ph, st, phase, status, rdate, rstart, astart, acomp,
                        user, resp, parent, None if rint is None else str(rint), runit, args, desc,
                        ctext, logf, outf, jobs[rid], now))
        j = job_from_description(desc)
        if j:
            mapping[j] = (pshort, (desc or "").strip())
    con.executemany(UPSERT_REQ, payload)
    con.executemany(
        "INSERT INTO job_mapping(job_name, program_short, commentaire) VALUES (?,?,?) "
        "ON CONFLICT(job_name) DO UPDATE SET program_short=excluded.program_short, commentaire=excluded.commentaire",
        [(j, p, d) for j, (p, d) in mapping.items()])
    con.commit()
    con.close()
    pending = sum(1 for r in rows if r[4] == "P")
    running = sum(1 for r in rows if r[4] == "R")
    err = sum(1 for r in rows if r[4] == "C" and r[5] in ("E", "G", "X"))
    return (f"{len(rows)} demandes Oracle chargées : {running} en cours, {pending} en attente, "
            f"{err} terminées en erreur/avertissement ; {len(mapping)} jobs Control-M reconnus.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--jours", type=float, help="historique en jours (chargement initial)")
    ap.add_argument("--programmes", action="store_true", help="rafraîchir aussi le référentiel des programmes")
    ap.add_argument("--test", action="store_true", help="tester la connexion et sortir")
    a = ap.parse_args()
    if a.test:
        print(test_connexion())
    else:
        if a.programmes:
            print(refresh_programs())
        print(refresh_requests(a.jours * 24 if a.jours else None))
