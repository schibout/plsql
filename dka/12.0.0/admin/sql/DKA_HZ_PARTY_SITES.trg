----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_HZ_PARTY_SITES.trg
-- DESCRIPTION       : Trigger sur la table HZ_PARTY_SITES
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
PROMPT CREATION DU TRIGGER DKA_HZ_PARTY_SITES
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER DKA_HZ_PARTY_SITES
    AFTER INSERT OR UPDATE OR DELETE
    ON HZ_PARTY_SITES
    FOR EACH ROW
    
DECLARE
   
  vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
  vv_user_name                 VARCHAR2(50);
  pn_vendor_id       NUMBER ;
  pn_vendor_site_id   NUMBER;
  
BEGIN
    
	 dka_sapfrs_history_pkg.get_vendor_party (:NEW.party_site_id  , 
						    pn_vendor_id      ,
							pn_vendor_site_id ) ;


    vt_field_names(1) := 'Nom de l''adresse';
    vt_field_names(2) := 'Statut';

              
     -- les anciennes valeurs des champs à  tracer
              
    vt_field_old_values(1) := :OLD.PARTY_SITE_NAME;
    vt_field_old_values(2) := :OLD.STATUS;

              
    -- les nouvelles valeurs des champs à  tracer
              
    vt_field_new_values(1) := :NEW.PARTY_SITE_NAME;
    vt_field_new_values(2) := :NEW.STATUS;
              
    dka_sapfrs_history_pkg.get_user_name( :NEW.last_updated_by, vv_user_name);

  IF vv_user_name = 'EXPLOITATION'  THEN
    RETURN;
    else            
          IF INSERTING 
         THEN
             dka_sapfrs_history_pkg.insert_supplier_sites_history('CREATION',         -- Type de l'opération DML                                               
                                                          :NEW.party_site_id,         --
                                                          :NEW.party_site_id,         -- --                                                        
                                                          :NEW.last_update_date,       -- -- -- valeurs permanentes
                                                          :NEW.last_updated_by,        -- --
                                                          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                          vt_field_old_values,         -- Anciennes valeurs -> NULL 
                                                          vt_field_new_values          -- Nouvelles valeurs                           
                                                         );  
         ELSIF UPDATING
         THEN
		 
		
             dka_sapfrs_history_pkg.insert_supplier_sites_history('MODIFICATION',              -- Type de l'opération DML                                            
                                                          pn_vendor_id,                    --
                                                          pn_vendor_site_id,       -- --                                                        
                                                          :NEW.last_update_date,       -- -- -- valeurs permanentes
                                                          :NEW.last_updated_by,        -- 
                                                          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                          vt_field_old_values,         -- Anciennes valeurs -> NULL 
                                                          vt_field_new_values          -- Nouvelles valeurs                                       
                                                         );  
        ELSIF DELETING
         THEN
              dka_sapfrs_history_pkg.insert_supplier_sites_history('SUPPRESSION',              -- Type de l'opération DML                                            
                                                           pn_vendor_id,                       --
                                                           pn_vendor_site_id,          -- --                                                        
                                                          :NEW.last_update_date,       -- -- -- valeurs permanentes
                                                          :NEW.last_updated_by,        -- 
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
