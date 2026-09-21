"""Programme Oracle Applications associé à chaque job Control-M (lanceur → traitement métier)."""
import db
import forecast as fc


def test_programmes_oracle_prend_le_traitement_lance_par_le_lanceur(tmp_path):
    con = db.connect(tmp_path / "t.db")
    con.execute("INSERT INTO job_mapping(job_name, program_short, commentaire) VALUES ('FINFIN_J18TRT_04_IMP01_Q', 'DKA_SLAUNCHER', 'x')")
    rows = [(1, "DKA_SLAUNCHER", "Lanceur générique", "FINFIN_J18TRT_04_IMP01_Q"),
            (2, "DKA_IPAPROJETHRM", "Import projets HRM", "FINFIN_J18TRT_04_IMP01_Q"),
            (3, "DKA_IPAPROJETHRM", "Import projets HRM", "FINFIN_J18TRT_04_IMP01_Q"),
            (4, "APXIIMPT", "Import des factures fournisseurs", "FINFIN_J18TRT_04_IMP01_Q"),
            (5, "DKA_SLAUNCHER", "Lanceur générique", "FINEXT_J11GEN_06_EXP01_Q")]      # lanceur seul
    con.executemany("INSERT INTO ora_requests(request_id, program_short, program_name, job_name) VALUES (?,?,?,?)", rows)
    con.commit()
    prog = fc.programmes_oracle(con)
    assert prog["FINFIN_J18TRT_04_IMP01_Q"] == "DKA_IPAPROJETHRM · Import projets HRM ; APXIIMPT · Import des factures fournisseurs"
    assert "FINEXT_J11GEN_06_EXP01_Q" not in prog          # lanceur seul : pas de programme métier connu
    assert "INCONNU" not in prog
    con.close()


def test_programmes_oracle_ignore_les_demandes_et_programmes_mock(tmp_path):
    con = db.connect(tmp_path / "t.db")
    con.execute("INSERT INTO job_mapping(job_name, program_short, commentaire) VALUES ('JOB_A', 'DKA_SLAUNCHER', 'x')")
    con.executemany(
        "INSERT INTO ora_requests(request_id, program_short, program_name, job_name, source) VALUES (?,?,?,?,?)",
        [(1, "PROG_REEL", "Programme réel", "JOB_A", "oracle"),
         (2, "PROG_MOCK", "Programme simulé", "JOB_A", "mock")],
    )
    con.executemany(
        "INSERT INTO ora_programs(program_short, program_name, source) VALUES (?,?,?)",
        [("PROG_REEL", "Programme réel", "oracle"), ("PROG_MOCK", "Programme simulé", "mock")],
    )
    con.commit()

    assert fc.programmes_oracle(con)["JOB_A"] == "PROG_REEL · Programme réel"
    con.close()


def test_programme_depuis_description():
    import oracle_refresh as orf
    assert orf.programme_from_description("FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh") == "DKA_IPAPROJETHRM"
    assert orf.programme_from_description("FINEXT_J11GEN_06_EXP01_Q : DKA_APEXPCDE_JOB.sh (DKA : Lanceur (SHELL))") == "DKA_APEXPCDE"
    assert orf.programme_from_description("FINFIN_X : ebsstop.ksh") == "EBSSTOP"
    assert orf.programme_from_description("Import des projets") is None


def test_programmes_oracle_utilise_le_script_du_lanceur_a_defaut_de_filles(tmp_path):
    con = db.connect(tmp_path / "t.db")
    con.execute("INSERT INTO job_mapping(job_name, program_short, commentaire, programme) VALUES "
                "('FINFIN_J18TRT_04_IMP01_Q', 'DKA_SLAUNCHER', 'FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh', 'DKA_IPAPROJETHRM')")
    con.execute("INSERT INTO ora_programs(program_short, program_name) VALUES ('DKA_IPAPROJETHRM', 'Import projets HRM')")
    con.execute("INSERT INTO ora_requests(request_id, program_short, program_name, job_name) VALUES (1, 'DKA_SLAUNCHER', 'Lanceur', 'FINFIN_J18TRT_04_IMP01_Q')")
    con.commit()
    assert fc.programmes_oracle(con)["FINFIN_J18TRT_04_IMP01_Q"] == "DKA_IPAPROJETHRM · Import projets HRM"
    con.close()


def test_programmes_oracle_n_affiche_jamais_le_lanceur(tmp_path):
    con = db.connect(tmp_path / "t.db")
    con.execute("INSERT INTO job_mapping(job_name, program_short, commentaire) VALUES ('FINFIN_J11TEC_04_DEB01_Q', 'DKA_SLAUNCHER', 'x')")
    con.execute("INSERT INTO ora_requests(request_id, program_short, program_name, job_name) VALUES (1, 'DKA_SLAUNCHER', 'Lanceur', 'FINFIN_J11TEC_04_DEB01_Q')")
    con.commit()
    assert "FINFIN_J11TEC_04_DEB01_Q" not in fc.programmes_oracle(con)
    con.close()
