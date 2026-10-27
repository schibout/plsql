# CapAppro_UN_SQL — exécuter un seul fichier SQL

Lanceur autonome du Lanceur Central : exécute **un** fichier `.sql` sur Oracle
et enregistre le résultat dans **un** fichier `.csv` ou `.xlsx`. Pas de Drive,
pas de mail, pas de classeur lanceur : uniquement la requête et sa sortie.

## Utilisation

```bat
CapAppro_UN_SQL.bat requete.sql resultat.csv
CapAppro_UN_SQL.bat requete.sql resultat.xlsx --configBDD config_oracle_finance
CapAppro_UN_SQL.bat requete.sql resultat.csv --env-oracle env_oracle.sh
```

ou directement en Python :

```bat
C:\tmp\odatenv\Scripts\python.exe CapAppro_UN_SQL.py --sql requete.sql --sortie resultat.csv
py CapAppro_UN_SQL.py --sql requete.sql --sortie resultat.csv --dry-run
```

| Option | Rôle |
|---|---|
| `--sql <fichier>` | fichier `.sql` à exécuter (une seule requête `SELECT` / `WITH`) |
| `--sortie <fichier>` | fichier de sortie ; le format est déduit de l'extension : `.csv` ou `.xlsx` |
| `--configBDD <section>` | section `[config_...]` de `config_lanceur_central.ini` |
| `--env-oracle <fichier>` | fichier `env_oracle.sh` (`export ORACLE_USER=...`) |
| `--dry-run` | affiche la connexion résolue et la requête, n'exécute rien |

Le `;` ou `/` final du fichier SQL est retiré automatiquement. Encodages
acceptés : UTF-8 (avec ou sans BOM), cp1252.

Codes retour : `0` succès, `1` échec d'exécution, `2` argument invalide.

## Identifiants de connexion

Ordre de priorité :

1. `--configBDD <section>` : section du `.ini` (`config_oracle_prod`,
   `config_oracle_finance`, `config_oracle_test`, ...). Toute clé reste
   surchargeable par une variable d'environnement `CAPAPPRO_<SECTION>_<CLE>`,
   par exemple `CAPAPPRO_CONFIG_ORACLE_PROD_DB_PASSWORD`.
2. `--env-oracle <fichier>` : fichier shell `env_oracle.sh` ; les références
   `${VAR}` sont résolues.
3. Sans option : `[connexion] DEFAUT_CONFIG_BDD` du `.ini` (par défaut
   `config_oracle_prod`) ; si vide, `env_oracle.sh` à côté du script ; sinon
   les variables `ORACLE_USER`, `ORACLE_PASSWORD`, `ORACLE_HOST`,
   `ORACLE_PORT`, `ORACLE_SERVICE` de la session.

Le mot de passe est masqué dans les logs.

## Pilote Oracle

Le script reprend le fonctionnement d'ODAT Watch (`odat_watch/oracle_refresh.py`) :
**`python-oracledb`** en priorité, `cx_Oracle` seulement en repli.

Section `[connexion]` de `config_lanceur_central.ini` :

```ini
DEFAUT_CONFIG_BDD = config_oracle_prod
MODE = auto                              ; auto | thin | thick
CLIENT_DIR = C:\app\instantclient_23_26  ; même valeur que odat_watch\config.ini
```

- `auto` : mode thick si `CLIENT_DIR` (ou `[paths] ORACLE_CLIENT_HOME\bin`)
  existe, sinon thin (aucun client Oracle nécessaire).
- `thin` : jamais de client.
- `thick` : client obligatoire ; nécessaire pour les comptes dont le mot de
  passe a un vérificateur 10g (erreur `DPY-3015`). Dézipper un Instant Client
  64 bits (Basic Light suffit, 19c ou plus) et renseigner `CLIENT_DIR`.

### Quel Python ?

`CapAppro_UN_SQL.bat` cherche, comme `odat_watch\run.bat` :

1. `.venv\Scripts\python.exe` à côté du script ;
2. `C:\tmp\odatenv\Scripts\python.exe` (venv d'ODAT Watch, contient `oracledb`) ;
3. sinon `py` du PATH.

Erreur `No module named 'cx_Oracle'` / `'oracledb'` : le Python utilisé n'a pas
de pilote. Soit lancer avec le venv d'ODAT Watch, soit installer le pilote :

```bat
py -m pip install oracledb pandas XlsxWriter
```

## Format de sortie

Identique au worker `CapAppro_GENERIQUE_EXECUTION.py`, sauf l'en-tête
(noms de colonnes), toujours écrit en minuscules :

- **CSV** : séparateur `;`, UTF-8 avec BOM, chaînes entre guillemets, dates
  `dd/mm/yyyy hh:mm:ss`, nombres décimaux sur 5 décimales.
- **XLSX** : feuille `Sheet1`, dates au format `dd/mm/yyyy hh:mm:ss`.

## Fichiers

| Fichier | Rôle |
|---|---|
| `CapAppro_UN_SQL.py` | le lanceur |
| `CapAppro_UN_SQL.bat` | wrapper Windows (choix du Python) |
| `config_lanceur_central.ini` | sections `[config_...]` et `[connexion]` |
| `capappro_config.py` | lecture du `.ini`, journalisation (partagé avec le Lanceur Central) |
| `env_oracle.sh` | identifiants au format shell (optionnel) |

## Variante en flux : CapAppro_UN_SQL_FLUX

Pour les grosses extractions. Mêmes identifiants et même format que
`CapAppro_UN_SQL`, mais les lignes sont lues et écrites **par lots**
(`fetchmany`), sans pandas et sans tout charger en mémoire. La mémoire reste
constante quel que soit le volume.

Le paramètre principal est un **fichier CSV** qui liste une ou plusieurs
extractions, une par ligne, au format `requete;resultat` :

```text
requete;resultat
# les lignes vides et celles commençant par # sont ignorées
C:\Projects\plsql\ScriptsLanceurCentrale\capApproSql\D5_folio_vs_batchprefix.sql;C:\Projects\plsql\ScriptsLanceurCentrale\csv_result\D5_folio_vs_batchprefix.csv
capApproSql\D1_folios_fichiers_ap.sql;csv_result\D1_folios_fichiers_ap.xlsx
```

La ligne d'en-tête est facultative. Les chemins relatifs partent du dossier
du CSV. Le dossier de sortie est créé s'il n'existe pas. Exemple fourni :
`query_execute.csv`.

```bat
CapAppro_UN_SQL_FLUX.bat query_execute.csv
CapAppro_UN_SQL_FLUX.bat query_execute.csv --lot 200 --arret-sur-erreur
CapAppro_UN_SQL_FLUX.bat requete.sql resultat.csv --lot 200
py CapAppro_UN_SQL_FLUX.py --csv query_execute.csv --configBDD config_oracle_finance
py CapAppro_UN_SQL_FLUX.py --sql requete.sql --sortie resultat.xlsx --lot 500
```

Le `.bat` choisit le mode selon le premier argument : un `.csv` lance la
liste, sinon il attend `requete.sql sortie`.

| Option | Rôle |
|---|---|
| `--csv <liste.csv>` | liste des extractions `requete;resultat` |
| `--sql <f.sql> --sortie <f.csv>` | une seule extraction, au lieu de `--csv` |
| `--lot <N>` | lignes lues puis écrites par lot ; défaut `[execution] TAILLE_LOT` du `.ini`, sinon 500 |
| `--arret-sur-erreur` | arrête la liste à la première extraction en échec ; par défaut, les suivantes continuent |
| `--dry-run` | vérifie la liste, les fichiers SQL et la connexion résolue, sans rien exécuter |

Une seule connexion Oracle sert à toute la liste. Un bilan final donne le
statut de chaque ligne. Codes retour : `0` tout OK, `1` au moins une
extraction en échec, `2` argument ou CSV invalide.

Comportement :

- **Écriture atomique** : le résultat est écrit dans `<sortie>.tmp`, puis
  renommé à la fin. En cas d'échec, le `.tmp` est supprimé et l'ancien fichier
  de sortie reste intact. Pendant l'exécution, la taille du `.tmp` en CSV
  montre l'avancement.
- **Journal** : une ligne de progression au plus toutes les 5 secondes, avec
  le cumul de lignes et le débit.
- **XLSX** : écrit ligne à ligne (xlsxwriter `constant_memory`) ; lisible
  seulement à la fin. Au-delà de 1 048 575 lignes, l'exécution échoue avec un
  message demandant une sortie `.csv`.
- **CLOB/BLOB** : le contenu est écrit (BLOB en hexadécimal).
- La clé `ARRAYSIZE` reste utilisée pour les allers-retours réseau ; la valeur
  effective est le maximum de `ARRAYSIZE` et de la taille de lot.

Format : identique à `CapAppro_UN_SQL` (vérifié octet par octet en CSV et
valeur par valeur en XLSX), avec une seule différence voulue. Un entier est
toujours écrit comme un entier, par exemple `1`. pandas écrit `"1.00000"`
quand la même colonne contient aussi un vide ou un décimal, ce qui ne peut
pas être connu avant d'avoir lu toute la colonne.

| Fichier | Rôle |
|---|---|
| `CapAppro_UN_SQL_FLUX.py` | le lanceur en flux (importe la connexion de `CapAppro_UN_SQL.py`) |
| `CapAppro_UN_SQL_FLUX.bat` | wrapper Windows (choix du Python) |
