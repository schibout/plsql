/** Paramètres communs du moteur multi-flux. */
const MAIL_IMPORT_ENGINE_CONFIG = Object.freeze({
  CODE_VERSION: 'MAIL-IMPORTS-2026-09-22.1',
  MAX_MESSAGES_PER_FLOW_PER_RUN: 50,
  SEARCH_BATCH_SIZE: 100,
  MAX_THREADS_PER_FLOW_PER_RUN: 500,
  MAX_PROCESSED_IDS: 500,
  STATE_RETENTION_DAYS: 150,
  MAX_STATE_JSON_CHARS: 8000,
  MAX_FILENAME_COLLISIONS: 999,
  LOCK_WAIT_MS: 5000,
  TRIGGER_FUNCTION: 'processMailImports',
  TRIGGER_INTERVAL_HOURS: 1,
  TRIGGER_SCHEDULE_VERSION: 'HOURLY_V1',
  TRIGGER_STATE_PROPERTY_KEY: 'MAIL_IMPORT_TRIGGER_STATE',
});

/**
 * Liste des types de mails à télécharger.
 *
 * Pour ajouter un flux, dupliquer le bloc `virements_eur`, puis modifier toutes
 * ses valeurs. ID, LABEL_NAME, STATE_PROPERTY_KEY et
 * DRIVE_MESSAGE_MARKER_PREFIX doivent rester uniques.
 */
const MAIL_IMPORT_FLOWS = Object.freeze([
  Object.freeze({
    ID: 'virements_eur',
    DISPLAY_NAME: 'Virements EUR',
    ENABLED: true,

    FOLDER_ID: '1H4J7VFzEXdJ0rLPuihiLow2Ui3nFa3GQ',
    SEARCH_QUERY: 'in:anywhere from:quartz.messenger@treasury-factory.com ' +
      'subject:"Dalkia Virements importés du jour EUR"',
    EXPECTED_SENDERS: Object.freeze([
      'quartz.messenger@treasury-factory.com',
    ]),
    EXPECTED_SUBJECT_PREFIXES: Object.freeze([
      'Dalkia Virements importés du jour EUR',
    ]),
    ALLOWED_EXTENSIONS: Object.freeze(['xls', 'xlsx']),

    LABEL_NAME: 'Virements_EUR_Traites',
    STATE_PROPERTY_KEY: 'VIREMENTS_EUR_IMPORT_STATE_V1',
    // Valeur historique conservée pour reconnaître les fichiers déjà importés.
    DRIVE_MESSAGE_MARKER_PREFIX: 'VIREMENT_MESSAGE_ID=',
    TIME_ZONE: 'Europe/Paris',
    INITIAL_LOOKBACK_MONTHS: 4,
    DATE_OFFSET_DAYS: null,
    FILE_NAME_MODE: 'timestamp_original',
    FILE_TIMESTAMP_FORMAT: 'ddMMyyyy',
  }),

  Object.freeze({
    ID: 'prelevements_cashcollection',
    DISPLAY_NAME: 'Prélèvements Dalkia CashCollection',
    ENABLED: true,

    FOLDER_ID: '1yEjJwQaPdVZ6dFnpASp8xo-Ew99iRYvw',
    SEARCH_QUERY: 'in:anywhere ' +
      'subject:"[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection"',
    // Le script historique ne filtrait pas l'expéditeur.
    EXPECTED_SENDERS: Object.freeze(['*']),
    EXPECTED_SUBJECT_PREFIXES: Object.freeze([
      '[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection',
    ]),
    // Une liste vide signifie : accepter toutes les extensions.
    ALLOWED_EXTENSIONS: Object.freeze([]),

    LABEL_NAME: 'Controle_Prelevements_CashCollection_Traite',
    STATE_PROPERTY_KEY: 'PRELEVEMENTS_CASHCOLLECTION_IMPORT_STATE_V1',
    DRIVE_MESSAGE_MARKER_PREFIX: 'PRELEVEMENTS_CASHCOLLECTION_MESSAGE_ID=',
    TIME_ZONE: 'Europe/Paris',
    INITIAL_LOOKBACK_MONTHS: 4,
    DATE_OFFSET_DAYS: 3,
    FILE_NAME_MODE: 'timestamp_original',
    FILE_TIMESTAMP_FORMAT: 'ddMMyyyy',
  }),

  Object.freeze({
    ID: 'prelevements_oracle_edf',
    DISPLAY_NAME: 'Prélèvements Oracle - Regroupements EDF',
    // Désactivé le temps de valider virements_eur seul ; repasser à true pour l'activer.
    ENABLED: false,

    FOLDER_ID: '1skW6lJUvX1qlmw6RoLqE_94o5P1yu7o2',
    SEARCH_QUERY: 'in:anywhere ' +
      'subject:"[PROD] [PRELEVEMENTS ORACLE] - Regroupements effectués pour EDF"',
    // Le script historique ne filtrait pas l'expéditeur.
    EXPECTED_SENDERS: Object.freeze(['*']),
    EXPECTED_SUBJECT_PREFIXES: Object.freeze([
      '[PROD] [PRELEVEMENTS ORACLE] - Regroupements effectués pour EDF',
    ]),
    ALLOWED_EXTENSIONS: Object.freeze([]),

    LABEL_NAME: 'Controle_Prelevements_Oracle_EDF_Traite',
    STATE_PROPERTY_KEY: 'PRELEVEMENTS_ORACLE_EDF_IMPORT_STATE_V1',
    DRIVE_MESSAGE_MARKER_PREFIX: 'PRELEVEMENTS_ORACLE_EDF_MESSAGE_ID=',
    TIME_ZONE: 'Europe/Paris',
    INITIAL_LOOKBACK_MONTHS: 4,
    DATE_OFFSET_DAYS: 3,
    FILE_NAME_MODE: 'timestamp_original',
    FILE_TIMESTAMP_FORMAT: 'ddMMyyyy',
  }),

  Object.freeze({
    ID: 'prelevements_rejets',
    DISPLAY_NAME: 'Prélèvements - Rejets bancaires du jour',
    ENABLED: true,

    FOLDER_ID: '1W5woP7yjzwpe9NDfwagWvwhL75MrBHxG',
    SEARCH_QUERY: 'in:anywhere ' +
      'subject:"Dalkia Liste des rejets bancaires du jour - Prélèvements"',
    EXPECTED_SENDERS: Object.freeze(['*']),
    EXPECTED_SUBJECT_PREFIXES: Object.freeze([
      'Dalkia Liste des rejets bancaires du jour - Prélèvements',
    ]),
    ALLOWED_EXTENSIONS: Object.freeze([]),

    LABEL_NAME: 'Controle_Prelevements_Rejets_Traite',
    STATE_PROPERTY_KEY: 'PRELEVEMENTS_REJETS_IMPORT_STATE_V1',
    DRIVE_MESSAGE_MARKER_PREFIX: 'PRELEVEMENTS_REJETS_MESSAGE_ID=',
    TIME_ZONE: 'Europe/Paris',
    INITIAL_LOOKBACK_MONTHS: 4,
    DATE_OFFSET_DAYS: 3,
    FILE_NAME_MODE: 'timestamp_original',
    FILE_TIMESTAMP_FORMAT: 'ddMMyyyy',
  }),

  /*
   * EXEMPLE À COPIER POUR UN FUTUR FLUX (laisser commenté) :
   *
   * Object.freeze({
   *   ID: 'rapport_csv',
   *   DISPLAY_NAME: 'Rapport CSV',
   *   ENABLED: true,
   *   FOLDER_ID: 'ID_DU_DOSSIER_DRIVE',
   *   SEARCH_QUERY: 'in:anywhere from:robot@example.com subject:"Rapport CSV"',
   *   EXPECTED_SENDERS: Object.freeze(['robot@example.com']),
   *   EXPECTED_SUBJECT_PREFIXES: Object.freeze(['Rapport CSV']),
   *   ALLOWED_EXTENSIONS: Object.freeze(['csv', 'zip']),
   *   LABEL_NAME: 'Rapport_CSV_Traite',
   *   STATE_PROPERTY_KEY: 'RAPPORT_CSV_IMPORT_STATE_V1',
   *   DRIVE_MESSAGE_MARKER_PREFIX: 'RAPPORT_CSV_MESSAGE_ID=',
   *   TIME_ZONE: 'Europe/Paris',
   *   INITIAL_LOOKBACK_MONTHS: 4,
   *   DATE_OFFSET_DAYS: null,
   *   FILE_NAME_MODE: 'timestamp_original',
   *   FILE_TIMESTAMP_FORMAT: 'ddMMyyyy',
   * }),
   */
]);

/** Alias conservé pour les appels/tests historiques du premier flux. */
const VIREMENT_CONFIG = MAIL_IMPORT_FLOWS[0];
