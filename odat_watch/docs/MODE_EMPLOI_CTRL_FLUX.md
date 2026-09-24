# Mode d'emploi — Ctrl Flux

Ctrl Flux contrôle les fichiers transmis par les applications amont à Oracle Finance : ce qui est parti de
l'amont (**App Amont**) doit se retrouver dans le SI Finance, sinon la ligne est **en écart**. Le cycle du
matin : **charger** le dernier export Ctrl Flux, **lire** les couleurs et les écarts, **expliquer** chaque écart
(rejet GDR, pièce en interface Oracle, compensation entre lignes), **rapprocher** ce qui se compense,
**diffuser** le rapport HTML. L'historique, la GDR et la carte des flux servent à comprendre et à remonter
le temps.

## Ctrl Flux

La **situation actuelle** : le dernier export chargé, et seulement lui.

### 1. Charger

- **📥 Importer des exports Ctrl Flux** : glisser-déposer un ou plusieurs `ExportCSV-JJ-MM-AAAA.csv`, puis
  **Importer les fichiers déposés** ; ou **Importer le dossier ControleFolioRose** pour tout le dossier.
- Un lot est chargé du plus ancien au plus récent (date du nom) : à la fin, le tableau montre **le plus récent**.
- Chaque fichier est aussi versé dans **📚 Historique**. Les **rapprochements** sont conservés d'un chargement
  à l'autre : ils sont attachés à la clé folio + date + fichier transmis.
- Les exports **GDR** déposés dans le dossier GDR sont lus automatiquement à l'ouverture de l'onglet
  (journal dans « 🧾 Imports GDR »).

### 2. Contrôler dans Oracle (facultatif)

**🅾 Contrôler dans Oracle** interroge, pour chaque couple folio + fichier, l'interface et les tables
définitives (clients, fournisseurs, GL). Il faut `config.ini` renseigné et un accès Oracle (poste Dalkia). Les
colonnes Oracle (Nb Pièces Interface OA, Montant Interface OA, Nb Pièces OA, Montant OA, écarts calculés,
statut OK / KO) n'apparaissent qu'après ce contrôle.

### 3. Lire

- **Tuiles** : lignes, folios, lignes rapprochées, OK / KO Oracle, lignes vues en GDR.
- **Filtres** : Type, Statut, Folio, **Masquer les rapprochées** (coché par défaut).
- **Colonnes affichées** (volet 🧮) : choisir les colonnes ; *Somme Amont Fichier* et *Somme Écart Fichier* sont
  décochées par défaut ; vider la liste rétablit le choix par défaut. Le commentaire est en dernière colonne.
- **Couleur des lignes** (voir le tableau ci-dessous) : la première règle qui s'applique l'emporte.
- **Colonne GDR (rejets)** : « n pièces dans la GDR … = l'écart débit / le montant de la pièce / pièce − OA /
  pièce − interface » quand le montant rejeté explique l'écart ; « probable » quand le fichier et le folio sont
  dans la GDR sans que le montant tombe juste.
- **Afficher aussi les lignes disparues** : lignes absentes du dernier export couvrant leur date (en gris italique).

### 4. Expliquer et rapprocher

1. **Cocher des lignes** dans le tableau : un panneau en bas à droite cumule les écarts **débit**, **crédit** et
   **nombre de pièces** de la sélection.
2. Quand les trois sont à zéro (au moins deux lignes), **🔗 Rapprocher ces lignes**, avec un commentaire
   facultatif. Les lignes rapprochées sont masquées par défaut.
3. Pour les lignes cochées qui ont des pièces rejetées, le dépliant **🧾 Pièces rejetées dans la GDR** en donne
   le détail (numéro, code et libellé de rejet, montant, depuis quand).
4. **Groupes compensés en attente** : couples folio + fichier dont les écarts se compensent déjà ; **Rapprocher**
   à l'unité ou **🔗 Tout rapprocher**. **Folios compensés en attente** : même chose tous fichiers confondus.
5. **Historique des rapprochements** : chaque rapprochement est daté ; **Annuler** le défait.

### 5. Diffuser

**📄 Générer le rapport HTML** puis **⬇ Télécharger** : fichier `Ctrl_Flux_AAAAMMJJ_HHMM.html` dans le dossier
des rapports, mêmes colonnes et mêmes couleurs que l'écran.

## Historique

Toutes les lignes jamais chargées, une par clé **folio + date + nom du fichier transmis**, dans leur dernière
version connue. Rien n'y est jamais supprimé.

- Une ligne connue prend les valeurs de l'export le **plus récent** ; recharger un vieux fichier ne change que
  les colonnes *Premier vu* et *Exports* (nombre d'exports où la ligne apparaît), jamais les montants.
- **📥 Reconstituer depuis le dossier ControleFolioRose** verse tous les `ExportCSV-*.csv` du dossier et de
  `sauvegarde` dans l'historique, sans toucher à la situation actuelle. Relancer ne double rien.
- **Filtres** : Folio, Type, recherche libre (fichier transmis, commentaire), **Seulement les écarts**,
  **Absentes du dernier export** (lignes qui ne figurent plus dans le fichier le plus récent).
- **⬇ Exporter la sélection (CSV)** ; le dépliant **Exports versés** liste chaque fichier ExportCSV avec sa
  période et sa date de versement.

## GDR

Les rejets de la GDR (gestion des rejets) : chaque jour, le mail « Etat de synthèse des rejets GL, AP et AR »
apporte trois exports `JJMMAAAA_Synthese_des_rejets_<AP|AR|GL>_au_JJ-MM-AAAA[_02].csv`, déposés dans le dossier
GDR (ci-dessus).

- **📥 Importer les nouveaux exports** lit les fichiers inconnus du dossier (Ctrl Flux le fait aussi à
  l'ouverture). Chaque export est une **photo** des rejets encore ouverts : une pièce absente de la photo la plus
  récente de son type est considérée **traitée**, avec sa date.
- **Tuiles** : pièces et lignes rejetées ouvertes, montant rejeté, lignes nouvelles et traitées de la dernière photo.
- **Filtres** : Type (AP / AR / GL), Code rejet, Folio, **Afficher les rejets traités**, recherche libre (fichier,
  n° de pièce, description).
- **Pièces rejetées** (une ligne par pièce, montant de la pièce) puis **Lignes rejetées** (détail comptable).
- **Par code rejet** et **Par folio** : où se concentrent les rejets. Dépliant **Imports GDR** : les fichiers lus.
- Les libellés avec des « ? » ou « � » viennent tels quels de l'export GDR : l'accent est perdu à la source.

## Carte des flux

Tous les flux qui entrent dans Oracle et en sortent, d'après le schéma « Flux pour FIN01 - ORACLE » (66 flux,
25 applications), avec l'état de chacun.

### 1. Alimenter le référentiel

- **🗺 Charger les flux du schéma FIN01** : ajoute les flux manquants sans toucher aux fiches déjà saisies.
- **🔍 Déclarer les fichiers inconnus** : une fiche par famille de fichiers transmis qu'aucun motif ne reconnaît.
  À faire **après** le chargement du schéma, sinon des fichiers intermédiaires prennent la place des vrais flux.
- **⬇ Exporter (CSV)** / **📥 Importer** : partager le référentiel (fiches, interlocuteurs, attributs) entre postes.

### 2. Lire le graphe

- **Oracle Finance au centre**, un nœud par application, à la couleur de son **domaine** (légende sous le graphe).
- **Une flèche par flux** : couleur = **état** (tableau ci-dessous), tirets longs = batch, points = fil de l'eau.
- **Survol** d'un nœud : par type de flux (FOURNISSEURS / CLIENTS / GL), fichiers, folios, pièces, montant amont,
  écart ; puis folios, motifs et dernier fichier transmis. **Survol** d'une flèche : même détail pour ce flux.
- Les nœuds se **déplacent** à la souris, la **molette** zoome. **Séparer fournisseurs / clients / GL** éclate
  chaque application par type ; **Objets sur les flèches** écrit l'objet du flux le long de sa flèche.
- **Filtres** Sens, Domaine, Nature, État ; tuiles et jauge *Santé des flux suivis*.

### 3. Météo et fiche d'un flux

- **Météo des flux** : une ligne par flux, avec son état, sa volumétrie Ctrl Flux et son motif.
- **Fiche d'un flux** (choisir le flux sous la météo) : corriger les colonnes du schéma et saisir le **motif du
  nom de fichier** — joker `*` et `?`, ou expression régulière si le motif commence par `^` ; le nombre de
  fichiers connus qu'il reconnaît s'affiche aussitôt. **💾 Enregistrer la fiche**, ou **🗑 Supprimer ce flux**.
- **Interlocuteurs** (nom, rôle amont / EAI / métier / Oracle, mail, téléphone) et **Attributs libres**
  (clé / valeur : criticité, heure attendue, ticket, procédure…) : chacun avec son bouton **💾 Enregistrer**.
- **Source de l'état** : `ctrl_flux` (lignes Ctrl Flux reconnues par le motif), `virements`, `prelevements`,
  `releves` (derniers contrôles de l'onglet Banque), vide (sans donnée).
