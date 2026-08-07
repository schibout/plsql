/**
 * @fileoverview Script pour rechercher des e-mails spécifiques dans Gmail,
 * télécharger leurs pièces jointes et les sauvegarder dans un dossier Google Drive
 * avec un nom de fichier horodaté.
 */

//================ CONFIGURATION ================
const CONFIG = {
  // ID du dossier dans Google Drive où les pièces jointes seront sauvegardées.
  DRIVE_FOLDER_ID: '1skW6lJUvX1qlmw6RoLqE_94o5P1yu7o2',

  // L'objet des e-mails doit COMMENCER par l'une de ces phrases.
  EMAIL_SUBJECT_PREFIXES: [
    '[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection',
    '[PROD] [PRELEVEMENTS ORACLE] - Regroupements effectués pour EDF'
  ],

  // Décalage en jours pour la recherche des e-mails (ex: 3 = J-3).
  DATE_OFFSET_DAYS: 3,

  // Fuseau horaire pour le formatage des dates.
  TIMEZONE: Session.getScriptTimeZone(),

  // Extensions de fichiers autorisées. Laisser vide [] pour tout accepter.
  // Ex: ['csv', 'zip', 'pdf']
  ALLOWED_EXTENSIONS: [],

  // Nombre maximum de conversations à traiter par exécution pour éviter de dépasser les quotas.
  MAX_THREADS_PER_RUN: 500,

  // --- Options de robustesse ---
  // Appliquer un label pour éviter de retraiter les mêmes e-mails.
  APPLY_LABEL: true,
  // Nom du label à créer et appliquer.
  PROCESSED_LABEL_NAME: 'Controle_Transfert_Traité',
};
//===============================================


/**
 * POINT D'ENTRÉE POUR L'AUTOMATISATION (TRIGGER)
 * Exécute le processus en se basant sur la date du jour.
 * À planifier pour une exécution quotidienne.
 */
function runAutomatically() {
  const today = new Date();
  Logger.log(`Lancement automatique du traitement pour la date du ${today.toLocaleDateString()}`);
  processEmailsForDate(today);
}

/**
 * POINT D'ENTRÉE POUR UN TEST MANUEL
 * Demande à l'utilisateur de saisir une date pour le traitement.
 */
function runManually() {
  const ui = SpreadsheetApp.getUi(); // Ou DocumentApp.getUi() si le script est lié à un document.
  const response = ui.prompt(
    'Test Manuel',
    'Veuillez saisir une date de référence (JJ/MM/AAAA) pour lancer la recherche (la recherche se fera à J-3) :',
    ui.ButtonSet.OK_CANCEL
  );

  if (response.getSelectedButton() !== ui.Button.OK) {
    Logger.log('Opération annulée par l\'utilisateur.');
    return;
  }

  const dateString = response.getResponseText().trim();
  const parts = dateString.match(/^(\d{2})\/(\d{2})\/(\d{4})$/);

  if (!parts) {
    ui.alert('Format de date invalide. Veuillez utiliser le format JJ/MM/AAAA.');
    Logger.log(`Format de date invalide fourni : ${dateString}`);
    return;
  }

  // new Date(année, mois - 1, jour)
  const executionDate = new Date(parts[3], parts[2] - 1, parts[1]);
  if (isNaN(executionDate.getTime())) {
    ui.alert('La date saisie est invalide.');
    return;
  }

  Logger.log(`Lancement manuel du traitement pour la date de référence : ${executionDate.toLocaleDateString()}`);
  processEmailsForDate(executionDate);
  ui.alert('Traitement terminé. Consultez les journaux (Affichage > Journaux) pour plus de détails.');
}

/**
 * Logique principale : recherche les e-mails pour une date donnée et traite les pièces jointes.
 * @param {Date} executionDate La date de référence pour le script. La recherche réelle se fera à `executionDate` - `CONFIG.DATE_OFFSET_DAYS`.
 */
function processEmailsForDate(executionDate) {
  let targetFolder;
  try {
    targetFolder = DriveApp.getFolderById(CONFIG.DRIVE_FOLDER_ID);
    Logger.log(`Dossier cible : "${targetFolder.getName()}" (ID: ${targetFolder.getId()})`);
  } catch (e) {
    Logger.log(`ERREUR : Impossible d'accéder au dossier Drive avec l'ID "${CONFIG.DRIVE_FOLDER_ID}". Vérifiez que l'ID est correct et que vous avez les autorisations d'accès. Détails : ${e.toString()}`);
    // Arrête l'exécution si le dossier est inaccessible.
    return;
  }

  const processedLabel = CONFIG.APPLY_LABEL ? getOrCreateLabel(CONFIG.PROCESSED_LABEL_NAME) : null;

  // Calcule la date de recherche exacte (J-3)
  const searchDate = new Date(executionDate);
  searchDate.setDate(searchDate.getDate() - CONFIG.DATE_OFFSET_DAYS);

  // Construit la requête de recherche pour Gmail
  const afterDateStr = Utilities.formatDate(searchDate, CONFIG.TIMEZONE, 'yyyy/MM/dd');
  const beforeDate = new Date(searchDate);
  beforeDate.setDate(beforeDate.getDate() + 1);
  const beforeDateStr = Utilities.formatDate(beforeDate, CONFIG.TIMEZONE, 'yyyy/MM/dd');

  // Requête simple et robuste : on filtre par date et pièce jointe, puis on affine dans le script.
  // On exclut aussi les emails déjà traités si l'option est activée.
  let searchQuery = `after:${afterDateStr} before:${beforeDateStr} has:attachment`;
  if (processedLabel) {
    searchQuery += ` -label:${processedLabel.getName()}`;
  }

  Logger.log(`Recherche des e-mails avec la requête : ${searchQuery}`);

  let totalThreadsProcessed = 0;
  let totalFilesSaved = 0;
  let totalFilesSkipped = 0;
  let foundMatches = false;
  const pageSize = 100; // Taille de page pour la recherche Gmail
  let start = 0;

  while (true) {
    const threads = GmailApp.search(searchQuery, start, pageSize);

    if (threads.length === 0) {
      if (start === 0) { // Si aucun thread n'a été trouvé dès le début.
        Logger.log("Aucun e-mail correspondant trouvé pour cette période.");
      }
      break;
    }

    Logger.log(`Page ${start / pageSize + 1} - Traitement de ${threads.length} conversation(s)...`);

    threads.forEach(thread => {
      totalThreadsProcessed++;
      const messages = thread.getMessages();
      let threadProcessed = false; // Pour savoir si on doit appliquer le label au thread

      messages.forEach(message => {
      // 1. Vérification de la date (sécurité supplémentaire)
      const messageDateStr = Utilities.formatDate(message.getDate(), CONFIG.TIMEZONE, 'yyyy/MM/dd');
      if (messageDateStr !== afterDateStr) {
        return; // Passe au message suivant si la date ne correspond pas exactement
      }

      // 2. Vérification précise : l'objet doit COMMENCER par un des préfixes.
      const subject = message.getSubject();
      const isMatch = CONFIG.EMAIL_SUBJECT_PREFIXES.some(prefix => subject.startsWith(prefix));

      if (!isMatch) return; // L'objet ne correspond pas, on ignore ce message.

      foundMatches = true;
      threadProcessed = true; // Marque le thread pour l'application du label
      const attachments = message.getAttachments();

      if (attachments.length > 0) {
        Logger.log(`  - Traitement de ${attachments.length} pièce(s) jointe(s) de l'e-mail : "${subject}"`);

        attachments.forEach(attachment => {
          const originalName = attachment.getName();

          // Filtre par extension
          if (!isAllowedExtension(originalName, CONFIG.ALLOWED_EXTENSIONS)) {
            Logger.log(`    - Ignoré (extension non autorisée) : ${originalName}`);
            totalFilesSkipped++;
            return; // Passe à la pièce jointe suivante
          }

          try {
            const timestamp = Utilities.formatDate(message.getDate(), CONFIG.TIMEZONE, 'yyyyMMdd_HHmm');
            const newFileName = `${timestamp}_${originalName}`;

            // Crée le fichier dans Drive en évitant les doublons si le script est relancé
            const existingFiles = targetFolder.getFilesByName(newFileName);
            if (existingFiles.hasNext()) {
              Logger.log(`    - Le fichier "${newFileName}" existe déjà. Ignoré.`);
              totalFilesSkipped++;
            } else {
              const file = targetFolder.createFile(attachment.copyBlob());
              file.setName(newFileName);
              Logger.log(`    - Fichier sauvegardé sous : "${newFileName}"`);
              totalFilesSaved++;
            }
          } catch (e) {
            Logger.log(`    - ERREUR lors de la sauvegarde d'une pièce jointe : ${e.toString()}`);
          }
        });
      }
    });
      // Applique le label à la conversation si au moins un message a été traité
      if (threadProcessed && processedLabel) {
        thread.addLabel(processedLabel);
        Logger.log(`  - Label "${processedLabel.getName()}" appliqué à la conversation.`);
      }
    });

    start += pageSize;
    if (start >= CONFIG.MAX_THREADS_PER_RUN) {
      Logger.log(`Limite de ${CONFIG.MAX_THREADS_PER_RUN} conversations atteinte. Relancer si nécessaire pour traiter le reste.`);
      break;
    }
  }

  if (!foundMatches) {
    Logger.log("Aucun e-mail dont l'objet correspond exactement aux préfixes n'a été trouvé après filtrage.");
  }

  const summary = `--- Résumé du traitement ---
  Conversations traitées: ${totalThreadsProcessed}
  Fichiers sauvegardés: ${totalFilesSaved}
  Fichiers ignorés: ${totalFilesSkipped}
  --------------------------`;
  Logger.log(summary);
}

/**
 * Récupère ou crée un label Gmail.
 * @param {string} name Le nom du label à rechercher ou créer.
 * @return {GmailApp.GmailLabel} L'objet label trouvé ou créé.
 */
function getOrCreateLabel(name) {
  let label = GmailApp.getUserLabelByName(name);
  if (!label) {
    label = GmailApp.createLabel(name);
    Logger.log(`Label Gmail "${name}" créé.`);
  }
  return label;
}

/**
 * Vérifie si l'extension du fichier est autorisée.
 * @param {string} fileName Le nom du fichier.
 * @param {string[]} allowedExtensions Un tableau d'extensions (sans le point).
 * @return {boolean}
 */
function isAllowedExtension(fileName, allowedExtensions) {
  if (!Array.isArray(allowedExtensions) || allowedExtensions.length === 0) {
    return true; // Tout accepter si la liste est vide ou invalide
  }
  const ext = fileName.split('.').pop().toLowerCase();
  // Convertit les extensions autorisées en minuscules pour une comparaison insensible à la casse.
  return allowedExtensions.map(e => e.toLowerCase()).includes(ext);
}