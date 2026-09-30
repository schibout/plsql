SELECT DECODE(fcr.request_type, 
              'M', fcr.description, 
              'S', fcr.description, 
              'B', fcr.description, 
              fcp.user_concurrent_program_name)                 AS PROGRAMME
       COUNT(*)                                                 AS nb_err,
       TO_CHAR(MIN(fcr.actual_start_date), 'DD/MM HH24:MI:SS')  AS PREMIERE,
       TO_CHAR(MAX(fcr.actual_start_date), 'DD/MM HH24:MI:SS')  AS DERNIERE,
       SUBSTR(MIN(fcr.completion_text), 1, 70)                  AS msg
  FROM fnd_concurrent_requests fcr
  JOIN fnd_concurrent_programs_vl fcp 
    ON fcr.concurrent_program_id = fcp.concurrent_program_id
   AND fcr.program_application_id = fcp.application_id -- Jointure ajoutée : Indispensable dans EBS
 WHERE fcr.actual_start_date >= TRUNC(SYSDATE - 1) + 19 / 24
   AND fcr.actual_start_date <  TRUNC(SYSDATE)     + 7 / 24
   AND fcr.requested_by IN (SELECT user_id 
                              FROM fnd_user 
                             WHERE user_name LIKE 'EXP%')
   AND fcr.status_code = 'E'
 GROUP BY DECODE(fcr.request_type, 
                 'M', fcr.description, 
                 'S', fcr.description, 
                 'B', fcr.description, 
                 fcp.user_concurrent_program_name)
 ORDER BY nb_err DESC;