### =====================================================================
#                                                                       #                    
#             L'ensemble des Requêtes de Contrôle                       #
#                                                                       #
### =====================================================================

## SOMMAIRE

### Contrôles Pré-Refresh
1. État général de la vue matérialisée
2. Changements en attente dans les logs
3. Intégrité référentielle des données sources
4. Cohérence des dates
5. Doublons potentiels (risque TOO_MANY_ROWS)

### Contrôles Post-Refresh
6. Comparaison volumes MV vs Source
7. Vérification état des index
8. Vérification vidage des logs

### Scripts et Outils
9. Script de refresh complet avec contrôles intégrés
10. Tableau de bord des contrôles (requête unique)
11. Job de refresh automatique quotidien (00h00)
12. Points d'attention
### 1 Contrôle Pré-Refresh : Vérification de l'État

```sql
-- =====================================================================
-- CONTRÔLE 1 : État général de la vue matérialisée
-- =====================================================================
SELECT 
    mview_name,
    staleness,
    TO_CHAR(stale_since, 'DD/MM/YYYY HH24:MI:SS') as stale_depuis,
    compile_state,
    refresh_mode,
    refresh_method,
    fast_refreshable,
    last_refresh_type,
    TO_CHAR(last_refresh_date, 'DD/MM/YYYY HH24:MI:SS') as dernier_refresh
FROM user_mviews 
WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE';
```

### 2 Contrôle Pré-Refresh : Changements en Attente

```sql
-- =====================================================================
-- CONTRÔLE 2 : Nombre de changements en attente dans les logs
-- =====================================================================
SELECT 'MLOG$_DKA_FFI_TACHE' as log_table, COUNT(*) as changements_en_attente 
FROM MLOG$_DKA_FFI_TACHE
UNION ALL
SELECT 'MLOG$_DKA_FFI_CENTRE_FINAN', COUNT(*) 
FROM MLOG$_DKA_FFI_CENTRE_FINAN;
```

### 3 Contrôle Pré-Refresh : Intégrité des Données Sources

```sql
-- =====================================================================
-- CONTRÔLE 3 : Intégrité référentielle des données sources
-- =====================================================================
SELECT 
    'Tâches orphelines (sans projet parent)' as controle,
    COUNT(*) as nb_anomalies,
    CASE WHEN COUNT(*) > 0 THEN 'Attention ATTENTION' ELSE ' OK' END as statut
FROM DKA_FFI_TACHE t
WHERE NOT EXISTS (
    SELECT 1 FROM DKA_FFI_PROJET p 
    WHERE p.CODEPROJET = t.PARENTPROJET
)
UNION ALL
SELECT 
    'Projets orphelins (sans centre finance)',
    COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN 'Attention ATTENTION' ELSE ' OK' END
FROM DKA_FFI_PROJET p
WHERE NOT EXISTS (
    SELECT 1 FROM DKA_FFI_CENTRE_FINANCE cf 
    WHERE cf.CODECENTREFINANCE = p.PARENTCENTREFINANCE
)
UNION ALL
SELECT 
    'Centres finance sans UO Dalkia',
    COUNT(*),
    CASE WHEN COUNT(*) > 0 THEN ' CRITIQUE' ELSE ' OK' END
FROM DKA_FFI_CENTRE_FINANCE
WHERE UODALKIA IS NULL;
```

### 4 Contrôle Pré-Refresh : Cohérence des Dates

```sql
-- =====================================================================
-- CONTRÔLE 4 : Dates incohérentes (fin < début)
-- =====================================================================
SELECT 
    'Projets avec date fin < date début' as controle,
    COUNT(*) as anomalies
FROM DKA_FFI_PROJET
WHERE DATEFIN IS NOT NULL AND DATEFIN < DATEDEBUT
UNION ALL
SELECT 
    'Centres finance avec date fin < date début',
    COUNT(*)
FROM DKA_FFI_CENTRE_FINANCE
WHERE DATEFIN IS NOT NULL AND DATEFIN < DATEDEBUT;
```

### 5 Contrôle Pré-Refresh : Doublons Potentiels

```sql
-- =====================================================================
-- CONTRÔLE 5 : Tâches avec plusieurs UO Dalkia actives (doublons)
-- Risque de TOO_MANY_ROWS dans la procédure
-- =====================================================================
SELECT 
    CODETACHE,
    COUNT(*) as nb_uo_actives,
    LISTAGG(UODALKIA, ', ') WITHIN GROUP (ORDER BY UODALKIA) as uo_list
FROM DKA_FFI_UODALKIA_TACHE
WHERE (DATEFINP IS NULL OR DATEFINP > SYSDATE)
  AND (DATEFINCF IS NULL OR DATEFINCF > SYSDATE)
GROUP BY CODETACHE
HAVING COUNT(*) > 1
ORDER BY nb_uo_actives DESC;
```

### 6 Contrôle Post-Refresh : Comparaison Volumes

```sql
-- =====================================================================
-- CONTRÔLE 6 : Comparaison du nombre de lignes MV vs Source
-- À exécuter APRÈS le refresh
-- =====================================================================
SELECT 
    (SELECT COUNT(*) FROM DKA_FFI_UODALKIA_TACHE) as nb_lignes_mv,
    (SELECT COUNT(*) 
     FROM DKA_FFI_TACHE t
     JOIN DKA_FFI_PROJET p ON t.PARENTPROJET = p.CODEPROJET
     JOIN DKA_FFI_CENTRE_FINANCE cf ON p.PARENTCENTREFINANCE = cf.CODECENTREFINANCE
    ) as nb_lignes_attendu,
    (SELECT COUNT(*) FROM DKA_FFI_UODALKIA_TACHE) - 
    (SELECT COUNT(*) 
     FROM DKA_FFI_TACHE t
     JOIN DKA_FFI_PROJET p ON t.PARENTPROJET = p.CODEPROJET
     JOIN DKA_FFI_CENTRE_FINANCE cf ON p.PARENTCENTREFINANCE = cf.CODECENTREFINANCE
    ) as ecart
FROM dual;
```

### 7 Contrôle Post-Refresh : Vérification Index

```sql
-- =====================================================================
-- CONTRÔLE 7 : État des index après refresh
-- =====================================================================
SELECT 
    index_name,
    index_type,
    status,
    CASE WHEN status = 'VALID' THEN ' OK' ELSE ' REBUILD REQUIS' END as action
FROM user_indexes
WHERE table_name = 'DKA_FFI_UODALKIA_TACHE';
```

### 8 Contrôle Post-Refresh : Logs Vidés

```sql
-- =====================================================================
-- CONTRÔLE 8 : Vérifier que les logs sont vidés après refresh COMPLETE
-- =====================================================================
SELECT 
    'MLOG$_DKA_FFI_TACHE' as log_table, 
    COUNT(*) as lignes_restantes,
    CASE WHEN COUNT(*) = 0 THEN ' OK' ELSE 'Attention Non vidé' END as statut
FROM MLOG$_DKA_FFI_TACHE
UNION ALL
SELECT 
    'MLOG$_DKA_FFI_CENTRE_FINAN', 
    COUNT(*),
    CASE WHEN COUNT(*) = 0 THEN ' OK' ELSE 'Attention Non vidé' END
FROM MLOG$_DKA_FFI_CENTRE_FINAN;
```

---

## 9. Script de Refresh avec Contrôles Intégrés

```sql
-- =====================================================================
-- SCRIPT DE REFRESH COMPLET AVEC CONTRÔLES
-- =====================================================================
-- Date : 15/01/2026
-- Vue : DKA_FFI_UODALKIA_TACHE
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET TIMING ON

DECLARE
    v_nb_mv_avant     NUMBER;
    v_nb_mv_apres     NUMBER;
    v_nb_source       NUMBER;
    v_nb_orphelins    NUMBER;
    v_staleness       VARCHAR2(30);
    v_start_time      TIMESTAMP := SYSTIMESTAMP;
    v_end_time        TIMESTAMP;
BEGIN
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('REFRESH DKA_FFI_UODALKIA_TACHE');
    DBMS_OUTPUT.PUT_LINE('Début : ' || TO_CHAR(v_start_time, 'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('========================================');
    
    -- CONTRÔLE PRE-REFRESH 1 : État actuel
    SELECT staleness INTO v_staleness 
    FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE';
    DBMS_OUTPUT.PUT_LINE('État avant refresh : ' || v_staleness);
    
    -- CONTRÔLE PRE-REFRESH 2 : Nombre de lignes avant
    SELECT COUNT(*) INTO v_nb_mv_avant FROM DKA_FFI_UODALKIA_TACHE;
    DBMS_OUTPUT.PUT_LINE('Lignes MV avant : ' || TO_CHAR(v_nb_mv_avant, '999,999,999'));
    
    -- CONTRÔLE PRE-REFRESH 3 : Tâches orphelines
    SELECT COUNT(*) INTO v_nb_orphelins
    FROM DKA_FFI_TACHE t
    WHERE NOT EXISTS (SELECT 1 FROM DKA_FFI_PROJET p WHERE p.CODEPROJET = t.PARENTPROJET);
    DBMS_OUTPUT.PUT_LINE('Tâches orphelines Sans Projet: ' || v_nb_orphelins);
    
    IF v_nb_orphelins > 500 THEN
        DBMS_OUTPUT.PUT_LINE('Attention ATTENTION : Nombre élevé de tâches orphelines !');
    END IF;
    
    -- REFRESH COMPLET (COMPLETE car FAST impossible sans log sur PROJET)
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('>>> Exécution du REFRESH COMPLETE...');
    
    DBMS_MVIEW.REFRESH(
        list                 => 'EAI_FRONTAL_FINANCE.DKA_FFI_UODALKIA_TACHE',
        method               => 'C',  -- Complete refresh
        atomic_refresh       => TRUE,
        out_of_place         => FALSE
    );
    
    v_end_time := SYSTIMESTAMP;
    
    -- CONTRÔLE POST-REFRESH 1 : État après
    SELECT staleness INTO v_staleness 
    FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE';
    DBMS_OUTPUT.PUT_LINE('État après refresh : ' || v_staleness);
    
    -- CONTRÔLE POST-REFRESH 2 : Nombre de lignes après
    SELECT COUNT(*) INTO v_nb_mv_apres FROM DKA_FFI_UODALKIA_TACHE;
    DBMS_OUTPUT.PUT_LINE('Lignes MV après : ' || TO_CHAR(v_nb_mv_apres, '999,999,999'));
    
    -- CONTRÔLE POST-REFRESH 3 : Lignes attendues
    SELECT COUNT(*) INTO v_nb_source
    FROM DKA_FFI_TACHE t
    JOIN DKA_FFI_PROJET p ON t.PARENTPROJET = p.CODEPROJET
    JOIN DKA_FFI_CENTRE_FINANCE cf ON p.PARENTCENTREFINANCE = cf.CODECENTREFINANCE;
    
    DBMS_OUTPUT.PUT_LINE('Lignes source : ' || TO_CHAR(v_nb_source, '999,999,999'));
    
    -- VALIDATION
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('RÉSUMÉ');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Durée : ' || 
        EXTRACT(MINUTE FROM (v_end_time - v_start_time)) || ' min ' ||
        ROUND(EXTRACT(SECOND FROM (v_end_time - v_start_time))) || ' sec');
    DBMS_OUTPUT.PUT_LINE('Delta lignes : ' || TO_CHAR(v_nb_mv_apres - v_nb_mv_avant, 'S999,999'));
    
    IF v_nb_mv_apres = v_nb_source THEN
        DBMS_OUTPUT.PUT_LINE(' REFRESH RÉUSSI - Données synchronisées');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Attention ÉCART DÉTECTÉ : ' || (v_nb_mv_apres - v_nb_source) || ' lignes');
        DBMS_OUTPUT.PUT_LINE('   (Normal si tâches orphelines)');
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(' ERREUR : ' || SQLERRM);
        RAISE;
END;
/
```

## 10. Tableau de Bord des Contrôles

```sql
-- =====================================================================
-- REQUÊTE TABLEAU DE BORD : État complet en une seule requête
-- =====================================================================

SELECT 'État MV' as categorie, staleness as valeur, 
       CASE staleness WHEN 'FRESH' THEN '' WHEN 'STALE' THEN 'Attention' ELSE '' END as statut
FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE'
UNION ALL
SELECT 'Dernier refresh', TO_CHAR(last_refresh_date, 'DD/MM/YYYY HH24:MI'),
       CASE WHEN last_refresh_date > SYSDATE - 1 THEN '' 
            WHEN last_refresh_date > SYSDATE - 7 THEN 'Attention' 
            ELSE '' END
FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE'
UNION ALL
SELECT 'Lignes MV', TO_CHAR(COUNT(*), '999,999,999'), ''
FROM DKA_FFI_UODALKIA_TACHE
UNION ALL
SELECT 'Log Tâches en attente', TO_CHAR(COUNT(*), '999,999'), 
       CASE WHEN COUNT(*) = 0 THEN '' WHEN COUNT(*) < 1000 THEN 'Attention' ELSE '' END
FROM MLOG$_DKA_FFI_TACHE
UNION ALL
SELECT 'Log CF en attente', TO_CHAR(COUNT(*), '999,999'),
       CASE WHEN COUNT(*) = 0 THEN '' WHEN COUNT(*) < 100 THEN 'Attention' ELSE '' END
FROM MLOG$_DKA_FFI_CENTRE_FINAN
UNION ALL
SELECT 'Tâches orphelines', TO_CHAR(COUNT(*), '999,999'),
       CASE WHEN COUNT(*) = 0 THEN '' WHEN COUNT(*) < 500 THEN 'Attention' ELSE '' END
FROM DKA_FFI_TACHE t
WHERE NOT EXISTS (SELECT 1 FROM DKA_FFI_PROJET p WHERE p.CODEPROJET = t.PARENTPROJET)
UNION ALL
SELECT 'Index', status, CASE status WHEN 'VALID' THEN '' ELSE '' END
FROM user_indexes WHERE table_name = 'DKA_FFI_UODALKIA_TACHE';
```

---

## 11. Job de Refresh Automatique Quotidien (00h00)

```sql
-- =====================================================================
-- JOB : Refresh automatique quotidien de la vue matérialisée
-- Planifié tous les jours à 00h00
-- =====================================================================

BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_REFRESH_MV_UODALKIA_TACHE',
        job_type        => 'PLSQL_BLOCK',
        job_action      => q'[
            DECLARE
                v_nb_mv_avant     NUMBER;
                v_nb_mv_apres     NUMBER;
                v_staleness       VARCHAR2(30);
                v_start_time      TIMESTAMP := SYSTIMESTAMP;
                v_end_time        TIMESTAMP;
                v_duree_minutes   NUMBER;
            BEGIN
                -- État avant
                SELECT staleness INTO v_staleness 
                FROM user_mviews WHERE mview_name = 'DKA_FFI_UODALKIA_TACHE';
                
                SELECT COUNT(*) INTO v_nb_mv_avant FROM DKA_FFI_UODALKIA_TACHE;
                
                -- Refresh COMPLETE
                DBMS_MVIEW.REFRESH(
                    list           => 'EAI_FRONTAL_FINANCE.DKA_FFI_UODALKIA_TACHE',
                    method         => 'C',
                    atomic_refresh => TRUE
                );
                
                v_end_time := SYSTIMESTAMP;
                v_duree_minutes := EXTRACT(MINUTE FROM (v_end_time - v_start_time)) + 
                                  (EXTRACT(SECOND FROM (v_end_time - v_start_time)) / 60);
                
                -- État après
                SELECT COUNT(*) INTO v_nb_mv_apres FROM DKA_FFI_UODALKIA_TACHE;
                
                -- Log du résultat (adapter selon votre table de log)
                INSERT INTO DKA_FFI_LOG_REFRESH (
                    date_refresh, vue_name, nb_lignes_avant, nb_lignes_apres, 
                    duree_minutes, statut
                ) VALUES (
                    SYSDATE, 'DKA_FFI_UODALKIA_TACHE', v_nb_mv_avant, v_nb_mv_apres,
                    v_duree_minutes, 'SUCCESS'
                );
                COMMIT;
                
            EXCEPTION
                WHEN OTHERS THEN
                    -- Log de l''erreur
                    INSERT INTO DKA_FFI_LOG_REFRESH (
                        date_refresh, vue_name, statut, message_erreur
                    ) VALUES (
                        SYSDATE, 'DKA_FFI_UODALKIA_TACHE', 'ERROR', SQLERRM
                    );
                    COMMIT;
                    RAISE;
            END;
        ]',
        start_date      => TRUNC(SYSDATE + 1),  -- Démarre demain à 00h00
        repeat_interval => 'FREQ=DAILY; BYHOUR=0; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Refresh quotidien automatique de DKA_FFI_UODALKIA_TACHE à 00h00'
    );
    
    DBMS_OUTPUT.PUT_LINE('Job JOB_REFRESH_MV_UODALKIA_TACHE créé avec succès');
END;
/

-- =====================================================================
-- VÉRIFICATION : Consulter le job créé
-- =====================================================================
SELECT 
    job_name,
    state,
    enabled,
    TO_CHAR(next_run_date, 'DD/MM/YYYY HH24:MI:SS') as prochaine_execution,
    TO_CHAR(last_start_date, 'DD/MM/YYYY HH24:MI:SS') as derniere_execution,
    run_count,
    failure_count
FROM user_scheduler_jobs
WHERE job_name = 'JOB_REFRESH_MV_UODALKIA_TACHE';

-- =====================================================================
-- GESTION DU JOB
-- =====================================================================

-- Désactiver temporairement le job
-- EXEC DBMS_SCHEDULER.DISABLE('JOB_REFRESH_MV_UODALKIA_TACHE');

-- Réactiver le job
-- EXEC DBMS_SCHEDULER.ENABLE('JOB_REFRESH_MV_UODALKIA_TACHE');

-- Exécuter manuellement le job
-- EXEC DBMS_SCHEDULER.RUN_JOB('JOB_REFRESH_MV_UODALKIA_TACHE');

-- Supprimer le job
-- EXEC DBMS_SCHEDULER.DROP_JOB('JOB_REFRESH_MV_UODALKIA_TACHE');

-- =====================================================================
-- HISTORIQUE D'EXÉCUTION DU JOB
-- =====================================================================
SELECT 
    log_date,
    status,
    TO_CHAR(actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
    ROUND((run_duration) * 86400 / 60, 2) as duree_minutes,
    error#,
    additional_info
FROM user_scheduler_job_run_details
WHERE job_name = 'JOB_REFRESH_MV_UODALKIA_TACHE'
ORDER BY log_date DESC;
```

---

## 12. Points d'Attention

### Attention Vue Matérialisée UNUSABLE

Si La vue matérialisée `DKA_FFI_UODALKIA_TACHE` a un statut **UNUSABLE** . 

**Action recommandée** :
```sql
-- Rafraîchir la vue matérialisée
EXEC DBMS_MVIEW.REFRESH('EAI_FRONTAL_FINANCE.DKA_FFI_UODALKIA_TACHE', 'C');
```
