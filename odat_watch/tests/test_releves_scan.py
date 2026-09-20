"""Scan des dossiers PFE / EBS et rapprochement par md5 (fichiers réels de ControleReleveBancaire)."""
from pathlib import Path

import db
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"


def test_tables_rb_creees(tmp_path):
    con = db.connect(tmp_path / "t.db")
    tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"rb_pfe", "rb_ebs", "rb_imports", "rb_import_releves", "rb_controles", "rb_controle_lignes",
            "rb_comptes_connus"} <= tables


def test_config_releves_par_defaut(tmp_path, monkeypatch):
    monkeypatch.setattr(rb, "CONFIG", tmp_path / "absent.ini")
    cfg = rb.config_releves()
    assert cfg["banque_flux_b"] == "30003"
    assert cfg["dossier_pfe"].name == "fluxPFE" and cfg["dossier_ebs"].name == "fichierBanque"
    assert [d.name for d in cfg["dossiers_logs"]] == ["import", "controle"]
    assert "30003/03620/00020137269" in cfg["comptes_connus"]


def test_scanner_pfe_13_executions(tmp_path):
    con = db.connect(tmp_path / "t.db")
    n = rb.scanner_pfe(REF / "fluxPFE", con, "30003")
    assert n == 13
    assert rb.scanner_pfe(REF / "fluxPFE", con, "30003") == 0          # déjà en base : rien de nouveau
    r = con.execute("SELECT * FROM rb_pfe WHERE uuid='2b6da61b5e384790970e4ab0b536102e'").fetchone()
    assert r["horodatage"] == "2026-09-15 08:16:14" and r["flux"] == "B" and r["nb_releves"] == 213
    assert r["complete"] == 1 and r["ls_in_ok"] == 1 and r["zip"].endswith("compteur_20260915_0816.zip")
    assert (r["date_min"], r["date_max"]) == ("2026-09-11", "2026-09-14")


def test_scanner_ebs(tmp_path):
    con = db.connect(tmp_path / "t.db")
    n = rb.scanner_ebs(REF / "fichierBanque", con, "30003")
    assert n == 22
    r = con.execute("SELECT * FROM rb_ebs WHERE nom='AFB120.txt_20260917081953'").fetchone()
    assert r["horodatage"] == "2026-09-17 08:19:53" and r["flux"] == "B"
    r = con.execute("SELECT horodatage FROM rb_ebs WHERE nom LIKE 'AFB120.txt_20260907110939%'").fetchone()
    assert r["horodatage"] == "2026-09-07 11:09:39"                    # suffixe libre toléré


def test_rapprochement_pfe_ebs(tmp_path):
    con = db.connect(tmp_path / "t.db")
    rb.scanner_pfe(REF / "fluxPFE", con, "30003")
    rb.scanner_ebs(REF / "fichierBanque", con, "30003")
    rb.rapprocher_pfe_ebs(con)
    absents = {r[0] for r in con.execute("SELECT uuid FROM rb_pfe WHERE ebs_md5_recu=0")}
    assert absents == {"2b6da61b5e384790970e4ab0b536102e", "f067afff37d54178852c7c46a7048ab0"}
    assert con.execute("SELECT COUNT(*) FROM rb_pfe WHERE ebs_md5_recu=1").fetchone()[0] == 11
