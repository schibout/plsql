CREATE OR REPLACE TRIGGER DKA_AP_INVOICES_ALL_BIUR
----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI 
-- PROJET           : DALKIA Helios R12
-- NOM              : DKA_AP_INVOICES_ALL_BIUR
-- DESCRIPTION      : Alimentation du champ ATTRIBUTE2 de la table AP_INVOICES_ALL
--
-- AUTEUR           : Maxime EGOT
-- DATE DE CREATION : 20/07/16
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------

  BEFORE INSERT OR UPDATE ON ap_invoices_all
  FOR EACH ROW

BEGIN

  IF :new.vendor_site_id IS NOT NULL 
      AND NVL(TO_NUMBER(:new.ATTRIBUTE2),-1) <> :new.vendor_site_id THEN
  
    :new.ATTRIBUTE2 := :new.vendor_site_id;
  
  END IF;

END;
/
SHOW ERRORS;
EXIT;
