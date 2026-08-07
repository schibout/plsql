/**
 * @OnlyCurrentDoc
 *
 * Import unifié des pièces jointes Gmail vers Google Drive.
 *
 * Remplace 'importPrelevement.gs' (IMPORT_AVP_DK) et 'rejet_interne.gs' (REJETS_INTERNES_DK).
 * Un seul moteur, piloté par la table IMPORT_CONFIG.SOURCES : pour ajouter un nouveau flux,
 * il suffit d'ajouter une entrée dans cette table.
 *
 * Fonctions à exécuter / planifier :
 *   - import_runAll()      : traite toutes les sources activées (fonction du déclencheur).
 *   - import_listSenders() : diagnostic, liste les expéditeurs réels de chaque source.
 *   - import_showState()   : diagnostic, affiche l'état mémorisé de chaque source.
 *   - import_resetState()  : purge l'état mémorisé (force un scan complet).
 */

// --- CONFIGURATION ---
const IMPORT_CONFIG = {

  /** Profondeur de la recherche Gmail, en jours. */
  SEARCH_WINDOW_DAYS: 30,

  /**
   * Label posé sur les conversations traitées. Laisser vide pour désactiver.
   * Note : dans Apps Script un label s'applique à la CONVERSATION, pas au message. Il sert donc
   * au classement et au contrôle visuel, mais ce n'est pas lui qui empêche de relire un mail :
   * ces messages automatiques ayant un sujet identique chaque jour, Gmail peut les regrouper dans
   * une même conversation, et un filtre '-label:' rendrait le mail du lendemain invisible.
   * Le "déjà traité" repose sur l'ID de message mémorisé (voir PROCESSED_*).
   */
  PROCESSED_LABEL: 'z_traite_gdrive',

  /** Ne pas ré-enregistrer un fichier déjà présent (même nom) dans le dossier de destination. */
  SKIP_DUPLICATES: true,

  /**
   * Adresse à prévenir en cas d'anomalie (aucun fichier importé, messages rejetés,
   * dossier Drive inaccessible...). Laisser vide pour ne notifier que dans les logs.
   */
  NOTIFY_EMAIL: '',

  /** Fenêtre utilisée par import_listSenders() pour découvrir les expéditeurs. */
  DISCOVERY_WINDOW: 'newer_than:180d',

  /** Préfixe des clés d'état dans les propriétés du script. */
  STATE_KEY_PREFIX: 'IMPORT_STATE_',

  /** Marge d'élagage des ID mémorisés, au-delà de la fenêtre de recherche (en jours). */
  PROCESSED_RETENTION_MARGIN_DAYS: 7,

  /** Plafond d'ID mémorisés par source (les propriétés du script sont limitées à 9 Ko par clé). */
  MAX_PROCESSED_IDS: 500,

  SOURCES: [
    {
      /**
       * Identifiant STABLE de la source : sert de clé de persistance de l'état.
       * Ne jamais le modifier, sinon l'historique est perdu et tout est relu.
       */
      KEY: 'prelevements',

      /** Libellé d'affichage, librement modifiable. */
      NAME: 'Prélèvements',
      ENABLED: true,

      /** Dossier Drive de destination. */
      DRIVE_FOLDER_ID: '1Ihixuvehv94arFYxEm8blOxKDKqrdSjE',

      /**
       * IMPORTANT : expéditeurs autorisés. Tant que la liste est vide, la source est
       * refusée (n'importe qui peut envoyer un mail avec le bon sujet et la bonne PJ).
       * Exécutez import_listSenders() pour découvrir les expéditeurs réels.
       */
      ALLOWED_SENDERS: [],

      /** Sujet attendu. Laisser vide pour ne pas filtrer sur le sujet. */
      SUBJECT: '[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection',

      /**
       * Exiger l'égalité stricte du sujet. La recherche Gmail 'subject:' est approximative
       * (ponctuation ignorée, RE:/TR: et mails de recette inclus) : ce contrôle élimine
       * les faux positifs. Sans effet si SUBJECT est vide.
       */
      STRICT_SUBJECT: true,

      /** Seules les PJ dont le nom commence par ce texte sont importées. */
      ATTACHMENT_NAME_PREFIX: 'IMPORT_AVP_DK',

      /** Surcharge facultative du label global. Vide = on utilise IMPORT_CONFIG.PROCESSED_LABEL. */
      PROCESSED_LABEL: '',

      /**
       * Ajouter 'filename:<préfixe>' à la requête Gmail pour réduire le volume analysé.
       * Laissé à false par défaut : la recherche 'filename:' de Gmail découpe les mots et
       * pourrait manquer un fichier, ce qui provoquerait un import incomplet silencieux.
       */
      USE_FILENAME_FILTER: false,
    },
    {
      KEY: 'rejets_internes',
      NAME: 'Rejets internes',
      ENABLED: true,
      DRIVE_FOLDER_ID: '1Q0ToZKjWdH7HJt7XSA19UsKwBHD2FLG5',

      /** IMPORTANT : à renseigner (voir import_listSenders()). */
      ALLOWED_SENDERS: [],

      /** Sujet inconnu à ce stade : le filtre expéditeur + préfixe de PJ fait foi. */
      SUBJECT: '',
      STRICT_SUBJECT: false,

      ATTACHMENT_NAME_PREFIX: 'REJETS_INTERNES_DK',
      PROCESSED_LABEL: '',
      USE_FILENAME_FILTER: false,
    },
  ],
};
// --- FIN DE LA CONFIGURATION ---


/**
 * Point d'entrée : traite toutes les sources activées et produit un bilan consolidé.
 * C'est la fonction à planifier via un déclencheur.
 */
function import_runAll() {
  Logger.log('=== Début de l\'import des pièces jointes ===');

  const reports = [];
  IMPORT_CONFIG.SOURCES.forEach(source => {
    if (source.ENABLED === false) {
      Logger.log(`--- Source "${source.NAME}" désactivée, ignorée. ---`);
      return;
    }
    reports.push(import_runSource_(source));
  });

  Logger.log('=== Bilan consolidé ===');
  const anomalies = [];
  reports.forEach(report => {
    Logger.log(
      `  ${report.name} : ${report.saved} importé(s), ${report.duplicates} doublon(s), ` +
      `${report.alreadyProcessed} déjà traité(s), ${report.labeled} conversation(s) labellisée(s), ` +
      `${report.rejectedSender} rejet(s) expéditeur, ${report.rejectedSubject} rejet(s) sujet.`
    );
    report.errors.forEach(error => anomalies.push(`[${report.name}] ${error}`));

    // Un message au bon sujet mais du mauvais expéditeur signale soit un changement
    // légitime d'émetteur (à répercuter dans la config, sinon l'import s'arrête
    // silencieusement), soit une tentative d'usurpation. Dans les deux cas, il faut le voir.
    if (report.saved === 0 && (report.rejectedSender > 0 || report.rejectedSubject > 0)) {
      anomalies.push(
        `[${report.name}] Aucun fichier importé alors que ` +
        `${report.rejectedSender + report.rejectedSubject} message(s) ont été rejetés. ` +
        `Vérifiez ALLOWED_SENDERS et SUBJECT.`
      );
    }
  });
  Logger.log('=======================');

  if (anomalies.length > 0) {
    import_alert_('Import des pièces jointes : anomalies détectées', anomalies.join('\n'));
  }
}


/**
 * Traite une source : recherche les messages, contrôle l'expéditeur et le sujet,
 * enregistre les pièces jointes correspondantes sur Drive, mémorise les messages traités
 * et pose le label sur les conversations concernées.
 * @param {Object} source Une entrée de IMPORT_CONFIG.SOURCES.
 * @return {Object} Le bilan de la source (compteurs et erreurs).
 */
function import_runSource_(source) {
  const report = {
    name: source.NAME,
    saved: 0,
    duplicates: 0,
    alreadyProcessed: 0,
    labeled: 0,
    rejectedSender: 0,
    rejectedSubject: 0,
    errors: [],
  };

  Logger.log(`--- Source "${source.NAME}" ---`);

  if (!source.KEY) {
    report.errors.push("La source n'a pas de KEY : identifiant de persistance manquant.");
    Logger.log(`  ERREUR : ${report.errors[report.errors.length - 1]}`);
    return report;
  }

  if (!source.DRIVE_FOLDER_ID) {
    report.errors.push("L'ID du dossier Google Drive (DRIVE_FOLDER_ID) n'est pas configuré.");
    Logger.log(`  ERREUR : ${report.errors[report.errors.length - 1]}`);
    return report;
  }

  const allowedSenders = import_normalizeSenders_(source.ALLOWED_SENDERS);
  if (allowedSenders.length === 0) {
    report.errors.push(
      "Aucun expéditeur autorisé (ALLOWED_SENDERS vide) : source ignorée. " +
      "Exécutez import_listSenders() pour identifier les expéditeurs légitimes."
    );
    Logger.log(`  ERREUR : ${report.errors[report.errors.length - 1]}`);
    return report;
  }

  const state = import_loadState_(source);

  try {
    const destinationFolder = DriveApp.getFolderById(source.DRIVE_FOLDER_ID);
    const query = import_buildQuery_(source, allowedSenders, state);
    const labelName = source.PROCESSED_LABEL || IMPORT_CONFIG.PROCESSED_LABEL;
    const processedLabel = labelName ? import_getOrCreateLabel_(labelName) : null;

    Logger.log(`  Destination : "${destinationFolder.getName()}"`);
    Logger.log(`  Dernière exécution : ${state.lastRunIso || 'jamais'}`);
    Logger.log(`  Requête : ${query}`);
    if (labelName && !processedLabel) {
      report.errors.push(`Le label "${labelName}" est inaccessible : les conversations ne seront pas marquées.`);
    }

    const threads = GmailApp.search(query);
    Logger.log(`  ${threads.length} conversation(s) trouvée(s).`);

    threads.forEach(thread => {
      let threadHandled = false;

      thread.getMessages().forEach(message => {
        if (message.isInTrash() || message.isDraft()) return;

        // Contrôle 0 : message déjà traité lors d'une exécution précédente.
        // Ce test se fait sur l'ID du MESSAGE (et non sur le label, qui est porté par la
        // conversation) : un nouveau message arrivé dans une conversation déjà labellisée
        // est donc bien traité. Il précède les appels à Drive, qui sont les plus coûteux.
        const messageId = message.getId();
        if (state.processed[messageId]) {
          report.alreadyProcessed++;
          return;
        }

        // Contrôle 1 : l'adresse réelle de l'expéditeur, et non le nom d'affichage.
        // GmailApp.search('from:') matche aussi le nom affiché : un expéditeur externe
        // qui se nomme "cashcollection@dalkia.fr" passerait le filtre de la requête.
        const sender = import_extractEmail_(message.getFrom());
        if (allowedSenders.indexOf(sender) === -1) {
          report.rejectedSender++;
          Logger.log(`  REJETÉ (expéditeur) : "${sender}" — sujet "${message.getSubject()}".`);
          return;
        }

        // Contrôle 2 : le sujet exact, la recherche Gmail 'subject:' étant approximative.
        const subject = message.getSubject();
        if (source.SUBJECT && source.STRICT_SUBJECT && subject.trim() !== source.SUBJECT) {
          report.rejectedSubject++;
          Logger.log(`  REJETÉ (sujet) : "${subject}" — expéditeur ${sender}.`);
          return;
        }

        let messageComplete = true;

        message.getAttachments().forEach(attachment => {
          const fileName = attachment.getName();
          if (!fileName.startsWith(source.ATTACHMENT_NAME_PREFIX)) return;

          Logger.log(`  Pièce jointe trouvée : "${fileName}" (de ${sender}).`);

          try {
            if (IMPORT_CONFIG.SKIP_DUPLICATES && destinationFolder.getFilesByName(fileName).hasNext()) {
              report.duplicates++;
              Logger.log(`    -> Déjà présent dans le dossier. Ignoré.`);
              return;
            }

            destinationFolder.createFile(attachment.copyBlob());
            report.saved++;
            Logger.log(`    -> SUCCÈS : sauvegardé dans "${destinationFolder.getName()}".`);
          } catch (e) {
            // Le message ne sera pas mémorisé : la prochaine exécution réessaiera cette PJ,
            // et le contrôle des doublons empêchera de ré-importer celles déjà passées.
            messageComplete = false;
            report.errors.push(`Échec de l'import de "${fileName}" : ${e.message}`);
            Logger.log(`    -> ERREUR : ${e.message}`);
          }
        });

        if (messageComplete) {
          state.processed[messageId] = import_messageTime_(message);
          threadHandled = true;
        }
      });

      if (threadHandled && processedLabel) {
        try {
          thread.addLabel(processedLabel);
          report.labeled++;
        } catch (e) {
          // L'import a réussi : un échec de labellisation ne doit pas le remettre en cause.
          report.errors.push(`Label non appliqué à une conversation : ${e.message}`);
          Logger.log(`  ! Label non appliqué : ${e.message}`);
        }
      }
    });

  } catch (e) {
    // Une source en erreur ne doit pas empêcher les autres de s'exécuter.
    report.errors.push(`Erreur durant le traitement : ${e.message}`);
    Logger.log(`  ERREUR CRITIQUE : ${e.message}`);
    Logger.log(`  Stack trace: ${e.stack}`);
  }

  // Les ID traités sont toujours enregistrés (le travail effectué ne doit pas être refait),
  // mais la date de dernière exécution n'avance qu'en l'absence d'erreur : en cas d'incident,
  // la plage reste couverte par la prochaine recherche.
  if (report.errors.length === 0) {
    state.lastRunIso = new Date().toISOString();
  }
  import_saveState_(source, state);

  return report;
}


/**
 * Outil de diagnostic : pour chaque source, liste les expéditeurs réels des messages
 * portant une pièce jointe au bon préfixe, avec le nombre de messages.
 * À exécuter une fois pour renseigner les ALLOWED_SENDERS.
 */
function import_listSenders() {
  IMPORT_CONFIG.SOURCES.forEach(source => {
    Logger.log(`--- Expéditeurs pour "${source.NAME}" ---`);

    const clauses = ['has:attachment', IMPORT_CONFIG.DISCOVERY_WINDOW];
    if (source.SUBJECT) clauses.push(`subject:("${source.SUBJECT}")`);
    else clauses.push(`filename:${source.ATTACHMENT_NAME_PREFIX}`);
    const query = clauses.join(' ');
    Logger.log(`  Requête : ${query}`);

    const counts = {};
    try {
      GmailApp.search(query).forEach(thread => {
        thread.getMessages().forEach(message => {
          if (message.isInTrash() || message.isDraft()) return;
          // On ne retient que les messages portant réellement la PJ attendue.
          const hasAttachment = message.getAttachments().some(
            attachment => attachment.getName().startsWith(source.ATTACHMENT_NAME_PREFIX)
          );
          if (!hasAttachment) return;
          const sender = import_extractEmail_(message.getFrom());
          counts[sender] = (counts[sender] || 0) + 1;
        });
      });
    } catch (e) {
      Logger.log(`  ERREUR : ${e.message}`);
      return;
    }

    const senders = Object.keys(counts);
    if (senders.length === 0) {
      Logger.log('  Aucun message trouvé sur la période.');
      return;
    }
    senders
      .sort((a, b) => counts[b] - counts[a])
      .forEach(sender => Logger.log(`  ${sender} : ${counts[sender]} message(s)`));
    Logger.log('  Reportez le(s) expéditeur(s) légitime(s) dans ALLOWED_SENDERS.');
  });
}


/**
 * Outil de diagnostic : affiche l'état mémorisé de chaque source.
 */
function import_showState() {
  IMPORT_CONFIG.SOURCES.forEach(source => {
    const state = import_loadState_(source);
    const count = Object.keys(state.processed).length;
    Logger.log(
      `${source.NAME} (${source.KEY}) : dernière exécution = ${state.lastRunIso || 'jamais'}, ` +
      `${count} message(s) mémorisé(s).`
    );
  });
}


/**
 * Outil de maintenance : purge l'état mémorisé de toutes les sources.
 * La prochaine exécution rescannera toute la fenêtre de recherche. Sans danger : le contrôle
 * des doublons empêche de ré-importer un fichier déjà présent sur Drive.
 */
function import_resetState() {
  const properties = PropertiesService.getScriptProperties();
  IMPORT_CONFIG.SOURCES.forEach(source => {
    properties.deleteProperty(import_stateKey_(source));
    Logger.log(`État purgé pour "${source.NAME}" (${source.KEY}).`);
  });
}


/**
 * Construit la requête Gmail d'une source.
 * @param {Object} source Une entrée de IMPORT_CONFIG.SOURCES.
 * @param {string[]} allowedSenders Les expéditeurs autorisés, normalisés.
 * @param {Object} state L'état mémorisé de la source.
 * @return {string} La requête de recherche.
 */
function import_buildQuery_(source, allowedSenders, state) {
  // La syntaxe {a b} signifie 'a OU b'. Ce filtre est une première barrière : il porte
  // aussi sur le nom d'affichage, donc l'adresse réelle est revérifiée à la lecture.
  const clauses = [
    `from:{${allowedSenders.join(' ')}}`,
    'has:attachment',
    `after:${import_searchStartDate_(state)}`,
  ];
  if (source.SUBJECT) clauses.push(`subject:("${source.SUBJECT}")`);
  if (source.USE_FILENAME_FILTER) clauses.push(`filename:${source.ATTACHMENT_NAME_PREFIX}`);
  return clauses.join(' ');
}


/**
 * Calcule la date de début de recherche, au format attendu par l'opérateur Gmail 'after:'.
 * On retient la PLUS ANCIENNE des deux bornes : la fenêtre nominale reste donc d'au moins
 * SEARCH_WINDOW_DAYS jours, et s'élargit automatiquement si le déclencheur est resté en panne
 * plus longtemps que cette fenêtre.
 * @param {Object} state L'état mémorisé de la source.
 * @return {string} La date au format 'yyyy/MM/dd'.
 */
function import_searchStartDate_(state) {
  const dayMs = 24 * 60 * 60 * 1000;
  let start = Date.now() - IMPORT_CONFIG.SEARCH_WINDOW_DAYS * dayMs;

  if (state.lastRunIso) {
    // 'after:' a une granularité au jour : on recule d'un jour pour absorber les fuseaux.
    const lastRun = new Date(state.lastRunIso).getTime() - dayMs;
    if (!isNaN(lastRun) && lastRun < start) start = lastRun;
  }

  return Utilities.formatDate(new Date(start), Session.getScriptTimeZone(), 'yyyy/MM/dd');
}


/**
 * Clé de persistance d'une source.
 * @param {Object} source Une entrée de IMPORT_CONFIG.SOURCES.
 * @return {string} La clé de propriété.
 */
function import_stateKey_(source) {
  return IMPORT_CONFIG.STATE_KEY_PREFIX + source.KEY;
}


/**
 * Lit l'état mémorisé d'une source. Un état absent ou corrompu ne doit jamais bloquer
 * l'import : on repart alors d'un état vierge.
 * @param {Object} source Une entrée de IMPORT_CONFIG.SOURCES.
 * @return {{lastRunIso: ?string, processed: Object}} L'état de la source.
 */
function import_loadState_(source) {
  const empty = { lastRunIso: null, processed: {} };
  try {
    const raw = PropertiesService.getScriptProperties().getProperty(import_stateKey_(source));
    if (!raw) return empty;
    const parsed = JSON.parse(raw);
    return {
      lastRunIso: parsed.lastRunIso || null,
      processed: parsed.processed || {},
    };
  } catch (e) {
    Logger.log(`  ! État illisible pour "${source.NAME}", repart de zéro : ${e.message}`);
    return empty;
  }
}


/**
 * Enregistre l'état d'une source, après élagage des ID de messages devenus inutiles
 * (hors fenêtre de recherche, ou au-delà du plafond) : les propriétés du script sont
 * limitées à 9 Ko par clé.
 * @param {Object} source Une entrée de IMPORT_CONFIG.SOURCES.
 * @param {Object} state L'état à enregistrer.
 */
function import_saveState_(source, state) {
  const dayMs = 24 * 60 * 60 * 1000;
  const retentionDays = IMPORT_CONFIG.SEARCH_WINDOW_DAYS + IMPORT_CONFIG.PROCESSED_RETENTION_MARGIN_DAYS;
  const cutoff = Date.now() - retentionDays * dayMs;

  // Du plus récent au plus ancien, on ne garde que ce qui reste utile.
  const kept = {};
  Object.keys(state.processed)
    .filter(id => state.processed[id] >= cutoff)
    .sort((a, b) => state.processed[b] - state.processed[a])
    .slice(0, IMPORT_CONFIG.MAX_PROCESSED_IDS)
    .forEach(id => { kept[id] = state.processed[id]; });

  try {
    PropertiesService.getScriptProperties().setProperty(
      import_stateKey_(source),
      JSON.stringify({ lastRunIso: state.lastRunIso, processed: kept })
    );
  } catch (e) {
    // Sans état, la prochaine exécution relira les mails : coûteux, mais pas faux
    // (le contrôle des doublons reste le filet de sécurité).
    Logger.log(`  ! État non enregistré pour "${source.NAME}" : ${e.message}`);
  }
}


/**
 * Date d'un message en millisecondes, avec repli sur l'instant courant si elle est indisponible.
 * @param {GmailMessage} message Le message.
 * @return {number} L'horodatage en millisecondes.
 */
function import_messageTime_(message) {
  try {
    const date = message.getDate();
    if (date) return date.getTime();
  } catch (e) {
    // Repli ci-dessous.
  }
  return Date.now();
}


/**
 * Récupère ou crée un label Gmail.
 * @param {string} name Le nom du label.
 * @return {?GmailLabel} Le label, ou null s'il est inaccessible.
 */
function import_getOrCreateLabel_(name) {
  try {
    let label = GmailApp.getUserLabelByName(name);
    if (!label) {
      label = GmailApp.createLabel(name);
      Logger.log(`  Label Gmail "${name}" créé.`);
    }
    return label;
  } catch (e) {
    Logger.log(`  ! Label "${name}" inaccessible : ${e.message}`);
    return null;
  }
}


/**
 * Normalise une liste d'adresses (minuscules, sans espaces, sans entrées vides).
 * @param {string[]} senders Les adresses brutes.
 * @return {string[]} Les adresses normalisées.
 */
function import_normalizeSenders_(senders) {
  return (senders || [])
    .filter(sender => typeof sender === 'string')
    .map(sender => sender.trim().toLowerCase())
    .filter(sender => sender !== '');
}


/**
 * Extrait l'adresse d'un en-tête 'From' de la forme 'Nom <adresse@domaine>'.
 * @param {string} from La valeur brute retournée par GmailMessage.getFrom().
 * @return {string} L'adresse en minuscules.
 */
function import_extractEmail_(from) {
  const match = /<([^>]+)>/.exec(from || '');
  return (match ? match[1] : (from || '')).trim().toLowerCase();
}


/**
 * Signale une anomalie : journal, e-mail si NOTIFY_EMAIL est renseigné, alerte UI sinon.
 * @param {string} subject L'objet de l'alerte.
 * @param {string} body Le détail de l'alerte.
 */
function import_alert_(subject, body) {
  Logger.log(`ALERTE — ${subject}\n${body}`);

  if (IMPORT_CONFIG.NOTIFY_EMAIL) {
    try {
      MailApp.sendEmail(IMPORT_CONFIG.NOTIFY_EMAIL, subject, body);
      return;
    } catch (e) {
      Logger.log(`Échec de l'envoi de l'alerte par e-mail : ${e.message}`);
    }
  }

  try {
    SpreadsheetApp.getUi().alert(`${subject}\n\n${body}`);
  } catch (e) {
    // Aucune UI disponible (exécution par déclencheur) : le journal suffit.
  }
}
