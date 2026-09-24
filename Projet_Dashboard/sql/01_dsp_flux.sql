-- DSP - Detail des flux (fichiers)
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT 'DSP' AS SRC,
       TO_CHAR(date_creation, 'DD/MM/YY') AS DATE_CR,
       RTRIM(jour_creation) AS JOUR,
       -- Les fichiers de commandes arrivent nommes DSP01_PO_ENTETE_... :
       -- ni '%CDE%' ni 'ORDER%' ne les attrapaient, et ils tombaient tous
       -- dans AUTRE. Verifie sur les 9 derniers logs : COMMANDES n'y
       -- apparait jamais, alors qu'AUTRE est present chaque jour.
       CASE
           WHEN file_name LIKE '%SUP%'                              THEN 'FOURNISSEURS'
           WHEN file_name LIKE '%PO[_]%' ESCAPE '['
             OR file_name LIKE '%CDE%'
             OR file_name LIKE 'ORDER%'                             THEN 'COMMANDES'
           WHEN file_name LIKE '%REC%'                              THEN 'RECEPTIONS'
           WHEN file_name LIKE '%DEB%' OR file_name LIKE '%DEBLOC%' THEN 'DEBLOCAGE'
           ELSE 'AUTRE'
       END AS TYPE_FLUX,
       file_name
FROM (
    SELECT DISTINCT TRUNC(dih.creation_date) AS date_creation,
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour_creation,
           dih.file_name
    FROM   dka_ipofrs_hist_entetes dih
    WHERE  dih.creation_date > SYSDATE - &nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_ipocde_hist_headers dih
    WHERE  dih.creation_date > SYSDATE - &nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_iporec_hist_interface dih
    WHERE  dih.creation_date > SYSDATE - &nb_jours_histo
    UNION ALL
    SELECT DISTINCT TRUNC(dih.creation_date),
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'),
           dih.file_name
    FROM   dka_iapfac_debloc_hist_interf dih
    WHERE  dih.creation_date > SYSDATE - &nb_jours_histo
)
ORDER BY date_creation DESC, TYPE_FLUX, file_name;
