---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_RELANCE_JT_BDC.prc
-- DESCRIPTION      : Lancement automatique du traitement DKA_RELANCE_JT_BDC
---
--- AUTEUR           : GVA
--- DATE DE CREATION : 28/12/2010
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------
--- 01032011   CDE Adapatation pour lancement sur Veolia
---------------------------------------------------------------------------------------------------------------
--- 24/05/16   MEG Migration R12
---------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE DKA_RELANCE_JT_BDC
(pv_errbuf    IN OUT   VARCHAR2,
 pn_retcode   OUT      NUMBER,
 pv_date_deb  IN VARCHAR2,
 pv_date_fin  IN VARCHAR2
)
IS
CURSOR CUR_BDC
IS
  SELECT distinct fcr1.argument3 seg1
  FROM   fnd_concurrent_requests fcr1, -- prog edition bdc
         fnd_concurrent_requests fcr2, -- etape edition bdc
         fnd_concurrent_requests fcr3, -- etape stockage bdc
         fnd_conc_req_summary_v fcr4,  -- prog stockage bdc
		 fnd_responsibility fr, 
		 fnd_profile_option_values  fpov,
         fnd_profile_options fpo
  WHERE  fcr3.request_id = fcr4.parent_request_id 
  AND    fcr2.parent_request_id = fcr3.parent_request_id 
  AND    fcr1.parent_request_id = fcr2.request_id 
  AND    fcr1.output_file_type = 'PDF'
  and    fcr4.actual_start_date >= fnd_conc_date.string_to_date(pv_date_deb)
  and    fcr4.actual_start_date <= fnd_conc_date.string_to_date(pv_date_fin)
  and    fcr4.program_short_name = 'DKA_SPOBON_STOCIMG'
  and    fcr4.status_code = 'E'
  and    fcr4.responsibility_id = fr.responsibility_id
  and    fr.responsibility_id = fpov.level_value
  and    fpov.profile_option_id = fpo.profile_option_id
  and    fpo.profile_option_name = 'ORG_ID'
  and    fpov.level_id = 10003
  and    fpov.profile_option_value = fnd_profile.value('ORG_ID');
  
  REC_BDC CUR_BDC%ROWTYPE;
  v_success BOOLEAN;
  v_progress VARCHAR2(300);
  v_request_id NUMBER;
  v_user_id NUMBER;
  v_qty_precision VARCHAR2(30);
  va_request_ids  pa_utils.idtabtyp; -- GV20100526
  vn_requests_cnt NUMBER; -- GV20100526
  vv_phase                 VARCHAR2(100);
  vv_status                VARCHAR2(100);
  vv_dev_phase             VARCHAR2(100);
  vv_dev_status            VARCHAR2(100);
  vv_message               VARCHAR2(2000);

BEGIN
     pn_retcode := 0;
     pv_errbuf := NULL;
     dka_tools_pkg.put_debug_message ('Relance JT envoi BDC');
     dka_tools_pkg.put_debug_message ('');
     dka_tools_pkg.put_debug_message ('-------------------------------');
     dka_tools_pkg.put_debug_message ('| N° Commande   | Request_Id  |');
     dka_tools_pkg.put_debug_message ('-------------------------------');
     
     vn_requests_cnt    := 0;

     FOR REC_BDC IN CUR_BDC
     LOOP
         dka_tools_pkg.put_debug_message(rec_bdc.seg1);
         -- Mise à jour Flag envoi automatique
         v_progress := 'Mise à jour Flag Envoi automatique à NON';
         dka_tools_pkg.put_debug_message (v_progress);
         
         UPDATE PO_HEADERS
         SET ATTRIBUTE6 = 'NON'
         WHERE SEGMENT1 = REC_BDC.SEG1;
         
         v_success := fnd_submit.set_request_set('DKA','DKA_SPOBON_PDF_FAX');            
           
         IF (v_success)
         THEN
             -- appel du programme d'edition au format PDF
             v_progress := 'Préparation 1ère phase';  
             dka_tools_pkg.put_debug_message (v_progress); 
             dbms_output.put_line(v_progress);
               
             v_success := fnd_submit.submit_program (
                                  'DKA'
                                 ,'DKA_SPOBON_PDF'
                                 ,'STAGE10'
                                 ,'R'
                                 ,NULL
                                 ,rec_bdc.seg1
                                 ,rec_bdc.seg1
                                 ,NULL
                                 ,NULL
                                 ,NULL
                                 ,NULL
                                 ,NULL
                                 ,NULL
                                 ,'Y'
                                 ,NULL
                                 ,fnd_global.user_id
                                 ,v_qty_precision
                                 ,'N'
                                 ,NULL
                                 ,'Y'
                                 ,'N'
                               );
             IF (v_success)
             THEN
                 -- appel du programme d'impression bon de commande en XML

                 v_progress        := 'Préparation 2ème phase'; 
                 dka_tools_pkg.put_debug_message (v_progress);  
                 dbms_output.put_line(v_progress);  
                            
                 v_success := fnd_submit.submit_program (
                               'DKA'
                              ,'DKA_SPOBON_XML'
                              ,'STAGE25'
                              );

                 IF (v_success)
                 THEN
                     -- appel du programme de stockage des bons de commande
                     v_progress        := 'Préparation 3ème phase';
                     dka_tools_pkg.put_debug_message (v_progress);
                     dbms_output.put_line(v_progress); 
                     
                     v_success := fnd_submit.submit_program (
                                   'DKA'
                                  ,'DKA_SPOBON_STOCIMG'
                                  ,'STAGE30'
                                  );

                     IF (v_success)
                     THEN
                         -- appel du programme de stockage des bons de commande
                         v_progress        := 'Préparation 4ème phase';
                         dka_tools_pkg.put_debug_message (v_progress);
                         dbms_output.put_line(v_progress); 
                         
                         v_success := fnd_submit.submit_program (
                                       'DKA'
                                      ,'DKA_SPOBON_DUPLI_MAIL'
                                      ,'STAGE40'
                                      );

                         IF (v_success)
                         THEN
                             v_progress := 'Lancement du jeu'; 
                             dka_tools_pkg.put_debug_message (v_progress);  
                                                       
                             v_request_id := fnd_submit.submit_set(null,FALSE);
                             
                             v_progress        := 'Request_id : ' || TO_CHAR (v_request_id);
                             dka_tools_pkg.put_debug_message (v_progress);
                             dbms_output.put_line(v_progress); 
                             
                             dka_tools_pkg.put_debug_message ('| '|| RPAD(rec_bdc.seg1, 14) || '| ' || RPAD(TO_CHAR (v_request_id), 12) || '|');

                             vn_requests_cnt                  := vn_requests_cnt + 1;
                             va_request_ids (vn_requests_cnt) := v_request_id;                                                          
                         END IF;
                     END IF;
                 END IF;
             END IF;
         END IF;
		 
	 	 UPDATE po_headers
		 SET attribute15 = to_char(v_request_id)
         WHERE segment1 = rec_bdc.seg1;	 
		 
     END LOOP;         
     dka_tools_pkg.put_debug_message ('-------------------------------');
     COMMIT;
     
     WHILE vn_requests_cnt > 0
     LOOP
         IF NOT (fnd_concurrent.wait_for_request (
                            va_request_ids (vn_requests_cnt),
                            15,
                            0,
                            vv_phase,
                            vv_status,
                            vv_dev_phase,
                            vv_dev_status,
                            vv_message
                        )
                       )
         THEN
             dka_tools_pkg.put_outdebug_message (
             'Traitement numéro '|| TO_CHAR (va_request_ids (vn_requests_cnt)) || ' trop long ou tombé en erreur'
                  );
         ELSIF (    vv_dev_phase = 'COMPLETE'
                 AND vv_dev_status = 'NORMAL'
                      )
         THEN
             dka_tools_pkg.put_outdebug_message (
              'Traitement numéro '|| TO_CHAR (va_request_ids (vn_requests_cnt)) || ' correctement exécuté'
                    );   
         END IF; 
         vn_requests_cnt    := vn_requests_cnt - 1;
		 
     END LOOP;
     
     FOR REC_BDC IN CUR_BDC
     LOOP                             
         -- Remise à jour Flag Envoi Automatique
         UPDATE PO_HEADERS
         SET ATTRIBUTE6 = 'OUI'
         WHERE SEGMENT1 = REC_BDC.SEG1;    
     END LOOP;
         
     COMMIT;
     
 EXCEPTION
 WHEN OTHERS
    THEN dka_tools_pkg.put_debug_message('Erreur lors de ' || v_progress); 
         dka_tools_pkg.put_debug_message(SQLERRM); 
    ROLLBACK;
END DKA_RELANCE_JT_BDC;    
/
SHOW ERROR;
EXIT

     
     
         
                           
                           
                           
                           
                           
                           
                           
                           
                           
                           
                           
                           
