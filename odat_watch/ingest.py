"""Ingestion des fichiers ODAT Control-M (Report_ctm_*.csv) dans SQLite + archive datée.

Usage :
    python ingest.py                 # scanne ../ODAT et ~/Downloads
    python ingest.py chemin1 chemin2 # scanne les chemins donnés (fichiers ou dossiers)
"""
from __future__ import annotations
import csv
import hashlib
import re
import shutil
import sys
from datetime import datetime, timedelta
from pathlib import Path

from db import connect, BASE_DIR

ODAT_DIR = BASE_DIR.parent / "ODAT"
ARCHIVE_DIR = ODAT_DIR / "archive"
DOWNLOADS = Path.home() / "Downloads"
FILE_RE = re.compile(r"Report_ctm_(\d{6})", re.I)
# Photos déposées par Control-M : 20260919_164523_Report_ctm_260919_19_new.csv (horodatage de la photo en préfixe)
PREFIX_RE = re.compile(r"^(\d{8})_(\d{6})_Report_ctm_", re.I)
DATE_FMT = "%B %d, %Y %I:%M:%S %p"
ODATE_FMT = "%B %d, %Y"

COLS = ["application", "group_name", "job_name", "odate", "start_time", "end_time",
        "run_time", "status", "description", "member", "task_type", "deleted", "rerun",
        "cyclic", "ctm_name", "tbl", "run_as", "hostname", "nodegroup", "order_id"]


def parse_dt(txt: str) -> str | None:
    txt = (txt or "").strip().strip('"')
    if not txt:
        return None
    for fmt, out in ((DATE_FMT, "%Y-%m-%d %H:%M:%S"), (ODATE_FMT, "%Y-%m-%d")):
        try:
            return datetime.strptime(txt, fmt).strftime(out)
        except ValueError:
            pass
    return txt


def to_int(txt: str) -> int | None:
    txt = (txt or "").strip()
    return int(txt) if txt.isdigit() else None


def file_hash(path: Path) -> str:
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def odate_from_name(path: Path) -> str | None:
    m = FILE_RE.search(path.name) or FILE_RE.search(path.parent.name)
    return datetime.strptime(m.group(1), "%y%m%d").strftime("%Y-%m-%d") if m else None


def read_rows(path: Path) -> list[dict]:
    rows = []
    with open(path, encoding="utf-8-sig", newline="") as f:
        reader = csv.reader(f, delimiter=";")
        header = next(reader, None)
        if not header or header[0].strip() != "Application":
            raise ValueError(f"En-tête inattendu dans {path.name}: {header[:3] if header else header}")
        for rec in reader:
            if len(rec) < 20 or not rec[2].strip():
                continue
            rec = [c.strip() for c in rec[:20]]
            row = dict(zip(COLS, rec))
            row["odate"] = parse_dt(row["odate"])
            row["start_time"] = parse_dt(row["start_time"])
            row["end_time"] = parse_dt(row["end_time"])
            row["run_time"] = to_int(row["run_time"])
            row["rerun"] = to_int(row["rerun"]) or 0
            rows.append(row)
    return rows


def archive(path: Path, snap_time: datetime) -> Path:
    dest_dir = ARCHIVE_DIR / snap_time.strftime("%Y/%m/%d")
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / f"{snap_time.strftime('%H%M')}_odate_{odate_from_name(path) or 'inconnu'}.csv"
    if not dest.exists():
        shutil.copy2(path, dest)
    return dest


def snap_time_from_name(path: Path) -> datetime:
    """Horodatage du préfixe AAAAMMJJ_HHMMSS_ s'il existe, sinon date de modification du fichier."""
    m = PREFIX_RE.match(path.name)
    if m:
        return datetime.strptime(m.group(1) + m.group(2), "%Y%m%d%H%M%S").replace(second=0)
    return datetime.fromtimestamp(path.stat().st_mtime).replace(microsecond=0)


def snap_time_from_rows(rows: list[dict], fallback: datetime) -> datetime:
    """Heure de la photo = dernier événement (fin ou début) présent dans le fichier, à la minute supérieure.

    Plus fiable que la date du fichier, qui change à chaque copie / git pull / téléchargement en lot.
    """
    evts = [r["end_time"] or r["start_time"] for r in rows if (r["end_time"] or r["start_time"])]
    evts = [e for e in evts if len(e) == 19]
    if not evts:
        return fallback
    last = datetime.fromisoformat(max(evts))
    return (last + timedelta(seconds=59)).replace(second=0)


def ingest_file(con, path: Path) -> str:
    h = file_hash(path)
    if con.execute("SELECT 1 FROM snapshots WHERE file_hash=?", (h,)).fetchone():
        return "doublon, ignoré"
    rows = read_rows(path)
    snap_time = snap_time_from_rows(rows, snap_time_from_name(path))
    odate = odate_from_name(path) or min(r["odate"] for r in rows if r["odate"])
    if con.execute("SELECT 1 FROM snapshots WHERE odate=? AND snap_time=?", (odate, snap_time.strftime("%Y-%m-%d %H:%M:%S"))).fetchone():
        return f"même photo déjà chargée ({snap_time:%d/%m %H:%M}), ignoré"
    dest = archive(path, snap_time)
    cur = con.execute(
        "INSERT INTO snapshots(odate, snap_time, source_file, file_hash, nb_lignes) VALUES (?,?,?,?,?)",
        (odate, snap_time.strftime("%Y-%m-%d %H:%M:%S"), str(dest.relative_to(ODAT_DIR)), h, len(rows)))
    sid = cur.lastrowid
    con.executemany(
        f"INSERT OR IGNORE INTO ctm_jobs(snapshot_id,{','.join(COLS)}) VALUES (?{',?' * len(COLS)})",
        [(sid, *[r[c] for c in COLS]) for r in rows])
    con.commit()
    return f"chargé ({len(rows)} lignes, photo {snap_time:%d/%m %H:%M}, odate {odate})"


def recaler_snapshots(con) -> int:
    """Recalcule snap_time des photos déjà chargées à partir de leur contenu (une fois, après mise à jour)."""
    n = 0
    for sid, snap in con.execute("SELECT id, snap_time FROM snapshots").fetchall():
        last = con.execute("SELECT MAX(COALESCE(end_time, start_time)) FROM ctm_jobs WHERE snapshot_id=? "
                           "AND LENGTH(COALESCE(end_time, start_time)) = 19", (sid,)).fetchone()[0]
        if not last:
            continue
        new = (datetime.fromisoformat(last) + timedelta(seconds=59)).replace(second=0).strftime("%Y-%m-%d %H:%M:%S")
        if new != snap:
            con.execute("UPDATE snapshots SET snap_time=? WHERE id=?", (new, sid))
            n += 1
    # doublons de contenu (même odate + même heure) : on garde le premier
    dbl = con.execute("""SELECT id FROM snapshots WHERE id NOT IN (SELECT MIN(id) FROM snapshots GROUP BY odate, snap_time)""").fetchall()
    for (sid,) in dbl:
        con.execute("DELETE FROM ctm_jobs WHERE snapshot_id=?", (sid,))
        con.execute("DELETE FROM snapshots WHERE id=?", (sid,))
    con.commit()
    return n + len(dbl)


def find_files(roots: list[Path]) -> list[Path]:
    out = set()
    for root in roots:
        if root.is_file():
            out.add(root)
        elif root.is_dir():
            out.update(p for p in root.rglob("*Report_ctm_*.csv") if ARCHIVE_DIR not in p.parents)
    return sorted(out, key=lambda p: p.stat().st_mtime)


def run(roots: list[Path] | None = None) -> list[str]:
    roots = roots or [ODAT_DIR, DOWNLOADS]
    con = connect()
    logs = []
    n = recaler_snapshots(con)
    if n:
        logs.append(f"{n} photo(s) recalée(s) ou dédoublonnée(s) d'après leur contenu.")
    for root in roots:
        if root.is_dir() or root.is_file():
            logs.append(f"{root} : {len(find_files([root]))} fichier(s) *Report_ctm_*.csv")
        else:
            logs.append(f"{root} : absent")
    for f in find_files(roots):
        try:
            logs.append(f"{f.name} -> {ingest_file(con, f)}")
        except Exception as e:  # noqa: BLE001
            logs.append(f"{f.name} -> ERREUR {e}")
    n = con.execute("SELECT COUNT(*) FROM snapshots").fetchone()[0]
    m = con.execute("SELECT COUNT(*) FROM ctm_jobs").fetchone()[0]
    logs.append(f"Base : {n} photos, {m} lignes jobs.")
    con.close()
    return logs


if __name__ == "__main__":
    print("\n".join(run([Path(a) for a in sys.argv[1:]] or None)))
