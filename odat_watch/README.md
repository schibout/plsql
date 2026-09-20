# ODAT Watch

Exploitation des photos Control-M (fichiers ODAT `Report_ctm_*.csv`) et des demandes concurrentes
Oracle EBS R12 pour répondre à : **qu'est-ce qui tourne ce soir, et demain ?** puis
**pourquoi ça a planté ?** (FIN-FINANCE par défaut, toutes applications disponibles).

## Contenu

| Fichier | Rôle |
|---|---|
| `ingest.py` | Scanne `../ODAT` (dont `Report_CTM/`, dépôt Control-M horodaté `AAAAMMJJ_HHMMSS_Report_ctm_*.csv`), `~/Downloads` et les dossiers ajoutés dans « Sources d'import », archive chaque CSV dans `../ODAT/archive/AAAA/MM/JJ/HHMM_odate_*.csv`, charge dans `odat.db` (SQLite). Doublons ignorés (hash du fichier). |
| `forecast.py` | Profils par job Control-M (heure médiane, durée, jours, fiabilité), prévisions ce soir / demain, anomalies. |
| `ui_preproduction.py` | Onglet « Préparer ma nuit » : prévision d'une plage libre, suivi sur dernière photo et bilan, y compris hors clôture. |
| `ui_calendriers.py` / `calendar_import.py` | Import contrôlé des classeurs trimestriels de clôture (.xlsx), aperçu des trois mois, versionnement et provenance. |
| `assistant_nuit.py` | Questions guidées sur le plan affiché, sans transfert vers un service d'IA externe. |
| `oracle_refresh.py` | **Brique Oracle Apps** : charge `FND_CONCURRENT_REQUESTS` et `FND_CONCURRENT_PROGRAMS` dans SQLite — tout l'historique utile la première fois (`jours_initial`, 90 j), puis seulement ce qui a été créé ou modifié depuis le dernier chargement (borne Oracle mémorisée dans `parametres`, `--complet` pour repartir de zéro). Lie chaque demande à son job Control-M (la DESCRIPTION des demandes du lanceur DKA_SLAUNCHER contient le nom du job ; les demandes filles héritent du parent). |
| `logs.py` | Analyse des `l<id>.req` / `o<id>.out` rapatriés du serveur EBS : compteurs, messages FND_FILE, codes d'erreur, diagnostic. Génère `list.txt` pour `copy_ebs_logs.sh`. |
| `diagnostics.json` | Dictionnaire code d'erreur → explication, action, gravité. **À enrichir au fil des incidents.** |
| `ui_oracle.py` | Onglet Oracle de l'interface. |
| `controle_matin.py` | **Contrôle du matin** : portage `oracledb` des 15 contrôles de `ControleMatinGenerique/Controle_Quotidien_Complet.sql` (DSP, Notilus, factures Xerox/Tradeshift, GL, traitements de la nuit, RB) sur une plage date+heure libre. Calcule les statuts OK/W et le statut global, historise la synthèse dans `controle_matin_histo`. Aussi en ligne de commande (`--rapport`). Le `.sql` reste la référence : toute évolution métier se fait d'abord là, puis se reporte ici. |
| `rapport_matin.py` | Rapport HTML du contrôle du matin (charte des `Rapport_Verification_*.html`), écrit dans `rapports/` (ignoré par git). |
| `planif_matin.py` | Tâche du Planificateur Windows `ODATWatch_ControleMatin` (`schtasks`) qui lance `controle_matin.py --rapport` chaque matin. |
| `ui_matin.py` | Onglet Matin : plage date+heure, bandeau, tuiles avec écart vs. veille, détail par section, génération/téléchargement du rapport, programmation, tendance 30 jours. |
| `folio_rose.py` | **Folio Rose** : portage de `Verifier_Factures.ps1` (import des exports `ExportCSV-*.csv`, tables `fr_*`, groupes compensés, rapprochements, contrôle Oracle). |
| `rapport_folio_rose.py` | Rapport HTML Folio Rose (même charte que `rapport_matin.py`), écrit dans `rapports/`. |
| `ui_folio_rose.py` | Onglet Folio Rose : import, tableau avec sélection et somme des écarts en direct, rapprochements (manuels et groupes compensés), contrôle Oracle, rapport HTML, historique. |
| `releves_scan.py` | **Relevés bancaires — acquisition** : section `[releves]` de `config.ini`, lecture des fichiers AFB120 (CFONB 120 : relevés, mouvements, banques, dates, md5, flux A/B), scan des exécutions PFE (`<uuid>/SOURCE,TARGET,TALEND`) et des `AFB120.txt_*` reçus par EBS, parseurs des logs `RBAFBIMP` (synthèse des relevés, erreurs 001/025) et `DKA_SRBCTRLRB` (comptes en anomalie), comptes connus, chaîne Control-M `FINEXT_J14INT_05/06` lue dans les photos ODAT. Tables `rb_*`. |
| `releves.py` | **Relevés bancaires — métier** : verdict de la matinée par flux (frise PFE · Control-M · Reçu EBS · Import · Contrôle, causes), chronologie des imports, continuité par compte SG (retard, trou), plan de reprise ordonné, `list_releves.txt` des logs manquants, vues PFE ↔ EBS et contrôles. Ré-exporte les noms publics de `releves_scan.py`. |
| `rapport_releves.py` | Rapport HTML Relevés bancaires (même charte que `rapport_matin.py`), écrit dans `rapports/Releves_*.html`. |
| `ui_releves.py` | Onglet Relevés bancaires : date, scan, tuiles, frise A/B, plan de reprise, chronologie + mini-tendance, continuité, PFE ↔ EBS, Control-M, contrôles, comptes connus éditables, rapport HTML. |
| `sources.py` | Dossiers d'import choisis par l'utilisateur (boîte de dialogue Windows ou chemin collé), mémorisés dans la table `parametres` d'`odat.db`. |
| `virements.py` / `ui_virements.py` | **Virements** : onglet pont vers `../controleVirement` (choix de la journée parmi les dossiers `*_cible`, lancement de `controle_virements.executer`, tuiles, doublons D1-D6, contrôles de forme, niveaux 0-3, synthèse). Config `[virements]`. |
| `referentiel.py` / `ui_profils.py` | **Profils + référentiel** : profil calculé de chaque job (onglet Profils) enrichi du référentiel jobs Control-M ↔ programmes Oracle Applications : alimenté automatiquement (photos ODAT + demandes Oracle : lanceur, filles, script `DKA_X_JOB.sh`), corrigeable à la main (saisie prioritaire partout), export CSV. Table `referentiel_jobs`. |
| `ui_sql.py` | Onglet SQL : explorateur des tables SQLite (structure, volumes) et requêteur libre en lecture seule, exemples fournis, export CSV. |
| `mock_oracle.py` | **Poste sans Oracle** : fabrique des demandes simulées à partir des exécutions Control-M (lanceur + programme métier, statuts alignés) et des logs présents. `python mock_oracle.py --reset`. Écrasé par les vraies données au premier `oracle_refresh.py`. |
| `app.py` | Interface Streamlit : Ce soir, Demain, Maintenant, Matin, Relevés bancaires, Folio Rose, Virements, Oracle, Historique, Profils (avec référentiel), Données, SQL. |
| `.streamlit/config.toml` | Thème de l'interface. |
| `run.bat` | Import ODAT + lancement de l'interface. |
| `config.ini.exemple` | Modèle de configuration (Oracle, filtres, dossiers de logs, section `[releves]`). Copier en `config.ini` (ignoré par git). |

## Installation (une fois)

Python 3.11+ avec `streamlit`, `pandas`, `plotly`, `oracledb`. Le Python du Microsoft Store échoue
sur les chemins longs : créer un venv dans un chemin court.

```bat
python -m venv C:\tmp\odatenv
C:\tmp\odatenv\Scripts\python.exe -m pip install streamlit pandas plotly oracledb
copy config.ini.exemple config.ini      REM puis renseigner user / password / dsn
```

## Utilisation

1. Déposer les fichiers ODAT reçus dans `../ODAT` (ou les laisser dans Téléchargements), ou ajouter
   son propre dossier dans la barre latérale (« 📂 Sources d'import » → « Parcourir… »). Fichiers `Report_ctm_*.csv`
   uniquement : dézipper les archives reçues par mail.
2. Double-cliquer `run.bat` : import des nouveaux fichiers, ouverture du navigateur.
3. Barre latérale : « Importer les nouveaux fichiers ODAT », « Demandes » (Oracle 48 h), « Programmes »
   (référentiel, une fois par semaine suffit), « Analyser les logs ».
4. Onglet **Préparer ma nuit** : choisir une date, une plage horaire et le mode Préparer / Suivre / Bilan.
   Le suivi indique la fraîcheur de la dernière photo importée ; ce n'est pas une supervision Control-M en temps réel.
5. Onglet **Clôtures** : déposer un fichier trimestriel `.xlsx` constitué de trois feuilles mensuelles,
   vérifier l'aperçu puis cliquer « Enregistrer et activer ce calendrier ». Une version antérieure reste consultable.

En ligne de commande :

```bat
python oracle_refresh.py --test          REM teste la connexion
python oracle_refresh.py --programmes    REM référentiel + demandes
python oracle_refresh.py --complet       REM refait le chargement initial (jours_initial)
python oracle_refresh.py --jours 7       REM fenêtre explicite, sans toucher la borne du delta
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

## Contrôle du matin

Onglet **☀️ Matin** : choisir la plage de nuit (défaut hier 19:00 → aujourd'hui 07:00 ; modifiable pour rejouer un
matin passé), « ▶ Lancer le contrôle » exécute les mêmes requêtes que `ControleMatinGenerique\Lancer_Controle_Quotidien.ps1`,
puis « 📄 Générer le rapport HTML » produit `rapports\Controle_Matin_AAAAMMJJ_HHMM.html` à joindre au mail.
« ⏰ Programmer » crée une tâche Windows quotidienne (`schtasks`) qui fait la même chose sans ouvrir l'application.
Les compteurs de la synthèse sont historisés dans `controle_matin_histo` (tuiles : écart vs. veille, tendance 30 j).

En ligne de commande : `python controle_matin.py [--debut "AAAA-MM-JJ HH:MM"] [--fin "..."] [--histo 3] [--rapport]`.

Tests : `PYTHONIOENCODING=utf-8 python -m pytest tests -q` (sans Oracle) — 42 tests, dont 5 tests d'interface
AppTest. Validation métier : lancer l'onglet et le `.ps1` le même matin, les compteurs de la « SYNTHESE DU JOUR »
doivent coïncider.

Validation Oracle en attente : à faire sur le poste Dalkia (le serveur n'est pas joignable depuis le poste de
développement). Les requêtes ont été vérifiées ligne à ligne contre le `.sql` ; la première exécution réelle doit
être comparée au log du `.ps1` du même matin.

Jours sans intégration : si la veille contrôlée (date de « Début de nuit ») est un samedi, un dimanche ou un jour
férié français (fériés calculés, Pâques inclus), les volumes (flux DSP, notes de frais, factures, GL, imports RB)
passent en **N/A** et ne pèsent pas dans le statut global : seuls les traitements de la nuit (erreurs, warnings,
en cours) et les images Xerox manquantes comptent. Case « Contrôler les volumes malgré tout » (ou `--volumes` en
ligne de commande) pour forcer. Le lundi, pour contrôler tout le week-end, mettre « Début de nuit » au vendredi 19:00.
Le rappel « fichier SG » s'affiche chaque lundi. Les tuiles de synthèse sont cliquables : elles ouvrent la section
de détail correspondante.

## 🏦 Relevés bancaires

Suit chaque matinée la chaîne PFE → Control-M (`FINEXT_J14INT_05_Q` flux A multi-banques ~07:50,
`FINEXT_J14INT_06_Q` flux B Société Générale ~08:20, chaîne cyclique) → EBS (`RBAFBIMP` puis `DKA_SRBCTRLRB`).
Le flux d'un fichier est déduit de ses banques : B = uniquement la banque `banque_flux_b` (30003), A = tout le reste
(les fichiers A contiennent aussi quelques comptes SG).

Sources locales (section `[releves]` de `config.ini`, valeurs par défaut vers `..\ControleReleveBancaire`) :
- `dossier_pfe` : un sous-dossier `<uuid>` par exécution Talend (`SOURCE/`, `TARGET/compt_AFB120_*.txt` +
  `compteur_*.zip`, `TALEND/LS_IN.OK`) ; une exécution est « complète » si les quatre sont présents (SOURCE, TARGET,
  zip, LS_IN.OK) et que le zip contient le TARGET ;
- `dossier_ebs` : les `AFB120.txt_<AAAAMMJJHHMMSS>` reçus par EBS (`data/traite`, suffixe libre toléré) ;
- `dossiers_logs` : les `l<id>.req` / `o<id>.out` des imports et contrôles, rapatriés avec `copy_ebs_logs.sh` à
  partir du `list_releves.txt` généré par « 📋 list_releves.txt des logs manquants » (demandes Oracle chargées sans `.out` local).
  Un log dont seul le `.req` est présent est chargé puis complété au scan suivant quand le `.out` arrive.

Deux modules : `releves_scan.py` (lecture et chargement dans les tables `rb_*`) et `releves.py` (verdict, continuité,
reprise). « 🔄 Scanner » relit les dossiers (ce qui est déjà en base est ignoré), rapproche PFE ↔ EBS par md5 et
relie chaque import au fichier EBS reçu dans la même minute (ou les 3 minutes précédentes, même flux de préférence).
L'onglet affiche ensuite :
- les tuiles (verdict du jour, flux A, flux B, comptes en rupture, fichiers à rejouer) ;
- la **frise de la matinée** par flux — PFE · Control-M · Reçu EBS · Import · Contrôle — avec verdict `OK` / `WARN` /
  `KO` / `—` et causes en français (fichier PFE non reçu, conflit `06_MOV01` / `05_MOV01`, `06_ZIP01` Ended Not OK,
  import rejeté en bloc en `Erreur 025` « journée manquante », `.out` absent, contrôle non vide hors comptes connus).
  Pour le flux A, les comptes SG listés par un contrôle lancé avant le flux B ne comptent pas ;
- le **plan de reprise** quand la continuité est rompue : fichiers à rejouer dans l'ordre (TARGET PFE non reçus, puis
  fichiers EBS rejetés ou jamais importés), période couverte et résultat attendu (`207 chargés / 6 erreurs` = relevés
  moins les comptes connus en erreur chaque jour) ;
- la chronologie des imports sur 15 jours avec une mini-tendance (relevés chargés en vert, en erreur en rouge) ;
- la continuité par compte SG (dernier relevé chargé, date attendue, retard, trou = rejet 025 postérieur au dernier
  chargement), le rapprochement PFE ↔ EBS, la chaîne Control-M de la matinée (dernière photo ODAT prise ce jour-là ;
  une photo de la veille au soir n'est pas utilisée), les contrôles `DKA_SRBCTRLRB` avec le détail des lignes ;
- les **comptes connus** (anomalies préexistantes, `banque/guichet/compte`) : initialisés depuis `config.ini`, éditables
  dans l'onglet, ignorés par le verdict ; l'enregistrement recalcule aussitôt les anomalies « hors comptes connus »
  des contrôles déjà chargés. Les comptes en rupture (tuile, continuité du rapport) excluent les comptes connus.

« 📄 Rapport HTML » écrit `rapports/Releves_AAAAMMJJ_HHMM.html` (frise, chronologie, continuité, plan, PFE ↔ EBS,
contrôles). Samedi, dimanche et jours fériés : aucune intégration attendue pour un flux qui n'a rien produit (verdict
`—`, pas d'alerte) ; le samedi le flux A tourne normalement.

Tests : `tests/test_releves_*.py`, `test_rapport_releves.py`, `test_ui_releves.py` (AppTest), tous sur les fichiers réels
de `ControleReleveBancaire/` (incident des 15–18/09/2026 : flux B non reçu deux jours puis rejet `Erreur 025`).

## Folio Rose

Clé métier d'une ligne : **folio + date + nom de fichier transmis**. Un nouvel export met à jour les lignes
existantes (montants, commentaire) et ajoute les inédites ; une ligne de la période couverte qui a disparu est
marquée « disparue » (masquée par défaut, jamais supprimée). Les rapprochements sont attachés à cette clé et
survivent aux mises à jour. Le tableau montre l'état courant ; les exports importés forment l'historique.

Onglet **🌹 Folio Rose** : portage de `Verifier_Factures.ps1`. Déposer un ou plusieurs
`ExportCSV-*.csv` par glisser-déposer, ou importer d'un coup le dossier `ControleFolioRose` (et son
sous-dossier `sauvegarde`) ; les fichiers déjà importés (même hash) sont ignorés. Le tableau se filtre par
type, statut et folio ; cocher des lignes affiche la somme de leurs écarts débit en direct, et à 0 (au moins
deux lignes) propose « 🔗 Rapprocher ces lignes ». Les groupes folio + fichier dont la somme des écarts fait
déjà 0 sont listés à part (« Groupes compensés en attente ») avec un rapprochement à l'unité ou « Tout
rapprocher ». « 🅾 Contrôler dans Oracle » interroge Oracle par couple (folio, fichier de base, type) et
mémorise nombre/montant côté Oracle, avec l'erreur affichée en clair (colonne « Erreur Oracle ») quand la
requête échoue. « 📄 Générer le rapport HTML » produit `rapports/Folio_Rose_AAAAMMJJ_HHMM.html` (même charte
que le rapport du matin). Les rapprochements sont historisés (annulables) et les données vivent dans les
tables `fr_lignes`, `fr_oracle`, `fr_rapprochements`, `fr_rapprochement_lignes`.

`Verifier_Factures.ps1` reste utilisable en parallèle (aucune dépendance vers l'onglet).

Tests : `folio_rose.py` et `rapport_folio_rose.py` sont couverts unitairement, `ui_folio_rose.py` par AppTest
(import, sélection/somme via `folio_rose.somme_selection`, rapprochement de groupe) — inclus dans les 92 tests
de `pytest tests -q`.

Validation Oracle en attente : à faire sur le poste Dalkia. Vérifier notamment le schéma propriétaire de
`DKA_IARPAFAC_INTERFACE`, référencée sans préfixe dans le `.ps1` mais préfixée `APPS.` ici si
`schema = APPS` dans `config.ini`.
