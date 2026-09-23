"""Historique Ctrl Flux : la situation actuelle ne garde que le dernier fichier, l'historique garde tout."""
from pathlib import Path

import pytest

import ctrl_flux as cf
import db
import ui_ctrl_flux

SAUVEGARDE = Path(__file__).resolve().parents[2] / "ControleFolioRose" / "sauvegarde"
ANCIEN, RECENT = SAUVEGARDE / "ExportCSV-04-08-2026.csv", SAUVEGARDE / "ExportCSV-19-08-2026.csv"
pytestmark = pytest.mark.skipif(not (ANCIEN.exists() and RECENT.exists()), reason="exports absents")


def test_ordre_chronologique():
    noms = ["ExportCSV-19-08-2026.csv", "autre.csv", "ExportCSV-04-08-2026.csv", "ExportCSV-03-09-2026.csv"]
    assert [noms[i] for i in cf.ordre_chronologique(noms)] == [
        "autre.csv", "ExportCSV-04-08-2026.csv", "ExportCSV-19-08-2026.csv", "ExportCSV-03-09-2026.csv"]


def test_situation_actuelle_et_historique(tmp_path, monkeypatch):
    base = tmp_path / "t.db"
    monkeypatch.setattr(ui_ctrl_flux, "connect", lambda: db.connect(base))
    # lot donné dans le désordre : le plus récent devient la situation actuelle
    msgs = ui_ctrl_flux._importer_fichiers([RECENT, ANCIEN])
    assert msgs[-1] == f"Situation actuelle : {RECENT.name}"
    con = db.connect(base)
    ancien, recent = cf.lire_export(ANCIEN), cf.lire_export(RECENT)
    courant = cf.lignes(con, disparues=True)
    assert set(courant["empreinte"]) == set(recent.lignes["empreinte"])       # seulement le dernier fichier
    h = cf.historique(con)
    assert set(h["empreinte"]) == set(ancien.lignes["empreinte"]) | set(recent.lignes["empreinte"])
    assert len(cf.exports_historiques(con)) == 2
    communes = set(ancien.lignes["empreinte"]) & set(recent.lignes["empreinte"])
    if communes:
        e = next(iter(communes))
        r = h.set_index("empreinte").loc[e]
        assert r["nb_exports"] == 2 and r["premier_vu"] == "2026-08-04" and r["dernier_vu"] == "2026-08-19"
        assert r["dernier_export"] == RECENT.name and bool(r["dans_dernier"])
    seulement_ancien = set(ancien.lignes["empreinte"]) - set(recent.lignes["empreinte"])
    if seulement_ancien:
        assert not h.set_index("empreinte").loc[next(iter(seulement_ancien)), "dans_dernier"]
    con.close()


def test_vieux_fichier_n_ecrase_pas_une_valeur_plus_recente(tmp_path):
    con = db.connect(tmp_path / "t.db")
    recent = cf.lire_export(RECENT)
    cf.historiser(recent, con)
    e = recent.lignes.iloc[0]["empreinte"]
    con.execute("UPDATE fr_historique SET commentaire = 'valeur récente' WHERE empreinte = ?", (e,))
    con.commit()
    vieux = cf.lire_export(RECENT)
    vieux.date_export = vieux.date_export.replace(year=2025)
    vieux.file_hash = "autre-hash"
    cf.historiser(vieux, con)                                                  # plus ancien : bornes seulement
    r = cf.historique(con).set_index("empreinte").loc[e]
    assert r["commentaire"] == "valeur récente" and r["premier_vu"].startswith("2025") and r["nb_exports"] == 2
    cf.historiser(recent, con)                                                 # même fichier : pas recompté
    assert cf.historique(con).set_index("empreinte").loc[e, "nb_exports"] == 2
    con.close()


def test_vider_etat_garde_l_historique(tmp_path):
    con = db.connect(tmp_path / "t.db")
    cf.importer(cf.lire_export(RECENT), con)
    cf.vider_etat(con)
    assert cf.lignes(con).empty and len(cf.historique(con)) > 0
    con.close()
