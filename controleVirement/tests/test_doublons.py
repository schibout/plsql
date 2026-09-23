"""Doublons complementaires D2..D6 (cv.doublons) et mode cible seule."""
from pathlib import Path

from cv.doublons import (charger_envois, doublons_croises, doublons_intra_envoi, doublons_historique,
                         doublons_sources, dossiers_cible_precedents, ref_paiement)
from cv.model import LotAck, LotDK, OracleRow, Virement
from cv.parsers import parse_ack
from cv.reconcile import controle_doublons_ack, controle_fichiers, controle_totaux_source

PAYEUR = "FR7630003011000002002534384"


def _v(iban, montant, nom="NOM", libelle=""):
    return Virement(iban, montant, nom, "BIC", libelle)


def _ack(*virements, payeur=PAYEUR):
    return LotAck(payeur, list(virements), len(virements), sum(v.montant_cts for v in virements))


# ------------------------------------------------------------------ D2 / D3
def test_croises_aucun_doublon_quand_envois_disjoints():
    acks = [("g", "A", _ack(_v("FR1", 100), _v("FR2", 200))), ("g", "B", _ack(_v("FR3", 300)))]
    chev, multi = doublons_croises(acks)
    assert chev == [] and multi == []


def test_croises_chevauchement_partiel_et_virement_multi():
    acks = [("g", "A", _ack(_v("FR1", 100), _v("FR2", 200), _v("FR3", 300))),
            ("g", "B", _ack(_v("FR2", 200), _v("FR3", 300), _v("FR4", 400)))]
    chev, multi = doublons_croises(acks)
    assert len(chev) == 1
    c = chev[0]
    assert (c["fichier"], c["fichier_autre"], c["nb_communs"], c["pct_commun"]) == ("A", "B", 2, 67)
    assert c["montant_commun_cts"] == 500 and c["gravite"] == "KO"
    assert [(m["iban"], m["nb_envois"], m["envois"]) for m in multi] == [("FR3", 2, "A | B"), ("FR2", 2, "A | B")]


def test_croises_ignorent_les_copies_identiques_deja_signalees():
    a = _ack(_v("FR1", 100), _v("FR2", 200))
    acks = [("g", "A", a), ("g", "B", _ack(_v("FR1", 100), _v("FR2", 200)))]
    identiques = controle_doublons_ack(acks)
    assert len(identiques) == 1
    chev, multi = doublons_croises(acks, identiques)
    assert chev == [] and multi == []


def test_croises_payeurs_differents_pas_de_doublon():
    acks = [("g", "A", _ack(_v("FR1", 100))), ("g", "B", _ack(_v("FR1", 100), payeur="FR_AUTRE"))]
    assert doublons_croises(acks) == ([], [])


# ------------------------------------------------------------------ ligne entiere
ENTETE = "03029992DK  CODEREMETTAN170926DALKIA Virement         260915021823EURSOGEFRPPXXX" + PAYEUR + "       30003"


def test_entete_ack_ignore_seulement_l_horodatage_de_creation(tmp_path):
    for nom, entete in (("a", ENTETE), ("b", ENTETE.replace("260915021823", "260916093000")),
                        ("c", ENTETE.replace("170926", "180926"))):
        (tmp_path / nom).write_text(entete + "\n0802" + "0" * 23, encoding="latin-1")
    a, b, c = (parse_ack(tmp_path / n) for n in "abc")
    assert a.iban_payeur == PAYEUR and a.entete == b.entete != c.entete


def test_doublon_exige_la_ligne_entiere_identique(tmp_path):
    """Meme beneficiaire, IBAN et montant ne suffisent pas : une reference differente, ce n'est pas un doublon.
    Les numeros de sequence (propres a chaque fichier) ne comptent pas."""
    ligne = ("FR1", 100, "NOM", "21/09/2026-1000-Site X")
    ack = "CDPG.NC4.IMPORT_ACK."
    _ecrit_ack(tmp_path, "g1", ack + "A", [ligne])
    _ecrit_ack(tmp_path, "g1", ack + "B", [("FR1", 100, "NOM", "21/09/2026-2000-Site X")])
    _ecrit_ack(tmp_path, "g2", ack + "C", [("FR9", 5, "AUTRE"), ligne])          # meme ligne, en 2e position
    chev, multi = doublons_croises(charger_envois(tmp_path))
    assert [(m["envois"], m["libelle"]) for m in multi] == [(f"{ack}A | {ack}C", "21/09/2026-1000-Site X")]
    assert [(c["fichier"], c["fichier_autre"]) for c in chev] == [(ack + "A", ack + "C")]

    intra = tmp_path / "intra"
    _ecrit_ack(intra, "g", ack + "D", [ligne, ligne, ("FR1", 100, "NOM", "21/09/2026-3000-Site X")])
    _ecrit_ack(intra, "g", ack + "E", [ligne, ("FR1", 100, "NOM", "21/09/2026-3000-Site X")])
    assert [(l["fichier"], l["occurrences"], l["gravite"]) for l in doublons_intra_envoi(charger_envois(intra))] == [
        (ack + "D", 2, "KO")]


# ------------------------------------------------------------------ D4
def test_ref_paiement_extraite_du_libelle():
    assert ref_paiement(_v("FR1", 1, libelle="20260918-0019DCWXTIERSEXVIR0001 21/09/2026-44756-Site FRA67403 FOU")) == "44756"
    assert ref_paiement(_v("FR1", 1, libelle="")) == ""


def test_intra_envoi_seule_la_ligne_identique_est_signalee():
    l1 = "21/09/2026-1000-Site"
    l2 = "21/09/2026-2000-Site"
    acks = [("g", "A", _ack(_v("FR1", 100, libelle=l1), _v("FR1", 100, libelle=l2), _v("FR2", 100))),
            ("g", "B", _ack(_v("FR1", 100, libelle=l1), _v("FR1", 100, libelle=l1)))]
    lignes = doublons_intra_envoi(acks)
    assert [(l["fichier"], l["occurrences"], l["gravite"], l["references"]) for l in lignes] == [("B", 2, "KO", "1000")]


# ------------------------------------------------------------------ D5
def _ecrit_ack(dossier, guid, nom, virements, payeur=PAYEUR):
    target = Path(dossier) / guid / "TARGET"
    target.mkdir(parents=True, exist_ok=True)
    lignes = ["03" + " " * 78 + payeur.ljust(27) + " " * 100]
    for i, (iban, cts, nom_b, *libelle) in enumerate(virements, 1):
        lignes.append("06" + f"{i:021d}" + nom_b.ljust(24) + " " * 24 + "BIC".ljust(11) + iban.ljust(34)
                      + f"{cts:016d}" + (libelle[0] if libelle else "libelle").ljust(70))
    lignes.append("08" + "02" + f"{len(virements):07d}" + f"{sum(v[1] for v in virements):016d}")
    (target / nom).write_text("\n".join(lignes), encoding="latin-1")


def test_dossiers_cible_precedents_dans_la_fenetre(tmp_path):
    for d in ("10092026", "15092026", "18092026", "19092026", "01082026"):
        (tmp_path / f"{d}_cible").mkdir()
    assert [d for d, _ in dossiers_cible_precedents(tmp_path, "18092026", 7)] == ["15092026"]
    assert [d for d, _ in dossiers_cible_precedents(tmp_path, "18092026", 30)] == ["10092026", "15092026"]
    # disposition courante (sans suffixe) mélangée à l'ancienne, fichiers ignorés
    (tmp_path / "16092026").mkdir()
    (tmp_path / "rapport_16092026").mkdir()
    (tmp_path / "Liste des virements importes du jour16092026.xls").write_text("")
    assert [d for d, _ in dossiers_cible_precedents(tmp_path, "18092026", 7)] == ["15092026", "16092026"]


def test_historique_ack_identique_fichier_rejoue_et_virement_deja_envoye(tmp_path):
    hier = tmp_path / "17092026_cible"
    _ecrit_ack(hier, "g0", "CDPG.NC4.IMPORT_ACK.X", [("FR1", 100, "A"), ("FR2", 200, "B")])
    _ecrit_ack(hier, "g0", "CDPG.NC4.IMPORT_ACK.Y", [("FR9", 900, "Z")])
    jour = tmp_path / "18092026"
    _ecrit_ack(jour, "g1", "CDPG.NC4.IMPORT_ACK.1", [("FR1", 100, "A"), ("FR2", 200, "B")])   # meme contenu que ACK_X
    _ecrit_ack(jour, "g1", "CDPG.NC4.IMPORT_ACK.Y", [("FR5", 500, "E")])                      # meme nom de fichier
    _ecrit_ack(jour, "g1", "CDPG.NC4.IMPORT_ACK.2", [("FR7", 700, "G"), ("FR9", 900, "Z"),    # ligne deja envoyee
                                                     ("FR9", 900, "Z", "autre reference")])  # meme IBAN/montant : non
    lignes, nb = doublons_historique(charger_envois(jour), tmp_path, "18092026", 7)
    assert nb == 1
    assert [(l["fichier"], l["type"], l["gravite"], l["date_precedente"]) for l in lignes] == [
        ("CDPG.NC4.IMPORT_ACK.1", "ACK_IDENTIQUE", "KO", "17092026"),
        ("CDPG.NC4.IMPORT_ACK.2", "VIREMENT_DEJA_ENVOYE", "KO", "17092026"),
        ("CDPG.NC4.IMPORT_ACK.Y", "FICHIER_REJOUE", "KO", "17092026"),
    ]
    assert lignes[1]["montant_cts"] == 900


def test_historique_sans_journee_precedente(tmp_path):
    assert doublons_historique([("g", "A", _ack(_v("FR1", 1)))], tmp_path, "18092026") == ([], 0)


# ------------------------------------------------------------------ D6
def _ecrit_dkfin01(chemin, virements):
    lignes = ["AP;REF;1.00;AP;;ORACLE", "ENTETE"]
    for iban, cts, nom in virements:
        cols = [""] * 15
        cols[9], cols[10], cols[12], cols[14] = str(cts), nom, iban, "BIC"
        lignes.append(";".join(cols))
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text("\n".join(lignes), encoding="latin-1")


def _orow(source, guid_edf="ACK"):
    return OracleRow("30003", PAYEUR, "20260918", source, 1, 100, guid_edf, 1, 100)


def test_sources_meme_nom_meme_contenu_et_reference_multiple(tmp_path):
    a = tmp_path / "g1" / "DK_FIN01_A.txt"; _ecrit_dkfin01(a, [("FR1", 100, "A")])
    a2 = tmp_path / "g2" / "DK_FIN01_A.txt"; _ecrit_dkfin01(a2, [("FR1", 100, "A")])
    b = tmp_path / "g2" / "DK_FIN01_B.txt"; _ecrit_dkfin01(b, [("FR1", 100, "A")])
    c = tmp_path / "g2" / "DK_FIN01_C.txt"; _ecrit_dkfin01(c, [("FR3", 300, "C")])
    lignes = doublons_sources({"g1": {"DK_FIN01_A.txt": a}, "g2": {"DK_FIN01_A.txt": a2, "DK_FIN01_B.txt": b, "DK_FIN01_C.txt": c}},
                              {"g1": [_orow("DK_FIN01_A.txt")], "g2": [_orow("DK_FIN01_A.txt"), _orow("DK_FIN01_C.txt"), _orow("DK_FIN01_C.txt")]})
    types = {(l["type"], l["fichier"]): l for l in lignes}
    assert types[("FICHIER_DANS_PLUSIEURS_INSTANCES", "DK_FIN01_A.txt")]["guids"] == "g1 | g2"
    assert types[("CONTENU_IDENTIQUE", "DK_FIN01_A.txt | DK_FIN01_B.txt")]["gravite"] == "KO"
    assert types[("REFERENCE_ORACLE_MULTIPLE", "DK_FIN01_A.txt")]["detail"] == "reference 2 fois par le CSV Oracle"
    assert types[("REFERENCE_ORACLE_MULTIPLE", "DK_FIN01_C.txt")]["guids"] == "g2"
    assert len(lignes) == 4


# ------------------------------------------------------------------ mode cible seule
def test_controle_fichiers_cible_seule_n_attend_ni_dk_ni_dkfin01_source():
    lignes = controle_fichiers("g", set(), set(), {"DK_FIN01_x"}, {"ACK_x"}, [_orow("DK_FIN01_x", "ACK_x")],
                               cible_seul=True)
    assert [(l["categorie"], l["statut"]) for l in lignes] == [("DK_FIN01_cible", "OK"), ("ACK", "OK")]


def test_totaux_source_cible_seule_compare_entete_dkfin01():
    dkf = LotDK("R", 300, [_v("FR1", 100), _v("FR2", 200)], euro_lines=1)
    row = OracleRow("30003", PAYEUR, "d", "DK_FIN01_x", 2, 300, "ACK", 2, 300)
    res = controle_totaux_source("g", "DK_FIN01_x", None, dkf, row, cible_seul=True)
    assert res["nb_dk"] is None and res["montant_dk_fin01_entete"] == 300
    assert res["statut_lignes"] == "OK" and res["statut_montant"] == "OK"
    dkf.montant_entete_cts = 301
    assert controle_totaux_source("g", "DK_FIN01_x", None, dkf, row, cible_seul=True)["statut_montant"] == "KO"
    # sans le mode, l'absence de DK reste un ecart
    assert controle_totaux_source("g", "DK_FIN01_x", None, dkf, row)["statut_lignes"] == "KO"
