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


def test_photo_de_la_veille_au_soir_ignoree(tmp_path):
    """Seule une photo de l'odate prise le soir même (avant la matinée) : on ne diagnostique rien."""
    con = db.connect(tmp_path / "t.db")
    _charger_photo(con, REF / "Report_ctm_260914_14_16h45.csv", "2026-09-14 16:45:00")
    df = rb.chaine_controlm(con, date(2026, 9, 15))
    assert df.empty
    assert rb.diagnostic_controlm(df)["photo"] is None


def test_conflit_detecte_sur_un_rerun_anterieur(con):
    """Le conflit MOV est cherché sur tous les reruns de 06_MOV01, pas seulement sur le dernier."""
    df = rb.chaine_controlm(con, date(2026, 9, 15))
    assert df["job_name"].is_unique
    assert "starts_06_mov" in df.attrs and "2026-09-15 07:49:37" in df.attrs["starts_06_mov"]
    # on décale le dernier rerun (la ligne dédoublonnée) : le conflit doit rester visible via les reruns bruts
    df.loc[df["job_name"] == "FINEXT_J14INT_06_MOV01_Q", "start_time"] = "2026-09-15 09:00:00"
    assert rb.diagnostic_controlm(df)["conflit_mov"]
    # heures inexploitables : pas de conflit, pas d'exception
    df.attrs["starts_06_mov"] = ["n/a"]
    df.loc[df["job_name"] == "FINEXT_J14INT_05_MOV01_Q", "start_time"] = "n/a"
    assert not rb.diagnostic_controlm(df)["conflit_mov"]


def test_message_zip01_generique_et_rerun_nan(con):
    df = rb.chaine_controlm(con, date(2026, 9, 15))
    df.loc[df["job_name"] == "FINEXT_J14INT_06_ZIP01_Q", "rerun"] = float("nan")
    d = rb.diagnostic_controlm(df)
    zip_msg = next(c for c in d["causes"] if "06_ZIP01" in c)
    assert "08:16" in zip_msg and "zip suivant du flux B" in zip_msg and "rerun 0" in zip_msg
