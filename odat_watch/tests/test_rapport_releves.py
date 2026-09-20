"""Rapport HTML de l'onglet Relevés bancaires, généré sur le jeu de données réel."""
from datetime import date
from pathlib import Path

import db
import rapport_releves as rr
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"
CFG = dict(dossier_pfe=REF / "fluxPFE", dossier_ebs=REF / "fichierBanque",
           dossiers_logs=[REF / "import", REF / "controle"], banque_flux_b="30003",
           comptes_connus=["30003/03620/00020137269", "16807/00166/31990892212"])


def test_rapport_complet(tmp_path):
    con = db.connect(tmp_path / "t.db")
    rb.scanner_tout(CFG, con)
    bilan = rr.Bilan(journee=rb.journee(con, date(2026, 9, 15), CFG), chronologie=rb.chronologie(con, 15, date(2026, 9, 18)),
                     continuite=rb.continuite(con, CFG), plan=rb.plan_reprise(con, CFG),
                     pfe=rb.rapprochement_pfe(con), controles=rb.controles(con))
    html = rr.construire(bilan)
    for titre in ("Matinée du 15/09/2026", "Flux A", "Flux B", "Chronologie des imports", "Continuité",
                  "Plan de reprise", "Rapprochement PFE", "Contrôles"):
        assert titre in html
    assert "compt_AFB120_RELEVESDECOMPTE_260915-081614.txt" in html and "bandeau ko" in html
    chemin = rr.ecrire(bilan, tmp_path)
    assert chemin.name.startswith("Releves_20260915_") and chemin.suffix == ".html"


def test_echappement(tmp_path):
    con = db.connect(tmp_path / "t.db")
    j = rb.journee(con, date(2026, 9, 15), CFG)
    j.flux["A"].causes.append("<script>alert(1)</script>")
    html = rr.construire(rr.Bilan(journee=j))
    assert "<script>alert" not in html and "&lt;script&gt;" in html


def test_accesseurs_tabulaires(tmp_path):
    con = db.connect(tmp_path / "t.db")
    rb.scanner_tout(CFG, con)
    pfe = rb.rapprochement_pfe(con)
    assert len(pfe) == 13 and list(pfe["horodatage"]) == sorted(pfe["horodatage"])
    statut = dict(zip(pfe["uuid"], pfe["statut"]))
    assert statut["2b6da61b5e384790970e4ab0b536102e"] == "non reçu"
    assert statut["9098a5f957a749dd8e1545f9e9b68199"] == "reçu"
    assert statut["d114a1fb5eeb483980d10171ec11a136"] == "reçu · rejeté Erreur 025"     # TARGET du 17/09 08:16
    ctl = rb.controles(con)
    assert len(ctl) == 18 and ctl.iloc[0]["request_id"] == 49069921
    lignes = rb.lignes_controle(con, 49069921)
    assert len(lignes) == 208 and lignes.iloc[0]["banque"] == "16807"
    assert rb.rapprochement_pfe(db.connect(tmp_path / "vide.db")).empty


def test_t_valeurs_manquantes_pandas():
    import pandas as pd
    import rapport_releves as rr
    assert rr._t(pd.NA) == "" and rr._t(pd.NaT) == "" and rr._t(None) == "" and rr._t("x") == "x"


def test_continuite_du_rapport_hors_comptes_connus(tmp_path):
    con = db.connect(tmp_path / "t.db")
    rb.scanner_tout(CFG, con)
    j = rb.journee(con, date(2026, 9, 18), CFG)
    html = rr.construire(rr.Bilan(journee=j, continuite=rb.continuite(con, CFG)))
    assert "30003.01100.00020398294" in html and "30003.03620.00020137269" not in html      # compte connu exclu

