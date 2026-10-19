create or replace TRIGGER DKA_AP_INVOICES_INTERFACE_BIUR
   BEFORE
   UPDATE or INSERT
   ON ap.ap_invoices_interface
   FOR EACH ROW
----------------------------------------------------------------------------------------------
-- $Id: DKA_AP_INVOICES_INTERFACE_BIUR.trg$
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AP_INVOICES_INTERFACE_BIUR.trg
-- DESCRIPTION       : Trigger sur la table AP_INVOICES_INTERFACE
-- SPECIFIQUE        : SPE202 - Remboursement client avoir a figurer sur la facture AP
---
--- AUTEUR           : Redouane BELAYACHI
--- DATE DE CREATION : 14/11/2016
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
DECLARE
  V_BILL_TO_SITE_USE_ID     NUMBER;
  V_CUSTOMER_TRX_ID         NUMBER;
  V_SEGMENT1                VARCHAR2(150);
  V_SEGMENT2                VARCHAR2(150);
  V_SEGMENT3                VARCHAR2(150);
  V_SEGMENT4                VARCHAR2(150);
  V_SEGMENT5                VARCHAR2(150);
  V_SEGMENT6                VARCHAR2(150);
  V_SEGMENT7                VARCHAR2(150);
  V_SEGMENT8                VARCHAR2(150);
  V_SEGMENT9                VARCHAR2(150);
  V_SEGMENT10               VARCHAR2(150);
  V_SEGMENT11               VARCHAR2(150);
  V_SEGMENT12               VARCHAR2(150);
  
BEGIN
    -- 
    IF :NEW.invoice_type_lookup_code = 'PAYMENT REQUEST' AND :NEW.source = 'Receivables' AND :NEW.product_table = 'AR_RECEIVABLE_APPLICATIONS_ALL' THEN
      
      -- Alimentation du numero de l avoir.
      SELECT 'Av '|| TRX_NUMBER, 
             'Av '|| TRX_NUMBER, 
             BILL_TO_SITE_USE_ID,
             CUSTOMER_TRX_ID
      INTO   :NEW.DESCRIPTION,
             :NEW.REMITTANCE_MESSAGE1,
             V_BILL_TO_SITE_USE_ID,
             V_CUSTOMER_TRX_ID
      FROM RA_CUSTOMER_TRX_ALL
      WHERE customer_trx_id = ( SELECT customer_trx_id
                                FROM AR_RECEIVABLE_APPLICATIONS_ALL
                                WHERE receivable_application_id = :NEW.REFERENCE_KEY1
                               );
    
      -- Alimentation de la cle comptable
      
      SELECT SEGMENT1,SEGMENT2,SEGMENT4,SEGMENT6,SEGMENT7,SEGMENT8,SEGMENT9,SEGMENT10,SEGMENT11,SEGMENT12  
      INTO   V_SEGMENT1,V_SEGMENT2,V_SEGMENT4,V_SEGMENT6,V_SEGMENT7,V_SEGMENT8,V_SEGMENT9,V_SEGMENT10,V_SEGMENT11,V_SEGMENT12
      FROM GL_CODE_COMBINATIONS 
      WHERE CODE_COMBINATION_ID = ( SELECT ACCTS_PAY_CODE_COMBINATION_ID
                                    FROM FINANCIALS_SYSTEM_PARAMETERS
                                   ); 

      v_segment3 := FND_PROFILE.value('DKA_LIAB_AR_REFUND');
      
      SELECT SEGMENT5 
      INTO v_segment5
      FROM GL_CODE_COMBINATIONS
      WHERE CODE_COMBINATION_ID  = (SELECT CODE_COMBINATION_ID
                                    FROM RA_CUST_TRX_LINE_GL_DIST_ALL 
                                    WHERE  CUSTOMER_TRX_ID = V_CUSTOMER_TRX_ID  
                                    AND ACCOUNT_CLASS = 'REC' 
                                    );

      -- Renseigner les segments de la cle comptable
      :NEW.ACCTS_PAY_CODE_CONCATENATED := V_SEGMENT1||'.'||V_SEGMENT2||'.'||V_SEGMENT3||'.'||V_SEGMENT4||'.'||V_SEGMENT5||'.'||V_SEGMENT6||'.'||V_SEGMENT7||'.'||V_SEGMENT8||'.'||V_SEGMENT9||'.'||V_SEGMENT10||'.'||V_SEGMENT11||'.'||V_SEGMENT12;
    
      -- Positionner le flag Exclusive payment a Y
      :NEW.EXCLUSIVE_PAYMENT_FLAG := 'Y';
    
    END IF;

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/
SHOW ERRORS;
EXIT;