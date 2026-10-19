CREATE OR REPLACE PACKAGE BODY dka_spadeptravint_pkg AS

--------------------------------------------------------------------------------------------
-- NOM           : DKA_SPADEPTRAVINT_PKG.pks
-- DESCRIPTION   : DKA_SPADEPTRAVINT_PKG package spec : spécifique extraction de PA des dépenses
--                                                      travaux internes pour la Garantie Totale
---
--- AUTEUR           : Grégory VANACKERE
--- DATE DE CREATION : 10/03/2006
--- DOC. ASSOCIEE    :
---
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date              Qui                       Description
--- 09/05/2016        ROSHANAK GHARAGOZLOU      Modifications suite à la migration R12   ---
--- 05/12/2016        Pierre BAUDOUR            artf2051629 rectification de clause. Modification des champs amount, nature et IDDATJ_GT
--------------------------------------------------------------------------------------------


--**************************************************************************************
--  FONCTIONS ET PROCEDURES PRIVEES
--**************************************************************************************

--------------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procédure principale
--
--  PARAMETRES :
--    pv_errbuf       Sortie
--    pn_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
--                         ou le code erreur ORA
--------------------------------------------------------------------------------------------
PROCEDURE main (
    pv_errbuf                  IN OUT   VARCHAR2,
    pn_retcode                 IN OUT   NUMBER
)
IS
    e_error_main            EXCEPTION;

    BEGIN

        Dka_Tools_Pkg.put_debug_message ('Début procédure MAIN');

        ----- Initialisation des variables -----
        pv_errbuf           := NULL;
        pn_retcode          := 0;

        Dka_Tools_Pkg.put_debug_message ('TRUNCATE de la table temporaire DKA_IEOPAGTO01_TMP');
        EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_IEOPAGTO01_TMP';

        Dka_Tools_Pkg.put_debug_message ('Insertion des lignes de dépenses PA dans la table temporaire DKA_IEOPAGTO01_TMP');

        INSERT INTO DKA_IEOPAGTO01_TMP
        /*
          SELECT peia.expenditure_item_id, -- expenditure_item_id
                 ppc_etab.class_code, -- imput_def
                 LPAD(ppc_soc.class_code, 5, '0'), -- org_imput_def
                 ppa.segment1, -- imputation_ana
                 to_char(to_date(substr(ppa.attribute8, 1, 10), 'YYYY/MM/DD'), 'YYYYMMDD'), -- end_date 
                 substr(ppa.attribute5, 9, 2), -- chauff_code
                 ppa.attribute6, -- mat_num
                 peia.burden_cost, -- amount
                 DECODE(ppc_type_h.class_code, 'P3 MRE', '532', 'P3 RENOUVELLEMENT', '530', 'P3 DEP.NON IMPUTEE', '531', NULL) -- Nature                      
          FROM pa_tasks pt,
               pa_projects_all ppa,
               pa_expenditure_items_all peia,
               pa_project_classes ppc_etab,
               pa_project_classes ppc_type_h,
               pa_project_classes ppc_soc
          WHERE (peia.attribute5 > (select varchar2_value
                                    from dka_parameters
                                    where program_code = 'IEOPAGTO01'
                                      and parameter_name = 'LAST_EXTRACTION_DATE')
                 OR peia.attribute5 IS NULL)
            AND trunc(fnd_date.canonical_to_date(ppa.attribute8)) <= (select max(end_date)
                                                                   from pa_periods_all
                                                                   where status = 'C'
                                                                     and start_date < SYSDATE)
            AND peia.cost_distributed_flag = 'Y'
            AND peia.task_id = pt.task_id
            AND ppa.project_id = pt.project_id
            AND ppa.project_type = 'TRAVAUX INTERNES'
          
            -- Restriction sur codes H de type 'P3 MRE', 'P3 RENOUVELLEMENT' et 'P3 DEP.NON IMPUTEE'      
            AND ppc_type_h.class_category = 'TYPE_CODE_H'
            AND ppc_type_h.class_code IN ('P3 MRE', 'P3 RENOUVELLEMENT', 'P3 DEP.NON IMPUTEE')
            AND ppc_type_h.project_id = ppa.project_id
          
            -- Récupération code établissement
            AND ppc_etab.class_category = 'CODE_ETABLISSEMENT'
            AND ppc_etab.project_id = ppa.project_id
           
            -- Récupération société
            AND ppc_soc.class_category = 'SOCIETE'
            AND ppc_soc.project_id = ppa.project_id
          
            -- La ligne n'a pas encore été transférée
            AND NOT EXISTS (select 'X'
                            from pa_cost_distribution_lines_all pcdla                                                                   
                            where peia.expenditure_item_id = pcdla.expenditure_item_id
                              and nvl(pcdla.transfer_status_code, 'X') not in ('A', 'V')
                          );
                         
            Dka_Tools_Pkg.put_debug_message ('Nombre de lignes insérées dans DKA_IEOPAGTO01_TMP : ' || SQL%ROWCOUNT);                     
                 
           -- Mise à jour de l'attribute5        
           UPDATE pa_expenditure_items_all peia
           SET peia.attribute5 = to_char(SYSDATE, 'YYYYMMDD')
           WHERE EXISTS (select 'X' from dka_ieopagto01_tmp dit
                         where peia.expenditure_item_id = dit.expenditure_item_id); 
         */ -- RGH 
          SELECT SUBSTR(pt.Task_Number , 1, 10),  -- imputation_ana
                 to_char(to_date(pt.attribute2, 'YYYY/MM/DD HH24:MI:SS'), 'YYYYMMDD'), -- end_date 
                 peia.burden_cost,                                  -- amount artf2051629
                 DECODE(pt.attribute1,'MRE',532,'REN',530,'DNI', 531), -- Nature artf2051629
                 to_char(SYSDATE, 'YYYYMMDD') ,                     -- IDDATJ_GT artf2051629
                 peia.expenditure_item_id
            FROM PA_TASKS                       pt,
                 PA_PROJECTS_ALL                ppa,
                 PA_PROJECTS_ALL                modele_projet,
                 pa_expenditure_items_all       peia,
                 PA_COST_DISTRIBUTION_LINES_ALL pcdla
           WHERE 1 = 1
             AND ppa.project_id              = pt.project_id
             AND ppa.CREATED_FROM_PROJECT_ID = modele_projet.project_id
             AND pt.task_id                  = peia.task_id
             AND peia.expenditure_item_id    = pcdla.expenditure_item_id
             AND ppa.template_flag = 'N'
             --AND modele_projet.template_flag = 'Y'   
             --AND upper(pt.TASK_NAME) = 'TRAVAUX INTERNES P3'             --RG 02 artf2051629
             AND pt.task_number like 'GT%'                                 --RG 02-1
             AND UPPER(modele_projet.segment1) like '%OPERATIONNEL%'       --RG 02-1
             AND SYSDATE > to_date(pt.attribute2, 'YYYY/MM/DD HH24:MI:SS') --RG 02-1
             --AND ppa.project_status_code ='CLOSED'                       --RG 02-1
             AND pt.attribute1 in ('DNI', 'MRE', 'REN')                    --RG 02-1      
             AND pcdla.GL_DATE is not NULL                                 --RG 02-2   
             AND ppa.project_type <> 'Investissement'                      --RG 03   
             AND peia.cost_distributed_flag = 'Y'                          --RG04
            AND (peia.attribute5 > (select varchar2_value
                                       from dka_parameters
                                      where program_code = 'IEOPAGTO'
                                        and parameter_name = 'LAST_EXTRACTION_DATE')
                  OR
                  peia.attribute5 IS NULL
                  ) 
                                                                 --RG04
             AND NOT EXISTS (select 'X'
                               from pa_cost_distribution_lines_all pcdla
                              where peia.expenditure_item_id = pcdla.expenditure_item_id
                                and nvl(pcdla.transfer_status_code, 'X') not in ('A', 'V')
                             )                                          
              ;
               
          Dka_Tools_Pkg.put_debug_message ('Nombre de lignes insérées dans DKA_IEOPAGTO01_TMP : ' || SQL%ROWCOUNT);


         -- Mise à jour de l'attribute5
        UPDATE pa_expenditure_items_all peia
         SET peia.attribute5 = to_char(SYSDATE, 'YYYYMMDD')
         WHERE EXISTS (select 'X' from DKA_IEOPAGTO01_TMP dit
                       where peia.expenditure_item_id = dit.expenditure_item_id);

         Dka_Tools_Pkg.put_debug_message ('Nombre de lignes mises à jour dans DKA_IEOPAGTO01_TMP : ' || SQL%ROWCOUNT);

         COMMIT;


         -- Mise à jour du paramètre Last_Extraction_Date dans la table dka_parameters
         UPDATE dka_parameters
         SET varchar2_value = to_char(SYSDATE, 'YYYYMMDD')
         WHERE program_code = 'IEOPAGTO'
           AND parameter_name = 'LAST_EXTRACTION_DATE';

         IF SQL%ROWCOUNT != 1
         THEN
             pn_retcode := 1;
             pv_errbuf := 'La mise à jour du paramètre LAST_EXTRACTION_DATE dans dka_parameters ne s''est pas faite correctement';
             ROLLBACK;
         END IF;

         Dka_Tools_Pkg.put_debug_message ('Fin de la procédure MAIN');

    EXCEPTION

        WHEN OTHERS
        THEN
            ROLLBACK;
            pn_retcode := 2;
            pv_errbuf := 'Erreur non gérée : ' || SQLERRM;

    END main;
END dka_spadeptravint_pkg;   -- Package body

/

SHOW ERROR

EXIT 