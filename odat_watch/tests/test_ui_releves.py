"""Onglet Relevés bancaires via AppTest : scan, frise, plan de reprise."""
from pathlib import Path

import pytest
from streamlit.testing.v1 import AppTest

import db
import releves as rb
import ui_releves

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"
CFG = dict(dossier_pfe=REF / "fluxPFE", dossier_ebs=REF / "fichierBanque",
           dossiers_logs=[REF / "import", REF / "controle"], banque_flux_b="30003",
           comptes_connus=["30003/03620/00020137269", "16807/00166/31990892212"])


def _script():
    import sys
    from datetime import date
    from pathlib import Path
    import streamlit as st
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_releves

    def faux_kpi(col, valeur, libelle, ton=""):
        assert ton in {"ok", "warn", "err", "run", "neutral", ""}, ton      # tons connus de app.kpi
        col.markdown(f"{valeur} {libelle} [{ton}]")

    st.session_state.setdefault("rb_jour", date(2026, 9, 15))
    ui_releves.render(faux_kpi)


@pytest.fixture
def app(tmp_path, monkeypatch):
    base = tmp_path / "odat.db"
    monkeypatch.setattr(ui_releves, "connect", lambda: db.connect(base))
    monkeypatch.setattr(ui_releves.rb, "config_releves", lambda: CFG)
    at = AppTest.from_function(_script, default_timeout=120)
    at.run()
    assert not at.exception
    return at, base


def _texte(at) -> str:
    """Markdown, légendes, alertes et contenu des tableaux (le plan de reprise est un st.dataframe)."""
    return ("\n".join(m.value for m in at.markdown) + "\n".join(c.value for c in at.caption)
            + "\n".join(e.value for e in at.error) + "\n".join(d.value.to_string() for d in at.dataframe))


def test_avant_scan_invite(app):
    at, _ = app
    assert "Scanner" in "\n".join(b.label for b in at.button)
    assert any("Aucune donnée" in c.value for c in at.caption)


def test_scan_puis_frise_et_plan(app):
    at, base = app
    at.button(key="rb_scanner").click().run()
    assert not at.exception
    con = db.connect(base)
    assert con.execute("SELECT COUNT(*) FROM rb_pfe").fetchone()[0] == 13
    texte = _texte(at)
    assert "Flux B" in texte and "non reçu" in texte
    assert "Plan de reprise" in texte and "260915-081614" in texte
    assert "KO" in texte
    assert "KO verdict du jour [err]" in texte and "KO flux B [err]" in texte        # tuile KO en rouge
    assert "13 exécution(s) PFE" in "\n".join(i.value for i in at.info)
    assert "207 comptes en rupture [err]" in texte                                    # hors comptes connus
    assert "list_releves.txt des logs manquants" in "\n".join(b.label for b in at.button)
    assert len(at.get("plotly_chart")) == 1                                         # mini-tendance des imports
    at.run()                                                                        # relance sans clic : le message ne colle pas
    assert not any("exécution(s) PFE" in i.value for i in at.info)


def test_rapport_html(app, tmp_path, monkeypatch):
    at, base = app
    import rapport_releves
    monkeypatch.setattr(rapport_releves, "DOSSIER_RAPPORTS", tmp_path / "rapports")
    at.button(key="rb_scanner").click().run()
    at.button(key="rb_btn_rapport").click().run()
    assert not at.exception
    assert list((tmp_path / "rapports").glob("Releves_20260915_*.html"))
    assert any("Rapport écrit" in s.value for s in at.success)
    at.run()
    assert not any("Rapport écrit" in s.value for s in at.success)                  # message affiché une fois
