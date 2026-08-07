/**
 * @OnlyCurrentDoc
 *
 * Ce script automatise la récupération des pièces jointes 'IMPORT_AVP_DK'
 * depuis les e-mails de synthèse des prélèvements et leur sauvegarde sur Google Drive.
 */

// --- CONFIGURATION ---
// Préfixé pour éviter les conflits de nom dans l'espace de noms global d'Apps Script.
const PRELEVEMENT_CONFIG = {
  // IMPORTANT : ID du dossier Google Drive où les pièces jointes seront sauvegardées.
  // Pour trouver l'ID : ouvrez le dossier dans Drive, l'ID est la partie finale de l'URL.
  DRIVE_FOLDER_ID: '1Ihixuvehv94arFYxEm8blOxKDKqrdSjE',

  // IMPORTANT : adresse(s) e-mail autorisée(s) à fournir les fichiers de prélèvements.
  // Tant que cette liste est vide, aucun import n'est réalisé (protection contre
  // l'usurpation : n'importe qui peut envoyer un mail avec le bon sujet).
  // Exécutez 'prelevement_listSenders' pour découvrir les expéditeurs réels.
  ALLOWED_SENDERS: [],

  // Préfixe du nom des pièces jointes à rechercher.
  ATTACHMENT_NAME_PREFIX: 'IMPORT_AVP_DK',

  // Sujet exact de l'e-mail à rechercher.
  EMAIL_SUBJECT: '[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection',

  // Le sujet du message doit-il correspondre exactement à EMAIL_SUBJECT ?
  // La recherche Gmail 'subject:' est approximative (ponctuation ignorée, RE:/TR: inclus) :
  // ce contrôle élimine les faux positifs (mails de recette, réponses, transferts).
  STRICT_SUBJECT: true,

  // Faut-il ignorer les fichiers déjà présents dans le dossier de destination ?
  SKIP_DUPLICATES: true,
};
// --- FIN DE LA CONFIGURATION ---


/**
 * Fonction principale pour importer les pièces jointes des prélèvements.
 * À exécuter manuellement ou via un déclencheur.
 */
function prelevement_importAttachments() {
  // Vérification de la configuration
  if (!PRELEVEMENT_CONFIG.DRIVE_FOLDER_ID) {
    prelevement_fail_("ERREUR : L'ID du dossier Google Drive n'est pas configuré dans la variable 'PRELEVEMENT_CONFIG.DRIVE_FOLDER_ID'.");
    return;
  }

  const allowedSenders = prelevement_allowedSenders_();
  if (allowedSenders.length === 0) {
    prelevement_fail_("ERREUR : aucun expéditeur autorisé dans 'PRELEVEMENT_CONFIG.ALLOWED_SENDERS'. Import annulé. Exécutez 'prelevement_listSenders' pour identifier les expéditeurs légitimes, puis renseignez la liste.");
    return;
  }

  // Construction de la requête de recherche Gmail.
  // La syntaxe {a b} signifie 'a OU b'. Ce filtre est une première barrière : il porte
  // aussi sur le nom d'affichage, donc l'adresse réelle est revérifiée plus bas.
  const fromClause = `from:{${allowedSenders.join(' ')}}`;
  const searchQuery = `${fromClause} subject:("${PRELEVEMENT_CONFIG.EMAIL_SUBJECT}") has:attachment newer_than:30d`;

  try {
    const destinationFolder = DriveApp.getFolderById(PRELEVEMENT_CONFIG.DRIVE_FOLDER_ID);
    Logger.log(`Dossier de destination trouvé : "${destinationFolder.getName()}"`);
    Logger.log(`Expéditeurs autorisés : ${allowedSenders.join(', ')}`);
    Logger.log(`Recherche des e-mails avec la requête : "${searchQuery}"`);

    const threads = GmailApp.search(searchQuery);
    Logger.log(`${threads.length} conversation(s) trouvée(s) à traiter.`);

    if (threads.length === 0) {
      Logger.log("Aucun e-mail correspondant trouvé. Fin du script.");
      return;
    }

    let savedFilesCount = 0;
    let rejectedSenderCount = 0;
    let rejectedSubjectCount = 0;

    threads.forEach(thread => {
      const messages = thread.getMessages();
      messages.forEach(message => {
        if (message.isInTrash() || message.isDraft()) return;

        // Contrôle 2 : l'adresse réelle de l'expéditeur, et non le nom d'affichage.
        // GmailApp.search('from:') matche aussi le nom affiché : un expéditeur externe
        // qui se nomme "cashcollection@dalkia.fr" passerait le filtre de la requête.
        const sender = prelevement_extractEmail_(message.getFrom());
        if (allowedSenders.indexOf(sender) === -1) {
          rejectedSenderCount++;
          Logger.log(`  -> REJETÉ : expéditeur non autorisé "${sender}" (sujet : "${message.getSubject()}"). Import ignoré.`);
          return;
        }

        // Contrôle 3 : le sujet exact, la recherche Gmail étant approximative.
        const subject = message.getSubject();
        if (PRELEVEMENT_CONFIG.STRICT_SUBJECT && subject.trim() !== PRELEVEMENT_CONFIG.EMAIL_SUBJECT) {
          rejectedSubjectCount++;
          Logger.log(`  -> REJETÉ : sujet non conforme "${subject}" (expéditeur : ${sender}). Import ignoré.`);
          return;
        }

        const attachments = message.getAttachments();
        attachments.forEach(attachment => {
          const fileName = attachment.getName();

          if (fileName.startsWith(PRELEVEMENT_CONFIG.ATTACHMENT_NAME_PREFIX)) {
            Logger.log(`Pièce jointe trouvée : "${fileName}" dans l'e-mail de ${sender}`);

            if (PRELEVEMENT_CONFIG.SKIP_DUPLICATES) {
              const existingFiles = destinationFolder.getFilesByName(fileName);
              if (existingFiles.hasNext()) {
                Logger.log(`  -> Fichier "${fileName}" déjà présent dans le dossier. Ignoré.`);
                return;
              }
            }

            const fileBlob = attachment.copyBlob();
            destinationFolder.createFile(fileBlob);
            Logger.log(`  -> SUCCÈS : Fichier "${fileName}" sauvegardé dans "${destinationFolder.getName()}".`);
            savedFilesCount++;
          }
        });
      });
    });

    Logger.log(`--- Bilan de l'exécution ---`);
    Logger.log(`Fichiers sauvegardés : ${savedFilesCount}`);
    Logger.log(`Messages rejetés (expéditeur) : ${rejectedSenderCount}`);
    Logger.log(`Messages rejetés (sujet) : ${rejectedSubjectCount}`);
    Logger.log(`--------------------------`);

    // Un mail au bon sujet mais du mauvais expéditeur signale soit un changement
    // légitime d'émetteur (à répercuter dans la config, sinon l'import s'arrête
    // silencieusement), soit une tentative d'usurpation. Dans les deux cas, il faut le voir.
    if (savedFilesCount === 0 && (rejectedSenderCount > 0 || rejectedSubjectCount > 0)) {
      prelevement_fail_(`ATTENTION : aucun fichier importé alors que ${rejectedSenderCount + rejectedSubjectCount} message(s) ont été rejetés (expéditeur ou sujet non conforme). Vérifiez 'PRELEVEMENT_CONFIG.ALLOWED_SENDERS' et 'EMAIL_SUBJECT'.`);
    }

  } catch (e) {
    Logger.log(`ERREUR CRITIQUE : Une erreur est survenue durant l'exécution. Détails : ${e.message}`);
    Logger.log(`Stack trace: ${e.stack}`);
  }
}


/**
 * Outil de diagnostic : liste les expéditeurs réels des e-mails correspondant au sujet
 * configuré, avec le nombre de messages pour chacun. À exécuter une fois pour renseigner
 * 'PRELEVEMENT_CONFIG.ALLOWED_SENDERS'.
 */
function prelevement_listSenders() {
  const query = `subject:("${PRELEVEMENT_CONFIG.EMAIL_SUBJECT}") has:attachment newer_than:180d`;
  Logger.log(`Recherche des expéditeurs avec la requête : "${query}"`);

  const counts = {};
  GmailApp.search(query).forEach(thread => {
    thread.getMessages().forEach(message => {
      if (message.isInTrash() || message.isDraft()) return;
      const sender = prelevement_extractEmail_(message.getFrom());
      counts[sender] = (counts[sender] || 0) + 1;
    });
  });

  const senders = Object.keys(counts);
  if (senders.length === 0) {
    Logger.log('Aucun message trouvé sur les 180 derniers jours.');
    return;
  }

  Logger.log('--- Expéditeurs trouvés (message(s)) ---');
  senders
    .sort((a, b) => counts[b] - counts[a])
    .forEach(sender => Logger.log(`  ${sender} : ${counts[sender]}`));
  Logger.log("Reportez le(s) expéditeur(s) légitime(s) dans 'PRELEVEMENT_CONFIG.ALLOWED_SENDERS'.");
}


/**
 * Retourne la liste des expéditeurs autorisés, normalisée (minuscules, sans espaces).
 * @return {string[]} Les adresses autorisées.
 */
function prelevement_allowedSenders_() {
  return (PRELEVEMENT_CONFIG.ALLOWED_SENDERS || [])
    .map(sender => String(sender).trim().toLowerCase())
    .filter(sender => sender !== '');
}


/**
 * Extrait l'adresse e-mail d'un en-tête 'From' de la forme 'Nom <adresse@domaine>'.
 * @param {string} from La valeur brute retournée par GmailMessage.getFrom().
 * @return {string} L'adresse en minuscules.
 */
function prelevement_extractEmail_(from) {
  const match = /<([^>]+)>/.exec(from || '');
  return (match ? match[1] : (from || '')).trim().toLowerCase();
}


/**
 * Journalise un message d'erreur et tente de l'afficher à l'utilisateur.
 * @param {string} message Le message à signaler.
 */
function prelevement_fail_(message) {
  Logger.log(message);
  try {
    SpreadsheetApp.getUi().alert(message);
  } catch (e) {
    // Ignore l'erreur si aucune UI n'est disponible (exécution par déclencheur).
  }
}
