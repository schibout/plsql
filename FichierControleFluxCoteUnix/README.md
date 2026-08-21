# Contrôle du flux FAC02 — Factures clients

## 1. Fichiers du flux

Chaque flux dépose **deux fichiers** dans le répertoire `SOURCE/` :

| Fichier | Rôle |
|---|---|
| `FAC02_SRC_FACTURESCLIENTS_<AAMMJJ-HHMMSS>_ST_FAC02_<id>_<seq>.csv` | Fichier de **données** : écritures comptables des factures |
| `FAC02_CTL_FACTURESCLIENTS_<AAMMJJ-HHMMSS>_ST_FAC02_<id>_<seq>.csv` | Fichier de **contrôle** : totaux attendus par portefeuille |

Les deux fichiers d'un même flux partagent le même horodatage, le même identifiant et le même numéro de séquence — seul `SRC` / `CTL` diffère.

## 2. Structure du fichier CTL

Une ligne par portefeuille, séparateur `;` :

```
PORTEFEUILLE;DATE;NB_FACTURES;MONTANT;MONTANT;NOM_FICHIER_SRC;0
```

Exemple :
```
SVD;20/08/2026;342;79572,04;79572,04;FAC02_SRC_FACTURESCLIENTS_200826-...;0
```

| Colonne | Description |
|---|---|
| 1 | Code portefeuille (SVD, GCA, VTC, IGP, FAS, RNE, SVB…) |
| 2 | Date du flux (JJ/MM/AAAA) |
| 3 | Nombre de factures du portefeuille |
| 4 et 5 | Montant total du portefeuille (virgule décimale, peut être négatif en cas d'avoirs) |
| 6 | Nom du fichier SRC (sans extension) |
| 7 | Indicateur (0) |

## 3. Structure du fichier SRC

Écritures comptables, séparateur `;`, 35 champs. Champs utiles au contrôle (indexés à partir de 1) :

| Champ | Contenu | Exemple |
|---|---|---|
| 1 | Code société | `0688` |
| 3 | Numéro de facture | `GN1316005K` |
| 4 | Période comptable | `202608` |
| 7 | Compte comptable | `411150`, `707000`, `445710`… |
| 9 | Date de la pièce | `20260819` |
| 12 | Sens : `D` (débit) / `C` (crédit) | `D` |
| 13 | **Montant en centimes** (sans séparateur décimal) | `56299` = 562,99 |
| 14 | Signe du montant : `+` / `-` | `+` |
| 17 | Code portefeuille | `SVD` |

Chaque facture génère plusieurs lignes d'écriture équilibrées : une ligne **compte client `411*`** (le TTC de la facture, généralement en débit) et ses contreparties (produits `70*`, TVA `445*`, etc.).

## 4. Règle de rapprochement SRC ↔ CTL

Règle vérifiée à 100 % sur le fichier du 20/08/2026 (7 portefeuilles) :

- **NB_FACTURES** (CTL col 3) = nombre de lignes SRC dont le compte (champ 7) commence par `411`
- **MONTANT** (CTL col 4) = somme des montants de ces lignes `411*` :
  - montant = champ 13 / 100
  - signe `-` (champ 14) → montant négatif
  - sens `C` (champ 12) → montant négatif (avoirs)

Exemple : SVD → 342 lignes `411150`, somme = **79 572,04** = valeurs du CTL.
Un montant négatif dans le CTL (ex. SVB : −5 461,12) correspond à un portefeuille majoritairement en avoirs.

## 5. Script de contrôle `ctl_fac02.sh`

```sh
./ctl_fac02.sh <fichier_SRC> [fichier_CTL]
```

Si le fichier CTL est omis, il est déduit du nom du SRC (`_SRC_` → `_CTL_`).

Le script affiche :
1. **Synthèse par portefeuille** : nombre de factures et montant total (format français, virgule décimale)
2. **Rapprochement SRC ↔ CTL** : statut `OK` / `ECART` par portefeuille (nombre + montant, tolérance 0,005), et détection des portefeuilles présents dans un seul des deux fichiers
3. **Factures à montant 0** : toutes les lignes `411*` dont le montant est nul (portefeuille, n° facture, compte, date)

Codes retour (exploitables en ordonnanceur) :

| Code | Signification |
|---|---|
| 0 | Rapprochement OK |
| 1 | Écart(s) détecté(s) |
| 2 | Erreur d'usage (fichier manquant ou illisible) |

Exemple :
```sh
cd FichierControleFluxCoteUnix/FAC02factureClient
./ctl_fac02.sh SOURCE/FAC02_SRC_FACTURESCLIENTS_200826-004640_ST_FAC02_639227836001961326_001.csv
```

Portable AIX / Linux : `sh` POSIX + `awk` POSIX uniquement, aucune dépendance externe (`bc`, GNU awk…).

## 6. Version Windows : `ctl_fac02_client.bat` + `ctl_fac02.py`

Même contrôle, mêmes sorties et mêmes codes retour que le script Unix, en Python (bibliothèque standard uniquement) :

```bat
ctl_fac02_client.bat [dossier_source | fichier_SRC] [fichier_CTL]
```

- **Dossier en paramètre** : traite le fichier SRC le plus récent de ce dossier — `ctl_fac02_client.bat FAC02factureClient\SOURCE`
- **Fichier en paramètre** : traite ce fichier (CTL optionnel en 2e argument)
- **Sans argument** : cherche le dossier SOURCE aux emplacements connus (`SOURCE\`, `FAC02factureClient\SOURCE\`…) et prend le fichier SRC le plus récent

Le script Python peut aussi être lancé directement : `python ctl_fac02.py <fichier_SRC> [fichier_CTL]`.

### Rapport Excel

La version Python génère en plus un rapport **`rapport/FAC02_SYNTHESE_<horodatage>.xlsx`** (le dossier `rapport/` est créé automatiquement à côté du script) (nécessite `openpyxl` : `pip install openpyxl` ; sans lui le contrôle fonctionne, seul l'Excel est ignoré) :

- **Onglet « Synthese »** : en-tête (fichiers, résultat global), puis une ligne par portefeuille avec nb factures et montant SRC vs CTL, statut OK (vert) / ECART (rouge), et ligne TOTAL
- **Onglet « Factures a 0 »** : liste des factures à montant nul (portefeuille, n° facture, compte, date)

## 7. Flux FOURNISSEURS : `ctl_fac02_fournisseur.bat` + `ctl_fac02_fournisseur.py`

Même contrôle que le flux clients, adapté à la structure du fichier `FAC02_SRC_FACTURESFOURNISSEURS_...csv`, qui diffère :

- **1re ligne = en-tête** (ignorée)
- Montants **décimaux à virgule**, déjà signés (pas de centimes, pas de sens D/C)
- Champs utiles (indexés à partir de 1) : 3 = Compte Comptable Achat, 6 = **Code folio** (GAZ, BIO, HAC, ING…), 10 = Montant, 12 = Date de la pièce, 13 = Numéro de pièce

Règle de rapprochement (vérifiée à 100 % sur le fichier du 19/08/2026, 4 folios) : **NB_FACTURES** = nombre de lignes sur comptes fournisseurs `401*` par folio ; **MONTANT** = somme des montants de ces lignes. Le fichier CTL a le même format que celui des clients.

```bat
ctl_fac02_fournisseur.bat [dossier_source | fichier_SRC] [fichier_CTL]
```

Mêmes trois modes d'appel que `ctl_fac02_client.bat` (sans argument : cherche `FAC02FACTURESFOURNISSEURS\SOURCE\`), mêmes codes retour, mêmes sorties (synthèse par folio, rapprochement, factures à 0) et rapport Excel dans `rapport\FAC02_SYNTHESE_FOURNISSEURS_<horodatage>.xlsx`. Le script Python réutilise les fonctions communes de `ctl_fac02.py` (les deux fichiers doivent rester dans le même dossier).

## 8. Vérification dans Oracle EBS : un lanceur par flux

Contrôle complémentaire, sur le modèle de `ControleFolioRose` : vérifie si les factures du fichier SRC sont **intégrées dans Oracle** (tables définitives) ou **bloquées en open interface**. Un couple `.bat` + `.ps1` par flux :

```bat
Lancer_Verification_Oracle_Client.bat      [dossier_source | fichier_SRC]
Lancer_Verification_Oracle_Fournisseur.bat [dossier_source | fichier_SRC]
```

Dossier en paramètre : fichier SRC le plus récent de ce dossier. Fichier en paramètre : ce fichier (glisser-déposer possible). Sans argument : dossier SOURCE aux emplacements connus.

Fonctionnement (une seule session `sqlplus`, connexion partagée dans `config.ps1`) : agrégation du fichier SRC par portefeuille/folio (même règle que le contrôle CTL), puis pour chacun deux comptages Oracle avec la clé fichier = nom SRC tronqué avant `_ST_` (`attribute10 LIKE fichier%`, `attribute9 = portefeuille/folio`) :

| Flux | Définitif | Open interface |
|---|---|---|
| **Clients** (`Verifier_Oracle_FAC02_Client.ps1`) | `APPS.RA_CUSTOMER_TRX_ALL` / `RA_CUSTOMER_TRX_LINES_ALL` | `DKA_IARPAFAC_INTERFACE` (`FIC_IDENT LIKE fichier%`, `FMT_ORIGIN = portefeuille`, comptes `411%`, lignes non soldées `OA_status != 'A'`) |
| **Fournisseurs** (`Verifier_Oracle_FAC02_Fournisseur.ps1`) | `APPS.AP_INVOICES_ALL` | `APPS.AP_INVOICES_INTERFACE` + `AP_INVOICE_LINES_INTERFACE`, hors lignes rejetées (`AP_INTERFACE_REJECTIONS`) |

Statut par portefeuille/folio :

| Statut | Signification |
|---|---|
| `INTEGREE` | Nb et montant retrouvés dans les tables définitives |
| `EN INTERFACE` | Rien en définitif, montant retrouvé en open interface |
| `PARTIELLE` | Réparti entre définitif et interface (somme cohérente) |
| `ABSENTE` | Introuvable dans Oracle |
| `ECART` | Montants incohérents |

Sorties dans `Logs\` (clients : `Rapport_Oracle_FAC02_*`, fournisseurs : `Rapport_Oracle_FAC02_FOURNISSEURS_*`) :

- `..._<horodatage>.csv` : synthèse par portefeuille/folio ;
- `..._Detail_<horodatage>.csv` : détail facture par facture (pièce, date, montant fichier vs Oracle vs interface, statut) ;
- `..._<horodatage>.xlsx` : classeur Excel à 2 onglets — **Synthèse** et **Détail Factures** (nécessite Excel installé sur le poste ; via automatisation COM, sans dépendance supplémentaire. Sans Excel, seuls les CSV sont produits).

Codes retour : 0 = tout intégré, 1 = erreur technique (dont erreur Oracle : aucun rapport produit, pour ne pas présenter des zéros comme un résultat), 2 = anomalies (interface / absent / écart).

Options du script PowerShell : `-Diagnostic` (affiche le SQL généré et la sortie brute d'Oracle), `-GarderTempSQL` (conserve le script SQL dans `Logs\`).

> **Prérequis sur le poste d'exécution** (non disponibles sur ce poste de développement) : un client Oracle (`sqlplus`, `sqlcl` ou `sql`) dans le PATH, et `config.ps1` renseigné (ne pas committer ce fichier : il contient le mot de passe).
