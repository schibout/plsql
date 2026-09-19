"""Page "Préparer ma nuit" : plan, suivi sur exports et bilan."""
from __future__ import annotations

from datetime import datetime, time, timedelta
import sqlite3

import pandas as pd
import plotly.express as px
import streamlit as st

import night_monitoring
import production_plan
import forecast
import ui_assistant_nuit

COLORS = {"à venir": "#8A94A6", "Wait for Event": "#D9A400", "Executing": "#2F6FED",
          "Ended OK": "#1F9D55", "Ended Not OK": "#D23F31"}


def _timeline(plan: pd.DataFrame, begin: datetime, end: datetime) -> None:
    if plan.empty:
        st.info("Aucun traitement attendu sur cette période avec les règles actuellement observées.")
        return
    data = plan.copy()
    data["fin_affichee"] = data["heure_prevue"] + pd.to_timedelta(data["duree_min"].clip(lower=6), unit="m")
    fig = px.timeline(data, x_start="heure_prevue", x_end="fin_affichee", y="groupe", color="statut",
                      hover_name="job", hover_data={"description": True, "duree_min": ":.1f", "nb_obs": True,
                                                     "heure_prevue": "|%d/%m %H:%M", "fin_affichee": "|%H:%M"},
                      color_discrete_map=COLORS)
    fig.update_layout(height=max(320, 25 * data["groupe"].nunique() + 120),
                      margin=dict(l=10, r=10, t=35, b=10),
                      xaxis=dict(range=[begin, end], title=None), yaxis=dict(title=None),
                      legend=dict(orientation="h", y=1.08, title=None),
                      plot_bgcolor="rgba(0,0,0,0)", paper_bgcolor="rgba(0,0,0,0)")
    st.plotly_chart(fig, use_container_width=True)


def _tree(plan: pd.DataFrame) -> None:
    st.markdown("##### Chaînes attendues")
    if plan.empty:
        return
    groups = (plan.groupby("groupe", dropna=False)
              .agg(jobs=("job", "size"), début=("heure_prevue", "min"), fin=("fin_prevue", "max"),
                   erreurs=("statut", lambda s: int((s == "Ended Not OK").sum())))
              .reset_index())
    groups["début"] = pd.to_datetime(groups["début"]).dt.strftime("%H:%M")
    groups["fin"] = pd.to_datetime(groups["fin"]).dt.strftime("%H:%M")
    st.dataframe(groups, use_container_width=True, hide_index=True, height=300)


def _table(plan: pd.DataFrame, mode: str, programmes: dict[str, str]) -> None:
    if plan.empty:
        return
    table = plan.copy()
    table["prévu"] = table["heure_prevue"].dt.strftime("%d/%m %H:%M")
    table["fin estimée"] = table["fin_prevue"].dt.strftime("%H:%M")
    table["programme Oracle"] = table["job"].map(programmes).fillna("")
    cols = ["prévu", "fin estimée", "job", "groupe", "description", "programme Oracle", "statut", "duree_min",
            "confiance", "nb_obs"]
    if mode != "Préparer":
        cols.insert(7, "suivi")
    st.dataframe(table[cols], use_container_width=True, hide_index=True, height=min(700, 38 * len(table) + 40),
                 column_config={"duree_min": st.column_config.NumberColumn("durée médiane (min)", format="%.1f"),
                                "nb_obs": st.column_config.NumberColumn("observations"),
                                "groupe": st.column_config.TextColumn("chaîne", width="medium"),
                                "description": st.column_config.TextColumn("description", width="large"),
                                "programme Oracle": st.column_config.TextColumn(
                                    "programme Oracle Applications", width="large",
                                    help="Traitement soumis par le lanceur du job (d'après les demandes Oracle chargées)")})


def render(con: sqlite3.Connection, profs, last: pd.DataFrame, now: datetime, kpi) -> None:
    st.subheader("Préparer ma nuit")
    st.caption("Prévision issue de l'historique Control-M ; le suivi utilise la dernière photo importée et n'est pas une supervision temps réel.")
    default_day = now.date() if now.hour >= 6 else (now - timedelta(days=1)).date()
    c1, c2, c3, c4 = st.columns([1.2, .8, .8, 1.4])
    day = c1.date_input("Date de début", value=default_day, key="plan_day")
    start_t = c2.time_input("Début", value=time(19, 0), key="plan_start")
    end_t = c3.time_input("Fin", value=time(7, 0), key="plan_end")
    mode = c4.radio("Mode", ["Préparer", "Suivre la nuit", "Bilan"], horizontal=True, key="plan_mode")
    begin = datetime.combine(day, start_t)
    end = datetime.combine(day, end_t)
    if end <= begin:
        end += timedelta(days=1)
    plan, events, context = production_plan.construire(con, profs, begin, end, last)
    context_filter = st.radio("Contexte", ["Toutes", "Hors clôture", "Clôture", "Inconnu"], index=0, horizontal=True,
                              help="Hors clôture est confirmé seulement lorsqu'un calendrier actif couvre la période.")
    shown = production_plan.filtrer_contexte(plan, events, context_filter)
    if mode != "Préparer":
        shown = night_monitoring.suivi(shown, last, now)
    st.caption(f"{begin:%d/%m %H:%M} → {end:%d/%m %H:%M} · {context} · filtre : {context_filter}")
    if not events.empty:
        with st.expander(f"{len(events)} jalon(s) de clôture dans cette plage", expanded=False):
            e = events.copy()
            e["libellé"] = e[["arrete", "traitement", "restitution"]].fillna("").agg(" · ".join, axis=1).str.strip(" ·")
            st.dataframe(e[["date_operation", "decalage_j", "moment", "libellé", "source_sheet", "source_row"]],
                         use_container_width=True, hide_index=True)
    counts = night_monitoring.compteurs(shown if mode != "Préparer" else pd.DataFrame())
    cards = st.columns(5)
    kpi(cards[0], len(shown), "jobs attendus")
    kpi(cards[1], shown["groupe"].nunique() if not shown.empty else 0, "chaînes")
    kpi(cards[2], counts.get("Terminé OK", 0), "terminés OK")
    kpi(cards[3], counts.get("Erreur constatée", 0), "erreurs")
    kpi(cards[4], counts.get("Non observé — à vérifier", 0), "à vérifier")
    # Le tableau d'abord (ce que l'exploitant lit), la chronologie en bas.
    st.markdown("##### Traitements attendus")
    _table(shown, mode, forecast.programmes_oracle(con))
    left, right = st.columns([1, 1])
    with left:
        _tree(shown)
    with right:
        ui_assistant_nuit.render(shown, context, begin, end)
    st.markdown("##### Chronologie des chaînes")
    _timeline(shown, begin, end)
