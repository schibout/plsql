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
