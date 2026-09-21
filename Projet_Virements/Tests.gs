/** Tests unitaires sans accès Gmail ni Drive. */
function runVirementUnitTests() {
  const tests = [
    {
      name: 'déclare au moins un profil multi-flux actif',
      run: function() {
        virementAssertTrue_(MAIL_IMPORT_FLOWS.length >= 1);
        virementAssertEquals_('virements_eur', MAIL_IMPORT_FLOWS[0].ID);
        virementAssertEquals_(true, MAIL_IMPORT_FLOWS[0].ENABLED);
        MAIL_IMPORT_FLOWS.filter(function(flow) {
          return flow.ENABLED;
        }).forEach(function(flow) {
          virementAssertEquals_('timestamp_original', flow.FILE_NAME_MODE);
          virementAssertEquals_('ddMMyyyy', flow.FILE_TIMESTAMP_FORMAT);
        });
      },
    },
    {
      name: 'conserve les bornes d’exploitation multi-flux',
      run: function() {
        virementAssertEquals_(
          50,
          MAIL_IMPORT_ENGINE_CONFIG.MAX_MESSAGES_PER_FLOW_PER_RUN
        );
        virementAssertEquals_(
          500,
          MAIL_IMPORT_ENGINE_CONFIG.MAX_THREADS_PER_FLOW_PER_RUN
        );
        virementAssertEquals_(5000, MAIL_IMPORT_ENGINE_CONFIG.LOCK_WAIT_MS);
        virementAssertEquals_(8000, MAIL_IMPORT_ENGINE_CONFIG.MAX_STATE_JSON_CHARS);
        virementAssertEquals_(500, MAIL_IMPORT_ENGINE_CONFIG.MAX_PROCESSED_IDS);
        virementAssertEquals_(1, MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_INTERVAL_HOURS);
        virementAssertEquals_(
          'HOURLY_V1',
          MAIL_IMPORT_ENGINE_CONFIG.TRIGGER_SCHEDULE_VERSION
        );
      },
    },
    {
      name: 'refuse deux profils avec le même identifiant',
      run: function() {
        const first = virementTestFlow_('duplicated');
        const second = virementTestFlow_('duplicated');
        let rejected = false;
        try {
          mailImportValidateConfigs_([first, second]);
        } catch (error) {
          rejected = error.message.indexOf('duplicated') !== -1;
        }
        virementAssertTrue_(rejected);
      },
    },
    {
      name: 'déclare deux profils prélèvements indépendants',
      run: function() {
        const matches = MAIL_IMPORT_FLOWS.filter(function(flow) {
          return flow.ID.indexOf('prelevements_') === 0;
        });
        virementAssertEquals_(2, matches.length);
        matches.forEach(function(flow) {
          virementAssertTrue_(typeof flow.FOLDER_ID === 'string' &&
            flow.FOLDER_ID.length > 0);
          virementAssertEquals_(1, flow.EXPECTED_SUBJECT_PREFIXES.length);
          virementAssertEquals_(3, flow.DATE_OFFSET_DAYS);
          virementAssertEquals_(0, flow.ALLOWED_EXTENSIONS.length);
        });
        virementAssertTrue_(matches[0].STATE_PROPERTY_KEY !==
          matches[1].STATE_PROPERTY_KEY);
        virementAssertTrue_(matches[0].LABEL_NAME !== matches[1].LABEL_NAME);
        virementAssertTrue_(matches[0].DRIVE_MESSAGE_MARKER_PREFIX !==
          matches[1].DRIVE_MESSAGE_MARKER_PREFIX);
        virementAssertFalse_(matches[0].SEARCH_QUERY.indexOf(
          matches[1].EXPECTED_SUBJECT_PREFIXES[0]
        ) !== -1);
      },
    },
    {
      name: 'une liste d extensions vide accepte tous les fichiers',
      run: function() {
        virementAssertTrue_(virementIsAllowedAttachment_('rapport.csv', []));
        virementAssertTrue_(virementIsAllowedAttachment_('archive.zip', []));
      },
    },
    {
      name: 'construit une recherche exacte à J-3',
      run: function() {
        const flow = virementTestFlow_('j_moins_3');
        flow.DATE_OFFSET_DAYS = 3;
        const query = virementBuildSearchQuery_(
          flow,
          new Date('2026-09-21T12:00:00.000Z')
        );
        virementAssertContains_(query, 'after:2026/09/18');
        virementAssertContains_(query, 'before:2026/09/19');
      },
    },
    {
      name: 'le profil prélèvements accepte tout expéditeur mais seulement J-3',
      run: function() {
        const flow = MAIL_IMPORT_FLOWS.filter(function(candidate) {
          return candidate.ID === 'prelevements_cashcollection';
        })[0];
        const validMessage = {
          isInTrash: function() { return false; },
          isDraft: function() { return false; },
          getDate: function() { return new Date('2026-09-18T08:00:00.000Z'); },
          getFrom: function() { return 'nimporte.quel.robot@example.com'; },
          getSubject: function() { return flow.EXPECTED_SUBJECT_PREFIXES[0]; },
        };
        const reference = new Date('2026-09-21T12:00:00.000Z');
        virementAssertEquals_(
          'matched',
          virementGetMessageMatchResult_(
            validMessage,
            new Date('2026-05-21T00:00:00.000Z'),
            flow,
            reference
          ).reason
        );
        validMessage.getDate = function() {
          return new Date('2026-09-17T08:00:00.000Z');
        };
        virementAssertEquals_(
          'date',
          virementGetMessageMatchResult_(
            validMessage,
            new Date('2026-05-21T00:00:00.000Z'),
            flow,
            reference
          ).reason
        );
      },
    },
    {
      name: 'le profil prélèvements préfixe le nom avec DDMMYYYY',
      run: function() {
        const flow = MAIL_IMPORT_FLOWS.filter(function(candidate) {
          return candidate.ID === 'prelevements_cashcollection';
        })[0];
        virementAssertEquals_(
          '18092026_rapport.csv',
          mailImportBuildOutputFileName_(
            'rapport.csv',
            new Date('2026-09-18T08:00:00.000Z'),
            flow
          )
        );
      },
    },
    {
      name: 'extrait une adresse Gmail avec nom affiché',
      run: function() {
        virementAssertEquals_(
          'quartz.messenger@treasury-factory.com',
          virementExtractEmailAddress_(
            'Quartz <QUARTZ.MESSENGER@TREASURY-FACTORY.COM>'
          )
        );
      },
    },
    {
      name: 'accepte le sujet exact observé',
      run: function() {
        virementAssertTrue_(virementSubjectMatches_(
          'Dalkia Virements importés du jour EUR',
          VIREMENT_CONFIG.EXPECTED_SUBJECT_PREFIXES[0]
        ));
      },
    },
    {
      name: 'accepte un suffixe variable après le sujet',
      run: function() {
        virementAssertTrue_(virementSubjectMatches_(
          'Dalkia Virements importés du jour EUR 21/09/2026',
          VIREMENT_CONFIG.EXPECTED_SUBJECT_PREFIXES[0]
        ));
      },
    },
    {
      name: 'refuse un prolongement sans séparateur',
      run: function() {
        virementAssertFalse_(virementSubjectMatches_(
          'Dalkia Virements importés du jour EURO',
          VIREMENT_CONFIG.EXPECTED_SUBJECT_PREFIXES[0]
        ));
      },
    },
    {
      name: 'accepte xls et xlsx mais refuse pdf',
      run: function() {
        virementAssertTrue_(virementIsAllowedAttachment_(
          'Liste.xls', VIREMENT_CONFIG.ALLOWED_EXTENSIONS
        ));
        virementAssertTrue_(virementIsAllowedAttachment_(
          'Liste.XLSX', VIREMENT_CONFIG.ALLOWED_EXTENSIONS
        ));
        virementAssertFalse_(virementIsAllowedAttachment_(
          'Liste.pdf', VIREMENT_CONFIG.ALLOWED_EXTENSIONS
        ));
      },
    },
    {
      name: 'nettoie un chemin de pièce jointe',
      run: function() {
        virementAssertEquals_(
          'Liste des virements.xls',
          virementSanitizeFileName_('../export\\Liste des virements.xls\u0000')
        );
      },
    },
    {
      name: 'ajoute le suffixe collision avant extension',
      run: function() {
        virementAssertEquals_(
          'Liste des virements_02.xls',
          virementAddCollisionSuffix_('Liste des virements.xls', 2)
        );
      },
    },
    {
      name: 'la requête ne masque pas les conversations labellisées',
      run: function() {
        const query = virementBuildSearchQuery_(VIREMENT_CONFIG);
        virementAssertContains_(query, 'newer_than:4m');
        virementAssertFalse_(query.indexOf('-label:') !== -1);
      },
    },
    {
      name: 'accepte le message Gmail attendu',
      run: function() {
        const message = virementMockMessage_(
          'Quartz <quartz.messenger@treasury-factory.com>',
          'Dalkia Virements importés du jour EUR'
        );
        virementAssertEquals_(
          'matched',
          virementGetMessageMatchResult_(
            message,
            new Date('2026-05-21T00:00:00.000Z')
          ).reason
        );
      },
    },
    {
      name: 'refuse un autre expéditeur',
      run: function() {
        const message = virementMockMessage_(
          'intrus@example.com',
          'Dalkia Virements importés du jour EUR'
        );
        virementAssertEquals_(
          'sender',
          virementGetMessageMatchResult_(
            message,
            new Date('2026-05-21T00:00:00.000Z')
          ).reason
        );
      },
    },
    {
      name: 'applique les critères du profil transmis',
      run: function() {
        const message = virementMockMessage_(
          'quartz.messenger@treasury-factory.com',
          'Dalkia Virements importés du jour EUR'
        );
        const otherFlow = virementTestFlow_('autre_flux');
        otherFlow.EXPECTED_SENDERS = ['autre@example.com'];
        virementAssertEquals_(
          'sender',
          virementGetMessageMatchResult_(
            message,
            new Date('2026-05-21T00:00:00.000Z'),
            otherFlow
          ).reason
        );
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
    throw new Error('Tests Virements en échec :\n' + failures.join('\n'));
  }
}

/** @private */
function virementTestFlow_(id) {
  return {
    ID: id,
    DISPLAY_NAME: id,
    ENABLED: true,
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
    FILE_NAME_MODE: 'timestamp_original',
    FILE_TIMESTAMP_FORMAT: 'ddMMyyyy',
  };
}

/** @private */
function virementMockMessage_(sender, subject) {
  return {
    isInTrash: function() { return false; },
    isDraft: function() { return false; },
    getDate: function() { return new Date('2026-09-21T06:32:00.000Z'); },
    getFrom: function() { return sender; },
    getSubject: function() { return subject; },
  };
}

function virementAssertEquals_(expected, actual) {
  if (expected !== actual) {
    throw new Error('attendu=' + JSON.stringify(expected) +
      ', obtenu=' + JSON.stringify(actual));
  }
}

function virementAssertTrue_(actual) {
  virementAssertEquals_(true, actual);
}

function virementAssertFalse_(actual) {
  virementAssertEquals_(false, actual);
}

function virementAssertContains_(actual, expectedPart) {
  if (String(actual).indexOf(expectedPart) === -1) {
    throw new Error(JSON.stringify(actual) +
      ' ne contient pas ' + JSON.stringify(expectedPart));
  }
}
