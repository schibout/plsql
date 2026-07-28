-- =====================================================================
-- Mise à Jour AP_INVOICES_ALL - Date du Jour (SYSDATE)
-- =====================================================================
-- Date de création : 23/03/2026
-- Base de données  : Oracle EBS 12.2.13 (Database 19.25.0.0.0)
--
-- DESCRIPTION :
--   Met à jour le champ LAST_UPDATE_DATE à la date du jour (SYSDATE)
--   ainsi que les champs d'audit LAST_UPDATED_BY et LAST_UPDATE_LOGIN
--   sur les factures AP correspondant aux critères définis en SECTION 2.
--
-- UTILISATION :
--   Adapter le WHERE de la SECTION 2 avant exécution.
--   Lancer via : Lancer_Update_AP.bat
-- =====================================================================


-- =====================================================================
-- PARAMETRE : Numéro de facture à traiter (à modifier ici uniquement)
-- =====================================================================
DEFINE V_INVOICE_NUM = '9258127'
DEFINE V_INVOICE_ID = 9258127 ;  -- S'assure que la valeur est en majuscules

PROMPT Facture ciblée : &V_INVOICE_NUM


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
    TO_CHAR(AIA.INVOICE_DATE,        'DD/MM/YYYY')          AS INVOICE_DATE,
    TO_CHAR(AIA.LAST_UPDATE_DATE,    'DD/MM/YYYY HH24:MI')  AS LAST_UPDATE_DATE,
    AIA.LAST_UPDATED_BY,
    AIA.APPROVAL_STATUS,
    AIA.PAYMENT_STATUS_FLAG
FROM
    AP.AP_INVOICES_ALL  AIA
    JOIN AP.AP_SUPPLIERS APS ON AIA.VENDOR_ID = APS.VENDOR_ID
WHERE
    AIA.INVOICE_ID = '&V_INVOICE_ID'
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
    AIA.LAST_UPDATED_BY   = FND_GLOBAL.USER_ID,  -- H00035381F (Samir CHIBOUT) via session initialisée
    AIA.LAST_UPDATE_LOGIN = FND_GLOBAL.LOGIN_ID
WHERE
    AIA.INVOICE_ID = '&V_INVOICE_ID';

-- Affichage du nombre de lignes mises à jour
PROMPT Lignes mises à jour :
-- (sqlplus/sqlcl affiche automatiquement "N rows updated.")


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
    TO_CHAR(AIA.INVOICE_DATE,        'DD/MM/YYYY')          AS INVOICE_DATE,
    TO_CHAR(AIA.LAST_UPDATE_DATE,    'DD/MM/YYYY HH24:MI')  AS LAST_UPDATE_DATE,
    AIA.LAST_UPDATED_BY,
    AIA.APPROVAL_STATUS,
    AIA.PAYMENT_STATUS_FLAG
FROM
    AP.AP_INVOICES_ALL  AIA
    JOIN AP.AP_SUPPLIERS APS ON AIA.VENDOR_ID = APS.VENDOR_ID
WHERE
    AIA.INVOICE_NUM = '&V_INVOICE_NUM'
ORDER BY
    AIA.INVOICE_DATE DESC;

PROMPT ============================================================
PROMPT Traitement terminé.
PROMPT ============================================================
