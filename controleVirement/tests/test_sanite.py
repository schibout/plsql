"""Controles de forme sur la cible (cv.sanite)."""
from cv.model import LotAck, OracleRow, Virement
from cv.sanite import controle_sanite, iban_valide

PAYEUR = "FR7630003011000002002534384"
IBAN_OK = "FR7630087330800001083600186"


def test_iban_valide():
    assert iban_valide(IBAN_OK) and iban_valide(PAYEUR) and iban_valide("GB82 WEST 1234 5698 7654 32")
    assert not iban_valide("FR7630087330800001083600187") and not iban_valide("") and not iban_valide("FR76-30")


def _ack(virements, payeur=PAYEUR, date="260918", footer=None):
    return LotAck(payeur, virements, len(virements) if footer is None else footer,
                  sum(v.montant_cts for v in virements), date_creation=date)


def _row(nom_edf="ACK_A", payeur=PAYEUR):
    return OracleRow("30003", payeur, "20260918", "DK_FIN01_x", 1, 100, nom_edf, 1, 100)


def test_sanite_rien_a_signaler(tmp_path):
    asc = tmp_path / "ACK_A.asc"; asc.write_text("PGP")
    acks = {"ACK_A": _ack([Virement(IBAN_OK, 100, "N", "BIC")])}
    assert controle_sanite("g", acks, {"ACK_A.asc": asc}, [_row()], "18092026", "0") == []


def test_sanite_detecte_chaque_type(tmp_path):
    vide = tmp_path / "ACK_B.asc"; vide.write_text("")
    acks = {
        "ACK_A": _ack([Virement(IBAN_OK, 0, "N", "BIC"), Virement("FR00", 100, "M", "")], payeur="FR_AUTRE", date="260917"),
        "ACK_B": _ack([], footer=3),
    }
    lignes = controle_sanite("g", acks, {"ACK_B.asc": vide}, [_row("ACK_A"), _row("ACK_B")], "18092026", "1")
    types = [(l["fichier"], l["type"], l["gravite"]) for l in lignes]
    assert types == [
        ("TALEND/LS_OUT.OK", "TALEND_KO", "KO"),
        ("ACK_A", "SIGNATURE_ABSENTE", "KO"),
        ("ACK_A", "PAYEUR_DIFFERENT", "KO"),
        ("ACK_A", "DATE_DIFFERENTE", "A_VERIFIER"),
        ("ACK_A", "MONTANT_NUL_OU_NEGATIF", "KO"),
        ("ACK_A", "IBAN_INVALIDE", "KO"),
        ("ACK_A", "BIC_ABSENT", "A_VERIFIER"),
        ("ACK_B", "SIGNATURE_ABSENTE", "KO"),
        ("ACK_B", "ACK_VIDE", "KO"),
        ("ACK_B", "PIED_INCOHERENT", "KO"),
    ]


def test_sanite_ls_out_absent_a_verifier():
    lignes = controle_sanite("g", {}, {}, [], "18092026", None)
    assert [(l["type"], l["gravite"]) for l in lignes] == [("TALEND_SANS_RETOUR", "A_VERIFIER")]
