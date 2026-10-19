CREATE OR REPLACE TRIGGER dka_ap_invoice_dist_bir2
----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AP_INVOICE_DIST_BIR2.trg
-- DESCRIPTION       : Trigger sur la table AP_INVOICE_DISTRIBUTIONS_ALL
---
--- AUTEUR           : Maxime EGOT (CAPGEMINI)
--- DATE DE CREATION : 12/04/2017
--- DOC. ASSOCIEE    : artf2131554 : SPE022 - Ne plus alimenter le projet et la tâche à refacturer sur les lignes de factures
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------------------------
--- 19/10/2018 MTIA artf3041110 : INC0257512 - SPE022 - Trigger sur la table AP_INVOICE_DISTRIBUTIONS_ALL - REFAC
--  09/02/2021 NBO TASK0132016 - Etude d'impact mise en place correctif refacturation
----------------------------------------------------------------------------------------------
BEFORE INSERT
    ON ap.ap_invoice_distributions_all
    FOR EACH ROW

when (NEW.attribute1 IS NULL AND NEW.attribute7 IS NULL)
DECLARE
  vv_attribute1 ap_invoice_lines_all.attribute1%TYPE;
  vv_attribute7 ap_invoice_lines_all.attribute7%TYPE;
  vv_errbuf     VARCHAR2(500);
  vn_retcode    NUMBER(15);
  vv_step       VARCHAR2(50);
BEGIN

  SELECT aila.attribute1, aila.attribute7
    INTO vv_attribute1, vv_attribute7
    FROM ap_invoice_lines_all aila
   WHERE aila.invoice_id = :NEW.invoice_id
     AND aila.line_number = :NEW.invoice_line_number;

 --- 19/10/2018 MTIA artf3041110 : Filtre sur type de ligne ITEM pour faire redescendre les informations du CUF
  IF vv_attribute1 IS NOT NULL AND vv_attribute7 IS NOT NULL AND :new.line_type_lookup_code not in('REC_TAX' ,'NONREC_TAX') THEN

    :NEW.attribute1 := vv_attribute1;
    :NEW.attribute7 := vv_attribute7;
    
 --  09/02/2021 NBO TASK0132016 - Etude d'impact mise en place correctif refacturation   
/*
    UPDATE ap_invoice_lines_all aila
       SET aila.attribute1 = NULL,
           aila.attribute7 = NULL
     WHERE aila.invoice_id = :NEW.invoice_id
       AND aila.line_number = :NEW.invoice_line_number;
*/
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    NULL;
END;
/
SHOW ERRORS
EXIT;