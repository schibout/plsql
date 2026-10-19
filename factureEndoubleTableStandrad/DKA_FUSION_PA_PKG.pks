SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_SARAUTENC_PKG IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_SARAUTENC_PKG.pkb  V1.0
  --
  -- AUTEUR
  --    Capgemini
  --
  -- DESCRIPTION
  --    Création du package du traitement de création des encaissements clients pour le compte de
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
  -- V1.0    09/08/2018     OBE Creation
  -- V1.1    21/01/2019     SNI artf2863631 exclure les encaissements au statut « annulé ». 
  -- V1.2    08/07/2019     AAM artf07286081 modifier la sortie générée par le traitement pour 
  --                        changer l'UO affiché. Il faut afficher l'UO du règlement dans AR.
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
					  
    SELECT fr.responsibility_id, fr.application_id
    INTO vn_responsibility_id, vn_application_id
    FROM fnd_responsibility fr
    WHERE responsibility_key = 'TOUT_AR_ADMINISTRATEUR';
    
    Fnd_Global.apps_initialize(Fnd_Global.user_id,
                               vn_responsibility_id,
                               vn_application_id);
                               
    mo_global.init('AR');					  
					  
					  
  
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
   * PROCEDURE NAME : print_errors
   *
   * DESCRIPTION
   *  Procédure pour écrire les anomalies du programme
   *
   * PARAMETERS
   * ==========
   * NAME               DESCRIPTION
  .* -----------------  ------------------------------------------------------
   *
   ************************************************************************
   */

  PROCEDURE print_errors IS
  
    CURSOR cur_success_messages IS
      SELECT *
        FROM DKA_PROGRAM_MESSAGES
       WHERE REQUEST_ID = g_request_id
         AND SOURCE = 'API'
		 AND MESSAGE_TYPE = 'I'
		 ;
  
    CURSOR cur_error_messages IS
      SELECT *
        FROM DKA_PROGRAM_MESSAGES
       WHERE REQUEST_ID = g_request_id
         AND SOURCE = 'API'
		 AND MESSAGE_TYPE = 'E'
		 ;
  
  BEGIN

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,'Etat des encaissements créés et non créés le ' || to_char(sysdate,'DD/MM/YYYY'));
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'Règlements créés : ');					  
	fnd_file.put_line(fnd_file.OUTPUT, '------------------');
    fnd_file.put_line(fnd_file.OUTPUT, 'Numéro du règlement traité    UO         Numéro de règlement créé    Client                         Montant    Mode de règlement');
    fnd_file.put_line(fnd_file.OUTPUT, '--------------------------    -------    ------------------------    ---------------------------    -------    ----------------- ');
  
    FOR msg IN cur_success_messages LOOP
      Fnd_File.put_line(Fnd_File.output,msg.message_text);
    END LOOP;
  
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'Règlements non créés : ');					  
	fnd_file.put_line(fnd_file.OUTPUT, '------------------');
    fnd_file.put_line(fnd_file.OUTPUT, 'Numéro du règlement traité    UO         Numéro de règlement créé    Client                         Montant    Mode de règlement              Motif d''erreur');
    fnd_file.put_line(fnd_file.OUTPUT, '--------------------------    -------    ------------------------    ---------------------------    -------    ---------------------------    ----------------');
  
    FOR msg IN cur_error_messages LOOP
      Fnd_File.put_line(Fnd_File.output,msg.message_text);
    END LOOP;

  
  END print_errors;


  
  


/*
 *************************************************************************
 * PROCEDURE NAME : create_data
 *
 * DESCRIPTION
 *  Procédure de création des données
 *
 * PARAMETERS
 * ==========
 * NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
 * p_errbuf            Retour de message éventuel
 * p_retcode           Statut du traitement en sortie
 ************************************************************************
 */

 PROCEDURE create_data(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
  CURSOR cur_enc_divers IS
    select acr.cash_receipt_id, 
	       acr.amount, 
		   acr.receipt_number, 
		   art.name evenement, 
		   hou2.name uo_name_interco,
		   hou2.organization_id,
		   hou.name uo_name, 
		   gcc.segment5 code_interco, 
		   ac.customer_name, 
		   ac.customer_id,
		   ract.bill_to_site_use_id,
		   ract.customer_trx_id,
		   ract.trx_number,
		   acr.currency_code,
		   acr.attribute5
    from ar_cash_receipts_all acr, 
	     ar_receivables_trx_all art, 
		 ar_customers ac,
		 ra_customer_trx_all ract, 
		 hr_operating_units hou, 
		 hr_operating_units hou2,
		 gl_code_combinations gcc
    where 1=1
    and acr.attribute6 is null
    and acr.attribute5 is not null
    and acr.attribute5 = ract.customer_trx_id
	and ac.customer_id = ract.bill_to_customer_id
    and acr.type = 'MISC'
    and art.receivables_trx_id = acr.receivables_trx_id
    and art.org_id = acr.org_id
    and art.type = 'MISCCASH'
    and art.status = 'A'
	AND acr.status <> 'REV' -- SNIK artf2863631 exclure les encaissements au statut « annulé ». 
    and art.code_combination_id = gcc.code_combination_id
    and hou.organization_id = acr.org_id
	and hou2.name = gcc.segment5
    and exists (select 1 
                from AR_CASH_RECEIPT_HISTORY_ALL
                where cash_receipt_id = acr.cash_receipt_id
                and gl_posted_date is not null
                )
    ;	
  
  e_mode_reglement       EXCEPTION;
  vv_return_status       VARCHAR2(30);
  vv_msg_count           NUMBER;
  vv_msg_data            VARCHAR2(2000);  
  vv_mode_reglement      VARCHAR2(100);
  vn_mode_reglement_id   NUMBER;
  vn_num_reglement       VARCHAR2(30);
  vn_cr_id               NUMBER;
  i                      NUMBER;
  j                      NUMBER;
  
  BEGIN
  
      Dka_Tools_Pkg.put_debug_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début create_data');
	  Dka_Tools_Pkg.put_debug_message('--> Parcours des encaissements divers');

      FOR rec in cur_enc_divers LOOP
	  
	   BEGIN
	  
		-- Récupération du numéro de règlement
		Dka_Tools_Pkg.put_debug_message('Numéro règlement : ' || rec.receipt_number);  
		select to_char('PC' || LPAD(DKA_SARAUTENC_S.nextval,6,'0')) into vn_num_reglement from dual;
		Dka_Tools_Pkg.put_debug_message('Numéro règlement à créer : ' || vn_num_reglement); 

		-- Détermination du mode de règlement
		 
		BEGIN
		   select a.receipt_method_id, a.name
		   into vn_mode_reglement_id, vv_mode_reglement
		   from ar_receipt_methods a, AR_RECEIPT_METHOD_ACCOUNTS_ALL b, GL_CODE_COMBINATIONS c
		   where 1=1
		   and a.receipt_class_id = 1001 
		   and a.name like substr(rec.code_interco,4,4) || '_' || substr(rec.code_interco,1,3) || '%'
		   and a.end_date is null
		   and a.receipt_method_id = b.receipt_method_id
		   and b.cash_ccid = c.code_combination_id
		   and b.end_date is null
		   and b.primary_flag = 'Y'
		   and c.segment5 = rec.uo_name;
		 
		EXCEPTION
		 WHEN OTHERS THEN
		   RAISE e_mode_reglement;
		END;
		
		Dka_Tools_Pkg.put_debug_message('--> Récupération mode de règlement : ' || vv_mode_reglement);
		
		
		-- Appel à l'api standard
		Dka_Tools_Pkg.put_debug_message('--> Appel de l''API standard');
		
		AR_RECEIPT_API_PUB.Create_and_apply (p_api_version                => 1.0,
											 p_init_msg_list              => FND_API.G_TRUE,
											 p_commit                     => FND_API.G_FALSE,
											 p_validation_level           => FND_API.G_VALID_LEVEL_FULL,
											 x_return_status              => vv_return_status,
											 x_msg_count                  => vv_msg_count,
											 x_msg_data                   => vv_msg_data,
											 p_currency_code              => rec.currency_code,
											 p_amount                     => rec.amount,
											 p_receipt_number             => vn_num_reglement,
											 p_customer_id                => rec.customer_id,
											 p_customer_trx_id            => rec.customer_trx_id,
											 p_customer_site_use_id       => rec.bill_to_site_use_id,
											 p_receipt_method_id          => vn_mode_reglement_id,
											 p_org_id                     => rec.organization_id,
											 p_cr_id                      => vn_cr_id,
											 p_amount_applied             => rec.amount,
											 p_apply_date                 => SYSDATE
											);

        IF (vv_return_status = 'S') THEN
          --COMMIT;
		  
		  UPDATE ar_cash_receipts_all
	      SET attribute7       = (SELECT DISTINCT trx_number FROM ra_customer_trx_all
                                  WHERE CUSTOMER_TRX_ID = (SELECT DISTINCT attribute5 FROM AR_CASH_RECEIPTS_all
                                                            WHERE cash_receipt_id = rec.cash_receipt_id ))
	         ,attribute5       = NULL
	         ,last_update_date = SYSDATE
	      WHERE cash_receipt_id = rec.cash_receipt_id; --artf2863631 SNK 04/03/2019
	  
	  
          Dka_Tools_Pkg.put_debug_message( 'SUCCESS');
          Dka_Tools_Pkg.put_debug_message('Return Status   :' || SUBSTR(vv_return_status, 1, 255));
          Dka_Tools_Pkg.put_debug_message( 'Cash receipt Id :' || vn_cr_id);
          Dka_Tools_Pkg.put_debug_message(
                            '---------------------------------------------------------------');
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SARAUTENC',
                                         'API',
                                         'AR_CASH_RECEIPTS_ALL',
                                         NULL,
                                         'CASH_RECEIPT_ID',
                                         to_char(rec.cash_receipt_id),
                                         'I',
                                         RPAD(rec.receipt_number, 26, ' ') || '    ' || RPAD(rec.uo_name, 7, ' ') || '    ' || RPAD(vn_num_reglement, 24, ' ') || '    ' || 
										 RPAD(rec.customer_name, 27, ' ') || '    ' || RPAD(rec.amount, 7, ' ') || '    ' || vv_mode_reglement
										 );  --AAM artf07286081 (rempalcer rec.uo_name_interco par rec.uo_name	)					
        
        ELSE
          --ROLLBACK;
          g_warning := TRUE;
          IF fnd_msg_pub.count_msg > 0 THEN
            FOR j in 1 .. FND_MSG_PUB.count_msg LOOP
              FND_MSG_PUB.get(p_msg_index     => j,
                              p_encoded       => 'F',
                              p_data          => vv_msg_data,
                              p_msg_index_out => i);
              Dka_Tools_Pkg.put_debug_message('Error Receipt ' || vn_num_reglement ||' : ' || j || ':' || vv_msg_data);
                                 
            END LOOP;
          END IF;
          Dka_Tools_Pkg.put_debug_message('---------------------------------------------------------------');
		  
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SARAUTENC',
                                         'API',
                                         'AR_CASH_RECEIPTS_ALL',
                                         NULL,
                                         'CASH_RECEIPT_ID',
                                         to_char(rec.cash_receipt_id),
                                         'E',
                                         RPAD(rec.receipt_number, 26, ' ') || '    ' || RPAD(rec.uo_name, 7, ' ') || '    ' || RPAD(vn_num_reglement, 24, ' ') || '    ' || 
										 RPAD(rec.customer_name, 27, ' ') || '    ' || RPAD(rec.amount, 7, ' ') || '    ' || RPAD(vv_mode_reglement, 27, ' ')
										 || '    ' || vv_msg_data
										 );		--AAM artf07286081 (rempalcer rec.uo_name_interco par rec.uo_name	)	  
        
        END IF;	

      EXCEPTION
	   WHEN e_mode_reglement THEN
	        g_warning := TRUE;
	        Dka_Tools_Pkg.put_debug_message('Erreur : Mode de règlement introuvable ou invalide.');
			vv_mode_reglement := 'INTROUVABLE';
            dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_SARAUTENC',
                                         'API',
                                         'AR_CASH_RECEIPTS_ALL',
                                         NULL,
                                         'CASH_RECEIPT_ID',
                                         to_char(rec.cash_receipt_id),
                                         'E',
                                         RPAD(rec.receipt_number, 26, ' ') || '    ' || RPAD(rec.uo_name, 7, ' ') || '    ' || RPAD(vn_num_reglement, 24, ' ') || '    ' || 
										 RPAD(rec.customer_name, 27, ' ') || '    ' || RPAD(rec.amount, 7, ' ') || '    ' || RPAD(vv_mode_reglement, 27, ' ')
										 || '    ' || 'Erreur : Mode de règlement introuvable ou invalide.'
										 );		--AAM artf07286081 (rempalcer rec.uo_name_interco par rec.uo_name	)			
      END;	  
      
	  
	  
	  
      END LOOP;    

    COMMIT;
	
	
	-- Mettre à jour l'attribute6 des règlements traités
	Dka_Tools_Pkg.put_debug_message('--> Mise à jour de l''attribute6 des règlements traités');
	
	UPDATE ar_cash_receipts_all
	SET attribute6       = g_request_id
	   ,last_update_date = sysdate
	WHERE cash_receipt_id IN (
	                           SELECT to_number(column_value)
							   from dka_program_messages
							   where request_id = g_request_id
							   and message_type = 'I'
	                         )
    ;	
    
	
    	
	Dka_Tools_Pkg.put_debug_message('Nombre de règlements taguées : '|| to_char(SQL%ROWCOUNT));  
    Dka_Tools_Pkg.put_debug_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin create_data');
					  
					  
 EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'create_data : ' || SQLERRM;
      Dka_Tools_Pkg.put_debug_message( p_errbuf);
      Dka_Tools_Pkg.put_debug_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure create_data : EXCEPTION OTHERS ');
 END create_data;




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
                 p_retcode OUT NUMBER) IS
  
    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
    -- v_directory              VARCHAR2(100):='/oradata/HELDEV/app/data/in';
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
  
    v_errbuf  := NULL;
    v_retcode := 0;
  
    Init(v_errbuf, v_retcode);
  
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;

    
  
    -------------------------------------
    -- PHASE DE CREATION DES DONNEES --
    -------------------------------------
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DE CREATION DES DONNEES');
  
    -- Lancement du programme de chargement
    create_data(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
  

    ----------------------------------
    -- PHASE DE BILAN DU TRAITEMENT --
    ----------------------------------
  
    print_errors;

  
    ---------------------------------------
    -- PHASE DE FIN DU TRAITEMENT MAITRE --
    ---------------------------------------
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
    ELSIF (g_warning) THEN
      p_errbuf  := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
      p_retcode := 1;	  
    ELSE
      p_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      p_retcode := 0;
    END IF;
  
    Dka_Tools_Pkg.put_debug_message( p_errbuf);
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf || CHR(10));
    output_end;
    Dka_Tools_Pkg.put_debug_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');
  
  EXCEPTION
    WHEN Erreur_Programme THEN
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
                        'DKA_SARAUTENC_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END main;

END DKA_SARAUTENC_PKG;
/
SHOW ERRORS
EXIT
