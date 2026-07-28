-- =====================================================================
-- Mise à Jour AP_INVOICES_ALL - LAST_UPDATE_DATE = SYSDATE
-- Contexte : Synchronisation DacShop
-- =====================================================================
-- Date de création : 14/04/2026
-- Auteur           : H00035381F (Samir CHIBOUT)
-- Base de données  : Oracle EBS 12.2.13 (Database 19.25.0.0.0)
--
-- DESCRIPTION :
--   Met à jour le champ LAST_UPDATE_DATE à SYSDATE ainsi que les
--   champs d'audit LAST_UPDATED_BY et LAST_UPDATE_LOGIN sur les
--   factures AP ciblées (adapter le WHERE en SECTION 2).
--
-- UTILISATION :
--   1. Adapter les paramètres ci-dessous (DEFINE)
--   2. Adapter le filtre WHERE de la SECTION 2 si nécessaire
--   3. Exécuter via SQLcl / SQL*Plus
-- =====================================================================


-- =====================================================================
-- PARAMETRES : à adapter avant exécution
-- =====================================================================
DEFINE V_INVOICE_NUM  = 'XXXXX'    -- Numéro de facture cible (ou commentez le WHERE correspondant)
DEFINE V_INVOICE_ID   = 0          -- INVOICE_ID cible (0 = tous les critères WHERE)

PROMPT ============================================================
PROMPT Paramètres : INVOICE_NUM=&V_INVOICE_NUM  /  INVOICE_ID=&V_INVOICE_ID
PROMPT ============================================================


-- =====================================================================
-- SECTION 0 : Initialisation de la session Oracle EBS
-- =====================================================================
-- USER_ID  : 36313  -> H00035381F (Samir CHIBOUT)
-- RESP_ID  : 51214  -> Administrateur Exploitation Dalkia
-- APP_ID   : 50001
-- =====================================================================
PROMPT ============================================================
PROMPT SECTION 0 : Initialisation de la session Oracle EBS
PROMPT ============================================================

BEGIN
    FND_GLOBAL.APPS_INITIALIZE(
        user_id      => 36313,   -- H00035381F (Samir CHIBOUT)
        resp_id      => 51214,   -- Administrateur Exploitation Dalkia
        resp_appl_id => 50001
    );
    DBMS_OUTPUT.PUT_LINE('Session initialisee : USER=' || FND_GLOBAL.USER_NAME
                         || ' / RESP=' || FND_GLOBAL.RESP_NAME);
END;
/


-- =====================================================================
-- SECTION 1 : Vérification AVANT mise à jour
-- =====================================================================
PROMPT ============================================================
PROMPT SECTION 1 : Factures ciblées (AVANT mise à jour)
PROMPT ============================================================

SELECT
    AIA.INVOICE_ID,
    AIA.INVOICE_NUM,
    APS.VENDOR_NAME,
    AIA.INVOICE_AMOUNT,
    AIA.INVOICE_CURRENCY_CODE,
    TO_CHAR(AIA.INVOICE_DATE,     'DD/MM/YYYY')         AS INVOICE_DATE,
    TO_CHAR(AIA.LAST_UPDATE_DATE, 'DD/MM/YYYY HH24:MI') AS LAST_UPDATE_DATE,
    AIA.LAST_UPDATED_BY,
    AIA.APPROVAL_STATUS,
    AIA.PAYMENT_STATUS_FLAG
FROM
    AP.AP_INVOICES_ALL  AIA
    JOIN AP.AP_SUPPLIERS APS ON AIA.VENDOR_ID = APS.VENDOR_ID
WHERE
    AIA.INVOICE_ID = &V_INVOICE_ID
    -- OU adapter le critère selon le besoin :
    -- AIA.INVOICE_NUM = '&V_INVOICE_NUM'
    -- AIA.SOURCE = 'DACSHOP'
ORDER BY
    AIA.INVOICE_DATE DESC;


-- =====================================================================
-- SECTION 2 : Mise à jour LAST_UPDATE_DATE = SYSDATE
-- =====================================================================
PROMPT ============================================================
PROMPT SECTION 2 : Mise à jour en cours...
PROMPT ============================================================

UPDATE AP.AP_INVOICES_ALL AIA
SET
    AIA.LAST_UPDATE_DATE  = SYSDATE,
    AIA.LAST_UPDATED_BY   = FND_GLOBAL.USER_ID,   -- H00035381F via session initialisée
    AIA.LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID
WHERE
    AIA.INVOICE_ID = &V_INVOICE_ID;
    -- OU adapter le critère selon le besoin :
    -- AIA.INVOICE_NUM = '&V_INVOICE_NUM'
    -- AIA.SOURCE = 'DACSHOP'

PROMPT Lignes mises à jour :
-- (SQLcl / SQL*Plus affiche automatiquement "N rows updated.")


-- =====================================================================
-- SECTION 3 : Validation
-- =====================================================================
COMMIT;

PROMPT ============================================================
PROMPT SECTION 3 : Commit effectué - vérification APRÈS mise à jour
PROMPT ============================================================

SELECT
    AIA.INVOICE_ID,
    AIA.INVOICE_NUM,
    APS.VENDOR_NAME,
    AIA.INVOICE_AMOUNT,
    AIA.INVOICE_CURRENCY_CODE,
    TO_CHAR(AIA.INVOICE_DATE,     'DD/MM/YYYY')         AS INVOICE_DATE,
    TO_CHAR(AIA.LAST_UPDATE_DATE, 'DD/MM/YYYY HH24:MI') AS LAST_UPDATE_DATE,
    AIA.LAST_UPDATED_BY,
    AIA.APPROVAL_STATUS,
    AIA.PAYMENT_STATUS_FLAG
FROM
    AP.AP_INVOICES_ALL  AIA
    JOIN AP.AP_SUPPLIERS APS ON AIA.VENDOR_ID = APS.VENDOR_ID
WHERE
    AIA.INVOICE_ID = &V_INVOICE_ID
ORDER BY
    AIA.INVOICE_DATE DESC;

PROMPT ============================================================
PROMPT Traitement terminé.
PROMPT ============================================================
