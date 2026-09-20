"""Onglet « 🏦 Relevés bancaires » : frise de la matinée (PFE → Control-M → EBS → import → contrôle), chronologie,
continuité des comptes SG, plan de reprise, rapprochement PFE ↔ EBS, chaîne Control-M, contrôles, comptes connus."""
from __future__ import annotations

from datetime import date

import pandas as pd
import streamlit as st

import rapport_releves as rr
import releves as rb
from db import connect

COULEUR = {"ok": "#1F9D55", "warn": "#D9A400", "ko": "#D23F31", "neutral": "#8A94A6"}
FOND = {"ok": "#EAF7EE", "warn": "#FFF8E1", "ko": "#FDECEC", "neutral": "#F3F4F6"}
ICONE = {"OK": "✅", "WARN": "⚠️", "KO": "🔴", "—": "⚪"}


def _frise(f: rb.Flux) -> None:
    ton = rb.TON_VERDICT[f.verdict]
    st.markdown(f"**Flux {f.code}** — {'multi-banques, import ~07:50' if f.code == 'A' else 'Société Générale, import ~08:20'} "
                f"&nbsp; <span style='background:{FOND[ton]};color:{COULEUR[ton]};border:1px solid {COULEUR[ton]};"
                f"border-radius:10px;padding:1px 9px;font-weight:700'>{ICONE[f.verdict]} {f.verdict}</span>",
                unsafe_allow_html=True)
    cols = st.columns(5)
    for col, e in zip(cols, f.etapes):
        col.markdown(f"<div style='background:#fff;border:1px solid #dde3ea;"
                     f"border-top:4px solid {COULEUR[e['ton']]};border-radius:6px;padding:8px 10px;min-height:74px'>"
                     f"<div style='font-size:.75rem;text-transform:uppercase;color:#57606a'>{e['libelle']}</div>"
                     f"<div style='font-size:.85rem'>{e['texte']}</div></div>", unsafe_allow_html=True)
    for c in f.causes:
        (st.error if ton == "ko" else st.warning)(c)


def _tuiles(kpi, j: rb.Journee, plan: list, cont: pd.DataFrame) -> None:
    c1, c2, c3, c4, c5 = st.columns(5)
    kpi(c1, ICONE[j.verdict] + " " + j.verdict, "verdict du jour", rb.TON_VERDICT[j.verdict])
    for col, code in ((c2, "A"), (c3, "B")):
        f = j.flux[code]
        kpi(col, f.verdict, f"flux {code}", rb.TON_VERDICT[f.verdict])
    n_trou = int(cont["trou"].sum()) if not cont.empty else 0
    kpi(c4, n_trou, "comptes en rupture", "err" if n_trou else "ok")
    kpi(c5, len(plan), "fichiers à rejouer", "err" if plan else "ok")


def render(kpi):
    cfg = rb.config_releves()
    con = connect()
    try:
        st.markdown("#### Chaîne des relevés bancaires · PFE → Control-M (FINEXT_J14INT_05/06) → EBS (RBAFBIMP → DKA_SRBCTRLRB)")
        b1, b2, b3, b4 = st.columns([1.2, 1.4, 1.4, 1.6])
        # valeur par défaut portée par session_state (pas de `value` + `key` déjà en état : StreamlitAPIException)
        st.session_state.setdefault("rb_jour", date.today())
        jour = b1.date_input("Matinée", key="rb_jour", format="DD/MM/YYYY")
        if b2.button("🔄 Scanner les dossiers", type="primary", use_container_width=True, key="rb_scanner",
                     help=f"PFE : {cfg['dossier_pfe']}\nEBS : {cfg['dossier_ebs']}\nLogs : {'; '.join(str(d) for d in cfg['dossiers_logs'])}"):
            with st.spinner("Lecture des fichiers PFE, EBS et des logs…"):
                st.session_state["rb_msg"] = rb.scanner_tout(cfg, con)
        if b3.button("📋 list.txt des logs manquants", use_container_width=True, key="rb_liste"):
            st.session_state["rb_msg"] = rb.liste_logs_manquants(con)
        if st.session_state.get("rb_msg"):
            st.info(st.session_state["rb_msg"])

        vide = con.execute("SELECT (SELECT COUNT(*) FROM rb_pfe) + (SELECT COUNT(*) FROM rb_ebs) + (SELECT COUNT(*) FROM rb_imports)").fetchone()[0] == 0
        if vide:
            st.caption("Aucune donnée : copiez les exécutions PFE (dossiers <uuid>), les fichiers AFB120.txt_* et les logs "
                       ".req/.out dans les dossiers de `config.ini [releves]`, puis cliquez sur **Scanner**.")
            return

        j = rb.journee(con, jour, cfg)
        plan = rb.plan_reprise(con, cfg)
        cont = rb.continuite(con, cfg, jour)
        if b4.button("📄 Rapport HTML", use_container_width=True, key="rb_btn_rapport"):
            bilan = rr.Bilan(journee=j, chronologie=rb.chronologie(con, 15, jour), continuite=cont, plan=plan,
                             pfe=rb.rapprochement_pfe(con), controles=rb.controles(con))
            chemin = rr.ecrire(bilan, rr.DOSSIER_RAPPORTS)
            st.session_state["rb_rapport"] = str(chemin)
        if st.session_state.get("rb_rapport"):
            st.success(f"Rapport écrit : `{st.session_state['rb_rapport']}`")

        _tuiles(kpi, j, plan, cont)
        if j.motif:
            st.caption(f"{jour:%d/%m/%Y} = {j.motif} : pas d'intégration attendue.")

        st.markdown("##### Frise de la matinée")
        for code in ("A", "B"):
            _frise(j.flux[code])

        if plan:
            st.markdown("##### 🛠 Plan de reprise")
            st.error("Rupture de continuité : rejouer ces fichiers **un par un, dans l'ordre**, en attendant la fin de "
                     "chaque request RBAFBIMP (copier sous `AFB120.txt` dans `data/in`, lancer l'import, vérifier "
                     "`Relevés chargés`). Puis lancer DKA_SRBCTRLRB.")
            st.dataframe(pd.DataFrame(plan)[["ordre", "chemin", "origine", "periode", "nb_releves", "attendu"]],
                         hide_index=True, use_container_width=True,
                         column_config={"ordre": "Étape", "chemin": "Fichier source", "origine": "Origine",
                                        "periode": "Relevé", "nb_releves": "Relevés", "attendu": "Résultat attendu"})

        st.markdown("##### Chronologie des imports (15 jours)")
        ch = rb.chronologie(con, 15, jour)
        st.dataframe(ch[["debut", "request_id", "fichier", "flux", "lus", "ecrits", "charges", "erreurs", "resultat"]],
                     hide_index=True, use_container_width=True,
                     column_config={"debut": "Date / heure", "request_id": st.column_config.NumberColumn("Request", format="%d"),
                                    "fichier": "Fichier EBS", "flux": "Flux", "lus": "Lus", "ecrits": "Écrits",
                                    "charges": "Chargés", "erreurs": "Erreurs", "resultat": "Résultat"})

        with st.expander(f"Continuité des comptes {cfg['banque_flux_b']} — {int(cont['trou'].sum()) if not cont.empty else 0} en rupture", expanded=bool(plan)):
            if cont.empty:
                st.caption("Aucun import chargé pour cette banque.")
            else:
                vue = cont.sort_values(["trou", "retard_j"], ascending=[False, False])
                st.dataframe(vue[["compte", "dernier_charge", "attendu", "retard_j", "trou", "connu"]], hide_index=True,
                             use_container_width=True, height=320,
                             column_config={"compte": "Compte", "dernier_charge": "Dernier relevé chargé", "attendu": "Attendu",
                                            "retard_j": "Retard (j)", "trou": "Trou", "connu": "Connu"})

        with st.expander("Rapprochement PFE ↔ EBS"):
            pfe = rb.rapprochement_pfe(con)
            st.dataframe(pfe[["horodatage", "uuid", "flux", "nb_releves", "date_min", "date_max", "fichier_ebs", "request_id", "statut"]],
                         hide_index=True, use_container_width=True,
                         column_config={"horodatage": "Exécution PFE", "uuid": "UUID", "flux": "Flux", "nb_releves": "Relevés",
                                        "date_min": "Du", "date_max": "Au", "fichier_ebs": "Fichier EBS",
                                        "request_id": st.column_config.NumberColumn("Import", format="%d"), "statut": "Statut"})

        with st.expander("Chaîne Control-M de la matinée"):
            if j.controlm_df.empty:
                st.caption("Aucune photo ODAT pour cette matinée (importer les fichiers Report_ctm dans l'onglet Données).")
            else:
                d = j.flux["B"].controlm
                st.caption(f"Photo du {d['photo']} · conflit MOV 05/06 : {'oui' if d['conflit_mov'] else 'non'} · "
                           f"06_ZIP01 Not OK : {'oui' if d['zip06_not_ok'] else 'non'} · 06_IMP01 exécuté : {'oui' if d['import06_execute'] else 'non'}")
                st.dataframe(j.controlm_df[["job_name", "group_name", "status", "start_time", "end_time", "rerun"]],
                             hide_index=True, use_container_width=True)

        with st.expander("Contrôles DKA_SRBCTRLRB"):
            ctl = rb.controles(con)
            st.dataframe(ctl, hide_index=True, use_container_width=True)
            if not ctl.empty:
                rid = st.selectbox("Détail du contrôle", ctl["request_id"].tolist(), key="rb_ctl")
                st.dataframe(rb.lignes_controle(con, int(rid)), hide_index=True, use_container_width=True, height=300)

        with st.expander("Comptes connus (anomalies préexistantes ignorées par le verdict)"):
            df = pd.read_sql_query("SELECT cle, motif FROM rb_comptes_connus ORDER BY cle", con)
            edite = st.data_editor(df, num_rows="dynamic", hide_index=True, use_container_width=True, key="rb_connus",
                                   column_config={"cle": "banque/guichet/compte", "motif": "Motif"})
            if st.button("💾 Enregistrer les comptes connus", key="rb_connus_save"):
                rb.enregistrer_comptes_connus(edite, con)
                st.success("Comptes connus enregistrés — relancez « Scanner » pour recalculer les contrôles.")
    finally:
        con.close()
