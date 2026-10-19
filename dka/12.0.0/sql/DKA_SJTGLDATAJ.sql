/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SJTGLDATAJ.sql
-- DESCRIPTION      : Lancement automatique du traitement SJTGLDATAJ
---
--- AUTEUR           : X. Descamps (CGEY)
--- DATE DE CREATION : 17/05/2002
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_request_set_name     CONSTANT VARCHAR2 (30)  := 'DKA_SJTGLDATAJ';
    cn_tempo                CONSTANT NUMBER         := 20;
    vv_user                          VARCHAR2 (80)  := '&&1';
    Vr_Data                          Dka_Parameters%ROWTYPE;
    vv_resp                          VARCHAR2 (80)  ;
    vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
    vn_req_application_id            NUMBER (15);
    vv_req_application_short_name    VARCHAR2 (50);
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

    DBMS_OUTPUT.put_line ('Recuperation de la responsabilité');
    
    Dka_Tools_Pkg.get_parameter('DKA_SJTGLDATAJ',
                                 'GL_RESPONSIBILITY_KEY',
                                 Vr_Data,
                                 vn_retcode,
                                 vv_errbuf);
                                   
    IF vn_retcode != 0 THEN
      
      DBMS_OUTPUT.put_line ('Erreur lors de la récupération de la responsabilité ');
      DBMS_OUTPUT.put_line (vv_errbuf);
      :ret_code    := 'FAILURE';
      RETURN;
    
    END IF;                              
                                   
    vv_resp  := Vr_Data.Varchar2_Value;
    
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

    DBMS_OUTPUT.put_line ('Recuperation des infos sur le jeu de traitements');
    SELECT frs.application_id,
           fa.application_short_name
    INTO   vn_req_application_id,
           vv_req_application_short_name
    FROM   fnd_request_sets frs,
           fnd_application fa
    WHERE      frs.request_set_name = cv_request_set_name
           AND fa.application_id = frs.application_id;

    DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
    fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);

    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';

    DBMS_OUTPUT.put_line ('Soumission du jeu de traitements');
    dka_tools_pkg.launch_request_set (
        vv_errbuf,
        vn_retcode,
        vv_req_application_short_name,
        cv_request_set_name,
        vv_user,
        vv_resp,
        vn_request_id);

    DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
    COMMIT;

    IF vn_request_id = 0
    THEN
        DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
        DBMS_OUTPUT.put_line (vv_errbuf);
        :ret_code    := 'FAILURE';
        RETURN;
    END IF;

    DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));

    IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
       :ret_code := 'FAILURE';
       RETURN;
    ELSE
       IF vv_dstatus = 'WARNING' THEN
          dbms_output.put_line (CHR (10) || '>>> Traitement termine en Warning ');
          :ret_code := 'WARNING';
          RETURN;
       ELSIF vv_dstatus != 'NORMAL' THEN
          dbms_output.put_line (CHR (10) || '>>> Traitement termine en Erreur ');
          :ret_code := 'FAILURE';
          RETURN;
       END IF;
    END IF;

    DBMS_OUTPUT.put_line (CHR (10) || '>>> Fin normale');
    :ret_code        := 'SUCCESS';
EXCEPTION
    WHEN OTHERS
    THEN
        DBMS_OUTPUT.put_line (cv_request_set_name || ' ==> ERREUR : ' || SQLERRM);
        :ret_code    := 'FAILURE';
END;
/
/*<TOAD_FILE_CHUNK>*/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
