"""Sous-onglet Carte des flux via AppTest : chargement du schéma, tuiles, météo, fiche d'un flux."""
import pytest
from streamlit.testing.v1 import AppTest

import db
import flux_ref as fx
import ui_carte_flux

CEL_FRS = "CEL01_SRC_FACTURESFOURNISSEURS_210926-201628_ST_CEL01_639256185881865112_001"


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_carte_flux

    def faux_kpi(col, valeur, libelle, ton=""):
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_carte_flux.render(faux_kpi)


@pytest.fixture
def app(tmp_path, monkeypatch):
    base = tmp_path / "odat.db"
    con = db.connect(base)
    con.execute("INSERT INTO fr_lignes(empreinte, folio, date, type, fichier, fichier_base, amont_nb, amont_debit, "
                "si_nb, si_debit, ecart_nb, ecart_debit, present) VALUES ('e1','CEE','21/09/2026','FOURNISSEURS',?,?,"
                "10,1000,10,1000,0,0,1)", (CEL_FRS, CEL_FRS[:40]))
    con.commit()
    con.close()
    monkeypatch.setattr(ui_carte_flux, "connect", lambda: db.connect(base))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    return at, base


def test_vide_puis_chargement_du_schema(app):
    at, base = app
    assert any("Aucun flux déclaré" in i.value for i in at.info)
    at.button(key="cf_charger").click().run()
    assert not at.exception
    valeurs = " ".join(m.value for m in at.markdown)
    assert "66 flux" in valeurs and "33 vers Oracle" in valeurs and "33 depuis Oracle" in valeurs
    con = db.connect(base)
    assert len(fx.flux(con)) == 66
    con.close()
    assert any("Météo des flux (66)" in m.value for m in at.markdown)
    assert at.dataframe                                   # la météo (AppTest n'expose pas st.progress)


def test_filtre_et_fiche(app):
    at, base = app
    at.button(key="cf_charger").click().run()
    at.session_state["cf_f_sens"] = ["sortant"]
    at.run()
    assert not at.exception
    assert any("Météo des flux (33)" in m.value for m in at.markdown)
    # la fiche d'un flux se choisit dans la liste filtrée
    options = at.selectbox(key="cf_choix").options
    assert len(options) == 33 and all("Oracle →" in o for o in options)


def test_declarer_les_fichiers_inconnus(app):
    at, base = app
    at.button(key="cf_decouvrir").click().run()
    assert not at.exception
    con = db.connect(base)
    f = fx.flux(con)
    assert len(f) == 1 and f.iloc[0]["motif"] == "CEL01_SRC_FACTURESFOURNISSEURS_*"
    assert f.iloc[0]["application"] == "CEL01" and f.iloc[0]["sens"] == "entrant"
    con.close()
    valeurs = " ".join(m.value for m in at.markdown)
    assert "1 conformes [ok]" in valeurs                  # le fichier connu est à l'équilibre
