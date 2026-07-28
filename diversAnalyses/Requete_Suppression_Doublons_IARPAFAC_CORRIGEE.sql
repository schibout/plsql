-- =====================================================================
-- Détection des doublons dans DKA_IARPAFAC_INTERFACE
-- =====================================================================
-- Date de création : 07/03/2026
-- Base de données : Oracle EBS 19.28.0.0.0
--
-- PROBLÈME RÉSOLU : 
-- - Erreur ORA-01722 (conversion de type) corrigée
-- - Colonnes NUMBER (FMT_AMOUNT, FMT_INFO_TYPE, LINE_NUMBER) converties avec TO_CHAR
-- - Colonnes DATE (FMT_INVOICE_DATE, FMT_DUE_DATE) converties avec TO_CHAR
--
-- CHANGEMENTS PAR RAPPORT À LA VERSION ORIGINALE :
-- 1. Ajout de TO_CHAR() pour toutes les colonnes NUMBER et DATE
-- 2. Simplification possible avec ROW_NUMBER() pour améliorer les performances
--
-- NOTE : GL_DATE est commenté dans le EXISTS pour élargir la recherche
-- =====================================================================

-- VERSION 1 : Requête originale corrigée
-- Utilise NOT IN avec sous-requête MIN()

SELECT * 
FROM DKA.DKA_IARPAFAC_INTERFACE dii
WHERE dii.IARPAFAC_ID NOT IN (
    -- Garder uniquement le plus petit ID (= le plus ancien)
    SELECT MIN(dii2.IARPAFAC_ID)
    FROM DKA.DKA_IARPAFAC_INTERFACE dii2
    WHERE NVL(dii2.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii2.CATEGORY, 'X') = NVL(dii.CATEGORY, 'X')
    AND NVL(dii2.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii2.INVOICE_NUMBER, 'X') = NVL(dii.INVOICE_NUMBER, 'X')
    AND NVL(dii2.TASK_CODE, 'X') = NVL(dii.TASK_CODE, 'X')
    AND NVL(dii2.ANALYTIC_NATURE, 'X') = NVL(dii.ANALYTIC_NATURE, 'X')
    AND NVL(dii2.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii2.SUB_ACCOUNT, 'X') = NVL(dii.SUB_ACCOUNT, 'X')
    AND NVL(dii2.TAX_CODE, 'X') = NVL(dii.TAX_CODE, 'X')
    AND NVL(dii2.TAX_RATE, 'X') = NVL(dii.TAX_RATE, 'X')
    AND NVL(dii2.DEBIT_OR_CREDIT, 'X') = NVL(dii.DEBIT_OR_CREDIT, 'X')
    AND NVL(TO_CHAR(dii2.FMT_AMOUNT), 'X') = NVL(TO_CHAR(dii.FMT_AMOUNT), 'X')
    AND NVL(TO_CHAR(dii2.FMT_INFO_TYPE), 'X') = NVL(TO_CHAR(dii.FMT_INFO_TYPE), 'X')
    AND NVL(TO_CHAR(dii2.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X') = NVL(TO_CHAR(dii.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X')
    AND NVL(TO_CHAR(dii2.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X') = NVL(TO_CHAR(dii.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X')
    AND NVL(dii2.FMT_ORIGIN, 'X') = NVL(dii.FMT_ORIGIN, 'X')
    AND NVL(TO_CHAR(dii2.LINE_NUMBER), 'X') = NVL(TO_CHAR(dii.LINE_NUMBER), 'X')
    AND NVL(dii2.TYPMVT, 'X') = NVL(dii.TYPMVT, 'X')
    AND NVL(dii2.LINK_TO_NUMBER, 'X') = NVL(dii.LINK_TO_NUMBER, 'X')
    AND NVL(dii2.GL_DATE, 'X') = NVL(dii.GL_DATE, 'X')
    AND NVL(dii2.INFO_TYPE, 'X') = NVL(dii.INFO_TYPE, 'X')
    AND NVL(dii2.SEGMENTATION, 'X') = NVL(dii.SEGMENTATION, 'X')
    AND NVL(dii2.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    AND NVL(dii2.SIGN, 'X') = NVL(dii.SIGN, 'X')
    AND NVL(dii2.AMOUNT, 'X') = NVL(dii.AMOUNT, 'X')
    AND NVL(dii2.CURRENCY, 'X') = NVL(dii.CURRENCY, 'X')
    AND NVL(dii2.DESCRIPTION, 'X') = NVL(dii.DESCRIPTION, 'X')
    AND NVL(dii2.QUANTITY, 'X') = NVL(dii.QUANTITY, 'X')
    AND NVL(dii2.FUNCTION_CODE, 'X') = NVL(dii.FUNCTION_CODE, 'X')
    AND NVL(dii2.OA_STATUS, 'X') = NVL(dii.OA_STATUS, 'X')
    AND NVL(TO_CHAR(dii2.OA_REQUEST_ID), 'X') = NVL(TO_CHAR(dii.OA_REQUEST_ID), 'X')
    AND NVL(TO_CHAR(dii2.GROUP_ID), 'X') = NVL(TO_CHAR(dii.GROUP_ID), 'X')
    AND NVL(dii2.TAX_EQUAL_FLAG, 'X') = NVL(dii.TAX_EQUAL_FLAG, 'X')
    AND NVL(dii2.TAX_LINE_TYPE, 'X') = NVL(dii.TAX_LINE_TYPE, 'X')
    AND NVL(dii2.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    AND NVL(dii2.TYPE_EVT_DEP, 'X') = NVL(dii.TYPE_EVT_DEP, 'X')
    AND NVL(dii2.RECEIPT_METHOD, 'X') = NVL(dii.RECEIPT_METHOD, 'X')
    AND NVL(dii2.TYPE_PIECE, 'X') = NVL(dii.TYPE_PIECE, 'X')
    AND NVL(dii2.REGION, 'X') = NVL(dii.REGION, 'X')
    AND NVL(dii2.COMMENTS, 'X') = NVL(dii.COMMENTS, 'X')
)
AND EXISTS (
    -- Vérifier qu'il existe bien des doublons
    SELECT 1
    FROM DKA.DKA_IARPAFAC_INTERFACE dii3
    WHERE NVL(dii3.ORIGIN, 'X') = NVL(dii.ORIGIN, 'X')
    AND NVL(dii3.CATEGORY, 'X') = NVL(dii.CATEGORY, 'X')
    AND NVL(dii3.COMPANY_CODE, 'X') = NVL(dii.COMPANY_CODE, 'X')
    AND NVL(dii3.INVOICE_NUMBER, 'X') = NVL(dii.INVOICE_NUMBER, 'X')
    AND NVL(dii3.TASK_CODE, 'X') = NVL(dii.TASK_CODE, 'X')
    AND NVL(dii3.ANALYTIC_NATURE, 'X') = NVL(dii.ANALYTIC_NATURE, 'X')
    AND NVL(dii3.LOCAL_ACCOUNT, 'X') = NVL(dii.LOCAL_ACCOUNT, 'X')
    AND NVL(dii3.SUB_ACCOUNT, 'X') = NVL(dii.SUB_ACCOUNT, 'X')
    AND NVL(dii3.TAX_CODE, 'X') = NVL(dii.TAX_CODE, 'X')
    AND NVL(dii3.TAX_RATE, 'X') = NVL(dii.TAX_RATE, 'X')
    AND NVL(dii3.DEBIT_OR_CREDIT, 'X') = NVL(dii.DEBIT_OR_CREDIT, 'X')
    AND NVL(TO_CHAR(dii3.FMT_AMOUNT), 'X') = NVL(TO_CHAR(dii.FMT_AMOUNT), 'X')
    AND NVL(TO_CHAR(dii3.FMT_INFO_TYPE), 'X') = NVL(TO_CHAR(dii.FMT_INFO_TYPE), 'X')
    AND NVL(TO_CHAR(dii3.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X') = NVL(TO_CHAR(dii.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X')
    AND NVL(TO_CHAR(dii3.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X') = NVL(TO_CHAR(dii.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X')
    AND NVL(dii3.FMT_ORIGIN, 'X') = NVL(dii.FMT_ORIGIN, 'X')
    AND NVL(TO_CHAR(dii3.LINE_NUMBER), 'X') = NVL(TO_CHAR(dii.LINE_NUMBER), 'X')
    AND NVL(dii3.TYPMVT, 'X') = NVL(dii.TYPMVT, 'X')
    AND NVL(dii3.LINK_TO_NUMBER, 'X') = NVL(dii.LINK_TO_NUMBER, 'X')
    -- GL_DATE commenté dans le EXISTS pour élargir la recherche de doublons
    -- AND NVL(dii3.GL_DATE, 'X') = NVL(dii.GL_DATE, 'X')
    AND NVL(dii3.INFO_TYPE, 'X') = NVL(dii.INFO_TYPE, 'X')
    AND NVL(dii3.SEGMENTATION, 'X') = NVL(dii.SEGMENTATION, 'X')
    AND NVL(dii3.LINE_TYPE, 'X') = NVL(dii.LINE_TYPE, 'X')
    AND NVL(dii3.SIGN, 'X') = NVL(dii.SIGN, 'X')
    AND NVL(dii3.AMOUNT, 'X') = NVL(dii.AMOUNT, 'X')
    AND NVL(dii3.CURRENCY, 'X') = NVL(dii.CURRENCY, 'X')
    AND NVL(dii3.DESCRIPTION, 'X') = NVL(dii.DESCRIPTION, 'X')
    AND NVL(dii3.QUANTITY, 'X') = NVL(dii.QUANTITY, 'X')
    AND NVL(dii3.FUNCTION_CODE, 'X') = NVL(dii.FUNCTION_CODE, 'X')
    AND NVL(dii3.OA_STATUS, 'X') = NVL(dii.OA_STATUS, 'X')
    AND NVL(TO_CHAR(dii3.OA_REQUEST_ID), 'X') = NVL(TO_CHAR(dii.OA_REQUEST_ID), 'X')
    AND NVL(TO_CHAR(dii3.GROUP_ID), 'X') = NVL(TO_CHAR(dii.GROUP_ID), 'X')
    AND NVL(dii3.TAX_EQUAL_FLAG, 'X') = NVL(dii.TAX_EQUAL_FLAG, 'X')
    AND NVL(dii3.TAX_LINE_TYPE, 'X') = NVL(dii.TAX_LINE_TYPE, 'X')
    AND NVL(dii3.FIC_IDENT, 'X') = NVL(dii.FIC_IDENT, 'X')
    AND NVL(dii3.TYPE_EVT_DEP, 'X') = NVL(dii.TYPE_EVT_DEP, 'X')
    AND NVL(dii3.RECEIPT_METHOD, 'X') = NVL(dii.RECEIPT_METHOD, 'X')
    AND NVL(dii3.TYPE_PIECE, 'X') = NVL(dii.TYPE_PIECE, 'X')
    AND NVL(dii3.REGION, 'X') = NVL(dii.REGION, 'X')
    AND NVL(dii3.COMMENTS, 'X') = NVL(dii.COMMENTS, 'X')
    GROUP BY 
        NVL(dii3.ORIGIN, 'X'), NVL(dii3.CATEGORY, 'X'), NVL(dii3.COMPANY_CODE, 'X'), 
        NVL(dii3.INVOICE_NUMBER, 'X'), NVL(dii3.TASK_CODE, 'X'), NVL(dii3.ANALYTIC_NATURE, 'X'),
        NVL(dii3.LOCAL_ACCOUNT, 'X'), NVL(dii3.SUB_ACCOUNT, 'X'), NVL(dii3.TAX_CODE, 'X'), 
        NVL(dii3.TAX_RATE, 'X'), NVL(dii3.DEBIT_OR_CREDIT, 'X'), NVL(TO_CHAR(dii3.FMT_AMOUNT), 'X'), 
        NVL(TO_CHAR(dii3.FMT_INFO_TYPE), 'X'), NVL(TO_CHAR(dii3.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
        NVL(TO_CHAR(dii3.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
        NVL(dii3.FMT_ORIGIN, 'X'), NVL(TO_CHAR(dii3.LINE_NUMBER), 'X'), NVL(dii3.TYPMVT, 'X'), 
        NVL(dii3.LINK_TO_NUMBER, 'X'),
        NVL(dii3.INFO_TYPE, 'X'), NVL(dii3.SEGMENTATION, 'X'), NVL(dii3.LINE_TYPE, 'X'), 
        NVL(dii3.SIGN, 'X'), NVL(dii3.AMOUNT, 'X'), NVL(dii3.CURRENCY, 'X'), 
        NVL(dii3.DESCRIPTION, 'X'), NVL(dii3.QUANTITY, 'X'), NVL(dii3.FUNCTION_CODE, 'X'),
        NVL(dii3.OA_STATUS, 'X'), NVL(TO_CHAR(dii3.OA_REQUEST_ID), 'X'), NVL(TO_CHAR(dii3.GROUP_ID), 'X'), 
        NVL(dii3.TAX_EQUAL_FLAG, 'X'), NVL(dii3.TAX_LINE_TYPE, 'X'), NVL(dii3.FIC_IDENT, 'X'), 
        NVL(dii3.TYPE_EVT_DEP, 'X'), NVL(dii3.RECEIPT_METHOD, 'X'), NVL(dii3.TYPE_PIECE, 'X'), 
        NVL(dii3.REGION, 'X'), NVL(dii3.COMMENTS, 'X')
    HAVING COUNT(*) > 1
);

-- =====================================================================
-- VERSION 2 : Approche alternative plus performante avec ROW_NUMBER()
-- Recommandé pour de grosses volumétries
-- =====================================================================

SELECT *
FROM (
    SELECT 
        dii.*,
        ROW_NUMBER() OVER (
            PARTITION BY 
                NVL(ORIGIN, 'X'), 
                NVL(CATEGORY, 'X'), 
                NVL(COMPANY_CODE, 'X'), 
                NVL(INVOICE_NUMBER, 'X'), 
                NVL(TASK_CODE, 'X'), 
                NVL(ANALYTIC_NATURE, 'X'),
                NVL(LOCAL_ACCOUNT, 'X'), 
                NVL(SUB_ACCOUNT, 'X'), 
                NVL(TAX_CODE, 'X'), 
                NVL(TAX_RATE, 'X'), 
                NVL(DEBIT_OR_CREDIT, 'X'), 
                NVL(TO_CHAR(FMT_AMOUNT), 'X'), 
                NVL(TO_CHAR(FMT_INFO_TYPE), 'X'), 
                NVL(TO_CHAR(FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
                NVL(TO_CHAR(FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
                NVL(FMT_ORIGIN, 'X'), 
                NVL(TO_CHAR(LINE_NUMBER), 'X'), 
                NVL(TYPMVT, 'X'), 
                NVL(LINK_TO_NUMBER, 'X'),
                -- Décommenter si vous voulez inclure GL_DATE dans la détection
                -- NVL(GL_DATE, 'X'),
                NVL(INFO_TYPE, 'X'), 
                NVL(SEGMENTATION, 'X'), 
                NVL(LINE_TYPE, 'X'), 
                NVL(SIGN, 'X'), 
                NVL(AMOUNT, 'X'), 
                NVL(CURRENCY, 'X'), 
                NVL(DESCRIPTION, 'X'), 
                NVL(QUANTITY, 'X'), 
                NVL(FUNCTION_CODE, 'X'),
                NVL(OA_STATUS, 'X'), 
                NVL(TO_CHAR(OA_REQUEST_ID), 'X'), 
                NVL(TO_CHAR(GROUP_ID), 'X'), 
                NVL(TAX_EQUAL_FLAG, 'X'), 
                NVL(TAX_LINE_TYPE, 'X'), 
                NVL(FIC_IDENT, 'X'), 
                NVL(TYPE_EVT_DEP, 'X'), 
                NVL(RECEIPT_METHOD, 'X'), 
                NVL(TYPE_PIECE, 'X'), 
                NVL(REGION, 'X'), 
                NVL(COMMENTS, 'X')
            ORDER BY IARPAFAC_ID  -- Garde le plus petit ID (le plus ancien)
        ) AS rn
    FROM DKA.DKA_IARPAFAC_INTERFACE dii
)
WHERE rn > 1;  -- Retourne uniquement les doublons (pas le premier de chaque groupe)

-- =====================================================================
-- VERSION 3 : Pour DELETE (à utiliser avec PRÉCAUTION !)
-- Supprime les doublons et garde uniquement le plus ancien
-- =====================================================================

/*
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE
WHERE IARPAFAC_ID IN (
    SELECT IARPAFAC_ID
    FROM (
        SELECT 
            IARPAFAC_ID,
            ROW_NUMBER() OVER (
                PARTITION BY 
                    NVL(ORIGIN, 'X'), NVL(CATEGORY, 'X'), NVL(COMPANY_CODE, 'X'), 
                    NVL(INVOICE_NUMBER, 'X'), NVL(TASK_CODE, 'X'), NVL(ANALYTIC_NATURE, 'X'),
                    NVL(LOCAL_ACCOUNT, 'X'), NVL(SUB_ACCOUNT, 'X'), NVL(TAX_CODE, 'X'), 
                    NVL(TAX_RATE, 'X'), NVL(DEBIT_OR_CREDIT, 'X'), 
                    NVL(TO_CHAR(FMT_AMOUNT), 'X'), NVL(TO_CHAR(FMT_INFO_TYPE), 'X'), 
                    NVL(TO_CHAR(FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
                    NVL(TO_CHAR(FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
                    NVL(FMT_ORIGIN, 'X'), NVL(TO_CHAR(LINE_NUMBER), 'X'), 
                    NVL(TYPMVT, 'X'), NVL(LINK_TO_NUMBER, 'X'),
                    NVL(INFO_TYPE, 'X'), NVL(SEGMENTATION, 'X'), NVL(LINE_TYPE, 'X'), 
                    NVL(SIGN, 'X'), NVL(AMOUNT, 'X'), NVL(CURRENCY, 'X'), 
                    NVL(DESCRIPTION, 'X'), NVL(QUANTITY, 'X'), NVL(FUNCTION_CODE, 'X'),
                    NVL(OA_STATUS, 'X'), NVL(TO_CHAR(OA_REQUEST_ID), 'X'), 
                    NVL(TO_CHAR(GROUP_ID), 'X'), 
                    NVL(TAX_EQUAL_FLAG, 'X'), NVL(TAX_LINE_TYPE, 'X'), NVL(FIC_IDENT, 'X'), 
                    NVL(TYPE_EVT_DEP, 'X'), NVL(RECEIPT_METHOD, 'X'), NVL(TYPE_PIECE, 'X'), 
                    NVL(REGION, 'X'), NVL(COMMENTS, 'X')
                ORDER BY IARPAFAC_ID
            ) AS rn
        FROM DKA.DKA_IARPAFAC_INTERFACE
    )
    WHERE rn > 1
);

COMMIT;
*/
