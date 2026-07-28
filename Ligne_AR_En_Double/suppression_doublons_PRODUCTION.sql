-- =====================================================================
-- Suppression des doublons - DKA.DKA_IARPAFAC_INTERFACE (PRODUCTION)
-- =====================================================================
-- Date de création : 06/03/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS Production
--
-- OBJECTIF : Supprimer les enregistrements en doublon dans DKA.DKA_IARPAFAC_INTERFACE
--            en conservant l'enregistrement le plus ancien (plus petit IARPAFAC_ID)
--
-- CRITÈRES DE DOUBLON : TOUTES LES COLONNES MÉTIER (40 colonnes)
--   - ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE
--   - LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT
--   - FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN
--   - LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION
--   - LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE
--   - OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE
--   - FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
--
-- RÈGLE : On garde la ligne avec le plus petit IARPAFAC_ID (= plus ancienne)
--
-- USAGE : 
--   0. Exécuter PARTIE 0 pour créer une sauvegarde de sécurité
--   1. Exécuter PARTIE 1 pour identifier les doublons AVANT suppression
--   2. Exécuter PARTIE 2 pour voir les enregistrements qui seront supprimés
--   3. Exécuter PARTIE 3 pour supprimer les doublons (PRODUCTION)
--   4. Exécuter PARTIE 4 pour vérifier qu'il n'y a plus de doublons
--
-- ⚠️  ATTENTION : Ce script modifie la table de production DKA.DKA_IARPAFAC_INTERFACE
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 1000

-- =============================================================================
-- PARTIE 0 : SAUVEGARDE DE SÉCURITÉ AVANT SUPPRESSION
-- =============================================================================

PROMPT =====================================================
PROMPT PARTIE 0 : SAUVEGARDE DE SÉCURITÉ
PROMPT =====================================================
PROMPT
PROMPT Création d'une sauvegarde de la table DKA.DKA_IARPAFAC_INTERFACE
PROMPT avant suppression des doublons...
PROMPT

-- Suppression de l'ancienne table de sauvegarde si elle existe
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DKA.DKA_IARPAFAC_INTERFACE_BKP_BEFORE_DEDUPE';
    DBMS_OUTPUT.PUT_LINE('✓ Ancienne table de sauvegarde supprimée');
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE = -942 THEN
            DBMS_OUTPUT.PUT_LINE('→ Aucune ancienne table de sauvegarde à supprimer');
        ELSE
            RAISE;
        END IF;
END;
/

-- Création de la nouvelle table de sauvegarde
PROMPT
PROMPT Création de DKA.DKA_IARPAFAC_INTERFACE_BKP_BEFORE_DEDUPE...
PROMPT

CREATE TABLE DKA.DKA_IARPAFAC_INTERFACE_BKP_BEFORE_DEDUPE AS
SELECT * FROM DKA.DKA_IARPAFAC_INTERFACE;

PROMPT
PROMPT ✓ Sauvegarde créée avec succès !
PROMPT

-- Vérification du nombre de lignes sauvegardées
SELECT 
    'DKA.DKA_IARPAFAC_INTERFACE' AS TABLE_SOURCE,
    COUNT(*) AS NB_LIGNES
FROM DKA.DKA_IARPAFAC_INTERFACE
UNION ALL
SELECT 
    'DKA.DKA_IARPAFAC_INTERFACE_BKP_BEFORE_DEDUPE' AS TABLE_BACKUP,
    COUNT(*) AS NB_LIGNES
FROM DKA.DKA_IARPAFAC_INTERFACE_BKP_BEFORE_DEDUPE;

PROMPT
PROMPT ✓ En cas de problème, vous pouvez restaurer avec :
PROMPT   TRUNCATE TABLE DKA.DKA_IARPAFAC_INTERFACE;
PROMPT   INSERT INTO DKA.DKA_IARPAFAC_INTERFACE SELECT * FROM DKA.DKA_IARPAFAC_INTERFACE_BKP_BEFORE_DEDUPE;
PROMPT   COMMIT;
PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 0
PROMPT =====================================================


-- =============================================================================
-- PARTIE 1 : IDENTIFICATION DES DOUBLONS AVANT SUPPRESSION
-- =============================================================================

PROMPT
PROMPT
PROMPT =====================================================
PROMPT PARTIE 1 : IDENTIFICATION DES DOUBLONS
PROMPT =====================================================
PROMPT

-- Vue d'ensemble des doublons
SELECT 
    ORIGIN,
    CATEGORY,
    COMPANY_CODE,
    INVOICE_NUMBER,
    LINE_NUMBER,
    LINE_TYPE,
    LOCAL_ACCOUNT,
    AMOUNT,
    FIC_IDENT,
    COUNT(*) AS NB_DOUBLONS,
    MIN(IARPAFAC_ID) AS ID_A_GARDER,
    MAX(IARPAFAC_ID) AS ID_DERNIER,
    MIN(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS PREMIERE_CREATION,
    MAX(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS DERNIERE_CREATION
FROM DKA.DKA_IARPAFAC_INTERFACE
GROUP BY 
    ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
    LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
    FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
    LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
    LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
    OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
    FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, INVOICE_NUMBER, LINE_NUMBER;

PROMPT
PROMPT Statistiques des doublons :
PROMPT

-- Statistiques globales
WITH DOUBLONS AS (
    SELECT 
        ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
        LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
        FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
        LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
        LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
        OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
        FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS,
        COUNT(*) AS NB_OCCURRENCES,
        COUNT(*) - 1 AS NB_A_SUPPRIMER
    FROM DKA.DKA_IARPAFAC_INTERFACE
    GROUP BY 
        ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
        LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
        FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
        LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
        LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
        OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
        FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
    HAVING COUNT(*) > 1
)
SELECT 
    COUNT(*) AS NB_GROUPES_DOUBLONS,
    SUM(NB_OCCURRENCES) AS TOTAL_LIGNES_EN_DOUBLON,
    SUM(NB_A_SUPPRIMER) AS TOTAL_LIGNES_A_SUPPRIMER,
    MAX(NB_OCCURRENCES) AS MAX_DOUBLONS_PAR_GROUPE
FROM DOUBLONS;

PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 1
PROMPT =====================================================


-- =============================================================================
-- PARTIE 2 : PREVIEW DES LIGNES QUI SERONT SUPPRIMÉES
-- =============================================================================

PROMPT
PROMPT
PROMPT =====================================================
PROMPT PARTIE 2 : PREVIEW DES LIGNES À SUPPRIMER
PROMPT =====================================================
PROMPT
PROMPT Ces lignes seront supprimées (on garde la plus ancienne par groupe) :
PROMPT

-- Liste des 50 premières lignes qui seront supprimées
SELECT * FROM (
    SELECT 
        T.IARPAFAC_ID,
        T.INVOICE_NUMBER,
        T.LINE_NUMBER,
        T.LINE_TYPE,
        T.LOCAL_ACCOUNT,
        T.AMOUNT,
        T.FIC_IDENT,
        TO_CHAR(T.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS CREATION_DATE,
        'A SUPPRIMER' AS ACTION
    FROM DKA.DKA_IARPAFAC_INTERFACE T
    WHERE T.IARPAFAC_ID NOT IN (
        -- Garder uniquement le plus ancien IARPAFAC_ID de chaque groupe
        SELECT MIN(IARPAFAC_ID)
        FROM DKA.DKA_IARPAFAC_INTERFACE
        GROUP BY 
            ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
            LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
            FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
            LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
            LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
            OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
            FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
    )
    ORDER BY T.INVOICE_NUMBER, T.LINE_NUMBER, T.IARPAFAC_ID
)
WHERE ROWNUM <= 50;

PROMPT
PROMPT Comptage des lignes à supprimer :
PROMPT

SELECT COUNT(*) AS NB_LIGNES_A_SUPPRIMER
FROM DKA.DKA_IARPAFAC_INTERFACE T
WHERE T.IARPAFAC_ID NOT IN (
    SELECT MIN(IARPAFAC_ID)
    FROM DKA.DKA_IARPAFAC_INTERFACE
    GROUP BY 
        ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
        LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
        FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
        LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
        LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
        OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
        FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
);

PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 2
PROMPT =====================================================


-- =============================================================================
-- PARTIE 3 : SUPPRESSION DES DOUBLONS (PRODUCTION)
-- =============================================================================

PROMPT
PROMPT
PROMPT =====================================================
PROMPT PARTIE 3 : SUPPRESSION DES DOUBLONS
PROMPT =====================================================
PROMPT
PROMPT ⚠️  ATTENTION : Cette opération va MODIFIER la table de PRODUCTION !
PROMPT
PROMPT Pour des raisons de sécurité, le script est en mode COMMENTAIRE.
PROMPT Décommentez le bloc ci-dessous pour exécuter la suppression.
PROMPT
PROMPT =====================================================

/*
-- Suppression des doublons (on garde le plus ancien IARPAFAC_ID)
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE T
WHERE T.IARPAFAC_ID NOT IN (
    -- Garder uniquement le plus ancien IARPAFAC_ID de chaque groupe
    SELECT MIN(IARPAFAC_ID)
    FROM DKA.DKA_IARPAFAC_INTERFACE
    GROUP BY 
        ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
        LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
        FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
        LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
        LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
        OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
        FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
);

-- Affichage du nombre de lignes supprimées
PROMPT
PROMPT Nombre de lignes supprimées :
SELECT SQL%ROWCOUNT AS NB_LIGNES_SUPPRIMEES FROM DUAL;

COMMIT;

PROMPT
PROMPT ✓ COMMIT effectué - Doublons supprimés avec succès !
PROMPT

*/

PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 3 (en mode COMMENTAIRE)
PROMPT =====================================================


-- =============================================================================
-- PARTIE 4 : VÉRIFICATION APRÈS SUPPRESSION
-- =============================================================================

PROMPT
PROMPT
PROMPT =====================================================
PROMPT PARTIE 4 : VÉRIFICATION APRÈS SUPPRESSION
PROMPT =====================================================
PROMPT

-- Comptage global après suppression
SELECT 
    'AVANT (BACKUP)' AS MOMENT,
    COUNT(*) AS NB_LIGNES
FROM DKA.DKA_IARPAFAC_INTERFACE_BKP_BEFORE_DEDUPE
UNION ALL
SELECT 
    'APRÈS (ACTUEL)' AS MOMENT,
    COUNT(*) AS NB_LIGNES
FROM DKA.DKA_IARPAFAC_INTERFACE
ORDER BY MOMENT DESC;

PROMPT
PROMPT Vérification qu'il ne reste plus de doublons...
PROMPT

-- Recherche de doublons résiduels
SELECT 
    ORIGIN,
    CATEGORY,
    COMPANY_CODE,
    INVOICE_NUMBER,
    LINE_NUMBER,
    LINE_TYPE,
    LOCAL_ACCOUNT,
    AMOUNT,
    FIC_IDENT,
    COUNT(*) AS NB_DOUBLONS
FROM DKA.DKA_IARPAFAC_INTERFACE
GROUP BY 
    ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
    LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
    FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
    LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
    LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
    OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
    FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
HAVING COUNT(*) > 1;

PROMPT
PROMPT ✓ Si aucune ligne n'est retournée ci-dessus, alors tous les doublons ont été supprimés !
PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 4
PROMPT =====================================================
