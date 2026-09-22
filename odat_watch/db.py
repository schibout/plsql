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
    enabled           TEXT, description TEXT, refreshed_at TEXT,
    source            TEXT NOT NULL DEFAULT 'oracle'
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
    refreshed_at      TEXT,
    source            TEXT NOT NULL DEFAULT 'oracle'
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
    program_short TEXT,                 -- programme de la demande portant le nom du job (le lanceur)
    commentaire   TEXT,
    programme     TEXT                  -- programme concurrent déduit du script lancé (DKA_X_JOB.sh -> DKA_X)
);

CREATE TABLE IF NOT EXISTS controle_matin_histo (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    date_ctrl         TEXT NOT NULL,      -- AAAA-MM-JJ, jour de la borne de fin
    executed_at       TEXT NOT NULL,      -- AAAA-MM-JJ HH:MM:SS
    plage_debut       TEXT NOT NULL,      -- AAAA-MM-JJ HH:MM
    plage_fin         TEXT NOT NULL,
    statut_global     TEXT NOT NULL,      -- OK | WARNING | ALERTE | ERREUR
    nb_flux_dsp       INTEGER, nb_ndf INTEGER, nb_fac_xerox INTEGER, nb_fac_tradeshift INTEGER,
    nb_fac_dsp        INTEGER, nb_fac_ar INTEGER, nb_fac_ar_rejet INTEGER,
    nb_gl_interface   INTEGER, nb_gl_lignes INTEGER,
    nb_traitements    INTEGER, nb_erreurs INTEGER, nb_warnings INTEGER,
    nb_rb_imports     INTEGER, nb_images_manq INTEGER,
    duree_s           REAL,
    fichier_rapport   TEXT
);
CREATE INDEX IF NOT EXISTS ix_cm_histo_date ON controle_matin_histo(date_ctrl, executed_at);

-- Virements : instances importées (ODAT/virements/JJMMAAAA/<uuid>), envois vers la banque, historique des contrôles.
-- Alimentées à chaque lancement du contrôle depuis l'onglet ; les fichiers restent la source de vérité.
CREATE TABLE IF NOT EXISTS vir_imports (
    guid          TEXT PRIMARY KEY,       -- instance Talend (uuid)
    date_ctrl     TEXT NOT NULL,          -- AAAA-MM-JJ, journée du dossier
    dossier       TEXT,                   -- dossier rapport du dernier contrôle l'ayant lue
    nb_fichiers   INTEGER,                -- fichiers vus par le contrôle (DK_FIN01, ACK, CSV…)
    nb_envois     INTEGER,                -- fichiers ACK envoyés à la banque
    cible_seul    INTEGER,                -- 1 = sans dossier _source (DK en euros)
    importe_le    TEXT NOT NULL,          -- première prise en compte (import depuis import_virement ou premier contrôle)
    controle_le   TEXT                    -- dernier contrôle (NULL : importée, jamais contrôlée)
);
CREATE TABLE IF NOT EXISTS vir_histo (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    date_ctrl       TEXT NOT NULL,
    executed_at     TEXT NOT NULL,
    ok              INTEGER NOT NULL,
    nb_instances    INTEGER, nb_envoyes INTEGER, montant_envoye REAL,
    ko              INTEGER, a_verifier INTEGER, ecarts INTEGER,
    quartz          INTEGER, cible_seul INTEGER,
    dossier_rapport TEXT,
    fichier_rapport TEXT                  -- rapport HTML généré depuis l'onglet, s'il existe
);
CREATE INDEX IF NOT EXISTS ix_vir_histo_date ON vir_histo(date_ctrl, executed_at);
CREATE TABLE IF NOT EXISTS vir_envois (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    histo_id      INTEGER NOT NULL,
    date_ctrl     TEXT NOT NULL,
    guid          TEXT NOT NULL,
    fichier_ack   TEXT NOT NULL,          -- CDPG.NC4.IMPORT_ACK.*
    nb            INTEGER,                -- virements (pied de fichier)
    montant       REAL,                   -- euros
    statut        TEXT                    -- OK, ou statut_lignes/statut_montant en écart
);
CREATE INDEX IF NOT EXISTS ix_vir_envois_date ON vir_envois(date_ctrl, fichier_ack);

-- Prélèvements : trésorerie EDF persistante (états de réception, rejets internes) et historique des rapprochements.
-- Alimentées à chaque lancement depuis l'onglet ; les fichiers ORACLE restent des fichiers.
CREATE TABLE IF NOT EXISTS pv_fichiers (
    nom           TEXT PRIMARY KEY,       -- IMPORT_AVP_DK.<date>.<heure>.csv / REJETS_INTERNES_DK.<date>.<heure>.csv
    genre         TEXT NOT NULL,          -- EDF | REJET
    date_fichier  TEXT NOT NULL,          -- AAAA-MM-JJ
    nb_lignes     INTEGER,                -- lignes retenues (SI suivi / rejets dédoublonnés)
    taille        INTEGER, md5 TEXT,
    importe_le    TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS pv_edf (
    fichier        TEXT NOT NULL,
    date_fichier   TEXT NOT NULL,
    nom_si         TEXT,
    iban_creancier TEXT NOT NULL,
    echeance       TEXT NOT NULL,
    nb             INTEGER, montant REAL,
    PRIMARY KEY (fichier, iban_creancier, echeance)
);
CREATE INDEX IF NOT EXISTS ix_pv_edf_date ON pv_edf(date_fichier);
CREATE TABLE IF NOT EXISTS pv_rejets (
    fichier        TEXT NOT NULL,
    date_fichier   TEXT NOT NULL,
    iban_creancier TEXT, rum TEXT NOT NULL, iban_debiteur TEXT,
    echeance       TEXT NOT NULL,
    montant        REAL NOT NULL,
    code           TEXT, motif TEXT,
    appariee       INTEGER,               -- 1 = rattaché à une émission Oracle connue
    beneficiaire   TEXT,
    PRIMARY KEY (fichier, rum, echeance, montant)
);
CREATE INDEX IF NOT EXISTS ix_pv_rejets_date ON pv_rejets(date_fichier);
CREATE TABLE IF NOT EXISTS pv_histo (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    reference       TEXT NOT NULL,        -- AAAA-MM-JJ, date de référence du rapprochement
    executed_at     TEXT NOT NULL,
    statut_global   TEXT NOT NULL,        -- OK | ANOMALIES | ERREUR | DEGRADE
    nb_cles         INTEGER, nb_emis INTEGER, montant_emis REAL,
    en_attente      INTEGER, anomalies INTEGER, signales INTEGER, a_investiguer INTEGER,
    doublons        INTEGER, similitudes INTEGER, lignes_ko INTEGER, avertissements INTEGER,
    base            TEXT,                 -- Rapprochement_Cle_Metier_<date>_<heure>
    fichier_rapport TEXT
);
CREATE INDEX IF NOT EXISTS ix_pv_histo_ref ON pv_histo(reference, executed_at);

-- Référentiel jobs Control-M <-> programmes Oracle Applications (auto + saisie manuelle prioritaire)
CREATE TABLE IF NOT EXISTS referentiel_jobs (
    job_name         TEXT PRIMARY KEY,
    application_ctm  TEXT, chaine TEXT, description TEXT, script TEXT,
    programme_auto   TEXT,                 -- nom utilisateur du programme déduit des demandes Oracle (lanceur / filles / script)
    programme_code   TEXT,                 -- code (nom court) du même programme
    programme        TEXT,                 -- saisie manuelle (prioritaire) ; vide = auto
    application_ora  TEXT,                 -- saisie manuelle
    commentaire      TEXT,
    vu_le            TEXT,                 -- dernière photo où le job apparaît
    maj_le           TEXT                  -- dernière modification manuelle
);

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
-- État courant des lignes Folio Rose : une ligne par clé métier folio + date + fichier (+ rang si doublon
-- strict dans un même export). Un import met à jour la ligne existante, n'en crée pas une nouvelle.
CREATE TABLE IF NOT EXISTS fr_lignes (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    empreinte         TEXT NOT NULL UNIQUE,            -- sha1(folio|date|fichier|rang)
    rang              INTEGER NOT NULL DEFAULT 0,
    folio             TEXT, date TEXT, type TEXT, fichier TEXT, fichier_base TEXT,
    amont_nb          REAL, amont_debit REAL, amont_credit REAL,
    si_nb             REAL, si_debit REAL, si_credit REAL,
    ecart_nb          REAL, ecart_debit REAL, ecart_credit REAL,
    commentaire       TEXT, piece_jointe TEXT, lettrage TEXT,
    age_j             INTEGER,
    premier_export_id INTEGER REFERENCES fr_exports(id),
    dernier_export_id INTEGER REFERENCES fr_exports(id),
    num               INTEGER,                         -- rang dans le dernier fichier
    present           INTEGER NOT NULL DEFAULT 1,      -- 0 : absente du dernier export couvrant sa date
    maj_le            TEXT
);
CREATE INDEX IF NOT EXISTS ix_fr_lignes_cle ON fr_lignes(folio, date, fichier);
CREATE INDEX IF NOT EXISTS ix_fr_lignes_dernier ON fr_lignes(dernier_export_id);
CREATE TABLE IF NOT EXISTS fr_oracle (
    folio             TEXT NOT NULL, fichier_base TEXT NOT NULL, type TEXT NOT NULL,
    nb_oracle         REAL, montant_oracle REAL, nb_interface REAL, montant_interface REAL,
    erreur            TEXT, controle_le TEXT NOT NULL,
    PRIMARY KEY (folio, fichier_base, type)
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

-- GDR : photos quotidiennes des rejets ouverts (AP / AR / GL) et etat courant des lignes rejetees
CREATE TABLE IF NOT EXISTS gdr_fichiers (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    nom_fichier TEXT NOT NULL,
    file_hash   TEXT NOT NULL UNIQUE,
    type        TEXT NOT NULL,                 -- AP | AR | GL
    date_photo  TEXT NOT NULL,                 -- AAAA-MM-JJ (prefixe JJMMAAAA du nom)
    rang        INTEGER NOT NULL DEFAULT 1,    -- 1 : premier envoi du jour, 2 : suffixe _02...
    importe_le  TEXT NOT NULL,
    nb_lignes   INTEGER NOT NULL
);
CREATE TABLE IF NOT EXISTS gdr_lignes (
    line_gdr              TEXT PRIMARY KEY,    -- Line GDR
    id_gdr                TEXT,                -- ID GDR : la piece
    type                  TEXT NOT NULL,
    code_rejet            TEXT, libelle_rejet TEXT,
    fichier_source        TEXT,                -- = « Nom fichier transmis » de Folio Rose
    folio                 TEXT,                -- 3 premieres lettres du folio GDR
    folio_libelle         TEXT, societe TEXT, region TEXT,
    numero_piece          TEXT, date_piece TEXT, compte TEXT,
    montant_debit         REAL, montant_credit REAL,
    description           TEXT,
    date_creation_gdr     TEXT, date_arrete TEXT, fichier_src_technique TEXT,
    premier_fichier_id    INTEGER REFERENCES gdr_fichiers(id),
    dernier_fichier_id    INTEGER REFERENCES gdr_fichiers(id),
    present               INTEGER NOT NULL DEFAULT 1,   -- 0 : absente de la derniere photo de son type (rejet traite)
    disparu_le            TEXT                          -- date de la photo ou la ligne a disparu
);
CREATE INDEX IF NOT EXISTS ix_gdr_lignes_cle ON gdr_lignes(fichier_source, folio);
CREATE INDEX IF NOT EXISTS ix_gdr_lignes_piece ON gdr_lignes(id_gdr);

-- Calendriers de clôture importés depuis Excel. Les versions restent conservées.
CREATE TABLE IF NOT EXISTS calendar_imports (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    nom_fichier   TEXT NOT NULL,
    file_hash     TEXT NOT NULL UNIQUE,
    importe_le    TEXT NOT NULL,
    statut        TEXT NOT NULL DEFAULT 'active', -- active | inactive
    nb_mois       INTEGER NOT NULL,
    nb_operations INTEGER NOT NULL,
    message       TEXT
);
CREATE TABLE IF NOT EXISTS calendar_events (
    id                INTEGER PRIMARY KEY AUTOINCREMENT,
    import_id         INTEGER NOT NULL REFERENCES calendar_imports(id) ON DELETE CASCADE,
    periode_comptable TEXT NOT NULL, -- AAAA-MM, mois de la feuille
    reference_j       TEXT,
    date_operation    TEXT NOT NULL,
    decalage_j        TEXT,
    moment            TEXT,
    arrete            TEXT,
    traitement        TEXT,
    restitution       TEXT,
    source_sheet      TEXT NOT NULL,
    source_row        INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS ix_calendar_event_date ON calendar_events(date_operation);
CREATE INDEX IF NOT EXISTS ix_calendar_event_period ON calendar_events(periode_comptable, import_id);

-- Correspondances volontairement explicites entre une opération métier et un job Control-M.
CREATE TABLE IF NOT EXISTS calendar_job_mapping (
    event_id INTEGER NOT NULL REFERENCES calendar_events(id) ON DELETE CASCADE,
    job_name TEXT NOT NULL,
    commentaire TEXT,
    PRIMARY KEY (event_id, job_name)
);

-- Relevés bancaires (onglet « Relevés bancaires », modules releves_scan.py / releves.py)
CREATE TABLE IF NOT EXISTS rb_pfe (                -- une exécution Talend (dossier <uuid>) : le fichier livré à EBS
    uuid            TEXT PRIMARY KEY,
    horodatage      TEXT,                          -- YYYY-MM-DD HH:MM:SS (nom du TARGET)
    fichier_source  TEXT, fichier_target TEXT, zip TEXT,
    ls_in_ok        INTEGER, complete INTEGER,
    flux            TEXT,                          -- A | B
    nb_releves      INTEGER, nb_lignes INTEGER, banques TEXT,   -- banques : "30003:213;30004:12"
    date_min        TEXT, date_max TEXT,           -- YYYY-MM-DD
    md5             TEXT,
    ebs_md5_recu    INTEGER DEFAULT 0,             -- 1 si un fichier rb_ebs a le même md5
    vu_le           TEXT
);
CREATE TABLE IF NOT EXISTS rb_ebs (                -- fichier AFB120.txt_<horodatage> reçu par EBS (data/traite)
    nom             TEXT PRIMARY KEY,
    horodatage      TEXT, flux TEXT,
    nb_releves      INTEGER, nb_lignes INTEGER, banques TEXT,
    date_min        TEXT, date_max TEXT, md5 TEXT, vu_le TEXT
);
CREATE TABLE IF NOT EXISTS rb_imports (            -- request RBAFBIMP (logs l<id>.req / o<id>.out)
    request_id      INTEGER PRIMARY KEY,
    debut           TEXT, fin TEXT, fichier TEXT,
    lus             INTEGER, ecrits INTEGER, batch INTEGER,
    releves_charges INTEGER, releves_erreurs INTEGER, lignes_chargees INTEGER, lignes_erreurs INTEGER,
    err001          INTEGER DEFAULT 0, err025 INTEGER DEFAULT 0, autres_erreurs INTEGER DEFAULT 0,
    flux            TEXT, md5_ebs TEXT,
    source_req      TEXT, source_out TEXT
);
CREATE TABLE IF NOT EXISTS rb_import_releves (     -- « Synthèse des relevés » : une ligne par relevé
    request_id  INTEGER NOT NULL, num INTEGER NOT NULL,
    compte      TEXT, banque TEXT, guichet TEXT, numero TEXT, devise TEXT,
    date_debut  TEXT, date_fin TEXT, mouvements INTEGER,
    en_erreur   INTEGER DEFAULT 0, code_erreur TEXT,
    PRIMARY KEY (request_id, num)
);
CREATE TABLE IF NOT EXISTS rb_controles (          -- request DKA_SRBCTRLRB
    request_id      INTEGER PRIMARY KEY,
    executed_at     TEXT, date_reference TEXT,
    nb_anomalies    INTEGER, nb_sg INTEGER, nb_hors_connus INTEGER,
    source_req      TEXT, source_out TEXT
);
CREATE TABLE IF NOT EXISTS rb_controle_lignes (
    request_id  INTEGER NOT NULL, compte_id TEXT NOT NULL,
    banque TEXT, guichet TEXT, numero TEXT, nom_compte TEXT,
    date_dernier_import TEXT, date_debut_releve TEXT, date_fin_releve TEXT,
    PRIMARY KEY (request_id, compte_id)
);
CREATE TABLE IF NOT EXISTS rb_comptes_connus (     -- anomalies préexistantes à ignorer : 'banque/guichet/compte'
    cle       TEXT PRIMARY KEY,
    motif     TEXT, ajoute_le TEXT
);
"""


def _migrer_folio_rose(con: sqlite3.Connection) -> None:
    """Ancien modèle (une copie des lignes par export, empreinte incluant les montants) -> état courant par clé
    folio + date + fichier. Les rapprochements sont reportés sur la nouvelle empreinte."""
    cols = [r[1] for r in con.execute("PRAGMA table_info(fr_lignes)")]
    if not cols or "present" in cols:
        return
    import hashlib
    anciennes = con.execute("SELECT id, export_id, num, empreinte, folio, date, type, fichier, fichier_base, amont_nb, "
                            "amont_debit, amont_credit, si_nb, si_debit, si_credit, ecart_nb, ecart_debit, ecart_credit, "
                            "commentaire, piece_jointe, lettrage, age_j FROM fr_lignes "
                            "ORDER BY export_id, num").fetchall()
    con.execute("ALTER TABLE fr_lignes RENAME TO fr_lignes_ancien")
    con.execute("DROP TABLE IF EXISTS fr_oracle")
    con.executescript("""
    CREATE TABLE fr_lignes (
        id INTEGER PRIMARY KEY AUTOINCREMENT, empreinte TEXT NOT NULL UNIQUE, rang INTEGER NOT NULL DEFAULT 0,
        folio TEXT, date TEXT, type TEXT, fichier TEXT, fichier_base TEXT,
        amont_nb REAL, amont_debit REAL, amont_credit REAL, si_nb REAL, si_debit REAL, si_credit REAL,
        ecart_nb REAL, ecart_debit REAL, ecart_credit REAL, commentaire TEXT, piece_jointe TEXT, lettrage TEXT,
        age_j INTEGER, premier_export_id INTEGER REFERENCES fr_exports(id), dernier_export_id INTEGER REFERENCES fr_exports(id),
        num INTEGER, present INTEGER NOT NULL DEFAULT 1, maj_le TEXT);""")
    correspondance = {}
    nouvelles = {}
    rangs: dict[tuple, int] = {}
    export_courant = None
    for r in anciennes:
        (_id, eid, num, anc, folio, date, typ, fichier, base, an, ad, ac, sn, sd, sc, en, ed, ec, com, pj, let, age) = r
        if eid != export_courant:
            export_courant, rangs = eid, {}
        cle = ((folio or "").strip(), (date or "").strip(), (fichier or "").strip())
        rang = rangs.get(cle, 0)
        rangs[cle] = rang + 1
        emp = hashlib.sha1(f"{cle[0]}|{cle[1]}|{cle[2]}|{rang}".encode("utf-8")).hexdigest()
        correspondance[anc] = emp
        prem = nouvelles[emp][0] if emp in nouvelles else eid
        nouvelles[emp] = (prem, eid, num, rang, folio, date, typ, fichier, base, an, ad, ac, sn, sd, sc, en, ed, ec,
                          com, pj, let, age)
    con.executemany(
        "INSERT INTO fr_lignes(empreinte, premier_export_id, dernier_export_id, num, rang, folio, date, type, fichier, "
        "fichier_base, amont_nb, amont_debit, amont_credit, si_nb, si_debit, si_credit, ecart_nb, ecart_debit, "
        "ecart_credit, commentaire, piece_jointe, lettrage, age_j) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
        [(emp, *v) for emp, v in nouvelles.items()])
    for anc, emp in correspondance.items():
        con.execute("UPDATE OR IGNORE fr_rapprochement_lignes SET empreinte = ? WHERE empreinte = ?", (emp, anc))
    con.execute("DROP TABLE fr_lignes_ancien")
    con.commit()


def connect(path: Path | str = DB_PATH) -> sqlite3.Connection:
    con = sqlite3.connect(str(path))
    con.row_factory = sqlite3.Row
    con.execute("PRAGMA foreign_keys = ON")
    _migrate(con)
    con.executescript(SCHEMA)
    return con


def _migrate(con: sqlite3.Connection) -> None:
    """Tables Oracle recréées si leur structure a changé (elles se rechargent en un clic)."""
    _migrer_folio_rose(con)
    for table, colonne in (("job_mapping", "programme"), ("rb_controles", "source_req")):
        cols = [r[1] for r in con.execute(f"PRAGMA table_info({table})")]
        if cols and colonne not in cols:
            con.execute(f"ALTER TABLE {table} ADD COLUMN {colonne} TEXT")
            con.commit()
    # vir_imports : controle_le est devenu facultatif (import sans contrôle) ; table recréée, elle se réalimente au prochain contrôle
    info = con.execute("PRAGMA table_info(vir_imports)").fetchall()
    if any(r[1] == "controle_le" and r[3] == 1 for r in info):
        con.execute("DROP TABLE vir_imports")
        con.commit()
    cols = [r[1] for r in con.execute("PRAGMA table_info(referentiel_jobs)")]
    if cols and "programme_code" not in cols:
        con.execute("ALTER TABLE referentiel_jobs ADD COLUMN programme_code TEXT")
        con.commit()
    # Contrôle du matin : compteurs ajoutés après la création de l'historique (factures AR, 21/09/2026)
    cols = [r[1] for r in con.execute("PRAGMA table_info(controle_matin_histo)")]
    for colonne in ("nb_fac_ar", "nb_fac_ar_rejet"):
        if cols and colonne not in cols:
            con.execute(f"ALTER TABLE controle_matin_histo ADD COLUMN {colonne} INTEGER")
            con.commit()
    for table in ("ora_requests", "ora_programs"):
        cols = [r[1] for r in con.execute(f"PRAGMA table_info({table})")]
        if cols and "source" not in cols:
            con.execute(f"ALTER TABLE {table} ADD COLUMN source TEXT NOT NULL DEFAULT 'oracle'")
            con.commit()
    # Les anciennes versions ne marquaient que les programmes mock. Leur horodatage commun permet
    # d'identifier le lot de demandes simulées sans toucher aux chargements Oracle réels.
    if all(con.execute(f"SELECT 1 FROM sqlite_master WHERE type='table' AND name='{table}'").fetchone()
           for table in ("ora_requests", "ora_programs")):
        con.execute("UPDATE ora_programs SET source='mock' WHERE description='(mock)' AND source<>'mock'")
        con.execute("UPDATE ora_requests SET source='mock' WHERE source<>'mock' AND refreshed_at IN "
                    "(SELECT refreshed_at FROM ora_programs WHERE description='(mock)')")
        con.commit()
    for table, colonne in (("ora_requests", "job_name"),):
        cols = [r[1] for r in con.execute(f"PRAGMA table_info({table})")]
        if cols and colonne not in cols:
            con.execute(f"DROP TABLE {table}")
            con.commit()
