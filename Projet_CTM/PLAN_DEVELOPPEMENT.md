# Plan de développement — Automatisation des rapports CTM

## 1. Objet du projet

Mettre en place une chaîne en deux étapes :

1. Google Apps Script recherche les e-mails CTM reçus depuis `indic_ctm@dalkia.fr`, ouvre chaque archive ZIP, extrait son CSV, le renomme avec la date et l'heure réelles de réception du mail, puis le dépose dans un dossier Google Drive sans écrasement ni double traitement.
2. Le programme Python récupère ensuite les nouveaux CSV depuis Google Drive pour poursuivre le traitement local ou applicatif.

Le volume métier attendu est de cinq e-mails par jour. Les archives et les CSV peuvent conserver le même nom d'un envoi à l'autre ; l'heure de réception du message est donc indispensable pour les distinguer.

Le développement cible Google Apps Script, conformément à `prompt.txt`. Le fichier `ctm_extractor.py` constitue un prototype local antérieur, mais ne doit pas être utilisé tel quel en production.

## 2. État des lieux

### Fichiers existants

- `prompt.txt` : expression du besoin pour une solution Google Apps Script.
- `ctm_extractor.py` : prototype Python utilisant IMAP et un stockage local.

### Écarts du prototype Python par rapport au besoin

- Il télécharge les rapports sur le disque local au lieu de Google Drive.
- Il utilise IMAP au lieu des services Gmail natifs de Google Apps Script.
- Il ne marque pas les e-mails comme traités.
- Il utilise l'heure d'exécution au lieu de la date de réception du message.
- Il remplace un fichier local portant déjà le même nom, ce qui contredit la règle « ne jamais écraser ».
- Il ne protège pas l'exécution contre deux traitements simultanés.
- L'extraction ZIP ne neutralise pas explicitement les chemins internes potentiellement dangereux.
- Il contient des identifiants en dur. Le mot de passe présent dans le fichier doit être supprimé de l'historique exploitable et changé s'il correspond à un vrai compte.

### Éléments hors sujet présents dans `prompt.txt`

Les erreurs suivantes ne concernent pas l'automatisation Gmail/Drive et ne doivent pas être intégrées à ce développement :

- erreur Oracle `DPY-3015` ;
- avertissement Streamlit concernant `use_container_width`.

Elles devront faire l'objet d'un diagnostic séparé si elles appartiennent à une autre application.

## 3. Périmètre fonctionnel

### Inclus dans la première version

1. Configuration du dossier Drive, de la requête Gmail, du libellé et du fuseau horaire.
2. Recherche des messages CTM non encore traités.
3. Prise en charge des pièces jointes `.csv` et `.zip`.
4. Filtrage des fichiers CSV contenus dans les ZIP.
5. Nommage à partir de la date de réception du message.
6. Dépôt dans Google Drive sans écrasement.
7. Marquage du traitement réussi dans Gmail.
8. Journalisation détaillée et isolation des erreurs par message.
9. Verrouillage contre les exécutions concurrentes.
10. Procédure d'installation, d'autorisation et de création du déclencheur.
11. Récupération des nouveaux CSV de Google Drive vers Python, sans téléchargement en double.

### Hors périmètre de la première version

- Lecture ou transformation du contenu métier des CSV après leur récupération par Python.
- Chargement des données dans Oracle ou une autre base.
- Interface Streamlit ou tableau de bord.
- Traitement des formats autres que CSV et ZIP.
- ZIP imbriqués ou archives protégées par mot de passe.
- Notifications automatiques en cas d'échec, sauf décision ultérieure.
- Reprise automatique avancée avec file d'attente externe.

## 4. Décisions à valider avant l'implémentation

| ID | Sujet | Proposition recommandée | Pourquoi |
|---|---|---|---|
| D-01 | Unité de suivi Gmail | Suivre chaque message par son identifiant dans `PropertiesService`, et utiliser le libellé comme indicateur visuel au niveau du thread | Dans Apps Script, le libellé est principalement appliqué au thread ; un thread peut recevoir plusieurs messages et le libellé seul n'assure pas une idempotence fiable par message |
| D-02 | Message sans CSV exploitable | Ne pas le marquer comme traité et produire un log d'avertissement | Évite de masquer une anomalie d'envoi |
| D-03 | Contenu attendu du ZIP | Exiger exactement un CSV par ZIP ; zéro ou plusieurs CSV déclenchent une anomalie et le message reste non traité | Le flux décrit contient toujours un ZIP avec un seul CSV ; une autre cardinalité indique un envoi inattendu |
| D-04 | Collision de noms | Conserver le format demandé, puis ajouter `_02`, `_03`, etc. avant `.csv` si nécessaire | Plusieurs pièces jointes de même nom dans le même message auraient le même horodatage |
| D-05 | Fuseau horaire | Utiliser `Europe/Paris` et configurer le projet Apps Script avec le même fuseau | Rend les noms cohérents avec les heures métier françaises |
| D-06 | Fréquence | Déclencheur toutes les 15 minutes | Convient à quelques rapports par jour sans consommation excessive de quota |
| D-07 | Ancien prototype | Le conserver temporairement comme référence, sans l'exécuter, puis l'archiver après validation de la version Apps Script | Évite deux mécanismes concurrents et retire la dépendance au mot de passe IMAP |
| D-08 | Liaison Drive vers Python | Utiliser l'API Google Drive ; OAuth utilisateur pour un poste local, ou compte de service pour une exécution serveur autorisée par l'organisation | Cette solution permet de lister et télécharger uniquement les nouveaux fichiers et ne dépend pas d'une synchronisation manuelle |

## 5. Architecture proposée dans `Projet_CTM`

```text
Projet_CTM/
├── prompt.txt                  # Besoin initial, conservé comme source
├── PLAN_DEVELOPPEMENT.md       # Présent plan
├── README.md                   # Installation, configuration et exploitation
├── appsscript.json             # Manifeste Apps Script, fuseau et droits
├── Config.gs                   # Constantes et validation de configuration
├── Code.gs                     # Orchestration principale
├── GmailService.gs             # Recherche et suivi des messages
├── AttachmentService.gs        # Détection CSV/ZIP et extraction
├── DriveService.gs             # Nommage, collisions et sauvegarde
├── Utils.gs                    # Formatage, normalisation et logs
├── python/
│   ├── drive_downloader.py     # Récupération des nouveaux CSV depuis Drive
│   ├── requirements.txt        # Bibliothèques Google nécessaires
│   └── .env.example            # Paramètres sans aucun secret
└── tests/
    ├── TEST_CASES.md           # Cas de test unitaires et d'intégration
    └── fixtures/               # Description des jeux de fichiers de recette
```

Le nombre de fichiers `.gs` peut être réduit si l'équipe préfère un seul `Code.gs`. La séparation proposée facilite cependant les tests, la maintenance et la lecture des responsabilités.

## 6. Spécification fonctionnelle initiale

### Exigences fonctionnelles

- **FR-01** — Le système DOIT rechercher les e-mails correspondant exactement à l'expéditeur et au sujet configurés.
- **FR-02** — Le système DOIT ignorer tout message déjà traité avec succès.
- **FR-03** — Le système DOIT traiter séparément chaque message trouvé, afin qu'un échec n'interrompe pas les suivants.
- **FR-04** — Le système DOIT accepter une pièce jointe CSV indépendamment de la casse de son extension.
- **FR-05** — Le système DOIT vérifier que chaque ZIP contient exactement un fichier CSV exploitable et extraire ce fichier ; sinon, aucun fichier de cette archive ne doit être sauvegardé.
- **FR-06** — Le système DOIT ignorer les dossiers et les autres formats contenus dans un ZIP.
- **FR-07** — Le système DOIT préfixer le nom d'origine par la date de réception au format `YYYYMMDD_HHMMSS_`.
- **FR-08** — Le système NE DOIT JAMAIS écraser un fichier existant.
- **FR-09** — Le système DOIT appliquer une règle de collision déterministe si le nom final existe déjà.
- **FR-10** — Le système DOIT marquer un message comme traité uniquement après la sauvegarde réussie de tous ses CSV valides.
- **FR-11** — Le système DOIT journaliser les résultats et les erreurs sans exposer de données sensibles.
- **FR-12** — La fonction `setupFolderAndLabels()` DOIT vérifier l'accès au dossier Drive et créer le libellé si nécessaire.
- **FR-13** — La fonction `processCtmEmails()` DOIT pouvoir être appelée manuellement ou par un déclencheur temporel.
- **FR-14** — Le système DOIT empêcher deux exécutions simultanées de traiter les mêmes messages.
- **FR-15** — Le système DOIT utiliser `message.getDate()` comme source de l'horodatage et NE DOIT PAS utiliser l'heure du déclencheur ou l'heure courante.
- **FR-16** — Le système DOIT traiter tous les messages correspondants trouvés ; le volume de cinq messages par jour est une attente métier et non une limite technique.
- **FR-17** — Le composant Python DOIT pouvoir lister puis télécharger les nouveaux CSV du dossier Drive configuré.
- **FR-18** — Le composant Python DOIT mémoriser l'identifiant Drive des fichiers déjà récupérés afin de ne pas les télécharger une seconde fois.
- **FR-19** — L'authentification Python à Google Drive DOIT utiliser OAuth ou un compte de service autorisé, sans secret inclus dans Git.

### Exigences non fonctionnelles

- **NFR-01 — Sécurité :** aucun mot de passe, jeton ou secret ne doit être stocké dans le dépôt.
- **NFR-02 — Fiabilité :** une nouvelle exécution après échec ne doit pas dupliquer les fichiers déjà enregistrés.
- **NFR-03 — Traçabilité :** chaque message doit produire un bilan comprenant son identifiant, le nombre de pièces jointes examinées, le nombre de CSV sauvegardés et le statut final.
- **NFR-04 — Maintenabilité :** les fonctions de formatage, de détection de type et de génération de nom doivent être pures et testables sans Gmail ni Drive.
- **NFR-05 — Quotas :** la recherche Gmail doit être paginée et le nombre de messages traité par exécution doit être configurable.
- **NFR-06 — Compatibilité :** le projet doit utiliser le runtime V8 de Google Apps Script.
- **NFR-07 — Confidentialité :** les logs ne doivent contenir ni contenu CSV, ni adresse autre que l'expéditeur configuré, ni secret.
- **NFR-08 — Complétude métier :** le bilan doit permettre de constater le nombre de rapports reçus et traités dans la journée, notamment par rapport aux cinq rapports attendus.

### Nommage attendu pour les cinq réceptions quotidiennes

Le nom doit être construit à partir de la date du message Gmail, pas à partir de l'heure à laquelle le déclencheur s'exécute. Avec un fichier source nommé à chaque fois `Report_ctm.csv`, les résultats d'une journée pourront par exemple être :

```text
20260919_074000_Report_ctm.csv
20260919_080600_Report_ctm.csv
20260919_134500_Report_ctm.csv
20260919_164000_Report_ctm.csv
```

Le cinquième horaire n'a pas encore été précisé. Le script ne dépendra pas d'horaires fixes : il utilisera l'heure propre à chacun des cinq messages réellement reçus.

## 7. Flux de traitement cible

1. Acquérir un verrou `LockService` avec une attente courte.
2. Charger et valider la configuration.
3. Récupérer ou créer le libellé Gmail.
4. Ouvrir le dossier Drive cible et vérifier les droits d'écriture.
5. Rechercher par lots les threads/messages correspondant à la requête.
6. Pour chaque message non enregistré comme traité :
   1. récupérer sa date de réception et ses pièces jointes ;
   2. détecter les CSV directs et les ZIP ;
   3. décompresser chaque ZIP dans la mémoire Apps Script ;
   4. filtrer et normaliser les noms de fichiers ;
   5. construire un nom unique à partir de la date du message ;
   6. sauvegarder les CSV dans Drive ;
   7. vérifier que toutes les sauvegardes attendues ont réussi ;
   8. enregistrer l'identifiant du message comme traité ;
   9. appliquer le libellé au thread si tous les messages concernés sont traités.
7. Produire un bilan global de l'exécution.
8. Libérer le verrou dans un bloc `finally`.

### Flux Google Drive vers Python

1. Le composant Python s'authentifie auprès de l'API Google Drive.
2. Il liste les CSV du dossier Drive configuré, triés par date de création.
3. Il compare les identifiants Drive à son registre local de fichiers déjà récupérés.
4. Il télécharge uniquement les nouveaux fichiers dans un répertoire local d'entrée.
5. Il vérifie que le téléchargement est complet avant de mettre à jour le registre local.
6. Le traitement Python existant peut ensuite lire ces fichiers ; son comportement métier reste séparé de l'étape de téléchargement.

Pour une utilisation purement manuelle sur un poste de travail, Google Drive pour ordinateur pourrait également synchroniser le dossier. Pour une automatisation fiable et contrôlable, l'API Google Drive reste la solution recommandée.

## 8. Stratégie d'idempotence et de non-écrasement

Le simple préfixe horodaté n'est pas suffisant : une relance du même message ou deux pièces jointes portant le même nom produiraient le même nom final.

La stratégie proposée combine :

1. l'identifiant Gmail du message enregistré dans `ScriptProperties` après succès complet ;
2. la recherche préalable d'un fichier homonyme dans le dossier Drive ;
3. l'ajout d'un suffixe numérique en cas de collision ;
4. un verrou de script pour bloquer les exécutions concurrentes ;
5. un journal de progression par fichier pour permettre une reprise contrôlée après une erreur partielle.

Avant le développement, il faudra choisir entre deux niveaux de reprise :

- **Version simple :** en cas d'échec partiel, supprimer manuellement les fichiers créés ou accepter les suffixes lors de la relance.
- **Version robuste recommandée :** mémoriser une clé par fichier, par exemple `messageId + nom original + index`, afin que la relance détecte les fichiers déjà sauvegardés sans les recréer.

## 9. Gestion des erreurs

### Erreurs bloquant uniquement un message

- ZIP corrompu ;
- pièce jointe illisible ;
- erreur de création d'un fichier Drive ;
- nom de fichier vide ou invalide ;
- absence de CSV dans un message supposé en contenir.

Le message concerné reste non traité, l'erreur est journalisée, puis le traitement continue avec le message suivant.

### Erreurs bloquant l'exécution complète

- `FOLDER_ID` absent ou invalide ;
- dossier inaccessible en écriture ;
- configuration Gmail invalide ;
- impossibilité d'acquérir le verrou ;
- autorisations Apps Script manquantes.

Dans ces cas, l'exécution doit s'arrêter avec un log explicite, sans modifier l'état des messages non commencés.

## 10. Plan de réalisation

### Phase 0 — Sécurisation immédiate

- Retirer tout identifiant/mot de passe du code suivi par Git.
- Changer le mot de passe présent dans `ctm_extractor.py` s'il est réel ou a déjà été utilisé.
- Ajouter les fichiers secrets et de configuration locale à `.gitignore` si une piste Python est conservée.
- Décider que Google Apps Script devient l'unique mécanisme de production.

**Livrable :** dépôt sans secret actif et décision d'architecture validée.

### Phase 1 — Validation du besoin

- Valider les décisions D-01 à D-08.
- Confirmer l'adresse expéditrice et le sujet exact sur un e-mail réel.
- Confirmer le dossier Drive et les droits du compte exécutant le script.
- Recueillir des exemples anonymisés : CSV direct, ZIP valide, ZIP sans CSV et ZIP corrompu.
- Confirmer sur un échantillon réel que chaque ZIP contient exactement un CSV.
- Préciser le cinquième horaire habituel, uniquement pour le contrôle d'exploitation ; le traitement n'en dépendra pas.
- Préciser où Python sera exécuté : poste utilisateur, serveur ou ordonnanceur.
- Fixer la politique de rétention et le comportement attendu après une erreur partielle.

**Livrable :** spécification approuvée et jeux de recette disponibles.

### Phase 2 — Squelette Apps Script et configuration

- Créer le projet Apps Script et son manifeste.
- Définir les constantes de configuration et la validation au démarrage.
- Implémenter `setupFolderAndLabels()`.
- Configurer le fuseau `Europe/Paris`.
- Documenter les autorisations Gmail et Drive demandées.

**Livrable :** projet installable qui valide Gmail, le libellé et le dossier cible.

### Phase 3 — Fonctions pures et tests unitaires

- Implémenter `formatDateForFilename(date)`.
- Normaliser les noms issus des ZIP avec `getName()` ou le nom de base uniquement.
- Implémenter la détection CSV/ZIP insensible à la casse.
- Implémenter la génération de nom et la règle de collision.
- Tester les dates, caractères spéciaux, doubles extensions, noms identiques et fichiers sans extension.

**Livrable :** fonctions utilitaires testées indépendamment des services Google.

### Phase 4 — Traitement Gmail et pièces jointes

- Construire la requête Gmail à partir de `SEARCH_QUERY`.
- Paginer les résultats.
- Parcourir chaque message et ses pièces jointes.
- Traiter les CSV directs.
- Décompresser les ZIP avec `Utilities.unzip()` et filtrer les CSV.
- Isoler les exceptions au niveau du message.

**Livrable :** extraction contrôlée des blobs CSV à partir des messages de test.

### Phase 5 — Sauvegarde Drive et idempotence

- Sauvegarder chaque blob sous un nom unique.
- Mettre en œuvre la clé d'idempotence par message et par fichier.
- N'enregistrer le succès du message qu'après traitement complet.
- Appliquer le libellé Gmail selon la décision D-01.
- Ajouter `LockService` autour de l'orchestration.

**Livrable :** chaîne Gmail → Drive résistante aux relances et aux collisions.

### Phase 6 — Journalisation et exploitation

- Structurer les logs avec les niveaux INFO, WARN et ERROR.
- Ajouter un bilan par message et par exécution.
- Rédiger `README.md` : configuration, premier lancement manuel, autorisations, déclencheur et dépannage.
- Ajouter une procédure de reprise après échec.

**Livrable :** solution observable et exploitable par une autre personne.

### Phase 7 — Recette et mise en production

- Exécuter tous les cas de recette dans un dossier Drive de test.
- Vérifier une deuxième exécution sans création de doublons.
- Tester deux lancements rapprochés pour valider le verrou.
- Vérifier le comportement sur un message en erreur puis corrigé.
- Configurer le déclencheur de production.
- Surveiller les premières exécutions et contrôler les quotas Apps Script.

**Livrable :** procès-verbal de recette et déclencheur de production actif.

### Phase 8 — Raccordement de Python à Google Drive

- Activer l'API Google Drive dans le projet Google associé si nécessaire.
- Choisir OAuth utilisateur pour un poste local, ou un compte de service pour un traitement serveur.
- Partager le dossier Drive avec l'identité technique retenue selon les règles de l'organisation.
- Implémenter la liste paginée des CSV et leur téléchargement.
- Stocker localement les identifiants Drive déjà récupérés.
- Vérifier qu'une deuxième exécution ne retélécharge aucun fichier.
- Brancher ensuite le traitement métier Python sur le répertoire local d'entrée.

**Livrable :** téléchargement automatisé Drive → Python, authentifié et idempotent.

## 11. Critères d'acceptation

- **AC-01 / FR-01 :** étant donné un e-mail d'un autre expéditeur ou avec un autre sujet, quand le script s'exécute, alors aucun de ses fichiers n'est enregistré.
- **AC-02 / FR-04, FR-07 :** étant donné un message contenant un CSV direct, quand le traitement réussit, alors le fichier apparaît dans Drive avec la date de réception du message dans son nom.
- **AC-03 / FR-05, FR-06 :** étant donné un ZIP contenant exactement un CSV, quand le script s'exécute, alors ce CSV est enregistré ; avec zéro ou plusieurs CSV, aucun fichier de cette archive n'est enregistré, une anomalie est journalisée et le message n'est pas marqué traité.
- **AC-04 / FR-08, FR-09 :** étant donné deux fichiers aboutissant au même nom, quand ils sont sauvegardés, alors les deux existent et aucun contenu n'est remplacé.
- **AC-05 / FR-02, FR-10 :** étant donné un message déjà traité avec succès, quand le script est relancé, alors aucun nouveau fichier n'est créé.
- **AC-06 / FR-03 :** étant donné un ZIP corrompu suivi d'un message valide, quand le script s'exécute, alors le premier est signalé en erreur et le second est traité.
- **AC-07 / FR-10 :** étant donné un échec de sauvegarde partiel, quand le traitement se termine, alors le message n'est pas marqué comme complètement traité.
- **AC-08 / FR-12 :** étant donné un libellé absent, quand `setupFolderAndLabels()` est exécutée, alors le libellé est créé et le dossier cible est validé.
- **AC-09 / FR-14 :** étant donné deux exécutions concurrentes, quand la première détient le verrou, alors la seconde quitte proprement sans traiter les messages.
- **AC-10 / NFR-01, NFR-07 :** étant donné le dépôt et les logs, quand ils sont inspectés, alors aucun secret ni contenu CSV n'est exposé.
- **AC-11 / FR-15 :** étant donné un mail reçu à 07:40:25 et un déclencheur exécuté à 07:45, quand le fichier est créé, alors son nom contient `074025`, et non `074500`.
- **AC-12 / FR-16, NFR-08 :** étant donné cinq messages valides reçus dans la journée avec le même nom de CSV, quand le script s'exécute, alors cinq fichiers distincts sont présents dans Drive et le bilan indique cinq succès.
- **AC-13 / FR-17, FR-18 :** étant donné cinq nouveaux CSV dans Drive, quand Python s'exécute deux fois, alors les cinq fichiers sont téléchargés à la première exécution et aucun ne l'est à la seconde.
- **AC-14 / FR-19 :** étant donné le composant Python, quand son dépôt est inspecté, alors aucun jeton, mot de passe ou fichier d'identification réel n'est suivi par Git.

## 12. Matrice minimale de tests

| Cas | Entrée | Résultat attendu |
|---|---|---|
| T-01 | CSV direct valide | Un fichier correctement horodaté dans Drive |
| T-02 | Extension `.CSV` en majuscules | Fichier accepté |
| T-03 | ZIP avec exactement un CSV | L'unique CSV est enregistré |
| T-04 | ZIP sans CSV | Avertissement et message non marqué traité |
| T-05 | ZIP corrompu | Erreur isolée, message suivant traité |
| T-06 | Pièce jointe PDF | Ignorée et journalisée |
| T-07 | Deux noms identiques dans un message | Deux fichiers distincts sans écrasement |
| T-08 | Relance du même message | Aucun doublon |
| T-09 | Deux exécutions simultanées | Une seule traite les messages |
| T-10 | Dossier Drive invalide | Arrêt contrôlé avant traitement |
| T-11 | Message sans pièce jointe | Avertissement, état conforme à D-02 |
| T-12 | Date autour d'un changement d'heure | Nom produit dans le fuseau Europe/Paris |
| T-13 | Nom interne ZIP avec sous-dossier | Seul le nom de base sécurisé est utilisé |
| T-14 | Échec après un premier fichier sauvegardé | Reprise sans duplication avec la stratégie robuste |
| T-15 | ZIP avec deux CSV | Anomalie, aucun marquage de succès |
| T-16 | Cinq mails avec le même nom source | Cinq noms distincts fondés sur les dates de réception |
| T-17 | Déclencheur exécuté après réception | Le nom utilise l'heure du mail et non celle de l'exécution |
| T-18 | Deux exécutions du téléchargeur Python | Aucun second téléchargement |
| T-19 | Identifiants Google absents ou invalides côté Python | Échec contrôlé sans modifier le registre local |

## 13. Risques et mesures de réduction

| Risque | Impact | Mesure |
|---|---|---|
| Libellé appliqué au thread plutôt qu'au message | Message récent ignoré ou état ambigu | Suivi par identifiant de message dans `PropertiesService` |
| Déclencheurs simultanés | Doublons | `LockService` et idempotence par fichier |
| Limites d'exécution ou quotas Google | Traitement incomplet | Pagination, taille de lot configurable et reprise à l'exécution suivante |
| Archive volumineuse ou corrompue | Mémoire/temps dépassé | Contrôle de taille, `try...catch` ciblé et limites documentées |
| Faux type MIME | CSV valide ignoré | Accepter MIME CSV ou extension `.csv`, sans tenir compte de la casse |
| Collisions de noms | Ambiguïté ou doublon | Suffixe déterministe et clé d'idempotence |
| Secret présent dans l'historique Git | Compromission du compte | Rotation immédiate et nettoyage contrôlé de l'historique si nécessaire |

## 14. Définition de terminé

Le développement sera considéré comme terminé lorsque :

- toutes les décisions de la section 4 auront été validées ;
- tous les critères AC-01 à AC-14 seront vérifiés ;
- les tests T-01 à T-19 auront un résultat documenté ;
- aucun secret ne sera présent dans le code ou les logs ;
- le guide d'installation et de reprise sera utilisable par une personne autre que le développeur ;
- une relance Apps Script, une exécution concurrente et une relance Python ne créeront aucun doublon ;
- le déclencheur de production aura exécuté au moins un cycle surveillé avec succès.

## 15. Ordre conseillé pour démarrer

1. Sécuriser immédiatement le mot de passe du prototype Python.
2. Valider D-01 à D-08, en particulier le suivi par message, la règle de collision et le mode d'authentification de Python.
3. Obtenir des exemples anonymisés de pièces jointes réelles.
4. Créer le squelette Apps Script et le dossier Drive de test.
5. Développer les fonctions pures avec leurs tests.
6. Brancher Gmail, puis Drive, puis l'idempotence.
7. Réaliser la recette avant d'activer le déclencheur de production.
