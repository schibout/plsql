CREATE OR REPLACE TRIGGER DKA_AR_ADJUSTMENTS_ALL_BIR
----------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_AR_ADJUSTMENTS_ALL_BIR.trg
-- DESCRIPTION       : Trigger sur la table AR_ADJUSTMENTS_ALL
---
--- AUTEUR           : Grégory Vanackere (Capgemini)
--- DATE DE CREATION : 01/03/2005
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------------------------
--- 2016/07/26 JJA Migration Helios R12
----------------------------------------------------------------------------------------------
BEFORE INSERT
    ON ar.ar_adjustments_all
    FOR EACH ROW
    
when (NEW.CODE_COMBINATION_ID IS NOT NULL)
DECLARE
       vv_segment3             gl_code_combinations.segment3%TYPE;         
       vn_project_id           pa_projects_all.project_id%TYPE;
       vv_tache                ar_receivables_trx_all.attribute3%TYPE;
BEGIN
     -- Le compte local doit etre un compte de charge ou de produit
     SELECT gcc.segment3
     INTO vv_segment3
     FROM gl_code_combinations gcc
     WHERE gcc.code_combination_id = :NEW.code_combination_id;
     
     IF substr(vv_segment3, 1, 1) IN ('6', '7')
     THEN
         -- Recherche du project_id du segment6 de la CCF
         SELECT ppa.project_id
         INTO vn_project_id
         FROM pa_projects_all ppa,
              gl_code_combinations gcc
         WHERE ppa.segment1 = gcc.segment8
           AND gcc.code_combination_id = :NEW.code_combination_id;
         
         :NEW.ATTRIBUTE11 := vn_project_id;
           
         -- Recherche du type de dépense ou d'événement dans le CUF des réceptions
         IF :NEW.CREATED_FROM <> 'REVERSE_ADJUSTMENT'
         THEN
             SELECT arta.attribute2,arta.attribute3
             INTO :NEW.ATTRIBUTE13,vv_tache
             FROM ar_receivables_trx_all arta
             WHERE arta.receivables_trx_id = :NEW.receivables_trx_id;
             
             --Alimentation avec la tâche
             SELECT task_id
             INTO :NEW.ATTRIBUTE14
             FROM pa_tasks pt
             where project_id = vn_project_id
              AND pt.task_number = vv_tache;
             
         ELSE
             SELECT aaa.receivables_trx_id, -- Ajout TB 07/07/2006
                    aaa.attribute13
             INTO :NEW.ATTRIBUTE12, -- Ajout TB 07/07/2006
                  :NEW.ATTRIBUTE13
             FROM ar_adjustments_all aaa
             WHERE aaa.adjustment_id = 
                   (SELECT max(adjustment_id)
                    FROM ar_adjustments_all
                    WHERE customer_trx_id = :NEW.CUSTOMER_TRX_ID
                      AND associated_cash_receipt_id = :NEW.ASSOCIATED_CASH_RECEIPT_ID
                      AND code_combination_id = :NEW.CODE_COMBINATION_ID);
                      
             :NEW.ATTRIBUTE5 := null; -- Ajout TB 26/06/2006
                                        
         END IF;
     END IF;    
     
EXCEPTION
    WHEN OTHERS THEN
        app_exception.raise_exception;
END DKA_AR_ADJUSTMENTS_ALL_BIR;
/
SHOW ERROR
EXIT
