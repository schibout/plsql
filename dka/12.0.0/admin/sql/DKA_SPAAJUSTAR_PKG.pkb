CREATE OR REPLACE PACKAGE BODY dka_spaajustar_pkg AS

--------------------------------------------------------------------------------------------
-- NOM           : DKA_SPAAJUSTAR_PKG.pkb
-- DESCRIPTION   : DKA_SPAAJUSTAR_PKG package body : spécifique ajustements AR->PA
---
--- AUTEUR           : Grégory VANACKERE
--- DATE DE CREATION : 04/03/2005
--- DOC. ASSOCIEE    :
---
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 2016/07/26 JJA Migration Helios R12
--- 2016/12/23 RBE Correction artf2070551
--- 2017/03/22 YWA artf2125403 ,artf2125189,artf2125414
--- 2017/04/04 YWA artf2131866
--- 2017/05/16 RBE artf2154097
-------------------------------------------------------------------------------------------------------
  
    ----- Déclaration des variables globales du package -----
    gv_currency_code                 VARCHAR2 (3);
    gv_expend_group_status_code      VARCHAR2 (50);
    gv_system_linkage_function       VARCHAR2 (30);
    gv_transaction_source            VARCHAR2 (30);
    gv_expenditure_status_code       VARCHAR2 (30);
    gv_expenditure_class_code        VARCHAR2 (30);
    gv_ar_attribute_category         VARCHAR2 (30)                                    := 'AR_AJUS'; -- Modif TB 14/06/2006
    gv_line_type                     pa_cost_distribution_lines_all.line_type%TYPE    := 'R';
    --gv_default_task_number           pa_tasks.task_number%TYPE                        := '1';
    gn_current_org_id                hr_all_organization_units.organization_id%TYPE;
    gn_user_id                       NUMBER;
    gn_request_id                    NUMBER;
    gn_last_update_login             NUMBER;
    gn_program_application_id        NUMBER;
    gn_program_id                    NUMBER;
    gn_retcode                       NUMBER;
    gv_errbuf                        VARCHAR2 (500);
    e_trt                            EXCEPTION;   -- erreur spécifique
    e_fin_normale                    EXCEPTION;
    
    --- Déclaration
    gn_seg3_flex_value_set_id        fnd_flex_value_sets.flex_value_set_id%TYPE;
    gv_seg3_flex_value_set_name      fnd_flex_value_sets.flex_value_set_name%TYPE;        

--**************************************************************************************
--  FONCTIONS ET PROCEDURES PRIVEES
--**************************************************************************************

-----------------------------------------------------------------
-- NOM         : get_param_varchar
-- DESCRIPTION : Recupere la valeur d'un parametre DKA de type VARCHAR
-----------------------------------------------------------------
    FUNCTION get_param_varchar (
        pv_parameter   IN   VARCHAR2,
        pv_prog_code   IN   VARCHAR2 DEFAULT 'SPAAJUSTAR'
    )
        RETURN VARCHAR2
    IS
        rec_param   dka_parameters%ROWTYPE;
    BEGIN
        dka_tools_pkg.get_parameter (pv_prog_code, pv_parameter, rec_param, gn_retcode, gv_errbuf);

        IF gn_retcode != 0
        THEN
            gv_errbuf    := 'DKA_SPAAJUSTAR_PKG.get_param_varchar' || '-' || pv_prog_code || '-' || pv_parameter || '-'
                            || gv_errbuf;
            RAISE e_trt;
        ELSE
            RETURN rec_param.varchar2_value;
        END IF;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPAAJUSTAR_PKG.get_param_varchar:' || SQLERRM;
            RAISE e_trt;
    END get_param_varchar;

--------------------------------------------------------------------------------------
--  Nom           : INIT
--  Description   : initialisation des parametres
----------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_prog   IN   VARCHAR2 DEFAULT NULL
    )
    IS
        rec_param   dka_parameters%ROWTYPE;
    BEGIN
        gn_retcode    := NULL;
        gv_errbuf     := NULL;

        -- On recherche l'id et le nom du jeu de valeur du segment "compte local" de la clé GL
        IF gn_seg3_flex_value_set_id IS NULL
        THEN
            dka_tools_pkg.get_flex_key_seg_value_set
                                            (
                pv_errbuf                    => gv_errbuf,
                pn_retcode                   => gn_retcode,
                pv_legal_flex_key_flag       => 'N',   -- on considere la ccf des organisations opérationnelles
                pn_segment_num               => 3,
                pn_flex_value_set_id         => gn_seg3_flex_value_set_id,
                pv_flex_value_set_name       => gv_seg3_flex_value_set_name
            );

            IF gn_retcode != 0
            THEN
                RAISE e_trt;
            END IF;
        END IF;

        IF gn_user_id IS NULL
        THEN
            gn_user_id    := fnd_global.user_id;
        END IF;

        IF gn_request_id IS NULL
        THEN
            gn_request_id    := fnd_global.conc_request_id;
        END IF;

        IF gn_last_update_login IS NULL
        THEN
            gn_last_update_login    := fnd_global.conc_login_id;
        END IF;

        IF gn_program_application_id IS NULL
        THEN
            gn_program_application_id    := fnd_global.prog_appl_id;
        END IF;

        IF gn_program_id IS NULL
        THEN
            gn_program_id    := fnd_global.conc_program_id;
        END IF;

        IF pv_prog = 'TRANSFER'
        THEN
            gv_currency_code               := get_param_varchar (pv_parameter => 'CURRENCY_CODE');
            gv_transaction_source          := get_param_varchar (pv_parameter => 'TRANSACTION_SOURCE');
            gv_expenditure_status_code     := get_param_varchar (pv_parameter => 'EXPENDITURE_STATUS_CODE');
            gv_expend_group_status_code    := get_param_varchar (pv_parameter => 'EXPENDITURE_GROUP_STATUS_CODE');
            gv_system_linkage_function     := get_param_varchar (pv_parameter => 'SYSTEM_LINKAGE_FUNCTION');
            gv_expenditure_class_code      := get_param_varchar (pv_parameter => 'EXPENDITURE_CLASS_CODE');
        END IF;
           
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFAR_PKG.Init:' || SQLERRM;
            RAISE e_trt;
    END init;

----------------------------------------------------------------------------------------
--  Fonction      : get_account_info
--  Description   : recherche des infos du du compte local (segment3) passé en parametre
----------------------------------------------------------------------------------------
    FUNCTION get_account_info (
        pv_segment3               IN       VARCHAR2,
        pn_set_id                 IN       NUMBER        
    )
        RETURN VARCHAR2
    IS
      pv_account_type VARCHAR2(15);
      
    BEGIN
        SELECT SUBSTR (ffv.compiled_value_attributes, INSTR (ffv.compiled_value_attributes, CHR (10), 3, 1) + 1, 1)               
        INTO   pv_account_type
        FROM   fnd_flex_values_vl ffv
        WHERE      ffv.flex_value = pv_segment3
               AND ffv.flex_value_set_id = pn_set_id;
               
        RETURN pv_account_type;
               
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := dka_tools_pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SPAAJUSTAR_E001',
                                pv_token1            => 'COMPTE_LOCAL',
                                pv_value1            => pv_segment3
                            );
            RAISE e_trt;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_account_info:' || SQLERRM;
            RAISE e_trt;
    END get_account_info;
        
----------------------------------------------------------------------------------------
--  Nom           :  get_contrep_ccid_f
--  Description   :  renvoie l'id de la clé GL contrepartie avec meme segment1 et segment2
----------------------------------------------------------------------------------------
    FUNCTION get_contrep_ccid_f (
        pv_segment1   IN   gl_code_combinations.segment1%TYPE,
        pv_segment2   IN   gl_code_combinations.segment2%TYPE, -- GV20050721 : adaptation PHENIX 2005
        pd_gl_date    IN   DATE
    )
        RETURN NUMBER
    IS
        vn_contrep_ccid   gl_code_combinations.code_combination_id%TYPE;
        
        vv_errbuf         VARCHAR2(500);
        vn_retcode        NUMBER;
        
    BEGIN
    
        Dka_Tools_Pkg.get_code_combination_id ( pv_segment1,
                                                pv_segment2,
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                '0',
                                                vn_contrep_ccid,
                                                vv_errbuf,
                                                vn_retcode,
                                                'Y');

        RETURN vn_contrep_ccid;
        
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPAAJUSTAR_PKG.get_contrep_ccid_f:' || SQLERRM;
            RAISE e_trt;
    END get_contrep_ccid_f;

----------------------------------------------------------------------------------------
--  Nom           :  get_org_id_f
--  Description   :  renvoie l'id de l'org dont le nom est passé en parametre
----------------------------------------------------------------------------------------
    FUNCTION get_org_id_f (
        pv_affaire   IN   VARCHAR2
    )
        RETURN NUMBER
    IS
        vn_organization_id   pa_projects_all.carrying_out_organization_id%TYPE;
    BEGIN
        SELECT ppa.carrying_out_organization_id
        INTO   vn_organization_id
        FROM   pa_projects_all ppa
        WHERE  ppa.segment1 = pv_affaire;

        RETURN vn_organization_id;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPAAJUSTAR_PKG.get_org_id_f:' || SQLERRM;
            RAISE e_trt;
    END get_org_id_f;

----------------------------------------------------------------------------------------
--  Nom           :  get_burden_cost_f
--  Description   :  renvoie le montant des couts complets
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
        IF NVL(gn_current_org_id,-1) != pn_org_id --RBE
        THEN
            fnd_profile.put ('ORG_ID', pn_org_id);
            --fnd_client_info.set_org_context (CONTEXT => pn_org_id);
            mo_global.set_policy_context('S',pn_org_id); --RBE 
            gn_current_org_id    := pn_org_id;
        END IF;

        pa_cost_plus1.view_indirect_cost (
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
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPAAJUSTAR_PKG.get_burden_cost_f:' || SQLERRM;
            RAISE e_trt;
    END get_burden_cost_f;

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
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPAAJUSTAR_PKG.Ins_Pa_Expend_Groups:' || SQLERRM;
            RAISE e_trt;
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
        pn_expenditure_id                OUT      NUMBER,
		pn_currency_code                 IN       VARCHAR2 --SNK
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
                     incurred_by_organization_id,   --number (15), -- ORG DE LA DÉPENSE
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
                     pn_currency_code,   --acct_currency_code
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
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPAAJUSTAR_PKG.Ins_Pa_Expenditures:' || SQLERRM;
            RAISE e_trt;
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
        pn_expenditure_item_id           OUT      NUMBER,
		pn_currency_code                 IN       VARCHAR2 --SNK
		
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
                     orig_transaction_reference,   -- varchar2 (30), -- N° UNIQUE !!!
                     transaction_source,   -- varchar2 (30), -- 'ORACLE GL'
                     project_id,   -- number (15),
                     task_id,   --number (15)   not null,
                     cost_distributed_flag,   --varchar2 (1)  not null, -- INDICATEUR COUT CALCULÉ
                     revenue_distributed_flag,   --varchar2 (1)  not null, -- 'n'
                     billable_flag,   --varchar2 (1)  not null, -- 'n'
                     bill_hold_flag,   --varchar2 (1)  not null, -- 'n'
                     quantity,   --number (22,5), -- QUANTITÉ
                     non_labor_resource,   --varchar2 (20),
                     organization_id,   --number (15),      -- ??
                     override_to_organization_id,   --number (15),
                     raw_cost,   --number (22,5), -- COUT DIRECT
                     raw_cost_rate,   --number (22,5), -- COUT DIRECT / QUANTITÉ
                     burden_cost,   --number (22,5), -- COUT COMPLET
                     burden_cost_rate,   --number (22,5), -- COUT COMPLET / QUANTITÉ
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
                     attribute1,   --varchar2 (150), -- cuf PROJET A REFACTURER
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
                     -- GV20050721 : adaptation PHENIX 2005
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
                     -- FIN GV20050721
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
                     pn_currency_code,   --denom_currency_code
                     pn_currency_code,   --acct_currency_code
                     pn_currency_code,   --project_currency_code
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
                     -- GV20050721 : adaptation PHENIX 2005
                     , NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, NULL, NULL,
                     NULL, NULL, NULL,
                     NULL, pn_raw_cost, pn_burden_cost, NULL, NULL,
                     NULL, NULL, pn_currency_code, NULL,
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
                     -- FIN GV20050721
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
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPAAJUSTAR_PKG.Ins_Pa_Expend_Items:' || SQLERRM;
            RAISE e_trt;
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
        pn_org_id                   IN   NUMBER,
		pn_currency_code            IN   VARCHAR2 --SNK
    )
    IS
        vv_period     gl_periods.period_name%TYPE;
        
    BEGIN
    
        SELECT distinct period_name
        INTO   vv_period
        FROM   gl_periods gp, gl_ledgers gl,gl_access_set_assignments gasa
        WHERE  pd_gl_date BETWEEN gp.start_date AND gp.end_date
        AND    gp.period_set_name = gl.period_set_name
        AND    gasa.ledger_id = gl.ledger_id
        AND    gasa.access_set_id = fnd_profile.value('GL_ACCESS_SET_ID')
        AND    gl.ledger_category_code = 'PRIMARY' --YWA artf2125189 
        ;
        
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
                     -- GV20050721 : adaptation PHENIX 2005
                     , UTIL_SUMMARIZED_FLAG, LIQUIDATE_ENCUM_FLAG, ENCUMBRANCE_BATCH_NAME,
                     ENCUMBRANCE_TYPE_ID, ENCUM_TRANSFER_REJ_REASON, BUDGET_CCID, ENCUMBRANCE_AMOUNT,
                     PROJFUNC_COST_EXCHANGE_RATE, PROJECT_RAW_COST, PROJECT_BURDENED_COST, WORK_TYPE_ID,
                     GL_PERIOD_NAME, RECVR_GL_PERIOD_NAME, PA_PERIOD_NAME, PROJFUNC_COST_RATE_TYPE,
                     PROJFUNC_COST_RATE_DATE, RECVR_PA_PERIOD_NAME, PROJFUNC_CURRENCY_CODE, SYSTEM_REFERENCE4,
                     PJI_SUMMARIZED_FLAG, ORG_LABOR_SCH_RULE_ID, COST_RATE_SCH_ID, DENOM_BURDENED_CHANGE,
                     PROJECT_BURDENED_CHANGE, PROJFUNC_BURDENED_CHANGE, ACCT_BURDENED_CHANGE, PARENT_LINE_NUM,
                     PREV_IND_COMPILED_SET_ID
                     -- FIN GV20050721
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
                     pn_currency_code,   --denom_currency_code
                     pn_currency_code,   --acct_currency_code
                     NULL,   --ind_compiled_set_id        ???
                     pd_pa_date,   --pa_date
                     pd_gl_date,   --gl_date
                     pn_project_id,   --project_id
                     pn_task_id,   --task_id
                     pn_currency_code,   --project_currency_code
                     pv_batch_name,   --batch_name
                     gv_line_type,   --line_type
                     pn_org_id,   --org_id
                     gn_request_id,   --request_id
                     gn_program_application_id,   -- program_application_id
                     gn_program_id,   -- program_id
                     SYSDATE,   -- program_update_date
                     SYSDATE,   --creation_date
                     gn_user_id   --created_by
                     -- GV20050721 : adaptation PHENIX 2005
                     , 'N', NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, pn_raw_cost, pn_burden_cost, NULL,
                     vv_period, vv_period, vv_period, NULL,
                     NULL, vv_period,pn_currency_code , NULL,
                     'N', NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL
                     -- FIN GV20050721
                    );
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPAAJUSTAR_PKG.Ins_Pa_Cost_Distrib_Lines:' || SQLERRM;
            RAISE e_trt;
    END ins_pa_cost_distrib_lines;
        
    
--------------------------------------------------------------------------------------------
--  Nom           : TRANSFER_FROM_AR_TO_PA
--  Description   : Transfert des écritures d'ajustements AR vers PA
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
PROCEDURE transfer_from_ar_to_pa (
    pv_errbuf                  IN OUT   VARCHAR2,
    pn_retcode                 IN OUT   NUMBER
)
IS
        vv_spaajustar_seq_num     VARCHAR2 (30);
        vd_gl_date                DATE;
        vd_pa_date                DATE;
        vv_company_code           VARCHAR2 (4);
        vv_description            ar_adjustments_all.comments%TYPE;
        vn_task_id                pa_tasks.task_id%TYPE;
        vn_contrep_ccid           gl_code_combinations.code_combination_id%TYPE;
        vv_expenditure_group      pa_expenditure_groups.expenditure_group%TYPE;
        vn_expenditure_id         pa_expenditures_all.expenditure_id%TYPE;
        vn_expenditure_item_id    pa_expenditure_items_all.expenditure_item_id%TYPE;
        vn_cost_center_org_id     hr_all_organization_units.organization_id%TYPE;
        vn_burden_cost            NUMBER (15, 2);   -- montant des couts complets
        vv_attribute_category     pa_expenditure_items_all.attribute_category%TYPE;
        ln_nb_ok                  NUMBER := 0;
        ln_nb_ko                  NUMBER := 0;
        vd_start_date_ar_en_cours DATE := NULL;
        vd_end_date_ar_en_cours   DATE := NULL;
		v_currency_ar             VARCHAR2 (4);
        
        CURSOR cur_ar_adjustments_all 
        IS
            SELECT   aaa.adjustment_id,
                     aaa.adjustment_number,
                     aaa.code_combination_id,
                     aaa.gl_date,
                     DECODE (art.tax_recoverable_flag,'Y',
                             aaa.line_adjusted * (-1), aaa.amount * (-1) ) raw_cost, -- montant des couts directs                     
                     DECODE (art.tax_recoverable_flag,'Y',
                             aaa.line_adjusted, aaa.amount) event_amount,    -- montant de produit
                     aaa.comments,
                     TO_NUMBER (aaa.attribute11) project_id,
                     TO_NUMBER (aaa.attribute14) task_id,
                     aaa.attribute13, -- Type dévénement ou type de dépense
                     aaa.created_from,
                     ppa.org_id org_id,
                     gcc.segment1 segment1,
                     gcc.segment2 ccid_segment2, 
                     gcc.segment3 segment3, 
                     gcc.segment5 segment5,
                     gcc.segment8 ccid_segment8, --YWA artf2125403   
                     aaa.ASSOCIATED_CASH_RECEIPT_ID --SNK					 
            FROM     ar_adjustments_all aaa,
                     ar_receivables_trx_all art,
                     pa_projects_all ppa,
                     gl_code_combinations gcc,
                     gl_access_set_assignments gasa                                                                                        
            WHERE        aaa.gl_date BETWEEN vd_start_date_ar_en_cours AND vd_end_date_ar_en_cours
                     --AND aaa.set_of_books_id = pn_set_of_books_id
                     and gasa.ledger_id = aaa.set_of_books_id
                     and gasa.access_set_id = fnd_profile.value('GL_ACCESS_SET_ID')
                     AND aaa.created_from != 'REVERSE_ADJUSTMENT'
                     AND aaa.receivables_trx_id = art.receivables_trx_id                    
                     AND art.org_id = ppa.org_id    
                     AND ppa.project_id = TO_NUMBER (aaa.attribute11)
                     --AND ppa.project_type = 'APPARTENANCE' --JJA 27/07/2016
                     AND gcc.code_combination_id = aaa.code_combination_id
                     AND get_account_info(gcc.segment3, gn_seg3_flex_value_set_id) in ('R', 'E') -- Compte de compte de charge ou de produit
                     AND aaa.attribute5 IS NULL -- Ligne non transférée
                     AND aaa.gl_posted_date IS NOT NULL -- Ligne comptabilisée dans GL
                     AND aaa.amount != 0 -- Ajustement différent de 0       
/*Ajout TB 07/07/2006*/
            UNION
            SELECT   aaa.adjustment_id,
                     aaa.adjustment_number,
                     aaa.code_combination_id,
                     aaa.gl_date,
                     DECODE (art.tax_recoverable_flag,'Y',
                             aaa.line_adjusted * (-1), aaa.amount * (-1) ) raw_cost, -- montant des couts directs
                     DECODE (art.tax_recoverable_flag,'Y',
                              aaa.line_adjusted, aaa.amount) event_amount,    -- montant de produit
                     aaa.comments,
                     TO_NUMBER (aaa.attribute11) project_id,
                     TO_NUMBER (aaa.attribute14) task_id,
                     aaa.attribute13, -- Type dévénement ou type de dépense
                     aaa.created_from,
                     ppa.org_id org_id,
                     gcc.segment1 segment1,
                     gcc.segment2 ccid_segment2,
                     gcc.segment3 segment3, 
                     gcc.segment5 segment5,
                     gcc.segment8 ccid_segment8, --YWA artf2125403 
					 aaa.ASSOCIATED_CASH_RECEIPT_ID --SNK
            FROM     ar_adjustments_all aaa,
                     ar_receivables_trx_all art,
                     pa_projects_all ppa,
                     gl_code_combinations gcc,
                     gl_access_set_assignments gasa                                                                                         
            WHERE        aaa.gl_date BETWEEN vd_start_date_ar_en_cours AND vd_end_date_ar_en_cours
                     --AND aaa.set_of_books_id = pn_set_of_books_id
                     and gasa.ledger_id = aaa.set_of_books_id
                     and gasa.access_set_id = fnd_profile.value('GL_ACCESS_SET_ID')
                     AND aaa.created_from = 'REVERSE_ADJUSTMENT'
                     AND TO_NUMBER (aaa.attribute12) = art.receivables_trx_id
                     AND art.org_id = ppa.org_id    
                     AND ppa.project_id = TO_NUMBER (aaa.attribute11)
                     --AND ppa.project_type = 'APPARTENANCE'  --JJA 27/07/2016
                     AND gcc.code_combination_id = aaa.code_combination_id
                     AND get_account_info(gcc.segment3, gn_seg3_flex_value_set_id) in ('R', 'E') -- Compte de compte de charge ou de produit
                     AND aaa.attribute5 IS NULL -- Ligne non transférée
                     AND aaa.gl_posted_date IS NOT NULL -- Ligne comptabilisée dans GL
                     AND aaa.amount != 0; -- Ajustement différent de 0  
          
            
        rec_ar_adjustments_all          cur_ar_adjustments_all%ROWTYPE;
        
    BEGIN
        --- Appel de la procédure INIT pour l'initialisation de parametres globaux
        init (pv_prog => 'TRANSFER');

        Dka_Tools_Pkg.put_outdebug_message ('<<<<<<<<<<< TRANSFER DE AR VERS PA >>>>>>>>>>>>>>>>>>>>');
        Dka_Tools_Pkg.put_log_message ('<<<<<<<<<<< TRANSFER DE AR VERS PA >>>>>>>>>>>>>>>>>>>>');
        Dka_Tools_Pkg.put_outdebug_message ('');
        Dka_Tools_Pkg.put_log_message ('');

        -- Recherche de la période AR en cours (plus petite période AR ouverte)
        SELECT distinct start_date, end_date
        INTO vd_start_date_ar_en_cours, vd_end_date_ar_en_cours
        FROM gl_period_statuses gps
        WHERE gps.application_id = 222
        AND gps.closing_status = 'O'
        AND gps.set_of_books_id in (SELECT gl.ledger_id
                                    FROM gl_access_set_assignments gasa, gl_ledgers gl  --RBE artf2154097
                                    WHERE access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID')
                                    AND gl.ledger_id = gasa.ledger_id
                                    AND gl.ledger_category_code = 'PRIMARY' --YWA artf2125189 
                                    )
        AND gps.start_date = (SELECT MIN(start_date) 
                              FROM gl_period_statuses gpsmin
                              WHERE gpsmin.application_id = gps.application_id
                              AND gpsmin.closing_status = gps.closing_status
                              AND gpsmin.set_of_books_id in (
                                                            SELECT gl.ledger_id
                                                            FROM gl_access_set_assignments gasa, gl_ledgers gl  --RBE artf2154097
                                                            WHERE access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID')
                                                            AND gl.ledger_id = gasa.ledger_id
                                                            AND gl.ledger_category_code = 'PRIMARY' --YWA artf2125189 
                                                             )
                              --AND gpsmin.set_of_books_id = gps.set_of_books_id --RBE artf2070551 
                              );
        
        Dka_Tools_Pkg.put_log_message ('vd_start_date_ar_en_cours :'||to_char(vd_start_date_ar_en_cours,'dd/mm/yyyy'));
        Dka_Tools_Pkg.put_log_message ('vd_end_date_ar_en_cours   :'||to_char(vd_end_date_ar_en_cours,'dd/mm/yyyy'));
        
        --TEST
        --vd_start_date_ar_en_cours := SYSDATE-1;
        --vd_end_date_ar_en_cours   := SYSDATE+1;
        
        Dka_Tools_Pkg.put_outdebug_message ('');
        Dka_Tools_Pkg.put_log_message ('');
        Dka_Tools_Pkg.put_outdebug_message ('   ' || RPAD ('Adjustment_id', 15) || ' ' || RPAD ('Adjustment_Number', 17) || ' ' || 'Résultat');
        Dka_Tools_Pkg.put_outdebug_message ('   ' || RPAD ('=========', 15, '=') || ' ' || RPAD ('=', 17, '=') || ' ' || RPAD ('=', 50, '='));


        -- Pour chaque ligne d'ajustement AR a traiter
        FOR rec_cur_ar_adjustments_all IN cur_ar_adjustments_all
        LOOP
            BEGIN
                -- On pose un point d'arret pour les rollbacks
                SAVEPOINT dka_spaajustar_new_line;
                
                -- On initialise le n° de séquence identifiant
                vv_spaajustar_seq_num := TO_CHAR(rec_cur_ar_adjustments_all.adjustment_id);
                                                             
                -- Dates GL et PA ramenées en fin de mois
                vd_gl_date := vd_end_date_ar_en_cours;--LAST_DAY (rec_cur_ar_adjustments_all.gl_date); --YWA artf2125414 
                dka_tools_pkg.put_debug_message ('vd_gl_date = ' || vd_gl_date);
                vd_pa_date := vd_gl_date;
                dka_tools_pkg.put_debug_message ('vd_pa_date = ' || vd_pa_date);
                
                --
                vv_company_code := rec_cur_ar_adjustments_all.segment1; -- GV20050721 : adaptation Phénix 2005
                vn_cost_center_org_id := get_org_id_f(rec_cur_ar_adjustments_all.ccid_segment8); --YWA artf2125403
                
                vn_contrep_ccid := get_contrep_ccid_f (pv_segment1 => rec_cur_ar_adjustments_all.segment1,
                                                       pv_segment2 => rec_cur_ar_adjustments_all.ccid_segment2, 
                                                       pd_gl_date  => vd_gl_date
                                                      );
                
                -- Si annulation, alors mettre en description REVERSE_ADJUSTMENT
                IF rec_cur_ar_adjustments_all.created_from = 'REVERSE_ADJUSTMENT'
                THEN
                    vv_description := rec_cur_ar_adjustments_all.created_from;
                ELSE
                    vv_description := rec_cur_ar_adjustments_all.comments;
                END IF;                                                          
                                
                -- CAS D'UNE DEPENSE PA
                IF get_account_info(rec_cur_ar_adjustments_all.segment3, gn_seg3_flex_value_set_id) = 'E'
                THEN
                    Dka_Tools_Pkg.put_log_message ('CAS D''UNE DEPENSE PA');
                    -- On recherche l'id de la tâche '1' du projet
                    vn_task_id := rec_cur_ar_adjustments_all.task_id;
                    dka_tools_pkg.put_debug_message ('vn_task_id = ' || vn_task_id);
                    
                    -- Détermination des couts complets
                    vn_burden_cost              := get_burden_cost_f (
                                                      pn_org_id                            => rec_cur_ar_adjustments_all.org_id,
                                                      pn_task_id                           => vn_task_id,
                                                      pd_ref_date                          => vd_gl_date,
                                                      pv_expenditure_type                  => rec_cur_ar_adjustments_all.attribute13,
                                                      pn_expenditure_organization_id       => vn_cost_center_org_id,
                                                      pn_raw_cost                          => rec_cur_ar_adjustments_all.raw_cost
                                                  );
                                                  
                    dka_tools_pkg.put_debug_message ('burden_cost = ' || vn_burden_cost);
                    
                    -- Insertion d'un enregistrement dans PA_EXPENDITURE_GROUPS
                    dka_tools_pkg.put_debug_message ('Before Ins_Pa_Expend_Groups');
                    ins_pa_expend_groups (
                        pv_company_code            => vv_company_code,
                        pn_org_id                  => rec_cur_ar_adjustments_all.org_id,
                        pd_gl_date                 => vd_gl_date,
                        pv_expenditure_group       => vv_expenditure_group
                    );
                    -- Insertion d'un enregistrement dans PA_EXPENDITURES_ALL
					
					--SNK
					BEGIN
					SELECT DISTINCT currency_code 
                    INTO v_currency_ar
                    FROM AR_CASH_RECEIPTS_all 
                    WHERE cash_receipt_id = rec_cur_ar_adjustments_all.ASSOCIATED_CASH_RECEIPT_ID;
					EXCEPTION                
                    WHEN NO_DATA_FOUND THEN
				     v_currency_ar := NULL;
					END; --SNK
		
                    dka_tools_pkg.put_debug_message ('Before Ins_Pa_Expenditures');
                    ins_pa_expenditures (
                        pv_expenditure_group                 => vv_expenditure_group,
                        pd_gl_date                           => vd_gl_date,
                        pn_expenditure_organization_id       => vn_cost_center_org_id,
                        pn_org_id                            => rec_cur_ar_adjustments_all.org_id,
                        pn_expenditure_id                    => vn_expenditure_id,
						pn_currency_code                     => v_currency_ar
                    );
                    -- Insertion d'un enregistrement dans PA_EXPENDITURE_ITEMS_ALL
                    dka_tools_pkg.put_debug_message ('Before Ins_Pa_Expend_Items');
                    ins_pa_expend_items (
                        pn_expenditure_id                    => vn_expenditure_id,
                        pv_expenditure_type                  => rec_cur_ar_adjustments_all.attribute13,
                        pn_expenditure_organization_id       => vn_cost_center_org_id,
                        pn_project_id                        => rec_cur_ar_adjustments_all.project_id,
                        pn_task_id                           => vn_task_id,
                        pn_raw_cost                          => rec_cur_ar_adjustments_all.raw_cost,
                        pn_burden_cost                       => vn_burden_cost,
                        pn_quantity                          => rec_cur_ar_adjustments_all.raw_cost,
                        pn_project_id_refac                  => NULL,
                        pv_orig_transaction_reference        => vv_spaajustar_seq_num,
                        pd_gl_date                           => vd_gl_date,
                        pn_org_id                            => rec_cur_ar_adjustments_all.org_id,
                        pv_attribute_category                => gv_ar_attribute_category,
                        pv_description                       => vv_description,
                        pn_expenditure_item_id               => vn_expenditure_item_id,
						pn_currency_code                     => v_currency_ar
                    );
                    -- Insertion d'un enregistrement dans PA_COST_DISTRIBUTION_LINES_ALL
                    dka_tools_pkg.put_debug_message ('Before Ins_Pa_Cost_Distrib_Lines');
                    ins_pa_cost_distrib_lines (
                        pn_expenditure_item_id          => vn_expenditure_item_id,
                        pn_project_id                   => rec_cur_ar_adjustments_all.project_id,
                        pn_task_id                      => vn_task_id,
                        pn_dr_code_combination_id       => rec_cur_ar_adjustments_all.code_combination_id,
                        pn_cr_code_combination_id       => vn_contrep_ccid,
                        pn_raw_cost                     => rec_cur_ar_adjustments_all.raw_cost,
                        pn_burden_cost                  => vn_burden_cost,
                        pn_quantity                     => rec_cur_ar_adjustments_all.raw_cost,
                        pv_batch_name                   => rec_cur_ar_adjustments_all.adjustment_id,
                        pd_gl_date                      => vd_gl_date,
                        pd_pa_date                      => vd_pa_date,
                        pn_org_id                       => rec_cur_ar_adjustments_all.org_id,
						pn_currency_code                => v_currency_ar
                    );
                    
                -- CAS D'UN EVENEMENT DE PRODUIT PA
                ELSIF get_account_info(rec_cur_ar_adjustments_all.segment3, gn_seg3_flex_value_set_id) = 'R'
                THEN
				     
				    IF NVL(gn_current_org_id,-1) != rec_cur_ar_adjustments_all.org_id --SNK 23/04/2019 EDB241
                    THEN
                        fnd_profile.put ('ORG_ID', rec_cur_ar_adjustments_all.org_id);
                        mo_global.set_policy_context('S',rec_cur_ar_adjustments_all.org_id); 
                        gn_current_org_id    := rec_cur_ar_adjustments_all.org_id; 
                    END IF; --SNK 23/04/2019 EDB241
					
                    Dka_Tools_Pkg.put_log_message ('CAS D''UN EVENEMENT DE PRODUIT PA');
                    dka_tools_pkg.put_debug_message ('Before DKA_TOOLS_PKG.pa_insert_event');
                    dka_pa_tools_pkg.pa_insert_event (
                        pn_task_id                     => rec_cur_ar_adjustments_all.task_id, --YWA artf2131866
                        pv_event_type                  => rec_cur_ar_adjustments_all.attribute13,
                        pn_amount                      => rec_cur_ar_adjustments_all.event_amount,
                        pn_project_id                  => rec_cur_ar_adjustments_all.project_id,
                        pd_completion_date             => vd_gl_date,
                        pn_group_id                    => NULL,
                        pv_insert_revenue_flag         => 'Y',
                        pv_insert_into_gl              => 'N',
                        pn_unbilled_ccid               => vn_contrep_ccid,
                        pv_batch_name                  => rec_cur_ar_adjustments_all.adjustment_id,
                        pv_description                 => vv_description,
                        pn_ccid                        => rec_cur_ar_adjustments_all.code_combination_id,
                        pv_event_attr_context          => gv_ar_attribute_category,
                        pv_event_attribute1            => NULL,
                        pv_event_attribute2            => NULL,
                        pv_event_attribute3            => NULL,
                        pv_event_attribute4            => NULL,
                        pv_event_attribute5            => vv_spaajustar_seq_num,
                        pn_event_organization_id       => vn_cost_center_org_id,
                        pn_org_id                      => rec_cur_ar_adjustments_all.org_id,
                        pv_errbuf                      => gv_errbuf,
                        pn_result                      => gn_retcode
                    );

                    IF gn_retcode != 0
                    THEN
                        gv_errbuf    := 'DKA_TOOLS_PKG.pa_insert_event:' || gv_errbuf;
                        RAISE e_trt;
                    END IF;
                END IF;

                -- On met a jour la ligne AR pour signifier qu'elle a été traitée
                dka_tools_pkg.put_debug_message ('Before UPDATE  ar_adjustments_all');

                UPDATE ar_adjustments_all aaa
                SET aaa.attribute5 = TO_CHAR(SYSDATE, 'YYYYMMDD'),
                    aaa.last_update_date = SYSDATE,
                    aaa.last_updated_by = gn_user_id
                WHERE aaa.adjustment_id = rec_cur_ar_adjustments_all.adjustment_id;                     

                -- Affichage message + incrémentation du nbre de lignes traitées avec succes
                Dka_Tools_Pkg.put_outdebug_message (
                       '++  '
                    || RPAD (SUBSTR (rec_cur_ar_adjustments_all.adjustment_id, 1, 15), 15)
                    || ' '
                    || RPAD (rec_cur_ar_adjustments_all.adjustment_number, 7)
                    || '            '
                    || 'OK'
                );
                ln_nb_ok                                  := ln_nb_ok + 1;
                dka_tools_pkg.put_debug_message ('End of Loop');
            EXCEPTION                
                WHEN e_trt
                THEN
                    ROLLBACK TO SAVEPOINT dka_spaajustar_new_line;
                    ln_nb_ko     := ln_nb_ko + 1;
                    gv_errbuf    :=    '--  '
                                    || RPAD (SUBSTR (rec_cur_ar_adjustments_all.adjustment_id, 1, 15), 15)
                                    || ' '
                                    || RPAD (rec_cur_ar_adjustments_all.adjustment_number, 7)
                                    || '           '
                                    || 'ERROR -> '
                                    || gv_errbuf;
                    Dka_Tools_Pkg.put_log_message (gv_errbuf);
                    Dka_Tools_Pkg.put_outdebug_message (gv_errbuf);
                WHEN OTHERS
                THEN
                    ROLLBACK TO SAVEPOINT dka_spaajustar_new_line;
                    gv_errbuf    := 'DKA_SPAAJUSTAR_PKG.transfer_from_ar_to_pa loop:' || SQLERRM;
                    gv_errbuf    :=    '--  '
                                    || RPAD (SUBSTR (rec_cur_ar_adjustments_all.adjustment_id, 1, 15), 15)
                                    || ' '
                                    || RPAD (rec_cur_ar_adjustments_all.adjustment_number, 7)
                                    || '           '
                                    || 'ERROR -> '
                                    || gv_errbuf;
                    Dka_Tools_Pkg.put_log_message (gv_errbuf);
                    Dka_Tools_Pkg.put_outdebug_message (gv_errbuf);
                    ln_nb_ko     := ln_nb_ko + 1;
            END;   -- -- Pour chaque ligne AR a traiter
        END LOOP;   -- -- Pour chaque ligne AR a traiter

        -- Fin normale
        COMMIT;

        IF ln_nb_ko != 0
        THEN
            pn_retcode    := 1;   -- Warning
        ELSE
            pn_retcode    := 0;   -- Succes
        END IF;

        pv_errbuf    := NULL;
        Dka_Tools_Pkg.put_outdebug_message ('');
        Dka_Tools_Pkg.put_outdebug_message ('Nombre de lignes AR traitées avec SUCCES :' || ln_nb_ok);
        Dka_Tools_Pkg.put_outdebug_message ('Nombre de lignes AR en ECHEC             :' || ln_nb_ko);
        Dka_Tools_Pkg.put_log_message ('');
        Dka_Tools_Pkg.put_log_message ('Nombre de lignes AR traitées avec SUCCES :' || ln_nb_ok);
        Dka_Tools_Pkg.put_log_message ('Nombre de lignes AR en ECHEC             :' || ln_nb_ko);
    EXCEPTION
        WHEN e_fin_normale
        THEN
            pn_retcode    := 1;
            pv_errbuf     := NULL;
        WHEN e_trt
        THEN
            ROLLBACK;
            pn_retcode    := gn_retcode;
            pv_errbuf     := gv_errbuf;
        WHEN OTHERS
        THEN
            ROLLBACK;
            pn_retcode    := SQLCODE;
            pv_errbuf     := 'DKA_SPAAJUSTAR_PKG.transfer_from_ar_to_pa' || SQLERRM;
    END transfer_from_ar_to_pa;
END dka_spaajustar_pkg;   -- Package body
/
SHOW ERRORS
EXIT
