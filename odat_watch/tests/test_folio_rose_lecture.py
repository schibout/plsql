"""Lecture des exports Folio Rose (règles de Verifier_Factures.ps1) sur les fichiers réels du dépôt."""
from datetime import date
from pathlib import Path

import pytest

import folio_rose as fr

RACINE = Path(__file__).resolve().parents[2] / "ControleFolioRose"
EXPORTS = sorted(RACINE.glob("sauvegarde/ExportCSV-*.csv")) + sorted(RACINE.glob("ExportCSV-*.csv"))


def _lignes_donnees(chemin: Path) -> int:
    octets = chemin.read_bytes()
    texte = octets.decode(fr.detecter_encodage(octets))
    lignes = texte.splitlines()
    if lignes and lignes[0].lstrip("﻿").startswith("Folio") and "Ecart" in lignes[0].split(";")[1:2]:
        lignes = lignes[2:]
    return sum(1 for l in lignes[1:] if l.replace(";", "").replace(",", "").strip())


@pytest.mark.parametrize("chemin", EXPORTS, ids=lambda p: p.name)
def test_lecture_export_reel(chemin):
    e = fr.lire_export(chemin)
    assert len(e.lignes) == _lignes_donnees(chemin)
    assert set(e.lignes["type"]) <= {"CLIENTS", "FOURNISSEURS", "GL", "AUTRE"}
    assert e.lignes["empreinte"].str.len().eq(40).all()
    assert e.periode_debut and e.periode_fin
    assert e.date_export == date(int(chemin.stem[16:20]), int(chemin.stem[13:15]), int(chemin.stem[10:12]))
    for c in ("folio", "fichier", "fichier_base", "ecart_debit", "amont_debit", "si_debit", "age_j"):
        assert c in e.lignes.columns


def test_regles_unitaires():
    assert fr.normaliser("App Amont Nb piéce ") == "app amont nb piece"
    assert fr.montant("1 234,56") == (1234.56, False)
    assert fr.montant("1 234,56") == (1234.56, False)
    assert fr.montant("-") == (0.0, False) and fr.montant("") == (0.0, False)
    assert fr.montant("abc") == (0.0, True)
    assert fr.montant("nan") == (0.0, True)
    assert fr.type_flux("HEF01_SRC_FACTURESCLIENTS_070826-011057_ST_HEF01_6392_001") == "CLIENTS"
    assert fr.type_flux("CEL01_SRC_FACTURESFOURNISSEURS_070826") == "FOURNISSEURS"
    assert fr.type_flux("CDPG_XXX") == "GL" and fr.type_flux("truc") == "AUTRE" and fr.type_flux("") == "AUTRE"
    assert fr.fichier_base("A_B_ST_HEF01_6392_001") == "A_B" and fr.fichier_base("A_B") == "A_B"
    assert fr.date_export_du_nom("ExportCSV-19-08-2026_16h00.csv") == date(2026, 8, 19)
    assert fr.date_export_du_nom("autre.csv") is None
    assert fr.date_export_du_nom("ExportCSV-32-13-2026.csv") is None


def test_empreinte_stable_entre_deux_exports():
    a = fr.lire_export(RACINE / "sauvegarde" / "ExportCSV-18-08-2026.csv").lignes
    b = fr.lire_export(RACINE / "sauvegarde" / "ExportCSV-19-08-2026.csv").lignes
    communes = set(a["empreinte"]) & set(b["empreinte"])
    assert len(communes) >= 10          # les exports se recouvrent largement
    la = a.drop_duplicates("empreinte").set_index("empreinte").loc[sorted(communes)]
    lb = b.drop_duplicates("empreinte").set_index("empreinte").loc[sorted(communes)]
    assert (la["folio"] == lb["folio"]).all() and (la["fichier"] == lb["fichier"]).all()


def test_empreintes_uniques_dans_un_export():
    for chemin in EXPORTS:
        e = fr.lire_export(chemin)
        assert not e.lignes["empreinte"].duplicated().any(), chemin.name


def test_empreinte_rang_stable():
    a = fr.lire_export(RACINE / "sauvegarde" / "ExportCSV-18-08-2026.csv").lignes
    b = fr.lire_export(RACINE / "sauvegarde" / "ExportCSV-19-08-2026.csv").lignes
    # la facture VFF 672,72 du 10/08 est présente deux fois dans les deux exports : mêmes deux empreintes
    da = a[(a["folio"] == "VFF") & (a["amont_debit"].sub(672.72).abs() < 0.005)]
    db_ = b[(b["folio"] == "VFF") & (b["amont_debit"].sub(672.72).abs() < 0.005)]
    assert len(da) == 2 and set(da["empreinte"]) == set(db_["empreinte"])


def test_colonnes_decalees_donnent_autre():
    contenu = ("Folio;Ecart;Début de période;Fin de période\nTous;Oui;01/01/2026;31/01/2026\n"
               "Folio;Date;App Amont Nb piéce;App Amont Débit;App Amont Crédit;SI Finance Nb piece;SI Finance Débit;"
               "SI Finance Crédit;Ecarts Nb Piece;Ecarts Débit;Ecarts Crédit;Commentaire;Nom fichier transmis\n"
               "ABC;10/01/2026;1;10;10;0;0;0;1;10;10;com;ment;aire;FAC02_SRC_FACTURESCLIENTS_X_ST_Y_001\n"
               "ABC;11/01/2026;0;0;0;1;10;10;-1;-10;-10;;FAC02_SRC_FACTURESCLIENTS_X_ST_Y_001\n\n").encode("utf-8-sig")
    e = fr.lire_export(contenu, "ExportCSV-31-01-2026.csv")
    assert len(e.lignes) == 2
    assert list(e.lignes["type"]) == ["AUTRE", "CLIENTS"]      # ';' dans le commentaire → fichier décalé
    assert e.lignes["age_j"].tolist() == [21, 20]


def test_colonnes_obligatoires_absentes():
    with pytest.raises(ValueError, match="Ecarts Débit"):
        fr.lire_export(b"Folio;Date\nA;1\n", "x.csv")
