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
  constructor(name, contentType) {
    this.name = name;
    this.contentType = contentType;
  }
  getName() { return this.name; }
  getContentType() { return this.contentType; }
  copyBlob() { return new MockBlob(this.name, this.contentType); }
  setName(name) { this.name = name; return this; }
}

let nextId = 1;
class MockFile extends MockBlob {
  constructor(name) {
    super(name, 'application/octet-stream');
    this.id = 'file-' + nextId++;
    this.description = '';
    this.trashed = false;
  }
  getId() { return this.id; }
  getDescription() { return this.description; }
  setDescription(value) { this.description = value; return this; }
  setTrashed(value) { this.trashed = value; return this; }
}

class MockFolder {
  constructor(name) {
    this.name = name;
    this.files = [];
    this.folders = [];
  }
  getName() { return this.name; }
  getFilesByName(name) {
    const matches = this.files.filter(file => !file.trashed && file.getName() === name);
    let index = 0;
    return {hasNext: () => index < matches.length, next: () => matches[index++]};
  }
  getFoldersByName(name) {
    const matches = this.folders.filter(folder => folder.getName() === name);
    let index = 0;
    return {hasNext: () => index < matches.length, next: () => matches[index++]};
  }
  createFolder(name) {
    const folder = new MockFolder(name);
    this.folders.push(folder);
    return folder;
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

const propertyStore = {};
let lockReleased = false;
const context = vm.createContext({
  console, Date, JSON, Object, String, Number, Array, RegExp, Error, isNaN,
  Logger: {log: () => {}},
  Utilities: {formatDate},
  PropertiesService: {
    getScriptProperties: () => ({
      getProperty: key => propertyStore[key] || null,
      setProperty: (key, value) => { propertyStore[key] = value; },
    }),
  },
  LockService: {
    getScriptLock: () => ({
      tryLock: () => true,
      releaseLock: () => { lockReleased = true; },
    }),
  },
});

[
  'Config.gs', 'Utils.gs', 'GmailService.gs',
  'AttachmentService.gs', 'DriveService.gs', 'Code.gs',
].forEach(fileName => {
  vm.runInContext(
    fs.readFileSync(path.join(projectRoot, fileName), 'utf8'),
    context,
    {filename: fileName}
  );
});

context.MockBlob = MockBlob;
context.MockFolder = MockFolder;
context.MockMessage = MockMessage;
context.propertyStore = propertyStore;
context.getLockReleased = () => lockReleased;

vm.runInContext(`
  function assert(condition, message) {
    if (!condition) throw new Error(message);
  }

  const receivedAt = new Date('2026-09-21T06:32:00.000Z');
  const xls = new MockBlob('export/Liste des virements.xls', 'application/vnd.ms-excel');
  const xlsx = new MockBlob('Complement.XLSX', 'application/octet-stream');
  const image = new MockBlob('logo.png', 'image/png');
  const message = new MockMessage('message-1', receivedAt, [xls, xlsx, image]);
  const extraction = virementExtractExcelAttachments_(message);
  assert(extraction.candidates.length === 2, 'deux classeurs doivent être extraits');
  assert(extraction.skipped === 1, 'le logo doit être ignoré');
  assert(extraction.candidates[0].originalName === 'Liste des virements.xls',
    'le chemin interne doit être retiré');

  const parent = new MockFolder('Controle_Transfert');
  const dateFolder = virementGetDateFolder_(parent, receivedAt);
  assert(dateFolder.getName() === '21092026', 'nom du sous-dossier incorrect');
  assert(virementGetDateFolder_(parent, receivedAt) === dateFolder,
    'le sous-dossier existant doit être réutilisé');

  const first = virementSaveAttachment_(dateFolder, extraction.candidates[0], message);
  assert(first.created === true, 'le premier fichier doit être créé');
  assert(first.fileName === 'Liste des virements.xls', 'le nom original doit être conservé');

  const repeated = virementSaveAttachment_(dateFolder, extraction.candidates[0], message);
  assert(repeated.created === false, 'la relance doit réutiliser le fichier');
  assert(dateFolder.files.length === 1, 'la relance ne doit pas créer de doublon');

  const secondMessage = new MockMessage('message-2', receivedAt, [xls]);
  const collision = virementSaveAttachment_(
    dateFolder, extraction.candidates[0], secondMessage
  );
  assert(collision.fileName === 'Liste des virements_02.xls',
    'le second message doit recevoir le suffixe _02');
  assert(dateFolder.files.length === 2, 'la collision doit préserver deux fichiers');

  const state = {lastSuccessfulRunIso: receivedAt.toISOString(), processed: {}};
  for (let index = 0; index < 600; index++) {
    state.processed['message-' + String(index).padStart(4, '0') + '-xxxxxxxx'] = Date.now();
  }
  virementSaveState_(state);
  const serialized = propertyStore.VIREMENTS_EUR_IMPORT_STATE_V1;
  assert(serialized.length <= 8000, 'l’état doit rester sous 8 000 caractères');
  assert(Object.keys(JSON.parse(serialized).processed).length <= 500,
    'l’état doit conserver au plus 500 identifiants');

  function makeFlow(id, enabled) {
    return {
      ID: id,
      DISPLAY_NAME: id,
      ENABLED: enabled,
      FOLDER_ID: 'folder-' + id,
      SEARCH_QUERY: 'from:' + id + '@example.com',
      EXPECTED_SENDERS: [id + '@example.com'],
      EXPECTED_SUBJECT_PREFIXES: ['Rapport ' + id],
      ALLOWED_EXTENSIONS: ['csv'],
      LABEL_NAME: 'label-' + id,
      STATE_PROPERTY_KEY: 'state-' + id,
      DRIVE_MESSAGE_MARKER_PREFIX: 'marker-' + id + '=',
      TIME_ZONE: 'Europe/Paris',
      INITIAL_LOOKBACK_MONTHS: 4,
      DATE_OFFSET_DAYS: null,
      CREATE_DATE_SUBFOLDER: true,
      SUBFOLDER_DATE_FORMAT: 'ddMMyyyy',
      FILE_NAME_MODE: 'original',
      FILE_TIMESTAMP_FORMAT: 'yyyyMMdd_HHmm',
    };
  }

  const processedFlows = [];
  mailImportProcessFlow_ = function(flow) {
    processedFlows.push(flow.ID);
    if (flow.ID === 'flow_error') throw new Error('échec simulé');
    return mailImportEmptyReport_(flow);
  };
  let globalFailure = false;
  try {
    mailImportProcessConfiguredFlows_([
      makeFlow('flow_error', true),
      makeFlow('flow_disabled', false),
      makeFlow('flow_ok', true),
    ]);
  } catch (error) {
    globalFailure = /flow_error/.test(error.message);
  }
  assert(globalFailure, 'une erreur critique doit être signalée après les autres flux');
  assert(processedFlows.join(',') === 'flow_error,flow_ok',
    'les flux actifs suivants doivent continuer et le flux désactivé doit être ignoré');
  assert(getLockReleased(), 'le verrou global doit toujours être libéré');

  const csvFlow = makeFlow('csv_flow', true);
  const csvMessage = new MockMessage('csv-message', receivedAt, [
    new MockBlob('rapport.csv', 'text/csv'),
    new MockBlob('rapport.pdf', 'application/pdf'),
  ]);
  const csvExtraction = virementExtractAttachments_(csvMessage, csvFlow);
  assert(csvExtraction.candidates.length === 1, 'le profil CSV doit accepter son extension');
  assert(csvExtraction.skipped === 1, 'le profil CSV doit ignorer le PDF');

  const prelevementFlow = MAIL_IMPORT_FLOWS.filter(function(flow) {
    return flow.ID === 'prelevements';
  })[0];
  const prelevementParent = new MockFolder('Controle_Transfert');
  assert(
    virementGetDateFolder_(prelevementParent, receivedAt, prelevementFlow) ===
      prelevementParent,
    'le profil prélèvements doit écrire dans le dossier racine'
  );
  const prelevementSave = virementSaveAttachment_(
    prelevementParent,
    {blob: new MockBlob('rapport.csv', 'text/csv'), originalName: 'rapport.csv'},
    message,
    prelevementFlow
  );
  assert(prelevementSave.fileName === '20260921_0832_rapport.csv',
    'le profil prélèvements doit préfixer le nom avec l’horodatage de Paris');

  const isolatedA = makeFlow('isolated_a', true);
  const isolatedB = makeFlow('isolated_b', true);
  const isolatedState = {lastSuccessfulRunIso: null, processed: {same: Date.now()}};
  virementSaveState_(isolatedState, isolatedA);
  assert(virementIsProcessed_(virementLoadState_(isolatedA), 'same'),
    'le premier profil doit retrouver son état');
  assert(!virementIsProcessed_(virementLoadState_(isolatedB), 'same'),
    'le second profil ne doit pas partager l’état du premier');

  let aliasCalls = 0;
  processMailImports = function() {
    aliasCalls++;
    return ['delegated'];
  };
  const aliasResult = processVirementEmails();
  assert(aliasCalls === 1 && aliasResult[0] === 'delegated',
    'l’ancien point d’entrée doit déléguer au moteur multi-flux');

  console.log('SERVICE TESTS: tous réussis.');
`, context, {filename: 'service-tests'});
