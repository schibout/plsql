---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_GLXRCAUT.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_SARAFFACTURAGE
---
--- AUTEUR           : G. Vanackère
--- DATE DE CREATION : 16/11/2010
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 27/07/16   OBE Migration R12
--- 07/07/17   OBE artf2184553 : SPE177 : Lettrage GL (Hebdomadaire) : DKA_GLXRCAUT_JOB.sh
--- 12/02/18   MEG artf2371699 : SPE177 - Pb dans le lancement du traitement « Rapprochement - Rapprochement automatique »
--- 07/01/19   NBO artf3058144 : INC0277858 - SPE177 - Lettrage GL 
--- 28/10/19   SCH artf07257784: INC0259575 - SPE177 - Performance traitement Lettrage
--- 20/04/20   AAM artf07367097: INC0419725- correctif pour alimenter les dates de début/fin
--- 15/06/22   IBA artf07521223 : TASK0174825 - Modification paramètres périodes lettrage automatique
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 200000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_prog_name            CONSTANT VARCHAR2 (30)  := 'GLXRCAUT';
    cn_tempo                CONSTANT NUMBER         := 20;
    vv_user                          VARCHAR2 (80)  := '&&1';
    vv_resp                          VARCHAR2 (80)  := '&&2';
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
	vn_traitement                    NUMBER         := 0;  
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
    vv_cle_de                        VARCHAR2 (240);
    vv_cle_a                         VARCHAR2 (240);
    --< OBE
    vv_gl_access_set_id              NUMBER;
    vv_chart_of_account_id           NUMBER;
    vv_ledger_id                     NUMBER;
    --> OBE
    
    --< OBE artf2184553
    vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
    vn_trt_warning                   NUMBER:=0;
	
	--AAM artf07367097 DEBUT
	vv_start_date gl_period_statuses.start_date%TYPE;
	vv_end_date   gl_period_statuses.end_date%TYPE;
	--AAM artf07367097 FIN
    
    TYPE myrecord IS RECORD (
     request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
    INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;
    
    --> OBE artf2184553

	CURSOR /*cur_region_period*/ cur_period IS  
  --< OBE
	/*SELECT ffv.flex_value as region,gps.period_name
	  FROM fnd_flex_value_sets ffs,
		   fnd_flex_values ffv,
		   gl_period_statuses gps
	 WHERE ffs.flex_value_set_id = ffv.flex_value_set_id
	   AND ffs.flex_value_set_name = 'DAOPCCF_REGION'
	   AND ffv.enabled_flag = 'Y'
	   AND ffv.summary_flag = 'N'
	   AND gps.application_id = 200
	   AND gps.set_of_books_id = 1
	   AND add_months(SYSDATE,-1) BETWEEN gps.start_date AND gps.end_date
	ORDER BY 1;   */
 	SELECT glasl.ledger_id
	,SUBSTR(gps.period_name,1,3) period_if --SNK artf3061958 04/02/2019
    ,gps.period_name
	,TO_CHAR(ADD_MONTHS(TO_DATE(gps.period_name,'MM-YYYY'), - 3),'MON-YY') period_name_2_1  -- SCH 
--  ,TO_CHAR(ADD_MONTHS(TO_DATE(gps.period_name,'MM-YYYY'), - 5),'MON-YY') period_name_2_1 --SNK artf3061958 04/02/2019  -- SCH
    ,TO_CHAR(ADD_MONTHS(TO_DATE(gps.period_name,'MM-YYYY'), - 1),'MON-YY') period_name_12_1  --IBA artf07521223
    ,gps2.period_name period_name_2
    ,gps3.period_name period_name_3
    ,gps4.period_name period_name_4
	  FROM 
		   gl_period_statuses gps,
       gl_period_statuses gps2,
       gl_period_statuses gps3,
       gl_period_statuses gps4,
       GL_ACCESS_SET_LEDGERS glasl,
       gl_ledgers gl
	 WHERE 1=1
     AND glasl.access_set_id = fnd_profile.VALUE('GL_ACCESS_SET_ID')
     AND glasl.ledger_id = gps.ledger_id 
     AND gps.application_id = 101
     AND SYSDATE BETWEEN gps.start_date AND gps.end_date
     AND gps2.application_id = gps.application_id
     AND gps2.ledger_id = glasl.ledger_id 
     AND gps2.period_year = gps.period_year 
     AND gps2.period_num = 1 
     AND gps3.ledger_id = gps.ledger_id 
     AND gps3.application_id = gps.application_id
     --- 07/01/19   NBO artf3058144 : INC0277858 - SPE177 - Lettrage GL 
     --AND TRUNC(TO_DATE(('15/'||TO_CHAR(ADD_MONTHS( SYSDATE, -1 ),'MM')||TO_CHAR(SYSDATE,'/YY')),'DD/MM/YY'))
     AND ADD_MONTHS(trunc(TO_DATE(('15/'||TO_CHAR(SYSDATE,'MM/YY')),'DD/MM/YY')),-1) 
          BETWEEN gps3.start_date AND gps3.end_date  
     AND gps4.ledger_id = gps.ledger_id
     AND gps4.application_id = gps.application_id
     AND trunc(TO_DATE(('15/'||TO_CHAR(SYSDATE,'MM/YY')),'DD/MM/YY')) BETWEEN gps4.start_date AND gps4.end_date
     
     AND glasl.ledger_id = gl.ledger_id
     AND gl.ledger_category_code = 'PRIMARY'
     
    ORDER BY 1
    ;  
    --> OBE
	
BEGIN

    DBMS_OUTPUT.put_line ('Récuperation des identifiants user');
    SELECT fr.responsibility_id,
           fr.application_id
    INTO   vn_responsibility_id,
           vn_application_id
    FROM   fnd_responsibility fr
    WHERE  responsibility_key = vv_resp;

    SELECT user_id
    INTO   vn_user_id
    FROM   fnd_user
    WHERE  user_name = vv_user;

    DBMS_OUTPUT.put_line ('Récuperation des identifiants programme');
    SELECT fcp.application_id,
           fa.application_short_name,
           fcp.concurrent_program_id
    INTO   vn_prog_application_id,
           vv_prog_application_short_name,
           vn_program_id
    FROM   fnd_concurrent_programs fcp,
           fnd_application fa
    WHERE      fcp.concurrent_program_name = cv_prog_name
           AND fa.application_id = fcp.application_id;

  DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
  fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
  
  EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
  
  FOR rec_period IN cur_period
    LOOP

    vn_trt_a_lancer := vn_trt_a_lancer + 3;                 -- OBE artf2184553
    --DBMS_OUTPUT.put_line ('Recuperation des parametres'); -- OBE artf2184553
    --< OBE
    /*dka_tools_pkg.get_request_set_params (
        pv_errbuf                      => vv_errbuf,
        pn_retcode                     => vn_retcode,
        pn_application_id              => NULL,
        pn_request_set_id              => NULL,
        pn_request_set_program_id      => NULL,
        pn_prog_application_id         => vn_prog_application_id,
        pn_program_id                  => vn_program_id
    );*/
    
    -- Récuperation de l'option de profil GL_ACCESS_SET_ID    
    vv_gl_access_set_id := fnd_profile.VALUE('GL_ACCESS_SET_ID');
    
    -- Récuperation du ledger_id
    /*
    SELECT ledger_id
    INTO vv_ledger_id
    FROM gl_ledgers
    WHERE ledger_id                = gl_access_set_security_pkg.get_default_ledger_id(vv_gl_access_set_id, 'B')
    AND enable_reconciliation_flag = 'Y';
    */
    
    -- Récuperation du chart_of_accounts_id
    SELECT chart_of_accounts_id
    INTO vv_chart_of_account_id
    FROM GL_ACCESS_SETS
    WHERE access_set_id = vv_gl_access_set_id;    

    /*IF vn_retcode != 0
    THEN
        DBMS_OUTPUT.put_line ('Impossible de récupérer les paramètres :');
        DBMS_OUTPUT.put_line (vv_errbuf);
        :ret_code    := 'FAILURE';
        RETURN;
    END IF;*/
    --> OBE
    
    
    --vv_cle_de:='0.'||rec_region_period.region||'.0.0.0.0.0.0.0.0'; 
    --vv_cle_a:='Z.'||rec_region_period.region||'.Z.Z.Z.Z.Z.Z.Z.Z';
    
    /*vv_cle_de:='0001.'||rec_region_period.region||'.0.0.0.0.0.0.0.0.0.0'; 
    vv_cle_a:='0001.'||rec_region_period.region||'.Z.Z.Z.Z.Z.Z.Z.Z.Z.Z';*/
    
    --DBMS_OUTPUT.put_line ('Les clés concernées par ces traitements sont : '||vv_cle_de||'  à : '||vv_cle_a);
    
    --DBMS_OUTPUT.put_line ('Soumission du traitement avec reference NULL: NON , Mettre à jour lettrage : OUI  , Type de montant  : Comptable');  
    --< OBE
    /*vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            dka_tools_pkg.tab_request_params(1), --ARGUMENT1
                            dka_tools_pkg.tab_request_params(2), --ARGUMENT2
                            'Toutes les devises', --ARGUMENT3
                            1, --ARGUMENT4
                            'Y', --ARGUMENT5
                            rec_region_period.period_name, --ARGUMENT6
                            rec_region_period.period_name, --ARGUMENT7
                            dka_tools_pkg.tab_request_params(8), --ARGUMENT13
                            dka_tools_pkg.tab_request_params(9), --ARGUMENT13
                            dka_tools_pkg.tab_request_params(10), --ARGUMENT13
                            vv_cle_de, --ARGUMENT11
                            vv_cle_a, --ARGUMENT12
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
                        );*/
    
	
	IF rec_period.period_if = 'MAI' OR rec_period.period_if = 'JUN' OR rec_period.period_if = 'JUL' OR rec_period.period_if = 'AOU' OR rec_period.period_if = 'SEP' OR rec_period.period_if = 'OCT' 
	   OR rec_period.period_if = 'NOV' OR rec_period.period_if = 'DEC'  --SNK artf3061958 04/02/2019 --SCH : ajout de jun et mai
    THEN
	--AAM artf07367097 DEBUT
	  SELECT start_date 
      INTO  vv_start_date
      FROM  gl_period_statuses 
      WHERE APPLICATION_ID = vn_prog_application_id
	  AND   LEDGER_ID      = rec_period.ledger_id
      AND  period_name = rec_period.period_name_2_1;
      SELECT end_date 
      INTO vv_end_date
      FROM gl_period_statuses 
	  WHERE APPLICATION_ID = vn_prog_application_id
	  AND   LEDGER_ID      = rec_period.ledger_id
      AND period_name   = rec_period.period_name;
	--AAM artf07367097 FIN  
	DBMS_OUTPUT.put_line ('Soumission du traitement par référence de lettrage, période de : premiere periode de l''exercie en cours, période à : période en cours');                          
    vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            vv_gl_access_set_id, --ARGUMENT1
                            --vv_ledger_id, --ARGUMENT2
                            rec_period.ledger_id, --ARGUMENT2
                            'Toutes les devises', --ARGUMENT3
                            1, --ARGUMENT4
                            'Y', --ARGUMENT5
                            rec_period.period_name_2_1, --ARGUMENT6 SNK artf3061958 04/02/2019
                            rec_period.period_name, --ARGUMENT7
                            TO_CHAR(vv_start_date,'YYYY/MM/DD hh24:mi:ss'), --ARGUMENT8 AAM artf07367097
                            TO_CHAR(vv_end_date,'YYYY/MM/DD hh24:mi:ss'), --ARGUMENT9   AAM artf07367097
                            vv_chart_of_account_id, --ARGUMENT10
                            NULL,
                            NULL
                            --vv_cle_de, --ARGUMENT11
                            --vv_cle_a --ARGUMENT12
                        );    
    --> OBE                        
    --DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande'); -- OBE artf2184553
    vn_traitement := vn_traitement + 1;                                                 -- OBE artf2184553
    vt_traitement(vn_traitement).request_id   := vn_request_id;                         -- OBE artf2184553
    
    COMMIT;
	
	ELSE if rec_period.period_if = 'JAN'
	then 
	DBMS_OUTPUT.put_line ('Soumission du traitement par référence de lettrage, période de : premiere periode de l''exercie en cours, période à : période en cours');                          
	  --AAM artf07367097 DEBUT
	  SELECT start_date 
      INTO  vv_start_date
      FROM  gl_period_statuses 
      WHERE APPLICATION_ID = vn_prog_application_id
	  AND   LEDGER_ID      = rec_period.ledger_id
      AND  period_name     = rec_period.period_name_12_1;
	  
      SELECT end_date 
      INTO vv_end_date
      FROM gl_period_statuses 
	  WHERE APPLICATION_ID = vn_prog_application_id
	  AND   LEDGER_ID      = rec_period.ledger_id
      AND period_name   = rec_period.period_name;
	  --AAM artf07367097 FIN
    vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            vv_gl_access_set_id, --ARGUMENT1
                            --vv_ledger_id, --ARGUMENT2
                            rec_period.ledger_id, --ARGUMENT2
                            'Toutes les devises', --ARGUMENT3
                            1, --ARGUMENT4
                            'Y', --ARGUMENT5
                            rec_period.period_name_12_1, --ARGUMENT6
                            rec_period.period_name, --ARGUMENT7
                            TO_CHAR(vv_start_date,'YYYY/MM/DD hh24:mi:ss'), --ARGUMENT8 AAM artf07367097
                            TO_CHAR(vv_end_date,'YYYY/MM/DD hh24:mi:ss'), --ARGUMENT9   AAM artf07367097
                            vv_chart_of_account_id, --ARGUMENT10
                            NULL,
                            NULL
                            --vv_cle_de, --ARGUMENT11
                            --vv_cle_a --ARGUMENT12
                        );    
    --> OBE                        
    --DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande'); -- OBE artf2184553
    vn_traitement := vn_traitement + 1;                                                 -- OBE artf2184553
    vt_traitement(vn_traitement).request_id   := vn_request_id;                         -- OBE artf2184553
    
    COMMIT;
	--IBA artf07521223
	else if rec_period.period_if = 'FEV' OR rec_period.period_if = 'MAR' OR rec_period.period_if = 'AVR'
	then 
	
	DBMS_OUTPUT.put_line ('Soumission du traitement par référence de lettrage, période de : premiere periode de l''exercie en cours, période à : période en cours');                          
	  --AAM artf07367097 DEBUT
	  SELECT start_date 
      INTO  vv_start_date
      FROM  gl_period_statuses 
      WHERE APPLICATION_ID = vn_prog_application_id
	  AND   LEDGER_ID      = rec_period.ledger_id
      AND  period_name     = rec_period.period_name_2;
	  
      SELECT end_date 
      INTO vv_end_date
      FROM gl_period_statuses 
	  WHERE APPLICATION_ID = vn_prog_application_id
	  AND   LEDGER_ID      = rec_period.ledger_id
      AND period_name   = rec_period.period_name;
	  --AAM artf07367097 FIN
    vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            vv_gl_access_set_id, --ARGUMENT1
                            --vv_ledger_id, --ARGUMENT2
                            rec_period.ledger_id, --ARGUMENT2
                            'Toutes les devises', --ARGUMENT3
                            1, --ARGUMENT4
                            'Y', --ARGUMENT5
                            rec_period.period_name_2, --ARGUMENT6
                            rec_period.period_name, --ARGUMENT7
                            TO_CHAR(vv_start_date,'YYYY/MM/DD hh24:mi:ss'), --ARGUMENT8 AAM artf07367097
                            TO_CHAR(vv_end_date,'YYYY/MM/DD hh24:mi:ss'), --ARGUMENT9   AAM artf07367097
                            vv_chart_of_account_id, --ARGUMENT10
                            NULL,
                            NULL
                            --vv_cle_de, --ARGUMENT11
                            --vv_cle_a --ARGUMENT12
                        );    
    --> OBE                        
    --DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande'); -- OBE artf2184553
    vn_traitement := vn_traitement + 1;                                                 -- OBE artf2184553
    vt_traitement(vn_traitement).request_id   := vn_request_id;                         -- OBE artf2184553
    
    COMMIT;
	
    END IF;
	end if;
	end if;
	
    IF vn_request_id = 0
    THEN
        DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
        :ret_code    := 'FAILURE';
        RETURN;
    END IF;

    DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
    vn_trt_lances := vn_trt_lances + 1; -- OBE artf2184553

     --< OBE artf2184553
    /*IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
    THEN
        :ret_code    := 'FAILURE';
        RETURN;
    ELSE
        IF vv_dstatus = 'WARNING'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Warning ');
            :ret_code    := 'WARNING';
        ELSIF vv_dstatus != 'NORMAL'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Erreur ');
            :ret_code    := 'FAILURE';
            RETURN;
        END IF;
    END IF;

    DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale');
    :ret_code        := 'SUCCESS';*/
    --> OBE artf2184553
  /*  
    DBMS_OUTPUT.put_line ('Soumission du traitement sans référence de lettrage, période actuelle 1');                          
    vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            vv_gl_access_set_id, --ARGUMENT1
                            --vv_ledger_id, --ARGUMENT2
                            rec_period.ledger_id, --ARGUMENT2
                            'Toutes les devises', --ARGUMENT3
                            2, --ARGUMENT4
                            'Y', --ARGUMENT5
                            rec_period.period_name_3, --ARGUMENT6
                            rec_period.period_name_4, --ARGUMENT7
                            --- 07/01/19   NBO artf3058144 : INC0277858 - SPE177 - Lettrage GL 
                            --('15/'||to_char(ADD_MONTHS( SYSDATE, -1 ),'MM')||to_char(SYSDATE,'/YY')), --ARGUMENT8
                            to_char(ADD_MONTHS(to_date('15/'||to_char(SYSDATE,'MM/YY'),'DD/MM/YY'),-1),'DD/MM/YY'), --ARGUMENT8
                            ('15/'||to_char(SYSDATE,'MM/YY')), --ARGUMENT9
                            vv_chart_of_account_id, --ARGUMENT10
                            NULL,
                            NULL
                            --vv_cle_de, --ARGUMENT11
                            --vv_cle_a --ARGUMENT12
                        );    
    --> OBE                        
    --DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande'); -- OBE artf2184553
    vn_traitement := vn_traitement + 1;                                                 -- OBE artf2184553
    vt_traitement(vn_traitement).request_id   := vn_request_id;                         -- OBE artf2184553
    
    COMMIT;

    IF vn_request_id = 0
    THEN
        DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
        :ret_code    := 'FAILURE';
        RETURN;
    END IF;

    DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
    vn_trt_lances := vn_trt_lances + 1; -- OBE artf2184553

    */
    --< OBE artf2184553
    /*IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
    THEN
        :ret_code    := 'FAILURE';
        RETURN;
    ELSE
        IF vv_dstatus = 'WARNING'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Warning ');
            :ret_code    := 'WARNING';
        ELSIF vv_dstatus != 'NORMAL'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Erreur ');
            :ret_code    := 'FAILURE';
            RETURN;
        END IF;
    END IF;

    DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale');
    :ret_code        := 'SUCCESS'; */   
    --> OBE artf2184553
    
  /* SHA 
  IF rec_period.period_if = 'MAI' OR rec_period.period_if = 'JUN' OR rec_period.period_if = 'JUL' OR rec_period.period_if = 'AOU' OR rec_period.period_if = 'SEP' OR rec_period.period_if = 'OCT' 
	   OR rec_period.period_if = 'NOV' OR rec_period.period_if = 'DEC'  --SNK artf3061958 04/02/2019  --SCH : ajout de jun et mai
    THEN
	
    DBMS_OUTPUT.put_line ('Soumission du traitement sans référence de lettrage, période actuelle 2');                          
    vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            vv_gl_access_set_id, --ARGUMENT1
                            --vv_ledger_id, --ARGUMENT2
                            rec_period.ledger_id, --ARGUMENT2
                            'Toutes les devises', --ARGUMENT3
                            2, --ARGUMENT4
                            'Y', --ARGUMENT5
                            rec_period.period_name_2_1, --ARGUMENT6 SNK artf3061958 04/02/2019
                            rec_period.period_name, --ARGUMENT7
                            NULL, --ARGUMENT8
                            NULL, --ARGUMENT9
                            vv_chart_of_account_id, --ARGUMENT10
                            NULL,
                            NULL
                            --vv_cle_de, --ARGUMENT11
                            --vv_cle_a --ARGUMENT12
                        );    
    --> OBE                        
    --DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande'); -- OBE artf2184553
    vn_traitement := vn_traitement + 1;                                                 -- OBE artf2184553
    vt_traitement(vn_traitement).request_id   := vn_request_id;                         -- OBE artf2184553
        
    COMMIT;
    
	ELSE
	
	DBMS_OUTPUT.put_line ('Soumission du traitement sans référence de lettrage, période actuelle 2');                          
    vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            vv_gl_access_set_id, --ARGUMENT1
                            --vv_ledger_id, --ARGUMENT2
                            rec_period.ledger_id, --ARGUMENT2
                            'Toutes les devises', --ARGUMENT3
                            2, --ARGUMENT4
                            'Y', --ARGUMENT5
                            rec_period.period_name_2, --ARGUMENT6
                            rec_period.period_name, --ARGUMENT7
                            NULL, --ARGUMENT8
                            NULL, --ARGUMENT9
                            vv_chart_of_account_id, --ARGUMENT10
                            NULL,
                            NULL
                            --vv_cle_de, --ARGUMENT11
                            --vv_cle_a --ARGUMENT12
                        );    
    --> OBE                        
    --DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande'); -- OBE artf2184553
    vn_traitement := vn_traitement + 1;                                                 -- OBE artf2184553
    vt_traitement(vn_traitement).request_id   := vn_request_id;                         -- OBE artf2184553
        
    COMMIT;
	
	END IF;
	
    IF vn_request_id = 0
    THEN
        DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
        :ret_code    := 'FAILURE';
        RETURN;
    END IF;

    DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
    vn_trt_lances := vn_trt_lances + 1; -- OBE artf2184553 
*/
    
   --< OBE artf2184553  
   /* IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
    THEN
        :ret_code    := 'FAILURE';
        RETURN;
    ELSE
        IF vv_dstatus = 'WARNING'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Warning ');
            :ret_code    := 'WARNING';
        ELSIF vv_dstatus != 'NORMAL'
        THEN
            DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Erreur ');
            :ret_code    := 'FAILURE';
            RETURN;
        END IF;
    END IF;

    DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale');
    :ret_code        := 'SUCCESS';   */   

    --> OBE artf2184553
    
    --RETURN;
  END LOOP;
  
   --< OBE artf2184553
    FOR vn_indice IN 1..vn_traitement 
    LOOP
        IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, 20, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
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
    
    --> OBE artf2184553

    
EXCEPTION
    WHEN OTHERS
    THEN
        DBMS_OUTPUT.put_line (cv_prog_name || ' ==> ERREUR : ' || SQLERRM);
        :ret_code    := 'FAILURE';
        
END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
