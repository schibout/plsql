----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : iby_ext_party_pmt_mthds.trg
-- DESCRIPTION       : Trigger sur la table IBY_EXTERNAL_PAYEES_ALL
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
PROMPT CREATION DU TRIGGER iby_ext_party_pmt_mthds
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER dka_iby_ext_party_pmt_mthd
    AFTER  INSERT OR UPDATE OR DELETE 
    ON iby_ext_party_pmt_mthds
    FOR EACH ROW 
    
DECLARE
   
  vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
  pn_vendor_site_id       NUMBER ; 
  pn_vendor_id            NUMBER ;
   vv_user_name                 VARCHAR2(50);
  pn_mode_payement iby_ext_party_pmt_mthds.PAYMENT_METHOD_CODE%type;
BEGIN							 
              vt_field_names(1) := 'Mode de paiement';

              dka_sapfrs_history_pkg.get_vendor_site_id(:new.ext_pmt_party_id , pn_vendor_site_id);
			  dka_sapfrs_history_pkg.get_vendor_id( pn_vendor_site_id, pn_vendor_id);
			  dka_sapfrs_history_pkg.get_payement_method( :old.ext_pmt_party_id,:old.ext_party_pmt_mthd_id,:old.primary_flag, pn_mode_payement);
              -- les anciennes valeurs des champs à  tracer
              
              vt_field_old_values(1) := pn_mode_payement;
              
              -- les nouvelles valeurs des champs à  tracer
              
              vt_field_new_values(1) := :NEW.PAYMENT_METHOD_CODE;
  dka_sapfrs_history_pkg.get_user_name( :NEW.last_updated_by, vv_user_name);

  IF vv_user_name = 'EXPLOITATION'  THEN
    RETURN;
    else 
        if  pn_vendor_id is not null then 
              
			 IF INSERTING 
			 THEN
				 dka_sapfrs_history_pkg.insert_supplier_mode_p('CREATION',                  -- Type de l'opération DML                                               
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
				 dka_sapfrs_history_pkg.insert_supplier_mode_p('MODIFICATION',              -- Type de l'opération DML                                            
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
				  dka_sapfrs_history_pkg.insert_supplier_mode_p('SUPPRESSION',              -- Type de l'opération DML                                            
															  pn_vendor_id,          
															  pn_vendor_site_id,                 -- --                                                        
															  :NEW.last_update_date,       -- -- -- valeurs permanentes
															  :NEW.last_updated_by,        -- 
															  vt_field_names,              -- Chaine contenant la liste des champs tracés
															  vt_field_old_values,         -- Anciennes valeurs -> NULL 
															  vt_field_new_values          -- Nouvelles valeurs                                       
															 );                                  
			 END IF;
		   
        END IF;
       
    END IF;
EXCEPTION
    WHEN OTHERS THEN
      NULL;
END;
/

SHOW ERROR
EXIT;
