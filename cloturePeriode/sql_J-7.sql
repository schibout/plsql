SELECT fcr.request_id                                              AS REQ_ID,
       fcp.user_concurrent_program_name                            AS PROGRAMME,
       fcr.phase_code                                              AS PHASE_CODE,
       flp.meaning                                                 AS PHASE_LIBELLE,
       fcr.status_code                                             AS STATUS_CODE,
       fls.meaning                                                 AS STATUS_LIBELLE,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS')          AS DEBUT,
       ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 1)       AS DUREE_MIN,
       SUBSTR(fcr.argument_text, 1, 50)                            AS PARAMETRES
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp 
  ON   fcr.concurrent_program_id = fcp.concurrent_program_id
 AND   fcr.program_application_id = fcp.application_id -- Bonne pratique R12
LEFT JOIN fnd_lookups flp 
  ON   flp.lookup_type = 'CP_PHASE_CODE'
 AND   flp.lookup_code = fcr.phase_code
LEFT JOIN fnd_lookups fls 
  ON   fls.lookup_type = 'CP_STATUS_CODE'
 AND   fls.lookup_code = fcr.status_code
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) + :v_heure_fermeture / 24
  AND  fcr.requested_by IN (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
--AND  fcp.user_concurrent_program_name LIKE '%Fermeture%'
ORDER BY fcr.actual_start_date;