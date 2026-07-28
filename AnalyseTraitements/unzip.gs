// =====================================================================
// Décompression des fichiers ZIP depuis Google Drive
// =====================================================================
// Prérequis : les ZIP ont été téléchargés par download.gs dans le
//             dossier 'Report_CTM' de Google Drive.
//
// Fonctionnement :
//   1. Parcourt tous les .zip du dossier source
//   2. Extrait le contenu dans un sous-dossier 'Extraits'
//   3. Déplace les ZIP traités dans un sous-dossier 'ZIP_Traites'
// =====================================================================

// --- CONFIGURATION ---
var UNZIP_CONFIG = {
  // Dossier Drive contenant les ZIP (même que download.gs)
  sourceFolderName: 'Report_CTM',

  // Sous-dossier pour les fichiers extraits
  extractFolderName: 'Extraits',

  // Sous-dossier pour archiver les ZIP déjà traités
  archiveFolderName: 'ZIP_Traites',

  // Extensions à extraire (laisser vide [] pour tout extraire)
  allowedExtensions: ['csv', 'xlsx', 'xls', 'txt', 'pdf'],

  // Si true, renomme le fichier si un doublon existe déjà (ex: fichier_1.csv)
  renameDuplicates: true
};

// =====================================================================
// Fonction principale
// =====================================================================
function unzipFiles() {
  var sourceFolder  = getFolderByName(UNZIP_CONFIG.sourceFolderName);
  if (!sourceFolder) {
    Logger.log('ERREUR : dossier "' + UNZIP_CONFIG.sourceFolderName + '" introuvable dans Drive.');
    return;
  }

  var extractFolder = getOrCreateSubFolder(sourceFolder, UNZIP_CONFIG.extractFolderName);
  var archiveFolder = getOrCreateSubFolder(sourceFolder, UNZIP_CONFIG.archiveFolderName);

  var zipFiles = sourceFolder.getFilesByType('application/zip');
  var totalExtracted = 0;
  var totalSkipped   = 0;
  var totalZips      = 0;

  while (zipFiles.hasNext()) {
    var zipFile = zipFiles.next();
    var zipName = zipFile.getName();
    totalZips++;

    Logger.log('Traitement : ' + zipName);

    try {
      var blobs = Utilities.unzip(zipFile.getBlob());

      blobs.forEach(function(blob) {
        var fileName = blob.getName();

        // Ignorer les dossiers internes (__MACOSX, etc.)
        if (fileName.indexOf('/') !== -1) {
          fileName = fileName.split('/').pop();
        }
        if (!fileName || fileName.indexOf('.') === -1) return;

        // Filtre par extension
        if (!isAllowedExt(fileName, UNZIP_CONFIG.allowedExtensions)) {
          Logger.log('  Ignoré (extension) : ' + fileName);
          return;
        }

        // Renommage si doublon
        if (UNZIP_CONFIG.renameDuplicates && fileExistsIn(extractFolder, fileName)) {
          fileName = getUniqueFileNameIn(extractFolder, fileName);
          Logger.log('  Doublon détecté, renommé en : ' + fileName);
        }

        extractFolder.createFile(blob.setName(fileName));
        Logger.log('  Extrait : ' + fileName);
        totalExtracted++;
      });

      // Déplacer le ZIP vers le dossier archive
      zipFile.moveTo(archiveFolder);
      Logger.log('  ZIP archivé → ' + UNZIP_CONFIG.archiveFolderName + '/');

    } catch (e) {
      Logger.log('  ERREUR sur ' + zipName + ' : ' + e.message);
    }
  }

  var summary = 'Terminé — ZIP traités : ' + totalZips +
                ' | Fichiers extraits : ' + totalExtracted +
                ' | Ignorés (doublon) : ' + totalSkipped;
  Logger.log(summary);
  Logger.log('Dossier extraits : https://drive.google.com/drive/folders/' + extractFolder.getId());
}

// =====================================================================
// Pipeline complet : télécharger puis dézipper
// =====================================================================
function downloadAndUnzip() {
  Logger.log('=== ÉTAPE 1 : Téléchargement des pièces jointes ===');
  downloadAttachments();
  Logger.log('');
  Logger.log('=== ÉTAPE 2 : Décompression des ZIP ===');
  unzipFiles();
}

// =====================================================================
// Fonctions utilitaires
// =====================================================================

function getFolderByName(name) {
  var folders = DriveApp.getFoldersByName(name);
  return folders.hasNext() ? folders.next() : null;
}

function getOrCreateSubFolder(parentFolder, name) {
  var folders = parentFolder.getFoldersByName(name);
  if (folders.hasNext()) {
    return folders.next();
  }
  Logger.log('Création du sous-dossier : ' + name);
  return parentFolder.createFolder(name);
}

function fileExistsIn(folder, fileName) {
  var files = folder.getFilesByName(fileName);
  return files.hasNext();
}

function getUniqueFileNameIn(folder, fileName) {
  var dotIndex = fileName.lastIndexOf('.');
  var baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  var extension = dotIndex > 0 ? fileName.substring(dotIndex) : '';
  var counter = 1;
  var newName = baseName + '_' + counter + extension;
  while (fileExistsIn(folder, newName)) {
    counter++;
    newName = baseName + '_' + counter + extension;
  }
  return newName;
}

function isAllowedExt(fileName, allowed) {
  if (!allowed || allowed.length === 0) return true;
  var ext = fileName.split('.').pop().toLowerCase();
  return allowed.indexOf(ext) !== -1;
}
