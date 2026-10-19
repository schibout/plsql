	create or replace PACKAGE BODY DKA_SAPFRSDUPLI_MASSE_PKG IS

	--------------------------------------------------------------------------------
	-- $$
	-- Capgemini
	-- Projet           : DALKIA Oracle Applications
	-- Nom              : DKA_SAPFRSDUPLI_MASSE_PKG.pkb
	-- Description      : DKA_SAPFRSDUPLI_MASSE_PKG package body
	-- Auteur           : S.HAHIOUI(Capgemini)
	-- Date de création : 15/01/2020
	-- Doc. associée    :
	-- Commentaire      : À exécuter sous SQLPLUS avec l'utilisateur APPS
	--------------------------------------------------------------------------------
	-- Historique
	-- Date       Version Qui Description
	-- ---------- ------- --- --------------------------------------------------------------
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- CONSTANTES ET VARIABLES PRIVEES
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
		l_erreur                l_erreur_dupli;
		l_averti                l_avertissement;
		vn_cpt_existe           NUMBER := 0;
		vn_cpt_site             NUMBER := 0;
		vn_cpt_avt              NUMBER := 0;
		g_package               VARCHAR2(30)  := 'DKA_SAPFRSDUPLI_MASSE_PKG';
		g_nom_traitement        VARCHAR2(200) := 'DKA:Duplication en masse des sites fournisseurs';
		g_sqlerrm               VARCHAR2(500) := NULL;
		g_retproc               NUMBER        := 0;
		g_user                  NUMBER        := fnd_profile.value('USER_ID');
		g_login_id              fnd_logins.login_id%TYPE     := fnd_global.login_id;
		g_request_id            NUMBER        := fnd_global.conc_request_id;

		g_nombre_succes         NUMBER := 0;
		g_nombre_echoues        NUMBER := 0;
		g_nombre_ignores        NUMBER := 0;
		g_nombre_existe         NUMBER := 0;
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	-- FONCTIONS ET PROCEDURES PRIVEES
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	------------------------------------------------------------------------------------
	-- Nom              : Output_header
	-- Description      : Procédure de duplication en masse des sites fournisseurs
	--
	-- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
	--                    pn_retgcc     Sortie gcc Retour de la procédure
	--                                   '0' : Normal
	--                                   '1' : Avertissement
	--                                   '2' : Erreur
	--
	------------------------------------------------------------------------------------
	PROCEDURE output_header is
	BEGIN

		Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
		Dka_Tools_Pkg.Put_Outdebug_Message(' COMPTE-RENDU DU TRAITEMENT « '||g_nom_traitement||' » ');
		Dka_Tools_Pkg.Put_Outdebug_Message(' Traitement n° '||g_request_id);
		Dka_Tools_Pkg.Put_Outdebug_Message(' Programme lancé le  : ' ||to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
		Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------------------------------------');
			
	END;

	   /*============================================================================*/
	  /* Procedure         : writelog                                               */
	  /* Description       : Ecriture dans fichier *.LOG                            */
	  /* Parametres entree : P_message IN VARCHAR2 : message a ecrire               */
	  /*                   : P_av      IN NUMBER   : Nb de saut de ligne avant      */
	  /*                   : P_ap      IN NUMBER   : Nb de saut de ligne apres      */
	  /* Parametres sortie : AUCUN                                                  */
	  /*============================================================================*/
	  PROCEDURE writelog(p_message IN VARCHAR2, p_av IN NUMBER, p_ap IN NUMBER)
	  IS

	  i                             NUMBER       := 0;
	  l_procedure                   VARCHAR2(30) := 'writelog';
	  v_etape                     VARCHAR2(2000);

	  BEGIN
		  v_etape := 'appel a FND_FILE.PUT_LINE';

		  FOR i IN 1 .. p_av
		  LOOP
			  fnd_file.put_line(fnd_file.LOG, ' ');
		  END LOOP;

		  fnd_file.put_line(fnd_file.LOG, p_message);

		  FOR i IN 1 .. p_ap
		  LOOP
			  fnd_file.put_line(fnd_file.LOG, ' ');
		  END LOOP;
	  EXCEPTION
		  WHEN OTHERS THEN
			  g_retproc := 1;
			  g_sqlerrm := substr(sqlerrm, 1, 500);
			  writelog('-------------------- ERREUR --------------------', 1, 0);
			  writelog('Package   : ' || g_package, 0, 0);
			  writelog('Procedure : ' || l_procedure, 0, 0);
			  writelog('Exception : OTHERS', 0, 0);
			  writelog('Message   : ' || v_etape, 0, 0);
			  writelog('Cause     : ' || g_sqlerrm, 0, 0);
			  writelog('------------------------------------------------', 0, 0);
	  END writelog;
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
			cv_line    := '+-------------------------------------------------------------------------+';
			Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
			Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
			Fnd_File.put_line (Fnd_File.output, cv_line);
	  END output_end;

	 /*============================================================================*/
	  -- Procedure         : writeout
	  -- Description       : Ecriture dans fichier *.OUT
	  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
	  -- Parametres sortie : AUCUN
	  -- Auteur            : Saloua HA
	  -- Date              : 14/01/2020
	  -- Remarques         :
	/*============================================================================*/
	PROCEDURE writeout(P_message IN VARCHAR2) IS
	  L_procedure VARCHAR2(30) := 'writeout';
	  v_etape   VARCHAR2(100);
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
	/*
	 *************************************************************************
	 * PROCEDURE NAME : Report_Bilan
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
	PROCEDURE Report_Bilan(p_Errbuf            OUT VARCHAR2,
							 p_retcode           OUT NUMBER
							 )
	IS
	vv_message varchar2(1000);
	BEGIN

		Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

		--------------------
		-- Initialisation --
		--------------------

		p_Errbuf  := NULL;
		p_retcode := 0;

		fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
		fnd_file.put_line(fnd_file.OUTPUT,'BILAN :');
		fnd_file.put_line(fnd_file.OUTPUT,'-------');

		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de sites fournisseurs dupliqués avec succès                                 :'||g_nombre_succes);
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de sites fournisseurs non dupliqués car déjà existants                      :'||g_nombre_existe);
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de sites fournisseurs non dupliqués car à ignorer                           :'||g_nombre_ignores);
		fnd_file.put_line(fnd_file.OUTPUT,'   . Nombre de sites fournisseurs pour lesquels la duplication a échoué                 :'||g_nombre_echoues);
		fnd_file.put_line(fnd_file.OUTPUT,CHR(10));




		IF l_erreur.count > 0 
		THEN
			fnd_file.put_line(fnd_file.OUTPUT,'LISTE DES ERREURS DE DUPLICATION :');
			fnd_file.put_line(fnd_file.OUTPUT,'----------------------------------');
			fnd_file.put_line(fnd_file.OUTPUT,' ');
			writeout( RPAD('Fichier',50)||RPAD('N° Ligne',20)||RPAD('N° frs',20)||RPAD('Code site',20)||RPAD('Périmètre',20)||RPAD('Message erreur',500));
			writeout( RPAD('--------',50)||RPAD('------------------',20)||RPAD('------------------',20)||RPAD('---------',20)||RPAD('----------',20)||RPAD('--------------',500));

			  FOR i IN l_erreur.first..l_erreur.last 
			LOOP
				 vv_message := RPAD(l_erreur(i).NOM_FICHIER,50)||RPAD(l_erreur(i).NUM_LIGNE,20)||RPAD(nvl(l_erreur(i).NUM_FOURNISSEUR,' '),20)||RPAD(nvl(l_erreur(i).CODE_SITE,' '),20)||RPAD(nvl(l_erreur(i).UO_SITE,' '),20)||RPAD(l_erreur(i).MSG_erreur,500);
			   writeout(vv_message);

			  END LOOP;

		  END IF ;
		fnd_file.put_line(fnd_file.OUTPUT,CHR(10));

			
		IF l_averti.count > 0 
		THEN
			fnd_file.put_line(fnd_file.OUTPUT,' ');
			fnd_file.put_line(fnd_file.OUTPUT,'LISTE DES AVERTISSEMENTS LIES AUX SITES NON DUPLIQUES :');
			fnd_file.put_line(fnd_file.OUTPUT,'-------------------------------------------------------');
			fnd_file.put_line(fnd_file.OUTPUT,' ');
			writeout( RPAD('Fichier',50)||RPAD('N° Ligne',20)||RPAD('N° frs',20)||RPAD('Code site',20)||RPAD('Périmètre',20)||RPAD('Message avertissement',500));
			writeout( RPAD('--------',50)||RPAD('------------------',20)||RPAD('------------------',20)||RPAD('---------',20)||RPAD('----------',20)||RPAD('---------------------',500));

			FOR i IN l_averti.first..l_averti.last 
			LOOP
				vv_message := RPAD(l_averti(i).NOM_FICHIER,50)||RPAD(l_averti(i).NUM_LIGNE,20)||RPAD(l_averti(i).NUM_FOURNISSEUR,20)||RPAD(l_averti(i).CODE_SITE,20)||RPAD(l_averti(i).UO_SITE,20)||RPAD(l_averti(i).MSG_erreur,500);
				writeout(vv_message);

			END LOOP;

		 END IF ;

		 fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
		 Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');


	EXCEPTION
	WHEN OTHERS
	THEN
			p_retcode   := 2;
			p_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
			Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
			Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
	END Report_Bilan;


	------------------------------------------------------------------------------------
	-- Nom              : DKA_SAPFRSDUPLI_MASSE
	-- Description      : Procédure de duplication en masse des sites fournisseurs
	--
	-- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
	--                    pn_retgcc     Sortie gcc Retour de la procédure
	--                                   '0' : Normal
	--                                   '1' : Avertissement
	--                                   '2' : Erreur
	--                  pv_type_fusion type de fusion
	--
	--
	-- VALEUR RETOURNEE :
	-- Description       :
	-- Valeurs possibles :
	------------------------------------------------------------------------------------

	PROCEDURE DKA_SAPFRSDUPLI_MASSE (
									  p_errbuf                  OUT VARCHAR2
									 ,p_retcode                 OUT NUMBER
									 )
	IS
	  vv_perimetre               DKA_SAPFRSDUPLI_PKG.tabtype;
	  vv_retcode                 NUMBER;
	  vv_nombre_succes           NUMBER := 0;
	  vv_nombre_echoues          NUMBER := 0;
	  vv_nombre_ignores          NUMBER := 0;
	  V_ACTION_ID                NUMBER;
	  v_statut                   VARCHAR2(2);
	  vv_resultat_duplication    VARCHAR2(10);
	  vv_nombre_existe           NUMBER:= 0;
	  vv_id_liste_erreur         NUMBER;
	  vv_id_site_cree            NUMBER;
	  vv_region_uo               DKA_SAPFRSDUPLI_MASSE_TMP.PERIMETRE_DUPLI%type;
	  vv_vendor_site_id          ap_supplier_sites_all.vendor_site_id%type;
	  vd_vendor_site_id          ap_supplier_sites_all.vendor_site_id%type;
	  vv_location_id             ap_supplier_sites_all.location_id%type;
	  vv_message                 varchar2(1000);
	  vd_inactive_date           DATE;
	  Erreur_Prog                EXCEPTION;

	--DEBUT SHA
	  CURSOR c_fournisseurs IS
		SELECT RECORD_ID
			  ,VENDOR_NUM
			  ,ID_IVALUA
			  ,VENDOR_SITE_CODE_REF
			  ,PERIMETRE_DUPLI
			  ,LINE_NUM
			  ,FILE_NAME
		FROM DKA_SAPFRSDUPLI_MASSE_TMP dsmt,
			 FND_LOGINS fl
		WHERE dsmt.STATUT   = 'NEW'
		AND   dsmt.CREATED_BY = fl.USER_ID
		AND   fl.LOGIN_ID = g_login_id
		AND   ((fl.SUBMITTED_LOGIN_ID != -1 AND dsmt.LOGIN_ID = fl.SUBMITTED_LOGIN_ID) 
		 OR   (fl.SUBMITTED_LOGIN_ID = -1 AND FILE_NAME = 'IVALUA')) -- Cas particulier pour iValua
		ORDER BY  LINE_NUM asc;
	--FIN SHA

		TYPE t_fournisseurs IS TABLE OF c_fournisseurs%ROWTYPE index by binary_integer;
		lt_fournisseurs t_fournisseurs;


	BEGIN

	   p_retcode           := 0;
	   p_errbuf            := NULL;
	 
	   Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début duplication en masse');
		writelog(g_login_id,0,0);
	   OPEN c_fournisseurs;
		 FETCH c_fournisseurs BULK COLLECT INTO lt_fournisseurs;
	   CLOSE c_fournisseurs;

	   IF lt_fournisseurs.COUNT > 0 THEN
		  FOR i in lt_fournisseurs.FIRST..lt_fournisseurs.LAST 
		  LOOP

			 vv_nombre_existe 	 := 0;
			 vv_nombre_succes    := 0;
			 vv_nombre_echoues   := 0;
			 vv_nombre_ignores   := 0;

			 BEGIN
				SELECT
					 PERIMETRE_DUPLI
				BULK COLLECT INTO
					 vv_perimetre
				FROM
					  DKA_SAPFRSDUPLI_MASSE_TMP
				WHERE RECORD_ID = lt_fournisseurs(i).RECORD_ID;

			 EXCEPTION
			 WHEN OTHERS THEN
				 writelog('Problème pour trouver le vv_perimetre',0,0);
				 vv_perimetre := NULL;
			 END;

			 BEGIN
				SELECT DISTINCT vendor_site_id  , assa.location_id
				INTO  vv_vendor_site_id         , vv_location_id 
				FROM  ap_supplier_sites_all assa,
					  ap_suppliers   ass,
					  hr_operating_units hou
				WHERE assa.vendor_site_code = lt_fournisseurs(i).vendor_site_code_ref
				AND   assa.vendor_id        = ass.vendor_id 
				AND   ass.segment1          = lt_fournisseurs(i).VENDOR_NUM
				AND   assa.org_id           = hou.organization_id
				AND   hou.name              = 'REF9999'
				;
			 EXCEPTION
			 WHEN OTHERS THEN
				 vv_vendor_site_id :=0;
			 END;

			 --DEBUT SHA
			 IF vv_vendor_site_id = 0 
			 THEN 
				BEGIN
				   SELECT DISTINCT vendor_site_id , assa.location_id
				   INTO  vv_vendor_site_id        , vv_location_id 
				   FROM  ap_supplier_sites_all assa,
						 ap_suppliers ass,
						 hr_operating_units hou
				   WHERE assa.attribute4       = lt_fournisseurs(i).ID_IVALUA
				   AND   assa.vendor_id        = ass.vendor_id 
				   AND   ass.segment1          = lt_fournisseurs(i).VENDOR_NUM
				   AND   assa.org_id           = hou.organization_id
				   AND   hou.name              = 'REF9999'
				   ;
				EXCEPTION
				WHEN OTHERS THEN
				  vv_vendor_site_id :=0;
				END;
				--FIN SHA

				  IF vv_vendor_site_id = 0 
				  THEN 
						vn_cpt_site    := vn_cpt_site + 1;
						SELECT ACTION_ID_S.nextval
						INTO   V_ACTION_ID
						FROM   DUAL;

						INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
												   v_action_id,
												   vv_vendor_site_id,
												   9,
												  'ERREUR',
												  'Le site fournisseur n''existe pas sur la référence.',
												   SYSDATE,
												   g_user
												  );
						l_erreur(vn_cpt_site).NUM_FOURNISSEUR      := lt_fournisseurs(i).VENDOR_NUM;
						l_erreur(vn_cpt_site).CODE_SITE            := lt_fournisseurs(i).vendor_site_code_ref;
						l_erreur(vn_cpt_site).UO_SITE              := lt_fournisseurs(i).PERIMETRE_DUPLI;
						l_erreur(vn_cpt_site).NOM_FICHIER          := lt_fournisseurs(i).FILE_NAME;
						l_erreur(vn_cpt_site).NUM_LIGNE            := lt_fournisseurs(i).LINE_NUM;
						l_erreur(vn_cpt_site).MSG_erreur           :='Le site fournisseur n''existe pas sur la référence.';
		
						p_retcode := 1;
						g_nombre_echoues := g_nombre_echoues + 1;

						
						UPDATE DKA_SAPFRSDUPLI_MASSE_TMP
						SET STATUT = 'REJECTED'
						   ,ERROR_ID  = v_action_id
						   ,NBR_DUPLI_OK = 0
						   ,NBR_DUPLI_KO = 1
						   ,NBR_SITE_EXIST = 0
						   ,NBR_SITE_IGNORED = 0
						WHERE record_id = lt_fournisseurs(i).RECORD_ID;

						COMMIT;
				  END IF;
			 END IF;   -- end if recherche site
			 
			  
			 IF vv_vendor_site_id != 0 
			 THEN
			 
				BEGIN
				   SELECT assa.inactive_date
				   INTO  vd_inactive_date
				   FROM  ap_supplier_sites_all assa,
						 hr_operating_units hou
				   WHERE assa.vendor_site_id = vv_vendor_site_id
				   AND   assa.org_id = hou.organization_id
				   AND   hou.name    = 'REF9999'
				   ;
				EXCEPTION
				WHEN OTHERS THEN
					 vd_inactive_date := trunc(SYSDATE-1);
				END;

				IF (vd_inactive_date IS NOT NULL AND vd_inactive_date < SYSDATE) 
				THEN 
					vn_cpt_site    := vn_cpt_site + 1;
					SELECT ACTION_ID_S.nextval
					INTO   V_ACTION_ID
					FROM   DUAL;

					INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
												   v_action_id,
												   vv_vendor_site_id,
												   9,
												  'ERREUR',
												  'Le site fournisseur n''est pas actif sur la référence.',
												   SYSDATE,
												   g_user
												  );
					l_erreur(vn_cpt_site).NUM_FOURNISSEUR      := lt_fournisseurs(i).VENDOR_NUM;
					l_erreur(vn_cpt_site).CODE_SITE            := lt_fournisseurs(i).vendor_site_code_ref;
					l_erreur(vn_cpt_site).UO_SITE              := lt_fournisseurs(i).PERIMETRE_DUPLI;
					l_erreur(vn_cpt_site).NOM_FICHIER          := lt_fournisseurs(i).FILE_NAME;
					l_erreur(vn_cpt_site).NUM_LIGNE            := lt_fournisseurs(i).LINE_NUM;
					l_erreur(vn_cpt_site).MSG_erreur           := 'Le site fournisseur n''est pas actif sur la référence.';
					p_retcode := 1;
					g_nombre_echoues := g_nombre_echoues + 1;

					BEGIN
					   UPDATE DKA_SAPFRSDUPLI_MASSE_TMP
					   SET STATUT = 'REJECTED'
						  ,ERROR_ID  = v_action_id
						  ,NBR_DUPLI_OK = 0
						  ,NBR_DUPLI_KO = 1
						  ,NBR_SITE_EXIST = 0
						  ,NBR_SITE_IGNORED = 0                   
					   WHERE record_id = lt_fournisseurs(i).RECORD_ID;
					EXCEPTION
					WHEN OTHERS THEN
						vv_message := ' Problème de modification de la table DKA_SAPFRSDUPLI_MASSE_TMP';
						p_retcode := 2;
						writelog(vv_message,0,0);
						RAISE Erreur_prog;
					END;
					COMMIT;

			ELSE
				--Début SHA
				BEGIN
				
				 SELECT  count(1)
				   INTO  vd_vendor_site_id
				   FROM  ap_supplier_sites_all assa,
						 hr_operating_units hou
				   WHERE assa.location_id      = vv_location_id 
				   AND   assa.org_id           = hou.organization_id
				   AND   hou.name              = 'REF9999'
				   ;
				EXCEPTION
				WHEN OTHERS THEN
					 vd_vendor_site_id := 0;
				
				END;
				  IF vd_vendor_site_id > 1  
				  THEN 
						vn_cpt_site    := vn_cpt_site + 1;
						SELECT ACTION_ID_S.nextval
						INTO   V_ACTION_ID
						FROM   DUAL;

						INSERT INTO dka_sapfrsdupli_error_tmp VALUES (
												   v_action_id,
												   vv_vendor_site_id,
												   9,
												  'ERREUR',
												  'Le site fournisseur n''est pas unique pour cette adresse sur la référence. ',
												   SYSDATE,
												   g_user
												  );
						l_erreur(vn_cpt_site).NUM_FOURNISSEUR      := lt_fournisseurs(i).VENDOR_NUM;
						l_erreur(vn_cpt_site).CODE_SITE            := lt_fournisseurs(i).vendor_site_code_ref;
						l_erreur(vn_cpt_site).UO_SITE              := lt_fournisseurs(i).PERIMETRE_DUPLI;
						l_erreur(vn_cpt_site).NOM_FICHIER          := lt_fournisseurs(i).FILE_NAME;
						l_erreur(vn_cpt_site).NUM_LIGNE            := lt_fournisseurs(i).LINE_NUM;
						l_erreur(vn_cpt_site).MSG_erreur           :='Le site fournisseur n''est pas unique pour cette adresse sur la référence. ';
		
						p_retcode := 1;
						g_nombre_echoues := g_nombre_echoues + 1;

						
						UPDATE DKA_SAPFRSDUPLI_MASSE_TMP
						SET STATUT = 'REJECTED'
						   ,ERROR_ID  = v_action_id
						   ,NBR_DUPLI_OK = 0
						   ,NBR_DUPLI_KO = 1
						   ,NBR_SITE_EXIST = 0
						   ,NBR_SITE_IGNORED = 0
						WHERE record_id = lt_fournisseurs(i).RECORD_ID;

						COMMIT;
					
					ELSE 
					DKA_SAPFRSDUPLI_PKG.DUPLICATION_SITE_FOURNISSEUR(
													vv_retcode,
													vv_perimetre,
													vv_vendor_site_id,
													vv_nombre_succes,
													vv_nombre_echoues,
													vv_nombre_ignores,
													vv_resultat_duplication,
													vv_nombre_existe,
													vv_id_liste_erreur,
													vv_id_site_cree
													  );

					writelog('vv_nombre_succes '||vv_nombre_succes,0,0);
					writelog('vv_nombre_echoues '||vv_nombre_echoues,0,0);

					-- Récupération des messages d'avertissement
					IF (vv_nombre_ignores > 0 OR vv_nombre_existe > 0)
					THEN
						--Initialisation du tableau
						FOR rec_averti IN (SELECT * FROM DKA_SAPFRSDUPLI_ERROR_TMP
										   WHERE  ACTION_ID = vv_id_liste_erreur
											 AND  UPPER(MESSAGE_TYPE) = 'AVERTISSEMENT') 
						LOOP
							vn_cpt_avt    := vn_cpt_avt + 1;
			
							l_averti(vn_cpt_avt).NUM_FOURNISSEUR      := lt_fournisseurs(i).VENDOR_NUM;
							l_averti(vn_cpt_avt).CODE_SITE            := lt_fournisseurs(i).vendor_site_code_ref;
							l_averti(vn_cpt_avt).UO_SITE              := lt_fournisseurs(i).PERIMETRE_DUPLI;
							l_averti(vn_cpt_avt).NOM_FICHIER          := lt_fournisseurs(i).FILE_NAME;
							l_averti(vn_cpt_avt).NUM_LIGNE            := lt_fournisseurs(i).LINE_NUM;
							l_averti(vn_cpt_avt).MSG_erreur           := rec_averti.error_message;
	   
						END LOOP;
					END IF;

					IF vv_nombre_echoues > 0 
					THEN
						--Initialisation du tableau
						FOR rec_erreur IN (SELECT * FROM DKA_SAPFRSDUPLI_ERROR_TMP
										   WHERE  ACTION_ID = vv_id_liste_erreur
											 AND  MESSAGE_TYPE = 'ERREUR') 
						LOOP
							vn_cpt_site    := vn_cpt_site + 1;
			
							l_erreur(vn_cpt_site).NUM_FOURNISSEUR      := lt_fournisseurs(i).VENDOR_NUM;
							l_erreur(vn_cpt_site).CODE_SITE            := lt_fournisseurs(i).vendor_site_code_ref;
							l_erreur(vn_cpt_site).UO_SITE              := lt_fournisseurs(i).PERIMETRE_DUPLI;
							l_erreur(vn_cpt_site).NOM_FICHIER          := lt_fournisseurs(i).FILE_NAME;
							l_erreur(vn_cpt_site).NUM_LIGNE            := lt_fournisseurs(i).LINE_NUM;
							l_erreur(vn_cpt_site).MSG_erreur           := rec_erreur.error_message;
	   
						END LOOP;
						vv_message := '====> ERREUR :Le traitement de duplication a échoué';
						writelog(vv_message,0,0);

						BEGIN
						   UPDATE DKA_SAPFRSDUPLI_MASSE_TMP
							  SET STATUT = 'REJECTED'
								 ,ERROR_ID  = vv_id_liste_erreur
								 ,NBR_DUPLI_OK = vv_nombre_succes
								 ,NBR_DUPLI_KO = vv_nombre_echoues
								 ,NBR_SITE_EXIST = vv_nombre_existe
								 ,NBR_SITE_IGNORED = vv_nombre_ignores
						   WHERE record_id = lt_fournisseurs(i).RECORD_ID;
						EXCEPTION
						WHEN OTHERS THEN
							vv_message := ' Problème de modification de la table DKA_SAPFRSDUPLI_MASSE_TMP';
							writelog(vv_message,0,0);
							p_retcode := 2;
							p_errbuf := vv_message;
							RAISE Erreur_prog;
						END;

						p_retcode := 1;
						COMMIT;
		
					ELSE
						BEGIN
						   UPDATE DKA_SAPFRSDUPLI_MASSE_TMP
							  SET STATUT = 'SUCCESS'
								 ,ERROR_ID  = vv_id_liste_erreur
								 ,NBR_DUPLI_OK = vv_nombre_succes
								 ,NBR_DUPLI_KO = vv_nombre_echoues
								 ,NBR_SITE_EXIST = vv_nombre_existe
								 ,NBR_SITE_IGNORED = vv_nombre_ignores
						   WHERE record_id = lt_fournisseurs(i).RECORD_ID;
		
						   COMMIT;
						EXCEPTION
						WHEN OTHERS THEN
							fnd_file.put_line(fnd_file.OUTPUT,'Problème de modification de la table DKA_SAPFRSDUPLI_MASSE_TMP') ;
							writelog(vv_message,0,0);
							p_retcode := 2;
							p_errbuf := vv_message;
							RAISE Erreur_prog;
						END;

					END IF; -- duplication en erreur
	 

					g_nombre_echoues  := g_nombre_echoues + vv_nombre_echoues ;
					g_nombre_succes   := g_nombre_succes + vv_nombre_succes ;
					g_nombre_existe   := g_nombre_existe + vv_nombre_existe ;
					g_nombre_ignores  := g_nombre_ignores + vv_nombre_ignores;
					
				END IF;--unicité du site
				END IF; -- site actif
				   

			 END IF; -- Site existe




	   END LOOP;--LOOP SITE
	   END IF;--SITE


	 Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin duplication en masse');

	EXCEPTION
	WHEN Erreur_prog 
	THEN
		p_retcode := 2;
		p_errbuf := 'ERREUR TECHNIQUE : '||p_errbuf;
	END;---procédure duplication en masse
	--DEBUT SHA
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

			DELETE FROM DKA_SAPFRSDUPLI_ERROR_TMP 
			WHERE  ACTION_ID in ( select ERROR_ID 
								  from   DKA_SAPFRSDUPLI_MASSE_TMP DSMT
								  WHERE  DSMT.statut    != 'NEW'
								  and    DSMT.FILE_NAME not like '%IVALUA%' 
								);


			DELETE DKA_SAPFRSDUPLI_MASSE_TMP DSMT
			WHERE  DSMT.statut    != 'NEW'
			AND    DSMT.FILE_NAME not like '%IVALUA%' ;

			Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||' - fin ' || v_current_program_unit);
		COMMIT;	
		EXCEPTION
			WHEN OTHERS
			THEN
				pn_retcode   := 2;
				pv_errbuf    := 'PURGE_DATA : ' ||SQLERRM;   
		END purge_data;
	 --FIN SHA
	------------------------------------------------------------------------------------
	-- Nom              : MAIN
	-- Description      : Main de duplication en masse des sites fournisseurs
	--
	-- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
	--                    pn_retgcc     Sortie gcc Retour de la procédure
	--                                   '0' : Normal
	--                                   '1' : Avertissement
	--                                   '2' : Erreur
	--                  pv_type_fusion type de fusion
	--
	--
	-- VALEUR RETOURNEE :
	-- Description       :
	-- Valeurs possibles :
	------------------------------------------------------------------------------------
	  PROCEDURE main( p_errbuf           OUT VARCHAR2,
					  p_retcode           OUT NUMBER)
		IS
		v_errbuf                   VARCHAR2(2500);
		v_retcode                  NUMBER;
		Erreur_Programme           EXCEPTION;
		v_warning                  BOOLEAN := FALSE;
		l_path_c                   VARCHAR2(240) := 'DKA_IN_DIR';
		v_chemin_fichier           VARCHAR2(500);
		v_responsibility_id        NUMBER;
		v_application_id           NUMBER;

	BEGIN

		v_errbuf  := NULL;
		v_retcode := 0;
		output_header;


		--Positionnement du programme sur la responsabilité DKA_GESTION_REFERENTIEL_FOURNISSEURS qui a accès à toutes les UO   
		BEGIN
		   SELECT responsibility_id,application_id
		   INTO v_responsibility_id,v_application_id
		   FROM fnd_responsibility_vl
		   WHERE responsibility_key = 'DKA_GESTION_REF_FOURNISS';
		EXCEPTION
		WHEN OTHERS THEN
		   v_errbuf  := 'ERREUR : Impossible de se positionner sur la responsabilité DKA_GESTION_REFERENTIEL_FOURNISSEURS';
		   RAISE Erreur_Programme;
		END;   


		fnd_global.apps_initialize(user_id => g_user, resp_id => v_responsibility_id, resp_appl_id => v_application_id);

		--Purger la table de travail
		PURGE_DATA(v_errbuf, v_retcode);

		IF v_retcode = 2
		  THEN
			  p_Errbuf  := v_errbuf;
			  p_retcode := v_retcode;
			  RAISE Erreur_Programme;
		END IF;

		-- Lancement de la duplication en masse 

		DKA_SAPFRSDUPLI_MASSE ( v_errbuf,
								v_retcode
							 );


		IF v_retcode = 2
		THEN
			  p_Errbuf  := v_errbuf;
			  p_retcode := v_retcode;
			  RAISE Erreur_Programme;
		ELSIF v_retcode = 1
		THEN
			  p_retcode  := v_retcode;
		END IF;

		Report_Bilan ( v_errbuf,
					   v_retcode
					 );

		

		IF p_retcode = 2
		THEN
			 p_errbuf := 'ATTENTION : Erreur bloquante : '||p_errbuf;
		ELSIF (p_retcode = 1 OR g_nombre_echoues !=0) 
		THEN
			 p_errbuf := 'ATTENTION : Il y a des cas de rejet.';
			 p_retcode := 1;
		ELSE
			 p_errbuf := 'Fin normale du traitement - Aucun rejet.';
			 p_retcode := 0;
		END IF;

	COMMIT;


		  Fnd_File.put_line (Fnd_File.LOG, v_retcode);
		  Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
		  Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf||CHR(10));
		  output_end;
		  Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');


		EXCEPTION
			WHEN Erreur_Programme
			THEN
				p_retcode   := 2;
				p_errbuf    := v_errbuf;
				Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
				Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||p_errbuf);

			WHEN OTHERS
			THEN
			   fnd_concurrent.af_rollback;
			   p_retcode := 2;

			   Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
			   p_errbuf := SQLERRM;


	END;



	END;--body/


	/
	SHOW ERRORS
	EXIT
