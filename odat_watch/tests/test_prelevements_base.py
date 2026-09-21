"""Prélèvements en base : fichiers EDF et rejets persistants, historique des rapprochements, vues trésorerie."""
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path

import db
import prelevements as pv


def _res(tmp_path: Path, statut="OK", **maj) -> dict:
    """Ce que renvoie rapprochement_cle_metier.executer, réduit aux clés utilisées par l'enregistrement."""
    edf, rejets = tmp_path / "EDF", tmp_path / "REJETS"
    edf.mkdir(exist_ok=True)
    rejets.mkdir(exist_ok=True)
    (edf / "IMPORT_AVP_DK.20260913.070100.csv").write_text("NOM DU SI;IBAN;ECH;NB;MONTANT;\nORACLE;FR76A;30/09/2026;1;100,00;\n")
    (edf / "IMPORT_AVP_DK.20260914.070100.csv").write_text("NOM DU SI;IBAN;ECH;NB;MONTANT;\nORACLE;FR76A;30/09/2026;2;250,00;\n")
    (edf / "IMPORT_AVP_DK.20260915.070100.csv").write_text("NOM DU SI;IBAN;ECH;NB;MONTANT;\nCIF;FR76C;30/09/2026;1;5,00;\n")
    (rejets / "REJETS_INTERNES_DK.20260914.070000.csv").write_text("x\n")
    res = {"code": 0, "statut_global": statut, "base": "Rapprochement_Cle_Metier_20260914_081400",
           "dossier": tmp_path / "rapport", "reference": date(2026, 9, 14),
           "par_statut": {"RAPPROCHE": {"cles": 3, "nb": 10, "montant": Decimal("1000.00")},
                          "EN_ATTENTE": {"cles": 1, "nb": 2, "montant": Decimal("250.00")}},
           "nb_anomalies": 0, "nb_signales": 0, "nb_a_investiguer": 0, "nb_doublons": 0, "nb_similitudes": 1,
           "nb_lignes_ko": 0, "avertissements": [], "contexte": {"Lignes Oracle": 12},
           "dossier_edf": str(edf), "dossier_rejets": str(rejets),
           "fichiers_edf": [{"fichier": "IMPORT_AVP_DK.20260913.070100.csv", "date_fichier": date(2026, 9, 13)},
                            {"fichier": "IMPORT_AVP_DK.20260914.070100.csv", "date_fichier": date(2026, 9, 14)},
                            {"fichier": "IMPORT_AVP_DK.20260915.070100.csv", "date_fichier": date(2026, 9, 15)}],   # sans ligne ORACLE
           "fichiers_rejets": [{"fichier": "REJETS_INTERNES_DK.20260914.070000.csv", "date_fichier": date(2026, 9, 14)}],
           "edf": [{"fichier": "IMPORT_AVP_DK.20260913.070100.csv", "date_fichier": date(2026, 9, 13), "nom_si": "ORACLE",
                    "iban_creancier": "FR76A", "echeance": date(2026, 9, 30), "nb": 1, "montant": Decimal("100.00")},
                   {"fichier": "IMPORT_AVP_DK.20260914.070100.csv", "date_fichier": date(2026, 9, 14), "nom_si": "ORACLE",
                    "iban_creancier": "FR76A", "echeance": date(2026, 9, 30), "nb": 2, "montant": Decimal("250.00")}],
           "rejets": [{"fichier": "REJETS_INTERNES_DK.20260914.070000.csv", "date_fichier": date(2026, 9, 14),
                       "iban_creancier": "FR76A", "rum": "RUM1", "iban_debiteur": "FR76D", "echeance": date(2026, 9, 30),
                       "montant": Decimal("50.00"), "code": "AM04", "motif": "Provision insuffisante", "appariee": True,
                       "beneficiaire": "CLIENT X"}]}
    res.update(maj)
    return res


def test_tables_creees(tmp_path):
    con = db.connect(tmp_path / "t.db")
    noms = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"pv_fichiers", "pv_edf", "pv_rejets", "pv_histo"} <= noms
    con.close()


def test_enregistrer_est_idempotent(tmp_path):
    con = db.connect(tmp_path / "t.db")
    hid = pv.enregistrer(_res(tmp_path), con, quand=datetime(2026, 9, 21, 8, 0))
    assert hid == 1
    fichiers = {r[0]: tuple(r) for r in con.execute("SELECT nom, genre, date_fichier, nb_lignes, taille FROM pv_fichiers")}
    assert fichiers["IMPORT_AVP_DK.20260913.070100.csv"][1:] == ("EDF", "2026-09-13", 1, fichiers["IMPORT_AVP_DK.20260913.070100.csv"][4])
    assert fichiers["REJETS_INTERNES_DK.20260914.070000.csv"][1:4] == ("REJET", "2026-09-14", 1)
    assert fichiers["IMPORT_AVP_DK.20260913.070100.csv"][4] > 0
    edf = [tuple(r) for r in con.execute("SELECT date_fichier, iban_creancier, echeance, nb, montant FROM pv_edf ORDER BY date_fichier")]
    assert edf == [("2026-09-13", "FR76A", "2026-09-30", 1, 100.0), ("2026-09-14", "FR76A", "2026-09-30", 2, 250.0)]
    rej = [tuple(r) for r in con.execute("SELECT date_fichier, rum, code, montant, appariee, beneficiaire FROM pv_rejets")]
    assert rej == [("2026-09-14", "RUM1", "AM04", 50.0, 1, "CLIENT X")]
    # second enregistrement (relance) : rien ne se duplique, l'historique s'allonge
    pv.enregistrer(_res(tmp_path, statut="ANOMALIES", nb_anomalies=1), con, quand=datetime(2026, 9, 21, 9, 0))
    assert con.execute("SELECT COUNT(*) FROM pv_edf").fetchone()[0] == 2
    assert con.execute("SELECT COUNT(*) FROM pv_rejets").fetchone()[0] == 1
    assert con.execute("SELECT COUNT(*) FROM pv_fichiers").fetchone()[0] == 4
    assert con.execute("SELECT nb_lignes FROM pv_fichiers WHERE nom='IMPORT_AVP_DK.20260915.070100.csv'").fetchone()[0] == 0
    h = pv.historique(30, con)
    assert len(h) == 1 and h.loc[0, "statut_global"] == "ANOMALIES" and int(h.loc[0, "en_attente"]) == 1
    assert int(h.loc[0, "nb_emis"]) == 12 and int(h.loc[0, "anomalies"]) == 1
    con.close()


def test_tresorerie_chronologie_et_rejets(tmp_path):
    con = db.connect(tmp_path / "t.db")
    pv.enregistrer(_res(tmp_path), con, quand=datetime(2026, 9, 21, 8, 0))
    t = pv.tresorerie(con, jours=30, reference=date(2026, 9, 15))
    chrono = t["chronologie"]
    assert list(chrono["date_fichier"]) == ["2026-09-15", "2026-09-14", "2026-09-13"]
    assert int(chrono.loc[chrono["date_fichier"] == "2026-09-14", "nb"].iloc[0]) == 2
    assert int(chrono.loc[chrono["date_fichier"] == "2026-09-14", "rejets"].iloc[0]) == 1
    # un état reçu sans ligne ORACLE (15/09) compte comme reçu : aucun jour ouvré manquant entre le 13/09 et le 15/09
    assert t["jours_sans_etat"] == []
    assert list(t["rejets"]["rum"]) == ["RUM1"]
    assert t["recidives"].empty                       # un seul rejet pour ce mandat
    # un second rejet du même mandat -> récidive
    res = _res(tmp_path)
    res["rejets"].append(dict(res["rejets"][0], fichier="REJETS_INTERNES_DK.20260915.070000.csv",
                              date_fichier=date(2026, 9, 15), montant=Decimal("60.00")))
    (tmp_path / "REJETS" / "REJETS_INTERNES_DK.20260915.070000.csv").write_text("y\n")
    pv.enregistrer(res, con, quand=datetime(2026, 9, 21, 9, 0))
    t = pv.tresorerie(con, jours=30, reference=date(2026, 9, 15))
    assert list(t["recidives"]["rum"]) == ["RUM1"] and int(t["recidives"]["nb_rejets"].iloc[0]) == 2
    con.close()


def test_fichiers_absents_du_dossier(tmp_path):
    con = db.connect(tmp_path / "t.db")
    res = _res(tmp_path)
    pv.enregistrer(res, con)
    (tmp_path / "EDF" / "IMPORT_AVP_DK.20260913.070100.csv").unlink()
    absents = pv.fichiers_absents(con, Path(res["dossier_edf"]), Path(res["dossier_rejets"]))
    assert absents == ["IMPORT_AVP_DK.20260913.070100.csv"]
    con.close()
