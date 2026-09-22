"""Sous-onglet GDR : rejets ouverts (pièces et lignes), filtres, ancienneté, historique des imports."""
from __future__ import annotations
import contextlib

import pandas as pd
import streamlit as st

import gdr as gd
from db import connect

LIB_PIECES = {"type": "Type", "numero_piece": "N° pièce", "folio": "Folio", "fichier_source": "Nom fichier transmis",
              "code_rejet": "Code rejet", "libelle_rejet": "Libellé rejet", "montant": "Montant",
              "nb_lignes": "Lignes", "vu_depuis": "Rejetée depuis", "id_gdr": "ID GDR"}
COLS_PIECES = ["type", "numero_piece", "folio", "fichier_source", "code_rejet", "libelle_rejet", "montant",
               "nb_lignes", "vu_depuis", "id_gdr"]
LIB_LIGNES = {"type": "Type", "numero_piece": "N° pièce", "folio": "Folio", "folio_libelle": "Folio (libellé)",
              "fichier_source": "Nom fichier transmis", "code_rejet": "Code rejet", "libelle_rejet": "Libellé rejet",
              "societe": "Société", "region": "Région", "compte": "Compte", "montant_debit": "Montant débit",
              "montant_credit": "Montant crédit", "description": "Description", "date_piece": "Date pièce",
              "date_creation_gdr": "Créée le", "date_arrete": "Arrêté", "vu_depuis": "Rejetée depuis",
              "vu_le": "Vue le", "present": "Ouverte", "disparu_le": "Traitée le", "id_gdr": "ID GDR",
              "line_gdr": "Line GDR"}
COLS_LIGNES = ["type", "numero_piece", "folio", "fichier_source", "code_rejet", "libelle_rejet", "societe",
               "compte", "montant_debit", "montant_credit", "description", "date_piece", "date_creation_gdr",
               "vu_depuis", "vu_le", "present", "disparu_le", "id_gdr", "line_gdr"]
COLS_MONTANTS = ("Montant", "Montant débit", "Montant crédit")


def _eur(v) -> str:
    return f"{float(v):,.2f}".replace(",", " ").replace(".", ",") + " €"


def _config(colonnes) -> dict:
    cfg = {c: st.column_config.NumberColumn(c, format="euro") for c in COLS_MONTANTS if c in colonnes}
    if "Lignes" in colonnes:
        cfg["Lignes"] = st.column_config.NumberColumn("Lignes", format="%d")
    if "Ouverte" in colonnes:
        cfg["Ouverte"] = st.column_config.CheckboxColumn("Ouverte", disabled=True,
                                                         help="Décochée : absente de la dernière photo, rejet traité")
    return cfg


def _table(df: pd.DataFrame, colonnes: list[str], libelles: dict, hauteur: int) -> None:
    aff = df[[c for c in colonnes if c in df.columns]].rename(columns=libelles)
    for c in COLS_MONTANTS:
        if c in aff.columns:
            aff[c] = pd.to_numeric(aff[c], errors="coerce")
    st.dataframe(aff, use_container_width=True, hide_index=True, height=hauteur, column_config=_config(aff.columns))


def render(kpi):
    racine = gd.config_gdr()["racine"]
    with contextlib.closing(connect()) as con:
        # ------------------------------------------------------------ import
        c1, c2 = st.columns([1, 3])
        if c1.button("📥 Importer les nouveaux exports", use_container_width=True, key="gdr_import",
                     help=str(racine)):
            st.session_state["gdr_import_log"] = gd.importer_dossier(racine, con)
            st.session_state.pop("cf_gdr_log", None)     # l'onglet Ctrl Flux rebalaiera le dossier
            st.rerun()
        c2.caption(f"Exports quotidiens « Synthèse des rejets AP / AR / GL » lus dans `{racine}` "
                   "(`config.ini [gdr] racine`). Chaque export est une photo des rejets encore ouverts.")
        if st.session_state.get("gdr_import_log"):
            st.code("\n".join(st.session_state["gdr_import_log"]))

        fichiers = gd.fichiers(con)
        if fichiers.empty:
            st.info(f"Aucun export GDR importé. Déposez les fichiers « JJMMAAAA_Synthese_des_rejets_*.csv » "
                    f"dans `{racine}`, puis cliquez sur « Importer les nouveaux exports ».")
            return
        tous = gd.rejets(con, ouverts=False)
        ouverts = tous[tous["present"]]
        pieces_ouvertes = gd.pieces(ouverts)
        derniere = fichiers["date_photo"].max()
        st.caption(f"Dernière photo : {derniere} · {len(fichiers)} export(s) importé(s) · "
                   f"types présents : {', '.join(sorted(fichiers['type'].unique()))}")

        # ------------------------------------------------------------ tuiles
        t = st.columns(5)
        kpi(t[0], len(pieces_ouvertes), "pièces rejetées", "err" if len(pieces_ouvertes) else "ok")
        kpi(t[1], len(ouverts), "lignes", "neutral")
        montant = float(pieces_ouvertes["montant"].sum()) if not pieces_ouvertes.empty else 0.0
        t[2].markdown(f"**{_eur(montant)}** montant rejeté")
        nouvelles = int((ouverts["vu_depuis"] == derniere).sum()) if not ouverts.empty else 0
        kpi(t[3], nouvelles, "lignes nouvelles", "warn" if nouvelles else "neutral")
        traitees = int((tous["disparu_le"] == derniere).sum()) if not tous.empty else 0
        kpi(t[4], traitees, "lignes traitées", "ok")

        # ------------------------------------------------------------ filtres
        f1, f2, f3, f4 = st.columns([1, 1.4, 2, 1.2])
        types = f1.multiselect("Type", sorted(tous["type"].unique()), key="gdr_types")
        codes = f2.multiselect("Code rejet", sorted(tous["code_rejet"].dropna().unique()), key="gdr_codes")
        folios = f3.multiselect("Folio", sorted(tous["folio"].dropna().unique()), key="gdr_folios")
        voir_traites = f4.checkbox("Afficher les rejets traités", False, key="gdr_traites",
                                   help="Pièces absentes de la dernière photo de leur type.")
        recherche = st.text_input("Recherche (fichier, n° de pièce, description)", key="gdr_recherche",
                                  placeholder="Nom du fichier transmis, numéro de pièce, libellé…")

        vue = tous if voir_traites else ouverts
        if types:
            vue = vue[vue["type"].isin(types)]
        if codes:
            vue = vue[vue["code_rejet"].isin(codes)]
        if folios:
            vue = vue[vue["folio"].isin(folios)]
        if recherche.strip():
            r = recherche.strip()
            cibles = ["fichier_source", "numero_piece", "description", "libelle_rejet", "folio_libelle", "societe"]
            masque = False
            for c in cibles:
                masque = vue[c].fillna("").astype(str).str.contains(r, case=False, regex=False) | masque
            vue = vue[masque]
        vue = vue.reset_index(drop=True)

        # ------------------------------------------------------------ pièces puis lignes
        pcs = gd.pieces(vue)
        st.markdown(f"#### Pièces rejetées ({len(pcs)})")
        if pcs.empty:
            st.caption("Aucune pièce pour ces filtres.")
        else:
            st.caption(f"Montant total {_eur(float(pcs['montant'].sum()))} · "
                       f"{pcs['fichier_source'].nunique()} fichier(s) transmis · {pcs['folio'].nunique()} folio(s)")
            _table(pcs.sort_values(["type", "folio", "numero_piece"]), COLS_PIECES, LIB_PIECES, 320)

        st.markdown(f"#### Lignes rejetées ({len(vue)})")
        if vue.empty:
            st.caption("Aucune ligne pour ces filtres.")
        else:
            _table(vue, COLS_LIGNES, LIB_LIGNES, 380)

        # ------------------------------------------------------------ répartitions
        if not pcs.empty:
            g1, g2 = st.columns(2)
            par_code = (pcs.groupby(["code_rejet", "libelle_rejet"]).agg(pieces=("id_gdr", "size"),
                                                                        montant=("montant", "sum"))
                        .reset_index().sort_values("pieces", ascending=False))
            g1.markdown("**Par code rejet**")
            g1.dataframe(par_code.rename(columns={"code_rejet": "Code", "libelle_rejet": "Libellé",
                                                  "pieces": "Pièces", "montant": "Montant"}),
                         use_container_width=True, hide_index=True, height=220,
                         column_config={"Montant": st.column_config.NumberColumn("Montant", format="euro")})
            par_folio = (pcs.groupby("folio").agg(pieces=("id_gdr", "size"), montant=("montant", "sum"))
                         .reset_index().sort_values("montant", ascending=False))
            g2.markdown("**Par folio**")
            g2.dataframe(par_folio.rename(columns={"folio": "Folio", "pieces": "Pièces", "montant": "Montant"}),
                         use_container_width=True, hide_index=True, height=220,
                         column_config={"Montant": st.column_config.NumberColumn("Montant", format="euro")})

        # ------------------------------------------------------------ historique des imports
        with st.expander(f"🧾 Imports GDR ({len(fichiers)})", expanded=False):
            st.dataframe(fichiers.rename(columns={"nom_fichier": "Fichier", "type": "Type", "date_photo": "Photo",
                                                  "rang": "Rang", "importe_le": "Importé le",
                                                  "nb_lignes": "Lignes"}).drop(columns=["id"]),
                         use_container_width=True, hide_index=True, height=260)
