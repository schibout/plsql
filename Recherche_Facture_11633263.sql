-- =====================================================================
-- Recherche complète pour la facture 11633263 du fournisseur 27254
-- =====================================================================
-- Date de création : 21/05/2024
-- Base de données  : Oracle EBS Production
--
-- OBJECTIF : Extraire toutes les informations pertinentes pour la facture 11633263
--            du fournisseur avec le segment1 '27254' et le site 'FRA35510'.
-- =====================================================================

-- =====================================================================
-- PARTIE 1 : Informations générales du fournisseur
-- =====================================================================
SELECT 
    APS.VENDOR_ID,
    APS.VENDOR_NAME,
    APS.SEGMENT1 AS NUMERO_FOURNISSEUR,
    APS.VENDOR_TYPE_LOOKUP_CODE AS TYPE_FOURNISSEUR,
    APS.ENABLED_FLAG AS ACTIF,
    APS.START_DATE_ACTIVE AS DATE_DEBUT_VALIDITE,
    APS.END_DATE_ACTIVE AS DATE_FIN_VALIDITE,
    APS.CREATION_DATE,
    APS.LAST_UPDATE_DATE
FROM 
    AP.AP_SUPPLIERS APS
WHERE 
    APS.SEGMENT1 = '27254';

-- =====================================================================
-- PARTIE 2 : Détails du site fournisseur
-- =====================================================================
SELECT 
    -- Identification
    APSA.VENDOR_SITE_ID,
    APSA.VENDOR_SITE_CODE AS CODE_SITE,
    HOU.NAME AS OPERATING_UNIT,
    APSA.ORG_ID,
    
    -- Adresse
    APSA.ADDRESS_LINE1 || ' ' || APSA.ADDRESS_LINE2 || ' ' || APSA.ADDRESS_LINE3 AS ADRESSE,
    APSA.CITY AS VILLE,
    APSA.ZIP AS CODE_POSTAL,
    APSA.COUNTRY AS PAYS,
    
    -- Statut
    APSA.INACTIVE_DATE AS DATE_INACTIVATION,
    
    -- Options
    APSA.PURCHASING_SITE_FLAG AS SITE_ACHATS,
    APSA.PAY_SITE_FLAG AS SITE_PAIEMENT,
    APSA.PAYMENT_METHOD_LOOKUP_CODE AS METHODE_PAIEMENT,
    APSA.PAY_GROUP_LOOKUP_CODE AS GROUPE_PAIEMENT
FROM 
    AP.AP_SUPPLIER_SITES_ALL APSA
    INNER JOIN AP.AP_SUPPLIERS APS 
        ON APSA.VENDOR_ID = APS.VENDOR_ID
    LEFT OUTER JOIN HR.HR_OPERATING_UNITS HOU 
        ON APSA.ORG_ID = HOU.ORGANIZATION_ID
WHERE 
    APS.SEGMENT1 = '27254'
    AND APSA.VENDOR_SITE_CODE = 'FRA35510';

-- =====================================================================
-- PARTIE 2.1 : Attributs du site fournisseur (potentiel ID iValua)
-- =====================================================================
SELECT
    APSA.ATTRIBUTE_CATEGORY,
    APSA.ATTRIBUTE1,
    APSA.ATTRIBUTE2,
    APSA.ATTRIBUTE3,
    APSA.ATTRIBUTE4, -- Suspecté d'être l'ID iValua
    APSA.ATTRIBUTE5,
    APSA.ATTRIBUTE6,
    APSA.ATTRIBUTE7,
    APSA.ATTRIBUTE8,
    APSA.ATTRIBUTE9,
    APSA.ATTRIBUTE10,
    APSA.ATTRIBUTE11,
    APSA.ATTRIBUTE12,
    APSA.ATTRIBUTE13,
    APSA.ATTRIBUTE14,
    APSA.ATTRIBUTE15
FROM
    AP.AP_SUPPLIER_SITES_ALL APSA
JOIN AP.AP_SUPPLIERS APS ON APSA.VENDOR_ID = APS.VENDOR_ID
WHERE APS.SEGMENT1 = '27254' AND APSA.VENDOR_SITE_CODE = 'FRA35510';

-- =====================================================================
-- PARTIE 3 : Informations sur la facture
-- =====================================================================
SELECT 
    AIA.INVOICE_ID,
    AIA.INVOICE_NUM AS NUMERO_FACTURE,
    AIA.INVOICE_DATE AS DATE_FACTURE,
    AIA.GL_DATE AS DATE_COMPTABLE,
    AIA.INVOICE_AMOUNT AS MONTANT_FACTURE,
    AIA.INVOICE_CURRENCY_CODE AS DEVISE,
    AIA.PAYMENT_STATUS_FLAG AS STATUT_PAIEMENT,
    DECODE(AIA.PAYMENT_STATUS_FLAG, 'N', 'Non payée', 'P', 'Partiellement payée', 'Y', 'Payée') AS STATUT_PAIEMENT_LIBELLE,
    AIA.AMOUNT_PAID AS MONTANT_PAYE,
    AIA.SOURCE,
    AIA.DESCRIPTION,
    AIA.CREATION_DATE,
    AIA.LAST_UPDATE_DATE,
    (SELECT USER_NAME FROM FND_USER WHERE USER_ID = AIA.CREATED_BY) AS CREE_PAR
FROM 
    AP.AP_INVOICES_ALL AIA
WHERE 
    AIA.INVOICE_NUM = '11633263'
    AND AIA.VENDOR_ID = (SELECT VENDOR_ID FROM AP.AP_SUPPLIERS WHERE SEGMENT1 = '27254');

-- =====================================================================
-- PARTIE 4 : Lignes de distribution de la facture (imputations)
-- =====================================================================
SELECT 
    AIDA.DISTRIBUTION_LINE_NUMBER AS NUM_LIGNE_DIST,
    AIDA.LINE_TYPE_LOOKUP_CODE AS TYPE_LIGNE,
    AIDA.AMOUNT AS MONTANT,
    AIDA.DESCRIPTION,
    GCC.CONCATENATED_SEGMENTS AS CODE_COMPTABLE,
    AIDA.POSTED_FLAG AS COMPTABILISE
FROM 
    AP.AP_INVOICE_DISTRIBUTIONS_ALL AIDA
    LEFT OUTER JOIN GL.GL_CODE_COMBINATIONS_KFV GCC
        ON AIDA.DIST_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
WHERE 
    AIDA.INVOICE_ID = (SELECT INVOICE_ID FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '11633263' AND VENDOR_ID = (SELECT VENDOR_ID FROM AP.AP_SUPPLIERS WHERE SEGMENT1 = '27254'));

-- =====================================================================
-- PARTIE 5 : Paiements liés à la facture
-- =====================================================================
SELECT
    AIPA.AMOUNT,
    AIPA.PAYMENT_NUM,
    ACA.CHECK_DATE AS DATE_PAIEMENT,
    ACA.STATUS_LOOKUP_CODE AS STATUT_PAIEMENT
FROM AP.AP_INVOICE_PAYMENTS_ALL AIPA
JOIN AP.AP_CHECKS_ALL ACA ON AIPA.CHECK_ID = ACA.CHECK_ID
WHERE AIPA.INVOICE_ID = (SELECT INVOICE_ID FROM AP.AP_INVOICES_ALL WHERE INVOICE_NUM = '11633263' AND VENDOR_ID = (SELECT VENDOR_ID FROM AP.AP_SUPPLIERS WHERE SEGMENT1 = '27254'));