/** Traite tous les profils actifs configurés dans MAIL_IMPORT_FLOWS. */
function processMailImports() {
  ScriptApp.requireAllScopes(ScriptApp.AuthMode.FULL);
  return mailImportProcessConfiguredFlows_(MAIL_IMPORT_FLOWS);
}

/** @private */
function mailImportProcessConfiguredFlows_(flows) {
  mailImportValidateConfigs_(flows);

  const lock = LockService.getScriptLock();
  if (!lock.tryLock(MAIL_IMPORT_ENGINE_CONFIG.LOCK_WAIT_MS)) {
    virementLog_('WARN', 'Une autre exécution multi-flux est déjà en cours.');
    return [];
  }

  const reports = [];
  const criticalErrors = [];
  try {
    flows.forEach(function(flow) {
      if (!flow.ENABLED) return;
      try {
        reports.push(mailImportProcessFlow_(flow));
      } catch (error) {
        const failureReport = mailImportEmptyReport_(flow);
        failureReport.errors = 1;
        failureReport.criticalError = virementErrorMessage_(error);
        reports.push(failureReport);
        criticalErrors.push(flow.ID + ': ' + failureReport.criticalError);
        mailImportFlowLog_(flow, 'ERROR', 'Échec critique du flux.', {
          error: failureReport.criticalError,
          stack: error && error.stack ? String(error.stack) : '',
        });
      }
    });
  } finally {
    virementLog_('INFO', 'Bilan global multi-flux.', {reports: reports});
    lock.releaseLock();
  }

  if (criticalErrors.length > 0) {
    throw new Error('Un ou plusieurs flux ont échoué :\n' + criticalErrors.join('\n'));
  }
  return reports;
}

/** Alias compatible avec l'ancien déclencheur. */
function processVirementEmails() {
  return processMailImports();
}

/** @private */
function mailImportProcessFlow_(flow) {
  const report = mailImportEmptyReport_(flow);
  const parentFolder = DriveApp.getFolderById(flow.FOLDER_ID);
  const label = virementGetOrCreateLabel_(flow.LABEL_NAME);
  const state = virementLoadState_(flow);
  const now = new Date();
  const cutoff = virementCutoffDate_(now, flow.INITIAL_LOOKBACK_MONTHS);
  const query = virementBuildSearchQuery_(flow, now);
  const searchResult = virementSearchThreads_(query);
  const collection = virementCollectMessages_(
    searchResult.threads,
    cutoff,
    report,
    flow,
    now
  );

  report.threads = searchResult.threads.length;
  report.matched = collection.items.length;
  mailImportFlowLog_(flow, 'INFO', 'Début du traitement du flux.', {
    version: MAIL_IMPORT_ENGINE_CONFIG.CODE_VERSION,
    query: query,
    folder: parentFolder.getName(),
    matched: report.matched,
    rejected: collection.rejectionReasons,
  });

  for (let index = 0; index < collection.items.length; index++) {
    const item = collection.items[index];
    if (virementIsProcessed_(state, item.messageId)) {
      report.alreadyProcessed++;
      continue;
    }
    if (report.attempted >=
        MAIL_IMPORT_ENGINE_CONFIG.MAX_MESSAGES_PER_FLOW_PER_RUN) {
      report.deferred = collection.items.slice(index).filter(function(candidate) {
        return !virementIsProcessed_(state, candidate.messageId);
      }).length;
      break;
    }

    report.attempted++;
    try {
      const extraction = virementExtractAttachments_(item.message, flow);
      report.skippedFiles += extraction.skipped;
      const dateFolder = virementGetDateFolder_(
        parentFolder,
        item.message.getDate(),
        flow
      );
      extraction.candidates.forEach(function(candidate) {
        const saveResult = virementSaveAttachment_(
          dateFolder,
          candidate,
          item.message,
          flow
        );
        if (saveResult.created) report.createdFiles++;
        else report.recoveredFiles++;
      });
      virementMarkProcessed_(state, item.message);
      virementSaveState_(state, flow);
    } catch (error) {
      report.errors++;
      mailImportFlowLog_(flow, 'ERROR', 'Message non traité ; il sera retenté.', {
        messageId: item.messageId,
        error: virementErrorMessage_(error),
      });
    }
  }

  if (!collection.failed && report.deferred === 0 && !searchResult.hasMore) {
    state.lastSuccessfulRunIso = now.toISOString();
  }
  virementSaveState_(state, flow);
  virementUpdateThreadLabels_(
    searchResult.threads,
    label,
    state,
    cutoff,
    report,
    flow,
    now
  );

  if (searchResult.hasMore) {
    report.errors++;
    mailImportFlowLog_(flow, 'ERROR', 'Plafond de conversations atteint.', {
      maxThreads: MAIL_IMPORT_ENGINE_CONFIG.MAX_THREADS_PER_FLOW_PER_RUN,
    });
  }
  mailImportFlowLog_(flow, 'INFO', 'Bilan du flux.', report);
  return report;
}

/** Diagnostic en lecture seule de tous les profils actifs. */
function diagnoseMailImports() {
  mailImportValidateConfigs_(MAIL_IMPORT_FLOWS);
  return MAIL_IMPORT_FLOWS.filter(function(flow) {
    return flow.ENABLED;
  }).map(function(flow) {
    try {
      return mailImportDiagnoseFlow_(flow);
    } catch (error) {
      return {
        flowId: flow.ID,
        flowName: flow.DISPLAY_NAME,
        version: MAIL_IMPORT_ENGINE_CONFIG.CODE_VERSION,
        error: virementErrorMessage_(error),
      };
    }
  });
}

/** Alias compatible. */
function diagnoseVirementEmails() {
  return diagnoseMailImports();
}

/** @private */
function mailImportDiagnoseFlow_(flow) {
  const folder = DriveApp.getFolderById(flow.FOLDER_ID);
  const now = new Date();
  const cutoff = virementCutoffDate_(now, flow.INITIAL_LOOKBACK_MONTHS);
  const query = virementBuildSearchQuery_(flow, now);
  const searchResult = virementSearchThreads_(query);
  const result = {
    flowId: flow.ID,
    flowName: flow.DISPLAY_NAME,
    version: MAIL_IMPORT_ENGINE_CONFIG.CODE_VERSION,
    folderName: folder.getName(),
    query: query,
    threads: searchResult.threads.length,
    matchedMessages: 0,
    acceptedFiles: 0,
    rejectedByReason: {},
  };

  searchResult.threads.forEach(function(thread) {
    try {
      thread.getMessages().forEach(function(message) {
        const match = virementGetMessageMatchResult_(message, cutoff, flow, now);
        if (!match.matches) {
          result.rejectedByReason[match.reason] =
            (result.rejectedByReason[match.reason] || 0) + 1;
          return;
        }
        result.matchedMessages++;
        const acceptedNames = message.getAttachments({
          includeInlineImages: false,
          includeAttachments: true,
        }).map(function(attachment) {
          return attachment.getName();
        }).filter(function(fileName) {
          return virementIsAllowedAttachment_(fileName, flow.ALLOWED_EXTENSIONS);
        });
        result.acceptedFiles += acceptedNames.length;
        mailImportFlowLog_(flow, 'INFO', 'Diagnostic : message accepté.', {
          date: message.getDate().toISOString(),
          sender: virementExtractEmailAddress_(message.getFrom()),
          subject: message.getSubject(),
          files: acceptedNames,
        });
      });
    } catch (error) {
      result.rejectedByReason.unreadableThread =
        (result.rejectedByReason.unreadableThread || 0) + 1;
    }
  });
  mailImportFlowLog_(flow, 'INFO', 'Diagnostic terminé.', result);
  return result;
}

/** Vérifie les dossiers et crée les libellés de tous les profils actifs. */
function setupMailImportProject() {
  ScriptApp.requireAllScopes(ScriptApp.AuthMode.FULL);
  mailImportValidateConfigs_(MAIL_IMPORT_FLOWS);
  const errors = [];
  MAIL_IMPORT_FLOWS.forEach(function(flow) {
    if (!flow.ENABLED) return;
    try {
      const folder = DriveApp.getFolderById(flow.FOLDER_ID);
      const label = virementGetOrCreateLabel_(flow.LABEL_NAME);
      mailImportFlowLog_(flow, 'INFO', 'Flux prêt.', {
        folderName: folder.getName(),
        folderId: folder.getId(),
        label: label.getName(),
      });
    } catch (error) {
      errors.push(flow.ID + ': ' + virementErrorMessage_(error));
    }
  });
  if (errors.length > 0) {
    throw new Error('Configuration inaccessible :\n' + errors.join('\n'));
  }
}

/** Alias compatible. */
function setupVirementProject() {
  return setupMailImportProject();
}

/** Efface l'état de chaque profil sans supprimer de mail ni de fichier. */
function resetMailImportStates() {
  const properties = PropertiesService.getScriptProperties();
  MAIL_IMPORT_FLOWS.forEach(function(flow) {
    if (flow.STATE_PROPERTY_KEY) {
      properties.deleteProperty(flow.STATE_PROPERTY_KEY);
    }
  });
  virementLog_('INFO', 'États d’import multi-flux réinitialisés.');
}

/** Alias compatible. */
function resetVirementImportState() {
  return resetMailImportStates();
}

/** Crée un unique déclencheur global toutes les heures. */
function createMailImportTimeDrivenTrigger() {
  mailImportValidateConfigs_(MAIL_IMPORT_FLOWS);
  const compatibleHandlers = [
    MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_FUNCTION,
    'processVirementEmails',
  ];
  const triggers = ScriptApp.getProjectTriggers();
  const properties = PropertiesService.getScriptProperties();
  const expectedStatePrefix =
    MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_SCHEDULE_VERSION + ':';
  const storedState = String(properties.getProperty(
    MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_STATE_PROPERTY_KEY
  ) || '');
  const storedTriggerId = storedState.indexOf(expectedStatePrefix) === 0
    ? storedState.slice(expectedStatePrefix.length)
    : '';
  const currentTriggerExists = !!storedTriggerId && triggers.some(function(trigger) {
    return trigger.getUniqueId() === storedTriggerId &&
      trigger.getHandlerFunction() === MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_FUNCTION;
  });

  if (currentTriggerExists) {
    virementLog_('INFO', 'Le déclencheur multi-flux horaire existe déjà.', {
      triggerId: storedTriggerId,
    });
    return;
  }

  let deleted = 0;
  triggers.forEach(function(trigger) {
    if (compatibleHandlers.indexOf(trigger.getHandlerFunction()) === -1) return;
    ScriptApp.deleteTrigger(trigger);
    deleted++;
  });

  const created = ScriptApp.newTrigger(MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_FUNCTION)
    .timeBased()
    .everyHours(MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_INTERVAL_HOURS)
    .create();
  properties.setProperty(
    MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_STATE_PROPERTY_KEY,
    expectedStatePrefix + created.getUniqueId()
  );
  virementLog_('INFO', 'Déclencheur multi-flux horaire créé.', {
    intervalHours: MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_INTERVAL_HOURS,
    triggerId: created.getUniqueId(),
    replacedTriggers: deleted,
  });
}

/** Alias compatible. */
function createVirementTimeDrivenTrigger() {
  return createMailImportTimeDrivenTrigger();
}

/** @private */
function mailImportEmptyReport_(flow) {
  return {
    flowId: flow.ID,
    flowName: flow.DISPLAY_NAME,
    version: MAIL_IMPORT_ENGINE_CONFIG.CODE_VERSION,
    threads: 0,
    matched: 0,
    attempted: 0,
    alreadyProcessed: 0,
    createdFiles: 0,
    recoveredFiles: 0,
    skippedFiles: 0,
    deferred: 0,
    errors: 0,
    labelsApplied: 0,
  };
}

/** @private */
function virementCollectMessages_(threads, cutoff, report, flow, referenceDate) {
  const items = [];
  const rejectionReasons = {};
  let failed = false;
  threads.forEach(function(thread) {
    try {
      thread.getMessages().forEach(function(message) {
        try {
          const match = virementGetMessageMatchResult_(
            message,
            cutoff,
            flow,
            referenceDate
          );
          if (!match.matches) {
            rejectionReasons[match.reason] =
              (rejectionReasons[match.reason] || 0) + 1;
            return;
          }
          items.push({
            message: message,
            thread: thread,
            messageId: message.getId(),
            receivedMs: message.getDate().getTime(),
          });
        } catch (error) {
          failed = true;
          report.errors++;
        }
      });
    } catch (error) {
      failed = true;
      report.errors++;
      mailImportFlowLog_(flow, 'ERROR', 'Conversation Gmail illisible.', {
        threadId: thread.getId(),
        error: virementErrorMessage_(error),
      });
    }
  });
  items.sort(function(left, right) {
    if (left.receivedMs !== right.receivedMs) return left.receivedMs - right.receivedMs;
    return left.messageId.localeCompare(right.messageId);
  });
  return {items: items, failed: failed, rejectionReasons: rejectionReasons};
}

/** @private */
function virementUpdateThreadLabels_(
  threads,
  label,
  state,
  cutoff,
  report,
  flow,
  referenceDate
) {
  threads.forEach(function(thread) {
    try {
      const matchingMessages = thread.getMessages().filter(function(message) {
        return virementGetMessageMatchResult_(
          message,
          cutoff,
          flow,
          referenceDate
        ).matches;
      });
      if (matchingMessages.length === 0) return;
      const allProcessed = matchingMessages.every(function(message) {
        return virementIsProcessed_(state, message.getId());
      });
      if (allProcessed) {
        label.addToThread(thread);
        report.labelsApplied++;
      } else {
        label.removeFromThread(thread);
      }
    } catch (error) {
      mailImportFlowLog_(flow, 'WARN', 'Libellé de conversation non mis à jour.', {
        threadId: thread.getId(),
        error: virementErrorMessage_(error),
      });
    }
  });
}

/** Valide la structure et l'unicité des profils avant tout accès externe. */
function mailImportValidateConfigs_(flows) {
  if (!Array.isArray(flows) || flows.length === 0) {
    throw new Error('MAIL_IMPORT_FLOWS doit contenir au moins un profil.');
  }
  const uniqueFields = [
    'ID',
    'LABEL_NAME',
    'STATE_PROPERTY_KEY',
    'DRIVE_MESSAGE_MARKER_PREFIX',
  ];
  const seen = {};
  uniqueFields.forEach(function(field) { seen[field] = {}; });

  flows.forEach(function(flow, index) {
    if (!flow || !flow.ID) {
      throw new Error('Le profil à l’index ' + index + ' doit avoir un ID.');
    }
    if (typeof flow.ENABLED !== 'boolean') {
      throw new Error('Le profil "' + flow.ID + '" doit définir ENABLED.');
    }
    uniqueFields.forEach(function(field) {
      const value = flow[field];
      if (!value) return;
      if (seen[field][value]) {
        throw new Error(
          'Valeur dupliquée pour ' + field + ' : "' + value + '".'
        );
      }
      seen[field][value] = true;
    });

    if (!flow.ENABLED) return;
    const requiredStrings = [
      'DISPLAY_NAME', 'FOLDER_ID', 'SEARCH_QUERY', 'LABEL_NAME',
      'STATE_PROPERTY_KEY', 'DRIVE_MESSAGE_MARKER_PREFIX', 'TIME_ZONE',
      'SUBFOLDER_DATE_FORMAT', 'FILE_NAME_MODE', 'FILE_TIMESTAMP_FORMAT',
    ];
    requiredStrings.forEach(function(field) {
      if (!String(flow[field] || '').trim()) {
        throw new Error('Le profil "' + flow.ID + '" doit définir ' + field + '.');
      }
    });
    const requiredArrays = [
      'EXPECTED_SENDERS', 'EXPECTED_SUBJECT_PREFIXES',
    ];
    requiredArrays.forEach(function(field) {
      if (!Array.isArray(flow[field]) || flow[field].length === 0) {
        throw new Error('Le profil "' + flow.ID + '" doit définir ' + field + '.');
      }
    });
    if (!Array.isArray(flow.ALLOWED_EXTENSIONS)) {
      throw new Error(
        'Le profil "' + flow.ID + '" doit définir ALLOWED_EXTENSIONS.'
      );
    }
    flow.ALLOWED_EXTENSIONS.forEach(function(extension) {
      if (!/^[a-z0-9]+$/.test(String(extension))) {
        throw new Error(
          'Extension invalide dans le profil "' + flow.ID + '" : ' + extension
        );
      }
    });
    if (!Number.isInteger(flow.INITIAL_LOOKBACK_MONTHS) ||
        flow.INITIAL_LOOKBACK_MONTHS < 1) {
      throw new Error(
        'INITIAL_LOOKBACK_MONTHS invalide pour le profil "' + flow.ID + '".'
      );
    }
    if (flow.DATE_OFFSET_DAYS !== null &&
        flow.DATE_OFFSET_DAYS !== undefined &&
        (!Number.isInteger(flow.DATE_OFFSET_DAYS) || flow.DATE_OFFSET_DAYS < 0)) {
      throw new Error(
        'DATE_OFFSET_DAYS invalide pour le profil "' + flow.ID + '".'
      );
    }
    if (typeof flow.CREATE_DATE_SUBFOLDER !== 'boolean') {
      throw new Error(
        'CREATE_DATE_SUBFOLDER invalide pour le profil "' + flow.ID + '".'
      );
    }
    if (['original', 'timestamp_original'].indexOf(flow.FILE_NAME_MODE) === -1) {
      throw new Error('FILE_NAME_MODE invalide pour le profil "' + flow.ID + '".');
    }
  });
}

/** Alias de validation historique. @private */
function virementValidateConfig_() {
  return mailImportValidateConfigs_(MAIL_IMPORT_FLOWS);
}
