/**
 * @fileoverview Recherche dans Gmail les e-mails de virements d'une journée donnée (J-N),
 * télécharge leurs pièces jointes et les enregistre sous leur nom d'origine dans un
 * sous-dossier Google Drive daté (ex. "05072026" pour les mails du 05 juillet 2026).
 *
 * IMPORTANT : ce fichier partage l'espace de noms global du projet Apps Script avec
 * controlePrelevement.gs. Tous les identifiants sont donc préfixés par `virement`
 * pour éviter toute collision. Ne pas renommer sans vérifier l'autre fichier.
 */

//================ CONFIGURATION ================
const VIREMENT_CONFIG = {
  // Dossier Drive de destination. Accepte soit un ID de dossier, soit un nom.
  // - ID  : le dossier doit exister (erreur bloquante sinon).
  // - Nom : le dossier est créé automatiquement s'il n'existe pas.
  DRIVE_FOLDER: '1KFQvMNyQEy2H4niTTWg9jSeyCrJCS51Q',

  // Range les pièces jointes dans un sous-dossier nommé d'après la date de
  // réception des e-mails (ex. un mail du 05 juillet 2026 -> sous-dossier
  // "05072026"). Le sous-dossier n'est créé qu'au premier fichier enregistré.
  CREATE_DATE_SUBFOLDER: true,

  // Format du nom du sous-dossier (syntaxe SimpleDateFormat).
  // 'ddMMyyyy' -> 05072026 | 'yyyy-MM-dd' -> 2026-07-05
  SUBFOLDER_DATE_FORMAT: 'ddMMyyyy',

  // Objets des e-mails recherchés (comparaison insensible à la casse, aux accents
  // de préfixe "Re:/Tr:/Fwd:" et aux espaces multiples — voir SUBJECT_MATCH_MODE).
  // En mode 'prefix', il suffit d'indiquer le début invariant de l'objet : la
  // partie variable (date, numéro de lot, montant...) est ignorée.
  EMAIL_SUBJECTS: [
    'Dalkia Virements importés du jour',
    'Calcul du poids pour la campagne de virements',
  ],

  // 'prefix' : l'objet doit COMMENCER par une des chaînes ci-dessus (recommandé :
  //            tolère les objets complétés par une date ou un numéro de lot).
  // 'exact'  : l'objet doit correspondre exactement.
  SUBJECT_MATCH_MODE: 'prefix',

  // Décalage en jours pour la recherche des e-mails (ex : 3 = J-3).
  DATE_OFFSET_DAYS: 3,

  // Fuseau horaire utilisé pour le formatage des dates et le nom des fichiers.
  TIMEZONE: Session.getScriptTimeZone(),

  // Extensions autorisées, sans le point. Laisser [] pour tout accepter.
  // Ex : ['csv', 'zip', 'pdf']
  ALLOWED_EXTENSIONS: [],

  // Nombre maximum de conversations analysées par exécution (garde-fou quotas).
  MAX_THREADS_PER_RUN: 500,

  // Appliquer un label Gmail pour ne pas retraiter les mêmes e-mails.
  APPLY_LABEL: true,
  PROCESSED_LABEL_NAME: 'Controle_Virement_Traité',

  // Ajoute un filtre `subject:` à la requête Gmail pour réduire le volume analysé.
  // Le filtre reste approximatif (Gmail ignore la ponctuation) : le script
  // revérifie systématiquement l'objet exact côté code.
  USE_SUBJECT_PREFILTER: true,

  // Ignore les images intégrées à la signature / au corps du message.
  INCLUDE_INLINE_IMAGES: false,

  // Mode simulation : journalise tout mais n'écrit rien dans Drive et n'applique
  // aucun label. À utiliser pour valider la configuration avant mise en production.
  DRY_RUN: false,

  // Arrêt propre avant la limite d'exécution Apps Script (6 min). En millisecondes.
  MAX_RUNTIME_MS: 5 * 60 * 1000,
};
//===============================================


/**
 * POINT D'ENTRÉE POUR L'AUTOMATISATION (DÉCLENCHEUR)
 * Traite les e-mails reçus à J-DATE_OFFSET_DAYS. À planifier quotidiennement.
 * @return {!Object} Le résumé du traitement.
 */
function virementRunAutomatically() {
  const today = new Date();
  Logger.log('Lancement automatique — date de référence : %s',
      Utilities.formatDate(today, VIREMENT_CONFIG.TIMEZONE, 'dd/MM/yyyy'));
  return virementProcessForDate(today);
}

/**
 * POINT D'ENTRÉE POUR UN TEST MANUEL
 * Demande une date de référence à l'utilisateur puis lance le traitement.
 * Nécessite un script lié à un Google Sheets ; sinon, utiliser
 * virementRunForDateString('JJ/MM/AAAA') directement depuis l'éditeur.
 */
function virementRunManually() {
  let ui;
  try {
    ui = SpreadsheetApp.getUi();
  } catch (e) {
    Logger.log('Interface indisponible (script non lié à un document ou exécuté ' +
        'hors contexte UI). Utilisez virementRunForDateString(\'JJ/MM/AAAA\').');
    return;
  }

  const response = ui.prompt(
      'Test manuel — téléchargement des virements',
      'Date de référence (JJ/MM/AAAA). La recherche portera sur J-' +
          VIREMENT_CONFIG.DATE_OFFSET_DAYS + ' :',
      ui.ButtonSet.OK_CANCEL);

  if (response.getSelectedButton() !== ui.Button.OK) {
    Logger.log('Opération annulée par l\'utilisateur.');
    return;
  }

  const executionDate = virementParseFrenchDate_(response.getResponseText());
  if (!executionDate) {
    ui.alert('Date invalide. Format attendu : JJ/MM/AAAA (ex. 21/07/2026).');
    return;
  }

  const summary = virementProcessForDate(executionDate);
  ui.alert(
      'Traitement terminé',
      virementFormatSummary_(summary) +
          '\n\nDétail complet dans les journaux d\'exécution.',
      ui.ButtonSet.OK);
}

/**
 * POINT D'ENTRÉE POUR UN RATTRAPAGE
 * Permet de relancer le traitement pour une date précise depuis l'éditeur,
 * sans interface graphique.
 * @param {string} dateString Date de référence au format 'JJ/MM/AAAA'.
 * @return {!Object} Le résumé du traitement.
 */
function virementRunForDateString(dateString) {
  const executionDate = virementParseFrenchDate_(dateString);
  if (!executionDate) {
    throw new Error('Date invalide : "' + dateString + '". Format attendu : JJ/MM/AAAA.');
  }
  return virementProcessForDate(executionDate);
}


/**
 * Logique principale : recherche les e-mails de la date cible et sauvegarde
 * leurs pièces jointes dans Drive.
 * @param {!Date} executionDate Date de référence. La recherche porte sur
 *     `executionDate` - `VIREMENT_CONFIG.DATE_OFFSET_DAYS`.
 * @return {!Object} Résumé { threads, matched, saved, skipped, errors, targetDate, stoppedEarly }.
 */
function virementProcessForDate(executionDate) {
  const cfg = VIREMENT_CONFIG;
  const deadline = new Date().getTime() + cfg.MAX_RUNTIME_MS;

  const summary = {
    threads: 0,
    matched: 0,
    saved: 0,
    skipped: 0,
    errors: 0,
    targetDate: '',
    stoppedEarly: false,
  };

  // --- Date cible (J-N) et bornes de recherche ---
  const searchDate = new Date(executionDate.getTime());
  searchDate.setDate(searchDate.getDate() - cfg.DATE_OFFSET_DAYS);
  const targetDateStr = Utilities.formatDate(searchDate, cfg.TIMEZONE, 'yyyy/MM/dd');
  summary.targetDate = targetDateStr;

  const nextDay = new Date(searchDate.getTime());
  nextDay.setDate(nextDay.getDate() + 1);
  const nextDayStr = Utilities.formatDate(nextDay, cfg.TIMEZONE, 'yyyy/MM/dd');

  Logger.log('Date ciblée : %s (J-%s)', targetDateStr, cfg.DATE_OFFSET_DAYS);
  if (cfg.DRY_RUN) {
    Logger.log('*** MODE SIMULATION (DRY_RUN) — aucun fichier ne sera écrit. ***');
  }

  // --- Dossier de destination ---
  const targetFolder = virementResolveFolder_(cfg.DRIVE_FOLDER);
  if (!targetFolder) {
    return summary; // L'erreur est déjà journalisée.
  }
  Logger.log('Dossier cible : "%s" (ID : %s)', targetFolder.getName(), targetFolder.getId());

  // Destination effective des fichiers : sous-dossier daté, créé à la demande.
  const destination = virementCreateDestination_(targetFolder, searchDate);
  if (cfg.CREATE_DATE_SUBFOLDER) {
    Logger.log('Les pièces jointes seront rangées dans : %s', destination.path);
  }

  // --- Label de suivi ---
  const processedLabel = (cfg.APPLY_LABEL && !cfg.DRY_RUN)
      ? virementGetOrCreateLabel_(cfg.PROCESSED_LABEL_NAME)
      : null;

  // --- Construction de la requête Gmail ---
  const queryParts = ['after:' + targetDateStr, 'before:' + nextDayStr, 'has:attachment'];
  if (cfg.USE_SUBJECT_PREFILTER && cfg.EMAIL_SUBJECTS.length > 0) {
    const subjectFilter = cfg.EMAIL_SUBJECTS
        .map(function(s) { return 'subject:"' + s.replace(/"/g, '') + '"'; })
        .join(' OR ');
    queryParts.push('(' + subjectFilter + ')');
  }
  if (cfg.APPLY_LABEL) {
    // Les guillemets sont indispensables : le nom du label contient des accents.
    queryParts.push('-label:"' + cfg.PROCESSED_LABEL_NAME + '"');
  }
  const searchQuery = queryParts.join(' ');
  Logger.log('Requête Gmail : %s', searchQuery);

  // --- Objets recherchés, normalisés une seule fois ---
  const normalizedSubjects = cfg.EMAIL_SUBJECTS.map(virementNormalizeSubject_);

  // --- Parcours paginé des conversations ---
  const PAGE_SIZE = 100;
  let start = 0;

  while (start < cfg.MAX_THREADS_PER_RUN) {
    if (new Date().getTime() > deadline) {
      Logger.log('Temps d\'exécution maximal atteint. Arrêt anticipé — relancer pour traiter le reste.');
      summary.stoppedEarly = true;
      break;
    }

    const pageSize = Math.min(PAGE_SIZE, cfg.MAX_THREADS_PER_RUN - start);
    const threads = GmailApp.search(searchQuery, start, pageSize);

    if (threads.length === 0) {
      if (start === 0) {
        Logger.log('Aucune conversation ne correspond à la requête pour cette date.');
      }
      break;
    }

    Logger.log('Page %s — %s conversation(s).', (start / PAGE_SIZE) + 1, threads.length);

    for (let i = 0; i < threads.length; i++) {
      summary.threads++;
      const shouldLabel = virementProcessThread_(
          threads[i], destination, targetDateStr, normalizedSubjects, summary);

      if (shouldLabel && processedLabel) {
        try {
          threads[i].addLabel(processedLabel);
        } catch (e) {
          Logger.log('  ! Label non appliqué à la conversation : %s', e.message);
          summary.errors++;
        }
      }
    }

    if (threads.length < pageSize) {
      break; // Dernière page.
    }
    start += pageSize;
  }

  if (start >= cfg.MAX_THREADS_PER_RUN) {
    Logger.log('Limite de %s conversations atteinte. Relancer si nécessaire.', cfg.MAX_THREADS_PER_RUN);
    summary.stoppedEarly = true;
  }
  if (summary.matched === 0) {
    Logger.log('Aucun e-mail dont l\'objet correspond aux critères n\'a été trouvé après filtrage.');
  }

  Logger.log(virementFormatSummary_(summary));
  return summary;
}


/**
 * Traite une conversation : filtre les messages par date et par objet, puis
 * sauvegarde leurs pièces jointes.
 * @param {!GoogleAppsScript.Gmail.GmailThread} thread
 * @param {!Object} destination Destination d'écriture (voir virementCreateDestination_).
 * @param {string} targetDateStr Date attendue au format 'yyyy/MM/dd'.
 * @param {!Array<string>} normalizedSubjects Objets recherchés, normalisés.
 * @param {!Object} summary Compteurs mis à jour en place.
 * @return {boolean} true si au moins un message de la conversation correspond.
 * @private
 */
function virementProcessThread_(thread, destination, targetDateStr, normalizedSubjects, summary) {
  const cfg = VIREMENT_CONFIG;
  const messages = thread.getMessages();
  let threadMatched = false;

  for (let i = 0; i < messages.length; i++) {
    const message = messages[i];

    // 1. La date du message doit correspondre exactement à la date cible.
    const messageDateStr = Utilities.formatDate(message.getDate(), cfg.TIMEZONE, 'yyyy/MM/dd');
    if (messageDateStr !== targetDateStr) {
      continue;
    }

    // 2. L'objet doit correspondre à un des objets configurés.
    const subject = message.getSubject();
    if (!virementSubjectMatches_(subject, normalizedSubjects)) {
      continue;
    }

    // Filtre additionnel sur l'expéditeur pour l'objet "Dalkia Virements...".
    // On normalise l'objet pour une comparaison robuste (casse, préfixes Re:, etc.).
    const normalizedSubject = virementNormalizeSubject_(subject);
    if (normalizedSubject.indexOf(virementNormalizeSubject_('Dalkia Virements importés du jour')) === 0) {
      const from = message.getFrom();
      if (from.toLowerCase().indexOf('quartz.messenger@treasury-factory.com') === -1) {
        Logger.log('  - Ignoré (expéditeur non-conforme pour sujet "Dalkia...") : %s', from);
        continue;
      }
    }

    threadMatched = true;
    summary.matched++;

    const attachments = message.getAttachments({
      includeInlineImages: cfg.INCLUDE_INLINE_IMAGES,
      includeAttachments: true,
    });

    if (attachments.length === 0) {
      Logger.log('  - "%s" : aucune pièce jointe exploitable.', subject);
      continue;
    }

    Logger.log('  - "%s" : %s pièce(s) jointe(s).', subject, attachments.length);

    for (let j = 0; j < attachments.length; j++) {
      virementSaveAttachment_(attachments[j], destination, summary);
    }
  }

  return threadMatched;
}


/**
 * Sauvegarde une pièce jointe dans Drive, sous son nom d'origine.
 * Le classement chronologique est assuré par le sous-dossier daté.
 * @param {!GoogleAppsScript.Gmail.GmailAttachment} attachment
 * @param {!Object} destination Destination d'écriture (voir virementCreateDestination_).
 * @param {!Object} summary Compteurs mis à jour en place.
 * @private
 */
function virementSaveAttachment_(attachment, destination, summary) {
  const fileName = attachment.getName();

  if (!virementIsAllowedExtension_(fileName, VIREMENT_CONFIG.ALLOWED_EXTENSIONS)) {
    Logger.log('    · Ignoré (extension non autorisée) : %s', fileName);
    summary.skipped++;
    return;
  }

  try {
    // Résolution paresseuse : le sous-dossier daté n'est créé qu'ici, donc
    // uniquement si un fichier est réellement à enregistrer.
    const folder = destination.resolve();

    if (!folder) {
      // Uniquement en simulation, lorsque le sous-dossier n'existe pas encore.
      Logger.log('    · [SIMULATION] Aurait été enregistré : %s/%s', destination.path, fileName);
      summary.saved++;
      return;
    }

    // Idempotence : une relance sur la même date ne duplique pas les fichiers.
    if (folder.getFilesByName(fileName).hasNext()) {
      Logger.log('    · Déjà présent, ignoré : %s', fileName);
      summary.skipped++;
      return;
    }

    if (VIREMENT_CONFIG.DRY_RUN) {
      Logger.log('    · [SIMULATION] Aurait été enregistré : %s/%s', destination.path, fileName);
      summary.saved++;
      return;
    }

    virementWithRetry_(function() {
      folder.createFile(attachment.copyBlob().setName(fileName));
    }, 'création de ' + fileName);

    Logger.log('    · Enregistré : %s', fileName);
    summary.saved++;
  } catch (e) {
    Logger.log('    ! ERREUR sur "%s" : %s', fileName, e.message);
    summary.errors++;
  }
}


//================ UTILITAIRES ================

/**
 * Construit la destination d'écriture des pièces jointes.
 *
 * Si CREATE_DATE_SUBFOLDER est actif, les fichiers vont dans un sous-dossier
 * nommé d'après la date des e-mails traités (ex. "05072026" pour le
 * 05 juillet 2026). Le sous-dossier est résolu — et créé si besoin — à la
 * première pièce jointe réellement enregistrée : aucun dossier vide n'est créé
 * lorsqu'aucun e-mail ne correspond.
 *
 * @param {!GoogleAppsScript.Drive.Folder} parentFolder Dossier racine.
 * @param {!Date} messageDate Date des e-mails traités.
 * @return {{path: string, resolve: function(): ?GoogleAppsScript.Drive.Folder}}
 *     `resolve()` retourne le dossier d'écriture, ou null en mode simulation
 *     lorsque le sous-dossier n'existe pas encore.
 * @private
 */
function virementCreateDestination_(parentFolder, messageDate) {
  const cfg = VIREMENT_CONFIG;

  if (!cfg.CREATE_DATE_SUBFOLDER) {
    return {
      path: parentFolder.getName(),
      resolve: function() { return parentFolder; },
    };
  }

  const subFolderName = Utilities.formatDate(
      messageDate, cfg.TIMEZONE, cfg.SUBFOLDER_DATE_FORMAT);
  let resolved = null;

  return {
    path: parentFolder.getName() + '/' + subFolderName,

    resolve: function() {
      if (resolved) {
        return resolved;
      }

      const existing = parentFolder.getFoldersByName(subFolderName);
      if (existing.hasNext()) {
        resolved = existing.next();
        Logger.log('  Sous-dossier "%s" réutilisé.', subFolderName);
        return resolved;
      }

      if (cfg.DRY_RUN) {
        Logger.log('  [SIMULATION] Le sous-dossier "%s" serait créé.', subFolderName);
        return null;
      }

      resolved = virementWithRetry_(function() {
        return parentFolder.createFolder(subFolderName);
      }, 'création du sous-dossier ' + subFolderName);
      Logger.log('  Sous-dossier "%s" créé.', subFolderName);
      return resolved;
    },
  };
}

/**
 * Résout le dossier de destination. La valeur peut être un ID de dossier Drive
 * (le dossier doit alors exister) ou un nom (créé à la volée si absent).
 * @param {string} idOrName
 * @return {?GoogleAppsScript.Drive.Folder} null si le dossier est inaccessible.
 * @private
 */
function virementResolveFolder_(idOrName) {
  const value = String(idOrName || '').trim();
  if (!value) {
    Logger.log('ERREUR : VIREMENT_CONFIG.DRIVE_FOLDER n\'est pas renseigné.');
    return null;
  }

  // Un ID Drive est une longue chaîne sans espace ni caractère accentué.
  const looksLikeId = /^[A-Za-z0-9_-]{25,}$/.test(value);
  if (looksLikeId) {
    try {
      return DriveApp.getFolderById(value);
    } catch (e) {
      Logger.log('ERREUR : dossier Drive introuvable pour l\'ID "%s". Vérifiez l\'ID ' +
          'et vos droits d\'accès. Détail : %s', value, e.message);
      return null;
    }
  }

  try {
    const folders = DriveApp.getFoldersByName(value);
    if (folders.hasNext()) {
      return folders.next();
    }
    Logger.log('Dossier "%s" introuvable — création.', value);
    return DriveApp.createFolder(value);
  } catch (e) {
    Logger.log('ERREUR critique sur le dossier Drive "%s" : %s', value, e.message);
    return null;
  }
}

/**
 * Récupère ou crée un label Gmail.
 * @param {string} name
 * @return {?GoogleAppsScript.Gmail.GmailLabel}
 * @private
 */
function virementGetOrCreateLabel_(name) {
  try {
    let label = GmailApp.getUserLabelByName(name);
    if (!label) {
      label = GmailApp.createLabel(name);
      Logger.log('Label Gmail "%s" créé.', name);
    }
    return label;
  } catch (e) {
    Logger.log('AVERTISSEMENT : label "%s" indisponible, le suivi est désactivé pour ' +
        'cette exécution. Détail : %s', name, e.message);
    return null;
  }
}

/**
 * Normalise un objet d'e-mail pour une comparaison tolérante : suppression des
 * préfixes de réponse/transfert, des espaces superflus et de la casse.
 * @param {string} subject
 * @return {string}
 * @private
 */
function virementNormalizeSubject_(subject) {
  return String(subject || '')
      .replace(/^(?:\s*(?:re|ré|rép|fw|fwd|tr)\s*:\s*)+/i, '')
      .replace(/\s+/g, ' ')
      .trim()
      .toLowerCase();
}

/**
 * Indique si l'objet d'un message correspond à un des objets recherchés,
 * selon VIREMENT_CONFIG.SUBJECT_MATCH_MODE.
 * @param {string} subject
 * @param {!Array<string>} normalizedSubjects
 * @return {boolean}
 * @private
 */
function virementSubjectMatches_(subject, normalizedSubjects) {
  const normalized = virementNormalizeSubject_(subject);
  const exact = VIREMENT_CONFIG.SUBJECT_MATCH_MODE === 'exact';

  return normalizedSubjects.some(function(candidate) {
    return exact ? normalized === candidate : normalized.indexOf(candidate) === 0;
  });
}

/**
 * Vérifie que l'extension d'un fichier fait partie des extensions autorisées.
 * @param {string} fileName
 * @param {!Array<string>} allowedExtensions Extensions sans le point.
 * @return {boolean} true si la liste est vide (tout est accepté).
 * @private
 */
function virementIsAllowedExtension_(fileName, allowedExtensions) {
  if (!Array.isArray(allowedExtensions) || allowedExtensions.length === 0) {
    return true;
  }
  const name = String(fileName || '');
  const dotIndex = name.lastIndexOf('.');
  if (dotIndex <= 0 || dotIndex === name.length - 1) {
    return false; // Pas d'extension exploitable.
  }
  const ext = name.slice(dotIndex + 1).toLowerCase();
  return allowedExtensions.some(function(allowed) {
    return String(allowed).replace(/^\./, '').toLowerCase() === ext;
  });
}

/**
 * Convertit une date saisie au format JJ/MM/AAAA en objet Date, en rejetant les
 * dates syntaxiquement valides mais inexistantes (ex. 31/02/2026).
 * @param {string} dateString
 * @return {?Date} null si la date est invalide.
 * @private
 */
function virementParseFrenchDate_(dateString) {
  const parts = String(dateString || '').trim().match(/^(\d{1,2})\/(\d{1,2})\/(\d{4})$/);
  if (!parts) {
    return null;
  }

  const day = Number(parts[1]);
  const month = Number(parts[2]);
  const year = Number(parts[3]);
  const date = new Date(year, month - 1, day);

  // Contrôle de cohérence : new Date(2026, 1, 31) donne le 03/03/2026.
  if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
    return null;
  }
  return date;
}

/**
 * Exécute une action en réessayant en cas d'erreur transitoire de l'API Drive,
 * avec un délai exponentiel.
 * @param {function()} action
 * @param {string} label Libellé utilisé dans les journaux.
 * @param {number=} attempts Nombre total de tentatives (3 par défaut).
 * @return {*} La valeur retournée par `action`.
 * @private
 */
function virementWithRetry_(action, label, attempts) {
  const maxAttempts = attempts || 3;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return action();
    } catch (e) {
      if (attempt === maxAttempts) {
        throw e;
      }
      const waitMs = Math.pow(2, attempt) * 500;
      Logger.log('    ! Échec %s (tentative %s/%s) : %s. Nouvelle tentative dans %s ms.',
          label, attempt, maxAttempts, e.message, waitMs);
      Utilities.sleep(waitMs);
    }
  }
}

/**
 * Met en forme le résumé d'exécution.
 * @param {!Object} summary
 * @return {string}
 * @private
 */
function virementFormatSummary_(summary) {
  return [
    '--- Résumé du traitement (' + summary.targetDate + ') ---',
    'Conversations analysées : ' + summary.threads,
    'E-mails correspondants  : ' + summary.matched,
    'Fichiers enregistrés    : ' + summary.saved,
    'Fichiers ignorés        : ' + summary.skipped,
    'Erreurs                 : ' + summary.errors,
    summary.stoppedEarly ? 'Traitement INCOMPLET (limite atteinte) — relancer.' : 'Traitement complet.',
    '------------------------------------------',
  ].join('\n');
}
