// =====================================================================
// SCRIPT DE MISE À JOUR DE CLÔTURE COMPTABLE
// =====================================================================
// Paramètres configurables pour les déclencheurs
// =====================================================================

const CONFIG = {
  FOLDER_ID: "1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl",  // ID du dossier Drive
  OLD_PERIOD: "DEC-25",                             // Période actuelle
  NEW_PERIOD: "JAN-26"                              // Nouvelle période
};

// =====================================================================
// FONCTION PRINCIPALE AVEC PARAMÈTRES
// =====================================================================

function UpdateCloture(oldPeriod = CONFIG.OLD_PERIOD, newPeriod = CONFIG.NEW_PERIOD, folderId = CONFIG.FOLDER_ID) {
  try {
    Logger.log('=== MISE À JOUR CLÔTURE COMPTABLE ===');
    Logger.log('Dossier cible : ' + folderId);
    Logger.log('Remplacement : ' + oldPeriod + ' → ' + newPeriod);
    Logger.log('Date/Heure : ' + new Date());
    Logger.log('');
    
    var folder = DriveApp.getFolderById(folderId);
    var files = folder.searchFiles('mimeType contains "SQL"');
    
    var updated_count = 0;
    var skipped_count = 0;
    var error_count = 0;
    
    while (files.hasNext()) {
      try {
        var file = files.next();
        var file_blob = file.getBlob();
        var text = file_blob.getDataAsString();
        
        // Vérifier si la période existe
        if (text.includes(oldPeriod)) {
          var updated_text = text.split(oldPeriod).join(newPeriod);
          file.setContent(updated_text);
          
          Logger.log('✓ Mis à jour : ' + file.getName());
          updated_count++;
        } else {
          Logger.log('⚠ Aucune référence ' + oldPeriod + ' : ' + file.getName());
          skipped_count++;
        }
      } catch (fileError) {
        Logger.log('✗ ERREUR fichier : ' + file.getName() + ' - ' + fileError.toString());
        error_count++;
      }
    }
    
    Logger.log('');
    Logger.log('=== RÉSUMÉ ===');
    Logger.log('✓ Fichiers mis à jour : ' + updated_count);
    Logger.log('⚠ Fichiers ignorés : ' + skipped_count);
    Logger.log('✗ Erreurs : ' + error_count);
    Logger.log('Total traité : ' + (updated_count + skipped_count + error_count));
    
  } catch (error) {
    Logger.log('ERREUR FATALE : ' + error.toString());
  }
}

// =====================================================================
// FONCTIONS DE DÉCLENCHEMENT PRÉDÉFINIES
// =====================================================================

// Déclencheur pour mise à jour DEC-25 → JAN-26
function TriggerDEC25ToJAN26() {
  UpdateCloture("DEC-25", "JAN-26", CONFIG.FOLDER_ID);
}

// Déclencheur pour mise à jour JAN-26 → FEB-26
function TriggerJAN26ToFEB26() {
  UpdateCloture("JAN-26", "FEB-26", CONFIG.FOLDER_ID);
}

// Déclencheur personnalisé (à adapter)
function TriggerCustom(oldPeriod, newPeriod) {
  UpdateCloture(oldPeriod, newPeriod, CONFIG.FOLDER_ID);
}

// =====================================================================
// GESTION DES DÉCLENCHEURS
// =====================================================================

// Créer un déclencheur pour exécution programmée
function CreateScheduleTrigger(triggerFunction, hourOfDay = 2) {
  try {
    // Supprimer les anciens déclencheurs
    var triggers = ScriptApp.getProjectTriggers();
    for (var i = 0; i < triggers.length; i++) {
      if (triggers[i].getHandlerFunction() === triggerFunction) {
        ScriptApp.deleteTrigger(triggers[i]);
      }
    }
    
    // Créer un nouveau déclencheur quotidien à l'heure spécifiée
    ScriptApp.newTrigger(triggerFunction)
      .timeBased()
      .atHour(hourOfDay)
      .everyDays(1)
      .create();
    
    Logger.log('✓ Déclencheur créé : ' + triggerFunction + ' à ' + hourOfDay + ':00');
  } catch (error) {
    Logger.log('✗ ERREUR création déclencheur : ' + error.toString());
  }
}

// Lister tous les déclencheurs actifs
function ListActiveTriggers() {
  var triggers = ScriptApp.getProjectTriggers();
  Logger.log('=== DÉCLENCHEURS ACTIFS ===');
  
  if (triggers.length === 0) {
    Logger.log('Aucun déclencheur actif');
    return;
  }
  
  for (var i = 0; i < triggers.length; i++) {
    var trigger = triggers[i];
    Logger.log(i + 1 + '. Fonction : ' + trigger.getHandlerFunction() + 
               ' | Type : ' + trigger.getTriggerSource() + 
               ' | ID : ' + trigger.getUniqueId());
  }
}

// Supprimer tous les déclencheurs
function RemoveAllTriggers() {
  var triggers = ScriptApp.getProjectTriggers();
  
  for (var i = 0; i < triggers.length; i++) {
    ScriptApp.deleteTrigger(triggers[i]);
  }
  
  Logger.log('✓ Tous les déclencheurs ont été supprimés');
}

// =====================================================================
// EXEMPLES D'UTILISATION
// =====================================================================

/*
// Exécution manuelle
UpdateCloture("DEC-25", "JAN-26", "1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl");

// Créer un déclencheur quotidien à 2h du matin
CreateScheduleTrigger("TriggerDEC25ToJAN26", 2);

// Lister les déclencheurs
ListActiveTriggers();

// Supprimer les déclencheurs
RemoveAllTriggers();
*/