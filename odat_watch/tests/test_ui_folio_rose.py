"""Onglet Folio Rose via AppTest : import, somme de la sélection, rapprochement."""
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

import db
import folio_rose as fr
import ui_folio_rose

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_folio_rose

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_folio_rose.render(faux_kpi)


@pytest.fixture
def app(tmp_path, monkeypatch):
    base = tmp_path / "odat.db"
    con = db.connect(base)
    e = fr.lire_export(SAUVEGARDE / "ExportCSV-19-08-2026.csv")
    fr.importer(e, con)
    con.close()
    monkeypatch.setattr(ui_folio_rose, "connect", lambda: db.connect(base))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    return at, base


def test_affichage(app):
    at, _ = app
    assert any("lignes [neutral]" in m.value for m in at.markdown)
    assert at.dataframe
    assert any("Cochez des lignes" in c.value for c in at.caption)


def test_selection_et_rapprochement(app):
    at, base = app
    con = db.connect(base)
    eid = int(fr.exports(con)["id"].iloc[0])
    lignes = fr.lignes_export(eid, con)
    # deux lignes du même folio dont on force la compensation
    a, b = lignes.index[:2]
    con.execute("UPDATE fr_lignes SET folio='ZZZ', fichier_base='F', ecart_debit=100 WHERE empreinte=?", (lignes.loc[a, "empreinte"],))
    con.execute("UPDATE fr_lignes SET folio='ZZZ', fichier_base='F', ecart_debit=-100 WHERE empreinte=?", (lignes.loc[b, "empreinte"],))
    con.commit()
    at.session_state["fr_folios"] = ["ZZZ"]
    at.run()
    assert not at.exception
    assert any("Groupes compensés en attente (1)" in m.value for m in at.markdown)
    # la sélection de lignes dans st.dataframe n'est pas pilotable par AppTest : on rapproche le groupe
    at.button(key="fr_grp_0").click().run()
    assert not at.exception
    assert fr.lignes_export(eid, con)["rapproche"].sum() == 2
    assert any("Groupes compensés en attente (0)" in m.value for m in at.markdown)
    con.close()
