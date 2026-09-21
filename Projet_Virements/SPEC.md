# Spec: Import Gmail multi-flux vers Google Drive

**Author:** Codex avec validation utilisateur
**Date:** 2026-09-21
**Status:** Approved
**Reviewers:** Samir Chibout
**Related specs:** `Projet_CTM/PLAN_DEVELOPPEMENT.md`

## Context

Le dossier `Projet_Virements` contient initialement un import spécialisé pour
un seul expéditeur, un seul objet et des classeurs Excel. Le besoin métier est
d'utiliser ce même projet Apps Script pour plusieurs types de mails et de
fichiers, sans dupliquer le moteur à chaque nouveau flux.

Les futurs flux ne sont pas encore définis. Le projet doit donc exposer une
liste de profils indépendants. Chaque profil décrit ses critères Gmail, ses
extensions autorisées, son dossier Drive et ses clés de suivi. Le profil
« Virements EUR » reste actif et compatible avec le déploiement existant.

## Functional Requirements

- FR-1: Le projet MUST déclarer une liste `MAIL_IMPORT_FLOWS` contenant un ou plusieurs profils d'import indépendants.
- FR-2: Chaque profil MUST posséder un identifiant unique, un nom, un indicateur d'activation, un dossier Drive, une requête Gmail, une liste d'expéditeurs, une liste de préfixes d'objet, une liste d'extensions, une stratégie de date et de nommage, un libellé, une clé d'état et un préfixe de marqueur Drive.
- FR-3: Le moteur MUST traiter successivement tous les profils activés et MUST continuer avec les profils suivants lorsqu'un profil échoue.
- FR-4: Le filtre MUST accepter un message lorsque son expéditeur correspond à l'un des expéditeurs du profil, ou lorsque le profil contient le joker `*`, et que son objet correspond à l'un de ses préfixes.
- FR-5: L'extracteur MUST accepter toutes les pièces jointes dont l'extension figure dans le profil, MUST accepter toutes les extensions lorsque la liste est vide et MUST ignorer les images intégrées.
- FR-6: Chaque profil actif MUST écrire directement dans son dossier racine sans créer de sous-dossier et MUST renommer chaque fichier sous `DDMMYYYY_nom-original.ext` selon la date de réception.
- FR-7: L'idempotence MUST être isolée par profil grâce à une propriété ScriptProperties, un libellé Gmail et un marqueur Drive propres au profil.
- FR-8: La recherche MUST NOT exclure les conversations labellisées, afin qu'un nouveau message d'une conversation existante soit encore détecté.
- FR-9: Le projet MUST conserver `processVirementEmails`, `diagnoseVirementEmails`, `setupVirementProject`, `resetVirementImportState` et `createVirementTimeDrivenTrigger` comme alias compatibles.
- FR-10: Le projet MUST fournir les points d'entrée génériques `processMailImports`, `diagnoseMailImports`, `setupMailImportProject`, `resetMailImportStates` et `createMailImportTimeDrivenTrigger`.
- FR-11: Le profil initial `virements_eur` MUST filtrer `quartz.messenger@treasury-factory.com`, l'objet `Dalkia Virements importés du jour EUR`, et les extensions `.xls` et `.xlsx`.
- FR-12: En cas de collision de nom entre deux messages différents dans le même dossier, le moteur MUST préserver le premier fichier et suffixer le suivant.
- FR-13: La validation MUST refuser les identifiants, clés d'état, libellés ou préfixes de marqueur dupliqués entre profils.
- FR-14: Les prélèvements MUST être séparés entre `prelevements_cashcollection` et `prelevements_oracle_edf`, avec un seul préfixe d'objet et un état indépendant par profil, tout en partageant le dossier `1skW6lJUvX1qlmw6RoLqE_94o5P1yu7o2`, toutes les extensions, aucun filtre d'expéditeur, une date exacte à J-3 et le nom `DDMMYYYY_nom-original`.

## Non-Functional Requirements

- NFR-1: Une exécution MUST tenter au plus 50 nouveaux messages par profil et inspecter au plus 500 conversations par profil.
- NFR-2: L'état de chaque profil MUST rester inférieur ou égal à 8 000 caractères et conserver au plus 500 identifiants de messages.
- NFR-3: Deux exécutions globales simultanées MUST être empêchées par un verrou de script attendu au plus 5 secondes.
- NFR-4: Le projet MUST fonctionner avec le moteur Apps Script V8 sans service avancé Google.
- NFR-5: Les fonctions de validation, filtrage, extension, nommage et collision MUST être couvertes par des tests Node.js sans accès réel à Gmail ou Drive.

## Acceptance Criteria

### AC-1: Plusieurs profils actifs (FR-1, FR-2, FR-3)
Given deux profils activés ayant des configurations valides
When `processMailImports` est exécuté
Then le moteur appelle le traitement une fois pour chacun des deux profils
And les deux bilans portent des identifiants de flux différents.

### AC-2: Profil désactivé (FR-2, FR-3)
Given un profil dont `ENABLED` vaut `false`
When `processMailImports` est exécuté
Then aucune recherche Gmail ni écriture Drive n'est effectuée pour ce profil.

### AC-3: Filtrage propre au profil (FR-4, FR-11)
Given le profil `virements_eur` et un message reçu de `quartz.messenger@treasury-factory.com` avec l'objet attendu
When le filtre contrôle les métadonnées avec ce profil
Then le message est accepté
And le même message est refusé par un profil dont les critères diffèrent.

### AC-4: Extensions propres au profil (FR-5, FR-11)
Given un profil autorisant `xls` et `xlsx` et un message contenant un classeur et un PDF
When les pièces jointes sont extraites avec ce profil
Then le classeur est retourné
And le PDF est compté comme ignoré.

### AC-5: Destination propre au profil (FR-6)
Given un profil configuré avec le format `ddMMyyyy` et un message reçu le 21 septembre 2026 contenant `rapport.xls`
When la destination Drive est résolue et le fichier enregistré
Then aucun sous-dossier n'est créé
And le fichier est placé dans le dossier racine sous `21092026_rapport.xls`.

### AC-6: États isolés (FR-7)
Given deux profils dont les clés d'état sont différentes
When le même identifiant Gmail est mémorisé dans le premier profil
Then le second profil ne considère pas cet identifiant comme traité.

### AC-7: Nouvelle réponse dans une conversation labellisée (FR-8)
Given une conversation déjà labellisée contenant un nouveau message non mémorisé
When la requête du profil est construite
Then la requête ne contient aucune exclusion `-label:`
And le nouveau message reste candidat.

### AC-8: Compatibilité des anciens points d'entrée (FR-9, FR-10)
Given un déclencheur existant appelant `processVirementEmails`
When cet alias est exécuté après la migration
Then il délègue au moteur multi-flux
And aucun renommage manuel du déclencheur n'est obligatoire.

### AC-9: Collision sans écrasement (FR-12)
Given deux messages différents portant le même nom de fichier dans la même destination
When le second fichier est enregistré
Then le premier reste inchangé
And le second reçoit le suffixe `_02` avant son extension.

### AC-10: Configuration ambiguë refusée (FR-13)
Given deux profils partageant la même clé d'état ou le même identifiant
When la configuration globale est validée
Then une erreur explicite est levée avant toute recherche Gmail ou écriture Drive.

### AC-11: Bornes et tests (NFR-1, NFR-2, NFR-3, NFR-4, NFR-5)
Given une configuration valide et les doubles locaux Gmail/Drive
When les deux commandes Node.js documentées sont exécutées
Then tous les tests se terminent avec un code de sortie zéro
And les limites de messages, d'état et de verrou sont vérifiées.

### AC-12: Séparation des prélèvements (FR-4, FR-5, FR-6, FR-7, FR-14)
Given les profils `prelevements_cashcollection` et `prelevements_oracle_edf` et une date de référence du 21 septembre 2026
When leurs configurations sont validées
Then chaque profil possède exactement un préfixe d'objet
And leurs libellés, clés d'état et marqueurs Drive sont différents
And ils partagent le même dossier Drive et les règles J-3 et `DDMMYYYY_nom-original`.

## Edge Cases

- EC-1: Un profil activé est incomplet → refuser toute l'exécution avant le premier accès Gmail ou Drive.
- EC-2: Deux profils utilisent la même clé d'état, le même libellé, le même identifiant ou le même marqueur → lever une erreur de configuration nommant la valeur dupliquée.
- EC-3: Gmail est illisible pour un profil → journaliser l'erreur, poursuivre les autres profils et signaler l'échec global après leur traitement.
- EC-4: Drive est inaccessible pour un profil → ne modifier ni état ni libellé pour ce profil, puis poursuivre les autres.
- EC-5: Un message ne contient aucune extension autorisée → ne pas le mémoriser afin qu'il puisse être retenté après correction.
- EC-6: Plusieurs pièces jointes autorisées sont présentes → toutes les archiver avant de mémoriser le message.
- EC-7: Un profil est désactivé → l'ignorer sans valider ses accès Gmail/Drive.
- EC-8: L'état d'un profil est absent ou invalide → repartir avec un état vide uniquement pour ce profil.
- EC-9: Une pièce jointe contient un chemin ou des caractères de contrôle → conserver uniquement son nom de base nettoyé.
- EC-10: Un profil contient `ALLOWED_EXTENSIONS: []` → accepter toute extension non intégrée au corps du message.

## API Contracts

Il n'existe pas d'API HTTP. Les fonctions Apps Script constituent le contrat public :

```typescript
function processMailImports(): MailImportReport[];
function diagnoseMailImports(): MailImportDiagnostic[];
function setupMailImportProject(): void;
function resetMailImportStates(): void;
function createMailImportTimeDrivenTrigger(): void;

// Alias compatibles
function processVirementEmails(): MailImportReport[];
function diagnoseVirementEmails(): MailImportDiagnostic[];
function setupVirementProject(): void;
function resetVirementImportState(): void;
function createVirementTimeDrivenTrigger(): void;
```

Une erreur critique d'un profil est capturée afin de traiter les suivants. Après
le dernier profil, `processMailImports` lève une erreur récapitulative lorsqu'au
moins un profil a subi une erreur critique.

## Data Models

### MailImportFlow

| Field | Type | Constraints |
|---|---|---|
| `ID` | string | Non vide et unique |
| `DISPLAY_NAME` | string | Non vide |
| `ENABLED` | boolean | Obligatoire |
| `FOLDER_ID` | string | ID Drive non vide si actif |
| `SEARCH_QUERY` | string | Requête Gmail sans exclusion de libellé |
| `EXPECTED_SENDERS` | string[] | Au moins une adresse ou le joker `*` si actif |
| `EXPECTED_SUBJECT_PREFIXES` | string[] | Au moins un préfixe si actif |
| `ALLOWED_EXTENSIONS` | string[] | Extensions sans point, minuscules ; vide = toutes |
| `LABEL_NAME` | string | Non vide et unique |
| `STATE_PROPERTY_KEY` | string | Non vide et unique |
| `DRIVE_MESSAGE_MARKER_PREFIX` | string | Non vide et unique |
| `TIME_ZONE` | string | Fuseau IANA |
| `INITIAL_LOOKBACK_MONTHS` | number | Entier supérieur ou égal à 1 |
| `DATE_OFFSET_DAYS` | number ou null | Entier ≥ 0 pour une date exacte J-N ; null pour la fenêtre glissante |
| `FILE_NAME_MODE` | string | MUST être `timestamp_original` pour les profils actifs |
| `FILE_TIMESTAMP_FORMAT` | string | MUST être `ddMMyyyy` pour les profils actifs |

### MailImportState

| Field | Type | Constraints |
|---|---|---|
| `processed` | `Record<string, number>` | Isolé par `STATE_PROPERTY_KEY` |
| `lastSuccessfulRunIso` | string ou null | ISO-8601 |

### MailImportReport

| Field | Type | Constraints |
|---|---|---|
| `flowId` | string | Identifiant du profil |
| `matched` | number | Supérieur ou égal à zéro |
| `createdFiles` | number | Supérieur ou égal à zéro |
| `skippedFiles` | number | Supérieur ou égal à zéro |
| `errors` | number | Supérieur ou égal à zéro |

## Out of Scope

- OS-1: Inventer les critères des futurs mails — ils seront ajoutés comme profils quand leurs expéditeurs, objets et extensions seront connus.
- OS-2: Analyser le contenu métier des pièces jointes — le moteur archive les fichiers sans lire leurs cellules ou leur texte.
- OS-3: Exécuter les traitements Python locaux après téléchargement — Apps Script ne peut pas démarrer un programme sur le poste.
- OS-4: Modifier `Projet_CTM` — le moteur multi-flux reste isolé dans `Projet_Virements`.
