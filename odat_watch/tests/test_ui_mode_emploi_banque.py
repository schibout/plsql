"""Sous-onglet Banque › Mode d'emploi : une section par onglet, dossiers lus dans config.ini, statuts de l'écran."""
from pathlib import Path

from streamlit.testing.v1 import AppTest

import prelevements as pv
import ui_mode_emploi_banque as me


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_mode_emploi_banque
    ui_mode_emploi_banque.render()


def test_le_guide_a_une_section_par_onglet():
    intro, corps = me.sections(me.GUIDE.read_text(encoding="utf-8"))
    assert intro and {titre for _, titre, _ in me.ONGLETS} <= set(corps)


def test_dossiers_suivent_config_ini(monkeypatch, tmp_path):
    ini = tmp_path / "config.ini"
    ini.write_text("[prelevements]\n" f"racine = {tmp_path}\n" "dossier_edf = CASH\n", encoding="utf-8")
    monkeypatch.setattr(pv, "CONFIG", ini)
    (tmp_path / "CASH").mkdir()
    (tmp_path / "CASH" / "IMPORT_AVP_DK.20260918.070101.csv").write_text("")
    df = me.dossiers("prelevements").set_index("clé config.ini")
    assert df.loc["dossier_edf", "chemin"] == str(tmp_path / "CASH")
    assert df.loc["dossier_edf", "état"] == "✅ 1 élément(s)" and df.loc["dossier_rejets", "état"] == "❌ absent"


def test_rendu():
    at = AppTest.from_function(_script, default_timeout=30)
    at.run()
    assert not at.exception
    assert [t.label for t in at.tabs] == [o[0] for o in me.ONGLETS]
    # un tableau de dossiers par onglet + les statuts des prélèvements, tous issus de prelevements.py
    assert len(at.dataframe) == 4
    assert list(at.dataframe[3].value["statut"]) == [pv.LIBELLES_STATUT[s] for s in pv.ORDRE_STATUTS]
    assert any("Plan de reprise" in m.value for m in at.markdown)
