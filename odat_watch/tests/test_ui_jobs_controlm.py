"""Filtres et présentation de l'onglet Jobs CtrlM."""
import pandas as pd
from streamlit.testing.v1 import AppTest

import ui_jobs_controlm as ui


def _jobs():
    return pd.DataFrame([
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "job_name": "JOB_OK", "status": "Ended OK", "start_time": "2026-09-21 08:00:00"},
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "job_name": "JOB_KO", "status": "Ended Not OK", "start_time": "2026-09-21 08:05:00"},
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "job_name": "JOB_RUN", "status": "Executing", "start_time": "2026-09-21 08:10:00"},
    ])


def test_filtre_plusieurs_noms_et_statuts():
    resultat = ui.filtrer_jobs(
        _jobs(),
        noms=["JOB_OK", "JOB_KO"],
        statuts=["Ended OK", "Ended Not OK"],
    )
    assert list(resultat["job_name"]) == ["JOB_OK", "JOB_KO"]


def test_filtre_non_ok_exclut_uniquement_ended_ok():
    resultat = ui.filtrer_jobs(_jobs(), non_ok_uniquement=True)
    assert list(resultat["job_name"]) == ["JOB_KO", "JOB_RUN"]


def test_table_place_les_anomalies_avant_les_jobs_ok():
    table = ui.preparer_table(_jobs())
    assert list(table["job"]) == ["JOB_KO", "JOB_RUN", "JOB_OK"]
    assert table.loc[0, "statut"] == "✖ Ended Not OK"


def _script():
    import pandas as pd
    import ui_jobs_controlm

    jobs = pd.DataFrame([
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "job_name": "JOB_OK", "status": "Ended OK", "start_time": "2026-09-21 08:00:00"},
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "job_name": "JOB_KO", "status": "Ended Not OK", "start_time": "2026-09-21 08:05:00"},
    ])
    ui_jobs_controlm.render(jobs)


def test_rendu_permet_la_selection_multiple_et_le_filtre_non_ok():
    at = AppTest.from_function(_script, default_timeout=30)
    at.run()
    assert not at.exception
    assert at.multiselect(key="ctrlm_jobs_noms").label == "Nom du job"
    assert at.multiselect(key="ctrlm_jobs_statuts").label == "Statut"

    at.multiselect(key="ctrlm_jobs_noms").set_value(["JOB_OK", "JOB_KO"])
    at.checkbox(key="ctrlm_jobs_non_ok").check().run()
    assert list(at.dataframe[0].value["job"]) == ["JOB_KO"]
