from cv.model import Virement, LotDK, LotAck, OracleRow
from cv.reconcile import nom_dk_depuis_fin01, controle_fichiers


def test_nom_dk_depuis_fin01():
    assert nom_dk_depuis_fin01("DK_FIN01_30003-0001DEWRBT-x.txt") == "DK_30003-0001DEWRBT-x.txt"


def _orow(src, edf):
    return OracleRow("30003", "FR76", "20260630", src, 3, 10443126, edf, 3, 10443126)


def test_controle_fichiers_tout_present():
    dkfin = "DK_FIN01_30003-0001DEWRBT-x.txt"
    ack = "CDPG.NC4.IMPORT_ACK.DLK_VIR_1.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL"
    lignes = controle_fichiers(
        guid="g1",
        dk_names={"DK_30003-0001DEWRBT-x.txt"},
        dkfin01_source={dkfin},
        dkfin01_cible={dkfin},
        ack_names={ack},
        oracle_rows=[_orow(dkfin, ack)],
    )
    assert all(l["statut"] == "OK" for l in lignes)
    assert {l["categorie"] for l in lignes} >= {"DK", "DK_FIN01_source", "DK_FIN01_cible", "ACK"}


def test_controle_fichiers_dk_manquant():
    dkfin = "DK_FIN01_30003-0001DEWRBT-x.txt"
    ack = "CDPG.NC4.IMPORT_ACK.DLK_VIR_1.PY_TRANSFER.I_DAL_VIR.DALKIA.NULL"
    lignes = controle_fichiers(
        guid="g1",
        dk_names=set(),                      # DK source absent
        dkfin01_source={dkfin},
        dkfin01_cible={dkfin},
        ack_names={ack},
        oracle_rows=[_orow(dkfin, ack)],
    )
    dk_line = next(l for l in lignes if l["categorie"] == "DK")
    assert dk_line["statut"] == "MANQUANT"


from cv.reconcile import controle_totaux_source, controle_totaux_edf


def _lot(entete, montants):
    virs = [Virement("FR76", m, "NOM", "BIC") for m in montants]
    return LotDK(ref="R", montant_entete_cts=entete, virements=virs, euro_lines=0)


def test_controle_totaux_source_ok():
    dk = _lot(10443126, [1795783, 8548539, 98804])
    dkf = LotDK("R", 10443126, [Virement("FR76", m, "N", "B") for m in [1795783, 8548539, 98804]], euro_lines=1)
    orow = _orow("DK_FIN01_x", "ACK_x")  # nb_source=3, montant_source=10443126
    res = controle_totaux_source("g1", "DK_FIN01_x", dk, dkf, orow)
    assert res["statut_lignes"] == "OK"
    assert res["statut_montant"] == "OK"
    assert res["euro_lines"] == 1


def test_controle_totaux_source_ecart_montant():
    dk = _lot(10443126, [1795783, 8548539, 98804])
    dkf = LotDK("R", 10443126, [Virement("FR76", m, "N", "B") for m in [1795783, 8548539, 99999]], euro_lines=1)
    orow = _orow("DK_FIN01_x", "ACK_x")
    res = controle_totaux_source("g1", "DK_FIN01_x", dk, dkf, orow)
    assert res["statut_montant"] == "KO"


def test_controle_totaux_edf_regroupement_ok():
    # 2 sources regroupees : 2 + 3 = 5 virements, 100 + 200 = 300 cts
    r1 = OracleRow("30004", "FR76", "20260630", "DK_FIN01_a", 2, 100, "ACK_g", 5, 300)
    r2 = OracleRow("30004", "FR76", "20260630", "DK_FIN01_b", 3, 200, "ACK_g", 5, 300)
    ack = LotAck("FR76", [Virement("FR76", m, "N", "B") for m in [100, 50, 50, 50, 50]], footer_count=5, footer_total_cts=300)
    res = controle_totaux_edf("g1", "ACK_g", ack, [r1, r2])
    assert res["nb_sources_regroupees"] == 2
    assert res["statut_lignes"] == "OK"
    assert res["statut_montant"] == "OK"


def test_controle_totaux_edf_somme_incoherente():
    r1 = OracleRow("30004", "FR76", "20260630", "DK_FIN01_a", 2, 100, "ACK_g", 5, 300)
    r2 = OracleRow("30004", "FR76", "20260630", "DK_FIN01_b", 3, 999, "ACK_g", 5, 300)
    ack = LotAck("FR76", [Virement("FR76", m, "N", "B") for m in [100, 50, 50, 50, 50]], footer_count=5, footer_total_cts=300)
    res = controle_totaux_edf("g1", "ACK_g", ack, [r1, r2])
    assert res["statut_montant"] == "KO"


from cv.reconcile import controle_lignes, _norm_nom


def _lignes(dkf, ack):
    """Helper de test : enveloppe le DK_FIN01 unique dans une liste de lots."""
    return controle_lignes("g1", "lot", [dkf], ack)


def test_norm_nom_espaces_multiples():
    assert _norm_nom("COMMUNE   D  ALLAUCH") == _norm_nom("COMMUNE D ALLAUCH")


def _v(iban, montant, nom="NOM", bic="BIC"):
    return Virement(iban, montant, nom, bic)


def test_controle_lignes_aucun_ecart():
    dkf = LotDK("R", 0, [_v("FR1", 100, "COMMUNE D ALLAUCH"), _v("FR2", 200, "ISTRES")], 1)
    ack = LotAck("P", [_v("FR1", 100, "COMMUNE D ALLAUCH"), _v("FR2", 200, "ISTRES")], 2, 300)
    assert _lignes(dkf, ack) == []


def test_controle_lignes_virement_manquant_cote_ack():
    dkf = LotDK("R", 0, [_v("FR1", 100), _v("FR2", 200)], 1)
    ack = LotAck("P", [_v("FR1", 100)], 1, 100)
    ecarts = _lignes(dkf, ack)
    assert len(ecarts) == 1
    assert ecarts[0]["type_ecart"] == "ABSENT_ACK"
    assert ecarts[0]["iban"] == "FR2"


def test_controle_lignes_nom_different():
    dkf = LotDK("R", 0, [_v("FR1", 100, "COMMUNE D ALLAUCH")], 1)
    ack = LotAck("P", [_v("FR1", 100, "AUTRE BENEFICIAIRE")], 1, 100)
    ecarts = _lignes(dkf, ack)
    assert any(e["type_ecart"] == "NOM_DIFFERENT" for e in ecarts)


def test_controle_lignes_bic8_vs_bic11_pas_decart():
    dkf = LotDK("R", 0, [_v("FR1", 100, "N", "SOGEFRPP")], 1)
    ack = LotAck("P", [_v("FR1", 100, "N", "SOGEFRPPXXX")], 1, 100)
    assert _lignes(dkf, ack) == []


def test_controle_lignes_bic_reellement_different():
    dkf = LotDK("R", 0, [_v("FR1", 100, "N", "SOGEFRPP")], 1)
    ack = LotAck("P", [_v("FR1", 100, "N", "BNPAFRPP")], 1, 100)
    ecarts = _lignes(dkf, ack)
    assert any(e["type_ecart"] == "BIC_DIFFERENT" for e in ecarts)


from cv.reconcile import controle_quartz


def test_controle_quartz_tout_ok():
    cible = [_v("FR1", 100, "COMMUNE D ALLAUCH"), _v("FR2", 200, "ISTRES")]
    quartz = [_v("", 100, "COMMUNE D ALLAUCH"), _v("", 200, "ISTRES")]
    totaux, ecarts = controle_quartz(cible, quartz)
    assert totaux["nb_cible"] == 2 and totaux["nb_quartz"] == 2
    assert totaux["statut_lignes"] == "OK" and totaux["statut_montant"] == "OK"
    assert ecarts == []


def test_controle_quartz_virement_absent_dans_quartz():
    cible = [_v("FR1", 100, "ALLAUCH"), _v("FR2", 200, "ISTRES")]
    quartz = [_v("", 100, "ALLAUCH")]
    totaux, ecarts = controle_quartz(cible, quartz)
    assert totaux["statut_lignes"] == "KO"
    assert any(e["type_ecart"] == "ABSENT_QUARTZ" and e["montant_cts"] == 200 for e in ecarts)


def test_controle_quartz_virement_en_trop_dans_quartz():
    cible = [_v("FR1", 100, "ALLAUCH")]
    quartz = [_v("", 100, "ALLAUCH"), _v("", 999, "INCONNU")]
    totaux, ecarts = controle_quartz(cible, quartz)
    assert any(e["type_ecart"] == "ABSENT_CIBLE" and e["montant_cts"] == 999 for e in ecarts)


def test_controle_quartz_nom_different():
    cible = [_v("FR1", 100, "COMMUNE D ALLAUCH")]
    quartz = [_v("", 100, "AUTRE BENEFICIAIRE")]
    totaux, ecarts = controle_quartz(cible, quartz)
    assert any(e["type_ecart"] == "NOM_DIFFERENT" for e in ecarts)
