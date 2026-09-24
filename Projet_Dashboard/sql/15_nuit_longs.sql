-- NUIT - Traitements longs (> 30 min)
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT fcr.request_id                                                            AS REQ_ID,
       fcp.user_concurrent_program_name                                           AS PROGRAMME,
       TO_CHAR(fcr.actual_start_date,      'DD/MM HH24:MI')                      AS DEBUT,
       TO_CHAR(fcr.actual_completion_date, 'DD/MM HH24:MI')                      AS FIN,
       ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 1)  AS DUREE_MIN,
       CASE fcr.status_code WHEN 'C' THEN 'OK' WHEN 'E' THEN 'ERREUR' WHEN 'G' THEN 'WARNING' ELSE fcr.status_code END AS STATUT
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + &heure_fermeture / 24
AND    fcr.actual_start_date <  TRUNC(SYSDATE)      + &heure_ouverture / 24
AND    fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
AND    (fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60 > 30
ORDER BY (fcr.actual_completion_date - fcr.actual_start_date) DESC;
