"""Parseurs des logs RBAFBIMP (import) et DKA_SRBCTRLRB (contrôle) sur les fichiers réels."""
from pathlib import Path

import db
import logs
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire"


def test_parse_import_out_rejet_total():
    p = rb.parse_import_out(logs.lire(REF / "import/o49061539.out"))
    assert p["batch"] == 1010051
    assert (p["releves_charges"], p["releves_erreurs"], p["releves_total"]) == (0, 213, 213)
    # Fichier réel : 208 × 025 (journée manquante) + 5 × 001 (comptes inconnus d'EBS) = 213 relevés, tous rejetés
    assert p["erreurs"] == {"Erreur 001": 5, "Erreur 025": 208}
    assert len(p["releves"]) == 213 and all(r["en_erreur"] for r in p["releves"])
    assert sum(1 for r in p["releves"] if r["code_erreur"] == "Erreur 025") == 208
    r = p["releves"][0]
    assert r["compte"] == "30003.01100.00020398294" and r["code_erreur"] == "Erreur 025"
    assert (r["date_debut"], r["date_fin"]) == ("2026-09-15", "2026-09-16")


def test_parse_import_out_ok():
    p = rb.parse_import_out(logs.lire(REF / "import/o49029106.out"))
    assert (p["releves_charges"], p["releves_erreurs"], p["releves_total"]) == (207, 6, 213)
    assert (p["lignes_chargees"], p["lignes_erreurs"]) == (1663, 295)
    assert p["erreurs"] == {"Erreur 001": 5, "Erreur 025": 1}
    ko = [r for r in p["releves"] if r["en_erreur"]]
    assert len(ko) == 6 and {r["code_erreur"] for r in ko} == {"Erreur 001", "Erreur 025"}
    assert next(r for r in ko if r["compte"] == "30003.03620.00020137269")["code_erreur"] == "Erreur 025"
    ok = next(r for r in p["releves"] if not r["en_erreur"])
    assert ok["mouvements"] >= 0 and ok["date_fin"] == "2026-09-11"


def test_scanner_logs_imports(tmp_path):
    con = db.connect(tmp_path / "t.db")
    n = rb.scanner_logs([REF / "import"], con)
    # 17 requests dans import/, dont 48991448 qui est en réalité un contrôle DKA_SRBCTRLRB (rangé là par erreur)
    assert n == 17
    assert con.execute("SELECT COUNT(*) FROM rb_imports").fetchone()[0] == 16
    assert con.execute("SELECT COUNT(*) FROM rb_controles").fetchone()[0] == 1
    assert rb.scanner_logs([REF / "import"], con) == 0
    r = con.execute("SELECT * FROM rb_imports WHERE request_id=49061539").fetchone()
    assert (r["lus"], r["ecrits"], r["releves_charges"], r["releves_erreurs"]) == (8285, 0, 0, 213)
    assert (r["err001"], r["err025"], r["autres_erreurs"]) == (5, 208, 0)
    assert r["debut"] == "2026-09-17 08:19:53" and r["fichier"].endswith("data/in/AFB120.txt")
    assert r["flux"] == "B"
    r = con.execute("SELECT flux, releves_charges FROM rb_imports WHERE request_id=49041437").fetchone()
    assert (r["flux"], r["releves_charges"]) == ("A", 141)
    assert con.execute("SELECT COUNT(*) FROM rb_import_releves WHERE request_id=49029106").fetchone()[0] == 213


def test_parse_controle_out():
    p = rb.parse_controle_out(logs.lire(REF / "controle/o49069921.out"))
    assert p["date_reference"] == "2026-09-17"
    assert len(p["lignes"]) == 208
    sg = [l for l in p["lignes"] if l["banque"] == "30003"]
    assert len(sg) == 207
    l = p["lignes"][0]
    assert l["compte_id"] == "11412" and l["guichet"] == "00370" and l["numero"] == "00025100813"
    assert (l["date_dernier_import"], l["date_debut_releve"], l["date_fin_releve"]) == ("2026-09-14", "2026-09-10", "2026-09-11")


def test_scanner_logs_controles_et_comptes_connus(tmp_path):
    con = db.connect(tmp_path / "t.db")
    rb.comptes_connus_init(con, ["30003/03620/00020137269", "16807/00166/31990892212"])
    n = rb.scanner_logs([REF / "controle"], con)
    assert n >= 17 and con.execute("SELECT COUNT(*) FROM rb_imports").fetchone()[0] == 0
    r = con.execute("SELECT * FROM rb_controles WHERE request_id=49069921").fetchone()
    assert r["executed_at"] == "2026-09-18 08:27:49" and r["date_reference"] == "2026-09-17"
    assert (r["nb_anomalies"], r["nb_sg"], r["nb_hors_connus"]) == (208, 207, 207)   # 16807 connu, SG 03620/…269 connu
    assert con.execute("SELECT COUNT(*) FROM rb_controle_lignes WHERE request_id=49069921").fetchone()[0] == 208


def test_parse_import_out_flux_a_comptes_alphanumeriques():
    """Flux A : comptes suisses CH530/CH260 (codes banque alphanumériques) et erreurs associées par plage d'enregistrements."""
    p = rb.parse_import_out(logs.lire(REF / "import/o49041437.out"))
    assert len(p["releves"]) == p["releves_total"] == 160
    assert sum(r["en_erreur"] for r in p["releves"]) == sum(p["erreurs"].values()) == 19
    ch = [r for r in p["releves"] if r["banque"].startswith("CH")]
    assert {r["compte"] for r in ch} == {"CH530.87050.00003064301", "CH260.87050.00003064302"}
    ko = [r for r in p["releves"] if r["en_erreur"]]
    assert all(r["code_erreur"] for r in ko)                       # chaque relevé en erreur a son code
    assert all(r["l1"] <= r["l2"] for r in p["releves"])
    assert next(r for r in ko if r["compte"] == "CH260.87050.00003064302")["code_erreur"] == "Erreur 001"


def test_parse_controle_out_mois_francais():
    p = rb.parse_controle_out(logs.lire(REF / "controle/o49069921.out"))
    l = next(l for l in p["lignes"] if l["compte_id"] == "186831")
    assert (l["date_debut_releve"], l["date_fin_releve"], l["date_dernier_import"]) == ("2026-08-28", "2026-08-31", "2026-09-07")
    assert rb._date_ctrl("17-SEP-2026 08:19:53") == "2026-09-17 08:19:53" and rb._date_ctrl("") is None


def test_enregistrer_comptes_connus_ignore_lignes_vides(tmp_path):
    import pandas as pd
    con = db.connect(tmp_path / "t.db")
    df = pd.DataFrame({"cle": ["30003/03620/00020137269", None, "   ", float("nan"), "16807/00166/31990892212"],
                       "motif": ["ancien", None, "x", "y", float("nan")]})
    rb.enregistrer_comptes_connus(df, con)
    rows = {r["cle"]: r["motif"] for r in con.execute("SELECT cle, motif FROM rb_comptes_connus")}
    assert rows == {"30003/03620/00020137269": "ancien", "16807/00166/31990892212": ""}


def test_scanner_logs_rescan_quand_le_out_arrive(tmp_path):
    import shutil
    d = tmp_path / "logs"
    d.mkdir()
    shutil.copy(REF / "import/l49061539.req", d)
    con = db.connect(tmp_path / "t.db")
    assert rb.scanner_logs([d], con) == 1
    r = con.execute("SELECT lus, source_req, source_out, releves_erreurs FROM rb_imports WHERE request_id=49061539").fetchone()
    assert r["lus"] == 8285 and r["source_req"] and r["source_out"] is None
    assert con.execute("SELECT COUNT(*) FROM rb_import_releves").fetchone()[0] == 0
    con.execute("UPDATE rb_imports SET md5_ebs='abc' WHERE request_id=49061539")
    con.commit()
    shutil.copy(REF / "import/o49061539.out", d)
    assert rb.scanner_logs([d], con) == 1
    r = con.execute("SELECT source_out, releves_erreurs, err025, md5_ebs FROM rb_imports WHERE request_id=49061539").fetchone()
    assert r["source_out"] and r["releves_erreurs"] == 213 and r["err025"] == 208 and r["md5_ebs"] == "abc"
    assert con.execute("SELECT COUNT(*) FROM rb_import_releves").fetchone()[0] == 213
    assert rb.scanner_logs([d], con) == 0
