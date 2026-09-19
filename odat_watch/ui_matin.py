"""Onglet Matin : contrôle quotidien à la demande sur une plage date+heure, rapport HTML,
programmation quotidienne, tendance."""
from __future__ import annotations
import configparser
import contextlib
import sqlite3
import subprocess
from datetime import datetime, time as dtime
from pathlib import Path

import pandas as pd
import plotly.graph_objects as go
import streamlit as st
import streamlit.components.v1 as components

import controle_matin as cm
import planif_matin as pm
import rapport_matin as rm
from db import connect
from oracle_refresh import CONFIG

AFFICHE = {"OK": st.success, "WARNING": st.warning, "ALERTE": st.error, "ERREUR": st.error}
# Palette des KPI de app.py (ok / warn / err / run) + violet pour les images manquantes.
COULEURS = {"nb_erreurs": "#D23F31", "nb_warnings": "#D9A400", "nb_images_manq": "#7B3FBF", "nb_flux_dsp": "#2F6FED"}
COULEUR_STATUT = {"OK": "#1F9D55", "WARNING": "#D9A400", "ALERTE": "#D23F31", "ERREUR": "#8A94A6"}


def _delta_txt(delta: dict, cle: str) -> str:
    if cle not in delta:
        return ""
    d = delta[cle]
    j = datetime.strptime(delta["date"], "%Y-%m-%d").strftime("%d/%m")
    return f" · {d:+d} vs {j}" if d else f" · = {j}"


# Section de détail ouverte par un clic sur la tuile
SECTION_TUILE = {"nb_flux_dsp": "dsp_detail", "nb_ndf": "notilus", "nb_fac_xerox": "fact_source",
                 "nb_fac_tradeshift": "fact_source", "nb_fac_dsp": "fact_source", "nb_gl_interface": "gl_interface",
                 "nb_gl_lignes": "gl_lignes", "nb_traitements": "nuit_synthese", "nb_erreurs": "nuit_err_detail",
                 "nb_warnings": "nuit_warnings", "nb_rb_imports": "rb", "nb_images_manq": "xerox_sans_img"}
COULEUR_TON = {"ok": "#1F9D55", "warn": "#D9A400", "err": "#D23F31", "neutral": "#8A94A6", "run": "#2F6FED"}


def _tuile_cliquable(col, cle: str, valeur, libelle: str, ton: str) -> bool:
    """Tuile KPI rendue comme un bouton (même charte que kpi()) : le clic renvoie True."""
    key = f"m_tuile_{cle}"
    col.markdown(f"""<style>
.st-key-{key} button {{width:100%; text-align:left; background:#fff; border:1px solid #E4E8EF; border-left:5px solid {COULEUR_TON.get(ton, '#8A94A6')};
  border-radius:14px; padding:.8rem 1rem .7rem 1.1rem; margin-bottom:.4rem; box-shadow:0 1px 2px rgba(16,24,40,.04); display:block;}}
.st-key-{key} button:hover {{border-color:#2F6FED; border-left-color:{COULEUR_TON.get(ton, '#8A94A6')}; background:#F7F9FE;}}
.st-key-{key} button p {{margin:0; font-size:.72rem; color:#5B6573; text-transform:uppercase; letter-spacing:.04em; line-height:1.15;}}
.st-key-{key} button p strong {{display:block; font-size:1.7rem; font-weight:700; color:#1B2430; letter-spacing:-.02em; text-transform:none; margin-bottom:.15rem;}}
</style>""", unsafe_allow_html=True)
    section = dict(cm.CATALOGUE_TITRES).get(SECTION_TUILE.get(cle), "")
    return col.button(f"**{valeur}**  \n{libelle}", key=key, help=f"Voir la section « {section} »")


def _ton_tuile(res: cm.Resultat, cle: str) -> str:
    v = res.compteurs.get(cle)
    if cle in res.erreurs_synthese or v is None:
        return "err"
    if cle in res.statuts:
        return "neutral" if res.statuts[cle] == "N/A" else ("ok" if res.statuts[cle] == "OK" else "warn")
    if cle in ("nb_erreurs", "nb_images_manq"):
        return "err" if v > 0 else "ok"
    if cle == "nb_warnings":
        return "warn" if v > 0 else "ok"
    return "neutral"


def _bouton_telecharger(chemin: Path, cle: str, libelle: str = "⬇ Télécharger"):
    st.download_button(libelle, data=chemin.read_bytes(), file_name=chemin.name, mime="text/html", key=cle)


def _config_oracle_ok() -> bool:
    if not CONFIG.exists():
        return False
    cfg = configparser.ConfigParser(inline_comment_prefixes=(";", "#"))
    cfg.read(CONFIG, encoding="utf-8")
    return cfg.has_section("database")


@st.cache_data(ttl=60, show_spinner=False)
def _etat_tache():
    """schtasks est un sous-processus : on ne l'interroge pas à chaque rerun de l'application."""
    return pm.etat()


def render(now: datetime, kpi):
    if not _config_oracle_ok():
        st.info("Renseignez `config.ini` (copie de `config.ini.exemple`, section `[database]`) pour lancer le contrôle du matin.")
        return

    d0, f0 = cm.plage_par_defaut(now)
    gauche, droite = st.columns([3, 2])
    with gauche:
        st.markdown("#### Plage contrôlée")
        c1, c2, c3, c4, c5 = st.columns([1.2, 0.8, 1.2, 0.8, 0.8])
        j_deb = c1.date_input("Début de nuit", d0.date(), key="m_jd")
        h_deb = c2.time_input("Heure", dtime(19, 0), key="m_hd", step=900)
        j_fin = c3.date_input("Fin de nuit", f0.date(), key="m_jf")
        h_fin = c4.time_input("Heure ", dtime(7, 0), key="m_hf", step=900)
        histo = c5.number_input("Histo (j)", 1, 30, 3)
        debut, fin = datetime.combine(j_deb, h_deb), datetime.combine(j_fin, h_fin)
        motif = cm.jour_sans_integration(debut.date())
        st.caption(f"Traitements de nuit du {debut:%d/%m %H:%M} au {fin:%d/%m %H:%M} · veille = {debut:%d/%m} · jour = {fin:%d/%m}"
                   + (f" · **veille = {motif} : volumes non contrôlés**" if motif else ""))
        forcer = st.checkbox("Contrôler les volumes malgré tout (week-end / férié)", False, key="m_forcer") if motif else False
        if st.button("▶ Lancer le contrôle", type="primary", use_container_width=True):
            if fin <= debut:
                st.error("La fin de la plage doit être après son début.")
            else:
                with st.spinner("Contrôles en cours sur Oracle…"):
                    try:
                        st.session_state["matin"] = cm.executer(debut, fin, int(histo), forcer_volumes=forcer)
                        st.session_state.pop("matin_rapport", None)
                    # SystemExit : oracle_refresh signale ainsi config.ini / Instant Client manquants ;
                    # non attrapé, il tuerait le script Streamlit sans message.
                    except (Exception, SystemExit) as e:  # noqa: BLE001 — connexion Oracle, config : on affiche tel quel
                        st.error(f"Contrôle impossible : {e}")
    with droite:
        _bloc_programmer()

    res: cm.Resultat | None = st.session_state.get("matin")
    if res is None:
        st.caption("Aucune exécution dans cette session. Les rapports déjà générés sont listés en bas de page.")
        _anciens_rapports()
        with contextlib.closing(connect()) as con:
            _tendance(con)
        return

    AFFICHE[res.statut_global](f"**Statut global : {res.statut_global}** — {rm.MESSAGE_STATUT[res.statut_global]}  \n"
                               f"Plage {res.debut:%d/%m %H:%M} → {res.fin:%d/%m %H:%M}, exécuté le "
                               f"{res.executed_at:%d/%m/%Y à %H:%M} en {res.duree_s} s.")
    if res.sans_integration:
        st.info(f"Veille = **{res.sans_integration}** : pas d'intégration ce jour-là, les volumes (flux, factures, GL, RB) "
                "sont affichés à titre indicatif (N/A) et ne pèsent pas dans le statut.", icon="📅")
    if res.executed_at.weekday() == 0:
        st.warning("**Rappel lundi :** charger manuellement le fichier SG (Société Générale).", icon="🏦")
    if res.erreurs_synthese:
        st.error("Compteurs non contrôlés : " + ", ".join(cm.LIBELLES[k] for k in res.erreurs_synthese))

    with contextlib.closing(connect()) as con:
        delta = cm.delta_veille(res.compteurs, res.date_ctrl, con)
        cols = st.columns(6)
        for i, cle in enumerate(cm.COMPTEURS):
            v = res.compteurs.get(cle)
            suffixe = " · N/A" if res.statuts.get(cle) == "N/A" else _delta_txt(delta, cle)
            if _tuile_cliquable(cols[i % 6], cle, "?" if v is None else v, cm.LIBELLES[cle] + suffixe, _ton_tuile(res, cle)):
                st.session_state["m_focus"] = SECTION_TUILE.get(cle)
        focus = st.session_state.pop("m_focus", None)
        if res.date_rb_max:
            st.caption(f"Dernier import RB : {res.date_rb_max:%d/%m/%Y}")

        st.markdown("#### Détail des contrôles")
        for sec in res.sections:
            titre = f"{'🔴 ' if sec.erreur else '⚠️ ' if sec.alerte else ''}{sec.titre} — {sec.nb} ligne(s)"
            st.markdown(f'<div id="sec-{sec.cle}"></div>', unsafe_allow_html=True)
            ouvert = (sec.cle == focus) if focus else bool(sec.alerte or sec.erreur)
            with st.expander(titre, expanded=ouvert):
                if sec.erreur:
                    st.error(sec.erreur)
                elif sec.df is None or sec.df.empty:
                    st.caption("Aucune ligne.")
                else:
                    st.dataframe(sec.df, use_container_width=True, hide_index=True)

        if focus:
            # défilement vers l'ancre de la section : le script tourne dans l'iframe du composant,
            # la page de l'application est son parent.
            components.html(f"<script>window.parent.document.getElementById('sec-{focus}')"
                            f"?.scrollIntoView({{behavior:'smooth', block:'start'}});</script>", height=0)

        st.markdown("#### Rapport")
        r1, r2 = st.columns([1, 3])
        if r1.button("📄 Générer le rapport HTML", use_container_width=True):
            try:
                chemin = rm.ecrire(res)
                if res.histo_id:
                    cm.maj_fichier_rapport(res.histo_id, str(chemin), con)
                st.session_state["matin_rapport"] = str(chemin)
            except (OSError, sqlite3.Error) as e:
                st.error(f"Écriture du rapport impossible : {e}")
        if st.session_state.get("matin_rapport"):
            chemin = Path(st.session_state["matin_rapport"])
            with r2:
                st.caption(f"Rapport écrit : `{chemin}`")
                _bouton_telecharger(chemin, "dl_courant")

        _anciens_rapports()
        _tendance(con)


def _bloc_programmer():
    st.markdown("#### ⏰ Programmer chaque matin")
    etat = _etat_tache()
    if etat:
        st.success(f"Tâche **{pm.NOM_TACHE}** active — prochaine : {etat['prochaine']} · "
                   f"dernière : {etat['derniere'] or '—'} (résultat {etat['dernier_resultat'] or '—'})", icon="✅")
    else:
        st.caption("Aucune tâche planifiée. La tâche lance `controle_matin.py --rapport` (plage par défaut 19h → 7h), "
                   "poste allumé et session ouverte.")
    c1, c2, c3 = st.columns([1, 1.2, 1])
    heure = c1.time_input("Heure", dtime(7, 15), key="m_hp", step=900)
    if c2.button("Programmer", use_container_width=True, type="secondary"):
        try:
            pm.creer(heure.strftime("%H:%M"))
            _etat_tache.clear()
            st.rerun()
        except (RuntimeError, OSError, subprocess.SubprocessError) as e:
            st.error(f"schtasks a échoué : {e}")
            st.code(subprocess.list2cmdline(pm.commande(heure.strftime("%H:%M"))), language="bat")
    if c3.button("Supprimer", use_container_width=True, disabled=etat is None):
        try:
            pm.supprimer()
            _etat_tache.clear()
            st.rerun()
        except (RuntimeError, OSError, subprocess.SubprocessError) as e:
            st.error(f"schtasks a échoué : {e}")


def _anciens_rapports():
    fichiers = sorted(rm.DOSSIER_RAPPORTS.glob("Controle_Matin_*.html"), reverse=True)[:10] if rm.DOSSIER_RAPPORTS.exists() else []
    if not fichiers:
        return
    with st.expander(f"Rapports précédents ({len(fichiers)})"):
        for f in fichiers:
            a, b = st.columns([3, 1])
            a.write(f.name)
            with b:
                _bouton_telecharger(f, f"dl_{f.stem}")


def _tendance(con):
    h = cm.historique(30, con)
    if len(h) < 2:
        return
    st.markdown("#### Tendance 30 jours")
    h["date_ctrl"] = pd.to_datetime(h["date_ctrl"])
    fig = go.Figure()
    for cle, couleur in COULEURS.items():
        fig.add_trace(go.Scatter(x=h["date_ctrl"], y=h[cle], name=cm.LIBELLES[cle], mode="lines+markers",
                                 line=dict(color=couleur, width=2.5, shape="spline", smoothing=0.6),
                                 marker=dict(size=7, color=couleur, line=dict(width=1, color="white")),
                                 hovertemplate="%{x|%d/%m}<br>%{y}<extra>" + cm.LIBELLES[cle] + "</extra>"))
    ymax = max(float(h[COULEURS.keys()].max().max()), 1.0)
    fig.add_trace(go.Scatter(x=h["date_ctrl"], y=[-ymax * 0.07] * len(h), mode="markers", name="statut du jour",
                             marker=dict(size=13, symbol="square", color=[COULEUR_STATUT.get(s, "#8A94A6") for s in h["statut_global"]],
                                         line=dict(width=1, color="white")),
                             hovertemplate="%{x|%d/%m} : %{text}<extra></extra>", text=h["statut_global"]))
    fig.update_layout(height=340, margin=dict(l=10, r=10, t=10, b=10), template="plotly_white",
                      legend=dict(orientation="h", y=1.08), hovermode="x unified",
                      xaxis=dict(tickformat="%d/%m", showgrid=False),
                      yaxis=dict(rangemode="normal", gridcolor="#EEF1F5", zeroline=True, zerolinecolor="#C9CED4"))
    st.plotly_chart(fig, use_container_width=True)
