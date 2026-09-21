/** @private */
function virementGetOrCreateLabel_(labelName) {
  let label = GmailApp.getUserLabelByName(labelName);
  if (!label) {
    label = GmailApp.createLabel(labelName);
    virementLog_('INFO', 'Libellé Gmail créé.', {label: labelName});
  }
  return label;
}

/** @private */
function virementSearchThreads_(query) {
  const threads = [];
  let start = 0;
  while (threads.length < MAIL_IMPORT_ENGINE_CONFIG.MAX_THREADS_PER_FLOW_PER_RUN) {
    const remaining = MAIL_IMPORT_ENGINE_CONFIG.MAX_THREADS_PER_FLOW_PER_RUN -
      threads.length;
    const batchSize = Math.min(MAIL_IMPORT_ENGINE_CONFIG.SEARCH_BATCH_SIZE, remaining);
    const batch = GmailApp.search(query, start, batchSize);
    Array.prototype.push.apply(threads, batch);
    if (batch.length < batchSize) break;
    start += batch.length;
  }
  const hasMore = threads.length ===
      MAIL_IMPORT_ENGINE_CONFIG.MAX_THREADS_PER_FLOW_PER_RUN &&
    GmailApp.search(query, threads.length, 1).length > 0;
  return {threads: threads, hasMore: hasMore};
}

/** @private */
function virementGetMessageMatchResult_(message, cutoff, flow, referenceDate) {
  const activeFlow = flow || VIREMENT_CONFIG;
  if (message.isInTrash()) return {matches: false, reason: 'trash'};
  if (message.isDraft()) return {matches: false, reason: 'draft'};
  if (message.getDate().getTime() < cutoff.getTime()) {
    return {matches: false, reason: 'beforeCutoff'};
  }
  const sender = virementExtractEmailAddress_(message.getFrom());
  const expectedSenders = activeFlow.EXPECTED_SENDERS.map(function(value) {
    return String(value).toLowerCase();
  });
  if (expectedSenders.indexOf('*') === -1 && expectedSenders.indexOf(sender) === -1) {
    return {matches: false, reason: 'sender'};
  }
  const subjectMatches = activeFlow.EXPECTED_SUBJECT_PREFIXES.some(function(prefix) {
    return virementSubjectMatches_(message.getSubject(), prefix);
  });
  if (!subjectMatches) {
    return {matches: false, reason: 'subject'};
  }
  if (!mailImportMessageDateMatches_(message.getDate(), activeFlow, referenceDate)) {
    return {matches: false, reason: 'date'};
  }
  return {matches: true, reason: 'matched'};
}

/** @private */
function virementEmptyState_() {
  return {lastSuccessfulRunIso: null, processed: {}};
}

/** @private */
function virementLoadState_(flow) {
  const activeFlow = flow || VIREMENT_CONFIG;
  try {
    const raw = PropertiesService.getScriptProperties()
      .getProperty(activeFlow.STATE_PROPERTY_KEY);
    if (!raw) return virementEmptyState_();
    const parsed = JSON.parse(raw);
    return {
      lastSuccessfulRunIso: parsed.lastSuccessfulRunIso || null,
      processed: parsed.processed || {},
    };
  } catch (error) {
    virementLog_('WARN', 'État mémorisé illisible ; reprise avec un état vide.', {
      error: virementErrorMessage_(error),
    });
    return virementEmptyState_();
  }
}

/** @private */
function virementSaveState_(state, flow) {
  const activeFlow = flow || VIREMENT_CONFIG;
  const cutoffMs = Date.now() -
    MAIL_IMPORT_ENGINE_CONFIG.STATE_RETENTION_DAYS * 24 * 60 * 60 * 1000;
  const ids = Object.keys(state.processed)
    .filter(function(messageId) {
      return Number(state.processed[messageId]) >= cutoffMs;
    })
    .sort(function(left, right) {
      return Number(state.processed[right]) - Number(state.processed[left]);
    })
    .slice(0, MAIL_IMPORT_ENGINE_CONFIG.MAX_PROCESSED_IDS);

  let processed = virementSelectProcessed_(state.processed, ids);
  let serialized = virementSerializeState_(state, processed);
  while (serialized.length > MAIL_IMPORT_ENGINE_CONFIG.MAX_STATE_JSON_CHARS &&
      ids.length > 0) {
    ids.pop();
    processed = virementSelectProcessed_(state.processed, ids);
    serialized = virementSerializeState_(state, processed);
  }
  state.processed = processed;
  PropertiesService.getScriptProperties().setProperty(
    activeFlow.STATE_PROPERTY_KEY,
    serialized
  );
}

/** @private */
function virementSelectProcessed_(processed, ids) {
  const selected = {};
  ids.forEach(function(messageId) {
    selected[messageId] = processed[messageId];
  });
  return selected;
}

/** @private */
function virementSerializeState_(state, processed) {
  return JSON.stringify({
    lastSuccessfulRunIso: state.lastSuccessfulRunIso || null,
    processed: processed,
  });
}

/** @private */
function virementIsProcessed_(state, messageId) {
  return Object.prototype.hasOwnProperty.call(state.processed, messageId);
}

/** @private */
function virementMarkProcessed_(state, message) {
  state.processed[message.getId()] = message.getDate().getTime();
}
