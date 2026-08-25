from pathlib import Path


RACINE = Path(__file__).resolve().parents[1]


def lire(nom):
    return (RACINE / nom).read_text(encoding="utf-8-sig")


def test_rapports_locaux_partagent_la_palette_et_la_navigation():
    for nom in ("ctl_fac02.py", "ctl_ecritures_gl.py"):
        script = lire(nom)
        assert 'bleu = "1F497D"' in script
        assert 'peche = "FCE4D6"' in script
        assert 'vert = "EDEFDA"' in script
        assert "freeze_panes" in script
        assert "showGridLines = False" in script
        assert "auto_filter.ref" in script


SCRIPTS_ORACLE = (
    "Verifier_Oracle_FAC02_Client.ps1",
    "Verifier_Oracle_FAC02_Fournisseur.ps1",
    "Verifier_Oracle_Ecritures_GL.ps1",
)


def test_les_controles_oracle_alimentent_le_classeur_de_synthese():
    for nom in SCRIPTS_ORACLE:
        script = lire(nom)
        assert "rapport_oracle.ps1" in script
        assert "Export-OngletsOracle" in script
        assert "ConvertTo-LignesOnglet" in script


def test_aucun_controle_ne_produit_de_csv():
    for nom in SCRIPTS_ORACLE:
        assert "Export-Csv" not in lire(nom)


def test_aucun_controle_ne_pilote_excel_en_com():
    """L'ecriture passe par openpyxl : le rapport ne depend plus d'Excel."""
    for nom in SCRIPTS_ORACLE:
        script = lire(nom)
        assert "Excel.Application" not in script
        assert "ReleaseComObject" not in script


def test_le_module_partage_reprend_la_palette_des_rapports():
    script = lire("rapport_excel.py")
    assert 'BLEU = "1F497D"' in script
    assert 'PECHE = "FCE4D6"' in script
    assert 'VERT = "EDEFDA"' in script
    assert "freeze_panes" in script
    assert "showGridLines = False" in script
    assert "auto_filter.ref" in script
