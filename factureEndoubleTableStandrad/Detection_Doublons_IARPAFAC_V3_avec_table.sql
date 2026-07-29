-- =====================================================================
-- Requête d'identification des doublons via table DOUBLON - VERSION 3
-- =====================================================================
-- Date de création : 09/03/2026
-- Base de données : Oracle EBS 19.28.0.0.0
--
-- DESCRIPTION :
-- Cette requête utilise la table DKA_IARPAFAC_INTERFACE_DOUBLON
-- (créée préalablement) pour identifier tous les enregistrements en doublon
-- avec indication de l'action à effectuer (GARDER ou SUPPRIMER)
--
-- PREREQUIS :
-- La table DKA_IARPAFAC_INTERFACE_DOUBLON doit exister et être à jour
-- =====================================================================

SELECT 
    dii.IARPAFAC_ID,
    dii.CREATION_DATE,
    dii.ORIGIN,
    dii.CATEGORY,
    dii.COMPANY_CODE,
    dii.INVOICE_NUMBER,
    dii.TASK_CODE,
    dii.FMT_AMOUNT,
    dii.GL_DATE,
    dii.LINE_NUMBER,
    dii.AMOUNT,
    dii.CURRENCY,
    dii.DESCRIPTION,
    dii.OA_STATUS,
    dii.OA_REQUEST_ID,
    -- Statistiques du groupe de doublons
    dbl.NB_DOUBLONS,
    dbl.MIN_IARPAFAC_ID,
    dbl.MAX_IARPAFAC_ID,
    dbl.MIN_CREATION_DATE AS GROUPE_MIN_CREATION_DATE,
    dbl.MAX_CREATION_DATE AS GROUPE_MAX_CREATION_DATE,
    -- Indicateur : garder ou supprimer
    CASE 
        WHEN dii.IARPAFAC_ID = dbl.MIN_IARPAFAC_ID THEN 'GARDER'
        ELSE 'SUPPRIMER'
    END AS ACTION
FROM DKA.DKA_IARPAFAC_INTERFACE dii
INNER JOIN DKA.DKA_IARPAFAC_INTERFACE_DOUBLON dbl
    ON NVL(dii.ORIGIN, 'X') = dbl.ORIGIN
    AND NVL(dii.CATEGORY, 'X') = dbl.CATEGORY
    AND NVL(dii.COMPANY_CODE, 'X') = dbl.COMPANY_CODE
    AND NVL(dii.INVOICE_NUMBER, 'X') = dbl.INVOICE_NUMBER
    AND NVL(dii.TASK_CODE, 'X') = dbl.TASK_CODE
    AND NVL(dii.ANALYTIC_NATURE, 'X') = dbl.ANALYTIC_NATURE
    AND NVL(dii.LOCAL_ACCOUNT, 'X') = dbl.LOCAL_ACCOUNT
    AND NVL(dii.SUB_ACCOUNT, 'X') = dbl.SUB_ACCOUNT
    AND NVL(dii.TAX_CODE, 'X') = dbl.TAX_CODE
    AND NVL(dii.TAX_RATE, 'X') = dbl.TAX_RATE
    AND NVL(dii.DEBIT_OR_CREDIT, 'X') = dbl.DEBIT_OR_CREDIT
    AND NVL(TO_CHAR(dii.FMT_AMOUNT), 'X') = dbl.FMT_AMOUNT
    AND NVL(TO_CHAR(dii.FMT_INFO_TYPE), 'X') = dbl.FMT_INFO_TYPE
    AND NVL(TO_CHAR(dii.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X') = dbl.FMT_INVOICE_DATE
    AND NVL(TO_CHAR(dii.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X') = dbl.FMT_DUE_DATE
    AND NVL(dii.FMT_ORIGIN, 'X') = dbl.FMT_ORIGIN
    AND NVL(TO_CHAR(dii.LINE_NUMBER), 'X') = dbl.LINE_NUMBER
    AND NVL(dii.TYPMVT, 'X') = dbl.TYPMVT
    AND NVL(dii.LINK_TO_NUMBER, 'X') = dbl.LINK_TO_NUMBER
    AND NVL(dii.GL_DATE, 'X') = dbl.GL_DATE
    AND NVL(dii.INFO_TYPE, 'X') = dbl.INFO_TYPE
    AND NVL(dii.SEGMENTATION, 'X') = dbl.SEGMENTATION
    AND NVL(dii.LINE_TYPE, 'X') = dbl.LINE_TYPE
    AND NVL(dii.SIGN, 'X') = dbl.SIGN
    AND NVL(dii.AMOUNT, 'X') = dbl.AMOUNT
    AND NVL(dii.CURRENCY, 'X') = dbl.CURRENCY
    AND NVL(dii.DESCRIPTION, 'X') = dbl.DESCRIPTION
    AND NVL(dii.QUANTITY, 'X') = dbl.QUANTITY
    AND NVL(dii.FUNCTION_CODE, 'X') = dbl.FUNCTION_CODE
    AND NVL(dii.OA_STATUS, 'X') = dbl.OA_STATUS
    AND NVL(TO_CHAR(dii.OA_REQUEST_ID), 'X') = dbl.OA_REQUEST_ID
    AND NVL(TO_CHAR(dii.GROUP_ID), 'X') = dbl.GROUP_ID
    AND NVL(dii.TAX_EQUAL_FLAG, 'X') = dbl.TAX_EQUAL_FLAG
    AND NVL(dii.TAX_LINE_TYPE, 'X') = dbl.TAX_LINE_TYPE
    AND NVL(dii.FIC_IDENT, 'X') = dbl.FIC_IDENT
    AND NVL(dii.TYPE_EVT_DEP, 'X') = dbl.TYPE_EVT_DEP
    AND NVL(dii.RECEIPT_METHOD, 'X') = dbl.RECEIPT_METHOD
    AND NVL(dii.TYPE_PIECE, 'X') = dbl.TYPE_PIECE
    AND NVL(dii.REGION, 'X') = dbl.REGION
    AND NVL(dii.COMMENTS, 'X') = dbl.COMMENTS
ORDER BY 
    dbl.NB_DOUBLONS DESC,
    dbl.COMPANY_CODE,
    dbl.INVOICE_NUMBER,
    dii.IARPAFAC_ID;

-- =====================================================================
-- Requête de COMPTAGE des doublons à supprimer - VERSION 4A
-- =====================================================================
-- Date de création : 09/03/2026
-- Cette requête compte les enregistrements qui seront supprimés
-- (tous sauf le MIN_IARPAFAC_ID de chaque groupe)
-- =====================================================================

SELECT COUNT(*) AS NB_LIGNES_A_SUPPRIMER
FROM DKA.DKA_IARPAFAC_INTERFACE dii
WHERE EXISTS (
    SELECT 1
    FROM DKA.DKA_IARPAFAC_INTERFACE_DOUBLON dbl
    WHERE NVL(dii.ORIGIN, 'X') = dbl.ORIGIN
    AND NVL(dii.CATEGORY, 'X') = dbl.CATEGORY
    AND NVL(dii.COMPANY_CODE, 'X') = dbl.COMPANY_CODE
    AND NVL(dii.INVOICE_NUMBER, 'X') = dbl.INVOICE_NUMBER
    AND NVL(dii.TASK_CODE, 'X') = dbl.TASK_CODE
    AND NVL(dii.ANALYTIC_NATURE, 'X') = dbl.ANALYTIC_NATURE
    AND NVL(dii.LOCAL_ACCOUNT, 'X') = dbl.LOCAL_ACCOUNT
    AND NVL(dii.SUB_ACCOUNT, 'X') = dbl.SUB_ACCOUNT
    AND NVL(dii.TAX_CODE, 'X') = dbl.TAX_CODE
    AND NVL(dii.TAX_RATE, 'X') = dbl.TAX_RATE
    AND NVL(dii.DEBIT_OR_CREDIT, 'X') = dbl.DEBIT_OR_CREDIT
    AND NVL(TO_CHAR(dii.FMT_AMOUNT), 'X') = dbl.FMT_AMOUNT
    AND NVL(TO_CHAR(dii.FMT_INFO_TYPE), 'X') = dbl.FMT_INFO_TYPE
    AND NVL(TO_CHAR(dii.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X') = dbl.FMT_INVOICE_DATE
    AND NVL(TO_CHAR(dii.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X') = dbl.FMT_DUE_DATE
    AND NVL(dii.FMT_ORIGIN, 'X') = dbl.FMT_ORIGIN
    AND NVL(TO_CHAR(dii.LINE_NUMBER), 'X') = dbl.LINE_NUMBER
    AND NVL(dii.TYPMVT, 'X') = dbl.TYPMVT
    AND NVL(dii.LINK_TO_NUMBER, 'X') = dbl.LINK_TO_NUMBER
    AND NVL(dii.GL_DATE, 'X') = dbl.GL_DATE
    AND NVL(dii.INFO_TYPE, 'X') = dbl.INFO_TYPE
    AND NVL(dii.SEGMENTATION, 'X') = dbl.SEGMENTATION
    AND NVL(dii.LINE_TYPE, 'X') = dbl.LINE_TYPE
    AND NVL(dii.SIGN, 'X') = dbl.SIGN
    AND NVL(dii.AMOUNT, 'X') = dbl.AMOUNT
    AND NVL(dii.CURRENCY, 'X') = dbl.CURRENCY
    AND NVL(dii.DESCRIPTION, 'X') = dbl.DESCRIPTION
    AND NVL(dii.QUANTITY, 'X') = dbl.QUANTITY
    AND NVL(dii.FUNCTION_CODE, 'X') = dbl.FUNCTION_CODE
    AND NVL(dii.OA_STATUS, 'X') = dbl.OA_STATUS
    AND NVL(TO_CHAR(dii.OA_REQUEST_ID), 'X') = dbl.OA_REQUEST_ID
    AND NVL(TO_CHAR(dii.GROUP_ID), 'X') = dbl.GROUP_ID
    AND NVL(dii.TAX_EQUAL_FLAG, 'X') = dbl.TAX_EQUAL_FLAG
    AND NVL(dii.TAX_LINE_TYPE, 'X') = dbl.TAX_LINE_TYPE
    AND NVL(dii.FIC_IDENT, 'X') = dbl.FIC_IDENT
    AND NVL(dii.TYPE_EVT_DEP, 'X') = dbl.TYPE_EVT_DEP
    AND NVL(dii.RECEIPT_METHOD, 'X') = dbl.RECEIPT_METHOD
    AND NVL(dii.TYPE_PIECE, 'X') = dbl.TYPE_PIECE
    AND NVL(dii.REGION, 'X') = dbl.REGION
    AND NVL(dii.COMMENTS, 'X') = dbl.COMMENTS
    AND dii.IARPAFAC_ID != dbl.MIN_IARPAFAC_ID  -- Garder le MIN, supprimer les autres
);

-- =====================================================================
-- Requête de SUPPRESSION des doublons - VERSION 4B
-- =====================================================================
-- Date de création : 09/03/2026
-- ATTENTION : Cette requête supprime DÉFINITIVEMENT les données
-- 
-- PROCEDURE RECOMMANDEE :
-- 1. Exécuter la requête de comptage ci-dessus
-- 2. Vérifier que le nombre correspond à vos attentes
-- 3. Faire un BACKUP de la table avant suppression
-- 4. Décommenter la requête ci-dessous
-- 5. Exécuter la suppression
-- 6. Vérifier le résultat
-- 7. COMMIT si OK, ROLLBACK sinon
-- =====================================================================

/*
DELETE FROM DKA.DKA_IARPAFAC_INTERFACE dii
WHERE EXISTS (
    SELECT 1
    FROM DKA.DKA_IARPAFAC_INTERFACE_DOUBLON dbl
    WHERE NVL(dii.ORIGIN, 'X') = dbl.ORIGIN
    AND NVL(dii.CATEGORY, 'X') = dbl.CATEGORY
    AND NVL(dii.COMPANY_CODE, 'X') = dbl.COMPANY_CODE
    AND NVL(dii.INVOICE_NUMBER, 'X') = dbl.INVOICE_NUMBER
    AND NVL(dii.TASK_CODE, 'X') = dbl.TASK_CODE
    AND NVL(dii.ANALYTIC_NATURE, 'X') = dbl.ANALYTIC_NATURE
    AND NVL(dii.LOCAL_ACCOUNT, 'X') = dbl.LOCAL_ACCOUNT
    AND NVL(dii.SUB_ACCOUNT, 'X') = dbl.SUB_ACCOUNT
    AND NVL(dii.TAX_CODE, 'X') = dbl.TAX_CODE
    AND NVL(dii.TAX_RATE, 'X') = dbl.TAX_RATE
    AND NVL(dii.DEBIT_OR_CREDIT, 'X') = dbl.DEBIT_OR_CREDIT
    AND NVL(TO_CHAR(dii.FMT_AMOUNT), 'X') = dbl.FMT_AMOUNT
    AND NVL(TO_CHAR(dii.FMT_INFO_TYPE), 'X') = dbl.FMT_INFO_TYPE
    AND NVL(TO_CHAR(dii.FMT_INVOICE_DATE, 'YYYYMMDDHH24MISS'), 'X') = dbl.FMT_INVOICE_DATE
    AND NVL(TO_CHAR(dii.FMT_DUE_DATE, 'YYYYMMDDHH24MISS'), 'X') = dbl.FMT_DUE_DATE
    AND NVL(dii.FMT_ORIGIN, 'X') = dbl.FMT_ORIGIN
    AND NVL(TO_CHAR(dii.LINE_NUMBER), 'X') = dbl.LINE_NUMBER
    AND NVL(dii.TYPMVT, 'X') = dbl.TYPMVT
    AND NVL(dii.LINK_TO_NUMBER, 'X') = dbl.LINK_TO_NUMBER
    AND NVL(dii.GL_DATE, 'X') = dbl.GL_DATE
    AND NVL(dii.INFO_TYPE, 'X') = dbl.INFO_TYPE
    AND NVL(dii.SEGMENTATION, 'X') = dbl.SEGMENTATION
    AND NVL(dii.LINE_TYPE, 'X') = dbl.LINE_TYPE
    AND NVL(dii.SIGN, 'X') = dbl.SIGN
    AND NVL(dii.AMOUNT, 'X') = dbl.AMOUNT
    AND NVL(dii.CURRENCY, 'X') = dbl.CURRENCY
    AND NVL(dii.DESCRIPTION, 'X') = dbl.DESCRIPTION
    AND NVL(dii.QUANTITY, 'X') = dbl.QUANTITY
    AND NVL(dii.FUNCTION_CODE, 'X') = dbl.FUNCTION_CODE
    AND NVL(dii.OA_STATUS, 'X') = dbl.OA_STATUS
    AND NVL(TO_CHAR(dii.OA_REQUEST_ID), 'X') = dbl.OA_REQUEST_ID
    AND NVL(TO_CHAR(dii.GROUP_ID), 'X') = dbl.GROUP_ID
    AND NVL(dii.TAX_EQUAL_FLAG, 'X') = dbl.TAX_EQUAL_FLAG
    AND NVL(dii.TAX_LINE_TYPE, 'X') = dbl.TAX_LINE_TYPE
    AND NVL(dii.FIC_IDENT, 'X') = dbl.FIC_IDENT
    AND NVL(dii.TYPE_EVT_DEP, 'X') = dbl.TYPE_EVT_DEP
    AND NVL(dii.RECEIPT_METHOD, 'X') = dbl.RECEIPT_METHOD
    AND NVL(dii.TYPE_PIECE, 'X') = dbl.TYPE_PIECE
    AND NVL(dii.REGION, 'X') = dbl.REGION
    AND NVL(dii.COMMENTS, 'X') = dbl.COMMENTS
    AND dii.IARPAFAC_ID != dbl.MIN_IARPAFAC_ID  -- Garder le MIN, supprimer les autres
);

-- Vérification après suppression
SELECT 'Lignes supprimées : ' || SQL%ROWCOUNT FROM DUAL;

-- Si tout est OK, décommenter la ligne suivante pour valider :
-- COMMIT;

-- Si problème, décommenter la ligne suivante pour annuler :
-- ROLLBACK;
*/
