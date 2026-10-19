----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_IBY_PMT_INSTR_USES_ALL.trg
-- DESCRIPTION       : Trigger sur la table IBY_PMT_INSTR_USES_ALL
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
PROMPT CREATION DU TRIGGER DKA_IBY_PMT_INSTR_USES_ALL
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER APPS.DKA_IBY_PMT_INSTR_USES_ALL
    before INSERT OR UPDATE OR DELETE
    ON IBY_PMT_INSTR_USES_ALL
    FOR EACH ROW


DECLARE

  vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
  vn_seq_id                    NUMBER(15);
  pn_vendor_id       NUMBER ;
  pn_vendor_site_id   NUMBER;
   vv_user_name                 VARCHAR2(50);
PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN
        dka_sapfrs_history_pkg.get_vendor_site_id (:NEW.ext_pmt_party_id,
						                           pn_vendor_site_id      );

		dka_sapfrs_history_pkg.get_vendor_id (pn_vendor_site_id,
						                      pn_vendor_id      );


              vt_field_names(1) := 'Date de fin d''affectation du compte bancaire';
              vt_field_names(2) := 'Priorité d''affectation du compte bancaire';


              -- les anciennes valeurs des champs à  tracer

              vt_field_old_values(1) := :OLD.END_DATE;
              vt_field_old_values(2) := :OLD.ORDER_OF_PREFERENCE;


              -- les nouvelles valeurs des champs à  tracer

              vt_field_new_values(1) := :NEW.END_DATE;
              vt_field_new_values(2) := :NEW.ORDER_OF_PREFERENCE;

 dka_sapfrs_history_pkg.get_user_name( :NEW.last_updated_by, vv_user_name);

  IF vv_user_name = 'EXPLOITATION'  THEN
    RETURN;
    else 
        if  pn_vendor_id is not null then

   SELECT DKA_SAPFRS_MAJ_SITES_S.nextval
         INTO vn_seq_id
         FROM DUAL;

			  IF INSERTING
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
                  ext_bank_account_id
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
                  pn_vendor_site_id,
                  :NEW.last_update_date,
                  :NEW.last_updated_by,
                  'CREATION',
                  vt_field_names(1),
                  vt_field_old_values(1),
                  vt_field_new_values(1),
                  :NEW.instrument_id

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
                  ext_bank_account_id
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
                  pn_vendor_site_id,
                  :NEW.last_update_date,
                  :NEW.last_updated_by,
                  'CREATION',
                  vt_field_names(2),
                  vt_field_old_values(2),
                  vt_field_new_values(2),
                  :NEW.instrument_id

                 );


                 commit;



			 ELSIF UPDATING
			 THEN

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
                  ext_bank_account_id
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
                  pn_vendor_site_id,
                  :NEW.last_update_date,
                  :NEW.last_updated_by,
                  'MODIFICATION',
                  vt_field_names(1),
                  vt_field_old_values(1),
                  vt_field_new_values(1),
                  :NEW.instrument_id

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
                  ext_bank_account_id
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
                  pn_vendor_site_id,
                  :NEW.last_update_date,
                  :NEW.last_updated_by,
                  'MODIFICATION',
                  vt_field_names(2),
                  vt_field_old_values(2),
                  vt_field_new_values(2),
                  :NEW.instrument_id

                 );

                  END IF;
                  commit;

			ELSIF DELETING
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
                  ext_bank_account_id
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
                  pn_vendor_site_id,
                  :NEW.last_update_date,
                  :NEW.last_updated_by,
                  'SUPPRESSION',
                  vt_field_names(1),
                  vt_field_old_values(1),
                  vt_field_new_values(1),
                  :NEW.instrument_id

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
                  ext_bank_account_id
                 )
                 VALUES
                 (vn_seq_id,
                  pn_vendor_id,
                  pn_vendor_site_id,
                  :NEW.last_update_date,
                  :NEW.last_updated_by,
                  'SUPPRESSION',
                  vt_field_names(2),
                  vt_field_old_values(2),
                  vt_field_new_values(2),
                  :NEW.instrument_id

                 );
			 END IF;

        end if;

commit;

end if;
EXCEPTION
    WHEN OTHERS THEN
      NULL;
END;


/

SHOW ERROR
EXIT;
