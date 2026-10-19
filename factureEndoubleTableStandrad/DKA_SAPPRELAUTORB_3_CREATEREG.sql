/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
--  $Id: DKA_AUTO_RJETVADEDUC.sql 683 2008-05-21 13:53:37Z CORP\jjardez $
--  CAP GEMINI
--  PROJET           : DALKIA Oracle Applications
--  NOM              : DKA_RJETVADEDUC.sql
--  DESCRIPTION      : Lancement automatique du traitement DKA_RJETVADEDUC
---
--- AUTEUR           : CG
--- DATE DE CREATION : 16/10/2003
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 02/09/2004 STI Portage specifique PHENIX 2004
---                Modification responsabilites
--- 28/10/2005 EB  Modification du positionnement dans le contexte O.A
--- 15/05/2008 JDE CSP Portabilité 2008
--- 30/01/2017 YWA artf2083525 : ETA057 : TVA : Déclaration de la TVA déductible : Pas de résultats
--- 08/02/2018 MEG artf2361551 : Automatisation Etats de TVA : ETA026 - SPE077 - ETA084 - ETA081 - ETA057
--- 08/10/2018 MEN artf2416369 : EDB207 - Rajout de l'Unité d'Organisation et le Nom de la Société dans le Nom du programme
--- 03/04/2019 SFA artf07235613: INC0306496 - Correctif états de TVA
--- 23/04/2019 SFA artf07235613: INC0306496 - Correctif états de TVA
--- 21/09/2021 NBO EDB280B_Archivage et envoi des états TVA au format txt dans un fichier zip par mail aux régions
--- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
--- 19/05/2022 SELO EDB280C
--- 31/08/2022 IBA  artf07540527 EDB347-Automatisation des états de TVA - Lancement des états de TVA si UO présente dans profil sécurité DKA_TOUT
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);
VAR utl_file_name VARCHAR2(512);

DECLARE
    vv_prog_name                     VARCHAR2 (30)  := 'DKA_RJETVADEDUC';
    vn_tempo                         NUMBER         := 20;
    vv_user                          VARCHAR2 (80);
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
    vn_retcode_r                     NUMBER         := 0;  -- PHENIX 2004
    vn_traitement                    NUMBER         := 0;
    vn_indice                        NUMBER;
    vn_prog_application_id           NUMBER (15);
    vv_prog_application_short_name   VARCHAR2 (50);
    vn_program_id                    NUMBER (15);
    vn_responsibility_id             NUMBER (15);
    vn_application_id                NUMBER (15);
    vn_user_id                       NUMBER (15);
    vn_request_id                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vv_responsibility_ref            fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility                fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility_name           fnd_responsibility.responsibility_key%TYPE;
    rec_param                        dka_parameters%ROWTYPE;
    pn_retcode                       NUMBER;
    vb_lancement_trt                 BOOLEAN;
    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
	vn_conc_request_id               NUMBER (15);
    vv_archivage                     VARCHAR2(30) := 'DKA_ETATVAHORSDALKIA';
    vf_myfile                        UTL_FILE.FILE_TYPE;
    K_DIRECTORY                      CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
    vv_utl_file_dir                  VARCHAR2(250);

    TYPE myrecord IS RECORD (
         request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;

    -- Début CSP Portabilité 2008
    -- Curseur de sélection des sociétés pour les traitements annuels
    -----------------------------------------------------------------
    CURSOR cur_soc IS
        /*	
        SELECT DISTINCT digi.company_code    company_name,
               digi.mainoffice_cost_center  user_name
        FROM   (select distinct tmp.company_code, tmp.company_type 
                from   dka_ibdsoc_i00dgic tmp
                ) di,               
               dka_ibdsoc_general_info  digi,
               fnd_flex_value_sets sets,
               fnd_flex_values_vl val              
        WHERE  1=1
        AND    di.company_code(+) = digi.company_code 
        AND    (NVL(di.company_type,'0') = '0' or to_number(NVL(di.company_code,0)) >        2999)
        and    sets.flex_value_set_id = val.flex_value_set_id
        and    val.enabled_flag = 'Y'
        and    val.compiled_value_attributes = 'Y'||chr(10)||'Y'
        and    val.summary_flag = 'N'
        and    val.FLEX_VALUE = digi.company_code
        and    sets.flex_value_set_id in (
                                        select fifs.flex_value_set_id
                                        from org_organization_definitions ood,
                                        fnd_id_flex_segments fifs,
                                        fnd_segment_attribute_values fsav
                                        where ood.organization_id = fnd_profile.value('ORG_ID')
                                        and ood.chart_of_accounts_id = fsav.id_flex_num
                                        and fifs.application_id = fsav.application_id
                                        and fifs.id_flex_code = fsav.id_flex_code
                                        and fifs.id_flex_num = fsav.id_flex_num
                                        and fifs.application_column_name = fsav.application_column_name
                                        and fsav.id_flex_code = 'GL#'
                                        and fsav.application_id = 101
                                        and fsav.segment_attribute_type = 'GL_BALANCING'
                                        and fsav.attribute_value = 'Y');*/ --RGH
										


		        /*SELECT DISTINCT val.FLEX_VALUE    company_name,
								val.ATTRIBUTE2   user_name
				FROM   fnd_flex_value_sets sets,
					   fnd_flex_values_vl val              
				WHERE  sets.flex_value_set_id = val.flex_value_set_id
				AND    val.enabled_flag = 'Y'
				AND    val.compiled_value_attributes = 'Y'||chr(10)||'Y'
				AND    val.summary_flag = 'N'
				AND    val.VALUE_CATEGORY ='DAOPCCF_STE'; --RGH  */ 
        --- 08/10/2018 Rajout du nom de la société         
        SELECT DISTINCT val.FLEX_VALUE    company_name,
               val.ATTRIBUTE2   user_name,
               gl.ledger_id  , val.attribute2 || val.flex_value ||' - ' || gl.name society_name
        FROM   fnd_flex_value_sets sets,
               fnd_flex_values_vl val,
               hr_operating_units hou,
               gl_ledgers          gl,
			   per_security_organizations   pso -- IBA artf07540527
        WHERE  sets.flex_value_set_id = val.flex_value_set_id
        AND    val.enabled_flag = 'Y'
        AND    val.compiled_value_attributes = 'Y'||chr(10)||'Y'
        AND    val.summary_flag = 'N'
        and    hou.name = val.ATTRIBUTE2||val.FLEX_VALUE
        and    hou.set_of_books_id= gl.ledger_id
        AND    gl.ledger_category_code = 'PRIMARY'
		AND    val.FLEX_VALUE <> '0001'  --SFA artf07235613
        AND    val.VALUE_CATEGORY ='DAOPCCF_STE' --YWA artf2083525         
		--< IBA  artf07540527 EDB347
			 AND pso.organization_id = hou.organization_id
             AND pso.security_profile_id = 63;
		--> IBA  artf07540527 EDB347				
						
						
    --vv_responsibility_key            dka_parameters.parameter_name%TYPE  := 'AP_RESPONSIBILITY_KEY_' || fnd_profile.value('ORG_ID');
    vv_responsibility_key            fnd_responsibility.responsibility_key%TYPE  := 'DKA_ETATS';--RGH 
    -- Fin CSP Portabilité 2008
    rec_soc                          cur_soc%ROWTYPE;
	
	--- 21/09/2021 NBO EDB280B_Archivage et envoi des états TVA au format txt dans un fichier zip par mail aux régions
    CURSOR cur_directory (p_path VARCHAR, p_request_id NUMBER) IS
    SELECT DISTINCT 'mkdir -p $REP_DATA/editions_legales/'||p_path||'/' || to_char(gps.start_date,'RRRRMM') || '/' || ffv.attribute2 line
      FROM fnd_concurrent_requests    fcr,
           gl_ledgers                 gl,
           fnd_user                   fu,
           fnd_concurrent_programs_vl fcp,
           gl_period_statuses         gps,
--- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
           fnd_flex_value_sets        ffvs,
           fnd_flex_values            ffv
     WHERE fcr.parent_request_id = p_request_id
       AND fcr.argument1 = gl.ledger_id
       AND gl.short_name != '0001'
       AND fcr.requested_by = fu.user_id
       AND fcp.concurrent_program_id = fcr.concurrent_program_id
       AND gps.set_of_books_id = gl.ledger_id
       AND gps.application_id = 101
       AND to_date(fcr.argument2, 'RRRR/MM/DD HH24:MI:SS') BETWEEN
           gps.start_date AND gps.end_date
       --- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
       AND ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
       AND ffv.flex_value = gl.short_name;
           
    rec_directory             cur_directory%ROWTYPE;

    CURSOR cur_file (p_path VARCHAR, p_request_id NUMBER) IS
    SELECT 'cp ' || fcr.OUTFILE_NAME || ' $REP_DATA''/editions_legales/'||p_path||'/' || to_char(gps.start_date,'RRRRMM') || '/' || ffv.attribute2 || '/'
        --  || ffv.attribute2 || '_' || fcr.request_id || '_' || REPLACE(fcr.description,'''', ' ') || '_' ||
        --   REPLACE(REPLACE(REPLACE(fcp.user_concurrent_program_name, ':', '-'),'''',''''''),'é','e') || '_' ||
        --   gps.period_name || '.txt''' line
		|| ffv.attribute2 || '_' || 
		substr(REPLACE(fcr.description,'''', ' '), 4, 4)|| '_' || 
        replace(REPLACE(fcr.description,'', ' '),'''','') || '_' ||
		REPLACE(REPLACE(fcp.user_concurrent_program_name, ':', '-'),'é','e')  || '_' ||
        to_char(fcr.request_id) || '_' || 
        gps.period_name	|| '.txt''' line 		   
		   
      FROM fnd_concurrent_requests    fcr,
           gl_ledgers                 gl,
           fnd_user                   fu,
           fnd_concurrent_programs_vl fcp,
           gl_period_statuses         gps,
--- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
           fnd_flex_value_sets        ffvs,
           fnd_flex_values            ffv
     WHERE fcr.parent_request_id = p_request_id
       AND fcr.argument1 = gl.ledger_id
       AND gl.short_name != '0001'
       AND fcr.requested_by = fu.user_id
       AND fcp.concurrent_program_id = fcr.concurrent_program_id
       AND gps.set_of_books_id = gl.ledger_id
       AND gps.application_id = 101
       AND to_date(fcr.argument2, 'RRRR/MM/DD HH24:MI:SS') BETWEEN
           gps.start_date AND gps.end_date
       --- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
       AND ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
       AND ffv.flex_value = gl.short_name;
	
	rec_file             cur_file%ROWTYPE;


    -------------------------------------------------------
    -- Procédure de positionnement dans le contexte O.A. --
    -------------------------------------------------------
    PROCEDURE positionnement_contexte ( pv_user_name IN     VARCHAR2,
                                        pv_resp_name IN     VARCHAR2,
                                        pv_prog_name IN     VARCHAR2,
                                        pn_retcode      OUT NUMBER,
                                        pv_errbuf       OUT VARCHAR2 )
    IS
    BEGIN
        -- Recherche de l'utilisateur
        -----------------------------
        BEGIN
			
            SELECT user_id
            INTO   vn_user_id
            FROM   fnd_user
            WHERE  user_name = NVL(pv_user_name, 'EXPLOITATION');

        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees a l''utilisateur';
                 RETURN;
        END;
        

                 -- Récupération des informations liées a la responsabilite
        ----------------------------------------------------------
        BEGIN
            SELECT fr.responsibility_id,
                   fr.application_id,
                   fr.responsibility_key
            INTO   vn_responsibility_id,
                   vn_application_id,
                   vv_responsibility      
            FROM   fnd_responsibility fr
            WHERE  fr.responsibility_key = pv_resp_name;

        EXCEPTION
           WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees a la responsabilite';
                 RETURN;
        END;

        -- Récupération des informations du traitement
        ----------------------------------------------
        BEGIN
            SELECT fcp.application_id,
                   fa.application_short_name,
                   fcp.concurrent_program_id
            INTO   vn_prog_application_id,
                   vv_prog_application_short_name,
                   vn_program_id
            FROM   fnd_concurrent_programs fcp,
                   fnd_application fa
            WHERE  fcp.concurrent_program_name = vv_prog_name
            AND    fa.application_id           = fcp.application_id;
   
        EXCEPTION
            WHEN OTHERS THEN
                 pn_retcode := 2;
                 pv_errbuf  := '==> Impossible de trouver les informations liees au programme';
                 RETURN;
        END;

        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
        --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || Fnd_Profile.value ('ICX_LANGUAGE') || '''';
		EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=French';
        pn_retcode := 0; -- PHENIX 2004

    END;


    ------------------------------------------
    -- Fonction de soumission du traitement --
    ------------------------------------------
    PROCEDURE soumission_traitement (soc_name IN VARCHAR2) IS
    BEGIN
        vn_request_id := Fnd_Request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                      vv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                      --NULL,                         -- PROGRAM NAME  --- 08/10/2018 ajout de paramètre de la nom société
                                                      soc_name,                       -- PROGRAM NAME
                                                      NULL,                           -- START
                                                      FALSE,                          -- SUB REQUEST
                                                      Dka_Tools_Pkg.tab_request_params(1), --ARGUMENT1
                                                      Dka_Tools_Pkg.tab_request_params(2), --ARGUMENT2
                                                      Dka_Tools_Pkg.tab_request_params(3), --ARGUMENT3
                                                      Dka_Tools_Pkg.tab_request_params(4), --ARGUMENT4
                                                      Dka_Tools_Pkg.tab_request_params(5), --ARGUMENT5
                                                      Dka_Tools_Pkg.tab_request_params(6), --ARGUMENT6
                                                      Dka_Tools_Pkg.tab_request_params(7), --ARGUMENT7
                                                      Dka_Tools_Pkg.tab_request_params(8), --ARGUMENT8
                                                      Dka_Tools_Pkg.tab_request_params(9), --ARGUMENT9
                                                      Dka_Tools_Pkg.tab_request_params(10), --ARGUMENT10
                                                      Dka_Tools_Pkg.tab_request_params(11), --ARGUMENT11
                                                      Dka_Tools_Pkg.tab_request_params(12), --ARGUMENT12
                                                      Dka_Tools_Pkg.tab_request_params(13), --ARGUMENT13
                                                      Dka_Tools_Pkg.tab_request_params(14), --ARGUMENT14
                                                      Dka_Tools_Pkg.tab_request_params(15), --ARGUMENT15
                                                      Dka_Tools_Pkg.tab_request_params(16), --ARGUMENT16
                                                      Dka_Tools_Pkg.tab_request_params(17), --ARGUMENT17
                                                      Dka_Tools_Pkg.tab_request_params(18), --ARGUMENT18
                                                      Dka_Tools_Pkg.tab_request_params(19), --ARGUMENT19
                                                      Dka_Tools_Pkg.tab_request_params(20), --ARGUMENT20
                                                      Dka_Tools_Pkg.tab_request_params(21), --ARGUMENT21
                                                      Dka_Tools_Pkg.tab_request_params(22), --ARGUMENT22
                                                      Dka_Tools_Pkg.tab_request_params(23), --ARGUMENT23
                                                      Dka_Tools_Pkg.tab_request_params(24), --ARGUMENT24
                                                      Dka_Tools_Pkg.tab_request_params(25), --ARGUMENT25
                                                      Dka_Tools_Pkg.tab_request_params(26), --ARGUMENT26
                                                      Dka_Tools_Pkg.tab_request_params(27), --ARGUMENT27
                                                      Dka_Tools_Pkg.tab_request_params(28), --ARGUMENT28
                                                      Dka_Tools_Pkg.tab_request_params(29), --ARGUMENT29
                                                      Dka_Tools_Pkg.tab_request_params(30), --ARGUMENT30
                                                      Dka_Tools_Pkg.tab_request_params(31), --ARGUMENT31
                                                      Dka_Tools_Pkg.tab_request_params(32), --ARGUMENT32
                                                      Dka_Tools_Pkg.tab_request_params(33), --ARGUMENT33
                                                      Dka_Tools_Pkg.tab_request_params(34), --ARGUMENT34
                                                      Dka_Tools_Pkg.tab_request_params(35), --ARGUMENT35
                                                      Dka_Tools_Pkg.tab_request_params(36), --ARGUMENT36
                                                      Dka_Tools_Pkg.tab_request_params(37), --ARGUMENT37
                                                      Dka_Tools_Pkg.tab_request_params(38), --ARGUMENT38
                                                      Dka_Tools_Pkg.tab_request_params(39), --ARGUMENT39
                                                      Dka_Tools_Pkg.tab_request_params(40), --ARGUMENT40
                                                      Dka_Tools_Pkg.tab_request_params(41), --ARGUMENT41
                                                      Dka_Tools_Pkg.tab_request_params(42), --ARGUMENT42
                                                      Dka_Tools_Pkg.tab_request_params(43), --ARGUMENT43
                                                      Dka_Tools_Pkg.tab_request_params(44), --ARGUMENT44
                                                      Dka_Tools_Pkg.tab_request_params(45), --ARGUMENT45
                                                      Dka_Tools_Pkg.tab_request_params(46), --ARGUMENT46
                                                      Dka_Tools_Pkg.tab_request_params(47), --ARGUMENT47
                                                      Dka_Tools_Pkg.tab_request_params(48), --ARGUMENT48
                                                      Dka_Tools_Pkg.tab_request_params(49), --ARGUMENT49
                                                      Dka_Tools_Pkg.tab_request_params(50), --ARGUMENT50
                                                      Dka_Tools_Pkg.tab_request_params(51), --ARGUMENT51
                                                      Dka_Tools_Pkg.tab_request_params(52), --ARGUMENT52
                                                      Dka_Tools_Pkg.tab_request_params(53), --ARGUMENT53
                                                      Dka_Tools_Pkg.tab_request_params(54), --ARGUMENT54
                                                      Dka_Tools_Pkg.tab_request_params(55), --ARGUMENT55
                                                      Dka_Tools_Pkg.tab_request_params(56), --ARGUMENT56
                                                      Dka_Tools_Pkg.tab_request_params(57), --ARGUMENT57
                                                      Dka_Tools_Pkg.tab_request_params(58), --ARGUMENT58
                                                      Dka_Tools_Pkg.tab_request_params(59), --ARGUMENT59
                                                      Dka_Tools_Pkg.tab_request_params(60), --ARGUMENT60
                                                      Dka_Tools_Pkg.tab_request_params(61), --ARGUMENT61
                                                      Dka_Tools_Pkg.tab_request_params(62), --ARGUMENT62
                                                      Dka_Tools_Pkg.tab_request_params(63), --ARGUMENT63
                                                      Dka_Tools_Pkg.tab_request_params(64), --ARGUMENT64
                                                      Dka_Tools_Pkg.tab_request_params(65), --ARGUMENT65
                                                      Dka_Tools_Pkg.tab_request_params(66), --ARGUMENT66
                                                      Dka_Tools_Pkg.tab_request_params(67), --ARGUMENT67
                                                      Dka_Tools_Pkg.tab_request_params(68), --ARGUMENT68
                                                      Dka_Tools_Pkg.tab_request_params(69), --ARGUMENT69
                                                      Dka_Tools_Pkg.tab_request_params(70), --ARGUMENT70
                                                      Dka_Tools_Pkg.tab_request_params(71), --ARGUMENT71
                                                      Dka_Tools_Pkg.tab_request_params(72), --ARGUMENT72
                                                      Dka_Tools_Pkg.tab_request_params(73), --ARGUMENT73
                                                      Dka_Tools_Pkg.tab_request_params(74), --ARGUMENT74
                                                      Dka_Tools_Pkg.tab_request_params(75), --ARGUMENT75
                                                      Dka_Tools_Pkg.tab_request_params(76), --ARGUMENT76
                                                      Dka_Tools_Pkg.tab_request_params(77), --ARGUMENT77
                                                      Dka_Tools_Pkg.tab_request_params(78), --ARGUMENT78
                                                      Dka_Tools_Pkg.tab_request_params(79), --ARGUMENT79
                                                      Dka_Tools_Pkg.tab_request_params(80), --ARGUMENT80
                                                      Dka_Tools_Pkg.tab_request_params(81), --ARGUMENT81
                                                      Dka_Tools_Pkg.tab_request_params(82), --ARGUMENT82
                                                      Dka_Tools_Pkg.tab_request_params(83), --ARGUMENT83
                                                      Dka_Tools_Pkg.tab_request_params(84), --ARGUMENT84
                                                      Dka_Tools_Pkg.tab_request_params(85), --ARGUMENT85
                                                      Dka_Tools_Pkg.tab_request_params(86), --ARGUMENT86
                                                      Dka_Tools_Pkg.tab_request_params(87), --ARGUMENT87
                                                      Dka_Tools_Pkg.tab_request_params(88), --ARGUMENT88
                                                      Dka_Tools_Pkg.tab_request_params(89), --ARGUMENT89
                                                      Dka_Tools_Pkg.tab_request_params(90), --ARGUMENT90
                                                      Dka_Tools_Pkg.tab_request_params(91), --ARGUMENT91
                                                      Dka_Tools_Pkg.tab_request_params(92), --ARGUMENT92
                                                      Dka_Tools_Pkg.tab_request_params(93), --ARGUMENT93
                                                      Dka_Tools_Pkg.tab_request_params(94), --ARGUMENT94
                                                      Dka_Tools_Pkg.tab_request_params(95), --ARGUMENT95
                                                      Dka_Tools_Pkg.tab_request_params(96), --ARGUMENT96
                                                      Dka_Tools_Pkg.tab_request_params(97), --ARGUMENT97
                                                      Dka_Tools_Pkg.tab_request_params(98), --ARGUMENT98
                                                      Dka_Tools_Pkg.tab_request_params(99), --ARGUMENT99
                                                      Dka_Tools_Pkg.tab_request_params(100) --ARGUMENT100
                                                      );
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id   := vn_request_id;
        COMMIT;

        IF vn_request_id = 0 THEN
           DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
		--- 21/09/2021 NBO EDB280B_Archivage et envoi des états TVA au format txt dans un fichier zip par mail aux régions
        ELSE
		  update fnd_concurrent_requests
			set priority_request_id = vn_conc_request_id , is_sub_request = 'Y' , parent_request_id = vn_conc_request_id
			where request_id = vn_request_id;
		  commit;
        END IF;

    END;

BEGIN
    
    -- vv_user := Fnd_Profile.VALUE('USERNAME');
	vn_conc_request_id := Fnd_Global.CONC_REQUEST_ID;
    
    -- Début CSP Portabilité 2008
    -- Contrôle des valeurs de profil ORG_ID et GL_SET_OF_BKS_ID
	/*
    IF fnd_profile.value('ORG_ID') IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée');
      RAISE no_data_found;
    END IF;
    
    IF fnd_profile.value('GL_SET_OF_BKS_ID') IS NULL THEN
      DBMS_OUTPUT.PUT_LINE('L''option de profil 1_Nom de l''entité comptable GL n''est pas paramétrée');
      RAISE no_data_found;
    END IF;
	*/ --RGH
    -- Fin CSP Portabilité 2008

    ----------------------------
    -- LANCEMENT DES ETATS AP --
    ----------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
	/*
    Dka_Tools_Pkg.get_parameter ('DKA_RJETVADEDUC', vv_responsibility_key, rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;
    vv_responsibility_ref := rec_param.varchar2_value;
    */ --RGH
    ------------------------------------------------------------------------------------
    -- Automatisation du traitement 'DKA : France - Déclaration de la TVA déductible' --
    ------------------------------------------------------------------------------------
    vv_prog_name := 'DKA_RJETVADEDUC';

    /* --- PHENIX 2004
    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    vv_responsibility_name := vv_responsibility_ref;
    positionnement_contexte ( vv_user, 
                              vv_responsibility_name, 
                              vv_prog_name,
                              vn_retcode_r,
                              vv_errbuf );
    IF vn_retcode_r != 0 THEN
       DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
       DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
       DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_name);
       DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
       vb_lancement_trt := FALSE;
    END IF;*/ -- Modif EB
    -- FIN PHENIX 2004

    OPEN cur_soc;
    LOOP
        FETCH cur_soc INTO rec_soc;
        EXIT WHEN cur_soc%NOTFOUND;

        vn_trt_a_lancer := vn_trt_a_lancer + 1;

        -- initialisation de la variable vb_lancement_trt
        -------------------------------------------------
        /*IF vn_retcode_r = 0  THEN -- PHENIX 2004
          vb_lancement_trt := TRUE;
        END IF;*/

	    vb_lancement_trt := TRUE;  -- MODIF EB


        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        vv_user                := rec_soc.user_name;
        -- vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', rec_soc.company_name);
	
	    vv_responsibility_name := vv_responsibility_key; -- RGH
        positionnement_contexte ( vv_user, 
                                  vv_responsibility_name, 
                                  vv_prog_name,
                                  vn_retcode,
                                  vv_errbuf );
						  
        IF vn_retcode != 0 THEN
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
           vb_lancement_trt := FALSE;
        END IF;

        
        -- Récupération des paramètres
        ------------------------------
        IF vb_lancement_trt THEN
           Dka_Tools_Pkg.get_request_set_params (
               pv_errbuf                      => vv_errbuf,
               pn_retcode                     => vn_retcode,
               pn_application_id              => NULL,
               pn_request_set_id              => NULL,
               pn_request_set_program_id      => NULL,
               pn_prog_application_id         => vn_prog_application_id,
               pn_program_id                  => vn_program_id
               );

           IF vn_retcode != 0 THEN
		      DBMS_OUTPUT.PUT_LINE ('vn_retcode != 0 ');
              DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
              DBMS_OUTPUT.PUT_LINE (vv_errbuf);
              vb_lancement_trt := FALSE;
           END IF;
           -- Initialisation des parametres
           --------------------------------
           /*SELECT gl.ledger_id
            INTO dka_tools_pkg.tab_request_params(1)
            FROM gl_access_set_assignments gasa, 
          			 gl_ledgers gl  
          	WHERE gasa.access_set_id = Fnd_Profile.VALUE('GL_ACCESS_SET_ID')
            AND gl.ledger_id = gasa.ledger_id
          	AND gl.ledger_category_code = 'PRIMARY'
          	AND gl.short_name = rec_soc.company_name; --RGH*/--YWA artf2083525
           dka_tools_pkg.tab_request_params(1) := rec_soc.ledger_id;--YWA artf2083525
           --Dka_Tools_Pkg.tab_request_params(2) := TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS');
           			 
			 --<!--SFA artf07235613 --
			 SELECT  TO_CHAR(TRUNC(end_date), 'YYYY/MM/DD HH24:MI:SS')
			    INTO Dka_Tools_Pkg.tab_request_params(2)
			 FROM gl_periods
			 WHERE period_set_name = 'GROUPE'
				   AND end_date = (SELECT min(start_date) - 1
									 FROM gl_period_statuses
									WHERE application_id = 200
									  AND ledger_id = (SELECT ledger_id from gl_ledgers where short_name = '0001')   --SFA artf07235613  -- AND ledger_id = rec_soc.ledger_id 
									  AND closing_status = 'O')
				AND ROWNUM = 1;
			-->--				  
        END IF;           

        -- Lancement du traitement
        --------------------------
        IF vb_lancement_trt THEN
           soumission_traitement (rec_soc.society_name);   --- 08/10/2018  ajout du paramètre Nom société
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
           DBMS_OUTPUT.PUT_LINE ('==>             Société : '||Dka_Tools_Pkg.tab_request_params(1));
           DBMS_OUTPUT.PUT_LINE ('==> Date de déclaration : '||Dka_Tools_Pkg.tab_request_params(2));
           DBMS_OUTPUT.PUT_LINE (CHR(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;

    END LOOP; -- fin boucle des livres

    CLOSE cur_soc;


    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    FOR vn_indice IN 1..vn_traitement 
    LOOP
        IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, vn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
           DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
        ELSE
           IF vv_dstatus = 'NORMAL' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
              vn_trt_normal := vn_trt_normal + 1;
           ELSIF vv_dstatus = 'WARNING' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
              vn_trt_warning := vn_trt_warning + 1;
           ELSIF vv_dstatus != 'NORMAL' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
              vn_trt_erreur := vn_trt_erreur + 1;
           END IF;
        END IF;

     	  :ret_code := 'SUCCESS';
    END LOOP;

    -- Fermeture du fichier de commandes
    ------------------------------------
    DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
	
	--- 21/09/2021 NBO EDB280B_Archivage et envoi des états TVA au format txt dans un fichier zip par mail aux régions
    -- Récupération répertoire DKA_OUT_DIR
    BEGIN
       SELECT directory_path INTO vv_utl_file_dir FROM all_directories WHERE directory_name = 'DKA_OUT_DIR';

    EXCEPTION
        WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE ('Impossible de récupérer le répertoire de création des fichiers');
             :ret_code := 'FAILURE';
             RETURN;
    END;
	
	:utl_file_name   := vv_utl_file_dir||'/'||vv_prog_name||'.sh';
    
    vf_myfile := UTL_FILE.FOPEN (K_DIRECTORY, vv_prog_name||'.sh', 'w');
    
    FOR rec_directory IN cur_directory (vv_archivage, vn_conc_request_id) LOOP
      UTL_FILE.PUT_LINE (vf_myfile, rec_directory.line);
    END LOOP;
    
    FOR rec_file IN cur_file (vv_archivage, vn_conc_request_id) LOOP
      UTL_FILE.PUT_LINE (vf_myfile, rec_file.line);
    END LOOP;
    
    UTL_FILE.FFLUSH (vf_myfile);
    UTL_FILE.FCLOSE_ALL;

EXCEPTION
    WHEN OTHERS THEN
         DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'FAILURE';
END;
/

--- 21/09/2021 NBO EDB280B_Archivage et envoi des états TVA au format txt dans un fichier zip par mail aux régions
COL :utl_file_name NEW_VALUE utl_file_name;
SELECT :utl_file_name
FROM   DUAL;
HOST sh &utl_file_name;

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
