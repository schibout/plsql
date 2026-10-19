/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SGLSTPM.sql
-- DESCRIPTION      : Lancement automatique du traitement GLSTPM
---
--- AUTEUR           : Capgemini
--- DATE DE CREATION : 06/07/2004
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 12/07/2004 EMA Suppression du return dans l'attente de la fin des traitements.
--- 09/08/2005 CDE Migration Phenix 2005
--- 20/10/2016 JPE Migration R12
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_prog_name            CONSTANT VARCHAR2 (30)  := 'GLSTPM';
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
    vn_chart_of_accounts_id          NUMBER (15);
    vn_template_id                   NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vv_responsibility_ref      	     fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility		     	       fnd_responsibility.responsibility_key%TYPE;
    rec_param              		       dka_parameters%ROWTYPE;
    pn_retcode				               NUMBER;


    CURSOR Cur_Cle IS

        SELECT * 
        FROM   DKA_GL_SUMMARY_TEMPLATES_SAVE;

    Rec_Cle                          Cur_Cle%ROWTYPE;

BEGIN
    
    dka_tools_pkg.put_out_header;
    --récupération des parametres utilisés par le traitement
    dka_tools_pkg.get_parameter ('GLSTPM', 'GL_RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf);
    
    IF pn_retcode != 0 THEN
  	 :ret_code := 'FAILURE';
  	 RETURN;
    END IF;

    vv_responsibility_ref := rec_param.varchar2_value;
    dbms_output.put_line ('==> '||vv_responsibility_ref);

    dbms_output.put_line ('Recuperation des identifiants user');
    SELECT user_id
    INTO   vn_user_id
    FROM   fnd_user
    WHERE  user_name = vv_user;

    dbms_output.put_line ('Recuperation des infos sur le traitement');
    SELECT fcp.application_id,
           fa.application_short_name,
           fcp.concurrent_program_id
    INTO   vn_prog_application_id,
           vv_prog_application_short_name,
           vn_program_id
    FROM   fnd_concurrent_programs fcp,
           fnd_application fa
    WHERE  fcp.concurrent_program_name = cv_prog_name
    AND    fa.application_id = fcp.application_id;
    
    
  
    OPEN cur_Cle;

    LOOP
        FETCH cur_Cle INTO rec_Cle;
        EXIT WHEN cur_Cle%NOTFOUND;
        
        dbms_output.put_line ('Récupération du nouveau template_id');
        SELECT  GL_SUMMARY_TEMPLATES_S.nextval
        INTO    vn_template_id
        FROM    DKA_GL_SUMMARY_TEMPLATES_SAVE
        WHERE   template_id = rec_Cle.template_id;
        
	      dbms_output.put_line ('Mise à jour du template_id et du status');
        UPDATE DKA_GL_SUMMARY_TEMPLATES_SAVE
        SET    template_id = vn_template_id,
               status = 'A'
        WHERE  template_id = rec_Cle.template_id;
        
        dbms_output.put_line ('Insertion de la Cle de synthèse : '|| rec_Cle.template_name);
        INSERT INTO GL_SUMMARY_TEMPLATES gst
        SELECT * FROM DKA_GL_SUMMARY_TEMPLATES_SAVE  
         WHERE  template_id = vn_template_id;      
 
        --récupération des variables nécessaires au lancement du traitement
       dbms_output.put_line ('Recuperation des variables necessaires au lancement du traitement');
       SELECT fr.responsibility_id,
               fr.application_id,
               fr.responsibility_key
        INTO   vn_responsibility_id,
               vn_application_id,
               vv_responsibility      
        FROM   fnd_responsibility fr
        WHERE  fr.responsibility_key = vv_responsibility_ref; -- PHENIX 2005

        dbms_output.put_line ('Initialisation dans le contexte OA');
        fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
        
        dbms_output.put_line ('Recherche du chart_of_accounts_id');
        SELECT  chart_of_accounts_id
        INTO    vn_chart_of_accounts_id 
        FROM    gl_sets_of_books
        WHERE   set_of_books_id = rec_Cle.ledger_id;
        
        dbms_output.put_line ('Soumission du traitement');
        vn_request_id := fnd_request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                      cv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                      NULL,                           -- PROGRAM NAME
                                                      NULL,                           -- START
                                                      FALSE,                          -- SUB REQUEST
                                                      'A',
                                                      vn_template_id,
                                                      rec_Cle.ledger_id,
                                                      vn_chart_of_accounts_id);                 
        dbms_output.put_line ('Validation pour que les GTS puissent prendre la demande');
        COMMIT;

        IF vn_request_id = 0 THEN
           dbms_output.put_line ('Impossible de lancer le Traitement ');
           dbms_output.put_line (vv_errbuf);
           :ret_code    := 'FAILURE';
           RETURN;
        END IF;

        dbms_output.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
        IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
        THEN
            :ret_code    := 'FAILURE';
            -- Modif EM 12/07/2004
            -- Suppression du Return 
            -- RETURN;
        ELSE
            IF vv_dstatus = 'WARNING'
            THEN
                dbms_output.put_line (CHR (10) || '>>> Traitement termine en Warning ');
                :ret_code    := 'WARNING';
                -- Modif EM 12/07/2004
                -- Suppression du Return 
                -- RETURN;
            ELSIF vv_dstatus != 'NORMAL'
            THEN
                dbms_output.put_line (CHR (10) || '>>> Traitement termine en Erreur ');
                :ret_code    := 'FAILURE';
                -- Modif EM 12/07/2004
                -- Suppression du Return 
                -- RETURN;
            END IF;
        END IF;
        
    
      	dbms_output.put_line ('Suppression de la Cle dans la table de travail');
        DELETE DKA_GL_SUMMARY_TEMPLATES_SAVE
        WHERE  template_id =  vn_template_id;
        
        dbms_output.put_line (CHR (10) || '>>> Fin normale');
        
    	  :ret_code := 'SUCCESS';
        
    END LOOP; -- fin boucle des Cles

    CLOSE cur_Cle;

EXCEPTION
    WHEN OTHERS THEN
         dbms_output.put_line (cv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code    := 'FAILURE';
END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
