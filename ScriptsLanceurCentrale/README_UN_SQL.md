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

Identique au worker `CapAppro_GENERIQUE_EXECUTION.py` :

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
