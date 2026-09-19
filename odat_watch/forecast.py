"""Profils d'exécution et prévisions (ce soir / demain) à partir de l'historique SQLite."""
from __future__ import annotations
import statistics
from dataclasses import dataclass, field
from datetime import datetime, date, timedelta, time

import pandas as pd

from db import connect

STATUS_DONE = ("Ended OK", "Ended Not OK")
JOURS = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"]
JOURS_LONGS = ["lundi", "mardi", "mercredi", "jeudi", "vendredi", "samedi", "dimanche"]
FREQ = {"Q": "Quotidien", "H": "Hebdo", "M": "Mensuel", "J": "Journalier"}


def _con(con):
    return con or connect()


# ---------------------------------------------------------------- données brutes
def runs(con=None, application: str | None = "FIN-FINANCE") -> pd.DataFrame:
    """Une ligne par exécution réelle (job, odate, start_time), dernière photo connue."""
    con = _con(con)
    q = """
    SELECT j.job_name, j.group_name, j.application, j.description, j.member, j.task_type,
           j.cyclic, j.odate, j.start_time, j.end_time, j.status, j.rerun, j.order_id,
           s.snap_time
    FROM ctm_jobs j JOIN snapshots s ON s.id = j.snapshot_id
    WHERE j.task_type <> 'Dummy' AND (? IS NULL OR j.application = ?)
    """
    df = pd.read_sql_query(q, con, params=(application, application))
    df = df.sort_values("snap_time")
    df = df.drop_duplicates(["job_name", "odate", "start_time"], keep="last")
    for c in ("start_time", "end_time", "snap_time"):
        df[c] = pd.to_datetime(df[c], errors="coerce")
    df["odate"] = pd.to_datetime(df["odate"]).dt.date
    df["duree_min"] = (df["end_time"] - df["start_time"]).dt.total_seconds() / 60
    return df


def latest_snapshot(con=None, application: str | None = "FIN-FINANCE") -> pd.DataFrame:
    con = _con(con)
    row = con.execute("SELECT id, odate, snap_time FROM snapshots ORDER BY snap_time DESC LIMIT 1").fetchone()
    if not row:
        return pd.DataFrame()
    df = pd.read_sql_query(
        "SELECT * FROM ctm_jobs WHERE snapshot_id = ? AND (? IS NULL OR application = ?)",
        con, params=(row["id"], application, application))
    df = df.astype(object).where(df.notna(), None)
    df.attrs["odate"] = row["odate"]
    df.attrs["snap_time"] = row["snap_time"]
    return df


def snapshots_list(con=None) -> pd.DataFrame:
    return pd.read_sql_query("SELECT odate, snap_time, nb_lignes, source_file FROM snapshots ORDER BY snap_time DESC", _con(con))


# ---------------------------------------------------------------- profils
@dataclass
class Profil:
    job_name: str
    description: str
    group_name: str
    member: str
    nb_exec: int
    nb_jours_obs: int
    jours_semaine: set = field(default_factory=set)
    heure_mediane: time | None = None
    decalage_jour: int = 0            # 1 si le job tourne le lendemain de son odate
    duree_mediane: float | None = None
    taux_ok: float | None = None
    cyclique: bool = False
    frequence: str = "?"

    @property
    def heure_txt(self):
        return self.heure_mediane.strftime("%H:%M") if self.heure_mediane else "?"


def _minutes(dt: datetime, odate: date) -> float:
    return (dt - datetime.combine(odate, time())).total_seconds() / 60


def profils(df: pd.DataFrame) -> dict[str, Profil]:
    out: dict[str, Profil] = {}
    if df.empty:
        return out
    nb_jours_obs = df["odate"].nunique()
    for job, g in df.groupby("job_name"):
        gs = g[g["start_time"].notna()]
        p = Profil(job, g["description"].iloc[-1] or "", g["group_name"].iloc[-1], g["member"].iloc[-1] or "",
                   nb_exec=len(gs), nb_jours_obs=nb_jours_obs, cyclique=(g["cyclic"] == "Yes").any())
        if len(gs):
            mins = [_minutes(st, od) for st, od in zip(gs["start_time"], gs["odate"])]
            med = round(statistics.median(mins))
            p.decalage_jour = int(med // 1440)
            p.heure_mediane = (datetime.min + timedelta(minutes=med % 1440)).time()
            p.jours_semaine = {od.weekday() for od in gs["odate"]}
            d = gs["duree_min"].dropna()
            p.duree_mediane = float(d.median()) if len(d) else None
            done = gs[gs["status"].isin(STATUS_DONE)]
            p.taux_ok = float((done["status"] == "Ended OK").mean() * 100) if len(done) else None
        p.frequence = FREQ.get(job.rsplit("_", 1)[-1], "?")
        out[job] = p
    return out


def profils_df(profs: dict[str, Profil]) -> pd.DataFrame:
    rows = [dict(job=p.job_name, description=p.description, frequence=p.frequence, heure=p.heure_txt,
                 lendemain=bool(p.decalage_jour), duree_min=None if p.duree_mediane is None else round(p.duree_mediane, 1),
                 fiabilite=None if p.taux_ok is None else round(p.taux_ok), nb_exec=p.nb_exec,
                 jours=" ".join(JOURS[i][:2] for i in range(7) if i in p.jours_semaine),
                 cyclique=p.cyclique, script=p.member, groupe=p.group_name) for p in profs.values()]
    return pd.DataFrame(rows).sort_values("heure").reset_index(drop=True)


# ---------------------------------------------------------------- prévisions
def prevision(profs: dict[str, Profil], debut: datetime, fin: datetime,
              dernier: pd.DataFrame | None = None) -> pd.DataFrame:
    """Jobs attendus entre debut et fin, avec état temps réel issu de la dernière photo."""
    etat: dict[str, pd.Series] = {}
    odate_photo = None
    if dernier is not None and not dernier.empty:
        odate_photo = str(dernier.attrs.get("odate"))
        for _, r in dernier.sort_values("start_time", na_position="first").iterrows():
            etat[r["job_name"]] = r
    lignes = []
    for p in profs.values():
        if not p.heure_mediane:
            continue
        for od in pd.date_range(debut.date() - timedelta(days=1), fin.date(), freq="D"):
            od = od.date()
            # pas assez d'historique : on suppose tous les jours ouvrés pour les quotidiens
            if p.frequence in ("Quotidien", "Journalier") and p.nb_jours_obs < 5:
                if od.weekday() >= 5 and od.weekday() not in p.jours_semaine:
                    continue
            elif od.weekday() not in p.jours_semaine:
                continue
            prevu = datetime.combine(od + timedelta(days=p.decalage_jour), p.heure_mediane)
            # Une nuit peut commencer avant minuit : conserver aussi un job lancé
            # avant le créneau mais dont la durée habituelle le fait chevaucher.
            fin_prevue = prevu + timedelta(minutes=max(p.duree_mediane or 0, 6))
            if not (prevu < fin and fin_prevue > debut):
                continue
            r = etat.get(p.job_name)
            statut, reel_debut, reel_fin = "à venir", None, None
            if r is not None and odate_photo == str(od):
                statut = r["status"] or "?"
                reel_debut, reel_fin = r["start_time"], r["end_time"]
                if statut == "Wait for Event" and not reel_debut:
                    statut = "à venir"
            lignes.append(dict(
                heure_prevue=prevu, job=p.job_name, description=p.description, statut=statut,
                duree_min=round(p.duree_mediane or 0, 1),
                fiabilite=None if p.taux_ok is None else round(p.taux_ok), frequence=p.frequence,
                cyclique=p.cyclique, script=p.member, groupe=p.group_name, nb_obs=p.nb_exec,
                debut_reel=reel_debut, fin_reel=reel_fin, odate=od))
    cols = ["heure_prevue", "job", "description", "statut", "duree_min", "fiabilite", "frequence",
            "cyclique", "script", "groupe", "nb_obs", "debut_reel", "fin_reel", "odate"]
    df = pd.DataFrame(lignes, columns=cols)
    return df.sort_values(["heure_prevue", "job"]).reset_index(drop=True)


def plage_ce_soir(now: datetime | None = None):
    now = now or datetime.now()
    debut = now.replace(hour=17, minute=0, second=0, microsecond=0)
    if now.hour < 6:
        debut -= timedelta(days=1)
    return debut, debut + timedelta(hours=13)


def plage_demain(now: datetime | None = None):
    now = now or datetime.now()
    d = (now + timedelta(days=1)).replace(hour=6, minute=0, second=0, microsecond=0)
    if now.hour < 6:
        d -= timedelta(days=1)
    return d, d + timedelta(hours=24)


# ---------------------------------------------------------------- anomalies "maintenant"
def anomalies(profs: dict[str, Profil], dernier: pd.DataFrame) -> pd.DataFrame:
    cols = ["job", "statut", "motif", "debut", "fin", "description", "groupe"]
    if dernier is None or dernier.empty:
        return pd.DataFrame(columns=cols)
    snap = datetime.fromisoformat(dernier.attrs["snap_time"])
    odate = date.fromisoformat(dernier.attrs["odate"])
    rows = []
    for _, r in dernier.iterrows():
        p = profs.get(r["job_name"])
        st = pd.to_datetime(r["start_time"]) if r["start_time"] else None
        en = pd.to_datetime(r["end_time"]) if r["end_time"] else None
        motif = None
        if r["status"] == "Ended Not OK":
            motif = "Terminé en erreur"
        elif r["status"] == "Executing" and st is not None and p and p.duree_mediane:
            enc = (snap - st).total_seconds() / 60
            if enc > max(2 * p.duree_mediane, p.duree_mediane + 15):
                motif = f"En cours depuis {enc:.0f} min (habituel {p.duree_mediane:.0f} min)"
        elif r["status"] == "Wait for Event" and p and p.heure_mediane and st is None:
            prevu = datetime.combine(odate + timedelta(days=p.decalage_jour), p.heure_mediane)
            if snap > prevu + timedelta(minutes=30) and odate.weekday() in p.jours_semaine:
                motif = f"Pas démarré, prévu {prevu:%d/%m %H:%M}"
        if (r["rerun"] or 0) > 1 and not (p and p.cyclique):
            motif = (motif + " ; " if motif else "") + f"relancé x{r['rerun']}"
        if motif:
            rows.append(dict(job=r["job_name"], statut=r["status"], motif=motif, debut=st, fin=en,
                             description=r["description"], groupe=r["group_name"]))
    return pd.DataFrame(rows, columns=cols)


def historique_job(df_runs: pd.DataFrame, job: str) -> pd.DataFrame:
    h = df_runs[(df_runs["job_name"] == job) & df_runs["start_time"].notna()].copy()
    return h.sort_values("start_time", ascending=False)[
        ["odate", "start_time", "end_time", "duree_min", "status", "rerun", "order_id"]]


def programmes_oracle(con) -> dict[str, str]:
    """Job Control-M -> programmes Oracle Applications qu'il déclenche, par fréquence décroissante.

    Le job lance un lanceur (DKA_SLAUNCHER, mémorisé dans job_mapping), qui soumet le traitement métier :
    c'est ce dernier qu'on affiche. Un job dont on ne connaît que le lanceur affiche le lanceur.
    """
    lanceurs = {r[0]: r[1] for r in con.execute("SELECT job_name, program_short FROM job_mapping")}
    rows = con.execute("""
        SELECT job_name, program_short, COALESCE(program_name, ''), COUNT(*) AS n
        FROM ora_requests WHERE job_name IS NOT NULL AND program_short IS NOT NULL
        GROUP BY job_name, program_short, program_name ORDER BY job_name, n DESC""").fetchall()
    par_job: dict[str, list[tuple[str, str]]] = {}
    for job, short, name, _n in rows:
        par_job.setdefault(job, []).append((short, name))
    out = {}
    for job, progs in par_job.items():
        metier = [(s, n) for s, n in progs if s != lanceurs.get(job)] or progs
        out[job] = " ; ".join(f"{s} · {n}" if n else s for s, n in metier[:4])
    for job, short in lanceurs.items():
        out.setdefault(job, short)
    return out
