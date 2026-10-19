CREATE OR REPLACE PACKAGE BODY Dka_Sarfacman_Pkg
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SARFACMAN_PKG.pkb
-- DESCRIPTION       : DKA_SARFACMAN_PKG package body :
---
--- AUTEUR           : Julien PELAT (CGEY)
--- DATE DE CREATION : 16/08/2016
--- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 10/10/2016 JPE MIGRATION R12
--- 17/11/2016 MEG artf2046309
--- 29/12/2016 OBE Modification - artf2070476
--- 30/12/2016 NBO artf2070058 - SPE027 : Calcul de la clef comptable dans le cas de refacturation de charge ne fonctionne pas 
--- 03/01/2017 OBE Modification - artf2070476 - Modification de l'option de profil ORG_ID par MO : Profil sécurité 
--- 26/01/2017 MEG artf2086811 : SPE027 : message d'erreur de valeur d'attribut dans un cas de refac
--- 27/01/2017 MEG artf2087101 : SPE027 - ajout message utilisateur interdisant la refacturation sur les comptes de charges
--- 09/02/2017 OBE Modification - artf2096903
--- 22/12/2017 OBE artf2297904 : SPE027 - Interface des factures manuelles sur projets - Project status code
--- 03/01/2018 JJA artf2297904 : Correction libellé
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- Variables Globales
    gv_type_manuel_facture          dka_parameters.varchar2_value%TYPE;
    gv_type_manuel_annul_fac        dka_parameters.varchar2_value%TYPE;
    gv_type_manuel_avoir            dka_parameters.varchar2_value%TYPE;
    gv_type_manuel_annul_avo        dka_parameters.varchar2_value%TYPE;
    gv_type_passage_irrecouvrable   dka_parameters.varchar2_value%TYPE;
    gv_cr_seg4                		  fnd_flex_values.flex_value%TYPE; 
    gv_cr_seg3                		  fnd_flex_values.flex_value%TYPE;
    gv_event_context_normal         pa_events.attribute_category%TYPE;
    gv_event_context_refac          pa_events.attribute_category%TYPE;
    gv_project_type_refac           pa_project_types.project_type%TYPE;
    gv_project_type_appart          pa_project_types.project_type%TYPE;
    gv_ar_function_code             pa_function_transactions.function_code%TYPE;
    gv_ar_function_transaction      pa_function_transactions.function_transaction_code%TYPE;
    gv_line_type                    pa_cost_distribution_lines_all.line_type%TYPE    := 'R';
    gv_currency_code                VARCHAR2 (3);
    gv_expend_group_status_code     VARCHAR2 (50);
    gv_system_linkage_function      VARCHAR2 (30);
    gv_transaction_source           VARCHAR2 (30);
    gv_expenditure_status_code      VARCHAR2 (30);
    gv_expenditure_class_code       VARCHAR2 (30);
    gv_default_task_number          pa_tasks.task_number%TYPE                        := '1';
    gn_current_org_id               hr_all_organization_units.organization_id%TYPE;
    gn_set_of_books_id              gl_sets_of_books.set_of_books_id%TYPE;
    gn_user_id                      NUMBER;
    gn_request_id                   NUMBER;
    gn_last_update_login            NUMBER;  
    gn_program_application_id       NUMBER;
    gn_program_id                   NUMBER;      
    e_error                         EXCEPTION;
    gn_retcode                      NUMBER;
    gv_errbuf                       VARCHAR2 (500);
    gv_org_id                       NUMBER;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

----------------------------------------------------------------------------------------------------------------------
  --  Nom           : get_select_record_group
  --  Description   : Requete pour les listes de valeurs
  --
  --  PARAMETRES    :
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       : Ordre Select
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    FUNCTION get_select_record_group (
        pv_record_group    IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_select   VARCHAR2 (5000);
    BEGIN
    	--Restriction code tva sur l'entUte
        IF pv_record_group = 'ARXTWTGW_TRANSACTION_TYPE'
        THEN
            vv_select    := REPLACE (
                                cg_select_ctt_type_name,
                                'order by',
                                   'and NVL (ctt.attribute1, ''N'') = ''Y'' '
                                || 'order by'
                            );
        ELSE
            vv_select    := NULL;
        END IF;

        RETURN vv_select;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_select_record_group;

-----------------------------------------------------------------------------------------------------------------------
  --  Nom           : init
  --  Description   : Initialisation
  --
  --  PARAMETRES    :
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       : Initialisation
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        rec_param   dka_parameters%ROWTYPE;
    BEGIN
        pv_errbuf                  := NULL;
        pn_retcode                 := 0;
        Dka_Tools_Pkg.put_debug_message ('Lancement des initialisations');
        gv_org_id    := FND_PROFILE.VALUE ('XLA_MO_SECURITY_PROFILE_LEVEL'); --FND_PROFILE.VALUE('ORG_ID'); -- OBE
        --Géneration de l'entUte du fichier de sortie --
        Dka_Tools_Pkg.put_out_header;
        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'MANUEL_FACTURE', rec_param, pn_retcode, pv_errbuf);
        gv_type_manuel_facture                   := substr (rec_param.varchar2_value,5);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'MANUEL_FACTURE - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'MANUEL_ANNUL_FAC', rec_param, pn_retcode, pv_errbuf);
        gv_type_manuel_annul_fac                   := substr (rec_param.varchar2_value,5);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'MANUEL_ANNUL_FAC - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'MANUEL_AVOIR', rec_param, pn_retcode, pv_errbuf);
        gv_type_manuel_avoir                   := substr (rec_param.varchar2_value,5);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'MANUEL_AVOIR - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'MANUEL_ANNUL_AVO', rec_param, pn_retcode, pv_errbuf);
        gv_type_manuel_annul_avo                   := substr (rec_param.varchar2_value,5);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'MANUEL_ANNUL_AVO - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'PASSAGE_IRRECOUVRABL', rec_param, pn_retcode, pv_errbuf);
        gv_type_passage_irrecouvrable                   := substr (rec_param.varchar2_value,6);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PASSAGE_IRRECOUVRABL - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'EVENT_CONTEXT_NORMAL', rec_param, pn_retcode, pv_errbuf);
        gv_event_context_normal    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_CONTEXT_NORMAL - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'EVENT_CONTEXT_REFAC', rec_param, pn_retcode, pv_errbuf);
        gv_event_context_refac     := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_CONTEXT_REFAC - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'CR_SEGMENT4', rec_param, pn_retcode, pv_errbuf);  -- PHENIX 2004: 'CR_SEGMENT2' -> 'CR_SEGMENT4'
        gv_cr_seg4     := rec_param.varchar2_value;  -- PHENIX 2004: gv_cr_seg2 -> gv_cr_seg4.

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'CR_SEGMENT4 - ' || pv_errbuf;  -- PHENIX 2004: 'CR_SEGMENT2' -> 'CR_SEGMENT4'
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'CR_SEGMENT3', rec_param, pn_retcode, pv_errbuf);
        gv_cr_seg3     := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'CR_SEGMENT3 - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'PROJECT_TYPE_REFAC', rec_param, pn_retcode, pv_errbuf);
        gv_project_type_refac     := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PROJECT_TYPE_REFAC - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'PROJECT_TYPE_APPART', rec_param, pn_retcode, pv_errbuf);
        gv_project_type_appart    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PROJECT_TYPE_APPART - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'AR_FUNCTION_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_ar_function_code             := rec_param.varchar2_value;
        IF pn_retcode != 0
        THEN
                pv_errbuf    := 'AR_FUNCTION_CODE - ' || pv_errbuf;
                RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'AR_FUNCTION_TRANSACTION_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_ar_function_transaction      := rec_param.varchar2_value;
        IF pn_retcode != 0
        THEN
                pv_errbuf    := 'AR_FUNCTION_TRANSACTION_CODE - ' || pv_errbuf;
                RETURN;
        END IF;

        /*Ajout TB 16/05/2006*/
        
        -- On recherche le set of books id
        IF gn_set_of_books_id IS NULL
        THEN
            gn_set_of_books_id := TO_NUMBER (Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID'));
        END IF;
          
        IF gn_user_id IS NULL
        THEN
            gn_user_id    := Fnd_Global.user_id;
        END IF;
        
        IF gn_request_id IS NULL
        THEN
            gn_request_id    := Fnd_Global.conc_request_id;
        END IF;
        
        IF gn_last_update_login IS NULL
        THEN
            gn_last_update_login    := Fnd_Global.conc_login_id;
        END IF;

        IF gn_program_application_id IS NULL
        THEN
            gn_program_application_id    := Fnd_Global.prog_appl_id;
        END IF;

        IF gn_program_id IS NULL
        THEN
            gn_program_id    := Fnd_Global.conc_program_id;
        END IF;
        
        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'TRANSACTION_SOURCE', rec_param, pn_retcode, pv_errbuf);
        gv_transaction_source      := rec_param.varchar2_value;
        
        IF pn_retcode != 0
        THEN
          pv_errbuf    := 'TRANSACTION_SOURCE - ' || pv_errbuf;
          RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'SYSTEM_LINKAGE_FUNCTION', rec_param, pn_retcode, pv_errbuf);
        gv_system_linkage_function := rec_param.varchar2_value;
        IF pn_retcode != 0
        THEN
          pv_errbuf    := 'SYSTEM_LINKAGE_FUNCTION - ' || pv_errbuf;
          RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'EXPENDITURE_GROUP_STATUS_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_expend_group_status_code := rec_param.varchar2_value;
        IF pn_retcode != 0
        THEN
          pv_errbuf    := 'EXPENDITURE_GROUP_STATUS_CODE - ' || pv_errbuf;
          RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'EXPENDITURE_STATUS_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_expenditure_status_code := rec_param.varchar2_value;
        IF pn_retcode != 0
        THEN
          pv_errbuf    := 'EXPENDITURE_STATUS_CODE - ' || pv_errbuf;
          RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('SARFACMAN', 'EXPENDITURE_CLASS_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_expenditure_class_code := rec_param.varchar2_value;
        IF pn_retcode != 0
        THEN
          pv_errbuf    := 'EXPENDITURE_CLASS_CODE - ' || pv_errbuf;
          RETURN;
        END IF;

        /*Fin ajout TB*/
        
        Dka_Tools_Pkg.put_debug_message ('Fin de l''initialisation des parametres ');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END init;


-----------------------------------------------------------------------------------------------------------------------
  --  Nom           :get_acct_combination
  --  Description   :Procedure qui vérifiée le rejet des évenements
  --
  --  PARAMETRES    :
  --    pn_project_id
  --    pd_date
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_acct_combination (
        pv_custom_event_name            IN      VARCHAR2,      
        pv_concatened_segments_in       IN      VARCHAR2,
        pn_ccid_in                      IN      NUMBER,
        pn_org_id                       IN      NUMBER, --RBE
        pn_project_id                   IN OUT  NUMBER,
        pn_tache_id	                    IN OUT  NUMBER,
        pv_event_type                   IN      VARCHAR2,
        pd_gl_date                      IN      DATE,
        pv_trx_type                     IN      VARCHAR2,
        pv_account_class                IN      VARCHAR2,
        pn_customer_id                  IN      VARCHAR2,
        pn_cust_site_use_id             IN      VARCHAR2,
        pb_update_user_flexfield        OUT     BOOLEAN,
        pb_refac                        OUT     BOOLEAN,
        pn_refac_project_id             IN OUT  NUMBER,
        pn_refac_tache_id               IN OUT  NUMBER,
        pv_cuf                          IN OUT  VARCHAR2,
        pv_concatened_segments_out      OUT     VARCHAR2,
        pn_ccid_out                     OUT     NUMBER,
        Pv_Message                      OUT     VARCHAR2,
        pv_errbuf                       OUT     VARCHAR2,
        pn_retcode                      OUT     NUMBER
    )
    IS
        e_error                  EXCEPTION;
        e_acct_error             EXCEPTION;
        e_seg4_error             EXCEPTION;
        vv_step                  VARCHAR2 (200);
        vv_segment1_2            gl_code_combinations.segment1%TYPE;  -- PHENIX 2004: Ajout.
        vv_segment1              gl_code_combinations.segment1%TYPE;
        vv_segment2              gl_code_combinations.segment2%TYPE;
        vv_segment3              gl_code_combinations.segment3%TYPE;
        vv_segment4              gl_code_combinations.segment4%TYPE;
        vv_segment5              gl_code_combinations.segment5%TYPE;
        vv_segment6              gl_code_combinations.segment6%TYPE;  
        vv_segment7              gl_code_combinations.segment7%TYPE;
        vv_segment8              gl_code_combinations.segment8%TYPE;
        vv_segment9              gl_code_combinations.segment9%TYPE;  -- PHENIX 2004: Ajout.
        vv_segment10             gl_code_combinations.segment10%TYPE;  -- PHENIX 2004: Ajout.
        vv_segment11             gl_code_combinations.segment11%TYPE;  -- PHENIX 2004: Ajout.
        vv_segment12             gl_code_combinations.segment12%TYPE;  -- PHENIX 2004: Ajout.
        vv_user_org_name         VARCHAR2(128);                       -- PHENIX 2004: Ajout.
        vv_project_type          pa_project_types.project_type%TYPE;
        vv_project_org_name      pa_project_classes.class_code%TYPE;  -- PHENIX 2004: Avant: vn_project_org_id        hr_organization_units.organization_id%TYPE;
        vv_refac_project_org_name      pa_project_classes.class_code%TYPE;  -- PHENIX 2004: Ajout.
        vn_acct_project_id       pa_projects_all.project_id%TYPE;
        vn_zrefac_project_id     pa_projects_all.project_id%TYPE;
        vv_zrefac_project_number pa_projects_all.segment1%TYPE;
        vv_zrefac_project_name   pa_projects_all.name%TYPE;
        vn_segment_rule_id       pa_rules.rule_id%TYPE;
        vv_compte_local          VARCHAR2(1); -- Modif TB 16/05/2006
	     	vn_org_id          		   NUMBER;
        vv_soc_proj              gl_code_combinations.segment1%TYPE;   
        vn_expend_item_id        pa_expenditure_items_all.expenditure_item_id%TYPE;   
        vv_task_template         VARCHAR2(5); -- MIGRATION R12
    BEGIN
        pv_errbuf         := NULL;
        pn_retcode        := 0;
        pb_refac          := FALSE;
        vn_expend_item_id := NULL;   
          
        IF pn_project_id IS NOT NULL
        THEN
            -- Migration R12
            Dka_Sarfacman_Pkg.get_data_for_refaccuf(pn_project_id,
                                                    pn_tache_id,
                                                    pv_event_type, 
                                                    pn_org_id, --RBE         
                                                    pb_refac,
                                                    pn_refac_project_id,
                                                    pn_refac_tache_id,
                                                    pv_concatened_segments_in,
                                                    pv_trx_type,
                                                    pv_account_class,
                                                    pv_cuf,
                                                    vn_org_id, 
                                                    Pv_Message,
                                                    pv_errbuf,
                                                    pn_retcode);
            IF pn_retcode != 0
            THEN
                Pv_Message   := pv_errbuf;
                -- debug jpe
                --Pv_Message := 'DEBUG JPE Proj :' || pn_project_id || ' - refacproj:' || pn_refac_project_id || ' - tache:' || pn_tache_id || ' - refactache:' || pn_refac_tache_id;
                --pv_errbuf   := Pv_Message;
                RAISE e_error;
            END IF;                                         
            
            -- Ajout TB 16/05/2006 : récupération du premier chiffre du segment3
            SELECT SUBSTR(SUBSTR (pv_concatened_segments_in, INSTR (pv_concatened_segments_in, '.', 1, 2) + 1,
                                  (INSTR (pv_concatened_segments_in, '.', 1, 3) - INSTR (pv_concatened_segments_in, '.', 1, 2) - 1)),1,1)
            INTO vv_compte_local
            FROM dual;

            --
            -- Calcul de la nouvelle combinaison
            --
            vv_step := '08 - ';
            vn_acct_project_id := pn_project_id;
            
            -- artf2031575 : Afficher un message lorsqu'il y a refacturation 
            IF pb_refac THEN
              Pv_Message := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_I0002');
            END IF;

            -- Contrôles de cohérence des données
            Dka_Pa_Tools_Pkg.pa_check_transaction_data (
                pv_errbuf                      => pv_errbuf,
                pn_retcode                     => pn_retcode,
                pn_project_id                  => pn_project_id,
				        pn_tache_id					           => pn_tache_id,
                pv_expenditure_type            => pv_event_type,
                pb_no_test_type_evt            => TRUE,
                pv_event_type                  => NULL,
                pd_date                        => pd_gl_date               
            );
                                 
            IF pn_retcode != 0
            THEN
                Pv_Message   := pv_errbuf;
                RAISE e_error;
            END IF;


            -- Segment1 et 2
            vv_step := '09 - ';
            -- MIGRATION R12
            IF pv_account_class = 'REV' THEN              
              vv_segment1 := DKA_SPAAUTOACCOUNTING_PKG.societe_projet(vn_acct_project_id);
              vv_segment2 := DKA_SPAAUTOACCOUNTING_PKG.uo_projet(vn_acct_project_id);
            ELSE 
                vv_segment1_2 := SUBSTR (pv_concatened_segments_in, 1, INSTR (pv_concatened_segments_in, '.', 1, 1) - 1);  -- PHENIX 2004: vv_segment1 -> vv_segment1_2
                vv_segment1 := SUBSTR(vv_segment1_2, Dka_Tools_Pkg.segment_size(1), Dka_Tools_Pkg.segment_size(1));
                vv_segment2 := SUBSTR(vv_segment1_2, 1, Dka_Tools_Pkg.segment_size(2));
            END IF;
            
            -- Segment3
            -- On ne le recacule que si le type de mouvement n'est pas 'PASSAGE_IRRECOUVRABLE'
            vv_step := '10 - ';   -- PHENIX 2004: '10 - ' -> '11 - ' 0
            IF pv_account_class = 'REV'
               AND substr (pv_trx_type,6) != gv_type_passage_irrecouvrable  -- Modif TB 16/05/2006
            THEN         
                -- Ajout TB 16/05/2006
                -- Calcul du segment3 en fonction du compte local
                IF vv_compte_local = '6' THEN  
                  -- MIGRATION R12
                  vv_segment3 := DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts(pn_project_id  => vn_acct_project_id,
                                                         pv_expenditure_type => pv_event_type,
                                                         pn_task_id          => pn_tache_id);
                ELSE
                  SELECT psrp.rule_id
                  INTO vn_segment_rule_id
                  FROM pa_segment_rule_pairings psrp
                  WHERE psrp.application_id = 275
                    AND psrp.function_code = gv_ar_function_code
                    AND psrp.function_transaction_code = gv_ar_function_transaction
                    AND psrp.segment_num = 2 ; -- Numerotation a partir de 0
                  Dka_Pa_Tools_Pkg.pa_run_accounting_rule(pn_rule_id          => vn_segment_rule_id,
                                                          pv_event_type       => pv_event_type,
                                                          pn_project_id       => vn_acct_project_id,
                                                          pv_segment_value    => vv_segment3,
                                                          pv_errbuf           => pv_errbuf,
                                                          pn_retcode          => pn_retcode );
                END IF;
            ELSE
                vv_segment3 := SUBSTR (pv_concatened_segments_in, INSTR (pv_concatened_segments_in, '.', 1, 2) + 1, (INSTR (pv_concatened_segments_in, '.', 1, 3) - INSTR (pv_concatened_segments_in, '.', 1, 2) - 1));
            END IF;

            IF vv_segment3 IS NULL
            THEN
                pn_retcode := 2;
                pv_errbuf := 'Erreur sur récupération Segment 3 : ' || pv_errbuf;
                pv_errbuf :=  substr(pv_errbuf || ' vn_acct_project_id:' ||  vn_acct_project_id || ' pv_event_type:' || pv_event_type || ' pn_tache_id:' || pn_tache_id,250);
                RAISE e_acct_error;
            END IF;

            -- On ne le recalcule que si le type de mouvement n'est pas 'PASSAGE_IRRECOUVRABLE'
            vv_step := '11 - ' || pv_account_class || ' / ' || pv_trx_type;
            IF pv_account_class = 'REV'
               AND substr (pv_trx_type,6) != gv_type_passage_irrecouvrable -- Modif TB 16/05/2006
            THEN
            -- Calcul du segment4 en fonction du compte local
               IF vv_compte_local = '6' THEN
                  
        		 -- artf2070058 - SPE027 : Calcul de la clef comptable dans le cas de refacturation de charge ne fonctionne pas 
		         vv_segment4 := DKA_SPAAUTOACCOUNTING_PKG.run_cpt_groupe_couts_f(pn_project_id       => vn_acct_project_id,
                                                                                pv_expenditure_type => pv_event_type,
                                                                                pn_task_id          => pn_tache_id,
																				pn_refac_project_id       => pn_refac_project_id
                                                                                );
                  
                ELSE
                  vv_segment4 := Dka_Spaautoaccounting_Pkg.run_cpt_groupe_produit_f ( pn_project_id => vn_acct_project_id,  -- PHENIX 2004: vv_segment2 -> vv_segment4.
                                                                                      pv_event_type => pv_event_type,
                                                                                      pn_task_id    => pn_tache_id );
                END IF; 
            ELSE
                vv_segment4 := SUBSTR (pv_concatened_segments_in, INSTR (pv_concatened_segments_in, '.', 1, 3) + 1, (INSTR (pv_concatened_segments_in, '.', 1, 4) - INSTR (pv_concatened_segments_in, '.', 1, 3) - 1)); -- Correction TB 16/05/2006  PHENIX 2004: vv_segment2 -> vv_segment4.
            END IF;

            IF vv_segment4 IS NULL -- PHENIX 2004: vv_segment2 -> vv_segment4.
            THEN
                    pn_retcode := 2;
                    pv_errbuf := ' Erreur sur récupération Segment 4 : ';
                    vv_task_template := dka_spaautoaccounting_pkg.get_task_template_f(pn_tache_id);
                    IF  (vv_task_template ='GT' OR vv_task_template='GD') AND vv_compte_local != '6' THEN
                      pv_errbuf :=  pv_errbuf || 'Pas de produit sur les tâches de type TRAVAUX INTERNES (GT) et ENTREPOT, MAGASIN, STOCK (GD)';
                      RAISE e_seg4_error;
                    ELSE
                      pv_errbuf :=  pv_errbuf || ' vn_acct_project_id:' ||  vn_acct_project_id || ' pv_event_type:' || pv_event_type || ' pn_tache_id:' || pn_tache_id || ' pn_refac_project_id : ' || pn_refac_project_id ;
                      RAISE e_acct_error;
                    END IF;
            END IF;

            -- Segment5  -- PHENIX 2004: Segment4 -> Segment5.
            -- On ne le recacule que s'il ne s'agit pas d'un cas de Surtaxe Communale
            -- par contre, on le calcule pour toutes les lignes REC et REV
            vv_step := '12 - ';
            /*
            IF     pv_account_class IN ('REV', 'REC')
               AND NOT (    vv_segment4 = '25080'  -- PHENIX 2004: vv_segment2 -> vv_segment4.
                        AND vv_segment3 IN ('467300', '467296')
                       )
            THEN
                -- JPE MIGRATION R12
                IF vv_compte_local = '6' THEN
                  IF vn_expend_item_id IS NULL THEN                    
                    SELECT peia.expenditure_item_id
                  	INTO   vn_expend_item_id
                  	FROM   pa_expenditure_items_all peia
                    WHERE  peia.expenditure_type = pv_event_type; 
                  END IF;
                  vv_segment5 := dka_spaautoaccounting_pkg.code_interco( pn_expenditure_item_id => vn_expend_item_id,
                                                                         pn_project_id => vn_acct_project_id,
                                                                         pn_id_site_fourn => NULL); 
                ELSE
                  vv_segment5 := get_code_partenaire (pn_customer_id); -- PHENIX 2004: vv_segment4 -> vv_segment5.
                END IF;                                                          
            ELSE
                vv_segment5 := SUBSTR (pv_concatened_segments_in, INSTR (pv_concatened_segments_in, '.', 1, 4) + 1, (INSTR (pv_concatened_segments_in, '.', 1, 5) - INSTR (pv_concatened_segments_in, '.', 1, 4) - 1)); -- Correction TB 16/05/2006 PHENIX 2004: vv_segment4 -> vv_segment5.
            END IF;
            */
            
            --artf2046309
            IF pv_account_class IN ('REV', 'REC') THEN
              vv_segment5 := get_code_partenaire(pn_customer_id, pn_cust_site_use_id);
            ELSE
              vv_segment5 := SUBSTR(pv_concatened_segments_in,
                                    INSTR(pv_concatened_segments_in, '.', 1, 4) + 1,
                                    (INSTR(pv_concatened_segments_in, '.', 1, 5) -
                                    INSTR(pv_concatened_segments_in, '.', 1, 4) - 1));
            END IF;

             IF vv_segment5 IS NULL -- PHENIX 2004: vv_segment2 -> vv_segment4.
            THEN
                pn_retcode := 2;
                pv_errbuf := 'Erreur sur récupération Segment 5';
                pv_errbuf :=  pv_errbuf || ' vn_acct_project_id:' ||  vn_acct_project_id || ' pv_event_type:' || pv_event_type || ' pn_customer_id:' || pn_customer_id;
                RAISE e_acct_error;
            END IF;
            
            vv_step := '13 - ';
            IF pv_account_class = 'REV'
            THEN
                vv_segment6 := dka_spaautoaccounting_pkg.centrefi(pn_project_id => vn_acct_project_id); 
            ELSE
                vv_segment6 := SUBSTR (pv_concatened_segments_in, INSTR (pv_concatened_segments_in, '.', 1, 5) + 1, (INSTR (pv_concatened_segments_in, '.', 1, 6) - INSTR (pv_concatened_segments_in, '.', 1, 5) - 1)); -- Correction TB 16/05/2006 PHENIX 2004: vv_segment5 -> vv_segment6.
            END IF; 

            IF vv_segment6 IS NULL -- PHENIX 2004: vv_segment5 -> vv_segment6.
            THEN
              pn_retcode := 2;
              pv_errbuf := 'Erreur sur récupération Segment 6';
              RAISE e_acct_error;
            END IF;

            -- Segment7 -- PHENIX 2004: Segment6 -> Segment7.
            vv_step := '14 - ';
            IF pv_account_class = 'REV'
            THEN
                             
                SELECT psrp.rule_id
                INTO vn_segment_rule_id
                FROM pa_segment_rule_pairings_all psrp
                WHERE psrp.application_id = 275
                AND psrp.function_code = gv_ar_function_code
                AND psrp.function_transaction_code = gv_ar_function_transaction
                AND psrp.segment_num = 6 
                AND psrp.org_id = vn_org_id; -- Numerotation a partir de 0  -- PHENIX 2004: 5 -> 6.

                Dka_Pa_Tools_Pkg.pa_run_accounting_rule( pn_rule_id       => vn_segment_rule_id,
                                                         pv_event_type    => pv_event_type,
                                                         pn_project_id    => vn_acct_project_id,
                                                         pv_segment_value => vv_segment7, -- PHENIX 2004: vv_segment6 -> vv_segment7.
                                                         pv_errbuf        => pv_errbuf,
                                                         pn_retcode       => pn_retcode );
                IF pn_retcode != 0
                THEN
                        pv_errbuf := 'Erreur sur récupération Segment 7 : ' || pv_errbuf; -- PHENIX 2004: Segment6 -> Segment7.
                        RAISE e_acct_error;
                END IF;
            ELSE
                vv_segment7 := SUBSTR (pv_concatened_segments_in, INSTR (pv_concatened_segments_in, '.', 1, 6) + 1, (INSTR (pv_concatened_segments_in, '.', 1, 7) - INSTR (pv_concatened_segments_in, '.', 1, 6) - 1)); -- Correction TB 16/05/2006 PHENIX 2004: vv_segment6 -> vv_segment7.
            END IF;

            -- Segment8 -- PHENIX 2004: Segment7 -> Segment8.
            vv_step := '15 - ';
            IF pv_account_class = 'REV'
            THEN
                SELECT psrp.rule_id
                INTO vn_segment_rule_id
                FROM pa_segment_rule_pairings_all psrp
                WHERE psrp.application_id = 275
                  AND psrp.function_code = gv_ar_function_code
                  AND psrp.function_transaction_code = gv_ar_function_transaction
                  AND psrp.segment_num = 7 
                  AND psrp.org_id = vn_org_id; -- Numerotation a partir de 0  -- PHENIX 2004: 6 -> 7.
                Dka_Pa_Tools_Pkg.pa_run_accounting_rule(   pn_rule_id       => vn_segment_rule_id,
                                                        pv_event_type    => pv_event_type,
                                                        pn_project_id    => vn_acct_project_id,
                                                        pv_segment_value => vv_segment8,  -- PHENIX 2004: vv_segment7 -> vv_segment8.
                                                        pv_errbuf        => pv_errbuf,
                                                        pn_retcode       => pn_retcode );
                IF pn_retcode != 0
                THEN
                        pv_errbuf := 'Erreur sur récupération Segment 8 : ' || pv_errbuf;  -- PHENIX 2004: Segment7 -> Segment8.
                        RAISE e_acct_error;
                END IF;
            ELSE
                vv_segment8 := SUBSTR (pv_concatened_segments_in, INSTR (pv_concatened_segments_in, '.', 1, 7) + 1, (INSTR (pv_concatened_segments_in, '.', 1, 8) - INSTR (pv_concatened_segments_in, '.', 1, 7) - 1)); -- Correction TB 16/05/2006 PHENIX 2004: vv_segment7 -> vv_segment8.
            END IF;

            -- Segment9 -- PHENIX 2004: Segment8 -> Segment9.
            vv_step := '16 - ';
            IF pv_account_class = 'REV'
            THEN
                SELECT psrp.rule_id
                INTO vn_segment_rule_id
                FROM pa_segment_rule_pairings_all psrp
                WHERE psrp.application_id = 275
                  AND psrp.function_code = gv_ar_function_code
                  AND psrp.function_transaction_code = gv_ar_function_transaction
                  AND psrp.segment_num = 8 
                  AND psrp.org_id = vn_org_id; -- Numerotation a partir de 0  -- PHENIX 2004: 7 -> 8.
                Dka_Pa_Tools_Pkg.pa_run_accounting_rule(   pn_rule_id       => vn_segment_rule_id,
                                                        pv_event_type    => pv_event_type,
                                                        pn_project_id    => vn_acct_project_id,
                                                        pv_segment_value => vv_segment9,  -- PHENIX 2004: vv_segment8 -> vv_segment9.
                                                        pv_errbuf        => pv_errbuf,
                                                        pn_retcode       => pn_retcode );
                IF pn_retcode != 0
                THEN
                        pv_errbuf := 'Erreur sur récupération Segment 9 : ' || pv_errbuf;  -- PHENIX 2004: Segment8 -> Segment9.
                        RAISE e_acct_error;
                END IF;
            ELSE
                vv_segment9 := SUBSTR (pv_concatened_segments_in, INSTR (pv_concatened_segments_in, '.', 1, 8) + 1, (INSTR (pv_concatened_segments_in, '.', 1, 9) - INSTR (pv_concatened_segments_in, '.', 1, 8) - 1));  -- Correction TB 16/05/2006 PHENIX 2004: vv_segment8 -> vv_segment9.
            END IF;

            -- Segment10 -- PHENIX 2004: Ajout.
            vv_step := '16bis - ';
            vv_segment10 := '0';
            vv_segment11 := '0';
            vv_segment12 := '0';


            -- Concaténation
            vv_step := '17 - ';
            pv_concatened_segments_out :=    vv_segment1 || '.'
                                          || vv_segment2 || '.'
                                          || vv_segment3 || '.'
                                          || vv_segment4 || '.'
                                          || vv_segment5 || '.'
                                          || vv_segment6 || '.'
                                          || vv_segment7 || '.'
                                          || vv_segment8 || '.'  -- PHENIX 2004: Ajout: || '.'.
                                          || vv_segment9 || '.'  -- PHENIX 2004: Ajout.
                                          || vv_segment10 || '.'  -- PHENIX 2004: Ajout: || '.'.
                                          || vv_segment11 || '.'  -- migration r12
                                          || vv_segment12 ;       -- migration r12

            --
            -- Si nécessaire, calcul du nouveau ccid
            --
            vv_step := '18 - ';
            IF NVL (pn_ccid_in, -1) != -1
            THEN
                Dka_Tools_Pkg.get_code_combination_id ( vv_segment1,
                                                        vv_segment2,
                                                        vv_segment3,
                                                        vv_segment4,
                                                        vv_segment5,
                                                        vv_segment6,
                                                        vv_segment7,
                                                        vv_segment8,
                                                        vv_segment9,  -- PHENIX 2004: Ajout.
                                                        vv_segment10, -- PHENIX 2004: Ajout.
                                                        vv_segment11, 
                                                        vv_segment12,
                                                        pn_ccid_out,
                                                        pv_errbuf,
                                                        pn_retcode );
                IF pn_retcode != 0
                THEN
                  Pv_Message := pv_errbuf;
                  pv_errbuf := 'Erreur sur récupération vn_ccid_out : ' || pv_errbuf;
                  RAISE e_error;
                END IF;                
            END IF;
        END IF; -- Fin IF pn_project_id IS NOT NULL

    EXCEPTION
        WHEN e_error
        THEN
            pn_retcode := 2;
            IF Pv_Message IS NULL
            THEN
              Pv_Message := vv_step || pv_errbuf;
            END IF;
        WHEN e_acct_error
        THEN
            pn_retcode := 2;
            Pv_Message := vv_step || 'Incompatibilité entre le code projet et le type d''évenement ou de dépense. '|| pv_errbuf;
        WHEN e_seg4_error
        THEN
            pn_retcode := 2;
            Pv_Message := vv_step || pv_errbuf;
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
            IF Pv_Message IS NULL
            THEN
              Pv_Message := vv_step || pv_errbuf;
            END IF;
    END get_acct_combination;

-----------------------------------------------------------------------------------------------------------------------
  --  Nom           :events_status_rejection
  --  Description   :Procedure qui vérifiée le rejet des évenements
  --
  --  PARAMETRES    :
  --    pn_project_id
  --    pd_date
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE events_status_rejection (
        pn_project_id   IN       NUMBER,
        pv_segment1     IN       VARCHAR2,
        pd_date         IN       DATE,
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    )
    IS
        vv_project_status_name   pa_project_statuses.project_status_name%TYPE;
        vd_start_date_active     DATE;
        vd_end_date_active       DATE;
        vv_segment1              pa_projects_all.segment1%TYPE;
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        SELECT pps.project_status_name,
               pps.start_date_active,
               pps.end_date_active,
               pp.segment1
        INTO   vv_project_status_name,
               vd_start_date_active,
               vd_end_date_active,
               vv_segment1
        FROM   pa_projects_all pp,
               pa_project_statuses pps
        WHERE      pp.project_status_code = pps.project_status_code
               AND pp.project_id = pn_project_id;

        IF (   (vv_project_status_name = 'Fermé'/*'CLOSE'*/) -- OBE artf2297904
            OR (pd_date NOT IN (vd_start_date_active, NVL (vd_end_date_active, pd_date)))
           )
        THEN
            pn_retcode    := 2;
            pv_errbuf     := 'Le code projet ' || vv_segment1 || ' ne correspond pas a un code projet actif';
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END events_status_rejection;


-----------------------------------------------------------------------------------------------------------------------
  --  Nom           :events_type_rejection
  --  Description   :Procedure qui vérifiée le rejet des évenements
  --
  --  PARAMETRES    :
  --    pn_project_id
  --    pd_date
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE events_type_rejection (
        pv_event_type   IN       VARCHAR2,
        pd_date         IN       DATE,
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER
    )
    IS
        vd_start_date_active   DATE;
        vd_end_date_active     DATE;
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        SELECT pet.start_date_active,
               pet.end_date_active
        INTO   vd_start_date_active,
               vd_end_date_active
        FROM   pa_event_types pet
        WHERE  pet.event_type = pv_event_type;

        IF pd_date NOT IN (vd_start_date_active, NVL (vd_end_date_active, pd_date))
        THEN
            pn_retcode    := 2;
            pv_errbuf     := 'Le type d''evenement' || pv_event_type || 'non valide';
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END events_type_rejection;


-----------------------------------------------------------------------------------------------------------------------
  --  Nom           : Purge_sarfacman_tmp
  --  Description   : Purger la table temporaire
  --
  --  PARAMETRES    :
  --    pv_errbuf
  --    pv_retcode

--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE purge_sarfacman_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        DELETE      dka_sarfacman_tmp dst;
        --WHERE       dst.transfer_status_code = 'A';

        Dka_Tools_Pkg.put_debug_message (SQL%ROWCOUNT || ' lignes supprimées');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END purge_sarfacman_tmp;


----------------------------------------------------------------------------------------------------------------

--  Nom           :insert_sarfacman_tmp
--  Description   :insertion dans la table dka__sarfacman_tmp
--
--  PARAMETRES :
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    PROCEDURE insert_sarfacman_tmp (
        pv_batch_source_name   IN       VARCHAR2 DEFAULT NULL,
        pv_errbuf              OUT      VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message ('Lancement des insertions dans la table dka_sarfacman_tmp');

        INSERT INTO dka_sarfacman_tmp
                    (cust_trx_line_gl_dist_id,
                     customer_trx_id,
                     cust_trx_line_id,
                     line_type,
                     account_type,
                     gl_date,
                     quantity_invoiced,
                     unit_selling_price,
                     extended_amount,
                     TYPE,
                     NAME,
                     org_id,
                     trx_number,
                     description,
                     bill_to_customer_id,
                     cr_code_combination_id,
                     dr_code_combination_id,
                     project_id,
                     event_type,
                     bill_to_project_id,
                     task_id,
                     task_id_refac,
                     last_update_date,
                     last_updated_by,
                     creation_date,
                     created_by,
                     last_update_login,
                     transfer_status_code,
                     tranfer_rejection_reason
                    )
            SELECT rctlgd.cust_trx_line_gl_dist_id,      --cust_trx_line_gl_dist_id
                   rctlgd.customer_trx_id,               --customer_trx_id
                   rctl.customer_trx_line_id,            --cust_trx_line_id
                   rctl.line_type,                       --line_type
                   gcc.account_type,                     --account_type
                   rctlgd.gl_date,                       --gl_date
                   rctl.quantity_invoiced,               --quantity_invoiced
                   rctl.unit_selling_price,              --unit_selling_price
                   rctlgd.amount,                        --extended_amount
                   rctt.TYPE,                            --TYPE
                   rctt.NAME,                            --NAME
                   rctl.org_id,                          --org_id
                   rct.trx_number,                       --trx_number
                   rctl.description,                     --description
                   rct.bill_to_customer_id,              --bill_to_customer_id
                   rctlgd.code_combination_id,           --cr_code_combination_id
                   NULL,                                 --dr_code_combination_id
                   rctlgd.attribute1,                    --project_id
                   rctlgd.attribute2,                    --event_type
                   rctlgd.attribute3,                    --bill_to_project_id
                   rctlgd.attribute4,                    --task_id
                   rctlgd.attribute7,                    --task_id_refac
                   SYSDATE,                              --last_update_date
                   Fnd_Global.user_id,                   --last_updated_by
                   SYSDATE,                              --creation_date
                   Fnd_Global.user_id,                   --created_by
                   Fnd_Global.login_id,                  --last_update_login
                   'P',                                  --transfer_status_code
                   NULL                                  --tranfer_rejection_reason
            FROM   ra_customer_trx_all rct,
                   ra_customer_trx_lines_all rctl,
                   ra_cust_trx_line_gl_dist_all rctlgd,
                   ra_cust_trx_types_all rctt,
                   ra_batch_sources_all rbs,
                   gl_code_combinations gcc,  -- Ajout TB 16/05/2006
                   PER_SECURITY_PROFILES_V PSP,     -- OBE
                   PER_SECURITY_ORGANIZATIONS_V PSO -- OBE
            WHERE      rctl.customer_trx_id = rct.customer_trx_id
                   AND rctl.customer_trx_id = rctlgd.customer_trx_id
                   AND rctl.customer_trx_line_id = rctlgd.customer_trx_line_id
                   AND rct.cust_trx_type_id = rctt.cust_trx_type_id
                   AND rctt.org_id = rct.org_id
                   AND rbs.org_id =rct.org_id -- OBE
                   AND rbs.batch_source_id = rct.batch_source_id
                   AND rctlgd.code_combination_id = gcc.code_combination_id -- Ajout TB 16/05/2006
                   AND rbs.NAME = NVL (pv_batch_source_name, rbs.NAME)
                   AND rctlgd.attribute5 IS NULL
                   AND rctlgd.attribute1 IS NOT NULL
                   AND rct.complete_flag = 'Y'
                   -- JPE MIGRATION R12
                   AND rct.invoice_currency_code = (SELECT FC.Currency_Code
                                          					 FROM FND_CURRENCIES         FC,
                                          								GL_SETS_OF_BOOKS       GB,
                                          								PA_IMPLEMENTATIONS_ALL IMP
                                          					WHERE FC.Currency_Code =
                                          								DECODE(IMP.Set_Of_Books_ID, Null, Null, GB.CURRENCY_CODE)
                                          						AND GB.Set_Of_Books_ID = IMP.Set_Of_Books_ID
                                          						AND IMP.org_id = rct.org_id)
                   AND rctlgd.gl_posted_date IS NOT NULL
                   --AND rbs.org_id = NVL (gv_org_id,rbs.org_id) -- OBE
                   AND rctlgd.account_class = 'REV'
                   AND PSO.SECURITY_PROFILE_ID    = PSP.SECURITY_PROFILE_ID -- OBE
                   AND PSP.SECURITY_PROFILE_ID    = gv_org_id               -- OBE
                   AND PSO.organization_id        = rbs.org_id              -- OBE
                   ;

        Dka_Tools_Pkg.put_log_message (SQL%ROWCOUNT || ' lignes inserees dans dka_sarfacman_tmp');
        COMMIT;

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_sarfacman_tmp;


 ---------------------------------------------------------------------------------------------------------------------
--  Nom           :get_societe
--  Description   :
--
--  PARAMETRES :
--    pv_project
--    vv_societe
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    PROCEDURE get_societe (
        pv_project   IN       VARCHAR2,
        vv_societe   OUT      VARCHAR2,
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        vn_org_id   NUMBER (15);
        vn_result   NUMBER;
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        SELECT ppa.org_id
        INTO   vn_org_id
        FROM   pa_projects_all ppa
        WHERE  segment1 = pv_project;

        -- Appel de la procédure qui calcule le code societe --
        Dka_Tools_Pkg.get_code_societe (vn_org_id, vv_societe, pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RETURN;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := SQLCODE;
            pv_errbuf    := SQLERRM;
    END get_societe;


 ------------------------------------------------------------------------------------------------------------
   --  Nom           :create_output
  --  Description   :Création du fichier de sortie
  --  PARAMETRES :
  --    pv_errbuf
  --    pn_result
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --                 2: deroulement avec erreur
-----------------------------------------------------------------------------------------------------------
    PROCEDURE create_output (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        --Déclaration du curseur--

        CURSOR dka_sarfacman_tmp_cur
        IS
            SELECT dst.cust_trx_line_gl_dist_id,
                   dst.customer_trx_id,
                   dst.cust_trx_line_id,
                   dst.org_id,
                   dst.trx_number,
                   dst.bill_to_customer_id,
                   dst.cr_code_combination_id,
                   dst.dr_code_combination_id,
                   dst.project_id,
                   dst.event_type,
                   dst.bill_to_project_id,
                   dst.transfer_status_code,
                   dst.tranfer_rejection_reason,
                   pp.segment1 project_number
            FROM   dka_sarfacman_tmp dst,
                   pa_projects_all pp
            WHERE  pp.project_id = dst.project_id
            ORDER BY dst.transfer_status_code DESC;

        dka_sarfacman_tmp_rec   dka_sarfacman_tmp_cur%ROWTYPE;
        vv_message              VARCHAR2 (255);
        vn_count                INTEGER;
        vn_reject               INTEGER; -- Compteur des lignes rejetées (Modif TB 28/06/2005)

    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        --initialisation du compteur a 0 --
        vn_count      := 0;
        vn_reject     := 0; -- Modif TB 28/06/2005
        vv_message    := 'Liste des écritures traitées';
        Fnd_File.put_line (Fnd_File.output, vv_message);
        vv_message    := '-----------------------------';
        Fnd_File.put_line (Fnd_File.output, vv_message);
        vv_message    := '';
        Fnd_File.put_line (Fnd_File.output, vv_message);
        vv_message    := '';
        Fnd_File.put_line (Fnd_File.output, vv_message);
        vv_message    := RPAD ('Numéro facture AR', 25) || ' ' || RPAD ('Code projet', 11) || ' ' || RPAD ('Statut', 6) || ' ' || RPAD ('Motif de rejet', 80);
        Fnd_File.put_line (Fnd_File.output, vv_message);
        vv_message    := RPAD ('-', 25, '-') || ' ' || RPAD ('-', 11, '-') || ' ' || RPAD ('-', 6, '-') || ' ' || RPAD ('-', 80, '-');
        Fnd_File.put_line (Fnd_File.output, vv_message);
        Dka_Tools_Pkg.put_log_message ('Fin presentation');

        IF NOT dka_sarfacman_tmp_cur%ISOPEN
        THEN
            OPEN dka_sarfacman_tmp_cur;
        END IF;

        LOOP
            FETCH dka_sarfacman_tmp_cur INTO dka_sarfacman_tmp_rec;
            EXIT WHEN dka_sarfacman_tmp_cur%NOTFOUND;
            --Affichage des données des enregistrements
            vv_message    :=
                  RPAD (dka_sarfacman_tmp_rec.trx_number, 25) || ' ' || RPAD (dka_sarfacman_tmp_rec.project_number, 11) || ' ' || RPAD (dka_sarfacman_tmp_rec.transfer_status_code, 6) || ' ' || SUBSTR (
                                                                                                                                                                      dka_sarfacman_tmp_rec.tranfer_rejection_reason,
                                                                                                                                                                      1,
                                                                                                                                                                      80
                                                                                                                                                                  );
            Fnd_File.put_line (Fnd_File.output, vv_message);

                -- Calcul des lignes insérées et rejetées (Modif TB 28/06/2005)
        IF dka_sarfacman_tmp_rec.transfer_status_code = 'A'
        THEN
            vn_count      := vn_count + 1;
        ELSE
            vn_reject     := vn_reject + 1;
        END IF;

        END LOOP;
        CLOSE dka_sarfacman_tmp_cur;

              -- Affichage du nombre de lignes insérées et rejetées (Modif TB 28/06/2005)
        vv_message    := '';
        Fnd_File.put_line (Fnd_File.output, vv_message);
        Fnd_File.put_line (Fnd_File.output, vv_message);
        vv_message    := 'Nombre de lignes insérées : ' || TO_CHAR (vn_count);
        Fnd_File.put_line (Fnd_File.output, vv_message);
        vv_message    := '';
        Fnd_File.put_line (Fnd_File.output, vv_message);
        vv_message    := 'Nombre de lignes rejetées : ' || TO_CHAR (vn_reject);
        Fnd_File.put_line (Fnd_File.output, vv_message);


              -- Modification du statut du traitement selon les rejets (Modif TB 28/06/2005)
        IF vn_reject > 0
	      THEN
		        IF vn_count > 0
		        THEN
			          pn_retcode    := 1;
			          pv_errbuf     := 'Attention !!! ' || TO_CHAR (vn_reject) ||' ligne(s) rejetée(s).';
		        ELSIF vn_count = 0
		        THEN
			          pn_retcode    := 2;
			          pv_errbuf     := 'Attention !!! Toutes les lignes ont été rejetées.';
            END IF;
	      ELSE
		         pn_retcode    := 0;
		         pv_errbuf     := NULL;
	      END IF;

    EXCEPTION
        WHEN OTHERS
        THEN

            IF dka_sarfacman_tmp_cur%ISOPEN
            THEN
                CLOSE dka_sarfacman_tmp_cur;
            END IF;

            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END create_output;


---------------------------------------------------------------------------------------------------------------------
 --  Nom           :get_code_saisie
 --  Description   :Recherche du segment5 saisie dans cuf -- PHENIX 2004: segment4 -> segment5.
 --
 --  PARAMETRES :
 --    pv_compte_gl
 --    vv_errbuf
 --    vn_retcode
 --  VALEUR RETOURNEE :
 --     Description       :
 --     Valeurs possibles : 0: deroulement correct
 --                         2: deroulement avec erreur
 ----------------------------------------------------------------------------------------------------------------
    FUNCTION get_code_saisie (
        pv_compte_gl   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        --vn_result     NUMBER;
        vn_debut      NUMBER;
        vn_fin        NUMBER;
        vn_longueur   NUMBER;
        vv_segment5   ra_customers.attribute1%TYPE;  -- PHENIX 2004: vv_segment4 -> vv_segment5.
    BEGIN
        -- Recherche de la position de debut du segment4
        vn_debut       := INSTR (pv_compte_gl, '.', 1, 3) + 1;
        -- Recherche de la position de fin du segment4
        vn_fin         := INSTR (pv_compte_gl, '.', 1, 4);
        --Longueur du segment4
        vn_longueur    := vn_fin - vn_debut;
        --valeur du segment4
        vv_segment5    := SUBSTR (pv_compte_gl, vn_debut, vn_longueur);  -- PHENIX 2004: vv_segment4 -> vv_segment5.
        RETURN vv_segment5;  -- PHENIX 2004: vv_segment4 -> vv_segment5.
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_code_saisie;


--------------------------------------------------------------------------------------------------------------------
--  Nom           :get_attribute_category
--  Description   :Détermine le contexte pour affichage du cuf
--
--  PARAMETRES :
--    pv_compte_gl
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    FUNCTION get_attribute_category (
        pv_account_class     IN   VARCHAR2,
        pv_accounting_flex   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        e_error                  EXCEPTION;
        vv_errbuf                VARCHAR2 (200);
        vn_retcode               NUMBER;
        vv_attribute_category    ra_cust_trx_line_gl_dist_all.attribute_category%TYPE;
        vn_flex_value_set_id     fnd_flex_value_sets.flex_value_set_id%TYPE;
        vv_flex_value_set_name   fnd_flex_value_sets.flex_value_set_name%TYPE;
        vv_flex_value            fnd_flex_values.flex_value%TYPE;
        vv_account_type          VARCHAR2 (1);
        vv_account_attribute     fnd_flex_values.attribute4%TYPE;
        vv_surtaxe_attribute     VARCHAR2(1); -- OBE
    BEGIN
        IF pv_account_class = 'REV'
        THEN
            Dka_Tools_Pkg.get_flex_key_seg_value_set (
                pv_errbuf                      => vv_errbuf,
                pn_retcode                     => vn_retcode,
                pn_segment_num                 => 3,
                pn_flex_value_set_id           => vn_flex_value_set_id,
                pv_flex_value_set_name         => vv_flex_value_set_name
            );

            IF vn_retcode != 0
            THEN
                RAISE e_error;
            END IF;

            --Détermination du segment3
            vv_flex_value    := SUBSTR (pv_accounting_flex, (INSTR (pv_accounting_flex, '.', 1, 2) + 1), (INSTR (pv_accounting_flex, '.', 1, 3) - INSTR (pv_accounting_flex, '.', 1, 2) - 1));

            SELECT SUBSTR (ffv.compiled_value_attributes, 5, 1),
                   ffv.attribute4,
                   NVL(ffv.attribute10,'N') -- OBE
            INTO   vv_account_type,
                   vv_account_attribute,
                   vv_surtaxe_attribute     -- OBE
            FROM   fnd_flex_values ffv
            WHERE      ffv.flex_value_set_id = vn_flex_value_set_id
                   AND ffv.flex_value = vv_flex_value;

            -- Modif TB 16/05/2006
            IF vv_account_type = 'R'
            THEN
                vv_attribute_category    := 'Y';
            ELSIF vv_account_type = 'E'
               THEN
                   vv_attribute_category    := 'C';
               ELSE
                   vv_attribute_category    := 'N';
            END IF;
            
            --< OBE
            IF vv_surtaxe_attribute = 'Y' THEN
              vv_attribute_category    := 'S'; 
            END IF; 
            --> OBE
            
        ELSE
            vv_attribute_category    := 'N';
        END IF; -- Fin pv_account_class = 'REV'

        RETURN vv_attribute_category;
    EXCEPTION
        WHEN e_error
        THEN
            RETURN NULL;
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_attribute_category;


---------------------------------------------------------------------------------------------------------------------
 --  Nom           :Amount_sign
 --  Description   :Recherche du segment4 saisie dans cuf
 --
 --  PARAMETRES :
 --    pv_compte_gl
 --    vv_errbuf
 --    vn_retcode
 --  VALEUR RETOURNEE :
 --     Description       :
 --     Valeurs possibles : 0: deroulement correct
 --                         2: deroulement avec erreur
 ----------------------------------------------------------------------------------------------------------------
    FUNCTION amount_sign (
        pv_type     IN   VARCHAR2,
        pv_name     IN   VARCHAR2,
        pn_amount   IN   NUMBER
    )
        RETURN NUMBER
    IS
        vn_signe   NUMBER;
        amount     NUMBER;
    BEGIN
        vn_signe    := 1;

        IF    (    pv_type = 'INV'
               AND substr (pv_name,6) = gv_type_manuel_annul_fac
              )
           OR (    pv_name = 'CM'
               AND substr (pv_name,6) IN (gv_type_manuel_avoir, gv_type_passage_irrecouvrable)
              )
        THEN
            vn_signe    := -1;
        END IF;

        --Affectation du signe
        amount      := vn_signe * pn_amount;
        RETURN amount;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END amount_sign;


---------------------------------------------------------------------------------------------------------------------
 --  Nom           :get_code_partenaire
 --  Description   :Recherche du segment5 du cuf  -- PHENIX 2004: segment4 -> segment5.
 --
 --  PARAMETRES :
 --    pn_customer_id
 --    pn_cust_site_use_id
 --  VALEUR RETOURNEE :
 --     Description       :
 --     Valeurs possibles : 0: deroulement correct
 --                         2: deroulement avec erreur
 ----------------------------------------------------------------------------------------------------------------
    FUNCTION get_code_partenaire (
        pn_customer_id      IN   NUMBER,
        pn_cust_site_use_id IN NUMBER
    )
        RETURN VARCHAR2
    IS
        --vn_result     NUMBER;
        vv_segment5   ra_customers.attribute1%TYPE; -- PHENIX 2004: vv_segment4 -> vv_segment5.
    BEGIN
        /*SELECT NVL (rc.attribute1, 0)
        INTO   vv_segment5 -- PHENIX 2004: vv_segment4 -> vv_segment5.
        FROM   ra_customers rc
        WHERE  rc.customer_id = pn_customer_id;  */
        --JPE MIGRATION R12
        /*
        SELECT NVL(hca.attribute1, 0)
          INTO vv_segment5
					FROM HZ_CUST_ACCOUNTS hca
				 where hca.cust_account_id = pn_customer_id;
        RETURN vv_segment5;
        */
        --artf2046309
        SELECT NVL(hca_bill_dfv.partenaire_interco, 0)
          INTO vv_segment5
          FROM hz_cust_accounts           bill_cus,
               hz_parties                 bill_party,
               HZ_CUST_SITE_USES_ALL      hcs_bill,
               HZ_CUST_ACCT_SITES_ALL     hca_bill,
               HZ_CUST_ACCT_SITES_ALL_DFV hca_bill_dfv,
               hz_party_sites             hps_bill,
               hz_locations               hl_bill
         WHERE 1 = 1
           AND hca_bill.rowid = hca_bill_dfv.row_id
           AND bill_cus.cust_account_id = pn_customer_id
           AND bill_party.party_id = bill_cus.party_id
           AND hcs_bill.site_use_id = pn_cust_site_use_id
           AND hcs_bill.site_use_code = 'BILL_TO'
           AND hca_bill.cust_acct_site_id = hcs_bill.cust_acct_site_id
           AND hps_bill.party_site_id = hca_bill.party_site_id
           AND hl_bill.location_id = hps_bill.location_id;   
           
        RETURN vv_segment5;     
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_code_partenaire;


----------------------------------------------------------------------------------------------------------------
--  Nom           :get_code_partenaire_desc
--  Description   :Recherche de la description du segment5 -- PHENIX 2004: segment4 -> segment5.
--
--  PARAMETRES :
--    pv_code_partenaire
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    FUNCTION get_code_partenaire_desc (
        pv_code_partenaire   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_code_partenaire_desc   fnd_flex_values_vl.description%TYPE;
    BEGIN
        SELECT ffv.description
        INTO   vv_code_partenaire_desc
        FROM   gl_sets_of_books gsob,
               fnd_id_flex_segments fifs,
               fnd_flex_values_vl ffv
        WHERE      gsob.set_of_books_id = Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID')
               AND fifs.application_id = 101
               AND fifs.id_flex_code = 'GL#'
               AND fifs.id_flex_num = gsob.chart_of_accounts_id
               AND fifs.segment_num = 5 -- PHENIX 2004: 4 -> 5.
               AND ffv.flex_value_set_id = fifs.flex_value_set_id
               AND ffv.flex_value = pv_code_partenaire;

        RETURN vv_code_partenaire_desc;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_code_partenaire_desc;


---------------------------------------------------------------------------------------------------------------------
--  Nom           :get_dr_code_combination_id
--  Description   :insertion des évenements
--
--  PARAMETRES :
--    pv_segment1
--    vv_errbuf
--    vn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
----------------------------------------------------------------------------------------------------------------
    PROCEDURE get_dr_code_combination_id (
        pv_segment1   IN       VARCHAR2,
        pv_segment2   IN       VARCHAR2,  -- PHENIX 2004: Ajout.
        pn_ccid       OUT      NUMBER,
        pv_errbuf     OUT      VARCHAR2,
        pn_retcode    OUT      NUMBER
    )
    IS

--        vv_segment4   gl_code_combinations.segment4%TYPE;
--        vv_segment5   gl_code_combinations.segment5%TYPE;
--        vv_segment6   gl_code_combinations.segment6%TYPE;
--        vv_segment7   gl_code_combinations.segment7%TYPE;
--        vv_segment8   gl_code_combinations.segment8%TYPE;
--        vv_segment9   gl_code_combinations.segment9%TYPE;  -- PHENIX 2004: Ajout.
--        vv_segment10  gl_code_combinations.segment10%TYPE; -- PHENIX 2004: Ajout.


------------------------


    BEGIN
        --Initialisation des valeurs de ségments--
--        vv_segment4    := pv_segment2; -- PHENIX 2004: '0' -> pv_segment2.
--        vv_segment5    := '0';
--        vv_segment6    := '0';
--        vv_segment7    := '0';
--        vv_segment8    := '0';
--        vv_segment9    := '0';  -- PHENIX 2004: Ajout.
--        vv_segment10   := '0';  -- PHENIX 2004: Ajout.

        --Calcul du code combination id --
        -- dka_tools_pkg.get_code_combination_id (pv_segment1, gv_cr_seg2, gv_cr_seg3, vv_segment4, vv_segment5, vv_segment6, vv_segment7, vv_segment8, pn_ccid, pv_errbuf, vn_result);
        --
        -- IF vn_result != 0
        -- THEN
        --     pn_retcode    := 2;
        --     dka_tools_pkg.put_log_message (pv_errbuf);
        --     RETURN;
        -- END IF;

        BEGIN
            SELECT gcc.code_combination_id
            INTO   pn_ccid
            FROM   gl_code_combinations gcc
            WHERE      gcc.segment1 = pv_segment1
                   AND gcc.segment2 = pv_segment2  -- PHENIX 2004: gv_cr_seg2 -> pv_segment2
                   AND gcc.segment3 = gv_cr_seg3
                   AND gcc.segment4 = gv_cr_seg4   -- PHENIX 2004: '0' -> gv_cr_seg4
                   AND gcc.segment5 = '0'
                   AND gcc.segment6 = '0'
                   AND gcc.segment7 = '0'
                   AND gcc.segment8 = '0'
                   AND gcc.segment9 = '0'
                   AND gcc.segment10= '0'
                   -- AND gcc.enabled_flag = 'Y'; --Ajout TB 19/08/2005 : pour éviter doublon de ccid -- MODIF TB 23/03/2009
                   AND ROWNUM = 1; -- MODIF TB 23/03/2009 : correction pour doublon
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                SELECT gl_code_combinations_s.NEXTVAL
                INTO pn_ccid
                FROM dual; 
                
                -- Insertion de la nouvelle combinaison
                INSERT INTO gl_code_combinations (
                    code_combination_id,
                    chart_of_accounts_id,
                    detail_posting_allowed_flag,
                    detail_budgeting_allowed_flag,
                    account_type,
                    enabled_flag,
                    summary_flag,
                    preserve_flag,
                    segment1,
                    segment2,
                    segment3,
                    segment4,
                    segment5,
                    segment6,
                    segment7,
                    segment8,
                    segment9,   -- PHENIX 2004: Ajout.
                    segment10,  -- PHENIX 2004: Ajout.
                    reference3,
                    jgzz_recon_flag,
                    last_update_date,
                    last_updated_by
                )
                SELECT pn_ccid,
                       gl.chart_of_accounts_id,
                       'N',
                       'N',
                       'A',
                       'N',
                       'N',
                       'Y',
                       pv_segment1,
                       pv_segment2,  -- PHENIX 2004: gv_cr_seg2 -> pv_segment2
                       gv_cr_seg3,
                       gv_cr_seg4,   -- PHENIX 2004: '0' -> gv_cr_seg4
                       '0',
                       '0',
                       '0',
                       '0',
                       '0',          -- PHENIX 2004: Ajout.
                       '0',          -- PHENIX 2004: Ajout.
                       'N',
                       'N',
                       SYSDATE,
                       Fnd_Global.user_id
                FROM   gl_ledgers gl /*gl_sets_of_books gsob*/ -- OBE artf2297904
                WHERE  gl.ledger_id /*gsob.set_of_books_id*/ = (SELECT SET_OF_BOOKS_ID FROM HR_OPERATING_UNITS WHERE SHORT_CODE = pv_segment2 || pv_segment1); -- OBE artf2297904

                -- Récupération de l'id
                /*SELECT gl_code_combinations_s.CURRVAL
                INTO   pn_ccid
                FROM   dual;*/
        END;

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
            Dka_Tools_Pkg.put_log_message (pv_errbuf);
    END get_dr_code_combination_id;

----------------------------------------------------------------------------------------
--  Nom           :  get_burden_cost_f
--  Description   :  renvoie le montant des co¹ts complets
----------------------------------------------------------------------------------------
    FUNCTION get_burden_cost_f (
        pn_org_id                        IN   NUMBER,
        pn_task_id                       IN   NUMBER,
        pd_ref_date                      IN   DATE,
        pv_expenditure_type              IN   VARCHAR2,
        pn_expenditure_organization_id   IN   NUMBER,
        pn_raw_cost                      IN   NUMBER
    )
        RETURN NUMBER
    IS
        vn_status          NUMBER := 0;
        vn_stage           NUMBER;
        vn_indirect_cost   NUMBER;
    BEGIN
        -- On se place dans la bonne ORG_ID si on ne l'est pas déja
        IF NVL(gn_current_org_id,-1) != pn_org_id --RBE artf2060019 
        THEN
            Fnd_Profile.put ('ORG_ID', pn_org_id); 
            --Fnd_Client_Info.set_org_context (CONTEXT => pn_org_id);
            mo_global.set_policy_context('S',pn_org_id); --RBE artf2060019 
            gn_current_org_id    := pn_org_id;
        END IF;

        Pa_Cost_Plus1.view_indirect_cost (
            task_id                => pn_task_id,
            effective_date         => pd_ref_date,
            expenditure_type       => pv_expenditure_type,
            organization_id        => pn_expenditure_organization_id,
            schedule_type          => 'C',
            direct_cost            => pn_raw_cost,
            indirect_cost          => vn_indirect_cost,
            status                 => vn_status,
            stage                  => vn_stage
        );
 
        RETURN (NVL (pn_raw_cost, 0) + NVL (vn_indirect_cost, 0));
    EXCEPTION
        WHEN e_error
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SARFACMAN_PKG.get_burden_cost_f:' || SQLERRM;
            RAISE e_error;
    END get_burden_cost_f;    

----------------------------------------------------------------------------------------
--  Nom           :  get_task_id_f
--  Description   :  renvoie l'id de la tache d'un projet (par défaut la tache '1')
----------------------------------------------------------------------------------------
    FUNCTION get_task_id_f (
        pn_project_id    IN   NUMBER,
        pv_task_number   IN   VARCHAR2 DEFAULT NULL
    )
        RETURN NUMBER
    IS
        vn_task_id   pa_tasks.task_id%TYPE;
    BEGIN
        SELECT pt.task_id
        INTO   vn_task_id
        FROM   pa_tasks pt
        WHERE      pt.project_id = pn_project_id
               AND pt.task_number = NVL (pv_task_number, gv_default_task_number);

        RETURN vn_task_id;
    EXCEPTION
        WHEN e_error
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SARFACMAN_PKG.get_task_id_f:' || SQLERRM;
            RAISE e_error;
    END get_task_id_f;    

----------------------------------------------------------------------------------------
--  Nom           :  get_org_id_f
--  Description   :  renvoie l'id de l'org dont le nom est passé en parametre
----------------------------------------------------------------------------------------
    FUNCTION get_org_id_f (
        pv_org_name   IN   VARCHAR2
    )
        RETURN NUMBER
    IS
        vn_organization_id   hr_all_organization_units.organization_id%TYPE;
    BEGIN
        SELECT hou.organization_id
        INTO   vn_organization_id
        FROM   hr_all_organization_units hou
        WHERE  hou.NAME = pv_org_name;

        RETURN vn_organization_id;
    EXCEPTION
        WHEN e_error
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SARFACMAN_PKG.get_org_id_f:' || SQLERRM;
            RAISE e_error;
    END get_org_id_f;
    
--------------------------------------------------------------------------------------
--  Nom           : Ins_Pa_Expend_Groups
--  Description   : Insertion d'un enregistrement dans PA_EXPENDITURE_GROUPS_ALL
--------------------------------------------------------------------------------------
    PROCEDURE ins_pa_expend_groups (
        pv_company_code        IN       VARCHAR2,
        pn_org_id              IN       NUMBER,
        pd_gl_date             IN       DATE,
        pv_expenditure_group   OUT      VARCHAR2
    )
    IS
        vn_nb   NUMBER (1);
    BEGIN
        pv_expenditure_group    := 'AR-' || pv_company_code || '-' || TO_CHAR (gn_request_id);

        SELECT COUNT (*)
        INTO   vn_nb
        FROM   pa_expenditure_groups_all
        WHERE  expenditure_group = pv_expenditure_group;

        IF vn_nb > 0
        THEN
            RETURN;
        END IF;

        INSERT INTO pa_expenditure_groups_all
                    (
                     expenditure_group,   --VARCHAR2 (20)  NOT NULL,
                     expenditure_group_status_code,   --VARCHAR2 (30)  NOT NULL,
                     expenditure_ending_date,   --DATE          NOT NULL,
                     system_linkage_function,   --VARCHAR2 (30)  NOT NULL,
                     transaction_source,   --VARCHAR2 (30),
                     description,   --VARCHAR2 (250),
                     org_id,   --NUMBER (15)
                     request_id,   --NUMBER (15),
                     program_application_id,
                     program_id,
                     program_update_date,
                     last_update_login,
                     last_update_date,   --DATE          NOT NULL,
                     last_updated_by,   --NUMBER (15)   NOT NULL,
                     creation_date,   --DATE          NOT NULL,
                     created_by   --NUMBER (15)   NOT NULL,
                    )
        VALUES      (
                     pv_expenditure_group,   --expenditure_group
                     gv_expend_group_status_code,   --expenditure_group_status_code -- 'SUBMITTED' ?
                     pd_gl_date,   --expenditure_ending_date
                     gv_system_linkage_function,   --system_linkage_function    -- Miscellaneous Transaction = Mouvements divers ?
                     gv_transaction_source,   --transaction_source        -- Pré-approuvé -- Oracle GL ??
                     pv_expenditure_group,   --description
                     pn_org_id,   --org_id
                     gn_request_id,   --request_id
                     gn_program_application_id,   -- program_application_id
                     gn_program_id,   -- program_id
                     SYSDATE,   -- program_update_date
                     gn_last_update_login,   -- last_update_login
                     SYSDATE,   --last_update_date
                     gn_user_id,   --last_updated_by
                     SYSDATE,   --creation_date
                     gn_user_id   --created_by
                    );
    EXCEPTION
        WHEN e_error
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SARFACMAN_PKG.Ins_Pa_Expend_Groups:' || SQLERRM;
            RAISE e_error;
    END ins_pa_expend_groups;

--------------------------------------------------------------------------------------
--  Nom           : Ins_Pa_Expenditures
--  Description   : Insertion d'un enregistrement dans PA_EXPENDITURES_ALL
--------------------------------------------------------------------------------------
    PROCEDURE ins_pa_expenditures (
        pv_expenditure_group             IN       VARCHAR2,
        pd_gl_date                       IN       DATE,
        pn_expenditure_organization_id   IN       NUMBER,
        pn_org_id                        IN       NUMBER,
        pn_expenditure_id                OUT      NUMBER
    )
    IS
    BEGIN
        SELECT pa_expenditures_s.NEXTVAL
        INTO   pn_expenditure_id
        FROM   DUAL;

        INSERT INTO pa_expenditures_all
                    (
                     expenditure_id,   --number (15)   not null,
                     expenditure_group,   --varchar2 (20),
                     expenditure_status_code,   --varchar2 (30)  not null,
                     expenditure_ending_date,   --date          not null,
                     expenditure_class_code,   --varchar2 (2)  not null,
                     incurred_by_organization_id,   --number (15), -- ORG DE LA D+PENSE
                     incurred_by_person_id,   --number (9),
                     acct_currency_code,   --varchar2 (15),
                     org_id,   --number (15)
                     request_id,   --NUMBER (15),
                     program_application_id,
                     program_id,
                     program_update_date,
                     last_update_login,
                     last_update_date,   --date          not null,
                     last_updated_by,   --number (15)   not null,
                     creation_date,   --date          not null,
                     created_by   --number (15)   not null,
                    )
        VALUES      (
                     pn_expenditure_id,   --expenditure_id
                     pv_expenditure_group,   -- expenditure_group
                     gv_expenditure_status_code,   --expenditure_status_code
                     pd_gl_date,   --expenditure_ending_date
                     gv_expenditure_class_code,   --expenditure_class_code     -- main d'oeuvre
                     pn_expenditure_organization_id,   --incurred_by_organization_id
                     NULL,   --incurred_by_person_id
                     gv_currency_code,   --acct_currency_code
                     pn_org_id,   --org_id
                     gn_request_id,   --request_id
                     gn_program_application_id,   -- program_application_id
                     gn_program_id,   -- program_id
                     SYSDATE,   -- program_update_date
                     gn_last_update_login,   -- last_update_login
                     SYSDATE,   --last_update_date
                     gn_user_id,   --last_updated_by
                     SYSDATE,   --creation_date
                     gn_user_id   --created_by
                    );
    EXCEPTION
        WHEN e_error
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SARFACMAN_PKG.Ins_Pa_Expenditures:' || SQLERRM;
            RAISE e_error;
    END ins_pa_expenditures;

--------------------------------------------------------------------------------------
--  Nom           : Ins_Pa_Expend_Items
--  Description   : Insertion d'un enregistrement dans PA_EXPENDITURE_ITEMS_ALL
--------------------------------------------------------------------------------------
    PROCEDURE ins_pa_expend_items (
        pn_expenditure_id                IN       NUMBER,
        pv_expenditure_type              IN       VARCHAR2,
        pn_expenditure_organization_id   IN       NUMBER,
        pn_project_id                    IN       NUMBER,
        pn_task_id                       IN       NUMBER,
        pn_raw_cost                      IN       NUMBER,
        pn_burden_cost                   IN       NUMBER,
        pn_quantity                      IN       NUMBER,
        pn_project_id_refac              IN       NUMBER,
        pv_orig_transaction_reference    IN       VARCHAR2,
        pd_gl_date                       IN       DATE,
        pn_org_id                        IN       NUMBER,
        pv_attribute_category            IN       VARCHAR2,
        pv_description                   IN       VARCHAR2,
        pn_expenditure_item_id           OUT      NUMBER
    )
    IS
    BEGIN
        SELECT pa_expenditure_items_s.NEXTVAL
        INTO   pn_expenditure_item_id
        FROM   DUAL;

        INSERT INTO pa_expenditure_items_all
                    (
                     expenditure_item_id,   --number (15)   not null,
                     expenditure_id,   --number (15)   not null,
                     expenditure_item_date,   --date          not null,
                     expenditure_type,   --varchar2 (30)  not null,
                     orig_transaction_reference,   -- varchar2 (30), -- NO UNIQUE !!!
                     transaction_source,   -- varchar2 (30), -- 'ORACLE GL'
                     project_id,   -- number (15),
                     task_id,   --number (15)   not null,
                     cost_distributed_flag,   --varchar2 (1)  not null, -- INDICATEUR COOT CALCUL+
                     revenue_distributed_flag,   --varchar2 (1)  not null, -- 'n'
                     billable_flag,   --varchar2 (1)  not null, -- 'n'
                     bill_hold_flag,   --varchar2 (1)  not null, -- 'n'
                     quantity,   --number (22,5), -- QUANTIT+
                     non_labor_resource,   --varchar2 (20),
                     organization_id,   --number (15),      -- ??
                     override_to_organization_id,   --number (15),
                     raw_cost,   --number (22,5), -- COUT DIRECT
                     raw_cost_rate,   --number (22,5), -- COUT DIRECT / QUANTIT+
                     burden_cost,   --number (22,5), -- COUT COMPLET
                     burden_cost_rate,   --number (22,5), -- COUT COMPLET / QUANTIT+
                     system_linkage_function,   --varchar2 (3)  not null,  -- ???
                     denom_currency_code,   --varchar2 (15),
                     acct_currency_code,   --varchar2 (15),
                     project_currency_code,   --varchar2 (15),
                     cc_cross_charge_code,   --varchar2 (1)  default 'P' not null,
                     cc_cross_charge_type,   --varchar2 (2)  default 'NO',
                     cc_bl_distributed_code,   --varchar2 (1)  default 'X' not null,
                     cc_ic_processed_code,   --varchar2 (1)  default 'X' not null,
                     cc_prvdr_cost_reclass_code,   --varchar2 (1)  default 'N',
                     net_zero_adjustment_flag,   --varchar2 (1)
                     acct_burdened_cost,
                     acct_raw_cost,
                     cost_burden_distributed_flag,
                     denom_burdened_cost,
                     denom_raw_cost,
                     attribute_category,   --varchar2 (30),
                     attribute1,   --varchar2 (150), -- cuf PROJET + REFACTURER
                     attribute4,   --varchar2 (150),
                     org_id,   --number (15)
                     request_id,   --NUMBER (15),
                     program_application_id,
                     program_id,
                     program_update_date,
                     last_update_login,
                     last_update_date,   --date          not null,
                     last_updated_by,   --number (15)   not null,
                     creation_date,   --date          not null,
                     created_by   --number (15)   not null,
                     -- PHENIX 2004
                     , COST_DIST_WARNING_CODE, PROJECT_TP_RATE_DATE, PROJECT_TP_RATE_TYPE, PROJECT_TP_EXCHANGE_RATE,
                     PROJFUNC_TP_RATE_DATE, PROJFUNC_TP_RATE_TYPE, PROJFUNC_TP_EXCHANGE_RATE, PROJFUNC_TRANSFER_PRICE,
                     BILL_TRANS_FORECAST_CURR_CODE, BILL_TRANS_FORECAST_REVENUE, PROJFUNC_REV_RATE_DATE,
                     PROJFUNC_REV_EXCHANGE_RATE, PROJFUNC_COST_RATE_TYPE, PROJFUNC_COST_RATE_DATE,
                     PROJFUNC_COST_EXCHANGE_RATE, PROJECT_RAW_COST, PROJECT_BURDENED_COST, ASSIGNMENT_ID, WORK_TYPE_ID,
                     PROJFUNC_RAW_REVENUE, PROJECT_BILL_AMOUNT, PROJFUNC_CURRENCY_CODE, PROJECT_RAW_REVENUE,
                     PROJECT_TRANSFER_PRICE, TP_AMT_TYPE_CODE, BILL_TRANS_CURRENCY_CODE, BILL_TRANS_RAW_REVENUE,
                     BILL_TRANS_BILL_AMOUNT, BILL_TRANS_ADJUSTED_REVENUE, REVPROC_CURRENCY_CODE, REVPROC_RATE_TYPE,
                     REVPROC_RATE_DATE, REVPROC_EXCHANGE_RATE, INVPROC_CURRENCY_CODE, INVPROC_RATE_TYPE, INVPROC_RATE_DATE,
                     DISCOUNT_PERCENTAGE, LABOR_MULTIPLIER, AMOUNT_CALCULATION_CODE, BILL_MARKUP_PERCENTAGE, RATE_SOURCE_ID,
                     INVPROC_EXCHANGE_RATE, INV_GEN_REJECTION_CODE, PROJFUNC_BILL_AMOUNT, PROJECT_REV_RATE_TYPE,
                     PROJECT_REV_RATE_DATE, PROJECT_REV_EXCHANGE_RATE, PROJFUNC_REV_RATE_TYPE, PROJFUNC_INV_RATE_TYPE,
                     PROJFUNC_INV_RATE_DATE, PROJFUNC_INV_EXCHANGE_RATE, PROJECT_INV_RATE_TYPE, PROJECT_INV_RATE_DATE,
                     PROJECT_INV_EXCHANGE_RATE, PROJFUNC_FCST_RATE_TYPE, PROJFUNC_FCST_RATE_DATE, PROJFUNC_FCST_EXCHANGE_RATE,
                     PRVDR_ACCRUAL_DATE, RECVR_ACCRUAL_DATE, RATE_DISC_REASON_CODE, POSTED_DENOM_BURDENED_COST,
                     POSTED_PROJECT_BURDENED_COST, POSTED_PROJFUNC_BURDENED_COST, POSTED_ACCT_BURDENED_COST, ADJUSTMENT_TYPE,
                     CAPITAL_EVENT_ID
                     -- FIN PHENIX 2004
                    )
        VALUES      (
                     pn_expenditure_item_id,   --expenditure_item_id
                     pn_expenditure_id,   --expenditure_id
                     pd_gl_date,   --expenditure_item_date
                     pv_expenditure_type,   --expenditure_type
                     pv_orig_transaction_reference,   --orig_transaction_reference
                     gv_transaction_source,   --transaction_source            ???
                     pn_project_id,   --project_id
                     pn_task_id,   --task_id
                     'Y',   --cost_distributed_flag
                     'N',   --revenue_distributed_flag
                     'N',   --billable_flag
                     'N',   --bill_hold_flag
                     pn_quantity,   --quantity
                     NULL,   --non_labor_resource         ???
                     NULL,   --organization_id            ???
                     pn_expenditure_organization_id,   --override_to_organization_id
                     pn_raw_cost,   --raw_cost
                     pn_raw_cost / pn_quantity,   --raw_cost_rate
                     pn_burden_cost,   --burden_cost
                     pn_burden_cost / pn_quantity,   --burden_cost_rate
                     gv_system_linkage_function,   --system_linkage_function
                     gv_currency_code,   --denom_currency_code
                     gv_currency_code,   --acct_currency_code
                     gv_currency_code,   --project_currency_code
                     'P',   --cc_cross_charge_code       ??
                     'NO',   --cc_cross_charge_type       ??
                     'X',   --cc_bl_distributed_code
                     'X',   --cc_ic_processed_code
                     'N',   --cc_prvdr_cost_reclass_code
                     'N',   --net_zero_adjustment_flag
                     pn_burden_cost,   --acct_burdened_cost
                     pn_raw_cost,   --acct_raw_cost
                     'N',   --cost_burden_distributed_flag
                     pn_burden_cost,   --denom_burdened_cost
                     pn_raw_cost,   --denom_raw_cost
                     pv_attribute_category,   --attribute_category
                     pn_project_id_refac,   --attribute1
                     pv_orig_transaction_reference,   --attribute4
                     pn_org_id,   --org_id
                     gn_request_id,   --request_id
                     gn_program_application_id,   -- program_application_id
                     gn_program_id,   -- program_id
                     SYSDATE,   -- program_update_date
                     gn_last_update_login,   -- last_update_login
                     SYSDATE,   --last_update_date
                     gn_user_id,   --last_updated_by
                     SYSDATE,   --creation_date
                     gn_user_id   --created_by
                     -- PHENIX 2004
                     , NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL,
                     NULL, NULL, NULL,
                     NULL, pn_raw_cost, pn_burden_cost, NULL, NULL,
                     NULL, NULL, 'EUR', NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL
                     -- FIN PHENIX 2004
                    );

        IF pv_description IS NOT NULL
        THEN
            INSERT INTO pa_expenditure_comments
                        (
                         expenditure_item_id,   --number (15)   not null,
                         line_number,   --number (15)   not null,
                         expenditure_comment,   --varchar2 (240)  not null,
                         request_id,   --number (15),
                         program_application_id,
                         program_id,
                         program_update_date,
                         last_update_login,
                         last_update_date,   --date          not null,
                         last_updated_by,   --number (15)   not null,
                         creation_date,   --date          not null,
                         created_by   --number (15)   not null,
                        )
            VALUES      (
                         pn_expenditure_item_id,   --expenditure_item_id
                         1,   --line_number
                         pv_description,   --expenditure_comment
                         gn_request_id,   --request_id
                         gn_program_application_id,   -- program_application_id
                         gn_program_id,   -- program_id
                         SYSDATE,   -- program_update_date
                         gn_last_update_login,   -- last_update_login
                         SYSDATE,   --last_update_date
                         gn_user_id,   --last_updated_by
                         SYSDATE,   --creation_date
                         gn_user_id   --created_by
                        );
        END IF;
    EXCEPTION
        WHEN e_error
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SARFACMAN_PKG.Ins_Pa_Expend_Items:' || SQLERRM;
            RAISE e_error;
    END ins_pa_expend_items;

--------------------------------------------------------------------------------------
--  Nom           : Ins_Pa_Cost_Distrib_Lines
--  Description   : Insertion d'un enregistrement dans PA_COST_DISTRIBUTION_LINES_ALL
--------------------------------------------------------------------------------------
    PROCEDURE ins_pa_cost_distrib_lines (
        pn_expenditure_item_id      IN   NUMBER,
        pn_project_id               IN   NUMBER,
        pn_task_id                  IN   NUMBER,
        pn_cr_code_combination_id   IN   NUMBER,
        pn_dr_code_combination_id   IN   NUMBER,
        pn_raw_cost                 IN   NUMBER,
        pn_burden_cost              IN   NUMBER,
        pn_quantity                 IN   NUMBER,
        pv_batch_name               IN   VARCHAR2,
        pd_gl_date                  IN   DATE,
        pd_pa_date                  IN   DATE,
        pn_org_id                   IN   NUMBER
    )
    IS
      vv_period     gl_periods.period_name%TYPE;
    BEGIN
        IF gn_set_of_books_id IS NULL THEN
         SELECT SET_OF_BOOKS_ID 
         INTO gn_set_of_books_id 
         FROM HR_OPERATING_UNITS 
         WHERE organization_id = pn_org_id;
        END IF;
        
        SELECT period_name
        INTO   vv_period
        FROM   gl_periods gp, gl_sets_of_books gsob
        WHERE  pd_gl_date BETWEEN gp.start_date AND gp.end_date
        AND    gp.period_set_name = gsob.period_set_name
        AND    set_of_books_id = gn_set_of_books_id;

        INSERT INTO pa_cost_distribution_lines_all
                    (
                     expenditure_item_id,   --number (15)   not null,
                     line_num,   --number (15)   not null,
                     transfer_status_code,   --varchar2 (1)  not null, -- 'A'
                     amount,   --number (22,5) not null, -- IDEM
                     quantity,   --number (22,5) not null,
                     billable_flag,   --varchar2 (1)  not null,
                     transferred_date,   --date,
                     code_combination_id,   --number (15),
                     cr_code_combination_id,   --number (15),
                     dr_code_combination_id,   --number (15), -- !!
                     burdened_cost,   --number (22,5),
                     acct_raw_cost,   --number,
                     denom_raw_cost,   --number,
                     acct_burdened_cost,   --number,
                     denom_burdened_cost,   --number,
                     denom_currency_code,   --varchar2 (15),
                     acct_currency_code,   --varchar2 (15),
                     ind_compiled_set_id,   --number (15),
                     pa_date,   --date,
                     gl_date,   --date,
                     project_id,   --number (15)   not null,
                     task_id,   --number (15)   not null,
                     project_currency_code,   --varchar2 (15),
                     batch_name,   --varchar2 (30),     -- NOM DU LOT DANS gl
                     line_type,   --varchar2 (1)  not null, -- 'r'
                     org_id,   --number (15)
                     request_id,   --NUMBER (15),
                     program_application_id,
                     program_id,
                     program_update_date,
                     creation_date,   --date          not null,
                     created_by   --number (15)   not null,
                     -- PHENIX 2004
                     , UTIL_SUMMARIZED_FLAG, LIQUIDATE_ENCUM_FLAG, ENCUMBRANCE_BATCH_NAME,
                     ENCUMBRANCE_TYPE_ID, ENCUM_TRANSFER_REJ_REASON, BUDGET_CCID, ENCUMBRANCE_AMOUNT,
                     PROJFUNC_COST_EXCHANGE_RATE, PROJECT_RAW_COST, PROJECT_BURDENED_COST, WORK_TYPE_ID,
                     GL_PERIOD_NAME, RECVR_GL_PERIOD_NAME, PA_PERIOD_NAME, PROJFUNC_COST_RATE_TYPE,
                     PROJFUNC_COST_RATE_DATE, RECVR_PA_PERIOD_NAME, PROJFUNC_CURRENCY_CODE, SYSTEM_REFERENCE4,
                     PJI_SUMMARIZED_FLAG, ORG_LABOR_SCH_RULE_ID, COST_RATE_SCH_ID, DENOM_BURDENED_CHANGE,
                     PROJECT_BURDENED_CHANGE, PROJFUNC_BURDENED_CHANGE, ACCT_BURDENED_CHANGE, PARENT_LINE_NUM,
                     PREV_IND_COMPILED_SET_ID
                     -- FIN PHENIX 2004
                    )
        VALUES      (
                     pn_expenditure_item_id,   --expenditure_item_id
                     1,   --line_num
                     'A',   --transfer_status_code
                     pn_raw_cost,   --amount
                     pn_quantity,   --quantity
                     'Y',   --billable_flag              ???
                     SYSDATE,   --transferred_date       ???
                     NULL,   --code_combination_id
                     pn_cr_code_combination_id,   --cr_code_combination_id
                     pn_dr_code_combination_id,   --dr_code_combination_id
                     pn_burden_cost,   --burdened_cost
                     pn_raw_cost,   --acct_raw_cost
                     pn_raw_cost,   --denom_raw_cost
                     pn_burden_cost,   --acct_burdened_cost
                     pn_burden_cost,   --denom_burdened_cost
                     gv_currency_code,   --denom_currency_code
                     gv_currency_code,   --acct_currency_code
                     NULL,   --ind_compiled_set_id        ???
                     pd_pa_date,   --pa_date
                     pd_gl_date,   --gl_date
                     pn_project_id,   --project_id
                     pn_task_id,   --task_id
                     gv_currency_code,   --project_currency_code
                     pv_batch_name,   --batch_name
                     gv_line_type,   --line_type
                     pn_org_id,   --org_id
                     gn_request_id,   --request_id
                     gn_program_application_id,   -- program_application_id
                     gn_program_id,   -- program_id
                     SYSDATE,   -- program_update_date
                     SYSDATE,   --creation_date
                     gn_user_id   --created_by
                     -- PHENIX 2004
                     , 'N', NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, pn_raw_cost, pn_burden_cost, NULL,
                     vv_period, vv_period, vv_period, NULL,
                     NULL, vv_period, 'EUR', NULL,
                     'N', NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL
                     -- FIN PHENIX 2004
                    );
    EXCEPTION
        WHEN e_error
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SARFACMAN_PKG.Ins_Pa_Cost_Distrib_Lines:' || SQLERRM;
            RAISE e_error;
    END ins_pa_cost_distrib_lines;  
    
    
---------------------------------------------------------------------------------------------------------------------
  --  Nom           :insert_pa_events
  --  Description   :insertion des évenements
  --
  --  PARAMETRES :
  --    vv_errbuf
  --    vn_retcode
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --                         2: deroulement avec erreur
  ----------------------------------------------------------------------------------------------------------------

    PROCEDURE insert_pa_events (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        --Déclaration du curseur sur les évenements--

        CURSOR events_cur
        IS
            SELECT dst.ROWID row_id,
                   dst.cust_trx_line_gl_dist_id,
                   dst.customer_trx_id,
                   dst.cust_trx_line_id,
                   dst.line_type,
                   dst.gl_date,
                   dst.quantity_invoiced,
                   dst.unit_selling_price,
                   dst.extended_amount,
                   dst.TYPE,
                   dst.NAME,
                   dst.org_id,
                   dst.trx_number,
                   dst.description,
                   dst.bill_to_customer_id,
                   dst.cr_code_combination_id,
                   dst.dr_code_combination_id,
                   dst.project_id,
                   dst.task_id,
                   dst.event_type,
                   dst.bill_to_project_id,
                   dst.task_id_refac,
                   dst.last_update_date,
                   dst.last_updated_by,
                   dst.creation_date,
                   dst.created_by,
                   dst.last_update_login,
                   dst.transfer_status_code,
                   dst.tranfer_rejection_reason,
                   gcc.segment1,
                   gcc.segment2
            FROM   dka_sarfacman_tmp dst,
                   gl_code_combinations gcc
            WHERE  gcc.code_combination_id = dst.cr_code_combination_id
              AND  dst.account_type = 'R';

        events_rec                  events_cur%ROWTYPE;
        vn_dr_code_combination_id   NUMBER (15);
        vv_event_attr_context       pa_events.attribute_category%TYPE;
        vv_uo_proj                  hr_operating_units.SHORT_CODE%TYPE;
        
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        ---recupération des évenement ---
        IF NOT events_cur%ISOPEN
        THEN
            OPEN events_cur;
        END IF;

        LOOP
            FETCH events_cur INTO events_rec;
            EXIT WHEN events_cur%NOTFOUND;

            DECLARE
                e_error     EXCEPTION;
            BEGIN

                --verification de la validité du statut de l''evenenment--
                Dka_Sarfacman_Pkg.events_status_rejection (events_rec.project_id, events_rec.segment2 || events_rec.segment1, events_rec.gl_date, pv_errbuf, pn_retcode);  -- PHENIX 2004: events_rec.segment1 -> events_rec.segment2 || events_rec.segment1.

                IF pn_retcode != 0
                THEN
                    RAISE e_error;
                END IF;

                --vérification de la validité du type de l''évenement--
                Dka_Sarfacman_Pkg.events_type_rejection (events_rec.event_type, events_rec.gl_date, pv_errbuf, pn_retcode);

                IF pn_retcode != 0
                THEN
                    RAISE e_error;
                END IF;

                ---Appel de la procedure qui calcule le ccid--
                Dka_Sarfacman_Pkg.get_dr_code_combination_id (events_rec.segment1, events_rec.segment2, vn_dr_code_combination_id, pv_errbuf, pn_retcode);  -- PHENIX 2004: Ajout: events_rec.segment2, .

                --Vérification du calcul du ccid--
                IF pn_retcode != 0
                THEN
                    RAISE e_error;
                END IF;

                --Détermination du contexte de l'évenement--
                IF events_rec.bill_to_project_id IS NOT NULL
                THEN
                    vv_event_attr_context    := gv_event_context_refac;
                ELSE
                    vv_event_attr_context    := gv_event_context_normal;
                END IF;

                --Appel du package 
                Dka_Pa_Tools_Pkg.pa_insert_event (
                    pn_task_id              => events_rec.task_id,
                    pv_event_type           => events_rec.event_type,
                    pn_amount               => events_rec.extended_amount,
                    pn_project_id           => events_rec.project_id,
                    pd_completion_date      => events_rec.gl_date,
                    pn_group_id             => TO_NUMBER (NULL),
                    pv_insert_revenue_flag  => 'Y',
                    pv_insert_into_gl       => 'N',
                    pn_unbilled_ccid        => vn_dr_code_combination_id,
                    pv_description          => nvl(events_rec.event_type,'event_type vide'),
                    pn_ccid                 => events_rec.cr_code_combination_id,
                    pv_event_attr_context   => vv_event_attr_context,
                    pv_event_attribute1     => events_rec.bill_to_project_id,
                    pv_event_attribute2     => TO_CHAR (NULL),
                    pv_event_attribute3     => TO_CHAR (NULL),
                    pv_event_attribute4     => TO_CHAR (events_rec.cust_trx_line_gl_dist_id),
                    pv_event_attribute5     => TO_CHAR (NULL),
                    pv_event_attribute7     => events_rec.task_id_refac,
                    pv_errbuf               => pv_errbuf,
                    pn_result               => pn_retcode
                );

                IF pn_retcode != 0
                THEN
                    RAISE e_error;
                END IF;

                ---Mise a jour des lignes traitées---
                UPDATE dka_sarfacman_tmp dst
                SET    dr_code_combination_id = vn_dr_code_combination_id,
                       transfer_status_code = 'A'
                WHERE  dst.ROWID = events_rec.row_id;

                UPDATE ra_cust_trx_line_gl_dist_all rctlgd
                SET    rctlgd.attribute5 = TO_CHAR (Fnd_Global.conc_request_id)
                WHERE  rctlgd.cust_trx_line_gl_dist_id = events_rec.cust_trx_line_gl_dist_id;

  		          COMMIT; -- Ajout TB du 19/08/2005

                Dka_Tools_Pkg.put_log_message ('>>> OK pour');
                Dka_Tools_Pkg.put_log_message ('customer_trx_id: ' || events_rec.customer_trx_id);
                Dka_Tools_Pkg.put_log_message ('cust_trx_line_id: ' || events_rec.cust_trx_line_id);

            -- Modification du traitement des erreurs (Modif TB du 28/06/2005)
            EXCEPTION
                WHEN e_error
                 THEN

                -- Annulation des lignes de produit insérées (Modif TB du 28/06/2005)
                ROLLBACK;
                Dka_Tools_Pkg.put_log_message ('Erreur dans le traitement insert_pa_events.');

                Dka_Tools_Pkg.put_log_message ('>>> KO pour');                                        -- Ajout TB du 19/08/2005
                Dka_Tools_Pkg.put_log_message ('customer_trx_id: ' || events_rec.customer_trx_id);    -- Ajout TB du 19/08/2005
                Dka_Tools_Pkg.put_log_message ('cust_trx_line_id: ' || events_rec.cust_trx_line_id);  -- Ajout TB du 19/08/2005
 
 
                    --Rejet de la ligne courante
                    UPDATE dka_sarfacman_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.tranfer_rejection_reason = pv_errbuf
                    WHERE  dst.ROWID = events_rec.row_id;
                COMMIT;
                -- Dka_Tools_Pkg.put_log_message ('Mise a jour des lignes de la table temporaire.');
                WHEN OTHERS
                THEN

                -- Annulation des lignes de produit insérées (Modif TB du 28/06/2005)
                ROLLBACK;
                Dka_Tools_Pkg.put_log_message ('Erreur dans le traitement insert_pa_events.');

                Dka_Tools_Pkg.put_log_message ('>>> KO pour');                                        -- Ajout TB du 19/08/2005
                Dka_Tools_Pkg.put_log_message ('customer_trx_id: ' || events_rec.customer_trx_id);    -- Ajout TB du 19/08/2005
                Dka_Tools_Pkg.put_log_message ('cust_trx_line_id: ' || events_rec.cust_trx_line_id);  -- Ajout TB du 19/08/2005

                    pv_errbuf := SQLERRM;
                    pn_retcode := SQLCODE;
                    --Rejet de la ligne courante
                    UPDATE dka_sarfacman_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.tranfer_rejection_reason = pv_errbuf
                    WHERE  dst.ROWID = events_rec.row_id;
                COMMIT;
            END;

        END LOOP;

        CLOSE events_cur;
        pn_retcode    := 0;
    EXCEPTION
        WHEN OTHERS
        THEN

            IF events_cur%ISOPEN
            THEN
                CLOSE events_cur;
            END IF;

            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_pa_events;

---------------------------------------------------------------------------------------------------------------------
  --  Nom           :insert_pa_expenditures
  --  Description   :insertion des dépenses
  --
  --  PARAMETRES :
  --    vv_errbuf
  --    vn_retcode
  --  VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles : 0: deroulement correct
  --                         2: deroulement avec erreur
  ----------------------------------------------------------------------------------------------------------------

    PROCEDURE insert_pa_expenditures (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        --Déclaration du curseur sur les dépenses

        CURSOR expends_cur
        IS
            SELECT dst.ROWID row_id,
                   dst.cust_trx_line_gl_dist_id,
                   dst.customer_trx_id,
                   dst.cust_trx_line_id,
                   dst.line_type,
                   dst.gl_date,
                   dst.quantity_invoiced,
                   dst.unit_selling_price,
                   (- dst.extended_amount) extended_amount,  -- Inversion du montant pour les dépenses
                   dst.TYPE,
                   dst.NAME,
                   dst.org_id,
                   dst.trx_number,
                   dst.description,
                   dst.bill_to_customer_id,
                   dst.cr_code_combination_id,
                   dst.dr_code_combination_id,
                   dst.project_id,
                   dst.event_type,
                   dst.bill_to_project_id,
                   dst.task_id,
                   dst.last_update_date,
                   dst.last_updated_by,
                   dst.creation_date,
                   dst.created_by,
                   dst.last_update_login,
                   dst.transfer_status_code,
                   dst.tranfer_rejection_reason,
                   gcc.segment1,
                   gcc.segment2,  -- PHENIX 2004: Ajout.
                   gcc.segment6 
            FROM   dka_sarfacman_tmp dst,
                   gl_code_combinations gcc
            WHERE  gcc.code_combination_id = dst.cr_code_combination_id
              AND  dst.account_type = 'E';

        expends_rec                 expends_cur%ROWTYPE;
        vn_dr_code_combination_id   NUMBER (15);
        vn_burden_cost              NUMBER (15, 2);   -- montant des co¹ts complets
        vv_event_attr_context       pa_events.attribute_category%TYPE;
        vv_expenditure_group        pa_expenditure_groups.expenditure_group%TYPE;
        vn_cost_center_org_id       hr_all_organization_units.organization_id%TYPE;
        vn_expenditure_id           pa_expenditures_all.expenditure_id%TYPE;
        vn_expenditure_item_id      pa_expenditure_items_all.expenditure_item_id%TYPE;
        vn_task_id                  pa_tasks.task_id%TYPE;
        vv_sarfacman_seq_num        VARCHAR2 (30);
        vd_gl_date                  DATE;
        vd_pa_date                  DATE;
        
    BEGIN
        pv_errbuf              := NULL;
        pn_retcode             := 0;

        --- récupération des dépenses ---
        IF NOT expends_cur%ISOPEN
        THEN
            OPEN expends_cur;
        END IF;

        LOOP
            FETCH expends_cur INTO expends_rec;
            EXIT WHEN expends_cur%NOTFOUND;

            DECLARE
                e_error     EXCEPTION;
            BEGIN
                
                 --- Appel de la procedure qui calcule la ccid ---
                Dka_Sarfacman_Pkg.get_dr_code_combination_id (expends_rec.segment1, expends_rec.segment2, vn_dr_code_combination_id, pv_errbuf, pn_retcode);  -- PHENIX 2004: Ajout: events_rec.segment2, .

                -- Vérification du calcul de la ccid --
                IF pn_retcode != 0
                THEN
                    RAISE e_error;
                END IF;

                -- Détermination du contexte de la dépense --
                IF expends_rec.bill_to_project_id IS NOT NULL
                THEN
                    vv_event_attr_context    := gv_event_context_refac;
                ELSE
                    vv_event_attr_context    := gv_event_context_normal;
                END IF;

                -- Calcul date GL et date PA (fin de mois)
                -- MIGRATION R12 JPE artifact artf2031438
                --vd_gl_date     := LAST_DAY (expends_rec.gl_date);
                vd_gl_date     := expends_rec.gl_date;
                vd_pa_date     := vd_gl_date;
                
                -- On initialise le CC et le nO de tâche
                vn_cost_center_org_id  := get_org_id_f (pv_org_name => expends_rec.segment6);
                --vn_task_id            := get_task_id_f (pn_project_id => expends_rec.project_id);                        
                vn_task_id := expends_rec.task_id;
                
                -- Détermination des co¹ts complets
                vn_burden_cost         := get_burden_cost_f (
                                              pn_org_id                            => expends_rec.org_id,
                                              pn_task_id                           => vn_task_id,
                                              pd_ref_date                          => vd_gl_date,
                                              pv_expenditure_type                  => expends_rec.event_type,
                                              pn_expenditure_organization_id       => vn_cost_center_org_id,
                                              pn_raw_cost                          => expends_rec.extended_amount
                                       );
                                       
                -- Insertion des lignes de dépenses dans PA

                
                -- Insertion d'un enregistrement dans PA_EXPENDITURE_GROUPS
                Dka_Tools_Pkg.put_log_message ('Before Ins_Pa_Expend_Groups');
                ins_pa_expend_groups (
                    pv_company_code            => expends_rec.segment1,
                    pn_org_id                  => expends_rec.org_id,
                    pd_gl_date                 => vd_gl_date,
                    pv_expenditure_group       => vv_expenditure_group
                );
                -- Insertion d'un enregistrement dans PA_EXPENDITURES_ALL
                Dka_Tools_Pkg.put_log_message ('Before Ins_Pa_Expenditures');
                ins_pa_expenditures (
                    pv_expenditure_group                 => vv_expenditure_group,
                    pd_gl_date                           => vd_gl_date,
                    pn_expenditure_organization_id       => vn_cost_center_org_id,
                    pn_org_id                            => expends_rec.org_id,
                    pn_expenditure_id                    => vn_expenditure_id
                );
                -- Insertion d'un enregistrement dans PA_EXPENDITURE_ITEMS_ALL
                Dka_Tools_Pkg.put_log_message ('Before Ins_Pa_Expend_Items');
                ins_pa_expend_items (
                    pn_expenditure_id                    => vn_expenditure_id,
                    pv_expenditure_type                  => expends_rec.event_type,
                    pn_expenditure_organization_id       => vn_cost_center_org_id,
                    pn_project_id                        => expends_rec.project_id,
                    pn_task_id                           => vn_task_id,
                    pn_raw_cost                          => expends_rec.extended_amount,
                    pn_burden_cost                       => vn_burden_cost,
                    pn_quantity                          => expends_rec.extended_amount,
                    pn_project_id_refac                  => expends_rec.bill_to_project_id,
                    pv_orig_transaction_reference        => TO_CHAR (expends_rec.cust_trx_line_gl_dist_id), 
                    pd_gl_date                           => vd_gl_date,
                    pn_org_id                            => expends_rec.org_id,
                    pv_attribute_category                => vv_event_attr_context,
                    pv_description                       => expends_rec.description,
                    pn_expenditure_item_id               => vn_expenditure_item_id
                );
                -- Insertion d'un enregistrement dans PA_COST_DISTRIBUTION_LINES_ALL
                Dka_Tools_Pkg.put_log_message ('Before Ins_Pa_Cost_Distrib_Lines');
                ins_pa_cost_distrib_lines (
                    pn_expenditure_item_id          => vn_expenditure_item_id,
                    pn_project_id                   => expends_rec.project_id,
                    pn_task_id                      => vn_task_id,
                    pn_dr_code_combination_id       => expends_rec.cr_code_combination_id,
                    pn_cr_code_combination_id       => vn_dr_code_combination_id,
                    pn_raw_cost                     => expends_rec.extended_amount,
                    pn_burden_cost                  => vn_burden_cost,
                    pn_quantity                     => expends_rec.extended_amount,
                    pv_batch_name                   => null,
                    pd_gl_date                      => vd_gl_date,
                    pd_pa_date                      => vd_pa_date,
                    pn_org_id                       => expends_rec.org_id
                );


                IF pn_retcode != 0
                THEN
                    RAISE e_error;
                END IF;

                ---Mise a jour des lignes traitées---
                UPDATE dka_sarfacman_tmp dst
                SET    dr_code_combination_id = vn_dr_code_combination_id,
                       transfer_status_code = 'A'
                WHERE  dst.ROWID = expends_rec.row_id;

                UPDATE ra_cust_trx_line_gl_dist_all rctlgd
                SET    rctlgd.attribute5 = TO_CHAR (Fnd_Global.conc_request_id)
                WHERE  rctlgd.cust_trx_line_gl_dist_id = expends_rec.cust_trx_line_gl_dist_id;

  		          COMMIT; -- Ajout TB du 19/08/2005

                Dka_Tools_Pkg.put_log_message ('>>> OK pour');
                Dka_Tools_Pkg.put_log_message ('customer_trx_id: ' || expends_rec.customer_trx_id);
                Dka_Tools_Pkg.put_log_message ('cust_trx_line_id: ' || expends_rec.cust_trx_line_id);

            -- Modification du traitement des erreurs (Modif TB du 28/06/2005)
            EXCEPTION
                WHEN e_error
                 THEN

                -- Annulation des lignes de produit insérées (Modif TB du 28/06/2005)
                ROLLBACK;
                Dka_Tools_Pkg.put_log_message ('Erreur dans le traitement insert_pa_expenditures.');

                Dka_Tools_Pkg.put_log_message ('>>> KO pour');                                        -- Ajout TB du 19/08/2005
                Dka_Tools_Pkg.put_log_message ('customer_trx_id: ' || expends_rec.customer_trx_id);    -- Ajout TB du 19/08/2005
                Dka_Tools_Pkg.put_log_message ('cust_trx_line_id: ' || expends_rec.cust_trx_line_id);  -- Ajout TB du 19/08/2005
 
 
                    --Rejet de la ligne courante
                    UPDATE dka_sarfacman_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.tranfer_rejection_reason = pv_errbuf
                    WHERE  dst.ROWID = expends_rec.row_id;
                COMMIT;
                -- Dka_Tools_Pkg.put_log_message ('Mise a jour des lignes de la table temporaire.');
                WHEN OTHERS
                THEN

                -- Annulation des lignes de produit insérées (Modif TB du 28/06/2005)
                ROLLBACK;
                Dka_Tools_Pkg.put_log_message ('Erreur dans le traitement insert_pa_expenditures.');

                Dka_Tools_Pkg.put_log_message ('>>> KO pour');                                        -- Ajout TB du 19/08/2005
                Dka_Tools_Pkg.put_log_message ('customer_trx_id: ' || expends_rec.customer_trx_id);    -- Ajout TB du 19/08/2005
                Dka_Tools_Pkg.put_log_message ('cust_trx_line_id: ' || expends_rec.cust_trx_line_id);  -- Ajout TB du 19/08/2005

                    pv_errbuf := SQLERRM;
                    pn_retcode := SQLCODE;
                    
                    --Rejet de la ligne courante
                    UPDATE dka_sarfacman_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.tranfer_rejection_reason = pv_errbuf
                    WHERE  dst.ROWID = expends_rec.row_id;
                COMMIT;
            END;

        END LOOP;

        CLOSE expends_cur;
        pn_retcode    := 0;
        
    EXCEPTION
        WHEN OTHERS
        THEN

            IF expends_cur%ISOPEN
            THEN
                CLOSE expends_cur;
            END IF;

            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_pa_expenditures;       
-----------------------------------------------------------------------------------------------------------------------
--  Nom           : get_data_for_refaccuf
--  Description   : données pour remplir le cuf dans le cas d'une refac
--
--  PARAMETRES    :
--    pn_project_id
--    pn_tache_id
--    pn_refac_project_id
--    pn_refac_tache_id
--    Pv_Message
--    pv_errbuf
--    pn_retcode
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_data_for_refaccuf (
        pn_project_id                   IN OUT  NUMBER,
        pn_tache_id	                    IN OUT  NUMBER,
        pv_event_type                   IN      VARCHAR2,    
        pn_trx_org_id                   IN      NUMBER, --RBE      
        pb_refac                        OUT     BOOLEAN,
        pn_refac_project_id             IN OUT  NUMBER,
        pn_refac_tache_id               IN OUT  NUMBER,
        pv_concatened_segments_in       IN      VARCHAR2,
        pv_trx_type                     IN      VARCHAR2,
        pv_account_class                IN      VARCHAR2,
        pv_cuf                          IN OUT  VARCHAR2,
        pn_org_id                       OUT     NUMBER,
        Pv_Message                      OUT     VARCHAR2,
        pv_errbuf                       OUT     VARCHAR2,
        pn_retcode                      OUT     NUMBER
        )
    IS
        e_error                  EXCEPTION;
        
        vv_step               VARCHAR2 (20);
        vv_segment1           gl_code_combinations.segment1%TYPE;
        vv_segment2           gl_code_combinations.segment2%TYPE; -- CODE PROJET
        vv_segment3           gl_code_combinations.segment3%TYPE;
        
        vv_task_number        pa_tasks_v.task_number%TYPE;
                                 
	     	vn_org_id          		NUMBER;
        vv_soc_proj           gl_code_combinations.segment1%TYPE;
        vv_uo_proj            hr_operating_units.SHORT_CODE%TYPE;
        
        vv_project_name       pa_projects_all.name%TYPE;
        vv_segment_proj       gl_code_combinations.segment1%TYPE;
        vv_cuf_origine        varchar2(1000);
        vv_cuf_depart         varchar2(1000);
        vv_cuf_finale         varchar2(1000);
        vv_projet_remplace    varchar2(50);
        vv_tache_remplace     varchar2(50);
        vv_projet_a_refactuer varchar2(50);
        vv_tache_a_refactuer  varchar2(50);
        vn_cpt number;    
        vv_project_type       pa_projects_all.project_type%TYPE;
        vv_org_name           VARCHAR2(240);
        vv_account_types      VARCHAR2(1);
        
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        pb_refac      := FALSE;
        --Pv_Message := 'DEBUG JPE pn_project_id ' || pn_project_id;
        IF pn_project_id IS NOT NULL
        THEN
            vv_step := '00 - ';   
            Dka_Sarfacman_Pkg.init(pv_errbuf, pn_retcode);
            IF pn_retcode != 0
            THEN
              RAISE e_error;
            END IF;
            
            IF pv_account_class = 'REV'          
            THEN
      				--Pv_Message := 'DEBUG JPE pv_account_class ' || pv_account_class;
              vn_org_id := NULL;
      				-- JPE MIGRATION R12
      				-- On vérifie que le projet et la tache sont liés
      				BEGIN
                SELECT pp.org_id,   
                       ptv.task_number,
                       pp.project_type
                INTO vn_org_id,
                     vv_task_number,
                     vv_project_type
        				FROM pa_projects_all pp, pa_tasks ptv            
        				WHERE pp.project_id = pn_project_id
        				AND pp.project_id   = ptv.project_id
        				AND	ptv.task_id     = pn_tache_id;
      				
      				EXCEPTION
        				WHEN NO_DATA_FOUND
                THEN	
                  pn_retcode := 2;
                  pv_errbuf  := 'Erreur : Pas de lien entre la tache id : ' || pn_tache_id || ' et le projet id : ' || pn_project_id;
        					RAISE e_error;
              END;
				      
              -- On vérifie que le projet saisi n'est pas un projet de refac 
      				IF vv_project_type = gv_project_type_refac THEN
                  Pv_Message := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_E0003');
                  pn_retcode := 2;
                  pv_errbuf := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_E0003');
                  RAISE e_error;
              END IF; 
                 
		        	vv_step := '01 - ';
              BEGIN
                SELECT substr (SHORT_CODE,4,4) AS SOC,
                      SHORT_CODE
                INTO  vv_soc_proj,
                      vv_uo_proj
                FROM  hr_operating_units 
                WHERE ORGANIZATION_id = vn_org_id;
              EXCEPTION
        				WHEN NO_DATA_FOUND
                THEN	
                  pn_retcode := 2;
                  pv_errbuf  := 'Erreur : le projet ' || pn_project_id || ' n''est affecté a aucune société';
        					RAISE e_error;
              END;
             
             
                          
              vv_step := '02 - ';
              
              --RBE 
              BEGIN
                SELECT name
                INTO vv_org_name
                FROM HR_OPERATING_UNITS HOP
                WHERE  organization_id = pn_trx_org_id
                ;
              EXCEPTION
              WHEN OTHERS THEN 
                  pn_retcode := 2;
                  pv_errbuf  := 'Erreur : unité opérationnelle ' || vv_project_name || ' n''est pas trouvée';
        					RAISE e_error;
              END;
              
              vv_segment1 := SUBSTR(pv_concatened_segments_in, 1, INSTR(pv_concatened_segments_in, '.', 1, 1) - 1); --segment1                    
              vv_segment2 := SUBSTR(pv_concatened_segments_in, INSTR(pv_concatened_segments_in, '.',1,1) + 1, INSTR(pv_concatened_segments_in, '.',1,2) - INSTR(pv_concatened_segments_in, '.',1,1) - 1); --segment2                    
              vv_segment3 := SUBSTR(pv_concatened_segments_in, INSTR(pv_concatened_segments_in, '.',1,2) + 1, INSTR(pv_concatened_segments_in, '.',1,3) - INSTR(pv_concatened_segments_in, '.',1,2) - 1); --segment3                    
              
              DECLARE
                vv_errbuf              VARCHAR2(200);
                vn_retcode             NUMBER;
                vn_flex_value_set_id   fnd_flex_value_sets.flex_value_set_id%TYPE;
                vv_flex_value_set_name fnd_flex_value_sets.flex_value_set_name%TYPE;
                vv_account_type        VARCHAR2(1);
                vv_account_attribute   fnd_flex_values.attribute4%TYPE;
              
              BEGIN
              
                Dka_Tools_Pkg.get_flex_key_seg_value_set(pv_errbuf              => vv_errbuf,
                                                         pn_retcode             => vn_retcode,
                                                         pn_segment_num         => 3,
                                                         pn_flex_value_set_id   => vn_flex_value_set_id,
                                                         pv_flex_value_set_name => vv_flex_value_set_name);
              
                SELECT SUBSTR(ffv.compiled_value_attributes, 5, 1), ffv.attribute4
                  INTO vv_account_type, vv_account_attribute
                  FROM fnd_flex_values ffv
                 WHERE ffv.flex_value_set_id = vn_flex_value_set_id
                   AND ffv.flex_value = vv_segment3;
              
                vv_account_types := vv_account_type;
              
              EXCEPTION
                WHEN OTHERS THEN
                  NULL;
              END;
              
              IF vv_soc_proj != vv_segment1  THEN -- MIGRATION R12 JPE RG6 : Si les sociétés sont différentes, il y a refacturation automatique    
                IF (substr (pv_trx_type,6) != gv_type_passage_irrecouvrable) AND (substr (vv_task_number,1,2) != 'GK') AND (NVL(vv_account_types,'X') != 'E') THEN
                  pb_refac := TRUE; 
                  pn_refac_project_id        := pn_project_id;
                  pn_refac_tache_id          := pn_tache_id;
                  --vv_project_name            := vv_segment2 || vv_segment1 || '-REFAC'; -- RBE
                  vv_project_name            := vv_org_name || '-REFAC'; --RBE
                  BEGIN  
                    SELECT PROJECT_ID, SEGMENT1
                    INTO   pn_project_id, vv_segment_proj
                    FROM   pa_projects_all
                    WHERE  pa_projects_all.name = vv_project_name; 
                  EXCEPTION
          				WHEN NO_DATA_FOUND
                  THEN	
                    pn_retcode := 2;
                    pv_errbuf  := 'Erreur : le projet ' || vv_project_name || ' n''existe pas';
          					RAISE e_error;
                  END;
                  BEGIN  
                      SELECT ptv.task_id
                      INTO  pn_tache_id
                      FROM  pa_tasks ptv            
            				  WHERE ptv.project_id = pn_project_id
            				  AND	  ptv.task_number = '1';
                    EXCEPTION
            				WHEN NO_DATA_FOUND
                    THEN	
                      pn_retcode := 2;
                      pv_errbuf  := 'Erreur : la tâche "1" du projet ' || vv_project_name || ' n''existe pas';
            					RAISE e_error;
                  END;
                 	              
                  IF pv_cuf IS NOT NULL THEN   
                    -- MIGRATION R12 JPE ON MAJ LES VALEURS DU CUF                  
                  	vv_cuf_origine := pv_cuf;	
                  	vv_cuf_depart  := vv_cuf_origine;
                  	--vn_cpt := 1;
                  	
                  	WHILE INSTR(vv_cuf_depart, '..') > 0 LOOP
                  		SELECT REPLACE(vv_cuf_depart, '..', '.A_REMPLACER' || '.') INTO vv_cuf_depart FROM DUAL;
                  		--vn_cpt := vn_cpt + 1; 
                    END LOOP;
                  	
                  	vv_projet_remplace    := SUBSTR(vv_cuf_depart, 1, INSTR(vv_cuf_depart, '.') - 1);
                    vv_tache_remplace     := SUBSTR(vv_cuf_depart, INSTR(vv_cuf_depart, '.',1,1) + 1, INSTR(vv_cuf_depart, '.',1,2) - INSTR(vv_cuf_depart, '.',1,1) - 1);
                  	vv_projet_a_refactuer := SUBSTR(vv_cuf_depart, INSTR(vv_cuf_depart, '.',1,3) + 1, INSTR(vv_cuf_depart, '.',1,4) - INSTR(vv_cuf_depart, '.',1,3) - 1);
                  	vv_tache_a_refactuer  := SUBSTR(vv_cuf_depart, INSTR(vv_cuf_depart, '.',1,4) + 1, INSTR(vv_cuf_depart, '.',1,5) - INSTR(vv_cuf_depart, '.',1,4) - 1);
                  	
                  	vv_cuf_finale := vv_cuf_depart;
                  	
                  	if vv_projet_remplace is not null then	
                  		SELECT REPLACE(vv_cuf_finale, vv_projet_remplace, vv_segment_proj) INTO vv_cuf_finale FROM DUAL;
                  		SELECT REPLACE(vv_cuf_finale, vv_projet_a_refactuer, vv_projet_remplace) INTO vv_cuf_finale FROM DUAL;
                  	end if;
                  	
                  	if vv_tache_remplace is not null then	
                  		SELECT REPLACE(vv_cuf_finale, vv_tache_remplace, '1') INTO vv_cuf_finale FROM DUAL;
                  		SELECT REPLACE(vv_cuf_finale, vv_tache_a_refactuer, vv_tache_remplace) INTO vv_cuf_finale FROM DUAL;
                  	end if; 
                    
                    SELECT REPLACE(vv_cuf_finale, 'A_REMPLACER', '..') INTO vv_cuf_finale FROM DUAL;
                                   	              
                  	pv_cuf := vv_cuf_finale;
                  END IF; 	
                 /* ------------------ POUR DEBUG -------------------
                  
                  DBMS_OUTPUT.put_line('vv_projet_remplace : '   || vv_projet_remplace);
                	DBMS_OUTPUT.put_line('vv_tache_remplace : '    || vv_tache_remplace);
                	DBMS_OUTPUT.put_line('vv_projet_a_refactuer : ' || vv_projet_a_refactuer);
                	DBMS_OUTPUT.put_line('vv_tache_a_refactuer : ' || vv_tache_a_refactuer);
                	DBMS_OUTPUT.put_line('DEPART : ' || vv_cuf_origine);
                	DBMS_OUTPUT.put_line('FINALE : ' || vv_cuf_finale); */
                  
                  -- MIGRATION R12 JPE FIN MAJ LES VALEURS DU CUF                  
                	
                  
                ELSE              
                  /*Pv_Message := 'Refacturation automatique interdite sur les tâches organiques';
                  pn_retcode := 2;
                  pv_errbuf  := 'Refacturation automatique interdite sur les tâches organiques';
                  RAISE e_error; */
                  Pv_Message := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_E0005');
                  pn_retcode := 2;
                  pv_errbuf := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_E0005');
                  IF substr (pv_trx_type,6) = gv_type_passage_irrecouvrable THEN
                        Pv_Message := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_E0004');
                        pn_retcode := 2;
                        pv_errbuf := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_E0004');                         
                  END IF;
                  IF NVL(vv_account_types,'X') = 'E' THEN
                        Pv_Message := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_E0007');
                        pn_retcode := 2;
                        pv_errbuf := Dka_Tools_Pkg.get_message ('DKA', 'DKA_SARFACMAN_E0007');  
                  END IF;
                  RAISE e_error;
                END IF;
              END IF; -- MIGRATION R12 JPE FIN RG6 : Si les sociétés sont différentes, il y a refacturation automatique               
              pn_org_id := vn_org_id;                   	
            END IF;  
        END IF;    
    EXCEPTION
        WHEN e_error
        THEN
            pn_retcode := 2;
            IF Pv_Message IS NULL
            THEN
                Pv_Message := vv_step || pv_errbuf;
            END IF;
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
            IF Pv_Message IS NULL
            THEN
                Pv_Message := vv_step || pv_errbuf;
            END IF;
    END get_data_for_refaccuf;
    
------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale encha?nant l'ensemble des autres procédures
  --
  --  PARAMETRES :
  --    pv_batch_source_name        Entrée
  --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       :        code retour de validité
  --     Valeurs possibles :        0: normal, 1: warning, 2: erreur
  --
  ---------------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER,
        pv_batch_source_name   IN       VARCHAR2 DEFAULT NULL
    )
    IS
        vn_result   NUMBER;
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        --Lancement de la procedure init--
        Dka_Tools_Pkg.put_log_message ('Lancement INIT');
        Dka_Sarfacman_Pkg.init (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RETURN;
        END IF;

        --Purge de la table temporaire--
        Dka_Tools_Pkg.put_log_message ('Lancement de Purge_sarfacman_tmp');
        Dka_Sarfacman_Pkg.purge_sarfacman_tmp (pv_errbuf, pn_retcode);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RETURN;
        END IF;

        --Lancement de la procedure d'insertion dans la table temporaire--
        Dka_Tools_Pkg.put_log_message ('Lancement insert_sarfacman_tmp');
        Dka_Sarfacman_Pkg.insert_sarfacman_tmp (pv_batch_source_name, pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RETURN;
        END IF;

        --Lancement de la procedure d'insertion des évenements dans PA--
        Dka_Tools_Pkg.put_log_message ('Lancement insert_pa_events');
        Dka_Sarfacman_Pkg.insert_pa_events (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RETURN;
        END IF;

        -- Ajout TB 16/05/2006
        --Lancement de la procedure d'insertion des dépenses dans PA
        Dka_Tools_Pkg.put_log_message ('Lancement insert_pa_expenditures');
        Dka_Sarfacman_Pkg.insert_pa_expenditures (pv_errbuf, vn_result);
        
        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RETURN;
        END IF;
        
        
        --Lancement de la procedure de création du fichier de sortie
        Dka_Tools_Pkg.put_log_message ('Lancement CREATE_OUTPUT');
        Dka_Sarfacman_Pkg.create_output (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            IF vn_result = 1
            THEN
                pn_retcode    := 1;
            ELSE
                pn_retcode    := 2;
            END IF;
        RETURN;
        END IF;                         

    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := SQLERRM;
            pn_retcode    := 2;
    END main;
----------------------------------------------------------------------------------------------------------------------
END Dka_Sarfacman_Pkg;
/
SHOW ERRORS
EXIT
