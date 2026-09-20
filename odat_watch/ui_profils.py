"""Onglet Profils : profil calculé de chaque job Control-M + référentiel programme Oracle (auto, corrigeable)."""
from __future__ import annotations
import contextlib
from datetime import datetime

import pandas as pd
import streamlit as st

import referentiel as ref
from db import connect

COLS_REF = ["programme_auto", "programme", "application_ora", "commentaire", "source"]
COLS_SAISIE = ("programme", "application_ora", "commentaire")
LIBELLES = {"job": "job", "frequence": "fréquence", "description": "description", "groupe": "chaîne", "heure": "heure",
            "lendemain": "J+1", "duree_min": "durée (min)", "fiabilite": "fiabilité", "nb_exec": "exécutions",
            "jours": "jours", "cyclique": "cyclique", "script": "script",
            "programme_auto": "programme (auto)", "programme": "programme (saisie)", "application_ora": "application Oracle",
            "commentaire": "commentaire", "source": "source"}
COLONNES = list(LIBELLES)


def fusion(profils: pd.DataFrame, table_ref: pd.DataFrame) -> pd.DataFrame:
    """Profils (une ligne par job) enrichis des colonnes du référentiel ; « programme » = saisie manuelle brute
    (vide si la valeur effective est l'automatique). Un job absent du référentiel est « à renseigner »."""
    if profils.empty:
        return pd.DataFrame(columns=COLONNES)
    r = table_ref[["job_name", *COLS_REF]].copy() if not table_ref.empty else pd.DataFrame(columns=["job_name", *COLS_REF])
    r["programme"] = r["programme"].where(r["source"] == "manuel", "")
    out = profils.merge(r, left_on="job", right_on="job_name", how="left").drop(columns="job_name")
    out["source"] = out["source"].fillna("à renseigner")
    for c in COLS_REF:
        out[c] = out[c].fillna("")
    return out[COLONNES].reset_index(drop=True)


def rechercher(vue: pd.DataFrame, frequences: list[str], chaines: list[str], sources: list[str], recherche: str) -> pd.DataFrame:
    """Filtres de l'onglet : fréquence, chaîne, source du programme, texte libre (job, description, script, programmes, commentaire)."""
    if frequences:
        vue = vue[vue["frequence"].isin(frequences)]
    if chaines:
        vue = vue[vue["groupe"].isin(chaines)]
    if sources:
        vue = vue[vue["source"].isin(sources)]
    if recherche:
        m = pd.Series(False, index=vue.index)
        for col in ("job", "description", "script", "programme", "programme_auto", "application_ora", "commentaire"):
            m |= vue[col].fillna("").astype(str).str.lower().str.contains(recherche, regex=False)
        vue = vue[m]
    return vue


def render(profils: pd.DataFrame, application: str, now: datetime, filtrer):
    st.caption("Profil calculé pour chaque job à partir de l'historique (plus il y a de jours, plus c'est fiable), "
               "complété par le programme Oracle Applications déduit des demandes Oracle. Les colonnes « programme (saisie) », "
               "« application Oracle » et « commentaire » sont modifiables : une saisie est prioritaire partout dans "
               "l'application et survit aux resynchronisations ; l'effacer rend la main à l'automatique.")
    with contextlib.closing(connect()) as con:
        if st.button("🔄 Synchroniser le référentiel avec les photos ODAT et les demandes Oracle", key="prof_sync"):
            n = ref.synchroniser(con)
            st.toast(f"{n} nouveau(x) job(s) ajouté(s) au référentiel.", icon="✅")
            st.cache_data.clear()
        t = ref.table(con)
        if t.empty:
            ref.synchroniser(con)
            t = ref.table(con)
        vue = fusion(profils, t)
        if vue.empty:
            st.info("Aucun job connu : importez d'abord des photos ODAT.")
            return

        c = st.columns(4)
        c[0].metric("Jobs", len(vue))
        c[1].metric("Programme trouvé (auto)", int((vue["source"] == "auto").sum()))
        c[2].metric("Saisis à la main", int((vue["source"] == "manuel").sum()))
        c[3].metric("À renseigner", int((vue["source"] == "à renseigner").sum()))

        # ------------------------------------------------------------ filtres
        f0, f1, f2, f3 = st.columns([1, 1, 1, 2])
        frequences = f0.multiselect("Fréquence", sorted(vue["frequence"].dropna().unique()), key="prof_freq")
        chaines = f1.multiselect("Chaîne", sorted(vue["groupe"].dropna().unique()), key="prof_chaines")
        sources = f2.multiselect("Source du programme", ["à renseigner", "auto", "manuel"], key="prof_sources")
        recherche = f3.text_input("Rechercher (job, description, script, programme, commentaire)", "", key="prof_q").strip().lower()
        vue = rechercher(filtrer(vue), frequences, chaines, sources, recherche).reset_index(drop=True)
        st.caption(f"{len(vue)} job(s) affiché(s).")

        edite = st.data_editor(
            vue.rename(columns=LIBELLES), use_container_width=True, hide_index=True, height=min(700, 38 * len(vue) + 40),
            num_rows="fixed", key="prof_editeur",
            disabled=[LIBELLES[c] for c in COLONNES if c not in COLS_SAISIE],
            column_config={
                LIBELLES["fiabilite"]: st.column_config.ProgressColumn("fiabilité", min_value=0, max_value=100, format="%d %%"),
                LIBELLES["duree_min"]: st.column_config.NumberColumn("durée (min)", format="%.1f"),
                LIBELLES["lendemain"]: st.column_config.CheckboxColumn("J+1"),
                LIBELLES["cyclique"]: st.column_config.CheckboxColumn("cyclique"),
                LIBELLES["description"]: st.column_config.TextColumn(width="large"),
                LIBELLES["programme_auto"]: st.column_config.TextColumn(width="large"),
                LIBELLES["programme"]: st.column_config.TextColumn(width="large", help="Laisser vide pour garder la valeur automatique"),
                LIBELLES["source"]: st.column_config.TextColumn(width="small"),
            })
        modifs = 0
        for i, row in edite.iterrows():
            avant = vue.iloc[i]
            nouveau = {k: (row[LIBELLES[k]] or "") for k in COLS_SAISIE}
            if any(str(nouveau[k]).strip() != str(avant[k]).strip() for k in nouveau):
                ref.enregistrer(con, avant["job"], nouveau["programme"], nouveau["application_ora"], nouveau["commentaire"])
                modifs += 1
        if modifs:
            st.cache_data.clear()
            st.toast(f"{modifs} job(s) mis à jour.", icon="💾")
            st.rerun()

        st.download_button("⬇ Exporter les profils et le référentiel (CSV)",
                           vue.to_csv(index=False, sep=";").encode("utf-8-sig"),
                           f"profils_{application}_{now:%Y%m%d}.csv", "text/csv", key="prof_csv")
