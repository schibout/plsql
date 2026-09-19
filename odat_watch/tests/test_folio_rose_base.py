"""Folio Rose : import SQLite, statuts, groupes compensés, rapprochements, contrôle Oracle simulé."""
from datetime import date, datetime
from pathlib import Path

import pandas as pd
import pytest

import db
import folio_rose as fr

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"


def test_tables_folio_rose(tmp_path):
    con = db.connect(tmp_path / "t.db")
    tables = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"fr_exports", "fr_lignes", "fr_oracle", "fr_rapprochements", "fr_rapprochement_lignes"} <= tables
    cols = [r[1] for r in con.execute("PRAGMA table_info(fr_lignes)")]
    for c in ("empreinte", "folio", "type", "fichier_base", "ecart_debit", "age_j"):
        assert c in cols
    con.close()
