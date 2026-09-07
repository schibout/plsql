# PROMPT — Lanceur Centralisé CapAppro (Dalkia / Team RPA)

Tu interviens sur une chaîne RPA Python d'extraction de données Oracle EBS,
pilotée par un Google Sheet et ordonnancée par Rundeck. Ce document contient le
contexte complet, les contrats de données réels, trois exécutions observées,
les statistiques de production, l'état des lieux et le backlog technique.
Utilise-le comme base pour toute demande d'évolution, de correction ou de
refactoring sur ce projet.

---

## 1. CONTEXTE FONCTIONNEL

Chaîne RPA d'extraction de données Oracle EBS pilotée par Google Sheets.
Un ordonnanceur central lit un Google Sheet, et pour chaque « projet » activé,
lance un sous-processus qui télécharge des fichiers SQL depuis Google Drive,
les exécute sur Oracle, produit des CSV/XLSX, les remonte sur Drive et/ou
un partage DataViz, envoie des mails et journalise l'exécution dans le Sheet.

**Échelle réelle : 28 projets actifs, ~1 000 exécutions par trimestre,
2,5 ans d'historique (5 050 exécutions depuis février 2024).**

## 2. ARCHITECTURE (2 niveaux)

### Niveau 1 — `CapAppro_CENTRAL.py` (302 lignes) : L'ORDONNANCEUR
- Lit le Google Sheet central (spreadsheet_id `1QNJUUM8lJcHkVOQTNguInGvmI5xZX69EwUqxYL0al1Q`,
  onglet `Feuil1`, dossier Drive `1bkXK77bOQb8TXG69y_n_Qw9zM-Wru1BO`) via la lib maison
  `gdrive` (token "générique").
- Filtre les lignes `Exécution == "oui"` ; filtre optionnel sur `IdExec` via la
  variable d'environnement `RD_OPTION_IDEXEC` (injectée par Rundeck, liste séparée
  par des virgules — en pratique toujours un seul id).
- Valide les champs obligatoires (contrôle NaN), construit une ligne de commande :
  `py "CapAppro_GENERIQUE_EXECUTION.py" --idExec ... --ProjectName ... --configBDD ...`
- Exécute chaque projet **séquentiellement** via `Popen`, agrège les erreurs dans
  `errorMessage`, envoie un mail d'incident à `dsin-rpa-robot1@dalkia.fr`,
  et `raise` en fin de script si échec (code retour ≠ 0 pour Rundeck).

### Niveau 2 — `CapAppro_GENERIQUE_EXECUTION.py` (1130 lignes) : LE WORKER (1 projet)
- Parse les arguments avec `fire` (fonction `funcParams`), puis **tout le reste du
  script s'exécute au niveau module**, hors de `if __name__ == '__main__'`.
- Lit `config_lanceur_central.ini` → identifiants et instance Oracle.
- Connexion Oracle via `cx_Oracle` + SQLAlchemy (client Oracle 12.2 local).
  Une branche `SQLSERVER` (pyodbc) est prévue mais non finalisée.
- Télécharge depuis le Drive du projet le fichier Excel « lanceur » (cf. §3.2),
  vérifie que tous les `.sql` référencés existent sur le Drive (mail si manquants),
  les télécharge, retire les `;`.
- Type `script` → génère un `.bat` :
  `sqlplus.exe user/pwd@host:port/service @fichier.sql > sortie.txt`
  puis cherche « Procédure PL/SQL terminée avec succès » / « PL/SQL procedure
  successfully completed » dans la sortie texte.
- Type `export` → `pd.read_sql(query, engine)`, export CSV (séparateur `;`,
  `utf-8-sig`, QUOTE_NONNUMERIC) ou XLSX (xlsxwriter), horodatage optionnel du
  nom de sortie.
- Upload Drive (3 tentatives) et/ou copie vers un chemin DataViz (`copiedataviz`).
- Mails : récapitulatif HTML (tableau des statuts par requête), fichiers manquants,
  date d'expiration dépassée.
- Écrit une ligne dans l'onglet `HistoExec` + hyperlien `=LIEN_HYPERTEXTE(...)`
  vers le dossier Drive des logs.

---

## 3. CONTRATS DE DONNÉES (relevés sur les fichiers réels)

### 3.1 — Google Sheet central `OrdonnanceurCentral`
Onglets : `Feuil1` (pilotage), `HistoExec` (journal), `data` (config→drive),
`FeuillRequête_Modèle` (gabarit), + un TCD et une feuille de travail.

**`Feuil1` — 29 lignes × 12 colonnes** (28 actives, 1 désactivée) :

| Colonne | Lue par le code | Remarque |
|---|---|---|
| `IdExec` | ✅ obligatoire | clé, castée en `int` |
| `ProjectName` | ✅ obligatoire | |
| `Exécution` | ✅ obligatoire | `oui`/`non` |
| `DownloadDossier_drive_id` | ✅ obligatoire | Drive source (SQL + Excel lanceur) |
| `filenameLanceur` | ✅ obligatoire | nom du fichier Excel lanceur |
| `config` | ✅ obligatoire | **une seule valeur en prod : `config_oracle_finance`** |
| `UploadDossier_drive_id` | ⭕ optionnel | souvent identique au Drive de download |
| `Copiedataviz` | ⭕ optionnel | **1 seul projet actif l'utilise** (`\\ftp.dtz.prod.aws.local\dataviz16`) |
| `ListeDeDiffusion` | ⭕ optionnel | mails séparés par `,` |
| `Date_expiration_requête` | ⭕ optionnel | **10 projets actifs ont une date expirée (31/12/2025)** |
| `commentaires` | ❌ ignorée | porte la fréquence réelle (« tous les 1er du mois à 7h00 ») |
| `Lancement` | ❌ ignorée | entièrement vide |

**`data` — 2 lignes × 3 colonnes** (`configBDD`, `exécution`, `driveLogs`) :
- `config_oracle_finance` → `1_cZoOJbE5swtIxiHFda7WOTkhz258KiM`
- `config_cid_celeris` → *« indiquer le driveCID de dépôt des logs »* (placeholder, `non`)
- ⚠ **Aucune ligne pour `config_oracle_test`** alors que la section existe dans le `.ini`
- ⚠ **Aucune section `.ini` pour `config_cid_celeris`** alors que la ligne existe ici

**`HistoExec` — 5 050 lignes × 6 colonnes**
(`IdExec`, `ProjectName`, `exec`, `temps exec global`, `statutExec`, `logFileName`),
alimenté en append par le worker.

### 3.2 — Fichier Excel lanceur (par projet, sur le Drive du projet)
Exemple : `EXTRACTIONS_AUTOMATISEES_ORACLE.xlsx`, onglets `Extraction Oracle` + `Modifications`.
⚠ **Le même nom de fichier désigne des contenus différents selon le Drive du projet** —
c'est une convention de nommage, pas un fichier unique.

23 lignes × **15 colonnes, dont 5 seulement sont lues** (`usecols` strict) :

| Colonne | Lue | Rôle |
|---|---|---|
| `Nom rêquete` | ✅ | nom du `.sql` sur le Drive (⚠ typo `rêquete` figée) |
| `Type rêquete` | ✅ | `Script` (PL/SQL via sqlplus) ou `Export` (SELECT → fichier) |
| `Exécution` | ✅ | `oui`/`non` |
| `Nom fichier sortie` | ✅ | extension pilote le format (`.csv` / `.xlsx`) |
| `formatHorodatage` | ✅ | ex. `DDMMYYYY` → `Factures_payees_J-1_04092026.csv` |
| `1` (en-tête numérique) | ❌ | description libre de la requête |
| `Paramètres` | ❌ | **jamais implémenté** alors que les descriptions disent « depuis la date en paramètre » |
| `Date expiration requête` | ❌ | expiration *par requête* ignorée (seule celle du projet est traitée) |
| `Format fichier sortie` | ❌ | documentation (`csv avec entête, séparateur ";"`) |
| `Répertoire fichier sortie` | ❌ | documentation (`CAP APPRO DATA`) |
| `Fréquence execution` | ❌ | documentation (`Chaque dimanche`) |
| `Mode execution`, `Condition exection`, 2 × `Unnamed` | ❌ | vides ou notes |

---

## 4. ENVIRONNEMENT D'EXÉCUTION

- Windows, **Python 3.7.9** (EOL — confirmé par les `FutureWarning` google-cloud),
  exécuté sous le compte utilisateur `ddebarros`.
- Déploiement : `C:\RPA\CapAppro\04-TestCentral\Scripts\`
- Libs maison : `C:\RPA\python-libraries\` → `gdrive`, `pylibrary` (libraries), `gmail` (Mail)
- Client Oracle : `C:\app\product\12.2.0\client_1`
- Dossiers temporaires : `C:\RPA\CapAppro\04-TestCentral\downloadFolder\<YYYY-MM-DD>\<tmpXXXX>\`
  avec sous-dossiers `batProcedure\`, `extractFiles\`, `requetes\`
- Ordonnancement : **Rundeck**, un job par projet (option `IDEXEC` → `RD_OPTION_IDEXEC`).
  Le job est **multi-étapes** : étape 1 = ce lanceur Python, étape 2 = une tâche
  Robot Framework (`C:\uft\mail-export-drive`, suite « Export-Drive-Envoi-Mail-From-Sheet »).
  Un garde calendaire précède parfois l'étape 1 (« On continue l'exécution pour la suite »).
- Format des logs Rundeck : `HH:MM:SS [user@host étape][NIVEAU] message`
- Dépendances : pandas, cx_Oracle, sqlalchemy, fire, openpyxl, xlsxwriter,
  python-magic, python-dateutil, numpy

---

## 5. EXÉCUTIONS RÉELLES OBSERVÉES

### Exemple A — `Extraction_Lionel` (IdExec 39, 07/09/2026 09:20) — OK
```
--idExec "39" --ProjectName "Extraction_Lionel"
--DownloadDossier_drive_id "1L-5F_16qjMZ4Q-Qv7MfEdY3iA_N_LkjZ"
--filenameLanceur "Config_Export_ctrl_Lionel.xlsx"
--UploadDossier_drive_id "1L-5F_16qjMZ4Q-Qv7MfEdY3iA_N_LkjZ"
--ListeDeDiffusion "david.de-barros@dalkia.fr" --configBDD "config_oracle_finance"
```
2 exports (`01_ctrl_Lionel.sql` → `Export_01_ctrl_Lionel.xlsx`, idem 02).
Drive de download == Drive d'upload. Durée 21 s. `HistoExec` :
`[39, 'Extraction_Lionel', '07/09/2026 09:20:14', '00:00:21', 'OK', '…log']`

### Exemple B — `Reporting Cash prelevement auto` (IdExec 5, 02/09/2026 08:15) — OK
3 exports dont un de **47 MB**. Profil de temps :
**07:57 au total, dont 06:48 pour la seule écriture XLSX locale** et 13 s d'upload Drive.
→ Le goulot n'est ni Oracle ni le réseau, c'est `xlsxwriter`.
Durée totale du job : 12 min 29 (08:15:11 → 08:27:40).

### Exemple C — `Facture payees` (IdExec 21, 04/09/2026 08:30) — OK
1 export, chemin **horodatage** : `formatHorodatage = DDMMYYYY` →
`Factures_payees_J-1.csv` devient `Factures_payees_J-1_04092026.csv`.
L'upload logue `On créé un nouveau fichier avec le même nom` : les fichiers datés
s'empilent indéfiniment sur le Drive. Durée 33 s, dont ~30 s de latence Drive/init.

### Ce que ces logs prouvent
| Observation | Conclusion |
|---|---|
| `DB_PASSWORD = SupervisionDk` en clair, dans les 3 logs | les secrets fuient dans Rundeck, lisibles par tout opérateur |
| `Dimensions … '{filePath}'`, `nbRows={nbRows}`, `Upload … : {nomFichierSortie}`, `row_Index : {row_Index}` | f-strings oubliés — confirmé en prod |
| `Rentr�e dans la fonction main`, `requ�te` | mojibake : stdout UTF-8 décodé en `latin-1` par le central |
| `outputErr:` toujours vide, même sur 12 min de traitement | le double `communicate()` détruit systématiquement stderr |
| Tout le stdout à un **seul timestamp** après 12 min | `communicate()` bufferise : **aucune visibilité live**, un job bloqué est indétectable |
| `py ""C:\...\Scripts\\CapAppro_...py""` | guillemets doublés — passe par chance sous `cmd.exe` |
| Listing intégral du dossier Drive avant chaque `get_Element_id`/upload | la lib `gdrive` énumère tout le dossier à chaque appel : coût API O(n), ~900 lignes de bruit sur 954 dans le log C |
| Historique de logs remontant à juillet 2026 dans le listing | aucune purge du dossier `driveLogs` |

---

## 6. STATISTIQUES DE PRODUCTION (`HistoExec`, 5 050 exécutions, 02/2024 → 09/2026)

**Taux d'échec global : 18,4 % (931 KO / 5 050).
Sur les 3 derniers mois : 15,5 % (156 KO / 1 004).**
Le taux ne s'améliore pas avec le temps.

Projets les plus en échec (n ≥ 20 exécutions) :

| Projet | Exécutions | KO | % KO | Durée médiane | Durée max |
|---|---:|---:|---:|---:|---:|
| ExportOralceLaPosteImmo | 481 | 363 | **75 %** | 3 min 24 | 23 min |
| requetes audit interne | 57 | 42 | **74 %** | 37 min | 6 h 18 |
| Extractions Clôtures FRN | 40 | 24 | 60 % | 56 s | 40 min |
| Reporting Cash prelevement auto | 95 | 47 | 49 % | 38 s | **17 h 47** |
| Factures Bloquées | 104 | 45 | 43 % | 53 min | 2 h 40 |
| CapAppro histo | 34 | 13 | 38 % | 16 min | 4 h 31 |
| CapAppro hebdo | 208 | 61 | 29 % | 1 h 36 | 4 h 48 |
| Export Doublons Factures | 422 | 108 | 26 % | 23 s | 74 s |
| Etats du jour | 180 | 41 | 23 % | 33 min | 4 h 10 |
| Export Mathieu | 507 | 74 | 15 % | 54 min | **17 h 27** |

Lectures à retenir :
- **`ExportOralceLaPosteImmo` échoue 3 fois sur 4 depuis 481 exécutions** et reste
  actif dans `Feuil1` — l'alerting mail ne déclenche aucune action corrective.
  Le commentaire de `Extractions Clôtures FRN` dit d'ailleurs *« requête KO depuis
  upgrade Oracle »* : les pannes connues restent en production.
- Des exécutions de **17 h 47** confirment l'absence totale de timeout (défaut 11).
- L'écart médiane/max (38 s → 17 h) montre que les échecs sont surtout des
  **blocages**, pas des erreurs SQL immédiates.

---

## 7. ÉTAT DES LIEUX — DÉFAUTS IDENTIFIÉS

### 🔴 Critiques

1. **Secrets en clair — confirmé en production.** `config_lanceur_central.ini`
   contient les mots de passe Oracle en clair et versionnés dans git. Ils sont
   **imprimés dans les logs Rundeck** (~ligne 435) et **écrits sur disque dans les
   `.bat`** (`sqlplus.exe {DB_USER}/{DB_PASSWORD}@...`, ~ligne 263), jamais supprimés.

2. **`logging.ERROR(...)` au lieu de `logging.error(...)`** — lignes ~290 et ~295.
   `logging.ERROR` est une constante entière (40), pas une fonction → `TypeError`
   levé **à l'intérieur du handler d'erreur** de `lancementScriptProcedure`.
   Le message d'erreur réel des procédures PL/SQL est perdu.

3. **`Popen.communicate()` appelé deux fois** — `CapAppro_CENTRAL.py` l. 71-72.
   Le 2ᵉ appel renvoie vide → **stderr systématiquement perdu** (`outputErr:` vide
   dans les 3 logs) ; en cas d'exception `launchCmd` retourne `None`, traité comme
   erreur même si tout s'est bien passé.
   Correctif : `out, err = process.communicate()` en un seul appel.

4. **Aucune sortie temps réel + aucun timeout.** `communicate()` bufferise tout le
   stdout, et rien ne borne la durée. Conséquence mesurée : des exécutions de
   **17 h 47** (§6), invisibles pendant tout leur déroulement.
   Correctif : lecture ligne à ligne du flux + `timeout` sur `Popen` et sur les
   requêtes SQL.

5. **18 % d'échecs en production sans boucle de remédiation** (§6). Le mail
   d'incident part, mais aucun projet n'est désactivé ni corrigé — `ExportOralceLaPosteImmo`
   tourne à 75 % KO depuis 481 exécutions. Il manque un seuil d'alerte
   (« N échecs consécutifs → désactivation + escalade ») et un tableau de bord.

6. **Suppression aveugle des `;`** — ligne ~583, `replacetext(file, ";", "")` retire
   **tous** les points-virgules du SQL, y compris dans les littéraux (`', '`,
   `LISTAGG`, commentaires). Ne retirer que le `;` terminal via une regex ancrée.

7. **Mojibake systématique.** Le central décode le stdout du worker en `latin-1`
   alors que le worker écrit en UTF-8 → accents corrompus dans les logs Rundeck
   et dans les messages d'erreur remontés par mail. Correctif :
   `encoding="utf-8", errors="replace"` + `PYTHONIOENCODING=utf-8` côté enfant.

### 🟠 Robustesse

8. **Pas de `if __name__ == '__main__':` global** : ~950 lignes s'exécutent au niveau
   module. Script intestable, non importable. `fire.Fire()` sous `__main__` suivi de
   code global est fragile.

9. **`except Exception: pass` / `continue` omniprésents** : beaucoup de chemins
   n'alimentent pas `errorMessage` → exécutions « vertes » alors qu'un fichier n'a
   pas été produit.

10. **Variables potentiellement non définies** : `TYPE_BDD`, `now`, `dfRequests`,
    `requestName` utilisées en fin de script alors qu'une exception amont peut les
    laisser non définies → `NameError` masquant l'erreur d'origine.

11. **`time.sleep(3)` après `subprocess.run([batFile])`** : sqlplus est déjà
    synchrone. Et le **code retour de sqlplus n'est jamais vérifié** — on se fie à
    un `grep` de texte localisé FR/EN.

12. **Le worker ne remonte pas l'exécution en cas de crash précoce** : si la lecture
    du `.ini` ou la connexion Oracle échoue, `HistoExec` n'est pas alimenté.
    Aggravé par le fait que `config_oracle_test` n'a **aucune ligne dans `data`** :
    toute exécution sur l'environnement de test perd son upload de log.

13. **`copyFolder(download_folder, r"C:\Temp\debugOracle\\")`** en cas d'échec de
    script : dépose des `.bat` contenant les mots de passe, jamais nettoyé.

14. **Collision de la variable de boucle `i`** — ligne ~787, la boucle de retry
    `for i in range(0, 3)` réutilise le nom de l'index de la boucle principale.
    ⚠ **Piège latent, pas un bug actif** : les logs montrent que les exports suivants
    restent corrects (le `for` réassigne `i`, et rien ne relit `i` après le bloc
    d'upload). À renommer en `attempt` quand même.

15. **`copiedataviz` NaN non géré** : `if copiedataviz != "": copiedataviz[-1]`
    s'exécute **avant** le contrôle `is_NaN`. Inoffensif tant que la source est le
    Google Sheet (qui renvoie `""`), mais le chemin `pd.read_excel` — commenté dans
    le code, et c'est exactement le fichier `OrdonnanceurCentral.xlsx` fourni ici —
    renvoie `NaN`, et `NaN[-1]` lève `TypeError`, non rattrapé, qui tue tout le
    lanceur. 27 des 28 projets actifs sont concernés.

16. **Guillemets doublés dans la commande** : `scriptFolder` finit par `\\` et
    `launchCmd` réencadre une chaîne déjà entre guillemets → `py ""C:\...py""`.

### 🟡 Fonctionnalités documentées mais non implémentées

17. **Colonne `Paramètres` du fichier lanceur jamais lue**, alors que les
    descriptions annoncent « depuis la date en paramètre ». Les requêtes sont donc
    soit full, soit paramétrées en dur dans le `.sql`.
18. **`Date expiration requête` par requête ignorée** : seule l'expiration du
    *projet* est traitée. Et **10 des 28 projets actifs sont expirés depuis le
    31/12/2025** → ils envoient un mail d'expiration à chaque exécution, bruit qui
    noie les vraies alertes.
19. **`Fréquence execution`, `Mode execution`, `Condition exection`,
    `Répertoire fichier sortie`** documentées dans l'Excel mais pilotées ailleurs
    (Rundeck) ou nulle part → source de vérité ambiguë.
20. **Colonne `commentaires` de `Feuil1`** porte la fréquence réelle en texte libre :
    la planification n'est nulle part exploitable par machine.

### 🟡 Qualité / performance / maintenance

21. **Écriture XLSX = goulot d'étranglement** : 6 min 48 pour 47 MB via `xlsxwriter`
    (vs 13 s d'upload). Pour les gros volumes : CSV, `constant_memory=True`, ou
    écriture par blocs.
22. **Listing Drive intégral à chaque appel** (`get_Element_id`, `uploadFileToDrive`)
    → ~900 lignes de bruit sur 954 dans le log C, coût API O(n).
23. **Aucune purge** ni du dossier `driveLogs`, ni des fichiers de sortie horodatés.
24. **Code mort** : tout ce qui suit `sys.exit()` dans `CapAppro_CENTRAL.py` (l. 283-302).
25. **Fichiers `.bak` et `copy.py` versionnés**.
26. **f-strings oubliés** (l. ~53, 54, 60, 279, 783) → les tailles et dimensions des
    exports sont **impossibles à auditer** dans les logs.
27. **`getFileEncoding` copie vers `C:\Temp\temp.txt`** : chemin global non
    thread-safe, appelé à chaque lecture de fichier, et inutile.
28. **`shell=True` + concaténation** : injection possible via les valeurs du Sheet.
29. **Exécution séquentielle** des projets et des requêtes.
30. **Constantes dupliquées** (`spreadsheet_id`, `Dossier_drive_id`) dans les deux scripts.
31. **Section `[env] environnement=dev`** du `.ini` : morte. Et
    `config_cid_celeris` référencée dans `data` sans section `.ini` correspondante.
32. **Python 3.7.9 en fin de vie**.

---

## 8. BACKLOG PRIORISÉ

| Prio | Action | Défauts | Effort |
|------|--------|---------|--------|
| 1 | Fix `communicate()` double + encodage UTF-8 + `logging.ERROR` + f-strings | 2, 3, 7, 26 | 1 h |
| 2 | Sortir les secrets du `.ini`/git, masquer les logs, purger les `.bat` | 1, 13 | 0,5 j |
| 3 | Streaming du stdout worker + timeouts SQL et sous-processus | 4 | 0,5 j |
| 4 | **Traiter les 18 % de KO** : diagnostiquer `ExportOralceLaPosteImmo` (75 %) et `requetes audit interne` (74 %), désactiver ou corriger | 5 | 2-3 j |
| 5 | Nettoyer les 10 dates d'expiration périmées + le bruit d'alerte associé | 18 | 1 h |
| 6 | Nettoyage code : code mort, `.bak`, `copy.py`, `[env]`, `i`→`attempt`, garde NaN sur `copiedataviz` | 14, 15, 24, 25, 31 | 2 h |
| 7 | Perf export : CSV par défaut / `constant_memory`, cache du listing Drive, purge des logs et sorties | 21, 22, 23 | 1-2 j |
| 8 | Encapsuler le worker dans des fonctions + `main()`, vérifier le RC sqlplus | 8, 10, 11 | 2-3 j |
| 9 | `HistoExec` garanti même en crash précoce + ligne `data` pour `config_oracle_test` | 12 | 0,5 j |
| 10 | Implémenter `Paramètres` et l'expiration par requête, ou les retirer du contrat | 17, 18, 19 | à cadrer |
| 11 | Parallélisation + migration Python 3.11+ | 29, 32 | à cadrer |

---

## 9. CONTRAINTES À RESPECTER

- Ne **jamais** renommer les colonnes du Google Sheet ni du fichier Excel lanceur
  (`Nom rêquete`, `Type rêquete`, …) sans coordination : ce sont des contrats
  externes édités manuellement par les équipes métier, et `usecols` est strict —
  un accent modifié casse tous les projets d'un coup.
- Un même `filenameLanceur` (ex. `EXTRACTIONS_AUTOMATISEES_ORACLE.xlsx`) désigne
  des contenus **différents** selon le Drive du projet : ne pas raisonner sur un
  fichier unique.
- Le code retour du script central est consommé par Rundeck : conserver le
  `raise` / exit ≠ 0 en cas d'échec. Une étape Robot Framework s'exécute **après**
  celle-ci dans le même job — ne pas casser l'enchaînement.
- Les libs `gdrive`, `pylibrary`, `gmail` sont externes (`C:\RPA\python-libraries\`)
  et non modifiables depuis ce dépôt. Les défauts #22 et #27 les concernent :
  contourner côté appelant ou solliciter les mainteneurs.
- Environnement Windows uniquement (chemins, `.bat`, sqlplus, client Oracle),
  Python 3.7 : pas de `match`, pas de `dict | dict`, pas de types génériques natifs
  (`list[str]`).
