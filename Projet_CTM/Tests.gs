/**
 * Tests unitaires légers, exécutables directement dans Google Apps Script.
 *
 * Exécuter runCtmUnitTests() depuis l'éditeur Apps Script. Ces tests portent
 * uniquement sur les fonctions pures ; les accès Gmail et Drive sont couverts
 * par la recette d'intégration décrite dans tests/TEST_CASES.md.
 */
function runCtmUnitTests() {
  const tests = [
    {
      name: 'formate la date du message dans le fuseau Europe/Paris',
      run: function() {
        const date = new Date('2026-09-19T05:40:25.000Z');
        ctmAssertEquals_('20260919_074025', ctmFormatTimestamp_(date, 'Europe/Paris'));
      },
    },
    {
      name: 'construit le nom final depuis la date de réception',
      run: function() {
        const date = new Date('2026-09-19T05:40:25.000Z');
        ctmAssertEquals_(
          '20260919_074025_Report_ctm.csv',
          ctmBuildFileName_(date, 'Report_ctm.csv', 'Europe/Paris')
        );
      },
    },
    {
      name: 'retire les chemins internes et les caractères de contrôle',
      run: function() {
        ctmAssertEquals_(
          'Report_ctm.csv',
          ctmSanitizeFileName_('../sous-dossier\\Report_ctm.csv\u0000')
        );
      },
    },
    {
      name: 'détecte une extension CSV sans tenir compte de la casse',
      run: function() {
        ctmAssertTrue_(ctmIsCsv_('REPORT_CTM.CSV', 'application/octet-stream'));
      },
    },
    {
      name: 'détecte un CSV grâce au type MIME',
      run: function() {
        ctmAssertTrue_(ctmIsCsv_('rapport_sans_extension', 'text/csv'));
      },
    },
    {
      name: 'refuse un PDF comme CSV',
      run: function() {
        ctmAssertFalse_(ctmIsCsv_('rapport.pdf', 'application/pdf'));
      },
    },
    {
      name: 'détecte un ZIP sans tenir compte de la casse',
      run: function() {
        ctmAssertTrue_(ctmIsZip_('Rapport.ZIP', 'application/octet-stream'));
      },
    },
    {
      name: 'ajoute le suffixe de collision avant extension',
      run: function() {
        ctmAssertEquals_(
          '20260919_074025_Report_ctm_02.csv',
          ctmAddCollisionSuffix_('20260919_074025_Report_ctm.csv', 2)
        );
      },
    },
    {
      name: 'extrait et normalise une adresse avec nom affiché',
      run: function() {
        ctmAssertEquals_(
          'indic_ctm@dalkia.fr',
          ctmExtractEmailAddress_('Indicateurs CTM <INDIC_CTM@DALKIA.FR>')
        );
      },
    },
    {
      name: 'construit une requête sans exclusion par libellé',
      run: function() {
        const query = ctmBuildSearchQuery_({
          SEARCH_QUERY: 'from:indic_ctm@dalkia.fr subject:"DALKIA / Extract CSV du Suivi Quotidien CTM"',
          SEARCH_WINDOW_DAYS: 30,
        }, new Date('2026-09-19T12:00:00.000Z'));
        ctmAssertContains_(query, 'after:2026/08/20');
        ctmAssertFalse_(query.indexOf('-label:') !== -1);
      },
    },
  ];

  let passed = 0;
  const failures = [];

  tests.forEach(function(test) {
    try {
      test.run();
      passed++;
      Logger.log('OK - %s', test.name);
    } catch (error) {
      failures.push(test.name + ' : ' + error.message);
      Logger.log('ECHEC - %s : %s', test.name, error.message);
    }
  });

  Logger.log('Résultat : %s/%s test(s) réussi(s).', passed, tests.length);
  if (failures.length > 0) {
    throw new Error('Tests CTM en échec :\n' + failures.join('\n'));
  }
}

function ctmAssertEquals_(expected, actual) {
  if (expected !== actual) {
    throw new Error('attendu=' + JSON.stringify(expected) + ', obtenu=' + JSON.stringify(actual));
  }
}

function ctmAssertTrue_(actual) {
  ctmAssertEquals_(true, actual);
}

function ctmAssertFalse_(actual) {
  ctmAssertEquals_(false, actual);
}

function ctmAssertContains_(actual, expectedPart) {
  if (String(actual).indexOf(expectedPart) === -1) {
    throw new Error(JSON.stringify(actual) + ' ne contient pas ' + JSON.stringify(expectedPart));
  }
}
