/**
 * Configuration du flux CTM.
 *
 * Seule la valeur FOLDER_ID doit obligatoirement être remplacée avant le
 * premier lancement. Aucun mot de passe Gmail n'est nécessaire : le script
 * utilise les autorisations du compte Google qui l'exécute.
 */
const CTM_CONFIG = Object.freeze({
  /** Version visible dans les journaux pour verifier le code reellement deploye. */
  CODE_VERSION: 'CTM-2026-09-19.3',

  /** ID du dossier Google Drive de destination. */
 FOLDER_ID: '1__xp-bdnQJlb_W7aJ9OerGsxgyVbI0qq',

  /** Requête Gmail de base. Une fenêtre temporelle est ajoutée à l'exécution. */
  SEARCH_QUERY: 'from:indic_ctm@dalkia.fr subject:"DALKIA / Extract CSV du Suivi Quotidien CTM"',

  /** Valeurs revérifiées sur chaque message, car la recherche Gmail est approximative. */
  EXPECTED_SENDER: 'indic_ctm@dalkia.fr',
  // L'objet continue par exemple avec : (ODAT=250717) => 18/07/2025 07-36-23
  EXPECTED_SUBJECT_PREFIX: 'DALKIA / Extract CSV du Suivi Quotidien CTM',

  /** Libellé visuel appliqué aux conversations entièrement traitées. */
  LABEL_NAME: 'CTM_CSV_Traites',

  /** Fuseau utilisé pour le nom des fichiers. */
  TIME_ZONE: 'Europe/Paris',

  /** Première mise en service : rattrapage des quatre derniers mois. */
  INITIAL_LOOKBACK_MONTHS: 4,

  /** Mode courant : petite marge rescannée, sans recréer les fichiers connus. */
  INCREMENTAL_OVERLAP_DAYS: 2,

  /** Le rattrapage progresse par lots pour rester sous la durée maximale Apps Script. */
  MAX_MESSAGES_PER_RUN: 40,
  SEARCH_BATCH_SIZE: 100,
  MAX_THREADS_PER_RUN: 1000,

  /** État d'idempotence conservé dans les propriétés du script. */
  // V3 force un nouveau rattrapage apres la correction du filtre principal.
  STATE_PROPERTY_KEY: 'CTM_IMPORT_STATE_V3',
  STATE_RETENTION_DAYS: 37,
  MAX_PROCESSED_IDS: 200,
  MAX_STATE_JSON_CHARS: 8000,

  /** Protection contre deux déclencheurs simultanés. */
  LOCK_WAIT_MS: 5000,

  /** Contrôle d'exploitation, sans limiter le nombre de messages traités. */
  EXPECTED_DAILY_FILES: 5,

  /** Paramètres de création du déclencheur. */
  TRIGGER_FUNCTION: 'processCtmEmails',
  TRIGGER_INTERVAL_MINUTES: 15,

  /** Métadonnée inscrite dans la description de chaque fichier Drive. */
  DRIVE_MESSAGE_MARKER_PREFIX: 'CTM_MESSAGE_ID=',

  /** Garde-fou en cas de très nombreuses collisions de noms. */
  MAX_FILENAME_COLLISIONS: 999,
});
