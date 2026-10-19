----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_IBY_EXTERNAL_PAYEES_ALL.trg
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
PROMPT CREATION DU TRIGGER DKA_IBY_EXTERNAL_PAYEES_ALL
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER APPS.DKA_IBY_EXTERNAL_PAYEES_ALL
    AFTER INSERT OR UPDATE OR DELETE
    ON IBY_EXTERNAL_PAYEES_ALL
    FOR EACH ROW

DECLARE

  vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
  vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
  vv_user_name                 VARCHAR2(50);
  pn_vendor_id       NUMBER ;

BEGIN


	          dka_sapfrs_history_pkg.get_vendor_id (:NEW.SUPPLIER_SITE_ID,
						                            pn_vendor_id      );

              vt_field_names(1) := 'Mode de paiement';
              vt_field_names(2) := 'Adresse mail avis virement';


              -- les anciennes valeurs des champs à  tracer

              vt_field_old_values(1) := :OLD.DEFAULT_PAYMENT_METHOD_CODE;
              vt_field_old_values(2) := :OLD.REMIT_ADVICE_EMAIL;


              -- les nouvelles valeurs des champs à  tracer

              vt_field_new_values(1) := :NEW.DEFAULT_PAYMENT_METHOD_CODE;
              vt_field_new_values(2) := :NEW.REMIT_ADVICE_EMAIL;
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
