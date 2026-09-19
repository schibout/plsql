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

CREATE TABLE IF NOT EXISTS parametres (      -- réglages de l'interface (ex. import.dossiers)
    cle    TEXT PRIMARY KEY,
    valeur TEXT
);

-- Folio Rose : exports, lignes, contrôle Oracle, rapprochements
CREATE TABLE IF NOT EXISTS fr_exports (
    id                     INTEGER PRIMARY KEY AUTOINCREMENT,
    nom_fichier            TEXT NOT NULL,
    file_hash              TEXT NOT NULL UNIQUE,
    date_export            TEXT NOT NULL,          -- AAAA-MM-JJ (nom du fichier, sinon date d'import)
    periode_debut          TEXT, periode_fin TEXT, -- JJ/MM/AAAA tels que lus
    importe_le             TEXT NOT NULL,
    nb_lignes              INTEGER NOT NULL,
    encodage               TEXT,
    nb_montants_illisibles INTEGER DEFAULT 0
);
CREATE TABLE IF NOT EXISTS fr_lignes (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    export_id     INTEGER NOT NULL REFERENCES fr_exports(id) ON DELETE CASCADE,
    num           INTEGER NOT NULL,                -- rang dans le fichier
    empreinte     TEXT NOT NULL,                   -- identité stable d'une ligne entre exports
    folio         TEXT, date TEXT, type TEXT, fichier TEXT, fichier_base TEXT,
    amont_nb      REAL, amont_debit REAL, amont_credit REAL,
    si_nb         REAL, si_debit REAL, si_credit REAL,
    ecart_nb      REAL, ecart_debit REAL, ecart_credit REAL,
    commentaire   TEXT, piece_jointe TEXT, lettrage TEXT,
    age_j         INTEGER
);
CREATE INDEX IF NOT EXISTS ix_fr_lignes_export ON fr_lignes(export_id);
CREATE INDEX IF NOT EXISTS ix_fr_lignes_empreinte ON fr_lignes(empreinte);
CREATE TABLE IF NOT EXISTS fr_oracle (
    export_id         INTEGER NOT NULL REFERENCES fr_exports(id) ON DELETE CASCADE,
    folio             TEXT NOT NULL, fichier_base TEXT NOT NULL, type TEXT NOT NULL,
    nb_oracle         REAL, montant_oracle REAL, nb_interface REAL, montant_interface REAL,
    erreur            TEXT, controle_le TEXT NOT NULL,
    PRIMARY KEY (export_id, folio, fichier_base, type)
);
CREATE TABLE IF NOT EXISTS fr_rapprochements (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    cree_le     TEXT NOT NULL,
    commentaire TEXT,
    somme_ecart REAL NOT NULL,
    nb_lignes   INTEGER NOT NULL,
    annule_le   TEXT
);
CREATE TABLE IF NOT EXISTS fr_rapprochement_lignes (
    rapprochement_id INTEGER NOT NULL REFERENCES fr_rapprochements(id) ON DELETE CASCADE,
    empreinte        TEXT NOT NULL,
    PRIMARY KEY (rapprochement_id, empreinte)
);
CREATE INDEX IF NOT EXISTS ix_fr_rl_empreinte ON fr_rapprochement_lignes(empreinte);
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
