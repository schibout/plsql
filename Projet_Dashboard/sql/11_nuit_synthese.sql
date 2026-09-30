-- NUIT - Synthese par statut
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par export.sql : 10, 19, 7.

SELECT 'NUIT_SYNTHESE' AS CONTROLE,
       CASE status_code
           WHEN 'C' THEN 'OK'
           WHEN 'E' THEN '*** ERREUR ***'
           WHEN 'G' THEN 'WARNING'
           WHEN 'R' THEN 'EN COURS'
           WHEN 'W' THEN 'EN ATTENTE'
           ELSE 'AUTRE (' || status_code || ')'
       END AS STATUT,
       COUNT(*) AS NB
FROM   fnd_concurrent_requests
WHERE  actual_start_date >= TRUNC(SYSDATE - 1) + 19 / 24
AND    actual_start_date <  TRUNC(SYSDATE)      + 7 / 24
AND    requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
GROUP BY CASE status_code
             WHEN 'C' THEN 'OK'
             WHEN 'E' THEN '*** ERREUR ***'
             WHEN 'G' THEN 'WARNING'
             WHEN 'R' THEN 'EN COURS'
             WHEN 'W' THEN 'EN ATTENTE'
             ELSE 'AUTRE (' || status_code || ')'
         END
ORDER BY 1;
