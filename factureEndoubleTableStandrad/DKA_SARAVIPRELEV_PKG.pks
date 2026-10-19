DEFINE package_name = "DKA_SARSURTAXE_PKG";

--******************************************************************************************--
--***************** Ecriture du corps du package *******************************************--
--******************************************************************************************--

CREATE OR REPLACE PACKAGE BODY Dka_Sarsurtaxe_Pkg
AS
-------------------------------------------------------------------------------
-- CAPGEMINI
-- Projet : DALKIA Oracle Applications
-- Auteur : Guilhem LE NEZET
-- Date Création : 11/10/2001
-- Version livrables : V01
--------------------------------------------------------------------------------
-- NOM : dka_sarsurtaxe_pkg.sql
-- DESCRIPTION : Package du spécifique "surtaxe communale"
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 09/10/02   CD  Correction procédures INSERT_AR_INVOICES, INSERT_GL_INVOICES_GERICCO
--			          LOAD_REF_LET
-- 20/11/02   CD  Correction procédures INSERT_GL_INTERFACE
-- 18/04/03   CD  Modification de la gestion du segment2 - Ajout fonction get_segment2
-- 15/05/03   CD  Pour optimisation, ajout analyse stats après insertion dka_sarsurtaxe_tmp
--                + ajout row_id dans les update de la procédure load_ap_invoices_interfaces
--				        + Mise en commentaire de la phase insert_gl_invoices_gericco
-- 06/11/03   CD  Ajout des procédures pour l'état de contrôle des rejets (main6)
--	              + Modif INSERT_AR_INVOICES lien segment4 avec po_vendors
-- 10/12/03   CD  Ajout du N° de fournisseur dans l'état de contrôle
-- 07/04/04   CD  Ajout analyse stats sur gl_j_lines et headers dans main3
-- 20/07/04   STI Portage specifique PHENIX 2004
--                procedure init changement variable segment2 en variable segment4
--                procedure get_segment2 --> get_segment4  : changement du segment2 en segment 4
--                procedure insert_ar_invoices  ajout de 2 champs segment 9 et 10, changement segment 4 en segment5
--                procedure insert_gl_invoices_gericco ajout de 2 champs segment 9 et 10, segment4 -> segment5 et segment1 -> seg1 + seg2
--                procedure insert_ap_inv_lines_interface ajout de 2 segments ( 9 et 10)
--			          procedure load_ap_invoices_interfaces ajout de 2 segments
--			          procedure load_ref_let ajout de 2 segments et segment4 -> segment5
--			          procedure insert_dka_sarsurtaxe_ctl_tmp ajout de 2 segments et segment4 -> segment5  
--			          procedure controle_fournisseur_absent segment4 -> segment5
--			          procedure controle_fournisseur_doublon segment4 -> segment5
--		            procedure controle_site_frs_absent segment4 -> segment5 et segment1-> segment1 + segment2
--		            procedure controle_facture_negative segment4 -> segment5 et segment1-> segment1 + segment2
-- 13/06/05   CD  Report modif SOPRA du 09/06/05 : fonction get_vdr_account
-- 04/10/05   EMA Ajout de la procedure main7 qui permet le lancement des 
--                éditions par centre de gestion.
-- 22/11/05   CD  Correction Nbe copie (main7) + modif nom facture AP org_id => societe pr éviter mauvais regroupement
--                + controle factures négatives par société
-- 16/01/06   CD  Report modif du 22/06/04 sur procédure purge_dka_sarsurtaxe_tmp. 
--                Delete de toutes les lignes.
-- 16/10/2006 EMA Le calcul des statistiques devient obsolète
-- 14/05/2008 CD  Procedure load_ref_let : Modif paramètre 3 de update_gl_je_lines -
--                vv_description_segment5 remplacé par vv_nom_fournisseur
-- 16/04/2012 JJA lors de Récupération du code TVA exonérée de la société 
--                on ne prend que le nom de TVA de débit
--------------------------------------------------------------------------------
-- 15/08/2016 OBE Migration R12
-- 27/02/2017 OBE Modification - artf2097138
-- 12/07/2017 OBE artf2194455 : SPE021 - Surtaxe Communale - Facture AP en Erreur - N° Ligne en Double - Defect BeB 953
-- 25/07/2017 OBE artf2202215 : SPE021_Surtaxe - Defect 1006 - Dans les logs on retrouve des indicateurs concernant l extraction GL Gerrico
--                artf2202658 : SPE021 : Insertions des lignes SURTAXE OD dans GL - Ne pas créer les lignes dont le montant = Zero - Defect 10005
--                artf2202695 : SPE021 : Etat Editions surtaxe communale DKA_SARSURTAXE_RDF - Defect 1003  
--                artf2202971 : SPE021 : Ajout de la Référence de Lettrage sur la ligne de 467300 pour les mouvements AR sélectionné par la REFAC
-- 01/08/2017 OBE artf2205925 : SPE021 : Lancement de la validation des factures
--                artf2205931 : SPE021 : Lancement du traitement Rapprochement - Rapprochement automatique
-- 02/08/2017 OBE artf2206496 : SPE021 - Etat de contrôle de la surtaxe - Modification de la fonction contrôle facture négative
-- 09/08/2017 OBE artf2210354 : SPE021 - Traitement Surtaxe - Lettrage des mouvements de Surtaxe - defect BeB #1004
-- 11/08/2017 OBE artf2211298 : SPE021 - Surtaxe communale - Il y a des valeurs codés en dur au niveau des comptes
-- 17/08/2017 MEG artf2212301 : SPE021 - Surtaxe communale - Créer une comptabilisation - BeB Defect # 1047
-- 04/09/2017 OBE artf2215399 : SPE021 : Traitement de surtaxe Communale 
-- 14/02/2018 OBE artf2376874 : INC0191057 : Traitement de surtaxe communale
-- 21/08/2018 OBE artf3017857 : INC0234351 : Traitement de surtaxe - OD GL à corriger
-- 03/02/2020 SEL artf07348345: INC0391676 : traitement de surtaxe - Modification 1.B et 1.C
-- 04/08/2022 IBA TASK0175032
--------------------------------------------------------------------------------

    ----- Déclaration des variables globales du package -----
    gv_source                  VARCHAR2 (80);
    gv_tax_type                ap_tax_codes_all.tax_type%TYPE;
    gv_line_type_code          VARCHAR2 (25);
    gv_org_id                  VARCHAR2 (25);
    gv_user_je_category_name   gl_je_categories.user_je_category_name%TYPE;
    gv_user_je_source_name     gl_je_sources.user_je_source_name%TYPE;
    gv_gl_segment3_list        dka_parameters.varchar2_value%TYPE;
    gv_gl_segment4_like        dka_parameters.varchar2_value%TYPE;
    gv_gericco_cat_name        gl_je_categories.user_je_category_name%TYPE;
    gv_gericco_proj_cat_name   gl_je_categories.user_je_category_name%TYPE;

    --< OBE
    gn_responsibility_id       NUMBER (15);
    gn_application_id          NUMBER (15);
    gv_responsibility_ref      fnd_responsibility.responsibility_key%TYPE;
    --> OBE    
    
    gn_line_number             NUMBER (15); -- OBE artf2194455

-------------------------------------------------------------------------------------
--  Nom           : INIT
--  Description   : Procédure d'initialisation des variables du package
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK  ou 2: erreur
------------------------------------------------------------------------------------
    PROCEDURE init (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        rec_param   dka_parameters%ROWTYPE;
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf                   := NULL;
        pn_retcode                  := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début de la procédure INIT');
        ----- Initialisation des variables globales -----
        Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'SOURCE', rec_param, pv_errbuf, pn_retcode);
        gv_source                   := rec_param.varchar2_value;
        
        gn_line_number := 1; -- OBE artf2194455

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'SOURCE - ' || pv_errbuf;
            RETURN;
        END IF;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_source : ' || gv_source);
        /*
        Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'TAX_TYPE', rec_param, pv_errbuf, pn_retcode);
        gv_tax_type                 := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'TAX_TYPE - ' || pv_errbuf;
            RETURN;
        END IF;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_tax_type : ' || gv_tax_type);
        */
        Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'LINE_TYPE_CODE', rec_param, pv_errbuf, pn_retcode);
        gv_line_type_code           := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'LINE_TYPE_CODE - ' || pv_errbuf;
            RETURN;
        END IF;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_line_type_code : ' || gv_line_type_code);
        -- Valeur de la source du journal pour interface SARSURTAXE --
        Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'JE_SOURCE_NAME', rec_param, pv_errbuf, pn_retcode);
        gv_user_je_source_name      := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'JE_SOURCE_NAME - ' || pv_errbuf;
            RETURN;
        END IF;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_user_je_source_name : ' || gv_user_je_source_name);
        -- Valeur de la catégorie du journal pour interface SARSURTAXE --
        Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'USER_JE_CATEGORY_NAME', rec_param, pv_errbuf, pn_retcode);
        gv_user_je_category_name    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'USER_JE_CATEGORY_NAME - ' || pv_errbuf;
            RETURN;
        END IF;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_user_je_category_name : ' || gv_user_je_category_name);
        -- Valeurs des paramètres pour la requête d'alimentation de la table --
        --< OBE artf2202215
        --Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'GL_SEGMENT4_LIKE', rec_param, pv_errbuf, pn_retcode);
        --gv_gl_segment4_like         := rec_param.varchar2_value;

        --IF pn_retcode != 0
        --THEN
            --pv_errbuf    := 'GL_SEGMENT4_LIKE - ' || pv_errbuf;
            --RETURN;
        --END IF;

        --Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_gl_segment4_like : ' || gv_gl_segment4_like);
        --Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'GL_SEGMENT3_LIST', rec_param, pv_errbuf, pn_retcode);
        --gv_gl_segment3_list         := rec_param.varchar2_value;

        --IF pn_retcode != 0
        --THEN
            --pv_errbuf    := 'GL_SEGMENT3_LIST - ' || pv_errbuf;
            --RETURN;
        --END IF;
        
        --Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_gl_segment3_list : ' || gv_gl_segment3_list);
        --> OBE artf2202215
        /*
        Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'GERICCO_CAT_NAME', rec_param, pv_errbuf, pn_retcode);
        gv_gericco_cat_name         := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'GERICCO_CAT_NAME - ' || pv_errbuf;
            RETURN;
        END IF;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_gericco_cat_name : ' || gv_gericco_cat_name);
        Dka_Tools_Pkg.get_parameter ('SARSURTAXE', 'GERICCO_PROJ_CAT_NAME', rec_param, pv_errbuf, pn_retcode);
        gv_gericco_proj_cat_name    := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'GERICCO_PROJ_CAT_NAME - ' || pv_errbuf;
            RETURN;
        END IF;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_gericco_proj_cat_name : ' || gv_gericco_proj_cat_name);
        */
        ----- Récupération de l'identifiant de l'organisation -----
        Fnd_Profile.get ('ORG_ID', gv_org_id);
        Fnd_File.put_line(Fnd_File.LOG,'gv_org_id : '|| gv_org_id);
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END init;


--------------------------------------------------------------------------------------
--  Nom           : GET_SEGMENT4
--  Description   : Procédure de récupération du segment4 en fonction du segment3 à 
--					partir de la table de transco -- PHENIX 2004
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------											
    PROCEDURE get_segment4 ( 
        pv_segment3   			IN   VARCHAR2,
		pv_segment4   			OUT  VARCHAR2, -- PHENIX 2004
		pv_errbuf               OUT  VARCHAR2,
        pn_retcode              OUT  NUMBER
    )
	IS
	BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
		pv_segment4   := NULL;
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début de la procédure GET_SEGMENT4');
		
		        -- Recuperation du compte groupe (segment4) en fonction du compte local (segment3)
				SELECT dsl.return_value
				INTO pv_segment4 -- PHENIX 2004
				FROM dka_stransco_headers dsh,
				     dka_stransco_lines dsl
				WHERE dsl.set_id = dsh.set_id
				AND dsh.set_name = 'MIGR_GROUP_ACCOUNT_CLASS_BILAN'
				AND param1_value = pv_segment3 --'467297' -- OBE artf3017857
				AND SYSDATE BETWEEN dsl.start_date AND NVL(dsl.end_date, SYSDATE)
				AND dsl.ENABLE = 'Y';

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END get_segment4; -- PHENIX 2004


-------------------------------------------------------------------------------------
--  Nom           : PURGE_DKA_SARSURTAXE_TMP
--  Description   : Procédure qui purge la table dka_sarsurtaxe_tmp pour les lignes
--              pour lesquelles le traitement s'est déroulé normalement.
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE purge_dka_sarsurtaxe_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début  de la procédure PURGE_DKA_SARSURTAXE_TMP');

        DELETE FROM dka_sarsurtaxe_tmp_all; 
        -- 16/01/06            AND rejection_reason = 'Traitement normale de la ligne';
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END purge_dka_sarsurtaxe_tmp;


-------------------------------------------------------------------------------------
--  Nom           : INSERT_AR_INVOICES
--  Description   : Procédure d'insertion dans la table dka_sarsurtaxe_tmp des lignes
--              de surtaxe communale des factures AR ayant les caractéristiques suivantes :
--            - solde nul
--            - de type avoir et facture
--            - comptes utilisés : 467300 et 467296 (GIE IVRY)
--                    - concernant un organisme collecteur ( code partenaire segment4 = CSC%)
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_ar_invoices (
        pn_count     IN    NUMBER,
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début INSERT_AR_INVOICES');
        Fnd_File.put_line(Fnd_File.LOG,TO_CHAR (SYSDATE, 'HH24:MI:SS'));


        INSERT INTO dka_sarsurtaxe_tmp
                    (customer_trx_id,
                     trx_number,
                     cust_trx_line_gl_dist_id,
                     je_batch_id,
                     je_header_id,
                     je_line_num,
                     collectivite,
                     vendor_site_id,
                     account_surtaxe,
                     amount,
                     invoice_id,
                     invoice_num,
                     segment1,
                     segment2,
                     segment3,
                     segment4,
                     segment5,
                     segment6,
                     segment7,
                     segment8,
                     segment9,  -- PHENIX 2004
                     segment10, -- PHENIX 2004
                     segment11,  -- OBE
                     segment12, -- OBE
                     ccid,
                     invoice_currency_code,
                     org_id,
                     status,
                     rejection_reason
                    )
            SELECT   rct.customer_trx_id,
                     rct.trx_number,
                     rctlgd.cust_trx_line_gl_dist_id,
                     NULL,
                     NULL,
                     NULL,
                     pv.vendor_id,
                     pvs.vendor_site_id,
                     gcc.segment3 compte_surtaxe,
                     rctlgd.amount, -- sum (rctlgd.amount)
                     NULL, -- invoice_id
                     pv.segment1 || '-' || gcc.segment2 || '-' || TO_CHAR (SYSDATE, 'MM-YYYY') || '-' || gcc.segment1 || '-' ||TO_CHAR (pn_count),    --to_char(SYSDATE,'DD-MM-YYYY-HH24:MI:SS') -- PHENIX 2004 -- OBE artf2210354
                     --gcc.segment2 || '-' || TO_CHAR (SYSDATE, 'MM-YYYY') || '-' || gcc.segment1 || '-' ||TO_CHAR (pn_count), -- OBE artf2210354 Correction valeur
                     gcc.segment1,
                     gcc.segment2,
                     gcc.segment3,
                     gcc.segment4,
                     gcc.segment5,
                     gcc.segment6,
                     gcc.segment7,
                     gcc.segment8,
                     gcc.segment9, --PHENIX 2004
                     gcc.segment10, --PHENIX 2004
                     gcc.segment11, -- OBE
                     gcc.segment12, -- OBE
                     rctlgd.code_combination_id,
                     rct.invoice_currency_code,
                     rct.org_id, 
                     'P',
                     NULL
            FROM     ra_customer_trx rct,
                     ra_cust_trx_types rctt,
                     ra_cust_trx_line_gl_dist_all rctlgd,
                     gl_code_combinations gcc,
                     po_vendors pv,
                     po_vendor_sites pvs
                     --fnd_flex_value_sets ffvs, -- OBE artf2211298 
                     --fnd_flex_values     ffv   -- OBE artf2211298 
            -- identification de l'organisme collecteur --
            WHERE        --gcc.segment5 LIKE 'CSC%' -- PHENIX 2004  -- OBE
                      rctlgd.attribute8 LIKE 'CSC%'                 -- OBE
                     -- cuf 'valeur contextuelle' de ligne de facture non renseignée
                     AND rctlgd.attribute6 IS NULL
                     -- factures soldées
                     AND Arp_Bal_Util.get_trx_balance (rct.customer_trx_id, NULL) = '0'
                     -- on prend les avoir + factures
                     AND rctt.cust_trx_type_id = rct.cust_trx_type_id
                     AND rctt.TYPE IN ('INV', 'CM')
                     -- Pas de reliquats sur la facture
                     AND NOT EXISTS ( SELECT 1
                                      FROM   ar_adjustments aa,
                                             ra_customer_trx rct_rel,
                                             ra_cust_trx_types rctt_rel
                                      WHERE      rctt_rel.cust_trx_type_id = rct_rel.cust_trx_type_id
                                             AND rctt_rel.TYPE = 'CB'
                                             AND aa.customer_trx_id = rct.customer_trx_id
                                             AND rct_rel.customer_trx_id = aa.chargeback_customer_trx_id)
                     -- JDV DAOPCCF_LOCAL
                     --< OBE artf2211298 
                     /*
                     AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
                     AND ffvs.flex_value_set_id   = ffv.flex_value_set_id
                     AND ffv.enabled_flag         = 'Y'
                     AND ffv.attribute10          = 'Y'
                     */
                     --> OBE artf2211298 
                     -- comptes de surtaxe utilisés
                     --AND gcc.segment3 IN (ffv.flex_value) -- ('467300', '467296') -- OBE artf2211298 
                     AND DKA_AR_TOOLS_PKG.issurtaxeaccount(gcc.segment3) = 'TRUE'   -- OBE artf2211298 
                     AND rctlgd.customer_trx_id = rct.customer_trx_id
                     AND gcc.code_combination_id = rctlgd.code_combination_id
                     -- Lignes transférées dans GL --
                     AND rctlgd.gl_posted_date IS NOT NULL
                     -- Identification de la collectivité --
                     -- CD AND pv.vendor_name = gcc.segment4
			   -- début CD 11/02
			   --AND pv.vendor_name = (SELECT ffvv.description 
				--			 FROM gl_sets_of_books gsob,
				--				fnd_flex_values_vl ffvv,
				--				fnd_id_flex_segments fifs	
				--			 WHERE ffvv.flex_value_set_id = fifs.flex_value_set_id
				--			 AND gsob.set_of_books_id = fnd_profile.VALUE('GL_SET_OF_BKS_ID')
				--			 AND fifs.id_flex_num = gsob.chart_of_accounts_id
				--			 AND fifs.application_id = 101
				--			 AND fifs.id_flex_code = 'GL#'
				--			 AND fifs.application_column_name = 'SEGMENT5'    -- PHENIX 2004
				--			 AND ffvv.flex_value = gcc.segment5) -- PHENIX 2004
			   -- fin CD 11/02
			   		 -- CD 06/11/03
			   		 --AND pv.attribute6 = gcc.segment5  	-- PHENIX 2004  -- OBE
               AND pv.attribute6 = rctlgd.attribute8              -- OBE
			   AND nvl(pv.end_date_active, sysdate)>=sysdate 
			   --and rctlgd.customer_trx_id=1359896
               --< OBE artf2215399
               AND CASE WHEN (SELECT COUNT(1)
                              FROM po_vendors pv2
                              WHERE pv2.attribute6 = rctlgd.attribute8
                              ) > 1
                   THEN pv.vendor_type_lookup_code
                   ELSE 'VENDOR'
                   END <> 'FACTOR'
                 --> OBE artf2215399
                     -- Identification du site
                     AND pvs.vendor_id = pv.vendor_id
                     AND pvs.vendor_site_id = (SELECT MIN (pvs1.vendor_site_id)
                                               FROM po_vendor_sites pvs1,
                                                    gl_code_combinations gcc_pvs1, hr_operating_units hou -- NBO
                                               WHERE     pvs1.vendor_id = pv.vendor_id
                                                     AND pvs1.accts_pay_code_combination_id = gcc_pvs1.code_combination_id
                                                     AND pvs1.pay_site_flag = 'Y' -- OBE
                                                     AND gcc_pvs1.segment2 = gcc.segment2
                                                     AND gcc_pvs1.segment1 = gcc.segment1  -- OBE
                                                     AND hou.name = gcc.segment2 || gcc.segment1 -- NBO
                                                     AND hou.organization_id = pvs1.org_id -- NBO
                                                     ); -- PHENIX 2004
           /*
            GROUP BY rct.customer_trx_id,
                     rct.trx_number,
                     rctlgd.cust_trx_line_gl_dist_id,
                     pv.vendor_id,
                     rctlgd.amount,
                     gcc.segment3,
                     gcc.segment1,
                     gcc.segment2,
                     gcc.segment4,
                     gcc.segment5,
                     gcc.segment6,
                     gcc.segment7,
                     gcc.segment8,
                     gcc.segment9, -- PHENIX 2004
                     gcc.segment10,-- PHENIX 2004
                     rctlgd.code_combination_id,
                     rct.invoice_currency_code,
                     rct.org_id;
           */
        Fnd_File.put_line(Fnd_File.LOG,'Row inserted : '||TO_CHAR(SQL%ROWCOUNT));
        Fnd_File.put_line(Fnd_File.LOG,TO_CHAR (SYSDATE, 'HH24:MI:SS'));
		
		-- SEL - DEBUT - INC0391676 
		update DKA_SARSURTAXE_TMP_ALL temp
		   set STATUS = 'Z'
		   where exists (select 1
                  from PO_VENDORS pov,
                       PO_VENDOR_SITES_ALL povsa
                 where temp.vendor_site_id = povsa.vendor_site_id
                   and povsa.VENDOR_ID = pov.VENDOR_ID
                   and pov.attribute6 like 'CSC%'
                   and pov.vendor_type_lookup_code <> 'FACTOR'
				   and nvl(pov.end_date_active, sysdate)>=sysdate 
                   and exists (select 1
                                 from PO_VENDORS pv,
                                      po_vendor_sites_all pvs1,
                                      gl_code_combinations gcc_pvs1, 
                                      hr_operating_units hou -- NBO
                                where pv.vendor_id <> pov.vendor_id
                                  and pv.attribute6 = pov.attribute6
                                  and pv.vendor_type_lookup_code <> 'FACTOR'
                                  and pvs1.vendor_id = pv.vendor_id
                                 AND pvs1.accts_pay_code_combination_id = gcc_pvs1.code_combination_id
                                 AND pvs1.pay_site_flag = 'Y'
                                 AND gcc_pvs1.segment2 = temp.segment2
                                 AND gcc_pvs1.segment1 = temp.segment1  
                                 AND hou.name = temp.segment2 || temp.segment1 
                                 AND hou.organization_id = pvs1.org_id 
								 AND nvl(pv.end_date_active, sysdate)>=sysdate 
                                  and rownum<2));
		-- SEL - FIN - INC0391676 
		
		
		
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_ar_invoices;


-------------------------------------------------------------------------------------
--  Nom           : INSERT_GL_INVOICES_GERICCO
--  Description   : Procédure d'insertion dans la table dka_sarsurtaxe_tmp des lignes
--              de surtaxe communale de GL pour les factures portant sur des
--                  clients GERICCO (types de mouvement = 'GERICCO%')
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_gl_invoices_gericco (
        pn_count     IN    NUMBER,
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début INSERT_GL_INVOICES_GERICCO');
        Fnd_File.put_line(Fnd_File.LOG,TO_CHAR (SYSDATE, 'HH24:MI:SS'));

        INSERT INTO dka_sarsurtaxe_tmp
                    (customer_trx_id,
                     trx_number,
                     cust_trx_line_gl_dist_id,
                     je_batch_id,
                     je_header_id,
                     je_line_num,
                     collectivite,
                     vendor_site_id,
                     account_surtaxe,
                     amount,
                     invoice_id,
                     invoice_num,
                     segment1,
                     segment2,
                     segment3,
                     segment4,
                     segment5,
                     segment6,
                     segment7,
                     segment8,
                     segment9,  --PHENIX 2004
                     segment10, --PHENIX 2004
                     ccid,
                     invoice_currency_code,
                     org_id,
                     status,
                     rejection_reason
                    )
            SELECT   NULL,
                     NULL,
                     NULL,
                     gjh.je_batch_id, -- gjh.je_batch_id
                     gjl.je_header_id, -- gjl.je_header_id
                     gjl.je_line_num, -- gjl.je_line_num
                     pv.vendor_id,
                     pvs.vendor_site_id,
                     gcc.segment3 compte_surtaxe,
                     -- ano AR 9 --
                     NVL(gjl.entered_cr,gjl.entered_dr),	--SUM (NVL (gjl.entered_dr, 0) + NVL (gjl.entered_cr, 0)),
                     NULL, -- invoice_id
                     pv.segment1 || '-' || gcc.segment2 || '-' || TO_CHAR (SYSDATE, 'MM-YYYY') || '-' || gv_org_id || '-' ||TO_CHAR(pn_count), -- PHENIX 2004
                     gcc.segment1,
                     gcc.segment2,
                     gcc.segment3,
                     gcc.segment4,
                     gcc.segment5,
                     gcc.segment6,
                     gcc.segment7,
                     gcc.segment8,
                     gcc.segment9, -- PHENIX 2004
                     gcc.segment10, -- PHENIX 2004
                     gjl.code_combination_id,
                     gjh.currency_code,
                     Fnd_Profile.VALUE ('ORG_ID'), 
                     'P',
                     NULL
            FROM     gl_je_lines gjl,
                     gl_je_headers gjh,
                     gl_je_categories_tl gjct,
                     gl_code_combinations gcc,
                     po_vendors pv,
                     po_vendor_sites pvs
            -- identification de l'organisme collecteur --
            WHERE        1 = 1
                     -- jamais selectionnée --
                     AND gjl.attribute19 IS NULL
                     -- code journal Gericco sur projet'--
        --20/11      AND gjct.user_je_category_name IN (gv_gericco_cat_name, gv_gericco_proj_cat_name) --('Gericco sur projet', 'Gericco')
                     AND UPPER(gjct.user_je_category_name) IN (UPPER(gv_gericco_cat_name), UPPER(gv_gericco_proj_cat_name)) --('Gericco sur projet', 'Gericco')
                     AND gjct.LANGUAGE = USERENV ('LANG')
                     AND gjh.je_category = gjct.je_category_name
                     AND gjl.je_header_id = gjh.je_header_id
                     AND gcc.code_combination_id = gjl.code_combination_id
                     -- lignes imputées dans GL
                     AND gjl.status = 'P'
                     -- dans la société de lancement du traitement  --
                     AND gcc.segment1 = Pa_Utils.getorgname (Fnd_Profile.VALUE ('ORG_ID')) -- PHENIX 2004
                     -- Comptes utilisés pour la surtaxe --
                     --AND gcc.segment3 IN ('467300', '467296') -- PHENIX 2004    -- OBE artf2211298 
                     AND DKA_AR_TOOLS_PKG.issurtaxeaccount(gcc.segment3) = 'TRUE' -- OBE artf2211298 
                     -- Collecteur surtaxe --
                     AND gcc.segment5 LIKE 'CSC%' -- PHENIX 2004
                     -- Identification de la collectivité --
                     -- CD AND pv.vendor_name = gcc.segment5 -- PHENIX 2004
					 -- début CD 11/02
					 --AND pv.vendor_name = (SELECT ffvv.description 
					 --					   FROM gl_sets_of_books gsob,
					 --							fnd_flex_values_vl ffvv,
					 --							fnd_id_flex_segments fifs	
					 --					   WHERE ffvv.flex_value_set_id = fifs.flex_value_set_id
					 --						AND gsob.set_of_books_id = fnd_profile.VALUE('GL_SET_OF_BKS_ID')
					 --						AND fifs.id_flex_num = gsob.chart_of_accounts_id
					 --						AND fifs.application_id = 101
					 --						AND fifs.id_flex_code = 'GL#'
					 --						AND fifs.application_column_name = 'SEGMENT4' 
					 --						AND ffvv.flex_value = gcc.segment4)
					 -- fin CD 11/02
					 -- CD 06/11/03
			   		 AND pv.attribute6 = gcc.segment5 -- PHENIX 2004
                     -- Identification du site
                     AND pvs.vendor_site_id = (SELECT MIN (pvs1.vendor_site_id)
                                               FROM po_vendor_sites pvs1,
                                                    gl_code_combinations gcc_pvs1
                                               WHERE     pvs1.vendor_id = pv.vendor_id
                                                     AND pvs1.accts_pay_code_combination_id = gcc_pvs1.code_combination_id
                                                     AND gcc_pvs1.segment2 = gcc.segment2); -- PHENIX 2004

            /*GROUP BY gjh.je_batch_id,
                     gjl.je_header_id,
                     gjl.je_line_num,
                     pv.vendor_id,
                     gcc.segment3,
                     gcc.segment1,
                     gcc.segment2,
                     gcc.segment4,
                     gcc.segment5,
                     gcc.segment6,
                     gcc.segment7,
                     gcc.segment8,
                     gcc.segment9, -- PHENIX 2004
                     gcc.segment10, -- PHENIX 2004
                     gjl.code_combination_id,
                     gjh.currency_code;
    */
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_gl_invoices_gericco;


/*

 -------------------------------------------------------------------------------------
 --  Nom           : INSERT_AR_INVOICES_REMAINDER
 --  Description   : Procédure d'insertion dans la table dka_sarsurtaxe_tmp des factures soldées
 --              par un reliquat et ayant des lignes de surtaxe communale :
 --  PARAMETRES    :
 --    pv_errbuf       Sortie
 --    pv_retcode          Sortie

 --  VALEUR RETOURNEE :
 --     Description       : code retour de validité
 --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
 ------------------------------------------------------------------------------------
 PROCEDURE INSERT_AR_INVOICES_REMAINDER (pv_errbuf OUT         VARCHAR2,
                         pn_retcode    OUT     NUMBER)

 IS
 BEGIN

   ----- Initialisation des variables de sortie de la procédure -----
   pv_errbuf := NULL;
   pn_retcode := 0;

   dka_tools_pkg.put_debug_message('début INSERT_AR_INVOICES_REMAINDER');
   dka_tools_pkg.put_debug_message(to_char(sysdate,'HH24:MI:SS'));

   INSERT INTO dka_sarsurtaxe_tmp (      customer_trx_id,
                         trx_number,
                         cust_trx_line_gl_dist_id,
                         collectivite,
                         account_surtaxe,
                     amount,
                     invoice_id,
                     invoice_num,
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
                     ccid,
                     invoice_currency_code,
                     org_id,
                     status,
                     rejection_reason
                     )
                      SELECT rct.customer_trx_id,
                     rct.trx_number,
                     rctlgd.cust_trx_line_gl_dist_id,
                     pv.vendor_id,
                     gcc.segment3 compte_surtaxe,
                     arpcurr.currround( SUM (NVL(rctlgd.amount,0))
                                * ( SUM (NVL(aps_rel.amount_applied,0)) + SUM (NVL(aps.amount_applied,0)) )
                                    / SUM (NVL(aps.amount_due_original,0)) ),
                                     null,                                         -- invoice_id
                                     pv.vendor_id||'-'||to_char(SYSDATE,'DD-MM-YYYY-HH24:MI:SS')||'-'||gv_org_id,      -- invoice_num
                                     gcc.segment1,
                                     gcc.segment2,
                                     gcc.segment3,
                                     gcc.segment4,
                                     gcc.segment5,
                                     gcc.segment6,
                                     gcc.segment7,
                                     gcc.segment8,
                                     rctlgd.code_combination_id,
                                     rct.invoice_currency_code,
                                     rct.org_id,
                                     'P',
                                     null
                                FROM ra_customer_trx rct,
                     ra_cust_trx_types rctt,
                     ra_cust_trx_line_gl_dist_all rctlgd,
                     ar_payment_schedules aps,
                     gl_code_combinations gcc,
                     ra_customer_trx rct_rel,
                     ra_cust_trx_types rctt_rel,
                     ar_payment_schedules aps_rel,
                         po_vendors pv
                      -- identification de l'organisme collecteur --
                   WHERE  gcc.segment5 like 'CSC%' -- PHENIX 2004
                                      -- cuf 'valeur contextuelle' de ligne de facture non renseignée
                     AND rctlgd.attribute1 IS NULL
                      -- factures soldées
                     AND arp_bal_util.get_trx_balance( rct.customer_trx_id, NULL) = 0
                      -- cas des factures et avoir
                     AND rctt.cust_trx_type_id = rct.cust_trx_type_id
                     AND rctt.type in ('INV', 'CM')
                                     AND rctlgd.customer_trx_id =  rct.customer_trx_id
                                     AND gcc.code_combination_id = rctlgd.code_combination_id
                                      -- les comptes utilisés
                                     AND gcc.segment3 IN ('467300', '467296')
                     AND aps.customer_trx_id = rct.customer_trx_id
                      -- les factures ayant des reliquats
                     AND rct.customer_trx_id IN ( SELECT aa.customer_trx_id
                                        FROM ar_adjustments aa
                                       WHERE aa.chargeback_customer_trx_id = rct_rel.customer_trx_id )
                     -- les reliquats soldés
                    AND arp_bal_util.get_trx_balance( rct_rel.customer_trx_id, NULL) = 0
                    AND rctt_rel.cust_trx_type_id = rct_rel.cust_trx_type_id
                    AND rctt_rel.type = 'CB'
                    AND aps_rel.customer_trx_id = rct_rel.customer_trx_id
                    -- Identification de la collectivité --
                    -- CD AND pv.vendor_name = gcc.segment4
			  -- début CD 11/02
				--AND pv.vendor_name = (SELECT ffvv.description 
				--			    FROM gl_sets_of_books gsob,
				--				   fnd_flex_values_vl ffvv,
				--				   fnd_id_flex_segments fifs	
				--			    WHERE ffvv.flex_value_set_id = fifs.flex_value_set_id
				--				AND gsob.set_of_books_id = fnd_profile.VALUE('GL_SET_OF_BKS_ID')
				--				AND fifs.id_flex_num = gsob.chart_of_accounts_id
				--				AND fifs.application_id = 101
				--				AND fifs.id_flex_code = 'GL#'
				--				AND fifs.application_column_name = 'SEGMENT5' -- PHENIX 2004
				--				AND ffvv.flex_value = gcc.segment5)
			  -- fin CD 11/02
			  -- CD 06/11/03
			   		 AND pv.attribute6 = gcc.segment5 -- PHENIX 2004
                 HAVING SUM (NVL(aps.amount_due_original,0)) != 0
                    AND ( SUM (NVL(aps_rel.amount_applied,0)) + SUM (NVL(aps.amount_applied,0)) ) != 0
                 GROUP BY rct.customer_trx_id,
                    rct.trx_number,
                    cust_trx_line_gl_dist_id,
                    pv.vendor_id,
                    gcc.segment3,
                    gcc.segment1,
                    gcc.segment2,
                    gcc.segment4,
                    gcc.segment5,
                 	  gcc.segment6,
                    gcc.segment7,
                    gcc.segment8,
                    gcc.segment9, -- PHENIX 2004
                    gcc.segment10, -- PHENIX 2004
                    rctlgd.code_combination_id,
                    rct.invoice_currency_code,
                    rct.org_id;

  dka_tools_pkg.put_debug_message(to_char(sysdate,'HH24:MI:SS'));

  EXCEPTION
      WHEN OTHERS THEN
        pn_retcode := SQLCODE;
        pv_errbuf := SQLERRM;


 END INSERT_AR_INVOICES_REMAINDER;

*/
 -------------------------------------------------------------------------------------
 --  Nom           : INSERT_DKA_SARSURTAXE_TMP
 --  Description   : Procédure d'insertion dans la table dka_sarsurtaxe_tmp de lignes
 --                  de surtaxe communale issues des factures AR.
 --  PARAMETRES    :
 --    pv_errbuf       Sortie
 --    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK  ou 2: erreur
------------------------------------------------------------------------------------
    PROCEDURE insert_dka_sarsurtaxe_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
     )
    IS
      vn_count     NUMBER(15);
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début de la procédure DKA_SARSURTAXE_TMP');
        ----- Appel de la procédure PURGE_DKA_SARSURTAXE_TMP -----
        --dka_sarsurtaxe_pkg.purge_dka_sarsurtaxe_tmp(pv_errbuf,pn_retcode);
        SELECT  dka_sarsurtaxe_s.NEXTVAL
        INTO vn_count
        FROM DUAL;

        ----- Appel de la procédure INSERT_AR_INVOICES pour le chargement des factures provenant de AR de la table dka_sarsutaxe_tmp -----
        Dka_Sarsurtaxe_Pkg.insert_ar_invoices (vn_count,
        				       pv_errbuf,
        				       pn_retcode);

        IF pn_retcode = 0
        THEN
            Fnd_File.put_line(Fnd_File.LOG,'insertion des factures dans DKA_SARSURTAXE_TMP bien terminée');
        ELSE
            Fnd_File.put_line(Fnd_File.LOG,'Erreur : '||pv_errbuf);
        END IF;

  /* -- CD 15/05/03 Décision MOA : La partie Gericco n'est pour l'instant pas à traiter par le traitement de surtaxe
  		----- Appel de la procédure INSERT_GL_INVOICES_GERICCO pour le chargement des factures GERICCO provenant de GL de la table dka_sarsutaxe_tmp ----- -----
        dka_sarsurtaxe_pkg.insert_gl_invoices_gericco (vn_count,
        					       pv_errbuf,
        					       pn_retcode);

        IF pn_retcode = 0
        THEN
            Fnd_File.put_line(Fnd_File.LOG,'insertion des factures GERICCO dans DKA_SARSURTAXE_TMP bien terminée');
        ELSE
            Fnd_File.put_line(Fnd_File.LOG,'Erreur : '||pv_errbuf);
        END IF;
	*/	
    /*
    ----- Appel de la procédure INSERT_AR_INVOICES_REMAINDER -----
    dka_sarsurtaxe_pkg.insert_ar_invoices_remainder (pv_errbuf,pn_retcode);
    IF pn_retcode = 0
    THEN
     dka_tools_pkg.put_debug_message('insertion des factures avec reliquat dans DKA_SARSURTAXE_TMP bien terminée');
    ELSE
      dka_tools_pkg.put_debug_message('Erreur : insertion des factures avec reliquat dans DKA_SARSURTAXE_TMP non effectuée');
    END IF;
    */

    END insert_dka_sarsurtaxe_tmp;


-------------------------------------------------------------------------------------
--  Nom           : INSERT_AP_INVOICES_INTERFACE
--  Description   : Procédure d'insertion dans la table AP_INVOICES_INTERFACE
--  PARAMETRES    :
--    pv_collectivite         Entrée
--    pv_invoice_num          Entrée
--    pv_amount           Entrée
--    pn_invoice_id           Sortie
--    pv_errbuf           Sortie
--    pv_retcode              Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_ap_invoices_interface (
        pv_collectivite   IN       VARCHAR2,
        pn_vendor_site_id IN       NUMBER,
        pv_invoice_num    IN       VARCHAR2,
        pv_amount         IN       VARCHAR2,
        pv_segment1       IN       VARCHAR2, -- PHENIX 2004
        pv_segment2       IN       VARCHAR2, -- PHENIX 2004
        pn_invoice_id     OUT      NUMBER,
        pv_errbuf         OUT      VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS
        --vn_vendor_site_id   NUMBER (15);
        vn_pay_glc po_vendor_sites_all.pay_group_lookup_code%TYPE; -- PHENIX 2004
        vn_accts_ccid NUMBER;

  -- PHENIX 2004
  FUNCTION get_vdr_account (p_vdr_site_id IN NUMBER, pv_segment1 IN VARCHAR2)
      RETURN NUMBER
   IS
      -- Récupère le ccid en prenant en compte la société à partir du ccid de l'écran
      CURSOR cur_new_ccid (p_ccid IN NUMBER, p_segment1 IN VARCHAR2)
      IS
         SELECT gcc_new.code_combination_id
           FROM gl_code_combinations gcc_old, gl_code_combinations gcc_new
          WHERE 1 = 1
            AND gcc_new.segment1 = NVL (p_segment1, gcc_old.segment1)
            AND gcc_new.segment2 = gcc_old.segment2
            AND gcc_new.segment3 = gcc_old.segment3
            AND gcc_new.segment4 = gcc_old.segment4
            AND gcc_new.segment5 = gcc_old.segment5
            AND gcc_new.segment6 = gcc_old.segment6
            AND gcc_new.segment7 = gcc_old.segment7
            AND gcc_new.segment8 = gcc_old.segment8
            AND gcc_new.segment9 = gcc_old.segment9
            AND gcc_new.segment10 = gcc_old.segment10
            AND gcc_new.segment11 = gcc_old.segment11 -- OBE
            AND gcc_new.segment12 = gcc_old.segment12 -- OBE
            AND gcc_old.code_combination_id = p_ccid;

      l_new_ccid       gl_code_combinations.code_combination_id%TYPE;

      -- Génère une concaténation en prenant en compte la société à partir du ccid de l'écran
      CURSOR cur_new_conc_seg (p_ccid IN NUMBER, p_segment1 IN VARCHAR2)
      IS
         SELECT    p_segment1 || '.' || segment2 || '.' || segment3 || '.'
                || segment4 || '.' || segment5 || '.' || segment6 || '.'
                || segment7 || '.' || segment8 || '.' || segment9
                || '.' || segment10 || '.' || segment11 || '.' || segment12 -- OBE
           FROM gl_code_combinations
          WHERE code_combination_id = p_ccid;

      l_new_conc_seg   gl_code_combinations_kfv.concatenated_segments%TYPE;
      l_segs           Fnd_Flex_Ext.segmentarray;
      l_num_segs       NUMBER;
      l_struct         NUMBER;
	  l_site_ccid gl_code_combinations.code_combination_id%TYPE;
   BEGIN
      SELECT chart_of_accounts_id
        INTO l_struct
        FROM --gl_sets_of_books 
             --gl_ledgers                                                             -- OBE
             gl_access_sets                                                           -- OBE
       --WHERE /*set_of_books_id*/ ledger_id = Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID');  -- OBE
       WHERE access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID');  -- OBE

      SELECT DISTINCT accts_pay_code_combination_id
                 INTO l_site_ccid
                 FROM AP_SUPPLIER_SITES_ALL--po_vendor_sites_pay_ap_v -- OBE
                WHERE vendor_site_id = p_vdr_site_id;

      OPEN cur_new_ccid (l_site_ccid, pv_segment1);

      FETCH cur_new_ccid
       INTO l_new_ccid;

      IF cur_new_ccid%NOTFOUND
      THEN
         OPEN cur_new_conc_seg (l_site_ccid, pv_segment1);

         FETCH cur_new_conc_seg
          INTO l_new_conc_seg;

         CLOSE cur_new_conc_seg;

         l_num_segs :=
            Fnd_Flex_Ext.breakup_segments
                                        (concatenated_segs      => l_new_conc_seg,
                                         delimiter              => '.',
                                         segments               => l_segs
                                        );

         IF NOT Fnd_Flex_Ext.get_combination_id
                                           (application_short_name      => 'SQLGL',
                                            key_flex_code               => 'GL#',
                                            structure_number            => l_struct,
                                            validation_date             => SYSDATE,
                                            n_segments                  => 10,
                                            segments                    => l_segs,
                                            combination_id              => l_new_ccid
                                           )
         THEN
            CLOSE cur_new_ccid;

            RAISE NO_DATA_FOUND;
         END IF;
      END IF;

      CLOSE cur_new_ccid;

      IF (Fnd_Flex_Keyval.validate_ccid (appl_short_name       => 'SQLGL',
                                         key_flex_code         => 'GL#',
                                         structure_number      => l_struct,
                                         combination_id        => l_new_ccid,
                                         displayable           => 'ALL',
                                         data_set              => NULL,
                                         vrule                 => NULL,
                                         security              => 'CHECK',
                                         get_columns           => NULL,
                                         resp_appl_id          => NULL,
                                         resp_id               => NULL,
                                         user_id               => NULL
                                        )
         )
      THEN
         l_new_conc_seg :=
            Fnd_Flex_Ext.get_segs (application_short_name      => 'SQLGL',
                                   key_flex_code               => 'GL#',
                                   structure_number            => l_struct,
                                   combination_id              => l_new_ccid
                                  );

         IF (l_new_conc_seg IS NULL)
         THEN
            RAISE NO_DATA_FOUND;
         ELSE
            RETURN l_new_ccid;
         END IF;
      END IF;
   END get_vdr_account;
   -- FIN PHENIX 2004


    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pn_invoice_id    := -1;
        pv_errbuf        := NULL;
        pn_retcode       := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début INSERT_AP_INVOICES_INTERFACES');
        Fnd_File.put_line(Fnd_File.LOG,TO_CHAR (SYSDATE, 'HH24:MI:SS'));

        ----- Recherche du site fournisseur correspondant à la collectivité -----
        --SELECT MIN (vendor_site_id)
        --INTO   vn_vendor_site_id
        --FROM   po_vendor_sites pvs
        --WHERE  pvs.vendor_id = pv_collectivite;
        
        --Fnd_File.put_line(Fnd_File.LOG,'vn_vendor_site_id : '|| TO_CHAR (vn_vendor_site_id));

        -- PHENIX 2004
        SELECT pay_group_lookup_code
        INTO   vn_pay_glc
        FROM   po_vendor_sites_all
        WHERE  vendor_site_id = pn_vendor_site_id;

        vn_accts_ccid := get_vdr_account (pn_vendor_site_id, pv_segment1);
        -- FIN PHENIX 2004
        


        BEGIN
            INSERT INTO ap_invoices_interface
                        (invoice_id,
                         invoice_num,
                         invoice_type_lookup_code,
                         invoice_date,
                         po_number,
                         vendor_id,
                         vendor_num,
                         vendor_name,
                         vendor_site_id,
                         vendor_site_code,
                         invoice_amount,
                         invoice_currency_code,
                         exchange_rate,
                         exchange_rate_type,
                         exchange_date,
                         terms_id,
                         terms_name,
                         description,
                         awt_group_id,
                         awt_group_name,
                         last_update_date,
                         last_updated_by,
                         last_update_login,
                         creation_date,
                         created_by,
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
                         attribute11,
                         attribute12,
                         attribute13,
                         attribute14,
                         attribute15,
                         global_attribute_category,
                         global_attribute1,
                         global_attribute2,
                         global_attribute3,
                         global_attribute4,
                         global_attribute5,
                         global_attribute6,
                         global_attribute7,
                         global_attribute8,
                         global_attribute9,
                         global_attribute10,
                         global_attribute11,
                         global_attribute12,
                         global_attribute13,
                         global_attribute14,
                         global_attribute15,
                         global_attribute16,
                         global_attribute17,
                         global_attribute18,
                         global_attribute19,
                         global_attribute20,
                         status,
                         SOURCE,
                         GROUP_ID,
                         request_id,
                         payment_cross_rate_type,
                         payment_cross_rate_date,
                         payment_cross_rate,
                         payment_currency_code,
                         workflow_flag,
                         doc_category_code,
                         voucher_num,
                         payment_method_lookup_code,
                         pay_group_lookup_code,
                         goods_received_date,
                         invoice_received_date,
                         gl_date,
                         accts_pay_code_combination_id,
                         ussgl_transaction_code,
                         exclusive_payment_flag,
                         org_id,
                         amount_applicable_to_discount,
                         prepay_num,
                         prepay_dist_num,
                         prepay_apply_amount,
                         prepay_gl_date
                        )
                SELECT ap_invoices_interface_s.NEXTVAL, --invoice_id,
                       pv_invoice_num, --invoice_num,
                       'STANDARD', -- invoice_type_lookup_code,
                       TRUNC(SYSDATE), --pr_ar_invoices_rec.invoice_date,   -- invoice_date,
                       NULL, -- po_number   ???,
                       pv_collectivite, -- vendor_id,
                       NULL, -- vendor_num,
                       NULL, -- vendor_name,
                       pn_vendor_site_id, -- vendor_site_id,
                       NULL, -- vendor_site_code,
                       pv_amount, -- invoice_amount,
                       NULL, -- invoice_currency_code,
                       NULL, -- exchange_rate,
                       NULL, -- exchange_rate_type,
                       NULL, -- exchange_date,
                       NULL, -- terms_id,
                       NULL, -- terms_name,
                       NULL, -- description,
                       NULL, -- awt_group_id,
                       NULL, -- awt_group_name,
                       SYSDATE, -- last_update_date,
                       Fnd_Global.user_id, -- last_updated_by,
                       Fnd_Global.login_id, -- last_update_login,
                       SYSDATE, -- creation_date,
                       Fnd_Global.user_id, -- created_by,
                       NULL, -- attribute_category,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL, -- attribute1..5,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL, -- attribute6..10,
                       NULL,
                       NULL,
                       NULL,
                       NULL,
                       NULL, -- attribute11..15,
                       NULL, -- global_attribute_category,
                       NULL,
                       NULL,
                       NULL, -- global_attribute1..3,
                       NULL,
                       NULL,
                       NULL, -- global_attribute4..6,
                       NULL,
                       NULL,
                       NULL, -- global_attribute7..9,
                       NULL,
                       NULL,
                       NULL, -- global_attribute10..12,
                       NULL,
                       NULL,
                       NULL, -- global_attribute13..15,
                       NULL,
                       NULL,
                       NULL, -- global_attribute16..18,
                       NULL,
                       NULL, -- global_attribute19..20,
                       NULL, -- status,
                       gv_source, -- source,
                       ap_interface_groups_s.NEXTVAL, -- group_id,
                       NULL, -- request_id,
                       NULL, -- payment_cross_rate_type,
                       TRUNC(SYSDATE), -- payment_cross_rate_date,
                       1, -- payment_cross_rate,
                       NULL, -- payment_currency_code,
                       NULL, -- workflow_flag,
                       --pv_segment1 || '_STD INV', -- PHENIX 2004 => doc_category_code = NULL,  -- OBE
                       'STD INV',                                                                -- OBE 
                       NULL, -- voucher_num,
                       NULL, -- payment_method_lookup_code,
                       --pv_segment1 || vn_pay_glc, -- PHENIX 2004 => pay_group_lookup_code = NULL, -- OBE
                       vn_pay_glc,                                                                  -- OBE
                       NULL, -- goods_received_date,
                       NULL, -- invoice_received_date,
                       NULL, -- gl_date,
                       vn_accts_ccid, -- accts_pay_code_combination_id,-- FIN PHENIX 2004
                       NULL, -- ussgl_transaction_code,
                       NULL, -- exclusive_payment_flag,
                       gv_org_id, -- org_id,
                       NULL, -- amount_applicable_to_discount,
                       NULL, -- prepay_num,
                       NULL, -- prepay_dist_num,
                       NULL, -- prepay_apply_amount,
                       NULL -- prepay_gl_date
                FROM   DUAL;
                
                Fnd_File.put_line(Fnd_File.LOG,'Row inserted : '||TO_CHAR(SQL%ROWCOUNT));
                
        EXCEPTION
            WHEN OTHERS
            THEN
                pn_retcode    := SQLCODE;
                pv_errbuf     := SQLERRM;
        END;

        ----- Récupération du numéro de facture courante -----
        SELECT ap_invoices_interface_s.CURRVAL
        INTO   pn_invoice_id
        FROM   DUAL;

        Fnd_File.put_line(Fnd_File.LOG,'pn_invoice_id : '|| TO_CHAR (pn_invoice_id));
        Fnd_File.put_line(Fnd_File.LOG,'fin de insert_ap_invoices_interfaces');
    END insert_ap_invoices_interface;


-------------------------------------------------------------------------------------
--  Nom           : INSERT_AP_INVOICE_LINES_INTERFACE
--  Description   : Procédure d'insertion dans la table AP_INVOICE_LINES_INTERFACE
--  PARAMETRES    :
--    pn_invoice_id           Entrée
--    pv_amount           Entrée
--    pn_customer_trx_line_id IN  Entrée
--    pv_segment1         Entrée
--    pv_segment2         Entrée
--    pv_segment3         Entrée
--    pv_segment4         Entrée
--    pv_segment5         Entrée
--    pv_segment6         Entrée
--    pv_segment7         Entrée
--    pv_segment8         Entrée
--    pv_segment9         Entrée -- PHENIX 2004
--    pv_segment10        Entrée -- PHENIX 2004
--    pv_errbuf           Sortie
--    pv_retcode              Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_ap_inv_lines_interface (
        pn_invoice_id             IN       NUMBER,
        pv_amount                 IN       VARCHAR2,
        pn_customer_trx_line_id   IN       NUMBER,
        pn_je_header_id           IN       NUMBER,
        pn_je_line_num            IN       NUMBER,
        pv_segment1               IN       VARCHAR2,
        pv_segment2               IN       VARCHAR2,
        pv_segment3               IN       VARCHAR2,
        pv_segment4               IN       VARCHAR2,
        pv_segment5               IN       VARCHAR2,
        pv_segment6               IN       VARCHAR2,
        pv_segment7               IN       VARCHAR2,
        pv_segment8               IN       VARCHAR2,
        pv_segment9               IN       VARCHAR2, -- PHENIX 2004
        pv_segment10              IN       VARCHAR2, -- PHENIX 2004
        pv_segment11              IN       VARCHAR2, -- OBE
        pv_segment12              IN       VARCHAR2, -- OBE        
        pv_errbuf                 OUT      VARCHAR2,
        pn_retcode                OUT      NUMBER
    )
    IS
        vv_tax_code                  VARCHAR2 (25);
        vv_dummy                     VARCHAR2 (25);
        vn_dist_code_combinaton_id   NUMBER (15);
	    vv_segment4					 VARCHAR2 (10); --CD 18/04 -- PHENIX 2004
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début INSERT_AP_INVOICE_LINES_INTERFACE');

        -- Selection du compte de ventilation suivant la socièté collectrice --
        SELECT DECODE (pv_segment3, '467300', '467301', '467297')
        INTO   vv_dummy
        FROM   DUAL;
		
		--18/04 début CD Récupération du nouveau compte groupe
		Dka_Sarsurtaxe_Pkg.get_segment4 (vv_dummy, vv_segment4, pv_errbuf, pn_retcode); -- PHENIX 2004

    IF pn_retcode != 0 
		THEN
            Fnd_File.put_line(Fnd_File.LOG,'Erreur : '||pv_errbuf);
			
		ELSE

		--18/04 fin CD Récupération du nouveau compte groupe

        ----- Récupération du CCid -----
        Dka_Tools_Pkg.get_code_combination_id (pv_segment1, pv_segment2, vv_dummy, vv_segment4, pv_segment5, pv_segment6, pv_segment7, pv_segment8, pv_segment9, pv_segment10, pv_segment11, pv_segment12, vn_dist_code_combinaton_id, pv_errbuf, pn_retcode); -- PHENIX 2004
        Fnd_File.put_line(Fnd_File.LOG,'vn_dist_code_combinaton_id :'|| TO_CHAR (vn_dist_code_combinaton_id));

        -- Récupération du code TVA exonérée de la société --
        --< OBE
        /*
        SELECT atca.NAME
        INTO   vv_tax_code
        FROM   ap_tax_codes_all atca
        WHERE  atca.org_id = gv_org_id
        AND    atca.tax_type = gv_tax_type
        AND    atca.NAME LIKE pv_segment1 || '_' || pv_segment2 || '%D';  --JJA 16/04/2012
        */
        --> OBE
        -- PHENIX 2004

        INSERT INTO ap_invoice_lines_interface
                    (invoice_id,
                     invoice_line_id,
                     line_number,
                     line_type_lookup_code,
                     line_group_number,
                     amount,
                     accounting_date,
                     description,
                     amount_includes_tax_flag,
                     prorate_across_flag,
                     tax_code,
                     final_match_flag,
                     po_header_id,
                     po_number,
                     po_line_id,
                     po_line_number,
                     po_line_location_id,
                     po_shipment_num,
                     po_distribution_id,
                     po_distribution_num,
                     po_unit_of_measure,
                     inventory_item_id,
                     item_description,
                     quantity_invoiced,
                     ship_to_location_code,
                     unit_price,
                     distribution_set_id,
                     distribution_set_name,
                     dist_code_concatenated,
                     dist_code_combination_id,
                     awt_group_id,
                     awt_group_name,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     created_by,
                     creation_date,
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
                     attribute11,
                     attribute12,
                     attribute13,
                     attribute14,
                     attribute15,
                     global_attribute_category,
                     global_attribute1,
                     global_attribute2,
                     global_attribute3,
                     global_attribute4,
                     global_attribute5,
                     global_attribute6,
                     global_attribute7,
                     global_attribute8,
                     global_attribute9,
                     global_attribute10,
                     global_attribute11,
                     global_attribute12,
                     global_attribute13,
                     global_attribute14,
                     global_attribute15,
                     global_attribute16,
                     global_attribute17,
                     global_attribute18,
                     global_attribute19,
                     global_attribute20,
                     po_release_id,
                     release_num,
                     account_segment,
                     balancing_segment,
                     cost_center_segment,
                     project_id,
                     task_id,
                     expenditure_type,
                     expenditure_item_date,
                     expenditure_organization_id,
                     project_accounting_context,
                     pa_addition_flag,
                     pa_quantity,
                     ussgl_transaction_code,
                     stat_amount,
                     type_1099,
                     income_tax_region,
                     assets_tracking_flag,
                     price_correction_flag,
                     org_id,
                     receipt_number,
                     receipt_line_number,
                     match_option,
                     packing_slip,
                     rcv_transaction_id,
                     pa_cc_ar_invoice_id,
                     pa_cc_ar_invoice_line_num,
                     reference_1,
                     reference_2,
                     pa_cc_processed_code,
                     tax_recovery_rate,
                     tax_recovery_override_flag,
                     tax_recoverable_flag,
                     tax_code_override_flag,
                     tax_code_id,
                     TAX_CLASSIFICATION_CODE, -- OBE
                     credit_card_trx_id,
                     award_id
                    )
            SELECT pn_invoice_id, --invoice_id,
                   ap_invoice_lines_interface_s.NEXTVAL, --invoice_line_id,
                   gn_line_number,--pn_customer_trx_line_id, --line_number, -- OBE artf2194455
                   gv_line_type_code, --line_type_lookup_code,
                   NULL, --line_group_number,
                   pv_amount, --amount,
                   NULL, --accounting_date,
                   NULL, --description,
                   NULL, --amount_includes_tax_flag,
                   NULL, --prorate_across_flag,
                   --vv_tax_code, --tax_code,  -- OBE
                   NULL,                       -- OBE
                   NULL, --final_match_flag,
                   NULL, --po_header_id,
                   NULL, --po_number,
                   NULL, --po_line_id,
                   NULL, --po_line_number,
                   NULL, --po_line_location_id,
                   NULL, --po_shipment_num,
                   NULL, --po_distribution_id,
                   NULL, --po_distribution_num,
                   NULL, --po_unit_of_measure,
                   NULL, --inventory_item_id,
                   NULL, --item_description,
                   NULL, --quantity_invoiced,
                   NULL, --ship_to_location_code,
                   NULL, --unit_price,
                   NULL, --distribution_set_id,
                   NULL, --distribution_set_name,
                   NULL, --dist_code_concatenated,
                   vn_dist_code_combinaton_id, --dist_code_combination_id,
                   NULL, --awt_group_id,
                   NULL, --awt_group_name,
                   Fnd_Global.user_id, --last_updated_by,
                   SYSDATE, --last_update_date,
                   Fnd_Global.login_id, --last_update_login,
                   Fnd_Global.user_id, --created_by,
                   SYSDATE, --creation_date,
                   NULL, --attribute_category,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute1,..5,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute6, ..10,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute11, ..15,
                   NULL, --global_attribute_category,
                   NULL,
                   NULL, --global_attribute1..2,
                   NULL,
                   NULL,
                   NULL, --global_attribute3..5,
                   NULL,
                   NULL,
                   NULL, --global_attribute6..8,
                   NULL,
                   NULL,
                   NULL, --global_attribute9..11,
                   NULL,
                   NULL,
                   NULL, --global_attribute12..14,
                   NULL,
                   NULL,
                   NULL, --global_attribute15..17,
                   NULL,
                   NULL,
                   NULL, --global_attribute18..20,
                   NULL, --po_release_id,
                   NULL, --release_num,
                   NULL, --account_segment,
                   NULL, --balancing_segment,
                   NULL, --cost_center_segment,
                   NULL, --project_id,
                   NULL, --task_id,
                   NULL, --expenditure_type,
                   NULL, --expenditure_item_date,
                   NULL, --expenditure_organization_id,
                   NULL, --project_accounting_context,
                   NULL, --pa_addition_flag,
                   NULL, --pa_quantity,
                   NULL, --ussgl_transaction_code,
                   NULL, --stat_amount,
                   NULL, --type_1099,
                   NULL, --income_tax_region,
                   NULL, --assets_tracking_flag,
                   NULL, --price_correction_flag,
                   gv_org_id, --org_id,
                   NULL, --receipt_number,
                   NULL, --receipt_line_number,
                   NULL, --match_option,
                   NULL, --packing_slip,
                   NULL, --rcv_transaction_id,
                   NULL, --pa_cc_ar_invoice_id,
                   NULL, --pa_cc_ar_invoice_line_num,
                   NULL,
                   NULL, --reference_1, reference_2,
                   NULL, --pa_cc_processed_code,
                   NULL, --tax_recovery_rate,
                   NULL, --tax_recovery_override_flag,
                   NULL, --tax_recoverable_flag,
                   NULL, --tax_code_override_flag,
                   NULL, --tax_code_id,
                   'DED_00.00D', -- TAX_CLASSIFICATION_CODE
                   NULL, --credit_card_trx_id,
                   NULL --award_id
            FROM   DUAL;
            
            Fnd_File.put_line(Fnd_File.LOG,'Row inserted : '||TO_CHAR(SQL%ROWCOUNT));
            
        --< OBE artf2194455    
         /*   
        Fnd_File.put_line(Fnd_File.LOG,'Insertion d''une ligne TAX');                
        
        INSERT INTO ap_invoice_lines_interface
                    (invoice_id,
                     invoice_line_id,
                     line_number,
                     line_type_lookup_code,
                     line_group_number,
                     amount,
                     accounting_date,
                     description,
                     amount_includes_tax_flag,
                     prorate_across_flag,
                     tax_code,
                     final_match_flag,
                     po_header_id,
                     po_number,
                     po_line_id,
                     po_line_number,
                     po_line_location_id,
                     po_shipment_num,
                     po_distribution_id,
                     po_distribution_num,
                     po_unit_of_measure,
                     inventory_item_id,
                     item_description,
                     quantity_invoiced,
                     ship_to_location_code,
                     unit_price,
                     distribution_set_id,
                     distribution_set_name,
                     dist_code_concatenated,
                     dist_code_combination_id,
                     awt_group_id,
                     awt_group_name,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     created_by,
                     creation_date,
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
                     attribute11,
                     attribute12,
                     attribute13,
                     attribute14,
                     attribute15,
                     global_attribute_category,
                     global_attribute1,
                     global_attribute2,
                     global_attribute3,
                     global_attribute4,
                     global_attribute5,
                     global_attribute6,
                     global_attribute7,
                     global_attribute8,
                     global_attribute9,
                     global_attribute10,
                     global_attribute11,
                     global_attribute12,
                     global_attribute13,
                     global_attribute14,
                     global_attribute15,
                     global_attribute16,
                     global_attribute17,
                     global_attribute18,
                     global_attribute19,
                     global_attribute20,
                     po_release_id,
                     release_num,
                     account_segment,
                     balancing_segment,
                     cost_center_segment,
                     project_id,
                     task_id,
                     expenditure_type,
                     expenditure_item_date,
                     expenditure_organization_id,
                     project_accounting_context,
                     pa_addition_flag,
                     pa_quantity,
                     ussgl_transaction_code,
                     stat_amount,
                     type_1099,
                     income_tax_region,
                     assets_tracking_flag,
                     price_correction_flag,
                     org_id,
                     receipt_number,
                     receipt_line_number,
                     match_option,
                     packing_slip,
                     rcv_transaction_id,
                     pa_cc_ar_invoice_id,
                     pa_cc_ar_invoice_line_num,
                     reference_1,
                     reference_2,
                     pa_cc_processed_code,
                     TAX, -- OBE
                     TAX_JURISDICTION_CODE, -- OBE
                     TAX_STATUS_CODE, -- OBE
                     TAX_RATE_CODE, -- OBE
                     tax_recovery_rate,
                     tax_recovery_override_flag,
                     tax_recoverable_flag,
                     tax_code_override_flag,
                     tax_code_id,
                     TAX_REGIME_CODE, -- OBE
                     credit_card_trx_id,
                     award_id
                    )
            SELECT pn_invoice_id, --invoice_id,
                   ap_invoice_lines_interface_s.NEXTVAL, --invoice_line_id,
                   2,--pn_customer_trx_line_id, --line_number,
                   'TAX', --line_type_lookup_code,
                   NULL, --line_group_number,
                   0, --amount,
                   NULL, --accounting_date,
                   NULL, --description,
                   NULL, --amount_includes_tax_flag,
                   NULL, --prorate_across_flag,
                   --vv_tax_code, --tax_code,  -- OBE
                   NULL,                       -- OBE
                   NULL, --final_match_flag,
                   NULL, --po_header_id,
                   NULL, --po_number,
                   NULL, --po_line_id,
                   NULL, --po_line_number,
                   NULL, --po_line_location_id,
                   NULL, --po_shipment_num,
                   NULL, --po_distribution_id,
                   NULL, --po_distribution_num,
                   NULL, --po_unit_of_measure,
                   NULL, --inventory_item_id,
                   NULL, --item_description,
                   NULL, --quantity_invoiced,
                   NULL, --ship_to_location_code,
                   NULL, --unit_price,
                   NULL, --distribution_set_id,
                   NULL, --distribution_set_name,
                   NULL, --dist_code_concatenated,
                   NULL,--vn_dist_code_combinaton_id, --dist_code_combination_id,
                   NULL, --awt_group_id,
                   NULL, --awt_group_name,
                   Fnd_Global.user_id, --last_updated_by,
                   SYSDATE, --last_update_date,
                   Fnd_Global.login_id, --last_update_login,
                   Fnd_Global.user_id, --created_by,
                   SYSDATE, --creation_date,
                   NULL, --attribute_category,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute1,..5,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute6, ..10,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute11, ..15,
                   NULL, --global_attribute_category,
                   NULL,
                   NULL, --global_attribute1..2,
                   NULL,
                   NULL,
                   NULL, --global_attribute3..5,
                   NULL,
                   NULL,
                   NULL, --global_attribute6..8,
                   NULL,
                   NULL,
                   NULL, --global_attribute9..11,
                   NULL,
                   NULL,
                   NULL, --global_attribute12..14,
                   NULL,
                   NULL,
                   NULL, --global_attribute15..17,
                   NULL,
                   NULL,
                   NULL, --global_attribute18..20,
                   NULL, --po_release_id,
                   NULL, --release_num,
                   NULL, --account_segment,
                   NULL, --balancing_segment,
                   NULL, --cost_center_segment,
                   NULL, --project_id,
                   NULL, --task_id,
                   NULL, --expenditure_type,
                   NULL, --expenditure_item_date,
                   NULL, --expenditure_organization_id,
                   NULL, --project_accounting_context,
                   'N', --pa_addition_flag,
                   NULL, --pa_quantity,
                   NULL, --ussgl_transaction_code,
                   NULL, --stat_amount,
                   NULL, --type_1099,
                   NULL, --income_tax_region,
                   NULL, --assets_tracking_flag,
                   NULL, --price_correction_flag,
                   gv_org_id, --org_id,
                   NULL, --receipt_number,
                   NULL, --receipt_line_number,
                   NULL, --match_option,
                   NULL, --packing_slip,
                   NULL, --rcv_transaction_id,
                   NULL, --pa_cc_ar_invoice_id,
                   NULL, --pa_cc_ar_invoice_line_num,
                   NULL,
                   NULL, --reference_1, reference_2,
                   NULL, --pa_cc_processed_code,
                   'TVA',-- TAX
                   'FR_JURIDICTION', --TAX_JURISDICTION_CODE
                   'STANDARD', --TAX_STATUS_CODE
                   'DED_00.00D', --TAX_RATE_CODE
                   NULL, --tax_recovery_rate,
                   NULL, --tax_recovery_override_flag,
                   NULL, --tax_recoverable_flag,
                   NULL, --tax_code_override_flag,
                   NULL, --tax_code_id,
                   'FR-TAX', --TAX_REGIME_CODE
                   NULL, --credit_card_trx_id,
                   NULL --award_id
            FROM   DUAL;
            
            Fnd_File.put_line(Fnd_File.LOG,'Row inserted : '||TO_CHAR(SQL%ROWCOUNT));            */
        --> OBE artf2194455    
			END IF;
			
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_ap_inv_lines_interface;
    
    
--< OBE artf2194455    
    
-------------------------------------------------------------------------------------
--  Nom           : insert_ap_inv_lines_int_tax
--  Description   : Procédure d'insertion dans la table AP_INVOICE_LINES_INTERFACE
--  PARAMETRES    :
--    pn_invoice_id           Entrée
--    pv_amount           Entrée
--    pn_customer_trx_line_id IN  Entrée
--    pv_segment1         Entrée
--    pv_segment2         Entrée
--    pv_segment3         Entrée
--    pv_segment4         Entrée
--    pv_segment5         Entrée
--    pv_segment6         Entrée
--    pv_segment7         Entrée
--    pv_segment8         Entrée
--    pv_segment9         Entrée -- PHENIX 2004
--    pv_segment10        Entrée -- PHENIX 2004
--    pv_errbuf           Sortie
--    pv_retcode              Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE insert_ap_inv_lines_int_tax (
        pn_invoice_id             IN       NUMBER,
        pv_errbuf                 OUT      VARCHAR2,
        pn_retcode                OUT      NUMBER
    )
    IS

    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début insert_ap_inv_lines_int_tax');

            
        Fnd_File.put_line(Fnd_File.LOG,'Insertion d''une ligne TAX');                
        
        INSERT INTO ap_invoice_lines_interface
                    (invoice_id,
                     invoice_line_id,
                     line_number,
                     line_type_lookup_code,
                     line_group_number,
                     amount,
                     accounting_date,
                     description,
                     amount_includes_tax_flag,
                     prorate_across_flag,
                     tax_code,
                     final_match_flag,
                     po_header_id,
                     po_number,
                     po_line_id,
                     po_line_number,
                     po_line_location_id,
                     po_shipment_num,
                     po_distribution_id,
                     po_distribution_num,
                     po_unit_of_measure,
                     inventory_item_id,
                     item_description,
                     quantity_invoiced,
                     ship_to_location_code,
                     unit_price,
                     distribution_set_id,
                     distribution_set_name,
                     dist_code_concatenated,
                     dist_code_combination_id,
                     awt_group_id,
                     awt_group_name,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     created_by,
                     creation_date,
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
                     attribute11,
                     attribute12,
                     attribute13,
                     attribute14,
                     attribute15,
                     global_attribute_category,
                     global_attribute1,
                     global_attribute2,
                     global_attribute3,
                     global_attribute4,
                     global_attribute5,
                     global_attribute6,
                     global_attribute7,
                     global_attribute8,
                     global_attribute9,
                     global_attribute10,
                     global_attribute11,
                     global_attribute12,
                     global_attribute13,
                     global_attribute14,
                     global_attribute15,
                     global_attribute16,
                     global_attribute17,
                     global_attribute18,
                     global_attribute19,
                     global_attribute20,
                     po_release_id,
                     release_num,
                     account_segment,
                     balancing_segment,
                     cost_center_segment,
                     project_id,
                     task_id,
                     expenditure_type,
                     expenditure_item_date,
                     expenditure_organization_id,
                     project_accounting_context,
                     pa_addition_flag,
                     pa_quantity,
                     ussgl_transaction_code,
                     stat_amount,
                     type_1099,
                     income_tax_region,
                     assets_tracking_flag,
                     price_correction_flag,
                     org_id,
                     receipt_number,
                     receipt_line_number,
                     match_option,
                     packing_slip,
                     rcv_transaction_id,
                     pa_cc_ar_invoice_id,
                     pa_cc_ar_invoice_line_num,
                     reference_1,
                     reference_2,
                     pa_cc_processed_code,
                     TAX, -- OBE
                     TAX_JURISDICTION_CODE, -- OBE
                     TAX_STATUS_CODE, -- OBE
                     TAX_RATE_CODE, -- OBE
                     tax_recovery_rate,
                     tax_recovery_override_flag,
                     tax_recoverable_flag,
                     tax_code_override_flag,
                     tax_code_id,
                     TAX_REGIME_CODE, -- OBE
                     credit_card_trx_id,
                     award_id
                    )
            SELECT pn_invoice_id, --invoice_id,
                   ap_invoice_lines_interface_s.NEXTVAL, --invoice_line_id,
                   gn_line_number,--pn_customer_trx_line_id, --line_number,
                   'TAX', --line_type_lookup_code,
                   NULL, --line_group_number,
                   0, --amount,
                   NULL, --accounting_date,
                   NULL, --description,
                   NULL, --amount_includes_tax_flag,
                   NULL, --prorate_across_flag,
                   --vv_tax_code, --tax_code,  -- OBE
                   NULL,                       -- OBE
                   NULL, --final_match_flag,
                   NULL, --po_header_id,
                   NULL, --po_number,
                   NULL, --po_line_id,
                   NULL, --po_line_number,
                   NULL, --po_line_location_id,
                   NULL, --po_shipment_num,
                   NULL, --po_distribution_id,
                   NULL, --po_distribution_num,
                   NULL, --po_unit_of_measure,
                   NULL, --inventory_item_id,
                   NULL, --item_description,
                   NULL, --quantity_invoiced,
                   NULL, --ship_to_location_code,
                   NULL, --unit_price,
                   NULL, --distribution_set_id,
                   NULL, --distribution_set_name,
                   NULL, --dist_code_concatenated,
                   NULL,--vn_dist_code_combinaton_id, --dist_code_combination_id,
                   NULL, --awt_group_id,
                   NULL, --awt_group_name,
                   Fnd_Global.user_id, --last_updated_by,
                   SYSDATE, --last_update_date,
                   Fnd_Global.login_id, --last_update_login,
                   Fnd_Global.user_id, --created_by,
                   SYSDATE, --creation_date,
                   NULL, --attribute_category,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute1,..5,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute6, ..10,
                   NULL,
                   NULL,
                   NULL,
                   NULL,
                   NULL, --attribute11, ..15,
                   NULL, --global_attribute_category,
                   NULL,
                   NULL, --global_attribute1..2,
                   NULL,
                   NULL,
                   NULL, --global_attribute3..5,
                   NULL,
                   NULL,
                   NULL, --global_attribute6..8,
                   NULL,
                   NULL,
                   NULL, --global_attribute9..11,
                   NULL,
                   NULL,
                   NULL, --global_attribute12..14,
                   NULL,
                   NULL,
                   NULL, --global_attribute15..17,
                   NULL,
                   NULL,
                   NULL, --global_attribute18..20,
                   NULL, --po_release_id,
                   NULL, --release_num,
                   NULL, --account_segment,
                   NULL, --balancing_segment,
                   NULL, --cost_center_segment,
                   NULL, --project_id,
                   NULL, --task_id,
                   NULL, --expenditure_type,
                   NULL, --expenditure_item_date,
                   NULL, --expenditure_organization_id,
                   NULL, --project_accounting_context,
                   'N', --pa_addition_flag,
                   NULL, --pa_quantity,
                   NULL, --ussgl_transaction_code,
                   NULL, --stat_amount,
                   NULL, --type_1099,
                   NULL, --income_tax_region,
                   NULL, --assets_tracking_flag,
                   NULL, --price_correction_flag,
                   gv_org_id, --org_id,
                   NULL, --receipt_number,
                   NULL, --receipt_line_number,
                   NULL, --match_option,
                   NULL, --packing_slip,
                   NULL, --rcv_transaction_id,
                   NULL, --pa_cc_ar_invoice_id,
                   NULL, --pa_cc_ar_invoice_line_num,
                   NULL,
                   NULL, --reference_1, reference_2,
                   NULL, --pa_cc_processed_code,
                   'TVA',-- TAX
                   'FR_JURIDICTION', --TAX_JURISDICTION_CODE
                   'STANDARD', --TAX_STATUS_CODE
                   'DED_00.00D', --TAX_RATE_CODE
                   NULL, --tax_recovery_rate,
                   NULL, --tax_recovery_override_flag,
                   NULL, --tax_recoverable_flag,
                   NULL, --tax_code_override_flag,
                   NULL, --tax_code_id,
                   'FR-TAX', --TAX_REGIME_CODE
                   NULL, --credit_card_trx_id,
                   NULL --award_id
            FROM   DUAL;
            
            Fnd_File.put_line(Fnd_File.LOG,'Row inserted : '||TO_CHAR(SQL%ROWCOUNT));            
			
			
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_ap_inv_lines_int_tax;    
    
--> OBE artf2194455        

-------------------------------------------------------------------------------------
--  Nom           : LOAD_AP_INVOICES_INTERFACES
--  Description   : Procédure de chargement des tables AP_INVOICES_INTERFACES et
--              AP_INVOICES_LINES_INTERFACES
--  PARAMETRES    :
--    pv_collectivite     Entrée
--    pv_invoice_num      Entrée
--    pv_amount       Entrée
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE load_ap_invoices_interfaces (
        pv_collectivite   IN       VARCHAR2,
        pn_vendor_site_id IN       NUMBER,
        pv_invoice_num    IN       VARCHAR2,
        pv_amount         IN       VARCHAR2,
        pv_errbuf         OUT      VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS

        -- PHENIX 2004
        CURSOR cur_segments (
            cv_collectivite   IN   VARCHAR2,
            cn_vendor_site_id IN   NUMBER,
            cv_invoice_num    IN   VARCHAR2
        )
        IS
        SELECT segment1, segment2
        FROM   dka_sarsurtaxe_tmp
        WHERE  collectivite = cv_collectivite
        AND    invoice_num = cv_invoice_num
        AND    vendor_site_id = cn_vendor_site_id
		AND    STATUS <>'Z';
        rec_segments cur_segments%ROWTYPE;
        -- FIN PHENIX 2004

        ----- Curseur sur la table dka_sarsurtaxe_tmp traitant les factures de statut 'P' -----
        CURSOR cur2_tbl_dka_sarsurtaxe_tmp (
            cv_collectivite   IN   VARCHAR2,
            cn_vendor_site_id IN   NUMBER,
            cv_invoice_num    IN   VARCHAR2
        )
        IS
            SELECT dst.ROWID,
			       dst.cust_trx_line_gl_dist_id,
                   dst.je_header_id,
                   dst.je_line_num,
                   dst.invoice_num,
                   dst.amount,
                   dst.segment1,
                   dst.segment2,
                   dst.segment3,
                   dst.segment4,
                   dst.segment5,
                   dst.segment6,
                   dst.segment7,
                   dst.segment8,
                   dst.segment9, -- PHENIX 2004
                   dst.segment10, -- PHENIX 2004
                   dst.segment11, -- OBE
                   dst.segment12  -- OBE
            FROM   dka_sarsurtaxe_tmp dst
            WHERE      dst.collectivite = cv_collectivite
                   AND dst.invoice_num = cv_invoice_num
                   AND dst.vendor_site_id = cn_vendor_site_id
				   AND dst.STATUS <>'Z';

        invoices_detail_ar_rec   cur2_tbl_dka_sarsurtaxe_tmp%ROWTYPE;
        vn_invoice_id            NUMBER (15);
        vn_je_header_id          NUMBER (15);
        vn_je_line_num           NUMBER (15);
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf          := NULL;
        pn_retcode         := 0;
        vn_je_header_id    := invoices_detail_ar_rec.je_header_id;
        vn_je_line_num     := invoices_detail_ar_rec.je_line_num;
        ----- Appel de la procédure INSERT_AP_INVOICES_INTERFACE -----
        -- PHENIX 2004
        
        OPEN cur_segments (pv_collectivite, pn_vendor_site_id, pv_invoice_num);
        FETCH cur_segments INTO rec_segments;
        CLOSE cur_segments;
        
        --< OBE
        /*gv_responsibility_ref    := rec_segments.segment2||rec_segments.segment1||'_AP_ADMINISTRATEUR';
        
        Fnd_File.put_line(Fnd_File.LOG,'gv_responsibility_ref : '||gv_responsibility_ref);
        
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   gn_responsibility_id,
               gn_application_id
        FROM   fnd_responsibility fr
        WHERE  fr.responsibility_key = gv_responsibility_ref;

        
        fnd_global.apps_initialize (FND_PROFILE.VALUE('USER_ID'), gn_responsibility_id, gn_application_id);        
        MO_GLOBAL.INIT('SQLAP');
        Fnd_Profile.get ('ORG_ID', gv_org_id);
        Fnd_File.put_line(Fnd_File.LOG,'GV_ORG_ID : '|| gv_org_id);*/
        
        SELECT organization_id
        INTO gv_org_id
        FROM hr_operating_units
        WHERE name = rec_segments.segment2||rec_segments.segment1
        ;
        
        Fnd_File.put_line(Fnd_File.LOG,'Traitement de l''ORG_ID : '|| gv_org_id);
        
        --> OBE        

        Dka_Sarsurtaxe_Pkg.insert_ap_invoices_interface (pv_collectivite,
                                                         pn_vendor_site_id,
                                                         pv_invoice_num,
                                                         pv_amount,
                                                         rec_segments.segment1,
                                                         rec_segments.segment2,
                                                         vn_invoice_id,
                                                         pv_errbuf,
                                                         pn_retcode);
        -- FIN PHENIX 2004

        IF pn_retcode != 0
        THEN
            -- Mise à jour du motif de rejet de la ligne de la table dka_sarsurtaxe_tmp --
            UPDATE dka_sarsurtaxe_tmp dst
            SET    dst.status = 'R',
                   dst.rejection_reason = 'Factures non insérées dans la table AP_INVOICES_INTERFACE'
            WHERE  dst.invoice_num = pv_invoice_num
			  AND dst.STATUS <>'Z';
        ELSE
            ----- Ouverture du curseur ------
            OPEN cur2_tbl_dka_sarsurtaxe_tmp (pv_collectivite, pn_vendor_site_id, pv_invoice_num);

            ----- Chargement du curseur -----
            LOOP
                FETCH cur2_tbl_dka_sarsurtaxe_tmp INTO invoices_detail_ar_rec;
                EXIT WHEN cur2_tbl_dka_sarsurtaxe_tmp%NOTFOUND;
                
                ----- Appel de la procédure INSERT_AP_INVOICES_LINES_INTERFACES -----
                Dka_Sarsurtaxe_Pkg.insert_ap_inv_lines_interface (
                    vn_invoice_id,
                    invoices_detail_ar_rec.amount,
                    invoices_detail_ar_rec.cust_trx_line_gl_dist_id,
                    invoices_detail_ar_rec.je_header_id,
                    invoices_detail_ar_rec.je_line_num,
                    invoices_detail_ar_rec.segment1,
                    invoices_detail_ar_rec.segment2,
                    invoices_detail_ar_rec.segment3,
                    invoices_detail_ar_rec.segment4,
                    invoices_detail_ar_rec.segment5,
                    invoices_detail_ar_rec.segment6,
                    invoices_detail_ar_rec.segment7,
                    invoices_detail_ar_rec.segment8, 
                    invoices_detail_ar_rec.segment9,  -- PHENIX 2004
                    invoices_detail_ar_rec.segment10, -- PHENIX 2004
                    invoices_detail_ar_rec.segment11, -- OBE
                    invoices_detail_ar_rec.segment12, -- OBE
                    pv_errbuf,
                    pn_retcode
                );
                
                gn_line_number := gn_line_number + 1;

                IF pn_retcode != 0
                THEN
                    IF invoices_detail_ar_rec.cust_trx_line_gl_dist_id IS NULL
                    THEN
                        -- Mise à jour de la ligne de la table dka_sarsurtaxe_tmp : motif de rejet de la ligne pour les lignes venant de GERICC via GL --
                        UPDATE dka_sarsurtaxe_tmp dst
                        SET    dst.status = 'R',
                               dst.rejection_reason = 'Factures non insérées dans la table AP_INVOICE_LINES_INTERFACE - GERICC'
                        WHERE  dst.je_header_id = vn_je_header_id
                        AND dst.je_line_num = vn_je_line_num
                        AND dst.ROWID = invoices_detail_ar_rec.ROWID
						AND dst.STATUS <>'Z';
                    ELSE
                        -- Mise à jour de la ligne de la table dka_sarsurtaxe_tmp : motif de rejet de la ligne pour les lignes venant de AR --
                        UPDATE dka_sarsurtaxe_tmp dst
                        SET    dst.status = 'R',
                               dst.rejection_reason = 'Factures non insérées dans la table AP_INVOICE_LINES_INTERFACE - AR'
                        WHERE  dst.cust_trx_line_gl_dist_id = invoices_detail_ar_rec.cust_trx_line_gl_dist_id
                        AND dst.ROWID = invoices_detail_ar_rec.ROWID
						AND dst.STATUS <>'Z';
                    END IF;
                ELSE
                    -- Mise à jour du numéro de facture dans la table dka_sarsurtaxe_tmp --
                    UPDATE dka_sarsurtaxe_tmp dst
                    SET    dst.status = 'T',
                           dst.rejection_reason = 'Factures dans les tables interfaces AP',
                           dst.invoice_id = vn_invoice_id
                    WHERE  dst.invoice_num = pv_invoice_num
                    AND dst.ROWID = invoices_detail_ar_rec.ROWID
					AND dst.STATUS <>'Z';
                END IF;
            END LOOP;

            ----- Fermeture du curseur -----
            CLOSE cur2_tbl_dka_sarsurtaxe_tmp;
            
            --< OBE artf2194455
              
            ----- Appel de la procédure INSERT_AP_INVOICES_LINES_INTERFACE_TAX -----
            Dka_Sarsurtaxe_Pkg.insert_ap_inv_lines_int_tax (
                vn_invoice_id,
                pv_errbuf,
                pn_retcode
            );            

            IF pn_retcode != 0
            THEN
                -- Mise à jour de la ligne de la table dka_sarsurtaxe_tmp : motif de rejet de la ligne pour les lignes venant de AR --
                UPDATE dka_sarsurtaxe_tmp dst
                SET    dst.status = 'R',
                       dst.rejection_reason = 'Ligne de TAX non insérée dans la table AP_INVOICE_LINES_INTERFACE - AR'
                WHERE  dst.cust_trx_line_gl_dist_id = invoices_detail_ar_rec.cust_trx_line_gl_dist_id
                AND dst.ROWID = invoices_detail_ar_rec.ROWID
				AND dst.STATUS <>'Z';
           END IF;            

            --> OBE artf2194455
                
        END IF;

        Fnd_File.put_line(Fnd_File.LOG,'FIN de la procédure LOAD_AP_INVOICES_INTERFACES');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END load_ap_invoices_interfaces;


-------------------------------------------------------------------------------------
--  Nom           : LOAD_DATA
--  Description   : Procédure de traitement des données de la table dka_sarsurtaxe_tmp
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK  ou 2: erreur
------------------------------------------------------------------------------------
    PROCEDURE load_data (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
        ----- Curseur sur la table dka_sarsurtaxe_tmp traitant les factures de statut 'P' -----
        CURSOR cur_tbl_dka_sarsurtaxe_tmp
        IS
            SELECT   collectivite,
                     vendor_site_id,
                     invoice_num,
                     SUM (amount) amount
            FROM     dka_sarsurtaxe_tmp
            WHERE    status = 'P'
            GROUP BY collectivite,
                     vendor_site_id,
                     invoice_num;

        invoices_ar_rec   cur_tbl_dka_sarsurtaxe_tmp%ROWTYPE;
    BEGIN
    
        --< OBE
        /*gv_responsibility_ref    := 'DRW0028_AR_ADMINISTRATEUR';

        SELECT fr.responsibility_id,
               fr.application_id
        INTO   gn_responsibility_id,
               gn_application_id   
        FROM   fnd_responsibility fr
        WHERE  fr.responsibility_key = gv_responsibility_ref;

        fnd_global.apps_initialize (FND_PROFILE.VALUE('USER_ID'), gn_responsibility_id, gn_application_id);*/
        --MO_GLOBAL.INIT('AR');        
        
        --> OBE
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début de la procédure LOAD_DATA');
        ----- Ouverture du curseur ------
        OPEN cur_tbl_dka_sarsurtaxe_tmp;

        ----- Chargement du curseur -----
        LOOP
            FETCH cur_tbl_dka_sarsurtaxe_tmp INTO invoices_ar_rec;
            EXIT WHEN cur_tbl_dka_sarsurtaxe_tmp%NOTFOUND;
            
            Dka_Sarsurtaxe_Pkg.load_ap_invoices_interfaces (invoices_ar_rec.collectivite, invoices_ar_rec.vendor_site_id, invoices_ar_rec.invoice_num, invoices_ar_rec.amount, pv_errbuf, pn_retcode);
        END LOOP;

        ----- Fermeture du curseur -----
        CLOSE cur_tbl_dka_sarsurtaxe_tmp;
        Fnd_File.put_line(Fnd_File.LOG,'FIN de la procédure LOAD_DATA');
    END load_data;


--------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
 --
 --  PARAMETRES :
 --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
 --    pn_retcode                  Sortie          status du traitement en sortie
 --
 --  VALEUR RETOURNEE :
 --     Description       : code retour de validité
 --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
 --
 ----------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure principale' || CHR (10));
        ----- Appel de la procédure INIT -----
        Dka_Sarsurtaxe_Pkg.init (pv_errbuf, pn_retcode);
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'gv_source : ' || gv_source);
        ----- Appel de la procédure PURGE_DKA_SARSURTAXE_TMP -----
        Dka_Sarsurtaxe_Pkg.purge_dka_sarsurtaxe_tmp (pv_errbuf, pn_retcode);
        ----- Appel de la procédure INSERT_DKA_SARSURTAXE_TMP -----
        Dka_Sarsurtaxe_Pkg.insert_dka_sarsurtaxe_tmp (pv_errbuf, pn_retcode);

        -- Début modif du 25/10/2006 : Le calcul des statistiques est obsolète 
        -- CD 15/05 Ajout analyse de la table pour les stats après insertion
        -- DBMS_DDL.ANALYZE_OBJECT('TABLE', 'DKA' ,'dka_sarsurtaxe_tmp', 'ESTIMATE');
        -- Fin modif EMA du 25/10/2006 

        ----- Appel de la procédure LOAD_DATA -----
        Dka_Sarsurtaxe_Pkg.load_data (pv_errbuf, pn_retcode);
    END main;


------------------------------------------------------------------------------------
--       SUITE DU TRAITEMENT APRES L'EXECUTION DU TRAITEMENT STANDARD             --
--                 CREATION DES FACTURES AR DANS AP                               --
------------------------------------------------------------------------------------




--------------------------------------------------------------------------------------
--  Nom           : UPDATE_AFTER_IMPORT_AP
--  Description   : Procédure de mise à jour de la table dka_sarsurtaxe_tmp apres le traitement
--              standard 'programme d'importation de l'interface coopérative d'oracle Payables'
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE update_after_import_ap (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure UPDATE_AFTER_IMPORT_AP' || CHR (10));

        ----- Mise à jour du statut des lignes après le traitement standard -----
        UPDATE dka_sarsurtaxe_tmp dst
        SET    dst.status = 'R',
               dst.rejection_reason = (SELECT alc.description
                                       FROM   ap_lookup_codes alc,
                                              ap_interface_rejections air
                                       WHERE      alc.lookup_type = 'REJECT CODE'
                                              AND alc.lookup_code = air.reject_lookup_code
                                              AND air.parent_id = dst.invoice_id
											  and rownum = 1) -- IBA TASK0175032
        WHERE  dst.invoice_id IN (SELECT aii.invoice_id
                                  FROM   ap_invoices_interface aii
                                  WHERE  aii.status = 'REJECTED')
		  AND dst.STATUS <>'Z';

        UPDATE dka_sarsurtaxe_tmp dst
        SET    dst.status = 'X',
               dst.rejection_reason = 'Factures AP crees'
        WHERE  dst.invoice_id IN (SELECT aii.invoice_id
                                  FROM   ap_invoices_interface aii
                                  WHERE  aii.status = 'PROCESSED')
		  AND dst.STATUS <>'Z';
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END update_after_import_ap;


--------------------------------------------------------------------------------------
--  Nom           : UPDATE_RA_CUST_TRX_LINE_GL_DIS
--  Description   : Procédure de mise à jour de la table ra_cust_trx_line_gl_dist_all
--              apres le transfert des factures AR dans AP
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE update_ra_cust_trx_line_gl_dis (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure UPDATE_RA_CUST_TRX_LINE_GL_DIS' || CHR (10));

        ----- Mise à jour de l'attribute1( identifiant B) après le transfert des factures AR dans AP -----
        UPDATE ra_cust_trx_line_gl_dist_all rctlgd
        SET    rctlgd.attribute6 = (SELECT dst.invoice_num
                                    FROM   dka_sarsurtaxe_tmp dst
                                    WHERE  dst.cust_trx_line_gl_dist_id = rctlgd.cust_trx_line_gl_dist_id
									AND dst.STATUS <>'Z')
        WHERE  rctlgd.cust_trx_line_gl_dist_id IN
                                      (SELECT dst.cust_trx_line_gl_dist_id
                                       FROM   dka_sarsurtaxe_tmp dst,
                                              ap_invoices_interface aii
                                       WHERE      dst.invoice_id = aii.invoice_id
                                              AND aii.status = 'PROCESSED'
											  AND dst.STATUS <>'Z');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END update_ra_cust_trx_line_gl_dis;


--------------------------------------------------------------------------------------
--  Nom           : UPDATE_GL_JE_LINES_CUF
--  Description   : Procédure de mise à jour du cuf 'transféré dans AP' de la table gl_je_lines
--              après le transfert des lignes de facture contenant de la surtaxe
--              pour les clients de type GERICCO dans AP
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE update_gl_je_lines_cuf (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure UPDATE_GL_JE_LINES_CUF' || CHR (10));

        ----- Mise à jour de l'attribute10(avec identifiant B) après la création de la facture dans AP -----
        UPDATE gl_je_lines gjl
        SET    gjl.attribute19 = (SELECT dst.invoice_num
                                  FROM   dka_sarsurtaxe_tmp dst
                                  WHERE      dst.je_header_id = gjl.je_header_id
                                         AND dst.je_line_num = gjl.je_line_num
										 AND dst.STATUS <>'Z')
        WHERE  (gjl.je_header_id, gjl.je_line_num) IN
                                 (SELECT dst.je_header_id,
                                         dst.je_line_num
                                  FROM   dka_sarsurtaxe_tmp dst,
                                         ap_invoices_interface aii
                                  WHERE      dst.invoice_id = aii.invoice_id
                                         AND aii.status = 'PROCESSED'
										 AND dst.STATUS <>'Z');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END update_gl_je_lines_cuf;


-------------------------------------------------------------------------------------
--  Nom           : PURGE_AP_INVOICES_INTERFACE
--  Description   : Procédure de purge des tables d'interfaces AP
--
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK  ou 2: erreur
------------------------------------------------------------------------------------
    PROCEDURE purge_ap_invoices_interface (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,'début de la procédure PURGE_AP_INVOICES_INTERFACE');

        ----- Purge des tables d'interfaces ap_invoice_lines_interface et ap_invoices_interface  -----
        DELETE FROM ap_invoice_lines_interface aili
        WHERE       aili.invoice_id IN (SELECT aii.invoice_id
                                        FROM   ap_invoices_interface aii
                                        WHERE  aii.SOURCE = gv_source);

        DELETE FROM ap_invoices_interface
        WHERE       SOURCE = gv_source;

        --COMMIT;
        Fnd_File.put_line(Fnd_File.LOG,'fin de la procédure PURGE_AP_INVOICES_INTERFACE');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END purge_ap_invoices_interface;


--------------------------------------------------------------------------------------
--  Nom           : launch_apprvl
--  Description   : Procédure qui permet de lancer le traitment standard APPRVL
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE launch_apprvl (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS    
    
    vv_phase                  VARCHAR2 (100);
    vv_status                 VARCHAR2 (100);
    vv_dev_phase              VARCHAR2 (100);
    vv_name                   VARCHAR2 (100);
    vv_dev_status             VARCHAR2 (100);
    vv_message                VARCHAR2 (100);
    vn_request_id             NUMBER (15);
    vv_trace_option VARCHAR2(10);
    vv_debug_switch VARCHAR2(10);
    
    BEGIN
    
      ----- Initialisation des variables de sortie de la procédure -----
      pv_errbuf     := NULL;
      pn_retcode    := 0;
      Fnd_File.put_line(Fnd_File.LOG,'début de la procédure LAUNCH_APPRVL');    
    
      SELECT DECODE(meaning,'Oui','Y','N') 
      INTO vv_trace_option
      FROM fnd_lookups 
      WHERE lookup_type = 'YES_NO' 
      AND lookup_code = 'N'
      ;
      
      SELECT DECODE(meaning,'Oui','Y','N') 
      INTO vv_debug_switch
      FROM fnd_lookups 
      WHERE lookup_type = 'YES_NO' 
      AND lookup_code = 'N'
      ;
      
      -- Lancemet du traitement validation de factures
      FOR rec IN (--< OBE artf2205925
                  /*SELECT DISTINCT set_of_books_id, b.name
                  FROM dka_sarsurtaxe_tmp a,
                       hr_operating_units b
                  WHERE b.organization_id = a.org_id*/
                  SELECT b.set_of_books_id, b.name, b.organization_id, MIN(c.invoice_date) min_date, MAX(c.invoice_date) max_date
                  FROM dka_sarsurtaxe_tmp a,
                       hr_operating_units b,
                       ap_invoices c
                  WHERE b.organization_id = a.org_id
                  AND c.invoice_num = a.invoice_num
				  AND a.STATUS <>'Z'
                  GROUP BY b.set_of_books_id, b.name, b.organization_id
                  --> OBE artf2205925
          )
      LOOP
      
      gv_responsibility_ref    := rec.name||'_AP_ADMINISTRATEUR';
      
      Fnd_File.put_line(Fnd_File.LOG,'gv_responsibility_ref : '||gv_responsibility_ref);
      
      SELECT fr.responsibility_id,
             fr.application_id
      INTO   gn_responsibility_id,
             gn_application_id
      FROM   fnd_responsibility fr
      WHERE  fr.responsibility_key = gv_responsibility_ref;

      
      fnd_global.apps_initialize (FND_PROFILE.VALUE('USER_ID'), gn_responsibility_id, gn_application_id);        
      MO_GLOBAL.INIT('SQLAP');

      Fnd_File.put_line(Fnd_File.LOG,'Lancement du traitement de validation de factures pour le livre : '||rec.set_of_books_id);          
      
              vn_request_id := fnd_request.submit_request ( 
                                  'SQLAP',              -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                  'APPRVL',             -- SHORT NAME DU TRAITEMENT
                                  NULL,                 -- PROGRAM NAME
                                  NULL,                 -- START
                                  FALSE,                -- SUB REQUEST
                                  rec.organization_id,  --ARGUMENT1 -- OBE artf2205925
                                  'New',                --ARGUMENT2
                                  NULL,                 --ARGUMENT3
                                  TO_CHAR(rec.min_date,'YYYY/MM/DD HH24:MI:SS'), --ARGUMENT4 -- OBE artf2205925
                                  TO_CHAR(rec.max_date,'YYYY/MM/DD HH24:MI:SS'), --ARGUMENT5 -- OBE artf2205925
                                  NULL,                 --ARGUMENT6
                                  NULL,                 --ARGUMENT7
                                  NULL,                 --ARGUMENT8
                                  NULL,                 --ARGUMENT9
                                  rec.set_of_books_id,  --ARGUMENT10
                                  vv_trace_option,      --ARGUMENT11
                                  1000,                 --ARGUMENT12
                                  1,                    --ARGUMENT13
                                  vv_debug_switch       --ARGUMENT14
                                   );                                        

              IF vn_request_id = 0
              THEN
                  pn_retcode    := 2;
                  Fnd_File.put_line(Fnd_File.LOG,' Le traitement de Validation de factures a échoué!');
              ELSE
                  Fnd_File.put_line(Fnd_File.LOG,' vv_dev_phase  OR vv_dev_status : '|| vv_dev_phase || '   ' || vv_dev_status);
                  COMMIT;

                  IF NOT (Fnd_Concurrent.wait_for_request (vn_request_id, 60, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_message))
                  THEN
                      Fnd_File.put_line(Fnd_File.LOG,'Attente du programme de la fin Validation de factures dépassé : Fin du traitement ');
                  ELSIF (    vv_dev_phase = 'COMPLETE'
                         AND vv_dev_status = 'NORMAL'
                        )
                  THEN
                      --dka_tools_pkg.put_debug_message(' vv_dev_phase  OR vv_dev_status : '||vv_dev_phase||vv_dev_status);
                      Fnd_File.put_line(Fnd_File.LOG,'L''éxécution de Validation de factures OK');
                  END IF; -- fin IF NOT
              END IF; -- fin if request        
              
      END LOOP;
      
     Fnd_File.put_line(Fnd_File.LOG,'fin de la procédure LAUNCH_APPRVL');          

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;    
    
    
    END launch_apprvl;    
--------------------------------------------------------------------------------------
--  Nom           : MAIN2
--  Description   : Procédure
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main2 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS

      
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure MAIN2' || CHR (10));
        ----- Appel de la procédure INIT -----
        Dka_Sarsurtaxe_Pkg.init (pv_errbuf, pn_retcode);
        ----- Appel de la procédure UPDATE_AFTER_IMPORT_AP -----
        Dka_Sarsurtaxe_Pkg.update_after_import_ap (pv_errbuf, pn_retcode);
        ----- Appel de la procédure UPDATE_RA_CUST_TRX_LINE_GL_DIS -----
        ----- Mise à jour du CUF 'transferé dans AP' sur le panneau AR  -----
        Dka_Sarsurtaxe_Pkg.update_ra_cust_trx_line_gl_dis (pv_errbuf, pn_retcode);
        ----- Appel de la procédure UPDATE_GL_JE_LINES -----
        ----- Mise à jour du CUF 'transferé dans AP' de gl_je_lines  -----
        Dka_Sarsurtaxe_Pkg.update_gl_je_lines_cuf (pv_errbuf, pn_retcode);
        ----- Appel de la procédure PURGE_AP_INVOICES_INTERFACE -----
        --Dka_Sarsurtaxe_Pkg.purge_ap_invoices_interface (pv_errbuf, pn_retcode);
        
    END main2;


------------------------------------------------------------------------------------
--       SUITE DU TRAITEMENT APRES L'EXECUTION DU TRAITEMENT STANDARD             --
--                 IMPUTATION DES FACTURES AP DANS GL                             --
------------------------------------------------------------------------------------




--------------------------------------------------------------------------------------
--  Nom           : UPDATE_GL_JE_LINES
--  Description   : Procédure qui permet de renseigner la référence de lettrage.
--
--  PARAMETRES :
--    pv_invoice_num              Entrée
--    pv_nom_collecti             Entrée
--    pv_ccid             Entrée
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE update_gl_je_lines (
        pv_invoice_num    IN       VARCHAR2,
        pv_nom_collecti   IN       VARCHAR2,
        pv_ccid           IN       NUMBER,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure UPDATE_GL_JE_LINES' || CHR (10));
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'pv_invoice_num' || pv_invoice_num);
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'pv_nom_collecti' || pv_nom_collecti);


        UPDATE gl_je_lines_recon gjl -- OBE
               --gl_je_lines gjl      -- OBE
        SET    gjl.jgzz_recon_ref = ltrim(substr(pv_invoice_num,instr(pv_invoice_num,'-')+1))
        WHERE  gjl.jgzz_recon_ref IS NULL
        AND (gjl.je_header_id, gjl.je_line_num) IN (SELECT gjh.je_header_id,
                                                           gjl_2.je_line_num
                                                    --< OBE artf2202971       
                                                    FROM   gl_je_headers gjh,
                                                           gl_je_lines gjl_2,
                                                           XLA_AE_HEADERS xlah2,
                                                           XLA_AE_LINES xlal2,
                                                           dka_sarsurtaxe_tmp dst
                                                    WHERE      gjh.je_source = 'Receivables'
                                                    AND gjl_2.je_header_id = gjh.je_header_id
                                                    AND gjl_2.code_combination_id = dst.ccid
                                                    and xlal2.gl_sl_link_id = gjl_2.gl_sl_link_id
                                                    and xlal2.ae_header_id = xlah2.ae_header_id         
                                                    and xlah2.description like '%'||dst.trx_number||'%'                                                           
                                                    AND dst.invoice_num = pv_invoice_num
													AND dst.STATUS <>'Z'
                                                    /*       
                                                    FROM   gl_je_headers gjh,
                                                           gl_je_lines gjl_2,
                                                           dka_sarsurtaxe_tmp dst,
                                                           ra_customer_trx rct,
                                                           ra_cust_trx_types rctt
                                                    WHERE gjh.je_source = 'Receivables' --'AR Translator' -- OBE
                                                    AND gjl_2.je_header_id = gjh.je_header_id
                                                    AND dst.invoice_num = pv_invoice_num
                                                    --AND gjl_2.reference_3 = TO_CHAR(dst.cust_trx_line_gl_dist_id) -- OBE
                                                    AND rct.customer_trx_id = dst.customer_trx_id
                                                    AND rct.cust_trx_type_id = rctt.cust_trx_type_id
                                                    AND gjl_2.description = rctt.NAME || ' ' || rct.trx_number
                                                    */
                                                    --> OBE artf2202971
                                                    UNION ALL
                                                    SELECT gjh_2.je_header_id,
                                                           gjl_3.je_line_num
                                                    FROM   gl_je_headers gjh_2,
                                                           gl_je_lines gjl_3,
                                                           XLA_AE_HEADERS xlah, -- OBE
                                                           XLA_AE_LINES xlal    -- OBE
                                                    WHERE      gjh_2.je_source = 'Payables' --'AP Translator' -- OBE
                                                    AND gjl_3.je_header_id = gjh_2.je_header_id
                                                    AND gjl_3.code_combination_id = pv_ccid
                                                    --AND gjl_3.reference_1 = pv_nom_collecti
                                                    --AND gjl_3.reference_5 = pv_invoice_num
                                                    and xlal.gl_sl_link_id = gjl_3.gl_sl_link_id       -- OBE
                                                    and xlal.ae_header_id = xlah.ae_header_id          -- OBE
                                                    and xlah.description like '%'||pv_invoice_num||'%' -- OBE
                                                    UNION ALL
                                                    SELECT dst.je_header_id,
                                                           dst.je_line_num
                                                    FROM   dka_sarsurtaxe_tmp dst
                                                    WHERE  dst.invoice_num = pv_invoice_num
													  AND  dst.STATUS <>'Z'
								    );

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END update_gl_je_lines;


--------------------------------------------------------------------------------------
--  Nom           : LOAD_REF_LET
--  Description   : Procédure qui permet de renseigner la référence de lettrage.
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE load_ref_let (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        ----- Curseur sur la table dka_sarsurtaxe_tmp traitant les factures de statut 'X' -----
        CURSOR cur3_tbl_dka_sarsurtaxe_tmp
        IS
            SELECT DISTINCT segment1,
                            segment2,
                            segment3,
                            segment4,
                            segment5,
                            segment6,
                            segment7,
                            segment8,
                            segment9, -- PHENIX 2004
                            segment10, -- PHENIX 2004	
                            segment11,    -- OBE
                            segment12,    -- OBE
                            collectivite, -- OBE
                            invoice_num
            FROM            dka_sarsurtaxe_tmp
            WHERE           status = 'X';

        invoices_num_rec             cur3_tbl_dka_sarsurtaxe_tmp%ROWTYPE;
        vv_dummy                     VARCHAR2 (25);
        vv_jgzz_recon_flag           VARCHAR2 (1);
        vv_dist_code_combinaton_id   NUMBER; --CD VARCHAR2(20);
		vv_dist_code_combinaton_id2  NUMBER;
	      vv_description_segment5 	   VARCHAR2 (240); --CD  -- PHENIX 2004
	      vv_segment4					         VARCHAR2 (10); --CD 18/04 -- PHENIX 2004
        vv_nom_fournisseur           VARCHAR2 (240);
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure LOAD_REF_LET' || CHR (10));
        ----- Ouverture du curseur ------
        OPEN cur3_tbl_dka_sarsurtaxe_tmp;

        ----- Chargement du curseur -----
        LOOP
            FETCH cur3_tbl_dka_sarsurtaxe_tmp INTO invoices_num_rec;
            EXIT WHEN cur3_tbl_dka_sarsurtaxe_tmp%NOTFOUND;
            Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'appel de la procédure get_code_combination_id' || CHR (10));

            -- Selection du compte de ventilation suivant la société collectrice --
            SELECT DECODE (invoices_num_rec.segment3, '467300', '467301', '467297')
            INTO   vv_dummy
            FROM   DUAL;
			
			
	  		--18/04 début CD Récupération du nouveau compte groupe
  			Dka_Sarsurtaxe_Pkg.get_segment4 (vv_dummy, vv_segment4, pv_errbuf, pn_retcode); -- PHENIX 2004  
  			
		  	IF pn_retcode != 0 
	 		  THEN
			      Fnd_File.put_line(Fnd_File.LOG,'Erreur : '||pv_errbuf);
						
			  ELSE
			
		   
            -- Appel de la fonction get_code_combination_id pour retrouver le ccid --
            Dka_Tools_Pkg.get_code_combination_id (
                invoices_num_rec.segment1,
                invoices_num_rec.segment2, --CD 18/04 invoices_num_rec.segment2, -- PHENIX 2004 
                vv_dummy,
                vv_segment4, -- PHENIX 2004
                invoices_num_rec.segment5,
                invoices_num_rec.segment6,
                invoices_num_rec.segment7,
                invoices_num_rec.segment8,
                invoices_num_rec.segment9, -- PHENIX 2004
				        invoices_num_rec.segment10, -- PHENIX 2004				
                invoices_num_rec.segment11, -- OBE
				        invoices_num_rec.segment12, -- OBE
                vv_dist_code_combinaton_id,
                pv_errbuf,
                pn_retcode
            );
            Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'vv_dist_code_combinaton_id,' || vv_dist_code_combinaton_id);
			  END IF;
			
        --< OBE
        /*
  		  -- début CD  
  		  -- Recherche de la description associee au segment4
  		     SELECT ffvv.description
	  	     INTO vv_description_segment5   -- PHENIX 2004 
	  	     FROM --gl_sets_of_books gsob, -- OBE
                gl_ledgers gl,           -- OBE
  		          fnd_flex_values_vl ffvv,
  		          fnd_id_flex_segments fifs	
  		     WHERE ffvv.flex_value_set_id = fifs.flex_value_set_id
  		       --AND gsob.set_of_books_id = Fnd_Profile.VALUE('GL_SET_OF_BKS_ID') -- OBE
             AND gl.ledger_id = fnd_profile.VALUE('GL_SET_OF_BKS_ID')           -- OBE
  		       AND fifs.id_flex_num = gl.chart_of_accounts_id
  		       AND fifs.application_id = 101
  		       AND fifs.id_flex_code = 'GL#'
  		       AND fifs.application_column_name = 'SEGMENT5' -- PHENIX 2004
  		       AND ffvv.flex_value = invoices_num_rec.segment5;  -- PHENIX 2004
  		  -- fin CD
        */
        
        
        --> OBE
        -- CD 140508 récupération du nom du fournisseur pour passer en paramètre de la fonction update_gl_je_lines à la place de
        -- vv_description_segment5 car parfois la description du segment5 est différente du nom du fournisseur de surtaxe correspondant.
    		    SELECT pv.vendor_name
		        INTO vv_nom_fournisseur  
		        FROM po_vendors pv
		        WHERE pv.vendor_id = TO_NUMBER(invoices_num_rec.collectivite) -- OBE
            --pv.attribute6 = invoices_num_rec.segment5  -- OBE
            ;


            -- Vérification de la l'autorisation de lettrage sur les comptes utilisés --
            --< OBE
            SELECT jgzz_recon_flag
            INTO   vv_jgzz_recon_flag
            FROM   gl_code_combinations gcc
            WHERE  gcc.code_combination_id = vv_dist_code_combinaton_id;
            
            --vv_jgzz_recon_flag := 'Y';
            --> OBE

            Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'vv_dist_code_combinaton_id,' || vv_jgzz_recon_flag);

            IF vv_jgzz_recon_flag != 'Y'
            THEN
                -- Le Compte n'autorise pas le lettrage --
                Fnd_File.put_line(Fnd_File.LOG,CHR (10) || ' le compte ayant le ccid :' || vv_dist_code_combinaton_id || ' n-autorise pas le lettrage ');
            ELSE
                -- Appel de la procédure UPDATE_GL_JE_LINES pour renseigner la référence de lettrage--
                Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'appel de la procédure update_gl_je_lines' || CHR (10));
                -- CD dka_sarsurtaxe_pkg.update_gl_je_lines (invoices_num_rec.invoice_num, invoices_num_rec.segment4, vv_dist_code_combinaton_id, pv_errbuf, pn_retcode);
                -- CD 140508 Dka_Sarsurtaxe_Pkg.update_gl_je_lines (invoices_num_rec.invoice_num, vv_description_segment5, vv_dist_code_combinaton_id, pv_errbuf, pn_retcode); -- PHENIX 2004
                Dka_Sarsurtaxe_Pkg.update_gl_je_lines (invoices_num_rec.invoice_num, vv_nom_fournisseur, vv_dist_code_combinaton_id, pv_errbuf, pn_retcode);



                IF pn_retcode != 0
                THEN
                    -- Erreur sur le renseignement du critère de lettrage --
                    Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'Erreur lors de la mise à jour de la référence de lettrage' || CHR (10));

                    -- Mise a jour du statut de la ligne dans dka_sarsurtaxe --
                    UPDATE dka_sarsurtaxe_tmp dst
                    SET    dst.status = 'W',
                           dst.rejection_reason = 'réference de lettrage pas indiquée '
                    WHERE  dst.invoice_num = invoices_num_rec.invoice_num;
                ELSE
                    Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'Mise à jour de la référence de lettrage' || CHR (10));

                    -- Mise a jour du statut de la ligne dans dka_sarsurtaxe --
                    UPDATE dka_sarsurtaxe_tmp dst
                    SET    dst.status = 'L',
                           dst.rejection_reason = 'réference de lettrage indiquée '
                    WHERE  dst.invoice_num = invoices_num_rec.invoice_num;
                END IF;
            END IF;
			
			--< OBE artf3017857
			
			-- Récupération du ccid de l'OG GL débit venant de AR
  			Dka_Sarsurtaxe_Pkg.get_segment4 (invoices_num_rec.segment3, vv_segment4, pv_errbuf, pn_retcode);
  			
		  	IF pn_retcode != 0 THEN
			      Fnd_File.put_line(Fnd_File.LOG,'Erreur : '||pv_errbuf);
						
			ELSE
			
		   
            -- Appel de la fonction get_code_combination_id pour retrouver le ccid --
            Dka_Tools_Pkg.get_code_combination_id (
                invoices_num_rec.segment1,
                invoices_num_rec.segment2,
                invoices_num_rec.segment3,
                vv_segment4,
                invoices_num_rec.segment5,
                invoices_num_rec.segment6,
                invoices_num_rec.segment7,
                invoices_num_rec.segment8,
                invoices_num_rec.segment9,
				invoices_num_rec.segment10,
                invoices_num_rec.segment11,
				invoices_num_rec.segment12,
                vv_dist_code_combinaton_id2,
                pv_errbuf,
                pn_retcode
            );
            Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'vv_dist_code_combinaton_id2,' || vv_dist_code_combinaton_id2);
			END IF;			
			
			--< OBE artf2376874			
			update dka_sarsurtaxe_tmp
			set ccid = vv_dist_code_combinaton_id2
			where invoice_num = invoices_num_rec.invoice_num
			 AND STATUS <>'Z';
			--> OBE artf2376874			
			
			--> OBE artf3017857
			
        END LOOP;

        ----- fermeture du curseur ------
        CLOSE cur3_tbl_dka_sarsurtaxe_tmp;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END load_ref_let;


--------------------------------------------------------------------------------------
--  Nom           : MAIN3
--  Description   : Procédure qui permet de renseigner la référence de lettrage.
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main3 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure MAIN3' || CHR (10));
        -----On renseigne la référence de lettrage : appel de la procédure LOAD_REF_LET -----

        -- Début modif EMA du 25/10/2006 : Le calcul des statistiques est obsolète
        -- CD 07/04/04 Ajout analyse des tables pour les stats avant update
        -- DBMS_DDL.ANALYZE_OBJECT('TABLE', 'GL' ,'GL_JE_HEADERS', 'ESTIMATE');
        -- DBMS_DDL.ANALYZE_OBJECT('TABLE', 'GL' ,'GL_JE_LINES', 'ESTIMATE');
        -- Fin modif EMA du 25/10/2006

        Dka_Sarsurtaxe_Pkg.load_ref_let (pv_errbuf, pn_retcode);
    --  Mise à jour du statut de la ligne à 'L' dans la table dka_sarsurtaxe_tmp --
    --dka_sarsurtaxe_pkg.update_dka_sarsurtaxe_tmp (pv_errbuf,pn_retcode);



    END main3;


--------------------------------------------------------------------------------------
--        CREATION D'UNE OPERATION DIVERSE DANS GL                  --
--------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------
--  Nom           : INSERT_GL_INTERFACE_CONTROL
--  Description   : Procédure permettant l'insertion dans la table GL_INTERFACE_CONTROL
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE insert_gl_interface_control (
        pn_group_id           OUT      NUMBER,
        pn_interface_run_id   OUT      NUMBER,
        pv_errbuf             IN OUT   VARCHAR2,
        pn_retcode            OUT      NUMBER
    )
    IS

    vv_je_source_name       VARCHAR2(25);

    BEGIN
        -- Selection du group_id --
        SELECT gl_interface_control_s.NEXTVAL
        INTO   pn_group_id
        FROM   DUAL;

        --Récupération du je_source_name --user_je_source_name
        SELECT  je_source_name
        INTO vv_je_source_name
        FROM gl_je_sources
        WHERE user_je_source_name = gv_user_je_source_name;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'INSERT_GL_INTERFACE_CONTROL' || CHR (10));
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'pn_group_id :   ' || TO_CHAR (pn_group_id));

        -- Selection du interface_run_id --
        SELECT gl_journal_import_s.NEXTVAL
        INTO   pn_interface_run_id
        FROM   DUAL;

        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'pn_interface_run_id :' || TO_CHAR (pn_interface_run_id));

        INSERT INTO gl_interface_control
                    (je_source_name,
                     status,
                     interface_run_id,
                     GROUP_ID,
                     set_of_books_id,
                     packet_id
                    )
            SELECT vv_je_source_name,
                   'S',
                   pn_interface_run_id,
                   pn_group_id,
                   --Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID'),
                   hr.set_of_books_id,
                   NULL
            FROM  dka_sarsurtaxe_tmp dst          -- OBE
                 ,hr_operating_units hr           -- OBE
            WHERE 1=1                             -- OBE
            AND   hr.organization_id = dst.org_id -- OBE
			AND   dst.STATUS <>'Z'
            GROUP BY hr.set_of_books_id           -- OBE
            ;                                     -- OBE
            --DUAL;                               -- OBE
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_gl_interface_control;


--------------------------------------------------------------------------------------
--  Nom           : INSERT_GL_INTERFACE
--  Description   : Procédure permettant l'insertion dans la table GL_INTERFACE
--
--  PARAMETRES :
--    pn_group_id         Entrée
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE insert_gl_interface (
        pn_group_id   IN       NUMBER,
        pv_errbuf     IN OUT   VARCHAR2,
        pn_retcode    OUT      NUMBER
    )
    IS
    BEGIN
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'INSERT_GL_INTERFACE' || CHR (10));
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'pn_group_id :   ' || TO_CHAR (pn_group_id));

        -- Insertion d'une OD débit venant de AR et GL --
        INSERT INTO gl_interface
                    (status,
                     --set_of_books_id,
                     ledger_id, -- OBE
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
                     status_description,
                     stat_amount,
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
            SELECT   'NEW', -- status,
                     --Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID'), -- Set_of_books_id, -- OBE
                     hr.set_of_books_id,                                           -- OBE
                     TRUNC(SYSDATE), -- accounting_date,
                     dst.invoice_currency_code, -- currency_code,
                     SYSDATE, -- date_created,
                     Fnd_Global.user_id, --created_by,
                     'A', --actual_flag,
                     gv_user_je_category_name, --user_je_category_name,
                     gv_user_je_source_name, --user_je_source_name,
                     NULL, --currency_conversion_date,
                     NULL, --encumbrance_type_id,
                     NULL, --budget_version_id,
                     NULL, --user_currency_conversion_type,
                     NULL, --currency_conversion_rate,
                     NULL, --average_journal_flag,
                     NULL, --originating_bal_seg_value,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --segment1, segment2, segment3, segment4, segment5, segment6, segment7, segment8,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --segment9, segment10, segment11, segment12, segment13, segment14, segment15, segment16,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --segment17, segment18, segment19, segment20, segment21, segment22, segment23, segment24,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --segment25, segment26, segment27, segment28, segment29, segment30,
                     SUM (dst.amount), --entered_dr,
                     NULL, -- entered_cr,
                     NULL, -- accounted_dr,
                     NULL, -- accounted_cr,
                     NULL, --transaction_date,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --reference1, reference2, reference3, reference4, reference5, reference6, reference7,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --reference8, reference9, reference10, reference11, reference12, reference13, reference14,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --reference15, reference16, reference17, reference18, reference19, reference20, reference21,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --reference22, reference23, reference24, reference25, reference26, reference27, reference28,
                     NULL,
                     NULL, --reference29, reference30,
                     NULL, --je_batch_id,
                     NULL, --period_name,
                     NULL, --je_header_id,
                     NULL, --je_line_num,
                     NULL, --chart_of_accounts_id,
                     NULL, --functional_currency_code,
                     dst.ccid, --code_combination_id,
                     NULL, --date_created_in_gl,
                     NULL, --warning_code,
                     NULL, --status_description,
                     NULL, --stat_amount,
                     pn_group_id, --group_id,
                     NULL, --request_id,
                     NULL, --subledger_doc_sequence_id,
                     NULL, --subledger_doc_sequence_value,
                     NULL,
                     NULL, --attribute1, attribute2,
                     NULL,
                     NULL, --gl_sl_link_id, gl_sl_link_table,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --attribute3, attribute4, attribute5, attribute6, attribute7, attribute8, attribute9,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --attribute10, attribute11, attribute12, attribute13, attribute14, attribute15, attribute16,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --attribute17, attribute18, attribute19, attribute20,
                     NULL,
                     NULL,
                     NULL, --context, context2, invoice_date,
                     NULL, --tax_code,
                     NULL, --invoice_identifier,
                     NULL, --invoice_amount,
                     NULL, --context3,
                     NULL, --ussgl_transaction_code,
                     NULL, --descr_flex_error_message,
                     ltrim(substr(dst.invoice_num,instr(dst.invoice_num,'-')+1))--jgzz_recon_ref
            FROM     dka_sarsurtaxe_tmp dst
                    ,hr_operating_units hr           -- OBE
            WHERE    dst.status = 'L'
            AND      hr.organization_id = dst.org_id -- OBE
            GROUP BY dst.invoice_currency_code,
                     dst.ccid,
                     dst.invoice_num,
                     hr.set_of_books_id              -- OBE
            HAVING   SUM (dst.amount) <> 0           -- OBE artf2202658
                     ;

        -- Insertion d'une OD credit venant de AP --
        INSERT INTO gl_interface
                    (status,
                     --set_of_books_id,
                     ledger_id, -- OBE
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
                     status_description,
                     stat_amount,
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
            SELECT   'NEW', -- status,
                     --Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID'), -- Set_of_books_id, -- OBE
                     hr.set_of_books_id,                                           -- OBE
                     SYSDATE, -- accounting_date,
                     -- 20/11 dst.invoice_currency_code, -- currency_code,
                     aia.invoice_currency_code,
                     SYSDATE, -- date_created,
                     Fnd_Global.user_id, --created_by,
                     'A', --actual_flag,
                     gv_user_je_category_name, --user_je_category_name,
                     gv_user_je_source_name, --user_je_source_name,
                     NULL, --currency_conversion_date,
                     NULL, --encumbrance_type_id,
                     NULL, --budget_version_id,
                     NULL, --user_currency_conversion_type,
                     NULL, --currency_conversion_rate,
                     NULL, --average_journal_flag,
                     NULL, --originating_bal_seg_value,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --segment1, segment2, segment3, segment4, segment5, segment6, segment7, segment8,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --segment9, segment10, segment11, segment12, segment13, segment14, segment15, segment16,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --segment17, segment18, segment19, segment20, segment21, segment22, segment23, segment24,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --segment25, segment26, segment27, segment28, segment29, segment30,
                     NULL, --entered_dr,
                     aida.amount, -- entered_cr,
                     NULL, -- accounted_dr,
                     NULL, -- accounted_cr,
                     NULL, --transaction_date,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --reference1, reference2, reference3, reference4, reference5, reference6, reference7,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --reference8, reference9, reference10, reference11, reference12, reference13, reference14,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --reference15, reference16, reference17, reference18, reference19, reference20, reference21,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --reference22, reference23, reference24, reference25, reference26, reference27, reference28,
                     NULL,
                     NULL, --reference29, reference30,
                     NULL, --je_batch_id,
                     NULL, --period_name,
                     NULL, --je_header_id,
                     NULL, --je_line_num,
                     NULL, --chart_of_accounts_id,
                     NULL, --functional_currency_code,
                     aida.dist_code_combination_id, --code_combination_id,
                     NULL, --date_created_in_gl,
                     NULL, --warning_code,
                     NULL, --status_description,
                     NULL, --stat_amount,
                     pn_group_id, --group_id,
                     NULL, --request_id,
                     NULL, --subledger_doc_sequence_id,
                     NULL, --subledger_doc_sequence_value,
                     NULL,
                     NULL, --attribute1, attribute2,
                     NULL,
                     NULL, --gl_sl_link_id, gl_sl_link_table,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --attribute3, attribute4, attribute5, attribute6, attribute7, attribute8, attribute9,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --attribute10, attribute11, attribute12, attribute13, attribute14, attribute15, attribute16,
                     NULL,
                     NULL,
                     NULL,
                     NULL, --attribute17, attribute18, attribute19, attribute20,
                     NULL,
                     NULL,
                     NULL, --context, context2, invoice_date,
                     NULL, --tax_code,
                     NULL, --invoice_identifier,
                     NULL, --invoice_amount,
                     NULL, --context3,
                     NULL, --ussgl_transaction_code,
                     NULL, --descr_flex_error_message,
                     ltrim(substr(aia.invoice_num,instr(aia.invoice_num,'-')+1))--jgzz_recon_ref
  --20/11          FROM     ap_invoices_all aia,
  				   FROM ap_invoices aia,
                  ap_invoice_distributions_all aida,
                  hr_operating_units hr     -- OBE
  --20/11            dka_sarsurtaxe_tmp dst
  --20/11          WHERE        aia.invoice_num = dst.invoice_num
  				   WHERE aia.invoice_num IN (SELECT DISTINCT invoice_num
                                       FROM dka_sarsurtaxe_tmp
                                       WHERE status = 'L'
                                       )
  --20/11                   AND dst.status = 'L'
             AND aida.invoice_id = aia.invoice_id
             AND hr.organization_id = aia.org_id -- OBE
             AND aida.amount <> 0 -- OBE artf2202658             
  --20/11          GROUP BY dst.invoice_currency_code,
  --20/11                   aida.amount,
  --20/11                   aida.dist_code_combination_id,
  --20/11                   aia.invoice_num
  				   ;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END insert_gl_interface;

    
--------------------------------------------------------------------------------------
--  Nom           : launch_glxrcaut
--  Description   : Procédure qui permet de lancer le traitment standard GLXRCAUT
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE launch_glxrcaut (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS    
    
    vv_phase                  VARCHAR2 (100);
    vv_status                 VARCHAR2 (100);
    vv_dev_phase              VARCHAR2 (100);
    vv_name                   VARCHAR2 (100);
    vv_dev_status             VARCHAR2 (100);
    vv_message                VARCHAR2 (100);
    vn_request_id             NUMBER (15);
    vn_rule                   NUMBER;
    vn_chart_of_account_id    NUMBER;
    vv_currency_code          VARCHAR2(10);
    vv_period_name_de         VARCHAR2(10);
    vv_period_name_a          VARCHAR2(10);
    vv_start_date             VARCHAR2(25);
    vv_end_date               VARCHAR2(25);
    --< OBE artf2205931 
    vv_min_cpt_surtaxe        VARCHAR2(25);
    vv_max_cpt_surtaxe        VARCHAR2(25);    
    vv_argument11             VARCHAR2(50);    
    vv_argument12             VARCHAR2(50);
    --> OBE artf2205931 
    
    
    BEGIN
    
      ----- Initialisation des variables de sortie de la procédure -----
      pv_errbuf     := NULL;
      pn_retcode    := 0;
      Fnd_File.put_line(Fnd_File.LOG,'début de la procédure LAUNCH_APPRVL');    
      
      SELECT lookup_code 
      INTO vn_rule
      FROM gl_lookups 
      WHERE lookup_type='GL_RECONCILIATION_RULES' 
      AND LOOKUP_CODE=1 --3 OBE artf2210354     
      ;
      
      SELECT chart_of_accounts_id 
      INTO vn_chart_of_account_id
      FROM GL_ACCESS_SETS 
      WHERE access_set_id =fnd_profile.VALUE ('GL_ACCESS_SET_ID')
      ;
    
     
      -- Lancemet du traitement validation de factures
      FOR rec IN (--< OBE artf2210354
                  /*SELECT DISTINCT set_of_books_id, substr(b.name,4,4) region
                  FROM dka_sarsurtaxe_tmp a,
                       hr_operating_units b
                  WHERE b.organization_id = a.org_id*/
                  SELECT b.set_of_books_id ,MIN(d.gl_date) gl_date
                  FROM dka_sarsurtaxe_tmp a,
                    hr_operating_units b,
                    ra_customer_trx c,
                    ra_cust_trx_line_gl_dist d
                  WHERE b.organization_id = a.org_id
                  AND a.customer_trx_id   = c.customer_trx_id
                  AND c.customer_trx_id   = d.customer_trx_id
                  AND d.account_class     = 'REC'
                  AND d.latest_rec_flag   = 'Y'
				  AND a.STATUS <>'Z'
                  GROUP BY b.set_of_books_id
                  --> OBE artf2210354
                  )
      LOOP
      
        SELECT currency_code
        INTO vv_currency_code
        FROM gl_ledgers 
        WHERE ledger_id = rec.set_of_books_id
        ; 
        
        --< OBE artf2210354
        
        SELECT period_name 
        INTO vv_period_name_de
        FROM gl_period_statuses 
        WHERE application_id =101 
        AND ledger_id = rec.set_of_books_id
        AND TRUNC(rec.gl_date) BETWEEN TRUNC(start_date) AND TRUNC(end_date)
        AND ROWNUM = 1
        ;
        
        SELECT period_name 
        INTO vv_period_name_a
        FROM gl_period_statuses 
        WHERE application_id =101 
        AND ledger_id = rec.set_of_books_id
        AND TRUNC(SYSDATE) BETWEEN TRUNC(start_date) AND TRUNC(end_date)
        AND ROWNUM = 1
        ;

        /*
        SELECT TO_CHAR(start_date,'YYYY/MM/DD HH24:MI:SS'), TO_CHAR(end_date,'YYYY/MM/DD HH24:MI:SS')
        INTO vv_start_date, vv_end_date                                                              
        FROM gl_period_statuses 
        WHERE application_id = 101 
        AND ledger_id = rec.set_of_books_id
        AND period_name = vv_period_name
        ;
        */

        SELECT TO_CHAR(start_date,'YYYY/MM/DD HH24:MI:SS')
        INTO vv_start_date
        FROM gl_period_statuses
        WHERE application_id = 101
        AND ledger_id        = rec.set_of_books_id
        AND period_name      = vv_period_name_de
        ;  
        
        SELECT TO_CHAR(end_date,'YYYY/MM/DD HH24:MI:SS')
        INTO vv_end_date
        FROM gl_period_statuses
        WHERE application_id = 101
        AND ledger_id        = rec.set_of_books_id
        AND period_name      = vv_period_name_a
        ;  
        --> OBE artf2210354
        
        --< OBE artf2205931
        SELECT MIN(ffv.flex_value), MAX(ffv.flex_value)
        INTO vv_min_cpt_surtaxe, vv_max_cpt_surtaxe
        FROM fnd_flex_value_sets ffvs,
             fnd_flex_values ffv
        WHERE ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
        AND ffvs.flex_value_set_id     = ffv.flex_value_set_id
        AND ffv.enabled_flag           = 'Y'
        AND ffv.attribute10            = 'Y'
        ;        
        
        vv_argument11 := '0.0.'||vv_min_cpt_surtaxe||'.0.0.0.0.0.0.0.0.0';
        vv_argument12 := 'Z.Z.'||vv_max_cpt_surtaxe||'.Z.Z.Z.Z.Z.Z.Z.Z.Z';        
        --> OBE artf2205931
        
        gv_responsibility_ref    := 'TOUT_GL_OPE_ADMINISTRATEUR'; --rec.region||'_GL_ADMINISTRATEUR';
        
        Fnd_File.put_line(Fnd_File.LOG,'gv_responsibility_ref : '||gv_responsibility_ref);
        
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   gn_responsibility_id,
               gn_application_id
        FROM   fnd_responsibility fr
        WHERE  fr.responsibility_key = gv_responsibility_ref;

        
        fnd_global.apps_initialize (FND_PROFILE.VALUE('USER_ID'), gn_responsibility_id, gn_application_id);        

        Fnd_File.put_line(Fnd_File.LOG,'Lancement du traitement de rapprochement pour le livre : '||rec.set_of_books_id);          
        
                  -- Lancement du traitement de Rapprochement
                  vn_request_id := fnd_request.submit_request ( 
                                      'SQLGL',                                -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                      'GLXRCAUT',                             -- SHORT NAME DU TRAITEMENT
                                      NULL,                                   -- PROGRAM NAME
                                      NULL,                                   -- START
                                      FALSE,                                  -- SUB REQUEST
                                      FND_PROFILE.value('GL_ACCESS_SET_ID'),  --ARGUMENT1
                                      rec.set_of_books_id,                    --ARGUMENT2
                                      vv_currency_code,                       --ARGUMENT3
                                      vn_rule,                                --ARGUMENT4
                                      'Y',                                    --ARGUMENT5
                                      vv_period_name_de,                      --ARGUMENT6 -- OBE artf2210354
                                      vv_period_name_a,                       --ARGUMENT7 -- OBE artf2210354
                                      vv_start_date,                          --ARGUMENT8
                                      vv_end_date,                            --ARGUMENT9
                                      vn_chart_of_account_id,                 --ARGUMENT10
                                      vv_argument11,                          --ARGUMENT11 -- OBE artf2205931
                                      vv_argument12                           --ARGUMENT12 -- OBE artf2205931
                                       );                                        

                  IF vn_request_id = 0
                  THEN
                      pn_retcode    := 2;
                      Fnd_File.put_line(Fnd_File.LOG,' Le traitement de rapprochement a échoué!');
                  ELSE
                      Fnd_File.put_line(Fnd_File.LOG,' vv_dev_phase  OR vv_dev_status : '|| vv_dev_phase || '   ' || vv_dev_status);
                      COMMIT;

                      IF NOT (Fnd_Concurrent.wait_for_request (vn_request_id, 60, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_message))
                      THEN
                          Fnd_File.put_line(Fnd_File.LOG,'Attente du programme de la fin IMPUTATION dépassé : Fin du traitement ');
                      ELSIF (    vv_dev_phase = 'COMPLETE'
                             AND vv_dev_status = 'NORMAL'
                            )
                      THEN
                          --dka_tools_pkg.put_debug_message(' vv_dev_phase  OR vv_dev_status : '||vv_dev_phase||vv_dev_status);
                          Fnd_File.put_line(Fnd_File.LOG,'L''éxécution de IMPUTATION OK');
                      END IF; -- fin IF NOT
                  END IF; -- fin if request       
              
      END LOOP;
      
     Fnd_File.put_line(Fnd_File.LOG,'fin de la procédure LAUNCH_GLXRCAUT');          

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;    
    
    
    END launch_glxrcaut;        

--------------------------------------------------------------------------------------
--  Nom           : MAIN4
--  Description   : Procédure qui permet de renseigner la référence de lettrage.
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main4 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        vn_gl_set_of_bks_id       NUMBER (15);
        vn_chart_of_accounts_id   NUMBER (15);
        vv_phase                  VARCHAR2 (100);
        vv_status                 VARCHAR2 (100);
        vv_dev_phase              VARCHAR2 (100);
        vv_name                   VARCHAR2 (100);
        vv_dev_status             VARCHAR2 (100);
        vv_message                VARCHAR2 (100);
        vn_request_id             NUMBER (15);
        vn_interface_run_id       NUMBER (15);
        vn_posting_run_id         NUMBER (15);
        vn_group_id               NUMBER (15);
        --< OBE
        vv_gl_responsibility      VARCHAR2 (50);
        vn_responsibility_id      NUMBER;
        vn_application_id         NUMBER;
        v_autopost_set_id         NUMBER;      
        --> OBE
    BEGIN
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure MAIN4' || CHR (10));
        
        --< OBE
        gv_responsibility_ref    := 'TOUT_AP_ADMINISTRATEUR';
        
        Fnd_File.put_line(Fnd_File.LOG,'gv_responsibility_ref : '||gv_responsibility_ref);
        
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   gn_responsibility_id,
               gn_application_id
        FROM   fnd_responsibility fr
        WHERE  fr.responsibility_key = gv_responsibility_ref;

        fnd_global.apps_initialize (FND_PROFILE.VALUE('USER_ID'), gn_responsibility_id, gn_application_id); 
        MO_GLOBAL.INIT('SQLAP');  
        
        --> OBE
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf              := NULL;
        pn_retcode             := 0;
        ----- Appel de la procédure INIT -----
        Dka_Sarsurtaxe_Pkg.init (pv_errbuf, pn_retcode);
        ----- Récupération du GL_SET_OF_BKS_ID -----
        --vn_gl_set_of_bks_id    := Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID'); -- OBE
        ----- Création d'une OD dans GL .. INSERTION DANS LES TABLES D'INTERFACES GL : INSERT_GL_INTERFACE_CONTROL,INSERT_GL_INTERFACE -----
        Dka_Sarsurtaxe_Pkg.insert_gl_interface_control (vn_group_id, vn_interface_run_id, pv_errbuf, pn_retcode);
        Dka_Sarsurtaxe_Pkg.insert_gl_interface (vn_group_id, pv_errbuf, pn_retcode);
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'vn_interface_run_id   ' || TO_CHAR (vn_interface_run_id));
        -- Lancement de EASYLINK de GL --
        Fnd_File.put_line(Fnd_File.LOG,'Lancement du traitement : run-'|| TO_CHAR (vn_interface_run_id));
      
      
        
        --< OBE
   
        /*                
        FOR rec IN (SELECT DISTINCT set_of_books_id, substr(b.name,4,4) societe
                    FROM dka_sarsurtaxe_tmp a,
                         hr_operating_units b
                    WHERE b.organization_id = a.org_id
                    )
        LOOP    */       
        --> OBE        
        
        gv_responsibility_ref    := 'TOUT_GL_OPE_ADMINISTRATEUR'; --rec.societe||'_GL_ADMINISTRATEUR';
        
        Fnd_File.put_line(Fnd_File.LOG,'gv_responsibility_ref : '||gv_responsibility_ref);
        
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   gn_responsibility_id,
               gn_application_id
        FROM   fnd_responsibility fr
        WHERE  --DECODE(fr.responsibility_key,'001_GL_ADMINISTRATEUR','0001_GL_ADMINISTRATEUR',fr.responsibility_key) = gv_responsibility_ref; -- OBE
        fr.responsibility_key = gv_responsibility_ref;
        
        fnd_global.apps_initialize (FND_PROFILE.VALUE('USER_ID'), gn_responsibility_id, gn_application_id);             
        
        vn_request_id          := Fnd_Request.submit_request (
                                      'SQLGL', --APPL
                                      'GLLEZL', --PROG
                                      NULL, --PROGRAM_NAME
                                      NULL, --START
                                      FALSE, --SUB_REQUEST
                                      vn_interface_run_id, --ARGUMENT1
                                      FND_PROFILE.value('GL_ACCESS_SET_ID'),
                                      --rec.set_of_books_id,               -- OBE
                                      --vn_gl_set_of_bks_id, --ARGUMENT2 -- OBE
                                      'N', --ARGUMENT3
                                      NULL, --ARGUMENT4
                                      NULL, --ARGUMENT5
                                      'N', --ARGUMENT6
                                      'O', --ARGUMENT7
                                      'Y'
                                  );

        IF vn_request_id = 0
        THEN
            pn_retcode    := 2;
            Fnd_File.put_line(Fnd_File.LOG,' Le traitement EASYLINK a échoué!');
        --RETURN FALSE;
        ELSE
            COMMIT;
            Fnd_File.put_line(Fnd_File.LOG,'vn_request_id: '|| TO_CHAR (vn_request_id));
            Fnd_File.put_line(Fnd_File.LOG,'Debut du IF NOT');

            IF NOT (Fnd_Concurrent.wait_for_request (vn_request_id, 60, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_message))
            THEN
                Fnd_File.put_line(Fnd_File.LOG,'Attente du programme de la fin EASYLINK dépassé : Fin du traitement ');
            ELSIF (    vv_dev_phase = 'COMPLETE'
                   AND vv_dev_status = 'NORMAL'
                  )
            THEN
                --dka_tools_pkg.put_debug_message(' vv_dev_phase  OR vv_dev_status : '||vv_dev_phase||vv_dev_status);
                Fnd_File.put_line(Fnd_File.LOG,'L''éxécution de EASYLINK OK');
                COMMIT;
                -- Récupération du nom (source(user_je_source_name), request ID, actual flag , group ID) à imputer --
                vv_name          := SUBSTR (gv_user_je_source_name || ' ' || vn_request_id || ': ' || 'A' || ' ' || vn_group_id, 1, 50);
                Fnd_File.put_line(Fnd_File.LOG,'vv_name :'|| vv_name);

                -- Recupération du posting_run_id --
                SELECT Gl_Je_Batches_Post_Pkg.get_unique_id
                INTO   vn_posting_run_id
                FROM   DUAL;

                Fnd_File.put_line(Fnd_File.LOG,'vn_posting_run_id :'|| vn_posting_run_id);

                -- Selection du lot à imputer --
                UPDATE gl_je_batches gjb
                SET    gjb.status = 'S',
                       gjb.posting_run_id = vn_posting_run_id
                WHERE  gjb.NAME = vv_name;

                -- Récupération du chart_of_accounts_id --
                /*
                SELECT gl.chart_of_accounts_id
                INTO   vn_chart_of_accounts_id
                FROM   --gl_sets_of_books gsob 
                       gl_ledgers gl -- OBE
                WHERE  --gsob.set_of_books_id = vn_gl_set_of_bks_id;
                       gl.ledger_id = rec.set_of_books_id; --vn_gl_set_of_bks_id; -- OBE
                       */

                --Fnd_File.put_line(Fnd_File.LOG,'vn_chart_of_accounts_id :'|| vn_chart_of_accounts_id);
                -- Lancement de l'imputation  pour le lot selectionné --
                Fnd_File.put_line(Fnd_File.LOG,' Lancement IMPUTATION du traitement : vn_posting_run_id :'|| TO_CHAR (vn_posting_run_id));
                --< OBE
                /*vn_request_id    := Fnd_Request.submit_request (
                                        'SQLGL', --APPL
                                        'GLPPOSS',
                                        --'GLPPOS', --PROG
                                        NULL, --PROGRAM_NAME
                                        NULL, --START
                                        FALSE, --SUB_REQUEST
                                        vn_gl_set_of_bks_id, --ARGUMENT1
                                        vn_chart_of_accounts_id, --ARGUMENT2
                                        vn_posting_run_id --ARGUMENT4
                                    );*/
                SELECT autopost_set_id
                INTO v_autopost_set_id
                FROM GL_AUTOMATIC_POSTING_SETS
                WHERE autopost_set_name = 'DKA_JEU_TOTAL'
                ;                                      
                vn_request_id := fnd_request.submit_request ( 
                                    'SQLGL',   -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                    'GLPAUTOP',                  -- SHORT NAME DU TRAITEMENT
                                    NULL,                             -- PROGRAM NAME
                                    NULL,                             -- START
                                    FALSE,                            -- SUB REQUEST
                                    FND_PROFILE.value('GL_ACCESS_SET_ID'),  --argument1
                                    v_autopost_set_id                       --argument2
                                     );   
                --> OBE                                     

                IF vn_request_id = 0
                THEN
                    pn_retcode    := 2;
                    Fnd_File.put_line(Fnd_File.LOG,' Le traitement a échoué!');
                ELSE
                    Fnd_File.put_line(Fnd_File.LOG,' vv_dev_phase  OR vv_dev_status : '|| vv_dev_phase || '   ' || vv_dev_status);
                    COMMIT;

                    IF NOT (Fnd_Concurrent.wait_for_request (vn_request_id, 60, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_message))
                    THEN
                        Fnd_File.put_line(Fnd_File.LOG,'Attente du programme de la fin IMPUTATION dépassé : Fin du traitement ');
                    ELSIF (    vv_dev_phase = 'COMPLETE'
                           AND vv_dev_status = 'NORMAL'
                          )
                    THEN
                        --dka_tools_pkg.put_debug_message(' vv_dev_phase  OR vv_dev_status : '||vv_dev_phase||vv_dev_status);
                        Fnd_File.put_line(Fnd_File.LOG,'L''éxécution de IMPUTATION OK');
                    END IF; -- fin IF NOT
                END IF; -- fin if request
            END IF;
        END IF;
         
        --END LOOP; -- OBE

        --COMMIT;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END main4;


--------------------------------------------------------------------------------------
--    ETAPE 5: FIN DU TRAITEMENT SPECIFIQUE APRES LE LETTRAGE AUTOMATIQUE           --
--------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--  Nom           : UPDATE_DKA_SARSURTAXE_TMP
--  Description   : Procédure de mise à jour du statut dans la table dka_sarsurtaxe_tmp
--              à la fin du traitement
--  PARAMETRES    :
--    pv_errbuf       Sortie
--    pv_retcode          Sortie

--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
------------------------------------------------------------------------------------
    PROCEDURE update_dka_sarsurtaxe_tmp (
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        ----- Mise à jour du statut 'A' de la ligne dans la table dka_sarsurtaxe_tmp -----
        UPDATE dka_sarsurtaxe_tmp dst
        SET    dst.status = 'A',
               dst.rejection_reason = 'Traitement normale de la ligne'
        WHERE  ltrim(substr(dst.invoice_num,instr(dst.invoice_num,'-')+1)) 
                               IN (SELECT DISTINCT jgzz_recon_ref
                                   FROM            gl_je_lines_recon -- OBE
                                                   --gl_je_lines     -- OBE
                                   WHERE           jgzz_recon_status = 'R')
		  AND dst.STATUS <>'Z';
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := SQLCODE;
            pv_errbuf     := SQLERRM;
    END update_dka_sarsurtaxe_tmp;


--------------------------------------------------------------------------------------
--  Nom           : MAIN5
--  Description   : Procédure
--
--  PARAMETRES :
--    pv_errbuf                   Entrée/Sortie       retour de message eventuel
--    pn_retcode                  Sortie          status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
----------------------------------------------------------------------------------------
    PROCEDURE main5 (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'début de la procédure MAIN5' || CHR (10));
        ----- Initialisation des variables de sortie de la procédure -----
        pv_errbuf     := NULL;
        pn_retcode    := 0;
        -- Mise à jour du statut 'A' de la ligne dans la table dka_sarsurtaxe_tmp après le lettrage automatique --
        Dka_Sarsurtaxe_Pkg.update_dka_sarsurtaxe_tmp (pv_errbuf, pn_retcode);
        -- traitement terminé ---
        Fnd_File.put_line(Fnd_File.LOG,CHR (10) || 'traitement terminé' || CHR (10));
    END main5;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : INSERT_DKA_SARSURTAXE_CTL_TMP
--  Description   : Insertion des éléments de surtaxe dans la table temporaire de contrôle
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE insert_dka_sarsurtaxe_ctl_tmp ( 
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
		)

IS
BEGIN
   ----- Initialisation des variables de sortie de la procédure -----
   pv_errbuf := NULL;
   pn_retcode := 0;

   -- suppression des enregistrements de la table
   DELETE dka_sarsurtaxe_ctl_tmp_all;

   Dka_Tools_Pkg.put_debug_message('début INSERT_DKA_SARSURTAXE_CTL_TMP');
   Dka_Tools_Pkg.put_debug_message(TO_CHAR(SYSDATE,'HH24:MI:SS'));

   INSERT INTO dka_sarsurtaxe_ctl_tmp (      
                         customer_trx_id,
                         trx_number,
                         cust_trx_line_gl_dist_id,
                         amount,
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
                         segment11, -- OBE
                         segment12, -- OBE
                         ccid,
                         invoice_currency_code,
                         compte_surtaxe,        -- OBE artf2206496 
                         org_id
                        )
                         SELECT
					                  rct.customer_trx_id,
					                  rct.trx_number,
					                  rctlgd.cust_trx_line_gl_dist_id,
					                  rctlgd.amount, 
					                  gcc.segment1,
					                  gcc.segment2,
					                  gcc.segment3,
					                  gcc.segment4,
					                  gcc.segment5,
					                  gcc.segment6,
					                  gcc.segment7,
					                  gcc.segment8,
					                  gcc.segment9, -- PHENIX 2004
  					                gcc.segment10, -- PHENIX 2004
                            gcc.segment11, -- OBE
  					                gcc.segment12, -- OBE
					                  rctlgd.code_combination_id,
					                  rct.invoice_currency_code,
                            rctlgd.attribute8,         -- OBE artf2206496 
					                  rct.org_id
					          FROM     ra_customer_trx rct,
					                   ra_cust_trx_types rctt,
					                   ra_cust_trx_line_gl_dist_all rctlgd,
					                   gl_code_combinations gcc
                             --fnd_flex_value_sets ffvs, -- OBE artf2211298 
                             --fnd_flex_values     ffv   -- OBE artf2211298
					          WHERE        --gcc.segment5 LIKE 'CSC%' -- PHENIX 2004 -- OBE
                              rctlgd.attribute8 LIKE 'CSC%'                -- OBE
					                   AND rctlgd.attribute6 IS NULL
					                   AND Arp_Bal_Util.get_trx_balance (rct.customer_trx_id, NULL) = '0'
					                   AND rctt.cust_trx_type_id = rct.cust_trx_type_id
					                   AND rctt.TYPE IN ('INV', 'CM')
					                   AND NOT EXISTS ( SELECT 1
					                                    FROM   ar_adjustments aa,
					                                           ra_customer_trx rct_rel,
					                                           ra_cust_trx_types rctt_rel
					                                    WHERE      rctt_rel.cust_trx_type_id = rct_rel.cust_trx_type_id
					                                           AND rctt_rel.TYPE = 'CB'
					                                           AND aa.customer_trx_id = rct.customer_trx_id
					                                           AND rct_rel.customer_trx_id = aa.chargeback_customer_trx_id)
                             -- JDV DAOPCCF_LOCAL
                             --< OBE artf2211298 
                             /*
                             AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
                             AND ffvs.flex_value_set_id   = ffv.flex_value_set_id
                             AND ffv.enabled_flag         = 'Y'
                             AND ffv.attribute10          = 'Y'
                             */
                             --> OBE artf2211298 
					                   --AND gcc.segment3 IN (ffv.flex_value) --('467300', '467296') -- OBE artf2211298 
                             AND DKA_AR_TOOLS_PKG.issurtaxeaccount(gcc.segment3) = 'TRUE'  -- OBE artf2211298 
					                   AND rctlgd.customer_trx_id = rct.customer_trx_id
					                   AND gcc.code_combination_id = rctlgd.code_combination_id
					                   AND rctlgd.gl_posted_date IS NOT NULL
									   --and  rct.customer_trx_id = 1359896
									   ;

  Dka_Tools_Pkg.put_debug_message(TO_CHAR(SYSDATE,'HH24:MI:SS'));

  EXCEPTION
      WHEN OTHERS THEN
        pn_retcode := SQLCODE;
        pv_errbuf := SQLERRM;

  
END insert_dka_sarsurtaxe_ctl_tmp;


	
-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONTROLE_FOURNISSEUR_ABSENT
--  Description   : Vérification que le code partenaire est bien associé à un fournisseur
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE controle_fournisseur_absent ( 
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
		)

IS

	   
        CURSOR cur_fournisseur_absent
        IS
        SELECT  DISTINCT
                dsct.segment1,
                dsct.compte_surtaxe --segment5  -- PHENIX 2004  -- OBE artf2206496 
        FROM     dka_sarsurtaxe_ctl_tmp dsct
        WHERE        NOT EXISTS ( SELECT 'x'
                                  FROM    po_vendors pv
                                  WHERE   pv.attribute6 = dsct.compte_surtaxe -- segment5 -- OBE artf2206496 
                                 ); -- PHENIX 2004

        rec_fournisseur_absent      cur_fournisseur_absent%ROWTYPE;


BEGIN 
 
 	OPEN cur_fournisseur_absent;
 	
 	FETCH cur_fournisseur_absent INTO rec_fournisseur_absent;
 						  		
    	
   	IF (cur_fournisseur_absent%FOUND) THEN

            Dka_Tools_Pkg.put_outdebug_message('Le code partenaire '||rec_fournisseur_absent.compte_surtaxe||
		 			' n''a pas de fournisseur correspondant'); -- PHENIX 2004

        LOOP
            FETCH cur_fournisseur_absent INTO rec_fournisseur_absent;
            EXIT WHEN cur_fournisseur_absent%NOTFOUND;
            Dka_Tools_Pkg.put_outdebug_message('Le code partenaire '||rec_fournisseur_absent.compte_surtaxe||
		 			' n''a pas de fournisseur correspondant'); -- PHENIX 2004


        END LOOP;    			
        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('===> Créez le ou les fournisseurs manquants ou mettez à jour le CUF '||
				'"Code surtaxe communale" sur l''entête du fournisseur qui correspond au code partenaire');
 		
		
      	ELSE
      	
         Dka_Tools_Pkg.put_outdebug_message('Aucune anomalie rencontrée');
     	   	
      		
   	END IF;
	
	CLOSE cur_fournisseur_absent;
  
END controle_fournisseur_absent;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONTROLE_FOURNISSEUR_DOUBLON
--  Description   : Vérification que le code partenaire est bien associé à un seul fournisseur
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE controle_fournisseur_doublon ( 
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
		)

IS

	   
        CURSOR cur_fournisseur_doublon
        IS
		select pv.attribute6 compte_surtaxe, 
               COUNT(DISTINCT pv.vendor_name) 
		  from po_vendorS pv
		 where pv.attribute6 like 'CSC%'
           and pv.vendor_type_lookup_code <> 'FACTOR'
		   and nvl(pv.end_date_active, sysdate)>=sysdate 
		 GROUP BY attribute6  
		HAVING COUNT(DISTINCT pv.vendor_name) > 1; 
		/*
        SELECT  
                dsct.compte_surtaxe, -- segment5,   -- PHENIX 2004 -- OBE artf2206496 
                COUNT(DISTINCT pv.vendor_name)
        FROM     dka_sarsurtaxe_ctl_tmp dsct,
                 po_vendors pv
        WHERE    pv.attribute6 = dsct.compte_surtaxe -- segment5 -- PHENIX 2004 -- OBE artf2206496 
        GROUP BY dsct.compte_surtaxe -- segment5 -- PHENIX 2004 -- OBE artf2206496 
        HAVING COUNT(DISTINCT pv.vendor_name) > 1;*/
		
		
        rec_fournisseur_doublon      cur_fournisseur_doublon%ROWTYPE;
		
        CURSOR cur_liste_doublon(vn_code_part VARCHAR2)
        IS
        SELECT  vendor_name
				, segment1
        FROM    po_vendors pv
        WHERE    pv.attribute6 = vn_code_part
        ;

        rec_liste_doublon      cur_liste_doublon%ROWTYPE;

BEGIN 
 
 	OPEN cur_fournisseur_doublon;
 	
 	FETCH cur_fournisseur_doublon INTO rec_fournisseur_doublon;
 						  		
    	
   	IF (cur_fournisseur_doublon%FOUND) THEN

            Dka_Tools_Pkg.put_outdebug_message('Le code partenaire '||rec_fournisseur_doublon.compte_surtaxe --segment5  -- OBE artf2206496 
			|| ' est associé à plusieurs fournisseurs : '); -- PHENIX 2004

			 	OPEN cur_liste_doublon(rec_fournisseur_doublon.compte_surtaxe);  -- PHENIX 2004 -- OBE artf2206496 
				LOOP
			 	FETCH cur_liste_doublon INTO rec_liste_doublon;
                EXIT WHEN cur_liste_doublon%NOTFOUND;
				Dka_Tools_Pkg.put_outdebug_message('N° '||rec_liste_doublon.segment1||' - '||rec_liste_doublon.vendor_name);
				END LOOP;
				CLOSE cur_liste_doublon;


        LOOP
            FETCH cur_fournisseur_doublon INTO rec_fournisseur_doublon;
            EXIT WHEN cur_fournisseur_doublon%NOTFOUND;
            Dka_Tools_Pkg.put_outdebug_message('Le code partenaire '||rec_fournisseur_doublon.compte_surtaxe -- segment5 -- OBE artf2206496 
			|| ' est associé à plusieurs fournisseurs : '); -- PHENIX 2004
			
			 	OPEN cur_liste_doublon(rec_fournisseur_doublon.compte_surtaxe); -- PHENIX 2004 -- OBE artf2206496 
				LOOP
			 	FETCH cur_liste_doublon INTO rec_liste_doublon;
                EXIT WHEN cur_liste_doublon%NOTFOUND;
				Dka_Tools_Pkg.put_outdebug_message('N° '||rec_liste_doublon.segment1||' -  '||rec_liste_doublon.vendor_name); 
				END LOOP;
				CLOSE cur_liste_doublon;
				
        END LOOP;    			

        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('===> Il ne doit exister qu''un fournisseur par code partenaire.' ||
		' Veuillez corriger le CUF sur ces fournisseurs ');
 		
		
      	ELSE
      	
         Dka_Tools_Pkg.put_outdebug_message('Aucune anomalie rencontrée');
     	   	
      		
   	END IF;
	
	CLOSE cur_fournisseur_doublon;
  
END controle_fournisseur_doublon;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CTR_FOURNISSEUR_DOUBLON_TMP
--  Description   : Vérification qu'' Il ne doit exister qu''un fournisseur par code partenaire. 
--                  Veuillez corriger le CUF sur ces fournisseurs puis relancer le traitement de surtaxe pour recyclage.
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE CTR_FOURNISSEUR_DOUBLON_TMP ( 
        pv_errbuf    OUT   VARCHAR2,
        pn_retcode   OUT   NUMBER
		)

IS

	   
        CURSOR cur_fournisseur_doublon
        IS
		select pov.VENDOR_NAME, temp.trx_number, temp.invoice_num
		  from PO_VENDORS pov,
			   DKA_SARSURTAXE_TMP_ALL temp,
               PO_VENDOR_SITES_ALL povsa
         where temp.vendor_site_id = povsa.vendor_site_id
           and povsa.VENDOR_ID = pov.VENDOR_ID
		   and nvl(pov.end_date_active, sysdate)>=sysdate 
		   and temp.status ='Z'
        ; 
		

        rec_fournisseur_doublon      cur_fournisseur_doublon%ROWTYPE;
		Exist_doublon varchar2(1);
		
       
BEGIN 
    Exist_doublon :='N';
    FOR rec_fournisseur_doublon IN cur_fournisseur_doublon LOOP 
			Dka_Tools_Pkg.put_outdebug_message('Le fournisseur '||rec_fournisseur_doublon.VENDOR_NAME || -- segment5 -- OBE artf2206496 
				 ' pour la facture : ' ||rec_fournisseur_doublon.trx_number ); -- PHENIX 2004
		    Exist_doublon :='Y';
	END LOOP;
	
	If Exist_doublon = 'Y' then
			Dka_Tools_Pkg.put_outdebug_message(CHR(10));
			Dka_Tools_Pkg.put_outdebug_message('===> Il ne doit exister qu''un fournisseur par code partenaire. Veuillez corriger le CUF sur ces fournisseurs puis relancer le traitement de surtaxe pour recyclage.'); 
		
	ELSE

			Dka_Tools_Pkg.put_outdebug_message('Aucune anomalie rencontrée');
	END IF;	 
	
 
 
 /*
 
 	OPEN cur_fournisseur_doublon;
 	
 	FETCH cur_fournisseur_doublon INTO rec_fournisseur_doublon;
 						  		
    	
   	IF (cur_fournisseur_doublon%FOUND) THEN

            

        LOOP
            FETCH cur_fournisseur_doublon INTO rec_fournisseur_doublon;
            EXIT WHEN cur_fournisseur_doublon%NOTFOUND;
            Dka_Tools_Pkg.put_outdebug_message('Le fournisseur '||rec_fournisseur_doublon.VENDOR_NAME || -- segment5 -- OBE artf2206496 
			 ' pour la facture : ' ||rec_fournisseur_doublon.trx_number ); -- PHENIX 2004
							
        END LOOP;    			

        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('===> Il ne doit exister qu''un fournisseur par code partenaire. Veuillez corriger le CUF sur ces fournisseurs puis relancer le traitement de surtaxe pour recyclage.'); 
 		
		
      	ELSE
      	
         Dka_Tools_Pkg.put_outdebug_message('Aucune anomalie rencontrée');
     	   	
      		
   	END IF;
	
	CLOSE cur_fournisseur_doublon;
	*/
  
END CTR_FOURNISSEUR_DOUBLON_TMP;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONTROLE_SITE_FRS_ABSENT
--  Description   : Vérification que le fournisseur a bien un site dupliqué
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE controle_site_frs_absent ( 
				 	pv_errbuf 	OUT VARCHAR2,
				 	pn_retcode   OUT   NUMBER
					)
IS

  
        CURSOR cur_site_frs_absent
        IS
            SELECT  DISTINCT
			        dsct.segment1,
			        dsct.compte_surtaxe, -- segment5, -- PHENIX 2004 -- OBE artf2206496 
			        pv.vendor_name
			FROM     dka_sarsurtaxe_ctl_tmp dsct,
			         po_vendors	pv
			WHERE    pv.attribute6 = dsct.compte_surtaxe -- segment5  -- PHENIX 2004 -- OBE artf2206496 
			AND NOT EXISTS (SELECT 'x'
			                FROM po_vendor_sites pvs1,
			                     gl_code_combinations gcc_pvs1
			                WHERE     pvs1.vendor_id = pv.vendor_id
			                AND pvs1.accts_pay_code_combination_id = gcc_pvs1.code_combination_id
			                AND gcc_pvs1.segment2 = dsct.segment2 ); -- PHENIX 2004

        rec_site_frs_absent         cur_site_frs_absent%ROWTYPE;



BEGIN 
 
 	OPEN cur_site_frs_absent;
 	
 	FETCH cur_site_frs_absent INTO rec_site_frs_absent;
 						  		
    	
   	IF (cur_site_frs_absent%FOUND) THEN

            Dka_Tools_Pkg.put_outdebug_message('Pas de site pour le fournisseur '||rec_site_frs_absent.vendor_name
			        ||' dans la société/centre de gestion '||rec_site_frs_absent.segment1); 

        LOOP
            FETCH cur_site_frs_absent INTO rec_site_frs_absent;
            EXIT WHEN cur_site_frs_absent%NOTFOUND;
            Dka_Tools_Pkg.put_outdebug_message('Pas de site pour le fournisseur '||rec_site_frs_absent.vendor_name
			        ||' dans la société/centre de gestion '||rec_site_frs_absent.segment1);


        END LOOP;    			

        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('===> Veuillez lancer le traitement de duplication du site fournisseur pour cette société/centre de gestion.');
 		
		
      	ELSE
      	
         Dka_Tools_Pkg.put_outdebug_message('Aucune anomalie rencontrée');
     	   	
      		
   	END IF;
	
	CLOSE cur_site_frs_absent;
  
END controle_site_frs_absent;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONTROLE_FACTURE_NEGATIVE
--  Description   : Liste des factures négatives
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE controle_facture_negative ( 
				 	pv_errbuf 	OUT VARCHAR2,
				 	pn_retcode   OUT   NUMBER)

IS

	
        CURSOR cur_facture_negative
        IS
           SELECT  dsct.segment1 societe,
                   pv.segment1,
                   pv.vendor_name,
                   pvs.vendor_site_code,
                   SUM (dsct.amount) montant
           FROM     dka_sarsurtaxe_ctl_tmp dsct,
                    po_vendors pv,
                    po_vendor_sites pvs
           WHERE pv.attribute6 = dsct.compte_surtaxe -- segment5 -- PHENIX 2004  -- OBE artf2206496 
           AND pv.vendor_id = pvs.vendor_id                                      -- OBE artf2206496 
           AND pvs.vendor_site_id = (SELECT MIN(pvs1.vendor_site_id)
                                      FROM po_vendor_sites pvs1,
                                           gl_code_combinations gcc_pvs1
                                      WHERE pvs1.vendor_id = pv.vendor_id
                                      AND pvs1.accts_pay_code_combination_id = gcc_pvs1.code_combination_id
                                      AND gcc_pvs1.segment2 = dsct.segment2) --PHENIX 2001
           GROUP BY dsct.segment1,
                    pv.segment1,
                    pv.vendor_name,
                    pvs.vendor_site_code
           HAVING SUM (dsct.amount) < 0
           ;


        rec_facture_negative         cur_facture_negative%ROWTYPE;



BEGIN 
 
 	OPEN cur_facture_negative;
 	
 	FETCH cur_facture_negative INTO rec_facture_negative;
 						  		

   	IF (cur_facture_negative%FOUND) THEN

			Dka_Tools_Pkg.put_outdebug_message('La facture de '||TO_CHAR(rec_facture_negative.montant, '999G999G999G999D99' )||' euros pour le fournisseur '||rec_facture_negative.vendor_name||' sur la société '||rec_facture_negative.societe);


        LOOP
		    FETCH cur_facture_negative INTO rec_facture_negative;
            EXIT WHEN cur_facture_negative%NOTFOUND;
			
			Dka_Tools_Pkg.put_outdebug_message('La facture de '||TO_CHAR(rec_facture_negative.montant, '999G999G999G999D99' )||' euros pour le fournisseur '||rec_facture_negative.vendor_name||' sur la société '||rec_facture_negative.societe);
           
	
        END LOOP;    			


        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('===> Impossible de créer une facture standard d''un montant négatif');
 		
		
      	ELSE
      	
         Dka_Tools_Pkg.put_outdebug_message('Aucune anomalie rencontrée');
     	   	
      		
   	END IF;
	
	CLOSE cur_facture_negative;
  
END controle_facture_negative;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : BILAN_SURTAXE
--  Description   : Synthèse des lignes traitées par la surtaxe
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE bilan_surtaxe ( 
				 	pv_errbuf 	OUT VARCHAR2,
				 	pn_retcode   OUT   NUMBER)

IS

	   
        CURSOR cur_bilan_surtaxe
        IS
           SELECT pv.segment1, 
                  vendor_site_id,  
                  invoice_num,
                  status,
                  rejection_reason,
                  COUNT(*) nbre_ligne
          FROM    dka_sarsurtaxe_tmp dst,
		          po_vendors pv
		  WHERE pv.vendor_id = dst.collectivite
		    AND dst.STATUS <>'Z'
          GROUP BY pv.segment1, 
                   vendor_site_id,  
                   invoice_num,
                   status,
                   rejection_reason		
		;

        rec_bilan_surtaxe   cur_bilan_surtaxe%ROWTYPE;



BEGIN 
 
 	OPEN cur_bilan_surtaxe;
 	
 	FETCH cur_bilan_surtaxe INTO rec_bilan_surtaxe;
 						  		
    	
   	IF (cur_bilan_surtaxe%FOUND) THEN

        Dka_Tools_Pkg.put_outdebug_message('N° FRS | N° FACTURE            | STATUT | DESCRIPTION                         | NBRE LIGNE ');

            Dka_Tools_Pkg.put_outdebug_message(
							rec_bilan_surtaxe.segment1  
			                        || '     | '
			                        ||rec_bilan_surtaxe.invoice_num
			                        || '  | '
			                        ||rec_bilan_surtaxe.status
			                        || '      | '
			                        ||rec_bilan_surtaxe.rejection_reason							
			                        || '    | '
			                        ||rec_bilan_surtaxe.nbre_ligne);


        LOOP
            FETCH cur_bilan_surtaxe INTO rec_bilan_surtaxe;
            EXIT WHEN cur_bilan_surtaxe%NOTFOUND;
            Dka_Tools_Pkg.put_outdebug_message(
							rec_bilan_surtaxe.segment1
			                        || '     | '
			                        ||rec_bilan_surtaxe.invoice_num
			                        || '  | '
			                        ||rec_bilan_surtaxe.status
			                        || '      | '
			                        ||rec_bilan_surtaxe.rejection_reason							
			                        || '    | '
			                        ||rec_bilan_surtaxe.nbre_ligne);



        END LOOP;    			
  
 				
      	ELSE
      	
         Dka_Tools_Pkg.put_outdebug_message('Aucune ligne traitée');
     	   	
      		
   	END IF;
	
	CLOSE cur_bilan_surtaxe;
  
END bilan_surtaxe;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : main6
--  Description   : Etat de contrôle des rejets de surtaxe
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE main6 (
        pv_errbuf   IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
	--pv_societe VARCHAR2(5);
	--pn_org_id NUMBER;
	
	BEGIN
	
	        pv_errbuf     := NULL;
	        pn_retcode    := 0;
			

	    -- Initialisation de l'état de sortie
	    Dka_Tools_Pkg.put_out_header;
	    Dka_Tools_Pkg.put_outdebug_message( CHR(10));

      --pn_org_id := Fnd_Profile.VALUE('ORG_ID');

      --Dka_Tools_Pkg.get_code_societe( pn_org_id, pv_societe, pv_errbuf, pn_retcode);
		  Dka_Tools_Pkg.put_outdebug_message('***************************** BILAN TOUTES SOCIETES *****************************');
	    Dka_Tools_Pkg.put_outdebug_message( CHR(10));

		
		-- Chargement de la table temporaire
		Dka_Sarsurtaxe_Pkg.insert_dka_sarsurtaxe_ctl_tmp(pv_errbuf, pn_retcode );

		
	    Dka_Tools_Pkg.put_outdebug_message('CONTROLE 1 : Vérification que le code partenaire est bien associé a un et un seul fournisseur.'||CHR(10));

	    Dka_Tools_Pkg.put_outdebug_message('1.A Vérification que le code partenaire a bien un fournisseur associé.'||CHR(10));

	    Dka_Sarsurtaxe_Pkg.controle_fournisseur_absent(pv_errbuf, pn_retcode );

	    Dka_Tools_Pkg.put_outdebug_message( CHR(10));
	    Dka_Tools_Pkg.put_outdebug_message('1.B Vérification que le code partenaire a bien un seul fournisseur.'||CHR(10));

	    Dka_Sarsurtaxe_Pkg.controle_fournisseur_doublon(pv_errbuf, pn_retcode );

	    Dka_Tools_Pkg.put_outdebug_message( CHR(10)); 
	    Dka_Tools_Pkg.put_outdebug_message('1.C Vérification des doublons de code CSC au niveau des fournisseurs présents en table de travail. '||CHR(10));

	    Dka_Sarsurtaxe_Pkg.CTR_FOURNISSEUR_DOUBLON_TMP(pv_errbuf, pn_retcode );

	    Dka_Tools_Pkg.put_outdebug_message( CHR(10));
	    Dka_Tools_Pkg.put_outdebug_message('CONTROLE 2 : Vérification que le site fournisseur existe pour le code partenaire.'||CHR(10));

	    Dka_Sarsurtaxe_Pkg.controle_site_frs_absent(pv_errbuf, pn_retcode );

	    Dka_Tools_Pkg.put_outdebug_message( CHR(10));
	    Dka_Tools_Pkg.put_outdebug_message('CONTROLE 3 : Le montant de la facture est inférieur à zéro.'||CHR(10));

	    Dka_Sarsurtaxe_Pkg.controle_facture_negative(pv_errbuf, pn_retcode );


	    Dka_Tools_Pkg.put_outdebug_message( CHR(10));
	    Dka_Tools_Pkg.put_outdebug_message('CONTROLE 4 : Synthèse des lignes traitées par le traitement de surtaxe.'||CHR(10));

	    Dka_Sarsurtaxe_Pkg.bilan_surtaxe(pv_errbuf, pn_retcode );


        Fnd_File.put_line (Fnd_File.output, CHR(10));
        Fnd_File.put_line (Fnd_File.output, CHR(10));
        Fnd_File.put_line (Fnd_File.output,'FIN DE L''ETAT D''ANOMALIE');
        Fnd_File.put_line (Fnd_File.output,'--------------------------------------------------------------');


END main6;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : main7
--  Description   : Lancement des éditions par centre de gestion
--
--  PARAMETRES    :
--          pv_invoices  varchar2
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	 varchar2
--	      pv_status	 varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE main7 (
        pv_errbuf               IN OUT   VARCHAR2,
        pn_retcode                 OUT   NUMBER,
        pv_include_all_invoices IN       VARCHAR2
    )
    IS
      CURSOR cur_region IS
          SELECT ffv.flex_value region
          FROM   fnd_flex_value_sets ffvs,
                 fnd_flex_values     ffv,
                 fnd_user            fu                                     -- OBE
          WHERE  ffvs.flex_value_set_name = 'DAOPCCF_UO' --'DAOPCCF_REGION' -- OBE
          AND    ffvs.flex_value_set_id   = ffv.flex_value_set_id
          AND    ffv.enabled_flag         = 'Y'
          AND    ffv.flex_value          != 'T'
          AND    fu.user_name             = ffv.flex_value                  -- OBE
          ORDER BY 1;

      rec_region             cur_region%ROWTYPE;
      vn_request_id          NUMBER;
      vn_user_id             fnd_user.user_id%TYPE;
      vc_copy_printer_name   fnd_printer.printer_name%TYPE;
      vc_output_print_style  fnd_concurrent_programs.output_print_style%TYPE;
	  vn_responsibility_id   NUMBER;
	  vn_appli_id            NUMBER;
    vv_include_all_invoices VARCHAR2(1);
	
	BEGIN
          pv_errbuf     := NULL;
          pn_retcode    := 0;
      
		  vn_responsibility_id := fnd_global.resp_id();
		  vn_appli_id := fnd_global.resp_appl_id();
      
      IF pv_include_all_invoices = 'N' THEN -- OBE artf2202695
        vv_include_all_invoices := 'N';
      ELSE
        vv_include_all_invoices := 'Y';
      END IF;

          -- Récupération du style de l'état
          ----------------------------------
          BEGIN
              SELECT output_print_style 
              INTO   vc_output_print_style
              FROM fnd_concurrent_programs
              WHERE concurrent_program_name = 'DKA_SARSURTAXE_RDF';

          EXCEPTION
              WHEN OTHERS THEN
                   vc_output_print_style := NULL;
          END;
	

          -- Boucle de recherche des centres de gestion
          ---------------------------------------------
          OPEN cur_region;
          LOOP
              FETCH cur_region INTO rec_region;
              EXIT WHEN cur_region%NOTFOUND;

              BEGIN
                  SELECT fu.user_id
                  INTO   vn_user_id
                  FROM   fnd_user fu
                  WHERE  fu.user_name = rec_region.region;
              END;
 
--              Fnd_Profile.Initialize ( vn_user_id );
			  fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_appli_id);

              vc_copy_printer_name := Fnd_Profile.VALUE ('PRINTER');

              -- Changement imprimante
              ------------------------
              IF fnd_request.set_print_options ( vc_copy_printer_name, -- Printer
                                                vc_output_print_style, -- Style
                                                1 -- Nb of copies
                                              ) THEN
                 Fnd_File.put_line(Fnd_File.LOG,'Sélection de l''imprimante '||vc_copy_printer_name||' pour l''impression de l''état de la région '||rec_region.region);
              ELSE
                 Fnd_File.put_line(Fnd_File.LOG,'Impossible de changer l''imprimante pour la région : '||rec_region.region);
              END IF;

              -- Lancement de l'état
              ----------------------
              Fnd_File.put_line(Fnd_File.LOG,'Lancement du traitement pour la region : '||rec_region.region);
              vn_request_id := Fnd_Request.submit_request ( 'DKA',                    --APPL
                                                            'DKA_SARSURTAXE_RDF',     --PROG
                                                            NULL,                     --PROGRAM_NAME
                                                            NULL,                     --START
                                                            FALSE,                    --SUB_REQUEST
                                                            vv_include_all_invoices,  --ARGUMENT1
                                                            rec_region.region,      --ARGUMENT2
                                                            Null                      --ARGUMENT3
                                                          );
              COMMIT;

              IF vn_request_id = 0 THEN
                 Fnd_File.put_line(Fnd_File.LOG,'Impossible de lancer l''édition pour la région : '||rec_region.region);
              ELSE
                 Fnd_File.put_line(Fnd_File.LOG,'Traitement : '||vn_request_id||' lancé pour la région : '||rec_region.region);
              END IF;


          END LOOP;
          CLOSE cur_region;
			
END main7;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : launch_xlaaccpb
--  Description   : Lancement du traitement Créer une comptabilisation
--
--  PARAMETRES    :
--          pv_invoices  varchar2
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	 varchar2
--	    pv_status	 varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE launch_xlaaccpb (
    pv_errbuf               IN OUT   VARCHAR2,
    pn_retcode                 OUT   NUMBER
)
IS
    
    vn_responsibility_id NUMBER;
    vn_application_id    NUMBER;
    vv_ar_responsibility VARCHAR2(100);
    vn_request_id        NUMBER;
    vn_approval_org_id   NUMBER;
    vv_phase             VARCHAR2(100);
    vv_status            VARCHAR2(100);
    vv_dev_phase         VARCHAR2(100);
    vv_dev_status        VARCHAR2(100);
    va_request_ids       pa_utils.IdTabTyp; ---Tableau
    vn_requests_cnt      NUMBER;
    vv_errbuf            VARCHAR2(150);
    vv_parameter         dka_parameters.parameter_name%TYPE;
    vn_prog_application_id NUMBER;
    vv_prog_application_short_name VARCHAR2(50);
    vn_program_id        NUMBER;
    vn_request_layout    BOOLEAN;

  --paramètres du traitement XLAACCPB
    n_application number;
    n_source_application number;
    n_ledger number;
    v_process_category varchar2(10);
    v_dummy0    varchar2(10);
    d_end_date date;
    v_create_accounting_flag varchar2(10);
    v_dummy1 varchar2(10);
    v_accounting_mode varchar2(10);
    v_dummy2 varchar2(10);
    v_errors_only_flag varchar2(10);
    v_report varchar2(20);
    v_transfer_to_gl_flag varchar2(10);
    v_dummy3 varchar2(10);
    v_gl_batch_name varchar2(10);
    v_mixed_currency_precision varchar2(10);
    v_post_to_gl varchar2(30);
    v_include_zero varchar2(10);
    v_include_zero_flag varchar2(10);
    v_request_id number;
    v_entity_id varchar2(10);
    n_source_application_name varchar2(10);
    v_application_name varchar2(20);
    v_ledger_name varchar2(50);
    v_short_name varchar2(10);
    v_ledger_id number;
    v_process_category_n varchar2(10);
    v_create_accounting varchar2(10);
    v_accounting_mode_name varchar2(30);
    v_errors_only varchar2(10);
    v_report_level varchar2(30);
    v_transfer_to_gl varchar2(30);
    v_post_in_gl varchar2(10);
    n_secu_id_int_1 number;
    n_secu_id_int_2 number;
    n_secu_id_int_3 number;
    v_security_id_char_1 varchar2(10);
    v_security_id_char_2 varchar2(10);
    v_security_id_char_3 varchar2(10);
    v_valuation_method varchar2(10);
    v_p_include_user_trx_id_flag varchar2(10);
    v_p_include_user_trx_id varchar2(10);
    v_p_debug_flag varchar2(10);
    v_p_user_id varchar2(10);
    v_p_scalable_flag varchar2(10);
    v_p_launch_balance_program varchar2(10);
    v_p_launch_bal_program varchar2(10);
    n_concurrent_request_id number;
    v_source_application_name varchar2(20);
  --curseur sur tous les livres comptables primaires définis dans le jeu de livres affecté à la responsabilité via l¿option de profil 'GL: Jeu d'accès aux données'
	/*CURSOR cur_acess is	  
		SELECT   gl.name livre , gl.ledger_id
		  FROM     gl_access_set_assignments gasa, gl_ledgers gl
		  WHERE    access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
		  AND      gl.ledger_id = gasa.ledger_id
		  AND      gl.ledger_category_code = 'PRIMARY' ;*/

BEGIN


    pn_retcode := 0;
    pv_errbuf  := NULL;
    --vv_ar_responsibility := 'TOUT_AR_ADMINISTRATEUR';
    
    --vv_ar_responsibility := v_short_name||'_AP_ADMINISTRATEUR';
    vv_ar_responsibility := 'TOUT_AP_ADMINISTRATEUR';
   
    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      RETURN;
    END IF;
    
    vn_requests_cnt := 0;
    dka_tools_pkg.gv_debug_mode := 'Y';
    dka_tools_pkg.put_debug_message('Recuperation des identifiants programme');        
    -- Récupération de l'id de l'application et de son nom court
    SELECT fcp.application_id,
           fa.application_short_name,
           fcp.concurrent_program_id
      INTO vn_prog_application_id,
           vv_prog_application_short_name,
           vn_program_id
      FROM fnd_concurrent_programs fcp, fnd_application fa
     WHERE fcp.concurrent_program_name = 'XLAACCPB'
       AND fa.application_id = fcp.application_id;

    

    --récupération des variables nécessaires au lancement du traitement
    SELECT fr.responsibility_id, fr.application_id
    INTO vn_responsibility_id, vn_application_id
    FROM fnd_responsibility fr
     WHERE fr.responsibility_key = vv_ar_responsibility;
     

    

    -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
    fnd_global.apps_initialize(fnd_global.user_id,
                 vn_responsibility_id,
                 vn_application_id);
    MO_GLOBAL.INIT('SQLAP');                  
    dka_tools_pkg.put_debug_message('initialisation réussie sur la resp:' ||vv_ar_responsibility ||'   '
                                      ||fnd_global.user_id   ||'   '
                                      ||vn_responsibility_id ||'   '
                                      ||vn_application_id);    
    
    FOR rec IN (SELECT DISTINCT set_of_books_id
                FROM dka_sarsurtaxe_tmp a,
                     hr_operating_units b
                WHERE b.organization_id = a.org_id
				  AND a.STATUS <>'Z'
                )
    LOOP               
    
        --BEGIN
        dka_tools_pkg.put_debug_message('Recuperation du ledger_id');   
        -- Récupération du ledger_id 
        SELECT ledger_id, name, short_name
        INTO v_ledger_id, v_ledger_name, v_short_name
        FROM gl_ledgers
        WHERE ledger_id = rec.set_of_books_id --TO_NUMBER(gl_access_set_security_pkg.get_default_ledger_id(FND_PROFILE.value('GL_ACCESS_SET_ID'), 'R'))
        ;    
        /*EXCEPTION
          WHEN OTHERS THEN
        END;*/
        dka_tools_pkg.put_debug_message('Recuperation du ledger_id : '||v_ledger_name);   

        --FOR rec_livre IN cur_acess LOOP
            ----------------------------------
            -- Renseignement des paramètres --
            ----------------------------------
        -- Récupération des valeurs par défaut
       dka_tools_pkg.put_debug_message('Récupération des paramètres');
       --dka_tools_pkg.put_debug_message(v_ledger_id);
       --dka_tools_pkg.put_debug_message(fnd_profile.value('RESP_APPL_ID'));

        SELECT lookup_code
        into v_accounting_mode
        FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
        WHERE XLK.LOOKUP_TYPE = 'XLA_ACCOUNTING_ENTRY_STATUS'
        AND    XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
        AND   XSO.APPLICATION_ID = vn_application_id
        AND   XSO.LEDGER_ID      = v_ledger_id;

        SELECT lookup_code into v_transfer_to_gl_flag
        FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
        WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
        AND    XLK.LOOKUP_CODE = XSO.SUBMIT_TRANSFER_TO_GL_FLAG
        AND   XSO.APPLICATION_ID = vn_application_id
        AND   XSO.LEDGER_ID = v_ledger_id;

        SELECT lookup_code into v_report
        FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
        WHERE XLK.LOOKUP_TYPE = 'XLA_REPORT_LEVEL'
        AND    XLK.LOOKUP_CODE = XSO.SUMMARY_REPORT_FLAG
        AND   XSO.APPLICATION_ID = vn_application_id
        AND   XSO.LEDGER_ID = v_ledger_id;

        SELECT MEANING into v_report_level
        FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
        WHERE XLK.LOOKUP_TYPE = 'XLA_REPORT_LEVEL'
        AND    XLK.LOOKUP_CODE = XSO.SUMMARY_REPORT_FLAG
        AND   XSO.APPLICATION_ID = vn_application_id
        AND   XSO.LEDGER_ID = v_ledger_id;

        SELECT MEANING into v_transfer_to_gl
        FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
        WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
        AND    XLK.LOOKUP_CODE = XSO.SUBMIT_TRANSFER_TO_GL_FLAG
        AND   XSO.APPLICATION_ID = vn_application_id
        AND   XSO.LEDGER_ID = v_ledger_id;

        SELECT meaning into v_accounting_mode_name
        FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
        WHERE XLK.LOOKUP_TYPE = 'XLA_ACCOUNTING_ENTRY_STATUS'
        AND    XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
        AND   XSO.APPLICATION_ID = vn_application_id
        AND   XSO.LEDGER_ID = v_ledger_id;
        
        SELECT meaning into v_post_in_gl
        FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
        WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
        AND    XLK.LOOKUP_CODE = XSO.SUBMIT_GL_POST_FLAG
        AND   XSO.APPLICATION_ID = vn_application_id
        AND   XSO.LEDGER_ID = v_ledger_id;

        SELECT lookup_code into v_post_to_gl
        FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
        WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
        AND    XLK.LOOKUP_CODE = XSO.SUBMIT_GL_POST_FLAG
        AND   XSO.APPLICATION_ID = vn_application_id
        AND   XSO.LEDGER_ID = v_ledger_id;
        
        SELECT MEANING into v_p_launch_bal_program FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'Y';

        SELECT lookup_code into v_create_accounting_flag FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'Y';

        SELECT 'Y' into v_dummy2 FROM DUAL WHERE NVL(v_accounting_mode,'F') = 'F';

        SELECT LOOKUP_CODE into v_errors_only_flag FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'N';

        SELECT meaning into v_p_include_user_trx_id FROM xla_lookups WHERE lookup_type ='XLA_YES_NO' and lookup_code ='N';

        SELECT application_name into v_source_application_name from fnd_application_tl where application_id=fnd_profile.value('resp_appl_id') and language='F';

        SELECT application_name into v_application_name from fnd_application_tl where application_id=fnd_profile.value('resp_appl_id') and language='F';

        --SELECT 'Y' into v_dummy3 FROM DUAL WHERE v_transfer_to_gl_flag = 'Y';
        SELECT lookup_code into v_include_zero_flag FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'N';

        -- SELECT name into v_ledger_name from gl_ledgers where ledger_id=v_ledger_id;
        SELECT MEANING into v_create_accounting FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'Y';

        SELECT MEANING into v_errors_only FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'N';

        SELECT MEANING into v_include_zero FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'N';

        --v_ledger_name := rec_livre.livre;
                
        n_application:= fnd_profile.value('RESP_APPL_ID');
        n_source_application:=fnd_profile.value('RESP_APPL_ID');
        n_ledger:=v_ledger_id;
        v_dummy0:='Y';
        d_end_date:=sysdate;
        v_process_category:=null;
        v_dummy1:='Y';
        v_dummy3:='Y';
        v_mixed_currency_precision:=null;
        v_gl_batch_name:=null;
        v_request_id:=null;
        v_entity_id:=null;
        v_process_category_n:=null;
        v_p_include_user_trx_id_flag:='N';
        v_p_debug_flag:='N';
        v_p_user_id :=fnd_global.user_id;
        v_p_scalable_flag:='N';
        v_p_launch_balance_program :='Y';
        n_secu_id_int_1:=null;
        n_secu_id_int_2:=null;
        n_secu_id_int_3:=null;
        v_security_id_char_1 :=null;
        v_security_id_char_2 :=null;
        v_security_id_char_3 :=null;
        v_valuation_method:=null;
        v_p_launch_balance_program:='Y';
        n_concurrent_request_id :=null;


        Fnd_File.put_line(Fnd_File.LOG,'Soumission du traitement appli = :'||vv_prog_application_short_name ||' short_name: '||vn_program_id);

        -- Ajout du template
        vn_request_layout := FND_REQUEST.add_layout('XLA',
                                                    'XLAACCPB02',
                                                    'fr',
                                                    'FR',
                                                    'PDF');
                                                
        IF vn_request_layout THEN

          vn_request_id    := fnd_request.submit_request (
                                  vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT  'SQLAR'
                                  'XLAACCPB', --SHORT_NAME du TRAITEMENT
                                  NULL, --PROGRAM_NAME
                                  NULL, --START
                                  FALSE, --SUB_REQUEST
                                  n_application,
                                  n_source_application,
                                  v_dummy0,
                                  n_ledger,
                                  v_process_category, -- Process Category ,
                                  TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'), --ARGUMENT6
                                  v_create_accounting_flag,
                                  v_dummy1,
                                  v_accounting_mode,
                                  v_dummy2,
                                  v_errors_only_flag,
                                  v_report,
                                  v_transfer_to_gl_flag,
                                  v_dummy3,
                                  v_post_to_gl,
                                  v_gl_batch_name, -- GL Batch Name,
                                  v_mixed_currency_precision,
                                  v_include_zero_flag,
                                  v_request_id,
                                  v_entity_id,
                                  v_source_application_name,
                                  v_application_name,
                                  v_ledger_name,
                                  v_process_category_n,
                                  v_create_accounting,
                                  v_accounting_mode_name,
                                  v_errors_only,
                                  v_report_level,
                                  v_transfer_to_gl,
                                  v_post_in_gl,
                                  v_include_zero,
                                  v_valuation_method,
                                  v_security_id_char_1,
                                  v_security_id_char_2,
                                  v_security_id_char_3,
                                  n_secu_id_int_1,
                                  n_secu_id_int_2,
                                  n_secu_id_int_3,
                                  n_concurrent_request_id,
                                  v_p_include_user_trx_id_flag,
                                  v_p_include_user_trx_id,
                                  v_p_debug_flag,
                                  v_p_user_id,
                                  v_p_scalable_flag,
                                  v_p_launch_balance_program,
                                  v_p_launch_bal_program
                              );

            dka_tools_pkg.put_debug_message('Valeur de vn_request_id = '||vn_request_id );
            IF vn_request_id IS NULL THEN
              pn_retcode := 1;
              pv_errbuf  := 'Le traitement d''approbation n''a pas pu être lancé pour la livre  ' ||
                            v_ledger_name;--rec_livre.livre;
            ELSE
              pn_retcode := 0;
              pv_errbuf  := 'Traitement d''approbation : ' ||
                            TO_CHAR(vn_request_id) || ' lancé sur la livre ' ||
                            v_ledger_name;--rec_livre.livre;
              dka_tools_pkg.put_debug_message(pv_errbuf);

              vn_requests_cnt := vn_requests_cnt + 1;
              va_request_ids(vn_requests_cnt) := vn_request_id;

            END IF;

            COMMIT;
          
        END IF;
        
    END LOOP;

    WHILE vn_requests_cnt > 0 LOOP
      IF NOT (fnd_concurrent.wait_for_request(va_request_ids(vn_requests_cnt),
                                              15,
                                              0,
                                              vv_phase,
                                              vv_status,
                                              vv_dev_phase,
                                              vv_dev_status,
                                              vv_errbuf)) THEN
        dka_tools_pkg.put_outdebug_message('Traitement numéro ' ||
                                           TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                           ' trop long ou tombé en erreur');
      ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
        dka_tools_pkg.put_debug_message('Traitement numéro ' ||
                                        TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                        ' correctement exécuté');
      END IF;

      vn_requests_cnt := vn_requests_cnt - 1;

    END LOOP;      
    
   --END LOOP;

EXCEPTION
    WHEN OTHERS
    THEN
        pn_retcode    := SQLCODE;
        pv_errbuf     := SQLERRM;        
    
END launch_xlaaccpb;    


END Dka_Sarsurtaxe_Pkg; -- Package body
/
SHOW ERRORS;

EXIT
