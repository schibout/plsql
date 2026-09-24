// Apercu local du dashboard sans Apps Script : node tests/preview.js  puis ouvrir tests/preview.html
// Les donnees viennent des CSV d'exemple de tests/Dashboard_CSV (memes fichiers que ceux produits par export_csv.py).
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.join(__dirname, '..');
const csvDir = path.join(__dirname, 'Dashboard_CSV');
const ctx = {Utilities: {parseCsv: text => text.split(/\r?\n/).map(line => line.split(','))}};
vm.createContext(ctx);
['Config.gs', 'Code.gs'].forEach(f => vm.runInContext(fs.readFileSync(path.join(root, f), 'utf8'), ctx));
vm.runInContext('this.config = Object.assign({KPI_LINKS: DASHBOARD_KPI_LINKS, DEMAT: DASHBOARD_DEMAT}, DASHBOARD_CONFIG);' +
  'this.sections = DASHBOARD_SECTIONS; this.kpiFile = DASHBOARD_KPI_FILE; this.parse = dashboardParseCsv_;', ctx);

const now = new Date().toISOString();
function read(file) {
  const p = path.join(csvDir, file);
  if (!fs.existsSync(p)) return {missing: true, header: [], rows: []};
  const t = ctx.parse(fs.readFileSync(p, 'utf8'));
  return {header: Array.from(t.header), rows: t.rows.map(r => Array.from(r)), updated: now};
}
const data = {generatedAt: now, kpi: read(ctx.kpiFile), sections: Array.from(ctx.sections).map(s => Object.assign({}, s, read(s.file)))};

// google.script.run factice : renvoie les CSV lus ci-dessus.
const stub = '<script>window.google={script:{run:{withSuccessHandler(f){this.f=f;return this},withFailureHandler(){return this},' +
  'getDashboardData(){setTimeout(()=>this.f(' + JSON.stringify(data) + '))}}}};</script>';
const html = fs.readFileSync(path.join(root, 'Index.html'), 'utf8')
  .replace('<?= config.TITLE ?>', ctx.config.TITLE + ' (apercu local)')
  .replace('<?!= JSON.stringify(config) ?>', JSON.stringify(ctx.config))
  .replace('<script>', stub + '<script>');
const out = path.join(__dirname, 'preview.html');
fs.writeFileSync(out, html);
console.log('Apercu ecrit : ' + out + ' (' + data.sections.length + ' sections)');
