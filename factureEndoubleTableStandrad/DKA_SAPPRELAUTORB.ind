	create or replace PACKAGE BODY DKA_IPOFRS_IVALUA_PKG IS
	  
	--------------------------------------------------------------------------------
	-- $Id: DKA_IPOFRS_IVALUA_PKG.pkb  $
	-- Capgemini
	-- Projet           :
	-- Nom              : DKA_IPOFRS_IVALUA_PKG.pks
	-- Description      : Corps du package DKA_IPOFRS_IVALUA_PKG
	-- Auteur           : Saloua HA
	-- Date de création : 08/05/2020
	-- Commentaires     :
	---------------------------------------------------------------------------------------------------------------
    --- HISTORIQUE DES MODIFICATIONS
    --- Date       Qui Description
    --- ---------- --- --------------------------------------------------------------------------------------------
    --- 09/08/2021 ARA EDB303 - Gestion fonction achats sur Interface des fournisseurs
	--- 17/05/2022 ARA EDB330
	--------------------------------------------------------------------------------  
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- CONSTANTES ET VARIABLES PRIVEES
	--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		g_package                            VARCHAR2(30)  := 'DKA_IPOFRS_IVALUA_PKG';
		g_sqlerrm                            VARCHAR2(500) := NULL;
		g_retproc                            NUMBER        := 0;							      
		g_user_id                            NUMBER        := fnd_profile.value('USER_ID');
		g_login_id                           fnd_logins.login_id%type := fnd_global.login_id;
		g_org_id                             hr_all_organization_units.organization_id%TYPE;
		g_request_id                         NUMBER        := fnd_global.conc_request_id; 
		g_loader_request_id                  fnd_concurrent_requests.request_id%TYPE;
		g_import_request_id                  NUMBER        := fnd_global.conc_request_id;
		g_tempo                              NUMBER ;
		g_nb_entetes_traite                  NUMBER ;   
		g_nb_lignes_traite			         NUMBER ;  
		g_nb_homologation_traite			 NUMBER ;  
		g_nb_entetes_traite_succes           NUMBER ;   
		g_nb_lignes_traite_succes			 NUMBER ;    
		g_nb_homo_traite_succes		         NUMBER ;    
		g_nb_entetes_traite_rejected1        NUMBER ;   
		g_nb_lignes_traite_rejected1		 NUMBER ;  
		g_nb_homo_traite_rejected1	         NUMBER ;  
		g_nb_entetes_traite_rejected2        NUMBER ;   
		g_nb_lignes_traite_rejected2		 NUMBER ;  
		g_nb_homo_traite_rejected2	         NUMBER ;  
		 
	   
	/**************************************************************************
	 * PROCEDURE NAME : update_record_id
	 * 
	 * DESCRIPTION
	 *  Procédure de mise à jour du record_id
	 *
	 * PARAMETERS
	 * ==========
	 * NAME              DESCRIPTION
	.* ----------------- ------------------------------------------------------
	 * pv_errbuf         Retour de message éventuel
	 * pn_retcode        Statut du traitement en sortie
	 *
	 *************************************************************************/
	  PROCEDURE update_record_id (
									pv_errbuf    OUT      VARCHAR2,
									pn_retcode   OUT      NUMBER,
									p_request_id IN       NUMBER 
								  )
	  IS
	  
		cursor cur_entete (p_request_id NUMBER) IS (SELECT * FROM DKA_IPOFRS_ENTETES where LOADER_REQUEST_ID = p_request_id);
		cursor cur_ligne  (p_request_id NUMBER) IS (SELECT * FROM DKA_IPOFRS_LIGNES where LOADER_REQUEST_ID = p_request_id);
		cursor cur_homo   (p_request_id NUMBER) IS (SELECT * FROM DKA_IPOFRS_HOMOLOGATIONS where LOADER_REQUEST_ID = p_request_id);
		l_message   VARCHAR2(2000);
		
	  BEGIN
		FOR rec_entete in cur_entete(p_request_id) LOOP
				
				  UPDATE DKA_IPOFRS_REPORTING_ENTETES
				  SET    record_id         = rec_entete.record_id
					,    request_id        = g_request_id
				  WHERE  LOADER_REQUEST_ID = p_request_id
				  AND    line_num          = rec_entete.line_num;

				  UPDATE DKA_IPOFRS_HIST_ENTETES
				  SET    record_id         = rec_entete.record_id
					,    request_id        = g_request_id			  
				  WHERE  LOADER_REQUEST_ID = p_request_id
				  AND    line_num          = rec_entete.line_num;
			
		END LOOP cur_entete;
		
		  FOR rec_ligne in cur_ligne(p_request_id) LOOP
				
				  
				  UPDATE DKA_IPOFRS_REPORTING_LIGNES
				  SET    record_id         = rec_ligne.record_id
					,    request_id        = g_request_id			  
				  WHERE  LOADER_REQUEST_ID = p_request_id
				  AND    line_num          = rec_ligne.line_num;

				  UPDATE DKA_IPOFRS_HIST_LIGNES
				  SET    record_id         = rec_ligne.record_id
					,    request_id        = g_request_id			  
				  WHERE  LOADER_REQUEST_ID = p_request_id
				  AND    line_num          = rec_ligne.line_num;
			
		END LOOP cur_ligne;
		
		FOR rec_homo in cur_homo(p_request_id) LOOP
				  
				  UPDATE DKA_IPOFRS_REPORTING_HOMOLOG
				  SET    record_id         = rec_homo.record_id
					,    request_id        = g_request_id			  
				  WHERE  LOADER_REQUEST_ID = p_request_id
				  AND    line_num          = rec_homo.line_num;

				  UPDATE DKA_IPOFRS_HIST_HOMOLOGATIONS
				  SET    record_id         = rec_homo.record_id
					,    request_id        = g_request_id			  
				  WHERE  LOADER_REQUEST_ID = p_request_id
				  AND    line_num          = rec_homo.line_num;
			
		END LOOP cur_homo;
		
	  END update_record_id;
	  
	  /**************************************************************************
	 * PROCEDURE NAME : update_statut
	 * 
	 * DESCRIPTION
	 *  Procédure de mise à jour du statut
	 *
	 * PARAMETERS
	 * ==========
	 * NAME              DESCRIPTION
	.* ----------------- ------------------------------------------------------
	 * pv_errbuf         Retour de message éventuel
	 * pn_retcode        Statut du traitement en sortie
	 *
	 *************************************************************************/
	  PROCEDURE update_statut (
									pv_errbuf    OUT      VARCHAR2,
									pn_retcode   OUT      NUMBER
								  )
	  IS
	  
		cursor cur_entete  IS (SELECT * FROM DKA_IPOFRS_ENTETES where REQUEST_ID = g_request_id);
		cursor cur_ligne   IS (SELECT * FROM DKA_IPOFRS_LIGNES where REQUEST_ID = g_request_id);
		cursor cur_homo    IS (SELECT * FROM DKA_IPOFRS_HOMOLOGATIONS where REQUEST_ID = g_request_id);
		l_message   VARCHAR2(2000);
		
	  BEGIN
	 
				  UPDATE DKA_IPOFRS_REPORTING_ENTETES dire
				  SET  statut        = (SELECT statut 
										  FROM DKA_IPOFRS_ENTETES die
										 WHERE die.record_id = dire.record_id)
					   , request_id = g_request_id
				  WHERE dire.record_id IN (SELECT record_id 
											 FROM DKA_IPOFRS_ENTETES) ;
		
				  UPDATE DKA_IPOFRS_REPORTING_LIGNES dire
				  SET  statut        = (SELECT statut 
										  FROM DKA_IPOFRS_LIGNES die
										 WHERE die.record_id = dire.record_id)
					   , request_id = g_request_id
				  WHERE dire.record_id IN (SELECT record_id 
											 FROM DKA_IPOFRS_LIGNES) ;
		
				 UPDATE DKA_IPOFRS_REPORTING_HOMOLOG dire
				  SET  statut        = (SELECT statut 
										  FROM DKA_IPOFRS_HOMOLOGATIONS die
										 WHERE die.record_id = dire.record_id)
					   , request_id = g_request_id
				  WHERE dire.record_id IN (SELECT record_id 
											 FROM DKA_IPOFRS_HOMOLOGATIONS) ;	
		COMMIT;
	  END update_statut;
	/**************************************************************************
	 * PROCEDURE NAME : Delete_obsolete_records
	 * 
	 * DESCRIPTION
	 *  Procédure de suppression des enregistrements obsoletes en erreur
	 *
	 * PARAMETERS
	 * ==========
	 * NAME              DESCRIPTION
	.* ----------------- ------------------------------------------------------
	 * pv_errbuf         Retour de message éventuel
	 * pn_retcode        Statut du traitement en sortie
	 *
	 *************************************************************************/
	  PROCEDURE delete_obsolete_records (
										pv_errbuf    OUT      VARCHAR2,
										pn_retcode   OUT      NUMBER
										 )
	  IS
	  
	  BEGIN
		
		-- Initialisation des variables
		pv_errbuf  := NULL;
		pn_retcode := 0;
		
			-- Modification du statut des enregistrements obsolètes dans les tables reporting - RG 234
		update  DKA_IPOFRS_REPORTING_ENTETES  dire
		   SET  dire.STATUT     ='DELETED'
			,   request_id        = g_request_id	
		WHERE   dire.record_id  IN (select record_id 
									from DKA_IPOFRS_ENTETES die
												WHERE  die.statut           IN ('REJECTED1','REJECTED2')
												AND    die.NUM_FOURNISSEUR  IN (SELECT die1.NUM_FOURNISSEUR
																	FROM   DKA_IPOFRS_ENTETES die1
																	WHERE  die1.statut = 'NEW'
																	)
											);	
							
		update  DKA_IPOFRS_REPORTING_lignes  dirs
		SET     dirs.STATUT     ='DELETED'
		  ,     request_id        = g_request_id		
		WHERE   dirs.record_id  in (select record_id from DKA_IPOFRS_LIGNES dil
													  WHERE  dil.statut IN ('REJECTED1','REJECTED2')
													  AND    exists(SELECT 'x'
												  FROM DKA_IPOFRS_LIGNES dih1
												  WHERE dih1.statut = 'NEW'
												  AND dih1.NUM_FOURNISSEUR = dil.NUM_FOURNISSEUR
												  AND dih1.ID_IVALUA_SITE_FOURNISSEUR = dil.ID_IVALUA_SITE_FOURNISSEUR
												  )
									);
			update  DKA_IPOFRS_REPORTING_HOMOLOG  dirh
			   SET  dirh.STATUT ='DELETED'
				,   request_id        = g_request_id		
			WHERE  dirh.record_id in (select record_id 
									  FROM DKA_IPOFRS_HOMOLOGATIONS dih
									  WHERE   dih.statut IN ('REJECTED1','REJECTED2')
									  AND exists (SELECT 'x'
												  FROM DKA_IPOFRS_HOMOLOGATIONS dih1
												  WHERE dih1.statut = 'NEW'
												  AND dih1.NUM_FOURNISSEUR = dih.NUM_FOURNISSEUR
												  AND dih1.ID_IVALUA_SITE_FOURNISSEUR = dih.ID_IVALUA_SITE_FOURNISSEUR
												  AND dih1.PERIMETRE_HOMOLOGATION = dih.PERIMETRE_HOMOLOGATION
												  )
									  );
		   
			DELETE FROM DKA_PROGRAM_MESSAGES 
			WHERE PROG_NAME  = 'DKA_IPOFRS_IVALUA_PKG'
			;
			
			
			DELETE DKA_IPOFRS_ENTETES die
			WHERE  die.statut IN ('REJECTED1','REJECTED2')
			AND    die.NUM_FOURNISSEUR IN (SELECT die1.NUM_FOURNISSEUR
										   FROM   DKA_IPOFRS_ENTETES die1
										   WHERE  die1.statut = 'NEW' 
										   );
										 
		   
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de DKA_IPOFRS_ENTETES.');
			
			
				DELETE DKA_IPOFRS_LIGNES dil
			WHERE  dil.statut IN ('REJECTED1','REJECTED2')
			AND    exists(SELECT 'x'
						 FROM DKA_IPOFRS_LIGNES dih1
						 WHERE dih1.statut = 'NEW'
						 AND dih1.NUM_FOURNISSEUR = dil.NUM_FOURNISSEUR
						 AND dih1.ID_IVALUA_SITE_FOURNISSEUR = dil.ID_IVALUA_SITE_FOURNISSEUR
						);
				Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de DKA_IPOFRS_LIGNES.');
			
				DELETE  DKA_IPOFRS_HOMOLOGATIONS dih
			WHERE   dih.statut IN ('REJECTED1','REJECTED2')
			 AND    exists (SELECT 'x'
							FROM DKA_IPOFRS_HOMOLOGATIONS dih1
							WHERE dih1.statut = 'NEW'
							AND dih1.NUM_FOURNISSEUR = dih.NUM_FOURNISSEUR
							AND dih1.ID_IVALUA_SITE_FOURNISSEUR = dih.ID_IVALUA_SITE_FOURNISSEUR
							AND dih1.PERIMETRE_HOMOLOGATION = dih.PERIMETRE_HOMOLOGATION
							);
			
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || SQL%ROWCOUNT || ' Enregistrements obsolètes supprimés de DKA_IPOFRS_HOMOLOGATIONS.');
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin delete_obsolete_records');
			
		COMMIT;	
	  EXCEPTION
			WHEN OTHERS
			THEN
				pn_retcode   := 2;
				pv_errbuf    := 'DELETE_OBSOLETE_RECORDS : ' ||SQLERRM;
	  END delete_obsolete_records; 
	 
	  /*=========================================================================*/
		/* PROCEDURE NAME : purge_data
		/*
		/* DESCRIPTION
		/*  Purge des donner des opens interfaces
		/*
		/* PARAMETERS
		/* ==========
		/* NAME               DESCRIPTION
		/* -----------------  ------------------------------------------------------
		/*
		/*
		 /*=========================================================================*/
		PROCEDURE purge_data(pv_errbuf    OUT      VARCHAR2,
							 pn_retcode   OUT      NUMBER)
		IS
		v_current_program_unit   VARCHAR2(30);

		BEGIN
			v_current_program_unit := 'purge_data';
			Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - début ' || v_current_program_unit);

			-- Suppression des enregistrements traités avec succès lors de la précédente exécution de l’interface (champ STATUT = COMPLETE)
			DELETE DKA_IPOFRS_ENTETES die
			WHERE  die.statut  = 'COMPLETE';
			
				DELETE DKA_IPOFRS_LIGNES dil
			WHERE  dil.statut  = 'COMPLETE';	

				DELETE  DKA_IPOFRS_HOMOLOGATIONS dih
			WHERE   dih.statut in ( 'COMPLETE');
			
			DELETE  DKA_SAPFRSDUPLI_MASSE_TMP dih
			WHERE   dih.FILE_NAME = 'IVALUA';
			
			Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - fin ' || v_current_program_unit);
		COMMIT;	
		EXCEPTION
			WHEN OTHERS
			THEN
				pn_retcode   := 2;
				pv_errbuf    := 'PURGE_DATA : ' ||SQLERRM;   
		END purge_data;
		/*============================================================================*/
	  -- Procedure         : writeout
	  -- Description       : Ecriture dans fichier *.OUT
	  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
	  -- Parametres sortie : AUCUN
	  -- Auteur            : Saloua HA 
	  -- Date              : 03/06/2020
	  -- Remarques         :
	/*============================================================================*/
	PROCEDURE writeout(P_message IN VARCHAR2) IS
	  L_procedure VARCHAR2(30) := 'writeout';
	  v_etape     VARCHAR2(100);
	  
	  BEGIN
	  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);

	  EXCEPTION
	  WHEN OTHERS THEN
		G_retproc := 1;
		G_sqlerrm := SUBSTR(SQLERRM, 1, 200);
		Fnd_File.put_line(Fnd_File.LOG,
						  '-------------------- ERREUR --------------------');
		Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || G_package);
		Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || L_procedure);
		Fnd_File.put_line(Fnd_File.LOG, 'Exception : OTHERS');
		Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || v_etape);
		Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || G_sqlerrm);
	  END writeout;
	  
		 /*==============================================================================*/
	  -- Procedure         : Report_Bilan
	  -- Description       : Procédure pour lister les anomalies
	  -- Parametres entree : p_request_id
	  -- Parametres sortie : AUCUN
	  -- Auteur            : Saloua HA
	  -- Date              : 06/06/2020
	  -- Remarques         :
	/*=================================================================================*/
	  PROCEDURE Report_Bilan
	  IS
		l_procedure                   VARCHAR2(30) := 'Report_Bilan';
		l_message                     VARCHAR2(2000);
		message_text                     VARCHAR2(2000);
		  v_vendor_number               DKA_IPOFRS_LIGNES.NUM_FOURNISSEUR%TYPE;
		v_file_name					          DKA_IPOFRS_LIGNES.file_name%TYPE;
		CURSOR cur_liste_entete IS
		SELECT dih.NUM_FOURNISSEUR ,
			   dpm.message_text
		FROM  DKA_PROGRAM_MESSAGES dpm
		,     DKA_IPOFRS_ENTETES    dih
		WHERE dpm.REQUEST_ID = g_request_id
		AND   dih.record_id  = dpm.table_id
		AND   dpm.table_name = 'DKA_IPOFRS_ENTETES';
		
		CURSOR cur_liste_ligne IS
		SELECT dih.NUM_FOURNISSEUR ,
			   dih.NOM_ADRESSE_SITE SITE,
			   dpm.message_text
		FROM  DKA_PROGRAM_MESSAGES dpm
		,     DKA_IPOFRS_LIGNES    dih
		WHERE dpm.REQUEST_ID = g_request_id
		AND   dih.record_id  = dpm.table_id
		AND   dpm.table_name = 'DKA_IPOFRS_LIGNES';
		
	CURSOR cur_liste_homologation IS
		SELECT dih.NUM_FOURNISSEUR ,
			   dih.NOM_ADRESSE_SITE SITE,
			   dih.PERIMETRE_HOMOLOGATION UO,
			   dpm.message_text
		FROM  DKA_PROGRAM_MESSAGES        dpm
		,     DKA_IPOFRS_HOMOLOGATIONS    dih
		WHERE dpm.REQUEST_ID = g_request_id
		AND   dih.record_id  = dpm.table_id
		AND   dpm.table_name = 'DKA_IPOFRS_HOMOLOGATIONS'
		AND   dih.statut = 'REJECTED1'
		UNION
		SELECT dih.NUM_FOURNISSEUR ,
			   dih.NOM_ADRESSE_SITE SITE,
			   dih.PERIMETRE_HOMOLOGATION UO,
			   dset.error_message
		FROM  DKA_IPOFRS_HOMOLOGATIONS    dih
			 ,DKA_SAPFRSDUPLI_MASSE_TMP dsmt
			 ,DKA_SAPFRSDUPLI_ERROR_TMP dset
		WHERE dih.record_id  = dsmt.line_num
		AND   dsmt.file_name = 'IVALUA' 
		AND   dsmt.error_id = dset.action_id
		AND   dset.message_type = 'ERREUR'
		AND   dih.statut = 'REJECTED2';
		
		CURSOR cur_liste_avertissement IS
		SELECT dih.VENDOR_NUM ,
			   dih.VENDOR_SITE_CODE_REF SITE,
			   dih.PERIMETRE_DUPLI UO,
			   NBR_SITE_EXIST,
			   NBR_SITE_IGNORED
		FROM  DKA_SAPFRSDUPLI_MASSE_TMP        dih
		WHERE dih.STATUT = 'SUCCESS'
		AND  ( dih.NBR_SITE_EXIST  > 0 
			  OR   
			  dih.NBR_SITE_IGNORED > 0
			  );

	  BEGIN
			writeout(' ENTETES Fournisseurs : ');
			writeout('. Nombre d''enregistrements à traiter                                                : '||g_nb_entetes_traite);
			writeout('. Nombre d''enregistrements traités avec succès                                      : '||g_nb_entetes_traite_succes );
			writeout('. Nombre d''enregistrements rejetés (phase de validation)                            : '||g_nb_entetes_traite_rejected1  );
			writeout('. Nombre d''enregistrements rejetés (phase de création/mise à jour)                  : '||g_nb_entetes_traite_rejected2  );
			writeout('                                                                          ');
			writeout( 'LISTE DES ANOMALIES :');
			writeout( '---------------------');
			writeout( RPAD('Fournisseur',35)||RPAD('Message erreur',500));
			writeout( RPAD('-----------',35)||RPAD('--------------',500));
			FOR rec_entete IN cur_liste_entete LOOP
			   l_message := RPAD(NVL(rec_entete.NUM_FOURNISSEUR,'  '),35,'  ')||RPAD(rec_entete.message_text,500);
			   writeout(l_message);
				END LOOP;
			writeout('--------------------------------------------------------------------------------------------');
			writeout('                                                                          ');
			writeout(' SITES Fournisseurs :');
			writeout('. Nombre d''enregistrements à traiter                                                : '||g_nb_lignes_traite);
			writeout('. Nombre d''enregistrements traités avec succès                                      : '||g_nb_lignes_traite_succes );
			writeout('. Nombre d''enregistrements rejetés (phase de validation)                            : '||g_nb_lignes_traite_rejected1  );
			writeout('. Nombre d''enregistrements rejetés (phase de création/mise à jour)                  : '||g_nb_lignes_traite_rejected2  );
			writeout('                                                                          ');
			writeout( 'LISTE DES ANOMALIES :');
			writeout( '---------------------');
			writeout( RPAD('Fournisseur',35)||RPAD('Site',35)||RPAD('Message erreur',500));
			writeout( RPAD('-----------',35)||RPAD('-----------',35)||RPAD('--------------',500));
			FOR rec_lignes IN cur_liste_ligne LOOP
			   l_message := RPAD(NVL(rec_lignes.NUM_FOURNISSEUR,'  '),35,' ')||RPAD(NVL(rec_lignes.SITE,'  '),35,' ')||RPAD(rec_lignes.message_text,500);
			   writeout(l_message);
			END LOOP;
			writeout('--------------------------------------------------------------------------------------------');
			writeout('                                                                          ');
			writeout(' HOMOLOGATIONS Fournisseurs :');
			writeout('. Nombre d''enregistrements à traiter                                                 : '||g_nb_homologation_traite);
			writeout('. Nombre d''enregistrements traités avec succès                                       : '||g_nb_homo_traite_succes );
			writeout('. Nombre d''enregistrements rejetés (phase de validation)                             : '||g_nb_homo_traite_rejected1  );
			writeout('. Nombre d''enregistrements rejetés (phase de création/mise à jour)                   : '||g_nb_homo_traite_rejected2  );
			writeout('                                                                          ');
			writeout( 'LISTE DES ANOMALIES :');
			writeout( '---------------------');
			writeout( RPAD('Fournisseur',35)||RPAD('Site',35)||RPAD('UO',35)||RPAD('Message erreur',500));
			writeout( RPAD('-----------',35)||RPAD('-----------',35)||RPAD('-----------',35)||RPAD('--------------',500));
			FOR rec_homologation IN cur_liste_homologation LOOP
			   l_message := RPAD(NVL(rec_homologation.NUM_FOURNISSEUR,'  '),35,' ')||RPAD(NVL(rec_homologation.SITE,'  '),35,' ')||RPAD(NVL(rec_homologation.UO,'  '),35,' ')||RPAD(rec_homologation.message_text,500);
			   writeout(l_message);
				END LOOP;
		   writeout('                                                                          ');
		   writeout( 'LISTE DES AVERTISSEMENTS :');
		   FOR rec_avertissement IN cur_liste_avertissement LOOP
			BEGIN
			 if rec_avertissement.NBR_SITE_EXIST > 0 THEN
			 message_text := 'Le site a déja été dupliqué ';
			 else if rec_avertissement.NBR_SITE_IGNORED > 0 then
			 message_text := 'le site ne doit pas être dupliqué';
			 end if;
			 end if;
			
			END;
			   l_message := RPAD(NVL(rec_avertissement.vendor_num,''),35,' ')||RPAD(NVL(rec_avertissement.SITE,''),35,' ')||RPAD(NVL(rec_avertissement.UO,''),35,' ')||RPAD(message_text,500);
			   writeout(l_message);
				END LOOP;
	  END Report_Bilan;
	  
	  /*
	 *************************************************************************
	 * PROCEDURE NAME : init
	 * 
	 * DESCRIPTION
	 *  Procédure d'initialisation des variables globales
	 *
	 * PARAMETERS
	 * ==========
	 * NAME              DESCRIPTION
	.* ----------------- ------------------------------------------------------
	 * p_errbuf         Retour de message éventuel
	 * p_retcode        Statut du traitement en sortie
	 ************************************************************************
	 */
	  PROCEDURE init 
	  IS

		v_current_program_unit    VARCHAR2(30);
		v_step_program_error      VARCHAR2(1000);
		program_error             EXCEPTION;
		rec_param dka_parameters%ROWTYPE;
		v_resp_appl_id 	fnd_responsibility.application_id%TYPE;
		v_resp_id   fnd_responsibility.responsibility_id%TYPE;

	  BEGIN
			----------------------------------
			-- Initialisation des variables --
			----------------------------------
		  
			
			g_nb_entetes_traite                     := 0;
			g_nb_lignes_traite			            := 0;
			g_nb_homologation_traite			    := 0;
			g_nb_entetes_traite_succes              := 0;
			g_nb_lignes_traite_succes			    := 0;
			g_nb_homo_traite_succes		            := 0;
			g_nb_entetes_traite_rejected1           := 0;
			g_nb_lignes_traite_rejected1	        := 0;
			g_nb_homo_traite_rejected1	            := 0;
			g_nb_entetes_traite_rejected2           := 0;
			g_nb_lignes_traite_rejected2	        := 0;
			g_nb_homo_traite_rejected2	            := 0;
			
		---- initialisation d'environnement
			BEGIN
				SELECT responsibility_id, application_id
				INTO v_resp_id, v_resp_appl_id
				FROM fnd_responsibility fr
				WHERE  fr.responsibility_key = 'REF9999_AP_ADMINISTRATEUR';--'DKA_GESTION_REF_FOURNISS';--'TOUT_AP_ADMINISTRATEUR';--'DKA_GESTION_REFERENTIEL_FOURNISSEURS';

				  

			EXCEPTION
				WHEN OTHERS THEN
					v_resp_id   := NULL;
					v_resp_appl_id := NULL;
				  
			END;
			APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => g_user_id,
												  RESP_ID      => v_resp_id,
												  RESP_APPL_ID => v_resp_appl_id
												  );
			
	  END INIT ; 
		
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
		* p_file_name       Nom du fichier a charger
		* p_errbuf          Retour de message éventuel
		* p_retcode         Statut du traitement en sortie
		*
		************************************************************************
		*/
		PROCEDURE Launch_Loader  (pv_errbuf  IN OUT VARCHAR2,
								  pn_retcode OUT    NUMBER
								  ) IS

	  l_procedure               VARCHAR2(30) := 'Launch_Loader';
	  l_message                 VARCHAR2(2000);
	  l_request_id              NUMBER;
	  l_application_code        VARCHAR2(50) := 'DKA';
	  l_conc_program            VARCHAR2(50) := 'DKA_IPOFRS_IVALUA_LOADER';
	  l_execute_code            BOOLEAN;
	  l_req_interval            NUMBER := 30;
	  l_req_max_wait            NUMBER := 999999;
	  l_req_ret_code            NUMBER;
	  l_req_phase               VARCHAR2(255);
	  l_req_status              VARCHAR2(255);
	  l_req_dev_phase           VARCHAR2(255);
	  l_req_dev_status          VARCHAR2(255);
	  l_req_message             VARCHAR2(255);
	  vf_errbuf                 VARCHAR2(500);
	  vf_retcode                NUMBER;
	  BEGIN
		l_message := l_procedure || '- 01 - Debut';
		Fnd_File.put_line(Fnd_File.LOG, l_message);

		l_message := l_procedure || '- 02 - Submit Request';
		Fnd_File.put_line(Fnd_File.LOG, l_message);
		l_request_id := FND_REQUEST.submit_request(l_application_code,
													l_conc_program,
													'',
													SYSDATE,
													FALSE
													);


		COMMIT;
		IF l_request_id != 0 THEN
			DKA_TOOLS_PKG.put_log_message(l_message);
			l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST( REQUEST_ID => l_request_id
															 , INTERVAL   => l_req_interval
															 , MAX_WAIT   => l_req_max_wait
															 , PHASE      => l_req_phase
															 , STATUS     => l_req_status
															 , DEV_PHASE  => l_req_dev_phase
															 , DEV_STATUS => l_req_dev_status
															 , MESSAGE    => l_req_message
															 );

			IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
				l_message := l_procedure||' - 04a - Traitement terminé en avertissement';
				DKA_TOOLS_PKG.put_log_message(l_message);
				pn_retcode := 1;
			ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
				l_message := l_procedure||' - 04b - Traitement terminé en erreur';
				l_req_dev_status := 'Erreur';
				 DELETE FROM DKA_IPOFRS_HIST_ENTETES
				 WHERE LOADER_REQUEST_ID =l_request_id
				 ;
				 
				 DELETE FROM DKA_IPOFRS_HIST_LIGNES
				 WHERE LOADER_REQUEST_ID =l_request_id
				 ;
			   
				 DELETE FROM DKA_IPOFRS_HIST_HOMOLOGATIONS 
				 WHERE LOADER_REQUEST_ID =l_request_id
				 ;   
				DKA_TOOLS_PKG.put_log_message(l_message);
				pn_retcode := 2;
			ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'NORMAL' THEN
				l_message := l_procedure||' - 04b - Traitement terminé normal';
				DKA_TOOLS_PKG.put_log_message(l_message);
				Fnd_File.put_line(Fnd_File.LOG, l_message);
				pn_retcode := 0;
				
				UPDATE_RECORD_id(vf_errbuf ,
								 vf_retcode ,
								 l_request_id)
								 ;

			END IF;
		ELSE
			l_message := l_procedure||' - 03 - Erreur lors du lancement du traitement';
			DKA_TOOLS_PKG.put_log_message(l_message);
			DBMS_OUTPUT.PUT_LINE(l_message);
			pn_retcode := 2;

		END IF;
		COMMIT;
		writeout('CHARGEMENT DES FICHIER :');
		writeout('-----------------------');
		writeout('. Numéro du traitement : '||l_request_id);
		writeout('. Statut de fin : Terminé/'||l_req_dev_status);
		writeout('                                                                           ');
		writeout('                                                                           ');
		 DBMS_OUTPUT.PUT_LINE('. Numéro du traitement  '||l_request_id);
		  Fnd_File.put_line(Fnd_File.LOG, '. Numéro du traitement de chargement du fichier : '||l_request_id);
	END Launch_Loader;

	 
	---------------------------------------------------------------------------------------
	--  Nom           : ins_prog_message
	--  Description   : Insere un message dans la table d'erreurs DKA_PROGRAM_MESSAGES et 
	--                  Insere un message dans le journal
	--     NB         :  cette proc s'exécute dans une transaction propre et fait un commit
	-------------------------------------------------------------------------------------------------------------------
	  PROCEDURE ins_prog_message(pn_request_id       IN NUMBER,
								 pv_prog_name        IN VARCHAR2,
								 pv_source           IN VARCHAR2 DEFAULT 'ETL',
								 pv_table_name       IN VARCHAR2,
								 pv_table_id         IN VARCHAR2,
								 pv_column_name      IN VARCHAR2,
								 pv_column_value     IN VARCHAR2,
								 pv_message_type     IN VARCHAR2 DEFAULT 'E',
								 pv_message_text     IN VARCHAR2) IS
		--PRAGMA AUTONOMOUS_TRANSACTION;
	  BEGIN
	  
		INSERT INTO dka_program_messages
		  (request_id,
		   prog_name,
		   SOURCE,
		   table_name,
		   table_id,
		   column_name,
		   column_value,
		   message_type,
		   message_text)
		VALUES
		  (pn_request_id,   --request_id
		   pv_prog_name,    --prog_name
		   pv_source,       --source
		   pv_table_name,   --table_name
		   pv_table_id,     --table_id
		   pv_column_name,  --column_name
		   pv_column_value, --column_value
		   pv_message_type, --message_type
		   pv_message_text  --message_text
		   );
		   
	  EXCEPTION
		WHEN OTHERS THEN
		  ROLLBACK;
		  RAISE_APPLICATION_ERROR(-20000,
								  'DKA_TOOLS_PKG.ins_prog_message:' || SQLERRM);
	  END ins_prog_message;
	  
	 /*
	 *************************************************************************
	 * PROCEDURE NAME : validate_data
	 * 
	 * DESCRIPTION
	 *  Procédure de transcodification et de validation des données
	 *
	 * PARAMETERS
	 * ==========
	 * NAME                 DESCRIPTION
	.* -------------------- ---------------------------------------------------
	 * p_errbuf            Retour de message éventuel
	 * p_retcode           Statut du traitement en sortie
	 ************************************************************************
	 */  
	 
	  PROCEDURE validate_data(p_errbuf        OUT VARCHAR2,
							  p_retcode       OUT NUMBER
							  ) 
	  IS
	  
	  ---------- VARIABLES ----------
	  v_etape              VARCHAR2(500);
	  v_compte_actif       VARCHAR2(2);
	  v_nom_fournisseur    varchar(80);
	  v_code_das2          varchar(80);
	  v_code_surtaxe       varchar(80);
	  v_type               varchar(80);
	  v_type_fournisseur   varchar(80);
	  v_type_min           varchar(80);
	  v_occasionnel        varchar(1);
	  v_federal            varchar(1);
	  v_contexte           varchar(80);
	  v_partenaire         varchar(80);
	  v_code_partenaire    varchar(80);
	  v_num_fournisseur    varchar(80);
	  v_num_societe_mere   varchar(80);
	  v_code_pays          varchar(4);
	  v_mode_notification  varchar(25);
	  v_uo                 VARCHAR2(1);
	  vv_exist_f           VARCHAR2(1);
	  vv_exist_h1          VARCHAR2(1);
	  vv_exist_h2          VARCHAR2(1);
	  vv_exist_h3            VARCHAR2(1);
	  v_compte_acompte     gl_code_combinations.code_combination_id%TYPE;
	  v_compte_fournisseur gl_code_combinations.code_combination_id%TYPE;
	  v_compte_effet       gl_code_combinations.code_combination_id%TYPE;
	  vn_PREPAY_CCID       gl_code_combinations.code_combination_id%TYPE;
	  vn_ACCTS_PAY_CCID    gl_code_combinations.code_combination_id%TYPE;
	  vn_future_CCID       gl_code_combinations.code_combination_id%TYPE;
	  vn_segment1          gl_code_combinations.segment1%TYPE;
	  vn_segment2          gl_code_combinations.segment2%TYPE;
	  vn_segment3          gl_code_combinations.segment3%TYPE;
	  vn_segment4          gl_code_combinations.segment4%TYPE;
	  vn_segment5          gl_code_combinations.segment5%TYPE;
	  vn_segment6          gl_code_combinations.segment6%TYPE;
	  vn_segment7          gl_code_combinations.segment7%TYPE;
	  vn_segment8          gl_code_combinations.segment8%TYPE;
	  vn_segment9          gl_code_combinations.segment9%TYPE;
	  vn_segment10         gl_code_combinations.segment10%TYPE;
	  vn_segment11         gl_code_combinations.segment11%TYPE;
	  vn_segment12         gl_code_combinations.segment12%TYPE;
	  vn_retcode           PLS_INTEGER := 0;
	  vv_errbuf            VARCHAR2(500);
	  v_message            VARCHAR2(500) := null;
	  l_message            VARCHAR2(2000);
	  vr_vendor_rec         ap_vendor_pub_pkg.r_vendor_rec_type;
	  --FLAG
	  v_flag_erreur_entete        BOOLEAN;
	  v_flag_erreur_lignes        BOOLEAN;
	  v_flag_erreur_homologation  BOOLEAN;
	  v_flag_exist_lines          BOOLEAN;
	  --- EDB330
	  vn_echeance			NUMBER;
	  
	   ---------- CURSORS ----------
			CURSOR cur_fournisseur
			IS SELECT die.*
			FROM DKA_IPOFRS_ENTETES die
			WHERE die.statut in  ('NEW','REJECTED1' ,'REJECTED2')
			;

			CURSOR cur_site_fournisseur
			IS SELECT dis.*
			FROM DKA_IPOFRS_lignes dis
			WHERE dis.statut in  ('NEW','REJECTED1' ,'REJECTED2')
			;
			
		   CURSOR cur_homologation
			IS SELECT dih.*
			FROM DKA_IPOFRS_HOMOLOGATIONS dih
			WHERE dih.statut in ('NEW' ,'REJECTED1','REJECTED2')
			;
	BEGIN 
		 
		FOR rec_fournisseur IN cur_fournisseur LOOP
			g_nb_entetes_traite        := g_nb_entetes_traite + 1;
			v_flag_erreur_entete       := FALSE;
		  
		/*//--vérification que les champs obligatoires ne sont pas vides --//*/
	  
		--- RG403 : Numéro de fournisseur 
		  v_etape:= 'Numéro de fournisseur';
		DKA_TOOLS_PKG.put_log_message(v_etape);
		IF rec_fournisseur.NUM_FOURNISSEUR IS NULL 
		 THEN 
			v_flag_erreur_entete := TRUE;
			l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOFRS_005');
			ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'NUM_FOURNISSEUR'
							  ,rec_fournisseur.NUM_FOURNISSEUR
							  ,'E'
							  ,l_message
							);
		END IF;
		DKA_TOOLS_PKG.put_log_message(l_message);
	  
		--- RG404 : NOM du fournisseur 
		v_etape:= 'NOM du fournisseur';
		DKA_TOOLS_PKG.put_log_message(v_etape);
		IF rec_fournisseur.NOM_FOURNISSEUR IS NULL 
		 THEN
			v_flag_erreur_entete := TRUE;	 
			l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOFRS_006');
			ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'NOM_FOURNISSEUR'
							  ,rec_fournisseur.NOM_FOURNISSEUR
							  ,'E'
							  ,l_message
							);
			DKA_TOOLS_PKG.put_log_message(l_message);
		ELSE 
		  BEGIN 
			  select distinct '1'
			  into v_nom_fournisseur
			  from
				 (select '1'
				 from 
				 DKA_IPOFRS_ENTETES die
				 where die.NOM_FOURNISSEUR  = rec_fournisseur.NOM_FOURNISSEUR
				 and   (NVL(die.NUM_FOURNISSEUR,'@') != rec_fournisseur.NUM_FOURNISSEUR )
				 union
				 select '1'
				 from 
				 ap_suppliers asup
				 where asup.vendor_name = rec_fournisseur.NOM_FOURNISSEUR
				 and asup.segment1      != rec_fournisseur.NUM_FOURNISSEUR)
		  ;
			EXCEPTION
		  WHEN NO_DATA_FOUND THEN
			  v_nom_fournisseur := NULL;
		END; 
		
		  IF v_nom_fournisseur = '1' then 
		
			  v_flag_erreur_entete := TRUE;
					l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_007','NOM_FOURNISSEUR',rec_fournisseur.NOM_FOURNISSEUR);
					ins_prog_message(  g_import_request_id
								  ,'DKA_IPOFRS_IVALUA_PKG'
								  ,'ENTETE'
								  ,'DKA_IPOFRS_ENTETES'
								  --,NULL
								  ,rec_fournisseur.RECORD_ID
								  ,'NOM_FOURNISSEUR'
								  ,rec_fournisseur.NOM_FOURNISSEUR
								  ,'E'
								  ,l_message
								);
					DKA_TOOLS_PKG.put_log_message(l_message);
		
		 
			
		 
		
			END IF;
		END IF;
		
		--- RG408 : Code DAS2  
		v_etape:= 'Code DAS2';
	  DKA_TOOLS_PKG.put_log_message(v_etape);
	  if rec_fournisseur.CODE_DAS2 is not null then 
		BEGIN
		  select '1'
		into  v_code_das2	
		FROM  FND_LOOKUP_VALUES flv
		where flv.lookup_type   ='JE_FR_TAX_TYPES'
			and   flv.lookup_code   = rec_fournisseur.CODE_DAS2
			AND   flv.enabled_flag  = 'Y'
		AND   NVL(flv.END_DATE_ACTIVE  ,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
			AND   NVL(flv.START_DATE_ACTIVE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
		and rownum <2;
			v_federal :='Y';
			EXCEPTION
		  WHEN NO_DATA_FOUND  THEN 
				v_flag_erreur_entete := TRUE;
				v_federal            := null;
				l_message            := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_008','CODE_DAS2',rec_fournisseur.code_das2);
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'DAS2'
							  ,rec_fournisseur.code_das2
							  ,'E'
							  ,l_message
							);
			  DKA_TOOLS_PKG.put_log_message(l_message);	
		END;
		end if;
	 ----- RG411 :Numéro de la société mère 
		v_etape:= 'Numéro de la société mère';
		DKA_TOOLS_PKG.put_log_message(v_etape);
	  IF rec_fournisseur.NUM_SOCIETE_MERE IS NOT NULL THEN 
	  BEGIN
		select '1'
		  into v_num_societe_mere 
		from ap_suppliers aps
		where aps.segment1 = rec_fournisseur.NUM_SOCIETE_MERE
		and aps.enabled_flag  = 'Y'
		and (aps.end_date_active IS NULL OR aps.end_date_active > SYSDATE);
		  EXCEPTION
		  WHEN NO_DATA_FOUND THEN 
				v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_009','SOCIETE_MERE',rec_fournisseur.NUM_SOCIETE_MERE);
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'NUM SOCIETE MERE'
							  ,rec_fournisseur.NUM_SOCIETE_MERE
							  ,'E'
							  ,l_message
							);
				
			DKA_TOOLS_PKG.put_log_message(l_message);
		END;
	  END IF;
		
	 ------ Occasionnel
	  v_etape:= 'Occasionnel';
	  DKA_TOOLS_PKG.put_log_message(v_etape);
	  IF rec_fournisseur.OCCASIONNEL is null then
		  v_occasionnel := 'N';
	  ELSIF rec_fournisseur.OCCASIONNEL not in ('N','Y') then
		v_flag_erreur_entete := TRUE;
			l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_010','OCCASIONNEL',rec_fournisseur.OCCASIONNEL);
		ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'Occasionnel'
							  ,rec_fournisseur.OCCASIONNEL
							  ,'E'
							  ,l_message
						);
			DKA_TOOLS_PKG.put_log_message(l_message);
		ELSE 
		  v_occasionnel := rec_fournisseur.OCCASIONNEL;
	  END IF;
	 
	 ---TYPE
		v_etape:= 'TYPE';
		DKA_TOOLS_PKG.put_log_message(v_etape);
	  IF  rec_fournisseur.type is null then
		  v_flag_erreur_entete := TRUE;
			  l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_011');
		  ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'Type'
							  ,rec_fournisseur.TYPE
							  ,'E'
							  ,l_message
							);
		  DKA_TOOLS_PKG.put_log_message(l_message);
	  END IF; 
	   if rec_fournisseur.type is not null then 
	  BEGIN
		  SELECT '1'
			into   v_type
			from   FND_LOOKUP_VALUES flv
		where  flv.lookup_type   = 'VENDOR TYPE'
			and    flv.lookup_code   = rec_fournisseur.type
			AND    flv.enabled_flag  = 'Y'
		AND    NVL(flv.END_DATE_ACTIVE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
			AND    NVL(flv.START_DATE_ACTIVE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
		and rownum <2;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
				v_flag_erreur_entete := TRUE;	
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_012','TYPE_FOURNISSEUR',rec_fournisseur.TYPE);			
			ins_prog_message(     g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'Type'
							  ,rec_fournisseur.type
							  ,'E'
							  ,l_message
						);
			DKA_TOOLS_PKG.put_log_message(l_message);	
		END;
		end if ; 
	  -----RG414 : type de minorité 
		v_etape:= 'SOUS TYPE';
		DKA_TOOLS_PKG.put_log_message(v_etape);
	  IF rec_fournisseur.sous_type IS NOT NULL THEN
	  BEGIN
		  SELECT '1'
			into  v_type_min
			from  FND_LOOKUP_VALUES flv
		where flv.lookup_type   = 'MINORITY GROUP'
			and   flv.lookup_code   = rec_fournisseur.sous_type
			AND   flv.enabled_flag  = 'Y'
		AND   NVL(flv.END_DATE_ACTIVE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
			AND   NVL(flv.START_DATE_ACTIVE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
		and rownum <2;
			EXCEPTION
		  WHEN NO_DATA_FOUND THEN
		  v_flag_erreur_entete := TRUE;	
		  l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_013','SOUS_TYPE',rec_fournisseur.SOUS_TYPE);			
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'Sous Type'
							  ,rec_fournisseur.SOUS_TYPE
							  ,'E'
							  ,l_message
							);
			DKA_TOOLS_PKG.put_log_message(l_message);	
		END;
	END IF;
	  -----CUF - Fournisseur de services 
		v_etape:= 'CUF - Fournisseur de services';
		DKA_TOOLS_PKG.put_log_message(v_etape);
	  IF rec_fournisseur.FOURNISSEUR_SERVICES is null then
		  v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_014');	
		  ins_prog_message(  g_import_request_id
						,'DKA_IPOFRS_IVALUA_PKG'
						,'ENTETE'
						,'DKA_IPOFRS_ENTETES'
						--,NULL
						,rec_fournisseur.RECORD_ID
						,'FOURNISSEUR DE SERVICES'
						,rec_fournisseur.FOURNISSEUR_SERVICES
						,'E'
						,l_message
					  );
				DKA_TOOLS_PKG.put_log_message(l_message);			
	  ELSIF rec_fournisseur.FOURNISSEUR_SERVICES not in ('N','Y') then
		  v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_015','FOURNISSEUR_SERVICES',rec_fournisseur.FOURNISSEUR_SERVICES);			
				ins_prog_message(  g_import_request_id
						,'DKA_IPOFRS_IVALUA_PKG'
						,'ENTETE'
						,'DKA_IPOFRS_ENTETES'
						--,NULL
						,rec_fournisseur.RECORD_ID
						,'FOURNISSEUR DE SERVICES'
						,rec_fournisseur.FOURNISSEUR_SERVICES
						,'E'
						,l_message
					  );
				DKA_TOOLS_PKG.put_log_message(l_message);
	  END IF; 
	  
	   -----CUF - Fournisseur de combustibles 
		v_etape:= 'CUF - Fournisseur de combustibles ';
		DKA_TOOLS_PKG.put_log_message(v_etape);   
	  IF rec_fournisseur.FOURNISSEUR_COMBUSTIBLES is null then
		  v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_016');	
		  ins_prog_message(  g_import_request_id
						,'DKA_IPOFRS_IVALUA_PKG'
						,'ENTETE'
						,'DKA_IPOFRS_ENTETES'
						--,NULL
						,rec_fournisseur.RECORD_ID
						,'FOURNISSEUR DE COMBUSTIBLES'
						,rec_fournisseur.FOURNISSEUR_COMBUSTIBLES
						,'E'
						,l_message
						  );
			DKA_TOOLS_PKG.put_log_message(l_message);
	  ELSIF rec_fournisseur.FOURNISSEUR_COMBUSTIBLES not in ('N','Y') then
		  v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_017','FOURNISSEUR_COMBUSTIBLES',rec_fournisseur.FOURNISSEUR_COMBUSTIBLES);			
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'FOURNISSEUR DE COMBUSTIBLES'
							  ,rec_fournisseur.FOURNISSEUR_COMBUSTIBLES
							  ,'E'
							  ,l_message
							);
			DKA_TOOLS_PKG.put_log_message(l_message);
	  END IF; 
	  
	   -----CUF - Fournisseur de véhicules 
		v_etape:= 'CUF - Fournisseur de véhicules  ';
		DKA_TOOLS_PKG.put_log_message(v_etape);      
	  IF rec_fournisseur.FOURNISSEUR_VEHICULES is null then
		  v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_018');	
		  ins_prog_message(  g_import_request_id
						,'DKA_IPOFRS_IVALUA_PKG'
						,'ENTETE'
						,'DKA_IPOFRS_ENTETES'
						--,NULL
						,rec_fournisseur.RECORD_ID
						,'FOURNISSEUR DE VÉHICULES '
						,rec_fournisseur.FOURNISSEUR_VEHICULES
						,'E'
						,l_message
					  );
				DKA_TOOLS_PKG.put_log_message(l_message);
	  ELSIF rec_fournisseur.FOURNISSEUR_VEHICULES not in ('N','Y') then
		  v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_019','FOURNISSEUR_VEHICULES',rec_fournisseur.FOURNISSEUR_VEHICULES);			
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'FOURNISSEUR DE VÉHICULES'
							  ,rec_fournisseur.FOURNISSEUR_VEHICULES
							  ,'E'
							  ,l_message
							);
			DKA_TOOLS_PKG.put_log_message(l_message);
	  END IF; 
	  -----CUF – Code Surtaxe com 
		v_etape:= 'CUF – Code Surtaxe com  ';
		DKA_TOOLS_PKG.put_log_message(v_etape);
		IF rec_fournisseur.CODE_SURTAXE_COM Is not null then 
	  BEGIN
			select ffv.flex_value  
		  into v_code_surtaxe	   
		  from fnd_flex_value_sets ffvs ,
			   fnd_flex_values     ffv  
		  where 
			  ffv.flex_value_set_id = ffvs.flex_value_set_id
		  AND flex_value_set_name = 'DKA_SURTAXE_COMMUNALE_ORGANISME'
		  AND ffv.flex_value = rec_fournisseur.CODE_SURTAXE_COM
		  and ffv.enabled_flag = 'Y'
		  and ffv.summary_flag = 'N'
		  and ffv.enabled_flag = 'Y'
		  and nvl(ffv.start_date_active,SYSDATE) <= SYSDATE
		  and nvl(ffv.end_date_active,SYSDATE)       >= SYSDATE
		  and rownum <2;
		   EXCEPTION
				WHEN NO_DATA_FOUND THEN 
				v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_020','SURTAXE_COMMUNALE',rec_fournisseur.CODE_SURTAXE_COM);			
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'Code Surtaxe com'
							  ,rec_fournisseur.CODE_SURTAXE_COM
							  ,'E'
							  ,l_message
							);
			DKA_TOOLS_PKG.put_log_message(l_message);
	  END;
	  end if;
	  ------CUF – Code Partenaire 
		v_etape:= 'CUF – Code Partenaire   ';
		DKA_TOOLS_PKG.put_log_message(v_etape);
	  IF rec_fournisseur.type = 'PARTENAIRE' OR rec_fournisseur.type = 'EXTERNAL  PARTNER'	 then
		v_contexte := 'PARTENAIRE';
		if rec_fournisseur.code_partenaire is null then 
			v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_021','CODE_PARTENAIRE',rec_fournisseur.code_partenaire,'TYPE_FOURNISSEUR',rec_fournisseur.type);			
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'code partenaire'
							  ,rec_fournisseur.code_partenaire
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		else
			BEGIN
				select ffv.flex_value 
				into v_partenaire			
				from fnd_flex_value_sets ffvs,
					 fnd_flex_values     ffv  
				where ffv.flex_value_set_id = ffvs.flex_value_set_id
				AND flex_value_set_name = 'DAOPCCF_INTERCO'
				AND ffv.flex_value like '%'||rec_fournisseur.code_partenaire
				and ffv.enabled_flag = 'Y'
				and ffv.summary_flag = 'N'
		  and ffv.enabled_flag = 'Y'
		  and nvl(ffv.start_date_active,SYSDATE) <= SYSDATE
		  and nvl(ffv.end_date_active,SYSDATE)       >= SYSDATE
		  and rownum <2;
				EXCEPTION
						WHEN NO_DATA_FOUND THEN 
						v_flag_erreur_entete := TRUE;
						l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_022','CODE_PARTENAIRE',rec_fournisseur.code_partenaire);			
				
						ins_prog_message(  g_import_request_id
									,'DKA_IPOFRS_IVALUA_PKG'
									,'ENTETE'
									,'DKA_IPOFRS_ENTETES'
									--,NULL
									,rec_fournisseur.RECORD_ID
									,'code partenaire'
									,rec_fournisseur.code_partenaire
									,'E'
									,l_message
									);
				DKA_TOOLS_PKG.put_log_message(l_message);
			
			END ; 
		END IF;
	  ELSE 
	   v_contexte := null;
	  if rec_fournisseur.code_partenaire is not null then 
				v_flag_erreur_entete := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_023','CODE_PARTENAIRE',rec_fournisseur.code_partenaire,'TYPE_FOURNISSEUR',rec_fournisseur.type);				
				
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'ENTETE'
							  ,'DKA_IPOFRS_ENTETES'
							  --,NULL
							  ,rec_fournisseur.RECORD_ID
							  ,'code partenaire'
							  ,rec_fournisseur.code_partenaire
							  ,'E'
							  , l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
	  END IF; 
	  
	  END IF;
	  
	 -- TEST FLAG
	   IF NOT v_flag_erreur_entete THEN
				UPDATE DKA_IPOFRS_ENTETES
				SET  STATUT      		    = 'VALIDATED'
				  ,  OCCASIONNEL 		    = v_occasionnel
				  ,  CONTEXTE    		    = v_contexte
				  ,  FEDERAL                = v_federal
				  ,  LAST_UPDATE_DATE    	= SYSDATE
				  ,  LAST_UPDATED_BY     	= g_user_id				
				  ,  request_id             = g_request_id                
				WHERE RECORD_ID = rec_fournisseur.RECORD_ID
				;
				
			  ELSE -- en cas d'erreur
				  g_nb_entetes_traite_rejected1 := g_nb_entetes_traite_rejected1 + 1;
				UPDATE DKA_IPOFRS_ENTETES
				SET   STATUT 			= 'REJECTED1'   
					 ,LAST_UPDATE_DATE  = SYSDATE
					 ,LAST_UPDATED_BY   = g_user_id	
					 ,request_id        = g_request_id				 
				WHERE RECORD_ID 		= rec_fournisseur.RECORD_ID
				;
			  p_retcode := 1;
			  END IF; 
			  
	 
		END LOOP;-- entetes
		COMMIT;
		----- validate site 
		
		FOR rec_site_f IN cur_site_fournisseur LOOP
		g_nb_lignes_traite := g_nb_lignes_traite + 1;
		v_flag_erreur_lignes := FALSE;
		
		/*//--vérification que les champs obligatoires ne sont pas vides --//*/
		--Existence du fournisseur 
		v_etape:= 'fournisseur – num_fournisseur ';
	  DKA_TOOLS_PKG.put_log_message(v_etape);
		if rec_site_f.num_fournisseur is null then 
			 v_flag_erreur_lignes := TRUE;
			 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_005','FOURNISSEUR',rec_site_f.num_fournisseur);		
			 ins_prog_message(  g_import_request_id
														,'DKA_IPOFRS_IVALUA_PKG'
														,'LIGNES'
														,'DKA_IPOFRS_LIGNES'
														--,NULL
														,rec_site_f.RECORD_ID
														,'num_fournisseur'
														,rec_site_f.num_fournisseur
														,'E'
														,l_message
							);	
				DKA_TOOLS_PKG.put_log_message(l_message);
		ELSE 		
			BEGIN
					select '1'
					into vv_exist_f
					from ap_suppliers aps
					where aps.segment1 = rec_site_f.num_fournisseur;
					EXCEPTION
						 WHEN too_many_rows THEN
							 vv_exist_f := '1';
						 WHEN OTHERS THEN
							 vv_exist_f := NULL;
				
				END;
			IF
			vv_exist_f IS NULL THEN
				BEGIN
					select '1'
					into vv_exist_f
					from DKA_IPOFRS_ENTETES dil
					where dil.num_fournisseur = rec_site_f.num_fournisseur
					and    dil.statut         ='VALIDATED';
					EXCEPTION
						 WHEN too_many_rows THEN
							 vv_exist_f := '1';
						 WHEN OTHERS THEN
							 vv_exist_f := NULL;
						 
				END;
			END IF ; 
			IF
			vv_exist_f IS NULL THEN
							v_flag_erreur_lignes := TRUE;
							l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_024','FOURNISSEUR',rec_site_f.num_fournisseur);
							ins_prog_message(  g_import_request_id
														,'DKA_IPOFRS_IVALUA_PKG'
														,'LIGNES'
														,'DKA_IPOFRS_LIGNES'
														--,NULL
														,rec_site_f.RECORD_ID
														,'num_fournisseur'
														,rec_site_f.num_fournisseur
														,'E'
														,l_message
											 );
						DKA_TOOLS_PKG.put_log_message(l_message);
			END IF ; 
		
		END IF ; 
		
		IF rec_site_f.NOM_ADRESSE_SITE IS NULL THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_025');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'NOM_ADRESSE_SITE'
							  ,rec_site_f.NOM_ADRESSE_SITE
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		IF rec_site_f.ID_IVALUA_SITE_FOURNISSEUR IS NULL THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_026');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'ID_IVALUA_SITE_FOURNISSEUR'
							  ,rec_site_f.ID_IVALUA_SITE_FOURNISSEUR
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		IF rec_site_f.PAYS IS NULL THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_027');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'PAYS'
							  ,rec_site_f.PAYS
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
							
			ELSE 
			BEGIN
			select territory_code
			into v_code_pays 
			from  FND_TERRITORIES_vl 
			where territory_code = rec_site_f.PAYS;
			EXCEPTION
						WHEN NO_DATA_FOUND THEN 
						v_flag_erreur_lignes := TRUE;
						l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_028','CODE_PAYS',rec_site_f.PAYS);
						ins_prog_message(  g_import_request_id
									,'DKA_IPOFRS_IVALUA_PKG'
									,'LIGNES'
									,'DKA_IPOFRS_LIGNES'
									--,NULL
									,rec_site_f.RECORD_ID
									,'pays'
									,rec_site_f.PAYS
									,'E'
									,l_message
									);
					DKA_TOOLS_PKG.put_log_message(l_message);
			END; 
			
			
		END IF;
		
		IF rec_site_f.ADRESSE_LIGNE1 IS NULL THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_029');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'ADRESSE_LIGNE1'
							  ,rec_site_f.ADRESSE_LIGNE1
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		IF rec_site_f.VILLE IS NULL THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_030');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'VILLE'
							  ,rec_site_f.VILLE
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		
		IF rec_site_f.CODE_POSTAL IS NULL THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_031');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'CODE_POSTAL'
							  ,rec_site_f.CODE_POSTAL
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		
		IF rec_site_f.STATUT_SITE_FOURNISSEUR IS NULL THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_032');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'STATUT_SITE_FOURNISSEUR'
							  ,rec_site_f.STATUT_SITE_FOURNISSEUR
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		  
		ELSE IF rec_site_f.STATUT_SITE_FOURNISSEUR not in ( 'ACTIF' ,'INACTIF') THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_033','STATUT_FOURNISSEUR',rec_site_f.STATUT_SITE_FOURNISSEUR);
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'STATUT_SITE_FOURNISSEUR'
							  ,rec_site_f.STATUT_SITE_FOURNISSEUR
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		END IF;
		
		IF rec_site_f.FONCTION_ACHATS IS NULL THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_034');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'FONCTION_ACHATS'
							  ,rec_site_f.FONCTION_ACHATS
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		ELSE IF rec_site_f.FONCTION_ACHATS not in ('N','Y') THEN
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_035','FONCTION_ACHATS',rec_site_f.FONCTION_ACHATS);
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'FONCTION_ACHATS'
							  ,rec_site_f.FONCTION_ACHATS
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		END IF;
	--- debut SHA 
		
		IF rec_site_f.FONCTION_CARTE_ACHAT IS NULL THEN
			  v_flag_erreur_lignes := TRUE;
				  l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_038');
				ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'FONCTION_CARTE_ACHAT'
							  ,rec_site_f.FONCTION_CARTE_ACHAT
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		ELSE IF rec_site_f.FONCTION_CARTE_ACHAT not in ('N','Y') THEN
			v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_039','CARTE_ACHAT',rec_site_f.FONCTION_CARTE_ACHAT);
			  ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'FONCTION_CARTE_ACHAT'
							  ,rec_site_f.FONCTION_CARTE_ACHAT
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		END IF;
		
		IF rec_site_f.EMAIL_ACHAT IS NULL and rec_site_f.FONCTION_ACHATS = 'Y' THEN
			v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_040');
			  ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'LIGNES'
							  ,'DKA_IPOFRS_LIGNES'
							  --,NULL
							  ,rec_site_f.RECORD_ID
							  ,'EMAIL'
							  ,rec_site_f.EMAIL_ACHAT
							  ,'E'
							  ,l_message
							);
				DKA_TOOLS_PKG.put_log_message(l_message);
		ELSE IF rec_site_f.EMAIL_ACHAT IS not NULL then
			v_mode_notification := 'EMAIL';
		END IF;
		END IF;
		
		
		---- Comptes fournisseur, d’acompte et d’effet à payer (bloc Comptabilité) 
		  BEGIN
		  SELECT aps.vendor_type_lookup_code , attribute2 
		  into  v_type_fournisseur , v_code_partenaire
		  FROM ap_suppliers aps
		  where aps.segment1 = rec_site_f.num_fournisseur;
		  EXCEPTION
				WHEN NO_DATA_FOUND THEN
				v_type_fournisseur := null;
		  END ;
		  IF v_type_fournisseur IS NULL THEN 
			   BEGIN
			   SELECT aps.type , aps.code_partenaire
			   into  v_type_fournisseur , v_code_partenaire 
			   FROM  DKA_IPOFRS_ENTETES aps
			   where aps.num_fournisseur = rec_site_f.num_fournisseur
			   AND   aps.STATUT = 'VALIDATED'
			   and rownum<2;
			   EXCEPTION
				WHEN NO_DATA_FOUND THEN
				v_type_fournisseur := null;
			   END;
		  END IF ; 
		  Begin 
		  
			  select ACCTS_PAY_CODE_COMBINATION_ID 
				,PREPAY_CODE_COMBINATION_ID 
				,FUTURE_DATED_PAYMENT_CCID 
		  INTO 
				v_compte_fournisseur
			   ,v_compte_acompte
			   ,v_compte_effet
			   
		  from FINANCIALS_SYSTEM_PARAMS_ALL aspa 
			  ,HR_OPERATING_UNITS hr
			  
		  where aspa.SET_OF_BOOKS_ID = hr.SET_OF_BOOKS_ID
		  AND   name like 'REF9999';
		
		END;
		
		 if v_compte_fournisseur is null then 
		 v_flag_erreur_lignes := TRUE;
		  l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_046','COMPTE_FOURNISSEUR',v_compte_fournisseur);
									ins_prog_message(  g_import_request_id
													  ,'DKA_IPOFRS_IVALUA_PKG'
													  ,'LIGNES'
													  ,'DKA_IPOFRS_LIGNES'
													  --,NULL
													  ,rec_site_f.RECORD_ID
													  ,'compte fournisseur'
													  ,v_compte_fournisseur
													  ,'E'
													  ,l_message
													);
													
		 ELSE 
			BEGIN
			select      '1' ,
									segment1,
									segment2,
									segment3,
									segment4,
									segment5,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
									v_compte_actif,
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
			from gl_code_combinations
			where  code_combination_id = v_compte_fournisseur
			and enabled_flag ='Y'
			and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);
			EXCEPTION WHEN OTHERS THEN 
			v_compte_actif := null;
			END;
			
			if v_compte_actif is null then 
				v_flag_erreur_lignes := TRUE;
				l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_046','COMPTE_FOURNISSEUR',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
									ins_prog_message(  g_import_request_id
													  ,'DKA_IPOFRS_IVALUA_PKG'
													  ,'LIGNES'
													  ,'DKA_IPOFRS_LIGNES'
													  --,NULL
													  ,rec_site_f.RECORD_ID
													  ,'compte fournisseur'
													  ,v_compte_fournisseur
													  ,'E'
													  ,l_message
													);
													
			END IF ; 
		 END IF ; 
		 
		 if v_compte_acompte is null then 
		 v_flag_erreur_lignes := TRUE;
		 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_047','COMPTE_ACOMPTE',v_compte_acompte);
									ins_prog_message(  g_import_request_id
													  ,'DKA_IPOFRS_IVALUA_PKG'
													  ,'LIGNES'
													  ,'DKA_IPOFRS_LIGNES'
													  --,NULL
													  ,rec_site_f.RECORD_ID
													  ,'compte ACOMPTE'
													  ,v_compte_acompte
													  ,'E'
													  ,l_message
													);
		 ELSE 
			BEGIN
			select                  '1' ,
									segment1,
									segment2,
									segment3,
									segment4,
									segment5,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
									v_compte_actif,
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
			
			from gl_code_combinations
			where  code_combination_id = v_compte_acompte
			and enabled_flag ='Y'
			and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);
			EXCEPTION WHEN OTHERS THEN 
			v_compte_actif := null;
			END;
			
			if v_compte_actif is null then 
				 v_flag_erreur_lignes := TRUE;
				 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_047','COMPTE_ACOMPTE',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
									ins_prog_message(  g_import_request_id
													  ,'DKA_IPOFRS_IVALUA_PKG'
													  ,'LIGNES'
													  ,'DKA_IPOFRS_LIGNES'
													  --,NULL
													  ,rec_site_f.RECORD_ID
													  ,'compte Acompte'
													  ,v_compte_acompte
													  ,'E'
													  ,l_message
													);
													
			END IF ; 
		 END IF ;
		 
		 if v_compte_effet is null then
		 v_flag_erreur_lignes := TRUE;
		 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_048','COMPTE_EFFET',v_compte_effet);
									ins_prog_message(  g_import_request_id
													  ,'DKA_IPOFRS_IVALUA_PKG'
													  ,'LIGNES'
													  ,'DKA_IPOFRS_LIGNES'
													  --,NULL
													  ,rec_site_f.RECORD_ID
													  ,'compte effet'
													  ,v_compte_effet
													  ,'E'
													  ,l_message
													);
		 ELSE 
		  BEGIN
				
			SELECT                 
									   '1' ,
									segment1,
									segment2,
									segment3,
									segment4,
									segment5,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
									v_compte_actif,
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
			
			from gl_code_combinations
			where  code_combination_id = v_compte_effet
			and enabled_flag ='Y'
			and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);
			EXCEPTION WHEN OTHERS THEN 
			v_compte_actif := null;
			END;
			
			if v_compte_actif is null then 
				 v_flag_erreur_lignes := TRUE;
				 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_048','COMPTE_EFFET',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
									ins_prog_message(  g_import_request_id
													  ,'DKA_IPOFRS_IVALUA_PKG'
													  ,'LIGNES'
													  ,'DKA_IPOFRS_LIGNES'
													  --,NULL
													  ,rec_site_f.RECORD_ID
													  ,'compte effet'
													  ,v_compte_effet
													  ,'E'
													  ,l_message
													);
													
			END IF ; 
		 END IF; 
		
		
		IF  v_type_fournisseur in ('PARTENAIRE' , 'EXTERNAL  PARTNER') then 
		
		-- Récupération nouveau compte fournisseur
						  BEGIN
						   SELECT   
									
									segment1,
									segment2,
									'401050',
									segment4,
									'XXX'||v_code_partenaire,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
								   
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
								FROM
									gl_code_combinations
								WHERE
									code_combination_id = v_compte_fournisseur
									and ENABLED_FLAG    = 'Y'
									and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);

						  EXCEPTION
						  WHEN OTHERS THEN
									NULL;
						  END;

						  --Compte GL founisseur
						  dka_tools_pkg.get_code_combination_id(
													  pv_segment1  => vn_segment1,
													  pv_segment2  => vn_segment2,
													  pv_segment3  => vn_segment3,
													  pv_segment4  => vn_segment4,
													  pv_segment5  => vn_segment5,
													  pv_segment6  => vn_segment6,
													  pv_segment7  => vn_segment7,
													  pv_segment8  => vn_segment8,
													  pv_segment9  => vn_segment9,
													  pv_segment10 => vn_segment10,
													  pv_segment11 => vn_segment11,
													  pv_segment12 => vn_segment12,
													  pn_code_combination_id=> vn_ACCTS_PAY_CCID,
													  pv_errbuf => vv_errbuf,
													  pn_retcode => vn_retcode);

							IF
								vn_retcode != 0
							THEN
								BEGIN
									v_flag_erreur_lignes := TRUE;
									l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_046','COMPTE_FOURNISSEUR',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
									ins_prog_message(  g_import_request_id
													  ,'DKA_IPOFRS_IVALUA_PKG'
													  ,'LIGNES'
													  ,'DKA_IPOFRS_LIGNES'
													  --,NULL
													  ,rec_site_f.RECORD_ID
													  ,'compte fournisseur'
													  ,vn_ACCTS_PAY_CCID
													  ,'E'
													  ,l_message
													);
									DKA_TOOLS_PKG.put_log_message(l_message);
								END;
							END IF;
							
							
		-- Récupération nouveau compte Acompte
						  BEGIN
								SELECT
									segment1,
									segment2,
									segment3,
									segment4,
									'XXX'||v_code_partenaire,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
									
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
								FROM
									gl_code_combinations
								WHERE
									code_combination_id = v_compte_acompte
									and ENABLED_FLAG    = 'Y'
									and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);

						  EXCEPTION
						  WHEN OTHERS THEN
									NULL;
						  END;

						  --Compte GL ACOMPTE
						  dka_tools_pkg.get_code_combination_id(
													  pv_segment1  => vn_segment1,
													  pv_segment2  => vn_segment2,
													  pv_segment3  => vn_segment3,
													  pv_segment4  => vn_segment4,
													  pv_segment5  => vn_segment5,
													  pv_segment6  => vn_segment6,
													  pv_segment7  => vn_segment7,
													  pv_segment8  => vn_segment8,
													  pv_segment9  => vn_segment9,
													  pv_segment10 => vn_segment10,
													  pv_segment11 => vn_segment11,
													  pv_segment12 => vn_segment12,
													  pn_code_combination_id=> vn_PREPAY_CCID,
													  pv_errbuf => vv_errbuf,
													  pn_retcode => vn_retcode);

			  IF
				  vn_retcode != 0
			  THEN
				  BEGIN
								  v_flag_erreur_lignes := TRUE;
									l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_047','COMPTE_ACOMPTE',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
					 ins_prog_message(  g_import_request_id
													   ,'DKA_IPOFRS_IVALUA_PKG'
													   ,'LIGNES'
													   ,'DKA_IPOFRS_LIGNES'
													   --,NULL
													   ,rec_site_f.RECORD_ID
													   ,'compte Acompte'
													   ,vn_PREPAY_CCID
													   ,'E'
													   ,l_message
										);
					 DKA_TOOLS_PKG.put_log_message(l_message);
				  END;
			   END IF;
		
		-- Récupération nouveau effet à payer 
						  BEGIN
								SELECT
									segment1,
									segment2,
									segment3,
									segment4,
									'XXX'||v_code_partenaire,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
								FROM
									gl_code_combinations
								WHERE
									code_combination_id = v_compte_effet
									and ENABLED_FLAG    = 'Y'
									and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);

						  EXCEPTION
						  WHEN OTHERS THEN
									NULL;
						  END;

						  --Compte GL effet 
						  dka_tools_pkg.get_code_combination_id(
													  pv_segment1  => vn_segment1,
													  pv_segment2  => vn_segment2,
													  pv_segment3  => vn_segment3,
													  pv_segment4  => vn_segment4,
													  pv_segment5  => vn_segment5,
													  pv_segment6  => vn_segment6,
													  pv_segment7  => vn_segment7,
													  pv_segment8  => vn_segment8,
													  pv_segment9  => vn_segment9,
													  pv_segment10 => vn_segment10,
													  pv_segment11 => vn_segment11,
													  pv_segment12 => vn_segment12,
													  pn_code_combination_id=> vn_future_CCID,
													  pv_errbuf => vv_errbuf,
													  pn_retcode => vn_retcode);

			  IF
				  vn_retcode != 0
			  THEN
					BEGIN
								v_flag_erreur_lignes := TRUE;
								  l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_048','COMPTE_EFFET',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
								  ins_prog_message(  g_import_request_id
																 ,'DKA_IPOFRS_IVALUA_PKG'
																 ,'LIGNES'
																 ,'DKA_IPOFRS_LIGNES'
																 --,NULL
																 ,rec_site_f.RECORD_ID
																 ,'compte Effet'
																 ,vn_future_CCID
																 ,'E'
																 ,l_message
									 );
								DKA_TOOLS_PKG.put_log_message(l_message);
					END;
			  END IF;	
		ELSE  
			
			vn_future_CCID    := v_compte_effet;
			vn_ACCTS_PAY_CCID := v_compte_fournisseur;
			vn_PREPAY_CCID    := v_compte_acompte;
		END IF;
		
		-- EDB330 ARA
	  v_etape:= 'Validation Echeance SITES  ';
	  DKA_TOOLS_PKG.put_log_message(v_etape);

	  BEGIN
	  select count(1)
	  INTO vn_echeance
	  from(
		select *
		from ap_terms apt
		where name = replace(replace(rec_site_f.ECHEANCE, chr(13), ''), chr(10), ' ')
	  );
	  
	  IF vn_echeance = 0 THEN
		v_flag_erreur_lignes := TRUE;
		l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_049','ECHEANCE',rec_site_f.ECHEANCE);				
		
		ins_prog_message(  g_import_request_id
							 ,'DKA_IPOFRS_IVALUA_PKG'
							 ,'LIGNES'
							 ,'DKA_IPOFRS_LIGNES'
							 --,NULL
							 ,rec_site_f.RECORD_ID
							 ,'ECHEANCE'
							 ,rec_site_f.ECHEANCE
							 ,'E'
							 ,l_message
									 );
		DKA_TOOLS_PKG.put_log_message(l_message);
	  END IF;
	  END;
		
		-- END EDB330
		
		IF NOT v_flag_erreur_lignes THEN
				
				UPDATE DKA_IPOFRS_LIGNES
				SET  STATUT      		= 'VALIDATED'
					,mode_notification  = v_mode_notification
							,compte_fournisseur = vn_ACCTS_PAY_CCID
							,compte_effet       = vn_future_CCID
							,compte_acompte     = vn_PREPAY_CCID
					,LAST_UPDATE_DATE  	= SYSDATE
					,LAST_UPDATED_BY   	= g_user_id	
					,request_id        = g_request_id
				WHERE RECORD_ID         = rec_site_f.RECORD_ID
				;
				
			  ELSE -- en cas d'erreur
			  g_nb_lignes_traite_rejected1 := g_nb_lignes_traite_rejected1 + 1;
				UPDATE DKA_IPOFRS_LIGNES
				SET   STATUT 			= 'REJECTED1'   
					 ,LAST_UPDATE_DATE  = SYSDATE
					 ,LAST_UPDATED_BY   = g_user_id
					 ,request_id        = g_request_id
				WHERE RECORD_ID 		= rec_site_f.RECORD_ID
				;
			  p_retcode := 1;
	  END IF; 
		
		END LOOP ; --site 
		
		
		COMMIT;
		
		
		FOR rec_homologation IN cur_homologation  LOOP
	  
		  g_nb_homologation_traite   := g_nb_homologation_traite +1;
		  v_flag_erreur_homologation := FALSE;
		  
			BEGIN
					select '1'
					into vv_exist_h1
					from ap_supplier_sites_all assa,
						 ap_suppliers          asa ,
						   hr_organization_units hr
					where asa.segment1 = rec_homologation.num_fournisseur
					and   assa.vendor_site_code = rec_homologation.NOM_ADRESSE_SITE
					and   assa.vendor_id = asa.vendor_id
					and   hr.organization_id = assa.org_id
					and   hr.name            = 'REF9999';
					EXCEPTION
						 WHEN too_many_rows THEN
							 vv_exist_h1 := '1';
						 WHEN OTHERS THEN
							 vv_exist_h1 := NULL;
						 
			  END;
		
					
			
		   BEGIN
					select '1'
					into vv_exist_h2
					from ap_supplier_sites_all assa,
						 ap_suppliers          asa ,
						   hr_organization_units hr
					where asa.segment1 = rec_homologation.num_fournisseur
					and   assa.attribute4 = rec_homologation.ID_IVALUA_SITE_FOURNISSEUR
					and   assa.vendor_id = asa.vendor_id
					and   hr.organization_id = assa.org_id
					and   hr.name            = 'REF9999';
					EXCEPTION
						 WHEN too_many_rows THEN
							 vv_exist_h2 := '1';
						 WHEN OTHERS THEN
							 vv_exist_h2 := NULL;
						 
			  END;
		
		  BEGIN
			select '1'
			into vv_exist_h3
			FROM
			  DKA_IPOFRS_LIGNES  dih
			WHERE   dih.ID_IVALUA_SITE_FOURNISSEUR = rec_homologation.ID_IVALUA_SITE_FOURNISSEUR
			AND     dih.NOM_ADRESSE_SITE           = rec_homologation.NOM_ADRESSE_SITE
			AND     dih.NUM_FOURNISSEUR            = rec_homologation.NUM_FOURNISSEUR
			AND     dih.STATUT ='VALIDATED'
			;
				  EXCEPTION
				  WHEN OTHERS THEN
				  vv_exist_h3 := null;
		  END;
		  
		  IF rec_homologation.NUM_FOURNISSEUR IS NULL 
		 THEN 
			v_flag_erreur_homologation := TRUE;
			l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOFRS_005');
			ins_prog_message(  g_import_request_id
							  ,'DKA_IPOFRS_IVALUA_PKG'
							  ,'HOMOLOGATION'
							  ,'DKA_IPOFRS_HOMOLOGATIONS'
							  --,NULL
							  ,rec_homologation.RECORD_ID
							  ,'NUM_FOURNISSEUR'
							  ,rec_homologation.NUM_FOURNISSEUR
							  ,'E'
							  ,l_message
							);
					DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
		
		  
		  if rec_homologation.NOM_ADRESSE_SITE is null then 

			 v_flag_erreur_homologation := TRUE;
			 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_025');		
				
							ins_prog_message(  g_import_request_id
														,'DKA_IPOFRS_IVALUA_PKG'
														,'HOMOLOGATION'
														,'DKA_IPOFRS_HOMOLOGATIONS'
														--,NULL
														,rec_homologation.RECORD_ID
														,'num_fournisseur'
														,rec_homologation.num_fournisseur
														,'E'
														,l_message
							);	
					DKA_TOOLS_PKG.put_log_message(l_message);
		END IF;
			
		IF    rec_homologation.ID_IVALUA_SITE_FOURNISSEUR IS NULL THEN
							v_flag_erreur_homologation := TRUE;
							l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_026');
							ins_prog_message(  g_import_request_id
														,'DKA_IPOFRS_IVALUA_PKG'
														,'HOMOLOGATION'
														,'DKA_IPOFRS_HOMOLOGATIONS'
														--,NULL
														,rec_homologation.RECORD_ID
														,'ID_IVALUA_SITE_FOURNISSEUR'
														,rec_homologation.ID_IVALUA_SITE_FOURNISSEUR
														,'E'
														,l_message
											 );
							DKA_TOOLS_PKG.put_log_message(l_message);
		END IF ; 

		IF
			vv_exist_h1 IS NULL AND vv_exist_h2 IS NULL  and vv_exist_h3 IS NULL THEN
							v_flag_erreur_homologation := TRUE;
							l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_042','SITE_FOURNISSEUR',rec_homologation.NOM_ADRESSE_SITE);
							ins_prog_message(  g_import_request_id
														,'DKA_IPOFRS_IVALUA_PKG'
														,'HOMOLOGATION'
														,'DKA_IPOFRS_HOMOLOGATIONS'
														--,NULL
														,rec_homologation.RECORD_ID
														,'site fournisseur'
														,rec_homologation.NOM_ADRESSE_SITE
														,'E'
														,l_message
											 );
							DKA_TOOLS_PKG.put_log_message(l_message);
			END IF ; 
			
		IF 	rec_homologation.PERIMETRE_HOMOLOGATION is NULL then 
			v_flag_erreur_homologation := TRUE;
			l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_043');
			ins_prog_message(  g_import_request_id
										,'DKA_IPOFRS_IVALUA_PKG'
										,'HOMOLOGATION'
										,'DKA_IPOFRS_HOMOLOGATIONS'
										--,NULL
										,rec_homologation.RECORD_ID
										,'UNITE_OPERATIONNELLE'
										,rec_homologation.PERIMETRE_HOMOLOGATION
										,'E'
										,l_message
							  );
						  DKA_TOOLS_PKG.put_log_message(l_message);
		ELSE 
			
		BEGIN
			 SELECT  '1'
			 into v_uo
		 FROM
			hr_operating_units
		 WHERE
			organization_id IN (
				SELECT
					organization_id
				FROM
					per_security_organizations
				WHERE
					security_profile_id = (
						SELECT
							security_profile_id
						FROM
							per_security_profiles
						WHERE
							security_profile_name = 'DKA_TOUT'
					)
							   )
			and name =  rec_homologation.PERIMETRE_HOMOLOGATION ;
		EXCEPTION WHEN OTHERS THEN 
			BEGIN
			v_flag_erreur_homologation := TRUE;
			l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_044','UO',rec_homologation.PERIMETRE_HOMOLOGATION);
			ins_prog_message(  g_import_request_id
										,'DKA_IPOFRS_IVALUA_PKG'
										,'HOMOLOGATION'
										,'DKA_IPOFRS_HOMOLOGATIONS'
										--,NULL
										,rec_homologation.RECORD_ID
										,'UNITE_OPERATIONNELLE'
										,rec_homologation.PERIMETRE_HOMOLOGATION
										,'E'
										,l_message
							  );
							  DKA_TOOLS_PKG.put_log_message(l_message);
			END;
		END;
		
		END IF;  
		
		IF NOT v_flag_erreur_homologation THEN
				
				UPDATE DKA_IPOFRS_HOMOLOGATIONS
				SET  STATUT      		= 'VALIDATED'
					,LAST_UPDATE_DATE  	= SYSDATE
					,LAST_UPDATED_BY   	= g_user_id	
					,request_id        = g_request_id				
				WHERE RECORD_ID         = rec_homologation.RECORD_ID
				
				;
			  ELSE -- en cas d'erreur
					g_nb_homo_traite_rejected1 := g_nb_homo_traite_rejected1 + 1;
				UPDATE DKA_IPOFRS_HOMOLOGATIONS
				SET   STATUT 			= 'REJECTED1'   
					 ,LAST_UPDATE_DATE  = SYSDATE
					 ,LAST_UPDATED_BY   = g_user_id	
					 ,request_id        = g_request_id				 
				WHERE RECORD_ID 		= rec_homologation.RECORD_ID
				;
			  p_retcode := 1;
			  END IF; 
		
		COMMIT;
		END LOOP; -- homologation
		
		EXCEPTION
			WHEN OTHERS
			THEN
				p_retcode   := 2;
				p_errbuf    := 'validate_data : ' ||SQLERRM;
				Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
				Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure validate_data : EXCEPTION OTHERS ');
	  END validate_data; 
	/*
	 *************************************************************************
	 * PROCEDURE NAME : import_data
	 * 
	 * DESCRIPTION
	 *  Procédure de création  et mise à jour des fournisseur 
	 *
	 * PARAMETERS
	 * ==========
	 * NAME                 DESCRIPTION
	.* -------------------- ---------------------------------------------------
	 * p_errbuf            Retour de message éventuel
	 * p_retcode           Statut du traitement en sortie
	 ************************************************************************
	 */  
		PROCEDURE import_data( p_errbuf        OUT VARCHAR2,
							 p_retcode       OUT NUMBER
							) 
		IS
		----Variables
		  p_api_version          number;
		  p_init_msg_list        varchar2(200);
		  p_commit               varchar2(200);
		  p_validation_level     number;
		  x_return_status        varchar2(200);
		  x_msg_count            number;
		  x_msg_data             varchar2(200);
		  l_msg                  varchar2(200);
		  l_message   VARCHAR2(2000);
		  v_compte_actif       VARCHAR2(2);
		  v_submitted_login_id    fnd_logins.submitted_login_id%type;
		  lr_vend_create          ap_vendor_pub_pkg.r_vendor_rec_type;
		  lr_vend_update          ap_vendor_pub_pkg.r_vendor_rec_type;
		  --lr_ex_vend             DKA_IPOFRS_ENTETES%rowtype;
		  p_ext_payee_tab        iby_disbursement_setup_pub.external_payee_tab_type;
		  p_ext_payee_id_tab     iby_disbursement_setup_pub.Ext_Payee_ID_Tab_Type;
		  vv_ext_payee_id        IBY_EXTERNAL_PAYEES_ALL.ext_payee_id%type;
		  vv_payee_party_id      IBY_EXTERNAL_PAYEES_ALL.payee_party_id%type;
		  x_vendor_id            number;
		  x_party_id             number;
		  v_parent_supplier_id   number;
		  v_vendor_id            ap_suppliers.vendor_id%type;
		  p_vendor_num           varchar2(80);
		  vv_exist               VARCHAR2(1);
		  v_uo                   VARCHAR2(1);
		  vv_exist_f             VARCHAR2(1);
		  vv_exist_h1            VARCHAR2(1);
		  vv_exist_h2            VARCHAR2(1);
		  vn_retcode             PLS_INTEGER := 0;
		  vv_errbuf              VARCHAR2(500);	
		  vn_validation_level    NUMBER;
		  vv_return_status       VARCHAR2(200);
		  vn_msg_count           NUMBER;
		  vv_msg_data            VARCHAR2(1000);
		  vv_commit              VARCHAR2(200);
		  vn_party_site_id       ap_supplier_sites_all.party_site_id%type;
		  v_party_id             ap_suppliers.party_id%type;
		  v_code_partenaire      ap_suppliers.attribute2%type;
		  vn_location_id         NUMBER;
		  i                      NUMBER   := 0 ;
		  v_resp_appl_id 	fnd_responsibility.application_id%TYPE;
		  v_resp_id   fnd_responsibility.responsibility_id%TYPE;
		  v_org_id               hr_organization_units.organization_id%TYPE;
		  lr_vendor_site_create    ap_vendor_pub_pkg.r_vendor_site_rec_type;
		  lr_vendor_site_update    ap_vendor_pub_pkg.r_vendor_site_rec_type;
		  v_compte_acompte     gl_code_combinations.code_combination_id%TYPE;
		  v_compte_fournisseur gl_code_combinations.code_combination_id%TYPE;
		  v_compte_effet       gl_code_combinations.code_combination_id%TYPE;
		  vn_PREPAY_CCID       gl_code_combinations.code_combination_id%TYPE;
		  vn_ACCTS_PAY_CCID    gl_code_combinations.code_combination_id%TYPE;
		  vn_future_CCID       gl_code_combinations.code_combination_id%TYPE;
		  vn_segment1          gl_code_combinations.segment1%TYPE;
		  vn_segment2          gl_code_combinations.segment2%TYPE;
		  vn_segment3          gl_code_combinations.segment3%TYPE;
		  vn_segment4          gl_code_combinations.segment4%TYPE;
		  vn_segment5          gl_code_combinations.segment5%TYPE;
		  vn_segment6          gl_code_combinations.segment6%TYPE;
		  vn_segment7          gl_code_combinations.segment7%TYPE;
		  vn_segment8          gl_code_combinations.segment8%TYPE;
		  vn_segment9          gl_code_combinations.segment9%TYPE;
		  vn_segment10         gl_code_combinations.segment10%TYPE;
		  vn_segment11         gl_code_combinations.segment11%TYPE;
		  vn_segment12         gl_code_combinations.segment12%TYPE;
		  vn_vendor_id           ap_suppliers.vendor_id%TYPE;
		  p_vendor_id            NUMBER;
		  vr_site_rowtype        ap_supplier_sites_all%ROWTYPE;
		  vv_site_rowtype        DKA_IPOFRS_LIGNES%ROWTYPE;
		  l_payee_upd_status     iby_disbursement_setup_pub.ext_payee_update_tab_type;
		  l_payee_upd_id         iby_disbursement_setup_pub.Ext_Payee_ID_Tab_Type;
		  v_fonction_achat       DKA_IPOFRS_LIGNES.FONCTION_ACHATS%TYPE;
		  v_payee_party_id           IBY_EXTERNAL_PAYEES_ALL.payee_party_id%type;
		  v_vendor_site_id  ap_supplier_sites_all.vendor_site_id%type;
		  v_inactive_date_site   DATE;
		  v_inactive_date_fournisseur DATE;
		  v_status_fournisseur   ap_supplier_sites_all.ATTRIBUTE2%TYPE;
		  v_location_id          ap_supplier_sites_all.location_id%TYPE;
		 --- appel duplication en masse
		  v_statut                  VARCHAR2(2); 
		  l_request_id              NUMBER;
		  l_application_code        VARCHAR2(50) := 'DKA';
		  l_conc_program            VARCHAR2(50) := 'DKA_SAPFRSDUPLI_MASSE';
		  l_execute_code            BOOLEAN;
		  l_req_interval            NUMBER := 30;
		  l_req_max_wait            NUMBER := 999999;
		  l_req_ret_code            NUMBER;
		  l_req_phase               VARCHAR2(255);
		  l_req_status              VARCHAR2(255);
		  l_req_dev_phase           VARCHAR2(255);
		  l_req_dev_status          VARCHAR2(255);
		  l_req_message             VARCHAR2(255);
		  vf_errbuf                 VARCHAR2(500);
		  vf_retcode                NUMBER;
		  v_duplication             NUMBER;
		   ----- FLAG ------ 
		  v_flag_erreur_creation BOOLEAN;
		  v_flag_erreur_site     BOOLEAN;
		  vv_vendor_site_id      ap_supplier_sites_all.vendor_site_id%type; 
		  v_party_site_id        ap_supplier_sites_all.party_site_id%type; 
		  vv_party_site_id        ap_supplier_sites_all.party_site_id%type;
		  V_exist_vendor_site_id   NUMBER;
		  ----- EDB330
		  vn_term_id               NUMBER;
		  
		   ---------- CURSORS ----------
			CURSOR cur_fournisseur
			IS SELECT die.*
			FROM DKA_IPOFRS_ENTETES die
			WHERE die.statut = 'VALIDATED'
			;

			CURSOR cur_site_fournisseur
			IS SELECT dis.*
			FROM DKA_IPOFRS_lignes dis
			WHERE dis.statut = 'VALIDATED'
			;
			
			CURSOR cur_homologation
			IS SELECT dih.*
			FROM DKA_IPOFRS_HOMOLOGATIONS dih
			WHERE dih.statut = 'VALIDATED'
			;
			
		   
	BEGIN
		 for rec_fournisseur  IN  cur_fournisseur LOOP
			BEGIN 
				 select parent.vendor_id 
				 into v_parent_supplier_id
				 from ap_suppliers parent
				 where parent.segment1 = rec_fournisseur.NUM_SOCIETE_MERE;
				 EXCEPTION
						WHEN NO_DATA_FOUND THEN
						v_parent_supplier_id :=0;
			END;
			BEGIN
			 SELECT
					'1' , vendor_id
				INTO
					vv_exist , vn_vendor_id
				FROM
					ap_suppliers aps
				WHERE
					aps.segment1 = rec_fournisseur.num_fournisseur;

					 EXCEPTION
						 WHEN too_many_rows THEN
							 vv_exist := '1';
						 WHEN OTHERS THEN
							 vv_exist := NULL;
			END;
		   
			IF
				vv_exist IS NULL --création
			THEN
			
				
				
				 -- Assign Basic Values
		  p_api_version      := 1.0;
		  p_init_msg_list    := fnd_api.g_true;
		  p_commit           := fnd_api.g_true;
		  p_validation_level := fnd_api.g_valid_level_full;
		  -- Hold Details
		  lr_vend_create.hold_flag              := null;
		  lr_vend_create.purchasing_hold_reason := null;
		  lr_vend_create.hold_by                := null;
		  lr_vend_create.hold_date              := null;

		  -- organisation
		  lr_vend_create.vendor_id               := null;
		  lr_vend_create.vendor_name             := rec_fournisseur.NOM_FOURNISSEUR ;
		  lr_vend_create.vendor_name_alt         := rec_fournisseur.AUTRE_NOM_FOURNISSEUR;
		  lr_vend_create.sic_code                := rec_fournisseur.CODE_NAF;
		  lr_vend_create.vendor_type_lookup_code := rec_fournisseur.type;
		  lr_vend_create.start_date_active       := sysdate;
		  lr_vend_create.FEDERAL_REPORTABLE_FLAG := rec_fournisseur.FEDERAL;

		  -- Blank values
		  lr_vend_create.party_id                  := null;
		  lr_vend_create.parent_party_id           := null;
		  lr_vend_create.url                       := null;
		  lr_vend_create.supplier_notif_method     := null;
		  lr_vend_create.remittance_email          := null;
		  lr_vend_create.ceo_name                  := null;
		  lr_vend_create.ceo_title                 := null;
		  lr_vend_create.inventory_organization_id := null;
		  lr_vend_create.default_terms_id          := null;
		  lr_vend_create.vendor_interface_id       := null;
		  lr_vend_create.validation_number         := null;

		  -- Other Values
		  lr_vend_create.one_time_flag                  := rec_fournisseur.OCCASIONNEL;
		  lr_vend_create.parent_vendor_id               := v_parent_supplier_id;
		  lr_vend_create.jgzz_fiscal_code               := rec_fournisseur.ID_FISCALE;
		  lr_vend_create.type_1099                      := rec_fournisseur.CODE_DAS2;
		  lr_vend_create.minority_group_lookup_code     := rec_fournisseur.SOUS_TYPE;
		  lr_vend_create.vat_registration_num           := rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE;
		  lr_vend_create.tax_reference                  := rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE;
		  -- Attribute Details
		  lr_vend_create.attribute_category             := rec_fournisseur.contexte;
		  lr_vend_create.attribute1                     := rec_fournisseur.FOURNISSEUR_SERVICES;
		  lr_vend_create.attribute2                     := rec_fournisseur.CODE_PARTENAIRE;
		  lr_vend_create.attribute3                     := rec_fournisseur.FOURNISSEUR_COMBUSTIBLES;
		  lr_vend_create.attribute4                     := rec_fournisseur.CODE_ACCORD;
		  lr_vend_create.attribute5                     := rec_fournisseur.FOURNISSEUR_VEHICULES;
		  lr_vend_create.attribute6                     := rec_fournisseur.CODE_SURTAXE_COM;
		  
		  -- Call the API
			ap_vendor_pub_pkg.create_vendor(p_api_version      => p_api_version,
										  p_init_msg_list    => p_init_msg_list,
										  p_commit           => p_commit,
										  p_validation_level => p_validation_level,
										  x_return_status    => x_return_status,
										  x_msg_count        => x_msg_count,
										  x_msg_data         => x_msg_data,
										  p_vendor_rec       => lr_vend_create,
										  x_vendor_id        => x_vendor_id,
										  x_party_id         => x_party_id);


		  IF (x_return_status <> FND_API.G_RET_STS_SUCCESS)
		  THEN     
			FOR i IN 1..FND_MSG_PUB.COUNT_MSG LOOP
			  l_msg := FND_MSG_PUB.get( p_msg_index => i,
										p_encoded   => FND_API.G_FALSE
									  );   
				UPDATE DKA_IPOFRS_ENTETES
				SET   STATUT 			= 'REJECTED2'   
					 ,LAST_UPDATE_DATE  = SYSDATE
					 ,LAST_UPDATED_BY   = g_user_id
					 ,request_id        = g_request_id				 
				WHERE RECORD_ID 		= rec_fournisseur.RECORD_ID
				;

				l_message := substr(fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);
				ins_prog_message(  g_import_request_id
								  ,'DKA_IPOFRS_IVALUA_PKG'
								  ,'ENTETE'
								  ,'DKA_IPOFRS_ENTETES'
								  --,NULL
								  ,rec_fournisseur.RECORD_ID
								  ,'NUM_FOURNISSEUR'
								  ,rec_fournisseur.NUM_FOURNISSEUR
								  ,'E'
								  ,substr('Une erreur est survenue lors de création du fournisseur '
														  ||' - '||l_message,1,500)
								);			
				
				g_nb_entetes_traite_rejected2 := g_nb_entetes_traite_rejected2 + 1;
				 p_retcode := 1;
			END LOOP;
		  ELSE
			update ap.ap_suppliers
			   set segment1 = rec_fournisseur.NUM_FOURNISSEUR
			 where vendor_id = x_vendor_id;
			 
			UPDATE DKA_IPOFRS_ENTETES
				SET   STATUT 			= 'COMPLETE'   
					 ,LAST_UPDATE_DATE  = SYSDATE
					 ,LAST_UPDATED_BY   = g_user_id
					 ,request_id        = g_request_id				 
				WHERE RECORD_ID 		= rec_fournisseur.RECORD_ID
				;
			g_nb_entetes_traite_succes := g_nb_entetes_traite_succes + 1;
		  END IF;
		  
		ELSE --Mise à jour
		 BEGIN
			select party_id , attribute2
			into v_party_id	, v_code_partenaire	
			from
			ap_suppliers
			where vendor_id = vn_vendor_id;
			EXCEPTION WHEN OTHERS THEN 
			v_code_partenaire := null;
			v_party_id           := null;

		END;	
		 
			 -- Assign Basic Values
			p_api_version      := 1.0;
			p_init_msg_list    := fnd_api.g_true;
			p_commit           := fnd_api.g_false;
			p_validation_level := fnd_api.g_valid_level_full;
			vv_return_status    := NULL;
			vn_msg_count        := NULL;
			vv_msg_data         := NULL;
			lr_vend_update.vendor_id                      := vn_vendor_id;
			lr_vend_update.vendor_name             	   := rec_fournisseur.NOM_FOURNISSEUR ;
			lr_vend_update.vendor_name_alt         	   := rec_fournisseur.AUTRE_NOM_FOURNISSEUR;
			lr_vend_update.sic_code                	   := rec_fournisseur.CODE_NAF;
			lr_vend_update.one_time_flag                  := rec_fournisseur.OCCASIONNEL;
			lr_vend_update.jgzz_fiscal_code               := rec_fournisseur.ID_FISCALE;
			lr_vend_update.vat_registration_num           := rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE;
			lr_vend_update.tax_reference                  := rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE;
			lr_vend_update.parent_vendor_id               := v_parent_supplier_id;
			-- Attribute Details
			lr_vend_update.attribute_category             := rec_fournisseur.contexte;
			lr_vend_update.attribute1                     := rec_fournisseur.FOURNISSEUR_SERVICES;
			lr_vend_update.attribute2                     := rec_fournisseur.CODE_PARTENAIRE;
			lr_vend_update.attribute3                     := rec_fournisseur.FOURNISSEUR_COMBUSTIBLES;
			lr_vend_update.attribute4                     := rec_fournisseur.CODE_ACCORD;
			lr_vend_update.attribute5                     := rec_fournisseur.FOURNISSEUR_VEHICULES;
			lr_vend_update.attribute6                     := rec_fournisseur.CODE_SURTAXE_COM;
			
			
			ap_vendor_pub_pkg.update_vendor_public (    p_api_version,
												p_init_msg_list,
												p_commit,
												p_validation_level,
												vv_return_status,
												vn_msg_count,
												vv_msg_data,
												lr_vend_update,
												vn_vendor_id           
												);

			commit;
				IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
				  UPDATE DKA_IPOFRS_ENTETES
				  SET   STATUT 			= 'COMPLETE'   
					   ,LAST_UPDATE_DATE  = SYSDATE
					   ,LAST_UPDATED_BY   = g_user_id
					   ,request_id        = g_request_id				   
				  WHERE RECORD_ID 		= rec_fournisseur.RECORD_ID
				;
		--------- Pour la suppression des champs non obligatoires
				if (rec_fournisseur.AUTRE_NOM_FOURNISSEUR is null or rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE is null 
				or v_parent_supplier_id is null or rec_fournisseur.OCCASIONNEL is null or rec_fournisseur.CODE_ACCORD is null 
				or rec_fournisseur.CODE_SURTAXE_COM is null or rec_fournisseur.contexte  is null or rec_fournisseur.ID_FISCALE is null 
				or rec_fournisseur.CODE_NAF is null or rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE is null )then  
						update ap_suppliers
						set    vendor_name_alt                = rec_fournisseur.AUTRE_NOM_FOURNISSEUR
							  ,vat_registration_num           = rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE
							  ,parent_vendor_id               = v_parent_supplier_id
							  ,one_time_flag                  = rec_fournisseur.OCCASIONNEL
							  ,attribute4                     = rec_fournisseur.CODE_ACCORD
							  ,attribute6                     = rec_fournisseur.CODE_SURTAXE_COM
							  ,attribute_category             = rec_fournisseur.contexte
							  
						where vendor_id = vn_vendor_id ; 
						
						update hz_parties 
						set    jgzz_fiscal_code              = rec_fournisseur.ID_FISCALE 
							  ,sic_code                	     = rec_fournisseur.CODE_NAF
							  ,tax_reference                 = rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE
							  ,ORGANIZATION_NAME_PHONETIC    = rec_fournisseur.AUTRE_NOM_FOURNISSEUR
						where party_id =v_party_id;
						
						update HZ_ORGANIZATION_PROFILES 
						set    tax_reference                 = rec_fournisseur.NUM_ID_INTRACOMMUNAUTAIRE
							  ,JGZZ_FISCAL_CODE              = rec_fournisseur.ID_FISCALE
							  ,ORGANIZATION_NAME_PHONETIC    = rec_fournisseur.AUTRE_NOM_FOURNISSEUR
						where party_id =v_party_id;
				END IF ; 		
				
				IF v_code_partenaire 	!= rec_fournisseur.CODE_PARTENAIRE then 
				
				BEGIN 
				  
					  select ACCTS_PAY_CODE_COMBINATION_ID 
						,PREPAY_CODE_COMBINATION_ID 
						,FUTURE_DATED_PAYMENT_CCID 
				  INTO 
						v_compte_fournisseur
					   ,v_compte_acompte
					   ,v_compte_effet
					   
				  from FINANCIALS_SYSTEM_PARAMS_ALL aspa 
					  ,HR_OPERATING_UNITS hr
					  
				  where aspa.SET_OF_BOOKS_ID = hr.SET_OF_BOOKS_ID
				  AND   name like 'REF9999';
				
				END;
		
			 if v_compte_fournisseur is null then 
			  l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_046','COMPTE_FOURNISSEUR',v_compte_fournisseur);
										ins_prog_message(  g_import_request_id
														  ,'DKA_IPOFRS_IVALUA_PKG'
														  ,'LIGNES'
														  ,'DKA_IPOFRS_ENTETES'
														  --,NULL
														  ,rec_fournisseur.RECORD_ID
														  ,'compte fournisseur'
														  ,v_compte_fournisseur
														  ,'E'
														  ,l_message
														);
														
			 ELSE 
				BEGIN
				select      '1' ,
										segment1,
										segment2,
										segment3,
										segment4,
										segment5,
										segment6,
										segment7,
										segment8,
										segment9,
										segment10,
										segment11,
										segment12
									INTO
										v_compte_actif,
										vn_segment1,
										vn_segment2,
										vn_segment3,
										vn_segment4,
										vn_segment5,
										vn_segment6,
										vn_segment7,
										vn_segment8,
										vn_segment9,
										vn_segment10,
										vn_segment11,
										vn_segment12
				from gl_code_combinations
				where  code_combination_id = v_compte_fournisseur
				and enabled_flag ='Y'
				and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);
				EXCEPTION WHEN OTHERS THEN 
				v_compte_actif := null;
				END;
				
				if v_compte_actif is null then 
					
					l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_046','COMPTE_FOURNISSEUR',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
											'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
										ins_prog_message(  g_import_request_id
														  ,'DKA_IPOFRS_IVALUA_PKG'
														  ,'LIGNES'
														  ,'DKA_IPOFRS_ENTETES'
														  --,NULL
														  ,rec_fournisseur.RECORD_ID
														  ,'compte fournisseur'
														  ,v_compte_fournisseur
														  ,'E'
														  ,l_message
														);
														
				END IF ; 
			 END IF ; 
			 
			 if v_compte_acompte is null then 
			 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_047','COMPTE_ACOMPTE',v_compte_acompte);
										ins_prog_message(  g_import_request_id
														  ,'DKA_IPOFRS_IVALUA_PKG'
														  ,'LIGNES'
														  ,'DKA_IPOFRS_ENTETES'
														  --,NULL
														  ,rec_fournisseur.RECORD_ID
														  ,'compte ACOMPTE'
														  ,v_compte_acompte
														  ,'E'
														  ,l_message
														);
			 ELSE 
				BEGIN
				select                  '1' ,
										segment1,
										segment2,
										segment3,
										segment4,
										segment5,
										segment6,
										segment7,
										segment8,
										segment9,
										segment10,
										segment11,
										segment12
									INTO
										v_compte_actif,
										vn_segment1,
										vn_segment2,
										vn_segment3,
										vn_segment4,
										vn_segment5,
										vn_segment6,
										vn_segment7,
										vn_segment8,
										vn_segment9,
										vn_segment10,
										vn_segment11,
										vn_segment12
				
				from gl_code_combinations
				where  code_combination_id = v_compte_acompte
				and enabled_flag ='Y'
				and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);
				EXCEPTION WHEN OTHERS THEN 
				v_compte_actif := null;
				END;
				
				if v_compte_actif is null then 
					
					 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_047','COMPTE_ACOMPTE',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
											'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
										ins_prog_message(  g_import_request_id
														  ,'DKA_IPOFRS_IVALUA_PKG'
														  ,'LIGNES'
														  ,'DKA_IPOFRS_ENTETES'
														  --,NULL
														  ,rec_fournisseur.RECORD_ID
														  ,'compte Acompte'
														  ,v_compte_acompte
														  ,'E'
														  ,l_message
														);
														
				END IF ; 
			 END IF ;
			 
			 if v_compte_effet is null then
			 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_048','COMPTE_EFFET',v_compte_effet);
										ins_prog_message(  g_import_request_id
														  ,'DKA_IPOFRS_IVALUA_PKG'
														  ,'LIGNES'
														  ,'DKA_IPOFRS_ENTETES'
														  --,NULL
														  ,rec_fournisseur.RECORD_ID
														  ,'compte effet'
														  ,v_compte_effet
														  ,'E'
														  ,l_message
														);
			 ELSE 
			  BEGIN
					
				SELECT                 
										   '1' ,
										segment1,
										segment2,
										segment3,
										segment4,
										segment5,
										segment6,
										segment7,
										segment8,
										segment9,
										segment10,
										segment11,
										segment12
									INTO
										v_compte_actif,
										vn_segment1,
										vn_segment2,
										vn_segment3,
										vn_segment4,
										vn_segment5,
										vn_segment6,
										vn_segment7,
										vn_segment8,
										vn_segment9,
										vn_segment10,
										vn_segment11,
										vn_segment12
				
				from gl_code_combinations
				where  code_combination_id = v_compte_effet
				and enabled_flag ='Y'
				and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);
				EXCEPTION WHEN OTHERS THEN 
				v_compte_actif := null;
				END;
				
				if v_compte_actif is null then 
					
					 l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_048','COMPTE_EFFET',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
											'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
										ins_prog_message(  g_import_request_id
														  ,'DKA_IPOFRS_IVALUA_PKG'
														  ,'LIGNES'
														  ,'DKA_IPOFRS_ENTETES'
														  --,NULL
														  ,rec_fournisseur.RECORD_ID
														  ,'compte effet'
														  ,v_compte_effet
														  ,'E'
														  ,l_message
														);
														
				END IF ; 
				END IF; 
				
			IF  rec_fournisseur.type in ('PARTENAIRE' , 'EXTERNAL  PARTNER') then 
		
		-- Récupération nouveau compte fournisseur
						  BEGIN
						   SELECT   
									
									segment1,
									segment2,
									'401050',
									segment4,
									'XXX'||v_code_partenaire,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
								   
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
								FROM
									gl_code_combinations
								WHERE
									code_combination_id = v_compte_fournisseur
									and ENABLED_FLAG    = 'Y'
									and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);

						  EXCEPTION
						  WHEN OTHERS THEN
									NULL;
						  END;

						  --Compte GL founisseur
						  dka_tools_pkg.get_code_combination_id(
													  pv_segment1  => vn_segment1,
													  pv_segment2  => vn_segment2,
													  pv_segment3  => vn_segment3,
													  pv_segment4  => vn_segment4,
													  pv_segment5  => vn_segment5,
													  pv_segment6  => vn_segment6,
													  pv_segment7  => vn_segment7,
													  pv_segment8  => vn_segment8,
													  pv_segment9  => vn_segment9,
													  pv_segment10 => vn_segment10,
													  pv_segment11 => vn_segment11,
													  pv_segment12 => vn_segment12,
													  pn_code_combination_id=> vn_ACCTS_PAY_CCID,
													  pv_errbuf => vv_errbuf,
													  pn_retcode => vn_retcode);

							IF
								vn_retcode != 0
							THEN
								BEGIN
								   
									l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_046','COMPTE_FOURNISSEUR',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
									ins_prog_message(  g_import_request_id
													  ,'DKA_IPOFRS_IVALUA_PKG'
													  ,'LIGNES'
													  ,'DKA_IPOFRS_ENTETES'
													  --,NULL
													  ,rec_fournisseur.RECORD_ID
													  ,'compte fournisseur'
													  ,vn_ACCTS_PAY_CCID
													  ,'E'
													  ,l_message
													);
									DKA_TOOLS_PKG.put_log_message(l_message);
								END;
							END IF;
							
							
		-- Récupération nouveau compte Acompte
						  BEGIN
								SELECT
									segment1,
									segment2,
									segment3,
									segment4,
									'XXX'||v_code_partenaire,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
									
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
								FROM
									gl_code_combinations
								WHERE
									code_combination_id = v_compte_acompte
									and ENABLED_FLAG    = 'Y'
									and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);

						  EXCEPTION
						  WHEN OTHERS THEN
									NULL;
						  END;

						  --Compte GL ACOMPTE
						  dka_tools_pkg.get_code_combination_id(
													  pv_segment1  => vn_segment1,
													  pv_segment2  => vn_segment2,
													  pv_segment3  => vn_segment3,
													  pv_segment4  => vn_segment4,
													  pv_segment5  => vn_segment5,
													  pv_segment6  => vn_segment6,
													  pv_segment7  => vn_segment7,
													  pv_segment8  => vn_segment8,
													  pv_segment9  => vn_segment9,
													  pv_segment10 => vn_segment10,
													  pv_segment11 => vn_segment11,
													  pv_segment12 => vn_segment12,
													  pn_code_combination_id=> vn_PREPAY_CCID,
													  pv_errbuf => vv_errbuf,
													  pn_retcode => vn_retcode);

			  IF
				  vn_retcode != 0
			  THEN
				  BEGIN
								  
									l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_047','COMPTE_ACOMPTE',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
									ins_prog_message(  g_import_request_id
													   ,'DKA_IPOFRS_IVALUA_PKG'
													   ,'LIGNES'
													   ,'DKA_IPOFRS_ENTETES'
													   --,NULL
													   ,rec_fournisseur.RECORD_ID
													   ,'compte Acompte'
													   ,vn_PREPAY_CCID
													   ,'E'
													   ,l_message
										);
					 DKA_TOOLS_PKG.put_log_message(l_message);
				  END;
			   END IF;
		
		-- Récupération nouveau effet à payer 
						  BEGIN
								SELECT
									segment1,
									segment2,
									segment3,
									segment4,
									'XXX'||v_code_partenaire,
									segment6,
									segment7,
									segment8,
									segment9,
									segment10,
									segment11,
									segment12
								INTO
									vn_segment1,
									vn_segment2,
									vn_segment3,
									vn_segment4,
									vn_segment5,
									vn_segment6,
									vn_segment7,
									vn_segment8,
									vn_segment9,
									vn_segment10,
									vn_segment11,
									vn_segment12
								FROM
									gl_code_combinations
								WHERE
									code_combination_id = v_compte_effet
									and ENABLED_FLAG    = 'Y'
									and (END_DATE_ACTIVE IS NULL OR END_DATE_ACTIVE > SYSDATE);

						  EXCEPTION
						  WHEN OTHERS THEN
									NULL;
						  END;

						  --Compte GL effet 
						  dka_tools_pkg.get_code_combination_id(
													  pv_segment1  => vn_segment1,
													  pv_segment2  => vn_segment2,
													  pv_segment3  => vn_segment3,
													  pv_segment4  => vn_segment4,
													  pv_segment5  => vn_segment5,
													  pv_segment6  => vn_segment6,
													  pv_segment7  => vn_segment7,
													  pv_segment8  => vn_segment8,
													  pv_segment9  => vn_segment9,
													  pv_segment10 => vn_segment10,
													  pv_segment11 => vn_segment11,
													  pv_segment12 => vn_segment12,
													  pn_code_combination_id=> vn_future_CCID,
													  pv_errbuf => vv_errbuf,
													  pn_retcode => vn_retcode);

			  IF
				  vn_retcode != 0
			  THEN
					BEGIN
								
								  l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOFRS_048','COMPTE_EFFET',vn_segment1||'.'||vn_segment2||'.'||vn_segment3||'.'||vn_segment4||'.'||vn_segment5||
										'.'||vn_segment6||'.'||vn_segment7||'.'||vn_segment8||'.'||vn_segment9||'.'||vn_segment10||'.'||vn_segment11||'.'||vn_segment12);
								  ins_prog_message(  g_import_request_id
																 ,'DKA_IPOFRS_IVALUA_PKG'
																 ,'LIGNES'
																 ,'DKA_IPOFRS_ENTETES'
																 --,NULL
																 ,rec_fournisseur.RECORD_ID
																 ,'compte Effet'
																 ,vn_future_CCID
																 ,'E'
																 ,l_message
									 );
								DKA_TOOLS_PKG.put_log_message(l_message);
					END;
					  END IF;	
				ELSE  
					
					vn_future_CCID    := v_compte_effet;
					vn_ACCTS_PAY_CCID := v_compte_fournisseur;
					vn_PREPAY_CCID    := v_compte_acompte;
				END IF;	
				
				update 
				   ap_supplier_sites_all ass
				 set accts_pay_code_combination_id = vn_ACCTS_PAY_CCID,
					 prepay_code_combination_id   =  vn_PREPAY_CCID,
					 future_dated_payment_ccid    =  vn_future_CCID
				WHERE   ass.org_id         = (select hou.organization_id
										 FROM hr_operating_units    hou 
										 where hou.name           = 'REF9999'
										)
				and     ass.vendor_id      = vn_vendor_id ;
		END IF;
				commit;
				g_nb_entetes_traite_succes := g_nb_entetes_traite_succes + 1; 
				ELSE
				  UPDATE DKA_IPOFRS_ENTETES
				  SET   STATUT 			= 'REJECTED2'   
					   ,LAST_UPDATE_DATE  = SYSDATE
					   ,LAST_UPDATED_BY   = g_user_id
					   ,request_id        = g_request_id				   
				  WHERE RECORD_ID 		= rec_fournisseur.RECORD_ID;
				   g_nb_entetes_traite_rejected2 := g_nb_entetes_traite_rejected2 + 1; 
				   l_message := substr(fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);
				   ins_prog_message(  g_import_request_id
									 ,'DKA_IPOFRS_IVALUA_PKG'
									 ,'ENTETE'
									 ,'DKA_IPOFRS_ENTETES'
									 --,NULL
									 ,rec_fournisseur.RECORD_ID
									 ,'NUM_FOURNISSEUR'
									 ,rec_fournisseur.NUM_FOURNISSEUR
									 ,'E'
									 ,substr('Une erreur est survenue lors de la mise à jour du fournisseur '
														  ||' - '||l_message,1,500)
								   );			
					p_retcode := 1;    
				END IF;

	  
		END IF;--EXIST
		
		END LOOP;--ENTETE 
		COMMIT;
		
		
		for rec_lignes  IN  cur_site_fournisseur LOOP
		    v_statut  := null;
		
		--- ORG_ID de la référence 
			BEGIN
			select hou.organization_id 
			into v_org_id 
			from hr_organization_units  hou
			where hou.name = 'REF9999' ;
			exception
				 when others then
				 null;
			END; 
			
			-- EDB330 ARA
			  BEGIN
				SELECT term_id
				INTO vn_term_id
				from ap_terms
				where name = replace(replace(rec_lignes.ECHEANCE, chr(13), ''), chr(10), ' ');
			  END;
			  
			  
			BEGIN
				
				--- Existence de site fournisseur
				
			  SELECT
					'1', vendor_site_id , location_id 
				INTO
					vv_exist, v_exist_vendor_site_id , v_location_id 
				FROM
				( select '1' , vendor_site_id ,location_id
				from 
					ap_supplier_sites_all apss,
					ap_suppliers          aps
				WHERE
					aps.vendor_id         = apss.vendor_id
				and aps.segment1          = rec_lignes.num_fournisseur
				and apss.vendor_site_code = rec_lignes.NOM_ADRESSE_SITE
				and apss.org_id           = v_org_id
					  
				union 
				select '1' , vendor_site_id , location_id
				from 
					ap_supplier_sites_all apss,
					ap_suppliers          aps
				WHERE
					aps.vendor_id         = apss.vendor_id
				and aps.segment1          = rec_lignes.num_fournisseur
				and apss.attribute4       = rec_lignes.ID_IVALUA_SITE_FOURNISSEUR
				and apss.org_id           = v_org_id)
				  ;
				
				 EXCEPTION
						 WHEN too_many_rows THEN 
							BEGIN  ---- Debut SHA : defect #1232
							    UPDATE DKA_IPOFRS_LIGNES
							    SET   STATUT 			= 'REJECTED2'   
							   	,LAST_UPDATE_DATE  = SYSDATE
							   	,LAST_UPDATED_BY   = g_user_id
							   	,request_id        = g_request_id										
							    WHERE RECORD_ID 		= rec_lignes.RECORD_ID;
							    ins_prog_message(  g_import_request_id
							   				 ,'DKA_IPOFRS_IVALUA_PKG'
							   				 ,'LIGNES'
							   				 ,'DKA_IPOFRS_LIGNES'
							   				 --,NULL
							   				 ,rec_lignes.RECORD_ID
							   				 ,'Site fournisseur'
							   				 ,'MAJ site fournisseur'
							   				 ,'E'
							   				 ,'Ce site fournisseur n''est pas unique sur l''UO de référence. '
							   				
							   			   );
								DKA_TOOLS_PKG.put_log_message(l_message);
								END;
							  v_statut  := 'E';
							  p_retcode := 1;
							  vv_exist  := '2'; 
							  g_nb_lignes_traite_rejected2 := g_nb_lignes_traite_rejected2 + 1;----Fin SHA : defect #1232
						 WHEN OTHERS THEN
							 vv_exist := NULL;
			END;

			IF
				vv_exist IS NULL --création
			THEN
			
			
			 BEGIN 
				select vendor_id
				into x_vendor_id
				from ap_suppliers
				where segment1 = rec_lignes.NUM_FOURNISSEUR;
			   exception
					 when others then
					 x_vendor_id := NULL;
				 END ; 
			  
			--Création site fournisseur 
				IF x_vendor_id is not null THEN
				  vv_commit                 := FND_API.G_FALSE;
				  vn_validation_level       := FND_API.G_VALID_LEVEL_FULL;
				  vv_return_status           := NULL;
				  vn_msg_count               := NULL;
				  vv_msg_data                := NULL;

				  lr_vendor_site_create.org_id                        := v_org_id; --2960;
				  lr_vendor_site_create.last_update_date              := SYSDATE;
				  lr_vendor_site_create.last_updated_by               := g_user_id ; --7646 ;---1;
				  lr_vendor_site_create.vendor_id                     := x_vendor_id ; --632001;
				  ---Adresse site fournisseur-----
				  lr_vendor_site_create.country                       := rec_lignes.PAYS;
				  lr_vendor_site_create.address_line1                 := rec_lignes.ADRESSE_LIGNE1;
				  lr_vendor_site_create.address_line2                 := rec_lignes.ADRESSE_LIGNE2;
				  lr_vendor_site_create.address_line3                 := rec_lignes.ADRESSE_LIGNE3;
				  lr_vendor_site_create.address_line4                 := rec_lignes.NOM_ADRESSE_SITE;
				  lr_vendor_site_create.city                          := rec_lignes.VILLE;
				  lr_vendor_site_create.zip                           := rec_lignes.CODE_POSTAL;
				  lr_vendor_site_create.county                        := rec_lignes.REGION;
				  lr_vendor_site_create.vendor_site_code              := rec_lignes.NOM_ADRESSE_SITE;
				  ---CUF ---------------------------
				  lr_vendor_site_create.attribute1                    := rec_lignes.COMPLEMENT_SIRET;
				  lr_vendor_site_create.attribute2                    := rec_lignes.STATUT_SITE_FOURNISSEUR;
				  lr_vendor_site_create.attribute4                    := rec_lignes.ID_IVALUA_SITE_FOURNISSEUR;
				  lr_vendor_site_create.attribute6                    := rec_lignes.CODE_INSEE_COMMUNE;
				  lr_vendor_site_create.attribute7                    := rec_lignes.BUREAU_DISTRIBUTEUR;
				  ---Fonctions site fournisseur-----
				  lr_vendor_site_create.purchasing_site_flag          := rec_lignes.FONCTION_ACHATS;
				  lr_vendor_site_create.pay_site_flag                 := 'N';
				  lr_vendor_site_create.pcard_site_flag               := rec_lignes.FONCTION_CARTE_ACHAT;
				  ---- clé comptable
				  lr_vendor_site_create.accts_pay_code_combination_id := rec_lignes.compte_fournisseur;
				  lr_vendor_site_create.prepay_code_combination_id    := rec_lignes.compte_acompte;
				  lr_vendor_site_create.future_dated_payment_ccid     := rec_lignes.compte_effet;
				  ---Info de communication----------
				  lr_vendor_site_create.supplier_notif_method          := rec_lignes.MODE_NOTIFICATION;
				  lr_vendor_site_create.phone                          := rec_lignes.TELEPHONE;
				  lr_vendor_site_create.email_address                  := rec_lignes.EMAIL_ACHAT;
				  -- EDB330 ARA --------
				  lr_vendor_site_create.AUTO_TAX_CALC_FLAG            := 'Y';
				  lr_vendor_site_create.AP_TAX_ROUNDING_RULE          := 'N';
				  lr_vendor_site_create.AMOUNT_INCLUDES_TAX_FLAG      := 'N';
				  lr_vendor_site_create.terms_id      := vn_term_id;
				  
					ap_vendor_pub_pkg.create_vendor_site(1.0,
								   FND_API.G_TRUE,
								   vv_commit,
								   vn_validation_level,
								   vv_return_status,
								   vn_msg_count,
								   vv_msg_data,
								   lr_vendor_site_create,
								   vv_vendor_site_id,
								   vn_party_site_id,
								   vn_location_id);
								   
							COMMIT;
							IF
								( vv_return_status <> fnd_api.g_ret_sts_success )
							THEN
								FOR i IN 1..fnd_msg_pub.count_msg LOOP
									BEGIN
									   UPDATE DKA_IPOFRS_LIGNES
									   SET   STATUT 			= 'REJECTED2'   
											,LAST_UPDATE_DATE  = SYSDATE
											,LAST_UPDATED_BY   = g_user_id
											,request_id        = g_request_id										
									   WHERE RECORD_ID 		= rec_lignes.RECORD_ID;
									   l_message := substr(fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);
									   ins_prog_message(  g_import_request_id
														 ,'DKA_IPOFRS_IVALUA_PKG'
														 ,'LIGNES'
														 ,'DKA_IPOFRS_LIGNES'
														 --,NULL
														 ,rec_lignes.RECORD_ID
														 ,'Site fournisseur'
														 ,'Creation site fournisseur'
														 ,'E'
														 ,substr('Une erreur est survenue lors de la création du site fournisseur '
														  ||' - '||l_message,1,500)
													   );
									DKA_TOOLS_PKG.put_log_message(l_message);
									END;
								  v_statut := 'E';
								  p_retcode := 1;
								END LOOP;
							ELSE
							--SHA 
							update ap_supplier_sites_all
							set ADDRESS_LINE4 = null 
							where vendor_site_id = vv_vendor_site_id;
							
							update hz_locations 
							set ADDRESS4 = null 
							where location_id = vn_location_id;
							commit;
							-- fin SHA 
								vv_payee_party_id := null;
								vv_ext_payee_id := null;
								BEGIN
								   SELECT payee_party_id  , ext_payee_id
								   INTO vv_payee_party_id , vv_ext_payee_id
								   FROM IBY_EXTERNAL_PAYEES_ALL
								   WHERE 1=1
								   AND SUPPLIER_SITE_ID  = vv_vendor_site_id
								   AND ORG_ID            = v_org_id
								   ;
								EXCEPTION
								WHEN OTHERS THEN
								NULL;
								END;
																
					
								BEGIN
								
								SELECT ext_payee_id, payee_party_id
								INTO vv_ext_payee_id,v_payee_party_id                     
								FROM IBY_EXTERNAL_PAYEES_ALL  iepa
								WHERE 1=1
								AND   iepa.SUPPLIER_SITE_ID = vv_vendor_site_id;--rec_frns_duplique.VENDOR_SITE_ID;
							   EXCEPTION
								WHEN OTHERS THEN
									vv_ext_payee_id :=NULL;
									v_payee_party_id:=NULL;
								END;
								p_ext_payee_tab(i).exclusive_pay_flag           := 'N';
								p_ext_payee_tab(i).default_pmt_method           := 'CHECK';
								p_ext_payee_tab(i).remit_advice_email           := rec_lignes.EMAIL_FINANCE;				
								p_ext_payee_tab(i).payee_party_id               := v_payee_party_id;
								p_ext_payee_tab(i).Payee_party_site_id          := vn_party_site_id;    
								p_ext_payee_tab(i).Supplier_Site_id             := vv_vendor_site_id;   
								p_ext_payee_tab(i).Payer_Org_Type               := 'OPERATING_UNIT';
								p_ext_payee_tab(i).Payer_Org_id                 := v_org_id;
								p_ext_payee_tab(i).payment_function            := 'PAYABLES_DISB';
								p_ext_payee_id_tab(i).ext_payee_id              := vv_ext_payee_id;
								
								
								 IBY_DISBURSEMENT_SETUP_PUB.update_external_payee ( p_api_version            => 1.0,
																				   p_init_msg_list          => 'T',
																				   p_ext_payee_tab          => p_ext_payee_tab,
																				   p_ext_payee_id_tab       => p_ext_payee_id_tab,
																				   x_return_status          => x_return_status,
																				   x_msg_count              => x_msg_count,
																				   x_msg_data               => x_msg_data,
																				   x_ext_payee_status_tab   => l_payee_upd_status
																				  );
									
										   IF x_return_status = 'E'
										THEN
											   FOR k IN l_payee_upd_status.FIRST .. l_payee_upd_status.LAST
											   LOOP
												   
												   BEGIN
											
											
											   UPDATE DKA_IPOFRS_LIGNES
											   SET   STATUT 			= 'REJECTED2'   
													,LAST_UPDATE_DATE  = SYSDATE
													,LAST_UPDATED_BY   = g_user_id
													,request_id        = g_request_id
											   WHERE RECORD_ID 		= rec_lignes.RECORD_ID;
										
												l_message := substr(fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);
												ins_prog_message(  g_import_request_id
																  ,'DKA_IPOFRS_IVALUA_PKG'
																  ,'LIGNES'
																  ,'DKA_IPOFRS_LIGNES'
																  --,NULL
																  ,rec_lignes.RECORD_ID
																  ,'Site fournisseur'
																  ,'MAJ information de règlement'
																  ,'E'
																  ,substr('Une erreur est survenue lors de la mise à jour des informations de règlement '
																  ||' - '||l_message,1,500)
																);
											DKA_TOOLS_PKG.put_log_message(l_message);
											
													p_retcode := 1;
													v_statut := 'E';
												END;
											   END LOOP;
											  
										ELSE
											 BEGIN
											   UPDATE DKA_IPOFRS_LIGNES
											   SET   STATUT 			= 'COMPLETE'   
													,LAST_UPDATE_DATE  = SYSDATE
													,LAST_UPDATED_BY   = g_user_id
													,request_id        = g_request_id
											   WHERE RECORD_ID 		= rec_lignes.RECORD_ID;
										
											  END;
											 g_nb_lignes_traite_succes := g_nb_lignes_traite_succes + 1;
										END IF; 


							   
									
		commit;
		
							END IF;	
					   if 		v_statut = 'E'	then 
					   g_nb_lignes_traite_rejected2 := g_nb_lignes_traite_rejected2 + 1;
					   end if ;
				END IF; -- create site 
			ELSIF vv_exist = '1' then  --mise à jour ---- SHA : defect #1232
			--RG703
			BEGIN
			
			 SELECT assa.ATTRIBUTE2 , inactive_date , party_site_id , vendor_id ,purchasing_site_flag
			 into  v_status_fournisseur , v_inactive_date_site , vv_party_site_id , v_vendor_id ,v_fonction_achat-- SHA Problème de mise à jour du fontion d'achat
			 from ap_supplier_sites_all assa
			 where assa.vendor_site_id = v_exist_vendor_site_id;
			 EXCEPTION
			 WHEN OTHERS THEN
			  v_status_fournisseur := NULL;
			  v_inactive_date_site := NULL;
			END;
			
			BEGIN 
			select end_date_active
			into v_inactive_date_fournisseur
			from ap_suppliers
			where vendor_id = v_vendor_id;
			EXCEPTION
			 WHEN OTHERS THEN
			  v_inactive_date_fournisseur := NULL;
			  
			END ;
		
		
		--IF (rec_lignes.FONCTION_ACHATS ='Y') then --EDB303
			if  (rec_lignes.STATUT_SITE_FOURNISSEUR = 'INACTIF')then
					if (v_status_fournisseur = 'ACTIF')then
					  v_fonction_achat := 'N';
					ELSIF (v_status_fournisseur = 'INACTIF') then --EDB303
					  v_fonction_achat := 'N';
					END IF;
			else if (rec_lignes.STATUT_SITE_FOURNISSEUR = 'ACTIF')then
					if (v_status_fournisseur = 'INACTIF')then
					   v_fonction_achat := rec_lignes.FONCTION_ACHATS; --EDB303
					   v_inactive_date_site  := null;
					   v_inactive_date_fournisseur  := null;
					
					--EDB303
					ELSIF(v_status_fournisseur = 'ACTIF') THEN
						v_fonction_achat := rec_lignes.FONCTION_ACHATS;
					END IF;
					
			END IF;
			END IF;
		
		
		--END IF;
				--Mise à jour site fournisseur 
				
				-- EDB330
				/*update ap.ap_supplier_sites_all
				set  terms_id     = vn_term_id
				where vendor_site_id = v_exist_vendor_site_id;--vv_vendor_site_id;
				
				commit;*/
				
				  p_api_version             := 1.0;
				  p_init_msg_list           := FND_API.G_TRUE;
				  vv_commit                 := FND_API.G_TRUE;
				  vn_validation_level       := FND_API.G_VALID_LEVEL_FULL;
				  x_return_status           := NULL;
				  x_msg_count               := NULL;
				  x_msg_data                := NULL;
				 
				  lr_vendor_site_update.last_update_date              := SYSDATE;
				  lr_vendor_site_update.last_updated_by               := g_user_id ;---1;
				  lr_vendor_site_update.vendor_id                     := v_vendor_id;
				  lr_vendor_site_update.vendor_site_id                := v_exist_vendor_site_id;
				  ---Adresse site fournisseur-----
				
				  lr_vendor_site_update.address_line1                 := rec_lignes.ADRESSE_LIGNE1;
				  lr_vendor_site_update.address_line2                 := rec_lignes.ADRESSE_LIGNE2;
				  lr_vendor_site_update.address_line3                 := rec_lignes.ADRESSE_LIGNE3;
				  lr_vendor_site_update.city                          := rec_lignes.VILLE;
				  lr_vendor_site_update.zip                           := rec_lignes.CODE_POSTAL;
				  lr_vendor_site_update.county                        := rec_lignes.REGION;
				  --lr_vendor_site_update.vendor_site_code              := rec_lignes.NOM_ADRESSE_SITE;
				   ---CUF ---------------------------
				  lr_vendor_site_update.attribute1                    := rec_lignes.COMPLEMENT_SIRET;
				  lr_vendor_site_update.attribute2                    := rec_lignes.STATUT_SITE_FOURNISSEUR;
				  lr_vendor_site_update.attribute6                    := rec_lignes.CODE_INSEE_COMMUNE;
				  lr_vendor_site_update.attribute7                    := rec_lignes.BUREAU_DISTRIBUTEUR;
				  ---Fonctions site fournisseur-----
				  lr_vendor_site_update.purchasing_site_flag          := v_fonction_achat;
				  lr_vendor_site_update.pcard_site_flag               := rec_lignes.FONCTION_CARTE_ACHAT;
				  ---Info de communication----------
				  lr_vendor_site_update.supplier_notif_method         := rec_lignes.MODE_NOTIFICATION;
				  lr_vendor_site_update.phone                         := rec_lignes.TELEPHONE;
				  lr_vendor_site_update.email_address                 := rec_lignes.EMAIL_ACHAT;
				  ---- clé comptable
				  lr_vendor_site_update.accts_pay_code_combination_id := rec_lignes.compte_fournisseur;
				  lr_vendor_site_update.prepay_code_combination_id    := rec_lignes.compte_acompte;
				  lr_vendor_site_update.future_dated_payment_ccid     := rec_lignes.compte_effet;
				  ----- EDB330 -----------------
				  lr_vendor_site_update.terms_id      := vn_term_id;
				  
				  
				  AP_VENDOR_PUB_PKG.UPDATE_VENDOR_SITE_PUBLIC (p_api_version,
														  p_init_msg_list,
														  vv_commit,
														  vn_validation_level,
														  x_return_status,
														  x_msg_count,
														  x_msg_data,
														  lr_vendor_site_update,
														  v_exist_vendor_site_id --rec_lignes.ID_IVALUA_SITE_FOURNISSEUR
														  );
				
				
				
				IF
								( x_return_status <> fnd_api.g_ret_sts_success )--SHA : defect #1232
							THEN
								FOR i IN 1..fnd_msg_pub.count_msg LOOP
									
									BEGIN
										UPDATE DKA_IPOFRS_LIGNES
									   SET   STATUT 			= 'REJECTED2'   
											,LAST_UPDATE_DATE  = SYSDATE
											,LAST_UPDATED_BY   = g_user_id
											,request_id        = g_request_id										
									   WHERE RECORD_ID 		= rec_lignes.RECORD_ID;

									END;
								   g_nb_lignes_traite_rejected2 := g_nb_lignes_traite_rejected2 + 1;
								   l_message := substr(fnd_msg_pub.get(p_msg_index => i,p_encoded => fnd_api.g_false),1,500);
										ins_prog_message(  g_import_request_id
														  ,'DKA_IPOFRS_IVALUA_PKG'
														  ,'LIGNES'
														  ,'DKA_IPOFRS_LIGNES'
														  --,NULL
														  ,rec_lignes.RECORD_ID
														  ,'Site fournisseur'
														  ,'MAJ site fournisseur'
														  ,'E'
														  ,substr('Une erreur est survenue lors de la mise à jour du site fournisseur '
														  ||' - '||l_message,1,500)
														);
									
								DKA_TOOLS_PKG.put_log_message('error message : ' || fnd_msg_pub.get (fnd_msg_pub.g_next, fnd_api.g_false));
								p_retcode := 1;   
								END LOOP;
							ELSE
							BEGIN
							
								update hz_party_sites 
								set  party_site_name = rec_lignes.NOM_ADRESSE_SITE
								where  party_site_id = vv_party_site_id;
								
								update hz_locations 
								set  ADDRESS1    = rec_lignes.ADRESSE_LIGNE1
									,ADDRESS2    = rec_lignes.ADRESSE_LIGNE2
									,ADDRESS3    = rec_lignes.ADRESSE_LIGNE3
									,CITY        = rec_lignes.VILLE
									,COUNTY      = rec_lignes.REGION
									,POSTAL_CODE = rec_lignes.CODE_POSTAL
									
								WHERE location_id = v_location_id;
								
								
									  --------- Pour la suppression des champs non obligatoires
								if 	(rec_lignes.NOM_ADRESSE_SITE is null or rec_lignes.ADRESSE_LIGNE1 is null or rec_lignes.ADRESSE_LIGNE2 is null 
								or rec_lignes.ADRESSE_LIGNE3 is null or rec_lignes.REGION is null or rec_lignes.COMPLEMENT_SIRET is null 
								or rec_lignes.CODE_INSEE_COMMUNE is null or rec_lignes.BUREAU_DISTRIBUTEUR is null or rec_lignes.TELEPHONE is null 
								or v_inactive_date_site is null or v_inactive_date_fournisseur is null ) then 
									update ap.ap_supplier_sites_all
									set  vendor_site_code              = rec_lignes.NOM_ADRESSE_SITE
										,address_line1                 = rec_lignes.ADRESSE_LIGNE1
										,address_line2                 = rec_lignes.ADRESSE_LIGNE2
										,address_line3                 = rec_lignes.ADRESSE_LIGNE3
										,county                        = rec_lignes.REGION
										,attribute1                    = rec_lignes.COMPLEMENT_SIRET
										,attribute6                    = rec_lignes.CODE_INSEE_COMMUNE
										,attribute7                    = rec_lignes.BUREAU_DISTRIBUTEUR
										,phone                         = rec_lignes.TELEPHONE
										,inactive_date                 = v_inactive_date_site
									where vendor_site_id = v_exist_vendor_site_id;
									  
									update ap_suppliers
									set    END_DATE_ACTIVE = v_inactive_date_fournisseur
									where  vendor_id = v_vendor_id ; 
									
									
								END IF;	  
										UPDATE DKA_IPOFRS_LIGNES
									   SET   STATUT 			= 'COMPLETE'   
											,LAST_UPDATE_DATE  = SYSDATE
											,LAST_UPDATED_BY   = g_user_id	
											,request_id        = g_request_id										
									   WHERE RECORD_ID 		= rec_lignes.RECORD_ID;

									END;
								   g_nb_lignes_traite_succes := g_nb_lignes_traite_succes + 1;
							   
							END IF;
						
					
		END IF; -- exist
		END LOOP; --- site fournisseur
	 COMMIT; 
	  BEGIN
	  select 
	  submitted_login_id
	  into
	  v_submitted_login_id
	  FROM  fnd_logins fl 
	  where fl.login_id = g_login_id;
	  EXCEPTION
			 WHEN OTHERS THEN
			  null;                   
	  
	  END;
	  v_duplication :=0; 
	  FOR rec_homo  IN  cur_homologation LOOP
	  --Alimentation de l’outil de duplication en masse 
	  BEGIN
	  insert into DKA_SAPFRSDUPLI_MASSE_TMP 
	  values
	  (DKA_SAPFRSDUPLI_MASSE_TMP_S.NEXTVAL,
	   rec_homo.NUM_FOURNISSEUR,
	   rec_homo.NOM_ADRESSE_SITE,
	   rec_homo.ID_IVALUA_SITE_FOURNISSEUR,
	   rec_homo.PERIMETRE_HOMOLOGATION,
	   'NEW',
	   sysdate,
	   g_user_id,
	   sysdate,
	   g_user_id,
	   v_submitted_login_id,
	   'IVALUA',
	   rec_homo.record_id,
	   NULL,
	   NULL,
	   NULL,
	   NULL,
	   NULL
	  );
	  v_duplication :=1;
	  EXCEPTION
			 WHEN OTHERS THEN
			   null;
	  END ;

	  END LOOP; --homologation
	  COMMIT;
	  IF v_duplication <> 0 THEN
		  l_request_id := FND_REQUEST.submit_request(l_application_code,
													 l_conc_program,
													 '',
													 SYSDATE,
													 FALSE
													 );
		  
		  
			COMMIT;
			IF l_request_id != 0 THEN
				DKA_TOOLS_PKG.put_log_message(l_message);
				l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST( REQUEST_ID => l_request_id
																 , INTERVAL   => l_req_interval
																 , MAX_WAIT   => l_req_max_wait
																 , PHASE      => l_req_phase
																 , STATUS     => l_req_status
																 , DEV_PHASE  => l_req_dev_phase
																 , DEV_STATUS => l_req_dev_status
																 , MESSAGE    => l_req_message
																 );
		  
				IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
					l_message := ' - Duplication en masse terminé en avertissement';
					DKA_TOOLS_PKG.put_log_message(l_message);
					-- g_nb_homo_traite_rejected2 := g_nb_homo_traite_rejected2 + 1;
					p_retcode := 1;
				ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
					l_message := ' - Duplication en masse terminé en erreur';
					DKA_TOOLS_PKG.put_log_message(l_message);
					p_retcode := 2;
					-- g_nb_homo_traite_rejected2 := g_nb_homo_traite_rejected2 + 1;
				ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'NORMAL' THEN
					l_message := ' - Traitement terminé normal';
					DKA_TOOLS_PKG.put_log_message(l_message);
					Fnd_File.put_line(Fnd_File.LOG, l_message);
					p_retcode := 0;
				   -- g_nb_homo_traite_succes := g_nb_homo_traite_succes + 1;
				END IF;
			ELSE
				l_message := ' - Erreur lors du lancement du traitement';
				DKA_TOOLS_PKG.put_log_message(l_message);
				DBMS_OUTPUT.PUT_LINE(l_message);
				p_retcode := 2;
		  
			END IF;
		
		UPDATE DKA_IPOFRS_HOMOLOGATIONS dih
		   SET statut = 'REJECTED2'
		   WHERE exists (SELECT 'x' 
						 FROM DKA_SAPFRSDUPLI_MASSE_TMP dsmt
						 WHERE dsmt.line_num = dih.record_id
						 AND dsmt.file_name = 'IVALUA'
						 AND dsmt.statut != 'SUCCESS');
		   g_nb_homo_traite_rejected2 := SQL%ROWCOUNT;              
						 
		   UPDATE DKA_IPOFRS_HOMOLOGATIONS dih
		   SET statut = 'COMPLETE'
		   WHERE exists (SELECT 'x' 
						 FROM DKA_SAPFRSDUPLI_MASSE_TMP dsmt
						 WHERE dsmt.line_num = dih.record_id
						 AND dsmt.file_name = 'IVALUA'
						 AND dsmt.statut = 'SUCCESS');    
			g_nb_homo_traite_succes := SQL%ROWCOUNT; 

		
		commit;
		END IF;
	  
	  END;
		
		
		/*=====================================================================================*/
		/* PROCEDURE NAME : main
		/*
		/* DESCRIPTION
		/*  Procédure principale de l'interface d'import des fournisseurs
		/*
		/* PARAMETERS
		/* ==========
		/* NAME              DESCRIPTION
		/* ----------------- ------------------------------------------------------
		/* p_errbuf         Retour de message éventuel
		/* p_retcode        Statut du traitement en sortie
		/*=====================================================================================*/

		PROCEDURE MAIN( p_errbuf          IN  OUT VARCHAR2,
						p_retcode         IN  OUT NUMBER,
						p_recyclage         IN  VARCHAR2
						
						)
		IS

			-- ========== VARIABLES ==========
			v_package                    VARCHAR2(30)  := 'DKA_IPOFRS_IVALUA_PKG';
			v_nom_traitement             VARCHAR2(200) := 'Import des fournisseurs';
			v_sqlerrm                    VARCHAR2(250) := NULL;
			v_nb_erreurs                 NUMBER :=0;

			v_procedure                  VARCHAR2(30)    := 'MAIN';
			v_message                    VARCHAR2(500);

			v_errbuf                     VARCHAR2(2500);
			v_retcode                    NUMBER;
			v_exeption                   EXCEPTION;
			v_resp_appl_id 	fnd_responsibility.application_id%TYPE;
			v_resp_id   fnd_responsibility.responsibility_id%TYPE;
			
			
			CURSOR cur_fournisseur
			IS SELECT die.*
			FROM DKA_IPOFRS_ENTETES die
			WHERE die.statut in  ('NEW','REJECTED1' ,'REJECTED2')
			;

			CURSOR cur_site_fournisseur
			IS SELECT dis.*
			FROM DKA_IPOFRS_lignes dis
			WHERE dis.statut in  ('NEW','REJECTED1' ,'REJECTED2')
			;
			
			 CURSOR cur_homologation
			IS SELECT dih.*
			FROM DKA_IPOFRS_HOMOLOGATIONS dih
			WHERE dih.statut  in  ('NEW','REJECTED1' ,'REJECTED2')
			;
		
		BEGIN

			-- Début du Programme --
			-- ========Initialisation des variables d'anomalies========
			p_retcode   := 0;
			p_errbuf   := NULL;
			v_message   := 'Début procédure MAIN';

			 -- Initialization des journaux --
			Dka_Tools_Pkg.put_log_message('=======================================================================');
			Dka_Tools_Pkg.put_log_message('Import fournisseur DKA_IPOFRS_IVALUA');
			Dka_Tools_Pkg.put_log_message('=======================================================================');
			Dka_Tools_Pkg.put_log_message('Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
			Dka_Tools_Pkg.put_log_message('Numéro de traitement : ' || TO_CHAR(g_request_id));
			 -- Initialization de la sortie --
			 
			writeout('--------------------------------------------------------------------------------------------');
			writeout(' COMPTE-RENDU DU TRAITEMENT « DKA : Import des données Fournisseurs depuis iValua » ');
			writeout(' Traitement n° '||TO_CHAR(g_request_id));
			writeout(' Le  : '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
			writeout('--------------------------------------------------------------------------------------------');
			writeout('                                                                ');
		  
			-- Entete fichier log
			Dka_Tools_Pkg.put_log_message('==========================================================================');
			Dka_Tools_Pkg.put_log_message('Numéro de traitement '||TO_CHAR(g_request_id));
			Dka_Tools_Pkg.put_log_message('Libelle du login OA '||FND_GLOBAL.USER_NAME);
			Dka_Tools_Pkg.put_log_message('==========================================================================');

			
			/*============================================================================================*/
			/*Initialisation des variables*/
			/*============================================================================================*/
			v_message   := 'Init';
			Init;
			
			IF p_recyclage ='NON' THEN
			   
				
			   
				/*============================================================================================*/
			-- PHASE DE PURGE DES ANCIENNES DONNEES d'open interface --
			/*============================================================================================*/
				purge_data(v_errbuf,v_retcode);
				
			/*============================================================================================*/
			/*Chargement des fichiers*/
			/*============================================================================================*/
				Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
				Dka_Tools_Pkg.put_log_message('/*Chargement des fichiers*/');
				Dka_Tools_Pkg.put_log_message('/*============================================================================================*/');
				Dka_Tools_Pkg.put_log_message('PHASE DE CHARGEMENT DU FICHIER');
				v_message   := 'CHARGEMENT DES FICHIERS';
				Launch_Loader(v_errbuf,v_retcode);
				IF v_retcode = 2
				THEN
					p_errbuf  := v_errbuf;
					p_retcode := v_retcode;
					Dka_Tools_Pkg.put_outdebug_message('Chargement des fichiers en erreur');
					RAISE v_exeption;
				END IF;
				Dka_Tools_Pkg.put_outdebug_message('Fin chargement des fichiers avec succes');
			  /*============================================================================================*/
			  /*delete_obsolete_records*/
			  /*============================================================================================*/  
			   delete_obsolete_records(v_errbuf,v_retcode);
				  /*============================================================================================*/
			  /*Validation de données */
			  /*============================================================================================*/
			  v_message   := 'VALIDATION DES DONNEES';
				  validate_data(v_errbuf,v_retcode);
				  IF v_retcode = 2
				THEN
					p_errbuf  := v_errbuf;
					p_retcode := v_retcode;
					RAISE v_exeption;
				END IF;
			  /*============================================================================================*/
			  /*Importation de données */
			  /*============================================================================================*/
			  v_message   := 'IMPORTATION DES DONNEES';
				  import_data(v_errbuf,v_retcode);
				  IF v_retcode = 2
				THEN
					p_errbuf  := v_errbuf;
					p_retcode := v_retcode;
					RAISE v_exeption;
			  END IF;
			  
				
			  /*============================================================================================*/
			  /*Bilan de l'interface */
			  /*============================================================================================*/
			  v_message   := 'BILAN';
			   Report_Bilan;
			   update_statut(v_errbuf,v_retcode);
			ELSE 
				/*============================================================================================*/
			-- PHASE DE PURGE DES ANCIENNES DONNEES d'open interface --
			/*============================================================================================*/
				v_message   := 'PURGE DES ANCIENNES DONNEES';
				purge_data(v_errbuf,v_retcode);
				/*============================================================================================*/
			  /*Validation de données */
			  /*============================================================================================*/
			  v_message   := 'VALIDATION DES DONNEES';
				  validate_data(v_errbuf,v_retcode);
				  IF v_retcode = 2
				THEN
					p_errbuf  := v_errbuf;
					p_retcode := v_retcode;
					RAISE v_exeption;
				END IF;
			  /*============================================================================================*/
			  /*Importation de données */
			  /*============================================================================================*/
			  v_message   := 'IMPORTATION DES DONNEES';
				  import_data(v_errbuf,v_retcode);
				  IF v_retcode = 2
				THEN
					p_errbuf  := v_errbuf;
					p_retcode := v_retcode;
					RAISE v_exeption;
			  END IF;
				
			  /*============================================================================================*/
			  /*Bilan de l'interface */
			  /*============================================================================================*/
			   v_message   := 'BILAN';
			   Report_Bilan;
			   update_statut(v_errbuf,v_retcode);

		END IF;
		
		IF p_retcode = 2
			THEN
			 p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
		 ELSIF  (p_retcode = 1 OR g_nb_entetes_traite_rejected1 !=0 OR g_nb_entetes_traite_rejected2 != 0 OR g_nb_lignes_traite_rejected1 !=0 OR g_nb_lignes_traite_rejected2 != 0 OR g_nb_homo_traite_rejected1 != 0 OR g_nb_homo_traite_rejected2 != 0)
			THEN
			 p_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
			 p_retcode := 1;
		  ELSE
			 p_errbuf := 'Fin normale du traitement - Aucun rejet.';
			 p_retcode := 0;
		  END IF;

			COMMIT;
			
			Dka_Tools_Pkg.put_outdebug_message( CHR(10)||p_errbuf||CHR(10));
			writeout('--------------------------------------------------------------------------------------------');
			Dka_Tools_Pkg.put_outdebug_message( 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
			writeout('--------------------------------------------------------------------------------------------');

		EXCEPTION
			WHEN v_exeption THEN
				--p_retcode := 2;
				--p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
				Dka_Tools_Pkg.put_outdebug_message('-------------------- ERREUR --------------------');
				Dka_Tools_Pkg.put_outdebug_message('Package   : '||v_package);
				Dka_Tools_Pkg.put_outdebug_message('Procédure : '||v_procedure);
				Dka_Tools_Pkg.put_outdebug_message('Exception : OTHERS');
				Dka_Tools_Pkg.put_outdebug_message('Message   : '||v_message);
				Dka_Tools_Pkg.put_log_message('Cause     : '||p_errbuf);
				Dka_Tools_Pkg.put_outdebug_message('------------------------------------------------');
				Dka_Tools_Pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
				Dka_Tools_Pkg.put_log_message( '==> Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption ');
				Dka_Tools_Pkg.put_log_message('=========================================================================');
				Dka_Tools_Pkg.put_log_message('Traitement '||v_nom_traitement||' terminé en erreur         ');
				Dka_Tools_Pkg.put_log_message('=========================================================================');
				ROLLBACK;

		   WHEN OTHERS THEN
				v_sqlerrm := SUBSTR(SQLERRM,1,200);
				p_retcode := 2;
				p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
				Dka_Tools_Pkg.put_outdebug_message('-------------------- ERREUR --------------------');
				Dka_Tools_Pkg.put_outdebug_message('Package   : '||v_package);
				Dka_Tools_Pkg.put_outdebug_message('Procédure : '||v_procedure);
				Dka_Tools_Pkg.put_outdebug_message('Exception : OTHERS');
				Dka_Tools_Pkg.put_outdebug_message('Message   : '||v_message);
				Dka_Tools_Pkg.put_log_message( CHR(10)||p_errbuf);
				Dka_Tools_Pkg.put_outdebug_message('Cause     : '||v_sqlerrm);
				Dka_Tools_Pkg.put_outdebug_message('------------------------------------------------');
				Dka_Tools_Pkg.put_log_message('=========================================================================');
				Dka_Tools_Pkg.put_log_message('Traitement '||v_nom_traitement||' terminé en erreur         ');
				Dka_Tools_Pkg.put_log_message('=========================================================================');
				ROLLBACK;

		END main;
	  
		
	END DKA_IPOFRS_IVALUA_PKG;

	/
	SHOW ERRORS
	EXIT;