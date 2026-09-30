/** Point d'entree de l'application web. */
function doGet() {
  const page = HtmlService.createTemplateFromFile('Index');
  page.config = Object.assign({KPI_LINKS: DASHBOARD_KPI_LINKS, DEMAT: DASHBOARD_DEMAT}, DASHBOARD_CONFIG);
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
 * CSV (separateur ';') -> {header, rows}. Retire le BOM et les lignes vides,
 * en-tetes mis en majuscules (les noms de colonnes de Index.html le sont).
 * @private
 */
function dashboardParseCsv_(text) {
  const lines = Utilities.parseCsv(String(text).replace(/^﻿/, ''), ';')
    .map(function(row) { return row.map(function(cell) { return cell.trim(); }); })
    .filter(function(row) { return row.some(function(cell) { return cell !== ''; }); });
  return {header: (lines[0] || []).map(function(h) { return h.toUpperCase(); }), rows: lines.slice(1)};
}

/** Declencheur quotidien : envoie la synthese aux destinataires de DASHBOARD_MAIL. */
function envoyerMailSynthese() {
  if (!DASHBOARD_MAIL.TO.length) return;
  const data = getDashboardData();
  MailApp.sendEmail({
    to: DASHBOARD_MAIL.TO.join(','),
    subject: dashboardMailSubject_(data),
    htmlBody: dashboardMailHtml_(data, ScriptApp.getService().getUrl()),
  });
}

/** A lancer une fois depuis l'editeur : (re)cree le declencheur quotidien. */
function installerMailQuotidien() {
  ScriptApp.getProjectTriggers()
    .filter(function(t) { return t.getHandlerFunction() === 'envoyerMailSynthese'; })
    .forEach(function(t) { ScriptApp.deleteTrigger(t); });
  ScriptApp.newTrigger('envoyerMailSynthese').timeBased().everyDays(1).atHour(DASHBOARD_MAIL.HOUR).create();
}

/** @private Objet : pire statut des tuiles (KO > W > OK). */
function dashboardMailSubject_(data) {
  const st = dashboardKpiRows_(data.kpi).map(function(k) { return k.statut; });
  const pire = st.indexOf('KO') >= 0 ? 'KO' : st.indexOf('W') >= 0 ? 'W' : 'OK';
  return '[' + pire + '] ' + DASHBOARD_CONFIG.TITLE;
}

/** @private Corps HTML : tuiles, sections a traiter, fichiers absents ou perimes, lien. */
function dashboardMailHtml_(data, url) {
  const esc = function(s) {
    return String(s).replace(/[&<>"]/g, function(c) { return {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;'}[c]; });
  };
  const color = {OK: '#1e8e3e', W: '#e37400', KO: '#d93025'};
  const tuiles = dashboardKpiRows_(data.kpi).map(function(k) {
    return '<tr><td>' + esc(k.kpi) + '</td><td align="right">' + esc(k.valeur) + '</td>' +
      '<td style="color:' + (color[k.statut] || '#000') + ';font-weight:bold">' + esc(k.statut) + '</td></tr>';
  }).join('');
  const now = new Date(data.generatedAt).getTime();
  const all = [Object.assign({title: 'Synthese (' + DASHBOARD_KPI_FILE + ')'}, data.kpi)].concat(data.sections);
  const points = data.sections
    .filter(function(s) { return s.alertIfRows && s.rows.length; })
    .map(function(s) { return esc(s.title) + ' : ' + s.rows.length + ' ligne(s) a traiter'; })
    .concat(all.filter(function(s) { return s.missing; }).map(function(s) { return esc(s.title) + ' : fichier absent'; }))
    .concat(all.filter(function(s) { return !s.missing && now - new Date(s.updated).getTime() > DASHBOARD_CONFIG.STALE_HOURS * 3600e3; })
      .map(function(s) { return esc(s.title) + ' : fichier perime'; }));
  return '<h2>' + esc(DASHBOARD_CONFIG.TITLE) + '</h2>' +
    '<table cellpadding="4" style="border-collapse:collapse">' + tuiles + '</table>' +
    (points.length ? '<h3>A traiter</h3><ul><li>' + points.join('</li><li>') + '</li></ul>' : '<p>Rien a traiter.</p>') +
    (url ? '<p><a href="' + esc(url) + '">Ouvrir le dashboard</a></p>' : '');
}

/** @private Lignes de 00_kpi.csv -> [{kpi, valeur, statut}]. */
function dashboardKpiRows_(kpi) {
  const i = function(n) { return kpi.header.indexOf(n); };
  return kpi.rows.map(function(r) { return {kpi: r[i('KPI')], valeur: r[i('VALEUR')], statut: r[i('STATUT')]}; });
}
