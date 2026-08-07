/**
 * Volet 2 : Extraction de données depuis les e-mails "Lanceur Central"
 *
 * Rôle : Expert en Google Apps Script, spécialisé dans l'automatisation Gmail
 * et l'analyse de contenu (parsing HTML).
 *
 * Objectif : Écrire un script qui recherche des e-mails spécifiques, en extrait
 * un tableau HTML, et enregistre ces données dans un fichier CSV sur Google Drive.
 */

// --- CONFIGURATION ---
const EMAIL_EXTRACTION_CONFIG = {
  /** Expéditeur de l'e-mail à rechercher. */
  SENDER: 'dsin-rpa-robot1@dalkia.fr',

  /** Le sujet de l'e-mail doit commencer par ce texte. */
  SUBJECT_PREFIX: '[Lanceur Central]',

  /** 
   * Date de début de recherche des e-mails (format AAAA-MM-JJ).
   * Modifiez cette date pour correspondre à la période que vous souhaitez analyser.
   */
  START_DATE: '2026-01-01',

  /** ID du dossier Google Drive où le fichier CSV sera enregistré. */
  DESTINATION_FOLDER_ID: '1__xp-bdnQJlb_W7aJ9OerGsxgyVbI0qq',

  /** Nom du label à appliquer aux e-mails traités pour éviter les doublons. */
  PROCESSED_LABEL_NAME: 'Lanceur_Traité',

  /** Préfixe du nom de fichier pour le CSV généré. */
  CSV_FILENAME_PREFIX: 'Resultat_Lanceur_Central_',

  /** Préfixe du nom de fichier pour le log CSV généré. */
  LOG_FILENAME_PREFIX: 'Log_Extraction_Emails_'
};
// --- FIN DE LA CONFIGURATION ---

/**
 * Fonction principale pour extraire les tableaux des e-mails et les sauvegarder en CSV.
 * C'est la fonction à exécuter ou à planifier.
 */
function extractTableFromEmails() {
  const logEntries = [];
  const log = (message) => {
    const timestamp = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyy-MM-dd HH:mm:ss');
    logEntries.push([timestamp, message]);
    Logger.log(`[${timestamp}] ${message}`); // Continue de logger dans la console pour le débogage en direct.
  };

  log('--- Début de l\'extraction des données depuis les e-mails ---');

  try {
    const processedLabel = getOrCreateLabel_(EMAIL_EXTRACTION_CONFIG.PROCESSED_LABEL_NAME);
    const destinationFolder = getDestinationFolder_();
    if (!destinationFolder) {
      log('ERREUR CRITIQUE : Le dossier de destination est inaccessible. Arrêt du script.');
      return; // Arrêt si le dossier de destination est inaccessible.
    }

    // Construction de la requête de recherche Gmail
    // Le filtre 'is:unread' a été retiré pour inclure aussi les e-mails déjà lus.
    // La logique repose maintenant uniquement sur l'absence du label de traitement.
    // Le filtre '-label' a été retiré pour analyser tous les e-mails à chaque exécution, même ceux déjà traités.
    const query = `from:(${EMAIL_EXTRACTION_CONFIG.SENDER}) subject:("${EMAIL_EXTRACTION_CONFIG.SUBJECT_PREFIX}") after:${EMAIL_EXTRACTION_CONFIG.START_DATE}`;
    log(`Recherche Gmail avec la requête : ${query}`);

    const threads = GmailApp.search(query);
    log(`${threads.length} conversation(s) non traitée(s) trouvée(s).`);

    if (threads.length === 0) {
      log('Aucun nouvel e-mail à traiter.');
      return;
    }

    const allDataRows = [];
    let headerRow = null;

    threads.forEach(thread => {
      // On ne traite que le message le plus récent de la conversation
      const message = thread.getMessages()[thread.getMessageCount() - 1];

      try {
        log(`Traitement de l'e-mail avec le sujet : "${message.getSubject()}" (ID: ${message.getId()})`);
        const htmlBody = message.getBody();

        const tableData = parseHtmlTable_(htmlBody, log);
        if (!tableData || tableData.length === 0) {
          log(`AVERTISSEMENT : Aucun tableau n'a été trouvé ou extrait de l'e-mail ID: ${message.getId()}`);
        } else {
          // Capture l'en-tête depuis le premier tableau valide trouvé
          if (!headerRow && tableData.length > 0) {
            headerRow = tableData[0];
          }

          // Ajoute les lignes de données (en sautant l'en-tête)
          const dataRows = tableData.slice(1);
          if (dataRows.length > 0) {
            allDataRows.push(...dataRows);
            log(`SUCCÈS : ${dataRows.length} ligne(s) de données extraite(s) de l'e-mail ID: ${message.getId()}`);
          } else {
            log(`AVERTISSEMENT : Le tableau de l'e-mail ID: ${message.getId()} ne contient que des en-têtes.`);
          }
        }

        // Marquer comme traité pour ne pas le relire, même si le tableau est vide
        thread.addLabel(processedLabel);
        message.markRead();
        log(`L'e-mail (et sa conversation) a été marqué comme traité (lu et labellisé).`);
      } catch (e) {
        log(`ERREUR lors du traitement de l'e-mail ID: ${message.getId()}. Erreur: ${e.message}`);
        console.error(e);
      }
    });

    // Création du fichier CSV consolidé après avoir traité tous les e-mails
    if (headerRow && allDataRows.length > 0) {
      const consolidatedData = [headerRow, ...allDataRows];
      const csvContent = arrayToCsv_(consolidatedData);
      const dateString = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyyMMdd');
      const fileName = `${EMAIL_EXTRACTION_CONFIG.CSV_FILENAME_PREFIX}${dateString}_consolidated.csv`;
      destinationFolder.createFile(fileName, csvContent, MimeType.CSV);
      log(`SUCCÈS : Fichier consolidé "${fileName}" créé avec ${allDataRows.length} lignes de données.`);
    } else {
      log('Aucune donnée de tableau n\'a été extraite pour créer un fichier CSV.');
    }
  } catch (e) {
    log(`ERREUR INATTENDUE dans le script : ${e.message}`);
    console.error(e);
  } finally {
    log('--- Fin du traitement ---');
    writeLogsToCsv_(logEntries);
  }
}

/**
 * Analyse le corps HTML d'un e-mail pour en extraire le premier tableau.
 * Utilise XmlService pour une analyse robuste du HTML.
 * @param {string} htmlBody Le corps HTML de l'e-mail.
 * @returns {Array<Array<string>>|null} Un tableau 2D représentant les données du tableau, ou null si aucun tableau n'est trouvé.
 * @param {function(string):void} log La fonction de logging.
 * @private
 */
function parseHtmlTable_(htmlBody, log) {
  try {
    // XmlService nécessite un noeud racine bien formé, on encadre donc le HTML.
    const root = XmlService.parse(`<html><body>${htmlBody}</body></html>`).getRootElement();
    const body = root.getChild('body');
    
    // On cherche la première balise <table> parmi les descendants
    const tableElement = body.getDescendants().find(d => d.asElement() && d.asElement().getName() === 'table');
    if (!tableElement) return null;

    const data = [];
    const rows = tableElement.asElement().getChildren('tr');
    
    rows.forEach(rowElement => {
      const rowData = [];
      const cells = rowElement.getChildren(); // Prend <th> et <td>
      cells.forEach(cellElement => {
        rowData.push(cellElement.getValue().trim());
      });
      data.push(rowData);
    });
    return data;
  } catch (e) {
    log(`Erreur de parsing XML : ${e.message}. Le contenu HTML est peut-être malformé.`);
    return null;
  }
}

/**
 * Convertit un tableau 2D en une chaîne de caractères au format CSV.
 * @private
 */
function arrayToCsv_(data) {
  return data.map(row => row.map(cell => `"${(cell || '').toString().replace(/"/g, '""')}"`).join(';')).join('\n');
}

/**
 * Récupère ou crée le label Gmail pour marquer les e-mails traités.
 * @private
 */
function getOrCreateLabel_(labelName) {
  let label = GmailApp.getUserLabelByName(labelName);
  if (!label) {
    label = GmailApp.createLabel(labelName);
  }
  return label;
}

/**
 * Récupère l'objet dossier de destination.
 * @private
 */
function getDestinationFolder_() {
  try {
    return DriveApp.getFolderById(EMAIL_EXTRACTION_CONFIG.DESTINATION_FOLDER_ID);
  } catch (e) {
    Logger.log(`ERREUR CRITIQUE : Le dossier de destination avec l'ID "${EMAIL_EXTRACTION_CONFIG.DESTINATION_FOLDER_ID}" est introuvable ou inaccessible.`);
    return null;
  }
}

/**
 * Écrit les entrées de log dans un fichier CSV dans le dossier de destination.
 * @param {Array<Array<string>>} logEntries Les entrées de log à écrire.
 * @private
 */
function writeLogsToCsv_(logEntries) {
  if (!logEntries || logEntries.length === 0) {
    return; // Rien à logger
  }

  // Utilise une nouvelle tentative pour obtenir le dossier au cas où il aurait été inaccessible au début.
  const destinationFolder = getDestinationFolder_();
  if (!destinationFolder) {
    Logger.log('Impossible d\'écrire le fichier de log car le dossier de destination est inaccessible.');
    return;
  }

  try {
    const header = ['Timestamp', 'Message'];
    const data = [header, ...logEntries];
    const csvContent = data.map(row => row.map(cell => `"${(cell || '').toString().replace(/"/g, '""')}"`).join(',')).join('\n');

    const dateString = Utilities.formatDate(new Date(), Session.getScriptTimeZone(), 'yyyyMMdd_HHmmss');
    const logFileName = `${EMAIL_EXTRACTION_CONFIG.LOG_FILENAME_PREFIX}${dateString}.csv`;

    destinationFolder.createFile(logFileName, csvContent, MimeType.CSV);
    Logger.log(`Fichier de log "${logFileName}" créé avec succès.`);
  } catch (e) {
    Logger.log(`ERREUR CRITIQUE : Impossible de créer le fichier de log. Erreur: ${e.message}`);
    console.error(e);
  }
}