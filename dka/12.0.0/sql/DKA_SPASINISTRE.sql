---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPASINISTRE.sql
-- DESCRIPTION      : Lancement automatique du traitement SPASINISTRE
---
--- AUTEUR           : G. LE NEZET (CGEY)
--- DATE DE CREATION : 24/07/2002
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 10/01/2017 NBO artf2077350 - SPE051 - Plantage Automatisation si pas de période GL ouverte
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_prog_name            CONSTANT VARCHAR2 (30)  := 'DKA_SPASINISTRE';
    cn_tempo                CONSTANT NUMBER         := 20;
    vv_user                          VARCHAR2 (80)  := '&&1';
    vv_resp                          VARCHAR2 (80)  := '&&2';
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
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
	vv_bool 						 BOOLEAN;
	vn_traitement                    NUMBER         := 0;
	vn_indice                        NUMBER;
	vn_trt_a_lancer                  NUMBER:=0;
    vn_trt_lances                    NUMBER:=0;
	vn_trt_non_lances                NUMBER:=0;
    vn_trt_normal                    NUMBER:=0;
    vn_trt_erreur                    NUMBER:=0;
	
    vn_trt_warning                   NUMBER:=0;
	
	TYPE myrecord IS RECORD (
	 request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;
	
	
    --  09/12/2016 NBO artf2059148 - Traitement multi-org + définition du traitement
	CURSOR cur_organisation IS
	SELECT   hou.ORGANIZATION_ID,
	         hou.name
		FROM     PER_SECURITY_PROFILES psp,
				 PER_SECURITY_ORGANIZATIONS pso,
				 HR_OPERATING_UNITS hou
		WHERE    pso.SECURITY_PROFILE_ID = psp.SECURITY_PROFILE_ID
		   AND   pso.ORGANIZATION_ID = hou.ORGANIZATION_ID
		   AND   psp.SECURITY_PROFILE_ID = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL');
		   
BEGIN
    DBMS_OUTPUT.put_line ('Recuperation des identifiants user');
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

    DBMS_OUTPUT.put_line ('Recuperation des identifiants programme');
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

    --  09/12/2016 NBO artf2059148 - Traitement multi-org + définition du traitement
	MO_GLOBAL.INIT('AR');
	
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
	
    --  09/12/2016 NBO artf2059148 - Traitement multi-org + définition du traitement
	FOR rec_organisation IN cur_organisation LOOP
		--  09/12/2016 NBO artf2059148 - Traitement multi-org + définition du traitement
		DBMS_OUTPUT.put_line ('Positionne l''organisation');
        FND_REQUEST.SET_ORG_ID(rec_organisation.organization_id);
		MO_GLOBAL.set_policy_context('S',rec_organisation.organization_id);
		DBMS_OUTPUT.put_line ('ORG_ID : ' ||MO_GLOBAL.get_current_org_id);
		
		


		DBMS_OUTPUT.put_line ('Recuperation des parametres');
		BEGIN
			dka_tools_pkg.get_request_set_params (
				pv_errbuf                      => vv_errbuf,
				pn_retcode                     => vn_retcode,
				pn_application_id              => NULL,
				pn_request_set_id              => NULL,
				pn_request_set_program_id      => NULL,
				pn_prog_application_id         => vn_prog_application_id,
				pn_program_id                  => vn_program_id
			);
			
			IF vn_retcode != 0
			THEN
				DBMS_OUTPUT.put_line ('Impossible de récupérer les paramètres :');
				DBMS_OUTPUT.put_line (vv_errbuf);
				:ret_code    := 'FAILURE';
				RETURN;
			END IF;
		--- 10/01/2017 NBO artf2077350 - SPE051 - Plantage Automatisation si pas de période GL ouverte
		EXCEPTION
			WHEN OTHERS THEN
			DBMS_OUTPUT.put_line ('Impossible de récupérer la période');
			vn_trt_non_lances := vn_trt_non_lances + 1;
			CONTINUE;
		END;
		
		
		--  09/12/2016 NBO artf2059148 - Traitement multi-org + définition du traitement
		DBMS_OUTPUT.put_line ('Positionne la langue');
        vv_bool := FND_REQUEST.SET_OPTIONS(language => 'FRENCH', territory => 'FRANCE');

		DBMS_OUTPUT.put_line ('Soumission du traitement pour ' || rec_organisation.name);
		vn_request_id    := fnd_request.submit_request (
								vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
								cv_prog_name, --SHORT_NAME du TRAITEMENT
								NULL, --PROGRAM_NAME
								NULL, --START
								FALSE, --SUB_REQUEST
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
		DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
		vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id   := vn_request_id;
		vn_trt_a_lancer := vn_trt_a_lancer + 1;
		COMMIT;

		/*IF vn_request_id = 0
		THEN
			DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
			:ret_code    := 'FAILURE';
			RETURN;
		END IF;*/

		DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));

		/*IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
		THEN
			:ret_code    := 'FAILURE';
			RETURN;
		ELSE
			IF vv_dstatus = 'WARNING'
			THEN
				DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Warning ');
				:ret_code    := 'WARNING';
				RETURN;
			ELSIF vv_dstatus != 'NORMAL'
			THEN
				DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Erreur ');
				:ret_code    := 'FAILURE';
				RETURN;
			END IF;
		END IF;*/
	END LOOP;
	
	FOR vn_indice IN 1..vn_traitement 
	LOOP
		IF NOT fnd_concurrent.wait_for_request (vt_traitement(vn_indice).request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
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

    ------------------------------------
    --- 10/01/2017 NBO artf2077350 - SPE051 - Plantage Automatisation si pas de période GL ouverte
	DBMS_OUTPUT.PUT_LINE (CHR(10)||'==> Nombre de traitements non lancés en erreur   : '||TO_CHAR(vn_trt_non_lances, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements à lancer             : '||TO_CHAR(vn_trt_a_lancer, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines normalement : '||TO_CHAR(vn_trt_normal, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en warning  : '||TO_CHAR(vn_trt_warning, '99990'));
    DBMS_OUTPUT.PUT_LINE ('==> Nombre de traitements termines en erreur   : '||TO_CHAR(vn_trt_erreur, '99990'));
	

    IF vn_trt_erreur > 0 THEN
		:ret_code    := 'FAILURE';
        RETURN; 
    END IF;	
	
    DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale');
    :ret_code        := 'SUCCESS';
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
