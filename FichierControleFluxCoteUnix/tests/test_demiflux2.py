"""Lecture du second demi-flux, sur les exports de reference du depot."""

from pathlib import Path

import pytest

import demiflux2


DOSSIER_SCRIPT = Path(__file__).resolve().parents[1]
EXPORT_FOURNISSEURS = DOSSIER_SCRIPT / "26082026_FOURNISSEURS_HAF"
EXPORT_CLIENTS = DOSSIER_SCRIPT / "27082026_CLIENTS_GCA"
EXPORT_GL = DOSSIER_SCRIPT / "27082026_GL_GER"

INSTANCE_HAF_REJETS = "3f248e34a4ce44619d3ab5e0f1824535"


def instance(export, guid):
    for candidate in demiflux2.trouver_instances(export):
        if candidate.guid == guid:
            return candidate
    pytest.skip("instance %s absente de %s" % (guid, export.name))


def test_instances_fournisseurs_reconnues():
    instances = demiflux2.trouver_instances(EXPORT_FOURNISSEURS)

    assert {i.guid for i in instances} == {
        INSTANCE_HAF_REJETS,
        "7a7b4f4c5aaf4bfaa09787a381dfd076",
    }
    assert {i.type_flux for i in instances} == {"FOURNISSEUR"}


def test_fichier_repris_est_le_src_et_jamais_le_ctl():
    """Le dossier SOURCE du demi-flux 2 contient aussi le fichier CTL."""
    repris = demiflux2.fichier_repris(instance(EXPORT_FOURNISSEURS, INSTANCE_HAF_REJETS))

    assert "_SRC_" in repris.name
    assert "_CTL_" not in repris.name


def test_export_gl_sans_demi_flux2():
    """Les exports GL ne rapatrient pas le second demi-flux : ce n'est pas une erreur."""
    assert demiflux2.trouver_instances(EXPORT_GL) == []


def test_statut_talend_et_nombre_publie():
    statut = demiflux2.lire_statut(instance(EXPORT_FOURNISSEURS, INSTANCE_HAF_REJETS))

    assert statut.ls == "WARNING"
    assert statut.ts == "OK"
    assert statut.nb_publies == 141
    # Un WARNING signale des rejets fonctionnels : la publication a bien eu lieu.
    assert statut.abouti


def test_rejets_regroupes_par_piece():
    rejets = demiflux2.lire_rejets(instance(EXPORT_FOURNISSEURS, INSTANCE_HAF_REJETS))
    pieces = demiflux2.grouper_rejets(rejets)

    assert len(rejets) == 12
    assert len(pieces) == 4
    assert {p.code for p in pieces} == {"OAE025"}
    assert all(p.libelle == "Site Fournisseur inactif ou inexistant" for p in pieces)
    assert all(
        p.appel == "XXEAI_INTERFACE_TOOLS_PKG.Get_Info_Invoice_Header" for p in pieces
    )
    assert sum(p.nb_lignes for p in pieces) == len(rejets)


def test_rejets_conformes_aux_pieces_en_erreur_de_tmp():
    cible = instance(EXPORT_FOURNISSEURS, INSTANCE_HAF_REJETS)
    pieces = {p.piece for p in demiflux2.grouper_rejets(demiflux2.lire_rejets(cible))}

    assert pieces == set(demiflux2.lire_erreurs_tmp(cible))


def test_cible_ap_egale_le_nombre_publie():
    """Header + Line reconstituent exactement le compteur Talend."""
    cible_instance = instance(EXPORT_FOURNISSEURS, INSTANCE_HAF_REJETS)
    cible = demiflux2.lire_cible(cible_instance)

    assert cible.nb_entetes == 46
    assert cible.nb_lignes == 95
    assert cible.nb_enregistrements == 141
    assert cible.nb_enregistrements == demiflux2.lire_statut(cible_instance).nb_publies
    assert cible.montant == 59_704_624
    assert cible.par_folio == {"HAF": 46}


def test_cible_ar_egale_le_nombre_publie():
    cible_instance = demiflux2.trouver_instances(EXPORT_CLIENTS)[0]
    cible = demiflux2.lire_cible(cible_instance)

    assert cible.nb_enregistrements == 10283
    assert cible.nb_enregistrements == demiflux2.lire_statut(cible_instance).nb_publies
    # Totaux par portefeuille du fichier CTL amont, en centimes.
    assert cible.montant_par_portefeuille["GCA"] == 854_956_690
    assert cible.nb_par_portefeuille["SVD"] == 289


def test_cible_gl_equilibree():
    pivots = demiflux2.fichiers_pivot_gl(EXPORT_GL)
    cible = demiflux2.lire_cible_gl(pivots[0])

    assert len(pivots) == 1
    assert cible.nb_lignes == 62
    assert cible.equilibre
    assert cible.debit == cible.credit
    assert set(cible.nb_par_origine) == {"GER", "FGE"}


@pytest.mark.parametrize(
    "texte, attendu",
    [
        ("151,96", 15196),          # ecriture francaise, demi-flux 1
        ("151.96", 15196),          # ecriture anglaise, demi-flux 2
        ("", 0),
        ("   ", 0),
        ("abc", 0),                 # montant illisible : compte pour zero
        ("-37 736,77", -3773677),   # separateur de milliers
    ],
)
def test_conversion_des_montants(texte, attendu):
    assert demiflux2.centimes(texte) == attendu


@pytest.mark.parametrize(
    "nom, attendu",
    [
        ("FAC02_SRC_FACTURESCLIENTS_270826.csv", "CLIENT"),
        ("PRN01_SRC_FACTURESFOURNISSEURS_20260826.txt", "FOURNISSEUR"),
        ("FAC02_SRC_ECRITURESGL_270826.csv", "GL"),
        ("FIN01_SRC_ECRITURESCOMPTABLES_20260328.csv", "GL"),
        ("CLES_FONCTIONNELLES.csv", None),
    ],
)
def test_deduction_du_type_de_flux(nom, attendu):
    assert demiflux2.deduire_type(nom) == attendu


def test_rejet_dont_la_ligne_source_contient_des_points_virgules(tmp_path):
    """Le 8e champ porte la ligne source entiere : elle ne doit pas etre decoupee."""
    instance_test = demiflux2.Instance(
        guid="test", chemin=tmp_path, type_flux="FOURNISSEUR"
    )
    cible = tmp_path / "TARGET"
    cible.mkdir()
    ligne_source = "26/08/2026;0367;401100;78936;GN1;HAF;LIB;0,1;STANDARD;10,00"
    (cible / "REJETS_FONCTIONNELS_20260827-090228.csv").write_text(
        "20260827-090228|OAE025|Site inactif|PIRENE|FLUX.FIN01|FIC|txt|%s"
        "|XXEAI_INTERFACE_TOOLS_PKG.Get_Info_Invoice_Header|VLF26G0026\n"
        % ligne_source,
        encoding="latin-1",
    )

    rejets = demiflux2.lire_rejets(instance_test)

    assert len(rejets) == 1
    assert rejets[0].ligne_source == ligne_source
    assert rejets[0].piece == "VLF26G0026"
