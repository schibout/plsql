---------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AP_SUPPLIERS.trg
-- DESCRIPTION       : Trigger sur la table AP_SUPPLIERS
---
--- AUTEUR           : Anas RAOUF (Capgemini)
--- DATE DE CREATION : 23/12/2021
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER DKA_AP_SUPPLIERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER DKA_AP_SUPPLIERS
    AFTER INSERT OR UPDATE OR DELETE
    ON AP.AP_SUPPLIERS
    FOR EACH ROW
    
DECLARE

	
	vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
	vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
	vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
	
	vv_user_name VARCHAR2(50);
	

BEGIN
	
	dka_sapfrs_history_pkg.get_user_name(:NEW.last_updated_by, vv_user_name);
	
	IF vv_user_name <> 'EXPLOITATION'
	THEN
	
	vt_field_names(1) := 'Nom du fournisseur';
    vt_field_names(2) := 'Type de fournisseur';
    vt_field_names(3) := 'Bloquer le règlement/Toutes les factures';
    vt_field_names(4) := 'Bloquer le règlement/Factures non rapprochée';
    vt_field_names(5) := 'Bloquer le règlement/Factures non validées';
	vt_field_names(6) := 'Statut (Date de désactivation)';
	
	-- les anciennes valeurs des champs à  tracer
	 
	vt_field_old_values(1) := :OLD.VENDOR_NAME;
    vt_field_old_values(2) := :OLD.VENDOR_TYPE_LOOKUP_CODE;
	vt_field_old_values(3) := :OLD.HOLD_ALL_PAYMENTS_FLAG;
    vt_field_old_values(4) := :OLD.HOLD_UNMATCHED_INVOICES_FLAG;
    vt_field_old_values(5) := :OLD.HOLD_FUTURE_PAYMENTS_FLAG;  
    vt_field_old_values(6) := :OLD.END_DATE_ACTIVE;
	 
	-- les nouvelles valeurs des champs à  tracer
	
	vt_field_new_values(1) := :NEW.VENDOR_NAME;
    vt_field_new_values(2) := :NEW.VENDOR_TYPE_LOOKUP_CODE;
	vt_field_new_values(3) := :NEW.HOLD_ALL_PAYMENTS_FLAG;
    vt_field_new_values(4) := :NEW.HOLD_UNMATCHED_INVOICES_FLAG;
    vt_field_new_values(5) := :NEW.HOLD_FUTURE_PAYMENTS_FLAG;
    vt_field_new_values(6) := :NEW.END_DATE_ACTIVE; 
	
	 
	 IF INSERTING 
         THEN
             dka_sapfrs_history_pkg.insert_supplier_history('CREATION',                  -- Type de l'opération DML                                               
                                                          :NEW.vendor_id,              --                     -- --                                                        
                                                          :NEW.last_update_date,       -- -- -- valeurs permanentes
                                                          :NEW.last_updated_by,        -- --                   -- 
                                                          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                          vt_field_old_values,         -- Anciennes valeurs -> NULL 
                                                          vt_field_new_values          -- Nouvelles valeurs                            
                                                         );  
     ELSIF UPDATING
        THEN
             dka_sapfrs_history_pkg.insert_supplier_history('MODIFICATION',              -- Type de l'opération DML                                            
                                                          :NEW.vendor_id,              --                        -- --                                                        
                                                          :NEW.last_update_date,       -- -- -- valeurs permanentes
                                                          :NEW.last_updated_by,        -- --                  -- 
                                                          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                          vt_field_old_values,         -- Anciennes valeurs -> NULL 
                                                          vt_field_new_values          -- Nouvelles valeurs                                       
                                                         );  
	 ELSIF DELETING
        THEN
             dka_sapfrs_history_pkg.insert_supplier_history('SUPPRESSION',              -- Type de l'opération DML                                            
                                                          :NEW.vendor_id,              --                        -- --                                                        
                                                          :NEW.last_update_date,       -- -- -- valeurs permanentes
                                                          :NEW.last_updated_by,        -- --                  -- 
                                                          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                          vt_field_old_values,         -- Anciennes valeurs -> NULL 
                                                          vt_field_new_values          -- Nouvelles valeurs                                       
                                                         );  
                                          
      END IF;
	END IF;

EXCEPTION
    WHEN OTHERS THEN
      NULL;
END;
/

SHOW ERROR
EXIT;
