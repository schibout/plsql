/*<TOAD_FILE_CHUNK>*/
/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
--  CAP GEMINI
--  PROJET           : DALKIA Oracle Applications
--  NOM              : DKA_ARXCOA2.sql
--  DESCRIPTION      : Lancement automatique du traitement DKA_ARXCOA2
---
--- AUTEUR           : CG
--- DATE DE CREATION : 16/10/2003
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 12/07/2005 EMA Suppression de Dbms_Output.Put_Line inutile
--- 28/10/2005 EB  Modification du positionnement dans le contexte O.A
--- 01/03/2011 TB  Suppression de l'utilisation de la table Dka_Ibdsoc_I00ic_Tmp
--- 09/11/2016 NSI Migration R12
--- 08/12/2016 YWA Migration R12 PARAMETRES de lancement
--- 08/08/2018 OBE artf2982881 : INC0238716 : Etat Règlements AR non lettré : Modifié la date de lancement de l'état
--- 03/04/2019 SFA artf07235613: INC0306496 - Correctif états de TVA
--- 22/09/2022 IBA EDB348 - Automatisation et Archivage - Etats de Clôture Registre des règlements clients Non lettrés
---------------------------------------------------------------------------------------------------------------
SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);
VAR utl_file_name VARCHAR2(512);
DECLARE
  vv_prog_name                     VARCHAR2 (30)  := 'DKA_ARXCOA2'; 
  vn_tempo                         NUMBER         := 20;
  vv_user                          VARCHAR2 (80);
  vv_errbuf                        VARCHAR2 (500) := NULL;
  vn_retcode                       NUMBER         := 0;
  vn_retcode_r                     NUMBER         := 0;  -- PHENIX 2004
  vn_traitement                    NUMBER         := 0;
  vn_session_id                    NUMBER(15);
  vn_conc_request_id               NUMBER (15);
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
  
  vd_end_date                      DATE;
    ---<EDB348
	vn_request_id_0001				 NUMBER(15);
	vv_line							 VARCHAR2(400); 
	vv_repertoire					 VARCHAR2(250);
	vv_period_name					 VARCHAR2(10);
	l_req_data                       VARCHAR2(30);
    vv_archivage                     VARCHAR2(30) := 'DKA_ETATVAHORSDALKIA';
    vf_myfile                        UTL_FILE.FILE_TYPE;
    K_DIRECTORY                      CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
    vv_utl_file_dir                  VARCHAR2(250);
     ---EDB348>
	 
  TYPE myrecord IS RECORD (
       request_id    NUMBER);

  TYPE mytable IS TABLE OF myrecord
       INDEX BY BINARY_INTEGER;

  vt_traitement                    mytable;

  -- Curseur de sélection des sociétés pour les traitements annuels
  -----------------------------------------------------------------
  cursor c_societe is
  
    --<!--SFA artf07235613
  /*select gl.ledger_id,
         gl.chart_of_accounts_id,
         gl.short_name     societe,
         ffv.attribute2    region  ,
        currency_code         
  from gl_ledgers           gl
  join fnd_flex_values      ffv  on(ffv.flex_value = gl.short_name)
  join fnd_flex_value_sets  ffvs on(ffvs.flex_value_set_id = ffv.flex_value_set_id)
  where 1=1
    and ledger_category_code = 'PRIMARY'
    and ffvs.flex_value_set_name = 'DAOPCCF_STE'
    and ffv.value_category = 'DAOPCCF_STE'
	and ffv.enabled_flag = 'Y'; --SNK*/

   SELECT DISTINCT gl.ledger_id,
                gl.chart_of_accounts_id,
                gl.short_name     societe,
                val.attribute2    region  ,
                currency_code ,                  
              val.attribute2 || val.flex_value ||' - ' || gl.name society_name
        FROM   fnd_flex_value_sets sets,
               fnd_flex_values_vl val,
               hr_operating_units hou,
               gl_ledgers          gl,
			   per_security_organizations   pso -- IBA  EDB348
        WHERE  sets.flex_value_set_id = val.flex_value_set_id
        AND    val.enabled_flag = 'Y' --SNK
        AND    val.summary_flag = 'N'
        AND    hou.name = val.ATTRIBUTE2||val.FLEX_VALUE
        AND    hou.set_of_books_id= gl.ledger_id
		AND    sets.flex_value_set_name = 'DAOPCCF_STE'
        AND    gl.ledger_category_code = 'PRIMARY'
        AND    val.FLEX_VALUE <> '0001' 
        AND    val.VALUE_CATEGORY ='DAOPCCF_STE'
		--< IBA  EDB348
			 AND pso.organization_id = hou.organization_id
             AND pso.security_profile_id = 63
			 
		;	--> IBA  EDB348		
    -->--
  rec_soc                          c_societe%ROWTYPE;
  
  ---<EDB348
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
       AND fcr.argument19 = gl.ledger_id
       AND gl.short_name != '0001'
       AND fcr.requested_by = fu.user_id
       AND fcp.concurrent_program_id = fcr.concurrent_program_id
       AND gps.set_of_books_id = gl.ledger_id
       AND gps.application_id = 101
       AND to_date(fcr.argument4, 'RRRR/MM/DD HH24:MI:SS') BETWEEN
           gps.start_date AND gps.end_date
--- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
       AND ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
       AND ffv.flex_value = gl.short_name;
           
    rec_directory             cur_directory%ROWTYPE;
  
   CURSOR cur_file (p_path VARCHAR, p_request_id NUMBER) IS
    SELECT 'cp ' || fcr.OUTFILE_NAME || ' $REP_DATA''/editions_legales/'||p_path||'/' || to_char(gps.start_date,'RRRRMM') || '/' || ffv.attribute2 || '/'
        --  || ffv.attribute2 || '_' || fcr.request_id || '_' || REPLACE(fcr.description,'''', ' ') || '_' ||
        --   REPLACE(REPLACE(fcp.user_concurrent_program_name, ':', '-'),'''','''''') || '_' ||
        --   gps.period_name || '.txt''' line
		|| ffv.attribute2 || '_' || 
		substr(REPLACE(fcr.description,'''', ' '), 4, 4)|| '_' || 
        replace(REPLACE(fcr.description,'', ' '),'''','')|| '_' ||
		REPLACE(REPLACE(REPLACE(REPLACE(fcp.user_concurrent_program_name, ':', '-'),'''',''''''),'é','e'),'è','e') || '_' ||
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
       AND fcr.argument19 = gl.ledger_id
       AND gl.short_name != '0001'
       AND fcr.requested_by = fu.user_id
       AND fcp.concurrent_program_id = fcr.concurrent_program_id
       AND gps.set_of_books_id = gl.ledger_id
       AND gps.application_id = 101
       AND to_date(fcr.argument4, 'RRRR/MM/DD HH24:MI:SS') BETWEEN
           gps.start_date AND gps.end_date
--- 29/09/2021 NBO artf07483632 - EDB280B /SPE2338 Les régions principales ne sont pas déterminée comme telles 
       AND ffvs.flex_value_set_name = 'DAOPCCF_STE'
       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
       AND ffv.flex_value = gl.short_name;
           
    rec_file             cur_file%ROWTYPE; 
  
  
  --> IBA  EDB348
  
  /*CURSOR cur_soc IS
  SELECT DISTINCT dii.company_code                                    company_name,
         digi.mainoffice_cost_center                                  user_name
  FROM   dka_ibdsoc_i00dgic       dii,
         dka_ibdsoc_general_info  digi
  WHERE  dii.company_type    = '0'
  AND    dii.company_code    = digi.company_code
  ORDER BY dii.company_code ASC;*/
  
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
    --Fnd_Global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
     fnd_global.INITIALIZE( 
          vn_session_id, 
          vn_user_id, 
          vn_responsibility_id, 
          vn_application_id,
          null,
          -1,
          null,
          null,
          null,
          null,
          vn_conc_request_id,
          null,
          null,
          null,
          null,
          null,
          null,
          -1);
    -- EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || Fnd_Profile.value ('ICX_LANGUAGE') || '''';
	EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';   
    pn_retcode := 0;

  END;

  ------------------------------------------
  -- Fonction de soumission du traitement --
  ------------------------------------------
  PROCEDURE soumission_traitement (soc_name IN VARCHAR2) /*--SFA artf07235613*/ IS
  BEGIN
    vn_request_id := Fnd_Request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                  vv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                   --NULL,                           -- PROGRAM NAME  
												  soc_name,                       -- PROGRAM NAME   -- SFA artf07235613
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
                                                  Dka_Tools_Pkg.tab_request_params(19)--, --ARGUMENT19
                                                  /*Dka_Tools_Pkg.tab_request_params(20), --ARGUMENT20
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
                                                  Dka_Tools_Pkg.tab_request_params(100) --ARGUMENT100*/--YWA
                                                  );
    vn_traitement := vn_traitement + 1;
    vt_traitement(vn_traitement).request_id   := vn_request_id;
    COMMIT;

    IF vn_request_id = 0 THEN
       DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
       DBMS_OUTPUT.PUT_LINE (vv_errbuf);
    ---<EDB348 IBA
	ELSE
		  update fnd_concurrent_requests
			set priority_request_id = vn_conc_request_id , is_sub_request = 'Y' , parent_request_id = vn_conc_request_id
			where request_id = vn_request_id;
		  commit;
		  
	---EDB348 IBA>
	END IF;

  END;

BEGIN
    ---<IBA EDB348
	 
	 vn_conc_request_id := Fnd_Global.CONC_REQUEST_ID;
    vn_session_id := Fnd_Global.session_id;
	
	 ---IBA EDB348>

	
  vv_user := Fnd_Profile.VALUE('USERNAME');
  DBMS_OUTPUT.PUT_LINE ('==> vv_user      : '||vv_user); ---IBA EDB348
  ----------------------------
  -- LANCEMENT DES ETATS AR --
  ----------------------------
  -- Recherche de la responsabilité pour le lancement du traitement
  -----------------------------------------------------------------
  Dka_Tools_Pkg.get_parameter ('DKA_ARXCOA2', 'AR_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
  IF pn_retcode != 0 THEN
    :ret_code := 'FAILURE';
    RETURN;
  END IF;

  vv_responsibility_ref := rec_param.varchar2_value;

  ------------------------------------------------------------------------------
  -- Automatisation du traitement 'DKA : Registre des règlements non lettrés' --
  ------------------------------------------------------------------------------
  vv_prog_name := 'DKA_ARXCOA2';

  -- Positionnement dans le contexte O.A.
  ---------------------------------------
  /*vv_responsibility_name := vv_responsibility_ref;
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

  OPEN c_societe;
  LOOP
    FETCH c_societe INTO rec_soc;
    EXIT WHEN c_societe%NOTFOUND;

    vn_trt_a_lancer := vn_trt_a_lancer + 1;

    -- initialisation de la variable vb_lancement_trt
    -------------------------------------------------
    /*IF vn_retcode_r = 0 THEN 
      vb_lancement_trt := TRUE;
    END IF; */

	  vb_lancement_trt := TRUE;  -- MODIF EB

	  -- PHENIX 2004
    -- Positionnement dans le contexte O.A.
    ---------------------------------------
    vv_user := rec_soc.region;
    --vv_responsibility_name := REPLACE (vv_responsibility_ref, 'XXXX', rec_soc.company_name);
    vv_responsibility_name := vv_responsibility_ref; -- Modif EB

    positionnement_contexte ( vv_user, 
                              vv_responsibility_name, 
                              vv_prog_name,
                              vn_retcode,
                              vv_errbuf );

 	  DBMS_OUTPUT.PUT_LINE('vn_retcode : ' || vn_retcode);	                                  
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
    /*
      DKA_TOOLS_PKG.GET_REQUEST_SET_PARAMS (
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
      END IF;*/--YWA
	  
	  --<!--SFA artf07235613 -- 
	  /*--< OBE artf2982881
	  BEGIN
	   select gp.end_date
	   into vd_end_date
       from gl_period_statuses gp
       where (select gp2.start_date - 1
              from gl_period_statuses gp2
              where sysdate between gp2.start_date and gp2.end_date
              and gp2.ledger_id = rec_soc.ledger_id
              and gp2.application_id = 222) between gp.start_date and gp.end_date
       and gp.ledger_id = rec_soc.ledger_id
       and gp.application_id = 222;	   
	  EXCEPTION
	   WHEN OTHERS THEN
	     vd_end_date := LAST_DAY(ADD_MONTHS(SYSDATE, -1));
	  END;
	  --> OBE artf2982881*/--<!--SFA artf07235613 --
	  
	  --<!--SFA artf07235613 --	
         BEGIN	  
			SELECT  end_date
			    INTO vd_end_date
			 FROM gl_periods
			 WHERE period_set_name = 'GROUPE'
				   AND end_date = (SELECT min(start_date) - 1
									 FROM gl_period_statuses
									WHERE application_id = 222
									   AND ledger_id = (SELECT ledger_id from gl_ledgers where short_name = '0001') --SFA artf07235613  -- AND ledger_id = rec_soc.ledger_id
									  AND closing_status = 'O');
         EXCEPTION
	    WHEN OTHERS THEN
	    vd_end_date := LAST_DAY(ADD_MONTHS(SYSDATE, -1));
	    END;									  
            -->--

      -- Initialisation des parametres
      --------------------------------
      Dka_Tools_Pkg.tab_request_params(2)  := 'DETAIL';
      Dka_Tools_Pkg.tab_request_params(4)  := TO_CHAR(TRUNC(vd_end_date), 'YYYY/MM/DD HH24:MI:SS');--TO_CHAR(TRUNC(LAST_DAY(ADD_MONTHS(SYSDATE, -1))), 'YYYY/MM/DD HH24:MI:SS'); -- OBE artf2982881
      Dka_Tools_Pkg.tab_request_params(5)  := rec_soc.currency_code;--'EUR';ywa
      Dka_Tools_Pkg.tab_request_params(17) := rec_soc.societe;
      Dka_Tools_Pkg.tab_request_params(18) := rec_soc.chart_of_accounts_id;
      Dka_Tools_Pkg.tab_request_params(19) := rec_soc.ledger_id;
      Dka_Tools_Pkg.tab_request_params(1)  := null;
      Dka_Tools_Pkg.tab_request_params(3)  := null;
      Dka_Tools_Pkg.tab_request_params(6)  := null;
      Dka_Tools_Pkg.tab_request_params(7)  := null;
      Dka_Tools_Pkg.tab_request_params(8)  := null;
      Dka_Tools_Pkg.tab_request_params(9)  := null;
      Dka_Tools_Pkg.tab_request_params(10) := null;
      Dka_Tools_Pkg.tab_request_params(11) := null;
      Dka_Tools_Pkg.tab_request_params(12) := null;
      Dka_Tools_Pkg.tab_request_params(13) := null;
      Dka_Tools_Pkg.tab_request_params(14) := null;
      Dka_Tools_Pkg.tab_request_params(15) := null;
      Dka_Tools_Pkg.tab_request_params(16) := 'O';

    END IF;       

    -- Lancement du traitement
    --------------------------
    IF vb_lancement_trt THEN
      soumission_traitement(rec_soc.society_name); --SFA artf07235613;
      DBMS_OUTPUT.PUT_LINE (CHR(10)||'TRAITEMENT '||vn_request_id||' LANCE AVEC LES PARAMETRES');
      DBMS_OUTPUT.PUT_LINE ('==>             Option format : '||Dka_Tools_Pkg.tab_request_params(2));
      DBMS_OUTPUT.PUT_LINE ('==> Date GL du règlement - Au : '||Dka_Tools_Pkg.tab_request_params(4));
      DBMS_OUTPUT.PUT_LINE ('==>               Code devise : '||Dka_Tools_Pkg.tab_request_params(5));
      DBMS_OUTPUT.PUT_LINE ('==>        Nom du client - De : '||Dka_Tools_Pkg.tab_request_params(8));
      DBMS_OUTPUT.PUT_LINE ('==>        Nom du client - A  : '||Dka_Tools_Pkg.tab_request_params(9));
      DBMS_OUTPUT.PUT_LINE ('==>     Numéro du client - De : '||Dka_Tools_Pkg.tab_request_params(10));
      DBMS_OUTPUT.PUT_LINE ('==>     Numéro de client - A  : '||Dka_Tools_Pkg.tab_request_params(11));
      DBMS_OUTPUT.PUT_LINE ('==>           Nom du lot - De : '||Dka_Tools_Pkg.tab_request_params(12));
      DBMS_OUTPUT.PUT_LINE ('==>           Nom du lot - A  : '||Dka_Tools_Pkg.tab_request_params(13));
      DBMS_OUTPUT.PUT_LINE ('==>   Nom origine du lot - De : '||Dka_Tools_Pkg.tab_request_params(14));
      DBMS_OUTPUT.PUT_LINE ('==>   Nom origine du lot - A  : '||Dka_Tools_Pkg.tab_request_params(15));
      DBMS_OUTPUT.PUT_LINE ('==>     Numéro règlement - De : '||Dka_Tools_Pkg.tab_request_params(16));
      DBMS_OUTPUT.PUT_LINE ('==>     Numéro règlement - A  : '||Dka_Tools_Pkg.tab_request_params(17));
      DBMS_OUTPUT.PUT_LINE (CHR(10));
      vn_trt_lances := vn_trt_lances + 1;
    END IF;

  END LOOP; -- fin boucle des sociétés

  CLOSE c_societe;

  -----------------------------------------------
  -- Attente de la fin de tous les traitements --
  -----------------------------------------------
  FOR vn_indice IN 1..vn_traitement LOOP
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
  -- Récupération période
  SELECT PERIOD_NAME
	INTO vv_period_name
    FROM gl_period_statuses
        WHERE application_id=101
        AND end_date IN (SELECT start_date - 1
                         FROM gl_period_statuses
                         WHERE TRUNC(sysdate) between start_date and end_date
                         AND application_id = 101)
        AND ROWNUM = 1                 
            ; 
---<EDB348 IBA
	-- Récupération répertoire DKA_OUT_DIR
 BEGIN
       SELECT directory_path INTO vv_utl_file_dir FROM all_directories WHERE directory_name = 'DKA_OUT_DIR';

    EXCEPTION
        WHEN OTHERS THEN
             DBMS_OUTPUT.PUT_LINE ('Impossible de récupérer le répertoire de création des fichiers');
             :ret_code := 'FAILURE';
             RETURN;
    END;
    vv_repertoire := '$REP_DATA/editions_legales/DKA_ETATVA0001/';
    :utl_file_name   := vv_utl_file_dir||'/'||vv_prog_name||'.sh';
    vv_line := 'cp $APPLCSF/$APPLOUT/o'||vn_request_id_0001||'.out '||vv_repertoire||'DKA_GL_DECLAR_TVA_0001_'||vv_period_name||'.out';
   
    vf_myfile := UTL_FILE.FOPEN (K_DIRECTORY, vv_prog_name||'.sh', 'w');
    UTL_FILE.PUT_LINE (vf_myfile, vv_line);
	
    FOR rec_directory IN cur_directory (vv_archivage, vn_conc_request_id) LOOP
      UTL_FILE.PUT_LINE (vf_myfile, rec_directory.line);
    END LOOP;
    
    FOR rec_file IN cur_file (vv_archivage, vn_conc_request_id) LOOP
      UTL_FILE.PUT_LINE (vf_myfile, rec_file.line);
    END LOOP;
    
    UTL_FILE.FFLUSH (vf_myfile);
    UTL_FILE.FCLOSE_ALL;



--EDB342 IBA>
  -- Fermeture du fichier de commandes
  ------------------------------------
  DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
  DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements lances               : '||TO_CHAR(vn_trt_lances, '99990'));
  DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
  DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
  DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));


EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE (vv_prog_name || ' ==> ERREUR : ' || SQLERRM);
    :ret_code := 'FAILURE';
END;
/
/*<TOAD_FILE_CHUNK>*/
COL :utl_file_name NEW_VALUE utl_file_name;
SELECT :utl_file_name
FROM   DUAL;
HOST sh &utl_file_name;

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code

