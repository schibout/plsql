-- =====================================================================
-- Inventaire des Jobs Control-M FINFIN et Programmes Concurrents
-- =====================================================================
-- Date de creation : 06/02/2026
-- Auteur : GitHub Copilot
-- Base de donnees : Oracle EBS 12.2.13
--
-- OBJECTIF : Lister tous les jobs Control-M (FINFIN_%) avec le
--            script shell lance, les statistiques d'execution,
--            la frequence et le taux de succes.
--
-- NOTE IMPORTANTE : Tous les jobs Control-M passent par le lanceur
--   generique DKA_SLAUNCHER (Host Shell Script). Le vrai traitement
--   est identifie par le nom du script .sh dans la DESCRIPTION de
--   la requete concurrente (= nom du job Control-M).
--
-- VOIR : Analyse_Chaine_ControlM_Concsub.md
-- =====================================================================


-- =====================================================================
-- 1) INVENTAIRE COMPLET DES JOBS FINFIN (90 derniers jours)
-- =====================================================================
-- Chaque ligne = 1 job Control-M avec son script et ses statistiques
-- =====================================================================
SELECT 
    FCR.DESCRIPTION                                    AS JOB_CONTROLM,
    -- Extraction du type de chaine depuis le nom du job
    SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1) AS CODE_JOB,
    -- Extraction du nom du script
    SUBSTR(FCR.DESCRIPTION, INSTR(FCR.DESCRIPTION, ': ') + 2) AS SCRIPT_SHELL,
    -- Frequence (J=Jour, H=Hebdo, M=Mensuel, Q=Quotidien)
    SUBSTR(
        SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1),
        -1
    )                                                  AS FREQUENCE_CODE,
    DECODE(
        SUBSTR(SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1), -1),
        'Q', 'Quotidien',
        'H', 'Hebdomadaire',
        'M', 'Mensuel',
        'J', 'Journalier',
        'Autre'
    )                                                  AS FREQUENCE,
    -- Type de traitement (IMP=Import, WRK=Work, EXP=Export, CTL=Controle, STP/STR=Start/Stop)
    REGEXP_SUBSTR(
        SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1),
        '(IMP|WRK|EXP|CTL|STP|STR)[0-9]+',
        1, 1
    )                                                  AS TYPE_TRAITEMENT,
    -- Statistiques
    COUNT(*)                                           AS NB_EXEC_90J,
    SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END) AS NB_SUCCES,
    SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END) AS NB_ERREURS,
    SUM(CASE WHEN FCR.STATUS_CODE = 'G' THEN 1 ELSE 0 END) AS NB_WARNINGS,
    -- Taux de succes
    ROUND(
        SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        1
    )                                                  AS TAUX_SUCCES_PCT,
    -- Durees
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN,
    ROUND(MAX((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MAX_MIN,
    ROUND(MIN((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MIN_MIN,
    -- Dates
    TO_CHAR(MAX(FCR.ACTUAL_START_DATE), 'DD/MM/YYYY HH24:MI') AS DERNIERE_EXEC,
    TO_CHAR(MIN(FCR.ACTUAL_START_DATE), 'DD/MM/YYYY HH24:MI') AS PREMIERE_EXEC
FROM APPS.FND_CONCURRENT_REQUESTS FCR
WHERE FCR.DESCRIPTION LIKE 'FINFIN_%'
  AND FCR.REQUEST_DATE >= SYSDATE - 90
  AND FCR.PHASE_CODE = 'C'
GROUP BY FCR.DESCRIPTION
ORDER BY FCR.DESCRIPTION;


-- =====================================================================
-- 2) SYNTHESE PAR FREQUENCE (Q=Quotidien, H=Hebdo, M=Mensuel)
-- =====================================================================
SELECT 
    DECODE(
        SUBSTR(SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1), -1),
        'Q', 'Quotidien',
        'H', 'Hebdomadaire',
        'M', 'Mensuel',
        'J', 'Journalier',
        'Autre'
    )                                   AS FREQUENCE,
    COUNT(DISTINCT FCR.DESCRIPTION)     AS NB_JOBS_DISTINCTS,
    COUNT(*)                            AS NB_EXEC_TOTAL,
    SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END) AS TOTAL_SUCCES,
    SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END) AS TOTAL_ERREURS,
    SUM(CASE WHEN FCR.STATUS_CODE = 'G' THEN 1 ELSE 0 END) AS TOTAL_WARNINGS,
    ROUND(
        SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        1
    )                                   AS TAUX_SUCCES_PCT
FROM APPS.FND_CONCURRENT_REQUESTS FCR
WHERE FCR.DESCRIPTION LIKE 'FINFIN_%'
  AND FCR.REQUEST_DATE >= SYSDATE - 90
  AND FCR.PHASE_CODE = 'C'
GROUP BY 
    DECODE(
        SUBSTR(SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1), -1),
        'Q', 'Quotidien',
        'H', 'Hebdomadaire',
        'M', 'Mensuel',
        'J', 'Journalier',
        'Autre'
    )
ORDER BY NB_EXEC_TOTAL DESC;


-- =====================================================================
-- 3) SYNTHESE PAR TYPE DE TRAITEMENT (WRK, IMP, CTL, EXP, STP/STR)
-- =====================================================================
SELECT 
    DECODE(
        REGEXP_SUBSTR(
            SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1),
            '(IMP|WRK|EXP|CTL|STP|STR)',
            1, 1
        ),
        'WRK', 'Traitement (WRK)',
        'IMP', 'Import (IMP)',
        'EXP', 'Export (EXP)',
        'CTL', 'Controle (CTL)',
        'STP', 'Demarrage (STP)',
        'STR', 'Demarrage (STR)',
        'Autre'
    )                                   AS TYPE_TRAITEMENT,
    COUNT(DISTINCT FCR.DESCRIPTION)     AS NB_JOBS_DISTINCTS,
    COUNT(*)                            AS NB_EXEC_TOTAL,
    SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END) AS TOTAL_ERREURS,
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN
FROM APPS.FND_CONCURRENT_REQUESTS FCR
WHERE FCR.DESCRIPTION LIKE 'FINFIN_%'
  AND FCR.REQUEST_DATE >= SYSDATE - 90
  AND FCR.PHASE_CODE = 'C'
GROUP BY 
    DECODE(
        REGEXP_SUBSTR(
            SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1),
            '(IMP|WRK|EXP|CTL|STP|STR)',
            1, 1
        ),
        'WRK', 'Traitement (WRK)',
        'IMP', 'Import (IMP)',
        'EXP', 'Export (EXP)',
        'CTL', 'Controle (CTL)',
        'STP', 'Demarrage (STP)',
        'STR', 'Demarrage (STR)',
        'Autre'
    )
ORDER BY NB_EXEC_TOTAL DESC;


-- =====================================================================
-- 4) TOP 20 JOBS LES PLUS LONGS (duree max)
-- =====================================================================
SELECT 
    FCR.DESCRIPTION                     AS JOB_CONTROLM,
    COUNT(*)                            AS NB_EXEC,
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN,
    ROUND(MAX((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MAX_MIN,
    ROUND(
        SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        1
    )                                   AS TAUX_SUCCES_PCT
FROM APPS.FND_CONCURRENT_REQUESTS FCR
WHERE FCR.DESCRIPTION LIKE 'FINFIN_%'
  AND FCR.REQUEST_DATE >= SYSDATE - 90
  AND FCR.PHASE_CODE = 'C'
GROUP BY FCR.DESCRIPTION
ORDER BY DUREE_MAX_MIN DESC
FETCH FIRST 20 ROWS ONLY;


-- =====================================================================
-- 5) JOBS EN ECHEC OU WARNING (taux succes < 100%)
-- =====================================================================
SELECT 
    FCR.DESCRIPTION                     AS JOB_CONTROLM,
    COUNT(*)                            AS NB_EXEC,
    SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END) AS SUCCES,
    SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END) AS ERREURS,
    SUM(CASE WHEN FCR.STATUS_CODE = 'G' THEN 1 ELSE 0 END) AS WARNINGS,
    ROUND(
        SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        1
    )                                   AS TAUX_SUCCES_PCT,
    TO_CHAR(MAX(CASE WHEN FCR.STATUS_CODE = 'E' THEN FCR.ACTUAL_START_DATE END), 'DD/MM/YYYY HH24:MI') AS DERNIERE_ERREUR
FROM APPS.FND_CONCURRENT_REQUESTS FCR
WHERE FCR.DESCRIPTION LIKE 'FINFIN_%'
  AND FCR.REQUEST_DATE >= SYSDATE - 90
  AND FCR.PHASE_CODE = 'C'
GROUP BY FCR.DESCRIPTION
HAVING SUM(CASE WHEN FCR.STATUS_CODE IN ('E', 'G') THEN 1 ELSE 0 END) > 0
ORDER BY 
    SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END) DESC,
    SUM(CASE WHEN FCR.STATUS_CODE = 'G' THEN 1 ELSE 0 END) DESC;


-- =====================================================================
-- 6) PLAGE HORAIRE D'EXECUTION DES JOBS FINFIN
-- =====================================================================
SELECT 
    CASE
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 0 AND 6   THEN '1-NUIT (00h-07h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 7 AND 8   THEN '2-MATIN (07h-09h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 9 AND 12  THEN '3-MATINEE (09h-13h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 13 AND 17 THEN '4-APRES-MIDI (13h-18h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 18 AND 20 THEN '5-SOIR (18h-21h)'
        ELSE '6-NUIT (21h-00h)'
    END                                 AS PLAGE_HORAIRE,
    COUNT(DISTINCT FCR.DESCRIPTION)     AS NB_JOBS_DISTINCTS,
    COUNT(*)                            AS NB_EXEC_TOTAL,
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN
FROM APPS.FND_CONCURRENT_REQUESTS FCR
WHERE FCR.DESCRIPTION LIKE 'FINFIN_%'
  AND FCR.REQUEST_DATE >= SYSDATE - 90
  AND FCR.PHASE_CODE = 'C'
  AND FCR.ACTUAL_START_DATE IS NOT NULL
GROUP BY 
    CASE
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 0 AND 6   THEN '1-NUIT (00h-07h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 7 AND 8   THEN '2-MATIN (07h-09h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 9 AND 12  THEN '3-MATINEE (09h-13h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 13 AND 17 THEN '4-APRES-MIDI (13h-18h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 18 AND 20 THEN '5-SOIR (18h-21h)'
        ELSE '6-NUIT (21h-00h)'
    END
ORDER BY PLAGE_HORAIRE;


-- =====================================================================
-- 7) LISTE DES SCRIPTS UNIQUES ET LEUR UTILISATION
-- =====================================================================
-- Un meme script peut etre appele par plusieurs jobs Control-M
-- =====================================================================
SELECT
    SUBSTR(FCR.DESCRIPTION, INSTR(FCR.DESCRIPTION, ': ') + 2) AS SCRIPT_SHELL,
    COUNT(DISTINCT SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1)) AS NB_JOBS_UTILISENT,
    LISTAGG(
        DISTINCT SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1), 
        ', '
    ) WITHIN GROUP (ORDER BY SUBSTR(FCR.DESCRIPTION, 1, INSTR(FCR.DESCRIPTION, ' ') - 1)) AS JOBS_CONTROLM,
    COUNT(*)                            AS NB_EXEC_TOTAL,
    SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END) AS TOTAL_ERREURS,
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN
FROM APPS.FND_CONCURRENT_REQUESTS FCR
WHERE FCR.DESCRIPTION LIKE 'FINFIN_%'
  AND FCR.REQUEST_DATE >= SYSDATE - 90
  AND FCR.PHASE_CODE = 'C'
GROUP BY SUBSTR(FCR.DESCRIPTION, INSTR(FCR.DESCRIPTION, ': ') + 2)
ORDER BY NB_EXEC_TOTAL DESC;
