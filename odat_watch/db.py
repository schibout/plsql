"""Accès SQLite pour ODAT Watch."""
from __future__ import annotations
import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / "odat.db"

SCHEMA = """
CREATE TABLE IF NOT EXISTS snapshots (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    odate       TEXT NOT NULL,
    snap_time   TEXT NOT NULL,
    source_file TEXT NOT NULL,
    file_hash   TEXT NOT NULL UNIQUE,
    nb_lignes   INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS ctm_jobs (
    snapshot_id  INTEGER NOT NULL REFERENCES snapshots(id) ON DELETE CASCADE,
    application  TEXT, group_name TEXT, job_name TEXT NOT NULL,
    odate        TEXT, start_time TEXT, end_time TEXT, run_time INTEGER,
    status       TEXT, description TEXT, member TEXT, task_type TEXT,
    deleted      TEXT, rerun INTEGER, cyclic TEXT, ctm_name TEXT, tbl TEXT,
    run_as       TEXT, hostname TEXT, nodegroup TEXT, order_id TEXT,
    UNIQUE (snapshot_id, order_id, rerun, start_time)
);
CREATE INDEX IF NOT EXISTS ix_ctm_jobs_job ON ctm_jobs(job_name, odate);
CREATE INDEX IF NOT EXISTS ix_ctm_jobs_app ON ctm_jobs(application, snapshot_id);

CREATE TABLE IF NOT EXISTS ora_requests (
    request_id        INTEGER PRIMARY KEY,
    program_short     TEXT, program_name TEXT, application_short TEXT,
    phase_code        TEXT, status_code TEXT, phase TEXT, status TEXT,
    requested_start   TEXT, actual_start TEXT, actual_completion TEXT,
    requestor         TEXT, parent_request_id INTEGER, resubmit_interval TEXT,
    resubmit_unit     TEXT, argument_text TEXT, refreshed_at TEXT
);
CREATE INDEX IF NOT EXISTS ix_ora_prog ON ora_requests(program_short, requested_start);

CREATE TABLE IF NOT EXISTS job_mapping (
    job_name      TEXT PRIMARY KEY,
    program_short TEXT,
    commentaire   TEXT
);
"""


def connect(path: Path | str = DB_PATH) -> sqlite3.Connection:
    con = sqlite3.connect(str(path))
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    con.executescript(SCHEMA)
    return con
