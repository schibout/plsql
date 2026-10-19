----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_IBY_EXT_PAYEE_RELATIONSHIPS.trg
-- DESCRIPTION       : Trigger sur la table IBY_EXT_PAYEE_RELATIONSHIPS
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
PROMPT CREATION DU TRIGGER DKA_IBY_EXT_PAYEE_RELATION
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER DKA_IBY_EXT_PAYEE_RELATION
    AFTER INSERT OR UPDATE OR DELETE
    ON IBY_EXT_PAYEE_RELATIONSHIPS
    FOR EACH ROW
    
DECLARE
   
  vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
   vv_user_name                 VARCHAR2(50);
  pn_vendor_id       NUMBER ;
  pn_vendor_name     varchar2(100);
  pn_vendor_site_code  varchar2(100);
  pn_vendor_name_old    varchar2(100);
  pn_vendor_site_code_old  varchar2(100);
BEGIN

	 dka_sapfrs_history_pkg.get_vendor_id (:NEW.SUPPLIER_SITE_ID, 
						                     pn_vendor_id      );
											 

											 
              vt_field_names(1) := 'Nom du fournisseur pour le règlement';
              vt_field_names(2) := 'Site fournisseur pour le règlement';
              vt_field_names(3) := 'Principal (Oui/Non)';
              vt_field_names(4) := 'Date de début';
              vt_field_names(5) := 'Date de fin';

              
              -- les anciennes valeurs des champs à tracer
 
 dka_sapfrs_history_pkg.get_vendor_name (:OLD.REMIT_SUPPLIER_SITE_ID,
										    pn_vendor_name_old,
											pn_vendor_site_code_old);  
											
              vt_field_old_values(1) :=  pn_vendor_name_old ;--OLD.REMIT_PARTY_ID;
              vt_field_old_values(2) :=  pn_vendor_site_code_old; --OLD.REMIT_SUPPLIER_SITE_ID;
              vt_field_old_values(3) := :OLD.PRIMARY_FLAG;
              vt_field_old_values(4) := :OLD.FROM_DATE;
              vt_field_old_values(5) := :OLD.TO_DATE;
              
              -- les nouvelles valeurs des champs à tracer

 dka_sapfrs_history_pkg.get_vendor_name (:NEW.REMIT_SUPPLIER_SITE_ID,
										    pn_vendor_name,
											pn_vendor_site_code);  
              
              vt_field_new_values(1) := pn_vendor_name;--NEW.REMIT_PARTY_ID;
              vt_field_new_values(2) := pn_vendor_site_code;--NEW.REMIT_SUPPLIER_SITE_ID;                      
              vt_field_new_values(3) := :NEW.PRIMARY_FLAG;           
              vt_field_new_values(4) := :NEW.FROM_DATE;                
              vt_field_new_values(5) := :NEW.TO_DATE;
    dka_sapfrs_history_pkg.get_user_name( :NEW.last_updated_by, vv_user_name);

  IF vv_user_name = 'EXPLOITATION'  THEN
    RETURN;
    else           
        if  pn_vendor_id is not null then               
			   IF INSERTING 
				 THEN
					 dka_sapfrs_history_pkg.insert_supplier_sites_history('CREATION',                  -- Type de l'opération DML                                               
																  pn_vendor_id,              --
																  :NEW.SUPPLIER_SITE_ID,         -- --                                                        
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
																  :NEW.SUPPLIER_SITE_ID,              -- --                                                        
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
																  :NEW.SUPPLIER_SITE_ID,                 -- --                                                        
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
