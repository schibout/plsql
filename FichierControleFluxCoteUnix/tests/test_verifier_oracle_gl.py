from pathlib import Path


RACINE = Path(__file__).resolve().parents[1]


def lire(nom):
    return (RACINE / nom).read_text(encoding="utf-8-sig")


def test_requete_gl_reutilise_les_cles_controle_folio_rose():
    script = lire("Verifier_Oracle_Ecritures_GL.ps1")
    assert "APPS.GL_JE_HEADERS" in script
    assert "APPS.GL_JE_LINES" in script
    assert "APPS.GL_INTERFACE" in script
    assert "attribute10 LIKE TRIM('$b') || '%'" in script
    assert "attribute9 = TRIM('$f')" in script


def test_rapport_excel_reprend_la_palette_de_prelevements():
    script = lire("Verifier_Oracle_Ecritures_GL.ps1")
    assert "$COULEUR_ENTETE = 0x7D491F" in script
    assert "$COULEUR_ECART  = 0xD6E4FC" in script
    assert "$COULEUR_OK     = 0xDAEFED" in script
    assert "Synthese Oracle" in script
    assert "Detail Pieces SRC" in script


def test_lanceur_execute_controle_local_puis_oracle():
    lanceur = lire("controleGL.bat")
    assert 'ctl_ecritures_gl.py" "%SOURCE_SELECTIONNEE%' in lanceur
    assert 'Verifier_Oracle_Ecritures_GL.ps1' in lanceur
    assert 'exit /b 2' in lanceur
