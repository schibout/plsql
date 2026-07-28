-- =====================================================================
-- JOB : Refresh automatique de la MV TOUS LES JOURS à 20h00
-- =====================================================================
-- Date : 15/01/2026
-- Vue : DKA_FFI_UODALKIA_TACHE
-- Fréquence : Quotidienne à 20h00
-- =====================================================================

BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name        => 'JOB_REFRESH_MV_20H00',
        job_type        => 'PLSQL_BLOCK',
        job_action      => q'[
            BEGIN
                DBMS_MVIEW.REFRESH(
                    list                 => 'EAI_FRONTAL_FINANCE.DKA_FFI_UODALKIA_TACHE',
                    method               => 'C',
                    atomic_refresh       => TRUE,
                    out_of_place         => FALSE
                );
            END;
        ]',
        start_date      => TRUNC(SYSDATE) + (20/24),  -- Démarre aujourd'hui à 20h00
        repeat_interval => 'FREQ=DAILY; BYHOUR=20; BYMINUTE=0; BYSECOND=0',
        enabled         => TRUE,
        comments        => 'Refresh quotidien de DKA_FFI_UODALKIA_TACHE chaque jour à 20h00'
    );
    
    DBMS_OUTPUT.PUT_LINE('✅ Job JOB_REFRESH_MV_20H00 créé avec succès');
    DBMS_OUTPUT.PUT_LINE('   Exécution : Tous les jours à 20h00');
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
WHERE job_name = 'JOB_REFRESH_MV_20H00';

-- =====================================================================
-- GESTION DU JOB
-- =====================================================================

-- Désactiver temporairement le job
-- EXEC DBMS_SCHEDULER.DISABLE('JOB_REFRESH_MV_20H00');

-- Réactiver le job
-- EXEC DBMS_SCHEDULER.ENABLE('JOB_REFRESH_MV_20H00');

-- Exécuter manuellement le job maintenant
-- EXEC DBMS_SCHEDULER.RUN_JOB('JOB_REFRESH_MV_20H00');

-- Supprimer le job
-- EXEC DBMS_SCHEDULER.DROP_JOB('JOB_REFRESH_MV_20H00');

-- Voir tous les jobs
-- SELECT job_name, state, enabled FROM user_scheduler_jobs;

-- =====================================================================
-- HISTORIQUE D'EXÉCUTION
-- =====================================================================
SELECT 
    TO_CHAR(log_date, 'DD/MM/YYYY HH24:MI:SS') as date_execution,
    status,
    TO_CHAR(actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
    ROUND((run_duration) * 86400, 0) as duree_secondes,
    error#,
    additional_info
FROM user_scheduler_job_run_details
WHERE job_name = 'JOB_REFRESH_MV_20H00'
ORDER BY log_date DESC;
