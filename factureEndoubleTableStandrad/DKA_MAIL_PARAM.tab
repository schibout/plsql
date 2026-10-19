create or replace PACKAGE BODY DKA_SPOAUTFERMCMD_CITY_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SPOAUTFERMCMD_CITY_PKG.pkb
    -- DESCRIPTION      : DKA_SPOAUTFERMCMD_CITY_PKG Package Body
    --
    -- AUTEUR           : Anas RAOUF (Capgemini)
    -- DATE DE CREATION : 12/05/2021
    -- COMMENTAIRES     : A exÃ©cuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- -----------------------------------------------------------------------------
    
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


   
    g_request_id      VARCHAR2(30) := fnd_global.CONC_REQUEST_ID;
    gv_created_by      VARCHAR2(60) := fnd_profile.value('USER_NAME');
    
	g_user_id          PLS_INTEGER  := fnd_profile.value('USER_ID');
	g_resp_id          PLS_INTEGER  := fnd_profile.value('RESP_ID');
    g_org_id           PLS_INTEGER  := FND_GLOBAL.org_id;
	g_resp_appl_id     PLS_INTEGER  := fnd_global.resp_appl_id;
    g_login_id                     fnd_logins.login_id%TYPE;
	cv_directory CONSTANT VARCHAR2(50) := 'DKA_OUT_DIR';
	
    g_step             VARCHAR2(500);



	
/*
 *************************************************************************
 * PROCEDURE NAME : Output_Header
 *
 * DESCRIPTION
 *  Procédure pour insérer une en-tête dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (1000);
        v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

        cv_line    := '+-----------------------------------------------------------------------------------------------------------------+';

        ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
        BEGIN
            SELECT fcp.concurrent_program_name,
                   fcpt.user_concurrent_program_name
            INTO   v_conc_program_name,
                   v_user_conc_program_name
            FROM   fnd_concurrent_programs fcp,
                   fnd_concurrent_programs_tl fcpt
            WHERE  fcp.application_id = Fnd_Global.prog_appl_id
            AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.application_id = Fnd_Global.prog_appl_id
            AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
            AND    fcpt.LANGUAGE = Fnd_Global.current_language;
        EXCEPTION
            WHEN OTHERS
            THEN
                v_user_conc_program_name    := '???????????????????????';
                v_conc_program_name         := '???????';
        END;


        Fnd_File.put_line (Fnd_File.output, cv_line );
		Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Automatisation de la fermeture automatique des commandes intragroupe CITY »');
        Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
		Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
  END output_header;
 

 /*
 *************************************************************************
 * PROCEDURE NAME : Output_End
 *
 * DESCRIPTION
 *  Procédure pour insérer une fin dans le fichier de sortie
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 *
 *
 ************************************************************************
 */

  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (1000);
  BEGIN

        cv_line    := '+---------------------------------------------------------------------+';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;

  -----------------------------------------------------------------
	--  Nom           : OUT_MSG
	--  Description   : procedure d'affichage des messages
	--
	--  PARAMETRES :
	--   p_message          texte a imprimer dans la sortie
	--
	-----------------------------------------------------------------
	PROCEDURE out_msg(p_message in varchar2) IS
	BEGIN
	  -- Ecriture dans le fichier de sortie
	  fnd_file.put_line(fnd_file.output, p_message);
	END out_msg;


    -----------------------------------------------------------------
    --  Nom           : LOG_MSG
    --  Description   : procedure d'affichage des messages
    --
    --  PARAMETRES :
    --   p_message      texte a imprimer dans le log
    --
    -----------------------------------------------------------------
    PROCEDURE log_msg(p_message in varchar2) IS
        l_message VARCHAR2(1000);
    BEGIN

        l_message := SUBSTR(p_message, 1, 1000);

        IF (l_message IS NULL) THEN
            l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.LOG, l_message);
    END log_msg;

  

PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER
                   )
IS
	v_errbuf                          VARCHAR2(2500);
	v_retcode                         NUMBER;
	Erreur_Programme                  EXCEPTION;
    AVR_Programme                     EXCEPTION;
	cv_line                           VARCHAR2 (100);
	v_current_program_unit            VARCHAR2(30);
	vn_nb_line                        NUMBER;
	vv_file_name                      VARCHAR2(70);
	v_period					      VARCHAR2(20);
	cv_request_name_1                 CONSTANT VARCHAR2 (30)  := 'DKA_SPOAUTCMD_CITY';
	cv_request_name_2                 CONSTANT VARCHAR2 (30)  := 'DKA_SPOCMDMAIL_CITY';
	cn_tempo                          CONSTANT NUMBER         := 20;
	Vr_Data                           Dka_Parameters%ROWTYPE;
	vv_resp                           VARCHAR2 (80)  ;
	vv_errbuf                         VARCHAR2 (500) := NULL;
	vn_retcode                        NUMBER         := 0;
	vv_err_retcode					  NUMBER         := 0;
	vv_warn_retcode					  NUMBER         := 0;
	vn_req_application_id             NUMBER (15);
	vv_req_application_short_name     VARCHAR2 (50);
	vn_responsibility_id              NUMBER (15);
	vn_application_id                 NUMBER (15);
	vn_user_id                        NUMBER (15);
	vn_request_id                     NUMBER (15);
	vn_request_idd                     NUMBER (15);
	vn_new_request_id				  BOOLEAN;
	v_req_id                          NUMBER (15);
	vv_rphase                         VARCHAR2 (80);
	vv_rrphase                        VARCHAR2 (80);
	vv_rstatus                        VARCHAR2 (80);
	vv_rrstatus                       VARCHAR2 (80);
	vv_dphase                         VARCHAR2 (30);
	vv_ddphase                        VARCHAR2 (30);
	vv_dstatus                        VARCHAR2 (30);
	vv_ddstatus                       VARCHAR2 (30);
	vv_message                        VARCHAR2 (240);
	vvv_message                       VARCHAR2 (240);
	v_autopost_set_id                 NUMBER;   
	vn_cpt                            NUMBER (10);
	
	vn_retcode_1                      NUMBER         := 0;
	vn_retcode_2                      NUMBER         := 0;
	vv_msg							  VARCHAR2 (30);
    vv_etat                           BOOLEAN;
	vv_warn                           BOOLEAN;
    vv_err                            BOOLEAN;
	
    
    CURSOR cur_region IS
    SELECT ffv.flex_value REGION
          from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
         where ffvs.flex_value_set_id = ffv.flex_value_set_id
           and ffvs.flex_value_set_name = 'DAOPCCF_UO'
           and ffv.ENABLED_FLAG = 'Y'
           AND ffv.flex_value != 'REF'
           and ffv.SUMMARY_FLAG = 'N';
		   
	CURSOR cur_trt_fils IS
	SELECT req.request_id Trt_fils , SUBSTR(req.argument_text,INSTR(req.argument_text,',')+2,3 ) region 
		FROM fnd_concurrent_requests req , fnd_concurrent_programs_tl pro
		WHERE req.request_id > g_request_id 
       AND req.concurrent_program_id = pro.concurrent_program_id
       AND pro.language = 'F' 
		AND user_concurrent_program_name = 'DKA : Edition et envoi par mail de l''état de la facturation et des commandes CITY';
 
BEGIN
	  
	  
      Output_Header;
    
      BEGIN
		  SELECT period_name
				INTO v_period
				FROM gl_periods
				WHERE period_set_name = 'GROUPE'
				AND start_date = (SELECT min(start_date)
				FROM gl_period_statuses
				WHERE application_id = 200 
				AND ledger_id in (select distinct set_of_books_id
				FROM hr_operating_units
				where organization_id in ( SELECT organization_id 
				FROM PER_SECURITY_ORGANIZATIONS
				WHERE SECURITY_PROFILE_ID = (
				SELECT SECURITY_PROFILE_ID
				FROM PER_SECURITY_PROFILES
				WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')) )  
				AND closing_status = 'O');
		  EXCEPTION
		  WHEN OTHERS THEN
		  v_period := NULL;
	   END;
	   
	   
	   
	   IF v_period IS NULL THEN
		  Pn_Retcode := 2;
		  out_msg('ERREUR : Impossible de déterminer la période en cours.'|| CHR(10));
		  -- raise chi exception pour sortie
          RAISE Erreur_Programme;
	    ELSE
       
		vv_err := FALSE;
		
		out_msg('Période en cours : ' || v_period || CHR(10));
		-- 1
		g_step := 'Recuperation des infos sur le traitement ' || cv_request_name_1 ;
		log_msg(g_step);
        
        BEGIN   
		SELECT fcp.application_id,
			   fa.application_short_name
		INTO   vn_req_application_id,
			   vv_req_application_short_name
		FROM   fnd_concurrent_programs fcp,
			   fnd_application fa 
		WHERE  fcp.concurrent_program_name = cv_request_name_1
		AND    fa.application_id = fcp.application_id;
		EXCEPTION
        WHEN NO_DATA_FOUND THEN
        vn_req_application_id := 0;
        vv_req_application_short_name := NULL;
        END;
        
		vn_request_id := fnd_request.submit_request ( vv_req_application_short_name,   -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                  cv_request_name_1,                  -- SHORT NAME DU TRAITEMENT
                                                  NULL,                             -- PROGRAM NAME
                                                  NULL,                             -- START
                                                  FALSE,                            -- SUB REQUEST
                                                  v_period
                                                   );
                                                   
    
		--DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
		g_step := 'Validation pour que les GTS puissent prendre la demande';
		log_msg(g_step);
		COMMIT;
		
		IF vn_request_id = 0
		THEN
			
		  g_step := 'Impossible de lancer le Traitement ' || vv_errbuf;
		  log_msg(g_step);
          vv_err := TRUE;
		  --Pn_Retcode := 2;
		  --vv_etat := TRUE;
		ELSE
		  g_step := 'Le Traitement ' || cv_request_name_1 || ' N° ' || vn_request_id || ' a été bien lancé';
		  log_msg(g_step);
		END IF;
		
		IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
        
		vn_retcode_1 := 2;
       
		ELSE
		   IF vv_dstatus = 'WARNING' THEN
			  
			 g_step := CHR (10) || '>>> Traitement terminé en Warning ';
			 log_msg(g_step);
			 vn_retcode_1 := 1;
		   ELSIF vv_dstatus != 'NORMAL' THEN
			
			  g_step := CHR (10) || '>>> Traitement terminé en Erreur ';
			 log_msg(g_step);
			 vn_retcode_1 := 2;
		   END IF;
		END IF;
		
		IF vn_retcode_1 = 2 THEN
			vv_msg := 'Erreur';
		ELSIF vn_retcode_1 = 1 THEN
			vv_msg := 'Avertissement';
		ELSE 
			vv_msg := 'Normal';
		END IF;
		
		Fnd_File.put_line (Fnd_File.output, 'DKA : Fermeture automatique des commandes intragroupe CITY : ');      
		Fnd_File.put_line (Fnd_File.output, '------------------------------------------------------------------' );
		
        IF (vv_err) THEN
            Fnd_File.put_line (Fnd_File.OUTPUT, 'ERREUR : Erreur lors du lancement du traitement.' || CHR(10)); 
        ELSE
            cv_line := 'Numéro de traitement : ' || RPAD(vn_request_id,9,' ') ||'           Statut : '|| NVL(vv_msg,' ')  ;
            Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
        END IF;
		
		-- Step 2
		
        vv_etat:= FALSE;
		vv_warn := FALSE;
        vv_err := FALSE;
        
        Fnd_File.put_line (Fnd_File.output, 'DKA : Edition et envoi par mail de l''état de la facturation et des commandes CITY : ');      
		Fnd_File.put_line (Fnd_File.output, '--------------------------------------------------------------------------------------' );
        
        FOR rec_region IN cur_region
        LOOP
            
			g_step := 'Récupération des infos sur le traitement ' || cv_request_name_2 ;
			log_msg(g_step);
           
			SELECT fcp.application_id,
				   fa.application_short_name
			INTO   vn_req_application_id,
				   vv_req_application_short_name
			FROM   fnd_concurrent_programs fcp,
				   fnd_application fa 
			WHERE  fcp.concurrent_program_name = cv_request_name_2
			AND    fa.application_id = fcp.application_id;
			
			------------------
			
			log_msg('Responsablilité trouvée : ' || rec_region.REGION || '_PO_FERMETURE_DEFINITIVE');
			
			DBMS_OUTPUT.PUT_LINE ('Recuperation des identifiants user');
			SELECT fr.responsibility_id,
				   fr.application_id
			INTO   vn_responsibility_id,
				   vn_application_id
			FROM   fnd_responsibility_vl fr
			WHERE  fr.responsibility_name = rec_region.REGION || '_PO_FERMETURE_DEFINITIVE';

			SELECT user_id
			INTO   vn_user_id
			FROM   fnd_user
			WHERE  user_name = rec_region.REGION;
			
			DBMS_OUTPUT.PUT_LINE ('Initialisation dans le contexte O.A.');
			fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
			EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
			
			
			vn_request_idd := fnd_request.submit_request ( vv_req_application_short_name,   -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                  cv_request_name_2,                  -- SHORT NAME DU TRAITEMENT
                                                  NULL,                             -- PROGRAM NAME
                                                  NULL,                             -- START
                                                  FALSE,                            -- SUB REQUEST
                                                  v_period,		-- First ARG
												  rec_region.REGION -- Second ARG
                                                   );
                                                   
    
			--DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
			g_step := 'Validation pour que les GTS puissent prendre la demande';
			log_msg(g_step);
			COMMIT;
			
			IF vn_request_idd = 0
			THEN
				
			  g_step := 'Impossible de lancer le Traitement ' || vv_errbuf;
			  log_msg(g_step);
              vv_err := TRUE;
             --Fnd_File.put_line (Fnd_File.OUTPUT, 'ERREUR : Erreur lors du lancement du traitement.');        
              
              
			ELSE
			  g_step := 'Le Traitement ' || cv_request_name_2 || ' N° ' || vn_request_idd || ' a été bien lancé';
			  log_msg(g_step);
			END IF;
			
		END LOOP;
			

        vv_err := FALSE;
			
		log_msg('BEFORE ');
		
		log_msg('parent request id :' || g_request_id);
		
		FOR rec_fils IN cur_trt_fils LOOP
			
			log_msg('Numéro du traitement fils : ' || rec_fils.Trt_fils);
			
			IF NOT fnd_concurrent.wait_for_request (rec_fils.Trt_fils, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
			
			vn_retcode_2 := 2;
		   
			ELSE
			   IF vv_dstatus = 'WARNING' THEN
				  
				 g_step := CHR (10) || '>>> Traitement terminé en Warning ';
				 log_msg(g_step);
				 vn_retcode_2 := 1;
				 
			   ELSIF vv_dstatus != 'NORMAL' THEN
				
				 g_step := CHR (10) || '>>> Traitement terminé en Erreur ';
				 log_msg(g_step);
				 vn_retcode_2 := 2;
			   END IF;
			END IF;
			
			IF vn_retcode_2 = 2 THEN
				vv_msg := 'Erreur';
                vv_etat := TRUE;
			ELSIF vn_retcode_2 = 1 THEN
				vv_warn := TRUE;
				vv_msg := 'Warning';
			ELSE 
				vv_msg := 'Normal';
			END IF;
			
			log_msg('Statut du traitement fils : ' || vv_msg);
			
            IF (vv_err) THEN
                Fnd_File.put_line (Fnd_File.OUTPUT, 'ERREUR : Erreur lors du lancement du traitement.' || CHR(10)); 
                RAISE Erreur_Programme;
            ELSE
                cv_line := 'Région : ' || RPAD(NVL(rec_fils.region, ' '),9,' ') ||'           Numéro de traitement : '|| RPAD(rec_fils.Trt_fils,9,' ') || '         Statut : ' || NVL(vv_msg,' ');
                Fnd_File.put_line (Fnd_File.output, cv_line);
            END IF;
				
			
			vn_retcode_2 := 0;
			
        END LOOP;
		
		
        
	   END IF; -- big if
       
	   Fnd_File.put_line (Fnd_File.output, CHR(10));
	  
		
		IF (vv_etat) OR vn_retcode_1 = 2 THEN
			RAISE Erreur_Programme;
		END IF;
		
		IF (vv_warn) OR vn_retcode_1 = 1 THEN
			RAISE AVR_Programme;
		END IF;
	   
	   
      output_end;
	  EXCEPTION
        WHEN Erreur_Programme THEN
            Pn_Retcode   := 2;
            Pv_Errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
            Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement ');        
			output_end;
		WHEN AVR_Programme THEN
            Pn_Retcode   := 1;
            Pv_Errbuf    := v_errbuf;
            Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||Pv_Errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
            Fnd_File.put_line (Fnd_File.OUTPUT, '===> AVERTISSEMENT : Fin anormale du traitement ');        
			output_end;
       WHEN OTHERS 
       THEN
           fnd_concurrent.af_rollback;
           Pn_Retcode := 2;
           Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SPOAUTFERMCMD_CITY_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
           Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '===> Erreur technique (voir journal du traitement)' || CHR(10));
           Pv_Errbuf := SQLERRM;
END main;

END DKA_SPOAUTFERMCMD_CITY_PKG;

/
SHOW ERRORS;
EXIT