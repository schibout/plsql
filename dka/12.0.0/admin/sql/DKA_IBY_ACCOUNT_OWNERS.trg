----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_IBY_ACCOUNT_OWNERS.trg
-- DESCRIPTION       : Trigger sur la table IBY_ACCOUNT_OWNERS
---
--- AUTEUR           : Saloua HAHIOUI (SHA)
--- DATE DE CREATION : 21/12/2021
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER DKA_IBY_ACCOUNT_OWNERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER DKA_IBY_ACCOUNT_OWNERS
    AFTER INSERT OR UPDATE OR DELETE
    ON IBY_ACCOUNT_OWNERS
    FOR EACH ROW
    
DECLARE
   
  vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
   vv_user_name                 VARCHAR2(50);
  
  pn_vendor_id       NUMBER ;
  pn_vendor_site_id   NUMBER;

PRAGMA AUTONOMOUS_TRANSACTION;  
  
BEGIN
        dka_sapfrs_history_pkg.get_vendor_site_id (:NEW.ACCOUNT_OWNER_PARTY_ID, 
						                           pn_vendor_site_id      );
     
		dka_sapfrs_history_pkg.get_vendor_id (pn_vendor_site_id, 
						                      pn_vendor_id      );	
                                              
                                              
              vt_field_names(1) := 'Date de fin d''affectation du compte bancaire';

              
              -- les anciennes valeurs des champs à  tracer
              
              vt_field_old_values(1) := :OLD.END_DATE;

              
              -- les nouvelles valeurs des champs à  tracer
              
              vt_field_new_values(1) := :NEW.END_DATE;

 dka_sapfrs_history_pkg.get_user_name( :NEW.last_updated_by, vv_user_name);

  IF vv_user_name = 'EXPLOITATION'  THEN
    RETURN;
    else
        if  pn_vendor_id is not null then     
               
			  IF INSERTING 
			 THEN
			 
				 dka_sapfrs_history_pkg.insert_supplier_sites_history('CREATION',                  -- Type de l'opération DML                                               
															  pn_vendor_id,              --
															  pn_vendor_site_id,         -- --                                                        
															  :NEW.last_update_date,       -- -- -- valeurs permanentes
															  :NEW.last_updated_by,        -- --
															  vt_field_names,              -- Chaine contenant la liste des champs tracés
															  vt_field_old_values,         -- Anciennes valeurs -> NULL 
															  vt_field_new_values          -- Nouvelles valeurs                           
															 );  

	
			 ELSIF UPDATING
			 THEN
				 dka_sapfrs_history_pkg.insert_supplier_sites_history('MODIFICATION',              -- Type de l'opération DML                                            
															  pn_vendor_id,          
															  pn_vendor_site_id,              -- --                                                        
															  :NEW.last_update_date,       -- -- -- valeurs permanentes
															  :NEW.last_updated_by,        -- 
															  vt_field_names,              -- Chaine contenant la liste des champs tracés
															  vt_field_old_values,         -- Anciennes valeurs -> NULL 
															  vt_field_new_values          -- Nouvelles valeurs                                       
															 );  
			ELSIF DELETING
			 THEN
				  dka_sapfrs_history_pkg.insert_supplier_sites_history('SUPPRESSION',              -- Type de l'opération DML                                            
															  pn_vendor_id,          
															  pn_vendor_site_id,                 -- --                                                        
															  :NEW.last_update_date,       -- -- -- valeurs permanentes
															  :NEW.last_updated_by,        -- 
															  vt_field_names,              -- Chaine contenant la liste des champs tracés
															  vt_field_old_values,         -- Anciennes valeurs -> NULL 
															  vt_field_new_values          -- Nouvelles valeurs                                       
															 );                                  
			 END IF;
		   
        end if;
end if;

EXCEPTION
    WHEN OTHERS THEN
      NULL;
END;
/

SHOW ERROR
EXIT;
