/**
 * Point d'entrée principal. À lancer manuellement pour la recette, puis avec un
 * déclencheur temporel toutes les 15 minutes.
 *
 * Cette automatisation ne supprime aucun e-mail et ne modifie jamais son état
 * lu/non lu. Le libellé de suivi est la seule modification effectuée dans Gmail.
 */
function processCtmEmails() {
  // Ne demande rien lorsque les droits sont deja accordes. En execution
  // manuelle, Google affiche l'ecran de consentement si un scope manque.
  ctmRequireFullAuthorization_();

  const lock = LockService.getScriptLock();
  if (!lock.tryLock(CTM_CONFIG.LOCK_WAIT_MS)) {
    ctmLog_('WARN', 'Une autre exécution CTM est déjà en cours. Arrêt sans traitement.');
    return;
  }

  const report = {
    version: CTM_CONFIG.CODE_VERSION,
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
      version: CTM_CONFIG.CODE_VERSION,
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
    ctmLog_('INFO', 'Résultat du filtrage des messages.', {
      version: CTM_CONFIG.CODE_VERSION,
      matched: report.matched,
      rejected: collection.rejectionReasons,
    });

    if (ctmShouldBlockEmptyInitialBackfill_(
      state,
      searchWindow.mode,
      threads.length,
      report.matched
    )) {
      throw new Error(
        'Incoherence de filtrage : la recherche Gmail a trouve ' + threads.length +
        ' conversation(s), mais aucun message CTM. Verifiez que Config.gs, ' +
        'Utils.gs et GmailService.gs sont tous deployes dans la meme version.'
      );
    }

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
    // Une erreur de configuration ou d'accès doit faire apparaître l'exécution
    // en échec dans Apps Script, et non comme une exécution terminée sans fichier.
    throw error;
  } finally {
    ctmLog_('INFO', 'Bilan du traitement CTM.', report);
    lock.releaseLock();
  }
}

/**
 * Diagnostic en lecture seule : vérifie la configuration, l'accès Drive et les
 * messages réellement visibles dans Gmail. Cette fonction ne crée aucun fichier,
 * ne pose aucun libellé et ne modifie aucun e-mail.
 */
function diagnoseCtmEmails() {
  const result = {
    version: CTM_CONFIG.CODE_VERSION,
    configurationValid: false,
    folderAccessible: false,
    effectiveUser: '',
    broadMessages: 0,
    exactMessages: 0,
    subjectMatchesMessages: 0,
    mainFilterMessages: 0,
    mainFilterRejections: {},
    outsideWindowMessages: 0,
    latestOutsideWindowDate: null,
    discoveryMessages: 0,
    discoveredSenders: [],
    discoveredSubjects: [],
  };

  try {
    result.effectiveUser = Session.getEffectiveUser().getEmail() || '';
    ctmLog_('INFO', 'Diagnostic : compte Google exécutant le script.', {
      effectiveUser: result.effectiveUser || '(adresse non exposée par Google)',
    });
  } catch (error) {
    ctmLog_('WARN', 'Diagnostic : compte exécutant non déterminé.', {
      error: ctmErrorMessage_(error),
    });
  }

  try {
    ctmValidateConfig_();
    result.configurationValid = true;
    const folder = DriveApp.getFolderById(CTM_CONFIG.FOLDER_ID);
    result.folderAccessible = true;
    ctmLog_('INFO', 'Diagnostic : dossier Drive accessible.', {
      folderName: folder.getName(),
      folderId: folder.getId(),
    });
  } catch (error) {
    ctmLog_('ERROR', 'Diagnostic : configuration ou dossier Drive invalide.', {
      error: ctmErrorMessage_(error),
    });
  }

  const now = new Date();
  const cutoff = ctmSubtractCalendarMonths_(now, CTM_CONFIG.INITIAL_LOOKBACK_MONTHS);
  cutoff.setHours(0, 0, 0, 0);
  const broadQuery = 'from:' + CTM_CONFIG.EXPECTED_SENDER +
    ' has:attachment newer_than:' + CTM_CONFIG.INITIAL_LOOKBACK_MONTHS + 'm';
  const exactQuery = CTM_CONFIG.SEARCH_QUERY +
    ' has:attachment newer_than:' + CTM_CONFIG.INITIAL_LOOKBACK_MONTHS + 'm';

  ctmLog_('INFO', 'Diagnostic : recherche Gmail large.', {query: broadQuery});
  const broadThreads = GmailApp.search(broadQuery, 0, 100);
  let logged = 0;

  broadThreads.forEach(function(thread) {
    thread.getMessages().forEach(function(message) {
      if (message.getDate().getTime() < cutoff.getTime()) return;
      if (ctmExtractEmailAddress_(message.getFrom()) !== CTM_CONFIG.EXPECTED_SENDER.toLowerCase()) {
        return;
      }

      const attachments = message.getAttachments({
        includeInlineImages: false,
        includeAttachments: true,
      });
      if (attachments.length === 0) return;

      result.broadMessages++;
      const messageSubject = String(message.getSubject() || '').trim();
      const exactSubject = messageSubject === CTM_CONFIG.EXPECTED_SUBJECT_PREFIX;
      const subjectMatches = ctmSubjectMatches_(
        messageSubject,
        CTM_CONFIG.EXPECTED_SUBJECT_PREFIX
      );
      if (exactSubject) result.exactMessages++;
      if (subjectMatches) result.subjectMatchesMessages++;
      const mainFilterResult = ctmGetMessageMatchResult_(message, cutoff);
      if (mainFilterResult.matches) {
        result.mainFilterMessages++;
      } else {
        result.mainFilterRejections[mainFilterResult.reason] =
          (result.mainFilterRejections[mainFilterResult.reason] || 0) + 1;
      }

      if (logged < 20) {
        ctmLog_('INFO', 'Diagnostic : message candidat.', {
          date: message.getDate().toISOString(),
          sender: ctmExtractEmailAddress_(message.getFrom()),
          subject: message.getSubject(),
          exactSubject: exactSubject,
          subjectMatches: subjectMatches,
          mainFilterMatches: mainFilterResult.matches,
          mainFilterReason: mainFilterResult.reason,
          attachments: attachments.map(function(attachment) {
            return attachment.getName();
          }),
        });
        logged++;
      }
    });
  });

  ctmLog_('INFO', 'Diagnostic : recherche Gmail exacte.', {query: exactQuery});

  // Recherche sans limite de date pour distinguer un mauvais expediteur d'un
  // historique simplement anterieur a la fenetre de quatre mois.
  const historicalQuery = 'in:anywhere from:' + CTM_CONFIG.EXPECTED_SENDER +
    ' has:attachment';
  ctmLog_('INFO', 'Diagnostic : recherche des messages hors fenetre.', {
    query: historicalQuery,
    cutoff: cutoff.toISOString(),
  });
  GmailApp.search(historicalQuery, 0, 100).forEach(function(thread) {
    thread.getMessages().forEach(function(message) {
      const messageDate = message.getDate();
      if (messageDate.getTime() >= cutoff.getTime()) return;
      if (ctmExtractEmailAddress_(message.getFrom()) !==
          CTM_CONFIG.EXPECTED_SENDER.toLowerCase()) return;
      if (!ctmSubjectMatches_(
        message.getSubject(),
        CTM_CONFIG.EXPECTED_SUBJECT_PREFIX
      )) return;

      const attachments = message.getAttachments({
        includeInlineImages: false,
        includeAttachments: true,
      });
      if (attachments.length === 0) return;

      result.outsideWindowMessages++;
      if (!result.latestOutsideWindowDate ||
          messageDate.getTime() > new Date(result.latestOutsideWindowDate).getTime()) {
        result.latestOutsideWindowDate = messageDate.toISOString();
      }
    });
  });

  // Recherche de découverte : aucun filtre d'expéditeur, afin d'identifier
  // l'adresse réellement portée par les mails contenant Report_ctm.
  const discoveryQueries = [
    'in:anywhere has:attachment newer_than:' +
      CTM_CONFIG.INITIAL_LOOKBACK_MONTHS + 'm filename:Report_ctm',
    'in:anywhere has:attachment newer_than:' +
      CTM_CONFIG.INITIAL_LOOKBACK_MONTHS + 'm subject:"Extract CSV"',
  ];
  const seenMessageIds = {};
  const discoveredSenders = {};
  const discoveredSubjects = {};

  discoveryQueries.forEach(function(discoveryQuery) {
    ctmLog_('INFO', 'Diagnostic : recherche de découverte.', {query: discoveryQuery});
    GmailApp.search(discoveryQuery, 0, 100).forEach(function(thread) {
      thread.getMessages().forEach(function(message) {
        const messageId = message.getId();
        if (seenMessageIds[messageId]) return;
        if (message.getDate().getTime() < cutoff.getTime()) return;

        const attachments = message.getAttachments({
          includeInlineImages: false,
          includeAttachments: true,
        });
        const attachmentNames = attachments.map(function(attachment) {
          return attachment.getName();
        });
        const hasReportCtm = attachmentNames.some(function(fileName) {
          return /^Report_ctm_.*\.(?:zip|csv)$/i.test(String(fileName || ''));
        });
        const hasExpectedWords = /extract\s+csv/i.test(String(message.getSubject() || ''));
        if (!hasReportCtm && !hasExpectedWords) return;

        seenMessageIds[messageId] = true;
        result.discoveryMessages++;
        const actualSender = ctmExtractEmailAddress_(message.getFrom());
        const actualSubject = String(message.getSubject() || '').trim();
        discoveredSenders[actualSender] = true;
        discoveredSubjects[actualSubject] = true;

        if (logged < 20) {
          ctmLog_('INFO', 'Diagnostic : message découvert sans filtre expéditeur.', {
            date: message.getDate().toISOString(),
            sender: actualSender,
            subject: actualSubject,
            inTrash: message.isInTrash(),
            attachments: attachmentNames,
          });
          logged++;
        }
      });
    });
  });

  result.discoveredSenders = Object.keys(discoveredSenders).sort();
  result.discoveredSubjects = Object.keys(discoveredSubjects).sort();
  ctmLog_('INFO', 'Diagnostic CTM terminé.', result);
  return result;
}

/** @private */
function ctmCollectCandidateMessages_(threads, cutoff, report) {
  const messages = [];
  let failed = false;
  const rejectionReasons = {};

  threads.forEach(function(thread) {
    try {
      thread.getMessages().forEach(function(message) {
        try {
          const matchResult = ctmGetMessageMatchResult_(message, cutoff);
          if (!matchResult.matches) {
            rejectionReasons[matchResult.reason] =
              (rejectionReasons[matchResult.reason] || 0) + 1;
            return;
          }
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

  return {
    messages: messages,
    failed: failed,
    rejectionReasons: rejectionReasons,
  };
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
  ctmRequireFullAuthorization_();
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
 * Force l'autorisation de tous les services utilises par le projet, puis teste
 * une vraie ecriture dans le dossier CTM. Le fichier de test est aussitot mis
 * a la corbeille et aucun e-mail n'est modifie.
 *
 * A lancer manuellement depuis l'editeur Apps Script avant le premier import.
 */
function authorizeAndTestCtmDrive() {
  ctmRequireFullAuthorization_();
  ctmValidateConfig_();

  const folder = DriveApp.getFolderById(CTM_CONFIG.FOLDER_ID);
  const testName = 'CTM_PERMISSION_TEST_' + new Date().getTime() + '.txt';
  let testFile = null;

  try {
    testFile = folder.createFile(
      Utilities.newBlob(
        'Test temporaire d\'autorisation Drive pour le projet CTM.',
        'text/plain',
        testName
      )
    );
    ctmLog_('INFO', 'Test d\'ecriture Drive reussi.', {
      version: CTM_CONFIG.CODE_VERSION,
      folderName: folder.getName(),
      fileId: testFile.getId(),
    });
    return true;
  } catch (error) {
    ctmLog_('ERROR', 'Test d\'ecriture Drive refuse.', {
      version: CTM_CONFIG.CODE_VERSION,
      folderName: folder.getName(),
      error: ctmErrorMessage_(error),
    });
    throw error;
  } finally {
    if (testFile) {
      try {
        testFile.setTrashed(true);
        ctmLog_('INFO', 'Fichier temporaire de permission place dans la corbeille.', {
          fileId: testFile.getId(),
        });
      } catch (cleanupError) {
        ctmLog_('WARN', 'Le fichier temporaire doit etre supprime manuellement.', {
          fileId: testFile.getId(),
          fileName: testName,
          error: ctmErrorMessage_(cleanupError),
        });
      }
    }
  }
}

/** @private */
function ctmRequireFullAuthorization_() {
  ScriptApp.requireAllScopes(ScriptApp.AuthMode.FULL);
}

/**
 * Efface uniquement le curseur et les identifiants d'import memorises.
 * Les e-mails, leurs libelles et les fichiers Drive ne sont pas supprimes.
 * A executer manuellement avant de recommencer un rattrapage des quatre mois.
 */
function resetCtmImportState() {
  PropertiesService.getScriptProperties()
    .deleteProperty(CTM_CONFIG.STATE_PROPERTY_KEY);
  ctmLog_('INFO', 'Etat d\'import CTM reinitialise.', {
    propertyKey: CTM_CONFIG.STATE_PROPERTY_KEY,
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
  if (!CTM_CONFIG.SEARCH_QUERY || !CTM_CONFIG.EXPECTED_SENDER ||
      !CTM_CONFIG.EXPECTED_SUBJECT_PREFIX) {
    throw new Error('La configuration Gmail CTM est incomplète.');
  }
  if (!CTM_CONFIG.LABEL_NAME) {
    throw new Error('CTM_CONFIG.LABEL_NAME est vide.');
  }
  if (CTM_CONFIG.INITIAL_LOOKBACK_MONTHS < 1 || CTM_CONFIG.MAX_MESSAGES_PER_RUN < 1) {
    throw new Error('La configuration du rattrapage CTM est invalide.');
  }
}
