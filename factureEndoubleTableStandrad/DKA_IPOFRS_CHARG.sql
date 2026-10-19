/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_ENTRTSTAT_JOB.sql
-- DESCRIPTION      : Lancement automatique des traitements de Collecte des statistiques de la table et schéma
---
--- AUTEUR           : S.HAHIOUI (SHA)
--- DATE DE CREATION : 25/05/2022
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
    cv_prog_name            CONSTANT VARCHAR2 (30)  := 'FNDGSCST';
    cn_tempo                CONSTANT NUMBER         := 20;
    vv_user                          VARCHAR2 (80)  := '&&1';
    vv_resp                          VARCHAR2 (80)  := '&&2';
	vv_schema                        VARCHAR2 (30)  := '&&3';
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

       DBMS_OUTPUT.put_line ('Soumission du traitement');
    vn_request_id    := fnd_request.submit_request (
                            vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                            cv_prog_name, --SHORT_NAME du TRAITEMENT
                            NULL, --PROGRAM_NAME
                            NULL, --START
                            FALSE, --SUB_REQUEST
                            vv_schema, --ARGUMENT1
                            NULL, --ARGUMENT2
                            NULL, --ARGUMENT3
                            'NOBACKUP', --ARGUMENT4
                            NULL, --ARGUMENT5
                            'LASTRUN', --ARGUMENT6
                            'GATHER', --ARGUMENT7
                            NULL, --ARGUMENT8
                            'Y' --ARGUMENT9
                        );
    DBMS_OUTPUT.put_line ('Validation pour que les GTS puissent prendre la demande');
    COMMIT;

    IF vn_request_id = 0
    THEN
        DBMS_OUTPUT.put_line ('Impossible de lancer le Traitement ');
        :ret_code    := 'FAILURE';
        RETURN;
    END IF;
	
    DBMS_OUTPUT.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));

    IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
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
