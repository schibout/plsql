CREATE OR REPLACE PACKAGE BODY Dka_Spacutoffgl_Pkg
AS
----------------------------------------------------------------------------------------------
-- NOM               : DKA_SPACUTOFFGL_PKG.pkb
-- DESCRIPTION       : DKA_SPACUTOFFGL_PKG package body : spécifique CUTOFF GL/PA
---
--- AUTEUR           : K.Helali
--- DATE DE CREATION : 30/10/2001
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  04/03/2002 KH  Appel à DKA_TOOLS_PKG.get_code_combination_id au lieu de FND_FLEX_EXT.get_ccid
--                 Suppression de la clause "For Update" du package
--  16/05/2002 GLN Ajout d'un contexte supplémentaire (codes inter-bancaire)
--  24/07/2002 XD  Correction du format de nombre pour gl_je_lines.attribute14
--                 Ajout de NVL sur gl_je_lines.accounted_cr et gl_je_lines.accounted_dr
--  09/09/2002 XD  Utilisation de LAST_DAY pour le calcul de la date GL
--  17/10/2002 XD  transfer_from_gl_to_pa : Correction pour le signe de la quantité
--- 11/08/2003 XD  get_calc_segment2_f : modification du calcul pour les comptes 'R'
---                get_calc_segment3_f : modification du calcul pour les comptes 'R'
---                Mise en forme du script
---                controler_line_gl : Ajout de contrôles de cohérence des données
---                gv_errbuf : passage de 255 à 500 caractères
--- 21/11/2003 XD  get_calc_segment2_f : modification du calcul pour les comptes 'R'
---                get_calc_segment3_f : modification du calcul pour les comptes 'R'
---                get_contrep_ccid_f : ne plus utiliser dka_tools_pkg car la clé est invalide
--- 02/12/2003 XD  get_contrep_ccid_f : mise à jour du champ preserve_flag
--- 05/12/2003 XD  Report suite régression :
---                 get_calc_segment2_f : Dans l'exception, suppression du RAISE pour rendre la main
---                                       à la procédure appelante
--- 04/02/2003 AD  transfer_from_gl_to_pa: Correction du format de nombre pour gl_je_lines.attribute14
---                Selection en type CHAR puis test lors de la conversion en NUMBER
---                Ajout de l'exception INVALID_NUMBER pour traiter l'anomalie dans le fichier
---                .out.
--- 11/02/2004 XD  controler_line_gl : modification de l'appel à dka_tools_pkg.pa_check_transaction_data si le type de pièce
---                                    est à contrepassation automatique
--- 29/03/2004 AD  transfer_from_gl_to_pa : Réference_1 (gl_je lines)ne contient que désormais le ccid + gl_date
---                La capacité du champs reference_6 ayant dépassé les 30 caractères.
--- 22/10/2004 STI portage specifique PHENIX 2004
---			   	   modification des fonctions get_calc_segment1_f, get_calc_segment2_f, get_calc_segment4_f
--- 			   get_calc_segment5_f, get_calc_segment6_f, get_calc_segment7_f, get_calc_segment8_f
---				   ajout des fonctions get_calc_segment9_f et get_calc_segment10_f
---				   procedure get_contrep_ccid_f : ajout d'un argument pv_segment2
---				   procedure transfer_from_gl_to_pa : modification de l'appel à get_contrep_ccid_f
---				   procedure controler_line_gl ; ajout des segments 9 et 10 + vv_segment1_acct_area + vv_segment1_company_code
--- 11/02/2005 CDE Report de maintenance PHENIX 2005
---			   	   - 19/11/2004 GV  transfer_from_gl_to_pa : ajout de la notion de periode dans le curseur cur_gl_je_lines
---                                                       pour réduire le temps de traitement
--- 21/12/2004 GV  get_context_cuf : ajout du contexte FRAIS pour les compte se trouvant dans le jeu
---                                                de valeurs DKA_CPT_FRAIS_BANC
--- 30/05/2005 TB  Suppression de l'exclusion des projets de type "APPARTENANCE"
--- 25/08/2005 TB  get_contrep_ccid_f : Ajout d'un test sur l'activation d'un ccid dans le cas de doublon (idem que DKA_SARFACMAN)
--- 15/09/2005 GV  controler_line_gl : Ajout du contexte FRAIS
--- 03/10/2005 TB  transfer_from_gl_to_pa : Exclusion des lignes d'un montant nul.
--- 07/04/2005 TB  transfer_from_gl_to_pa : Ajout d'une condition sur la nature du compte local des lignes à traiter
---                get_account_info : Modification de la valeur retournée pour l'attribute2 (cf. NOT20060028)
--- 13/09/2006 TB  controler_line_gl : Ajout du contrôle des informations du CUF pour le calcul des marges amont
--- 06/12/2006 TB  controler_line_gl : Modification du type de variable pour code_d_n à cause des clients gerrico
---                                    enregistrés dans le meme attribute
--- 26/06/2007 TB  get_calc_segment4_f et controler_ligne_gl : correction du message de retour en cas d'erreur sur le calcul su segment4
--                 get_calc_segment3_f : rajout du compte local attendu dans le message d'erreur
--- 23/03/2009 TB  get_dr_code_combinaison_id : correction gestion des doublons de ccid 
--- 02/07/2013 BCO INC000000425356 - transfer_from_gl_to_pa : modification de la log de sortie de la procédure.
--- 18/12/2013 TB  INC000000490825 - transfer_from_gl_to_pa : Ne traite que les périodes GL ouvertes
--- 08/09/2016 OBE Migration R12
--- 19/10/2016 OBE Correction cas de REFAC -artf2031532- / Alimentation tâche à refacturer sur attribute7 au lieu de attribute2 -artf2031110- 
--- 03/11/2016 OBE Correction artf2033968 et artf2033949 
--- 21/11/2016 OBE Correction artf2047443
--- 28/11/2016 OBE Correction artf2052379
--- 01/12/2016 RBE Correction artf2055421
--- 07/12/2016 OBE Correction artf2057218
--- 05/01/2016 MEG Correction : artf2077423, artf2077049 et artf2077040
--- 12/01/2016 MEG Modification : EDB Evolution pour passage d’une immos en cours sur un projet non invest sur un projet d’invest
--- 23/01/2017 MEG Modification : EDB Evolution sur le matricule
--- 16/02/2017 MEG Modification : artf2101504 : SPE048 - Mauvaise date des dépenses
--- 30/05/2017 YWA artf2162994 : SPE048 - Invalid number - Defect Bout_en_Bout_Helios_Ref #715
--- 12/07/2017 MEG artf2194372 : SPE048 - defect ORACLE_R12 #706 GL/PA Problème de sélection des périodes à traiter
--- 12/09/2017 OBE artf2221505 : SPE048 - GL Ouverture CUF Matricule seulement pour les valeurs actives - defect ORACLE_R12 #920
--- 26/02/2018 MEG artf2399742 : SPE048 - Arrondir la quantité à 5 décimales au lieu de rejeter la ligne
--- 11/10/2018 MEN artf3038502 : INC0254865 : Correctif sur saisie manuelle TEC et PCA sur mouvement Evt Type Malus
--- 16/04/2020 SELO EDB259
--- 04/05/2023 ARA Migration ExaCC
--- 02/11/2023 ARA EDB281 - DGE20210006 - Alimentation du segment5 de la clé comptable
--------------------------------------------------------------------------------------------
    
    ----- Déclaration des constantes globales du package -----
    cv_delim_cuf            CONSTANT VARCHAR2 (1)                                     := '#';
    ----- Déclaration des variables globales du package -----
    gv_currency_code                 VARCHAR2 (3);
    gv_expend_group_status_code      VARCHAR2 (50);
    gv_system_linkage_function       VARCHAR2 (30);
    gv_transaction_source            VARCHAR2 (30);
    gv_expenditure_status_code       VARCHAR2 (30);
    gv_expenditure_class_code        VARCHAR2 (30);
    gv_gl_attribute_category         VARCHAR2 (30)                                    := 'GL';
    gv_gl_refac_attribute_category   VARCHAR2 (30)                                    := 'GL_REFAC';
    gv_line_type                     pa_cost_distribution_lines_all.line_type%TYPE    := 'R';
    gv_default_task_number           pa_tasks.task_number%TYPE                        := '1';
    gv_spacutoff_prefixe             VARCHAR2 (30)                                    := 'DKA_SPACUTOFF_';
    gv_gl_reference_revenue          VARCHAR2 (30)                                    := 'Revenue - Event Revenue';
    gv_gl_reference_cost             VARCHAR2 (30)                                    := 'Cost';
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
    --- Declaration
    gn_set_of_books_id               gl_sets_of_books.set_of_books_id%TYPE;
    gn_ledger_id                     gl_ledgers.ledger_id%TYPE;                   -- OBE
    gn_sob_chart_of_accounts_id      gl_sets_of_books.chart_of_accounts_id%TYPE;
    gn_seg3_flex_value_set_id        fnd_flex_value_sets.flex_value_set_id%TYPE;
    gv_seg3_flex_value_set_name      fnd_flex_value_sets.flex_value_set_name%TYPE;
    gv_project_type_refac            pa_project_types_all.project_type%TYPE;
    -- Variables pour optimiser la recherche dans la proc get_context_cuf
    gv_user_je_category_name         gl_je_categories.user_je_category_name%TYPE;
    gv_account                       gl_code_combinations.segment1%TYPE;
    gv_context_cuf_gljl              gl_je_lines.context3%TYPE;
    gv_project_type_invest          pa_project_types_all.project_type%TYPE;
    
--**************************************************************************************
--  FONCTIONS ET PROCEDURES PRIVEES
--**************************************************************************************
-----------------------------------------------------------------
-- NOM         : put_line_log
-- DESCRIPTION : Ecrit une ligne dans le fichier log du traitement
-----------------------------------------------------------------
    PROCEDURE put_line_log (
        pv_buffer   IN   VARCHAR2
    )
    IS
    BEGIN
        Fnd_File.put_line (Fnd_File.LOG, pv_buffer);
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;   -- on ne fait rien
    END put_line_log;
-----------------------------------------------------------------
-- NOM         : put_line_out
-- DESCRIPTION : Ecrit une ligne dans le fichier out du traitement
-----------------------------------------------------------------
    PROCEDURE put_line_out (
        pv_buffer   IN   VARCHAR2
    )
    IS
    BEGIN
        Fnd_File.put_line (Fnd_File.output, pv_buffer);
    EXCEPTION
        WHEN OTHERS
        THEN
            NULL;   -- on ne fait rien
    END put_line_out;
-----------------------------------------------------------------
-- NOM         : get_param_varchar
-- DESCRIPTION : Recupere la valeur d'un parametre DKA de type VARCHAR
-----------------------------------------------------------------
    FUNCTION get_param_varchar (
        pv_parameter   IN   VARCHAR2,
        pv_prog_code   IN   VARCHAR2 DEFAULT 'SPACUTOFF'
    )
        RETURN VARCHAR2
    IS
        rec_param   dka_parameters%ROWTYPE;
    BEGIN
        Dka_Tools_Pkg.get_parameter (pv_prog_code, pv_parameter, rec_param, gn_retcode, gv_errbuf);
        IF gn_retcode != 0
        THEN
            gv_errbuf    := 'DKA_SPACUTOFFGL_PKG.get_param_varchar' || '-' || pv_prog_code || '-' || pv_parameter || '-'
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
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_param_varchar:' || SQLERRM;
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
        -- On recherche le set of books id
        /*
        IF gn_ledger_id IS NULL AND pv_prog != 'TRANSFER'
        THEN
            --gn_set_of_books_id    := TO_NUMBER (Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID')); -- OBE
            gn_ledger_id := TO_NUMBER(gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R')); -- OBE
            SELECT sob.chart_of_accounts_id
            INTO   gn_sob_chart_of_accounts_id
            FROM   gl_ledgers sob --gl_sets_of_books sob       -- OBE
            WHERE  --sob.set_of_books_id = gn_set_of_books_id; -- OBE
                   sob.ledger_id = gn_ledger_id;               -- OBE
        END IF;
        */
        -- On recherche l'id et le nom du jeu de valeur du segment "compte local" de la clé GL
        IF gn_seg3_flex_value_set_id IS NULL
        THEN
            Dka_Tools_Pkg.get_flex_key_seg_value_set
                                            (
                pv_errbuf                    => gv_errbuf,
                pn_retcode                   => gn_retcode,
                pv_legal_flex_key_flag       => 'N',   -- on considère la ccf des organisations opérationnelles
                pn_segment_num               => 3,
                pn_flex_value_set_id         => gn_seg3_flex_value_set_id,
                pv_flex_value_set_name       => gv_seg3_flex_value_set_name
            );
            IF gn_retcode != 0
            THEN
                RAISE e_trt;
            END IF;
        END IF;
        put_line_log ('Récupération projet type REFAC');
        IF gv_project_type_refac IS NULL
        THEN
            Dka_Tools_Pkg.get_parameter (
                pv_program_code         => 'TOOLS',
                pv_parameter_name       => 'PROJECT_TYPE_REFAC',
                pr_data                 => rec_param,
                pn_retcode              => gn_retcode,
                pv_err_msg              => gv_errbuf
            );
            IF gn_retcode != 0
            THEN
                RAISE e_trt;
            ELSE
                gv_project_type_refac    := rec_param.varchar2_value;
            END IF;
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
        
        IF pv_prog = 'TRANSFER'
        THEN
            gv_currency_code               := get_param_varchar (pv_parameter => 'CURRENCY_CODE');
            gv_transaction_source          := get_param_varchar (pv_parameter => 'TRANSACTION_SOURCE');
            gv_expenditure_status_code     := get_param_varchar (pv_parameter => 'EXPENDITURE_STATUS_CODE');
            gv_expend_group_status_code    := get_param_varchar (pv_parameter => 'EXPENDITURE_GROUP_STATUS_CODE');
            gv_system_linkage_function     := get_param_varchar (pv_parameter => 'SYSTEM_LINKAGE_FUNCTION');
            gv_expenditure_class_code      := get_param_varchar (pv_parameter => 'EXPENDITURE_CLASS_CODE');
        END IF; -- pv_prog = 'TRANSFER'

        -- Recuperation de la variable concernant le type de projet Investissement dans la table DKA_PARAMETERS
        put_line_log ('Récupération projet type Investissement');
        IF gv_project_type_invest IS NULL
        THEN
            Dka_Tools_Pkg.get_parameter (
                pv_program_code         => 'SPAAUTOACCOUNTING',
                pv_parameter_name       => 'PROJECT_TYPE_INVEST',
                pr_data                 => rec_param,
                pn_retcode              => gn_retcode,
                pv_err_msg              => gv_errbuf
            );
            IF gn_retcode != 0
            THEN
                RAISE e_trt;
            ELSE
                gv_project_type_invest    := rec_param.varchar2_value;
            END IF;
        END IF;
        
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.Init:' || SQLERRM;
            RAISE e_trt;
    END init;
----------------------------------------------------------------------------------------
--  Fonction      : get_account_info
--  Description   : recherche des infos du du compte local (segment3) passé en paramètre
----------------------------------------------------------------------------------------
    PROCEDURE get_account_info (
        pv_segment3               IN       VARCHAR2,
        pv_account_type           OUT      VARCHAR2,
        pv_flag_compte_prov_cli   OUT      VARCHAR2,
        pv_flag_tec_pca_cca       OUT      VARCHAR2,
        pv_flag_compte_chg_immo   OUT      VARCHAR2,
        pv_flag_matricule         OUT      VARCHAR2
    )
    IS
    BEGIN
        SELECT SUBSTR (ffv.compiled_value_attributes, INSTR (ffv.compiled_value_attributes, CHR (10), 3, 1) + 1, 1),
               DECODE (ffv.attribute2,'Y',ffv.attribute2, 'X'), -- Modif TB 20060407 : Modification de la valeur retournée pour l'attribute2
               NVL (ffv.attribute3, 'N')
        INTO   pv_account_type,
               pv_flag_compte_prov_cli,
               pv_flag_tec_pca_cca
        FROM   fnd_flex_values_vl ffv
        WHERE  ffv.flex_value = pv_segment3
           AND ffv.flex_value_set_id = gn_seg3_flex_value_set_id;
        
        -- Controle que le compte local est compte de charge d'immo      
        SELECT DECODE(COUNT(1), 0, 'N', 'Y')
          INTO pv_flag_compte_chg_immo
          FROM fa_categories_vl fcv, 
               fa_category_books fcb
         WHERE EXISTS (SELECT 1
                         FROM fa_book_controls_sec bc
                        WHERE nvl(date_ineffective, sysdate + 1) > sysdate
                          AND bc.book_type_code = fcb.book_type_code)
           AND fcv.category_id = fcb.category_id
           AND NVL(fcv.enabled_flag, 'N') = 'Y'
           AND fcb.asset_clearing_acct = pv_segment3;

        -- si compte de charge d'immo alors on le traite comme un compte de charge
        IF pv_flag_compte_chg_immo = 'Y' THEN
            pv_account_type    := 'E';
        END IF;
        
        -- Controle que le compte local est inclus dans le jdv DKA_COMPTE_MATRICULE
        SELECT DECODE(COUNT(1), 0, 'N', 'Y')
          INTO pv_flag_matricule
          FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
         WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
           AND ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
           AND ffv.flex_value = pv_segment3
           AND ffv.enabled_flag = 'Y'; -- OBE artf2221505
   
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E008',
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
--  Fonction      : get_je_category_info
--  Description   : recherche des infos du type de pièce passé en paramètre
----------------------------------------------------------------------------------------
    PROCEDURE get_je_category_info (
        pv_user_je_category_name   IN       VARCHAR2,
        pv_flag_cuf_actif          OUT      VARCHAR2
    )
    IS
    BEGIN
        SELECT NVL (gjc.attribute1, 'N')
        INTO   pv_flag_cuf_actif
        FROM   gl_je_categories gjc
        WHERE  gjc.user_je_category_name = pv_user_je_category_name;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_je_category_info:' || SQLERRM;
            RAISE e_trt;
    END get_je_category_info;
--------------------------------------------------------------------------------------
--  Nom           : get_project_info
--  Description   : Vérifie l'existence et recherche des infos du projet
----------------------------------------------------------------------------------------
    PROCEDURE get_project_info (
        pn_project_id      IN       NUMBER,
        pd_ref_date        IN       DATE,
        pv_project_code    OUT      VARCHAR2,
        pv_project_type    OUT      VARCHAR2,
        pv_proj_org_id     OUT      VARCHAR2,
        pv_proj_org_name   OUT      VARCHAR2
    )
    IS
    BEGIN
        -- PHENIX 2004
        SELECT pap.segment1,
               pap.project_type,
               haou.organization_id,
               SUBSTR(haou.NAME,4)                                       -- OBE
        INTO   pv_project_code,
               pv_project_type,
               pv_proj_org_id,
               pv_proj_org_name
        FROM   pa_projects_all pap,
               --pa_project_classes ppc,                                 -- OBE
               hr_all_organization_units haou
        WHERE  pap.project_id = pn_project_id
        --AND    pap.PROJECT_ID = ppc.PROJECT_ID                         -- OBE
        --AND    ppc.class_category = 'SOCIETE'                          -- OBE
        --AND    pap.carrying_out_organization_id = haou.organization_id -- OBE
        AND    pap.org_id = haou.organization_id                         -- OBE
        AND    pd_ref_date BETWEEN pap.start_date AND NVL (pap.completion_date, pd_ref_date);
        --AND    haou.name = ppc.class_code;                             -- OBE
        -- FIN PHENIX 2004
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E004',
                                pv_token1            => 'PROJET',
                                pv_value1            => pv_project_code
                            );
            RAISE e_trt;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_project_info:' || SQLERRM;
            RAISE e_trt;
    END get_project_info;
----------------------------------------------------------------------------------------
--  Nom           :  get_expenditure_type_info
--  Description   :  verification du type de dépense et retour de l'unité de mesure de la dépense
----------------------------------------------------------------------------------------
    PROCEDURE get_expenditure_type_info (
        pv_expenditure_type   IN       VARCHAR2,
        pd_ref_date           IN       DATE,
        pv_unit_of_measure    OUT      VARCHAR2
    )
    IS
    BEGIN
        SELECT pet.unit_of_measure
        INTO   pv_unit_of_measure
        FROM   pa_expenditure_types pet
        WHERE      pet.expenditure_type = pv_expenditure_type
               AND pd_ref_date BETWEEN pet.start_date_active AND NVL (pet.end_date_active, pd_ref_date);
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E005',
                                pv_token1            => 'TYPE_DEPENSE',
                                pv_value1            => pv_expenditure_type
                            );
            RAISE e_trt;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_expenditure_type_info:' || SQLERRM;
            RAISE e_trt;
    END get_expenditure_type_info;
----------------------------------------------------------------------------------------
--  Nom           :  check_exist_event_type
--  Description   :  verification que l'évenement produit existe
----------------------------------------------------------------------------------------
    PROCEDURE check_exist_event_type (
        pv_event_type   IN   VARCHAR2,
        pd_ref_date     IN   DATE
    )
    IS
        vv_dummy   CHAR (1);
    BEGIN
        SELECT '1'
        INTO   vv_dummy
        FROM   pa_event_types pet
        WHERE      pet.event_type = pv_event_type
               AND pd_ref_date BETWEEN pet.start_date_active AND NVL (pet.end_date_active, pd_ref_date);
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E007',
                                pv_token1            => 'EVENT_PRODUIT',
                                pv_value1            => pv_event_type
                            );
            RAISE e_trt;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.check_exist_event_type:' || SQLERRM;
            RAISE e_trt;
    END check_exist_event_type;
--< OBE
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment1_f
--  Description   :  Calcul et renvoie le segment1 de la clé (Société) -- PHENIX 2004
----------------------------------------------------------------------------------------
/*
    FUNCTION get_calc_segment1_f (
        pn_project_id   IN   NUMBER,
        pd_ref_date     IN   DATE
    )
        RETURN VARCHAR2
    IS
        vv_segment   gl_code_combinations.segment1%TYPE;
    BEGIN
        DBMS_OUTPUT.put ('pn_project_id');
        DBMS_OUTPUT.put_line (pn_project_id);
        DBMS_OUTPUT.put ('pd_ref_date');
        DBMS_OUTPUT.put_line (pd_ref_date);
       
        vv_segment    := Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f (pn_project_id => pn_project_id, pv_return_type => '0',
                            pd_ref_date          => pd_ref_date);
                     
		vv_segment    := SUBSTR(vv_segment, 4); -- PHENIX 2004
        RETURN vv_segment;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment1_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment1_f;
 */
 
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment1_f
--  Description   :  Calcul et renvoie le segment10 de la clé (Segment libre)
-- PHENIX 2004    :
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment1_f (
        pv_segment1_orig   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
    BEGIN
        -- Segment 1 inchangé !!
        RETURN pv_segment1_orig;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment1_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment1_f;
--> OBE
    
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment2_f
--  Description   :  Calcul et renvoie le segment2 de la clé (Centre de Gestion )
-- PHENIX 2004 même methode que get_calc_segment1_f sauf qu'on prend les 3 premiers caracteres
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment2_f (
        pn_project_id   IN   NUMBER,
        pd_ref_date     IN   DATE 
    )
        RETURN VARCHAR2
    IS
        vv_segment   gl_code_combinations.segment1%TYPE;
    BEGIN
        DBMS_OUTPUT.put ('pn_project_id');
        DBMS_OUTPUT.put_line (pn_project_id);
        
        --< OBE
        /*
        DBMS_OUTPUT.put ('pd_ref_date');
        DBMS_OUTPUT.put_line (pd_ref_date);
        
        vv_segment    := Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f (pn_project_id => pn_project_id, pv_return_type => '0',
                            pd_ref_date          => pd_ref_date);
        vv_segment    := SUBSTR(vv_segment, 1,3); --PHENIX 2004
        */
        vv_segment    := dka_spaautoaccounting_pkg.uo_projet(pn_project_id => pn_project_id);
        --> OBE
        
        RETURN vv_segment;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment2_f:' || SQLERRM; --PHENIX 2004
            RAISE e_trt;
    END get_calc_segment2_f; -- PHENIX 2004
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment3_f
--  Description   :  Calcul et renvoie le segment3 de la clé (Compte Local)
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment3_f (
        pv_segment3_orig        IN   VARCHAR2,
        pv_account_type         IN   VARCHAR2,
        pv_flag_tec_pca_cca     IN   VARCHAR2,
        pv_amount_type          IN   VARCHAR2,
        pv_expenditure_type     IN   VARCHAR2,
        pv_event_type           IN   VARCHAR2,
        pn_project_id           IN   NUMBER,  -- OBE
        pn_task_id              IN   NUMBER,   -- OBE
        pv_flag_compte_chg_immo IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_segment   gl_code_combinations.segment1%TYPE;
    BEGIN
        -- Compte de charge
        IF pv_account_type = 'E' OR pv_flag_compte_chg_immo = 'Y'
        THEN
            --< OBE
            /*
            Dka_Pa_Tools_Pkg.pa_run_accounting_rule (
                pv_rule_name              => 'CPT_LOCAL_COUTS',
                pv_expenditure_type       => pv_expenditure_type,
                pv_segment_value          => vv_segment,
                pv_errbuf                 => gv_errbuf,
                pn_retcode                => gn_retcode
            );*/
            
            vv_segment := dka_spaautoaccounting_pkg.CPT_LOCAL_COUTS(
                        pn_project_id       => pn_project_id,
                        pv_expenditure_type => pv_expenditure_type,
                        pn_task_id          => pn_task_id
            );
           --> OBE 
            
        -- Compte de produit différent de TEC , PCA ou CCA
        -- ou Compte de produit avec montant saisi au crédit
        --ELSIF      pv_account_type = 'R'
        --       AND (   pv_flag_tec_pca_cca = 'N'
        --            OR pv_amount_type = 'C'
        --           )
        --THEN
        --    dka_pa_tools_pkg.pa_run_accounting_rule (
        --        pv_rule_name                   => 'CPT_LOCAL_PRODUIT',
        --        pv_event_type                  => pv_event_type,
        --        pv_segment_value               => vv_segment,
        --        pv_errbuf                      => gv_errbuf,
        --        pn_retcode                     => gn_retcode
        --    );
        ---- Compte de produit "TEC , PCA ou CCA" avec montant saisi au débit
        --ELSE
        --    dka_pa_tools_pkg.pa_run_accounting_rule (
        --        pv_rule_name                   => 'CPT_LOCAL_CONTREP_PRODUIT',
        --        pv_event_type                  => pv_event_type,
        --        pv_segment_value               => vv_segment,
        --        pv_errbuf                      => gv_errbuf,
        --        pn_retcode                     => gn_retcode
        --    );
        ELSIF pv_account_type = 'R'
        THEN
            --DECLARE
            --    vv_event_type_class   pa_event_types.event_type_classification%TYPE;
            --BEGIN
            --    SELECT pet.event_type_classification
            --    INTO   vv_event_type_class
            --    FROM   pa_event_types pet
            --    WHERE  pet.event_type = pv_event_type;
            --
            --    IF vv_event_type_class = 'WRITE OFF'
            --    THEN
            --        /***** Evenement de type MALUS *****/
            --        dka_pa_tools_pkg.pa_run_accounting_rule (
            --            pv_rule_name           => 'CPT_LOCAL_CONTREP_PRODUIT',
            --            pv_event_type          => pv_event_type,
            --            pv_segment_value       => vv_segment,
            --            pv_errbuf              => gv_errbuf,
            --            pn_retcode             => gn_retcode
            --        );
            --    ELSE
            --        /***** Evenement de type BONUS *****/
            --        dka_pa_tools_pkg.pa_run_accounting_rule (
            --            pv_rule_name           => 'CPT_LOCAL_PRODUIT',
            --            pv_event_type          => pv_event_type,
            --            pv_segment_value       => vv_segment,
            --            pv_errbuf              => gv_errbuf,
            --            pn_retcode             => gn_retcode
            --        );
            --    END IF;
            --END;
            
            Dka_Pa_Tools_Pkg.pa_run_accounting_rule (
                pv_rule_name           => 'CPT_LOCAL_PRODUIT',
                pv_event_type          => pv_event_type,
                pv_segment_value       => vv_segment,
                pv_errbuf              => gv_errbuf,
                pn_retcode             => gn_retcode
            );
            
            IF (gn_retcode != 0)
            THEN
                gv_errbuf    := 'DKA_SPACUTOFFGL_PKG.get_calc_segment3_f:' || gv_errbuf;
                RAISE e_trt;
            END IF;
        END IF;
        IF gn_retcode != 0
        THEN
            gv_errbuf    := 'DKA_SPACUTOFFGL_PKG.get_calc_segment3_f:' || gv_errbuf;
            RAISE e_trt;
        END IF;
        IF vv_segment != pv_segment3_orig
        THEN
            gn_retcode    := 2;
            IF pv_account_type = 'E' OR pv_flag_compte_chg_immo = 'Y'
            THEN
                gv_errbuf    := Dka_Tools_Pkg.GET_MESSAGE (
                                   pv_application       => 'DKA',
                                   pv_name              => 'DKA_SAPCUTOFFGL_E103',
                                   pv_token1            => 'TYPE_DEPENSE',
                                   pv_value1            => pv_expenditure_type || ' (' || vv_segment || ') ',
                                   pv_token2            => 'COMPTE_LOCAL',
                                   pv_value2            => pv_segment3_orig
                               );
            ELSE
                gv_errbuf    := Dka_Tools_Pkg.GET_MESSAGE (
                                   pv_application       => 'DKA',
                                   pv_name              => 'DKA_SAPCUTOFFGL_E104',
                                   pv_token1            => 'EVENT_PRODUIT',
                                   pv_value1            => pv_event_type || ' (' || vv_segment || ') ',
                                   pv_token2            => 'COMPTE_LOCAL',
                                   pv_value2            => pv_segment3_orig
                               );
            END IF;
            RAISE e_trt;
        END IF;
        RETURN vv_segment;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment3_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment3_f;
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment4_f
--  Description   :  Calcul et renvoie le segment4 de la clé (Compte Groupe)
--  PHENIX 2004   :	 cette fonction est l'ancienne get_calc_segment2_f
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment4_f (
        pn_project_id           IN   NUMBER,
        pn_project_id_refac     IN   NUMBER,
        pv_account_type         IN   VARCHAR2,
        pv_flag_tec_pca_cca     IN   VARCHAR2,
        pv_amount_type          IN   VARCHAR2,
        pv_expenditure_type     IN   VARCHAR2,
        pv_event_type           IN   VARCHAR2,
        pd_ref_date             IN   DATE,
        pn_task_id              IN   NUMBER,
        pv_flag_compte_chg_immo IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_segment   gl_code_combinations.segment1%TYPE;
    BEGIN
        -- Compte de charge
        IF pv_account_type = 'E' OR pv_flag_compte_chg_immo = 'Y'
        THEN
            vv_segment    := Dka_Spaautoaccounting_Pkg.run_cpt_groupe_couts_f (
                                pn_project_id             => pn_project_id,
                                pv_expenditure_type       => pv_expenditure_type,
                                --pd_date                   => pd_ref_date,         -- OBE
                                pn_task_id                => pn_task_id,            -- OBE
                                pn_refac_project_id       => pn_project_id_refac
                            );
        -- Compte de produit différent de TEC , PCA ou CCA
        -- ou Compte de produit avec montant saisi au crédit
            --ELSIF      pv_account_type = 'R'
            --       AND (   pv_flag_tec_pca_cca = 'N'
            --            OR pv_amount_type = 'C'
            --           )
            --THEN
            --    vv_segment    := dka_spaautoaccounting_pkg.run_cpt_groupe_produit_f (
            --                         pn_project_id                  => pn_project_id,
            --                         pv_event_type                  => pv_event_type,
            --                         pd_date                        => pd_ref_date
            --                     );
            ---- Compte de produit "TEC , PCA ou CCA" avec montant saisi au débit
            --ELSE
            --    dka_pa_tools_pkg.pa_run_accounting_rule (
            --        pv_rule_name                   => 'CPT_GROUPE_CONTREP_PRODUIT',
            --        pv_event_type                  => pv_event_type,
            --        pv_segment_value               => vv_segment,
            --        pv_errbuf                      => gv_errbuf,
            --        pn_retcode                     => gn_retcode
            --    );
            --
            --    IF gn_retcode != 0
            --    THEN
            --        gv_errbuf    := 'DKA_SPACUTOFFGL_PKG.get_calc_segment2_f:' || gv_errbuf;
            --        RAISE e_trt;
            --    END IF;
        ELSIF pv_account_type = 'R'
        THEN
            DECLARE
                vv_event_type_class   pa_event_types.event_type_classification%TYPE;
            BEGIN
                --SELECT pet.event_type_classification
                --INTO   vv_event_type_class
                --FROM   pa_event_types pet
                --WHERE  pet.event_type = pv_event_type;
                --
                --IF vv_event_type_class = 'WRITE OFF'
                --THEN
                --    /***** Evenement de type MALUS *****/
                --    dka_pa_tools_pkg.pa_run_accounting_rule (
                --        pv_rule_name           => 'CPT_GROUPE_CONTREP_PRODUIT',
                --        pv_event_type          => pv_event_type,
                --        pv_segment_value       => vv_segment,
                --        pv_errbuf              => gv_errbuf,
                --        pn_retcode             => gn_retcode
                --    );
                --
                --    IF (gn_retcode != 0)
                --    THEN
                --        gv_errbuf    := 'DKA_SPACUTOFFGL_PKG.get_calc_segment2_f:' || gv_errbuf;
                --        RAISE e_trt;
                --    END IF;
                --ELSE
                --    /***** Evenement de type BONUS *****/
                --    vv_segment    := dka_spaautoaccounting_pkg.run_cpt_groupe_produit_f (pn_project_id => pn_project_id,
                --                        pv_event_type       => pv_event_type, pd_date => pd_ref_date);
                --
                --    IF (vv_segment IS NULL)
                --    THEN
                --        gn_retcode    := 1;
                --        gv_errbuf     :=    'Aucun compte groupe ne correspond au projet : '
                --                         || pn_project_id
                --                         || ' et au type d-event: '
                --                         || pv_event_type;
                --        RAISE e_trt;
                --    END IF;
                --END IF;
                vv_segment    := Dka_Spaautoaccounting_Pkg.run_cpt_groupe_produit_f (
                                     pn_project_id   => pn_project_id,
                                     pv_event_type   => pv_event_type,
                                     --pd_date         => pd_ref_date   -- OBE
                                     pn_task_id      => pn_task_id      -- OBE 
                                     );
            END;
        END IF;
-- Début Modif TB 26/06/2007
        IF (vv_segment IS NULL)
        THEN
            gn_retcode    := 2;
            IF pv_account_type = 'E' OR pv_flag_compte_chg_immo = 'Y'
            THEN
                gv_errbuf     :=    'Le type de dépense '
                              || pv_expenditure_type
                              || ' n''est pas compatible avec ce type de projet.';
            ELSE
                gv_errbuf     :=    'Le type d''évenement '
                              || pv_event_type
                              || ' n''est pas compatible avec ce type de projet.';
            END IF;                    
                    
        RAISE e_trt;
        END IF;
-- Fin modif TB 26/06/2007
        RETURN vv_segment;
    EXCEPTION
        WHEN e_trt
        THEN
            --RAISE;
            RETURN NULL; -- Modif TB 26/06/07
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment4_f:' || SQLERRM; -- PHENIX 2004
            RAISE e_trt;
    END get_calc_segment4_f; --PHENIX 2004
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment5_f
--  Description   :  Calcul et renvoie le segment5 de la clé (Code Partenaire)
-- PHENIX 2004    : cette fonction est l'ancienne get_calc_segment4_f
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment5_f (
        pv_segment5_orig   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
    BEGIN
        -- Segment 5 inchangé !!
        RETURN pv_segment5_orig;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment5_f:' || SQLERRM; -- PHENIX 2004
            RAISE e_trt;
    END get_calc_segment5_f; -- PHENIX 2004
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment6_f
--  Description   :  Calcul et renvoie le segment6 de la clé (Cost Center)
--  PHENIX 2004   :	 cette fonction est l'ancienne get_calc_segment5_f
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment6_f (
        pn_project_id   IN   NUMBER,
        pd_ref_date     IN   DATE
    )
        RETURN VARCHAR2
    IS
        vv_segment   gl_code_combinations.segment1%TYPE;
    BEGIN
        --vv_segment    := Dka_Spaautoaccounting_Pkg.get_cost_center_f (pn_project_id => pn_project_id, pd_date => pd_ref_date); -- OBE
        vv_segment    := Dka_Spaautoaccounting_Pkg.centrefi (pn_project_id => pn_project_id);                                    -- OBE
        RETURN vv_segment;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment6_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment6_f;
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment7_f
--  Description   :  Calcul et renvoie le segment7 de la clé (Code Affaire)
--  PHENIX 2004   :	 cette fonction est l'ancienne get_calc_segment6_f
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment7_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2
    IS
        vv_segment   gl_code_combinations.segment1%TYPE;
    BEGIN
        --< OBE
        /*Dka_Pa_Tools_Pkg.pa_run_accounting_rule (
            pv_rule_name           => 'CODE_D',
            pn_project_id          => pn_project_id,
            pv_segment_value       => vv_segment,
            pv_errbuf              => gv_errbuf,
            pn_retcode             => gn_retcode
        );*/
        vv_segment    := Dka_Spaautoaccounting_Pkg.affaire(pn_project_id => pn_project_id); 
        --> OBE
        RETURN vv_segment;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment7_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment7_f;
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment8_f
--  Description   :  Calcul et renvoie le segment8 de la clé (Nature d'activité)
--  PHENIX 2004   :	 cette fonction est l'ancienne get_calc_segment7_f
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment8_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2
    IS
        vv_segment   gl_code_combinations.segment1%TYPE;
    BEGIN
         --< OBE
        /*vv_segment    := Dka_Spaautoaccounting_Pkg.get_class_code_f (pn_project_id => pn_project_id,
                            pv_class_category       => 'NATURE_ACTIVITE');*/
        vv_segment    := Dka_Spaautoaccounting_Pkg.PROJETFI(pn_project_id => pn_project_id);                             
         --> OBE
        RETURN vv_segment;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment8_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment8_f;
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment9_f
--  Description   :  Calcul et renvoie le segment9 de la clé (Segment libre)
-- PHENIX 2004    :
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment9_f (
        pv_segment9_orig   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
    BEGIN
        -- Segment 9 inchangé !!
        RETURN pv_segment9_orig;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment9_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment9_f;
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment10_f
--  Description   :  Calcul et renvoie le segment10 de la clé (Segment libre)
-- PHENIX 2004    :
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment10_f (
        pv_segment10_orig   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
    BEGIN
        -- Segment 10 inchangé !!
        RETURN pv_segment10_orig;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment10_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment10_f;
    
----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment10_f
--  Description   :  Calcul et renvoie le segment10 de la clé (Segment libre)
-- PHENIX 2004    :
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment11_f (
        pv_segment11_orig   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
    BEGIN
        -- Segment 11 inchangé !!
        RETURN pv_segment11_orig;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment11_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment11_f;

----------------------------------------------------------------------------------------
--  Nom           :  get_calc_segment10_f
--  Description   :  Calcul et renvoie le segment10 de la clé (Segment libre)
-- PHENIX 2004    :
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment12_f (
        pv_segment12_orig   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
    BEGIN
        -- Segment 12 inchangé !!
        RETURN pv_segment12_orig;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_calc_segment12_f:' || SQLERRM;
            RAISE e_trt;
    END get_calc_segment12_f;    
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
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_task_id_f:' || SQLERRM;
            RAISE e_trt;
    END get_task_id_f;
--< OBE
----------------------------------------------------------------------------------------
--  Nom           :  get_task_id
--  Description   :  renvoie l'id de la tache d'un projet (par défaut la tache '1')
----------------------------------------------------------------------------------------
    FUNCTION get_task_id (
       pn_project_id    IN   NUMBER
      ,pv_task_number   IN   VARCHAR2 DEFAULT NULL
    )
        RETURN NUMBER
    IS
        vn_task_id   pa_tasks.task_id%TYPE;
    BEGIN
        SELECT pt.task_id
        INTO   vn_task_id
        FROM   pa_tasks pt
        WHERE  pt.task_number = NVL (pv_task_number, gv_default_task_number)
        AND    pt.project_id  = pn_project_id;
        RETURN vn_task_id;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_task_id:' || SQLERRM;
            RAISE e_trt;
    END get_task_id;    
--> OBE    
----------------------------------------------------------------------------------------
--  Nom           :  get_contrep_ccid_f
--  Description   :  renvoie l'id de la clé GL contrepartie avec même segment1 et segment2
----------------------------------------------------------------------------------------
    FUNCTION get_contrep_ccid_f (
        pv_segment1   IN   gl_code_combinations.segment1%TYPE,
		    pv_segment2   IN   gl_code_combinations.segment1%TYPE, -- PHENIX 2004
        pd_gl_date    IN   DATE,
        pn_ledger_id  IN   NUMBER --RBE MigR12
    )
        RETURN NUMBER
    IS
        vn_contrep_ccid   gl_code_combinations.code_combination_id%TYPE;
    BEGIN
        -- -- Construction de la combinaison comptable : même segment1 et les autres à '0'
        -- dka_tools_pkg.get_code_combination_id (
        --     pv_segment1                  => pv_segment1,
        --     pv_segment2                  => pv_segment2,
        --     pv_segment3                  => '0',
        --     pv_segment4                  => '0',
        --     pv_segment5                  => '0',
        --     pv_segment6                  => '0',
        --     pv_segment7                  => '0',
        --     pv_segment8                  => '0',
        --     pv_segment9                  => '0',  PHENIX 2004
        --     pv_segment10                  => '0', PHENIX 2004
        --     pn_code_combination_id       => vn_contrep_ccid,
        --     pv_errbuf                    => gv_errbuf,
        --     pn_retcode                   => gn_retcode
        -- );
        --
        -- IF gn_retcode != 0
        -- THEN
        --     RAISE e_trt;
        -- ELSE
        --     RETURN vn_contrep_ccid;
        -- END IF;
        BEGIN
            SELECT gcc.code_combination_id
            INTO   vn_contrep_ccid
            FROM   gl_code_combinations gcc
            WHERE      gcc.segment1 = pv_segment1
                   AND gcc.segment2 = pv_segment2 -- PHENIX 2004
                   AND gcc.segment3 = '0'
                   AND gcc.segment4 = '0'
                   AND gcc.segment5 = '0'
                   AND gcc.segment6 = '0'
                   AND gcc.segment7 = '0'
                   AND gcc.segment8 = '0'
				           AND gcc.segment9 = '0' -- PHENIX 2004
                   AND gcc.segment10 = '0' -- PHENIX 2004
                   AND gcc.segment11 = '0' -- RBE MigR12
                   AND gcc.segment12 = '0' -- RBE MigR12
                   -- AND gcc.enabled_flag = 'Y'; -- Ajout TB 25/08/2005 : pour éviter doublon de ccid -- MODIF TB 23/03/2009
                   AND ROWNUM = 1; -- MODIF TB 23/03/2009 : correction pour doublon
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
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
					          segment9, -- PHENIX 2004
                    segment10, -- PHENIX 2004
                    segment11, --RBE MigR12
                    segment12, --RBE MigR12
                    reference3,
                    jgzz_recon_flag,
                    last_update_date,
                    last_updated_by
                )
                SELECT gl_code_combinations_s.NEXTVAL,
                       gsob.chart_of_accounts_id,
                       'N',
                       'N',
                       'A',
                       'N',
                       'N',
                       'Y',
                       pv_segment1,
                       pv_segment2, -- PHENIX 2004
                       '0',
                       '0',
                       '0',
                       '0',
                       '0',
                       '0',
                       '0', -- PHENIX 2004
                       '0', -- PHENIX 2004
                       '0', --RBE MigR12
                       '0', --RBE MigR12
                       'N',
                       'N',
                       SYSDATE,
                       Fnd_Global.user_id
                FROM   gl_sets_of_books gsob
                WHERE  gsob.set_of_books_id = pn_ledger_id; --Fnd_Profile.value ('GL_SET_OF_BKS_ID'); --RBE MigR12
                -- Récupération de l'id
                SELECT gl_code_combinations_s.CURRVAL
                INTO   vn_contrep_ccid
                FROM   dual;
        END;
        RETURN vn_contrep_ccid;
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_contrep_ccid_f:' || SQLERRM;
            RAISE e_trt;
    END get_contrep_ccid_f;
----------------------------------------------------------------------------------------
--  Nom           :  get_org_id_f
--  Description   :  renvoie l'id de l'org dont le nom est passé en paramètre
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
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_org_id_f:' || SQLERRM;
            RAISE e_trt;
    END get_org_id_f;
----------------------------------------------------------------------------------------
--  Nom           :  get_burden_cost_f
--  Description   :  renvoie le montant des coûts complets
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
        -- On se place dans la bonne ORG_ID si on ne l'est pas déjà
        IF gn_current_org_id != pn_org_id
        THEN
            Fnd_Profile.put ('ORG_ID', pn_org_id);
            Fnd_Client_Info.set_org_context (CONTEXT => pn_org_id);
            gn_current_org_id    := pn_org_id;
        END IF;
        mo_global.set_policy_context('S',pn_org_id); -- OBE
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
        /*    IF vn_status != 0 THEN
                gn_retcode := 0;
                gv_errbuf  := 'DKA_SPACUTOFFGL_PKG.get_burden_cost_f: erreur en retour de PA_COST_PLUS1.view_indirect_cost';
                RAISE e_trt;
            END IF;
        */
        RETURN (NVL (pn_raw_cost, 0) + NVL (vn_indirect_cost, 0));
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_burden_cost_f:' || SQLERRM;
            RAISE e_trt;
    END get_burden_cost_f;
--------------------------------------------------------------------------------------
--  Nom           : Ins_Pa_Expend_Groups
--  Description   : Insertion d'un enregistrement dans PA_EXPENDITURE_GROUPS_ALL
--------------------------------------------------------------------------------------
    PROCEDURE ins_pa_expend_groups (
        pv_company_code        IN       VARCHAR2,
        pv_region              IN       VARCHAR2,  -- OBE
        pn_org_id              IN       NUMBER,
        pd_gl_date             IN       DATE,
        pv_expenditure_group   OUT      VARCHAR2
    )
    IS
        vn_nb   NUMBER (1);
    BEGIN
        --pv_expenditure_group    := 'GL-' || pv_company_code || '-' || TO_CHAR (gn_request_id);            -- OBE
        pv_expenditure_group    := 'GL-' || pv_region || pv_company_code || '-' || TO_CHAR (gn_request_id); -- OBE
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
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.Ins_Pa_Expend_Groups:' || SQLERRM;
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
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.Ins_Pa_Expenditures:' || SQLERRM;
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
        pn_task_id_refac                 IN       NUMBER, -- OBE
        pv_orig_transaction_reference    IN       VARCHAR2,
		pv_spacutoff_lig_num			 IN       VARCHAR2,  --SELO : EDB259
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
                     cost_distributed_flag,   --varchar2 (1)  not null, -- INDICATEUR COÛT CALCULÉ
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
                     attribute1,   --varchar2 (150), -- cuf PROJET À REFACTURER
                     attribute4,   --varchar2 (150),
					 attribute8,
                     attribute7,                     -- cuf TACHE À REFACTURER  -- OBE
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
					 pv_spacutoff_lig_num, --  SELO : EDB259  -- attribute8
                     pn_task_id_refac,      --attribute7 -- OBE
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
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.Ins_Pa_Expend_Items:' || SQLERRM;
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
        pn_ledger_id                IN   NUMBER DEFAULT NULL,   -- OBE
		pn_currency_code            IN   VARCHAR2 --SNK
    )
    IS
      vv_period     gl_periods.period_name%TYPE;
    BEGIN
        SELECT period_name
        INTO   vv_period
        FROM   gl_periods gp, gl_sets_of_books gsob
        WHERE  pd_gl_date BETWEEN gp.start_date AND gp.end_date
        AND    gp.period_set_name = gsob.period_set_name
        AND    set_of_books_id = pn_ledger_id -- OBE
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
                     -- PHENIX 2004
                     , 'N', NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL, pn_raw_cost, pn_burden_cost, NULL,
                     vv_period, vv_period, vv_period, NULL,
                     NULL, vv_period, pn_currency_code, NULL,
                     'N', NULL, NULL, NULL,
                     NULL, NULL, NULL, NULL,
                     NULL
                     -- FIN PHENIX 2004
                    );
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN OTHERS
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := 'DKA_SPACUTOFFGL_PKG.Ins_Pa_Cost_Distrib_Lines:' || SQLERRM;
            RAISE e_trt;
    END ins_pa_cost_distrib_lines;
--**************************************************************************************
--  FONCTIONS ET PROCEDURES PUBLIQUES
--**************************************************************************************
----------------------------------------------------------------------------------------
--  Nom           : CONTROLER_LINE_GL
--  Description   : controle de la ligne dans GL
--
--  PARAMETRES :
--    pv_errbuf               Sortie
--    pn_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         1: normal mais rien à faire en retour
--                         2: erreur
--                 ou le code erreur ORA
----------------------------------------------------------------------------------------
    PROCEDURE controler_line_gl (
        pv_errbuf                  IN OUT   VARCHAR2,
        pn_retcode                 IN OUT   NUMBER,
        pv_user_je_category_name   IN       VARCHAR2,
        pd_gl_date                 IN       DATE,
        pv_amount_type             IN       VARCHAR2,   -- D = Débit, C = Crédit
        pv_segment1_in             IN       VARCHAR2,
        pv_segment2_in             IN       VARCHAR2,
        pv_segment3_in             IN       VARCHAR2,
        pv_segment4_in             IN       VARCHAR2,
        pv_segment5_in             IN       VARCHAR2,
        pv_segment6_in             IN       VARCHAR2,
        pv_segment7_in             IN       VARCHAR2,
        pv_segment8_in             IN       VARCHAR2,
        pv_segment9_in             IN       VARCHAR2, -- PHENIX 2004
        pv_segment10_in            IN       VARCHAR2, -- PHENIX 2004
        pv_segment11_in            IN       VARCHAR2, -- OBE
        pv_segment12_in            IN       VARCHAR2, -- OBE
        pn_project_id              IN OUT   NUMBER,
        pn_task_id                 IN OUT   NUMBER, -- OBE
        pv_event_type              IN       VARCHAR2,
        pv_expenditure_type        IN       VARCHAR2,
        pn_quantity                IN       NUMBER DEFAULT NULL,
        --pv_famille                 IN       VARCHAR2 DEFAULT NULL, -- TB:13/09/2006  -- OBE
        --pn_code_d_n                IN       VARCHAR2 DEFAULT NULL, -- TB:06/12/2006  -- OBE
        pn_ledger_id               IN       NUMBER DEFAULT NULL,   -- OBE
        pn_project_id_refac        IN OUT   NUMBER,   --code projet à refacturer
        pn_task_id_refac           IN OUT   NUMBER,   -- OBE
        pv_segment1_out            OUT      VARCHAR2,
        pv_segment2_out            OUT      VARCHAR2,
        pv_segment3_out            OUT      VARCHAR2,
        pv_segment4_out            OUT      VARCHAR2,
        pv_segment5_out            OUT      VARCHAR2,
        pv_segment6_out            OUT      VARCHAR2,
        pv_segment7_out            OUT      VARCHAR2,
        pv_segment8_out            OUT      VARCHAR2,
        pv_segment9_out            OUT      VARCHAR2, -- PHENIX 2004
		    pv_segment10_out           OUT      VARCHAR2, -- PHENIX 2004
        pv_segment11_out           OUT      VARCHAR2, -- OBE
		    pv_segment12_out           OUT      VARCHAR2, -- OBE
        pv_concatenated_segs       OUT      VARCHAR2,
        pn_ccid                    OUT      NUMBER,
        pv_message_info            OUT      VARCHAR2
    )
    IS
        vv_context                     VARCHAR2 (150);
        vv_project_code                pa_projects_all.segment1%TYPE;
        vv_project_type                pa_projects_all.project_type%TYPE;
        vv_proj_org_id                 pa_projects_all.org_id%TYPE;
        vv_proj_org_name               hr_all_organization_units.NAME%TYPE;
        vv_project_code_refac          pa_projects_all.segment1%TYPE;
        vv_marge_amont                 VARCHAR2 (1); -- TB:13/09/2006
        -- projet à refacturer
        vv_project_type_refac          pa_projects_all.project_type%TYPE;
        vv_proj_org_id_refac           pa_projects_all.org_id%TYPE;
        vv_proj_org_name_refac         hr_all_organization_units.NAME%TYPE;
        vv_unit_of_measure             pa_expenditure_types.unit_of_measure%TYPE;
        vv_account_type                VARCHAR2 (1);
        vv_flag_compte_prov_cli        VARCHAR2 (1);
        vv_flag_tec_pca_cca            VARCHAR2 (1);
        vv_flag_compte_chg_immo        VARCHAR2 (1);
        vv_flag_matricule              VARCHAR2 (1);
        vv_flag_contrepass_auto        VARCHAR2 (1);
        vv_segment1_acct_area          VARCHAR2 (3);
        vv_segment1_company_code       VARCHAR2 (4);
        vv_ledger_id NUMBER; -- OBE
        vv_project_name                pa_projects_all.NAME%TYPE;
        vb_is_transaction_type_refac   BOOLEAN;
        test                           VARCHAR2(20);
        vv_type_projet                 VARCHAR2(20);
        
    -- = TRUE si type de dépense ou d'évenement est refacturable
    BEGIN
        --- appel de la procédure INIT pour l'initialisation de parametres globaux
        --init(pv_prog => 'CONTROL'); -- OBE 
        init; -- OBE
        -- On extrait la société et le centre de gestion du segment1 et du segment2 resp.
        vv_segment1_acct_area       := pv_segment2_in; --  PHENIX 2004
        vv_segment1_company_code    := pv_segment1_in; -- PHENIX 2004
        vv_ledger_id := pn_ledger_id;

        -- On vérifie le contexte du CUF pour voir si les contrôles sont applicables
        get_context_cuf (
            pv_errbuf                      => gv_errbuf,
            pn_retcode                     => gn_retcode,
            pv_user_je_category_name       => pv_user_je_category_name,
            pv_account                     => pv_segment3_in,
            pv_context                     => vv_context
        );
        IF gn_retcode != 0
        THEN
            RAISE e_trt;
        -- Modif GV20050915 : ajout du contexte FRAIS pour autoaccounting
        ELSIF NVL(vv_context,'NULL') NOT IN ('Y.E.X', 'Y.R.X', 'FRAIS') --EDB281
        THEN
            RAISE e_fin_normale;
        END IF;
		
   
        -- Recherche de la nature du compte local, de son flag "Compte provision client"
        -- et de son flag tec_pca_cca
        get_account_info (
            pv_segment3                   => pv_segment3_in,
            pv_account_type               => vv_account_type,
            pv_flag_compte_prov_cli       => vv_flag_compte_prov_cli,
            pv_flag_tec_pca_cca           => vv_flag_tec_pca_cca,
            pv_flag_compte_chg_immo       => vv_flag_compte_chg_immo,
            pv_flag_matricule             => vv_flag_matricule
        );
        -- Si c'est un compte de bilan => rien à faire
        --IF vv_account_type NOT IN ('E','R') THEN
        --    RAISE e_fin_normale ;
        --END IF;
        
        -- Code projet obligatoire pour les imputation su charges ou produits
        IF     vv_account_type IN ('E', 'R')
           AND pn_project_id IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E001');
            RAISE e_trt;
        ELSE
            -- Verification de l'existance du projet et de son ouverture à la date de la pièce
            get_project_info (
                pn_project_id          => pn_project_id,
                pd_ref_date            => pd_gl_date,
                pv_project_code        => vv_project_code,
                pv_project_type        => vv_project_type,
                pv_proj_org_id         => vv_proj_org_id,
                pv_proj_org_name       => vv_proj_org_name
            );
            -- On vérifie que le code projet saisi n'est pas de type REFAC
            IF vv_project_type = gv_project_type_refac
            THEN
                IF pn_project_id_refac IS NULL
                THEN
                    -- erreur "Ce code projet n'est pas autorisé en saisie directe. Choisissez un autre code projet"
                    gn_retcode    := 2;
                    gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E100');
                    RAISE e_trt;
                ELSE   -- pn_project_id_refac IS NOT NULL
                    -- Verification de l'existance du projet à refacturer et de son ouverture à la date de la pièce
                    get_project_info (
                        pn_project_id          => pn_project_id_refac,
                        pd_ref_date            => pd_gl_date,
                        pv_project_code        => vv_project_code_refac,
                        pv_project_type        => vv_project_type_refac,
                        pv_proj_org_id         => vv_proj_org_id_refac,
                        pv_proj_org_name       => vv_proj_org_name_refac
                    );
                    -- Vérification que le projet à refacturer n'est pas dans la société du projet de refac
                    IF vv_proj_org_id = vv_proj_org_id_refac
                    THEN
                        gn_retcode    := 2;
                        gv_errbuf     :=
                               'Il est interdit de mettre à jour le projet à refacturer.'
                            || CHR (10)
                            || 'De plus, vous avez saisi un projet qui ne génère plus de refacturation, car dans la même société que l''écriture.'
                            || CHR (10)
                            || 'S''il s''agit d''une erreur de saisie, mettez à jour le champ "Projet" ou effacez la ligne et recommencez la saisie.';
                        RAISE e_trt;
                    END IF;
                END IF;   -- pn_project_id_refac IS NULL THEN
            END IF;   --vv_project_type = gv_project_type_refac THEN
        END IF;

          
        -- Le type de dépense doit être renseigné dans les imputations pour les imputations de charges
        IF     vv_account_type = 'E'
           AND pv_expenditure_type IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E002');
            RAISE e_trt;
        -- L'événement produit doit être renseigné dans le CUF pour les imputations de produits
        ELSIF     vv_account_type = 'R'
              AND pv_event_type IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E003');
            RAISE e_trt;
        -- On vérifie que le type de dépense existe et est actif à la date de la pièce GL
        ELSIF vv_account_type = 'E'
        THEN
            get_expenditure_type_info (pv_expenditure_type => pv_expenditure_type, pd_ref_date => pd_gl_date,
                pv_unit_of_measure        => vv_unit_of_measure);
            -- si unité de mesure != 'EUR' alors la quantité doit être renseignée
            IF     vv_unit_of_measure != 'EUR'
               AND NVL (pn_quantity, 0) = 0
            THEN
                gn_retcode    := 2;
                gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                    pv_application       => 'DKA',
                                    pv_name              => 'DKA_SAPCUTOFFGL_E006',
                                    pv_token1            => 'TYPE_DEPENSE',
                                    pv_value1            => pv_expenditure_type
                                );
                RAISE e_trt;
            END IF;
        -- On vérifie que l'évènement produit existe et est actif à la date de la pièce GL
        ELSIF vv_account_type = 'R'
        THEN
            check_exist_event_type (pv_event_type => pv_event_type, pd_ref_date => pd_gl_date);
        END IF;
        
 -- DEBUT AJOUT TB : 13/09/2006
 --< OBE
 -- La gestion de la marge amont n'est pas reprise en R12
  /*
        -- Récupération du flag pour les marges amont
        IF     vv_account_type = 'E'
        THEN
            SELECT pet.attribute4
            INTO vv_marge_amont
            FROM PA_EXPENDITURE_TYPES pet
            WHERE pet.expenditure_type = pv_expenditure_type ;
        ELSIF vv_account_type = 'R'
        THEN
            SELECT NVL(pet.attribute4,'N')
            INTO vv_marge_amont
            FROM PA_EVENT_TYPES pet
            WHERE pet.event_type = pv_event_type ;
        END IF;
        

          
        -- Test du flag pour les marges amont
        IF vv_marge_amont = 'Y'
        THEN
            IF (pn_quantity IS NULL)
               OR (pv_famille IS NULL)
               OR (pn_code_d_n IS NULL)
            THEN
                gn_retcode    := 2;
                gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                        pv_application       => 'DKA',
                                        pv_name              => 'DKA_SAPCUTOFFGL_E106');
                RAISE e_trt;
            END IF;
        END IF;
        */
--> OBE        
-- FIN AJOUT TB

        -- Si on est dans un cas de REFAC
        IF     vv_account_type IN ('E', 'R')
           AND (
                   (    pn_project_id_refac IS NULL
                    AND vv_segment1_company_code != vv_proj_org_name)
                OR (    pn_project_id_refac IS NOT NULL
                    AND vv_segment1_company_code != vv_proj_org_name_refac)
               )
        THEN
        
            -- Recuperation du type de projet --
            vv_type_projet := dka_spaautoaccounting_pkg.get_project_type_f(pn_project_id);
    
            -- On Verifie que le type de projet n'est pas Investissement
            IF vv_type_projet = gv_project_type_invest
            THEN
                gn_retcode    := 2;
                gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E107');
                RAISE e_trt;
            END IF;
            
            -- On vérifie que le type de pièce n'est pas à contrepassation automatique
            Dka_Gl_Tools_Pkg.gl_get_category_autorev_flag (
                pv_errbuf                      => gv_errbuf,
                pn_retcode                     => gn_retcode,
                pn_ledger_id                   => vv_ledger_id,--gn_ledger_id,  -- OBE
                pv_user_je_category_name       => pv_user_je_category_name,
                pv_autoreverse_flag            => vv_flag_contrepass_auto
            );
            
            IF gn_retcode != 0
            THEN
                gv_errbuf    := 'DKA_GL_TOOLS_PKG.gl_get_category_autorev_flag:' || gv_errbuf;
                RAISE e_trt;
            END IF;         

            -- si le type de pièce est à contrepassation automatique
            -- => erreur "" Refacturation automatique interdite pour les journaux à contre passation automatique.
            --              Choisissez un autre code projet ou un autre type de pièce "
            IF vv_flag_contrepass_auto = 'Y'
            THEN
                gn_retcode    := 2;
                gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E101');
                RAISE e_trt;
            END IF;
            -- On vérifie que le type de dépense ou évenement produit est bien refacturable
                       

          
            IF vv_account_type = 'E'
            THEN
                vb_is_transaction_type_refac    := Dka_Sarrefac_Pkg.is_transaction_type_refac (pv_transaction_type => pv_expenditure_type); 
                IF NOT vb_is_transaction_type_refac
                THEN
                    gn_retcode    := 2;
                    gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                        pv_application       => 'DKA',
                                        pv_name              => 'DKA_SAPCUTOFFGL_E102',
                                        pv_token1            => 'TYPE',
                                        pv_value1            => 'de dépense'
                                    );
                    RAISE e_trt;
                END IF;
            ELSE
                vb_is_transaction_type_refac    := Dka_Sarrefac_Pkg.is_transaction_type_refac (pv_transaction_type => pv_event_type); 
                IF NOT vb_is_transaction_type_refac
                THEN
                    gn_retcode    := 2;
                    gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                        pv_application       => 'DKA',
                                        pv_name              => 'DKA_SAPCUTOFFGL_E102',
                                        pv_token1            => 'TYPE',
                                        pv_value1            => 'd''événement'
                                    );
                    RAISE e_trt;
                END IF;
            END IF;

          
          
            IF pn_project_id_refac IS NULL
            THEN
                -- Tout est ok => La refacturation va avoir lieu
                vv_project_code_refac    := vv_project_code;
                -- projet à refacturer
                pn_project_id_refac      := pn_project_id;
                pn_task_id_refac         := pn_task_id;     -- OBE
                

                Dka_Pa_Tools_Pkg.pa_get_code_z_refac (
                    pn_org_id               => NULL,
                    pv_societe              => vv_segment1_company_code,
                    pv_centre_gestion       => vv_segment1_acct_area,
                    pv_segment1             => vv_project_code,
                    pn_project_id           => pn_project_id,
                    pv_project_name         => vv_project_name,
                    pv_errbuf               => gv_errbuf,
                    pn_retcode              => gn_retcode
                );
                IF gn_retcode != 0
                THEN
                    gv_errbuf    := Dka_Tools_Pkg.GET_MESSAGE (
                                       pv_application       => 'DKA',
                                       pv_name              => 'DKA_SAPCUTOFFGL_E010',
                                       pv_token1            => 'SOCIETE',
                                       pv_value1            => vv_segment1_company_code,
                                       pv_token2            => 'MESSAGE_ERREUR',
                                       pv_value2            => gv_errbuf
                                   );
                    RAISE e_trt;
                END IF;
                
                -- Détermination de la tâche REFAC 
                pn_task_id               := get_task_id (pn_project_id => pn_project_id, pv_task_number => '1');
                
                -- On renseigne le message d'information 'Refacturation effectuée vers projet xxxx'
                pv_message_info          := Dka_Tools_Pkg.GET_MESSAGE (
                                               pv_application       => 'DKA',
                                               pv_name              => 'DKA_SAPCUTOFFGL_I001',
                                               pv_token1            => 'CODE_PROJET',
                                               pv_value1            => vv_project_code
                                           );
            ELSE
                -- La refacturation a déjà été calculée
                NULL;
            END IF;   --  pn_project_id_refac IS NULL THEN
        ELSE   -- On n'est pas dans un cas de refacturation
            vv_project_code_refac    := NULL;   -- projet à refacturer
            pn_project_id_refac      := NULL;
            pn_task_id_refac         := NULL;   -- OBE
        END IF;   -- Si on est dans un cas de REFAC
        -- Contrôle de cohérence des données
        --< OBE
        DKA_PA_TOOLS_PKG.pa_check_transaction_data (
            pv_errbuf                 => gv_errbuf,
            pn_retcode                => gn_retcode,
            pn_project_id             => pn_project_id,
            pn_tache_id               => pn_task_id,
            pv_expenditure_type       => pv_expenditure_type,
            pv_event_type             => pv_event_type,
            pd_date                   => pd_gl_date--,
            --pv_refac                  => 'N'
        );
        --> OBE
        IF gn_retcode != 0
        THEN
            gn_retcode    := 2;
            RAISE e_trt;
        END IF;
        IF pn_project_id_refac IS NOT NULL
        THEN
            -- Contrôle de cohérence des données
                       

            --< OBE
            DKA_PA_TOOLS_PKG.pa_check_transaction_data (
                pv_errbuf                 => gv_errbuf,
                pn_retcode                => gn_retcode,
                pn_project_id             => pn_project_id_refac,
                pn_tache_id               => pn_task_id_refac,
                pv_expenditure_type       => pv_expenditure_type,
                pv_event_type             => pv_event_type,
                pd_date                   => pd_gl_date--,
                --pv_refac                  => 'Y'
            );
            --> OBE
            IF gn_retcode != 0
            THEN
                gn_retcode    := 2;
                RAISE e_trt;
            END IF;
        END IF;
        -- Vérification si la catégorie est à contrepassation automatique
        Dka_Gl_Tools_Pkg.gl_get_category_autorev_flag (
            pv_errbuf                      => gv_errbuf,
            pn_retcode                     => gn_retcode,
            pn_ledger_id                   => vv_ledger_id,--gn_ledger_id,  -- OBE
            pv_user_je_category_name       => pv_user_je_category_name,
            pv_autoreverse_flag            => vv_flag_contrepass_auto
        );
        IF gn_retcode != 0
        THEN
            gv_errbuf    := 'DKA_GL_TOOLS_PKG.gl_get_category_autorev_flag:' || gv_errbuf;
            RAISE e_trt;
        END IF;               

        -- Si la catégorie est à contrepassation automatique, on valide les données à la date de contrepassation
        IF vv_flag_contrepass_auto = 'Y'
        THEN
            -- Contrôle de cohérence des données
            --< OBE
            DKA_PA_TOOLS_PKG.pa_check_transaction_data (
                pv_errbuf                 => gv_errbuf,
                pn_retcode                => gn_retcode,
                pn_project_id             => pn_project_id,
                pn_tache_id               => pn_task_id,
                pv_expenditure_type       => pv_expenditure_type,
                pv_event_type             => pv_event_type,
                pd_date                   => TRUNC (ADD_MONTHS (pd_gl_date, 1), 'MONTH')--,
                --pv_refac                  => 'N'
            );
            --> OBE
            IF gn_retcode != 0
            THEN
                gv_errbuf     :=    'Imputation interdite pour le projet '
                                 || vv_project_code
                                 || ' sur un journal à extourne automatique'
                                 || ' car ce projet ne sera plus valide à la date de l''extourne ('
                                 || TO_CHAR (TRUNC (ADD_MONTHS (pd_gl_date, 1), 'MONTH'), 'DD/MM/YYYY')
                                 || ')';
                gn_retcode    := 2;
                RAISE e_trt;
            END IF;
            IF pn_project_id_refac IS NOT NULL
            THEN
                -- Contrôle de cohérence des données
                --< OBE
                DKA_PA_TOOLS_PKG.pa_check_transaction_data (
                    pv_errbuf                 => gv_errbuf,
                    pn_retcode                => gn_retcode,
                    pn_project_id             => pn_project_id_refac,
                    pn_tache_id               => pn_task_id_refac,
                    pv_expenditure_type       => pv_expenditure_type,
                    pv_event_type             => pv_event_type,
                    pd_date                   => TRUNC (ADD_MONTHS (pd_gl_date, 1), 'MONTH')--,
                    --pv_refac                  => 'Y'
                );
                --> OBE
                IF gn_retcode != 0
                THEN
                    gv_errbuf     :=    'Imputation interdite pour le projet '
                                     || vv_project_code
                                     || ' sur un journal à extourne automatique'
                                     || ' car ce projet ne sera plus valide à la date de l''extourne ('
                                     || TO_CHAR (TRUNC (ADD_MONTHS (pd_gl_date, 1), 'MONTH'), 'DD/MM/YYYY')
                                     || ')';
                    gn_retcode    := 2;
                    RAISE e_trt;
                END IF;
            END IF;
        END IF;
        


        -- On recalcule le segment1 de la clé
        --< OBE
        
        pv_segment1_out             := get_calc_segment1_f (pv_segment1_orig => pv_segment1_in);--pn_project_id => pn_project_id, pd_ref_date => pd_gl_date);
        IF pv_segment1_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '1'
                            );
            RAISE e_trt;
        END IF;
        
        --> OBE
        -- On recalcule le segment2 de la clé
        pv_segment2_out             := get_calc_segment2_f (pn_project_id => pn_project_id, pd_ref_date => pd_gl_date); -- PHENIX 2004
        IF pv_segment2_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '2'
                            );
            RAISE e_trt;
        END IF;
        -- On recalcule le segment3 de la clé
        pv_segment3_out             := get_calc_segment3_f (
                                          pv_segment3_orig          => pv_segment3_in,
                                          pv_account_type           => vv_account_type,
                                          pv_flag_tec_pca_cca       => vv_flag_tec_pca_cca,
                                          pv_amount_type            => pv_amount_type,
                                          pv_expenditure_type       => pv_expenditure_type,
                                          pv_event_type             => pv_event_type,
                                          pn_project_id             => pn_project_id,  -- OBE
                                          pn_task_id                => pn_task_id,     -- OBE
                                          pv_flag_compte_chg_immo   => vv_flag_compte_chg_immo
                                      );
        IF pv_segment3_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '3'
                            );
            RAISE e_trt;
        END IF;
        -- On recalcule le segment4 de la clé
        pv_segment4_out             := get_calc_segment4_f (
                                          pn_project_id             => pn_project_id,
                                          pn_project_id_refac       => pn_project_id_refac,
                                          pv_account_type           => vv_account_type,
                                          pv_flag_tec_pca_cca       => vv_flag_tec_pca_cca,
                                          pv_amount_type            => pv_amount_type,
                                          pv_expenditure_type       => pv_expenditure_type,
                                          pv_event_type             => pv_event_type,
                                          pd_ref_date               => pd_gl_date,
                                          pn_task_id                => pn_task_id,      -- OBE
                                          pv_flag_compte_chg_immo   => vv_flag_compte_chg_immo
                                      ); -- PHENIX 2004
        IF pv_segment4_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '4'
                            ) || ' : ' || chr(10) || gv_errbuf ;  -- Modif TB 26/06/2007
            RAISE e_trt;
        END IF;
        -- On recalcule le segment5 de la clé
		pv_segment5_out             := get_calc_segment5_f (pv_segment5_orig => pv_segment5_in); -- PHENIX 2004
        IF pv_segment5_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '5'
                            );
            RAISE e_trt;
        END IF;
        -- On recalcule le segment6 de la clé
        pv_segment6_out             := get_calc_segment6_f (pn_project_id => pn_project_id, pd_ref_date => pd_gl_date); -- PHENIX 2004
        IF pv_segment6_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '6'
                            );
            RAISE e_trt;
        END IF;
        -- On recalcule le segment7 de la clé
        pv_segment7_out             := get_calc_segment7_f (pn_project_id => pn_project_id);
        IF pv_segment7_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '7'
                            );
            RAISE e_trt;
        END IF;
        -- On recalcule le segment8 de la clé
        pv_segment8_out             := get_calc_segment8_f (pn_project_id => pn_project_id);
        IF pv_segment8_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '8'
                            );
            RAISE e_trt;
        END IF;
		-- On recalcule le segment9 de la clé
		-- PHENIX 2004
        pv_segment9_out             := get_calc_segment9_f (pv_segment9_orig => pv_segment9_in);
        IF pv_segment9_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '9'
                            );
            RAISE e_trt;
        END IF;
               
		-- On recalcule le segment10 de la clé
        pv_segment10_out             := get_calc_segment10_f (pv_segment10_orig => pv_segment10_in);
        IF pv_segment10_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '10'
                            );
            RAISE e_trt;
        END IF;
        
--< OBE         
		-- On recalcule le segment11 de la clé
        pv_segment11_out             := get_calc_segment11_f (pv_segment11_orig => pv_segment11_in);
        IF pv_segment11_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '11'
                            );
            RAISE e_trt;
        END IF;

		-- On recalcule le segment12 de la clé
        pv_segment12_out             := get_calc_segment12_f (pv_segment12_orig => pv_segment12_in);
        IF pv_segment12_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (
                                pv_application       => 'DKA',
                                pv_name              => 'DKA_SAPCUTOFFGL_E105',
                                pv_token1            => 'NUM_SEGMENT',
                                pv_value1            => '12'
                            );
            RAISE e_trt;
        END IF;

--> OBE
        
        -- Construction de la combinaison comptable
        pv_concatenated_segs        :=    pv_segment1_out
                                       || '.'
                                       || pv_segment2_out
                                       || '.'
                                       || pv_segment3_out
                                       || '.'
                                       || pv_segment4_out
                                       || '.'
                                       || pv_segment5_out
                                       || '.'
                                       || pv_segment6_out
                                       || '.'
                                       || pv_segment7_out
                                       || '.'
                                       || pv_segment8_out
                                       || '.'
                                       || pv_segment9_out -- PHENIX 2004
                                       || '.'
                                       || pv_segment10_out	-- PHENIX 2004
                                       || '.'
                                       || pv_segment11_out	-- OBE
                                       || '.'
                                       || pv_segment12_out;	-- OBE
        Dka_Tools_Pkg.get_code_combination_id (
            pv_segment1                  => pv_segment1_out,
            pv_segment2                  => pv_segment2_out,
            pv_segment3                  => pv_segment3_out,
            pv_segment4                  => pv_segment4_out,
            pv_segment5                  => pv_segment5_out,
            pv_segment6                  => pv_segment6_out,
            pv_segment7                  => pv_segment7_out,
            pv_segment8                  => pv_segment8_out,
            pv_segment9                  => pv_segment9_out, -- PEHNIX 2004
            pv_segment10                 => pv_segment10_out, -- PHENIX 2004
            pv_segment11                 => pv_segment11_out, -- OBE
            pv_segment12                 => pv_segment12_out, -- OBE
            pn_code_combination_id       => pn_ccid,
            pv_errbuf                    => gv_errbuf,
            pn_retcode                   => gn_retcode
        );
        IF gn_retcode != 0
        THEN
            RAISE e_trt;
        END IF;
        -- FIN PHENIX 2004
        -- Fin normale
        pn_retcode                  := 0;
        pv_errbuf                   := NULL;
    EXCEPTION
        WHEN e_fin_normale
        THEN
            pn_retcode    := 1;
            pv_errbuf     := NULL;
        WHEN e_trt
        THEN
            pn_retcode    := gn_retcode;
            pv_errbuf     := gv_errbuf;
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := 'DKA_SPACUTOFFGL_PKG.controler_line_gl' || SQLERRM;
    END controler_line_gl;
----------------------------------------------------------------------------------------
--  Nom           : get_context_cuf
--  Description   : Recherche du contexte applicable pour le CUF sur lignes GL
--
--  PARAMETRES :
--    pv_errbuf               Sortie
--    pn_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
--                 ou le code erreur ORA
----------------------------------------------------------------------------------------
    PROCEDURE get_context_cuf (
        pv_errbuf                  IN OUT   VARCHAR2,
        pn_retcode                 IN OUT   NUMBER,
        pv_user_je_category_name   IN       VARCHAR2,
        pv_account                 IN       VARCHAR2,
        pv_context                 OUT      VARCHAR2
    )
    IS
        vv_flag_cuf_actif         VARCHAR2 (1);
        vv_account_type           VARCHAR2 (1);
        vv_flag_compte_prov_cli   VARCHAR2 (1);
        vv_flag_tec_pca_cca       VARCHAR2 (1);
        vv_flag_compte_chg_immo   VARCHAR2 (1);
        vv_flag_matricule         VARCHAR2 (1);
        cv_rb_context    CONSTANT VARCHAR2 (2) := 'RB';
		vn_count                  NUMBER := 0;
    BEGIN
        -- Si un des critères est NULL, contexte = NULL
        IF    pv_user_je_category_name IS NULL
           OR pv_account IS NULL
        THEN
            pv_context    := NULL;
            RAISE e_fin_normale;
        END IF;
        -- Si on a déjà recherché le contexte pour les même critères,
        -- on renvoie la valeur mémorisée
        IF     pv_user_je_category_name = gv_user_je_category_name
           AND pv_account = gv_account
        THEN
            pv_context    := gv_context_cuf_gljl;
            RAISE e_fin_normale;
        END IF;
        -- Si la valeur du segment 3 commence par 51XXXX  alors --
        IF SUBSTR (pv_account, 1, 2) = '51'
        THEN
            pv_context    := cv_rb_context;
            RAISE e_trt;
        END IF;
        -- Modif GV20041221 : Ajout Contexte FRAIS pour les comptes du jeu de valeur DKA_CPT_FRAIS_BANC
        SELECT count(1)
        INTO vn_count
        FROM fnd_flex_values_vl ffv,
             fnd_flex_value_sets ffvs
        WHERE ffvs.flex_value_set_name = 'DKA_CPT_FRAIS_BANC'
          AND ffvs.flex_value_set_id = ffv.flex_value_set_id
          AND ffv.flex_value = pv_account;
        IF vn_count <> 0
        THEN
            pv_context := 'FRAIS';
            RAISE e_trt;
        END IF;
        -- Fin Modif GV20041221
        -- On recherche l'id et le nom du jeu de valeur du segment "compte local" de la clé GL
        IF gn_seg3_flex_value_set_id IS NULL
        THEN
            Dka_Tools_Pkg.get_flex_key_seg_value_set
                                            (
                pv_errbuf                    => gv_errbuf,
                pn_retcode                   => gn_retcode,
                pv_legal_flex_key_flag       => 'N',   -- on considère la ccf des organisations opérationnelles
                pn_segment_num               => 3,
                pn_flex_value_set_id         => gn_seg3_flex_value_set_id,
                pv_flex_value_set_name       => gv_seg3_flex_value_set_name
            );
            IF gn_retcode != 0
            THEN
                RAISE e_trt;
            END IF;
        END IF;
        -- Recherche de la nature du compte local, de son flag "Compte provision client"
        -- et de son flag tec_pca_cca
        get_account_info (
            pv_segment3                   => pv_account,
            pv_account_type               => vv_account_type,
            pv_flag_compte_prov_cli       => vv_flag_compte_prov_cli,
            pv_flag_tec_pca_cca           => vv_flag_tec_pca_cca,
            pv_flag_compte_chg_immo       => vv_flag_compte_chg_immo,
            pv_flag_matricule             => vv_flag_matricule
        );
        IF vv_account_type NOT IN ('E', 'R')
        THEN
            vv_account_type    := 'X';
        END IF;
        
        -- Recherche des infos du type de pièce
        get_je_category_info (pv_user_je_category_name => pv_user_je_category_name, pv_flag_cuf_actif => vv_flag_cuf_actif);

        -- Constitution du contexte
        IF vv_flag_matricule = 'N' THEN
           pv_context             := vv_flag_cuf_actif || '.' || vv_account_type || '.' || vv_flag_compte_prov_cli;
        ELSE
		   -- pv_context             := 'MAT'; --EDB281
		  pv_context := NULL; --EDB281
        END IF;
        
        -- Mémorisation du contexte
        gv_context_cuf_gljl    := pv_context;
        
    EXCEPTION
        WHEN e_fin_normale
        THEN
            pn_retcode    := 1;
            pv_errbuf     := NULL;
        WHEN e_trt
        THEN
            pn_retcode    := gn_retcode;
            pv_errbuf     := gv_errbuf;
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := 'DKA_SPACUTOFFGL_PKG.get_context_cuf' || SQLERRM;
    END get_context_cuf;
----------------------------------------------------------------------------------------
--  Nom           : TRANSFER_FROM_GL_TO_PA
--  Description   : Transfert des écritures de CUTOFF de GL vers PA
--  
--  PARAMETRES :
--    pv_errbuf               Sortie
--    pn_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
--                 ou le code erreur ORA
----------------------------------------------------------------------------------------
    PROCEDURE transfer_from_gl_to_pa (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
    )
    IS
        vv_spacutoff_seq_num     VARCHAR2 (30);
		vv_spacutoff_lig_num     VARCHAR2 (30);
        vd_gl_date               DATE;
        vd_pa_date               DATE;
        vv_company_code          VARCHAR2 (4);
        vv_region                VARCHAR2 (3); -- OBE
        vn_task_id               pa_tasks.task_id%TYPE;
        vn_contrep_ccid          gl_code_combinations.code_combination_id%TYPE;
        vv_expenditure_group     pa_expenditure_groups.expenditure_group%TYPE;
        vn_expenditure_id        pa_expenditures_all.expenditure_id%TYPE;
        vn_expenditure_item_id   pa_expenditure_items_all.expenditure_item_id%TYPE;
        vn_cost_center_org_id    hr_all_organization_units.organization_id%TYPE;
        vn_burden_cost           NUMBER (15, 2);   -- montant des coûts complets
        vn_raw_cost              NUMBER;   -- OBE
        vv_attribute_category    pa_expenditure_items_all.attribute_category%TYPE;
        vv_unit_of_measure       pa_expenditure_types.unit_of_measure%TYPE;
        ln_nb_ok                 NUMBER := 0;
        ln_nb_ko                 NUMBER := 0;
        vn_quantity              NUMBER := 0;
        vn_autopost_set_id       NUMBER;
        vd_start_date_except     DATE;
        vv_period_name_except    VARCHAR2(30) := NULL; -- GV20041119
        vd_start_date_cours      DATE := NULL; -- GV20041119
        vd_end_date_cours        DATE := NULL; -- GV20041119
        vv_period_name_cours     VARCHAR2(30) := NULL; -- GV20041119        
        --< OBE
        vn_sob_id                NUMBER; 
        vn_event_amount          NUMBER;
        vn_rate                  NUMBER;
        --> OBE
        
		CURSOR cur_gl_je_lines (
            pn_set_of_books_id   IN   NUMBER
        )
        IS
            SELECT   gjh.je_header_id je_header_id,
                     gjh.NAME gjh_name,
                     gjh.default_effective_date default_effective_date,
                     gjh.accrual_rev_je_header_id accrual_rev_je_header_id,   -- id de la pièce contrepassée
                     gjl.je_line_num je_line_num,
                     gjl.code_combination_id code_combination_id,
                     DECODE (NVL (gjl.accounted_cr, 0), 0, gjl.accounted_dr, gjl.accounted_cr * (-1)) raw_cost,    -- montant des coûts directs
                     --DECODE (NVL (gjl.accounted_dr, 0), 0, gjl.accounted_cr, gjl.accounted_dr * (-1)) event_amount,-- montant de produit -- OBE 
                     --* DECODE (pet.event_type_classification, 'WRITE ON', 1, (-1)) event_amount,   -- montant de produit               -- OBE 
                      DECODE (NVL (gjl.accounted_dr, 0), 0, gjl.accounted_cr, gjl.accounted_dr * (-1))                    --11/10/2018
                     * DECODE (pet.event_type_classification, 'WRITE ON', 1, (-1)) event_amount,   -- montant de produit  --11/10/2018
                     DECODE (NVL (gjl.entered_cr, 0), 0, gjl.entered_dr, gjl.entered_cr * (-1)) raw_cost_2,    -- montant des coûts directs -- OBE
                     DECODE (NVL (gjl.entered_dr, 0), 0, gjl.entered_cr, gjl.entered_dr * (-1))                           -- OBE
                     * DECODE (pet.event_type_classification, 'WRITE ON', 1, (-1)) event_amount_2,  -- montant de produit   --11/10/2018
                     gjl.accounted_dr                accounted_dr,
                     gjl.accounted_cr                accounted_cr,
                     gjl.entered_dr                  entered_dr,   -- OBE
                     gjl.entered_cr                  entered_cr,   -- OBE
                     gjl.description description,
                     TO_NUMBER (gjl.attribute11) project_id,
                     gjl.attribute12 event_type,
                     gjl.attribute13 expenditure_type,
                     --               ,TO_NUMBER(gjl.attribute14)      quantity
                     --TO_NUMBER (gjl.attribute14, '999999999999D99999', 'NLS_NUMERIC_CHARACTERS=.,') quantity,
                     gjl.attribute14 quantity,
                     TO_NUMBER (gjl.attribute15) project_id_refac,
                     TO_NUMBER (gjl.attribute18) task_id_refac, -- OBE
                     gjl.attribute16 cutoff_transfer_status,
                     gjl.reference_1 reference_1,
                     gjl.reference_2 reference_2,
                     gjl.reference_3 reference_3,
                     gjl.reference_6 reference_6,
                     ppa.org_id org_id,
                     gcc.segment1 ccid_segment1,
					           gcc.segment2 ccid_segment2, -- PHENIX 2004
                     gcc.segment6 ccid_segment6, -- PHENIX 2004
					           gcc_kfv.concatenated_segments,
                     gjl.ROWID,
                     gjl.attribute17 task_id,   -- OBE
                     gjh.currency_code devise_transaction,   -- OBE
                     gll.currency_code devise_comptable,     -- OBE
                     ppa.project_currency_code devise_projet, -- OBE
                     gjh.CURRENCY_CONVERSION_DATE,
                     ppa.CARRYING_OUT_ORGANIZATION_ID project_org_id
            FROM     gl_je_headers gjh,
                     gl_je_lines gjl,
                     pa_projects_all ppa,
                     gl_code_combinations gcc,
                     gl_code_combinations_kfv gcc_kfv,
                     pa_event_types pet,
                     gl_ledgers gll,
                     (SELECT DISTINCT period_name                                                                     --
                      FROM gl_period_statuses                                                                          -- GV20041119 :
                      WHERE set_of_books_id = pn_set_of_books_id                                                       -- Ajout liste périodes
                        AND application_id = 101 --GL                                                                  -- à traiter
                        AND start_date BETWEEN NVL(vd_start_date_except, vd_start_date_cours) AND vd_start_date_cours  --
                        AND closing_status = 'O'                                                                   -- Ajout TB 18/12/2013
                     ) list_periods                                                                                    --
            WHERE        gjh.period_name = list_periods.period_name -- Modif GV20041119 : Ajout période pour réduire le temps du traitement
                     --AND gjh.set_of_books_id = pn_set_of_books_id -- OBE
                     AND gjh.ledger_id = pn_set_of_books_id         -- OBE
                     AND gjh.status = 'P'
                     --AND gjh.currency_code = gv_currency_code -- OBE
                     AND gjh.currency_code  != 'STAT'           -- OBE
                     AND gjh.je_header_id = gjl.je_header_id
                     AND (
                             gjl.attribute16 IS NULL
                          OR   -- lignes normales non traitées
                             gjl.attribute16 NOT LIKE    TO_CHAR (gjl.je_header_id)
                                                      || cv_delim_cuf
                                                      || '%'   -- lignes contrepassées non traitées
                         )
                     AND to_char(ppa.project_id) = gjl.attribute11--YWA artf2162994 
                     -- AND ppa.project_type != 'APPARTENANCE'   -- Modif TB20053005 : Suppression de l'exclusion des projets de Type "APPARTENANCE"
                     AND gcc.code_combination_id = gjl.code_combination_id
                     AND pet.event_type(+) = gjl.attribute12
                     AND (gjl.accounted_cr != 0 or gjl.accounted_dr != 0)  -- Modif TB20050410 : Exclusion des écritures de montant nul
                     AND (gcc.account_type in ('E', 'R') -- Modif TB20060407 : Exclusion des écritures ne portant pas sur des comptes de résultats
					           
                     OR (SELECT DECODE(COUNT(1), 0, 'N', 'Y')
                            FROM fa_categories_vl fcv, fa_category_books fcb
                           WHERE EXISTS (SELECT 1
                                          FROM fa_book_controls_sec bc
                                         WHERE nvl(date_ineffective, sysdate + 1) > sysdate
                                           AND bc.book_type_code = fcb.book_type_code)
                             AND fcv.category_id = fcb.category_id
                             AND NVL(fcv.enabled_flag, 'N') = 'Y'
                             AND fcb.asset_clearing_acct = gcc.segment3) = 'Y') 
                     
                     AND gcc_kfv.code_combination_id = gcc.code_combination_id
                     AND gll.ledger_id = gjl.ledger_id -- OBE
            ORDER BY gjh.NAME,   -- tri par numéro
                     gjl.je_line_num   -- et n° de ligne
           ;
 
        rec_gl_je_lines          cur_gl_je_lines%ROWTYPE;
        
    BEGIN
        --- appel de la procédure INIT pour l'initialisation de parametres globaux
        init (pv_prog => 'TRANSFER');
  
        put_line_out ('<<<<<<<<<<< TRANSFERT DE GL VERS PA >>>>>>>>>>>>>>>>>>>>');
        put_line_log ('<<<<<<<<<<< TRANSFERT DE GL VERS PA >>>>>>>>>>>>>>>>>>>>');
        put_line_out ('');
        put_line_log ('');
        
        put_line_out ('Identifiant du traitement : ' || fnd_global.conc_request_id);
        put_line_log ('Identifiant du traitement : ' || fnd_global.conc_request_id);
        put_line_out ('Date du traitement : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
        put_line_log ('Date du traitement : ' || to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
        put_line_out ('');
        put_line_log ('');
        
        --< OBE
        vn_sob_id := fnd_profile.VALUE ('GL_ACCESS_SET_ID');
        
        FOR ledger IN ( SELECT a.ledger_id,b.short_name, b.name  --RBE artf2055421
                        FROM GL_ACCESS_SET_LEDGERS a, gl_ledgers b
                        WHERE a.access_set_id = vn_sob_id
                        AND   a.ledger_id = b.ledger_id
                        AND b.ledger_category_code = 'PRIMARY'
                        ORDER BY b.short_name
                      )
        LOOP
        --> OBE
        -- Modif GV20041911 : vérification si une période a été ouverte exceptionnellement
        --< OBE

            DKA_GL_TOOLS_PKG.period_gl_to_close(            -- OBE
            --dka_sglcloture_except_pkg.period_gl_to_close( -- OBE
                 --gn_set_of_books_id,  -- OBE
                 ledger.ledger_id,      -- OBE
                 vn_autopost_set_id,
                 vv_period_name_except,
                 gv_errbuf,
                 gn_retcode
            );

        --> OBE
        
        IF vv_period_name_except IS NOT NULL
        THEN
            vd_start_date_except := to_date(vv_period_name_except, 'MON-YY');
        END IF;
        -- Modif GV20041911 : recherche de la période GL en cours (plus petite période GL ouverte non ouverte exceptionnellement)
        BEGIN
          /*        
          SELECT MIN(start_date), end_date, period_name
          INTO vd_start_date_cours, vd_end_date_cours, vv_period_name_cours
          FROM gl_period_statuses
          WHERE application_id = 101 --GL
            AND set_of_books_id = ledger.ledger_id --gn_set_of_books_id -- OBE
            AND closing_status = 'O' --OPEN
            AND ROWNUM = 1
            AND NVL (attribute1, 'N') != 'Y'
          GROUP BY start_date, end_date, period_name;
          */
          SELECT gps1.start_date, gps1.end_date, gps1.period_name
            INTO vd_start_date_cours, vd_end_date_cours, vv_period_name_cours
            FROM gl_period_statuses gps1
           WHERE gps1.start_date = (SELECT min(gps.start_date)
                                      FROM gl_period_statuses gps, GL_ACCESS_SET_LEDGERS gasl
                                     WHERE gps.application_id = 101 -- GL
                                       AND gasl.access_set_id = fnd_profile.VALUE('GL_ACCESS_SET_ID')
                                       AND gasl.ledger_id = gps.ledger_id
                                       AND gasl.ledger_id = ledger.ledger_id
                                       AND gps.closing_status = 'O'
                                       AND NVL(attribute1, 'N') != 'Y' -- Pas une période ouverte exceptionnellement
                                    )
             and rownum = 1;
          
        EXCEPTION
          WHEN OTHERS THEN
            vd_start_date_cours := NULL;
            vd_end_date_cours := NULL;
            vv_period_name_cours := NULL;
        END;
        
        -- Modif GV20041119 : ajout messages informatifs dans la sortie
        IF vv_period_name_except IS NULL
        THEN
            put_line_out('Traitement de la période ' || vv_period_name_cours|| ' pour la société '||ledger.short_name || ' (' || ledger.name || ')'); --RBE artf2055421
            put_line_log('Traitement de la période ' || vv_period_name_cours|| ' pour la société '||ledger.short_name || ' (' || ledger.name || ')'); --RBE artf2055421
        ELSE
            put_line_out('Traitement de la période ' || vv_period_name_except || ' à la période ' || vv_period_name_cours || ' pour la société '||ledger.short_name|| ' (' || ledger.name || ')'); --RBE artf2055421
            put_line_log('Traitement de la période ' || vv_period_name_except || ' à la période ' || vv_period_name_cours || ' pour la société '||ledger.short_name|| ' (' || ledger.name || ')'); --RBE artf2055421
        END IF;
        -- Fin Modif GV20041119
        put_line_out ('');
        put_line_log ('');
		--- 02/07/2013 BCO INC000000425356 - ajout de l'identifiant de l'entête.
        put_line_out ('   ' || RPAD ('Id Entête', 11) || ' ' || RPAD ('Pièce GL', 60) || ' ' || RPAD ('Ligne', 7) || ' ' || RPAD ('Clé Comptable', 55) || ' ' || RPAD ('Montant Débit', 15) || ' ' || RPAD ('Montant Crédit', 16) || ' ' || 'Résultat');
        put_line_out ('   ' || RPAD ('=', 11, '=') || ' ' || RPAD ('=====', 60, '=') || ' ' || RPAD ('=', 7, '=') || ' ' || RPAD ('=', 55, '=')  || ' ' || RPAD ('=', 15, '=')  || ' ' || RPAD ('=', 16, '=') || ' ' || RPAD ('=', 40, '='));
        -- Pour chaque ligne GL à traiter
        FOR rec_gl_je_lines IN cur_gl_je_lines (pn_set_of_books_id => ledger.ledger_id --gn_set_of_books_id
        ) -- OBE
        LOOP
            BEGIN
                -- On pose un point d'arrêt pour les rollbacks
                SAVEPOINT dka_spacutoffgl_new_line_gl;
                -- On initialise le n° de séquence identifiant
                vv_spacutoff_seq_num                      :=    TO_CHAR (rec_gl_je_lines.je_header_id)
                                                            -- || '_' || TO_CHAR (rec_gl_je_lines.je_line_num)  -- SELO : EDB259
															 ;
															 
				vv_spacutoff_lig_num                      :=    -- TO_CHAR (rec_gl_je_lines.je_header_id)|| '_' ||  -- SELO : EDB259
																TO_CHAR (rec_gl_je_lines.je_line_num);											 
															 
															 
                -- SELECT  dka_spacutoff_s.NEXTVAL
                -- INTO    vn_spacutoff_seq_num
                -- FROM    DUAL;        
                
                -- On initialise les infos nécessaires
                -- Date GL ramenée en fin de mois
                --vd_gl_date := DKA_TOOLS_PKG.get_gl_period_date_f (
                --                          pd_ref_date           => rec_gl_je_lines.default_effective_date
                --                         ,pn_set_of_books_id    => gn_set_of_books_id
                --                    ) ;
                    
                vd_gl_date                                := /*LAST_DAY (*/rec_gl_je_lines.default_effective_date/*)*/;
                Dka_Tools_Pkg.put_debug_message ('vd_gl_date = ' || vd_gl_date);
                -- Date PA ramenée en fin de mois
                vd_pa_date                                := vd_gl_date;   --!!!
                Dka_Tools_Pkg.put_debug_message ('vd_pa_date = ' || vd_pa_date);
                vn_contrep_ccid                           := get_contrep_ccid_f (
                                                                pv_segment1       => rec_gl_je_lines.ccid_segment1,
																                                pv_segment2       => rec_gl_je_lines.ccid_segment2, -- PHENIX 2004
                                                                pd_gl_date        => vd_gl_date,
                                                                pn_ledger_id      => ledger.ledger_id --RBE artf2055421
                                                            );
                vv_company_code                           := rec_gl_je_lines.ccid_segment1; -- PHENIX 2004
                vv_region                                 := rec_gl_je_lines.ccid_segment2; -- OBE
                --vn_cost_center_org_id                   := get_org_id_f (pv_org_name => rec_gl_je_lines.ccid_segment6); -- PHENIX 2004
                vn_cost_center_org_id                     := rec_gl_je_lines.project_org_id;
                
                -- Formattage de la zone des quantités
                -- Si la capacité est supérieure 5 décimale
                -- On tombe dans l'exception invalid_number.
				-- SELECT TO_NUMBER (round(rec_gl_je_lines.quantity,5), '999999999999D99999', 'NLS_NUMERIC_CHARACTERS=.,') ARA ExaCC
				SELECT round(fnd_number.canonical_to_number(rec_gl_je_lines.quantity),5) --ARA ExaCC
                INTO   vn_quantity
                FROM   gl_je_lines t
                WHERE  t.ROWID = rec_gl_je_lines.ROWID;
                IF rec_gl_je_lines.project_id_refac IS NOT NULL
                THEN
                    vv_attribute_category    := gv_gl_refac_attribute_category;
                ELSE
                    vv_attribute_category    := gv_gl_attribute_category;
                END IF;
                -- On initialise les champs référence de la ligne GL
                rec_gl_je_lines.reference_1               :=    rec_gl_je_lines.code_combination_id
                                                             || '-'
                                                             || TO_DATE (vd_gl_date, 'DD-MON-RR');
 --ADR le 29/03/04                                           || '-'
                                                             --||
                                                                -- gv_spacutoff_prefixe ||
                                                                --vv_spacutoff_seq_num;
                rec_gl_je_lines.reference_6               := rec_gl_je_lines.reference_1;
                rec_gl_je_lines.reference_2               := vn_contrep_ccid;
                IF rec_gl_je_lines.event_type IS NOT NULL
                THEN
                    rec_gl_je_lines.reference_3    := gv_gl_reference_revenue;
                ELSIF rec_gl_je_lines.expenditure_type IS NOT NULL
                THEN
                    rec_gl_je_lines.reference_3    := gv_gl_reference_cost;
                ELSE
                    gn_retcode    := 2;
                    -- Ni le type d'évenement ni le type de dépense ne sont renseignés dans le CUF de la ligne GL
                    gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E020');
                    RAISE e_trt;
                END IF;
                -- On initialise le champ qui indique que la ligne a été traitée
                rec_gl_je_lines.cutoff_transfer_status    := rec_gl_je_lines.je_header_id || cv_delim_cuf || gn_request_id;
                -- CAS D'UNE DEPENSE PA
                IF rec_gl_je_lines.expenditure_type IS NOT NULL
                THEN
                    put_line_log ('CAS D UNE DEPENSE PA');
                    -- On recherche l'id de la tâche '1' du projet
                    vn_task_id                  := rec_gl_je_lines.task_id; --get_task_id_f (pn_project_id => rec_gl_je_lines.project_id);  -- OBE
                    Dka_Tools_Pkg.put_debug_message ('vn_task_id = ' || vn_task_id);
                    -- On cherche l'unité de mesure du type de dépense
                    get_expenditure_type_info (
                        pv_expenditure_type       => rec_gl_je_lines.expenditure_type,
                        pd_ref_date               => vd_gl_date,
                        pv_unit_of_measure        => vv_unit_of_measure
                    );
                    -- Si la pièce est issue d'une contrepassation...
                    IF rec_gl_je_lines.accrual_rev_je_header_id IS NOT NULL
                    THEN
                        -- On inverse le signe de la quantité
                        IF vn_quantity IS NOT NULL
                        THEN
                            vn_quantity    := vn_quantity * (-1);
                        END IF;
                    END IF;
                    -- Si la quantité est nulle ou unité de mesure = EUR, on l'alimente avec le montant des coûts directs
                    IF    vn_quantity IS NULL
                       OR vv_unit_of_measure = 'EUR'
                    THEN
                        vn_quantity    := rec_gl_je_lines.raw_cost;
                    END IF;
                    -- La quantité doit être du même signe que le raw_cost
                    vn_quantity    := ABS (vn_quantity) * SIGN (rec_gl_je_lines.raw_cost);
                    -- Détermination des coûts complets
                    vn_burden_cost              := get_burden_cost_f (
                                                      pn_org_id                            => rec_gl_je_lines.org_id,
                                                      pn_task_id                           => vn_task_id,
                                                      pd_ref_date                          => vd_gl_date,
                                                      pv_expenditure_type                  => rec_gl_je_lines.expenditure_type,
                                                      pn_expenditure_organization_id       => vn_cost_center_org_id,
                                                      pn_raw_cost                          => rec_gl_je_lines.raw_cost
                                                  );
                    Dka_Tools_Pkg.put_debug_message ('raw_cost = ' || rec_gl_je_lines.raw_cost);
                   
					-- Calcul des coûts directs 
                    IF rec_gl_je_lines.devise_projet = rec_gl_je_lines.devise_transaction THEN
                          vn_raw_cost := rec_gl_je_lines.raw_cost_2;
                    ELSIF rec_gl_je_lines.devise_projet = rec_gl_je_lines.devise_comptable THEN
                          vn_raw_cost := rec_gl_je_lines.raw_cost;
				   
                    ELSE
                          -- Calcul du raw cost
                          BEGIN
                            SELECT CONVERSION_RATE
                            INTO vn_rate
                            FROM GL_DAILY_RATES
                            WHERE UPPER(CONVERSION_TYPE) = 'CORPORATE'
                            AND FROM_CURRENCY     = rec_gl_je_lines.devise_transaction
                            AND TO_CURRENCY       = rec_gl_je_lines.devise_projet 
                            AND CONVERSION_DATE   = rec_gl_je_lines.CURRENCY_CONVERSION_DATE
                            ;
                          EXCEPTION
                            WHEN OTHERS THEN
                                  vn_rate := 1;
                                  Dka_Tools_Pkg.put_debug_message ('Taux de change introuvable');
                          END;
                          
                          vn_raw_cost := rec_gl_je_lines.raw_cost_2 * vn_rate;
                          
                    END IF;
                    
                    -- Insertion d'un enregistrement dans PA_EXPENDITURE_GROUPS
                    Dka_Tools_Pkg.put_debug_message ('Before Ins_Pa_Expend_Groups');
                    ins_pa_expend_groups (
                        pv_company_code            => vv_company_code,
                        pv_region                  => vv_region,         -- OBE
                        pn_org_id                  => rec_gl_je_lines.org_id,
                        pd_gl_date                 => vd_gl_date,
                        pv_expenditure_group       => vv_expenditure_group
                    );
                    -- Insertion d'un enregistrement dans PA_EXPENDITURES_ALL
                    Dka_Tools_Pkg.put_debug_message ('Before Ins_Pa_Expenditures');
                    ins_pa_expenditures (
                        pv_expenditure_group                 => vv_expenditure_group,
                        pd_gl_date                           => vd_gl_date,
                        pn_expenditure_organization_id       => vn_cost_center_org_id,
                        pn_org_id                            => rec_gl_je_lines.org_id,
                        pn_expenditure_id                    => vn_expenditure_id,
						pn_currency_code                     => rec_gl_je_lines.devise_transaction
                    );
                    -- Insertion d'un enregistrement dans PA_EXPENDITURE_ITEMS_ALL
                    Dka_Tools_Pkg.put_debug_message ('Before Ins_Pa_Expend_Items');
                    ins_pa_expend_items (
                        pn_expenditure_id                    => vn_expenditure_id,
                        pv_expenditure_type                  => rec_gl_je_lines.expenditure_type,
                        pn_expenditure_organization_id       => vn_cost_center_org_id,
                        pn_project_id                        => rec_gl_je_lines.project_id,
                        pn_task_id                           => rec_gl_je_lines.task_id, --vn_task_id,   -- OBE
                        pn_raw_cost                          => vn_raw_cost, --rec_gl_je_lines.raw_cost, -- OBE
                        pn_burden_cost                       => vn_burden_cost,
                        pn_quantity                          => vn_quantity,
                        pn_project_id_refac                  => rec_gl_je_lines.project_id_refac,
                        pn_task_id_refac                     => rec_gl_je_lines.task_id_refac,           -- OBE
                        pv_orig_transaction_reference        => vv_spacutoff_seq_num,
						pv_spacutoff_lig_num				 => vv_spacutoff_lig_num,                    -- SELO : EDB259
                        pd_gl_date                           => vd_gl_date,
                        pn_org_id                            => rec_gl_je_lines.org_id,
                        pv_attribute_category                => vv_attribute_category,
                        pv_description                       => rec_gl_je_lines.description,
                        pn_expenditure_item_id               => vn_expenditure_item_id,
						pn_currency_code                     => rec_gl_je_lines.devise_transaction
                    );
                    -- Insertion d'un enregistrement dans PA_COST_DISTRIBUTION_LINES_ALL
                    Dka_Tools_Pkg.put_debug_message ('Before Ins_Pa_Cost_Distrib_Lines');
                    ins_pa_cost_distrib_lines (
                        pn_expenditure_item_id          => vn_expenditure_item_id,
                        pn_project_id                   => rec_gl_je_lines.project_id,
                        pn_task_id                      => rec_gl_je_lines.task_id, --vn_task_id,   -- OBE
                        pn_dr_code_combination_id       => rec_gl_je_lines.code_combination_id,
                        pn_cr_code_combination_id       => vn_contrep_ccid,
                        pn_raw_cost                     => vn_raw_cost,--rec_gl_je_lines.raw_cost,  -- OBE
                        pn_burden_cost                  => vn_burden_cost,
                        pn_quantity                     => vn_quantity,
                        pv_batch_name                   => rec_gl_je_lines.reference_6,
                        pd_gl_date                      => vd_gl_date,
                        pd_pa_date                      => vd_pa_date,
                        pn_org_id                       => rec_gl_je_lines.org_id,
                        pn_ledger_id                    => ledger.ledger_id,                         -- OBE
						pn_currency_code                     => rec_gl_je_lines.devise_transaction
                    );
                -- CAS D'UN EVENEMENT DE PRODUIT PA
                ELSIF rec_gl_je_lines.event_type IS NOT NULL
                THEN
                    put_line_log ('CAS D UN EVENEMENT DE PRODUIT PA');
                    Dka_Tools_Pkg.put_debug_message ('Before DKA_TOOLS_PKG.pa_insert_event');
                    
					
					
					
                    -- Calcul du Montant de produits 
                    IF rec_gl_je_lines.devise_projet = rec_gl_je_lines.devise_transaction THEN
                          vn_event_amount := rec_gl_je_lines.event_amount_2;
                    ELSIF rec_gl_je_lines.devise_projet = rec_gl_je_lines.devise_comptable THEN
                          vn_event_amount := rec_gl_je_lines.event_amount;
				 
                    ELSE
                          BEGIN
                            SELECT CONVERSION_RATE
                            INTO vn_rate
                            FROM GL_DAILY_RATES
                            WHERE UPPER(CONVERSION_TYPE) = 'CORPORATE'
                            AND FROM_CURRENCY     = rec_gl_je_lines.devise_transaction
                            AND TO_CURRENCY       = rec_gl_je_lines.devise_projet 
                            AND CONVERSION_DATE   = rec_gl_je_lines.CURRENCY_CONVERSION_DATE
                            ;
                          EXCEPTION
                            WHEN OTHERS THEN
                                  vn_rate := 1;
                                  Dka_Tools_Pkg.put_debug_message ('Taux de change introuvable');
                          END;
                          
                          vn_event_amount := rec_gl_je_lines.event_amount_2 * vn_rate;
                          
                    END IF;
                    
                    --Dka_Tools_Pkg.pa_insert_event (     -- OBE
                    DKA_PA_TOOLS_PKG.pa_insert_event (
                        pv_event_type                  => rec_gl_je_lines.event_type,
                        pn_amount                      => vn_event_amount, --rec_gl_je_lines.event_amount,            -- OBE
                        pn_project_id                  => rec_gl_je_lines.project_id,                                 
                        pn_task_id                     => rec_gl_je_lines.task_id,                                    -- OBE
                        pn_event_organization_id       => vn_cost_center_org_id,                                      
                        pd_completion_date             => vd_gl_date,        -- OBE
                        pn_group_id                    => NULL,
                        pv_insert_revenue_flag         => 'Y',
                        pv_insert_into_gl              => 'N',
                        pn_unbilled_ccid               => vn_contrep_ccid,
                        pn_ccid                        => rec_gl_je_lines.code_combination_id,
                        pv_batch_name                  => rec_gl_je_lines.reference_6,
                        pv_description                 => NVL(rec_gl_je_lines.description,rec_gl_je_lines.event_type), -- OBE
                        pv_event_attr_context          => vv_attribute_category,
                        pv_event_attribute1            => rec_gl_je_lines.project_id_refac,
                        pv_event_attribute2            => NULL,                                                        -- OBE
                        --pv_event_attribute2            => rec_gl_je_lines.task_id_refac,                             -- OBE
                        pv_event_attribute3            => NULL,                                                        
                        pv_event_attribute4            => NULL,                                                        
                        pv_event_attribute5            => vv_spacutoff_seq_num,    
                        pv_event_attribute7            => rec_gl_je_lines.task_id_refac,                               -- OBE
						pv_event_attribute8            => vv_spacutoff_lig_num,                                        -- SELO : EDB259
                        pn_org_id                      => rec_gl_je_lines.org_id,
                        pv_errbuf                      => gv_errbuf,
                        pn_result                      => gn_retcode
                    );
                    IF gn_retcode != 0
                    THEN
                        gv_errbuf    := 'DKA_TOOLS_PKG.pa_insert_event:' || gv_errbuf;
                        RAISE e_trt;
                    END IF;
                END IF;
                -- On met à jour la ligne GL pour signifier qu'elle a été traitée
                Dka_Tools_Pkg.put_debug_message ('Before UPDATE  gl_je_lines gjl');
                UPDATE gl_je_lines gjl
                SET gjl.attribute16 = rec_gl_je_lines.cutoff_transfer_status,
                    gjl.reference_1 = rec_gl_je_lines.reference_1,
                    gjl.reference_2 = rec_gl_je_lines.reference_2,
                    gjl.reference_3 = rec_gl_je_lines.reference_3,
                    gjl.reference_6 = rec_gl_je_lines.reference_6,
                    gjl.last_update_date = SYSDATE,
                    gjl.last_updated_by = gn_user_id
                WHERE      gjl.je_header_id = rec_gl_je_lines.je_header_id
                       AND gjl.je_line_num = rec_gl_je_lines.je_line_num;
                -- Affichage message + incrémentation du nbre de lignes traitées avec succès
                --- 02/07/2013 BCO INC000000425356 - ajout de l'identifiant de l'entête.
				put_line_out (
                       '++ '
                    || RPAD (rec_gl_je_lines.je_header_id, 11)
                    || ' '
					|| RPAD (SUBSTR (rec_gl_je_lines.gjh_name, 1, 60), 60)
					|| ' '
                    || RPAD (rec_gl_je_lines.je_line_num, 7)
                    || ' '
					|| RPAD (rec_gl_je_lines.concatenated_segments, 55)
                    || ' '
					|| RPAD (nvl(rec_gl_je_lines.accounted_dr,0), 15)
                    || ' '
					|| RPAD (nvl(rec_gl_je_lines.accounted_cr,0), 16)
					|| ' '
                    || 'OK'
                );
                ln_nb_ok                                  := ln_nb_ok + 1;
                Dka_Tools_Pkg.put_debug_message ('End of Loop');
            EXCEPTION
                WHEN INVALID_NUMBER
                THEN
                    ROLLBACK TO SAVEPOINT dka_spacutoffgl_new_line_gl;
                    ln_nb_ko     := ln_nb_ko + 1;
					--- 02/07/2013 BCO INC000000425356 - ajout de l'identifiant de l'entête.
                    gv_errbuf    :=    '-- '
                                    || RPAD (rec_gl_je_lines.je_header_id, 11)
									|| ' '
									|| RPAD (SUBSTR (rec_gl_je_lines.gjh_name, 1, 60), 60)
									|| ' '
                                    || RPAD (rec_gl_je_lines.je_line_num, 7)
									|| ' '
									|| RPAD (rec_gl_je_lines.concatenated_segments, 55)
									|| ' '
									|| RPAD (nvl(rec_gl_je_lines.accounted_dr,0), 15)
									|| ' '
									|| RPAD (nvl(rec_gl_je_lines.accounted_cr,0), 16)
									|| ' '
                                    || 'ERROR -> '
                                    || 'Quantité ayant plus de 5 décimales';
                    put_line_log (gv_errbuf);
                    put_line_out (gv_errbuf);
                WHEN e_trt
                THEN
                    ROLLBACK TO SAVEPOINT dka_spacutoffgl_new_line_gl;
                    ln_nb_ko     := ln_nb_ko + 1;
					--- 02/07/2013 BCO INC000000425356 - ajout de l'identifiant de l'entête.
                    gv_errbuf    :=    '-- '
                                    || RPAD (rec_gl_je_lines.je_header_id, 11)
                                    || ' '
									|| RPAD (SUBSTR (rec_gl_je_lines.gjh_name, 1, 60), 60)
									|| ' '
                                    || RPAD (rec_gl_je_lines.je_line_num, 7)
									|| ' '
									|| RPAD (rec_gl_je_lines.concatenated_segments, 55)
									|| ' '
									|| RPAD (nvl(rec_gl_je_lines.accounted_dr,0), 15)
									|| ' '
									|| RPAD (nvl(rec_gl_je_lines.accounted_cr,0), 16)
									|| ' '
                                    || 'ERROR -> '
                                    || gv_errbuf;
                    put_line_log (gv_errbuf);
                    put_line_out (gv_errbuf);
                WHEN OTHERS
                THEN
                    ROLLBACK TO SAVEPOINT dka_spacutoffgl_new_line_gl;
                    gv_errbuf    := 'DKA_IBDAPPART_PKG.transfer_from_gl_to_pa loop:' || SQLERRM;
					--- 02/07/2013 BCO INC000000425356 - ajout de l'identifiant de l'entête.
                    gv_errbuf    :=    '-- '
                                    || RPAD (rec_gl_je_lines.je_header_id, 11)
                                    || ' '
									|| RPAD (SUBSTR (rec_gl_je_lines.gjh_name, 1, 60), 60)
									|| ' '
                                    || RPAD (rec_gl_je_lines.je_line_num, 7)
									|| ' '
									|| RPAD (rec_gl_je_lines.concatenated_segments, 55)
									|| ' '
									|| RPAD (nvl(rec_gl_je_lines.accounted_dr,0), 15)
									|| ' '
									|| RPAD (nvl(rec_gl_je_lines.accounted_cr,0), 16)
									|| ' '
                                    || 'ERROR -> '
                                    || gv_errbuf;
                    put_line_log (gv_errbuf);
                    put_line_out (gv_errbuf);
                    ln_nb_ko     := ln_nb_ko + 1;
            END;   -- -- Pour chaque ligne GL à traiter
        END LOOP;   -- -- Pour chaque ligne GL à traiter
        -- Fin normale
        
        END LOOP; -- Fin Ledger
        
        
        COMMIT;
        IF ln_nb_ko != 0
        THEN
            IF ln_nb_ok = 0
            THEN
                pn_retcode    := 2;   -- Erreur  -- Modif TB le 03/10/05 
            ELSE
                pn_retcode    := 1;   -- Warning
            END IF;
        ELSE
            pn_retcode    := 0;   -- Succès
        END IF;
        pv_errbuf    := NULL;
        put_line_out ('');
        put_line_out ('Nombre de lignes GL traitées avec SUCCES :' || ln_nb_ok);
        put_line_out ('Nombre de lignes GL en ECHEC             :' || ln_nb_ko);
        put_line_log ('');
        put_line_log ('Nombre de lignes GL traitées avec SUCCES :' || ln_nb_ok);
        put_line_log ('Nombre de lignes GL en ECHEC             :' || ln_nb_ko);
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
            pv_errbuf     := 'DKA_SPACUTOFFGL_PKG.transfer_from_gl_to_pa' || SQLERRM;
    END transfer_from_gl_to_pa;
END Dka_Spacutoffgl_Pkg;   -- Package body
/
SHOW ERRORS
EXIT
