// Tests hors Apps Script : node tests/run_local_tests.js
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.join(__dirname, '..');
const ctx = {Utilities: {parseCsv: require('./parse_csv')}};
vm.createContext(ctx);
['Config.gs', 'Code.gs'].forEach(f => vm.runInContext(fs.readFileSync(path.join(root, f), 'utf8'), ctx));
const run = code => vm.runInContext(code, ctx);

// Parse : BOM, lignes vides et espaces retires, separateur ";" et guillemets, en-tetes en majuscules.
ctx.sample = '﻿\r\n"kpi";"valeur"\r\n"Flux; DSP"; 5 \r\n\r\n';
const table = run('dashboardParseCsv_(sample)');
assert.deepStrictEqual(Array.from(table.header), ['KPI', 'VALEUR']);
assert.deepStrictEqual(table.rows.map(r => Array.from(r)), [['Flux; DSP', '5']]);
assert.strictEqual(run('dashboardParseCsv_("")').rows.length, 0);

// Chaque requete de sql\ a sa section dans Config.gs, et inversement.
const sqlFiles = fs.readdirSync(path.join(root, 'sql'))
  .filter(f => /^\d.*\.sql$/.test(f)).map(f => f.replace(/\.sql$/, '.csv')).sort();
const configured = run('[DASHBOARD_KPI_FILE].concat(DASHBOARD_SECTIONS.map(s => s.file))');
assert.deepStrictEqual(Array.from(configured).sort(), sqlFiles);

// Tuiles cliquables : chaque KPI de 00_kpi.sql a ses sections, et elles existent.
const kpiSql = fs.readFileSync(path.join(root, 'sql', '00_kpi.sql'), 'utf8');
const kpiNames = [...kpiSql.matchAll(/SELECT \d+,?\s+(?:AS ORDRE, )?'([^']+)'/g)].map(m => m[1]);
assert.strictEqual(kpiNames.length, 13, 'KPI trouves dans 00_kpi.sql : ' + kpiNames);
const links = run('DASHBOARD_KPI_LINKS');
assert.deepStrictEqual(Object.keys(links).sort(), kpiNames.sort());
Object.values(links).forEach(files => files.forEach(f => assert.ok(configured.includes(f), f)));

// Les graphiques (Index.html) lisent ces colonnes : elles doivent exister dans les CSV d'exemple.
const REQUIRED = {
  '00_kpi.csv': ['ORDRE', 'KPI', 'VALEUR', 'STATUT'],
  '01_dsp_flux.csv': ['DATE_CR', 'TYPE_FLUX', 'FILE_NAME'],
  '02_dsp_synthese.csv': ['DATE_CR', 'JOUR', 'TOTAL'],
  '03_ndf_notilus.csv': ['DATE_CR', 'JOUR', 'NB_NDF', 'MONTANT_TOT'],
  '04_factures_source.csv': ['DATE_CR', 'SOURCE', 'NB_FACS'],
  '05_xerox_sans_image.csv': ['AGE_J', 'FOURNISSEUR', 'NUM_FACT', 'MONTANT'],
  '06_xerox_avec_image.csv': ['NB_AVEC_IMG'],
  '07_fac_ar_recues.csv': ['ORIGINE', 'STATUT_OA', 'NB_FACTURES'],
  '09_gl_interface.csv': ['SOURCE', 'STATUS_GL', 'NB_LIGNES', 'AGE_J'],
  '10_gl_lignes.csv': ['DATE_CR', 'SOURCE', 'NB_LIGNES'],
  '11_nuit_synthese.csv': ['STATUT', 'NB'],
  '13_nuit_erreurs_detail.csv': ['REQ_ID', 'PROGRAMME', 'DEBUT', 'DUREE_MIN'],
  '14_nuit_warnings.csv': ['REQ_ID', 'PROGRAMME', 'DEBUT', 'DUREE_MIN'],
  '15_nuit_longs.csv': ['REQ_ID', 'PROGRAMME', 'DEBUT', 'DUREE_MIN', 'STATUT'],
  '16_nuit_en_cours.csv': ['REQ_ID', 'PROGRAMME', 'DEBUT', 'DUREE_MIN'],
  '17_rb_imports.csv': ['DATE_CR', 'JOUR', 'NB_CTES'],
  '18_demat_statut.csv': ['STATUT', 'NB'],
  '19_demat_par_jour.csv': ['DATE_CR', 'JOUR', 'NB_INSERE', 'NB_INTEGREE', 'NB_COMPLETED', 'TOTAL'],
};
const csvDir = path.join(__dirname, 'Dashboard_CSV');
Object.keys(REQUIRED).forEach(file => {
  const p = path.join(csvDir, file);
  assert.ok(fs.existsSync(p), 'CSV d\'exemple absent : ' + file);
  ctx.csv = fs.readFileSync(p, 'utf8');
  const header = Array.from(run('dashboardParseCsv_(csv).header'));
  REQUIRED[file].forEach(c => assert.ok(header.includes(c), file + ' : colonne ' + c + ' absente (' + header.join(',') + ')'));
});

// Mail : objet = pire statut, sections a traiter / absentes / perimees listees, HTML echappe.
ctx.mailData = {
  generatedAt: '2026-10-01T08:00:00Z',
  kpi: Object.assign(run('dashboardParseCsv_(' + JSON.stringify(fs.readFileSync(path.join(csvDir, '00_kpi.csv'), 'utf8')) + ')'), {updated: '2026-10-01T07:30:00Z'}),
  sections: [
    {title: 'Rejets <AR>', alertIfRows: true, rows: [['x']], updated: '2026-10-01T07:30:00Z'},
    {title: 'Vide', alertIfRows: true, rows: [], updated: '2026-10-01T07:30:00Z'},
    {title: 'Absent', missing: true, rows: []},
    {title: 'Vieux', rows: [], updated: '2026-09-30T08:00:00Z'},
  ],
};
assert.strictEqual(run('dashboardMailSubject_(mailData)'), '[KO] ' + run('DASHBOARD_CONFIG.TITLE'));
const mail = run('dashboardMailHtml_(mailData, "https://x/exec")');
['Rejets &lt;AR&gt; : 1 ligne(s)', 'Absent : fichier absent', 'Vieux : fichier perime', 'Images Xerox manquantes', 'https://x/exec']
  .forEach(s => assert.ok(mail.includes(s), 'mail sans : ' + s));
assert.ok(!mail.includes('Vide'));

console.log('OK - ' + sqlFiles.length + ' requetes, parse CSV valide, mail.');
