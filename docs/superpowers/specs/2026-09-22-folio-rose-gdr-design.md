# Folio Rose × GDR : rapprocher les rejets GDR avec le contrôle des flux

> Note (22/09/2026) : la fonction décrite ici s'appelle désormais **Ctrl Flux** dans ODAT Watch (modules `ctrl_flux.py`, `ui_ctrl_flux.py`, `rapport_ctrl_flux.py`). Le texte ci-dessous garde le nom d'origine « Folio Rose », tel qu'il était au moment de la conception.

Date : 22/09/2026 · État : **implémenté** le 22/09/2026 (module `odat_watch/gdr.py`, colonne « GDR (rejets) »
dans l'onglet et le rapport). Les réponses aux questions ouvertes sont reportées en fin de document.

## Ce qu'on a

- **Arrivée des fichiers** : chaque jour, le mail « Etat de synthèse des rejets GL, AP et AR au JJ/MM/AAAA »
  (`noreply-gdr@prod.dalkia.fr`) est récupéré par le profil Apps Script `gdr_rejets_synthese`
  (Projet_Virements, commit « GDR ») vers le dossier Drive `1fF_34VEeM3i8C9Db29rSdzkpNw0EdIVG`, avec le préfixe
  `JJMMAAAA_`. Localement les fichiers sont dans `ODAT/GDR/` (150 fichiers, du 28/05 au 29/06/2026).
- **Trois fichiers par envoi** : `…_Synthese_des_rejets_AP_au_…`, `…_AR_…`, `…_GL_…` ; un second envoi dans la
  journée donne le suffixe `_02`. Chaque fichier est une **photo** des rejets encore ouverts à cette date : une
  pièce (`ID GDR`) revient d'un jour sur l'autre tant qu'elle n'est pas traitée, et disparaît ensuite.
- **Format** : CSV `;`, UTF-8 avec BOM (quelques caractères illisibles `�` dans certains fichiers), CRLF.
  Colonnes communes : Code Rejet, Libellé rejet, **Fichier Source**, Appli Source, **Folio**, Région, Société,
  **Numéro pièce**, Date pièce comptable, …, Date création GDR, Date Arrêté comptable, Fichier SRC technique,
  **ID GDR** (la pièce), **Line GDR** (la ligne, unique).
  - AP : `Montant Ligne`, `Compte Frs`, `Compte local` ; la ligne sur le compte 401 porte le total de la facture,
    les suivantes (code rejet vide) sont les lignes de la même pièce.
  - AR : `Montant Ligne`, `Sens (Dbt/Cdt)`, `Signe`, `Sous compte`.
  - GL : `Montant débit`, `Montant crédit`, une pièce = ses lignes débit + crédit.
- **Clé de rapprochement avec Folio Rose** (vérifié sur les données) :
  - `Fichier Source` GDR = colonne « Nom fichier transmis » Folio Rose, **à l'identique**
    (ex. `CEL01_SRC_FACTURESFOURNISSEURS_020626-200619_ST_CEL01_639160275797193567_001`, ou
    `FAC02_SRC_ECRITURESGL_270526-171607` pour le GL, ou `CDPG.NC4.EXPORT.…` pour les flux compta).
  - `Folio` GDR = `CEE - CELERIS Achats Electricité` → **3 premières lettres** = folio Folio Rose (`CEE`).
  - Montant : à comparer avec l'**écart débit** de la ligne Folio Rose (ce qui manque dans SI Finance), pas
    avec le montant amont. Nombre de pièces rejetées ↔ écart nombre de pièces.

## Ce qu'on veut

Quand une ligne Folio Rose (folio + fichier) est en écart et que la GDR contient, pour le même fichier et le
même folio (3 lettres), des pièces rejetées dont le montant explique l'écart, le signaler : « pièce(s) dans la
GDR ». Recharger chaque jour les nouveaux fichiers sans effort. Plus tard : rapprocher aussi côté Oracle.

## Plan proposé

### 1. Lecture et import des fichiers GDR (`odat_watch/gdr.py`)

- `lire_fichier(chemin)` → type (AP/AR/GL), date du fichier (préfixe `JJMMAAAA`), rang (`_02`), et un
  DataFrame normalisé : `line_gdr`, `id_gdr`, `type`, `code_rejet` (reporté sur les lignes de continuation où
  il est vide), `libelle_rejet`, `fichier_source`, `folio_libelle`, `folio` (3 lettres), `societe`, `region`,
  `numero_piece`, `date_piece`, `compte`, `montant_debit`, `montant_credit`, `description`, `date_creation_gdr`,
  `date_arrete`, `fichier_src_technique`.
  Montant d'une pièce : AP = ligne sur compte 401 (sinon somme des lignes) ; AR = `Signe` × `Montant Ligne`
  agrégé par sens ; GL = somme des débits (et des crédits) de la pièce.
- Tables SQLite : `gdr_fichiers` (nom, hash, type, date, rang, importé le, nb lignes) et `gdr_lignes`
  (`line_gdr` unique, colonnes ci-dessus, `premier_fichier_id`, `dernier_fichier_id`, `present`).
  Même mécanique que Folio Rose : un fichier met à jour, une pièce absente de la dernière photo de son type
  passe `present = 0` (= rejet traité, on garde la date de disparition). **Pas de vidage** : l'historique
  sert à dater l'apparition et la résolution des rejets.
- Import : bouton « Importer le dossier GDR » + **balayage automatique** du dossier (`[gdr] racine` dans
  `config.ini`, défaut `ODAT/GDR`) à l'ouverture de l'onglet : tout fichier dont le hash est inconnu est
  importé, dans l'ordre date puis rang. Un jour = la dernière photo du jour (`_02` remplace le premier envoi).

### 2. Rapprochement avec Folio Rose (`gdr.py` : `rapprocher_folio_rose(lignes_fr, gdr_courant)`)

- Agrégation GDR par (`fichier_source`, `folio`) sur les pièces présentes : `nb_pieces` (ID GDR distincts),
  `montant_rejete` (somme des montants de pièce), liste des pièces (numéro, code rejet, libellé, montant).
- Jointure avec les lignes Folio Rose sur `fichier` = `fichier_source` et `folio` = `folio` (3 lettres).
- Verdict par ligne :
  - **« pièce(s) dans la GDR »** : |écart débit − montant rejeté| < 0,01 (et, si renseigné, écart nb pièces =
    nb pièces) ;
  - **« partiellement dans la GDR »** : montant rejeté non nul mais différent de l'écart (on affiche le reste) ;
  - vide sinon.
- Affichage dans l'onglet Folio Rose : nouvelle colonne **« GDR »** (texte du verdict + `n pièces · X €`)
  à côté de « Commentaire », et un dépliant sous le tableau listant les pièces rejetées de la ligne
  sélectionnée. Même colonne dans le rapport HTML. Le commentaire de l'export n'est **pas** modifié : il vient
  du CSV Folio Rose et serait écrasé au chargement suivant. Couleur : proposition d'un violet clair pour les
  lignes entièrement expliquées par la GDR (à confirmer, voir questions).

### 3. Onglet « GDR » (ou section dans Folio Rose)

- Tuiles : pièces rejetées ouvertes par type (AP/AR/GL), nouvelles du jour, résolues depuis la veille.
- Tableau des rejets ouverts (filtres type, code rejet, folio, fichier, société), colonne « Folio Rose »
  indiquant si la pièce explique une ligne en écart.
- Historique des imports (fichiers, dates, nb lignes) et des pièces disparues (date de résolution).

### 4. Plus tard (hors périmètre de cette itération)

- Rapprochement Oracle des rejets GDR (les pièces rejetées sont-elles réinjectées / présentes dans
  l'interface ou les tables définitives ?). L'agrégat par (fichier, folio, type) de la GDR pourra alimenter
  la règle « orange » existante.
- Envoi Apps Script → poste local : aujourd'hui `ODAT/GDR` s'arrête au 29/06 ; à brancher sur le dossier Drive
  ou sur un téléchargement quotidien.

### 5. Tests

- Unitaires sur les fichiers réels de juin (`ODAT/GDR`) : lecture des trois types, report du code rejet,
  montant de pièce, import successif (présent / disparu, `_02`), agrégation et verdict.
- AppTest sur l'onglet Folio Rose avec un jeu GDR forgé pour obtenir un « pièce dans la GDR ».

## Réponses retenues (22/09/2026)

1. **Plusieurs montants possibles**, dans cet ordre : l'écart débit ; le montant de la pièce (rejet total) ;
   la pièce moins le montant Oracle OA ; la pièce moins le montant de l'interface. Le flux explique pourquoi :
   les écritures entrent d'abord dans l'interface, puis dans Oracle ; une pièce peut être rejetée en totalité
   ou partiellement, et le rejet vaut alors la part non intégrée. La première correspondance trouvée est
   affichée avec son libellé, pour que la règle appliquée reste lisible.
2. **Colonne « GDR (rejets) »** dédiée, plus une couleur violette pour les lignes expliquées (pas pour les
   « probable »). Le commentaire de l'export n'est pas touché.
3. **Oui** : dès que le fichier et le folio se retrouvent dans la GDR, la ligne est signalée « probable »,
   même si aucun montant ne tombe juste. Il y a de fortes chances que la pièce soit la même, intégrée
   partiellement.
4. Balayage automatique du dossier `[gdr] racine` à l'ouverture de l'onglet (défaut `..\ODAT\GDR`).
5. Pas d'onglet séparé pour l'instant : colonne, tuile et dépliant dans Folio Rose.

## Reste à faire

- Rapprochement Oracle des pièces rejetées (sont-elles réinjectées dans l'interface ou les tables définitives ?).
- Alimentation du dossier `ODAT/GDR` sur le poste : aujourd'hui les fichiers s'arrêtent au 29/06/2026.
- Éventuel onglet GDR (rejets ouverts par type, nouveaux du jour, résolus depuis la veille).
