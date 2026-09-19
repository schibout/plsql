# Cas de test — Import CTM Gmail vers Google Drive

## Tests unitaires automatisés

Exécuter `runCtmUnitTests()` dans l'éditeur Google Apps Script.

| ID | Fonction | Résultat attendu |
|---|---|---|
| UT-01 | Formatage de la date | `2026-09-19 07:40:25` devient `20260919_074025` |
| UT-02 | Construction du nom | L'horodatage précède le nom CSV d'origine |
| UT-03 | Nettoyage du nom | Les chemins ZIP et caractères de contrôle sont retirés |
| UT-04 | Détection CSV | Les extensions sont insensibles à la casse |
| UT-05 | Détection MIME | `text/csv` est reconnu même sans extension |
| UT-06 | Rejet de format | Un PDF n'est pas considéré comme un CSV |
| UT-07 | Détection ZIP | Les extensions ZIP sont insensibles à la casse |
| UT-08 | Collision | Le suffixe `_02` est placé avant `.csv` |
| UT-09 | Expéditeur | L'adresse est extraite d'un champ avec nom affiché |
| UT-10 | Recherche Gmail | La fenêtre de recherche est présente et aucun `-label:` n'est utilisé |

## Recette d'intégration

Utiliser un dossier Drive de test et des messages anonymisés.

| ID | Scénario | Résultat attendu |
|---|---|---|
| IT-01 | Mail valide avec un ZIP contenant un CSV | Un CSV est enregistré et le message est mémorisé |
| IT-02 | Mail reçu à 07:40:25, script lancé à 07:45 | Le nom contient `074025`, pas `074500` |
| IT-03 | Cinq mails, même nom de ZIP et de CSV | Cinq fichiers distincts sont présents dans Drive |
| IT-04 | Relance du script | Aucun fichier supplémentaire n'est créé |
| IT-05 | Nouveau mail dans une conversation déjà labellisée | Le nouveau message est quand même traité |
| IT-06 | ZIP vide | Aucun fichier créé, message non mémorisé, erreur journalisée |
| IT-07 | ZIP avec deux CSV | Aucun fichier créé, message non mémorisé, erreur journalisée |
| IT-08 | ZIP corrompu | L'erreur est isolée et les autres messages sont traités |
| IT-09 | Expéditeur incorrect avec le bon objet | Message rejeté |
| IT-10 | Objet proche mais non identique | Message rejeté |
| IT-11 | Dossier Drive inaccessible | Arrêt avant modification des messages |
| IT-12 | Deux exécutions simultanées | Une seule obtient le verrou et traite les messages |
| IT-13 | Nom déjà présent pour un autre message | Suffixe `_02`, puis `_03`, sans écrasement |
| IT-14 | Fichier créé mais état perdu | Le marqueur Drive permet de reconnaître le fichier à la relance |
| IT-15 | Libellé absent | `setupFolderAndLabels()` le crée |
