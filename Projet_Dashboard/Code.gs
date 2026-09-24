/** Point d'entree de l'application web. */
function doGet() {
  const page = HtmlService.createTemplateFromFile('Index');
  page.config = DASHBOARD_CONFIG;
  return page.evaluate()
    .setTitle(DASHBOARD_CONFIG.TITLE)
    .addMetaTag('viewport', 'width=device-width, initial-scale=1');
}

/** Appele par la page : lit tous les CSV du dossier Drive. */
function getDashboardData() {
  const folder = DriveApp.getFolderById(DASHBOARD_CONFIG.FOLDER_ID);
  return {
    generatedAt: new Date().toISOString(),
    kpi: dashboardReadCsv_(folder, DASHBOARD_KPI_FILE),
    sections: DASHBOARD_SECTIONS.map(function(section) {
      return Object.assign({}, section, dashboardReadCsv_(folder, section.file));
    }),
  };
}

/** @private */
function dashboardReadCsv_(folder, fileName) {
  const files = folder.getFilesByName(fileName);
  if (!files.hasNext()) return {missing: true, header: [], rows: []};
  const file = files.next();
  const table = dashboardParseCsv_(file.getBlob().getDataAsString('UTF-8'));
  table.updated = file.getLastUpdated().toISOString();
  return table;
}

/**
 * CSV SQL*Plus -> {header, rows}. Retire le BOM et les lignes vides que
 * SPOOL ajoute en tete et en fin de fichier.
 * @private
 */
function dashboardParseCsv_(text) {
  const lines = Utilities.parseCsv(String(text).replace(/^﻿/, ''))
    .map(function(row) { return row.map(function(cell) { return cell.trim(); }); })
    .filter(function(row) { return row.some(function(cell) { return cell !== ''; }); });
  return {header: lines[0] || [], rows: lines.slice(1)};
}
