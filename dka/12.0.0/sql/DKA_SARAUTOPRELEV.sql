---------------------------------------------------------------------------------------------------------------
-- $Id: $
-- CAP GEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SARAUTOPRELEV.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_SARAUTOPRELEV
---
--- AUTEUR           : C.TROCHU 
--- DATE DE CREATION : 18/07/2008
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- --------------------------------------------------------------------------------------------
--- 23/02/2009 GV  Ajout du paramètre planification pour calcul de la date d'échéance
--- 16/09/2016 MEG Migration R12
--- 08/02/2017 YWA artf2097725  
--- 17/03/2017 OBE MODIFICATION artf2121061
--- 27/06/2024 ARA EDB379 - MISE EN PLACE DES PRELEVEMENTS EXPRESS
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
  cv_prog_name            CONSTANT VARCHAR2 (30)  := 'DKA_SARAUTOPRELEV';
  cn_tempo                CONSTANT NUMBER         := 20;
  
  -- Modif GV20090223 : ajout de la planification en paramètre, pour calcul de la date d'échéance
  vv_planif                        VARCHAR2(10)    := '&&1';--YWA artf2097725  
  vv_date_echeance                 VARCHAR2(8); -- format YYYYMMDD
  vv_user                          VARCHAR2 (80)  := '&&2';
  vv_resp                          VARCHAR2 (80)  := '&&3';
  -- fin modif sur les paramètres   
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
  INTO vn_prog_application_id,
       vv_prog_application_short_name,
       vn_program_id
  FROM fnd_concurrent_programs fcp,
       fnd_application         fa
  WHERE fcp.concurrent_program_name = cv_prog_name
    AND fa.application_id = fcp.application_id;

  DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
  fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
  MO_GLOBAL.INIT('AR');    
    
  --EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || ''''; -- OBE
  EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';                                         -- OBE

  DBMS_OUTPUT.put_line ('Recuperation des parametres');
  dka_tools_pkg.get_request_set_params (
        pv_errbuf                      => vv_errbuf,
        pn_retcode                     => vn_retcode,
        pn_application_id              => NULL,
        pn_request_set_id              => NULL,
        pn_request_set_program_id      => NULL,
        pn_prog_application_id         => vn_prog_application_id,
        pn_program_id                  => vn_program_id);

  IF vn_retcode != 0 THEN
    DBMS_OUTPUT.put_line ('Impossible de récupérer les paramètres :');
    DBMS_OUTPUT.put_line (vv_errbuf);
    :ret_code    := 'FAILURE';
    RETURN;
  END IF;
    
  -- Modif GV20090223 : calcul de la date en fonction du paramètre planification
  DBMS_OUTPUT.put_line ('Calcul de la date d''échéance');
  SELECT CASE WHEN vv_planif = 'ECHE10'  THEN TO_CHAR(trunc(add_months(SYSDATE, 1), 'MM') + 9, 'YYYYMMDD')--Le 10 du mois suivant
              WHEN vv_planif = 'ECHE20'  THEN TO_CHAR(trunc(SYSDATE, 'MM') + 19, 'YYYYMMDD')              --Le 20 du mois en cours
              WHEN vv_planif = 'ECHEFDM' THEN TO_CHAR(last_day(SYSDATE), 'YYYYMMDD')                      --Le dernier jour du mois en cours
			  WHEN vv_planif = 'EXPRESS' THEN TO_CHAR(SYSDATE, 'YYYYMMDD')  --ARA EDB379 
         ELSE NULL END
  INTO vv_date_echeance
  FROM DUAL;
    
  --ARA EDB379
  BEGIN
  
  --Suppression de l'ancienne value : 
  delete from DKA_SARAUTOPRELEV_STAT;
  
  INSERT INTO DKA_SARAUTOPRELEV_STAT 
  VALUES (vv_planif); 
  
  COMMIT;

  END;
	
	
	
  DBMS_OUTPUT.put_line ('Planif ' || vv_planif || ' => Date calculée = ' || vv_date_echeance);             
  DBMS_OUTPUT.put_line ('Soumission du traitement');
  vn_request_id    := fnd_request.submit_request (
                        vv_prog_application_short_name,      --APPLICATION PROPRIETAIRE DU TRAITEMENT
                        cv_prog_name,                        --SHORT_NAME du TRAITEMENT
                        NULL,                                --PROGRAM_NAME
                        NULL,                                --START
                        FALSE,                               --SUB_REQUEST
                        vv_date_echeance,                    --ARGUMENT1
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
                        dka_tools_pkg.tab_request_params(100)); --ARGUMENT100
  DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
  COMMIT;

  IF vn_request_id = 0 THEN
    DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
    :ret_code    := 'FAILURE';
    RETURN;
  END IF;

  DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));

  IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
    :ret_code    := 'FAILURE';
    RETURN;
  ELSE
    IF vv_dstatus = 'WARNING' THEN
      DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Warning ');
      :ret_code    := 'WARNING';
      RETURN;
    ELSIF vv_dstatus != 'NORMAL' THEN
      DBMS_OUTPUT.put_line (CHR (10) || '>>> Traitement termine en Erreur ');
      :ret_code    := 'FAILURE';
      RETURN;
    END IF;
  END IF;

  DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale');
  :ret_code        := 'SUCCESS';
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.put_line (cv_prog_name || ' ==> ERREUR : ' || SQLERRM);
    :ret_code    := 'FAILURE';
END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM DUAL;
EXIT &ret_code
