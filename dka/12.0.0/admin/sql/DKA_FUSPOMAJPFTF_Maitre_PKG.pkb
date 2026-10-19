CREATE OR REPLACE PACKAGE BODY DKA_FUSPOMAJPFTF_Maitre_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_FUSPOMAJPFTF_Maitre_PKG
  -- Description      : Body du package DKA_FUSPOMAJPFTF_Maitre_PKG
  -- Auteur           : Samir EL OUAHABI
  -- Date de création : 01/09/2019
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  

 
  PROCEDURE main(p_errbuf       IN OUT  VARCHAR2,
                 p_retcode      OUT     NUMBER
                 )
  IS

   CURSOR CUR_UO
   IS
    select distinct prh.org_id
	  from po_requisition_headers_all prh,
		   po_requisition_lines_all prl,
		   po_req_distributions_all prd,
		   pa_projects_all ppa,
           pa_tasks pt		   
	 where prh.requisition_header_id=prl.requisition_header_id
	   and prl.requisition_line_id=prd.requisition_line_id
	   and ppa.project_id=prd.project_id
	   and pt.task_id=prd.task_id
	   and prl.line_location_id is null
	   and prh.org_id not in ( SELECT HOU.organization_id
							     FROM HR_ORGANIZATION_UNITS HOU,
								      DKA_STRANSCO_LINES DSTL,
								      DKA_STRANSCO_HEADERS DSTH
							    WHERE DSTL.SET_ID = DSTH.SET_ID
								  AND HOU.NAME = DSTL.PARAM1_VALUE
								  AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
								  AND DSTL.ENABLE = 'Y'
								  AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
							   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
								 )
       and ppa.org_id in ( SELECT HOU.organization_id
					         FROM HR_ORGANIZATION_UNITS HOU,
								  DKA_STRANSCO_LINES DSTL,
								  DKA_STRANSCO_HEADERS DSTH
					        WHERE DSTL.SET_ID = DSTH.SET_ID
						      AND HOU.NAME = DSTL.PARAM1_VALUE
						      AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
						      AND DSTL.ENABLE = 'Y'
						      AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
							  )  
     union
	select poha.org_id
		 FROM PO_HEADERS_ALL poha,
			  PO_LINES_ALL pola,
			  PO_DISTRIBUTIONS_ALL poda,
			  PA_PROJECTS_ALL papa,
			  PA_TASKS PT	--SELO
		 --  ,hr_all_organization_units hraou
		WHERE poda.po_header_id = poha.po_header_id
		  AND poda.po_line_id = pola.po_line_id
		  AND poha.type_lookup_code        = 'STANDARD'
		  AND NVL(poha.closed_code,'OPEN') = 'OPEN'
		  AND NVL(poha.cancel_flag,'N')    = 'N'
		  AND poda.PROJECT_ID = papa.project_id (+)
		  AND PT.TASK_ID = poda.TASK_ID
		  AND poha.org_id not in ( SELECT HOU.organization_id
									 FROM HR_ORGANIZATION_UNITS HOU,
										  DKA_STRANSCO_LINES DSTL,
										  DKA_STRANSCO_HEADERS DSTH
									WHERE DSTL.SET_ID = DSTH.SET_ID
									  AND HOU.NAME = DSTL.PARAM1_VALUE
									  AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
									  AND DSTL.ENABLE = 'Y'
									  AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
								   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
								   )
		  AND papa.org_id in ( SELECT HOU.organization_id
								 FROM HR_ORGANIZATION_UNITS HOU,
									  DKA_STRANSCO_LINES DSTL,
									  DKA_STRANSCO_HEADERS DSTH
								WHERE DSTL.SET_ID = DSTH.SET_ID
								  AND HOU.NAME = DSTL.PARAM1_VALUE
								  AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
								  AND DSTL.ENABLE = 'Y'
								  AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
							   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
							  ) ;	 
				
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);
        b_result                 BOOLEAN;
        
        v_user_id                NUMBER;                       
        v_resp_id                NUMBER;
        v_resp_appl_id           NUMBER;

        TYPE num_traitement IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
        num_trait_list 			num_traitement;
		g_int_request_id        fnd_concurrent_requests.request_id%TYPE;
      
        v_cpt 					INTEGER := 0;
		g_tempo                 NUMBER;

 
 BEGIN
  
        v_user_id      := FND_PROFILE.VALUE('USER_ID');
        --v_resp_id      := FND_PROFILE.VALUE('RESP_ID');     -- V1.4
        --v_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');-- V1.4  
        g_tempo                        := 20;
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début');    
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                         'LANCEMENT DU PROGRAMME DE MISE A JOURS PAR SOCIETE : ');
        
        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'LANCEMENT DU PROGRAMME DE MISE A JOURS PAR SOCIETE : ');
        fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
        FOR rec IN cur_uo LOOP

            --fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
            --fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
            fnd_file.put_line(fnd_file.LOG, 'Lancement du programme pour l''org_id : '||rec.org_id);
            fnd_file.put_line(fnd_file.OUTPUT, 'Lancement du programme  pour l''org_id : '||rec.org_id);
            --fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
            
            
            BEGIN 
              SELECT responsibility_id, application_id
                INTO v_resp_id, v_resp_appl_id
                FROM fnd_responsibility fr, hr_operating_units hou
               WHERE hou.organization_id = rec.org_id
                 AND fr.responsibility_key = hou.name || '_PO_ADMINISTRATEUR';
                
              
              APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                              RESP_ID      => v_resp_id,
                                              RESP_APPL_ID => v_resp_appl_id
                                              );
                                              
              mo_global.set_policy_context('S',rec.org_id);
              
              Fnd_Request.set_org_id(org_id => rec.org_id); 

            EXCEPTION
            WHEN OTHERS THEN
                p_retcode   := 2;
                v_resp_id   := NULL; -- RBE artf2061712
                v_resp_appl_id := NULL; -- RBE artf2061712 
                --fnd_file.put_line(fnd_file.OUTPUT, 'Lancement de l''interface des commandes pour l''org_id : '||rec.org_id);
                fnd_file.put_line(fnd_file.OUTPUT, '. Problème de recupération de la responsabilité ');
                fnd_file.put_line(fnd_file.LOG, '. Problème de recupération de la responsabilité ');
            END;
            
            IF v_resp_id IS NOT NULL THEN
            ---------------------------------------------------
            -- Lancement du traitement de MAJ des DA commandes par societe --
            ---------------------------------------------------     
             -- Lancement du traitement 
            g_int_request_id          := Fnd_Request.submit_request (
                                                 'DKA'                            -- APPL
                                                ,'DKAFUSPOMAJPFTF'                -- PROG
                                                ,NULL                             -- PROGRAM_NAME
                                                ,NULL                             -- START
                                                ,FALSE                            -- SUB_REQUEST
                                                ,rec.org_id
                                                );
     
            IF g_int_request_id = 0
            THEN
                p_retcode    := 2;
                 Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Lancement du traitement de MAJ des DA commandes par societe');
            ELSE
                COMMIT;
                v_cpt := v_cpt + 1;
                num_trait_list(v_cpt) := g_int_request_id;
                --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || g_int_request_id);            
                Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement  : ' || g_int_request_id);  
                Fnd_File.put_line(Fnd_File.LOG, '. Numéro du traitement  : ' || g_int_request_id);
           
            END IF;
            
          END IF;
          
        END LOOP;

        fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
        fnd_file.put_line(fnd_file.OUTPUT, 'ETAT DE MAJ DES DA et COMMANDES : ');
        fnd_file.put_line(fnd_file.OUTPUT, '-------------------------------------------- ');
        -- Attente de la fin des traitements
        FOR var IN 1 .. v_cpt LOOP
        
          --Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || num_trait_list(var));            
          Fnd_File.put_line(Fnd_File.OUTPUT,
                            '. Numéro du traitement : ' ||
                            num_trait_list(var));
        
          IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
                                                  g_tempo,
                                                  0,
                                                  v_phase,
                                                  v_status,
                                                  v_dev_phase,
                                                  v_dev_status,
                                                  v_message)) THEN
            p_errbuf := v_Message;
            Fnd_file.put_line(Fnd_file.log,
                              'ERREUR : Attente de la fin du programme de MAJ des DA commandes par societe : Fin du traitement' ||
                              CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
          END IF;
        
          IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
            Fnd_File.put_line(Fnd_File.LOG,
                              'COMPLETION= ' || v_dev_phase || '/' ||
                              v_dev_status);
            Fnd_File.put_line(Fnd_File.OUTPUT,
                              '. Statut de fin : ' || v_phase || '/' ||
                              v_status);
          
          ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
            Fnd_File.put_line(Fnd_File.LOG,
                              'Fin du traitement de MAJ des DA commandes par societe en warning ' ||
                              g_int_request_id);
            Fnd_File.put_line(Fnd_File.OUTPUT,
                              'Fin du traitement de MAJ des DA commandes par societe en warning ' ||
                              g_int_request_id);
            p_retcode := 1;
          
          ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
            p_retcode := 1;  --artf2063044
            p_errbuf  := 'ERREUR : Fin anormale du traitement de MAJ des DA commandes par societe : ' ||
                         v_Message;
          
            fnd_file.put_line(fnd_file.LOG,
                              'ERREUR : Fin anormale du traitement de MAJ des DA commandes par societe ' ||
                              g_int_request_id || CHR(10) || 'Phase/Statut : ' ||
                              v_dev_phase || '/' || v_dev_status || CHR(10) ||
                              'MESSAGE : ' || v_message || CHR(10));
            Fnd_File.put_line(Fnd_File.OUTPUT,
                              '===> ERREUR : Fin anormale du traitement de MAJ des DA commandes par societe ' ||
                              g_int_request_id);
          END IF;
        END LOOP;
        
	

        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin ');    
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'Erreur : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de programme : EXCEPTION OTHERS ');
    END Main; 
END DKA_FUSPOMAJPFTF_Maitre_PKG;


/
SHOW ERRORS;
EXIT
