CREATE OR REPLACE PACKAGE BODY DKA_IGL_INTERFACE_EAI_PKG AS
     ------------------------------------------------------------------------
     -- $Id: DKA_IGL_INTERFACE_EAI_PKG.pkb
     -- Capgemini
     -- Nom              : DKA_IGL_INTERFACE_EAI_PKG.pkb
     -- Description      : Corps du package DKA_IGL_INTERFACE_EAI_PKG
     -- Auteur           : Coudrier Benjamin
     -- Date de création : 06/10/2014
     -- Doc. associée    :
     -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
     ------------------------------------------------------------------------
     -- Historique
     -- Date       Qui Description
     -- ---------- --- ------------------------------------------------------
	   -- 20/04/2015 BCO INC000000673796 - Correctif pour lancement en masse Easylink
     -- 02/05/2016 RAZ Migration R12
     -- 08/02/2017 MEG Correction artf2093212
	 -- 18/09/19 - NBO - INC0324117 - Optimisation de l'import
	   -- ---------- --- ------------------------------------------------------
     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     -- CONSTANTES ET VARIABLES PRIVEES
     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     cn_set_of_books_id NUMBER /*:= Fnd_Profile.VALUE('GL_SET_OF_BKS_ID')*/;
     gv_step            VARCHAR2(500);
     gn_user_id         fnd_user.user_id%TYPE;

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

     ---------------------------------------------------------------------------------------------------
     --  Nom           : get_user_eai
     --  Description   : Fonction retournant l'identifiant de l'utilisateur EAI
     ---------------------------------------------------------------------------------------------------
     FUNCTION get_user_eai RETURN NUMBER IS
          vn_user_id NUMBER;
     BEGIN
          SELECT USER_ID
            INTO vn_user_id
            FROM fnd_user fu
           WHERE fu.user_name = 'EAI'
             AND SYSDATE BETWEEN fu.start_date AND
                 nvl(fu.end_date, SYSDATE);
          RETURN vn_user_id;
     EXCEPTION
          WHEN OTHERS THEN
               vn_user_id := 0;
               RETURN vn_user_id;
     END get_user_eai;

     -------------------------------------------------------------------------------------------------------------------------------------
     --  Nom           : insert_interface_control
     --  Description   : Procedure de création d'une entete de lot d'écritue dans la table
     --                      GL_INTERFACE_CONTROL pour l'origine indiquée
     --  PARAMETRES    :
     -- pv_je_source_name         Entrée
     -- pn_nb_lines_gc        Entrée/Sortie
     -- pn_interface_run_id       Sortie
     -- pn_group_id               Sortie
     -- pv_errbuf                 Entrée/Sortie    message d'erreur
     -- pn_retcode                Sortie           code de retour: 'o=normal', '1=warning', '2=erreur'

     --  VALEUR RETOURNEE :
     --     Description       : code de retour
     --     Valeurs possibles : 0=normal, 1=warning, 2=erreur
     ------------------------------------------------------------------------------------------------------------------------------------------
     PROCEDURE insert_interface_control(pv_je_source_name   IN VARCHAR2,
                                        pn_nb_lines_gc      IN OUT NUMBER,
                                        pn_interface_run_id OUT NUMBER,
                                        pn_group_id         OUT NUMBER,
                                        pv_errbuf           OUT VARCHAR2,
                                        pn_retcode          OUT NUMBER,
                                        vv_segment1         IN VARCHAR2) IS
     
          vv_je_source_name GL_JE_SOURCES.JE_SOURCE_NAME%TYPE;
     
     BEGIN
          gv_step := 'INSERT_INTERFACE_CONTROL 000 - DEBUT.';
          log_msg(gv_step);
          ----- Détermination de l'identifiant du groupe que l'on va insérer ------
          SELECT gl_interface_control_s.NEXTVAL INTO pn_group_id FROM DUAL;
          gv_step := 'INSERT_INTERFACE_CONTROL 001 - SEQUENCE GROUP_ID = ' ||
                     pn_group_id || '.';
          log_msg(gv_step);
     
          ----- Détermination de l'identifiant du lot a insérer ------
          SELECT gl_journal_import_s.NEXTVAL
            INTO pn_interface_run_id
            FROM DUAL;
     
          ----- Déterminer le champ je_source_name -----
          SELECT GLS.JE_SOURCE_NAME
            INTO vv_je_source_name
            FROM GL_JE_SOURCES GLS
           WHERE GLS.USER_JE_SOURCE_NAME = pv_je_source_name;
     
          gv_step := 'INSERT_INTERFACE_CONTROL 002 - SEQUENCE INTERFACE_RUN_ID = ' ||
                     pn_interface_run_id || '.';
          log_msg(gv_step);

          ------------------------------------------------
          ----- Insertion de l'entête du lot -----
          INSERT INTO gl_interface_control
               (je_source_name,
                status,
                interface_run_id,
                GROUP_ID,
                set_of_books_id,
                packet_id)
          VALUES
               (vv_je_source_name,
                'S',
                pn_interface_run_id,
                pn_group_id,
                cn_set_of_books_id,   -- RAZ - Migration R12
                NULL);
          gv_step := 'INSERT_INTERFACE_CONTROL 003 - INSERTION DES ENREGISTREMENTS DANS LA TABLE GL_INTERFACE_CONTROL.';
          log_msg(gv_step);
          COMMIT;
          pn_nb_lines_gc := pn_nb_lines_gc + 1;
          gv_step        := 'INSERT_INTERFACE_CONTROL 999 - FIN NORMAL.';
          log_msg(gv_step);
     EXCEPTION
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'Erreur lors de l''insertion dans la table GL_INTERFACE_CONTROL';
               log_msg(pv_errbuf);
               gv_step := 'INSERT_INTERFACE_CONTROL 999 - FIN ERREUR.';
               log_msg(gv_step);
     END insert_interface_control;

     -------------------------------------------------------------------------------------------------------------------------------------
     --  Nom           : run_import
     --  Description   : Procedure standard du Traitement Standard GLLEZI de l'open interface (easy link)
     --  PARAMETRES    :
     -- pn_group_id              Entrée
     -- pn_interface_run_id      Entrée
     -- pn_request_id            Sortie
     -- pv_status         Sortie
     -- pv_errbuf                Entrée/Sortie    message d'erreur
     -- pn_retcode               Sortie           code de retour: 'o=normal', '1=warning', '2=erreur'

     --  VALEUR RETOURNEE :
     --     Description       :
     --     Valeurs possibles :
     ------------------------------------------------------------------------------------------------------------------------------------------
     PROCEDURE run_import(pn_interface_run_id IN NUMBER,
                          pn_set_of_books_id  IN NUMBER,
                          pn_request_id       OUT NUMBER,
                          pv_status           OUT VARCHAR2,
                          pv_errbuf           OUT VARCHAR2,
                          pn_retcode          OUT NUMBER) IS
          vv_rphase  VARCHAR2(80);
          vv_rstatus VARCHAR2(80);
          vv_dphase  VARCHAR2(30);
          vv_dstatus VARCHAR2(30);
          vv_message VARCHAR2(240);
          cn_tempo CONSTANT NUMBER := 20;
          e_error EXCEPTION;
     BEGIN
          gv_step := 'RUN_IMPORT 000 - DEBUT.';
          log_msg(gv_step); 
     
          gv_step := 'RUN_IMPORT 001 - Lancement du traitement de création de la pièce : Easylink. run-' ||
                     TO_CHAR(pn_interface_run_id);
          log_msg(gv_step);
          pn_request_id := fnd_request.submit_request('SQLGL', --APPL
                                                      'GLLEZL', --PROG
                                                      NULL, --PROGRAM_NAME
                                                      NULL, --START
                                                      FALSE, --SUB_REQUEST
                                                      pn_interface_run_id, --ARGUMENT1
                                                      pn_set_of_books_id, --ARGUMENT2 RAZ R12
                                                      'N', --ARGUMENT3
                                                      NULL, --ARGUMENT4
                                                      NULL, --ARGUMENT5
                                                      'N', --ARGUMENT6
                                                      'O' --ARGUMENT7
                                                      );
     
          gv_step := 'RUN_IMPORT 003 - Validation pour que les GTS puissent prendre la demande';
          log_msg(gv_step);
          COMMIT;
     
          gv_step := 'RUN_IMPORT 005 => Numéro du traitement : ' ||
                     TO_CHAR(pn_request_id);
          log_msg(gv_step);
          gv_step := 'RUN_IMPORT 999 - FIN NORMAL';
          log_msg(gv_step);
     EXCEPTION
          WHEN e_error THEN
               log_msg(gv_step);
               gv_step := 'RUN_IMPORT 999 - FIN ERROR';
               log_msg(gv_step);
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'procédure run_import : ' || SQLERRM(SQLCODE);
               log_msg(pv_errbuf);
     END run_import;

     -----------------------------------------------------------------
     --  NOM           : EDITION_OUTPUT_ENTETE
     --  DESCRIPTION   : procedure d'edition du fichier de sortie
     --
     --  PARAMETRES :
     --
     --  P_RETCODE             code retour out
     --  P_ERRBUF              description de l'erreur out
     --
     -----------------------------------------------------------------
     PROCEDURE edition_output_entete(pn_nb_lines_gc  IN NUMBER,
                                     pn_nb_lines_new IN NUMBER,
                                     pn_nb_lines_p   IN NUMBER,
                                     p_errbuf        OUT VARCHAR2,
                                     p_retcode       OUT NUMBER) IS
     
          l_out VARCHAR2(4000);
          -- Parcours des enregistrements présents dans la table d'interface GL.
          CURSOR cur_easy_link IS
               SELECT * FROM DKA_IGL_INTERFACE_EAI GI FOR UPDATE;
		  
          rec_easy_link cur_easy_link%ROWTYPE;
		  vv_status		VARCHAR2(50);
		  vn_sleep      NUMBER;
     BEGIN
          --Init des variables de sortie
		  vn_sleep := 1;
		  
          gv_step := 'EDITION_OUTPUT 000 : DEBUT';
          log_msg(gv_step);
     
          l_out := pn_nb_lines_new ||
                   ' lignes MAJ dans gl_interface avec le statut « NEW »' ||
                   chr(10) || pn_nb_lines_p ||
                   ' lignes MAJ dans gl_interface avec le statut « P»' ||
                   chr(10) || pn_nb_lines_gc ||
                   ' lignes insérées dans gl_interface_control' || chr(10) ||
                   'EasyLink : .' || chr(10);
          out_msg(l_out);
     
          FOR rec_easy_link IN cur_easy_link LOOP
			  -- DEB 20/04/2015 BCO INC000000673796 - Correctif pour lancement en masse Easylink
			  BEGIN
				  select COUNT(1)
					into vn_sleep
					from FND_CONC_REQ_SUMMARY_V FC
				   where FC.PHASE_CODE != 'C'
					 and FC.REQUEST_ID = rec_easy_link.REQUEST_ID;
			  EXCEPTION
				WHEN OTHERS THEN
					vn_sleep := 0;
			  END;
			  
			  WHILE vn_sleep != 0 LOOP
				DBMS_LOCK.sleep(5);
				  BEGIN
					  select COUNT(1)
						into vn_sleep
						from FND_CONC_REQ_SUMMARY_V FC
					   where FC.PHASE_CODE != 'C'
						 and FC.REQUEST_ID = rec_easy_link.REQUEST_ID;
				  EXCEPTION
					WHEN OTHERS THEN
						vn_sleep := 0;
				  END;
			  END LOOP;
			  
			   --Mise à jour des status + attente de la fin des EASY-LINK.
			   SELECT decode(FCR.STATUS_CODE, 'C', 'normal', 'E', 'en erreur', 'G', 'avertissement', 'X', 'abandonné', 'D', 'annulé', 'A')
			     INTO vv_status
				 FROM FND_CONC_REQ_SUMMARY_V FCR 
				WHERE FCR.REQUEST_ID = rec_easy_link.REQUEST_ID;
				
			   UPDATE DKA_IGL_INTERFACE_EAI
			      SET STATUS = vv_status
				WHERE CURRENT OF cur_easy_link;
			   -- FIN 20/04/2015 BCO INC000000673796 - Correctif pour lancement en masse Easylink
               l_out := 'Easylink n°' || rec_easy_link.REQUEST_ID ||
                        ' terminé ' || vv_status;
               out_msg(l_out);
          END LOOP;
		  COMMIT;
		  
          gv_step := 'EDITION_OUTPUT 999 : FIN';
          log_msg(gv_step);
     
     EXCEPTION
          WHEN OTHERS THEN
               p_retcode := 2;
               p_errbuf  := 'Erreur procedure EDITION_OUTPUT :' || gv_step ||
                            chr(10) || SQLERRM;
               log_msg(p_errbuf);
     END edition_output_entete;

     ---------------------------------------------------------------------------------------------------
     --  Nom           : main
     --  Description   :
     --  PARAMETRES    :
     --  pv_errbuf           Entrée/Sortie       message d'erreur

     --  VALEUR RETOURNEE :  pn_retcode
     --     Description       :
     --     Valeurs possibles : 0=normal, 1=warning, 2=erreur
     ---------------------------------------------------------------------------------------------------
     PROCEDURE main(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    
          vv_user_je_source_name   GL_INTERFACE.USER_JE_SOURCE_NAME%TYPE;
          vv_user_je_category_name GL_INTERFACE.USER_JE_CATEGORY_NAME%TYPE;
          vd_accounting_date       GL_INTERFACE.ACCOUNTING_DATE%TYPE;
          vv_segment1              GL_INTERFACE.SEGMENT1%TYPE;
     
          vn_nb_lines_gc      NUMBER;
          vn_nb_lines_new     NUMBER;
          vn_nb_lines_p       NUMBER;
          vn_group_id         NUMBER;
          vn_interface_run_id NUMBER;
          vn_request_id       NUMBER;
          vv_status           VARCHAR2(100);
          vn_period_open      NUMBER;
          -- Parcours des enregistrements présents dans la table d'interface GL.
          CURSOR cur_gl_interface IS
               SELECT DISTINCT GI.user_je_source_name,
                               GI.user_je_category_name,
                               GI.accounting_date,
                               GI.segment1,
                               GI.STATUS,
                               GI.GROUP_ID
                 FROM GL_INTERFACE GI
                WHERE GI.GROUP_ID IS NULL
                  AND GI.STATUS IN ('NEW', 'P')
                  AND GI.CREATED_BY = gn_user_id;
     
          -- Parcours des enregistrements présents dans la table d'interface GL.
          CURSOR cur_easy_link IS
               SELECT * FROM DKA_IGL_INTERFACE_EAI GI;
     
          --rec_gl_interface cur_gl_interface%ROWTYPE;
          rec_easy_link cur_easy_link%ROWTYPE;
     
          e_main EXCEPTION;
     BEGIN
          gv_step := 'MAIN 000 - Initialisation de l''ensemble des variables.';
          log_msg(gv_step);
          vn_nb_lines_gc         := 0;
          vn_nb_lines_new        := 0;
          vn_nb_lines_p          := 0;
          vv_user_je_source_name := ' ';
          gv_step                := 'MAIN 001 - Suppression des enregistrements dans la table de travail DKA_IGL_INTERFACE_EAI.';
          log_msg(gv_step);
          
          DELETE DKA_IGL_INTERFACE_EAI;
          COMMIT;
     
          gv_step := 'MAIN 002 - Recherche de l''identifiant de l''utilisateur EAI.';
          log_msg(gv_step);
          -- Recherche de l'identifiant de l'utilisateur EAI:
          gn_user_id := get_user_eai();
     
          gv_step := 'MAIN 003 - Parcours des lignes GL dans la table d''interface pour un group_id vide et un statut à ''NEW'' ou ''P''.';
          log_msg(gv_step);
          
          FOR rec_gl_interface IN cur_gl_interface LOOP

               gv_step := 'MAIN 003.0 - Récupération du set_of_books_id.';
               log_msg(gv_step);
                
               ----------- Migration R12 ( RAZ ) Déterminer le champ cn_set_of_books_id-------------------
               BEGIN
                 SELECT ledger_id 
                 INTO   cn_set_of_books_id
                 FROM   gl_ledgers 
                 WHERE  short_name = rec_gl_interface.segment1 /*vv_segment1*/;
               EXCEPTION
                   WHEN OTHERS THEN
                   DBMS_OUTPUT.PUT_LINE ('société'|| rec_gl_interface.segment1 /*vv_segment1*/ || 'non définie comme livre dans Oracle – Contacter l’administrateur' ); -- 
                   CONTINUE;
               END;
               
               gv_step := 'MAIN 003.1 - Vérifier si la pièce est présente sur une période GL ouverte ou fermée.';
               log_msg(gv_step);
               vn_period_open := 0;
               
               -- Recherche de la période GL en cours :
               BEGIN
                    SELECT count(1)
                      INTO vn_period_open
                      FROM gl_period_statuses gps
                     WHERE gps.set_of_books_id = cn_set_of_books_id
                       AND gps.application_id = 101
                       AND rec_gl_interface.accounting_date BETWEEN
                           gps.start_date AND gps.end_date
                       AND gps.closing_status in ('O', 'C');
               EXCEPTION
                    WHEN OTHERS THEN
                         vn_period_open := 0;
               END;
               
               IF vn_period_open > 0 THEN
                    gv_step := 'MAIN 003.2 - Si la date comptable de la pièce GL est comprise dans une période ouverte.';
                    log_msg(gv_step);
               
                    gv_step := 'MAIN 003.2.a - L''origine est ' ||
                               vv_user_je_source_name;
                    log_msg(gv_step);
                    IF rec_gl_interface.user_je_source_name !=
                       vv_user_je_source_name OR rec_gl_interface.user_je_category_name !=
                       vv_user_je_category_name OR rec_gl_interface.accounting_date !=
                       vd_accounting_date OR
                       rec_gl_interface.segment1 != vv_segment1 THEN
                    
                         gv_step := 'MAIN 003.2.b - Si nouveau regroupement user_je_source_name : ' ||
                                    rec_gl_interface.user_je_source_name ||
                                    ' / user_je_category_name : ' ||
                                    rec_gl_interface.user_je_category_name ||
                                    ' / accounting_date : ' ||
                                    rec_gl_interface.accounting_date ||
                                    ' / segment1 : ' ||
                                    rec_gl_interface.segment1 || '.';
                         log_msg(gv_step);
                    
                         vv_user_je_source_name   := rec_gl_interface.user_je_source_name;
                         vv_user_je_category_name := rec_gl_interface.user_je_category_name;
                         vd_accounting_date       := rec_gl_interface.accounting_date;
                         vv_segment1              := rec_gl_interface.segment1;
 
                         gv_step := 'MAIN 003.2.c - Appel de la procédure insert_interface_control.';
                         log_msg(gv_step);
                         insert_interface_control(vv_user_je_source_name, vn_nb_lines_gc, vn_interface_run_id, vn_group_id, pv_errbuf, pn_retcode,vv_segment1);
                    
                         ----- Insertion de l'entête du lot -----
                         INSERT INTO DKA_IGL_INTERFACE_EAI
                              (GROUP_ID,
                               INTERFACE_RUN_ID,
                               SET_OF_BOOK_ID,
                               REQUEST_ID,
                               STATUS,
                               DATE_INSERTION)
                         VALUES
                              (vn_group_id,
                               vn_interface_run_id,
                               cn_set_of_books_id,
                               NULL,
                               NULL,
                               SYSDATE);
                    
                    END IF;
               
                    UPDATE GL_INTERFACE GI
                       SET GI.STATUS = 'NEW', GI.GROUP_ID = vn_group_id
                     WHERE GI.user_je_source_name =
                           rec_gl_interface.user_je_source_name
                       AND GI.user_je_category_name =
                           rec_gl_interface.user_je_category_name
                       AND GI.accounting_date =
                           rec_gl_interface.accounting_date
                       AND (GI.segment1 = rec_gl_interface.segment1 OR
                           (GI.segment1 IS NULL AND
                           rec_gl_interface.segment1 IS NULL));
                    vn_nb_lines_new := vn_nb_lines_new + SQL%ROWCOUNT;
                    COMMIT;
               ELSE
                    gv_step := 'MAIN 003.2.a - Si la date comptable de la pièce GL n''est pas comprise dans une période ouverte.';
                    log_msg(gv_step);
                    UPDATE GL_INTERFACE GI
                       SET GI.STATUS = 'P'
                     WHERE GI.user_je_source_name =
                           rec_gl_interface.user_je_source_name
                       AND GI.user_je_category_name =
                           rec_gl_interface.user_je_category_name
                       AND GI.accounting_date =
                           rec_gl_interface.accounting_date
                       AND (GI.segment1 = rec_gl_interface.segment1 OR
                           (GI.segment1 IS NULL AND
                           rec_gl_interface.segment1 IS NULL));
                    vn_nb_lines_p := vn_nb_lines_p + SQL%ROWCOUNT;
                    COMMIT;
               END IF;
          END LOOP;
          gv_step := 'MAIN 004 - Exécution de l''ensemble des traitements d''intégration.';
          log_msg(gv_step);
          
          -- 18/09/19 - NBO - INC0324117 - Optimisation de l'import
          Fnd_Stats.Gather_Table_Stats(Ownname => 'GL',
                               Tabname => 'GL_INTERFACE',
                               Percent => 100,
                               Degree  => 8,
                               Cascade => True);          
          
          FOR rec_easy_link IN cur_easy_link LOOP
               gv_step := 'MAIN 004.a - EASY-LINK Group_Id = ' ||
                          rec_easy_link.group_id || ' , ' ||
                          rec_easy_link.interface_run_id;
               log_msg(gv_step);
               run_import(rec_easy_link.interface_run_id, rec_easy_link.SET_OF_BOOK_ID, vn_request_id, vv_status , pv_errbuf, pn_retcode);
          
               gv_step := 'MAIN 004.b - Mise à jour de la table DKA_IGL_INTERFACE_EAI.';
               log_msg(gv_step);
               UPDATE DKA_IGL_INTERFACE_EAI GIIE
                  SET GIIE.REQUEST_ID = vn_request_id
                WHERE GIIE.GROUP_ID = rec_easy_link.group_id
                  AND GIIE.INTERFACE_RUN_ID =
                      rec_easy_link.interface_run_id;
          
               COMMIT;
          END LOOP;
          gv_step := 'MAIN 005 - Création de la sortie du traitement.';
          log_msg(gv_step);
          edition_output_entete(vn_nb_lines_gc, vn_nb_lines_new, vn_nb_lines_p, pv_errbuf, pn_retcode);
     
     EXCEPTION
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'Erreur lors de l''exécution de la procédure principal MAIN ' ||
                             chr(10) || SQLERRM;
               log_msg(pv_errbuf);
     END main;

END DKA_IGL_INTERFACE_EAI_PKG;
/
show errors 
exit;
