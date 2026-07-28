-- =====================================================================
-- Script de Mise à Jour - Facture AP 3850521294
-- =====================================================================
-- Date de création : 31/12/2025
-- Base de données : Oracle EBS 12.2.13 (Database 19.25.0.0.0)
-- Facture : 3850521294 - COMPUTACENTER FRANCE
-- Source : SCAN_XGS
--
-- DESCRIPTION :
-- Script de mise à jour pour la facture fournisseur 3850521294.
-- Utilisateur de mise à jour : EXPLOITATION (USER_ID: 1205)
--
-- =====================================================================

-- =====================================================================
-- Script de Mise à Jour - Facture 3850521294
-- Compatible SQL Developer
-- =====================================================================

-- =====================================================================
-- SECTION 1 : Vérification de l'existence de la facture
-- =====================================================================

SELECT 
    AIA.INVOICE_ID,
    AIA.INVOICE_NUM,
    APS.VENDOR_NAME,
    AIA.INVOICE_AMOUNT,
    AIA.INVOICE_CURRENCY_CODE,
    TO_CHAR(AIA.INVOICE_DATE, 'DD/MM/YYYY') AS INVOICE_DATE,
    AIA.SOURCE,
    AIA.PAYMENT_STATUS_FLAG,
    AIA.APPROVAL_STATUS
FROM 
    AP.AP_INVOICES_ALL AIA
    JOIN AP.AP_SUPPLIERS APS ON AIA.VENDOR_ID = APS.VENDOR_ID
WHERE 
    AIA.INVOICE_NUM = '3850521294';

-- =====================================================================
-- SECTION 2 : Script de mise à jour des champs d'audit
-- =====================================================================

UPDATE AP.AP_INVOICES_ALL
SET 
    LAST_UPDATE_DATE = SYSDATE,
    LAST_UPDATED_BY = 1205,  -- EXPLOITATION
    LAST_UPDATE_LOGIN = USERENV('SESSIONID')
WHERE 
    INVOICE_NUM = '3850521294'
    AND INVOICE_ID = 10897847;

COMMIT;

-- =====================================================================
-- SECTION 3 : Vérification après mise à jour
-- =====================================================================

SELECT 
    AIA.INVOICE_ID,
    AIA.INVOICE_NUM,
    APS.VENDOR_NAME,
    AIA.LAST_UPDATED_BY,
    TO_CHAR(AIA.LAST_UPDATE_DATE, 'DD/MM/YYYY HH24:MI:SS') AS LAST_UPDATE_DATE,
    AIA.LAST_UPDATE_LOGIN
FROM 
    AP.AP_INVOICES_ALL AIA
    JOIN AP.AP_SUPPLIERS APS ON AIA.VENDOR_ID = APS.VENDOR_ID
WHERE 
    AIA.INVOICE_NUM = '3850521294';

-- =====================================================================
-- SECTION 4 : Détails complets de la facture (référence)
-- =====================================================================

SELECT 
    'INVOICE_ID' AS CHAMP, TO_CHAR(INVOICE_ID) AS VALEUR FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'VENDOR_ID', TO_CHAR(VENDOR_ID) FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'VENDOR_SITE_ID', TO_CHAR(VENDOR_SITE_ID) FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'ORG_ID', TO_CHAR(ORG_ID) FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'INVOICE_AMOUNT', TO_CHAR(INVOICE_AMOUNT) FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'INVOICE_CURRENCY_CODE', INVOICE_CURRENCY_CODE FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'INVOICE_DATE', TO_CHAR(INVOICE_DATE, 'DD/MM/YYYY') FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'GL_DATE', TO_CHAR(GL_DATE, 'DD/MM/YYYY') FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'SOURCE', SOURCE FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'DESCRIPTION', DESCRIPTION FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'PAYMENT_STATUS_FLAG', PAYMENT_STATUS_FLAG FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'APPROVAL_STATUS', APPROVAL_STATUS FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'ATTRIBUTE1', NVL(ATTRIBUTE1, '<null>') FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'ATTRIBUTE2', NVL(ATTRIBUTE2, '<null>') FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'ATTRIBUTE_CATEGORY', NVL(ATTRIBUTE_CATEGORY, '<null>') FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'GLOBAL_ATTRIBUTE_CATEGORY', NVL(GLOBAL_ATTRIBUTE_CATEGORY, '<null>') FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
UNION ALL
SELECT 'PO_HEADER_ID', TO_CHAR(PO_HEADER_ID) FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294'
ORDER BY CHAMP;

-- =====================================================================
-- SECTION 5 : Lignes de distribution de la facture
-- =====================================================================

-- =====================================================================
-- SECTION 5 : Lignes de distribution de la facture
-- =====================================================================

SELECT 
    AID.INVOICE_DISTRIBUTION_ID,
    AID.DISTRIBUTION_LINE_NUMBER,
    AID.LINE_TYPE_LOOKUP_CODE,
    AID.AMOUNT,
    GCC.CONCATENATED_SEGMENTS AS CODE_COMPTABLE,
    AID.ACCOUNTING_DATE,
    AID.POSTED_FLAG
FROM 
    AP.AP_INVOICE_DISTRIBUTIONS_ALL AID
    LEFT JOIN GL.GL_CODE_COMBINATIONS_KFV GCC ON AID.DIST_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
WHERE 
    AID.INVOICE_ID = (SELECT INVOICE_ID FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '3850521294')
ORDER BY 
    AID.DISTRIBUTION_LINE_NUMBER;

-- =====================================================================
-- NOTES IMPORTANTES :
-- =====================================================================
-- 1. Cette facture a été créée via SCAN_XGS (source d'import dacshop/XGS)
-- 2. Elle est actuellement PAYÉE (PAYMENT_STATUS_FLAG = 'Y')
-- 3. Elle est APPROUVÉE (APPROVAL_STATUS = 'WFAPPROVED')
-- 4. Toute modification sur une facture payée doit être validée
-- 5. L'utilisateur EXPLOITATION (USER_ID: 1205) sera utilisé pour l'audit
-- 6. Ne pas oublier de COMMIT après les modifications
-- 7. Vérifier l'impact sur la comptabilité avant toute modification
-- =====================================================================
