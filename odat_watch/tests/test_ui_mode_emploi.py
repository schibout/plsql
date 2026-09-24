"""Sous-onglet Mode d'emploi : s'affiche sans base, légende et exemple en vraies couleurs."""
from streamlit.testing.v1 import AppTest

import plan_prod as pp
import ui_mode_emploi


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_mode_emploi
    ui_mode_emploi.render()


def test_legende_couvre_tous_les_symboles_de_la_grille():
    cellules = {c[:1] for c, _, _ in ui_mode_emploi.LEGENDE if c}
    assert set(pp.ICONES.values()) | {pp.NON_OBSERVE, pp.PREVU, pp.SANS_PHOTO} <= cellules


def test_rendu():
    at = AppTest.from_function(_script, default_timeout=30)
    at.run()
    assert not at.exception
    assert len(at.dataframe) >= 4
    assert "FINEXT_J17GEN_06_M" in list(at.dataframe[1].value["chaîne"])
