-- DSP - Synthese par jour et type
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

-- Cette synthese comptait des libelles constants issus d'un DISTINCT, donc
-- au plus 1 par table et par jour : elle indiquait "1 fournisseur" un jour ou
-- 2 fichiers etaient arrives (log du 28/07). On compte desormais les fichiers.
SELECT TO_CHAR(date_creation, 'DD/MM/YY') AS DATE_CR,
       RTRIM(jour_creation)               AS JOUR,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'FOURNISSEURS' THEN file_name END) AS NB_SUP,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'COMMANDES'    THEN file_name END) AS NB_CDE,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'RECEPTIONS'   THEN file_name END) AS NB_REC,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'DEBLOCAGE'    THEN file_name END) AS NB_DEB,
       COUNT(DISTINCT CASE WHEN TYPE_FLUX = 'AUTRE'        THEN file_name END) AS NB_AUT,
       COUNT(DISTINCT file_name) AS TOTAL
FROM (
    SELECT TRUNC(dih.creation_date) AS date_creation,
           TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH') AS jour_creation,
           dih.file_name,
           CASE
               WHEN dih.file_name LIKE '%SUP%'                                  THEN 'FOURNISSEURS'
               WHEN dih.file_name LIKE '%PO[_]%' ESCAPE '['
                 OR dih.file_name LIKE '%CDE%'
                 OR dih.file_name LIKE 'ORDER%'                                 THEN 'COMMANDES'
               WHEN dih.file_name LIKE '%REC%'                                  THEN 'RECEPTIONS'
               WHEN dih.file_name LIKE '%DEB%' OR dih.file_name LIKE '%DEBLOC%' THEN 'DEBLOCAGE'
               ELSE 'AUTRE'
           END AS TYPE_FLUX
    FROM   dka_ipofrs_hist_entetes dih WHERE dih.creation_date > SYSDATE - &nb_jours_histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), dih.file_name,
           CASE WHEN dih.file_name LIKE '%PO[_]%' ESCAPE '[' OR dih.file_name LIKE '%CDE%' THEN 'COMMANDES' ELSE 'AUTRE' END
    FROM   dka_ipocde_hist_headers dih WHERE dih.creation_date > SYSDATE - &nb_jours_histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), dih.file_name,
           'RECEPTIONS'
    FROM   dka_iporec_hist_interface dih WHERE dih.creation_date > SYSDATE - &nb_jours_histo
    UNION ALL
    SELECT TRUNC(dih.creation_date), TO_CHAR(dih.creation_date, 'DAY', 'NLS_DATE_LANGUAGE=FRENCH'), dih.file_name,
           'DEBLOCAGE'
    FROM   dka_iapfac_debloc_hist_interf dih WHERE dih.creation_date > SYSDATE - &nb_jours_histo
)
GROUP BY date_creation, jour_creation
ORDER BY date_creation DESC;
