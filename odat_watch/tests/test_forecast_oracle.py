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
    assert prog["FINEXT_J11GEN_06_EXP01_Q"] == "DKA_SLAUNCHER · Lanceur générique"
    assert "INCONNU" not in prog
    con.close()
