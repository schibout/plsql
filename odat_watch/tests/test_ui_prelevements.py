"""Onglet Prélèvements via AppTest : lecture d'un rapport fabriqué, tuiles, groupes par statut, message sans rapport."""
from datetime import date

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
    assert at.date_input[0].value == date.today()          # défaut : aujourd'hui, pas la dernière date contrôlée
    assert any("Lancer le rapprochement" in c.value for c in at.caption)
    at.date_input[0].set_value(date(2026, 9, 14)).run()
    assert not at.exception
    texte = "\n".join(m.value for m in at.markdown) + "\n".join(c.value for c in at.caption)
    assert "✅ OK résultat global [ok]" in texte
    assert "592 prélèvements émis" in texte and "1 en attente EDF [warn]" in texte
    assert "Rapport généré le" in texte
    labels = [e.label for e in at.expander]
    assert any("Rapproché" in l and "1 clé" in l for l in labels)
    assert any("En attente EDF" in l for l in labels)
    assert any("Justification des écarts" in l and "1 à investiguer" in l for l in labels)
    assert "0 émis en double [ok]" in texte
    assert any("émis en double — 0 doublon(s), 0 similitude(s)" in l for l in labels)


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


def test_lancer_affiche_message_et_journal(monkeypatch, tmp_path):
    def faux_lancer(reference, cfg):
        _rapport(tmp_path / "rapport", f"Rapprochement_Cle_Metier_{reference:%Y%m%d}_120000")
        return {"statut_global": "OK", "par_statut": {"RAPPROCHE": {"cles": 1}}, "nb_anomalies": 0,
                "base": f"Rapprochement_Cle_Metier_{reference:%Y%m%d}_120000",
                "journal": "Oracle : 1 fichier(s), 1 ligne(s)\nEDF : 1 fichier(s)"}
    monkeypatch.setattr(pv, "config_prelevements", _cfg(tmp_path))
    monkeypatch.setattr(pv, "lancer", faux_lancer)
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    at.button(key="pv_lancer").click().run()
    assert not at.exception
    assert any("terminé : OK" in s.value for s in at.success)
    assert any("Journal d'exécution" in e.label for e in at.expander)
    assert any("Oracle : 1 fichier(s)" in c.value for c in at.code)
    assert any("résultat global [ok]" in m.value for m in at.markdown)


def test_onglet_signale_les_doublons(monkeypatch, tmp_path):
    _rapport(tmp_path / "rapport", "Rapprochement_Cle_Metier_20260914_081400",
             doublons="DOUBLON;P1;RUM1;FR76A;FR76D;X;30/09/2026;100.00;2;f1 + f2;11/09/2026 + 12/09/2026\n")
    monkeypatch.setattr(pv, "config_prelevements", _cfg(tmp_path))
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    at.date_input[0].set_value(date(2026, 9, 14)).run()
    assert not at.exception
    assert any("1 émis en double [err]" in m.value for m in at.markdown)
    assert any("1 doublon(s), 0 similitude(s)" in e.label for e in at.expander)


def test_rapport_html_et_texte_mail(monkeypatch, tmp_path):
    import rapport_prelevements as rp
    _rapport(tmp_path / "rapport", "Rapprochement_Cle_Metier_20260914_081400")
    monkeypatch.setattr(pv, "config_prelevements", _cfg(tmp_path))
    monkeypatch.setattr(rp, "DOSSIER_RAPPORTS", tmp_path / "rapports")
    at = AppTest.from_function(_script, default_timeout=60)
    at.run()
    at.date_input[0].set_value(date(2026, 9, 14)).run()
    at.button(key="pv_rapport").click().run()
    assert not at.exception
    fichiers = list((tmp_path / "rapports").glob("Prelevements_20260914_*.html"))
    assert len(fichiers) == 1
    assert any("Rapport HTML" in b.label for b in at.download_button)
    assert any("Prélèvements Oracle ↔ EDF au 14/09/2026 : OK" in c.value for c in at.code)
