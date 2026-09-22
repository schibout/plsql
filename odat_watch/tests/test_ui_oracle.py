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


def test_cache_est_invalide_quand_les_donnees_oracle_changent(tmp_path, monkeypatch):
    base = tmp_path / "oracle_cache.db"
    con = db.connect(base)
    con.execute(
        "INSERT INTO ora_requests(request_id, program_short, refreshed_at, source) VALUES (1, 'PROG_1', '2026-09-21 09:00:00', 'oracle')"
    )
    con.commit()
    con.close()

    monkeypatch.setattr(ui_oracle, "connect", lambda: db.connect(base))
    ui_oracle._charger.clear()
    try:
        demandes, _, _ = ui_oracle._charger(("1", "2026-09-21 09:00:00"))
        assert list(demandes["request_id"]) == [1]

        con = db.connect(base)
        con.execute(
            "INSERT INTO ora_requests(request_id, program_short, refreshed_at, source) VALUES (2, 'PROG_2', '2026-09-23 08:00:00', 'oracle')"
        )
        con.commit()
        con.close()

        demandes, _, _ = ui_oracle._charger(("2", "2026-09-23 08:00:00"))
        assert list(demandes["request_id"]) == [1, 2]
    finally:
        ui_oracle._charger.clear()


def _lanceurs():
    """Demandes telles qu'Oracle les livre : presque tout passe par le lanceur générique."""
    return pd.DataFrame([
        {"request_id": 10, "job_name": "FINFIN_J34TRT_04_WRK07_H", "program_short": "DKA_SLAUNCHER",
         "program_name": "DKA : Lanceur (SHELL)", "description": "FINFIN_J34TRT_04_WRK07_H : DKA_FNDGSCST_JOB.sh",
         "argument_text": "DKA_FNDGSCST_JOB.sh, GL, , , , "},
        {"request_id": 11, "job_name": "FINEXT_J12INT_05_IMP01_Q", "program_short": "DKA_SLAUNCHER",
         "program_name": "DKA : Lanceur (SHELL)", "description": "sans les deux points",
         "argument_text": "DKA_IIZCIAP01_JTLOAD_JOB.sh, , , , , "},
        {"request_id": 12, "job_name": "INCONNU", "program_short": "DKA_SLAUNCHER",
         "program_name": "DKA : Lanceur (SHELL)", "description": "", "argument_text": ""},
        {"request_id": 13, "job_name": "AUTRE", "program_short": "XXRB", "program_name": "Import banques",
         "description": "", "argument_text": ""},
    ])


def test_resoudre_lanceurs_utilise_referentiel_puis_description_puis_arguments():
    r = ui_oracle._resoudre_lanceurs(_lanceurs(), {"FINFIN_J34TRT_04_WRK07_H": "GL : Coûts standard"})
    assert list(r["via_lanceur"]) == [True, True, True, False]
    # 1) référentiel : nom utilisateur du programme, code déduit du script
    assert r.loc[0, "program_name"] == "GL : Coûts standard" and r.loc[0, "program_short"] == "DKA_FNDGSCST"
    # 2) sans référentiel : le script de la description, sinon celui des arguments
    assert r.loc[1, "program_short"] == "DKA_IIZCIAP01_JTLOAD" and r.loc[1, "program_name"] == "DKA_IIZCIAP01_JTLOAD"
    # 3) rien d'exploitable : la demande reste, avec le lanceur
    assert r.loc[2, "program_short"] == "DKA_SLAUNCHER"
    # 4) demande hors lanceur : inchangée
    assert r.loc[3, "program_short"] == "XXRB" and r.loc[3, "program_name"] == "Import banques"
    # le lanceur d'origine reste consultable
    assert list(r["lanceur"]) == ["DKA_SLAUNCHER", "DKA_SLAUNCHER", "DKA_SLAUNCHER", ""]


def test_resoudre_lanceurs_ne_perd_aucune_demande():
    d = _lanceurs()
    assert len(ui_oracle._resoudre_lanceurs(d, {})) == len(d)
    vide = ui_oracle._resoudre_lanceurs(d.iloc[0:0], {})
    assert vide.empty and "via_lanceur" in vide.columns
