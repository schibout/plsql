CREATE OR REPLACE PACKAGE BODY DKA_PA_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_PA_TOOLS_PKG.pkb
-- DESCRIPTION       : DKA_PA_TOOLS_PKG package body : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--  06/10/2016 JPE Ajout de la fonction pa_insert_event_2
--  06/10/2016 NBO Ajout de la fonction get_class_project et get_parent_project
--  19/10/2016 OBE Ajout du parametre pv_event_attribute7 dans la procédure pa_insert_event2
--  20/10/2016 OBE pa_insert_event2 renommé en pa_insert_event
--  20/10/2016 NBO ajout des steps dans pa_insert_event + récupération des exceptions sur les agreements
--  25/10/2016 JJA SPE022 - Refacturation - Ajout de la fonction PA_GET_PROJECT_TASK
--  25/10/2016 NBO Ajout de la fonction pa_get_period
--  16/11/2016 NBO Ajout de la notion de tâche dans la description sur GL_INTERFACE
--  07/12/2016 OBE Modification pa_insert_event : Mise à 0 du champ 
--  14/12/2016 MEG artf2065132 : Erreur saisie facture avec rapprochement commande
--  30/03/2017 YWA artf2131570
--  08/04/2018 AAM artf07231300
--  16/04/2020 SELO : EDB259
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);

    gn_per_business_group_id NUMBER := TO_NUMBER(FND_PROFILE.VALUE('PER_BUSINESS_GROUP_ID'));
    gn_org_id                NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));
    gn_sobid        CONSTANT NUMBER := Fnd_Profile.value('GL_SET_OF_BKS_ID');
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
        pd_date               IN       DATE
    )IS
        e_error                     EXCEPTION;
        e_check_ko                  EXCEPTION;
        vn_project_id               pa_projects_all.project_id%TYPE;
        vn_task_id                  pa_tasks.task_id%TYPE;
        vv_project_type             pa_projects_all.project_type%TYPE;
        vv_dummy		    VARCHAR2(10);
        
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
                     pp.project_type
              INTO   vn_project_id,
                     vn_task_id,
                     vv_project_type
              FROM   pa_tasks pt, pa_projects_all pp            
              WHERE  pt.project_id = pn_project_id
              AND    pt.task_id = pn_tache_id
              AND    pt.project_id = pp.project_id;
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                pv_errbuf := 'Le couple projet ' || pn_project_id || ' / tâche ' || pn_tache_id || ' n''existe pas';
                RAISE e_error;
        END;

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

----------------------------------------------------------------------------------------
--  Nom           : PA_AA_RUN_FUNCTION_TRANSACTION
--  Description   : Procédure permettant d'executer
--                  une fonction d'autoaccounting
--  PARAMETRES :
--    pn_org_id         Entrée
--    pv_segment1       Sortie
--    pn_project_id     Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE pa_aa_run_function_transaction (
        pv_function_code               IN       VARCHAR2,
        pv_function_transaction_code   IN       VARCHAR2,
        pv_segment1                    OUT      VARCHAR2,
        pv_segment2                    OUT      VARCHAR2,
        pv_segment3                    OUT      VARCHAR2,
        pv_segment4                    OUT      VARCHAR2,
        pv_segment5                    OUT      VARCHAR2,
        pv_segment6                    OUT      VARCHAR2,
        pv_segment7                    OUT      VARCHAR2,
        pv_segment8                    OUT      VARCHAR2,
        pv_segment9                    OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_segment10                   OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_segment11                   OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_segment12                   OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_expenditure_type            IN       VARCHAR2 DEFAULT NULL, -- Par 03
        pv_organization_name           IN       VARCHAR2 DEFAULT NULL, -- Par 06
        pv_revenue_category            IN       VARCHAR2 DEFAULT NULL, -- Par 07
        pv_event_type                  IN       VARCHAR2 DEFAULT NULL, -- Par 19
        pn_project_id                  IN       NUMBER DEFAULT NULL, -- Par 24
        pn_event_num                   IN       NUMBER DEFAULT NULL, -- Par 33
        -- NBO 09/11/16 - Ajout de la notion de tâche dans l'autoaccounting 
		pn_task_id                     IN       NUMBER DEFAULT NULL, -- Par 26
        pv_errbuf                      OUT      VARCHAR2,
        pn_retcode                     OUT      NUMBER
    )
    IS
        e_error                    EXCEPTION;
        cv_procedure               VARCHAR2 (50)                                    := 'PA_AA_RUN_FUNCTION_TRANSACTION - ';
        cn_application_id          fnd_application.application_id%TYPE              := 275; -- Application PA
        vv_enabled_flag            pa_function_transactions_all.enabled_flag%TYPE;
        vv_segment_lookup          pa_rules.constant_value%TYPE;
        vv_parameter_value         pa_rules.constant_value%TYPE;
        vv_segment_value           gl_code_combinations.segment1%TYPE;
        vv_sql                     pa_rules.select_statement%TYPE;
        vv_class_code              pa_project_classes.class_code%TYPE;

        CURSOR segment_rule_pairing_cur
        IS
            SELECT   (psrp.segment_num + 1) segment_num, -- +1 car numerotation a partir de 0
                     psrp.rule_id,
                     pr.key_source,
                     pr.constant_value,
                     pr.key_parameter_id,
                     pr.select_statement,
                     pr.rule_type,
                     pr.segment_value_lookup_set_id
            FROM     pa_segment_rule_pairings psrp,
                     pa_rules pr
            WHERE        psrp.application_id = cn_application_id
                     AND psrp.function_code = pv_function_code
                     AND psrp.function_transaction_code = pv_function_transaction_code
                     AND pr.rule_id = psrp.rule_id
            ORDER BY psrp.segment_num ASC;

        segment_rule_pairing_rec   segment_rule_pairing_cur%ROWTYPE;

        CURSOR rule_parameter_cur (
            pn_rule_id   NUMBER
        )
        IS
            SELECT   prp.parameter_seq,
                     prp.parameter_id
            FROM     pa_rule_parameters prp
            WHERE    prp.rule_id = pn_rule_id
            ORDER BY parameter_seq DESC;

        rule_parameter_rec         rule_parameter_cur%ROWTYPE;
    BEGIN
        -- Vérification que la fonction/transaction est active
        -- dka_tools_pkg.put_debug_message (
        --     cv_procedure || 'Vérif fonction active: ' || pv_function_code || '-' || pv_function_transaction_code
        -- );

        SELECT pft.enabled_flag
        INTO   vv_enabled_flag
        FROM   pa_function_transactions pft
        WHERE      pft.application_id = cn_application_id
               AND pft.function_code = pv_function_code
               AND pft.function_transaction_code = pv_function_transaction_code;

        IF vv_enabled_flag = 'N'
        THEN
            pn_retcode    := 2;
            pv_errbuf     := cv_procedure || 'La fonction ' || pv_function_code || '-' || pv_function_transaction_code || ' est inactive';
            RETURN;
        END IF;

        -- Determination de la regle de chaque segment
        -- dka_tools_pkg.put_debug_message (cv_procedure || 'Determination de la regle de chaque segment');
        OPEN segment_rule_pairing_cur;

        LOOP
            FETCH segment_rule_pairing_cur INTO segment_rule_pairing_rec;
            EXIT WHEN segment_rule_pairing_cur%NOTFOUND;

            -- Détermination de la valeur intermédiaire
            IF segment_rule_pairing_rec.key_source = 'C' -- Constante
            THEN
                vv_segment_lookup    := segment_rule_pairing_rec.constant_value;
                -- dka_tools_pkg.put_debug_message (
                --     cv_procedure || 'Segment' || segment_rule_pairing_rec.segment_num || ' constante ' || vv_segment_lookup
                -- );
            ELSIF segment_rule_pairing_rec.key_source = 'P' -- Parametre
            THEN
                -- dka_tools_pkg.put_debug_message (
                --        cv_procedure
                --     || 'Segment'
                --     || segment_rule_pairing_rec.segment_num
                --     || ' parameter_id '
                --     || segment_rule_pairing_rec.key_parameter_id
                -- );

                IF segment_rule_pairing_rec.key_parameter_id = 1
                THEN
                    SELECT ppc.class_code
                    INTO   vv_class_code
                    FROM   pa_class_categories pcc,
                           pa_project_classes ppc
                    WHERE      pcc.autoaccounting_flag = 'Y'
                           AND ppc.class_category = pcc.class_category
                           AND ppc.project_id = pn_project_id;
                END IF;

                SELECT DECODE (
                           pp.parameter_id,
                           1, vv_class_code,
                           3, pv_expenditure_type,
                           6, pv_organization_name,
                           7, pv_revenue_category,
                           19, pv_event_type,
                           24, TO_CHAR (pn_project_id),
						   -- NBO 09/11/16 - Ajout de la notion de tâche dans l'autoaccounting
                           26, TO_CHAR (pn_task_id),
                           33, TO_CHAR (pn_event_num),
                           NULL
                       ) --'/!\ Erreur')
                INTO   vv_segment_lookup
                FROM   pa_parameters pp
                WHERE  pp.parameter_id = segment_rule_pairing_rec.key_parameter_id;

                -- dka_tools_pkg.put_debug_message (
                --     cv_procedure || 'Segment' || segment_rule_pairing_rec.segment_num || ' parametre ' || vv_segment_lookup
                -- );
            ELSIF segment_rule_pairing_rec.key_source = 'S' -- Ordre SQL
            THEN
                vv_sql    := segment_rule_pairing_rec.select_statement;
                --dka_tools_pkg.put_debug_message('vv_sql: ' || vv_sql);

                -- Remplacement des parametres
                OPEN rule_parameter_cur (segment_rule_pairing_rec.rule_id);

                LOOP
                    FETCH rule_parameter_cur INTO rule_parameter_rec;
                    EXIT WHEN rule_parameter_cur%NOTFOUND;

                    --dka_tools_pkg.put_debug_message('parameter_id: ' || rule_parameter_rec.parameter_id);
                    --dka_tools_pkg.put_debug_message('pv_event_type: ' || pv_event_type);
                    IF rule_parameter_rec.parameter_id = 1
                    THEN
                        SELECT ppc.class_code
                        INTO   vv_class_code
                        FROM   pa_class_categories pcc,
                               pa_project_classes ppc
                        WHERE      pcc.autoaccounting_flag = 'Y'
                               AND ppc.class_category = pcc.class_category
                               AND ppc.project_id = pn_project_id;
                    END IF;

                    SELECT DECODE (
                               pp.parameter_id,
                               1, vv_class_code,
                               3, pv_expenditure_type,
                               6, pv_organization_name,
                               7, pv_revenue_category,
                               19, pv_event_type,
                               24, TO_CHAR (pn_project_id),
                               -- NBO 09/11/16 - Ajout de la notion de tâche dans l'autoaccounting
                               26, TO_CHAR (pn_task_id),
                               33, TO_CHAR (pn_event_num),
                               NULL
                           ) --'/!\ Erreur')
                    INTO   vv_parameter_value
                    FROM   pa_parameters pp
                    WHERE  pp.parameter_id = rule_parameter_rec.parameter_id;

                    dka_tools_pkg.put_debug_message('vv_parameter_value: ' || vv_parameter_value);

                    vv_sql    := REPLACE (vv_sql, ':' || rule_parameter_rec.parameter_seq, '''' || vv_parameter_value || '''');
                dka_tools_pkg.put_debug_message('vv_sql: ' || vv_sql);

                END LOOP;

                CLOSE rule_parameter_cur;
                -- Execution de la requete
                --dka_tools_pkg.put_debug_message('vv_sql: ' || vv_sql);
                EXECUTE IMMEDIATE vv_sql
                    INTO vv_segment_lookup;
                -- dka_tools_pkg.put_debug_message (
                --     cv_procedure || 'Segment' || segment_rule_pairing_rec.segment_num || ' sql ' || vv_segment_lookup
                -- );
            ELSE
                pn_retcode    := 2;
                pv_errbuf     := cv_procedure || 'Erreur key_source: segment_num = ' || TO_CHAR (
                                                                                            segment_rule_pairing_rec.segment_num
                                                                                        );
                RETURN;
            END IF;

            -- Fin de la determination de la valeur intermediaire

            -- Determination de la valeur finale
            IF segment_rule_pairing_rec.rule_type = 'K'
            THEN
                vv_segment_value    := vv_segment_lookup;
                -- dka_tools_pkg.put_debug_message (
                --     cv_procedure || 'Segment' || segment_rule_pairing_rec.segment_num || ' K ' || vv_segment_value
                -- );
            ELSIF segment_rule_pairing_rec.rule_type = 'L'
            THEN
                SELECT psvl.segment_value
                INTO   vv_segment_value
                FROM   pa_segment_value_lookups psvl
                WHERE      psvl.segment_value_lookup_set_id = segment_rule_pairing_rec.segment_value_lookup_set_id
                       AND psvl.segment_value_lookup = vv_segment_lookup;

                -- dka_tools_pkg.put_debug_message (
                --     cv_procedure || 'Segment' || segment_rule_pairing_rec.segment_num || ' lookup ' || vv_segment_value
                -- );
            ELSE
                pn_retcode    := 2;
                pv_errbuf     := cv_procedure || 'Erreur rule_type: segment_num = ' || TO_CHAR (
                                                                                           segment_rule_pairing_rec.segment_num
                                                                                       );
                RETURN;
            END IF;

            -- Fin de la determination de la valeur finale

            IF vv_segment_value IS NULL
            THEN
                pv_errbuf    :=    'Erreur lors de la récupération du segment '
                                || TO_CHAR (segment_rule_pairing_rec.segment_num)
                                || ' - Rule_Id: '
                                || TO_CHAR (segment_rule_pairing_rec.rule_id);
                RAISE e_error;
            END IF;

            -- Affectation de la valeur a la variable de sortie
            IF segment_rule_pairing_rec.segment_num = 1
            THEN
                pv_segment1    := vv_segment_value;
            ELSIF segment_rule_pairing_rec.segment_num = 2
            THEN
                pv_segment2    := vv_segment_value;
            ELSIF segment_rule_pairing_rec.segment_num = 3
            THEN
                pv_segment3    := vv_segment_value;
            ELSIF segment_rule_pairing_rec.segment_num = 4
            THEN
                pv_segment4    := vv_segment_value;
            ELSIF segment_rule_pairing_rec.segment_num = 5
            THEN
                pv_segment5    := vv_segment_value;
            ELSIF segment_rule_pairing_rec.segment_num = 6
            THEN
                pv_segment6    := vv_segment_value;
            ELSIF segment_rule_pairing_rec.segment_num = 7
            THEN
                pv_segment7    := vv_segment_value;
            ELSIF segment_rule_pairing_rec.segment_num = 8
            THEN
                pv_segment8    := vv_segment_value;
            ELSIF segment_rule_pairing_rec.segment_num = 9  
            THEN                                            
                pv_segment9    := vv_segment_value;         
            ELSIF segment_rule_pairing_rec.segment_num = 10 
            THEN                                            
                pv_segment10    := vv_segment_value;        
            ELSIF segment_rule_pairing_rec.segment_num = 11 
            THEN                                            
                pv_segment11    := vv_segment_value;        
            ELSIF segment_rule_pairing_rec.segment_num = 12 
            THEN                                            
                pv_segment12    := vv_segment_value;        
            ELSE
                pn_retcode    := 2;
                pv_errbuf     := cv_procedure || 'Erreur numero: segment_num = ' || TO_CHAR (segment_rule_pairing_rec.segment_num);
                RETURN;
            END IF;
        END LOOP;

        CLOSE segment_rule_pairing_cur;
    EXCEPTION
        WHEN e_error
        THEN
            pv_errbuf     := cv_procedure || pv_errbuf;
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := cv_procedure || SQLERRM;
            pn_retcode    := SQLCODE;
    END pa_aa_run_function_transaction;

    -------------------------------------------------------------------------------------
--  Nom           : insert_event
--  Description   :insérer un évenement dans la table standard PA_EVENTS.
--
--  PARAMETRES    :   pv_event_type       Entrée
--            pn_amont        Entrée
--            pn_project_id       Entrée
--            pn_group_id     ENTRée
--            pd_completion_date  Entrée
--
--  VALEUR RETOURNEE :
--     Description       : pv_errbuf,pn_result
--     Valeurs possibles :
--
------------------------------------------------------------------------------------
    PROCEDURE pa_insert_event (
        pn_task_id                 IN       NUMBER DEFAULT NULL,       -- RGH
        pv_event_type              IN       VARCHAR2,
        pn_amount                  IN       NUMBER,
        pn_project_id              IN       NUMBER,
        pd_completion_date         IN       DATE,
        pn_group_id                IN       NUMBER DEFAULT NULL,
        pv_insert_revenue_flag     IN       VARCHAR2 DEFAULT 'N',
        pv_insert_into_gl          IN       VARCHAR2 DEFAULT 'Y',
        pn_unbilled_ccid           IN       NUMBER DEFAULT NULL,
        pv_batch_name              IN       VARCHAR2 DEFAULT 'XXX',
        pv_description             IN       VARCHAR2 DEFAULT NULL,
        pn_ccid                    IN       NUMBER DEFAULT NULL,
        pv_event_attr_context      IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute1        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute2        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute3        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute4        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute5        IN       VARCHAR2 DEFAULT NULL,
        pv_event_attribute7        IN       VARCHAR2 DEFAULT NULL,    -- OBE
		pv_event_attribute8        IN       VARCHAR2 DEFAULT NULL,  --- SELO EDB259
        pn_event_organization_id   IN       NUMBER DEFAULT NULL,
        pn_org_id                  IN       NUMBER DEFAULT NULL,
        pv_errbuf                  OUT      VARCHAR2,
        pn_result                  OUT      NUMBER
    )
    IS
        e_error                        EXCEPTION;
        cn_customer_bill_split         pa_project_customers.customer_bill_split%TYPE             := 100;
        vn_event_num                   pa_events.event_num%TYPE;
        vn_event_id                    pa_events.event_id%TYPE;
        vn_organization_id             hr_all_organization_units.organization_id%TYPE;
        vn_org_id                      hr_all_organization_units.organization_id%TYPE;
        vv_organization_name           hr_all_organization_units.NAME%TYPE;
        vn_draft_revenue_num           pa_draft_revenues_all.draft_revenue_num%TYPE;
        vn_agreement_id                pa_agreements_all.agreement_id%TYPE;
        vn_unbilled_ccid               gl_code_combinations.code_combination_id%TYPE;
        vn_ccid                        gl_code_combinations.code_combination_id%TYPE;
        vn_set_of_books_id             gl_interface.set_of_books_id%TYPE;
        vv_currency_code               fnd_currencies.currency_code%TYPE;
        --vv_expenditure_type          pa_expenditure_types%TYPE;
        --vn_group_id                  gl_interface.group_id%TYPE;
        vn_acct_amount                 NUMBER (22, 5);
        vv_event_type_class            pa_event_types.event_type_classification%TYPE;
        vv_project_number              pa_projects_all.segment1%TYPE;
        vv_segment1                    gl_code_combinations.segment1%TYPE;
        vv_segment2                    gl_code_combinations.segment2%TYPE;
        vv_segment3                    gl_code_combinations.segment3%TYPE;
        vv_segment4                    gl_code_combinations.segment4%TYPE;
        vv_segment5                    gl_code_combinations.segment5%TYPE;
        vv_segment6                    gl_code_combinations.segment6%TYPE;
        vv_segment7                    gl_code_combinations.segment7%TYPE;
        vv_segment8                    gl_code_combinations.segment8%TYPE;
        vv_segment9                    gl_code_combinations.segment9%TYPE;
        vv_segment10                   gl_code_combinations.segment10%TYPE;
        vv_segment11                   gl_code_combinations.segment11%TYPE;
        vv_segment12                   gl_code_combinations.segment12%TYPE;
        vv_revenue_category_code       pa_event_types.revenue_category_code%TYPE;
        vv_function_transaction_code   pa_function_transactions.function_transaction_code%TYPE;
        vv_function_code               pa_function_transactions.function_code%TYPE;
        gv_user_je_source_name         dka_parameters.varchar2_value%TYPE;
        gv_user_je_category_name       dka_parameters.varchar2_value%TYPE;
        gv_revenue_source              dka_parameters.varchar2_value%TYPE;
        rec_param                      dka_parameters%ROWTYPE;
        -- MIGRATION R12
        vn_legal_entity_id             hr_operating_units.default_legal_context_id%TYPE;
        -- PHENIX 2004
		--Debut AAM artf07231300
		vn_project_currency_code       PA_PROJECTS.PROJECT_CURRENCY_CODE%TYPE;
		vn_revproc_currency_code       PA_PROJECTS.REVPROC_CURRENCY_CODE%TYPE; 
		vn_projfunc_currency_code      PA_PROJECTS.PROJFUNC_CURRENCY_CODE%TYPE;
		vn_invproc_currency_code       PA_PROJECTS.PROJFUNC_CURRENCY_CODE%TYPE;
		vn_bill_trans_currency_code    PA_PROJECTS.PROJFUNC_CURRENCY_CODE%TYPE;
		--Fin AAM
        CURSOR cur_period (pd_comp_date IN DATE) IS
        SELECT gp.period_name
        FROM   gl_periods gp, gl_sets_of_books gsob
        WHERE  pd_comp_date BETWEEN gp.start_date AND gp.end_date
        AND    gp.period_set_name = gsob.period_set_name
        AND    set_of_books_id = gn_sobid;
        vv_period gl_periods.period_name%TYPE;
        vv_step VARCHAR2(200);
        -- FIN PHENIX 2004
        -- NBO - 16/11/16 - Ajout de la notion de tâche dans la description sur GL_INTERFACE
        vv_task_number VARCHAR2(50);
        vv_description VARCHAR2(300);
    BEGIN
        vv_step := 'START';
        Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT2: Initialisation des Variables de Sortie');
        pv_errbuf                   := NULL;
        pn_result                   := 0;

---------------------------------------
-- Récupération des données          --
---------------------------------------

        Dka_Tools_Pkg.get_parameter ('TOOLS', 'INSERT_EVENT_USER_JE_CATEGORY_NAME', rec_param, pn_result, pv_errbuf);
        gv_user_je_category_name    := rec_param.varchar2_value;

        IF pn_result != 0
        THEN
            pv_errbuf    := 'INSERT_EVENT_USER_JE_CATEGORY_NAME - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('TOOLS', 'INSERT_EVENT_USER_JE_SOURCE_NAME', rec_param, pn_result, pv_errbuf);
        gv_user_je_source_name      := rec_param.varchar2_value;

        IF pn_result != 0
        THEN
            pv_errbuf    := 'INSERT_EVENT_USER_JE_SOURCE_NAME - ' || pv_errbuf;
            RETURN;
        END IF;

        Dka_Tools_Pkg.get_parameter ('TOOLS', 'INSERT_EVENT_REVENUE_SOURCE', rec_param, pn_result, pv_errbuf);
        gv_revenue_source           := rec_param.varchar2_value;

        IF pn_result != 0
        THEN
            pv_errbuf    := 'INSERT_EVENT_REVENUE_SOURCE - ' || pv_errbuf;
            RETURN;
        END IF;

        vv_step := 'PA_EVENTS';
        --Déterminer le Numéro de l'Evenement:
        SELECT (MAX (pe.event_num) + 1)
        INTO   vn_event_num
        FROM   pa_events pe
        WHERE  pe.project_id = pn_project_id
        AND    pe.task_id = pn_task_id;

        IF vn_event_num IS NULL
        THEN
            vn_event_num    := 1;
        END IF;

        Dka_Tools_Pkg.put_debug_message (
            'PROC_PA_INSERT_EVENT: Récuperation du numéro de l''evenement: '|| TO_CHAR (pn_project_id) || ' - ' || TO_CHAR (pn_task_id)  ||' - ' || TO_CHAR (vn_event_num)
        );

        --Récupérer l'Organisation de l'événement
        vv_step := 'ORG_ID_EVT';
        IF pn_event_organization_id IS NOT NULL
        THEN
            vn_organization_id    := pn_event_organization_id;
        ELSE
            SELECT hou.organization_id
            INTO   vn_organization_id
            FROM   hr_all_organization_units hou,
                   pa_projects_all ppa
            WHERE  hou.organization_id = ppa.carrying_out_organization_id
            AND    ppa.project_id = pn_project_id;
        END IF;

        -- Récuperer l'org_id du Projet:
        vv_step := 'ORG_ID_PRJ';
        IF pn_org_id IS NOT NULL
        THEN
            vn_org_id    := pn_org_id;
        ELSE
            SELECT pp.org_id
            INTO   vn_org_id
            FROM   pa_projects/*_all*/ pp /*ETANCHEITE DALKIA 2007*/
            WHERE  pp.project_id = pn_project_id;
        END IF;

        Dka_Tools_Pkg.put_debug_message (
            'PROC_PA_INSERT_EVENT: Récuperation de l''organisation du projet: '|| TO_CHAR (vn_organization_id)
        );
        -- Insertion des données dans la Table PA_EVENTS:
        Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT: Insertion de l''évenement dans la table PA_EVENTS');
        
		--Debut AAM artf07231300
		vv_step := 'Currency code';
		BEGIN
		  SELECT DECODE(P.INVPROC_CURRENCY_TYPE,'PROJECT_CURRENCY',P.PROJECT_CURRENCY_CODE,'PROJFUNC_CURRENCY',P.PROJFUNC_CURRENCY_CODE,'REVPROC_CURRENCY',REVPROC_CURRENCY_CODE)
         -- ,DECODE(P.REVTRANS_CURRENCY_TYPE,'XX', P.PROJECT_CURRENCY_CODE,'PROJ_FUNC_CURR_ONLY',P.PROJFUNC_CURRENCY_CODE,'XX',REVPROC_CURRENCY_CODE)
          ,P.PROJFUNC_CURRENCY_CODE 
		  ,P.PROJECT_CURRENCY_CODE 
		  ,P.REVPROC_CURRENCY_CODE 
		  ,P.PROJFUNC_CURRENCY_CODE
		  INTO vn_invproc_currency_code    ,
		       vn_bill_trans_currency_code ,
		       vn_project_currency_code    , 
		       vn_revproc_currency_code    , 
		       vn_projfunc_currency_code
          FROM   PA_PROJECTS P
          WHERE  P.project_id = pn_project_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
               vn_invproc_currency_code    := NULL ;
			   vn_bill_trans_currency_code := NULL ;
			   vn_project_currency_code    := NULL ;
			   vn_revproc_currency_code    := NULL ;
			   vn_projfunc_currency_code   := NULL ;
        END;
		--Fin AAM artf07231300
       
      vv_step := 'INSERT_EVT';
      INSERT INTO pa_events
                    (task_id,
                     event_num,
                     last_update_date,
                     last_updated_by,
                     creation_date,
                     created_by,
                     last_update_login,
                     event_type,
                     description,
                     bill_amount,
                     revenue_amount,
                     revenue_distributed_flag,
                     bill_hold_flag,
                     completion_date,
                     rev_dist_rejection_code,
                     request_id,
                     program_application_id,
                     program_id,
                     program_update_date,
                     attribute_category,
                     attribute1,
                     attribute2,
                     attribute3,
                     attribute4,
                     attribute5,
                     attribute6,
                     attribute7,
                     attribute8,
                     attribute9,
                     attribute10,
                     project_id,
                     organization_id,
                     billing_assignment_id,
                     event_num_reversed,
                     calling_place,
                     calling_process,
                     audit_cost_budget_type_code,
                     audit_rev_budget_type_code,
                     audit_amount1,
                     audit_amount2,
                     audit_amount3,
                     audit_amount4,
                     audit_amount5,
                     audit_amount6,
                     audit_amount7,
                     audit_amount8,
                     audit_amount9,
                     audit_amount10,
                     event_id,
                     inventory_org_id,
                     inventory_item_id,
                     quantity_billed,
                     uom_code,
                     unit_price,
                     reference1,
                     reference2,
                     reference3,
                     reference4,
                     reference5,
                     reference6,
                     reference7,
                     reference8,
                     reference9,
                     reference10
                     -- PHENIX 2004
                     , BILL_TRANS_CURRENCY_CODE, BILL_TRANS_BILL_AMOUNT, BILL_TRANS_REV_AMOUNT,
                     PROJECT_CURRENCY_CODE, PROJECT_RATE_TYPE, PROJECT_RATE_DATE, PROJECT_EXCHANGE_RATE,
                     PROJECT_REV_RATE_DATE, PROJECT_REV_EXCHANGE_RATE, PROJECT_REVENUE_AMOUNT, PROJECT_INV_RATE_DATE,
                     PROJECT_INV_EXCHANGE_RATE, PROJECT_BILL_AMOUNT, PROJFUNC_CURRENCY_CODE, PROJFUNC_RATE_TYPE,
                     PROJFUNC_RATE_DATE, PROJFUNC_EXCHANGE_RATE, PROJFUNC_REV_RATE_DATE, PROJFUNC_REV_EXCHANGE_RATE,
                     PROJFUNC_REVENUE_AMOUNT, PROJFUNC_INV_RATE_DATE, PROJFUNC_INV_EXCHANGE_RATE, PROJFUNC_BILL_AMOUNT,
                     FUNDING_RATE_TYPE, FUNDING_RATE_DATE, FUNDING_EXCHANGE_RATE, REVPROC_CURRENCY_CODE, REVPROC_RATE_TYPE,
                     REVPROC_RATE_DATE, REVPROC_EXCHANGE_RATE, INVPROC_CURRENCY_CODE, INVPROC_RATE_TYPE, INVPROC_RATE_DATE,
                     INVPROC_EXCHANGE_RATE, INV_GEN_REJECTION_CODE, ADJUSTING_REVENUE_FLAG, ZERO_REVENUE_AMOUNT_FLAG,
                     NON_UPDATEABLE_FLAG, PROJECT_FUNDING_ID, REVENUE_HOLD_FLAG, AUDIT_COST_PLAN_TYPE_ID,
                     AUDIT_REV_PLAN_TYPE_ID, PM_PRODUCT_CODE, PM_EVENT_REFERENCE
                     -- FIN PHENIX 2004
                    )
        VALUES      (-- NULL, --task_id
                     pn_task_id,  --task_id -- RGH  
                     vn_event_num, --event_num
                     SYSDATE, --last_update_date
                     Fnd_Global.user_id, --last_updated_by
                     SYSDATE, --creation_date
                     Fnd_Global.user_id, --created_by
                     Fnd_Global.login_id, --last_update_login
                     pv_event_type, --event_type
                     -- NBO 09/11/16 - Ne pas forcer la description
                     --pv_event_type, --description
                     nvl(pv_description, pv_event_type),-- YWA artf2131570  --pv_description, -- description
                     0, --bill_amount
                     pn_amount, --revenue_amount
                     pv_insert_revenue_flag, --revenue_distributed_flag
                     'N', --bill_hold_flag
                     pd_completion_date, --completion_date
                     NULL, --rev_dist_rejection_code
                     Fnd_Global.conc_request_id, --request_id
                     Fnd_Global.prog_appl_id, --program_application_id
                     Fnd_Global.conc_program_id, --program_id
                     SYSDATE, --program_update_date
                     pv_event_attr_context, --attribute_category
                     pv_event_attribute1, --attribute1
                     pv_event_attribute2, --attribute2
                     pv_event_attribute3, --attribute3
                     pv_event_attribute4, --attribute4
                     pv_event_attribute5, --attribute5
                     NULL, --attribute6
                     pv_event_attribute7,                 -- OBE
                     --NULL, --attribute7                 -- OBE
                     pv_event_attribute8, --attribute8 -- SELO : EDB259
                     NULL, --attribute9
                     NULL, --attribute10
                     pn_project_id, --project_id
                     vn_organization_id, --organization_id
                     NULL, --billing_assignement_id
                     NULL, --event_num_reversed
                     NULL, --calling_place
                     NULL, --calling_process
                     NULL, --audit_cost_budget_type_code
                     NULL, --audit_rev_budget_type_code
                     pn_amount, --audit_amount1
                     NULL, --audit_amount2
                     NULL, --audit_amount3
                     NULL, --audit_amount4
                     NULL, --audit_amount5
                     NULL, --audit_amount6
                     NULL, --audit_amount7
                     NULL, --audit_amount8
                     NULL, --audit_amount9
                     NULL, --audit_amount10
                     pa_events_s.NEXTVAL, --event_id
                     NULL, --inventory_org_id
                     NULL, --inventory_item_id
                     NULL, --quantity_billed
                     NULL, --uom_code
                     NULL, --unit_price
                     NULL, --reference1
                     NULL, --reference2
                     NULL, --reference3
                     NULL, --reference4
                     NULL, --reference5
                     NULL, --reference6
                     NULL, --reference7
                     NULL, --reference8
                     NULL, --reference9
                     NULL --reference10
                     -- PHENIX 2004
                     -- NBO 09/11/16 - Il manquait le bill trans_rev_amount
                    -- , 'EUR', 
					,vn_bill_trans_currency_code,--BILL_TRANS_CURRENCY_CODE --AAM artf07231300
					 0/* OBE pn_amount*/, --bill_trans_amount
                     pn_amount, -- BILL_TRANS_REV_AMOUNT
                    -- 'EUR',
					vn_project_currency_code ,--PROJECT_CURRENCY_CODE --AAM artf07231300
					 NULL, NULL, NULL,
                     NULL, NULL, 0, NULL,
                     NULL, NULL,
					-- 'EUR', 
					vn_projfunc_currency_code ,--PROJFUNC_CURRENCY_CODE --AAM artf07231300
					NULL,
                     NULL, NULL, NULL, NULL,
                     0, NULL, NULL, NULL, NULL,
                     NULL, NULL, 
					-- 'EUR',
					vn_revproc_currency_code, --REVPROC_CURRENCY_CODE --AAM artf07231300
					 NULL, NULL,
                     NULL, 
					-- 'EUR', 
					vn_invproc_currency_code, --INVPROC_CURRENCY_CODE --AAM artf07231300
					 NULL, NULL,
                     NULL, NULL, 'N', 'N',
                     'N', NULL, 'N', NULL,
                     NULL, NULL, NULL
                     -- FIN PHENIX 2004
                    );

        -- S'il faut insérer le revenu, détermination des informations complémentaires
        IF pv_insert_revenue_flag = 'Y'
        THEN
            --Détermination du Numéro du produit provisoire:
            vv_step := 'DRAFT_NUM';
            SELECT (MAX (pdr.draft_revenue_num) + 1)
            INTO   vn_draft_revenue_num
            FROM   pa_draft_revenues_all pdr
            WHERE  pdr.project_id = pn_project_id;
            /*ETANCHEITE DALKIA 2007*/
            --AND pdr.org_id = gn_org_id;

            IF vn_draft_revenue_num IS NULL
            THEN
                vn_draft_revenue_num    := 1;
            END IF;

            Dka_Tools_Pkg.put_debug_message (
                   'PROC_PA_INSERT_EVENT: Récuperation du numéro produit provisoire: '
                || TO_CHAR (pn_project_id)
                || '-'
                || TO_CHAR (vn_draft_revenue_num)
            );

            -- Détermination du contrat
            vv_step := 'AGREEMENT';
            BEGIN
              SELECT ppf.agreement_id
              INTO   vn_agreement_id
              FROM   pa_project_fundings ppf
              WHERE  ppf.project_id = pn_project_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 pv_errbuf := 'Impossible de retrouver l''accord projet pour le projet ' || pn_project_id;
                 RAISE e_error;
            END;

            Dka_Tools_Pkg.put_debug_message (
                'PROC_PA_INSERT_EVENT: Récuperation du agreement_id: '|| TO_CHAR (pn_project_id) || '-' || TO_CHAR (vn_agreement_id)
            );
            -- Détermination de l'entité comptable
            -- JPE MIGRATION R12
            vv_step := 'HR_OU';
            SELECT HOU.SET_OF_BOOKS_ID,
                   HOU.default_legal_context_id
            INTO   vn_set_of_books_id,
                   vn_legal_entity_id
            FROM   hr_operating_units HOU
            WHERE  HOU.ORGANIZATION_id = vn_org_id;
            --Dka_Tools_Pkg.put_debug_message ('DEBUG JPE PROC_PA_INSERT_EVENT: Récuperation du SET OF BOOKS: '|| TO_CHAR (vn_set_of_books_id));
            
            -- Détermination de la devise de l'entité
            -- JPE MIGRATION R12 
            vv_step := 'DEVISE';                             
            SELECT FC.Currency_Code
            INTO  vv_currency_code
            FROM  FND_CURRENCIES         FC,
            		  GL_SETS_OF_BOOKS       GB,
            		  PA_IMPLEMENTATIONS_ALL IMP
            WHERE FC.Currency_Code =
            		  DECODE(IMP.Set_Of_Books_ID, Null, Null, GB.CURRENCY_CODE)
            AND   GB.Set_Of_Books_ID = IMP.Set_Of_Books_ID
            AND   IMP.org_id = vn_org_id;            
            --Dka_Tools_Pkg.put_debug_message ('DEBUG JPE PROC_PA_INSERT_EVENT: Récuperation du vv_currency_code: '|| TO_CHAR (vv_currency_code));
            
            -- Détermination du nom de l'organisation du projet
            vv_step := 'HOU_ALL';
            SELECT hou.NAME
            INTO   vv_organization_name
            FROM   hr_all_organization_units hou
            WHERE  hou.organization_id = vn_organization_id;
            --Dka_Tools_Pkg.put_debug_message ('DEBUG JPE PROC_PA_INSERT_EVENT: Récuperation du vv_organization_name: '|| TO_CHAR (vv_organization_name));
            
            -- Détermination des informations sur le type d'évenement
            vv_step := 'EVENT_TYPES';
            SELECT pet.revenue_category_code,
                   pet.event_type_classification
            INTO   vv_revenue_category_code,
                   vv_event_type_class
            FROM   pa_event_types pet
            WHERE  pet.event_type = pv_event_type;
            --Dka_Tools_Pkg.put_debug_message ('DEBUG JPE PROC_PA_INSERT_EVENT: Récuperation du vv_revenue_category_code: '|| TO_CHAR (vv_revenue_category_code));
            
            -- Détermination du montant comptabilisé
            IF vv_event_type_class = 'WRITE OFF'
            THEN
                vn_acct_amount    := (-1) * pn_amount;
            ELSE
                vn_acct_amount    := pn_amount;
            END IF;

            -- Récupération de l'event_id
            vv_step := 'CUR_EVENT';
            SELECT pa_events_s.CURRVAL
            INTO   vn_event_id
            FROM   DUAL;
            --Dka_Tools_Pkg.put_debug_message ('DEBUG JPE PROC_PA_INSERT_EVENT: Récuperation du vn_event_id: '|| TO_CHAR (vn_event_id));
            
            -- Determination du unbilled_ccid
            IF pn_unbilled_ccid IS NOT NULL
            THEN
                vn_unbilled_ccid    := pn_unbilled_ccid;
            ELSE
                BEGIN
                    vv_function_code                := 'GER';
                    Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT: Function_Code '|| vv_function_code);
                    vv_function_transaction_code    := 'WRITE-OFF';
                    Dka_Tools_Pkg.put_debug_message (
                        'PROC_PA_INSERT_EVENT: Function_Transaction_Code '|| vv_function_transaction_code
                    );
                    vv_step := 'pa_aa_run_function_transaction_unbill';
                    pa_aa_run_function_transaction (
                        pv_function_code               => vv_function_code,
                        pv_function_transaction_code   => vv_function_transaction_code,
                        pv_segment1                    => vv_segment1,
                        pv_segment2                    => vv_segment2,
                        pv_segment3                    => vv_segment3,
                        pv_segment4                    => vv_segment4,
                        pv_segment5                    => vv_segment5,
                        pv_segment6                    => vv_segment6,
                        pv_segment7                    => vv_segment7,
                        pv_segment8                    => vv_segment8,
                        pv_segment9                    => vv_segment9,  -- PHENIX 2004: Ajout.
                        pv_segment10                   => vv_segment10, -- PHENIX 2004: Ajout.
                        pv_segment11                   => vv_segment11, -- PHENIX 2004: Ajout.
                        pv_segment12                   => vv_segment12, -- PHENIX 2004: Ajout.
                        pv_organization_name           => vv_organization_name,
                        pv_revenue_category            => vv_revenue_category_code,
                        pv_event_type                  => pv_event_type,
                        pn_project_id                  => pn_project_id,
                        pn_event_num                   => vn_event_num,
                        -- NBO 09/11/16 - Ajout de la notion de tâche dans l'autoaccounting
                        pn_task_id                     => pn_task_id,
                        pv_errbuf                      => pv_errbuf,
                        pn_retcode                     => pn_result
                    );

                    IF pn_result != 0
                    THEN
                        RETURN;
                    END IF;

                    Dka_Tools_Pkg.put_debug_message (
                           'PROC_PA_INSERT_EVENT: Récuperation du unbilled: '
                        || vv_segment1
                        || '-'
                        || vv_segment2
                        || '-'
                        || vv_segment3
                        || '-'
                        || vv_segment4
                        || '-'
                        || vv_segment5
                        || '-'
                        || vv_segment6
                        || '-'
                        || vv_segment7
                        || '-'
                        || vv_segment8
                        || '-'
                        || vv_segment9
                        || '-'
                        || vv_segment10
                        || '-'
                        || vv_segment11
                        || '-'
                        || vv_segment12
                    );
                    vv_step := 'get_code_combination_id_unbill';
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
                        vn_unbilled_ccid,
                        pv_errbuf,
                        pn_result
                    );

                    IF vn_unbilled_ccid IS NULL
                    THEN
                        RAISE e_error;
                    END IF;

                    Dka_Tools_Pkg.put_debug_message (
                           'PROC_PA_INSERT_EVENT:Récuperation du unbilled_ccid: '
                        || TO_CHAR (pn_project_id)
                        || '-'
                        || TO_CHAR (vn_unbilled_ccid)
                    );
                END;
            END IF;

            -- Determination du ccid
            IF pn_ccid IS NOT NULL
            THEN
                vn_ccid    := pn_ccid;
            ELSE
                BEGIN
                    vv_function_code                := 'GER';
                    Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT: Function_Code '|| vv_function_code);
                    --SELECT pft.function_transaction_code
                    --INTO vv_function_transaction_code
                    --FROM pa_event_types_v pet,
                    --     pa_function_transactions pft
                    --WHERE pet.event_type = pv_event_type
                    --  AND pft.function_transaction_name = pet.event_type_class_name ;
                    vv_function_transaction_code    := 'WRITE-ON';
                    Dka_Tools_Pkg.put_debug_message (
                        'PROC_PA_INSERT_EVENT: Function_Transaction_Code '|| vv_function_transaction_code
                    );
                    vv_step := 'pa_aa_run_function_transaction_ccid';
                    pa_aa_run_function_transaction (
                        pv_function_code               => vv_function_code,
                        pv_function_transaction_code   => vv_function_transaction_code,
                        pv_segment1                    => vv_segment1,
                        pv_segment2                    => vv_segment2,
                        pv_segment3                    => vv_segment3,
                        pv_segment4                    => vv_segment4,
                        pv_segment5                    => vv_segment5,
                        pv_segment6                    => vv_segment6,
                        pv_segment7                    => vv_segment7,
                        pv_segment8                    => vv_segment8,
                        pv_segment9                    => vv_segment9,  -- PHENIX 2004: Ajout.
                        pv_segment10                   => vv_segment10, -- PHENIX 2004: Ajout.
                        pv_segment11                   => vv_segment11, -- PHENIX 2004: Ajout.
                        pv_segment12                   => vv_segment12, -- PHENIX 2004: Ajout.
                        pv_organization_name           => vv_organization_name,
                        pv_revenue_category            => vv_revenue_category_code,
                        pv_event_type                  => pv_event_type,
                        pn_project_id                  => pn_project_id,
                        pn_event_num                   => vn_event_num,
                        pn_task_id                     => pn_task_id,
                        pv_errbuf                      => pv_errbuf,
                        pn_retcode                     => pn_result
                    );

                    IF pn_result != 0
                    THEN
                        RETURN;
                    END IF;

                    Dka_Tools_Pkg.put_debug_message (
                           'PROC_PA_INSERT_EVENT: Récupération du ccid: '
                        || vv_segment1
                        || '-'
                        || vv_segment2
                        || '-'
                        || vv_segment3
                        || '-'
                        || vv_segment4
                        || '-'
                        || vv_segment5
                        || '-'
                        || vv_segment6
                        || '-'
                        || vv_segment7
                        || '-'
                        || vv_segment8
                        || '-'
                        || vv_segment9
                        || '-'
                        || vv_segment10
                        || '-'
                        || vv_segment11
                        || '-'
                        || vv_segment12
                    );
                    vv_step := 'get_code_combination_id_ccid';
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
                        vn_ccid,
                        pv_errbuf,
                        pn_result
                    );

                    IF vn_ccid IS NULL
                    THEN
                        RAISE e_error;
                    END IF;

                    Dka_Tools_Pkg.put_debug_message (
                        'PROC_PA_INSERT_EVENT:Récupération du ccid: '|| TO_CHAR (pn_project_id) || '-' || TO_CHAR (vn_ccid)
                    );
                END;
            END IF; -- pn_ccid IS NOT NULL

            -- Insertion des données dans la Table PA_DRAFT_REVENUES_ALL:
            Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT: Insertion de l''¿venement dans la table PA_DRAFT_REVENUE_ALL');

            OPEN cur_period (pd_completion_date);
            FETCH cur_period INTO vv_period;
            CLOSE cur_period;

            vv_step := 'INSERT pa_draft_revenues_all';
            INSERT INTO pa_draft_revenues_all
                        (project_id,
                         draft_revenue_num,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         agreement_id,
                         transfer_status_code,
                         generation_error_flag,
                         pa_date,
                         request_id,
                         program_application_id,
                         program_id,
                         resource_accumulated_flag,
                         program_update_date,
                         customer_bill_split,
                         accrue_through_date,
                         released_date,
                         transferred_date,
                         transfer_rejection_reason,
                         unbilled_receivable_dr,
                         unearned_revenue_cr,
                         unbilled_code_combination_id,
                         unearned_code_combination_id,
                         unbilled_batch_name,
                         unearned_batch_name,
                         gl_date,
                         accumulated_flag,
                         draft_revenue_num_credited,
                         last_update_login,
                         org_id
                         -- PHENIX 2004
                         , GL_PERIOD_NAME, PA_PERIOD_NAME, ADJUSTING_REVENUE_FLAG,
                         UBR_SUMMARY_ID, UER_SUMMARY_ID, UBR_UER_PROCESS_FLAG, PJI_SUMMARIZED_FLAG,
                         REALIZED_GAINS_AMOUNT, REALIZED_LOSSES_AMOUNT, REALIZED_GAINS_CCID,
                         REALIZED_LOSSES_CCID, REALIZED_GAINS_BATCH_NAME, REALIZED_LOSSES_BATCH_NAME
                         -- FIN PHENIX 2004
                         -- JPE MIGRATION R12
                         , legal_entity_id
                        )
            VALUES      (pn_project_id, --project_id
                         vn_draft_revenue_num, --draft_revenue_num
                         SYSDATE, --last_update_date
                         Fnd_Global.user_id, --last_updated_by
                         SYSDATE, --creation_date
                         Fnd_Global.user_id, --created_by
                         vn_agreement_id, --agreement_id
                         'A', --transfer_status_code
                         'N', --generation_error_flag
                         pd_completion_date, --pa_date
                         Fnd_Global.conc_request_id, --request_id
                         Fnd_Global.prog_appl_id, --program_application_id
                         Fnd_Global.conc_program_id, --program_id
                         'N', --resource_accumulated_flag
                         SYSDATE, --program_update_date
                         cn_customer_bill_split, --customer_bill_split
                         pd_completion_date, --accrue_through_date
                         SYSDATE, --released_date
                         SYSDATE, --transferred_date
                         NULL, --transfer_rejection_reason
                         vn_acct_amount, --unbilled_receivable_dr
                         0, --unearned_revenue_cr
                         vn_unbilled_ccid, --unbilled_code_combination_id
                         NULL, --unearned_code_combination_id
                         pv_batch_name, --unbilled_batch_name
                         pv_batch_name, --unearned_batch_name
                         pd_completion_date, --gl_date
                         'N', --accumulated_flag
                         NULL, --draft_revenue_num_credited
                         Fnd_Global.login_id, --last_update_login
                         vn_org_id --org_id
                         -- PHENIX 2004
                         , vv_period, vv_period, 'N',
                         NULL, NULL, 'N', NULL,
                         NULL, NULL, NULL,
                         NULL, NULL, NULL
                         -- FIN PHENIX 2004
                         -- JPE MIGRATION R12
                         , vn_legal_entity_id
                        );

            -- Insertion des données dans la Table PA_DRAFT_REVENUE_ITEMS:
            Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT: Insertion de l''¿venement dans la Table PA_DRAFT_REVENUE_ITEMS');

            vv_step := 'INSERT pa_draft_revenue_items';
            INSERT INTO pa_draft_revenue_items
                        (project_id,
                         task_id, --task_id JPE chgt ¿ confirmer
                         draft_revenue_num,
                         line_num,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         amount,
                         revenue_source,
                         revenue_category_code,
                         last_update_login,
                         request_id,
                         program_application_id,
                         program_id,
                         program_update_date
                         -- PHENIX 2004
                         , REVPROC_CURRENCY_CODE, PROJFUNC_CURRENCY_CODE, PROJFUNC_REVENUE_AMOUNT,
                         PROJECT_CURRENCY_CODE, PROJECT_REVENUE_AMOUNT, FUNDING_CURRENCY_CODE, FUNDING_REVENUE_AMOUNT
                         -- FIN PHENIX 2004
                        )
            VALUES      (pn_project_id, --project_id
                         pn_task_id, --task_id JPE chgt ¿ confirmer
                         vn_draft_revenue_num, --draft_revenue_num
                         1, --line_num
                         SYSDATE, --last_update_date
                         Fnd_Global.user_id, --last_updated_by
                         SYSDATE, --creation_date
                         Fnd_Global.user_id, --created_by
                         vn_acct_amount, --amount
                         gv_revenue_source, --revenue_source
                         vv_revenue_category_code, --revenue_category_code
                         Fnd_Global.login_id, --last_update_login
                         NULL, --request_id
                         NULL, --program_application_id
                         NULL, --program_id
                         NULL --program_update_date
                         -- PHENIX 2004
                        -- , 'EUR',
						,vn_revproc_currency_code , --REVPROC_CURRENCY_CODE --AAM artf07231300
						--'EUR',
						vn_projfunc_currency_code , --PROJFUNC_CURRENCY_CODE --AAM artf07231300
						vn_acct_amount,
                        -- 'EUR',
						vn_project_currency_code , -- PROJECT_CURRENCY_CODE --AAM artf07231300
						vn_acct_amount, 'EUR', vn_acct_amount
                         -- FIN PHENIX 2004
                        );

            -- Insertion des données dans la Table PA_CUST_EVENT_RDL_ALL :
            Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT:  Insertion de l''Evenement dans la Table PA_CUST_EVENT_RDL_ALL');

            vv_step := 'INSERT pa_cust_event_rdl_all';
            INSERT INTO pa_cust_event_rdl_all
                        (task_id,  --task_id JPE chgt ¿ confirmer
                         event_num,
                         line_num,
                         amount,
                         creation_date,
                         created_by,
                         project_id,
                         draft_revenue_num,
                         draft_revenue_item_line_num,
                         code_combination_id,
                         request_id,
                         program_application_id,
                         program_id,
                         program_update_date,
                         draft_invoice_num,
                         draft_invoice_item_line_num,
                         batch_name,
                         line_num_reversed,
                         reversed_flag,
                         org_id,
                         output_vat_tax_id,
                         output_tax_exempt_flag,
                         output_tax_exempt_reason_code,
                         output_tax_exempt_number,
                         prc_generated_flag
                         -- PHENIX 2004
                         , BILL_TRANS_CURRENCY_CODE, BILL_TRANS_AMOUNT, REVPROC_CURRENCY_CODE,
                         REVPROC_RATE_TYPE, REVPROC_RATE_DATE, REVPROC_EXCHANGE_RATE, INVPROC_CURRENCY_CODE,
                         INVPROC_RATE_TYPE, INVPROC_RATE_DATE, INVPROC_EXCHANGE_RATE, PROJECT_CURRENCY_CODE,
                         PROJECT_REVENUE_AMOUNT, PROJECT_REV_RATE_TYPE, PROJECT_REV_RATE_DATE, PROJECT_REV_EXCHANGE_RATE,
                         PROJECT_BILL_AMOUNT, PROJECT_INV_RATE_TYPE, PROJECT_INV_RATE_DATE, PROJECT_INV_EXCHANGE_RATE,
                         PROJFUNC_CURRENCY_CODE, PROJFUNC_REVENUE_AMOUNT, PROJFUNC_REV_RATE_TYPE, PROJFUNC_REV_RATE_DATE,
                         PROJFUNC_REV_EXCHANGE_RATE, PROJFUNC_BILL_AMOUNT, PROJFUNC_INV_RATE_TYPE, PROJFUNC_INV_RATE_DATE,
                         PROJFUNC_INV_EXCHANGE_RATE, FUNDING_CURRENCY_CODE, FUNDING_REVENUE_AMOUNT, FUNDING_REV_RATE_TYPE,
                         FUNDING_REV_RATE_DATE, FUNDING_REV_EXCHANGE_RATE, FUNDING_BILL_AMOUNT, FUNDING_INV_RATE_TYPE,
                         FUNDING_INV_RATE_DATE, FUNDING_INV_EXCHANGE_RATE, INV_GEN_REJECTION_CODE, RETN_DRAFT_INVOICE_NUM,
                         RETN_DRAFT_INVOICE_LINE_NUM, RETAINED_AMOUNT, RETENTION_RULE_ID
                         -- FIN PHENIX 2004
                        )
            VALUES      (pn_task_id, --task_id JPE chgt ¿ confirmer
                         vn_event_num, --event_num
                         1, --line_num
                         vn_acct_amount, --amount
                         SYSDATE, --creation_date
                         Fnd_Global.user_id, --created_by
                         pn_project_id, --project_id
                         vn_draft_revenue_num, --draft_revenue_num
                         1, --draft_revenue_item_line_num                                                                                   num,
                         vn_ccid, --code_combination_id
                         Fnd_Global.conc_request_id, --request_id
                         Fnd_Global.prog_appl_id, --program_application_id
                         Fnd_Global.conc_program_id, --program_id
                         SYSDATE, --program_update_date
                         NULL, --draft_invoice_num
                         NULL, --draft_invoice_item_line_num                                                                                   num,
                         TO_CHAR (vn_unbilled_ccid) || '-' || TO_CHAR (pd_completion_date, 'DD-MON-RR') || '-' || TO_CHAR (
                                                                                                                      vn_event_id
                                                                                                                  ), --batch_name
                         NULL, --line_num_reversed
                         NULL, --reversed_flag
                         vn_org_id, --org_id
                         NULL, --output_vat_tax_id
                         NULL, --output_tax_exempt_flag
                         NULL, --output_tax_exempt_reason                                                                                  _code,
                         NULL, --output_tax_exempt_number                                                                                  ,
                         NULL --prc_generated_flag
                         -- PHENIX 2004
                        -- , 'EUR',
						,vn_bill_trans_currency_code ,-- BILL_TRANS_CURRENCY_CODE --AAM artf07231300
						 vn_acct_amount,
						-- 'EUR',
						vn_revproc_currency_code , --REVPROC_CURRENCY_CODE --AAM artf07231300
                         NULL, NULL, NULL,
						-- NULL,
						vn_invproc_currency_code,--INVPROC_CURRENCY_CODE --AAM artf07231300
                         NULL, NULL, NULL,
						-- 'EUR',
						vn_project_currency_code ,--PROJECT_CURRENCY_CODE--AAM artf07231300
                         vn_acct_amount, NULL, NULL, NULL,
                         NULL, NULL, NULL, NULL,
                        -- 'EUR', 
						vn_projfunc_currency_code ,--PROJFUNC_CURRENCY_CODE --AAM artf07231300
						 vn_acct_amount, NULL, NULL,
                         NULL, NULL, NULL, NULL,
                         NULL, 'EUR', vn_acct_amount, NULL,
                         NULL, NULL, NULL, NULL,
                         NULL, NULL, NULL, NULL,
                         NULL, NULL, NULL
                         -- FIN PHENIX 2004
                        );

            --  Insertion des données dans la Table PA_DISTRIBUTION_WARNINGS:
            Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT: Insertion de l''Evenement dans la Table PA_DISTRIBUTION_WARNINGS');

            vv_step := 'INSERT pa_distribution_warnings';
            INSERT INTO pa_distribution_warnings
                        (project_id,
                         task_id, --task_id JPE chgt ¿ confirmer
                         draft_revenue_num,
                         draft_invoice_num,
                         last_update_date,
                         last_updated_by,
                         creation_date,
                         created_by,
                         last_update_login,
                         request_id,
                         program_application_id,
                         program_id,
                         program_update_date,
                         warning_message
                        )
                SELECT pn_project_id, --project_id
                       pn_task_id, --task_id JPE chgt ¿ confirmer
                       vn_draft_revenue_num, --draft_revenue_num
                       NULL, --draft_invoice_num
                       SYSDATE, --last_update_date
                       Fnd_Global.user_id, --last_updated_by
                       SYSDATE, --creation_date
                       Fnd_Global.user_id, --created_by
                       Fnd_Global.login_id, --last_update_login
                       Fnd_Global.conc_request_id, --request_id
                       Fnd_Global.prog_appl_id, --program_application_id
                       Fnd_Global.conc_program_id, --program_id
                       SYSDATE, --pogram_update_date
                       pl.meaning --warning_message)
                FROM   pa_lookups pl
                WHERE      pl.lookup_type = 'REVENUE DISTRIBUTION WARNING'
                       AND pl.lookup_code = 'SOFT LIMIT';

            --Update de la Table PA_SUMMARY_PROJECT_FUNDINGS:
            Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT: UPDATE  de la Table PA_SUMMARY_PROJECT_FUNDINGS');

            vv_step := 'UPDATE pa_summary_project_fundings pspf';
            UPDATE pa_summary_project_fundings pspf
            SET    pspf.total_accrued_amount = total_accrued_amount + pn_amount,
                   pspf.last_update_date = SYSDATE,
                   pspf.last_updated_by = Fnd_Global.user_id,
                   pspf.last_update_login = Fnd_Global.login_id
            WHERE      pspf.project_id = pn_project_id
                   AND pspf.agreement_id = vn_agreement_id;

            IF pv_insert_into_gl = 'Y'
            THEN
                -- Insertion des données dans la Table GL_INTERFACE:
                Dka_Tools_Pkg.put_debug_message ('PROC_PA_INSERT_EVENT: Insertion de l''¿venement dans la table GL_INTERFACE');

                vv_step := 'select_pa_projects';
                SELECT pp.segment1
                INTO   vv_project_number
                FROM   pa_projects/*_all*/ pp /*ETANCHEITE DALKIA 2007*/
                WHERE  pp.project_id = pn_project_id;

                -- NBO - 16/11/16 - Ajout de la notion de tâche dans la description sur GL_INTERFACE
                vv_step := 'select_pa_tasks';
                IF pn_task_id IS NOT NULL THEN
                   SELECT pt.task_number
                   INTO   vv_task_number
                   FROM   pa_tasks pt
                   WHERE  pt.task_id = pn_task_id;
                   
                   vv_description := (vv_project_number || '-' || vv_task_number || ' - ' || pv_event_type);
                ELSE
                   vv_description := (vv_project_number || ' - ' || pv_event_type);
                END IF;
                
                -- Insertion de la ligne au débit
                vv_step := 'INSERT INTO gl_interface debit';
                INSERT INTO gl_interface
                            (status,
                             set_of_books_id,
                             accounting_date,
                             currency_code,
                             date_created,
                             created_by,
                             actual_flag,
                             user_je_category_name,
                             user_je_source_name,
                             currency_conversion_date,
                             encumbrance_type_id,
                             budget_version_id,
                             user_currency_conversion_type,
                             currency_conversion_rate,
                             average_journal_flag,
                             originating_bal_seg_value,
                             segment1,
                             segment2,
                             segment3,
                             segment4,
                             segment5,
                             segment6,
                             segment7,
                             segment8,
                             segment9,
                             segment10,
                             segment11,
                             segment12,
                             segment13,
                             segment14,
                             segment15,
                             segment16,
                             segment17,
                             segment18,
                             segment19,
                             segment20,
                             segment21,
                             segment22,
                             segment23,
                             segment24,
                             segment25,
                             segment26,
                             segment27,
                             segment28,
                             segment29,
                             segment30,
                             entered_dr,
                             entered_cr,
                             accounted_dr,
                             accounted_cr,
                             transaction_date,
                             reference1,
                             reference2,
                             reference3,
                             reference4,
                             reference5,
                             reference6,
                             reference7,
                             reference8,
                             reference9,
                             reference10,
                             reference11,
                             reference12,
                             reference13,
                             reference14,
                             reference15,
                             reference16,
                             reference17,
                             reference18,
                             reference19,
                             reference20,
                             reference21,
                             reference22,
                             reference23,
                             reference24,
                             reference25,
                             reference26,
                             reference27,
                             reference28,
                             reference29,
                             reference30,
                             je_batch_id,
                             period_name,
                             je_header_id,
                             je_line_num,
                             chart_of_accounts_id,
                             functional_currency_code,
                             code_combination_id,
                             date_created_in_gl,
                             warning_code,
                             stat_amount,
                             status_description,
                             GROUP_ID,
                             request_id,
                             subledger_doc_sequence_id,
                             subledger_doc_sequence_value,
                             attribute1,
                             attribute2,
                             gl_sl_link_id,
                             gl_sl_link_table,
                             attribute3,
                             attribute4,
                             attribute5,
                             attribute6,
                             attribute7,
                             attribute8,
                             attribute9,
                             attribute10,
                             attribute11,
                             attribute12,
                             attribute13,
                             attribute14,
                             attribute15,
                             attribute16,
                             attribute17,
                             attribute18,
                             attribute19,
                             attribute20,
                             CONTEXT,
                             context2,
                             invoice_date,
                             tax_code,
                             invoice_identifier,
                             invoice_amount,
                             context3,
                             ussgl_transaction_code,
                             descr_flex_error_message,
                             jgzz_recon_ref
                            )
                VALUES      ('NEW', --status
                             vn_set_of_books_id, --set_of_books_id
                             pd_completion_date, --accounting_date
                             vv_currency_code, --currency_code
                             SYSDATE, --date_created
                             Fnd_Global.user_id, --created_by
                             'A', --actual_flag
                             gv_user_je_category_name, --user_je_category_name
                             gv_user_je_source_name, --user_je_source_name
                             NULL, --currency_conversion_date
                             NULL, --encumbrance_type_id
                             NULL, --budget_version_id
                             NULL, --user_currency_conversion_type
                             NULL, --currency_conversion_rate
                             NULL, --average_journal_flag
                             NULL, --originating_bal_seg_value
                             NULL, --segment1
                             NULL, --segment2
                             NULL, --segment3
                             NULL, --segment4
                             NULL, --segment5
                             NULL, --segment6
                             NULL, --segment7
                             NULL, --segment8
                             NULL, --segment9
                             NULL, --segment10
                             NULL, --segment11
                             NULL, --segment12
                             NULL, --segment13
                             NULL, --segment14
                             NULL, --segment15
                             NULL, --segment16
                             NULL, --segment17
                             NULL, --segment18
                             NULL, --segment19
                             NULL, --segment20
                             NULL, --segment21
                             NULL, --segment22
                             NULL, --segment23
                             NULL, --segment24
                             NULL, --segment25
                             NULL, --segment26
                             NULL, --segment27
                             NULL, --segment28
                             NULL, --segment29
                             NULL, --segment30
                             pn_amount, --entered_dr
                             NULL, --entered_cr
                             NULL, --accounted_dr
                             NULL, --accounted_cr
                             NULL, --transaction_date
                             pv_batch_name, --reference1
                             pv_batch_name, --reference2
                             NULL, --reference3
                             gv_user_je_category_name, --reference4
                             NULL, --reference5
                             NULL, --reference6
                             NULL, --reference7
                             NULL, --reference8
                             NULL, --reference9
                             --(vv_project_number || ' - ' || pv_event_type), --reference10 : Description
                             vv_description, --reference10 : Description
                             NULL, --reference11
                             NULL, --reference12
                             NULL, --reference13
                             NULL, --reference14
                             NULL, --reference15
                             NULL, --reference16
                             NULL, --reference17
                             NULL, --reference18
                             NULL, --reference19
                             NULL, --reference20
                             (   TO_CHAR (DECODE (vv_event_type_class,
                                                  'WRITE ON', vn_unbilled_ccid,
                                                  vn_ccid))
                              || '-'
                              || TO_CHAR (pd_completion_date, 'DD-MON-RR')
                              || '-'
                              || TO_CHAR (vn_event_id)), --reference21
                             TO_CHAR (DECODE (vv_event_type_class,
                                              'WRITE ON', vn_ccid,
                                              vn_unbilled_ccid)), --reference22
                             'Revenue - Event Revenue', --reference23
                             NULL, --reference24
                             NULL, --reference25
                             (   TO_CHAR (DECODE (vv_event_type_class,
                                                  'WRITE ON', vn_unbilled_ccid,
                                                  vn_ccid))
                              || '-'
                              || TO_CHAR (pd_completion_date, 'DD-MON-RR')
                              || '-'
                              || TO_CHAR (vn_event_id)), --reference26
                             NULL, --reference27
                             NULL, --reference28
                             NULL, --reference29
                             NULL, --reference30
                             NULL, --je_batch_id
                             NULL, --period_name
                             NULL, --je_header_id
                             NULL, --je_line_num
                             NULL, --chart_of_accounts_id
                             NULL, --functional_currency_code
                             DECODE (vv_event_type_class,
                                     'WRITE ON', vn_unbilled_ccid,
                                     vn_ccid), --code_combination_id
                             NULL, --date_created_in_gl
                             NULL, --warning_code
                             NULL, --stat_amount
                             NULL, --status_description
                             pn_group_id, --group_id
                             NULL, --request_id
                             NULL, --subledger_doc_sequence_id
                             NULL, --subledger_doc_sequence_value
                             NULL, --attribute1
                             NULL, --attribute2
                             NULL, --gl_sl_link_id
                             NULL, --gl_sl_link_table
                             NULL, --attribute3
                             NULL, --attribute4
                             NULL, --attribute5
                             NULL, --attribute6
                             NULL, --attribute7
                             NULL, --attribute8
                             NULL, --attribute9
                             NULL, --attribute10
                             NULL, --attribute11
                             NULL, --attribute12
                             NULL, --attribute13
                             NULL, --attribute14
                             NULL, --attribute15
                             NULL, --attribute16
                             NULL, --attribute17
                             NULL, --attribute18
                             NULL, --attribute19
                             NULL, --attribute20
                             NULL, --context
                             'No', --context2
                             NULL, --invoice_date
                             NULL, --tax_code
                             NULL, --invoice_identifier
                             NULL, --invoice_amount
                             NULL, --context3
                             NULL, --ussgl_transaction_code
                             NULL, --descr_flex_error_message
                             NULL --jgzz_recon_ref
                            );

                -- Insertion de la ligne au crédit
                vv_step := 'INSERT INTO gl_interface credit';
                INSERT INTO gl_interface
                            (status,
                             set_of_books_id,
                             accounting_date,
                             currency_code,
                             date_created,
                             created_by,
                             actual_flag,
                             user_je_category_name,
                             user_je_source_name,
                             currency_conversion_date,
                             encumbrance_type_id,
                             budget_version_id,
                             user_currency_conversion_type,
                             currency_conversion_rate,
                             average_journal_flag,
                             originating_bal_seg_value,
                             segment1,
                             segment2,
                             segment3,
                             segment4,
                             segment5,
                             segment6,
                             segment7,
                             segment8,
                             segment9,
                             segment10,
                             segment11,
                             segment12,
                             segment13,
                             segment14,
                             segment15,
                             segment16,
                             segment17,
                             segment18,
                             segment19,
                             segment20,
                             segment21,
                             segment22,
                             segment23,
                             segment24,
                             segment25,
                             segment26,
                             segment27,
                             segment28,
                             segment29,
                             segment30,
                             entered_dr,
                             entered_cr,
                             accounted_dr,
                             accounted_cr,
                             transaction_date,
                             reference1,
                             reference2,
                             reference3,
                             reference4,
                             reference5,
                             reference6,
                             reference7,
                             reference8,
                             reference9,
                             reference10,
                             reference11,
                             reference12,
                             reference13,
                             reference14,
                             reference15,
                             reference16,
                             reference17,
                             reference18,
                             reference19,
                             reference20,
                             reference21,
                             reference22,
                             reference23,
                             reference24,
                             reference25,
                             reference26,
                             reference27,
                             reference28,
                             reference29,
                             reference30,
                             je_batch_id,
                             period_name,
                             je_header_id,
                             je_line_num,
                             chart_of_accounts_id,
                             functional_currency_code,
                             code_combination_id,
                             date_created_in_gl,
                             warning_code,
                             stat_amount,
                             status_description,
                             GROUP_ID,
                             request_id,
                             subledger_doc_sequence_id,
                             subledger_doc_sequence_value,
                             attribute1,
                             attribute2,
                             gl_sl_link_id,
                             gl_sl_link_table,
                             attribute3,
                             attribute4,
                             attribute5,
                             attribute6,
                             attribute7,
                             attribute8,
                             attribute9,
                             attribute10,
                             attribute11,
                             attribute12,
                             attribute13,
                             attribute14,
                             attribute15,
                             attribute16,
                             attribute17,
                             attribute18,
                             attribute19,
                             attribute20,
                             CONTEXT,
                             context2,
                             invoice_date,
                             tax_code,
                             invoice_identifier,
                             invoice_amount,
                             context3,
                             ussgl_transaction_code,
                             descr_flex_error_message,
                             jgzz_recon_ref
                            )
                VALUES      ('NEW', --status
                             vn_set_of_books_id, --set_of_books_id
                             pd_completion_date, --accounting_date
                             vv_currency_code, --currency_code
                             SYSDATE, --date_created
                             Fnd_Global.user_id, --created_by
                             'A', --actual_flag
                             gv_user_je_category_name, --user_je_category_name
                             gv_user_je_source_name, --user_je_source_name
                             NULL, --currency_conversion_date
                             NULL, --encumbrance_type_id
                             NULL, --budget_version_id
                             NULL, --user_currency_conversion_type
                             NULL, --currency_conversion_rate
                             NULL, --average_journal_flag
                             NULL, --originating_bal_seg_value
                             NULL, --segment1
                             NULL, --segment2
                             NULL, --segment3
                             NULL, --segment4
                             NULL, --segment5
                             NULL, --segment6
                             NULL, --segment7
                             NULL, --segment8
                             NULL, --segment9
                             NULL, --segment10
                             NULL, --segment11
                             NULL, --segment12
                             NULL, --segment13
                             NULL, --segment14
                             NULL, --segment15
                             NULL, --segment16
                             NULL, --segment17
                             NULL, --segment18
                             NULL, --segment19
                             NULL, --segment20
                             NULL, --segment21
                             NULL, --segment22
                             NULL, --segment23
                             NULL, --segment24
                             NULL, --segment25
                             NULL, --segment26
                             NULL, --segment27
                             NULL, --segment28
                             NULL, --segment29
                             NULL, --segment30
                             NULL, --entered_dr
                             pn_amount, --entered_cr
                             NULL, --accounted_dr
                             NULL, --accounted_cr
                             NULL, --transaction_date
                             pv_batch_name, --reference1
                             pv_batch_name, --reference2
                             NULL, --reference3
                             gv_user_je_category_name, --reference4
                             NULL, --reference5
                             NULL, --reference6
                             NULL, --reference7
                             NULL, --reference8
                             NULL, --reference9
                             -- NBO - 16/11/16 - Ajout de la notion de tâche dans la description sur GL_INTERFACE
                             --(vv_project_number || ' - ' || pv_event_type), --reference10 : Description
                             vv_description, --reference10 : Description
                             NULL, --reference11
                             NULL, --reference12
                             NULL, --reference13
                             NULL, --reference14
                             NULL, --reference15
                             NULL, --reference16
                             NULL, --reference17
                             NULL, --reference18
                             NULL, --reference19
                             NULL, --reference20
                             (  TO_CHAR (DECODE (vv_event_type_class,
                                                 'WRITE ON', vn_ccid,
                                                 vn_unbilled_ccid))
                              || '-'
                              || TO_CHAR (pd_completion_date, 'DD-MON-RR')
                              || '-'
                              || TO_CHAR (vn_event_id)), --reference21
                             TO_CHAR (DECODE (vv_event_type_class,
                                              'WRITE ON', vn_unbilled_ccid,
                                              vn_ccid)), --reference22
                             'Revenue - Event Revenue', --reference23
                             NULL, --reference24
                             NULL, --reference25
                             (  TO_CHAR (DECODE (vv_event_type_class,
                                                 'WRITE ON', vn_ccid,
                                                 vn_unbilled_ccid))
                              || '-'
                              || TO_CHAR (pd_completion_date, 'DD-MON-RR')
                              || '-'
                              || TO_CHAR (vn_event_id)), --reference26
                             NULL, --reference27
                             NULL, --reference28
                             NULL, --reference29
                             NULL, --reference30
                             NULL, --je_batch_id
                             NULL, --period_name
                             NULL, --je_header_id
                             NULL, --je_line_num
                             NULL, --chart_of_accounts_id
                             NULL, --functional_currency_code
                             DECODE (vv_event_type_class,
                                     'WRITE ON', vn_ccid,
                                     vn_unbilled_ccid), --code_combination_id
                             NULL, --date_created_in_gl
                             NULL, --warning_code
                             NULL, --stat_amount
                             NULL, --status_description
                             pn_group_id, --group_id
                             NULL, --request_id
                             NULL, --subledger_doc_sequence_id
                             NULL, --subledger_doc_sequence_value
                             NULL, --attribute1
                             NULL, --attribute2
                             NULL, --gl_sl_link_id
                             NULL, --gl_sl_link_table
                             NULL, --attribute3
                             NULL, --attribute4
                             NULL, --attribute5
                             NULL, --attribute6
                             NULL, --attribute7
                             NULL, --attribute8
                             NULL, --attribute9
                             NULL, --attribute10
                             NULL, --attribute11
                             NULL, --attribute12
                             NULL, --attribute13
                             NULL, --attribute14
                             NULL, --attribute15
                             NULL, --attribute16
                             NULL, --attribute17
                             NULL, --attribute18
                             NULL, --attribute19
                             NULL, --attribute20
                             NULL, --context
                             'No', --context2
                             NULL, --invoice_date
                             NULL, --tax_code
                             NULL, --invoice_identifier
                             NULL, --invoice_amount
                             NULL, --context3
                             NULL, --ussgl_transaction_code
                             NULL, --descr_flex_error_message
                             NULL --jgzz_recon_ref
                            );
            END IF;
        END IF; -- Fin d'insertion des données du revenu
    EXCEPTION
        WHEN e_error
        THEN
            pn_result    := 2;
            pv_errbuf    := vv_step ||':' || NVL (pv_errbuf, 'E R R E U R');
        WHEN OTHERS
        THEN
            pn_result    := SQLCODE;
            pv_errbuf    := vv_step ||':' || SQLERRM;
    END pa_insert_event;
    
-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_GET_INFO_TASK
--  Description   : Récupération des informations relative a la tache en parametre
--
--  PARAMETRES    :
--    pv_errbuf           varchar2
--    pn_retcode          number
--    pv_task_number      varchar2
--    pv_task_id          number
--    pv_segment1         varchar2
--    pn_project_id       varchar2
--    pv_project_name     varchar2
--    pv_project_type     varchar2
--    pd_start_date       date
--    pd_completion_date  date
--    pd_closed_date      date
--    pv_org_projet       varchar2
--    pv_org_projet_id       number
--    pv_societe          varchar2
--    pv_region           varchar2
--    pv_org_fin          varchar2
--    pv_org_fin_id       number
--
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_get_info_task (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pv_task_number        IN       VARCHAR2,
        pv_task_id            OUT      NUMBER,
        pn_project_id         OUT      VARCHAR2,  
        pv_project_name       OUT      VARCHAR2,  
        pv_project_type       OUT      VARCHAR2,  
        pd_start_date         OUT      DATE,      
        pd_completion_date    OUT      DATE,      
        pd_closed_date        OUT      DATE,      
        pv_org_projet         OUT      VARCHAR2,
        pv_org_projet_id      OUT      NUMBER,  
        pv_societe            OUT      VARCHAR2,  
        pv_region             OUT      VARCHAR2,  
        pv_org_fin            OUT      VARCHAR2,  
        pv_org_fin_id         OUT      NUMBER
        ) is
    BEGIN
       pv_errbuf  := '';
       pn_retcode := 0;
    
      SELECT 
           pt.task_id,
           ppa.project_id,
           ppa.segment1,
           ppa.project_type,
           ppa.start_date,
           ppa.completion_date,
           ppa.closed_date,
           haou_p.NAME ORG_PROJET,
           haou_p.organization_id ORG_PROJET_ID,
           substr(haou_p.NAME,-4) SOCIETE,
           substr(haou_p.NAME,1,3) REGION,
           haou_c.NAME ORG_FIN,
           haou_c.organization_id ORG_FIN_ID
      INTO
          pv_task_id,         
          pn_project_id,      
          pv_project_name,    
          pv_project_type,    
          pd_start_date,      
          pd_completion_date, 
          pd_closed_date,     
          pv_org_projet, 
          pv_org_projet_id,     
          pv_societe,         
          pv_region,          
          pv_org_fin,
          pv_org_fin_id         
      FROM pa_projects_all           ppa,
           pa_tasks                  pt,
           hr_all_organization_units haou_p,
           hr_all_organization_units haou_c
     WHERE ppa.project_id = pt.project_id
       AND ppa.org_id = haou_p.organization_id
       AND ppa.carrying_out_organization_id = haou_c.organization_id
       AND ppa.enabled_flag = 'Y'
       AND ppa.summary_flag = 'N'
       AND ppa.template_flag = 'N'
       AND SYSDATE BETWEEN nvl(ppa.start_date,SYSDATE) AND nvl(ppa.closed_date,SYSDATE)
       AND SYSDATE BETWEEN nvl(pt.start_date,SYSDATE) AND nvl(pt.completion_date,SYSDATE)
       AND pt.task_number = pv_task_number;
    
    EXCEPTION
     WHEN OTHERS THEN
       pv_errbuf  := SQLERRM;
       pn_retcode := 2;
    END pa_get_info_task;
    

----------------------------------------------------------------------------------------
--  Nom           : PA_GET_CODE_Z_REFAC
--  Description   : Procédure permettant de déterminer le code projet de Refac
--                  correspondant au couple société/centre de gestion
--  PARAMETRES :
--    pn_org_id         Entrée
--    pv_segment1       Sortie
--    pn_project_id     Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
--- PHENIX 2004
--- suppression de la premiere partie du " IF " (test + requete sur " hr_all_organization_units ")
    PROCEDURE pa_get_code_z_refac (
        pn_org_id           IN       NUMBER DEFAULT NULL,
        pv_societe          IN       VARCHAR2 DEFAULT NULL,
        pv_centre_gestion   IN       VARCHAR2,
        pv_segment1         OUT      VARCHAR2,
        pn_project_id       OUT      NUMBER,
        pv_project_name     OUT      VARCHAR2,
        pv_errbuf           OUT      VARCHAR2,
        pn_retcode          OUT      NUMBER
    )
    IS
        gv_project_type_refac   pa_project_types_all.project_type%TYPE;
        vv_societe              hr_all_organization_units.NAME%TYPE;
        rec_param               dka_parameters%ROWTYPE;
        e_param                 EXCEPTION;
    BEGIN
        -- Initialisation des variables de sortie
        pv_errbuf                := NULL;
        pn_retcode               := 0;
        pv_segment1              := NULL;
        pn_project_id            := NULL;

---------------------------------------
-- Récupération des parametres       --
---------------------------------------
        Dka_Tools_Pkg.get_parameter ('TOOLS', 'PROJECT_TYPE_REFAC', rec_param, pn_retcode, pv_errbuf);
        gv_project_type_refac    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'PA_GET_CODE_Z_REFAC - PROJECT_TYPE_REFAC - ' || pv_errbuf;
            RETURN;
        END IF;

        --- PHENIX 2004
        --IF      pv_societe IS NULL
        --    AND pn_org_id IS NOT NULL
        --THEN
        --    SELECT hou.NAME
        --    INTO   vv_societe
        --    FROM   hr_all_organization_units hou
        --    WHERE  hou.organization_id = pn_org_id;
        --ELSIF pv_societe IS NOT NULL
        IF pv_societe IS NOT NULL
        THEN
            vv_societe    := pv_societe;
        ELSE
            RAISE e_param;
        END IF;
        --- Fin PHENIX 2004

        SELECT pp.project_id,
               pp.segment1,
               pp.NAME
        INTO   pn_project_id,
               pv_segment1,
               pv_project_name
        FROM   pa_projects_all pp /*ETANCHEITE DALKIA 2007*/
        WHERE      pp.template_flag = 'N'
               AND pp.project_type = gv_project_type_refac
               AND pp.segment1 = pv_centre_gestion || vv_societe;
    EXCEPTION
        WHEN e_param
        THEN
            pv_errbuf     := 'PA_GET_CODE_Z_REFAC - Erreur lors du passage des parametres';
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := 'PA_GET_CODE_Z_REFAC - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END pa_get_code_z_refac;
    
-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_PROJECT_INFO
--  Description   : Récupération d'informations du projet
--
--  PARAMETRES    :
--      pv_errbuf               OUT VARCHAR2
--      pn_retcode              OUT NUMBER
--      pn_project_id           IN  NUMBER
--      pv_project_segment1     IN  VARCHAR2
--      pv_project_soc          OUT VARCHAR2
--      pv_project_type         OUT VARCHAR2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE get_project_info (
        pv_errbuf             OUT      VARCHAR2,
        pn_retcode            OUT      NUMBER,
        pn_project_id         IN       NUMBER DEFAULT NULL,
        pv_project_segment1   IN       VARCHAR2 DEFAULT NULL,
        pv_project_soc        OUT      VARCHAR2, 
        pv_project_type       OUT      VARCHAR2
    )
    IS
    BEGIN
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        IF pn_project_id IS NOT NULL
        THEN
            SELECT substr(haou.name,4),
                   pp.project_type
            INTO   pv_project_soc,
                   pv_project_type
            FROM   pa_projects_all pp,
                   hr_all_organization_units haou
            WHERE  pp.project_id = pn_project_id
            AND    pp.org_id = haou.organization_id;
            
        ELSIF pv_project_segment1 IS NOT NULL
        THEN
            SELECT substr(haou.name,4) ,
                   pp.project_type
            INTO   pv_project_soc, 
                   pv_project_type
            FROM   pa_projects_all pp,
                   hr_all_organization_units haou
            WHERE  pp.segment1 = pv_project_segment1
            AND    pp.org_id = haou.organization_id;
        ELSE
            pv_errbuf     := 'GET_PROJECT_INFO - ' || 'Parametres non valides';
            pn_retcode    := 2;
        END IF;
        
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'GET_PROJECT_INFO - ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END get_project_info;

----------------------------------------------------------------------------------------
--  Nom           : PA_RUN_ACCOUNTING_RULE
--  Description   : Procédure permettant d'executer
--                  une règle d'autoaccounting
--  PARAMETRES :
--    pn_org_id         Entrée
--    pv_segment1       Sortie
--    pn_project_id     Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
    PROCEDURE pa_run_accounting_rule (
        pn_rule_id             IN       NUMBER DEFAULT NULL,
        pv_rule_name           IN       VARCHAR2 DEFAULT NULL,
        pv_expenditure_type    IN       VARCHAR2 DEFAULT NULL, -- Par 03
        pv_organization_name   IN       VARCHAR2 DEFAULT NULL, -- Par 06
        pv_revenue_category    IN       VARCHAR2 DEFAULT NULL, -- Par 07
        pv_event_type          IN       VARCHAR2 DEFAULT NULL, -- Par 19
        pn_project_id          IN       NUMBER DEFAULT NULL, -- Par 24
        pn_event_num           IN       NUMBER DEFAULT NULL, -- Par 33
        pv_segment_value       OUT      VARCHAR2,
        pv_errbuf              OUT      VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
        e_error                          EXCEPTION;
        vn_rule_id                       pa_rules.rule_id%TYPE;
        vv_key_source                    pa_rules.key_source%TYPE;
        vv_constant_value                pa_rules.constant_value%TYPE;
        vn_key_parameter_id              pa_rules.key_parameter_id%TYPE;
        vv_select_statement              pa_rules.select_statement%TYPE;
        vv_rule_type                     pa_rules.rule_type%TYPE;
        vn_segment_value_lookup_set_id   pa_rules.segment_value_lookup_set_id%TYPE;
        vv_segment_lookup                pa_rules.constant_value%TYPE;
        vv_parameter_value               pa_rules.constant_value%TYPE;
        vv_segment_value                 gl_code_combinations.segment1%TYPE;
        vv_class_code                    pa_project_classes.class_code%TYPE;
        CURSOR rule_parameter_cur (
            p_rule_id   IN   NUMBER
        )
        IS
            SELECT   prp.parameter_seq,
                     prp.parameter_id
            FROM     pa_rule_parameters prp
            WHERE    prp.rule_id = p_rule_id
            ORDER BY parameter_seq DESC;

        rule_parameter_rec               rule_parameter_cur%ROWTYPE;
    BEGIN
        -- Récupération du rule_id
        IF pn_rule_id IS NOT NULL
        THEN
            vn_rule_id    := pn_rule_id;
        ELSIF pv_rule_name IS NOT NULL
        THEN
            SELECT pr.rule_id
            INTO   vn_rule_id
            FROM   pa_rules pr
            WHERE  pr.rule_name = pv_rule_name;
        ELSE
            RAISE_APPLICATION_ERROR (-20001, 'PA_RUN_ACCOUNTING_RULE - Paramètres incorrects');
        END IF;

        -- Récupération des informations globales
        SELECT pr.key_source,
               pr.constant_value,
               pr.key_parameter_id,
               pr.select_statement,
               pr.rule_type,
               pr.segment_value_lookup_set_id
        INTO   vv_key_source,
               vv_constant_value,
               vn_key_parameter_id,
               vv_select_statement,
               vv_rule_type,
               vn_segment_value_lookup_set_id
        FROM   pa_rules pr
        WHERE  pr.rule_id = vn_rule_id;

        -- Détermination de la valeur intermédiaire
        IF vv_key_source = 'C' -- Constante
        THEN
            vv_segment_lookup    := vv_constant_value;
        ELSIF vv_key_source = 'P' -- Parametre
        THEN
            IF vn_key_parameter_id = 1
            THEN
                SELECT ppc.class_code
                INTO   vv_class_code
                FROM   pa_class_categories pcc,
                       pa_project_classes ppc
                WHERE      pcc.autoaccounting_flag = 'Y'
                       AND ppc.class_category = pcc.class_category
                       AND ppc.project_id = pn_project_id;
            END IF;
            SELECT DECODE (
                       pp.parameter_id,
                       1, vv_class_code,
                       3, pv_expenditure_type,
                       6, pv_organization_name,
                       7, pv_revenue_category,
                       19, pv_event_type,
                       24, TO_CHAR (pn_project_id),
                       33, TO_CHAR (pn_event_num),
                       NULL
                   ) --'/!\ Erreur')
            INTO   vv_segment_lookup
            FROM   pa_parameters pp
            WHERE  pp.parameter_id = vn_key_parameter_id;
        ELSIF vv_key_source = 'S' -- Ordre SQL
        THEN
            -- Remplacement des parametres
            OPEN rule_parameter_cur (p_rule_id => vn_rule_id);

            LOOP
                FETCH rule_parameter_cur INTO rule_parameter_rec;
                EXIT WHEN rule_parameter_cur%NOTFOUND;
                
                IF rule_parameter_rec.parameter_id = 1
                THEN
                    SELECT ppc.class_code
                    INTO   vv_class_code
                    FROM   pa_class_categories pcc,
                           pa_project_classes ppc
                    WHERE      pcc.autoaccounting_flag = 'Y'
                           AND ppc.class_category = pcc.class_category
                           AND ppc.project_id = pn_project_id;
                END IF;

                SELECT DECODE (
                           pp.parameter_id,
                           1, vv_class_code,
                           3, pv_expenditure_type,
                           6, pv_organization_name,
                           7, pv_revenue_category,
                           19, pv_event_type,
                           24, TO_CHAR (pn_project_id),
                           33, TO_CHAR (pn_event_num),
                           NULL --'/!\ Erreur'
                       )
                INTO   vv_parameter_value
                FROM   pa_parameters pp
                WHERE  pp.parameter_id = rule_parameter_rec.parameter_id;

                vv_select_statement    :=
                               REPLACE (vv_select_statement, ':' || rule_parameter_rec.parameter_seq,    ''''
                                                                                                      || vv_parameter_value
                                                                                                      || '''');
            END LOOP;

            CLOSE rule_parameter_cur;
            --vv_step := 'vv_select_statement :' || vv_select_statement;              
                
            -- Execution de la requete
            EXECUTE IMMEDIATE vv_select_statement
                INTO vv_segment_lookup;
        ELSE
            pn_retcode    := 2;
            pv_errbuf     := 'Erreur key_source: rule_id = ' || TO_CHAR (pn_rule_id);
            RETURN;
        END IF;

        -- Fin de la determination de la valeur intermediaire

        -- Determination de la valeur finale
        IF vv_rule_type = 'K'
        THEN
            vv_segment_value    := vv_segment_lookup;
        ELSIF vv_rule_type = 'L'
        THEN
            SELECT psvl.segment_value
            INTO   vv_segment_value
            FROM   pa_segment_value_lookups psvl
            WHERE      psvl.segment_value_lookup_set_id = vn_segment_value_lookup_set_id
                   AND psvl.segment_value_lookup = vv_segment_lookup;
        ELSE
            pn_retcode    := 2;
            pv_errbuf     := 'Erreur rule_type: rule_id = ' || TO_CHAR (pn_rule_id);
            RETURN;
        END IF;

        -- Fin de la determination de la valeur finale

        -- Affectation de la valeur a la variable de sortie
        pv_segment_value    := vv_segment_value;
    EXCEPTION
        WHEN e_error
        THEN
            pn_retcode    := 2;
        WHEN OTHERS
        THEN
            pv_errbuf     := 'Erreur pa_run_accounting_rule : ' || SQLERRM;
            pn_retcode    := SQLCODE;
    END pa_run_accounting_rule;
    
    ---------------------------------------------------------------------------------------------------------------------
--  Nom           : get_centre_finance
--  Description   : Fonction utilisée pour retourner l'appartenance du projet sur une période
--
--  PARAMETRES :
--  pn_project_id       Entrée
--  pd_date             Entrée
--  VALEUR RETOURNEE :
--  Description       : Societé
--  Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_centre_finance (
        fn_project_id   IN   NUMBER,
        fd_date         IN   DATE
    )
        RETURN VARCHAR2
    IS
        vv_appartenance_name VARCHAR2 (30);
    BEGIN
        SELECT haou.NAME
        INTO   vv_appartenance_name
        FROM   pa_cost_dist_overrides pcdo,
               hr_all_organization_units haou
        WHERE  pcdo.project_id = fn_project_id
        AND    fd_date >= pcdo.start_date_active
        AND    fd_date <= NVL (pcdo.end_date_active, fd_date)
        AND    pcdo.override_from_organization_id = haou.organization_id;

        RETURN vv_appartenance_name;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_centre_finance;
	        
---------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_APPART
--  Description   : Fonction utilis¿e pour retourner l'appartenance du projet sur une p¿riode
--
--  PARAMETRES :
--      pn_project_id                   Entrée
--  pd_date             Entrée
--  VALEUR RETOURNEE :
--     Description       : Societé
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
    FUNCTION get_appart (
        fn_project_id   IN   NUMBER,
        fd_date         IN   DATE
    )
        RETURN VARCHAR2
    IS
        vv_appartenance_name   VARCHAR2 (30);
    BEGIN
        SELECT haou.NAME
        INTO   vv_appartenance_name
        FROM   pa_cost_dist_overrides pcdo,
               hr_all_organization_units haou
        WHERE      pcdo.project_id = fn_project_id
               AND fd_date >= pcdo.start_date_active
               AND fd_date <= NVL (pcdo.end_date_active, fd_date)
               AND pcdo.override_from_organization_id = haou.organization_id;

        RETURN vv_appartenance_name;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END get_appart;    
    
---------------------------------------------------------------------------------------------------------------------
--  Nom           : get_class_project
--  Description   : Fonction utilisée pour retourner la valeur de la classe du project du projet sur une p¿riode
--
--  PARAMETRES :
--  fn_project_id                 Entrée
--  fv_class_category             Entrée
--  VALEUR RETOURNEE :
--     Description       : Class Code
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
FUNCTION get_class_project(fn_project_id     IN NUMBER,
                           fv_class_category IN VARCHAR2) RETURN VARCHAR2 IS
  vv_class_code VARCHAR2(30);
BEGIN
  select class_code
    into vv_class_code
    from pa_project_classes
   where project_id = fn_project_id
     and class_category = fv_class_category;

  RETURN vv_class_code;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END get_class_project;

---------------------------------------------------------------------------------------------------------------------
--  Nom           : get_parent_project
--  Description   : Fonction utilisée pour retourner le parent du projet avec sa tâche
--
--  PARAMETRES :
--  fn_task_id                 Entrée
--  VALEUR RETOURNEE :
--     Description       : Code projet
--     Valeurs possibles :
--
---------------------------------------------------------------------------------------------------------------------
FUNCTION get_parent_project(fn_task_id IN NUMBER) RETURN VARCHAR2 IS
  vv_code_project VARCHAR2(30);
BEGIN
  select pp.segment1
    into vv_code_project
    from pa_tasks pt, pa_projects_all pp
   where pt.task_id IN
         (select attribute7 from pa.pa_tasks where task_id = fn_task_id)
     and pt.PROJECT_ID = pp.project_id;

  RETURN vv_code_project;
EXCEPTION
  WHEN OTHERS THEN
    RETURN NULL;
END get_parent_project;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_GET_PROJECT_TASK
--  Description   : Récupération des informations sur la tâche d'un projet
--
--  PARAMETRES    :
--    pv_errbuf       varchar2
--    pn_retcode      number
--    pn_project_id   number
--    pv_segment1     varchar2
--    pn_task_id      number
--    pv_task_number  varchar2
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
PROCEDURE pa_get_project_task (
	pv_errbuf        OUT      VARCHAR2,
	pn_retcode       OUT      NUMBER,
	pn_project_id    IN       NUMBER DEFAULT NULL,
	pv_segment1      IN       VARCHAR2 DEFAULT NULL,
	pn_task_id       OUT      NUMBER,
	pv_task_number   OUT      VARCHAR2
)
IS
	e_error         EXCEPTION;
	vn_project_id   pa_projects_all.project_id%TYPE;
BEGIN
	IF pn_project_id IS NOT NULL
	THEN
		vn_project_id    := pn_project_id;
	ELSIF pv_segment1 IS NOT NULL
	THEN
		SELECT pp.project_id
		INTO   vn_project_id
		FROM   pa_projects/*_all*/ pp
		WHERE  pp.segment1 = pv_segment1;
	ELSE
		pv_errbuf    := 'Parametres insuffisants lors de l''appel a la procédure';
	END IF;

	SELECT pt.task_id,
		   pt.task_number
	INTO   pn_task_id,
		   pv_task_number
	FROM   pa_tasks pt
	WHERE  pt.project_id = vn_project_id;
EXCEPTION
	WHEN e_error
	THEN
		pv_errbuf     := 'PA_GET_PROJECT_TASK - ' || pv_errbuf;
		pn_retcode    := 2;
	WHEN NO_DATA_FOUND
	THEN
		pv_errbuf     := 'PA_GET_PROJECT_TASK - Le projet (id=' || TO_CHAR (vn_project_id) || ') ne comporte aucun tâche';
		pn_retcode    := 2;
	WHEN TOO_MANY_ROWS
	THEN
		pv_errbuf     := 'PA_GET_PROJECT_TASK - Le projet (id=' || TO_CHAR (vn_project_id) || ') comporte plusieurs tâches';
		pn_retcode    := 2;
	WHEN OTHERS
	THEN
		pv_errbuf     := SQLERRM;
		pn_retcode    := SQLCODE;
END pa_get_project_task;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PA_GET_PERIOD
--  Description   : Récupération des informations sur la période PA d'un événement
--
--  PARAMETRES    :
--    pv_errbuf       varchar2
--    pn_retcode      number
--    pn_project_id   number
--    pv_segment1     varchar2
--    pn_task_id      number
--    pv_task_number  varchar2
--  VALEUR RETOURNEE :
--     Description       :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
-------------------------------------------------------------------------------------------------------------------
PROCEDURE pa_get_period(pv_errbuf      OUT VARCHAR2,
                        pn_retcode     OUT NUMBER,
                        pd_event_date  IN DATE DEFAULT NULL,
                        pd_gl_date     IN DATE DEFAULT NULL,
                        pn_org_id      IN NUMBER DEFAULT NULL,
                        pd_start_date  OUT DATE,
                        pd_end_date    OUT DATE,
                        pd_pa_date     OUT DATE,
                        pv_period_name OUT VARCHAR2) IS
  ld_start_date  DATE;
  ld_end_date    DATE;
  ld_pa_date     DATE;
  lv_period_name DATE;
BEGIN

  BEGIN
    SELECT pap.start_date, pap.end_date, pap.end_date, pap.period_name
      INTO ld_start_date, ld_end_date, ld_pa_date, lv_period_name
      FROM pa_periods_all pap
     WHERE status IN ('O', 'F')
       AND pap.end_date >= trunc(pd_event_date)
       AND pd_gl_date BETWEEN pap.start_date AND pap.end_date
       AND org_id = pn_org_id;
  
  EXCEPTION
    WHEN no_data_found THEN
      ld_pa_date     := NULL;
      lv_period_name := NULL;
  END;

  IF (ld_pa_date IS NULL) THEN
    SELECT pap1.start_date, pap1.end_date, pap1.end_date, pap1.period_name
      INTO ld_start_date, ld_end_date, ld_pa_date, lv_period_name
      FROM pa_periods_all pap1
     WHERE pap1.end_date = (SELECT MIN(pap.end_date)
                              FROM pa_periods_all pap
                             WHERE pap.status IN ('O', 'F')
                               AND pap.end_date >= trunc(pd_event_date)
                               AND pap.org_id = pn_org_id)
       AND pap1.org_id = pn_org_id;
  END IF;
  
  pd_start_date := ld_start_date;
  pd_end_date := ld_end_date;
  pd_pa_date := ld_pa_date;
  pv_period_name :=  lv_period_name;

EXCEPTION
  WHEN no_data_found THEN
    pv_errbuf  := 'PA_GET_PERIOD - Aucune période n''est ouverte pour la date :' || pd_event_date;
    pn_retcode := 2;
  WHEN OTHERS THEN
    pv_errbuf  := SQLERRM;
    pn_retcode := SQLCODE;
END pa_get_period;

END DKA_PA_TOOLS_PKG; -- Spécification du package
/
SHOW ERRORS
EXIT;
