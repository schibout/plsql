-- =====================================================================
-- Détection des doublons dans DKA_IARPAFAC_INTERFACE - VERSION 1
-- =====================================================================
-- Date de création : 07/03/2026
-- Base de données : Oracle EBS 19.28.0.0.0
--
-- DESCRIPTION :
-- Cette requête détecte les doublons dans la table d'interface AR
-- en utilisant NOT IN avec MIN() pour garder le plus petit IARPAFAC_ID
--
-- CORRECTION ORA-01722 :
-- - Colonnes NUMBER converties avec TO_CHAR : FMT_AMOUNT, FMT_INFO_TYPE, 
--   LINE_NUMBER, OA_REQUEST_ID, GROUP_ID
-- - Colonnes DATE converties avec TO_CHAR : FMT_INVOICE_DATE, FMT_DUE_DATE
--
-- NOTE : GL_DATE est commenté dans le EXISTS pour élargir la recherche
-- =====================================================================

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
-- Requête de statistiques doublons - VERSION 2
-- =====================================================================
-- Cette requête montre les groupes de doublons avec statistiques
-- =====================================================================

SELECT 
        NVL(dii3.ORIGIN, 'X') AS ORIGIN, 
        NVL(dii3.CATEGORY, 'X') AS CATEGORY, 
        NVL(dii3.COMPANY_CODE, 'X') AS COMPANY_CODE, 
        NVL(dii3.INVOICE_NUMBER, 'X') AS INVOICE_NUMBER, 
        NVL(dii3.TASK_CODE, 'X') AS TASK_CODE, 
        NVL(dii3.ANALYTIC_NATURE, 'X') AS ANALYTIC_NATURE,
        NVL(dii3.LOCAL_ACCOUNT, 'X') AS LOCAL_ACCOUNT, 
        NVL(dii3.SUB_ACCOUNT, 'X') AS SUB_ACCOUNT, 
        NVL(dii3.TAX_CODE, 'X') AS TAX_CODE, 
        NVL(dii3.TAX_RATE, 'X') AS TAX_RATE, 
        NVL(dii3.DEBIT_OR_CREDIT, 'X') AS DEBIT_OR_CREDIT, 
        NVL(TO_CHAR(dii3.FMT_AMOUNT), 'X') AS FMT_AMOUNT, 
        NVL(TO_CHAR(dii3.FMT_INFO_TYPE), 'X') AS FMT_INFO_TYPE, 
        NVL(TO_CHAR(dii3.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X') AS FMT_INVOICE_DATE, 
        NVL(TO_CHAR(dii3.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X') AS FMT_DUE_DATE, 
        NVL(dii3.FMT_ORIGIN, 'X') AS FMT_ORIGIN, 
        NVL(TO_CHAR(dii3.LINE_NUMBER), 'X') AS LINE_NUMBER, 
        NVL(dii3.TYPMVT, 'X') AS TYPMVT, 
        NVL(dii3.LINK_TO_NUMBER, 'X') AS LINK_TO_NUMBER,
        NVL(dii3.GL_DATE, 'X') AS GL_DATE,
        NVL(dii3.INFO_TYPE, 'X') AS INFO_TYPE, 
        NVL(dii3.SEGMENTATION, 'X') AS SEGMENTATION, 
        NVL(dii3.LINE_TYPE, 'X') AS LINE_TYPE, 
        NVL(dii3.SIGN, 'X') AS SIGN, 
        NVL(dii3.AMOUNT, 'X') AS AMOUNT, 
        NVL(dii3.CURRENCY, 'X') AS CURRENCY, 
        NVL(dii3.DESCRIPTION, 'X') AS DESCRIPTION, 
        NVL(dii3.QUANTITY, 'X') AS QUANTITY, 
        NVL(dii3.FUNCTION_CODE, 'X') AS FUNCTION_CODE,
        NVL(dii3.OA_STATUS, 'X') AS OA_STATUS, 
        NVL(TO_CHAR(dii3.OA_REQUEST_ID), 'X') AS OA_REQUEST_ID, 
        NVL(TO_CHAR(dii3.GROUP_ID), 'X') AS GROUP_ID, 
        NVL(dii3.TAX_EQUAL_FLAG, 'X') AS TAX_EQUAL_FLAG, 
        NVL(dii3.TAX_LINE_TYPE, 'X') AS TAX_LINE_TYPE, 
        NVL(dii3.FIC_IDENT, 'X') AS FIC_IDENT, 
        NVL(dii3.TYPE_EVT_DEP, 'X') AS TYPE_EVT_DEP, 
        NVL(dii3.RECEIPT_METHOD, 'X') AS RECEIPT_METHOD, 
        NVL(dii3.TYPE_PIECE, 'X') AS TYPE_PIECE, 
        NVL(dii3.REGION, 'X') AS REGION, 
        NVL(dii3.COMMENTS, 'X') AS COMMENTS,
        -- Statistiques
        COUNT(*) AS NB_DOUBLONS,
        MIN(dii3.IARPAFAC_ID) AS MIN_IARPAFAC_ID,
        MAX(dii3.IARPAFAC_ID) AS MAX_IARPAFAC_ID,
        MIN(dii3.CREATION_DATE) AS MIN_CREATION_DATE,
        MAX(dii3.CREATION_DATE) AS MAX_CREATION_DATE
FROM DKA.DKA_IARPAFAC_INTERFACE dii3
GROUP BY 
        NVL(dii3.ORIGIN, 'X'), NVL(dii3.CATEGORY, 'X'), NVL(dii3.COMPANY_CODE, 'X'), 
        NVL(dii3.INVOICE_NUMBER, 'X'), NVL(dii3.TASK_CODE, 'X'), NVL(dii3.ANALYTIC_NATURE, 'X'),
        NVL(dii3.LOCAL_ACCOUNT, 'X'), NVL(dii3.SUB_ACCOUNT, 'X'), NVL(dii3.TAX_CODE, 'X'), 
        NVL(dii3.TAX_RATE, 'X'), NVL(dii3.DEBIT_OR_CREDIT, 'X'), NVL(TO_CHAR(dii3.FMT_AMOUNT), 'X'), 
        NVL(TO_CHAR(dii3.FMT_INFO_TYPE), 'X'), NVL(TO_CHAR(dii3.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
        NVL(TO_CHAR(dii3.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
        NVL(dii3.FMT_ORIGIN, 'X'), NVL(TO_CHAR(dii3.LINE_NUMBER), 'X'), NVL(dii3.TYPMVT, 'X'), 
        NVL(dii3.LINK_TO_NUMBER, 'X'), NVL(dii3.GL_DATE, 'X'),
        NVL(dii3.INFO_TYPE, 'X'), NVL(dii3.SEGMENTATION, 'X'), NVL(dii3.LINE_TYPE, 'X'), 
        NVL(dii3.SIGN, 'X'), NVL(dii3.AMOUNT, 'X'), NVL(dii3.CURRENCY, 'X'), 
        NVL(dii3.DESCRIPTION, 'X'), NVL(dii3.QUANTITY, 'X'), NVL(dii3.FUNCTION_CODE, 'X'),
        NVL(dii3.OA_STATUS, 'X'), NVL(TO_CHAR(dii3.OA_REQUEST_ID), 'X'), NVL(TO_CHAR(dii3.GROUP_ID), 'X'), 
        NVL(dii3.TAX_EQUAL_FLAG, 'X'), NVL(dii3.TAX_LINE_TYPE, 'X'), NVL(dii3.FIC_IDENT, 'X'), 
        NVL(dii3.TYPE_EVT_DEP, 'X'), NVL(dii3.RECEIPT_METHOD, 'X'), NVL(dii3.TYPE_PIECE, 'X'), 
        NVL(dii3.REGION, 'X'), NVL(dii3.COMMENTS, 'X')
HAVING COUNT(*) > 1
ORDER BY NB_DOUBLONS DESC, MIN_CREATION_DATE DESC;

--====================================================================
-- table des doublons
--====================================================================  
create table DKA_IARPAFAC_INTERFACE_DOUBLON
AS 
SELECT      -- Statistiques
        COUNT(*) AS NB_DOUBLONS,
        MIN(dii3.IARPAFAC_ID) AS MIN_IARPAFAC_ID,
        MAX(dii3.IARPAFAC_ID) AS MAX_IARPAFAC_ID,
        MIN(dii3.CREATION_DATE) AS MIN_CREATION_DATE,
        MAX(dii3.CREATION_DATE) AS MAX_CREATION_DATE,
        NVL(dii3.ORIGIN, 'X') AS ORIGIN, 
        NVL(dii3.CATEGORY, 'X') AS CATEGORY, 
        NVL(dii3.COMPANY_CODE, 'X') AS COMPANY_CODE, 
        NVL(dii3.INVOICE_NUMBER, 'X') AS INVOICE_NUMBER, 
        NVL(dii3.TASK_CODE, 'X') AS TASK_CODE, 
        NVL(dii3.ANALYTIC_NATURE, 'X') AS ANALYTIC_NATURE,
        NVL(dii3.LOCAL_ACCOUNT, 'X') AS LOCAL_ACCOUNT, 
        NVL(dii3.SUB_ACCOUNT, 'X') AS SUB_ACCOUNT, 
        NVL(dii3.TAX_CODE, 'X') AS TAX_CODE, 
        NVL(dii3.TAX_RATE, 'X') AS TAX_RATE, 
        NVL(dii3.DEBIT_OR_CREDIT, 'X') AS DEBIT_OR_CREDIT, 
        NVL(TO_CHAR(dii3.FMT_AMOUNT), 'X') AS FMT_AMOUNT, 
        NVL(TO_CHAR(dii3.FMT_INFO_TYPE), 'X') AS FMT_INFO_TYPE, 
        NVL(TO_CHAR(dii3.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X') AS FMT_INVOICE_DATE, 
        NVL(TO_CHAR(dii3.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X') AS FMT_DUE_DATE, 
        NVL(dii3.FMT_ORIGIN, 'X') AS FMT_ORIGIN, 
        NVL(TO_CHAR(dii3.LINE_NUMBER), 'X') AS LINE_NUMBER, 
        NVL(dii3.TYPMVT, 'X') AS TYPMVT, 
        NVL(dii3.LINK_TO_NUMBER, 'X') AS LINK_TO_NUMBER,
        NVL(dii3.GL_DATE, 'X') AS GL_DATE,
        NVL(dii3.INFO_TYPE, 'X') AS INFO_TYPE, 
        NVL(dii3.SEGMENTATION, 'X') AS SEGMENTATION, 
        NVL(dii3.LINE_TYPE, 'X') AS LINE_TYPE, 
        NVL(dii3.SIGN, 'X') AS SIGN, 
        NVL(dii3.AMOUNT, 'X') AS AMOUNT, 
        NVL(dii3.CURRENCY, 'X') AS CURRENCY, 
        NVL(dii3.DESCRIPTION, 'X') AS DESCRIPTION, 
        NVL(dii3.QUANTITY, 'X') AS QUANTITY, 
        NVL(dii3.FUNCTION_CODE, 'X') AS FUNCTION_CODE,
        NVL(dii3.OA_STATUS, 'X') AS OA_STATUS, 
        NVL(TO_CHAR(dii3.OA_REQUEST_ID), 'X') AS OA_REQUEST_ID, 
        NVL(TO_CHAR(dii3.GROUP_ID), 'X') AS GROUP_ID, 
        NVL(dii3.TAX_EQUAL_FLAG, 'X') AS TAX_EQUAL_FLAG, 
        NVL(dii3.TAX_LINE_TYPE, 'X') AS TAX_LINE_TYPE, 
        NVL(dii3.FIC_IDENT, 'X') AS FIC_IDENT, 
        NVL(dii3.TYPE_EVT_DEP, 'X') AS TYPE_EVT_DEP, 
        NVL(dii3.RECEIPT_METHOD, 'X') AS RECEIPT_METHOD, 
        NVL(dii3.TYPE_PIECE, 'X') AS TYPE_PIECE, 
        NVL(dii3.REGION, 'X') AS REGION, 
        NVL(dii3.COMMENTS, 'X') AS COMMENTS 
FROM DKA.DKA_IARPAFAC_INTERFACE dii3
GROUP BY 
        NVL(dii3.ORIGIN, 'X'), NVL(dii3.CATEGORY, 'X'), NVL(dii3.COMPANY_CODE, 'X'), 
        NVL(dii3.INVOICE_NUMBER, 'X'), NVL(dii3.TASK_CODE, 'X'), NVL(dii3.ANALYTIC_NATURE, 'X'),
        NVL(dii3.LOCAL_ACCOUNT, 'X'), NVL(dii3.SUB_ACCOUNT, 'X'), NVL(dii3.TAX_CODE, 'X'), 
        NVL(dii3.TAX_RATE, 'X'), NVL(dii3.DEBIT_OR_CREDIT, 'X'), NVL(TO_CHAR(dii3.FMT_AMOUNT), 'X'), 
        NVL(TO_CHAR(dii3.FMT_INFO_TYPE), 'X'), NVL(TO_CHAR(dii3.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
        NVL(TO_CHAR(dii3.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X'), 
        NVL(dii3.FMT_ORIGIN, 'X'), NVL(TO_CHAR(dii3.LINE_NUMBER), 'X'), NVL(dii3.TYPMVT, 'X'), 
        NVL(dii3.LINK_TO_NUMBER, 'X'), NVL(dii3.GL_DATE, 'X'),
        NVL(dii3.INFO_TYPE, 'X'), NVL(dii3.SEGMENTATION, 'X'), NVL(dii3.LINE_TYPE, 'X'), 
        NVL(dii3.SIGN, 'X'), NVL(dii3.AMOUNT, 'X'), NVL(dii3.CURRENCY, 'X'), 
        NVL(dii3.DESCRIPTION, 'X'), NVL(dii3.QUANTITY, 'X'), NVL(dii3.FUNCTION_CODE, 'X'),
        NVL(dii3.OA_STATUS, 'X'), NVL(TO_CHAR(dii3.OA_REQUEST_ID), 'X'), NVL(TO_CHAR(dii3.GROUP_ID), 'X'), 
        NVL(dii3.TAX_EQUAL_FLAG, 'X'), NVL(dii3.TAX_LINE_TYPE, 'X'), NVL(dii3.FIC_IDENT, 'X'), 
        NVL(dii3.TYPE_EVT_DEP, 'X'), NVL(dii3.RECEIPT_METHOD, 'X'), NVL(dii3.TYPE_PIECE, 'X'), 
        NVL(dii3.REGION, 'X'), NVL(dii3.COMMENTS, 'X')
HAVING COUNT(*) > 1
ORDER BY NB_DOUBLONS DESC, MIN_CREATION_DATE DESC;

-- =====================================================================
-- Requête pour trouver les lignes en erreur pour cause de doublon
-- =====================================================================
-- Cette requête sélectionne les lignes de RA_INTERFACE_LINES_ALL
-- qui ont une erreur spécifique 'Numéro de facture en double'
-- dans la table RA_INTERFACE_ERRORS_ALL.
-- =====================================================================
SELECT
    ril.INTERFACE_LINE_ID,
    ril.INTERFACE_STATUS,
    ril.INTERFACE_LINE_CONTEXT,
    ril.INTERFACE_LINE_ATTRIBUTE1 AS ORIGIN,
    ril.INTERFACE_LINE_ATTRIBUTE2 AS COMPANY_CODE,
    ril.INTERFACE_LINE_ATTRIBUTE3 AS INVOICE_NUMBER, -- Numéro de transaction (facture)
    ril.INTERFACE_LINE_ATTRIBUTE4 AS LINE_NUMBER,    -- Numéro de ligne
    ril.AMOUNT,
    ril.CURRENCY_CODE,
    ril.DESCRIPTION,
    TO_CHAR(ril.CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS DATE_CREATION,
    ril.REQUEST_ID,
    ril.ORG_ID
FROM
    AR.RA_INTERFACE_LINES_ALL ril
WHERE
    ril.interface_line_id IN (
        SELECT rie.interface_line_id
        FROM AR.RA_INTERFACE_ERRORS_ALL rie
        WHERE rie.message_text = 'Numéro de facture en double'
    )
ORDER BY
    INVOICE_NUMBER,
    LINE_NUMBER;