"""Filtres et présentation de l'onglet Jobs CtrlM."""
import pandas as pd
from streamlit.testing.v1 import AppTest

import ui_jobs_controlm as ui


def _jobs():
    return pd.DataFrame([
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "application": "FIN-FINANCE", "job_name": "JOB_OK", "description": "Import des factures", "status": "Ended OK", "start_time": "2026-09-21 08:00:00"},
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "application": "FIN-FINANCE", "job_name": "JOB_KO", "description": "Export bancaire", "status": "Ended Not OK", "start_time": "2026-09-21 08:05:00"},
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "application": "FIN-FINANCE", "job_name": "JOB_RUN", "description": None, "status": "Executing", "start_time": "2026-09-21 08:10:00"},
    ])


def test_recherche_sur_nom_du_job_et_description_sans_casse():
    assert list(ui.filtrer_jobs(_jobs(), recherche="job_ko")["job_name"]) == ["JOB_KO"]
    assert list(ui.filtrer_jobs(_jobs(), recherche="FACTURES")["job_name"]) == ["JOB_OK"]


def test_recherche_se_combine_avec_le_statut():
    resultat = ui.filtrer_jobs(_jobs(), recherche="job", statuts=["Ended Not OK"])
    assert list(resultat["job_name"]) == ["JOB_KO"]


def test_filtre_non_ok_exclut_uniquement_ended_ok():
    resultat = ui.filtrer_jobs(_jobs(), non_ok_uniquement=True)
    assert list(resultat["job_name"]) == ["JOB_KO", "JOB_RUN"]


def test_table_place_les_anomalies_avant_les_jobs_ok():
    table = ui.preparer_table(_jobs())
    assert list(table["job"]) == ["JOB_KO", "JOB_RUN", "JOB_OK"]
    assert table.loc[0, "statut"] == "✖ Ended Not OK"


def test_table_masque_les_trois_premieres_colonnes_techniques():
    table = ui.preparer_table(_jobs())
    assert "photo id" not in table.columns
    assert "photo" not in table.columns
    assert "application" not in table.columns


def _script():
    import pandas as pd
    import ui_jobs_controlm

    jobs = pd.DataFrame([
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "job_name": "JOB_OK", "description": "Import des factures", "status": "Ended OK", "start_time": "2026-09-21 08:00:00"},
        {"snapshot_id": 1, "snap_time": "2026-09-21 08:15:00", "job_name": "JOB_KO", "description": "Export bancaire", "status": "Ended Not OK", "start_time": "2026-09-21 08:05:00"},
    ])
    ui_jobs_controlm.render(jobs)


def test_rendu_permet_la_recherche_et_le_filtre_non_ok():
    at = AppTest.from_function(_script, default_timeout=30)
    at.run()
    assert not at.exception
    assert at.text_input(key="ctrlm_jobs_recherche").label == "Recherche"
    assert at.multiselect(key="ctrlm_jobs_statuts").label == "Statut"

    at.text_input(key="ctrlm_jobs_recherche").set_value("bancaire")
    at.checkbox(key="ctrlm_jobs_non_ok").check().run()
    assert list(at.dataframe[0].value["job"]) == ["JOB_KO"]


def test_non_lances_masques_par_defaut_sauf_si_demandes():
    jobs = pd.concat([_jobs(), pd.DataFrame([{"snapshot_id": 1, "job_name": "JOB_JAMAIS", "status": ui.NON_LANCE}])])
    assert "JOB_JAMAIS" not in list(ui.filtrer_jobs(jobs, non_lances=False)["job_name"])
    assert "JOB_JAMAIS" in list(ui.filtrer_jobs(jobs, non_lances=True)["job_name"])
    assert "JOB_JAMAIS" in list(ui.filtrer_jobs(jobs, statuts=[ui.NON_LANCE], non_lances=False)["job_name"])
    assert "JOB_JAMAIS" not in list(ui.filtrer_jobs(jobs, non_ok_uniquement=True)["job_name"])
