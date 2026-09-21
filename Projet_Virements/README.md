# Import Gmail multi-flux vers Google Drive

Projet Google Apps Script autonome capable de télécharger plusieurs types de
mails et de pièces jointes. Le moteur est écrit une seule fois ; chaque besoin
est ajouté sous forme de profil dans `MAIL_IMPORT_FLOWS`, dans `Config.gs`.

Le premier profil actif est `virements_eur` :

- expéditeur : `quartz.messenger@treasury-factory.com` ;
- objet : `Dalkia Virements importés du jour EUR` ;
- extensions : `.xls` et `.xlsx` ;
- dossier Drive : `1KFQvMNyQEy2H4niTTWg9jSeyCrJCS51Q`.

Le second profil actif est `prelevements` et reprend l'ancien `CONFIG` :

- dossier Drive : `1skW6lJUvX1qlmw6RoLqE_94o5P1yu7o2` ;
- objets CashCollection et regroupements Oracle EDF ;
- aucun filtre d'expéditeur ;
- toutes les extensions autorisées ;
- mails reçus exactement à J‑3 ;
- fichiers déposés dans le dossier racine sous
  `yyyyMMdd_HHmm_nom-original`.

`Projet_CTM` reste indépendant et n'est pas modifié.

## Ajouter un autre type de mail

Dans `Config.gs`, dupliquer le bloc `virements_eur` à l'intérieur de
`MAIL_IMPORT_FLOWS` :

```javascript
Object.freeze({
  ID: 'rapport_csv',
  DISPLAY_NAME: 'Rapport CSV',
  ENABLED: true,

  FOLDER_ID: 'ID_DU_DOSSIER_DRIVE',
  SEARCH_QUERY: 'in:anywhere from:robot@example.com subject:"Rapport CSV"',
  EXPECTED_SENDERS: Object.freeze(['robot@example.com']),
  EXPECTED_SUBJECT_PREFIXES: Object.freeze([
    'Rapport CSV quotidien',
    'Rapport CSV correctif',
  ]),
  ALLOWED_EXTENSIONS: Object.freeze(['csv', 'zip']),

  LABEL_NAME: 'Rapport_CSV_Traite',
  STATE_PROPERTY_KEY: 'RAPPORT_CSV_IMPORT_STATE_V1',
  DRIVE_MESSAGE_MARKER_PREFIX: 'RAPPORT_CSV_MESSAGE_ID=',
  TIME_ZONE: 'Europe/Paris',
  INITIAL_LOOKBACK_MONTHS: 4,
  DATE_OFFSET_DAYS: null,
  CREATE_DATE_SUBFOLDER: true,
  SUBFOLDER_DATE_FORMAT: 'ddMMyyyy',
  FILE_NAME_MODE: 'original',
  FILE_TIMESTAMP_FORMAT: 'yyyyMMdd_HHmm',
}),
```

Les quatre valeurs suivantes doivent être uniques pour chaque bloc :

- `ID`
- `LABEL_NAME`
- `STATE_PROPERTY_KEY`
- `DRIVE_MESSAGE_MARKER_PREFIX`

Les extensions s'écrivent sans point et en minuscules. Un profil temporairement
inactif peut rester dans la liste avec `ENABLED: false`.

Règles particulières :

- `EXPECTED_SENDERS: ['*']` désactive le filtre d'expéditeur ;
- `ALLOWED_EXTENSIONS: []` accepte toutes les extensions ;
- `DATE_OFFSET_DAYS: 3` cible exactement J‑3 ; `null` utilise la fenêtre des
  derniers mois ;
- `CREATE_DATE_SUBFOLDER: false` écrit directement dans le dossier racine ;
- `FILE_NAME_MODE: 'timestamp_original'` ajoute `FILE_TIMESTAMP_FORMAT` devant
  le nom original.

## Organisation dans Drive

Chaque profil choisit son propre dossier racine, sa stratégie de nommage et
l'utilisation éventuelle d'un sous-dossier daté. Le profil Virements produit :

```text
Dossier_du_flux/
└── 21092026/
    ├── rapport.xls
    └── rapport_02.xls
```

Le suffixe `_02`, puis `_03`, évite d'écraser deux fichiers de même nom issus
de messages différents. Le profil Prélèvements écrit directement dans son
dossier racine avec un préfixe horodaté.

## Fichiers à copier dans Apps Script

Créer un projet sur <https://script.google.com>, puis recopier :

- `Config.gs`
- `Utils.gs`
- `GmailService.gs`
- `AttachmentService.gs`
- `DriveService.gs`
- `Code.gs`
- `Tests.gs`
- `appsscript.json` dans le manifeste

`SPEC.md`, `README.md` et le dossier `tests/` restent dans le dépôt local.

## Installation

1. Compléter les profils de `MAIL_IMPORT_FLOWS` dans `Config.gs`.
2. Régler le fuseau du projet Apps Script sur `Europe/Paris`.
3. Exécuter `runVirementUnitTests()`.
4. Exécuter `diagnoseMailImports()` et contrôler un résultat par profil actif.
5. Exécuter `setupMailImportProject()` pour vérifier les dossiers et créer les
   libellés Gmail.
6. Exécuter `processMailImports()` et vérifier les fichiers Drive.
7. Exécuter une seule fois `createMailImportTimeDrivenTrigger()`.

Le déclencheur global appelle `processMailImports` toutes les heures et
traite successivement tous les profils actifs. Si un profil échoue, les suivants
sont quand même traités, puis l'exécution signale l'erreur récapitulative.

Lors du premier appel à `createMailImportTimeDrivenTrigger()` avec cette version,
les anciens déclencheurs associés à `processMailImports` ou
`processVirementEmails` sont remplacés par le déclencheur horaire. Les autres
déclencheurs du projet ne sont pas touchés. L'identifiant créé est mémorisé dans
`MAIL_IMPORT_TRIGGER_STATE`, ce qui rend les appels suivants idempotents.

## Points d'entrée

| Fonction générique | Effet |
|---|---|
| `processMailImports()` | Traite tous les profils actifs |
| `diagnoseMailImports()` | Diagnostic en lecture seule de chaque profil |
| `setupMailImportProject()` | Vérifie les dossiers et crée les libellés |
| `createMailImportTimeDrivenTrigger()` | Crée ou migre le déclencheur global horaire |
| `resetMailImportStates()` | Efface les états de tous les profils sans supprimer de fichiers |
| `runVirementUnitTests()` | Lance les tests purs dans Apps Script |

Les anciens noms restent disponibles comme alias :

- `processVirementEmails()`
- `diagnoseVirementEmails()`
- `setupVirementProject()`
- `createVirementTimeDrivenTrigger()`
- `resetVirementImportState()`

Un ancien déclencheur pointant vers `processVirementEmails` continue donc de
fonctionner et exécute désormais tous les profils actifs.

## Suivi et idempotence

Chaque profil possède son propre état ScriptProperties, son libellé et son
marqueur Drive. Deux profils peuvent voir le même message sans partager leur
état de traitement.

Le libellé Gmail est uniquement visuel. Il n'est jamais exclu de la requête : un
nouveau message ajouté dans une conversation déjà labellisée reste détectable.

Chaque fichier reçoit dans sa description :

```text
<DRIVE_MESSAGE_MARKER_PREFIX><identifiant Gmail>
MAIL_IMPORT_FLOW=<identifiant du profil>
MAIL_RECEIVED_AT=<date ISO>
MAIL_ORIGINAL_NAME=<nom d'origine>
```

## Diagnostic

`diagnoseMailImports()` retourne une liste contenant un bilan pour chaque profil
actif : requête Gmail, dossier Drive, conversations, messages acceptés, fichiers
acceptés et motifs de rejet.

En cas de problème :

- copier la requête `query` du profil dans Gmail ;
- vérifier l'expéditeur et le préfixe d'objet configurés ;
- vérifier les extensions sans point dans `ALLOWED_EXTENSIONS` ;
- vérifier que le compte exécutant peut écrire dans le `FOLDER_ID` du profil.

## Tests locaux

Depuis la racine du dépôt avec Node.js :

```powershell
node Projet_Virements/tests/run_local_tests.js
node Projet_Virements/tests/run_service_tests.js
```

La recette Google complète est décrite dans `tests/TEST_CASES.md`.
