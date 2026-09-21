"""Onglet Virements : choix de la journée (dossiers *_cible chargés à la main), lancement du contrôle
controleVirement, tuiles, synthèse et tables des doublons / écarts."""
from __future__ import annotations
from pathlib import Path

import pandas as pd
import streamlit as st

import mail
import rapport_virements as rp
import virements as vr
import virements_import as vi
from db import connect


def _tuiles(kpi, r: dict) -> None:
    c1, c2, c3, c4, c5, c6, c7 = st.columns(7)
    kpi(c1, "✅ OK" if r["ok"] else "❌ KO", "résultat global", "ok" if r["ok"] else "err")
    kpi(c2, f"{r['nb_envoyes']:,}".replace(",", " "), "virements envoyés", "neutral")
    kpi(c3, f"{r['montant_envoye']:,.0f} €".replace(",", " "), "montant envoyé", "neutral")
    kpi(c4, r["ko"], "doublons / forme bloquants", "err" if r["ko"] else "ok")
    kpi(c5, r["a_verifier"], "points à vérifier", "warn" if r["a_verifier"] else "ok")
    kpi(c6, "repris" if r["quartz"] else "non fourni", "retour trésorerie", "ok" if r["quartz"] else "warn")
    kpi(c7, r["nb_rejets"], "rejets bancaires du jour", "warn" if r["nb_rejets"] else "ok")


def _table(df, hauteur: int = 320) -> None:
    st.dataframe(df, hide_index=True, use_container_width=True, height=min(hauteur, 38 * len(df) + 40))


def render(kpi):
    cfg = vr.config_virements()
    racine = cfg["racine"]
    st.markdown("#### Virements · Oracle → FIN01.VIREMENT → VIREMENT.EDF01 (ACK banque) → Quartz")
    _import(cfg)
    dates = vr.dates_disponibles(racine) if racine.is_dir() else []
    if not dates:
        st.caption(f"Aucune journée : copiez les dossiers `JJMMAAAA` (un sous-dossier par instance : SOURCE, "
                   f"TALEND, TARGET) et le fichier Quartz dans `{racine}` — `config.ini [virements] racine`.")
        return

    b1, b2, b3 = st.columns([1.2, 1.4, 3])
    date = b1.selectbox("Journée", dates, format_func=vr.date_lisible, key="vir_date")
    if b2.button("▶ Lancer le contrôle", type="primary", use_container_width=True, key="vir_lancer",
                 help=f"Racine : {racine}\nHistorique : {cfg['historique_jours']} jour(s)"):
        with st.spinner("Contrôle des virements…"):
            try:
                res = vr.lancer(date, cfg)
                con = connect()
                try:
                    st.session_state["vir_histo_id"] = vr.enregistrer(date, res, con)
                finally:
                    con.close()
                st.session_state["vir_msg"] = (f"Contrôle du {vr.date_lisible(date)} terminé : "
                                               f"{'OK' if res['ok'] else 'KO'} · {res['nb_instances']} instance(s) · "
                                               f"enregistré en base")
            except Exception as e:  # noqa: BLE001 — l'outil externe peut échouer sur un fichier mal formé
                st.session_state["vir_msg"] = f"⚠ {type(e).__name__}: {e}"
    quartz = vr.fichier_quartz(cfg, date)
    b3.caption(f"{vr.nb_instances(racine, date)} instance(s) dans `{date}` · "
               f"Retour Quartz : {quartz.name if quartz else 'absent (niveau 3 ignoré)'}"
               + (" · DK en euros fournis (dossier _source)" if vr.source_presente(racine, date) else ""))
    if st.session_state.get("vir_msg"):
        msg = st.session_state.pop("vir_msg")
        (st.error if msg.startswith("⚠") else st.success)(msg)

    rapport = vr.lire_rapport(racine / f"rapport_{date}")
    if rapport is None:
        st.caption("Cette journée n'a pas encore été contrôlée : cliquez sur **Lancer le contrôle**.")
        return
    r = vr.resume(rapport)
    _tuiles(kpi, r)
    st.caption(f"Rapport généré le {rapport['genere_le']:%d/%m/%Y %H:%M} dans `{rapport['dossier']}`")

    st.markdown(rapport["synthese_simple"] or rapport["synthese"].split("---")[1])

    st.markdown("##### Doublons")
    doublons = [(cle, nom, lib) for cle, nom, lib in vr.CSV_RAPPORT if cle in vr.CLES_DOUBLONS and not rapport[cle].empty]
    if not doublons:
        st.success("Aucun doublon : envois identiques, chevauchements, virements multiples, intra-envoi, historique, sources.")
    for cle, nom, lib in doublons:
        df = rapport[cle]
        n_ko = int((df["gravite"] == "KO").sum()) if "gravite" in df.columns else len(df)
        with st.expander(f"{'🔴' if n_ko else '🟠'} {lib} — {len(df)} ligne(s)"
                         f"{f', {n_ko} bloquante(s)' if 'gravite' in df.columns else ''} · `{nom}`", expanded=True):
            _table(df)
    if not rapport["doublons_virements"].empty:
        with st.expander(f"Liste pour la banque — {len(rapport['doublons_virements'])} virement(s) des envois en double"):
            _table(rapport["doublons_virements"])
            st.download_button("⬇ Exporter (CSV)", rapport["doublons_virements"].to_csv(index=False, sep=";").encode("utf-8-sig"),
                               f"doublons_virements_{date}.csv", "text/csv", key="vir_csv_doublons")

    sanite = rapport["sanite"]
    with st.expander(f"Contrôles de forme — {len(sanite)} constat(s)", expanded=not sanite.empty):
        if sanite.empty:
            st.caption("Signature PGP, compte payeur, dates, pieds de fichier, code retour Talend, montants, IBAN, BIC : rien à signaler.")
        else:
            _table(sanite)

    with st.expander("Détail des niveaux 0 à 3 (fichiers, totaux, virement par virement, Quartz)"):
        for cle in ("fichiers", "totaux_source", "totaux_edf", "lignes", "quartz"):
            lib = next(l for c, _, l in vr.CSV_RAPPORT if c == cle)
            df = rapport[cle]
            st.markdown(f"**{lib}** — {len(df)} ligne(s)")
            if df.empty:
                st.caption("vide (aucun écart)" if cle in ("lignes", "quartz") else "vide")
            else:
                _table(df, 300)

    rejets = rapport["rejets"]
    with st.expander(f"Rejets bancaires du jour — {len(rejets)} virement(s)"
                     + (f" pour {r['montant_rejets']:,.2f} €".replace(",", " ").replace(".", ",") if len(rejets) else ""),
                     expanded=not rejets.empty):
        if rejets.empty:
            st.caption("Aucun rejet de virement reçu de la banque ce jour (fichier `REJETS/JJMMAAAA_*.xls` absent ou vide).")
        else:
            _table(rejets)
            st.download_button("⬇ Exporter (CSV)", rejets.to_csv(index=False, sep=";").encode("utf-8-sig"),
                               f"rejets_virements_{date}.csv", "text/csv", key="vir_csv_rejets")

    with st.expander("Synthèse complète (synthese.md)"):
        st.markdown(rapport["synthese"])
        st.download_button("⬇ Télécharger synthese.md", rapport["synthese"].encode("utf-8"),
                           f"synthese_virements_{date}.md", "text/markdown", key="vir_md")

    _rapport_et_mail(rapport, date)
    _historique()


def _import(cfg: dict) -> None:
    """Dépôt import_virement : instances, exports Quartz (EDF/) et rejets (REJET/) déposés en vrac, rangés en un clic."""
    depot = cfg["depot"]
    elements = vi.scanner(depot, cfg["racine"]) if depot.is_dir() else []
    a_importer = [e for e in elements if e.etat == "à importer"]
    c1, c2 = st.columns([1.4, 3])
    if c1.button(f"📥 Importer {len(a_importer)} élément(s) déposé(s)" if a_importer else "📥 Importer depuis le dépôt",
                 key="vir_import", use_container_width=True, disabled=not a_importer,
                 help=f"Dépôt : {depot}\nInstances (dossier uuid avec SOURCE, TALEND, TARGET), exports Quartz (EDF/) "
                      "et rejets de virements (REJET/), datés par leur nom ou leur contenu."):
        con = connect()
        try:
            bilan = vi.importer(depot, cfg["racine"], con)
        finally:
            con.close()
        st.session_state["vir_import_msg"] = bilan.message
        st.rerun()
    if not depot.is_dir():
        c2.caption(f"Dépôt `{depot}` absent : créez-le et déposez-y les instances Talend et les exports Quartz "
                   "(`config.ini [virements] depot`).")
    elif not elements:
        c2.caption(f"Dépôt `{depot.name}` vide. Déposez-y les instances (dossier uuid), les exports Quartz (EDF/) et les rejets (REJET/), sans les trier.")
    else:
        restes = [e for e in elements if e.etat != "à importer"]
        c2.caption(f"Dépôt `{depot.name}` : {len(a_importer)} à importer"
                   + (", " + ", ".join(f"{e.chemin.name} ({e.etat})" for e in restes) if restes else ""))
    if st.session_state.get("vir_import_msg"):
        st.success(st.session_state.pop("vir_import_msg"))


def _rapport_et_mail(rapport: dict, date: str) -> None:
    st.markdown("##### Rapport et envoi")
    c0, c1 = st.columns([1, 2])
    if c0.button("📄 Générer le rapport HTML", use_container_width=True, key="vir_rapport",
                 help="Synthèse en haut (résultat, chiffres, points d'attention), tableaux de détail en bas."):
        try:
            chemin = rp.ecrire(rapport, date, rp.DOSSIER_RAPPORTS)
            st.session_state["vir_rapport_html"] = str(chemin)
            if st.session_state.get("vir_histo_id"):
                con = connect()
                try:
                    vr.maj_fichier_rapport(st.session_state["vir_histo_id"], str(chemin), con)
                finally:
                    con.close()
        except OSError as e:
            st.error(f"Écriture du rapport impossible : {e}")
    chemin = st.session_state.get("vir_rapport_html")
    if not (chemin and Path(chemin).is_file() and f"_{date}_" in Path(chemin).name):
        c1.caption("Générer le rapport pour obtenir le fichier HTML et le mail prêt à envoyer.")
        return
    d1, d2, d3 = st.columns(3)
    d1.download_button("⬇ Rapport HTML", Path(chemin).read_bytes(), Path(chemin).name, "text/html",
                       key="vir_html", use_container_width=True)
    cfg_mail = mail.config_mail()
    dest = mail.destinataires(cfg_mail, "virements")
    texte = rp.texte_court(rapport, date)
    sujet = texte.splitlines()[0]
    pieces = [Path(chemin)] + [rapport["dossier"] / nom for cle, nom, _ in vr.CSV_RAPPORT
                               if cle in (*vr.CLES_DOUBLONS, "doublons_virements", "sanite") and not rapport[cle].empty]
    msg = mail.composer(sujet, Path(chemin).read_text(encoding="utf-8"), texte, pieces,
                        expediteur=cfg_mail["expediteur"], destinataires=dest)
    d2.download_button("✉ Mail prêt à envoyer (.eml)", mail.eml(msg), mail.nom_fichier("Virements", date),
                       "message/rfc822", key="vir_eml", use_container_width=True,
                       help="S'ouvre dans Outlook en mode composition : rapport HTML dans le corps, CSV des écarts en pièces jointes.")
    if cfg_mail["smtp_hote"] and dest:
        if d3.button(f"📤 Envoyer à {len(dest)} destinataire(s)", key="vir_envoyer", use_container_width=True):
            try:
                st.success(mail.envoyer(msg, cfg_mail))
            except Exception as e:  # noqa: BLE001 — relais SMTP injoignable, refus, etc.
                st.error(f"Envoi impossible : {e}")
    else:
        d3.caption("Envoi direct : renseigner `[mail] smtp_hote` et `destinataires_virements` dans config.ini.")
    with st.expander("✉ Texte court à coller dans un mail ou Teams"):
        st.code(texte, language=None)


def _historique() -> None:
    con = connect()
    try:
        h = vr.historique(60, con)
    finally:
        con.close()
    with st.expander(f"Historique des contrôles — {len(h)} journée(s) sur 60 jours"):
        if h.empty:
            st.caption("Aucun contrôle enregistré : chaque lancement depuis cet onglet alimente vir_histo, vir_imports et vir_envois.")
            return
        h = h.copy()
        h["résultat"] = h["ok"].map({1: "✅ OK", 0: "❌ KO"})
        h["journée"] = pd.to_datetime(h["date_ctrl"]).dt.strftime("%d/%m/%Y")
        h["montant_envoye"] = h["montant_envoye"].map(lambda v: f"{float(v or 0):,.2f} €".replace(",", " ").replace(".", ","))
        st.dataframe(h[["journée", "résultat", "nb_instances", "nb_envoyes", "montant_envoye", "ko", "a_verifier", "ecarts", "executed_at"]]
                     .rename(columns={"nb_instances": "instances", "nb_envoyes": "virements", "montant_envoye": "montant",
                                      "ko": "bloquants", "a_verifier": "à vérifier", "ecarts": "écarts", "executed_at": "contrôlé le"}),
                     hide_index=True, use_container_width=True)
