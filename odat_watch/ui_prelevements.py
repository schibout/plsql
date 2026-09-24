"""Onglet Prélèvements : date de référence, lancement du rapprochement clé métier (outil
CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS), tuiles, justification des écarts, clés par statut, téléchargements."""
from __future__ import annotations
from datetime import date
from pathlib import Path

import streamlit as st

import pandas as pd

import mail
import prelevements as pv
import rapport_prelevements as rp
from db import connect


def _fmt_nb(n) -> str:
    return f"{int(n):,}".replace(",", " ")


def _fmt_montant(m) -> str:
    return f"{float(m):,.2f} €".replace(",", " ").replace(".", ",")


def _tuiles(kpi, r: dict) -> None:
    c1, c2, c3, c4, c5, c6, c7, c8 = st.columns(8)
    g = r["statut_global"]
    kpi(c1, pv.LIBELLES_GLOBAL.get(g, g), "résultat global", pv.TON_GLOBAL.get(g, "neutral"))
    kpi(c2, _fmt_nb(r["nb_emis"]), "prélèvements émis", "neutral")
    kpi(c3, _fmt_montant(r["montant_emis"]), "montant émis", "neutral")
    kpi(c4, _fmt_nb(r["nb_cles"]), "clés IBAN × échéance", "neutral")
    kpi(c5, _fmt_nb(r["en_attente"]), "en attente EDF", "warn" if r["en_attente"] else "ok")
    kpi(c6, _fmt_nb(r["anomalies"]), "anomalies", "err" if r["anomalies"] else "ok")
    kpi(c7, _fmt_nb(r["a_investiguer"]), "écarts à investiguer", "err" if r["a_investiguer"] else "ok")
    kpi(c8, _fmt_nb(r["doublons"]), "émis en double", "err" if r["doublons"] else "ok")


def _table(df, hauteur: int = 320) -> None:
    st.dataframe(df, hide_index=True, use_container_width=True, height=min(hauteur, 38 * len(df) + 40))


def render(kpi):
    cfg = pv.config_prelevements()
    racine = cfg["racine"]
    st.markdown("#### Prélèvements · Oracle (OUT_SEPA) → EDF CashCollection (état de réception, rejets internes)")
    if not racine.is_dir():
        st.caption(f"Dossier des données introuvable : `{racine}` — `config.ini [prelevements] racine` "
                   "(y déposer ORACLE\\<AAAAMMJJ>, EDF et REJETS ; les rapports s'écrivent dans RAPPORTS — "
                   "sous-dossiers réglables par `dossier_oracle`, `dossier_edf`, `dossier_rejets`, `dossier_rapports`).")
        return

    dates = pv.dates_disponibles(cfg["rapports"])
    b1, b2, b3, b4 = st.columns([1.3, 0.8, 1.4, 3])
    reference = b1.date_input("Date de référence", value=date.today(), format="DD/MM/YYYY", key="pv_date",
                              help="Défaut : aujourd'hui. Choisir une date déjà contrôlée pour revoir son rapport.")
    jours = b2.number_input("Profondeur (j)", min_value=1, max_value=90, value=cfg["jours"], key="pv_jours")
    if b3.button("▶ Lancer le rapprochement", type="primary", use_container_width=True, key="pv_lancer",
                 help=f"Racine : {racine}\nSI : {cfg['nom_si']}"):
        with st.spinner("Rapprochement Oracle ↔ EDF…"):
            try:
                res = pv.lancer(reference, dict(cfg, jours=int(jours)))
                nb_cles = sum(e["cles"] for e in res["par_statut"].values())
                con = connect()
                try:
                    st.session_state["pv_histo_id"] = pv.enregistrer(res, con)
                finally:
                    con.close()
                st.session_state["pv_msg"] = (f"Rapprochement au {reference:%d/%m/%Y} terminé : "
                                              f"{res['statut_global']} · {nb_cles} clé(s) · "
                                              f"{res['nb_anomalies']} anomalie(s) · {len(res.get('edf', []))} ligne(s) EDF et "
                                              f"{len(res.get('rejets', []))} rejet(s) en base · `{res['base']}`")
                st.session_state["pv_journal"] = res["journal"]
            except Exception as e:  # noqa: BLE001 — l'outil externe peut échouer sur un fichier mal formé
                st.session_state["pv_msg"] = f"⚠ {type(e).__name__}: {e}"
                st.session_state["pv_journal"] = ""
    b4.caption("Dates déjà contrôlées : "
               + (", ".join(d.strftime("%d/%m") for d in dates[:8]) if dates else "aucune")
               + f" · SI = {cfg['nom_si']}")
    if st.session_state.get("pv_msg"):
        msg = st.session_state.pop("pv_msg")
        (st.error if msg.startswith("⚠") else st.success)(msg)
        journal = st.session_state.pop("pv_journal", "")
        if journal:
            with st.expander("Journal d'exécution (fichiers lus, avertissements)"):
                st.code(journal, language=None)

    rapport = pv.lire_rapport(cfg["rapports"], reference)
    if rapport is None:
        st.caption("Aucun rapport pour cette date de référence : cliquez sur **Lancer le rapprochement**.")
        _tresorerie(cfg, reference)
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

    dbl = rapport["doublons"]
    n_dbl = r["doublons"]
    with st.expander(f"{'🔴' if n_dbl else '🟢'} Prélèvements émis en double — {n_dbl} doublon(s)",
                     expanded=bool(n_dbl)):
        if dbl.empty:
            st.caption("Aucun prélèvement émis en double : aucune ligne n'est partie deux fois à l'identique.")
        else:
            st.caption("DOUBLON : ligne entière identique, caractère pour caractère (société, débiteur, IBAN, échéance, "
                       "montant, référence…), émise plusieurs fois : lot rejoué, le débiteur serait prélevé deux fois "
                       "→ anomalie. Des lignes qui diffèrent d'un seul caractère ne sont pas des doublons.")
            _table(dbl, 360)
            st.download_button("⬇ Doublons (CSV)", dbl.to_csv(index=False, sep=";").encode("utf-8-sig"),
                               f"{rapport['base']}_doublons.csv", "text/csv", key="pv_csv_dbl")

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

    st.markdown("##### Rapport et envoi")
    c0, c1, c2 = st.columns(3)
    if c0.button("📄 Générer le rapport HTML", use_container_width=True, key="pv_rapport",
                 help="Synthèse en haut (statut, chiffres, à faire), tableaux de détail en bas. Même charte que le rapport du matin."):
        try:
            st.session_state["pv_rapport_html"] = str(rp.ecrire(rapport, cfg["rapports"]))
            if st.session_state.get("pv_histo_id"):
                con = connect()
                try:
                    pv.maj_fichier_rapport(st.session_state["pv_histo_id"], st.session_state["pv_rapport_html"], con)
                finally:
                    con.close()
        except OSError as e:
            st.error(f"Écriture du rapport impossible : {e}")
    c1.download_button("⬇ Rapprochement complet (CSV)",
                       rapport["rapprochement"].to_csv(index=False, sep=";").encode("utf-8-sig"),
                       f"{rapport['base']}.csv", "text/csv", key="pv_csv", use_container_width=True)
    if rapport["xlsx"]:
        c2.download_button("⬇ Classeur Excel", rapport["xlsx"].read_bytes(), rapport["xlsx"].name,
                           "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", key="pv_xlsx",
                           use_container_width=True)
    chemin = st.session_state.get("pv_rapport_html")
    if chemin and Path(chemin).is_file() and rapport["base"][len(pv.PREFIXE):len(pv.PREFIXE) + 8] in Path(chemin).name:
        d1, d2, d3 = st.columns(3)
        d1.download_button("⬇ Rapport HTML", Path(chemin).read_bytes(), Path(chemin).name, "text/html",
                           key="pv_html", use_container_width=True)
        cfg_mail = mail.config_mail()
        dest = mail.destinataires(cfg_mail, "prelevements")
        texte = rp.texte_court(rapport)
        pieces = [Path(chemin)] + ([rapport["xlsx"]] if rapport["xlsx"] else []) + [
            rapport["dossier"] / f"{rapport['base']}{suffixe}" for suffixe in ("_justifications.csv", "_doublons.csv")]
        msg = mail.composer(texte.splitlines()[0], Path(chemin).read_text(encoding="utf-8"), texte, pieces,
                            expediteur=cfg_mail["expediteur"], destinataires=dest)
        d2.download_button("✉ Mail prêt à envoyer (.eml)", mail.eml(msg),
                           mail.nom_fichier("Prelevements", rapport["base"][len(pv.PREFIXE):len(pv.PREFIXE) + 8]),
                           "message/rfc822", key="pv_eml", use_container_width=True,
                           help="S'ouvre dans Outlook en mode composition : rapport HTML dans le corps, classeur et CSV en pièces jointes.")
        if cfg_mail["smtp_hote"] and dest:
            if d3.button(f"📤 Envoyer à {len(dest)} destinataire(s)", key="pv_envoyer", use_container_width=True):
                try:
                    st.success(mail.envoyer(msg, cfg_mail))
                except Exception as e:  # noqa: BLE001
                    st.error(f"Envoi impossible : {e}")
        else:
            d3.caption("Envoi direct : renseigner `[mail] smtp_hote` et `destinataires_prelevements` dans config.ini.")
    with st.expander("✉ Texte court à coller dans un mail ou Teams"):
        st.code(rp.texte_court(rapport), language=None)

    _tresorerie(cfg, reference)


def _eur(v) -> str:
    return f"{float(v or 0):,.2f} €".replace(",", " ").replace(".", ",")


def _tresorerie(cfg: dict, reference: date) -> None:
    """Mémoire persistante des états EDF et des rejets (base), indépendante des fichiers du dossier."""
    con = connect()
    try:
        t = pv.tresorerie(con, jours=90, reference=reference)
        h = pv.historique(60, con)
        absents = pv.fichiers_absents(con, cfg["edf"], cfg["rejets"])
    finally:
        con.close()
    chrono = t["chronologie"]
    st.markdown("##### Trésorerie EDF (base, 90 jours)")
    if chrono.empty:
        st.caption("Aucun état EDF en base : chaque lancement enregistre les états de réception et les rejets lus "
                   "(pv_fichiers, pv_edf, pv_rejets).")
    else:
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("États EDF reçus", len(chrono))
        c2.metric("Prélèvements confirmés", f"{int(chrono['nb'].sum()):,}".replace(",", " "))
        c3.metric("Montant confirmé", _eur(chrono["montant"].sum()))
        c4.metric("Rejets", len(t["rejets"]), delta=f"{len(t['recidives'])} mandat(s) récidiviste(s)" if not t["recidives"].empty else None,
                  delta_color="inverse")
        if t["jours_sans_etat"]:
            st.warning("Jours ouvrés sans état EDF : " + ", ".join(j.strftime("%d/%m") for j in t["jours_sans_etat"][-15:])
                       + (" …" if len(t["jours_sans_etat"]) > 15 else "")
                       + " — vérifier la réception du mail « Synthèse quotidienne des prélèvements ».")
        if absents:
            st.info(f"{len(absents)} fichier(s) connu(s) en base mais absent(s) du dossier (purgés) : la base en garde le contenu. "
                    f"Ex. {absents[0]}")
        with st.expander(f"Chronologie des états reçus — {len(chrono)} fichier(s)"):
            df = chrono.copy()
            df["montant"] = df["montant"].map(_eur)
            st.dataframe(df.rename(columns={"date_fichier": "reçu le", "nb": "prélèvements", "cles": "clés", "rejets": "rejets du jour"}),
                         hide_index=True, use_container_width=True, height=min(400, 38 * len(df) + 40))
        with st.expander(f"Rejets internes — {len(t['rejets'])} sur 90 jours"
                         + (f", {len(t['recidives'])} mandat(s) rejeté(s) plusieurs fois" if not t["recidives"].empty else ""),
                         expanded=not t["recidives"].empty):
            if not t["recidives"].empty:
                st.markdown("**Mandats rejetés plusieurs fois** — à signaler au métier (mandat ou débiteur à revoir)")
                st.dataframe(t["recidives"], hide_index=True, use_container_width=True)
            if t["rejets"].empty:
                st.caption("Aucun rejet sur la période.")
            else:
                df = t["rejets"].copy()
                df["appariee"] = df["appariee"].map({1: "oui", 0: "autre SI"})
                st.dataframe(df.rename(columns={"appariee": "émission Oracle connue"}), hide_index=True,
                             use_container_width=True, height=min(400, 38 * len(df) + 40))
    with st.expander(f"Historique des rapprochements — {len(h)} date(s) sur 60 jours"):
        if h.empty:
            st.caption("Aucun rapprochement enregistré.")
        else:
            df = h.copy()
            df["montant_emis"] = df["montant_emis"].map(_eur)
            df["reference"] = pd.to_datetime(df["reference"]).dt.strftime("%d/%m/%Y")
            st.dataframe(df[["reference", "statut_global", "nb_cles", "nb_emis", "montant_emis", "en_attente", "anomalies",
                             "a_investiguer", "doublons", "avertissements", "executed_at"]]
                         .rename(columns={"reference": "référence", "statut_global": "statut", "nb_cles": "clés", "nb_emis": "émis",
                                          "montant_emis": "montant", "en_attente": "en attente", "a_investiguer": "à investiguer",
                                          "executed_at": "lancé le"}),
                         hide_index=True, use_container_width=True)
