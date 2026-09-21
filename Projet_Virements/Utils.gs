/** @private */
function virementExtractEmailAddress_(fromValue) {
  const value = String(fromValue || '').trim();
  const angleAddress = value.match(/<([^<>]+)>/);
  return String(angleAddress ? angleAddress[1] : value).trim().toLowerCase();
}

/** @private */
function virementNormalizeSubject_(subject) {
  return String(subject || '')
    .replace(/^(?:\s*(?:re|ré|rép|fw|fwd|tr)\s*:\s*)+/i, '')
    .replace(/\s+/g, ' ')
    .trim()
    .toLowerCase();
}

/** @private */
function virementSubjectMatches_(subject, expectedPrefix) {
  const actual = virementNormalizeSubject_(subject);
  const expected = virementNormalizeSubject_(expectedPrefix);
  return !!expected && (actual === expected || actual.indexOf(expected + ' ') === 0);
}

/** @private */
function virementSanitizeFileName_(fileName) {
  const parts = String(fileName || '').split(/[\\/]/);
  const baseName = String(parts[parts.length - 1] || '')
    .replace(/[\u0000-\u001F\u007F]/g, '')
    .trim();
  if (!baseName || baseName === '.' || baseName === '..') {
    throw new Error('Nom de pièce jointe vide ou invalide.');
  }
  return baseName;
}

/** @private */
function virementFileExtension_(fileName) {
  const match = String(fileName || '').toLowerCase().match(/\.([a-z0-9]+)$/);
  return match ? match[1] : '';
}

/** @private */
function virementIsAllowedAttachment_(fileName, allowedExtensions) {
  if (!Array.isArray(allowedExtensions) || allowedExtensions.length === 0) {
    return true;
  }
  return allowedExtensions.indexOf(virementFileExtension_(fileName)) !== -1;
}

/** @private */
function virementAddCollisionSuffix_(fileName, collisionIndex) {
  const name = String(fileName || '');
  const dotIndex = name.lastIndexOf('.');
  const suffix = '_' + String(collisionIndex).padStart(2, '0');
  return dotIndex > 0
    ? name.slice(0, dotIndex) + suffix + name.slice(dotIndex)
    : name + suffix;
}

/** @private */
function virementBuildSearchQuery_(config, referenceDate) {
  // Le libellé n'est volontairement pas exclu : Gmail peut regrouper plusieurs
  // envois quotidiens dans une conversation déjà labellisée.
  if (Number.isInteger(config.DATE_OFFSET_DAYS) && config.DATE_OFFSET_DAYS >= 0) {
    const target = new Date((referenceDate || new Date()).getTime());
    target.setDate(target.getDate() - config.DATE_OFFSET_DAYS);
    const nextDay = new Date(target.getTime());
    nextDay.setDate(nextDay.getDate() + 1);
    return config.SEARCH_QUERY + ' has:attachment after:' +
      Utilities.formatDate(target, config.TIME_ZONE, 'yyyy/MM/dd') +
      ' before:' + Utilities.formatDate(nextDay, config.TIME_ZONE, 'yyyy/MM/dd');
  }
  return config.SEARCH_QUERY + ' has:attachment newer_than:' +
    config.INITIAL_LOOKBACK_MONTHS + 'm';
}

/** @private */
function mailImportMessageDateMatches_(messageDate, flow, referenceDate) {
  if (!Number.isInteger(flow.DATE_OFFSET_DAYS) || flow.DATE_OFFSET_DAYS < 0) {
    return true;
  }
  const target = new Date((referenceDate || new Date()).getTime());
  target.setDate(target.getDate() - flow.DATE_OFFSET_DAYS);
  return Utilities.formatDate(messageDate, flow.TIME_ZONE, 'yyyyMMdd') ===
    Utilities.formatDate(target, flow.TIME_ZONE, 'yyyyMMdd');
}

/** @private */
function mailImportBuildOutputFileName_(originalName, messageDate, flow) {
  const safeName = virementSanitizeFileName_(originalName);
  if (flow.FILE_NAME_MODE === 'timestamp_original') {
    return Utilities.formatDate(
      messageDate,
      flow.TIME_ZONE,
      flow.FILE_TIMESTAMP_FORMAT
    ) + '_' + safeName;
  }
  return safeName;
}

/** @private */
function mailImportFlowLog_(flow, level, message, details) {
  const enriched = {};
  Object.keys(details || {}).forEach(function(key) {
    enriched[key] = details[key];
  });
  enriched.flowId = flow.ID;
  enriched.flowName = flow.DISPLAY_NAME;
  virementLog_(level, message, enriched);
}

/** @private */
function virementCutoffDate_(now, months) {
  const result = new Date(now.getTime());
  const originalDay = result.getDate();
  result.setDate(1);
  result.setMonth(result.getMonth() - months);
  const lastDay = new Date(result.getFullYear(), result.getMonth() + 1, 0).getDate();
  result.setDate(Math.min(originalDay, lastDay));
  result.setHours(0, 0, 0, 0);
  return result;
}

/** @private */
function virementErrorMessage_(error) {
  if (!error) return 'Erreur inconnue';
  return error.message ? String(error.message) : String(error);
}

/** @private */
function virementLog_(level, message, details) {
  const suffix = details ? ' | ' + JSON.stringify(details) : '';
  Logger.log('[MAIL_IMPORT][' + level + '] ' + message + suffix);
}
