/*<TOAD_FILE_CHUNK>*/
/* Formatted on 05/16/2002 16:08 (Formatter Plus v4.5.2) */
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOXRAF.sql
-- DESCRIPTION      : Lancement automatique du traitement POXRAF
---
--- AUTEUR           : CGEY
--- DATE DE CREATION : 16/10/2003
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 03/08/2004 SFE Migration pour projet PHENIX 2004
--- 27/07/2005 EMA Report de maintenance PHENIX 2004
---                Le traitement spécifique DKA_POXRAF est remplacé par le traitement Standard POXRAF
---                Il est lancé une seule fois au lieu d'etre lancé pour chaque société
---------------------------------------------------------------------------------------------------------------
--- Migration R12
--- Date       Qui Description
--- 29/04/2016 RAZ Migration DALKIA R12
--- 26/05/2017 RBE Modification artf2147922  
--- 17/04/2020 ARA Modification tracker50786 - INC0419921
--- 05/12/2020 SEL Pas de lancement du traitement si la resp n existe pas
---------------------------------------------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 100000

VAR ret_code VARCHAR2(10);

DECLARE
    cv_prog_name                    CONSTANT VARCHAR2 (30)  := 'POXRAF';
    cn_tempo                        CONSTANT NUMBER         := 20;
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
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
    vv_responsibility_ref            fnd_responsibility.responsibility_key%TYPE;
    vv_responsibility                fnd_responsibility.responsibility_key%TYPE;
    rec_param                        dka_parameters%ROWTYPE;
    pn_retcode                       NUMBER;
    vv_parameter                     dka_parameters.parameter_name%TYPE;
    vn_org_id                        NUMBER;
    
    cv_line                     VARCHAR2 (100);
    
    --RBE
    TYPE num_traitement IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    num_trait_list num_traitement;

    v_cpt INTEGER := 0;
    
    v_trt_a_lancer      INTEGER := 0;
    v_trt_normal        INTEGER := 0;
    v_trt_avertissement INTEGER := 0;
    v_trt_erreur        INTEGER := 0;
    
    v_phase             VARCHAR2 (100);
    v_status            VARCHAR2 (100);
    v_dev_phase         VARCHAR2 (100);
    v_dev_status        VARCHAR2 (100);
	v_is_resp           INTEGER := 0;   -- SEL
    
BEGIN

    /*artf2127132 dka_tools_pkg.put_out_header;*/
    cv_line    := '+-------------------------------------------------------------------------+';
    dbms_output.put_line (cv_line);
    dbms_output.put_line ('');
    dbms_output.put_line ('Code du traitement : ' || cv_prog_name);
    dbms_output.put_line ('Utilisateur        : ' || vv_user);
    dbms_output.put_line ('Responsabilité     : ' || vv_resp);
    dbms_output.put_line (cv_line);
    dbms_output.put_line ('');
    dbms_output.put_line ('Date et heure systeme : ' || TO_CHAR (SYSDATE));
    dbms_output.put_line ('');
    dbms_output.put_line (cv_line);
    dbms_output.put_line ('');
    
    dbms_output.put_line ('Recuperation des identifiants user lie au batch');
    
    BEGIN
    SELECT user_id
    INTO   vn_user_id
    FROM   fnd_user
    WHERE  user_name = vv_user;    
    EXCEPTION
      when others then
        dbms_output.put_line ('impossible de recuperer user id'||vn_user_id); 
    END;
    
    /* Début Migration R12 RAZ*/
    FOR REC IN (SELECT organization_id,SHORT_CODE 
                FROM hr_operating_units
                WHERE 1=1
                AND SYSDATE BETWEEN DATE_FROM AND NVL(DATE_TO,SYSDATE+1)
                AND USABLE_FLAG IS NULL
                AND SHORT_CODE IS NOT NULL
				-- ARA tracker50786 - INC0419921
				AND organization_id IN (
					SELECT organization_id 
					FROM PER_SECURITY_ORGANIZATIONS
					WHERE SECURITY_PROFILE_ID = (
						SELECT SECURITY_PROFILE_ID
						FROM PER_SECURITY_PROFILES
						WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT'
					
					)
				
				)
				) LOOP 

    --RBE
    v_trt_a_lancer := v_trt_a_lancer + 1;
    
    vv_responsibility_ref := REC.SHORT_CODE||'_PO_ADMINISTRATEUR';
    dbms_output.put_line ('==> '||vv_responsibility_ref);
    
     /* Fin Migration R12 RAZ*/
    dbms_output.put_line ('Recuperation des infos sur le traitement');
    SELECT fcp.application_id,
           fa.application_short_name,
           fcp.concurrent_program_id
    INTO   vn_prog_application_id,
           vv_prog_application_short_name,
           vn_program_id
    FROM   fnd_concurrent_programs fcp,
           fnd_application         fa
    WHERE  fcp.concurrent_program_name = cv_prog_name
    AND    fa.application_id           = fcp.application_id;
    
    vn_responsibility_id := NULL;
    vn_application_id    := NULL;
	v_is_resp            := 0; -- SEL

    begin
      SELECT fr.responsibility_id,
             fr.application_id,
             fr.responsibility_key
      INTO   vn_responsibility_id,
             vn_application_id,
             vv_responsibility      
      FROM   fnd_responsibility fr
      WHERE  fr.responsibility_key = vv_responsibility_ref;
    
    exception
        when others then
        dbms_output.put_line ('impossible de recuperer la resp'||vv_responsibility_ref); -- ou introuvable
		v_is_resp            := 1; -- SEL
    end;
	
	if v_is_resp = 0 then
		dbms_output.put_line ('Initialisation dans le contexte OA');
		fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
		
		
		
		
		EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || fnd_profile.value ('ICX_LANGUAGE') || '''';
	   
		dbms_output.put_line ('Soumission du traitement');
		
		-- Le traitement est appelé sans aucun parametre
		vn_request_id := fnd_request.submit_request ( vv_prog_application_short_name, -- APPLICATION PROPRIETAIRE DU TRAITEMENT
													  cv_prog_name,                   -- SHORT NAME DU TRAITEMENT
													  NULL,                           -- PROGRAM NAME
													  NULL,                           -- START
													  FALSE );                        -- SUB REQUEST
													  -- FALSE,                          -- SUB REQUEST
													  -- rec_soc.name );                 -- PARAMETRE1
		
		dbms_output.put_line ('Validation pour que les GTS puissent prendre la demande');
		COMMIT;

		IF vn_request_id = 0 THEN
		   dbms_output.put_line ('Impossible de lancer le Traitement');
		   dbms_output.put_line (vv_errbuf);
		   :ret_code    := 'FAILURE';
		   RETURN;
		ELSE
			v_cpt := v_cpt + 1;
			num_trait_list(v_cpt) := vn_request_id;
		END IF;

		dbms_output.put_line ('Traitement numero : ' || TO_CHAR (vn_request_id));
		
	end if;

    --dbms_output.put_line (CHR (10) || '>>> Fin normale');
    :ret_code := 'SUCCESS';

  END LOOP;
    
    --RBE
    -- Attente de la fin des traitements
    FOR var IN 1 .. v_cpt LOOP

      IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
                                              cn_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              vv_message)) THEN
                                              
        dbms_output.put_line (cv_prog_name || ' ==> ERREUR : Attente de la fin du programme numero '||num_trait_list(var)||' : Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || vv_message || CHR(10));
      END IF;

      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
            v_trt_normal := v_trt_normal + 1;
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
            v_trt_avertissement := v_trt_avertissement + 1;
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
            v_trt_erreur := v_trt_erreur + 1;
      END IF;
    END LOOP;

    COMMIT;
    
    dbms_output.put_line ('-------------------------------------------------------');
    dbms_output.put_line ('==> Nombre de traitements à lancer             :  ' || TO_CHAR(v_trt_a_lancer));
    dbms_output.put_line ('==> Nombre de traitements lancés               :  ' || TO_CHAR(v_cpt));
    dbms_output.put_line ('==> Nombre de traitements terminés normalement :  ' || TO_CHAR(v_trt_normal));
    dbms_output.put_line ('==> Nombre de traitements terminés en warning  :  ' || TO_CHAR(v_trt_avertissement));
    dbms_output.put_line ('==> Nombre de traitements terminés en erreur   :  ' || TO_CHAR(v_trt_erreur));
    dbms_output.put_line ('-------------------------------------------------------');
    
    --Fin RBE
  
  
EXCEPTION
    WHEN OTHERS THEN
         dbms_output.put_line (cv_prog_name || ' ==> ERREUR : ' || SQLERRM);
         :ret_code    := 'FAILURE';
END;
/
/*<TOAD_FILE_CHUNK>*/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
