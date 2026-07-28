import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from controle_virements import main, collecter_instance
from cv.discovery import discover_instances

RACINE = Path(__file__).resolve().parents[1]  # dossier controleVirement/


def test_e2e_sur_donnees_reelles():
    code = main(["26062026", "--racine", str(RACINE)])
    rapport = RACINE / "rapport_26062026"
    assert rapport.exists()
    assert (rapport / "controle_totaux_source.csv").exists()
    assert (rapport / "controle_totaux_edf.csv").exists()
    assert code in (0, 1)


def test_e2e_totaux_concordent():
    instances = discover_instances(RACINE, "26062026")
    assert instances, "instances 26062026 introuvables"
    for inst in instances:
        _, totaux_source, totaux_edf, ecarts, _ = collecter_instance(inst)
        for t in totaux_source:
            assert t["statut_lignes"] == "OK", t
            assert t["statut_montant"] == "OK", t
            assert t["euro_lines"] == 1, t
        for t in totaux_edf:
            assert t["statut_lignes"] == "OK", t
            assert t["statut_montant"] == "OK", t
        assert ecarts == [], ecarts


def test_e2e_quartz_concorde():
    from controle_virements import trouver_fichier_quartz, collecter_instance
    from cv.parsers import parse_quartz_xls
    from cv.reconcile import controle_quartz
    from cv.discovery import discover_instances

    quartz = trouver_fichier_quartz(RACINE, "26062026")
    assert quartz is not None, "fichier Quartz introuvable"
    cible = []
    for inst in discover_instances(RACINE, "26062026"):
        *_, cv = collecter_instance(inst)
        cible += cv
    totaux, ecarts = controle_quartz(cible, parse_quartz_xls(quartz))
    assert totaux["nb_cible"] == totaux["nb_quartz"] == 66, totaux
    assert totaux["statut_lignes"] == "OK", totaux
    assert totaux["statut_montant"] == "OK", totaux
    assert ecarts == [], ecarts
