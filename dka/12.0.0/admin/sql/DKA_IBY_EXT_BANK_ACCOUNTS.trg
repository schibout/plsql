CREATE OR REPLACE TRIGGER APPS.DKA_IBY_EXT_BANK_ACCOUNTS
    AFTER INSERT OR UPDATE OR DELETE
    ON IBY_EXT_BANK_ACCOUNTS
    FOR EACH ROW
DECLARE

  vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
  vv_user_name VARCHAR2(50);
  
  vn_seq_id          NUMBER ;
 -- pn_vendor_id       NUMBER ;
 -- pn_vendor_site_id  NUMBER ;
  
  CURSOR cur_site_fournisseur (pn_ext_bank_account NUMBER) IS
  
 select distinct assa.vendor_site_id, assa.vendor_id 
  from IBY_PMT_INSTR_USES_ALL ipiua, 
  iby_external_payees_all epa, 
  ap_supplier_sites_all assa ,
  AP_suppliers asa,
  iby_ext_bank_accounts eba
 where ipiua.EXT_PMT_PARTY_ID = epa.ext_payee_id
 and assa.VENDOR_SITE_ID = epa.supplier_site_id
 and eba.ext_bank_account_id = instrument_id
 and assa.vendor_id         =  asa.vendor_id
 and eba.ext_bank_account_id = pn_ext_bank_account;
 
 
  
PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
  
              vt_field_names(1) := 'N° de compte bancaire (RIB)';
              vt_field_names(2) := 'Date de fin du compte bancaire';
              vt_field_names(3) := 'IBAN';


              -- les anciennes valeurs des champs à  tracer

              vt_field_old_values(1) := :OLD.BANK_ACCOUNT_NUM;
              vt_field_old_values(2) := :OLD.END_DATE;
              vt_field_old_values(3) := :OLD.IBAN;

              -- les nouvelles valeurs des champs à  tracer

              vt_field_new_values(1) := :NEW.BANK_ACCOUNT_NUM;
              vt_field_new_values(2) := :NEW.END_DATE;
              vt_field_new_values(3) := :NEW.IBAN;
    
dka_sapfrs_history_pkg.get_user_name( :NEW.last_updated_by, vv_user_name);

  IF vv_user_name = 'EXPLOITATION'  THEN
    RETURN;
    else
    IF INSERTING
         THEN
           SELECT DKA_SAPFRS_MAJ_SITES_S.nextval
         INTO vn_seq_id
         FROM DUAL;

        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                  EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                  :NEW.ext_bank_account_id,
                  :NEW.ext_bank_account_id,
                  :NEW.last_update_date,       -- -- -- valeurs permanentes
                                  :NEW.last_updated_by,
                  'CREATION',
                  'N° de compte bancaire (RIB)',
                  null,
                  vt_field_new_values(1),
                  :NEW.ext_bank_account_id
                 );

        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                  EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                  :NEW.ext_bank_account_id,
                  :NEW.ext_bank_account_id,
                  :NEW.last_update_date,       -- -- -- valeurs permanentes
                                  :NEW.last_updated_by,
                  'CREATION',
                  'Date de fin du compte bancaire',
                  null,
                  vt_field_new_values(2),
                  :NEW.ext_bank_account_id
                 );

        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                   EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                  :NEW.ext_bank_account_id,
                  :NEW.ext_bank_account_id,
                  :NEW.last_update_date,       -- -- -- valeurs permanentes
                  :NEW.last_updated_by,
                  'CREATION',
                  'IBAN',
                  null,
                  vt_field_new_values(3),
                  :NEW.ext_bank_account_id
                 );

             Commit;
             
   END IF;
  
for rec_site_fournisseur  IN  cur_site_fournisseur( :NEW.ext_bank_account_id ) LOOP
  
    IF UPDATING
         THEN 


   SELECT DKA_SAPFRS_MAJ_SITES_S.nextval
         INTO vn_seq_id
         FROM DUAL;
         
        
           
 
            -- dka_sapfrs_history_pkg.INSERT_CUSTOMER_HISTORY('MODIFICATION',              -- Type de l'opération DML
                                             --             :NEW.ext_bank_account_id,              --
                                                  --        :NEW.last_update_date,       -- -- -- valeurs permanentes
                                                  --        :NEW.last_updated_by,        --
                                                  --        vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                   --       vt_field_old_values,         -- Anciennes valeurs -> NULL
                                                   --       vt_field_new_values          -- Nouvelles valeurs
                                                    --     );
                                                    
             IF NVL(vt_field_new_values(1), '$$$') <> NVL(vt_field_old_values(1), '$$$')
                 THEN                                       
               
        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                  EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                  rec_site_fournisseur.vendor_id,
                    rec_site_fournisseur.vendor_site_id,
                   :NEW.last_update_date,       -- -- -- valeurs permanentes
                                  :NEW.last_updated_by,
                  'MODIFICATION',
                  vt_field_names(1),
                  vt_field_old_values(1),
                  vt_field_new_values(1),
                  :NEW.ext_bank_account_id
                 );

 END IF;
            
           IF NVL(vt_field_new_values(2), '$$$') <> NVL(vt_field_old_values(2), '$$$')      
                  THEN 
 
        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                  EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                  rec_site_fournisseur.vendor_id,
                  rec_site_fournisseur.vendor_site_id,
                  :NEW.last_update_date,       -- -- -- valeurs permanentes
                                  :NEW.last_updated_by,
                   'MODIFICATION',
                  vt_field_names(2),
                  vt_field_old_values(2),
                  vt_field_new_values(2),
                  :NEW.ext_bank_account_id
                 );
                 
 
  
     END IF;
            
           IF NVL(vt_field_new_values(3), '$$$') <> NVL(vt_field_old_values(3), '$$$')      
                  THEN 

        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                   EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                  rec_site_fournisseur.vendor_id,
                  rec_site_fournisseur.vendor_site_id,
                  :NEW.last_update_date,       -- -- -- valeurs permanentes
                                  :NEW.last_updated_by,
                 'MODIFICATION',
                  vt_field_names(3),
                  vt_field_old_values(3),
                  vt_field_new_values(3),
                  :NEW.ext_bank_account_id
                 );
END IF;
           
 
 commit;

          ELSIF DELETING
         THEN
             -- dka_sapfrs_history_pkg.INSERT_CUSTOMER_HISTORY('SUPPRESSION',              -- Type de l'opération DML
                                              --            :NEW.ext_bank_account_id,              --
                                               --           :NEW.last_update_date,       -- -- -- valeurs permanentes
                                                --          :NEW.last_updated_by,        --
                                                --          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                 --         vt_field_old_values,         -- Anciennes valeurs -> NULL
                                                  --        vt_field_new_values          -- Nouvelles valeurs
                                                   --      );
                                                   
                     
        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                  EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                 rec_site_fournisseur.vendor_id,
                  rec_site_fournisseur.vendor_site_id,
                  :NEW.last_update_date,       -- -- -- valeurs permanentes
                                  :NEW.last_updated_by,
                  'SUPPRESSION',
                  'N° de compte bancaire (RIB)',
                  null,
                  vt_field_new_values(1),
                  :NEW.ext_bank_account_id
                 );

        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                  EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                  rec_site_fournisseur.vendor_id,
                  rec_site_fournisseur.vendor_site_id,
                  :NEW.last_update_date,       -- -- -- valeurs permanentes
                                  :NEW.last_updated_by,
                  'SUPPRESSION',
                  'Date de fin du compte bancaire',
                  null,
                  vt_field_new_values(2),
                  :NEW.ext_bank_account_id
                 );

        INSERT INTO DKA_SAPFRS_MAJ_SITES
                 (seq_id,
                  vendor_id,
                  vendor_site_id,
                  last_update_date,
                  last_updated_by,
                  action_type,
                  item,
                  old_item_value,
                  new_item_value,
                   EXT_BANK_ACCOUNT_ID
                 )
                 VALUES
                 (vn_seq_id,
                  rec_site_fournisseur.vendor_id,
                  rec_site_fournisseur.vendor_site_id,
                  :NEW.last_update_date,       -- -- -- valeurs permanentes
                                  :NEW.last_updated_by,
                  'SUPPRESSION',
                  'IBAN',
                  null,
                  vt_field_new_values(3),
                  :NEW.ext_bank_account_id
                 );

             Commit;
  END IF;
end loop;

Commit;
END IF;
EXCEPTION
    WHEN OTHERS THEN
      NULL;
END;
/

SHOW ERROR
EXIT;