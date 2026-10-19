CREATE OR REPLACE PACKAGE BODY APPS.DKA_SARREFAC_PKG
AS
--------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SARREFAC_PKG.pkb
-- DESCRIPTION       : DKA_SARREFAC_PKG package body :
---
--- AUTEUR           : Xavier Descamps (CGEY)
--- DATE DE CREATION : 03/12/2001
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 2016/09/26 JJA Portage Helios R12
--- 2017/01/31 RBE artf2082348 et artf2082357
--- 2017/02/06 YWA artf2093206
--- 2017/02/13 RBE artf2098415
--- 2017/03/02 YWA artf2108946
--- 2017/05/12 RBE artf2154096
--- 2017/05/30 YWA artf2159826 : SPE022 - Paramètre de détermination du site fournisseur à refacturer
--- 2017/08/29 OBE artf2216086 : SPE022 ¿ Lignes d¿origine GL non prises en compte dans la REFAC ¿ Defect BeB #1061
--- 2017/09/12 OBE artf2222202 : SPE022 - Anomalie sur le nbre de lignes à MAJ pour la recherche du fournisseur - Defect # 942
--- 2018/03/13 JJA artf2420580 : SPE022 - Edition des duplicatas (vide)
--- 2018/04/30 JJA artf2572923 : INC0213453 - Edition de refacturation incomplète (Détails manquants)
---                on lance le traitement run_all_invoice_printing de façon autonome
--- 2018/09/17 OBE artf3030545 : INC0227726 : Correctif sur le spécifique de REFAC - Cration des factures dans AR
--- 2023/09/14 BNZ EDB369 : La date de la REFACTURATION cohérente avec la date de génération de la pièce 
--- 2024/10/03 SHA EDB380 : Evolution sur le traitement de REFACTURATION (Date GL et CUF)
--------------------------------------------------------------------------------------------

    /*
    DEFINITION DES CUFS
    Ap_Invoice_Distributions_All    1: To_Project_Id (Projet a refacturer)

    Hr_All_Organization_Units       4: Société acceptant la Refac (Y/N)

    Pa_Expenditure_Items_All :      1: To_Project_Id (Projet a refacturer)
                                    2: Id du segment1 a refacturer
                                    3: Traité par la Refac : Id du traitement

    Pa_Events :                     1: To_Project_Id (Projet a refacturer)
                                    2: Id du segment1 (Couple CdG/Soc) a refacturer
                                    3: Traité par la Refac : Id du traitement

    Ra_Customer_Trx_Lines_All :     1: Project_Id
                                    2: Type d'évenement
                                   13: Num ligne de la facture AP
                                   14: Orig_Txn_Type (EXPENDITURE ou EVENT)
                                   15: Orig_Txn_Id (expenditure_item_id ou event_id)
    */

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -- Constantes
    cv_program_code                CONSTANT dka_parameters.program_code%TYPE                    := 'SARREFAC';
    cv_separator                   CONSTANT VARCHAR2 (5)                                        := '/';
    cn_number_of_copies            CONSTANT NUMBER (15)                                         := 0;

    -- Variables Globales
    gn_ap_term_id                  ap_terms.term_id%TYPE;
    gn_ar_term_id                  ra_terms.term_id%TYPE;
    gn_conc_request_id             fnd_concurrent_requests.request_id%TYPE;
    gn_login_id                    fnd_logins.login_id%TYPE;
    gn_resp_application_id         fnd_application.application_id%TYPE;
    gn_responsibility_id           fnd_responsibility.responsibility_id%TYPE;
    gn_seg4_flex_value_set_id      fnd_flex_value_sets.flex_value_set_id%TYPE;
    gv_tax_code_coll               zx_rates_vl.tax_rate_code%TYPE;
    gn_tax_rate_coll               zx_rates_vl.percentage_rate%TYPE;
    gv_tax_code_ded                zx_rates_vl.tax_rate_code%TYPE;
    gn_tax_rate_ded                zx_rates_vl.percentage_rate%TYPE;
    gn_tax_rate_id_coll            zx_rates_vl.tax_rate_id%TYPE;
    gn_tax_rate_id_ded             zx_rates_vl.tax_rate_id%TYPE;
    gv_tax_status_code_coll        zx_rates_vl.tax_status_code%TYPE;
    gv_tax_status_code_ded         zx_rates_vl.tax_status_code%TYPE;
    gv_tax_regime_code             zx_rates_vl.tax_regime_code%TYPE;
    gv_tax_jurisdiction_code       zx_rates_vl.tax_jurisdiction_code%TYPE;
    gv_tax                         zx_rates_vl.tax%TYPE;
    gn_user_id                     fnd_user.user_id%TYPE;
    gv_ap_doc_category_code        fnd_doc_sequence_categories.code%TYPE;
    gv_ap_invoice_type             ap_invoices_all.invoice_type_lookup_code%TYPE;
    gv_ap_line_type_line           ap_invoice_distributions.line_type_lookup_code%TYPE;
    gv_ap_line_type_tax            ap_invoice_distributions.line_type_lookup_code%TYPE;
    gv_ap_responsibility_key       fnd_responsibility.responsibility_key%TYPE;
    gv_ap_source                   ap_invoices_interface.SOURCE%TYPE;
    gv_ap_tax_segment3             fnd_flex_values.flex_value%TYPE;
    gv_ap_tax_type                 ap_tax_codes_all.tax_type%TYPE;
    gv_ap_term                     ap_terms_vl.NAME%TYPE;
    gv_appendix_print_style        fnd_printer_styles.printer_style_name%TYPE;
    gv_ar_batch_source             ra_batch_sources_all.NAME%TYPE;
    gv_ar_cust_trx_type            ra_cust_trx_types_all.NAME%TYPE;
    gv_ar_cust_trx_type_cm         ra_cust_trx_types_all.NAME%TYPE;
    gv_ar_function_code            pa_function_transactions.function_code%TYPE;
    gv_ar_function_transaction     pa_function_transactions.function_transaction_code%TYPE;
    gv_ar_interface_line_context   ra_interface_lines_all.interface_line_context%TYPE;
    gv_ar_line_type_line           ra_interface_lines_all.line_type%TYPE;
    gv_ar_line_type_tax            ra_interface_lines_all.line_type%TYPE;
    gv_ar_responsibility_key       fnd_responsibility.responsibility_key%TYPE;
    gv_ar_tax_segment3             fnd_flex_values.flex_value%TYPE;
    gv_ar_tax_type                 ar_vat_tax_all_b.tax_type%TYPE;
    gv_ar_term                     ra_terms_vl.NAME%TYPE;
    gv_conversion_type             gl_daily_conversion_types.conversion_type%TYPE;
    gv_default_description         ra_customer_trx_lines_all.description%TYPE;
    gv_event_source                dka_parameters.varchar2_value%TYPE;
    gv_expenditure_source          dka_parameters.varchar2_value%TYPE;
    gv_global_attribute_category   fnd_descr_flex_contexts.descriptive_flex_context_code%TYPE;
    gv_invoice_print_style         fnd_printer_styles.printer_style_name%TYPE;
    gv_pa_context_ap_refac         pa_expenditure_items_all.attribute_category%TYPE;
    gv_project_type_refac          pa_project_types_all.project_type%TYPE;
    gv_seg4_flex_value_set_name    fnd_flex_value_sets.flex_value_set_name%TYPE;
    gv_trx_number_beginning        dka_parameters.varchar2_value%TYPE;

    CV_SUFFIXE_PAY_GROUP_LC        VARCHAR2 (50) := 'GROUPE';
    -- Curseurs


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-------------------------------------------------------------------------------------------------------------------
--  Nom           : IS_TRANSACTION_TYPE_REFAC
--  Description   : Fonction qui vérifie si le type de mouvement est soumis a la Refac
--
--  PARAMETRES    :
--      pv_transaction_type     VARCHAR2
--  VALEUR RETOURNEE :
--     Description       : soumis a la Refac
--     Valeurs possibles : TRUE : soumis a la Refac
--                         FALSE: non soumis a la Refac
-------------------------------------------------------------------------------------------------------------------
    FUNCTION is_transaction_type_refac (
        pv_transaction_type   IN   VARCHAR2
    )
        RETURN BOOLEAN
    IS
        vn_count    NUMBER (22);
        vb_result   BOOLEAN;
    BEGIN
        SELECT COUNT (1)
        INTO   vn_count
        FROM   dka_sarrefac_param dsp
        WHERE  dsp.orig_transaction_type = pv_transaction_type;

        RETURN vn_count > 0;

    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END is_transaction_type_refac;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_SELECT_RECORD_GROUP
--  Description   : Récupération de requete pour lov dans forms
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pv_item                 IN      VARCHAR2
--      pv_select               OUT     VARCHAR2
--  VALEUR RETOURNEE :
--     Description       : Ordre Select
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_select_record_group (
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pv_item      IN       VARCHAR2,
        pv_select    OUT      VARCHAR2
    )
    IS
    BEGIN
        IF UPPER (pv_item) = 'LINE_SUM_FOLDER.EXPENDITURE_TYPE'
        THEN
            pv_select    :=
                       ''
                    -- Projet avec controle des mouvements au niveau tache
                    || 'SELECT DISTINCT petev.expenditure_type,'
                    || ' petev.description,'
                    || ' petev.unit_of_measure,'
                    || ' petev.cost_rate_flag,'
                    || ' petev.system_linkage_m,'
                    || ' petev.system_linkage_function'
                    || ' FROM pa_transaction_controls ptc,'
                    || ' pa_tasks pt,'
                    || ' pa_expenditure_types_expend_v petev'
                    || ' WHERE pt.project_id = :LINE_SUM_FOLDER.PROJECT_ID'
                    || ' AND pt.task_id = :LINE_SUM_FOLDER.TASK_ID'
                    || ' AND pt.limit_to_txn_controls_flag = ''Y'''
                    || ' AND ptc.project_id = :LINE_SUM_FOLDER.PROJECT_ID'
                    || ' AND ptc.task_id = :LINE_SUM_FOLDER.TASK_ID'
                    || ' AND petev.expenditure_type = ptc.expenditure_type'
                    || ' AND petev.system_linkage_function = DECODE(:INV_SUM_FOLDER.INVOICE_TYPE_LOOKUP_CODE, ''EXPENSE REPORT'', ''ER'', ''VI'')'
                    || ' AND SYSDATE BETWEEN petev.expnd_typ_start_date_active AND NVL(petev.expnd_typ_end_date_active, SYSDATE)'
                    || ' AND SYSDATE BETWEEN petev.sys_link_start_date_active AND NVL(petev.sys_link_end_date_active, SYSDATE)'
                    || ' UNION ALL '
                    -- Projet sans controle des mouvements au niveau tache, avec controle des mouvements au niveau projet
                    || 'SELECT DISTINCT petev.expenditure_type,'
                    || ' petev.description,'
                    || ' petev.unit_of_measure,'
                    || ' petev.cost_rate_flag,'
                    || ' petev.system_linkage_m,'
                    || ' petev.system_linkage_function'
                    || ' FROM pa_transaction_controls ptc,'
                    || ' pa_projects_all pp,'
                    || ' pa_tasks pt,'
                    || ' pa_expenditure_types_expend_v petev'
                    || ' WHERE pp.project_id = :LINE_SUM_FOLDER.PROJECT_ID'
                    || ' AND pp.limit_to_txn_controls_flag = ''Y'''
                    || ' AND pt.project_id = :LINE_SUM_FOLDER.PROJECT_ID'
                    || ' AND pt.task_id = :LINE_SUM_FOLDER.TASK_ID'
                    || ' AND pt.limit_to_txn_controls_flag = ''N'''
                    || ' AND ptc.project_id = :LINE_SUM_FOLDER.PROJECT_ID'
                    || ' AND NVL(ptc.task_id, 0) = 0'
                    || ' AND petev.expenditure_type = ptc.expenditure_type'
                    || ' AND petev.system_linkage_function = DECODE(:INV_SUM_FOLDER.INVOICE_TYPE_LOOKUP_CODE, ''EXPENSE REPORT'', ''ER'', ''VI'')'
                    || ' AND SYSDATE BETWEEN petev.expnd_typ_start_date_active AND NVL(petev.expnd_typ_end_date_active, SYSDATE)'
                    || ' AND SYSDATE BETWEEN petev.sys_link_start_date_active AND NVL(petev.sys_link_end_date_active, SYSDATE)'
                    || ' UNION ALL '
                    -- Projet sans controle des mouvements au niveau tache, sans controle des mouvements au niveau projet
                    || 'SELECT petev.expenditure_type,'
                    || ' petev.description,'
                    || ' petev.unit_of_measure,'
                    || ' petev.cost_rate_flag,'
                    || ' petev.system_linkage_m,'
                    || ' petev.system_linkage_function'
                    || ' FROM pa_projects_all pp,'
                    || ' pa_tasks pt,'
                    || ' pa_expenditure_types_expend_v petev'
                    || ' WHERE pp.project_id = :LINE_SUM_FOLDER.PROJECT_ID'
                    || ' AND pp.limit_to_txn_controls_flag = ''N'''
                    || ' AND pt.project_id = pp.project_id'
                    || ' AND pt.task_id = :LINE_SUM_FOLDER.TASK_ID'
                    || ' AND pt.limit_to_txn_controls_flag = ''N'''
                    || ' AND petev.system_linkage_function = DECODE(:INV_SUM_FOLDER.INVOICE_TYPE_LOOKUP_CODE, ''EXPENSE REPORT'', ''ER'', ''VI'')'
                    || ' AND SYSDATE BETWEEN petev.expnd_typ_start_date_active AND NVL(petev.expnd_typ_end_date_active, SYSDATE)'
                    || ' AND SYSDATE BETWEEN petev.sys_link_start_date_active AND NVL(petev.sys_link_end_date_active, SYSDATE)'
                    || ' ORDER BY expenditure_type';
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END get_select_record_group;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHECK_AP_INVOICE
--  Description   : Vérification des lignes d'une facture suite au rapprochement avec une commande
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_invoice_id           IN      NUMBER
--      pv_message              OUT     VARCHAR2
--  VALEUR RETOURNEE :
--     Description       : Message
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE check_ap_invoice (
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER,
        pn_invoice_id   IN       VARCHAR2,
        Pv_Message      OUT      VARCHAR2
    )
    IS
        CURSOR cur
        IS
            SELECT aid.distribution_line_number
            FROM   ap_invoice_distributions_all aid,
                   gl_code_combinations gcc
            WHERE      aid.invoice_id = pn_invoice_id
                   AND gcc.code_combination_id = aid.dist_code_combination_id
                   AND gcc.segment1  = 'XXXX'
                   AND gcc.segment2  = 'XXX'
                   AND gcc.segment3  = 'ERREUR'
                   AND gcc.segment4  = '0'
                   AND gcc.segment5  = '0'
                   AND gcc.segment6  = '0'
                   AND gcc.segment7  = '0'
                   AND gcc.segment8  = '0'
                   AND gcc.segment9  = '0'
                   AND gcc.segment10 = '0'
                   AND gcc.segment11 = '0'
                   AND gcc.segment12 = '0';
    BEGIN
        pn_retcode   := 0;

        FOR rec IN cur
        LOOP
            pn_retcode   := pn_retcode + 1;

            IF pn_retcode = 1
            THEN
                Pv_Message   := TO_CHAR (rec.distribution_line_number);
            ELSE
                Pv_Message   :=    Pv_Message
                                || ', '
                                || TO_CHAR (rec.distribution_line_number);
            END IF;
        END LOOP;

        IF pn_retcode > 0
        THEN
            Pv_Message   :=    'Erreur de rapprochement pour les lignes de ventilation n° '
                            || Pv_Message
                            || '.'
                            || CHR (10)
                            || 'Veuillez corriger le projet et/ou le type de dépense pour ces lignes.';
        END IF;

    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END check_ap_invoice;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_CHECK_TRANSACTION_DATA
--  Description   : Vérification de cohérence des données saisies sur projet
--
--  PARAMETRES    :
--    pv_errbuf           varchar2
--    pn_retcode          number
--    pn_project_id       number
--    pv_segment1         varchar2
--    pv_expenditure_type varchar2
--    pv_event_type       varchar2
--    pd_date             date
--    pv_refac            varchar2
--
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_transaction_data (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_project_id         IN       NUMBER DEFAULT NULL,
        pn_tache_id           IN       NUMBER DEFAULT NULL,
        pv_expenditure_type   IN       VARCHAR2 DEFAULT NULL,
        pb_no_test_type_evt   IN       BOOLEAN  DEFAULT FALSE,
        pv_event_type         IN       VARCHAR2 DEFAULT NULL,
        pd_date               IN       DATE,
        pv_refac              IN       VARCHAR2 DEFAULT 'N'
    )IS
        e_error                     EXCEPTION;
        e_check_ko                  EXCEPTION;
        vn_project_id               pa_projects_all.project_id%TYPE;
        vn_task_id                  pa_tasks.task_id%TYPE;
        vv_project_type             pa_projects_all.project_type%TYPE;
        vv_project_name             pa_projects_all.NAME%TYPE;
        vv_project_org_attribute4   hr_all_organization_units.attribute4%TYPE;

        vv_dummy        VARCHAR2(10);

    BEGIN
        pn_retcode    := 0;
        vv_dummy := NULL;

        -- Controle des parametres d'entrée
        IF   pn_project_id IS NULL
        THEN
            pv_errbuf    := 'Aucun projet en entrée';
            --pv_errbuf    := pv_errbuf || ' DEBUG JPE - ' || pn_retcode || ' - ' || pn_project_id || ' - ' || pn_tache_id || ' - ' || pv_expenditure_type || ' - ' || pv_event_type;
            RAISE e_error;
        END IF;

        IF  pn_tache_id IS NULL
        THEN
            pv_errbuf    := 'Aucun tâche en entrée';
            RAISE e_error;
        END IF;

        IF      pv_expenditure_type IS NULL
            AND pv_event_type IS NULL
        THEN
            pv_errbuf    := 'Aucun type de mouvement en entrée';
            RAISE e_error;
        END IF;

        IF      pv_expenditure_type IS NOT NULL
            AND pv_event_type IS NOT NULL
        THEN
            pv_errbuf    := 'Trop de types de mouvement en entrée';
            RAISE e_error;
        END IF;

        IF pd_date IS NULL
        THEN
            pv_errbuf    := 'Aucune date en entrée';
            RAISE e_error;
        END IF;

        -- Récupération de l'identifiant du projet
        BEGIN
              SELECT pt.project_id,
                     pt.task_id,
                     pp.project_type,
                     pp.name,
                     hou.attribute4
              INTO   vn_project_id,
                     vn_task_id,
                     vv_project_type,
                     vv_project_name,
                     vv_project_org_attribute4
              FROM   pa_tasks pt, pa_projects_all pp,hr_all_organization_units hou
              WHERE  pt.project_id = pn_project_id
              AND    pt.task_id = pn_tache_id
              AND    pt.project_id = pp.project_id
              AND    pp.org_id =  hou.organization_id;

        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                pv_errbuf := 'Le couple projet ' || pn_project_id || ' / tâche ' || pn_tache_id || ' n''existe pas';
                RAISE e_error;
        END;

        -- Vérification que le type de mouvement est refacturable
        IF pv_refac = 'Y'
        THEN
            IF pv_expenditure_type IS NOT NULL
            THEN
                IF NOT Dka_Sarrefac_Pkg.is_transaction_type_refac (pv_expenditure_type)
                THEN
                    pv_errbuf    := 'Le type de dépense ' || pv_expenditure_type || ' n''est pas refacturable';
                    RAISE e_check_ko;
                END IF;
            ELSE
                IF NOT Dka_Sarrefac_Pkg.is_transaction_type_refac (pv_event_type)
                THEN
                    pv_errbuf    := 'Le type d''évenement ' || pv_event_type || ' n''est pas refacturable';
                    RAISE e_check_ko;
                END IF;
            END IF;

            IF     vv_project_type != 'REFAC'
               AND pv_expenditure_type IS NOT NULL
            THEN
                -- On vérifie que le type de dépense qui sera refacturé est autorisé sur le projet final
                DECLARE
                    vv_new_expenditure_type   pa_expenditure_types.expenditure_type%TYPE;
                    vn_count                  NUMBER (15);
                BEGIN
                    -- Récupération du type de dépense
                    SELECT dsp.ap_expenditure_type
                    INTO   vv_new_expenditure_type
                    FROM   dka_sarrefac_param dsp
                    WHERE  dsp.orig_transaction_type = pv_expenditure_type;

                    -- Vérification de l'autorisation
                    SELECT COUNT (1)
                    INTO   vn_count
                    FROM   DUAL
                    WHERE  vv_new_expenditure_type IN
                                   ( -- Projet avec controle des mouvements au niveau tache
                                    SELECT petev.expenditure_type
                                    FROM   pa_transaction_controls ptc,
                                           pa_tasks pt,
                                           pa_expenditure_types_expend_v petev
                                    WHERE      pt.project_id = vn_project_id
                                           AND pt.limit_to_txn_controls_flag = 'Y'
                                           AND ptc.project_id = vn_project_id
                                           AND ptc.task_id = pt.task_id
                                           AND petev.expenditure_type = ptc.expenditure_type
                                           AND pd_date BETWEEN petev.expnd_typ_start_date_active
                                                           AND NVL (petev.expnd_typ_end_date_active, pd_date)
                                           AND pd_date BETWEEN petev.sys_link_start_date_active
                                                           AND NVL (petev.sys_link_end_date_active, pd_date)
                                    UNION ALL
                                    -- Projet sans controle des mouvements au niveau tache, avec controle des mouvements au niveau projet
                                    SELECT petev.expenditure_type
                                    FROM   pa_transaction_controls ptc,
                                           pa_projects_all pp,
                                           pa_tasks pt,
                                           pa_expenditure_types_expend_v petev
                                    WHERE      pp.project_id = vn_project_id
                                           AND pp.limit_to_txn_controls_flag = 'Y'
                                           AND pt.project_id = vn_project_id
                                           AND pt.limit_to_txn_controls_flag = 'N'
                                           AND ptc.project_id = vn_project_id
                                           AND NVL (ptc.task_id, 0) = 0
                                           AND petev.expenditure_type = ptc.expenditure_type
                                           AND pd_date BETWEEN petev.expnd_typ_start_date_active
                                                           AND NVL (petev.expnd_typ_end_date_active, pd_date)
                                           AND pd_date BETWEEN petev.sys_link_start_date_active
                                                           AND NVL (petev.sys_link_end_date_active, pd_date)
                                    UNION ALL
                                    -- Projet sans controle des mouvements au niveau tache, sans controle des mouvements au niveau projet
                                    SELECT petev.expenditure_type
                                    FROM   pa_projects_all pp,
                                           pa_tasks pt,
                                           pa_expenditure_types_expend_v petev
                                    WHERE      pp.project_id = vn_project_id
                                           AND pp.limit_to_txn_controls_flag = 'N'
                                           AND pt.project_id = pp.project_id
                                           AND pt.limit_to_txn_controls_flag = 'N'
                                           AND pd_date BETWEEN petev.expnd_typ_start_date_active
                                                           AND NVL (petev.expnd_typ_end_date_active, pd_date)
                                           AND pd_date BETWEEN petev.sys_link_start_date_active
                                                           AND NVL (petev.sys_link_end_date_active, pd_date));

                    IF vn_count = 0
                    THEN
                        pv_errbuf    :=    'Le type de dépense de Refacturation '
                                        || vv_new_expenditure_type
                                        || ' n''est pas autorisé sur le projet a refacturer '
                                        || vv_project_name
                                        || '.'
                                        || CHR (10)
                                        || 'Remettez la valeur initiale du type de dépense ou du projet a refacturer que vous avez modifié.';
                        RAISE e_check_ko;
                    END IF;

                    -- Ajout du contrôle si type de dépense refacturé existe dans le jeu de
                    --  code express => Appel de DKA_SPAAUTOACCOUTING_PKG.RUN_CPT_GROUPE_COUTS_F
                    vv_dummy := Dka_Spaautoaccounting_Pkg.run_cpt_groupe_couts_f (
                        pn_project_id       => nvl(pn_project_id,vn_project_id),
                        pv_expenditure_type => vv_new_expenditure_type,
                        pn_task_id          => pn_tache_id);

                    IF vv_dummy IS NULL
                    THEN
                        pv_errbuf := 'Le type de dépense de refacturation '
                                     || vv_new_expenditure_type
                                     || ' n''est pas autorisé en saisie sur ce type de projet'
                                     || CHR (10)
                                     || 'Vérifiez le jeu de code express associé';
                        RAISE e_check_ko;
                    END IF;

                    -- Vérification que le type de dépense est autorisé en saisie
                    --
                    SELECT COUNT(1)
                    INTO vn_count
                    FROM pa_expend_typ_sys_links
                    WHERE expenditure_type = vv_new_expenditure_type
                    AND system_linkage_function = 'VI'
                    AND NVL(end_date_active, TRUNC(SYSDATE)) >= TRUNC(SYSDATE);

                    IF vn_count = 0
                    THEN
                        pv_errbuf := 'Le type de dépense de refacturation ' || vv_new_expenditure_type || ' n''est pas autorisé en saisie fournisseur';
                        RAISE e_check_ko;
                    END IF;

                END;
            END IF;

            -- On vérifie que la société du projet final accepte la refac
            IF     vv_project_type != 'REFAC'
               AND vv_project_org_attribute4 = 'N'
            THEN
                pv_errbuf   :=    'La société du projet a refacturer ('
                               || vv_project_name
                               || ') n''accepte pas la refac';
                RAISE e_check_ko;
            END IF;

            -- Ajout du contrôle si type d'événement refacturé existe dans le jeu
            -- de code express
            IF     vv_project_type != 'REFAC'
               AND pv_event_type IS NOT NULL
            THEN
                DECLARE
                    vv_new_event_type   pa_event_types.event_type%TYPE;
                    vn_count            NUMBER(15);
                BEGIN
                    -- Récupération du type d'événement
                    SELECT dsp.ar_event_type
                    INTO   vv_new_event_type
                    FROM   dka_sarrefac_param dsp
                    WHERE  dsp.orig_transaction_type = pv_event_type;

                    -- Vérification de l'autorisation
                    vv_dummy := Dka_Spaautoaccounting_Pkg.run_cpt_groupe_produit_f (
                        pn_project_id => NVL(pn_project_id, vn_project_id),
                        pv_event_type => vv_new_event_type,
                        pn_task_id    => pn_tache_id);

                    IF vv_dummy IS NULL
                    THEN
                        pv_errbuf := 'Le type d''événement de refacturation '
                               || vv_new_event_type
                               || ' n''est pas autorisé en saisie sur ce type de projet';
                        RAISE e_check_ko;
                    END IF;
                END;
            END IF;

        END IF;

        -- Vérification que le type de dépense est autorisé dans le contrôle des mouvements
        IF (pv_expenditure_type IS NOT NULL) AND (NOT pb_no_test_type_evt)
        THEN
            DECLARE
                vn_count   NUMBER (15);
            BEGIN
                SELECT COUNT (1)
                INTO   vn_count
                FROM   DUAL
                WHERE  pv_expenditure_type IN
                               ( -- Projet avec controle des mouvements au niveau tache
                                SELECT petev.expenditure_type
                                FROM   pa_transaction_controls ptc,
                                       pa_tasks pt,
                                       pa_expenditure_types_expend_v petev
                                WHERE  pt.project_id = vn_project_id
                                       AND pt.limit_to_txn_controls_flag = 'Y'
                                       AND ptc.project_id = vn_project_id
                                       AND ptc.task_id = pt.task_id
                                       AND pt.task_id = vn_task_id
                                       AND petev.expenditure_type = ptc.expenditure_type
                                       AND pd_date BETWEEN petev.expnd_typ_start_date_active
                                                       AND NVL (petev.expnd_typ_end_date_active, pd_date)
                                       AND pd_date BETWEEN petev.sys_link_start_date_active
                                                       AND NVL (petev.sys_link_end_date_active, pd_date)
                                UNION ALL
                                -- Projet sans controle des mouvements au niveau tache, avec controle des mouvements au niveau projet
                                SELECT petev.expenditure_type
                                FROM   pa_transaction_controls ptc,
                                       pa_projects_all pp,
                                       pa_tasks pt,
                                       pa_expenditure_types_expend_v petev
                                WHERE      pp.project_id = vn_project_id
                                       AND pp.limit_to_txn_controls_flag = 'Y'
                                       AND pt.project_id = vn_project_id
                                       AND pt.limit_to_txn_controls_flag = 'N'
                                       AND ptc.project_id = vn_project_id
                                       AND pt.task_id = vn_task_id
                                       AND NVL (ptc.task_id, 0) = 0
                                       AND petev.expenditure_type = ptc.expenditure_type
                                       AND pd_date BETWEEN petev.expnd_typ_start_date_active
                                                       AND NVL (petev.expnd_typ_end_date_active, pd_date)
                                       AND pd_date BETWEEN petev.sys_link_start_date_active
                                                       AND NVL (petev.sys_link_end_date_active, pd_date)
                                UNION ALL
                                -- Projet sans controle des mouvements au niveau tache, sans controle des mouvements au niveau projet
                                SELECT petev.expenditure_type
                                FROM   pa_projects_all pp,
                                       pa_tasks pt,
                                       pa_expenditure_types_expend_v petev
                                WHERE  pp.project_id = vn_project_id
                                       AND pt.task_id = vn_task_id
                                       AND pp.limit_to_txn_controls_flag = 'N'
                                       AND pt.project_id = pp.project_id
                                       AND pt.limit_to_txn_controls_flag = 'N'
                                       AND pd_date BETWEEN petev.expnd_typ_start_date_active
                                                       AND NVL (petev.expnd_typ_end_date_active, pd_date)
                                       AND pd_date BETWEEN petev.sys_link_start_date_active
                                                       AND NVL (petev.sys_link_end_date_active, pd_date));

                IF vn_count = 0
                THEN
                    pv_errbuf    :=    'Le type de dépense '
                                    || pv_expenditure_type
                                    || ' n''est pas autorisé sur le projet '
                                    || vn_project_id;
                    RAISE e_check_ko;
                END IF;
            END;
        END IF;

        -- Vérification de la validité du projet a la date reçue
        DECLARE
            vn_count   NUMBER (15);
        BEGIN
            SELECT COUNT (1)
            INTO   vn_count
            FROM   pa_projects_all pp
            WHERE      pp.project_id = vn_project_id
                   AND pd_date BETWEEN NVL (pp.start_date, pd_date)
                                   AND NVL (NVL (pp.completion_date, Fnd_Date.canonical_to_date (pp.attribute7)), pd_date);

            IF vn_count = 0
            THEN
                pv_errbuf    := 'Le projet ' || vn_project_id || ' n''est pas valide au ' || TO_CHAR (pd_date, 'DD/MM/YYYY');
                RAISE e_check_ko;
            END IF;
        END;
    EXCEPTION
        WHEN e_error
        THEN
            pn_retcode    := 2;
        WHEN e_check_ko
        THEN
            pn_retcode    := 1;
        WHEN OTHERS
        THEN
            pv_errbuf     := 'pa_check_transaction_data - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END pa_check_transaction_data;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_RULE_ID
--  Description   : Fonction de recherche de regle d'autoaccounting
--
--  PARAMETRES    :
--      pn_segment_num        pa_segment_rule_pairings.segment_num%TYPE
--      pn_org_id             pa_segment_rule_pairings.org_id%TYPE
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : pa_segment_rule_pairings.rule_id%TYPE
-------------------------------------------------------------------------------------------------------------------
    FUNCTION get_rule_id (pn_segment_num     pa_segment_rule_pairings.segment_num%TYPE,
                          pn_org_id          pa_segment_rule_pairings.org_id%TYPE
                      ) RETURN pa_segment_rule_pairings.rule_id%TYPE
    IS
      vn_ar_seg_rule_id   pa_segment_rule_pairings.rule_id%TYPE;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- get_rule_id (+)');

        SELECT DISTINCT psrp.rule_id
        INTO   vn_ar_seg_rule_id
        FROM   pa_segment_rule_pairings psrp
        WHERE      psrp.application_id = 275
               AND psrp.function_code = gv_ar_function_code
               AND psrp.function_transaction_code = gv_ar_function_transaction
               AND psrp.segment_num = pn_segment_num - 1 -- Numerotation a partir de 0
               AND psrp.org_id = pn_org_id ;

        Dka_Tools_Pkg.put_debug_message ('- get_rule_id (-)');

        RETURN vn_ar_seg_rule_id;

    END get_rule_id;

-----------------------------------------------------------------------------------------------------------------------
--  Nom           : INIT
--  Description   : Initialisation
--
--  PARAMETRES    :
--    pv_errbuf
--    pv_retcode
--
--  VALEUR RETOURNEE :
--     Description       : Initialisation
--     Valeurs possibles :
----------------------------------------------------------------------------------------------------------------------

    PROCEDURE init (
        pv_errbuf     OUT   VARCHAR2,
        pn_retcode    OUT   NUMBER,
        pd_ref_date   OUT   DATE
    )
    IS
        rec_param   dka_parameters%ROWTYPE;
        vv_step     VARCHAR2 (20);
        e_error     EXCEPTION;

        vv_period_name gl_period_statuses.period_name%TYPE;

    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- init (+)');
        vv_step                         := 'INIT - 00';
        pv_errbuf                       := NULL;
        pn_retcode                      := 0;

        -- Appel a la procédure commune d'initialisation de l'état de sortie
        Dka_Tools_Pkg.put_out_header;
        vv_step                         := 'INIT - 01';

        -- Contrôle s'il n'existe qu'une seule période ouverte
        BEGIN
          SELECT DISTINCT PERIOD_NAME
          INTO vv_period_name
          FROM gl_period_statuses gps
          WHERE gps.application_id = 222
           AND closing_status = 'O'
           AND set_of_books_id in  (SELECT gl.ledger_id
                                    FROM gl_access_set_assignments gasa, gl_ledgers gl  --RBE artf2154096
                                    WHERE access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID')
                                    AND gl.ledger_id = gasa.ledger_id
                                    AND gl.ledger_category_code = 'PRIMARY' --YWA artf2108946
                                    );

        EXCEPTION
         WHEN TOO_MANY_ROWS THEN
          pv_errbuf    := 'MULTIPLE PERIOD AR OPEN - ' || pv_errbuf;
          RAISE e_error;
        END;

        -- Calcul de la date de référence
        SELECT MIN (gps.end_date)
        INTO   pd_ref_date
        FROM   gl_period_statuses gps
        WHERE      gps.application_id = 222
               AND closing_status = 'O'
               AND set_of_books_id in ( SELECT gl.ledger_id
                                        FROM gl_access_set_assignments gasa, gl_ledgers gl  --RBE artf2154096
                                        WHERE access_set_id = FND_PROFILE.value('GL_ACCESS_SET_ID')
                                        AND gl.ledger_id = gasa.ledger_id
                                        AND gl.ledger_category_code = 'PRIMARY' --YWA artf2108946
                                        );

        Dka_Tools_Pkg.put_debug_message ('Date de référence: '|| TO_CHAR (pd_ref_date, 'DD/MM/YYYY'));

        -- Récupération des variables de la table des parametres
        vv_step                         := 'INIT - 02';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'PROJECT_TYPE_REFAC', rec_param, pn_retcode, pv_errbuf);
        gv_project_type_refac           := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PROJECT_TYPE_REFAC - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 03';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'EXPENDITURE_SOURCE', rec_param, pn_retcode, pv_errbuf);
        gv_expenditure_source           := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EXPENDITURE_SOURCE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 04';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'EVENT_SOURCE', rec_param, pn_retcode, pv_errbuf);
        gv_event_source                 := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'EVENT_SOURCE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 05';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_CUST_TRX_TYPE', rec_param, pn_retcode, pv_errbuf);
        gv_ar_cust_trx_type             := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_CUST_TRX_TYPE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 06';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_CUST_TRX_TYPE_CM', rec_param, pn_retcode, pv_errbuf);
        gv_ar_cust_trx_type_cm          := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_CUST_TRX_TYPE_CM - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 07';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_BATCH_SOURCE', rec_param, pn_retcode, pv_errbuf);
        gv_ar_batch_source              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_BATCH_SOURCE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 08';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_INTERFACE_LINE_CONTEXT', rec_param, pn_retcode, pv_errbuf);
        gv_ar_interface_line_context    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_INTERFACE_LINE_CONTEXT - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 09';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_LINE_TYPE_LINE', rec_param, pn_retcode, pv_errbuf);
        gv_ar_line_type_line            := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_LINE_TYPE_LINE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 10';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_LINE_TYPE_TAX', rec_param, pn_retcode, pv_errbuf);
        gv_ar_line_type_tax             := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_LINE_TYPE_TAX - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 11';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'CONVERSION_TYPE', rec_param, pn_retcode, pv_errbuf);
        gv_conversion_type              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'CONVERSION_TYPE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 11';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'TAX_REGIME_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_tax_regime_code              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'TAX_REGIME_CODE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 11';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'TAX', rec_param, pn_retcode, pv_errbuf);
        gv_tax              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'TAX - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 11';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'TAX_JURISDICTION_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_tax_jurisdiction_code              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'TAX - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 12';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'TAX_CODE_COLL', rec_param, pn_retcode, pv_errbuf);
        gv_tax_code_coll                := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'TAX_CODE_COLL - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        BEGIN
         SELECT percentage_rate,tax_rate_id,tax_status_code
         INTO gn_tax_rate_coll,gn_tax_rate_id_coll,gv_tax_status_code_coll
         FROM zx_rates_vl
         WHERE
          tax_rate_code       = gv_tax_code_coll
          AND tax_regime_code = gv_tax_regime_code
          AND tax             = gv_tax
          AND tax_jurisdiction_code = gv_tax_jurisdiction_code;

        EXCEPTION
         WHEN OTHERS THEN
           pv_errbuf    := 'TAX_RATE_COLL - ' || SQLERRM;
           RAISE e_error;
        END;

        vv_step                         := 'INIT - 12';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'TAX_CODE_DED', rec_param, pn_retcode, pv_errbuf);
        gv_tax_code_ded                 := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'TAX_CODE_DED - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        BEGIN
         SELECT percentage_rate,tax_rate_id,tax_status_code
         INTO gn_tax_rate_ded,gn_tax_rate_id_ded,gv_tax_status_code_ded
         FROM zx_rates_vl
         WHERE
          tax_rate_code       = gv_tax_code_ded
          AND tax_regime_code = gv_tax_regime_code
          AND tax             = gv_tax
          AND tax_jurisdiction_code = gv_tax_jurisdiction_code;

        EXCEPTION
         WHEN OTHERS THEN
           pv_errbuf    := 'TAX_RATE_DED - ' || SQLERRM;
           RAISE e_error;
        END;

        vv_step                         := 'INIT - 13';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_TAX_TYPE', rec_param, pn_retcode, pv_errbuf);
        gv_ar_tax_type                  := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_TAX_TYPE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- CD 20/05/03
        vv_step                         := 'INIT - 14';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_TAX_SEGMENT3', rec_param, pn_retcode, pv_errbuf);
        gv_ar_tax_segment3              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_TAX_SEGMENT3 - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 15';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_TAX_TYPE', rec_param, pn_retcode, pv_errbuf);
        gv_ap_tax_type                  := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_TAX_TYPE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 16';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_TAX_SEGMENT3', rec_param, pn_retcode, pv_errbuf);
        gv_ap_tax_segment3              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_TAX_SEGMENT3 - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 17';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_INVOICE_TYPE', rec_param, pn_retcode, pv_errbuf);
        gv_ap_invoice_type              := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_INVOICE_TYPE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 18';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_SOURCE', rec_param, pn_retcode, pv_errbuf);
        gv_ap_source                    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_SOURCE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 19';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_DOC_CATEGORY_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_ap_doc_category_code         := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_DOC_CATEGORY_CODE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 20';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_LINE_TYPE_LINE', rec_param, pn_retcode, pv_errbuf);
        gv_ap_line_type_line            := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_LINE_TYPE_LINE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 21';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_LINE_TYPE_TAX', rec_param, pn_retcode, pv_errbuf);
        gv_ap_line_type_tax             := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_LINE_TYPE_TAX - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 22';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'DEFAULT_DESCRIPTION', rec_param, pn_retcode, pv_errbuf);
        gv_default_description          := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'DEFAULT_DESCRIPTION - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 23';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_RESPONSIBILITY_KEY', rec_param, pn_retcode, pv_errbuf);
        gv_ar_responsibility_key        := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_RESPONSIBILITY_KEY - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 24';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_RESPONSIBILITY_KEY', rec_param, pn_retcode, pv_errbuf);
        gv_ap_responsibility_key        := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_RESPONSIBILITY_KEY - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 25';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'INVOICE_PRINT_STYLE', rec_param, pn_retcode, pv_errbuf);
        gv_invoice_print_style          := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'INVOICE_PRINT_STYLE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 26';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'APPENDIX_PRINT_STYLE', rec_param, pn_retcode, pv_errbuf);
        gv_appendix_print_style         := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'APPENDIX_PRINT_STYLE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 27';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_FUNCTION_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_ar_function_code             := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_FUNCTION_CODE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 28';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_FUNCTION_TRANSACTION_CODE', rec_param, pn_retcode, pv_errbuf);
        gv_ar_function_transaction      := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_FUNCTION_TRANSACTION_CODE - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 29';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'TRX_NUMBER_BEGINNING', rec_param, pn_retcode, pv_errbuf);
        gv_trx_number_beginning         := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'TRX_NUMBER_BEGINNING - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 30';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'PA_CONTEXT_AP_REFAC', rec_param, pn_retcode, pv_errbuf);
        gv_pa_context_ap_refac          := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PA_CONTEXT_AP_REFAC - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 31';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AP_TERM', rec_param, pn_retcode, pv_errbuf);
        gv_ap_term                      := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AP_TERM - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 32';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'AR_TERM', rec_param, pn_retcode, pv_errbuf);
        gv_ar_term                      := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR_TERM - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 33';
        Dka_Tools_Pkg.get_parameter ('SARREFAC', 'GLOBAL_ATTRIBUTE_CATEGORY', rec_param, pn_retcode, pv_errbuf);
        gv_global_attribute_category    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'GLOBAL_ATTRIBUTE_CATEGORY - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 34';
        gn_user_id                      := Fnd_Global.user_id;
        gn_login_id                     := Fnd_Global.login_id;
        vv_step                         := 'INIT - 35';
        gn_conc_request_id              := Fnd_Global.conc_request_id;
        vv_step                         := 'INIT - 36';
        gn_responsibility_id            := Fnd_Profile.VALUE ('RESP_ID');
        gn_resp_application_id          := Fnd_Profile.VALUE ('RESP_APPL_ID');

        vv_step                         := 'INIT - 37';
        Dka_Tools_Pkg.get_flex_key_seg_value_set (
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode,
            pn_segment_num                 => 4,
            pn_flex_value_set_id           => gn_seg4_flex_value_set_id,
            pv_flex_value_set_name         => gv_seg4_flex_value_set_name
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'JDV SEGMENT4 - ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step                         := 'INIT - 51';

        BEGIN
            SELECT rt.term_id
            INTO   gn_ar_term_id
            FROM   ra_terms rt
            WHERE  rt.NAME = gv_ar_term;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                pv_errbuf    := 'TERM_ID AR - Non trouvé';
                RAISE e_error;
        END;

        vv_step                         := 'INIT - 52';

        BEGIN
            SELECT a.term_id
            INTO   gn_ap_term_id
            FROM   ap_terms a
            WHERE  a.NAME = gv_ap_term;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                pv_errbuf    := 'TERM_ID AR - Non trouvé';
                RAISE e_error;
        END;

        Dka_Tools_Pkg.put_debug_message ('- init (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := vv_step || ' -> ' || SQLERRM;
    END init;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PRE_REQUEST
--  Description   : Traitement préliminaire
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pre_request (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- pre_request (+)');

        UPDATE PA_EXPENDITURE_ITEMS_ALL pei
        SET    (pei.attribute1,pei.attribute2,pei.attribute7) =
        /*(SELECT aid.attribute1,ppa.org_id,aid.attribute7
         FROM   pa_cost_distribution_lines_all pcdl,
                ap_invoice_distributions_all aid, --RBE artf2082348
                pa_projects_all ppa
         WHERE      pcdl.expenditure_item_id = pei.expenditure_item_id
                AND aid.org_id = pei.org_id
                AND aid.invoice_id = pcdl.system_reference2
                AND aid.distribution_line_number = pcdl.system_reference3 --RBE artf2082348
                AND ppa.project_id = aid.attribute1),*/
    (SELECT aid.attribute1,ppa.org_id,aid.attribute7
         FROM   pa_expenditure_items_all pei1, -- MODIF TB 09022017
                        ap_invoice_distributions_all aid, --RBE artf2082348
                        pa_projects_all ppa
         WHERE      pei1.expenditure_item_id = pei.expenditure_item_id -- MODIF TB
                AND aid.org_id = pei.org_id
                AND aid.invoice_distribution_id = pei1.document_distribution_id -- MODIF TB 09022017
                AND ppa.project_id = aid.attribute1),
               pei.attribute_category = gv_pa_context_ap_refac
          WHERE  pei.expenditure_item_id IN (SELECT pei0.expenditure_item_id
                                             FROM   pa_expenditure_items_all pei0,
                                                    pa_projects_all pp,
                                                    pa_tasks pt,
                                                    pa_cost_distribution_lines_all pcdl,
                                                    pa_implementations_all pi
                                             WHERE       pei0.org_id = pi.org_id
                                                    AND pei0.attribute3 IS NULL -- Non traité par la refac
                                                    AND (pei0.attribute1 IS NULL -- Infos non renseignées
                                                         or pei0.attribute2 IS NULL
                                                         or pei0.attribute7 IS NULL)
                                                    AND pei0.system_linkage_function IN ('VI', 'ER')
                                                    AND pt.task_id = pei0.task_id
                                                    AND pp.project_id = pt.project_id
                                                    AND pp.project_type = gv_project_type_refac
                                                    AND pcdl.expenditure_item_id = pei0.expenditure_item_id
                                                    AND pcdl.transfer_status_code = 'V');

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes mises a jour');

        --< OBE artf2216086
        UPDATE pa_expenditure_items_all pei
        SET ATTRIBUTE2 = (SELECT ppa.org_id
                          FROM pa_projects_all ppa, pa_expenditure_items_all pei1
                          WHERE pei1.expenditure_item_id = pei.expenditure_item_id
                          AND   pei1.attribute1 = ppa.project_id
                         )
        WHERE pei.ATTRIBUTE_CATEGORY ='GL_REFAC'
        AND pei.ATTRIBUTE3 IS NULL;
        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes de dépenses GL REFAC mises a jour');

        UPDATE PA_EVENTS pae
        SET ATTRIBUTE2 = (SELECT ppa.org_id
                          FROM pa_projects_all ppa, PA_EVENTS pae1
                          WHERE pae1.event_id = pae.event_id
                          AND   pae1.attribute1 = ppa.project_id
                         )
        WHERE pae.ATTRIBUTE_CATEGORY ='GL_REFAC'
        AND pae.ATTRIBUTE3 IS NULL;
        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes d''évenements GL REFAC mises a jour');
        --> OBE artf2216086
        Dka_Tools_Pkg.put_debug_message ('- pre_request (-)');

    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END pre_request;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : DELETE_DKA_SARREFAC_TMP
--  Description   : Purge de la table DKA_SARREFAC_TMP
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE delete_dka_sarrefac_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- delete_dka_sarrefac_tmp (+)');

        DELETE      dka_sarrefac_tmp dst;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimées de dka_sarrefac_tmp');

        DELETE      dka_sarrefac_ar_trx_interface dsati;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimées de dka_sarrefac_ar_trx_interface');

        DELETE      dka_sarrefac_ap_inv_interface dsaii;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimées de dka_sarrefac_ap_inv_interface');
        Dka_Tools_Pkg.put_debug_message ('- delete_dka_sarrefac_tmp (-)');
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END delete_dka_sarrefac_tmp;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : INSERT_DKA_SARREFAC_TMP
--  Description   : Insertion des données la table DKA_SARREFAC_TMP
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------

    PROCEDURE insert_dka_sarrefac_tmp (
        pv_errbuf     OUT      VARCHAR2,
        pn_retcode    OUT      NUMBER,
        pd_ref_date   IN       DATE
    )
    IS
        vn_dummy_event   PLS_INTEGER;
        vn_dummy_dep     PLS_INTEGER;
        e_error    EXCEPTION;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- insert_dka_sarrefac_tmp (+)');

        Dka_Tools_Pkg.put_debug_message ('--Lignes de dépenses');

        INSERT INTO dka_sarrefac_tmp
                    (transaction_source,
                     from_org_id,
                     from_org_name,
                     to_org_id,
                     to_org_name,
                     from_project_id,
                     from_task_id,
                     to_project_id,
                     to_task_id,
                     from_acct_center,
                     to_acct_center,
                     create_ap_data_flag,
                     create_ar_data_flag,
                     to_segment1,
                     to_segment2,
                     expenditure_item_id,
                     expenditure_org_id,
                     event_id,
                     description,
                     pa_cr_ccid,
                     pa_dr_ccid,
                     quantity,
                     orig_transaction_date,
                     gl_date,
                     orig_transaction_type,
                     ar_event_type,
                     ap_expenditure_type,
                     amount,
                     invoice_number,
                     customer_id,
                     customer_number,
                     customer_site_id,
                     customer_site_code,
                     vendor_id,
                     vendor_number,
                     vendor_site_id,
                     vendor_site_code,
                     created_by,
                     creation_date,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     request_id,
                     transfer_status_code,
                     transfer_rejection_reason
                    )
            SELECT *
              FROM (SELECT gv_expenditure_source AS Transaction_Source,
                           from_hou.organization_id AS From_Org_Id,
                           from_hou.name AS From_Org_Name,
                           to_pp.org_id To_Org_Id,
                           to_haou.name AS To_Org_Name,
                           (SELECT from_pp.project_id
                              FROM pa_projects_all from_pp,
                                   pa_tasks from_pt
                             WHERE from_pp.project_id = from_pt.project_id
                               AND from_pt.task_id = pei.task_id
                               AND from_pp.org_id = pei.org_id
                               AND from_pp.project_type = gv_project_type_refac) AS From_Project_Id,
                           pei.task_id AS From_Task_Id,
                           to_pp.project_id AS To_Project_Id,
                           to_pt.task_id AS To_Task_Id,
                           NULL AS From_acct_center,
                           NULL AS To_acct_center,
                           NVL (to_haou.attribute4, 'Y') AS create_ap_data_flag,
                           NVL (from_hou_fils.attribute4, 'Y') AS create_ar_data_flag,
                           NULL AS To_Segment1,
                           NULL AS To_Segment2,
                           pei.expenditure_item_id AS Expenditure_item_id,
                           to_pp.carrying_out_organization_id AS expenditure_org_id,
                           NULL AS Event_Id,
                           NVL ((SELECT pec.expenditure_comment FROM pa_expenditure_comments pec WHERE pec.expenditure_item_id = pei.expenditure_item_id), gv_default_description) AS Description,
                           pcdl.cr_code_combination_id AS PA_Cr_Ccid,
                           pcdl.dr_code_combination_id AS PA_Dr_Ccid,
                           pei.quantity AS Quantity,
                           pei.expenditure_item_date AS Orig_Transaction_Date,
                           pcdl.gl_date AS Gl_Date,
                           pei.expenditure_type AS Orig_Transaction_Type,
                           (SELECT dsp.ar_event_type
                              FROM dka_sarrefac_param dsp
                             WHERE dsp.orig_transaction_type = pei.expenditure_type) AS AR_Event_Type,
                           (SELECT dsp.ap_expenditure_type
                              FROM dka_sarrefac_param dsp
                             WHERE dsp.orig_transaction_type = pei.expenditure_type) AS AP_Expenditure_Type,
                           pei.raw_cost AS Amount,
                           NULL AS invoice_number,
                           NULL AS Customer_Id,
                           NULL AS Customer_Number,
                           NULL AS Customer_Site_Use_Id,
                           NULL AS Customer_Site_Use_Code,
                           NULL AS Vendor_Id,
                           NULL AS Vendor_Number,
                           NULL AS Vendor_Site_Id,
                           NULL AS Vendor_Site_Code,
                           gn_user_id AS Created_By,
                           SYSDATE AS Creation_Date,
                           gn_user_id AS Last_Updated_By,
                           SYSDATE AS Last_Update_Date,
                           gn_login_id AS Last_Update_Login,
                           gn_conc_request_id AS Request_Id,
                           'P' AS Transfer_Status_Code,
                           NULL AS Transfer_Rejection_Reason
                      FROM pa_expenditure_items_all pei,
                           pa_cost_distribution_lines_all pcdl,
                           pa_projects_all to_pp,
                           pa_tasks        to_pt,
                           hr_all_organization_units to_haou,
                           hr_all_organization_units from_hou_fils,
                           hr_all_organization_units from_hou
                     WHERE
                       pei.attribute3 IS NULL -- Non traité
                       AND pei.attribute1 IS NOT NULL -- Avec un projet
                       AND pei.attribute7 IS NOT NULL -- Avec une tache
                       AND pcdl.expenditure_item_id = pei.expenditure_item_id
                       AND pcdl.org_id = pei.org_id
                       AND pcdl.transfer_status_code IN ('A', 'V')
                       AND TRUNC (pcdl.gl_date) <= TRUNC (pd_ref_date)
                       AND to_pp.project_id = TO_NUMBER (pei.attribute1)
                       and to_pt.task_id    = TO_NUMBER (pei.attribute7)
                       and to_pt.project_id = to_pp.project_id
                       AND from_hou_fils.organization_id = pei.override_to_organization_id
                       and to_pp.org_id =  to_haou.organization_id
                       and from_hou.organization_id = TO_NUMBER (pei.attribute2)
                   )
             WHERE from_project_id IS NOT NULL;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes de dépenses insérées');
        Dka_Tools_Pkg.put_debug_message ('>>>>> Validation apres insertion');
        COMMIT;

        Dka_Tools_Pkg.put_debug_message ('-- Lignes d''évenements');


        INSERT INTO dka_sarrefac_tmp
                    (transaction_source,
                     from_org_id,
                     from_org_name,
                     to_org_id,
                     to_org_name,
                     from_project_id,
                     from_task_id,
                     to_project_id,
                     to_task_id,
                     from_acct_center,
                     to_acct_center,
                     create_ap_data_flag,
                     create_ar_data_flag,
                     to_segment1,
                     to_segment2, --PHENIX 2004
                     expenditure_item_id,
                     expenditure_org_id,
                     event_id,
                     description,
                     pa_cr_ccid,
                     pa_dr_ccid,
                     quantity,
                     orig_transaction_date,
                     gl_date,
                     orig_transaction_type,
                     ar_event_type,
                     ap_expenditure_type,
                     amount,
                     invoice_number,
                     customer_id,
                     customer_number,
                     customer_site_id,
                     customer_site_code,
                     vendor_id,
                     vendor_number,
                     vendor_site_id,
                     vendor_site_code,
                     created_by,
                     creation_date,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     request_id,
                     transfer_status_code,
                     transfer_rejection_reason
                    )
            SELECT gv_event_source, --Transaction_Source
                   from_hou.organization_id, --From_Org_Id  PHENIX 2004 from_pp.org_id
                   from_hou.NAME, --From_Org_Name
                   to_hou.organization_id, --To_Org_Id   PHENIX 2004 to_pp.org_id
                   to_hou.NAME, --To_Org_Name
                   from_pp.project_id, --From_Project_Id
                   from_pt.task_id, --From_Task_Id
                   to_pp.project_id, --To_Project_Id
                   to_pt.task_id, --To_Task_Id
                   NULL, --From_acct_center
                   NULL, --To_acct_center
                   NVL (from_hou.attribute4, 'Y'), --create_ap_data_flag
                   NVL (to_hou.attribute4, 'Y'), --create_ar_data_flag
                   NULL, --To_Segment1
                   NULL, --To_Segment2 -- PHENIX 2004
                   NULL, --Expenditure_item_id
                   from_pp.carrying_out_organization_id,--expenditure_org_id
                   pe.event_id, --Event_Id
                   NVL (pe.description, gv_default_description), --Description
                   pdr.unearned_code_combination_id, --PA_Cr_Ccid
                   pcer.code_combination_id, --PA_Dr_Ccid
                   pe.revenue_amount, --Quantity
                   pe.completion_date, --Orig_Transaction_Date
                   pdr.gl_date, --Gl_Date
                   pe.event_type, --Orig_Transaction_Type
                   dsp.ar_event_type, --AR_Event_Type
                   dsp.ap_expenditure_type, --AP_Expenditure_Type
                   pe.revenue_amount, --Amount
                   NULL, --To_Char(to_pp.org_id) || '_' || To_Char(from_pp.org_id) || '_' || To_Char(gn_conc_request_id), --Invoice_Number
                   NULL, --Customer_Id
                   NULL, --Customer_Number
                   NULL, --Customer_Site_Use_Id
                   NULL, --Customer_Site_Use_Code
                   NULL, --Vendor_Id
                   NULL, --Vendor_Number
                   NULL, --Vendor_Site_Id
                   NULL, --Vendor_Site_Code
                   gn_user_id, --Created_By
                   SYSDATE, --Creation_Date
                   gn_user_id, --Last_Updated_By
                   SYSDATE, --Last_Update_Date
                   gn_login_id, --Last_Update_Login
                   gn_conc_request_id, --Request_Id
                   'P', --Transfer_Status_Code
                   NULL --Transfer_Rejection_Reason
            FROM   pa_events pe,
                   pa_cust_event_rdl_all pcer,
                   pa_draft_revenues_all pdr,
                   pa_projects_all from_pp,
                   pa_tasks from_pt,
                   pa_projects_all to_pp,
                   pa_tasks to_pt,
                   dka_sarrefac_param dsp,
                   hr_all_organization_units from_hou,
                   hr_all_organization_units from_hou_fils,
                   hr_all_organization_units to_hou,
                   pa_implementations_all pi,
                   gl_ledgers gl
            WHERE  --gl.name=  mo_utils.Get_Ledger_Name(to_hou.organization_id)
                   pi.set_of_books_id = gl.ledger_id
                   AND from_pp.org_id = pi.org_id
                   AND pe.attribute3 IS NULL -- Non traité
                   AND pe.attribute1 IS NOT NULL -- Avec un projet
                   AND pe.attribute7 IS NOT NULL -- Avec une tache
                   AND from_pp.project_id = pe.project_id
                   AND from_pp.project_type = gv_project_type_refac
                   AND to_pp.project_id = TO_NUMBER (pe.attribute1)
                   AND dsp.orig_transaction_type = pe.event_type
                   AND pcer.project_id = pe.project_id
                   AND pcer.event_num = pe.event_num
                   AND pcer.org_id = from_pp.org_id
                   AND pdr.project_id = pcer.project_id
                   AND pdr.draft_revenue_num = pcer.draft_revenue_num
                   AND pdr.org_id = pcer.org_id
                   AND TRUNC (pdr.gl_date) <= TRUNC (pd_ref_date)
                   AND from_hou.organization_id = from_pp.org_id
                   AND from_hou_fils.organization_id = pe.organization_id
                   AND to_hou.organization_id = to_pp.org_id
                   AND from_pt.project_id = from_pp.project_id
                   AND from_pt.task_id = (SELECT MIN (pt.task_id)
                                          FROM   pa_tasks pt
                                          WHERE      pt.project_id = from_pp.project_id
                                                 AND pt.chargeable_flag = 'Y'
                                                 AND pe.completion_date BETWEEN pt.start_date
                                                                            AND NVL (pt.completion_date, pe.completion_date))
                   AND to_pt.project_id = to_pp.project_id
                   AND to_pt.task_id = TO_NUMBER (pe.attribute7);

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes d''évenements insérées');
        Dka_Tools_Pkg.put_debug_message ('>>>>> Validation apres insertion');
        COMMIT;


        -- Vérification de doublons
        SELECT COUNT (1)
        INTO   vn_dummy_event
        FROM   DUAL
        WHERE  EXISTS ( SELECT   event_id,
                                 COUNT (1)
                        FROM     dka_sarrefac_tmp dst
                        WHERE    dst.transaction_source = gv_event_source
                        HAVING   COUNT (1) > 1
                        GROUP BY dst.event_id);

        IF vn_dummy_event = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Pas de doublon pour '|| gv_event_source);
        ELSE
            pv_errbuf    := 'Doublons pour ' || gv_event_source;
        END IF;

        -- Vérification de doublons
        SELECT COUNT (1)
        INTO   vn_dummy_dep
        FROM   DUAL
        WHERE  EXISTS ( SELECT   expenditure_item_id,
                                 COUNT (1)
                        FROM     dka_sarrefac_tmp dst
                        WHERE    dst.transaction_source = gv_expenditure_source
                        HAVING   COUNT (1) > 1
                        GROUP BY dst.expenditure_item_id);

        IF vn_dummy_dep = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Pas de doublon pour '|| gv_expenditure_source);
        ELSE
            pv_errbuf    := 'Doublons pour ' || gv_expenditure_source;
        END IF;


        IF vn_dummy_event > 0 or vn_dummy_dep > 0
        THEN
            RAISE e_error;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('- insert_dka_sarrefac_tmp (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := cv_program_code || pv_errbuf;
            pn_retcode    := 2;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
    END insert_dka_sarrefac_tmp;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_ACCT_AREAS
--  Description   : Traitement préliminaire de calcul des centres de gestion
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_acct_areas (
        pv_errbuf     OUT      VARCHAR2,
        pn_retcode    OUT      NUMBER,
        pd_ref_date   IN       DATE
    )
    IS
        CURSOR dka_sarrefac_tmp_cur
        IS
            SELECT dst.ROWID row_id,
                   dst.*
            FROM   dka_sarrefac_tmp dst
            WHERE  dst.transfer_status_code = 'P';

        e_error                EXCEPTION;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- get_acct_areas (+)');

        --Modif recherche société from et to
        FOR dka_sarrefac_tmp_rec IN dka_sarrefac_tmp_cur LOOP

            DECLARE -- Début pre-traitement du record
                rec_error           EXCEPTION;
                vn_from_org_id      hr_all_organization_units.organization_id%TYPE; -- PHENIX 2004 Ajout
                vv_from_societe     VARCHAR2(10);
                vv_from_acct_area   VARCHAR2(10);
                vn_to_org_id        hr_all_organization_units.organization_id%TYPE; -- PHENIX 2004 Ajout
                vv_to_societe       VARCHAR2(10);
                vv_to_acct_area     VARCHAR2(10);
                vn_to_segment1      fnd_flex_values.flex_value_id%TYPE;
                vn_to_segment2      fnd_flex_values.flex_value_id%TYPE;             -- PHENIX 2004 Ajout
            BEGIN
                --dka_tools_pkg.put_debug_message (
                --       'Pré-traitement de la ligne '
                --    || dka_sarrefac_tmp_rec.transaction_source
                --    || ' | exp_item_id = '
                --    || dka_sarrefac_tmp_rec.expenditure_item_id
                --    || ' | event_id = '
                --    || dka_sarrefac_tmp_rec.event_id
                --);

                -- Détermination des sociétés et centres de gestion
                vv_from_societe      := NULL;
                vv_from_acct_area    := NULL;
                vv_to_societe        := NULL;
                vv_to_acct_area      := NULL;

                --------------------
                --FROM
                --------------------

                BEGIN

                 SELECT
                  ppa.org_id,
                  SUBSTR (haou.name, 1 , 3),
                  SUBSTR (haou.name, 4)
                 INTO
                  vn_from_org_id,
                  vv_from_acct_area,
                  vv_from_societe
                 FROM
                  pa_projects_all ppa,
                  hr_all_organization_units haou
                 where
                  project_id = dka_sarrefac_tmp_rec.from_project_id
                  and haou.organization_id = ppa.org_id;

               EXCEPTION
                WHEN OTHERS THEN
                  Dka_Tools_Pkg.put_debug_message (
                           'Pré-traitement de la ligne '
                        || dka_sarrefac_tmp_rec.transaction_source
                        || ' | exp_item_id = '
                        || dka_sarrefac_tmp_rec.expenditure_item_id
                        || ' | event_id = '
                        || dka_sarrefac_tmp_rec.event_id
                    );
                    Dka_Tools_Pkg.put_debug_message (
                           'ERREUR lors de la récupération du centre de gestion d''origine'
                        || ' - project_id:'
                        || TO_CHAR (dka_sarrefac_tmp_rec.from_project_id)
                        || ' - org_name:'
                        || dka_sarrefac_tmp_rec.from_org_name
                    );
                    --dka_tools_pkg.put_debug_message ('>>> ' || pv_errbuf);
                    pn_retcode    := 2;
                    pv_errbuf     := 'ERREUR lors de la récupération du centre de gestion d''origine';
                    RAISE rec_error;
                END ;

                --------------------
                --TO
                --------------------

                BEGIN

                 SELECT
                  ppa.org_id,
                  SUBSTR (haou.name, 1 , 3),
                  SUBSTR (haou.name, 4)
                 INTO
                  vn_to_org_id,
                  vv_to_acct_area,
                  vv_to_societe
                 FROM
                  pa_projects_all ppa,
                  hr_all_organization_units haou
                 where
                  project_id = dka_sarrefac_tmp_rec.to_project_id
                  and haou.organization_id = ppa.org_id;

               EXCEPTION
                WHEN OTHERS THEN
                  Dka_Tools_Pkg.put_debug_message (
                           'Pré-traitement de la ligne '
                        || dka_sarrefac_tmp_rec.transaction_source
                        || ' | exp_item_id = '
                        || dka_sarrefac_tmp_rec.expenditure_item_id
                        || ' | event_id = '
                        || dka_sarrefac_tmp_rec.event_id
                    );
                    Dka_Tools_Pkg.put_debug_message (
                           'ERREUR lors de la récupération du centre de gestion de destination'
                        || ' - project_id:'
                        || TO_CHAR (dka_sarrefac_tmp_rec.to_project_id)
                        || ' - org_name:'
                        || dka_sarrefac_tmp_rec.to_org_name
                    );
                    --dka_tools_pkg.put_debug_message ('>>> ' || pv_errbuf);
                    pn_retcode    := 2;
                    pv_errbuf     := 'ERREUR lors de la récupération du centre de gestion de destination';
                    RAISE rec_error;
                END;


                -- Détermination de l'identifiant du segment1 comptable
                SELECT ffv.flex_value_id
                INTO   vn_to_segment1
                FROM   gl_sets_of_books gsob,
                       fnd_id_flex_segments fifs,
                       fnd_flex_values_vl ffv,
                       fnd_segment_attribute_values fsav,
                       gl_ledgers gl
                WHERE      gl.name = mo_utils.Get_Ledger_Name( vn_to_org_id )
                       AND gsob.set_of_books_id = gl.ledger_id
                       AND fifs.id_flex_num = gsob.chart_of_accounts_id
                       AND fifs.application_id = 101
                       AND fifs.id_flex_code = 'GL#'
                       AND fifs.application_column_name = fsav.application_column_name
                       AND fsav.id_flex_num = gsob.chart_of_accounts_id
                       AND fsav.application_id = fifs.application_id
                       AND fsav.id_flex_code = fifs.id_flex_code
                       AND fsav.segment_attribute_type = 'GL_BALANCING'
                       AND fsav.attribute_value = 'Y'
                       AND ffv.flex_value_set_id = fifs.flex_value_set_id
                       AND ffv.summary_flag = 'N'
                       AND ffv.enabled_flag = 'Y'
                       AND ffv.flex_value = vv_to_societe;

                -- Détermination de l'identifiant du segment2 comptable
                SELECT ffv.flex_value_id
                INTO   vn_to_segment2
                FROM   fnd_flex_value_sets ffvs,
                       fnd_flex_values_vl ffv
                WHERE      ffvs.flex_value_set_id = ffv.flex_value_set_id
                       AND ffvs.flex_value_set_name = 'DAOPCCF_UO'
                       AND ffv.flex_value = vv_to_acct_area;

                -- Mise a jour des informations
                UPDATE dka_sarrefac_tmp dst
                SET    dst.from_org_id = vn_from_org_id,
                       dst.from_org_name = vv_from_societe,
                       dst.from_acct_center = vv_from_acct_area,
                       dst.to_org_id = vn_to_org_id,
                       dst.to_org_name = vv_to_societe,
                       dst.to_acct_center = vv_to_acct_area,
                       dst.to_segment1 = vn_to_segment1,
                       dst.to_segment2 = vn_to_segment2,
                       dst.last_update_date = SYSDATE,
                       dst.last_updated_by = gn_user_id,
                       dst.last_update_login = gn_login_id,
                       dst.request_id = gn_conc_request_id
                WHERE  dst.ROWID = dka_sarrefac_tmp_rec.row_id;
            EXCEPTION
                WHEN rec_error
                THEN
                    -- Marquer la ligne en statut 'Rejeté'
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = pv_errbuf,
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE  dst.ROWID = dka_sarrefac_tmp_rec.row_id;

                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
                    Dka_Tools_Pkg.put_debug_message (
                           'ERREUR => '
                        || pv_errbuf
                        || ' -> '
                        || dka_sarrefac_tmp_rec.transaction_source
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.expenditure_item_id)
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.event_id)
                    );
                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
                WHEN NO_DATA_FOUND
                THEN
                    pv_errbuf    :=    'La valeur '
                                    || vv_to_societe || ' du segment1 '
                                    || vv_to_acct_area || ' du segment2 n''existe pas ou n''est pas valide';

                    -- Marquer la ligne en statut 'Rejeté'
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = pv_errbuf,
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE  dst.ROWID = dka_sarrefac_tmp_rec.row_id;

                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
                    Dka_Tools_Pkg.put_debug_message (
                           'ERREUR => '
                        || pv_errbuf
                        || ' -> '
                        || dka_sarrefac_tmp_rec.transaction_source
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.expenditure_item_id)
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.event_id)
                    );
                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
                WHEN OTHERS
                THEN
                    pv_errbuf    := SQLERRM;

                    -- Marquer la ligne en statut 'Rejeté'
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = pv_errbuf,
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE  dst.ROWID = dka_sarrefac_tmp_rec.row_id;

                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
                    Dka_Tools_Pkg.put_debug_message (
                           'ERREUR => '
                        || pv_errbuf
                        || ' -> '
                        || dka_sarrefac_tmp_rec.transaction_source
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.expenditure_item_id)
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.event_id)
                    );
                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
            END; -- Fin pre-traitement record
        END LOOP;


        -- Rejet des lignes sans centre de gestion
        UPDATE dka_sarrefac_tmp dst
        SET    dst.transfer_status_code = 'R',
               dst.transfer_rejection_reason = 'Impossible de déterminer le centre de gestion',
               dst.last_update_date = SYSDATE,
               dst.last_updated_by = gn_user_id,
               dst.last_update_login = gn_login_id,
               dst.request_id = gn_conc_request_id
        WHERE      dst.transfer_status_code = 'P'
               AND (   dst.from_acct_center IS NULL
                    OR dst.to_acct_center IS NULL
                   );

        Dka_Tools_Pkg.put_debug_message ('- get_acct_areas (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END get_acct_areas;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_TRX_NUMBERS
--  Description   : Détermine le numéro de facture
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_trx_numbers (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        e_error           EXCEPTION;
        vv_trx_number     ra_customer_trx_all.trx_number%TYPE;

        CURSOR trx_numbers_cur
        IS
            SELECT DISTINCT dst.from_org_id ar_org_id,
                            dst.from_acct_center ar_from_acct_center,
                            dst.from_org_name ar_from_org_name,
                            dst.to_acct_center ar_to_acct_center,
                            dst.to_org_name ar_to_org_name
            FROM            dka_sarrefac_tmp dst
            WHERE               dst.transaction_source = gv_expenditure_source
                            AND dst.transfer_status_code = 'P'
            UNION
            SELECT DISTINCT dst.to_org_id ar_org_id,
                            dst.to_acct_center ar_from_acct_center,
                            dst.to_org_name ar_from_org_name,
                            dst.from_acct_center ar_to_acct_center,
                            dst.from_org_name ar_to_org_name
            FROM            dka_sarrefac_tmp dst
            WHERE               dst.transaction_source = gv_event_source
                            AND dst.transfer_status_code = 'P';

        trx_numbers_rec   trx_numbers_cur%ROWTYPE;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- get_trx_numbers (+)');

        FOR trx_numbers_rec IN trx_numbers_cur LOOP

            -- Récupération du numéro de facture
            BEGIN
                SELECT gv_trx_number_beginning || LTRIM (TO_CHAR ((dstn.last_trx_number + 1), '0000000'))
                INTO   vv_trx_number
                FROM   dka_sarrefac_trx_numbers_all dstn;

                UPDATE dka_sarrefac_trx_numbers_all dstn
                SET    dstn.last_trx_number = (dstn.last_trx_number + 1),
                       dstn.last_update_date = SYSDATE,
                       dstn.last_updated_by = gn_user_id,
                       dstn.last_update_login = gn_login_id,
                       dstn.request_id = gn_conc_request_id;

            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    -- La société n'a jamais créé de facture de Refac, il faut donc créer la ligne
                    INSERT INTO dka_sarrefac_trx_numbers_all
                                (last_trx_number,
                                 org_name,
                                 org_id,
                                 creation_date,
                                 created_by,
                                 last_update_date,
                                 last_updated_by,
                                 last_update_login,
                                 request_id
                                )
                        SELECT 100000, -- 1, -- RBE artf2098415
                               'xxxx', -- PHENIX 2004
                               0, -- PHENIX 2004
                               SYSDATE,
                               gn_user_id,
                               SYSDATE,
                               gn_user_id,
                               gn_login_id,
                               gn_conc_request_id
                        FROM   dual;

                    vv_trx_number    := gv_trx_number_beginning || LTRIM (TO_CHAR (100000, '0000000')); -- RBE artf2098415
            END;

            -- Mise a jour des lignes dans les tables temporaires
            UPDATE dka_sarrefac_tmp dst
            SET    dst.invoice_number = vv_trx_number
            WHERE     (    dst.transaction_source = gv_expenditure_source
                       AND dst.transfer_status_code = 'P'
                       AND dst.from_org_id = trx_numbers_rec.ar_org_id
                       AND dst.from_acct_center = trx_numbers_rec.ar_from_acct_center
                       AND dst.from_org_name = trx_numbers_rec.ar_from_org_name
                       AND dst.to_acct_center = trx_numbers_rec.ar_to_acct_center
                       AND dst.to_org_name = trx_numbers_rec.ar_to_org_name
                      )
                   OR (    dst.transaction_source = gv_event_source
                       AND dst.transfer_status_code = 'P'
                       AND dst.to_org_id = trx_numbers_rec.ar_org_id
                       AND dst.to_acct_center = trx_numbers_rec.ar_from_acct_center
                       AND dst.to_org_name = trx_numbers_rec.ar_from_org_name
                       AND dst.from_acct_center = trx_numbers_rec.ar_to_acct_center
                       AND dst.from_org_name = trx_numbers_rec.ar_to_org_name
                      );

            --dka_tools_pkg.put_debug_message (
            --       'Société AR '
            --    || trx_numbers_rec.ar_from_org_name
            --    || ' Facture '
            --    || vv_trx_number
            --    || ' : '
            --    || TO_CHAR (SQL%ROWCOUNT)
            --    || ' lignes'
            --);

        END LOOP;


        -- Rejet des lignes sans numero de facture
        UPDATE dka_sarrefac_tmp dst
        SET    dst.transfer_status_code = 'R',
               dst.transfer_rejection_reason = 'Impossible de déterminer le numéro de facture',
               dst.last_update_date = SYSDATE,
               dst.last_updated_by = gn_user_id,
               dst.last_update_login = gn_login_id,
               dst.request_id = gn_conc_request_id
        WHERE      dst.transfer_status_code = 'P'
               AND dst.invoice_number IS NULL;

        Dka_Tools_Pkg.put_debug_message ('- get_trx_numbers (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := cv_program_code || pv_errbuf;
            pn_retcode    := 2;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);

        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);

    END get_trx_numbers;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_CUSTOMERS
--  Description   : Détermine les informations clients
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_customers (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        e_error         EXCEPTION;

        CURSOR customers_cur
        IS
            SELECT   v.org_name org_name,
                     v.acct_center acct_center,
                     v.org_id org_id,
                     hou.NAME soc,
                     SUM (v.nb_lignes) nb_lignes
            FROM     (SELECT   dst.to_acct_center||dst.to_org_name org_name,
                               dst.from_acct_center acct_center,
                               dst.from_org_id org_id,
                               dst.transaction_source transaction_source,
                               COUNT (1) nb_lignes
                      FROM     dka_sarrefac_tmp dst
                      WHERE        dst.transaction_source = gv_expenditure_source
                               AND dst.transfer_status_code = 'P'
                      GROUP BY dst.to_acct_center||dst.to_org_name,
                               dst.from_acct_center,
                               dst.from_org_id,
                               dst.transaction_source
                      UNION ALL
                      SELECT   dst.from_acct_center||dst.from_org_name org_name,
                               dst.to_acct_center acct_center,
                               dst.to_org_id org_id,
                               dst.transaction_source transaction_source,
                               COUNT (1) nb_lignes
                      FROM     dka_sarrefac_tmp dst
                      WHERE        dst.transaction_source = gv_event_source
                               AND dst.transfer_status_code = 'P'
                      GROUP BY dst.from_acct_center||dst.from_org_name,
                               dst.to_acct_center,
                               dst.to_org_id,
                               dst.transaction_source) v,
                     hr_all_organization_units hou
            WHERE    hou.organization_id = v.org_id
            GROUP BY v.org_name,
                     v.acct_center,
                     hou.NAME,
                     v.org_id;

        customers_rec   customers_cur%ROWTYPE;
        vn_count        NUMBER (22);
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- get_customers (+)');
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        vn_count      := 0;

        FOR customers_rec IN customers_cur LOOP

            vn_count   := vn_count + 1;

            DECLARE
                rec_error                EXCEPTION;
                vv_errbuf                VARCHAR2 (500);
                vn_retcode               NUMBER (22)                         := 0;
                vn_customer_id           ra_customers.customer_id%TYPE;
                vn_customer_number       ra_customers.customer_number%TYPE;
                vn_customer_site_id      AR_ADDRESSES_V.party_site_id%TYPE;
                vn_bill_to_site_use_id   ra_site_uses_all.site_use_id%TYPE;
                vv_interco               hz_cust_acct_sites_all.attribute8%TYPE;

            BEGIN
                -- Détermination client partenaire
                dka_ar_tools_pkg.get_customer_partner (
                    pv_orgname                     => customers_rec.org_name,
                    pn_org_id                      => customers_rec.org_id,
                    pn_customer_id                 => vn_customer_id,
                    pv_customer_number             => vn_customer_number,
                    pn_customer_site_id            => vn_customer_site_id,
                    pn_bill_to_site_use_id         => vn_bill_to_site_use_id,
                    pv_interco                     => vv_interco,
                    pv_errbuf                      => vv_errbuf,
                    pn_retcode                     => vn_retcode
                );
                IF      vn_retcode != 0
                THEN
                    vv_errbuf    := (   'ERREUR lors de la recherche du client partenaire '
                                     || customers_rec.org_name
                                     || ' : '
                                     || vv_errbuf
                                    );
                    Dka_Tools_Pkg.put_debug_message ('>>> '|| vv_errbuf);
                    RAISE rec_error;
                END IF;
                -- Mise a jour de la table de travail Refac
                UPDATE dka_sarrefac_tmp dst
                SET    dst.customer_id = vn_customer_id,
                       dst.customer_site_id = vn_customer_site_id,
                       dst.interco = vv_interco,
                       dst.last_update_date = SYSDATE,
                       dst.last_updated_by = gn_user_id,
                       dst.last_update_login = gn_login_id,
                       dst.request_id = gn_conc_request_id
                WHERE     (    dst.to_acct_center||dst.to_org_name = customers_rec.org_name
                           AND dst.from_acct_center = customers_rec.acct_center
                           AND dst.from_org_id = customers_rec.org_id
                           AND dst.transaction_source = gv_expenditure_source
                           AND dst.transfer_status_code = 'P'
                          )
                       OR (    dst.from_acct_center||dst.from_org_name = customers_rec.org_name
                           AND dst.to_acct_center = customers_rec.acct_center
                           AND dst.to_org_id = customers_rec.org_id
                           AND dst.transaction_source = gv_event_source
                           AND dst.transfer_status_code = 'P'
                          );
                IF SQL%ROWCOUNT != customers_rec.nb_lignes
                THEN
                    pv_errbuf    :=    'ERREUR sur le nombre de lignes mises a jour pour les sites clients'
                                    || CHR (10)
                                    || '>>> org_name = ' || customers_rec.org_name
                                    || ' | acct_area = ' || customers_rec.acct_center
                                    || ' | org_id = ' || TO_CHAR (customers_rec.org_id)
                                    || ' | nb_lignes = ' || TO_CHAR (customers_rec.nb_lignes);
                    RAISE e_error;
                END IF;
            EXCEPTION
                WHEN rec_error
                THEN
                    -- Mise a jour de la table de travail Refac
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = SUBSTR (vv_errbuf, 1, 240),
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE     (    dst.to_acct_center||dst.to_org_name = customers_rec.org_name
                               AND dst.from_acct_center = customers_rec.acct_center
                               AND dst.from_org_id = customers_rec.org_id
                               AND dst.transaction_source = gv_expenditure_source
                               AND dst.transfer_status_code = 'P'
                              )
                           OR (    dst.from_acct_center||dst.from_org_name = customers_rec.org_name
                               AND dst.to_acct_center = customers_rec.acct_center
                               AND dst.to_org_id = customers_rec.org_id
                               AND dst.transaction_source = gv_event_source
                               AND dst.transfer_status_code = 'P'
                              );

                    IF SQL%ROWCOUNT != customers_rec.nb_lignes
                    THEN
                        pv_errbuf    :=    'ERREUR sur le nombre de lignes mises a jour pour les sites clients'
                                        || CHR (10)
                                        || '>>> org_name = ' || customers_rec.org_name
                                        || ' | acct_area = ' || customers_rec.acct_center
                                        || ' | org_id = ' || TO_CHAR (customers_rec.org_id)
                                        || ' | nb_lignes = ' || TO_CHAR (customers_rec.nb_lignes);
                        RAISE e_error;
                    END IF;

                WHEN OTHERS
                THEN
                    vv_errbuf    := SUBSTR (('Détermination client : '|| SQLERRM), 1, 240);
                    -- Mise a jour de la table de travail Refac
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = vv_errbuf,
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE     (    dst.to_acct_center||dst.to_org_name = customers_rec.org_name
                               AND dst.from_acct_center = customers_rec.acct_center
                               AND dst.from_org_id = customers_rec.org_id
                               AND dst.transaction_source = gv_expenditure_source
                               AND dst.transfer_status_code = 'P'
                              )
                           OR (    dst.from_acct_center||dst.from_org_name = customers_rec.org_name
                               AND dst.to_acct_center = customers_rec.acct_center
                               AND dst.to_org_id = customers_rec.org_id
                               AND dst.transaction_source = gv_event_source
                               AND dst.transfer_status_code = 'P'
                              );

                    IF SQL%ROWCOUNT != customers_rec.nb_lignes
                    THEN
                        pv_errbuf    :=    'ERREUR sur le nombre de lignes mises a jour pour les sites clients'
                                        || CHR (10)
                                        || '>>> org_name = ' || customers_rec.org_name
                                        || ' | acct_area = ' || customers_rec.acct_center
                                        || ' | org_id = ' || TO_CHAR (customers_rec.org_id)
                                        || ' | nb_lignes = ' || TO_CHAR (customers_rec.nb_lignes);
                        RAISE e_error;
                    END IF;
            END;
        END LOOP;

        Dka_Tools_Pkg.put_debug_message ('Nb sites clients calculés : ' || TO_CHAR (vn_count));

        -- Rejet des lignes sans client
        UPDATE dka_sarrefac_tmp dst
        SET    dst.transfer_status_code = 'R',
               dst.transfer_rejection_reason = 'Impossible de déterminer le site client',
               dst.last_update_date = SYSDATE,
               dst.last_updated_by = gn_user_id,
               dst.last_update_login = gn_login_id,
               dst.request_id = gn_conc_request_id
        WHERE      dst.transfer_status_code = 'P'
               AND (   dst.customer_id IS NULL
                    OR dst.customer_site_id IS NULL
                   );

        Dka_Tools_Pkg.put_debug_message ('Nb lignes sans client : ' || TO_CHAR (SQL%ROWCOUNT));
        Dka_Tools_Pkg.put_debug_message ('- get_customers (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := 'get_customers : ' || pv_errbuf;
            pn_retcode    := 2;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
        WHEN OTHERS
        THEN
            pv_errbuf     := 'get_customers : ' || SQLERRM;
            pn_retcode    := SQLCODE;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
    END get_customers;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_VENDORS
--  Description   : Détermine les informations fournisseurs
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_vendors (
        pv_errbuf     OUT      VARCHAR2,
        pn_retcode    OUT      NUMBER,
        pd_ref_date   IN       DATE
    )
    IS
        e_error       EXCEPTION;

        CURSOR vendors_cur
        IS
            SELECT   v.societe societe, -- STE A REMBOURSER --modif TB -- YWA artf2159826
                     v.acct_center acct_center,
                     v.org_id org_id, -- STE A FACTURER --modif TB -- YWA artf2159826
                     hou.NAME soc, -- STE A FACTURER --modif TB -- YWA artf2159826
                     SUM (v.nb_lignes) nb_lignes
            FROM     (SELECT    dst.from_acct_center||dst.from_org_name societe,  --modif TB -- YWA artf2159826 : supp commentaire
                               dst.to_acct_center acct_center,
                               dst.to_org_id org_id,
                               COUNT (1) nb_lignes
                      FROM     dka_sarrefac_tmp dst
                      WHERE        dst.transaction_source = gv_expenditure_source
                               AND dst.transfer_status_code = 'P'
                      GROUP BY dst.from_acct_center||dst.from_org_name, --modif TB -- YWA artf2159826 : supp commentaire
                               dst.to_acct_center,
                               dst.to_org_id
                      UNION ALL -- OBE artf2222202
                      SELECT   dst.to_acct_center||dst.to_org_name societe, --modif TB -- YWA artf2159826 : supp commentaire
                               dst.from_acct_center acct_center,
                               dst.from_org_id org_id,
                               COUNT (1) nb_lignes
                      FROM     dka_sarrefac_tmp dst
                      WHERE        dst.transaction_source = gv_event_source
                               AND dst.transfer_status_code = 'P'
                      GROUP BY  dst.to_acct_center||dst.to_org_name, --modif TB -- YWA artf2159826 : supp commentaire
                               dst.from_acct_center,
                               dst.from_org_id) v,
                     hr_all_organization_units hou
            WHERE    hou.organization_id = v.org_id
            GROUP BY v.societe,
                     v.acct_center,
                     hou.NAME,
                     v.org_id;

        vn_count      NUMBER (22);
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- get_vendors (+)');
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        vn_count   := 0;

        FOR vendors_rec IN vendors_cur LOOP

            vn_count   := vn_count + 1;

            DECLARE
                rec_error           EXCEPTION;
                vv_errbuf           VARCHAR2 (500);
                vn_retcode          NUMBER (22)                               := 0;
                vn_vendor_id        po_vendors.vendor_id%TYPE;
                vn_vendor_site_id   po_vendor_sites_all.vendor_site_id%TYPE;
            BEGIN
                Dka_Tools_Pkg.put_debug_message ('Parametres get_vendor_partner');
                Dka_Tools_Pkg.put_debug_message (' STE_A_REMB ' || vendors_rec.societe); --modif TB -- YWA artf2159826 -- YWA artf2093206
                Dka_Tools_Pkg.put_debug_message (' STE_A_FACT ' || vendors_rec.org_id); --modif TB -- YWA artf2159826 -- YWA artf2093206

                DKA_AP_TOOLS_PKG.GET_VENDOR_PARTNER (
                    pv_code_societe                => vendors_rec.societe, --modif TB -- YWA artf2159826 vendors_rec.soc, -- YWA artf2093206
                    pn_org_id                      => vendors_rec.org_id,
                    pn_vendor_id                   => vn_vendor_id,
                    pn_vendor_site_id              => vn_vendor_site_id,
                    pv_errbuf                      => vv_errbuf,
                    pn_retcode                     => vn_retcode
                );

                IF NVL (vn_retcode, 1) = 2 THEN
                  Dka_Tools_Pkg.put_debug_message (vv_errbuf);
                  RAISE rec_error;
                END IF;

                -- Mise a jour de la table de travail Refac
                UPDATE dka_sarrefac_tmp dst
                SET    dst.vendor_id = vn_vendor_id,
                       dst.vendor_site_id = vn_vendor_site_id,
                       dst.last_update_date = SYSDATE,
                       dst.last_updated_by = gn_user_id,
                       dst.last_update_login = gn_login_id,
                       dst.request_id = gn_conc_request_id
                WHERE     (    dst.from_acct_center||dst.from_org_name = vendors_rec.societe  --modif TB -- YWA artf2159826 : supp commentaire
                           AND dst.to_acct_center = vendors_rec.acct_center
                           AND dst.to_org_id = vendors_rec.org_id
                           AND dst.transaction_source = gv_expenditure_source
                           AND dst.transfer_status_code = 'P'
                          )
                       OR (    dst.to_acct_center||dst.to_org_name = vendors_rec.societe --modif TB -- YWA artf2159826 : supp commentaire
                           AND dst.from_acct_center = vendors_rec.acct_center
                           AND dst.from_org_id = vendors_rec.org_id
                           AND dst.transaction_source = gv_event_source
                           AND dst.transfer_status_code = 'P'
                          );
            EXCEPTION
                WHEN rec_error
                THEN
                    -- Mise a jour de la table de travail Refac
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = SUBSTR (vv_errbuf, 1, 240),
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE     (    dst.from_acct_center||dst.from_org_name = vendors_rec.societe --modif TB -- YWA artf2159826 : supp commentaire
                               AND dst.to_acct_center = vendors_rec.acct_center
                               AND dst.to_org_id = vendors_rec.org_id
                               AND dst.transaction_source = gv_expenditure_source
                               AND dst.transfer_status_code = 'P'
                              )
                           OR (    dst.to_acct_center||dst.to_org_name = vendors_rec.societe --modif TB -- YWA artf2159826 : supp commentaire
                               AND dst.from_acct_center = vendors_rec.acct_center
                               AND dst.from_org_id = vendors_rec.org_id
                               AND dst.transaction_source = gv_event_source
                               AND dst.transfer_status_code = 'P'
                              );

                    IF SQL%ROWCOUNT != vendors_rec.nb_lignes
                    THEN
                        pv_errbuf    := 'ERREUR sur le nombre de lignes mises a jour pour les sites fournisseur';
                        RAISE e_error;
                    END IF;

                WHEN OTHERS
                THEN
                    vv_errbuf    := SUBSTR (('Détermination fournisseur : '|| SQLERRM), 1, 240);

                    -- Mise a jour de la table de travail Refac
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = vv_errbuf,
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE     (    dst.from_acct_center||dst.from_org_name = vendors_rec.societe --modif TB -- YWA artf2159826 : supp commentaire
                               AND dst.to_acct_center = vendors_rec.acct_center
                               AND dst.to_org_id = vendors_rec.org_id
                               AND dst.transaction_source = gv_expenditure_source
                               AND dst.transfer_status_code = 'P'
                              )
                           OR (    dst.to_acct_center||dst.to_org_name = vendors_rec.societe --modif TB -- YWA artf2159826 : supp commentaire
                               AND dst.from_acct_center = vendors_rec.acct_center
                               AND dst.from_org_id = vendors_rec.org_id
                               AND dst.transaction_source = gv_event_source
                               AND dst.transfer_status_code = 'P'
                              );

                    IF SQL%ROWCOUNT != vendors_rec.nb_lignes
                    THEN
                        pv_errbuf    := 'ERREUR sur le nombre de lignes mises a jour pour les sites fournisseur';
                        RAISE e_error;
                    END IF;
            END;
        END LOOP;

        Dka_Tools_Pkg.put_debug_message ('Nb sites fournisseur calculés : ' || TO_CHAR (vn_count));

        -- Rejet des lignes sans fournisseur
        UPDATE dka_sarrefac_tmp dst
        SET    dst.transfer_status_code = 'R',
               dst.transfer_rejection_reason = 'Impossible de déterminer le site fournisseur',
               dst.last_update_date = SYSDATE,
               dst.last_updated_by = gn_user_id,
               dst.last_update_login = gn_login_id,
               dst.request_id = gn_conc_request_id
        WHERE      dst.transfer_status_code = 'P'
               AND (   dst.vendor_id IS NULL
                    OR dst.vendor_site_id IS NULL
                   );

        Dka_Tools_Pkg.put_debug_message ('Nb lignes sans fournisseur : ' || TO_CHAR (SQL%ROWCOUNT));
        Dka_Tools_Pkg.put_debug_message ('- get_vendors (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := 'get_vendors : ' || pv_errbuf;
            pn_retcode    := 2;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);

        WHEN OTHERS
        THEN
            pv_errbuf     := 'get_vendors : ' || SQLERRM;
            pn_retcode    := SQLCODE;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);

    END get_vendors;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CREATE_AP_DATA
--  Description   : Alimente la table DKA_SARREFAC_AP_INV_INTERFACE
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE create_ap_data (
        pv_errbuf                  OUT      VARCHAR2,
        pn_retcode                 OUT      NUMBER,
        pv_invoice_num             IN       VARCHAR2,
        pn_org_id                  IN       NUMBER,
        pv_org_name                IN       VARCHAR2,
        pv_acct_area               IN       VARCHAR2,
        pn_vendor_id               IN       NUMBER,
        pn_vendor_site_id          IN       NUMBER,
        pd_gl_date                 IN       DATE,
        pn_amount                  IN       NUMBER,
        pv_description             IN       VARCHAR2,
        pn_project_id              IN       NUMBER,
        pn_task_id                 IN       NUMBER,
        pv_expenditure_type        IN       VARCHAR2,
        pd_expenditure_item_date   IN       DATE,
        pn_expenditure_quantity    IN       NUMBER,
        pn_expenditure_org_id      IN       NUMBER,
        pv_orig_txn_source         IN       VARCHAR2,
        pn_orig_txn_id             IN       NUMBER,
        pv_create_ar_data_flag     IN       VARCHAR2,
        pn_invoice_id              OUT      NUMBER,
        pn_line_number             OUT      NUMBER,
        pv_doc_category_code       IN       VARCHAR2
    )
    IS
        vn_group_id                      ap_invoices_interface.GROUP_ID%TYPE;
        vn_expenditure_org_name          hr_all_organization_units.NAME%TYPE;
        vn_expenditure_organization_id   hr_all_organization_units.organization_id%TYPE;
        vv_currency_code                 fnd_currencies.currency_code%TYPE;

        vv_step                          VARCHAR2 (20);
        e_error                          EXCEPTION;

        vn_conc_segments VARCHAR2(2000);

    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - create_ap_data (+)');
        Dka_Tools_Pkg.put_debug_message ('Société / Région : ' || pv_org_name || ' / ' || pv_acct_area);
        vv_step                    := 'CREATE_AP_DATA - 00';


        vv_step := 'CREATE_AP_DATA - 01';

        --INIT
        pn_line_number    := 1;

        -- Recherche de group_id
        BEGIN
            SELECT dsaii.GROUP_ID
            INTO   vn_group_id
            FROM   dka_sarrefac_ap_inv_interface dsaii
            WHERE      dsaii.org_id = pn_org_id
                   AND ROWNUM = 1;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                SELECT ap_interface_groups_s.NEXTVAL
                INTO   vn_group_id
                FROM   DUAL;
        END;

        vv_step                    := 'CREATE_AP_DATA - 02';

        -- Recherche de invoice_id, term_id
        BEGIN
            SELECT   dsaii.invoice_id,
                     (MAX (dsaii.line_number) + 1
                     )
            INTO     pn_invoice_id,
                     pn_line_number
            FROM     dka_sarrefac_ap_inv_interface dsaii
            WHERE        dsaii.invoice_num = pv_invoice_num
                     AND dsaii.vendor_id = pn_vendor_id
                     AND dsaii.vendor_site_id = pn_vendor_site_id
            GROUP BY dsaii.invoice_id;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                vv_step           := 'CREATE_AP_DATA - 03';

                SELECT ap_invoices_interface_s.NEXTVAL
                INTO   pn_invoice_id
                FROM   DUAL;

                pn_line_number    := 1;

                vv_step           := 'CREATE_AP_DATA - 04';
        END;

        vv_step                    := 'CREATE_AP_DATA - 05';
        Pa_Currency.G_org_id := pn_org_id;
        vv_currency_code     := Pa_Currency.get_currency_code;


        vv_step                    := 'CREATE_AP_DATA - 06';

        -- Insertion de la ligne
        INSERT INTO dka_sarrefac_ap_inv_interface
                    (invoice_id,
                     invoice_num,
                     invoice_type_lookup_code,
                     org_id,
                     vendor_id,
                     vendor_site_id,
                     SOURCE,
                     GROUP_ID,
                     payment_cross_rate,
                     gl_date,
                     invoice_currency_code,
                     term_id,
                     line_number,
                     line_type_lookup_code,
                     line_amount,
                     description,
                     tax_code,
                     project_id,
                     task_id,
                     ap_expenditure_type,
                     expenditure_item_date,
                     expenditure_organization_id,
                     expenditure_quantity,
                     orig_transaction_source,
                     orig_transaction_id,
                     created_by,
                     creation_date,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     request_id,
                     transfer_status_code,
                     transfer_rejection_reason,
                     doc_category_code
                    )
        VALUES      (pn_invoice_id, -- Invoice_Id
                     pv_invoice_num, -- Invoice_Num
                     NULL,  -- Invoice_Type_Lookup_Code
                     pn_org_id, -- Org_Id
                     pn_vendor_id, -- Vendor_Id
                     pn_vendor_site_id, -- Vendor_Site_Id
                     gv_ap_source, -- Source
                     vn_group_id, -- Group_Id
                     1, -- Payment_Cross_Rate
                     pd_gl_date, -- Gl_Date
                     vv_currency_code, -- Invoice_Currency_Code
                     gn_ap_term_id, -- Term_Id
                     pn_line_number, -- Line_Number
                     gv_ap_line_type_line, -- Line_Type_Lookup_Code
                     pn_amount, -- Line_Amount
                     pv_description, -- Description
                     gv_tax_code_ded, -- Tax_Code
                     pn_project_id, -- Project_Id
                     pn_task_id, -- Task_Id
                     pv_expenditure_type, -- AP_Expenditure_Type
                     pd_expenditure_item_date, -- Expenditure_Item_Date
                     pn_expenditure_org_id, -- Expenditure_Organization_Id
                     pn_expenditure_quantity, -- Expenditure_Quantity
                     pv_orig_txn_source, -- Orig_Transaction_Source
                     pn_orig_txn_id, -- Orig_Transaction_Id
                     gn_user_id, -- Created_By
                     SYSDATE, -- Creation_Date
                     gn_user_id, -- Last_Updated_By
                     SYSDATE, -- Last_Update_Date
                     gn_login_id, -- Last_Update_Login
                     gn_conc_request_id, -- Request_Id
                     'P', -- Transfer_Status_Code
                     NULL, -- Transfer_Rejection_Reason
                     pv_doc_category_code
                    );

        Dka_Tools_Pkg.put_debug_message ('- - create_ap_data (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || vv_step || ' -> ' || pv_errbuf;
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || vv_step || ' -> ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END create_ap_data;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CREATE_AR_DATA
--  Description   : Alimente la table DKA_SARREFAC_AR_TRX_INTERFACE
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE create_ar_data (
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pv_trx_number            IN       VARCHAR2,
        pn_org_id                IN       NUMBER,
        pv_description           IN       VARCHAR2,
        pn_amount                IN       NUMBER,
        pn_bill_to_customer_id   IN       NUMBER,
        pn_bill_to_address_id    IN       NUMBER,
        pv_interco               IN       VARCHAR2,
        pn_term_id               IN       NUMBER,
        pd_trx_date              IN       DATE,
        pd_gl_date               IN       DATE,
        pv_to_acct_area          IN       VARCHAR2,
        pv_to_company_name       IN       VARCHAR2,
        pv_from_acct_area        IN       VARCHAR2,
        pv_from_company_name     IN       VARCHAR2,
        pn_project_id            IN       NUMBER,
        pn_task_id               IN       NUMBER,
        pv_event_type            IN       VARCHAR2,
        pv_orig_txn_type         IN       VARCHAR2,
        pn_orig_txn_id           IN       NUMBER,
        pn_ap_line_number        IN       NUMBER,
        pv_create_ap_data_flag   IN       VARCHAR2,
        pv_cust_trx_type         IN       VARCHAR2
    )
    IS
        cv_tax_exempt_flag   ra_interface_lines_all.tax_exempt_flag%TYPE             := 'R';
        vn_tax_amount        NUMBER (22, 5);
        vn_revenue_ccid      gl_code_combinations.code_combination_id%TYPE;
        vn_tax_ccid          gl_code_combinations.code_combination_id%TYPE;
        vv_line_attribute2   ra_interface_lines_all.interface_line_attribute1%TYPE;
        vv_tax_attribute2    ra_interface_lines_all.interface_line_attribute2%TYPE;
        vv_attribute1        ra_interface_lines_all.interface_line_attribute1%TYPE;
        vv_step              VARCHAR2 (20);
        vv_segment1          gl_code_combinations.segment1%TYPE;
        vv_segment2          gl_code_combinations.segment2%TYPE;
        vv_segment3          gl_code_combinations.segment3%TYPE;
        vv_segment4          gl_code_combinations.segment4%TYPE;
        vv_segment5          gl_code_combinations.segment5%TYPE;
        vv_segment6          gl_code_combinations.segment6%TYPE;
        vv_segment7          gl_code_combinations.segment7%TYPE;
        vv_segment8          gl_code_combinations.segment8%TYPE;
        vv_segment9          gl_code_combinations.segment9%TYPE;
        vv_segment10         gl_code_combinations.segment10%TYPE;
        vv_segment11         gl_code_combinations.segment11%TYPE;
        vv_segment12         gl_code_combinations.segment12%TYPE;
        vn_conc_segments     gl_code_combinations_kfv.concatenated_segments%TYPE;
        vn_rec_ccid          gl_code_combinations.code_combination_id%TYPE;
        vn_nb_lig_rec        NUMBER;
        vv_currency_code     fnd_currencies.currency_code%TYPE;
        vn_tax_account_ccid  zx_accounts.tax_account_ccid%TYPE;

        vn_set_of_books_id   gl_ledgers.ledger_id%TYPE;

        e_error              EXCEPTION;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - create_ar_data (+)');
        vv_step          := 'CREATE_AR_DATA - 00';

        vv_step          := 'CREATE_AR_DATA - 02';
        -- Calcul de attribute1 qui sera le champ "Reference" de la facture: vv_attribute1
        --dka_tools_pkg.put_debug_message (
        --       'Référence : '
        --    || pv_trx_number
        --    || cv_separator
        --    || pv_from_company_name
        --    || cv_separator
        --    || pv_from_acct_area
        --    || cv_separator
        --    || pv_to_company_name
        --    || cv_separator
        --    || pv_to_acct_area
        --);

        vv_attribute1    :=    pv_trx_number
                            || cv_separator
                            || pv_from_company_name
                            || cv_separator
                            || pv_from_acct_area
                            || cv_separator
                            || pv_to_company_name
                            || cv_separator
                            || pv_to_acct_area;
        vv_step          := 'CREATE_AR_DATA - 03';

        -- Calcul des attribute2
        SELECT TO_CHAR (dka_sarrefac_s.NEXTVAL)
        INTO   vv_line_attribute2
        FROM   DUAL;

        SELECT TO_CHAR (dka_sarrefac_s.NEXTVAL)
        INTO   vv_tax_attribute2
        FROM   DUAL;

        -- Calcul du ledger_id
        vv_step                    := 'CREATE_AR_DATA - 05';
        SELECT ledger_id
        INTO vn_set_of_books_id
        FROM gl_ledgers
        WHERE name=  mo_utils.Get_Ledger_Name( pn_org_id );

        vv_step                    := 'CREATE_AR_DATA - 05';
        Pa_Currency.G_org_id := pn_org_id;
        vv_currency_code     := Pa_Currency.get_currency_code;

        vv_step                    := 'CREATE_AR_DATA - 05';
        SELECT za.tax_account_ccid --DECODE(zrb.def_rec_settlement_option_code,'DEFERRED',za.INTERIM_TAX_CCID,za.tax_account_ccid) --RBE artf2154096 -- OBE artf3030545
        INTO vn_tax_account_ccid
        FROM zx_accounts za,zx_rates_b   zrb
        WHERE za.tax_account_entity_id = ZRB.TAX_RATE_ID
        AND za.tax_account_entity_id  = gn_tax_rate_id_coll
        AND za.INTERNAL_ORGANIZATION_ID = pn_org_id;

        -- Calcul du code de taxe et de son taux: vn_tax_id, vn_tax_rate et vn_tax_ccid
        vv_step          := 'CREATE_AR_DATA - 05';
        -- Calcul du montant de la Taxe: vn_tax_amount
        vn_tax_amount    := Pa_Currency.round_trans_currency_amt ((pn_amount * gn_tax_rate_coll / 100), vv_currency_code);
        Dka_Tools_Pkg.put_debug_message ('Montant de la taxe = ' || TO_CHAR(vn_tax_amount) || ' = ' || pn_amount || ' * ' || gn_tax_rate_coll );

        ---------------------------------------------------------
        -- Calcul du ccid de la ligne de Produit: vn_revenue_ccid
        ---------------------------------------------------------

        vv_step          := 'CREATE_AR_DATA - 06';
        -- Récupération Segment1
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (1,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment1,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment1 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment2
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (2,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment2,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment2 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment3
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (3,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment3,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment3 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment4
        vv_segment4 := DKA_SPAAUTOACCOUNTING_PKG.run_cpt_groupe_produit_f ( pn_project_id => pn_project_id,
                                                                            pv_event_type => pv_event_type,
                                                                            pn_task_id    => pn_task_id);

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment4 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        --SEGMENT5
        vv_segment5 := pv_interco;

        IF vv_segment5 IS NULL
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment5 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment6
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (6,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment6,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment6 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment7
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (7,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment7,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment7 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment8
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (8,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment8,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment8 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment9
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (9,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment9,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment9 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment10
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (10,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment10,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment10 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment11
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (11,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment11,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment11 : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        -- Récupération Segment12
        DKA_PA_TOOLS_PKG.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (12,pn_org_id),
            pv_event_type                  => pv_event_type,
            pn_project_id                  => pn_project_id,
            pv_segment_value               => vv_segment12,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération Segment12 : ' || pv_errbuf;
            RAISE e_error;
        END IF;


        -- Détermination du ccid correspondant
        Dka_Tools_Pkg.get_code_combination_id (
            vv_segment1,
            vv_segment2,
            vv_segment3,
            vv_segment4,
            vv_segment5,
            vv_segment6,
            vv_segment7,
            vv_segment8,
            vv_segment9,
            vv_segment10,
            vv_segment11,
            vv_segment12,
            vn_revenue_ccid,
            pv_errbuf,
            pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'AR : Erreur sur récupération vn_revenue_ccid : ' || pv_errbuf;
            RAISE e_error;
        END IF;

        vv_step          := 'CREATE_AR_DATA - 07';
        -- Calcul du ccid de la ligne de Taxe: vn_tax_ccid
        -- Annulé, ce ccid est celui du type de taxe
        vv_step          := 'CREATE_AR_DATA - 08';

        --dka_tools_pkg.put_debug_message ('Insertion des 2 lignes');
        -- Insertion de la ligne HT
        Dka_Tools_Pkg.put_debug_message ('Insertion de la ligne HT->');
        INSERT INTO dka_sarrefac_ar_trx_interface
                    (interface_line_context,
                     interface_line_attribute1,
                     interface_line_attribute2,
                     link_to_line_context,
                     link_to_line_attribute1,
                     link_to_line_attribute2,
                     batch_source_name,
                     set_of_books_id,
                     org_id,
                     line_type,
                     description,
                     currency_code,
                     amount,
                     cust_trx_type_name,
                     term_id,
                     orig_system_bill_customer_id,
                     orig_system_bill_address_id,
                     conversion_type,
                     trx_date,
                     gl_date,
                     trx_number,
                     tax_exempt_flag,
                     tax_code,
                     code_combination_id,
                     account_class,
                     project_id,
                     task_id,
                     ar_event_type,
                     attribute13,
                     attribute14,
                     attribute15,
                     created_by,
                     creation_date,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     request_id,
                     transfer_status_code,
                     transfer_rejection_reason
                    )
        VALUES      (gv_ar_interface_line_context, -- Interface_Line_Context
                     vv_attribute1, -- Interface_Line_Attribute1
                     vv_line_attribute2, -- Interface_Line_Attribute2
                     NULL, -- Link_To_Line_Context
                     NULL, -- Link_To_Line_Attribute1
                     NULL, -- Link_To_Line_Attribute2
                     gv_ar_batch_source, -- Batch_Source_Name
                     vn_set_of_books_id, -- Set_Of_Books_Id
                     pn_org_id, -- Org_Id
                     gv_ar_line_type_line, -- Line_Type
                     pv_description, -- Description
                     vv_currency_code, -- Currency_Code
                     pn_amount, -- Amount
                     pv_cust_trx_type, -- Cust_Trx_Type_Name
                     pn_term_id, -- Term_Id
                     pn_bill_to_customer_id, -- Orig_System_Bill_Customer_Id
                     pn_bill_to_address_id, -- Orig_System_Bill_Address_Id
                     gv_conversion_type, -- Conversion_Type
                     pd_trx_date, -- Trx_Date (pd_trx_date)
                     pd_gl_date, -- Gl_Date
                     pv_trx_number, -- Trx_Number
                     cv_tax_exempt_flag, -- Tax_Exempt_Flag
                     gv_tax_code_coll, -- Tax_Code
                     vn_revenue_ccid, -- Code_Combination_id
                     'REV', -- Account_Class
                     pn_project_id, -- Project_Id
                     pn_task_id,                           -- Task_Id
                     pv_event_type, -- AR_Event_Type
                     pn_ap_line_number, -- Attribute13
                     pv_orig_txn_type, -- Attribute14
                     TO_CHAR (pn_orig_txn_id), -- Attribute15
                     gn_user_id, -- Created_By
                     SYSDATE, -- Creation_Date
                     gn_user_id, -- Last_Updated_By
                     SYSDATE, -- Last_Update_Date
                     gn_login_id, -- Last_Update_Login
                     gn_conc_request_id, -- Request_Id
                     'P', -- Transfer_Status_Code
                     NULL -- Transfer_Rejection_Reason
                    );
        Dka_Tools_Pkg.put_debug_message ('<-Insertion de la ligne HT');
        vv_step          := 'CREATE_AR_DATA - 09';

        Dka_Tools_Pkg.put_debug_message ('Montant de la taxe = ' || TO_CHAR(vn_tax_amount) || ' = ' || pn_amount || ' * ' || gn_tax_rate_coll );
        -- Insertion de la ligne de Taxe
        Dka_Tools_Pkg.put_debug_message ('Insertion de la ligne de Taxe->');
        INSERT INTO dka_sarrefac_ar_trx_interface
                    (interface_line_context,
                     interface_line_attribute1,
                     interface_line_attribute2,
                     link_to_line_context,
                     link_to_line_attribute1,
                     link_to_line_attribute2,
                     batch_source_name,
                     set_of_books_id,
                     org_id,
                     line_type,
                     description,
                     currency_code,
                     amount,
                     cust_trx_type_name,
                     term_id,
                     orig_system_bill_customer_id,
                     orig_system_bill_address_id,
                     conversion_type,
                     trx_date,
                     gl_date,
                     trx_number,
                     tax_exempt_flag,
                     tax_code,
                     code_combination_id,
                     account_class,
                     project_id,
                     task_id,
                     ar_event_type,
                     attribute14,
                     attribute15,
                     created_by,
                     creation_date,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     request_id,
                     transfer_status_code,
                     transfer_rejection_reason
                    )
        VALUES      (gv_ar_interface_line_context, -- Interface_Line_Context
                     vv_attribute1, -- Interface_Line_Attribute1
                     vv_tax_attribute2, -- Interface_Line_Attribute2
                     gv_ar_interface_line_context, -- Link_To_Line_Context
                     vv_attribute1, -- Link_To_Line_Attribute1
                     vv_line_attribute2, -- Link_To_Line_Attribute2
                     gv_ar_batch_source, -- Batch_Source_Name
                     vn_set_of_books_id, -- Set_Of_Books_Id
                     pn_org_id, -- Org_Id
                     gv_ar_line_type_tax, -- Line_Type
                     pv_description, -- Description
                     vv_currency_code, -- Currency_Code
                     vn_tax_amount, -- Amount
                     pv_cust_trx_type, -- Cust_Trx_Type_Name
                     NULL, -- Term_Id
                     NULL, -- Orig_System_Bill_Customer_Id
                     NULL, -- Orig_System_Bill_Address_Id
                     gv_conversion_type, -- Conversion_Type
                     NULL, -- Trx_Date
                     NULL, -- Gl_Date
                     NULL, -- Trx_Number
                     NULL, -- Tax_Exempt_Flag
                     gv_tax_code_coll, -- Tax_Code
                     vn_tax_account_ccid, -- Code_Combination_id
                     'TAX', -- Account_Class
                     pn_project_id, -- Project_Id
                     pn_task_id,                           -- Task_Id
                     pv_event_type, -- AR_Event_Type
                     NULL, -- Attribute14
                     NULL, -- Attribute15
                     gn_user_id, -- Created_By
                     SYSDATE, -- Creation_Date
                     gn_user_id, -- Last_Updated_By
                     SYSDATE, -- Last_Update_Date
                     gn_login_id, -- Last_Update_Login
                     gn_conc_request_id, -- Request_Id
                     'P', -- Transfer_Status_Code
                     NULL -- Transfer_Rejection_Reason
                    );
        Dka_Tools_Pkg.put_debug_message ('<-Insertion de la ligne de Taxe');

        vv_step          := 'CREATE_AR_DATA - 10';

        -- Insertion de la ligne REC (client)
        -- si elle n existe pas
        SELECT COUNT(1)
        INTO   vn_nb_lig_rec
        FROM   dka_sarrefac_ar_trx_interface
        WHERE  trx_number = pv_trx_number
        AND    account_class = 'REC';

         Dka_Tools_Pkg.put_debug_message ('Insertion de la ligne REC : '||vn_nb_lig_rec);


        IF vn_nb_lig_rec = 0 THEN

          SELECT g.concatenated_segments
            INTO vn_conc_segments
            FROM hz_cust_site_uses_all h, gl_code_combinations_kfv g
           WHERE 1 = 1
             AND g.code_combination_id = h.gl_id_rec
             AND h.cust_acct_site_id = pn_bill_to_address_id
             AND h.site_use_code = 'BILL_TO';

          Dka_Tools_Pkg.get_code_combination_id (pv_segment1            => pv_from_company_name,
                                                 pv_segment2            => pv_from_acct_area,
                                                 pv_segment3            => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,2)+1,INSTR(vn_conc_segments,'.',1,3)-INSTR(vn_conc_segments,'.',1,2)-1),
                                                 pv_segment4            => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,3)+1,INSTR(vn_conc_segments,'.',1,4)-INSTR(vn_conc_segments,'.',1,3)-1),
                                                 pv_segment5            => pv_interco,
                                                 pv_segment6            => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,5)+1,INSTR(vn_conc_segments,'.',1,6)-INSTR(vn_conc_segments,'.',1,5)-1),
                                                 pv_segment7            => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,6)+1,INSTR(vn_conc_segments,'.',1,7)-INSTR(vn_conc_segments,'.',1,6)-1),
                                                 pv_segment8            => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,7)+1,INSTR(vn_conc_segments,'.',1,8)-INSTR(vn_conc_segments,'.',1,7)-1),
                                                 pv_segment9            => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,8)+1,INSTR(vn_conc_segments,'.',1,9)-INSTR(vn_conc_segments,'.',1,8)-1),
                                                 pv_segment10           => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,9)+1,INSTR(vn_conc_segments,'.',1,10)-INSTR(vn_conc_segments,'.',1,9)-1),
                                                 pv_segment11           => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,10)+1,INSTR(vn_conc_segments,'.',1,11)-INSTR(vn_conc_segments,'.',1,10)-1),
                                                 pv_segment12           => SUBSTR(vn_conc_segments,INSTR(vn_conc_segments,'.',1,11)+1),
                                                 pn_code_combination_id => vn_rec_ccid,
                                                 pv_errbuf              => pv_errbuf,
                                                 pn_retcode             => pn_retcode);
          IF pn_retcode != 0
          THEN
              Dka_Tools_Pkg.put_debug_message ('Erreur de récupération de la clé client : ' || pv_errbuf);
              RAISE e_error;
          END IF;

          INSERT INTO dka_sarrefac_ar_trx_interface
                      (interface_line_context,
                       interface_line_attribute1,
                       interface_line_attribute2,
                       batch_source_name,
                       set_of_books_id,
                       org_id,
                       line_type,
                       description,
                       currency_code,
                       cust_trx_type_name,
                       term_id,
                       orig_system_bill_customer_id,
                       orig_system_bill_address_id,
                       conversion_type,
                       trx_date,
                       gl_date,
                       trx_number,
                       tax_exempt_flag,
                       tax_code,
                       code_combination_id,
                       account_class,
                       created_by,
                       creation_date,
                       last_updated_by,
                       last_update_date,
                       last_update_login,
                       request_id,
                       transfer_status_code
                      )
          VALUES      (gv_ar_interface_line_context, -- Interface_Line_Context
                       vv_attribute1, -- Interface_Line_Attribute1
                       vv_line_attribute2, -- Interface_Line_Attribute2
                       gv_ar_batch_source, -- Batch_Source_Name
                       vn_set_of_books_id, -- Set_Of_Books_Id
                       pn_org_id, -- Org_Id
                       gv_ar_line_type_line, -- Line_Type
                       pv_description, -- Description
                       vv_currency_code, -- Currency_Code
                       pv_cust_trx_type, -- Cust_Trx_Type_Name PHENIX 2004 gv_ar_cust_trx_type
                       pn_term_id, -- Term_Id
                       pn_bill_to_customer_id, -- Orig_System_Bill_Customer_Id
                       pn_bill_to_address_id, -- Orig_System_Bill_Address_Id
                       gv_conversion_type, -- Conversion_Type
                       pd_trx_date, -- Trx_Date (pd_trx_date)
                       pd_gl_date, -- Gl_Date
                       pv_trx_number, -- Trx_Number
                       cv_tax_exempt_flag, -- Tax_Exempt_Flag
                       gv_tax_code_coll, -- Tax_Code
                       vn_rec_ccid, -- Code_Combination_id
                       'REC', -- Account_Class
                       gn_user_id, -- Created_By
                       SYSDATE, -- Creation_Date
                       gn_user_id, -- Last_Updated_By
                       SYSDATE, -- Last_Update_Date
                       gn_login_id, -- Last_Update_Login
                       gn_conc_request_id, -- Request_Id
                       'P' -- Transfer_Status_Code
                      );
        END IF;

        Dka_Tools_Pkg.put_debug_message ('- - create_ar_data (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pn_retcode   := 2;
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            Dka_Tools_Pkg.put_debug_message (
                   pd_trx_date
                || ':'
                || pn_org_id
                || ':'
                || gv_tax_code_coll
                || ':'
                || gv_ar_tax_type
                || ':'
                || pv_from_acct_area
                || ':'
                || pv_from_company_name
            );
            pv_errbuf     := cv_program_code || vv_step || ' -> ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END create_ar_data;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CREATE_DATA_FOR_NON_OA_SOC
--  Description   : Alimente la table DKA_SARREFAC_TRX_NON_OA_SOC
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE create_data_for_non_oa_soc (
        pv_errbuf                OUT      VARCHAR2,
        pn_retcode               OUT      NUMBER,
        pd_ref_date              IN       DATE,
        pv_trx_number            IN       VARCHAR2,
        pd_trx_date              IN       DATE,
        pv_created_in_ap_flag    IN       VARCHAR2,
        pv_created_in_ar_flag    IN       VARCHAR2,
        pv_pa_txn_type           IN       VARCHAR2,
        pn_pa_txn_id             IN       NUMBER,
        pn_ap_org_id             IN       NUMBER,
        pv_ap_org_name           IN       VARCHAR2,
        pv_ap_acct_area          IN       VARCHAR2,
        pn_ap_project_id         IN       NUMBER,
        pn_ap_task_id            IN       NUMBER,
        pv_ap_expenditure_type   IN       VARCHAR2,
        pn_ap_vendor_id          IN       NUMBER,
        pn_ar_org_id             IN       NUMBER,
        pv_ar_org_name           IN       VARCHAR2,
        pv_ar_acct_area          IN       VARCHAR2,
        pn_ar_project_id         IN       NUMBER,
        pn_ar_task_id            IN       NUMBER,
        pv_ar_event_type         IN       VARCHAR2,
        pn_ar_customer_id        IN       NUMBER,
        pn_ar_customer_site_id   IN       NUMBER,
        pn_quantity              IN       NUMBER,
        pn_line_amount           IN       NUMBER
    )
    IS
        vv_ap_acct_segment4        fnd_flex_values.flex_value%TYPE;
        vv_ap_acct_segment4_desc   fnd_flex_values_tl.description%TYPE;
        vv_ap_acct_segment3        fnd_flex_values.flex_value%TYPE;
        vv_ar_acct_segment4        fnd_flex_values.flex_value%TYPE;
        vv_ar_acct_segment3        fnd_flex_values.flex_value%TYPE;
        vn_project_id              pa_projects_all.project_id%TYPE;
        vn_task_id                 pa_tasks.task_id%TYPE;
        vv_project_number          pa_projects_all.segment1%TYPE;
        vv_project_name            pa_projects_all.NAME%TYPE;
        vv_task_number             pa_tasks.task_number%TYPE;
        vv_task_name               pa_tasks.task_name%TYPE;
        vn_quantity                pa_expenditure_items_all.quantity%TYPE;
        vv_exp_type_uom            pa_expenditure_types.unit_of_measure%TYPE;
        vv_trx_reference           ra_interface_lines_all.interface_line_attribute1%TYPE;

        vv_step                    VARCHAR2 (50);
        e_error                    EXCEPTION;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - create_data_for_non_oa_soc (+)');

        vv_step                := 'CREATE_DATA_FOR_NON_OA_SOC - 00';
        pn_retcode             := 0;
        pv_errbuf              := NULL;

        -- Récupération Segment4
        vv_ap_acct_segment4 := DKA_SPAAUTOACCOUNTING_PKG.run_cpt_groupe_couts_f(pn_project_id       => pn_ap_project_id,
                                                                                pv_expenditure_type => pv_ap_expenditure_type,
                                                                                pn_task_id          => pn_ap_task_id
                                                                                );

        IF pn_retcode != 0
        THEN
            pv_errbuf    :=    'ERREUR récupération segment4 AP; project_id='
                            || TO_CHAR (pn_ap_project_id)
                            || '; expn_type='
                            || pv_ap_expenditure_type
                            || '; task_id='
                            || TO_CHAR (pn_ap_task_id)
                            || '; date='
                            || TO_CHAR (pd_ref_date, 'DD/MM/YYYY');
            RAISE e_error;
        END IF;

        SELECT ffv.description
        INTO   vv_ap_acct_segment4_desc
        FROM   fnd_flex_values_vl ffv
        WHERE      ffv.flex_value_set_id = gn_seg4_flex_value_set_id
               AND ffv.flex_value = vv_ap_acct_segment4;

        -- Calcul du segment3 de AP
        vv_step                := 'CREATE_DATA_FOR_NON_OA_SOC - 02';
        vv_ap_acct_segment3 := DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts(
                             pn_project_id       => pn_ap_project_id,
                             pv_expenditure_type => pv_ap_expenditure_type,
                             pn_task_id          => pn_ap_task_id);


        IF vv_ap_acct_segment3 IS NULL THEN
            pv_errbuf    := 'ERREUR récupération segment3 AP; expn_type=' || pv_ap_expenditure_type;
            RAISE e_error;
        END IF;

        -- Récupération Segment4
        vv_ar_acct_segment4 := DKA_SPAAUTOACCOUNTING_PKG.run_cpt_groupe_produit_f ( pn_project_id => pn_ar_project_id,
                                                                            pv_event_type => pv_ar_event_type,
                                                                            pn_task_id    => pn_ar_task_id);

        IF vv_ar_acct_segment4 is null  THEN
            pn_retcode    := 2;
            pv_errbuf     :=    'ERREUR récupération segment4 AR; project_id/task_id='
                             || TO_CHAR (pn_ar_project_id)||'/'||TO_CHAR (pn_ar_task_id)
                             || '; event_type='
                             || pv_ar_event_type
                             || '; date='
                             || TO_CHAR (pd_ref_date, 'DD/MM/YYYY');
            RAISE e_error;
        END IF;

        -- Calcul du segment3 de AR
        vv_step                := 'CREATE_DATA_FOR_NON_OA_SOC - 04';
        Dka_pa_Tools_Pkg.pa_run_accounting_rule (
            pn_rule_id                     => get_rule_id (3,pn_ar_org_id),
            pv_event_type                  => pv_ar_event_type,
            pn_project_id                  => pn_ar_project_id,
            pv_segment_value               => vv_ar_acct_segment3,
            pv_errbuf                      => pv_errbuf,
            pn_retcode                     => pn_retcode
        );

        IF pn_retcode != 0
        THEN
            pv_errbuf    :=
                    'ERREUR récupération segment3 AR; project_id=' || TO_CHAR (pn_ar_project_id) || '; event_type=' || pv_ar_event_type;
            RAISE e_error;
        END IF;


        -- Calcul du projet
        vv_step                := 'CREATE_DATA_FOR_NON_OA_SOC - 05';

        IF pv_pa_txn_type = gv_expenditure_source
        THEN
            vn_project_id    := pn_ap_project_id;
            vn_task_id       := pn_ap_task_id;
        ELSE
            vn_project_id    := pn_ar_project_id;
            vn_task_id       := pn_ar_task_id;
        END IF;

        SELECT pp.segment1,
               pp.NAME,
               pt.task_number,
               pt.task_name
        INTO   vv_project_number,
               vv_project_name,
               vv_task_number,
               vv_task_name
        FROM   pa_projects_all pp,
               pa_tasks pt
        WHERE  pp.project_id = vn_project_id
        and pp.project_id = pt.project_id
        and pt.task_id = vn_task_id;

        -- Calcul de la quantité
        vv_step                := 'CREATE_DATA_FOR_NON_OA_SOC - 06';

        SELECT pet.unit_of_measure
        INTO   vv_exp_type_uom
        FROM   pa_expenditure_types pet
        WHERE  pet.expenditure_type = pv_ap_expenditure_type;

        IF vv_exp_type_uom = 'EUR'
        THEN
            vn_quantity    := NULL;
        ELSE
            vn_quantity    := pn_quantity;
        END IF;

        vv_step                := 'CREATE_DATA_FOR_NON_OA_SOC - 07';

        IF pv_pa_txn_type = gv_expenditure_source
        THEN
            vv_trx_reference    :=    pv_trx_number
                                   || cv_separator
                                   || pv_ar_org_name
                                   || cv_separator
                                   || pv_ar_acct_area
                                   || cv_separator
                                   || pv_ap_org_name
                                   || cv_separator
                                   || pv_ap_acct_area;
        ELSE
            vv_trx_reference    :=    pv_trx_number
                                   || cv_separator
                                   || pv_ap_org_name
                                   || cv_separator
                                   || pv_ap_acct_area
                                   || cv_separator
                                   || pv_ar_org_name
                                   || cv_separator
                                   || pv_ar_acct_area;
        END IF;

        vv_step                := 'CREATE_DATA_FOR_NON_OA_SOC - 08';

        INSERT INTO dka_sarrefac_trx_non_oa_soc
                    (request_id,
                     trx_number,
                     trx_reference,
                     trx_date,
                     created_in_ap_flag,
                     created_in_ar_flag,
                     pa_txn_type,
                     pa_txn_id,
                     ap_org_id,
                     ap_org_name,
                     ap_acct_area,
                     ap_acct_segment3,
                     ap_acct_segment4, -- PHENIX 2004 ap_acct_segment2 -> ap_acct_segment4
                     ap_acct_segment4_description, -- PHENIX 2004 ap_acct_segment2_description -> ap_acct_segment4_description
                     ap_expenditure_type,
                     ap_vendor_id,
                     ar_org_id,
                     ar_org_name,
                     ar_acct_area,
                     ar_acct_segment3,
                     ar_acct_segment4,
                     ar_event_type,
                     ar_customer_id,
                     ar_customer_site_id,
                     project_id,
                     project_number,
                     project_name,
                     task_number,
                     task_name,
                     quantity,
                     line_amount,
                     created_by,
                     creation_date,
                     last_updated_by,
                     last_update_date,
                     last_update_login
                    )
        VALUES      (gn_conc_request_id, --request_id
                     pv_trx_number, --trx_number
                     vv_trx_reference, --trx_reference
                     pd_trx_date, --trx_date
                     pv_created_in_ap_flag, --created_in_ap_flag
                     pv_created_in_ar_flag, --created_in_ar_flag
                     pv_pa_txn_type, --pa_txn_type
                     pn_pa_txn_id, --pa_txn_id
                     pn_ap_org_id, --ap_org_id
                     pv_ap_org_name, --ap_org_name
                     pv_ap_acct_area, --ap_acct_area
                     vv_ap_acct_segment3, --ap_acct_segment3
                     vv_ap_acct_segment4, --ap_acct_segment4
                     vv_ap_acct_segment4_desc, --ap_acct_segment4_description
                     pv_ap_expenditure_type, --ap_expenditure_type
                     pn_ap_vendor_id, --ap_vendor_id
                     pn_ar_org_id, --ar_org_id
                     pv_ar_org_name, --ar_org_name
                     pv_ar_acct_area, --ar_acct_area
                     vv_ar_acct_segment3, --ar_acct_segment3
                     vv_ar_acct_segment4, --ar_acct_segment2
                     pv_ar_event_type, --ar_event_type
                     pn_ar_customer_id, --ar_customer_id
                     pn_ar_customer_site_id, --ar_customer_site_id
                     vn_project_id, --project_id
                     vv_project_number, --project_number
                     vv_project_name, --project_name
                     vv_task_number,
                     vv_task_name,
                     vn_quantity, --quantity
                     pn_line_amount, --line_amount
                     gn_user_id, --created_by,
                     SYSDATE, --creation_date,
                     gn_user_id, --last_updated_by,
                     SYSDATE, --last_update_date,
                     gn_login_id --last_update_login
                    );

        Dka_Tools_Pkg.put_debug_message ('- - create_data_for_non_oa_soc (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := cv_program_code || vv_step || ' -> ' || pv_errbuf;
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || vv_step || ' -> ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END create_data_for_non_oa_soc;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CORRECT_TVA
--  Description   : Corrige les écarts de TVA entre AP et AR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE correct_tva (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        vn_tax_gap               NUMBER (22, 5);

        CURSOR invoice_tax_amount_cur
        IS
            --RBE
--            SELECT tmp.invoice_number trx_number, ap_tax.invoice_id, ar_tax.ar_tax_amount, ap_tax.ap_tax_amount,
--                  ar_tax.org_id ar_org_id, ap_tax.org_id ap_org_id
--             FROM (SELECT   /*+ ORDERED */
--                            dsaii.org_id, dsaii.invoice_id, dsaii.invoice_num, hou.organization_id ar_org_id,
--                            hou_ap.organization_id ap_org_id,
--                            Pa_Currency.round_trans_currency_amt ((SUM (dsaii.line_amount) * gn_tax_rate_ded / 100),
--                                                                  Pa_Currency.get_currency_code
--                                                                 ) ap_tax_amount
--                       FROM dka_sarrefac_ap_inv_interface dsaii,
--                            po_vendors pv,
--                            hr_all_organization_units hou,
--                            hr_all_organization_units hou_ap
--                      WHERE dsaii.line_type_lookup_code = 'ITEM'
--                        AND pv.vendor_id = dsaii.vendor_id
--                        AND hou.NAME = pv.attribute2
--                        --AND hou_ap.NAME = SUBSTR (dsaii.doc_category_code, 1, 4) -- RBE
--                        AND hou_ap.organization_id = dsaii.org_id  -- RBE
--                   GROUP BY dsaii.invoice_id,
--                            dsaii.invoice_num,
--                            dsaii.org_id,
--                            hou.organization_id,
--                            hou_ap.organization_id) ap_tax,
--                  (SELECT   dsati_line.org_id, hou.organization_id ar_org_id, dsati_line.trx_number,
--                            Pa_Currency.round_trans_currency_amt (SUM (dsati_tax.amount), Pa_Currency.get_currency_code) ar_tax_amount
--                       FROM dka_sarrefac_ar_trx_interface dsati_line,
--                            dka_sarrefac_ar_trx_interface dsati_tax,
--                            hr_all_organization_units hou
--                      WHERE dsati_tax.link_to_line_context = dsati_line.interface_line_context
--                        AND dsati_tax.link_to_line_attribute1 = dsati_line.interface_line_attribute1
--                        AND dsati_tax.link_to_line_attribute2 = dsati_line.interface_line_attribute2
--                        --AND hou.NAME = SUBSTR (dsati_line.cust_trx_type_name, 1, 4) --RBE
--                        AND hou.organization_id = dsati_line.org_id  --RBE
--                        AND dsati_tax.line_type = gv_ar_line_type_tax
--                        AND dsati_line.line_type = gv_ar_line_type_line
--                        AND dsati_line.account_class <> 'REC' -- Supprimer la ligne de type client
--                   GROUP BY dsati_line.trx_number, hou.organization_id, dsati_line.org_id) ar_tax,
--                  (SELECT DISTINCT dst.invoice_number,
--                                   DECODE (dst.transaction_source,
--                                           gv_expenditure_source, dst.from_org_id,
--                                           dst.to_org_id
--                                          ) ar_org_id,
--                                   DECODE (dst.transaction_source,
--                                           gv_expenditure_source, dst.to_org_id,
--                                           dst.from_org_id
--                                          ) ap_org_id
--                              FROM dka_sarrefac_tmp dst
--                             WHERE create_ap_data_flag = 'Y'
--                          GROUP BY dst.invoice_number, dst.transaction_source, dst.from_org_id, dst.to_org_id) tmp
--            WHERE 1 = 1
--              AND tmp.ar_org_id = ar_tax.ar_org_id(+)
--              AND tmp.ap_org_id = ap_tax.ap_org_id
--              AND tmp.invoice_number = ap_tax.invoice_num
--              AND tmp.invoice_number = ar_tax.trx_number(+)
--              AND tmp.ar_org_id = ap_tax.ar_org_id;

             SELECT tmp.invoice_number trx_number, ap_tax.invoice_id, ar_tax.ar_tax_amount, ap_tax.ap_tax_amount,
                  ar_tax.org_id ar_org_id, ap_tax.org_id ap_org_id
             FROM (SELECT   /*+ ORDERED */
                            DSAII.ORG_ID, DSAII.INVOICE_ID, DSAII.INVOICE_NUM, AR_DSATI.org_id AR_ORG_ID,
                            --hou_ap.organization_id ap_org_id,
                            dsaii.org_id ap_org_id, --RBE
                            Pa_Currency.round_trans_currency_amt ((SUM (dsaii.line_amount) * gn_tax_rate_ded / 100),
                                                                  Pa_Currency.get_currency_code
                                                                 ) ap_tax_amount
                       FROM DKA_SARREFAC_AP_INV_INTERFACE DSAII,
                            DKA_SARREFAC_AR_TRX_INTERFACE AR_DSATI --RBE
                            --po_vendors pv,
                            --hr_all_organization_units hou,
                            --hr_all_organization_units hou_ap
                      WHERE DSAII.LINE_TYPE_LOOKUP_CODE = 'ITEM'
                        AND AR_DSATI.ACCOUNT_CLASS = 'REC'
                        AND AR_DSATI.TRX_NUMBER = DSAII.INVOICE_NUM
                        --AND pv.vendor_id = dsaii.vendor_id
                        --AND hou.NAME = pv.attribute2
                        --AND hou_ap.NAME = SUBSTR (dsaii.doc_category_code, 1, 4) -- RBE
                        --AND hou_ap.organization_id = dsaii.org_id  -- RBE
                   GROUP BY dsaii.invoice_id,
                            DSAII.INVOICE_NUM,
                            dsaii.org_id,
                            AR_DSATI.org_id) ap_tax,
                  (SELECT   dsati_line.org_id, dsati_line.org_id ar_org_id, dsati_line.trx_number,
                            Pa_Currency.round_trans_currency_amt (SUM (dsati_tax.amount), Pa_Currency.get_currency_code) ar_tax_amount
                       FROM DKA_SARREFAC_AR_TRX_INTERFACE DSATI_LINE,
                            DKA_SARREFAC_AR_TRX_INTERFACE DSATI_TAX--,
                            --hr_all_organization_units hou
                      WHERE dsati_tax.link_to_line_context = dsati_line.interface_line_context
                        AND dsati_tax.link_to_line_attribute1 = dsati_line.interface_line_attribute1
                        AND dsati_tax.link_to_line_attribute2 = dsati_line.interface_line_attribute2
                        --AND hou.NAME = SUBSTR (dsati_line.cust_trx_type_name, 1, 4) --RBE
                        --AND hou.organization_id = dsati_line.org_id  --RBE
                        AND dsati_tax.line_type = gv_ar_line_type_tax
                        AND dsati_line.line_type = gv_ar_line_type_line
                        AND dsati_line.account_class <> 'REC' -- Supprimer la ligne de type client
                   GROUP BY dsati_line.trx_number, dsati_line.org_id) ar_tax,
                  (SELECT DISTINCT dst.invoice_number,
                                   DECODE (dst.transaction_source,
                                           gv_expenditure_source, dst.from_org_id,
                                           dst.to_org_id
                                          ) ar_org_id,
                                   DECODE (dst.transaction_source,
                                           gv_expenditure_source, dst.to_org_id,
                                           dst.from_org_id
                                          ) ap_org_id
                              FROM dka_sarrefac_tmp dst
                             WHERE create_ap_data_flag = 'Y'
                          GROUP BY dst.invoice_number, dst.transaction_source, dst.from_org_id, dst.to_org_id) tmp
            WHERE 1 = 1
              AND tmp.ar_org_id = ar_tax.ar_org_id(+)
              AND tmp.ap_org_id = ap_tax.ap_org_id
              AND tmp.invoice_number = ap_tax.invoice_num
              AND TMP.INVOICE_NUMBER = AR_TAX.TRX_NUMBER(+)
              AND tmp.ar_org_id = ap_tax.ar_org_id;

        invoice_tax_amount_rec   invoice_tax_amount_cur%ROWTYPE;
        e_error                  EXCEPTION;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - correct_tva (+)');


        FOR invoice_tax_amount_rec IN invoice_tax_amount_cur LOOP

            Dka_Tools_Pkg.put_debug_message ('Vérification de la TVA pour facture '|| invoice_tax_amount_rec.trx_number);


            IF      invoice_tax_amount_rec.ar_tax_amount != invoice_tax_amount_rec.ap_tax_amount
                AND invoice_tax_amount_rec.ar_org_id IS NOT NULL -- Vérif que la facture AR existe dans OA
            THEN
                vn_tax_gap    := invoice_tax_amount_rec.ap_tax_amount - invoice_tax_amount_rec.ar_tax_amount;
                Dka_Tools_Pkg.put_debug_message (
                    'Facture '|| invoice_tax_amount_rec.trx_number || ': Ecart de TVA de ' || TO_CHAR (vn_tax_gap)
                );

                -- Correction d'une ligne de TVA
                UPDATE dka_sarrefac_ar_trx_interface dsati
                SET    dsati.amount = dsati.amount + vn_tax_gap
                WHERE  SUBSTR (dsati.interface_line_attribute1, 1, (INSTR (dsati.interface_line_attribute1, '/', 1, 1) - 1)) =
                                                                                              invoice_tax_amount_rec.trx_number
                       AND dsati.line_type = gv_ar_line_type_tax
                       AND dsati.org_id = invoice_tax_amount_rec.ar_org_id
                       -- Sur la ligne de plus gros montant (a enlever en cas de probleme de performance sur cette requete)
                       AND dsati.amount = (SELECT MAX (dsati1.amount)
                                           FROM   dka_sarrefac_ar_trx_interface dsati1
                                           WHERE      dsati1.interface_line_attribute1 = dsati.interface_line_attribute1
                                                  AND dsati1.line_type = gv_ar_line_type_tax)
                       -- Pour etre certain de n'avoir qu'une ligne
                       AND ROWNUM = 1;
            ELSE
                Dka_Tools_Pkg.put_debug_message ('TVA OK');
            END IF;

            Dka_Tools_Pkg.put_debug_message ('Insertion de la TVA AP pour la facture '|| invoice_tax_amount_rec.trx_number);

            INSERT INTO dka_sarrefac_ap_inv_interface
                        (invoice_id,
                         invoice_num,
                         invoice_type_lookup_code,
                         org_id,
                         vendor_id,
                         vendor_site_id,
                         SOURCE,
                         GROUP_ID,
                         payment_cross_rate,
                         gl_date,
                         invoice_currency_code,
                         term_id,
                         line_number,
                         line_type_lookup_code,
                         line_amount,
                         description,
                         dist_code_combination_id,
                         tax_code,
                         project_id,
                         task_id,
                         ap_expenditure_type,
                         expenditure_item_date,
                         expenditure_organization_id,
                         expenditure_quantity,
                         orig_transaction_source,
                         orig_transaction_id,
                         created_by,
                         creation_date,
                         last_updated_by,
                         last_update_date,
                         last_update_login,
                         request_id,
                         transfer_status_code,
                         transfer_rejection_reason,
                         doc_category_code,
                         pay_group_lookup_code
                        )
                SELECT   dsaii.invoice_id, --invoice_id
                         dsaii.invoice_num, --invoice_num
                         dsaii.invoice_type_lookup_code, --invoice_type_lookup_code
                         dsaii.org_id, --org_id
                         dsaii.vendor_id, --vendor_id
                         dsaii.vendor_site_id, --vendor_site_id
                         dsaii.SOURCE, --source
                         dsaii.GROUP_ID, --group_id
                         dsaii.payment_cross_rate, --payment_cross_rate
                         dsaii.gl_date, --gl_date
                         dsaii.invoice_currency_code, --invoice_currency_code
                         dsaii.term_id, --term_id
                         (MAX (dsaii.line_number) + 1), --line_number
                         gv_ap_line_type_tax, --item_type_lookup_code
                         invoice_tax_amount_rec.ap_tax_amount, --line_amount
                         zrb.description, --description
                         --atc.tax_code_combination_id, --dist_code_combination_id
                         DECODE(zrb.def_rec_settlement_option_code,'DEFERRED',za.INTERIM_TAX_CCID,za.tax_account_ccid), --za.tax_account_ccid, --RBE artf2154096
                         dsaii.tax_code, --tax_code
                         NULL, --project_id
                         NULL, --task_id
                         NULL, --ap_expenditure_type
                         NULL, --expenditure_item_date
                         NULL, --expenditure_organization_id
                         NULL, --expenditure_quantity
                         NULL, --orig_transaction_source
                         NULL, --orig_transaction_id
                         gn_user_id, --created_by
                         SYSDATE, --creation_date
                         gn_user_id, --last_updated_by
                         SYSDATE, --last_update_date
                         gn_login_id, --last_update_login
                         gn_conc_request_id, --request_id
                         'P', --transfer_status_code
                         NULL, --transfer_rejection_reason
                         dsaii.doc_category_code,
                         dsaii.pay_group_lookup_code
                FROM     dka_sarrefac_ap_inv_interface dsaii,
                         --ap_tax_codes_all atc
                         zx_rates_b   zrb,
                         ZX_ACCOUNTS  za
                WHERE    dsaii.invoice_id = invoice_tax_amount_rec.invoice_id
                         --AND atc.NAME = dsaii.tax_code
                         AND zrb.tax_rate_code = dsaii.tax_code
                         --AND atc.org_id = dsaii.org_id
                         AND ZRB.ACTIVE_FLAG ='Y'
                         AND SYSDATE > ZRB.effective_from
                         AND ZRB.TAX_RATE_ID = ZA.TAX_ACCOUNT_ENTITY_ID
                         AND ZA.Internal_organization_id = dsaii.org_id
                GROUP BY dsaii.invoice_id,
                         dsaii.invoice_num,
                         dsaii.invoice_type_lookup_code,
                         dsaii.org_id,
                         dsaii.vendor_id,
                         dsaii.vendor_site_id,
                         dsaii.SOURCE,
                         dsaii.GROUP_ID,
                         dsaii.payment_cross_rate,
                         dsaii.gl_date,
                         dsaii.invoice_currency_code,
                         dsaii.term_id,
                         zrb.description,
                         --atc.tax_code_combination_id,
                         DECODE(zrb.def_rec_settlement_option_code,'DEFERRED',za.INTERIM_TAX_CCID,za.tax_account_ccid),--za.tax_account_ccid,
                         dsaii.tax_code,
                         dsaii.doc_category_code,
                         dsaii.pay_group_lookup_code;
        END LOOP;

        Dka_Tools_Pkg.put_debug_message ('- - correct_tva (-)');

    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
            pn_retcode   := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END correct_tva;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : POPULATE_DATA
--  Description   : Complete les données la table DKA_SARREFAC_TMP
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE populate_data (
        pv_errbuf     OUT      VARCHAR2,
        pn_retcode    OUT      NUMBER,
        pd_ref_date   IN       DATE
    )
    IS
        CURSOR dka_sarrefac_tmp_cur
        IS
            SELECT dst.ROWID row_id,
                   dst.*
            FROM   dka_sarrefac_tmp dst
            WHERE  dst.transfer_status_code = 'P';

        e_error                EXCEPTION;
        vd_gener_date          Date; --EDB369
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- populate_data (+)');
        --<EDB369
        IF to_char(SYSDATE, 'HH24:MI:SS') >= '00:00:00' AND TO_char(SYSDATE,'HH24:MI:SS') <= '07:00:00' THEN
            vd_gener_date := trunc(sysdate-1);
          ELSE
            vd_gener_date := trunc(sysdate);
        END IF;
         -->EDB369
        FOR dka_sarrefac_tmp_rec IN dka_sarrefac_tmp_cur LOOP

            DECLARE -- Début traitement du record
                rec_error             EXCEPTION;
                vv_org_name           hr_all_organization_units.NAME%TYPE;
                vv_acct_area          dka_sarrefac_tmp.to_acct_center%TYPE;
                vn_org_id             hr_all_organization_units.organization_id%TYPE;
                vn_project_id         pa_projects_all.project_id%TYPE;
                vn_task_id            pa_tasks.task_id%TYPE;
                vn_ap_invoice_id      ap_invoices_interface.invoice_id%TYPE;
                vn_ap_line_number     ap_invoice_lines_interface.line_number%TYPE;
                vv_doc_category_code  ap_invoices_interface.doc_category_code%TYPE;
                vv_pay_group_lc       ap_invoices_interface.invoice_type_lookup_code%TYPE;
            BEGIN
                Dka_Tools_Pkg.put_debug_message (
                       'Traitement de la ligne '
                    || dka_sarrefac_tmp_rec.transaction_source
                    || ' | exp_item_id = '
                    || dka_sarrefac_tmp_rec.expenditure_item_id
                    || ' | event_id = '
                    || dka_sarrefac_tmp_rec.event_id
                );

                -- Insertion des données pour les factures AR et AP
                IF dka_sarrefac_tmp_rec.create_ap_data_flag = 'Y'
                THEN
                    -- Détermination de vn_org_id, vv_company_name, vn_project_id, vn_task_id
                    vv_doc_category_code := 'ACHAT_REFACTURATION';

                    IF dka_sarrefac_tmp_rec.transaction_source = gv_expenditure_source
                    THEN
                        vn_org_id            := dka_sarrefac_tmp_rec.to_org_id;
                        vv_org_name          := dka_sarrefac_tmp_rec.to_org_name;
                        vn_project_id        := dka_sarrefac_tmp_rec.to_project_id;
                        vn_task_id           := dka_sarrefac_tmp_rec.to_task_id;
                        vv_acct_area         := dka_sarrefac_tmp_rec.to_acct_center;
                    ELSE
                        vn_org_id            := dka_sarrefac_tmp_rec.from_org_id;
                        vv_org_name          := dka_sarrefac_tmp_rec.from_org_name;
                        vn_project_id        := dka_sarrefac_tmp_rec.from_project_id;
                        vn_task_id           := dka_sarrefac_tmp_rec.from_task_id;
                        vv_acct_area         := dka_sarrefac_tmp_rec.from_acct_center;
                    END IF;

                    --dka_tools_pkg.put_debug_message ('Création des données AP -> '
                    --                                || dka_sarrefac_tmp_rec.transaction_source
                    --                                || ':'
                    --                                || TO_CHAR(dka_sarrefac_tmp_rec.expenditure_item_id));
                    Dka_Sarrefac_Pkg.create_ap_data (
                        pv_errbuf                      => pv_errbuf,
                        pn_retcode                     => pn_retcode,
                        pv_invoice_num                 => dka_sarrefac_tmp_rec.invoice_number,
                        pn_org_id                      => vn_org_id,
                        pv_org_name                    => vv_org_name,
                        pv_acct_area                   => vv_acct_area,
                        pn_vendor_id                   => dka_sarrefac_tmp_rec.vendor_id,
                        pn_vendor_site_id              => dka_sarrefac_tmp_rec.vendor_site_id,
                        pd_gl_date                     => vd_gener_date, --pd_ref_date, EDB380
                        pn_amount                      => dka_sarrefac_tmp_rec.amount,
                        pv_description                 => dka_sarrefac_tmp_rec.description,
                        pn_project_id                  => vn_project_id,
                        pn_task_id                     => vn_task_id,
                        pv_expenditure_type            => dka_sarrefac_tmp_rec.ap_expenditure_type,
                        pd_expenditure_item_date       => vd_gener_date, --pd_ref_date, EDB369
                        pn_expenditure_quantity        => dka_sarrefac_tmp_rec.quantity,
                        pn_expenditure_org_id          => dka_sarrefac_tmp_rec.expenditure_org_id,
                        pv_orig_txn_source             => dka_sarrefac_tmp_rec.transaction_source,
                        pn_orig_txn_id                 => NVL (
                                                              dka_sarrefac_tmp_rec.expenditure_item_id,
                                                              dka_sarrefac_tmp_rec.event_id
                                                          ),
                        pv_create_ar_data_flag         => dka_sarrefac_tmp_rec.create_ar_data_flag,
                        pn_invoice_id                  => vn_ap_invoice_id,
                        pn_line_number                 => vn_ap_line_number,
                        pv_doc_category_code           => vv_doc_category_code
                    );

                    IF pn_retcode != 0
                    THEN
                        Dka_Tools_Pkg.put_debug_message ('ERREUR lors de l''insertion des données AP : '||chr(10)||pv_errbuf);
                        RAISE rec_error;
                    END IF;
                END IF;

                IF dka_sarrefac_tmp_rec.create_ar_data_flag = 'Y'
                THEN
                    --dka_tools_pkg.put_debug_message ('Création des données AR -> '
                    --                                || dka_sarrefac_tmp_rec.transaction_source
                    --                                || ':'
                    --                                || TO_CHAR(dka_sarrefac_tmp_rec.expenditure_item_id));

                    IF dka_sarrefac_tmp_rec.transaction_source = gv_expenditure_source
                    THEN
                        Dka_Sarrefac_Pkg.create_ar_data (
                            pv_errbuf                      => pv_errbuf,
                            pn_retcode                     => pn_retcode,
                            pv_trx_number                  => dka_sarrefac_tmp_rec.invoice_number,
                            pn_org_id                      => dka_sarrefac_tmp_rec.from_org_id,
                            pv_description                 => dka_sarrefac_tmp_rec.description,
                            pn_amount                      => dka_sarrefac_tmp_rec.amount,
                            pn_bill_to_customer_id         => dka_sarrefac_tmp_rec.customer_id,
                            pn_bill_to_address_id          => dka_sarrefac_tmp_rec.customer_site_id,
                            pv_interco                     => dka_sarrefac_tmp_rec.interco,
                            pn_term_id                     => gn_ar_term_id,
                            pd_trx_date                    => vd_gener_date, --EDB369 pd_ref_date,
                            pd_gl_date                     => vd_gener_date,--EDB380 pd_ref_date,
                            pv_to_acct_area                => dka_sarrefac_tmp_rec.to_acct_center,
                            pv_to_company_name             => dka_sarrefac_tmp_rec.to_org_name,
                            pv_from_acct_area              => dka_sarrefac_tmp_rec.from_acct_center,
                            pv_from_company_name           => dka_sarrefac_tmp_rec.from_org_name,
                            pn_project_id                  => dka_sarrefac_tmp_rec.from_project_id,
                            pn_task_id                     => dka_sarrefac_tmp_rec.from_task_id,
                            pv_event_type                  => dka_sarrefac_tmp_rec.ar_event_type,
                            pv_orig_txn_type               => dka_sarrefac_tmp_rec.transaction_source,
                            pn_orig_txn_id                 => dka_sarrefac_tmp_rec.expenditure_item_id,
                            pn_ap_line_number              => vn_ap_line_number,
                            pv_create_ap_data_flag         => dka_sarrefac_tmp_rec.create_ap_data_flag,
                            pv_cust_trx_type               => gv_ar_cust_trx_type
                        );
                    ELSE
                        Dka_Sarrefac_Pkg.create_ar_data (
                            pv_errbuf                      => pv_errbuf,
                            pn_retcode                     => pn_retcode,
                            pv_trx_number                  => dka_sarrefac_tmp_rec.invoice_number,
                            pn_org_id                      => dka_sarrefac_tmp_rec.to_org_id,
                            pv_description                 => dka_sarrefac_tmp_rec.description,
                            pn_amount                      => dka_sarrefac_tmp_rec.amount,
                            pn_bill_to_customer_id         => dka_sarrefac_tmp_rec.customer_id,
                            pn_bill_to_address_id          => dka_sarrefac_tmp_rec.customer_site_id,
                            pv_interco                     => dka_sarrefac_tmp_rec.interco,
                            pn_term_id                     => gn_ar_term_id,
                            pd_trx_date                    => vd_gener_date, --EDB369 pd_ref_date,
                            pd_gl_date                     => vd_gener_date, --EDB380 pd_ref_date,
                            pv_to_acct_area                => dka_sarrefac_tmp_rec.from_acct_center,
                            pv_to_company_name             => dka_sarrefac_tmp_rec.from_org_name,
                            pv_from_acct_area              => dka_sarrefac_tmp_rec.to_acct_center,
                            pv_from_company_name           => dka_sarrefac_tmp_rec.to_org_name,
                            pn_project_id                  => dka_sarrefac_tmp_rec.to_project_id,
                            pn_task_id                     => dka_sarrefac_tmp_rec.to_task_id,
                            pv_event_type                  => dka_sarrefac_tmp_rec.ar_event_type,
                            pv_orig_txn_type               => dka_sarrefac_tmp_rec.transaction_source,
                            pn_orig_txn_id                 => dka_sarrefac_tmp_rec.event_id,
                            pn_ap_line_number              => vn_ap_line_number,
                            pv_create_ap_data_flag         => dka_sarrefac_tmp_rec.create_ap_data_flag,
                            pv_cust_trx_type               => gv_ar_cust_trx_type
                        );
                    END IF;

                    IF pn_retcode != 0
                    THEN
                        Dka_Tools_Pkg.put_debug_message ('ERREUR lors de l''insertion des données AR : '||chr(10)||pv_errbuf);
                        RAISE rec_error;
                    END IF;
                END IF;

                -- Cas d'une des 2 sociétés non gérée dans OA
                IF    dka_sarrefac_tmp_rec.create_ap_data_flag = 'N'
                   OR dka_sarrefac_tmp_rec.create_ar_data_flag = 'N'
                THEN
                    IF dka_sarrefac_tmp_rec.transaction_source = gv_expenditure_source
                    THEN
                        Dka_Sarrefac_Pkg.create_data_for_non_oa_soc (
                            pv_errbuf                      => pv_errbuf,
                            pn_retcode                     => pn_retcode,
                            pd_ref_date                    => pd_ref_date,
                            pv_trx_number                  => dka_sarrefac_tmp_rec.invoice_number,
                            pd_trx_date                    => vd_gener_date, --pd_ref_date, EDB369
                            pv_created_in_ap_flag          => dka_sarrefac_tmp_rec.create_ap_data_flag,
                            pv_created_in_ar_flag          => dka_sarrefac_tmp_rec.create_ar_data_flag,
                            pv_pa_txn_type                 => dka_sarrefac_tmp_rec.transaction_source,
                            pn_pa_txn_id                   => dka_sarrefac_tmp_rec.expenditure_item_id,
                            pn_ap_org_id                   => dka_sarrefac_tmp_rec.to_org_id,
                            pv_ap_org_name                 => dka_sarrefac_tmp_rec.to_org_name,
                            pv_ap_acct_area                => dka_sarrefac_tmp_rec.to_acct_center,
                            pn_ap_project_id               => dka_sarrefac_tmp_rec.to_project_id,
                            pn_ap_task_id                  => dka_sarrefac_tmp_rec.to_task_id,
                            pv_ap_expenditure_type         => dka_sarrefac_tmp_rec.ap_expenditure_type,
                            pn_ap_vendor_id                => dka_sarrefac_tmp_rec.vendor_id,
                            pn_ar_org_id                   => dka_sarrefac_tmp_rec.from_org_id,
                            pv_ar_org_name                 => dka_sarrefac_tmp_rec.from_org_name,
                            pv_ar_acct_area                => dka_sarrefac_tmp_rec.from_acct_center,
                            pn_ar_project_id               => dka_sarrefac_tmp_rec.from_project_id,
                            pn_ar_task_id                  => dka_sarrefac_tmp_rec.from_task_id,
                            pv_ar_event_type               => dka_sarrefac_tmp_rec.ar_event_type,
                            pn_ar_customer_id              => dka_sarrefac_tmp_rec.customer_id,
                            pn_ar_customer_site_id         => dka_sarrefac_tmp_rec.customer_site_id,
                            pn_quantity                    => dka_sarrefac_tmp_rec.quantity,
                            pn_line_amount                 => dka_sarrefac_tmp_rec.amount
                        );
                    ELSE
                        Dka_Sarrefac_Pkg.create_data_for_non_oa_soc (
                            pv_errbuf                      => pv_errbuf,
                            pn_retcode                     => pn_retcode,
                            pd_ref_date                    => pd_ref_date,
                            pv_trx_number                  => dka_sarrefac_tmp_rec.invoice_number,
                            pd_trx_date                    => vd_gener_date, --pd_ref_date, EDB369
                            pv_created_in_ap_flag          => dka_sarrefac_tmp_rec.create_ap_data_flag,
                            pv_created_in_ar_flag          => dka_sarrefac_tmp_rec.create_ar_data_flag,
                            pv_pa_txn_type                 => dka_sarrefac_tmp_rec.transaction_source,
                            pn_pa_txn_id                   => dka_sarrefac_tmp_rec.event_id,
                            pn_ap_org_id                   => dka_sarrefac_tmp_rec.from_org_id,
                            pv_ap_org_name                 => dka_sarrefac_tmp_rec.from_org_name,
                            pv_ap_acct_area                => dka_sarrefac_tmp_rec.from_acct_center,
                            pn_ap_project_id               => dka_sarrefac_tmp_rec.from_project_id,
                            pn_ap_task_id                  => dka_sarrefac_tmp_rec.from_task_id,
                            pv_ap_expenditure_type         => dka_sarrefac_tmp_rec.ap_expenditure_type,
                            pn_ap_vendor_id                => dka_sarrefac_tmp_rec.vendor_id,
                            pn_ar_org_id                   => dka_sarrefac_tmp_rec.to_org_id,
                            pv_ar_org_name                 => dka_sarrefac_tmp_rec.to_org_name,
                            pv_ar_acct_area                => dka_sarrefac_tmp_rec.to_acct_center,
                            pn_ar_project_id               => dka_sarrefac_tmp_rec.to_project_id,
                            pn_ar_task_id                  => dka_sarrefac_tmp_rec.to_task_id,
                            pv_ar_event_type               => dka_sarrefac_tmp_rec.ar_event_type,
                            pn_ar_customer_id              => dka_sarrefac_tmp_rec.customer_id,
                            pn_ar_customer_site_id         => dka_sarrefac_tmp_rec.customer_site_id,
                            pn_quantity                    => dka_sarrefac_tmp_rec.quantity,
                            pn_line_amount                 => dka_sarrefac_tmp_rec.amount
                        );
                    END IF;

                    IF pn_retcode != 0
                    THEN
                        Dka_Tools_Pkg.put_debug_message ('ERREUR lors de l''insertion des données non OA');
                        RAISE rec_error;
                    END IF;

                END IF;

                -- Mise a jour de la table
                --dka_tools_pkg.put_debug_message ('Mise a jour de la table -> '
                --                                || dka_sarrefac_tmp_rec.transaction_source
                --                                || ':'
                --                                || TO_CHAR(dka_sarrefac_tmp_rec.expenditure_item_id)
                --                                || ':'
                --                                || TO_CHAR(dka_sarrefac_tmp_rec.event_id)
                --                                );
                UPDATE dka_sarrefac_tmp dst
                SET    dst.invoice_id = vn_ap_invoice_id,
                       dst.transfer_status_code = 'T',
                       dst.last_update_date = SYSDATE,
                       dst.last_updated_by = gn_user_id,
                       dst.last_update_login = gn_login_id,
                       dst.request_id = gn_conc_request_id
                WHERE  dst.ROWID = dka_sarrefac_tmp_rec.row_id;
            EXCEPTION
                WHEN rec_error
                THEN
                    -- Suppression des lignes de dka_sarrefac_ar_trx_interface
                    DELETE      dka_sarrefac_ar_trx_interface dsati
                    WHERE           dsati.attribute14 = dka_sarrefac_tmp_rec.transaction_source
                                AND dsati.attribute15 =
                                                      NVL (dka_sarrefac_tmp_rec.expenditure_item_id, dka_sarrefac_tmp_rec.event_id);

                    Dka_Tools_Pkg.put_debug_message (
                        TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimée(s) dans dka_sarrefac_ar_trx_interface'
                    );

                    -- Suppression des lignes de dka_sarrefac_ap_inv_interface
                    DELETE      dka_sarrefac_ap_inv_interface dsaii
                    WHERE           dsaii.orig_transaction_source = dka_sarrefac_tmp_rec.transaction_source
                                AND dsaii.orig_transaction_id =
                                                      NVL (dka_sarrefac_tmp_rec.expenditure_item_id, dka_sarrefac_tmp_rec.event_id);

                    Dka_Tools_Pkg.put_debug_message (
                        TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimée(s) dans dka_sarrefac_ap_inv_interface'
                    );

                    -- Suppression des lignes de dka_sarrefac_trx_non_oa_soc
                    DELETE      dka_sarrefac_trx_non_oa_soc dstnos
                    WHERE           dstnos.pa_txn_type = dka_sarrefac_tmp_rec.transaction_source
                                AND dstnos.pa_txn_id =
                                                      NVL (dka_sarrefac_tmp_rec.expenditure_item_id, dka_sarrefac_tmp_rec.event_id);

                    Dka_Tools_Pkg.put_debug_message (
                        TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimée(s) dans dka_sarrefac_trx_non_oa_soc'
                    );

                    -- Marquer la ligne en statut 'Rejeté'
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = pv_errbuf,
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE  dst.ROWID = dka_sarrefac_tmp_rec.row_id;

                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
                    Dka_Tools_Pkg.put_debug_message (
                           'ERREUR => '
                        || pv_errbuf
                        || ' -> '
                        || dka_sarrefac_tmp_rec.transaction_source
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.expenditure_item_id)
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.event_id)
                    );
                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
                WHEN OTHERS
                THEN
                    pn_retcode    := SQLCODE;
                    pv_errbuf     := SQLERRM;

                    -- Suppression des lignes de dka_sarrefac_ar_trx_interface
                    DELETE      dka_sarrefac_ar_trx_interface dsati
                    WHERE           dsati.attribute14 = dka_sarrefac_tmp_rec.transaction_source
                                AND dsati.attribute15 =
                                                      NVL (dka_sarrefac_tmp_rec.expenditure_item_id, dka_sarrefac_tmp_rec.event_id);

                    Dka_Tools_Pkg.put_debug_message (
                        TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimée(s) dans dka_sarrefac_ar_trx_interface'
                    );

                    -- Suppression des lignes de dka_sarrefac_ap_inv_interface
                    DELETE      dka_sarrefac_ap_inv_interface dsaii
                    WHERE           dsaii.orig_transaction_source = gv_event_source
                                AND dsaii.orig_transaction_id =
                                                      NVL (dka_sarrefac_tmp_rec.expenditure_item_id, dka_sarrefac_tmp_rec.event_id);

                    Dka_Tools_Pkg.put_debug_message (
                        TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimée(s) dans dka_sarrefac_ap_inv_interface'
                    );

                    -- Suppression des lignes de dka_sarrefac_trx_non_oa_soc
                    DELETE      dka_sarrefac_trx_non_oa_soc dstnos
                    WHERE           dstnos.pa_txn_type = dka_sarrefac_tmp_rec.transaction_source
                                AND dstnos.pa_txn_id =
                                                      NVL (dka_sarrefac_tmp_rec.expenditure_item_id, dka_sarrefac_tmp_rec.event_id);

                    Dka_Tools_Pkg.put_debug_message (
                        TO_CHAR (SQL%ROWCOUNT) || ' lignes supprimée(s) dans dka_sarrefac_trx_non_oa_soc'
                    );

                    -- Marquer la ligne en statut 'Rejeté'
                    UPDATE dka_sarrefac_tmp dst
                    SET    dst.transfer_status_code = 'R',
                           dst.transfer_rejection_reason = pv_errbuf,
                           dst.last_update_date = SYSDATE,
                           dst.last_updated_by = gn_user_id,
                           dst.last_update_login = gn_login_id,
                           dst.request_id = gn_conc_request_id
                    WHERE  dst.ROWID = dka_sarrefac_tmp_rec.row_id;

                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
                    Dka_Tools_Pkg.put_debug_message (
                           'ERREUR => '
                        || pv_errbuf
                        || ' -> '
                        || dka_sarrefac_tmp_rec.transaction_source
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.expenditure_item_id)
                        || ':'
                        || TO_CHAR (dka_sarrefac_tmp_rec.event_id)
                    );
                    Dka_Tools_Pkg.put_debug_message ('**************************************************');
            END; -- Fin traitement record
        END LOOP;

        -- Correction des écarts de TVA entre AR et AP
        Dka_Tools_Pkg.put_debug_message ('Correction des écarts de TVA entre AR et AP');
        Dka_Sarrefac_Pkg.correct_tva (pv_errbuf => pv_errbuf, pn_retcode => pn_retcode);

        IF pn_retcode != 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('ERREUR lors de la correction des écarts de TVA');
            RAISE e_error;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('- populate_data (-)');
    EXCEPTION
        WHEN e_error
        THEN
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);

        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);

    END populate_data;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHECK_FOR_CREDIT_MEMOS
--  Description   : Traite le cas des avoirs dans AR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE check_for_credit_memos (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        e_error   EXCEPTION;

    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- check_for_credit_memos (+)');

        UPDATE dka_sarrefac_ar_trx_interface dsati
        SET    dsati.cust_trx_type_name = gv_ar_cust_trx_type_cm,
               dsati.term_id = NULL
        WHERE     ((dsati.org_id, dsati.trx_number, dsati.line_type) IN (SELECT   dsati1.org_id,
                                                                                  dsati1.trx_number,
                                                                                  dsati1.line_type
                                                                         FROM     dka_sarrefac_ar_trx_interface dsati1
                                                                         WHERE        dsati1.cust_trx_type_name like gv_ar_cust_trx_type
                                                                                  AND dsati1.line_type = gv_ar_line_type_line
                                                                         HAVING   SUM (dsati1.amount) < 0
                                                                         GROUP BY dsati1.org_id,
                                                                                  dsati1.trx_number,
                                                                                  dsati1.line_type)
                  )
               OR ((dsati.org_id, dsati.line_type, dsati.link_to_line_context, dsati.link_to_line_attribute1) IN
                           (SELECT   dsati1.org_id,
                                     gv_ar_line_type_tax,
                                     dsati1.interface_line_context,
                                     dsati1.interface_line_attribute1
                            FROM     dka_sarrefac_ar_trx_interface dsati1
                            WHERE        dsati1.cust_trx_type_name like gv_ar_cust_trx_type
                                     AND dsati1.line_type = gv_ar_line_type_line
                            HAVING   SUM (dsati1.amount) < 0
                            GROUP BY dsati1.org_id,
                                     dsati1.interface_line_context,
                                     dsati1.interface_line_attribute1)
                  );

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes mises a jour');
        Dka_Tools_Pkg.put_debug_message ('- check_for_credit_memos (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END check_for_credit_memos;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ALIM_AR_INTERFACE
--  Description   : Alimente les tables d'Open Interface de AR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE alim_ar_interface (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        e_error   EXCEPTION;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- alim_ar_interface (+)');

        -- Insertion des lignes de mouvement
        INSERT INTO ra_interface_lines_all
                    (interface_line_context,
                     interface_line_attribute1,
                     interface_line_attribute2,
                     link_to_line_context,
                     link_to_line_attribute1,
                     link_to_line_attribute2,
                     batch_source_name,
                     set_of_books_id,
                     org_id,
                     line_type,
                     description,
                     currency_code,
                     amount,
                     cust_trx_type_name,
                     term_id,
                     orig_system_bill_customer_id,
                     orig_system_bill_address_id,
                     conversion_type,
                     conversion_date,
                     conversion_rate,
                     trx_date,
                     gl_date,
                     trx_number,
                     tax_exempt_flag,
                     tax_code,
                     creation_date,
                     created_by,
                     --R12
                     tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code
                    )
            SELECT dsati.interface_line_context, -- Interface_Line_Context
                   dsati.interface_line_attribute1, -- Interface_Line_Attribute1
                   dsati.interface_line_attribute2, -- Interface_Line_Attribute2
                   dsati.link_to_line_context, -- Link_To_Line_Context
                   dsati.link_to_line_attribute1, -- Link_To_Line_Attribute1
                   dsati.link_to_line_attribute2, -- Link_To_Line_Attribute2
                   dsati.batch_source_name, -- Batch_Source_Name
                   dsati.set_of_books_id, -- Set_Of_Books_Id
                   dsati.org_id, -- Org_Id
                   dsati.line_type, -- Line_Type
                   dsati.description, -- Description
                   dsati.currency_code, -- Currency_Code
                   dsati.amount, -- Amount
                   dsati.cust_trx_type_name, -- Cust_Trx_Type_Name
                   dsati.term_id, -- Term_Id
                   dsati.orig_system_bill_customer_id, -- Orig_System_Bill_Customer_Id
                   dsati.orig_system_bill_address_id, -- Orig_System_Bill_Address_Id
                   dsati.conversion_type, -- Conversion_Type
                   NULL, -- Conversion_Date
                   1, -- Conversion_Rate
                   dsati.trx_date, -- Trx_Date
                   dsati.gl_date, -- Gl_Date
                   dsati.trx_number, -- Trx_Number
                   dsati.tax_exempt_flag, -- Tax_Exempt_Flag
                   dsati.tax_code, -- Tax_Code
                   SYSDATE, -- Creation_Date
                   gn_user_id, -- Created_By
                   --R12
                   decode(ACCOUNT_CLASS,'TAX',gv_tax_code_coll,NULL),
                   decode(ACCOUNT_CLASS,'TAX',gv_tax_regime_code,NULL),
                   decode(ACCOUNT_CLASS,'TAX',gv_tax,NULL),
                   decode(ACCOUNT_CLASS,'TAX',gv_tax_jurisdiction_code,NULL),
                   decode(ACCOUNT_CLASS,'TAX',gv_tax_status_code_coll,NULL)
            FROM   dka_sarrefac_ar_trx_interface dsati
            WHERE  ACCOUNT_CLASS <> 'REC'; -- PHENIX 2004

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes insérées dans RA_INTERFACE_LINES_ALL');



        -- Insertion des lignes de ventilation
        INSERT INTO ra_interface_distributions_all
                    (interface_line_context,
                     interface_line_attribute1,
                     interface_line_attribute2,
                     account_class,
                     amount,
                     percent,
                     code_combination_id,
                     org_id,
                     attribute_category,
                     attribute1,
                     attribute2,
                     attribute4, --RBE
                     attribute13,
                     attribute14,
                     attribute15,
                     creation_date,
                     created_by,
           interim_tax_ccid -- OBE artf3030545
                    )
            SELECT dsati.interface_line_context, -- Interface_Line_Context
                   dsati.interface_line_attribute1, -- Interface_Line_Attribute1
                   dsati.interface_line_attribute2, -- Interface_Line_Attribute2
                   dsati.account_class, -- Account_Class
                   dsati.amount, -- Amount
                   DECODE (dsati.account_class, 'REC', 100, NULL), -- Percent
                   dsati.code_combination_id, -- Code_Combination_Id
                   dsati.org_id, -- Org_Id
                   DECODE (dsati.line_type, gv_ar_line_type_line, 'Y', 'N'), -- Attribute_Category
                   DECODE (dsati.line_type, gv_ar_line_type_line, TO_CHAR (dsati.project_id), NULL), -- Attribute1
                   DECODE (dsati.line_type, gv_ar_line_type_line, dsati.ar_event_type, NULL), -- Attribute2
                   TO_CHAR(dsati.task_id), --pt.task_number,-- RBE tache
                   dsati.attribute13, -- Attribute13
                   dsati.attribute14, -- Attribute14
                   dsati.attribute15, -- Attribute15
                   SYSDATE, -- Creation_Date
                   gn_user_id, -- Created_By
           --< OBE artf3030545
           (
           --select decode(a.segment3,'445714',a.code_combination_id,null) from gl_code_combinations a where a.code_combination_id = dsati.code_combination_id
                    select decode(account_class, 'TAX', zx.INTERIM_TAX_CCID, null)
                    from zx_accounts zx,
                         zx_rates_b zr
                    where zr.tax_rate_code = dsati.tax_code
                    AND zr.ACTIVE_FLAG ='Y'
                    AND SYSDATE > zr.effective_from
                    and zx.tax_account_entity_id = zr.tax_rate_id
                    and zx.Internal_organization_id = dsati.org_id
           ) interim_ccid
           --> OBE artf3030545
            FROM   dka_sarrefac_ar_trx_interface dsati
                   --pa_tasks pt                     --RBE
            --WHERE  dsati.task_id  = pt.task_id (+) --RBE
            ;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes insérées dans RA_INTERFACE_DISTRIBUTIONS_ALL');

        -- Mise a jour du statut dans DKA_SARREFAC_AR_TRX_INTERFACE
        UPDATE dka_sarrefac_ar_trx_interface dsati
        SET    dsati.transfer_status_code = 'T';

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes mises a ''T'' dans DKA_SARREFAC_AR_TRX_INTERFACE');
        Dka_Tools_Pkg.put_debug_message ('- alim_ar_interface (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END alim_ar_interface;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : ALIM_AP_INTERFACE
--  Description   : Alimente les tables d'Open Interface de AP
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE alim_ap_interface (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        e_error   EXCEPTION;

        CURSOR cur_int IS
        SELECT invoice_id, vendor_site_id, doc_category_code
        FROM   ap_invoices_interface
        WHERE  NVL (status, '*') <> 'PROCESSED'
        AND    source = gv_ap_source
        FOR UPDATE;

        vn_conc_segments            VARCHAR2 (2000);
        vn_dist_ccid                gl_code_combinations.code_combination_id%TYPE;
        
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- alim_ap_interface (+)');

        -- Insertion des en-tetes
        INSERT INTO ap_invoices_interface
                    (invoice_id,
                     invoice_num,
                     invoice_type_lookup_code,
                     org_id,
                     vendor_id,
                     vendor_site_id,
                     SOURCE,
                     GROUP_ID,
                     payment_cross_rate,
                     pay_group_lookup_code,
                     gl_date,
                     invoice_date,
                     invoice_currency_code,
                     terms_id,
                     invoice_amount,
                     doc_category_code,
                     global_attribute_category,
                     global_attribute1,
					 attribute3,--EDB380
					 attribute9,--EDB380
                     creation_date,
                     created_by,
                     last_update_date,
                     last_updated_by,
                     last_update_login
                    )
            SELECT   dsaii.invoice_id, -- Invoice_Id
                     dsaii.invoice_num , -- Invoice_Num
                     dsaii.invoice_type_lookup_code, -- Invoice_Type_Lookup_Code
                     dsaii.org_id , -- Org_Id
                     dsaii.vendor_id, -- Vendor_Id
                     dsaii.vendor_site_id, -- Vendor_Site_Id
                     dsaii.SOURCE, -- Source
                     dsaii.GROUP_ID, -- Group_Id
                     dsaii.payment_cross_rate, -- Payment_Cross_Rate
                     dsaii.pay_group_lookup_code,-- pay_group_lookup_code
                     dsaii.gl_date, -- Gl_Date
                     --dsaii.gl_date, -- Invoice_Date
                     max(dsaii.expenditure_item_date), --EDB369 Invoice_Date à la date de génération de refac  
                     dsaii.invoice_currency_code, -- Invoice_currency_code
                     dsaii.term_id, -- Term_Id
                     SUM (dsaii.line_amount), -- Invoice_Amount
                     dsaii.doc_category_code,
                     gv_global_attribute_category,
                     gv_ap_tax_type,
					 UPPER(dsaii.invoice_num||'.PDF'),--EDB380
					 'REFAC',--EDB380
                     SYSDATE,
                     gn_user_id,
                     SYSDATE,
                     gn_user_id,
                     gn_login_id
            FROM     dka_sarrefac_ap_inv_interface dsaii
            GROUP BY dsaii.invoice_id,
                     dsaii.invoice_num,
                     dsaii.invoice_type_lookup_code,
                     dsaii.org_id,
                     dsaii.vendor_id,
                     dsaii.vendor_site_id,
                     dsaii.SOURCE,
                     dsaii.GROUP_ID,
                     dsaii.payment_cross_rate,
                     dsaii.pay_group_lookup_code,
                     dsaii.gl_date,
                     dsaii.invoice_currency_code,
                     dsaii.term_id,
                     dsaii.doc_category_code;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes insérées dans AP_INVOICES_INTERFACE');

        -- Insertion des lignes de ventilation
        INSERT INTO ap_invoice_lines_interface
                    (invoice_id,
                     line_number,
                     line_type_lookup_code,
                     amount,
                     description,
                     dist_code_combination_id,
                     tax_code,
                     tax_recoverable_flag,
                     project_id,
                     task_id,
                     expenditure_type,
                     expenditure_item_date,
                     expenditure_organization_id,
                     pa_quantity,
                     org_id,
                     attribute13,
                     creation_date,
                     created_by,
                     last_update_date,
                     last_updated_by,
                     last_update_login,
                     --R12
                     line_group_number,
                     tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code,
                     prorate_across_flag
                    )
            SELECT dsaii.invoice_id, -- Invoice_Id
                   dsaii.line_number, -- Line_Number
                   dsaii.line_type_lookup_code, -- Line_Type_Lookup_Code
                   dsaii.line_amount, -- Amount
                   dsaii.description, -- Description
                   dsaii.dist_code_combination_id, -- Dist_Code_Combination_Id
                   dsaii.tax_code, -- Tax_Code
                   DECODE (dsaii.line_type_lookup_code, gv_ap_line_type_tax, 'Y', 'N'), -- Tax_Recoverable_Flag
                   dsaii.project_id, -- Project_Id
                   dsaii.task_id, -- Task_Id
                   dsaii.ap_expenditure_type, -- Expenditure_Type
                   dsaii.expenditure_item_date, -- Expenditure_Item_Date
                   dsaii.expenditure_organization_id, -- Expenditure_Organization_Id
                   dsaii.expenditure_quantity, -- Pa_Quantity
                   dsaii.org_id, -- Org_Id
                   TO_CHAR (dsaii.line_number), -- Attribute13
                   SYSDATE,
                   gn_user_id,
                   SYSDATE,
                   gn_user_id,
                   gn_login_id,
                   --R12
                   1,
                   decode(dsaii.line_type_lookup_code,'TAX',gv_tax_code_ded,NULL),
                   decode(dsaii.line_type_lookup_code,'TAX',gv_tax_regime_code,NULL),
                   decode(dsaii.line_type_lookup_code,'TAX',gv_tax,NULL),
                   decode(dsaii.line_type_lookup_code,'TAX',gv_tax_jurisdiction_code,NULL),
                   decode(dsaii.line_type_lookup_code,'TAX',gv_tax_status_code_ded,NULL),
                   decode(dsaii.line_type_lookup_code,'TAX','Y',NULL)
            FROM   dka_sarrefac_ap_inv_interface dsaii;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes insérées dans AP_INVOICE_LINES_INTERFACE');

        -- Mise a jour du statut dans DKA_SARREFAC_AP_INV_INTERFACE
        UPDATE dka_sarrefac_ap_inv_interface dsaii
        SET    dsaii.transfer_status_code = 'T';

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes mises a ''T'' dans DKA_SARREFAC_AP_INV_INTERFACE');
        Dka_Tools_Pkg.put_debug_message ('- alim_ap_interface (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END alim_ap_interface;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : UPDATE_PA
--  Description   : Mise a jour des les d'origine dans PA
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE update_pa (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        e_error         EXCEPTION;
        vn_request_id   NUMBER (15);
        vn_user_id      NUMBER (15);
        vn_login_id     NUMBER (15);
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- update_pa (+)');
        -- Détermination des variables
        vn_request_id    := gn_conc_request_id;
        vn_user_id       := gn_user_id;
        vn_login_id      := gn_login_id;

        -- Mise a jour des lignes de dépenses
        FOR rec_pei IN (SELECT dst.expenditure_item_id, dst.to_org_id
                        FROM   dka_sarrefac_tmp dst
                        WHERE  dst.transaction_source = gv_expenditure_source
                        AND    dst.transfer_status_code = 'T')
        LOOP
          UPDATE pa_expenditure_items_all pei
          SET    pei.last_update_date = SYSDATE,
                 pei.last_updated_by = vn_user_id,
                 pei.request_id = vn_request_id,
                 pei.attribute3 = TO_CHAR (vn_request_id),
                 --pei.attribute2 = rec_pei.to_segment1,
                 pei.attribute6 = rec_pei.to_org_id
          WHERE  pei.expenditure_item_id = rec_pei.expenditure_item_id;
        END LOOP;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes mises a jour dans PA_EXPENDITURE_ITEMS_ALL');

        -- Mise a jour des lignes d'évenements
        FOR enr_pe IN (SELECT dst.event_id, dst.to_org_id
                       FROM   dka_sarrefac_tmp dst
                       WHERE  dst.transaction_source = gv_event_source
                       AND    dst.transfer_status_code = 'T')
        LOOP
          UPDATE pa_events pe
          SET    pe.last_update_date = SYSDATE,
                 pe.last_updated_by = vn_user_id,
                 pe.request_id = vn_request_id,
                 pe.attribute3 = TO_CHAR (vn_request_id),
                 --pe.attribute2 = enr_pe.to_segment1,
                 pe.attribute6 = enr_pe.to_org_id
          WHERE  pe.event_id = enr_pe.event_id;
        END LOOP;

        Dka_Tools_Pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' lignes mises a jour dans PA_EVENTS');

        -- Mise a jour des lignes temporaires
        UPDATE dka_sarrefac_tmp dst
        SET    dst.transfer_status_code = 'A'
        WHERE  dst.transfer_status_code = 'T';

        Dka_Tools_Pkg.put_debug_message ('- update_pa (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END update_pa;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_AP_INTERFACE
--  Description   : Lancement d'une Open Interface de AP
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_org_id               IN      NUMBER
--      pn_group_id             IN      NUMBER
--      pd_ref_date             IN      DATE
--      pn_request_id           OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_ap_interface (
        pv_errbuf       OUT      VARCHAR2,
        pn_retcode      OUT      NUMBER,
        pn_org_id       IN       NUMBER,
        pv_source       IN       VARCHAR2,
        pn_group_id     IN       NUMBER,
        pn_request_id   OUT      NUMBER
    )
    IS
        e_error                EXCEPTION;
        vv_org_name            hr_all_organization_units.NAME%TYPE;
        vn_responsibility_id   fnd_responsibility.responsibility_id%TYPE;
        vn_application_id      fnd_application.application_id%TYPE;
        vv_hold_code           ap_hold_codes.hold_lookup_code%TYPE;
        vv_hold_reason         ap_hold_codes.hold_type%TYPE;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - launch_ap_interface (+)');

        -- Positionnement de l'environnement
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = gv_ap_responsibility_key;

        Fnd_Global.apps_initialize (gn_user_id, vn_responsibility_id, vn_application_id);
        mo_global.init('SQLAP');

        pn_request_id    :=
                Fnd_Request.submit_request (
                    'SQLAP',       --APPL
                    'APXIIMPT',    --PROG
                    NULL,          --PROGRAM_NAME
                    NULL,          --START
                    FALSE,         --SUB_REQUEST
                    pn_org_id,     --Org_id                       --ARGUMENT0
                    pv_source,     --Source                       --ARGUMENT1
                    pn_group_id,   --Group                        --ARGUMENT2
                    NULL,          --Invoice batch name (Null)    --ARGUMENT3
                    vv_hold_code,  --Hold code                    --ARGUMENT4
                    vv_hold_reason,--Hold reason                  --ARGUMENT5
                    NULL,          --GL date (pd_ref_date)        --ARGUMENT6
                    'Y',           --Purge                        --ARGUMENT7
                    Dka_Tools_Pkg.gv_debug_mode, --Trace switch   --ARGUMENT8
                    Dka_Tools_Pkg.gv_debug_mode, --Debug switch   --ARGUMENT9
                    'N'             --Summrize report             --ARGUMENT10
                );

        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF pn_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de lancer le traitement d''import AP pour l''org_id '|| TO_CHAR (pn_org_id)
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de lancer le traitement d''import AP pour l''org_id ' || TO_CHAR (pn_org_id);
            RAISE e_error;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('- - launch_ap_interface (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END launch_ap_interface;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_AR_INTERFACE
--  Description   : Lancement d'une Open Interface de AR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_org_id               IN      NUMBER
--      pv_batch_source_name    IN      VARCHAR2
--      pd_ref_date             IN      DATE
--      pn_request_id           OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_ar_interface (
        pv_errbuf              OUT      VARCHAR2,
        pn_retcode             OUT      NUMBER,
        pn_org_id              IN       NUMBER,
        pv_batch_source_name   IN       VARCHAR2,
        pd_ref_date            IN       DATE,
        pn_request_id          OUT      NUMBER
    )
    IS
        e_error                EXCEPTION;
        vv_org_name            hr_all_organization_units.NAME%TYPE;
        vn_responsibility_id   fnd_responsibility.responsibility_id%TYPE;
        vn_application_id      fnd_application.application_id%TYPE;
        vn_batch_source_id     ra_batch_sources_all.batch_source_id%TYPE;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - launch_ar_interface (+)');

        SELECT rbs.batch_source_id
        INTO   vn_batch_source_id
        FROM   ra_batch_sources_all rbs
        WHERE      rbs.NAME = pv_batch_source_name
               AND rbs.org_id = pn_org_id;

        -- Positionnement de l'environnement
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = gv_ar_responsibility_key;

        Fnd_Global.apps_initialize (gn_user_id, vn_responsibility_id, vn_application_id);
        mo_global.init('AR');

        pn_request_id    :=
                Fnd_Request.submit_request (
                    'AR', --APPL
                    'RAXTRX', --PROG
                    NULL, --PROGRAM_NAME
                    NULL, --START
                    FALSE, --SUB_REQUEST
                    'MAIN', -- Parallel Module Name                          --ARGUMENT1
                    'T', -- Running Mode                                     --ARGUMENT2
                    vn_batch_source_id, --Batch source id                    --ARGUMENT3
                    pv_batch_source_name, --Batch source name                --ARGUMENT4
                    Fnd_Date.Date_to_canonical (pd_ref_date), --Default Date --ARGUMENT5
                    '', --Transaction Field                                --ARGUMENT6
                    '', --Transaction Type                                 --ARGUMENT7
                    '', --Low Bill to customer num                         --ARGUMENT8
                    '', --High Bill to customer num                        --ARGUMENT9
                    '', --Low Bill to customer name                        --ARGUMENT10
                    '', --High Bill to customer name                       --ARGUMENT11
                    '', --Low GL Date                                      --ARGUMENT12
                    '', --High GL Date                                     --ARGUMENT13
                    '', --Low Ship Date                                    --ARGUMENT14
                    '', --High Ship Date                                   --ARGUMENT15
                    '', --Low Transaction number                           --ARGUMENT16
                    '', --High Transaction number                          --ARGUMENT17
                    '', --Low Sales order number                           --ARGUMENT18
                    '', --High Sales order number                          --ARGUMENT19
                    '', --Low Invoice date                                 --ARGUMENT20
                    '', --High Invoice date                                --ARGUMENT21
                    '', --Low Ship to customer num                         --ARGUMENT22
                    '', --High Ship to customer num                        --ARGUMENT23
                    '', --Low Ship to customer name                        --ARGUMENT24
                    '', --High Ship to customer name                       --ARGUMENT25
                    'N', --Call RAXTRX from RAXMTR flag                    --ARGUMENT26
                    'Y', --Base Due Date on Trx Date                       --ARGUMENT27
                    '', --Due Date Adjustment Days                         --ARGUMENT28
                    to_char(pn_org_id), --Org Id                           --ARGUMENT29
                    chr(0)                                                 --ARGUMENT30
                    );

        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF pn_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de lancer le traitement d''import AR pour l''org_id '|| TO_CHAR (pn_org_id)
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de lancer le traitement AR pour l''org_id ' || TO_CHAR (pn_org_id);
            RAISE e_error;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('- - launch_ar_interface (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END launch_ar_interface;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : RUN_ALL_INTERFACES
--  Description   : Lancement des Open Interface de AR et AP et attente qu'elles soient terminées
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE run_all_interfaces (
        pv_errbuf     OUT      VARCHAR2,
        pn_retcode    OUT      NUMBER,
        pd_ref_date   IN       DATE
    )
    IS
        e_error          EXCEPTION;
        vn_compteur      NUMBER (15);
        vn_request_id    fnd_concurrent_requests.request_id%TYPE;
        va_request_ids   Pa_Utils.idtabtyp;
        vv_phase         VARCHAR2 (100);
        vv_status        VARCHAR2 (100);
        vv_dev_phase     VARCHAR2 (100);
        vv_dev_status    VARCHAR2 (100);
        vv_message       VARCHAR2 (100);

        CURSOR interface_cur
        IS
            SELECT DISTINCT 'AR' MODULE,
                            DECODE (substr(hou.NAME,4), '0001', 1, '0804', 2, 99) priority,
                            hou.NAME company,
                            ril.org_id,
                            ril.batch_source_name ar_batch_source_name,
                            NULL ap_group_id,
                            NULL ap_source
            FROM            ra_interface_lines_all ril,
                            hr_all_organization_units hou
            WHERE               ril.batch_source_name = gv_ar_batch_source
                            AND ril.interface_line_context = gv_ar_interface_line_context
                            AND NVL (ril.interface_status, '~') != 'P'
                            AND hou.organization_id = ril.org_id
            UNION ALL
            SELECT DISTINCT 'AP' MODULE,
                            DECODE (substr(hou.NAME,4), '0001', 1, '0804', 2, 99) priority,
                            hou.NAME company,
                            aii.org_id,
                            NULL ar_batch_source_name,
                            aii.GROUP_ID ap_group_id,
                            aii.SOURCE ap_source
            FROM            ap_invoices_interface aii,
                            hr_all_organization_units hou
            WHERE               aii.SOURCE = gv_ap_source
                            AND (   aii.status IS NULL
                                 OR aii.status = 'REJECTED'
                                )
                            AND hou.organization_id = aii.org_id
            ORDER BY        priority ASC,
                            MODULE DESC;

        interface_rec    interface_cur%ROWTYPE;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- run_all_interfaces (+)');
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf      := NULL;
        pn_retcode     := 0;
        vn_compteur    := 0;



        FOR interface_rec IN interface_cur LOOP

            IF interface_rec.MODULE = 'AR'
            THEN
                -- Appel de la procédure AR --
                Dka_Sarrefac_Pkg.launch_ar_interface (
                    pv_errbuf,
                    pn_retcode,
                    interface_rec.org_id,
                    interface_rec.ar_batch_source_name,
                    pd_ref_date,
                    vn_request_id
                );
            ELSIF interface_rec.MODULE = 'AP'
            THEN
                -- Appel de la procédure AP --
                Dka_Sarrefac_Pkg.launch_ap_interface (
                    pv_errbuf,
                    pn_retcode,
                    interface_rec.org_id,
                    interface_rec.ap_source,
                    interface_rec.ap_group_id,
                    vn_request_id
                );
            END IF;

            IF pn_retcode != 0
            THEN
                Dka_Tools_Pkg.put_debug_message (
                       'ERREUR : Lancement du traitement '
                    || interface_rec.MODULE
                    || ' pour société '
                    || interface_rec.company
                    || ' a généré une erreur : '
                    || pv_errbuf
                );
                pn_retcode    := 1;
            END IF;

            Dka_Tools_Pkg.put_debug_message (
                   'Lancement du traitement d''import '
                || interface_rec.MODULE
                || ' pour société '
                || interface_rec.company
                || ' : '
                || TO_CHAR (vn_request_id)
            );
            vn_compteur                     := vn_compteur + 1;
            va_request_ids (vn_compteur)    := vn_request_id;
        END LOOP;

        -- Attente que les traitements soient tous terminés
        WHILE vn_compteur > 0  LOOP
            IF NOT (Fnd_Concurrent.wait_for_request (
                        va_request_ids (vn_compteur),
                        15,
                        0,
                        vv_phase,
                        vv_status,
                        vv_dev_phase,
                        vv_dev_status,
                        vv_message
                    )
                   )
            THEN
                Dka_Tools_Pkg.put_debug_message ('Traitement trop long: '|| TO_CHAR (va_request_ids (vn_compteur)));
                pv_errbuf     := 'Erreur sur le traitement ' || TO_CHAR (va_request_ids (vn_compteur));
                --  RAISE e_error;
                pn_retcode    := 1;
            ELSIF (    vv_dev_phase = 'COMPLETE'
                   AND vv_dev_status = 'NORMAL'
                  )
            THEN
                Dka_Tools_Pkg.put_debug_message ('Exécution du traitement '|| TO_CHAR (va_request_ids (vn_compteur)) || ' OK');
            END IF; -- fin IF NOT

            vn_compteur    := vn_compteur - 1;
        END LOOP;

        Dka_Tools_Pkg.put_debug_message ('Tous les traitements d''import sont terminés');
        Dka_Tools_Pkg.put_debug_message ('- run_all_interfaces (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := cv_program_code || pv_errbuf;
            pn_retcode    := 2;

        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;

    END run_all_interfaces;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_INVOICE_PRINTING_BIS
--  Description   : Lancement de l'impression de original de facture et annexe AR -- RECEPTEUR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_org_id               IN      NUMBER
--      pn_customer_trx_id      IN      NUMBER
--      pn_request_id           OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_invoice_printing_bis (
        pv_errbuf           OUT      VARCHAR2,
        pn_retcode          OUT      NUMBER,
        pn_org_id           IN       NUMBER,
        pv_trx_number       IN       VARCHAR2,
        pn_customer_id      IN       NUMBER,
        pv_to_acct_area     IN       VARCHAR2,
        pn_request_id_bis   OUT      NUMBER
    )
    IS
        e_error                    EXCEPTION;
        vn_to_user_id              fnd_user.user_id%TYPE;
        vv_original_printer_name   fnd_printer.printer_name%TYPE;
        l_layout boolean;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - launch_invoice_printing_bis (+)');

        --
        -- Récupération de l'utilisateur récepteur et de son imprimante pour l'original
        --
        BEGIN
            SELECT fu.user_id
            INTO   vn_to_user_id
            FROM   fnd_user fu
            WHERE  fu.user_name = pv_to_acct_area;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Dka_Tools_Pkg.put_debug_message ('Pas d''utilisateur pour le centre de gestion '|| pv_to_acct_area);
                pn_retcode    := 2;
                pv_errbuf     := 'Pas d''utilisateur pour le centre de gestion ' || pv_to_acct_area;
                RAISE e_error;
        END;

        -- Changement d'environnement
        Fnd_Global.apps_initialize (vn_to_user_id, gn_responsibility_id, gn_resp_application_id);
        -- Récupération imprimante
        vv_original_printer_name    := Fnd_Profile.VALUE ('PRINTER');
        Dka_Tools_Pkg.put_debug_message ('user_name : '|| pv_to_acct_area || ', printer :' || vv_original_printer_name);

        -- Positionnement des options pour impression original de facture
        /*IF NOT Fnd_Submit.set_print_options (
                   vv_original_printer_name, -- Printer
                   gv_invoice_print_style, -- Style
                   cn_number_of_copies -- Nb of copies
               )
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_submit.set_print_options" l''impression de original de facture '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.set_print_options" l''impression de original de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;*/

        -- Validation pour que les GTS puissent prendre la demande

        l_layout:=fnd_request.add_layout (
                      template_appl_name   => 'DKA',
                      template_code        => 'DKA_SARREFAC_GPE',
                      template_language    => 'fr', --Use language from template definition
                      template_territory   => 'F', --Use territory from template definition
                      output_format        => 'PDF' --Use output format from template definition
                        );

        -- Lancement impression de annexe
        pn_request_id_bis           :=
                Fnd_Request.submit_request (
                    'DKA', --APPL
                    'DKA_SARREFAC_GPE', --PROG
                    NULL, --PROGRAM_NAME
                    NULL,--Fnd_Date.date_to_canonical (SYSDATE + 1/24), --START
                    FALSE, --SUB_REQUEST
                    'TRX_NUMBER', --Order By                      -- Argument1
                    NULL, --Transaction_Class            -- Argument2
                    NULL, --Transaction_Type              -- Argument3
                    NULL, -- pv_trx_number, --Transaction_Number_Low        -- Argument4
                    NULL, -- pv_trx_number, --Transaction_Number_High       -- Argument5
                    NULL, --Date_Low                      -- Argument6
                    NULL, --Date High                     -- Argument7
                    NULL, --Customer_Class                -- Argument8
                    NULL, --pn_customer_id, --Customer_Id                   -- Argument9
                    NULL, --Open Invoices Only            -- Argument10
                    NULL, --cdg émetteur            -- Argument11
                    pv_to_acct_area, --cdg récepteur            -- Argument12
                    0, --Nb éditions déja effectuées : Factures jamais éditées pour sortir l'original
                    'OUI'
                );
        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF pn_request_id_bis = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de lancer l''impression de facture '|| pv_trx_number);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de lancer l''impression de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('- - end launch_invoice_printing_bis (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END launch_invoice_printing_bis;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_INVOICE_PRINTING
--  Description   : Lancement de l'impression de copie de facture et annexe AR -- EMETTEUR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_org_id               IN      NUMBER
--      pn_customer_trx_id      IN      NUMBER
--      pn_request_id           OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_invoice_printing (
        pv_errbuf           OUT      VARCHAR2,
        pn_retcode          OUT      NUMBER,
        pn_org_id           IN       NUMBER,
        pv_trx_number       IN       VARCHAR2,
        pn_customer_id      IN       NUMBER,
        pv_from_acct_area   IN       VARCHAR2,
        pn_request_id       OUT      NUMBER
    )
    IS
        e_error                EXCEPTION;
        vn_from_user_id        fnd_user.user_id%TYPE;
        vn_responsibility_id   fnd_responsibility.responsibility_id%TYPE;
        vn_application_id      fnd_application.application_id%TYPE;
        vv_copy_printer_name   fnd_printer.printer_name%TYPE;
        l_layout          boolean;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - launch_invoice_printing (+)');

        --
        -- Récupération de l'utilisateur émetteur et de son imprimante pour la copie
        --
        BEGIN
            SELECT fu.user_id
            INTO   vn_from_user_id
            FROM   fnd_user fu
            WHERE  fu.user_name = pv_from_acct_area;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Dka_Tools_Pkg.put_debug_message ('Pas d''utilisateur pour le centre de gestion '|| pv_from_acct_area);
                pn_retcode    := 2;
                pv_errbuf     := 'Pas d''utilisateur pour le centre de gestion ' || pv_from_acct_area;
                RAISE e_error;
        END;

        -- Changement d'environnement
        Fnd_Global.apps_initialize (vn_from_user_id, gn_responsibility_id, gn_resp_application_id);
        -- Récupération imprimante
        vv_copy_printer_name    := Fnd_Profile.VALUE ('PRINTER');
        Dka_Tools_Pkg.put_debug_message ('user_name : '|| pv_from_acct_area || ' , printer : ' || vv_copy_printer_name);

        IF vv_copy_printer_name IS NULL
        THEN
            Dka_Tools_Pkg.put_debug_message ('Pas d''imprimante pour le centre de gestion '|| pv_from_acct_area);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Pas d''imprimante pour le centre de gestion ' || pv_from_acct_area;
            RAISE e_error;
        END IF;

        -- Positionnement des options pour impression copie de facture
        /*IF NOT Fnd_Submit.set_print_options (
                   vv_copy_printer_name, -- Printer
                   gv_invoice_print_style, -- Style
                   cn_number_of_copies -- Nb of copies
               )
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_submit.set_print_options" l''impression de copie de facture '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.set_print_options" l''impression de copie de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;*/

        l_layout:=fnd_request.add_layout (
                      template_appl_name   => 'DKA',
                      template_code        => 'DKA_SARREFAC_GPE',
                      template_language    => 'fr', --Use language from template definition
                      template_territory   => 'F', --Use territory from template definition
                      output_format        => 'PDF' --Use output format from template definition
                        );

        -- Lancement impression de annexe
        pn_request_id           :=
                Fnd_Request.submit_request (
                    'DKA', --APPL
                    'DKA_SARREFAC_GPE', --PROG
                    NULL, --PROGRAM_NAME
                    NULL,--Fnd_Date.date_to_canonical (SYSDATE + 1/24), --START
                    FALSE, --SUB_REQUEST
                    'TRX_NUMBER', --Order By                      -- Argument1
                    NULL, --Transaction_Class            -- Argument2
                    NULL, --Transaction_Type              -- Argument3
                    NULL, --pv_trx_number, --Transaction_Number_Low        -- Argument4
                    NULL, --pv_trx_number, --Transaction_Number_High       -- Argument5
                    NULL, --Date_Low                      -- Argument6
                    NULL, --Date High                     -- Argument7
                    NULL, --Customer_Class                -- Argument8
                    NULL, --pn_customer_id, --Customer_Id                   -- Argument9
                    NULL, --Open Invoices Only            -- Argument10
                    pv_from_acct_area, --cdg émetteur            -- Argument11
                    NULL, --cdg récepteur            -- Argument12
                    1, --Nb éditions déja effectuées : Factures éditées une fois pour sortir la copie
                    'OUI'
                );
        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;
        Dka_Tools_Pkg.put_debug_message ('nb copies : '|| cn_number_of_copies);

        IF pn_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de lancer l''impression de facture '|| pv_trx_number);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de lancer l''impression de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Changement d'environnement - retour a la resp. 'Exploit'
        Dka_Tools_Pkg.put_debug_message ('- - end launch_invoice_printing (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END launch_invoice_printing;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : RUN_ALL_INVOICE_PRINTING
--  Description   : Lancement des impressions originaux, copies et annexes de factures
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
-- artf2572923 : lancement de la procédure dans une transaction autonome post price en compte AP et AR
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE run_all_invoice_printing (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        e_error_main   EXCEPTION;
        vd_ref_date    DATE;
        vn_result      NUMBER (22);

        e_error                    EXCEPTION;
        vn_from_user_id            fnd_user.user_id%TYPE;
        vn_to_user_id              fnd_user.user_id%TYPE;
        vv_original_printer_name   fnd_printer.printer_name%TYPE;
        vv_copy_printer_name       fnd_printer.printer_name%TYPE;

        CURSOR print_invoices_cur
        IS
            SELECT DISTINCT SUBSTR (
                                rct.interface_header_attribute1,
                                (INSTR (rct.interface_header_attribute1, '/', 1, 2) + 1),
                                (  INSTR (rct.interface_header_attribute1, '/', 1, 3)
                                 - INSTR (rct.interface_header_attribute1, '/', 1, 2)
                                 - 1
                                )
                            ) from_acct_area
            FROM            ra_cust_trx_types_all rctt,
                            ra_customer_trx_all rct,
                            RA_CUST_TRX_LINE_GL_DIST_ALL rctlgd,
                            ap_invoices_all ai,
                            gl_code_combinations gcc_ap,
                            gl_code_combinations gcc_ar,
                            hr_all_organization_units haou_ap,
                            hr_all_organization_units haou_ar
            WHERE           1 = 1
                            AND NVL (rct.printing_count, 1) = 1
                            AND rctt.cust_trx_type_id = rct.cust_trx_type_id
                            AND rctt.name IN (gv_ar_cust_trx_type, gv_ar_cust_trx_type_cm) -- ex : name de la forme 0001_REFAC
                            AND rctlgd.customer_trx_id = rct.customer_trx_id
                            AND rctlgd.account_class = 'REC'
                            AND ai.invoice_num = rct.trx_number
                            AND gcc_ar.code_combination_id = rctlgd.code_combination_id
                            AND gcc_ap.code_combination_id = ai.accts_pay_code_combination_id
                            and ai.org_id = haou_ap.organization_id
                            and rct.org_id = haou_ar.organization_id
                            AND substr(gcc_ar.segment5,4,4) = SUBSTR (haou_ap.name, 4)
                            AND substr(gcc_ap.segment5,4,4) = SUBSTR (haou_ar.name, 4)
                            AND NOT EXISTS ( SELECT 1
                                             FROM   dka_sarrefac_trx_non_oa_soc dstnos
                                             WHERE      dstnos.trx_number = rct.trx_number
                                                    AND dstnos.ar_org_name = SUBSTR (haou_ar.name, 4)
                                                    AND dstnos.created_in_ar_flag = 'Y');

        CURSOR print_invoices_cur_bis
        IS
            SELECT DISTINCT SUBSTR (rct.interface_header_attribute1, (INSTR (rct.interface_header_attribute1, '/', 1, 4) + 1)) to_acct_area
            FROM            ra_cust_trx_types_all rctt,
                            ra_customer_trx_all rct,
                            ra_cust_trx_line_gl_dist_all rctlgd,
                            ap_invoices_all ai,
                            gl_code_combinations gcc_ap,
                            gl_code_combinations gcc_ar,
                            hr_all_organization_units haou_ap,
                            hr_all_organization_units haou_ar
            WHERE           1 = 1
                            AND NVL (rct.printing_count, 0) = 0
                            AND rctt.cust_trx_type_id = rct.cust_trx_type_id
                            AND rctt.name IN (gv_ar_cust_trx_type, gv_ar_cust_trx_type_cm) -- ex : name de la forme 0001_REFAC
                            AND rctlgd.customer_trx_id = rct.customer_trx_id
                            AND rctlgd.account_class = 'REC'
                            AND ai.invoice_num = rct.trx_number
                            AND gcc_ar.code_combination_id = rctlgd.code_combination_id
                            AND gcc_ap.code_combination_id = ai.accts_pay_code_combination_id
                            and ai.org_id = haou_ap.organization_id
                            and rct.org_id = haou_ar.organization_id
                            AND substr(gcc_ar.segment5,4,4) = SUBSTR (haou_ap.name, 4)
                            AND substr(gcc_ap.segment5,4,4) = SUBSTR (haou_ar.name, 4)
                            AND NOT EXISTS ( SELECT 1
                                             FROM   dka_sarrefac_trx_non_oa_soc dstnos
                                             WHERE      dstnos.trx_number = rct.trx_number
                                                    AND dstnos.ar_org_name = SUBSTR (haou_ar.name, 4)
                                                    AND dstnos.created_in_ar_flag = 'Y');

        print_invoices_rec         print_invoices_cur%ROWTYPE;
        print_invoices_rec_bis     print_invoices_cur_bis%ROWTYPE;
        vn_request_id              fnd_concurrent_requests.request_id%TYPE;
        vn_request_id_bis          fnd_concurrent_requests.request_id%TYPE;

        TYPE t_request_id IS TABLE OF NUMBER index by binary_integer;
        vt_request_id t_request_id;

        vv_phase         VARCHAR2 (100);
        vv_status        VARCHAR2 (100);
        vv_dev_phase     VARCHAR2 (100);
        vv_dev_status    VARCHAR2 (100);
        vv_message       VARCHAR2 (100);


    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- run_all_invoice_printing (+)');

        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Initialisation');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.init (pv_errbuf, vn_result, vd_ref_date);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Lancement des éditions');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');

        BEGIN
            FOR print_invoices_rec_bis IN print_invoices_cur_bis LOOP

                Dka_Tools_Pkg.put_debug_message ('- curseur print_invoices_cur_bis - '||print_invoices_rec_bis.to_acct_area);

                Dka_Sarrefac_Pkg.launch_invoice_printing_bis ( --original sur récepteur
                    pv_errbuf,
                    pn_retcode,
                    NULL, --print_invoices_rec.org_id,
                    NULL, --print_invoices_rec.trx_number,
                    NULL, --print_invoices_rec.customer_id,
                    print_invoices_rec_bis.to_acct_area,
                    vn_request_id_bis
                );

                IF pn_retcode != 0
                THEN
                    Dka_Tools_Pkg.put_debug_message ('ERREUR: Lancement du traitement a généré une erreur: '|| pv_errbuf);
                    pn_retcode    := 1;
                ELSE
                    vt_request_id(vt_request_id.count+1) := vn_request_id_bis;
                    Dka_Tools_Pkg.put_debug_message ('Lancement du traitement '|| TO_CHAR (vn_request_id_bis));
                END IF;

            END LOOP;

        END;

         -- Changement d'environnement - retour au user 'Exploit'
         Fnd_Global.apps_initialize (gn_user_id, gn_responsibility_id, gn_resp_application_id);


        --Attente fin des traitements originaux
        Dka_Tools_Pkg.put_debug_message ('Attente fin des traitements originaux');
        IF vt_request_id.count > 0 THEN
          FOR i IN vt_request_id.first..vt_request_id.last LOOP
            IF NOT (Fnd_Concurrent.wait_for_request (
                        vt_request_id (i),
                        15,
                        0,
                        vv_phase,
                        vv_status,
                        vv_dev_phase,
                        vv_dev_status,
                        vv_message
                    )
                   )
            THEN
                Dka_Tools_Pkg.put_debug_message ('Traitement trop long: '|| TO_CHAR (vt_request_id (i)));
                pv_errbuf     := 'Erreur sur le traitement ' || TO_CHAR (vt_request_id (i));
            END IF; -- fin IF NOT
          END LOOP;
        END IF;


        BEGIN

            FOR print_invoices_rec IN print_invoices_cur LOOP
                Dka_Tools_Pkg.put_debug_message ('- curseur print_invoices_cur - '||print_invoices_rec.from_acct_area);


                Dka_Sarrefac_Pkg.launch_invoice_printing ( -- copie sur émetteur
                    pv_errbuf,
                    pn_retcode,
                    NULL, --print_invoices_rec.org_id,
                    NULL, --print_invoices_rec.trx_number,
                    NULL, --print_invoices_rec.customer_id,
                    print_invoices_rec.from_acct_area,
                    --print_invoices_rec.to_acct_area,
                    vn_request_id
                );

                 IF pn_retcode != 0
                THEN
                    Dka_Tools_Pkg.put_debug_message ('ERREUR: Lancement du traitement a généré une erreur: '|| pv_errbuf);
                    pn_retcode    := 1;
                ELSE
                   Dka_Tools_Pkg.put_debug_message ('Lancement du traitement '|| TO_CHAR (vn_request_id));
                END IF;

            END LOOP;

        END;

        Dka_Tools_Pkg.put_debug_message ('- run_all_invoice_printing (-)');

        -- Changement d'environnement - retour au user 'Exploit'
        --Fnd_Global.apps_initialize (gn_user_id, gn_responsibility_id, gn_resp_application_id);

    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := cv_program_code || pv_errbuf;
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END run_all_invoice_printing;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_NON_OA_AR_INV_CP  --émetteur - copie / annexe
--  Description   : Lancement de l'impression de facture non OA dans AR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_org_id               IN      NUMBER
--      pv_trx_number           IN      VARCHAR2
--      pn_request_id           OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_non_oa_ar_inv_cp (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_refac_request_id   IN       NUMBER,
        pn_org_id             IN       NUMBER,
        pv_org_name           IN       VARCHAR2,
        pv_trx_number         IN       VARCHAR2,
        pv_from_acct_area     IN       VARCHAR2,
        pv_to_acct_area       IN       VARCHAR2,
        pn_customer_id        IN       NUMBER,
        pn_request_id         OUT      NUMBER
    )
    IS
        e_error                EXCEPTION;
        vn_from_user_id        fnd_user.user_id%TYPE;
        vn_responsibility_id   fnd_responsibility.responsibility_id%TYPE;
        vn_application_id      fnd_application.application_id%TYPE;
        vv_copy_printer_name   fnd_printer.printer_name%TYPE;

    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - launch_non_oa_ar_inv_cp (+)');

        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = gv_ar_responsibility_key;

        --
        -- Récupération de l'utilisateur émetteur et de son imprimante pour la copie
        --
        BEGIN
            SELECT fu.user_id
            INTO   vn_from_user_id
            FROM   fnd_user fu
            WHERE  fu.user_name = pv_from_acct_area;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Dka_Tools_Pkg.put_debug_message ('Pas d''utilisateur pour le centre de gestion '|| pv_from_acct_area);
                pn_retcode    := 2;
                pv_errbuf     := 'Pas d''utilisateur pour le centre de gestion ' || pv_from_acct_area;
                RAISE e_error;
        END;

        -- Changement d'environnement
        Fnd_Global.apps_initialize (vn_from_user_id, vn_responsibility_id, vn_application_id);
        -- Récupération imprimante
        vv_copy_printer_name    := Fnd_Profile.VALUE ('PRINTER');

        IF vv_copy_printer_name IS NULL
        THEN
            Dka_Tools_Pkg.put_debug_message ('Pas d''imprimante pour le centre de gestion '|| pv_from_acct_area);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Pas d''imprimante pour le centre de gestion ' || pv_from_acct_area;
            RAISE e_error;
        END IF;

        --
        -- Lancement du jeu de traitements
        --

        -- Initialisation
        IF NOT Fnd_Submit.set_request_set ('DKA', 'DKA_SARREFAC_NON_OA_AR_INV_CP')
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_submit.set_request_set" l''impression de facture '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.set_request_set" l''impression de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Positionnement des options pour impression copie de facture
        IF NOT Fnd_Submit.set_print_options (
                   vv_copy_printer_name, -- Printer
                   gv_invoice_print_style, -- Style
                   cn_number_of_copies -- Nb of copies
               )
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_submit.set_print_options" l''impression de copie de facture '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.set_print_options" l''impression de copie de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Lancement impression copie de facture
        IF NOT Fnd_Submit.submit_program (
                   'DKA', -- Application
                   'DKA_SARREFAC_INVOICE', -- Program
                   'STAGE03', -- Stage
                   'TRX_NUMBER', --Order By                      -- Argument1
                   NULL, --Transaction_Class            -- Argument2
                   NULL, --Transaction_Type              -- Argument3
                   pv_trx_number, --Transaction_Number_Low        -- Argument4
                   pv_trx_number, --Transaction_Number_High       -- Argument5
                   NULL, --Date_Low                      -- Argument6
                   NULL, --Date High                     -- Argument7
                   NULL, --Customer_Class                -- Argument8
                   pn_customer_id, --Customer_Id                   -- Argument9
                   NULL --Open Invoices Only            -- Argument10
               )
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_submit.submit_program" l''impression de copie de facture '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.submit_program" l''impression de copie de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;


        -- Lancement impression de annexe
        IF NOT Fnd_Submit.submit_program (
                   'DKA', -- Application
                   'DKA_SARREFAC_NON_OA_APPENDIX', -- Program
                   'STAGE04', -- Stage
                   pn_refac_request_id, -- Argument1
                   pv_org_name, -- Argument2
                   pv_trx_number -- Argument3
               )
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de "fnd_submit.submit_program" l''impression de annexe '|| pv_trx_number);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.submit_program" l''impression de annexe ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Lancement du jeu
        pn_request_id           := Fnd_Submit.submit_set ();
        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF pn_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de lancer l''impression de facture '|| pv_trx_number);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de lancer l''impression de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('- - launch_non_oa_ar_inv_cp (-)');
        -- Changement d'environnement
        Fnd_Global.apps_initialize (gn_user_id, vn_responsibility_id, vn_application_id);

    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END launch_non_oa_ar_inv_cp;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_NON_OA_AR_INV_ORIG  --récepteur - original / annexe
--  Description   : Lancement de l'impression de facture non OA dans AR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_org_id               IN      NUMBER
--      pv_trx_number           IN      VARCHAR2
--      pn_request_id           OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_non_oa_ar_inv_orig (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_refac_request_id   IN       NUMBER,
        pn_org_id             IN       NUMBER,
        pv_org_name           IN       VARCHAR2,
        pv_trx_number         IN       VARCHAR2,
        pv_from_acct_area     IN       VARCHAR2,
        pv_to_acct_area       IN       VARCHAR2,
        pn_customer_id        IN       NUMBER,
        pn_request_id         OUT      NUMBER
    )
    IS
        e_error                    EXCEPTION;
        vn_to_user_id              fnd_user.user_id%TYPE;
        vn_responsibility_id       fnd_responsibility.responsibility_id%TYPE;
        vn_application_id          fnd_application.application_id%TYPE;
        vv_original_printer_name   fnd_printer.printer_name%TYPE;

    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - launch_non_oa_ar_inv_orig (+)');

        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = gv_ar_responsibility_key;

        --
        -- Récupération de l'utilisateur récepteur et de son imprimante pour l'original
        --
        BEGIN
            SELECT fu.user_id
            INTO   vn_to_user_id
            FROM   fnd_user fu
            WHERE  fu.user_name = pv_to_acct_area;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Dka_Tools_Pkg.put_debug_message ('Pas d''utilisateur pour le centre de gestion '|| pv_to_acct_area);
                pn_retcode    := 2;
                pv_errbuf     := 'Pas d''utilisateur pour le centre de gestion ' || pv_to_acct_area;
                RAISE e_error;
        END;

        -- Changement d'environnement
        Fnd_Global.apps_initialize (vn_to_user_id, vn_responsibility_id, vn_application_id);
        -- Récupération imprimante
        vv_original_printer_name    := Fnd_Profile.VALUE ('PRINTER');

        IF vv_original_printer_name IS NULL
        THEN
            Dka_Tools_Pkg.put_debug_message ('Pas d''imprimante pour le centre de gestion '|| pv_to_acct_area);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Pas d''imprimante pour le centre de gestion ' || pv_to_acct_area;
            RAISE e_error;
        END IF;

        --
        -- Lancement du jeu de traitements
        --
        -- Initialisation
        IF NOT Fnd_Submit.set_request_set ('DKA', 'DKA_SARREFAC_NON_OA_AR_INV_ORI')
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_submit.set_request_set" l''impression de facture '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.set_request_set" l''impression de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Positionnement des options pour impression original de facture
        IF NOT Fnd_Submit.set_print_options (
                   vv_original_printer_name, -- Printer
                   gv_invoice_print_style, -- Style
                   cn_number_of_copies -- Nb of copies
               )
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_submit.set_print_options" l''impression de original de facture '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.set_print_options" l''impression de original de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Lancement impression original de facture
        IF NOT Fnd_Submit.submit_program (
                   'DKA', -- Application
                   'DKA_SARREFAC_INVOICE', -- Program
                   'STAGE01', -- Stage
                   'TRX_NUMBER', --Order By                      -- Argument1
                   NULL, --Transaction_Class            -- Argument2
                   NULL, --Transaction_Type              -- Argument3
                   pv_trx_number, --Transaction_Number_Low        -- Argument4
                   pv_trx_number, --Transaction_Number_High       -- Argument5
                   NULL, --Date_Low                      -- Argument6
                   NULL, --Date High                     -- Argument7
                   NULL, --Customer_Class                -- Argument8
                   pn_customer_id, --Customer_Id                   -- Argument9
                   NULL --Open Invoices Only            -- Argument10
               )
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_submit.submit_program" l''impression de original de facture '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.submit_program" l''impression de original de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Lancement impression de l'annexe
        IF NOT Fnd_Submit.submit_program (
                   'DKA', -- Application
                   'DKA_SARREFAC_NON_OA_APPENDIX', -- Program
                   'STAGE04', -- Stage
                   pn_refac_request_id, -- Argument1
                   pv_org_name, -- Argument2
                   pv_trx_number -- Argument3
               )
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de "fnd_submit.submit_program" l''impression de annexe '|| pv_trx_number);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_submit.submit_program" l''impression de annexe ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Lancement du jeu
        pn_request_id               := Fnd_Submit.submit_set ();
        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF pn_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de lancer l''impression de facture '|| pv_trx_number);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de lancer l''impression de facture ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Changement d'environnement
        Fnd_Global.apps_initialize (gn_user_id, vn_responsibility_id, vn_application_id);
        Dka_Tools_Pkg.put_debug_message ('- - launch_non_oa_ar_inv_orig (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END launch_non_oa_ar_inv_orig;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_NON_OA_NON_AR_INV_CP  -émetteur, copie
--  Description   : Lancement de l'impression de facture non OA pas dans AR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_org_id               IN      NUMBER
--      pv_trx_number           IN      VARCHAR2
--      pn_request_id           OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_non_oa_non_ar_inv_cp (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_refac_request_id   IN       NUMBER,
        pn_org_id             IN       NUMBER,
        pv_org_name           IN       VARCHAR2,
        pv_trx_number         IN       VARCHAR2,
        pv_from_acct_area     IN       VARCHAR2,
        pv_to_acct_area       IN       VARCHAR2,
        pn_request_id         OUT      NUMBER
    )
    IS
        e_error                EXCEPTION;
        vn_from_user_id        fnd_user.user_id%TYPE;
        vn_responsibility_id   fnd_responsibility.responsibility_id%TYPE;
        vn_application_id      fnd_application.application_id%TYPE;
        vv_copy_printer_name   fnd_printer.printer_name%TYPE;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - launch_non_oa_non_ar_inv_print_cp (+)');

        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = gv_ar_responsibility_key;

        --
        -- Récupération de l'utilisateur émetteur et de son imprimante pour la copie
        --
        BEGIN
            SELECT fu.user_id
            INTO   vn_from_user_id
            FROM   fnd_user fu
            WHERE  fu.user_name = pv_from_acct_area;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Dka_Tools_Pkg.put_debug_message ('Pas d''utilisateur pour le centre de gestion '|| pv_from_acct_area);
                pn_retcode    := 2;
                pv_errbuf     := 'Pas d''utilisateur pour le centre de gestion ' || pv_from_acct_area;
                RAISE e_error;
        END;

        -- Changement d'environnement
        Fnd_Global.apps_initialize (vn_from_user_id, vn_responsibility_id, vn_application_id);
        -- Récupération imprimante
        vv_copy_printer_name    := Fnd_Profile.VALUE ('PRINTER');

        IF vv_copy_printer_name IS NULL
        THEN
            Dka_Tools_Pkg.put_debug_message ('Pas d''imprimante pour le centre de gestion '|| pv_from_acct_area);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Pas d''imprimante pour le centre de gestion ' || pv_from_acct_area;
            RAISE e_error;
        END IF;

        --
        -- Lancement du traitement
        --

        -- Ajout de la seconde imprimante
        IF NOT Fnd_Request.set_print_options (vv_copy_printer_name, -- Printer
                                              gv_invoice_print_style, -- Style
                                              cn_number_of_copies -- Nb of copies
                                                                                      )
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_request.set_print_options" l''impression de annexe '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_request.set_print_options" l''impression de annexe ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Lancement impression de annexe
        pn_request_id           :=
                Fnd_Request.submit_request (
                    'DKA', --APPL
                    'DKA_SARREFAC_NON_OA_APPENDIX', --PROG
                    NULL, --PROGRAM_NAME
                    NULL,--Fnd_Date.date_to_canonical (SYSDATE + 1/24), --START
                    FALSE, --SUB_REQUEST
                    pn_refac_request_id, --Refac_Request_Id          --ARGUMENT1
                    pv_org_name, --AR_Org_Name              --ARGUMENT2
                    pv_trx_number --Trx_Number            --ARGUMENT3
                );
        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF pn_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de "fnd_request.submit_request" l''impression de annexe '|| pv_trx_number);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_request.submit_request" l''impression de annexe ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Changement d'environnement
        Fnd_Global.apps_initialize (gn_user_id, vn_responsibility_id, vn_application_id);
        Dka_Tools_Pkg.put_debug_message ('- - launch_non_oa_non_ar_inv_cp (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END launch_non_oa_non_ar_inv_cp;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_NON_OA_NON_AR_INV_ORIG - récepteur / original
--  Description   : Lancement de l'impression de facture non OA pas dans AR
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--      pn_org_id               IN      NUMBER
--      pv_trx_number           IN      VARCHAR2
--      pn_request_id           OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       : Id du traitement lancé
--     Valeurs possibles :
--
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE launch_non_oa_non_ar_inv_orig (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_refac_request_id   IN       NUMBER,
        pn_org_id             IN       NUMBER,
        pv_org_name           IN       VARCHAR2,
        pv_trx_number         IN       VARCHAR2,
        pv_from_acct_area     IN       VARCHAR2,
        pv_to_acct_area       IN       VARCHAR2,
        pn_request_id         OUT      NUMBER
    )
    IS
        e_error                    EXCEPTION;
        vn_to_user_id              fnd_user.user_id%TYPE;
        vn_responsibility_id       fnd_responsibility.responsibility_id%TYPE;
        vn_application_id          fnd_application.application_id%TYPE;
        vv_original_printer_name   fnd_printer.printer_name%TYPE;

    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- - launch_non_oa_non_ar_inv_orig (+)');

        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  responsibility_key = gv_ar_responsibility_key;

        --
        -- Récupération de l'utilisateur récepteur et de son imprimante pour l'original
        --
        BEGIN
            SELECT fu.user_id
            INTO   vn_to_user_id
            FROM   fnd_user fu
            WHERE  fu.user_name = pv_to_acct_area;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                Dka_Tools_Pkg.put_debug_message ('Pas d''utilisateur pour le centre de gestion '|| pv_to_acct_area);
                pn_retcode    := 2;
                pv_errbuf     := 'Pas d''utilisateur pour le centre de gestion ' || pv_to_acct_area;
                RAISE e_error;
        END;

        -- Changement d'environnement
        Fnd_Global.apps_initialize (vn_to_user_id, vn_responsibility_id, vn_application_id);
        -- Récupération imprimante
        vv_original_printer_name    := Fnd_Profile.VALUE ('PRINTER');

        --
        -- Lancement du traitement
        --

        -- Positionnement des options pour impression original de facture
        IF NOT Fnd_Request.set_print_options (
                   vv_original_printer_name, -- Printer
                   gv_appendix_print_style, -- Style
                   cn_number_of_copies -- Nb of copies
               )
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de "fnd_request.set_print_options" l''impression de annexe '|| pv_trx_number
            );
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_request.set_print_options" l''impression de annexe ' || pv_trx_number;
            RAISE e_error;
        END IF;

        -- Lancement impression de annexe
        pn_request_id               :=
                Fnd_Request.submit_request (
                    'DKA', --APPL
                    'DKA_SARREFAC_NON_OA_APPENDIX', --PROG
                    NULL, --PROGRAM_NAME
                    NULL,--Fnd_Date.date_to_canonical (SYSDATE + 1/24), --START
                    FALSE, --SUB_REQUEST
                    pn_refac_request_id, --Refac_Request_Id          --ARGUMENT1
                    pv_org_name, --AR_Org_Name               --ARGUMENT2
                    pv_trx_number --Trx_Number                --ARGUMENT3
                );
        -- Validation pour que les GTS puissent prendre la demande
        COMMIT;

        IF pn_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message ('Impossible de "fnd_request.submit_request" l''impression de annexe '|| pv_trx_number);
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            pn_retcode    := 2;
            pv_errbuf     := 'Impossible de "fnd_request.submit_request" l''impression de annexe ' || pv_trx_number;
            RAISE e_error;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('- - launch_non_oa_non_ar_inv_orig (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf    := cv_program_code || pv_errbuf;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END launch_non_oa_non_ar_inv_orig;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : RUN_ALL_NON_OA_INV_PRINT
--  Description   : Lancement des impressions de factures et annexes non OA
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE run_all_non_oa_inv_print (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        e_error                    EXCEPTION;
        vv_copy_printer_name       fnd_printer.printer_name%TYPE;
        vn_from_user_id            fnd_user.user_id%TYPE;
        vn_responsibility_id       fnd_responsibility.responsibility_id%TYPE;
        vn_application_id          fnd_application.application_id%TYPE;
        vn_to_user_id              fnd_user.user_id%TYPE;
        vv_original_printer_name   fnd_printer.printer_name%TYPE;
        vv_org_name                hr_all_organization_units.NAME%TYPE;

        CURSOR print_invoices_cur
        IS
            SELECT DISTINCT dstnos.trx_number trx_number,
                            dstnos.request_id request_id,
                            dstnos.ar_org_id org_id,
                            dstnos.ar_org_name org_name,
                            dstnos.created_in_ar_flag created_in_ar_flag,
                            dstnos.ar_customer_id customer_id,
                            SUBSTR (
                                dstnos.trx_reference,
                                (INSTR (dstnos.trx_reference, cv_separator, 1, 2) + 1),
                                (  INSTR (dstnos.trx_reference, cv_separator, 1, 3)
                                 - INSTR (dstnos.trx_reference, cv_separator, 1, 2)
                                 - 1
                                )
                            ) from_acct_area,
                            SUBSTR (dstnos.trx_reference, (INSTR (dstnos.trx_reference, cv_separator, 1, 4) + 1)) to_acct_area
            FROM            dka_sarrefac_trx_non_oa_soc dstnos
            WHERE               dstnos.request_id = gn_conc_request_id
                            AND dstnos.created_in_ar_flag = 'N'
            UNION ALL
            SELECT DISTINCT dstnos.trx_number trx_number,
                            dstnos.request_id request_id,
                            dstnos.ar_org_id org_id,
                            dstnos.ar_org_name org_name,
                            dstnos.created_in_ar_flag created_in_ar_flag,
                            dstnos.ar_customer_id customer_id,
                            SUBSTR (
                                dstnos.trx_reference,
                                (INSTR (dstnos.trx_reference, cv_separator, 1, 2) + 1),
                                (  INSTR (dstnos.trx_reference, cv_separator, 1, 3)
                                 - INSTR (dstnos.trx_reference, cv_separator, 1, 2)
                                 - 1
                                )
                            ) from_acct_area,
                            SUBSTR (dstnos.trx_reference, (INSTR (dstnos.trx_reference, cv_separator, 1, 4) + 1)) to_acct_area
            FROM            dka_sarrefac_trx_non_oa_soc dstnos,
                            ra_cust_trx_types_all rctt,
                            ra_customer_trx_all rct
            WHERE               dstnos.created_in_ar_flag = 'Y'
                            AND rct.cust_trx_type_id = rctt.cust_trx_type_id
                            AND SUBSTR(rctt.name, 1, 4) = dstnos.ar_org_name
                            AND rct.trx_number = dstnos.trx_number
                            AND NVL (rct.printing_count, 0) = 0;

        print_invoices_rec         print_invoices_cur%ROWTYPE;
        vn_request_id              fnd_concurrent_requests.request_id%TYPE;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- run_all_non_oa_inv_print (+)');

        -- Récupération de la responsabilité
            SELECT fr.responsibility_id,
                   fr.application_id
            INTO   vn_responsibility_id,
                   vn_application_id
            FROM   fnd_responsibility fr
            WHERE  responsibility_key = gv_ar_responsibility_key;

        FOR print_invoices_rec IN print_invoices_cur LOOP
            --
            -- Récupération de l'utilisateur émetteur et de son imprimante pour la copie
            --
            BEGIN
                SELECT fu.user_id
                INTO   vn_from_user_id
                FROM   fnd_user fu
                WHERE  fu.user_name = print_invoices_rec.from_acct_area; --pv_from_acct_area;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    Dka_Tools_Pkg.put_debug_message (
                        'Pas d''utilisateur pour le centre de gestion '|| print_invoices_rec.from_acct_area
                    ); --pv_from_acct_area);
                    pn_retcode    := 2;
                    pv_errbuf     := 'Pas d''utilisateur pour le centre de gestion ' || print_invoices_rec.from_acct_area; --pv_from_acct_area;
                    RAISE e_error;
            END;

            Dka_Tools_Pkg.put_debug_message ('user émetteur :'|| vn_from_user_id);

            -- Changement d'environnement
            Fnd_Global.apps_initialize (vn_from_user_id, vn_responsibility_id, vn_application_id);

            -- Récupération imprimante
            --vv_copy_printer_name    := Fnd_Profile.VALUE ('PRINTER');
            --Dka_Tools_Pkg.put_debug_message ('printer émetteur :'|| vv_copy_printer_name);

            /*IF vv_copy_printer_name IS NULL
            THEN
                Dka_Tools_Pkg.put_debug_message (
                    'Pas d''imprimante pour le centre de gestion '|| print_invoices_rec.from_acct_area
                ); --pv_from_acct_area);
                Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
                pn_retcode    := 2;
                pv_errbuf     := 'Pas d''imprimante pour le centre de gestion ' || print_invoices_rec.from_acct_area; --pv_from_acct_area;
                RAISE e_error;
            END IF;*/


            --
            -- Récupération de l'utilisateur récepteur et de son imprimante pour l'original
            --
            BEGIN
                SELECT fu.user_id
                INTO   vn_to_user_id
                FROM   fnd_user fu
                WHERE  fu.user_name = print_invoices_rec.to_acct_area; --pv_to_acct_area;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    Dka_Tools_Pkg.put_debug_message (
                        'Pas d''utilisateur pour le centre de gestion '|| print_invoices_rec.to_acct_area
                    );
                    pn_retcode    := 2;
                    pv_errbuf     := 'Pas d''utilisateur pour le centre de gestion ' || print_invoices_rec.to_acct_area; --pv_to_acct_area;
                    RAISE e_error;
            END;

            Dka_Tools_Pkg.put_debug_message ('user recepteur :'|| vn_to_user_id);

            IF print_invoices_rec.created_in_ar_flag = 'Y'
            THEN
                -- Changement d'environnement
                Fnd_Global.apps_initialize (vn_to_user_id, vn_responsibility_id, vn_application_id);
                -- Récupération imprimante
                --vv_original_printer_name    := Fnd_Profile.VALUE ('PRINTER');
                --Dka_Tools_Pkg.put_debug_message ('printer recepteur :'|| vv_original_printer_name);

                /*IF NOT Fnd_Submit.set_print_options (
                           vv_original_printer_name, -- Printer
                           gv_invoice_print_style, -- Style
                           cn_number_of_copies -- Nb of copies
                       )
                THEN
                    Dka_Tools_Pkg.put_debug_message (
                           'Impossible de "fnd_submit.set_print_options" l''impression de original de facture '
                        || print_invoices_rec.trx_number --pv_trx_number
                    );
                    Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
                    pn_retcode    := 2;
                    pv_errbuf     :=    'Impossible de "fnd_submit.set_print_options" l''impression de original de facture '
                                     || print_invoices_rec.trx_number; --pv_trx_number;
                    RAISE e_error;
                END IF;*/

                Dka_Sarrefac_Pkg.launch_non_oa_ar_inv_orig (
                    pv_errbuf,
                    pn_retcode,
                    print_invoices_rec.request_id,
                    print_invoices_rec.org_id,
                    print_invoices_rec.org_name,
                    print_invoices_rec.trx_number,
                    print_invoices_rec.from_acct_area,
                    print_invoices_rec.to_acct_area,
                    print_invoices_rec.customer_id,
                    vn_request_id
                );
                -- Changement d'environnement
                Fnd_Global.apps_initialize (vn_from_user_id, vn_responsibility_id, vn_application_id);
                -- Récupération imprimante
                --vv_copy_printer_name        := Fnd_Profile.VALUE ('PRINTER');

                -- Changement imprimante
                /*IF NOT Fnd_Submit.set_print_options (
                           vv_copy_printer_name, -- Printer
                           gv_invoice_print_style, -- Style
                           cn_number_of_copies -- Nb of copies
                       )
                THEN
                    Dka_Tools_Pkg.put_debug_message (
                           'Impossible de "fnd_submit.set_print_options" l''impression de copie de facture '
                        || print_invoices_rec.trx_number --pv_trx_number
                    );
                    Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
                    pn_retcode    := 2;
                    pv_errbuf     :=    'Impossible de "fnd_submit.set_print_options" l''impression de copie de facture '
                                     || print_invoices_rec.trx_number; --pv_trx_number;
                    RAISE e_error;
                END IF;*/

                Dka_Sarrefac_Pkg.launch_non_oa_ar_inv_cp (
                    pv_errbuf,
                    pn_retcode,
                    print_invoices_rec.request_id,
                    print_invoices_rec.org_id,
                    print_invoices_rec.org_name,
                    print_invoices_rec.trx_number,
                    print_invoices_rec.from_acct_area,
                    print_invoices_rec.to_acct_area,
                    print_invoices_rec.customer_id,
                    vn_request_id
                );
            ELSE
                -- Changement d'environnement
                Fnd_Global.apps_initialize (vn_to_user_id, vn_responsibility_id, vn_application_id);
                -- Récupération imprimante
                vv_original_printer_name    := Fnd_Profile.VALUE ('PRINTER');

                -- Récupération imprimante
                IF NOT Fnd_Submit.set_print_options (
                           vv_original_printer_name, -- Printer
                           gv_invoice_print_style, -- Style
                           cn_number_of_copies -- Nb of copies
                       )
                THEN
                    Dka_Tools_Pkg.put_debug_message (
                           'Impossible de "fnd_submit.set_print_options" l''impression de original de facture '
                        || print_invoices_rec.trx_number --pv_trx_number
                    );
                    Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
                    pn_retcode    := 2;
                    pv_errbuf     :=    'Impossible de "fnd_submit.set_print_options" l''impression de original de facture '
                                     || print_invoices_rec.trx_number; --pv_trx_number;
                    RAISE e_error;
                END IF;

                Dka_Sarrefac_Pkg.launch_non_oa_non_ar_inv_orig (
                    pv_errbuf,
                    pn_retcode,
                    print_invoices_rec.request_id,
                    print_invoices_rec.org_id,
                    print_invoices_rec.org_name,
                    print_invoices_rec.trx_number,
                    print_invoices_rec.from_acct_area,
                    print_invoices_rec.to_acct_area,
                    vn_request_id
                );
                -- Changement d'environnement
                Fnd_Global.apps_initialize (vn_from_user_id, vn_responsibility_id, vn_application_id);
                -- Récupération imprimante
                vv_copy_printer_name        := Fnd_Profile.VALUE ('PRINTER');

                IF NOT Fnd_Submit.set_print_options (
                           vv_copy_printer_name, -- Printer
                           gv_invoice_print_style, -- Style
                           cn_number_of_copies -- Nb of copies
                       )
                THEN
                    Dka_Tools_Pkg.put_debug_message (
                           'Impossible de "fnd_submit.set_print_options" l''impression de copie de facture '
                        || print_invoices_rec.trx_number --pv_trx_number
                    );
                    Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
                    pn_retcode    := 2;
                    pv_errbuf     :=    'Impossible de "fnd_submit.set_print_options" l''impression de copie de facture '
                                     || print_invoices_rec.trx_number; --pv_trx_number;
                    RAISE e_error;
                END IF;

                Dka_Sarrefac_Pkg.launch_non_oa_non_ar_inv_cp (
                    pv_errbuf,
                    pn_retcode,
                    print_invoices_rec.request_id,
                    print_invoices_rec.org_id,
                    print_invoices_rec.org_name,
                    print_invoices_rec.trx_number,
                    print_invoices_rec.from_acct_area,
                    print_invoices_rec.to_acct_area,
                    vn_request_id
                );
            END IF;

            IF pn_retcode != 0
            THEN
                Dka_Tools_Pkg.put_debug_message ('ERREUR: Lancement du traitement a généré une erreur: '|| pv_errbuf);
                pn_retcode    := 1;
            END IF;

            Dka_Tools_Pkg.put_debug_message (
                'Lancement du jeu '|| TO_CHAR (vn_request_id) || ' pour la facture ' || print_invoices_rec.trx_number
            );
        END LOOP;

        Dka_Tools_Pkg.put_debug_message ('- run_all_non_oa_inv_print (-)');
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := cv_program_code || pv_errbuf;
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := SQLCODE;
    END run_all_non_oa_inv_print;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CREATE_OUTPUT
--  Description   : Etat de sortie du traitement
--
--  PARAMETRES    :
--      pv_errbuf               OUT     VARCHAR2
--      pn_retcode              OUT     NUMBER
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE create_output (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        e_error                  EXCEPTION;

        CURSOR rejected_invoices_cur
        IS
            SELECT   NVL (dst.invoice_number, ' ') invoice_number,
                     NVL (dst.transaction_source, ' ') transaction_source,
                     NVL (dst.expenditure_item_id, 0) expenditure_item_id,
                     NVL (dst.event_id, 0) event_id,
                     NVL (dst.amount, 0) amount,
                     NVL (dst.transfer_status_code, ' ') transfer_status_code,
                     NVL (dst.transfer_rejection_reason, ' ') transfer_rejection_reason
            FROM     dka_sarrefac_tmp dst
            WHERE    dst.transfer_status_code IN ('R', 'T')
            ORDER BY dst.invoice_number,
                     dst.transfer_status_code;

        CURSOR unprocessed_lines_cur
        IS
            -- DEPENSES NON REFACTUREES AVEC OU SANS PROJET A REFACTURER D'ORIGINE AUTRE QUE AP --
            SELECT   /*+ ordered use_nl (pt, pei, pcdl, gcc, pp_refac, dsp)*/
                     'Dépense' origine,
                     pei.expenditure_item_id id,
                     pp.segment1 projet_refac,
                     pei.expenditure_type type_mvt,
                     NVL (dsp.ap_expenditure_type, 'Non refacturable') refacture_en,
                     pei.expenditure_item_date date_pa,
                     pcdl.gl_date date_gl,
                     pcdl.amount montant,
                     gcc.concatenated_segments cle,
                     NVL (pp_refac.segment1, 'Manquant') projet_a_refac,
                     NVL (pp_refac.description, 'Projet a refacturer manquant') lib_projet_a_refac,
                     pei.creation_date date_creation_ligne
            FROM     pa_projects_all pp,
                     pa_tasks pt,
                     pa_expenditure_items_all pei,
                     pa_cost_distribution_lines_all pcdl,
                     gl_code_combinations_kfv gcc,
                     pa_projects_all pp_refac,
                     dka_sarrefac_param dsp
            WHERE        pei.task_id = pt.task_id
                     AND pp.project_id = pt.project_id
                     AND gcc.code_combination_id = pcdl.dr_code_combination_id
                     AND pp.project_type = gv_project_type_refac
                     AND pp_refac.project_id(+) = pei.attribute1
                     AND pcdl.expenditure_item_id = pei.expenditure_item_id
                     AND pei.expenditure_type != 'REFACTURATION PRODUITS'
                     AND pei.attribute3 IS NULL
                     AND pcdl.transfer_status_code != 'V'
                     AND dsp.orig_transaction_type(+) = pei.expenditure_type
            -- DEPENSES NON REFACTUREES AVEC OU SANS PROJET A REFACTURER D'ORIGINE AP
            UNION --RBE artf2082357
            SELECT   /*+ ordered use_nl (pt, pei, pcdl, aid, gcc, pp_refac, dsp)*/
                     'Dépense' origine,
                     pei.expenditure_item_id id,
                     pp.segment1 projet_refac,
                     pei.expenditure_type type_mvt,
                     NVL (dsp.ap_expenditure_type, 'Non refacturable') refacture_en,
                     pei.expenditure_item_date date_pa,
                     pcdl.gl_date date_gl,
                     pcdl.amount montant,
                     gcc.concatenated_segments cle,
                     NVL (pp_refac.segment1, 'Manquant') projet_a_refac,
                     NVL (pp_refac.description, 'Projet a refacturer manquant') lib_projet_a_refac,
                     pei.creation_date date_creation_ligne
            FROM     pa_projects_all pp,
                     pa_tasks pt,
                     pa_expenditure_items_all pei,
                     pa_cost_distribution_lines_all pcdl,
                     ap_invoice_distributions_all aid,
                     gl_code_combinations_kfv gcc,
                     pa_projects_all pp_refac,
                     dka_sarrefac_param dsp
            WHERE        pei.task_id = pt.task_id
                     AND pp.project_id = pt.project_id
                     AND gcc.code_combination_id = pcdl.dr_code_combination_id
                     AND pp.project_type = gv_project_type_refac
                     AND pcdl.expenditure_item_id = pei.expenditure_item_id
                     AND pei.expenditure_type != 'REFACTURATION PRODUITS'
                     AND pei.attribute3 IS NULL
                     AND pcdl.transfer_status_code = 'V'
                     --AND aid.invoice_id = pcdl.system_reference2                  --RBE artf2082357
                     --AND aid.distribution_line_number = pcdl.system_reference3    --RBE artf2082357
           AND pei.DOCUMENT_DISTRIBUTION_ID = aid.INVOICE_DISTRIBUTION_ID --RBE artf2082357
                     AND pp_refac.project_id(+) = aid.attribute1
                     AND dsp.orig_transaction_type(+) = pei.expenditure_type
            -- EVENEMENTS NON REFACTURES AU NIVEAU TACHE AVEC OU SANS PROJET A REFACTURER --
            UNION --RBE artf2082357
            SELECT   /*+ ordered use_nl (pt) */
                     'Evenement' origine,
                     pe.event_id id,
                     pp.segment1 projet_refac,
                     pe.event_type type_mvt,
                     NVL (dsp.ar_event_type, 'Non refacturable') refacture_en,
                     pe.completion_date date_pa,
                     pe.completion_date date_gl,
                     pcer.amount montant,
                     gcc.concatenated_segments cle,
                     NVL (pp_refac.segment1, 'Manquant') projet_a_refac,
                     NVL (pp_refac.description, 'Projet a refacturer manquant') lib_projet_a_refac,
                     pe.creation_date date_creation_ligne
            FROM     pa_projects_all pp,
                     pa_tasks pt,
                     pa_events pe,
                     pa_cust_event_rdl_all pcer,
                     pa_projects_all pp_refac,
                     gl_code_combinations_kfv gcc,
                     dka_sarrefac_param dsp
            WHERE        pe.task_id = pt.task_id
                     AND pp.project_id = pt.project_id
                     AND pp.project_type = gv_project_type_refac
                     AND pe.event_type NOT IN (SELECT DISTINCT ar_event_type
                                               FROM            dka_sarrefac_param
                                               WHERE           ar_event_type LIKE '%REFAC%')
                     AND pe.attribute3 IS NULL
                     AND pe.attribute1 = pp_refac.project_id(+)
                     AND pcer.project_id = pe.project_id
                     AND pcer.task_id = pe.task_id
                     AND pcer.event_num = pe.event_num
                     AND pcer.code_combination_id = gcc.code_combination_id
                     AND dsp.orig_transaction_type(+) = pe.event_type
            -- EVENEMENTS NON REFACTURES AU NIVEAU PROJET AVEC OU SANS PROJET A REFACTURER --
            UNION --RBE artf2082357
            SELECT   /*+ ordered use_nl (pe, pcer) */
                     'Evenement' origine,
                     pe.event_id id,
                     pp.segment1 projet_refac,
                     pe.event_type type_mvt,
                     NVL (dsp.ar_event_type, 'Non refacturable') refacture_en,
                     pe.completion_date date_pa,
                     pe.completion_date date_gl,
                     pcer.amount montant,
                     gcc.concatenated_segments cle,
                     NVL (pp_refac.segment1, 'Manquant') projet_a_refac,
                     NVL (pp_refac.description, 'Projet a refacturer manquant') lib_projet_a_refac,
                     pe.creation_date date_creation_ligne
            FROM     pa_projects_all pp,
                     pa_events pe,
                     pa_cust_event_rdl_all pcer,
                     pa_projects_all pp_refac,
                     gl_code_combinations_kfv gcc,
                     dka_sarrefac_param dsp
            WHERE        pp.project_id = pe.project_id
                     AND pp.project_type = gv_project_type_refac
                     AND pe.event_type NOT IN (SELECT DISTINCT ar_event_type
                                               FROM            dka_sarrefac_param
                                               WHERE           ar_event_type LIKE '%REFAC%')
                     AND pe.attribute3 IS NULL
                     AND pe.attribute1 = pp_refac.project_id(+)
                     AND pcer.project_id = pe.project_id
                     AND pcer.event_num = pe.event_num
                     AND pcer.code_combination_id = gcc.code_combination_id
                     AND dsp.orig_transaction_type(+) = pe.event_type
            ORDER BY 7,
                     3,
                     1,
                     4,
                     10,
                     2;
        vn_cpt                   PLS_INTEGER;
        vv_line                  VARCHAR2 (500);
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('- create_output (+)');

        -- Liste des enregistrements rejetés
        Fnd_File.put_line (Fnd_File.output, CHR (10));
        vv_line    := 'Liste des enregistrements rejetés';
        Fnd_File.put_line (Fnd_File.output, vv_line);
        vv_line    := '=================================';
        Fnd_File.put_line (Fnd_File.output, vv_line);
        Fnd_File.put_line (Fnd_File.output, '');
        vv_line    := LPAD ('FACTURE', 15);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('ORIGINE', 15);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('EXP_ID', 6);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('EVT_ID', 6);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('MONTANT', 14);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('MOTIF', 50);
        Fnd_File.put_line (Fnd_File.output, vv_line);
        vv_line    := LPAD ('-', 15, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 15, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 6, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 6, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('-', 14, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('-', 1, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 50, '-');
        Fnd_File.put_line (Fnd_File.output, vv_line);

        vn_cpt := 0;

        FOR rejected_invoices_rec IN rejected_invoices_cur LOOP

            vv_line    := LPAD (rejected_invoices_rec.invoice_number, 15);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (rejected_invoices_rec.transaction_source, 15);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || LPAD (NVL (TO_CHAR (rejected_invoices_rec.expenditure_item_id), ' '), 6);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || LPAD (NVL (TO_CHAR (rejected_invoices_rec.event_id), ' '), 6);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || LPAD (TO_CHAR (rejected_invoices_rec.amount, '999G999G990D00'), 14);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (rejected_invoices_rec.transfer_status_code, 1);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (rejected_invoices_rec.transfer_rejection_reason, 240); -- RBE artf2077143
            Fnd_File.put_line (Fnd_File.output, vv_line);

            vn_cpt := vn_cpt + 1;
        END LOOP;

        Fnd_File.put_line (Fnd_File.output, '');
        Fnd_File.put_line (Fnd_File.output, '');
        vv_line    := 'Nombre de lignes rejetées : ' || TO_CHAR (vn_cpt);
        Fnd_File.put_line (Fnd_File.output, vv_line);

        -- Liste des lignes non traitées
        Fnd_File.put_line (Fnd_File.output, CHR (10));
        vv_line    := 'Liste des lignes a refacturer non traitées';
        Fnd_File.put_line (Fnd_File.output, vv_line);
        vv_line    := '==========================================';
        Fnd_File.put_line (Fnd_File.output, vv_line);
        Fnd_File.put_line (Fnd_File.output, '');
        vv_line    := RPAD ('ORIGINE', 9);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('ID', 8);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('PROJ REFAC', 10);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('TYPE MOUVEMENT', 30);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('REFACTURE EN', 30);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('DATE PA', 8);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('DATE GL', 8);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('MONTANT', 12);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('CLE COMPTABLE', 40);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('PROJ A REFAC', 12);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('LIBELLE', 100);
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('DATE CREATION MVT', 17);
        Fnd_File.put_line (Fnd_File.output, vv_line);
        vv_line    := LPAD ('-', 9, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 8, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 10, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 30, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 30, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('-', 8, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('-', 8, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('-', 12, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('-', 40, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('-', 12, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || LPAD ('-', 100, '-');
        vv_line    := vv_line || ' ';
        vv_line    := vv_line || RPAD ('-', 17, '-');
        Fnd_File.put_line (Fnd_File.output, vv_line);

        vn_cpt := 0;

        FOR unprocessed_lines_rec IN unprocessed_lines_cur LOOP

            vv_line    := LPAD (NVL (unprocessed_lines_rec.origine, ' '), 9);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || LPAD (NVL (TO_CHAR (unprocessed_lines_rec.id), ' '), 8);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (NVL (unprocessed_lines_rec.projet_refac, ' '), 10);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (NVL (unprocessed_lines_rec.type_mvt, ' '), 30);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (NVL (unprocessed_lines_rec.refacture_en, ' '), 30);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || LPAD (NVL (TO_CHAR (unprocessed_lines_rec.date_pa, 'DD/MM/RR'), ' '), 8);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || LPAD (NVL (TO_CHAR (unprocessed_lines_rec.date_gl, 'DD/MM/RR'), ' '), 8);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || LPAD (NVL (TO_CHAR (unprocessed_lines_rec.montant, '9G999G990D00'), ' '), 12);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (NVL (unprocessed_lines_rec.cle, ' '), 40);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (NVL (unprocessed_lines_rec.projet_a_refac, ' '), 12);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (NVL (unprocessed_lines_rec.lib_projet_a_refac, ' '), 100);
            vv_line    := vv_line || ' ';
            vv_line    := vv_line || RPAD (NVL (TO_CHAR (unprocessed_lines_rec.date_creation_ligne, 'DD/MM/RR HH24:MI:SS'), ' '), 17);
            Fnd_File.put_line (Fnd_File.output, vv_line);

            vn_cpt := vn_cpt + 1;
        END LOOP;

        Fnd_File.put_line (Fnd_File.output, '');
        Fnd_File.put_line (Fnd_File.output, '');
        vv_line    := 'Nombre de lignes a refacturer non traitées : ' || TO_CHAR (vn_cpt);
        Fnd_File.put_line (Fnd_File.output, vv_line);

        Dka_Tools_Pkg.put_debug_message ('- create_output (-)');
    EXCEPTION
        WHEN e_error THEN
            pv_errbuf     := cv_program_code || pv_errbuf;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
            pn_retcode    := 2;

        WHEN OTHERS THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
            pn_retcode    := SQLCODE;

    END create_output;

------------------------------------------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES :
--    pv_errbuf                       Entrée/Sortie           retour de message eventuel
--    pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-----------------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        e_error_main   EXCEPTION;
        vn_result      NUMBER (22);
        vd_ref_date    DATE;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('main (+)');
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Initialisation');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.init (pv_errbuf, vn_result, vd_ref_date);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Traitement préliminaire');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.pre_request (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        -- Le traitement préliminaire n'ayant pour but que de compléter les données a traiter,
        -- on valide le traitement afin de ne pas devoir recommencer en cas de probleme plus loin
        Dka_Tools_Pkg.put_debug_message ('>>>>> Validation apres Pré-Traitement');
        COMMIT;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Purge de la table DKA_SARREFAC_TMP');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.delete_dka_sarrefac_tmp (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Alimentation de la table DKA_SARREFAC_TMP');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.insert_dka_sarrefac_tmp (pv_errbuf, vn_result, vd_ref_date);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Détermination des centres de gestion');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.get_acct_areas (pv_errbuf, vn_result, vd_ref_date);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('>>>>> Validation apres Détermination des centres de gestion');
        COMMIT;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Détermination des numéros de factures');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.get_trx_numbers (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Détermination des informations clients');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.get_customers (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Détermination des informations fournisseurs');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.get_vendors (pv_errbuf, vn_result, vd_ref_date);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Détermination des données complémentaires');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.populate_data (pv_errbuf, vn_result, vd_ref_date);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Traitement des avoirs dans AR');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.check_for_credit_memos (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;


        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Alimentation des tables d''Open Interface de AR');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.alim_ar_interface (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Alimentation des tables d''Open Interface de AP');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.alim_ap_interface (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        -- Apres l'alimentation des Open Interfaces,
        -- on met a jour les lignes de dépenses et les évenements,
        -- puis on valide pour que les traitements standards puissent voir les données
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Mise a jour des lignes d''origine dans PA');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.update_pa (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            pn_retcode    := 2;
            RAISE e_error_main;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('>>>>> Validation apres alimentation des Open Interface et mise a jour de PA');
        COMMIT;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Lancement des Open Interface de AR et AP');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.run_all_interfaces (pv_errbuf, vn_result, vd_ref_date);

        IF vn_result != 0
        THEN
            -- En cas d'erreur, le traitement doit continuer mais se terminer en "Warning"
            pn_retcode    := 1;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Lancement des Impressions de factures AR (lancé post-prise en compte AP et AR)');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        /*Dka_Sarrefac_Pkg.run_all_invoice_printing (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            -- En cas d'erreur, le traitement doit continuer mais se terminer en "Warning"
            pn_retcode    := 1;
        END IF;
        */

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Lancement des Impressions de factures incompletes');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.run_all_non_oa_inv_print (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            -- En cas d'erreur, le traitement doit continuer mais se terminer en "Warning"
            pn_retcode    := 1;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Tools_Pkg.put_debug_message ('| Création de l''état de sortie');
        Dka_Tools_Pkg.put_debug_message ('+------------------------------------------------+');
        Dka_Sarrefac_Pkg.create_output (pv_errbuf, vn_result);

        IF vn_result != 0
        THEN
            -- En cas d'erreur, le traitement doit continuer mais se terminer en "Warning"
            pn_retcode    := 1;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('main (-)');
    EXCEPTION
        WHEN e_error_main
        THEN
            pn_retcode    := 2;
            ROLLBACK;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_program_code || SQLERRM;
            pn_retcode    := 2;
            ROLLBACK;
    END main;

------------------------------------------------------------------------------------------------------------------------
--  Nom           : SEND_MAIL
--  Description   : Procédure d'envoi d'email
--
--  PARAMETRES :
--    pn_request_id NUMBER
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-----------------------------------------------------------------------------------------------------------------------
    PROCEDURE send_mail (
        pn_request_id   IN      NUMBER,
        Pv_CDG_FROM IN VARCHAR2,
        Pv_CDG_TO IN VARCHAR2,
        pv_edition IN VARCHAR2
    )
    IS
      rec_param   dka_parameters%ROWTYPE;

      vv_expediteur VARCHAR2(100);
      ln_retcode NUMBER;
      lv_errbuf VARCHAR2(1000);
      vv_entete VARCHAR2(4000);
      vv_body VARCHAR2(4000);
      vv_destinataire VARCHAR2(4000);
      ln_request_id NUMBER;

      CURSOR cur_destinataire(Pv_CDG_FROM IN VARCHAR2, Pv_CDG_TO IN VARCHAR2) IS
      select attribute1 from fnd_flex_values ffv, fnd_flex_value_sets ffvs
      where ffv.flex_value_set_id = ffvs.flex_value_set_id
      and ffvs.flex_value_set_name = 'DKA_ENVOI_MAIL_REGION_REFAC'
      and ffv.flex_value between NVL(Pv_CDG_FROM,Pv_CDG_To) and NVL(Pv_CDG_To,Pv_CDG_FROM);

      lv_cdg VARCHAR2(10);
    BEGIN
      Dka_Tools_Pkg.get_parameter ('SARREFAC', 'EXPEDITEUR', rec_param, ln_retcode, lv_errbuf);

      vv_expediteur := rec_param.VARCHAR2_VALUE;

      IF (Pv_CDG_FROM IS NULL) THEN
        lv_cdg := Pv_CDG_TO;
      ELSE
        lv_cdg := Pv_CDG_FROM;
      END IF;

      fnd_message.set_name ('DKA', 'DKA_SARREFAC_I0002');
      fnd_message.set_token('REGION', lv_cdg);
      fnd_message.set_token('EDITION', pv_edition);
      vv_entete := fnd_message.get;

      fnd_message.set_name ('DKA', 'DKA_SARREFAC_I0003');
      fnd_message.set_token('REGION', lv_cdg);
      fnd_message.set_token('EDITION', pv_edition);
      fnd_message.set_token('DATE', to_char(sysdate,'DD/MM/RRRR'));
      vv_body := fnd_message.get;

      FOR rec_destinataire IN cur_destinataire(Pv_CDG_FROM, Pv_CDG_TO) LOOP
        IF vv_destinataire IS NOT NULL THEN
          vv_destinataire := vv_destinataire || '; ' || rec_destinataire.attribute1;
        ELSE
          vv_destinataire := rec_destinataire.attribute1;
        END IF;
      END LOOP;

        insert into dka.dka_mail_param
        (expediteur, destinataire, objet, corps, req_id, attachement, filename)
        values (vv_expediteur, vv_destinataire, vv_entete, vv_body, pn_request_id, 'O', null);

        ln_request_id    :=
                Fnd_Request.submit_request (
                    'DKA',       --APPL
                    'DKA_MAIL',    --PROG
                    NULL,          --PROGRAM_NAME
                    NULL,          --START
                    FALSE,         --SUB_REQUEST
                    pn_request_id
                );
        COMMIT;
        Dka_Tools_Pkg.put_debug_message ('send_mail : Lancement du traitement : ' || ln_request_id);
        dbms_output.put_line('send_mail : Lancement du traitement : ' || ln_request_id);

        IF ln_request_id = 0
        THEN
            Dka_Tools_Pkg.put_debug_message (
                'Impossible de lancer le traitement ');
            Dka_Tools_Pkg.put_debug_message (Fnd_Message.get);
            dbms_output.put_line('Impossible de lancer le traitement ');
            dbms_output.put_line(Fnd_Message.get);
        END IF;

    EXCEPTION
        WHEN OTHERS
        THEN
            ROLLBACK;
    END send_mail;

END DKA_SARREFAC_PKG;

/
SHOW ERRORS
EXIT
