/**
 * Point d'entrée principal. À lancer manuellement pour la recette, puis avec un
 * déclencheur temporel toutes les 15 minutes.
 */
function processCtmEmails() {
  const lock = LockService.getScriptLock();
  if (!lock.tryLock(CTM_CONFIG.LOCK_WAIT_MS)) {
    ctmLog_('WARN', 'Une autre exécution CTM est déjà en cours. Arrêt sans traitement.');
    return;
  }

  const report = {
    threads: 0,
    matched: 0,
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
    const cutoff = ctmSearchCutoff_(CTM_CONFIG, now);
    const query = ctmBuildSearchQuery_(CTM_CONFIG, now);

    ctmLog_('INFO', 'Début du traitement CTM.', {
      destination: folder.getName(),
      query: query,
    });

    const threads = ctmSearchThreads_(query);
    report.threads = threads.length;
    ctmLog_('INFO', 'Conversations Gmail trouvées.', {count: threads.length});

    threads.forEach(function(thread) {
      try {
        ctmProcessThread_(thread, folder, label, state, cutoff, report);
      } catch (error) {
        report.errors++;
        ctmLog_('ERROR', 'Conversation non traitée ; poursuite avec la suivante.', {
          threadId: thread.getId(),
          error: ctmErrorMessage_(error),
        });
      }
    });

    state.lastRunIso = new Date().toISOString();
    ctmSaveState_(state);

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
function ctmProcessThread_(thread, folder, label, state, cutoff, report) {
  const messages = [];
  let allComplete = true;

  thread.getMessages().forEach(function(message) {
    try {
      if (ctmMessageMatches_(message, cutoff)) messages.push(message);
    } catch (error) {
      allComplete = false;
      report.errors++;
      ctmLog_('ERROR', 'Impossible de contrôler les métadonnées d’un message.', {
        error: ctmErrorMessage_(error),
      });
    }
  });

  if (messages.length === 0 && allComplete) return;

  messages.forEach(function(message) {
    const messageId = message.getId();
    report.matched++;

    if (ctmIsProcessed_(state, messageId)) {
      report.alreadyProcessed++;
      return;
    }

    try {
      const csvCandidate = ctmExtractSingleCsv_(message);
      const saveResult = ctmSaveCsv_(folder, csvCandidate, message);
      if (saveResult.created) report.created++;
      else report.recovered++;

      ctmMarkProcessed_(state, message);
      ctmSaveState_(state);
    } catch (error) {
      allComplete = false;
      report.errors++;
      ctmLog_('ERROR', 'Message non traité ; il sera retenté.', {
        messageId: messageId,
        receivedAt: message.getDate().toISOString(),
        error: ctmErrorMessage_(error),
      });
    }
  });

  // Vérification finale de tous les messages CTM visibles dans la fenêtre.
  if (messages.some(function(message) {
    return !ctmIsProcessed_(state, message.getId());
  })) {
    allComplete = false;
  }

  try {
    if (allComplete) {
      label.addToThread(thread);
      report.labelsApplied++;
    } else {
      // Un nouveau message en erreur peut appartenir à une conversation déjà
      // labellisée ; retirer le label évite un faux indicateur de réussite.
      label.removeFromThread(thread);
    }
  } catch (error) {
    ctmLog_('WARN', 'Impossible de mettre à jour le libellé de la conversation.', {
      threadId: thread.getId(),
      error: ctmErrorMessage_(error),
    });
  }
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
}
