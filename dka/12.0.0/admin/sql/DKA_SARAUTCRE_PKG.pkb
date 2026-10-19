SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_SARAUTCRE_PKG IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_SARAUTCRE_PKG.pkb  V1.0
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
  -- V1.0    15/10/2019     OCL Creation
  -- V2.0    10/12/2019     SELO Modification - pb de creation des categories. et alimentation de certains champs
  -- V3.0    16/01/2023     IBA  KDFI-671 - Traitement DKA : Création des comptes bancaires internes en erreur
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
  
    Dka_Tools_Pkg.put_log_message(
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
  
  
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin init');
  
    BEGIN
      SELECT printer, number_of_copies
        INTO gv_printer, g_number_of_copies
        FROM fnd_concurrent_requests fcr
       WHERE fcr.request_id = g_request_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Dka_Tools_Pkg.put_log_message(
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' - ' ||
                          'Erreur de récupération de l''imprimante');
        gv_printer         := NULL;
        g_number_of_copies := 0;
    END;
  
  EXCEPTION
    WHEN program_error THEN
      Dka_Tools_Pkg.put_log_message( 'ERREUR : ' || v_step_program_error);
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
    Dka_Tools_Pkg.put_log_message( 'PARAMETRES : ');
    Dka_Tools_Pkg.put_log_message( '--------------');
  
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
      Dka_Tools_Pkg.put_log_message(
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
        Dka_Tools_Pkg.put_log_message(
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
      END LOOP;
    
      Fnd_File.put_line(Fnd_File.output, CHR(10));
    
    ELSE
      Fnd_File.put_line(Fnd_File.output, 'Aucun argument');
      Dka_Tools_Pkg.put_log_message( 'Aucun argument');
    END IF;
  
    CLOSE cur_parameters;
  
  END Request_parameters;
  
------------------------------------------------------------
    -- get_receivables_trx_id
    -- Description: recherche de l'identifiant AR du type d'évènement pour les escomptes
    ------------------------------------------------------------
    FUNCTION GET_RECEIVABLES_TRX_ID(P_ORG_ID IN HR_ALL_ORGANIZATION_UNITS.ORGANIZATION_ID%TYPE,
                                    P_TYPE   IN AR_RECEIVABLES_TRX_ALL.TYPE%TYPE)
      RETURN AR_RECEIVABLES_TRX_ALL.RECEIVABLES_TRX_ID%TYPE IS
      K_API_NAME CONSTANT VARCHAR2(30) := 'GET_RECEIVABLES_TRX_ID';
      L_RESULT AR_RECEIVABLES_TRX_ALL.RECEIVABLES_TRX_ID%TYPE := NULL;
	  v_type AR_RECEIVABLES_TRX_ALL.TYPE%TYPE;
    
    BEGIN
    
      BEGIN
        SELECT RECEIVABLES_TRX_ID
          INTO L_RESULT
          FROM AR_RECEIVABLES_TRX_ALL
         WHERE ORG_ID = P_ORG_ID
           AND TYPE = P_TYPE
           AND STATUS = 'A';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
		   
		  select decode(nvl(p_type,'A'),'EDISC', 'escompte du actif', 'UNEDISC', 'escompte non du actif', nvl(p_type,'')) into v_type
		    from dual;
			
          --dbms_output.put_line('Il n''existe pas d''évènement d''escompte actif de type '||p_type||' pour l''ORG_ID '||p_org_id);
          Fnd_File.put_line(Fnd_File.LOG,
                            TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                            'Il n''existe pas de type d''évènement ' || v_type  || ' pour l''ORG_ID ' ||
                            p_org_id);
							
          fnd_file.put_line(fnd_file.output,
                            'Il n''existe pas de type d''évènement ' || v_type || ' pour l''ORG_ID ' ||
                            p_org_id);						
        WHEN OTHERS THEN
          --dbms_output.put_line('Une erreur est survenue lors de la recherche du type d''évènement pour les escomptes');
          Fnd_File.put_line(Fnd_File.LOG,
                            TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                            'Une erreur est survenue lors de la recherche du type d''évènement pour les escomptes');
          fnd_file.put_line(fnd_file.output,
							  'Une erreur est survenue lors de la recherche du type d''évènement pour les escomptes');								
      END;
    
      RETURN L_RESULT;
    END GET_RECEIVABLES_TRX_ID;
	
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
   * PROCEDURE NAME : Controle existence compte uo
   *
   * DESCRIPTION
   *  Controle existence compte bancaire interne
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   ************************************************************************
   */
   PROCEDURE CONTROLE_EXISTENCE_COMPTE_UO(PN_NAME_ORG IN VARCHAR2,
                                 PN_COUNT OUT NUMBER,
                                 P_ERRBUF OUT VARCHAR2,
								 P_RETCODE OUT NUMBER) IS
   BEGIN
   P_RETCODE :=0;
     SELECT COUNT(*)
	 INTO Pn_count
	 FROM CE_BANK_ACCOUNTS
	 WHERE BANK_ACCOUNT_NAME = substr(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||
	 substr(pn_name_org,1,3)||'0001';
	 
	 IF PN_COUNT > 0 THEN
		fnd_file.put_line(fnd_file.output,'Compte bancaire déjà existant '||substr(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||
			substr(pn_name_org,1,3)||'0001');
	   p_retcode := 1;
	 END IF;
	 
     EXCEPTION
      WHEN OTHERS THEN
	  p_retcode := 2;
	  Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || 
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
   END CONTROLE_EXISTENCE_COMPTE_UO;    
/*
   *************************************************************************
   * PROCEDURE NAME : Controle existence compte soc
   *
   * DESCRIPTION
   *  Controle existence compte bancaire interne
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   ************************************************************************
   */
   PROCEDURE CONTROLE_EXISTENCE_COMPTE_SOC(PN_NAME_ORG IN VARCHAR2,
                                 PN_COUNT OUT NUMBER,
                                 P_ERRBUF OUT VARCHAR2,
								 P_RETCODE OUT NUMBER) IS
   BEGIN
   P_RETCODE :=0;
     SELECT COUNT(*)
	 INTO Pn_count
	 FROM CE_BANK_ACCOUNTS
	 WHERE BANK_ACCOUNT_NAME = '0001_'||SUBSTR(PN_NAME_ORG,1,3)||'_452000_POUR_C_DE_'||PN_NAME_ORG;
	 
	  IF PN_COUNT > 0 THEN
		FND_FILE.PUT_LINE(fnd_file.output,'Compte bancaire déjà existant '||'0001_'||SUBSTR(PN_NAME_ORG,1,3)||'_452000_POUR_C_DE_'||PN_NAME_ORG);
		p_retcode := 1;
	 END IF;
	 
     EXCEPTION
      WHEN OTHERS THEN
	  p_retcode := 2;
	  Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || 
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
   END CONTROLE_EXISTENCE_COMPTE_SOC;
/*
   *************************************************************************
   * PROCEDURE NAME : recup_donnees_ccid
   *
   * DESCRIPTION
   *  Récupération données ccid
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   ************************************************************************
   */
   PROCEDURE RECUP_DONNEES_CCID(PN_NAME_ORG IN VARCHAR2,
                                 PV_CLE_COMPTABLE IN VARCHAR2,
								 PV_CENTRE_FINANCE OUT VARCHAR2,
								 PV_COMPTE_LOCAL OUT VARCHAR2,
								 PV_COMPTE_ANALYTIQUE OUT VARCHAR2,
								 PV_PROJET_FINANCE OUT VARCHAR2,
                                 P_ERRBUF OUT VARCHAR2,
								 P_RETCODE OUT NUMBER) IS
   BEGIN
	IF pv_cle_comptable = 'Gains de change réalisés'
	OR pv_cle_comptable = 'Pertes de change réalisées'
	THEN
	-- Récupération du centre finance à partir de la table de transco
	-- DKA_DKCODE_UO
		 BEGIN 
			
			SELECT DSL.PARAM1_VALUE 
			INTO PV_CENTRE_FINANCE
			FROM DKA_STRANSCO_HEADERS DSH,
				  DKA_STRANSCO_LINES DSL
			WHERE DSH.SET_NAME = 'DKA_DKCODE_UO'
			AND   DSH.SET_ID = DSL.SET_ID
			AND   DSL.RETURN_VALUE = SUBSTR(PN_NAME_ORG,1,3)
			AND   DSL.ENABLE = 'Y' 
			AND TRUNC(SYSDATE) BETWEEN DSL.START_DATE AND 
									   NVL(DSL.END_DATE,TRUNC(SYSDATE));
			
			
			EXCEPTION
			  WHEN NO_DATA_FOUND THEN
				fnd_file.put_line(fnd_file.output,
							 'Pas de centre finance trouvé pour la région '||SUBSTR(PN_NAME_ORG,1,3));
			  WHEN OTHERS THEN	
				fnd_file.put_line(fnd_file.output,
							 'Erreur dans la recherche du centre finance pour la région '||SUBSTR(PN_NAME_ORG,1,3));
		  END;		
	-- Récupération du projet finance de l'unité opérationnelle
	-- à partir du jeu de valeur DAOPCCF_PROJETFI
		BEGIN

			/*
		 SELECT VAL.FLEX_VALUE_MEANING
		  INTO PV_PROJET_FINANCE
		  FROM FND_FLEX_VALUE_SETS FFVS,
			   FND_FLEX_VALUES_VL VAL
		  WHERE FFVS.FLEX_VALUE_SET_ID = VAL.FLEX_VALUE_SET_ID
			AND FFVS.FLEX_VALUE_SET_NAME = 'DAOPCCF_PROJETFI'
			AND VAL.ENABLED_FLAG = 'Y'
			AND TRUNC(SYSDATE) BETWEEN VAL.START_DATE_ACTIVE
							   AND  NVL(VAL.END_DATE_ACTIVE,SYSDATE)
			AND VAL.DESCRIPTION like substr(PN_NAME_ORG,1,3)||'%'||substr(PN_NAME_ORG,4,4)||'%FPS%';
			
			*/
			
			
			SELECT DSTL.return_VALUE
			  INTO PV_PROJET_FINANCE
              FROM
					HR_ORGANIZATION_UNITS HOU,
					DKA_STRANSCO_LINES DSTL,
					DKA_STRANSCO_HEADERS DSTH
             WHERE
					DSTL.SET_ID = DSTH.SET_ID
                 AND HOU.NAME = DSTL.PARAM1_VALUE
				 AND HOU.NAME = SUBSTR(PN_NAME_ORG,1,7)
                 AND DSTH.SET_NAME LIKE 'DKA_CREATION_POUR_COMPTE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
				 AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE);
				 			
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				fnd_file.put_line(fnd_file.output,
							 'Pas de projet finance pour la société '||pn_name_org);
				
			/*	fnd_file.put_line(fnd_file.output,
							 '==> La clé comptable '|| pv_cle_comptable || ' n''est pas renseignée');
				fnd_file.put_line(fnd_file.output,
							 '==> Le compte bancaire interne n''est pas créé');*/
				p_retcode := 1;
				WHEN OTHERS THEN	
				fnd_file.put_line(fnd_file.output,
							 'Erreur dans la recherche du projet finance pour '||pn_name_org);
				
			/*	fnd_file.put_line(fnd_file.output,
							 '==> La clé comptable '|| pv_cle_comptable || ' n''est pas renseignée');
				fnd_file.put_line(fnd_file.output,
							 '==> Le compte bancaire interne n''est pas créé');	*/						 
				p_retcode := 1;
		 
		END;
	 ELSE 
	    PV_PROJET_FINANCE := '0';
		PV_CENTRE_FINANCE := '0';
	END IF;
-- Récupération des segments 3 (compte local) et 4 (compte analytique)
-- à partir de la table de transco DKA.DK_CLE_POUR_COMPTE
	BEGIN
        SELECT DSL.PARAM1_VALUE,
		       DSL.PARAM2_VALUE
	    INTO   PV_COMPTE_LOCAL,
		       PV_COMPTE_ANALYTIQUE
		FROM   DKA_STRANSCO_HEADERS DSH,
              DKA_STRANSCO_LINES DSL
        WHERE DSH.SET_NAME = 'DK_CLE_POUR_COMPTE'
        AND   DSH.SET_ID = DSL.SET_ID
        AND   DSL.RETURN_VALUE = PV_CLE_COMPTABLE
		AND   DSL.ENABLE = 'Y' 
        AND TRUNC(SYSDATE) BETWEEN DSL.START_DATE AND 
                                   NVL(DSL.END_DATE,TRUNC(SYSDATE));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			fnd_file.put_line(fnd_file.output,
			             'Pas de données trouvées pour la clé comptable '||PV_CLE_COMPTABLE);
			WHEN OTHERS THEN	
			fnd_file.put_line(fnd_file.output,
			             'Erreur dans la recherche des comptes local et analytique pour '||PV_CLE_COMPTABLE);
     
	END;
   EXCEPTION
      WHEN OTHERS THEN
	  p_retcode := 2;
	  Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || 
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
   END RECUP_DONNEES_CCID;
  /*
   *************************************************************************
   * PROCEDURE NAME : creation_comptes_uo
   *
   * DESCRIPTION
   *  Création des comptes bancaires internes pour l'UO passée en paramètre
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   ************************************************************************
   */
	PROCEDURE CREATION_COMPTES_UO(PN_NAME_ORG  IN VARCHAR2,
				 P_ERRBUF  OUT VARCHAR2,
				 P_RETCODE OUT NUMBER) IS
    v_current_program_unit VARCHAR2(30);
	v_errbuf               VARCHAR2(2500);
	v_retcode              NUMBER;
	p_acct_use_rec      apps.ce_bank_pub.bankacct_use_rec_type;
	vn_num_sequence    number;
	vn_bank_branch_id number;
	vn_bank_id    number;
	vv_currency_code varchar2(5);
	vn_account_owner_party_id number;
	vn_account_owner_org_id number;
	vv_entity_name VARCHAR2(240);
	vn_asset_code_combination_id gl_code_combinations.code_combination_id%type;
	vn_code_combination_id gl_code_combinations.code_combination_id%type;
	vv_compte_local VARCHAR2(240);
	vv_compte_analytique VARCHAR2(240);
	vv_centre_finance VARCHAR2(240);
	vv_projet_finance VARCHAR2(240);
	l_msg_count NUMBER;
	l_acct_use_id NUMBER;
	l_return_status VARCHAR2(1);
	v_org_id    number;
	vn_application_id number;
	
	BEGIN
	-- Récupération de bank_branch_id de l'agence
	P_RETCODE:=0;
	SELECT PARTY_ID
	INTO  VN_BANK_BRANCH_ID
	FROM   HZ_PARTIES
	WHERE party_name = 'COMPTE DE LIAISON';
	
	-- Récupération de bank_id 
	SELECT PARTY_ID
	INTO VN_BANK_ID
	FROM HZ_PARTIES
	WHERE party_name = 'TRESORERIE INTERNE';
	
	-- Récupération de la devise de la société
	-- du nom de la société
	-- des données du propriétaire du compte
	SELECT gsob.currency_code,
	       xep.name,
		   xep.party_id,
		   xep.legal_entity_id
	INTO vv_currency_code,
	     vv_entity_name,
		 vn_account_owner_party_id,
		 vn_account_owner_org_id
	FROM xle_entity_profiles xep,
		gl_sets_of_books gsob
	WHERE xep.legal_entity_identifier = substr(pn_name_org,4,4)
	--	AND xep.name = gsob.name     --IBA KDFI-671
		and xep.LEGAL_ENTITY_IDENTIFIER =gsob.SHORT_NAME; --IBA KDFI-671
			
  	SELECT APPLICATION_ID
	  INTO VN_APPLICATION_ID
	  FROM FND_APPLICATION
	 WHERE APPLICATION_SHORT_NAME = 'AR';	
		
	-- Récupération de la clé comptable de trésorerie
	BEGIN
		SELECT code_combination_id
	   INTO vn_asset_code_combination_id
	   FROM gl_code_combinations
	   WHERE SEGMENT1 = substr(pn_name_org,4,4)
	   AND  SEGMENT2 = substr(pn_name_org,1,3)
	   AND SEGMENT3 = '452000'
	   AND SEGMENT4 = '25080'
	   AND SEGMENT5 = substr(pn_name_org,1,3)||'0001'
	   AND SEGMENT6 = '0'
	   AND SEGMENT7 = '0'
	   AND SEGMENT8 = '0'
	   AND SEGMENT9 = '0'
	   AND SEGMENT10 = '0'
	   AND SEGMENT11 = '0'
	   AND SEGMENT12 = '0';
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
        Dka_Tools_Pkg.put_log_message(
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' - ' ||
                          'Création de la clé comptable');
	

        dka_tools_pkg.get_code_combination_id(
			pv_segment1 => substr(pn_name_org,4,4),
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => '452000',
			pv_segment4 => '25080',
			pv_segment5 => substr(pn_name_org,1,3)||'0001',
			pv_segment6 => '0',
			pv_segment7 => '0',
			pv_segment8 => '0',
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_asset_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);	
        
    END;
	
   -- Gestion de la séquence bank_account_id	
	SELECT ce_bank_accounts_s.nextval
	INTO vn_num_sequence
	FROM dual;
	
	--************************************
	-- Création du compte bancaire interne
	--************************************
	INSERT INTO ce_bank_accounts
	(
		bank_account_id,
		bank_account_name,
		last_update_date,
		last_updated_by,
		last_update_login,
		creation_date,
		created_by,
		bank_account_num,
		bank_branch_id,
		bank_id,
		currency_code,
		account_owner_party_id,
		account_owner_org_id,
		account_classification,
		ap_use_allowed_flag,
		ar_use_allowed_flag,
		multi_currency_allowed_flag,
		asset_code_combination_id,
		pooled_flag,
		receipt_multi_currency_flag,
		zero_amount_allowed,
		payment_multi_currency_flag,
		autorecon_ap_matching_order,
		autorecon_ap_matching_order2,
		stmt_line_float_handling_flag,
		autorecon_ar_matching_order,
		recon_for_bank_xrate_date_type,
		Recon_oi_matching_code,
		object_version_number,
		masked_account_num,
		ap_amount_tolerance,
		ar_amount_tolerance,
		ap_percent_tolerance,
		ar_percent_tolerance,
		recon_oi_amount_tolerance,
		recon_oi_percent_tolerance,
		ce_amount_tolerance,
		ce_percent_tolerance,
		pay_use_allowed_flag,
		netting_acct_flag,
		PAY_AMOUNT_TOLERANCE, -- SELO
		RECON_ENABLE_OI_FLAG, -- SELO
		BANK_ACCOUNT_NUM_ELECTRONIC -- SELO
	)
	VALUES
	(
		 vn_num_sequence,
		 substr(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||
		 substr(pn_name_org,1,3)||'0001',
		 SYSDATE,
		 FND_PROFILE.VALUE('USER_ID'),	 
		 FND_PROFILE.VALUE('LOGIN_ID'),
		 SYSDATE,
		 FND_PROFILE.VALUE('USER_ID'),
		 '99999999999',
		 vn_bank_branch_id,
		 vn_bank_id,
		 vv_currency_code,
		 vn_account_owner_party_id,
		 vn_account_owner_org_id,
		 'INTERNAL',
		 'Y',
		 'Y',
		 'Y',
		 vn_asset_code_combination_id,
		 'N',
		 'Y',
		 'Y',
		 'Y',
		 'T',--opération
		 'B',--Lot
		 'I',--ignorer
		 'T',--opération
		 'SLD',--date de la ligne de relevé
		 'T',--numéro de mouvement
		 1,
		 '99999999999',
		 0,
		 0,
		 0,
		 0,
		 0,
		 0,
		 0,
		 0,
		 'N',
		 'N',
		 0,  -- SELO
		 'N',-- SELO
		 '99999999999' -- SELO
	)
	;

	-- Utilisation de l'API CE_BANK_PUB.CREATE_BANK_ACCT_USE
	-- pour la création des affectations du compte bancaire
	
	-- Paramètres d'entrée de l'API
    v_org_id := g_unite_ope;
	p_acct_use_rec.asset_code_combination_id := vn_asset_code_combination_id;
	p_acct_use_rec.ap_asset_ccid := vn_asset_code_combination_id;
	p_acct_use_rec.ar_asset_ccid := vn_asset_code_combination_id;
	p_acct_use_rec.edisc_receivables_trx_id := get_receivables_trx_id(v_org_id, 'EDISC');
	p_acct_use_rec.unedisc_receivables_trx_id := get_receivables_trx_id(v_org_id, 'UNEDISC');
	p_acct_use_rec.ap_use_enable_flag := 'Y';
	p_acct_use_rec.ar_use_enable_flag := 'Y';
	p_acct_use_rec.bank_account_id := vn_num_sequence ;
	p_acct_use_rec.org_type   := 'OU';
	p_acct_use_rec.org_id   := v_org_id;
	p_acct_use_rec.authorized_flag            := 'Y';
    p_acct_use_rec.default_account_flag       := 'N';
	
	IF ((p_acct_use_rec.edisc_receivables_trx_id is null ) OR (p_acct_use_rec.unedisc_receivables_trx_id is null)) THEN
	     p_retcode:=2;
		 
	END IF;
	
	--**************************************************
	-- Récupération données Gains de change réalisés
	--**************************************************
	recup_donnees_ccid(pn_name_org => pn_name_org, 
	                  pv_cle_comptable => 'Gains de change réalisés',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
	IF v_retcode != 0
	  THEN
		 p_retcode:=v_retcode;
		 P_ERRBUF := v_errbuf;
		 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Récupération données Gains de change, Message: ' || P_ERRBUF);
	  END IF;
	-- SELO fin
	
	dka_tools_pkg.get_code_combination_id(
			pv_segment1 => substr(pn_name_org,4,4),
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => 'A00000000A',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
	IF v_retcode != 0
	  THEN
		 p_retcode:=v_retcode;
		 P_ERRBUF := v_errbuf;
		 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Gains de change, Message: ' || P_ERRBUF);
	  END IF;
	-- SELO fin
	
	p_acct_use_rec.gain_code_combination_id := vn_code_combination_id ;
	--**************************************************
	-- Recupération données pour Pertes de change réalisés
	--**************************************************
	recup_donnees_ccid(pn_name_org => pn_name_org, 
	                  pv_cle_comptable => 'Pertes de change réalisées',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
-- SELO Debut
	IF v_retcode != 0
	  THEN
		 p_retcode:=v_retcode;
		 P_ERRBUF := v_errbuf;
		 		 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Pertes de change, Message: ' || P_ERRBUF);
	  END IF;
	-- SELO fin
					  
	dka_tools_pkg.get_code_combination_id(
			pv_segment1 => substr(pn_name_org,4,4),
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => 'A00000000A',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
-- SELO Debut
	IF v_retcode != 0
	  THEN
		 p_retcode:=v_retcode;
		 P_ERRBUF := v_errbuf;
		 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Pertes de change, Message: ' || P_ERRBUF);
	  END IF;
	-- SELO fin	
	p_acct_use_rec.loss_code_combination_id := vn_code_combination_id;
	--*******************************************************
	-- Recupération données pour Encaissements non identifiés
	--********************************************************
	recup_donnees_ccid(pn_name_org => pn_name_org, 
	                  pv_cle_comptable => 'Enc/Rglt non identifiés',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
			 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Encaissements non identifiés, Message: ' || P_ERRBUF);
		END IF;
	-- SELO fin					  
	  dka_tools_pkg.get_code_combination_id(
			pv_segment1 => substr(pn_name_org,4,4),
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => '0',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
			 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Encaissements non identifiés, Message: ' || P_ERRBUF);			 
		END IF;	
	p_acct_use_rec.unidentified_ccid := vn_code_combination_id;
	--*******************************************************
	-- Recupération données pour Encaissements non lettrés
	--********************************************************
	recup_donnees_ccid(pn_name_org => pn_name_org, 
	                  pv_cle_comptable => 'Enc/Rglt non lettrés',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
			 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Encaissements non lettrés, Message: ' || P_ERRBUF);					 
		END IF;					  
	  dka_tools_pkg.get_code_combination_id(
			pv_segment1 => substr(pn_name_org,4,4),
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => '0',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
			 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Encaissements non lettrés, Message: ' || P_ERRBUF);				 
		END IF;	
	p_acct_use_rec.unapplied_ccid := vn_code_combination_id;
	--*******************************************************
	-- Recupération données pour Encaissements en compte
	--********************************************************
	recup_donnees_ccid(pn_name_org => pn_name_org, 
	                  pv_cle_comptable => 'Enc/Rglt en compte',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
			 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Encaissements en compte Encaissements non lettrés, Message: ' || P_ERRBUF);			 
		END IF;					  
	  dka_tools_pkg.get_code_combination_id(
			pv_segment1 => substr(pn_name_org,4,4),
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => '0',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
			 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Encaissements en compte Encaissements non lettrés, Message: ' || P_ERRBUF);				 
		END IF;	
	p_acct_use_rec.on_account_ccid := vn_code_combination_id;
	--********************************************************
	-- Appel de l'API pour les affectations du compte
	--********************************************************
	IF p_retcode = 0 THEN
	CE_BANK_PUB.CREATE_BANK_ACCT_USE(p_init_msg_list => FND_API.G_TRUE,
                                       p_acct_use_rec  => p_acct_use_rec,
                                       x_acct_use_id   => l_acct_use_id,
                                       x_return_status => l_return_status,
                                       x_msg_count     => l_msg_count,
                                       x_msg_data      => v_errbuf);
									   
		IF L_RETURN_STATUS <> FND_API.G_RET_STS_SUCCESS OR L_ACCT_USE_ID IS NULL THEN
			FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
							'Erreur lors de la création de l''affectation du compte bancaire '||PN_NAME_ORG);
			FND_FILE.PUT_LINE(FND_FILE.OUTPUT,V_ERRBUF);                        		
			P_RETCODE := 1;				
		ELSE
		   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
				'Création du compte bancaire '||SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)||'_452000_POUR_C_DE_'||
				SUBSTR(PN_NAME_ORG,1,3)||'0001');
		END IF;
	
	END IF;
	  EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END creation_comptes_uo;
  
  /*
   *************************************************************************
   * PROCEDURE NAME : creation_comptes_soc
   *
   * DESCRIPTION
   *  Création des comptes bancaires internes pour la société 0001
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   ************************************************************************
   */
	PROCEDURE creation_comptes_soc(pn_name_org  IN VARCHAR2,
	             pn_org_id_soc IN NUMBER,
				 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
   v_current_program_unit VARCHAR2(30);
	v_errbuf               VARCHAR2(2500);
	v_retcode              NUMBER;
	p_acct_use_rec      apps.ce_bank_pub.bankacct_use_rec_type;
	vn_num_sequence    number;
	vn_bank_branch_id number;
	vn_bank_id    number;
	vv_currency_code varchar2(5);
	vn_account_owner_party_id number;
	vn_account_owner_org_id number;
	vv_entity_name VARCHAR2(240);
	vn_asset_code_combination_id gl_code_combinations.code_combination_id%type;
	vn_code_combination_id gl_code_combinations.code_combination_id%type;
	vv_compte_local VARCHAR2(240);
	vv_compte_analytique VARCHAR2(240);
	vv_centre_finance VARCHAR2(240);
	vv_projet_finance VARCHAR2(240);
	l_msg_count NUMBER;
	l_acct_use_id NUMBER;
	l_return_status VARCHAR2(1);
	v_org_id number;
	vn_application_id number;		
	
	BEGIN
	P_RETCODE:=0;
	-- Récupération de bank_branch_id de l'agence
	SELECT PARTY_ID
	INTO  VN_BANK_BRANCH_ID
	FROM   HZ_PARTIES
	WHERE party_name = 'COMPTE DE LIAISON';
	
			 
	SELECT APPLICATION_ID
	  INTO VN_APPLICATION_ID
	  FROM FND_APPLICATION
	 WHERE APPLICATION_SHORT_NAME = 'AR';
			
	
	-- Récupération de bank_id 
	SELECT PARTY_ID
	INTO VN_BANK_ID
	FROM HZ_PARTIES
	WHERE party_name = 'TRESORERIE INTERNE';
	
	-- Récupération de la devise de la société
	-- du nom de la société
	-- des données du propriétaire du compte
	SELECT gsob.currency_code,
	       xep.name,
		   xep.party_id,
		   xep.legal_entity_id
	INTO vv_currency_code,
	     vv_entity_name,
		 vn_account_owner_party_id,
		 vn_account_owner_org_id
	FROM xle_entity_profiles xep,
		gl_sets_of_books gsob
	WHERE xep.legal_entity_identifier = '0001'
	--	AND xep.name = gsob.name   --IBA KDFI-671
		and xep.LEGAL_ENTITY_IDENTIFIER =gsob.SHORT_NAME; --IBA KDFI-671
	
	
	-- Récupération de la clé comptable de trésorerie
	BEGIN
		SELECT code_combination_id
	   INTO vn_asset_code_combination_id
	   FROM gl_code_combinations
	   WHERE SEGMENT1 = '0001'
	   AND  SEGMENT2 = substr(pn_name_org,1,3)
	   AND SEGMENT3 = '452000'
	   AND SEGMENT4 = '25080'
	   AND SEGMENT5 = pn_name_org
	   AND SEGMENT6 = '0'
	   AND SEGMENT7 = '0'
	   AND SEGMENT8 = '0'
	   AND SEGMENT9 = '0'
	   AND SEGMENT10 = '0'
	   AND SEGMENT11 = '0'
	   AND SEGMENT12 = '0';
	EXCEPTION
	WHEN NO_DATA_FOUND THEN
        Dka_Tools_Pkg.put_log_message(
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' - ' ||
                          'Création de la clé comptable');
	

        dka_tools_pkg.get_code_combination_id(
			pv_segment1 => '0001',
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => '452000',
			pv_segment4 => '25080',
			pv_segment5 => pn_name_org,
			pv_segment6 => '0',
			pv_segment7 => '0',
			pv_segment8 => '0',
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_asset_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
			);	
	END;	
   -- Gestion de la séquence bank_account_id	
	SELECT ce_bank_accounts_s.nextval
	INTO vn_num_sequence
	FROM dual;
	
	-- Création du compte bancaire interne
	INSERT INTO ce_bank_accounts
	(
		bank_account_id,
		bank_account_name,
		last_update_date,
		last_updated_by,
		last_update_login,
		creation_date,
		created_by,
		bank_account_num,
		bank_branch_id,
		bank_id,
		currency_code,
		account_owner_party_id,
		account_owner_org_id,
		account_classification,
		ap_use_allowed_flag,
		ar_use_allowed_flag,
		multi_currency_allowed_flag,
		asset_code_combination_id,
		pooled_flag,
		receipt_multi_currency_flag,
		zero_amount_allowed,
		payment_multi_currency_flag,
		autorecon_ap_matching_order,
		autorecon_ap_matching_order2,
		stmt_line_float_handling_flag,
		autorecon_ar_matching_order,
		recon_for_bank_xrate_date_type,
		Recon_oi_matching_code,
		object_version_number,
		masked_account_num,
		ap_amount_tolerance,
		ar_amount_tolerance,
		ap_percent_tolerance,
		ar_percent_tolerance,
		recon_oi_amount_tolerance,
		recon_oi_percent_tolerance,
		ce_amount_tolerance,
		ce_percent_tolerance,
		pay_use_allowed_flag,
		netting_acct_flag,
		PAY_AMOUNT_TOLERANCE,
		RECON_ENABLE_OI_FLAG, -- SELO
		BANK_ACCOUNT_NUM_ELECTRONIC -- SELO
	)
	
	VALUES
	(
		vn_num_sequence,
		'0001_'||SUBSTR(PN_NAME_ORG,1,3)||'_452000_POUR_C_DE_'||PN_NAME_ORG,
		 SYSDATE,
		 FND_PROFILE.VALUE('USER_ID'),	 
		 FND_PROFILE.VALUE('LOGIN_ID'),
		 SYSDATE,
		 FND_PROFILE.VALUE('USER_ID'),
		 '99999999999',
		 vn_bank_branch_id,
		 vn_bank_id,
		 vv_currency_code,
		 vn_account_owner_party_id,
		 vn_account_owner_org_id,
		 'INTERNAL',
		 'Y',
		 'Y',
		 'Y',
		 vn_asset_code_combination_id,
		 'N',
		 'Y',
		 'Y',
		 'Y',
		 'T',--opération
		 'B',--Lot
		 'I',--ignorer
		 'T',--opération
		 'SLD',--date de la ligne de relevé
		 'T',--numéro de mouvement
		 1,
		 '99999999999',
		 0,
		 0,
		 0,
		 0,
		 0,
		 0,
		 0,
		 0,
		 'N',
		 'N',
		 0,  -- SELO		 
		 'N',-- SELO
		 '99999999999' -- SELO
	)
	;
       			 
	-- Utilisation de l'API CE_BANK_PUB.CREATE_BANK_ACCT_USE
	-- pour la création des utilisations du compte bancaire
	select organization_id 
	into v_org_id
	from hr_operating_units
	where name = substr(pn_name_org,1,3)||'0001';
	-- Paramètres d'entrée de l'API

	p_acct_use_rec.asset_code_combination_id := vn_asset_code_combination_id;
	p_acct_use_rec.ap_asset_ccid := vn_asset_code_combination_id;
	p_acct_use_rec.ar_asset_ccid := vn_asset_code_combination_id;
	p_acct_use_rec.edisc_receivables_trx_id := get_receivables_trx_id(v_org_id, 'EDISC');
	p_acct_use_rec.unedisc_receivables_trx_id := get_receivables_trx_id(v_org_id, 'UNEDISC');
	p_acct_use_rec.ap_use_enable_flag := 'Y';
	p_acct_use_rec.ar_use_enable_flag := 'Y';
	p_acct_use_rec.bank_account_id := vn_num_sequence ;
	p_acct_use_rec.org_type   := 'OU';
	p_acct_use_rec.org_id   := v_org_id;
	p_acct_use_rec.authorized_flag            := 'Y';
    p_acct_use_rec.default_account_flag       := 'N';
	
	IF ((p_acct_use_rec.edisc_receivables_trx_id is null ) OR (p_acct_use_rec.unedisc_receivables_trx_id is null)) THEN
	     p_retcode:=2;
		 P_ERRBUF := 'Arrêt du traitement, pas de création de l''affectation du compte bancaire ';
		 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_ERRBUF);
	END IF;
	
	recup_donnees_ccid(pn_name_org => substr(pn_name_org,1,3)||'0001', 
	                  pv_cle_comptable => 'Gains de change réalisés',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		 
		 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Gains de change réalisés. Message: '||P_ERRBUF);			 
		END IF;					  
	--**************************************************
	-- Récupération données Gains de change réalisés
	--**************************************************
	dka_tools_pkg.get_code_combination_id(
			pv_segment1 => '0001',
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => 'A00000000A',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
			 
			 FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Gains de change réalisés. Message: '||P_ERRBUF);	
		END IF;	
	p_acct_use_rec.gain_code_combination_id := vn_code_combination_id ;
	--**************************************************
	-- Recupération données pour Pertes de change réalisés
	--**************************************************
	recup_donnees_ccid(pn_name_org => substr(pn_name_org,1,3)||'0001', 
	                  pv_cle_comptable => 'Pertes de change réalisées',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Pertes de change réalisées. Message: '||P_ERRBUF);				 
		END IF;					  
	dka_tools_pkg.get_code_combination_id(
			pv_segment1 => '0001',
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => 'A00000000A',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Pertes de change réalisées. Message: '||P_ERRBUF);			 
		END IF;	
	p_acct_use_rec.loss_code_combination_id := vn_code_combination_id;
	--*******************************************************
	-- Recupération données pour Encaissements non identifiés
	--********************************************************
	recup_donnees_ccid(pn_name_org => substr(pn_name_org,1,3)||'0001', 
	                  pv_cle_comptable => 'Enc/Rglt non identifiés',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Enc/Rglt non identifiés. Message: '||P_ERRBUF);			 
		END IF;					  
	  dka_tools_pkg.get_code_combination_id(
			pv_segment1 => '0001',
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => '0',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Enc/Rglt non identifiés. Message: '||P_ERRBUF);				 
		END IF;	
	p_acct_use_rec.unidentified_ccid := vn_code_combination_id;
	--*******************************************************
	-- Recupération données pour Encaissements non lettrés
	--********************************************************
	recup_donnees_ccid(pn_name_org => substr(pn_name_org,1,3)||'0001', 
	                  pv_cle_comptable => 'Enc/Rglt non lettrés',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Enc/Rglt non lettrés. Message: '||P_ERRBUF);				 
		END IF;					  
	  dka_tools_pkg.get_code_combination_id(
			pv_segment1 => '0001',
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => '0',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Enc/Rglt non lettrés. Message: '||P_ERRBUF);				 
		END IF;	
	p_acct_use_rec.unapplied_ccid := vn_code_combination_id;
	--*******************************************************
	-- Recupération données pour Encaissements en compte
	--********************************************************
	recup_donnees_ccid(pn_name_org => substr(pn_name_org,1,3)||'0001', 
	                  pv_cle_comptable => 'Enc/Rglt en compte',
					  pv_centre_finance => vv_centre_finance,
					  pv_compte_local =>  vv_compte_local,
					  pv_compte_analytique => vv_compte_analytique,
					  pv_projet_finance => vv_projet_finance,
					  p_errbuf => v_errbuf,
					  p_retcode => v_retcode);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Recupération données pour Enc/Rglt en compte. Message: '||P_ERRBUF);				 
		END IF;					  
	  dka_tools_pkg.get_code_combination_id(
			pv_segment1 => '0001',
			pv_segment2 => substr(pn_name_org,1,3),
			pv_segment3 => vv_compte_local,
			pv_segment4 => vv_compte_analytique,
			pv_segment5 => '0',
			pv_segment6 => vv_centre_finance,
			pv_segment7 => '0',
			pv_segment8 => vv_projet_finance,
			pv_segment9 => '0',
			pv_segment10 => '0',
			pv_segment11 => '0',
			pv_segment12 => '0',
			pn_code_combination_id => vn_code_combination_id, 
			pv_errbuf => v_errbuf ,
			pn_retcode => v_retcode ,
			pv_validation_flag => 'Y'
	);
	-- SELO Debut
		IF v_retcode != 0
		  THEN
			 p_retcode:=v_retcode;
			 P_ERRBUF := v_errbuf;
		     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Création clé comptable pour Enc/Rglt en compte. Message: '||P_ERRBUF);				 
		END IF;	
	p_acct_use_rec.on_account_ccid := vn_code_combination_id;
	--********************************************************
	-- Appel de l'API pour les affectations du compte
	--********************************************************
	IF p_retcode = 0 THEN
		ce_bank_pub.create_bank_acct_use(p_init_msg_list => FND_API.G_TRUE,
										   p_acct_use_rec  => p_acct_use_rec,
										   x_acct_use_id   => l_acct_use_id,
										   x_return_status => l_return_status,
										   x_msg_count     => l_msg_count,
										   x_msg_data      => v_errbuf);
		IF L_RETURN_STATUS <> FND_API.G_RET_STS_SUCCESS OR L_ACCT_USE_ID IS NULL THEN
			FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
							'Erreur lors de la création de l''affectation du compte bancaire '||pn_name_org);
			FND_FILE.PUT_LINE(FND_FILE.OUTPUT,V_ERRBUF); 
			P_RETCODE := 1;	
		ELSE
		   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
				'Création du compte bancaire '||'0001_'||SUBSTR(PN_NAME_ORG,1,3)||'_452000_POUR_C_DE_'||PN_NAME_ORG);
		END IF;
	END IF;
	  EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END creation_comptes_soc;
  
/*
   *************************************************************************
   * PROCEDURE NAME : verif_existence_seq
   *
   * DESCRIPTION
   *  Vérification de l'existence de l'affectation de la séquence
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   ************************************************************************
   */
   PROCEDURE verif_existence_seq(pn_name_org IN VARCHAR2,
                                 pv_method_code IN VARCHAR2,
                                 pn_set_of_books_id IN number,
								 pv_category_code in varchar2,
								 pn_doc_sequence_id in number,
								 pn_application_id in number,
                                 p_errbuf OUT VARCHAR2,
								 p_retcode OUT NUMBER) IS
    vn_count number;
   BEGIN
    p_retcode := 0;
	--- TEST D'EXISTENCE DE L'AFFECTATION DE LA SEQUENCE
	SELECT COUNT(*)
	INTO   vn_count
	FROM FND_DOC_SEQUENCE_ASSIGNMENTS
	WHERE 
	    METHOD_CODE = PV_METHOD_CODE
	AND SET_OF_BOOKS_ID = PN_SET_OF_BOOKS_ID
	AND CATEGORY_CODE = PV_CATEGORY_CODE 
	AND DOC_SEQUENCE_ID = PN_DOC_SEQUENCE_ID
	AND APPLICATION_ID = PN_APPLICATION_ID;

	IF VN_COUNT > 0 THEN
	 P_RETCODE := 1;	 
	 Fnd_File.put_line(Fnd_File.output,'Séquence déjà affectée : ');
	 fnd_File.put_line(Fnd_File.output,'category_code/methode_code');
	 Fnd_File.put_line(Fnd_File.output,PV_CATEGORY_CODE||'/'||PV_METHOD_CODE);
	 
	END IF;
	
	
   EXCEPTION
      WHEN OTHERS THEN
	  p_retcode := 2;
	  Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || 
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
   END verif_existence_seq;
   
 
/*
   *************************************************************************
   * PROCEDURE NAME : affectation_sequence_uo
   *
   * DESCRIPTION
   *  Affectation des sequences de l'uo passée en paramètre
   *  pour le compte de la société 0001
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   ************************************************************************
   */
	PROCEDURE affectation_sequence_uo(pn_name_org  IN VARCHAR2,
				 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
	v_current_program_unit VARCHAR2(30);
	v_errbuf               VARCHAR2(2500);
	v_retcode              NUMBER;
	vn_ccid         gl_code_combinations.code_combination_id%type;
	vn_receivables_trx_id number;
	Vn_set_of_books_id number;
	Vn_count  number;
	vn_application_id number;
	vn_doc_sequence_id number;
	vc_category_code varchar2(240);
	vn_num_sequence number;
	BEGIN
		-- RÉCUPÉRATION SET OF BOOKS ID POUR LE LIVRE DE LA SOCIÉTÉ PASSÉE EN PARAMÈTRE
		SELECT SET_OF_BOOKS_ID
		INTO VN_SET_OF_BOOKS_ID
		FROM GL_SETS_OF_BOOKS
		WHERE SHORT_NAME = SUBSTR(PN_NAME_ORG,4,4);
		-- RÉCUPÉRATION APPLICATION_ID
		SELECT APPLICATION_ID
		INTO VN_APPLICATION_ID
		FROM FND_APPLICATION
		WHERE APPLICATION_SHORT_NAME = 'AR';
		/* Récupération paramètres 
		  pour l'affectation de la séquence manuelle pour la catégorie 
		   YYYY_XXX_ENCAIS_POUR_XXX0001
		*/
		
		-- RÉCUPÉRATION CATÉGORIE DE CODE
		BEGIN 
			SELECT CODE 
			INTO VC_CATEGORY_CODE
			FROM FND_DOC_SEQUENCE_CATEGORIES
			WHERE NAME = SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)||'0001';
          EXCEPTION
  
		WHEN OTHERS THEN
		  p_retcode := 2;
		  Dka_Tools_Pkg.put_log_message(
							'Problème de recuperation de la catégorie : '||
							SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)||'0001');
		  Fnd_File.put_line(Fnd_File.Output,
							CHR(10) ||
							'Problème de recuperation de la catégorie : '||
							SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)||'0001'
						 ||
							CHR(10));
		 
	  END;					 
					 
		-- RÉCUPÉRATION DE LA SÉQUENCES
		BEGIN
        SELECT DOC_SEQUENCE_ID
        INTO VN_DOC_SEQUENCE_ID
        FROM FND_DOCUMENT_SEQUENCES
		WHERE NAME = SUBSTR(PN_NAME_ORG,4,4)||'_AJUSTEMENT';
		Exception
		WHEN OTHERS THEN
		  p_retcode := 2;
		  Dka_Tools_Pkg.put_log_message(
							'Problème de recuperation de la séquence : '||
							SUBSTR(PN_NAME_ORG,4,4)||'_AJUSTEMENT'
		       ||pn_name_org);
		  Fnd_File.put_line(Fnd_File.Output,
							CHR(10) ||
							'Problème de recuperation de la séquence : '||
							SUBSTR(PN_NAME_ORG,4,4)||'_AJUSTEMENT'
						 ||
							CHR(10));
		 
	  END;	
		--VERIFICATION EXISTENCE AFECTATION DE SEQUENCE
		VERIF_EXISTENCE_SEQ(
		    pn_name_org => pn_name_org,
			pv_method_code => 'M',
			pn_set_of_books_id =>  VN_SET_OF_BOOKS_ID,
			pv_category_code => VC_CATEGORY_CODE,
			pn_doc_sequence_id => VN_DOC_SEQUENCE_ID,
			pn_application_id => VN_APPLICATION_ID,
			p_errbuf => v_errbuf,
			p_retcode => v_retcode
		);
	
		IF V_RETCODE = 0 THEN
			SELECT FND_DOC_SEQUENCE_ASSIGNMENTS_S.NEXTVAL
			INTO VN_NUM_SEQUENCE
			FROM DUAL;
			
			/* Affectation de la séquence manuelle pour la catégorie 
			   YYYY_XXX_ENCAIS_POUR_XXX0001
			*/
			INSERT INTO FND_DOC_SEQUENCE_ASSIGNMENTS
			(DOC_SEQUENCE_ASSIGNMENT_ID,
			 METHOD_CODE,
			 START_DATE,
			 SET_OF_BOOKS_ID,
			 CATEGORY_CODE,
			 DOC_SEQUENCE_ID,
			 APPLICATION_ID,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 LAST_UPDATE_LOGIN)
			 VALUES
			 (vn_num_sequence,
			 'M',
			 TO_DATE('30/12/2016','DD/MM/YYYY'),
			 VN_SET_OF_BOOKS_ID,
			 VC_CATEGORY_CODE,
			 VN_DOC_SEQUENCE_ID,
			 VN_APPLICATION_ID,
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID')
			 )
			 ;
			 Fnd_File.put_line(Fnd_File.output,'Affectation séquence manuelle : ');
			 Fnd_File.put_line(Fnd_File.output,SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)||'0001');
					 
		
		ELSIF V_RETCODE = 1 THEN
		  P_RETCODE := 1;
		END IF;
		--VERIFICATION EXISTENCE AFFECTATION DE SEQUENCE
		VERIF_EXISTENCE_SEQ(
			pn_name_org => pn_name_org,
			pv_method_code => 'A',
			pn_set_of_books_id =>  VN_SET_OF_BOOKS_ID,
			pv_category_code => VC_CATEGORY_CODE,
			pn_doc_sequence_id => VN_DOC_SEQUENCE_ID,
			pn_application_id => VN_APPLICATION_ID,
			p_errbuf => v_errbuf,
			p_retcode => v_retcode
		);
	
		IF V_RETCODE = 0 THEN
			SELECT FND_DOC_SEQUENCE_ASSIGNMENTS_S.NEXTVAL
			INTO VN_NUM_SEQUENCE
			FROM DUAL;
			 /* Affectation de la séquence automatique pour la catégorie 
			   YYYY_XXX_ENCAIS_POUR_XXX0001
			*/
			INSERT INTO FND_DOC_SEQUENCE_ASSIGNMENTS
			(DOC_SEQUENCE_ASSIGNMENT_ID,
			METHOD_CODE,
			 START_DATE,
			 SET_OF_BOOKS_ID,
			 CATEGORY_CODE,
			 DOC_SEQUENCE_ID,
			 APPLICATION_ID,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 LAST_UPDATE_LOGIN)
			 VALUES
			 (vn_num_sequence,
			 'A',
			 TO_DATE('30/12/2016','DD/MM/YYYY'),
			 VN_SET_OF_BOOKS_ID,
			 VC_CATEGORY_CODE,
			 VN_DOC_SEQUENCE_ID,
			 VN_APPLICATION_ID,
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID')
			 )
			 ;
			 Fnd_File.put_line(Fnd_File.output,'Affectation séquence automatique : ');
			 Fnd_File.put_line(Fnd_File.output,SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)||'0001');
						 
		ELSIF V_RETCODE = 1 THEN
		  P_RETCODE := 1;
		END IF;
		
		 /* Récupération paramètres 
		  pour l'affectation de la séquence manuelle pour la catégorie 
		   YYYY_XXX_PC_XXX0001_452000
		*/
		-- RÉCUPÉRATION SET OF BOOKS ID POUR LE LIVRE DE LA SOCIÉTÉ PASSÉE EN PARAMÈTRE
		SELECT SET_OF_BOOKS_ID
		INTO VN_SET_OF_BOOKS_ID
		FROM GL_SETS_OF_BOOKS
		WHERE SHORT_NAME = SUBSTR(PN_NAME_ORG,4,4);
		-- RÉCUPÉRATION CATÉGORIE DE CODE
		BEGIN 
			SELECT CODE 
			INTO VC_CATEGORY_CODE
			FROM FND_DOC_SEQUENCE_CATEGORIES
			WHERE NAME = SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_PC_'||SUBSTR(PN_NAME_ORG,1,3)||'0001_452000';
		EXCEPTION
        WHEN OTHERS THEN
		  p_retcode := 2;
		  Dka_Tools_Pkg.put_log_message(
							'Problème de recuperation de la catégorie : '||
							SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
		             ||'_PC_'||SUBSTR(PN_NAME_ORG,1,3)||'0001_452000');
		  Fnd_File.put_line(Fnd_File.Output,
							CHR(10) ||
							'Problème de recuperation de la catégorie : '||
							SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
		             ||'_PC_'||SUBSTR(PN_NAME_ORG,1,3)||'0001_452000'
						 ||
							CHR(10));
		 
	  END;		
		-- RÉCUPÉRATION DE LA SÉQUENCES
        BEGIN
			SELECT DOC_SEQUENCE_ID
			INTO VN_DOC_SEQUENCE_ID
			FROM FND_DOCUMENT_SEQUENCES
			WHERE NAME = SUBSTR(PN_NAME_ORG,4,4)||'_ENCAISSEMENT';
        exception
		WHEN OTHERS THEN
		  p_retcode := 2;
		  Dka_Tools_Pkg.put_log_message(
							'Problème de recuperation de la séquence : '||
							SUBSTR(PN_NAME_ORG,4,4)||'_ENCAISSEMENT'
		       ||pn_name_org);
		  Fnd_File.put_line(Fnd_File.Output,
							CHR(10) ||
							'Problème de recuperation de la séquence : '||
							SUBSTR(PN_NAME_ORG,4,4)||'_ENCAISSEMENT'
						 ||
							CHR(10));
		 
	  END;					
		
		
		--VERIFICATION EXISTENCE AFECTATION DE SEQUENCE
		VERIF_EXISTENCE_SEQ(
			pn_name_org => pn_name_org,
			pv_method_code => 'M',
			pn_set_of_books_id =>  VN_SET_OF_BOOKS_ID,
			pv_category_code => VC_CATEGORY_CODE,
			pn_doc_sequence_id => VN_DOC_SEQUENCE_ID,
			pn_application_id => VN_APPLICATION_ID,
			p_errbuf => v_errbuf,
			p_retcode => v_retcode
		);
		IF V_RETCODE = 0 THEN
		
			SELECT FND_DOC_SEQUENCE_ASSIGNMENTS_S.NEXTVAL
			INTO VN_NUM_SEQUENCE
			FROM DUAL;
			/* Affectation de la séquence manuelle pour la catégorie 
			   YYYY_XXX_PC_XXX0001_452000
			*/
			INSERT INTO FND_DOC_SEQUENCE_ASSIGNMENTS
			(DOC_SEQUENCE_ASSIGNMENT_ID,
			METHOD_CODE,
			 START_DATE,
			 SET_OF_BOOKS_ID,
			 CATEGORY_CODE,
			 DOC_SEQUENCE_ID,
			 APPLICATION_ID,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 LAST_UPDATE_LOGIN)
			 VALUES
			 (vn_num_sequence,
			 'M',
			 TO_DATE('30/12/2016','DD/MM/YYYY'),
			 VN_SET_OF_BOOKS_ID,
			 VC_CATEGORY_CODE,
			 VN_DOC_SEQUENCE_ID,
			 VN_APPLICATION_ID,
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID')
			 )
			 ;
			 Fnd_File.put_line(Fnd_File.output,'Affectation séquence manuelle : ');
			 Fnd_File.put_line(Fnd_File.output,SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_PC_'||SUBSTR(PN_NAME_ORG,1,3)||'0001_452000');
		ELSIF V_RETCODE = 1 THEN
		  P_RETCODE := 1;
		END IF;
		
		
		VERIF_EXISTENCE_SEQ(
			pn_name_org => pn_name_org,
			pv_method_code => 'A',
			pn_set_of_books_id =>  VN_SET_OF_BOOKS_ID,
			pv_category_code => VC_CATEGORY_CODE,
			pn_doc_sequence_id => VN_DOC_SEQUENCE_ID,
			pn_application_id => VN_APPLICATION_ID,
			p_errbuf => v_errbuf,
			p_retcode => v_retcode
		);
		IF V_RETCODE = 0 THEN
		
			SELECT FND_DOC_SEQUENCE_ASSIGNMENTS_S.NEXTVAL
			INTO VN_NUM_SEQUENCE
			FROM DUAL;
			/* Affectation de la séquence automatique pour la catégorie 
			   YYYY_XXX_PC_XXX0001_452000
			*/
			INSERT INTO FND_DOC_SEQUENCE_ASSIGNMENTS
			(DOC_SEQUENCE_ASSIGNMENT_ID,
			METHOD_CODE,
			 START_DATE,
			 SET_OF_BOOKS_ID,
			 CATEGORY_CODE,
			 DOC_SEQUENCE_ID,
			 APPLICATION_ID,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 LAST_UPDATE_LOGIN)
			 VALUES
			 (vn_num_sequence,
			 'A',
			 TO_DATE('30/12/2016','DD/MM/YYYY'),
			 VN_SET_OF_BOOKS_ID,
			 VC_CATEGORY_CODE,
			 VN_DOC_SEQUENCE_ID,
			 VN_APPLICATION_ID,
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID')
			 )
			 ;
			 Fnd_File.put_line(Fnd_File.output,'Affectation séquence automatique : ');
			 Fnd_File.put_line(Fnd_File.output,SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_PC_'||SUBSTR(PN_NAME_ORG,1,3)||'0001_452000');
		 ELSIF V_RETCODE = 1 THEN
		  P_RETCODE := 1;
		END IF;
  	  EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
	      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Les séquences n''ont pas été affectées' ||
                        CHR(10));					
      p_errbuf := SQLERRM;
  END affectation_sequence_uo;
  
  /*
   *************************************************************************
   * PROCEDURE NAME : affectation_sequence_soc
   *
   * DESCRIPTION
   *  Affectation des sequences de la société 0001 pour
   * le compte de la société passée en paramètre
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   ************************************************************************
   */
	PROCEDURE affectation_sequence_soc(pn_name_org  IN VARCHAR2,
	             pn_org_id_soc IN NUMBER,
				 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
	v_current_program_unit VARCHAR2(30);
	v_errbuf               VARCHAR2(2500);
	v_retcode              NUMBER;
	vn_ccid         gl_code_combinations.code_combination_id%type;
	vn_receivables_trx_id number;
	Vn_set_of_books_id number;
	Vn_count  number;
	vn_application_id number;
	vn_doc_sequence_id number;
	vc_category_code varchar2(240);
	vn_num_sequence number;
	BEGIN
		-- RÉCUPÉRATION SET OF BOOKS ID POUR LE LIVRE DE LA SOCIÉTÉ PASSÉE EN PARAMÈTRE
		SELECT SET_OF_BOOKS_ID
		INTO VN_SET_OF_BOOKS_ID
		FROM GL_SETS_OF_BOOKS
		WHERE SHORT_NAME = '0001';
		-- RÉCUPÉRATION APPLICATION_ID
		SELECT APPLICATION_ID
		INTO VN_APPLICATION_ID
		FROM FND_APPLICATION
		WHERE APPLICATION_SHORT_NAME = 'AR';
		/* Récupération paramètres 
		  pour l'affectation de la séquence manuelle pour la catégorie 
		   0001_XXX_ENCAIS_POUR_XXXYYYY
		*/
		
		-- RÉCUPÉRATION CATÉGORIE DE CODE
		BEGIN
		SELECT CODE 
		INTO VC_CATEGORY_CODE
		FROM FND_DOC_SEQUENCE_CATEGORIES
		WHERE NAME = '0001_'||substr(pn_name_org,1,3)||'_ENCAIS_POUR_'
		       ||pn_name_org;
        exception
		WHEN OTHERS THEN
		  p_retcode := 2;
		  Dka_Tools_Pkg.put_log_message(
							'Problème de recuperation du catégorie : '||
							'0001_'||substr(pn_name_org,1,3)||'_ENCAIS_POUR_'
		       ||pn_name_org);
		  Fnd_File.put_line(Fnd_File.Output,
							CHR(10) ||
							'Problème de recuperation du catégorie : '||
							'0001_'||substr(pn_name_org,1,3)||'_ENCAIS_POUR_'
							||pn_name_org
						 ||
							CHR(10));
		 
	  END;						   
			   
			   
		-- RÉCUPÉRATION DE LA SÉQUENCES
		BEGIN 
			SELECT DOC_SEQUENCE_ID
			INTO VN_DOC_SEQUENCE_ID
			FROM FND_DOCUMENT_SEQUENCES
			WHERE NAME = '0001_AJUSTEMENT';
        Exception
		WHEN OTHERS THEN
		  p_retcode := 2;
		  Dka_Tools_Pkg.put_log_message(
							'Problème de recuperation de la séquence : '||
							'0001_AJUSTEMENT'
		       ||pn_name_org);
		  Fnd_File.put_line(Fnd_File.Output,
							CHR(10) ||
							'Problème de recuperation de la séquence : '||
							'0001_AJUSTEMENT'
						 ||
							CHR(10));
		 
	  END;			
		
		VERIF_EXISTENCE_SEQ(
			pn_name_org => pn_name_org,
			pv_method_code => 'M',
			pn_set_of_books_id =>  VN_SET_OF_BOOKS_ID,
			pv_category_code => VC_CATEGORY_CODE,
			pn_doc_sequence_id => VN_DOC_SEQUENCE_ID,
			pn_application_id => VN_APPLICATION_ID,
			p_errbuf => v_errbuf,
			p_retcode => v_retcode
		);
		/* Affectation de la séquence manuelle pour la catégorie 
		   YYYY_XXX_ENCAIS_POUR_XXX0001
		*/
		if v_retcode = 0 then
		    SELECT FND_DOC_SEQUENCE_ASSIGNMENTS_S.NEXTVAL
			INTO VN_NUM_SEQUENCE
			FROM DUAL;
			
			INSERT INTO FND_DOC_SEQUENCE_ASSIGNMENTS
			(DOC_SEQUENCE_ASSIGNMENT_ID,
			METHOD_CODE,
			 START_DATE,
			 SET_OF_BOOKS_ID,
			 CATEGORY_CODE,
			 DOC_SEQUENCE_ID,
			 APPLICATION_ID,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 LAST_UPDATE_LOGIN)
			 VALUES
			 (VN_NUM_SEQUENCE,
			 'M',
			 TO_DATE('30/12/2016','DD/MM/YYYY'),
			 VN_SET_OF_BOOKS_ID,
			 VC_CATEGORY_CODE,
			 VN_DOC_SEQUENCE_ID,
			 VN_APPLICATION_ID,
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID')
			 )
			 ;
			 Fnd_File.put_line(Fnd_File.output,'Affectation séquence manuelle : ');
			 Fnd_File.put_line(Fnd_File.output,'0001_'||substr(pn_name_org,1,3)||'_ENCAIS_POUR_'
				   ||pn_name_org);
		ELSIF v_retcode = 1 THEN
			p_retcode := 1;
		END IF;
		
		 /* Affectation de la séquence automatique pour la catégorie 
		   YYYY_XXX_ENCAIS_POUR_XXX0001
		*/
		VERIF_EXISTENCE_SEQ(
			pn_name_org => pn_name_org,
			pv_method_code => 'A',
			pn_set_of_books_id =>  VN_SET_OF_BOOKS_ID,
			pv_category_code => VC_CATEGORY_CODE,
			pn_doc_sequence_id => VN_DOC_SEQUENCE_ID,
			pn_application_id => VN_APPLICATION_ID,
			p_errbuf => v_errbuf,
			p_retcode => v_retcode
		);
		if v_retcode = 0 then
		
			SELECT FND_DOC_SEQUENCE_ASSIGNMENTS_S.NEXTVAL
			INTO VN_NUM_SEQUENCE
			FROM DUAL;
			
			INSERT INTO FND_DOC_SEQUENCE_ASSIGNMENTS
			(DOC_SEQUENCE_ASSIGNMENT_ID,
			METHOD_CODE,
			 START_DATE,
			 SET_OF_BOOKS_ID,
			 CATEGORY_CODE,
			 DOC_SEQUENCE_ID,
			 APPLICATION_ID,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 LAST_UPDATE_LOGIN)
			 VALUES
			 (VN_NUM_SEQUENCE,
			 'A',
			 TO_DATE('30/12/2016','DD/MM/YYYY'),
			 VN_SET_OF_BOOKS_ID,
			 VC_CATEGORY_CODE,
			 VN_DOC_SEQUENCE_ID,
			 VN_APPLICATION_ID,
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID')
			 )
			 ;
			 Fnd_File.put_line(Fnd_File.output,'Affectation séquence automatique : ');
			 Fnd_File.put_line(Fnd_File.output,'0001'||'_'||substr(pn_name_org,1,3)||'_ENCAIS_POUR_'
				   ||pn_name_org);
		 /* Récupération paramètres 
		  pour l'affectation de la séquence manuelle pour la catégorie 
		   0001_XXX_PC_XXXYYYY_452000
		*/
        ELSIF v_retcode = 1 THEN
			p_retcode := 1;
		END IF;
		
		
		-- RÉCUPÉRATION CATÉGORIE DE CODE
		BEGIN 
		SELECT CODE 
		INTO VC_CATEGORY_CODE
		FROM FND_DOC_SEQUENCE_CATEGORIES
		WHERE NAME = '0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
		             ||'_PC_'||PN_NAME_ORG||'_452000';
				EXCEPTION
        WHEN OTHERS THEN
		  p_retcode := 2;
		  Dka_Tools_Pkg.put_log_message(
							'Problème de recuperation de la catégorie : '||
							'0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
		             ||'_PC_'||PN_NAME_ORG||'_452000');
		  Fnd_File.put_line(Fnd_File.Output,
							CHR(10) ||
							'Problème de recuperation de la catégorie : '||
							'0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
		             ||'_PC_'||PN_NAME_ORG||'_452000'
						 ||
							CHR(10));
		 
	  END;	
		-- RÉCUPÉRATION DE LA SÉQUENCE
        BEGIN 
			SELECT DOC_SEQUENCE_ID
			INTO VN_DOC_SEQUENCE_ID
			FROM FND_DOCUMENT_SEQUENCES
			WHERE NAME = '0001_ENCAISSEMENT';
		Exception 
		WHEN OTHERS THEN
		  p_retcode := 2;
		  Dka_Tools_Pkg.put_log_message(
							'Problème de recuperation de la séquence : '||
							'0001_ENCAISSEMENT'
		       ||pn_name_org);
		  Fnd_File.put_line(Fnd_File.Output,
							CHR(10) ||
							'Problème de recuperation de la séquence : '||
							'0001_ENCAISSEMENT'
						 ||
							CHR(10));
		 
	  END;	
		VERIF_EXISTENCE_SEQ(
			pn_name_org => pn_name_org,
			pv_method_code => 'M',
			pn_set_of_books_id =>  VN_SET_OF_BOOKS_ID,
			pv_category_code => VC_CATEGORY_CODE,
			pn_doc_sequence_id => VN_DOC_SEQUENCE_ID,
			pn_application_id => VN_APPLICATION_ID,
			p_errbuf => v_errbuf,
			p_retcode => v_retcode
		);
		if v_retcode = 0 then
			SELECT FND_DOC_SEQUENCE_ASSIGNMENTS_S.NEXTVAL
			INTO VN_NUM_SEQUENCE
			FROM DUAL;
			/* Affectation de la séquence manuelle pour la catégorie 
			   YYYY_XXX_PC_XXX0001_452000
			*/
			INSERT INTO FND_DOC_SEQUENCE_ASSIGNMENTS
			(DOC_SEQUENCE_ASSIGNMENT_ID,
			METHOD_CODE,
			 START_DATE,
			 SET_OF_BOOKS_ID,
			 CATEGORY_CODE,
			 DOC_SEQUENCE_ID,
			 APPLICATION_ID,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 LAST_UPDATE_LOGIN)
			 VALUES
			 (VN_NUM_SEQUENCE,
			 'M',
			 TO_DATE('30/12/2016','DD/MM/YYYY'),
			 VN_SET_OF_BOOKS_ID,
			 VC_CATEGORY_CODE,
			 VN_DOC_SEQUENCE_ID,
			 VN_APPLICATION_ID,
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID')
			 )
			 ;
			 Fnd_File.put_line(Fnd_File.output,'Affectation séquence manuelle : ');
			 Fnd_File.put_line(Fnd_File.output,SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_PC_'||SUBSTR(PN_NAME_ORG,1,3)||'0001_452000');
		 ELSIF v_retcode = 1 THEN
			p_retcode := 1;
		END IF;

			VERIF_EXISTENCE_SEQ(
			pn_name_org => pn_name_org,
			pv_method_code => 'A',
			pn_set_of_books_id =>  VN_SET_OF_BOOKS_ID,
			pv_category_code => VC_CATEGORY_CODE,
			pn_doc_sequence_id => VN_DOC_SEQUENCE_ID,
			pn_application_id => VN_APPLICATION_ID,
			p_errbuf => v_errbuf,
			p_retcode => v_retcode
		);
		if v_retcode = 0 then
			SELECT FND_DOC_SEQUENCE_ASSIGNMENTS_S.NEXTVAL
			INTO VN_NUM_SEQUENCE
			FROM DUAL;
			 /* Affectation de la séquence automatique pour la catégorie 
			   YYYY_XXX_PC_XXX0001_452000
			*/
			INSERT INTO FND_DOC_SEQUENCE_ASSIGNMENTS
			(DOC_SEQUENCE_ASSIGNMENT_ID,
			 METHOD_CODE,
			 START_DATE,
			 SET_OF_BOOKS_ID,
			 CATEGORY_CODE,
			 DOC_SEQUENCE_ID,
			 APPLICATION_ID,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 LAST_UPDATE_LOGIN)
			 VALUES
			 (VN_NUM_SEQUENCE,
			 'A',
			 TO_DATE('30/12/2016','DD/MM/YYYY'),
			 VN_SET_OF_BOOKS_ID,
			 VC_CATEGORY_CODE,
			 VN_DOC_SEQUENCE_ID,
			 VN_APPLICATION_ID,
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID')
			 )
			 ;
			 Fnd_File.put_line(Fnd_File.output,'Affectation séquence automatique : ');
			 Fnd_File.put_line(Fnd_File.output,'0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
						 ||'_PC_'||PN_NAME_ORG||'_452000');
		ELSIF v_retcode = 1 THEN
			p_retcode := 1;
		END IF;			 
						 
  	  EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      Fnd_File.put_line(Fnd_File.Output, '==> Les séquences n''ont pas été affectées' 	);					
      p_errbuf := SQLERRM;
  END affectation_sequence_soc;
/*
   *************************************************************************
   * PROCEDURE NAME : creation_mode_reglt_uo
   *
   * DESCRIPTION
   *  Création du mode de règlement de l'UO passée en paramètre
   *  pour le compte de la société 0001
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   ************************************************************************
   */
	PROCEDURE creation_mode_reglt_uo(pn_name_org  IN VARCHAR2,
				 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
  
		v_current_program_unit VARCHAR2(30);
		v_errbuf               VARCHAR2(2500);
		v_retcode              NUMBER;
		vn_ccid         gl_code_combinations.code_combination_id%type;
	    vn_receivables_trx_id number;
		Vn_set_of_books_id number;
		Vn_count  number;
		Vn_receipt_class_id number;
		VN_REMIT_BANK_ACCT_USE_ID NUMBER;
		Vn_undisc_id  NUMBER;
		Vn_edisc_id   NUMBER;
		vn_CASH_CCID NUMBER; -- trésorerie
		vn_unapplied_ccid NUMBER; --reglt non lettres
		vn_unidentified_ccid NUMBER; -- reglt non identifiés
		vn_on_account_ccid NUMBER; --reglt en compte
		vn_num_sequence number;
		vn_application_id number;			
	BEGIN
	 -- Récupération du receipt_class_id pour la classe de règlement
	 -- POUR COMPTE
       p_retcode:=0;
	  SELECT RECEIPT_CLASS_ID
	  INTO  VN_RECEIPT_CLASS_ID 
	  FROM  AR_RECEIPT_CLASSES
	  WHERE NAME = 'POUR_COMPTE';

	SELECT APPLICATION_ID
	  INTO VN_APPLICATION_ID
	  FROM FND_APPLICATION
	 WHERE APPLICATION_SHORT_NAME = 'AR';
	  
	  SELECT AR_RECEIPT_METHODS_S.NEXTVAL
	  INTO vn_num_sequence
	  FROM DUAL;
	  BEGIN 
		  -- Insertion du mode de règlement
		  INSERT INTO AR_RECEIPT_METHODS
		  (
			LAST_UPDATE_DATE,
			LAST_UPDATED_BY,
			CREATION_DATE,
			CREATED_BY,
			LAST_UPDATE_LOGIN,
			RECEIPT_CLASS_ID,
			RECEIPT_METHOD_ID,
			NAME,
			PRINTED_NAME,
			START_DATE,
			PAYMENT_TYPE_CODE, -- SELO
			BR_INHERIT_INV_NUM_FLAG -- SELO
		 )
		  VALUES
		  (
			SYSDATE,
			FND_PROFILE.VALUE('USER_ID'),
			SYSDATE,
			FND_PROFILE.VALUE('USER_ID'),
			FND_PROFILE.VALUE('LOGIN_ID'),
			VN_RECEIPT_CLASS_ID,
			vn_num_sequence,
			SUBSTR(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_PC_'||substr(pn_name_org,1,3)||'0001_452000',
			SUBSTR(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_PC_'||substr(pn_name_org,1,3)||'0001_452000',
			TO_DATE('01/01/2000','DD/MM/YYYY'),
			'NONE', --SELO
			'N' --SELO	
					);
					
			-- SELO			
			INSERT INTO FND_DOC_SEQUENCE_CATEGORIES
			(APPLICATION_ID,
			 CODE,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_LOGIN,
			 NAME,
			 TABLE_NAME, 
			 DESCRIPTION, 
			 ZD_EDITION_NAME, 
			 ZD_SYNC 
			 )
			 VALUES
			 (
			 VN_APPLICATION_ID,
			 SUBSTR(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_PC_'||substr(pn_name_org,1,3)||'0001_452000',
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID'),
			 SUBSTR(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_PC_'||substr(pn_name_org,1,3)||'0001_452000',
			 'AR_CASH_RECEIPTS_ALL',
			 SUBSTR(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_PC_'||substr(pn_name_org,1,3)||'0001_452000',
			 'ORA$BASE',
			 'SYNCED'
			 )	;

					
		   --Paramètrage des comptes bancaires	
		   -- Récupération du compte interne
		   BEGIN
			   SELECT BA.BANK_ACCT_USE_ID,
					  UNEDISC_RECEIVABLES_TRX_ID,
					  EDISC_RECEIVABLES_TRX_ID
			   INTO   VN_REMIT_BANK_ACCT_USE_ID,
					  VN_UNDISC_ID,
					  VN_EDISC_ID
			   FROM ce_bank_acct_uses  ba,
						ce_bank_accounts   cba,
						ce_bank_branches_v bb
				  WHERE bb.bank_name like '%'
					AND bb.bank_branch_name like '%'
					AND bb.bank_institution_type = 'BANK'
					AND bb.branch_party_id = cba.bank_branch_id
					AND cba.bank_account_id = ba.bank_account_id
					AND cba.account_classification = 'INTERNAL'
					AND cba.bank_account_name = substr(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||substr(pn_name_org,1,3)||'0001'
					;
			Exception
			when others then
			    p_retcode := 2;
				fnd_file.put_line(Fnd_file.output,'Erreur lors de la récupération du compte interne : ' || substr(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||substr(pn_name_org,1,3)||'0001' );
			END;
		   --récupération des ccid 
		   -- trèsorerie
		   SELECT code_combination_id
		   INTO vn_CASH_CCID
		   FROM gl_code_combinations
		   WHERE SEGMENT1 = substr(pn_name_org,4,4)
			   AND  SEGMENT2 = substr(pn_name_org,1,3)
			   AND SEGMENT3 = '452000'
			   AND SEGMENT4 = '25080'
			   AND SEGMENT5 = substr(pn_name_org,1,3)||'0001'
			   AND SEGMENT6 = '0'
			   AND SEGMENT7 = '0'
			   AND SEGMENT8 = '0'
			   AND SEGMENT9 = '0'
			   AND SEGMENT10 = '0'
			   AND SEGMENT11 = '0'
			   AND SEGMENT12 = '0';
		   -- règlements non lettrés
		   SELECT code_combination_id
		   INTO vn_unapplied_ccid
		   FROM gl_code_combinations
		   WHERE SEGMENT1 = substr(pn_name_org,4,4)
			   AND  SEGMENT2 = substr(pn_name_org,1,3)
			   AND SEGMENT3 = '411100'
			   AND SEGMENT4 = '14100'
			   AND SEGMENT5 = '0'
			   AND SEGMENT6 = '0'
			   AND SEGMENT7 = '0'
			   AND SEGMENT8 = '0'
			   AND SEGMENT9 = '0'
			   AND SEGMENT10 = '0'
			   AND SEGMENT11 = '0'
			   AND SEGMENT12 = '0';
		   -- règlements non identifiés
		   SELECT code_combination_id
		   INTO vn_unidentified_ccid
		   FROM gl_code_combinations
		   WHERE SEGMENT1 = substr(pn_name_org,4,4)
			   AND  SEGMENT2 = substr(pn_name_org,1,3)
			   AND SEGMENT3 = '471008'
			   AND SEGMENT4 = '14300'
			   AND SEGMENT5 = '0'
			   AND SEGMENT6 = '0'
			   AND SEGMENT7 = '0'
			   AND SEGMENT8 = '0'
			   AND SEGMENT9 = '0'
			   AND SEGMENT10 = '0'
			   AND SEGMENT11 = '0'
			   AND SEGMENT12 = '0';
		   --règlements en compte
		   SELECT code_combination_id
		   INTO vn_on_account_ccid
		   FROM gl_code_combinations
		   WHERE SEGMENT1 = substr(pn_name_org,4,4)
			   AND  SEGMENT2 = substr(pn_name_org,1,3)
			   AND SEGMENT3 = '419100'
			   AND SEGMENT4 = '25020'
			   AND SEGMENT5 = '0'
			   AND SEGMENT6 = '0'
			   AND SEGMENT7 = '0'
			   AND SEGMENT8 = '0'
			   AND SEGMENT9 = '0'
			   AND SEGMENT10 = '0'
			   AND SEGMENT11 = '0'
			   AND SEGMENT12 = '0';
		 
		 -- SELO
		  IF (((VN_UNDISC_ID is null) or ( VN_EDISC_ID is null)) and p_retcode <> 2) then
				p_retcode := 1;
				fnd_file.put_line(Fnd_file.output,'Les types d''évènements ESCOMPTE DUS et/ou ESCOMPTES NON DUS ne sont pas paramétrés pour l''UO : ' || pn_name_org );
				
		  END IF;
		  
		  INSERT INTO AR_RECEIPT_METHOD_ACCOUNTS_ALL
		  (
		    RECEIPT_METHOD_ID,
			ORG_ID,
			START_DATE,
			LAST_UPDATE_DATE,
			LAST_UPDATED_BY,
			CREATION_DATE,
			CREATED_BY,
			LAST_UPDATE_LOGIN,
			REMIT_BANK_ACCT_USE_ID,
			PRIMARY_FLAG,
			UNEDISC_RECEIVABLES_TRX_ID,-- escomptes non dus
			EDISC_RECEIVABLES_TRX_ID,-- escomptes dus
			CASH_CCID, -- trésorerie
			UNAPPLIED_CCID, --REGLT NON LETTRES
			UNIDENTIFIED_CCID, -- REGLT NON IDENTIFIÉS
			ON_ACCOUNT_CCID, -- reglt en compte
			OVERRIDE_REMIT_ACCOUNT_FLAG -- SELO
			)
			VALUES
			(
			VN_NUM_SEQUENCE,
			G_UNITE_OPE,
			TO_DATE('01/01/2000','DD/MM/YYYY'),
			SYSDATE,
			FND_PROFILE.VALUE('USER_ID'),
			SYSDATE,
			FND_PROFILE.VALUE('USER_ID'),
			FND_PROFILE.VALUE('LOGIN_ID'),
			VN_REMIT_BANK_ACCT_USE_ID,
			'Y',
			VN_UNDISC_ID,
			VN_EDISC_ID,
			VN_CASH_CCID,
			VN_UNAPPLIED_CCID,
			VN_UNIDENTIFIED_CCID,
			VN_ON_ACCOUNT_CCID,
			'N' -- SELO
			);
			Fnd_File.put_line(Fnd_File.output,'Mode de règlement créé : ');
			Fnd_File.put_line(Fnd_File.output,SUBSTR(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_PC_'||substr(pn_name_org,1,3)||'0001_452000');
		  EXCEPTION
			  WHEN DUP_VAL_ON_INDEX THEN
				p_retcode := 1;
				fnd_file.put_line(Fnd_file.output,'Mode de règlement déjà existant : ' ||SUBSTR(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_PC_'||substr(pn_name_org,1,3)||'0001_452000');
		END;
	  EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
            Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) || 'Les modes de règlement '|| substr(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||substr(pn_name_org,1,3)||'0001'  || ' et ' || '0001'||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||pn_name_org || ' n''ont pas été créés')	;				
      p_errbuf := SQLERRM;
  END creation_mode_reglt_uo;
  
/*
   *************************************************************************
   * PROCEDURE NAME : creation_mode_reglt_soc
   *
   * DESCRIPTION
   *  Création du mode de règlement de la société 0001 pour le compte
   *  de la société passée en paramètre
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   * pn_org_id_soc  org_id de la société 0001
   ************************************************************************
   */
	PROCEDURE creation_mode_reglt_soc(pn_name_org  IN VARCHAR2,
				 pn_org_id_soc IN NUMBER,
                 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
  
		v_current_program_unit VARCHAR2(30);
		v_errbuf               VARCHAR2(2500);
		v_retcode              NUMBER;
		vn_ccid         gl_code_combinations.code_combination_id%type;
	    vn_receivables_trx_id number;
		Vn_set_of_books_id number;
		Vn_count number;
		vn_num_sequence number;
		VN_RECEIPT_CLASS_ID number;
		VN_REMIT_BANK_ACCT_USE_ID number;
		Vn_undisc_id  NUMBER;
		Vn_edisc_id   NUMBER;
		vn_CASH_CCID NUMBER; -- trésorerie
		vn_unapplied_ccid NUMBER; --reglt non lettres
		vn_unidentified_ccid NUMBER; -- reglt non identifiés
		vn_on_account_ccid NUMBER; --reglt en compte
		vn_application_id number;			
	BEGIN
	-- Récupération du receipt_class_id pour la classe de règlement
	 -- POUR COMPTE 
      p_retcode:=0;
	  SELECT RECEIPT_CLASS_ID
	  INTO  VN_RECEIPT_CLASS_ID 
	  FROM  AR_RECEIPT_CLASSES
	  WHERE NAME = 'POUR_COMPTE';

	  SELECT APPLICATION_ID
		INTO VN_APPLICATION_ID
	    FROM FND_APPLICATION
	   WHERE APPLICATION_SHORT_NAME = 'AR';
	  
	   SELECT AR_RECEIPT_METHODS_S.NEXTVAL
	  INTO vn_num_sequence
	  FROM DUAL;
	  BEGIN
		  -- Insertion du mode de règlement
		  INSERT INTO AR_RECEIPT_METHODS
		  (
			LAST_UPDATE_DATE,
			LAST_UPDATED_BY,
			CREATION_DATE,
			CREATED_BY,
			LAST_UPDATE_LOGIN,
			RECEIPT_CLASS_ID,
			RECEIPT_METHOD_ID,
			NAME,
			PRINTED_NAME,
			START_DATE,
			PAYMENT_TYPE_CODE, -- SELO
			BR_INHERIT_INV_NUM_FLAG -- SELO
		 )
		  VALUES
		  (
			SYSDATE,
			FND_PROFILE.VALUE('USER_ID'),
			SYSDATE,
			FND_PROFILE.VALUE('USER_ID'),
			FND_PROFILE.VALUE('LOGIN_ID'),
			VN_RECEIPT_CLASS_ID,
			vn_num_sequence,
			'0001'||'_'||substr(pn_name_org,1,3)||'_PC_'||pn_name_org||'_452000',
			'0001'||'_'||substr(pn_name_org,1,3)||'_PC_'||pn_name_org||'_452000',
			TO_DATE('01/01/2000','DD/MM/YYYY'),
			'NONE', --SELO
			'N' --SELO
		  );
		  
		  -- SELO			
		  INSERT INTO FND_DOC_SEQUENCE_CATEGORIES
			(APPLICATION_ID,
			 CODE,
			 LAST_UPDATE_DATE,
			 LAST_UPDATED_BY,
			 CREATION_DATE,
			 CREATED_BY,
			 LAST_UPDATE_LOGIN,
			 NAME,
			 TABLE_NAME, 
			 DESCRIPTION, 
			 ZD_EDITION_NAME, 
			 ZD_SYNC 
			 )
			 VALUES
			 (
			 VN_APPLICATION_ID,
			 '0001'||'_'||substr(pn_name_org,1,3)||'_PC_'||pn_name_org||'_452000',
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 SYSDATE,
			 FND_PROFILE.VALUE('USER_ID'),
			 FND_PROFILE.VALUE('LOGIN_ID'),
			 '0001'||'_'||substr(pn_name_org,1,3)||'_PC_'||pn_name_org||'_452000',
			 'AR_CASH_RECEIPTS_ALL',
			 '0001'||'_'||substr(pn_name_org,1,3)||'_PC_'||pn_name_org||'_452000',
			 'ORA$BASE',
			 'SYNCED'
			 )	;
		  
		  
		   --Paramètrage des comptes bancaires	
		   -- Récupération du compte interne
		   Begin
		   SELECT BA.BANK_ACCT_USE_ID,
				  UNEDISC_RECEIVABLES_TRX_ID,
				  EDISC_RECEIVABLES_TRX_ID
		   INTO   VN_REMIT_BANK_ACCT_USE_ID,
				  VN_UNDISC_ID,
				  VN_EDISC_ID
		   FROM ce_bank_acct_uses  ba,
					ce_bank_accounts   cba,
					ce_bank_branches_v bb
			  WHERE bb.bank_name like '%'
				AND bb.bank_branch_name like '%'
				AND bb.bank_institution_type = 'BANK'
				AND bb.branch_party_id = cba.bank_branch_id
				AND cba.bank_account_id = ba.bank_account_id
				AND cba.account_classification = 'INTERNAL'
				AND cba.bank_account_name = '0001'||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||pn_name_org
				;
			Exception
			when others then
			    p_retcode := 2;
				
				fnd_file.put_line(Fnd_file.output,'Erreur lors de la récupération du compte interne : ' || '0001'||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||pn_name_org );
			END;
							
			-- SELO
			
			IF (((VN_UNDISC_ID is null) or ( VN_EDISC_ID is null)) and p_retcode <> 2) THEN
				p_retcode := 1;
				fnd_file.put_line(Fnd_file.output,'Les types d''évènements ESCOMPTE DUS et/ou ESCOMPTES NON DUS ne sont pas paramétrés pour l''UO : ' || pn_name_org );
			END IF;
		   --récupération des ccid 
		   -- trèsorerie
		   SELECT code_combination_id
		   INTO vn_CASH_CCID
		   FROM gl_code_combinations
		   WHERE SEGMENT1 = '0001'
			   AND  SEGMENT2 = substr(pn_name_org,1,3)
			   AND SEGMENT3 = '452000'
			   AND SEGMENT4 = '25080'
			   AND SEGMENT5 = pn_name_org
			   AND SEGMENT6 = '0'
			   AND SEGMENT7 = '0'
			   AND SEGMENT8 = '0'
			   AND SEGMENT9 = '0'
			   AND SEGMENT10 = '0'
			   AND SEGMENT11 = '0'
			   AND SEGMENT12 = '0';
		   -- règlements non lettrés
		   SELECT code_combination_id
		   INTO vn_unapplied_ccid
		   FROM gl_code_combinations
		   WHERE SEGMENT1 = '0001'
			   AND  SEGMENT2 = substr(pn_name_org,1,3)
			   AND SEGMENT3 = '411100'
			   AND SEGMENT4 = '14100'
			   AND SEGMENT5 = '0'
			   AND SEGMENT6 = '0'
			   AND SEGMENT7 = '0'
			   AND SEGMENT8 = '0'
			   AND SEGMENT9 = '0'
			   AND SEGMENT10 = '0'
			   AND SEGMENT11 = '0'
			   AND SEGMENT12 = '0';
		   -- règlements non identifiés
		   SELECT code_combination_id
		   INTO vn_unidentified_ccid
		   FROM gl_code_combinations
		   WHERE SEGMENT1 = '0001'
			   AND  SEGMENT2 = substr(pn_name_org,1,3)
			   AND SEGMENT3 = '471008'
			   AND SEGMENT4 = '14300'
			   AND SEGMENT5 = '0'
			   AND SEGMENT6 = '0'
			   AND SEGMENT7 = '0'
			   AND SEGMENT8 = '0'
			   AND SEGMENT9 = '0'
			   AND SEGMENT10 = '0'
			   AND SEGMENT11 = '0'
			   AND SEGMENT12 = '0';
		   --règlements en compte
		   SELECT code_combination_id
		   INTO vn_on_account_ccid
		   FROM gl_code_combinations
		   WHERE SEGMENT1 = '0001'
			   AND  SEGMENT2 = substr(pn_name_org,1,3)
			   AND SEGMENT3 = '419100'
			   AND SEGMENT4 = '25020'
			   AND SEGMENT5 = '0'
			   AND SEGMENT6 = '0'
			   AND SEGMENT7 = '0'
			   AND SEGMENT8 = '0'
			   AND SEGMENT9 = '0'
			   AND SEGMENT10 = '0'
			   AND SEGMENT11 = '0'
			   AND SEGMENT12 = '0';
		 

		  INSERT INTO AR_RECEIPT_METHOD_ACCOUNTS_ALL
		  (
			RECEIPT_METHOD_ID,
			ORG_ID,
			START_DATE,
			LAST_UPDATE_DATE,
			LAST_UPDATED_BY,
			CREATION_DATE,
			CREATED_BY,
			LAST_UPDATE_LOGIN,
			REMIT_BANK_ACCT_USE_ID,
			PRIMARY_FLAG,
			UNEDISC_RECEIVABLES_TRX_ID,-- escomptes non dus
			EDISC_RECEIVABLES_TRX_ID,-- escomptes dus
			CASH_CCID, -- trésorerie
			UNAPPLIED_CCID, --REGLT NON LETTRES
			UNIDENTIFIED_CCID, -- REGLT NON IDENTIFIÉS
			ON_ACCOUNT_CCID, -- reglt en compte
			OVERRIDE_REMIT_ACCOUNT_FLAG -- SELO
			)
			VALUES
			(
			VN_NUM_SEQUENCE,
			PN_ORG_ID_SOC,
			TO_DATE('01/01/2000','DD/MM/YYYY'),
			SYSDATE,
			FND_PROFILE.VALUE('USER_ID'),
			SYSDATE,
			FND_PROFILE.VALUE('USER_ID'),
			FND_PROFILE.VALUE('LOGIN_ID'),
			VN_REMIT_BANK_ACCT_USE_ID,
			'Y',
			VN_UNDISC_ID,
			VN_EDISC_ID,
			VN_CASH_CCID,
			VN_UNAPPLIED_CCID,
			VN_UNIDENTIFIED_CCID,
			VN_ON_ACCOUNT_CCID,
			'N' -- SELO
			);
			Fnd_File.put_line(Fnd_File.output,'Mode de règlement créé : ');
			Fnd_File.put_line(Fnd_File.output,'0001'||'_'||substr(pn_name_org,1,3)||'_PC_'||pn_name_org||'_452000');
			EXCEPTION
			  WHEN DUP_VAL_ON_INDEX THEN
				p_retcode := 1;
				fnd_file.put_line(Fnd_file.output,'Mode de règlement déjà existant : ' ||'0001'||'_'||substr(pn_name_org,1,3)||'_PC_'||pn_name_org||'_452000');
			END;
	EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
		Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) || 'Les modes de règlement '|| substr(pn_name_org,4,4)||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||substr(pn_name_org,1,3)||'0001'  || ' et ' || '0001'||'_'||substr(pn_name_org,1,3)||'_452000_POUR_C_DE_'||pn_name_org || ' n''ont pas été créés');											
      p_errbuf := SQLERRM;
  END creation_mode_reglt_soc;


/*
   *************************************************************************
   * PROCEDURE NAME : creation_types_eve_uo
   *
   * DESCRIPTION
   *  Création des types d'événements pour la societé passée en paramètre
   *  pour le compte de la société 0001 de la même région
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pn_name_org        Org_id de l'UO passée en paramètre
   ************************************************************************
   */
	PROCEDURE creation_types_eve_uo(pn_name_org  IN VARCHAR2,
				 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
  
		v_current_program_unit VARCHAR2(30);
		v_errbuf               VARCHAR2(2500);
		v_retcode              NUMBER;
		vn_ccid         gl_code_combinations.code_combination_id%type;
	    vn_receivables_trx_id number;
		Vn_set_of_books_id number;
		Vn_count  number;
		vn_application_id number;
		
		
		BEGIN
		p_retcode:=0;
	 -- Récupération du set_of_books_id
	   SELECT SET_OF_BOOKS_ID
	   INTO Vn_set_of_books_id
	   FROM hr_operating_units
	   WHERE organization_id = G_UNITE_OPE;
	  
	  SELECT APPLICATION_ID
		  INTO VN_APPLICATION_ID
		  FROM FND_APPLICATION
		 WHERE APPLICATION_SHORT_NAME = 'AR';
	  -- Récupération du ccid
		begin
			SELECT CODE_COMBINATION_ID
			INTO VN_CCID
			FROM GL_CODE_COMBINATIONS
			WHERE SEGMENT1 = SUBSTR(PN_NAME_ORG,4,4)
			AND SEGMENT2 = SUBSTR(PN_NAME_ORG,1,3)
			AND SEGMENT3 = '452000'
			AND SEGMENT4 = '25080'
			AND SEGMENT5 = SUBSTR(PN_NAME_ORG,1,3)||'0001'
			AND SEGMENT6 = '0'
			AND SEGMENT7 = '0'
			AND SEGMENT8 = '0'
			AND SEGMENT9 = '0'
			AND SEGMENT10 = '0'
			AND SEGMENT11 = '0'
			AND SEGMENT12 = '0';
		Exception when others then
			dka_tools_pkg.get_code_combination_id(
													pv_segment1 => SUBSTR(PN_NAME_ORG,4,4),
													pv_segment2 => SUBSTR(PN_NAME_ORG,1,3),
													pv_segment3 => '452000',
													pv_segment4 => '25080',
													pv_segment5 => SUBSTR(PN_NAME_ORG,1,3)||'0001',
													pv_segment6 => '0',
													pv_segment7 => '0',
													pv_segment8 => '0',
													pv_segment9 => '0',
													pv_segment10 => '0',
													pv_segment11 => '0',
													pv_segment12 => '0',
													pn_code_combination_id => vn_ccid, 
													pv_errbuf => v_errbuf ,
													pn_retcode => v_retcode ,
													pv_validation_flag => 'Y'
	);	
		End;
	    -- SELO 
		SELECT AR_RECEIVABLES_TRX_S.nextval
		INTO VN_RECEIVABLES_TRX_ID
		FROM dual;
		/*
		SELECT MAX(RECEIVABLES_TRX_ID) + 1
		INTO VN_RECEIVABLES_TRX_ID
		FROM AR_RECEIVABLES_TRX_ALL;
		*/
		
		SELECT COUNT(*)
		INTO  Vn_count
		FROM AR_RECEIVABLES_TRX_ALL
		WHERE org_id = G_UNITE_OPE
		AND   name = SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
				||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)
				||'0001';
	    
		IF VN_COUNT = 0 THEN
			BEGIN	
		
		INSERT INTO AR_RECEIVABLES_TRX_ALL
				(RECEIVABLES_TRX_ID,
				 ORG_ID,
				 SET_OF_BOOKS_ID,
				 NAME,
				 DESCRIPTION,
				 TYPE,
				 STATUS, 
				 LAST_UPDATE_DATE,
				 LAST_UPDATED_BY,
				 CREATION_DATE,
				 CREATED_BY,
				 LAST_UPDATE_LOGIN,
				 GL_ACCOUNT_SOURCE,
				 TAX_CODE_SOURCE,
				 CODE_COMBINATION_ID,
				 ACCOUNTING_AFFECT_FLAG --SELO 
				 )
			 VALUES
			   (VN_RECEIVABLES_TRX_ID,
				G_UNITE_OPE,
				Vn_set_of_books_id,
				SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)
					||'0001',
				SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAISSEMENT_P_COMPTE_'||SUBSTR(PN_NAME_ORG,1,3)
					||'0001',
				'MISCCASH',
				'A',
				SYSDATE,
				FND_PROFILE.VALUE('USER_ID'),
				SYSDATE,
				FND_PROFILE.VALUE('USER_ID'),
				FND_PROFILE.VALUE('LOGIN_ID'),
				'ACTIVITY_GL_ACCOUNT',
				'NONE',
				VN_CCID,
				'Y'
					);	
          -- SELO
                INSERT INTO FND_DOC_SEQUENCE_CATEGORIES
				(APPLICATION_ID,
				 CODE,
				 LAST_UPDATE_DATE,
				 LAST_UPDATED_BY,
				 CREATION_DATE,
				 CREATED_BY,
				 LAST_UPDATE_LOGIN,
				 NAME,
				 TABLE_NAME, 
				 DESCRIPTION, 
				 ZD_EDITION_NAME, 
				 ZD_SYNC 
				 )
				 VALUES
				 (
				 VN_APPLICATION_ID,
				 SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)
					||'0001',
				 SYSDATE,
				 FND_PROFILE.VALUE('USER_ID'),
				 SYSDATE,
				 FND_PROFILE.VALUE('USER_ID'),
				 FND_PROFILE.VALUE('LOGIN_ID'),
				 SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)
					||'0001',
				 'AR_RECEIVABLES_TRX_ALL',
				 SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)
					||'0001',
				 'ORA$BASE',
				 'SYNCED'
				 );							
		  Fnd_File.put_line(Fnd_File.OUTPUT,'Type d''événement créé :');
		  Fnd_File.put_line(Fnd_File.OUTPUT,'UO/Nom/Description');
		  Fnd_File.put_line(Fnd_File.OUTPUT,PN_NAME_ORG||'/'||
							SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
							||'_ENCAIS_POUR_'||SUBSTR(PN_NAME_ORG,1,3)||'0001'||'/'||
							SUBSTR(PN_NAME_ORG,4,4)||'_'||SUBSTR(PN_NAME_ORG,1,3)
							||'_ENCAISSEMENT_P_COMPTE_'||SUBSTR(PN_NAME_ORG,1,3)||'0001'
							);
					
			EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						-- affichage message enregistrement déjà présent
						p_retcode := 1;
						Fnd_File.put_line(Fnd_File.OUTPUT,'Type d''événement de l''UO '||PN_NAME_ORG||' déjà existant pour le compte 0001');
			END;
		END IF;
		IF VN_COUNT > 0 THEN
			p_retcode := 1;
			Fnd_File.put_line(Fnd_File.OUTPUT,'Type d''événement de l''UO '||PN_NAME_ORG||' déjà existant pour le compte 0001');
		END IF;
	  EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END creation_types_eve_uo;
  
/*
   *************************************************************************
   * PROCEDURE NAME : creation_types_eve_soc
   *
   * DESCRIPTION
   *  Création des types d'événements de la société 0001 pour le compte 
   *  de la société passée en paramètre
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
	PROCEDURE creation_types_eve_soc(pn_name_org  IN VARCHAR2,
				 pn_org_id_soc IN NUMBER,
                 p_errbuf  OUT VARCHAR2,
				 p_retcode OUT NUMBER) IS
  
		v_current_program_unit VARCHAR2(30);
		v_errbuf               VARCHAR2(2500);
		v_retcode              NUMBER;
		vn_ccid         gl_code_combinations.code_combination_id%type;
	    vn_receivables_trx_id number;
		Vn_set_of_books_id number;
		Vn_count number;
		vn_application_id number;			
	BEGIN
	p_retcode:=0;
	    BEGIN 
		-- Récupération du ccid
			SELECT CODE_COMBINATION_ID
			INTO VN_CCID
			FROM GL_CODE_COMBINATIONS
			WHERE SEGMENT1 = '0001'
			AND SEGMENT2 = SUBSTR(PN_NAME_ORG,1,3)
			AND SEGMENT3 = '452000'
			AND SEGMENT4 = '25080'
			AND SEGMENT5 = PN_NAME_ORG
			AND SEGMENT6 = '0'
			AND SEGMENT7 = '0'
			AND SEGMENT8 = '0'
			AND SEGMENT9 = '0'
			AND SEGMENT10 = '0'
			AND SEGMENT11 = '0'
			AND SEGMENT12 = '0';
		Exception when others then
			dka_tools_pkg.get_code_combination_id(
													pv_segment1 => '0001',
													pv_segment2 => SUBSTR(PN_NAME_ORG,1,3),
													pv_segment3 => '452000',
													pv_segment4 => '25080',
													pv_segment5 => PN_NAME_ORG,
													pv_segment6 => '0',
													pv_segment7 => '0',
													pv_segment8 => '0',
													pv_segment9 => '0',
													pv_segment10 => '0',
													pv_segment11 => '0',
													pv_segment12 => '0',
													pn_code_combination_id => vn_ccid, 
													pv_errbuf => v_errbuf ,
													pn_retcode => v_retcode ,
													pv_validation_flag => 'Y'
	);	
		End;
		 -- Récupération du set_of_books_id
	   SELECT SET_OF_BOOKS_ID
	   INTO Vn_set_of_books_id
	   FROM hr_operating_units
	   WHERE organization_id = pn_org_id_soc;
		
		-- SELO 
		SELECT AR_RECEIVABLES_TRX_S.nextval
		  INTO VN_RECEIVABLES_TRX_ID
		  FROM dual;
		/*
		
		
		SELECT MAX(RECEIVABLES_TRX_ID) + 1
		INTO VN_RECEIVABLES_TRX_ID
		FROM AR_RECEIVABLES_TRX_ALL;
		*/
		
		SELECT APPLICATION_ID
		  INTO VN_APPLICATION_ID
		  FROM FND_APPLICATION
		 WHERE APPLICATION_SHORT_NAME = 'AR';
		
		SELECT COUNT(*)
		INTO  Vn_count
		FROM AR_RECEIVABLES_TRX_ALL
		WHERE org_id = pn_org_id_soc
		AND   name = '0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
				||'_ENCAIS_POUR_'||PN_NAME_ORG;
		
		IF vn_count = 0 THEN
			BEGIN	
			 INSERT INTO AR_RECEIVABLES_TRX_ALL
				(RECEIVABLES_TRX_ID,
				 ORG_ID,
				 SET_OF_BOOKS_ID,
				 NAME,
				 DESCRIPTION,
				 TYPE,
				 STATUS,
				 GL_ACCOUNT_SOURCE,
				 TAX_CODE_SOURCE, 
				 LAST_UPDATE_DATE,
				 LAST_UPDATED_BY,
				 CREATION_DATE,
				 CREATED_BY,
				 LAST_UPDATE_LOGIN,
				 CODE_COMBINATION_ID ,
				 ACCOUNTING_AFFECT_FLAG --SELO 
				 )
			 VALUES
			   (VN_RECEIVABLES_TRX_ID,
				pn_org_id_soc,
				Vn_set_of_books_id,
				'0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAIS_POUR_'||PN_NAME_ORG,
				'0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAISSEMENT_P_COMPTE_'||PN_NAME_ORG,
				'MISCCASH',
				'A',
				'ACTIVITY_GL_ACCOUNT',
				'NONE',
				SYSDATE,
				FND_PROFILE.VALUE('USER_ID'),
				SYSDATE,
				FND_PROFILE.VALUE('USER_ID'),
				FND_PROFILE.VALUE('LOGIN_ID'),
				VN_CCID,
				'Y'
					);
					
				-- SELO
                INSERT INTO FND_DOC_SEQUENCE_CATEGORIES
				(APPLICATION_ID,
				 CODE,
				 LAST_UPDATE_DATE,
				 LAST_UPDATED_BY,
				 CREATION_DATE,
				 CREATED_BY,
				 LAST_UPDATE_LOGIN,
				 NAME,
				 TABLE_NAME, 
				 DESCRIPTION, 
				 ZD_EDITION_NAME, 
				 ZD_SYNC 
				 )
				 VALUES
				 (
				 VN_APPLICATION_ID,
				 '0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAIS_POUR_'||PN_NAME_ORG,
				 SYSDATE,
				 FND_PROFILE.VALUE('USER_ID'),
				 SYSDATE,
				 FND_PROFILE.VALUE('USER_ID'),
				 FND_PROFILE.VALUE('LOGIN_ID'),
				 '0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAIS_POUR_'||PN_NAME_ORG,
				 'AR_RECEIVABLES_TRX_ALL',
				 '0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
					||'_ENCAISSEMENT_P_COMPTE_'||PN_NAME_ORG,
				 'ORA$BASE',
				 'SYNCED'
				 );						
			 Fnd_File.put_line(Fnd_File.OUTPUT,'Type d''événement créé :');
			 Fnd_File.put_line(Fnd_File.OUTPUT,'UO/Nom/Description');
			 Fnd_File.put_line(Fnd_File.OUTPUT,SUBSTR(PN_NAME_ORG,1,3)||'0001'||'/'||
							'0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
							 ||'_ENCAIS_POUR_'||PN_NAME_ORG||'/'||
							'0001'||'_'||SUBSTR(PN_NAME_ORG,1,3)
							 ||'_ENCAISSEMENT_P_COMPTE_'||PN_NAME_ORG
							);
			
			EXCEPTION
					WHEN DUP_VAL_ON_INDEX THEN
						-- affichage message enregistrement déjà présent
						p_retcode := 1;
						Fnd_File.put_line(Fnd_File.OUTPUT,'Type d''événement de l''UO 0001 déjà existant pour l''UO '||PN_NAME_ORG);
			END;
		END IF;
		IF vn_count > 0 THEN
		 p_retcode := 1;
		 Fnd_File.put_line(Fnd_File.OUTPUT,'Type d''événement de l''UO 0001 déjà existant pour l''UO '||PN_NAME_ORG);
		END IF;
	EXCEPTION
  
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END creation_types_eve_soc;
  
  /*
   *************************************************************************
   * PROCEDURE NAME : main_sequence
   *
   * DESCRIPTION
   *  Procédure principale d'affectation des séquences pour compte
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pv_unite_ope     Org_id de l'unité opérationnelle
   ************************************************************************
   */

  PROCEDURE main_sequence(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
				 pv_unite_ope IN NUMBER) IS
  
    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
	vn_name_org             VARCHAR2(200);
	vn_org_id_soc          NUMBER;
    Erreur_Programme EXCEPTION;
  
  BEGIN
    
    ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------
  
    v_current_program_unit := 'main';
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
  
    Output_Header;
    Request_parameters;
  
    Dka_Tools_Pkg.put_log_message(
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
	
	-- Récupération du nom de l'UO passée en paramètre
		SELECT name
		INTO vn_name_org
		FROM hr_operating_units
		WHERE organization_id = pv_unite_ope;
	
	 -- Récupération de l'org_id de la société 0001 de la même région que 
	-- la société passée en paramètre
		SELECT organization_id
		INTO   vn_org_id_soc
		FROM   hr_operating_units
		WHERE  name = substr(vn_name_org,1,3)||'0001';
    ----------------------------------------------------------------
    ---    AFFECTATION DE LA SEQUENCE DE L'UNITE OPERATIONNELLE
	---    PASSEE EN PARAMETRE POUR LE COMPTE DE LA SOCIETE 0001
    ----------------------------------------------------------------	
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CREATION MODE DE REGLEMENT DE L''UO '||pv_unite_ope);
	
	affectation_sequence_uo(vn_name_org, v_errbuf, v_retcode);
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
    -- AFFECTATION DE LA SEQUENCE DE LA SOCIETE 0001 POUR LE COMPTE
	-- DE L'UO SELECTIONNEE EN PARAMETRE
    -------------------------------------------------------------------
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CREATION TYPES D''EVENEMENTS DE LA SOCIETE 0001');
    
	affectation_sequence_soc(vn_name_org, vn_org_id_soc, v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
	
   IF v_retcode = 1 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
    END IF;
	
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
  
    Dka_Tools_Pkg.put_log_message( p_errbuf);
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf || CHR(10));
    output_end;
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');
					  
    EXCEPTION
    WHEN Erreur_Programme THEN
	  fnd_concurrent.af_rollback;
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      Dka_Tools_Pkg.put_log_message( p_errbuf);
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf);
      Dka_Tools_Pkg.put_log_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure ' || v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Fin de la procédure ' ||
                        v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
     Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Les séquences n''ont pas été affectées' ||
                        CHR(10));						
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      Fnd_File.put_line(Fnd_File.Output, '==> Les séquences n''ont pas été affectées' 	);
      	  
      p_errbuf := SQLERRM;
  END main_sequence;
  
  /*
   *************************************************************************
   * PROCEDURE NAME : main_reglement
   *
   * DESCRIPTION
   *  Procédure principale de création des classes de et modes de règlements pour compte
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * pv_unite_ope     Org_id de l'unité opérationnelle
   ************************************************************************
   */

  PROCEDURE main_reglement(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
				 pv_unite_ope IN NUMBER) IS
  
    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
	vn_name_org             VARCHAR2(200);
	vn_org_id_soc          NUMBER;
    Erreur_Programme EXCEPTION;
  
  BEGIN
    
    ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------
  
    v_current_program_unit := 'main';
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
  
    Output_Header;
    Request_parameters;
  
    Dka_Tools_Pkg.put_log_message(
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
	
	-- Récupération du nom de l'UO passée en paramètre
		SELECT name
		INTO vn_name_org
		FROM hr_operating_units
		WHERE organization_id = pv_unite_ope;
	
	 -- Récupération de l'org_id de la société 0001 de la même région que 
	-- la société passée en paramètre
		SELECT organization_id
		INTO   vn_org_id_soc
		FROM   hr_operating_units
		WHERE  name = substr(vn_name_org,1,3)||'0001';
    ----------------------------------------------------------------
    ---    CREATION DU MODE DE REGLEMENT DE L'UO PASSEE EN PARAMETRE
    ---    POUR LE COMPTE DE LA SOCIETE 0001
    ----------------------------------------------------------------	
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CREATION MODE DE REGLEMENT DE L''UO '||pv_unite_ope);
	creation_mode_reglt_uo(vn_name_org, v_errbuf, v_retcode);
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
    -- CREATION DU MODE DE REGLEMENT DE LA SOCIETE 0001 POUR LE COMPTE
	-- DE LA SOCIETE PASSEE EN PARAMETRE
    -------------------------------------------------------------------
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CREATION TYPES D''EVENEMENTS DE LA SOCIETE 0001');
  
    creation_mode_reglt_soc(vn_name_org, vn_org_id_soc, v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
	
   IF v_retcode = 1 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
    END IF;
	
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
  
    Dka_Tools_Pkg.put_log_message( p_errbuf);
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf || CHR(10));
    output_end;
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');
					  
    EXCEPTION
    WHEN Erreur_Programme THEN
	  fnd_concurrent.af_rollback;
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      Dka_Tools_Pkg.put_log_message( p_errbuf);
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf);
      Dka_Tools_Pkg.put_log_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure ' || v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Fin de la procédure ' ||
                        v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
	   Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) || 'Les modes de règlement '|| substr(vn_name_org,4,4)||'_'||substr(vn_name_org,1,3)||'_452000_POUR_C_DE_'||substr(vn_name_org,1,3)||'0001'  || ' et ' || '0001'||'_'||substr(vn_name_org,1,3)||'_452000_POUR_C_DE_'||vn_name_org || ' n''ont pas été créés');											
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
	   Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) || 'Les modes de règlement '|| substr(vn_name_org,4,4)||'_'||substr(vn_name_org,1,3)||'_452000_POUR_C_DE_'||substr(vn_name_org,1,3)||'0001'  || ' et ' || '0001'||'_'||substr(vn_name_org,1,3)||'_452000_POUR_C_DE_'||vn_name_org || ' n''ont pas été créés');					
  END main_reglement;
  /*
   *************************************************************************
   * PROCEDURE NAME : main_comptes
   *
   * DESCRIPTION
   *  Procédure principale de création des comptes bancaires internes POUR COMPTE
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

  PROCEDURE main_comptes(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
				 pv_unite_ope IN NUMBER) IS
  
    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
	vn_name_org             VARCHAR2(200);
	vn_org_id_soc          NUMBER;
	vn_legal_entity_id     NUMBER;
	vn_count               NUMBER;
    Erreur_Programme EXCEPTION;
  
  BEGIN
  
   ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------
  
    v_current_program_unit := 'main';
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
  
    Output_Header;
    Request_parameters;
  
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''INITIALISATION');
    g_unite_ope := pv_unite_ope;
    v_errbuf  := NULL;
    v_retcode := 0;
    vn_count := 0;
    Init(v_errbuf, v_retcode);
  
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    
	-- Récupération du nom de l'UO passée en paramètre
		SELECT name
		INTO vn_name_org
		FROM hr_operating_units
		WHERE organization_id = pv_unite_ope;
    -- Récupération de l'org_id de la société 0001 de la même région que 
	-- la société passée en paramètre
		SELECT organization_id
		INTO   vn_org_id_soc
		FROM   hr_operating_units
		WHERE  name = substr(vn_name_org,1,3)||'0001';
    ---------------------------------------------------------
    -- CREATION DES COMPTES BANCAIRES INTERNES DE L'UO PASSEE EN PARAMETRE
	-- POUR LE COMPTE DE LA SOCIETE 0001 DE LA MEME REGION
    ----------------------------------------------------------
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CREATION COMPTES BANCAIRES INTERNES DE L''UO '||pv_unite_ope);
	controle_existence_compte_uo(vn_name_org, vn_count, v_errbuf, v_retcode);
	if vn_count = 0 THEN
		creation_comptes_uo(vn_name_org, v_errbuf, v_retcode);
	end if;
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
  
    IF v_retcode = 1 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
    END IF;
		
   ---------------------------------------------------------
    -- CREATION DES COMPTES BANCAIRES INTERNES DE LA SOCIETE 0001
	-- POUR LE COMPTE DE L'UO PASSEE EN PARAMETRE
    ----------------------------------------------------------
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CREATION COMPTES BANCAIRES INTERNES DE L''UO '||pv_unite_ope);
	  controle_existence_compte_soc(vn_name_org, vn_count, v_errbuf, v_retcode);
	if vn_count = 0 THEN				  
		creation_comptes_soc(vn_name_org, vn_org_id_soc, v_errbuf, v_retcode);
	end if;
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
  
    IF v_retcode = 1 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
    END IF;
	
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
  
    Dka_Tools_Pkg.put_log_message( p_errbuf);
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf || CHR(10));
    output_end;
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');
  
  EXCEPTION
    WHEN Erreur_Programme THEN
	  fnd_concurrent.af_rollback;
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      Dka_Tools_Pkg.put_log_message( p_errbuf);
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf);
      Dka_Tools_Pkg.put_log_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure ' || v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Fin de la procédure ' ||
                        v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Le compte bancaire interne '||substr(vn_name_org,4,4)||'_'||substr(vn_name_org,1,3)||'_452000_POUR_C_DE_'||
	 substr(vn_name_org,1,3)||'0001'||' n''a pas été créé ');
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Le compte bancaire interne '||'0001_'||SUBSTR(vn_name_org,1,3)||'_452000_POUR_C_DE_'||vn_name_org||' n''a pas été créé ');					
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
 Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Le compte bancaire interne '||substr(vn_name_org,4,4)||'_'||substr(vn_name_org,1,3)||'_452000_POUR_C_DE_'||
	 substr(vn_name_org,1,3)||'0001'||' n''a pas été créé ');
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '==> Le compte bancaire interne '||'0001_'||SUBSTR(vn_name_org,1,3)||'_452000_POUR_C_DE_'||vn_name_org||' n''a pas été créé ');										
      p_errbuf := SQLERRM;
  END main_comptes;
  /*
   *************************************************************************
   * PROCEDURE NAME : main_evenement
   *
   * DESCRIPTION
   *  Procédure principale de création des types d'évènements pour compte
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

  PROCEDURE main_evenement(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
				 pv_unite_ope IN NUMBER) IS
  
    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
	vn_name_org             VARCHAR2(200);
	vn_org_id_soc          NUMBER;
	vn_legal_entity_id     NUMBER;
    Erreur_Programme EXCEPTION;
  
  BEGIN
  
    ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------
  
    v_current_program_unit := 'main';
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
  
    Output_Header;
    Request_parameters;
     
    Dka_Tools_Pkg.put_log_message(
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

    
	-- Récupération du nom de l'UO passée en paramètre
	     
		SELECT name
		INTO vn_name_org
		FROM hr_operating_units
		WHERE organization_id = pv_unite_ope;
    -- Récupération de l'org_id de la société 0001 de la même région que 
	     
	-- la société passée en paramètre
		SELECT organization_id
		INTO   vn_org_id_soc
		FROM   hr_operating_units
		WHERE  name = substr(vn_name_org,1,3)||'0001';
	---------------------------------------------------------
    -- CREATION DES TYPES D'EVENEMENTS DE L'UO PASSEE EN PARAMETRE
	-- POUR LE COMPTE DE LA SOCIETE 0001 DE LA MEME REGION
    ----------------------------------------------------------
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CREATION TYPES D''EVENEMENTS DE L''UO '||pv_unite_ope);

 
    creation_types_eve_uo(vn_name_org, v_errbuf, v_retcode);


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
    -- CREATION DES TYPES D'EVENEMENTS DE LA SOCIETE 0001 POUR LE COMPTE
	-- DE LA SOCIETE PASSEE EN PARAMETRE
    -------------------------------------------------------------------
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'CREATION TYPES D''EVENEMENTS DE LA SOCIETE 0001');
 		     
    creation_types_eve_soc(vn_name_org, vn_org_id_soc, v_errbuf, v_retcode);
	
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
  IF v_retcode = 1 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
    END IF;
		
  
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
  
    Dka_Tools_Pkg.put_log_message( p_errbuf);
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf || CHR(10));
    output_end;
    Dka_Tools_Pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');
  
  EXCEPTION
    WHEN Erreur_Programme THEN
	  fnd_concurrent.af_rollback;
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      Dka_Tools_Pkg.put_log_message( p_errbuf);
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf);
      Dka_Tools_Pkg.put_log_message(
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
      Dka_Tools_Pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_SARAUTCRE_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));

      p_errbuf := SQLERRM;
  END main_evenement;

END DKA_SARAUTCRE_PKG;



/
SHOW ERRORS
EXIT
