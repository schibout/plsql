/**
 * @OnlyCurrentDoc
 *
 * Ce script automatise la récupération de pièces jointes spécifiques depuis Gmail
 * et leur sauvegarde dans un dossier Google Drive.
 * Il est conçu pour rechercher des fichiers comme 'REJETS_INTERNES_DK.xxxxxx.csv'.
 */

// --- CONFIGURATION ---
// Modifiez les valeurs ci-dessous pour adapter le script à vos besoins.
const REJETS_CONFIG = {
  // IMPORTANT : ID du dossier Google Drive où les pièces jointes seront sauvegardées.
  // Pour trouver l'ID : ouvrez le dossier dans Drive, l'ID est la partie finale de l'URL.
  // Exemple : '1aBcDeFgHiJkLmNoPqRsTuVwXyZ'
  DRIVE_FOLDER_ID: '1Q0ToZKjWdH7HJt7XSA19UsKwBHD2FLG5',

  // Préfixe du nom des pièces jointes à rechercher.
  // Le script ne traitera que les fichiers dont le nom commence par ce texte.
  ATTACHMENT_NAME_PREFIX: 'REJETS_INTERNES_DK',

  // Critères de recherche des e-mails. Vous pouvez l'adapter.
  // Exemples :
  // 'is:unread' -> pour ne traiter que les non-lus.
  // 'label:boite-a-traiter' -> pour chercher dans un libellé spécifique que vous avez créé.
  // 'newer_than:30d' -> pour ne traiter que les e-mails des 30 derniers jours.
  GMAIL_SEARCH_QUERY: 'has:attachment newer_than:30d',

  // Faut-il ignorer les fichiers déjà présents dans le dossier de destination ?
  // Si 'true', un fichier avec le même nom ne sera pas sauvegardé à nouveau.
  SKIP_DUPLICATES: true,
};
// --- FIN DE LA CONFIGURATION ---


/**
 * Fonction principale à exécuter manuellement ou via un déclencheur.
 * Recherche les e-mails, extrait les pièces jointes correspondantes et les sauvegarde sur Drive.
 */
function rejeter_processAttachments() {
  // Vérification de la configuration
  if (!REJETS_CONFIG.DRIVE_FOLDER_ID) {
    const message = "ERREUR : L'ID du dossier Google Drive n'est pas configuré dans la variable 'REJETS_CONFIG.DRIVE_FOLDER_ID'.";
    Logger.log(message);
    // Si le script est lié à un Google Sheet, on peut afficher une alerte à l'utilisateur.
    try {
      SpreadsheetApp.getUi().alert(message);
    } catch (e) {
      // Ignore l'erreur si aucune interface utilisateur n'est disponible (contexte d'exécution simple).
    }
    return;
  }

  try {
    // 1. Accéder au dossier de destination sur Google Drive
    const destinationFolder = DriveApp.getFolderById(REJETS_CONFIG.DRIVE_FOLDER_ID);
    Logger.log(`Dossier de destination trouvé : "${destinationFolder.getName()}"`);

    // 2. Construire la requête de recherche Gmail
    const searchQuery = REJETS_CONFIG.GMAIL_SEARCH_QUERY;
    Logger.log(`Recherche des e-mails avec la requête : "${searchQuery}"`);

    // 3. Exécuter la recherche
    const threads = GmailApp.search(searchQuery);
    Logger.log(`${threads.length} conversation(s) trouvée(s) à traiter.`);

    if (threads.length === 0) {
      Logger.log("Aucun nouvel e-mail à traiter. Fin du script.");
      return;
    }

    let savedFilesCount = 0;

    // 4. Parcourir chaque conversation (thread)
    threads.forEach(thread => {
      const messages = thread.getMessages();

      // Parcourir chaque message dans la conversation
      messages.forEach(message => {
        // On ignore les messages dans la corbeille ou les brouillons
        if (message.isInTrash() || message.isDraft()) return;

        const attachments = message.getAttachments();

        // Parcourir chaque pièce jointe du message
        attachments.forEach(attachment => {
          const fileName = attachment.getName();

          // Vérifier si la pièce jointe correspond au critère de nom
          if (fileName.startsWith(REJETS_CONFIG.ATTACHMENT_NAME_PREFIX)) {
            Logger.log(`Pièce jointe trouvée : "${fileName}" dans l'e-mail avec le sujet "${message.getSubject()}"`);

            // Gérer les doublons (optionnel)
            if (REJETS_CONFIG.SKIP_DUPLICATES) {
              const existingFiles = destinationFolder.getFilesByName(fileName);
              if (existingFiles.hasNext()) {
                Logger.log(`  -> Fichier "${fileName}" déjà présent dans le dossier. Ignoré.`);
                return; // Passe à la pièce jointe suivante
              }
            }

            // Sauvegarder le fichier dans le dossier Drive
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
    // Gestion des erreurs (ex: dossier Drive inaccessible, permissions manquantes)
    Logger.log(`ERREUR CRITIQUE : Une erreur est survenue durant l'exécution. Détails : ${e.message}`);
    Logger.log(`Stack trace: ${e.stack}`);
  }
}
