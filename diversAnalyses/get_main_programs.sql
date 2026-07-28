-- Top 20 des programmes les plus exécutés (30 derniers jours)
PROMPT === TOP 20 PROGRAMMES CONCURRENTS (30 JOURS) ===
SELECT * FROM (
    SELECT fcp.user_concurrent_program_name,
           fcp.concurrent_program_name,
           count(*) as nb_executions,
           round(avg(fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as avg_duration_min
    FROM fnd_concurrent_requests fcr
    JOIN fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
    WHERE fcr.actual_start_date >= TRUNC(SYSDATE - 30)
    GROUP BY fcp.user_concurrent_program_name, fcp.concurrent_program_name
    ORDER BY count(*) DESC
) WHERE ROWNUM <= 20;

-- Top 20 des programmes personnalisés DKA les plus exécutés (30 derniers jours)
PROMPT === TOP 20 PROGRAMMES PERSONNALISES DKA (30 JOURS) ===
SELECT * FROM (
    SELECT fcp.user_concurrent_program_name,
           fcp.concurrent_program_name,
           count(*) as nb_executions,
           round(avg(fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as avg_duration_min
    FROM fnd_concurrent_requests fcr
    JOIN fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
    WHERE fcr.actual_start_date >= TRUNC(SYSDATE - 30)
    AND fcp.concurrent_program_name LIKE 'DKA%'
    GROUP BY fcp.user_concurrent_program_name, fcp.concurrent_program_name
    ORDER BY count(*) DESC
) WHERE ROWNUM <= 20;
