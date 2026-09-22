"""Rapport HTML Folio Rose (pur)."""
from pathlib import Path

import pandas as pd

import db
import folio_rose as fr
import rapport_folio_rose as rp

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"


def _contexte(tmp_path):
    con = db.connect(tmp_path / "t.db")
    e = fr.lire_export(SAUVEGARDE / "ExportCSV-19-08-2026.csv")
    fr.importer(e, con)
    lignes = fr.lignes(con)
    return con, e, lignes


def test_rapport_complet(tmp_path):
    con, e, lignes = _contexte(tmp_path)
    lignes.loc[lignes.index[0], "commentaire"] = "a <b> & c"
    h = rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    assert "Folio Rose — export du 19/08/2026" in h
    assert "a &lt;b&gt; &amp; c" in h and "<b>" not in h.split("</style>")[1]
    for titre in ("Synthèse par type", "Synthèse par folio", "Détail des lignes", "Rapprochements"):
        assert f"<h2>{titre}" in h
    assert h.count("<tr") - 6 >= len(lignes)          # lignes colorées (<tr class=...>) hors en-têtes des 5 tableaux
    assert 'class="bandeau' in h
    con.close()


def test_bandeau_ko_si_ko(tmp_path):
    con, e, lignes = _contexte(tmp_path)
    lignes["statut"] = "OK"
    assert 'bandeau ok' in rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    lignes.loc[lignes.index[0], "statut"] = "KO"
    assert 'bandeau ko' in rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    con.close()


def test_ligne_orange_interface_en_attente(tmp_path):
    con, e, lignes = _contexte(tmp_path)
    assert "tr class='orange'" not in rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    i = lignes.index[0]
    lignes.loc[i, ["nb_interface", "montant_interface", "nb_oracle", "montant_oracle"]] = [2, 50.0, 0, 0.0]
    lignes.loc[i, "statut"] = "KO"
    h = rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    assert h.count("tr class='orange'") == 1 and "tr.orange td" in h
    con.close()


def test_ligne_gdr(tmp_path):
    con, e, lignes = _contexte(tmp_path)
    lignes["gdr"] = ""
    assert "tr class='gdr'" not in rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    lignes.loc[lignes.index[0], "gdr"] = "1 pièce dans la GDR · 12,00 € = l'écart débit"
    lignes.loc[lignes.index[1], "gdr"] = "probable : 2 pièces dans la GDR · 30,00 €"
    h = rp.construire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con))
    assert h.count("tr class='gdr'") == 1                     # « probable » ne colore pas la ligne
    assert "1 pièce dans la GDR" in h and "GDR (rejets)" in h and "tr.gdr td" in h
    con.close()


def test_ecrire(tmp_path):
    con, e, lignes = _contexte(tmp_path)
    p = rp.ecrire(e, lignes, fr.groupes_compenses(lignes), fr.rapprochements(con), tmp_path)
    assert p.name.startswith("Folio_Rose_20260819_") and p.read_text(encoding="utf-8").startswith("<!DOCTYPE html>")
    con.close()
