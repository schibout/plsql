create or replace PACKAGE BODY DKA_SGLIMPUTATION_PKG IS

    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : DKA_SGLIMPUTATION_PKG.pkb
    -- DESCRIPTION      : DKA_SGLIMPUTATION_PKG Package Body
    --
    -- AUTEUR           : Anas RAOUF (Capgemini)
    -- DATE DE CREATION : 05/02/2021
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- -----------------------------------------------------------------------------

    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    gv_request_id      VARCHAR2(30) := fnd_global.CONC_REQUEST_ID;
    gv_created_by      VARCHAR2(60) := fnd_profile.value('USER_NAME');
	g_user_id          PLS_INTEGER  := fnd_profile.value('USER_ID');
    g_gl_id            PLS_INTEGER  := FND_PROFILE.value('GL_ACCESS_SET_ID');
    gv_expediteur      VARCHAR2(150);
    gv_conn            VARCHAR2(30);
    g_step             VARCHAR2(500);

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

------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement
  --
  --  PARAMETRES    : Message à afficher dans le journal
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) IS

  BEGIN

    dka_tools_pkg.put_log_message(p_message);

  END p_put_debug_message;


    -------------------------------------------------------------------------------------
    --  Nom           : main
    --  Description   : Procédure principale d'exécution du traitement "DKA : Imputation GL"
    --
    --  PARAMETRES    :
    --  Pv_Errbuf      IN OUT       Message d'avertissement
    --  Pn_Retcode  IN OUT     Code erreur
   
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validite
    --     Valeurs possibles : 0: OK, 2: erreur ou code erreur ORA
    --------------------------------------------------------------------------------------
    PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER
                   ) IS

		
        cv_request_name                 CONSTANT VARCHAR2 (30)  := 'GLPAUTOP';
        cn_tempo                        CONSTANT NUMBER         := 20;
        Vr_Data                         Dka_Parameters%ROWTYPE;
        vv_resp                          VARCHAR2 (80)  ;
        vv_errbuf                        VARCHAR2 (500) := NULL;
        vn_retcode                       NUMBER         := 0;
        vv_err_retcode					 NUMBER         := 0;
        vv_warn_retcode					 NUMBER         := 0;
        vn_req_application_id            NUMBER (15);
        vv_req_application_short_name    VARCHAR2 (50);
        vn_responsibility_id             NUMBER (15);
        vn_application_id                NUMBER (15);
        vn_user_id                       NUMBER (15);
        vn_request_id                    NUMBER (15);
		vn_new_request_id				 BOOLEAN;
        v_req_id                         NUMBER (15);
        vv_rphase                        VARCHAR2 (80);
		vv_rrphase                        VARCHAR2 (80);
        vv_rstatus                       VARCHAR2 (80);
		vv_rrstatus                       VARCHAR2 (80);
        vv_dphase                        VARCHAR2 (30);
		vv_ddphase                        VARCHAR2 (30);
        vv_dstatus                       VARCHAR2 (30);
		vv_ddstatus                       VARCHAR2 (30);
        vv_message                       VARCHAR2 (240);
		vvv_message                       VARCHAR2 (240);
        v_autopost_set_id                NUMBER;   
        vn_cpt                          NUMBER (10);

        CURSOR cur_GLPPOS_trt (v_req_id NUMBER) IS
         
            Select fcr.request_id CHILD_REQUEST_ID,
                PARENT_REQUEST_ID PARENT_REQUEST_ID,
                fcp.concurrent_program_name program_name,
                fcptl.user_concurrent_program_name user_concurrent_program_name,
                fcr.phase_code phase,
                fcr.status_code status
           from apps.fnd_concurrent_requests    fcr,
                apps.fnd_concurrent_programs    fcp,
                apps.fnd_concurrent_programs_tl fcptl
          WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
            AND fcr.program_application_id = fcp.application_id
            AND fcp.application_id = fcptl.application_id
            AND fcp.concurrent_program_id = fcptl.concurrent_program_id
            AND fcptl.language = 'F'
            AND fcp.CONCURRENT_PROGRAM_NAME in ('GLPPOS', 'GLPPOSS')
            AND fcr.parent_request_id = v_req_id -- request_id du traitement GLPAUTOP
            ;

            
    BEGIN
    
    --DBMS_OUTPUT.put_line ('Recuperation des identifiants user');
    g_step := 'Récuperation des identifiants user';
    log_msg(g_step);
    
     Dka_Tools_Pkg.get_parameter('DKA_SJTGLDATAJ',
                                  'GL_RESPONSIBILITY_KEY',
                                   Vr_Data,
                                   vn_retcode,
                                   vv_errbuf);
                                   
      IF vn_retcode != 0 THEN

        
        g_step := 'Erreur de récuperation de la responsabilité : ' || vv_errbuf;
          log_msg(g_step);
          --:ret_code := 'FAILURE';
          Pn_Retcode := 2;
      END IF;                              
                                   
    vv_resp  := Vr_Data.Varchar2_Value;
    g_step := 'Responsabilité récupérée :' || vv_resp;
    log_msg(g_step);
    SELECT fr.responsibility_id,
           fr.application_id
    INTO   vn_responsibility_id,
           vn_application_id
    FROM   fnd_responsibility fr
    WHERE  responsibility_key = vv_resp;

   /* SELECT user_id
    INTO   vn_user_id
    FROM   fnd_user
    WHERE  user_name = gv_created_by;*/

    --DBMS_OUTPUT.put_line ('Recuperation des infos sur le traitement');
    g_step := 'Recuperation des infos sur le traitement';
    log_msg(g_step);
           
    SELECT fcp.application_id,
           fa.application_short_name
    INTO   vn_req_application_id,
           vv_req_application_short_name
    FROM   fnd_concurrent_programs fcp,
           fnd_application fa 
    WHERE  fcp.concurrent_program_name = cv_request_name
    AND    fa.application_id = fcp.application_id;

    --DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
    g_step := 'Initialisation dans le contexte OA';
    log_msg(g_step);
   -- fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
    
    fnd_global.apps_initialize (g_user_id, vn_responsibility_id, vn_application_id);
    
    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';

    --DBMS_OUTPUT.put_line ('Recuperation des parametres du traitement');
    g_step := 'Recuperation des parametres du traitement';
    log_msg(g_step);
    BEGIN
      SELECT autopost_set_id
      INTO v_autopost_set_id
      FROM GL_AUTOMATIC_POSTING_SETS
      WHERE autopost_set_name = 'DKA_JEU_TOTAL'
      ;
    EXCEPTION
    WHEN OTHERS THEN
      
      g_step := 'Erreur de recuperation du jeu de livre';
      log_msg(g_step);
      --:ret_code := 'FAILURE';
      Pn_Retcode := 2;
      
    END;
    
  
    
   
         vn_request_id := fnd_request.submit_request ( vv_req_application_short_name,   -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                  cv_request_name,                  -- SHORT NAME DU TRAITEMENT
                                                  NULL,                             -- PROGRAM NAME
                                                  NULL,                             -- START
                                                  FALSE,                            -- SUB REQUEST
                                                  g_gl_id,                          --argument1
                                                  v_autopost_set_id                 --argument2
                                                   );
                                                   
    
    --DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
    g_step := 'Validation pour que les GTS puissent prendre la demande';
    log_msg(g_step);
    COMMIT;
    
    IF vn_request_id = 0
    THEN
        
        g_step := 'Impossible de lancer le Traitement ' || vv_errbuf;
      log_msg(g_step);
    
      Pn_Retcode := 2;
    ELSE
      g_step := 'Le Traitement ' || cv_request_name || ' N° ' || vn_request_id || ' a été bien lancé';
      log_msg(g_step);
    END IF;
    
    IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
      
      Pn_Retcode := 2;
       
    ELSE
       IF vv_dstatus = 'WARNING' THEN
          
         g_step := CHR (10) || '>>> Traitement terminé en Warning ';
         log_msg(g_step);
         Pn_Retcode := 1;
       ELSIF vv_dstatus != 'NORMAL' THEN
        
          g_step := CHR (10) || '>>> Traitement terminé en Erreur ';
         log_msg(g_step);
         Pn_Retcode := 2;
       END IF;
    END IF;
    
    --DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
	
    select count(1)
          into vn_cpt
          FROM
            ( 
            Select fcr.request_id CHILD_REQUEST_ID,
                PARENT_REQUEST_ID PARENT_REQUEST_ID,
                fcp.concurrent_program_name program_name,
                fcptl.user_concurrent_program_name user_concurrent_program_name,
                fcr.phase_code phase,
                fcr.status_code status
           from apps.fnd_concurrent_requests    fcr,
                apps.fnd_concurrent_programs    fcp,
                apps.fnd_concurrent_programs_tl fcptl
          WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
            AND fcr.program_application_id = fcp.application_id
            AND fcp.application_id = fcptl.application_id
            AND fcp.concurrent_program_id = fcptl.concurrent_program_id
            AND fcptl.language = 'F'
            AND fcp.CONCURRENT_PROGRAM_NAME in ('GLPPOS', 'GLPPOSS')
            AND fcr.parent_request_id = vn_request_id
            );
    
        if vn_cpt = 0 THEN
            g_step := 'Le traitement GLPPOS n''a pas été bien lancé . ';
            log_msg(g_step);
            vv_warn_retcode := 1;
    end if;
    
    
    IF vn_request_id > 0
    THEN
      --  LOOP
      FOR trt IN cur_GLPPOS_trt(vn_request_id) LOOP
      
            vn_new_request_id :=  fnd_concurrent.wait_for_request (trt.child_request_ID, cn_tempo, 0, vv_rrphase,
                vv_rrstatus, vv_ddphase, vv_ddstatus, vvv_message);
         
         
        COMMIT;
        
        g_step := 'Le traitement ' || trt.user_concurrent_program_name || ' N°' || trt.child_request_ID ||' a été bien lancé . ';
        log_msg(g_step);
        
    
        
        IF UPPER (vv_rrphase) IN ('COMPLETED','TERMINÉ') AND UPPER (vv_rrstatus) IN ('ERROR','ERREUR') THEN
            vv_err_retcode := 1;
            g_step := 'Le traitement ' || trt.user_concurrent_program_name || ' N°' || trt.child_request_ID ||' est terminé en erreur . ';
            log_msg(g_step);
            --Pn_Retcode := 2;
        ELSIF UPPER (vv_rrphase) IN ('COMPLETED','TERMINÉ') AND UPPER (vv_rrstatus) = 'NORMAL' THEN
            Pn_Retcode := 0;
            g_step := 'Le traitement ' || trt.user_concurrent_program_name || ' N°' || trt.child_request_ID ||' est terminé normalement . ';
            log_msg(g_step);
        ELSIF UPPER (vv_rrphase) IN ('COMPLETED','TERMINÉ') AND UPPER (vv_rrstatus) IN ('WARNING','AVERTISSEMENT') THEN
            vv_warn_retcode := 1;
            g_step := 'Le traitement ' || trt.user_concurrent_program_name || ' N°' || trt.child_request_ID ||' est terminé en avertissement . ';
            log_msg(g_step);
            --Pn_Retcode := 1;
        END IF;
      END LOOP;
    END IF;
    
    IF  vv_err_retcode = 1 THEN
        Pn_Retcode := 2;
    ELSIF vv_warn_retcode = 1 AND vv_err_retcode = 0 THEN
        Pn_Retcode := 1;
	ELSIF vv_err_retcode = 0 AND vv_warn_retcode = 0 THEN
        Pn_Retcode := 0;
    g_step := CHR (10) || '>>> Fin normale';
    log_msg(g_step);
    END IF;
    
    
EXCEPTION
    WHEN OTHERS
    THEN
        
        g_step := cv_request_name || ' ==> ERREUR : ' || SQLERRM;
        log_msg(g_step);
        Pn_Retcode := 2;


END main;

END DKA_SGLIMPUTATION_PKG;
/

SHOW ERRORS;
EXIT