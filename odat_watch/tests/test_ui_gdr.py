"""Sous-onglet GDR via AppTest : tuiles, pièces rejetées, lignes, historique des imports."""
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

import db
import gdr as gd
import ui_gdr

DOSSIER = Path(__file__).resolve().parents[2] / "ODAT" / "GDR"
pytestmark = pytest.mark.skipif(not DOSSIER.is_dir(), reason="données ODAT/GDR absentes")

GL_2905 = DOSSIER / "29052026_Synthese_des_rejets_GL_au_29-05-2026.csv"
GL_2905_02 = DOSSIER / "29052026_Synthese_des_rejets_GL_au_29-05-2026_02.csv"
AP_0306 = DOSSIER / "03062026_Synthese_des_rejets_AP_au_03-06-2026.csv"


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_gdr

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_gdr.render(faux_kpi)


def _app(tmp_path, monkeypatch, fichiers=(GL_2905, AP_0306)):
    base = tmp_path / "odat.db"
    con = db.connect(base)
    for f in fichiers:
        gd.importer(gd.lire_fichier(f), con)
    con.close()
    monkeypatch.setattr(ui_gdr, "connect", lambda: db.connect(base))
    monkeypatch.setattr(gd, "config_gdr", lambda: {"racine": tmp_path / "gdr"})
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    return at, base


def test_tuiles_et_tableaux(tmp_path, monkeypatch):
    at, base = _app(tmp_path, monkeypatch)
    con = db.connect(base)
    ouverts = gd.rejets(con)
    pcs = gd.pieces(ouverts)
    con.close()
    valeurs = " ".join(m.value for m in at.markdown)
    assert f"{len(pcs)} pièces rejetées" in valeurs
    assert f"{len(ouverts)} lignes" in valeurs
    assert at.dataframe                                  # pièces + lignes
    assert any("GL" in str(o) for o in at.multiselect[0].options)


def test_filtre_par_type(tmp_path, monkeypatch):
    at, base = _app(tmp_path, monkeypatch)
    at.session_state["gdr_types"] = ["AP"]
    at.run()
    assert not at.exception
    table = at.dataframe[0].value
    assert set(table["Type"]) == {"AP"}


def test_rejets_traites_masques_par_defaut(tmp_path, monkeypatch):
    # le _02 du 29/05 ne garde qu'une pièce ouverte : les autres sont traitées, donc masquées
    at, base = _app(tmp_path, monkeypatch, fichiers=(GL_2905, GL_2905_02))
    con = db.connect(base)
    ouverts, tous = len(gd.rejets(con)), len(gd.rejets(con, ouverts=False))
    con.close()
    assert ouverts < tous
    assert len(at.dataframe[1].value) == ouverts
    at.session_state["gdr_traites"] = True
    at.run()
    assert not at.exception
    assert len(at.dataframe[1].value) == tous


def test_historique_des_imports(tmp_path, monkeypatch):
    at, _ = _app(tmp_path, monkeypatch)
    assert any("Imports GDR (2)" in str(e.label) for e in at.expander)


def test_sans_donnees(tmp_path, monkeypatch):
    at, _ = _app(tmp_path, monkeypatch, fichiers=())
    assert any("Aucun export GDR" in i.value for i in at.info)
