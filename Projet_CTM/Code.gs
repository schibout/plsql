/**
 * Point d'entrée principal. À lancer manuellement pour la recette, puis avec un
 * déclencheur temporel toutes les 15 minutes.
 *
 * Cette automatisation ne supprime aucun e-mail et ne modifie jamais son état
 * lu/non lu. Le libellé de suivi est la seule modification effectuée dans Gmail.
 */
function processCtmEmails() {
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(CTM_CONFIG.LOCK_WAIT_MS)) {
    ctmLog_('WARN', 'Une autre exécution CTM est déjà en cours. Arrêt sans traitement.');
    return;
  }

  const report = {
    mode: '',
    threads: 0,
    matched: 0,
    attempted: 0,
    deferred: 0,
    created: 0,
    recovered: 0,
    alreadyProcessed: 0,
    errors: 0,
    labelsApplied: 0,
  };

  try {
    ctmValidateConfig_();
    const folder = DriveApp.getFolderById(CTM_CONFIG.FOLDER_ID);
    const label = ctmGetOrCreateLabel_(CTM_CONFIG.LABEL_NAME);
    const state = ctmLoadState_();
    const now = new Date();
    const searchWindow = ctmBuildSearchWindow_(CTM_CONFIG, state, now);
    const query = ctmBuildSearchQuery_(CTM_CONFIG, state, now);
    report.mode = searchWindow.mode;

    ctmLog_('INFO', 'Début du traitement CTM.', {
      mode: searchWindow.mode,
      destination: folder.getName(),
      query: query,
    });

    const searchResult = ctmSearchThreads_(query);
    const threads = searchResult.threads;
    report.threads = threads.length;
    ctmLog_('INFO', 'Conversations Gmail trouvées.', {
      count: threads.length,
      truncated: searchResult.hasMore,
    });

    const collection = ctmCollectCandidateMessages_(
      threads,
      searchWindow.messageCutoff,
      report
    );
    report.matched = collection.messages.length;

    let outcome = {deferred: 0, blocked: collection.failed};
    if (searchWindow.mode === 'backfill' && searchResult.hasMore) {
      outcome.blocked = true;
      report.errors++;
      ctmLog_('ERROR', 'Rattrapage suspendu : le nombre de conversations dépasse le plafond.', {
        maxThreads: CTM_CONFIG.MAX_THREADS_PER_RUN,
      });
    } else if (!collection.failed || searchWindow.mode === 'incremental') {
      const processingOutcome = ctmProcessCandidateMessages_(
        collection.messages,
        folder,
        state,
        searchWindow.mode,
        report
      );
      outcome = {
        deferred: processingOutcome.deferred,
        blocked: processingOutcome.blocked || collection.failed,
      };
    }

    report.deferred = outcome.deferred;

    let backfillCompletedThisRun = false;
    if (searchWindow.mode === 'backfill') {
      const backfillFinished = !outcome.blocked &&
        outcome.deferred === 0 &&
        !searchResult.hasMore &&
        collection.messages.every(function(item) {
          return ctmIsProcessed_(state, item.messageId);
        });

      if (backfillFinished) {
        state.backfillComplete = true;
        state.backfillCursorMs = null;
        state.lastSuccessfulRunIso = now.toISOString();
        backfillCompletedThisRun = true;
        ctmLog_('INFO', 'Rattrapage des quatre derniers mois terminé ; passage en incrémental.');
      } else {
        ctmLog_('INFO', 'Rattrapage à poursuivre lors de la prochaine exécution.', {
          cursor: state.backfillCursorMs
            ? new Date(state.backfillCursorMs).toISOString()
            : null,
          deferred: outcome.deferred,
        });
      }
    } else if (!outcome.blocked && outcome.deferred === 0 && !searchResult.hasMore) {
      state.lastSuccessfulRunIso = now.toISOString();
    }

    ctmSaveState_(state);
    ctmUpdateThreadLabels_(
      threads,
      label,
      state,
      searchWindow.messageCutoff,
      report,
      backfillCompletedThisRun
    );

    const todayCount = ctmCountProcessedOnDay_(state, now);
    ctmLog_('INFO', 'Contrôle du volume quotidien.', {
      processedToday: todayCount,
      expected: CTM_CONFIG.EXPECTED_DAILY_FILES,
    });
  } catch (error) {
    report.errors++;
    ctmLog_('ERROR', 'Erreur critique du traitement CTM.', {
      error: ctmErrorMessage_(error),
      stack: error && error.stack ? String(error.stack) : '',
    });
  } finally {
    ctmLog_('INFO', 'Bilan du traitement CTM.', report);
    lock.releaseLock();
  }
}

/** @private */
function ctmCollectCandidateMessages_(threads, cutoff, report) {
  const messages = [];
  let failed = false;

  threads.forEach(function(thread) {
    try {
      thread.getMessages().forEach(function(message) {
        try {
          if (!ctmMessageMatches_(message, cutoff)) return;
          messages.push({
            message: message,
            thread: thread,
            messageId: message.getId(),
            receivedMs: message.getDate().getTime(),
          });
        } catch (error) {
          failed = true;
          report.errors++;
          ctmLog_('ERROR', 'Impossible de contrôler les métadonnées d’un message.', {
            error: ctmErrorMessage_(error),
          });
        }
      });
    } catch (error) {
      failed = true;
      report.errors++;
      ctmLog_('ERROR', 'Impossible de lire une conversation Gmail.', {
        threadId: thread.getId(),
        error: ctmErrorMessage_(error),
      });
    }
  });

  messages.sort(function(left, right) {
    if (left.receivedMs !== right.receivedMs) return left.receivedMs - right.receivedMs;
    return left.messageId.localeCompare(right.messageId);
  });

  return {messages: messages, failed: failed};
}

/** @private */
function ctmProcessCandidateMessages_(items, folder, state, mode, report) {
  let attempted = 0;
  let blocked = false;
  let deferred = 0;

  for (let index = 0; index < items.length; index++) {
    const item = items[index];

    if (ctmIsProcessed_(state, item.messageId)) {
      report.alreadyProcessed++;
      if (mode === 'backfill') ctmAdvanceBackfillCursor_(state, item.receivedMs);
      continue;
    }

    if (attempted >= CTM_CONFIG.MAX_MESSAGES_PER_RUN) {
      deferred = items.slice(index).filter(function(candidate) {
        return !ctmIsProcessed_(state, candidate.messageId);
      }).length;
      break;
    }

    attempted++;
    report.attempted++;

    const message = item.message;

    try {
      const csvCandidate = ctmExtractSingleCsv_(message);
      const saveResult = ctmSaveCsv_(folder, csvCandidate, message);
      if (saveResult.created) report.created++;
      else report.recovered++;

      ctmMarkProcessed_(state, message);
      if (mode === 'backfill') ctmAdvanceBackfillCursor_(state, item.receivedMs);
      ctmSaveState_(state);
    } catch (error) {
      blocked = true;
      report.errors++;
      ctmLog_('ERROR', 'Message non traité ; il sera retenté.', {
        messageId: item.messageId,
        receivedAt: new Date(item.receivedMs).toISOString(),
        error: ctmErrorMessage_(error),
      });

      // En rattrapage, ne jamais avancer au-delà d'un message en erreur : le
      // curseur doit garantir qu'aucun historique n'est oublié.
      if (mode === 'backfill') {
        deferred = items.slice(index).filter(function(candidate) {
          return !ctmIsProcessed_(state, candidate.messageId);
        }).length;
        break;
      }
    }
  }

  return {deferred: deferred, blocked: blocked};
}

/** @private */
function ctmAdvanceBackfillCursor_(state, receivedMs) {
  if (state.backfillCursorMs === null || receivedMs > Number(state.backfillCursorMs)) {
    state.backfillCursorMs = receivedMs;
  }
}

/** @private */
function ctmUpdateThreadLabels_(threads, label, state, cutoff, report, forceComplete) {
  threads.forEach(function(thread) {
    let matchingMessages = [];
    let readable = true;

    try {
      matchingMessages = thread.getMessages().filter(function(message) {
        return ctmMessageMatches_(message, cutoff);
      });
    } catch (error) {
      readable = false;
      ctmLog_('WARN', 'Impossible de vérifier une conversation avant labellisation.', {
        threadId: thread.getId(),
        error: ctmErrorMessage_(error),
      });
    }

    if (matchingMessages.length === 0 && readable) return;
    const allComplete = forceComplete === true ||
      (readable && matchingMessages.every(function(message) {
        return ctmIsProcessed_(state, message.getId());
      }));

    try {
      if (allComplete) {
        label.addToThread(thread);
        report.labelsApplied++;
      } else {
        label.removeFromThread(thread);
      }
    } catch (error) {
      ctmLog_('WARN', 'Impossible de mettre à jour le libellé de la conversation.', {
        threadId: thread.getId(),
        error: ctmErrorMessage_(error),
      });
    }
  });
}

/**
 * Vérifie le dossier et crée le libellé. À exécuter une fois avant la recette.
 */
function setupFolderAndLabels() {
  ctmValidateConfig_();
  const folder = DriveApp.getFolderById(CTM_CONFIG.FOLDER_ID);
  const label = ctmGetOrCreateLabel_(CTM_CONFIG.LABEL_NAME);
  ctmLog_('INFO', 'Configuration CTM valide.', {
    folderName: folder.getName(),
    folderId: folder.getId(),
    label: label.getName(),
    timeZone: CTM_CONFIG.TIME_ZONE,
  });
}

/**
 * Crée le déclencheur de 15 minutes s'il n'existe pas déjà.
 */
function createCtmTimeDrivenTrigger() {
  ctmValidateConfig_();
  const exists = ScriptApp.getProjectTriggers().some(function(trigger) {
    return trigger.getHandlerFunction() === CTM_CONFIG.TRIGGER_FUNCTION;
  });

  if (exists) {
    ctmLog_('INFO', 'Le déclencheur CTM existe déjà.');
    return;
  }

  ScriptApp.newTrigger(CTM_CONFIG.TRIGGER_FUNCTION)
    .timeBased()
    .everyMinutes(CTM_CONFIG.TRIGGER_INTERVAL_MINUTES)
    .create();
  ctmLog_('INFO', 'Déclencheur CTM créé.', {
    intervalMinutes: CTM_CONFIG.TRIGGER_INTERVAL_MINUTES,
  });
}

/** @private */
function ctmValidateConfig_() {
  if (!CTM_CONFIG.FOLDER_ID || CTM_CONFIG.FOLDER_ID.indexOf('A_REMPLACER') !== -1) {
    throw new Error('Renseignez CTM_CONFIG.FOLDER_ID dans Config.gs.');
  }
  if (!CTM_CONFIG.SEARCH_QUERY || !CTM_CONFIG.EXPECTED_SENDER || !CTM_CONFIG.EXPECTED_SUBJECT) {
    throw new Error('La configuration Gmail CTM est incomplète.');
  }
  if (!CTM_CONFIG.LABEL_NAME) {
    throw new Error('CTM_CONFIG.LABEL_NAME est vide.');
  }
  if (CTM_CONFIG.INITIAL_LOOKBACK_MONTHS < 1 || CTM_CONFIG.MAX_MESSAGES_PER_RUN < 1) {
    throw new Error('La configuration du rattrapage CTM est invalide.');
  }
}
