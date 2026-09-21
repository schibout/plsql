"""Onglet Virements : choix de la journée (dossiers *_cible chargés à la main), lancement du contrôle
controleVirement, tuiles, synthèse et tables des doublons / écarts."""
from __future__ import annotations

import streamlit as st

import virements as vr


def _tuiles(kpi, r: dict) -> None:
    c1, c2, c3, c4, c5, c6 = st.columns(6)
    kpi(c1, "✅ OK" if r["ok"] else "❌ KO", "résultat global", "ok" if r["ok"] else "err")
    kpi(c2, f"{r['nb_envoyes']:,}".replace(",", " "), "virements envoyés", "neutral")
    kpi(c3, f"{r['montant_envoye']:,.0f} €".replace(",", " "), "montant envoyé", "neutral")
    kpi(c4, r["ko"], "doublons / forme bloquants", "err" if r["ko"] else "ok")
    kpi(c5, r["a_verifier"], "points à vérifier", "warn" if r["a_verifier"] else "ok")
    kpi(c6, "repris" if r["quartz"] else "non fourni", "retour trésorerie", "ok" if r["quartz"] else "warn")


def _table(df, hauteur: int = 320) -> None:
    st.dataframe(df, hide_index=True, use_container_width=True, height=min(hauteur, 38 * len(df) + 40))


def render(kpi):
    cfg = vr.config_virements()
    racine = cfg["racine"]
    st.markdown("#### Virements · Oracle → FIN01.VIREMENT → VIREMENT.EDF01 (ACK banque) → Quartz")
    dates = vr.dates_disponibles(racine) if racine.is_dir() else []
    if not dates:
        st.caption(f"Aucune journée : copiez les dossiers `JJMMAAAA_cible` (et `_source` si disponible, "
                   f"`copier_instances_virement.sh`) et le fichier Quartz dans `{racine}` — "
                   f"`config.ini [virements] racine`.")
        return

    b1, b2, b3 = st.columns([1.2, 1.4, 3])
    date = b1.selectbox("Journée", dates, format_func=vr.date_lisible, key="vir_date")
    if b2.button("▶ Lancer le contrôle", type="primary", use_container_width=True, key="vir_lancer",
                 help=f"Racine : {racine}\nHistorique : {cfg['historique_jours']} jour(s)"):
        with st.spinner("Contrôle des virements…"):
            try:
                res = vr.lancer(date, cfg)
                st.session_state["vir_msg"] = (f"Contrôle du {vr.date_lisible(date)} terminé : "
                                               f"{'OK' if res['ok'] else 'KO'} · {res['nb_instances']} instance(s)"
                                               + (" · cible seule" if res["cible_seul"] else ""))
            except Exception as e:  # noqa: BLE001 — l'outil externe peut échouer sur un fichier mal formé
                st.session_state["vir_msg"] = f"⚠ {type(e).__name__}: {e}"
    source = vr.source_presente(racine, date)
    quartz = vr.fichier_quartz(cfg, date)
    b3.caption(f"Dossier source : {'présent' if source else 'absent → contrôle sur la cible seule'} · "
               f"Retour Quartz : {quartz.name if quartz else 'absent (niveau 3 ignoré)'}")
    if st.session_state.get("vir_msg"):
        msg = st.session_state.pop("vir_msg")
        (st.error if msg.startswith("⚠") else st.success)(msg)

    rapport = vr.lire_rapport(racine / f"rapport_{date}")
    if rapport is None:
        st.caption("Cette journée n'a pas encore été contrôlée : cliquez sur **Lancer le contrôle**.")
        return
    r = vr.resume(rapport)
    _tuiles(kpi, r)
    st.caption(f"Rapport généré le {rapport['genere_le']:%d/%m/%Y %H:%M} dans `{rapport['dossier']}`"
               + (" · contrôle sur la cible seule" if r["cible_seul"] else ""))

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

    with st.expander("Synthèse complète (synthese.md)"):
        st.markdown(rapport["synthese"])
        st.download_button("⬇ Télécharger synthese.md", rapport["synthese"].encode("utf-8"),
                           f"synthese_virements_{date}.md", "text/markdown", key="vir_md")
