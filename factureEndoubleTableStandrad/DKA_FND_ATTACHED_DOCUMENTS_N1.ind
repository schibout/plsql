CREATE OR REPLACE PACKAGE BODY DKA_REPPAREVENUIMP_PKG IS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REPPAREVENUIMP_PKG.sql                              -
    -- Version : 1.0                                                     -
    -- AUTEUR  : J.PELAT SOCIETE : CAPGEMINI          				     -
    -- DATE    : 28/04/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR : Reprise DES REVENUS Import                      		 -
    -- FONCTION   : SFD001                                               -
    --                                                                   -
    --                                                                   -
    ----------------------------------------------------------------------
    -- VERSION              :        1.0                                 -
    -- PROGRAMME MODIFIE LE :        20/10/2016                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        artf2014423, artf2030027, artf2024248
    -- OBJET                :        Pb dans la gestion de la date,
    --                               Modification de la description de l'événement repris,
    --                               Plusieurs anomalies à corriger                                -                                   -
    --                                                                   -

    -- VERSION              :        1.1                                 -
    -- PROGRAMME MODIFIE LE :        27/10/2016                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        Ajout des status et des messages d'erreur, plus gestion des resp.
    --                               multi-org.
    --                                                                   -
    -- VERSION              :        1.2                                 -
    -- PROGRAMME MODIFIE LE :        09/11/2016                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        Gestion des exceptions lies aux evenements manquants
    --                               artf2041766 : Rejets de toutes les lignes de l'import des revenus
    --                                                                   -
    -- VERSION              :        1.3                                 -
    -- PROGRAMME MODIFIE LE :        09/01/2017                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        artf2074070 - Reprise des revenus - Import des CCA/TEC/PCA
    --                                                                   -
    --                                                                   -
    -- VERSION              :        1.4                                 -
    -- PROGRAMME MODIFIE LE :        18/01/2017                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        artf2074070 - Reprise des revenus - Import des CCA/TEC/PCA
    --                                                                   -
    --                                                                   -
    -- VERSION              :        1.5                                 -
    -- PROGRAMME MODIFIE LE :        08/02/2017                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        artf2096822 - RUN3 - Reprise des revenus - Alimentation de l'ATT_CAT pour les TEC et PCA DEBUT
    --                                                                   -
    -- VERSION              :        1.6                                 -
    -- PROGRAMME MODIFIE LE :        13/02/2017                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        artf2096822 - RUN3 - Reprise des revenus - Alimentation de l'ATT_CAT pour les TEC et PCA DEBUT
    --                                                                   -
    -- VERSION              :        1.7                                 -
    -- PROGRAMME MODIFIE LE :        02/03/2017                                    -
    -- PAR                  :        N. BOUSSEKEYT                                    -
    -- NUM_ANOMALIE         :        artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
	--								 artf2108043 - DEFECT 579 - Certains événements sont repris avec un mauvais TASK_ID 
    --                                                                   -
    -- VERSION              :        1.8                                 -
    -- PROGRAMME MODIFIE LE :        24/07/2017                          -
    -- PAR                  :        A. DEBRY                            -
    -- NUM_ANOMALIE         :        artf2200431 : Reprise des revenus projets - Ajouter un contrÃ´le sur les dates de validité du projet
    --
    -- VERSION              :        1.9                                 -
    -- PROGRAMME MODIFIE LE :        30/08/2017                          -
    -- PAR                  :        N. BOUSSEKEYT                       -
    -- NUM_ANOMALIE         :        artf2200431 : Reprise des revenus projets - Ajouter un contrÃ´le sur les dates de validité du projet
    --
    -- VERSION              :        1.10                                 -
    -- PROGRAMME MODIFIE LE :        19/09/2017                          -
    -- PAR                  :        N. BOUSSEKEYT                       -
    -- NUM_ANOMALIE         :        artf2200431 : Reprise des revenus projets - Ajouter un contrÃ´le sur les dates de validité du projet
    --
    -- VERSION              :        1.11                                -
    -- PROGRAMME MODIFIE LE :        07/11/2017                          -
    -- PAR                  :        N. BOUSSEKEYT                       -
    -- NUM_ANOMALIE         :        artf2271904 : REPRISE_REVENUS - Ne plus créer les événements TEC PCA CCA de DEBUT
    --
    -- VERSION              :        1.12                               -
    -- PROGRAMME MODIFIE LE :        13/11/2017                          -
    -- PAR                  :        Maxime EGOT                      -
    -- NUM_ANOMALIE         :        artf2274430 : REPRISE_REVENUS - IMPORT R12 - Modification de la description des événements repris
    --
    ----------------------------------------------------------------------
   --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    g_user_id                   fnd_user.user_id%TYPE;
    g_login_id                  fnd_logins.login_id%TYPE;
    g_request_id                fnd_concurrent_requests.request_id%TYPE;
    g_loader_request_id         fnd_concurrent_requests.request_id%TYPE;
	g_resp_id 					fnd_responsibility_tl.responsibility_id%TYPE;
    g_appl_id 				  	fnd_responsibility_tl.application_id%TYPE;

	g_tempo            	NUMBER;
    g_nb_event_cree 	NUMBER    :=0;
	g_nb_event_charger 	NUMBER    :=0;
    g_nb_event_rejete  	NUMBER    :=0;
    g_nb_event_nonvalide NUMBER  :=0;
    -- NBO - 26/10/16 - Ajout des status
    gv_status_new VARCHAR2(50) := 'NEW';
    gv_status_valid VARCHAR2(50) := 'VALID';
    gv_status_invalid VARCHAR2(50) := 'INVALID';
    gv_status_reject VARCHAR2(50) := 'REJECTED';
    gv_status_ok VARCHAR2(50) := 'OK';
    gv_step VARCHAR2(100);
    gv_period VARCHAR2(100);

	-- 09/01/2017 NBO artf2074070 - Reprise des revenus - Import des CCA/TEC/PCA
    gv_et_cca_debut VARCHAR2(50) := 'CCA SINISTRES DEBUT';
    gv_et_cca_fin VARCHAR2(50) := 'CCA SINISTRES FIN';
    gv_et_pca_debut VARCHAR2(50) := 'PCA ERE DEBUT';
    gv_et_pca_fin VARCHAR2(50) := 'PCA ERE FIN';
    gv_et_tec_ci_debut VARCHAR2(50) := 'VARIATION DES T.E.C CI DEBUT';
    gv_et_tec_ci_fin VARCHAR2(50) := 'VARIATION DES T.E.C CI FIN';
    gv_et_tec_debut VARCHAR2(50) := 'VARIATION DES T.E.C DEBUT';
    gv_et_tec_fin VARCHAR2(50) := 'VARIATION DES T.E.C FIN';

    /*
    *************************************************************************
    * PROCEDURE NAME : init
    *
    * DESCRIPTION
    * Procédure d'initialisation des variables globales
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    * ----------------- ------------------------------------------------------
    * pv_errbuf         Retour de message éventuel
    * pn_retcode        Statut du traitement en sortie
    ************************************************************************
    */
    PROCEDURE init
    IS
    BEGIN

        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init');

        ------------------------
        -- Variables globales --
        ------------------------

        g_login_id    := fnd_global.login_id;
        g_request_id  := fnd_global.conc_request_id;
        g_tempo       := 20;
		g_user_id 	  := fnd_global.user_id;

        Dka_Tools_Pkg.put_log_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init');

    END init;

    /*
    *************************************************************************
    * PROCEDURE NAME : init_environement
    *
    * DESCRIPTION
    *  Procédure d'initialisation de l'environnement 
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    * -----------------------------------------------------------------------
    * pv_uniteope       Numéro de l'unite operationnelle
    *************************************************************************
    */
    -- NBO 20/10/16 - Gestion des exceptions
    -- NBO 27/10/16 - Gestion des Responsabilités multi-org
    PROCEDURE init_environement (pv_errbuf IN OUT VARCHAR2, pn_retcode IN OUT NUMBER,  pv_uniteope IN VARCHAR2, pn_org_id NUMBER)
    IS
    BEGIN
        BEGIN
			SELECT responsibility_id
				  ,application_id
			INTO
			g_resp_id,
			g_appl_id
			FROM  fnd_responsibility_tl
			--WHERE responsibility_name   = pv_uniteope || '_PA_ADMINISTRATEUR'
      WHERE responsibility_name   = 'TOUT_PA_ADMINISTRATEUR'
			AND   language = FND_GLOBAL.current_language;

             -- NBO 20/10/16 - Gestion des exceptions
			fnd_global.apps_initialize(g_user_id, g_resp_id, g_appl_id);
		  MO_GLOBAL.INIT ('PA');
      MO_GLOBAL.SET_POLICY_CONTEXT('S',pn_org_id);

			EXCEPTION
			WHEN NO_DATA_FOUND THEN
				dka_tools_pkg.put_outdebug_message('Erreur : La responsabilité ' || pv_uniteope || '_PA_ADMINISTRATEUR n''existe pas.'); 
				--ROLLBACK;
        		pv_errbuf := 'Erreur : La responsabilité ' || pv_uniteope || '_PA_ADMINISTRATEUR n''existe pas.';
        		pn_retcode := 2;
		END;

    END init_environement;

    /*
    *************************************************************************
    * PROCEDURE NAME : Launch_Loader
    *
    * DESCRIPTION
    * Procédure de lancement du programme de chargement dans la table spécifique
    *
    * PARAMETERS
    * ==========
    * NAME               DESCRIPTION
    * -----------------------------------------------------------------------
    * p_directory      	 Répertoire du fichier
    * p_file_name        Nom du fichier à charger
    * pv_errbuf          Retour de message éventuel
    * pn_retcode         Statut du traitement en sortie
    *
    *************************************************************************
    */
    PROCEDURE Launch_Loader(pv_errbuf  IN OUT VARCHAR2,
							pn_retcode IN OUT NUMBER,
							pv_NomFich IN VARCHAR2
							)
    IS
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);

    BEGIN
        v_message := '';
		Dka_Tools_Pkg.put_log_message('Debut Launch_Loader' || CHR(10));

        Dka_Tools_Pkg.put_log_message( 'CHARGEMENT DU FICHIER :');
        Dka_Tools_Pkg.put_log_message( '----------------------');

		------------------------------------------------------
        -- Lancement du traitement de chargement du fichier --
        ------------------------------------------------------

        -- Lancement du traitement
        g_loader_request_id          := Fnd_Request.submit_request (
                                             'DKA'                            -- APPL
                                            ,'DKA_REPPAREVENUIMP_LOADER'     -- PROG
                                            ,NULL                             -- PROGRAM_NAME
                                            ,NULL                             -- START
                                            ,FALSE                            -- SUB_REQUEST
                                            ,pv_NomFich);

        IF g_loader_request_id = 0
        THEN
            pn_retcode := 2;
            pv_errbuf  := 'Erreur : Le traitement de chargement du fichier DKA_REPPAREVENUIMP_LOADER a échoué' ;
            dka_tools_pkg.put_outdebug_message( 'Erreur : Le traitement de chargement du fichier DKA_REPPAREVENUIMP_LOADER a échoué ');
        ELSE
            COMMIT;
            Dka_Tools_Pkg.put_log_message( '=> LOAD REQUEST ID= ' || g_loader_request_id);
            dka_tools_pkg.put_outdebug_message( 'Numéro du traitement de chargement du fichier : ' || g_loader_request_id);  
            -- Attente de la fin du traitement
            IF NOT (Fnd_Concurrent.wait_for_request (g_loader_request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
            THEN
                pn_retcode := 2;
                pv_errbuf  := 'Erreur : Attente de la fin du programme de chargement du fichier DKA_REPPAREVENUIMP_LOADER dépassée : Fin du traitement' ;
                Dka_Tools_Pkg.put_outdebug_message( 'Erreur : Attente de la fin du programme de chargement du fichier DKA_REPPAREVENUIMP_LOADER dépassée : Fin du traitement ' || v_message);  
            END IF;
            dka_tools_pkg.put_outdebug_message( 'Statut de fin du traitement de chargement de la table spécifique : ' || v_dev_phase || '/' || v_dev_status);  

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL')
            THEN
                Dka_Tools_Pkg.put_log_message( 'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
            THEN
                Dka_Tools_Pkg.put_log_message( 'Fin du traitement de chargement en warning '|| g_loader_request_id);
                pn_retcode := 1;
            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')
            THEN
                pn_retcode := 2;
                pv_errbuf  := 'Erreur : Fin anormale du traitement de chargement : '|| g_loader_request_id;
                Dka_Tools_Pkg.put_outdebug_message( 'Erreur : Fin anormale du traitement de chargement '|| g_loader_request_id  || CHR(10) ||
													'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
													'MESSAGE : ' || v_message || CHR(10) );
            END IF;
        END IF;

        SELECT count(*) INTO g_nb_event_charger FROM DKA_REPPAREVENUIMP_TMP where load_request_id=g_loader_request_id;

        Dka_Tools_Pkg.put_log_message('Fin Launch_Loader');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'LAUNCH_LOADER : ' ||SQLERRM;
            Dka_Tools_Pkg.put_log_message( pv_errbuf);
            Dka_Tools_Pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Erreur : ' || 'Fin de la Procédure Launch_Loader : EXCEPTION OTHERS ');
    END Launch_Loader;

  /*************************************************************************
    * PROCEDURE NAME : Control_Data
    *
    * DESCRIPTION
    *  Procédure de lancement du programme de chargement dans la table spécifique
    *
    * PARAMETERS
    * ==========
    * NAME               DESCRIPTION
    * -----------------  ------------------------------------------------------
    * pv_errbuf          Retour de message éventuel
    * pn_retcode         Statut du traitement en sortie
    *
    ************************************************************************
    */
  -- NBO - 26/10/16 - Ajout des contôles avant import
  PROCEDURE control_data(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode IN OUT NUMBER) IS
    v_code_projet_new    VARCHAR2(100);
    v_tache_new          VARCHAR2(100);
    lv_errmsg            VARCHAR2(1000);
    l_count              NUMBER;

    CURSOR cur_tmp IS
      SELECT dka.*, dka.ROWID rid
        FROM dka_repparevenuimp_tmp dka
       WHERE status IN (gv_status_new, gv_status_valid, gv_status_invalid);

  BEGIN
    g_nb_event_nonvalide := 0;
    FOR rec_tmp IN cur_tmp LOOP

      -- Transco de la clé comptable
      dka_rep_transco_pkg.get_transco(pv_transco_name => '014_PROJETS',
                                      pv_column_01    => rec_tmp.code_projet,
                                      pv_out_01       => v_code_projet_new,
                                      pv_out_02       => v_tache_new);

      IF v_code_projet_new IS NOT NULL AND v_tache_new IS NOT NULL THEN
        UPDATE dka_repparevenuimp_tmp
           SET code_projet_new = v_code_projet_new, tache = v_tache_new
         WHERE ROWID = rec_tmp.rid;
      ELSE
        lv_errmsg := 'Le code projet n''est pas dans la table de transco.';

        UPDATE dka_repparevenuimp_tmp
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;

        g_nb_event_nonvalide := g_nb_event_nonvalide + 1;
        continue;
      END IF;

      SELECT COUNT(1)
        INTO l_count
        FROM pa_projects_all ppa, pa_project_fundings ppf
       WHERE ppa.segment1 = v_code_projet_new
         AND ppf.project_id = ppa.project_id;

      IF l_count = 0 THEN
        lv_errmsg := 'L''accord projet n''existe pas.';

        UPDATE dka_repparevenuimp_tmp
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;

         g_nb_event_nonvalide := g_nb_event_nonvalide + 1;
         continue;
      END IF;

       SELECT COUNT(1)
        INTO l_count
        FROM pa_projects_all ppa, pa_tasks pt
       WHERE ppa.segment1 = v_code_projet_new
         AND pt.project_id = ppa.project_id
         AND pt.task_number = v_tache_new;

      IF l_count = 0 THEN
        lv_errmsg := 'La tache n''existe pas.';

        UPDATE dka_repparevenuimp_tmp
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;

         g_nb_event_nonvalide := g_nb_event_nonvalide + 1;
         continue;
      END IF;

      -- NBO 09/11/16 - Gestion des exceptions liés aux événements manquants 
      SELECT COUNT(1)
      INTO l_count
      FROM PA_EVENT_TYPES
      WHERE event_type = rec_tmp.type_evenement;

      IF l_count = 0 THEN
        lv_errmsg := 'Le type d''evenement n''existe pas.';

        UPDATE dka_repparevenuimp_tmp
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;

         g_nb_event_nonvalide := g_nb_event_nonvalide + 1;
         continue;
      END IF;
      
      -- NBO 19/09/17 - artf2200431 Reprise des revenus projets - Ajouter un contrÃŽle sur les dates de validité du projet
     SELECT COUNT(1)
       INTO l_count
       FROM pa_projects_all ppa, pa_tasks pt
      WHERE ppa.segment1 = v_code_projet_new
        AND pt.project_id = ppa.project_id
        AND pt.task_number = v_tache_new
        AND NOT EXISTS (SELECT 'x'
            FROM pa_periods_all pp
       WHERE pp.period_name = gv_period
         AND pp.end_date between pt.start_date AND nvl(pt.completion_date,pp.end_date));

      IF l_count > 0 THEN
        lv_errmsg := 'La date de fin de période n''est pas dans la fourchette de la tache du projet';
        dka_tools_pkg.put_debug_message(lv_errmsg);

        UPDATE DKA_REPPAREVENUIMP_TMP
        SET    STATUS = gv_status_invalid,
               ERROR_MESSAGE = lv_errmsg
        WHERE rowid = rec_tmp.rid;
        
        g_nb_event_nonvalide := g_nb_event_nonvalide + 1;
        continue;
      END IF;

      UPDATE dka_repparevenuimp_tmp
         SET status = gv_status_valid, error_message = NULL
       WHERE ROWID = rec_tmp.rid;

    END LOOP;
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      dka_tools_pkg.put_log_message('control_data , SQLCODE : ' || SQLCODE ||
                                    'SQLERRM : ' || SQLERRM);
  END;

	/*
    *************************************************************************
    * PROCEDURE NAME : Transco_CodeProjet
    *
    * DESCRIPTION
    *  Procédure effectuant la transco et le chargement du nouveau code projet et tache dans la table temporaire
    *
    * PARAMETERS
    * ==========
    * NAME               DESCRIPTION
    * -----------------  ------------------------------------------------------
    *
    *
    ************************************************************************
    */
	PROCEDURE Transco_CodeProjet IS

		v_code_projet_NEW	VARCHAR2(25);
		v_tache_NEW	VARCHAR2(25);

    -- NBO 20/10/16 - Gestion des rowids pour éviter les problémes de curseur
		CURSOR cur_revenus
        IS
		SELECT tmp.*, tmp.rowid rid FROM DKA_REPPAREVENUIMP_TMP tmp
		WHERE load_request_id = nvl(g_loader_request_id,-1);
  BEGIN

			Dka_Tools_Pkg.put_log_message('Debut de la transco');
    FOR c_f IN cur_revenus LOOP

      -- Transco de la clé comptable
				DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '014_PROJETS',
                                      pv_column_01    => c_f.code_projet,
												pv_out_01       => v_code_projet_NEW,
												pv_out_02       => v_tache_NEW);

        		Dka_Tools_Pkg.put_log_message(c_f.code_projet ||':'|| v_code_projet_NEW);
      -- Mise Ã  jour des segments transcodés dans la table temporaire
				-- NBO 20/10/16 - Gestion des rowids pour éviter les problémes de curseur
				UPDATE DKA_REPPAREVENUIMP_TMP
				SET  code_projet_NEW = v_code_projet_NEW
					,tache	 		 = v_tache_NEW
				WHERE rowid = c_f.rid;
    END LOOP;
    COMMIT;

			Dka_Tools_Pkg.put_log_message('Fin de la transco code Projet.');
	END Transco_CodeProjet;

	/*
    *************************************************************************
    * PROCEDURE NAME : Transco_Unite_Operationnelle
    *
    * DESCRIPTION
    *  Procédure effectuant la transco et le chargement de la nouvelle entité opérationnelle 
	*  dans la table temporaire pour les donnï¿¿es issues de la région GFK
    *
    * PARAMETERS
    * ==========
    * NAME               DESCRIPTION
    * -----------------  ------------------------------------------------------
    *
    *
    ************************************************************************
    */
	PROCEDURE Transco_Unite_Operationnelle(pv_region VARCHAR2) IS

		v_region_new VARCHAR2(25);

		CURSOR cur_revenus
        IS
		-- NBO 20/10/16 - Gestion des rowids pour éviter les problémes de curseur
		SELECT tmp.*, tmp.rowid rid FROM DKA_REPPAREVENUIMP_TMP tmp
		WHERE load_request_id = nvl(g_loader_request_id,-1)
		AND	REGION = pv_region;
	BEGIN
		Dka_Tools_Pkg.put_log_message('Debut de la transco Transco_Unite_Operationnelle.');
      DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '008_REGIONS',
										pv_column_01    => pv_region,
                pv_out_01       => v_region_new
                );
		FOR c_f IN cur_revenus LOOP
			-- Mise ï¿¿ jour des segments transcodï¿¿s dans la table temporaire
  		    -- NBO 20/10/16 - Gestion des rowids pour éviter les problémes de curseur
			UPDATE DKA_REPPAREVENUIMP_TMP
			SET  region_new 	= v_region_new
				,unite_ope_new	= v_region_new || c_f.societe
			WHERE rowid = c_f.rid;
		END LOOP;

    COMMIT;
		Dka_Tools_Pkg.put_log_message('Fin de la transco Transco_Unite_Operationnelle.');
	END Transco_Unite_Operationnelle;

	/*
    *************************************************************************
    /* PROCEDURE NAME :   insert_event_spec
    /*
    /* DESCRIPTION  "Dï¿¿rivï¿¿" de la fonction standard pa_billing_pub.insert_event 
    /* pour pouvoir insï¿¿rer des ï¿¿venements qui ont un type diffï¿¿rent d'un type "automatique" 
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
    /*
    *************************************************************************
	*/
    PROCEDURE insert_event_spec (X_rev_amt			REAL DEFAULT NULL,
						X_bill_amt			REAL DEFAULT NULL,
						X_project_id			NUMBER DEFAULT NULL,
						X_event_type			VARCHAR2 DEFAULT NULL,
						X_top_task_id			NUMBER DEFAULT NULL,
						X_organization_id		NUMBER DEFAULT NULL,
						X_completion_date		DATE DEFAULT NULL,
                       	X_event_description		VARCHAR2 DEFAULT NULL,
                        X_event_num_reversed            NUMBER DEFAULT NULL,
						X_attribute_category		VARCHAR2 DEFAULT NULL,
                        X_attribute1			VARCHAR2 DEFAULT NULL,
                        X_attribute2			VARCHAR2 DEFAULT NULL,
                        X_attribute3			VARCHAR2 DEFAULT NULL,
                        X_attribute4			VARCHAR2 DEFAULT NULL,
                        X_attribute5			VARCHAR2 DEFAULT NULL,
                        X_attribute6			VARCHAR2 DEFAULT NULL,
                        X_attribute7			VARCHAR2 DEFAULT NULL,
                        X_attribute8			VARCHAR2 DEFAULT NULL,
                        X_attribute9			VARCHAR2 DEFAULT NULL,
                        X_attribute10			VARCHAR2 DEFAULT NULL,
                        X_audit_amount1	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount2	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount3	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount4	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount5	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount6	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount7	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount8	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount9	 IN      NUMBER DEFAULT NULL,
                        X_audit_amount10 IN      NUMBER DEFAULT NULL,
						X_audit_cost_budget_type_code IN      VARCHAR2 DEFAULT NULL,
						X_audit_rev_budget_type_code  IN      VARCHAR2 DEFAULT NULL,
                        x_inventory_org_id      IN      NUMBER   DEFAULT NULL,
                        x_inventory_item_id     IN      NUMBER   DEFAULT NULL,
                        x_quantity_billed       IN      NUMBER   DEFAULT NULL,
                        x_uom_code              IN      VARCHAR2 DEFAULT NULL,
                        x_unit_price            IN      NUMBER   DEFAULT NULL,
                        x_reference1            IN      VARCHAR2 DEFAULT NULL,
                        x_reference2            IN      VARCHAR2 DEFAULT NULL,
                        x_reference3            IN      VARCHAR2 DEFAULT NULL,
                        x_reference4            IN      VARCHAR2 DEFAULT NULL,
                        x_reference5            IN      VARCHAR2 DEFAULT NULL,
                        x_reference6            IN      VARCHAR2 DEFAULT NULL,
                        x_reference7            IN      VARCHAR2 DEFAULT NULL,
                        x_reference8            IN      VARCHAR2 DEFAULT NULL,
                        x_reference9            IN      VARCHAR2 DEFAULT NULL,
                        x_reference10           IN      VARCHAR2 DEFAULT NULL,
                        X_txn_currency_code                IN      VARCHAR2 DEFAULT NULL, /* Added  20 columns for MCB2 */
                        X_project_rate_type                IN      VARCHAR2 DEFAULT NULL,
                        X_project_rate_date                IN      DATE     DEFAULT NULL,
                        X_project_exchange_rate            IN      NUMBER   DEFAULT NULL,
                        X_project_func_rate_type           IN      VARCHAR2 DEFAULT NULL,
                        X_project_func_rate_date           IN      DATE     DEFAULT NULL,
                        X_project_func_exchange_rate       IN      NUMBER   DEFAULT NULL,
                        X_funding_rate_type                IN      VARCHAR2 DEFAULT NULL,
                        X_funding_rate_date                IN      DATE     DEFAULT NULL,
                        X_funding_exchange_rate            IN      NUMBER   DEFAULT NULL,
                        X_zero_revenue_amount_flag         IN      VARCHAR2 DEFAULT NULL,  /* Funding MRC Changes */
                        X_audit_cost_plan_type_id          IN      NUMBER   DEFAULT NULL, /* Added for Fin plan impact */
                        X_audit_rev_plan_type_id           IN      NUMBER   DEFAULT NULL, /* Added for Fin plan impact */
            			x_bill_group                       IN      varchar2 DEFAULT NULL,/*Bug 17848201 KBR*/
                        X_agreement_id                     IN      NUMBER   DEFAULT NULL,
						X_error_message         OUT NOCOPY     VARCHAR2,
						X_status                OUT NOCOPY     NUMBER
			) IS

	XD_bill_trans_bill_amt		NUMBER(22,5); /* changed for MCB2 from rev/bill amount to trans bill/rev amount */
	XD_bill_trans_rev_amt		NUMBER(22,5);
	XD_organization_id	NUMBER(15);
	XD_completion_date	DATE;
    XD_event_description	VARCHAR2(240);
    XD_event_type		VARCHAR2(30);
	event_num		NUMBER(16);/*Increase size for bug 1742348*/
	invalid_id		EXCEPTION;
	event_type_error 	EXCEPTION;
	null_event_type_error 	EXCEPTION;
	invalid_project_event 	EXCEPTION;
	mandatory_prm_missing	EXCEPTION;
	zero_amounts		EXCEPTION;
    no_orig_event           EXCEPTION;
    invalid_calling_place   EXCEPTION;
    invalid_invent_id       EXCEPTION;
	l_status		NUMBER;
	err_status		NUMBER;
	err_message		VARCHAR2(240);

	/* MCB related changes as of 08/21/2001 by skannoji */
	l_project_id                      pa_projects_all.project_id%TYPE;
	l_multi_currency_billing_flag     pa_projects_all.multi_currency_billing_flag%TYPE;
	l_baseline_funding_flag           pa_projects_all.baseline_funding_flag%TYPE;
	l_revproc_currency_code           pa_projects_all.revproc_currency_code%TYPE;
	l_revproc_rate_type               pa_events.revproc_rate_type%TYPE;
	l_revproc_rate_date               pa_events.revproc_rate_date%TYPE;
	l_revproc_exchange_rate           pa_events.revproc_exchange_rate%TYPE;
	l_invproc_currency_code           pa_events.invproc_currency_code%TYPE;
	l_invproc_currency_type           pa_projects_all.invproc_currency_type%TYPE;
	l_invproc_rate_type               pa_events.invproc_rate_type%TYPE;
	l_invproc_rate_date               pa_events.invproc_rate_date%TYPE;
	l_invproc_exchange_rate           pa_events.invproc_exchange_rate%TYPE;
	l_project_currency_code           pa_projects_all.project_currency_code%TYPE;
	l_project_bil_rate_date_code      pa_projects_all.project_bil_rate_date_code%TYPE;
	l_project_bil_rate_type           pa_projects_all.project_bil_rate_type%TYPE;
	l_project_bil_rate_date           pa_projects_all.project_bil_rate_date%TYPE;
	l_project_bil_exchange_rate       pa_projects_all.project_bil_exchange_rate%TYPE;
	l_projfunc_currency_code          pa_projects_all.projfunc_currency_code%TYPE;
	l_projfunc_bil_rate_date_code     pa_projects_all.projfunc_bil_rate_date_code%TYPE;
	l_projfunc_bil_rate_type          pa_projects_all.projfunc_bil_rate_type%TYPE;
	l_projfunc_bil_rate_date          pa_projects_all.projfunc_bil_rate_date%TYPE;
	l_projfunc_bil_exchange_rate      pa_projects_all.projfunc_bil_exchange_rate%TYPE;
	l_funding_rate_date_code          pa_projects_all.funding_rate_date_code%TYPE;
	l_funding_rate_type               pa_projects_all.funding_rate_type%TYPE;
	l_funding_rate_date               pa_projects_all.funding_rate_date%TYPE;
	l_funding_exchange_rate           pa_projects_all.funding_exchange_rate%TYPE;
	l_txn_currency_code               pa_events.bill_trans_currency_code%TYPE;
	l_return_status                   VARCHAR2(30);
	l_msg_count                       NUMBER;
	l_msg_data                        VARCHAR2(30);
	l_defc_flag                       VARCHAR2(1); /*Added for Fedaral Contracting Enhancement*/
	l_agreement_id                    NUMBER(15);  /*Added for Fedaral Contracting Enhancement*/
	l_found                           VARCHAR2(30);

	l_proj_exch_rate_not_passd             EXCEPTION;
	l_func_exch_rate_not_passd             EXCEPTION;
	l_fund_exch_rate_not_passd             EXCEPTION;
	l_proj_invalid_rate_type               EXCEPTION;
	l_func_invalid_rate_type               EXCEPTION;
	l_fund_invalid_rate_type               EXCEPTION;
	l_invalid_currency                     EXCEPTION;

	status					VARCHAR2(240);     -- For error messages from subprogs
	last_updated_by			NUMBER(15);	   --|
	created_by   			NUMBER(15);        --|
	last_update_login		NUMBER(15);        --|Standard Who Columns     --|
	program_application_id	NUMBER(15);        --|
	program_id				NUMBER(15);        --
	BEGIN
	BEGIN

	-- Assigning who columns for insertion into PA_EVENTS.

	created_by      		:= FND_GLOBAL.USER_ID;
	last_updated_by 		:= FND_GLOBAL.USER_ID;
	last_update_login		:= FND_GLOBAL.LOGIN_ID;
	program_application_id	:= FND_GLOBAL.PROG_APPL_ID;
	program_id			    := FND_GLOBAL.CONC_PROGRAM_ID;

	X_status := 0;
	X_error_message := NULL;
   -- Validate Mandatory Parameters
	IF (pa_billing.GlobVars.BillingAssignmentId IS NULL OR
	   pa_billing.GlobVars.ReqId IS NULL OR
	   pa_billing.GlobVars.CallingPlace IS NULL OR
	   pa_billing.GlobVars.CallingProcess IS NULL) THEN
	raise mandatory_prm_missing;
	END IF;

    /* The following logic has been added for MCB2 functionality */
         l_project_id := nvl(X_project_id, pa_billing.GlobVars.ProjectId);
      PA_MULTI_CURRENCY_BILLING.get_project_defaults (
            p_project_id                  =>  l_project_id,
            x_multi_currency_billing_flag =>  l_multi_currency_billing_flag,
            x_baseline_funding_flag       =>  l_baseline_funding_flag,
            x_revproc_currency_code       =>  l_revproc_currency_code,
            x_invproc_currency_type       =>  l_invproc_currency_type,
            x_invproc_currency_code       =>  l_invproc_currency_code,
            x_project_currency_code       =>  l_project_currency_code,
            x_project_bil_rate_date_code  =>  l_project_bil_rate_date_code,
            x_project_bil_rate_type       =>  l_project_bil_rate_type,
            x_project_bil_rate_date       =>  l_project_bil_rate_date,
            x_project_bil_exchange_rate   =>  l_project_bil_exchange_rate,
            x_projfunc_currency_code      =>  l_projfunc_currency_code,
            x_projfunc_bil_rate_date_code =>  l_projfunc_bil_rate_date_code,
            x_projfunc_bil_rate_type      =>  l_projfunc_bil_rate_type,
            x_projfunc_bil_rate_date      =>  l_projfunc_bil_rate_date,
            x_projfunc_bil_exchange_rate  =>  l_projfunc_bil_exchange_rate,
            x_funding_rate_date_code      =>  l_funding_rate_date_code,
            x_funding_rate_type           =>  l_funding_rate_type,
            x_funding_rate_date           =>  l_funding_rate_date,
            x_funding_exchange_rate       =>  l_funding_exchange_rate,
            x_return_status               =>  l_return_status,
            x_msg_count                   =>  l_msg_count,
            x_msg_data                    =>  l_msg_data);

            l_txn_currency_code := NVL(x_txn_currency_code,l_projfunc_currency_code);
            BEGIN
               /* Validating Currency code */
               SELECT 'Y'
               INTO l_found
               FROM fnd_currencies /* Bug 4352166 Changed vl to base table*/
               WHERE currency_code = l_txn_currency_code
               AND TRUNC(SYSDATE) BETWEEN DECODE (TRUNC(start_date_active), NULL, TRUNC(SYSDATE),
                                           TRUNC(start_date_active))
                       AND DECODE(TRUNC(end_date_active), NULL, TRUNC(SYSDATE),TRUNC(end_date_active));
            EXCEPTION
              WHEN OTHERS THEN
               RAISE l_invalid_currency;
            END;

	/* Rounding the transaction amount upto the precision of transaction currency for MCB2 */
		XD_bill_trans_rev_amt	:= PA_MULTI_CURRENCY_BILLING.ROUND_TRANS_CURRENCY_AMT(NVL(X_rev_amt, 0),l_txn_currency_code);

		XD_bill_trans_bill_amt 	:= PA_MULTI_CURRENCY_BILLING.ROUND_TRANS_CURRENCY_AMT(NVL(X_bill_amt,0),l_txn_currency_code);

	  /* The following amounts have been commented for MCB2, the above amounts are satisfying the same requirement */
	/* 	XD_bill_trans_rev_amt	:= (NVL(X_rev_amt, 0));
		XD_bill_trans_bill_amt 	:= (NVL(X_bill_amt,0)); */

	-- Get defaults for other non-mandatory parameters
	XD_completion_date 	:= nvl(X_completion_date,
					to_date(pa_billing.GlobVars.AccrueThruDate,'YYYY/MM/DD'));


	-- Added check to prevent event creation from other calling places like 'PRE' 'POST'
	-- 'DEL' etc.
	--
	IF (pa_billing.GlobVars.CallingPlace NOT IN ('REG','ADJ','POST-REG')) THEN
	raise invalid_calling_place;
	END IF;


	IF (X_organization_id IS NULL) THEN
	     XD_organization_id := pa_billing_values.get_dflt_org(
					nvl(X_project_id,
						pa_billing.GlobVars.ProjectId),
					nvl(X_top_task_id,
						pa_billing.GlobVars.TaskId));
	ELSE
           XD_organization_id := X_organization_id;
	END IF;

	IF (X_event_description 	IS NULL OR
	    X_event_type 		IS NULL) 	THEN
	     pa_billing_values.get_dflt_desc(pa_billing.GlobVars.BillingAssignmentId,
				XD_event_type, XD_event_description);
	     XD_event_description := nvl(X_event_description,
					XD_event_description);
	     XD_event_type 	  := nvl(X_event_type, XD_event_type);

	     IF (XD_event_type IS NULL) THEN
			RAISE null_event_type_error;
	     END IF;
	ELSE
	     XD_event_description 	:= X_event_description;
	     XD_event_type 		:= X_event_type;
	END IF;


   -- Validate Id's

	IF (pa_billing_validate.valid_proj_task_extn(
			nvl(X_project_id,  pa_billing.GlobVars.ProjectId),
			nvl(X_top_task_id, pa_billing.GlobVars.TaskId),
				pa_billing.GlobVars.BillingAssignmentId) AND
	    pa_billing_validate.valid_organization(XD_organization_id)) THEN
		NULL;
	ELSE
		RAISE INVALID_ID;
	END IF;



	-- Validate funding level

	IF (nvl(X_top_task_id, pa_billing.GlobVars.TaskId) IS NULL) THEN
	  IF (pa_billing_values.funding_level(nvl(X_project_id,
					pa_billing.GlobVars.ProjectId))
							<> 'PROJECT') THEN
	    RAISE invalid_project_event;
	  END IF;
	END IF;

	-- Funding MRC Changes added the flag X_zero_revenue_amount_flag
	-- If revenue amount is zero and X_zero_revenue_amount_flag = 'Y' is a valid case
	-- should not raise the exception. (Create zero dollar revenue event)

	-- Validate amounts based on which process is calling.
	IF ((((XD_bill_trans_rev_amt  = 0) AND (nvl(X_zero_revenue_amount_flag,'N') = 'N')) AND
        (XD_bill_trans_bill_amt = 0)) OR
       ((XD_bill_trans_rev_amt  = 0) AND  (nvl(X_zero_revenue_amount_flag,'N') = 'N')  AND
		pa_billing.GlobVars.CallingProcess = 'Revenue') OR
       ((XD_bill_trans_bill_amt = 0) AND
		pa_billing.GlobVars.CallingProcess = 'Invoice')) THEN
	RAISE zero_amounts;
	END IF;

	/* Modified the below condition for Bug 9154825 */
	-- Check original event num for the ADJ automatic events.
	IF (PA_BILLING.GetCallPlace = 'ADJ' AND
       (pa_billing.GlobVars.CallingProcess = 'Invoice' OR pa_billing.GlobVars.CallingProcess = 'Revenue') AND
        nvl(X_event_num_reversed, 0) = 0) THEN
        RAISE no_orig_event;
	END IF;

    event_num := pa_billing_seq.next_eventnum(
		nvl(X_project_id, pa_billing.GlobVars.ProjectId),
		nvl(X_top_task_id, pa_billing.GlobVars.TaskId));


	/* Adding validation of newly added columns in event table for project contract integration */
   -- Validating inventory_org_id and inventory_item_id

	IF (x_inventory_org_id IS NOT NULL) THEN
	   IF (pa_billing_validate.valid_organization(x_inventory_org_id)) THEN
              NULL;
	   ELSE
              RAISE INVALID_INVENT_ID;
	   END IF;
        END IF;

	IF (x_inventory_item_id IS NOT NULL) THEN
          DECLARE
             l_dummy      varchar2(30);
          BEGIN
             SELECT  'Valid item'
             INTO    l_dummy
             FROM    mtl_item_flexfields
             WHERE   inventory_item_id = x_inventory_item_id;

          EXCEPTION
             WHEN NO_DATA_FOUND THEN
               RAISE INVALID_INVENT_ID;
             WHEN TOO_MANY_ROWS THEN
               null;
          END;
        END IF;

       /* MCB2: The following code have benn added to populate the conversion attributes  */

            IF ( l_txn_currency_code <> l_projfunc_currency_code ) THEN
              l_found := NULL;
             IF ( X_project_func_rate_type IS NOT NULL) THEN
              BEGIN
                  SELECT 'found'
                  INTO l_found
                  FROM ( SELECT conversion_type, user_conversion_type
                         FROM   pa_conversion_types_v
                         WHERE  conversion_type <>'User'
                         AND    (pa_multi_currency.is_user_rate_type_allowed(
                                 l_txn_currency_code,
                                 l_projfunc_currency_code,
                         DECODE(l_projfunc_bil_rate_date_code,
                            'PA_INVOICE_DATE', NVL(X_project_func_rate_date,l_projfunc_bil_rate_date),
                            'FIXED_DATE', NVL(X_project_func_rate_date,l_projfunc_bil_rate_date)))= 'N')
                         UNION
                         SELECT conversion_type, user_conversion_type
                         FROM   pa_conversion_types_v
                         WHERE  pa_multi_currency.is_user_rate_type_allowed(
                                l_txn_currency_code,
                                l_projfunc_currency_code,
                                DECODE(l_projfunc_bil_rate_date_code,
                                   'PA_INVOICE_DATE',NVL(X_project_func_rate_date,l_projfunc_bil_rate_date),
                                   'FIXED_DATE',NVL(X_project_func_rate_date,l_projfunc_bil_rate_date) ))= 'Y')
                  WHERE DECODE(conversion_type,X_project_func_rate_type,'Y','N') = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     RAISE l_func_invalid_rate_type;
               END;
              END IF;

              IF ( X_project_func_rate_type IS NULL AND l_projfunc_bil_rate_type = 'User') THEN
                   l_projfunc_bil_rate_date := NULL;
                   IF ( X_project_func_exchange_rate IS NULL ) THEN
                      null;
                   ELSE
                      l_projfunc_bil_exchange_rate := X_project_func_exchange_rate;
                   END IF;
              ELSIF (X_project_func_rate_type = 'User') THEN
                   l_projfunc_bil_rate_date := NULL;
                   l_projfunc_bil_rate_type := X_project_func_rate_type;
                   IF ( X_project_func_exchange_rate IS NULL ) THEN
                     RAISE l_func_exch_rate_not_passd;
                   ELSE
                      l_projfunc_bil_exchange_rate := X_project_func_exchange_rate;
                   END IF;
              ELSIF ( X_project_func_rate_type <> 'User' OR l_projfunc_bil_rate_type <> 'User') THEN
                   l_projfunc_bil_rate_type := NVL(X_project_func_rate_type,l_projfunc_bil_rate_type);
                   l_projfunc_bil_exchange_rate := NULL;
              END IF;


              IF ( l_projfunc_bil_rate_type <> 'User' AND l_projfunc_bil_rate_date_code = 'FIXED_DATE'
                   AND X_project_func_rate_date IS NOT NULL ) THEN
                   l_projfunc_bil_rate_date := X_project_func_rate_date;
              ELSIF (l_projfunc_bil_rate_type <> 'User' AND l_projfunc_bil_rate_date_code = 'PA_INVOICE_DATE'
                    AND X_project_func_rate_date IS NOT NULL ) THEN
                    l_projfunc_bil_rate_date := X_project_func_rate_date;
              END IF;
            END IF;

            /* Project currency code logic */
            IF ( l_txn_currency_code <> l_project_currency_code ) THEN
              l_found := NULL;
             IF ( X_project_rate_type IS NOT NULL) THEN
               BEGIN
                  SELECT 'found'
                  INTO l_found
                  FROM ( SELECT conversion_type, user_conversion_type
                         FROM   pa_conversion_types_v
                         WHERE  conversion_type <>'User'
                         AND    (pa_multi_currency.is_user_rate_type_allowed(
                                 l_txn_currency_code,
                                 l_project_currency_code,
                         DECODE(l_project_bil_rate_date_code,
                            'PA_INVOICE_DATE', NVL(X_project_rate_date,l_project_bil_rate_date),
                            'FIXED_DATE', NVL(X_project_rate_date,l_project_bil_rate_date)))= 'N')
                         UNION
                         SELECT conversion_type, user_conversion_type
                         FROM   pa_conversion_types_v
                         WHERE  pa_multi_currency.is_user_rate_type_allowed(
                                l_txn_currency_code,
                                l_project_currency_code,
                                DECODE(l_project_bil_rate_date_code,
                                   'PA_INVOICE_DATE',NVL(X_project_rate_date,l_project_bil_rate_date),
                                   'FIXED_DATE',NVL(X_project_rate_date,l_project_bil_rate_date) ))= 'Y')
                  WHERE DECODE(conversion_type,X_project_rate_type,'Y','N') = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                   RAISE  l_proj_invalid_rate_type;
               END;
              END IF;

              IF ( X_project_rate_type IS NULL AND l_project_bil_rate_type = 'User') THEN
                   l_project_bil_rate_date := NULL;
                   IF ( X_project_exchange_rate IS NULL ) THEN
                      null;
                   ELSE
                      l_project_bil_exchange_rate := X_project_exchange_rate;
                   END IF;
              ELSIF (X_project_rate_type = 'User') THEN
                   l_project_bil_rate_date := NULL;
                   l_project_bil_rate_type := X_project_rate_type;
                   IF ( X_project_exchange_rate IS NULL ) THEN
                     RAISE l_proj_exch_rate_not_passd;
                   ELSE
                      l_project_bil_exchange_rate := X_project_exchange_rate;
                   END IF;
              ELSIF ( X_project_rate_type <> 'User' OR l_project_bil_rate_type <> 'User') THEN
                   l_project_bil_rate_type := NVL(X_project_rate_type,l_project_bil_rate_type);
                   l_project_bil_exchange_rate := NULL;
              END IF;
              IF ( l_project_bil_rate_type <> 'User' AND l_project_bil_rate_date_code = 'FIXED_DATE'
                   AND X_project_rate_date IS NOT NULL ) THEN
                   l_project_bil_rate_date := X_project_rate_date;
              ELSIF (l_project_bil_rate_type <> 'User' AND l_project_bil_rate_date_code = 'PA_INVOICE_DATE'
                    AND X_project_rate_date IS NOT NULL ) THEN
                    l_project_bil_rate_date := X_project_rate_date;
              END IF;
            END IF;

            /* Funding Currency code logic */
            IF ( l_multi_currency_billing_flag = 'Y' OR l_multi_currency_billing_flag = 'y') THEN
              l_found := NULL;
             IF ( X_funding_rate_type IS NOT NULL) THEN
              BEGIN
                  SELECT 'found'
                  INTO l_found
                  FROM ( SELECT conversion_type, user_conversion_type
                         FROM   pa_conversion_types_v)
                  WHERE DECODE(conversion_type,X_funding_rate_type,'Y','N') = 'Y';
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                   RAISE  l_fund_invalid_rate_type;
               END;
              END IF;

              IF ( X_funding_rate_type IS NULL AND l_funding_rate_type = 'User') THEN
                   l_funding_rate_date := NULL;
                   IF ( X_funding_exchange_rate IS NULL ) THEN
                      null;
                   ELSE
                      l_funding_exchange_rate := X_funding_exchange_rate;
                   END IF;
              ELSIF (X_funding_rate_type = 'User') THEN
                   l_funding_rate_date := NULL;
                   l_funding_rate_type := X_funding_rate_type;
                   IF ( X_funding_exchange_rate IS NULL ) THEN
                     RAISE l_fund_exch_rate_not_passd;
                   ELSE
                      l_funding_exchange_rate := X_funding_exchange_rate;
                   END IF;
              ELSIF ( X_funding_rate_type <> 'User' OR l_funding_rate_type <> 'User') THEN
                   l_funding_rate_type := NVL(X_funding_rate_type,l_funding_rate_type);
                   l_funding_exchange_rate := NULL;
              END IF;
              IF ( l_funding_rate_type <> 'User' AND l_funding_rate_date_code = 'FIXED_DATE'
                   AND X_funding_rate_date IS NOT NULL ) THEN
                   l_funding_rate_date := X_funding_rate_date;
              ELSIF (l_funding_rate_type <> 'User' AND l_funding_rate_date_code = 'PA_INVOICE_DATE'
                    AND X_funding_rate_date IS NOT NULL ) THEN
                    l_funding_rate_date := X_funding_rate_date;
              END IF;
            END IF;

          /* Added for Bug3068864 */
            IF ( l_txn_currency_code = l_projfunc_currency_code ) THEN
               l_projfunc_bil_rate_type := Null;
               l_projfunc_bil_rate_date := Null;
               l_projfunc_bil_exchange_rate := Null;
            ELSIF (l_txn_currency_code = l_project_currency_code ) THEN
                  l_project_bil_rate_type := Null;
                  l_project_bil_rate_date := Null;
                  l_project_bil_exchange_rate := Null;
            END IF;
          /* till here for Bug3068864 */

              /* Populating Invoice attributes */

            IF ( l_invproc_currency_code = l_projfunc_currency_code ) THEN
               l_invproc_currency_code := l_projfunc_currency_code;
               l_invproc_rate_type     := l_projfunc_bil_rate_type;
               l_invproc_rate_date     := l_projfunc_bil_rate_date;
               l_invproc_exchange_rate := l_projfunc_bil_exchange_rate;
            ELSIF (l_invproc_currency_code = l_project_currency_code ) THEN
                  l_invproc_currency_code := l_project_currency_code;
                  l_invproc_rate_type     := l_project_bil_rate_type;
                  l_invproc_rate_date     := l_project_bil_rate_date;
                  l_invproc_exchange_rate := l_project_bil_exchange_rate;
            ELSE
                  l_invproc_currency_code := '';
                  l_invproc_rate_type     := l_funding_rate_type;
                  l_invproc_rate_date     := l_funding_rate_date;
                  l_invproc_exchange_rate := l_funding_exchange_rate;
            END IF;

              /* Populating Revenue attributes */

            IF ( l_revproc_currency_code = l_projfunc_currency_code ) THEN
               l_revproc_currency_code := l_projfunc_currency_code;
               l_revproc_rate_type     := l_projfunc_bil_rate_type;
               l_revproc_rate_date     := l_projfunc_bil_rate_date;
               l_revproc_exchange_rate := l_projfunc_bil_exchange_rate;
            END IF;

            /*Added for Federal Contracting Enhancement*/

	 /*Added end for Federal Contracting Enhancement*/
     /* MCB2: Removed Revenue amount and Bill amount because,these amounts are being used only for transactions */
     insert into pa_events
     (PROJECT_ID, TASK_ID, ORGANIZATION_ID, EVENT_NUM, EVENT_TYPE,       -- 1
     REVENUE_AMOUNT,BILL_AMOUNT,COMPLETION_DATE, REQUEST_ID,             -- 2
     DESCRIPTION, BILL_HOLD_FLAG, REV_DIST_REJECTION_CODE,               -- 3
     REVENUE_DISTRIBUTED_FLAG, PROGRAM_APPLICATION_ID, PROGRAM_ID,       -- 4
     PROGRAM_UPDATE_DATE, LAST_UPDATE_DATE, LAST_UPDATED_BY,             -- 5
     CREATION_DATE, CREATED_BY, LAST_UPDATE_LOGIN, ATTRIBUTE_CATEGORY,   -- 6
     ATTRIBUTE1, ATTRIBUTE2, ATTRIBUTE3, ATTRIBUTE4, ATTRIBUTE5,         -- 7
     ATTRIBUTE6, ATTRIBUTE7, ATTRIBUTE8, ATTRIBUTE9, ATTRIBUTE10,        -- 8
     BILLING_ASSIGNMENT_ID, calling_place, calling_process,              -- 9
     EVENT_NUM_REVERSED,                                                 -- 10
     AUDIT_AMOUNT1,
     AUDIT_AMOUNT2,
     AUDIT_AMOUNT3,
     AUDIT_AMOUNT4,
     AUDIT_AMOUNT5,
     AUDIT_AMOUNT6,
     AUDIT_AMOUNT7,
     AUDIT_AMOUNT8,
     AUDIT_AMOUNT9,
     AUDIT_AMOUNT10,
     AUDIT_COST_BUDGET_TYPE_CODE,
     AUDIT_REV_BUDGET_TYPE_CODE,
     EVENT_ID,
     INVENTORY_ORG_ID,
     INVENTORY_ITEM_ID,
     QUANTITY_BILLED,
     UOM_CODE,
     UNIT_PRICE,
     REFERENCE1,
     REFERENCE2,
     REFERENCE3,
     REFERENCE4,
     REFERENCE5,
     REFERENCE6,
     REFERENCE7,
     REFERENCE8,
     REFERENCE9,
     REFERENCE10,
     BILL_TRANS_CURRENCY_CODE, /* These 22 columns have been added for MCB2 */
     BILL_TRANS_REV_AMOUNT,
     BILL_TRANS_BILL_AMOUNT,
     PROJECT_CURRENCY_CODE,
     PROJECT_RATE_TYPE,
     PROJECT_RATE_DATE,
     PROJECT_EXCHANGE_RATE,
     PROJFUNC_CURRENCY_CODE,
     PROJFUNC_RATE_TYPE,
     PROJFUNC_RATE_DATE,
     PROJFUNC_EXCHANGE_RATE,
     FUNDING_RATE_TYPE,
     FUNDING_RATE_DATE,
     FUNDING_EXCHANGE_RATE,
     INVPROC_CURRENCY_CODE,
     INVPROC_RATE_TYPE,
     INVPROC_RATE_DATE,
     INVPROC_EXCHANGE_RATE,
     REVPROC_CURRENCY_CODE,
     REVPROC_RATE_TYPE,
     REVPROC_RATE_DATE,
     REVPROC_EXCHANGE_RATE,
     ZERO_REVENUE_AMOUNT_FLAG,              /* Funding MRC Changes */
     AUDIT_COST_PLAN_TYPE_ID,               /* Added for Fin Plan impact */
     AUDIT_REV_PLAN_TYPE_ID ,                /* Added for Fin Plan impact */
	 bill_group,   /*Bug 17848201 KBR*/
     agreement_id )
     values
     (nvl(X_project_id, pa_billing.GlobVars.ProjectId), nvl(X_top_task_id,pa_billing.GlobVars.TaskId),
	 XD_organization_id, event_num, XD_event_type,   		 -- 1
     0,0,XD_completion_date, pa_billing.GlobVars.ReqId,        -- 2
     XD_event_description, 'N', NULL,                                    -- 3
     'N', program_application_id,program_id,                             -- 4
     sysdate, sysdate, nvl(last_updated_by,0),                           -- 5
     sysdate, nvl(created_by,0), nvl(last_update_login,0),
					X_attribute_category,            -- 6
     X_attribute1, X_attribute2, X_attribute3, X_attribute4,
						X_attribute5,            -- 7
     X_attribute6, X_attribute7, X_attribute8, X_attribute9,
						X_attribute10,           -- 8
     pa_billing.GlobVars.BillingAssignmentId, pa_billing.GlobVars.CallingPlace,
				pa_billing.GlobVars.CallingProcess,   	 -- 9
     X_event_num_reversed,                                               -- 10
     pa_currency.round_currency_amt(X_audit_amount1),
     pa_currency.round_currency_amt(X_audit_amount2),
     pa_currency.round_currency_amt(X_audit_amount3),
     pa_currency.round_currency_amt(X_audit_amount4),
     pa_currency.round_currency_amt(X_audit_amount5),
     pa_currency.round_currency_amt(X_audit_amount6),
     pa_currency.round_currency_amt(X_audit_amount7),
     pa_currency.round_currency_amt(X_audit_amount8),
     pa_currency.round_currency_amt(X_audit_amount9),
     pa_currency.round_currency_amt(X_audit_amount10),
     X_audit_cost_budget_type_code,
     X_audit_rev_budget_type_code,
     pa_events_s.nextval,
     x_inventory_org_id,
     x_inventory_item_id,
     x_quantity_billed,
     x_uom_code,
     x_unit_price,
     x_reference1,
     x_reference2,
     x_reference3,
     x_reference4,
     x_reference5,
     x_reference6,
     x_reference7,
     x_reference8,
     x_reference9,
     x_reference10,
     l_txn_currency_code,
     XD_bill_trans_rev_amt,
     XD_bill_trans_bill_amt,
     l_project_currency_code,
     l_project_bil_rate_type,
     l_project_bil_rate_date,
     l_project_bil_exchange_rate,
     l_projfunc_currency_code,
     l_projfunc_bil_rate_type,
     l_projfunc_bil_rate_date,
     l_projfunc_bil_exchange_rate,
     l_funding_rate_type,
     l_funding_rate_date,
     l_funding_exchange_rate,
     l_invproc_currency_code,
     l_invproc_rate_type,
     l_invproc_rate_date,
     l_invproc_exchange_rate,
     l_revproc_currency_code,
     l_revproc_rate_type,
     l_revproc_rate_date,
     l_revproc_exchange_rate,
     NVL(X_zero_revenue_amount_flag, 'N'),
     X_audit_cost_plan_type_id,
     X_audit_rev_plan_type_id,
	 x_bill_group ,
     X_agreement_id/*Added for Federal Contracting Enhancement*/
     );
	--   COMMIT;

	EXCEPTION
     WHEN mandatory_prm_missing THEN
       status := pa_billing_values.get_message('MANDATORY_PRM_MISSING');
       l_status := 1;
	RAISE;
     WHEN invalid_id THEN
       status := pa_billing_values.get_message('INVALID_ID');
       l_status := 2;
	RAISE;
     WHEN invalid_project_event THEN
       status := pa_billing_values.get_message('INVALID_PROJECT_EVENT');
       l_status := 3;
	RAISE;
     /*WHEN event_type_error THEN commenting this for bug 3492506
       status := pa_billing_values.get_message('EVENT_TYPE_ERROR');
	RAISE;*/
     WHEN null_event_type_error THEN
       status := pa_billing_values.get_message('NULL_EVENT_TYPE_ERROR');
       l_status := 4;
	RAISE;
     WHEN zero_amounts THEN
	status := pa_billing_values.get_message('ZERO_AMOUNTS');
       l_status := 5;
	RAISE;
     WHEN no_orig_event THEN
        status := pa_billing_values.get_message('NO_ORIG_EVENT');
       l_status := 6;
        RAISE;
     WHEN invalid_calling_place THEN
        status := pa_billing_values.get_message('INVALID_CALLING_PLACE');
       l_status := 7;
        RAISE;
     WHEN invalid_invent_id THEN
        status := pa_billing_values.get_message('INVALID_INVENT_ID');
       l_status := 8;
        RAISE;
     WHEN l_func_exch_rate_not_passd THEN /* Added for MCB2 */
        status := pa_billing_values.get_message('PA_FUNC_EXCH_RATE_NOT_PASSD');
        l_status := 9;
        RAISE;
     WHEN l_proj_exch_rate_not_passd THEN /* Added for MCB2  */
        status := pa_billing_values.get_message('PA_PROJ_EXCH_RATE_NOT_PASSD');
        l_status := 10;
        RAISE;
     WHEN l_fund_exch_rate_not_passd THEN /* Added for MCB2  */
        status := pa_billing_values.get_message('PA_FUND_EXCH_RATE_NOT_PASSD');
        l_status := 11;
        RAISE;
     WHEN l_func_invalid_rate_type THEN /* Added for MCB2  */
        status := pa_billing_values.get_message('PA_FUNC_INVALID_RATE_TYPE');
        l_status := 12;
        RAISE;
     WHEN l_proj_invalid_rate_type THEN /* Added for MCB2  */
        status := pa_billing_values.get_message('PA_PROJ_INVALID_RATE_TYPE');
        l_status := 13;
        RAISE;
     WHEN l_fund_invalid_rate_type THEN /* Added for MCB2  */
        status := pa_billing_values.get_message('PA_FUND_INVALID_RATE_TYPE');
        l_status := 14;
        RAISE;
     WHEN l_invalid_currency THEN /* Added for MCB2  */
        status := pa_billing_values.get_message('PA_CURR_NOT_VALID_BC');
        l_status := 15;
        RAISE;
     WHEN event_type_error THEN /* adding this here for bug 3492506 */
        status := pa_billing_values.get_message('EVENT_TYPE_ERROR');
        l_status := 16;
        RAISE;
     WHEN OTHERS THEN
	   Dka_Tools_Pkg.put_log_message('Insert_event_spec : exception OTHERS ' || SQLERRM);

       status := substr(SQLERRM,1,240);
       l_status := sqlcode;
	--       ROLLBACK;
		RAISE;
	END;
    EXCEPTION
	WHEN OTHERS THEN
	--	DBMS_OUTPUT.PUT_LINE(status);
	--	DBMS_OUTPUT.PUT_LINE(SQLERRM);
	X_error_message := status;
	X_status 	:= l_status;

	/*pa_billing_pub.insert_message(X_inserting_procedure_name => 'insert_event_spec',
			X_attribute1 => XD_bill_trans_rev_amt,
			X_attribute2 => XD_bill_trans_bill_amt,
			X_message => status,
			X_status => err_status,
			X_error_message => err_message);*/

	IF (l_status <0 ) THEN
		RAISE;
	END IF;
	--Dka_Tools_Pkg.put_log_message('fin de insert_event_spec ' || l_status);

	--	COMMIT;
	END insert_event_spec;

	/*
    *************************************************************************
    /* PROCEDURE NAME :   program_import_revenus
    /*
    /* DESCRIPTION  Traitement standard d'import des fournisseurs
    /*
    /*
    /* PARAMETERS
    /* ==========
    /* NAME               DESCRIPTION
    /* -----------------  ------------------------------------------------------
    /*
    /*
    /*
    *************************************************************************
	*/
	-- NBO 20/10/16 - Gestion des rowids pour éviter les problémes de curseur
    -- artf2014423 - Pb dans la gestion de la date
	PROCEDURE program_import_revenus( pv_errbuf  IN OUT VARCHAR2,
                                      pn_retcode IN OUT NUMBER,
                                      pv_period  IN VARCHAR2
									)
    IS

        v_phase         VARCHAR2 (100);
        v_status        VARCHAR2 (100);
        v_dev_phase     VARCHAR2 (100);
        v_dev_status    VARCHAR2 (100);
        v_message       VARCHAR2 (500);
        n_msg_count		NUMBER := 0;
        vn_ccid       NUMBER;
        vn_unbilled_ccid NUMBER;
        n_status		NUMBER := 0;
		v_old_code_proj VARCHAR2 (100);
		v_old_tache_proj VARCHAR2 (100);
    v_societe VARCHAR2(4);
    v_region VARCHAR2(3);
    d_end_period DATE;
    d_next_period DATE;
		n_code_proj_id	NUMBER := 0;
		n_org_id		NUMBER := 0;
    n_evt_org_id NUMBER := 0;
		n_tache_id		NUMBER := 0;
		c_return_status VARCHAR2(1);
		b_continue      BOOLEAN;
    vn_retcode_billccid NUMBER;
    vn_retcode_ccid NUMBER;
    -- NBO 09/11/16 - Gestion des retours pour éviter des tous ou rien 
    vn_retcode NUMBER;
    vv_errbuf_billccid VARCHAR2(4000);
    vv_errbuf_ccid VARCHAR2(4000);
    lv_errmsg VARCHAR2(1000);
    lv_evt_type VARCHAR2(50);
    lv_evt_context     VARCHAR2(50);
    -- NBO 02/03/17 - artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
    lv_project_type VARCHAR2(50);
    lv_attribute3 VARCHAR2(50);
    l_count NUMBER;

		CURSOR cur_revenus
	    -- NBO 20/10/16 - Gestion des rowids pour inviter les problémes de curseur
      --  IS SELECT tmp.*, tmp.rowid rid FROM DKA_REPPAREVENUIMP_TMP TMP;
			--ADE 24/07/2017 - artf2200431 Verification que l'evenement est dans les dates du projet
			IS SELECT tmp.*, tmp.rowid rid
         FROM DKA_REPPAREVENUIMP_TMP TMP;
          -- NBO 29/09/17 - artf2200431
 --            ,PA_PROJECTS_ALL PPA
        -- WHERE TMP.code_projet_new = PPA.segment1;

         -- Le contrôle doit être effectuée au bon endroit de sorte que les lignes enfreignant le controle finissent au statut INVALID
         --AND TMP.date_evenement BETWEEN nvl(ppa.start_date,sysdate) AND nvl(ppa.closed_date, sysdate);

    BEGIN

		Dka_Tools_Pkg.put_log_message('Debut program_import_revenus');

        v_old_code_proj  := ' ';
		v_old_tache_proj := ' ';

		pa_billing.GlobVars.ReqId 			:= '-1';
		pa_billing.GlobVars.CallingPlace  	:= 'REG';
		pa_billing.GlobVars.CallingProcess	:= 'RUN';


		dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
		dka_tools_pkg.put_outdebug_message('---------------------------------------------------REJETS LORS DE L''INSERTION DES LIGNES DE REVENUS----------------------------------------------------');
		dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
		dka_tools_pkg.put_outdebug_message(RPAD('CODE PROJET',20,' ')||RPAD('TYPE EVT',15,' ')||RPAD('MONTANT',20,' ')||RPAD('ERREUR',150,' '));
		dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
		dka_tools_pkg.put_outdebug_message(chr(10));

		FOR c_tmp IN cur_revenus LOOP
            -- NBO - 26/10/16 - Ajout des status
			IF c_tmp.status IN (gv_status_valid, gv_status_reject) THEN
				--INIT
				--init_environement(c_tmp.UNITE_OPE);
        vn_retcode := 0;

				b_continue := true;
                -- 	NBO 02/03/17 artf2108043 - DEFECT 579 - Certains événements sont repris avec un mauvais TASK_ID 
				--IF (nvl(v_old_code_proj,'-1') <> nvl(c_tmp.CODE_PROJET_NEW,'-1')) THEN
					BEGIN
			-- NBO 20/10/16 - artf2024248 - Plusieurs anomalies à corriger
						--SELECT PROJECT_ID, ORG_ID
						--INTO n_code_proj_id, n_org_id
            gv_step := 'SELECT PROJET';
		    -- NBO 02/03/17 - artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
            SELECT PROJECT_ID, ORG_ID, CARRYING_OUT_ORGANIZATION_ID, substr(hou.name, 1, 3) region, substr(hou.name,4) societe, project_type
            INTO n_code_proj_id, n_org_id, n_evt_org_id, v_region, v_societe, lv_project_type
						FROM PA_PROJECTS_ALL PPA, hr_all_organization_units hou
            WHERE PPA.org_id = hou.ORGANIZATION_ID
            AND SEGMENT1 = c_tmp.CODE_PROJET_NEW;

            dka_tools_pkg.put_debug_message('region/soc : ' || v_region ||':'|| v_societe);

                        -- 	NBO 02/03/17 artf2108043 - DEFECT 579 - Certains événements sont repris avec un mauvais TASK_ID 
						--v_old_code_proj := c_tmp.CODE_PROJET_NEW;
						pa_billing.GlobVars.ProjectId := n_code_proj_id;
					EXCEPTION
						WHEN NO_DATA_FOUND THEN
			  -- NBO - 26/10/16 - Ajout des status
              lv_errmsg := 'Pas de projet trouve pour cette ligne de revenu';
							UPDATE DKA_REPPAREVENUIMP_TMP
							SET    STATUS = gv_status_reject,
                     ERROR_MESSAGE = lv_errmsg
							WHERE rowid = c_tmp.rid;
							lv_errmsg := RPAD(c_tmp.CODE_PROJET,20,' ') || RPAD(c_tmp.TYPE_EVENEMENT,15,' ') || RPAD(c_tmp.MONTANT_REVENU,20,' ')||RPAD('Pas de projet trouvé pour cette ligne de revenu',150,' ');

                            -- NBO 09/11/16 - Gestion des retours pour éviter des tous ou rien 
							vn_retcode := 1;
							g_nb_event_rejete := g_nb_event_rejete + 1;
							dka_tools_pkg.put_debug_message(lv_errmsg);
              b_continue := false;
					END;
				--END IF;

        IF v_societe <> c_tmp.societe THEN
          -- NBO - 26/10/16 - Ajout des status
          lv_errmsg := 'société du projet en R12 est différente de celle extraite de la 11i :' || c_tmp.societe ||','|| c_tmp.region || ',' || c_tmp.code_projet || ',' || c_tmp.type_evenement ||',' || v_societe;
          dka_tools_pkg.put_debug_message(lv_errmsg);

          lv_errmsg := 'société du projet en R12 est différente de celle extraite de la 11i';
       	  -- NBO 20/10/16 - Gestion des rowids pour éviter les problémes de curseur
          UPDATE DKA_REPPAREVENUIMP_TMP
          SET    STATUS = gv_status_reject,
                 ERROR_MESSAGE = lv_errmsg
          WHERE rowid = c_tmp.rid;
          g_nb_event_rejete := g_nb_event_rejete + 1;
          b_continue := false;

          -- NBO 09/11/16 - Gestion des retours pour éviter des tous ou rien 
          vn_retcode := 1;

        END IF;

         -- NBO 30/08/17 - artf2200431 Reprise des revenus projets - Ajouter un contrôle sur les dates de validité du projet
         /*SELECT COUNT(1)
           INTO l_count
           FROM pa_projects_all ppa, pa_tasks pt
          WHERE ppa.segment1 = c_tmp.code_projet_new
            AND pt.project_id = ppa.project_id
            AND pt.task_number = c_tmp.tache
            AND NOT EXISTS (SELECT 'x'
                FROM pa_periods_all pp
           WHERE pp.period_name = pv_period
             AND pp.end_date between pt.start_date AND nvl(pt.completion_date,pp.end_date));
             
            IF l_count > 0 THEN
            lv_errmsg := 'La date de fin de période n''est pas dans la fourchette de la tache du projet';
            dka_tools_pkg.put_debug_message(lv_errmsg);

            UPDATE DKA_REPPAREVENUIMP_TMP
            SET    STATUS = gv_status_reject,
                   ERROR_MESSAGE = lv_errmsg
            WHERE rowid = c_tmp.rid;
            g_nb_event_rejete := g_nb_event_rejete + 1;
            b_continue := false;

            vn_retcode := 1;
         END IF; */     

        
				IF b_continue THEN
      	  -- NBO 20/10/16 - déplacement de la fonction suite à  un probléme de choix de responsabilité
          gv_step := 'INIT ENV';
          init_environement(pv_errbuf, pn_retcode, v_region || v_societe, n_org_id);

					PA_INTERFACE_UTILS_PUB.Set_Global_Info(
												  p_api_version_number => 1.0,
												  p_responsibility_id  => g_resp_id,
												  p_user_id            => g_user_id,
												  p_resp_appl_id       => g_appl_id,
												  p_operating_unit_id   => n_org_id,
												  p_msg_count          => n_msg_count,
												  p_msg_data           => v_message,
												  p_return_status      => c_return_status
												  );

					SELECT PA_BILLING_ASSIGNMENTS_S.nextval
					INTO pa_billing.GlobVars.BillingAssignmentId
					FROM DUAL;

          dka_tools_pkg.put_debug_message('select task');
                    -- 	NBO 02/03/17 artf2108043 - DEFECT 579 - Certains évènements sont repris avec un mauvais TASK_ID 
					--IF (v_old_tache_proj <> c_tmp.TACHE) THEN
            gv_step := 'SELECT TASK';
						SELECT TOP_TASK_ID INTO n_tache_id FROM PA_TASKS WHERE TASK_NUMBER = c_tmp.TACHE AND PROJECT_ID = n_code_proj_id;
					--	v_old_tache_proj := c_tmp.TACHE;
					--END IF;
					v_message := '';

  		  -- NBO 20/10/16 - artf2024248 - Plusieurs anomalies à corriger
          --select end_date into d_end_period
          --from PA_PERIODS where period_name = pv_period;
       	  -- 09/01/2017 NBO artf2074070 - Reprise des revenus - Import des CCA/TEC/PCA
          SELECT end_date,
                 (SELECT start_date
                    FROM pa_periods pp2
                   WHERE pp.end_date + 1 BETWEEN pp2.start_date AND
                         pp2.end_date)
            INTO d_end_period, d_next_period
            FROM pa_periods pp
           WHERE period_name = pv_period;

					/*insert_event_spec(	X_rev_amt	 	  	=> c_tmp.MONTANT_REVENU,
										X_bill_amt	 	  	=> c_tmp.MONTANT_REVENU,
										X_project_id 	  	=> n_code_proj_id,
										X_event_type 	  	=> c_tmp.TYPE_EVENEMENT,
										X_top_task_id 	  	=> n_tache_id,
										X_organization_id 	=> n_org_id,
										X_completion_date 	=> c_tmp.DATE_EVENEMENT,
										x_event_description => 'MIGRATION_R12',
          								X_error_message	  	=> v_message,
										X_status	 	  	=> n_status
										);*/

  		  -- NBO 20/10/16 - artf2024248 - Plusieurs anomalies é corriger
          dka_tools_pkg.put_debug_message('pn_retcode='||pn_retcode);

          gv_step := 'BILL_CCID';
          dka_tools_pkg.get_code_combination_id(
                            pv_segment1 => v_societe,
                            pv_segment2 => v_region,
                            pv_segment3 => '0',
                            pv_segment4 => '0',
                            pv_segment5 => '0',
                            pv_segment6 => '0',
                            pv_segment7 => '0',
                            pv_segment8 => '0',
                            pv_segment9 => '0',
                            pv_segment10 => '0',
                            pv_segment11 => '0',
                            pv_segment12 => '0',
                            pn_code_combination_id => vn_unbilled_ccid,
                            pv_errbuf => vv_errbuf_billccid,
                            pn_retcode => vn_retcode_billccid,
                            pv_validation_flag => 'Y');

            --dka_tools_pkg.put_debug_message('pn_retcode='||pn_retcode);

            dka_tools_pkg.put_debug_message('vn_unbilled_ccid='||vn_unbilled_ccid);

            gv_step := 'CCID';
            dka_tools_pkg.get_code_combination_id(
                            pv_segment1 => v_societe,
                            pv_segment2 => v_region,
                            pv_segment3 => 'REP',
                            pv_segment4 => 'REP',
                            pv_segment5 => '0',
                            pv_segment6 => '0',
                            pv_segment7 => '0',
                            pv_segment8 => '0',
                            pv_segment9 => '0',
                            pv_segment10 => '0',
                            pv_segment11 => '0',
                            pv_segment12 => '0',
                            pn_code_combination_id => vn_ccid,
                            pv_errbuf => vv_errbuf_ccid,
                            pn_retcode => vn_retcode_ccid,
                            pv_validation_flag => 'Y');

            dka_tools_pkg.put_debug_message('vn_ccid='||vn_ccid);

            IF vn_retcode_billccid <> 0 THEN
               dka_tools_pkg.put_debug_message('vv_errbuf_billccid='||vv_errbuf_billccid);
               dka_tools_pkg.put_debug_message('vn_retcode_billccid='||vn_retcode_billccid);
               dka_tools_pkg.put_debug_message(v_societe||':'||v_region);
               vn_retcode := 1;
               pv_errbuf := vv_errbuf_billccid;
            END IF;

            IF vn_retcode_ccid <> 0 THEN
               dka_tools_pkg.put_debug_message('vn_retcode_ccid='||vn_retcode_ccid);
               dka_tools_pkg.put_debug_message(v_societe||':'||v_region);
               vn_retcode := 1;
               pv_errbuf := vv_errbuf_ccid;
            END IF;

            dka_tools_pkg.put_debug_message('vn_retcode='||vn_retcode);

            -- NBO 09/11/16 - Gestion des retours pour éviter des tous ou rien 
            IF vn_retcode = 0 THEN

              -- NBO - 18/10/16 - artf2014423 : Reprise des revenus projets - Pb dans la gestion de la date
              -- NBO - 18/10/16 - artf2030027 : changement de la description de l'evenement PA
               -- 18/01/2017 NBO artf2074070 - Reprise des revenus - Import des CCA/TEC/PCA
               IF c_tmp.TYPE_EVENEMENT IN (gv_et_cca_fin, gv_et_pca_fin, gv_et_tec_ci_fin, gv_et_tec_fin) AND d_next_period IS NULL THEN
                lv_errmsg := 'La période suivante n''a pas été trouvée';
                vn_retcode := 1;
              ELSE

                -- NBO 13/02/17 - artf2096822 - RUN3 - Reprise des revenus - Alimentation de l'ATT_CAT pour les TEC ET PCA DEBUT
                IF c_tmp.type_evenement = gv_et_cca_fin THEN
                  lv_evt_type := gv_et_cca_debut;
                  --lv_evt_context := 'CCA';
                  lv_evt_context := NULL;
                ELSIF c_tmp.type_evenement = gv_et_pca_fin THEN
                  lv_evt_type := gv_et_pca_debut;
                  lv_evt_context := 'PCA';
                ELSIF c_tmp.type_evenement = gv_et_tec_ci_fin THEN
                  lv_evt_type := gv_et_tec_ci_debut;
                  lv_evt_context := 'TEC';
                ELSIF c_tmp.type_evenement = gv_et_tec_fin THEN
                  lv_evt_type := gv_et_tec_debut;
                  lv_evt_context := 'TEC';
                ELSE
                  lv_evt_context := NULL;
                END IF;

			    -- NBO 02/03/17 - artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
                IF lv_project_type = 'REFAC' THEN
                  lv_attribute3 := 'MIGRATION_R12';
                ELSE
                  lv_attribute3 := NULL;
                END IF;

                gv_step := 'INSERT_EVENT';

                dka_pa_tools_pkg.pa_insert_event(pn_task_id => n_tache_id,
                                        pv_event_type => c_tmp.TYPE_EVENEMENT,
                                        pn_amount => c_tmp.MONTANT_REVENU,
                                        pn_project_id => n_code_proj_id,
                                        pd_completion_date => d_end_period,
                                        pv_insert_revenue_flag => 'Y',
                                        pv_description => 'REPRISE projet ' || c_tmp.code_projet || ' ' || c_tmp.region,
                                        pn_ccid => vn_ccid,
                                        pn_unbilled_ccid => vn_unbilled_ccid,
										-- NBO 13/02/17 - artf2096822 - RUN3 - Reprise des revenus - Alimentation de l'ATT_CAT pour les TEC ET PCA DEBUT
                    --                    pv_event_attr_context => lv_evt_type
									    -- NBO 02/03/17 - artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
                                        pv_event_attribute3 => lv_attribute3,
                                        pn_event_organization_id => n_evt_org_id,
                                        pn_org_id => n_org_id,
                                        pv_insert_into_gl => 'N',
                                        --pv_errbuf => pv_errbuf,
                                        -- NBO 09/11/16 - Gestion des retours pour éviter des tous ou rien 
                                        pv_errbuf => lv_errmsg,
                                        pn_result => vn_retcode);
                IF vn_retcode <> 0 THEN
                  ROLLBACK;
                ELSE
                  COMMIT;
                END IF;

                -- 09/01/2017 NBO artf2074070 - Reprise des revenus - Import des CCA/TEC/PCA
                -- 18/01/2017 NBO artf2074070 - Reprise des revenus - Import des CCA/TEC/PCA
                -- 07/11/2017 NBO artf2271904 : REPRISE_REVENUS - Ne plus créer les événements TEC PCA CCA de DEBUT
                /*IF c_tmp.TYPE_EVENEMENT IN (gv_et_cca_fin, gv_et_pca_fin, gv_et_tec_ci_fin, gv_et_tec_fin) THEN


                  gv_step := 'INSERT_EVENT2';
                  dka_pa_tools_pkg.pa_insert_event(pn_task_id => n_tache_id,
                                          pv_event_type => lv_evt_type,
                                          pn_amount => c_tmp.MONTANT_REVENU,
                                          pn_project_id => n_code_proj_id,
                                          pd_completion_date => d_next_period,
                                          pv_insert_revenue_flag => 'Y',
                                          pv_description => 'REPRISE projet ' || c_tmp.code_projet,
                                          pn_ccid => vn_ccid,
                                          pn_unbilled_ccid => vn_unbilled_ccid,
										  -- NBO 08/02/17 - artf2096822 - RUN3 - Reprise des revenus - Alimentation de l'ATT_CAT pour les TEC ET PCA DEBUT
                                          pv_event_attr_context => lv_evt_context,
										  -- NBO 02/03/17 - artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
                                          pv_event_attribute3 => lv_attribute3,
                                          pn_event_organization_id => n_evt_org_id,
                                          pn_org_id => n_org_id,
                                          pv_insert_into_gl => 'N',
                                          pv_errbuf => lv_errmsg,
                                          pn_result => vn_retcode);
                  IF vn_retcode <> 0 THEN
                    ROLLBACK;
                  ELSE
                    COMMIT;
                  END IF;
                END IF;*/
              END IF;

            ELSE
              -- NBO - 26/10/16 - Ajout des status
              lv_errmsg := 'Probléme de génération de CCID : '||vv_errbuf_billccid || ':' || vv_errbuf_billccid;
              UPDATE DKA_REPPAREVENUIMP_TMP
						  SET    STATUS = gv_status_reject,
                     ERROR_MESSAGE = lv_errmsg
						  WHERE rowid = c_tmp.rid;
						  g_nb_event_rejete := g_nb_event_rejete + 1;
            END IF;

					--IF n_status <> 0 THEN
          IF vn_retcode <> 0 THEN
                        -- NBO - 26/10/16 - Ajout des status
						--pn_retcode := 1;
						UPDATE DKA_REPPAREVENUIMP_TMP
						SET    STATUS = gv_status_reject
						WHERE rowid = c_tmp.rid;
						g_nb_event_rejete := g_nb_event_rejete + 1;
						IF n_status < 0 THEN
							pv_errbuf  := 'ERREUR ORACLE : ' || lv_errmsg;
							--Dka_Tools_Pkg.put_log_message('ERREUR ORACLE : Code projet : ' || c_tmp.CODE_PROJET || ' Type d''ï¿¿vï¿¿nement : ' || c_tmp.TYPE_EVENEMENT || ' Montant : ' || c_tmp.MONTANT_REVENU || ' / '  || v_message);	
						ELSE
							pv_errbuf  := 'ERREUR APPLICATION : ' || lv_errmsg;
							--Dka_Tools_Pkg.put_log_message('ERREUR APPLICATION : Code projet : ' || c_tmp.CODE_PROJET || ' Type d''ï¿¿vï¿¿nement : ' || c_tmp.TYPE_EVENEMENT || ' Montant : ' || c_tmp.MONTANT_REVENU || ' / '  || v_message);					
						END IF;
						dka_tools_pkg.put_outdebug_message(RPAD(c_tmp.CODE_PROJET,20,' ') || RPAD(c_tmp.TYPE_EVENEMENT,15,' ') || RPAD(c_tmp.MONTANT_REVENU,20,' ')||RPAD(pv_errbuf,150,' '));

					ELSE
						UPDATE DKA_REPPAREVENUIMP_TMP
						SET    STATUS = gv_status_ok,
                   ERROR_MESSAGE = null
            WHERE rowid = c_tmp.rid;
						--Dka_Tools_Pkg.put_log_message('SUCCES : Code projet : ' || c_tmp.CODE_PROJET || ' Type d''ï¿¿vï¿¿nement : ' || c_tmp.TYPE_EVENEMENT || ' Montant : ' || c_tmp.MONTANT_REVENU || ' / ' ||  v_message);						
						g_nb_event_cree := g_nb_event_cree + 1;
					END IF;
				END IF;
			END IF;
		END LOOP;

    -- NBO 09/11/16 - Gestion des retours pour éviter des tous ou rien  
    IF g_nb_event_rejete > 0 THEN
      pn_retcode := 1;
    END IF;

    gv_step := 'FIN';
		Dka_Tools_Pkg.put_log_message('Fin program_import_revenus');
    END program_import_revenus;

	/*
    *************************************************************************
    * PROCEDURE NAME : Bilan
    *
    * DESCRIPTION
    *  Procédure de génération du bilan du traitement 
    *
    * PARAMETERS
    * ==========
    * NAME                 DESCRIPTION
    .* -------------------- -------------------------------------------------
    * pv_errbuf            Retour de message éventuel
    * pn_retcode           Statut du traitement en sortie
    ************************************************************************
    */
    PROCEDURE Report_Bilan( pv_errbuf            IN OUT VARCHAR2,
							pn_retcode           IN OUT NUMBER
						  )
    IS

    BEGIN

        Dka_Tools_Pkg.put_log_message('Debut Report_Bilan');

        --------------------
        -- Initialisation --
        --------------------
        pv_errbuf  := NULL;
        pn_retcode := 0;

        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('-----------------------------------------------------BILAN-------------------------------------------------------------------------');
        Dka_Tools_Pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
        Dka_Tools_Pkg.put_outdebug_message('. Nombre d''enregistrements chargés dans la table spécifique des revenus : ' || TO_CHAR(g_nb_event_charger)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('. Nombre d''évènements créés : ' || TO_CHAR(g_nb_event_cree)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('. Nombre d''évènements non valides : ' || TO_CHAR(g_nb_event_nonvalide)||CHR(10));
        Dka_Tools_Pkg.put_outdebug_message('. Nombre d''évènements rejetés : ' || TO_CHAR(g_nb_event_rejete)||CHR(10));

        Dka_Tools_Pkg.put_outdebug_message(CHR(10));
        Dka_Tools_Pkg.put_log_message('Fin Report_Bilan');

    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
            Dka_Tools_Pkg.put_log_message( pv_errbuf);
            Dka_Tools_Pkg.put_outdebug_message( TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - Erreur: ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
    END Report_Bilan;

    /*
    *************************************************************************
    /* PROCEDURE NAME : main
    /*
    /* DESCRIPTION
    /*  Procédure principale de l'interface de création des fournisseurs
    /*
    /* PARAMETERS
    /* ==========
    /* NAME              DESCRIPTION
    /* ----------------- ------------------------------------------------------
    /* pv_errbuf         Retour de message éventuel
    /* pn_retcode        Statut du traitement en sortie
    *************************************************************************
    */
    -- NBO - 20/10/16 - artf2014423 : Pb dans la gestion de la date
    PROCEDURE MAIN( pv_errbuf        IN OUT VARCHAR2,
                    pn_retcode       IN OUT NUMBER,
                    pv_chargement_f  IN VARCHAR2,
					          pv_chargement_oi IN VARCHAR2,
                    pv_period IN VARCHAR2
                   )
    IS

        -- ========== VARIABLES ==========
        v_package        VARCHAR2(30)  := 'DKA_REPPAREVENUIMP_PKG';
        v_nom_traitement VARCHAR2(200) := 'Import des revenus';
        v_sqlerrm        VARCHAR2(250) := NULL;
        v_procedure      VARCHAR2(30)  := 'MAIN';
        v_message        VARCHAR2(500);
        v_errbuf         VARCHAR2(2500);
        v_retcode        NUMBER;
        v_exeption       EXCEPTION;
        v_NomFich		 VARCHAR2(200) := 'DKA_REPPAREVENU';
		v_region      	 VARCHAR2(3)  := 'GFK';
    BEGIN
        ----------------------------------
        -- Début du Programme principal --
        ----------------------------------

        -- Initialisation des variables d'anomalies
        pn_retcode  := 0;
        pv_errbuf   := NULL;
        v_message   := 'Début procédure MAIN';
        gv_period   := pv_period;

         -- Initialisation de la sortie
		     Dka_Tools_Pkg.put_out_header;
		     Dka_Tools_Pkg.put_outdebug_message('Paramètre de lancement du traitement ' 	 || v_nom_traitement);
        Dka_Tools_Pkg.put_outdebug_message('Chargement des tables temporaires : '    || pv_chargement_f);
        Dka_Tools_Pkg.put_outdebug_message('Chargement des tables open interface : ' || pv_chargement_oi);

        ----------------------------------
        -- Initialisation des variables --
		----------------------------------
        v_message   := 'Init';
        Dka_Tools_Pkg.put_log_message( 'Initialisation des variables');
        Init;

        -----------------------------
        -- Chargement des fichiers --
        -----------------------------
        IF pv_chargement_f ='Y' THEN
            --Dka_Tools_Pkg.put_log_message('*============================================================================================*');
            --Dka_Tools_Pkg.put_log_message('* Chargement du fichiers plat *');
            --Dka_Tools_Pkg.put_log_message('*============================================================================================*');
            v_message   := 'PHASE DE CHARGEMENT DU FICHIER';
            -- Lancement du programme de chargement des fichiers
            Launch_Loader(pv_errbuf, pn_retcode, v_NomFich);

            IF pn_retcode = 2 THEN
                Dka_Tools_Pkg.put_log_message('Erreur : Probléme lors du chargement des fichiers plat');
                RAISE v_exeption;
            END IF;
			--Dka_Tools_Pkg.put_log_message('Fin chargement des fichiers plat avec succés');

      -- NBO - 26/10/16 - Désactivation des transcos, mise en place des contr?
			-- Transco et Chargement des nouvelles UO
      --      Transco_Unite_Operationnelle(v_region);

			-- Transco et Chargement des nouveaux segments
        --    Transco_CodeProjet;

        END IF;

        -- NBO - 26/10/16 - Ajout de la procédure de contréle
        v_message   := 'PHASE DE CONTROLE';
        control_data(pv_errbuf, pn_retcode);

        -----------------------------------------------------------
        -- Création des événements de revenus via l'API standard --
        -----------------------------------------------------------
        IF pv_chargement_oi ='Y' THEN
			-- Création des événements de revenus via API standard
			--Dka_Tools_Pkg.put_log_message('*============================================================================================*');
            --Dka_Tools_Pkg.put_log_message('* Création des événements de revenus via fonction spécifique program_import_revenus *');
            --Dka_Tools_Pkg.put_log_message('*============================================================================================*');
      v_message   := 'PHASE D''IMPORT';
			program_import_revenus(pv_errbuf, pn_retcode, pv_period);
			IF pn_retcode = 2 THEN
				RAISE v_exeption;
			END IF;
			--Dka_Tools_Pkg.put_log_message('Création des événements de revenus terminée avec succés');       
	   END IF;
		----------------------------------
    -- Phase de bilan du traitement --
    ----------------------------------
    v_message   := 'PHASE DE REPORTING';
    Report_Bilan(pv_errbuf,pn_retcode);

    IF pn_retcode = 2 THEN
        RAISE v_exeption;
    END IF;

		IF g_nb_event_rejete > 0 then
			pn_retcode := 1;
      IF g_nb_event_rejete = 1 THEN
				Dka_Tools_Pkg.put_outdebug_message( 'Attention '|| g_nb_event_rejete ||' événement a été rejeté!');
			ELSE
				Dka_Tools_Pkg.put_outdebug_message( 'Attention '|| g_nb_event_rejete ||' événements ont été rejetés !');
			END IF;
		END IF;
        COMMIT;
        Dka_Tools_Pkg.put_log_message( pv_errbuf);
        Dka_Tools_Pkg.put_log_message( CHR(10)||pv_errbuf||CHR(10));
        Dka_Tools_Pkg.put_log_message('==========================================================================');
        Dka_Tools_Pkg.put_log_message( 'Traitement '|| v_nom_traitement ||' terminé ');
		Dka_Tools_Pkg.put_outdebug_message( 'Traitement '|| v_nom_traitement ||' terminé : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));

	    ----------------------------
        -- Gestion des exceptions --
		----------------------------
        EXCEPTION
        WHEN v_exeption THEN
            Dka_Tools_Pkg.put_log_message('-------------------- ERREUR --------------------');
            Dka_Tools_Pkg.put_log_message('Package   : '||v_package);
            Dka_Tools_Pkg.put_log_message('Procédure : '||v_procedure);
            Dka_Tools_Pkg.put_log_message('Exception : OTHERS');
            Dka_Tools_Pkg.put_log_message('Erreur     : '||pv_errbuf);
            Dka_Tools_Pkg.put_log_message('------------------------------------------------');
            Dka_Tools_Pkg.put_log_message('Fin de la procédure '||v_procedure||' : EXCEPTION v_exeption');        
            Dka_Tools_Pkg.put_log_message('=========================================================================');
            Dka_Tools_Pkg.put_outdebug_message('Traitement '||v_nom_traitement||' terminé en erreur.');
            ROLLBACK;

       WHEN OTHERS THEN
            v_sqlerrm := SUBSTR(SQLERRM,1,200);
            pn_retcode := 2;
            pv_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Dka_Tools_Pkg.put_log_message('-------------------- ERREUR --------------------');
            Dka_Tools_Pkg.put_log_message('Package   : '||v_package);
            Dka_Tools_Pkg.put_log_message('Procédure : '||v_procedure);
            Dka_Tools_Pkg.put_log_message('Exception : OTHERS');
            Dka_Tools_Pkg.put_log_message('Message   : '||v_message);
            Dka_Tools_Pkg.put_log_message('Etape : ' || gv_step);
            Dka_Tools_Pkg.put_log_message( CHR(10)||pv_errbuf);
            Dka_Tools_Pkg.put_log_message('Cause     : '||v_sqlerrm);
            Dka_Tools_Pkg.put_log_message('------------------------------------------------');
            Dka_Tools_Pkg.put_outdebug_message('Traitement '||v_nom_traitement||' terminé en erreur.');
            ROLLBACK;

    END main;


END DKA_REPPAREVENUIMP_PKG;
/
SHOW ERRORS;
EXIT
