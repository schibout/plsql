"""Lecture des fichiers AFB120 (CFONB 120) réels."""
from datetime import date
from pathlib import Path

import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"
TARGET_B = REF / "fluxPFE/2b6da61b5e384790970e4ab0b536102e/TARGET/compt_AFB120_RELEVESDECOMPTE_260915-081614.txt"
EBS_A = REF / "fichierBanque/AFB120.txt_20260915074956"


def test_flux_b_213_releves():
    a = rb.lire_afb120(TARGET_B)
    assert (a.nb_releves, a.nb_mouvements, a.nb_lignes) == (213, 2014, 8773)
    assert a.banques == {"30003": 213}
    assert a.flux == "B"
    assert (a.date_min, a.date_max) == (date(2026, 9, 11), date(2026, 9, 14))
    assert len(a.md5) == 32
    premier = a.comptes[0]
    assert premier["compte"] == "30003.01100.00020070505"
    assert (premier["date_debut"], premier["date_fin"]) == (date(2026, 9, 11), date(2026, 9, 14))


def test_flux_a_multi_banques():
    # Fichier réel : 160 relevés sur 6 banques, 30004 majoritaire ; 14 comptes SG (30003) y figurent aussi,
    # ce qui ne suffit pas à en faire un flux B (flux B = 30003 seule).
    a = rb.lire_afb120(EBS_A)
    assert a.flux == "A" and len(a.banques) == 6
    assert max(a.banques, key=a.banques.get) == "30004" and a.banques["30003"] == 14
    assert a.nb_releves == sum(a.banques.values()) == 160


def test_md5_identique_pfe_et_ebs():
    pfe = rb.lire_afb120(REF / "fluxPFE/9098a5f957a749dd8e1545f9e9b68199/TARGET/compt_AFB120_RELEVESDECOMPTE_260915-074613.txt")
    assert pfe.md5 == rb.lire_afb120(EBS_A).md5


def test_depuis_bytes_et_fichier_vide():
    a = rb.lire_afb120(TARGET_B.read_bytes())
    assert a.nb_releves == 213
    v = rb.lire_afb120(b"")
    assert (v.nb_releves, v.flux, v.date_min) == (0, None, None)
