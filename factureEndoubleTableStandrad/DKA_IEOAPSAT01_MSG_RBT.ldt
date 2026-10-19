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
--- COMMENTAIRE      : A ex‚cuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 13/07/2004 EMA Ajout de l'attente de la fin de tous les traitements
--- 09/08/2005 CDE Migration Phenix 2005
--- 20/10/2016 JPE Migration R12
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_prog_name            CONSTANT VARCHAR2 (30)  := 'GLSTPM';
    cn_tempo                CONSTANT NUMBER         := 20;
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vv_user                          VARCHAR2 (80)  := '&&1';
    vv_resp                          VARCHAR2 (80)  := '&&2';
    vn_retcode                       NUMBER         := 0;
    vn_traitement                    NUMBER         := 0;
    vn_indice                        NUMBER;
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

    TYPE myrecord IS RECORD (
         request_id    NUMBER,
         status        VARCHAR2(25));

    TYPE mytable IS TABLE OF myrecord
         INDEX BY BINARY_INTEGER;

    vt_traitement                    mytable;

    CURSOR Cur_Cle IS
        SELECT * 
        FROM   GL_SUMMARY_TEMPLATES
        WHERE  ATTRIBUTE1 = 'Y';

    Rec_Cle                          Cur_Cle%ROWTYPE;

BEGIN
    
    dka_tools_pkg.put_out_header;
    --recuperation des parametres utilises par le traitement
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

    DBMS_OUTPUT.put_line ('Recuperation des infos sur le traitement');
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
    
    
     DBMS_OUTPUT.put_line ('Sauvegarde des cles de synthŠse … mettre … jour');
    INSERT INTO DKA_GL_SUMMARY_TEMPLATES_SAVE 
    SELECT * FROM GL_SUMMARY_TEMPLATES
    WHERE  ATTRIBUTE1 = 'Y';
   
    
    OPEN cur_cle;

    LOOP
      FETCH cur_cle INTO rec_cle;
      EXIT WHEN cur_cle%NOTFOUND;

      
      dbms_output.put_line ('Recuperation des variables necessaires au lancement du traitement');
      
      --recuperation des variables necessaires au lancement du traitement
      SELECT fr.responsibility_id,
             fr.application_id,
             fr.responsibility_key
      INTO   vn_responsibility_id,
             vn_application_id,
             vv_responsibility      
      FROM   fnd_responsibility fr
      -- WHERE  fr.responsibility_key = REPLACE (vv_responsibility_ref, 'XXXX'/*, rec_cle.name*/);
      WHERE  fr.responsibility_key = vv_responsibility_ref; -- PHENIX 2005

      dbms_output.put_line ('Initialisation dans le contexte OA');
      fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

      EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
      
       
              
      dbms_output.put_line ('Recherche du chart_of_accounts_id');
      SELECT  chart_of_accounts_id
      INTO    vn_chart_of_accounts_id 
      FROM    gl_sets_of_books
      WHERE   set_of_books_id = rec_cle.ledger_id;
      
      dbms_output.put_line ('Soumission du traitement');
      vn_request_id := fnd_request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                    cv_prog_name,                   -- SHORT NAME DU TRAITEMENT
                                                    NULL,                           -- PROGRAM NAME
                                                    NULL,                           -- START
                                                    FALSE,                          -- SUB REQUEST
                                                    'D',
                                                    rec_cle.template_id,
                                                    rec_cle.ledger_id,
                                                    vn_chart_of_accounts_id);                 
      dbms_output.put_line ('Validation pour que les GTS puissent prendre la demande');
      vn_traitement := vn_traitement + 1;
      vt_traitement(vn_traitement).request_id := vn_request_id;
      vt_traitement(vn_traitement).status     := NULL;
      COMMIT;

      IF vn_request_id = 0 THEN
         dbms_output.put_line ('Impossible de lancer le Traitement ');
         dbms_output.put_line (vv_errbuf);
         :ret_code    := 'FAILURE';
         RETURN;
      END IF;

      dbms_output.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));

  	  :ret_code := 'SUCCESS';

    END LOOP; -- fin boucle des cles

    CLOSE cur_cle;

    -- Attente de la fin des traitements
    ------------------------------------
    FOR vn_indice IN 1..vn_traitement 
    LOOP
      IF NOT fnd_concurrent.wait_for_request (vt_traitement(vn_indice).request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
         DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning');
      ELSE
         IF vv_dstatus = 'NORMAL' THEN
            DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
         ELSIF vv_dstatus = 'WARNING' THEN
            DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Warning ');
         ELSIF vv_dstatus != 'NORMAL' THEN
            DBMS_OUTPUT.PUT_LINE (CHR (10) || '>>> Traitement '||vt_traitement(vn_indice).request_id||' termine en Erreur ');
         END IF;
      END IF; 
    END LOOP;

    :ret_code := 'SUCCESS';

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
