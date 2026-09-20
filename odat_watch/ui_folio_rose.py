"""Onglet Folio Rose : import des exports, tableau avec sélection et somme des écarts en direct,
rapprochements (manuels et groupes compensés), contrôle Oracle, rapport HTML, historique."""
from __future__ import annotations
import contextlib
import hashlib
from pathlib import Path

import pandas as pd
import streamlit as st

import folio_rose as fr
import rapport_folio_rose as rp
from db import connect
from oracle_refresh import CONFIG

BASE_DIR = Path(__file__).resolve().parent
DOSSIER_SAUVEGARDE = BASE_DIR.parent / "ControleFolioRose"
# Colonnes et ordre du Rapport_Verification_*.csv du .ps1, complétés par l'âge, le statut et le rapprochement
COLS_AFFICHEES = ["folio", "type", "date", "age_j", "fichier",
                  "amont_nb", "amont_debit", "amont_credit", "si_nb", "si_debit", "si_credit",
                  "ecart_nb", "ecart_debit", "ecart_credit", "commentaire",
                  "somme_amont_fichier", "somme_ecart_fichier",
                  "montant_interface", "nb_oracle", "montant_oracle", "ecart_nb_calcule", "ecart_mt_calcule",
                  "statut", "erreur", "rapproche", "present", "date_dernier_export"]
COLS_ORACLE = ["montant_interface", "nb_oracle", "montant_oracle", "ecart_nb_calcule", "ecart_mt_calcule", "erreur"]
LIBELLES = {"folio": "Folio", "type": "Type", "date": "Date", "age_j": "Âge (j)", "fichier": "Nom fichier transmis",
            "amont_nb": "App Amont Nb pièce", "amont_debit": "App Amont Débit", "amont_credit": "App Amont Crédit",
            "si_nb": "SI Finance Nb pièce", "si_debit": "SI Finance Débit", "si_credit": "SI Finance Crédit",
            "ecart_nb": "Écarts Nb pièce", "ecart_debit": "Écarts Débit", "ecart_credit": "Écarts Crédit",
            "commentaire": "Commentaire",
            "somme_amont_fichier": "Somme Amont Fichier", "somme_ecart_fichier": "Somme Écart Fichier",
            "montant_interface": "Montant Interface OA", "nb_oracle": "Nb Pièces OA", "montant_oracle": "Montant OA",
            "ecart_nb_calcule": "Écart Nb Pièce Calculé", "ecart_mt_calcule": "Écart Mt Calculé",
            "statut": "Statut Vérification", "erreur": "Erreur Oracle", "rapproche": "Rapproché",
            "present": "Présente", "date_dernier_export": "Dernier export"}
COLS_MONTANTS = ("App Amont Débit", "App Amont Crédit", "SI Finance Débit", "SI Finance Crédit", "Écarts Débit",
                 "Écarts Crédit", "Somme Amont Fichier", "Somme Écart Fichier", "Montant Interface OA", "Montant OA",
                 "Écart Mt Calculé")
COLS_NB = ("Âge (j)", "App Amont Nb pièce", "SI Finance Nb pièce", "Écarts Nb pièce", "Nb Pièces OA", "Écart Nb Pièce Calculé")


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
        if "Présente" in r and not r["Présente"]:
            return ["color: #9AA3AF; font-style: italic"] * len(r)
        if r["Statut Vérification"] == "KO":
            return ["background-color: #FDECEC"] * len(r)
        return [""] * len(r)
    return df.style.apply(ligne, axis=1)


# Formats numériques confiés au navigateur (locale française) : les valeurs restent des nombres,
# donc triables, et les NULL Oracle s'affichent vides (un Styler les rendrait « None »).
COLONNES_CONFIG = {**{c: st.column_config.NumberColumn(c, format="euro") for c in COLS_MONTANTS},
                   **{c: st.column_config.NumberColumn(c, format="%d") for c in COLS_NB},
                   "Rapproché": st.column_config.CheckboxColumn("Rapproché", disabled=True),
                   "Présente": st.column_config.CheckboxColumn("Présente", disabled=True,
                                                               help="Décochée : absente du dernier export couvrant sa date")}


def render(kpi):
    # ---------------------------------------------------------------- import
    with st.expander("📥 Importer des exports Folio Rose", expanded=False):
        fichiers = st.file_uploader("Glisser-déposer un ou plusieurs ExportCSV-*.csv", type=["csv"],
                                    accept_multiple_files=True, key="fr_upload")
        c1, c2 = st.columns(2)
        if c1.button("Importer les fichiers déposés", disabled=not fichiers, use_container_width=True, key="fr_imp_fichiers"):
            st.session_state["fr_import_log"] = _importer_fichiers(fichiers)
            st.rerun()
        if c2.button("Importer le dossier ControleFolioRose", use_container_width=True, key="fr_imp_dossier",
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
        export = fr.dernier_export(con)
        st.caption(f"État courant des lignes (clé : folio + date + fichier) · dernier export : {export.date_export:%d/%m/%Y} "
                   f"· période {export.periode_debut} → {export.periode_fin} · {len(ex)} import(s)")
        voir_disparues = st.checkbox("Afficher aussi les lignes disparues des derniers exports", False, key="fr_disparues")
        lignes = fr.lignes(con, disparues=voir_disparues)
        groupes = fr.groupes_compenses(lignes[lignes["present"]])

        # ------------------------------------------------------------ Oracle + rapport
        o1, o2 = st.columns(2)
        if o1.button("🅾 Contrôler dans Oracle", disabled=not CONFIG.exists(), use_container_width=True, key="fr_oracle"):
            with st.spinner("Interrogation Oracle…"):
                try:
                    st.session_state["fr_oracle_msg"] = fr.controler_oracle(con)
                    st.rerun()
                except (Exception, SystemExit) as e:  # noqa: BLE001 — même mécanique que l'onglet Matin
                    st.error(f"Contrôle impossible : {e}")
        if st.session_state.get("fr_oracle_msg"):
            o1.caption(st.session_state["fr_oracle_msg"])
        if o2.button("📄 Générer le rapport HTML", use_container_width=True, key="fr_btn_rapport"):
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


        # ------------------------------------------------------------ tuiles
        c = st.columns(4)
        kpi(c[0], len(lignes), "lignes", "neutral")
        kpi(c[1], lignes["folio"].nunique(), "folios", "neutral")
        kpi(c[2], int(lignes["rapproche"].sum()), "lignes rapprochées", "ok")
        nb_ko = int((lignes["statut"] == "KO").sum())
        kpi(c[3], nb_ko if "—" not in set(lignes["statut"]) else "—", "KO Oracle", "err" if nb_ko else "neutral")

        # ------------------------------------------------------------ filtres
        f1, f2, f3, f4 = st.columns([1, 1, 2, 1])
        types = f1.multiselect("Type", sorted(lignes["type"].unique()), key="fr_types")
        statuts = f2.multiselect("Statut", sorted(lignes["statut"].unique()), key="fr_statuts")
        folios = f3.multiselect("Folio", sorted(lignes["folio"].unique()), key="fr_folios")
        masquer = f4.checkbox("Masquer les rapprochées", True, key="fr_masquer")
        vue = lignes.copy()
        eid = export.id
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
        # colonnes Oracle masquées tant qu'aucun contrôle n'a été lancé (Streamlit afficherait « None »)
        colonnes = COLS_AFFICHEES if "—" not in set(lignes["statut"]) else [c for c in COLS_AFFICHEES if c not in COLS_ORACLE]
        aff = vue[colonnes].rename(columns=LIBELLES)
        for c in COLS_MONTANTS + COLS_NB:
            if c in aff.columns:
                aff[c] = pd.to_numeric(aff[c], errors="coerce")
        # Streamlit n'inclut pas les données dans l'identité d'un st.dataframe à clé : on change la clé
        # dès que l'ensemble (ou l'ordre) des lignes affichées change, sinon la sélection survit au filtre.
        sig = hashlib.blake2b("|".join(vue["empreinte"].astype(str)).encode("utf-8"), digest_size=6).hexdigest()
        ev = st.dataframe(_style(aff), use_container_width=True, hide_index=True, height=420,
                          column_config=COLONNES_CONFIG, on_select="rerun", selection_mode="multi-row",
                          key=f"fr_table_{eid}_{sig}")
        rows = list(ev.selection.rows) if ev and ev.selection else []
        sel_idx = [i for i in rows if 0 <= i < len(vue)]
        sel = vue.iloc[sel_idx]
        sommes = fr.sommes_selection(vue, sel["empreinte"].tolist())
        ok = len(sel) >= 2 and fr.compensee(sommes)
        _panneau_flottant(len(sel), sommes, ok)
        if sel.empty:
            st.caption("Cochez des lignes : les écarts débit, crédit et nombre de pièces se cumulent dans le panneau "
                       "en bas de l'écran. Quand les trois sont à 0, les lignes peuvent être rapprochées.")
        elif ok:
            st.success(f"✔ {len(sel)} lignes sélectionnées · écarts débit {_eur(sommes['ecart_debit'])} · "
                       f"crédit {_eur(sommes['ecart_credit'])} · pièces {sommes['ecart_nb']:g} — compensé, rapprochement possible.")
            com = st.text_input("Commentaire (optionnel)", key="fr_com")
            if st.button("🔗 Rapprocher ces lignes", type="primary", key="fr_rapprocher"):
                try:
                    fr.rapprocher(sel["empreinte"].tolist(), com, con)
                    st.session_state["fr_msg"] = f"Rapprochement enregistré ({len(sel)} lignes)."
                    st.rerun()
                except ValueError as e:
                    st.error(str(e))
        else:
            st.info(f"{len(sel)} ligne(s) sélectionnée(s) · écarts débit {_eur(sommes['ecart_debit'])} · "
                    f"crédit {_eur(sommes['ecart_credit'])} · pièces {sommes['ecart_nb']:g}"
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
                a.write(f"**{g['folio']}** · `{g['fichier_base']}` · {g['nb']} lignes · débit {_eur(g['somme'])} · "
                        f"crédit {_eur(g['somme_credit'])} · pièces {g['somme_nb']:g}")
                if b.button("Rapprocher", key=f"fr_grp_{i}"):
                    try:
                        fr.rapprocher(list(g["empreintes"]), "groupe compensé", con)
                        st.session_state["fr_msg"] = f"Groupe {g['folio']} rapproché."
                        st.rerun()
                    except ValueError as e:
                        st.error(str(e))

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


def _panneau_flottant(n: int, sommes: dict, ok: bool) -> None:
    """Compteur toujours visible (position fixe en bas à droite) : les trois écarts de la sélection."""
    if n == 0:
        return
    fond, bord, texte = ("#EAF7EE", "#1F9D55", "#0B6B3A") if ok else ("#FFF8E1", "#D9A400", "#5B4A00")
    etat = "✔ compensé — rapprochement possible" if ok else ("sélectionnez au moins deux lignes" if n < 2 else "écarts non nuls")
    st.markdown(f"""
<style>.fr-flot {{position:fixed; right:24px; bottom:24px; z-index:1000; background:{fond}; border:2px solid {bord};
  color:{texte}; border-radius:14px; padding:.7rem 1.1rem; box-shadow:0 8px 24px rgba(16,24,40,.18); font-size:.9rem; min-width:300px;}}
.fr-flot b {{font-size:1.05rem;}} .fr-flot .v {{font-variant-numeric:tabular-nums; font-weight:700;}}
.fr-flot table {{border-collapse:collapse; margin-top:.3rem;}} .fr-flot td {{padding:.05rem .6rem .05rem 0;}}</style>
<div class="fr-flot"><b>{n} ligne(s) sélectionnée(s)</b><table>
<tr><td>Écart débit</td><td class="v">{_eur(sommes['ecart_debit'])}</td></tr>
<tr><td>Écart crédit</td><td class="v">{_eur(sommes['ecart_credit'])}</td></tr>
<tr><td>Écart nb pièces</td><td class="v">{sommes['ecart_nb']:g}</td></tr></table>
<div style="margin-top:.35rem">{etat}</div></div>""", unsafe_allow_html=True)
