"""Référentiel des jobs Control-M et de leur programme Oracle Applications.

Alimenté automatiquement (jobs vus dans les photos ODAT, programme déduit des demandes Oracle par
forecast.programmes_oracle), corrigeable à la main : une saisie manuelle est prioritaire partout dans
l'application et survit aux resynchronisations ; l'effacer rend la main à la valeur automatique.
"""
from __future__ import annotations
import sqlite3
from datetime import datetime

import pandas as pd

import forecast


def synchroniser(con: sqlite3.Connection) -> int:
    """Ajoute les jobs inconnus, rafraîchit description / chaîne / programme auto. Renvoie le nb de nouveaux jobs."""
    jobs = con.execute("""
        SELECT j.job_name, j.application, j.group_name, j.description, j.member, MAX(s.snap_time) AS vu_le
        FROM ctm_jobs j JOIN snapshots s ON s.id = j.snapshot_id
        WHERE j.task_type IS NULL OR j.task_type <> 'Dummy'
        GROUP BY j.job_name""").fetchall()
    auto = forecast.programmes_oracle(con)
    connus = {r[0] for r in con.execute("SELECT job_name FROM referentiel_jobs")}
    nouveaux = 0
    with con:
        for job, app, chaine, desc, member, vu_le in jobs:
            if job in connus:
                con.execute("UPDATE referentiel_jobs SET application_ctm=?, chaine=?, description=?, script=?, "
                            "programme_auto=?, vu_le=? WHERE job_name=?",
                            (app, chaine, desc or "", member or "", auto.get(job), vu_le, job))
            else:
                con.execute("INSERT INTO referentiel_jobs(job_name, application_ctm, chaine, description, script, "
                            "programme_auto, vu_le) VALUES (?,?,?,?,?,?,?)",
                            (job, app, chaine, desc or "", member or "", auto.get(job), vu_le))
                nouveaux += 1
    return nouveaux


def enregistrer(con: sqlite3.Connection, job: str, programme: str, application: str, commentaire: str) -> None:
    """Saisie manuelle ; des champs vides effacent la saisie (retour à l'automatique)."""
    vals = [(v or "").strip() or None for v in (programme, application, commentaire)]
    with con:
        con.execute("UPDATE referentiel_jobs SET programme=?, application_ora=?, commentaire=?, maj_le=? WHERE job_name=?",
                    (*vals, datetime.now().strftime("%Y-%m-%d %H:%M:%S") if any(vals) else None, job))


def table(con: sqlite3.Connection) -> pd.DataFrame:
    """Vue complète : programme = saisie manuelle sinon auto ; source = manuel | auto | à renseigner."""
    df = pd.read_sql_query("SELECT * FROM referentiel_jobs ORDER BY job_name", con)
    for c in ("programme", "programme_auto", "application_ora", "commentaire", "description", "chaine", "script"):
        df[c] = df[c].fillna("")
    manuel = df["programme"] != ""
    df["source"] = "à renseigner"
    df.loc[df["programme_auto"] != "", "source"] = "auto"
    df.loc[manuel, "source"] = "manuel"
    df["programme"] = df["programme"].where(manuel, df["programme_auto"])
    return df


def programmes(con: sqlite3.Connection) -> dict[str, str]:
    """Job -> programme à afficher (manuel prioritaire, sinon auto). Complété par les jobs hors référentiel."""
    out = forecast.programmes_oracle(con)
    for job, prog, auto in con.execute("SELECT job_name, programme, programme_auto FROM referentiel_jobs"):
        if prog:
            out[job] = prog
        elif auto and job not in out:
            out[job] = auto
    return out
