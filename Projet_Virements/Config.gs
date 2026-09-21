/** Paramètres communs du moteur multi-flux. */
const MAIL_IMPORT_ENGINE_CONFIG = Object.freeze({
  CODE_VERSION: 'MAIL-IMPORTS-2026-09-21.2',
  MAX_MESSAGES_PER_FLOW_PER_RUN: 50,
  SEARCH_BATCH_SIZE: 100,
  MAX_THREADS_PER_FLOW_PER_RUN: 500,
  MAX_PROCESSED_IDS: 500,
  STATE_RETENTION_DAYS: 150,
  MAX_STATE_JSON_CHARS: 8000,
  MAX_FILENAME_COLLISIONS: 999,
  LOCK_WAIT_MS: 5000,
  TRIGGER_FUNCTION: 'processMailImports',
  TRIGGER_INTERVAL_MINUTES: 15,
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

    FOLDER_ID: '1KFQvMNyQEy2H4niTTWg9jSeyCrJCS51Q',
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
    CREATE_DATE_SUBFOLDER: true,
    SUBFOLDER_DATE_FORMAT: 'ddMMyyyy',
    FILE_NAME_MODE: 'original',
    FILE_TIMESTAMP_FORMAT: 'yyyyMMdd_HHmm',
  }),

  Object.freeze({
    ID: 'prelevements',
    DISPLAY_NAME: 'Prélèvements Dalkia et regroupements Oracle',
    ENABLED: true,

    FOLDER_ID: '1skW6lJUvX1qlmw6RoLqE_94o5P1yu7o2',
    SEARCH_QUERY: 'in:anywhere {' +
      'subject:"[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection" ' +
      'subject:"[PROD] [PRELEVEMENTS ORACLE] - Regroupements effectués pour EDF"' +
      '}',
    // Le script historique ne filtrait pas l'expéditeur.
    EXPECTED_SENDERS: Object.freeze(['*']),
    EXPECTED_SUBJECT_PREFIXES: Object.freeze([
      '[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection',
      '[PROD] [PRELEVEMENTS ORACLE] - Regroupements effectués pour EDF',
    ]),
    // Une liste vide signifie : accepter toutes les extensions.
    ALLOWED_EXTENSIONS: Object.freeze([]),

    LABEL_NAME: 'Controle_Transfert_Traité',
    STATE_PROPERTY_KEY: 'PRELEVEMENTS_IMPORT_STATE_V1',
    DRIVE_MESSAGE_MARKER_PREFIX: 'PRELEVEMENT_MESSAGE_ID=',
    TIME_ZONE: 'Europe/Paris',
    INITIAL_LOOKBACK_MONTHS: 4,
    DATE_OFFSET_DAYS: 3,
    CREATE_DATE_SUBFOLDER: false,
    SUBFOLDER_DATE_FORMAT: 'ddMMyyyy',
    FILE_NAME_MODE: 'timestamp_original',
    FILE_TIMESTAMP_FORMAT: 'yyyyMMdd_HHmm',
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
   *   CREATE_DATE_SUBFOLDER: true,
   *   SUBFOLDER_DATE_FORMAT: 'ddMMyyyy',
   *   FILE_NAME_MODE: 'original',
   *   FILE_TIMESTAMP_FORMAT: 'yyyyMMdd_HHmm',
   * }),
   */
]);

/** Alias conservé pour les appels/tests historiques du premier flux. */
const VIREMENT_CONFIG = MAIL_IMPORT_FLOWS[0];
