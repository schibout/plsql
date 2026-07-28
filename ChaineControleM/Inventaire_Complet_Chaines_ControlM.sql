-- =====================================================================
-- Inventaire Complet des ChaÃ®nes Control-M et Programmes Concurrents
-- =====================================================================
-- Date de crÃ©ation : 06/02/2026
-- Auteur : GitHub Copilot
-- Base de donnÃ©es : Oracle EBS 12.2.13
--
-- OBJECTIF : Lister tous les types de chaÃ®nes Control-M, les 
--            programmes concurrents associÃ©s, leur mÃ©thode d'exÃ©cution,
--            frÃ©quence, durÃ©e moyenne, et statut.
--
-- VOIR : Analyse_Chaine_ControlM_Concsub.md
-- =====================================================================


-- =====================================================================
-- 1) TOUS LES PROGRAMMES CUSTOM (DKA) AVEC DÃ‰TAILS D'EXÃ‰CUTION
-- =====================================================================
-- Ces programmes sont typiquement ceux orchestrÃ©s par Control-M
-- via concsub. Inclut les statistiques des 30 derniers jours.
-- =====================================================================
SELECT
    FA.APPLICATION_SHORT_NAME                          AS APPLICATION,
    FCP.CONCURRENT_PROGRAM_NAME                        AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME                   AS NOM_COMPLET,
    FE.EXECUTABLE_NAME                                 AS EXECUTABLE,
    FE.EXECUTION_FILE_NAME                             AS FICHIER_EXECUTION,
    DECODE(FE.EXECUTION_METHOD_CODE,
        'P', 'PL/SQL Stored Procedure',
        'L', 'SQL*Loader',
        'Q', 'SQL*Plus',
        'H', 'Host (Shell Script)',
        'I', 'PL/SQL (Immediate)',
        'A', 'Spawned',
        'J', 'Java Stored Procedure',
        'K', 'Java Concurrent',
        'M', 'Multi Language Function',
        'S', 'Immediate',
        'X', 'FlexRpt',
        'B', 'Request Set Stage',
        FE.EXECUTION_METHOD_CODE
    )                                                  AS TYPE_EXECUTION,
    FE.EXECUTION_METHOD_CODE                           AS CODE_TYPE,
    FCP.ENABLED_FLAG                                   AS ACTIF,
    FCP.DESCRIPTION                                    AS DESCRIPTION,
    -- Statistiques 30 derniers jours
    STATS.NB_EXECUTIONS,
    STATS.NB_SUCCES,
    STATS.NB_ERREURS,
    STATS.NB_AVERTISSEMENTS,
    STATS.DUREE_MOY_MIN,
    STATS.DUREE_MAX_MIN,
    STATS.DERNIERE_EXECUTION,
    STATS.UTILISATEUR_PRINCIPAL
FROM
    APPS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    LEFT JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
    -- Sous-requÃªte pour les statistiques des 30 derniers jours
    LEFT JOIN (
        SELECT
            FCR.CONCURRENT_PROGRAM_ID,
            FCR.PROGRAM_APPLICATION_ID,
            COUNT(*)                                                        AS NB_EXECUTIONS,
            SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END)         AS NB_SUCCES,
            SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END)         AS NB_ERREURS,
            SUM(CASE WHEN FCR.STATUS_CODE = 'G' THEN 1 ELSE 0 END)         AS NB_AVERTISSEMENTS,
            ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN,
            ROUND(MAX((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MAX_MIN,
            MAX(FCR.ACTUAL_START_DATE)                                      AS DERNIERE_EXECUTION,
            -- Utilisateur qui soumet le plus souvent (= user technique Control-M)
            (SELECT FU2.USER_NAME
             FROM APPS.FND_CONCURRENT_REQUESTS FCR2
             JOIN APPS.FND_USER FU2 ON FU2.USER_ID = FCR2.REQUESTED_BY
             WHERE FCR2.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
               AND FCR2.PROGRAM_APPLICATION_ID = FCR.PROGRAM_APPLICATION_ID
               AND FCR2.REQUEST_DATE >= SYSDATE - 30
             GROUP BY FU2.USER_NAME
             ORDER BY COUNT(*) DESC
             FETCH FIRST 1 ROW ONLY
            )                                                               AS UTILISATEUR_PRINCIPAL
        FROM
            APPS.FND_CONCURRENT_REQUESTS FCR
        WHERE
            FCR.REQUEST_DATE >= SYSDATE - 30
            AND FCR.PHASE_CODE = 'C'  -- TerminÃ©s uniquement
        GROUP BY
            FCR.CONCURRENT_PROGRAM_ID,
            FCR.PROGRAM_APPLICATION_ID
    ) STATS
        ON STATS.CONCURRENT_PROGRAM_ID = FCP.CONCURRENT_PROGRAM_ID
        AND STATS.PROGRAM_APPLICATION_ID = FCP.APPLICATION_ID
WHERE
    (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
     OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
    AND FCP.ENABLED_FLAG = 'Y'
ORDER BY
    FA.APPLICATION_SHORT_NAME,
    FE.EXECUTION_METHOD_CODE,
    FCP.CONCURRENT_PROGRAM_NAME;


-- =====================================================================
-- 2) RÃ‰PARTITION PAR TYPE D'EXÃ‰CUTION (Shell, PL/SQL, SQL*Loader, etc.)
-- =====================================================================
SELECT
    DECODE(FE.EXECUTION_METHOD_CODE,
        'P', 'PL/SQL Stored Procedure',
        'L', 'SQL*Loader',
        'Q', 'SQL*Plus',
        'H', 'Host (Shell Script)',
        'I', 'PL/SQL (Immediate)',
        'A', 'Spawned',
        'J', 'Java Stored Procedure',
        'K', 'Java Concurrent',
        'M', 'Multi Language Function',
        'S', 'Immediate',
        'X', 'FlexRpt',
        'B', 'Request Set Stage',
        FE.EXECUTION_METHOD_CODE
    )                                   AS TYPE_EXECUTION,
    COUNT(*)                            AS NB_PROGRAMMES,
    SUM(CASE WHEN FCP.ENABLED_FLAG = 'Y' THEN 1 ELSE 0 END) AS NB_ACTIFS,
    SUM(CASE WHEN FCP.ENABLED_FLAG = 'N' THEN 1 ELSE 0 END) AS NB_INACTIFS
FROM
    APPS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    LEFT JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
    OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%'
GROUP BY
    FE.EXECUTION_METHOD_CODE,
    DECODE(FE.EXECUTION_METHOD_CODE,
        'P', 'PL/SQL Stored Procedure',
        'L', 'SQL*Loader',
        'Q', 'SQL*Plus',
        'H', 'Host (Shell Script)',
        'I', 'PL/SQL (Immediate)',
        'A', 'Spawned',
        'J', 'Java Stored Procedure',
        'K', 'Java Concurrent',
        'M', 'Multi Language Function',
        'S', 'Immediate',
        'X', 'FlexRpt',
        'B', 'Request Set Stage',
        FE.EXECUTION_METHOD_CODE
    )
ORDER BY
    NB_PROGRAMMES DESC;


-- =====================================================================
-- 3) PROGRAMMES DE TYPE HOST/SHELL (lancÃ©s via concsub par Control-M)
-- =====================================================================
-- Ce sont les programmes directement mappÃ©s aux scripts .sh
-- appelÃ©s par Control-M
-- =====================================================================
SELECT
    FA.APPLICATION_SHORT_NAME          AS APPLICATION,
    FCP.CONCURRENT_PROGRAM_NAME        AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME   AS NOM_COMPLET,
    FE.EXECUTABLE_NAME                 AS EXECUTABLE,
    FE.EXECUTION_FILE_NAME             AS SCRIPT_SHELL,
    FCP.DESCRIPTION                    AS DESCRIPTION,
    FCP.ENABLED_FLAG                   AS ACTIF
FROM
    APPS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    FE.EXECUTION_METHOD_CODE = 'H'  -- Host = Shell Script
    AND (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
         OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
ORDER BY
    FA.APPLICATION_SHORT_NAME,
    FCP.CONCURRENT_PROGRAM_NAME;


-- =====================================================================
-- 4) PROGRAMMES PL/SQL (procÃ©dures stockÃ©es appelÃ©es par concsub)
-- =====================================================================
SELECT
    FA.APPLICATION_SHORT_NAME          AS APPLICATION,
    FCP.CONCURRENT_PROGRAM_NAME        AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME   AS NOM_COMPLET,
    FE.EXECUTABLE_NAME                 AS EXECUTABLE,
    FE.EXECUTION_FILE_NAME             AS PROCEDURE_PLSQL,
    FCP.DESCRIPTION                    AS DESCRIPTION,
    FCP.ENABLED_FLAG                   AS ACTIF
FROM
    APPS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    FE.EXECUTION_METHOD_CODE IN ('P', 'I')  -- PL/SQL
    AND (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
         OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
ORDER BY
    FA.APPLICATION_SHORT_NAME,
    FCP.CONCURRENT_PROGRAM_NAME;


-- =====================================================================
-- 5) PROGRAMMES SQL*LOADER (chargement de donnÃ©es)
-- =====================================================================
SELECT
    FA.APPLICATION_SHORT_NAME          AS APPLICATION,
    FCP.CONCURRENT_PROGRAM_NAME        AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME   AS NOM_COMPLET,
    FE.EXECUTABLE_NAME                 AS EXECUTABLE,
    FE.EXECUTION_FILE_NAME             AS FICHIER_CTL,
    FCP.DESCRIPTION                    AS DESCRIPTION,
    FCP.ENABLED_FLAG                   AS ACTIF
FROM
    APPS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    FE.EXECUTION_METHOD_CODE = 'L'  -- SQL*Loader
    AND (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
         OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
ORDER BY
    FA.APPLICATION_SHORT_NAME,
    FCP.CONCURRENT_PROGRAM_NAME;


-- =====================================================================
-- 6) PROGRAMMES JAVA
-- =====================================================================
SELECT
    FA.APPLICATION_SHORT_NAME          AS APPLICATION,
    FCP.CONCURRENT_PROGRAM_NAME        AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME   AS NOM_COMPLET,
    FE.EXECUTABLE_NAME                 AS EXECUTABLE,
    FE.EXECUTION_FILE_NAME             AS CLASSE_JAVA,
    FCP.DESCRIPTION                    AS DESCRIPTION,
    FCP.ENABLED_FLAG                   AS ACTIF
FROM
    APPS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    FE.EXECUTION_METHOD_CODE IN ('J', 'K')  -- Java
    AND (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
         OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
ORDER BY
    FA.APPLICATION_SHORT_NAME,
    FCP.CONCURRENT_PROGRAM_NAME;


-- =====================================================================
-- 7) REQUEST SETS (ensembles de requÃªtes / chaÃ®nes de programmes)
-- =====================================================================
-- Les Request Sets regroupent plusieurs programmes en une chaÃ®ne
-- Ce sont souvent les "chaÃ®nes" au sens Control-M
-- =====================================================================
SELECT
    FA.APPLICATION_SHORT_NAME                AS APPLICATION,
    FRS.REQUEST_SET_NAME                     AS NOM_COURT_SET,
    FRS.USER_REQUEST_SET_NAME                AS NOM_COMPLET_SET,
    FRS.DESCRIPTION                          AS DESCRIPTION_SET,
    FRSS.SET_STAGE_ID                        AS ETAPE_ID,
    FRSS.DISPLAY_SEQUENCE                    AS SEQUENCE,
    FRSS.USER_STAGE_NAME                     AS NOM_ETAPE,
    DECODE(FRSS.CRITICAL,
        'Y', 'Oui', 'N', 'Non', FRSS.CRITICAL) AS CRITIQUE,
    -- Programmes dans chaque Ã©tape
    FCP.CONCURRENT_PROGRAM_NAME              AS PROGRAMME_NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME         AS PROGRAMME_NOM_COMPLET,
    FA2.APPLICATION_SHORT_NAME               AS PROGRAMME_APPLICATION,
    DECODE(FE.EXECUTION_METHOD_CODE,
        'P', 'PL/SQL', 'H', 'Shell', 'L', 'SQL*Loader',
        'Q', 'SQL*Plus', 'J', 'Java',
        FE.EXECUTION_METHOD_CODE
    )                                        AS TYPE_PROGRAMME
FROM
    APPS.FND_REQUEST_SETS_VL FRS
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FRS.APPLICATION_ID
    JOIN APPS.FND_REQUEST_SET_STAGES_VL FRSS
        ON FRSS.SET_APPLICATION_ID = FRS.APPLICATION_ID
        AND FRSS.REQUEST_SET_ID = FRS.REQUEST_SET_ID
    LEFT JOIN APPS.FND_REQUEST_SET_PROGRAMS FRSP
        ON FRSP.SET_APPLICATION_ID = FRS.APPLICATION_ID
        AND FRSP.REQUEST_SET_ID = FRS.REQUEST_SET_ID
        AND FRSP.SET_STAGE_ID = FRSS.SET_STAGE_ID
    LEFT JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP
        ON FCP.CONCURRENT_PROGRAM_ID = FRSP.CONCURRENT_PROGRAM_ID
        AND FCP.APPLICATION_ID = FRSP.PROGRAM_APPLICATION_ID
    LEFT JOIN APPS.FND_APPLICATION_VL FA2
        ON FA2.APPLICATION_ID = FCP.APPLICATION_ID
    LEFT JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
    OR FRS.REQUEST_SET_NAME LIKE 'DKA%'
ORDER BY
    FRS.REQUEST_SET_NAME,
    FRSS.DISPLAY_SEQUENCE;


-- =====================================================================
-- 8) TOP 30 PROGRAMMES LES PLUS EXÃ‰CUTÃ‰S (30 derniers jours)
-- =====================================================================
-- Permet d'identifier les chaÃ®nes Control-M les plus actives
-- =====================================================================
SELECT
    FA.APPLICATION_SHORT_NAME                AS APPLICATION,
    FCP.CONCURRENT_PROGRAM_NAME              AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME         AS NOM_COMPLET,
    DECODE(FE.EXECUTION_METHOD_CODE,
        'P', 'PL/SQL', 'H', 'Shell', 'L', 'SQL*Loader',
        'Q', 'SQL*Plus', 'J', 'Java', 'I', 'PL/SQL(I)',
        FE.EXECUTION_METHOD_CODE
    )                                        AS TYPE,
    COUNT(*)                                 AS NB_EXECUTIONS,
    SUM(CASE WHEN FCR.STATUS_CODE = 'C' THEN 1 ELSE 0 END) AS SUCCES,
    SUM(CASE WHEN FCR.STATUS_CODE = 'E' THEN 1 ELSE 0 END) AS ERREURS,
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN,
    ROUND(MAX((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MAX_MIN,
    TO_CHAR(MAX(FCR.ACTUAL_START_DATE), 'DD/MM/YYYY HH24:MI') AS DERNIERE_EXEC
FROM
    APPS.FND_CONCURRENT_REQUESTS FCR
    JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP
        ON FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
        AND FCP.APPLICATION_ID = FCR.PROGRAM_APPLICATION_ID
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    LEFT JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
     OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
    AND FCR.REQUEST_DATE >= SYSDATE - 30
    AND FCR.PHASE_CODE = 'C'
GROUP BY
    FA.APPLICATION_SHORT_NAME,
    FCP.CONCURRENT_PROGRAM_NAME,
    FCP.USER_CONCURRENT_PROGRAM_NAME,
    FE.EXECUTION_METHOD_CODE
ORDER BY
    NB_EXECUTIONS DESC
FETCH FIRST 30 ROWS ONLY;


-- =====================================================================
-- 9) PROGRAMMES EN ERREUR (30 derniers jours)
-- =====================================================================
SELECT
    FA.APPLICATION_SHORT_NAME                AS APPLICATION,
    FCP.CONCURRENT_PROGRAM_NAME              AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME         AS NOM_COMPLET,
    COUNT(*)                                 AS NB_ERREURS,
    TO_CHAR(MAX(FCR.ACTUAL_START_DATE), 'DD/MM/YYYY HH24:MI') AS DERNIERE_ERREUR,
    LISTAGG(DISTINCT FU.USER_NAME, ', ') WITHIN GROUP (ORDER BY FU.USER_NAME) AS UTILISATEURS
FROM
    APPS.FND_CONCURRENT_REQUESTS FCR
    JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP
        ON FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
        AND FCP.APPLICATION_ID = FCR.PROGRAM_APPLICATION_ID
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    JOIN APPS.FND_USER FU
        ON FU.USER_ID = FCR.REQUESTED_BY
WHERE
    (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
     OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
    AND FCR.STATUS_CODE = 'E'
    AND FCR.PHASE_CODE = 'C'
    AND FCR.REQUEST_DATE >= SYSDATE - 30
GROUP BY
    FA.APPLICATION_SHORT_NAME,
    FCP.CONCURRENT_PROGRAM_NAME,
    FCP.USER_CONCURRENT_PROGRAM_NAME
ORDER BY
    NB_ERREURS DESC;


-- =====================================================================
-- 10) PLAGE HORAIRE D'EXÃ‰CUTION (pour identifier batch nuit / jour)
-- =====================================================================
SELECT
    DECODE(
        CASE
            WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 0 AND 6   THEN 'NUIT (00h-07h)'
            WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 7 AND 8   THEN 'MATIN (07h-09h)'
            WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 9 AND 17  THEN 'JOURNÃ‰E (09h-18h)'
            WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 18 AND 20 THEN 'SOIR (18h-21h)'
            ELSE 'NUIT (21h-00h)'
        END,
        NULL, 'INCONNU',
        CASE
            WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 0 AND 6   THEN 'NUIT (00h-07h)'
            WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 7 AND 8   THEN 'MATIN (07h-09h)'
            WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 9 AND 17  THEN 'JOURNÃ‰E (09h-18h)'
            WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 18 AND 20 THEN 'SOIR (18h-21h)'
            ELSE 'NUIT (21h-00h)'
        END
    )                                        AS PLAGE_HORAIRE,
    FCP.CONCURRENT_PROGRAM_NAME              AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME         AS NOM_COMPLET,
    COUNT(*)                                 AS NB_EXEC,
    ROUND(AVG((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60), 2) AS DUREE_MOY_MIN
FROM
    APPS.FND_CONCURRENT_REQUESTS FCR
    JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP
        ON FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
        AND FCP.APPLICATION_ID = FCR.PROGRAM_APPLICATION_ID
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
WHERE
    (FA.APPLICATION_SHORT_NAME LIKE 'DKA%'
     OR FCP.CONCURRENT_PROGRAM_NAME LIKE 'DKA%')
    AND FCR.REQUEST_DATE >= SYSDATE - 30
    AND FCR.PHASE_CODE = 'C'
    AND FCR.ACTUAL_START_DATE IS NOT NULL
GROUP BY
    CASE
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 0 AND 6   THEN 'NUIT (00h-07h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 7 AND 8   THEN 'MATIN (07h-09h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 9 AND 17  THEN 'JOURNÃ‰E (09h-18h)'
        WHEN TO_NUMBER(TO_CHAR(FCR.ACTUAL_START_DATE, 'HH24')) BETWEEN 18 AND 20 THEN 'SOIR (18h-21h)'
        ELSE 'NUIT (21h-00h)'
    END,
    FCP.CONCURRENT_PROGRAM_NAME,
    FCP.USER_CONCURRENT_PROGRAM_NAME
ORDER BY
    PLAGE_HORAIRE,
    NB_EXEC DESC;
