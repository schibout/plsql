"""ODAT Watch – interface Streamlit.

Lancement : streamlit run app.py   (ou run.bat)
"""
from __future__ import annotations
from datetime import datetime, timedelta
from pathlib import Path

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

import forecast as fc
import ingest
from db import connect, DB_PATH

st.set_page_config(page_title="ODAT Watch", page_icon="🕓", layout="wide")

# ------------------------------------------------------------------ styles
COULEURS = {
    "à venir": "#8A94A6",
    "Wait for Event": "#D9A400",
    "Executing": "#2F6FED",
    "Ended OK": "#1F9D55",
    "Ended Not OK": "#D23F31",
}
ICONES = {"à venir": "⏳", "Wait for Event": "⏸", "Executing": "▶", "Ended OK": "✔", "Ended Not OK": "✖"}

st.markdown("""
<style>
.block-container {padding-top: 3rem;}
.kpi {border:1px solid rgba(128,128,128,.25); border-radius:12px; padding:.7rem 1rem; margin-bottom:.4rem;}
.kpi .v {font-size:1.7rem; font-weight:700; line-height:1.1;}
.kpi .l {font-size:.8rem; opacity:.7;}
.job {font-family: ui-monospace, Consolas, monospace; font-size:.85rem;}
</style>
""", unsafe_allow_html=True)


# ------------------------------------------------------------------ données (cache)
@st.cache_data(show_spinner=False)
def charger(application: str | None, _stamp: float):
    con = connect()
    df = fc.runs(con, application)
    profs = fc.profils(df)
    last = fc.latest_snapshot(con, application)
    snaps = fc.snapshots_list(con)
    con.close()
    return df, profs, last, snaps


def stamp() -> float:
    return DB_PATH.stat().st_mtime if DB_PATH.exists() else 0.0


def kpi(col, valeur, libelle):
    col.markdown(f'<div class="kpi"><div class="v">{valeur}</div><div class="l">{libelle}</div></div>',
                 unsafe_allow_html=True)


def badge(statut: str) -> str:
    return f"{ICONES.get(statut, '•')} {statut}"


# ------------------------------------------------------------------ barre latérale
with st.sidebar:
    st.title("🕓 ODAT Watch")
    con = connect()
    apps = [r[0] for r in con.execute("SELECT DISTINCT application FROM ctm_jobs ORDER BY 1")]
    con.close()
    idx = apps.index("FIN-FINANCE") if "FIN-FINANCE" in apps else 0
    application = st.selectbox("Application", apps, index=idx) if apps else None
    recherche = st.text_input("Filtre (job, description, script)", "").strip().lower()
    st.divider()
    if st.button("📥 Importer les nouveaux fichiers ODAT", use_container_width=True):
        with st.spinner("Import en cours…"):
            logs = ingest.run()
        st.cache_data.clear()
        st.session_state["logs_import"] = logs
    if "logs_import" in st.session_state:
        with st.expander("Journal du dernier import"):
            st.code("\n".join(st.session_state["logs_import"]))
    st.caption("Sources scannées : dossier ODAT du dépôt et Téléchargements.")

if not apps:
    st.warning("Base vide. Lancez l'import depuis la barre latérale ou `python ingest.py`.")
    st.stop()

df_runs, profs, last, snaps = charger(application, stamp())
now = datetime.now()
snap_time = datetime.fromisoformat(last.attrs["snap_time"]) if not last.empty else None


def filtrer(df: pd.DataFrame) -> pd.DataFrame:
    if not recherche or df.empty:
        return df
    cols = [c for c in ("job", "job_name", "description", "script", "member") if c in df.columns]
    m = pd.Series(False, index=df.index)
    for c in cols:
        m |= df[c].fillna("").astype(str).str.lower().str.contains(recherche, regex=False)
    return df[m]


# ------------------------------------------------------------------ composants
def timeline_chaines(prev: pd.DataFrame, debut: datetime, fin: datetime, titre: str):
    """Une barre par chaîne (group_name) : du premier job prévu à la fin du dernier."""
    if prev.empty:
        st.info("Rien de prévu sur cette plage.")
        return
    p = prev.copy()
    p["fin_prevue"] = p["heure_prevue"] + pd.to_timedelta(p["duree_min"].clip(lower=6), unit="m")
    g = (p.groupby("groupe")
         .agg(debut=("heure_prevue", "min"), fin=("fin_prevue", "max"), nb=("job", "size"),
              jobs=("job", lambda s: "<br>".join(s.head(12)) + ("<br>…" if len(s) > 12 else "")),
              statut=("statut", lambda s: "Ended Not OK" if (s == "Ended Not OK").any()
                      else "Executing" if (s == "Executing").any()
                      else "Ended OK" if (s == "Ended OK").all() else "à venir"))
         .reset_index().sort_values("debut"))
    fig = px.timeline(g, x_start="debut", x_end="fin", y="groupe", color="statut",
                      color_discrete_map=COULEURS, custom_data=["nb", "jobs"],
                      category_orders={"groupe": list(g["groupe"])})
    fig.update_traces(marker_line_width=0, width=0.55,
                      hovertemplate="<b>%{y}</b><br>%{x|%H:%M} → %{customdata[0]} job(s)<br><br>%{customdata[1]}<extra></extra>")
    if debut <= now <= fin:
        fig.add_vline(x=now, line_width=1, line_dash="dot", line_color="#8A94A6",
                      annotation_text="maintenant", annotation_position="top")
    fig.update_layout(height=max(260, 22 * len(g) + 80), margin=dict(l=10, r=10, t=30, b=10),
                      xaxis=dict(range=[debut, fin], title=None, gridcolor="rgba(128,128,128,.15)"),
                      yaxis=dict(title=None, tickfont=dict(size=11)),
                      legend=dict(orientation="h", y=1.08, title=None), title=titre,
                      plot_bgcolor="rgba(0,0,0,0)", paper_bgcolor="rgba(0,0,0,0)")
    st.plotly_chart(fig, use_container_width=True)


def table_prevision(prev: pd.DataFrame):
    if prev.empty:
        return
    t = prev.copy()
    t["heure"] = t["heure_prevue"].dt.strftime("%H:%M")
    t["jour"] = [f"{fc.JOURS[d.weekday()]} {d:%d/%m}" for d in t["heure_prevue"]]
    t["état"] = t["statut"].map(badge)
    t["réel"] = [f"{pd.to_datetime(a):%H:%M}" + (f" → {pd.to_datetime(b):%H:%M}" if b else "") if a else ""
                 for a, b in zip(t["debut_reel"], t["fin_reel"])]
    t["fiabilité"] = t["fiabilite"]
    t["hebdo/mensuel"] = t["frequence"].isin(["Hebdo", "Mensuel"])
    cols = ["jour", "heure", "état", "job", "description", "duree_min", "fiabilité", "frequence", "cyclique", "script", "réel", "nb_obs"]
    st.dataframe(
        t[cols], use_container_width=True, hide_index=True, height=min(600, 38 * len(t) + 40),
        column_config={
            "duree_min": st.column_config.NumberColumn("durée (min)", format="%.1f"),
            "fiabilité": st.column_config.ProgressColumn("fiabilité", min_value=0, max_value=100, format="%d %%"),
            "nb_obs": st.column_config.NumberColumn("obs."),
            "cyclique": st.column_config.CheckboxColumn("cyclique"),
            "job": st.column_config.TextColumn("job", width="medium"),
            "description": st.column_config.TextColumn("description", width="large"),
        })


def resume(prev: pd.DataFrame):
    c = st.columns(5)
    kpi(c[0], len(prev), "jobs attendus")
    kpi(c[1], prev["groupe"].nunique() if not prev.empty else 0, "chaînes")
    kpi(c[2], int((prev["statut"] == "Ended OK").sum()) if not prev.empty else 0, "déjà terminés OK")
    kpi(c[3], int((prev["statut"] == "Ended Not OK").sum()) if not prev.empty else 0, "en erreur")
    kpi(c[4], int(prev["frequence"].isin(["Hebdo", "Mensuel"]).sum()) if not prev.empty else 0, "hebdo / mensuels")


# ------------------------------------------------------------------ en-tête
h1, h2 = st.columns([3, 2])
h1.subheader(f"{application} · {fc.JOURS_LONGS[now.weekday()]} {now:%d/%m/%Y %H:%M}")
if snap_time:
    age = now - snap_time
    h2.caption(f"Dernière photo Control-M : **{snap_time:%d/%m %H:%M}** (odate {last.attrs['odate']}), "
               f"il y a {int(age.total_seconds() // 3600)} h {int(age.total_seconds() % 3600 // 60)} min · "
               f"{len(snaps)} photos, {df_runs['odate'].nunique()} jours d'historique")

tab_soir, tab_demain, tab_now, tab_histo, tab_profils, tab_data = st.tabs(
    ["🌙 Ce soir", "📅 Demain", "🔴 Maintenant", "🔎 Historique", "📈 Profils", "🗂 Données"])

# ------------------------------------------------------------------ ce soir
with tab_soir:
    d0, d1 = fc.plage_ce_soir(now)
    prev = filtrer(fc.prevision(profs, d0, d1, last))
    st.caption(f"Plage {d0:%d/%m %H:%M} → {d1:%d/%m %H:%M}. Heures prévues = médiane des exécutions observées.")
    resume(prev)
    timeline_chaines(prev, d0, d1, "Chaînes attendues ce soir")
    table_prevision(prev)

# ------------------------------------------------------------------ demain
with tab_demain:
    d0, d1 = fc.plage_demain(now)
    prev = filtrer(fc.prevision(profs, d0, d1, last))
    st.caption(f"Plage {d0:%d/%m %H:%M} → {d1:%d/%m %H:%M}. Les jobs hebdo et mensuels sont ceux qu'on oublie : "
               f"filtrez la colonne *frequence*.")
    resume(prev)
    timeline_chaines(prev, d0, d1, "Chaînes attendues demain")
    table_prevision(prev)

# ------------------------------------------------------------------ maintenant
with tab_now:
    if last.empty:
        st.info("Aucune photo chargée.")
    else:
        an = filtrer(fc.anomalies(profs, last))
        stat = last["status"].value_counts()
        c = st.columns(5)
        kpi(c[0], int(stat.get("Ended OK", 0)), "✔ Ended OK")
        kpi(c[1], int(stat.get("Ended Not OK", 0)), "✖ Ended Not OK")
        kpi(c[2], int(stat.get("Executing", 0)), "▶ Executing")
        kpi(c[3], int(stat.get("Wait for Event", 0)), "⏸ Wait for Event")
        kpi(c[4], len(an), "⚠ anomalies détectées")
        st.markdown("#### Anomalies sur la dernière photo")
        if an.empty:
            st.success("Rien à signaler : pas d'erreur, pas de retard, pas de relance anormale.")
        else:
            a = an.copy()
            a["état"] = a["statut"].map(badge)
            a["début"] = pd.to_datetime(a["debut"]).dt.strftime("%d/%m %H:%M")
            a["fin"] = pd.to_datetime(a["fin"]).dt.strftime("%d/%m %H:%M")
            st.dataframe(a[["état", "job", "motif", "début", "fin", "description", "groupe"]],
                         use_container_width=True, hide_index=True)
        st.markdown("#### Toute la photo")
        l = filtrer(last.rename(columns={"job_name": "job", "member": "script"})).copy()
        l["état"] = l["status"].map(badge)
        l = l.fillna("")
        st.dataframe(l[["état", "job", "start_time", "end_time", "rerun", "cyclic", "description", "script", "group_name"]]
                     .sort_values(["état", "start_time"]),
                     use_container_width=True, hide_index=True, height=500)

# ------------------------------------------------------------------ historique
with tab_histo:
    jobs = sorted(profs)
    if recherche:
        jobs = [j for j in jobs if recherche in j.lower() or recherche in (profs[j].description or "").lower()]
    job = st.selectbox("Job", jobs, index=0 if jobs else None, format_func=lambda j: f"{j} — {profs[j].description}")
    if job:
        p = profs[job]
        c = st.columns(6)
        kpi(c[0], p.heure_txt + (" (J+1)" if p.decalage_jour else ""), "heure habituelle")
        kpi(c[1], f"{p.duree_mediane:.1f} min" if p.duree_mediane is not None else "?", "durée médiane")
        kpi(c[2], f"{p.taux_ok:.0f} %" if p.taux_ok is not None else "?", "taux OK")
        kpi(c[3], p.nb_exec, "exécutions observées")
        kpi(c[4], " ".join(fc.JOURS[i][:2] for i in range(7) if i in p.jours_semaine) or "?", "jours")
        kpi(c[5], p.frequence + (" · cyclique" if p.cyclique else ""), "fréquence")
        h = fc.historique_job(df_runs, job)
        if h.empty:
            st.info("Aucune exécution observée.")
        else:
            g1, g2 = st.columns(2)
            hh = h.dropna(subset=["start_time"]).copy()
            hh["heure_debut"] = hh["start_time"].dt.hour + hh["start_time"].dt.minute / 60
            fig = go.Figure()
            for s, grp in hh.groupby("status"):
                fig.add_trace(go.Scatter(x=grp["start_time"], y=grp["heure_debut"], mode="markers", name=s,
                                         marker=dict(size=9, color=COULEURS.get(s, "#8A94A6"), line=dict(width=1, color="white")),
                                         hovertemplate="%{x|%d/%m %H:%M}<br>%{y:.2f} h<extra>" + s + "</extra>"))
            fig.update_layout(title="Heure de démarrage", height=300, margin=dict(l=10, r=10, t=40, b=10),
                              yaxis=dict(title="heure (0–24)", gridcolor="rgba(128,128,128,.15)"),
                              xaxis=dict(title=None), legend=dict(orientation="h", y=1.15),
                              plot_bgcolor="rgba(0,0,0,0)", paper_bgcolor="rgba(0,0,0,0)")
            g1.plotly_chart(fig, use_container_width=True)
            fig2 = go.Figure(go.Bar(x=hh["start_time"], y=hh["duree_min"], marker_color="#2F6FED", width=1000 * 3600 * 2,
                                    hovertemplate="%{x|%d/%m %H:%M}<br>%{y:.1f} min<extra></extra>"))
            fig2.update_layout(title="Durée (min)", height=300, margin=dict(l=10, r=10, t=40, b=10),
                               yaxis=dict(gridcolor="rgba(128,128,128,.15)"), xaxis=dict(title=None),
                               plot_bgcolor="rgba(0,0,0,0)", paper_bgcolor="rgba(0,0,0,0)")
            g2.plotly_chart(fig2, use_container_width=True)
            hh["état"] = hh["status"].map(badge)
            st.dataframe(hh[["odate", "état", "start_time", "end_time", "duree_min", "rerun", "order_id"]],
                         use_container_width=True, hide_index=True,
                         column_config={"duree_min": st.column_config.NumberColumn("durée (min)", format="%.1f")})

# ------------------------------------------------------------------ profils
with tab_profils:
    st.caption("Profil calculé pour chaque job à partir de l'historique. Plus il y a de jours, plus c'est fiable.")
    pdf = filtrer(fc.profils_df(profs))
    st.dataframe(pdf, use_container_width=True, hide_index=True, height=600,
                 column_config={"fiabilite": st.column_config.ProgressColumn("fiabilité", min_value=0, max_value=100, format="%d %%"),
                                "duree_min": st.column_config.NumberColumn("durée (min)", format="%.1f"),
                                "lendemain": st.column_config.CheckboxColumn("J+1"),
                                "cyclique": st.column_config.CheckboxColumn("cyclique")})
    st.download_button("⬇ Exporter les profils (CSV)", pdf.to_csv(index=False, sep=";").encode("utf-8-sig"),
                       f"profils_{application}_{now:%Y%m%d}.csv", "text/csv")

# ------------------------------------------------------------------ données
with tab_data:
    st.markdown("#### Photos chargées")
    st.dataframe(snaps, use_container_width=True, hide_index=True)
    st.markdown("#### Comparer deux photos")
    opts = list(snaps["snap_time"])
    if len(opts) >= 2:
        c1, c2 = st.columns(2)
        s_a = c1.selectbox("Photo A (avant)", opts, index=1)
        s_b = c2.selectbox("Photo B (après)", opts, index=0)
        con = connect()
        q = """SELECT j.job_name, j.start_time, j.end_time, j.status, j.rerun, j.description
               FROM ctm_jobs j JOIN snapshots s ON s.id=j.snapshot_id
               WHERE s.snap_time=? AND j.application=? AND j.task_type<>'Dummy'"""
        a = pd.read_sql_query(q, con, params=(s_a, application)).sort_values("start_time").drop_duplicates("job_name", keep="last")
        b = pd.read_sql_query(q, con, params=(s_b, application)).sort_values("start_time").drop_duplicates("job_name", keep="last")
        con.close()
        m = a.merge(b, on="job_name", how="outer", suffixes=("_A", "_B")).fillna("")
        chg = m[(m["status_A"] != m["status_B"]) | (m["start_time_A"] != m["start_time_B"])].copy()
        chg = filtrer(chg.rename(columns={"job_name": "job", "description_B": "description"}))
        st.caption(f"{len(chg)} job(s) ont changé entre les deux photos.")
        st.dataframe(chg[["job", "status_A", "status_B", "start_time_B", "end_time_B", "rerun_B", "description"]],
                     use_container_width=True, hide_index=True, height=450)
