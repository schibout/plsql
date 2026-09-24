# Dashboard contrôle EBS

Application web Google Apps Script qui affiche les CSV d'un dossier Drive.
Les CSV sont produits toutes les heures par `export_csv.bat` (→ `export_csv.py`), qui exécute les
requêtes de `sql/` (extraites de `ControleMatinGenerique/Controle_Quotidien_Complet.sql`).

```
Oracle EBS --export_csv.bat (horaire)--> CSV_DIR (Drive pour ordinateur) --> dossier Drive --> app web (Index.html)
```

## Contenu

| Fichier | Rôle |
|---|---|
| `sql/00_kpi.sql` | Synthèse du jour (bloc PL/SQL d'origine réécrit en SELECT) → tuiles |
| `sql/01..17_*.sql` | Une requête par tableau du dashboard |
| `export_csv.py` | Exécute toutes les requêtes (python-oracledb, connexion d'odat_watch), un CSV par requête ; variables `nb_jours_histo`=3, `heure_fermeture`=19, `heure_ouverture`=7 |
| `export_csv.bat` | Lanceur pour la tâche planifiée : fixe `CSV_DIR` et `PYTHON` (surchargeables dans un `config.bat` optionnel) |
| `Config.gs` | ID du dossier Drive, seuil « périmé », liste des sections |
| `Code.gs` / `Index.html` | App web |
| `deploy.bat` | Tests locaux puis `clasp push` (+ `clasp deploy` si `.deployment_id`) |

Ajouter une requête : déposer `sql/18_xxx.sql`, puis ajouter la ligne
`18_xxx.csv` dans `DASHBOARD_SECTIONS` (`Config.gs`) — le test local échoue
tant que les deux ne correspondent pas.

## Première installation

1. **Export Oracle** : la connexion est celle d'odat_watch (`odat_watch/config.ini`,
   section `[database]` : dsn, user, password, schema, mode, client_dir) — rien à
   ressaisir. Régler `CSV_DIR` (dossier synchronisé par Google Drive pour ordinateur)
   dans `export_csv.bat` ou dans un `config.bat` (`set CSV_DIR=...`, `set PYTHON=...`).
   Lancer `export_csv.bat` une fois : une ligne `[OK]`/`[KO]` par requête.
2. **Planification horaire** :
   ```
   schtasks /create /tn "Dashboard EBS export" /sc hourly /tr "\"%CD%\export_csv.bat\""
   ```
3. **Apps Script** (`npm install -g @google/clasp` puis `clasp login`) :
   ```
   clasp create --type webapp --title "Projet_Dashboard" --rootDir .
   ```
   (si `clasp create` réécrit `appsscript.json`, le restaurer avec `git checkout appsscript.json`).
4. Dans `Config.gs`, renseigner `FOLDER_ID` (ID du dossier Drive des CSV).
5. `deploy.bat`, puis dans l'éditeur : **Déployer › Nouveau déploiement › Application web**.
   Copier l'ID de déploiement dans un fichier `.deployment_id` : les
   `deploy.bat` suivants mettront à jour la même URL `/exec`.

`appsscript.json` limite l'accès à `MYSELF` ; passer à `DOMAIN` pour partager.

## Lecture

- Tuiles : `OK` / `W` / `KO`, mêmes règles que le contrôle du matin (J-1).
- « périmé » : CSV non mis à jour depuis plus de `STALE_HOURS` (3 h) — export
  en échec pour cette requête (le CSV précédent est conservé, le message d'erreur est dans la sortie de `export_csv.bat`).
- « à traiter » : section qui ne devrait pas avoir de ligne (rejets, erreurs, images manquantes).
- La page se recharge toute seule toutes les 15 minutes.
