---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI 
-- $Id$
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SAPRPTMVTSSANSIMAGE.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_SAPRPT_MVTS_SANS_IMAGE
---
-- AUTEUR           : Maheswara Thunga
-- DATE DE CREATION : 21/05/2010
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
-------------- --- --------------------------------------------------------------------------------------------
--- 2016/07/05 JJA Portage Helios R12
--- 2017/03/10 EFL Modification suite artf2116842 : Recherche des infos du programme et affichage csp/division
--- 2021/12/23 AFE - TASK0162876 : Ajout HINT + ajout to_char pour éviter le plantage du traitement
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    CURSOR C_CSP is                                   --PN code Starts
     select /*+ INDEX(dsl2 DKA_STRANSCO_LINES_U1)*/ 
	distinct dsl.param1_value Division,
                    dsl.return_value CSP,
                    fr.responsibility_id,
                    fr.application_id
    from  DKA_STRANSCO_HEADERS dsh,
          DKA_STRANSCO_LINES dsl ,
          dka_stransco_headers dsh2,
          dka_stransco_lines   dsl2,
          fnd_responsibility fr
    where dsh.set_id=dsl.set_id  
    and dsh.set_name='CENTRE_SERVICE_PARTAGE'
    and DSL.param1_value='ENERGIE'
    and dsh2.set_id = dsl2.set_id
    AND dsh2.set_name =  'DKA_CSP_RESP'
    and dsl.return_value=dsl2.param1_value
    and to_char(fr.responsibility_id) = dsl2.return_value;
                   
    
    TYPE t is table of number
    INDEX by BINARY_INTEGER;                           
    cv_prog_name            CONSTANT VARCHAR2 (30)  := 'DKA_SAPRPT_MVTS_SANS_IMAGE';
    cn_tempo                CONSTANT NUMBER         := 20;
    vv_user                          VARCHAR2 (80)  := '&&1';
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
    vn_prog_application_id           NUMBER (15);
    vv_prog_application_short_name   VARCHAR2 (50);
    vn_program_id                    NUMBER (15);
    vn_responsibility_id             NUMBER (15);
    vn_application_id                NUMBER (15);
    vv_application_short_name        VARCHAR2 (50);
    vn_user_id                       NUMBER (15);
    vn_request_id                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vv_status                        VARCHAR2 (400);
    
    vd_pay_through_date              DATE;
    vd_payment_date                  DATE;
    v_request t;                   
    v_count number;               
    
BEGIN
    
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
		   

	MO_GLOBAL.INIT ('SQLAP'); --2016/07/05

    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';

    DBMS_OUTPUT.put_line ('Recuperation des parametres');
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
        DBMS_OUTPUT.put_line ('Impossible de récupérer les parametres :');
        DBMS_OUTPUT.put_line (vv_errbuf);
        :ret_code    := 'FAILURE';
        RETURN;
    END IF;	

	v_count:=1;
    FOR rec in c_csp LOOP 	
    	
    DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
    fnd_global.apps_initialize (vn_user_id, rec.responsibility_id, rec.application_id);
	
    DBMS_OUTPUT.put_line ('Soumission du traitement - CSP/Division: '||rec.CSP||'/'||rec.Division);
    vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            rec.CSP,  
                            rec.Division,
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
    COMMIT;

      IF vn_request_id = 0
      THEN
          DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
          :ret_code    := 'FAILURE';
          RETURN;
      ELSE
      
        DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
        v_request(v_count):=vn_request_id;   --PN Added
        v_count:=v_count+1;
        
      END IF;
    
    END LOOP;
    
    IF v_request.count > 0 THEN
      
      FOR i in 1..v_request.last LOOP   --PN Added
       
      IF NOT fnd_concurrent.wait_for_request (v_request(i), cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
      THEN
          :ret_code    := 'FAILURE';
          RETURN;
      ELSE
          IF vv_dstatus != 'NORMAL'
          THEN
              DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Erreur ');
              :ret_code    := 'FAILURE';
              RETURN;
          END IF;
      END IF;
      
      END LOOP;
    
    END IF;  
   
    DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale');
    :ret_code        := 'SUCCESS';
    
EXCEPTION
    WHEN OTHERS
    THEN
        DBMS_OUTPUT.put_line (cv_prog_name || ' ==> ERREUR : ' || SQLERRM);
        DBMS_OUTPUT.put_line (dbms_utility.format_error_backtrace);
        :ret_code    := 'FAILURE';
END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code

