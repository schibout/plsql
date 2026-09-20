"""Diagnostic de la chaîne FINEXT_J14INT_05/06 à partir des photos ODAT de l'incident (sans déplacer les fichiers)."""
from datetime import date
from pathlib import Path

import pytest

import db
import ingest
import releves as rb

REF = Path(__file__).resolve().parents[2] / "ControleReleveBancaire" / "FichierODAT"


def _charger_photo(con, path: Path, snap_time: str):
    rows = ingest.read_rows(path)
    odate = min(r["odate"] for r in rows if r["odate"])
    cur = con.execute("INSERT INTO snapshots(odate, snap_time, source_file, file_hash, nb_lignes) VALUES (?,?,?,?,?)",
                      (odate, snap_time, path.name, f"{path.name}-{snap_time}", len(rows)))
    con.executemany(f"INSERT OR IGNORE INTO ctm_jobs(snapshot_id,{','.join(ingest.COLS)}) VALUES (?{',?' * len(ingest.COLS)})",
                    [(cur.lastrowid, *[r[c] for c in ingest.COLS]) for r in rows])
    con.commit()


@pytest.fixture
def con(tmp_path):
    con = db.connect(tmp_path / "t.db")
    _charger_photo(con, REF / "Report_ctm_260914_14_8h06.csv", "2026-09-15 08:06:00")
    _charger_photo(con, REF / "Report_ctm_260915_15_September_2026 (1)" / "Report_ctm_260915_15_new.csv", "2026-09-16 08:06:00")
    # photo (3) de l'odate 16 : chaîne 05 du 17/09 exécutée à 07:19, sans conflit avec la 06
    _charger_photo(con, REF / "Report_ctm_260916_16_September_2026 (3)" / "Report_ctm_260916_16_new.csv", "2026-09-17 07:36:00")
    return con


def test_chaine_du_15_conflit_et_zip_not_ok(con):
    df = rb.chaine_controlm(con, date(2026, 9, 15))
    assert set(df["job_name"]) >= {"FINEXT_J14INT_05_MOV01_Q", "FINEXT_J14INT_06_MOV01_Q", "FINEXT_J14INT_06_ZIP01_Q"}
    zip06 = df[df["job_name"] == "FINEXT_J14INT_06_ZIP01_Q"].iloc[0]
    assert zip06["status"] == "Ended Not OK" and zip06["rerun"] >= 10
    d = rb.diagnostic_controlm(df)
    assert d["conflit_mov"] and d["zip06_not_ok"] and not d["import06_execute"]
    assert "06_ZIP01" in d["causes"][0] or "conflit" in d["causes"][0].lower()


def test_chaine_du_17_saine(con):
    d = rb.diagnostic_controlm(rb.chaine_controlm(con, date(2026, 9, 17)))
    assert not d["conflit_mov"] and not d["zip06_not_ok"]


def test_sans_photo(con):
    df = rb.chaine_controlm(con, date(2026, 9, 1))
    assert df.empty
    d = rb.diagnostic_controlm(df)
    assert d["photo"] is None and d["causes"] == []
