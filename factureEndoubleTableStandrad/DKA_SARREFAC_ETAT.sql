/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SARSURTAXE.sql
-- DESCRIPTION      : Lancement automatique du traitement SARSURTAXE
---
--- AUTEUR           : CGEY
--- DATE DE CREATION : 07/01/2003
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 30/08/2004 SFE Migration PHENIX 2004: modification de la gestion de apps_initialize
---                gcc.segment4 -> gcc.segmet5
--- 11/08/2017 OBE artf2211298 : SPE021 - Surtaxe communale - Il y a des valeurs codés en dur au niveau des comptes
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_request_set_name     CONSTANT VARCHAR2 (30)  := 'DKA_SARSURTAXE_SET';
    cn_tempo                CONSTANT NUMBER         := 20;
    vv_user                          VARCHAR2 (80)  := '&&1';
    vv_resp                          VARCHAR2 (80)  := '&&2';
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
    vv_responsibility_ref      	 fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility		     	 fnd_responsibility.responsibility_key%TYPE;
    rec_param              		 dka_parameters%ROWTYPE;
    pn_retcode				 NUMBER;
    vv_bool                          BOOLEAN;


	CURSOR cur_soc
	IS
		SELECT hou.organization_id,
                   hou.NAME
            FROM   hr_all_organization_units hou
            WHERE  hou.organization_id in (SELECT distinct rctlgd.org_id
                                           FROM ra_cust_trx_line_gl_dist_all rctlgd,
                                                gl_code_combinations gcc--,
                                                --fnd_flex_value_sets ffvs, -- OBE artf2211298
                                                --fnd_flex_values     ffv   -- OBE artf2211298
                                           WHERE gcc.code_combination_id = rctlgd.code_combination_id
                                           AND (rctlgd.attribute6 IS NULL)-- OR rctlgd.attribute1 IS NULL)               -- OBE
                                           --AND gcc.segment5 LIKE 'CSC%'  -- PHENIX 2004: gcc.segment4 -> gcc.segment5  -- OBE
                                           AND rctlgd.attribute8 LIKE 'CSC%'                                             -- OBE
                                           --< OBE artf2211298
                                           /*
                                           AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
                                           AND ffvs.flex_value_set_id   = ffv.flex_value_set_id
                                           AND ffv.enabled_flag         = 'Y'
                                           AND ffv.attribute10          = 'Y'
                                           */
                                           --> OBE artf2211298
                                           --AND gcc.segment3 IN (ffv.flex_value) --('467300', '467296') -- OBE artf2211298
                                           AND DKA_AR_TOOLS_PKG.issurtaxeaccount(gcc.segment3) = 'TRUE'  -- OBE artf2211298
                                           )
               AND ROWNUM = 1 -- OBE
               ;
               /*
		UNION
		SELECT hou.organization_id,
			 hou.NAME
		FROM   hr_all_organization_units hou
		WHERE hou.name in (SELECT distinct SUBSTR (gcc.segment1, 4) 
					 FROM gl_je_lines gjl
						, gl_code_combinations gcc
					 WHERE gjl.attribute19 IS NULL
					 AND gcc.code_combination_id = gjl.code_combination_id
					 AND gjl.status = 'P'
					 AND gcc.segment3 IN ('467300', '467296')
           --AND gcc.segment5 LIKE 'CSC%'  -- OBE
           );  -- PHENIX 2004: gcc.segment4 -> gcc.segment5
           */

BEGIN
    
--    SELECT fr.responsibility_id,
--           fr.application_id
--    INTO   vn_responsibility_id,
--           vn_application_id
--    FROM   fnd_responsibility fr
--    WHERE  responsibility_key = vv_resp;

  FOR rec_soc IN cur_soc
  LOOP

    dka_tools_pkg.put_out_header;
    --récupération des parametres utilisés par le traitement
    --dka_tools_pkg.get_parameter ('SARSURTAXE', 'RESPONSIBILITY_KEY', rec_param, pn_retcode, vv_errbuf); -- OBE

    IF pn_retcode != 0
    THEN
	:ret_code    := 'FAILURE';
	RETURN;
    END IF;

    vv_responsibility_ref    := 'TOUT_AP_ADMINISTRATEUR'; --rec_param.varchar2_value;

    DBMS_OUTPUT.put_line ('Recuperation des identifiants user');
    SELECT user_id
    INTO   vn_user_id
    FROM   fnd_user
    WHERE  user_name = vv_user;

    DBMS_OUTPUT.put_line ('Recuperation des infos sur le jeu');
    SELECT frs.application_id,
           fa.application_short_name
    INTO   vn_req_application_id,
           vv_req_application_short_name
    FROM   fnd_request_sets frs,
           fnd_application fa
    WHERE      frs.request_set_name = cv_request_set_name
           AND fa.application_id = frs.application_id;

    -- PHENIX 2004: Sortie de la boucle de ce code
            --récupération des variables nécessaires au lancement du traitement
    SELECT fr.responsibility_id,
           fr.application_id,
           fr.responsibility_key
    INTO   vn_responsibility_id,
           vn_application_id,
           vv_responsibility      
    FROM   fnd_responsibility fr
    WHERE  fr.responsibility_key = vv_responsibility_ref; -- PHENIX 2004: REPLACE (vv_responsibility_ref, 'XXXX', rec_soc.NAME) -> vv_responsibility_ref


      DBMS_OUTPUT.put_line ('Initialisation dans le contexte OA');
      fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
      MO_GLOBAL.INIT('SQLAP');
    -- PHENIX 2004: Fin de la sortie de la boucle de ce code
    
        --FOR rec_soc IN cur_soc
        --LOOP

    EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
    
    vv_bool := FND_REQUEST.SET_OPTIONS(language => 'FRENCH', territory => 'FRANCE');

    
    DBMS_OUTPUT.put_line ('Soumission du jeu de traitements');
    dka_tools_pkg.launch_request_set (
        vv_errbuf,
        vn_retcode,
        vv_req_application_short_name,
        cv_request_set_name,
        vv_user,
        vv_responsibility,
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
    --DBMS_OUTPUT.put_line ('vv_errbuf : ' || TO_CHAR (vv_errbuf));
    --DBMS_OUTPUT.put_line ('SQLERR : ' || TO_CHAR (SQLERRM));

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

	END LOOP; -- fin boucle des responsabilités

EXCEPTION
    WHEN OTHERS
    THEN
        DBMS_OUTPUT.put_line (cv_request_set_name || ' ==> ERREUR : ' || SQLERRM);
        :ret_code    := 'FAILURE';
END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
