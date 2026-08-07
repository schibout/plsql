# UpdateCloture — Google Apps Script

## Description

Script Google Apps Script utilisé dans le cadre de la **clôture financière mensuelle**.  
Il recherche tous les fichiers SQL dans un dossier Google Drive spécifique, remplace l'ancien libellé de période (ex. `MAR-26`) par le nouveau (ex. `AVR-26`), puis écrase chaque fichier avec le contenu mis à jour.

## Fonctionnement

1. **Recherche des fichiers** : Le script parcourt un dossier Google Drive identifié par son ID (`1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl`) et filtre les fichiers dont le type MIME contient `SQL`.
2. **Lecture du contenu** : Pour chaque fichier trouvé, le contenu texte est extrait via un Blob.
3. **Remplacement de la période** : Toutes les occurrences de `MAR-26` dans le texte sont remplacées par `AVR-26`.
4. **Mise à jour du fichier** : Le fichier original est écrasé sur Google Drive avec le nouveau contenu, en conservant son nom et son type MIME.

## Prérequis

- Accès à **Google Apps Script** (script.google.com)
- Le service avancé **Drive API v2** doit être activé dans le projet Apps Script :
  1. Dans l'éditeur, cliquer sur **"Services"** (icône `+` dans le panneau gauche)
  2. Rechercher **"Drive API"**, sélectionner la version **v2**
  3. Cliquer **"Ajouter"**
  > Sans cette étape, l'erreur `ReferenceError: Drive is not defined` sera levée à l'exécution.
- Droits d'écriture sur le dossier Google Drive cible

## Utilisation

1. Ouvrir le projet Apps Script : [Cloture finance](https://script.google.com/home/projects/1d-rUhbZPmn1mMfSoBRBsnrtoTmem0Rc10yhdhHTUjOuYubfp66iJknZ/edit)
2. Mettre à jour les libellés de période dans le code (ex. remplacer `MAR-26` → `AVR-26` par `AVR-26` → `MAI-26`) avant chaque clôture mensuelle.
3. Exécuter la fonction `UpdateCloture`.

## Paramètres à adapter chaque mois

| Paramètre | Exemple actuel | Description |
|---|---|---|
| ID du dossier Drive | `1qMxR3HjEy7axF8sEjfm2ytRnSxl-lyDl` | Dossier contenant les fichiers SQL |
| Ancienne période | `MAR-26` | Libellé à remplacer |
| Nouvelle période | `AVR-26` | Libellé de remplacement |

## Avertissements

- Le script **écrase directement** les fichiers sources sans créer de sauvegarde. Il est recommandé de versionner ou de sauvegarder les fichiers avant exécution.
- Le remplacement est global : toutes les occurrences du libellé sont remplacées dans chaque fichier.
