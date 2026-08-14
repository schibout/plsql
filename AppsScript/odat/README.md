# rapportOdat — Rapport quotidien Control-M (FIN-FINANCE)

## Description

Script Google Apps Script qui exploite le **rapport quotidien Control-M** reçu par e-mail
(`Report_ctm_<AAMMJJ>_13_<Mois_Année>.zip`, contenant un unique CSV).

Ce rapport couvre une vingtaine d'applications et ~1260 tâches. Le script en isole
**FIN-FINANCE** et n'envoie un e-mail HTML **que s'il contient au moins un job en échec**.

Tout se déroule **en mémoire** : aucun fichier n'est écrit sur Google Drive.

## Fonctionnement

1. **Recherche Gmail** du rapport le plus récent non encore traité, sur les 3 derniers jours.
2. **Contrôles** : adresse réelle de l'expéditeur, sujet, présence d'une pièce jointe `Report_ctm_*.zip`.
3. **Décompression en mémoire** de l'archive et lecture du CSV en UTF-8.
4. **Analyse** : filtre sur `Application = FIN-FINANCE`, exclusion des chaînes conteneurs `SMART Table`.
5. **Envoi** : e-mail HTML avec la synthèse par statut et le détail des jobs `Ended Not OK`,
   regroupés par chaîne. **Aucun envoi si aucun échec.**
6. **Mémorisation** du message traité, pour ne pas renvoyer deux fois le même rapport.

### Sur le rapport du 13/08/2026 (fichier d'exemple du dépôt)

| Mesure | Valeur |
|---|---|
| Lignes FIN-FINANCE | 236 |
| Chaînes conteneurs exclues (`SMART Table`) | 64 |
| Tâches réelles analysées | 172 |
| Répartition | `Ended OK` 148 · `Wait for Event` 18 · `Ended Not OK` 5 · `Executing` 1 |
| **Jobs en échec signalés** | **5, sur 3 chaînes** |

## Points d'attention traités par le script

- **Le CSV ne peut pas être découpé par `split(';')`.** Plusieurs descriptions contiennent un
  point-virgule entre guillemets, par exemple `"Archivage des repertoires IN; OUT et OUT_SEPA"` :
  un découpage naïf décale toutes les colonnes suivantes. Le script utilise
  `Utilities.parseCsv(contenu, ';')`.
- **La colonne `Run Time` du rapport est inexploitable** (valeurs `2220`, `1300`, `1114`, sans
  rapport avec les horodatages). Les durées sont **recalculées** depuis `Start Time` / `End Time`.
- **Les colonnes sont repérées par leur nom**, jamais par leur position : l'en-tête se termine
  par un `;` (colonne finale vide) et l'ordre n'est pas garanti d'une version à l'autre.
- **Les `SMART Table` sont exclues** : ce sont les chaînes conteneurs, dont le statut ne fait que
  refléter celui des jobs qu'elles contiennent. Sur le fichier d'exemple, 2 des 7 `Ended Not OK`
  sont des conteneurs — les garder ferait compter deux fois le même incident.
- **Les dates sont en anglais US** (`August 13, 2026 7:52:56 PM`) et analysées par un parseur
  dédié, `new Date()` dépendant de la locale du moteur. L'Odate est le 13/08 mais certains jobs
  se terminent le 14/08 : les durées à cheval sur minuit sont correctement mesurées.
- **Le contrôle de l'expéditeur porte sur l'adresse réelle**, pas sur le nom affiché :
  `GmailApp.search('from:')` matche aussi le nom d'affichage, donc un expéditeur externe se
  faisant appeler « control-m@… » passerait le filtre de la requête.

## Prérequis

- Accès à **Google Apps Script** (script.google.com).
- Services standard uniquement (`GmailApp`, `MailApp`, `Utilities`, `PropertiesService`) :
  aucun service avancé à activer.
- Le compte exécutant le script doit **recevoir** le mail de rapport Control-M.

## Installation

1. Créer un projet Apps Script et y coller `rapportOdat.gs`.
2. Exécuter **`odat_listSenders()`** et accepter les autorisations demandées.
   La fonction liste les expéditeurs, sujets et noms de pièces jointes réels sur 180 jours.
3. Renseigner le bloc `ODAT_CONFIG` en tête de fichier avec les valeurs découvertes :

| Paramètre | Rôle |
|---|---|
| `ALLOWED_SENDERS` | **Obligatoire.** Expéditeur(s) légitime(s) du rapport. Vide ⇒ le script refuse de tourner. |
| `SUBJECT` | Sujet attendu du mail. Vide ⇒ pas de filtre sur le sujet. |
| `RECIPIENTS` | **Obligatoire.** Destinataires du rapport, séparés par des virgules. |
| `ADMIN_EMAIL` | Adresse prévenue en cas d'anomalie technique. **Fortement recommandé** (voir plus bas). |
| `APPLICATION` | Application à isoler. Par défaut `FIN-FINANCE`. |
| `SEARCH_WINDOW_DAYS` | Profondeur de la recherche Gmail, en jours. |

4. Valider le rendu avec **`odat_dryRun()`** (voir ci-dessous).
5. Créer un déclencheur **journalier** sur `odat_runReport()`, calé après l'heure d'arrivée
   habituelle du mail Control-M.

## Fonctions disponibles

| Fonction | Rôle |
|---|---|
| `odat_runReport()` | Traitement complet et envoi. **Fonction à planifier.** |
| `odat_dryRun()` | Idem, mais crée un **brouillon Gmail** au lieu d'envoyer, et ne mémorise ni ne labellise rien. Relançable à volonté. |
| `odat_listSenders()` | Diagnostic : expéditeurs, sujets et pièces jointes réels des rapports. |
| `odat_showState()` | Diagnostic : messages déjà traités. |
| `odat_resetState()` | Purge l'état mémorisé — le prochain rapport sera retraité et **renvoyé**. |

## Surveillance : pourquoi `ADMIN_EMAIL` est important

Aucun mail n'est envoyé quand tout va bien. Sans `ADMIN_EMAIL`, il devient impossible de
distinguer « aucun échec » de « le script est cassé ». Une alerte technique y est donc envoyée
dans les cas suivants :

- configuration incomplète (`ALLOWED_SENDERS` ou `RECIPIENTS` vide) ;
- aucun rapport exploitable trouvé dans la fenêtre de recherche ;
- archive ZIP illisible ou sans CSV ;
- colonnes attendues absentes — le format du rapport Control-M a changé ;
- **0 ligne pour l'application configurée** alors que le CSV est rempli : l'application a
  probablement été renommée côté Control-M.

## Recette

1. `odat_dryRun()` → ouvrir le brouillon et vérifier :
   - la synthèse `148 / 18 / 5 / 1` et « 5 job(s) en échec sur 3 chaîne(s) » ;
   - que la description **`Archivage des repertoires IN; OUT et OUT_SEPA` s'affiche en entier**,
     avec l'hôte `ldkfinp11` et l'order id `3y6fb` en face — c'est le témoin que le parsing
     des champs entre guillemets fonctionne ;
   - le rendu sur mobile.
2. `odat_runReport()` en réel → mail reçu ; **relancer immédiatement** → aucun second envoi.
3. Voie « aucun échec » : passer temporairement `FAILED_STATUSES` à un statut inexistant,
   `odat_resetState()` puis `odat_runReport()` → aucun mail, journal explicite. Restaurer.
4. Garde-fou : mettre `APPLICATION` à une valeur inexistante → alerte reçue sur `ADMIN_EMAIL`.
   Restaurer.

## Avertissements

- `odat_resetState()` **provoquera un nouvel envoi** du dernier rapport à la prochaine exécution.
- Le label Gmail (`z_odat_traite`) porte sur la **conversation**, pas sur le message : les
  rapports quotidiens ayant un sujet identique, Gmail peut les regrouper. Ce n'est donc pas le
  label qui garantit l'unicité de l'envoi, mais l'**ID de message mémorisé** dans les propriétés
  du script.
- En cas de renvoi du rapport dans la journée, c'est le message **le plus récent** qui fait foi.
