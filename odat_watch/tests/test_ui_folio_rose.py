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
    lignes = fr.lignes(con)
    # deux lignes du même folio dont on force la compensation
    a, b = lignes.index[:2]
    con.execute("UPDATE fr_lignes SET folio='ZZZ', fichier_base='F', ecart_debit=100, ecart_credit=100, ecart_nb=1 WHERE empreinte=?", (lignes.loc[a, "empreinte"],))
    con.execute("UPDATE fr_lignes SET folio='ZZZ', fichier_base='F', ecart_debit=-100, ecart_credit=-100, ecart_nb=-1 WHERE empreinte=?", (lignes.loc[b, "empreinte"],))
    con.commit()
    at.session_state["fr_folios"] = ["ZZZ"]
    at.run()
    assert not at.exception
    assert any("Groupes compensés en attente (1)" in m.value for m in at.markdown)
    # la sélection de lignes dans st.dataframe n'est pas pilotable par AppTest : on rapproche le groupe
    at.button(key="fr_grp_0").click().run()
    assert not at.exception
    assert fr.lignes(con)["rapproche"].sum() == 2
    assert any("Groupes compensés en attente (0)" in m.value for m in at.markdown)
    con.close()


def test_generer_le_rapport(app, tmp_path, monkeypatch):
    import rapport_folio_rose as rm
    at, base = app
    monkeypatch.setattr(rm, "DOSSIER_RAPPORTS", tmp_path / "r")
    monkeypatch.setattr(rm.ecrire, "__defaults__", (tmp_path / "r",))
    at.button(key="fr_btn_rapport").click().run()
    assert not at.exception
    assert list((tmp_path / "r").glob("Folio_Rose_*.html"))


def test_import_remplace_l_etat(app, monkeypatch):
    # un nouvel import vide l'état courant : seules les lignes du dernier lot restent
    at, base = app
    fichiers = sorted(SAUVEGARDE.glob("ExportCSV-*.csv"))
    assert len(fichiers) >= 2
    autre = [f for f in fichiers if f.name != "ExportCSV-19-08-2026.csv"][0]
    msgs = ui_folio_rose._importer_fichiers([autre])
    assert "vidé" in msgs[0] and "importées" in msgs[1]
    con = db.connect(base)
    assert con.execute("SELECT COUNT(*) FROM fr_exports").fetchone()[0] == 1
    assert fr.exports(con).iloc[0]["nom_fichier"] == autre.name
    assert (fr.lignes(con, disparues=True)["dernier_export"] == autre.name).all()
    con.close()
