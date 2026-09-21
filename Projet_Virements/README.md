# Import Gmail multi-flux vers Google Drive

Projet Google Apps Script autonome capable de télécharger plusieurs types de
mails et de pièces jointes. Le moteur est écrit une seule fois ; chaque besoin
est ajouté sous forme de profil dans `MAIL_IMPORT_FLOWS`, dans `Config.gs`.

Le premier profil actif est `virements_eur` :

- expéditeur : `quartz.messenger@treasury-factory.com` ;
- objet : `Dalkia Virements importés du jour EUR` ;
- extensions : `.xls` et `.xlsx` ;
- dossier Drive : `1H4J7VFzEXdJ0rLPuihiLow2Ui3nFa3GQ` (valeur de `Config.gs`).

Le profil `virements_rejets` (actif) récupère « Dalkia Liste des rejets
bancaires du jour - Virements » (tout expéditeur, toute extension, J-3) dans le
dossier Drive `1raeLB3Meqw4GdtuQJrHZplvaVYR7jp2U`.

Les prélèvements sont séparés en trois profils :

- `prelevements_cashcollection` (actif) pour la synthèse quotidienne
  CashCollection, dossier Drive `1yEjJwQaPdVZ6dFnpASp8xo-Ew99iRYvw` ;
- `prelevements_rejets` (actif) pour « Dalkia Liste des rejets bancaires du
  jour - Prélèvements », dossier Drive `1W5woP7yjzwpe9NDfwagWvwhL75MrBHxG` ;
- `prelevements_oracle_edf` (désactivé, `ENABLED: false`, à réactiver après
  validation) pour les regroupements Oracle EDF, dossier Drive
  `1skW6lJUvX1qlmw6RoLqE_94o5P1yu7o2` ;
- aucun filtre d'expéditeur ;
- toutes les extensions autorisées ;
- mails reçus exactement à J‑3 ;
- fichiers déposés dans le dossier racine sous
  `DDMMYYYY_nom-original`.

Chacun possède son propre dossier Drive, sa propre
requête Gmail, son propre libellé, sa clé d'état et son marqueur anti-doublon.

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
  FILE_NAME_MODE: 'timestamp_original',
  FILE_TIMESTAMP_FORMAT: 'ddMMyyyy',
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
- `FILE_NAME_MODE: 'timestamp_original'` avec `FILE_TIMESTAMP_FORMAT: 'ddMMyyyy'`
  produit `DDMMYYYY_nom-original.ext`.

## Organisation dans Drive

Chaque profil écrit directement dans son dossier racine. Aucun sous-dossier
n'est créé. Les fichiers sont préfixés par la date de réception :

```text
Dossier_du_flux/
├── 21092026_rapport.xls
└── 21092026_rapport_02.xls
```

Le suffixe `_02`, puis `_03`, évite d'écraser deux fichiers de même nom issus
de messages différents.

## Déploiement depuis VS Code (clasp)

Une fois pour toutes : `npm install -g @google/clasp`, `clasp login`, puis activer
« Google Apps Script API » sur <https://script.google.com/home/usersettings>.
Le fichier `.clasp.json` (hors git) contient l'identifiant du projet.

Ensuite, `deploy.bat` lance les tests Node puis `clasp push --force` : les
fichiers `.gs` et `appsscript.json` remplacent ceux du projet en ligne
(`.claspignore` garde README, SPEC et `tests/` en local).

## Fichiers à copier dans Apps Script (sans clasp)

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
