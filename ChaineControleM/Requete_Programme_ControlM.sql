-- =====================================================================
-- Recherche Programme Concurrent depuis nom Control-M (concsub)
-- =====================================================================
-- Date de crÃ©ation : 06/02/2026
-- Auteur : GitHub Copilot
-- Base de donnÃ©es : Oracle EBS 12.2.13
--
-- OBJECTIF : Ã€ partir du nom d'un job Control-M, retrouver la 
--            dÃ©finition complÃ¨te du programme concurrent Oracle EBS
--            lancÃ© via concsub.
--
-- UTILISATION :
--   Remplacer &NOM_PROGRAMME par le nom extrait du job Control-M.
--   Ex: Pour "FINFIN_J18TRT_04_IMP01_Q : DKA_IPAPROJETHRM_JOB.sh"
--       â†’ saisir DKA_IPAPROJETHRM
--
-- VOIR : Analyse_Chaine_ControlM_Concsub.md
-- =====================================================================

-- =====================================================================
-- 1) DÃ‰FINITION DU PROGRAMME CONCURRENT
-- =====================================================================
SELECT
    FCP.CONCURRENT_PROGRAM_NAME        AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME   AS NOM_UTILISATEUR,
    FA.APPLICATION_SHORT_NAME          AS APPLICATION,
    FA.APPLICATION_NAME                AS NOM_APPLICATION,
    FCP.DESCRIPTION                    AS DESCRIPTION,
    FE.EXECUTABLE_NAME                 AS EXECUTABLE,
    FE.EXECUTION_FILE_NAME             AS FICHIER_EXECUTION,
    DECODE(FE.EXECUTION_METHOD_CODE,
        'P', 'PL/SQL Stored Procedure',
        'L', 'SQL*Loader',
        'Q', 'SQL*Plus',
        'H', 'Host (Shell Script)',
        'I', 'PL/SQL Stored Procedure (Immediate)',
        'A', 'Spawned',
        'J', 'Java Stored Procedure',
        'K', 'Java Concurrent Program',
        'M', 'Multi Language Function',
        'S', 'Immediate',
        'X', 'FlexRpt',
        'B', 'Request Set Stage Function',
        FE.EXECUTION_METHOD_CODE
    )                                  AS METHODE_EXECUTION,
    FCP.ENABLED_FLAG                   AS ACTIF,
    FCP.CREATION_DATE                  AS DATE_CREATION,
    FCP.LAST_UPDATE_DATE               AS DERNIERE_MAJ
FROM
    APPS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPS.FND_APPLICATION_VL FA
        ON FA.APPLICATION_ID = FCP.APPLICATION_ID
    LEFT JOIN APPS.FND_EXECUTABLES FE
        ON FE.EXECUTABLE_ID = FCP.EXECUTABLE_ID
        AND FE.APPLICATION_ID = FCP.EXECUTABLE_APPLICATION_ID
WHERE
    UPPER(FCP.CONCURRENT_PROGRAM_NAME) LIKE UPPER('%&NOM_PROGRAMME%')
ORDER BY
    FCP.CONCURRENT_PROGRAM_NAME;

-- =====================================================================
-- 2) PARAMÃˆTRES DU PROGRAMME
-- =====================================================================
SELECT
    FCP.CONCURRENT_PROGRAM_NAME        AS PROGRAMME,
    DFCU.COLUMN_SEQ_NUM                AS SEQ,
    DFCU.END_USER_COLUMN_NAME          AS NOM_PARAMETRE,
    DFCU.DESCRIPTION                   AS DESCRIPTION,
    DFCU.REQUIRED_FLAG                 AS OBLIGATOIRE,
    DFCU.DEFAULT_VALUE                 AS VALEUR_DEFAUT,
    DFCU.ENABLED_FLAG                  AS ACTIF,
    DFCU.DISPLAY_FLAG                  AS VISIBLE,
    FVS.FLEX_VALUE_SET_NAME            AS JEU_VALEURS
FROM
    APPS.FND_CONCURRENT_PROGRAMS_VL FCP
    JOIN APPS.FND_DESCR_FLEX_COL_USAGE_VL DFCU
        ON DFCU.DESCRIPTIVE_FLEXFIELD_NAME = '$SRS$.' || FCP.CONCURRENT_PROGRAM_NAME
    LEFT JOIN APPS.FND_FLEX_VALUE_SETS FVS
        ON FVS.FLEX_VALUE_SET_ID = DFCU.FLEX_VALUE_SET_ID
WHERE
    UPPER(FCP.CONCURRENT_PROGRAM_NAME) LIKE UPPER('%&NOM_PROGRAMME%')
ORDER BY
    FCP.CONCURRENT_PROGRAM_NAME,
    DFCU.COLUMN_SEQ_NUM;

-- =====================================================================
-- 3) HISTORIQUE DES 50 DERNIÃˆRES EXÃ‰CUTIONS
-- =====================================================================
SELECT
    FCR.REQUEST_ID,
    FCP.CONCURRENT_PROGRAM_NAME        AS NOM_COURT,
    FCP.USER_CONCURRENT_PROGRAM_NAME   AS NOM_UTILISATEUR,
    TO_CHAR(FCR.REQUEST_DATE, 'DD/MM/YYYY HH24:MI:SS')          AS DATE_SOUMISSION,
    TO_CHAR(FCR.ACTUAL_START_DATE, 'DD/MM/YYYY HH24:MI:SS')     AS DEBUT,
    TO_CHAR(FCR.ACTUAL_COMPLETION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS FIN,
    ROUND((FCR.ACTUAL_COMPLETION_DATE - FCR.ACTUAL_START_DATE) * 24 * 60, 2) AS DUREE_MIN,
    DECODE(FCR.PHASE_CODE,
        'C', 'TerminÃ©', 'R', 'En cours', 'P', 'En attente', 'I', 'Inactif',
        FCR.PHASE_CODE)                AS PHASE,
    DECODE(FCR.STATUS_CODE,
        'C', 'Normal', 'E', 'Erreur', 'G', 'Avertissement', 'W', 'En attente',
        'X', 'TerminÃ©', 'T', 'ArrÃªtÃ©',
        FCR.STATUS_CODE)               AS STATUT,
    FU.USER_NAME                       AS SOUMIS_PAR,
    FCR.ARGUMENT_TEXT                  AS PARAMETRES
FROM
    APPS.FND_CONCURRENT_REQUESTS FCR
    JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP
        ON FCP.CONCURRENT_PROGRAM_ID = FCR.CONCURRENT_PROGRAM_ID
        AND FCP.APPLICATION_ID = FCR.PROGRAM_APPLICATION_ID
    JOIN APPS.FND_USER FU
        ON FU.USER_ID = FCR.REQUESTED_BY
WHERE
    UPPER(FCP.CONCURRENT_PROGRAM_NAME) LIKE UPPER('%&NOM_PROGRAMME%')
    AND FCR.REQUEST_DATE >= SYSDATE - 30
ORDER BY
    FCR.REQUEST_DATE DESC
FETCH FIRST 50 ROWS ONLY;

-- =====================================================================
-- 4) INCOMPATIBILITÃ‰S DU PROGRAMME
-- =====================================================================
SELECT
    FCP1.CONCURRENT_PROGRAM_NAME       AS PROGRAMME,
    FCP1.USER_CONCURRENT_PROGRAM_NAME  AS NOM_UTILISATEUR,
    FCP2.CONCURRENT_PROGRAM_NAME       AS INCOMPATIBLE_AVEC,
    FCP2.USER_CONCURRENT_PROGRAM_NAME  AS NOM_INCOMPATIBLE
FROM
    APPS.FND_CONCURRENT_PROGRAM_SERIAL FPS
    JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP1
        ON FCP1.CONCURRENT_PROGRAM_ID = FPS.RUNNING_CONCURRENT_PROGRAM_ID
        AND FCP1.APPLICATION_ID = FPS.RUNNING_APPLICATION_ID
    JOIN APPS.FND_CONCURRENT_PROGRAMS_VL FCP2
        ON FCP2.CONCURRENT_PROGRAM_ID = FPS.TO_RUN_CONCURRENT_PROGRAM_ID
        AND FCP2.APPLICATION_ID = FPS.TO_RUN_APPLICATION_ID
WHERE
    UPPER(FCP1.CONCURRENT_PROGRAM_NAME) LIKE UPPER('%&NOM_PROGRAMME%')
    OR UPPER(FCP2.CONCURRENT_PROGRAM_NAME) LIKE UPPER('%&NOM_PROGRAMME%')
ORDER BY
    FCP1.CONCURRENT_PROGRAM_NAME;
