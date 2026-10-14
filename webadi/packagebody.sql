--------------------------------------------------------
--  Fichier créé - mercredi-octobre-14-2026   
--------------------------------------------------------
--------------------------------------------------------
--  DDL for Package Body DKA_SPACUTOFFGL_PKG
--------------------------------------------------------

  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "WEBADI"."DKA_SPACUTOFFGL_PKG" 
AS
----------------------------------------------------------------------------------------------
-- NOM               : WEBADI.DKA_SPACUTOFFGL_PKG.pkb
-- DESCRIPTION       : WEBADI.DKA_SPACUTOFFGL_PKG package body : spécifique CUTOFF GL/PA
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
---              modification des fonctions get_calc_segment1_f, get_calc_segment2_f, get_calc_segment4_f
---          get_calc_segment5_f, get_calc_segment6_f, get_calc_segment7_f, get_calc_segment8_f
---           ajout des fonctions get_calc_segment9_f et get_calc_segment10_f
---           procedure get_contrep_ccid_f : ajout d'un argument pv_segment2
---           procedure transfer_from_gl_to_pa : modification de l'appel à get_contrep_ccid_f
---           procedure controler_line_gl ; ajout des segments 9 et 10 + vv_segment1_acct_area + vv_segment1_company_code
--- 11/02/2005 CDE Report de maintenance PHENIX 2005
---              - 19/11/2004 GV  transfer_from_gl_to_pa : ajout de la notion de periode dans le curseur cur_gl_je_lines
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
-- 13/11/2007  GV  version allégée pour WebAdi
-- 27/11/2007  TB  controler_line_gl : mise en commentaire de la recherche de l'id de la ccid
-- 27/03/2009  TB  Optimisation des contrôles pour DKA WebAdi
-- 20/03/2010  TB  Contrôle de la version de WebADI : tab_get_context_cuf
-- 29/11/2016  TBO Version du package pour WebADI R12
-- 13/01/2017  MEG Modification : EDB Evolution pour passage dune immos en cours sur un projet non invest sur un projet dinvest
-- 23/01/2017  MEG Modification : EDB Evolution sur le matricule
-- 09/02/2017  YWA artf2098310
-- 12/09/2017  OBE artf2222143 : SPE117 - Outil de saisie GL - Lié à modif du SPE048 pour defect ORACLE_R12 #920
-- 03/11/2023  ARA EDB281 - DGE20210006 - Alimentation du segment5 de la clé comptable
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
    gv_default_task_number           apps.pa_tasks.task_number%TYPE                        := '1';
    gv_spacutoff_prefixe             VARCHAR2 (30)                                    := 'DKA_SPACUTOFF_';
    gv_gl_reference_revenue          VARCHAR2 (30)                                    := 'Revenue - Event Revenue';
    gv_gl_reference_cost             VARCHAR2 (30)                                    := 'Cost';
    gn_current_org_id                apps.hr_all_organization_units.organization_id%TYPE;
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
    gn_set_of_books_id               apps.gl_sets_of_books.set_of_books_id%TYPE;
    gn_ledger_id                     apps.gl_ledgers.ledger_id%TYPE;                   -- OBE
    gn_sob_chart_of_accounts_id      apps.gl_sets_of_books.chart_of_accounts_id%TYPE;
    gn_seg3_flex_value_set_id        apps.fnd_flex_value_sets.flex_value_set_id%TYPE;
    gv_seg3_flex_value_set_name      apps.fnd_flex_value_sets.flex_value_set_name%TYPE;
    gv_project_type_refac            apps.pa_project_types_all.project_type%TYPE;
    -- Variables pour optimiser la recherche dans la proc get_context_cuf
    gv_user_je_category_name         apps.gl_je_categories.user_je_category_name%TYPE;
    gv_account                       apps.gl_code_combinations.segment1%TYPE;
    gv_context_cuf_gljl              apps.gl_je_lines.context3%TYPE;
    gv_project_type_invest           apps.pa_project_types_all.project_type%TYPE;

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
        apps.Fnd_File.put_line (apps.Fnd_File.LOG, pv_buffer);
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
        apps.Fnd_File.put_line (apps.Fnd_File.output, pv_buffer);
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
        rec_param   apps.dka_parameters%ROWTYPE;
    BEGIN
        apps.Dka_Tools_Pkg.get_parameter (pv_prog_code, pv_parameter, rec_param, gn_retcode, gv_errbuf);
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
        rec_param   apps.dka_parameters%ROWTYPE;
    BEGIN
        gn_retcode    := NULL;
        gv_errbuf     := NULL;
        -- On recherche le set of books id


        IF /*gn_set_of_books_id*/ gn_ledger_id IS NULL
        THEN

            gn_ledger_id := TO_NUMBER(webadi.DKA_TOOLS_PKG.FND_PROFILE_VALUE('GL_SET_OF_BKS_ID')); -- OBE

            SELECT distinct sob.chart_of_accounts_id
            INTO   gn_sob_chart_of_accounts_id
            FROM   apps.gl_ledgers sob --gl_sets_of_books sob       -- OBE
            WHERE  --sob.set_of_books_id = gn_set_of_books_id; -- OBE
                   sob.ledger_id = gn_ledger_id;               -- OBE

        END IF;
        -- On recherche l'id et le nom du jeu de valeur du segment "compte local" de la clé GL

        IF gn_seg3_flex_value_set_id IS NULL
        THEN
            webadi.Dka_Tools_Pkg.get_flex_key_seg_value_set
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

        IF gv_project_type_refac IS NULL
        THEN
            webadi.Dka_Tools_Pkg.get_parameter (
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
            gn_user_id    := apps.Fnd_Global.user_id;
        END IF;
        IF gn_request_id IS NULL
        THEN
            gn_request_id    := apps.Fnd_Global.conc_request_id;
        END IF;
        IF gn_last_update_login IS NULL
        THEN
            gn_last_update_login    := apps.Fnd_Global.conc_login_id;
        END IF;
        IF gn_program_application_id IS NULL
        THEN
            gn_program_application_id    := apps.Fnd_Global.prog_appl_id;
        END IF;
        IF gn_program_id IS NULL
        THEN
            gn_program_id    := apps.Fnd_Global.conc_program_id;
        END IF;

        IF pv_prog = 'TRANSFER'
        THEN
            gv_currency_code               := get_param_varchar (pv_parameter => 'CURRENCY_CODE');
            gv_transaction_source          := get_param_varchar (pv_parameter => 'TRANSACTION_SOURCE');
            gv_expenditure_status_code     := get_param_varchar (pv_parameter => 'EXPENDITURE_STATUS_CODE');
            gv_expend_group_status_code    := get_param_varchar (pv_parameter => 'EXPENDITURE_GROUP_STATUS_CODE');
            gv_system_linkage_function     := get_param_varchar (pv_parameter => 'SYSTEM_LINKAGE_FUNCTION');
            gv_expenditure_class_code      := get_param_varchar (pv_parameter => 'EXPENDITURE_CLASS_CODE');
        END IF;   -- pv_prog = 'TRANSFER'

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
            gv_errbuf     := 'TB ' || 'DKA_SPACUTOFFGL_PKG.Init:' || SQLERRM;
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
        FROM   apps.fnd_flex_values_vl ffv
        WHERE      ffv.flex_value = pv_segment3
               AND ffv.flex_value_set_id = gn_seg3_flex_value_set_id;

        -- Controle que le compte local est compte de charge d'immo
        SELECT DECODE(COUNT(1), 0, 'N', 'Y')
          INTO pv_flag_compte_chg_immo
          FROM apps.fa_categories_vl fcv,
               apps.fa_category_books fcb
         WHERE EXISTS (SELECT 1
                         FROM apps.fa_book_controls_sec bc
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
          FROM apps.fnd_flex_value_sets ffvs, apps.fnd_flex_values ffv
         WHERE ffvs.flex_value_set_id = ffv.flex_value_set_id
           AND ffvs.flex_value_set_name = 'DKA_COMPTE_MATRICULE'
           AND ffv.flex_value = pv_segment3
           AND ffv.enabled_flag = 'Y'; --OBE artf2222143

    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
        FROM   apps.gl_je_categories gjc
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
               SUBSTR(haou.NAME,4)
        INTO   pv_project_code,
               pv_project_type,
               pv_proj_org_id,
               pv_proj_org_name
        FROM   apps.pa_projects_all pap,
               apps.hr_all_organization_units haou
        WHERE  pap.project_id = pn_project_id
        AND    pap.org_id = haou.organization_id   -- OBE
        AND    pd_ref_date BETWEEN pap.start_date AND NVL (pap.completion_date, pd_ref_date);

        -- FIN PHENIX 2004
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
        FROM   apps.pa_expenditure_types pet
        WHERE      pet.expenditure_type = pv_expenditure_type
               AND pd_ref_date BETWEEN pet.start_date_active AND NVL (pet.end_date_active, pd_ref_date);
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
        FROM   apps.pa_event_types pet
        WHERE      pet.event_type = pv_event_type
               AND pd_ref_date BETWEEN pet.start_date_active AND NVL (pet.end_date_active, pd_ref_date);
    EXCEPTION
        WHEN e_trt
        THEN
            RAISE;
        WHEN NO_DATA_FOUND
        THEN
            gn_retcode    := SQLCODE;
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
        vv_segment   apps.gl_code_combinations.segment1%TYPE;
    BEGIN

        --< OBE
        vv_segment    := webadi.dka_spaautoaccounting_pkg.uo_projet(pn_project_id => pn_project_id);
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
        pn_task_id              IN   NUMBER,  -- OBE
        pv_flag_compte_chg_immo IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        vv_segment   apps.gl_code_combinations.segment1%TYPE;
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

            vv_segment := webadi.dka_spaautoaccounting_pkg.CPT_LOCAL_COUTS(
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

            webadi.Dka_Pa_Tools_Pkg.pa_run_accounting_rule (
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
                gv_errbuf    := webadi.Dka_Tools_Pkg.GET_MESSAGE (
                                   pv_application       => 'DKA',
                                   pv_name              => 'DKA_SAPCUTOFFGL_E103',
                                   pv_token1            => 'TYPE_DEPENSE',
                                   pv_value1            => pv_expenditure_type || ' (' || vv_segment || ') ',
                                   pv_token2            => 'COMPTE_LOCAL',
                                   pv_value2            => pv_segment3_orig
                               );
            ELSE
                gv_errbuf    := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
--  PHENIX 2004   :   cette fonction est l'ancienne get_calc_segment2_f
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
        vv_segment   apps.gl_code_combinations.segment1%TYPE;
    BEGIN
        -- Compte de charge
        IF pv_account_type = 'E' OR pv_flag_compte_chg_immo = 'Y'
        THEN
            vv_segment    := webadi.Dka_Spaautoaccounting_Pkg.run_cpt_groupe_couts_f (
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
                vv_event_type_class   apps.pa_event_types.event_type_classification%TYPE;
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
                vv_segment    := webadi.Dka_Spaautoaccounting_Pkg.run_cpt_groupe_produit_f (
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
--  PHENIX 2004   :   cette fonction est l'ancienne get_calc_segment5_f
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment6_f (
        pn_project_id   IN   NUMBER,
        pd_ref_date     IN   DATE
    )
        RETURN VARCHAR2
    IS
        vv_segment   apps.gl_code_combinations.segment1%TYPE;
    BEGIN
        --vv_segment    := Dka_Spaautoaccounting_Pkg.get_cost_center_f (pn_project_id => pn_project_id, pd_date => pd_ref_date); -- OBE
        vv_segment    := webadi.Dka_Spaautoaccounting_Pkg.centrefi (pn_project_id => pn_project_id);                                    -- OBE
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
--  PHENIX 2004   :   cette fonction est l'ancienne get_calc_segment6_f
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment7_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2
    IS
        vv_segment   apps.gl_code_combinations.segment1%TYPE;
    BEGIN
        --< OBE
        /*Dka_Pa_Tools_Pkg.pa_run_accounting_rule (
            pv_rule_name           => 'CODE_D',
            pn_project_id          => pn_project_id,
            pv_segment_value       => vv_segment,
            pv_errbuf              => gv_errbuf,
            pn_retcode             => gn_retcode
        );*/
        vv_segment    := webadi.Dka_Spaautoaccounting_Pkg.affaire(pn_project_id => pn_project_id);
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
--  PHENIX 2004   :   cette fonction est l'ancienne get_calc_segment7_f
----------------------------------------------------------------------------------------
    FUNCTION get_calc_segment8_f (
        pn_project_id   IN   NUMBER
    )
        RETURN VARCHAR2
    IS
        vv_segment   apps.gl_code_combinations.segment1%TYPE;
    BEGIN
         --< OBE
        /*vv_segment    := Dka_Spaautoaccounting_Pkg.get_class_code_f (pn_project_id => pn_project_id,
                            pv_class_category       => 'NATURE_ACTIVITE');*/
        vv_segment    := webadi.Dka_Spaautoaccounting_Pkg.PROJETFI(pn_project_id => pn_project_id);
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
        vn_task_id   apps.pa_tasks.task_id%TYPE;
    BEGIN
        SELECT pt.task_id
        INTO   vn_task_id
        FROM   apps.pa_tasks pt
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
        vn_task_id   apps.pa_tasks.task_id%TYPE;
    BEGIN
        SELECT pt.task_id
        INTO   vn_task_id
        FROM   apps.pa_tasks pt
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
--  Nom           :  get_org_id_f
--  Description   :  renvoie l'id de l'org dont le nom est passé en paramètre
----------------------------------------------------------------------------------------
    FUNCTION get_org_id_f (
        pv_org_name   IN   VARCHAR2
    )
        RETURN NUMBER
    IS
        vn_organization_id   apps.hr_all_organization_units.organization_id%TYPE;
    BEGIN
        SELECT hou.organization_id
        INTO   vn_organization_id
        FROM   apps.hr_all_organization_units hou
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
        vv_project_code                apps.pa_projects_all.segment1%TYPE;
        vv_project_type                apps.pa_projects_all.project_type%TYPE;
        vv_proj_org_id                 apps.pa_projects_all.org_id%TYPE;
        vv_proj_org_name               apps.hr_all_organization_units.NAME%TYPE;
        vv_project_code_refac          apps.pa_projects_all.segment1%TYPE;
        vv_marge_amont                 VARCHAR2 (1); -- TB:13/09/2006
        -- projet à refacturer
        vv_project_type_refac          apps.pa_projects_all.project_type%TYPE;
        vv_proj_org_id_refac           apps.pa_projects_all.org_id%TYPE;
        vv_proj_org_name_refac         apps.hr_all_organization_units.NAME%TYPE;
        vv_unit_of_measure             apps.pa_expenditure_types.unit_of_measure%TYPE;
        vv_account_type                VARCHAR2 (1);
        vv_flag_compte_prov_cli        VARCHAR2 (1);
        vv_flag_tec_pca_cca            VARCHAR2 (1);
        vv_flag_compte_chg_immo        VARCHAR2 (1);
        vv_flag_matricule              VARCHAR2 (1);
        vv_flag_contrepass_auto        VARCHAR2 (1);
        vv_segment1_acct_area          VARCHAR2 (3);
        vv_segment1_company_code       VARCHAR2 (4);
        vv_project_name                apps.pa_projects_all.NAME%TYPE;
        vb_is_transaction_type_refac   BOOLEAN;
        test                           VARCHAR2(20);
        vv_type_projet                 VARCHAR2(20);

    -- = TRUE si type de dépense ou d'évenement est refacturable
    BEGIN
        --- appel de la procédure INIT pour l'initialisation de parametres globaux
        init;
        -- On extrait la société et le centre de gestion du segment1 et du segment2 resp.
        vv_segment1_acct_area       := pv_segment2_in; --  PHENIX 2004
        vv_segment1_company_code    := pv_segment1_in; -- PHENIX 2004
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
        ELSIF vv_context NOT IN ('Y.E.X', 'Y.R.X', 'FRAIS')
        THEN
            RAISE e_fin_normale;
        END IF;


        -- Recherche de la nature du compte local, de son flag "Compte provision client"
        -- et de son flag tec_pca_cca
        get_account_info(
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E001');
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
                    gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E100');
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E002');
            RAISE e_trt;
        -- L'événement produit doit être renseigné dans le CUF pour les imputations de produits
        ELSIF     vv_account_type = 'R'
              AND pv_event_type IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E003');
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
                gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            vv_type_projet := webadi.dka_spaautoaccounting_pkg.get_project_type_f(pn_project_id);

            -- On Verifie que le type de projet n'est pas Investissement
            IF vv_type_projet = gv_project_type_invest
            THEN
                gn_retcode    := 2;
                gv_errbuf     := Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E107');
                RAISE e_trt;
            END IF;

           -- On vérifie que le type de pièce n'est pas à contrepassation automatique
            webadi.Dka_gl_Tools_Pkg.gl_get_category_autorev_flag (
                pv_errbuf                      => gv_errbuf,
                pn_retcode                     => gn_retcode,
                pn_ledger_id                   => gn_ledger_id,  -- OBE
                pv_user_je_category_name       => pv_user_je_category_name,
                pv_autoreverse_flag            => vv_flag_contrepass_auto
            );
            IF gn_retcode != 0
            THEN
                gv_errbuf    := 'DKA_TOOLS_PKG.gl_get_category_autorev_flag:' || gv_errbuf;
                RAISE e_trt;
            END IF;

            -- si le type de pièce est à contrepassation automatique
            -- => erreur "" Refacturation automatique interdite pour les journaux à contre passation automatique.
            --              Choisissez un autre code projet ou un autre type de pièce "
            IF vv_flag_contrepass_auto = 'Y'
            THEN
                gn_retcode    := 2;
                gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (pv_application => 'DKA', pv_name => 'DKA_SAPCUTOFFGL_E101');
                RAISE e_trt;
            END IF;
            -- On vérifie que le type de dépense ou évenement produit est bien refacturable



            IF vv_account_type = 'E'
            THEN
                vb_is_transaction_type_refac    := TRUE;--Dka_Sarrefac_Pkg.is_transaction_type_refac (pv_transaction_type => pv_expenditure_type);
                IF NOT vb_is_transaction_type_refac
                THEN
                    gn_retcode    := 2;
                    gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
                                        pv_application       => 'DKA',
                                        pv_name              => 'DKA_SAPCUTOFFGL_E102',
                                        pv_token1            => 'TYPE',
                                        pv_value1            => 'de dépense'
                                    );
                    RAISE e_trt;
                END IF;
            ELSE
                vb_is_transaction_type_refac    := webadi.Dka_Sarrefac_Pkg.is_transaction_type_refac (pv_transaction_type => pv_event_type);
                IF NOT vb_is_transaction_type_refac
                THEN
                    gn_retcode    := 2;
                    gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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


                webadi.Dka_Pa_Tools_Pkg.pa_get_code_z_refac (
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
                    gv_errbuf    := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
                pv_message_info          := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
     webadi.DKA_PA_TOOLS_PKG.pa_check_transaction_data (
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
            webadi.DKA_PA_TOOLS_PKG.pa_check_transaction_data (
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
        webadi.Dka_Gl_Tools_Pkg.gl_get_category_autorev_flag (
            pv_errbuf                      => gv_errbuf,
            pn_retcode                     => gn_retcode,
            pn_ledger_id                   => gn_ledger_id,  -- OBE
            pv_user_je_category_name       => pv_user_je_category_name,
            pv_autoreverse_flag            => vv_flag_contrepass_auto
        );
        IF gn_retcode != 0
        THEN
            gv_errbuf    := 'DKA_TOOLS_PKG.gl_get_category_autorev_flag:' || gv_errbuf;
            RAISE e_trt;
        END IF;

        -- Si la catégorie est à contrepassation automatique, on valide les données à la date de contrepassation
        IF vv_flag_contrepass_auto = 'Y'
        THEN
            -- Contrôle de cohérence des données
            --< OBE
            webadi.DKA_PA_TOOLS_PKG.pa_check_transaction_data (
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
                webadi.DKA_PA_TOOLS_PKG.pa_check_transaction_data (
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
        pv_segment1_out             := get_calc_segment1_f (pv_segment1_orig => pv_segment1_in/*pn_project_id => pn_project_id, pd_ref_date => pd_gl_date*/);
        IF pv_segment1_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
                                          pn_task_id                => pn_task_id,    -- OBE
                                          pv_flag_compte_chg_immo   => vv_flag_compte_chg_immo
                                      ); -- PHENIX 2004
        IF pv_segment4_out IS NULL
        THEN
            gn_retcode    := 2;
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
            gv_errbuf     := webadi.Dka_Tools_Pkg.GET_MESSAGE (
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
                                       || pv_segment10_out  -- PHENIX 2004
                                       || '.'
                                       || pv_segment11_out  -- OBE
                                       || '.'
                                       || pv_segment12_out;  -- OBE

        webadi.Dka_Tools_Pkg.get_code_combination_id (
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
        cv_rb_context             CONSTANT VARCHAR2 (2) := 'RB';
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
        FROM apps.fnd_flex_values_vl ffv,
             apps.fnd_flex_value_sets ffvs
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
            webadi.Dka_Tools_Pkg.get_flex_key_seg_value_set
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
           --pv_context             := 'MAT'; --EDB281 ARA
		   pv_context             := NULL;
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

-----------------------------------------------------------------
-- NOM         : tab_get_context_cuf
-- DESCRIPTION : Procédure qui appel la procédure get_context_cuf pour un tableau
--               de paramètres
-----------------------------------------------------------------
   PROCEDURE tab_get_context_cuf (
        pv_user_je_category_name   IN       VARCHAR2,
        pt_retcode                 OUT      dka_cuf,
        pt_account                 IN       dka_cuf,
        pt_context                 OUT      dka_cuf,
        pv_version                 OUT      VARCHAR2
    )
    IS
  i                  NUMBER;
  pv_errbuf          VARCHAR2(200);
  pn_retcode         NUMBER;
  tv_context         VARCHAR2(200);

BEGIN
     FOR i IN pt_account.FIRST .. pt_account.LAST
     LOOP
          pv_errbuf  := NULL ;
          pn_retcode := 0 ;

          get_context_cuf(pv_errbuf,
                          pn_retcode,
                          pv_user_je_category_name,
                          pt_account(i),
                          tv_context);

          /*IF tv_context IS NOT NULL THEN
             pt_context(i) := tv_context;
             pt_retcode(i) := 0;
          ELSE
             pt_context(i) := pv_errbuf;
             pt_retcode(i) := 1;
          END IF;*/
		  --< EDB281 ARA
		  IF tv_context IS NOT NULL THEN
			pt_context(i) := tv_context;
			pt_retcode(i) := 0;
		  ELSE
			IF pn_retcode = 0 THEN
			  pt_context(i) := NULL;
			  pt_retcode(i) := 0;
			ELSE
			  pt_context(i) := pv_errbuf;
			  pt_retcode(i) := 1;
			END IF;
		  END IF;
      -- EDB281>

     END LOOP;

    -- Contrôle de la version du DKA WebADI
    SELECT 'Version ' || DSL.PARAM1_VALUE || ' du ' || DSL.RETURN_VALUE AS VERSION
    INTO pv_version
    FROM DKA.DKA_STRANSCO_HEADERS DSH, DKA.DKA_STRANSCO_LINES DSL
    WHERE DSH.SET_ID = DSL.SET_ID
      AND DSH.SET_NAME = 'VERSION_WEBADI'
      AND SYSDATE BETWEEN START_DATE AND NVL(END_DATE,SYSDATE)
      AND ENABLE = 'Y';
END tab_get_context_cuf;

-----------------------------------------------------------------
-- NOM         : tab_controler_line_gl
-- DESCRIPTION : Procédure qui appel la procédure controler_line_gl pour un tableau
--               de paramètres
-----------------------------------------------------------------
   PROCEDURE tab_controler_line_gl (
        pv_user_je_category_name   IN       VARCHAR2,
        pd_gl_date                 IN       DATE,
        pt_segment1                IN OUT   dka_cuf,
        pt_segment2                IN OUT   dka_cuf,
        pt_segment3                IN OUT   dka_cuf,
        pt_segment4                IN OUT   dka_cuf,
        pt_segment5                IN OUT   dka_cuf,
        pt_segment6                IN OUT   dka_cuf,
        pt_segment7                IN OUT   dka_cuf,
        pt_segment8                IN OUT   dka_cuf,
        pt_segment9                IN OUT   dka_cuf,
        pt_segment10               IN OUT   dka_cuf,
        pt_segment11               IN OUT   dka_cuf,
        pt_segment12               IN OUT   dka_cuf,
        pt_project_id              IN OUT   dka_ncuf,
        pt_task_id                 IN OUT   dka_ncuf,
        pt_event_type              IN OUT   dka_cuf,
        pt_expenditure_type        IN OUT   dka_cuf,
        pt_quantity                IN OUT   dka_ncuf,
        pt_project_id_refac        IN OUT   dka_ncuf,
        pt_task_id_refac           IN OUT   dka_ncuf,
        pt_retcode                 OUT      dka_cuf,
        pt_retour                  OUT      dka_cuf
    )
    IS
  i                                NUMBER;
  pv_errbuf                        VARCHAR2(200);
  pn_retcode                       NUMBER;
  pn_ccid                          NUMBER;
  pv_concatenated_segs             VARCHAR2(200);
  pv_message_info                  VARCHAR2(200);

BEGIN
     FOR i IN pt_segment1.FIRST .. pt_segment1.LAST
     LOOP

          pv_errbuf  := 0 ;
          pn_retcode := NULL ;
          pt_project_id_refac(i) := NULL; -- Ajout TB du 30/03/2009

          webadi.dka_spacutoffgl_pkg.controler_line_gl(pv_errbuf,
                                                pn_retcode,
                                                pv_user_je_category_name,
                                                pd_gl_date,
                                                'D',
                                                pt_segment1(i),
                                                pt_segment2(i),
                                                pt_segment3(i),
                                                pt_segment4(i),
                                                pt_segment5(i),
                                                pt_segment6(i),
                                                pt_segment7(i),
                                                pt_segment8(i),
                                                pt_segment9(i) ,
                                                pt_segment10(i),
                                                pt_segment11(i),
                                                pt_segment12(i),
                                                pt_project_id(i) ,
                                                pt_task_id(i),
                                                pt_event_type(i) ,
                                                pt_expenditure_type(i),
                                                pt_quantity(i)  ,
                                                pt_project_id_refac(i) ,
                                                pt_task_id_refac(i),
                                                pt_segment1(i),
                                                pt_segment2(i),
                                                pt_segment3(i),
                                                pt_segment4(i),
                                                pt_segment5(i),
                                                pt_segment6(i),
                                                pt_segment7(i),
                                                pt_segment8(i) ,
                                                pt_segment9(i) ,
                                                pt_segment10(i),
                                                pt_segment11(i),
                                                pt_segment12(i),
                                                pv_concatenated_segs ,
                                                pn_ccid,
                                                pv_message_info);


          IF pn_retcode = 0 THEN
            pt_retcode(i) := pn_retcode;
            pt_retour(i):= pv_errbuf;
          ELSE
            pt_retcode(i) := pn_retcode;
            pt_retour(i):= pv_errbuf;
          END IF;

     END LOOP;

END tab_controler_line_gl;

-----------------------------------------------------------------
-- NOM         : tab_select
-- DESCRIPTION : Procédure qui appel lance une requète passé en paramètre
--                pour un tableau de données
-----------------------------------------------------------------
   PROCEDURE tab_select (
        pv_req                     IN       VARCHAR2,
        pd_date                    IN       DATE,
        pt_project                 IN       dka_cuf,
        pt_value                   IN OUT   dka_cuf,
        pt_retcode                 OUT      dka_cuf
    )
    IS
  i                  NUMBER;
  pv_errbuf          VARCHAR2(200);
  pn_retcode         NUMBER;
  pv_value           VARCHAR2(100);
  pv_retour          VARCHAR2(100);

  TYPE dynamic_cursor IS REF CURSOR;
  cur_req dynamic_cursor;

  vv_cur VARCHAR2(5000);
  vv_cur_depenses VARCHAR2(5000);
  vv_cur_produits VARCHAR2(5000);
  vv_cur_tache    VARCHAR2(5000);
  vv_cur_livre    VARCHAR2(5000);

BEGIN


     FOR i IN pt_value.FIRST .. pt_value.LAST
     LOOP

     /*vv_cur_depenses := 'SELECT PET.EXPENDITURE_TYPE AS C1 FROM APPS.PA_EXPENDITURE_TYPES_EXPEND_V PET' ||
                     ' WHERE PET.SYSTEM_LINKAGE_FUNCTION = ''PJ'' AND PET.EXPENDITURE_TYPE IN' ||
                     ' (SELECT PTC.EXPENDITURE_TYPE FROM APPS.PA_TRANSACTION_CONTROLS PTC, APPS.PA_TASKS PT' ||
                     '  WHERE PT.TASK_ID = ' || pt_project(i) ||
                     '  AND PT.LIMIT_TO_TXN_CONTROLS_FLAG = ''Y'' AND PTC.TASK_ID = PT.TASK_ID'||
                     '  AND SYSDATE BETWEEN PTC.START_DATE_ACTIVE AND NVL(PTC.END_DATE_ACTIVE, SYSDATE)' ||
                     '  UNION ALL' ||
                     '  SELECT PET.EXPENDITURE_TYPE FROM APPS.PA_EXPENDITURE_TYPES PET, APPS.PA_TASKS PT' ||
                     '  WHERE PT.TASK_ID = ' || pt_project(i) || ' AND PT.LIMIT_TO_TXN_CONTROLS_FLAG = ''N'' )' ||
                     ' AND SYSDATE BETWEEN PET.EXPND_TYP_START_DATE_ACTIVE AND NVL(PET.EXPND_TYP_END_DATE_ACTIVE, SYSDATE)' ||
                     ' AND PET.EXPENDITURE_TYPE = ';*/--YWA  artf2098310

        vv_cur_depenses :=  'SELECT PET.EXPENDITURE_TYPE AS C1 ' ||
                            'FROM APPS.PA_EXPENDITURE_TYPES_EXPEND_V PET ' ||
                            'WHERE PET.SYSTEM_LINKAGE_FUNCTION = ''PJ'' ' ||
                            'AND EXISTS ' ||
                                 '(SELECT ''x'' ' ||
                                 'FROM APPS.PA_TRANSACTION_CONTROLS PTC, APPS.PA_TASKS PT' ||
                                 ' WHERE PT.TASK_ID = ' || pt_project(i) ||
                                   ' AND PTC.EXPENDITURE_TYPE = PET.EXPENDITURE_TYPE' ||
                                   ' AND PT.LIMIT_TO_TXN_CONTROLS_FLAG = ''Y'' ' ||
                                   ' AND PTC.TASK_ID  = PT.TASK_ID ' ||
                                   ' AND PTC.PROJECT_ID = PT.PROJECT_ID ' ||
                                   ' AND SYSDATE BETWEEN PTC.START_DATE_ACTIVE AND NVL(PTC.END_DATE_ACTIVE, SYSDATE) ' ||
                                ' UNION ALL ' ||
                                ' SELECT ''X'' ' ||
                                ' FROM APPS.PA_EXPENDITURE_TYPES PET2, APPS.PA_TASKS PT' ||
                                ' WHERE PT.TASK_ID = ' || pt_project(i) ||
                                  ' AND PET2.EXPENDITURE_TYPE = PET.EXPENDITURE_TYPE' ||
                                  ' AND PT.LIMIT_TO_TXN_CONTROLS_FLAG = ''N'' )' ||
                            ' AND SYSDATE BETWEEN PET.EXPND_TYP_START_DATE_ACTIVE AND NVL(PET.EXPND_TYP_END_DATE_ACTIVE, SYSDATE)' ||
                            ' AND PET.EXPENDITURE_TYPE = ' ; --ywa artf2098310


     vv_cur_tache := 'SELECT TASK_ID FROM APPS.PA_TASKS WHERE PROJECT_ID = ' || pt_project(i) || ' AND TASK_NUMBER = ';

          pv_errbuf  := NULL;
          pn_retcode := 0;
          pv_value   := pt_value(i);

          IF pv_req = 'DEPENSE' THEN
             vv_cur :=   vv_cur_depenses || '''' || pt_value(i) || '''';
          ELSIF pv_req = 'TACHE' THEN
             vv_cur :=   vv_cur_tache || '''' || pt_value(i) || '''';
          ELSE
              vv_cur :=  pv_req || '''' || pt_value(i) || '''';
          END IF;

       IF pt_value(i) IS NULL THEN
          pt_retcode(i) := '0';
       ELSE
          OPEN cur_req FOR vv_cur;
          LOOP
              BEGIN
              FETCH cur_req INTO pv_retour;
                 IF cur_req%NOTFOUND THEN
                    --pt_value(i)  := 'Non trouvé';
                    pt_retcode(i) := '1';
                    EXIT;
                 ELSE
                     pt_value(i) := to_char(pv_retour);
                     pt_retcode(i) := '0';
                     EXIT;
                 END IF;
              END;
          END LOOP;
       END IF;

     END LOOP;

END tab_select;

END DKA_SPACUTOFFGL_PKG;   -- Package body

/
