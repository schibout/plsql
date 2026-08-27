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

## 6. Version Windows CLIENTS : `controleClient.bat` + `ctl_fac02.py`

Le rapprochement SRC/CTL reprend le même contrôle et les mêmes sorties que le script Unix, en Python :

```bat
controleClient.bat [dossier_export | fichier_SRC] [fichier_CTL]
```

- **Dossier d'export en paramètre** : descend récursivement jusqu'aux répertoires `SOURCE` et traite le fichier `*_SRC_FACTURESCLIENTS*.csv` le plus récent — par exemple `controleClient.bat 31072026_FAS`
- **Fichier en paramètre** : traite ce fichier s'il se trouve dans `SOURCE` (CTL optionnel en 2e argument)
- **Préfixe libre** : le nom peut commencer par `FAC02`, `CEL01`, `PRN01`, etc.
- **Sans argument** : cherche récursivement sous le dossier du lanceur

Le lanceur unique exécute successivement le rapprochement SRC/CTL avec `ctl_fac02.py`, puis la vérification de l'intégration dans Oracle avec `Verifier_Oracle_FAC02_Client.ps1`, sur le même fichier SRC. Le script Python peut aussi être lancé directement : `python ctl_fac02.py <fichier_SRC> [fichier_CTL]`.

Codes retour du lanceur Windows : `0` = contrôles OK, `1` = erreur technique, `2` = anomalie ou écart.

### Rapport Excel

La version Python génère en plus un rapport **`rapport/FAC02_SYNTHESE_<horodatage>.xlsx`** (le dossier `rapport/` est créé automatiquement à côté du script) (nécessite `openpyxl` : `pip install openpyxl` ; sans lui le contrôle fonctionne, seul l'Excel est ignoré) :

- **Onglet « Synthese »** : en-tête (fichiers, résultat global), puis une ligne par portefeuille avec nb factures et montant SRC vs CTL, statut OK (vert) / ECART (pêche), et ligne TOTAL
- **Onglet « Factures a 0 »** : liste des factures à montant nul (portefeuille, n° facture, compte, date)

Tous les rapports Excel clients, fournisseurs et GL utilisent la même charte : bandeau et en-têtes bleu foncé, lignes alternées bleu très clair, conformités vert pâle, anomalies pêche, montants avec séparateurs, filtres automatiques, volets figés, largeurs contrôlées et quadrillage masqué. Cette charte s'applique aux contrôles locaux comme aux rapports Oracle.

## 7. Flux FOURNISSEURS : `controleFournisseur.bat` + `ctl_fac02_fournisseur.py`

Même contrôle que le flux clients, adapté à la structure du fichier `*_SRC_FACTURESFOURNISSEURS_...csv`, qui diffère :

- **1re ligne = en-tête** (ignorée)
- Montants **décimaux à virgule**, déjà signés (pas de centimes, pas de sens D/C)
- Champs utiles (indexés à partir de 1) : 3 = Compte Comptable Achat, 6 = **Code folio** (GAZ, BIO, HAC, ING…), 10 = Montant, 12 = Date de la pièce, 13 = Numéro de pièce

Règle de rapprochement (vérifiée à 100 % sur le fichier du 19/08/2026, 4 folios) : **NB_FACTURES** = nombre de lignes sur comptes fournisseurs `401*` par folio ; **MONTANT** = somme des montants de ces lignes. Le fichier CTL a le même format que celui des clients.

```bat
controleFournisseur.bat [dossier_export | fichier_SRC] [fichier_CTL]
```

Ce lanceur unique exécute successivement le rapprochement SRC/CTL en Python, puis la vérification de l'intégration dans Oracle avec `Verifier_Oracle_FAC02_Fournisseur.ps1`, sur le même fichier SRC. Un dossier d'export complet tel que `10082026_FOURNISSEUR_CEG` peut être passé directement : le lanceur descend jusqu'à `SOURCE` et accepte tout préfixe (`FAC02`, `CEL01`, `PRN01`…). Le fichier CTL peut être fourni en second argument ; sinon son nom est déduit du SRC.

Le rapport de rapprochement est généré dans `rapport\FAC02_SYNTHESE_FOURNISSEURS_<horodatage>.xlsx`. Le script Python réutilise les fonctions communes de `ctl_fac02.py` (les deux fichiers doivent rester dans le même dossier). Codes retour du lanceur : `0` = contrôles OK, `1` = erreur technique, `2` = anomalie ou écart.

## 7bis. Flux ÉCRITURES GL : `controleGL.bat` + `ctl_ecritures_gl.py`

Le contrôle GL rapproche le fichier `*_SRC_ECRITURESGL*.csv` avec son CTL. Pour chaque origine de flux (colonne 12 du SRC), il vérifie :

- le nombre de numéros de pièce distincts (colonne 1) ;
- le total débit (colonne 9) ;
- le total crédit (colonne 10) ;
- l'équilibre débit/crédit de chaque pièce et de chaque origine.

```bat
controleGL.bat [dossier | fichier_SRC] [fichier_CTL]
```

Un dossier peut être glissé sur le lanceur : la recherche du SRC le plus récent est récursive et limitée aux répertoires nommés `SOURCE`, ce qui permet de passer directement un dossier d'export complet tel que `04072026_GL_GER`. Le préfixe du fichier est libre. Le CTL est déduit automatiquement du nom du SRC s'il n'est pas fourni. Le rapport local est généré dans `rapport\GL_SYNTHESE_<horodatage>.xlsx`.

Le lanceur exécute ensuite `Verifier_Oracle_Ecritures_GL.ps1` sur le même SRC. La requête reprend la convention de `ControleFolioRose` (`attribute9 = origine`, `attribute10 LIKE nom_fichier%`) et rapproche `GL_JE_HEADERS`/`GL_JE_LINES` avec `GL_INTERFACE`.

Le rapport Oracle coloré est créé dans `Logs\Rapport_Oracle_GL_<horodatage>.xlsx` avec deux onglets : **Synthese Oracle** et **Detail Pieces SRC**. Il reprend la palette du projet `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS` (en-têtes bleu foncé, conformités vert pâle, anomalies pêche), les filtres, les volets figés et les montants formatés. Si Excel n'est pas installé, deux CSV de secours sont produits.

Statuts Oracle : `INTEGREE`, `EN INTERFACE`, `PARTIELLE`, `ABSENTE` ou `ECART`. Codes retour du lanceur : `0` = contrôles local et Oracle conformes, `1` = erreur technique, `2` = écart, écriture déséquilibrée ou intégration Oracle incomplète. Le contrôle des transformations du fichier `FAC02_PIVOT_GL_*` reste hors périmètre.

## 7ter. Récupération des fichiers côté Unix : `copier_instances_local.sh`

Sur le serveur Unix, copie les **dossiers d'instances complets** d'un flux créés à une date donnée dans un dossier local `DDMMYYYY_<TYPE>_<CODE>` (ex. `10082026_FOURNISSEUR_CEG`). Chaque instance conserve ses sous-répertoires `SOURCE`, `TARGET` et `TALEND` :

```sh
./copier_instances_local.sh [TYPE] [CODE] [DD-MM-YYYY]
# sans argument : type FOURNISSEUR, code FAC02, date du jour
./copier_instances_local.sh FOURNISSEUR CEG 10-08-2026
./copier_instances_local.sh CLIENT FAS 31-07-2026
./copier_instances_local.sh GL GER 04-07-2026
```

Types connus : `FOURNISSEUR`, `CLIENT` et `GL`. Le code détermine le préfixe applicatif (`FAC02`, `CEL01`, `PRN01`, `HEF01`, `NOT01`, `VHC03`…), utilisé avec le suffixe correspondant au type de flux.

Le dossier d'export obtenu se glisse tel quel sur le `.bat` correspondant (`controleClient.bat`, `controleFournisseur.bat` ou `controleGL.bat`) : le lanceur descend dans les répertoires `SOURCE`, sélectionne le SRC le plus récent et ignore les fichiers de `TARGET`.

## 7quater. Réconciliation source → Oracle : `reconciliation.py`

Les contrôles précédents rapprochent le SRC de son CTL : ils disent si l'application amont s'est trompée, **pas si le flux est arrivé dans Oracle**. Cette réponse est dans le **second demi-flux** (dossier `TARGET` de l'export), celui qui alimente Oracle et que rien ne lisait jusqu'ici.

`demiflux2.py` en extrait les quatre preuves d'intégration, `reconciliation.py` les enchaîne :

```
SRC (demi-flux 1) → cible du demi-flux 2 → publiés (TS_OUT) → rejets → Oracle
```

| Flux | Fichier cible du demi-flux 2 | Table Oracle visée |
|---|---|---|
| **Fournisseurs** | `TARGET\Header.csv` + `Line.csv` | `AP_INVOICE*_INTERFACE` |
| **Clients** | `TARGET\FACTURESCLIENTS_FIN01.txt` | `DKA_IARPAFAC_INTERFACE` |
| **GL** | `FAC02_PIVOT_GL_*.txt` (porté par le demi-flux 1) | `GL_INTERFACE` |

Identités vérifiées sur les exports du dépôt, sur lesquelles repose le diagnostic :

- **Fournisseurs** : `lignes(Header) + lignes(Line) = publiés = lignes de données du SRC − lignes rejetées`
- **Clients** : `lignes(FACTURESCLIENTS_FIN01) = publiés = lignes du SRC`

Le résultat n'est plus un OK/KO mais un diagnostic qui nomme l'étage en cause :

| Diagnostic | Signification |
|---|---|
| `INTEGRE_COMPLET` | Tout le fichier est parti vers Oracle |
| `INTEGRE_PARTIEL_REJETS` | Le reste est parti ; les pièces rejetées sont listées avec leur code et leur libellé |
| `NON_PUBLIE` | Le demi-flux 2 n'a pas abouti (`TS_OUT` KO ou absent) |
| `ECART_INEXPLIQUE` | La cascade ne boucle pas ; l'étage qui casse est désigné |
| `DEMI_FLUX2_ABSENT` | Le demi-flux 2 n'a pas été rapatrié (cas des exports GL) |

```bat
python reconciliation.py <dossier_export | fichier_SRC>
python reconciliation.py <dossier_parent> --tous --html    rem journée entière
```

Options : `--tous` (tous les exports d'un dossier parent), `--csv [fichier]`, `--html [fichier]` (rapport consolidé dans `Logs\`), `--rejets-json [fichier]`, `--sans-rapport`. Sans fichier, les sorties machine partent sur la sortie standard. Codes retour : 0 = intégration complète, 1 = erreur technique, 2 = rejets ou écart à traiter.

L'étape est appelée automatiquement par les trois lanceurs `controle*.bat` et ajoute trois onglets au classeur de l'export : **Cascade** (une ligne par fichier transmis), **Rejets** (une ligne par pièce rejetée, avec code, libellé et fonction PL/SQL en cause) et **Statuts Talend**.

## 8. Vérification dans Oracle EBS

Contrôle complémentaire, sur le modèle de `ControleFolioRose` : vérifie si les factures du fichier SRC sont **intégrées dans Oracle** (tables définitives) ou **bloquées en open interface**. Chaque flux utilise désormais un lanceur de contrôle unique :

```bat
controleClient.bat      [dossier_export | fichier_SRC] [fichier_CTL]
controleFournisseur.bat [dossier_export | fichier_SRC] [fichier_CTL]
controleGL.bat          [dossier_export | fichier_SRC] [fichier_CTL]
```

Dossier en paramètre : fichier SRC le plus récent de ce dossier. Fichier en paramètre : ce fichier (glisser-déposer possible). Sans argument : dossier SOURCE aux emplacements connus.

Fonctionnement (une seule session `sqlplus`, connexion partagée dans `config.ps1`) : agrégation du fichier SRC par portefeuille/folio (même règle que le contrôle CTL), puis pour chacun deux comptages Oracle avec la clé fichier = nom SRC tronqué avant `_ST_` (`attribute10 LIKE fichier%`, `attribute9 = portefeuille/folio`) :

| Flux | Définitif | Open interface |
|---|---|---|
| **Clients** (`Verifier_Oracle_FAC02_Client.ps1`) | `APPS.RA_CUSTOMER_TRX_ALL` / `RA_CUSTOMER_TRX_LINES_ALL` | `DKA_IARPAFAC_INTERFACE` (`FIC_IDENT LIKE fichier%`, `FMT_ORIGIN = portefeuille`, comptes `411%`, lignes non soldées `OA_status != 'A'`) |
| **Fournisseurs** (`Verifier_Oracle_FAC02_Fournisseur.ps1`) | `APPS.AP_INVOICES_ALL` | `APPS.AP_INVOICES_INTERFACE` + `AP_INVOICE_LINES_INTERFACE`, hors lignes rejetées (`AP_INTERFACE_REJECTIONS`) |
| **GL** (`Verifier_Oracle_Ecritures_GL.ps1`) | `APPS.GL_JE_HEADERS` + `APPS.GL_JE_LINES` | `APPS.GL_INTERFACE` |

Statut par portefeuille/folio :

| Statut | Signification |
|---|---|
| `INTEGREE` | Nb et montant retrouvés dans les tables définitives |
| `EN INTERFACE` | Rien en définitif, montant retrouvé en open interface |
| `PARTIELLE` | Réparti entre définitif et interface (somme cohérente) |
| `ABSENTE` | Introuvable dans Oracle |
| `ECART` | Montants incohérents |

### Motif de rejet dans l'onglet Détail

Une pièce refusée par les contrôles fonctionnels du second demi-flux **n'est jamais soumise à Oracle** : elle ressortait donc `ABSENTE`, ce qui est exact mais muet — ni la cause, ni l'action à mener.

L'onglet **Détail Oracle** interroge maintenant `reconciliation.py --rejets-json` (fonction `Get-RejetsDemiFlux2` de `rapport_oracle.ps1`) et gagne trois colonnes, `Code Rejet`, `Motif Rejet` et `Appel PL/SQL`. Ces pièces prennent le statut `REJETEE` :

| Pièce | Statut | Code | Motif | Appel PL/SQL |
|---|---|---|---|---|
| `VLF26G0026` | `REJETEE` | `OAE025` | Site Fournisseur inactif ou inexistant | `XXEAI_INTERFACE_TOOLS_PKG.Get_Info_Invoice_Header` |

Le traitement diffère d'une pièce `ABSENTE` : il s'agit de corriger le référentiel puis de rejouer, non de chercher dans Oracle. Si le second demi-flux n'a pas été rapatrié, la lecture échoue en silence et le contrôle se déroule exactement comme avant.

Sortie dans `Logs\` (clients : `Rapport_Oracle_FAC02_*`, fournisseurs : `Rapport_Oracle_FAC02_FOURNISSEURS_*`) — **un seul fichier**, sur le modèle des rapports de `CTRL_QUASI_AUTOMATIQUE_DES_PRELEVEMENTS` :

- `..._<horodatage>.xlsx` : classeur Excel à 2 onglets — **Synthèse** (par portefeuille/folio) et **Détail Factures** (pièce, date, montant fichier vs Oracle vs interface). La colonne Statut est colorée : **vert** = `INTEGREE`, **pêche** = tout autre statut (nécessite Excel installé sur le poste ; via automatisation COM, sans dépendance supplémentaire).
- Sans Excel sur le poste uniquement, deux CSV de secours sont produits à la place : `..._<horodatage>.csv` (synthèse) et `..._Detail_<horodatage>.csv` (détail).

Codes retour : 0 = tout intégré, 1 = erreur technique (dont erreur Oracle : aucun rapport produit, pour ne pas présenter des zéros comme un résultat), 2 = anomalies (interface / absent / écart).

Options du script PowerShell : `-Diagnostic` (affiche le SQL généré et la sortie brute d'Oracle), `-GarderTempSQL` (conserve le script SQL dans `Logs\`).

> **Prérequis sur le poste d'exécution** (non disponibles sur ce poste de développement) : un client Oracle (`sqlplus`, `sqlcl` ou `sql`) dans le PATH, et `config.ps1` renseigné (ne pas committer ce fichier : il contient le mot de passe).
