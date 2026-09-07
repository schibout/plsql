# Lanceur CapAppro — mode d'emploi en local

Deux façons de rejouer une extraction depuis un poste de développement.

| | **Mode natif PowerShell** | **Mode Python** |
|---|---|---|
| Point d'entrée | `CapAppro_Local.ps1` / `.bat` | `CapAppro_LOCAL.py` |
| Python requis | non | oui |
| Requêtes Oracle | oui | oui |
| Export CSV / XLSX | oui (en local) | oui |
| Scripts PL/SQL | oui (sqlplus) | oui |
| Téléchargement Drive | **non** | oui |
| Upload Drive | **non** | oui |
| Envoi des mails | **non** | oui |
| Mise à jour `HistoExec` | **non** | oui |
| Iso-production | non | **oui** |

Le mode natif est un outil de **mise au point de requêtes**. Le mode Python
reste la seule reproduction fidèle de la production.

---

# PARTIE A — Mode natif PowerShell (sans Python)

## A.1 Fichiers

| Fichier | Rôle |
|---|---|
| `CapAppro_Local.ps1` | Extracteur : lit les classeurs, interroge Oracle, écrit les fichiers |
| `CapAppro_Local.bat` | Lanceur CMD (double-clic possible, contourne l'ExecutionPolicy) |
| `CapAppro_Xlsx.psm1` | Lecture/écriture `.xlsx` en OpenXML pur — ni Excel, ni module PSGallery |
| `Get-OracleDriver.ps1` | Télécharge le pilote Oracle managé dans `.\lib\` |
| `config_lanceur_central.ini` | Configuration, section `[powershell]` |

## A.2 Installation

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

## A.3 Préparer le dossier de travail

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

## A.4 Configuration

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

## A.5 Utilisation

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

## A.6 Sortie

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

## A.7 Différences de comportement assumées

| Point | Production (Python) | Mode natif |
|---|---|---|
| Retrait des `;` | **tous** les `;` du fichier, y compris dans les littéraux | seul le `;` terminal — comportement corrigé |
| Typage des nombres | déduit par pandas | issu du pilote Oracle ; un `NUMBER` sans échelle peut différer d'une colonne |
| Fichier XLSX | xlsxwriter | générateur OpenXML minimal, une feuille, sans mise en forme |

## A.8 Problèmes courants

| Symptôme | Cause | Correctif |
|---|---|---|
| `Oracle.ManagedDataAccess.dll introuvable` | pilote non installé | `.\Get-OracleDriver.ps1` |
| `ReflectionTypeLoadException` au chargement | version 21.x/23.x du pilote | `.\Get-OracleDriver.ps1 -Version 19.28.0` |
| `ORA-12545 : impossible de résoudre le nom de l'hôte` | serveur non joignable | se connecter au réseau Dalkia / VPN |
| `ORA-12154` | chaîne de connexion non résolue | vérifier `BASE_URL`, `BASE_PORT`, `BASE_SERVICE_NAME` |
| `ORA-01017` | identifiants refusés | vérifier `DB_USER` / `DB_PASSWORD` |
| `Classeur lanceur introuvable` | dossier de travail incomplet | voir §A.3 |
| Accents illisibles dans la console | fichier `.ps1` sans BOM UTF-8 | les fichiers livrés en ont un : ne pas les réenregistrer en ANSI |
| `l'exécution de scripts est désactivée` | ExecutionPolicy | passer par `CapAppro_Local.bat`, ou `-ExecutionPolicy Bypass` |

---

# PARTIE B — Mode Python (iso-production)

À utiliser dès que le poste dispose d'un environnement Python complet : c'est
la seule façon de reproduire fidèlement la chaîne, Drive et mails compris.

## B.1 Installation

```bash
py -m pip install -r requirements.txt
```

Il faut en plus, et pip ne peut pas les fournir :

- les librairies maison `gdrive`, `pylibrary`, `gmail` (`C:\RPA\python-libraries\`) ;
- le client Oracle, sans quoi `cx_Oracle.init_oracle_client()` échoue ;
- le dossier `[paths] TEMP_FOLDER` (par défaut `C:\Temp\`).

## B.2 Utilisation

```bash
py CapAppro_LOCAL.py --list          # lister les IdExec
py CapAppro_LOCAL.py 39 --dry-run    # afficher la commande, sans exécuter
py CapAppro_LOCAL.py 39              # lancer
py CapAppro_LOCAL.py 39,40           # plusieurs lignes
py CapAppro_LOCAL.py 39 --local      # forcer la copie locale du classeur
```

Le plan d'exécution est lu **sur le Drive par défaut**, avec repli automatique
sur la copie locale si le Drive est injoignable.

## B.3 ⚠️ Ce qu'une exécution modifie vraiment

`CapAppro_LOCAL.py` lance **le vrai worker**. Même depuis ton poste :

- connexion à la base de `configBDD` — `config_oracle_finance` **est la production** ;
- écriture des fichiers **sur le Drive du projet**, en écrasant les homonymes ;
- copie vers le partage DataViz si `Copiedataviz` est renseigné ;
- **envoi de mails** à la `ListeDeDiffusion`, donc à des destinataires métier réels ;
- ajout d'une ligne dans `HistoExec` et upload du log.

Pour tester sans risque : `--dry-run` d'abord, puis la ligne `IdExec 40`
(« TEST »), ou une surcharge d'environnement vers la base de test.

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
