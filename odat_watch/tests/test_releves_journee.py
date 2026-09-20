"""Verdict par flux, chronologie, continuité et plan de reprise sur le jeu de données complet de l'incident."""
from datetime import date
from pathlib import Path

import pytest

import db
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"
CFG = dict(dossier_pfe=REF / "fluxPFE", dossier_ebs=REF / "fichierBanque",
           dossiers_logs=[REF / "import", REF / "controle"], banque_flux_b="30003",
           comptes_connus=["30003/03620/00020137269", "16807/00166/31990892212"])


@pytest.fixture(scope="module")
def con(tmp_path_factory):
    con = db.connect(tmp_path_factory.mktemp("rb") / "t.db")
    rb.scanner_tout(CFG, con)
    return con


def test_scanner_tout_journal(con):
    assert con.execute("SELECT COUNT(*) FROM rb_pfe").fetchone()[0] == 13
    assert con.execute("SELECT COUNT(*) FROM rb_ebs").fetchone()[0] == 22
    # 34 requests : 16 imports + 18 contrôles (48991448, rangé dans import/, est un contrôle)
    assert con.execute("SELECT COUNT(*) FROM rb_imports").fetchone()[0] == 16
    assert con.execute("SELECT COUNT(*) FROM rb_controles").fetchone()[0] == 18
    assert "30003/03620/00020137269" in rb.comptes_connus(con)
    # l'import de 08:19:53 est relié au fichier EBS de la même minute
    r = con.execute("SELECT e.nom FROM rb_imports i JOIN rb_ebs e ON e.md5 = i.md5_ebs WHERE i.request_id=49061539").fetchone()
    assert r["nom"] == "AFB120.txt_20260917081953"


def test_journee_15_09_flux_b_non_recu(con):
    j = rb.journee(con, date(2026, 9, 15), CFG)
    a, b = j.flux["A"], j.flux["B"]
    assert a.verdict == "OK" and a.pfe["uuid"] == "9098a5f957a749dd8e1545f9e9b68199" and a.import_["request_id"] == 49041437
    assert b.verdict == "KO" and b.pfe["uuid"] == "2b6da61b5e384790970e4ab0b536102e"
    assert b.ebs is None and b.import_ is None
    assert any("non reçu" in c for c in b.causes)
    assert j.verdict == "KO"


def test_journee_17_09_rejet_025(con):
    b = rb.journee(con, date(2026, 9, 17), CFG).flux["B"]
    assert b.verdict == "KO" and b.import_["request_id"] == 49061539
    assert any("Erreur 025" in c for c in b.causes)


def test_journee_14_09_ok_avec_erreurs_connues(con):
    j = rb.journee(con, date(2026, 9, 14), CFG)
    assert j.flux["B"].verdict == "OK" and j.flux["B"].import_["request_id"] == 49029106


def test_journee_12_09_samedi_flux_a_seul(con):
    """Samedi 12/09 : le flux A a tourné (PFE, import 49025145), la SG ne produit rien -> flux B « — », pas d'alerte."""
    j = rb.journee(con, date(2026, 9, 12), CFG)
    a, b = j.flux["A"], j.flux["B"]
    assert j.motif == "samedi"
    assert b.verdict == "—" and b.pfe is None and b.import_ is None and b.causes == []
    assert a.verdict == "OK" and a.import_["request_id"] == 49025145
    assert j.verdict == "OK"


def test_journee_flux_b_absent_un_jour_ouvre(con):
    """Jour ouvré sans aucune trace du flux B : WARN avec une cause « PFE » (aucune date réelle du jeu : on isole le flux)."""
    con.execute("SAVEPOINT s")
    try:
        con.execute("DELETE FROM rb_pfe WHERE flux='B' AND substr(horodatage,1,10)='2026-09-11'")
        con.execute("DELETE FROM rb_ebs WHERE flux='B' AND substr(horodatage,1,10)='2026-09-11'")
        con.execute("DELETE FROM rb_imports WHERE flux='B' AND substr(debut,1,10)='2026-09-11'")
        b = rb.journee(con, date(2026, 9, 11), CFG).flux["B"]       # vendredi
        assert b.verdict == "WARN" and b.pfe is None and any("PFE" in c for c in b.causes)
    finally:
        con.execute("ROLLBACK TO s")
        con.execute("RELEASE s")
    assert rb.journee(con, date(2026, 9, 11), CFG).flux["B"].import_["request_id"] == 49014213   # données restaurées


def test_journee_week_end(con):
    j = rb.journee(con, date(2026, 9, 13), CFG)       # dimanche : ni PFE ni import
    assert j.verdict == "—" and j.motif == "dimanche"
    assert all(f.verdict == "—" for f in j.flux.values())


def test_etapes_de_la_frise(con):
    b = rb.journee(con, date(2026, 9, 15), CFG).flux["B"]
    assert [e["cle"] for e in b.etapes] == ["pfe", "controlm", "ebs", "import", "controle"]
    assert b.etapes[0]["ton"] == "ok" and b.etapes[2]["ton"] == "ko"


def test_chronologie(con):
    ch = rb.chronologie(con, jours=15, jour=date(2026, 9, 18))
    r = ch[ch["request_id"] == 49061539].iloc[0]
    # rejet total du 17/09 : 208 × 025 (+ 5 × 001 habituels)
    assert r["fichier"] == "AFB120.txt_20260917081953" and r["flux"] == "B" and r["resultat"].startswith("208 × Erreur 025")
    r = ch[ch["request_id"] == 49029106].iloc[0]
    assert r["resultat"] == "OK" and r["charges"] == 207
    assert list(ch["debut"]) == sorted(ch["debut"])


def test_anomalies_par_flux_18_09(con):
    """18/09 : le contrôle de 07:49:54 (pendant l'import A) compte 128 anomalies non SG, le dernier 0."""
    a = rb.journee(con, date(2026, 9, 18), CFG).flux["A"]
    assert a.controles[0]["request_id"] == 49069846 and a.controles[0]["nb_hors_connus_flux"] == 128
    assert a.controles[-1]["nb_hors_connus_flux"] == 0 and a.verdict == "OK"


def test_journee_14_09_flux_a_ko(con):
    a = rb.journee(con, date(2026, 9, 14), CFG).flux["A"]
    assert a.verdict == "KO" and a.import_["request_id"] == 49029055        # 1 relevé, 0 chargé


def test_import_sans_out_warn(tmp_path):
    import shutil
    d = tmp_path / "logs"
    d.mkdir()
    shutil.copy(REF / "import/l49061539.req", d)
    con = db.connect(tmp_path / "t.db")
    cfg = dict(CFG, dossiers_logs=[d], dossier_pfe=tmp_path / "x", dossier_ebs=tmp_path / "y")
    rb.scanner_tout(cfg, con)
    b = rb.journee(con, date(2026, 9, 17), cfg).flux["B"]
    imp = next(e for e in b.etapes if e["cle"] == "import")
    assert imp["ton"] == "warn" and ".out absent" in imp["texte"]
    assert any("copy_ebs_logs.sh" in c for c in b.causes) and not any("aucun relevé chargé" in c for c in b.causes)
    assert b.verdict == "WARN"


def test_week_end_controle_neutre(con):
    j = rb.journee(con, date(2026, 9, 13), CFG)           # dimanche : contrôle manuel de 18:46 en base
    for f in j.flux.values():
        ctl = next(e for e in f.etapes if e["cle"] == "controle")
        assert ctl["ton"] == "neutral" and "pas d'intégration attendue" in ctl["texte"]


def test_chronologie_fenetre_exacte(con):
    ch = rb.chronologie(con, jours=1, jour=date(2026, 9, 18))
    assert set(ch["debut"].str[:10]) == {"2026-09-18"}


def test_causes_controlm_propagees(tmp_path):
    """Photo ODAT du 15/09 08:06 : la chaîne 06 bloquée remonte dans les causes du flux B."""
    import ingest
    con = db.connect(tmp_path / "t.db")
    rb.scanner_tout(CFG, con)
    path = REF / "FichierODAT" / "Report_ctm_260914_14_8h06.csv"
    rows = ingest.read_rows(path)
    cur = con.execute("INSERT INTO snapshots(odate, snap_time, source_file, file_hash, nb_lignes) VALUES (?,?,?,?,?)",
                      (min(r["odate"] for r in rows if r["odate"]), "2026-09-15 08:06:00", path.name, "h1", len(rows)))
    con.executemany(f"INSERT OR IGNORE INTO ctm_jobs(snapshot_id,{','.join(ingest.COLS)}) VALUES (?{',?' * len(ingest.COLS)})",
                    [(cur.lastrowid, *[r[c] for c in ingest.COLS]) for r in rows])
    con.commit()
    b = rb.journee(con, date(2026, 9, 15), CFG).flux["B"]
    assert next(e for e in b.etapes if e["cle"] == "controlm")["ton"] == "ko"
    assert any("06_ZIP01" in c for c in b.causes) and any("Conflit de chaînes" in c for c in b.causes)
    assert b.verdict == "KO"


def test_continuite_sg(con):
    c = rb.continuite(con, CFG, jour=date(2026, 9, 18))
    assert len(c) >= 200
    r = c[c["compte"] == "30003.01100.00020398294"].iloc[0]
    assert r["dernier_charge"] == "2026-09-11" and r["attendu"] == "2026-09-17" and r["retard_j"] == 6 and r["trou"]
    connu = c[c["compte"] == "30003.03620.00020137269"]
    assert len(connu) == 1 and connu.iloc[0]["connu"]


def test_plan_reprise(con):
    plan = rb.plan_reprise(con, CFG)
    assert [Path(e["chemin"]).name for e in plan] == [
        "compt_AFB120_RELEVESDECOMPTE_260915-081614.txt", "compt_AFB120_RELEVESDECOMPTE_260916-081613.txt",
        "AFB120.txt_20260917081953", "AFB120.txt_20260918082009"]
    assert plan[0]["periode"] == "2026-09-11 → 2026-09-14" and plan[0]["attendu"] == "207 chargés / 6 erreurs"
    assert plan[2]["origine"] == "EBS (rejeté Erreur 025)" and plan[0]["origine"] == "PFE (non reçu)"


def test_plan_reprise_vide_sans_trou(tmp_path):
    con = db.connect(tmp_path / "v.db")
    assert rb.plan_reprise(con, CFG) == []


def test_liste_logs_manquants(con, tmp_path):
    con.execute("INSERT INTO ora_requests(request_id, program_short, phase_code, logfile_name, outfile_name, actual_start) "
                "VALUES (49999999, 'RBAFBIMP', 'C', '/l/l49999999.req', '/o/o49999999.out', '2026-09-19 08:20:00')")
    con.execute("INSERT INTO ora_requests(request_id, program_short, phase_code, logfile_name, outfile_name, actual_start) "
                "VALUES (49061539, 'RBAFBIMP', 'C', '/l/l49061539.req', '/o/o49061539.out', '2026-09-17 08:19:53')")
    con.commit()
    dest = tmp_path / "list.txt"
    msg = rb.liste_logs_manquants(con, dest)
    assert dest.read_text() == "/l/l49999999.req /o/o49999999.out\n" and "1 ligne" in msg


def test_liste_logs_manquants_out_absent(tmp_path):
    """Un import connu par son seul .req reste à rapatrier (le .out manque)."""
    import shutil
    d = tmp_path / "logs"
    d.mkdir()
    shutil.copy(REF / "import/l49061539.req", d)
    con = db.connect(tmp_path / "t.db")
    rb.scanner_logs([d], con)
    con.execute("INSERT INTO ora_requests(request_id, program_short, phase_code, logfile_name, outfile_name, actual_start) "
                "VALUES (49061539, 'RBAFBIMP', 'C', '/l/l49061539.req', '/o/o49061539.out', '2026-09-17 08:19:53')")
    con.commit()
    dest = tmp_path / "list.txt"
    rb.liste_logs_manquants(con, dest)
    assert dest.read_text() == "/l/l49061539.req /o/o49061539.out\n"


def test_continuite_trou_rejet_puis_rechargement(tmp_path):
    """Compte rejeté en 025 puis rechargé par un import postérieur : plus de trou ; retard jamais négatif."""
    con = db.connect(tmp_path / "t.db")
    con.execute("INSERT INTO rb_pfe(uuid, flux, date_max, md5) VALUES ('u1', 'B', '2026-09-17', 'm1')")
    con.execute("INSERT INTO rb_imports(request_id, debut, fin, flux) VALUES (1, '2026-09-17 08:20:00', '2026-09-17 08:20:05', 'B')")
    con.execute("INSERT INTO rb_imports(request_id, debut, fin, flux) VALUES (2, '2026-09-18 10:00:00', '2026-09-18 10:00:05', 'B')")
    cpt = ("30003.01100.00000000001", "30003", "01100", "00000000001")
    con.execute("INSERT INTO rb_import_releves(request_id, num, compte, banque, guichet, numero, date_fin, en_erreur, code_erreur) "
                "VALUES (1, 1, ?, ?, ?, ?, '2026-09-16', 1, 'Erreur 025')", cpt)
    con.execute("INSERT INTO rb_import_releves(request_id, num, compte, banque, guichet, numero, date_fin, en_erreur) "
                "VALUES (2, 1, ?, ?, ?, ?, '2026-09-18', 0)", cpt)
    con.commit()
    c = rb.continuite(con, CFG)
    r = c.iloc[0]
    assert not r["trou"] and r["dernier_charge"] == "2026-09-18" and r["retard_j"] == 0     # 17 - 18 < 0 -> 0
    # borne « jour » : l'attendu ne dépasse pas la date demandée
    con.execute("INSERT INTO rb_ebs(nom, flux, date_max, md5) VALUES ('AFB120.txt_20260920', 'B', '2026-09-19', 'm2')")
    con.commit()
    assert rb.continuite(con, CFG).iloc[0]["attendu"] == "2026-09-19"
    assert rb.continuite(con, CFG, jour=date(2026, 9, 17)).iloc[0]["attendu"] == "2026-09-17"


def test_rendu_entiers_et_booleens():
    import numpy as np
    import pandas as pd
    import rapport_releves as rr
    assert rr._t(6.0) == "6" and rr._t(6.5) == "6.5" and rr._t(np.int64(7)) == "7" and rr._t(float("nan")) == ""
    assert rr._t(True) == "oui" and rr._t(np.bool_(False)) == "non"
    df = pd.DataFrame({"n": [np.int64(3)], "b": [True], "t": ["x"]})
    h = rr._table(df, {"n": "N", "b": "B", "t": "T"})
    assert "<td class='num'>3</td>" in h and "<td>oui</td>" in h and "<td>x</td>" in h


def test_textes_etapes_et_cause_025(con):
    b = rb.journee(con, date(2026, 9, 17), CFG).flux["B"]
    etapes = {e["cle"]: e["texte"] for e in b.etapes}
    assert etapes["import"].startswith("08:19 · req 49061539")
    assert etapes["controle"].startswith("08:26 · req 49061552")
    assert any("dernier relevé chargé le 2026-09-11" in c for c in b.causes)


def test_constantes_de_colonnes():
    for cols in (rb.COLONNES_PLAN, rb.COLONNES_CHRONO, rb.COLONNES_CONTINUITE, rb.COLONNES_PFE):
        assert isinstance(cols, dict) and cols
    assert list(rb.COLONNES_PLAN) == ["ordre", "chemin", "origine", "periode", "nb_releves", "attendu"]
    assert "resultat" in rb.COLONNES_CHRONO and "trou" in rb.COLONNES_CONTINUITE and "statut" in rb.COLONNES_PFE

