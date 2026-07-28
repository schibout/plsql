-- Définition complète du programme "Mise à jour quotidienne des sites fournisseurs dupliqués"

-- 1. Informations générales du programme concurrent
SELECT 
    fcp.concurrent_program_id,
    fcp.concurrent_program_name as nom_court,
    fcp.user_concurrent_program_name as nom_affiche,
    fcp.description,
    fcp.executable_id,
    fcp.execution_method_code as methode_execution,
    fcp.output_file_type as type_sortie,
    fcp.enable_trace as trace_active,
    fcp.enabled_flag as actif,
    fcp.run_alone_flag as execution_seule,
    fcp.increment_proc as incrementiel
FROM fnd_concurrent_programs_vl fcp
WHERE fcp.user_concurrent_program_name LIKE '%sites fournisseurs dupliqu%'
   OR fcp.user_concurrent_program_name LIKE '%Mise à jour quotidienne%';

-- 2. Détails de l'exécutable associé
SELECT 
    fcp.user_concurrent_program_name as programme,
    fe.executable_name as nom_executable,
    fe.execution_file_name as fichier_execution,
    fe.execution_method_code as methode,
    DECODE(fe.execution_method_code,
        'B', 'Request Set Stage Function',
        'Q', 'SQL*Plus',
        'H', 'Host',
        'L', 'SQL*Loader',
        'A', 'Spawned',
        'I', 'PL/SQL Stored Procedure',
        'P', 'Oracle Reports',
        'S', 'Immediate',
        'K', 'Java Concurrent Program',
        'J', 'Java Stored Procedure',
        fe.execution_method_code) as type_methode,
    fe.description as description_executable
FROM fnd_concurrent_programs_vl fcp
JOIN fnd_executables fe ON fcp.executable_id = fe.executable_id
WHERE fcp.user_concurrent_program_name LIKE '%sites fournisseurs dupliqu%'
   OR fcp.user_concurrent_program_name LIKE '%Mise à jour quotidienne%';

-- 3. Paramètres du programme
SELECT 
    fcp.user_concurrent_program_name as programme,
    fcpv.user_name as parametre,
    fcpv.description as description_param,
    fcpv.end_user_column_name as nom_colonne,
    fcpv.required_flag as obligatoire,
    fcpv.enabled_flag as actif,
    fcpv.default_type,
    fcpv.default_value as valeur_defaut,
    fvs.flex_value_set_name as liste_valeurs
FROM fnd_concurrent_programs_vl fcp
JOIN fnd_descr_flex_col_usage_vl fcpv 
    ON fcp.application_id = fcpv.application_id
    AND fcp.concurrent_program_id = fcpv.descriptive_flex_context_code
LEFT JOIN fnd_flex_value_sets fvs 
    ON fcpv.flex_value_set_id = fvs.flex_value_set_id
WHERE fcp.user_concurrent_program_name LIKE '%sites fournisseurs dupliqu%'
   OR fcp.user_concurrent_program_name LIKE '%Mise à jour quotidienne%'
ORDER BY fcpv.column_seq_num;

-- 4. Historique des exécutions (derniers 30 jours)
SELECT 
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY') as date_exec,
    COUNT(*) as nb_executions,
    AVG(ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2)) as duree_moy_min,
    MIN(ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2)) as duree_min_min,
    MAX(ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2)) as duree_max_min,
    SUM(CASE WHEN fcr.status_code = 'C' THEN 1 ELSE 0 END) as nb_succes,
    SUM(CASE WHEN fcr.status_code IN ('E','X') THEN 1 ELSE 0 END) as nb_erreurs
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
    ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE (fcp.user_concurrent_program_name LIKE '%sites fournisseurs dupliqu%'
   OR fcp.user_concurrent_program_name LIKE '%Mise à jour quotidienne%')
  AND fcr.actual_start_date >= SYSDATE - 30
GROUP BY TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY')
ORDER BY TO_DATE(TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY'), 'DD/MM/YYYY') DESC;

-- 5. Dernières 10 exécutions détaillées
SELECT 
    fcr.request_id,
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as debut,
    TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') as fin,
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as duree_min,
    fcr.status_code,
    DECODE(fcr.status_code, 
        'C', 'Complété', 
        'E', 'Erreur', 
        'R', 'En cours',
        'X', 'Terminé',
        fcr.status_code) as statut,
    fcr.argument_text as parametres,
    fcr.completion_text as message,
    fcr.logfile_name as fichier_log,
    fcr.outfile_name as fichier_sortie
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
    ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE (fcp.user_concurrent_program_name LIKE '%sites fournisseurs dupliqu%'
   OR fcp.user_concurrent_program_name LIKE '%Mise à jour quotidienne%')
ORDER BY fcr.actual_start_date DESC
FETCH FIRST 10 ROWS ONLY;

-- 6. Si c'est un programme PL/SQL, voir le code source
SELECT 
    fcp.user_concurrent_program_name as programme,
    fe.execution_file_name as package_procedure
FROM fnd_concurrent_programs_vl fcp
JOIN fnd_executables fe ON fcp.executable_id = fe.executable_id
WHERE (fcp.user_concurrent_program_name LIKE '%sites fournisseurs dupliqu%'
   OR fcp.user_concurrent_program_name LIKE '%Mise à jour quotidienne%')
  AND fe.execution_method_code IN ('I', 'J'); -- PL/SQL ou Java Stored Procedure

-- 7. Planifications (si le programme est planifié)
SELECT 
    fcp.user_concurrent_program_name as programme,
    fcr.requested_start_date as prochaine_execution,
    fcr.hold_flag as en_attente,
    fcr.resubmit_interval,
    fcr.resubmit_interval_unit_code,
    fcr.resubmit_interval_type_code
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
    ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE (fcp.user_concurrent_program_name LIKE '%sites fournisseurs dupliqu%'
   OR fcp.user_concurrent_program_name LIKE '%Mise à jour quotidienne%')
  AND fcr.phase_code = 'P'  -- Pending
  AND fcr.requested_start_date > SYSDATE
ORDER BY fcr.requested_start_date;
