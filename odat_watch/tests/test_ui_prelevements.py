"""Onglet Prélèvements via AppTest : lecture d'un rapport fabriqué, tuiles, groupes par statut, message sans rapport."""
from streamlit.testing.v1 import AppTest

import prelevements as pv
from test_prelevements import _rapport


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_prelevements

    def faux_kpi(col, valeur, libelle, ton=""):
        assert ton in {"ok", "warn", "err", "run", "neutral", ""}, ton
        col.markdown(f"{valeur} {libelle} [{ton}]")

    ui_prelevements.render(faux_kpi)


def _cfg(racine):
    return lambda: {"racine": racine, "jours": 10, "nom_si": "ORACLE"}


def test_onglet_affiche_le_rapport(monkeypatch, tmp_path):
    _rapport(tmp_path / "rapport", "Rapprochement_Cle_Metier_20260914_081400")
    monkeypatch.setattr(pv, "config_prelevements", _cfg(tmp_path))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    texte = "\n".join(m.value for m in at.markdown) + "\n".join(c.value for c in at.caption)
    assert "✅ OK résultat global [ok]" in texte
    assert "592 prélèvements émis" in texte and "1 en attente EDF [warn]" in texte
    assert "Rapport généré le" in texte
    labels = [e.label for e in at.expander]
    assert any("Rapproché" in l and "1 clé" in l for l in labels)
    assert any("En attente EDF" in l for l in labels)
    assert any("Justification des écarts" in l and "1 à investiguer" in l for l in labels)


def test_onglet_sans_aucun_rapport(monkeypatch, tmp_path):
    monkeypatch.setattr(pv, "config_prelevements", _cfg(tmp_path))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    assert any("Lancer le rapprochement" in c.value for c in at.caption)


def test_onglet_racine_absente(monkeypatch, tmp_path):
    monkeypatch.setattr(pv, "config_prelevements", _cfg(tmp_path / "nulle_part"))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    assert not at.exception
    assert any("config.ini [prelevements] racine" in c.value for c in at.caption)
