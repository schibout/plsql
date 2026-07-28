-- Identification des traitements de la nuit applicative (hier 19h00 à aujourd'hui 07h00)
-- Fenêtre : 19h00 la veille jusqu'à 07h00 le jour même

SELECT 
    fcr.request_id,
    fcp.user_concurrent_program_name as programme,
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as heure_debut,
    TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') as heure_fin,
    CASE fcr.status_code
        WHEN 'C' THEN 'Normal'
        WHEN 'E' THEN 'Erreur'
        WHEN 'G' THEN 'Warning'
        WHEN 'X' THEN 'Terminé'
        WHEN 'D' THEN 'Annulé'
        WHEN 'U' THEN 'Désactivé'
        WHEN 'R' THEN 'En cours'
        WHEN 'W' THEN 'En attente'
        ELSE 'Autre (' || fcr.status_code || ')'
    END as statut,
    CASE 
        WHEN fcr.status_code IN ('E', 'X', 'D', 'U') THEN 'KO'
        WHEN fcr.status_code = 'G' THEN 'WARNING'
        WHEN fcr.status_code = 'C' THEN 'OK'
        ELSE 'EN_COURS'
    END as resultat,
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24, 2) as duree_heures,
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24 * 60, 2) as duree_minutes,
    fcr.completion_text as message,
    fcr.argument_text as parametres
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcr.actual_start_date >= TRUNC(SYSDATE - 1) + 19/24  -- Hier à 19h00
  AND fcr.actual_start_date < TRUNC(SYSDATE) + 7/24       -- Aujourd'hui à 07h00
ORDER BY fcr.actual_start_date;

-- Version alternative : chercher tous les traitements longs du 27/11
-- (peu importe l'heure de début, tant qu'ils ont duré plusieurs heures)

/*
SELECT 
    fcr.request_id,
    fcp.user_concurrent_program_name as programme,
    TO_CHAR(fcr.actual_start_date, 'DD/MM/YYYY HH24:MI:SS') as heure_debut,
    TO_CHAR(fcr.actual_completion_date, 'DD/MM/YYYY HH24:MI:SS') as heure_fin,
    fcr.phase_code,
    fcr.status_code,
    ROUND((fcr.actual_completion_date - fcr.actual_start_date) * 24, 2) as duree_heures,
    fcr.completion_text as message
FROM fnd_concurrent_requests fcr
JOIN fnd_concurrent_programs_vl fcp 
  ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE fcr.actual_start_date >= TO_DATE('27/11/2025 00:00:00', 'DD/MM/YYYY HH24:MI:SS')
  AND fcr.actual_start_date <= TO_DATE('27/11/2025 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
  AND (fcr.actual_completion_date - fcr.actual_start_date) * 24 >= 3
ORDER BY (fcr.actual_completion_date - fcr.actual_start_date) DESC;
*/

-- Pour voir le détail des logs d'un traitement spécifique :
/*
SELECT 
    fcr.request_id,
    fcr.logfile_name,
    fcr.outfile_name
FROM fnd_concurrent_requests fcr
WHERE fcr.request_id = <REQUEST_ID_A_REMPLACER>;
*/
