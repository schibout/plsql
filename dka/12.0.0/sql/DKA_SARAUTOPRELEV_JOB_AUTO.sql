---------------------------------------------------------------------------------------------------------------
-- $Id: $
-- CAP GEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SARAUTOPRELEV_JOB_AUTO.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_SARAUTOPRELEV_JOB_AUTO
---
--- AUTEUR           : S.HAHIOUI
--- DATE DE CREATION : 30/11/2020
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- --------------------------------------------------------------------------------------------
--- ARA EDB379 - MISE EN PLACE DES PRELEVEMENTS EXPRESS
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
  cv_prog_name            CONSTANT VARCHAR2 (30)  := 'DKA_SARAUTOPRELEVBQUE';
  cn_tempo                CONSTANT NUMBER         := 20;
  
  vv_planif                        VARCHAR2(10)    := '&&1';--YWA artf2097725  
  vv_date_echeance                 VARCHAR2(8); -- format YYYYMMDD
  vv_user                          VARCHAR2 (80)  := '&&2';
  vv_resp                          VARCHAR2 (80)  := '&&3';
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
  vv_region                        VARCHAR2 (80);
  vn_tempo                         NUMBER         := 20;
  vn_traitement                    NUMBER         := 0;
  vn_trt_normal                    NUMBER:=0;
  vn_trt_erreur                    NUMBER:=0;
  vn_trt_warning                   NUMBER:=0;
  
  TYPE myrecord IS RECORD (
         request_id    NUMBER);

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;
	
 CURSOR cur_region IS
			SELECT distinct substr(organization_name, 1, 3) region
			FROM	MO_GLOB_ORG_ACCESS_TMP
			 
; 
  
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
			  WHEN (vv_planif = 'ECHE20' AND TO_CHAR(SYSDATE, 'DD') >= '20') THEN TO_CHAR(trunc(add_months(SYSDATE, 1), 'MM') + 19, 'YYYYMMDD') --Le 20 du mois suivant            
              WHEN (vv_planif = 'ECHE20' AND TO_CHAR(SYSDATE, 'DD') < '20') THEN TO_CHAR(trunc(SYSDATE, 'MM') + 19, 'YYYYMMDD') --Le 20 du mois en cours   
              WHEN vv_planif = 'ECHEFDM' THEN TO_CHAR(last_day(SYSDATE), 'YYYYMMDD')                      --Le dernier jour du mois en cours
			  WHEN vv_planif = 'EXPRESS' THEN TO_CHAR(SYSDATE, 'YYYYMMDD')  --ARA EDB379
         ELSE NULL END
  INTO vv_date_echeance
  FROM DUAL;
    
	FOR rec_cur_region IN cur_region LOOP
	
  DBMS_OUTPUT.put_line ('Planif ' || vv_planif || ' => Date calculée = ' || vv_date_echeance);             
  DBMS_OUTPUT.put_line ('Soumission du traitement');
  vn_request_id    := fnd_request.submit_request (
                        vv_prog_application_short_name,      --APPLICATION PROPRIETAIRE DU TRAITEMENT
                        cv_prog_name,                        --SHORT_NAME du TRAITEMENT
                        NULL,                                --PROGRAM_NAME
                        NULL,                                --START
                        FALSE,                               --SUB_REQUEST
                        vv_date_echeance,                    --ARGUMENT1
                        rec_cur_region.region				 --ARGUMENT2
												);
		
        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id   := vn_request_id;
        COMMIT;

        IF vn_request_id = 0 THEN
           DBMS_OUTPUT.PUT_LINE ('Impossible de lancer le Traitement ');
           DBMS_OUTPUT.PUT_LINE (vv_errbuf);
		       :ret_code    := 'FAILURE';
		RETURN;
        END IF;	

		
	END LOOP;


	
  DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
  --COMMIT;
/*
  IF vn_request_id = 0 THEN
    DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
    :ret_code    := 'FAILURE';
    RETURN;
  END IF;

  DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
*/
  	
	    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
    FOR vn_indice IN 1..vn_traitement 
    LOOP
        IF NOT Fnd_Concurrent.wait_for_request (vt_traitement(vn_indice).request_id, vn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
           DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
           RETURN;
		ELSE
           /*IF vv_dstatus = 'NORMAL' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
              vn_trt_normal := vn_trt_normal + 1;
              RETURN;
		   ELS*/IF vv_dstatus = 'WARNING' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
              vn_trt_warning := vn_trt_warning + 1;
              
		   ELSIF vv_dstatus != 'NORMAL' THEN
              DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
              vn_trt_erreur := vn_trt_erreur + 1;
			  
		   END IF;
        END IF;

     	  
	END LOOP;
	
	  DBMS_OUTPUT.put_line ('verifier le code retour du traitement vn_trt_erreur'||vn_trt_erreur||' ----  vn_trt_warning' ||vn_trt_warning);
	IF vn_trt_erreur > 0 THEN
		:ret_code    := 'FAILURE';
		DBMS_OUTPUT.put_line ('le traitement est en erreur');
		RETURN;
		ELSIF vn_trt_warning > 0 THEN
		:ret_code    := 'WARNING';
		DBMS_OUTPUT.put_line ('le traitement est en warning');
		RETURN;
	  ELSE 
		:ret_code := 'SUCCESS';
		RETURN;

	END IF;
	
	/*
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
*/
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
