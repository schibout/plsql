/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
--  CAP GEMINI
--  PROJET           : DALKIA Oracle Applications
--  NOM              : DKA_TVACOLLECTEE.sql
--  DESCRIPTION      : Lancement automatique du traitement DKA_TVACOLLECTEE
---
--- AUTEUR           : CG
--- DATE DE CREATION : 16/10/2003
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 01/09/2004 STI Portage PHENIX 2004
---                Modification de la gestion de la responsabilite par societe
--- 12/07/2005 EMA Modification du renseignment des paramètres pour que les états soient lancés pour toutes les
---                sociétés et non seulement la '0001'
--- 28/10/2005 EB  Modification du positionnement dans le contexte O.A
--- 08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
--- 03/04/2019 SFA artf07235613: INC0306496 - Correctif états de TVA 
--- 21/09/2021 NBO EDB280B_Archivage et envoi des états TVA au format txt dans un fichier zip par mail aux régions
--- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
--- 19/05/2022 SELO EDB280C
--- 31/08/2022 IBA  artf07540527 EDB347-Automatisation des états de TVA - Lancement des états de TVA si UO présente dans profil sécurité DKA_TOUT
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);
--- 21/09/2021 NBO EDB280B_Archivage et envoi des états TVA au format txt dans un fichier zip par mail aux régions
VAR utl_file_name VARCHAR2(512);

DECLARE
    vv_prog_name                     VARCHAR2 (30)  := 'DKA_TVACOLLECTEE';
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

    -- Curseur de sélection des sociétés pour les traitements annuels
    -----------------------------------------------------------------
    CURSOR cur_soc IS
        /*SELECT DISTINCT dii.company_code    company_name,
               digi.mainoffice_cost_center  user_name
        FROM   dka_ibdsoc_i00dgic       dii,
               --dka_ibdsoc_i00ic_tmp     diit, prem commented artf587083
               dka_ibdsoc_general_info  digi
        WHERE  1=1
        --AND    dii.company_code    = diit.company_code prem commented artf587083
        AND    dii.company_type    = '0'
        AND    dii.company_code    = digi.company_code
        ORDER BY dii.company_code ASC;*/
		
		  --<!--SFA artf07235613
        /*SELECT DISTINCT val.flex_value company_name,
          val.attribute2 user_name,
          gl.ledger_id 
        FROM fnd_flex_value_sets sets,
          fnd_flex_values_vl val ,
          gl_ledgers gl
        WHERE sets.flex_value_set_id = val.flex_value_set_id
        AND gl.short_name            =val.flex_value
        AND ledger_category_code     = 'PRIMARY'
        AND val.enabled_flag         = 'Y'
        AND SYSDATE BETWEEN NVL(val.start_date_active,SYSDATE) AND NVL(val.end_date_active,SYSDATE)
        AND val.summary_flag   = 'N'
        AND val.VALUE_CATEGORY ='DAOPCCF_STE'; */--SFA artf07235613 
        
		SELECT DISTINCT val.FLEX_VALUE    company_name,
               val.ATTRIBUTE2   user_name,
			    gl.ledger_id   ledger_id,
                val.attribute2 || val.flex_value ||' - ' || gl.name society_name
        FROM   fnd_flex_value_sets sets,
               fnd_flex_values_vl val,
               hr_operating_units hou,
               gl_ledgers          gl,
			   per_security_organizations   pso -- IBA artf07540527 EDB347
        WHERE  sets.flex_value_set_id = val.flex_value_set_id
        AND    val.enabled_flag = 'Y'
        AND    val.summary_flag = 'N'
        AND    hou.name = val.ATTRIBUTE2||val.FLEX_VALUE
        AND    hou.set_of_books_id= gl.ledger_id
        AND    SYSDATE BETWEEN nvl(val.start_date_active,SYSDATE) AND nvl(val.end_date_active,SYSDATE)
        AND    gl.ledger_category_code = 'PRIMARY'
        AND    val.FLEX_VALUE <> '0001' 
        AND    val.VALUE_CATEGORY ='DAOPCCF_STE'
		--< IBA artf07540527 EDB347
			 AND pso.organization_id = hou.organization_id
             AND pso.security_profile_id = 63;
			 --> IBA artf07540527 EDB347
    -->--
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
	   AND fcr.argument2 = gps.PERIOD_NAME
--- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
     AND ffvs.flex_value_set_name = 'DAOPCCF_STE'
     AND ffvs.flex_value_set_id = ffv.flex_value_set_id
     AND ffv.flex_value = gl.short_name;
           
    rec_directory             cur_directory%ROWTYPE;

    CURSOR cur_file (p_path VARCHAR, p_request_id NUMBER) IS
    SELECT 'cp ' || fcr.OUTFILE_NAME || ' $REP_DATA''/editions_legales/'||p_path||'/' || to_char(gps.start_date,'RRRRMM') || '/' || ffv.attribute2 || '/'
 --     || ffv.attribute2 || '_' || fcr.request_id || '_' || REPLACE(fcr.description,'''', ' ') || '_' ||
  --     REPLACE(REPLACE(fcp.user_concurrent_program_name, ':', '-'),'é','e') || '_' ||
 --      fcr.argument2 || '.txt''' line
		|| ffv.attribute2 || '_' || 
		substr(REPLACE(fcr.description,'''', ' '), 4, 4)|| '_' || 
        replace(REPLACE(fcr.description,'', ' '),'''','') || '_' ||
		REPLACE(REPLACE(REPLACE(fcp.user_concurrent_program_name, ':', '-'),'é','e'),'''','''''') || '_' ||
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
     AND fcr.argument2 = gps.PERIOD_NAME
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
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
        pn_retcode := 0;

    END;


    ------------------------------------------
    -- Fonction de soumission du traitement --
    ------------------------------------------
    PROCEDURE soumission_traitement (soc_name IN VARCHAR2) /*--SFA artf07235613*/ IS
    BEGIN
        vn_request_id := fnd_request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                      vv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                       --NULL,                           -- PROGRAM NAME  
													  soc_name,                       -- PROGRAM NAME  -- SFA artf07235613
                                                      NULL,                           -- START
                                                      FALSE,                          -- SUB REQUEST
                                                      dka_tools_pkg.tab_request_params(1), --ARGUMENT1
                                                      dka_tools_pkg.tab_request_params(2), --ARGUMENT2
                                                      dka_tools_pkg.tab_request_params(3), --ARGUMENT3
                                                      dka_tools_pkg.tab_request_params(4), --ARGUMENT4
                                                      dka_tools_pkg.tab_request_params(5), --ARGUMENT5
                                                      dka_tools_pkg.tab_request_params(6), --ARGUMENT6
                                                      dka_tools_pkg.tab_request_params(7), --ARGUMENT7
                                                      dka_tools_pkg.tab_request_params(8), --ARGUMENT8
                                                      dka_tools_pkg.tab_request_params(9), --ARGUMENT9
                                                      dka_tools_pkg.tab_request_params(10), --ARGUMENT10
                                                      dka_tools_pkg.tab_request_params(11), --ARGUMENT11
                                                      dka_tools_pkg.tab_request_params(12), --ARGUMENT12
                                                      dka_tools_pkg.tab_request_params(13), --ARGUMENT13
                                                      dka_tools_pkg.tab_request_params(14), --ARGUMENT14
                                                      dka_tools_pkg.tab_request_params(15), --ARGUMENT15
                                                      dka_tools_pkg.tab_request_params(16), --ARGUMENT16
                                                      dka_tools_pkg.tab_request_params(17), --ARGUMENT17
                                                      dka_tools_pkg.tab_request_params(18), --ARGUMENT18
                                                      dka_tools_pkg.tab_request_params(19), --ARGUMENT19
                                                      dka_tools_pkg.tab_request_params(20), --ARGUMENT20
                                                      dka_tools_pkg.tab_request_params(21), --ARGUMENT21
                                                      dka_tools_pkg.tab_request_params(22), --ARGUMENT22
                                                      dka_tools_pkg.tab_request_params(23), --ARGUMENT23
                                                      dka_tools_pkg.tab_request_params(24), --ARGUMENT24
                                                      dka_tools_pkg.tab_request_params(25), --ARGUMENT25
                                                      dka_tools_pkg.tab_request_params(26), --ARGUMENT26
                                                      dka_tools_pkg.tab_request_params(27), --ARGUMENT27
                                                      dka_tools_pkg.tab_request_params(28), --ARGUMENT28
                                                      dka_tools_pkg.tab_request_params(29), --ARGUMENT29
                                                      dka_tools_pkg.tab_request_params(30), --ARGUMENT30
                                                      dka_tools_pkg.tab_request_params(31), --ARGUMENT31
                                                      dka_tools_pkg.tab_request_params(32), --ARGUMENT32
                                                      dka_tools_pkg.tab_request_params(33), --ARGUMENT33
                                                      dka_tools_pkg.tab_request_params(34), --ARGUMENT34
                                                      dka_tools_pkg.tab_request_params(35), --ARGUMENT35
                                                      dka_tools_pkg.tab_request_params(36), --ARGUMENT36
                                                      dka_tools_pkg.tab_request_params(37), --ARGUMENT37
                                                      dka_tools_pkg.tab_request_params(38), --ARGUMENT38
                                                      dka_tools_pkg.tab_request_params(39), --ARGUMENT39
                                                      dka_tools_pkg.tab_request_params(40), --ARGUMENT40
                                                      dka_tools_pkg.tab_request_params(41), --ARGUMENT41
                                                      dka_tools_pkg.tab_request_params(42), --ARGUMENT42
                                                      dka_tools_pkg.tab_request_params(43), --ARGUMENT43
                                                      dka_tools_pkg.tab_request_params(44), --ARGUMENT44
                                                      dka_tools_pkg.tab_request_params(45), --ARGUMENT45
                                                      dka_tools_pkg.tab_request_params(46), --ARGUMENT46
                                                      dka_tools_pkg.tab_request_params(47), --ARGUMENT47
                                                      dka_tools_pkg.tab_request_params(48), --ARGUMENT48
                                                      dka_tools_pkg.tab_request_params(49), --ARGUMENT49
                                                      dka_tools_pkg.tab_request_params(50), --ARGUMENT50
                                                      dka_tools_pkg.tab_request_params(51), --ARGUMENT51
                                                      dka_tools_pkg.tab_request_params(52), --ARGUMENT52
                                                      dka_tools_pkg.tab_request_params(53), --ARGUMENT53
                                                      dka_tools_pkg.tab_request_params(54), --ARGUMENT54
                                                      dka_tools_pkg.tab_request_params(55), --ARGUMENT55
                                                      dka_tools_pkg.tab_request_params(56), --ARGUMENT56
                                                      dka_tools_pkg.tab_request_params(57), --ARGUMENT57
                                                      dka_tools_pkg.tab_request_params(58), --ARGUMENT58
                                                      dka_tools_pkg.tab_request_params(59), --ARGUMENT59
                                                      dka_tools_pkg.tab_request_params(60), --ARGUMENT60
                                                      dka_tools_pkg.tab_request_params(61), --ARGUMENT61
                                                      dka_tools_pkg.tab_request_params(62), --ARGUMENT62
                                                      dka_tools_pkg.tab_request_params(63), --ARGUMENT63
                                                      dka_tools_pkg.tab_request_params(64), --ARGUMENT64
                                                      dka_tools_pkg.tab_request_params(65), --ARGUMENT65
                                                      dka_tools_pkg.tab_request_params(66), --ARGUMENT66
                                                      dka_tools_pkg.tab_request_params(67), --ARGUMENT67
                                                      dka_tools_pkg.tab_request_params(68), --ARGUMENT68
                                                      dka_tools_pkg.tab_request_params(69), --ARGUMENT69
                                                      dka_tools_pkg.tab_request_params(70), --ARGUMENT70
                                                      dka_tools_pkg.tab_request_params(71), --ARGUMENT71
                                                      dka_tools_pkg.tab_request_params(72), --ARGUMENT72
                                                      dka_tools_pkg.tab_request_params(73), --ARGUMENT73
                                                      dka_tools_pkg.tab_request_params(74), --ARGUMENT74
                                                      dka_tools_pkg.tab_request_params(75), --ARGUMENT75
                                                      dka_tools_pkg.tab_request_params(76), --ARGUMENT76
                                                      dka_tools_pkg.tab_request_params(77), --ARGUMENT77
                                                      dka_tools_pkg.tab_request_params(78), --ARGUMENT78
                                                      dka_tools_pkg.tab_request_params(79), --ARGUMENT79
                                                      dka_tools_pkg.tab_request_params(80), --ARGUMENT80
                                                      dka_tools_pkg.tab_request_params(81), --ARGUMENT81
                                                      dka_tools_pkg.tab_request_params(82), --ARGUMENT82
                                                      dka_tools_pkg.tab_request_params(83), --ARGUMENT83
                                                      dka_tools_pkg.tab_request_params(84), --ARGUMENT84
                                                      dka_tools_pkg.tab_request_params(85), --ARGUMENT85
                                                      dka_tools_pkg.tab_request_params(86), --ARGUMENT86
                                                      dka_tools_pkg.tab_request_params(87), --ARGUMENT87
                                                      dka_tools_pkg.tab_request_params(88), --ARGUMENT88
                                                      dka_tools_pkg.tab_request_params(89), --ARGUMENT89
                                                      dka_tools_pkg.tab_request_params(90), --ARGUMENT90
                                                      dka_tools_pkg.tab_request_params(91), --ARGUMENT91
                                                      dka_tools_pkg.tab_request_params(92), --ARGUMENT92
                                                      dka_tools_pkg.tab_request_params(93), --ARGUMENT93
                                                      dka_tools_pkg.tab_request_params(94), --ARGUMENT94
                                                      dka_tools_pkg.tab_request_params(95), --ARGUMENT95
                                                      dka_tools_pkg.tab_request_params(96), --ARGUMENT96
                                                      dka_tools_pkg.tab_request_params(97), --ARGUMENT97
                                                      dka_tools_pkg.tab_request_params(98), --ARGUMENT98
                                                      dka_tools_pkg.tab_request_params(99), --ARGUMENT99
                                                      dka_tools_pkg.tab_request_params(100) --ARGUMENT100
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
    vn_conc_request_id := Fnd_Global.CONC_REQUEST_ID;
    vv_user := FND_PROFILE.VALUE('USERNAME');

    ----------------------------
    -- LANCEMENT DES ETATS AR --
    ----------------------------
    -- Recherche de la responsabilité pour le lancement du traitement
    -----------------------------------------------------------------
    dka_tools_pkg.get_parameter ('DKA_TVACOLLECTEE', 'AR_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    IF pn_retcode != 0 THEN
       :ret_code := 'FAILURE';
       RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;

    ----------------------------------------------------------------------------------
    -- Automatisation du traitement 'DKA : TVA Collectee : état préparatoire' --
    ----------------------------------------------------------------------------------
    vv_prog_name := 'DKA_TVACOLLECTEE';

    /*-- PHENIX 2004
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
    END IF;*/ --Modif EB
    -- FIN PHENIX 2004	
	
    OPEN cur_soc;
    LOOP
        FETCH cur_soc INTO rec_soc;
        EXIT WHEN cur_soc%NOTFOUND;

        vn_trt_a_lancer := vn_trt_a_lancer + 1;

        -- initialisation de la variable vb_lancement_trt
        -------------------------------------------------
        /* IF vn_retcode_r = 0 THEN 
          vb_lancement_trt := TRUE;  -- PHENIX 2004
        END IF;  */

        vb_lancement_trt := TRUE;  -- MODIF EB

       
        -- Positionnement dans le contexte O.A.
        ---------------------------------------
        vv_user                := rec_soc.user_name;
        -- vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', rec_soc.company_name);

        vv_responsibility_name := vv_responsibility_ref; -- Modif EB

        positionnement_contexte ( vv_user, 
                                  vv_responsibility_name, 
                                  vv_prog_name,
                                  vn_retcode,
                                  vv_errbuf );
        IF vn_retcode != 0 THEN
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de se positionner dans le contexte O.A. :');
           DBMS_OUTPUT.PUT_LINE ('==> Utilisateur    : '||vv_user);
           DBMS_OUTPUT.PUT_LINE ('==> Responsabilite : '||vv_responsibility_name);
           DBMS_OUTPUT.PUT_LINE ('==> Programme      : '||vv_prog_name);
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
           vb_lancement_trt := FALSE;
        END IF;
      

        -- Récupération des paramètres
        ------------------------------
        IF vb_lancement_trt THEN
           dka_tools_pkg.get_request_set_params (
               pv_errbuf                      => vv_errbuf,
               pn_retcode                     => vn_retcode,
               pn_application_id              => NULL,
               pn_request_set_id              => NULL,
               pn_request_set_program_id      => NULL,
               pn_prog_application_id         => vn_prog_application_id,
               pn_program_id                  => vn_program_id
               );

           IF vn_retcode != 0 THEN
              DBMS_OUTPUT.PUT_LINE (CHR(10)||'Impossible de récupérer les paramètres :');
              DBMS_OUTPUT.PUT_LINE (vv_errbuf);
              vb_lancement_trt := FALSE;
           END IF;

           -- Initialisation des parametres
           --------------------------------
           -- Renseignement de la société
           -- Début modification EMA du 12/07/2005 
           dka_tools_pkg.tab_request_params(1) := rec_soc.ledger_id;
           -- Fin modification EMA du 12/07/2005

           -- Recherche de la dernière période
           DECLARE
               CURSOR cur_periode IS
				   --<!--SFA artf07235613 --		
					SELECT  period_name			   
					 FROM gl_periods
					 WHERE period_set_name = 'GROUPE'
						   AND end_date = (SELECT min(start_date) - 1
											 FROM gl_period_statuses
											WHERE application_id = 222 --application_id = 101 --SFA artf07235613
											  AND ledger_id = (SELECT ledger_id from gl_ledgers where short_name = '0001') --SFA artf07235613  -- AND ledger_id = rec_soc.ledger_id
											  AND closing_status = 'O')
					ORDER BY period_year DESC, period_num DESC;						  
            -->--

           BEGIN
               OPEN cur_periode;
               FETCH cur_periode INTO dka_tools_pkg.tab_request_params(2);
               CLOSE cur_periode;
           END;
        END IF;           
        --dka_tools_pkg.tab_request_params(3) := 
        dka_tools_pkg.tab_request_params(4) := 'N';
        -- Lancement du traitement
        --------------------------
        IF vb_lancement_trt THEN
           soumission_traitement(rec_soc.society_name); --SFA artf07235613;;
           DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
           DBMS_OUTPUT.PUT_LINE ('==>      Code Société : '||dka_tools_pkg.tab_request_params(1));
           DBMS_OUTPUT.PUT_LINE ('==> Période comptable : '||dka_tools_pkg.tab_request_params(2));
           DBMS_OUTPUT.PUT_LINE (chr(10));
           vn_trt_lances := vn_trt_lances + 1;
        END IF;

    END LOOP; -- fin boucle des sociétés

    CLOSE cur_soc;


    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    FOR vn_indice IN 1..vn_traitement 
    LOOP
        IF NOT fnd_concurrent.wait_for_request (vt_traitement(vn_indice).request_id, vn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
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

    --  08/06/2017 NBO artf2158298 - ETA030 : Paralléliser les sous-traitements
    IF vn_trt_erreur > 0 THEN
        :ret_code    := 'FAILURE';
    END IF;
    
    IF vn_trt_warning > 0 THEN
        :ret_code    := 'WARNING';
    END IF; 

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
