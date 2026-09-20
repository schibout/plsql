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
