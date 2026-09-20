"""Onglet SQL via AppTest : les boutons de l'explorateur remplissent la zone SQL et exécutent la requête."""
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

import db
import ui_sql


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_sql

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_sql.render(faux_kpi)


@pytest.fixture
def app(tmp_path, monkeypatch):
    base = tmp_path / "odat.db"
    con = db.connect(base)
    con.execute("INSERT INTO snapshots(odate, snap_time, source_file, file_hash, nb_lignes) VALUES ('2026-09-19','2026-09-19 07:00:00','x','h',1)")
    con.commit(); con.close()
    monkeypatch.setattr(ui_sql, "connect", lambda: db.connect(base))
    monkeypatch.setattr(ui_sql, "DB_PATH", base)
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    return at


def test_select_etoile_remplit_et_execute(app):
    at = app
    at.selectbox(key="sql_table").select("snapshots").run()
    at.button(key="sql_select_all").click().run()
    assert not at.exception
    assert at.text_area(key="sql_area").value.startswith("SELECT *\nFROM snapshots")
    assert at.dataframe                                    # résultat affiché
    assert any("1 ligne(s)" in c.value for c in at.caption)


def test_colonnes_choisies(app):
    at = app
    at.selectbox(key="sql_table").select("snapshots").run()
    at.multiselect(key="sql_cols").set_value(["odate", "nb_lignes"]).run()
    at.button(key="sql_select_cols").click().run()
    assert not at.exception
    sql = at.text_area(key="sql_area").value
    assert sql.startswith("SELECT odate, nb_lignes\nFROM snapshots")
    df = at.dataframe[-1].value
    assert list(df.columns) == ["odate", "nb_lignes"]


def test_exemple_puis_modification_manuelle(app):
    at = app
    at.selectbox(key="sql_exemple").select("Photos chargées par jour").run()
    assert "FROM snapshots GROUP BY odate" in at.text_area(key="sql_area").value
    at.text_area(key="sql_area").set_value("SELECT COUNT(*) AS n FROM snapshots").run()
    at.button(key="sql_run").click().run()
    assert not at.exception
    assert int(at.dataframe[-1].value["n"].iloc[0]) == 1


def test_lecture_seule(app):
    at = app
    at.text_area(key="sql_area").set_value("DELETE FROM snapshots").run()
    at.button(key="sql_run").click().run()
    assert any("Lecture seule" in e.value for e in at.error)
