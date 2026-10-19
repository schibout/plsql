CREATE OR REPLACE TRIGGER DKA_RB_LINES_ALL_BRI
---------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_RB_LINES_ALL_BRI.trg
-- DESCRIPTION       : Trigger sur la table DKA_RB_LINES_ALL
---
--- AUTEUR           : Grégory Vanackère (Capgemini)
--- DATE DE CREATION : 12/11/2008
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------------------------
--- 29/06/2009 GV  Ajout de la date d'échéance dans la date de valeur pour les règlements de type "Prélèvement" 
--- 09/07/2013 BCO INC000000408703 - Ajout du fournisseur GDF SUEZ lors du rapprochement automatique.
--- 21/11/2016 RBE Migration R12
----------------------------------------------------------------------------------------------
BEFORE INSERT ON RB_LINES_ALL
FOR EACH ROW

DECLARE
vv_pos_LIB  NUMBER;
vv_pos_car  NUMBER;
vv_ref      VARCHAR2(50);
vd_due_date DATE;

BEGIN
     ---------------------------------------------------------------------
     --                          Partie Bancaire                        --
     ---------------------------------------------------------------------
     -- Il faut ajouter la référence du prélèvement dans la description --
     -- => Pour GDF, le libellé comporte la chaine 'PRLV GAZ DE FRANCE' --
     -- => Pour EDF, le libellé comporte la chaine 'ELECTRICITE DE FRA' --
	 -- => Pour GDF SUEZ, le libellé comporte la chaine 'PRLV GDF SUEZ' --
     ---------------------------------------------------------------------
     IF :NEW.LINE_TYPE = 'B'
     THEN
         -- Recherche des prélèvements GAZ DE FRANCE 
		 -- 09/07/2013 BCO INC000000408703 - Ajout du fournisseur GDF SUEZ lors du rapprochement automatique.
         IF UPPER(:NEW.LONG_DESCRIPTION) LIKE '%PRLV%GAZ%DE%FRANCE%LIB%*%' OR UPPER(:NEW.LONG_DESCRIPTION) LIKE '%PRLV%GDF%SUEZ%LIB%*%'
         THEN
             -- On extrait les caractères qui se situent entre la chaine 'LIB' et '*'
             vv_pos_LIB := INSTR(:NEW.LONG_DESCRIPTION, 'LIB');
             IF vv_pos_LIB <> 0
             THEN
                 vv_pos_car := INSTR(:NEW.LONG_DESCRIPTION, '*', vv_pos_LIB);
                 IF vv_pos_car <> 0
                 THEN
                     vv_ref := SUBSTR(:NEW.LONG_DESCRIPTION, vv_pos_LIB + 3, vv_pos_car - vv_pos_LIB - 3);  
                 END IF;
             END IF;
         
         -- Rechercher des prélèvements ELECTRICITE DE FRANCE    
         ELSIF UPPER(:NEW.LONG_DESCRIPTION) LIKE '%ELECTRICITE%DE%LIB*%'
         THEN
             -- On extrait les 17 caractères situés après la chaines 'LIB*', en plaçant les 5 derniers
             -- précédés d'un blanc en premier
             vv_pos_LIB := INSTR(:NEW.LONG_DESCRIPTION, 'LIB*');
             IF vv_pos_LIB <> 0 
             THEN
                 vv_pos_car := INSTR(:NEW.LONG_DESCRIPTION, ' ', vv_pos_LIB);
                 IF vv_pos_car <> 0
                 THEN
                     vv_ref := SUBSTR(:NEW.LONG_DESCRIPTION, vv_pos_car + 1, 5);
                     vv_ref := vv_ref || SUBSTR(:NEW.LONG_DESCRIPTION, vv_pos_LIB + 4, vv_pos_car - vv_pos_LIB - 4);
                 END IF;
             END IF;
         END IF;
         
         -- On ajoute cette référence dans le champ description ainsi que le champ référence            
         IF vv_ref IS NOT NULL
         THEN
             vv_ref := TRIM(vv_ref);
             :NEW.DESCRIPTION := vv_ref || ' - ' || :NEW.DESCRIPTION;
             IF :NEW.REFERENCE1 IS NULL OR TRIM(:NEW.REFERENCE1) IS NULL
             THEN
                 :NEW.REFERENCE1 := vv_ref;
             END IF;
         END IF;    
              
     ---------------------------------------------------------------
     --                          Partie Comptable                 --
     ---------------------------------------------------------------
     -- Il faut récupérer la description de la facture associé au --
     -- règlement AP                                              -- 
     ---------------------------------------------------------------
     ELSIF :NEW.LINE_TYPE = 'A' 
     THEN
         IF :NEW.APPLICATION_ID = 200  
         THEN
             -- Recherche des prélèvements GAZ DE FRANCE
             IF :NEW.DESCRIPTION LIKE 'Prélèvement%GAZ%DE%FRANCE%' OR :NEW.DESCRIPTION LIKE 'Prélèvement%ELECTRICITE%DE%FRANCE%' OR :NEW.DESCRIPTION LIKE 'Prélèvement%GDF%SUEZ%'
             THEN                
                 BEGIN
                      -- Récupération de la description de la facture associée 
                      SELECT aia.description
                      INTO vv_ref
                      FROM ap_invoices_all aia,
                           ap_invoice_payments_all aipa
                      WHERE aipa.invoice_id = aia.invoice_id
                        AND aipa.check_id = :NEW.CHECK_ID;
                        
                      -- On reporte le libellé dans la description
                      :NEW.DESCRIPTION := vv_ref || ' - ' || :NEW.DESCRIPTION;
                      
                      -- On extrait le point de livraison pour le mettre dans la référence
                      IF :NEW.REFERENCE1 IS NULL OR TRIM(:NEW.REFERENCE1) IS NULL
                      THEN
                          IF vv_ref LIKE '%GAZ%' 
                          THEN
                              vv_pos_car := INSTR(vv_ref, 'GAZ');
                          ELSE
                              vv_pos_car := INSTR(vv_ref, 'ELE');   
                          END IF;    
                          
                          IF vv_pos_car <> 0
                          THEN
                              :NEW.REFERENCE1 := SUBSTR(vv_ref, vv_pos_car + 3, length(vv_ref) - vv_pos_car - 2);
                          END IF;                     
                      END IF;
                      
                 EXCEPTION 
                      WHEN OTHERS THEN NULL;
                 END;          
             END IF;
             
             -- Ajout GV20090629 : on renseigne la date de prélèvement dans la date de valeur
             BEGIN
                  SELECT DISTINCT apsa.due_date --> Si plusieurs factures pour un même prélèvement, alors elles doivent toutes avoir la même date d'échéance
                  INTO vd_due_date
                  FROM ap_payment_schedules_all apsa,
                       ap_checks_all aca,
                       ce_payment_documents cpd, --RBE MigR12
                       ap_invoice_payments_all aipa,
                       rb_bank_transaction_codes_lnk rbtcl
                  WHERE aca.check_id = aipa.check_id
                    AND apsa.invoice_id = aipa.invoice_id
                    AND ACA.PAYMENT_DOCUMENT_ID     = CPD.PAYMENT_DOCUMENT_ID --RBE MigR12
                    --AND aca.check_format_id = rbtcl.check_format_id         --RBE MigR12
                    AND CPD.FORMAT_CODE             = RBTCL.FORMAT_CODE       --RBE MigR12
                    AND rbtcl.bank_transaction_code = '08' --> On ne prend que le type "Prélèvement"
                    AND aca.check_id = :NEW.CHECK_ID;              
                  
                  -- On copie la date d'échéance dans la date de valeur
                  :NEW.BANK_DATE := vd_due_date;
                     
                  EXCEPTION
                  WHEN NO_DATA_FOUND 
                      THEN 
                          -- Il ne s'agit pas d'un prélèvements automatique => on ignore                      
                          NULL;
                  WHEN TOO_MANY_ROWS
                      THEN
                          -- Plusieurs date d'échéance pour le même règlement => on ne prend pas
                          NULL;
                  WHEN OTHERS
                      THEN NULL;              
             END;    
             
/* Code propose par Elsy.
            IF :NEW.PAYMENT_DOCUMENT_ID IS NOT NULL THEN 
              BEGIN 
                SELECT DISTINCT apsa.DUE_DATE --> Si plusieurs factures pour un même prélèvement, alors elles doivent toutes avoir la même date d'échéance 
                  INTO vd_due_date 
                  FROM AP_PAYMENT_SCHEDULES_ALL apsa 
                       ,AP_INVOICE_PAYMENTS_ALL aipa 
                       ,CE_PAYMENT_DOCUMENTS cpd 
                       ,RB_BANK_TRANSACTION_CODES_LNK rbtcl 
                 WHERE apsa.INVOICE_ID             = aipa.INVOICE_ID 
                   AND aipa.CHECK_ID               = :NEW.CHECK_ID 
                   --AND cpd.PAYMENT_DOCUMENT_ID     = :NEW.PAYMENT_DOCUMENT_ID 
                   AND cpd.FORMAT_CODE             = rbtcl.FORMAT_CODE 
                   AND rbtcl.BANK_TRANSACTION_CODE = '08' --> On ne prend que le type "Prélèvement" 
                   ; 
                               
               -- On copie la date d'échéance dans la date de valeur 
               :NEW.BANK_DATE := vd_due_date; 
                                  
              EXCEPTION 
                -- Il ne s'agit pas d'un prélèvement automatique ou 
                -- il y a plusieurs date d'échéance pour le même règlement 
                -- => on ignore 
                WHEN OTHERS THEN 
                    NULL;               
              END;          
            
            ELSIF :NEW.PAYMENT_PROFILE_ID IS NOT NULL 
              BEGIN 
                SELECT DISTINCT apsa.DUE_DATE --> Si plusieurs factures pour un même prélèvement, alors elles doivent toutes avoir la même date d'échéance 
                  INTO vd_due_date 
                  FROM AP_PAYMENT_SCHEDULES_ALL apsa 
                       ,AP_INVOICE_PAYMENTS_ALL aipa 
                       ,IBY_ACCT_PMT_PROFILES_B iappb 
                       ,IBY_SYS_PMT_PROFILES_B isppb 
                       ,RB_BANK_TRANSACTION_CODES_LNK rbtcl 
                 WHERE apsa.INVOICE_ID             = aipa.INVOICE_ID 
                   AND aipa.CHECK_ID               = :NEW.CHECK_ID 
                   --AND iappb.PAYMENT_PROFILE_ID    = :NEW.PAYMENT_PROFILE_ID 
                   AND iappb.SYSTEM_PROFILE_CODE   = isppb.SYSTEM_PROFILE_CODE 
                   AND isppb.PAYMENT_FORMAT_CODE   = rbtcl.FORMAT_CODE 
                   AND rbtcl.BANK_TRANSACTION_CODE = '08' --> On ne prend que le type "Prélèvement" 
                ; 
                               
              -- On copie la date d'échéance dans la date de valeur 
              :NEW.BANK_DATE := vd_due_date; 
                                 
              EXCEPTION 
                WHEN OTHERS THEN 
                  NULL;               
              END; 
              
            END IF; 
*/

         END IF;
     END IF;     
     
     EXCEPTION
     WHEN OTHERS THEN 
        NULL;

END DKA_RB_LINES_ALL_BRI;            
/
SHOW ERRORS
EXIT
             
            


