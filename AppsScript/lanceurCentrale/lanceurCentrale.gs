/**
 * @OnlyCurrentDoc
 *
 * Rôle : Expert en développement Google Apps Script et en automatisation Google Workspace.
 *
 * Objectif : Écrire un script Google Apps Script qui automatise le téléchargement de fichiers
 * depuis Google Drive en se basant sur les informations contenues dans un fichier CSV.
 */

// --- CONFIGURATION ---
/**
 * ID du classeur Google Sheet contenant la configuration.
 * @const {string}
 */
const CONFIG_SHEET_ID = '1QNJUUM8lJcHkVOQTNguInGvmI5xZX69EwUqxYL0al1Q';

/**
 * GID (ID de la feuille) de la feuille spécifique dans le classeur de configuration.
 * C'est le numéro après "gid=" dans l'URL de la feuille.
 * @const {number}
 */
const CONFIG_SHEET_GID = 1898807058;

/**
 * ID du dossier Google Drive où tous les fichiers seront copiés.
 * Assurez-vous que le compte qui exécute le script a les droits d'écriture sur ce dossier.
 * @const {string}
 */
const DESTINATION_FOLDER_ID = '1__xp-bdnQJlb_W7aJ9OerGsxgyVbI0qq';

/**
 * Index des colonnes dans le fichier CSV (commençant à 0).
 */
const COLUMN_INDICES = {
  PROJECT_NAME: 1,     // Colonne B
  SOURCE_FOLDER_ID: 3, // Colonne D
  FILE_NAME: 6,        // Colonne G
};
// --- FIN DE LA CONFIGURATION ---


/**
 * Fonction principale qui orchestre le processus de copie des fichiers.
 * C'est la fonction que vous devez exécuter.
 */
function processLauncherFile() {
  Logger.log('--- Début du traitement ---');

  let destinationFolder;
  try {
    destinationFolder = DriveApp.getFolderById(DESTINATION_FOLDER_ID);
    Logger.log(`Dossier de destination trouvé : "${destinationFolder.getName()}"`);
  } catch (e) {
    Logger.log(`ERREUR CRITIQUE : Le dossier de destination avec l'ID "${DESTINATION_FOLDER_ID}" est introuvable ou inaccessible. Arrêt du script.`);
    console.error(e);
    return;
  }

  const sheetData = getOrdonnanceurCentralData();
  if (!sheetData) {
    Logger.log(`ERREUR CRITIQUE : Impossible de récupérer les données de la feuille de calcul "OrdonnanceurCentral". Arrêt du script.`);
    return;
  }

  Logger.log(`Feuille de configuration trouvée (ID: ${CONFIG_SHEET_ID}, GID: ${CONFIG_SHEET_GID}).`);

  // Ignore la première ligne (en-têtes) en utilisant slice(1)
  // sheetData est déjà un tableau 2D, pas besoin de parseCsv
  const rowsToProcess = sheetData.slice(1);
  Logger.log(`${rowsToProcess.length} ligne(s) à traiter.`);

  rowsToProcess.forEach((row, index) => {
    const lineNumber = index + 2; // +1 pour l'index 0-based, +1 pour l'en-tête sauté
    const projectName = row[COLUMN_INDICES.PROJECT_NAME]?.trim();
    const sourceFolderId = row[COLUMN_INDICES.SOURCE_FOLDER_ID]?.trim();
    const fileName = row[COLUMN_INDICES.FILE_NAME]?.trim();

    // --- Validation de la ligne ---
    if (!sourceFolderId || !fileName) {
      Logger.log(`Ligne ${lineNumber}: AVERTISSEMENT - Ligne ignorée car l'ID du dossier (colonne D) ou le nom du fichier (colonne G) est manquant.`);
      return;
    }

    Logger.log(`Ligne ${lineNumber}: Traitement de "${fileName}" depuis le dossier ID "${sourceFolderId}"`);

    try {
      const sourceFolder = DriveApp.getFolderById(sourceFolderId);
      const files = sourceFolder.getFilesByName(fileName);

      if (!files.hasNext()) {
        Logger.log(`Ligne ${lineNumber}: ERREUR - Le fichier "${fileName}" n'a pas été trouvé dans le dossier "${sourceFolder.getName()}".`);
        return;
      }

      const fileToCopy = files.next();
      
      // Vérifie s'il y a d'autres fichiers avec le même nom pour lever une ambiguïté
      if (files.hasNext()) {
        Logger.log(`Ligne ${lineNumber}: AVERTISSEMENT - Plusieurs fichiers nommés "${fileName}" existent dans le dossier source. Seul le premier sera copié.`);
      }

      // Détermine le nouveau nom du fichier en utilisant la colonne B (ProjectName)
      let newFileName = fileName; // Nom par défaut si la colonne B est vide
      if (projectName) {
        const extensionMatch = fileName.match(/\..+$/); // Trouve l'extension du fichier original
        const extension = extensionMatch ? extensionMatch[0] : '';
        newFileName = projectName + extension;
      } else {
        Logger.log(`Ligne ${lineNumber}: AVERTISSEMENT - ProjectName (colonne B) est manquant. Le nom de fichier original "${fileName}" sera conservé.`);
      }

      // Copie le fichier dans le dossier de destination
      const copiedFile = fileToCopy.makeCopy(newFileName, destinationFolder);
      Logger.log(`Ligne ${lineNumber}: SUCCÈS - Fichier "${fileName}" copié et renommé en "${newFileName}" dans "${destinationFolder.getName()}". Nouveau fichier ID: ${copiedFile.getId()}`);

    } catch (e) {
      Logger.log(`Ligne ${lineNumber}: ERREUR - Impossible de traiter cette ligne. Cause probable : L'ID du dossier source "${sourceFolderId}" est invalide ou inaccessible.`);
      console.error(e);
    }
  });

  Logger.log('--- Fin du traitement ---');
}

/**
 * Ouvre la feuille de calcul Google Sheet et récupère toutes les données de la feuille spécifiée.
 * @returns {Array<Array<string>>|null} Un tableau 2D des données, ou null en cas d'erreur.
 */
function getOrdonnanceurCentralData() {
  try {
    const spreadsheet = SpreadsheetApp.openById(CONFIG_SHEET_ID);
    const sheet = spreadsheet.getSheetById(CONFIG_SHEET_GID);
    if (!sheet) {
      Logger.log(`ERREUR : La feuille avec GID "${CONFIG_SHEET_GID}" est introuvable dans le classeur ID "${CONFIG_SHEET_ID}".`);
      return null;
    }
    return sheet.getDataRange().getValues();
  } catch (e) {
    Logger.log(`ERREUR lors de l'accès à la feuille de calcul (ID: ${CONFIG_SHEET_ID}, GID: ${CONFIG_SHEET_GID}): ${e.message}`);
    console.error(e);
    return null;
  }
}