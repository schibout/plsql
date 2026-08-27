"""Cascade source -> Oracle, sur les exports de reference du depot."""

from pathlib import Path

import pytest

import reconciliation


DOSSIER_SCRIPT = Path(__file__).resolve().parents[1]
EXPORT_FOURNISSEURS = DOSSIER_SCRIPT / "26082026_FOURNISSEURS_HAF"
EXPORT_CLIENTS = DOSSIER_SCRIPT / "27082026_CLIENTS_GCA"
EXPORT_GL = DOSSIER_SCRIPT / "27082026_GL_GER"

# Tous les exports presents dans le depot, pour verifier qu'aucun ne provoque
# d'erreur technique et qu'aucun ecart ne reste inexplique.
TOUS_LES_EXPORTS = sorted(
    chemin
    for chemin in DOSSIER_SCRIPT.iterdir()
    if chemin.is_dir()
    and len(chemin.name) > 9
    and chemin.name[:8].isdigit()
    and chemin.name[8] == "_"
)


def cascade(resultat, fragment):
    for element in resultat.cascades:
        if fragment in element.fichier:
            return element
    pytest.fail("aucune cascade pour %s" % fragment)


def test_cascade_fournisseurs_avec_rejets():
    """Le SRC moins les lignes rejetees doit egaler ce que Talend a publie."""
    resultat = reconciliation.reconcilier(EXPORT_FOURNISSEURS)
    element = cascade(resultat, "20260826_205624")

    assert element.nb_src == 153
    assert element.nb_lignes_rejetees == 12
    assert element.nb_publies == 141
    assert element.nb_cible == 141
    assert element.nb_src - element.nb_lignes_rejetees == element.nb_publies
    assert element.nb_pieces_rejetees == 4
    assert element.diagnostic == reconciliation.INTEGRE_PARTIEL_REJETS
    assert element.codes_rejets == "OAE025"


def test_les_montants_bouclent_aussi():
    """Montant du SRC moins montant rejete = montant parti vers Oracle."""
    element = cascade(
        reconciliation.reconcilier(EXPORT_FOURNISSEURS), "20260826_205624"
    )

    assert element.montant_src == 75_292_611
    assert element.montant_rejete == 15_587_987
    assert element.montant_src - element.montant_rejete == element.montant_cible


def test_cascade_fournisseurs_sans_rejet():
    element = cascade(
        reconciliation.reconcilier(EXPORT_FOURNISSEURS), "20260826_210251"
    )

    assert element.nb_src == element.nb_publies == element.nb_cible == 6
    assert element.nb_pieces_rejetees == 0
    assert element.diagnostic == reconciliation.INTEGRE_COMPLET


def test_cascade_clients_complete():
    resultat = reconciliation.reconcilier(EXPORT_CLIENTS)
    element = resultat.cascades[0]

    assert element.type_flux == "CLIENT"
    assert element.nb_src == element.nb_cible == element.nb_publies == 10283
    # Le fichier amont ecrit les centimes en entier, le fichier repris avec
    # deux decimales : les deux etages doivent malgre tout se retrouver.
    assert element.montant_src == element.montant_cible == 1_296_593_449
    assert element.diagnostic == reconciliation.INTEGRE_COMPLET
    assert resultat.code_retour == reconciliation.EXIT_OK


def test_cascade_gl_sans_demi_flux2():
    """Sans demi-flux 2, le pivot GL fait foi et le diagnostic le dit."""
    resultat = reconciliation.reconcilier(EXPORT_GL)
    element = resultat.cascades[0]

    assert element.type_flux == "GL"
    assert element.nb_src == element.nb_cible == 62
    assert element.diagnostic == reconciliation.DEMI_FLUX2_ABSENT
    assert "Verifier_Oracle_Ecritures_GL.ps1" in element.explication
    assert resultat.code_retour == reconciliation.EXIT_ANOMALIE


@pytest.mark.parametrize(
    "entree",
    [
        EXPORT_FOURNISSEURS,
        EXPORT_FOURNISSEURS / "SOURCE",
        EXPORT_FOURNISSEURS / "SOURCE" / "3f248e34a4ce44619d3ab5e0f1824535",
        EXPORT_FOURNISSEURS / "TARGET" / "3f248e34a4ce44619d3ab5e0f1824535" / "TMP",
    ],
)
def test_dossier_export_retrouve_depuis_n_importe_quel_niveau(entree):
    """Les lanceurs passent un chemin de fichier SRC, pas le dossier d'export."""
    assert reconciliation.dossier_export(entree) == EXPORT_FOURNISSEURS.resolve()


def test_dossier_export_depuis_un_fichier_src():
    src = next(
        (EXPORT_GL / "SOURCE").glob("*/SOURCE/*_SRC_*")
    )

    assert reconciliation.dossier_export(src) == EXPORT_GL.resolve()


@pytest.mark.parametrize("export", TOUS_LES_EXPORTS, ids=lambda p: p.name)
def test_aucun_export_du_depot_ne_reste_inexplique(export):
    """Garde-fou : chaque export se lit et sa cascade boucle."""
    resultat = reconciliation.reconcilier(export)

    assert resultat.cascades
    for element in resultat.cascades:
        assert element.diagnostic != reconciliation.ECART_INEXPLIQUE, (
            "%s / %s : %s" % (export.name, element.fichier, element.explication)
        )


def test_sortie_csv_exploitable_par_powershell():
    resultat = reconciliation.reconcilier(EXPORT_FOURNISSEURS)
    lignes = reconciliation.lignes_csv(resultat)

    assert len(lignes) == len(resultat.cascades)
    assert all(len(ligne) == len(reconciliation.COLONNES_CSV) for ligne in lignes)
    # Les montants suivent la convention francaise des rapports du depot.
    assert lignes[0][reconciliation.COLONNES_CSV.index("Montant SRC")] == "752926,11"
    assert lignes[0][reconciliation.COLONNES_CSV.index("Diagnostic")] == (
        reconciliation.INTEGRE_PARTIEL_REJETS
    )


def test_onglets_du_rapport():
    onglets = reconciliation.onglets(reconciliation.reconcilier(EXPORT_FOURNISSEURS))

    assert [onglet["nom"] for onglet in onglets] == [
        "Cascade", "Rejets", "Statuts Talend"
    ]
    rejets = next(o for o in onglets if o["nom"] == "Rejets")
    assert len(rejets["lignes"]) == 4
    assert rejets["lignes"][0]["Code"] == "OAE025"
    # Excel doit recevoir des nombres, pas du texte formate.
    cascade_onglet = next(o for o in onglets if o["nom"] == "Cascade")
    assert cascade_onglet["lignes"][0]["Montant SRC"] == 752926.11


def test_dossier_sans_flux_signale_une_erreur(tmp_path):
    with pytest.raises(reconciliation.ErreurReconciliation):
        reconciliation.reconcilier(tmp_path)


def test_index_des_rejets_pour_le_detail_oracle():
    """Les scripts Verifier_Oracle_*.ps1 cherchent la piece en majuscules."""
    index = reconciliation.index_rejets(
        reconciliation.reconcilier(EXPORT_FOURNISSEURS)
    )

    assert set(index) == {
        "VLF26G0026", "2026-07-VCOM 342", "2026-07-VCOM 341", "2026-07-VCOM 338"
    }
    assert all(cle == cle.upper() for cle in index)
    assert index["VLF26G0026"]["code"] == "OAE025"
    assert index["VLF26G0026"]["libelle"] == "Site Fournisseur inactif ou inexistant"
    assert index["VLF26G0026"]["appel"].startswith("XXEAI_INTERFACE_TOOLS_PKG")


def test_index_des_rejets_vide_sans_demi_flux2():
    assert reconciliation.index_rejets(reconciliation.reconcilier(EXPORT_GL)) == {}


def test_json_des_rejets_relisible(tmp_path):
    import json

    destination = tmp_path / "rejets.json"
    reconciliation.ecrire_rejets_json(
        reconciliation.reconcilier(EXPORT_FOURNISSEURS), destination
    )
    donnees = json.loads(destination.read_text(encoding="utf-8"))

    assert donnees["exports"] == [EXPORT_FOURNISSEURS.name]
    assert len(donnees["rejets"]) == 4


def test_consolidation_de_plusieurs_exports():
    resultats = reconciliation.reconcilier_tous(DOSSIER_SCRIPT)

    assert len(resultats) == len(TOUS_LES_EXPORTS)
    assert len(reconciliation.lignes_csv(resultats)) == sum(
        len(r.cascades) for r in resultats
    )
