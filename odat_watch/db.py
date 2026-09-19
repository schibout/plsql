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

CREATE TABLE IF NOT EXISTS ora_programs (
    program_short     TEXT PRIMARY KEY,
    program_name      TEXT, application_short TEXT, application_name TEXT,
    executable_name   TEXT, execution_method TEXT, execution_file TEXT,
    enabled           TEXT, description TEXT, refreshed_at TEXT
);
CREATE TABLE IF NOT EXISTS ora_requests (
    request_id        INTEGER PRIMARY KEY,
    program_short     TEXT, program_name TEXT, application_short TEXT,
    phase_code        TEXT, status_code TEXT, phase TEXT, status TEXT,
    request_date      TEXT, requested_start TEXT, actual_start TEXT, actual_completion TEXT,
    requestor         TEXT, responsibility TEXT, parent_request_id INTEGER,
    resubmit_interval TEXT, resubmit_unit TEXT, argument_text TEXT,
    description       TEXT, completion_text TEXT,
    logfile_name      TEXT, outfile_name TEXT, job_name TEXT,
    refreshed_at      TEXT
);
CREATE INDEX IF NOT EXISTS ix_ora_prog ON ora_requests(program_short, requested_start);
CREATE INDEX IF NOT EXISTS ix_ora_job ON ora_requests(job_name, actual_start);
CREATE INDEX IF NOT EXISTS ix_ora_phase ON ora_requests(phase_code, status_code);

CREATE TABLE IF NOT EXISTS ora_request_logs (
    request_id   INTEGER NOT NULL,
    kind         TEXT NOT NULL,             -- 'req' (log) ou 'out' (sortie)
    path         TEXT, size INTEGER, loaded_at TEXT,
    program      TEXT, started TEXT, ended TEXT,
    compteurs    TEXT,                      -- JSON {libellé: valeur}
    erreurs      TEXT,                      -- JSON [{code, message, nb}]
    fnd_messages TEXT,                      -- extrait des messages FND_FILE
    diagnostic   TEXT,                      -- JSON [{code, explication, action}]
    PRIMARY KEY (request_id, kind)
);

CREATE TABLE IF NOT EXISTS job_mapping (
    job_name      TEXT PRIMARY KEY,
    program_short TEXT,
    commentaire   TEXT
);

CREATE TABLE IF NOT EXISTS controle_matin_histo (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    date_ctrl         TEXT NOT NULL,      -- AAAA-MM-JJ, jour de la borne de fin
    executed_at       TEXT NOT NULL,      -- AAAA-MM-JJ HH:MM:SS
    plage_debut       TEXT NOT NULL,      -- AAAA-MM-JJ HH:MM
    plage_fin         TEXT NOT NULL,
    statut_global     TEXT NOT NULL,      -- OK | WARNING | ALERTE | ERREUR
    nb_flux_dsp       INTEGER, nb_ndf INTEGER, nb_fac_xerox INTEGER, nb_fac_tradeshift INTEGER,
    nb_fac_dsp        INTEGER, nb_gl_interface INTEGER, nb_gl_lignes INTEGER,
    nb_traitements    INTEGER, nb_erreurs INTEGER, nb_warnings INTEGER,
    nb_rb_imports     INTEGER, nb_images_manq INTEGER,
    duree_s           REAL,
    fichier_rapport   TEXT
);
CREATE INDEX IF NOT EXISTS ix_cm_histo_date ON controle_matin_histo(date_ctrl, executed_at);
"""


def connect(path: Path | str = DB_PATH) -> sqlite3.Connection:
    con = sqlite3.connect(str(path))
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    _migrate(con)
    con.executescript(SCHEMA)
    return con


def _migrate(con: sqlite3.Connection) -> None:
    """Tables Oracle recréées si leur structure a changé (elles se rechargent en un clic)."""
    for table, colonne in (("ora_requests", "job_name"),):
        cols = [r[1] for r in con.execute(f"PRAGMA table_info({table})")]
        if cols and colonne not in cols:
            con.execute(f"DROP TABLE {table}")
            con.commit()
