SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

create or replace PACKAGE BODY DKA_REPARENCIMP_PKG IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_REPARENCIMP_PKG.pkb  V1.9
  --
  -- AUTEUR
  --    Capgemini
  --
  -- DESCRIPTION
  --    Création du package de l'interface specifique des encaissements clients
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
  -- V1.0    26/04/2016     OBN Creation
  ---------------------------------------------------------------------------------------------
  -- V1.1    29/07/2016     OBN Modification : Ajout du customer_id et correction date p_apply_gl_date
  ---------------------------------------------------------------------------------------------
  -- V1.2    02/08/2016     OBN Modification : Modification de la sortie du traitement
  ---------------------------------------------------------------------------------------------
  -- V1.3    07/09/2016     OBN Modification : Stockage RECEIPT_METHOD 11i dans un CUF -artf2002538-
  ---------------------------------------------------------------------------------------------
  -- V1.4    23/09/2016     OBN Modification : Modification table transco mode de règlement -artf2010909-
  ---------------------------------------------------------------------------------------------
  -- V1.5    20/10/2016     MEG Modification : artf2032055 : Reprise des encaissement - Controle du client
  --                                           artf2031884 : Reprise des encaissement - Controle du solde
  --                                           artf2032268 : Reprise des encaissement - Gestion de la date GL
  --                                           artf2024580 : GFK devient DOS. Merci de prévoir la substitution de la région GFK par DOS lors de la reprise des encaissements clients
  ---------------------------------------------------------------------------------------------
  -- V1.6    20/10/2016     MEG Modification : artf2032359 : Pas d'appel des API
  ---------------------------------------------------------------------------------------------
  -- V1.7    25/01/2017     JLY Modification : artf2090816 : Gestion de la date GL d'import
  ---------------------------------------------------------------------------------------------
  -- V1.8    26/04/2017     NBO Modification : artf2143239 : Reprise des encaissements client - R12 - Règlement en doublon
  ---------------------------------------------------------------------------------------------
  -- V1.9    26/10/2017     OBE Modification : artf2250806 : REP005 - Reprise des encaissements client - Ajout du champ commentaire
  ---------------------------------------------------------------------------------------------  

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  TYPE summary_typ IS RECORD(
    loaded_rows            NUMBER -- Nb de Lignes chargées en table spécifique
    ,
    rejected_rows          NUMBER -- Nb de lignes rejetées en table spécifique
    ,
    rejected_api_rows      NUMBER -- Nb de lignes rejetées après l'api
    ,
    inserted_receipts_rows NUMBER -- Nb de Lignes de réceptions non lettrées insérées dans Oracle
    ,
    inserted_unid_rows     NUMBER -- Nb de Lignes de réceptions non identifiées insérées dans Oracle
    ,
    inserted_on_acc_rows   NUMBER -- Nb de Lignes de réceptions en compte insérées dans Oracle
    );

  g_summary summary_typ;

  g_user_id              fnd_user.user_id%TYPE;
  g_login_id             fnd_logins.login_id%TYPE;
  g_org_id               hr_all_organization_units.organization_id%TYPE;
  g_request_id           fnd_concurrent_requests.request_id%TYPE;
  g_loader_request_id    fnd_concurrent_requests.request_id%TYPE;
  g_request_OI_vendor_id fnd_concurrent_requests.request_id%TYPE;
  g_request_OI_site_id   fnd_concurrent_requests.request_id%TYPE;
  gv_printer             fnd_concurrent_requests.printer%TYPE;
  g_number_of_copies     fnd_concurrent_requests.number_of_copies%TYPE;
  g_tempo                NUMBER;
  g_gl_date              DATE;
  g_gl_date_max          DATE; -- V1.7

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
                 p_retcode OUT NUMBER,
                 p_gl_date IN VARCHAR2) IS
  
    v_current_program_unit VARCHAR2(30);
    v_step_program_error   VARCHAR2(1000);
    program_error EXCEPTION;
  
  BEGIN
  
    Fnd_File.put_line(Fnd_File.LOG,
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
  
    -- Variables globales de comptage
    g_summary.loaded_rows            := 0;
    g_summary.rejected_rows          := 0;
    g_summary.rejected_api_rows      := 0;
    g_summary.inserted_receipts_rows := 0;
    g_summary.inserted_unid_rows     := 0;
    g_summary.inserted_on_acc_rows   := 0;
  
    -- Formatage de la date comptable
    g_gl_date := TRUNC(fnd_date.canonical_to_date(p_gl_date));
  
    --< V1.7
    SELECT  trunc(add_months(g_gl_date, 1), 'MM') - 1
    INTO    g_gl_date_max
    FROM    DUAL;
    --> V1.7
    
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin init');
  
    BEGIN
      SELECT printer, number_of_copies
        INTO gv_printer, g_number_of_copies
        FROM fnd_concurrent_requests fcr
       WHERE fcr.request_id = g_request_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' - ' ||
                          'Erreur de récupération de l''imprimante');
        gv_printer         := NULL;
        g_number_of_copies := 0;
    END;
  
  EXCEPTION
    WHEN program_error THEN
      fnd_file.put_line(fnd_file.log, 'ERREUR : ' || v_step_program_error);
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
    Fnd_File.put_line(Fnd_File.log, 'PARAMETRES : ');
    Fnd_File.put_line(Fnd_File.log, '--------------');
  
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
      Fnd_File.put_line(Fnd_File.log,
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
        Fnd_File.put_line(Fnd_File.log,
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
      END LOOP;
    
      Fnd_File.put_line(Fnd_File.output, CHR(10));
    
    ELSE
      Fnd_File.put_line(Fnd_File.output, 'Aucun argument');
      Fnd_File.put_line(Fnd_File.log, 'Aucun argument');
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
  
    CURSOR cur_prog_mess IS
      SELECT *
        FROM DKA_PROGRAM_MESSAGES
       WHERE REQUEST_ID = g_request_id
         AND SOURCE = 'ETL';
  
    CURSOR cur_prog_mess_api IS
      SELECT *
        FROM DKA_PROGRAM_MESSAGES
       WHERE REQUEST_ID = g_request_id
         AND SOURCE = 'API';
  
  BEGIN
    --<V1.2
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,
                      'LISTE DES ANOMALIES PHASE DE VALIDATION:');
    fnd_file.put_line(fnd_file.OUTPUT,
                      '----------------------------------------');
    fnd_file.put_line(fnd_file.OUTPUT, 'Encaissement    Ligne    Message');
    fnd_file.put_line(fnd_file.OUTPUT, '------------    -----    -------');
  
    FOR msg IN cur_prog_mess LOOP
      --Fnd_File.put_line (Fnd_File.output, '. '||msg.message_text);
      Fnd_File.put_line(Fnd_File.output,
                        RPAD(msg.column_value, 12, ' ') || '    ' ||
                        RPAD(NVL(msg.table_id, ' '), 5, ' ') || '    ' ||
                        msg.message_text);
    END LOOP;
  
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'LISTE DES ANOMALIES DE L''API:');
    fnd_file.put_line(fnd_file.OUTPUT, '------------------------------');
    fnd_file.put_line(fnd_file.OUTPUT, 'Encaissement    Ligne    Message');
    fnd_file.put_line(fnd_file.OUTPUT, '------------    -----    -------');
  
    FOR msg IN cur_prog_mess_api LOOP
      --Fnd_File.put_line (Fnd_File.output, '. '||msg.message_text);
      Fnd_File.put_line(Fnd_File.output,
                        RPAD(msg.column_value, 12, ' ') || '    ' ||
                        RPAD(NVL(msg.table_id, ' '), 5, ' ') || '    ' ||
                        msg.message_text);
    END LOOP;
    -->V1.2
  
  END print_errors;

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
  PROCEDURE Launch_Loader(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
    b_result     BOOLEAN;
  
  BEGIN
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Launch_Loader');
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Lancement de chargement du fichier dans la table d''interface spécifique : ');
  
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'CHARGEMENT DU FICHIER :');
    fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
    ------------------------------------------------------
    -- Lancement du traitement de chargement du fichier --
    ------------------------------------------------------
    -- Positionnement des options d'impression
    b_result := fnd_request.set_print_options(printer => gv_printer,
                                              copies  => g_number_of_copies);
    -- Lancement du traitement
    g_loader_request_id := Fnd_Request.submit_request('DKA' -- APPL
                                                     ,
                                                      'DKA_LOADER_REPARENCIMP' -- PROG
                                                     ,
                                                      NULL -- PROGRAM_NAME
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                      );
  
    IF g_loader_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.LOG,
                        'ERREUR : Le traitement de chargement du fichier a échoué' ||
                        CHR(10) || 'PROGRAMME  : DKA_LOADER_REPARENCIMP' ||
                        CHR(10));
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '====> ERREUR : Le traitement de chargement du fichier a échoué');
    ELSE
      COMMIT;
      Fnd_File.put_line(Fnd_File.LOG,
                        '=> LOAD REQUEST ID= ' || g_loader_request_id);
      Fnd_File.put_line(Fnd_File.OUTPUT,
                        '. Numéro du traitement de chargement du fichier : ' ||
                        g_loader_request_id);
    
      -- Attente de la fin du traitement
      IF NOT (Fnd_Concurrent.wait_for_request(g_loader_request_id,
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        p_errbuf := v_Message;
        Fnd_file.put_line(Fnd_file.log,
                          'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
      END IF;
    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        Fnd_File.put_line(Fnd_File.OUTPUT,
                          '. Statut de fin : ' || v_phase || '/' ||
                          v_status);
      
        UPDATE DKA_AR_RECEIPTS_TMP
           SET load_request_id = g_loader_request_id
         WHERE load_request_id IS NULL;
      
        SELECT COUNT(*)
          INTO g_summary.loaded_rows
          FROM DKA_AR_RECEIPTS_TMP
         WHERE load_request_id = g_loader_request_id;
        Fnd_File.put_line(Fnd_File.LOG,
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' Nbre enregistrements charges => ' ||
                          g_summary.loaded_rows);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        Fnd_File.put_line(Fnd_File.LOG,
                          'Fin du traitement de chargement en warning ' ||
                          g_loader_request_id);
        p_retcode := 1;
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        p_retcode := 2;
        p_errbuf  := 'ERREUR : Fin anormale du traitement de chargement : ' ||
                     v_Message;
      
        fnd_file.put_line(fnd_file.LOG,
                          'ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id || CHR(10) ||
                          'Phase/Statut : ' || v_dev_phase || '/' ||
                          v_dev_status || CHR(10) || 'MESSAGE : ' ||
                          v_message || CHR(10));
        Fnd_File.put_line(Fnd_File.OUTPUT,
                          '===> ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id);
      END IF;
    
    END IF;
  
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Launch_Loader');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'LAUNCH_LOADER : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
  END Launch_Loader;

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

  PROCEDURE validate_data(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    CURSOR cur_enc IS
      SELECT *
        FROM DKA_AR_RECEIPTS_TMP
       WHERE LOAD_REQUEST_ID =
             DECODE(g_loader_request_id,
                    -1,
                    load_request_id,
                    g_loader_request_id)
         AND STATUT IS NULL
         FOR UPDATE OF STATUT, ORG_ID, AMOUNT, CUSTOMER_ID;
  
    v_flag_erreur       BOOLEAN := FALSE;
    v_org_id            NUMBER;
    v_customer_id       NUMBER;
    v_receipt_method    VARCHAR2(50);
    v_remit_bank_acc_id NUMBER;
    v_exists            VARCHAR2(10);
    v_region            VARCHAR2(30);
  
  BEGIN
  
    FOR enc IN cur_enc LOOP
      v_flag_erreur := FALSE;
    
      -- Vérification de l'existence de l'organisation
      BEGIN
      
        -- Tanscodification de la région
        dka_rep_transco_pkg.get_transco(pv_transco_name => '008_REGIONS',
                                        pv_column_01    => substr(enc.operating_unit,
                                                                  1,
                                                                  3),
                                        pv_out_01       => v_region);
      
        -- Récupération de l'identifiant de l'organisation
        SELECT hou.organization_id
          INTO v_org_id
          FROM hr_operating_units hou
        --< V1.6
        --WHERE   hou.name = v_region||substr(enc.OPERATING_UNIT,4)
         WHERE hou.name = v_region || substr(enc.OPERATING_UNIT, 4, 4)
              --> V1.6
           AND trunc(SYSDATE) BETWEEN nvl(date_from, SYSDATE) AND
               nvl(date_to, SYSDATE);
      
      EXCEPTION
        WHEN OTHERS THEN
          v_flag_erreur := TRUE;
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPARENCIMP',
                                         'ETL',
                                         'DKA_AR_RECEIPTS_TMP',
                                         enc.logical_line_num,
                                         'OPERATING_UNIT',
                                         enc.receipt_number,
                                         'E',
                                         'L''unité opérationnelle ' ||
                                         v_region ||
                                         substr(enc.OPERATING_UNIT, 4, 4) ||
                                         ' est introuvable');
          g_summary.rejected_rows := g_summary.rejected_rows + 1;
      END;
    
      -- Vérification de l'existence du mode de réglement
      BEGIN
      
        -- Transcodification du mode de paiement
        DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '017_RECEIPT_METHOD_ENC', -- V1.4
                                        pv_column_01    => enc.receipt_method,
                                        pv_out_01       => v_receipt_method);
      
        -- Recherche de remittance_bank_account_id
        SELECT armaa.remit_bank_acct_use_id
          INTO v_remit_bank_acc_id
          FROM ar_receipt_method_accounts_all armaa, ar_receipt_methods arm
         WHERE armaa.receipt_method_id = arm.receipt_method_id
           AND arm.name = v_receipt_method;
      
      EXCEPTION
        WHEN OTHERS THEN
          v_flag_erreur       := TRUE;
          v_remit_bank_acc_id := NULL;
        
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPARENCIMP',
                                         'ETL',
                                         'DKA_AR_RECEIPTS_TMP'
                                         --,NULL
                                        ,
                                         enc.logical_line_num,
                                         'RECEIPT_METHOD'
                                         --,enc.RECEIPT_METHOD
                                        ,
                                         enc.receipt_number,
                                         'E',
                                         'Le mode de paiement ' ||
                                         v_receipt_method ||
                                         ' n''existe pas dans la table AR_RECEIPT_METHODS');
          g_summary.rejected_rows := g_summary.rejected_rows + 1;
      END;
    
      --< V1.1
      --< V1.5 : modification
      --IF  enc.customer_number IS NOT NULL AND enc.customer_name IS NOT NULL THEN
      IF enc.customer_number IS NOT NULL THEN
      
        BEGIN
        
          --< V1.5 : modification
          /*
          SELECT customer_id
          INTO v_customer_id
          FROM AR_CUSTOMERS
          WHERE customer_name = enc.customer_name
          AND   customer_number = enc.customer_number;
          */
        
          SELECT customer_id
            INTO v_customer_id
            FROM AR_CUSTOMERS
           WHERE customer_number = enc.customer_number;
        
          --Fnd_File.put_line(Fnd_File.LOG, 'Récupération ID du client '||enc.customer_name||'. ID : '||v_customer_id);
        
        EXCEPTION
          WHEN OTHERS THEN
            v_flag_erreur := TRUE;
            v_customer_id := NULL;
          
            dka_tools_pkg.ins_prog_message(g_request_id,
                                           'DKA_REPARENCIMP',
                                           'ETL',
                                           'DKA_AR_RECEIPTS_TMP'
                                           --,NULL
                                          ,
                                           enc.logical_line_num,
                                           'CUSTOMER_ID',
                                           enc.receipt_number,
                                           'E',
                                           'Le client ' ||
                                           enc.customer_name || ' (num:' ||
                                           enc.customer_number ||
                                           ') n''existe pas');
            g_summary.rejected_rows := g_summary.rejected_rows + 1;
          
        END;
      ELSE
        v_customer_id := NULL;
      END IF;
      --> V1.1
    
      --< V1.5 : ajout
      BEGIN
      
        IF NVL(enc.amount_non_applied, 0) > NVL(enc.receipt_amount, 0) OR
           NVL(enc.amount_non_applied, 0) < 0 THEN
        
          v_flag_erreur := TRUE;
        
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPARENCIMP',
                                         'ETL',
                                         'DKA_AR_RECEIPTS_TMP',
                                         enc.logical_line_num,
                                         'AMOUNT_NON_APPLIED',
                                         enc.receipt_number,
                                         'E',
                                         'Solde incohérent : Montant initial : ' || 
                                         enc.receipt_amount ||
                                         '/ Montant non lettré ' ||
                                         enc.amount_non_applied);
        
          g_summary.rejected_rows := g_summary.rejected_rows + 1;
        
        END IF;
      
      END;
      --< V1.5 : fin ajout
    
      IF NOT v_flag_erreur THEN
      
        UPDATE DKA_AR_RECEIPTS_TMP
           SET STATUT             = 'S',
               ORG_ID             = v_org_id,
               AMOUNT             = enc.amount_non_applied -- enc.amount_on_account + enc.amount_non_applied
              ,
               CUSTOMER_ID        = v_customer_id,
               REMIT_BANK_ACC_ID  = v_remit_bank_acc_id,
               RECEIPT_METHOD_NEW = v_receipt_method
         WHERE CURRENT OF cur_enc;
      
      ELSE
        -- en cas d'erreur
      
        UPDATE DKA_AR_RECEIPTS_TMP
           SET STATUT = 'E'
         WHERE CURRENT OF cur_enc;
      
      END IF;
    
    END LOOP;
  
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
  
    CURSOR cur_recep IS
      -- V1.8    26/04/2017     NBO Modification : artf2143239 : Reprise des encaissements client - R12 - Règlement en doublon
      SELECT tmp.*, tmp2.new_receipt_number
            FROM DKA_AR_RECEIPTS_TMP tmp,
                 ( SELECT rowid rid,
            row_number() over(PARTITION BY receipt_number, customer_number, customer_name, receipt_date, amount_non_applied ORDER BY 1) rk,
            decode(row_number() over(PARTITION BY receipt_number,
                        customer_number,
                        customer_name,
                        receipt_date,
                        amount_non_applied ORDER BY 1, statut desc),
                   1,
                   receipt_number,
                   substr(receipt_number, 1, 28) || '-' || row_number()
                   over(PARTITION BY receipt_number,
                        customer_number,
                        customer_name,
                        receipt_date,
                        amount_non_applied ORDER BY 1, statut desc)) new_receipt_number
       FROM dka_ar_receipts_tmp tmp) tmp2
       WHERE tmp.rowid = tmp2.rid
         AND LOAD_REQUEST_ID =
             DECODE(g_loader_request_id,
                    -1,
                    load_request_id,
                    g_loader_request_id)
         AND STATUT = 'S'
         FOR UPDATE OF STATUT;
  
    v_interface_header_id NUMBER;
  
    v_approval_statut   VARCHAR2(25);
    v_quantity          NUMBER;
    v_STYLE_ID          NUMBER;
    v_resp_id           NUMBER;
    v_resp_appl_id      NUMBER;
    v_user_id           NUMBER;
    v_receipt_method_id NUMBER;
    --v_customer_id               NUMBER;
    i                  NUMBER;
    j                  NUMBER;
    v_societe_region   VARCHAR2(30);
    v_receipt_method   VARCHAR2(30);
    v_return_status    VARCHAR2(30);
    v_currency_code    VARCHAR(3);
    v_msg_count        NUMBER;
    v_msg_data         VARCHAR2(2000);
    v_attribute_rec    AR_RECEIPT_API_PUB.attribute_rec_type;
    v_cr_id            NUMBER;
    v_amount           NUMBER;
    v_org_id           NUMBER := FND_PROFILE.VALUE('ORG_ID');
    v_rcpt_method_name VARCHAR2(20);
    v_amount_applied   ar_receivable_applications.amount_applied%TYPE;
    v_apply_date       ar_receivable_applications.apply_date%TYPE;
    --v_apply_gl_date    ar_receivable_applications.gl_date%TYPE;
    v_flag_erreur      BOOLEAN := FALSE;
  
  BEGIN
  
    --v_attribute_rec.attribute1 := '100';
    v_apply_date    := sysdate;
    --v_apply_gl_date := g_gl_date; --sysdate; -- V1.1
  
    v_user_id      := FND_PROFILE.VALUE('USER_ID');
    v_resp_id      := FND_PROFILE.VALUE('RESP_ID');
    v_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');
  
    ---------------------------------------------------------------------------------
    -- Transcodification des données et alimentation de la table PO_HEADERS_INTERFACE
    ---------------------------------------------------------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      'Parcours du curseur des encaissements');
  
    FOR enc IN cur_recep LOOP
    
      BEGIN
        v_flag_erreur := FALSE;

        Fnd_File.put_line(Fnd_File.LOG,
                          '--------------------------------------------');
        Fnd_File.put_line(Fnd_File.LOG,
                          'Numéro d''encaissement : ' || enc.new_receipt_number);
        Fnd_File.put_line(Fnd_File.LOG,
                          '--------------------------------------------');
      
        v_attribute_rec.attribute1 := enc.receipt_amount;
        v_attribute_rec.attribute3 := enc.RECEIPT_METHOD; -- V1.3
      
        --< V1.6
        --APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
        --                                RESP_ID      => v_resp_id,
        --                                RESP_APPL_ID => v_resp_appl_id
        --                               );
        --mo_global.set_org_context(enc.org_id,NULL,'AR');
        --MO_GLOBAL.INIT('AR');
        --> V1.6
      
        BEGIN
          SELECT receipt_method_id
            INTO v_receipt_method_id
            FROM ar_receipt_methods
           WHERE name = enc.RECEIPT_METHOD_NEW -- v1.3
          ;
          Fnd_File.put_line(Fnd_File.LOG,
                            'Récupération ID de la méthode de réception ' ||
                            enc.RECEIPT_METHOD_NEW || '. ID : ' ||
                            v_receipt_method_id);
        
        EXCEPTION
          WHEN OTHERS THEN
            v_receipt_method_id := null;
            v_flag_erreur := TRUE;
            
            Fnd_File.put_line(Fnd_File.LOG,
                              'ID de la méthode de réception ' ||
                              enc.RECEIPT_METHOD_NEW || ' introuvable');
                              
            dka_tools_pkg.ins_prog_message(g_request_id,
                                           'DKA_REPARENCIMP',
                                           'API',
                                           'DKA_AR_RECEIPTS_TMP',
                                           enc.logical_line_num,
                                           'RECEIPT_METHOD_NEW',
                                           enc.RECEIPT_METHOD_NEW,
                                           'E',
                                           'ID de la méthode de réception introuvable');                                  
        END;
      
        IF NOT v_flag_erreur THEN
          IF enc.amount_on_account = 0 THEN
          
            Fnd_File.put_line(Fnd_File.LOG,
                              'Création d''un encaissement non lettré ou non identifié');
            -- Création d'un encaissement non lettré ou non identifié
            ar_receipt_api_pub.Create_cash(p_api_version                  => 1.0,
                                           p_init_msg_list                => FND_API.G_TRUE,
                                           p_commit                       => FND_API.G_FALSE,
                                           p_validation_level             => FND_API.G_VALID_LEVEL_FULL,
                                           x_return_status                => v_return_status,
                                           x_msg_count                    => v_msg_count,
                                           x_msg_data                     => v_msg_data,
                                           p_usr_currency_code            => NULL, --the translated currency code
                                           p_currency_code                => enc.currency_code,
                                           p_usr_exchange_rate_type       => NULL,
                                           p_exchange_rate_type           => NULL, --enc.exchange_rate_type,
                                           p_exchange_rate                => NULL, --enc.exchange_rate,
                                           p_exchange_rate_date           => NULL, --enc.exchange_date,
                                           p_amount                       => enc.amount, --v_amount,
  -- V1.8    26/04/2017     NBO Modification : artf2143239 : Reprise des encaissements client - R12 - Règlement en doublon
                                           p_receipt_number               => enc.new_receipt_number,
                                           p_receipt_date                 => enc.receipt_date,
                                           --V1.5 : p_gl_date             => g_gl_date,
                                           --< v1.7
                                           --p_gl_date                    => GREATEST(g_gl_date, enc.GL_DATE),
                                           p_gl_date                      => CASE WHEN enc.GL_DATE <= g_gl_date_max
                                                                                  THEN g_gl_date
                                                                                  ELSE enc.GL_DATE
                                                                             END,
                                           --> v1.7
                                           p_maturity_date                => enc.due_date,
                                           p_customer_id                  => enc.customer_id, --v_customer_id,
                                           --p_customer_name                => enc.customer_name,
                                           --p_customer_number              => enc.customer_number,
                                           p_customer_bank_account_id     => NULL,
                                           p_customer_bank_account_num    => NULL,
                                           p_customer_bank_account_name   => NULL,
                                           p_customer_receipt_reference   => 'SKM-API',
                                           p_override_remit_account_flag  => NULL,
                                           p_remittance_bank_account_id   => enc.REMIT_BANK_ACC_ID,
                                           p_remittance_bank_account_num  => NULL,
                                           p_remittance_bank_account_name => NULL,
                                           p_deposit_date                 => sysdate,
                                           p_receipt_method_id            => v_receipt_method_id, --NULL,
                                           p_receipt_method_name          => NULL,
                                           p_org_id                       => enc.org_id, --v_org_id,
                                           p_called_from                  => 'pl/sql Script',
                                           p_attribute_rec                => v_attribute_rec,
                                           p_comments                     => enc.COMMENTS, --'Migration DALKIA R12', --OBE artf2250806
                                           p_issuer_name                  => NULL,
                                           p_issue_date                   => NULL,
                                           p_issuer_bank_branch_id        => NULL,
                                           p_cr_id                        => v_cr_id
                                          );
          
            IF (v_return_status = 'S') THEN
              -- COMMIT;
              v_flag_erreur := FALSE;
              Fnd_File.put_line(Fnd_File.LOG, 'SUCCESS');
              Fnd_File.put_line(Fnd_File.LOG,
                                'Return Status   :' ||
                                SUBSTR(v_return_status, 1, 255));
              Fnd_File.put_line(Fnd_File.LOG, 'Cash receipt Id :' || v_cr_id);
              IF enc.customer_name IS NOT NULL AND
                 enc.customer_number IS NOT NULL THEN
                g_summary.inserted_receipts_rows := g_summary.inserted_receipts_rows + 1;
              ELSE
                g_summary.inserted_unid_rows := g_summary.inserted_unid_rows + 1;
              END IF;
              Fnd_File.put_line(Fnd_File.LOG,
                                '---------------------------------------------------------------');
            ELSE
              -- ROLLBACK;
              g_summary.rejected_api_rows := g_summary.rejected_api_rows + 1;
            
              IF fnd_msg_pub.count_msg > 0 THEN
                v_flag_erreur := TRUE;
                FOR j in 1 .. FND_MSG_PUB.count_msg LOOP
                  FND_MSG_PUB.get(p_msg_index     => j,
                                  p_encoded       => 'F',
                                  p_data          => v_msg_data,
                                  p_msg_index_out => i);
                  Fnd_File.put_line(Fnd_File.LOG,
  -- V1.8    26/04/2017     NBO Modification : artf2143239 : Reprise des encaissements client - R12 - Règlement en doublon
                                    'Error Receipt ' || enc.new_receipt_number ||
                                    ' : ' || j || ':' || v_msg_data);
                
                  --Ecriture de lerreur dans la table specifique
                  dka_tools_pkg.ins_prog_message(g_request_id,
                                                 'DKA_REPARENCIMP',
                                                 'API',
                                                 'DKA_AR_RECEIPTS_TMP',
                                                 enc.logical_line_num,
                                                 NULL,--'RECEIPT_NUMBER',
                                                 NULL,--enc.receipt_number,
                                                 'E',
                                                 v_msg_data);                
                  
                END LOOP;
              END IF;
              Fnd_File.put_line(Fnd_File.LOG,
                                '---------------------------------------------------------------');
            
            END IF;
          
          ELSE
            Fnd_File.put_line(Fnd_File.LOG,
                              'Création et mise en compte d''un encaissement');
            v_amount_applied := enc.amount_on_account;
          
            -- Création et mise en compte d'un encaissement
            AR_RECEIPT_API_PUB.Create_Apply_on_acc(p_api_version                => 1.0,
                                                   p_init_msg_list              => FND_API.G_TRUE,
                                                   p_commit                     => FND_API.G_FALSE,
                                                   p_validation_level           => FND_API.G_VALID_LEVEL_FULL,
                                                   x_return_status              => v_return_status,
                                                   x_msg_count                  => v_msg_count,
                                                   x_msg_data                   => v_msg_data,
                                                   p_currency_code              => enc.currency_code,
                                                   p_amount                     => enc.amount, --v_amount,
  -- V1.8    26/04/2017     NBO Modification : artf2143239 : Reprise des encaissements client - R12 - Règlement en doublon
                                                   p_receipt_number             => enc.new_receipt_number,
                                                   p_receipt_date               => enc.receipt_date,
                                                   --V1.5 : p_gl_date             => g_gl_date,
                                                   --< v1.7
                                                   --p_gl_date                    => GREATEST(g_gl_date, enc.GL_DATE),
                                                   p_gl_date                    => CASE WHEN enc.GL_DATE <= g_gl_date_max
                                                                                        THEN g_gl_date
                                                                                        ELSE enc.GL_DATE
                                                                                   END,
                                                   --> v1.7
                                                   p_maturity_date              => enc.due_date,
                                                   p_customer_receipt_reference => 'SKM-API',
                                                   p_customer_id                => enc.customer_id, --v_customer_id,
                                                   --p_customer_name               => enc.customer_name,
                                                   --p_customer_number             => enc.customer_number,
                                                   p_receipt_method_id          => v_receipt_method_id,
                                                   --p_receipt_method_name         => enc.RECEIPT_METHOD,
												   p_receipt_comments           => enc.COMMENTS, --OBE artf2250806
                                                   p_attribute_rec              => v_attribute_rec,
                                                   p_org_id                     => enc.org_id, --v_org_id,
                                                   p_cr_id                      => v_cr_id,
                                                   p_amount_applied             => v_amount_applied,
                                                   p_apply_date                 => v_apply_date,
                                                   --V1.5 : p_apply_gl_date       => v_apply_gl_date
                                                   --< v1.7
                                                   --p_apply_gl_date              => GREATEST(v_apply_gl_date, enc.GL_DATE)
                                                   p_apply_gl_date              => CASE WHEN enc.GL_DATE <= g_gl_date_max
                                                                                        THEN g_gl_date
                                                                                        ELSE enc.GL_DATE
                                                                                   END
                                                   --> v1.7
                                                  );
          
            IF (v_return_status = 'S') THEN
              --COMMIT;
              v_flag_erreur := FALSE;
              Fnd_File.put_line(Fnd_File.LOG, 'SUCCESS');
              Fnd_File.put_line(Fnd_File.LOG,
                                'Return Status   :' ||
                                SUBSTR(v_return_status, 1, 255));
              Fnd_File.put_line(Fnd_File.LOG, 'Cash receipt Id :' || v_cr_id);
              g_summary.inserted_on_acc_rows := g_summary.inserted_on_acc_rows + 1;
              Fnd_File.put_line(Fnd_File.LOG,
                                '---------------------------------------------------------------');
            
            ELSE
              --ROLLBACK;
              g_summary.rejected_api_rows := g_summary.rejected_api_rows + 1;
            
              IF fnd_msg_pub.count_msg > 0 THEN
                v_flag_erreur := TRUE;
                FOR j in 1 .. FND_MSG_PUB.count_msg LOOP
                  FND_MSG_PUB.get(p_msg_index     => j,
                                  p_encoded       => 'F',
                                  p_data          => v_msg_data,
                                  p_msg_index_out => i);
                  Fnd_File.put_line(Fnd_File.LOG,
  -- V1.8    26/04/2017     NBO Modification : artf2143239 : Reprise des encaissements client - R12 - Règlement en doublon
                                    'Error Receipt ' || enc.new_receipt_number ||
                                    ' : ' || j || ':' || v_msg_data);
                                    
                  --Ecriture de lerreur dans la table specifique
                  dka_tools_pkg.ins_prog_message(g_request_id,
                                                 'DKA_REPARENCIMP',
                                                 'API',
                                                 'DKA_AR_RECEIPTS_TMP',
                                                 enc.logical_line_num,
                                                 NULL,--'RECEIPT_NUMBER',
                                                 NULL,--enc.receipt_number,
                                                 'E',
                                                 v_msg_data);     
                END LOOP;
              END IF;
              Fnd_File.put_line(Fnd_File.LOG,
                                '---------------------------------------------------------------');
            
            END IF;
          END IF;
        END IF;
      
        -- Mise à jour du statut de la ligne
        IF NOT v_flag_erreur THEN
        
          UPDATE DKA_AR_RECEIPTS_TMP
             SET STATUT = 'T'
           WHERE CURRENT OF cur_recep;
        ELSE
          -- en cas d'erreur
          UPDATE DKA_AR_RECEIPTS_TMP
             SET STATUT = 'E'
           WHERE CURRENT OF cur_recep;
        
        END IF;
      
      EXCEPTION
        WHEN OTHERS THEN
          dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                                          ' - ' || SQLERRM);
                                          
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPARENCIMP',
                                         'API',
                                         'DKA_AR_RECEIPTS_TMP',
                                         enc.logical_line_num,
                                         NULL,--'RECEIPT_NUMBER',
                                         NULL,--enc.receipt_number,
                                         'E',
                                         SQLERRM);                                                   
          p_retcode := 1;
      END;
    
    END LOOP;
  
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'create_data : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure create_data : EXCEPTION OTHERS ');
  END create_data;

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
  PROCEDURE Report_Bilan(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
  BEGIN
  
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Report_Bilan');
  
    --------------------
    -- Initialisation --
    --------------------
  
    p_errbuf  := NULL;
    p_retcode := 0;
  
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'BILAN :');
    fnd_file.put_line(fnd_file.OUTPUT, '-------');
    --<V1.2
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table spécifique          : ' ||
                      TO_CHAR(g_summary.loaded_rows));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''anomalies après la phase de validation des données        : ' ||
                      TO_CHAR(g_summary.rejected_rows));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''anomalies après le lancement de l''API                     : ' ||
                      TO_CHAR(g_summary.rejected_api_rows) || CHR(10));
    -->V1.2
  
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''encaissement non lettrées créés          : ' ||
                      TO_CHAR(g_summary.inserted_receipts_rows));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d'' encaissement non identifiées créés       : ' ||
                      TO_CHAR(g_summary.inserted_unid_rows));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d'' encaissement en compte créées            : ' ||
                      TO_CHAR(g_summary.inserted_on_acc_rows) || CHR(10));
  
    fnd_file.put_line(fnd_file.OUTPUT,
                      'Voir les sorties des traitements d''Open interface pour avoir plus de détails sur les enregistrements rejetés.');
  
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Report_Bilan');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'REPORT_BILAN : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan;

  /*
  *************************************************************************
   * PROCEDURE NAME : set_recovery_mode
   *
   * DESCRIPTION
   *  Procédure d'initialisation du mode reprise (Pas de fichier en entrée)
   *
   * PARAMETERS
   * ==========
   * NAME               DESCRIPTION
   * -----------------  ------------------------------------------------------
   *
   ************************************************************************
   */

  PROCEDURE set_recovery_mode(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
  BEGIN
  
    g_loader_request_id := -1;
  
    UPDATE DKA_AR_RECEIPTS_TMP SET STATUT = NULL WHERE STATUT = 'E';
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'SET_RECOVERY_MODE : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure SET_RECOVERY_MODE : EXCEPTION OTHERS ');
  END set_recovery_mode;

  /*
  ************************************************************************
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
   ************************************************************************
   */

  PROCEDURE purge_data(p_Errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
  BEGIN
  
    Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_AR_RECEIPTS_TMP');
    DELETE FROM DKA_AR_RECEIPTS_TMP;
    Fnd_File.Put_Line(Fnd_File.LOG,
                      '=> Deleted rows ' || TO_CHAR(SQL%ROWCOUNT));
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'PURGE_DATA : ' || SQLERRM;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;

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
                 p_gl_date IN VARCHAR2,
                 p_reprise IN VARCHAR2) IS
  
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
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
  
    Output_Header;
    Request_parameters;
  
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''INITIALISATION');
  
    v_errbuf  := NULL;
    v_retcode := 0;
  
    Init(v_errbuf, v_retcode, p_gl_date);
  
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
  
    IF p_reprise = 'N' THEN
    
      -------------------------------------------
      -- PHASE DE PURGE DES ANCIENNES DONNEES  --
      -------------------------------------------
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'PURGE DES DONNEES');
      purge_data(v_errbuf, v_retcode);
      IF v_retcode = 2 THEN
        p_Errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE Erreur_Programme;
      END IF;
    
      ------------------------------------
      -- PHASE DE CHARGEMENT DU FICHIER --
      ------------------------------------
      Fnd_File.put_line(Fnd_File.LOG,
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'PHASE DE CHARGEMENT DU FICHIER');
    
      -- Lancement du programme de chargement
      Launch_Loader(v_errbuf, v_retcode);
      IF v_retcode = 2 THEN
        RAISE Erreur_Programme;
      END IF;
    
    ELSE
      set_recovery_mode(v_errbuf, v_retcode);
    
    END IF;
  
    --IF g_summary.loaded_rows != 0 THEN
  
    -------------------------------------
    -- PHASE DE VALIDATION DES DONNEES --
    -------------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DE VALIDATION DES DONNEES');
  
    validate_data(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
    -------------------------------------
    -- PHASE DE CREATION DES DONNEES --
    -------------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DE CREATION DES DONNEES');
  
    -- Lancement du programme de chargement
    create_data(v_errbuf, v_retcode);
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      RAISE Erreur_Programme;
    END IF;
  
    --END IF;
  
    ----------------------------------
    -- PHASE DE BILAN DU TRAITEMENT --
    ----------------------------------
  
    Report_Bilan(v_errbuf, v_retcode);
  
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      --RAISE Erreur_Programme;
    END IF;
  
    ------------------------------------
    -- PHASE DE CHARGEMENT DU FICHIER --
    ------------------------------------
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DES ANOMALIES');
  
    print_errors;
  
    ---------------------------------------
    -- PHASE DE FIN DU TRAITEMENT MAITRE --
    ---------------------------------------
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
    ELSIF (g_summary.rejected_rows > 0) OR
          (g_summary.rejected_api_rows > 0) THEN
      p_errbuf  := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
      p_retcode := 1;
    ELSIF (g_summary.loaded_rows = 0) THEN
      p_errbuf  := 'ATTENTION : Aucun enregistrement chargé.';
      p_retcode := 1;
    ELSE
      p_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      p_retcode := 0;
    END IF;
  
    Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
    Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf || CHR(10));
    output_end;
    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');
  
  EXCEPTION
    WHEN Erreur_Programme THEN
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      Fnd_File.put_line(Fnd_File.LOG, p_errbuf);
      Fnd_File.put_line(Fnd_File.OUTPUT, CHR(10) || p_errbuf);
      Fnd_File.put_line(Fnd_File.LOG,
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
      Fnd_File.put_line(Fnd_File.Log,
                        'Erreur technique sur le composant   : ' ||
                        'DKA_REPARENCIMP_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END main;

END DKA_REPARENCIMP_PKG;
/
SHOW ERRORS
EXIT
