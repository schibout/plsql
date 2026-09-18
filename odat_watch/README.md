# ODAT Watch

Exploitation des photos Control-M (fichiers ODAT `Report_ctm_*.csv`) pour répondre à :
**qu'est-ce qui tourne ce soir, et demain ?** (FIN-FINANCE par défaut, toutes applications disponibles).

## Contenu

| Fichier | Rôle |
|---|---|
| `ingest.py` | Scanne `../ODAT` et `~/Downloads`, archive chaque CSV dans `../ODAT/archive/AAAA/MM/JJ/HHMM_odate_*.csv`, charge dans `odat.db` (SQLite). Les doublons sont ignorés (hash du fichier). |
| `forecast.py` | Profils par job (heure médiane, durée, jours, fiabilité) et prévisions ce soir / demain, anomalies. |
| `app.py` | Interface Streamlit : Ce soir, Demain, Maintenant, Historique, Profils, Données. |
| `run.bat` | Import + lancement de l'interface. |
| `config.ini.exemple` | Connexion Oracle (étape 2, pas encore branchée). |

## Installation (une fois)

Python 3.11+ avec `streamlit`, `pandas`, `plotly`. Le Python du Microsoft Store échoue sur
les chemins longs : créer un venv dans un chemin court.

```bat
python -m venv C:\tmp\odatenv
C:\tmp\odatenv\Scripts\python.exe -m pip install streamlit pandas plotly
```

## Utilisation

1. Déposer les fichiers ODAT reçus dans `../ODAT` (ou les laisser dans Téléchargements).
2. Double-cliquer `run.bat` : les nouveaux fichiers sont importés, le navigateur s'ouvre.
3. Le bouton « Importer les nouveaux fichiers ODAT » de la barre latérale fait la même chose sans relancer.

Les heures prévues sont la médiane des démarrages observés : avec 3 jours d'historique c'est
indicatif, avec 3 mois c'est fiable. Les jobs hebdo (`_H`) et mensuels (`_M`) ne sont prévus
que les jours de semaine où on les a déjà vus.

## Étape suivante

Rafraîchissement depuis `FND_CONCURRENT_REQUESTS` (la DESCRIPTION contient le nom du job
Control-M, donc le lien est automatique) pour croiser Control-M et la réalité côté R12.
