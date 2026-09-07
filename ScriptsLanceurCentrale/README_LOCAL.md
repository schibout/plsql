# Lanceur CapAppro — mode d'emploi en local

**Le mode de référence est `CapAppro_LOCAL.py`, qui lit les classeurs Excel
sur le Google Drive** — exactement comme l'ordonnanceur de production.

Un extracteur natif PowerShell existe en secours, pour un poste où Python
n'est pas exploitable. Il ne remplace pas le mode Python : il n'accède pas au
Drive et exige que les fichiers soient copiés à la main.

| | **Mode Python (référence)** | **Mode natif PowerShell (secours)** |
|---|---|---|
| Point d'entrée | `CapAppro_LOCAL.py` | `CapAppro_Local.ps1` / `.bat` |
| Classeurs lus **sur le Drive** | **oui** | non — copie manuelle |
| Téléchargement des `.sql` | oui | non — copie manuelle |
| Requêtes Oracle | oui | oui |
| Export CSV / XLSX | oui | oui (en local) |
| Scripts PL/SQL | oui | oui (sqlplus) |
| Upload Drive / mails / `HistoExec` | oui | non |
| Iso-production | **oui** | non |
| Python requis | oui | non |

Commencer par un diagnostic de l'environnement :

```bash
py CapAppro_LOCAL.py --check
```

Il liste précisément ce qui est présent et ce qui manque.

---

# PARTIE A — Mode Python, classeurs lus sur le Drive

## A.1 Prérequis

```bash
py -m pip install -r requirements.txt
```

Trois éléments ne s'installent pas avec pip et doivent être récupérés sur la
machine RPA :

1. **Les librairies maison** — copier le dossier
   `C:\RPA\python-libraries\` (`gdrive`, `pylibrary`, `gmail`), puis
   renseigner son emplacement dans `[paths] LIBRARY_PATH`.
   **Sans elles, aucun accès au Drive n'est possible.**
2. **Le jeton OAuth** utilisé par `gdrive(token="générique")`, sans quoi
   l'authentification Google échouera.
3. **Le client Oracle**, sans quoi `cx_Oracle.init_oracle_client()` échoue.

⚠️ `cx_Oracle` ne se compile pas sous Python 3.13 : sa dernière version
(8.3.0) ne fournit pas de wheel au-delà de Python 3.11. Utiliser un
interpréteur plus ancien, par exemple `py -3.10 CapAppro_LOCAL.py 39`.

## A.2 Utilisation

```bash
py CapAppro_LOCAL.py --check         # diagnostic de l'environnement
py CapAppro_LOCAL.py --list          # lister les IdExec (lus sur le Drive)
py CapAppro_LOCAL.py 39 --dry-run    # afficher la commande, sans exécuter
py CapAppro_LOCAL.py 39              # lancer
py CapAppro_LOCAL.py 39,40           # plusieurs lignes
```

Codes retour : `0` succès, `1` échec d'exécution, `2` argument invalide ou
plan d'exécution illisible.

## A.3 Le Drive est la source de référence

Le plan d'exécution est lu **sur le Drive**. Si celui-ci est injoignable, le
script **s'arrête** au lieu de basculer silencieusement sur une copie locale
qui pourrait être périmée :

```
[ERROR] Les librairies maison sont introuvables : le Drive n'est pas accessible.
[ERROR] Arrêt : le plan d'exécution doit être lu sur le Drive.
```

Le repli sur une copie locale doit être demandé explicitement, et n'est utile
que pour dépanner hors ligne :

```bash
py CapAppro_LOCAL.py 39 --local      # ponctuel
```
```ini
[local]
AUTORISER_REPLI_LOCAL = oui          # ou durablement, dans le .ini
```

## A.4 ⚠️ Ce qu'une exécution modifie vraiment

`CapAppro_LOCAL.py` lance **le vrai worker**. Même depuis ton poste :

- connexion à la base de `configBDD` — `config_oracle_finance` **est la production** ;
- écriture des fichiers **sur le Drive du projet**, en écrasant les homonymes ;
- copie vers le partage DataViz si `Copiedataviz` est renseigné ;
- **envoi de mails** à la `ListeDeDiffusion`, donc à des destinataires métier réels ;
- ajout d'une ligne dans `HistoExec` et upload du log.

Pour tester sans risque : `--dry-run` d'abord, puis la ligne `IdExec 40`
(« TEST »), ou une surcharge d'environnement vers la base de test :

```powershell
$env:CAPAPPRO_CONFIG_ORACLE_FINANCE_BASE_URL = "etiscandb03.eti.dalkia.net"
$env:CAPAPPRO_CONFIG_ORACLE_FINANCE_BASE_SERVICE_NAME = "ebs_PDBFINI2"
```

---

# PARTIE B — Mode natif PowerShell (secours, sans Python)

## B.1 Fichiers

| Fichier | Rôle |
|---|---|
| `CapAppro_Local.ps1` | Extracteur : lit les classeurs, interroge Oracle, écrit les fichiers |
| `CapAppro_Local.bat` | Lanceur CMD (double-clic possible, contourne l'ExecutionPolicy) |
| `CapAppro_Xlsx.psm1` | Lecture/écriture `.xlsx` en OpenXML pur — ni Excel, ni module PSGallery |
| `Get-OracleDriver.ps1` | Télécharge le pilote Oracle managé dans `.\lib\` |
| `config_lanceur_central.ini` | Configuration, section `[powershell]` |

## B.2 Installation

Une seule étape, à faire une fois :

```powershell
.\Get-OracleDriver.ps1
```

Le script récupère `Oracle.ManagedDataAccess.dll` depuis NuGet et le dépose
dans `.\lib\`. C'est une implémentation 100 % .NET du protocole Oracle :
**aucun client Oracle n'est nécessaire**.

> La version 19.28.0 est imposée volontairement. Les versions 21.x et 23.x
> déclarent des dépendances NuGet (`System.Text.Json`, `System.Formats.Asn1`)
> absentes de .NET Framework, et échouent au chargement sous Windows
> PowerShell 5.1 avec une `ReflectionTypeLoadException`.

Si `nuget.org` est bloqué, récupérer le paquet `Oracle.ManagedDataAccess`
manuellement, l'ouvrir comme une archive ZIP et copier
`lib/net462/Oracle.ManagedDataAccess.dll` dans `.\lib\`.

À défaut de pilote managé, le script bascule sur OLE DB (`OraOLEDB.Oracle`)
puis ODBC — mais ces deux modes exigent un client Oracle installé.

## B.3 Préparer le dossier de travail

Le mode natif n'accède pas au Drive. Les fichiers du projet doivent donc être
déposés à la main, dans `DOSSIER_TRAVAIL\<ProjectName>\` :

```
C:\Temp\CapAppro\
└── CapAppro hebdo\                          <- exactement le ProjectName
    ├── EXTRACTIONS_AUTOMATISEES_ORACLE.xlsx <- le classeur lanceur du projet
    ├── COMMANDES_EN_COURS_V2.sql
    ├── BLOCAGES_EN_COURS_V3.sql
    └── extractFiles\                        <- créé automatiquement
```

Le nom du sous-dossier doit correspondre au `ProjectName` du classeur
d'ordonnancement, et le classeur lanceur porter le nom indiqué par
`filenameLanceur`.

## B.4 Configuration

```ini
[powershell]
DOSSIER_TRAVAIL = C:\Temp\CapAppro\
FOURNISSEUR_ORACLE = auto        ; auto | managed | oledb | odbc
ODP_MANAGED_DLL =                ; vide = recherche automatique
TIMEOUT_REQUETE_SECONDES = 3600

[local]
FICHIER_ORDONNANCEUR = OrdonnanceurCentral (1).xlsx
ONGLET_ORDONNANCEUR  = Feuil1
```

Comme du côté Python, toute clé se surcharge par variable d'environnement
`CAPAPPRO_<SECTION>_<CLE>` :

```powershell
$env:CAPAPPRO_CONFIG_ORACLE_FINANCE_BASE_URL = "etiscandb03.eti.dalkia.net"
$env:CAPAPPRO_CONFIG_ORACLE_FINANCE_BASE_SERVICE_NAME = "ebs_PDBFINI2"
```

## B.5 Utilisation

```powershell
.\CapAppro_Local.ps1 -List           # lister les IdExec disponibles
.\CapAppro_Local.ps1 1 -DryRun       # afficher le plan, sans toucher la base
.\CapAppro_Local.ps1 1               # exécuter
.\CapAppro_Local.ps1 1,5 -DryRun     # plusieurs projets
```

Équivalents en CMD, sans se soucier de l'ExecutionPolicy :

```
CapAppro_Local.bat -List
CapAppro_Local.bat 1 -DryRun
CapAppro_Local.bat 1
```

Un double-clic sur le `.bat` liste les projets et laisse la fenêtre ouverte.

Codes retour : `0` succès, `1` échec d'exécution, `2` argument invalide,
`3` PowerShell introuvable, `4` script introuvable.

## B.6 Sortie

```
17:54:36 [INFO] >>> DEBUT  PROJET [1/1] IdExec 1 - CapAppro hebdo
17:54:36 [INFO] Lignes actives dans le classeur lanceur : 7 / 23
17:54:36 [INFO] Connexion établie via ODP.NET managé (...\lib\Oracle.ManagedDataAccess.dll)
17:54:36 [INFO] >>> DEBUT  [1/7] EXPORT :: COMMANDES_EN_COURS_V2.sql
17:54:38 [INFO] Résultat : 15 234 ligne(s) x 22 colonne(s)
17:54:39 [INFO] Écrit : C:\Temp\CapAppro\CapAppro hebdo\extractFiles\COMMANDES_EN_COURS.csv
17:54:39 [INFO] <<< FIN    [1/7] EXPORT :: COMMANDES_EN_COURS_V2.sql | statut=OK | duree=00:00:03
...
17:54:52 [INFO] SYNTHÈSE
Requete                     Type   Statut Lignes Duree
COMMANDES_EN_COURS_V2.sql   export OK      15234 00:00:03
```

Le format CSV reproduit celui de la production : séparateur `;`, encodage
UTF-8 avec BOM, tout champ non numérique entre guillemets, dates en
`JJ/MM/AAAA HH:MM:SS`, décimaux à 5 chiffres.

## B.7 Différences de comportement assumées

| Point | Production (Python) | Mode natif |
|---|---|---|
| Retrait des `;` | **tous** les `;` du fichier, y compris dans les littéraux | seul le `;` terminal — comportement corrigé |
| Typage des nombres | déduit par pandas | issu du pilote Oracle ; un `NUMBER` sans échelle peut différer d'une colonne |
| Fichier XLSX | xlsxwriter | générateur OpenXML minimal, une feuille, sans mise en forme |

## B.8 Problèmes courants

| Symptôme | Cause | Correctif |
|---|---|---|
| `Oracle.ManagedDataAccess.dll introuvable` | pilote non installé | `.\Get-OracleDriver.ps1` |
| `ReflectionTypeLoadException` au chargement | version 21.x/23.x du pilote | `.\Get-OracleDriver.ps1 -Version 19.28.0` |
| `ORA-12545 : impossible de résoudre le nom de l'hôte` | serveur non joignable | se connecter au réseau Dalkia / VPN |
| `ORA-12154` | chaîne de connexion non résolue | vérifier `BASE_URL`, `BASE_PORT`, `BASE_SERVICE_NAME` |
| `ORA-01017` | identifiants refusés | vérifier `DB_USER` / `DB_PASSWORD` |
| `Classeur lanceur introuvable` | dossier de travail incomplet | voir §B.3 |
| Accents illisibles dans la console | fichier `.ps1` sans BOM UTF-8 | les fichiers livrés en ont un : ne pas les réenregistrer en ANSI |
| `l'exécution de scripts est désactivée` | ExecutionPolicy | passer par `CapAppro_Local.bat`, ou `-ExecutionPolicy Bypass` |

---

# Comment le classeur pilote l'exécution

```
Classeur d'ordonnancement — onglet Feuil1
        │  une ligne = un projet, repérée par IdExec
        ▼
   IdExec 1 -> ProjectName, filenameLanceur, config, Drive...
        │
        ▼
Classeur lanceur du projet (filenameLanceur)
        │  une ligne = une requête
        │    Type = Script  ->  sqlplus (procédure PL/SQL)
        │    Type = Export  ->  SELECT -> .csv / .xlsx
        ▼
   Fichiers de sortie
```

`IdExec` désigne un **projet**, pas une requête. Un projet exécute autant de
requêtes que son classeur lanceur compte de lignes `Exécution = oui`.

---

# Limites connues

Détaillées dans [PROMPT_CONTEXTE.md](PROMPT_CONTEXTE.md). Les plus utiles ici :

- les mots de passe sont encore en clair dans le `.ini` ;
- côté Python, l'écriture XLSX est lente sur les gros volumes (~7 min pour
  47 Mo) : un export qui « ne rend pas la main » est souvent en train
  d'écrire son fichier ;
- `saveToExcel` trace ses erreurs sans les propager : un export peut être
  compté `OK` alors que le fichier n'a pas été écrit.
