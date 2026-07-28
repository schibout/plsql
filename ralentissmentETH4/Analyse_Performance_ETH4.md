# 🔍 Analyse Performance Oracle EBS - Environnement ETH4

**Date de création** : 21 janvier 2026  
**Environnement** : ETH4 (Hors Production)  
**Base de données** : Oracle EBS 12.2.13 (Database 19c)  
**Objectif** : Diagnostic complet des ralentissements

---

## 📋 TABLE DES MATIÈRES

1. [Contrôles Rapides (Quick Health Check)](#1-contrôles-rapides)
2. [Analyse des Traitements Concurrents (Concurrent Requests)](#2-analyse-des-traitements-concurrents)
3. [Sessions Actives et Blocages](#3-sessions-actives-et-blocages)
4. [Statistiques et Gather Table Stats (GTS)](#4-statistiques-et-gather-table-stats)
5. [Analyse AWR/ASH](#5-analyse-awrash)
6. [Espace Disque et Tablespaces](#6-espace-disque-et-tablespaces)
7. [Alertes et Logs](#7-alertes-et-logs)
8. [Requêtes les Plus Coûteuses](#8-requêtes-les-plus-coûteuses)

---

## 1. CONTRÔLES RAPIDES

### 1.1 État Général de l'Instance

```sql
-- Vérifier l'état de l'instance Oracle
SELECT 
    instance_name,
    host_name,
    version,
    status,
    database_status,
    TO_CHAR(startup_time, 'DD/MM/YYYY HH24:MI:SS') AS startup_time,
    TRUNC(SYSDATE - startup_time) || ' jours' AS uptime
FROM v$instance;
```

### 1.2 Paramètres Critiques de Performance

```sql
-- Paramètres importants pour la performance
SELECT name, value, description
FROM v$parameter
WHERE name IN (
    'sga_target',
    'pga_aggregate_target',
    'memory_target',
    'db_cache_size',
    'shared_pool_size',
    'optimizer_mode',
    'cursor_sharing',
    'parallel_max_servers',
    'processes',
    'sessions',
    'undo_retention',
    'open_cursors'
)
ORDER BY name;
```

### 1.3 Hit Ratio Buffer Cache (doit être > 95%)

```sql
SELECT 
    ROUND((1 - (phy.value / (cur.value + con.value))) * 100, 2) AS buffer_cache_hit_ratio
FROM 
    v$sysstat cur,
    v$sysstat con,
    v$sysstat phy
WHERE 
    cur.name = 'db block gets'
    AND con.name = 'consistent gets'
    AND phy.name = 'physical reads';
```

### 1.4 Library Cache Hit Ratio (doit être > 99%)

```sql
SELECT 
    ROUND((1 - SUM(reloads) / SUM(pins)) * 100, 2) AS library_cache_hit_ratio
FROM v$librarycache;
```

---

## 2. ANALYSE DES TRAITEMENTS CONCURRENTS

### 2.1 🔴 Top 20 Traitements les Plus Lents (30 derniers jours)

```sql
SELECT * FROM (
    SELECT 
        fcp.user_concurrent_program_name AS "Programme",
        fcr.request_id AS "Request ID",
        TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI') AS "Début",
        TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI') AS "Fin",
        ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) AS "Durée (min)",
        ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24, 2) AS "Durée (heures)",
        DECODE(fcr.phase_code, 'C', 'Terminé', 'P', 'En attente', 'R', 'En cours', 'I', 'Inactif', fcr.phase_code) AS "Phase",
        DECODE(fcr.status_code, 'C', 'Normal', 'E', 'Erreur', 'G', 'Warning', 'R', 'En cours', 'W', 'En attente', fcr.status_code) AS "Statut",
        fu.user_name AS "Lancé par"
    FROM 
        apps.fnd_concurrent_requests fcr
        JOIN apps.fnd_concurrent_programs_vl fcp 
            ON fcr.concurrent_program_id = fcp.concurrent_program_id
            AND fcr.program_application_id = fcp.application_id
        LEFT JOIN apps.fnd_user fu ON fcr.requested_by = fu.user_id
    WHERE 
        fcr.actual_start_date >= SYSDATE - 30
        AND fcr.actual_completion_date IS NOT NULL
        AND (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60 > 5 -- Plus de 5 minutes
    ORDER BY (fcr.actual_completion_date - fcr.actual_start_date) DESC
)
WHERE ROWNUM <= 20;
```

### 2.2 Traitements Actuellement en Cours (Running)

```sql
SELECT 
    fcr.request_id AS "Request ID",
    fcp.user_concurrent_program_name AS "Programme",
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') AS "Démarré le",
    ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 0) AS "Durée (min)",
    ROUND((SYSDATE - fcr.actual_start_date) * 24, 2) AS "Durée (heures)",
    fcr.oracle_session_id AS "Session ID",
    fcr.oracle_process_id AS "Process ID",
    fu.user_name AS "Lancé par",
    fcr.argument_text AS "Arguments"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
        AND fcr.program_application_id = fcp.application_id
    LEFT JOIN apps.fnd_user fu ON fcr.requested_by = fu.user_id
WHERE 
    fcr.phase_code = 'R'
    AND fcr.status_code = 'R'
ORDER BY fcr.actual_start_date;
```

### 2.3 Traitements en Erreur (7 derniers jours)

```sql
SELECT 
    fcr.request_id AS "Request ID",
    fcp.user_concurrent_program_name AS "Programme",
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI') AS "Début",
    DECODE(fcr.status_code, 'E', 'Erreur', 'G', 'Warning', 'X', 'Terminé', fcr.status_code) AS "Statut",
    fcr.completion_text AS "Message",
    fu.user_name AS "Lancé par"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
        AND fcr.program_application_id = fcp.application_id
    LEFT JOIN apps.fnd_user fu ON fcr.requested_by = fu.user_id
WHERE 
    fcr.actual_start_date >= SYSDATE - 7
    AND fcr.status_code IN ('E', 'G', 'X')
ORDER BY fcr.actual_start_date DESC;
```

### 2.4 Traitements en Attente (Pending)

```sql
SELECT 
    fcr.request_id AS "Request ID",
    fcp.user_concurrent_program_name AS "Programme",
    TO_CHAR(fcr.request_date, 'DD/MM/YYYY HH24:MI:SS') AS "Soumis le",
    ROUND((SYSDATE - fcr.request_date) * 24 * 60, 0) AS "Attente (min)",
    DECODE(fcr.status_code, 'I', 'Normal', 'Q', 'Standby', 'A', 'En attente', fcr.status_code) AS "Statut",
    fu.user_name AS "Lancé par",
    fcr.hold_flag AS "En hold"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
        AND fcr.program_application_id = fcp.application_id
    LEFT JOIN apps.fnd_user fu ON fcr.requested_by = fu.user_id
WHERE 
    fcr.phase_code = 'P'
ORDER BY fcr.request_date;
```

### 2.5 Comparaison Durée Moyenne vs Dernière Exécution

```sql
SELECT 
    fcp.user_concurrent_program_name AS "Programme",
    COUNT(*) AS "Nb Exécutions",
    ROUND(AVG((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60), 2) AS "Durée Moy (min)",
    ROUND(MIN((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60), 2) AS "Durée Min (min)",
    ROUND(MAX((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60), 2) AS "Durée Max (min)",
    ROUND(STDDEV((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60), 2) AS "Écart-Type"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
        AND fcr.program_application_id = fcp.application_id
WHERE 
    fcr.actual_start_date >= SYSDATE - 30
    AND fcr.actual_completion_date IS NOT NULL
    AND fcr.status_code = 'C'
GROUP BY fcp.user_concurrent_program_name
HAVING COUNT(*) >= 5
ORDER BY AVG((fcr.actual_completion_date - fcr.actual_start_date)) DESC
FETCH FIRST 30 ROWS ONLY;
```

---

## 3. SESSIONS ACTIVES ET BLOCAGES

### 3.1 🔴 Sessions Bloquantes (CRITIQUE)

```sql
SELECT 
    s1.sid || ',' || s1.serial# AS "Session Bloquée",
    s1.username AS "User Bloqué",
    s1.program AS "Programme Bloqué",
    s1.machine AS "Machine Bloquée",
    s1.event AS "Wait Event",
    s1.seconds_in_wait AS "Attente (sec)",
    s2.sid || ',' || s2.serial# AS "Session Bloquante",
    s2.username AS "User Bloquant",
    s2.program AS "Prog Bloquant",
    do.owner || '.' || do.object_name AS "Objet Verrouillé",
    do.object_type AS "Type Objet"
FROM 
    v$locked_object lo
    JOIN dba_objects do ON lo.object_id = do.object_id
    JOIN v$session s1 ON lo.session_id = s1.sid
    JOIN v$lock l1 ON l1.sid = s1.sid
    JOIN v$lock l2 ON l2.id1 = l1.id1 AND l2.request > 0
    JOIN v$session s2 ON l2.sid = s2.sid
WHERE 
    l1.block = 1
ORDER BY s1.seconds_in_wait DESC;
```

### 3.2 Toutes les Sessions Actives

```sql
SELECT 
    s.sid,
    s.serial#,
    s.username,
    s.program,
    s.machine,
    s.status,
    s.event AS "Wait Event",
    s.wait_class,
    s.seconds_in_wait AS "Wait (sec)",
    s.sql_id,
    TO_CHAR(s.logon_time, 'DD/MM HH24:MI') AS "Logon",
    ROUND((SYSDATE - s.logon_time) * 24, 2) AS "Connecté (h)"
FROM v$session s
WHERE 
    s.type = 'USER'
    AND s.status = 'ACTIVE'
    AND s.username IS NOT NULL
ORDER BY s.seconds_in_wait DESC;
```

### 3.3 Sessions EBS (Concurrent Manager)

```sql
SELECT 
    s.sid,
    s.serial#,
    s.username,
    s.status,
    s.event,
    s.seconds_in_wait,
    s.sql_id,
    fcr.request_id,
    fcp.user_concurrent_program_name AS "Programme",
    ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60) AS "Durée (min)"
FROM 
    v$session s
    JOIN v$process p ON s.paddr = p.addr
    JOIN apps.fnd_concurrent_requests fcr ON p.spid = fcr.oracle_process_id
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE 
    fcr.phase_code = 'R'
ORDER BY (SYSDATE - fcr.actual_start_date) DESC;
```

### 3.4 Détail des Locks Actifs

```sql
SELECT 
    s.sid,
    s.serial#,
    s.username,
    s.program,
    l.type AS "Lock Type",
    DECODE(l.lmode, 
        0, 'None', 
        1, 'Null', 
        2, 'Row Share (SS)', 
        3, 'Row Exclusive (SX)', 
        4, 'Share (S)', 
        5, 'Share Row Excl (SSX)', 
        6, 'Exclusive (X)', 
        l.lmode) AS "Lock Mode",
    DECODE(l.request, 
        0, 'None', 
        1, 'Null', 
        2, 'Row Share', 
        3, 'Row Exclusive', 
        4, 'Share', 
        5, 'Share Row Excl', 
        6, 'Exclusive', 
        l.request) AS "Lock Requested",
    l.ctime AS "Lock Time (sec)",
    o.owner || '.' || o.object_name AS "Objet",
    o.object_type
FROM 
    v$lock l
    JOIN v$session s ON l.sid = s.sid
    LEFT JOIN dba_objects o ON l.id1 = o.object_id
WHERE 
    l.type IN ('TX', 'TM', 'UL')
    AND s.username IS NOT NULL
ORDER BY l.ctime DESC;
```

---

## 4. STATISTIQUES ET GATHER TABLE STATS (GTS)

### 4.1 🔴 Tables avec Statistiques Obsolètes (> 7 jours)

```sql
SELECT 
    owner,
    table_name,
    num_rows,
    TO_CHAR(last_analyzed, 'DD/MM/YYYY HH24:MI') AS "Dernière Analyse",
    TRUNC(SYSDATE - last_analyzed) AS "Jours Depuis Analyse",
    stale_stats
FROM dba_tab_statistics
WHERE 
    owner IN ('AP', 'AR', 'GL', 'PO', 'FA', 'XLA', 'APPS')
    AND (last_analyzed IS NULL OR last_analyzed < SYSDATE - 7)
    AND num_rows > 10000
ORDER BY last_analyzed NULLS FIRST, num_rows DESC
FETCH FIRST 50 ROWS ONLY;
```

### 4.2 État des Statistiques par Schéma

```sql
SELECT 
    owner AS "Schéma",
    COUNT(*) AS "Nb Tables",
    SUM(CASE WHEN last_analyzed IS NULL THEN 1 ELSE 0 END) AS "Sans Stats",
    SUM(CASE WHEN last_analyzed < SYSDATE - 7 THEN 1 ELSE 0 END) AS "Stats > 7j",
    SUM(CASE WHEN stale_stats = 'YES' THEN 1 ELSE 0 END) AS "Stats Stale",
    TO_CHAR(MIN(last_analyzed), 'DD/MM/YYYY') AS "Plus Vieille",
    TO_CHAR(MAX(last_analyzed), 'DD/MM/YYYY') AS "Plus Récente"
FROM dba_tab_statistics
WHERE owner IN ('AP', 'AR', 'GL', 'PO', 'FA', 'XLA', 'INV', 'ONT', 'OE', 'APPS')
GROUP BY owner
ORDER BY owner;
```

### 4.3 Tables les Plus Volumineuses sans Statistiques Récentes

```sql
SELECT 
    dt.owner,
    dt.table_name,
    dt.num_rows,
    ROUND(dt.num_rows * dt.avg_row_len / 1024 / 1024, 2) AS "Taille Estimée (MB)",
    TO_CHAR(dt.last_analyzed, 'DD/MM/YYYY HH24:MI') AS "Dernière Analyse",
    TRUNC(SYSDATE - dt.last_analyzed) AS "Jours"
FROM dba_tables dt
WHERE 
    dt.owner IN ('AP', 'AR', 'GL', 'PO', 'FA', 'XLA', 'INV', 'APPS')
    AND dt.num_rows > 100000
    AND (dt.last_analyzed IS NULL OR dt.last_analyzed < SYSDATE - 3)
ORDER BY dt.num_rows DESC
FETCH FIRST 30 ROWS ONLY;
```

### 4.4 Index sans Statistiques ou Statistiques Périmées

```sql
SELECT 
    owner,
    index_name,
    table_name,
    num_rows,
    TO_CHAR(last_analyzed, 'DD/MM/YYYY HH24:MI') AS "Dernière Analyse",
    TRUNC(SYSDATE - last_analyzed) AS "Jours"
FROM dba_indexes
WHERE 
    owner IN ('AP', 'AR', 'GL', 'PO', 'FA', 'XLA', 'APPS')
    AND (last_analyzed IS NULL OR last_analyzed < SYSDATE - 7)
    AND num_rows > 50000
ORDER BY num_rows DESC
FETCH FIRST 30 ROWS ONLY;
```

### 4.5 Historique des Gather Stats (FND_STATS)

```sql
-- Vérifier les dernières exécutions de Gather Schema Statistics
SELECT 
    fcr.request_id,
    fcp.user_concurrent_program_name AS "Programme",
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI') AS "Début",
    TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI') AS "Fin",
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) AS "Durée (min)",
    DECODE(fcr.status_code, 'C', 'OK', 'E', 'Erreur', 'G', 'Warning', fcr.status_code) AS "Statut",
    fcr.argument_text AS "Arguments"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE 
    UPPER(fcp.user_concurrent_program_name) LIKE '%GATHER%STAT%'
    AND fcr.actual_start_date >= SYSDATE - 30
ORDER BY fcr.actual_start_date DESC;
```

### 4.6 Commandes pour Regénérer les Statistiques

```sql
-- ⚠️ À EXÉCUTER AVEC PRÉCAUTION - Regénération des statistiques

-- Statistiques sur une table spécifique
EXEC DBMS_STATS.GATHER_TABLE_STATS(
    ownname => 'AP',
    tabname => 'AP_INVOICES_ALL',
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
    cascade => TRUE,
    degree => 4
);

-- Statistiques sur un schéma complet (long !)
EXEC DBMS_STATS.GATHER_SCHEMA_STATS(
    ownname => 'AP',
    estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
    degree => 4,
    cascade => TRUE
);

-- Via FND_STATS (méthode EBS recommandée)
EXEC FND_STATS.GATHER_SCHEMA_STATS('AP');
```

---

## 5. ANALYSE AWR/ASH

### 5.1 Top SQL par Temps d'Exécution (dernière heure)

```sql
SELECT * FROM (
    SELECT 
        sql_id,
        ROUND(elapsed_time_total / 1000000, 2) AS "Elapsed (sec)",
        ROUND(cpu_time_total / 1000000, 2) AS "CPU (sec)",
        executions_total AS "Exécutions",
        ROUND(elapsed_time_total / NULLIF(executions_total, 0) / 1000000, 4) AS "Avg (sec)",
        disk_reads_total AS "Disk Reads",
        buffer_gets_total AS "Buffer Gets",
        SUBSTR(sql_text, 1, 100) AS "SQL (début)"
    FROM v$sqlstats
    WHERE last_active_time > SYSDATE - 1/24
    ORDER BY elapsed_time_total DESC
)
WHERE ROWNUM <= 20;
```

### 5.2 Top Wait Events (Dernière Heure)

```sql
SELECT 
    event,
    wait_class,
    total_waits,
    ROUND(time_waited / 100, 2) AS "Time Waited (sec)",
    ROUND(average_wait * 10, 2) AS "Avg Wait (ms)"
FROM v$system_event
WHERE 
    wait_class NOT IN ('Idle')
ORDER BY time_waited DESC
FETCH FIRST 20 ROWS ONLY;
```

### 5.3 Top Sessions par Ressources

```sql
SELECT 
    s.sid,
    s.serial#,
    s.username,
    s.program,
    s.machine,
    ss.value AS "CPU Used (cs)",
    ROUND(ss.value / 100, 2) AS "CPU (sec)"
FROM 
    v$session s
    JOIN v$sesstat ss ON s.sid = ss.sid
    JOIN v$statname sn ON ss.statistic# = sn.statistic#
WHERE 
    sn.name = 'CPU used by this session'
    AND s.type = 'USER'
    AND s.username IS NOT NULL
ORDER BY ss.value DESC
FETCH FIRST 20 ROWS ONLY;
```

### 5.4 Historique I/O par Fichier

```sql
SELECT 
    df.file_name,
    df.tablespace_name,
    fs.phyrds AS "Physical Reads",
    fs.phywrts AS "Physical Writes",
    ROUND(fs.readtim / NULLIF(fs.phyrds, 0) * 10, 2) AS "Avg Read (ms)",
    ROUND(fs.writetim / NULLIF(fs.phywrts, 0) * 10, 2) AS "Avg Write (ms)"
FROM 
    v$filestat fs
    JOIN dba_data_files df ON fs.file# = df.file_id
ORDER BY (fs.phyrds + fs.phywrts) DESC
FETCH FIRST 20 ROWS ONLY;
```

### 5.5 Snapshots AWR Disponibles

```sql
SELECT 
    snap_id,
    dbid,
    instance_number,
    TO_CHAR(begin_interval_time, 'DD/MM/YYYY HH24:MI') AS "Début",
    TO_CHAR(end_interval_time, 'DD/MM/YYYY HH24:MI') AS "Fin",
    ROUND((end_interval_time - begin_interval_time) * 24 * 60, 0) AS "Durée (min)"
FROM dba_hist_snapshot
WHERE begin_interval_time > SYSDATE - 7
ORDER BY snap_id DESC
FETCH FIRST 50 ROWS ONLY;
```

### 5.6 Générer un Rapport AWR

```sql
-- Identifier les snapshots
SELECT snap_id, TO_CHAR(begin_interval_time, 'DD/MM HH24:MI') 
FROM dba_hist_snapshot 
WHERE begin_interval_time > SYSDATE - 1
ORDER BY snap_id;

-- Générer le rapport AWR (remplacer X et Y par les snap_id)
-- @?/rdbms/admin/awrrpt.sql
-- Ou via :
SELECT output FROM TABLE(DBMS_WORKLOAD_REPOSITORY.AWR_REPORT_HTML(
    l_dbid     => (SELECT dbid FROM v$database),
    l_inst_num => 1,
    l_bid      => &snap_debut,
    l_eid      => &snap_fin
));
```

---

## 6. ESPACE DISQUE ET TABLESPACES

### 6.1 🔴 Tablespaces Critiques (< 20% libre)

```sql
SELECT 
    df.tablespace_name AS "Tablespace",
    ROUND(df.bytes / 1024 / 1024 / 1024, 2) AS "Taille (GB)",
    ROUND((df.bytes - NVL(fs.bytes, 0)) / 1024 / 1024 / 1024, 2) AS "Utilisé (GB)",
    ROUND(NVL(fs.bytes, 0) / 1024 / 1024 / 1024, 2) AS "Libre (GB)",
    ROUND(NVL(fs.bytes, 0) / df.bytes * 100, 2) AS "% Libre",
    CASE 
        WHEN NVL(fs.bytes, 0) / df.bytes * 100 < 10 THEN '🔴 CRITIQUE'
        WHEN NVL(fs.bytes, 0) / df.bytes * 100 < 20 THEN '🟠 ATTENTION'
        WHEN NVL(fs.bytes, 0) / df.bytes * 100 < 30 THEN '🟡 À SURVEILLER'
        ELSE '🟢 OK'
    END AS "Statut"
FROM 
    (SELECT tablespace_name, SUM(bytes) bytes 
     FROM dba_data_files GROUP BY tablespace_name) df
    LEFT JOIN 
    (SELECT tablespace_name, SUM(bytes) bytes 
     FROM dba_free_space GROUP BY tablespace_name) fs
    ON df.tablespace_name = fs.tablespace_name
ORDER BY NVL(fs.bytes, 0) / df.bytes;
```

### 6.2 UNDO Tablespace

```sql
SELECT 
    tablespace_name,
    status,
    ROUND(SUM(bytes) / 1024 / 1024, 2) AS "Taille (MB)"
FROM dba_undo_extents
GROUP BY tablespace_name, status
ORDER BY tablespace_name, status;
```

### 6.3 TEMP Tablespace Usage

```sql
SELECT 
    tablespace_name,
    ROUND(tablespace_size / 1024 / 1024, 2) AS "Taille (MB)",
    ROUND(allocated_space / 1024 / 1024, 2) AS "Alloué (MB)",
    ROUND(free_space / 1024 / 1024, 2) AS "Libre (MB)",
    ROUND(free_space / tablespace_size * 100, 2) AS "% Libre"
FROM dba_temp_free_space;
```

### 6.4 Segments les Plus Volumineux

```sql
SELECT 
    owner,
    segment_name,
    segment_type,
    tablespace_name,
    ROUND(bytes / 1024 / 1024 / 1024, 2) AS "Taille (GB)"
FROM dba_segments
WHERE owner IN ('AP', 'AR', 'GL', 'PO', 'FA', 'XLA', 'INV', 'APPS')
ORDER BY bytes DESC
FETCH FIRST 30 ROWS ONLY;
```

---

## 7. ALERTES ET LOGS

### 7.1 Erreurs ORA- dans Alert Log (via V$DIAG_ALERT_EXT)

```sql
SELECT 
    TO_CHAR(originating_timestamp, 'DD/MM/YYYY HH24:MI:SS') AS "Date",
    message_text AS "Message"
FROM v$diag_alert_ext
WHERE 
    originating_timestamp > SYSDATE - 1
    AND (message_text LIKE '%ORA-%' 
         OR message_text LIKE '%error%'
         OR message_text LIKE '%fatal%')
ORDER BY originating_timestamp DESC
FETCH FIRST 50 ROWS ONLY;
```

### 7.2 Concurrent Managers Status

```sql
SELECT 
    fcq.user_concurrent_queue_name AS "Manager",
    fcq.max_processes AS "Max Processes",
    fcq.running_processes AS "Running",
    DECODE(fcq.enabled_flag, 'Y', 'Enabled', 'N', 'Disabled') AS "Enabled",
    fcp.node_name AS "Node",
    fcp.process_status_code AS "Status"
FROM 
    apps.fnd_concurrent_queues_vl fcq
    LEFT JOIN apps.fnd_concurrent_processes fcp 
        ON fcq.concurrent_queue_id = fcp.concurrent_queue_id
        AND fcp.process_status_code = 'A'
WHERE fcq.enabled_flag = 'Y'
ORDER BY fcq.user_concurrent_queue_name;
```

### 7.3 Workflow Mailer Status

```sql
SELECT 
    component_name,
    component_status,
    TO_CHAR(last_notification_date, 'DD/MM/YYYY HH24:MI') AS "Dernier Notif"
FROM apps.fnd_svc_components
WHERE component_type = 'WF_MAILER'
ORDER BY component_name;
```

---

## 8. REQUÊTES LES PLUS COÛTEUSES

### 8.1 Top SQL par Buffer Gets (I/O Logique)

```sql
SELECT * FROM (
    SELECT 
        sql_id,
        buffer_gets_total AS "Buffer Gets",
        executions_total AS "Exécutions",
        ROUND(buffer_gets_total / NULLIF(executions_total, 0), 0) AS "Gets/Exec",
        ROUND(elapsed_time_total / 1000000, 2) AS "Elapsed (sec)",
        SUBSTR(sql_text, 1, 80) AS "SQL"
    FROM v$sqlstats
    WHERE buffer_gets_total > 100000
    ORDER BY buffer_gets_total DESC
)
WHERE ROWNUM <= 20;
```

### 8.2 Top SQL par Disk Reads (I/O Physique)

```sql
SELECT * FROM (
    SELECT 
        sql_id,
        disk_reads_total AS "Disk Reads",
        executions_total AS "Exécutions",
        ROUND(disk_reads_total / NULLIF(executions_total, 0), 0) AS "Reads/Exec",
        ROUND(elapsed_time_total / 1000000, 2) AS "Elapsed (sec)",
        SUBSTR(sql_text, 1, 80) AS "SQL"
    FROM v$sqlstats
    WHERE disk_reads_total > 10000
    ORDER BY disk_reads_total DESC
)
WHERE ROWNUM <= 20;
```

### 8.3 Plan d'Exécution d'une Requête

```sql
-- Remplacer 'xxxxxxxxxxxx' par le sql_id à analyser
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR('xxxxxxxxxxxx', NULL, 'ALL'));
```

### 8.4 Full Table Scans Récents

```sql
SELECT 
    sql_id,
    plan_hash_value,
    executions,
    ROUND(elapsed_time / 1000000, 2) AS "Elapsed (sec)",
    SUBSTR(sql_fulltext, 1, 100) AS "SQL"
FROM v$sql
WHERE 
    sql_text LIKE '%TABLE ACCESS FULL%'
    AND last_active_time > SYSDATE - 1
ORDER BY elapsed_time DESC
FETCH FIRST 20 ROWS ONLY;
```

---

## 📊 CHECKLIST DE DIAGNOSTIC RAPIDE

| # | Contrôle | Requête | Seuil Alerte |
|---|----------|---------|--------------|
| 1 | Buffer Cache Hit Ratio | §1.3 | < 95% |
| 2 | Library Cache Hit Ratio | §1.4 | < 99% |
| 3 | Sessions Bloquantes | §3.1 | > 0 |
| 4 | Traitements > 1h en cours | §2.2 | À vérifier |
| 5 | Traitements en erreur | §2.3 | À vérifier |
| 6 | Tablespace < 20% libre | §6.1 | Critique |
| 7 | Tables sans stats > 7j | §4.1 | À regénérer |
| 8 | UNDO/TEMP usage | §6.2, §6.3 | > 80% |
| 9 | Wait Events non-idle | §5.2 | Top 5 |
| 10 | Concurrent Managers | §7.2 | Tous actifs |

---

## 🛠️ ACTIONS CORRECTIVES COURANTES

### Tuer une Session Bloquante

```sql
-- Identifier la session
SELECT sid, serial#, username, program FROM v$session WHERE ...;

-- Tuer la session (IMMEDIATE)
ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;

-- Tuer le process OS si nécessaire (avec DBA)
ALTER SYSTEM DISCONNECT SESSION 'sid,serial#' POST_TRANSACTION;
```

### Annuler un Concurrent Request

```sql
-- Via SQL (avec précaution)
UPDATE apps.fnd_concurrent_requests
SET phase_code = 'C',
    status_code = 'X',
    completion_text = 'Terminé manuellement - Analyse performance',
    actual_completion_date = SYSDATE
WHERE request_id = &request_id;
COMMIT;
```

### Forcer les Statistiques sur Tables Critiques EBS

```sql
-- Tables AP critiques
EXEC DBMS_STATS.GATHER_TABLE_STATS('AP', 'AP_INVOICES_ALL', cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS('AP', 'AP_INVOICE_LINES_ALL', cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS('AP', 'AP_INVOICE_DISTRIBUTIONS_ALL', cascade => TRUE);

-- Tables GL critiques
EXEC DBMS_STATS.GATHER_TABLE_STATS('GL', 'GL_JE_HEADERS', cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS('GL', 'GL_JE_LINES', cascade => TRUE);

-- Tables XLA critiques
EXEC DBMS_STATS.GATHER_TABLE_STATS('XLA', 'XLA_AE_HEADERS', cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS('XLA', 'XLA_AE_LINES', cascade => TRUE);
EXEC DBMS_STATS.GATHER_TABLE_STATS('XLA', 'XLA_DISTRIBUTION_LINKS', cascade => TRUE);
```

---

## 9. RECOMPILATION DES OBJETS INVALIDES

### 9.1 Identifier le Programme de Recompilation EBS

```sql
-- Rechercher les programmes de compilation/recompilation dans EBS
SELECT 
    fcp.concurrent_program_id,
    fcp.concurrent_program_name AS "Nom Technique",
    fcp.user_concurrent_program_name AS "Nom Utilisateur",
    fa.application_short_name AS "Application",
    fcp.enabled_flag AS "Actif",
    fet.execution_file_name AS "Fichier/Package",
    DECODE(fet.execution_method_code, 
        'I', 'PL/SQL Stored Procedure',
        'P', 'Oracle Reports',
        'L', 'SQL*Loader',
        'H', 'Host Script',
        'S', 'Spawned',
        'J', 'Java',
        fet.execution_method_code) AS "Type Exécution"
FROM 
    apps.fnd_concurrent_programs_vl fcp
    JOIN apps.fnd_application fa ON fcp.application_id = fa.application_id
    LEFT JOIN apps.fnd_executables fet ON fcp.executable_id = fet.executable_id
WHERE 
    UPPER(fcp.user_concurrent_program_name) LIKE '%COMPIL%'
    OR UPPER(fcp.user_concurrent_program_name) LIKE '%INVALID%'
    OR UPPER(fcp.concurrent_program_name) LIKE '%COMPILE%'
    OR UPPER(fcp.concurrent_program_name) LIKE '%INVALID%'
ORDER BY fcp.user_concurrent_program_name;
```

### 9.2 Historique des Exécutions de Recompilation

```sql
-- Historique des exécutions du programme de compilation
SELECT 
    fcr.request_id AS "Request ID",
    fcp.user_concurrent_program_name AS "Programme",
    fcp.concurrent_program_name AS "Nom Technique",
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') AS "Début",
    TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') AS "Fin",
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) AS "Durée (min)",
    DECODE(fcr.phase_code, 'C', 'Terminé', 'R', 'En cours', 'P', 'En attente', fcr.phase_code) AS "Phase",
    DECODE(fcr.status_code, 'C', 'Normal', 'E', 'Erreur', 'G', 'Warning', 'R', 'Running', fcr.status_code) AS "Statut",
    fu.user_name AS "Lancé par",
    fcr.argument_text AS "Arguments"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
        AND fcr.program_application_id = fcp.application_id
    LEFT JOIN apps.fnd_user fu ON fcr.requested_by = fu.user_id
WHERE 
    (UPPER(fcp.user_concurrent_program_name) LIKE '%COMPIL%'
     OR UPPER(fcp.user_concurrent_program_name) LIKE '%INVALID%'
     OR UPPER(fcp.concurrent_program_name) LIKE '%COMPILE%')
    AND fcr.actual_start_date >= SYSDATE - 30
ORDER BY fcr.actual_start_date DESC;
```

### 9.3 Objets Invalides Actuels (à recompiler)

```sql
-- Lister les objets invalides par schéma
SELECT 
    owner AS "Schéma",
    object_type AS "Type",
    COUNT(*) AS "Nb Invalides"
FROM dba_objects
WHERE status = 'INVALID'
GROUP BY owner, object_type
ORDER BY owner, COUNT(*) DESC;
```

```sql
-- Détail des objets invalides EBS
SELECT 
    owner,
    object_name,
    object_type,
    TO_CHAR(created, 'DD/MM/YYYY') AS "Créé le",
    TO_CHAR(last_ddl_time, 'DD/MM/YYYY HH24:MI') AS "Dernier DDL",
    status
FROM dba_objects
WHERE 
    status = 'INVALID'
    AND owner IN ('APPS', 'AP', 'AR', 'GL', 'PO', 'FA', 'XLA', 'INV', 'ONT')
ORDER BY owner, object_type, object_name;
```

### 9.4 Programme Standard EBS : "Compile Invalid Objects"

**Nom technique** : `FNDCPUCN` ou rechercher via :
- **"Compile Invalid Objects"** (AD_DD package)
- **"Generate Applications Files"**

```sql
-- Trouver spécifiquement le programme de compilation AD
SELECT 
    fcp.concurrent_program_id,
    fcp.concurrent_program_name,
    fcp.user_concurrent_program_name,
    fa.application_short_name,
    fet.execution_file_name
FROM 
    apps.fnd_concurrent_programs_vl fcp
    JOIN apps.fnd_application fa ON fcp.application_id = fa.application_id
    LEFT JOIN apps.fnd_executables fet ON fcp.executable_id = fet.executable_id
WHERE 
    fa.application_short_name = 'AD'
    AND (fcp.concurrent_program_name LIKE '%COMPILE%'
         OR fcp.concurrent_program_name LIKE '%INVALID%'
         OR fcp.user_concurrent_program_name LIKE '%Compile%');
```

### 9.5 Recompilation Manuelle (DBA)

```sql
-- Recompiler tous les objets invalides (méthode Oracle standard)
-- ⚠️ À exécuter par le DBA uniquement

-- Option 1 : UTL_RECOMP (recommandé)
EXEC UTL_RECOMP.RECOMP_SERIAL();      -- Séquentiel
EXEC UTL_RECOMP.RECOMP_PARALLEL(4);   -- Parallèle (4 threads)

-- Option 2 : Script utlrp.sql
-- @?/rdbms/admin/utlrp.sql

-- Option 3 : Via DBMS_UTILITY
EXEC DBMS_UTILITY.COMPILE_SCHEMA(schema => 'APPS', compile_all => FALSE);
```

### 9.6 Planification via Concurrent Manager

```sql
-- Vérifier si le programme est planifié (scheduled)
SELECT 
    fcr.request_id,
    fcp.user_concurrent_program_name AS "Programme",
    TO_CHAR(fcr.requested_start_date, 'DD/MM/YYYY HH24:MI') AS "Planifié pour",
    fcr.resubmit_interval || ' ' || fcr.resubmit_interval_unit_code AS "Récurrence",
    fu.user_name AS "Planifié par"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
    LEFT JOIN apps.fnd_user fu ON fcr.requested_by = fu.user_id
WHERE 
    fcr.phase_code = 'P'
    AND fcr.hold_flag = 'N'
    AND (UPPER(fcp.user_concurrent_program_name) LIKE '%COMPIL%'
         OR UPPER(fcp.concurrent_program_name) LIKE '%COMPILE%')
ORDER BY fcr.requested_start_date;
```

---

## 📝 NOTES D'ANALYSE

### Observations

| Date | Observation | Action |
|------|-------------|--------|
| 21/01/2026 | | |
| | | |
| | | |

### Contacts

| Rôle | Contact | Responsabilité |
|------|---------|----------------|
| DBA Oracle | | Performance, AWR, tuning |
| Admin EBS | | Concurrent Managers |
| Réseau | | Latence, connectivité |

---

*Document généré le 21/01/2026 - GitHub Copilot*
