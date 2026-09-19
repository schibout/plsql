"""Onglet Référentiel : jobs Control-M <-> programmes Oracle Applications, auto-alimenté et corrigeable."""
from __future__ import annotations
import contextlib

import pandas as pd
import streamlit as st

import referentiel as ref
from db import connect

COLONNES = ["job_name", "application_ctm", "chaine", "description", "programme_auto", "programme",
            "application_ora", "commentaire", "source", "vu_le"]
LIBELLES = {"job_name": "job Control-M", "application_ctm": "application", "chaine": "chaîne", "description": "description",
            "programme_auto": "programme (auto)", "programme": "programme (saisie)", "application_ora": "application Oracle",
            "commentaire": "commentaire", "source": "source", "vu_le": "vu le"}


def render():
    st.subheader("Référentiel chaînes Control-M ↔ programmes Oracle Applications")
    st.caption("Alimenté automatiquement à chaque import ODAT et chargement Oracle ; les colonnes « programme (saisie) », "
               "« application Oracle » et « commentaire » sont modifiables : une saisie est prioritaire partout dans "
               "l'application et survit aux resynchronisations. Effacer la saisie rend la main à l'automatique.")
    with contextlib.closing(connect()) as con:
        if st.button("🔄 Synchroniser avec les photos ODAT et les demandes Oracle", key="ref_sync"):
            n = ref.synchroniser(con)
            st.toast(f"{n} nouveau(x) job(s) ajouté(s) au référentiel.", icon="✅")
            st.cache_data.clear()
        t = ref.table(con)
        if t.empty:
            ref.synchroniser(con)
            t = ref.table(con)
        if t.empty:
            st.info("Aucun job connu : importez d'abord des photos ODAT.")
            return

        c = st.columns(4)
        c[0].metric("Jobs", len(t))
        c[1].metric("Programme trouvé (auto)", int((t["source"] == "auto").sum()))
        c[2].metric("Saisis à la main", int((t["source"] == "manuel").sum()))
        c[3].metric("À renseigner", int((t["source"] == "à renseigner").sum()))

        f1, f2, f3 = st.columns([1, 1, 2])
        apps = sorted(t["application_ctm"].dropna().unique())
        app_sel = f1.multiselect("Application", apps, default=[a for a in apps if a == "FIN-FINANCE"], key="ref_apps")
        sources = f2.multiselect("Source", ["à renseigner", "auto", "manuel"], key="ref_sources")
        recherche = f3.text_input("Rechercher (job, description, programme)", "", key="ref_q").strip().lower()
        vue = t.copy()
        if app_sel:
            vue = vue[vue["application_ctm"].isin(app_sel)]
        if sources:
            vue = vue[vue["source"].isin(sources)]
        if recherche:
            m = pd.Series(False, index=vue.index)
            for col in ("job_name", "description", "programme", "programme_auto", "chaine"):
                m |= vue[col].str.lower().str.contains(recherche, regex=False)
            vue = vue[m]
        vue = vue[COLONNES].reset_index(drop=True)
        # la colonne « programme » de la vue est la valeur effective : on édite la saisie brute
        brute = t.set_index("job_name")
        vue["programme"] = vue["job_name"].map(lambda j: "" if brute.loc[j, "source"] != "manuel" else brute.loc[j, "programme"])

        edite = st.data_editor(
            vue.rename(columns=LIBELLES), use_container_width=True, hide_index=True, height=min(700, 38 * len(vue) + 40),
            num_rows="fixed", key="ref_editeur",
            disabled=[LIBELLES[c] for c in COLONNES if c not in ("programme", "application_ora", "commentaire")],
            column_config={
                LIBELLES["programme_auto"]: st.column_config.TextColumn(width="large"),
                LIBELLES["programme"]: st.column_config.TextColumn(width="large", help="Laisser vide pour garder la valeur automatique"),
                LIBELLES["description"]: st.column_config.TextColumn(width="large"),
                LIBELLES["source"]: st.column_config.TextColumn(width="small"),
            })
        modifs = 0
        for i, row in edite.iterrows():
            job = row[LIBELLES["job_name"]]
            avant = vue.iloc[i]
            nouveau = {k: (row[LIBELLES[k]] or "") for k in ("programme", "application_ora", "commentaire")}
            if any(str(nouveau[k]).strip() != str(avant[k]).strip() for k in nouveau):
                ref.enregistrer(con, job, nouveau["programme"], nouveau["application_ora"], nouveau["commentaire"])
                modifs += 1
        if modifs:
            st.cache_data.clear()
            st.toast(f"{modifs} job(s) mis à jour.", icon="💾")
            st.rerun()

        st.download_button("⬇ Exporter le référentiel (CSV)", t[COLONNES].to_csv(index=False, sep=";").encode("utf-8-sig"),
                           file_name="referentiel_jobs_oracle.csv", mime="text/csv", key="ref_csv")
