"""Tableau et filtres de l'onglet Jobs CtrlM."""
from __future__ import annotations

from collections.abc import Iterable

import pandas as pd


STATUT_OK = "Ended OK"
ORDRE_STATUTS = {
    "Ended Not OK": 0,
    "Executing": 1,
    "Wait for Event": 2,
    "Ended OK": 3,
}
ICONES = {
    "Ended Not OK": "✖",
    "Executing": "▶",
    "Wait for Event": "⏸",
    "Ended OK": "✔",
}


def filtrer_jobs(
    jobs: pd.DataFrame,
    recherche: str = "",
    statuts: Iterable[str] = (),
    non_ok_uniquement: bool = False,
) -> pd.DataFrame:
    """Filtre les jobs par nom/description, statut et état non OK."""
    if jobs.empty:
        return jobs.copy()

    resultat = jobs.copy()
    statuts = set(statuts)
    recherche = recherche.strip()
    if recherche:
        noms = resultat["job_name"].fillna("").astype(str)
        descriptions = resultat.get("description", pd.Series("", index=resultat.index)).fillna("").astype(str)
        resultat = resultat[
            noms.str.contains(recherche, case=False, regex=False)
            | descriptions.str.contains(recherche, case=False, regex=False)
        ]
    if statuts:
        resultat = resultat[resultat["status"].isin(statuts)]
    if non_ok_uniquement:
        resultat = resultat[resultat["status"].fillna("").ne(STATUT_OK)]
    return resultat


def preparer_table(jobs: pd.DataFrame) -> pd.DataFrame:
    """Prépare les colonnes métier présentées dans le tableau Streamlit."""
    if jobs.empty:
        return pd.DataFrame()

    table = jobs.copy()
    for colonne in ("snap_time", "start_time", "end_time"):
        if colonne in table.columns:
            table[colonne] = pd.to_datetime(table[colonne], errors="coerce")
    table["état"] = table["status"].fillna("Inconnu").map(
        lambda statut: f"{ICONES.get(statut, '•')} {statut}"
    )
    table["_priorite"] = table["status"].map(ORDRE_STATUTS).fillna(4)
    tri = (["snap_time"] if "snap_time" in table.columns else []) + ["_priorite", "start_time", "job_name"]
    croissant = ([False] if "snap_time" in table.columns else []) + [True, False, True]
    table = table.sort_values(tri, ascending=croissant, na_position="last")

    colonnes = {
        "odate": "odate",
        "état": "statut",
        "job_name": "job",
        "group_name": "chaîne",
        "start_time": "début",
        "end_time": "fin",
        "run_time": "durée (s)",
        "rerun": "relances",
        "cyclic": "cyclique",
        "description": "description",
        "member": "script",
        "hostname": "hôte",
        "run_as": "utilisateur",
        "order_id": "order id",
    }
    disponibles = [colonne for colonne in colonnes if colonne in table.columns]
    return table[disponibles].rename(columns=colonnes).reset_index(drop=True)


def render(jobs: pd.DataFrame, application: str = "FIN-FINANCE") -> None:
    """Affiche les lignes de toutes les photos et les filtres nom/statut."""
    import streamlit as st

    st.markdown("#### Jobs Control-M")
    if jobs.empty:
        st.info("Aucun job Control-M chargé.")
        return

    statuts_disponibles = sorted(
        jobs["status"].dropna().astype(str).unique(),
        key=lambda statut: (ORDRE_STATUTS.get(statut, 99), statut),
    )

    col_recherche, col_statuts, col_non_ok = st.columns([2.2, 1.4, 1])
    recherche = col_recherche.text_input(
        "Recherche",
        placeholder="Nom du job ou description…",
        key="ctrlm_jobs_recherche",
    )
    statuts = col_statuts.multiselect(
        "Statut",
        statuts_disponibles,
        placeholder="Tous les statuts",
        key="ctrlm_jobs_statuts",
    )
    non_ok = col_non_ok.checkbox(
        "Non OK uniquement",
        key="ctrlm_jobs_non_ok",
        help="Exclut les jobs au statut Ended OK.",
    )

    selection = filtrer_jobs(jobs, recherche, statuts, non_ok)
    nb_photos = jobs["snapshot_id"].nunique() if "snapshot_id" in jobs.columns else 0
    st.caption(
        f"Application {application} · {len(selection)} ligne(s) affichée(s) sur {len(jobs)} "
        f"dans {nb_photos} photo(s)."
    )

    if selection.empty:
        st.info("Aucun job ne correspond aux filtres sélectionnés.")
        return

    table = preparer_table(selection)
    st.dataframe(
        table,
        use_container_width=True,
        hide_index=True,
        height=min(650, 38 * len(table) + 40),
        column_config={
            "job": st.column_config.TextColumn("job", width="medium"),
            "chaîne": st.column_config.TextColumn("chaîne", width="medium"),
            "début": st.column_config.DatetimeColumn("début", format="DD/MM/YYYY HH:mm"),
            "fin": st.column_config.DatetimeColumn("fin", format="DD/MM/YYYY HH:mm"),
            "durée (s)": st.column_config.NumberColumn("durée (s)", format="%d"),
            "description": st.column_config.TextColumn("description", width="large"),
            "script": st.column_config.TextColumn("script", width="medium"),
        },
    )
