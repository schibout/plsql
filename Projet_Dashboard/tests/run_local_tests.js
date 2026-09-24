// Tests hors Apps Script : node tests/run_local_tests.js
const assert = require('assert');
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const root = path.join(__dirname, '..');
const ctx = {
  // Substitut minimal de Utilities.parseCsv (pas de guillemets dans les jeux de test).
  Utilities: {parseCsv: text => text.split(/\r?\n/).map(line => line.split(','))},
};
vm.createContext(ctx);
['Config.gs', 'Code.gs'].forEach(f => vm.runInContext(fs.readFileSync(path.join(root, f), 'utf8'), ctx));
const run = code => vm.runInContext(code, ctx);

// Parse : BOM, lignes vides de SPOOL et espaces retires.
ctx.sample = '﻿\r\n"KPI","VALEUR"\r\nFlux DSP, 5 \r\n\r\n';
const table = run('dashboardParseCsv_(sample)');
assert.deepStrictEqual(Array.from(table.header), ['"KPI"', '"VALEUR"']);
assert.deepStrictEqual(table.rows.map(r => Array.from(r)), [['Flux DSP', '5']]);
assert.strictEqual(run('dashboardParseCsv_("")').rows.length, 0);

// Chaque requete de sql\ a sa section dans Config.gs, et inversement.
const sqlFiles = fs.readdirSync(path.join(root, 'sql'))
  .filter(f => /^\d.*\.sql$/.test(f)).map(f => f.replace(/\.sql$/, '.csv')).sort();
const configured = run('[DASHBOARD_KPI_FILE].concat(DASHBOARD_SECTIONS.map(s => s.file))');
assert.deepStrictEqual(Array.from(configured).sort(), sqlFiles);

console.log('OK - ' + sqlFiles.length + ' requetes, parse CSV valide.');
