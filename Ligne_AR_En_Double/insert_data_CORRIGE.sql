-- =====================================================================
-- Insertion des données manquantes depuis le backup vers la table actuelle
-- =====================================================================
-- Date de création : 06/03/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS Production
--
-- OBJECTIF : Insérer dans DKA.DKA_IARPAFAC_INTERFACE toutes les données qui 
--            existent dans APPS.DKA_IARPAFAC_INTERFACE_BKP_05032026 mais pas 
--            dans la table actuelle
--
-- CRITÈRES D'UNICITÉ : TOUTES LES COLONNES MÉTIER (44 colonnes)
--   (Comparaison de toutes les colonnes sauf IARPAFAC_ID, CREATION_DATE, LAST_UPDATE_DATE, LAST_UPDATED_BY)
--
-- USAGE : 
--   0. Exécuter PARTIE 0 pour créer une sauvegarde avant insertion
--   1. Exécuter PARTIE 1 pour voir les données manquantes
--   2. Exécuter PARTIE 2 pour insérer les données manquantes
--   3. Exécuter PARTIE 3 pour vérifier l'insertion
--
-- ⚠️  ATTENTION : Ce script modifie la table de production DKA.DKA_IARPAFAC_INTERFACE
-- =====================================================================

SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 1000

-- =============================================================================
-- PARTIE 0 : SAUVEGARDE DE LA TABLE AVANT INSERTION
-- =============================================================================

PROMPT =====================================================
PROMPT PARTIE 0 : SAUVEGARDE DE LA TABLE ACTUELLE
PROMPT =====================================================
PROMPT
PROMPT Création d'une sauvegarde de la table DKA.DKA_IARPAFAC_INTERFACE
PROMPT avant insertion des données manquantes...
PROMPT

-- Suppression de l'ancienne table de sauvegarde si elle existe
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE DKA.DKA_IARPAFAC_INTERFACE_BKP_06032026';
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
PROMPT Création de DKA.DKA_IARPAFAC_INTERFACE_BKP_06032026...
PROMPT

CREATE TABLE DKA.DKA_IARPAFAC_INTERFACE_BKP_06032026 AS
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
    'DKA.DKA_IARPAFAC_INTERFACE_BKP_06032026' AS TABLE_BACKUP,
    COUNT(*) AS NB_LIGNES
FROM DKA.DKA_IARPAFAC_INTERFACE_BKP_06032026;

PROMPT
PROMPT ✓ En cas de problème, vous pouvez restaurer avec :
PROMPT   TRUNCATE TABLE DKA.DKA_IARPAFAC_INTERFACE;
PROMPT   INSERT INTO DKA.DKA_IARPAFAC_INTERFACE SELECT * FROM DKA.DKA_IARPAFAC_INTERFACE_BKP_06032026;
PROMPT   COMMIT;
PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 0
PROMPT =====================================================


-- =============================================================================
-- PARTIE 1 : IDENTIFICATION DES DONNÉES MANQUANTES
-- =============================================================================

PROMPT
PROMPT
PROMPT =====================================================
PROMPT PARTIE 1 : IDENTIFICATION DES DONNÉES MANQUANTES
PROMPT =====================================================
PROMPT
PROMPT Recherche des enregistrements présents dans le backup mais absents de la table actuelle...
PROMPT

-- Comptage global
SELECT 
    'BACKUP (APPS)' AS SOURCE,
    COUNT(*) AS NB_LIGNES
FROM APPS.DKA_IARPAFAC_INTERFACE_BKP_05032026
UNION ALL
SELECT 
    'ACTUEL (DKA)' AS SOURCE,
    COUNT(*) AS NB_LIGNES
FROM DKA.DKA_IARPAFAC_INTERFACE
ORDER BY SOURCE;

PROMPT
PROMPT Comptage des données manquantes par critères d'unicité...
PROMPT

-- Identification des données manquantes (sur toutes les colonnes métier)
WITH BACKUP_UNIQUE AS (
    SELECT DISTINCT
        ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
        LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
        FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
        LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
        LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
        OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
        FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
    FROM APPS.DKA_IARPAFAC_INTERFACE_BKP_05032026
),
ACTUEL_UNIQUE AS (
    SELECT DISTINCT
        ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
        LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
        FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
        LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
        LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
        OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
        FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
    FROM DKA.DKA_IARPAFAC_INTERFACE
)
SELECT 
    (SELECT COUNT(*) FROM BACKUP_UNIQUE) AS NB_LIGNES_UNIQUES_BACKUP,
    (SELECT COUNT(*) FROM ACTUEL_UNIQUE) AS NB_LIGNES_UNIQUES_ACTUEL,
    (SELECT COUNT(*) FROM BACKUP_UNIQUE B 
     WHERE NOT EXISTS (
         SELECT 1 FROM ACTUEL_UNIQUE A
         WHERE NVL(A.ORIGIN,'#') = NVL(B.ORIGIN,'#')
           AND NVL(A.CATEGORY,'#') = NVL(B.CATEGORY,'#')
           AND NVL(A.COMPANY_CODE,'#') = NVL(B.COMPANY_CODE,'#')
           AND NVL(A.INVOICE_NUMBER,'#') = NVL(B.INVOICE_NUMBER,'#')
           AND NVL(A.TASK_CODE,'#') = NVL(B.TASK_CODE,'#')
           AND NVL(A.ANALYTIC_NATURE,'#') = NVL(B.ANALYTIC_NATURE,'#')
           AND NVL(A.LOCAL_ACCOUNT,'#') = NVL(B.LOCAL_ACCOUNT,'#')
           AND NVL(A.SUB_ACCOUNT,'#') = NVL(B.SUB_ACCOUNT,'#')
           AND NVL(A.TAX_CODE,'#') = NVL(B.TAX_CODE,'#')
           AND NVL(A.TAX_RATE,'#') = NVL(B.TAX_RATE,'#')
           AND NVL(A.DEBIT_OR_CREDIT,'#') = NVL(B.DEBIT_OR_CREDIT,'#')
           AND NVL(A.FMT_AMOUNT,-999999999) = NVL(B.FMT_AMOUNT,-999999999)
           AND NVL(A.FMT_INFO_TYPE,-999) = NVL(B.FMT_INFO_TYPE,-999)
           AND NVL(A.FMT_INVOICE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(B.FMT_INVOICE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY'))
           AND NVL(A.FMT_DUE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(B.FMT_DUE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY'))
           AND NVL(A.FMT_ORIGIN,'#') = NVL(B.FMT_ORIGIN,'#')
           AND NVL(A.LINE_NUMBER,-999) = NVL(B.LINE_NUMBER,-999)
           AND NVL(A.TYPMVT,'#') = NVL(B.TYPMVT,'#')
           AND NVL(A.LINK_TO_NUMBER,'#') = NVL(B.LINK_TO_NUMBER,'#')
           AND NVL(A.GL_DATE,'#') = NVL(B.GL_DATE,'#')
           AND NVL(A.INFO_TYPE,'#') = NVL(B.INFO_TYPE,'#')
           AND NVL(A.SEGMENTATION,'#') = NVL(B.SEGMENTATION,'#')
           AND NVL(A.LINE_TYPE,'#') = NVL(B.LINE_TYPE,'#')
           AND NVL(A.SIGN,'#') = NVL(B.SIGN,'#')
           AND NVL(A.AMOUNT,'#') = NVL(B.AMOUNT,'#')
           AND NVL(A.CURRENCY,'#') = NVL(B.CURRENCY,'#')
           AND NVL(A.DESCRIPTION,'#') = NVL(B.DESCRIPTION,'#')
           AND NVL(A.QUANTITY,'#') = NVL(B.QUANTITY,'#')
           AND NVL(A.FUNCTION_CODE,'#') = NVL(B.FUNCTION_CODE,'#')
           AND NVL(A.OA_STATUS,'#') = NVL(B.OA_STATUS,'#')
           AND NVL(A.OA_REQUEST_ID,-999) = NVL(B.OA_REQUEST_ID,-999)
           AND NVL(A.GROUP_ID,-999) = NVL(B.GROUP_ID,-999)
           AND NVL(A.TAX_EQUAL_FLAG,'#') = NVL(B.TAX_EQUAL_FLAG,'#')
           AND NVL(A.TAX_LINE_TYPE,'#') = NVL(B.TAX_LINE_TYPE,'#')
           AND NVL(A.FIC_IDENT,'#') = NVL(B.FIC_IDENT,'#')
           AND NVL(A.TYPE_EVT_DEP,'#') = NVL(B.TYPE_EVT_DEP,'#')
           AND NVL(A.RECEIPT_METHOD,'#') = NVL(B.RECEIPT_METHOD,'#')
           AND NVL(A.TYPE_PIECE,'#') = NVL(B.TYPE_PIECE,'#')
           AND NVL(A.REGION,'#') = NVL(B.REGION,'#')
           AND NVL(A.COMMENTS,'#') = NVL(B.COMMENTS,'#')
     )) AS NB_LIGNES_MANQUANTES
FROM DUAL;

PROMPT
PROMPT Détail des 20 premières lignes manquantes :
PROMPT

-- Affichage des 20 premières lignes manquantes
SELECT * FROM (
    SELECT 
        BKP.INVOICE_NUMBER,
        BKP.LINE_NUMBER,
        BKP.LINE_TYPE,
        BKP.LOCAL_ACCOUNT,
        BKP.COMPANY_CODE,
        BKP.ORIGIN,
        BKP.FIC_IDENT,
        BKP.AMOUNT,
        TO_CHAR(BKP.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS CREATION_DATE
    FROM APPS.DKA_IARPAFAC_INTERFACE_BKP_05032026 BKP
    WHERE NOT EXISTS (
        SELECT 1 
        FROM DKA.DKA_IARPAFAC_INTERFACE ACT
        WHERE NVL(ACT.ORIGIN,'#') = NVL(BKP.ORIGIN,'#')
          AND NVL(ACT.CATEGORY,'#') = NVL(BKP.CATEGORY,'#')
          AND NVL(ACT.COMPANY_CODE,'#') = NVL(BKP.COMPANY_CODE,'#')
          AND NVL(ACT.INVOICE_NUMBER,'#') = NVL(BKP.INVOICE_NUMBER,'#')
          AND NVL(ACT.TASK_CODE,'#') = NVL(BKP.TASK_CODE,'#')
          AND NVL(ACT.ANALYTIC_NATURE,'#') = NVL(BKP.ANALYTIC_NATURE,'#')
          AND NVL(ACT.LOCAL_ACCOUNT,'#') = NVL(BKP.LOCAL_ACCOUNT,'#')
          AND NVL(ACT.SUB_ACCOUNT,'#') = NVL(BKP.SUB_ACCOUNT,'#')
          AND NVL(ACT.TAX_CODE,'#') = NVL(BKP.TAX_CODE,'#')
          AND NVL(ACT.TAX_RATE,'#') = NVL(BKP.TAX_RATE,'#')
          AND NVL(ACT.DEBIT_OR_CREDIT,'#') = NVL(BKP.DEBIT_OR_CREDIT,'#')
          AND NVL(ACT.FMT_AMOUNT,-999999999) = NVL(BKP.FMT_AMOUNT,-999999999)
          AND NVL(ACT.FMT_INFO_TYPE,-999) = NVL(BKP.FMT_INFO_TYPE,-999)
          AND NVL(ACT.FMT_INVOICE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(BKP.FMT_INVOICE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY'))
          AND NVL(ACT.FMT_DUE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(BKP.FMT_DUE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY'))
          AND NVL(ACT.FMT_ORIGIN,'#') = NVL(BKP.FMT_ORIGIN,'#')
          AND NVL(ACT.LINE_NUMBER,-999) = NVL(BKP.LINE_NUMBER,-999)
          AND NVL(ACT.TYPMVT,'#') = NVL(BKP.TYPMVT,'#')
          AND NVL(ACT.LINK_TO_NUMBER,'#') = NVL(BKP.LINK_TO_NUMBER,'#')
          AND NVL(ACT.GL_DATE,'#') = NVL(BKP.GL_DATE,'#')
          AND NVL(ACT.INFO_TYPE,'#') = NVL(BKP.INFO_TYPE,'#')
          AND NVL(ACT.SEGMENTATION,'#') = NVL(BKP.SEGMENTATION,'#')
          AND NVL(ACT.LINE_TYPE,'#') = NVL(BKP.LINE_TYPE,'#')
          AND NVL(ACT.SIGN,'#') = NVL(BKP.SIGN,'#')
          AND NVL(ACT.AMOUNT,'#') = NVL(BKP.AMOUNT,'#')
          AND NVL(ACT.CURRENCY,'#') = NVL(BKP.CURRENCY,'#')
          AND NVL(ACT.DESCRIPTION,'#') = NVL(BKP.DESCRIPTION,'#')
          AND NVL(ACT.QUANTITY,'#') = NVL(BKP.QUANTITY,'#')
          AND NVL(ACT.FUNCTION_CODE,'#') = NVL(BKP.FUNCTION_CODE,'#')
          AND NVL(ACT.OA_STATUS,'#') = NVL(BKP.OA_STATUS,'#')
          AND NVL(ACT.OA_REQUEST_ID,-999) = NVL(BKP.OA_REQUEST_ID,-999)
          AND NVL(ACT.GROUP_ID,-999) = NVL(BKP.GROUP_ID,-999)
          AND NVL(ACT.TAX_EQUAL_FLAG,'#') = NVL(BKP.TAX_EQUAL_FLAG,'#')
          AND NVL(ACT.TAX_LINE_TYPE,'#') = NVL(BKP.TAX_LINE_TYPE,'#')
          AND NVL(ACT.FIC_IDENT,'#') = NVL(BKP.FIC_IDENT,'#')
          AND NVL(ACT.TYPE_EVT_DEP,'#') = NVL(BKP.TYPE_EVT_DEP,'#')
          AND NVL(ACT.RECEIPT_METHOD,'#') = NVL(BKP.RECEIPT_METHOD,'#')
          AND NVL(ACT.TYPE_PIECE,'#') = NVL(BKP.TYPE_PIECE,'#')
          AND NVL(ACT.REGION,'#') = NVL(BKP.REGION,'#')
          AND NVL(ACT.COMMENTS,'#') = NVL(BKP.COMMENTS,'#')
    )
    ORDER BY BKP.INVOICE_NUMBER, BKP.LINE_NUMBER
)
WHERE ROWNUM <= 20;

PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 1
PROMPT =====================================================


-- =============================================================================
-- PARTIE 2 : INSERTION DES DONNÉES MANQUANTES
-- =============================================================================

PROMPT
PROMPT
PROMPT =====================================================
PROMPT PARTIE 2 : INSERTION DES DONNÉES MANQUANTES
PROMPT =====================================================
PROMPT
PROMPT ⚠️  ATTENTION : Cette opération va modifier la table de production !
PROMPT
PROMPT Pour des raisons de sécurité, le script est en mode COMMENTAIRE.
PROMPT Décommentez le bloc ci-dessous pour exécuter l'insertion.
PROMPT
PROMPT =====================================================

/*
-- Insertion des données manquantes
INSERT INTO DKA.DKA_IARPAFAC_INTERFACE (
    IARPAFAC_ID,
    ORIGIN,
    CATEGORY,
    COMPANY_CODE,
    INVOICE_NUMBER,
    TASK_CODE,
    ANALYTIC_NATURE,
    LOCAL_ACCOUNT,
    SUB_ACCOUNT,
    TAX_CODE,
    TAX_RATE,
    DEBIT_OR_CREDIT,
    FMT_AMOUNT,
    FMT_INFO_TYPE,
    FMT_INVOICE_DATE,
    FMT_DUE_DATE,
    FMT_ORIGIN,
    LINE_NUMBER,
    TYPMVT,
    LINK_TO_NUMBER,
    GL_DATE,
    INFO_TYPE,
    SEGMENTATION,
    LINE_TYPE,
    SIGN,
    AMOUNT,
    CURRENCY,
    DESCRIPTION,
    QUANTITY,
    FUNCTION_CODE,
    OA_STATUS,
    OA_REQUEST_ID,
    GROUP_ID,
    CREATION_DATE,
    LAST_UPDATE_DATE,
    LAST_UPDATED_BY,
    TAX_EQUAL_FLAG,
    TAX_LINE_TYPE,
    FIC_IDENT,
    TYPE_EVT_DEP,
    RECEIPT_METHOD,
    TYPE_PIECE,
    REGION,
    COMMENTS
)
SELECT 
    DKA.DKA_IARPAFAC_INTERFACE_S.NEXTVAL,  -- Nouveau IARPAFAC_ID
    BKP.ORIGIN,
    BKP.CATEGORY,
    BKP.COMPANY_CODE,
    BKP.INVOICE_NUMBER,
    BKP.TASK_CODE,
    BKP.ANALYTIC_NATURE,
    BKP.LOCAL_ACCOUNT,
    BKP.SUB_ACCOUNT,
    BKP.TAX_CODE,
    BKP.TAX_RATE,
    BKP.DEBIT_OR_CREDIT,
    BKP.FMT_AMOUNT,
    BKP.FMT_INFO_TYPE,
    BKP.FMT_INVOICE_DATE,
    BKP.FMT_DUE_DATE,
    BKP.FMT_ORIGIN,
    BKP.LINE_NUMBER,
    BKP.TYPMVT,
    BKP.LINK_TO_NUMBER,
    BKP.GL_DATE,
    BKP.INFO_TYPE,
    BKP.SEGMENTATION,
    BKP.LINE_TYPE,
    BKP.SIGN,
    BKP.AMOUNT,
    BKP.CURRENCY,
    BKP.DESCRIPTION,
    BKP.QUANTITY,
    BKP.FUNCTION_CODE,
    BKP.OA_STATUS,
    BKP.OA_REQUEST_ID,
    BKP.GROUP_ID,
    SYSDATE,                -- CREATION_DATE : nouvelle date
    SYSDATE,                -- LAST_UPDATE_DATE : nouvelle date
    BKP.LAST_UPDATED_BY,    -- Conserver l'auteur original
    BKP.TAX_EQUAL_FLAG,
    BKP.TAX_LINE_TYPE,
    BKP.FIC_IDENT,
    BKP.TYPE_EVT_DEP,
    BKP.RECEIPT_METHOD,
    BKP.TYPE_PIECE,
    BKP.REGION,
    BKP.COMMENTS
FROM APPS.DKA_IARPAFAC_INTERFACE_BKP_05032026 BKP
WHERE NOT EXISTS (
    -- Vérifier que la ligne n'existe pas déjà selon TOUTES les colonnes métier
    SELECT 1 
    FROM DKA.DKA_IARPAFAC_INTERFACE ACT
    WHERE NVL(ACT.ORIGIN,'#') = NVL(BKP.ORIGIN,'#')
      AND NVL(ACT.CATEGORY,'#') = NVL(BKP.CATEGORY,'#')
      AND NVL(ACT.COMPANY_CODE,'#') = NVL(BKP.COMPANY_CODE,'#')
      AND NVL(ACT.INVOICE_NUMBER,'#') = NVL(BKP.INVOICE_NUMBER,'#')
      AND NVL(ACT.TASK_CODE,'#') = NVL(BKP.TASK_CODE,'#')
      AND NVL(ACT.ANALYTIC_NATURE,'#') = NVL(BKP.ANALYTIC_NATURE,'#')
      AND NVL(ACT.LOCAL_ACCOUNT,'#') = NVL(BKP.LOCAL_ACCOUNT,'#')
      AND NVL(ACT.SUB_ACCOUNT,'#') = NVL(BKP.SUB_ACCOUNT,'#')
      AND NVL(ACT.TAX_CODE,'#') = NVL(BKP.TAX_CODE,'#')
      AND NVL(ACT.TAX_RATE,'#') = NVL(BKP.TAX_RATE,'#')
      AND NVL(ACT.DEBIT_OR_CREDIT,'#') = NVL(BKP.DEBIT_OR_CREDIT,'#')
      AND NVL(ACT.FMT_AMOUNT,-999999999) = NVL(BKP.FMT_AMOUNT,-999999999)
      AND NVL(ACT.FMT_INFO_TYPE,-999) = NVL(BKP.FMT_INFO_TYPE,-999)
      AND NVL(ACT.FMT_INVOICE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(BKP.FMT_INVOICE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY'))
      AND NVL(ACT.FMT_DUE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(BKP.FMT_DUE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY'))
      AND NVL(ACT.FMT_ORIGIN,'#') = NVL(BKP.FMT_ORIGIN,'#')
      AND NVL(ACT.LINE_NUMBER,-999) = NVL(BKP.LINE_NUMBER,-999)
      AND NVL(ACT.TYPMVT,'#') = NVL(BKP.TYPMVT,'#')
      AND NVL(ACT.LINK_TO_NUMBER,'#') = NVL(BKP.LINK_TO_NUMBER,'#')
      AND NVL(ACT.GL_DATE,'#') = NVL(BKP.GL_DATE,'#')
      AND NVL(ACT.INFO_TYPE,'#') = NVL(BKP.INFO_TYPE,'#')
      AND NVL(ACT.SEGMENTATION,'#') = NVL(BKP.SEGMENTATION,'#')
      AND NVL(ACT.LINE_TYPE,'#') = NVL(BKP.LINE_TYPE,'#')
      AND NVL(ACT.SIGN,'#') = NVL(BKP.SIGN,'#')
      AND NVL(ACT.AMOUNT,'#') = NVL(BKP.AMOUNT,'#')
      AND NVL(ACT.CURRENCY,'#') = NVL(BKP.CURRENCY,'#')
      AND NVL(ACT.DESCRIPTION,'#') = NVL(BKP.DESCRIPTION,'#')
      AND NVL(ACT.QUANTITY,'#') = NVL(BKP.QUANTITY,'#')
      AND NVL(ACT.FUNCTION_CODE,'#') = NVL(BKP.FUNCTION_CODE,'#')
      AND NVL(ACT.OA_STATUS,'#') = NVL(BKP.OA_STATUS,'#')
      AND NVL(ACT.OA_REQUEST_ID,-999) = NVL(BKP.OA_REQUEST_ID,-999)
      AND NVL(ACT.GROUP_ID,-999) = NVL(BKP.GROUP_ID,-999)
      AND NVL(ACT.TAX_EQUAL_FLAG,'#') = NVL(BKP.TAX_EQUAL_FLAG,'#')
      AND NVL(ACT.TAX_LINE_TYPE,'#') = NVL(BKP.TAX_LINE_TYPE,'#')
      AND NVL(ACT.FIC_IDENT,'#') = NVL(BKP.FIC_IDENT,'#')
      AND NVL(ACT.TYPE_EVT_DEP,'#') = NVL(BKP.TYPE_EVT_DEP,'#')
      AND NVL(ACT.RECEIPT_METHOD,'#') = NVL(BKP.RECEIPT_METHOD,'#')
      AND NVL(ACT.TYPE_PIECE,'#') = NVL(BKP.TYPE_PIECE,'#')
      AND NVL(ACT.REGION,'#') = NVL(BKP.REGION,'#')
      AND NVL(ACT.COMMENTS,'#') = NVL(BKP.COMMENTS,'#')
);

-- Affichage du nombre de lignes insérées
PROMPT
PROMPT Nombre de lignes insérées :
SELECT SQL%ROWCOUNT AS NB_LIGNES_INSEREES FROM DUAL;

COMMIT;

PROMPT
PROMPT ✓ COMMIT effectué - Données insérées avec succès !
PROMPT

*/

PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 2 (en mode COMMENTAIRE)
PROMPT =====================================================


-- =============================================================================
-- PARTIE 3 : VÉRIFICATION APRÈS INSERTION
-- =============================================================================

PROMPT
PROMPT
PROMPT =====================================================
PROMPT PARTIE 3 : VÉRIFICATION APRÈS INSERTION
PROMPT =====================================================
PROMPT

-- Comptage global après insertion
SELECT 
    'BACKUP (APPS)' AS SOURCE,
    COUNT(*) AS NB_LIGNES
FROM APPS.DKA_IARPAFAC_INTERFACE_BKP_05032026
UNION ALL
SELECT 
    'ACTUEL (DKA) APRÈS INSERT' AS SOURCE,
    COUNT(*) AS NB_LIGNES
FROM DKA.DKA_IARPAFAC_INTERFACE
ORDER BY SOURCE;

PROMPT
PROMPT Vérification qu'il ne reste plus de données manquantes...
PROMPT

-- Vérification qu'il ne reste plus de données manquantes
WITH BACKUP_UNIQUE AS (
    SELECT DISTINCT
        ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
        LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
        FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
        LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
        LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
        OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
        FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
    FROM APPS.DKA_IARPAFAC_INTERFACE_BKP_05032026
),
ACTUEL_UNIQUE AS (
    SELECT DISTINCT
        ORIGIN, CATEGORY, COMPANY_CODE, INVOICE_NUMBER, TASK_CODE, ANALYTIC_NATURE,
        LOCAL_ACCOUNT, SUB_ACCOUNT, TAX_CODE, TAX_RATE, DEBIT_OR_CREDIT,
        FMT_AMOUNT, FMT_INFO_TYPE, FMT_INVOICE_DATE, FMT_DUE_DATE, FMT_ORIGIN,
        LINE_NUMBER, TYPMVT, LINK_TO_NUMBER, GL_DATE, INFO_TYPE, SEGMENTATION,
        LINE_TYPE, SIGN, AMOUNT, CURRENCY, DESCRIPTION, QUANTITY, FUNCTION_CODE,
        OA_STATUS, OA_REQUEST_ID, GROUP_ID, TAX_EQUAL_FLAG, TAX_LINE_TYPE,
        FIC_IDENT, TYPE_EVT_DEP, RECEIPT_METHOD, TYPE_PIECE, REGION, COMMENTS
    FROM DKA.DKA_IARPAFAC_INTERFACE
)
SELECT 
    (SELECT COUNT(*) FROM BACKUP_UNIQUE B 
     WHERE NOT EXISTS (
         SELECT 1 FROM ACTUEL_UNIQUE A
         WHERE NVL(A.ORIGIN,'#') = NVL(B.ORIGIN,'#')
           AND NVL(A.CATEGORY,'#') = NVL(B.CATEGORY,'#')
           AND NVL(A.COMPANY_CODE,'#') = NVL(B.COMPANY_CODE,'#')
           AND NVL(A.INVOICE_NUMBER,'#') = NVL(B.INVOICE_NUMBER,'#')
           AND NVL(A.TASK_CODE,'#') = NVL(B.TASK_CODE,'#')
           AND NVL(A.ANALYTIC_NATURE,'#') = NVL(B.ANALYTIC_NATURE,'#')
           AND NVL(A.LOCAL_ACCOUNT,'#') = NVL(B.LOCAL_ACCOUNT,'#')
           AND NVL(A.SUB_ACCOUNT,'#') = NVL(B.SUB_ACCOUNT,'#')
           AND NVL(A.TAX_CODE,'#') = NVL(B.TAX_CODE,'#')
           AND NVL(A.TAX_RATE,'#') = NVL(B.TAX_RATE,'#')
           AND NVL(A.DEBIT_OR_CREDIT,'#') = NVL(B.DEBIT_OR_CREDIT,'#')
           AND NVL(A.FMT_AMOUNT,-999999999) = NVL(B.FMT_AMOUNT,-999999999)
           AND NVL(A.FMT_INFO_TYPE,-999) = NVL(B.FMT_INFO_TYPE,-999)
           AND NVL(A.FMT_INVOICE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(B.FMT_INVOICE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY'))
           AND NVL(A.FMT_DUE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY')) = NVL(B.FMT_DUE_DATE,TO_DATE('01/01/1900','DD/MM/YYYY'))
           AND NVL(A.FMT_ORIGIN,'#') = NVL(B.FMT_ORIGIN,'#')
           AND NVL(A.LINE_NUMBER,-999) = NVL(B.LINE_NUMBER,-999)
           AND NVL(A.TYPMVT,'#') = NVL(B.TYPMVT,'#')
           AND NVL(A.LINK_TO_NUMBER,'#') = NVL(B.LINK_TO_NUMBER,'#')
           AND NVL(A.GL_DATE,'#') = NVL(B.GL_DATE,'#')
           AND NVL(A.INFO_TYPE,'#') = NVL(B.INFO_TYPE,'#')
           AND NVL(A.SEGMENTATION,'#') = NVL(B.SEGMENTATION,'#')
           AND NVL(A.LINE_TYPE,'#') = NVL(B.LINE_TYPE,'#')
           AND NVL(A.SIGN,'#') = NVL(B.SIGN,'#')
           AND NVL(A.AMOUNT,'#') = NVL(B.AMOUNT,'#')
           AND NVL(A.CURRENCY,'#') = NVL(B.CURRENCY,'#')
           AND NVL(A.DESCRIPTION,'#') = NVL(B.DESCRIPTION,'#')
           AND NVL(A.QUANTITY,'#') = NVL(B.QUANTITY,'#')
           AND NVL(A.FUNCTION_CODE,'#') = NVL(B.FUNCTION_CODE,'#')
           AND NVL(A.OA_STATUS,'#') = NVL(B.OA_STATUS,'#')
           AND NVL(A.OA_REQUEST_ID,-999) = NVL(B.OA_REQUEST_ID,-999)
           AND NVL(A.GROUP_ID,-999) = NVL(B.GROUP_ID,-999)
           AND NVL(A.TAX_EQUAL_FLAG,'#') = NVL(B.TAX_EQUAL_FLAG,'#')
           AND NVL(A.TAX_LINE_TYPE,'#') = NVL(B.TAX_LINE_TYPE,'#')
           AND NVL(A.FIC_IDENT,'#') = NVL(B.FIC_IDENT,'#')
           AND NVL(A.TYPE_EVT_DEP,'#') = NVL(B.TYPE_EVT_DEP,'#')
           AND NVL(A.RECEIPT_METHOD,'#') = NVL(B.RECEIPT_METHOD,'#')
           AND NVL(A.TYPE_PIECE,'#') = NVL(B.TYPE_PIECE,'#')
           AND NVL(A.REGION,'#') = NVL(B.REGION,'#')
           AND NVL(A.COMMENTS,'#') = NVL(B.COMMENTS,'#')
     )) AS NB_LIGNES_ENCORE_MANQUANTES
FROM DUAL;

PROMPT
PROMPT ✓ Si NB_LIGNES_ENCORE_MANQUANTES = 0, alors toutes les données ont été restaurées !
PROMPT
PROMPT =====================================================
PROMPT Fin de PARTIE 3
PROMPT =====================================================
