----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AP_SUPPLIER_SITES_ALL.trg
-- DESCRIPTION       : Trigger sur la table DKA_AP_SUPPLIER_SITES_ALL
---
--- AUTEUR           : Saloua HAHIOUI (SHA)
--- DATE DE CREATION : 21/12/2021
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 29/08/2023 IBA EDB297 Etat de mise à jour du référentiel fournisseur
--------------------------------------------------------------------------------------------


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER DKA_AP_SUPPLIER_SITES_ALL
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TRIGGER APPS.DKA_AP_SUPPLIER_SITES_ALL
  AFTER INSERT OR UPDATE OR DELETE ON AP.AP_SUPPLIER_SITES_ALL
FOR EACH ROW
DECLARE

vt_field_names      dka_sapfrs_history_pkg.dka_typ_fields;
vt_field_old_values dka_sapfrs_history_pkg.dka_typ_fields;
vt_field_new_values dka_sapfrs_history_pkg.dka_typ_fields;
pn_term_name_old       ap_terms.name%type ;
pn_term_name_new       ap_terms.name%type ;
g_user                  NUMBER        := fnd_profile.value('USER_ID');
vv_user_name                 VARCHAR2(50);

PRAGMA AUTONOMOUS_TRANSACTION;

BEGIN     
  
         -- Initialisation du tableau contenant les champs à  tracer
         
         vt_field_names(1)   := 'Nom du site';
         vt_field_names(2)   := 'Adresse (Ligne 1)';
     vt_field_names(3)   := 'Adresse (Ligne 2)';
     vt_field_names(4)   := 'Adresse (Ligne 3)';
     vt_field_names(5)   := 'Adresse (Ligne 4)';
         vt_field_names(6)   := 'Ville';
         vt_field_names(7)   := 'Code postal';
         vt_field_names(8)   := 'Unité opérationnelle';
         vt_field_names(9)   := 'Site d''achat (Oui/Non)';  
     vt_field_names(10)  := 'Site de règlements (Oui/Non)';
         vt_field_names(11)  := 'Conditions de règlements';
         vt_field_names (12) := 'Calcul de la TVA (Oui/Non)';
         vt_field_names (13) := 'Autoriser la Tva Intracommunautaire (Oui/Non)';
         vt_field_names (14) := 'Bloquer le règlement/Toutes les factures (Oui/Non)';
         vt_field_names (15) := 'Bloquer le règlement/Factures non rapprochée (Oui/Non)';
         vt_field_names (16) := 'Bloquer le règlement/Factures non validées (Oui/Non)';
     vt_field_names (17) := 'Statut (Date de désactivation)';
         
         -- Initialisation du tableau contenant les anciennes valeurs des champs à tracer
        dka_sapfrs_history_pkg.get_term_name(:OLD.TERMS_ID , 
                                 pn_term_name_old  );
                    
     vt_field_old_values(1)   := :OLD.vendor_site_code;
         vt_field_old_values(2)   := :OLD.address_line1 ;
     vt_field_old_values(3)   := :OLD.address_line2 ;
     vt_field_old_values(4)   := :OLD.address_line3 ;
     vt_field_old_values(5)   := :OLD.address_line4 ;
         vt_field_old_values(6)   := :OLD.CITY;
         vt_field_old_values(7)   := :OLD.ZIP;
         vt_field_old_values(8)   := :OLD.ORG_ID;
         vt_field_old_values(9)   := :OLD.PURCHASING_SITE_FLAG;        
         vt_field_old_values(10)   := :OLD.PAY_SITE_FLAG;
     vt_field_old_values(11)   := pn_term_name_old;
     vt_field_old_values (12)  := :OLD.AUTO_TAX_CALC_FLAG;
     vt_field_old_values (13) := :OLD.OFFSET_TAX_FLAG;
     vt_field_old_values (14) := :OLD.HOLD_ALL_PAYMENTS_FLAG;  
     vt_field_old_values (15) := :OLD.HOLD_UNMATCHED_INVOICES_FLAG;
     vt_field_old_values (16) := :OLD.HOLD_FUTURE_PAYMENTS_FLAG;
     vt_field_old_values (17) := :OLD.INACTIVE_DATE;
                                      
         -- Initialisation du tableau contenant les nouvelles valeurs des champs à tracer
         dka_sapfrs_history_pkg.get_term_name(:NEW.TERMS_ID , 
                          pn_term_name_new      );
     vt_field_new_values(1)   := :NEW.vendor_site_code;
         vt_field_new_values(2)   := :NEW.address_line1 ;
     vt_field_new_values(3)   := :NEW.address_line2 ; 
     vt_field_new_values(4)   := :NEW.address_line3 ;
     vt_field_new_values(5)   := :NEW.address_line4;
         vt_field_new_values(6)   := :NEW.CITY;
         vt_field_new_values(7)   := :NEW.ZIP;
         vt_field_new_values(8)   := :NEW.ORG_ID;
         vt_field_new_values(9)   := :NEW.PURCHASING_SITE_FLAG;      
         vt_field_new_values(10)   := :NEW.PAY_SITE_FLAG;
     vt_field_new_values(11)   := pn_term_name_new;
     vt_field_new_values (12)  := :NEW.AUTO_TAX_CALC_FLAG;
     vt_field_new_values (13) := :NEW.OFFSET_TAX_FLAG;
     vt_field_new_values (14) := :NEW.HOLD_ALL_PAYMENTS_FLAG;  
     vt_field_new_values (15) := :NEW.HOLD_UNMATCHED_INVOICES_FLAG;
     vt_field_new_values (16) := :NEW.HOLD_FUTURE_PAYMENTS_FLAG;
     vt_field_new_values (17) := :NEW.INACTIVE_DATE;
	 
	dka_sapfrs_history_pkg.get_user_name( :NEW.last_updated_by, vv_user_name);

    IF vv_user_name = 'EXPLOITATION'  THEN
	 
	 RETURN;
    else 
	 
         
         IF INSERTING 
         THEN
             dka_sapfrs_history_pkg.insert_supplier_sites_history('CREATION',                  -- Type de l'opération DML                                               
                                                          :NEW.vendor_id,              --
                                                          :NEW.vendor_site_id,         -- --                                                        
                                                          sysdate,       -- -- -- valeurs permanentes
                                                          g_user,        -- --
                                                          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                          vt_field_old_values,         -- Anciennes valeurs -> NULL 
                                                          vt_field_new_values          -- Nouvelles valeurs                           
                                                         );  
         ELSIF UPDATING
         THEN
             dka_sapfrs_history_pkg.insert_supplier_sites_history('MODIFICATION',              -- Type de l'opération DML                                            
                                                          :NEW.vendor_id,              --
                                                          :NEW.vendor_site_id,         -- --                                                        
                                                          sysdate,       -- -- -- valeurs permanentes
                                                          g_user,        -- 
                                                          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                          vt_field_old_values,         -- Anciennes valeurs -> NULL 
                                                          vt_field_new_values          -- Nouvelles valeurs                                       
                                                         );  
         
     
         --ARA
     IF (TRUNC(:NEW.INACTIVE_DATE) = trunc(sysdate)) THEN
     
      delete from  DKA_SAPFRS_MAJ_SITES bb
        where (item in (
            'Nom du site',
            'Adresse (Ligne 1)',
            'Adresse (Ligne 2)',
            'Adresse (Ligne 3)',
            'Adresse (Ligne 4)',
            'Ville',
            'Code postal',
            'Calcul de la TVA (Oui/Non)',
            'Conditions de règlements',
           -- 'Site de règlements (Oui/Non)',
           -- 'Site d''achat (Oui/Non)',
            'Unité opérationnelle',
            'Adresse mail avis virement',
            'Mode de paiement',
            'Bloquer le règlement/Factures non validées (Oui/Non)',
            'Bloquer le règlement/Factures non rapprochée (Oui/Non)',
            'Bloquer le règlement/Toutes les factures (Oui/Non)',
            'Autoriser la Tva Intracommunautaire (Oui/Non)'         
            )
          and  seq_id IN (
                select seq_id from DKA_SAPFRS_MAJ_SITES aa
                  where seq_id IN
                  (
                    (
                       select distinct seq_id
                       from DKA_SAPFRS_MAJ_SITES bb
                       where aa.vendor_id = bb.vendor_id
                       and aa.vendor_site_id = bb.vendor_site_id
                       and aa.action_type = bb.action_type
                       and NEW_ITEM_VALUE is null
                       and item = 'Adresse (Ligne 1)'
                    ),
                    (
                       select distinct seq_id
                       from DKA_SAPFRS_MAJ_SITES bb
                       where aa.vendor_id = bb.vendor_id
                       and aa.vendor_site_id = bb.vendor_site_id
                       and aa.action_type = bb.action_type
                       and OLD_ITEM_VALUE is null
                       and item = 'Adresse (Ligne 1)'
                    ) 
                  )
            )
           )
         and bb.action_type = 'MODIFICATION'                          
         ; 
     
     delete from  DKA_SAPFRS_MAJ_SITES bb
      where (item in (
              'Nom du site',
              'Adresse (Ligne 1)',
              'Adresse (Ligne 2)',
              'Adresse (Ligne 3)',
              'Adresse (Ligne 4)',
              'Ville',
              'Code postal',
              'Calcul de la TVA (Oui/Non)',
              'Conditions de règlements',
            --  'Site de règlements (Oui/Non)',
             -- 'Site d''achat (Oui/Non)',
              'Unité opérationnelle',
              'Adresse mail avis virement',
              'Mode de paiement',
             -- 'Statut (Date de désactivation)',
              'Bloquer le règlement/Factures non validées (Oui/Non)',
              'Bloquer le règlement/Factures non rapprochée (Oui/Non)',
              'Bloquer le règlement/Toutes les factures (Oui/Non)',
              'Autoriser la Tva Intracommunautaire (Oui/Non)'         
              )
         and  seq_id > (select min(aa.seq_id)
                from DKA_SAPFRS_MAJ_SITES aa
              where aa.vendor_id = bb.vendor_id
                
                and aa.last_updated_by = bb.last_updated_by
                 and aa.action_type = bb.action_type
                and aa.item = bb.item
                and nvl(aa.old_item_value,'a#') = nvl(bb.old_item_value,'a#')
                and nvl(aa.new_item_value,'a#') = nvl(bb.new_item_value,'a#'))
                )
         and bb.action_type = 'MODIFICATION'                          
                     ; 
     
     END IF;
       
     
         delete from  DKA_SAPFRS_MAJ_SITES bb
      where (item in (
              'Nom du site',
              'Adresse (Ligne 1)',
              'Adresse (Ligne 2)',
              'Adresse (Ligne 3)',
              'Adresse (Ligne 4)',
              'Ville',
              'Code postal',
              'Calcul de la TVA (Oui/Non)',
              'Conditions de règlements',
              --'Site de règlements (Oui/Non)',
             -- 'Site d''achat (Oui/Non)',
              'Unité opérationnelle',
              'Adresse mail avis virement',
              'Mode de paiement',
              --'Statut (Date de désactivation)',
              'Bloquer le règlement/Factures non validées (Oui/Non)',
              'Bloquer le règlement/Factures non rapprochée (Oui/Non)',
              'Bloquer le règlement/Toutes les factures (Oui/Non)',
              'Autoriser la Tva Intracommunautaire (Oui/Non)'         
              )
         and  seq_id > (select min(aa.seq_id)
                from DKA_SAPFRS_MAJ_SITES aa
              where aa.vendor_id = bb.vendor_id
                and exists ( select 1 from  ap_supplier_sites_all pvs,  ap_supplier_sites_all pvs_abs
                                              where pvs_abs.location_id=pvs.location_id
                                              and pvs.vendor_site_id = bb.vendor_site_id
                                              and pvs_abs.vendor_site_id =aa.vendor_site_id )
                and aa.last_updated_by = bb.last_updated_by
                 and aa.action_type = bb.action_type
                and aa.item = bb.item
                and nvl(aa.old_item_value,'a#') = nvl(bb.old_item_value,'a#')
                and nvl(aa.new_item_value,'a#') = nvl(bb.new_item_value,'a#')))
         and bb.action_type = 'MODIFICATION'                          
                     ; 
         COMMIT;
                  
                                                         
         ELSIF DELETING
         THEN
              dka_sapfrs_history_pkg.insert_supplier_sites_history('SUPPRESSION',              -- Type de l'opération DML                                            
                                                          :NEW.vendor_id,              --
                                                          :NEW.vendor_site_id,         -- --                                                        
                                                          sysdate,       -- -- -- valeurs permanentes
                                                          g_user,        -- 
                                                          vt_field_names,              -- Chaine contenant la liste des champs tracés
                                                          vt_field_old_values,         -- Anciennes valeurs -> NULL 
                                                          vt_field_new_values          -- Nouvelles valeurs                                       
                                                         );                                   
         END IF;
       
 END IF;    
EXCEPTION
WHEN OTHERS
     THEN app_exception.raise_exception; 
END;

/

SHOW ERROR
EXIT;
