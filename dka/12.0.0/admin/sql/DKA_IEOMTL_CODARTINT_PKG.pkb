create or replace PACKAGE BODY dka_ieomtl_codartint_pkg AS
------------------------------------------------------------------------
-- $Id: DKA_IEOMTL_CODARTINT_PKG.pkb
-- Capgemini
-- Nom              : DKA_IEOMTL_CODARTINT_PKG.pkb
-- Description      : Spécification du package DKA_IEOMTL_CODARTINT_PKG
-- Auteur           : F.Siham
-- Date de création : 01/11/2018
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------
-- 16/01/2019 CDE Ajustement package
-- 18/01/2019 SFA Modification gestion des erreurs de paramétrage
-- 23/01/2019 CDE Ajustement mise à jour des articles
-- 24/01/2019 SFA Modification pour optimisation du lancement de l'OI
-- 07/02/2019 SFA INT083 Interface des articles - Retour recette 1
-- 25/02/2019 CDE Ajout paramètre calcul stats
-- 06/01/2020 SEL Mettre en commentaire les stats sur les tables hors open interface
--				  et ajouter le parametre de parallelization à 8 pour l'open-interface
-- ---------- --- ------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    vg_phase1                   CONSTANT VARCHAR2(20) := 'VALIDATION_DONNEES';
    vg_phase2                   CONSTANT VARCHAR2(20) := 'INIT';
    vg_user_id                  CONSTANT NUMBER := fnd_profile.value('USER_ID');
    vg_login_id                 CONSTANT NUMBER := fnd_profile.value('LOGIN_ID');
    vg_request_id               CONSTANT NUMBER := fnd_profile.value('CONC_REQUEST_ID');
    vg_org_id                   CONSTANT NUMBER := fnd_profile.value('ORG_ID');
    vg_org_id_principale        hr_all_organization_units.organization_id%TYPE;
    vg_account_category_id      mtl_categories_b.category_id%TYPE;
    vg_security_profile_id      mtl_category_sets.structure_id%TYPE;
    vg_item_category_set_id1    mtl_category_sets.structure_id%TYPE;
    vg_item_category_set_id2    mtl_category_sets.structure_id%TYPE;
    vg_category_principale_id   mtl_categories_b.category_id%TYPE;
    vg_category_sec1_id         mtl_categories_b.category_id%TYPE;
    vg_category_sec2_id         mtl_categories_b.category_id%TYPE;
    vg_category_sec3_id         mtl_categories_b.category_id%TYPE;
    vg_category_sec4_id         mtl_categories_b.category_id%TYPE;
    vg_category_sec5_id         mtl_categories_b.category_id%TYPE;
    vg_template_id              mtl_item_templates.template_id%TYPE;
    vg_uom_code                 mtl_units_of_measure_tl.uom_code%TYPE;
    vg_structure_id1            mtl_category_sets.structure_id%TYPE;
    vg_structure_id2            mtl_category_sets.structure_id%TYPE;
    VG_default_category_id      mtl_category_sets.DEFAULT_CATEGORY_ID%TYPE;
    vg_status_active            mtl_system_items_b.inventory_item_status_code%TYPE;
    vg_nb_flexv_comp_tech_aj    NUMBER :=0;
    vg_nb_flexv_class_tech_mod  NUMBER :=0;
    vg_nb_flexv_comp_tech_mod   NUMBER :=0;   
    vg_nb_art_renouv_charge     NUMBER :=0;
    vg_nb_art_recycle           NUMBER:=0;
    vg_nb_art_rej_valid         NUMBER:=0;
    vg_nb_art_val_valid         NUMBER:=0;
    vg_nb_art_err_int           NUMBER:=0;
    vg_nb_art_err_aff_cat       NUMBER:=0;
    vg_nb_art_tot_traite        NUMBER:=0;
    vg_flex_value_set_id_eclass fnd_flex_value_sets.flex_value_set_id%TYPE;
    vg_flex_value_set_id_tech   fnd_flex_value_sets.flex_value_set_id%TYPE;
    vg_tempo                    NUMBER:=20;
    vg_val1                     VARCHAR2(150);
    vg_val_erreur               VARCHAR2(1000):='';
    vg_erreur                   VARCHAR2(1000);    
    vg_nblignes_lot             NUMBER;
    vg_calc_stats               NUMBER;

    TYPE  IdTabTyp      IS TABLE OF NUMBER(15)
    INDEX BY BINARY_INTEGER;

    CURSOR cur_org_fille 
						(
							gl_org_principale_id NUMBER,
							VG_SECURITY_PROFILE_ID NUMBER
						) 
						IS 
						( 
						  SELECT
								organization_id,
								organization_code
						  FROM
									mtl_parameters
                          WHERE
									  master_organization_id = gl_org_principale_id
									AND organization_id 
										IN 
											(
												 SELECT
													 organization_id
												 FROM
													 per_security_organizations
												 WHERE
													 security_profile_id = VG_SECURITY_PROFILE_ID
											)
						);


 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


 	------------------------------------------------------------------------------------
	--  Nom           : chgt_file_cod_artint
	--	Description		:	fonction pour alimenation de la table temporaire DKA_IEOMTL_SYSTEM_ITEMS_TMP

	--
	--  PARAMETRES    :
	--      access_id  : id du fichier
	--      pv_file_id : nom du fichier
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    FUNCTION chgt_file_cod_artint (
        access_id          IN NUMBER,
        pv_file_id         OUT VARCHAR2,
        pv_message_erreur  OUT VARCHAR2
    ) RETURN VARCHAR2 IS

	  --DEBUT----------------------------------------------------------------------------------
	  -- définition des variables pour l'insertion dans la table DKA_IEOMTL_SYSTEM_ITEMS_TMP --
	  -----------------------------------------------------------------------------------------

        v_result                         VARCHAR2(200);
        v_file_name                      VARCHAR2(100);
        v_file_id                        VARCHAR2(256);
        v_gfm_id                         NUMBER := NULL;
        src_lob                          BLOB;
        buffer_var1                      CLOB;
        v_separator                      VARCHAR2(1) := ';';
        v_dest_offset                    INTEGER := 1;
        v_src_offset                     INTEGER := 1;
        v_warning                        INTEGER;
        v_lang_context                   NUMBER := dbms_lob.default_lang_ctx;
        v_error                          NUMBER;
        v_existing_records               NUMBER;
        v_categorie_principale           dka_ieomtl_system_items_tmp.categorie_principale%TYPE;
        v_designation_cat_principale     dka_ieomtl_system_items_tmp.designation_cat_principale%TYPE;
        v_categorie_secondaire_1         dka_ieomtl_system_items_tmp.categorie_secondaire_1%TYPE;
        v_designation_cat_secondaire_1   dka_ieomtl_system_items_tmp.designation_cat_secondaire_1%TYPE;
        v_categorie_secondaire_2         dka_ieomtl_system_items_tmp.categorie_secondaire_2%TYPE;
        v_designation_cat_secondaire_2   dka_ieomtl_system_items_tmp.designation_cat_secondaire_2%TYPE;
        v_categorie_secondaire_3         dka_ieomtl_system_items_tmp.categorie_secondaire_3%TYPE;
        v_designation_cat_secondaire_3   dka_ieomtl_system_items_tmp.designation_cat_secondaire_3%TYPE;
        v_categorie_secondaire_4         dka_ieomtl_system_items_tmp.categorie_secondaire_4%TYPE;
        v_designation_cat_secondaire_4   dka_ieomtl_system_items_tmp.designation_cat_secondaire_4%TYPE;
        v_categorie_secondaire_5         dka_ieomtl_system_items_tmp.categorie_secondaire_5%TYPE;
        v_designation_cat_secondaire_5   dka_ieomtl_system_items_tmp.designation_cat_secondaire_5%TYPE;
        v_code_article                   dka_ieomtl_system_items_tmp.code_article%TYPE;
        v_description_article            dka_ieomtl_system_items_tmp.description_article%TYPE;
        v_code_eclass_n2                 dka_ieomtl_system_items_tmp.code_eclass_n2%TYPE;
        v_libelle_eclass_n2              dka_ieomtl_system_items_tmp.libelle_eclass_n2%TYPE;
        v_code_eclass_n3                 dka_ieomtl_system_items_tmp.code_eclass_n3%TYPE;
        v_libelle_eclass_n3              dka_ieomtl_system_items_tmp.libelle_eclass_n3%TYPE;
        v_code_eclass_n4                 dka_ieomtl_system_items_tmp.code_eclass_n4%TYPE;
        v_libelle_eclass_n4              dka_ieomtl_system_items_tmp.libelle_eclass_n4%TYPE;
        v_code_compl_n1                  dka_ieomtl_system_items_tmp.code_compl_n1%TYPE;
        v_designation_compl_n1           dka_ieomtl_system_items_tmp.designation_compl_n1%TYPE;
        v_code_compl_n2                  dka_ieomtl_system_items_tmp.code_compl_n2%TYPE;
        v_designation_compl_n2           dka_ieomtl_system_items_tmp.designation_compl_n2%TYPE;
        v_code_compl_n3                  dka_ieomtl_system_items_tmp.code_compl_n3%TYPE;
        v_designation_compl_n3           dka_ieomtl_system_items_tmp.designation_compl_n3%TYPE;
        v_code_compl_n4                  dka_ieomtl_system_items_tmp.code_compl_n4%TYPE;
        v_designation_compl_n4           dka_ieomtl_system_items_tmp.designation_compl_n4%TYPE;
        v_code_compl_n5                  dka_ieomtl_system_items_tmp.code_compl_n5%TYPE;
        v_designation_compl_n5           dka_ieomtl_system_items_tmp.designation_compl_n5%TYPE;
        v_code_compl_n6                  dka_ieomtl_system_items_tmp.code_compl_n6%TYPE;
        v_designation_compl_n6           dka_ieomtl_system_items_tmp.designation_compl_n6%TYPE;
        v_code_compl_n7                  dka_ieomtl_system_items_tmp.code_compl_n7%TYPE;
        v_designation_compl_n7           dka_ieomtl_system_items_tmp.designation_compl_n7%TYPE;
        v_code_compl_n8                  dka_ieomtl_system_items_tmp.code_compl_n8%TYPE;
        v_designation_compl_n8           dka_ieomtl_system_items_tmp.designation_compl_n8%TYPE;
        v_code_compl_n9                  dka_ieomtl_system_items_tmp.code_compl_n9%TYPE;
        v_designation_compl_n9           dka_ieomtl_system_items_tmp.designation_compl_n9%TYPE;
        v_unite_de_mesure                dka_ieomtl_system_items_tmp.unite_de_mesure%TYPE;
        v_statut_article                 dka_ieomtl_system_items_tmp.statut_article%TYPE;
        v_supp_rejet                     dka_ieomtl_system_items_tmp.supp_rejet%TYPE;
        v_status                         VARCHAR2(25);
        v_line_num                       NUMBER;
        v_offset                         INTEGER := 1;
        v_line_length                    PLS_INTEGER;
        v_line                           VARCHAR2(32767);
        v_total_length                   BINARY_INTEGER;
        v_cmpt_commit                    NUMBER;
        v_oracle_charset                 fnd_lobs.oracle_charset%TYPE;
        v_line_num                       NUMBER;
        v_i                              NUMBER;
        v_nb_article_unique              NUMBER;
        v_nb_err                         NUMBER :=0;
        v_nb_ligne_err                   NUMBER :=0;
	      v_ch_pb                          VARCHAR2(1000);
        v_message_erreur                 VARCHAR2(1000);

 ------------------------------------------------------------------------------------   
    BEGIN
       -- V_RESULT := 'OK';
        V_ERROR := 0;
        v_cmpt_commit := 0;
        v_message_erreur := NULL;

       -- Purge de la table temporaire DKA_IEOMTL_ERROR --
        EXECUTE IMMEDIATE 'truncate table DKA.DKA_IEOMTL_ERROR';	

        /*/--alimentation de la table DKA_IEOMTL_SYSTEM_ITEMS_TMP--//*/

        V_GFM_ID := fnd_gfm.get_file_id(access_id);
        IF V_GFM_ID IS NOT NULL THEN
            SELECT
                file_name,
                DECODE(instr(file_name,'/'),0,file_name,substr(file_name,instr(file_name,'/') + 1) ),
                file_data,
                oracle_charset
            INTO
                V_FILE_NAME,
                V_FILE_ID,
                src_lob,
                V_ORACLE_CHARSEt
            FROM
                fnd_lobs
            WHERE
                file_id = V_GFM_ID;

				    -- convertit le blob en clob

            dbms_lob.createtemporary(buffer_var1,true);
            dbms_lob.converttoclob(dest_lob => buffer_var1,
                                   src_blob => src_lob,
                                   amount => dbms_lob.lobmaxsize,
                                   dest_offset => V_DEST_OFFSET,
                                   src_offset => V_SRC_OFFSET,
                                   blob_csid => nls_charset_id(V_ORACLE_CHARSEt),
                                   lang_context => V_LANG_CONTEXT,warning => v_warning);

				    -- get file size				

            V_TOTAL_LENGTH := dbms_lob.getlength(buffer_var1); 
				    --récuperer numéro de ligne
            V_I := 0;
            
            WHILE V_OFFSET < V_TOTAL_LENGTH LOOP
                V_I := V_I + 1;
                v_ch_pb := '';
                V_NB_ERR := 0;

				        --get line size 				
                V_LINE_LENGTH := instr(buffer_var1,chr(10),V_OFFSET) - V_OFFSET;
                IF V_LINE_LENGTH < 0 THEN
                    V_LINE_LENGTH := V_TOTAL_LENGTH + 1 - V_OFFSET;
                END IF;
                V_LINE := substr(buffer_var1,V_OFFSET,V_LINE_LENGTH);


                IF V_I > 1                    -- On ne traite pas la ligne de titre
                THEN   
			 	           --vv_cmpt_commit:=vv_cmpt_commit+1;
                   BEGIN
                       V_CATEGORIE_PRINCIPALE := substr(V_LINE,'1',instr(V_LINE,V_SEPARATOR,1,1) - 1);
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_CATEGORIE_PRINCIPALE := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CATEGORIE_PRINCIPALE dépasse 11 caractères, ';
                   END;

                   BEGIN
                       V_DESIGNATION_CAT_PRINCIPALE := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,1) + 1, ( (instr(V_LINE,V_SEPARATOR,1,2) ) - (instr(V_LINE,V_SEPARATOR,1,1) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_DESIGNATION_CAT_PRINCIPALE := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'DESIGNATION_CAT_PRINCIPALE dépasse 240 caractères, ';
                   END;

                   BEGIN
                       V_CATEGORIE_SECONDAIRE_1 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,2) + 1, ( (instr(V_LINE,V_SEPARATOR,1,3) ) - (instr(V_LINE,V_SEPARATOR,1,2) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_CATEGORIE_SECONDAIRE_1 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CATEGORIE_SECONDAIRE_1 dépasse 11 caractères, ';
                   END;

                   BEGIN
                       V_DESIGNATION_CAT_SECONDAIRE_1 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,3) + 1, ( (instr(V_LINE,V_SEPARATOR,1,4) ) - (instr(V_LINE,V_SEPARATOR,1,3) + 1) ) );             
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_DESIGNATION_CAT_SECONDAIRE_1 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'DESIGNATION_CAT_SECONDAIRE_1 dépasse 240 caractères, ';                        
                   END;

                   BEGIN
                       V_CATEGORIE_SECONDAIRE_2 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,4) + 1, ( (instr(V_LINE,V_SEPARATOR,1,5) ) - (instr(V_LINE,V_SEPARATOR,1,4) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_CATEGORIE_SECONDAIRE_2 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CATEGORIE_SECONDAIRE_2 dépasse 11 caractères, ';
                   END;

                   BEGIN
                       V_DESIGNATION_CAT_SECONDAIRE_2 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,5) + 1, ( (instr(V_LINE,V_SEPARATOR ,1,6) ) - (instr(V_LINE,V_SEPARATOR,1,5) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_DESIGNATION_CAT_SECONDAIRE_2 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'DESIGNATION_CAT_SECONDAIRE_2 dépasse 240 caractères, ';                
                   END;

                   BEGIN
                       V_CATEGORIE_SECONDAIRE_3 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,6) + 1, ( (instr(V_LINE,V_SEPARATOR,1,7) ) - (instr(V_LINE,V_SEPARATOR,1,6) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_CATEGORIE_SECONDAIRE_3 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CATEGORIE_SECONDAIRE_3 dépasse 11 caractères, ';
                   END;

                   BEGIN
                       V_DESIGNATION_CAT_SECONDAIRE_3 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,7) + 1, ( (instr(V_LINE,V_SEPARATOR ,1,8) ) - (instr(V_LINE,V_SEPARATOR,1,7) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_DESIGNATION_CAT_SECONDAIRE_3 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'DESIGNATION_CAT_SECONDAIRE_3 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       V_CATEGORIE_SECONDAIRE_4 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,8) + 1, ( (instr(V_LINE,V_SEPARATOR,1,9) ) - (instr(V_LINE,V_SEPARATOR,1,8) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_CATEGORIE_SECONDAIRE_4 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CATEGORIE_SECONDAIRE_4 dépasse 11 caractères,';
                   END;

                   BEGIN
                       V_DESIGNATION_CAT_SECONDAIRE_4 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,9) + 1, ( (instr(V_LINE,V_SEPARATOR,1,10) ) - (instr(V_LINE,V_SEPARATOR,1,9) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_DESIGNATION_CAT_SECONDAIRE_4 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'DESIGNATION_CAT_SECONDAIRE_4 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       V_CATEGORIE_SECONDAIRE_5 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,10) + 1, ( (instr(V_LINE,V_SEPARATOR,1,11) ) - (instr(V_LINE,V_SEPARATOR,1,10) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_CATEGORIE_SECONDAIRE_5 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CATEGORIE_SECONDAIRE_5 dépasse 11 caractères, ';
                   END;

                   BEGIN
                       V_DESIGNATION_CAT_SECONDAIRE_5 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,11) + 1, ( (instr(V_LINE,V_SEPARATOR,1,12) ) - (instr(V_LINE,V_SEPARATOR,1,11) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_DESIGNATION_CAT_SECONDAIRE_5 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'DESIGNATION_CAT_SECONDAIRE_5 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       V_code_article := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,12) + 1, ( (instr(V_LINE,V_SEPARATOR,1,13) ) - (instr(V_LINE,V_SEPARATOR,1,12) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        V_code_article := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CODE_ARTICLE dépasse 49 caractères,';
                   END;

                   BEGIN
                        v_description_article := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,13) + 1, ( (instr(V_LINE,V_SEPARATOR,1,14) ) - (instr(V_LINE,V_SEPARATOR,1,13) + 1) ) );              
                   EXCEPTION
                    WHEN OTHERS THEN
                        v_description_article := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'DESCRIPTION_ARTICLE dépasse 240 caractères, ';
                   END;

                   BEGIN
                       v_code_eclass_n2 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,14) + 1, ( (instr(V_LINE,V_SEPARATOR,1,15) ) -(instr(V_LINE,V_SEPARATOR,1,14) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        v_code_eclass_n2 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CODE ECLASS N2 dépasse 8 caractères,';
                   END;

                   BEGIN
                      v_libelle_eclass_n2 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,15) + 1, ( (instr(V_LINE,V_SEPARATOR,1,16) ) - (instr(V_LINE,V_SEPARATOR,1,15) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        v_libelle_eclass_n2 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'LIBELLE ECLASS N2 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       v_code_eclass_n3 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,16) + 1, ( (instr(V_LINE,V_SEPARATOR,1,17) ) -(instr(V_LINE,V_SEPARATOR,1,16) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        v_code_eclass_n3 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CODE ECLASS N3 dépasse 8 caractères, ';
                   END;

                   BEGIN
                       v_libelle_eclass_n3 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,17) + 1, ( (instr(V_LINE,V_SEPARATOR,1,18) )- (instr(V_LINE,V_SEPARATOR,1,17) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        v_libelle_eclass_n3 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'LIBELLE ECLASS N3 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       v_code_eclass_n4 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,18) + 1, ( (instr(V_LINE,V_SEPARATOR,1,19) ) - (instr(V_LINE,V_SEPARATOR,1,18) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        v_code_eclass_n4 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'CODE ECLASS N4 dépasse 8 caractères, ';
                   END;

                   BEGIN
                       v_libelle_eclass_n4 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,19) + 1, ( (instr(V_LINE,V_SEPARATOR,1,20) )- (instr(V_LINE,V_SEPARATOR,1,19) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                        v_libelle_eclass_n4 := NULL;
                        V_NB_ERR := V_NB_ERR +1;
                        v_ch_pb  := v_ch_pb || 'LIBELLE ECLASS N4 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       v_code_compl_n1 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,20) + 1, ( (instr(V_LINE,V_SEPARATOR,1,21) ) - ( instr(V_LINE,V_SEPARATOR,1,20) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n1 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N1 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n1 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,21) + 1, ( (instr(V_LINE,V_SEPARATOR,1,22 ) ) - (instr(V_LINE,V_SEPARATOR,1,21) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n1 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N1 dépasse 240 caractères, ';
                   END;

                   BEGIN
                      v_code_compl_n2 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,22) + 1, ( (instr(V_LINE,V_SEPARATOR,1,23) ) - (instr(V_LINE,V_SEPARATOR,1,22) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n2 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N2 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n2 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,23) + 1, ( (instr(V_LINE,V_SEPARATOR,1,24) ) - (instr(V_LINE,V_SEPARATOR,1,23) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n2 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N2 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       v_code_compl_n3 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,24) + 1, ( (instr(V_LINE,V_SEPARATOR,1,25) ) - (instr(V_LINE,V_SEPARATOR,1,24) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n3 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N3 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n3 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,25) + 1, ( (instr(V_LINE,V_SEPARATOR,1,26) ) - (instr(V_LINE,V_SEPARATOR,1,25) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n3 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N3 dépasse 240 caractères, ';
                   END;

                   BEGIN
                      v_code_compl_n4 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,26) + 1, ( (instr(V_LINE,V_SEPARATOR,1,27) ) - ( instr(V_LINE,V_SEPARATOR,1,26) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n4 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N4 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n4 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,27) + 1, ( (instr(V_LINE,V_SEPARATOR,1,28) ) - (instr(V_LINE,V_SEPARATOR,1,27) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n4 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N4 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       v_code_compl_n5 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,28) + 1, ( (instr(V_LINE,V_SEPARATOR,1,29) ) - (instr(V_LINE,V_SEPARATOR,1,28) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n5 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N5 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n5 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,29) + 1, ( (instr(V_LINE,V_SEPARATOR,1,30) ) - (instr(V_LINE,V_SEPARATOR,1,29) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n5 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N5 dépasse 240 caractères, '; 
                   END;

                   BEGIN
                       v_code_compl_n6 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,30) + 1, ( (instr(V_LINE,V_SEPARATOR,1,31) ) - (instr(V_LINE,V_SEPARATOR,1,30) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n6 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N6 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n6 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,31) + 1, ( (instr(V_LINE,V_SEPARATOR,1,32) ) - (instr(V_LINE,V_SEPARATOR,1,31) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n6 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N6 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       v_code_compl_n7 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,32) + 1, ( (instr(V_LINE,V_SEPARATOR,1,33) ) - (instr(V_LINE,V_SEPARATOR,1,32) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n7 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N7 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n7 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,33) + 1, ( (instr(V_LINE,V_SEPARATOR,1,34) ) - (instr(V_LINE,V_SEPARATOR,1,33) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n7 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N7 dépasse 240 caractères,  ';
                   END;

                   BEGIN
                       v_code_compl_n8 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,34) + 1, ( (instr(V_LINE,V_SEPARATOR,1,35) ) - (instr(V_LINE,V_SEPARATOR,1,34) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n8 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N8 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n8 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,35) + 1, ( (instr(V_LINE,V_SEPARATOR,1,36) ) - (instr(V_LINE,V_SEPARATOR,1,35) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n8 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N8 dépasse 240 caractères, ';
                   END;

                   BEGIN
                       v_code_compl_n9 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,36) + 1, ( (instr(V_LINE,V_SEPARATOR,1,37) ) - (instr(V_LINE,V_SEPARATOR,1,36) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_code_compl_n9 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'CODE COMPL N9 dépasse 10 caractères, ';
                   END;

                   BEGIN
                       v_designation_compl_n9 := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,37) + 1, ( (instr(V_LINE,V_SEPARATOR,1,38) ) - (instr(V_LINE,V_SEPARATOR,1,37) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_designation_compl_n9 := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'DESIGNATION COMPL N9 dépasse 240 caractères ';
                   END;

                   BEGIN
                       v_unite_de_mesure := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,38) + 1, ( (instr(V_LINE,V_SEPARATOR,1,39) ) -(instr(V_LINE,V_SEPARATOR,1,38) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_unite_de_mesure := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'UNITE DE MESURE dépasse 25 caractères, ';
                   END;

                   BEGIN
                       v_statut_article := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,39) + 1, ( (instr(V_LINE,V_SEPARATOR,1,40) ) - (instr(V_LINE,V_SEPARATOR,1,39) + 1) ) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_statut_article := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'STATUT ARTICLE dépasse 25 caractères, ';
                   END;

                   BEGIN
                       v_supp_rejet := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,40) + 1, length(V_LINE) - (instr (V_LINE,V_SEPARATOR,1,40) + 1) );
                   EXCEPTION
                    WHEN OTHERS THEN
                       v_supp_rejet := NULL;
                       V_NB_ERR := V_NB_ERR +1;
                       v_ch_pb  := v_ch_pb || 'SUPP REJET dépasse 3 caractères';
                   END;


                   IF V_NB_ERR>0 
                   THEN
                       v_nb_ligne_err := v_nb_ligne_err + 1;
                       v_message_erreur := substr(v_message_erreur ||CHR(10)||'Ligne N°'||V_I||' => Erreur : '||v_ch_pb, 1, 1000);
                   END IF;
                --COMMIT;

                /*// --------------------------------------------Insertion dans la table spécifique dka_ieomtl_system_items_tmp--------------------------------------//*/

                
                   INSERT INTO dka_ieomtl_system_items_tmp (
																categorie_principale,
																designation_cat_principale,
																categorie_secondaire_1,
																designation_cat_secondaire_1,
																categorie_secondaire_2,
																designation_cat_secondaire_2,
																categorie_secondaire_3,
																designation_cat_secondaire_3,
																categorie_secondaire_4,
																designation_cat_secondaire_4,
																categorie_secondaire_5,
																designation_cat_secondaire_5,
																code_article,
																description_article,
																code_eclass_n2,
																libelle_eclass_n2,
																code_eclass_n3,
																libelle_eclass_n3,
																code_eclass_n4,
																libelle_eclass_n4,
																code_compl_n1,
																designation_compl_n1,
																code_compl_n2,
																designation_compl_n2,
																code_compl_n3,
																designation_compl_n3,
																code_compl_n4,
																designation_compl_n4,
																code_compl_n5,
																designation_compl_n5,
																code_compl_n6,
																designation_compl_n6,
																code_compl_n7,
																designation_compl_n7,
																code_compl_n8,
																designation_compl_n8,
																code_compl_n9,
																designation_compl_n9,
																unite_de_mesure,
																statut_article,
																supp_rejet,
																creation_date,
																created_by,
																last_update_date,
																last_updated_by,
																statut,
																file_name,
																line_num
														    ) 
													 VALUES (
																TRIM(V_CATEGORIE_PRINCIPALE),
																TRIM(V_DESIGNATION_CAT_PRINCIPALE),
																TRIM(V_CATEGORIE_SECONDAIRE_1),
																TRIM(V_DESIGNATION_CAT_SECONDAIRE_1),
																TRIM(V_CATEGORIE_SECONDAIRE_2),
																TRIM(V_DESIGNATION_CAT_SECONDAIRE_2),
																TRIM(V_CATEGORIE_SECONDAIRE_3),
																TRIM(V_DESIGNATION_CAT_SECONDAIRE_3),
																TRIM(V_CATEGORIE_SECONDAIRE_4),
																TRIM(V_DESIGNATION_CAT_SECONDAIRE_4),
																TRIM(V_CATEGORIE_SECONDAIRE_5),
																TRIM(V_DESIGNATION_CAT_SECONDAIRE_5),
																TRIM(V_code_article),
																TRIM(v_description_article),
																TRIM(v_code_eclass_n2),
																TRIM(v_libelle_eclass_n2),
																TRIM(v_code_eclass_n3),
																TRIM(v_libelle_eclass_n3),
																TRIM(v_code_eclass_n4),
																TRIM(v_libelle_eclass_n4),
																TRIM(v_code_compl_n1),
																TRIM(v_designation_compl_n1),
																TRIM(v_code_compl_n2),
																TRIM(v_designation_compl_n2),
																TRIM(v_code_compl_n3),
																TRIM(v_designation_compl_n3),
																TRIM(v_code_compl_n4),
																TRIM(v_designation_compl_n4),
																TRIM(v_code_compl_n5),
																TRIM(v_designation_compl_n5),
																TRIM(v_code_compl_n6),
																TRIM(v_designation_compl_n6),
																TRIM(v_code_compl_n7),
																TRIM(v_designation_compl_n7),
																TRIM(v_code_compl_n8),
																TRIM(v_designation_compl_n8),
																TRIM(v_code_compl_n9),
																TRIM(v_designation_compl_n9),
																TRIM(v_unite_de_mesure),
																TRIM(v_statut_article),
																TRIM(v_supp_rejet),
																SYSDATE,
																VG_USER_ID,
																SYSDATE,
																VG_USER_ID,
																'NEW',
																V_FILE_NAME,
																V_I
															);

                    --COMMIT;
                END IF;

                V_OFFSET := V_OFFSET + V_LINE_LENGTH + 1;


            END LOOP;

     

            /*/------------vérification de l'unicité du code article dans le fichier------------/*/

            V_NB_ARTICLE_UNIQUE := dka_ieomtl_codartint_pkg.controle_unicite;

            IF V_NB_ARTICLE_UNIQUE > 0 THEN
                V_RESULT := 'PB_UNICITE_ARTICLE';
                pv_message_erreur := 'Impossible de traiter le fichier => Le fichier à charger ne doit contenir qu''un seul enregistrement par code article interne';
                    DELETE FROM DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP
                      WHERE
                        STATUT = 'NEW'
                        AND CREATED_BY = VG_USER_ID
                        AND TO_CHAR(CREATION_DATE,'DD/MM/RRRR') = TO_CHAR(SYSDATE,'DD/MM/RRRR');                   
                    COMMIT;
            ELSIF v_nb_ligne_err >0  THEN 
               V_RESULT := 'PB_LONGUEUR';
               pv_message_erreur := 'Impossible de traiter le fichier =>'||v_nb_ligne_err ||' ligne(s) en erreur : '||CHR(20)|| v_message_erreur;
             
                  DELETE FROM DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP
                     WHERE
                        STATUT = 'NEW'
                        AND CREATED_BY = VG_USER_ID
                        AND TO_CHAR(CREATION_DATE,'DD/MM/RRRR') = TO_CHAR(SYSDATE,'DD/MM/RRRR');

                    COMMIT;  
                           
            ELSE  --IF V_NB_ERR =0 AND  V_NB_ARTICLE_UNIQUE =0 THEN 


                V_RESULT := 'OK';
                
                COMMIT;  
                
            END IF;



        ELSE
            V_RESULT := 'PB_FILE';
            pv_message_erreur := 'Impossible de traiter le fichier => Problème lors de la lecture du fichier';
        END IF;

        pv_file_id := V_FILE_ID;


        return(V_RESULT);
    EXCEPTION
        WHEN OTHERS THEN
            return(sqlerrm || 'Impossible d''inserer des enregistrements dans la table temporaire');
    END chgt_file_cod_artint;

 	------------------------------------------------------------------------------------
	--  Nom           : controle_nbr_enreg_file
	--	Description		:	Procédure de contrôle du nombre d'enregistrements insérés

	--
	--  PARAMETRES    :
	--      
	--      
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    PROCEDURE controle_nbr_enreg_file (
        p_errbuf    OUT NOCOPY VARCHAR2,
        p_retcode   OUT NOCOPY NUMBER
    ) IS
        v_nb_enr   NUMBER;
    BEGIN
		-- calcul de nombre d'enregistrements dans la table temporaire DKA_IEOMTL_SYSTEM_ITEMS_TMP. --
        BEGIN
            SELECT
                COUNT(1)
            INTO v_nb_enr
            FROM
                dka_ieomtl_system_items_tmp;

        EXCEPTION
            WHEN no_data_found THEN
                v_nb_enr := 0;
        END;

        IF v_nb_enr = 0 THEN
            p_retcode := 2;
            p_errbuf := sqlerrm || 'ERREUR : Le fichier ne contient aucun enregistrement.';
        END IF;

    END controle_nbr_enreg_file;



 	------------------------------------------------------------------------------------
	--  Nom           : control_format_codes
	--	Description		:	Fonction de contrôle de format des enregistremets du fichier

	--
	--  PARAMETRES    :
	--      
	--      
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    FUNCTION control_format_codes (
        p_code IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_val   VARCHAR2(20);
    BEGIN
        BEGIN
            SELECT
                'OK'
            INTO v_val
            FROM
                dual
            WHERE
                p_code LIKE ( '__.__.__.__' );

            IF v_val != 'OK' THEN
                v_val := 'ER';
            END IF;    
        EXCEPTION
            WHEN no_data_found THEN
                v_val := 'ER';
        END;

        RETURN v_val;
    END control_format_codes;


 	------------------------------------------------------------------------------------
	--  Nom           : control_format_article
	--	Description		:	Fonction de contrôle de format du code article

	--
	--  PARAMETRES    :
	--      
	--      
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    FUNCTION control_format_article (
        p_code IN VARCHAR2
    ) RETURN VARCHAR2 IS
        v_nbre  NUMBER;
        v_str   VARCHAR2(50);
        v_val   VARCHAR2(20);
    BEGIN
        v_val := 'OK';
        
        BEGIN
            SELECT instr(p_code,'.',1,2)   -- On vérifie qu'il n'y a pas 2 . dans le code article
            INTO v_str
            FROM dual;   
            
            IF v_str != 0
            THEN             
                v_val := 'ER';
            ELSE
                BEGIN      
                     -- On vérifie qu'il y a bien un code après le premier .         
                     SELECT substr(p_code,decode(instr(p_code,'.',1,1),0,length(p_code),instr(p_code,'.',1,1) )  + 1, length(p_code)) 
                     INTO v_str
                     FROM dual;
                EXCEPTION   
                WHEN others THEN
                     v_val := 'ER';
                END;
                
                IF v_str IS NULL
                THEN
                    v_val := 'ER';
                END IF;    
            END IF;   
                   
        EXCEPTION
            WHEN others THEN
                v_val := 'ER';
        END;

        RETURN v_val;
    END control_format_article;

 	------------------------------------------------------------------------------------
	--  Nom           : controle_unicite
	--	Description		:	Fonction de contrôle d'unicité des enregistrements du fichier

	--
	--  PARAMETRES    :
	--      
	--      
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    FUNCTION controle_unicite RETURN NUMBER IS
        v_nb_articles   NUMBER;
    BEGIN
        SELECT
            COUNT(val)
        INTO v_nb_articles
        FROM
            (
                SELECT
                    code_article,
                    COUNT(*) val
                FROM
                    dka_ieomtl_system_items_tmp
                WHERE
                    statut = 'NEW'
                AND nvl(supp_rejet,'NON') != 'OUI'    
                GROUP BY
                    code_article
                HAVING
                    COUNT(code_article) > 1
            );

        IF v_nb_articles IS NULL THEN
            v_nb_articles := 0;
        END IF;
        RETURN v_nb_articles;
    END controle_unicite;



/**************************************************************************
 * PROCEDURE NAME : delete_old_error_records
 * 
 * DESCRIPTION
 *  Procédure de suppression des enregistrements en erreur pour lesquels l'utilisateur
 *  a demandé la suppression (Article à supprimer = OUI) 
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
.* ----------------- ------------------------------------------------------
 * pv_errbuf         Retour de message éventuel
 * pn_retcode        Statut du traitement en sortie
 *
 *************************************************************************/
  PROCEDURE delete_old_error_records (
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
        )
  IS
  


  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début delete_old_error_records');

        -- Initialisation des variables
        pv_errbuf  := NULL;
        pn_retcode := 0;


        -- Suppression des articles en erreur à purger des tables d'interface (Supprimer article à OUI)
                
        DELETE FROM MTL_SYSTEM_ITEMS_INTERFACE
        WHERE ( SEGMENT1|| '.'|| SEGMENT2 ) IN (SELECT CODE_ARTICLE
                                               FROM DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP
                                               WHERE STATUT = 'NEW'
                                               AND UPPER(SUPP_REJET) = 'OUI'
                                               );
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements old supprimés de MTL_SYSTEM_ITEMS_INTERFACE.');


        DELETE MTL_INTERFACE_ERRORS mse
        WHERE  mse.transaction_id NOT IN (SELECT transaction_id 
                                          FROM MTL_SYSTEM_ITEMS_INTERFACE msci)
        AND    mse.table_name = 'MTL_SYSTEM_ITEMS_INTERFACE'
        ;  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements old supprimés de MTL_INTERFACE_ERRORS.');

                                                       
        DELETE FROM MTL_ITEM_CATEGORIES_INTERFACE
        WHERE INVENTORY_ITEM_ID IN ( SELECT msi.INVENTORY_ITEM_ID
                                     FROM DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP  disi
                                         ,MTL_SYSTEM_ITEMS_B msi
                                     WHERE disi.CODE_ARTICLE = msi.SEGMENT1||'.'||msi.SEGMENT2
                                     AND msi.ORGANIZATION_ID = vg_org_id_principale 
                                     AND disi.STATUT = 'NEW'
                                     AND UPPER(disi.SUPP_REJET) = 'OUI'
                                     );
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements old supprimés de MTL_ITEM_CATEGORIES_INTERFACE.');

                                     
        -- Suppression des enregistrements obsolètes dans la table des erreurs de l'open interface
        DELETE MTL_INTERFACE_ERRORS mse
        WHERE  mse.transaction_id NOT IN (SELECT transaction_id 
                                          FROM MTL_ITEM_CATEGORIES_INTERFACE msci)
        AND    mse.table_name = 'MTL_ITEM_CATEGORIES_INTERFACE'
        ;  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements old supprimés de MTL_INTERFACE_ERRORS.');
                     

        DELETE FROM DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP  disi
        WHERE nvl(disi.CODE_ARTICLE,'*') IN (SELECT nvl(disi1.CODE_ARTICLE,'*')
                                             FROM DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP  disi1
                                             WHERE STATUT = 'NEW'
                                             AND UPPER(disi1.SUPP_REJET) = 'OUI')
        ;
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements old supprimés de DKA_IEOMTL_SYSTEM_ITEMS_TMP.');


        commit;
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin delete_old_error_records');
 
  EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'DELETE_OLD_ERROR_RECORDS : ' ||SQLERRM;
  END delete_old_error_records; 

/**************************************************************************
 * PROCEDURE NAME : Delete_obsolete_records
 * 
 * DESCRIPTION
 *  Procédure de suppression des enregistrements obsoletes en erreur
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
.* ----------------- ------------------------------------------------------
 * pv_errbuf         Retour de message éventuel
 * pn_retcode        Statut du traitement en sortie
 *
 *************************************************************************/
  PROCEDURE delete_obsolete_records (
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
        )
  IS
  
  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début delete_obsolete_records');

        -- Initialisation des variables
        pv_errbuf  := NULL;
        pn_retcode := 0;


        -- Suppression des enregistrements obsolètes - nouvelle mise à jour reçue
        DELETE dka_ieomtl_system_items_tmp disi
        WHERE  disi.statut != 'NEW'
        AND    disi.code_article IN (SELECT disi1.code_article
                                     FROM   dka_ieomtl_system_items_tmp disi1
                                     WHERE  disi1.statut = 'NEW' 
                                     );
                                                    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de dka_ieomtl_system_items_tmp.');


        -- Suppression des enregistrements dans la table d'open interface qui sont obsolètes - ne font plus parti des enregistrements en rejet car nouvel enregistrement reçu)
        DELETE MTL_SYSTEM_ITEMS_INTERFACE msii
        WHERE ( SEGMENT1|| '.'|| SEGMENT2 ) NOT IN (SELECT disi1.code_article
                                                    FROM   dka_ieomtl_system_items_tmp disi1
                                                    WHERE  disi1.statut != 'NEW' 
                                                    );        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de MTL_SYSTEM_ITEMS_INTERFACE.');

        -- Suppression des enregistrements obsolètes dans la table des erreurs de l'open interface
        DELETE MTL_INTERFACE_ERRORS mse
        WHERE  mse.transaction_id NOT IN (SELECT transaction_id 
                                          FROM MTL_SYSTEM_ITEMS_INTERFACE msci)
        AND    mse.table_name = 'MTL_SYSTEM_ITEMS_INTERFACE'
        ;  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de MTL_INTERFACE_ERRORS.');

        -- Suppression des enregistrements dans la table d'open interface qui sont obsolètes
        DELETE MTL_ITEM_CATEGORIES_INTERFACE msci
        WHERE  msci.INVENTORY_ITEM_ID NOT IN (SELECT disi1.INVENTORY_ITEM_ID
                                              FROM   dka_ieomtl_system_items_tmp disi1
                                              WHERE  disi1.statut != 'NEW')
        ;   
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de MTL_ITEM_CATEGORIES_INTERFACE.');

        -- Suppression des enregistrements obsolètes dans la table des erreurs de l'open interface
        DELETE MTL_INTERFACE_ERRORS mse
        WHERE  mse.transaction_id NOT IN (SELECT transaction_id 
                                          FROM MTL_ITEM_CATEGORIES_INTERFACE msci)
        AND    mse.table_name = 'MTL_ITEM_CATEGORIES_INTERFACE'
        ;  
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de MTL_INTERFACE_ERRORS.');

        -- Suppression des enregistrements obsolètes dans la table de la table des révisions
        DELETE FROM MTL_ITEM_REVISIONS_INTERFACE
        WHERE  INVENTORY_ITEM_ID NOT IN (SELECT disi1.INVENTORY_ITEM_ID
                                         FROM   dka_ieomtl_system_items_tmp disi1
                                         WHERE  disi1.statut != 'NEW');        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de MTL_ITEM_REVISIONS_INTERFACE.');


        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin delete_obsolete_records');
 
  EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'DELETE_OBSOLETE_RECORDS : ' ||SQLERRM;
  END delete_obsolete_records; 
 
 
 
 /**************************************************************************
 * PROCEDURE NAME : reinit_statut
 * 
 * DESCRIPTION
 *  Procédure de ré-initialisation des statuts pour recyclage des erreurs
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
.* ----------------- ------------------------------------------------------
 * pv_errbuf         Retour de message éventuel
 * pn_retcode        Statut du traitement en sortie
 *
 *************************************************************************/
  PROCEDURE reinit_statut (
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
        )
  IS

  BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début reinit_statut');

        -- Initialisation des variables
        pv_errbuf  := NULL;
        pn_retcode := 0;
 
        -- Repositionnement du statut dans la table spécifique
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'REINIT LOADED DATA'); 
        UPDATE dka_ieomtl_system_items_tmp
        SET    statut = DECODE(statut, 'REJECTED','NEW','INSERT_OI_P','VALIDATED','INSERT_OI_F','INSERT_OA_P',statut)
              ,last_update_date = SYSDATE
              ,last_updated_by = vg_user_id
        WHERE  statut != 'NEW'     
        ;
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements mis à jour dans dka_ieomtl_system_items_tmp.');

        -- Suppression des messages d'erreur       
        DELETE dka_ieomtl_error
        ;
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements supprimés de la table dka_ieomtl_error.');

        -- suppression des enregistremesnts dans la table d'OI pour retraitement des données
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DELETE DATA MTL_SYSTEM_ITEMS_INTERFACE IF STATUT = NEW ou VALIDATED ou INSERT_OA_P');
        DELETE MTL_SYSTEM_ITEMS_INTERFACE msii
        WHERE  (msii.SEGMENT1||'.'||msii.SEGMENT2) IN (SELECT code_article
                                                       FROM dka_ieomtl_system_items_tmp disi
                                                       WHERE statut in ('NEW', 'VALIDATED','INSERT_OA_P'));       
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements supprimés de la table MTL_SYSTEM_ITEMS_INTERFACE.');


        -- suppression des enregistrements dans la table des erreurs de l'OI
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'DELETE DATA MTL_INTERFACE_ERRORS');
        DELETE MTL_INTERFACE_ERRORS mse
        WHERE  mse.transaction_id NOT IN (SELECT transaction_id 
                                          FROM MTL_SYSTEM_ITEMS_INTERFACE msci)
        AND    mse.table_name = 'MTL_SYSTEM_ITEMS_INTERFACE';
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements supprimés de la table MTL_INTERFACE_ERRORS.');

        -- Suppression des affectations de catégories en erreur dans la table d'OI pour retraitement
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'DELETE DATA MTL_ITEM_CATEGORIES_INTERFACE IF STATUT = INSERT_OA');
        DELETE MTL_ITEM_CATEGORIES_INTERFACE msci
        WHERE  msci.INVENTORY_ITEM_ID IN (SELECT disi.INVENTORY_ITEM_ID
                                          FROM dka_ieomtl_system_items_tmp disi
                                          WHERE statut = 'INSERT_OA');     
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements supprimés de la table MTL_ITEM_CATEGORIES_INTERFACE.');

        -- Suppression des erreurs liées à l'OI des affectations de catégorie
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'DELETE DATA MTL_INTERFACE_ERRORS');
        DELETE MTL_INTERFACE_ERRORS mse
        WHERE  mse.transaction_id NOT IN (SELECT transaction_id 
                                          FROM MTL_ITEM_CATEGORIES_INTERFACE msci)
        AND    mse.table_name = 'MTL_ITEM_CATEGORIES_INTERFACE';
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements supprimés de la table MTL_INTERFACE_ERRORS.');
              

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements mis à jour dans MTL_SYSTEM_ITEMS_INTERFACE.');

        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin reinit_statut');
 
  EXCEPTION
  WHEN OTHERS
  THEN
            pn_retcode   := 2;
            pv_errbuf    := 'REINIT_STATUT : ' ||SQLERRM;
  END reinit_statut; 


 	------------------------------------------------------------------------------------
	--  Nom           : controle_donnees
	--	Description		:	Procédure de contrôle de cohérence des enregistrements du fichier

	--
	--  PARAMETRES    :
	--      
	--      
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    PROCEDURE controle_donnees (
        p_errbuf IN OUT VARCHAR2,
        p_retcode   OUT NUMBER
    ) IS

        v_flag_format                  VARCHAR2(5);
	    	V_FLAG_FORMAT_NUM              VARCHAR2(20);
        v_CATEGORIE_PRINCIPALE         VARCHAR2(1);
        v_error_categorie_principale   VARCHAR2(100);
        v_error_code_eclass_n4         VARCHAR2(100);
        v_error_libelle_eclass_n4      VARCHAR2(100);
        v_error_code_compl_n1          VARCHAR2(100);
        v_error_designation_compl_n1   VARCHAR2(100);
        v_error_code_article           VARCHAR2(100);
        v_error_description_article    VARCHAR2(100);
        v_error_unite_de_mesure        VARCHAR2(100);
        v_error2_unite_de_mesure       VARCHAR2(100);
        v_error_f_categ_principale     VARCHAR2(100);
        v_error_f_categ_secondaire1    VARCHAR2(100);
        v_error_f_categ_secondaire2    VARCHAR2(100);
        v_error_f_categ_secondaire3    VARCHAR2(100);
        v_error_f_categ_secondaire4    VARCHAR2(100);
        v_error_f_categ_secondaire5    VARCHAR2(100); 
        v_error_statut_article         VARCHAR2(100);
	    	v_error_N_code_eclass_n2	     VARCHAR2(100);
		    v_error_N_code_eclass_n3	     VARCHAR2(100);
		    v_error_N_code_eclass_n4	     VARCHAR2(100);
        v_status_article               dka_ieomtl_system_items_tmp.statut_article%TYPE;
        vn_Inventory_item_id           mtl_system_items_tl.inventory_item_id%TYPE;
        v_status_article_active        mtl_item_status.inventory_item_status_code_tl%TYPE;
        v_status_article_inactive      mtl_item_status.inventory_item_status_code_tl%TYPE;
        v_description_article          mtl_system_items_tl.description%TYPE;
        v_statut_article               mtl_item_status.inventory_item_status_code_tl%TYPE;
        v_default_unit_mesure          mtl_units_of_measure_tl.unit_of_measure%TYPE;
        vn1_inventory_item_id          mtl_system_items_tl.inventory_item_id%TYPE;
        l_inventory_item_id            mtl_system_items_tl.inventory_item_id%TYPE;
        v_error_categorie_sec1         VARCHAR2(200);
        v_error_categorie_sec2         VARCHAR2(200);
        v_error_categorie_sec3         VARCHAR2(200);
        v_error_categorie_sec4         VARCHAR2(200);
        v_error_categorie_sec5         VARCHAR2(200);
        v_uom_code                     VARCHAR2(20);
        V_NB_ERRor                     NUMBER := 0;
        v_flag_crea_maj_art            VARCHAR2(1);
        l_val_seg_compl_tech           VARCHAR2(40);
        v_error_concat_segs            VARCHAR2(200);
        v_error_format_art             VARCHAR2(200);        
        v_notexists                    NUMBER := 0;


        CURSOR cur_article_inter IS 
              SELECT  *
                FROM
                    dka_ieomtl_system_items_tmp
								WHERE  
									   request_id =VG_REQUEST_ID
                AND  statut IN ('NEW', 'REJECTED')     
                FOR UPDATE;

    BEGIN

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début controle_donnees');

           UPDATE dka_ieomtl_system_items_tmp
				   SET
					     request_id = VG_REQUEST_ID
              ,statut_article = nvl(statut_article,VG_STATUS_ACTIVE)
              ,last_updated_by = vg_user_id
              ,last_update_date = sysdate
           ;
				COMMIT;



        FOR c IN cur_article_inter LOOP
        
        V_NB_ERRor := 0;

	/*//--vérification que les champs obligatoires ne sont pas vides --//*/
            BEGIN
                IF c.categorie_principale IS NULL THEN
                    v_error_categorie_principale := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_002','XXXXX','CATEGORIE_PRINCIPALE');


                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												  ) 
										VALUES   (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_002',
													v_error_categorie_principale,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												 );

                    V_NB_ERRor := V_NB_ERRor + 1;
                    --COMMIT;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            BEGIN
                IF c.code_eclass_n4 IS NULL THEN
                    v_error_code_eclass_n4 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_002','XXXXX','CODE_ECLASS_N4');

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												 ) 
												 VALUES 
												 (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_002',
													v_error_code_eclass_n4,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            BEGIN
                IF c.libelle_eclass_n4 IS NULL THEN
                    v_error_libelle_eclass_n4 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_002','XXXXX','LIBELLE_ECLASS_N4');

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												 ) 
										VALUES   (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_002',
													v_error_libelle_eclass_n4,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												 );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            BEGIN
                IF c.code_compl_n1 IS NULL THEN
                    v_error_code_compl_n1 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_002','XXXXX','CODE_COMPL_N1');

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												 ) 
											VALUES 
											     (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_002',
													v_error_code_compl_n1,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												 );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            BEGIN
                IF c.designation_compl_n1 IS NULL THEN
                    v_error_designation_compl_n1 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_002','XXXXX','DESIGNATION_COMPL_N1');

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												 ) 
										VALUES   (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_002',
													v_error_designation_compl_n1,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												 );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            BEGIN
                IF c.code_article IS NULL THEN
                    v_error_code_article := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_002','XXXXX','CODE_ARTICLE');

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
                              ) 
										VALUES   (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_002',
													v_error_code_article,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
                              );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            BEGIN
                IF c.description_article IS NULL THEN
                    v_error_description_article := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_002','XXXXX','DESCRIPTION_ARTICLE');

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												 ) 
										VALUES   (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_002',
													v_error_description_article,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												 );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            BEGIN
                IF c.unite_de_mesure IS NULL THEN
                    v_error_unite_de_mesure := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_002','XXXXX','UNITE_DE_MESURE');

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												  )
										  VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_002',
													v_error_unite_de_mesure,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												 );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            /*//--vérification du format des catégories dans la table DKA_IEOMTL_SYSTEM_ITEMS_TMP --//*/

            v_flag_format := NULL;
            BEGIN
                SELECT
                    control_format_codes(c.categorie_principale)
                INTO v_flag_format
                FROM
                    dual;

                IF  c.categorie_principale IS NOT NULL AND  v_flag_format != 'OK'  THEN
                    v_error_f_categ_principale := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_007','CATEGORY','CATEGORIE_PRINCIPALE','CODE',c.categorie_principale);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												  ) 
											VALUES(
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_007',
													v_error_f_categ_principale,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												   );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            v_flag_format := NULL;
            BEGIN
                SELECT
                    control_format_codes(c.categorie_secondaire_1)
                INTO v_flag_format
                FROM
                    dual;

                IF c.categorie_secondaire_1 IS NOT NULL AND  v_flag_format = 'ER' 
                THEN
                    v_error_f_categ_secondaire1 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_007','CATEGORY','CATEGORIE_SECONDAIRE_1','CODE',c.categorie_secondaire_1);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												 ) 
										VALUES   (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_007',
													v_error_f_categ_secondaire1,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
                                );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            v_flag_format := NULL;
            BEGIN
                SELECT
                    control_format_codes(c.categorie_secondaire_2)
                INTO v_flag_format
                FROM
                    dual;

                IF c.categorie_secondaire_2 IS NOT NULL  AND v_flag_format = 'ER'  
                THEN
                    v_error_f_categ_secondaire2 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_007','CATEGORY','CATEGORIE_SECONDAIRE_2','CODE',c.categorie_secondaire_2);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												  ) 
											VALUES(
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_007',
													v_error_f_categ_secondaire2,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												   );

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            v_flag_format := NULL;
            BEGIN
                SELECT
                    control_format_codes(c.categorie_secondaire_3)
                INTO v_flag_format
                FROM
                    dual;

                IF c.categorie_secondaire_3 IS NOT NULL AND  v_flag_format = 'ER'   
                THEN
                    v_error_f_categ_secondaire3 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_007','CATEGORY','CATEGORIE_SECONDAIRE_3','CODE',c.categorie_secondaire_3);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES  (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_007',
													v_error_f_categ_secondaire3,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            v_flag_format := NULL;
            BEGIN
                SELECT
                    control_format_codes(c.categorie_secondaire_4)
                INTO v_flag_format
                FROM
                    dual;

                IF c.categorie_secondaire_4 IS NOT NULL AND v_flag_format = 'ER'   
                THEN
                    v_error_f_categ_secondaire4 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_007','CATEGORY','CATEGORIE_SECONDAIRE_4','CODE',c.categorie_secondaire_4);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_007',
													v_error_f_categ_secondaire4,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;

            v_flag_format := NULL;
            BEGIN
                SELECT
                    control_format_codes(c.categorie_secondaire_5)
                INTO v_flag_format
                FROM
                    dual;

                IF c.categorie_secondaire_5 IS NOT NULL  AND  v_flag_format = 'ER'   
                THEN
                    v_error_f_categ_secondaire5 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_007','CATEGORY','CATEGORIE_SECONDAIRE_5','CODE',c.categorie_secondaire_5);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_007',
													v_error_f_categ_secondaire5,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;
			
			/*//--vérification que les champs sont de format numérique seulement --//*/  ---SFA --- Ajouté le 07/02/2019 
			
			v_flag_format_num := NULL;
			
            BEGIN
                SELECT
                    check_code_isNumeric(c.code_eclass_n2)
                INTO v_flag_format_num
                FROM
                    dual;

                IF c.code_eclass_n2 IS NOT NULL  AND LENGTH(c.code_eclass_n2)=8 AND  v_flag_format_num = 'ER'   
                THEN
                    v_error_N_code_eclass_n2 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_019','CODE_ECLASS','CODE_ECLASS_N2','CODE',c.code_eclass_n2);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_019',
													v_error_N_code_eclass_n2,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;
			EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;
				
				
		v_flag_format_num := NULL;
		
            BEGIN
                SELECT
                    check_code_isNumeric(c.code_eclass_n3)
                INTO v_flag_format_num
                FROM
                    dual;

                IF c.code_eclass_n3 IS NOT NULL  AND LENGTH(c.code_eclass_n3)=8 AND  v_flag_format_num = 'ER'   
                THEN
                    v_error_N_code_eclass_n3 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_019','CODE_ECLASS','CODE_ECLASS_N3','CODE',c.code_eclass_n3);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_019',
													v_error_N_code_eclass_n3,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;	
			EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;
			
		v_flag_format_num := NULL;

            BEGIN
                SELECT
                    check_code_isNumeric(c.code_eclass_n4)
                INTO v_flag_format_num
                FROM
                    dual;

                IF c.code_eclass_n4 IS NOT NULL  AND LENGTH(c.code_eclass_n4)=8 AND  v_flag_format_num = 'ER'   
                THEN
                    v_error_N_code_eclass_n4 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_019','CODE_ECLASS','CODE_ECLASS_N4','CODE',c.code_eclass_n4);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_019',
													v_error_N_code_eclass_n4,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                    V_NB_ERRor := V_NB_ERRor + 1;
                END IF;
			EXCEPTION
                WHEN OTHERS THEN
                    p_retcode := 1;
                    p_errbuf := 'Erreur : ' || sqlerrm;
            END;	
				
				/*//--fin vérification que les champs sont de format numérique seulement --//*/ 

            /*//---control du statut d'article---//*/

            BEGIN
                SELECT
                    inventory_item_status_code_tl
                INTO v_status_article
                FROM
                    mtl_item_status
                WHERE
                    inventory_item_status_code = c.statut_article;

            EXCEPTION
                WHEN no_data_found THEN
                    v_error_statut_article := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_008','STATUT',c.statut_article);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,  
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												 ) 
										VALUES  (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_008',
													v_error_statut_article,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
                          c.code_article
												);
                   V_NB_ERRor := V_NB_ERRor + 1;     

            END;  


            /*/vérification du paramétrage de l'unité de mesure dans oracle/*/

            IF c.unite_de_mesure IS NOT NULL
            THEN
               BEGIN
                   SELECT
                       uom_code
                   INTO v_uom_code
                   FROM
                       mtl_units_of_measure_vl
                   WHERE
                       unit_of_measure = c.unite_de_mesure;

                --COMMIT;
               EXCEPTION
                 WHEN no_data_found THEN
                    V_NB_ERRor := V_NB_ERRor + 1;
                    v_error2_unite_de_mesure := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_004','XXXXX',c.unite_de_mesure);
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_004',
													v_error2_unite_de_mesure,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

               END;
            END IF;

 /*/----------------------vérification de l'existance des catégories dans oracle-----------------/*/

            IF  c.categorie_principale IS NOT NULL
            THEN
               BEGIN
                   SELECT
                       category_id
                   INTO VG_CATEGORY_PRINCIPALE_ID
                   FROM
                       mtl_categories_v
                   WHERE
                       structure_name = 'Catégorie Article PO'
                   AND category_concat_segs = c.categorie_principale;

               EXCEPTION
                WHEN no_data_found THEN
                    V_NB_ERRor := V_NB_ERRor + 1;
                    v_error_categorie_principale := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_003','TYPE','PRINCIPALE','XXXXX',c.categorie_principale);

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												)
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_003',
													v_error_categorie_principale,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);
               END;
            END IF;
            
            IF  c.categorie_secondaire_1 IS NOT NULL     -- Champ non obligatoire
            THEN
                BEGIN
                    SELECT
                        category_id
                    INTO VG_CATEGORY_SEC1_ID
                    FROM
                        mtl_categories_v
                    WHERE
                        structure_name = 'Catégorie Article PO'
                        AND category_concat_segs = c.categorie_secondaire_1;

                EXCEPTION
                WHEN no_data_found THEN
                    v_error_categorie_sec1 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_003','TYPE','SECONDAIRE 1','XXXXX',c.categorie_secondaire_1);

                    V_NB_ERRor := V_NB_ERRor + 1;

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										 VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_003',
													v_error_categorie_sec1,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);
                END;
            END IF;
                

            IF  c.categorie_secondaire_2 IS NOT NULL     -- Champ non obligatoire
            THEN 
                BEGIN
                    SELECT
                        category_id
                    INTO VG_CATEGORY_SEC2_ID
                    FROM
                        mtl_categories_v
                    WHERE
                        structure_name = 'Catégorie Article PO'
                        AND category_concat_segs = c.categorie_secondaire_2;

                EXCEPTION
                WHEN no_data_found THEN

                    v_error_categorie_sec2 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_003','TYPE','SECONDAIRE 2','XXXXX',c.categorie_secondaire_2);
                    V_NB_ERRor := V_NB_ERRor + 1;
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_003',
													v_error_categorie_sec2,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                END;
            END IF;    

            IF  c.categorie_secondaire_3 IS NOT NULL     -- Champ non obligatoire
            THEN 
                BEGIN
                    SELECT
                        category_id
                    INTO VG_CATEGORY_SEC3_ID
                    FROM
                        mtl_categories_v
                    WHERE
                        structure_name = 'Catégorie Article PO'
                        AND category_concat_segs = c.categorie_secondaire_3;

                EXCEPTION
                WHEN no_data_found THEN
                    v_error_categorie_sec3 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_003','TYPE','SECONDAIRE 3','XXXXX',c.categorie_secondaire_3);
                    V_NB_ERRor := V_NB_ERRor + 1;
                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_003',
													v_error_categorie_sec3,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);
                END;
            END IF;    

            IF  c.categorie_secondaire_4 IS NOT NULL     -- Champ non obligatoire
            THEN
                BEGIN
                    SELECT
                        category_id
                    INTO VG_CATEGORY_SEC4_ID
                    FROM
                        mtl_categories_v
                    WHERE
                        structure_name = 'Catégorie Article PO'
                        AND category_concat_segs = c.categorie_secondaire_4;

                EXCEPTION
                WHEN no_data_found 
                THEN

                    v_error_categorie_sec4 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_003','TYPE','SECONDAIRE 4','XXXXX',c.categorie_secondaire_4);

                    V_NB_ERRor := V_NB_ERRor + 1;

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_003',
													v_error_categorie_sec4,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                END;
            END IF;             


            IF  c.categorie_secondaire_5 IS NOT NULL     -- Champ non obligatoire
            THEN
                BEGIN
                   SELECT
                       category_id
                   INTO VG_CATEGORY_SEC5_ID
                   FROM
                       mtl_categories_v
                   WHERE
                       structure_name = 'Catégorie Article PO'
                       AND category_concat_segs = c.categorie_secondaire_5;

                EXCEPTION
                WHEN no_data_found THEN

                    v_error_categorie_sec5 := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_003','TYPE','SECONDAIRE 5','XXXXX',c.categorie_secondaire_5);

                    V_NB_ERRor := V_NB_ERRor + 1;

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_003',
													v_error_categorie_sec5,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                END;
            END IF;            


            ------------------------------------------------------------------------------------------------------------
            -- Contrôle que le complément technique est bien la concaténation des attributs compléments techniques    --
            ------------------------------------------------------------------------------------------------------------
            IF  c.code_article IS NOT NULL     
            THEN
                
                BEGIN
                   SELECT
                         substr(c.code_article,instr(c.code_article,'.',1) + 1)
                   INTO l_val_seg_compl_tech
                   FROM
                      dual;
                EXCEPTION
                WHEN OTHERS THEN
                    l_val_seg_compl_tech := NULL;
                END;
                
                IF l_val_seg_compl_tech != c.code_compl_n1||c.code_compl_n2||c.code_compl_n3||c.code_compl_n4||c.code_compl_n5||c.code_compl_n6||c.code_compl_n7||c.code_compl_n8||c.code_compl_n9  
                THEN                            
                
                    v_error_concat_segs := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_005');

                    V_NB_ERRor := V_NB_ERRor + 1;

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_005',
													v_error_concat_segs,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                END IF;
            END IF;  

            ------------------------------------------------------------------------------------------------------------
            -- Contrôle du format du code article                                                                     --
            ------------------------------------------------------------------------------------------------------------
            IF  c.code_article IS NOT NULL     
            THEN
                
                
                IF control_format_article(c.code_article) = 'ER'
                THEN                            
                
                    v_error_format_art := dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_006');

                    V_NB_ERRor := V_NB_ERRor + 1;

                    INSERT INTO dka_ieomtl_error (
													file_name,
													line_num,
													phase,
													code_error,
													description_error,
													flag_msg,
													creation_date,
													created_by,
													request_id,
													code_article
												) 
										VALUES (
													c.file_name,
													c.line_num,
													'VALIDATION_DONNEES',
													'DKA_IEOMTL_ITEM_006',
													v_error_format_art,
													'1',
													SYSDATE,
													VG_USER_ID,
													VG_REQUEST_ID,
													c.code_article
												);

                END IF;
            END IF; 


            ---------------------------------------------------------
            -- Contrôle de l'existence de l'article dans oracle  --
            ---------------------------------------------------------
		        ---------------------------------------------------------
            -- Recherche de l'identifiant de l'article dans Oracle --
            ---------------------------------------------------------

            BEGIN

                BEGIN
                    Vn_Inventory_item_id := get_inventory_item_id(c.code_article,VG_ORG_ID_PRINCIPALE);
                EXCEPTION
                    WHEN no_data_found THEN
                        Vn_Inventory_item_id := NULL;
                END;

                IF Vn_Inventory_item_id IS NOT NULL THEN
                    BEGIN
                        SELECT
                             inventory_item_status_code
                            ,description
                        INTO v_statut_article
                            ,v_description_article
                        FROM
                            mtl_system_items_b
                        WHERE
                            inventory_item_id = Vn_Inventory_item_id
                            AND organization_id = VG_ORG_ID_PRINCIPALE;

                    EXCEPTION
                        WHEN no_data_found THEN
                            v_statut_article := NULL;
                            v_description_article := NULL;
                    END;


                    IF v_description_article = c.description_article AND v_statut_article = c.statut_article 
                    THEN
                        
                        
                        SELECT count(1)
                        INTO   v_notexists
                        FROM   MTL_PARAMETERS mp,
                               PER_SECURITY_ORGANIZATIONS pso
                        WHERE  mp.organization_id = pso.organization_id
                        AND    mp.master_organization_id = VG_ORG_ID_PRINCIPALE
                        AND    pso.security_profile_id = VG_SECURITY_PROFILE_ID
                        AND    NOT EXISTS (SELECT 'x'
                                           FROM MTL_SYSTEM_ITEMS_B msi
                                           WHERE msi.organization_id = mp.organization_id
                                           AND   msi.inventory_item_id = Vn_Inventory_item_id
                                           );
                        
                        IF v_notexists != 0
                        THEN 
                            v_flag_crea_maj_art :=  '3';       --3 :aucune modif ou mise à jour de l'article mais manquant sur au moins une UO 
                        ELSE
                            v_flag_crea_maj_art :=  '0';       --0 :aucune modif ou mise à jour de l'article 
                        END IF;

                    ELSIF v_description_article != c.description_article 
                    THEN
                        v_flag_crea_maj_art :=  '2';    --2 pour mise à jour de l'article 


                    ELSIF v_statut_article != c.statut_article 
                    THEN
                        v_flag_crea_maj_art :=  '2';    --2 pour mise à jour de l'article 

                   --     COMMIT;
                    END IF;

                ELSE
                    v_flag_crea_maj_art :=  '1';    -- 1 pour nouvelle création de l'article 


            --        COMMIT;
                END IF;

             --   COMMIT;

	      			/*//--------Vérification dans les organizations filles-------- //*/



            END; -- Fin Contrôle de l'existence de l'article

            IF V_NB_ERRor != 0 
            THEN
                UPDATE dka_ieomtl_system_items_tmp
                SET
                    statut = 'REJECTED' 
                   ,inventory_item_id = Vn_Inventory_item_id 
                   ,last_update_date = SYSDATE
                   ,last_updated_by = vg_user_id                   
                WHERE CURRENT OF cur_article_inter;  

                vg_nb_art_rej_valid := vg_nb_art_rej_valid + 1;
            ELSIF v_flag_crea_maj_art = 0
            THEN
                -- Article déjà existant mais pas de changement à apporter
                UPDATE dka_ieomtl_system_items_tmp
                SET
                    statut = 'INSERT_OA'
                   ,flag_crea_maj_art = v_flag_crea_maj_art 
                   ,inventory_item_id = Vn_Inventory_item_id
                   ,uom_code = v_uom_code
                   ,last_update_date = SYSDATE
                   ,last_updated_by = vg_user_id                     
                WHERE CURRENT OF cur_article_inter;  
                
                vg_nb_art_val_valid := vg_nb_art_val_valid + 1;

            ELSIF v_flag_crea_maj_art = 3
            THEN
                -- Article déjà existant mais pas de changement à apporter sur l'organisation principale
                UPDATE dka_ieomtl_system_items_tmp
                SET
                    statut = 'INSERT_OA_P'
                   ,flag_crea_maj_art = v_flag_crea_maj_art 
                   ,inventory_item_id = Vn_Inventory_item_id
                   ,uom_code = v_uom_code
                   ,last_update_date = SYSDATE
                   ,last_updated_by = vg_user_id                     
                WHERE CURRENT OF cur_article_inter;  
                
                vg_nb_art_val_valid := vg_nb_art_val_valid + 1;
            
            ELSE   
                -- Article validé pour import dans l'OI        
                UPDATE dka_ieomtl_system_items_tmp
                SET
                     statut = 'VALIDATED'
                    ,flag_crea_maj_art = v_flag_crea_maj_art 
                    ,inventory_item_id = Vn_Inventory_item_id
                    ,uom_code = v_uom_code
                    ,last_update_date = SYSDATE
                    ,last_updated_by = vg_user_id                      
                WHERE CURRENT OF cur_article_inter;  
                
                vg_nb_art_val_valid := vg_nb_art_val_valid + 1;

            END IF;        
        END LOOP;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||vg_nb_art_rej_valid||' enregistrements rejetés dans dka_ieomtl_system_items_tmp'); 
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||vg_nb_art_val_valid||' enregistrements insérés dans dka_ieomtl_system_items_tmp'); 



        COMMIT;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin controle_donnees');
        
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'CONTROLE_DONNEES : ' ||SQLERRM;        
    END controle_donnees; -----fin contrôle de données



 	------------------------------------------------------------------------------------
	--  Nom           : init
	--	Description		:	procédure de Récupération et control des variables paramètrées

	--
	--  PARAMETRES    :
	--      
	--      
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    PROCEDURE init(
        pv_errbuf    OUT      VARCHAR2,
        pn_retcode   OUT      NUMBER
        ) 
      IS

        PRAGMA autonomous_transaction;
        l_status_article               dka_ieomtl_system_items_tmp.statut_article%TYPE;
        V_Inventory_item_id            mtl_system_items_tl.inventory_item_id%TYPE;
        vn1_inventory_item_id          mtl_system_items_tl.inventory_item_id%TYPE;
        l_status_article_active        mtl_item_status.inventory_item_status_code_tl%TYPE;
        l_status_article_inactive      mtl_item_status.inventory_item_status_code_tl%TYPE;
        l_descrption_article           mtl_system_items_tl.description%TYPE;
        v_statut_article               mtl_item_status.inventory_item_status_code_tl%TYPE;
        l_default_unit_mesure          mtl_units_of_measure_tl.uom_code%TYPE;
        l_uom_code                     mtl_units_of_measure_tl.uom_code%TYPE;
        l_error_unite_de_mesure        VARCHAR2(200);
        l_error_categorie_principale   VARCHAR2(200);
        l_error_categorie_sec1         VARCHAR2(200);
        l_error_categorie_sec2         VARCHAR2(200);
        l_error_categorie_sec3         VARCHAR2(200);
        l_error_categorie_sec4         VARCHAR2(200);
        l_error_categorie_sec5         VARCHAR2(200);
        l_error_org_principale         VARCHAR2(200);
        l_exist_item                   VARCHAR2(1);
        l_inventory_item_id            NUMBER;


    BEGIN
        l_inventory_item_id := NULL;
        
        --Appel à la procédure commune d'initialisation de l'état de sortie
        Dka_Tools_Pkg.put_out_header;
  -----------------------------------------------------------
        -- vérification du paramétrage de principaux champs --
  -----------------------------------------------------------

			/*//--Récupération de l'organisation principale --//*/

        BEGIN
            SELECT
                mp.master_organization_id
            INTO VG_ORG_ID_PRINCIPALE
            FROM
                mtl_parameters mp,
                hr_all_organization_units hou
            WHERE
                mp.organization_id = hou.organization_id
                AND hou.name = 'DKA_MASTER';

        EXCEPTION
            WHEN OTHERS THEN


                vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_001'));
                pn_retcode := 2;
        END;

		 /*//---Récupération du profile de sécurité DKA_TOUT---//*/

        BEGIN
            SELECT
                security_profile_id
            INTO VG_SECURITY_PROFILE_ID
            FROM
                per_security_profiles
            WHERE
                security_profile_name = 'DKA_TOUT';

        EXCEPTION
            WHEN OTHERS THEN

                vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_011'));
                pn_retcode := 2;

        END;


          /*//---récupération du statut article par défaut---//*/

        BEGIN
            VG_STATUS_ACTIVE := fnd_profile.value('INV_STATUS_DEFAULT');
        EXCEPTION
            WHEN OTHERS THEN

                 vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_015'));
                 pn_retcode := 2;

        END;

        /*//---Récupération de la matrice DKA_ARTICLE---//*/

        BEGIN
            SELECT
                template_id
            INTO VG_TEMPLATE_ID
            FROM
                mtl_item_templates
            WHERE
                template_name = 'DKA_ARTICLE';

        EXCEPTION
            WHEN OTHERS THEN

                  vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_010'));
                  pn_retcode := 2;
        END;

		 /*//---Récupération du jeu de catégorie ACHATS---//*/

        BEGIN
            SELECT
                mcs.category_set_id,
                mcs.structure_id
            INTO
                VG_ITEM_CATEGORY_SET_ID1,
                VG_STRUCTURE_ID1
            FROM
                mtl_category_sets mcs
            WHERE
                mcs.category_set_name = 'ACHATS';

        EXCEPTION
            WHEN OTHERS THEN

                vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_009'));
                pn_retcode := 2;

        END;

          /*//---Récupération du catégorie par défaut d'ACHATS---//*/

        BEGIN
            SELECT
                mcs.DEFAULT_CATEGORY_ID
            INTO
                VG_default_category_id
            FROM
                mtl_category_sets mcs
            WHERE
                mcs.category_set_name = 'ACHATS';

        EXCEPTION
            WHEN OTHERS THEN
                vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_014'));
                pn_retcode := 2;


        END;

		  /*//---Récupération du jeu de catégorie ACHATS2---//*/

        BEGIN
            SELECT
                mcs.category_set_id,
                mcs.structure_id
            INTO
                VG_ITEM_CATEGORY_SET_ID2,
                VG_STRUCTURE_ID2
            FROM
                mtl_category_sets mcs
            WHERE
                mcs.category_set_name = 'ACHATS2';

        EXCEPTION
            WHEN OTHERS THEN

                 vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_018'));
                pn_retcode := 2;

        END;

         /*//---Récupération du statut actif---//*/

        BEGIN
            SELECT
                inventory_item_status_code_tl
            INTO l_status_article_active
            FROM
                mtl_item_status
            WHERE
                inventory_item_status_code = 'Active';

        EXCEPTION
            WHEN OTHERS THEN

                vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_012'));
                pn_retcode := 2;

        END;

		  /*//---Récupération du statut Inactif---//*/

        BEGIN
            SELECT
                inventory_item_status_code_tl
            INTO l_status_article_inactive
            FROM
                mtl_item_status
            WHERE
                inventory_item_status_code = 'Inactive';

        EXCEPTION
            WHEN OTHERS THEN

                vg_val_erreur :=vg_val_erreur || chr(10)||(dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_016'));
                pn_retcode := 2;

        END;

        /*//---Récupération du jeu de valeurs DKA_ARTICLE_ECLASS---//*/
        BEGIN
            SELECT
                flex_value_set_id
            INTO vg_flex_value_set_id_eclass
            FROM
                fnd_flex_value_sets ffvs
            WHERE
                ffvs.flex_value_set_name = 'DKA_ARTICLE_ECLASS';

        EXCEPTION
            WHEN OTHERS THEN

                vg_val_erreur :=vg_val_erreur || chr(10)|| (dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_013'));
                pn_retcode := 2;

        END;

        /*//---Récupération du jeu de valeurs DKA_ARTICLE_COMPL_TECH_ALL---//*/
        BEGIN
            SELECT
                flex_value_set_id
            INTO vg_flex_value_set_id_tech
            FROM
                fnd_flex_value_sets ffvs
            WHERE
                ffvs.flex_value_set_name = 'DKA_ARTICLE_COMPL_TECH_ALL';

        EXCEPTION
            WHEN OTHERS THEN

                vg_val_erreur :=vg_val_erreur || chr(10)|| (dka_tools_pkg.get_message('DKA','DKA_IEOMTL_ITEM_017'));
                pn_retcode := 2;

        END;

        /*//---Récupération du nombre de lignes à inserer par lot ---//*/

        BEGIN
                SELECT
                    NUMBER_VALUE
                INTO VG_NBLIGNES_LOT
                FROM
                    DKA_PARAMETERS
                WHERE
                    PROGRAM_CODE = 'DKA_IEOMTL_NBL'
                    AND PARAMETER_NAME = 'NBRE_LIGNES_LOT';

        EXCEPTION
            WHEN OTHERS THEN
                VG_NBLIGNES_LOT   := 0;
        END;

        /*//---Récupération du paramètre calcul stats ---//*/ -- 2 = Pas de calcul, 1 = Calcul des stats

        BEGIN
                SELECT
                    NUMBER_VALUE
                INTO VG_CALC_STATS
                FROM
                    DKA_PARAMETERS
                WHERE
                    PROGRAM_CODE = 'DKA_IEOMTL_NBL'
                    AND PARAMETER_NAME = 'CALCUL_STATS';

        EXCEPTION
            WHEN OTHERS THEN
                VG_CALC_STATS   := 0;
        END;

       IF  pn_retcode =2 THEN
           vg_val1:='-------------------------------------------------ERREUR DE PARAMETRAGE--------------------------------------------';
           pv_errbuf :=vg_val1 ||chr(10)||vg_val_erreur;      
      END IF;

        -- Comptage de données dans la table spécifique avant traitement
        SELECT count(*)
        INTO   vg_nb_art_renouv_charge
        FROM   dka_ieomtl_system_items_tmp
        WHERE  statut = 'NEW';

        SELECT count(*)
        INTO   vg_nb_art_recycle
        FROM   dka_ieomtl_system_items_tmp
        WHERE  statut != 'NEW' AND statut != 'COMPLETE';
    

  EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'INIT : ' ||SQLERRM;

    END init;	

 /* ************************************************************************* 
 * PROCEDURE NAME : Delete_complete_records
 * 
 * DESCRIPTION
 *  Procédure de suppression des enregistrements traités
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
.* ----------------- ------------------------------------------------------
 * pv_errbuf         Retour de message éventuel
 * pn_retcode        Statut du traitement en sortie
 *
 ************************************************************************ */

    PROCEDURE delete_complete_records (
        p_errbuf    OUT VARCHAR2,
        p_retcode   OUT NUMBER
    ) IS
    BEGIN
        fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Début delete_complete_records');

        -- Initialisation des variables

        p_errbuf := NULL;
        p_retcode := 0;

        -- Suppression des warnings liés à des enregistrements OK
        DELETE FROM dka_ieomtl_error die
        WHERE
            EXISTS (
                SELECT
                    disi.code_article
                FROM
                    dka_ieomtl_system_items_tmp disi
                WHERE
                    disi.statut = 'COMPLETE'
                AND disi.line_num = die.line_num
                AND disi.code_article = die.code_article
                AND disi.file_name = die.file_name                    
            );

        -- Suppression des enregistrements traités complètement  

        DELETE dka_ieomtl_system_items_tmp
        WHERE
            statut = 'COMPLETE';

        fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || SQL%rowcount
                                         || ' Enregistrements supprimés de DKA_IEOMTL_SYSTEM_ITEMS_TMP.');

        fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Fin delete_complete_records');

    EXCEPTION
        WHEN no_data_found THEN
            NULL;
        WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf := 'DELETE_COMPLETE_RECORDS : ' || sqlerrm;
    END delete_complete_records; 

/* *************************************************************************
 * FUNCTION NAME : Get_inventory_item_id
 *
 * DESCRIPTION
 *  Fonction pour récupérer l'identifiant de l'article
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
 * ----------------------- -------------------------------------------------

 * RETURN
 * ======
 * Identifiant de l'article   NUMBER
 *
 *************************************************************************/

    FUNCTION get_inventory_item_id (
        p_segment           IN VARCHAR2,
        p_organization_id   IN NUMBER
    ) RETURN NUMBER
    IS
        V_Inventory_item_id   NUMBER;
    BEGIN
        -- Recherche de l'identifiant de l'article      
        BEGIN
            SELECT DISTINCT
                msi.inventory_item_id
            INTO V_Inventory_item_id
            FROM
                mtl_system_items_b msi
            WHERE
                ( msi.segment1
                  || '.'
                  || msi.segment2 ) = p_segment
                AND msi.organization_id = p_organization_id;

        EXCEPTION
            WHEN no_data_found THEN
                V_Inventory_item_id := NULL;
        END;

        return(V_Inventory_item_id);
    END get_inventory_item_id;

/* *************************************************************************
 * FUNCTION NAME : get_category_id
 *
 * DESCRIPTION
 *  Fonction pour récupérer l'identifiant de la catégorie
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
/* ----------------------- -------------------------------------------------

 * RETURN
 * ======
 * Identifiant de la catégorie   NUMBER
 *
 *************************************************************************/

   FUNCTION get_category_id (
        p_structure_id       IN NUMBER,
        p_category            IN VARCHAR2
    ) RETURN NUMBER
    IS
        v_category_id   VARCHAR2(30);
    BEGIN
        -- Recherche de la catégorie achat affectée à  l'article      
        BEGIN

            SELECT mc.CATEGORY_ID
            INTO   v_category_id
            FROM
                 mtl_categories mc
            WHERE
				    	    mc.structure_id = p_structure_id           
              AND (mc.SEGMENT1||'.'||mc.SEGMENT2||'.'||mc.SEGMENT3||'.'||mc.SEGMENT4) = p_category;
        EXCEPTION
            WHEN no_data_found THEN
                v_category_id := null;
        END;

        RETURN  v_category_id;
    END get_category_id;  



 /* *************************************************************************
 * FUNCTION NAME : Get_item_category
 *
 * DESCRIPTION
 *  Fonction pour récupérer la catégorie d'achat d'un article
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
.* ----------------------- -------------------------------------------------
 * pn_inventory_item_id    Id de l'article
 *  
 * RETURN
 * ======
 * categorie d'achat       VARCHAR2
 *
 *************************************************************************/

    FUNCTION get_item_category (
        p_inventory_item_id IN NUMBER,
        p_item_category_set_id   IN NUMBER,
        p_structure_id       IN NUMBER
    ) RETURN VARCHAR2 IS
        vv_category   VARCHAR2(30);
    BEGIN
        -- Recherche de la catégorie achat de l'article      
        BEGIN

            SELECT  
               DISTINCT 
               mc.SEGMENT1||'.'||mc.SEGMENT2||'.'||mc.SEGMENT3||'.'||mc.SEGMENT4 
            INTO   vv_category
            FROM
                mtl_item_categories mic,
                mtl_categories mc
            WHERE
                    mic.category_id = mc.category_id
			       		AND mic.inventory_item_id = p_inventory_item_id
				      	AND mc.structure_id = p_structure_id
                AND mic.CATEGORY_SET_ID =p_item_category_set_id
                AND mic.organization_id = vg_org_id_principale;                

        EXCEPTION
            WHEN no_data_found THEN
                vv_category := null;
        END;

        RETURN  vv_category;
    END get_item_category;  

 /* *************************************************************************
 * FUNCTION NAME : Get_item_category_sec
 *
 * DESCRIPTION
 *  Fonction pour récupérer une catégorie secondaire d'un article
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
.* ----------------------- -------------------------------------------------
 * pn_inventory_item_id    Id de l'article
 *  
 * RETURN
 * ======
 * categorie d'achat       VARCHAR2
 *
 *************************************************************************/
    FUNCTION get_item_category_sec (
        p_inventory_item_id IN NUMBER,
        p_item_category_set_id   IN NUMBER,
        p_structure_id       IN NUMBER,
        p_category        IN VARCHAR2
    ) RETURN NUMBER IS
        vv_category_id   VARCHAR2(30);
    BEGIN
        -- Recherche de la catégorie achat de l'article      
        BEGIN

            SELECT  
               DISTINCT 
               mic.category_id 
            INTO   vv_category_id
            FROM
                mtl_item_categories mic,
                mtl_categories mc
            WHERE
                    mic.category_id = mc.category_id
					  AND mic.inventory_item_id = p_inventory_item_id
					  AND mc.structure_id = p_structure_id
            AND mic.CATEGORY_SET_ID =p_item_category_set_id
            AND (mc.SEGMENT1||'.'||mc.SEGMENT2||'.'||mc.SEGMENT3||'.'||mc.SEGMENT4)=p_category;                

        EXCEPTION
            WHEN no_data_found THEN
                vv_category_id := null;
        END;

        RETURN  vv_category_id;
    END get_item_category_sec;


 /* *************************************************************************
 * PROCEDURE NAME : insert_assign_category_item
 *
 * DESCRIPTION
 *  Procédure pour insérer les catégories dans la table d'OI
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
.* ----------------------- -------------------------------------------------
 * pn_inventory_item_id    Id de l'article
 *  
 * RETURN
 * ======
 * categorie d'achat       VARCHAR2
 *
 *************************************************************************/

    PROCEDURE insert_assign_category_item (
        p_errbuf    OUT VARCHAR2,
        p_retcode   OUT NUMBER
    ) 
    IS 
        V_OLD_CATEGORIE_PRINCIPALE  varchar2(200);
        V_OLD_CATEGORIE_PRINCIPALE_ID   mtl_categories_b.category_id%TYPE;
        V_NEW_CATEGORIE_PRINCIPALE_ID   mtl_categories_b.category_id%TYPE;
        V_CATEGORIE_SECONDAIRE_1_ID   mtl_categories_b.category_id%TYPE;
        V_CATEGORIE_SECONDAIRE_2_ID   mtl_categories_b.category_id%TYPE;
        V_CATEGORIE_SECONDAIRE_3_ID   mtl_categories_b.category_id%TYPE;
        V_CATEGORIE_SECONDAIRE_4_ID   mtl_categories_b.category_id%TYPE;
        V_CATEGORIE_SECONDAIRE_5_ID   mtl_categories_b.category_id%TYPE;
        V_CATEGORIE_SECONDAIRE_1       varchar2(200);
        V_CATEGORIE_SECONDAIRE_2       varchar2(200);
        V_CATEGORIE_SECONDAIRE_3       varchar2(200);
        V_CATEGORIE_SECONDAIRE_4       varchar2(200);
        V_CATEGORIE_SECONDAIRE_5       varchar2(200);
        v_set_process_id       NUMBER;
        v1_set_process_id       NUMBER;
        v2_set_process_id       NUMBER;
        v3_set_process_id       NUMBER;
        v4_set_process_id       NUMBER;
        v5_set_process_id       NUMBER;
        v6_set_process_id       NUMBER;
        v_nb_enreg_insert       NUMBER := 0;
 
        CURSOR cur_items IS 
              SELECT
                   INVENTORY_ITEM_ID,
                   STATUT,
                   CATEGORIE_PRINCIPALE,
                   DESIGNATION_CAT_PRINCIPALE,
                   CATEGORIE_SECONDAIRE_1,
                   DESIGNATION_CAT_SECONDAIRE_1,
                   CATEGORIE_SECONDAIRE_2,
                   DESIGNATION_CAT_SECONDAIRE_2,
                   CATEGORIE_SECONDAIRE_3,
                   DESIGNATION_CAT_SECONDAIRE_3,
                   CATEGORIE_SECONDAIRE_4,
                   DESIGNATION_CAT_SECONDAIRE_4,
                   CATEGORIE_SECONDAIRE_5,
                   DESIGNATION_CAT_SECONDAIRE_5,
                   REQUEST_ID,
                   LINE_NUM,
                   FILE_NAME,
                   CODE_ARTICLE,
                   DESCRIPTION_ARTICLE,
                   FLAG_CREA_MAJ_ART  ---ajouté dernier
                FROM
                   DKA_IEOMTL_SYSTEM_ITEMS_TMP
                WHERE statut='INSERT_OA'
                AND request_id=VG_REQUEST_ID
                FOR UPDATE;  

        CURSOR cur_cat_item_suppr (p_inventory_item_id NUMBER) IS 
              SELECT mic.inventory_item_id
                   , mc.category_id
                   , mc.concatenated_segments
              FROM  mtl_item_categories mic,
                    mtl_categories_kfv mc  
              WHERE mic.category_id = mc.category_id
              AND   mic.inventory_item_id = p_inventory_item_id
              AND   mic.category_set_id = VG_ITEM_CATEGORY_SET_ID2
              AND   mic.organization_id = VG_ORG_ID_PRINCIPALE
              AND  NOT EXISTS (SELECT 'x' 
                               FROM DKA_IEOMTL_SYSTEM_ITEMS_TMP disi
                               WHERE disi.inventory_item_id = mic.inventory_item_id
                               AND (disi.CATEGORIE_SECONDAIRE_1 = mc.concatenated_segments
                                    OR  disi.CATEGORIE_SECONDAIRE_2 = mc.concatenated_segments
                                    OR  disi.CATEGORIE_SECONDAIRE_3 = mc.concatenated_segments
                                    OR  disi.CATEGORIE_SECONDAIRE_4 = mc.concatenated_segments
                                    OR  disi.CATEGORIE_SECONDAIRE_5 = mc.concatenated_segments
                                    )
                               )     
               ;    
         rec_cat_item_suppr             cur_cat_item_suppr%ROWTYPE;
                         
    BEGIN

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début insert_assign_category_item');

        SELECT
            mtl_system_items_intf_sets_s.NEXTVAL
        INTO v_set_process_id
        FROM
            dual;

        SELECT
            mtl_system_items_intf_sets_s.NEXTVAL
        INTO v1_set_process_id
        FROM
            dual; 

        SELECT
            mtl_system_items_intf_sets_s.NEXTVAL
        INTO v2_set_process_id
        FROM
            dual;  

        SELECT
            mtl_system_items_intf_sets_s.NEXTVAL
        INTO v3_set_process_id
        FROM
            dual;  

        SELECT
            mtl_system_items_intf_sets_s.NEXTVAL
        INTO v4_set_process_id
        FROM
            dual;


        SELECT
            mtl_system_items_intf_sets_s.NEXTVAL
        INTO v5_set_process_id
        FROM
            dual;



        FOR c IN cur_items LOOP

           -- Mise à jour de la catégorie principale
            V_OLD_CATEGORIE_PRINCIPALE := GET_ITEM_CATEGORY(c.INVENTORY_ITEM_ID,VG_ITEM_CATEGORY_SET_ID1,VG_STRUCTURE_ID1);
            V_OLD_CATEGORIE_PRINCIPALE_ID := get_category_id (VG_STRUCTURE_ID1,V_OLD_CATEGORIE_PRINCIPALE);
            V_NEW_CATEGORIE_PRINCIPALE_ID := get_category_id (VG_STRUCTURE_ID1,c.CATEGORIE_PRINCIPALE);                                           

         
           IF V_OLD_CATEGORIE_PRINCIPALE  IS NOT NULL AND V_OLD_CATEGORIE_PRINCIPALE !=c.CATEGORIE_PRINCIPALE 
           THEN 

              INSERT INTO mtl_item_categories_interface
                      (inventory_item_id
                      ,category_set_id
                      ,category_id
                      ,last_update_date
                      ,last_updated_by
                      ,creation_date
                      ,created_by
                      ,last_update_login
                      ,organization_id
                      ,process_flag
                      ,transaction_type
                      ,old_category_id
                      ,set_process_id
                      )
                VALUES
                      (c.inventory_item_id --inventory_item_id
                      ,  VG_ITEM_CATEGORY_SET_ID1 --category_set_id
                      , V_NEW_CATEGORIE_PRINCIPALE_ID --category_id
                      , SYSDATE --last_update_date
                      , fnd_global.user_id --last_updated_by
                      , SYSDATE --creation_date
                      , fnd_global.user_id --created_by
                      , fnd_global.login_id --last_update_login
                      , VG_ORG_ID_PRINCIPALE --organization_id
                      , 1 --process_flag à Pending
                      , 'UPDATE' --transaction_type
                      , V_OLD_CATEGORIE_PRINCIPALE_ID --old_category_id
                      , v_set_process_id
                      ); 
                      
               v_nb_enreg_insert := v_nb_enreg_insert + 1;

          END IF;  


        /*//------------------------ categories secondaires ------------------------------------//*/

                
       -- Supprimer toutes les catégories secondaires de l'article qui ne sont plus présentes dans le fichier
        OPEN cur_cat_item_suppr(c.inventory_item_id);
        LOOP
            FETCH cur_cat_item_suppr INTO rec_cat_item_suppr;
            EXIT WHEN cur_cat_item_suppr%NOTFOUND;

             DELETE mtl_item_categories
             WHERE  inventory_item_id = rec_cat_item_suppr.inventory_item_id
             AND    category_id = rec_cat_item_suppr.category_id
             AND    category_set_id = VG_ITEM_CATEGORY_SET_ID2  
             ;


        END LOOP;
        CLOSE cur_cat_item_suppr;
        

        -- Insertion des nouvelles catégories
        /*//-----catégorie secondaire 1---------------//*/

        
        IF c.CATEGORIE_SECONDAIRE_1 IS NOT NULL
        THEN 
            V_CATEGORIE_SECONDAIRE_1_ID := get_item_category_sec(c.INVENTORY_ITEM_ID,VG_ITEM_CATEGORY_SET_ID2,VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_1);


            IF V_CATEGORIE_SECONDAIRE_1_ID IS NULL 
            THEN

                V_CATEGORIE_SECONDAIRE_1_ID:=DKA_IEOMTL_CODARTINT_PKG.get_category_id(VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_1);        

                INSERT INTO mtl_item_categories_interface
                          (inventory_item_id
                          ,category_set_id
                          ,category_id
                          ,last_update_date
                          ,last_updated_by
                          ,creation_date
                          ,created_by
                          ,last_update_login
                          ,organization_id
                          ,process_flag
                          ,transaction_type
                          ,set_process_id
                          )
                    VALUES
                          (c.inventory_item_id --inventory_item_id
                          ,  VG_ITEM_CATEGORY_SET_ID2 --category_set_id
                          , V_CATEGORIE_SECONDAIRE_1_ID --category_id
                          , SYSDATE --last_update_date
                          , fnd_global.user_id --last_updated_by
                          , SYSDATE --creation_date
                          , fnd_global.user_id --created_by
                          , fnd_global.login_id --last_update_login
                          , VG_ORG_ID_PRINCIPALE --organization_id
                          , 1 --process_flag à Pending
                          , 'CREATE' --transaction_type
                          , v1_set_process_id
                          );
                 v_nb_enreg_insert := v_nb_enreg_insert + 1;         
            END IF;
        END IF;
 
         ----------------catégorie secondaire 2---------------

        IF c.CATEGORIE_SECONDAIRE_2 IS NOT NULL
        THEN
            V_CATEGORIE_SECONDAIRE_2_ID := get_item_category_sec(c.INVENTORY_ITEM_ID,VG_ITEM_CATEGORY_SET_ID2,VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_2);
     
            IF V_CATEGORIE_SECONDAIRE_2_ID IS NULL 
            THEN

                V_CATEGORIE_SECONDAIRE_2_ID:=DKA_IEOMTL_CODARTINT_PKG.get_category_id(VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_2);        

                INSERT INTO mtl_item_categories_interface
                          (inventory_item_id
                          ,category_set_id
                          ,category_id
                          ,last_update_date
                          ,last_updated_by
                          ,creation_date
                          ,created_by
                          ,last_update_login
                          ,organization_id
                          ,process_flag
                          ,transaction_type
                          ,set_process_id
                          )
                    VALUES
                          (c.inventory_item_id --inventory_item_id
                          ,  VG_ITEM_CATEGORY_SET_ID2 --category_set_id
                          , V_CATEGORIE_SECONDAIRE_2_ID --category_id
                          , SYSDATE --last_update_date
                          , fnd_global.user_id --last_updated_by
                          , SYSDATE --creation_date
                          , fnd_global.user_id --created_by
                          , fnd_global.login_id --last_update_login
                          , VG_ORG_ID_PRINCIPALE --organization_id
                          , 1 --process_flag à Pending
                          , 'CREATE' --transaction_type
                          , v2_set_process_id
                          );
                  v_nb_enreg_insert := v_nb_enreg_insert + 1;        
                          
             END IF;
        END IF;

        ----------------catégorie secondaire 3---------------


        IF c.CATEGORIE_SECONDAIRE_3 IS NOT NULL
        THEN
            V_CATEGORIE_SECONDAIRE_3_ID :=get_item_category_sec(c.INVENTORY_ITEM_ID,VG_ITEM_CATEGORY_SET_ID2,VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_3);


            IF V_CATEGORIE_SECONDAIRE_3_ID IS NULL 
            THEN
        
                V_CATEGORIE_SECONDAIRE_3_ID:=DKA_IEOMTL_CODARTINT_PKG.get_category_id(VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_3);        

                INSERT INTO mtl_item_categories_interface
                          (inventory_item_id
                          ,category_set_id
                          ,category_id
                          ,last_update_date
                          ,last_updated_by
                          ,creation_date
                          ,created_by
                          ,last_update_login
                          ,organization_id
                          ,process_flag
                          ,transaction_type
                          ,set_process_id
                          )
                    VALUES
                          (c.inventory_item_id --inventory_item_id
                          ,  VG_ITEM_CATEGORY_SET_ID2 --category_set_id
                          , V_CATEGORIE_SECONDAIRE_3_ID --category_id
                          , SYSDATE --last_update_date
                          , fnd_global.user_id --last_updated_by
                          , SYSDATE --creation_date
                          , fnd_global.user_id --created_by
                          , fnd_global.login_id --last_update_login
                          , VG_ORG_ID_PRINCIPALE --organization_id
                          , 1 --process_flag à Pending
                          , 'CREATE' --transaction_type
                          , v3_set_process_id
                          );
                   v_nb_enreg_insert := v_nb_enreg_insert + 1;       
            END IF;
        END IF;

        ----------------catégorie secondaire 4---------------


        IF c.CATEGORIE_SECONDAIRE_4 IS NOT NULL
        THEN
            V_CATEGORIE_SECONDAIRE_4_ID := DKA_IEOMTL_CODARTINT_PKG.GET_ITEM_CATEGORY_SEC(C.INVENTORY_ITEM_ID,VG_ITEM_CATEGORY_SET_ID2,VG_STRUCTURE_ID2,C.CATEGORIE_SECONDAIRE_4);


           IF V_CATEGORIE_SECONDAIRE_4_ID IS NULL 
           THEN
           
               V_CATEGORIE_SECONDAIRE_4_ID:=DKA_IEOMTL_CODARTINT_PKG.get_category_id(VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_4);        

               INSERT INTO mtl_item_categories_interface
                          (inventory_item_id
                          ,category_set_id
                          ,category_id
                          ,last_update_date
                          ,last_updated_by
                          ,creation_date
                          ,created_by
                          ,last_update_login
                          ,organization_id
                          ,process_flag
                          ,transaction_type
                          ,set_process_id
                          )
                    VALUES
                          (c.inventory_item_id --inventory_item_id
                          ,  VG_ITEM_CATEGORY_SET_ID2 --category_set_id
                          , V_CATEGORIE_SECONDAIRE_4_ID --category_id
                          , SYSDATE --last_update_date
                          , fnd_global.user_id --last_updated_by
                          , SYSDATE --creation_date
                          , fnd_global.user_id --created_by
                          , fnd_global.login_id --last_update_login
                          , VG_ORG_ID_PRINCIPALE --organization_id
                          , 1 --process_flag à Pending
                          , 'CREATE' --transaction_type
                          , v4_set_process_id
                          );
                   v_nb_enreg_insert := v_nb_enreg_insert + 1;
            END IF;
        END IF;
        ----------------catégorie secondaire 5---------------


        IF c.CATEGORIE_SECONDAIRE_5 IS NOT NULL
        THEN
 
            V_CATEGORIE_SECONDAIRE_5_ID := DKA_IEOMTL_CODARTINT_PKG.get_item_category_sec(c.INVENTORY_ITEM_ID,VG_ITEM_CATEGORY_SET_ID2,VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_5);


            IF V_CATEGORIE_SECONDAIRE_5_ID IS NULL 
            THEN
                V_CATEGORIE_SECONDAIRE_5_ID:=DKA_IEOMTL_CODARTINT_PKG.get_category_id(VG_STRUCTURE_ID2,c.CATEGORIE_SECONDAIRE_5);        

                INSERT INTO mtl_item_categories_interface
                          (inventory_item_id
                          ,category_set_id
                          ,category_id
                          ,last_update_date
                          ,last_updated_by
                          ,creation_date
                          ,created_by
                          ,last_update_login
                          ,organization_id
                          ,process_flag
                          ,transaction_type
                          ,set_process_id
                          )
                    VALUES
                          (c.inventory_item_id --inventory_item_id
                          ,  VG_ITEM_CATEGORY_SET_ID2 --category_set_id
                          , V_CATEGORIE_SECONDAIRE_5_ID --category_id
                          , SYSDATE --last_update_date
                          , fnd_global.user_id --last_updated_by
                          , SYSDATE --creation_date
                          , fnd_global.user_id --created_by
                          , fnd_global.login_id --last_update_login
                          , VG_ORG_ID_PRINCIPALE --organization_id
                          , 1 --process_flag à Pending
                          , 'CREATE' --transaction_type
                          , v5_set_process_id
                          );
                   v_nb_enreg_insert := v_nb_enreg_insert + 1;       
            END IF;
        END IF;

          ------------------------fin affectation catégories secondaires---------------------------
      END LOOP;
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || v_nb_enreg_insert ||' Enregistrements insérés dans mtl_item_categories_interface'); 
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_assign_category_item');

    EXCEPTION
        WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf := 'INSERT_ASSIGN_CATEGORY_ITEM : ' || sqlerrm;
    END insert_assign_category_item;


 /* *************************************************************************
 * PROCEDURE NAME : launch_item_category
 *
 * DESCRIPTION
 *  Procédure pour lancement de l'OI des affectations de catégories
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
.* ----------------------- -------------------------------------------------
 * 
 *  
 * RETURN
 * ======
 * 
 *
 *************************************************************************/
    PROCEDURE  launch_item_category
                                   (
                                    p_errbuf    OUT      VARCHAR2,
                                    p_retcode   OUT      NUMBER
                                    )                
    IS

    va_request_ids            IdTabTyp;
    vn_requests_cnt           NUMBER (15) := 0;
    vv_phase                  VARCHAR2 (100);
    vv_status                 VARCHAR2 (100);
    vv_dev_phase              VARCHAR2 (100);
    vv_dev_status             VARCHAR2 (100);
    vv_message                VARCHAR2 (100);


    CURSOR Cur_Process  IS
            SELECT DISTINCT set_process_id
            FROM   mtl_item_categories_interface msii
            WHERE  msii.process_flag = 1
            AND    msii.organization_id = VG_ORG_ID_PRINCIPALE;
            vn_nbre  NUMBER;
            vn_request_id  NUMBER;
  BEGIN
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début launch_item_category');

--    fnd_stats.gather_table_stats('INV', 'MTL_ITEM_CATEGORIES', percent => 100, cascade => TRUE ); -- SEL

    BEGIN
    SELECT COUNT(*)
        INTO vn_nbre
        FROM DKA_IEOMTL_SYSTEM_ITEMS_TMP xeiit
        WHERE xeiit.statut = 'INSERT_OA'
        AND   xeiit.request_id = VG_REQUEST_ID;            
    EXCEPTION WHEN NO_DATA_FOUND THEN 
    vn_nbre:=0;
    END;


    IF vn_nbre !=0 
    THEN
       FOR Rec_Process IN Cur_Process LOOP
                 vn_request_id := Fnd_Request.submit_request (
                                                 'INV'                       -- APPL
                                                ,'INV_ITEM_CAT_ASSIGN_OI'    -- PROG
                                                ,NULL                        -- PROGRAM_NAME
                                                ,NULL                        -- START
                                                ,FALSE                       -- SUB_REQUEST
                                                ,Rec_Process.set_process_id  -- Jeu d'enregistrements à traiter
                                                ,1                           -- Charger les enregistrements traités
                                                ,1                           -- Supprimer les enregistrements traités

                                                );
                  IF vn_request_id = 0 THEN
                        p_retcode := 2;
                        fnd_file.put_line(fnd_file.log,'ERREUR : Le traitement d''affectation des catégories a échoué'
                                                         || chr(10)
                                                         || 'PROGRAMME  : INV_ITEM_CAT_ASSIGN_OI'
                                                         || chr(10));

                        fnd_file.put_line(fnd_file.output,'====> ERREUR : Le traitement d''import des articles a échoué');
                  ELSE  
                        commit;
                        fnd_file.put_line(fnd_file.log,'=> REQUEST ID= ' || vn_request_id);                              
                        vn_requests_cnt := vn_requests_cnt + 1;
                        va_request_ids (vn_requests_cnt):= vn_request_id;
                  END IF;

       END LOOP;

       fnd_file.put_line(fnd_file.log,'WAIT FOR REQUEST');
       WHILE vn_requests_cnt > 0
       LOOP
           IF NOT (Fnd_Concurrent.wait_for_request (va_request_ids (vn_requests_cnt), vg_tempo, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_message))
           THEN
               P_Errbuf  := Vv_Message;
               Fnd_file.put_line(Fnd_file.LOG, 'ERREUR : Attente de la fin du traitement d''import des articles dépassée : Fin du traitement' || CHR(10) ||
                                                        'MESSAGE : ' || Vv_Message || CHR(10) );
           END IF;
                
           IF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') 
           THEN
               fnd_file.put_line(fnd_file.log,'Fin normale du traitement '|| va_request_ids (vn_requests_cnt));            
               Fnd_File.put_line(Fnd_File.LOG,'Statut de fin = ' || vv_dev_phase || '/' || vv_dev_status);
           ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'WARNING')
           THEN
               Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement d''import des articles en warning '|| va_request_ids (vn_requests_cnt));
           ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status != 'NORMAL')  
           THEN
                p_retcode := 2;
                P_Errbuf  := 'ERREUR : Fin anormale du traitement d''import des articles : '||Vv_Message;
  
                fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement d''import des articles '|| va_request_ids (vn_requests_cnt) || CHR(10) ||
                                                'Phase/Statut : ' || vv_dev_phase || '/' || vv_dev_status || CHR(10) ||
                                                'MESSAGE : ' || vv_message || CHR(10) );
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement d''import des articles : ' || va_request_ids (vn_requests_cnt)); 
                Fnd_File.put_line(Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement d''import des articles ');
            END IF;          
                vn_requests_cnt    := vn_requests_cnt - 1;
        END LOOP; 

    END IF;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin launch_item_category');
   EXCEPTION
   WHEN OTHERS THEN
        p_retcode := 2;
        p_errbuf := 'LAUNCH_ITEM_CATEGORY : ' || sqlerrm;
   END  launch_item_category;

/* *************************************************************************
 * PROCEUDRE NAME : alimentation_jeux_valeurs
 *
 * DESCRIPTION
 *  chargement ou mise à jour des valeurs des jeux de valeurs DKA_ARTICLE_ECLASS 
													et DKA_ARTICLE_COMPL_TECH_ALL.
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
/* ----------------------- -------------------------------------------------
 *
 *************************************************************************/


    PROCEDURE alimentation_jeux_valeurs (
        p_errbuf IN OUT VARCHAR2,
        p_retcode   OUT NUMBER
    ) IS



	   l_flex_value_set_id1    NUMBER;
        l_flex_value_set_id2    NUMBER;
        l_flex_value_ids1       NUMBER;
        l_flex_value_ids2       NUMBER;
        l_flex_value_ids3       NUMBER;
        l_flex_value_idsc1      NUMBER;
        l_flex_value_idsc2      NUMBER;
        l_flex_value_idsc3      NUMBER;
        l_flex_value_idsc4      NUMBER;
        l_nbl_cree_cde_n2       NUMBER:=0;
        l_nbl_cree_cde_n3       NUMBER:=0;
        l_nbl_cree_cde_n4       NUMBER:=0;
        l_nbl_rej_cde_n2        NUMBER:=0;
        l_nbl_rej_cde_n3        NUMBER:=0;
        l_nbl_rej_cde_n4        NUMBER:=0;
        l_nbl_modifie_cde_n2    NUMBER:=0;
        l_nbl_modifie_cde_n3    NUMBER:=0;
        l_nbl_modifie_cde_n4    NUMBER:=0;
        l_nbl_cree_cmp_n1       NUMBER:=0;
        l_nbl_rej_cmp_n1        NUMBER:=0;
        l_nbl_modifie_cmp_n1    NUMBER:=0;
        l_nbl_modifie_tech      NUMBER:=0;
        l_exist_code_compl1     VARCHAR2(5);
        l_exist_code_compl2     VARCHAR2(5);
        l_exist_code_compl3     VARCHAR2(5);
        l_exist_code_compl4     VARCHAR2(5);
        l_exist_hierarchy       VARCHAR2(5);
        l_flex_value_id1        NUMBER;
        l_classe4_du            VARCHAR2(240);
        l_classe3_du            VARCHAR2(240);
        l_classe1_du            VARCHAR2(240);
        l_classe2_du            VARCHAR2(240);
        l_classe4_au            VARCHAR2(240);
        l_classe3_au            VARCHAR2(240);
        l_classe1_au            VARCHAR2(240);
        l_classe2_au            VARCHAR2(240);
        l_error_jeux_valeurs1   VARCHAR2(100);
        l_val_seg_compl_tech    VARCHAR2(240);
        l_desc_seg_compl_tech   VARCHAR2(240);


		/*//cusror cur_jv utilisé pour l'alimentation et la mise à jour du jeu de valeurs relatif au segment classification technique//*/

        CURSOR cur_jv IS ( 
							SELECT
								code_eclass_n2,
								libelle_eclass_n2,
								code_eclass_n3,
								libelle_eclass_n3,
								code_eclass_n4,
								libelle_eclass_n4
							FROM
								dka_ieomtl_system_items_tmp
							WHERE
								(statut = 'VALIDATED'                                       -- validé en création et mise à jour
                 OR (statut = 'INSERT_OA' and flag_crea_maj_art = '0' ))    -- validé en mise à jour sans modif de l'article (désignation/statut)
								 AND request_id =VG_REQUEST_ID
						  );

	/*//cusror cur_jvC utilisé pour l'alimentation et la mise à jour du jeu de valeurs relatif aux compléments famille technique//*/

        CURSOR cur_jvc IS ( 
							SELECT
                 code_eclass_n4,
								 code_compl_n1,
								 designation_compl_n1,
								 code_compl_n2,
								 designation_compl_n2,
								 code_compl_n3,
								 designation_compl_n3,
								 code_compl_n4,
								 designation_compl_n4,
								 code_compl_n5,
								 designation_compl_n5,
								 code_compl_n6,
								 designation_compl_n6,
								 code_compl_n7,
								 designation_compl_n7,
								 code_compl_n8,
								 designation_compl_n8,
								 code_compl_n9,
								 designation_compl_n9,
								 code_article,
								 description_article,
								 file_name,
								 line_num,
                 flag_crea_maj_art
              FROM
                  dka_ieomtl_system_items_tmp
              WHERE
						 		(statut = 'VALIDATED'                                       -- validé en création et mise à jour
                 OR (statut = 'INSERT_OA' and flag_crea_maj_art = '0' ))    -- validé en mise à jour sans modif de l'article (désignation/statut)
							  AND request_id =VG_REQUEST_ID
                );


    BEGIN

        /*//Alimentation et la mise à jour du jeu de valeurs relatif au segment classification technique//*/

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début alimentation_jeux_valeurs');

        IF vg_flex_value_set_id_eclass IS NOT NULL THEN

            FOR crjv IN cur_jv LOOP

				/*//--insertion des valeurs du champ CODE_ECLASS_N2//*/

                IF crjv.code_eclass_n2 IS NOT NULL THEN
                    BEGIN
                        UPDATE fnd_flex_values_tl ffvl
                        SET
                            description = crjv.libelle_eclass_n2,
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_global.user_id
                        WHERE
                            ffvl.flex_value_id IN (
													SELECT
														ffvl.flex_value_id
													FROM
														fnd_flex_values_vl ffvl
													WHERE
														ffvl.flex_value_set_id = vg_flex_value_set_id_eclass
															AND ffvl.flex_value = crjv.code_eclass_n2
															AND ffvl.description != crjv.libelle_eclass_n2
												  );


                        IF SQL%found THEN

                            l_nbl_modifie_cde_n2 := l_nbl_modifie_cde_n2 + 1;
                        END IF;
                    END;

                    BEGIN
                        IF SQL%notfound THEN
                        
                            SELECT
                                  fnd_flex_values_s.NEXTVAL
                            INTO l_flex_value_ids1
                            FROM
                                dual;
                            
                            INSERT INTO fnd_flex_values (
															flex_value_set_id,
															flex_value_id,
															flex_value,
															last_update_date,
															last_updated_by,
															creation_date,
															created_by,
															enabled_flag,
															summary_flag,
															compiled_value_attributes
														)
												  VALUES
														(
															vg_flex_value_set_id_eclass,
															l_flex_value_ids1,
															crjv.code_eclass_n2,
															SYSDATE,
															fnd_global.user_id,
															SYSDATE,
															fnd_global.user_id,
															'Y',
															'Y',
															( 'N'
															  || CHR(10)
															  || 'N' )
														);

                            --COMMIT;
                            INSERT INTO fnd_flex_values_tl (
															flex_value_id,
															language,
															last_update_date,
															last_updated_by,
															creation_date,
															created_by,
															last_update_login,
															description,
															source_lang,
															flex_value_meaning
															) 
												   VALUES 
														(
															l_flex_value_ids1,
															'F',
															SYSDATE,
															fnd_global.user_id,
															SYSDATE,
															fnd_global.user_id,
															fnd_global.login_id,
															crjv.libelle_eclass_n2,
															'F',
															crjv.code_eclass_n2
														);

														--COMMIT;
                            l_nbl_cree_cde_n2 := l_nbl_cree_cde_n2 + 1;
                        END IF;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_nbl_rej_cde_n2 := l_nbl_rej_cde_n2 + 1;							         
                    END;
                END IF;

				/*//--insertion des valeurs du champ CODE_ECLASS_N3//*/

                IF crjv.code_eclass_n3 IS NOT NULL THEN
                    BEGIN
                        UPDATE fnd_flex_values_tl ffvl
                        SET
                            description = crjv.libelle_eclass_n3,
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_global.user_id
                        WHERE
                            ffvl.flex_value_id IN (
													SELECT
														ffvl.flex_value_id
													FROM
														fnd_flex_values_vl ffvl
													WHERE
														ffvl.flex_value_set_id = vg_flex_value_set_id_eclass
															AND ffvl.flex_value = crjv.code_eclass_n3
															AND ffvl.description != crjv.libelle_eclass_n3
												   );

                        IF SQL%found THEN
                            l_nbl_modifie_cde_n3 := l_nbl_modifie_cde_n3 + 1;
                        END IF;
                    END;

                    BEGIN
                        IF SQL%notfound THEN
                            SELECT
                                fnd_flex_values_s.NEXTVAL
                            INTO l_flex_value_ids2
                            FROM
                                dual;

                            INSERT INTO fnd_flex_values (
															flex_value_set_id,
															flex_value_id,
															flex_value,
															last_update_date,
															last_updated_by,
															creation_date,
															created_by,
															enabled_flag,
															summary_flag,
															compiled_value_attributes
														) 
												  VALUES 
														(
															vg_flex_value_set_id_eclass,
															l_flex_value_ids2,
															crjv.code_eclass_n3,
															SYSDATE,
															fnd_global.user_id,
															SYSDATE,
															fnd_global.user_id,
															'Y',
															'Y',
															( 'N'
															  || CHR(10)
															  || 'N' )
														);

                            --COMMIT;
                            INSERT INTO fnd_flex_values_tl (
															flex_value_id,
															language,
															last_update_date,
															last_updated_by,
															creation_date,
															created_by,
															last_update_login,
															description,
															source_lang,
															flex_value_meaning
                                                            ) 
													VALUES 
													      (
															l_flex_value_ids2,
															'F',
															SYSDATE,
															fnd_global.user_id,
															SYSDATE,
															fnd_global.user_id,
															fnd_global.login_id,
															crjv.libelle_eclass_n3,
															'F',
															crjv.code_eclass_n3
															);

                            --COMMIT;
                            l_nbl_cree_cde_n3 := l_nbl_cree_cde_n3 + 1;
                        END IF;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_nbl_rej_cde_n3 := l_nbl_rej_cde_n3 + 1;

                            --COMMIT;
                    END;

                END IF;

				        /*//--insertion des valeurs du champ CODE_ECLASS_N4--//*/

                IF crjv.code_eclass_n4 IS NOT NULL THEN
                    BEGIN
                        UPDATE fnd_flex_values_tl ffvl
                        SET
                            description = crjv.libelle_eclass_n4,
                            last_update_date = SYSDATE,
                            last_updated_by = fnd_global.user_id
                        WHERE
                            ffvl.flex_value_id IN (
                                SELECT
                                    ffvl.flex_value_id
                                FROM
                                    fnd_flex_values_vl ffvl
                                WHERE
                                    ffvl.flex_value_set_id = vg_flex_value_set_id_eclass
									             	AND ffvl.flex_value = crjv.code_eclass_n4
										            AND ffvl.description != crjv.libelle_eclass_n4
													);

                        IF SQL%found THEN
                            l_nbl_modifie_cde_n4 := l_nbl_modifie_cde_n4 + 1;
                        END IF;
                    END;

                    BEGIN
                        IF SQL%notfound THEN

                            SELECT
                               fnd_flex_values_s.NEXTVAL
                            INTO l_flex_value_ids3
                            FROM
                                dual;

                            INSERT INTO fnd_flex_values (
															flex_value_set_id,
															flex_value_id,
															flex_value,
															last_update_date,
															last_updated_by,
															creation_date,
															created_by,
															enabled_flag,
															summary_flag,
															compiled_value_attributes
														) 
												VALUES  
												        (
															vg_flex_value_set_id_eclass,
															l_flex_value_ids3,
															crjv.code_eclass_n4,
															SYSDATE,
															fnd_global.user_id,
															SYSDATE,
															fnd_global.user_id,
															'Y',
															'N',
															( 'N'
															  || CHR(10)
															  || 'N' )
														);

                            --COMMIT;
                            INSERT INTO fnd_flex_values_tl(
															flex_value_id,
															language,
															last_update_date,
															last_updated_by,
															creation_date,
															created_by,
															last_update_login,
															description,
															source_lang,
															flex_value_meaning
														 ) 
													VALUES 
													     (
															l_flex_value_ids3,
															'F',
															SYSDATE,
															fnd_global.user_id,
															SYSDATE,
															fnd_global.user_id,
															fnd_global.login_id,
															crjv.libelle_eclass_n4,
															'F',
															crjv.code_eclass_n4
                                                         );

                            --COMMIT;
                            l_nbl_cree_cde_n4 := l_nbl_cree_cde_n4 + 1;
                        END IF;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_nbl_rej_cde_n4 := l_nbl_rej_cde_n4 + 1;
                            --COMMIT;
                    END;

                END IF;

            END LOOP;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_modifie_cde_n2 ||' codes elcass de niveau 2 mis à jour dans le jeu de valeurs');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_cree_cde_n2 ||' codes elcass de niveau 2 importés dans le jeu de valeurs');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_rej_cde_n2 ||' codes elcass de niveau 2 rejetés');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_modifie_cde_n3 ||' codes elcass de niveau 3 mis à jour dans le jeu de valeurs');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_cree_cde_n3 ||' codes elcass de niveau 3 importés dans le jeu de valeurs');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_rej_cde_n3 ||' codes elcass de niveau 3 rejetés');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_modifie_cde_n4 ||' codes elcass de niveau 4 mis à jour dans le jeu de valeurs');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_cree_cde_n4 ||' codes elcass de niveau 4 importés dans le jeu de valeurs');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_rej_cde_n4 ||' codes elcass de niveau 4 rejetés');


            --COMMIT;

		    	/*//--Alimentation de la hiérarchie eCl@ss--//*/
            FOR crjvh IN cur_jv LOOP

			       /*//--Pour chaque « Code eCl@ss N2 » renseigné--//*/
                IF crjvh.code_eclass_n2 IS NOT NULL THEN
                    BEGIN
                        SELECT
                            ffv.flex_value_id
                        INTO l_flex_value_id1
                        FROM
                            fnd_flex_values ffv
                        WHERE
                            ffv.flex_value_set_id = vg_flex_value_set_id_eclass
                            AND ffv.flex_value = crjvh.code_eclass_n2;

                        IF SQL%found THEN

				                 	/*//--Si un code « Code eCl@ss N3 » est renseigné--//*/
                            IF crjvh.code_eclass_n3 IS NOT NULL THEN
                                BEGIN
                                    SELECT
                                        'Y'
                                    INTO l_exist_hierarchy
                                    FROM
                                        fnd_flex_value_norm_hierarchy
                                    WHERE
                                        flex_value_set_id = vg_flex_value_set_id_eclass
							              				AND parent_flex_value = crjvh.code_eclass_n2
							              				AND range_attribute = 'P'
									              		AND child_flex_value_low = crjvh.code_eclass_n3
										              	AND child_flex_value_high = crjvh.code_eclass_n3;

                                EXCEPTION
                                    WHEN no_data_found THEN
                                        l_exist_hierarchy := 'N';
                                END;

                                IF l_exist_hierarchy = 'N' THEN
                                    SELECT
                                        MIN(crjvh.code_eclass_n3)
                                    INTO l_classe3_du
                                    FROM
                                        dka_ieomtl_system_items_tmp
                                    WHERE
                                        code_eclass_n2 = crjvh.code_eclass_n2
										                AND request_id =VG_REQUEST_ID;

                                    SELECT
                                        MAX(crjvh.code_eclass_n3)
                                    INTO l_classe3_au
                                    FROM
                                        dka_ieomtl_system_items_tmp
                                    WHERE
                                        code_eclass_n2 = crjvh.code_eclass_n2
										                AND request_id =VG_REQUEST_ID;

                                    INSERT INTO fnd_flex_value_norm_hierarchy (
																				flex_value_set_id,
																				parent_flex_value,
																				range_attribute,
																				child_flex_value_low,
																				child_flex_value_high,
																				created_by,
																				creation_date,
																				last_updated_by,
																				last_update_date,
																				last_update_login
																			  )
									                  VALUES 
																			 (
																				vg_flex_value_set_id_eclass,
																				crjvh.code_eclass_n2,
																				'P',
																				l_classe3_du,   -- a revoir 
																				l_classe3_au,   -- a revoir 
																				fnd_global.user_id,
																				SYSDATE,
																				fnd_global.user_id,
																				SYSDATE,
																				fnd_global.login_id
																			  );

                                    --COMMIT;
                                ELSIF l_exist_hierarchy = 'Y' THEN
                                    NULL;
                                END IF;

				                  	/*//--Si un code « Code eCl@ss N3 » n'est pas renseigné--//*/

                            ELSIF crjvh.code_eclass_n3 IS NULL THEN
                                BEGIN
                                    SELECT
                                        'Y'
                                    INTO l_exist_hierarchy
                                    FROM
                                        fnd_flex_value_norm_hierarchy
                                    WHERE
                                        flex_value_set_id = vg_flex_value_set_id_eclass
							               				AND parent_flex_value = crjvh.code_eclass_n2
								              			AND range_attribute = 'C'
									              		AND child_flex_value_low = crjvh.code_eclass_n4
									              		AND child_flex_value_high = crjvh.code_eclass_n4;

                                EXCEPTION
                                    WHEN no_data_found THEN
                                        l_exist_hierarchy := 'N';
                                END;

                                IF l_exist_hierarchy = 'N' THEN
                                    SELECT
                                        MIN(crjvh.code_eclass_n4)
                                    INTO l_classe4_du
                                    FROM
                                        dka_ieomtl_system_items_tmp
                                    WHERE
                                        code_eclass_n2 = crjvh.code_eclass_n2
									             	    AND request_id =VG_REQUEST_ID;

                                    SELECT
                                        MAX(crjvh.code_eclass_n4)
                                    INTO l_classe4_au
                                    FROM
                                        dka_ieomtl_system_items_tmp
                                    WHERE
                                        code_eclass_n2 = crjvh.code_eclass_n2
										                AND request_id =VG_REQUEST_ID;

                                    INSERT INTO fnd_flex_value_norm_hierarchy (
																				flex_value_set_id,
																				parent_flex_value,
																				range_attribute,
																				child_flex_value_low,
																				child_flex_value_high,
																				created_by,
																				creation_date,
																				last_updated_by,
																				last_update_date,
																				last_update_login
																			  )
																	   VALUES 
																	          (
																				vg_flex_value_set_id_eclass,
																				crjvh.code_eclass_n2,
																				'C',
																				l_classe4_du,   -- a revoir 
																				l_classe4_au,   -- a revoir 
																				fnd_global.user_id,
																				SYSDATE,
																				fnd_global.user_id,
																				SYSDATE,
																				fnd_global.login_id
																			   );

                                    --COMMIT;
                                ELSIF l_exist_hierarchy = 'Y' THEN
                                    NULL;
                                END IF;

                            END IF;

                        END IF;

                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;

                END IF;
            END LOOP;

            FOR crjvh1 IN cur_jv LOOP

		            /*//--Pour chaque « Code eCl@ss N3 » renseigné--//*/
                IF crjvh1.code_eclass_n3 IS NOT NULL THEN
                    BEGIN
                        SELECT
                            'Y'
                        INTO l_exist_hierarchy
                        FROM
                            fnd_flex_value_norm_hierarchy
                        WHERE
                            flex_value_set_id = vg_flex_value_set_id_eclass
								        AND parent_flex_value = crjvh1.code_eclass_n3
								        AND range_attribute = 'C'
								        AND child_flex_value_low = crjvh1.code_eclass_n4
								        AND child_flex_value_high = crjvh1.code_eclass_n4;

                    EXCEPTION
                        WHEN no_data_found THEN
                            l_exist_hierarchy := 'N';
                    END;

                    IF l_exist_hierarchy = 'N' THEN
                        SELECT
                            MIN(crjvh1.code_eclass_n4)
                        INTO l_classe4_du
                        FROM
                            dka_ieomtl_system_items_tmp
                        WHERE
                            code_eclass_n3 = crjvh1.code_eclass_n3
							          AND request_id =VG_REQUEST_ID;

                        SELECT
                            MAX(crjvh1.code_eclass_n4)
                        INTO l_classe4_au
                        FROM
                            dka_ieomtl_system_items_tmp
                        WHERE
                            code_eclass_n3 = crjvh1.code_eclass_n3;

                        INSERT INTO fnd_flex_value_norm_hierarchy (
																	flex_value_set_id,
																	parent_flex_value,
																	range_attribute,
																	child_flex_value_low,
																	child_flex_value_high,
																	created_by,
																	creation_date,
																	last_updated_by,
																	last_update_date,
																	last_update_login
																  ) 
														   VALUES 
														          (
																	vg_flex_value_set_id_eclass,
																	crjvh1.code_eclass_n3,
																	'C',
																	l_classe4_du,   -- a revoir 
																	l_classe4_au,   -- a revoir 
																	fnd_global.user_id,
																	SYSDATE,
																	fnd_global.user_id,
																	SYSDATE,
																	fnd_global.login_id
																  );

                        --COMMIT;
                    ELSIF l_exist_hierarchy = 'Y' THEN
                        NULL;
                    END IF;

                ELSE
                    NULL;
                END IF;
            END LOOP;

        END IF;

     /*// Fin de l'alimentation et la mise à jour du jeu de valeurs relatif au segment classification tecnique//*/
     /*--------------------------------------------------------------------------------------------------*/
     /*--//Alimentation et mise à jour du jeu de valeurs relatif aux segment compléments famille technique --//*/



        IF vg_flex_value_set_id_tech IS NOT NULL THEN
            BEGIN
                FOR crc IN cur_jvc LOOP

				         /*// insertion des valeurs compléments famille technique //*/
                    BEGIN
                        SELECT
                            substr(crc.code_article,instr(crc.code_article,'.',1) + 1)
                        INTO l_val_seg_compl_tech
                        FROM
                            dual;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_val_seg_compl_tech := NULL;
                    END;

                    BEGIN
                        SELECT
                            substr((crc.designation_compl_n1
                                       || decode(crc.designation_compl_n2,NULL,'','\')
                                       || crc.designation_compl_n2
                                       || decode(crc.designation_compl_n3,NULL,'','\')
                                       || crc.designation_compl_n3
                                       || decode(crc.designation_compl_n4,NULL,'','\')
                                       || crc.designation_compl_n4
                                       || decode(crc.designation_compl_n5,NULL,'','\')
                                       || crc.designation_compl_n5
                                       || decode(crc.designation_compl_n6,NULL,'','\')
                                       || crc.designation_compl_n6
                                       || decode(crc.designation_compl_n7,NULL,'','\')
                                       || crc.designation_compl_n7
                                       || decode(crc.designation_compl_n8,NULL,'','\')
                                       || crc.designation_compl_n8
                                       || decode(crc.designation_compl_n9,NULL,'','\')
                                       || crc.designation_compl_n9),'1',240)
                        INTO l_desc_seg_compl_tech
                        FROM
                            dual;

                    EXCEPTION
                        WHEN OTHERS THEN
                            l_desc_seg_compl_tech := NULL;
                    END;

                    IF l_val_seg_compl_tech IS NOT NULL THEN
                        BEGIN
                            UPDATE fnd_flex_values_tl ffvl
                            SET
                                description = l_desc_seg_compl_tech,
                                last_update_date = SYSDATE,
                                last_updated_by = fnd_global.user_id
                            WHERE
                                ffvl.flex_value_id IN (
                                    SELECT
                                        ffvl.flex_value_id
                                    FROM
                                        fnd_flex_values_vl ffvl
                                    WHERE
                                        ffvl.flex_value_set_id = vg_flex_value_set_id_tech
									              		AND ffvl.flex_value = l_val_seg_compl_tech
									              		AND ffvl.description != l_desc_seg_compl_tech
                                );

                            IF SQL%found THEN
                                l_nbl_modifie_cmp_n1 := l_nbl_modifie_cmp_n1 + 1;
                            END IF;
                        END;

                        BEGIN
                            IF SQL%notfound THEN

                                SELECT
                                   fnd_flex_values_s.NEXTVAL
                                INTO l_flex_value_idsc1
                                FROM
                                   dual;

                                INSERT INTO fnd_flex_values (
																flex_value_set_id,
																flex_value_id,
																flex_value,
																last_update_date,
																last_updated_by,
																creation_date,
																created_by,
																enabled_flag,
																summary_flag,
																compiled_value_attributes
															 ) 
													  VALUES
													         (
																vg_flex_value_set_id_tech,
																l_flex_value_idsc1,
																l_val_seg_compl_tech,
																SYSDATE,
																fnd_global.user_id,
																SYSDATE,
																fnd_global.user_id,
																'Y',
																'N',
																( 'N'
																  || CHR(10)
																  || 'N' )
															 );

                                --COMMIT;
                                INSERT INTO fnd_flex_values_tl (
																	flex_value_id,
																	language,
																	last_update_date,
																	last_updated_by,
																	creation_date,
																	created_by,
																	last_update_login,
																	description,
																	source_lang,
																	flex_value_meaning
                                                               ) 
														VALUES 
															   (
																	l_flex_value_idsc1,
																	'F',
																	SYSDATE,
																	fnd_global.user_id,
																	SYSDATE,
																	fnd_global.user_id,
																	fnd_global.login_id,
																	l_desc_seg_compl_tech,
																	'F',
																	l_val_seg_compl_tech
																);

                                --COMMIT;
                                l_nbl_cree_cmp_n1 := l_nbl_cree_cmp_n1 + 1;
                            END IF;

                        EXCEPTION
                            WHEN OTHERS THEN
                                l_nbl_rej_cmp_n1 := l_nbl_rej_cmp_n1 + 1;

                      END;
                      
                      

                    END IF;

                    IF crc.flag_crea_maj_art IN ('0', '2')    -- Mise à jour des désignations dans la table spécifique pour les articles en mise à jour
                    THEN
                    
                       BEGIN
                         UPDATE dka_ieomtl_compl_tech
                         SET DESCR_COMPL_TECH_1 = crc.designation_compl_n1
                            ,DESCR_COMPL_TECH_2 = crc.designation_compl_n2
                            ,DESCR_COMPL_TECH_3 = crc.designation_compl_n3
                            ,DESCR_COMPL_TECH_4 = crc.designation_compl_n4
                            ,DESCR_COMPL_TECH_5 = crc.designation_compl_n5
                            ,DESCR_COMPL_TECH_6 = crc.designation_compl_n6
                            ,DESCR_COMPL_TECH_7 = crc.designation_compl_n7
                            ,DESCR_COMPL_TECH_8 = crc.designation_compl_n8
                            ,DESCR_COMPL_TECH_9 = crc.designation_compl_n9
                            ,last_update_date = SYSDATE
                            ,last_updated_by = fnd_global.user_id
                          WHERE nvl(CLASSIF_TECHNIQUE,'*') = nvl(crc.code_eclass_n4,'*')
                          AND   nvl(COMPL_TECH_1,'*') = nvl(crc.code_compl_n1,'*')
                          AND   nvl(COMPL_TECH_2,'*') = nvl(crc.code_compl_n2,'*')
                          AND   nvl(COMPL_TECH_3,'*') = nvl(crc.code_compl_n3,'*')
                          AND   nvl(COMPL_TECH_4,'*') = nvl(crc.code_compl_n4,'*')
                          AND   nvl(COMPL_TECH_5,'*') = nvl(crc.code_compl_n5,'*')
                          AND   nvl(COMPL_TECH_6,'*') = nvl(crc.code_compl_n6,'*')
                          AND   nvl(COMPL_TECH_7,'*') = nvl(crc.code_compl_n7,'*')
                          AND   nvl(COMPL_TECH_8,'*') = nvl(crc.code_compl_n8,'*')
                          AND   nvl(COMPL_TECH_9,'*') = nvl(crc.code_compl_n9,'*')
                          AND  (nvl(DESCR_COMPL_TECH_1,'*') != nvl(crc.designation_compl_n1,'*')
                                 OR nvl(DESCR_COMPL_TECH_2,'*') != nvl(crc.designation_compl_n2,'*')
                                 OR nvl(DESCR_COMPL_TECH_3,'*') != nvl(crc.designation_compl_n3,'*')
                                 OR nvl(DESCR_COMPL_TECH_4,'*') != nvl(crc.designation_compl_n4,'*')
                                 OR nvl(DESCR_COMPL_TECH_5,'*') != nvl(crc.designation_compl_n5,'*')
                                 OR nvl(DESCR_COMPL_TECH_6,'*') != nvl(crc.designation_compl_n6,'*')
                                 OR nvl(DESCR_COMPL_TECH_7,'*') != nvl(crc.designation_compl_n7,'*')
                                 OR nvl(DESCR_COMPL_TECH_8,'*') != nvl(crc.designation_compl_n8,'*')
                                 OR nvl(DESCR_COMPL_TECH_9,'*') != nvl(crc.designation_compl_n9,'*'));
                                 
                            l_nbl_modifie_tech := l_nbl_modifie_tech + SQL%ROWCOUNT;     
                      EXCEPTION
                      WHEN OTHERS THEN
                        Fnd_File.put_line (Fnd_File.LOG,'Erreur lors de la mise à jour de dka_ieomtl_compl_tech');
                        p_retcode := 2;
                      END; 
                      
                    END IF;
                      

                END LOOP;
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_modifie_cmp_n1 ||' codes complément mis à jour dans le jeu de valeurs');
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_cree_cmp_n1 ||' codes complément inséré dans le jeu de valeurs');
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_rej_cmp_n1 ||' codes complément en erreur');
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || l_nbl_modifie_tech ||' enregistrements modifiés dans dka_ieomtl_compl_tech');


            END;

        END IF;



        -- Alimentation de la table spécifique dka_ieomtl_compl_tech  en création d'article
        BEGIN
						INSERT INTO dka_ieomtl_compl_tech (
                        CLASSIF_TECHNIQUE    , 
                        COMPL_TECH_1         , 
                        DESCR_COMPL_TECH_1   , 
                        COMPL_TECH_2         , 
                        DESCR_COMPL_TECH_2   , 
                        COMPL_TECH_3         , 
                        DESCR_COMPL_TECH_3   , 
                        COMPL_TECH_4         , 
                        DESCR_COMPL_TECH_4   , 
                        COMPL_TECH_5         , 
                        DESCR_COMPL_TECH_5   , 
                        COMPL_TECH_6         , 
                        DESCR_COMPL_TECH_6   , 
                        COMPL_TECH_7         , 
                        DESCR_COMPL_TECH_7   , 
                        COMPL_TECH_8         , 
                        DESCR_COMPL_TECH_8   , 
                        COMPL_TECH_9         , 
                        DESCR_COMPL_TECH_9   , 
                        ENABLED_FLAG         , 
                        CREATION_DATE        , 
                        CREATED_BY           , 
                        LAST_UPDATE_DATE     , 
                        LAST_UPDATED_BY      
                       ) 
                       (SELECT code_eclass_n4,
							          	     code_compl_n1,
								               designation_compl_n1,
								               code_compl_n2,
								               designation_compl_n2,
								               code_compl_n3,
								               designation_compl_n3,
								               code_compl_n4,
								               designation_compl_n4,
								               code_compl_n5,
								               designation_compl_n5,
								               code_compl_n6,
								               designation_compl_n6,
								               code_compl_n7,
								               designation_compl_n7,
								               code_compl_n8,
								               designation_compl_n8,
								               code_compl_n9,
								               designation_compl_n9,
                               'Y',
                               sysdate,
                               vg_user_id,
                               sysdate,
                               vg_user_id
				            		FROM
				              			dka_ieomtl_system_items_tmp disi
					            	WHERE
					              		statut = 'VALIDATED'
                        AND flag_crea_maj_art = 1 
                        AND NOT EXISTS (SELECT 'x'
                                        FROM dka_ieomtl_compl_tech tech
                                        WHERE nvl(tech.CLASSIF_TECHNIQUE,'*') = nvl(disi.code_eclass_n4,'*')
                                        AND   nvl(tech.COMPL_TECH_1,'*') = nvl(disi.code_compl_n1,'*')
                                        AND   nvl(tech.COMPL_TECH_2,'*') = nvl(disi.code_compl_n2,'*')
                                        AND   nvl(tech.COMPL_TECH_3,'*') = nvl(disi.code_compl_n3,'*')
                                        AND   nvl(tech.COMPL_TECH_4,'*') = nvl(disi.code_compl_n4,'*')
                                        AND   nvl(tech.COMPL_TECH_5,'*') = nvl(disi.code_compl_n5,'*')
                                        AND   nvl(tech.COMPL_TECH_6,'*') = nvl(disi.code_compl_n6,'*')
                                        AND   nvl(tech.COMPL_TECH_7,'*') = nvl(disi.code_compl_n7,'*')
                                        AND   nvl(tech.COMPL_TECH_8,'*') = nvl(disi.code_compl_n8,'*')
                                        AND   nvl(tech.COMPL_TECH_9,'*') = nvl(disi.code_compl_n9,'*')
                                        )                       

																 );

            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||SQL%ROWCOUNT||' enregistrements insérés dans dka_ieomtl_compl_tech.'); 
        EXCEPTION
            WHEN no_data_found THEN
                Fnd_File.put_line (Fnd_File.LOG, 'Aucune donnée trouvée pour l''alimentation de la table DKA_IEOMTL_COMPL_TECH');
        END;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin alimentation_jeux_valeurs');

    /*--// Fin d'alimentation et la mise à jour du jeu de valeurs relatif aux compléments famille technique --//*/
    EXCEPTION
        WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf := 'ALIMENTATION_JEUX_VALEURS : ' || sqlerrm;  
    END alimentation_jeux_valeurs;

/* *************************************************************************
 * PROCEUDRE NAME : insert_items_interface
 *
 * DESCRIPTION
 *  Insertion des articles dans les tables d'open interface
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
/* ----------------------- -------------------------------------------------
 *
 *************************************************************************/

    PROCEDURE insert_items_interface (
        p_type_org          IN VARCHAR2,
        p_statut            IN VARCHAR2,
        p_errbuf            OUT VARCHAR2,
        p_retcode           OUT NUMBER
    ) IS

        ----------------------------------------------------------
        -- Curseur de lecture des données de la table interface --
        ----------------------------------------------------------

        CURSOR cur_items (p_statut VARCHAR2)
        IS 
        SELECT *
        FROM
            dka_ieomtl_system_items_tmp
        WHERE
            statut IN ( p_statut
									    )
					AND request_id =VG_REQUEST_ID
          FOR UPDATE;

        iit     cur_items%ROWTYPE;

        vn_transfered_rows       NUMBER := 0;
        vn_nbre_record_cr        NUMBER := 0;
        vn_set_process_id_cr     NUMBER := 0;
        vn_nbre_record_maj       NUMBER := 0;
        vn_set_process_id_maj    NUMBER := 0;
        vn1_set_process_id_cr    NUMBER := 0;
        vn1_set_process_id_maj   NUMBER := 0;
        vn2_set_process_id_cr    NUMBER := 0;
        vn2_set_process_id_maj   NUMBER := 0;
        vn3_set_process_id_cr    NUMBER := 0;
        vn3_set_process_id_maj   NUMBER := 0;
        l_uom_code               VARCHAR2(5);
        v_exist                  NUMBER := 0;
        VN_NB_LIGNES_V1          NUMBER := 0;
        VN_NB_LIGNES_V2          NUMBER := 0;
        VN_NB_LIGNES_V3          NUMBER := 0;
        VN_NB_LIGNES_V4          NUMBER := 0;
                
    BEGIN


        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début insert_items_interface');
    

        IF p_type_org = 'PRINCIPALE'
        THEN
           SELECT
               mtl_system_items_intf_sets_s.NEXTVAL
           INTO vn_set_process_id_cr
           FROM
               dual;

           SELECT
               mtl_system_items_intf_sets_s.NEXTVAL
           INTO vn_set_process_id_maj
           FROM
               dual;
        ELSE       
           SELECT
             mtl_system_items_intf_sets_s.NEXTVAL
           INTO vn1_set_process_id_cr
           FROM
               dual;

           SELECT
               mtl_system_items_intf_sets_s.NEXTVAL
           INTO vn1_set_process_id_maj
           FROM
               dual;
        END IF;      
             
        p_errbuf := NULL;
        p_retcode := 0;


            ----------------------------------------------
            -- Insertion dans la table d'Open interface --
            ----------------------------------------------

        OPEN cur_items (p_statut);
        LOOP
            FETCH cur_items INTO iit;
            EXIT WHEN cur_items%NOTFOUND;

            IF p_type_org = 'PRINCIPALE'  AND iit.flag_crea_maj_art ='1' 
            THEN
                --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'ORGANISATION PRINCIPALE');

                /*//---------------contôle nb lignes par lot-----------//*/
                IF VN_NB_LIGNES_V1 = VG_NBLIGNES_LOT 
                THEN
                      VN_NB_LIGNES_V1 := 0;
                      SELECT
                            MTL_SYSTEM_ITEMS_INTF_SETS_S.NEXTVAL
                      INTO VN_SET_PROCESS_ID_CR
                      FROM
                            DUAL;           
                END IF;
                /*//---------------fin contôle nb lignes par lot-----------//*/

                INSERT INTO mtl_system_items_interface (
															inventory_item_id,
															organization_id,
															creation_date,
															created_by,
															description,
															segment1,
															segment2,
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
															PRIMARY_UNIT_OF_MEASURE,--primary_uom_code,
															inventory_item_status_code,
															process_flag,
															template_id,
															transaction_type,
															set_process_id
														) 
												 VALUES 
														(
															iit.inventory_item_id,
															VG_ORG_ID_PRINCIPALE,
															SYSDATE,
															VG_USER_ID,
															iit.description_article ,   --description
															iit.code_eclass_n4 ,--,SEGMENT1
															substr(iit.code_article,instr(iit.code_article,'.',1) + 1), --,SEGMENT2 
															iit.code_eclass_n4, --,ATTRIBUTE1
															iit.code_compl_n1, --,ATTRIBUTE2
															iit.code_compl_n2 ,--,ATTRIBUTE3
															iit.code_compl_n3, --,ATTRIBUTE4
															iit.code_compl_n4, --,ATTRIBUTE5
															iit.code_compl_n5, --,ATTRIBUTE6
															iit.code_compl_n6, --,ATTRIBUTE7 
															iit.code_compl_n7, --,ATTRIBUTE8
															iit.code_compl_n8, --,ATTRIBUTE9
															iit.code_compl_n9, --,ATTRIBUTE10
															iit.unite_de_mesure,----,PRIMARY_UOM_CODE
															iit.statut_article, -- ,INVENTORY_ITEM_STATUS_CODE
															1 ,--,PROCESS_FLAG
															VG_TEMPLATE_ID, --,TEMPLATE_ID
															DECODE(iit.flag_crea_maj_art,'1','CREATE') ,--,TRANSACTION_TYPE
															DECODE(iit.flag_crea_maj_art,'1',vn_set_process_id_cr)--,SET_PROCESS_ID
                                                        );
               -- COMMIT;
               vn_nbre_record_cr := vn_nbre_record_cr + 1;
               VN_NB_LIGNES_V1 :=VN_NB_LIGNES_V1+1;
               
            ELSIF  p_type_org = 'PRINCIPALE'  AND iit.flag_crea_maj_art ='2' 
            THEN
                
                   /*//---------------contôle nb lignes par lot-----------//*/
                   IF VN_NB_LIGNES_V2 = VG_NBLIGNES_LOT 
                   THEN
                      VN_NB_LIGNES_V2   := 0;
                      SELECT
                          MTL_SYSTEM_ITEMS_INTF_SETS_S.NEXTVAL
                      INTO vn_set_process_id_maj
                      FROM
                          DUAL;

                   END IF;
                   /*//---------------fin contôle nb lignes par lot-----------//*/
                   
                   INSERT INTO mtl_system_items_interface (
															inventory_item_id,
															organization_id,
															creation_date,
															created_by,
															description,
															segment1,
															segment2,
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
															PRIMARY_UNIT_OF_MEASURE,--primary_uom_code,
															inventory_item_status_code,
															process_flag,
															template_id,
															transaction_type,
															set_process_id
														) 
												 VALUES 
														(
															iit.inventory_item_id,
															VG_ORG_ID_PRINCIPALE,
															SYSDATE,
															VG_USER_ID,
															iit.description_article ,   --description
															iit.code_eclass_n4 ,--,SEGMENT1
															substr(iit.code_article,instr(iit.code_article,'.',1) + 1), --,SEGMENT2 
															iit.code_eclass_n4, --,ATTRIBUTE1
															iit.code_compl_n1, --,ATTRIBUTE2
															iit.code_compl_n2 ,--,ATTRIBUTE3
															iit.code_compl_n3, --,ATTRIBUTE4
															iit.code_compl_n4, --,ATTRIBUTE5
															iit.code_compl_n5, --,ATTRIBUTE6
															iit.code_compl_n6, --,ATTRIBUTE7 
															iit.code_compl_n7, --,ATTRIBUTE8
															iit.code_compl_n8, --,ATTRIBUTE9
															iit.code_compl_n9, --,ATTRIBUTE10
                              iit.unite_de_mesure,--iit.uom_code, --,PRIMARY_UOM_CODE
															iit.statut_article, -- ,INVENTORY_ITEM_STATUS_CODE
															1 ,--,PROCESS_FLAG
															VG_TEMPLATE_ID, --,TEMPLATE_ID
															DECODE(iit.flag_crea_maj_art,'2','UPDATE') ,--,TRANSACTION_TYPE
															DECODE(iit.flag_crea_maj_art,'2',vn_set_process_id_maj)--,SET_PROCESS_ID
                            );
            -- COMMIT;                                           
                   vn_nbre_record_maj := vn_nbre_record_maj + 1;
                   VN_NB_LIGNES_V2 :=VN_NB_LIGNES_V2+1;                   

            ELSIF p_type_org = 'FILLE' /* AND iit.flag_crea_maj_art_fil ='1'  AND iit.flag_crea_maj_art  IN ('1','2','0')*/ 
            THEN
                -- Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'ORGANISATION FILLE'); 

                
                -- Pour toutes les organisations filles
                FOR ICG IN CUR_ORG_FILLE(VG_ORG_ID_PRINCIPALE,VG_SECURITY_PROFILE_ID) 
                LOOP
                   --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'icg.organization_code :'||icg.organization_code);
                   IF  iit.flag_crea_maj_art = '1'  -- Création d'article
                   THEN
                       --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'iit.flag_crea_maj_art :'||iit.flag_crea_maj_art);
                       BEGIN
                           /*//---------------contôle nb lignes par lot-----------//*/
                           IF VN_NB_LIGNES_V3 = VG_NBLIGNES_LOT 
                           THEN
                                VN_NB_LIGNES_V3   := 0;
                                SELECT
                                    MTL_SYSTEM_ITEMS_INTF_SETS_S.NEXTVAL
                                INTO VN1_SET_PROCESS_ID_CR
                                FROM
                                    DUAL;

                           END IF;
                           /*//---------------fin contôle nb lignes par lot-----------//*/

                           INSERT INTO mtl_system_items_interface (
					     		  							 inventory_item_id,
								 							     organization_id,
															     creation_date,
															     created_by,
															     description,
															     segment1,
															     segment2,
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
															     PRIMARY_UNIT_OF_MEASURE,--primary_uom_code,
															     inventory_item_status_code,
															     process_flag,
															     template_id,
															     transaction_type,
															     set_process_id
														      ) 
											  	 VALUES 
												      		(
															     iit.inventory_item_id,
															     icg.organization_id,
															     SYSDATE,
															     VG_USER_ID,
															     iit.description_article ,   --description
															     iit.code_eclass_n4 ,--,SEGMENT1
															     substr(iit.code_article,instr(iit.code_article,'.',1) + 1), --,SEGMENT2 
															     iit.code_eclass_n4, --,ATTRIBUTE1
															     iit.code_compl_n1, --,ATTRIBUTE2
															     iit.code_compl_n2 ,--,ATTRIBUTE3
															     iit.code_compl_n3, --,ATTRIBUTE4
															     iit.code_compl_n4, --,ATTRIBUTE5
															     iit.code_compl_n5, --,ATTRIBUTE6
															     iit.code_compl_n6, --,ATTRIBUTE7 
															     iit.code_compl_n7, --,ATTRIBUTE8
															     iit.code_compl_n8, --,ATTRIBUTE9
															     iit.code_compl_n9, --,ATTRIBUTE10
                                   iit.unite_de_mesure,----,PRIMARY_UOM_CODE    iit.uom_code
															     iit.statut_article, -- ,INVENTORY_ITEM_STATUS_CODE
															     1 ,--,PROCESS_FLAG
															     VG_TEMPLATE_ID, --,TEMPLATE_ID
															     DECODE(iit.flag_crea_maj_art,'1','CREATE') ,--,TRANSACTION_TYPE
															     DECODE(iit.flag_crea_maj_art,'1',vn1_set_process_id_cr)--,SET_PROCESS_ID
                                   );
                       EXCEPTION
                       WHEN OTHERS
                       THEN
                                Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||sqlerrm);
                       END;        
                       --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||SQL%ROWCOUNT);                             
                       vn_nbre_record_cr := vn_nbre_record_cr + 1;                                  
                       VN_NB_LIGNES_V3:=VN_NB_LIGNES_V3+1;
             --   COMMIT;
                   ELSIF  iit.flag_crea_maj_art IN ('2','3') /*p_organization_id != VG_ORG_ID_PRINCIPALE  AND iit.flag_crea_maj_art_fil ='2' AND iit.flag_crea_maj_art ='2' */
                   THEN

                
                   -- Vérification que l'article existe bien dans l'organisation
                   
                        SELECT count(*)
                        INTO v_exist
                        FROM   MTL_SYSTEM_ITEMS_B
                        WHERE  inventory_item_id = iit.inventory_item_id
                        AND    Organization_id = icg.organization_id;
                        
                    
                        IF v_exist = 0               -- Création de l'article dans l'organisation fille, sinon rien à faire car données générées au niveau maître
                        THEN 

                            /*//---------------contôle nb lignes par lot-----------//*/

                            IF VN_NB_LIGNES_V4 = VG_NBLIGNES_LOT 
                            THEN
                               VN_NB_LIGNES_V4   := 0;
                               SELECT
                                   MTL_SYSTEM_ITEMS_INTF_SETS_S.NEXTVAL
                               INTO VN1_SET_PROCESS_ID_MAJ
                               FROM
                                   DUAL;                       
                            END IF;

                            /*//---------------fin contôle nb lignes par lot-----------//*/

                            INSERT INTO mtl_system_items_interface (
											     				inventory_item_id,
											    				organization_id,
											    				creation_date,
										    					created_by,
										    					description,
										    					segment1,
											    				segment2,
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
								    							PRIMARY_UNIT_OF_MEASURE,--primary_uom_code,
								    							inventory_item_status_code,
								    							process_flag,
								    							template_id,
							    								transaction_type,
							    								set_process_id
								    						) 
							    					 VALUES 
						    								(
							    								iit.inventory_item_id,
							    								icg.organization_id,
											    				SYSDATE,
											    				VG_USER_ID,
										    					iit.description_article ,   --description
										    					iit.code_eclass_n4 ,--,SEGMENT1
									    						substr(iit.code_article,instr(iit.code_article,'.',1) + 1), --,SEGMENT2 
									    						iit.code_eclass_n4, --,ATTRIBUTE1
									    						iit.code_compl_n1, --,ATTRIBUTE2
										    					iit.code_compl_n2 ,--,ATTRIBUTE3
										    					iit.code_compl_n3, --,ATTRIBUTE4
										    					iit.code_compl_n4, --,ATTRIBUTE5
										    					iit.code_compl_n5, --,ATTRIBUTE6
									    						iit.code_compl_n6, --,ATTRIBUTE7 
										    					iit.code_compl_n7, --,ATTRIBUTE8
											    				iit.code_compl_n8, --,ATTRIBUTE9
												    			iit.code_compl_n9, --,ATTRIBUTE10
                                  iit.unite_de_mesure,----,PRIMARY_UOM_CODE
										    					iit.statut_article, -- ,INVENTORY_ITEM_STATUS_CODE
										    					1 ,--,PROCESS_FLAG
											    				VG_TEMPLATE_ID, --,TEMPLATE_ID
											    				DECODE(iit.flag_crea_maj_art,'2','CREATE','3','CREATE') ,--,TRANSACTION_TYPE
										    					DECODE(iit.flag_crea_maj_art,'2',vn1_set_process_id_maj,'3', vn1_set_process_id_maj)--,SET_PROCESS_ID
                                );
                             vn_nbre_record_cr := vn_nbre_record_cr + 1;      
                             VN_NB_LIGNES_V4:=VN_NB_LIGNES_V4+1;                            
                        END IF;     
           --  COMMIT;                                           
                     END IF;
                 END LOOP;
            END IF;
            
            -- Mise à jour des enregistrements dans la table de travail
            IF   p_type_org = 'PRINCIPALE' 
            THEN
                UPDATE dka_ieomtl_system_items_tmp 
                SET
                    statut = 'INSERT_OI_P' 
                   ,last_updated_by =  vg_user_id
                   ,last_update_date = sysdate                              
                WHERE CURRENT OF cur_items;    
            ELSE
                UPDATE dka_ieomtl_system_items_tmp 
                SET
                    statut = 'INSERT_OI_F' 
                   ,last_updated_by =  vg_user_id
                   ,last_update_date = sysdate                              
                WHERE CURRENT OF cur_items;              
             END IF;
        END LOOP;
        CLOSE cur_items;
        COMMIT; 

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || vn_nbre_record_cr||' enregistrements insérés dans l''OI en CREATE');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || vn_nbre_record_maj||' enregistrements insérés dans l''OI en UPDATE');
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin insert_items_interface');

        fnd_stats.gather_table_stats('INV', 'MTL_SYSTEM_ITEMS_INTERFACE', percent => 100, degree => 8,  cascade => TRUE ); -- SEL : ajouter le parametre de parallelization à 8 pour l open-interface
          
    EXCEPTION
        WHEN OTHERS THEN
            p_retcode := 2;
            p_errbuf := 'INSERT_ITEMS_INTERFACE : ' || sqlerrm;         
    END insert_items_interface;

/* *************************************************************************
 * PROCEUDRE NAME : launch_items_oi
 *
 * DESCRIPTION
 *  Lancement OI des articles
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
/* ----------------------- -------------------------------------------------
 *
 *************************************************************************/
 
    PROCEDURE launch_items_oi (
        p_mode             IN NUMBER,
        p_type_org         IN VARCHAR2,
        p_errbuf           OUT VARCHAR2,
        p_retcode          OUT NUMBER
    ) IS

        vn_request_id     NUMBER;
        vn1_request_id    NUMBER;
        vv_phase          VARCHAR2(100);
        vv_status         VARCHAR2(100);
        vv_dev_phase      VARCHAR2(100);
        vv_dev_status     VARCHAR2(100);
        vv_message        VARCHAR2(100);
        vn_nbre           NUMBER;
        vn1_nbre          NUMBER;
        vv_mode           VARCHAR2(30);
        va_request_ids    IdTabTyp;        
        vn_requests_cnt   NUMBER(15) := 0;

        -----------------------------------------------------------------
        -- Curseur de lecture des set_process_id de la table interface --
        -----------------------------------------------------------------
        CURSOR cur_process (pv_mode VARCHAR2)
         IS 
         SELECT DISTINCT set_process_id
         FROM
               mtl_system_items_interface msii
         WHERE
               msii.process_flag = 1
				 AND ((p_type_org = 'PRINCIPALE' AND msii.organization_id = VG_ORG_ID_PRINCIPALE)
             OR (p_type_org = 'FILLE' AND msii.organization_id != VG_ORG_ID_PRINCIPALE))
				 AND msii.transaction_type = pv_mode;   
         
         Rec_Process               Cur_Process%ROWTYPE;      

    BEGIN
        fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Début Launch_Items_OI');
--        fnd_stats.gather_table_stats('INV', 'MTL_SYSTEM_ITEMS_B', percent => 100, cascade => TRUE );  	-- SEL
--        fnd_stats.gather_table_stats('INV', 'MTL_SYSTEM_ITEMS_TL', percent => 100, cascade => TRUE );     -- SEL
--        fnd_stats.gather_table_stats('INV', 'MTL_ITEM_REVISIONS_B', percent => 100, cascade => TRUE );    -- SEL                               

        IF p_mode = 1 THEN
            vv_mode := 'CREATE';
        ELSE
            vv_mode := 'UPDATE';

        END IF;


--              EXECUTE IMMEDIATE 'delete from MTL_SYSTEM_ITEMS_INTERFACE where transaction_type=''AUTO_CHILD''';
--              commit;

        IF p_type_org = 'PRINCIPALE' THEN

            BEGIN
                SELECT
                    COUNT('x')
                INTO vn_nbre
                FROM
                    dka_ieomtl_system_items_tmp xeiit
                WHERE
                    xeiit.statut = 'INSERT_OI_P'
					      AND request_id =VG_REQUEST_ID
                AND (
									( 
									   xeiit.flag_crea_maj_art = 1
											AND p_mode = 1 
									)
								OR (
								     xeiit.flag_crea_maj_art = 2
										AND p_mode = 2 
                                   )
                           );

            EXCEPTION
                WHEN no_data_found THEN
                    vn_nbre := 0;
            END;

            fnd_file.put_line(fnd_file.log, TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '|| vn_nbre||' enregistrements dans l''OI à traiter');
            -- Lancement du traitement seulement s'il y a des enregistrements à traiter   */

            IF vn_nbre != 0 THEN

            -----------------------------------------------------------    
            -- Boucle de lecture des jeux d'article de la table d'IO --

                OPEN Cur_Process (vv_mode);
                LOOP
                   FETCH Cur_Process INTO Rec_Process;
                   EXIT WHEN Cur_Process%NOTFOUND;

                ------------------------------------------------------------
                -- Lancement du traitement standard d'import des articles --
                ------------------------------------------------------------
                    vn_request_id := fnd_request.submit_request('INV'                         -- APPL
                                                               ,'INCOIN'                      -- PROG
                                                               ,NULL                          -- PROGRAM_NAME
                                                               ,NULL                          -- START
                                                               ,false                         -- SUB_REQUEST
                                                               ,VG_ORG_ID_PRINCIPALE          -- Id de l'organisation
                                                               ,2                             -- Toutes organisations (1: Oui; 2:Non)
                                                               ,1                             -- Valider articles (1: Oui; 2:Non)
                                                               ,1                             -- Traitement articles (1: Oui; 2:Non)
                                                               ,1                             -- Suppression des lignes traitées (1: Oui; 2:Non)
                                                               ,rec_process.set_process_id    -- Jeu d'articles à traiter
                                                               ,p_mode                        -- 1: Créer ; 2: Mettre à jour
                                                               ,vg_calc_stats                 -- Désactiver l'analyse des statistiques  (2 = Désactivé; 1 = Activé)
                                                                );
                    IF vn_request_id = 0 THEN
                        p_retcode := 2;
                        fnd_file.put_line(fnd_file.log,'ERREUR : Le traitement d''import des articles a échoué'
                                                         || chr(10)
                                                         || 'PROGRAMME  : INCOIN'
                                                         || chr(10));

                        fnd_file.put_line(fnd_file.output,'====> ERREUR : Le traitement d''import des articles a échoué');
                    ELSE
                        COMMIT;
                        fnd_file.put_line(fnd_file.log,'=> REQUEST ID= ' || vn_request_id);                                
                        vn_requests_cnt := vn_requests_cnt + 1;
                        va_request_ids (vn_requests_cnt):= vn_request_id; 
                    END IF;

                END LOOP;
                CLOSE Cur_Process;

                fnd_file.put_line(fnd_file.log,'WAIT FOR REQUEST');
                WHILE vn_requests_cnt > 0
                LOOP
                    IF NOT (Fnd_Concurrent.wait_for_request (va_request_ids (vn_requests_cnt), vg_tempo, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_message))
                    THEN
                        P_Errbuf  := Vv_Message;
                        Fnd_file.put_line(Fnd_file.LOG, TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '||'ERREUR : Attente de la fin du traitement d''import des articles dépassée : Fin du traitement' || CHR(10) ||
                                                        'MESSAGE : ' || Vv_Message || CHR(10) );
                    END IF;
                
                    IF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') 
                    THEN
                        fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '||'Fin normale du traitement '|| va_request_ids (vn_requests_cnt));            
                        Fnd_File.put_line(Fnd_File.LOG,'Statut de fin = ' || vv_dev_phase || '/' || vv_dev_status);
                    ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'WARNING')
                    THEN
                        Fnd_File.put_line (Fnd_File.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '|| 'Fin du traitement d''import des articles en warning '|| va_request_ids (vn_requests_cnt));
                    ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status != 'NORMAL')  
                    THEN
                        p_retcode := 2;
                        P_Errbuf  := 'ERREUR : Fin anormale du traitement d''import des articles : '||Vv_Message;
  
                        fnd_file.put_line(fnd_file.LOG, TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '||'ERREUR : Fin anormale du traitement d''import des articles '|| va_request_ids (vn_requests_cnt) || CHR(10) ||
                                                        'Phase/Statut : ' || vv_dev_phase || '/' || vv_dev_status || CHR(10) ||
                                                        'MESSAGE : ' || vv_message || CHR(10) );
                        Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement d''import des articles : ' || va_request_ids (vn_requests_cnt)); 
                        Fnd_File.put_line(Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement d''import des articles ');
                    END IF;          
                    vn_requests_cnt    := vn_requests_cnt - 1;
                END LOOP; 


            END IF;
       -- END IF;
        --commit;                     

--            EXECUTE IMMEDIATE 'delete from MTL_ITEM_REVISIONS_INTERFACE';
--             commit;

        elsIF  p_type_org = 'FILLE' THEN
            BEGIN
 
                SELECT
                    COUNT('x')
                INTO vn1_nbre
                FROM
                    dka_ieomtl_system_items_tmp xeiit
                WHERE
                    xeiit.statut = 'INSERT_OI_F'
					      AND request_id =VG_REQUEST_ID
                ;   

            EXCEPTION
                WHEN no_data_found THEN
                    vn1_nbre := 0;
            END;
            fnd_file.put_line(fnd_file.log, TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '|| vn1_nbre||' enregistrements dans l''OI à traiter');
            -- Lancement du traitement seulement s'il y a des enregistrements à traiter   */   

            IF vn1_nbre != 0 THEN

            -----------------------------------------------------------    
            -- Boucle de lecture des jeux d'article de la table d'IO --
            ----------------------------------------------------------- 
                OPEN Cur_Process (vv_mode);
                LOOP
                   FETCH Cur_Process INTO Rec_Process;
                   EXIT WHEN Cur_Process%NOTFOUND;

                ------------------------------------------------------------
                -- Lancement du traitement standard d'import des articles --
                ------------------------------------------------------------
                    vn1_request_id := fnd_request.submit_request('INV'                         -- APPL
                                                                   ,'INCOIN'                      -- PROG
                                                                   ,NULL                          -- PROGRAM_NAME
                                                                   ,NULL                          -- START
                                                                   ,false                         -- SUB_REQUEST
                                                                   ,NULL --p_organization_id            -- Id de l'organisation
                                                                   ,1 --2                             -- Toutes organisations (1: Oui; 2:Non)
                                                                   ,1                             -- Valider articles (1: Oui; 2:Non)
                                                                   ,1                             -- Traitement articles (1: Oui; 2:Non)
                                                                   ,1                             -- Suppression des lignes traitées (1: Oui; 2:Non)
                                                                   ,rec_process.set_process_id    -- Jeu d'articles à traiter
                                                                   ,p_mode                        -- 1: Créer ; 2: Mettre à jour
                                                                   ,vg_calc_stats                 -- Désactiver l'analyse des statistiques  (2 = Désactivé; 1 = Activé)
                                                                    );

                    IF vn1_request_id = 0 THEN
                        p_retcode := 2;
                        fnd_file.put_line(fnd_file.log,'ERREUR : Le traitement d''import des articles a échoué'
                                                         || chr(10)
                                                         || 'PROGRAMME  : INCOIN'
                                                         || chr(10));

                        fnd_file.put_line(fnd_file.output,'====> ERREUR : Le traitement d''import des articles a échoué');
                    ELSE  
                        commit;
                        fnd_file.put_line(fnd_file.log,'=> REQUEST ID= ' || vn1_request_id);                              
                        vn_requests_cnt := vn1_request_id + 1;
                        va_request_ids (vn_requests_cnt):= vn1_request_id;
                    END IF;

                END LOOP;
                CLOSE Cur_Process;

                fnd_file.put_line(fnd_file.log,'WAIT FOR REQUEST');
                WHILE vn_requests_cnt > 0
                LOOP
                    IF NOT (Fnd_Concurrent.wait_for_request (va_request_ids (vn_requests_cnt), vg_tempo, 0, vv_phase, vv_status, vv_dev_phase, vv_dev_status, vv_message))
                    THEN
                        P_Errbuf  := Vv_Message;
                        Fnd_file.put_line(Fnd_file.LOG, TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '||'ERREUR : Attente de la fin du traitement d''import des articles dépassée : Fin du traitement' || CHR(10) ||
                                                        'MESSAGE : ' || Vv_Message || CHR(10) );
                    END IF;
                
                    IF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') 
                    THEN
                        fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '||'Fin normale du traitement '|| va_request_ids (vn_requests_cnt));            
                        Fnd_File.put_line(Fnd_File.LOG,'Statut de fin = ' || vv_dev_phase || '/' || vv_dev_status);
                    ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'WARNING')
                    THEN
                        Fnd_File.put_line (Fnd_File.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '|| 'Fin du traitement d''import des articles en warning '|| va_request_ids (vn_requests_cnt));
                    ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status != 'NORMAL')  
                    THEN
                        p_retcode := 2;
                        P_Errbuf  := 'ERREUR : Fin anormale du traitement d''import des articles : '||Vv_Message;
  
                        fnd_file.put_line(fnd_file.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')|| ' - '|| 'ERREUR : Fin anormale du traitement d''import des articles '|| va_request_ids (vn_requests_cnt) || CHR(10) ||
                                                        'Phase/Statut : ' || vv_dev_phase || '/' || vv_dev_status || CHR(10) ||
                                                        'MESSAGE : ' || vv_message || CHR(10) );
                        Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement d''import des articles : ' || va_request_ids (vn_requests_cnt)); 
                        Fnd_File.put_line(Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement d''import des articles ');
                    END IF;          
                    vn_requests_cnt    := vn_requests_cnt - 1;
                END LOOP; 

            ELSE
                NULL;
            END IF;  
        END IF;

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin launch_items_oi');

EXCEPTION
WHEN OTHERS THEN
        p_retcode := 2;
        p_errbuf := 'LAUNCH_ITEMS_OI : ' || sqlerrm;         
END launch_items_oi;


/* *************************************************************************
 * PROCEDURE NAME : check_items_oi
 *
 * DESCRIPTION
 *  procédure pour vérifier la création de l'article dans oracle
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
/* ----------------------- -------------------------------------------------
 *
 *************************************************************************/

 procedure check_items_oi (
                            p_request_id       NUMBER,
                            p_type_org         VARCHAR2,
						              	p_status_old		   VARCHAR2,
                            p_status_new       VARCHAR2							
                          )

IS

BEGIN
     Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début check_items_oi');
     -- Cas des créations d'articles
     IF p_type_org = 'PRINCIPALE'
     THEN
              -- En création, récupération de l'Id de l'article 
              UPDATE  dka_ieomtl_system_items_tmp disi               
              SET     last_update_date = SYSDATE
                     ,last_updated_by = vg_user_id
                     ,inventory_item_id = (SELECT inventory_item_id 
                                           FROM   MTL_SYSTEM_ITEMS msii
                                           WHERE  disi.code_eclass_N4 = msii.segment1
                                           AND    substr(code_article,instr(disi.code_article,'.',1,1)+1,length(disi.code_article)-instr(disi.code_article,'.',1,1)) = msii.segment2
                                           AND    msii.organization_id = VG_ORG_ID_PRINCIPALE)
              WHERE
                      request_id=p_request_id
              AND     statut=p_status_old
              AND     flag_crea_maj_art = '1'
              ;   
              
              -- Mise à jour du statut pour les lignes importées avec succès dans Oracle
              UPDATE dka_ieomtl_system_items_tmp disi
              SET    statut = p_status_new
                    ,last_update_date = SYSDATE
                    ,last_updated_by = vg_user_id
              WHERE disi.statut = p_status_old
              AND   disi.request_id = p_request_id
              AND   disi.inventory_item_id IS NOT NULL
              AND   disi.flag_crea_maj_art = '1'; 

      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||SQL%ROWCOUNT||' enregistrements mis à INSERT_OA_P dans la table de travail car OK sur organisation principale');        
              
      ELSE
              -- Mise à jour du statut pour les lignes importées avec succès dans Oracle (Plus de lignes dans l'OI)
              UPDATE dka_ieomtl_system_items_tmp disi
              SET    statut = p_status_new
                    ,last_update_date = SYSDATE
                    ,last_updated_by = vg_user_id
              WHERE disi.statut = p_status_old
              AND   disi.request_id = p_request_id
              AND   disi.inventory_item_id IS NOT NULL
              AND   disi.flag_crea_maj_art = '1'
              AND   NOT EXISTS (SELECT '1' 
                                FROM   MTL_SYSTEM_ITEMS_INTERFACE msii
                                WHERE  disi.code_eclass_N4 = msii.segment1
                                AND    substr(code_article,instr(disi.code_article,'.',1,1)+1,length(disi.code_article)-instr(disi.code_article,'.',1,1)) = msii.segment2
                                AND    msii.organization_id != VG_ORG_ID_PRINCIPALE
                                );

             Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||SQL%ROWCOUNT||' enregistrements mis à INSERT_OA dans la table de travail car OK sur organisations filles');        

      END IF;
      
      -- Cas des mises à jour d'articles
      UPDATE dka_ieomtl_system_items_tmp disi
      SET    statut = p_status_new
            ,last_update_date = SYSDATE
            ,last_updated_by = vg_user_id
      WHERE disi.statut = p_status_old
      AND   disi.request_id = p_request_id
      AND   disi.inventory_item_id IS NOT NULL
      AND   disi.flag_crea_maj_art != '1'
      AND   NOT EXISTS (SELECT '1' 
                        FROM   MTL_SYSTEM_ITEMS_INTERFACE msii
                        WHERE  disi.code_eclass_N4 = msii.segment1
                        AND    substr(code_article,instr(disi.code_article,'.',1,1)+1,length(disi.code_article)-instr(disi.code_article,'.',1,1)) = msii.segment2
                        AND    (p_type_org = 'PRINCIPALE' AND msii.organization_id = VG_ORG_ID_PRINCIPALE)
                              OR (p_type_org = 'FILLE' AND msii.organization_id != VG_ORG_ID_PRINCIPALE)
                        );          
             
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||SQL%ROWCOUNT||' enregistrements mis à jour dans la table de travail car mises à jour OK dans Oracle');        
                                   
      commit;

      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin check_items_oi');


 EXCEPTION 
 WHEN OTHERS THEN 
            fnd_file.put_line(fnd_file.log,'CHECK_ITEMS_OI : '|| sqlerrm);            
 END;
      

    
/* *************************************************************************
 * PROCEDURE NAME : check_category_items_oi
 *
 * DESCRIPTION
 *  procédure pour vérifier l'affectation de l'article
 *
 * PARAMETERS
 * ==========
 * NAME                    DESCRIPTION
/* ----------------------- -------------------------------------------------
 *
 *************************************************************************/    
PROCEDURE check_category_items_oi 

IS
BEGIN

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début check_category_items_oi');
    
    UPDATE DKA_IEOMTL_SYSTEM_ITEMS_TMP xeiit
        SET statut = 'COMPLETE',
           last_update_date = sysdate,
           last_updated_by = VG_USER_ID

        where EXISTS (
              SELECT xeiit1.inventory_item_id 
                      FROM   DKA_IEOMTL_SYSTEM_ITEMS_TMP xeiit1,
                             MTL_ITEM_CATEGORIES mic,
                             MTL_CATEGORIES_B mc
                      WHERE  xeiit1.inventory_item_id = mic.inventory_item_id
                      AND    xeiit1.inventory_item_id = xeiit.inventory_item_id
                      AND    mic.category_id  = mc.category_id
                      AND    (mc.SEGMENT1||'.'||mc.SEGMENT2||'.'||mc.SEGMENT3||'.'||mc.SEGMENT4)=xeiit.categorie_principale
                      AND    mic.organization_id = VG_ORG_ID_PRINCIPALE
                      AND    mc.structure_id = VG_STRUCTURE_ID1
                      AND    (
                               (xeiit.categorie_secondaire_1 IS NOT NULL
                               AND EXISTS (SELECT 'x'
                                           FROM MTL_ITEM_CATEGORIES mic1,
                                                MTL_CATEGORIES_B mc1
                                           WHERE xeiit1.inventory_item_id = mic1.inventory_item_id
                                           AND   (mc1.SEGMENT1||'.'||mc1.SEGMENT2||'.'||mc1.SEGMENT3||'.'||mc1.SEGMENT4)=xeiit.categorie_secondaire_1
                                           AND    mc1.structure_id = VG_STRUCTURE_ID2
                                           AND    mic1.CATEGORY_SET_ID =VG_ITEM_CATEGORY_SET_ID2))
                             OR xeiit.categorie_secondaire_1 IS NULL)
                             
                      AND    (
                               (xeiit.categorie_secondaire_2 IS NOT NULL
                               AND EXISTS (SELECT 'x'
                                           FROM MTL_ITEM_CATEGORIES mic2,
                                                MTL_CATEGORIES_B mc2
                                           WHERE xeiit1.inventory_item_id = mic2.inventory_item_id
                                           AND   (mc2.SEGMENT1||'.'||mc2.SEGMENT2||'.'||mc2.SEGMENT3||'.'||mc2.SEGMENT4)=xeiit.categorie_secondaire_2
                                           AND    mc2.structure_id = VG_STRUCTURE_ID2
                                           AND    mic2.CATEGORY_SET_ID =VG_ITEM_CATEGORY_SET_ID2))
                             OR xeiit.categorie_secondaire_2 IS NULL)
                      AND    (
                               (xeiit.categorie_secondaire_3 IS NOT NULL
                               AND EXISTS (SELECT 'x'
                                           FROM MTL_ITEM_CATEGORIES mic3,
                                                MTL_CATEGORIES_B mc3
                                           WHERE xeiit1.inventory_item_id = mic3.inventory_item_id
                                           AND   (mc3.SEGMENT1||'.'||mc3.SEGMENT2||'.'||mc3.SEGMENT3||'.'||mc3.SEGMENT4)=xeiit.categorie_secondaire_3
                                           AND    mc3.structure_id = VG_STRUCTURE_ID2
                                           AND    mic3.CATEGORY_SET_ID =VG_ITEM_CATEGORY_SET_ID2))
                             OR xeiit.categorie_secondaire_3 IS NULL)
                      AND    (
                               (xeiit.categorie_secondaire_4 IS NOT NULL
                               AND EXISTS (SELECT 'x'
                                           FROM MTL_ITEM_CATEGORIES mic4,
                                                MTL_CATEGORIES_B mc4
                                           WHERE xeiit1.inventory_item_id = mic4.inventory_item_id
                                           AND   (mc4.SEGMENT1||'.'||mc4.SEGMENT2||'.'||mc4.SEGMENT3||'.'||mc4.SEGMENT4)=xeiit.categorie_secondaire_4
                                           AND    mc4.structure_id = VG_STRUCTURE_ID2
                                           AND    mic4.CATEGORY_SET_ID =VG_ITEM_CATEGORY_SET_ID2))
                             OR xeiit.categorie_secondaire_4 IS NULL)
                      AND    (
                               (xeiit.categorie_secondaire_5 IS NOT NULL
                               AND EXISTS (SELECT 'x'
                                           FROM MTL_ITEM_CATEGORIES mic5,
                                                MTL_CATEGORIES_B mc5
                                           WHERE xeiit1.inventory_item_id = mic5.inventory_item_id
                                           AND   (mc5.SEGMENT1||'.'||mc5.SEGMENT2||'.'||mc5.SEGMENT3||'.'||mc5.SEGMENT4)=xeiit.categorie_secondaire_5
                                           AND    mc5.structure_id = VG_STRUCTURE_ID2
                                           AND    mic5.CATEGORY_SET_ID =VG_ITEM_CATEGORY_SET_ID2))
                             OR xeiit.categorie_secondaire_5 IS NULL)
                      AND    xeiit1.statut = 'INSERT_OA'
                      AND    xeiit1.request_id =VG_REQUEST_ID                     
                      AND NOT EXISTS (SELECT distinct mici.inventory_item_id
                                      FROM MTL_ITEM_CATEGORIES_INTERFACE mici
                                           WHERE mici.inventory_item_id = xeiit1.inventory_item_id));
                    COMMIT;                    

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin check_category_items_oi');

EXCEPTION 
WHEN OTHERS THEN 
    fnd_file.put_line(fnd_file.log,'CHECK_CATEGORY_ITEMS_OI : '||sqlerrm);       
END check_category_items_oi;





 	------------------------------------------------------------------------------------
	--  Nom           : main
	--	Description		:	procédure principale

	--
	--  PARAMETRES    :
	--      P_ERRBUF  : Message erreur
	--      P_RETCODE : Code retour
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

   PROCEDURE MAIN (
    P_ERRBUF IN OUT VARCHAR2,
    P_RETCODE   OUT NUMBER
) IS
  --  ERREUR_PROGRAMME EXCEPTION;
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_Errbuf         VARCHAR2(2500);
    v_Retcode        NUMBER;
    Erreur_Programme EXCEPTION;    

BEGIN							 

       -----------------------------------------------
       -- PHASE D''INITIALISATION--
       -----------------------------------------------  
      FND_FILE.PUT_LINE(FND_FILE.LOG,CHR(10) );
      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                     || ' - '
                                     || 'PHASE D''INITIALISATION');

      INIT (v_Errbuf, v_Retcode);
      IF V_Retcode = 2 
      THEN
         P_ERRBUF  := v_Errbuf;
         P_RETCODE := v_Retcode;
         RAISE Erreur_Programme;
      END IF; 
    


      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                     || ' - '
                                     || 'FIN PHASE D''INITIALISATION');

      -----------------------------------------------
      -- PHASE DE SUPPRESSION DES DONNEES TRAITEES --
      -----------------------------------------------  

      fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'PHASE DE SUPPRESSION DES DONNEES TRAITEES');


      delete_complete_records(v_Errbuf,v_Retcode);
      IF v_Retcode = 2 
      THEN
         P_ERRBUF  := v_Errbuf;
         P_RETCODE := v_Retcode;
         RAISE Erreur_Programme;
      END IF; 

      FND_FILE.PUT_LINE(FND_FILE.LOG,CHR(10));

      
      ---------------------------------------------------------
      -- PHASE DE SUPPRESSION DES ARTICLES A NE PLUS TRAITER --
      ---------------------------------------------------------  
      fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'PHASE DE SUPPRESSION DES VIEUX REJETS');

      delete_old_error_records(v_Errbuf,v_Retcode);      
      IF v_Retcode = 2 
      THEN
         P_ERRBUF  := v_Errbuf;
         P_RETCODE := v_Retcode;
         RAISE Erreur_Programme;
      END IF; 

      --------------------------------------------------------------------------------
      -- PHASE DE SUPPRESSION DES ENREGISTREMENTS OBSOLETES (NOUVELLE VERSION RECUE --
      --------------------------------------------------------------------------------  

      delete_obsolete_records(v_Errbuf,v_Retcode);      
      IF v_Retcode = 2 
      THEN
         P_ERRBUF  := v_Errbuf;
         P_RETCODE := v_Retcode;
         RAISE Erreur_Programme;
      END IF; 
     
      ----------------------------------------------------------------------
      -- PHASE DE REINITIALISATION DES STATUTS POUR RECYCLAGE DES ERREURS --
      ----------------------------------------------------------------------  
      fnd_file.put_line(fnd_file.log,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'PHASE DE REINITIALISATION DES STATUTS');
      reinit_statut(v_Errbuf,v_Retcode);      
      IF v_Retcode = 2 
      THEN
         P_ERRBUF  := v_Errbuf;
         P_RETCODE := v_Retcode;
         RAISE Erreur_Programme;
      END IF; 
                
      
	    -------------------------------------
      -- PHASE DE CONROLE DES DONNEES --
      -------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || 'PHASE DE CONTROLE DES DONNEES');

      DKA_IEOMTL_CODARTINT_PKG.CONTROLE_DONNEES(P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
         P_ERRBUF  := v_Errbuf;
         P_RETCODE := v_Retcode;
         RAISE Erreur_Programme;
      END IF;


      FND_FILE.PUT_LINE(FND_FILE.LOG,CHR(10));

       /* *************************************************************************************************
       *PHASE D'ALIMENTATION ET MISE À JOUR DES JEUX DE VALEURS RELATIFS AUX SEGMENTS DE LA CLÉ ARTICLE
       *Stockage et mise à jour de la hiérarchie eCl@ss 
       ***************************************************************************************************/

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || '--PHASE D''ALIMENTATION ET MISE À JOUR DES JEUX DE VALEURS RELATIFS AUX SEGMENTS DE LA CLÉ ARTICLE,STOCKAGE ET MISE À JOUR DE LA HIÉRARCHIE ECL@SS'
                                             );

      ALIMENTATION_JEUX_VALEURS(P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
           P_ERRBUF  := v_Errbuf;
           P_RETCODE := v_Retcode;
          RAISE Erreur_Programme;
      END IF;        
 
      FND_FILE.PUT_LINE(FND_FILE.LOG,CHR(10));
      --------------------------------------------------------------
      -- PHASE D'INSERTION DANS L'OI POUR ORGANISATION PRINCIPALE --
      --------------------------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || 'PHASE D''ALIMENTATION DE L''OPEN INTERFACE POUR L''ORGANISATION PRINCIPALE');
      INSERT_ITEMS_INTERFACE('PRINCIPALE','VALIDATED',P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
           P_ERRBUF  := v_Errbuf;
           P_RETCODE := v_Retcode;
          RAISE Erreur_Programme;
      END IF;

      --------------------------------------------------------------------------------------
      -- PHASE D'IMPORT PAR L'OPEN INTERFACE DANS ORGANISATION PRINCIPALE - MODE CREATION --
      --------------------------------------------------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || 'PHASE D''IMPORT PAR L''OPEN INTERFACE DANS ORGANISATION PRINCIPALE - MODE CREATION');

      LAUNCH_ITEMS_OI(1,'PRINCIPALE',P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
           P_ERRBUF  := v_Errbuf;
           P_RETCODE := v_Retcode;
          RAISE Erreur_Programme;
      END IF;

        
      --------------------------------------------------------------------------------------
      -- PHASE D'IMPORT PAR L'OPEN INTERFACE DANS ORGANISATION PRINCIPALE - MODE UPDATE   --
      --------------------------------------------------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || 'PHASE D''IMPORT PAR L''OPEN INTERFACE DANS ORGANISATION PRINCIPALE - MODE UPDATE');

      LAUNCH_ITEMS_OI(2,'PRINCIPALE',P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
           P_ERRBUF  := v_Errbuf;
           P_RETCODE := v_Retcode;
          RAISE Erreur_Programme;
      END IF;

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || 'PHASE DE CONTROLE DE L''IMPORT DANS ORACLE POUR L''ORGANISATION PRINCIPALE');

      DKA_IEOMTL_CODARTINT_PKG.check_items_oi (
                                    VG_request_id ,
                                    'PRINCIPALE' ,
                                    'INSERT_OI_P',
                                    'INSERT_OA_P'
                                );

      --------------------------------------------------------------
      -- PHASE D'INSERTION DANS L'OI POUR ORGANISATIONS FILLES    --
      --------------------------------------------------------------
      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                                 || ' - '
                                                 || 'PHASE D''IMPORT PAR L''OPEN INTERFACE DANS LES ORGANISATIONS FILLES - MODE CREATION'
                                                 );
      INSERT_ITEMS_INTERFACE('FILLE', 'INSERT_OA_P', P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
            P_ERRBUF  := v_Errbuf;
            P_RETCODE := v_Retcode;
            RAISE Erreur_Programme;
      END IF;
      ---------------------------------------------------------------------------------------
      -- PHASE D'IMPORT PAR L'OPEN INTERFACE DANS LES ORGANISATIONS FILLES - MODE CREATION --
      ---------------------------------------------------------------------------------------


      LAUNCH_ITEMS_OI(1,'FILLE',P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
          P_ERRBUF  := v_Errbuf;
          P_RETCODE := v_Retcode;
          RAISE Erreur_Programme;
      END IF;


      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                                 || ' - '
                                                 || 'PHASE DE CONTROLE DE L''IMPORT DANS ORGANISATIONS FILLES'
                                                 );
      DKA_IEOMTL_CODARTINT_PKG.check_items_oi (
                                    VG_request_id ,
                                    'FILLE',
                                    'INSERT_OI_F',
                                    'INSERT_OA'
                                );

      --------------------------------------------------------------------------------------
      -- PHASE D'AFFECTATION DES CATEGORIES AU ARTICLES                                   --
      --------------------------------------------------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || 'PHASE D''AFFECTAION DES CATEGORIES AU ARTICLES');

      INSERT_ASSIGN_CATEGORY_ITEM(P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
            P_ERRBUF  := v_Errbuf;
            P_RETCODE := v_Retcode;
            RAISE Erreur_Programme;
      END IF;
            
      --------------------------------------------------------------------------------------
      -- PHASE D'IMPORT DE L'AFFECTATION DES CATEGORIES PAR L'OPEN INTERFACE              --
      --------------------------------------------------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || ' PHASE D''IMPORT DE L''AFFECTATION DES CATEGORIES PAR L''OPEN INTERFACE');

      LAUNCH_ITEM_CATEGORY(P_ERRBUF,P_RETCODE);
      IF v_Retcode = 2 
      THEN
            P_ERRBUF  := v_Errbuf;
            P_RETCODE := v_Retcode;
            RAISE Erreur_Programme;
      END IF;
        
      --------------------------------------------------------------------------------------
      -- PHASE DE VERIFICATION DE L'AFFECATION DES CATEGORIES                             --
      --------------------------------------------------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || ' PHASE DE VERIFICATION DE L''AFFECATION DES CATEGORIES ');
      CHECK_CATEGORY_ITEMS_OI;

      --------------------------------------------------------------------------------------
      -- PHASE  FINAL : BILAN DU TRAITEMENT                                               --
      --------------------------------------------------------------------------------------

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || 'BILAN DU TRAITEMENT');

      BILAN(P_ERRBUF,P_RETCODE);

      FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                             || ' - '
                                             || 'FIN DU TRAITEMENT');
            --------------------------------------------------------------------------------------
                                        -- FIN TRAITEMENT --
            --------------------------------------------------------------------------------------

      IF P_Retcode = 2
      THEN
           p_errbuf := 'ATTENTION : Traitement standard en ERREUR ou AVERTISSEMENT : '||p_errbuf;
      ELSIF (vg_nb_art_rej_valid > 0 
          OR vg_nb_art_err_int > 0
          OR vg_nb_art_err_aff_cat > 0
             )
      THEN
           p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
           p_retcode := 1;
      ELSE
           p_errbuf := 'Fin normale du traitement - Aucun rejet.';
           p_retcode := 0;
      END IF;


    EXCEPTION
        WHEN Erreur_Programme
        THEN
            p_retcode   := 2;
            p_errbuf    := v_Errbuf;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure main : EXCEPTION Erreur_Traitement ');        
            Fnd_File.put_line (Fnd_File.OUTPUT, '<- Fin de la procédure main : EXCEPTION Erreur_Traitement ');     
       WHEN OTHERS 
       THEN
           fnd_concurrent.af_rollback;
           p_retcode := 2;
           p_errbuf := SQLERRM;
    END main;


 	------------------------------------------------------------------------------------
	--  Nom           : Bilan
	--	Description		:	Bilan du traitement

	--
	--  PARAMETRES    :
	--      P_ERRBUF  : Message erreur
	--      P_RETCODE : Code retour
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------
    PROCEDURE bilan (P_Errbuf            OUT VARCHAR2,
                     P_Retcode           OUT NUMBER
                     )
    IS 
        CURSOR Cur_Data_Error  IS
            SELECT disi.file_name,
                   disi.line_num,
                   disi.code_article,
                   die.phase,
                   die.description_error
            FROM   DKA_IEOMTL_SYSTEM_ITEMS_TMP disi,
                   DKA_IEOMTL_ERROR die
            WHERE  nvl(die.code_article,'*') = nvl(disi.code_article,'*')
            AND    die.line_num = disi.line_num
            AND    die.file_name = disi.file_name
            AND    disi.statut = 'REJECTED'
            UNION
            SELECT disi.file_name,
                   disi.line_num,
                   disi.code_article,
                   'OI Articles' phase,
                   mie.message_name description_error
            FROM   DKA_IEOMTL_SYSTEM_ITEMS_TMP disi,
                   MTL_SYSTEM_ITEMS_INTERFACE msii,
                   MTL_INTERFACE_ERRORS mie
            WHERE  disi.code_article = msii.segment1 || msii.segment2
            AND    mie.transaction_id = msii.transaction_id     
            AND    mie.table_name = 'MTL_SYSTEM_ITEMS_INTERFACE'          
            UNION
            SELECT disi.file_name,
                   disi.line_num,
                   disi.code_article,
                   'OI Catégories' phase,
                   mie.message_name description_error
            FROM   DKA_IEOMTL_SYSTEM_ITEMS_TMP disi,
                   MTL_ITEM_CATEGORIES_INTERFACE msii,
                   MTL_INTERFACE_ERRORS mie
            WHERE  disi.INVENTORY_ITEM_ID = msii.INVENTORY_ITEM_ID
            AND    mie.transaction_id = msii.transaction_id     
            AND    mie.table_name = 'MTL_ITEM_CATEGORIES_INTERFACE'             
            ORDER BY file_name, line_num
            
            ;

        Rec_Data_Error             Cur_Data_Error%ROWTYPE;


    BEGIN


        SELECT COUNT(tmp.INVENTORY_ITEM_ID)
        INTO vg_nb_art_err_aff_cat
        FROM DKA_IEOMTL_SYSTEM_ITEMS_TMP TMP
        WHERE  TMP.STATUT IN ('INSERT_OI_P', 'INSERT_OI_F');

        SELECT COUNT(tmp.INVENTORY_ITEM_ID)
        INTO vg_nb_art_err_aff_cat
        FROM DKA_IEOMTL_SYSTEM_ITEMS_TMP TMP
        WHERE  TMP.STATUT = 'INSERT_OA';

        SELECT COUNT(tmp.INVENTORY_ITEM_ID)
        INTO vg_nb_art_tot_traite
        FROM DKA_IEOMTL_SYSTEM_ITEMS_TMP TMP
        WHERE TMP.STATUT = 'COMPLETE';


        fnd_file.put_line(fnd_file.OUTPUT,'Nombre d''articles nouvellement chargés : '||vg_nb_art_renouv_charge);
        fnd_file.put_line(fnd_file.OUTPUT,'Nombre d''articles à recycler : '||vg_nb_art_recycle);
        fnd_file.put_line(fnd_file.OUTPUT,'Nombre d''articles rejetés à l''issu de la phase de validation : '||vg_nb_art_rej_valid);
        fnd_file.put_line(fnd_file.OUTPUT,'Nombre d''articles validés à l''issu de la phase de validation : '||vg_nb_art_val_valid);
        fnd_file.put_line(fnd_file.OUTPUT,'Nombre d''articles en erreur dans l''Open Interface des articles : '||vg_nb_art_err_int);
        fnd_file.put_line(fnd_file.OUTPUT,'Nombre d''articles pour lesquels l''affectation des catégories s''est terminée en erreur :'||vg_nb_art_err_aff_cat);
        fnd_file.put_line(fnd_file.OUTPUT,'Nombre d''articles totalement traités : '||vg_nb_art_tot_traite);



        -----------------------------------------------------------    
        -- Boucle de lecture des données de la table des erreurs --
        -----------------------------------------------------------   
        Fnd_File.put_line (Fnd_File.LOG,'START BOUCLE ARTICLES EN ERREUR');
        Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||'******************************************************************************');
        Fnd_File.put_line (Fnd_File.OUTPUT, '***************                LISTE DES REJETS                ***************');
        Fnd_File.put_line (Fnd_File.OUTPUT, '******************************************************************************'||CHR(10));
        OPEN Cur_Data_Error;
        FETCH Cur_Data_Error INTO Rec_Data_Error;
        
        IF (Cur_Data_Error%FOUND) THEN
        
           Fnd_File.put_line (Fnd_File.OUTPUT, 'Nom fichier ;N° ligne ;Code article;Phase rejet ;Message d''erreur');
           Fnd_File.put_line (Fnd_File.OUTPUT, Rec_Data_Error.FILE_NAME||';'||Rec_Data_Error.LINE_NUM||';'||Rec_Data_Error.code_article||';'||Rec_Data_Error.phase||';'||Rec_Data_Error.description_error);
        
           LOOP
               FETCH Cur_Data_Error INTO Rec_Data_Error;
               EXIT WHEN Cur_Data_Error%NOTFOUND;  
                   Fnd_File.put_line (Fnd_File.OUTPUT, Rec_Data_Error.FILE_NAME||';'||Rec_Data_Error.LINE_NUM||';'||Rec_Data_Error.code_article||';'||Rec_Data_Error.phase||';'||Rec_Data_Error.description_error);
           END LOOP;
        
        ELSE
           Fnd_File.put_line (Fnd_File.OUTPUT, 'Aucun Article en erreur');        

        END IF; 
        CLOSE Cur_Data_Error;

    EXCEPTION
       WHEN OTHERS 
       THEN
           p_retcode := 2;
           p_errbuf := SQLERRM;
    END ;
	------------------------------------------------------------------------------------
	--  Nom           : check_code_isNumeric
	--	Description		:	fonction permettant de vérifier si un code est numérique.

	--
	--  PARAMETRES    :
	--      p_code  : la valeur
	
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------
	FUNCTION check_code_isNumeric (p_code VARCHAR2)
	RETURN VARCHAR2
	IS 
		v_val VARCHAR2 (50);
	BEGIN
		BEGIN
			SELECT 
			  DKA_TOOLS_PKG.numeric_check (p_code) 
		    INTO v_val 
			FROM DUAL;
		EXCEPTION 
    WHEN OTHERS THEN 
		v_val :='ER';
		END;
    
    IF v_val != '0'
    THEN 
        v_val :='ER';
    END IF;
        
	RETURN v_val;
	END;

END dka_ieomtl_codartint_pkg;

/
SHOW ERRORS

EXIT