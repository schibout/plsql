'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const projectRoot = path.resolve(__dirname, '..');

function formatDate(date, timeZone, pattern) {
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone,
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit', hourCycle: 'h23',
  });
  const parts = Object.fromEntries(
    formatter.formatToParts(date)
      .filter(part => part.type !== 'literal')
      .map(part => [part.type, part.value])
  );
  return pattern
    .replace('yyyy', parts.year).replace('MM', parts.month).replace('dd', parts.day)
    .replace('HH', parts.hour).replace('mm', parts.minute).replace('ss', parts.second);
}

class MockBlob {
  constructor(name, contentType, entries = []) {
    this.name = name;
    this.contentType = contentType;
    this.entries = entries;
  }
  getName() { return this.name; }
  getContentType() { return this.contentType; }
  copyBlob() { return new MockBlob(this.name, this.contentType, this.entries); }
  setName(name) { this.name = name; return this; }
}

let nextFileId = 1;
class MockFile extends MockBlob {
  constructor(name, description = '') {
    super(name, 'text/csv');
    this.id = 'file-' + nextFileId++;
    this.description = description;
    this.trashed = false;
  }
  getId() { return this.id; }
  getDescription() { return this.description; }
  setDescription(value) { this.description = value; return this; }
  setTrashed(value) { this.trashed = value; return this; }
}

class MockFolder {
  constructor(files = []) { this.files = files; }
  getFilesByName(name) {
    const matches = this.files.filter(file => !file.trashed && file.getName() === name);
    let index = 0;
    return {
      hasNext: () => index < matches.length,
      next: () => matches[index++],
    };
  }
  createFile(blob) {
    const file = new MockFile(blob.getName());
    this.files.push(file);
    return file;
  }
}

class MockMessage {
  constructor(id, date, attachments) {
    this.id = id;
    this.date = date;
    this.attachments = attachments;
  }
  getId() { return this.id; }
  getDate() { return this.date; }
  getAttachments() { return this.attachments; }
}

const context = vm.createContext({
  console, Date, JSON, Object, String, Number, Array, RegExp, Error, isNaN,
  Logger: {log: () => {}},
  Utilities: {
    formatDate,
    unzip: blob => blob.entries.map(entry => entry.copyBlob()),
  },
});

const propertyStore = {};
context.propertyStore = propertyStore;
context.PropertiesService = {
  getScriptProperties: () => ({
    getProperty: key => propertyStore[key] || null,
    setProperty: (key, value) => { propertyStore[key] = value; },
  }),
};

[
  'Config.gs',
  'Utils.gs',
  'AttachmentService.gs',
  'DriveService.gs',
  'GmailService.gs',
  'Code.gs',
].forEach(fileName => {
  vm.runInContext(
    fs.readFileSync(path.join(projectRoot, fileName), 'utf8'),
    context,
    {filename: fileName}
  );
});

context.MockBlob = MockBlob;
context.MockFile = MockFile;
context.MockFolder = MockFolder;
context.MockMessage = MockMessage;

vm.runInContext(`
  function assert(condition, message) {
    if (!condition) throw new Error(message);
  }

  const csv = new MockBlob('folder/Report_ctm.csv', 'text/csv');
  const pdf = new MockBlob('notice.pdf', 'application/pdf');
  const zip = new MockBlob('rapport.zip', 'application/zip', [csv, pdf]);
  const message = new MockMessage(
    'message-1',
    new Date('2026-09-19T05:40:25.000Z'),
    [zip]
  );

  const extracted = ctmExtractSingleCsv_(message);
  assert(extracted.originalName === 'Report_ctm.csv', 'nom CSV extrait incorrect');

  const invalidZip = new MockBlob('deux-csv.zip', 'application/zip', [
    new MockBlob('a.csv', 'text/csv'),
    new MockBlob('b.csv', 'text/csv'),
  ]);
  let rejected = false;
  try {
    ctmExtractSingleCsv_(new MockMessage('message-2', message.getDate(), [invalidZip]));
  } catch (error) {
    rejected = /exactement un CSV/.test(error.message);
  }
  assert(rejected, 'un ZIP avec deux CSV doit être rejeté');

  const folder = new MockFolder();
  const firstSave = ctmSaveCsv_(folder, extracted, message);
  assert(firstSave.created === true, 'le premier fichier doit être créé');
  assert(firstSave.fileName === '20260919_074025_Report_ctm.csv', 'nom Drive incorrect');

  const secondSave = ctmSaveCsv_(folder, extracted, message);
  assert(secondSave.created === false, 'la relance doit réutiliser le fichier existant');
  assert(folder.files.length === 1, 'la relance ne doit pas créer de doublon');

  const collisionMessage = new MockMessage(
    'message-3',
    message.getDate(),
    [zip]
  );
  const collisionSave = ctmSaveCsv_(folder, extracted, collisionMessage);
  assert(collisionSave.fileName === '20260919_074025_Report_ctm_02.csv', 'suffixe collision incorrect');
  assert(folder.files.length === 2, 'la collision doit créer un second fichier distinct');

  const oversizedState = {
    lastSuccessfulRunIso: new Date().toISOString(),
    backfillComplete: false,
    backfillCursorMs: null,
    processed: {},
  };
  for (let index = 0; index < 300; index++) {
    oversizedState.processed['message-id-' + String(index).padStart(4, '0') + '-xxxxxxxx'] = Date.now();
  }
  assert(ctmSaveState_(oversizedState) === true, 'l’état doit être enregistré');
  const serializedState = propertyStore.CTM_IMPORT_STATE_V2;
  assert(serializedState.length <= 8000, 'l’état doit rester sous la marge de 8 000 caractères');
  assert(Object.keys(JSON.parse(serializedState).processed).length <= 200, 'le plafond d’ID doit être respecté');

  ctmExtractSingleCsv_ = function(messageToProcess) {
    if (messageToProcess.fail) throw new Error('échec simulé');
    return {blob: new MockBlob('rapport.csv', 'text/csv'), originalName: 'rapport.csv'};
  };
  ctmSaveCsv_ = function() {
    return {created: true, fileName: 'rapport.csv', file: null};
  };

  function makeItem(index, fail) {
    const receivedMs = new Date('2026-05-19T00:00:00.000Z').getTime() + index * 60000;
    const batchMessage = new MockMessage('batch-' + index, new Date(receivedMs), []);
    batchMessage.fail = fail === true;
    return {
      message: batchMessage,
      messageId: batchMessage.getId(),
      receivedMs: receivedMs,
    };
  }

  const batchItems = [];
  for (let index = 0; index < 45; index++) batchItems.push(makeItem(index, false));
  const batchState = {
    lastSuccessfulRunIso: null,
    backfillComplete: false,
    backfillCursorMs: null,
    processed: {},
  };
  const batchReport = {attempted: 0, created: 0, recovered: 0, alreadyProcessed: 0, errors: 0};
  const firstBatch = ctmProcessCandidateMessages_(
    batchItems, {}, batchState, 'backfill', batchReport
  );
  assert(firstBatch.deferred === 5, 'cinq messages doivent être différés après le premier lot');
  assert(Object.keys(batchState.processed).length === 40, 'le premier lot doit traiter quarante messages');
  assert(batchState.backfillCursorMs === batchItems[39].receivedMs, 'le curseur doit suivre le lot');

  const secondBatch = ctmProcessCandidateMessages_(
    batchItems, {}, batchState, 'backfill', batchReport
  );
  assert(secondBatch.deferred === 0, 'le second lot doit terminer le rattrapage');
  assert(Object.keys(batchState.processed).length === 45, 'les quarante-cinq messages doivent être traités');
  assert(batchState.backfillCursorMs === batchItems[44].receivedMs, 'le curseur final est incorrect');

  const failingItems = [makeItem(100, false), makeItem(101, true), makeItem(102, false)];
  const failingState = {
    lastSuccessfulRunIso: null,
    backfillComplete: false,
    backfillCursorMs: null,
    processed: {},
  };
  const failingReport = {attempted: 0, created: 0, recovered: 0, alreadyProcessed: 0, errors: 0};
  const failingBackfill = ctmProcessCandidateMessages_(
    failingItems, {}, failingState, 'backfill', failingReport
  );
  assert(failingBackfill.blocked === true, 'une erreur doit bloquer le curseur de rattrapage');
  assert(failingBackfill.deferred === 2, 'le message en erreur et le suivant doivent être différés');
  assert(!failingState.processed['batch-102'], 'le rattrapage ne doit pas dépasser le message en erreur');

  console.log('SERVICE TESTS: 17/17 réussis.');
`, context, {filename: 'service-tests'});
