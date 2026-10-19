CREATE OR REPLACE TRIGGER dka_ap_invoice_dist_all_bir2
------------------------------------------------------------------------
-- $Id: DKA_AP_INVOICE_DIST_ALL_BIR2.trg 275 2008-03-26 10:47:11Z NORDEST\tbonduae $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AP_INVOICE_DIST_ALL_BIR2.trg
-- DESCRIPTION       : Trigger sur la table ap_invoice_distributions_all
--- AUTEUR           : Grégory Vanackere (Capgemini)
--- DATE DE CREATION : 27/01/2006
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------
--- 2016/09/02 JJA Portage Helios R12
------------------------------------------------------------------------
BEFORE INSERT
ON ap_invoice_distributions_all
FOR EACH ROW
when (NEW.line_type_lookup_code = 'TAX')
BEGIN
  UPDATE ap_invoices_all aia
     SET aia.vat_code = (SELECT name
                         FROM   ap_tax_codes_all
                         WHERE  tax_id = :NEW.tax_code_id)
   WHERE     aia.invoice_id = :NEW.invoice_id
         AND aia.source IN ('SCAN_XGS')
         AND aia.vat_code IS NULL;
         
EXCEPTION
  WHEN OTHERS THEN
    app_exception.raise_exception;
END dka_ap_invoice_dist_all_bir2;
/

SHOW ERRORS TRIGGER dka_ap_invoice_dist_all_bir2
EXIT