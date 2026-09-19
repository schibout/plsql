# Extracteur CTM — Google Apps Script

Ce projet lit les e-mails CTM, décompresse l'unique CSV contenu dans chaque ZIP,
renomme le CSV avec la date de réception du message et le sauvegarde dans Google
Drive sans écrasement.

## Configuration

1. Créer ou ouvrir un projet Google Apps Script avec le compte qui reçoit les e-mails CTM.
2. Copier les fichiers `.gs` et le manifeste `appsscript.json` dans le projet.
3. Ouvrir `Config.gs` et remplacer :

   ```javascript
   FOLDER_ID: 'A_REMPLACER_PAR_ID_DOSSIER_DRIVE'
   ```

   par l'identifiant du dossier Drive de destination.
4. Vérifier que le fuseau du projet est `Europe/Paris`.

Le dossier Drive doit être accessible en écriture par le compte qui exécute le
script. Aucun mot de passe Gmail ne doit être ajouté au code.

## Premier lancement

Exécuter les fonctions dans cet ordre depuis l'éditeur Apps Script :

1. `setupFolderAndLabels()` : autorise Gmail/Drive, vérifie le dossier et crée le libellé.
2. `authorizeAndTestCtmDrive()` : force l'autorisation OAuth et teste une vraie création dans le dossier. Le fichier temporaire est aussitôt placé dans la corbeille.
3. `runCtmUnitTests()` : exécute les tests des fonctions pures.
4. `processCtmEmails()` : réalise une première extraction manuelle.
5. Contrôler les fichiers dans le dossier Drive et les journaux d'exécution.
6. `createCtmTimeDrivenTrigger()` : crée le déclencheur toutes les 15 minutes.

Après toute modification de `appsscript.json`, relancer
`setupFolderAndLabels()` et accepter la nouvelle demande d'autorisation Google.
Le service Drive avancé n'est pas nécessaire : le projet utilise `DriveApp`.

Même lorsque Gmail et Drive appartiennent au même compte, chaque projet Apps
Script possède sa propre autorisation OAuth. Il n'y a aucun mot de passe ni
secret à configurer, mais le compte doit accepter une fois l'accès Drive en
écriture pour ce projet précis.

Si une ancienne exécution a enregistré le mode incrémental avant que les droits
Drive soient accordés, exécuter une seule fois `resetCtmImportState()`, puis
relancer `processCtmEmails()`. Cette réinitialisation ne supprime aucun mail ni
aucun fichier Drive.

## Première exécution et mode incrémental

- Tant que le rattrapage initial n'est pas terminé, la recherche remonte quatre mois en arrière.
- Le rattrapage traite au maximum 40 nouveaux messages par exécution afin de rester sous la limite de temps Apps Script.
- Un curseur est enregistré après chaque message réussi. L'exécution suivante reprend à cet endroit sans recréer les fichiers déjà présents.
- Le déclencheur de 15 minutes peut être activé dès le début : il terminera automatiquement les lots restants.
- Quand les quatre mois ont été parcourus, le script passe automatiquement en mode incrémental.
- En mode incrémental, une marge de deux jours est rescannée par sécurité, mais seuls les messages dont l'identifiant n'a pas déjà été traité produisent un nouveau fichier.

Ces valeurs peuvent être ajustées dans `Config.gs` avec `INITIAL_LOOKBACK_MONTHS`,
`MAX_MESSAGES_PER_RUN` et `INCREMENTAL_OVERLAP_DAYS`.

## Règles appliquées

- Expéditeur exact : `indic_ctm@dalkia.fr`.
- Préfixe d'objet : `DALKIA / Extract CSV du Suivi Quotidien CTM`. Le suffixe variable, par exemple `(ODAT=250717) => 18/07/2025 07-36-23`, est accepté.
- Un seul CSV exploitable doit être présent dans l'ensemble des pièces jointes.
- Nom final : `YYYYMMDD_HHMMSS_NomOriginal.csv`.
- La date provient de `message.getDate()`, jamais de l'heure du déclencheur.
- Une collision ajoute `_02`, `_03`, etc. avant `.csv`.
- L'identifiant Gmail est mémorisé et inscrit dans la description du fichier Drive.
- Le libellé Gmail est uniquement visuel, car plusieurs messages peuvent appartenir à la même conversation.
- Le premier historique couvre quatre mois, puis les exécutions suivantes sont incrémentales.
- Le script ne supprime aucun e-mail, ne le déplace pas dans la corbeille et ne modifie pas son état lu/non lu.
- Après un traitement réussi, la seule modification apportée dans Gmail est l'application du libellé `CTM_CSV_Traites` à la conversation.

## Vérification et dépannage

- Chaque exécution doit afficher `CTM-2026-09-19.4` dans le journal. Si cette version n'apparaît pas, les fichiers du projet Apps Script ne sont pas synchronisés.
- Les tests d'intégration sont décrits dans `tests/TEST_CASES.md`.
- Si l'exécution se termine sans fichier, exécuter `diagnoseCtmEmails()` puis consulter le journal d'exécution. Cette fonction est strictement en lecture seule. Elle recherche aussi les pièces jointes `Report_ctm...zip` sans imposer l'expéditeur et affiche le compte Google exécutant le script, l'expéditeur réel et l'objet réel.
- Si le script indique que le dossier est inaccessible, vérifier l'ID et les droits Drive.
- Si aucun message récent n'est trouvé, `outsideWindowMessages` et `latestOutsideWindowDate` indiquent si seuls des messages antérieurs aux quatre mois existent.
- Si un ZIP contient zéro ou plusieurs CSV, il est rejeté sans création de fichier.
- Une erreur sur un message n'empêche pas les autres messages d'être traités.

## Déclencheur manuel

Le déclencheur peut aussi être créé depuis l'interface Apps Script :

1. Ouvrir **Déclencheurs** dans le menu de gauche.
2. Cliquer sur **Ajouter un déclencheur**.
3. Choisir `processCtmEmails`.
4. Sélectionner **Déclencheur temporel**, puis **Toutes les 15 minutes**.
