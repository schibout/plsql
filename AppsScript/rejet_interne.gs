/**
 * @OnlyCurrentDoc
 *
 * Récupération des pièces jointes 'REJETS_INTERNES_DK.xxxxxx.csv' depuis Gmail
 * et sauvegarde dans un dossier Google Drive.
 *
 * Script AUTONOME : il n'a besoin d'aucun autre fichier. Si vous l'installez dans le même
 * projet Apps Script que 'importPiecesJointes.gs', ne planifiez QU'UNE SEULE des deux
 * fonctions — les deux écrivent dans le même dossier Drive et posent le même label, avec
 * chacune son propre état, ce qui ferait le travail en double.
 *
 * Fonctions à exécuter / planifier :
 *   - rejeter_processAttachments() : traitement (fonction du déclencheur).
 *   - rejeter_listSenders()        : diagnostic, liste les expéditeurs réels.
 *   - rejeter_showState()          : diagnostic, affiche l'état mémorisé.
 *   - rejeter_resetState()         : purge l'état mémorisé (force un scan complet).
 */

// --- CONFIGURATION ---
const REJETS_CONFIG = {
  // IMPORTANT : ID du dossier Google Drive où les pièces jointes seront sauvegardées.
  // Pour trouver l'ID : ouvrez le dossier dans Drive, l'ID est la partie finale de l'URL.
  DRIVE_FOLDER_ID: '1Q0ToZKjWdH7HJt7XSA19UsKwBHD2FLG5',

  // IMPORTANT : adresse(s) e-mail autorisée(s) à fournir les fichiers de rejets.
  // Tant que cette liste est vide, aucun import n'est réalisé : sans ce filtre, n'importe
  // quel e-mail portant une pièce jointe au bon nom alimenterait le dossier.
  // Exécutez 'rejeter_listSenders' pour découvrir les expéditeurs réels.
  ALLOWED_SENDERS: [],

  // Préfixe du nom des pièces jointes à rechercher.
  ATTACHMENT_NAME_PREFIX: 'REJETS_INTERNES_DK',

  // Sujet attendu. Laisser vide pour ne pas filtrer sur le sujet : le filtre expéditeur
  // et le préfixe de pièce jointe font alors foi.
  SUBJECT: '',

  // Exiger l'égalité stricte du sujet. La recherche Gmail 'subject:' est approximative
  // (ponctuation ignorée, RE:/TR: et mails de recette inclus) : ce contrôle élimine les
  // faux positifs. Sans effet si SUBJECT est vide.
  STRICT_SUBJECT: false,

  // Profondeur de la recherche Gmail, en jours.
  SEARCH_WINDOW_DAYS: 30,

  // Label posé sur les conversations traitées. Laisser vide pour désactiver.
  // Note : dans Apps Script un label s'applique à la CONVERSATION, pas au message. Il sert
  // donc au classement et au contrôle visuel, mais ce n'est pas lui qui empêche de relire
  // un mail : ces messages automatiques ayant un sujet répétitif, Gmail peut les regrouper
  // dans une même conversation, et un filtre '-label:' rendrait le mail suivant invisible.
  // Le "déjà traité" repose sur l'ID de message mémorisé.
  PROCESSED_LABEL: 'z_traite_gdrive',

  // Faut-il ignorer les fichiers déjà présents dans le dossier de destination ?
  SKIP_DUPLICATES: true,

  // Adresse à prévenir en cas d'anomalie. Laisser vide pour ne notifier que dans les logs.
  NOTIFY_EMAIL: '',

  // Fenêtre utilisée par rejeter_listSenders() pour découvrir les expéditeurs.
  DISCOVERY_WINDOW: 'newer_than:180d',

  // Clé de persistance de l'état dans les propriétés du script. Ne pas la modifier :
  // un changement efface l'historique et provoque une relecture complète.
  STATE_KEY: 'REJETS_INTERNES_STATE',

  // Marge d'élagage des ID mémorisés, au-delà de la fenêtre de recherche (en jours).
  PROCESSED_RETENTION_MARGIN_DAYS: 7,

  // Plafond d'ID mémorisés (les propriétés du script sont limitées à 9 Ko par clé).
  MAX_PROCESSED_IDS: 500,
};
// --- FIN DE LA CONFIGURATION ---


/**
 * Fonction principale : recherche les e-mails autorisés, extrait les pièces jointes
 * correspondantes, les sauvegarde sur Drive, mémorise les messages traités et pose le label.
 */
function rejeter_processAttachments() {
  Logger.log('--- Début de l\'import des rejets internes ---');

  const report = {
    saved: 0,
    duplicates: 0,
    alreadyProcessed: 0,
    labeled: 0,
    rejectedSender: 0,
    rejectedSubject: 0,
    errors: [],
  };

  if (!REJETS_CONFIG.DRIVE_FOLDER_ID) {
    rejeter_alert_(
      'Rejets internes : configuration incomplète',
      "L'ID du dossier Google Drive n'est pas configuré dans 'REJETS_CONFIG.DRIVE_FOLDER_ID'."
    );
    return;
  }

  const allowedSenders = rejeter_normalizeSenders_(REJETS_CONFIG.ALLOWED_SENDERS);
  if (allowedSenders.length === 0) {
    rejeter_alert_(
      'Rejets internes : configuration incomplète',
      "Aucun expéditeur autorisé dans 'REJETS_CONFIG.ALLOWED_SENDERS' : import annulé. " +
      "Exécutez 'rejeter_listSenders' pour identifier les expéditeurs légitimes, puis renseignez la liste."
    );
    return;
  }

  const state = rejeter_loadState_();

  try {
    const destinationFolder = DriveApp.getFolderById(REJETS_CONFIG.DRIVE_FOLDER_ID);
    const query = rejeter_buildQuery_(allowedSenders, state);
    const processedLabel = REJETS_CONFIG.PROCESSED_LABEL
      ? rejeter_getOrCreateLabel_(REJETS_CONFIG.PROCESSED_LABEL)
      : null;

    Logger.log(`Destination : "${destinationFolder.getName()}"`);
    Logger.log(`Dernière exécution : ${state.lastRunIso || 'jamais'}`);
    Logger.log(`Requête : ${query}`);
    if (REJETS_CONFIG.PROCESSED_LABEL && !processedLabel) {
      report.errors.push(
        `Le label "${REJETS_CONFIG.PROCESSED_LABEL}" est inaccessible : les conversations ne seront pas marquées.`
      );
    }

    const threads = GmailApp.search(query);
    Logger.log(`${threads.length} conversation(s) trouvée(s).`);

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
        // qui se nomme comme l'émetteur légitime passerait le filtre de la requête.
        const sender = rejeter_extractEmail_(message.getFrom());
        if (allowedSenders.indexOf(sender) === -1) {
          report.rejectedSender++;
          Logger.log(`REJETÉ (expéditeur) : "${sender}" — sujet "${message.getSubject()}".`);
          return;
        }

        // Contrôle 2 : le sujet exact, la recherche Gmail 'subject:' étant approximative.
        const subject = message.getSubject();
        if (REJETS_CONFIG.SUBJECT && REJETS_CONFIG.STRICT_SUBJECT && subject.trim() !== REJETS_CONFIG.SUBJECT) {
          report.rejectedSubject++;
          Logger.log(`REJETÉ (sujet) : "${subject}" — expéditeur ${sender}.`);
          return;
        }

        let messageComplete = true;

        message.getAttachments().forEach(attachment => {
          const fileName = attachment.getName();
          if (!fileName.startsWith(REJETS_CONFIG.ATTACHMENT_NAME_PREFIX)) return;

          Logger.log(`Pièce jointe trouvée : "${fileName}" (de ${sender}).`);

          try {
            if (REJETS_CONFIG.SKIP_DUPLICATES && destinationFolder.getFilesByName(fileName).hasNext()) {
              report.duplicates++;
              Logger.log(`  -> Déjà présent dans le dossier. Ignoré.`);
              return;
            }

            destinationFolder.createFile(attachment.copyBlob());
            report.saved++;
            Logger.log(`  -> SUCCÈS : sauvegardé dans "${destinationFolder.getName()}".`);
          } catch (e) {
            // Le message ne sera pas mémorisé : la prochaine exécution réessaiera cette PJ,
            // et le contrôle des doublons empêchera de ré-importer celles déjà passées.
            messageComplete = false;
            report.errors.push(`Échec de l'import de "${fileName}" : ${e.message}`);
            Logger.log(`  -> ERREUR : ${e.message}`);
          }
        });

        if (messageComplete) {
          state.processed[messageId] = rejeter_messageTime_(message);
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
          Logger.log(`! Label non appliqué : ${e.message}`);
        }
      }
    });

  } catch (e) {
    report.errors.push(`Erreur durant le traitement : ${e.message}`);
    Logger.log(`ERREUR CRITIQUE : ${e.message}`);
    Logger.log(`Stack trace: ${e.stack}`);
  }

  // Les ID traités sont toujours enregistrés (le travail effectué ne doit pas être refait),
  // mais la date de dernière exécution n'avance qu'en l'absence d'erreur : en cas d'incident,
  // la plage reste couverte par la prochaine recherche.
  if (report.errors.length === 0) {
    state.lastRunIso = new Date().toISOString();
  }
  rejeter_saveState_(state);

  Logger.log('--- Bilan de l\'exécution ---');
  Logger.log(
    `${report.saved} importé(s), ${report.duplicates} doublon(s), ` +
    `${report.alreadyProcessed} déjà traité(s), ${report.labeled} conversation(s) labellisée(s), ` +
    `${report.rejectedSender} rejet(s) expéditeur, ${report.rejectedSubject} rejet(s) sujet.`
  );
  Logger.log('----------------------------');

  // Un message rejeté signale soit un changement légitime d'émetteur (à répercuter dans la
  // config, sinon l'import s'arrête silencieusement), soit une tentative d'usurpation.
  const anomalies = report.errors.slice();
  if (report.saved === 0 && (report.rejectedSender > 0 || report.rejectedSubject > 0)) {
    anomalies.push(
      `Aucun fichier importé alors que ${report.rejectedSender + report.rejectedSubject} ` +
      `message(s) ont été rejetés. Vérifiez ALLOWED_SENDERS et SUBJECT.`
    );
  }
  if (anomalies.length > 0) {
    rejeter_alert_('Rejets internes : anomalies détectées', anomalies.join('\n'));
  }
}


/**
 * Outil de diagnostic : liste les expéditeurs réels des messages portant une pièce jointe
 * au bon préfixe. À exécuter une fois pour renseigner REJETS_CONFIG.ALLOWED_SENDERS.
 */
function rejeter_listSenders() {
  const clauses = ['has:attachment', REJETS_CONFIG.DISCOVERY_WINDOW];
  if (REJETS_CONFIG.SUBJECT) clauses.push(`subject:("${REJETS_CONFIG.SUBJECT}")`);
  else clauses.push(`filename:${REJETS_CONFIG.ATTACHMENT_NAME_PREFIX}`);
  const query = clauses.join(' ');
  Logger.log(`Requête : ${query}`);

  const counts = {};
  try {
    GmailApp.search(query).forEach(thread => {
      thread.getMessages().forEach(message => {
        if (message.isInTrash() || message.isDraft()) return;
        // On ne retient que les messages portant réellement la PJ attendue.
        const hasAttachment = message.getAttachments().some(
          attachment => attachment.getName().startsWith(REJETS_CONFIG.ATTACHMENT_NAME_PREFIX)
        );
        if (!hasAttachment) return;
        const sender = rejeter_extractEmail_(message.getFrom());
        counts[sender] = (counts[sender] || 0) + 1;
      });
    });
  } catch (e) {
    Logger.log(`ERREUR : ${e.message}`);
    return;
  }

  const senders = Object.keys(counts);
  if (senders.length === 0) {
    Logger.log('Aucun message trouvé sur la période.');
    return;
  }
  senders
    .sort((a, b) => counts[b] - counts[a])
    .forEach(sender => Logger.log(`  ${sender} : ${counts[sender]} message(s)`));
  Logger.log("Reportez le(s) expéditeur(s) légitime(s) dans REJETS_CONFIG.ALLOWED_SENDERS.");
}


/**
 * Outil de diagnostic : affiche l'état mémorisé.
 */
function rejeter_showState() {
  const state = rejeter_loadState_();
  Logger.log(
    `Rejets internes : dernière exécution = ${state.lastRunIso || 'jamais'}, ` +
    `${Object.keys(state.processed).length} message(s) mémorisé(s).`
  );
}


/**
 * Outil de maintenance : purge l'état mémorisé.
 * La prochaine exécution rescannera toute la fenêtre de recherche. Sans danger : le contrôle
 * des doublons empêche de ré-importer un fichier déjà présent sur Drive.
 */
function rejeter_resetState() {
  PropertiesService.getScriptProperties().deleteProperty(REJETS_CONFIG.STATE_KEY);
  Logger.log('État purgé pour les rejets internes.');
}


/**
 * Construit la requête Gmail.
 * @param {string[]} allowedSenders Les expéditeurs autorisés, normalisés.
 * @param {Object} state L'état mémorisé.
 * @return {string} La requête de recherche.
 */
function rejeter_buildQuery_(allowedSenders, state) {
  // La syntaxe {a b} signifie 'a OU b'. Ce filtre est une première barrière : il porte
  // aussi sur le nom d'affichage, donc l'adresse réelle est revérifiée à la lecture.
  const clauses = [
    `from:{${allowedSenders.join(' ')}}`,
    'has:attachment',
    `after:${rejeter_searchStartDate_(state)}`,
  ];
  if (REJETS_CONFIG.SUBJECT) clauses.push(`subject:("${REJETS_CONFIG.SUBJECT}")`);
  return clauses.join(' ');
}


/**
 * Calcule la date de début de recherche, au format attendu par l'opérateur Gmail 'after:'.
 * On retient la PLUS ANCIENNE des deux bornes : la fenêtre nominale reste donc d'au moins
 * SEARCH_WINDOW_DAYS jours, et s'élargit automatiquement si le déclencheur est resté en panne
 * plus longtemps que cette fenêtre.
 * @param {Object} state L'état mémorisé.
 * @return {string} La date au format 'yyyy/MM/dd'.
 */
function rejeter_searchStartDate_(state) {
  const dayMs = 24 * 60 * 60 * 1000;
  let start = Date.now() - REJETS_CONFIG.SEARCH_WINDOW_DAYS * dayMs;

  if (state.lastRunIso) {
    // 'after:' a une granularité au jour : on recule d'un jour pour absorber les fuseaux.
    const lastRun = new Date(state.lastRunIso).getTime() - dayMs;
    if (!isNaN(lastRun) && lastRun < start) start = lastRun;
  }

  return Utilities.formatDate(new Date(start), Session.getScriptTimeZone(), 'yyyy/MM/dd');
}


/**
 * Lit l'état mémorisé. Un état absent ou corrompu ne doit jamais bloquer l'import :
 * on repart alors d'un état vierge.
 * @return {{lastRunIso: ?string, processed: Object}} L'état.
 */
function rejeter_loadState_() {
  const empty = { lastRunIso: null, processed: {} };
  try {
    const raw = PropertiesService.getScriptProperties().getProperty(REJETS_CONFIG.STATE_KEY);
    if (!raw) return empty;
    const parsed = JSON.parse(raw);
    return {
      lastRunIso: parsed.lastRunIso || null,
      processed: parsed.processed || {},
    };
  } catch (e) {
    Logger.log(`! État illisible, repart de zéro : ${e.message}`);
    return empty;
  }
}


/**
 * Enregistre l'état, après élagage des ID de messages devenus inutiles (hors fenêtre de
 * recherche, ou au-delà du plafond) : les propriétés du script sont limitées à 9 Ko par clé.
 * @param {Object} state L'état à enregistrer.
 */
function rejeter_saveState_(state) {
  const dayMs = 24 * 60 * 60 * 1000;
  const retentionDays = REJETS_CONFIG.SEARCH_WINDOW_DAYS + REJETS_CONFIG.PROCESSED_RETENTION_MARGIN_DAYS;
  const cutoff = Date.now() - retentionDays * dayMs;

  // Du plus récent au plus ancien, on ne garde que ce qui reste utile.
  const kept = {};
  Object.keys(state.processed)
    .filter(id => state.processed[id] >= cutoff)
    .sort((a, b) => state.processed[b] - state.processed[a])
    .slice(0, REJETS_CONFIG.MAX_PROCESSED_IDS)
    .forEach(id => { kept[id] = state.processed[id]; });

  try {
    PropertiesService.getScriptProperties().setProperty(
      REJETS_CONFIG.STATE_KEY,
      JSON.stringify({ lastRunIso: state.lastRunIso, processed: kept })
    );
  } catch (e) {
    // Sans état, la prochaine exécution relira les mails : coûteux, mais pas faux
    // (le contrôle des doublons reste le filet de sécurité).
    Logger.log(`! État non enregistré : ${e.message}`);
  }
}


/**
 * Date d'un message en millisecondes, avec repli sur l'instant courant si elle est indisponible.
 * @param {GmailMessage} message Le message.
 * @return {number} L'horodatage en millisecondes.
 */
function rejeter_messageTime_(message) {
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
function rejeter_getOrCreateLabel_(name) {
  try {
    let label = GmailApp.getUserLabelByName(name);
    if (!label) {
      label = GmailApp.createLabel(name);
      Logger.log(`Label Gmail "${name}" créé.`);
    }
    return label;
  } catch (e) {
    Logger.log(`! Label "${name}" inaccessible : ${e.message}`);
    return null;
  }
}


/**
 * Normalise une liste d'adresses (minuscules, sans espaces, sans entrées vides).
 * @param {string[]} senders Les adresses brutes.
 * @return {string[]} Les adresses normalisées.
 */
function rejeter_normalizeSenders_(senders) {
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
function rejeter_extractEmail_(from) {
  const match = /<([^>]+)>/.exec(from || '');
  return (match ? match[1] : (from || '')).trim().toLowerCase();
}


/**
 * Signale une anomalie : journal, e-mail si NOTIFY_EMAIL est renseigné, alerte UI sinon.
 * @param {string} subject L'objet de l'alerte.
 * @param {string} body Le détail de l'alerte.
 */
function rejeter_alert_(subject, body) {
  Logger.log(`ALERTE — ${subject}\n${body}`);

  if (REJETS_CONFIG.NOTIFY_EMAIL) {
    try {
      MailApp.sendEmail(REJETS_CONFIG.NOTIFY_EMAIL, subject, body);
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
