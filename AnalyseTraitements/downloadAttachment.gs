// =====================================================================
// Téléchargement des pièces jointes Gmail → Google Drive
// =====================================================================
// Usage : Exécuter downloadAttachments() depuis l'éditeur Apps Script
//         ou configurer un déclencheur temporel (ex: chaque matin à 9h)
//
// Les fichiers sont sauvegardés dans Google Drive (Apps Script ne peut
// pas écrire directement sur le poste local).
// Pour récupérer en local : utiliser Google Drive for Desktop ou
// l'URL de téléchargement affichée dans les logs.
// =====================================================================

// --- CONFIGURATION ---
var CONFIG = {
  // Critère de recherche Gmail (syntaxe identique à la barre de recherche Gmail)
  // Emails CTM : sujet "DALKIA / Extract CSV du Suivi Quotidien CTM (ODAT=...)"
  // Emails nuit : sujet "Mail reporting Nuit Applicative"
  // after:2025/01/01 → depuis le 1er janvier 2025
  searchQuery: '(from:Indic_CTM OR from:dsin-rpa-robot1) has:attachment after:2025/01/01',

  // Nombre maximum de fils de discussion à traiter par exécution
  // GmailApp.search() pagine par tranches de 100
  // Attention : Apps Script a une limite de 6 min d'exécution
  maxThreads: 5000,

  // Nom du dossier Google Drive où sauvegarder les pièces jointes
  driveFolderName: 'Report_CTM',

  // Extensions autorisées (laisser vide [] pour tout accepter)
  allowedExtensions: ['zip', 'csv', 'xlsx', 'xls', 'pdf'],

  // Si true, marque les emails traités avec ce label Gmail
  applyLabel: true,
  labelName: 'PJ_Traitees',

  // Si true, renomme le fichier si un doublon existe déjà dans Drive (ex: fichier_1.csv)
  renameDuplicates: true
};

// =====================================================================
// Fonction principale
// =====================================================================
function downloadAttachments() {
  var folder = getOrCreateFolder(CONFIG.driveFolderName);
  var label   = CONFIG.applyLabel ? getOrCreateLabel(CONFIG.labelName) : null;

  var totalSaved   = 0;
  var totalSkipped = 0;
  var pageSize     = 100;  // nombre de fils par page (max Gmail API)
  var start        = 0;
  var totalThreads = 0;

  // Pagination : GmailApp.search() retourne au maximum 500 résultats par appel
  // On boucle par tranches de 100 jusqu'à épuisement des résultats
  while (true) {
    var threads = GmailApp.search(CONFIG.searchQuery, start, pageSize);
    if (threads.length === 0) break;

    totalThreads += threads.length;
    Logger.log('Page ' + (start / pageSize + 1) + ' — ' + threads.length + ' fils (total cumulé : ' + totalThreads + ')');

    threads.forEach(function(thread) {
      // Ne pas retraiter les fils déjà étiquetés
      if (CONFIG.applyLabel && threadHasLabel(thread, CONFIG.labelName)) {
        return;
      }

      var messages = thread.getMessages();

      messages.forEach(function(message) {
        var attachments = message.getAttachments();

        attachments.forEach(function(att) {
          var fileName = att.getName();

          // Filtre par extension
          if (!isAllowedExtension(fileName, CONFIG.allowedExtensions)) {
            Logger.log('Ignoré (extension) : ' + fileName);
            return;
          }

          // Renommage si doublon
          if (CONFIG.renameDuplicates && fileExistsInFolder(folder, fileName)) {
            fileName = getUniqueFileName(folder, fileName);
            Logger.log('Doublon détecté, renommé en : ' + fileName);
          }

          // Sauvegarde dans Drive
          try {
            folder.createFile(att.copyBlob().setName(fileName));
            Logger.log('Sauvegardé : ' + fileName);
            totalSaved++;
          } catch (e) {
            Logger.log('ERREUR sur ' + fileName + ' : ' + e.message);
          }
        });
      });

      // Appliquer le label après traitement du fil
      if (label) {
        thread.addLabel(label);
      }
    });

    start += pageSize;

    // Sécurité : ne pas dépasser maxThreads au total
    if (start >= CONFIG.maxThreads) {
      Logger.log('Limite maxThreads (' + CONFIG.maxThreads + ') atteinte — relancer pour continuer.');
      break;
    }
  }

  var summary = 'Terminé — Fils traités : ' + totalThreads + ' | Sauvegardés : ' + totalSaved + ' | Ignorés (doublon) : ' + totalSkipped;
  Logger.log(summary);
  Logger.log('Dossier Drive : https://drive.google.com/drive/folders/' + folder.getId());
}

// =====================================================================
// Fonctions utilitaires
// =====================================================================

/**
 * Récupère ou crée un dossier dans Mon Drive.
 */
function getOrCreateFolder(name) {
  var folders = DriveApp.getFoldersByName(name);
  if (folders.hasNext()) {
    return folders.next();
  }
  Logger.log('Création du dossier Drive : ' + name);
  return DriveApp.createFolder(name);
}

/**
 * Récupère ou crée un label Gmail.
 */
function getOrCreateLabel(name) {
  var label = GmailApp.getUserLabelByName(name);
  if (!label) {
    label = GmailApp.createLabel(name);
    Logger.log('Label Gmail créé : ' + name);
  }
  return label;
}

/**
 * Vérifie si un fil possède déjà un label donné.
 */
function threadHasLabel(thread, labelName) {
  var labels = thread.getLabels();
  for (var i = 0; i < labels.length; i++) {
    if (labels[i].getName() === labelName) return true;
  }
  return false;
}

/**
 * Vérifie si un fichier existe déjà dans un dossier Drive.
 */
function fileExistsInFolder(folder, fileName) {
  var files = folder.getFilesByName(fileName);
  return files.hasNext();
}

/**
 * Génère un nom de fichier unique en ajoutant un suffixe _1, _2, etc.
 * Ex: rapport.csv → rapport_1.csv → rapport_2.csv
 */
function getUniqueFileName(folder, fileName) {
  var dotIndex = fileName.lastIndexOf('.');
  var baseName = dotIndex > 0 ? fileName.substring(0, dotIndex) : fileName;
  var extension = dotIndex > 0 ? fileName.substring(dotIndex) : '';
  var counter = 1;
  var newName = baseName + '_' + counter + extension;
  while (fileExistsInFolder(folder, newName)) {
    counter++;
    newName = baseName + '_' + counter + extension;
  }
  return newName;
}

/**
 * Vérifie si l'extension du fichier est autorisée.
 * Si allowedExtensions est vide, tout est accepté.
 */
function isAllowedExtension(fileName, allowedExtensions) {
  if (!allowedExtensions || allowedExtensions.length === 0) return true;
  var ext = fileName.split('.').pop().toLowerCase();
  return allowedExtensions.indexOf(ext) !== -1;
}

// =====================================================================
// Gestion des déclencheurs automatiques
// =====================================================================

/**
 * Installe un déclencheur quotidien (ex: chaque matin à 8h).
 * À exécuter une seule fois manuellement.
 */
function installDailyTrigger() {
  // Supprimer les anciens déclencheurs sur downloadAttachments
  ScriptApp.getProjectTriggers().forEach(function(trigger) {
    if (trigger.getHandlerFunction() === 'downloadAttachments') {
      ScriptApp.deleteTrigger(trigger);
    }
  });

  ScriptApp.newTrigger('downloadAttachments')
    .timeBased()
    .everyDays(1)
    .atHour(8)
    .create();

  Logger.log('Déclencheur quotidien installé (08h00).');
}

/**
 * Supprime tous les déclencheurs sur downloadAttachments.
 */
function removeTrigger() {
  ScriptApp.getProjectTriggers().forEach(function(trigger) {
    if (trigger.getHandlerFunction() === 'downloadAttachments') {
      ScriptApp.deleteTrigger(trigger);
      Logger.log('Déclencheur supprimé.');
    }
  });
}
