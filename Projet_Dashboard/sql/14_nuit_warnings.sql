-- NUIT - Detail des warnings
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT fcr.request_id                                                            AS REQ_ID,
       fcp.user_concurrent_program_name                                           AS PROGRAMME,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS')                        AS DEBUT,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1)  AS DUREE_MIN,
       SUBSTR(fcr.completion_text, 1, 55)                                         AS MSG
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + &heure_fermeture / 24
AND    fcr.actual_start_date <  TRUNC(SYSDATE)      + &heure_ouverture / 24
AND    fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
AND    fcr.status_code = 'G'
-- Meme regle que le compteur v_nb_warnings : les fins annoncees normales ne sont pas listees.
AND    UPPER(TRIM(NVL(fcr.completion_text, '-')))
       NOT IN ('REQUEST COMPLETED NORMAL', 'FIN NORMALE')
ORDER BY fcr.actual_start_date DESC;
