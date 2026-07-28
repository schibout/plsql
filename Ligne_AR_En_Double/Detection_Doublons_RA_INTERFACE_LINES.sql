-- =====================================================================
-- Détection de Doublons - RA_INTERFACE_LINES_ALL
-- =====================================================================
-- Date de création : 05/03/2026
-- Auteur : GitHub Copilot
-- Base de données : Oracle EBS Production
--
-- OBJECTIF : Identifier les doublons dans RA_INTERFACE_LINES_ALL
--            basé sur la contrainte unique DKA_RA_INTERFACE_LINES_U1
--
-- MAPPING DU PACKAGE DKA_IARPAFAC_PKG :
--   INTERFACE_LINE_ATTRIBUTE1 = ORIGIN (GCA, CYC, etc.)
--   INTERFACE_LINE_ATTRIBUTE2 = COMPANY_CODE (0001, 0441, etc.)
--   INTERFACE_LINE_ATTRIBUTE3 = INVOICE_NUMBER (N° facture)
--   INTERFACE_LINE_ATTRIBUTE4 = LINE_NUMBER (N° ligne)
--   INTERFACE_LINE_ATTRIBUTE5 = Période YYYYMM (202601, etc.)
--   REQUEST_ID = ID du programme concurrent
--
-- VOIR : Analyse_RA_INTERFACE_LINES_ALL.md
-- =====================================================================

SET LINESIZE 200
SET PAGESIZE 1000

-- =============================================================================
-- REQUÊTE 1 : Vue d'ensemble des doublons (7 derniers jours)
-- =============================================================================

PROMPT =====================================================
PROMPT REQUÊTE 1 : VUE D'ENSEMBLE DES DOUBLONS
PROMPT =====================================================
PROMPT

SELECT 
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1 AS ORIGIN,           -- GCA, CYC, etc.
    INTERFACE_LINE_ATTRIBUTE2 AS COMPANY_CODE,     -- 0001, 0441, etc.
    INTERFACE_LINE_ATTRIBUTE3 AS INVOICE_NUMBER,   -- N° facture
    INTERFACE_LINE_ATTRIBUTE4 AS LINE_NUMBER,      -- N° ligne
    INTERFACE_LINE_ATTRIBUTE5 AS PERIOD_YYYYMM,    -- Période (202601)
    REQUEST_ID,
    COUNT(*) AS NB_DOUBLONS,
    MIN(INTERFACE_LINE_ID) AS ID_MIN,
    MAX(INTERFACE_LINE_ID) AS ID_MAX,
    MIN(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS PREMIERE_CREATION,
    MAX(TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS')) AS DERNIERE_CREATION,
    SUM(NVL(AMOUNT, 0)) AS MONTANT_TOTAL
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS IS NULL  -- Lignes non traitées uniquement
  AND CREATION_DATE >= TRUNC(SYSDATE) - 7  -- 7 derniers jours
GROUP BY 
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1,  -- ORIGIN
    INTERFACE_LINE_ATTRIBUTE2,  -- COMPANY_CODE
    INTERFACE_LINE_ATTRIBUTE3,  -- INVOICE_NUMBER
    INTERFACE_LINE_ATTRIBUTE4,  -- LINE_NUMBER
    INTERFACE_LINE_ATTRIBUTE5,  -- Période
    REQUEST_ID
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4;

-- =============================================================================
-- REQUÊTE 2 : Version simplifiée avec alias métier
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT REQUÊTE 2 : VERSION SIMPLIFIÉE AVEC ALIAS MÉTIER
PROMPT =====================================================
PROMPT

SELECT 
    INTERFACE_LINE_ATTRIBUTE1 AS ORIGIN,
    INTERFACE_LINE_ATTRIBUTE2 AS COMPANY,
    INTERFACE_LINE_ATTRIBUTE3 AS FACTURE,
    INTERFACE_LINE_ATTRIBUTE4 AS LIGNE,
    INTERFACE_LINE_ATTRIBUTE5 AS PERIODE,
    REQUEST_ID,
    COUNT(*) AS DOUBLONS,
    SUM(NVL(AMOUNT, 0)) AS TOTAL_EUROS,
    LISTAGG(INTERFACE_LINE_ID, ', ') WITHIN GROUP (ORDER BY INTERFACE_LINE_ID) AS LISTE_IDS
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS IS NULL
  AND CREATION_DATE >= TRUNC(SYSDATE) - 7
GROUP BY 
    INTERFACE_LINE_ATTRIBUTE1, 
    INTERFACE_LINE_ATTRIBUTE2, 
    INTERFACE_LINE_ATTRIBUTE3, 
    INTERFACE_LINE_ATTRIBUTE4, 
    INTERFACE_LINE_ATTRIBUTE5, 
    REQUEST_ID
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4;

-- =============================================================================
-- REQUÊTE 3 : Tous les statuts (traités + non traités)
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT REQUÊTE 3 : TOUS LES STATUTS (TRAITÉS + NON TRAITÉS)
PROMPT =====================================================
PROMPT

SELECT 
    INTERFACE_LINE_ATTRIBUTE1 AS ORIGIN,
    INTERFACE_LINE_ATTRIBUTE2 AS COMPANY_CODE,
    INTERFACE_LINE_ATTRIBUTE3 AS INVOICE_NUMBER,
    INTERFACE_LINE_ATTRIBUTE4 AS LINE_NUMBER,
    INTERFACE_LINE_ATTRIBUTE5 AS PERIOD_YYYYMM,
    REQUEST_ID,
    INTERFACE_STATUS,
    COUNT(*) AS NB_DOUBLONS,
    LISTAGG(INTERFACE_LINE_ID, ',') WITHIN GROUP (ORDER BY INTERFACE_LINE_ID) AS LISTE_IDS
FROM AR.RA_INTERFACE_LINES_ALL
WHERE CREATION_DATE >= TRUNC(SYSDATE) - 7
GROUP BY 
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1,
    INTERFACE_LINE_ATTRIBUTE2,
    INTERFACE_LINE_ATTRIBUTE3,
    INTERFACE_LINE_ATTRIBUTE4,
    INTERFACE_LINE_ATTRIBUTE5,
    REQUEST_ID,
    INTERFACE_STATUS
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC, INTERFACE_STATUS, INTERFACE_LINE_ATTRIBUTE3;

-- =============================================================================
-- REQUÊTE 4 : Doublons pour un REQUEST_ID spécifique
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT REQUÊTE 4 : DOUBLONS POUR UN REQUEST_ID SPÉCIFIQUE
PROMPT =====================================================
PROMPT Remplacer :p_request_id par votre valeur
PROMPT

SELECT 
    INTERFACE_LINE_ATTRIBUTE1 AS ORIGIN,
    INTERFACE_LINE_ATTRIBUTE2 AS COMPANY_CODE,
    INTERFACE_LINE_ATTRIBUTE3 AS INVOICE_NUMBER,
    INTERFACE_LINE_ATTRIBUTE4 AS LINE_NUMBER,
    COUNT(*) AS NB_DOUBLONS,
    SUM(NVL(AMOUNT, 0)) AS MONTANT_TOTAL,
    LISTAGG(INTERFACE_LINE_ID, ', ') WITHIN GROUP (ORDER BY INTERFACE_LINE_ID) AS IDS
FROM AR.RA_INTERFACE_LINES_ALL
WHERE REQUEST_ID = :p_request_id  -- Remplacer par votre REQUEST_ID
GROUP BY 
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1,
    INTERFACE_LINE_ATTRIBUTE2,
    INTERFACE_LINE_ATTRIBUTE3,
    INTERFACE_LINE_ATTRIBUTE4,
    INTERFACE_LINE_ATTRIBUTE5,
    REQUEST_ID
HAVING COUNT(*) > 1
ORDER BY INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4;

-- =============================================================================
-- REQUÊTE 5 : Analyse d'une facture spécifique
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT REQUÊTE 5 : ANALYSE D'UNE FACTURE SPÉCIFIQUE
PROMPT =====================================================
PROMPT Remplacer les paramètres par vos valeurs
PROMPT

SELECT 
    INTERFACE_LINE_ID,
    INTERFACE_LINE_ATTRIBUTE1 AS ORIGIN,
    INTERFACE_LINE_ATTRIBUTE2 AS COMPANY_CODE,
    INTERFACE_LINE_ATTRIBUTE3 AS INVOICE_NUMBER,
    INTERFACE_LINE_ATTRIBUTE4 AS LINE_NUMBER,
    LINE_TYPE,
    AMOUNT,
    DESCRIPTION,
    INTERFACE_STATUS,
    ERROR_MESSAGE,
    TO_CHAR(CREATION_DATE, 'DD/MM/YYYY HH24:MI:SS') AS CREATION,
    REQUEST_ID
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_LINE_ATTRIBUTE3 = :p_invoice_number  -- Ex: '0001S2601P211'
  AND INTERFACE_LINE_ATTRIBUTE1 = :p_origin          -- Ex: 'GCA'
  AND INTERFACE_LINE_ATTRIBUTE2 = :p_company_code    -- Ex: '0001'
ORDER BY 
    TO_NUMBER(INTERFACE_LINE_ATTRIBUTE4),  -- LINE_NUMBER numérique
    INTERFACE_LINE_ID;

-- =============================================================================
-- REQUÊTE 6 : CAS TYPIQUE - Même LINE_NUMBER, montants différents
-- =============================================================================
-- Type de doublon identifié dans l'incident TP12011976
-- Plusieurs lignes PRODUIT avec même LINE_NUMBER mais montants différents
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT REQUÊTE 6 : CAS TYPIQUE - MÊME LIGNE, MONTANTS DIFFÉRENTS
PROMPT =====================================================
PROMPT Identifie les doublons comme dans l'incident TP12011976
PROMPT

SELECT 
    INTERFACE_LINE_ATTRIBUTE3 AS FACTURE,
    INTERFACE_LINE_ATTRIBUTE4 AS LINE_NUMBER,
    COUNT(*) AS NB_LIGNES,
    COUNT(DISTINCT AMOUNT) AS NB_MONTANTS_DIFFERENTS,
    SUM(NVL(AMOUNT, 0)) AS MONTANT_TOTAL,
    LISTAGG(TO_CHAR(AMOUNT, '999999.99'), ' + ') 
        WITHIN GROUP (ORDER BY INTERFACE_LINE_ID) AS DETAIL_MONTANTS,
    LISTAGG(INTERFACE_LINE_ID, ', ') 
        WITHIN GROUP (ORDER BY INTERFACE_LINE_ID) AS LISTE_IDS
FROM AR.RA_INTERFACE_LINES_ALL
WHERE INTERFACE_STATUS IS NULL
  AND LINE_TYPE = 'LINE'  -- Lignes de détail uniquement
  AND CREATION_DATE >= TRUNC(SYSDATE) - 7
GROUP BY 
    INTERFACE_LINE_CONTEXT,
    INTERFACE_LINE_ATTRIBUTE1,
    INTERFACE_LINE_ATTRIBUTE2,
    INTERFACE_LINE_ATTRIBUTE3,
    INTERFACE_LINE_ATTRIBUTE4,
    INTERFACE_LINE_ATTRIBUTE5,
    REQUEST_ID
HAVING COUNT(*) > 1  -- Doublons
   AND COUNT(DISTINCT AMOUNT) > 1  -- Avec montants différents
ORDER BY COUNT(*) DESC, INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4;

-- =============================================================================
-- REQUÊTE 7 : Statistiques globales par REQUEST_ID
-- =============================================================================

PROMPT
PROMPT =====================================================
PROMPT REQUÊTE 7 : STATISTIQUES GLOBALES PAR REQUEST_ID
PROMPT =====================================================
PROMPT

SELECT 
    REQUEST_ID,
    COUNT(*) AS NB_LIGNES_TOTAL,
    COUNT(DISTINCT INTERFACE_LINE_ATTRIBUTE3) AS NB_FACTURES,
    SUM(CASE WHEN INTERFACE_STATUS IS NULL THEN 1 ELSE 0 END) AS NON_TRAITE,
    SUM(CASE WHEN INTERFACE_STATUS = 'SUCCESS' THEN 1 ELSE 0 END) AS SUCCES,
    SUM(CASE WHEN INTERFACE_STATUS = 'ERROR' THEN 1 ELSE 0 END) AS ERREUR,
    MIN(CREATION_DATE) AS DATE_DEBUT,
    MAX(LAST_UPDATE_DATE) AS DATE_FIN,
    SUM(NVL(AMOUNT, 0)) AS MONTANT_TOTAL,
    -- Comptage des doublons potentiels
    COUNT(*) - COUNT(DISTINCT 
        INTERFACE_LINE_CONTEXT || '|' ||
        INTERFACE_LINE_ATTRIBUTE1 || '|' ||
        INTERFACE_LINE_ATTRIBUTE2 || '|' ||
        INTERFACE_LINE_ATTRIBUTE3 || '|' ||
        INTERFACE_LINE_ATTRIBUTE4 || '|' ||
        INTERFACE_LINE_ATTRIBUTE5 || '|' ||
        TO_CHAR(REQUEST_ID)
    ) AS NB_DOUBLONS_POTENTIELS
FROM AR.RA_INTERFACE_LINES_ALL
WHERE CREATION_DATE >= TRUNC(SYSDATE) - 30  -- 30 derniers jours
GROUP BY REQUEST_ID
HAVING COUNT(*) - COUNT(DISTINCT 
        INTERFACE_LINE_CONTEXT || '|' ||
        INTERFACE_LINE_ATTRIBUTE1 || '|' ||
        INTERFACE_LINE_ATTRIBUTE2 || '|' ||
        INTERFACE_LINE_ATTRIBUTE3 || '|' ||
        INTERFACE_LINE_ATTRIBUTE4 || '|' ||
        INTERFACE_LINE_ATTRIBUTE5 || '|' ||
        TO_CHAR(REQUEST_ID)
    ) > 0  -- Afficher uniquement les REQUEST_ID avec doublons
ORDER BY NB_DOUBLONS_POTENTIELS DESC, REQUEST_ID DESC;

PROMPT
PROMPT =====================================================
PROMPT FIN DES REQUÊTES DE DÉTECTION
PROMPT =====================================================
PROMPT
PROMPT Pour plus d'informations, consulter :
PROMPT - Analyse_RA_INTERFACE_LINES_ALL.md (documentation complète)
PROMPT - TP12011976/analyse.md (incident ORA-00001)
PROMPT
