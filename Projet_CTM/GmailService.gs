/** @private */
function ctmGetOrCreateLabel_(labelName) {
  let label = GmailApp.getUserLabelByName(labelName);
  if (!label) {
    label = GmailApp.createLabel(labelName);
    ctmLog_('INFO', 'Libellé Gmail créé.', {label: labelName});
  }
  return label;
}

/** @private */
function ctmSearchThreads_(query) {
  const threads = [];
  let start = 0;

  while (threads.length < CTM_CONFIG.MAX_THREADS_PER_RUN) {
    const remaining = CTM_CONFIG.MAX_THREADS_PER_RUN - threads.length;
    const batchSize = Math.min(CTM_CONFIG.SEARCH_BATCH_SIZE, remaining);
    const batch = GmailApp.search(query, start, batchSize);

    Array.prototype.push.apply(threads, batch);
    if (batch.length < batchSize) break;
    start += batch.length;
  }

  return threads;
}

/** @private */
function ctmMessageMatches_(message, cutoff) {
  if (message.isInTrash() || message.isDraft()) return false;
  if (message.getDate().getTime() < cutoff.getTime()) return false;

  const sender = ctmExtractEmailAddress_(message.getFrom());
  const subject = String(message.getSubject() || '').trim();
  return sender === CTM_CONFIG.EXPECTED_SENDER.toLowerCase() &&
    subject === CTM_CONFIG.EXPECTED_SUBJECT;
}

/** @private */
function ctmLoadState_() {
  const emptyState = {lastRunIso: null, processed: {}};
  try {
    const raw = PropertiesService.getScriptProperties()
      .getProperty(CTM_CONFIG.STATE_PROPERTY_KEY);
    if (!raw) return emptyState;

    const parsed = JSON.parse(raw);
    return {
      lastRunIso: parsed.lastRunIso || null,
      processed: parsed.processed || {},
    };
  } catch (error) {
    ctmLog_('WARN', 'État mémorisé illisible ; reprise avec un état vide.', {
      error: ctmErrorMessage_(error),
    });
    return emptyState;
  }
}

/**
 * Enregistre et élague l'état pour rester sous les quotas de ScriptProperties.
 * @private
 */
function ctmSaveState_(state) {
  const cutoffMs = Date.now() - CTM_CONFIG.STATE_RETENTION_DAYS * 24 * 60 * 60 * 1000;
  const retainedIds = Object.keys(state.processed)
    .filter(function(messageId) {
      return Number(state.processed[messageId]) >= cutoffMs;
    })
    .sort(function(left, right) {
      return Number(state.processed[right]) - Number(state.processed[left]);
    })
    .slice(0, CTM_CONFIG.MAX_PROCESSED_IDS);

  let kept = ctmSelectProcessedIds_(state.processed, retainedIds);
  let serialized = JSON.stringify({lastRunIso: state.lastRunIso, processed: kept});

  // Une valeur ScriptProperties est limitée à 9 Ko. On conserve une marge et
  // retire d'abord les identifiants les plus anciens si la taille est dépassée.
  while (serialized.length > CTM_CONFIG.MAX_STATE_JSON_CHARS && retainedIds.length > 0) {
    retainedIds.pop();
    kept = ctmSelectProcessedIds_(state.processed, retainedIds);
    serialized = JSON.stringify({lastRunIso: state.lastRunIso, processed: kept});
  }

  state.processed = kept;
  try {
    PropertiesService.getScriptProperties().setProperty(
      CTM_CONFIG.STATE_PROPERTY_KEY,
      serialized
    );
    return true;
  } catch (error) {
    ctmLog_('ERROR', 'Impossible d’enregistrer l’état des messages traités.', {
      error: ctmErrorMessage_(error),
    });
    return false;
  }
}

/** @private */
function ctmSelectProcessedIds_(processed, messageIds) {
  const selected = {};
  messageIds.forEach(function(messageId) {
    selected[messageId] = processed[messageId];
  });
  return selected;
}

/** @private */
function ctmIsProcessed_(state, messageId) {
  return Object.prototype.hasOwnProperty.call(state.processed, messageId);
}

/** @private */
function ctmMarkProcessed_(state, message) {
  state.processed[message.getId()] = message.getDate().getTime();
}

/** @private */
function ctmCountProcessedOnDay_(state, date) {
  const targetDay = Utilities.formatDate(date, CTM_CONFIG.TIME_ZONE, 'yyyyMMdd');
  return Object.keys(state.processed).filter(function(messageId) {
    const timestamp = Number(state.processed[messageId]);
    return !isNaN(timestamp) &&
      Utilities.formatDate(new Date(timestamp), CTM_CONFIG.TIME_ZONE, 'yyyyMMdd') === targetDay;
  }).length;
}
