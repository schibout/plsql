CREATE OR REPLACE TRIGGER DKA_AP_INVOICES_INT_BIUR
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

  BEFORE INSERT OR UPDATE ON ap_invoices_interface
  FOR EACH ROW

DECLARE
  Vn_vendor_site_id NUMBER;

BEGIN

  IF :new.vendor_site_id IS NOT NULL 
      AND NVL(TO_NUMBER(:new.ATTRIBUTE2),-1) <> :new.vendor_site_id THEN
      
    :new.ATTRIBUTE2 := :new.vendor_site_id;
  
  ELSE
  
    SELECT pvsa.vendor_site_id
      INTO Vn_vendor_site_id
      FROM po_vendor_sites_all pvsa
     WHERE pvsa.vendor_id = :new.vendor_id
       AND pvsa.vendor_site_code = :new.vendor_site_code;
  
    :new.ATTRIBUTE2 := Vn_vendor_site_id;
  
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    NULL;
  
END;
/
SHOW ERRORS;
EXIT;
