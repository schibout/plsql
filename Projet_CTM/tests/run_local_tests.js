'use strict';

const fs = require('fs');
const path = require('path');
const vm = require('vm');

const projectRoot = path.resolve(__dirname, '..');

function formatDate(date, timeZone, pattern) {
  const formatter = new Intl.DateTimeFormat('en-GB', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  });
  const parts = Object.fromEntries(
    formatter.formatToParts(date)
      .filter(part => part.type !== 'literal')
      .map(part => [part.type, part.value])
  );

  return pattern
    .replace('yyyy', parts.year)
    .replace('MM', parts.month)
    .replace('dd', parts.day)
    .replace('HH', parts.hour)
    .replace('mm', parts.minute)
    .replace('ss', parts.second);
}

const context = vm.createContext({
  console,
  Date,
  JSON,
  Object,
  String,
  Number,
  Array,
  RegExp,
  Error,
  isNaN,
  Utilities: {formatDate},
  Logger: {
    log: (...args) => console.log(...args),
  },
});

['Config.gs', 'Utils.gs', 'GmailService.gs', 'Tests.gs'].forEach(fileName => {
  const source = fs.readFileSync(path.join(projectRoot, fileName), 'utf8');
  vm.runInContext(source, context, {filename: fileName});
});

vm.runInContext('runCtmUnitTests();', context, {filename: 'run_local_tests.js'});
