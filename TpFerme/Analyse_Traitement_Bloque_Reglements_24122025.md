# Analyse - Traitement Bloqué : Règlements Automatiques des Prélèvements Clients

**Date**: 24 décembre 2025  
**Incident**: Traitement DKA bloqué depuis 0h42  
**Gravité**: 🔴 Critique  
**Base de données**: Oracle EBS 12.2.13 Production (19.25.0.0.0)

---

## 1. RÉSUMÉ EXÉCUTIF

Le traitement concurrent **"DKA : Règlements automatiques des prélèvements clients"** (REQUEST_ID: 46584756) s'exécute depuis le 24/12/2025 à 00:42:21, soit **plus de 7h30** au moment de l'analyse, ce qui est **~4x plus long que la durée normale** (100-115 minutes).

### Diagnostic Principal

#### ⚠️ CORRECTION IMPORTANTE : Le Traitement TOURNE Réellement !

**Découverte** : Après analyse approfondie via `V$PROCESS`, le traitement **N'EST PAS MORT** mais s'exécute réellement depuis 7h30.

#### Incohérence dans FND_CONCURRENT_REQUESTS.ORACLE_SESSION_ID

**Situation observée** : Le concurrent request 46584756 est enregistré dans `APPS.FND_CONCURRENT_REQUESTS` avec :
- `PHASE_CODE = 'R'` (Running - En cours d'exécution)
- `STATUS_CODE = 'R'` (Running)
- `ORACLE_SESSION_ID = 34763198`
- `ACTUAL_COMPLETION_DATE = NULL` (pas de date de fin)

**Requête de vérification du concurrent request** :
```sql
SELECT 
    fcr.request_id,
    TO_CHAR(fcr.request_date, 'DD/MM HH24:MI:SS') AS "Date Soumission",
    TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS "Date Début",
    DECODE(fcr.phase_code, 'C', 'Terminé', 'P', 'En attente', 'R', 'En cours', fcr.phase_code) AS "Phase",
    DECODE(fcr.status_code, 'C', 'Terminé', 'E', 'Erreur', 'R', 'En cours', fcr.status_code) AS "Statut",
    TRUNC((SYSDATE - fcr.actual_start_date) * 24 * 60) AS "Durée Minutes",
    fcp.user_concurrent_program_name AS "Programme",
    fcr.oracle_session_id AS "SID"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE **34763198** (INCORRECT !) | Durée: 450 minutes

**Première vérification** dans `V$SESSION` pour le SID enregistré (34763198) :

```sql
SELECT 
    s.sid,
    s.serial#,
    s.username,
    s.program,
    s.status,
    s.blocking_session AS "Bloqué Par SID",
    s.event AS "Wait Event",
    TO_CHAR(s.logon_time, 'DD/MM HH24:MI:SS') AS "Logon Time"
FROM 
    v$session s
WHERE 
    s.sid = 34763198;
```

**Résultat** : **0 rows returned** ❌

**⚠️ MAIS** la vérification via `V$PROCESS` révèle que **le processus OS EXISTE** et possède une **session ACTIVE** !

```sql
-- Recherche via le processus OS (SPID)
SELECT 
    p.spid,
    p.program,
    s.sid,
    s.serial#,
    s.username,
    s.status,
    s.event,
    TO_CHAR(s.logon_time, 'DD/MM HH24:MI:SS') AS "Logon Time",
    TRUNC((SYSDATE - s.logon_time) * 24 * 60) AS "Minutes"
FROM 
    v$process p
    JOIN v$session s ON p.addr = s.paddr
WHERE 
    p.spid = (SELECT oracle_process_id FROM apps.fnd_concurrent_requests WHERE request_id = 46584756);
```
**Le traitement s'exécute RÉELLEMENT depuis 7h30**, mais présente deux anomalies :

1. **Incohérence du SID enregistré** : 
   - `FND_CONCURRENT_REQUESTS.ORACLE_SESSION_ID` = 34763198 (incorrect)
   - Session Oracle réelle = SID 104 (identifiée via SPID 322486)
   
2. **Durée d'exécution anormale** :
   - Durée actuelle : **450 minutes (7h30)**
   - Durée normale : 100-115 minutes
   - **Dépassement : ~4x la normale**

**État de la session SID 104** :
- **Status** : ACTIVE ✅
- **Wait Event** : `PL/SQL lock timer` (14 secondes)
- **Wait Class** : Idle
- **Programme** : `DKA_SARAUTOPRELEV_PKG.MAIN` en cours
- **Machine** : STANDARD@ldkfinp01
- **Module** : e:AR:cp:dka/DKA_SARAUTOPRELEV

**Interprétation du "PL/SQL lock timer"** :
- Peut être un `DBMS_LOCK.SLEEP()` programmé
- Peut être une attente sur une ressource applicative
- Peut indiquer un traitement par lots avec attentes entre chaque lot
- **Ce n'est PAS un deadlock**, la session est active

#### Mécanisme de Fonctionnement Normal

En fonctionnement normal, voici le cycle de vie d'un concurrent request :

1. **Soumission** : Le concurrent request est créé dans `FND_CONCURRENT_REQUESTS` avec `PHASE_CODE = 'P'` (Pending)
2. **Démarrage** : Le Concurrent Manager lance un processus qui :
   - Crée une **session Oracle** (ex: SID 34763198)
   - Met à jour le request avec `PHASE_CODE = 'R'` et stocke le `ORACLE_SESSION_ID`
   - Exécute le programme PL/SQL ou autre
3. **Fin normale** : À la fin de l'exécution :
   - Le programme se termine proprement
   - La session Oracle est fermée (DISCONNECT)
   - Le Concurrent Manager met à jour : `PHASE_CODE = 'C'`, `STATUS_CODE = 'C'/'E'`, `ACTUAL_COMPLETION_DATE = SYSDATE`

#### Ce Qui S'est Réellement Passé

Dans notre cas, **la session Oracle a disparu brutalement sans que le Concurrent Manager en soit informé** :

**Causes possibles de disparition de session** :
- **Kill manuel** : Un DBA a exécuté `ALTER SYSTEM KILL SESSION '34763198,xxx'`
- **Erreur fatale** : Exception PL/SQL non gérée (ex: `ORA-01555`, `ORA-00600`, `ORA-04030`)
- **Timeout réseau** : Perte de connexion entre le serveur applicatif et la base de données
- **Crash du processus** : Le processus OS du concurrent request a crashé (SIGSEGV, kill -9)
- **Arrêt brutal** : Shutdown de l'instance ou du Concurrent Manager sans cleanup

**Pourquoi le Concurrent Manager n'a pas détecté la mort** :

Le Concurrent Manager surveille les processus de deux façons :
1. **Monitoring actif** : Vérification périodique des processus OS (pid)
2. **Heartbeat de session** : Dans certains cas, vérification de `V$SESSION`

**Le problème** : Si la session disparaît entre deux vérifications, ou si le processus OS existe encore (zombie) mais que la session DB est morte, le Concurrent Manager peut ne pas détecter l'anomalie immédiatement. Il attend alors un timeout (souvent configuré à plusieurs heures) avant de considérer le request comme "perdu".

**Conséquence** : Le traitement est en réalité **mort/terminé anormalement depuis plusieurs heures** mais apparaît toujours comme "Running" dans Oracle EBS, créant une situation de **"zombie request"**.

---
1 : Sessions bloquées et bloquantes**
```sql
SELECT 
    s1.sid || ',' || s1.serial# AS "Session Bloquée",
    s1.username AS "User Bloqué",
    s1.program AS "Programme Bloqué",
    TRUNC((SYSDATE - s1.logon_time) * 24 * 60) AS "Minutes Connecté",
    s2.sid || ',' || s2.serial# AS "Session Bloquante",
    s2.username AS "User Bloquant",
    do.owner || '.' || do.object_name AS "Objet Verrouillé",
    do.object_type AS "Type Objet"
FROM 
    v$locked_object lo,
    dba_objects do,
    v$session s1,
    v$session s2,
    v$lock l1,
    v$lock l2
WHERE 
    lo.object_id = do.object_id
    AND lo.session_id = s1.sid
    AND l1.sid = s1.sid
    AND l2.id1 = l1.id1
    AND l2.request > 0
    AND l1.block = 1
    AND l2.sid = s2.sid
ORDER BY s1.logon_time;
```

**Résultat** : **0 rows selected** ✅

**Requête 2 : Locks actifs sur la session 34763198**
```sql
SELECT 
    l.sid,
    l.type AS "Type Lock",
    DECODE(l.lmode, 0, 'None', 1, 'Null', 2, 'Row Share', 3, 'Row Exclusive', 
           4, 'Share', 5, 'Share Row Exclusive', 6, 'Exclusive', l.lmode) AS "Lock Mode",
    DECODE(l.request, 0, 'None', 1, 'Null', 2, 'Row Share', 3, 'Row Exclusive',
           4, 'Share', 5, 'Share Row Exclusive', 6, 'Exclusive', l.request) AS "Lock Requested",
    l.ctime AS "Lock Time (seconds)",
    o.owner || '.' || o.object_name AS "Objet",
    o.object_type
FROM 
    v$lock l
    LEFT JOIN dba_objects o ON l.id1 = o.object_id
WHERE 
    l.sid détaillée de la session**
```sql
SELECT 
    s.sid,
    s.serial#, (enregistré)** | 34763198 ❌ (INCORRECT) |
| **Oracle Session ID (réel)** | **104** ✅ |
| **Oracle Process ID (SPID)** | 322486 |
| **Statut Session Oracle** | ✅ **ACTIVE** |
| **Wait Event** | PL/SQL lock timer (14s) |
| **SQL en cours** | DKA_SARAUTOPRELEV_PKG.MAIN
    s.program,
    s.machine,
    s.osuser,
    s.status,
    s.logon_time,
    TRUNC((SYSDATE - s.logon_time) * 24 * 60) AS "Minutes Connecté",
    s.blocking_session AS "Bloqué Par SID",
    s.blocking_session_status AS "Statut Session Bloquante",
    s.event AS "Wait Event",
    s.wait_class AS "Wait Class",
    s.seconds_in_wait AS "Secondes en Wait",
    s.state AS "State50 minutes (7h30) = **~4x la durée normale**

**Note** : Le traitement du 22/12 a aussi pris 114 minutes (proche de la limite supérieure normale), suggérant que les durées tendent à augmenter.
    s.sql_id,
    s.prev_sql_id
FROM 
    v$session s
WHERE 
    s.sid = 34763198;
```

**Résultat**: 
```
0 rows returned
```

**Conclusion**: La session Oracle **n'existe plus**. Elle a été:
- Tuée manuellement par un DBA (`ALTER SYSTEM KILL SESSION`)
- Déconnectée suite à un timeout réseau
- Terminée suite à une erreur fatale (ORA-00600, ORA-04030, etc.)
- Arrêtée lors d'un incident système (crash, shutdown)
| **Request ID** | 46584756 |
| **Programme** | DKA : Règlements automatiques des prélèvements clients |
| **Programme Technique** | DKA_SARAUTOPRELEV |
| **Type d'exécution** | **PL/SQL Stored Procedure** (code 'I') |
| **Package PL/SQL** | DKA_SARAUTOPRELEV_PKG.MAIN |
| **Date de lancement** | 24/12/2025 à 00:42:21 |
| **Durée écoulée** | 403 minutes (6h 43min) |
| **Phase Oracle EBS** | R (Running) |
| **Statut Oracle EBS** | R (Running) |
| **Oracle Session ID** | 34763198 |
| **Statut Session Oracle** | ❌ **N'EXISTE PLUS** (ANORMAL pour PL/SQL) |

### 2.2 Historique des Exécutions (7 derniers jours)

```
REQUEST_ID | Date Début    | Durée (min) | Statut
-----------|---------------|-------------|--------
46584756   | 24/12 00:42   | 403 (actuel)| Running ⚠️
46572956   | 22/12 23:55   | 114         | Succès ✓
46557972   | 20/12 01:28   | 102         | Succès ✓
46545684   | 19/12 02:24   | 0           | G
46535902   | 18/12 01:33   | 0           | G
46526068   | 17/12 02:46   | 3           | Succès ✓
```

**Durée normale**: 100-115 minutes  
**Durée actuelle**: 403 minutes = **~4x la durée normale**

---

## 3. ANALYSE TECHNIQUE

### 3.0 Type de Programme Concurrent

**Requête d'identification du type d'exécution** :
```sql
SELECT 
    fcr.request_id,
    fcp.user_concurrent_program_name AS "Programme",
    fcp.concurrent_program_name AS "Programme Technique",
    fcp.execution_method_code AS "Code Type",
    DECODE(fcp.execution_method_code,
        'B', 'Request Set (Batch)',
        'Q', 'SQL*Plus',
        'H', 'Host (Shell Unix)',
        'A', 'Spawn',
        'I', 'PL/SQL Stored Procedure',
        'P', 'Oracle Reports',
        'S', 'Immediate',
        'K', 'Java Stored Procedure',
        'J', 'Java Concurrent Program',
        fcp.execution_method_code) AS "Type Exécution",
    fe.executable_name AS "Nom Exécutable",
    fe.execution_file_name AS "Fichier Exécution",
    CASE 
        WHEN fcp.execution_method_code = 'H' THEN 'N/A - Programme Shell'
        WHEN fcp.execution_method_code = 'I' THEN 'OUI - Session Oracle requise'
        WHEN fcp.execution_method_code = 'P' THEN 'OUI - Session Oracle requise'
        ELSE 'À vérifier'
    END AS "Session DB Attendue?"
FROM 
    apps.fnd_concurrent_requests fcr
    JOIN apps.fnd_concurrent_programs_vl fcp 
        ON fcr.concurrent_program_id = fcp.concurrent_program_id
    LEFT JOIN apps.fnd_executables fe
        ON fcp.executable_application_id = fe.application_id
        AND fcp.executable_id = fe.executable_id
WHERE 
    fcr.request_id = 46584756;a session 34763198 enregistrée dans `FND_CONCURRENT_REQUESTS` n'existe pas, mais l'analyse via `V$PROCESS` a révélé que **la session RÉELLE est la SID 104**, qui est **ACTIVE** et exécute bien le package `DKA_SARAUTOPRELEV_PKG.MAIN`
```

**Résultat** :

| Attribut | Valeur |
|----------|--------|
| **Type d'exécution** | **PL/SQL Stored Procedure** (code 'I') |
| **Programme technique** | DKA_SARAUTOPRELEV |
| **Package PL/SQL** | DKA_SARAUTOPRELEV_PKG.MAIN |
| **Session Oracle attendue** | ✅ **OUI - REQUISE** |

**Conclusion importante** : Ce type de programme **DOIT avoir une session Oracle active** dans `V$SESSION`. Le fait que la session 34763198 n'existe plus est donc **TOTALEMENT ANORMAL** et confirme que le programme PL/SQL a crashé ou été interrompu brutalement.

**Types d'exécution Oracle EBS** :
- `'H'` Identification de la Session Réelle via V$PROCESS

**Découverte Clé** : Le SID enregistré dans `FND_CONCURRENT_REQUESTS` était incorrect. La session réelle a été trouvée via le processus OS.

**Requête d'identification via SPID** :
```sql
SELECT 
    fcr.request_id,
    fcr.oracle_session_id AS "SID Enregistré",
    fcr.oracle_process_id AS "SPID",
    p.spid AS "SPID Exists",
    s.sid AS "SID Réel",
    s.serial#,
    s.status,
    s.event,
    s.wait_class,
    TRUNC((SYSDATE - s.logon_time) * 24 * 60) AS "Minutes",
    s.sql_id
FROM 
    apps.fnd_concurrent_requests fcr
    LEFT JOIN v$process p ON fcr.oracle_process_id = TO_CHAR(p.spid)
    LEFT JOIN v$session s ON p.addr = s.paddr
WHERE 
    fcr.request_id = 46584756;
```

**Résultat** :
| REQUEST_ID | SID Enregistré | SPID | SID Réel | Status | Event | Minutes |
|------------|----------------|------|----------|--------|-------|---------|
| 46584756 | 34763198 ❌ | 322486 | **104** ✅ | ACTIVE | PL/SQL lock timer | 450 |

**SQL actuellement exécuté** :
```sql3 Analyse de la Session Réelle (SID 104)

**Détail complet de la session** :
```sql
SELECT 
    s.sid, s.serial#, s.username, s.status, s.state,
    s.event, s.wait_class, s.seconds_in_wait,
    s.blocking_session,
    TO_CHAR(s.logon_time, 'DD/MM HH24:MI:SS') AS logon_time,
    s.program, s.module,
    s.sql_id, s.prev_sql_id
FROM v$session s
WHERE s.sid = 104;
```

**Résultat** :
- **Status** : ACTIVE ✅
- **State** : WAITING
- **Event** : **PL/SQL lock timer** (classe: Idle)
- **Seconds in Wait** : 14 secondes
- **Blocking Session** : NULL (pas bloqué)
- **Programme** : STANDARD@ldkfinp01 (TNS V1-V3)
- **Module** : e:AR:cp:dka/DKA_SARAUTOPRELEV
- **Logon Time** : 24/12 00:42:21
- **Minutes connecté** : 450

**Interprétation** :
- Le traitement **s'exécute normalement**
- Le wait event "PL/SQL lock timer" indique probablement un `DBMS_LOCK.SLEEP()` ou attente programmée
- **Pas de blocage** (blocking_session = NULL)
- **Pas de lock** détecté

### 3.4 PourqRéel Identifié

1. **00:42:21** - Le traitement démarre normalement
2. **Depuis 00:42** - Le traitement **s'exécute réellement** sur la session SID 104
3. **Durée anormale** : 450 minutes (7h30) au lieu de 100-115 minutes normalement
4. **Incohérence** : Le SID enregistré dans `FND_CONCURRENT_REQUESTS` (34763198) ne correspond pas à la session réelle (104)

### Causes Possibles de la Durée Excessive
    LEFT JOIN v$session s ON fcr.oracle_session_id = s.sid
WHERE 
    fcr.request_id = 46584756;
```

**RéVolume de données anormalement élevé**
  - Nombre de règlements/prélèvements clients à traiter beaucoup plus important que d'habitude
  - Vérifier le nombre d'enregistrements traités vs historique
  
- **Performance dégradée du package PL/SQL**
  - Requêtes non optimisées dans `DKA_SARAUTOPRELEV_PKG.MAIN`
  - Absence d'index sur tables critiques
  - Statistiques obsolètes sur les tables
  - Plans d'exécution dégradés
  
- **Attentes programmées excessives**
  - `DBMS_LOCK.SLEEP()` avec durées trop longues
  - Attentes entre chaque lot de traitement (visible via "PL/SQL lock timer")
  
- **Problème métier**
  - Données incohérentes nécessitant des tentatives multiples
  - Rejets/erreurs métier nécessitant des retraitements
  
- **Contention sur ressources**
  - Locks applicatifs (pas visibles dans V$LOCK)
  - Attente sur ressources externes (web services, files d'attente)

### Causes Possibles de l'Incohérence du SID

- **Reconnexion automatique** : La session initiale a peut-être été interrompue puis reconnectée (nouveau SID attribué)
- **Bug Oracle EBS** : Certaines versions ne mettent pas à jour correctement `ORACLE_SESSION_ID` après reconnexion
- **Processus wrapper/proxy** : Le Concurrent Manager peut utiliser plusieurs sessions pour un même traitement
0 ⚠️ **Règlements automatiques en cours depuis 7h30** (durée anormalement longue)
- ⚠️ **Risque de timeout** si le traitement dépasse une limite système
- ⚠️ **Blocage potentiel des traitements suivants** qui dépendent de celui-ci
- 📊 **Impact utilisateurs** : Les règlements ne seront disponibles qu'à la fin du traitement

### 5.2 Impact Technique

- ⏱️ **Performance dégradée** : Le traitement prend 4x plus de temps que la normale
- 📈 **Ressources consommées** : Session active depuis 7h30 (PGA, CPU, locks potentiels)
- 🔍 **Monitoring difficile** : Le SID enregistré ne correspond pas à la réalité
- ⚠️ **Risque de conflit** si une nouvelle exécution est lancée manuellement
### 3.3 État du Concurrent Request

Bien que la session Oracle soit morte, `FND_CONCURRENT_REQUESTS` indique toujours:
- `PHASEOption 1 : Laisser le Traitement se Terminer (RECOMMANDÉ)

**⚠️ Le traitement s'exécute RÉELLEMENT**, il n'est pas bloqué. 

**Recommandation** : **Attendre qu'il se termine naturellement** sauf si :
- Il dépasse 10 heures (risque de timeout système)
- Des traitements critiques dépendants sont bloqués
- L'activité métier requiert une intervention immédiate

**Monitoring** :
```sql
-- Surveiller la progression (toutes les 10 minutes)
SELECT 
    s.sid,
    s.status,
    s.event,
    s.seconds_in_wait,
    TRUNC((SYSDATE - s.logon_time) * 24 * 60) AS "Minutes",
    s.sql_id
FROM v$session s
WHERE s.sid = 104;
```

### 6.2 Option 2 : Terminer le Traitement (SI NÉCESSAIRE)

**⚠️ ATTENTION** : Comme le traitement s'exécute réellement, le tuer causera une interruption brutale.

**Script SQL pour terminer la SESSION RÉELLE** (pas le SID enregistré) :

```sql
-- ATTENTION : Tuer la SESSION RÉELLE (SID 104), pas le SID enregistré !
ALTER 3 Analyser la Cause de la Durée Excessive

**1. Vérifier le volume de données traité** :
```sql
-- Comparer avec les exécutions précédentes
SELECT 
    fcr.request_id,
    TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI') AS debut,
    TRUNC((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60) AS duree_min
FROM apps.fnd_concurrent_requests fcr
JOIN apps.fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcp.concurrent_program_name = 'DKA_SARAUTOPRELEV'
  AND fcr.actual_start_date >= TRUNC(SYSDATE) - 30
  AND fcr.phase_code = 'C'
ORDER BY fcr.actual_start_date DESC;
```

**2. Analyser le plan d'exécution SQL** :
```sql
-- Identifier les requêtes lentes dans le package
SELECT sql_id, sql_text, elapsed_time/1000000 AS elapsed_sec, executions
FROM v$sql
WHERE sql_text LIKE '%DKA%SARAUTOPRELEV%'
  AND parsing_schema_name = 'APPS'
ORDER BY elapsed_time DESC;
```

**3. Consulter les logs du traitement** :
- Vérifier le fichier log du REQUEST_ID 46584756
- Identifier où le traitement passe le plus de temps

### 6.4ual_completion_date = SYSDATE,
    completion_text = 'Terminated manually - Excessive duration (450+ min) - Real SID was 104, not 34763198'
1. **00:42:21** - Le traitement démarre normalement (session 34763198 créée)
2. **Entre 00:42 et 07:25** - La session Oracle meurt pour une raison inconnue:
   - Erreur applicative non gérée
   - Problème réseau/connectivité
   - Timeout de session
   - Kill manuel de la session
3. **07:25** - Le Concurrent Manager **n'a pas détecté** la mort de la session
4. Le statut du REQUEST reste figé à "Running"

### Causes Possibles de la Mort de Session

- **Erreur PL/SQL non gérée** dans le package **DKA_SARAUTOPRELEV_PKG.MAIN**
  - Exception non capturée (WHEN OTHERS manquant)
  - Erreur fatale Oracle (ORA-00600, ORA-04030, ORA-01555)
  - Division par zéro, accès NULL, dépassement de mémoire
- **Timeout de session** (`SQLNET.EXPIRE_TIME`)
  - Connexion réseau perdue entre serveur applicatif et DB
  - Session idle trop longue
- **Problème réseau** entre le serveur applicatif et la base de données
  - Coupure réseau momentanée
  - Firewall qui coupe la connexion
- **Manque de ressources** 
  - TEMP space saturé
  - Rollback segments pleins
  - Mémoire PGA/UGA insuffisante
  - Processus max atteint
- **Kill manuel** par un DBA (vérifier les logs alert.log)
  - `ALTER SYSTEM KILL SESSION '34763198,xxx'`
  - Shutdown de la base de données

---

## 5. IMPACT

### 5.1 Impact Métier

- ❌ **Règlements automatiques non effectués** depuis 00:42
- ❌ **Prélèvements clients non traités**
- ⚠️ **Blocage potentiel des traitements suivants** si dépendance

### 5.2 Impact Technique

- Le REQUEST_ID 46584756 reste visible comme "En cours" dans le Concurrent Manager
- Risque de **conflit** si une nouvelle exécution est lancée manuellement
- Les **logs du traitement** ne seront pas complets (pas de log de fin)

---

## 6. SOLUTION RECOMMANDÉE

### 6.1 Action Immédiate : Forcer la Terminaison du Request

**Script SQL à exécuter** (en tant que APPS):

```sql
-- Marquer le traitement comme terminé en erreur
UPDATE apps.fnd_concurrent_requests
SET phase_code = 'C',
    status_code = 'E',
    actual_completion_date = SYSDATE,
    completion_text = 'Terminated manually - Session 34763198 lost at ' || 
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS')
WHERE request_id = 46584756
  AND phase_code = 'R';

COMMIT;
```

**Vérification post-exécution**:
```sql
SELECT 
    request_id,
    phase_code,
    status_code,
    TO_CHAR(actual_start_date, 'DD/MM HH24:MI:SS') AS debut,
    TO_CHAR(actual_completion_date, 'DD/MM HH24:MI:SS') AS fin,
    completion_text
FROM apps.fnd_concurrent_requests
WHERE request_id = 46584756;
```

### 6.2 Action de Reprise

RelanIMMÉDIAT** - ⏱️ **Surveiller** la session SID 104 toutes les 10 minutes jusqu'à terminaison
2. **COURT TERME** - 📊 Analyser les logs du REQUEST_ID 46584756 pour identifier les goulots d'étranglement
3. **COURT TERME** - 🔍 Comparer le volume de données traité vs historique
4. **MOYEN TERME** - ⚡ Optimiser le package `DKA_SARAUTOPRELEV_PKG.MAIN` :
   - Identifier les requêtes lentes
   - Vérifier les index manquants
   - Mettre à jour les statistiques
5. **MOYEN TERME** - 🔧 Investiguer pourquoi `FND_CONCURRENT_REQUESTS.ORACLE_SESSION_ID` est incorrect
6. **LONG TERME** - 📈 Mettre en place des alertes sur durée d'exécution anormale (> 150 min)
```

### 6.3 Actions Préventives
**DKA_SARAUTOPRELEV_PKG.MAIN**:
   - Log des étapes intermédiaires dans une table de log
   - EXCEPTION handlers avec COMMIT/ROLLBACK appropriés
   - Notification en cas d'erreur (email, table de monitoring)
   - Code exemple :
   ```sql
   EXCEPTION
     WHEN OTHERS THEN
       -- Log de l'erreur
       INSERT INTO dka_log_table (request_id, error_code, error_message, error_date)
       VALUES (p_request_id, SQLCODE, SQLERRM, SYSDATE);
       COMMIT;
       -- Propager l'erreur
       RAISE;
   END;
   ```[SID]/trace/
   ```

2. **Vérifier les paramètres de timeout**:
   ```sql
   SELECT name, value 
   FROM v$parameter 
   WHERE name LIKE '%timeout%' OR name LIKE '%expire%';
   ```

3. **Ajouter une gestion d'erreur robuste** dans le package PL/SQL:
   - Log des étapes intermédiaires
   - EXCEPTION handlers avec COMMIT/ROLLBACK appropriés
   -Identification du type de programme (PL/SQL Stored Procedure)
- ✅ Recherche de locks actifs (aucun trouvé)
- ✅ Vérification de la session Oracle 34763198 (n'existe plus)
- ✅ Analyse de l'historique des exécutions du traitement
- ✅ Identification de tous les traitements en cours (3 autres traitements zombies détectés
   Concurrent:Active Request Timeout
   ```

---

## 7. ACTIONS RÉALISÉES

- ✅ Connexion à la base de données `oracleProd`
- ✅ Recherche de locks actifs (aucun trouvé)
- ✅ Vérification de la session Oracle 34763198 (n'existe plus)
- ✅ Analyse de l'historique des exécutions du traitement
- ✅ Identification de tous les traitements en cours (aucun autre)
- ✅ Génération du rapport d'analyse

---

## 8. PROCHAINES ÉTAPES

1. **URGENT** - Exécuter le script de terminaison forcée du REQUEST 46584756
2. 

**Identification session réelle via V$PROCESS** (REQUÊTE CLÉ) :
```sql
SELECT 
    fcr.request_id,
    fcr.oracle_session_id AS "SID Enregistré",
---

## 10. LEÇONS APPRISES

### 10.1 Méthodologie de Diagnostic

**❌ Erreur initiale** : Se fier uniquement au SID enregistré dans `FND_CONCURRENT_REQUESTS.ORACLE_SESSION_ID`

**✅ Approche correcte** : 
1. Vérifier le SID enregistré dans `V$SESSION`
2. **Si introuvable**, chercher via `V$PROCESS` en utilisant `ORACLE_PROCESS_ID` (SPID)
3. Joindre `V$PROCESS` → `V$SESSION` via `ADDR` et `PADDR`

### 10.2 Points Clés

- Le champ `ORACLE_SESSION_ID` dans `FND_CONCURRENT_REQUESTS` **peut être obsolète/incorrect**
- Le **SPID (processus OS) est plus fiable** que le SID pour identifier une session
- Un wait event "PL/SQL lock timer" **n'est PAS un blocage**, c'est souvent une attente programmée
- Toujours vérifier `V$PROCESS` avant de conclure qu'une session est morte

### 10.3 Documentation Oracle

Pour référence, voici les vues système Oracle utilisées :
- **V$SESSION** : Sessions actives (identifiées par SID)
- **V$PROCESS** : Processus OS (identifiés par SPID)
- **V$LOCK** : Locks et contentions
- **FND_CONCURRENT_REQUESTS** : Requêtes concurrent Oracle EBS

**Note My Oracle Support** : Rechercher "Concurrent Request Shows Running But Session Does Not Exist" (divers Doc ID disponibles selon versions EBS)

---

**Rapport généré par**: GitHub Copilot (Claude Sonnet 4.5)  
**Date de génération**: 24/12/2025  
**Dernière mise à jour**: 24/12/2025 08:15 (Correction majeure - Session réelle identifiée)
    s.sid AS "SID Réel",
    s.status, s.event,
    TRUNC((SYSDATE - s.logon_time) * 24 * 60) AS "Minutes"
FROM 
    apps.fnd_concurrent_requests fcr
    LEFT JOIN v$process p ON fcr.oracle_process_id = TO_CHAR(p.spid)
    LEFT JOIN v$session s ON p.addr = s.paddr
WHERE 
    fcr.request_id = 46584756ent manuellement si nécessaire
3. **PRIORITAIRE** - Analyser les logs Oracle pour identifier la cause
4. **IMPORTANT** - Vérifier l'impact métier (règlements manquants)
5. **SUIVI** - Surveiller les prochaines exécutions du traitement

---

## 9. ANNEXES

### 9.1 Requêtes SQL Utilisées

**Recherche de locks**:
```sql
SELECT s1.sid || ',' || s1.serial# AS "Session Bloquée",
       s2.sid || ',' || s2.serial# AS "Session Bloquante",
       do.owner || '.' || do.object_name AS "Objet Verrouillé"
FROM v$locked_object lo, dba_objects do, v$session s1, v$session s2,
     v$lock l1, v$lock l2
WHERE lo.object_id = do.object_id
  AND lo.session_id = s1.sid
  AND l1.sid = s1.sid
  AND l2.id1 = l1.id1
  AND l2.request > 0
  AND l1.block = 1
  AND l2.sid = s2.sid;
```

**Vérification session**:
```sql
SELECT sid, serial#, username, program, status, 
       blocking_session, event, wait_class
FROM v$session
WHERE sid = 34763198;
```

**Historique traitement**:
```sql
SELECT fcr.request_id,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS') AS debut,
       TRUNC((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60) AS duree_min,
       fcr.phase_code, fcr.status_code
FROM apps.fnd_concurrent_requests fcr
JOIN apps.fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcp.user_concurrent_program_name = 
      'DKA : Règlements automatiques des prélèvements clients'
  AND fcr.actual_start_date >= TRUNC(SYSDATE) - 7
ORD

**Type de programme concurrent**:
```sql
SELECT 
    fcp.execution_method_code,
    DECODE(fcp.execution_method_code,
        'I', 'PL/SQL Stored Procedure',
        'H', 'Host (Shell)',
        'P', 'Oracle Reports',
        fcp.execution_method_code) AS type,
    fe.execution_file_name AS package
FROM apps.fnd_concurrent_programs_vl fcp
LEFT JOIN apps.fnd_executables fe
    ON fcp.executable_id = fe.executable_id
WHERE fcp.concurrent_program_name = 'DKA_SARAUTOPRELEV';
```ER BY fcr.actual_start_date DESC;
```

### 9.2 Contacts

- **DBA Oracle**: [À compléter]
- **Équipe Support EBS**: [À compléter]
- **Responsable Métier Finance**: [À compléter]

---

**Rapport généré par**: GitHub Copilot (Claude Sonnet 4.5)  
**Date de génération**: 24/12/2025  
**Connexion utilisée**: oracleProd via SQLcl MCP Server
