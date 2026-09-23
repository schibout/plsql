"""Sous-onglet Historique de Ctrl Flux : toutes les lignes jamais chargées, une par clé folio + date + fichier
transmis, dans leur dernière version connue, et la liste des exports versés."""
from __future__ import annotations
import contextlib
from pathlib import Path

import pandas as pd
import streamlit as st

import ctrl_flux as cf
from db import connect
from ui_ctrl_flux import DOSSIER_SAUVEGARDE

COLS = {"folio": "Folio", "date": "Date", "type": "Type", "fichier": "Nom fichier transmis",
        "amont_nb": "Amont Nb", "amont_debit": "Amont Débit", "si_nb": "SI Nb", "si_debit": "SI Débit",
        "ecart_nb": "Écart Nb", "ecart_debit": "Écart Débit", "ecart_credit": "Écart Crédit",
        "premier_vu": "Premier vu", "dernier_vu": "Dernier vu", "nb_exports": "Exports",
        "dans_dernier": "Dans le dernier export", "dernier_export": "Dernier export", "commentaire": "Commentaire"}
EUROS = ("Amont Débit", "SI Débit", "Écart Débit", "Écart Crédit")


def reconstituer(chemins) -> list[str]:
    """Verse des exports dans l'historique sans toucher à la situation actuelle."""
    chemins = list(chemins)
    msgs = []
    with contextlib.closing(connect()) as con:
        for i in cf.ordre_chronologique([Path(p).name for p in chemins]):
            p = Path(chemins[i])
            try:
                msgs.append(f"{p.name} : {cf.historiser(cf.lire_export(p), con)} lignes")
            except (ValueError, OSError, UnicodeDecodeError) as ex:
                msgs.append(f"{p.name} : ERREUR {ex}")
    return msgs


def render(kpi):
    with contextlib.closing(connect()) as con:
        h = cf.historique(con)
        ex = cf.exports_historiques(con)

    c1, c2 = st.columns([1.3, 3])
    if c1.button("📥 Reconstituer depuis le dossier ControleFolioRose", use_container_width=True, key="hf_reconst",
                 help=f"Verse dans l'historique tous les ExportCSV-*.csv de {DOSSIER_SAUVEGARDE} et de son "
                      "sous-dossier sauvegarde, du plus ancien au plus récent. La situation actuelle n'est pas touchée."):
        csvs = list(DOSSIER_SAUVEGARDE.glob("ExportCSV-*.csv")) + list((DOSSIER_SAUVEGARDE / "sauvegarde").glob("ExportCSV-*.csv"))
        st.session_state["hf_log"] = reconstituer(csvs)
        st.rerun()
    c2.caption("Chaque fichier chargé dans Ctrl Flux est versé ici. Clé : folio + date + nom du fichier transmis. "
               "Une ligne déjà connue prend les valeurs de l'export le plus récent ; rien n'est supprimé.")
    if st.session_state.get("hf_log"):
        with st.expander(f"Journal de la reconstitution ({len(st.session_state['hf_log'])})"):
            st.code("\n".join(st.session_state["hf_log"]))

    if h.empty:
        st.info("Historique vide. Chargez un export dans Ctrl Flux, ou reconstituez-le depuis le dossier.")
        return

    t = st.columns(5)
    kpi(t[0], len(h), "lignes connues", "neutral")
    kpi(t[1], len(ex), "exports versés", "neutral")
    kpi(t[2], h["folio"].nunique(), "folios", "neutral")
    kpi(t[3], int(h["dans_dernier"].sum()), "dans le dernier export", "ok")
    en_ecart = int((h["ecart_debit"].fillna(0).abs() >= 0.005).sum())
    kpi(t[4], en_ecart, "lignes en écart (dernière version)", "warn" if en_ecart else "ok")

    f1, f2, f3, f4 = st.columns([1.2, 1, 2, 1.2])
    folios = f1.multiselect("Folio", sorted(h["folio"].dropna().unique()), key="hf_folios")
    types = f2.multiselect("Type", sorted(h["type"].dropna().unique()), key="hf_types")
    recherche = f3.text_input("Recherche (fichier transmis, commentaire)", key="hf_rech")
    ecarts = f4.checkbox("Seulement les écarts", False, key="hf_ecarts")
    absentes = f4.checkbox("Absentes du dernier export", False, key="hf_absentes")
    vue = h
    if folios:
        vue = vue[vue["folio"].isin(folios)]
    if types:
        vue = vue[vue["type"].isin(types)]
    if recherche.strip():
        r = recherche.strip()
        vue = vue[vue["fichier"].fillna("").str.contains(r, case=False, regex=False)
                  | vue["commentaire"].fillna("").str.contains(r, case=False, regex=False)]
    if ecarts:
        vue = vue[vue["ecart_debit"].fillna(0).abs() >= 0.005]
    if absentes:
        vue = vue[~vue["dans_dernier"]]

    st.markdown(f"#### Lignes ({len(vue)})")
    aff = vue[list(COLS)].rename(columns=COLS)
    st.dataframe(aff, use_container_width=True, hide_index=True, height=520,
                 column_config={**{c: st.column_config.NumberColumn(c, format="euro") for c in EUROS},
                                "Dans le dernier export": st.column_config.CheckboxColumn(disabled=True)})
    st.download_button("⬇ Exporter la sélection (CSV)", aff.to_csv(sep=";", index=False).encode("utf-8-sig"),
                       file_name="ctrl_flux_historique.csv", mime="text/csv", key="hf_dl")

    with st.expander(f"Exports versés ({len(ex)})"):
        st.dataframe(ex.rename(columns={"nom_fichier": "Fichier", "date_export": "Date export",
                                        "periode_debut": "Période début", "periode_fin": "Période fin",
                                        "nb_lignes": "Lignes", "importe_le": "Versé le"}),
                     use_container_width=True, hide_index=True)
