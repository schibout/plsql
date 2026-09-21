"""Référentiel jobs Control-M <-> programmes Oracle Applications : auto-alimenté, corrigeable à la main."""
import db
import referentiel as ref


def _base(tmp_path):
    con = db.connect(tmp_path / "t.db")
    con.execute("INSERT INTO snapshots(id, odate, snap_time, source_file, file_hash, nb_lignes) VALUES (1,'2026-09-19','2026-09-19 07:00:00','x','h',3)")
    con.executemany("INSERT INTO ctm_jobs(snapshot_id, application, group_name, job_name, description, member, task_type) VALUES (1,?,?,?,?,?,?)",
                    [("FIN-FINANCE", "FINFIN_J18TRT_04_Q", "FINFIN_J18TRT_04_IMP01_Q", "Import des projets dans PA", "", "Job"),
                     ("FIN-FINANCE", "FINFIN_J11TEC_04_Q", "FINFIN_J11TEC_04_DEB01_Q", "Jalon Debut Finance", "", "Job"),
                     ("CEL-CELERIS", "CELCEL_J11TRT_04_H", "CELCEL_J11TRT_04_WRK01_H", "Maintenance Bdd", "maint.ksh", "Job")])
    con.execute("INSERT INTO job_mapping(job_name, program_short, commentaire, programme) VALUES "
                "('FINFIN_J18TRT_04_IMP01_Q','DKA_SLAUNCHER','x','DKA_IPAPROJETHRM')")
    con.execute("INSERT INTO ora_programs(program_short, program_name, application_short) VALUES ('DKA_IPAPROJETHRM','Import projets HRM','DKA')")
    con.commit()
    return con


def test_synchroniser_cree_les_lignes_et_remplit_l_auto(tmp_path):
    con = _base(tmp_path)
    n = ref.synchroniser(con)
    assert n == 3
    t = ref.table(con)
    assert list(t["job_name"]) == ["CELCEL_J11TRT_04_WRK01_H", "FINFIN_J11TEC_04_DEB01_Q", "FINFIN_J18TRT_04_IMP01_Q"]
    imp = t.set_index("job_name").loc["FINFIN_J18TRT_04_IMP01_Q"]
    assert imp["programme_auto"] == "Import projets HRM" and imp["programme"] == "Import projets HRM"
    assert imp["programme_code"] == "DKA_IPAPROJETHRM"
    assert imp["source"] == "auto" and imp["description"] == "Import des projets dans PA" and imp["chaine"] == "FINFIN_J18TRT_04_Q"
    jalon = t.set_index("job_name").loc["FINFIN_J11TEC_04_DEB01_Q"]
    assert jalon["source"] == "à renseigner" and jalon["programme"] == ""
    assert ref.synchroniser(con) == 0            # rien de nouveau
    con.close()


def test_saisie_manuelle_prioritaire_et_conservee(tmp_path):
    con = _base(tmp_path)
    ref.synchroniser(con)
    ref.enregistrer(con, "FINFIN_J18TRT_04_IMP01_Q", programme="PA_IMPORT_PROJETS", application="PA", commentaire="vu avec le DBA")
    t = ref.table(con).set_index("job_name")
    assert t.loc["FINFIN_J18TRT_04_IMP01_Q", "programme"] == "PA_IMPORT_PROJETS"
    assert t.loc["FINFIN_J18TRT_04_IMP01_Q", "source"] == "manuel"
    assert t.loc["FINFIN_J18TRT_04_IMP01_Q", "programme_auto"] == "Import projets HRM"
    ref.synchroniser(con)                         # une resynchro ne remplace pas la saisie
    assert ref.table(con).set_index("job_name").loc["FINFIN_J18TRT_04_IMP01_Q", "programme"] == "PA_IMPORT_PROJETS"
    ref.enregistrer(con, "FINFIN_J18TRT_04_IMP01_Q", programme="", application="", commentaire="")   # effacement -> retour à l'auto
    assert ref.table(con).set_index("job_name").loc["FINFIN_J18TRT_04_IMP01_Q", "source"] == "auto"
    assert ref.programmes(con)["FINFIN_J18TRT_04_IMP01_Q"] == "Import projets HRM"
    con.close()


def test_programmes_fusionne_manuel_et_auto(tmp_path):
    con = _base(tmp_path)
    ref.synchroniser(con)
    ref.enregistrer(con, "FINFIN_J11TEC_04_DEB01_Q", programme="(jalon, pas de programme)", application="", commentaire="")
    p = ref.programmes(con)
    assert p["FINFIN_J11TEC_04_DEB01_Q"] == "(jalon, pas de programme)"
    assert p["FINFIN_J18TRT_04_IMP01_Q"] == "Import projets HRM"
    con.close()


def test_synchroniser_relit_les_descriptions_de_lanceur_deja_en_base(tmp_path):
    """Les demandes Oracle chargées avant la règle « script -> programme » n'avaient pas alimenté job_mapping :
    la synchronisation relit toutes les descriptions de lanceur présentes en base."""
    con = _base(tmp_path)
    con.execute("INSERT INTO ctm_jobs(snapshot_id, application, group_name, job_name, description, member, task_type) "
                "VALUES (1,'FIN-FINANCE','FINEXT_J11GEN_06_Q','FINEXT_J11GEN_06_EXP01_Q','Export commandes','','Job')")
    con.execute("INSERT INTO ora_programs(program_short, program_name, application_short) VALUES ('DKA_IPOEXTRACTCDE','Extraction des commandes','DKA')")
    con.execute("INSERT INTO ora_requests(request_id, program_short, description, job_name, source) VALUES "
                "(1, 'DKA_SLAUNCHER', 'FINEXT_J11GEN_06_EXP01_Q : DKA_IPOEXTRACTCDE_JOB.sh', 'FINEXT_J11GEN_06_EXP01_Q', 'oracle')")
    con.commit()
    assert con.execute("SELECT COUNT(*) FROM job_mapping WHERE job_name='FINEXT_J11GEN_06_EXP01_Q'").fetchone()[0] == 0
    ref.synchroniser(con)
    t = ref.table(con).set_index("job_name")
    assert t.loc["FINEXT_J11GEN_06_EXP01_Q", "programme_auto"] == "Extraction des commandes"
    assert t.loc["FINEXT_J11GEN_06_EXP01_Q", "programme_code"] == "DKA_IPOEXTRACTCDE"
    assert con.execute("SELECT programme FROM job_mapping WHERE job_name='FINEXT_J11GEN_06_EXP01_Q'").fetchone()[0] == "DKA_IPOEXTRACTCDE"
    con.close()
