import os
from pathlib import Path

import pytest

from selectionner_source import ErreurSelection, selectionner_source


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
