# Prompt Gemini — Dashboard « Contrôle EBS »

> Copier tout ce qui suit la ligne `---` dans Gemini. Joindre si possible `Code.gs`, `Config.gs`,
> `Index.html` et le dossier `tests/Dashboard_CSV/` (jeu de données d'exemple).

---

## Rôle

Tu es un développeur senior Google Apps Script / front-end, spécialiste des dashboards de supervision
d'exploitation. Tu écris du code de production, lisible, commenté en français, sans dépendance inutile.

## Objectif

Générer une **application web Google Apps Script** (« Contrôle EBS – Dashboard ») qui affiche, sur une seule
page, l'état quotidien des traitements d'un ERP **Oracle E-Business Suite** (finance) : flux fournisseurs,
factures, écritures comptables, traitements de nuit, rapprochement bancaire, factures dématérialisées.

Public : 2 à 5 personnes de l'équipe d'exploitation finance, qui ouvrent la page le matin (et en cours de
journée) pour répondre en 10 secondes à la question : **« Est-ce que tout s'est bien passé, et sinon, quoi
traiter en premier ? »**

## Architecture existante (à respecter)

```
Oracle EBS ──(tâche planifiée horaire : export_csv.py)──> CSV locaux
          ──(Google Drive pour ordinateur)──> dossier Google Drive
          ──(Apps Script DriveApp, lecture seule)──> application web (HtmlService)
```

- Une requête SQL = un fichier CSV (`00_kpi.csv`, `01_dsp_flux.csv` … `20_demat_en_attente.csv`).
- Les CSV sont **réécrits toutes les heures**. Si une requête échoue, **l'ancien CSV est conservé** :
  sa date de dernière modification Drive (`file.getLastUpdated()`) est donc l'unique indicateur de fraîcheur.
- Aucun accès direct à Oracle depuis Apps Script. Aucune écriture : scope OAuth unique
  `https://www.googleapis.com/auth/drive.readonly`.

### Contraintes techniques

| Sujet | Contrainte |
|---|---|
| Runtime | Apps Script **V8**, fuseau `Europe/Paris` |
| Fichiers livrés | `Code.gs`, `Config.gs`, `Index.html` (un seul HTML : CSS + JS inline), `appsscript.json` |
| Déploiement | `clasp push` ; `.claspignore` n'envoie que `*.gs`, `*.html`, `appsscript.json` |
| Accès | `executeAs: USER_DEPLOYING`, `access: MYSELF` (passable à `DOMAIN`) |
| Librairies front | **Aucune** (pas de Chart.js, D3, Bootstrap, framework). Graphiques en **SVG inline** et barres en CSS. Polices système. |
| Communication | La page appelle `google.script.run.withSuccessHandler(...).getDashboardData()` une fois, puis toutes les `REFRESH_MINUTES` |
| Parsing CSV | Côté serveur avec `Utilities.parseCsv`, retirer le BOM UTF-8, `trim()` des cellules, ignorer les lignes entièrement vides (SPOOL SQL*Plus en ajoute en tête/fin) |
| Sécurité | Échapper **toute** valeur issue des CSV avant injection HTML (fonction `esc`) — les messages d'erreur Oracle contiennent `<`, `>`, `&`, `"` |
| Robustesse | Un CSV absent, vide, ou mal formé ne doit **jamais** casser la page : la section concernée affiche un état d'erreur, les autres s'affichent normalement. Chaque panneau graphique est rendu dans un `try/catch`. |

## Configuration (`Config.gs`) — tout le paramétrage est ici, rien en dur ailleurs

```js
const DASHBOARD_CONFIG = Object.freeze({
  FOLDER_ID: '<id du dossier Drive>',
  STALE_HOURS: 3,          // au-delà : CSV « périmé »
  REFRESH_MINUTES: 15,     // rechargement automatique des données
  TITLE: 'Controle EBS - Dashboard',
});
const DASHBOARD_KPI_FILE = '00_kpi.csv';

// Tuile KPI cliquée -> sections de détail mises en avant
const DASHBOARD_KPI_LINKS = Object.freeze({
  'Flux DSP': ['01_dsp_flux.csv', '02_dsp_synthese.csv'],
  'Notes de frais': ['03_ndf_notilus.csv'],
  'Factures Xerox': ['04_factures_source.csv', '05_xerox_sans_image.csv', '06_xerox_avec_image.csv'],
  'Factures Tradeshift': ['04_factures_source.csv'],
  'Factures DSP': ['04_factures_source.csv', '02_dsp_synthese.csv'],
  'GL interface': ['09_gl_interface.csv'],
  'Lignes GL creees': ['10_gl_lignes.csv'],
  'Imports RB': ['17_rb_imports.csv'],
  'Traitements nuit': ['11_nuit_synthese.csv', '15_nuit_longs.csv', '16_nuit_en_cours.csv'],
  'Erreurs nuit': ['12_nuit_erreurs_programme.csv', '13_nuit_erreurs_detail.csv'],
  'Avertissements nuit': ['14_nuit_warnings.csv'],
  'Images Xerox manquantes': ['05_xerox_sans_image.csv'],
  'Factures demat en attente': ['18_demat_statut.csv', '19_demat_par_jour.csv', '20_demat_en_attente.csv'],
});

// Sections, dans l'ordre d'affichage. alertIfRows = la section ne devrait contenir AUCUNE ligne.
const DASHBOARD_SECTIONS = Object.freeze([
  {file: '01_dsp_flux.csv',              title: 'DSP - Detail des flux',                 group: 'DSP'},
  {file: '02_dsp_synthese.csv',          title: 'DSP - Synthese par jour et type',       group: 'DSP'},
  {file: '03_ndf_notilus.csv',           title: 'Notilus - Notes de frais',              group: 'Factures'},
  {file: '04_factures_source.csv',       title: 'Factures - Synthese par source',        group: 'Factures'},
  {file: '05_xerox_sans_image.csv',      title: 'Xerox - Factures SANS image',           group: 'Factures', alertIfRows: true},
  {file: '06_xerox_avec_image.csv',      title: 'Xerox - Factures AVEC image',           group: 'Factures'},
  {file: '07_fac_ar_recues.csv',         title: 'Factures AR - Recues (24 h)',           group: 'Factures'},
  {file: '08_fac_ar_rejets.csv',         title: 'Factures AR - Rejets AutoInvoice',      group: 'Factures', alertIfRows: true},
  {file: '09_gl_interface.csv',          title: 'GL - Interface (en attente)',           group: 'GL'},
  {file: '10_gl_lignes.csv',             title: 'GL - Lignes creees',                    group: 'GL'},
  {file: '11_nuit_synthese.csv',         title: 'Nuit - Synthese par statut',            group: 'Nuit'},
  {file: '12_nuit_erreurs_programme.csv',title: 'Nuit - Erreurs par programme',          group: 'Nuit', alertIfRows: true},
  {file: '13_nuit_erreurs_detail.csv',   title: 'Nuit - Detail des erreurs',             group: 'Nuit', alertIfRows: true},
  {file: '14_nuit_warnings.csv',         title: 'Nuit - Warnings',                       group: 'Nuit'},
  {file: '15_nuit_longs.csv',            title: 'Nuit - Traitements > 30 min',           group: 'Nuit'},
  {file: '16_nuit_en_cours.csv',         title: 'Nuit - Traitements en cours',           group: 'Nuit'},
  {file: '17_rb_imports.csv',            title: 'Rapprochement bancaire - Imports',      group: 'RB'},
  {file: '18_demat_statut.csv',          title: 'Factures demat - Stock par statut',     group: 'Demat'},
  {file: '19_demat_par_jour.csv',        title: 'Factures demat - Arrivees par jour',    group: 'Demat'},
  {file: '20_demat_en_attente.csv',      title: 'Factures demat - En attente (INSERE)',  group: 'Demat', alertIfRows: true},
]);

const DASHBOARD_DEMAT = Object.freeze({
  KPI: 'Factures demat en attente',
  STATUT_FILE: '18_demat_statut.csv',
  JOUR_FILE: '19_demat_par_jour.csv',
  STATUTS: [   // ordre fixe = ordre des couleurs
    {code: 'INSERE', label: 'En attente'},
    {code: 'INTEGREE', label: 'Integree'},
    {code: 'COMPLETED', label: 'Terminee'},
    {code: 'AUTRE', label: 'Autre'},
  ],
});
```

Ajouter une section = ajouter un fichier SQL + une ligne dans `DASHBOARD_SECTIONS`. Le code ne doit
contenir **aucune** liste de fichiers en dur en dehors de `Config.gs`.

## Contrat de données (en-têtes réels des CSV)

Formats : dates `JJ/MM/AA` (ex. `24/09/26`) ou `JJ/MM HH:MI[:SS]` (ex. `24/09 03:02:54`) ;
jours en majuscules sans accent (`JEUDI`) ; nombres avec **point** décimal ; valeurs vides possibles.
Les données couvrent en général les 3 derniers jours (J-2 à J).

| Fichier | Colonnes | Volume type |
|---|---|---|
| `00_kpi.csv` | `ORDRE, KPI, VALEUR, STATUT` (STATUT ∈ `OK`, `W`, `KO`) | 13 lignes |
| `01_dsp_flux.csv` | `SRC, DATE_CR, JOUR, TYPE_FLUX, FILE_NAME` (TYPE_FLUX ∈ FOURNISSEUR, COMMANDE, RECEPTION, DEBLOCAGE, AUTRE ; l'heure d'arrivée est dans FILE_NAME : `..._AAAAMMJJHHMISS_...`) | ~15 |
| `02_dsp_synthese.csv` | `DATE_CR, JOUR, NB_SUP, NB_CDE, NB_REC, NB_DEB, NB_AUT, TOTAL` (5 fichiers attendus/jour) | 3 |
| `03_ndf_notilus.csv` | `CONTROLE, DATE_CR, JOUR, NB_NDF, MONTANT_TOT` | 3 |
| `04_factures_source.csv` | `CONTROLE, DATE_CR, SOURCE, NB_FACS` (SOURCE ∈ XEROX, TRADESHIFT, DSP) | ~7 |
| `05_xerox_sans_image.csv` | `RECUE_LE, NUM_FACT, FOURNISSEUR, DATE_FACT, MONTANT, DEV, IMAGE_ATTENDUE, FICHIER_XEROX, AGE_J, INVOICE_IDS` | 0–20 |
| `06_xerox_avec_image.csv` | `NB_AVEC_IMG` | 1 |
| `07_fac_ar_recues.csv` | `ORIGINE, STATUT_OA, NB_FACTURES, NB_LIGNES, MONTANT, PREMIERE, DERNIERE, LIGNES_ENCORE_EN_INTERFACE` (STATUT_OA : A = acceptée, R = rejetée) | ~10 |
| `08_fac_ar_rejets.csv` | `FACTURE, SOURCE, CONTEXTE, EN_INTERFACE_DEPUIS, NB_LIGNES, MONTANT, ERREUR` | 0 normalement |
| `09_gl_interface.csv` | `CONTROLE, SOURCE, TYPE_GL, STATUS_GL, NB_LIGNES, TOT_DEBIT, TOT_CREDIT, PLUS_ANCIEN, AGE_J` | 0–10 |
| `10_gl_lignes.csv` | `CONTROLE, DATE_CR, SOURCE, NB_LIGNES, TOT_DEBIT` (SOURCE vide = ligne de total du jour) | ~45 |
| `11_nuit_synthese.csv` | `CONTROLE, STATUT, NB` (STATUT ∈ OK, WARNING, ERROR) | 2–3 |
| `12_nuit_erreurs_programme.csv` | `PROGRAMME, NB_ERR, PREMIERE, DERNIERE, MSG` | 0 normalement |
| `13_nuit_erreurs_detail.csv` | `REQ_ID, PROGRAMME, DEBUT, FIN, DUREE_MIN, MSG` | 0 normalement |
| `14_nuit_warnings.csv` | `REQ_ID, PROGRAMME, DEBUT, DUREE_MIN, MSG` | ~50 |
| `15_nuit_longs.csv` | `REQ_ID, PROGRAMME, DEBUT, FIN, DUREE_MIN, STATUT` | ~90 |
| `16_nuit_en_cours.csv` | `REQ_ID, PROGRAMME, DEBUT, DUREE_MIN, PARAMETRES` | 0–10 |
| `17_rb_imports.csv` | `CONTROLE, DATE_CR, JOUR, NB_CTES` | 3 |
| `18_demat_statut.csv` | `STATUT, NB` | 2–4 |
| `19_demat_par_jour.csv` | `DATE_CR, JOUR, NB_INSERE, NB_INTEGREE, NB_COMPLETED, NB_ERROR, TOTAL` | ~10 |
| `20_demat_en_attente.csv` | **~250 colonnes** au format UBL/EN16931 (factures électroniques). Colonnes utiles : `ID` (n° facture), `ISSUEDATE`, `DUEDATE`, `ASP_P_PARTYNAME_NAME` (fournisseur), `ACP_P_PLE_REGISTNAME` (entité acheteuse), `ORDERREF_ID` (n° de commande), `LEGALMONTOT_PAYABLEAMNT` (montant TTC), `DOCCURRENCYCODE`, `STATUS`, `CREATION_DATE`, `NOM_FICHIER_XML` | ~150 |

### Règles des statuts KPI (calculées en SQL, fournies pour les libellés et infobulles)

| KPI | OK si | Sinon |
|---|---|---|
| Flux DSP | ≥ 5 fichiers | W |
| Notes de frais, Factures Xerox, Factures Tradeshift, GL interface, Lignes GL créées, Imports RB | > 0 | W |
| Factures DSP | = 0 et flux DSP ≥ 5 | W |
| Erreurs nuit | = 0 | KO |
| Avertissements nuit | = 0 | W |
| Images Xerox manquantes | = 0 | KO |
| Factures demat en attente | = 0 | W |

Le front **n'invente pas** de statut : il affiche celui de `00_kpi.csv`.

## Backend (`Code.gs`)

1. `doGet()` : `HtmlService.createTemplateFromFile('Index')`, injecte la config
   (`DASHBOARD_CONFIG` + `KPI_LINKS` + `DEMAT`) dans le template, `setTitle`, meta `viewport`.
2. `getDashboardData()` renvoie :
   ```js
   { generatedAt: ISOString,
     kpi:      {header, rows, updated} | {missing: true, header: [], rows: []},
     sections: [{file, title, group, alertIfRows, header, rows, updated, missing?}, ...] }
   ```
3. Fonctions privées suffixées `_` : `dashboardReadCsv_(folder, fileName)`, `dashboardParseCsv_(text)`.
4. Pour `20_demat_en_attente.csv`, **réduire côté serveur** aux colonnes utiles listées plus haut
   (liste configurable dans `Config.gs`) pour ne pas envoyer 250 colonnes au navigateur.
5. Si une ligne a un nombre de cellules différent de l'en-tête, la conserver mais la signaler
   (compteur `badRows` par section, affiché discrètement).

## Frontend (`Index.html`) — structure de la page

### 1. En-tête (sticky)
Titre, heure du dernier chargement, prochain rafraîchissement (compte à rebours), bouton « Actualiser »,
bascule clair/sombre (par défaut : `prefers-color-scheme`, choix mémorisé en `localStorage` dans un `try/catch`).
Bandeau rouge si `getDashboardData` échoue (message + bouton « Réessayer »), en conservant les dernières données affichées.

### 2. Bandeau « À traiter » (priorité absolue)
Liste compacte, triée KO puis W, de tout ce qui demande une action :
KPI en KO/W, sections `alertIfRows` non vides, CSV absents, CSV périmés.
Chaque entrée est un lien qui fait défiler et ouvre la section concernée. Si rien : message
« ✓ Tout est nominal » en vert.

### 3. Tuiles KPI (grille responsive, 13 tuiles, ordre = colonne ORDRE)
Valeur (formatée `fr-FR`, séparateur de milliers), libellé, badge `OK`/`W`/`KO`, bordure colorée
selon le statut, infobulle avec la règle du tableau ci-dessus. La tuile « Factures demat en attente »
porte un mini-donut des statuts demat.
**Clic sur une tuile** = filtre : seules les sections de `DASHBOARD_KPI_LINKS[kpi]` restent visibles
(`aria-pressed`, second clic = retire le filtre).

### 4. Filtres par domaine
Boutons-puces : Tous · DSP · Factures · GL · Nuit · RB · Demat (générés depuis `group`), avec le nombre
d'alertes par domaine.

### 5. Panneaux graphiques (un par domaine, au-dessus des tableaux du domaine)

- **DSP** : nuage de points SVG « heure d'arrivée des fichiers » (axe X 0–24 h, une ligne par jour,
  couleur par TYPE_FLUX, légende) + histogramme fichiers/jour avec la cible 5 (barre orange si < 5).
  Badge « n / 5 attendus » pour le dernier jour.
- **Factures** : mini-histogrammes par source (XEROX, TRADESHIFT, DSP) sur 3 jours ; histogramme
  Notilus (nombre de NDF, montant en infobulle) ; barres horizontales empilées acceptées/rejetées
  par ORIGINE AR ; « bande d'âge » des factures Xerox sans image (points colorés : ≤ 2 j bleu,
  3–7 j orange, > 7 j rouge). Si aucune facture sans image : « ✓ Toutes les factures Xerox ont leur image ».
- **GL** : lignes créées par jour (ligne SOURCE vide = total) ; top 6 des sources du dernier jour ;
  stock de l'interface GL (ou « ✓ Interface GL vide »).
- **Nuit** : donut OK / WARNING / ERROR ; frise « Gantt » SVG des traitements > 30 min (DEBUT→FIN,
  couleur selon STATUT) ; liste des traitements en cours avec leur durée, en rouge au-delà de 120 min.
- **RB** : histogramme des comptes importés par jour.
- **Demat** : grand donut du stock par statut (ordre et libellés de `DASHBOARD_DEMAT.STATUTS`,
  total au centre, légende interactive : survol d'un statut = mise en valeur du segment) ;
  barres empilées « arrivées par jour » ; tableau des factures en attente trié par ancienneté
  (`CREATION_DATE`), avec montant formaté en euros.

### 6. Sections de détail (tableaux)
`<details>` repliables, fermés par défaut sauf si la section est en alerte. Dans le `<summary>` :
titre, nombre de lignes, badge « à traiter » si `alertIfRows` et lignes > 0, heure de mise à jour
du CSV, badge « périmé » si plus vieux que `STALE_HOURS`, badge « CSV absent » si `missing`.
Tableau : en-tête collant, colonnes numériques alignées à droite, tri au clic sur l'en-tête
(numérique / date / texte), champ de recherche plein texte par tableau, défilement horizontal
dans son conteneur (jamais sur la page), colonne `MSG`/`ERREUR` tronquée avec texte complet en infobulle,
bouton « Copier » (TSV dans le presse-papiers, pour coller dans Excel).
Section vide : « Aucune ligne. » (en vert si `alertIfRows`).

## Design

- Sobre, dense, orienté lecture rapide (esprit Grafana / Linear), pas de décoration gratuite.
- Couleurs en variables CSS sur `:root`, redéfinies pour le thème sombre :
  `--ok` vert, `--w` orange, `--ko` rouge, `--bg`, `--card`, `--text`, `--muted`, `--line`,
  palette catégorielle `--c1..--c6`, couleurs demat `--s-INSERE`, `--s-INTEGREE`, `--s-COMPLETED`, `--s-AUTRE`.
- Le statut ne doit jamais être porté **uniquement** par la couleur (toujours le texte OK/W/KO ou une icône).
- Responsive : 1 colonne sur mobile (≥ 360 px, marge 16 px, aucun défilement horizontal de page),
  2 colonnes tablette, grille complète sur écran large.
- Animations discrètes à l'apparition (barres qui poussent, points qui apparaissent) désactivées
  sous `prefers-reduced-motion`.
- Accessibilité : contraste AA, focus visible, tuiles et légendes utilisables au clavier,
  `aria-label` sur les graphiques SVG + `<title>` sur chaque point/segment.

## Qualité du code

- JS moderne (const/let, fonctions fléchées, template literals) mais **sans build** ni module.
- Petites fonctions pures : `esc`, `num`, `fmtN`, `fmtTime`, `parseDateFr`, `isNum`, `colIndex(section, name)`
  (accès aux colonnes **par nom**, jamais par position) ; un rendu par zone : `renderHeader`, `renderTodo`,
  `renderKpis`, `renderFilters`, `renderPanels`, `renderSections`.
- Un objet `PANELS = {DSP: dspPanel, Factures: facturesPanel, ...}` : ajouter un domaine = ajouter une fonction.
- État UI (filtre actif, KPI sélectionné, sections ouvertes, tri) conservé lors du rafraîchissement automatique.
- Commentaires en français, concis. Pas de `console.log` laissé.

## Tests locaux (Node, sans Google)

Fournir `tests/run_local_tests.js` qui :
1. charge `Config.gs` et `Code.gs` dans un `vm` avec des bouchons `DriveApp`, `Utilities.parseCsv`
   (implémentation CSV RFC 4180 simple), `HtmlService` ;
2. lit les CSV de `tests/Dashboard_CSV/` ;
3. vérifie : chaque fichier de `DASHBOARD_SECTIONS` a son `sql/NN_xxx.sql` et inversement ;
   `getDashboardData()` renvoie toutes les sections ; un fichier manquant donne `missing: true` ;
   un BOM et des lignes vides sont retirés ; les colonnes de `20_demat_en_attente.csv` sont réduites.

Et `tests/preview.js` qui génère `tests/preview.html` (page rendue avec les CSV d'exemple, `google.script.run`
simulé) pour prévisualiser dans un navigateur sans déployer.

## Livrables attendus

Réponds **uniquement** avec le contenu complet de chaque fichier, dans cet ordre, chacun dans son bloc
de code précédé de son nom : `appsscript.json`, `Config.gs`, `Code.gs`, `Index.html`,
`tests/run_local_tests.js`, `tests/preview.js`. Puis une courte section « Hypothèses » listant ce que
tu as dû supposer. Pas de code tronqué, pas de « ... reste inchangé ».

## Critères d'acceptation

- [ ] Avec le jeu `tests/Dashboard_CSV/`, la page affiche les 13 tuiles, le bandeau « À traiter » contient
      « Images Xerox manquantes (9) – KO », « Avertissements nuit (52) – W », « GL interface – W ».
- [ ] Supprimer un CSV → badge « CSV absent », le reste de la page fonctionne.
- [ ] Un CSV daté de plus de 3 h → badge « périmé » + entrée dans « À traiter ».
- [ ] Un message contenant `<script>` s'affiche en texte, sans exécution.
- [ ] Clic sur la tuile « Erreurs nuit » → seules les sections 12 et 13 sont visibles.
- [ ] Rafraîchissement auto toutes les 15 min sans perdre filtres ni tris.
- [ ] Lisible sur un téléphone de 360 px de large, en thème clair et sombre.
- [ ] `node tests/run_local_tests.js` passe.
