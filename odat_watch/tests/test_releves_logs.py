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
