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

  // Préfixe du nom des pièces jointes à rechercher.
  ATTACHMENT_NAME_PREFIX: 'IMPORT_AVP_DK',
  
  // Sujet exact de l'e-mail à rechercher.
  EMAIL_SUBJECT: '[PRD] Synthèse quotidienne des prélèvements Dalkia reçus par CashCollection',

  // Faut-il ignorer les fichiers déjà présents dans le dossier de destination ?
  SKIP_DUPLICATES: true,
};
// --- FIN DE LA CONFIGURATION ---


/**
 * Fonction principale pour importer les pièces jointes des prélèvements.
 * À exécuter manuellement ou via un déclencheur.
 */
function prelevement_importAttachments() {
  // Construction de la requête de recherche Gmail
  const searchQuery = `subject:("${PRELEVEMENT_CONFIG.EMAIL_SUBJECT}") has:attachment newer_than:30d`;
  
  // Vérification de la configuration
  if (!PRELEVEMENT_CONFIG.DRIVE_FOLDER_ID) {
    const message = "ERREUR : L'ID du dossier Google Drive n'est pas configuré dans la variable 'PRELEVEMENT_CONFIG.DRIVE_FOLDER_ID'.";
    Logger.log(message);
    try {
      SpreadsheetApp.getUi().alert(message);
    } catch (e) {
      // Ignore l'erreur si aucune UI n'est disponible.
    }
    return;
  }

  try {
    const destinationFolder = DriveApp.getFolderById(PRELEVEMENT_CONFIG.DRIVE_FOLDER_ID);
    Logger.log(`Dossier de destination trouvé : "${destinationFolder.getName()}"`);
    Logger.log(`Recherche des e-mails avec la requête : "${searchQuery}"`);

    const threads = GmailApp.search(searchQuery);
    Logger.log(`${threads.length} conversation(s) trouvée(s) à traiter.`);

    if (threads.length === 0) {
      Logger.log("Aucun e-mail correspondant trouvé. Fin du script.");
      return;
    }

    let savedFilesCount = 0;

    threads.forEach(thread => {
      const messages = thread.getMessages();
      messages.forEach(message => {
        if (message.isInTrash() || message.isDraft()) return;

        const attachments = message.getAttachments();
        attachments.forEach(attachment => {
          const fileName = attachment.getName();

          if (fileName.startsWith(PRELEVEMENT_CONFIG.ATTACHMENT_NAME_PREFIX)) {
            Logger.log(`Pièce jointe trouvée : "${fileName}" dans l'e-mail avec le sujet "${message.getSubject()}"`);

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
    Logger.log(`--------------------------`);

  } catch (e) {
    Logger.log(`ERREUR CRITIQUE : Une erreur est survenue durant l'exécution. Détails : ${e.message}`);
    Logger.log(`Stack trace: ${e.stack}`);
  }
}