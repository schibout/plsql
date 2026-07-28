// =====================================================================
// Analyse des chaînes Control-M FIN-FINANCE
// =====================================================================
// Lit tous les CSV du dossier 'Report_CTM/Extraits' dans Google Drive,
// filtre Application = FIN-FINANCE, et génère un rapport Google Sheets.
//
// Rapport :
//   Onglet 1 — Synthèse par chaîne : nb exécutions, taux succès, durée
//   Onglet 2 — Détail quotidien : toutes les lignes FIN-FINANCE
//   Onglet 3 — Chaînes en erreur
// =====================================================================

var REPORT_CONFIG = {
  sourceFolderName: 'Report_CTM',
  extractSubFolder: 'Extraits',
  applicationFilter: 'FIN-FINANCE',
  reportName: 'Rapport_Chaines_FIN-FINANCE',
  delimiter: ';'
};

// =====================================================================
// Fonction principale
// =====================================================================
function generateFinanceReport() {
  // 1. Récupérer le dossier des extraits
  var sourceFolder = DriveApp.getFoldersByName(REPORT_CONFIG.sourceFolderName);
  if (!sourceFolder.hasNext()) {
    Logger.log('ERREUR : dossier "' + REPORT_CONFIG.sourceFolderName + '" introuvable.');
    return;
  }
  var extractFolder = sourceFolder.next().getFoldersByName(REPORT_CONFIG.extractSubFolder);
  if (!extractFolder.hasNext()) {
    Logger.log('ERREUR : sous-dossier "' + REPORT_CONFIG.extractSubFolder + '" introuvable.');
    return;
  }
  var folder = extractFolder.next();

  // 2. Lire tous les CSV
  var allRows = [];
  var csvFiles = folder.getFilesByType('text/csv');
  var fileCount = 0;

  while (csvFiles.hasNext()) {
    var file = csvFiles.next();
    fileCount++;
    var content = file.getBlob().getDataAsString('UTF-8');
    var lines = content.split('\n');

    // Ignorer l'en-tête (ligne 0) et les lignes vides
    for (var i = 1; i < lines.length; i++) {
      var line = lines[i].trim();
      if (!line) continue;

      var cols = parseCsvLine(line, REPORT_CONFIG.delimiter);
      var app = cols[0];

      if (app === REPORT_CONFIG.applicationFilter) {
        allRows.push({
          application:  cols[0],
          groupName:    cols[1],
          jobName:      cols[2],
          odate:        cleanQuotes(cols[3]),
          startTime:    cleanQuotes(cols[4]),
          endTime:      cleanQuotes(cols[5]),
          runTime:      cols[6],
          status:       cols[7],
          description:  cols[8],
          memberName:   cols[9],
          taskType:     cols[10],
          deleted:      cols[11],
          rerunCounter: cols[12],
          cyclic:       cols[13],
          ctmName:      cols[14],
          table:        cols[15],
          runAsUser:    cols[16],
          hostname:     cols[17],
          nodegroup:    cols[18],
          orderId:      cols[19]
        });
      }
    }
  }

  Logger.log('Fichiers CSV lus : ' + fileCount);
  Logger.log('Lignes FIN-FINANCE : ' + allRows.length);

  if (allRows.length === 0) {
    Logger.log('Aucune donnée FIN-FINANCE trouvée.');
    return;
  }

  // 3. Créer le classeur Google Sheets
  var ss = SpreadsheetApp.create(REPORT_CONFIG.reportName);
  Logger.log('Rapport créé : ' + ss.getUrl());

  // --- Onglet 1 : Synthèse par chaîne ---
  buildSynthesisSheet(ss, allRows);

  // --- Onglet 2 : Détail quotidien ---
  buildDetailSheet(ss, allRows);

  // --- Onglet 3 : Chaînes en erreur ---
  buildErrorSheet(ss, allRows);

  // Supprimer la feuille vide par défaut
  var defaultSheet = ss.getSheetByName('Feuille 1') || ss.getSheetByName('Sheet1');
  if (defaultSheet) {
    ss.deleteSheet(defaultSheet);
  }

  Logger.log('Rapport terminé : ' + ss.getUrl());
}

// =====================================================================
// Onglet 1 : Synthèse par chaîne (Group Name)
// =====================================================================
function buildSynthesisSheet(ss, allRows) {
  var sheet = ss.insertSheet('Synthèse par chaîne');

  // Agréger par Group Name
  var chainMap = {};
  allRows.forEach(function(row) {
    var key = row.groupName;
    if (!chainMap[key]) {
      chainMap[key] = {
        groupName: key,
        totalJobs: 0,
        endedOk: 0,
        errors: 0,
        executing: 0,
        waitEvent: 0,
        totalRunTime: 0,
        runTimeCount: 0,
        dates: {},
        descriptions: {}
      };
    }
    var c = chainMap[key];
    c.totalJobs++;

    if (row.status === 'Ended OK') c.endedOk++;
    else if (row.status === 'Ended Not OK') c.errors++;
    else if (row.status === 'Executing') c.executing++;
    else if (row.status === 'Wait for Event') c.waitEvent++;

    if (row.runTime && !isNaN(Number(row.runTime))) {
      c.totalRunTime += Number(row.runTime);
      c.runTimeCount++;
    }

    // Compter les dates distinctes
    if (row.odate) c.dates[row.odate] = true;

    // Garder la première description trouvée
    if (row.description && !c.descriptions[row.description]) {
      c.descriptions[row.description] = true;
    }
  });

  // Construire les données
  var headers = [
    'Chaîne (Group Name)', 'Description', 'Nb Jobs Total',
    'Ended OK', 'Erreurs', 'En cours', 'Wait Event',
    'Taux Succès (%)', 'Durée Moy (sec)', 'Nb Jours Exécutés'
  ];

  var data = [headers];
  var chains = Object.keys(chainMap).sort();

  chains.forEach(function(key) {
    var c = chainMap[key];
    var tauxSucces = c.totalJobs > 0 ? Math.round((c.endedOk / c.totalJobs) * 100 * 10) / 10 : 0;
    var dureeMoy = c.runTimeCount > 0 ? Math.round(c.totalRunTime / c.runTimeCount) : '';
    var descriptions = Object.keys(c.descriptions).join(' | ');
    var nbJours = Object.keys(c.dates).length;

    data.push([
      c.groupName, descriptions, c.totalJobs,
      c.endedOk, c.errors, c.executing, c.waitEvent,
      tauxSucces, dureeMoy, nbJours
    ]);
  });

  sheet.getRange(1, 1, data.length, headers.length).setValues(data);

  // Mise en forme
  var headerRange = sheet.getRange(1, 1, 1, headers.length);
  headerRange.setFontWeight('bold');
  headerRange.setBackground('#4472C4');
  headerRange.setFontColor('#FFFFFF');
  sheet.setFrozenRows(1);
  sheet.autoResizeColumns(1, headers.length);
}

// =====================================================================
// Onglet 2 : Détail quotidien
// =====================================================================
function buildDetailSheet(ss, allRows) {
  var sheet = ss.insertSheet('Détail quotidien');

  var headers = [
    'Date (Odate)', 'Chaîne (Group Name)', 'Job Name', 'Description',
    'Heure Début', 'Heure Fin', 'Durée (sec)', 'Statut',
    'Member Name', 'Hostname', 'Run As User', 'Cyclic', 'Rerun'
  ];

  var data = [headers];

  // Trier par date puis chaîne puis job
  allRows.sort(function(a, b) {
    var da = a.odate || '';
    var db = b.odate || '';
    if (da !== db) return da.localeCompare(db);
    if (a.groupName !== b.groupName) return a.groupName.localeCompare(b.groupName);
    return (a.jobName || '').localeCompare(b.jobName || '');
  });

  allRows.forEach(function(row) {
    data.push([
      row.odate, row.groupName, row.jobName, row.description,
      row.startTime, row.endTime, row.runTime, row.status,
      row.memberName, row.hostname, row.runAsUser, row.cyclic, row.rerunCounter
    ]);
  });

  // Google Sheets limite ~5M cellules ; tronquer si nécessaire
  var maxRows = Math.min(data.length, 50000);
  if (data.length > maxRows) {
    Logger.log('ATTENTION : détail tronqué à ' + maxRows + ' lignes (sur ' + data.length + ')');
  }

  sheet.getRange(1, 1, maxRows, headers.length).setValues(data.slice(0, maxRows));

  var headerRange = sheet.getRange(1, 1, 1, headers.length);
  headerRange.setFontWeight('bold');
  headerRange.setBackground('#4472C4');
  headerRange.setFontColor('#FFFFFF');
  sheet.setFrozenRows(1);
  sheet.autoResizeColumns(1, headers.length);

  // Colorer les erreurs en rouge
  if (maxRows > 1) {
    var statusCol = 8; // colonne H = Status
    var statusRange = sheet.getRange(2, statusCol, maxRows - 1, 1);
    var rule = SpreadsheetApp.newConditionalFormatRule()
      .whenTextEqualTo('Ended Not OK')
      .setBackground('#FFC7CE')
      .setFontColor('#9C0006')
      .setRanges([statusRange])
      .build();
    var rules = sheet.getConditionalFormatRules();
    rules.push(rule);
    sheet.setConditionalFormatRules(rules);
  }
}

// =====================================================================
// Onglet 3 : Chaînes en erreur
// =====================================================================
function buildErrorSheet(ss, allRows) {
  var sheet = ss.insertSheet('Erreurs');

  var errorRows = allRows.filter(function(row) {
    return row.status === 'Ended Not OK';
  });

  var headers = [
    'Date (Odate)', 'Chaîne (Group Name)', 'Job Name', 'Description',
    'Heure Début', 'Heure Fin', 'Statut', 'Hostname', 'Rerun'
  ];

  var data = [headers];

  if (errorRows.length === 0) {
    data.push(['Aucune erreur détectée sur la période', '', '', '', '', '', '', '', '']);
  } else {
    errorRows.sort(function(a, b) {
      return (a.odate || '').localeCompare(b.odate || '');
    });

    errorRows.forEach(function(row) {
      data.push([
        row.odate, row.groupName, row.jobName, row.description,
        row.startTime, row.endTime, row.status, row.hostname, row.rerunCounter
      ]);
    });
  }

  sheet.getRange(1, 1, data.length, headers.length).setValues(data);

  var headerRange = sheet.getRange(1, 1, 1, headers.length);
  headerRange.setFontWeight('bold');
  headerRange.setBackground('#C00000');
  headerRange.setFontColor('#FFFFFF');
  sheet.setFrozenRows(1);
  sheet.autoResizeColumns(1, headers.length);
}

// =====================================================================
// Utilitaires CSV
// =====================================================================

function parseCsvLine(line, delimiter) {
  var result = [];
  var current = '';
  var inQuotes = false;

  for (var i = 0; i < line.length; i++) {
    var ch = line[i];
    if (ch === '"') {
      inQuotes = !inQuotes;
    } else if (ch === delimiter && !inQuotes) {
      result.push(current.trim());
      current = '';
    } else {
      current += ch;
    }
  }
  result.push(current.trim());
  return result;
}

function cleanQuotes(val) {
  if (!val) return '';
  return val.replace(/^"|"$/g, '').trim();
}
