/** Formate la date d'un message pour le nom du fichier. */
function formatDateForFilename(date) {
  return ctmFormatTimestamp_(date, CTM_CONFIG.TIME_ZONE);
}

/** @private */
function ctmFormatTimestamp_(date, timeZone) {
  if (!(date instanceof Date) || isNaN(date.getTime())) {
    throw new Error('Date de message invalide.');
  }
  return Utilities.formatDate(date, timeZone, 'yyyyMMdd_HHmmss');
}

/** @private */
function ctmBuildFileName_(date, originalName, timeZone) {
  const safeName = ctmEnsureCsvExtension_(ctmSanitizeFileName_(originalName));
  return ctmFormatTimestamp_(date, timeZone) + '_' + safeName;
}

/**
 * Ne conserve que le nom de base d'une entrée ZIP et retire les caractères de
 * contrôle. Cette normalisation empêche un chemin interne d'influencer le nom
 * créé dans Drive.
 * @private
 */
function ctmSanitizeFileName_(fileName) {
  const parts = String(fileName || '').split(/[\\/]/);
  const baseName = String(parts[parts.length - 1] || '')
    .replace(/[\u0000-\u001F\u007F]/g, '')
    .trim();

  if (!baseName || baseName === '.' || baseName === '..') {
    throw new Error('Nom de fichier CSV vide ou invalide.');
  }
  return baseName;
}

/** @private */
function ctmEnsureCsvExtension_(fileName) {
  return /\.csv$/i.test(fileName) ? fileName : fileName + '.csv';
}

/** @private */
function ctmNormalizeContentType_(contentType) {
  return String(contentType || '').split(';')[0].trim().toLowerCase();
}

/** @private */
function ctmIsCsv_(fileName, contentType) {
  const mime = ctmNormalizeContentType_(contentType);
  return /\.csv$/i.test(String(fileName || '')) ||
    mime === 'text/csv' ||
    mime === 'application/csv';
}

/** @private */
function ctmIsZip_(fileName, contentType) {
  const mime = ctmNormalizeContentType_(contentType);
  return /\.zip$/i.test(String(fileName || '')) ||
    mime === 'application/zip' ||
    mime === 'application/x-zip-compressed';
}

/** @private */
function ctmAddCollisionSuffix_(fileName, collisionIndex) {
  const suffix = '_' + String(collisionIndex).padStart(2, '0');
  const dotIndex = fileName.toLowerCase().lastIndexOf('.csv');
  if (dotIndex === fileName.length - 4) {
    return fileName.slice(0, dotIndex) + suffix + fileName.slice(dotIndex);
  }
  return fileName + suffix;
}

/** @private */
function ctmExtractEmailAddress_(fromValue) {
  const value = String(fromValue || '').trim();
  const angleAddress = value.match(/<([^<>]+)>/);
  return String(angleAddress ? angleAddress[1] : value).trim().toLowerCase();
}

/** @private */
function ctmSearchCutoff_(config, now) {
  const dayMs = 24 * 60 * 60 * 1000;
  return new Date(now.getTime() - config.SEARCH_WINDOW_DAYS * dayMs);
}

/** @private */
function ctmBuildSearchQuery_(config, now) {
  const cutoff = ctmSearchCutoff_(config, now);
  const afterDate = Utilities.formatDate(cutoff, config.TIME_ZONE || 'Europe/Paris', 'yyyy/MM/dd');

  // Ne pas ajouter -label:. Gmail peut regrouper les cinq envois quotidiens
  // dans une seule conversation ; un nouveau message pourrait alors être masqué.
  return config.SEARCH_QUERY + ' has:attachment after:' + afterDate;
}

/** @private */
function ctmErrorMessage_(error) {
  if (!error) return 'Erreur inconnue';
  return error.message ? String(error.message) : String(error);
}

/** @private */
function ctmLog_(level, message, details) {
  const suffix = details ? ' | ' + JSON.stringify(details) : '';
  Logger.log('[CTM][' + level + '] ' + message + suffix);
}
