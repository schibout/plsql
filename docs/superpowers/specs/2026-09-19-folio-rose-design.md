# ODAT Watch — onglet « 🌹 Folio Rose »

> Note (22/09/2026) : la fonction décrite ici s'appelle désormais **Ctrl Flux** dans ODAT Watch (modules `ctrl_flux.py`, `ui_ctrl_flux.py`, `rapport_ctrl_flux.py`). Le texte ci-dessous garde le nom d'origine « Folio Rose », tel qu'il était au moment de la conception.

Date : 19/09/2026. Validé avec l'utilisateur.

## Objectif

Remplacer `ControleFolioRose/Verifier_Factures.ps1` (+ `Rapport_Html.ps1`) par un onglet d'ODAT Watch :
importer un export Folio Rose (`ExportCSV-JJ-MM-AAAA.csv`, glisser-déposer), contrôler les montants dans
Oracle (OK/KO), et surtout **rapprocher** des lignes : sélectionner des lignes, voir la somme des
« Écarts Débit » se recalculer, et enregistrer l'ensemble comme rapprochement quand la somme est 0.
Les données sont conservées (exports, lignes, résultats Oracle, rapprochements).

Décisions :
- Clé de groupe pour la détection automatique : **folio + fichier de base** (nom sans suffixe `_ST_…_001`).
- Un rapprochement est **enregistré** ; les lignes rapprochées sont reconnues dans les exports suivants.
- Contrôle Oracle en V1, fidèle au `.ps1` (3 requêtes CLIENTS / FOURNISSEURS / GL).
- Hors périmètre : cascade `reconciliation.py`, envoi mail, écriture dans Oracle, zips.

## Lecture d'un export (règles du `.ps1`, à reproduire)

- Encodage : BOM UTF-8 → utf-8-sig ; sinon octets 0x80–0x9F plus nombreux que ≥ 0xC0 → cp850 ; sinon cp1252.
- Les 2 premières lignes sont sautées si la première commence par `Folio;Ecart` (ou `,`/tab) ; la période
  (`Début de période`, `Fin de période`) est lue sur la 2e ligne.
- Séparateur : tab si présent dans l'en-tête, sinon `,` si pas de `;`, sinon `;`.
- En-têtes normalisés : accents retirés, minuscules, espaces réduits ; correspondance exacte, puis
  normalisée, puis sans espaces (`App Amont Nb piéce` = `app amont nb piece`).
- Montants : espaces (y compris insécables) retirés, virgule → point, vide ou `-` → 0 ; illisible → 0 + compteur.
- Ligne entièrement vide ignorée ; toute autre ligne est conservée. Sans folio ou sans nom de fichier
  (colonnes décalées par un `;` dans le commentaire) → type AUTRE.
- Type : nom de fichier contient `CLIENTS` → CLIENTS ; `FOURNISSEURS` → FOURNISSEURS ; `GL`, `GRAND LIVRE`
  ou `CDPG` → GL ; sinon AUTRE. `fichier_base` = partie avant `_ST_` (ou nom complet).
- `age_j` = date de l'export (nom du fichier `ExportCSV-JJ-MM-AAAA`, sinon date d'import) − `Date` de la ligne.
- **Empreinte** d'une ligne (identité stable entre exports) : sha1 de
  `folio | date | nom fichier transmis | app amont débit | si finance débit` (montants normalisés à 2 décimales).

## Données (SQLite `odat.db`, préfixe `fr_`)

```sql
fr_exports(id, nom_fichier, file_hash UNIQUE, date_export TEXT, periode_debut TEXT, periode_fin TEXT,
           importe_le TEXT, nb_lignes INT, encodage TEXT, nb_montants_illisibles INT)
fr_lignes(id, export_id → fr_exports, num INT, empreinte TEXT, folio, date TEXT, type TEXT, fichier TEXT,
          fichier_base TEXT, amont_nb REAL, amont_debit REAL, amont_credit REAL, si_nb REAL, si_debit REAL,
          si_credit REAL, ecart_nb REAL, ecart_debit REAL, ecart_credit REAL, commentaire TEXT,
          piece_jointe TEXT, lettrage TEXT, age_j INT)         -- index (export_id), (empreinte)
fr_oracle(export_id, folio, fichier_base, type, nb_oracle REAL, montant_oracle REAL, nb_interface REAL,
          montant_interface REAL, erreur TEXT, controle_le TEXT, PRIMARY KEY(export_id, folio, fichier_base, type))
fr_rapprochements(id, cree_le TEXT, commentaire TEXT, somme_ecart REAL, nb_lignes INT, annule_le TEXT)
fr_rapprochement_lignes(rapprochement_id → fr_rapprochements, empreinte TEXT, PRIMARY KEY(rapprochement_id, empreinte))
```

Une empreinte est « rapprochée » si elle appartient à un rapprochement non annulé.

## Moteur `folio_rose.py`

- `lire_export(chemin_ou_bytes, nom) -> Export` (dataclass : nom, date_export, periode, encodage, lignes: DataFrame
  aux colonnes de `fr_lignes`, nb_montants_illisibles). Lecture pure, sans base.
- `importer(export, con) -> int | None` : `None` si hash déjà présent, sinon id.
- `lignes_export(export_id, con) -> DataFrame` : lignes + colonnes Oracle (jointure sur folio/fichier_base/type)
  + `rapproche` (bool) + `statut` :
  `NON CONTROLE` (type AUTRE), `INDETERMINE` (contrôle lancé mais erreur/absence de réponse), `OK` si
  `amont_nb − nb_oracle == 0` et `|amont_debit − montant_oracle| < 0,005`, sinon `KO` ; vide (`—`) si le
  contrôle Oracle n'a pas encore été lancé pour cet export.
- `groupes_compenses(lignes) -> DataFrame` : par (folio, fichier_base), parmi les lignes **non rapprochées**,
  nb ≥ 2 et |somme ecart_debit| < 0,005 → colonnes folio, fichier_base, nb, somme, empreintes.
- `rapprocher(empreintes, commentaire, con) -> id` : refuse (ValueError) si |somme| ≥ 0,005, si < 2 lignes, ou si
  une empreinte est déjà rapprochée. `annuler_rapprochement(id, con)`. `rapprochements(con) -> DataFrame`.
- `controler_oracle(export_id, con) -> str` : couples distincts (folio, fichier_base, type ≠ AUTRE), une connexion
  (`oracle_refresh._connect_oracle`), requêtes du `.ps1` avec binds `:folio`, `:base` (+ `{s}` schéma), un
  `try/except` par couple (erreur → `fr_oracle.erreur`), upsert, résumé texte.

Requêtes (préfixe `{s}` = schéma configuré, ex. `APPS.`) :

- CLIENTS : `RA_CUSTOMER_TRX_ALL` × `RA_CUSTOMER_TRX_LINES_ALL` (`rctl.attribute10 LIKE :base||'%'`,
  `rctl.attribute9 = :folio`) → COUNT(DISTINCT customer_trx_id), SUM(extended_amount) ; interface
  `DKA_IARPAFAC_INTERFACE` (`FIC_IDENT LIKE :base||'%'`, `LOCAL_ACCOUNT LIKE '411%'`, `OA_status != 'A'`,
  `FMT_ORIGIN = :folio`) → COUNT(*), SUM(CASE TYPMVT='SI_AMT_FACTURE' THEN FMT_AMOUNT ELSE -FMT_AMOUNT).
- FOURNISSEURS : `AP_INVOICES_ALL` (`attribute10 LIKE`, `attribute9 =`) → COUNT(DISTINCT invoice_id),
  SUM(invoice_amount) ; interface `AP_INVOICES_INTERFACE` ⋈ `AP_INVOICE_LINES_INTERFACE`, hors rejets
  `AP_INTERFACE_REJECTIONS` → COUNT(DISTINCT invoice_id), SUM(amount).
- GL : `GL_JE_HEADERS` ⋈ `GL_JE_LINES` (`gjl.attribute10 LIKE`, `gjl.attribute9 =`) → COUNT(DISTINCT je_header_id),
  SUM(entered_dr) ; interface `GL_INTERFACE` → COUNT(*), SUM(entered_dr).

## Rapport `rapport_folio_rose.py`

Pur. `construire(export, lignes, groupes, rapprochements) -> str`, `ecrire(...) -> Path` dans `rapports/`
(`Folio_Rose_<date export>_<HHMM>.html`). Charte des deux autres rapports : bandeau (KO > 0 → ko ; sinon
INDÉTERMINÉ/groupes en attente → warn ; sinon ok), tuiles (lignes, folios, écart débit total, OK, KO,
rapprochées, groupes compensés en attente), synthèse par type et par folio (lignes, en écart, montant en
écart), détail des lignes (Folio, Type, Date, Âge, Fichier, Écart nb, Écart débit, Nb Oracle, Montant Oracle,
Montant Interface, Écart calculé, Commentaire, Statut, Rapproché), liste des rapprochements.

## Onglet `ui_folio_rose.py` (« 🌹 Folio Rose », après « ☀️ Matin »)

1. **Import** : `st.file_uploader` multi-fichiers `.csv` → `lire_export` + `importer` pour chacun, message
   « importé / déjà présent » ; bouton « Importer le dossier sauvegarde » (`ControleFolioRose/sauvegarde` et
   `ControleFolioRose/*.csv`) pour charger l'historique en une fois. Sélecteur de l'export courant
   (libellé : date export · période · n lignes), le plus récent par défaut.
2. **Tuiles** : lignes, folios, écart débit total, rapprochées, groupes compensés en attente, KO Oracle (ou « — »).
3. **Filtres** : type, statut, folio (multi), case « masquer les lignes rapprochées » (cochée).
4. **Tableau** `st.dataframe(..., on_select="rerun", selection_mode="multi-row")` : colonnes lisibles, montants
   formatés, styles : KO rouge pâle, rapprochée vert pâle. Sous le tableau, un bandeau **en direct** :
   « N ligne(s) sélectionnée(s) · somme des écarts débit = X € » ; si |X| < 0,005 et N ≥ 2 → `st.success`
   « ✔ compensé » + champ commentaire + bouton **Rapprocher** ; sinon `st.info` (bouton absent).
   Après rapprochement : `st.rerun`, sélection vidée.
5. **Propositions** : groupes compensés (folio, fichier, nb, somme) avec bouton « Rapprocher » par groupe et
   « Tout rapprocher » ; un clic sur un groupe peut aussi pré-sélectionner ses lignes (bouton « Voir »).
6. **Oracle** : bouton « 🅾 Contrôler dans Oracle » (désactivé sans `[database]`), résumé, colonnes dans le
   tableau ; erreurs de couple visibles en info-bulle/colonne.
7. **Rapport** : bouton « 📄 Générer le rapport HTML » + téléchargement.
8. **Historique des rapprochements** : tableau (date, nb lignes, somme, commentaire) + bouton « Annuler ».

## Erreurs

CSV illisible ou colonnes indispensables absentes (Folio, Nom fichier transmis, Ecarts Débit) → erreur explicite,
rien d'inséré. Oracle : même mécanique que Matin (`SystemExit` et exceptions affichées, rien d'écrasé).
Rapprochement refusé (somme ≠ 0, ligne déjà rapprochée) → message.

## Tests (pytest, sans Oracle)

- Lecture de tous les CSV de `ControleFolioRose/sauvegarde/` : aucune exception, nb de lignes = lignes de
  données, types ∈ {CLIENTS, FOURNISSEURS, GL, AUTRE}, colonnes attendues, période lue.
- Empreinte identique pour une même ligne dans deux exports successifs ; import dédoublonné par hash.
- `groupes_compenses` sur un DataFrame construit (cas 0, cas 3 lignes = 0, cas déjà rapprochées exclues).
- `rapprocher` / `annuler` / refus ; `lignes_export` calcule `statut` et `rapproche` ; `controler_oracle`
  simulé par un faux curseur (SQL formaté, binds, erreur d'un couple).
- Rapport : sections, échappement, bandeau.
- AppTest : import d'un CSV de `sauvegarde/`, sélection de lignes → somme affichée → rapprochement → ligne masquée.
