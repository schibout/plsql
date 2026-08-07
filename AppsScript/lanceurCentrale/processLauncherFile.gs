/**
 * Volet 1 : Téléchargement de fichiers depuis Google Drive basé sur une feuille de calcul.
 *
 * Rôle : Expert en développement Google Apps Script et en automatisation Google Workspace.
 *
 * Objectif : Écrire un script Google Apps Script qui automatise la copie de fichiers
 * depuis Google Drive en se basant sur les informations contenues dans une feuille de calcul.
 */

// --- CONFIGURATION ---
const LAUNCHER_CONFIG = {
  /** ID du classeur Google Sheet contenant les instructions. */
  SHEET_ID: '1QNJUUM8lJcHkVOQTNguInGvmI5xZX69EwUqxYL0al1Q',

  /** GID (Grid ID) de la feuille spécifique à lire dans le classeur. */
  SHEET_GID: 1898807058,

  /** ID du dossier Google Drive de destination où tous les fichiers seront copiés. */
  DESTINATION_FOLDER_ID: '1__xp-bdnQJlb_W7aJ9OerGsxgyVbI0qq',

  /** Index de colonne (base 1) pour l'ID du dossier source. Colonne D -> 4 */
  SOURCE_FOLDER_ID_COLUMN: 4,

  /** Index de colonne (base 1) pour le nom du fichier. Colonne G -> 7 */
  FILENAME_COLUMN: 7,

  /** Nombre de lignes d'en-tête à ignorer. */
  HEADER_ROWS_TO_SKIP: 1
};
// --- FIN DE LA CONFIGURATION ---


/**
 * Fonction principale pour traiter le fichier de lancement et copier les fichiers.
 * C'est la fonction à exécuter.
 */
function processLauncherFile() {
  Logger.log('--- Début du traitement du fichier de lancement ---');

  try {
    // 1. Localiser la feuille de calcul
    const sheet = getSheetByGid_(LAUNCHER_CONFIG.SHEET_ID, LAUNCHER_CONFIG.SHEET_GID);
    if (!sheet) {
      Logger.log(`ERREUR : Impossible de trouver la feuille avec GID ${LAUNCHER_CONFIG.SHEET_GID} dans le classeur ${LAUNCHER_CONFIG.SHEET_ID}.`);
      return;
    }
    Logger.log(`Feuille de calcul "${sheet.getName()}" trouvée.`);

    const destinationFolder = DriveApp.getFolderById(LAUNCHER_CONFIG.DESTINATION_FOLDER_ID);
    Logger.log(`Dossier de destination : "${destinationFolder.getName()}".`);

    // 2. Parcourir la feuille de calcul
    const data = sheet.getDataRange().getValues();
    const rowsToProcess = data.slice(LAUNCHER_CONFIG.HEADER_ROWS_TO_SKIP);
    Logger.log(`${rowsToProcess.length} ligne(s) à traiter.`);

    let successCount = 0;
    let errorCount = 0;

    // 3. Itérer sur les lignes
    rowsToProcess.forEach((row, index) => {
      const rowIndex = index + LAUNCHER_CONFIG.HEADER_ROWS_TO_SKIP + 1;
      const sourceFolderId = row[LAUNCHER_CONFIG.SOURCE_FOLDER_ID_COLUMN - 1];
      const fileName = row[LAUNCHER_CONFIG.FILENAME_COLUMN - 1];

      if (!sourceFolderId || !fileName) {
        Logger.log(`Ligne ${rowIndex}: AVERTISSEMENT - Ligne ignorée car l'ID du dossier ou le nom du fichier est manquant.`);
        return;
      }

      try {
        const sourceFolder = DriveApp.getFolderById(sourceFolderId);
        const files = sourceFolder.getFilesByName(fileName);

        if (files.hasNext()) {
          const fileToCopy = files.next();
          fileToCopy.makeCopy(fileName, destinationFolder);
          Logger.log(`Ligne ${rowIndex}: SUCCÈS - Fichier "${fileName}" copié vers "${destinationFolder.getName()}".`);
          successCount++;
        } else {
          Logger.log(`Ligne ${rowIndex}: ERREUR - Fichier "${fileName}" non trouvé dans le dossier source (ID: ${sourceFolderId}).`);
          errorCount++;
        }
      } catch (e) {
        Logger.log(`Ligne ${rowIndex}: ERREUR CRITIQUE - Impossible de traiter la ligne. Erreur: ${e.message}`);
        errorCount++;
      }
    });

    Logger.log(`--- Bilan du traitement ---\nFichiers copiés : ${successCount}\nErreurs : ${errorCount}\n--- Fin ---`);

  } catch (e) {
    Logger.log(`ERREUR INATTENDUE dans le script : ${e.message}\n${e.stack}`);
  }
}

/**
 * Utilitaire pour trouver une feuille par son GID.
 * @private
 */
function getSheetByGid_(spreadsheetId, gid) {
  const spreadsheet = SpreadsheetApp.openById(spreadsheetId);
  return spreadsheet.getSheets().find(s => s.getSheetId() == gid) || null;
}