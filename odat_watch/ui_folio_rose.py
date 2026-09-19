"""Onglet Folio Rose : import des exports, tableau avec sélection et somme des écarts en direct,
rapprochements (manuels et groupes compensés), contrôle Oracle, rapport HTML, historique."""
from __future__ import annotations
import contextlib
import hashlib
from datetime import date
from pathlib import Path

import pandas as pd
import streamlit as st

import folio_rose as fr
import rapport_folio_rose as rp
from db import connect
from oracle_refresh import CONFIG

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_SAUVEGARDE = BASE_DIR.parent / "ControleFolioRose"
COLS_AFFICHEES = ["folio", "type", "date", "age_j", "fichier", "amont_nb", "amont_debit", "si_nb", "si_debit",
                  "ecart_nb", "ecart_debit", "nb_oracle", "montant_oracle", "montant_interface", "statut",
                  "erreur", "rapproche", "commentaire"]
LIBELLES = {"folio": "Folio", "type": "Type", "date": "Date", "age_j": "Âge (j)", "fichier": "Fichier transmis",
            "amont_nb": "Amont nb", "amont_debit": "Amont débit", "si_nb": "SI nb", "si_debit": "SI débit",
            "ecart_nb": "Écart nb", "ecart_debit": "Écart débit", "nb_oracle": "Nb Oracle",
            "montant_oracle": "Montant Oracle", "montant_interface": "Montant interface", "statut": "Statut",
            "erreur": "Erreur Oracle", "rapproche": "Rapproché", "commentaire": "Commentaire"}
COLS_MONTANTS = ("Amont débit", "SI débit", "Écart débit", "Montant Oracle", "Montant interface")
COLS_NB = ("Âge (j)", "Amont nb", "SI nb", "Écart nb", "Nb Oracle")


def _fmt_mt(v) -> str:
    return "" if pd.isna(v) else f"{float(v):,.2f}".replace(",", " ").replace(".", ",")


def _fmt_nb(v) -> str:
    return "" if pd.isna(v) else f"{int(round(float(v))):,}".replace(",", " ")


def _eur(v) -> str:
    return f"{_fmt_mt(v)} €"


def _importer_fichiers(fichiers) -> list[str]:
    msgs = []
    with contextlib.closing(connect()) as con:
        for f in fichiers:
            nom = f.name if hasattr(f, "name") else Path(f).name
            try:
                e = fr.lire_export(f.getvalue() if hasattr(f, "getvalue") else Path(f), nom)
                eid = fr.importer(e, con)
                msgs.append(f"{nom} : {'déjà importé' if eid is None else f'{len(e.lignes)} lignes importées'}")
            except (ValueError, OSError, UnicodeDecodeError) as ex:
                msgs.append(f"{nom} : ERREUR {ex}")
    return msgs


def _style(df: pd.DataFrame):
    def ligne(r):
        if r["Rapproché"]:
            return ["background-color: #EAF7EE; color: #7A8794"] * len(r)
        if r["Statut"] == "KO":
            return ["background-color: #FDECEC"] * len(r)
        return [""] * len(r)
    fmt = {**{c: _fmt_mt for c in COLS_MONTANTS if c in df.columns}, **{c: _fmt_nb for c in COLS_NB if c in df.columns}}
    return df.style.apply(ligne, axis=1).format(fmt)


def render(kpi):
    # ---------------------------------------------------------------- import
    with st.expander("📥 Importer des exports Folio Rose", expanded=False):
        fichiers = st.file_uploader("Glisser-déposer un ou plusieurs ExportCSV-*.csv", type=["csv"],
                                    accept_multiple_files=True, key="fr_upload")
        c1, c2 = st.columns(2)
        if c1.button("Importer les fichiers déposés", disabled=not fichiers, use_container_width=True):
            st.session_state["fr_import_log"] = _importer_fichiers(fichiers)
            st.rerun()
        if c2.button("Importer le dossier ControleFolioRose", use_container_width=True,
                     help=str(DOSSIER_SAUVEGARDE)):
            csvs = sorted(DOSSIER_SAUVEGARDE.glob("ExportCSV-*.csv")) + sorted((DOSSIER_SAUVEGARDE / "sauvegarde").glob("ExportCSV-*.csv"))
            st.session_state["fr_import_log"] = _importer_fichiers(csvs)
            st.rerun()
        if st.session_state.get("fr_import_log"):
            st.code("\n".join(st.session_state["fr_import_log"]))

    with contextlib.closing(connect()) as con:
        ex = fr.exports(con)
        if ex.empty:
            st.info("Aucun export importé. Déposez un fichier ExportCSV-*.csv ci-dessus.")
            return
        libelles = {int(r.id): f"{r.date_export} · {r.periode_debut} → {r.periode_fin} · {r.nb_lignes} lignes · {r.nom_fichier}"
                    for r in ex.itertuples()}
        eid = st.selectbox("Export", list(libelles), format_func=libelles.get, key="fr_export")
        export = _export_obj(eid, ex)
        lignes = fr.lignes_export(eid, con)
        groupes = fr.groupes_compenses(lignes)

        # ------------------------------------------------------------ tuiles
        c = st.columns(6)
        kpi(c[0], len(lignes), "lignes", "neutral")
        kpi(c[1], lignes["folio"].nunique(), "folios", "neutral")
        kpi(c[2], _eur(lignes["ecart_debit"].sum()), "écart débit total", "warn" if abs(lignes["ecart_debit"].sum()) >= fr.TOL else "ok")
        kpi(c[3], int(lignes["rapproche"].sum()), "lignes rapprochées", "ok")
        kpi(c[4], len(groupes), "groupes compensés en attente", "warn" if len(groupes) else "ok")
        nb_ko = int((lignes["statut"] == "KO").sum())
        kpi(c[5], nb_ko if "—" not in set(lignes["statut"]) else "—", "KO Oracle", "err" if nb_ko else "neutral")

        # ------------------------------------------------------------ filtres
        f1, f2, f3, f4 = st.columns([1, 1, 2, 1])
        types = f1.multiselect("Type", sorted(lignes["type"].unique()), key="fr_types")
        statuts = f2.multiselect("Statut", sorted(lignes["statut"].unique()), key="fr_statuts")
        folios = f3.multiselect("Folio", sorted(lignes["folio"].unique()), key="fr_folios")
        masquer = f4.checkbox("Masquer les rapprochées", True, key="fr_masquer")
        vue = lignes.copy()
        if types:
            vue = vue[vue["type"].isin(types)]
        if statuts:
            vue = vue[vue["statut"].isin(statuts)]
        if folios:
            vue = vue[vue["folio"].isin(folios)]
        if masquer:
            vue = vue[~vue["rapproche"]]
        vue = vue.reset_index(drop=True)

        # ------------------------------------------------------------ tableau + sélection
        aff = vue[COLS_AFFICHEES].rename(columns=LIBELLES)
        # Streamlit n'inclut pas les données dans l'identité d'un st.dataframe à clé : on change la clé
        # dès que l'ensemble (ou l'ordre) des lignes affichées change, sinon la sélection survit au filtre.
        sig = hashlib.blake2b("|".join(vue["empreinte"].astype(str)).encode("utf-8"), digest_size=6).hexdigest()
        ev = st.dataframe(_style(aff), use_container_width=True, hide_index=True, height=420,
                          on_select="rerun", selection_mode="multi-row", key=f"fr_table_{eid}_{sig}")
        rows = list(ev.selection.rows) if ev and ev.selection else []
        sel_idx = [i for i in rows if 0 <= i < len(vue)]
        sel = vue.iloc[sel_idx]
        somme = fr.somme_selection(vue, sel["empreinte"].tolist())
        if sel.empty:
            st.caption("Cochez des lignes : la somme de leurs écarts débit s'affiche ici. À 0, elles peuvent être rapprochées.")
        elif len(sel) >= 2 and abs(somme) < fr.TOL:
            st.success(f"✔ {len(sel)} lignes sélectionnées · somme des écarts débit = {_eur(somme)} — compensé, rapprochement possible.")
            com = st.text_input("Commentaire (optionnel)", key="fr_com")
            if st.button("🔗 Rapprocher ces lignes", type="primary"):
                try:
                    fr.rapprocher(sel["empreinte"].tolist(), com, con)
                    st.session_state["fr_msg"] = f"Rapprochement enregistré ({len(sel)} lignes)."
                    st.rerun()
                except ValueError as e:
                    st.error(str(e))
        else:
            st.info(f"{len(sel)} ligne(s) sélectionnée(s) · somme des écarts débit = {_eur(somme)}"
                    + ("" if len(sel) >= 2 else " · sélectionnez au moins deux lignes"))
        msg = st.session_state.pop("fr_msg", None)
        if msg:
            st.toast(msg, icon="✅")

        # ------------------------------------------------------------ groupes compensés
        st.markdown(f"#### Groupes compensés en attente ({len(groupes)})")
        if groupes.empty:
            st.caption("Aucun groupe folio + fichier dont la somme des écarts débit fait 0.")
        else:
            if st.button("🔗 Tout rapprocher", key="fr_tous"):
                n = 0
                for _, g in groupes.iterrows():
                    try:
                        fr.rapprocher(list(g["empreintes"]), "groupe compensé (auto)", con); n += 1
                    except ValueError:
                        pass
                st.session_state["fr_msg"] = f"{n} groupe(s) rapproché(s), {len(groupes) - n} refusé(s)."
                st.rerun()
            for i, g in groupes.iterrows():
                a, b = st.columns([5, 1])
                a.write(f"**{g['folio']}** · `{g['fichier_base']}` · {g['nb']} lignes · somme {_eur(g['somme'])}")
                if b.button("Rapprocher", key=f"fr_grp_{i}"):
                    try:
                        fr.rapprocher(list(g["empreintes"]), "groupe compensé", con)
                        st.session_state["fr_msg"] = f"Groupe {g['folio']} rapproché."
                        st.rerun()
                    except ValueError as e:
                        st.error(str(e))

        # ------------------------------------------------------------ Oracle + rapport
        st.markdown("#### Oracle et rapport")
        o1, o2 = st.columns(2)
        if o1.button("🅾 Contrôler dans Oracle", disabled=not CONFIG.exists(), use_container_width=True):
            with st.spinner("Interrogation Oracle…"):
                try:
                    st.session_state["fr_oracle_msg"] = fr.controler_oracle(eid, con)
                    st.rerun()
                except (Exception, SystemExit) as e:  # noqa: BLE001 — même mécanique que l'onglet Matin
                    st.error(f"Contrôle impossible : {e}")
        if st.session_state.get("fr_oracle_msg"):
            o1.caption(st.session_state["fr_oracle_msg"])
        if o2.button("📄 Générer le rapport HTML", use_container_width=True):
            try:
                chemin = rp.ecrire(export, lignes, groupes, fr.rapprochements(con))
                st.session_state["fr_rapport"] = str(chemin)
            except OSError as e:
                st.error(f"Écriture impossible : {e}")
        if st.session_state.get("fr_rapport"):
            p = Path(st.session_state["fr_rapport"])
            if p.exists():
                o2.download_button("⬇ Télécharger " + p.name, p.read_bytes(), file_name=p.name, mime="text/html",
                                   key="fr_dl")

        # ------------------------------------------------------------ historique
        r = fr.rapprochements(con)
        with st.expander(f"Historique des rapprochements ({int((r['annule_le'].isna()).sum()) if not r.empty else 0} actifs)"):
            if r.empty:
                st.caption("Aucun rapprochement.")
            for _, x in r.iterrows():
                a, b = st.columns([5, 1])
                etat = f" · annulé le {x['annule_le']}" if x["annule_le"] else ""
                a.write(f"{x['cree_le']} · {x['folios'] or ''} · {x['nb_lignes']} lignes · {x['commentaire'] or ''}{etat}")
                if not x["annule_le"] and b.button("Annuler", key=f"fr_ann_{x['id']}"):
                    fr.annuler_rapprochement(int(x["id"]), con)
                    st.rerun()


def _export_obj(eid: int, ex: pd.DataFrame) -> fr.Export:
    """Reconstitue un Export (métadonnées) depuis la table, pour le rapport."""
    r = ex[ex["id"] == eid].iloc[0]
    return fr.Export(nom=r["nom_fichier"], date_export=date.fromisoformat(r["date_export"]),
                     periode_debut=r["periode_debut"], periode_fin=r["periode_fin"], encodage="", file_hash="",
                     lignes=pd.DataFrame(), id=eid)
