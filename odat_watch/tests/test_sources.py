"""Dossiers d'import mémorisés et journal d'import par dossier."""
import shutil
import sys
from pathlib import Path

import db
import ingest
import sources

ARCHIVE = Path(__file__).resolve().parents[2] / "ODAT" / "archive"


def test_dossiers_memorises_ajout_doublon_retrait(tmp_path):
    con = db.connect(tmp_path / "t.db")
    assert sources.dossiers_memorises(con) == []
    sources.ajouter_dossier(con, tmp_path / "a")
    sources.ajouter_dossier(con, str(tmp_path / "b"))
    sources.ajouter_dossier(con, tmp_path / "a")            # doublon ignoré
    assert sources.dossiers_memorises(con) == [tmp_path / "a", tmp_path / "b"]
    sources.retirer_dossier(con, tmp_path / "a")
    assert sources.dossiers_memorises(con) == [tmp_path / "b"]
    con.close()
    con = db.connect(tmp_path / "t.db")                       # persistance
    assert sources.dossiers_memorises(con) == [tmp_path / "b"]
    con.close()


def test_ajout_chemin_vide_ignore(tmp_path):
    con = db.connect(tmp_path / "t.db")
    sources.ajouter_dossier(con, "   ")
    assert sources.dossiers_memorises(con) == []
    con.close()


def test_commande_dialogue_utilise_le_python_courant():
    cmd = sources.commande_dialogue()
    assert cmd[0] == sys.executable and cmd[1] == "-c" and "askdirectory" in cmd[2]


def test_run_journalise_les_dossiers_et_importe(tmp_path, monkeypatch):
    photo = next(p for p in sorted(ARCHIVE.rglob("*.csv")) if p.stat().st_size < 400_000)
    src = tmp_path / "src"
    src.mkdir()
    shutil.copy(photo, src / "Report_ctm_test.csv")
    base = tmp_path / "t.db"
    monkeypatch.setattr(ingest, "connect", lambda: db.connect(base))
    monkeypatch.setattr(ingest, "ODAT_DIR", tmp_path / "odat")
    monkeypatch.setattr(ingest, "ARCHIVE_DIR", tmp_path / "odat" / "archive")
    absent = tmp_path / "nulle_part"

    logs = ingest.run([src, absent])
    assert any(l.startswith(f"{src} : 1 fichier") for l in logs), logs
    assert any(l.startswith(f"{absent} : absent") for l in logs), logs
    assert any("Report_ctm_test.csv -> chargé" in l for l in logs), logs

    logs = ingest.run([src])                                   # même fichier : doublon
    assert any("doublon" in l for l in logs), logs


def test_find_files_accepte_le_prefixe_horodate(tmp_path):
    (tmp_path / "20260919_164523_Report_ctm_260919_19_new.csv").write_text("x")
    (tmp_path / "Report_ctm_260917_17_new.csv").write_text("x")
    (tmp_path / "autre.csv").write_text("x")
    assert sorted(p.name for p in ingest.find_files([tmp_path])) == [
        "20260919_164523_Report_ctm_260919_19_new.csv", "Report_ctm_260917_17_new.csv"]


def test_snap_time_from_name(tmp_path):
    from datetime import datetime
    f = tmp_path / "20260919_164523_Report_ctm_260919_19_new.csv"
    f.write_text("x")
    assert ingest.snap_time_from_name(f) == datetime(2026, 9, 19, 16, 45)
    g = tmp_path / "Report_ctm_260917_17_new.csv"
    g.write_text("x")
    assert ingest.snap_time_from_name(g).year >= 2026
