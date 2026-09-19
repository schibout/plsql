"""Historique du contrôle du matin dans SQLite."""
from datetime import datetime

import db


def _cols(con, table):
    return [r[1] for r in con.execute(f"PRAGMA table_info({table})")]


def test_table_controle_matin_histo_creee(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cols = _cols(con, "controle_matin_histo")
    for c in ("date_ctrl", "plage_debut", "plage_fin", "statut_global", "nb_images_manq", "fichier_rapport"):
        assert c in cols
    con.close()
