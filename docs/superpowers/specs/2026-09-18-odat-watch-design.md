# ODAT Watch – Design

Date : 2026-09-18

## Objectif

Accumuler chaque jour les photos Control-M (fichiers ODAT `Report_ctm_*.csv`, 4 à 5 par jour : 7h05, 7h40, 8h06, 13h45, 16h45) et les demandes Oracle R12 (`FND_CONCURRENT_REQUESTS`) sur 3 à 4 mois, puis répondre via une interface web locale à la question : **qu'est-ce qui tourne ce soir et demain pour FIN-FINANCE ?**

## Sources

1. **ODAT Control-M** : CSV `;`, colonnes Application, Group Name, Job Name, Odate, Start Time, End Time, Run Time, Status, Description, Member Name, Task Type, Deleted, Rerun Counter, Cyclic, CONTROL-M Name, Table, Run as User, Hostname, Nodegroup, Order id. Statuts : Ended OK, Ended Not OK, Executing, Wait for Event.
2. **Oracle R12** : `FND_CONCURRENT_REQUESTS` joint à `FND_CONCURRENT_PROGRAMS_TL`, `FND_USER`. Requêtes des 48 dernières heures + toutes les demandes `PHASE_CODE = 'P'` (Pending, planifiées). Connexion via `config.ini` (user, password, dsn), même format que `controleNuit`.
3. **Mapping** job Control-M → programme concurrent : table éditable `mapping_jobs.csv`, initialisée à partir de `ChaineControleM/Inventaire_Jobs_FINFIN.sql` et des Member Name (`DKA_XXX_JOB.sh` → `DKA_XXX`).

## Stockage

- `ODAT/archive/YYYY/MM/DD/HHMM.csv` : copie brute de chaque fichier reçu. L'heure de photo = mtime du fichier.
- `odat_watch/odat.db` (SQLite) :
  - `snapshots(id, odate, snap_time, source_file)`
  - `ctm_jobs(snapshot_id, application, group_name, job_name, odate, start_time, end_time, run_time, status, description, member, task_type, rerun, cyclic, order_id, ...)` — clé unique (snapshot_id, order_id, rerun, start_time).
  - `ora_requests(request_id, program_short, program_name, phase, status, requested_start, actual_start, actual_completion, requestor, parent_id, resubmit, refreshed_at)`.
  - `job_mapping(job_name, program_short)`.
- Export Oracle optionnel : script générant DDL + INSERT pour le schéma de l'utilisateur.

## Moteur de prévision

Pour chaque job FIN (et chaque programme Oracle) : jours d'exécution (quotidien / jours de semaine / jour du mois), heure de démarrage médiane, durée médiane, taux OK sur 90 j. Prévision pour une plage (ce soir 17h→6h, demain 0h→24h) = jobs dont le profil prévoit une exécution dans la plage, enrichis par : état dans la dernière photo Control-M, demandes Oracle Pending/Running correspondantes. Réconciliation : vert (3 sources concordent), orange (source manquante), rouge (erreur ou écart).

## Interface (Streamlit)

- **Ce soir** : timeline 17h→6h, jobs attendus, heure prévue, durée, description, programme Oracle, fiabilité, état temps réel.
- **Demain** : idem sur la journée suivante, jobs hebdo/mensuels mis en avant.
- **Maintenant** : dernière photo, incidents Not OK, retards vs profil, reruns, Executing trop longs, écarts Control-M / Oracle.
- **Historique** : recherche job/description, 90 derniers passages, courbes heures de fin et durées.
- Boutons : « Importer nouveaux ODAT », « Rafraîchir Oracle ».

## Ingestion

`ingest.py` scanne `ODAT/` et `%USERPROFILE%\Downloads` pour `Report_ctm_*.csv`, archive, charge, ignore les doublons (hash du fichier). `refresh_oracle.py` extrait FND. Tâche planifiée Windows possible.

## Étapes

1. Ingestion ODAT → SQLite + archive. 2. Extraction Oracle + mapping. 3. Profils et prévisions. 4. Streamlit. 5. Planification.

## Hors périmètre v1

Autres applications que FIN-FINANCE dans les prévisions (les données sont chargées pour toutes, l'interface filtre FIN par défaut). Écriture dans Oracle.
