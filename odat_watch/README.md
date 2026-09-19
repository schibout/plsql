# ODAT Watch

Exploitation des photos Control-M (fichiers ODAT `Report_ctm_*.csv`) et des demandes concurrentes
Oracle EBS R12 pour répondre à : **qu'est-ce qui tourne ce soir, et demain ?** puis
**pourquoi ça a planté ?** (FIN-FINANCE par défaut, toutes applications disponibles).

## Contenu

| Fichier | Rôle |
|---|---|
| `ingest.py` | Scanne `../ODAT` et `~/Downloads`, archive chaque CSV dans `../ODAT/archive/AAAA/MM/JJ/HHMM_odate_*.csv`, charge dans `odat.db` (SQLite). Doublons ignorés (hash du fichier). |
| `forecast.py` | Profils par job Control-M (heure médiane, durée, jours, fiabilité), prévisions ce soir / demain, anomalies. |
| `oracle_refresh.py` | **Brique Oracle Apps** : charge `FND_CONCURRENT_REQUESTS` (48 h + demandes en attente) et `FND_CONCURRENT_PROGRAMS` dans SQLite. Lie chaque demande à son job Control-M (la DESCRIPTION des demandes du lanceur DKA_SLAUNCHER contient le nom du job ; les demandes filles héritent du parent). |
| `logs.py` | Analyse des `l<id>.req` / `o<id>.out` rapatriés du serveur EBS : compteurs, messages FND_FILE, codes d'erreur, diagnostic. Génère `list.txt` pour `copy_ebs_logs.sh`. |
| `diagnostics.json` | Dictionnaire code d'erreur → explication, action, gravité. **À enrichir au fil des incidents.** |
| `ui_oracle.py` | Onglet Oracle de l'interface. |
| `ui_sql.py` | Onglet SQL : explorateur des tables SQLite (structure, volumes) et requêteur libre en lecture seule, exemples fournis, export CSV. |
| `mock_oracle.py` | **Poste sans Oracle** : fabrique des demandes simulées à partir des exécutions Control-M (lanceur + programme métier, statuts alignés) et des logs présents. `python mock_oracle.py --reset`. Écrasé par les vraies données au premier `oracle_refresh.py`. |
| `app.py` | Interface Streamlit : Ce soir, Demain, Maintenant, Oracle, Historique, Profils, Données, SQL. |
| `.streamlit/config.toml` | Thème de l'interface. |
| `run.bat` | Import ODAT + lancement de l'interface. |
| `config.ini.exemple` | Modèle de configuration (Oracle, filtres, dossiers de logs). Copier en `config.ini` (ignoré par git). |

## Installation (une fois)

Python 3.11+ avec `streamlit`, `pandas`, `plotly`, `oracledb`. Le Python du Microsoft Store échoue
sur les chemins longs : créer un venv dans un chemin court.

```bat
python -m venv C:\tmp\odatenv
C:\tmp\odatenv\Scripts\python.exe -m pip install streamlit pandas plotly oracledb
copy config.ini.exemple config.ini      REM puis renseigner user / password / dsn
```

## Utilisation

1. Déposer les fichiers ODAT reçus dans `../ODAT` (ou les laisser dans Téléchargements).
2. Double-cliquer `run.bat` : import des nouveaux fichiers, ouverture du navigateur.
3. Barre latérale : « Importer les nouveaux fichiers ODAT », « Demandes » (Oracle 48 h), « Programmes »
   (référentiel, une fois par semaine suffit), « Analyser les logs ».

En ligne de commande :

```bat
python oracle_refresh.py --test          REM teste la connexion
python oracle_refresh.py --programmes    REM référentiel + demandes
python oracle_refresh.py --jours 90      REM chargement initial long
python logs.py                           REM analyse les dossiers de config.ini [logs]
python logs.py --liste                   REM écrit list.txt des logs manquants (demandes en erreur)
```

## Cycle d'analyse d'un incident

1. Onglet **Maintenant** : job Control-M en Ended Not OK.
2. Onglet **Oracle › Erreurs et logs** : la demande Oracle correspondante, son statut, son `completion_text`,
   les chemins `logfile_name` / `outfile_name`.
3. Pas de log local : bouton « Générer list.txt », puis sur le serveur EBS
   `./copy_ebs_logs.sh list.txt` (script dans `ControleReleveBancaire/`), rapatrier les fichiers dans un
   dossier listé dans `config.ini [logs]`.
4. « Analyser les logs » : compteurs, erreurs comptées, diagnostic et action proposés depuis `diagnostics.json`.
5. Code inconnu : le qualifier et l'ajouter dans `diagnostics.json` (clé exacte ou préfixe `ORA-20*`).

## Notes

- L'heure d'une photo est déduite de son contenu (dernier événement du fichier), pas de la date du fichier,
  qui change à chaque copie ou téléchargement en lot.
- Les heures prévues sont la médiane des démarrages observés : indicatif à 3 jours, fiable à 3 mois.
  Les jobs hebdo (`_H`) et mensuels (`_M`) ne sont prévus que les jours de semaine où on les a déjà vus.
- Le compte Oracle peut être nominatif : les vues FND doivent être lisibles sans préfixe (sinon
  `schema = APPS` dans `config.ini`).
- Piste à tester pour éviter le passage par le serveur : `FND_WEBFILE.GET_URL` renvoie une URL de
  téléchargement du log via le serveur web EBS.
- Prochaine étape possible : `ingest_gmail.py` (IMAP + mot de passe d'application) pour récupérer
  les ODAT directement depuis la boîte mail.
