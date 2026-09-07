# Lanceur CapAppro — mode d'emploi en local

Comment rejouer une extraction depuis un poste de développement, sans passer
par Rundeck.

---

## 1. À quoi sert quoi

| Fichier | Rôle |
|---|---|
| `CapAppro_LOCAL.py` | **Point d'entrée en local.** On lui donne un `IdExec`, il retrouve tout le reste. |
| `CapAppro_CENTRAL.py` | Ordonnanceur de production, lancé par Rundeck. Ne pas utiliser en local. |
| `CapAppro_GENERIQUE_EXECUTION.py` | Le worker : c'est lui qui fait le travail. Appelé par les deux précédents. |
| `capappro_config.py` | Config partagée + journalisation horodatée. |
| `config_lanceur_central.ini` | Tous les paramètres. C'est le seul fichier à adapter. |

Le lanceur local et l'ordonnanceur envoient au worker **exactement la même
commande** : ce que tu testes en local est ce qui tourne en production.

---

## 2. Installation

```bash
py -m pip install -r requirements.txt
```

Il faut en plus, et pip ne peut pas les fournir :

- **les librairies maison** `gdrive`, `pylibrary`, `gmail` — normalement dans
  `C:\RPA\python-libraries\`. Sans elles, le lanceur local fonctionne encore
  (repli sur une copie locale du classeur), mais le worker, lui, ne démarre
  pas ;
- **le client Oracle** — `cx_Oracle.init_oracle_client()` échoue si le chemin
  `[paths] ORACLE_CLIENT_HOME` n'existe pas. C'est le blocage le plus fréquent
  sur un poste de dev ;
- **le dossier temporaire** `[paths] TEMP_FOLDER` (par défaut `C:\Temp\`), que
  la détection d'encodage utilise. Le créer s'il n'existe pas.

---

## 3. Configuration

Tout est dans `config_lanceur_central.ini`. Sur un poste de dev, seules ces
clés changent en général :

```ini
[paths]
SCRIPT_FOLDER = C:\Users\<toi>\Documents\Project\plsql\ScriptsLanceurCentrale\
LIBRARY_PATH  = C:\RPA\python-libraries\
BASE_DOWNLOAD_FOLDER = C:\Temp\CapAppro\downloadFolder\
ORACLE_CLIENT_HOME   = C:\app\product\12.2.0\client_1

[local]
SOURCE = drive          # drive = classeur du Drive (à jour) | local = copie locale
FICHIER_ORDONNANCEUR = OrdonnanceurCentral (1).xlsx
RESPECTER_COLONNE_EXECUTION = non
```

`SCRIPT_FOLDER` peut rester vide : le dossier du script est alors utilisé.

### Ne pas modifier le fichier pour un test ponctuel

Toute clé se surcharge par variable d'environnement, au format
`CAPAPPRO_<SECTION>_<CLE>` :

```powershell
$env:CAPAPPRO_EXECUTION_TIMEOUT_PROJET_SECONDES = "600"
$env:CAPAPPRO_CONFIG_ORACLE_FINANCE_DB_PASSWORD = "..."
```

Et pour pointer un `.ini` entièrement différent :

```powershell
$env:CAPAPPRO_CONFIG = "C:\Temp\config_test.ini"
```

---

## 4. Utilisation

```bash
py CapAppro_LOCAL.py --list          # lister les IdExec disponibles
py CapAppro_LOCAL.py 39 --dry-run    # afficher la commande SANS l'exécuter
py CapAppro_LOCAL.py 39              # lancer
py CapAppro_LOCAL.py 39,40           # lancer plusieurs lignes
py CapAppro_LOCAL.py 39 --local      # forcer la copie locale du classeur
py CapAppro_LOCAL.py 39 --drive      # forcer la lecture du Drive
```

Codes retour : `0` succès, `1` échec d'exécution, `2` argument invalide.

### Toujours commencer par `--dry-run`

```
16:49:34 [INFO] [DRY-RUN] PROJET [1/1] IdExec 39 - Extraction_Lionel
16:49:34 [INFO] [DRY-RUN] py "...\CapAppro_GENERIQUE_EXECUTION.py"  --idExec "39"
  --ProjectName "Extraction_Lionel" --DownloadDossier_drive_id "1L-5F_..."
  --filenameLanceur "Config_Export_ctrl_Lionel.xlsx" ...
```

C'est le seul moyen de vérifier ce qui va réellement partir avant de toucher
la base de production.

---

## 5. ⚠️ Ce qu'une exécution locale modifie vraiment

`CapAppro_LOCAL.py` lance **le vrai worker**. Une exécution, même depuis ton
poste, produit tous les effets de bord de la production :

- connexion à la base indiquée par `configBDD` — `config_oracle_finance`
  **est la production** ;
- écriture des fichiers de sortie **sur le Google Drive du projet**, en
  écrasant les fichiers existants de même nom ;
- copie vers le partage DataViz si `Copiedataviz` est renseigné ;
- **envoi de mails** à la `ListeDeDiffusion` de la ligne — donc à des
  destinataires métier réels ;
- ajout d'une ligne dans l'onglet `HistoExec` du classeur d'ordonnancement,
  et upload du fichier de log sur le Drive.

### Tester sans rien casser

1. `--dry-run` d'abord, systématiquement.
2. Utiliser la ligne **`IdExec 40` (« TEST »)**, prévue pour ça.
3. Pour viser la base de test, surcharger la config sans modifier le
   classeur :
   ```powershell
   $env:CAPAPPRO_CONFIG_ORACLE_FINANCE_BASE_URL = "etiscandb03.eti.dalkia.net"
   $env:CAPAPPRO_CONFIG_ORACLE_FINANCE_BASE_SERVICE_NAME = "ebs_PDBFINI2"
   ```
   Passer la ligne du classeur en `config_oracle_test` fonctionne aussi, mais
   l'upload du log échouera : cette configuration n'a pas de ligne dans
   l'onglet `data` (voir §7).
4. Pour ne pas écrire sur le Drive du projet, changer temporairement
   `UploadDossier_drive_id` sur une copie locale du classeur et lancer avec
   `--local`.

---

## 6. Lire la sortie

Chaque ligne du fichier lanceur est encadrée par deux marqueurs horodatés,
émis **en direct** — le marqueur de fin apparaît même si la ligne part en
erreur :

```
16:49:34 [INFO] >>> DEBUT  [1/2] EXPORT :: 01_ctrl_Lionel.sql
    | Lancement requête :: [ 1 / 2 ] - Requête  01_ctrl_Lionel.sql
    | Temps Exécution requete : [ 00:00:03 ]
16:49:41 [INFO] <<< FIN    [1/2] EXPORT :: 01_ctrl_Lionel.sql | statut=OK | duree=00:00:07
```

Les lignes préfixées `    | ` viennent du worker et sont relayées au fil de
l'eau. Si rien ne s'affiche pendant plusieurs minutes, le traitement est
réellement bloqué — ce n'est plus un effet de bufferisation.

Le worker écrit en parallèle un fichier `.log` dans
`BASE_DOWNLOAD_FOLDER\<date>\<Projet>_<horodatage>.log`.

---

## 7. Problèmes courants

| Symptôme | Cause | Correctif |
|---|---|---|
| `Fichier de configuration introuvable` | `.ini` absent à côté du script | vérifier le dossier, ou définir `CAPAPPRO_CONFIG` |
| `Lecture du Drive impossible (No module named 'gdrive')` | librairies maison absentes | normal sur un poste de dev : le repli local prend la main, ou utiliser `--local` |
| `Aucune copie locale configurée` | `SOURCE=drive` en échec **et** `FICHIER_ORDONNANCEUR` vide | renseigner une copie locale du classeur |
| `IdExec introuvable(s)` | mauvais identifiant | `--list` pour voir les valeurs valides |
| `Colonnes absentes du fichier d'ordonnancement` | classeur renommé ou modifié | les intitulés sont un contrat métier, ne pas les corriger sans coordination |
| `Section de base de données absente : [config_cid_celeris]` | `configBDD` du classeur sans section correspondante dans le `.ini` | ajouter la section, ou corriger la ligne du classeur |
| `DPI-1047` / erreur `init_oracle_client` | client Oracle absent ou mauvais chemin | corriger `[paths] ORACLE_CLIENT_HOME` |
| `Impossible de récupérer le drive de la configuration utilisée` en fin de run | la `configBDD` n'a pas de ligne dans l'onglet `data` — c'est le cas de `config_oracle_test` | sans effet sur l'extraction : seul l'upload du log échoue |
| Le traitement dépasse le temps prévu et s'arrête | timeout de 4 h atteint | ajuster `[execution] TIMEOUT_PROJET_SECONDES` (`0` = illimité) |

---

## 8. Comment le classeur pilote l'exécution

```
Classeur d'ordonnancement (Drive) — onglet Feuil1
        │  une ligne = un projet, repérée par IdExec
        ▼
CapAppro_LOCAL.py  ──►  9 arguments  ──►  CapAppro_GENERIQUE_EXECUTION.py
                                                    │
                                                    ▼
                          Classeur lanceur du projet (filenameLanceur),
                          sur le Drive DownloadDossier_drive_id
                                                    │
                          une ligne = une requête :
                            Type = Script  →  sqlplus (procédure PL/SQL)
                            Type = Export  →  SELECT → .csv / .xlsx
                                                    │
                                                    ▼
                          Upload Drive + DataViz + mail + HistoExec
```

Retenir : `IdExec` désigne un **projet**, pas une requête. Un projet exécute
autant de requêtes que son classeur lanceur en contient de lignes marquées
`Exécution = oui`.

---

## 9. Limites connues

Elles sont documentées en détail dans [PROMPT_CONTEXTE.md](PROMPT_CONTEXTE.md).
Les plus utiles à connaître en local :

- les mots de passe sont encore en clair dans le `.ini` (la surcharge par
  variable d'environnement est disponible mais pas encore la norme) ;
- l'écriture XLSX est lente sur les gros volumes : ~7 min pour 47 Mo, contre
  13 s d'upload. Un export qui « ne rend pas la main » est souvent en train
  d'écrire son fichier ;
- `saveToExcel` trace ses erreurs sans les propager : un export peut être
  compté `OK` alors que le fichier n'a pas été écrit ;
- les `;` sont retirés de tout le SQL, y compris à l'intérieur des chaînes.
