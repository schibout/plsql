SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_SPAAUTCRE_PKG IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_SPAAUTCRE_PKG.pkb  V1.0
  --
  -- AUTEUR
  --    Capgemini
  --
  -- DESCRIPTION
  --    Création du package du traitement de création des sociétés 
  --
  -- USAGE
  --    A exécuter sous SqlPlus avec user APPS sans paramètre
  --
  -- NOTES
  --
  -- PARAMETERS
  --
  ---------------------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  ---------------------------------------------------------------------------------------------
  -- Version   Date         Qui Description
  ---------- -------------- --- ---------------------------------------------------------------
  -- V1.0    11/10/2019     OCL Creation
  -- V1.1    22/07/2022     IBA artf07553141 TASK0182686 - Problème de prise en compte de toutes les UO dans le traitement des options fournisseurs et beneficiaires
  ---------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  g_user_id              fnd_user.user_id%TYPE;
  g_login_id             fnd_logins.login_id%TYPE;
  g_org_id               hr_all_organization_units.organization_id%TYPE;
  g_request_id           fnd_concurrent_requests.request_id%TYPE;
  gv_printer             fnd_concurrent_requests.printer%TYPE;
  g_number_of_copies     fnd_concurrent_requests.number_of_copies%TYPE;
  g_tempo                NUMBER;
  g_warning              BOOLEAN := FALSE;
  g_unite_ope            NUMBER;
  g_cpteur_enreg         NUMBER := 0;
  g_cpteur_benef         NUMBER := 0;

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

  PROCEDURE init(p_errbuf  OUT VARCHAR2,
                 p_retcode OUT NUMBER) IS
  
    v_current_program_unit VARCHAR2(30);
    v_step_program_error   VARCHAR2(1000);
    program_error EXCEPTION;
	
	vn_responsibility_id  NUMBER;
	vn_application_id     NUMBER;
  
  BEGIN
  
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début init');
  
    ----------------------------------
    -- Initialisation des variables --
    ----------------------------------
    p_errbuf               := NULL;
    p_retcode              := 0;
    v_current_program_unit := 'INIT';
  
    ------------------------
    -- Variables globales --
    ------------------------
  
    g_user_id    := fnd_global.user_id;
    g_login_id   := fnd_global.login_id;
    g_request_id := fnd_global.conc_request_id;
    g_org_id     := fnd_profile.value('ORG_ID');
    g_tempo      := 20;
  
  
    -- Formatage de la date comptable
    --g_gl_date := TRUNC(fnd_date.canonical_to_date(p_gl_date));
  
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin init');
					  

  
    BEGIN
      SELECT printer, number_of_copies
        INTO gv_printer, g_number_of_copies
        FROM fnd_concurrent_requests fcr
       WHERE fcr.request_id = g_request_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Dka_Tools_Pkg.put_debug_message(
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' - ' ||
                          'Erreur de récupération de l''imprimante');
        gv_printer         := NULL;
        g_number_of_copies := 0;
    END;
  
  EXCEPTION
    WHEN program_error THEN
      Dka_Tools_Pkg.put_debug_message( 'ERREUR : ' || v_step_program_error);
      RAISE;
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'INIT : ' || SQLERRM;
  END init;

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

  PROCEDURE output_header IS
    cv_line                  VARCHAR2(100);
    v_conc_program_name      fnd_concurrent_programs.concurrent_program_name%TYPE;
    v_user_conc_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN
  
    cv_line := '+-------------------------------------------------------------------------+';
  
    ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
    BEGIN
      SELECT fcp.concurrent_program_name, fcpt.user_concurrent_program_name
        INTO v_conc_program_name, v_user_conc_program_name
        FROM fnd_concurrent_programs fcp, fnd_concurrent_programs_tl fcpt
       WHERE fcp.application_id = Fnd_Global.prog_appl_id
         AND fcp.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.application_id = Fnd_Global.prog_appl_id
         AND fcpt.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.LANGUAGE = Fnd_Global.current_language;
    EXCEPTION
      WHEN OTHERS THEN
        v_user_conc_program_name := '???????????????????????';
        v_conc_program_name      := '???????';
    END;
  
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Nom du traitement  : ' || v_user_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Code du traitement : ' || v_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Programme lancé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10) || CHR(10));
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

  PROCEDURE Request_parameters IS
  
    CURSOR cur_parameters IS
      SELECT form_left_prompt
        FROM fnd_concurrent_requests     fcr,
             fnd_concurrent_programs     fcp,
             fnd_descr_flex_col_usage_vl fdfcu
       WHERE fdfcu.descriptive_flexfield_name =
             '$SRS$.' || fcp.concurrent_program_name
         AND fcp.concurrent_program_id = fcr.concurrent_program_id
         AND fcr.request_id = Fnd_Global.conc_request_id
       ORDER BY fdfcu.column_seq_num;
    rec_parameters cur_parameters%ROWTYPE;
  
    sql_req           VARCHAR2(500);
    v_argument_number VARCHAR2(12);
    v_argument_num    NUMBER;
    v_argument_value  VARCHAR2(240);
  BEGIN
  
    Fnd_File.put_line(Fnd_File.output, 'PARAMETRES : ');
    Fnd_File.put_line(Fnd_File.output, '--------------');
    Dka_Tools_Pkg.put_debug_message( 'PARAMETRES : ');
    Dka_Tools_Pkg.put_debug_message( '--------------');
  
    v_argument_num := 1;
  
    OPEN cur_parameters;
    FETCH cur_parameters
      INTO rec_parameters;
  
    IF (cur_parameters%FOUND) THEN
      v_argument_number := 'ARGUMENT' || v_argument_num;
    
      sql_req := 'SELECT ' || v_argument_number ||
                 ' FROM fnd_concurrent_requests ' ||
                 'WHERE request_id = Fnd_Global.conc_request_id';
    
      EXECUTE IMMEDIATE sql_req
        INTO v_argument_value;
    
      Fnd_File.put_line(Fnd_File.output,
                        rec_parameters.form_left_prompt || ' : ' ||
                        v_argument_value);
      Dka_Tools_Pkg.put_debug_message(
                        rec_parameters.form_left_prompt || ' : ' ||
                        v_argument_value);
    
      LOOP
        FETCH cur_parameters
          INTO rec_parameters;
        EXIT WHEN cur_parameters%NOTFOUND;
      
        v_argument_num    := v_argument_num + 1;
        v_argument_number := 'ARGUMENT' || v_argument_num;
      
        sql_req := 'SELECT ' || v_argument_number ||
                   ' FROM fnd_concurrent_requests ' ||
                   'WHERE request_id = Fnd_Global.conc_request_id';
      
        EXECUTE IMMEDIATE sql_req
          INTO v_argument_value;
      
        Fnd_File.put_line(Fnd_File.output,
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
        Dka_Tools_Pkg.put_debug_message(
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
      END LOOP;
    
      Fnd_File.put_line(Fnd_File.output, CHR(10));
    
    ELSE
      Fnd_File.put_line(Fnd_File.output, 'Aucun argument');
      Dka_Tools_Pkg.put_debug_message( 'Aucun argument');
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

  PROCEDURE output_end IS
    cv_line VARCHAR2(100);
  BEGIN
  
    cv_line := '+-------------------------------------------------------------------------+';
  
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Programme terminé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line);
  END output_end;




/*
   *************************************************************************
   * PROCEDURE NAME : ajout_beneficiaires
   *
   * DESCRIPTION
   *  Ajout des UOs du périmètre en tant que bénéficiaire de l'UO passée 
   * en paramètre
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   * pn_legal_entity_id Entity_id de l'UO passée en paramètre
   ************************************************************************
   */
	PROCEDURE ajout_beneficiaires(pn_name_org  IN VARCHAR2,
				 pn_legal_entity_id IN NUMBER,
				 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
  
		v_current_program_unit VARCHAR2(30);
		v_errbuf               VARCHAR2(2500);
		v_retcode              NUMBER;
		
		CURSOR cur_uo  IS 
		SELECT 
		hou.organization_id ,
		hou.name,
		xep.legal_entity_id
		FROM
		hr_operating_units hou,
		xle_entity_profiles xep,
		gl_sets_of_books gsob,
		pa_implementations_all imp,
		PER_SECURITY_ORGANIZATIONS pso
		WHERE
		-- RG7 : Une unité opérationnelle ne peut être ajoutée 
		-- à la fois en en-tête des options définies par fournisseur/bénéficiaire 
		-- et en tant que bénéficiaire
		hou.organization_id != g_unite_ope
		-- RG5 UO active
	    AND (hou.date_to > sysdate
		OR   hou.date_to is null)
		--  RG5 UO qui utilise la devise EUR
		AND gsob.currency_code = 'EUR'
		AND gsob.name != 'REFERENCE'
		AND imp.org_id = hou.organization_id
		--<Debut IBA artf07553141
		and pso.ORGANIZATION_ID = Hou.organization_id
         AND pso.SECURITY_PROFILE_ID= 63
		  AND hou.default_legal_context_id = xep.legal_entity_id
       and xep.legal_entity_identifier = gsob.short_name
		--Fin IBA artf07553141>
		;
		
		rec_uo cur_uo%ROWTYPE;
		
	BEGIN
	
		
		OPEN Cur_uo;
		LOOP
			FETCH cur_uo INTO rec_uo;
			EXIT WHEN Cur_uo%NOTFOUND;
			BEGIN
				-- Insertion enregistrement
				INSERT INTO pa_cc_org_relationships
				(PRVDR_ORG_ID,
				 RECVR_ORG_ID,
				 PRVDR_ALLOW_CC_FLAG,
				 CROSS_CHARGE_CODE,
				 LAST_UPDATE_DATE,
				 LAST_UPDATED_BY,
				 CREATION_DATE,
				 CREATED_BY,
				 LAST_UPDATE_LOGIN,
				 PRVDR_LEGAL_ENTITY_ID,
				 RECVR_LEGAL_ENTITY_ID
				)
				VALUES
				(G_UNITE_OPE,
				 REC_UO.ORGANIZATION_ID,
				 'Y',
				 'N',
				 SYSDATE,
				 FND_PROFILE.VALUE('USER_ID'),
				 SYSDATE,
				 FND_PROFILE.VALUE('USER_ID'),
				 FND_PROFILE.VALUE('LOGIN_ID'),
				 PN_LEGAL_ENTITY_ID,
				 REC_UO.LEGAL_ENTITY_ID
				 );
				 Fnd_File.put_line(Fnd_File.OUTPUT,'UO '||rec_uo.name ||' ajoutée en tant que bénéficiaire sur '||pn_name_org);
				 g_cpteur_benef := g_cpteur_benef + 1;
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					p_retcode := 1;
					Fnd_File.put_line(Fnd_File.OUTPUT,'UO '||rec_uo.name ||' déjà existante en tant que bénéficiaire sur '||pn_name_org);
				
			END;
		END LOOP;
		CLOSE Cur_uo;
	
	  EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_debug_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SPAAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END ajout_beneficiaires;
  
/*
   *************************************************************************
   * PROCEDURE NAME : enregistrement
   *
   * DESCRIPTION
   *  Enregistrement de l'UO en tant que bénéficiaires sur les UO du périmètre
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   * pn_legal_entity_id Entity_id de l'UO passée en paramètre
   ************************************************************************
   */
	PROCEDURE enregistrement(pn_name_org  IN VARCHAR2,
				 pn_legal_entity_id IN NUMBER,
                 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
  
		v_current_program_unit VARCHAR2(30);
		v_errbuf               VARCHAR2(2500);
		v_retcode              NUMBER;
		CURSOR cur_enreg_uo  IS 
		SELECT 
		hou.organization_id ,
		hou.name,
		xep.legal_entity_id
		FROM
		hr_operating_units hou,
		xle_entity_profiles xep,
		gl_sets_of_books gsob,
		pa_implementations_all imp,
		PER_SECURITY_ORGANIZATIONS pso
		WHERE
		-- RG7 : Une unité opérationnelle ne peut être ajoutée 
		-- à la fois en en-tête des options définies par fournisseur/bénéficiaire 
		-- et en tant que bénéficiaire
		hou.organization_id != g_unite_ope
		-- RG5 UO active
	    AND (hou.date_to > sysdate
		OR   hou.date_to is null)
		--  RG5 UO qui utilise la devise EUR
		AND gsob.currency_code = 'EUR'
		AND gsob.name != 'REFERENCE'
		AND imp.org_id = hou.organization_id
		--<Debut IBA artf07553141
		and pso.ORGANIZATION_ID = Hou.organization_id -- SELO
         AND pso.SECURITY_PROFILE_ID= 63
		  AND hou.default_legal_context_id = xep.legal_entity_id
       and xep.legal_entity_identifier = gsob.short_name
		--Fin IBA artf07553141>
		; 
		
		rec_enreg_uo cur_enreg_uo%ROWTYPE;
	BEGIN
	
	  OPEN CUR_ENREG_UO;
		LOOP
			FETCH CUR_ENREG_UO INTO REC_ENREG_UO;
			EXIT WHEN CUR_ENREG_UO%NOTFOUND;
			BEGIN
				-- INSERTION ENREGISTREMENT
				INSERT INTO PA_CC_ORG_RELATIONSHIPS
				(PRVDR_ORG_ID,
				 RECVR_ORG_ID,
				 PRVDR_ALLOW_CC_FLAG,
				 CROSS_CHARGE_CODE,
				 LAST_UPDATE_DATE,
				 LAST_UPDATED_BY,
				 CREATION_DATE,
				 CREATED_BY,
				 LAST_UPDATE_LOGIN,
				 PRVDR_LEGAL_ENTITY_ID,
				 RECVR_LEGAL_ENTITY_ID
				)
				VALUES
				(REC_ENREG_UO.ORGANIZATION_ID,
				 G_UNITE_OPE,
				 'Y',
				 'N',
				 SYSDATE,
				 FND_PROFILE.VALUE('USER_ID'),
				 SYSDATE,
				 FND_PROFILE.VALUE('USER_ID'),
				 FND_PROFILE.VALUE('LOGIN_ID'),
				 REC_ENREG_UO.LEGAL_ENTITY_ID,
				 PN_LEGAL_ENTITY_ID
				 );
				  g_cpteur_enreg := g_cpteur_enreg + 1;
				  Fnd_File.put_line(Fnd_File.OUTPUT,'UO '||pn_name_org ||' ajoutée en tant que bénéficiaire sur '||rec_enreg_uo.name);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
				-- affichage message enregistrement déjà présent
				p_retcode := 1;
				Fnd_File.put_line(Fnd_File.OUTPUT,'UO '||pn_name_org ||' déjà existante en tant que bénéficiaire sur '||rec_enreg_uo.name);
			END;
		END LOOP;
		CLOSE CUR_ENREG_UO;
	  
	  EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_debug_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SPAAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END enregistrement;
  
  
  /*
   *************************************************************************
   * PROCEDURE NAME : main
   *
   * DESCRIPTION
   *  Procédure principale de l'interface de création des fournisseurs
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * p_directory      Repertoire
   * p_file_name      Nom du fichier à charger
   ************************************************************************
   */

  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
				 pv_unite_ope IN NUMBER) IS
  
    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
	vn_name_org             VARCHAR2(200);
	vn_legal_entity_id     NUMBER;
    Erreur_Programme EXCEPTION;
  
  BEGIN
  
    ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------
  
    v_current_program_unit := 'main';
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
  
    Output_Header;
    Request_parameters;
  
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''INITIALISATION');
    g_unite_ope := pv_unite_ope;
    v_errbuf  := NULL;
    v_retcode := 0;
  
    Init(v_errbuf, v_retcode);
  
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    
	-- Récupération de l'org_id de l'UO passée en paramètre
		SELECT name
		INTO vn_name_org
		FROM hr_operating_units
		WHERE organization_id = pv_unite_ope;
	-- Récupération de legal_entity_id de l'UO passée en paramètre	
		SELECT legal_entity_id
		INTO vn_legal_entity_id
		FROM xle_entity_profiles
		WHERE legal_entity_identifier = substr(vn_name_org,4,4);
    ---------------------------------------------------------
    -- AJOUT DES BENEFICIAIRES SUR L'UO PASSEE EN PARAMETRE --
    ----------------------------------------------------------
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'AJOUT DES BÉNÉFICIAIRES SUR L''UO '||pv_unite_ope);
  
    ajout_beneficiaires(vn_name_org, vn_legal_entity_id, v_errbuf, v_retcode);
	IF v_retcode = 1 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
    END IF;
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
  
	-------------------------------------------------------------------
    -- ENREGISTREMENT DE L'UO COMME BENEFICIAIRES SUR LES AUTRES UO --
    -------------------------------------------------------------------
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'ENREGISTREMENT DE L''UO '||pv_unite_ope||' COMME BENEFICIAIRE SUR LES AUTRES UO');
  
    enregistrement(vn_name_org, vn_legal_entity_id, v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
  IF v_retcode = 1 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
    END IF;
   Fnd_File.put_line(Fnd_File.OUTPUT,g_cpteur_benef ||' UO ajoutées en tant que bénéficiaire sur '||vn_name_org);
   Fnd_File.put_line(Fnd_File.OUTPUT,'UO '||vn_name_org ||' ajoutée en tant que bénéficiaire sur '||g_cpteur_enreg || ' UO');
		
  
    ---------------------------------------
    -- PHASE DE FIN DU TRAITEMENT MAITRE --
    ---------------------------------------
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
    ELSIF (p_retcode = 1) THEN
      p_errbuf  := 'AVERTISSEMENT';
      p_retcode := 1;	  
    ELSE
      p_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      p_retcode := 0;
	  COMMIT;
    END IF;
  
    Dka_Tools_Pkg.put_debug_message( p_errbuf);
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf || CHR(10));
    output_end;
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');
  
  EXCEPTION
    WHEN Erreur_Programme THEN
	  fnd_concurrent.af_rollback;
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      Dka_Tools_Pkg.put_debug_message( p_errbuf);
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf);
      Dka_Tools_Pkg.put_debug_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure ' || v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Fin de la procédure ' ||
                        v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_debug_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SPAAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END main;

END DKA_SPAAUTCRE_PKG;
/
SHOW ERRORS
EXIT
