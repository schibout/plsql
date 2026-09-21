"""Virements en base : instances importées, envois vers la banque, historique des contrôles."""
from datetime import datetime
from pathlib import Path

import db
import virements as vr

COLONNES = {c: n for c, n, _ in vr.CSV_RAPPORT}


def rapport_factice(dossier: Path, ok: bool = True) -> Path:
    """Dossier rapport_<date> minimal au format de l'outil (synthèses + CSV, ; comme séparateur)."""
    dossier.mkdir(parents=True, exist_ok=True)
    etat = "✅ Conforme" if ok else "⚠️ À examiner"
    (dossier / "synthese.md").write_text(f"# Synthèse\n---\n**Résultat : {etat}**\n", encoding="utf-8")
    (dossier / "synthese_simple.md").write_text(
        f"# Contrôle des virements — synthèse rapide\n\n**Résultat : {etat}**\n\n"
        "- Transmis à la banque : **205 virements** pour **2 667 877,07 EUR**\n"
        "- Retour trésorerie : non fourni (rapprochement non réalisé)\n\n"
        + ("Aucune anomalie.\n" if ok else "## Points d'attention\n\n- **1 envoi(s) transmis en double** à la banque.\n"),
        encoding="utf-8")
    vide = {c: "" for c in COLONNES}
    (dossier / COLONNES["totaux_edf"]).write_text(
        "guid;fichier_edf;nb_sources_regroupees;nb_ack_footer;nb_ack_detail;nb_oracle_edf;nb_somme_sources;"
        "montant_ack_footer;montant_ack_detail;montant_oracle_edf;montant_somme_sources;statut_lignes;statut_montant\n"
        "uuid1;CDPG.NC4.IMPORT_ACK.A;8;130;130;130;130;196878690;196878690;196878690;196878690;OK;OK\n"
        "uuid1;CDPG.NC4.IMPORT_ACK.B;2;75;75;75;75;69909017;69909017;69909017;69909017;OK;OK\n", encoding="utf-8")
    (dossier / COLONNES["fichiers"]).write_text(
        "guid;categorie;fichier;statut;detail\nuuid1;DK_FIN01_cible;DK_FIN01_x.txt;OK;\nuuid1;ACK;CDPG.NC4.IMPORT_ACK.A;OK;\n"
        "uuid1;ACK;CDPG.NC4.IMPORT_ACK.B;OK;\n", encoding="utf-8")
    if not ok:
        (dossier / COLONNES["doublons_ack"]).write_text("fichier;nb;montant\nCDPG.NC4.IMPORT_ACK.A;130;1968786.90\n", encoding="utf-8")
    for cle, nom in COLONNES.items():
        if not (dossier / nom).exists():
            (dossier / nom).write_text("", encoding="utf-8")
    return dossier


def resultat_factice(dossier: Path, ok: bool = True) -> dict:
    """Ce que renvoie controle_virements.executer, réduit aux clés utilisées par l'enregistrement."""
    return {"ok": ok, "dossier": dossier, "nb_instances": 1, "quartz": False, "cible_seul": True,
            "fichiers": [{"guid": "uuid1", "categorie": "DK_FIN01_cible", "fichier": "DK_FIN01_x.txt", "statut": "OK"},
                         {"guid": "uuid1", "categorie": "ACK", "fichier": "CDPG.NC4.IMPORT_ACK.A", "statut": "OK"},
                         {"guid": "uuid1", "categorie": "ACK", "fichier": "CDPG.NC4.IMPORT_ACK.B", "statut": "OK"}],
            "totaux_edf": [{"guid": "uuid1", "fichier_edf": "CDPG.NC4.IMPORT_ACK.A", "nb_ack_footer": 130,
                            "montant_ack_footer": 196878690, "statut_lignes": "OK", "statut_montant": "OK"},
                           {"guid": "uuid1", "fichier_edf": "CDPG.NC4.IMPORT_ACK.B", "nb_ack_footer": 75,
                            "montant_ack_footer": 69909017, "statut_lignes": "OK", "statut_montant": "OK"}]}


def test_tables_creees(tmp_path):
    con = db.connect(tmp_path / "t.db")
    noms = {r[0] for r in con.execute("SELECT name FROM sqlite_master WHERE type='table'")}
    assert {"vir_imports", "vir_histo", "vir_envois"} <= noms
    con.close()


def test_enregistrer_puis_historique(tmp_path):
    con = db.connect(tmp_path / "t.db")
    dossier = rapport_factice(tmp_path / "rapport_18092026")
    hid = vr.enregistrer("18092026", resultat_factice(dossier), con, quand=datetime(2026, 9, 21, 8, 0))
    assert hid == 1
    imp = con.execute("SELECT guid, date_ctrl, nb_fichiers, nb_envois, cible_seul FROM vir_imports").fetchall()
    assert [tuple(r) for r in imp] == [("uuid1", "2026-09-18", 3, 2, 1)]
    env = [tuple(r) for r in con.execute("SELECT date_ctrl, guid, fichier_ack, nb, montant, statut FROM vir_envois ORDER BY fichier_ack")]
    assert env == [("2026-09-18", "uuid1", "CDPG.NC4.IMPORT_ACK.A", 130, 1968786.90, "OK"),
                   ("2026-09-18", "uuid1", "CDPG.NC4.IMPORT_ACK.B", 75, 699090.17, "OK")]
    h = vr.historique(30, con)
    assert list(h["date_ctrl"]) == ["2026-09-18"] and int(h.loc[0, "nb_envoyes"]) == 205 and int(h.loc[0, "ok"]) == 1
    assert round(float(h.loc[0, "montant_envoye"]), 2) == 2667877.07
    # relancer la même journée : l'instance reste unique, les envois sont remplacés, l'historique s'allonge
    rapport_factice(dossier, ok=False)
    vr.enregistrer("18092026", resultat_factice(dossier, ok=False), con, quand=datetime(2026, 9, 21, 9, 0))
    assert con.execute("SELECT COUNT(*) FROM vir_imports").fetchone()[0] == 1
    assert con.execute("SELECT COUNT(*) FROM vir_envois").fetchone()[0] == 2
    assert con.execute("SELECT COUNT(*) FROM vir_histo").fetchone()[0] == 2
    h = vr.historique(30, con)                     # une ligne par jour : la dernière exécution
    assert len(h) == 1 and int(h.loc[0, "ok"]) == 0 and int(h.loc[0, "ko"]) == 1
    assert vr.imports_connus(con) == {"uuid1": "2026-09-18"}
    con.close()
