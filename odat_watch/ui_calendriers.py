"""Onglet Streamlit d'import et de consultation des calendriers de clôture."""
from __future__ import annotations

import pandas as pd
import streamlit as st

import calendar_import
from db import connect


def _preview_table(preview: calendar_import.WorkbookPreview) -> pd.DataFrame:
    return pd.DataFrame([{
        "période": e.period, "date": e.event_date, "J": e.reference_date or "",
        "J±N": e.offset or "", "moment": e.moment or "", "arrêté": e.arrete or "",
        "traitement": e.traitement or "", "restitution": e.restitution or "",
        "source": f"{e.source_sheet}!ligne {e.source_row}",
    } for e in preview.events])


def render() -> None:
    st.subheader("Calendriers de clôture")
    st.caption("Chargez un classeur trimestriel .xlsx : trois feuilles métier mensuelles sont requises. "
               "Le dépôt ne modifie rien avant validation explicite.")
    uploaded = st.file_uploader("Classeur trimestriel", type=["xlsx"], accept_multiple_files=False,
                                help="Les feuilles de synthèse et de jours fériés sont ignorées comme opérations.")
    if uploaded is not None:
        content = uploaded.getvalue()
        if len(content) > 15 * 1024 * 1024:
            st.error("Fichier trop volumineux (limite : 15 Mo).")
        else:
            try:
                preview = calendar_import.preview_workbook(content)
            except ValueError as exc:
                st.error(str(exc))
            else:
                months = sorted(preview.months)
                a, b, c = st.columns(3)
                a.metric("Mois reconnus", len(months))
                b.metric("Opérations datées", len(preview.events))
                c.metric("Feuilles annexes ignorées", len(preview.ignored_sheets))
                if preview.warnings:
                    for warning in preview.warnings:
                        st.warning(warning)
                if preview.ignored_sheets:
                    st.caption("Feuilles ignorées comme opérations : " + ", ".join(preview.ignored_sheets))
                data = _preview_table(preview)
                tabs = st.tabs(months)
                for tab, month in zip(tabs, months):
                    with tab:
                        st.dataframe(data[data["période"] == month], use_container_width=True, hide_index=True,
                                     height=420)
                valid = len(months) == 3
                if st.button("Enregistrer et activer ce calendrier", type="primary", disabled=not valid):
                    con = connect()
                    try:
                        _, message = calendar_import.import_workbook(con, uploaded.name, content, preview)
                    except ValueError as exc:
                        st.error(str(exc))
                    else:
                        st.success(message)
                        st.cache_data.clear()
                    finally:
                        con.close()

    st.divider()
    con = connect()
    rows = calendar_import.imports(con)
    if not rows:
        con.close()
        st.info("Aucun calendrier chargé. Les nuits ordinaires restent utilisables sans calendrier.")
        return
    _consulter(con, rows)
    con.close()

    st.markdown("#### Historique des imports")
    history = pd.DataFrame([dict(r) for r in rows])
    history["état"] = history["statut"].map({"active": "Actif", "inactive": "Historique"}).fillna(history["statut"])
    st.dataframe(history[["état", "nom_fichier", "importe_le", "nb_mois", "nb_operations", "message"]],
                 use_container_width=True, hide_index=True)


def _consulter(con, rows) -> None:
    """Contenu des calendriers enregistrés : une période comptable par onglet, prochains jalons en tête."""
    st.markdown("#### 📆 Consulter le calendrier")
    choix = {0: "Tous les calendriers actifs"}
    choix.update({int(r["id"]): f"{r['nom_fichier']} ({'actif' if r['statut'] == 'active' else 'historique'})" for r in rows})
    sel = st.selectbox("Calendrier", list(choix), format_func=choix.get, key="cal_sel")
    ev = calendar_import.evenements(con, None if sel == 0 else sel)
    if ev.empty:
        st.caption("Aucune opération dans ce calendrier.")
        return
    ev["date"] = pd.to_datetime(ev["date_operation"], errors="coerce")
    aujourdhui = pd.Timestamp.today().normalize()
    prochains = ev[(ev["date"] >= aujourdhui) & (ev["date"] <= aujourdhui + pd.Timedelta(days=14))]
    a, b, c = st.columns(3)
    a.metric("Opérations", len(ev))
    b.metric("Périodes", ev["periode_comptable"].nunique())
    c.metric("Jalons dans les 14 jours", len(prochains))
    if not prochains.empty:
        with st.expander(f"Prochains jalons ({len(prochains)})", expanded=True):
            for _, r in prochains.iterrows():
                st.write(f"**{r['date']:%a %d/%m}** · {r['decalage_j'] or ''} · {r['moment'] or ''} — {r['libellé']}")
    recherche = st.text_input("Rechercher une opération", "", key="cal_recherche",
                              placeholder="ex. paie, GL, stocks…").strip().lower()
    if recherche:
        ev = ev[ev["libellé"].str.lower().str.contains(recherche, regex=False)]
    colonnes = {"date_operation": "date", "decalage_j": "J±", "moment": "moment", "arrete": "arrêté",
                "traitement": "traitement", "restitution": "restitution", "source_sheet": "feuille"}
    periodes = sorted(ev["periode_comptable"].dropna().unique())
    if not periodes:
        st.caption("Aucune opération ne correspond.")
        return
    onglets = st.tabs([f"{p} ({int((ev['periode_comptable'] == p).sum())})" for p in periodes])
    for onglet, periode in zip(onglets, periodes):
        with onglet:
            t = ev[ev["periode_comptable"] == periode][list(colonnes)].rename(columns=colonnes)
            t.insert(1, "jour", pd.to_datetime(t["date"]).dt.strftime("%a"))
            st.dataframe(t, use_container_width=True, hide_index=True, height=min(600, 38 * len(t) + 40))
