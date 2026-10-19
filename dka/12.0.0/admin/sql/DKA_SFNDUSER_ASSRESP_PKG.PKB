	CREATE OR REPLACE PACKAGE BODY DKA_SFNDUSER_ASSRESP_PKG AS
	  --------------------------------------------------------------------------------
	  -- $
	  -- Capgemini
	  -- Projet           : DALKIA Oracle Applications
	  -- Nom              : DKA_SFNDUSER_ASSRESP_PKG 
	  -- Nom              : DKA_SFNDUSER_ASSRESP_PKG 
	  -- Description      : Body du package DKA_SFNDUSER_ASSRESP_PKG ( IMPORT DES RECEPTIONS PO )
	  -- Auteur           : SELO
	  -- Date de création : 17/09/2020
	  -- Doc. associée    :
	  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
	  --------------------------------------------------------------------------------
	  -- Historique
	  -- Date       Qui Description
	  -- ---------- --- --------------------------------------------------------------
	  -- 
	  --------------------------------------------------------------------------------  
	  
	 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- CONSTANTES ET VARIABLES PRIVEES
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
        liste_user                l_user;
		TYPE summary_typ IS RECORD 
		(
		 loaded_header_rows               NUMBER      -- Nb des en-entêtes chargées en table specifique
		,loaded_transaction_rows          NUMBER      -- Nb des transactions chargés en table specifique
		,rec_final_rows                   NUMBER      -- Nb des en-entêtes chargées en table specifique
		,rejected_header_rows             NUMBER      -- Nb de Lignes en-entêtes rejectées
		,rejected_io_rows                 NUMBER      -- Nb de Lignes transaction rejectés
		,complete_header_rows             NUMBER      -- SELO
		,inserted_header_rows             NUMBER      -- Nb de Lignes en-entêtes insérées
		,inserted_transaction_rows        NUMBER      -- Nb de Lignes transaction insérés
		,purged_header_rows               NUMBER      -- Nb de Lignes purgées en table spécifique   
		,purged_interface_rows            NUMBER      -- Nb de Lignes purgées en table spécifique 
		, purged_errors_rows              NUMBER
		, purged_transaction_rows         NUMBER
		,message_flag                     NUMBER      -- Flag d'entete etat des erreurs
		,reprise_flag                     VARCHAR2(1) -- Flag reprise
		,warning_flag                     VARCHAR2(1) -- Flag warning
		)
		;

		g_summary                      summary_typ;

		g_user_id                      fnd_user.user_id%TYPE;
		g_login_id                     fnd_logins.login_id%TYPE;
		g_request_id                   fnd_concurrent_requests.request_id%TYPE;
		g_loader_request_id            fnd_concurrent_requests.request_id%TYPE;
		gv_printer                     fnd_concurrent_requests.printer%TYPE;
		g_number_of_copies             fnd_concurrent_requests.number_of_copies%TYPE;
		g_tempo                        NUMBER;
		g_gl_date                      DATE; -- OBE
		--g_nb_entetes_group             NUMBER;


	  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	  -- FONCTIONS ET PROCEDURES PRIVEES
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
	g_group_id NUMBER := 0;
	g_group_id_correct NUMBER := 0;  --SELO
	g_group_id_add NUMBER := 0;  --SELO
	/*
	 *************************************************************************
	 * PROCEDURE NAME : Output_Header
	 *
	 * DESCRIPTION
	 *  Procédure pour insérer une en-tête dans le fichier de sortie
	 *
	 * PARAMETERS
	 * ==========
	 * NAME              DESCRIPTION
	 * ----------------- ------------------------------------------------------
	 *
	 *
	 ************************************************************************
	 */

	  PROCEDURE output_header
	  IS
			cv_line                     VARCHAR2 (100);
			v_conc_program_name         fnd_concurrent_programs.concurrent_program_name%TYPE;
			v_user_conc_program_name    fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
	  BEGIN

			cv_line    := '----------------------------------------------------------------------------------------------------';

			----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
			BEGIN
				SELECT fcp.concurrent_program_name,
					   fcpt.user_concurrent_program_name
				INTO   v_conc_program_name,
					   v_user_conc_program_name
				FROM   fnd_concurrent_programs fcp,
					   fnd_concurrent_programs_tl fcpt
				WHERE  fcp.application_id = Fnd_Global.prog_appl_id
				AND    fcp.concurrent_program_id = Fnd_Global.conc_program_id
				AND    fcpt.application_id = Fnd_Global.prog_appl_id
				AND    fcpt.concurrent_program_id = Fnd_Global.conc_program_id
				AND    fcpt.LANGUAGE = Fnd_Global.current_language;
			EXCEPTION
				WHEN OTHERS
				THEN
					v_user_conc_program_name    := '???????????????????????';
					v_conc_program_name         := '???????';
			END;


			Fnd_File.put_line (Fnd_File.output, cv_line );
			Fnd_File.put_line (Fnd_File.output, 'COMPTE-RENDU DU TRAITEMENT « DKA : Utilitaire de gestion des accès utilisateurs aux responsabilités »');
			Fnd_File.put_line (Fnd_File.output, 'Traitement n° '||fnd_global.conc_request_id);
			Fnd_File.put_line (Fnd_File.output, 'Programme lancé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
			Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
			--Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10) || CHR(10));
	  END output_header;
	  
	  
	 /*
	 *************************************************************************
	 * PROCEDURE NAME : Request_parameters
	 *
	 * DESCRIPTION
	 *  Procédure pour afficher les valeurs de paramètres du traitement
	 *
	 * PARAMETERS
	 * ==========
	 * NAME              DESCRIPTION
	 * ----------------- ------------------------------------------------------
	 *
	 ************************************************************************
	 */

	  PROCEDURE Request_parameters
	  IS

		  CURSOR cur_parameters
				IS
				SELECT form_left_prompt
				FROM   fnd_concurrent_requests fcr,
					   fnd_concurrent_programs fcp,
					   fnd_descr_flex_col_usage_vl fdfcu
				WHERE  fdfcu.descriptive_flexfield_name = '$SRS$.'||fcp.concurrent_program_name
				AND    fcp.concurrent_program_id = fcr.concurrent_program_id
				AND    fcr.request_id = Fnd_Global.conc_request_id
				ORDER BY fdfcu.column_seq_num
				;
			rec_parameters        cur_parameters%ROWTYPE;

			sql_req               VARCHAR2(500);
			v_argument_number    VARCHAR2(12);
			v_argument_num       NUMBER;
			v_argument_value     VARCHAR2(240);
	  BEGIN

			Fnd_File.put_line (Fnd_File.log, 'PARAMETRES : ');
			Fnd_File.put_line (Fnd_File.log, '--------------');
			Fnd_File.put_line (Fnd_File.output, 'PARAMETRES : ');
			Fnd_File.put_line (Fnd_File.output, '------------');		

			v_argument_num := 1;

			OPEN cur_parameters;
			FETCH cur_parameters INTO rec_parameters;

				 IF (cur_parameters%FOUND)
				 THEN
					   v_argument_number := 'ARGUMENT'||v_argument_num;

					   sql_req := 'SELECT '||v_argument_number||
								  ' FROM fnd_concurrent_requests '||
								  'WHERE request_id = Fnd_Global.conc_request_id';

					   EXECUTE IMMEDIATE sql_req INTO v_argument_value;

					   Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
					   Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);


					   LOOP
						  FETCH cur_parameters INTO rec_parameters;
						  EXIT WHEN cur_parameters%NOTFOUND;

							  v_argument_num := v_argument_num + 1;
							  v_argument_number := 'ARGUMENT'||v_argument_num;

							  sql_req := 'SELECT '||v_argument_number||
										 ' FROM fnd_concurrent_requests '||
										 'WHERE request_id = Fnd_Global.conc_request_id';

							  EXECUTE IMMEDIATE sql_req INTO v_argument_value;

							 -- Fnd_File.put_line (Fnd_File.output, rec_parameters.form_left_prompt||' : '||v_argument_value);
							  Fnd_File.put_line (Fnd_File.log, rec_parameters.form_left_prompt||' : '||v_argument_value);
					   END LOOP;

					   --Fnd_File.put_line (Fnd_File.output,CHR(10));

				ELSE
					   --Fnd_File.put_line (Fnd_File.output,'Aucun argument');
					   Fnd_File.put_line (Fnd_File.log,'Aucun argument');
				END IF;

			CLOSE cur_parameters;

	  END Request_parameters;

	 /*
	 *************************************************************************
	 * PROCEDURE NAME : Output_End
	 *
	 * DESCRIPTION
	 *  Procédure pour insérer une fin dans le fichier de sortie
	 *
	 * PARAMETERS
	 * ==========
	 * NAME              DESCRIPTION
	 * ----------------- ------------------------------------------------------
	 *
	 *
	 ************************************************************************
	 */

	  PROCEDURE output_end
	  IS
			cv_line                     VARCHAR2 (100);
	  BEGIN

			cv_line    := '-------------------------------------------------------------------------------------------------';

			Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
			Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
			Fnd_File.put_line (Fnd_File.output, cv_line);
	  END output_end;

	

	  PROCEDURE init (
					  p_errbuf    OUT      VARCHAR2,
					  p_retcode   OUT      NUMBER,
					  p_reprise   IN       VARCHAR2--,
					  --p_gl_date   IN       VARCHAR2
					  )
	  IS

		v_current_program_unit    VARCHAR2(30);
		v_step_program_error      VARCHAR2(1000);
		program_error             EXCEPTION;
		rec_param dka_parameters%ROWTYPE;

	  BEGIN

			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début init');

			----------------------------------
			-- Initialisation des variables --
			----------------------------------
			p_errbuf  := NULL;
			p_retcode := 0;
			v_current_program_unit := 'INIT';

			------------------------
			-- Variables globales --
			------------------------ 

			g_user_id                      := fnd_global.user_id;
			g_login_id                     := fnd_global.login_id;
			g_request_id                   := fnd_global.conc_request_id;
			g_tempo                        := 20;

			-- Variables globales de comptage

			g_summary.loaded_header_rows             := 0;
			g_summary.rec_final_rows                 := 0;
			g_summary.loaded_transaction_rows        := 0;

			g_summary.rejected_header_rows           := 0;
			g_summary.rejected_io_rows               := 0;
			g_summary.complete_header_rows           := 0;

			g_summary.inserted_header_rows           := 0;
			g_summary.inserted_transaction_rows      := 0;

			g_summary.purged_header_rows             := 0;
			g_summary.purged_interface_rows          := 0;
			g_summary.purged_errors_rows             := 0;
			g_summary.purged_transaction_rows        := 0;
			
			g_summary.message_flag                   := 0;
			g_summary.reprise_flag                   := NVL(p_reprise,'N');
			g_summary.warning_flag                   := 'N';
			
			
			-- Formatage de la date comptable 
			--bg_gl_date := TRUNC(fnd_date.canonical_to_date(p_gl_date)); -- SELO
			g_gl_date:=sysdate; -- SELO
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');
			
			BEGIN
			   SELECT printer
					 ,number_of_copies
			   INTO   gv_printer
					 ,g_number_of_copies
			   FROM   fnd_concurrent_requests fcr
			   WHERE  fcr.request_id = g_request_id;
			EXCEPTION
			WHEN NO_DATA_FOUND
			THEN
			   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Erreur de récupération de l''imprimante');
			   gv_printer := NULL;
			   g_number_of_copies := 0;
			END;
			
		EXCEPTION
			WHEN program_error THEN
				 fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
				 RAISE; 
			WHEN OTHERS
			THEN
				p_retcode   := 2;
				p_errbuf    := 'INIT : ' ||SQLERRM;
	  END init;
	/*
	 *************************************************************************
	 * PROCEDURE NAME : validate_data_group
	 * 
	 * DESCRIPTION
	 *  Procédure d'insertion dans les tables finales
	 *
	 * PARAMETERS
	 * ==========
	 * NAME               DESCRIPTION
	.* -----------------  ------------------------------------------------------
	 * p_errbuf          Retour de message éventuel
	 * p_retcode         Statut du traitement en sortie
	 * 
	 ************************************************************************
	 */
	--------------------------------------------------------------------------------------
	PROCEDURE validate_data_group(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER, v_RECORD_ID NUMBER) IS
	  v_code_site_four              VARCHAR2(100);
	  v_org_id                      NUMBER;
	  v_pers_id                     NUMBER;
	  v_rcv_header_id               NUMBER;
	  v_message                     VARCHAR2(500);
	  v_flag_erreur                 BOOLEAN := FALSE;
	  v_flag_erreur_trans           BOOLEAN := FALSE;
	  v_ship_to_organization_id     NUMBER;
	  v_code_site_four1             VARCHAR2(240);
	  v_receive_trans_id            NUMBER;
	  v_ship_to_location            VARCHAR2(100); -- OBE
	  v_vendor_site_code            VARCHAR2(25); -- OBE
	  v_vendor_site_code_2          VARCHAR2(25); -- OBE
	  v_location_code               VARCHAR2(60); -- OBE
	  v_deliver_to_location         VARCHAR2(60); -- OBE 
	  v_deliver_to_location_id      NUMBER;       -- RBE
	  v_DELIVER_TO_PERSON           VARCHAR2(240);
	  e_err_org_not_exist           EXCEPTION;
	  v_Multi_receipt               NUMBER; -- SELO
	  v_org_ok                      Number; -- SELO
	  v_vendor_id                   Number; -- SELO
	  v_start_date                  DATE;
	  v_DATE_DEBUT_VALIDITE         DATE;
	  V_RECEIPT_DATE                DATE;
	  v_CMD_ID                      Number;
	  v_vendor_site_id              Number;
	  v_LIGNE_ID                    Number;
	  v_reject                      Number;
	  vs_ship_to_Org_Id             Number; 
	  V_SHIPMENT_HEADER_ID          Number;
	  vs_vendor_id                  Number;
	  vs_vendor_site_id             Number;
	  vs_packing_slip               VARCHAR2(60);
	  v_rct_quantity                Number;
	  v_shipment_line_id            Number;
	  v_TRANSACTION_ID              Number;
	  v_PARENT_TRANSACTION_ID       Number; 
	  V_UNIT_OF_MEASURE             VARCHAR2(60);
	  v_LINE_LOCATION_ID            Number; 
	  v_PO_DISTRIBUTION_ID          Number; 
	  
	  
	  v_user                        Number;
	  v_RESPONSIBILITY_ID           Number;
	  -- Cursor des receptions
	  CURSOR cur_user_resp IS
		SELECT *
		  FROM dka.DKA_SFNDUSER_ASSRESP dsa
		 WHERE 1 = 1
		  -- AND load_request_id = DECODE(g_loader_request_id, -1, load_request_id, g_loader_request_id) -- 
		  -- AND flag = '-1' -- 
		   and dsa.record_id=v_RECORD_ID
		 ORDER BY record_id -- SOCIETE, REGION  ajout
		   FOR UPDATE OF STATUT, V_USER_ID       --, ORG_ID, CODE_SITE_FOUR -- 
		   ;

	BEGIN

	  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');
	  Fnd_File.put_line(Fnd_File.LOG,
						TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
						'Validation des données dans les tables spécifiques - record_id : '||v_RECORD_ID);

	  
	  FOR rec_cur_user_resp IN cur_user_resp LOOP
		BEGIN
			v_flag_erreur := FALSE;
			v_user := null; 
			IF rec_cur_user_resp.USER_NAME IS NULL THEN
				v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_03');
				--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
				DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
												'DKA_SFNDUSER_ASSRESP', --prog_name
												'USER_NAME',               --source
												'DKA_SFNDUSER_ASSRESP' ,   --table_name
												rec_cur_user_resp.RECORD_ID,  --table_id
												'USER_NAME',  --column_name
												rec_cur_user_resp.USER_NAME, --column_value
												'E',                       --message_type
											   v_message                   --message_text
												);
					v_flag_erreur := TRUE;
				
				UPDATE DKA_SFNDUSER_ASSRESP
				 SET STATUT = 'REJECTED'
			   WHERE CURRENT OF cur_user_resp;
			ELSE
				BEGIN
					select user_id into v_user
					  from fnd_user
					 where user_name = rec_cur_user_resp.USER_NAME;
					 
					update DKA_SFNDUSER_ASSRESP
					   SET V_USER_ID = v_user
					 WHERE CURRENT OF cur_user_resp;
					EXCEPTION
					WHEN OTHERS THEN
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_04');
						--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
						DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
														'DKA_SFNDUSER_ASSRESP', --prog_name
														'USER_NAME',               --source
														'DKA_SFNDUSER_ASSRESP' ,   --table_name
														rec_cur_user_resp.RECORD_ID,  --table_id
														'USER_NAME',  --column_name
														rec_cur_user_resp.USER_NAME, --column_value
														'E',                       --message_type
													   v_message                   --message_text
														);
							v_flag_erreur := TRUE;
						
						UPDATE DKA_SFNDUSER_ASSRESP
						 SET STATUT = 'REJECTED'
					   WHERE CURRENT OF cur_user_resp;
				End;
		  
			END IF;
		  
			v_RESPONSIBILITY_ID := null;
			IF rec_cur_user_resp.RESPONSIBILITY IS NOT NULL THEN
				BEGIN
					select RESPONSIBILITY_ID into v_RESPONSIBILITY_ID
					  from fnd_responsibility_tl
					 where responsibility_name = rec_cur_user_resp.RESPONSIBILITY
					   and language='F';
					   
					EXCEPTION
					WHEN OTHERS THEN
						v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_05');
							--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
							DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
															'DKA_SFNDUSER_ASSRESP', --prog_name
															'RESPONSIBILITY_ID',               --source
															'DKA_SFNDUSER_ASSRESP' ,   --table_name
															rec_cur_user_resp.RECORD_ID,  --table_id
															'RESPONSIBILITY_ID',  --column_name
															rec_cur_user_resp.RESPONSIBILITY, --column_value
															'E',                       --message_type
														   v_message                   --message_text
															);
								v_flag_erreur := TRUE;
							
							UPDATE DKA_SFNDUSER_ASSRESP
							 SET STATUT = 'REJECTED'
						   WHERE CURRENT OF cur_user_resp;
				End;
			END IF;
			IF ( v_RESPONSIBILITY_ID is not null ) and (rec_cur_user_resp.INACTIVE_DATE  is null) then
			BEGIN
			
			select RESPONSIBILITY_ID into v_RESPONSIBILITY_ID
			  from fnd_responsibility
			 where responsibility_id = v_RESPONSIBILITY_ID
			   and start_date <= sysdate
			   and nvl(end_date,sysdate+1) >=sysdate;
			   
			EXCEPTION
			WHEN OTHERS THEN
			v_RESPONSIBILITY_ID := null;
			v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_06');
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													'DKA_SFNDUSER_ASSRESP', --prog_name
													'RESPONSIBILITY_ID',               --source
													'DKA_SFNDUSER_ASSRESP' ,   --table_name
													rec_cur_user_resp.RECORD_ID,  --table_id
													'RESPONSIBILITY_ID',  --column_name
													rec_cur_user_resp.RESPONSIBILITY, --column_value
													'E',                       --message_type
												   v_message                   --message_text
													);
						v_flag_erreur := TRUE;
					
					UPDATE DKA_SFNDUSER_ASSRESP
					 SET STATUT = 'REJECTED'
				   WHERE CURRENT OF cur_user_resp;
			End;	  
		  END IF;

		  
		  -- RG403 
		  IF (rec_cur_user_resp.USER_NAME IS not NULL) and (rec_cur_user_resp.RESPONSIBILITY IS NULL) and ( rec_cur_user_resp.INACTIVE_DATE IS NULL ) THEN
			v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_07');
			--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
			DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											'DKA_SFNDUSER_ASSRESP', --prog_name
											'INACTIVE_DATE',               --source
											'DKA_SFNDUSER_ASSRESP' ,   --table_name
											rec_cur_user_resp.RECORD_ID,  --table_id
											'INACTIVE_DATE',  --column_name
											rec_cur_user_resp.INACTIVE_DATE, --column_value
											'E',                       --message_type
											v_message                   --message_text
											);
				v_flag_erreur := TRUE;
			
			UPDATE DKA_SFNDUSER_ASSRESP
			 SET STATUT = 'REJECTED'
		   WHERE CURRENT OF cur_user_resp;
		 
		  ELSIF (rec_cur_user_resp.USER_NAME IS not NULL) and (rec_cur_user_resp.RESPONSIBILITY IS NULL) and ( rec_cur_user_resp.INACTIVE_DATE IS NOT NULL ) THEN
			  BEGIN
				  v_user :=null;
				  select user_id into v_user
					from fnd_user
				   where user_name = rec_cur_user_resp.USER_NAME
					 and start_date <= rec_cur_user_resp.INACTIVE_DATE;
					 
			   EXCEPTION
				WHEN OTHERS THEN
				--Début SHA
				    BEGIN 
					v_DATE_DEBUT_VALIDITE := null;
					SELECT start_date into v_DATE_DEBUT_VALIDITE
				    FROM fnd_user 
				    WHERE user_name = rec_cur_user_resp.USER_NAME;
					END;
				--Fin SHA
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_08', 'DATE_DEBUT' , to_char(v_DATE_DEBUT_VALIDITE,'dd/mm/yyyy'));
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													'DKA_SFNDUSER_ASSRESP', --prog_name
													'INACTIVE_DATE',               --source
													'DKA_SFNDUSER_ASSRESP' ,   --table_name
													rec_cur_user_resp.RECORD_ID,  --table_id
													'INACTIVE_DATE',  --column_name
													rec_cur_user_resp.INACTIVE_DATE, --column_value
													'E',                       --message_type
												   v_message                   --message_text
													);
					v_flag_erreur := TRUE;
					
					UPDATE DKA_SFNDUSER_ASSRESP
					 SET STATUT = 'REJECTED'
					WHERE CURRENT OF cur_user_resp;
			  END;
		   END IF;
		
		  IF (v_user IS not NULL) and (v_RESPONSIBILITY_ID IS not NULL) and ( rec_cur_user_resp.INACTIVE_DATE IS not NULL ) THEN
			BEGIN 
				v_RESPONSIBILITY_ID := null;
				SELECT ret.responsibility_ID into v_RESPONSIBILITY_ID
				  FROM fnd_user user1
					 , FND_USER_RESP_GROUPS_DIRECT user_resp
					 , fnd_responsibility_tl ret 
				 WHERE user1.user_id = user_resp.user_id
				   AND user_resp.responsibility_id = ret.responsibility_id
				   AND user1.user_name = rec_cur_user_resp.USER_NAME
				   and language = 'F'
				   and ret.responsibility_name = rec_cur_user_resp.RESPONSIBILITY
			;	 
			EXCEPTION
			WHEN OTHERS THEN

					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_10');
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											'DKA_SFNDUSER_ASSRESP', --prog_name
											'INACTIVE_DATE',               --source
											'DKA_SFNDUSER_ASSRESP' ,   --table_name
											rec_cur_user_resp.RECORD_ID,  --table_id
											'INACTIVE_DATE',  --column_name
											rec_cur_user_resp.INACTIVE_DATE, --column_value
											'E',                       --message_type
											v_message                   --message_text
											);
				v_flag_erreur := TRUE;
			
				UPDATE DKA_SFNDUSER_ASSRESP
				 SET STATUT = 'REJECTED'
			   WHERE CURRENT OF cur_user_resp;
			   
			  END;
		   END IF;

		  IF (v_user IS not NULL) and (v_RESPONSIBILITY_ID IS not NULL) and ( rec_cur_user_resp.INACTIVE_DATE IS not NULL ) THEN
			BEGIN 
				v_RESPONSIBILITY_ID := null;
				SELECT ret.responsibility_ID  
				  into v_RESPONSIBILITY_ID   
				  FROM fnd_user user1
					 , FND_USER_RESP_GROUPS_DIRECT user_resp
					 , fnd_responsibility_tl ret 
				 WHERE user1.user_id = user_resp.user_id
				   AND user_resp.responsibility_id = ret.responsibility_id
				--   AND user_resp.end_date IS NULL
				   AND user1.user_name = rec_cur_user_resp.USER_NAME
				   and language= 'F'
				   and ret.responsibility_name = rec_cur_user_resp.RESPONSIBILITY
				   and user_resp.start_date <= rec_cur_user_resp.INACTIVE_DATE
			;	 
			EXCEPTION
			WHEN OTHERS THEN
                    --Début SHA
				   
				    BEGIN 
					v_start_date        := null;
					SELECT  user_resp.start_date 
					into    v_start_date
				    FROM fnd_user user1
					 , FND_USER_RESP_GROUPS_DIRECT user_resp
					 , fnd_responsibility_tl ret 
				    WHERE user1.user_id = user_resp.user_id
				    AND user_resp.responsibility_id = ret.responsibility_id
				    AND user1.user_name = rec_cur_user_resp.USER_NAME
				    and language = 'F'
				    and ret.responsibility_name = rec_cur_user_resp.RESPONSIBILITY;
					END;
				--Fin SHA
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_09', 'DATE_DEBUT' , to_char(v_start_date,'dd/mm/yyyy'));
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											'DKA_SFNDUSER_ASSRESP', --prog_name
											'INACTIVE_DATE',               --source
											'DKA_SFNDUSER_ASSRESP' ,   --table_name
											rec_cur_user_resp.RECORD_ID,  --table_id
											'INACTIVE_DATE',  --column_name
											rec_cur_user_resp.INACTIVE_DATE, --column_value
											'E',                       --message_type
											v_message                   --message_text
											);
				v_flag_erreur := TRUE;
			
				UPDATE DKA_SFNDUSER_ASSRESP
				 SET STATUT = 'REJECTED'
			   WHERE CURRENT OF cur_user_resp;
			   
			  END;
		   END IF; 

		 IF (v_user IS not NULL) and (v_RESPONSIBILITY_ID IS not NULL) and ( rec_cur_user_resp.INACTIVE_DATE IS not NULL ) THEN
			BEGIN 
				SELECT ret.responsibility_ID into v_RESPONSIBILITY_ID
				  FROM fnd_user user1
					 , FND_USER_RESP_GROUPS_DIRECT user_resp
					 , fnd_responsibility_tl ret 
				 WHERE user1.user_id = user_resp.user_id
				   AND user_resp.responsibility_id = ret.responsibility_id
				   AND user_resp.end_date IS NULL
				   AND user1.user_name = rec_cur_user_resp.USER_NAME
				   and language= 'F'
				   and ret.responsibility_name = rec_cur_user_resp.RESPONSIBILITY
				   and user_resp.start_date <= rec_cur_user_resp.INACTIVE_DATE
			;	 
			EXCEPTION
			WHEN OTHERS THEN

					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_11');
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											'DKA_SFNDUSER_ASSRESP', --prog_name
											'INACTIVE_DATE',               --source
											'DKA_SFNDUSER_ASSRESP' ,   --table_name
											rec_cur_user_resp.RECORD_ID,  --table_id
											'INACTIVE_DATE',  --column_name
											rec_cur_user_resp.INACTIVE_DATE, --column_value
											'E',                       --message_type
											v_message                   --message_text
											);
				v_flag_erreur := TRUE;
			
				UPDATE DKA_SFNDUSER_ASSRESP
				 SET STATUT = 'REJECTED'
			   WHERE CURRENT OF cur_user_resp;
			   
			  END;
		   END IF; 


		   IF (rec_cur_user_resp.USER_NAME IS not NULL) and (rec_cur_user_resp.RESPONSIBILITY IS not NULL) and ( rec_cur_user_resp.INACTIVE_DATE IS NULL ) THEN
			BEGIN
				  v_user :=null;
				  select user_id into v_user
					from fnd_user
				   where user_name = rec_cur_user_resp.USER_NAME
					 and nvl(end_date, sysdate) >= sysdate ;
					 
			   EXCEPTION
				WHEN OTHERS THEN
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_12');
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													'DKA_SFNDUSER_ASSRESP', --prog_name
													'USER_NAME',               --source
													'DKA_SFNDUSER_ASSRESP' ,   --table_name
													rec_cur_user_resp.RECORD_ID,  --table_id
													'USER_NAME',  --column_name
													rec_cur_user_resp.USER_NAME, --column_value
													'E',                       --message_type
												   v_message                   --message_text
													);
							v_flag_erreur := TRUE;
					
					UPDATE DKA_SFNDUSER_ASSRESP
					 SET STATUT = 'REJECTED'
					WHERE CURRENT OF cur_user_resp;
			  END;
			  IF v_user is not null THEN
				BEGIN
					v_RESPONSIBILITY_ID := null;
					SELECT ret.responsibility_ID into v_RESPONSIBILITY_ID
					  FROM fnd_user user1
						 , FND_USER_RESP_GROUPS_DIRECT user_resp
						 , fnd_responsibility_tl ret 
					 WHERE user1.user_id = user_resp.user_id
					   AND user_resp.responsibility_id = ret.responsibility_id
					   AND user_resp.end_date IS NULL
					   AND user1.user_name = rec_cur_user_resp.USER_NAME
					   and language= 'F'
					   and ret.responsibility_name = rec_cur_user_resp.RESPONSIBILITY
					   --and user_resp.start_date <= rec_cur_user_resp.INACTIVE_DATE
					   ;

				EXCEPTION
				WHEN OTHERS THEN
					null;
				end;
				if v_RESPONSIBILITY_ID is not null THEN
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_13');
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
											'DKA_SFNDUSER_ASSRESP', --prog_name
											'RESPONSIBILITY',               --source
											'DKA_SFNDUSER_ASSRESP' ,   --table_name
											rec_cur_user_resp.RECORD_ID,  --table_id
											'RESPONSIBILITY',  --column_name
											rec_cur_user_resp.RESPONSIBILITY, --column_value
											'E',                       --message_type
											v_message                   --message_text
											);
					 v_flag_erreur := TRUE;
					
					  UPDATE DKA_SFNDUSER_ASSRESP
					   SET STATUT = 'REJECTED'
					WHERE CURRENT OF cur_user_resp;
			   
			  END IF;
			END IF;
		   END IF; 	   	   
		   
		   IF NOT v_flag_erreur THEN
				UPDATE DKA_SFNDUSER_ASSRESP
				   SET STATUT = 'VALIDATED'
				 WHERE CURRENT OF cur_user_resp;    
			END IF ;
		EXCEPTION
			WHEN others THEN
				fnd_file.put_line(fnd_file.log,
								  'VALIDATION ||' || rec_cur_user_resp.USER_NAME  ||'/' ||rec_cur_user_resp.RESPONSIBILITY || '| erreur: ' || sqlerrm);
		  
				ROLLBACK;
		  
				UPDATE DKA_SFNDUSER_ASSRESP
				   SET STATUT = 'REJECTED'
				 WHERE CURRENT OF cur_user_resp;
		END;
	  END LOOP;

	  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data_group');

	  COMMIT; 

	EXCEPTION
	  WHEN OTHERS THEN
		p_retcode := 2;
		p_errbuf  := 'validate_data_group : ' || SQLERRM;
		Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
		Fnd_File.put_line(Fnd_File.LOG,
						  TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
						  'Fin de la procédure validate_data_group : EXCEPTION OTHERS ');
	END validate_data_group;


	 /*
	 *************************************************************************
	 * PROCEDURE NAME : validate_data
	 * 
	 * DESCRIPTION
	 *  Procédure d'insertion dans les tables finales
	 *
	 * PARAMETERS
	 * ==========
	 * NAME               DESCRIPTION
	.* -----------------  ------------------------------------------------------
	 * p_errbuf          Retour de message éventuel
	 * p_retcode         Statut du traitement en sortie
	 * 
	 ************************************************************************
	 */
	--------------------------------------------------------------------------------------
	PROCEDURE validate_data(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

	  v_person_id                   NUMBER;
	  v_code_site_four              VARCHAR2(100);
	  v_org_id                      NUMBER;
	  v_pers_id                     NUMBER;
	  v_rcv_header_id               NUMBER;
	  v_message                     VARCHAR2(500);
	  v_flag_erreur                 BOOLEAN := FALSE;
	  v_flag_erreur_trans           BOOLEAN := FALSE;
	  v_ship_to_organization_id     NUMBER;
	  v_code_site_four1             VARCHAR2(240);
	  v_receive_trans_id            NUMBER;
	  v_ship_to_location            VARCHAR2(100); -- OBE
	  v_vendor_site_code            VARCHAR2(25); -- OBE
	  v_vendor_site_code_2          VARCHAR2(25); -- OBE
	  v_location_code               VARCHAR2(60); -- OBE
	  v_deliver_to_location         VARCHAR2(60); -- OBE 
	  v_deliver_to_location_id      NUMBER;       -- RBE
	  v_DELIVER_TO_PERSON           VARCHAR2(240);
	  e_err_org_not_exist           EXCEPTION;
	  v_Multi_receipt               NUMBER; -- SELO
	  v_org_ok                      Number; -- SELO
	  v_vendor_id                   Number; -- SELO
	  v_start_date                  DATE;
	  V_RECEIPT_DATE                DATE;
	  v_CMD_ID                      Number;
	  v_vendor_site_id              Number;
	  v_LIGNE_ID                    Number;
	  v_reject                      Number;
	  vs_ship_to_Org_Id             Number; 
	  V_SHIPMENT_HEADER_ID          Number;
	  vs_vendor_id                  Number;
	  vs_vendor_site_id             Number;
	  vs_packing_slip               VARCHAR2(60);
	  v_rct_quantity                Number;
	  v_shipment_line_id            Number;
	  v_TRANSACTION_ID              Number;
	  v_PARENT_TRANSACTION_ID       Number; 
	  V_UNIT_OF_MEASURE             VARCHAR2(60);
	  v_LINE_LOCATION_ID            Number; 
	  v_PO_DISTRIBUTION_ID          Number; 
	  -- Cursor
	  CURSOR cur_user_resp IS
		SELECT *
		  FROM dka.DKA_SFNDUSER_ASSRESP dsa
		 WHERE STATUT  = 'NEW'
		 ORDER BY record_id
		   ;
	BEGIN

	  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début validate_data');
	  Fnd_File.put_line(Fnd_File.LOG,
						TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
						'Validation des données dans les tables spécifiques : ');

		 FOR rec_user_resp IN cur_user_resp LOOP
			 validate_data_group(p_Errbuf , p_retcode, rec_user_resp.RECORD_ID) ;
		 END LOOP;
	   
	  Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin validate_data');

	  COMMIT; 

	EXCEPTION
	  WHEN OTHERS THEN
		p_retcode := 2;
		p_errbuf  := 'validate_data : ' || SQLERRM;
		Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
		Fnd_File.put_line(Fnd_File.LOG,
						  TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
						  'Fin de la procédure validate_data : EXCEPTION OTHERS ');
	END validate_data;



	 /*
	 *************************************************************************
	 * PROCEDURE NAME : import_data
	 * 
	 * DESCRIPTION
	 *  Procédure d'insertion dans les tables d'interfaces
	 *
	 * PARAMETERS
	 * ==========
	 * NAME               DESCRIPTION
	 * -----------------  -----------------------------------------------------
	 * p_errbuf          Retour de message éventuel
	 * p_retcode         Statut du traitement en sortie
	 * 
	 ************************************************************************
	 */
	PROCEDURE import_data(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
	  v_person_id              NUMBER;
	  v_code_site_four         VARCHAR2(100);
	  v_org_id                 NUMBER;
	  v_pers_id                NUMBER;
	  v_rcv_header_id          NUMBER;
	  v_transaction_id         NUMBER;
	  v_cpt                    NUMBER := 0;
	  v_employee_id            NUMBER; -- SELO
	  v_inc_group              NUMBER := 0;
      i                        NUMBER := 0;
	  V_RESPONSIBILITY_KEY     VARCHAR2(100);
	  V_APPLICATION_SHORT_NAME VARCHAR2(100);
	  V_APPLICATION_ID         NUMBER;
	  v_RESPONSIBILITY_ID      number;
	  cv_line                  VARCHAR2(300);
	  v_end_date               date;
	  v_start_date             date; 
	  v_message                VARCHAR2(500);
	  V_security_group_id      FND_RESPONSIBILITY.data_group_id%TYPE; 
	  g_user                   NUMBER        := fnd_profile.value('USER_ID');
	  -- Curseur des receptions
	  CURSOR cur_USER_RESP IS
		SELECT *
		  FROM DKA_SFNDUSER_ASSRESP
		 WHERE 1 = 1
		   AND STATUT = 'VALIDATED';
	  CURSOR cur_USER_RESP_ATT is
	    SELECT  distinct dii.v_user_id  user_id
		                ,dii.user_name  user_name 
		FROM   fnd_user user1
			  ,fnd_responsibility_tl ret 
              ,DKA_SFNDUSER_ASSRESP dii
		 WHERE STATUT = 'COMPLETE'
		 AND NVL(user1.END_DATE, sysdate) >= sysdate 
		 AND user1.user_name = dii.user_name
         and ret.responsibility_name = dii.responsibility
		 and language = 'F'
         and not exists( select responsibility_id 
                                              from FND_USER_RESP_GROUPS_DIRECT 
                                              where  NVL(END_date,sysdate + 1) > sysdate
                                              and user1.user_id = user_id)
	     and not exists ( select dsa.v_user_id 
                          from DKA_SFNDUSER_ASSRESP dsa 
						  where dii.user_name = dsa.user_name
                          and   dsa.statut !=  'COMPLETE'
              );
			
	 
	BEGIN

		-- Boucle
		FOR rec_cur_USER_RESP IN cur_USER_RESP LOOP
			IF (rec_cur_USER_RESP.USER_NAME is not NULL) and (rec_cur_USER_RESP.responsibility is null) and (rec_cur_USER_RESP.INACTIVE_DATE is not null) THEN
			   BEGIN
				UPDATE FND_USER
				  SET END_DATE=rec_cur_USER_RESP.INACTIVE_DATE
					 , last_update_date = sysdate
					 , last_updated_by = g_user
				 where user_id = rec_cur_USER_RESP.v_user_id;
				 
				UPDATE DKA_SFNDUSER_ASSRESP
				   SET STATUT = 'COMPLETE'
				 where record_id=rec_cur_USER_RESP.record_id;
			   
			   EXCEPTION
				  WHEN OTHERS THEN

					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_14', 'MESSAGE_ERREUR_ORACLE' , sqlerrm);
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													'DKA_SFNDUSER_ASSRESP', --prog_name
													'INACTIVE_DATE',               --source
													'DKA_SFNDUSER_ASSRESP' ,   --table_name
													rec_cur_user_resp.RECORD_ID,  --table_id
													'INACTIVE_DATE',  --column_name
													rec_cur_user_resp.INACTIVE_DATE, --column_value
													'E',                       --message_type
												   v_message                   --message_text
													);
				 
					 UPDATE DKA_SFNDUSER_ASSRESP
						SET STATUT = 'REJECTED'
					  where record_id=rec_cur_USER_RESP.record_id;          				  
					  
				END;
			
			END IF;

			IF (rec_cur_USER_RESP.USER_NAME is not NULL) and (rec_cur_USER_RESP.responsibility is not null) and (rec_cur_USER_RESP.INACTIVE_DATE is not null) THEN
			  
					 SELECT ret.responsibility_ID into v_RESPONSIBILITY_ID
					   FROM fnd_responsibility_tl ret 
					  where ret.responsibility_name = rec_cur_user_resp.RESPONSIBILITY
						and language='F';
						
				   SELECT R1.RESPONSIBILITY_KEY,
						  R1.application_id,
						  R1.data_group_id ,
						  furgd.start_date
					 INTO V_RESPONSIBILITY_KEY,
						  V_APPLICATION_ID,
						  V_security_group_id,
						  v_start_date					  
					 FROM FND_RESPONSIBILITY_TL B, 
						  FND_RESPONSIBILITY R1,
						  fnd_user_resp_groups_direct furgd,
						  fnd_application  fa
					WHERE 1 = 1
					  AND fa.APPLICATION_ID = R1.APPLICATION_ID
					  AND B.RESPONSIBILITY_ID = R1.RESPONSIBILITY_ID
					  AND B.APPLICATION_ID = R1.APPLICATION_ID
					  AND R1.RESPONSIBILITY_ID = v_RESPONSIBILITY_ID
					  AND furgd.user_id = rec_cur_USER_RESP.v_user_id
					  AND R1.application_id = furgd.responsibility_application_id
					  AND R1.responsibility_id = furgd.responsibility_id				  
					  and language='F';	

					BEGIN
					FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT ( user_id => rec_cur_USER_RESP.v_user_id
																,responsibility_id => v_RESPONSIBILITY_ID
																,responsibility_application_id => V_APPLICATION_ID
																,security_group_id => V_security_group_id
																,start_date => v_start_date
																,end_date => rec_cur_USER_RESP.INACTIVE_DATE
																,description => V_RESPONSIBILITY_KEY
					);
					
					UPDATE DKA_SFNDUSER_ASSRESP
					   SET STATUT = 'COMPLETE'
					 where record_id=rec_cur_USER_RESP.record_id;	
					 
					EXCEPTION
					WHEN OTHERS
					THEN
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_14', 'MESSAGE_ERREUR_ORACLE' , sqlerrm);
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													'DKA_SFNDUSER_ASSRESP', --prog_name
													'INACTIVE_DATE',               --source
													'DKA_SFNDUSER_ASSRESP' ,   --table_name
													rec_cur_user_resp.RECORD_ID,  --table_id
													'INACTIVE_DATE',  --column_name
													rec_cur_user_resp.INACTIVE_DATE, --column_value
													'E',                       --message_type
												   v_message                   --message_text
													);
				 
					 UPDATE DKA_SFNDUSER_ASSRESP
						SET STATUT = 'REJECTED'
					  where record_id=rec_cur_USER_RESP.record_id;  
					END;				  
				
			
			END IF;
			
			IF (rec_cur_USER_RESP.USER_NAME is not NULL) and (rec_cur_USER_RESP.responsibility is not null) and (rec_cur_USER_RESP.INACTIVE_DATE is null) THEN   
				cv_line := 'Utilisateur: '|| rec_cur_USER_RESP.USER_NAME||'/ Responsabilité: '||rec_cur_USER_RESP.responsibility||'/ Date de validité' || rec_cur_USER_RESP.INACTIVE_DATE;
				SELECT ret.responsibility_ID into v_RESPONSIBILITY_ID
				  FROM fnd_responsibility_tl ret 
				 where ret.responsibility_name = rec_cur_user_resp.RESPONSIBILITY
				   and language='F';
				
				BEGIN
				v_end_date := null;
				 select END_DATE into v_end_date
				   from FND_USER_RESP_GROUPS_DIRECT
				  where user_id = rec_cur_USER_RESP.v_user_id
					and RESPONSIBILITY_ID = v_RESPONSIBILITY_ID;
				EXCEPTION
				  WHEN OTHERS THEN
					null;
				END;
				
				IF v_end_date is not null THEN
				
				   SELECT R1.RESPONSIBILITY_KEY,
						  R1.application_id,
						  R1.data_group_id ,
						  furgd.start_date
					 INTO V_RESPONSIBILITY_KEY,
						  V_APPLICATION_ID,
						  V_security_group_id,
						  v_start_date					  
					 FROM FND_RESPONSIBILITY_TL B, 
						  FND_RESPONSIBILITY R1,
						  fnd_user_resp_groups_direct furgd,
						  fnd_application  fa
					WHERE 1 = 1
					  AND fa.APPLICATION_ID = R1.APPLICATION_ID
					  AND B.RESPONSIBILITY_ID = R1.RESPONSIBILITY_ID
					  AND B.APPLICATION_ID = R1.APPLICATION_ID
					  AND R1.RESPONSIBILITY_ID = v_RESPONSIBILITY_ID
					  AND furgd.user_id = rec_cur_USER_RESP.v_user_id
					  AND R1.application_id = furgd.responsibility_application_id
					  AND R1.responsibility_id = furgd.responsibility_id				  
					  and language='F';	

					BEGIN
						FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT ( user_id => rec_cur_USER_RESP.v_user_id
																	,responsibility_id => v_RESPONSIBILITY_ID
																	,responsibility_application_id => V_APPLICATION_ID
																	,security_group_id => V_security_group_id
																	,start_date => v_start_date
																	,end_date => NULL
																	,description => V_RESPONSIBILITY_KEY
						);
					
						UPDATE DKA_SFNDUSER_ASSRESP
						   SET STATUT = 'COMPLETE'
						 where record_id=rec_cur_USER_RESP.record_id;	
					EXCEPTION
					WHEN OTHERS
					THEN
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_14', 'MESSAGE_ERREUR_ORACLE' , sqlerrm);
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													'DKA_SFNDUSER_ASSRESP', --prog_name
													'INACTIVE_DATE',               --source
													'DKA_SFNDUSER_ASSRESP' ,   --table_name
													rec_cur_user_resp.RECORD_ID,  --table_id
													'INACTIVE_DATE',  --column_name
													rec_cur_user_resp.INACTIVE_DATE, --column_value
													'E',                       --message_type
												   v_message                   --message_text
													);
				 
					 UPDATE DKA_SFNDUSER_ASSRESP
						SET STATUT = 'REJECTED'
					  where record_id=rec_cur_USER_RESP.record_id;  
					END;
		
				ELSE
				
				
					 BEGIN
					   SELECT R1.RESPONSIBILITY_KEY,
							  fa.APPLICATION_SHORT_NAME
						 INTO V_RESPONSIBILITY_KEY,
							  V_APPLICATION_SHORT_NAME		  
						 FROM FND_RESPONSIBILITY_TL B, 
							  FND_RESPONSIBILITY R1,
							  fnd_application  fa
						WHERE 1 = 1
						  AND fa.APPLICATION_ID = R1.APPLICATION_ID
						  AND B.RESPONSIBILITY_ID = R1.RESPONSIBILITY_ID
						  AND B.APPLICATION_ID = R1.APPLICATION_ID
						  AND R1.RESPONSIBILITY_ID = v_RESPONSIBILITY_ID
						  and language='F';
					   EXCEPTION
					   WHEN OTHERS THEN
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_14', 'MESSAGE_ERREUR_ORACLE' , sqlerrm);
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													'DKA_SFNDUSER_ASSRESP', --prog_name
													'INACTIVE_DATE',               --source
													'DKA_SFNDUSER_ASSRESP' ,   --table_name
													rec_cur_user_resp.RECORD_ID,  --table_id
													'INACTIVE_DATE',  --column_name
													rec_cur_user_resp.INACTIVE_DATE, --column_value
													'E',                       --message_type
												   v_message                   --message_text
													);
				 
					 UPDATE DKA_SFNDUSER_ASSRESP
						SET STATUT = 'REJECTED'
					  where record_id=rec_cur_USER_RESP.record_id;     
					 END;
					 BEGIN
					   fnd_user_pkg.addresp (rec_cur_USER_RESP.USER_NAME,V_APPLICATION_SHORT_NAME,V_RESPONSIBILITY_KEY,'STANDARD',rec_cur_USER_RESP.RESPONSIBILITY,SYSDATE,null); 
					   UPDATE DKA_SFNDUSER_ASSRESP
						  SET STATUT = 'COMPLETE'
						where record_id=rec_cur_USER_RESP.record_id;
					 EXCEPTION
					   WHEN OTHERS THEN
					v_message :=dka_tools_pkg.get_message('DKA','DKA_SFNDUSER_14', 'MESSAGE_ERREUR_ORACLE' , sqlerrm);
					--Add_Message(rec_cur_user_resp.RECEIPT_NUM, rec_cur_user_resp.RECORD_ID, v_message, rec_cur_user_resp.receipt_num);
					DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
													'DKA_SFNDUSER_ASSRESP', --prog_name
													'INACTIVE_DATE',               --source
													'DKA_SFNDUSER_ASSRESP' ,   --table_name
													rec_cur_user_resp.RECORD_ID,  --table_id
													'INACTIVE_DATE',  --column_name
													rec_cur_user_resp.INACTIVE_DATE, --column_value
													'E',                       --message_type
												   v_message                   --message_text
													);
				 
					 UPDATE DKA_SFNDUSER_ASSRESP
						SET STATUT = 'REJECTED'
					  where record_id=rec_cur_USER_RESP.record_id;     
					 END;
				END IF;
			END IF;
			 
		END LOOP;
		COMMIT;
		--debut sha
		FOR rec_cur_USER_RESP_ATT IN cur_USER_RESP_ATT LOOP
		    i := i + 1; 
		    BEGIN
				UPDATE FND_USER
				  SET END_DATE          =sysdate
					 , last_update_date = sysdate
					 , last_updated_by  = g_user
				 where user_id = rec_cur_USER_RESP_ATT.user_id;
				 
		    END;
			 liste_user(i).user_name      := rec_cur_USER_RESP_ATT.user_name;
	    END LOOP;
		-- fin sha
		Fnd_File.put_line(Fnd_File.LOG, TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin import_data');
		COMMIT; 

	EXCEPTION
	  WHEN OTHERS THEN
		p_retcode := 2;
		p_errbuf  := 'import_data : ' || SQLERRM;
		Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
		Fnd_File.put_line(Fnd_File.LOG,
						  TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
						  'Fin de la procédure import_data : EXCEPTION OTHERS ');
		ROLLBACK; 

	END import_data;

	
	------------------------------------------------------
	/*
	 *************************************************************************
	 * PROCEDURE NAME : Launch_Loader
	 *
	 * DESCRIPTION
	 *  Procédure de lancement du programme de chargement dans la table spécifique
	 *
	 * PARAMETERS
	 * ==========
	 * NAME               DESCRIPTION
	.* -----------------  ------------------------------------------------------
	 * p_directory       Répertoire du fichier
	 * p_file_name       Nom du fichier à charger
	 * p_errbuf          Retour de message éventuel
	 * p_retcode         Statut du traitement en sortie
	 *
	 ************************************************************************
	 */
	  PROCEDURE Launch_Loader(p_Errbuf            OUT VARCHAR2,
							  p_retcode           OUT NUMBER,
							  p_fichier           IN VARCHAR2
							  )
	  IS
			v_phase                  VARCHAR2 (100);
			v_status                 VARCHAR2 (100);
			v_dev_phase              VARCHAR2 (100);
			v_dev_status             VARCHAR2 (100);
			v_message                VARCHAR2 (500);
			b_result                  BOOLEAN;

	  BEGIN
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_Loader');
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
											 'Lancement de chargement du fichier dans la table d''interface spécifique : ');
			Fnd_File.put_line (Fnd_File.output,  CHR(10));										 
			Fnd_File.put_line (Fnd_File.OUTPUT, 'CHARGEMENT DU FICHIER :');
			Fnd_File.put_line (Fnd_File.OUTPUT, '-----------------------');		
													 

			------------------------------------------------------
			-- Lancement du traitement de chargement du fichier --
			------------------------------------------------------
			-- Positionnement des options d'impression
			b_result := fnd_request.set_print_options(printer => gv_printer,
													  copies => g_number_of_copies);
			-- Lancement du traitement
			g_loader_request_id         := Fnd_Request.submit_request (
																	   'DKA'                            -- APPL
																	  ,'DKA_SFNDUSER_ASSRESP_LOADER' -- PROG
																	  ,NULL                             -- PROGRAM_NAME
																	  ,NULL                             -- START
																	  ,FALSE                            -- SUB_REQUEST
																	  ,p_fichier
																	  );

			IF g_loader_request_id = 0
			THEN
				p_retcode    := 2;
				fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de chargement du fichier a échoué' || CHR(10) ||
												'PROGRAMME  : DKA_SFNDUSER_ASSRESP_LOADER'
												);
				delete from DKA_SFNDUSER_ASSRESP where statut ='NEW';
				commit;
				--Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de chargement du fichier a échoué');
			ELSE
				COMMIT;
				Fnd_File.put_line(Fnd_File.LOG, '=> LOAD REQUEST ID= ' || g_loader_request_id);
				Fnd_File.put_line (Fnd_File.OUTPUT, '. Numéro du traitement de chargement : ' || g_loader_request_id);
				--Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de chargement du fichier : ' || g_loader_request_id);

				-- Attente de la fin du traitement
				IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
				THEN
					p_Errbuf  := v_Message;
					Fnd_file.put_line(Fnd_file.log, 'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' || CHR(10) ||
													'MESSAGE : ' || v_Message || CHR(10) );
				END IF;

				IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
				THEN
					Fnd_File.put_line(Fnd_File.LOG, 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
					Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_dev_phase || '/' || v_dev_status);
					
					
				ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
				THEN
					Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de chargement en warning '|| g_loader_request_id);
					p_retcode    := 1;

				ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
				THEN
					p_retcode := 2;
					p_Errbuf  := 'ERREUR : Fin anormale du traitement de chargement : '||v_Message;

					fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de chargement '|| g_loader_request_id  || CHR(10) ||
													'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
													'MESSAGE : ' || v_message || CHR(10) );
					Fnd_File.put_line(Fnd_File.OUTPUT, '. Statut de fin : ' || v_dev_phase || '/' || v_dev_status);												
					Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de chargement '||g_loader_request_id);
				END IF;

			END IF;

		
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_Loader');

	  EXCEPTION
			WHEN OTHERS
			THEN
				p_retcode   := 2;
				p_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
				Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
				Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
	  END Launch_Loader;

	 /*
	 *************************************************************************
	 * PROCEDURE NAME : Bilan
	 * 
	 * DESCRIPTION
	 *  Procédure de génération du bilan du traitement d'interface
	 *
	 * PARAMETERS
	 * ==========
	 * NAME                 DESCRIPTION
	.* -------------------- ---------------------------------------------------
	 * p_errbuf            Retour de message éventuel
	 * p_retcode           Statut du traitement en sortie
	 ************************************************************************
	 */
	  PROCEDURE Report_Bilan(p_statut              IN NUMBER) 
	  IS
		
		CURSOR cur_err_validate is
		select table_id, dii.USER_NAME, dii.RESPONSIBILITY, dii.INACTIVE_DATE, dpm.message_text
		  from dka_program_messages dpm,
			   DKA_SFNDUSER_ASSRESP dii
		 where prog_name ='DKA_SFNDUSER_ASSRESP'
		   and table_id=dii.record_id
		   order by TABLE_ID;	


		CURSOR cur_User is
	   SELECT   distinct dii.user_name  USER_NAME
				  FROM fnd_user user1
					 , fnd_responsibility_tl ret 
                     , DKA_SFNDUSER_ASSRESP dii
				 WHERE STATUT = 'COMPLETE'
				   AND NVL(user1.END_DATE, sysdate) >= sysdate 
				   AND user1.user_name = dii.user_name
                   and ret.responsibility_name = dii.responsibility
				   and language = 'F'
                   and not exists( select responsibility_id 
                                                       from FND_USER_RESP_GROUPS_DIRECT 
                                                       where  NVL(END_date,sysdate + 1) > sysdate
                                                       and user1.user_id = user_id
                                                       )
                 and not exists ( select dsa.v_user_id 
                 from DKA_SFNDUSER_ASSRESP dsa where 
                 dii.user_name = dsa.user_name
                 and dsa.statut !=  'COMPLETE'
                       );
		
		cv_line    VARCHAR2(500);
		V_STATUT   VARCHAR2(15);
		c_user     number ;
		c_anomalie number ;
	  BEGIN

			---cv_line    := '----------------------------------------------------------------------------------';

	        c_user := 0;
			c_anomalie := 0;
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

			--------------------    
			-- Initialisation --
			--------------------          
	  
			BEGIN                          
				SELECT count(1)
				  INTO g_summary.rejected_header_rows
				  FROM DKA_SFNDUSER_ASSRESP
				 WHERE STATUT = 'REJECTED'
				;
				
				SELECT count(1)
				  INTO g_summary.loaded_header_rows
				  FROM DKA_SFNDUSER_ASSRESP;

				SELECT count(1)
				  INTO g_summary.rec_final_rows
				  FROM DKA_SFNDUSER_ASSRESP 
				 WHERE STATUT = 'COMPLETE';            
						
				
				select decode(p_statut, 0, 'Normal', 1, 'Avertissement', 2, 'Erreur') into v_statut
				  from dual;
			EXCEPTION
			  when others then
				null;
			END;		  
			Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
			Fnd_File.put_line (Fnd_File.output, 'BILAN :');  
			Fnd_File.put_line (Fnd_File.output, '-------'); 
			
			
			fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements à traiter                                          : '||TO_CHAR(g_summary.loaded_header_rows));
			fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements rejetés                                            : '|| TO_CHAR(g_summary.rejected_header_rows));		
			fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre d''enregistrements traités avec succès :                              : '||TO_CHAR(g_summary.rec_final_rows));		
			 
			Fnd_File.put_line (Fnd_File.output, CHR(10));
			Fnd_File.put_line (Fnd_File.output, 'LISTE DES ANOMALIES : ');
			Fnd_File.put_line (Fnd_File.output, '---------------------'); 
			cv_line := 'Utilisateur          Responsabilité                  Date désactivation   Message d''erreur';
			Fnd_File.put_line (Fnd_File.output, cv_line);
			cv_line := '-----------          --------------                  ------------------   -----------------';
			Fnd_File.put_line (Fnd_File.output, cv_line);

			FOR rec_cur_err_validate IN cur_err_validate LOOP		
                c_anomalie := c_anomalie + 1;
				cv_line := RPAD(nvl(rec_cur_err_validate.USER_NAME,' '),19,' ') ||'  '||RPAD(NVL(rec_cur_err_validate.responsibility,' '),30,' ') ||'  ' || RPAD(NVL(to_char(rec_cur_err_validate.INACTIVE_DATE,'dd/mm/yyyy'),' '),19,' ') ||'  ' || rec_cur_err_validate.message_text ;
			    Fnd_File.put_line (Fnd_File.output, cv_line);
			END LOOP;	
			if c_anomalie = 0 THEN
            Fnd_File.put_line (Fnd_File.output, 'Aucun rejet.  ');
			
            END IF ; 
			
			Fnd_File.put_line (Fnd_File.output, CHR(10));
			Fnd_File.put_line (Fnd_File.output, 'LISTE DES UTILISATEURS DESACTIVES CAR N''AYANT PLUS DE RATTACHEMENT ACTIF : ');
			Fnd_File.put_line (Fnd_File.output, '--------------------------------------------------------------------------- ');
			Fnd_File.put_line (Fnd_File.output, 'Utilisateur ');
			Fnd_File.put_line (Fnd_File.output, '----------- ');
			IF liste_user.count > 0 
            THEN
               
	             FOR i IN liste_user.first..liste_user.last 
                 LOOP
	             Fnd_File.put_line (Fnd_File.output, liste_user(i).USER_NAME);   
	             END LOOP;

	        else
            Fnd_File.put_line (Fnd_File.output, 'Aucun utilisateur n''a été désactivé. ');
            END IF ; 			
			fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');  

	 
	  END Report_Bilan; 

	
	/* *************************************************************************
	 * PROCEDURE NAME : purge_data
	 *
	 * DESCRIPTION
	 *  Procédure de purge des données
	 *
	 * PARAMETERS
	 * ==========
	 * NAME               DESCRIPTION
	 * -----------------  ------------------------------------------------------
	 *
	 *************************************************************************/
	  PROCEDURE purge_data(p_Errbuf            OUT VARCHAR2,
						   p_retcode           OUT NUMBER
								  ) 
	  IS

	  BEGIN




		 -- On supprime les enregistrements
		 --RG304
		 Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_SFNDUSER_ASSRESP ' );
		 DELETE FROM DKA_SFNDUSER_ASSRESP ;
		
		 
		
	  EXCEPTION
			WHEN OTHERS
			THEN
				p_retcode   := 2;
				p_errbuf    := 'PURGE_DATA : ' ||SQLERRM;
				Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
				Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
	  END purge_data;
	   
	 /*
	 *************************************************************************
	 * PROCEDURE NAME : main
	 * 
	 * DESCRIPTION
	 *  Procédure principale
	 *
	 * PARAMETERS
	 * ==========
	 * NAME              DESCRIPTION
	 * ----------------- ------------------------------------------------------
	 * p_errbuf          Retour de message éventuel
	 * p_retcode         Statut du traitement en sortie
	 ************************************************************************
	 */

	PROCEDURE main(
					p_Errbuf    IN OUT  VARCHAR2,
					p_retcode   OUT     NUMBER,
					p_fichier   IN      VARCHAR2--,
				  --  p_gl_date       IN VARCHAR2
				  )

	IS
	  v_errbuf                    VARCHAR2(2500);
	  v_retcode                   NUMBER;
	  Erreur_Programme            EXCEPTION;
	  error                       EXCEPTION;
	  v_current_program_unit      VARCHAR2(30);
	  p_reprise                   VARCHAR2(30); 
	  
	BEGIN

		  ----------------------------
		  -- PHASE D'INITIALISATION --
		  ----------------------------
		  
		  v_current_program_unit := 'main';
		  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'DEBUT DE L''INTERFACE'); 
		  
		  
		  Output_Header;
		
		  Request_parameters;   
		  
		  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE D''INITIALISATION'); 
		  
		  v_errbuf  := NULL;
		  v_retcode := 0;
		  
		  Init(v_errbuf, v_retcode, p_reprise);  -- SELO
		  
		  IF v_retcode = 2 
		  THEN
			  p_Errbuf  := v_errbuf;
			  p_retcode := v_retcode;
			  RAISE Erreur_Programme;
		  END IF;       
		   
		  ------------------------------------------
		  -- PHASE DE PURGE DES ANCIENNES DONNEES  --
		  -------------------------------------------
		  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PURGE DES DONNEES'); 
		  purge_data(v_errbuf,
						v_retcode
					   );
		  IF v_retcode = 2 
		  THEN
			  p_Errbuf  := v_errbuf;
			  p_retcode := v_retcode;
			  RAISE Erreur_Programme;
		  END IF; 
		  
		  
		  
		  IF g_summary.reprise_flag = 'N' THEN
	   
			------------------------------------
			-- PHASE DE CHARGEMENT DU FICHIER --
			------------------------------------ 
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'PHASE DE CHARGEMENT DU FICHIER'); 
		  
		  
			-- Lancement du programme de chargement
			Launch_Loader(v_errbuf,
						  v_retcode,
						  p_fichier
						 );
			IF v_retcode = 2 
			  THEN
			  RAISE Erreur_Programme;
			END IF;
	   
		  ELSE
			null; --SELO
		  END IF;
		  validate_data(v_errbuf,
						v_retcode
					   );
		  IF v_retcode = 2 
		  THEN
			  RAISE Erreur_Programme;
		  END IF;
		  
		  -- Lancement de l'insertion des données
		  import_data( v_errbuf,
					   v_retcode
					   );
		  IF v_retcode = 2 
		  THEN
			  RAISE Erreur_Programme;
		  END IF;
		  
			-- bilan
		  Report_Bilan(p_retcode); 	  
					 
		  ---------------------------------------
		  -- PHASE DE FIN DU TRAITEMENT MAITRE --
		  ---------------------------------------
		  IF p_retcode = 2
		  THEN
			 p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
		  ELSIF (g_summary.rejected_header_rows > 0 OR g_summary.rejected_io_rows > 0 OR g_summary.warning_flag = 'Y')
		  THEN
			 p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
			 p_retcode := 1;
		  ELSIF (g_summary.loaded_header_rows = 0 AND g_summary.loaded_transaction_rows = 0 AND g_summary.reprise_flag = 'N')
		  THEN
			 p_errbuf := 'ATTENTION : Aucun enregistrement chargé.';
			 p_retcode := 1;
		  ELSE 
			 p_errbuf := 'Fin normale du traitement - Aucun rejet.';
			 p_retcode := 0;
		  END IF;

		  
		  COMMIT;
		  


		  
		  Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
		  Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf||CHR(10));
		  output_end;
		  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');       


	  EXCEPTION
			WHEN Erreur_Programme THEN
				p_retcode   := 2;
				p_errbuf    := v_errbuf;
				Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
				Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);
				Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
				Fnd_File.put_line (Fnd_File.OUTPUT, '==> Fin de la procédure '||v_current_program_unit||' : EXCEPTION Erreur_Traitement ');        
		   WHEN OTHERS 
		   THEN
			   fnd_concurrent.af_rollback;
			   p_retcode := 2;
			   Fnd_File.put_line (Fnd_File.Log,'Erreur technique sur le composant   : '||'DKA_SFNDUSER_ASSRESP_PKG.' || v_current_program_unit||CHR(10)||'A retourné     : '||SQLERRM);
			   Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
			   p_errbuf := SQLERRM;
	  END main; 

	------------------------------------------------------
	END DKA_SFNDUSER_ASSRESP_PKG;
	  
	  
  
	/
	SHOW ERRORS;

	EXIT
	  
	