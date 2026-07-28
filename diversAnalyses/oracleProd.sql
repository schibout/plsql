SELECT fcr.request_id                                                           AS REQ_ID,
       fcp.user_concurrent_program_name                                          AS PROGRAMME,--fcp.*,
       fcp.concurrent_program_name concurrent_program_name ,
       fcp.description description,
       TO_CHAR(fcr.actual_start_date, 'DD/MM HH24:MI:SS')                       AS DEBUT,
       ROUND((SYSDATE - fcr.actual_start_date) * 24 * 60, 1)                    AS DUREE_MIN,
       SUBSTR(fcr.argument_text, 1, 50)                                          AS PARAMETRES
FROM   fnd_concurrent_requests fcr
JOIN   fnd_concurrent_programs_vl fcp ON fcr.concurrent_program_id = fcp.concurrent_program_id
WHERE  fcr.actual_start_date >= TRUNC(SYSDATE - 1) 
AND    fcr.requested_by = (SELECT user_id FROM fnd_user WHERE user_name LIKE 'EXP%')
AND    upper(fcp.description) like '%FICHIER%'
--AND    fcp.concurrent_program_name NOT IN ('FAGDA','DKA_SLAUNCHER','FNDRSSTG','DKA_SAPFRSDUPLI_MAJ','DKA_ICENTREFIN','FNDRSSUB','DKA_IPROJECT','PACOANOR','PAPMPRPB','RACUSTSB','ARHDQMSS','DKA_IPOFRS_IVALUA','DKA_IPOCDE_IVALUA','XLAACCPB','DKA_IPOFRS_IVALUA_LOADER')
ORDER BY fcr.actual_start_date;


select distinct attribute10 from gl_interface -- where attribute10 like ''


select distinct attribute9, attribute10 from gl_je_lines where attribute10  like 'FAC02_SRC_ECRITURESGL_%'


SELECT 
    person_id,
    employee_number,
    full_name,attribute1,attribute2,attribute3,attribute4,attribute5,attribute6,attribute7,attribute8,attribute9,attribute10,
    effective_start_date,
    effective_end_date
FROM 
    per_people_f
WHERE 
    TRUNC(SYSDATE) BETWEEN effective_start_date AND effective_end_date
  