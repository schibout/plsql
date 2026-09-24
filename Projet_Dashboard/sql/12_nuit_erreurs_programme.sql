-- NUIT - Erreurs regroupees par programme
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT fcp.user_concurrent_program_name                       AS PROGRAMME,
       COUNT(*)                                                AS NB_ERR,
       TO_CHAR(MIN(fcr.actual_start_date), 'DD/MM HH24:MI:SS') AS PREMIERE,
       TO_CHAR(MAX(fcr.actual_start_date), 'DD/MM HH24:MI:SS') AS DERNIERE,
       SUBSTR(MIN(fcr.completion_text), 1, 70)                 AS MSG
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + &heure_fermeture / 24
AND    fcr.actual_start_date <  TRUNC(SYSDATE)      + &heure_ouverture / 24
AND    fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
AND    fcr.status_code = 'E'
GROUP BY fcp.user_concurrent_program_name
ORDER BY COUNT(*) DESC;
