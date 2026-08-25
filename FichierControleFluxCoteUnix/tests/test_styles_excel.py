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


def test_rapports_oracle_clients_et_fournisseurs_sont_harmonises():
    for nom in (
        "Verifier_Oracle_FAC02_Client.ps1",
        "Verifier_Oracle_FAC02_Fournisseur.ps1",
    ):
        script = lire(nom)
        assert "$COULEUR_ENTETE   = 0x7D491F" in script
        assert "$COULEUR_ANOMALIE = 0xD6E4FC" in script
        assert "$COULEUR_OK       = 0xDAEFED" in script
        assert "DisplayGridlines = $false" in script
        assert "FreezePanes = $true" in script
        assert "AutoFilter()" in script
