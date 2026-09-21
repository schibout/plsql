"""Génère des données Oracle simulées (ora_requests, ora_programs, job_mapping) pour tester l'onglet
Oracle sans accès à la base. À utiliser UNIQUEMENT sur un poste sans Oracle : les vraies données
écrasent le mock au premier `oracle_refresh.py`.

Principe : pour chaque exécution Control-M FIN-FINANCE observée dans les photos ODAT dont le job passe
par le lanceur EBS (member vide, task_type Job), on fabrique la demande concurrente correspondante :
  - une demande parent DKA_SLAUNCHER (description = "<job> : <script>.sh"), même horaire que Control-M
  - une demande fille = programme métier déduit du nom du job (dictionnaire ci-dessous), 30 s plus tard
  - statut aligné sur Control-M (Ended OK → Normal, Ended Not OK → Error, Executing → Running,
    Wait for Event futur → Pending planifié)
Les demandes RBAFBIMP / DKA_SRBCTRLRB dont on possède les logs (.req/.out) sont créées avec leur vrai
request_id, pour que le diagnostic fonctionne.

Usage : python mock_oracle.py [--reset]
"""
from __future__ import annotations
import argparse
import random
import re
from datetime import datetime, timedelta

from db import connect

random.seed(42)
NOW = datetime.now().replace(microsecond=0)

# programme métier simulé selon le motif du job Control-M (indicatif, remplacé par la réalité sur Dalkia)
PROGRAMMES = [
    (r"FINFIN_J18TRT", ("DKA_IPAPROJETHRM", "DKA : Import des projets HRM dans PA", "DKA")),
    (r"FINFIN_J22TRT", ("DKA_APDUPSITEFOU", "DKA : Duplication des sites fournisseurs", "DKA")),
    (r"FINFIN_J15TRT", ("RBRAPAUTO", "XXRB - Rapprochement bancaire automatique", "XXRB")),
    (r"FINFIN_J32TRT", ("DKA_APPRELEVAUTO", "DKA : Automatisation des prélèvements fournisseurs", "DKA")),
    (r"FINFIN_J33TRT", ("FNDGSCST", "Gather Schema Statistics", "FND")),
    (r"FINFIN_J23TRT", ("APXIIMPT", "Payables Open Interface Import", "SQLAP")),
    (r"FINFIN_J1[2347]TRT", ("DKA_GLIMPORT", "DKA : Import des écritures GL", "DKA")),
    (r"FINFIN_J2[01]TRT", ("APXPBSEL", "Payables Payment Batch Selection", "SQLAP")),
    (r"FINEXT_J14INT_0[56].*IMP", ("RBAFBIMP", "XXRB - Import fichier des banques", "XXRB")),
    (r"FINEXT_J14INT_0[56].*WRK02", ("DKA_SRBCTRLRB", "DKA : Contrôle des relevés bancaires", "DKA")),
    (r"FINEXT_J14INT_0[56].*MEL", ("DKA_SRBMAILMANQ", "DKA : Relevés manquants par mail", "DKA")),
    (r"FINEXT_J1[578]INT.*IMP", ("DKA_APIMPFOUR", "DKA : Interface d'import des fournisseurs iValua", "DKA")),
    (r"FINEXT_J20INT.*IMP", ("DKA_APIMPFACDSP", "DKA : Chargement des factures iValua (CONTROL_DSP)", "DKA")),
    (r"FINEXT_J1[123]INT.*IMP", ("DKA_APIMPFACXER", "DKA : Chargement des factures XEROX", "DKA")),
    (r"FINXXX_J14INT", ("DKA_APRATTIMG", "DKA : Rattachement des images de factures", "DKA")),
    (r"FINDTR_J11GEN.*EXP", ("DKA_DTREXPORT", "DKA : Extraction pour le décisionnel DTR", "DKA")),
    (r"FINEXT_J1\dGEN.*EXP", ("DKA_APEXPCDE", "DKA : Exportation des commandes", "DKA")),
    (r"FINSIC_J11INT", ("DKA_SICIMP", "DKA : Intégration SIC", "DKA")),
    (r"FINHEC", ("DKA_HECEXP", "DKA : Extraction Hercule chiffrage", "DKA")),
    (r".*", ("DKA_GENERIQUE", "DKA : Traitement générique", "DKA")),
]
LANCEUR = ("DKA_SLAUNCHER", "DKA : Lanceur (SHELL)", "DKA")
USERS = ["EXPLOIT_CTM", "EXPLOIT_CTM", "EXPLOIT_CTM", "SCHIBOUT", "AROUX"]

LOG_DIR = "/u01/app/PDBFINP1/inst/apps/PDBFINP1_ldkfinp01/logs/appl/conc/log/"
OUT_DIR = "/u01/app/PDBFINP1/inst/apps/PDBFINP1_ldkfinp01/logs/appl/conc/out/"


def programme(job: str):
    for rx, p in PROGRAMMES:
        if re.match(rx, job):
            return p
    return PROGRAMMES[-1][1]


def statut(ctm_status: str, start: datetime | None, end: datetime | None):
    """→ (phase_code, status_code, phase, status)."""
    if ctm_status == "Ended OK":
        return ("C", "C", "Terminé", "Normal") if random.random() > 0.08 else ("C", "G", "Terminé", "Avertissement")
    if ctm_status == "Ended Not OK":
        return ("C", "E", "Terminé", "Erreur")
    if ctm_status == "Executing":
        return ("R", "R", "En cours", "Normal")
    if start and start < NOW:
        # cyclique "Wait for Event" déjà passé par une exécution : côté Oracle elle est terminée
        return ("C", "C", "Terminé", "Normal")
    return ("P", "Q", "En attente", "Programmé")


def main(reset: bool):
    con = connect()
    if reset:
        con.execute("DELETE FROM ora_requests")
        con.execute("DELETE FROM ora_programs")
    refreshed = NOW.strftime("%Y-%m-%d %H:%M:%S")

    # ---------- exécutions Control-M passant par le lanceur (dernière photo connue par exécution)
    rows = con.execute("""
        SELECT j.job_name, j.description, j.odate, j.start_time, j.end_time, j.status, j.rerun, MAX(s.snap_time)
        FROM ctm_jobs j JOIN snapshots s ON s.id = j.snapshot_id
        WHERE j.application = 'FIN-FINANCE' AND j.task_type = 'Job' AND COALESCE(j.member, '') = ''
        GROUP BY j.job_name, j.odate, j.start_time
        ORDER BY j.start_time""").fetchall()

    rid = 49070000
    reqs, progs, mapping = [], {}, {}
    progs[LANCEUR[0]] = LANCEUR
    for r in rows:
        job, desc, odate, st, en, status, rerun, _ = r
        pshort, pname, app = programme(job)
        progs[pshort] = (pshort, pname, app)
        script = f"{pshort}_JOB.sh"
        mapping[job] = (pshort, f"{job} : {script}")
        if st:
            start = datetime.fromisoformat(st)
            end = datetime.fromisoformat(en) if en else None
            req_date = start - timedelta(seconds=random.randint(2, 20))
        else:
            # pas démarré : demande planifiée à l'heure habituelle (fallback : 20:00 le jour de l'odate)
            start = datetime.fromisoformat(odate).replace(hour=20, minute=0) if odate else NOW + timedelta(hours=2)
            if start < NOW:
                continue  # dans le passé sans exécution → rien côté Oracle
            end, req_date = None, NOW - timedelta(minutes=30)
        ph, sc, phase, stt = statut(status, start, end)
        f = lambda d: d.strftime("%Y-%m-%d %H:%M:%S") if d else None
        parent_id = rid
        # parent : lanceur
        reqs.append((parent_id, LANCEUR[0], LANCEUR[1], LANCEUR[2], ph, sc, phase, stt, f(req_date), f(start),
                     f(start) if ph != "P" else None, f(end), random.choice(USERS), "DKA Exploitation", None,
                     None, None, f"{script}, {odate}", f"{job} : {script}",
                     "Normal completion" if sc == "C" else ("Erreur dans le traitement fils" if sc == "E" else None),
                     f"{LOG_DIR}l{parent_id}.req", f"{OUT_DIR}o{parent_id}.out", job, refreshed))
        rid += 1
        # fille : programme métier
        child_start = start + timedelta(seconds=30)
        child_end = (end - timedelta(seconds=5)) if end and end > child_start else end
        reqs.append((rid, pshort, pname, app, ph, sc, phase, stt, f(start), f(child_start),
                     f(child_start) if ph != "P" else None, f(child_end), "EXPLOIT_CTM", "DKA Exploitation",
                     parent_id, None, None, f"{odate}, N", None,
                     ("Normal completion" if sc == "C" else
                      "ORA-20001: Fichier d'entrée absent ou vide" if sc == "E" else
                      "Avertissement : 3 lignes rejetées" if sc == "G" else None),
                     f"{LOG_DIR}l{rid}.req", f"{OUT_DIR}o{rid}.out", job, refreshed))
        rid += 1

    # ---------- demandes planifiées "ce soir / demain" qui ne passent pas par Control-M (récurrentes)
    for i, (pshort, pname, app, heure, user, interv) in enumerate([
        ("FNDCPPUR", "Purge Concurrent Request and/or Manager Data", "FND", 22, "SYSADMIN", (1, "DAYS")),
        ("APXTRSWP", "Payables Transfer to General Ledger", "SQLAP", 21, "EXPLOIT_CTM", (1, "DAYS")),
        ("GLLEZL", "Journal Import", "SQLGL", 23, "EXPLOIT_CTM", (1, "DAYS")),
        ("DKA_APRELANCE", "DKA : Relance automatique fournisseurs", "DKA", 6, "SCHIBOUT", (7, "DAYS")),
    ]):
        progs[pshort] = (pshort, pname, app)
        start = NOW.replace(hour=heure, minute=0, second=0)
        if start < NOW:
            start += timedelta(days=1)
        reqs.append((rid, pshort, pname, app, "P", "Q", "En attente", "Programmé", (NOW - timedelta(days=3)).strftime("%Y-%m-%d %H:%M:%S"),
                     start.strftime("%Y-%m-%d %H:%M:%S"), None, None, user, "System Administrator", None,
                     str(interv[0]), interv[1], "", None, None, None, None, None, refreshed))
        rid += 1

    # ---------- demandes réelles dont on a les logs (.req/.out) → vrais request_id
    logs = con.execute("SELECT request_id, program, started, ended, erreurs FROM ora_request_logs WHERE kind='req'").fetchall()
    for l in logs:
        prog = (l["program"] or "").split(" — ")[0] or "RBAFBIMP"
        pname = (l["program"] or "").split(" — ")[-1]
        app = "XXRB" if prog.startswith("RB") else "DKA"
        progs.setdefault(prog, (prog, pname, app))
        def p(d):
            try:
                return datetime.strptime(d, "%d-%b-%Y %H:%M:%S").strftime("%Y-%m-%d %H:%M:%S")
            except Exception:  # noqa: BLE001
                return None
        out = con.execute("SELECT erreurs FROM ora_request_logs WHERE request_id=? AND kind='out'", (l["request_id"],)).fetchone()
        import json as _j
        nb025 = next((e["nb"] for e in _j.loads((out["erreurs"] if out else None) or "[]") if e["code"] == "Erreur 025"), 0)
        sc = "E" if nb025 >= 50 else ("G" if nb025 else "C")
        job = "FINEXT_J14INT_05_IMP01_Q" if prog == "RBAFBIMP" else ("FINEXT_J14INT_05_WRK02_Q" if prog == "DKA_SRBCTRLRB" else None)
        reqs.append((l["request_id"], prog, pname, app, "C", sc, "Terminé", {"C": "Normal", "G": "Avertissement", "E": "Erreur"}[sc],
                     p(l["started"]), p(l["started"]), p(l["started"]), p(l["ended"]), "EXPLOIT_CTM", "DKA Exploitation",
                     None, None, None, "AFB120.txt" if prog == "RBAFBIMP" else "", f"{job} : {prog}_JOB.sh" if job else None,
                     {"C": "Normal completion", "G": "Avertissement : lignes rejetées, voir sortie",
                      "E": f"Fichier rejeté en totalité : {nb025} × Erreur 025"}[sc],
                     f"{LOG_DIR}l{l['request_id']}.req", f"{OUT_DIR}o{l['request_id']}.out", job, refreshed))

    con.executemany("""INSERT OR REPLACE INTO ora_requests(request_id, program_short, program_name, application_short,
        phase_code, status_code, phase, status, request_date, requested_start, actual_start, actual_completion,
        requestor, responsibility, parent_request_id, resubmit_interval, resubmit_unit, argument_text, description,
        completion_text, logfile_name, outfile_name, job_name, refreshed_at, source)
        VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)""", [(*r, "mock") for r in reqs])
    con.executemany("""INSERT OR REPLACE INTO ora_programs(program_short, program_name, application_short, application_name,
        executable_name, execution_method, execution_file, enabled, description, refreshed_at, source)
        VALUES (?,?,?,?,?,?,?,?,?,?,?)""",
        [(s, n, a, {"DKA": "Application Specifique DKA", "XXRB": "ELSY-RB", "SQLAP": "Payables", "SQLGL": "General Ledger",
                    "FND": "Application Object Library"}.get(a, a),
          s, "Host" if s == "DKA_SLAUNCHER" else ("PL/SQL Stored Procedure" if s.startswith("DKA") else "Oracle Reports"),
          f"{s}.sh" if s == "DKA_SLAUNCHER" else f"{s}_PKG.MAIN", "Y", "(mock)", refreshed, "mock")
         for s, n, a in progs.values()])
    con.executemany("INSERT OR REPLACE INTO job_mapping(job_name, program_short, commentaire) VALUES (?,?,?)",
                    [(j, p, d) for j, (p, d) in mapping.items()])
    con.commit()
    n_err = sum(1 for r in reqs if r[5] in ("E", "G"))
    n_p = sum(1 for r in reqs if r[4] == "P")
    print(f"Mock : {len(reqs)} demandes ({n_p} planifiées, {n_err} erreur/avertissement), {len(progs)} programmes, "
          f"{len(mapping)} jobs mappés. Les vraies données remplaceront tout au premier oracle_refresh.py.")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--reset", action="store_true", help="vide ora_requests / ora_programs avant")
    main(ap.parse_args().reset)
