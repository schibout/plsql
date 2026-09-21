"""Onglet Prélèvements : date de référence, lancement du rapprochement clé métier (outil
CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS), tuiles, justification des écarts, clés par statut, téléchargements."""
from __future__ import annotations
from datetime import date

import streamlit as st

import prelevements as pv


def _fmt_nb(n) -> str:
    return f"{int(n):,}".replace(",", " ")


def _fmt_montant(m) -> str:
    return f"{float(m):,.2f} €".replace(",", " ").replace(".", ",")


def _tuiles(kpi, r: dict) -> None:
    c1, c2, c3, c4, c5, c6, c7 = st.columns(7)
    g = r["statut_global"]
    kpi(c1, pv.LIBELLES_GLOBAL.get(g, g), "résultat global", pv.TON_GLOBAL.get(g, "neutral"))
    kpi(c2, _fmt_nb(r["nb_emis"]), "prélèvements émis", "neutral")
    kpi(c3, _fmt_montant(r["montant_emis"]), "montant émis", "neutral")
    kpi(c4, _fmt_nb(r["nb_cles"]), "clés IBAN × échéance", "neutral")
    kpi(c5, _fmt_nb(r["en_attente"]), "en attente EDF", "warn" if r["en_attente"] else "ok")
    kpi(c6, _fmt_nb(r["anomalies"]), "anomalies", "err" if r["anomalies"] else "ok")
    kpi(c7, _fmt_nb(r["a_investiguer"]), "écarts à investiguer", "err" if r["a_investiguer"] else "ok")


def _table(df, hauteur: int = 320) -> None:
    st.dataframe(df, hide_index=True, use_container_width=True, height=min(hauteur, 38 * len(df) + 40))


def render(kpi):
    cfg = pv.config_prelevements()
    racine = cfg["racine"]
    st.markdown("#### Prélèvements · Oracle (OUT_SEPA) → EDF CashCollection (état de réception, rejets internes)")
    if not racine.is_dir():
        st.caption(f"Racine introuvable : `{racine}` — `config.ini [prelevements] racine` "
                   "(dossiers ORACLE\\<AAAAMMJJ>, EDF, EDF\\REJETS alimentés à la main).")
        return

    dates = pv.dates_disponibles(racine)
    b1, b2, b3, b4 = st.columns([1.3, 0.8, 1.4, 3])
    reference = b1.date_input("Date de référence", value=dates[0] if dates else date.today(),
                              format="DD/MM/YYYY", key="pv_date")
    jours = b2.number_input("Profondeur (j)", min_value=1, max_value=90, value=cfg["jours"], key="pv_jours")
    if b3.button("▶ Lancer le rapprochement", type="primary", use_container_width=True, key="pv_lancer",
                 help=f"Racine : {racine}\nSI : {cfg['nom_si']}"):
        with st.spinner("Rapprochement Oracle ↔ EDF…"):
            try:
                res = pv.lancer(reference, dict(cfg, jours=int(jours)))
                nb_cles = sum(e["cles"] for e in res["par_statut"].values())
                st.session_state["pv_msg"] = (f"Rapprochement au {reference:%d/%m/%Y} terminé : "
                                              f"{res['statut_global']} · {nb_cles} clé(s) · "
                                              f"{res['nb_anomalies']} anomalie(s)")
            except Exception as e:  # noqa: BLE001 — l'outil externe peut échouer sur un fichier mal formé
                st.session_state["pv_msg"] = f"⚠ {type(e).__name__}: {e}"
    b4.caption("Dates déjà contrôlées : "
               + (", ".join(d.strftime("%d/%m") for d in dates[:8]) if dates else "aucune")
               + f" · SI = {cfg['nom_si']}")
    if st.session_state.get("pv_msg"):
        msg = st.session_state.pop("pv_msg")
        (st.error if msg.startswith("⚠") else st.success)(msg)

    rapport = pv.lire_rapport(racine, reference)
    if rapport is None:
        st.caption("Aucun rapport pour cette date de référence : cliquez sur **Lancer le rapprochement**.")
        return
    r = pv.resume(rapport)
    _tuiles(kpi, r)
    st.caption(f"Rapport généré le {rapport['genere_le']:%d/%m/%Y %H:%M} dans `{rapport['dossier']}` · "
               f"`{rapport['base']}`")

    res = rapport["resume"]
    if r["lignes_ko"]:
        st.error(f"{r['lignes_ko']} ligne(s) Oracle non conforme(s) : résultat non fiable "
                 "(voir l'onglet « Lignes rejetées » du classeur).")
    for a in res.get("avertissements", []):
        st.warning(a)
    if res.get("contexte"):
        st.caption(" · ".join(f"{k} : {v}" for k, v in res["contexte"].items()))

    just = rapport["justifications"]
    n_inv = r["a_investiguer"]
    with st.expander(f"{'🔴' if n_inv else '🟢'} Justification des écarts — {len(just)} cause(s), "
                     f"{n_inv} à investiguer", expanded=bool(n_inv)):
        if just.empty:
            st.caption("Aucun écart : toutes les clés sont rapprochées.")
        else:
            st.caption("Une ligne par cause : REJET (rejet interne apparié), NON_CONFIRME, INEXPLIQUE, "
                       "SANS_ORACLE. Les causes INEXPLIQUE et SANS_ORACLE sont à investiguer.")
            _table(just, 400)
            st.download_button("⬇ Justifications (CSV)",
                               just.to_csv(index=False, sep=";").encode("utf-8-sig"),
                               f"{rapport['base']}_justifications.csv", "text/csv", key="pv_csv_just")

    st.markdown("##### Clés par statut")
    for statut, df in pv.par_statut(rapport["rapprochement"]):
        icone = ("🔴" if statut in pv.STATUTS_ANOMALIE
                 else "🟠" if statut in pv.STATUTS_SIGNALES or statut == "EN_ATTENTE" else "🟢")
        nb = df["nb_oracle"].sum() or df["nb_edf"].sum()
        with st.expander(f"{icone} {pv.LIBELLES_STATUT[statut]} — {len(df)} clé(s), "
                         f"{_fmt_nb(nb)} prélèvement(s) · `{statut}`",
                         expanded=statut in pv.STATUTS_ANOMALIE):
            st.caption(pv.EXPLICATIONS[statut])
            _table(df.drop(columns=["statut"]))

    c1, c2 = st.columns(2)
    c1.download_button("⬇ Rapprochement complet (CSV)",
                       rapport["rapprochement"].to_csv(index=False, sep=";").encode("utf-8-sig"),
                       f"{rapport['base']}.csv", "text/csv", key="pv_csv")
    if rapport["xlsx"]:
        c2.download_button("⬇ Classeur Excel", rapport["xlsx"].read_bytes(), rapport["xlsx"].name,
                           "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", key="pv_xlsx")
