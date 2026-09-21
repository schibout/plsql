"""Recherche multi de l'onglet Oracle."""
import pandas as pd

import ui_oracle


def _demandes():
    return pd.DataFrame([
        {"request_id": 1, "job_name": "JOB_A", "program_short": "PROG_1", "état": "✔ Normal"},
        {"request_id": 2, "job_name": "JOB_B", "program_short": "PROG_2", "état": "✖ Erreur"},
        {"request_id": 3, "job_name": "JOB_C", "program_short": "PROG_1", "état": "▶ En cours"},
    ])


def test_recherche_multi_accepte_plusieurs_jobs():
    resultat = ui_oracle._filtre_multi(_demandes(), jobs=["JOB_A", "JOB_C"])
    assert list(resultat["request_id"]) == [1, 3]


def test_recherche_multi_cumule_programme_et_statut():
    resultat = ui_oracle._filtre_multi(
        _demandes(),
        programmes=["PROG_1", "PROG_2"],
        statuts=["✖ Erreur"],
    )
    assert list(resultat["request_id"]) == [2]
