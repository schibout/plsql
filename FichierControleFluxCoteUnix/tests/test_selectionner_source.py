import os
from pathlib import Path

import pytest

from selectionner_source import ErreurSelection, detecter_flux, selectionner_source


@pytest.mark.parametrize(
    "type_flux,nom",
    [
        ("CLIENT", "PRN01_SRC_FACTURESCLIENTS_250826.csv"),
        ("FOURNISSEUR", "CEL01_SRC_FACTURESFOURNISSEURS_250826.csv"),
        ("GL", "VHC03_SRC_ECRITURESGL_250826.csv"),
    ],
)
def test_accepte_tous_les_prefixes_dans_source(tmp_path, type_flux, nom):
    source = tmp_path / "instance" / "SOURCE"
    source.mkdir(parents=True)
    attendu = source / nom
    attendu.write_text("test", encoding="ascii")

    assert selectionner_source(type_flux, tmp_path) == attendu.resolve()


def test_ignore_un_fichier_target_plus_recent(tmp_path):
    source = tmp_path / "instance" / "SOURCE"
    target = tmp_path / "instance" / "TARGET"
    source.mkdir(parents=True)
    target.mkdir(parents=True)
    attendu = source / "CEL01_SRC_FACTURESFOURNISSEURS_TEST.csv"
    parasite = target / "CEL01_SRC_FACTURESFOURNISSEURS_TEST.csv"
    attendu.write_text("source", encoding="ascii")
    parasite.write_text("target", encoding="ascii")
    os.utime(attendu, (1, 1))
    os.utime(parasite, (2, 2))

    assert selectionner_source("FOURNISSEUR", tmp_path) == attendu.resolve()


def test_selectionne_le_plus_recent_parmi_plusieurs_source(tmp_path):
    ancien = tmp_path / "instance1" / "SOURCE" / "FAC02_SRC_ECRITURESGL_ANCIEN.csv"
    recent = tmp_path / "instance2" / "SOURCE" / "FAC02_SRC_ECRITURESGL_RECENT.csv"
    ancien.parent.mkdir(parents=True)
    recent.parent.mkdir(parents=True)
    ancien.write_text("ancien", encoding="ascii")
    recent.write_text("recent", encoding="ascii")
    os.utime(ancien, (1, 1))
    os.utime(recent, (2, 2))

    assert selectionner_source("GL", tmp_path) == recent.resolve()


def test_accepte_un_dossier_source_comme_entree(tmp_path):
    source = tmp_path / "SOURCE"
    source.mkdir()
    attendu = source / "FAC02_SRC_FACTURESCLIENTS_TEST.csv"
    attendu.write_text("test", encoding="ascii")

    assert selectionner_source("CLIENT", source) == attendu.resolve()


def test_refuse_un_fichier_place_hors_source(tmp_path):
    fichier = tmp_path / "TARGET" / "FAC02_SRC_FACTURESCLIENTS_TEST.csv"
    fichier.parent.mkdir()
    fichier.write_text("test", encoding="ascii")

    with pytest.raises(ErreurSelection, match="SOURCE"):
        selectionner_source("CLIENT", fichier)


def test_refuse_un_type_de_flux_inconnu(tmp_path):
    with pytest.raises(ErreurSelection, match="inconnu"):
        selectionner_source("AUTRE", tmp_path)


def creer_src(tmp_path, dossier, nom):
    source = tmp_path / dossier / "export" / "SOURCE"
    source.mkdir(parents=True, exist_ok=True)
    fichier = source / nom
    fichier.write_text("test", encoding="ascii")
    return fichier


def test_detecte_le_flux_unique_d_un_dossier_d_export(tmp_path):
    attendu = creer_src(tmp_path, "10082026_FOURNISSEUR_CEG",
                        "CEL01_SRC_FACTURESFOURNISSEURS_TEST.csv")

    assert detecter_flux(tmp_path) == [("FOURNISSEUR", attendu.resolve())]


def test_detecte_tous_les_flux_d_un_dossier_parent(tmp_path):
    client = creer_src(tmp_path, "31072026_FAS", "FAC02_SRC_FACTURESCLIENTS_T.csv")
    frs = creer_src(tmp_path, "10082026_CEG", "CEL01_SRC_FACTURESFOURNISSEURS_T.csv")
    gl = creer_src(tmp_path, "04072026_GER", "FAC02_SRC_ECRITURESGL_T.csv")

    assert detecter_flux(tmp_path) == [
        ("CLIENT", client.resolve()),
        ("FOURNISSEUR", frs.resolve()),
        ("GL", gl.resolve()),
    ]


def test_detecte_tous_les_exports_d_un_meme_flux(tmp_path):
    """Un dossier de flux a plusieurs exports : chacun doit etre controle."""
    flux = "17082026_FOURNISSEUR_VFF"
    ancien = creer_src(tmp_path / flux, "export1",
                       "VHC03_SRC_FACTURESFOURNISSEURS_170826_134008.csv")
    recent = creer_src(tmp_path / flux, "export2",
                       "VHC03_SRC_FACTURESFOURNISSEURS_170826_161552.csv")
    os.utime(ancien, (1, 1))
    os.utime(recent, (2, 2))

    assert detecter_flux(tmp_path / flux) == [
        ("FOURNISSEUR", ancien.resolve()),
        ("FOURNISSEUR", recent.resolve()),
    ]


def test_detecter_sans_aucun_flux_est_une_erreur_explicite(tmp_path):
    with pytest.raises(ErreurSelection, match="aucun flux"):
        detecter_flux(tmp_path)
