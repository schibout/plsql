# Contrôle Prélèvement / Virement — Google Apps Script

## Description

Projet Apps Script de **contrôle des transferts bancaires**. Il surveille la boîte Gmail, identifie les e-mails de synthèse quotidienne (prélèvements et virements) reçus à **J-3**, et archive automatiquement leurs pièces jointes dans un dossier Google Drive, classées par date de réception.

Le projet contient deux scripts indépendants :

| Fichier | Flux couvert | Dossier Drive de destination |
|---|---|---|
| [downloadMailVirement.gs](downloadMailVirement.gs) | **Virements** (`Dalkia Virements importés du jour`, `[PROD] [PRELEVEMENTS ORACLE]`, `Calcul du poids`) | `1KFQvMNyQEy2H4niTTWg9jSeyCrJCS51Q` |
| [controlePrelevement.gs](controlePrelevement.gs) | **Prélèvements** (`[PRD] Synthèse quotidienne des prélèvements Dalkia`, `[PROD] [PRELEVEMENTS ORACLE]`) | `1skW6lJUvX1qlmw6RoLqE_94o5P1yu7o2` |
| extractLanceurCentraleText.gs | **Extraction de texte** (E-mails "Lanceur Centrale" du robot) | N/A (texte extrait, non archivé dans Drive) |

> ⚠️ **Les deux fichiers partagent le même espace de noms global.** Apps Script fusionne tous les `.gs` d'un projet : deux fonctions homonymes dans deux fichiers différents ne provoquent **aucune erreur visible**, la dernière chargée écrase silencieusement l'autre. C'est pourquoi tous les identifiants de `downloadMailVirement.gs` sont préfixés par `virement`. Voir [Dette technique connue](#dette-technique-connue).

## Fonctionnement (downloadMailVirement.gs)

1. **Calcul de la date cible** : date de référence − `DATE_OFFSET_DAYS` (3 jours par défaut).
2. **Recherche Gmail** : requête `after: … before: … has:attachment`, complétée par un pré-filtre `subject:` et l'exclusion du label de suivi déjà appliqué.
3. **Filtrage strict côté script** : pour chaque message, la date de réception doit correspondre **exactement** à la date cible, et l'objet doit correspondre à un des objets configurés (comparaison insensible à la casse, aux espaces multiples et aux préfixes `Re:` / `Tr:` / `Fwd:`).
4. **Sauvegarde des pièces jointes** : chaque fichier est écrit **sous son nom d'origine** dans un **sous-dossier daté** du dossier cible. C'est le sous-dossier qui porte l'information de date, les fichiers ne sont pas renommés.
5. **Marquage** : la conversation reçoit le label `Controle_Virement_Traité`, ce qui l'exclut des exécutions suivantes.
6. **Résumé** : un bilan chiffré est journalisé et retourné par la fonction.

### Arborescence produite

Toutes les pièces jointes des e-mails d'une même journée sont regroupées dans un sous-dossier nommé d'après la **date de réception des e-mails** (format `JJMMAAAA`). Pour des mails reçus le **05 juillet 2026** :

```
Controle_Transfert/            <- dossier cible (VIREMENT_CONFIG.DRIVE_FOLDER)
├── 05072026/                  <- sous-dossier créé automatiquement
│   ├── virements.csv          <- nom d'origine de la pièce jointe, inchangé
│   └── regroupements_edf.zip
└── 06072026/
    └── virements.csv
```

Le sous-dossier n'est créé **qu'au moment où une première pièce jointe doit y être enregistrée** : une journée sans e-mail correspondant ne laisse aucun dossier vide. S'il existe déjà (relance, rattrapage), il est réutilisé tel quel.

Pour revenir à un archivage à plat, passer `CREATE_DATE_SUBFOLDER` à `false` — mais attention : les noms des pièces jointes étant généralement identiques d'un jour à l'autre, tous les fichiers postérieurs au premier seraient alors considérés comme des doublons et ignorés.

## Prérequis

- Accès à **Google Apps Script** (script.google.com)
- Le compte exécutant le script doit :
  - recevoir les e-mails concernés dans sa boîte Gmail ;
  - disposer des **droits d'écriture** sur le dossier Drive cible.
- Autorisations OAuth demandées à la première exécution : **Gmail** (lecture + gestion des libellés) et **Drive** (création de fichiers).
- Aucun service avancé à activer.

## Utilisation

### Exécution automatique quotidienne

1. Ouvrir le projet Apps Script.
2. Menu **Déclencheurs** (icône réveil) → **Ajouter un déclencheur**.
3. Paramétrer :
   - Fonction à exécuter : **`virementRunAutomatically`**
   - Source de l'événement : **Basé sur le temps**
   - Type : **Minuteur journalier** → créneau conseillé : **6 h – 7 h**
4. Enregistrer et autoriser le script.

> 🔴 **Migration** : les points d'entrée ont été renommés (`runAutomatically` → `virementRunAutomatically`). Un déclencheur existant qui pointe vers `runAutomatically` exécute désormais le script **prélèvements**. Supprimer et recréer le déclencheur.

### Exécution manuelle

| Contexte | Fonction à lancer |
|---|---|
| Script lié à un Google Sheets | `virementRunManually` — ouvre une boîte de dialogue demandant la date de référence (JJ/MM/AAAA) |
| Script autonome / éditeur Apps Script | `virementRunForDateString('21/07/2026')` — à appeler depuis l'éditeur ou une fonction de test |

Dans les deux cas, la date saisie est la **date de référence** : la recherche porte sur J-3.

### Rattrapage d'une journée manquée

```javascript
// Rattrapage des e-mails reçus le 18/07/2026 (référence 21/07 − 3 jours)
function rattrapage() {
  virementRunForDateString('21/07/2026');
}
```

Le script est **idempotent** : un fichier déjà présent dans le dossier cible sous le même nom est ignoré, et les conversations déjà labellisées sont exclues de la recherche.

## Configuration

Tous les paramètres sont regroupés dans l'objet `VIREMENT_CONFIG` en tête de [downloadMailVirement.gs](downloadMailVirement.gs).

| Paramètre | Valeur par défaut | Description |
|---|---|---|
| `DRIVE_FOLDER` | `1KFQvMNyQEy2H4niTTWg9jSeyCrJCS51Q` | ID **ou** nom du dossier de destination. Un ID doit exister ; un nom est créé automatiquement s'il est absent. |
| `CREATE_DATE_SUBFOLDER` | `true` | Range les pièces jointes dans un sous-dossier daté. À `false` : archivage à plat dans `DRIVE_FOLDER`. |
| `SUBFOLDER_DATE_FORMAT` | `'ddMMyyyy'` | Format du nom du sous-dossier (`ddMMyyyy` → `05072026`, `yyyy-MM-dd` → `2026-07-05`) |
| `EMAIL_SUBJECTS` | 3 objets | Objets des e-mails recherchés. En mode `prefix`, indiquer uniquement le **début invariant** de l'objet ; la partie variable (date, n° de lot, montant) est ignorée. |
| `SUBJECT_MATCH_MODE` | `'prefix'` | `'prefix'` : l'objet doit commencer par la chaîne (tolère une date ou un n° de lot ajoutés). `'exact'` : correspondance stricte. |
| `DATE_OFFSET_DAYS` | `3` | Décalage en jours (J-N) |
| `TIMEZONE` | Fuseau du script | Utilisé pour le calcul de la date cible et le nom du sous-dossier |
| `ALLOWED_EXTENSIONS` | `[]` | Extensions autorisées, sans le point (ex. `['csv','zip']`). Vide = tout accepter. |
| `MAX_THREADS_PER_RUN` | `500` | Garde-fou sur le nombre de conversations analysées |
| `APPLY_LABEL` | `true` | Applique un label pour ne pas retraiter les mêmes e-mails |
| `PROCESSED_LABEL_NAME` | `Controle_Virement_Traité` | Nom du label de suivi |
| `USE_SUBJECT_PREFILTER` | `true` | Ajoute un filtre `subject:` à la requête Gmail pour réduire le volume analysé |
| `INCLUDE_INLINE_IMAGES` | `false` | À `false`, les logos de signature ne sont pas archivés |
| `DRY_RUN` | `false` | Mode simulation : journalise tout sans rien écrire dans Drive |
| `MAX_RUNTIME_MS` | `300000` | Arrêt propre avant la limite d'exécution Apps Script (6 min) |

### Valider une modification sans risque

Passer `DRY_RUN: true`, exécuter, lire les journaux, puis repasser à `false`. En mode simulation aucun fichier n'est créé et aucun label n'est appliqué.

## Points d'entrée

| Fonction | Rôle |
|---|---|
| `virementRunAutomatically()` | Point d'entrée du déclencheur quotidien |
| `virementRunManually()` | Test manuel avec saisie de date (nécessite une UI) |
| `virementRunForDateString(dateString)` | Rattrapage sur une date précise, sans UI |
| `virementProcessForDate(date)` | Cœur du traitement — retourne le résumé |

Les fonctions dont le nom se termine par `_` sont privées (non listées dans le menu d'exécution de l'éditeur).

## Diagnostic

| Symptôme | Cause probable |
|---|---|
| `Aucune conversation ne correspond à la requête` | Date cible sans e-mail, ou conversations déjà labellisées. Vérifier la requête journalisée en la collant dans la barre de recherche Gmail. |
| `Aucun e-mail dont l'objet correspond` | L'objet réel a changé. Passer `SUBJECT_MATCH_MODE` à `'prefix'` et vérifier `EMAIL_SUBJECTS`. |
| `dossier Drive introuvable pour l'ID …` | ID erroné ou dossier non partagé avec le compte exécutant. |
| Un dossier a été créé avec un nom ressemblant à un ID | Ancien bug corrigé : `DRIVE_FOLDER` gère désormais ID et nom. Supprimer le dossier parasite. |
| Traitement `INCOMPLET` | `MAX_THREADS_PER_RUN` ou `MAX_RUNTIME_MS` atteint. Relancer la même date : le traitement reprend là où il s'est arrêté grâce au label. |

Les journaux sont consultables dans l'éditeur via **Exécutions** (panneau gauche).

## Avertissements

- Les bornes `after:` / `before:` de la recherche Gmail sont interprétées dans le **fuseau du compte Gmail**, qui peut différer de `TIMEZONE`. Le script revérifie la date message par message, mais un décalage de fuseau important peut faire sortir un e-mail de la fenêtre de recherche initiale.
- Le label de suivi est appliqué **à la conversation entière**. Si un nouveau message arrive plus tard dans une conversation déjà traitée, il ne sera pas repris.
- Les pièces jointes conservent leur nom d'origine. Si **deux e-mails de la même journée** portent une pièce jointe de même nom (deux envois successifs, un correctif), la seconde est ignorée comme un doublon et **n'écrase pas** la première. Le cas est visible dans les journaux (`Déjà présent, ignoré`) et compté dans « Fichiers ignorés » du résumé.
- Modifier `SUBFOLDER_DATE_FORMAT` en cours d'exploitation ne renomme pas les sous-dossiers existants : l'historique se retrouve réparti entre deux conventions de nommage.
- Si un sous-dossier daté est renommé ou déplacé manuellement, la relance de la même date en recrée un nouveau et réimporte les fichiers (la détection de doublon se fait à l'intérieur du sous-dossier).

## Dette technique connue

`controlePrelevement.gs` déclare encore des fonctions aux noms génériques (`runAutomatically`, `runManually`, `processEmailsForDate`, `getOrCreateLabel`, `isAllowedExtension`) et une constante `CONFIG`. Tant qu'aucun autre fichier du projet n'utilise ces noms, le comportement est correct. Il est recommandé de lui appliquer le même préfixage (`prelevement…`) lors de sa prochaine évolution, et de factoriser la logique commune aux deux flux dans un fichier partagé.
