Rôle : Tu es un expert en développement Google Apps Script et en automatisation Google Workspace.

Objectif : Écrire un script Google Apps Script qui automatise le téléchargement de fichiers depuis Google Drive en se basant sur les informations contenues dans un fichier CSV.

Description du processus :

Le script doit lire une feuille de calcul Google Sheet spécifique.
Le classeur Google Sheet est identifié par l'ID `1QNJUUM8lJcHkVOQTNguInGvmI5xZX69EwUqxYL0al1Q`.
La feuille spécifique à lire dans ce classeur a le GID `1898807058`.

**Structure de la feuille de calcul `OrdonnanceurCentral` :**

*   **Colonne D (4ème colonne)** : Contient l'**ID** d'un dossier Google Drive source.
*   **Colonne G (7ème colonne)** : Contient le **nom exact** du fichier à télécharger, qui se trouve dans le dossier spécifié dans la colonne D.

**Logique de fonctionnement :**

1.  **Localiser la feuille de calcul** : Le script doit ouvrir le classeur Google Sheet par son ID et sélectionner la feuille par son GID.
2.  **Parcourir la feuille de calcul** : Lire toutes les données de la feuille, en ignorant la première ligne (qui contient les en-têtes).
3.  **Itérer sur les lignes** : Pour chaque ligne du fichier CSV :
    a.  Récupérer l'ID du dossier depuis la colonne D.
    b.  Récupérer le nom du fichier depuis la colonne G.
    c.  Vérifier que l'ID du dossier et le nom du fichier ne sont pas vides.
    d.  Accéder au dossier Google Drive en utilisant son ID.
    e.  Rechercher le fichier par son nom exact à l'intérieur de ce dossier.
    f.  Si le fichier est trouvé, le copier dans un dossier de destination unique.

**Gestion du dossier de destination :**

*   Tous les fichiers copiés doivent être placés dans le dossier Google Drive de destination identifié par l'ID suivant : `1__xp-bdnQJlb_W7aJ9OerGsxgyVbI0qq`.
*   Le script ne doit **pas** créer le dossier. Il doit utiliser cet ID pour y accéder directement. Si le dossier n'est pas accessible (droits manquants, dossier supprimé), une erreur doit être enregistrée dans les journaux.

**Gestion des erreurs :**

*   Le script doit journaliser (avec `Logger.log()`) les erreurs rencontrées, par exemple :
    *   Le dossier source (spécifié par l'ID en colonne D) n'a pas été trouvé.
    *   Le fichier (spécifié par le nom en colonne G) n'a pas été trouvé dans le dossier source.
    *   La ligne du CSV est malformée (colonne D ou G vide).

**Livrables attendus :**

*   Le code Google Apps Script complet, propre et commenté, dans une fonction principale (par exemple, `processLauncherFile()`).

---

### Volet 2 : Extraction de données depuis les e-mails "Lanceur Central"

**Rôle :** Tu es un expert en Google Apps Script, spécialisé dans l'automatisation Gmail et l'analyse de contenu (parsing HTML).

**Objectif :** Écrire un script qui recherche des e-mails spécifiques, en extrait un tableau HTML, et enregistre ces données dans un fichier CSV sur Google Drive.

**Description du processus :**

1.  **Recherche des e-mails :**
    *   Le script doit rechercher dans Gmail les e-mails non lus (ou non encore traités).
    *   **Expéditeur :** Doit provenir de `dsin-rpa-robot1@dalkia.fr`.
    *   **Sujet :** Doit commencer par `[Lanceur Central]`.
    *   **Période :** Uniquement les e-mails reçus durant l'année **2026**.

2.  **Extraction du tableau :**
    *   Pour chaque e-mail trouvé, le script doit analyser le corps du message au format HTML.
    *   Il doit trouver la première balise `<table>` dans le corps de l'e-mail.
    *   Il doit extraire toutes les lignes (`<tr>`) et cellules (`<td>`, `<th>`) de ce tableau pour les convertir en un tableau de données (Array 2D).

3.  **Génération du fichier CSV :**
    *   Les données extraites du tableau doivent être formatées en une chaîne de caractères CSV.
    *   Le séparateur de colonnes doit être le **point-virgule (`;`)**.
    *   Le script doit générer un fichier CSV dans le dossier de destination (`1__xp-bdnQJlb_W7aJ9OerGsxgyVbI0qq`).
    *   Le nom du fichier doit être unique, par exemple en incluant la date du jour : `Resultat_Lanceur_Central_AAAAMMJJ.csv`.

4.  **Gestion des e-mails traités :**
    *   Une fois qu'un e-mail a été traité avec succès, il doit être marqué comme lu ou recevoir un label spécifique (ex: `Lanceur_Traité`) pour éviter d'être traité à nouveau lors des prochaines exécutions.

**Livrables attendus :**

*   Le code Google Apps Script complet et commenté pour cette nouvelle fonctionnalité.