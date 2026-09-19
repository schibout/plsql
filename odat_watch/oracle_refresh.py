"""Brique Oracle Apps : charge FND_CONCURRENT_PROGRAMS et FND_CONCURRENT_REQUESTS dans SQLite.

Récupère :
  - le référentiel des programmes concurrents (ora_programs), option --programmes
  - première fois : les demandes des N derniers jours (config jours_initial, défaut 90) ; ensuite seulement
    celles créées ou modifiées depuis le dernier chargement (borne mémorisée dans parametres) + toutes les demandes
    en attente (PHASE_CODE = 'P', donc planifiées pour ce soir / demain)          (ora_requests)
La DESCRIPTION des demandes lancées par Control-M via DKA_SLAUNCHER contient le nom du job Control-M
("FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh") : elle alimente job_name et job_mapping.
Les demandes filles (PARENT_REQUEST_ID) héritent du job_name de leur parent.

Usage :
    python oracle_refresh.py                 # demandes des 48 dernières heures + en attente
    python oracle_refresh.py --jours 90      # chargement initial long
    python oracle_refresh.py --programmes    # rafraîchit aussi le référentiel des programmes
    python oracle_refresh.py --test          # teste seulement la connexion
    python oracle_refresh.py --clients       # liste les clients Oracle du poste et leur architecture
"""
from __future__ import annotations
import argparse
import configparser
import re
from datetime import datetime, timedelta

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
  AND  (:depuis IS NULL OR fcp.last_update_date >= :depuis OR fcpt.last_update_date >= :depuis)
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
WHERE  (fcr.request_id > :max_id OR fcr.request_date >= :depuis OR fcr.last_update_date >= :depuis
        OR fcr.phase_code IN ('P', 'R'))
  AND  (   :filtre IS NULL
        OR fcr.description LIKE :filtre
        OR fcp.concurrent_program_name IN ({progs})
        OR fcr.parent_request_id IN (SELECT p.request_id FROM {s}fnd_concurrent_requests p
                                     WHERE p.description LIKE :filtre
                                       AND p.request_date >= :depuis - 2))
ORDER BY fcr.request_id
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
    cfg = configparser.ConfigParser(interpolation=None, inline_comment_prefixes=(";", "#"))
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
            raise SystemExit(_diag_client(client_dir, e))
    elif mode == "thick":
        oracledb.init_oracle_client()  # cherche dans le PATH
        _THICK_DONE = True


def _arch_dll(path) -> str | None:
    """'x86' ou 'x64' d'après l'en-tête PE d'une DLL, None si illisible."""
    import struct
    try:
        with open(path, "rb") as f:
            f.seek(0x3C)
            off = struct.unpack("<I", f.read(4))[0]
            f.seek(off + 4)
            machine = struct.unpack("<H", f.read(2))[0]
        return {0x14C: "x86", 0x8664: "x64"}.get(machine)
    except OSError:
        return None


def _diag_client(client_dir: str, err: Exception) -> str:
    import platform
    from pathlib import Path
    py = platform.architecture()[0]
    d = Path(client_dir)
    oci = d / "oci.dll"
    if not oci.exists() and (d / "bin" / "oci.dll").exists():
        return (f"{client_dir} est un ORACLE_HOME complet : indiquez son sous-dossier bin\n"
                f"  client_dir = {d / 'bin'}")
    if not oci.exists():
        return (f"Aucun oci.dll dans {client_dir}. Indiquez le dossier qui contient oci.dll "
                "(Instant Client dézippé, ou <ORACLE_HOME>\\bin).")
    arch = _arch_dll(oci)
    if arch == "x86" and py == "64bit":
        return (f"Le client {client_dir} est 32 bits, votre Python est 64 bits : incompatibles.\n"
                "Deux options :\n"
                "  1) Dézipper un Instant Client 64 bits (Basic Light, 19c+) dans C:\\oracle\\instantclient_21_13\n"
                "     et mettre client_dir = C:\\oracle\\instantclient_21_13\n"
                "  2) Chercher un autre client 64 bits déjà présent : python oracle_refresh.py --clients")
    if arch == "x64" and py == "32bit":
        return f"Le client {client_dir} est 64 bits mais votre Python est 32 bits."
    return (f"Client Oracle dans {client_dir} ({arch or '?'}, Python {py}) non chargeable : {err}\n"
            "Souvent une DLL dépendante manquante (VC++ Redistributable 2017+ pour les Instant Client 19c+).")


def lister_clients() -> str:
    """Cherche les oci.dll présents sur le poste (dossiers Oracle usuels + PATH) et donne leur architecture."""
    import os
    import platform
    from pathlib import Path
    candidats: list[Path] = []
    for base in (r"C:\oracle", r"C:\app", r"C:\OraHome1", r"C:\Oracle", r"C:\instantclient",
                 r"C:\Program Files\Oracle", r"C:\Program Files (x86)\Oracle"):
        b = Path(base)
        if b.exists():
            for motif in ("oci.dll", "*/oci.dll", "*/*/oci.dll", "*/*/*/oci.dll", "*/*/*/*/oci.dll"):
                candidats += list(b.glob(motif))
    directs = [Path(p) for p in os.environ.get("PATH", "").split(";") if p]
    for base in (Path("C:/"), Path.home(), Path.home() / "Downloads", Path.home() / "Desktop"):
        if base.exists():
            directs += [d for d in base.iterdir() if d.is_dir() and d.name.lower().startswith("instantclient")]
    for d in directs:
        if (d / "oci.dll").exists():
            candidats.append(d / "oci.dll")
    vus, lignes = set(), []
    for oci in candidats:
        if oci in vus:
            continue
        vus.add(oci)
        lignes.append(f"  {_arch_dll(oci) or '?':4} {oci.parent}")
    ok = [l for l in lignes if l.strip().startswith("x64")]
    out = [f"Python {platform.architecture()[0]}. Clients Oracle trouvés :"] + (lignes or ["  aucun"])
    if ok:
        out.append(f"\nUtilisable : client_dir = {ok[0].split(None, 1)[1]}")
    else:
        out.append("\nAucun client 64 bits : dézipper un Instant Client Basic Light 64 bits (19c+) dans "
                   r"C:\oracle\instantclient_21_13 puis client_dir = C:\oracle\instantclient_21_13")
    return "\n".join(out)


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


# « FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh » : le script lancé par concsub nomme le programme
# concurrent (DKA_IPAPROJETHRM), cf. ChaineControleM/Analyse_Chaine_ControlM_Concsub.md.
SCRIPT_RE = re.compile(r":\s*([A-Za-z0-9_\-]+?)(?:_JOB)?\.(?:sh|ksh)(?![A-Za-z0-9])", re.I)


def programme_from_description(desc: str | None) -> str | None:
    m = SCRIPT_RE.search(desc or "")
    return m.group(1).upper() if m else None


def test_connexion() -> str:
    cfg = load_config()
    with _connect_oracle(cfg) as ocon:
        cur = ocon.cursor()
        cur.execute(f"SELECT COUNT(*), MAX(request_date) FROM {_schema(cfg)}fnd_concurrent_requests "
                    "WHERE request_date >= SYSDATE - 1")
        n, d = cur.fetchone()
    return f"Connexion OK. {n} demandes sur 24 h, dernière à {d:%d/%m %H:%M}."


# ------------------------------------------------------------------ chargement incrémental
# Première fois : tout l'historique utile (config [oracle] jours_initial, défaut 90 j). Ensuite, seulement
# ce qui a bougé depuis le dernier chargement (request_date ou last_update_date, plus les demandes en
# attente / en cours), avec une heure de marge. La borne est l'heure Oracle (SYSDATE) du dernier chargement,
# mémorisée dans la table parametres.
MARGE = timedelta(hours=1)
LOT = 20_000          # lignes par lot lors du chargement des demandes


def borne_chargement(cle: str, con) -> datetime | None:
    row = con.execute("SELECT valeur FROM parametres WHERE cle = ?", (f"oracle.{cle}.depuis",)).fetchone()
    return datetime.strptime(row[0], "%Y-%m-%d %H:%M:%S") if row and row[0] else None


def _memoriser_borne(cle: str, quand: datetime, con, signature: str = "") -> None:
    for k, v in ((f"oracle.{cle}.depuis", quand.strftime("%Y-%m-%d %H:%M:%S")), (f"oracle.{cle}.signature", signature)):
        con.execute("INSERT INTO parametres(cle, valeur) VALUES (?, ?) ON CONFLICT(cle) DO UPDATE SET valeur = excluded.valeur", (k, v))


def _signature(cfg) -> str:
    """Périmètre du chargement : s'il change (filtre, programmes suivis, profondeur), le delta ne suffit plus."""
    ora = cfg["oracle"] if cfg.has_section("oracle") else {}
    return "|".join(((ora.get("filtre_description", "") or "").strip(), (ora.get("programmes_suivis", "") or "").strip(),
                     str(ora.get("jours_initial", 365)).strip()))


def _signature_memorisee(cle: str, con) -> str | None:
    row = con.execute("SELECT valeur FROM parametres WHERE cle = ?", (f"oracle.{cle}.signature",)).fetchone()
    return row[0] if row else None


def etat_chargement(con) -> str:
    """Résumé pour l'interface : volume en base et dernier chargement."""
    n = con.execute("SELECT COUNT(*) FROM ora_requests").fetchone()[0]
    borne = borne_chargement("demandes", con)
    mn, mx = con.execute("SELECT MIN(request_date), MAX(request_date) FROM ora_requests").fetchone()
    periode = f", du {mn[:10]} au {mx[:10]}" if mn and mx else ""
    return f"{n} demandes en base{periode} · dernier chargement : {borne:%d/%m %H:%M}" if borne else f"{n} demandes en base · jamais chargé"


def _heure_oracle(cur) -> datetime:
    cur.execute("SELECT SYSDATE FROM dual")
    return cur.fetchone()[0]


AUCUN_ID = 2 ** 62   # request_id > AUCUN_ID est toujours faux : neutralise le critère max(request_id)


def _fenetre(cle: str, cfg, con, cur, heures: float | None, complet: bool) -> tuple[datetime, int, str, datetime]:
    """(borne :depuis, borne :max_id, libellé du mode, heure Oracle du chargement).

    Delta = toute demande de request_id supérieur au plus grand déjà chargé (rien ne peut être manqué,
    même si le chargement précédent a été interrompu) + demandes modifiées depuis la dernière borne
    (fin d'exécution, changement de statut) + demandes en attente / en cours."""
    ora = cfg["oracle"] if cfg.has_section("oracle") else {}
    jours_initial = float(ora.get("jours_initial", 365))
    maintenant = _heure_oracle(cur)
    borne = borne_chargement(cle, con)
    max_id = con.execute("SELECT MAX(request_id) FROM ora_requests").fetchone()[0]
    if heures:
        return maintenant - timedelta(hours=heures), AUCUN_ID, f"fenêtre de {heures:g} h", maintenant
    if complet or borne is None or max_id is None:
        return maintenant - timedelta(days=jours_initial), AUCUN_ID, f"chargement initial ({jours_initial:g} j)", maintenant
    if _signature_memorisee(cle, con) != _signature(cfg):
        return (maintenant - timedelta(days=jours_initial), AUCUN_ID,
                f"chargement initial ({jours_initial:g} j) — périmètre modifié dans config.ini", maintenant)
    return borne - MARGE, int(max_id), f"delta depuis le {borne:%d/%m %H:%M} (request_id > {max_id})", maintenant


def refresh_programs(complet: bool = False) -> str:
    cfg = load_config()
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    con = connect()
    with _connect_oracle(cfg) as ocon:
        cur = ocon.cursor()
        cur.arraysize = 5000
        borne = None if complet else borne_chargement("programmes", con)
        maintenant = _heure_oracle(cur)
        depuis = None if borne is None else borne - MARGE
        mode = "chargement initial" if depuis is None else f"delta depuis le {borne:%d/%m %H:%M}"
        cur.execute(SQL_PROGRAMS.format(s=_schema(cfg)), {"depuis": depuis})
        rows = cur.fetchall()
    with con:
        con.executemany(UPSERT_PROG, [(*r, now) for r in rows])
        _memoriser_borne("programmes", maintenant, con)
    con.close()
    return f"{len(rows)} programmes concurrents chargés ({mode})."


def refresh_requests(heures: float | None = None, complet: bool = False) -> str:
    """heures : fenêtre explicite (CLI --jours) ; complet : refait le chargement initial ; sinon delta."""
    cfg = load_config()
    ora = cfg["oracle"] if cfg.has_section("oracle") else {}
    filtre = (ora.get("filtre_description", "") or "").strip() or None
    progs = [p.strip() for p in (ora.get("programmes_suivis", "") or "").split(",") if p.strip()]
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    binds = {"filtre": filtre}
    if progs:
        names = ", ".join(f":p{i}" for i in range(len(progs)))
        binds.update({f"p{i}": p for i, p in enumerate(progs)})
    else:
        names = "NULL"
    sql = SQL_REQUESTS.format(s=_schema(cfg), progs=names)

    con = connect()
    with _connect_oracle(cfg) as ocon:
        cur = ocon.cursor()
        cur.arraysize = 5000
        binds["depuis"], binds["max_id"], mode, maintenant = _fenetre("demandes", cfg, con, cur, heures, complet)
        cur.execute(sql, binds)

        # Traitement par lots, dans l'ordre des request_id : un parent (lanceur DKA_SLAUNCHER, dont la
        # description porte le nom du job Control-M) précède toujours ses demandes filles, qui héritent
        # de son job. Les lots précédents sont retrouvés via `connus` (mémoire) ou la base.
        connus = {r[0]: r[1] for r in con.execute("SELECT request_id, job_name FROM ora_requests WHERE job_name IS NOT NULL")}
        mapping: dict[str, tuple[str, str, str | None]] = {}
        total = pending = running = err = 0
        while True:
            rows = cur.fetchmany(LOT)
            if not rows:
                break
            by_id = {r[0]: r for r in rows}
            jobs: dict[int, str | None] = {r[0]: job_from_description(r[18]) for r in rows}
            for r in rows:
                rid, parent = r[0], r[14]
                if not jobs[rid] and parent:
                    jobs[rid] = jobs.get(parent) or connus.get(parent) or (
                        job_from_description(by_id[parent][18]) if parent in by_id else None)
            payload = []
            for r in rows:
                (rid, pshort, pname, app, ph, st, phase, status, rdate, rstart, astart, acomp,
                 user, resp, parent, rint, runit, args, desc, ctext, logf, outf) = r
                payload.append((rid, pshort, pname, app, ph, st, phase, status, rdate, rstart, astart, acomp,
                                user, resp, parent, None if rint is None else str(rint), runit, args, desc,
                                ctext, logf, outf, jobs[rid], now))
                if jobs[rid]:
                    connus[rid] = jobs[rid]
                j = job_from_description(desc)
                if j:
                    mapping[j] = (pshort, (desc or "").strip(), programme_from_description(desc))
                total += 1
                pending += ph == "P"
                running += ph == "R"
                err += ph == "C" and st in ("E", "G", "X")
            with con:
                con.executemany(UPSERT_REQ, payload)

    with con:
        con.executemany(
            "INSERT INTO job_mapping(job_name, program_short, commentaire, programme) VALUES (?,?,?,?) "
            "ON CONFLICT(job_name) DO UPDATE SET program_short=excluded.program_short, commentaire=excluded.commentaire, "
            "programme=COALESCE(excluded.programme, job_mapping.programme)",
            [(j, p, d, prog) for j, (p, d, prog) in mapping.items()])
        if not heures:   # une fenêtre explicite ne fait pas avancer la borne du delta
            _memoriser_borne("demandes", maintenant, con, _signature(cfg))
    # les programmes nouvellement connus alimentent le référentiel jobs <-> programmes
    import referentiel
    referentiel.synchroniser(con)
    con.close()
    conseil = (" — 0 demande : vérifier filtre_description / programmes_suivis dans config.ini [oracle]."
               if not total and (filtre or progs) else "")
    return (f"{total} demandes Oracle chargées ({mode}) : {running} en cours, {pending} en attente, "
            f"{err} terminées en erreur/avertissement ; {len(mapping)} jobs Control-M reconnus.{conseil}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--jours", type=float, help="historique en jours (chargement initial)")
    ap.add_argument("--programmes", action="store_true", help="rafraîchir aussi le référentiel des programmes")
    ap.add_argument("--complet", action="store_true", help="refaire le chargement initial (jours_initial) au lieu du delta")
    ap.add_argument("--test", action="store_true", help="tester la connexion et sortir")
    ap.add_argument("--clients", action="store_true", help="lister les clients Oracle du poste (32/64 bits)")
    a = ap.parse_args()
    if a.clients:
        print(lister_clients())
    elif a.test:
        print(test_connexion())
    else:
        if a.programmes:
            print(refresh_programs(complet=a.complet))
        print(refresh_requests(a.jours * 24 if a.jours else None, complet=a.complet))
