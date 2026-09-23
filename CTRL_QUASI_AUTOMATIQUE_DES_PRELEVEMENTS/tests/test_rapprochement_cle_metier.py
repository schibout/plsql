"""Tests du rapprochement par cle metier.

Chaque test est adosse a un cas reellement present dans les donnees de
production : les jeux d'essai reproduisent la structure exacte des fichiers.
"""
import json
import sys
from datetime import date
from decimal import Decimal
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from rapprochement_cle_metier import (  # noqa: E402
    ErreurTraitement, Diagnostic, apparier_rejets, charger_edf, charger_oracle,
    charger_rejets, construire_rapprochement, date_us, date_fr, montant_edf,
    montant_oracle, statut_cle, AgregatEdf, Tranche, LigneRejet,
    ECART_PARTIEL, EDF_SANS_ORACLE, EN_ATTENTE, EXPLIQUE_PAR_REJET,
    HORS_PERIMETRE_HISTORIQUE, NON_RECU, RAPPROCHE, RAPPROCHE_REJET_POSTERIEUR,
    REJET_PARTIEL_NON_CONFIRME, REJETE_INTEGRALEMENT, executer, detecter_doublons,
)

# --- Construction des jeux d'essai ----------------------------------------
COLONNES = [
    "FORMAT1ENTITYID", "COUNTERPARTYID", "VALUEDATE", "TRANSACTIONDATE",
    "CURRENCYCODE", "AMOUNT", "CASHFLOWTYPE", "PAYMENTMETHOD",
    "DESCRIPTION/REFERENCE", "CUSTOMERREFERENCENUMBER",
    "CUSTOMERTRANSACTIONREFERENCEID", "ENTITYBANKACCOUNTNUMBER",
]
COLONNES += [f"COL{i}" for i in range(12, 24)]
COLONNES += ["COUNTERPARTYBANKACCOUNTNUMBER"]
COLONNES += [f"COL{i}" for i in range(25, 44)]
COLONNES += ["SEPAMANDATEID"]
COLONNES += [f"COL{i}" for i in range(45, 55)]
assert len(COLONNES) == 55
IDX = {nom: i for i, nom in enumerate(COLONNES)}
# COUNTERPARTYNAME est requis par le chargeur : on le pose sur une colonne libre.
COLONNES[14] = "COUNTERPARTYNAME"
IDX = {nom: i for i, nom in enumerate(COLONNES)}


_COMPTEUR_REF = [0]


def ligne_oracle(iban, echeance_us, montant, rum="NVOA0001", debiteur="FR7611111111111",
                 nom="BENEF", nb_champs=55, reference=None):
    champs = [""] * 55
    if reference is None:
        _COMPTEUR_REF[0] += 1
        reference = f"P{_COMPTEUR_REF[0]:05d} 260906 C00000700 S0001DSW"
    champs[IDX["DESCRIPTION/REFERENCE"]] = reference
    champs[IDX["FORMAT1ENTITYID"]] = "0001"
    champs[IDX["TRANSACTIONDATE"]] = echeance_us
    champs[IDX["VALUEDATE"]] = echeance_us
    champs[IDX["AMOUNT"]] = montant
    champs[IDX["ENTITYBANKACCOUNTNUMBER"]] = iban
    champs[IDX["SEPAMANDATEID"]] = rum
    champs[IDX["COUNTERPARTYBANKACCOUNTNUMBER"]] = debiteur
    champs[IDX["COUNTERPARTYNAME"]] = nom
    return ",".join(champs[:nb_champs])


def ecrire_oracle(racine, dossier, nom_fichier, lignes):
    d = racine / "ORACLE" / dossier
    d.mkdir(parents=True, exist_ok=True)
    contenu = ["HEADER,DK_0001,DD,", ",".join(COLONNES)] + lignes
    (d / nom_fichier).write_text("\n".join(contenu), encoding="latin-1")


def ecrire_edf(racine, date_fichier, lignes_si):
    d = racine / "EDF"
    d.mkdir(parents=True, exist_ok=True)
    contenu = ["", "ETAT DES RECEPTIONS", "NOM DU SI DALKIA;IBAN CREANCIER;DATE D'ECHEANCE;NOMBRE;MONTANT TOTAL;"]
    contenu += lignes_si
    (d / f"IMPORT_AVP_DK.{date_fichier}.070100.csv").write_text(
        "\n".join(contenu), encoding="latin-1")


def ecrire_rejets(racine, date_fichier, lignes):
    d = racine / "EDF" / "REJETS"
    d.mkdir(parents=True, exist_ok=True)
    contenu = ["", "LISTE DES REJETS INTERNES",
               "IBAN CREANCIER;RUM;IBAN DEBITEUR;DATE D'ECHEANCE;MONTANT;CODE REJET;MOTIF DU REJET;"]
    contenu += lignes
    (d / f"REJETS_INTERNES_DK.{date_fichier}.070000.csv").write_text(
        "\n".join(contenu), encoding="latin-1")


MOTIFS = ["*PCX*", "*PCL*"]
IBAN_A = "FR7630003011120002001135658"
IBAN_B = "FR7630004008280001264604376"


# --- Conversions ------------------------------------------------------------
def test_dates_oracle_et_edf_ont_des_conventions_opposees():
    # Oracle MM/JJ/AAAA, EDF JJ/MM/AAAA : la meme journee s'ecrit differemment.
    assert date_us("07/10/2026") == date(2026, 7, 10)
    assert date_fr("10/07/2026") == date(2026, 7, 10)


def test_montants_refusent_le_separateur_de_l_autre_source():
    assert montant_oracle("546.33") == Decimal("546.33")
    assert montant_edf("546,33") == Decimal("546.33")
    with pytest.raises(Exception):
        montant_oracle("546,33")
    with pytest.raises(Exception):
        montant_edf("1234.56")


# --- 1. Dossier a dates d'emission mixtes (cas ORACLE/20260626) -------------
def test_date_emission_vient_du_nom_de_fichier_pas_du_dossier(tmp_path):
    ecrire_oracle(tmp_path, "20260626", "DK_30003-0001DLSPCLFRST-20260629-48278459_20260629-015707.txt",
                  [ligne_oracle(IBAN_A, "07/31/2026", "100.00")])
    ecrire_oracle(tmp_path, "20260626", "DK_30003-0001DLSPCLRCUR-20260627-48278459_20260627-015707.txt",
                  [ligne_oracle(IBAN_A, "07/31/2026", "200.00")])

    lignes, ko = charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())
    assert ko == []
    assert {l.emission for l in lignes} == {date(2026, 6, 29), date(2026, 6, 27)}


# --- 2. Cle presente dans plusieurs fichiers EDF : les tranches se somment ---
def test_cle_sur_plusieurs_fichiers_edf_est_sommee(tmp_path):
    ecrire_edf(tmp_path, "20260727", [f"ORACLE;{IBAN_A};10/08/2026;0000000102;1000,00;"])
    ecrire_edf(tmp_path, "20260806", [f"ORACLE;{IBAN_A};10/08/2026;0000000001;10,00;"])

    agregats, dates = charger_edf(tmp_path / "EDF", "IMPORT_AVP_DK.*.*.csv", "ORACLE", Diagnostic())
    agg = agregats[(IBAN_A, date(2026, 8, 10))]
    assert agg.nb == 103          # et non 1 : ce sont des remontees incrementales
    assert agg.montant == Decimal("1010.00")
    assert len(agg.tranches) == 2
    assert dates == [date(2026, 7, 27), date(2026, 8, 6)]


# --- 3 et 4. Dedoublonnage des rejets --------------------------------------
def test_rejet_republie_a_l_identique_est_compte_une_fois(tmp_path):
    rejet = f"{IBAN_B};NVCI0003392620230414001;FR7615135001800400386505735;04/08/2026;150,00;CC01;MANDAT INVALIDE;"
    ecrire_rejets(tmp_path, "20260720", [rejet])
    ecrire_rejets(tmp_path, "20260724", [rejet])

    diag = Diagnostic()
    rejets = charger_rejets(tmp_path / "EDF" / "REJETS", "REJETS_INTERNES_DK.*.csv", diag)
    assert len(rejets) == 1
    assert diag.rejets_dupliques == 1


def test_meme_rum_sur_deux_echeances_reste_deux_rejets(tmp_path):
    ecrire_rejets(tmp_path, "20260720", [
        f"{IBAN_A};NVOA0136895605062026001;FR7611111111111;04/08/2026;150,00;CC01;MANDAT INVALIDE;",
        f"{IBAN_A};NVOA0136895605062026001;FR7611111111111;10/08/2026;150,00;CC01;MANDAT INVALIDE;",
    ])
    rejets = charger_rejets(tmp_path / "EDF" / "REJETS", "REJETS_INTERNES_DK.*.csv", Diagnostic())
    assert len(rejets) == 2


# --- 5. IBAN creancier partage entre CIF et ORACLE --------------------------
def test_rejet_attribue_au_bon_si_via_le_rum(tmp_path):
    """Les fichiers de rejets ne portent pas le nom du SI et certains IBAN
    creanciers sont partages : seul le RUM permet de trancher."""
    partage = "FR7630004003420002010707342"
    ecrire_oracle(tmp_path, "20260724", "DK_x-PCL-20260725-1_20260725-01.txt",
                  [ligne_oracle(partage, "08/10/2026", "500.00", rum="NVOA0000111")])
    ecrire_rejets(tmp_path, "20260728", [
        f"{partage};NVOA0000111;FR7611111111111;10/08/2026;500,00;CC01;MANDAT INVALIDE;",
        f"{partage};NVCI0009999;FR7622222222222;10/08/2026;300,00;CC01;MANDAT INVALIDE;",
    ])

    lignes, _ = charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())
    rejets = charger_rejets(tmp_path / "EDF" / "REJETS", "REJETS_INTERNES_DK.*.csv", Diagnostic())
    apparies = apparier_rejets(lignes, rejets)

    assert [r.rum for r in apparies[(partage, date(2026, 8, 10))]] == ["NVOA0000111"]
    assert [r.appariee for r in rejets] == [True, False]   # le rejet CIF est ecarte


# --- 6. Rejet posterieur a la remontee EDF ---------------------------------
def test_rejet_posterieur_signale_meme_si_les_totaux_concordent():
    """EDF est net des rejets CONNUS a l'instant ou la ligne est produite.
    Un rejet arrive apres laisse les totaux conformes, mais le prelevement
    echouera : le metier doit le voir."""
    edf = AgregatEdf(nb=1, montant=Decimal("100.00"),
                     tranches=[Tranche(date(2026, 6, 24), 1, Decimal("100.00"))])
    rejet = LigneRejet(IBAN_A, "NVOA1", "FR76", date(2026, 7, 10), Decimal("636.50"),
                       "CC02", "MOTIF", "f.csv", date(2026, 6, 26))

    statut, ecart_nb, ecart_mt = statut_cle(
        1, Decimal("100.00"), edf, [rejet], date(2026, 6, 22),
        [date(2026, 6, 24)], date(2026, 8, 6), date(2026, 6, 20), date(2026, 7, 10))

    assert statut == RAPPROCHE_REJET_POSTERIEUR
    assert (ecart_nb, ecart_mt) == (0, Decimal(0))


# --- 7. Ligne Oracle non conforme ------------------------------------------
def test_ligne_a_54_champs_est_ecartee_et_tracee(tmp_path):
    ecrire_oracle(tmp_path, "20260724", "DK_x-PCL-20260725-1_20260725-01.txt", [
        ligne_oracle(IBAN_A, "08/10/2026", "100.00"),
        ligne_oracle(IBAN_A, "08/10/2026", "200.00", nb_champs=54),
    ])
    lignes, ko = charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())
    assert len(lignes) == 1
    assert len(ko) == 1
    assert "54 champs" in ko[0]["motif"]


def test_iban_creancier_invalide_est_ecarte(tmp_path):
    """Une virgule saisie dans une reference decale la cle : on valide l'IBAN
    plutot que de faire confiance a la position."""
    ecrire_oracle(tmp_path, "20260724", "DK_x-PCL-20260725-1_20260725-01.txt",
                  [ligne_oracle("PAS_UN_IBAN", "08/10/2026", "100.00")])
    lignes, ko = charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())
    assert lignes == []
    assert "IBAN creancier invalide" in ko[0]["motif"]


def test_entete_sans_colonne_requise_est_fatale(tmp_path):
    d = tmp_path / "ORACLE" / "20260724"
    d.mkdir(parents=True)
    (d / "DK_x-PCL-20260725-1_20260725-01.txt").write_text(
        "HEADER,x,DD,\nFORMAT1ENTITYID,AMOUNT\n", encoding="latin-1")
    with pytest.raises(ErreurTraitement, match="Colonnes absentes"):
        charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())


# --- 8. Seuil EN_ATTENTE / NON_RECU sur le comptage de fichiers EDF ---------
@pytest.mark.parametrize("nb_fichiers_posterieurs, attendu", [
    (0, EN_ATTENTE), (1, EN_ATTENTE), (2, EN_ATTENTE), (3, NON_RECU), (5, NON_RECU)])
def test_seuil_attente_compte_les_fichiers_edf_pas_les_jours(nb_fichiers_posterieurs, attendu):
    """Regle immunisee contre les jours feries : EDF n'a produit aucun fichier
    les 13, 14 et 16/07, ce qui fausserait toute arithmetique calendaire."""
    emission = date(2026, 7, 1)
    dates_edf = [date(2026, 7, 2 + i) for i in range(nb_fichiers_posterieurs)]
    statut, _, _ = statut_cle(1, Decimal("100.00"), None, [], emission,
                              dates_edf, date(2026, 8, 6), date(2026, 6, 1), date(2026, 7, 31))
    assert statut == attendu


# --- Machine a etats : les autres branches ---------------------------------
def _edf(nb, montant, jour=27):
    return AgregatEdf(nb=nb, montant=Decimal(montant),
                      tranches=[Tranche(date(2026, 7, jour), nb, Decimal(montant))])


def test_totaux_egaux_sans_rejet_est_rapproche():
    s, _, _ = statut_cle(3, Decimal("300.00"), _edf(3, "300.00"), [], date(2026, 7, 24),
                         [], date(2026, 8, 6), date(2026, 6, 23), date(2026, 8, 10))
    assert s == RAPPROCHE


def test_ecart_egal_aux_rejets_est_explique():
    rejet = LigneRejet(IBAN_A, "R", "FR76", date(2026, 8, 10), Decimal("100.00"),
                       "CC01", "M", "f", date(2026, 7, 28))
    s, ecart_nb, ecart_mt = statut_cle(4, Decimal("400.00"), _edf(3, "300.00"), [rejet],
                                       date(2026, 7, 24), [], date(2026, 8, 6),
                                       date(2026, 6, 23), date(2026, 8, 10))
    assert s == EXPLIQUE_PAR_REJET
    assert (ecart_nb, ecart_mt) == (-1, Decimal("-100.00"))


def test_ecart_non_couvert_par_les_rejets_est_partiel():
    rejet = LigneRejet(IBAN_A, "R", "FR76", date(2026, 8, 10), Decimal("50.00"),
                       "CC01", "M", "f", date(2026, 7, 28))
    s, _, _ = statut_cle(4, Decimal("400.00"), _edf(3, "300.00"), [rejet],
                         date(2026, 7, 24), [], date(2026, 8, 6),
                         date(2026, 6, 23), date(2026, 8, 10))
    assert s == ECART_PARTIEL


def test_montant_faux_a_nombre_egal_n_est_pas_rapproche():
    """Le statut porte sur le couple (nombre, montant) : un ecart au centime
    a nombre identique doit ressortir."""
    s, _, _ = statut_cle(3, Decimal("300.00"), _edf(3, "299.99"), [], date(2026, 7, 24),
                         [], date(2026, 8, 6), date(2026, 6, 23), date(2026, 8, 10))
    assert s == ECART_PARTIEL


def test_tout_rejete_donne_rejete_integralement():
    rejet = LigneRejet(IBAN_A, "R", "FR76", date(2026, 8, 20), Decimal("1132.11"),
                       "CC02", "M", "f", date(2026, 8, 5))
    s, _, _ = statut_cle(1, Decimal("1132.11"), None, [rejet], date(2026, 8, 4),
                         [], date(2026, 8, 6), date(2026, 6, 23), date(2026, 8, 20))
    assert s == REJETE_INTEGRALEMENT


def test_rejet_partiel_sans_remontee_edf_est_signale():
    rejet = LigneRejet(IBAN_A, "R", "FR76", date(2026, 8, 20), Decimal("100.00"),
                       "CC02", "M", "f", date(2026, 8, 5))
    s, _, _ = statut_cle(3, Decimal("300.00"), None, [rejet], date(2026, 8, 4),
                         [], date(2026, 8, 6), date(2026, 6, 23), date(2026, 8, 20))
    assert s == REJET_PARTIEL_NON_CONFIRME


def test_edf_sans_oracle_est_une_anomalie_si_l_emission_etait_couverte():
    s, _, _ = statut_cle(0, Decimal(0), _edf(2, "200.00", jour=27), [], None,
                         [], date(2026, 8, 6), date(2026, 6, 23), date(2026, 8, 10))
    assert s == EDF_SANS_ORACLE


def test_edf_sans_oracle_est_non_concluant_au_bord_de_l_historique():
    """Une remontee EDF datee du debut de l'archive confirme une emission
    anterieure a celle-ci : on ne peut ni la trouver ni l'incriminer."""
    edf = AgregatEdf(nb=1, montant=Decimal("12076.15"),
                     tranches=[Tranche(date(2026, 6, 23), 1, Decimal("12076.15"))])
    s, _, _ = statut_cle(0, Decimal(0), edf, [], None, [], date(2026, 8, 6),
                         date(2026, 6, 23), date(2026, 7, 30))
    assert s == HORS_PERIMETRE_HISTORIQUE


# --- Perimetre --------------------------------------------------------------
def test_la_fenetre_porte_sur_l_echeance_et_non_sur_les_fichiers():
    """Une cle peut etre emise sur des lots separes de 17 jours : fenetrer les
    fichiers en couperait une tranche et fabriquerait un ecart massif."""
    from rapprochement_cle_metier import LigneOracle
    lignes = [
        LigneOracle(IBAN_A, date(2026, 8, 10), Decimal("100.00"), "R1", "FR76", "N",
                    date(2026, 7, 23), "f1"),
        LigneOracle(IBAN_A, date(2026, 8, 10), Decimal("10.00"), "R2", "FR76", "N",
                    date(2026, 8, 4), "f2"),
    ]
    agregats = {(IBAN_A, date(2026, 8, 10)): _edf(2, "110.00")}
    res = construire_rapprochement(lignes, agregats, {}, [], date(2026, 8, 6), 10)

    assert len(res) == 1
    # Les deux tranches d'emission sont agregees malgre 12 jours d'ecart.
    assert res[0]["nb_oracle"] == 2
    assert res[0]["statut"] == RAPPROCHE
    assert res[0]["emissions"] == "23/07/2026 + 04/08/2026"


def test_echeance_hors_fenetre_est_exclue():
    from rapprochement_cle_metier import LigneOracle
    lignes = [LigneOracle(IBAN_A, date(2026, 1, 15), Decimal("100.00"), "R", "FR76", "N",
                          date(2026, 1, 1), "f")]
    res = construire_rapprochement(lignes, {}, {}, [], date(2026, 8, 6), 10)
    assert res == []


# --- Justification des ecarts ----------------------------------------------
def _contexte_rejet(montant_rejet="932.25", nb_oracle=21, montant_oracle="24703.22",
                    nb_edf=20, montant_edf="23770.97"):
    """Reproduit le cas reel FR7630003012070002018665043 / echeance 10/07."""
    from rapprochement_cle_metier import LigneOracle
    ech = date(2026, 7, 10)
    lignes = [LigneOracle(IBAN_A, ech, Decimal(montant_rejet), "NVOA0147", "FR7610096",
                          "SDC ALTAIR", date(2026, 6, 23),
                          "DK_30003-0441DMSPCLFRST-20260623-48278459_20260623-015707.txt")]
    lignes += [LigneOracle(IBAN_A, ech, Decimal("1.00"), f"RUM{i}", "FR76", f"B{i}",
                           date(2026, 6, 23), "autre_fichier.txt")
               for i in range(nb_oracle - 1)]
    # On force les totaux attendus via un agregat EDF construit a la main.
    agg = AgregatEdf(nb=nb_edf, montant=Decimal(montant_edf),
                     tranches=[Tranche(date(2026, 6, 24), nb_edf, Decimal(montant_edf),
                                       "IMPORT_AVP_DK.20260624.070103.csv")])
    rejet = LigneRejet(IBAN_A, "NVOA0147", "FR7610096", ech, Decimal(montant_rejet),
                       "CC01", "MANDAT INVALIDE",
                       "REJETS_INTERNES_DK.20260624.070002.csv", date(2026, 6, 24))
    rejet.appariee = True
    rejet.origine = lignes[0]
    return lignes, {(IBAN_A, ech): agg}, {(IBAN_A, ech): [rejet]}


def test_justification_nomme_le_fichier_oracle_et_le_fichier_rejet():
    """L'objet du controle : savoir de quel fichier vient l'ecart."""
    from rapprochement_cle_metier import construire_justifications
    lignes, edf_agg, rejets = _contexte_rejet(nb_oracle=21, montant_oracle="24703.22",
                                              nb_edf=20, montant_edf="23770.97")
    # Oracle : 1 ligne a 932.25 + 20 lignes a 1.00 = 952.25 ; on aligne l'EDF dessus.
    edf_agg[(IBAN_A, date(2026, 7, 10))].montant = Decimal("20.00")
    edf_agg[(IBAN_A, date(2026, 7, 10))].nb = 20
    res = construire_rapprochement(lignes, edf_agg, rejets, [], date(2026, 7, 20), 30)
    just = construire_justifications(res)

    assert len(just) == 1
    j = just[0]
    assert j["cause"] == "REJET"
    assert j["montant"] == Decimal("932.25")
    assert j["beneficiaire"] == "SDC ALTAIR"
    assert j["code"] == "CC01"
    assert j["fichier_oracle"].startswith("DK_30003-0441DMSPCLFRST")
    assert j["fichier_rejet"] == "REJETS_INTERNES_DK.20260624.070002.csv"
    assert j["fichier_edf"] == "IMPORT_AVP_DK.20260624.070103.csv"


def test_une_cle_rapprochee_ne_genere_aucune_justification():
    from rapprochement_cle_metier import construire_justifications, LigneOracle
    ech = date(2026, 7, 31)
    lignes = [LigneOracle(IBAN_A, ech, Decimal("100.00"), "R", "FR76", "N",
                          date(2026, 7, 11), "f.txt")]
    agg = AgregatEdf(nb=1, montant=Decimal("100.00"),
                     tranches=[Tranche(date(2026, 7, 15), 1, Decimal("100.00"), "edf.csv")])
    res = construire_rapprochement(lignes, {(IBAN_A, ech): agg}, {}, [], date(2026, 7, 20), 30)
    assert res[0]["statut"] == RAPPROCHE
    assert construire_justifications(res) == []


def test_ecart_non_couvert_par_les_rejets_est_marque_a_investiguer():
    from rapprochement_cle_metier import construire_justifications, LigneOracle
    ech = date(2026, 7, 31)
    lignes = [LigneOracle(IBAN_A, ech, Decimal("100.00"), f"R{i}", "FR76", f"B{i}",
                          date(2026, 7, 11), "lot_du_11_07.txt") for i in range(3)]
    agg = AgregatEdf(nb=1, montant=Decimal("100.00"),
                     tranches=[Tranche(date(2026, 7, 15), 1, Decimal("100.00"), "edf.csv")])
    res = construire_rapprochement(lignes, {(IBAN_A, ech): agg}, {}, [], date(2026, 7, 20), 30)
    just = construire_justifications(res)

    assert [j["cause"] for j in just] == ["INEXPLIQUE"]
    assert just[0]["nb"] == 2
    assert just[0]["montant"] == Decimal("200.00")
    assert just[0]["fichier_oracle"] == "lot_du_11_07.txt"


def test_prelevement_non_encore_remonte_est_marque_non_confirme():
    from rapprochement_cle_metier import construire_justifications, LigneOracle
    ech = date(2026, 8, 10)
    lignes = [LigneOracle(IBAN_A, ech, Decimal("8000.00"), "R", "FR76", "N",
                          date(2026, 8, 6), "DK_30004-0284DEWPCXFRST.txt")]
    res = construire_rapprochement(lignes, {}, {}, [], date(2026, 8, 6), 10)
    just = construire_justifications(res)

    assert just[0]["cause"] == "NON_CONFIRME"
    assert just[0]["fichier_oracle"] == "DK_30004-0284DEWPCXFRST.txt"
    assert just[0]["fichier_edf"] == "(aucun)"


def test_les_justifications_couvrent_exactement_l_ecart():
    """Garantie de coherence : rien ne doit rester hors du compte."""
    from rapprochement_cle_metier import construire_justifications, LigneOracle
    ech = date(2026, 7, 31)
    lignes = [LigneOracle(IBAN_A, ech, Decimal("50.00"), "R1", "FR76", "B1",
                          date(2026, 7, 11), "f.txt"),
              LigneOracle(IBAN_A, ech, Decimal("30.00"), "R2", "FR76", "B2",
                          date(2026, 7, 11), "f.txt"),
              LigneOracle(IBAN_A, ech, Decimal("20.00"), "R3", "FR76", "B3",
                          date(2026, 7, 11), "f.txt")]
    rejet = LigneRejet(IBAN_A, "R1", "FR76", ech, Decimal("50.00"), "CC01", "M",
                       "rej.csv", date(2026, 7, 15))
    rejet.origine = lignes[0]
    agg = AgregatEdf(nb=1, montant=Decimal("30.00"),
                     tranches=[Tranche(date(2026, 7, 15), 1, Decimal("30.00"), "edf.csv")])

    res = construire_rapprochement(lignes, {(IBAN_A, ech): agg},
                                   {(IBAN_A, ech): [rejet]}, [], date(2026, 7, 20), 30)
    just = construire_justifications(res)

    # Oracle 100,00 - EDF 30,00 = 70,00 manquants : 50,00 de rejet + 20,00 inexpliques.
    assert sum(j["montant"] for j in just) == -res[0]["ecart_montant"] == Decimal("70.00")
    assert sum(j["nb"] for j in just) == -res[0]["ecart_nb"] == 2
    assert sorted(j["cause"] for j in just) == ["INEXPLIQUE", "REJET"]


# --- executer() : point d'entree importable (ODAT Watch) --------------------
def _jeu_minimal(tmp_path):
    """Un prelevement emis le 11/09 (echeance 30/09/2026), confirme par l'etat EDF du 13/09."""
    ecrire_oracle(tmp_path, "20260910", "DK_x-PCL-20260911-1_20260911-01.txt",
                  [ligne_oracle(IBAN_A, "09/30/2026", "100.00")])
    ecrire_edf(tmp_path, "20260913", [f"ORACLE;{IBAN_A};30/09/2026;1;100,00;"])
    (tmp_path / "EDF" / "REJETS").mkdir(parents=True, exist_ok=True)
    return tmp_path


def test_executer_ecrit_les_quatre_fichiers_et_le_resume(tmp_path):
    racine = _jeu_minimal(tmp_path)
    # jours=3 : l'historique Oracle (emission du 11/09) couvre tout le perimetre, pas d'avertissement
    res = executer(reference="2026-09-14", racine=racine, jours=3)
    assert res["code"] == 0 and res["statut_global"] == "OK"
    assert res["par_statut"][RAPPROCHE]["cles"] == 1
    dossier = racine / "rapport"
    for suffixe in (".xlsx", ".csv", "_justifications.csv", "_resume.json"):
        assert (dossier / (res["base"] + suffixe)).is_file(), suffixe
    resume = json.loads((dossier / (res["base"] + "_resume.json")).read_text(encoding="utf-8"))
    assert resume["reference"] == "2026-09-14" and resume["statut_global"] == "OK"
    assert resume["contexte"]["Lignes Oracle"] == 1 and resume["avertissements"] == []
    assert resume["par_statut"][RAPPROCHE]["montant"] == "100.00"


def test_executer_statut_degrade_sans_fichier_edf(tmp_path):
    racine = _jeu_minimal(tmp_path)
    (racine / "EDF" / "IMPORT_AVP_DK.20260913.070100.csv").unlink()
    res = executer(reference="2026-09-14", racine=racine, jours=10)
    assert res["code"] == 3 and res["statut_global"] == "DEGRADE"
    assert any("Aucun fichier EDF" in a for a in res["avertissements"])


def test_executer_leve_sur_racine_absente(tmp_path):
    with pytest.raises(ErreurTraitement):
        executer(reference="2026-09-14", racine=tmp_path / "nulle_part", jours=10)


# --- Doublons d'emission ----------------------------------------------------
def test_doublon_meme_reference_dans_deux_fichiers(tmp_path):
    """Un lot rejoue : la meme reference de paiement part deux fois -> DOUBLON."""
    ecrire_oracle(tmp_path, "20260910", "DK_x-PCL-20260911-1_20260911-01.txt",
                  [ligne_oracle(IBAN_A, "09/30/2026", "100.00", reference="P1 REF")])
    ecrire_oracle(tmp_path, "20260911", "DK_x-PCL-20260912-2_20260912-01.txt",
                  [ligne_oracle(IBAN_A, "09/30/2026", "100.00", reference="P1 REF")])
    diag = Diagnostic()
    lignes, _ = charger_oracle(tmp_path / "ORACLE", MOTIFS, diag)
    doublons = detecter_doublons(lignes)
    assert len(doublons) == 1 and doublons[0]["type"] == "DOUBLON"
    d = doublons[0]
    assert d["nb"] == 2 and d["reference"] == "P1 REF" and d["montant"] == Decimal("100.00")
    assert "20260911-1" in d["fichiers"] and "20260912-2" in d["fichiers"]
    assert d["emissions"] == "11/09/2026 + 12/09/2026"


def test_meme_debiteur_meme_montant_references_differentes_pas_de_doublon(tmp_path):
    """Deux factures distinctes de meme montant le meme jour : pas un doublon, rien n'est signale."""
    ecrire_oracle(tmp_path, "20260910", "DK_x-PCL-20260911-1_20260911-01.txt",
                  [ligne_oracle(IBAN_A, "09/30/2026", "614.63", reference="P22036"),
                   ligne_oracle(IBAN_A, "09/30/2026", "614.63", reference="P22037")])
    lignes, _ = charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())
    doublons = detecter_doublons(lignes)
    assert doublons == []


def test_aucun_doublon_quand_les_montants_different(tmp_path):
    ecrire_oracle(tmp_path, "20260910", "DK_x-PCL-20260911-1_20260911-01.txt",
                  [ligne_oracle(IBAN_A, "09/30/2026", "10.00"),
                   ligne_oracle(IBAN_A, "09/30/2026", "20.00")])
    lignes, _ = charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())
    assert detecter_doublons(lignes) == []


def test_meme_reference_mais_ligne_differente_n_est_pas_un_doublon(tmp_path):
    """Doublon = ligne entiere identique. Meme reference, meme montant, meme echeance mais un autre
    beneficiaire (un seul champ differe) : pas un doublon, rien n'est signale."""
    ecrire_oracle(tmp_path, "20260910", "DK_x-PCL-20260911-1_20260911-01.txt",
                  [ligne_oracle(IBAN_A, "09/30/2026", "100.00", reference="P1 REF", nom="DUPONT"),
                   ligne_oracle(IBAN_A, "09/30/2026", "100.00", reference="P1 REF", nom="DUPONT JEAN")])
    lignes, _ = charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())
    assert detecter_doublons(lignes) == []


def test_references_vides_ne_se_ressemblent_pas(tmp_path):
    ecrire_oracle(tmp_path, "20260910", "DK_x-PCL-20260911-1_20260911-01.txt",
                  [ligne_oracle(IBAN_A, "09/30/2026", "10.00", reference=""),
                   ligne_oracle(IBAN_A, "09/30/2026", "20.00", reference="")])
    lignes, _ = charger_oracle(tmp_path / "ORACLE", MOTIFS, Diagnostic())
    assert detecter_doublons(lignes) == []


def test_executer_signale_les_doublons_comme_anomalie(tmp_path):
    racine = _jeu_minimal(tmp_path)
    ecrire_oracle(racine, "20260911", "DK_x-PCL-20260912-2_20260912-01.txt",
                  [ligne_oracle(IBAN_A, "09/30/2026", "100.00", reference="REF DOUBLE"),
                   ligne_oracle(IBAN_A, "09/30/2026", "100.00", reference="REF DOUBLE")])
    res = executer(reference="2026-09-14", racine=racine, jours=3)
    assert res["nb_doublons"] == 1 and "nb_similitudes" not in res
    assert res["code"] == 1 and res["statut_global"] == "ANOMALIES"
    csv_doublons = (racine / "rapport" / (res["base"] + "_doublons.csv")).read_text(encoding="utf-8-sig")
    assert "DOUBLON;REF DOUBLE" in csv_doublons
    resume = json.loads((racine / "rapport" / (res["base"] + "_resume.json")).read_text(encoding="utf-8"))
    assert resume["nb_doublons"] == 1


# --- Disposition ODAT/prelevements : REJETS a cote d'EDF ; lignes lues exposees par executer() -----
def test_rejets_a_cote_d_edf_prioritaire(tmp_path):
    from rapprochement_cle_metier import trouver_dossier_rejets
    edf = tmp_path / "EDF"
    edf.mkdir()
    assert trouver_dossier_rejets(edf) == tmp_path / "REJETS"          # par defaut : frere d'EDF
    (edf / "REJETS").mkdir()
    assert trouver_dossier_rejets(edf) == edf / "REJETS"               # ancienne disposition acceptee
    (tmp_path / "REJETS").mkdir()
    assert trouver_dossier_rejets(edf) == tmp_path / "REJETS"          # la nouvelle l'emporte


def test_executer_expose_les_lignes_edf_et_rejets(tmp_path):
    racine = _jeu_minimal(tmp_path)
    # rejet range a cote d'EDF, apparie a la ligne Oracle (meme RUM, meme echeance)
    d = racine / "REJETS"
    d.mkdir()
    (d / "REJETS_INTERNES_DK.20260913.070000.csv").write_text(
        "\nLISTE DES REJETS INTERNES\nIBAN CREANCIER;RUM;IBAN DEBITEUR;DATE D'ECHEANCE;MONTANT;CODE REJET;MOTIF DU REJET;\n"
        f"{IBAN_A};NVOA0001;FR7611111111111;30/09/2026;100,00;AM04;Provision insuffisante;\n", encoding="latin-1")
    res = executer(reference="2026-09-14", racine=racine, jours=3)
    assert res["dossier_rejets"].endswith("REJETS") and "EDF" not in Path(res["dossier_rejets"]).name
    assert len(res["edf"]) == 1
    e = res["edf"][0]
    assert (e["fichier"], e["nom_si"], e["iban_creancier"], e["nb"], e["montant"]) == \
        ("IMPORT_AVP_DK.20260913.070100.csv", "ORACLE", IBAN_A, 1, Decimal("100.00"))
    assert e["date_fichier"] == date(2026, 9, 13) and e["echeance"] == date(2026, 9, 30)
    assert len(res["rejets"]) == 1
    r = res["rejets"][0]
    assert (r["rum"], r["code"], r["montant"], r["appariee"], r["beneficiaire"]) == ("NVOA0001", "AM04", Decimal("100.00"), True, "BENEF")
    # tous les fichiers recus sont listes, meme un etat EDF sans ligne du SI
    ecrire_edf(racine, "20260914", ["CIF;FR7612345678901;30/09/2026;1;5,00;"])
    res = executer(reference="2026-09-14", racine=racine, jours=3)
    assert [f["fichier"] for f in res["fichiers_edf"]] == ["IMPORT_AVP_DK.20260913.070100.csv", "IMPORT_AVP_DK.20260914.070100.csv"]
    assert res["fichiers_edf"][1]["date_fichier"] == date(2026, 9, 14) and len(res["edf"]) == 1
    assert [f["fichier"] for f in res["fichiers_rejets"]] == ["REJETS_INTERNES_DK.20260913.070000.csv"]
    # le JSON ecrit ne contient pas ces listes (elles ne sont pas serialisables telles quelles)
    resume = json.loads((racine / "rapport" / (res["base"] + "_resume.json")).read_text(encoding="utf-8"))
    assert "edf" not in resume and "rejets" not in resume
