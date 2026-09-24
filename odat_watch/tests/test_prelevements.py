"""Pont Prélèvements : config, dates disponibles, relecture du dernier rapport, chiffres des tuiles."""
import json
from datetime import date
from pathlib import Path

import prelevements as pv


def _rapport(dossier: Path, base: str, statut_global="OK", par_statut=None, avertissements=(), lignes_ko=0,
             doublons=""):
    """Fabrique un rapport complet (csv, justifications, doublons, xlsx factice, résumé JSON) au format de l'outil."""
    dossier.mkdir(parents=True, exist_ok=True)
    (dossier / f"{base}_doublons.csv").write_text(
        "type;reference;rum;iban_creancier;iban_debiteur;beneficiaire;echeance;montant;nb;fichiers;emissions\n"
        + doublons, encoding="utf-8-sig")
    (dossier / f"{base}.csv").write_text(
        "iban_creancier;echeance;nb_oracle;montant_oracle;nb_edf;montant_edf;ecart_nb;ecart_montant;"
        "nb_rejets;montant_rejets;codes_rejets;statut;emissions;tranches_edf\n"
        "FR76A;30/09/2026;589;2780219.23;0;0;589;2780219.23;0;0;;EN_ATTENTE;10/09/2026;\n"
        "FR76B;15/09/2026;3;300.00;3;300.00;0;0;0;0;;RAPPROCHE;01/09/2026;03/09:3\n",
        encoding="utf-8-sig")
    (dossier / f"{base}_justifications.csv").write_text(
        "echeance;iban_creancier;cause;nb;montant;beneficiaire;rum;iban_debiteur;code;motif;emission;"
        "fichier_oracle;fichier_rejet;fichier_edf;statut_cle;ecart_nb_cle;ecart_montant_cle\n"
        "30/09/2026;FR76A;INEXPLIQUE;589;2780219.23;;;;;;10/09/2026;DKA-20260910-1_PCLFRST.txt;;;EN_ATTENTE;589;2780219.23\n",
        encoding="utf-8-sig")
    (dossier / f"{base}.xlsx").write_bytes(b"PK")
    (dossier / f"{base}_resume.json").write_text(json.dumps({
        "code": {"OK": 0, "ANOMALIES": 1, "ERREUR": 2, "DEGRADE": 3}[statut_global],
        "statut_global": statut_global, "base": base, "dossier": str(dossier),
        "reference": "2026-09-14", "genere_le": "2026-09-14T08:14:00",
        "par_statut": par_statut or {"RAPPROCHE": {"cles": 1, "nb": 3, "montant": "300.00"},
                                     "EN_ATTENTE": {"cles": 1, "nb": 589, "montant": "2780219.23"}},
        "nb_anomalies": 0, "nb_signales": 0, "nb_a_investiguer": 1, "nb_justifications": 1,
        "nb_justifie_par_rejet": 0, "nb_lignes_ko": lignes_ko, "avertissements": list(avertissements),
        "contexte": {"Lignes Oracle": 592, "Lignes EDF": 3, "Rejets retenus": 0, "Clés rapprochées": 2},
    }), encoding="utf-8")


def test_config_par_defaut_sans_section(monkeypatch, tmp_path):
    monkeypatch.setattr(pv, "CONFIG", tmp_path / "absent.ini")
    cfg = pv.config_prelevements()
    assert cfg["outil"].name == "CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS"
    assert cfg["racine"].parts[-2:] == ("ODAT", "Prelevements")
    assert cfg["jours"] == 10 and cfg["nom_si"] == "ORACLE"


def test_config_lue_depuis_config_ini(monkeypatch, tmp_path):
    ini = tmp_path / "config.ini"
    ini.write_text("[prelevements]\noutil = C:\\outil\nracine = D:\\donnees\njours = 15\nnom_si = CIF\n", encoding="utf-8")
    monkeypatch.setattr(pv, "CONFIG", ini)
    cfg = pv.config_prelevements()
    assert cfg["outil"] == Path(r"C:\outil") and cfg["racine"] == Path(r"D:\donnees")
    assert cfg["jours"] == 15 and cfg["nom_si"] == "CIF"


def test_dates_disponibles_les_plus_recentes_d_abord(tmp_path):
    r = tmp_path / "RAPPORTS"
    _rapport(r, "Rapprochement_Cle_Metier_20260806_120000")
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400")
    _rapport(r, "Rapprochement_Cle_Metier_20260914_093000")
    assert pv.dates_disponibles(tmp_path / "RAPPORTS") == [date(2026, 9, 14), date(2026, 8, 6)]


def test_dates_disponibles_sans_dossier(tmp_path):
    assert pv.dates_disponibles(tmp_path / "RAPPORTS") == []


def test_lire_rapport_prend_le_plus_recent_de_la_date(tmp_path):
    r = tmp_path / "RAPPORTS"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400", statut_global="ANOMALIES")
    _rapport(r, "Rapprochement_Cle_Metier_20260914_093000")
    rapport = pv.lire_rapport(tmp_path / "RAPPORTS", date(2026, 9, 14))
    assert rapport["base"].endswith("_093000") and rapport["resume"]["statut_global"] == "OK"
    assert list(rapport["rapprochement"]["statut"]) == ["EN_ATTENTE", "RAPPROCHE"]
    assert len(rapport["justifications"]) == 1 and rapport["xlsx"].is_file()


def test_lire_rapport_absent(tmp_path):
    assert pv.lire_rapport(tmp_path / "RAPPORTS", date(2026, 9, 14)) is None


def test_lire_rapport_sans_resume_json_reste_lisible(tmp_path):
    """Rapports produits avant executer() : pas de _resume.json → statut global INCONNU, tables lues quand même."""
    r = tmp_path / "RAPPORTS"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400")
    (r / "Rapprochement_Cle_Metier_20260914_081400_resume.json").unlink()
    rapport = pv.lire_rapport(tmp_path / "RAPPORTS", date(2026, 9, 14))
    assert rapport["resume"]["statut_global"] == "INCONNU" and len(rapport["rapprochement"]) == 2


def test_resume_chiffres_des_tuiles(tmp_path):
    r = tmp_path / "RAPPORTS"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400", avertissements=["Aucun fichier EDF depuis 2026-09-11 (3 jours)"])
    res = pv.resume(pv.lire_rapport(tmp_path / "RAPPORTS", date(2026, 9, 14)))
    assert res["statut_global"] == "OK" and res["nb_cles"] == 2
    assert res["nb_emis"] == 592 and round(res["montant_emis"], 2) == 2780519.23
    assert res["en_attente"] == 1 and res["anomalies"] == 0 and res["signales"] == 0
    assert res["a_investiguer"] == 1 and res["avertissements"] == 1 and res["lignes_ko"] == 0


def test_par_statut_respecte_l_ordre_metier(tmp_path):
    r = tmp_path / "RAPPORTS"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400")
    groupes = pv.par_statut(pv.lire_rapport(tmp_path / "RAPPORTS", date(2026, 9, 14))["rapprochement"])
    assert [s for s, _ in groupes] == ["RAPPROCHE", "EN_ATTENTE"]
    assert len(groupes[1][1]) == 1


def test_lancer_capture_le_journal(monkeypatch, tmp_path):
    import sys
    import types
    faux = types.ModuleType("rapprochement_cle_metier")

    def executer(**kw):
        print("Oracle : 2 fichier(s)")
        print("AVERTISSEMENT : test", file=sys.stderr)
        return {"statut_global": "OK", "base": "x"}
    faux.executer = executer
    monkeypatch.setitem(sys.modules, "rapprochement_cle_metier", faux)
    res = pv.lancer(date(2026, 9, 21), {"outil": tmp_path, "racine": tmp_path, "jours": 10, "nom_si": "ORACLE", "oracle": tmp_path / "ORACLE",
                                             "edf": tmp_path / "EDF", "rejets": tmp_path / "REJETS", "rapports": tmp_path / "RAPPORTS"})
    assert res["journal"] == "Oracle : 2 fichier(s)\nAVERTISSEMENT : test"


def test_resume_ignore_les_similitudes_des_anciens_rapports(tmp_path):
    r = tmp_path / "RAPPORTS"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400",
             doublons="DOUBLON;P1;RUM1;FR76A;FR76D;X;30/09/2026;100.00;2;f1 + f2;11/09/2026 + 12/09/2026\n"
                      "SIMILITUDE;P2 + P3;RUM2;FR76A;FR76D;Y;30/09/2026;50.00;2;f1;11/09/2026\n")
    res = pv.resume(pv.lire_rapport(tmp_path / "RAPPORTS", date(2026, 9, 14)))
    assert res["doublons"] == 1 and "similitudes" not in res


def test_resume_sans_fichier_doublons(tmp_path):
    """Rapports anciens : pas de _doublons.csv → 0, pas d'erreur."""
    r = tmp_path / "RAPPORTS"
    _rapport(r, "Rapprochement_Cle_Metier_20260914_081400")
    (r / "Rapprochement_Cle_Metier_20260914_081400_doublons.csv").unlink()
    res = pv.resume(pv.lire_rapport(tmp_path / "RAPPORTS", date(2026, 9, 14)))
    assert res["doublons"] == 0


def test_config_sous_dossiers(monkeypatch, tmp_path):
    ini = tmp_path / "config.ini"
    ini.write_text("[prelevements]\n" r"racine = D:\pv" "\ndossier_edf = CASH\n" r"dossier_rapports = E:\rapports" "\n",
                   encoding="utf-8")
    monkeypatch.setattr(pv, "CONFIG", ini)
    cfg = pv.config_prelevements()
    assert cfg["oracle"] == Path(r"D:\pv\ORACLE") and cfg["edf"] == Path(r"D:\pv\CASH")
    assert cfg["rejets"] == Path(r"D:\pv\REJETS") and cfg["rapports"] == Path(r"E:\rapports")
