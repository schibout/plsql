"""Recherche multi de l'onglet Oracle."""
import pandas as pd

import db
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


def test_chargement_exclut_les_mocks_et_conserve_les_logs_reels(tmp_path):
    con = db.connect(tmp_path / "oracle.db")
    con.executemany(
        "INSERT INTO ora_requests(request_id, program_short, source) VALUES (?,?,?)",
        [(1, "PROG_REEL", "oracle"), (2, "PROG_MOCK", "mock")],
    )
    con.executemany(
        "INSERT INTO ora_programs(program_short, program_name, source) VALUES (?,?,?)",
        [("PROG_REEL", "Réel", "oracle"), ("PROG_MOCK", "Simulé", "mock")],
    )
    con.execute("INSERT INTO ora_request_logs(request_id, kind, path) VALUES (1, 'req', 'l1.req')")
    con.commit()

    demandes, logs, programmes = ui_oracle._charger_depuis(con)

    assert list(demandes["request_id"]) == [1]
    assert list(programmes["program_short"]) == ["PROG_REEL"]
    assert list(logs["request_id"]) == [1]
    con.close()
