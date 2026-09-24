"""Sous-onglet Ctrl Flux › Mode d'emploi : une section par sous-onglet, couleurs et états tirés du code."""
from streamlit.testing.v1 import AppTest

import carte_flux as cf
import ctrl_flux as cx
import ui_mode_emploi_flux as me


def _script():
    import sys
    from pathlib import Path
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    import ui_mode_emploi_flux
    ui_mode_emploi_flux.render()


def test_le_guide_a_une_section_par_sous_onglet():
    intro, corps = me.sections(me.GUIDE.read_text(encoding="utf-8"))
    assert intro and {titre for _, titre in me.ONGLETS} <= set(corps)


def test_toutes_les_couleurs_de_ligne_sont_expliquees():
    couleurs = {c for _, c, _ in me.REGLES_COULEUR}
    assert set(cx.COULEURS_LIGNE.values()) <= couleurs


def test_rendu():
    at = AppTest.from_function(_script, default_timeout=30)
    at.run()
    assert not at.exception
    assert [t.label for t in at.tabs] == [o[0] for o in me.ONGLETS]
    assert len(at.dataframe) == len(me.ONGLETS)                         # un tableau de dossiers par sous-onglet
    textes = " ".join(m.value for m in at.markdown)
    assert "Rapprocher ces lignes" in textes and "Reconstituer depuis le dossier" in textes
    assert all(cf.LIBELLES_ETAT[e] in textes for e in cf.ETATS)
