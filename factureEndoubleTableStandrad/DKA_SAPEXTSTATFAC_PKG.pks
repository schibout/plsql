SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_REPFNDRESP_PKG IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_REPFNDRESP_PKG.pkb  V1.0
  --
  -- AUTEUR
  --    Capgemini
  --
  -- DESCRIPTION
  --    Création du package du traitement d'import pour reprise des liens responsabilité/utilisateur
  --
  -- USAGE
  --    A exécuter sous SqlPlus avec user APPS sans parametre
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
  -- V1.0    18/05/2017     OBE Creation
  ---------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  TYPE summary_typ IS RECORD(
    loaded_rows            NUMBER -- Nb de Lignes chargées en table spécifique
    ,
    inserted_rows          NUMBER
    ,
    updated_rows           NUMBER
    ,
    rejected_rows          NUMBER -- Nb de lignes rejetées en table spécifique
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
  
  gn_insert PLS_INTEGER := 0;
  gn_update PLS_INTEGER := 0;
  gn_error  PLS_INTEGER := 0;
  

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
   * p_retcode        STATUS du traitement en sortie
   ************************************************************************
   */

  PROCEDURE init(p_errbuf  OUT VARCHAR2,
                 p_retcode OUT NUMBER) IS
  
    v_current_program_unit VARCHAR2(30);
    v_step_program_error   VARCHAR2(1000);
    program_error EXCEPTION;
  
  BEGIN
  
    dka_tools_pkg.put_log_message(
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
    g_summary.inserted_rows          := 0;
    g_summary.updated_rows           := 0;
    g_summary.rejected_rows          := 0;
  
    
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin init');
  
    BEGIN
      SELECT printer, number_of_copies
        INTO gv_printer, g_number_of_copies
        FROM fnd_concurrent_requests fcr
       WHERE fcr.request_id = g_request_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        dka_tools_pkg.put_log_message(
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' - ' ||
                          'Erreur de récupération de l''imprimante');
        gv_printer         := NULL;
        g_number_of_copies := 0;
    END;
  
  EXCEPTION
    WHEN program_error THEN
      dka_tools_pkg.put_log_message( 'ERREUR : ' || v_step_program_error);
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
  *  Procédure pour insérer une en-tete dans le fichier de sortie
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
  
    dka_tools_pkg.put_outdebug_message( cv_line || CHR(10));
    dka_tools_pkg.put_outdebug_message(
                      'Nom du traitement  : ' || v_user_conc_program_name);
    dka_tools_pkg.put_outdebug_message(
                      'Code du traitement : ' || v_conc_program_name);
    dka_tools_pkg.put_outdebug_message(
                      'Programme lancé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    dka_tools_pkg.put_outdebug_message( cv_line || CHR(10) || CHR(10));
  END output_header;

  /*
  *************************************************************************
  * PROCEDURE NAME : Request_parameters
  *
  * DESCRIPTION
  *  Procédure pour afficher les valeurs de parametres du traitement
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
  
    dka_tools_pkg.put_outdebug_message( 'PARAMETRES : ');
    dka_tools_pkg.put_outdebug_message( '--------------');
    dka_tools_pkg.put_log_message( 'PARAMETRES : ');
    dka_tools_pkg.put_log_message( '--------------');
  
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
    
      dka_tools_pkg.put_outdebug_message(
                        rec_parameters.form_left_prompt || ' : ' ||
                        v_argument_value);
      dka_tools_pkg.put_log_message(
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
      
        dka_tools_pkg.put_outdebug_message(
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
        dka_tools_pkg.put_log_message(
                          rec_parameters.form_left_prompt || ' : ' ||
                          v_argument_value);
      END LOOP;
    
      dka_tools_pkg.put_outdebug_message( CHR(10));
    
    ELSE
      dka_tools_pkg.put_outdebug_message( 'Aucun argument');
      dka_tools_pkg.put_log_message( 'Aucun argument');
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
  
    dka_tools_pkg.put_outdebug_message( cv_line || CHR(10));
    dka_tools_pkg.put_outdebug_message(
                      'Programme terminé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    dka_tools_pkg.put_outdebug_message( cv_line);
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
  
    /*CURSOR cur_prog_mess IS
      SELECT USER_NAME,LOGICAL_LINE_NUM,MESSAGE
        FROM DKA_REP_RESP
       WHERE STATUS   = 'ERROR'
       AND LOAD_REQUEST_ID = DECODE(g_loader_request_id,-1,load_request_id,g_loader_request_id)
       ;*/
       
    CURSOR cur_prog_mess IS
      SELECT *
        FROM DKA_PROGRAM_MESSAGES
       WHERE REQUEST_ID = g_request_id
        ;       
  
  
  BEGIN
    
    dka_tools_pkg.put_outdebug_message( CHR(10));
    dka_tools_pkg.put_outdebug_message(
                      'LISTE DES ANOMALIES :');
    dka_tools_pkg.put_outdebug_message(
                      '----------------------------------------');
  
    dka_tools_pkg.put_outdebug_message( 'Utilisateur        Ligne    Message');
    dka_tools_pkg.put_outdebug_message( '---------------    -----    -------');
  
    FOR msg IN cur_prog_mess LOOP
      dka_tools_pkg.put_outdebug_message(
                        RPAD(msg.column_value, 15, ' ') || '    ' ||
                        RPAD(NVL(TO_CHAR(msg.table_id), ' '), 5, ' ') || '    ' ||
                        msg.message_text
                        );
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_log_message( 'LAUNCH_LOADER : ' || SQLERRM);
      dka_tools_pkg.put_log_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure print_errors : EXCEPTION OTHERS ');
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
   * p_file_name       Nom du fichier a charger
   * p_errbuf          Retour de message éventuel
   * p_retcode         STATUS du traitement en sortie
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
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Launch_Loader');
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Lancement de chargement du fichier dans la table d''interface spécifique : ');
  
    dka_tools_pkg.put_outdebug_message( CHR(10));
    dka_tools_pkg.put_outdebug_message( 'CHARGEMENT DU FICHIER :');
    dka_tools_pkg.put_outdebug_message( '----------------------');
    ------------------------------------------------------
    -- Lancement du traitement de chargement du fichier --
    ------------------------------------------------------
    -- Positionnement des options d'impression
    b_result := fnd_request.set_print_options(printer => gv_printer,
                                              copies  => g_number_of_copies);
    -- Lancement du traitement
    g_loader_request_id := Fnd_Request.submit_request('DKA' -- APPL
                                                     ,
                                                      'DKA_LOADER_REPFNDRESP' -- PROG
                                                     ,
                                                      NULL -- PROGRAM_NAME
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                      );
  
    IF g_loader_request_id = 0 THEN
      p_retcode := 2;
      dka_tools_pkg.put_log_message(
                        'ERREUR : Le traitement de chargement du fichier a échoué' ||
                        CHR(10) || 'PROGRAMME  : DKA_LOADER_REPFNDRESP' ||
                        CHR(10));
      dka_tools_pkg.put_outdebug_message(
                        '====> ERREUR : Le traitement de chargement du fichier a échoué');
    ELSE
      COMMIT;
      dka_tools_pkg.put_log_message(
                        '=> LOAD REQUEST ID= ' || g_loader_request_id);
      dka_tools_pkg.put_outdebug_message(
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
        dka_tools_pkg.put_log_message(
                          'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
      END IF;
    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        dka_tools_pkg.put_log_message(
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        dka_tools_pkg.put_outdebug_message(
                          '. STATUS de fin : ' || v_phase || '/' ||
                          v_status);
      
        UPDATE DKA_REP_RESP
           SET load_request_id = g_loader_request_id
         WHERE load_request_id IS NULL;
      
        SELECT COUNT(*)
          INTO g_summary.loaded_rows
          FROM DKA_REP_RESP
         WHERE load_request_id = g_loader_request_id;
        dka_tools_pkg.put_log_message(
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                          ' Nbre enregistrements charges => ' ||
                          g_summary.loaded_rows);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        dka_tools_pkg.put_log_message(
                          'Fin du traitement de chargement en warning ' ||
                          g_loader_request_id);
        p_retcode := 1;
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        p_retcode := 2;
        p_errbuf  := 'ERREUR : Fin anormale du traitement de chargement : ' ||
                     v_Message;
      
        dka_tools_pkg.put_log_message(
                          'ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id || CHR(10) ||
                          'Phase/STATUS : ' || v_dev_phase || '/' ||
                          v_dev_status || CHR(10) || 'MESSAGE : ' ||
                          v_message || CHR(10));
        dka_tools_pkg.put_outdebug_message(
                          '===> ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id);
      END IF;
    
    END IF;
  
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Launch_Loader');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'LAUNCH_LOADER : ' || SQLERRM;
      dka_tools_pkg.put_log_message( p_errbuf);
      dka_tools_pkg.put_log_message(
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
   * p_retcode           STATUS du traitement en sortie
   ************************************************************************
   */

  PROCEDURE validate_data(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    CURSOR cur_resp IS
      SELECT *
        FROM DKA_REP_RESP
       WHERE LOAD_REQUEST_ID =
             DECODE(g_loader_request_id,
                    -1,
                    load_request_id,
                    g_loader_request_id)
         AND STATUS IS NULL
         FOR UPDATE;
  
      lv_msg              VARCHAR2(500);  
      v_flag_erreur       BOOLEAN := FALSE;
      vv_err_msg          VARCHAR2(500);
      vd_date             DATE;
      vv_exist            VARCHAR2(1);
  
  BEGIN
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début validate_data');
                      
                      
     FOR rec IN cur_resp LOOP 
     
        v_flag_erreur := FALSE;
        -- RGI09 : Si date début est non renseigné, elle prend la date du jour
        
        IF rec.START_DATE IS NULL THEN
            vd_date := sysdate;
        ELSE  
            vd_date := rec.START_DATE;
        END IF;
        
        -- RGI10 : Vérification si lien déjà existant 
        BEGIN  
        
          SELECT 'Y'
          INTO vv_exist
          FROM FND_USER_RESP_GROUPS a, FND_USER b, FND_RESPONSIBILITY_VL c
          WHERE a.user_id = b.user_id
          AND b.user_name = rec.user_name
          AND a.responsibility_id = c.responsibility_id
          AND c.RESPONSIBILITY_NAME = rec.RESPONSIBILITY_NAME
          ;
          
          v_flag_erreur := TRUE;
          vv_err_msg := 'La responsabilité ' || rec.RESPONSIBILITY_NAME ||' est déjà attribué à l''utilisateur '|| rec.user_name ||'.';
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFNDRESP',
                                         'ETL',
                                         'DKA_REP_RESP',
                                         rec.logical_line_num,
                                         'RESPONSIBILITY_NAME',
                                         rec.user_name,
                                         'E',
                                         'La responsabilité ' || rec.RESPONSIBILITY_NAME ||' est déjà attribué à l''utilisateur '|| rec.user_name ||'.');
          
          
        EXCEPTION
          WHEN OTHERS THEN
            NULL;
        END;
        
        
        -- RGI11 : Vérification validité responsabilité
        BEGIN  
        
          SELECT 'Y'
          INTO vv_exist
          FROM FND_RESPONSIBILITY_VL
          WHERE RESPONSIBILITY_NAME = rec.RESPONSIBILITY_NAME
          AND start_date <= nvl(end_date,sysdate)
          ; 
          
        EXCEPTION
          WHEN OTHERS THEN
          
          v_flag_erreur := TRUE;
          vv_err_msg := 'La responsabilité ' || rec.RESPONSIBILITY_NAME ||' n''est pas valide.';
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFNDRESP',
                                         'ETL',
                                         'DKA_REP_RESP',
                                         rec.logical_line_num,
                                         'RESPONSIBILITY_NAME',
                                         rec.user_name,
                                         'E',
                                         'La responsabilité ' || rec.RESPONSIBILITY_NAME ||' n''est pas valide.');          
          
        END;  

        -- Vérification si utilisateur existe
        BEGIN  
        
          SELECT 'Y'
          INTO vv_exist
          FROM fnd_user
          WHERE user_name = rec.user_name
          AND ROWNUM = 1
          ; 
          
        EXCEPTION
          WHEN OTHERS THEN
          
          v_flag_erreur := TRUE;
          vv_err_msg := 'User ' || rec.user_name ||' inexistant, impossible de lui affecter des responsabilités.';
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFNDRESP',
                                         'ETL',
                                         'DKA_REP_RESP',
                                         rec.logical_line_num,
                                         'USER_NAME',
                                         rec.user_name,
                                         'E',
                                         'User ' || rec.user_name ||' inexistant, impossible de lui affecter des responsabilités.');
          
        END;  
        
        -- Vérification si nom d'application existe
        BEGIN  
        
          SELECT 'Y'
          INTO vv_exist
          FROM FND_APPLICATION_TL
          WHERE APPLICATION_NAME = rec.APPLICATION_NAME
          AND LANGUAGE = 'F'
          AND ROWNUM = 1
          ; 
          
        EXCEPTION
          WHEN OTHERS THEN
          
          v_flag_erreur := TRUE;
          vv_err_msg := 'Application "' || rec.APPLICATION_NAME ||'" de la responsabilité inexistante.';
          dka_tools_pkg.ins_prog_message(g_request_id,
                                         'DKA_REPFNDRESP',
                                         'ETL',
                                         'DKA_REP_RESP',
                                         rec.logical_line_num,
                                         'APPLICATION_NAME',
                                         rec.user_name,
                                         'E',
                                         'Application "' || rec.APPLICATION_NAME ||'" de la responsabilité inexistante.');
          
        END;          
      
        
      IF NOT v_flag_erreur THEN                  
         UPDATE DKA_REP_RESP diu
          SET
           START_DATE = vd_date
          ,STATUS     = 'PENDING'
          ,MESSAGE    = NULL
         WHERE CURRENT OF cur_resp;        
      ELSE
         UPDATE DKA_REP_RESP diu
          SET STATUS     = 'ERROR'
             ,MESSAGE    = vv_err_msg
         WHERE CURRENT OF cur_resp;
         
         g_summary.rejected_rows := g_summary.rejected_rows + 1;          
      END IF;
          
     END LOOP;

    COMMIT;
    
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin validate_data');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'VALIDATE_DATA : ' || SQLERRM;
      dka_tools_pkg.put_log_message( p_errbuf);
      dka_tools_pkg.put_log_message(
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
 * p_retcode           STATUS du traitement en sortie
 ************************************************************************
 */

 PROCEDURE create_data(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
  CURSOR c_select IS 
   SELECT dka_resp.user_name, 
          dka_resp.APPLICATION_NAME,
          fnda.application_short_name,
          dka_resp.RESPONSIBILITY_NAME, 
          dka_resp.start_date, 
          dka_resp.end_date, 
          dka_resp.status, 
          dka_resp.message, 
          fnd_resp.responsibility_key 
   FROM DKA_REP_RESP dka_resp, fnd_responsibility_vl fnd_resp, FND_APPLICATION_TL fndatl, FND_APPLICATION fnda
   WHERE dka_resp.STATUS = 'PENDING'
   AND dka_resp.RESPONSIBILITY_NAME = fnd_resp.RESPONSIBILITY_NAME
   AND fndatl.application_id = fnda.application_id
   AND fndatl.APPLICATION_NAME = dka_resp.APPLICATION_NAME
   AND fndatl.language = 'F'
   AND dka_resp.LOAD_REQUEST_ID = DECODE(g_loader_request_id,
                                -1,
                                dka_resp.load_request_id,
                                g_loader_request_id)
   FOR UPDATE OF dka_resp.status, dka_resp.message
   ;
  
  vv_err_msg        VARCHAR2(500);
  v_flag_erreur       BOOLEAN := FALSE;

  
 BEGIN
 
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début create_data');
    
    dka_tools_pkg.put_log_message('Boucle des utilisateurs au STATUS PENDING');
    FOR l in c_select LOOP
      v_flag_erreur := FALSE;
       BEGIN

           FND_USER_PKG.addresp(username        => l.user_name,
                                resp_app        => l.application_short_name,
                                resp_key        => l.responsibility_key,
                                security_group  => 'STANDARD',
                                description     => l.RESPONSIBILITY_NAME,
                                start_date      => l.start_date,
                                end_date        => l.end_date);
           
           g_summary.inserted_rows := g_summary.inserted_rows + 1;

         
          UPDATE DKA_REP_RESP
          SET 
           STATUS  = 'ACCEPTED'
          ,MESSAGE = 'RESPONSIBILITY LINKED' 
          WHERE CURRENT OF c_select;
    
         
        EXCEPTION
         WHEN OTHERS THEN
         
              vv_err_msg := SQLERRM;
              dka_tools_pkg.put_log_message('Erreur création du lien pour la responsabilité '||l.RESPONSIBILITY_NAME||' : '||vv_err_msg);
              v_flag_erreur := TRUE;
        END;
        
      
        IF v_flag_erreur THEN
        
              UPDATE DKA_REP_RESP
              SET 
               STATUS = 'ERROR',
               MESSAGE = vv_err_msg
              WHERE CURRENT OF c_select;        
              
              g_summary.rejected_rows := g_summary.rejected_rows + 1;
        END IF;
        
        
     END LOOP;
     
     COMMIT;
     
     dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin create_data');
     
 EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'create_data : ' || SQLERRM;
      dka_tools_pkg.put_log_message( p_errbuf);
      dka_tools_pkg.put_log_message(
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
   * p_retcode           STATUS du traitement en sortie
   ************************************************************************
   */
  PROCEDURE Report_Bilan(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
  BEGIN
  
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Report_Bilan');
  
    --------------------
    -- Initialisation --
    --------------------
    
  
    p_errbuf  := NULL;
    p_retcode := 0;
  
    dka_tools_pkg.put_outdebug_message( CHR(10));
    dka_tools_pkg.put_outdebug_message( 'BILAN :');
    dka_tools_pkg.put_outdebug_message( '-------');
    dka_tools_pkg.put_outdebug_message(
                      '   . Nombre d''enregistrements chargés dans la table spécifique   : ' ||
                      TO_CHAR(g_summary.loaded_rows));
    dka_tools_pkg.put_outdebug_message(
                      '   . Nombre de liens créés                                       : ' ||
                      TO_CHAR(g_summary.inserted_rows));
    dka_tools_pkg.put_outdebug_message(
                      '   . Nombre de liens KO                                          : ' ||
                      TO_CHAR(g_summary.rejected_rows));
  
    
    dka_tools_pkg.put_outdebug_message( CHR(10));
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Report_Bilan');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'REPORT_BILAN : ' || SQLERRM;
      dka_tools_pkg.put_log_message( p_errbuf);
      dka_tools_pkg.put_log_message(
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
  
    UPDATE DKA_REP_RESP SET STATUS = NULL WHERE STATUS = 'ERROR';
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'SET_RECOVERY_MODE : ' || SQLERRM;
      dka_tools_pkg.put_log_message( p_errbuf);
      dka_tools_pkg.put_log_message(
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
  
    dka_tools_pkg.put_log_message( '-> DKA_REP_RESP');
    DELETE FROM DKA_REP_RESP;
    dka_tools_pkg.put_log_message(
                      '=> Deleted rows ' || TO_CHAR(SQL%ROWCOUNT));
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'PURGE_DATA : ' || SQLERRM;
      dka_tools_pkg.put_log_message( p_errbuf);
      dka_tools_pkg.put_log_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure PURGE_DATA : EXCEPTION OTHERS ');
  END purge_data;

  /*
   *************************************************************************
   * PROCEDURE NAME : main
   *
   * DESCRIPTION
   *  Procédure principale du traitement de reprise des utilisateurs
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        STATUS du traitement en sortie
   * p_reprise        Reprise du traitement (N = Chargement du fichier)
   ************************************************************************
   */

  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
                 p_reprise IN VARCHAR2) IS
  
    v_current_program_unit VARCHAR2(30);
    v_errbuf               VARCHAR2(2500);
    v_retcode              NUMBER;
    
    Erreur_Programme EXCEPTION;
  
  BEGIN
  
    ----------------------------
    -- PHASE D'INITIALISATION --
    ----------------------------
  
    v_current_program_unit := 'main';
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'DEBUT DE L''INTERFACE');
  
    Output_Header;
    Request_parameters;
  
    dka_tools_pkg.put_log_message(
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

   IF p_reprise = 'N' THEN
        -------------------------------------------
        -- PHASE DE PURGE DES ANCIENNES DONNEES  --
        -------------------------------------------
        /*dka_tools_pkg.put_log_message(
                          TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                          'PURGE DES DONNEES');
        purge_data(v_errbuf, v_retcode);
        IF v_retcode = 2 THEN
          p_Errbuf  := v_errbuf;
          p_retcode := v_retcode;
          RAISE Erreur_Programme;
        END IF;*/

        ------------------------------------
        -- PHASE DE CHARGEMENT DU FICHIER --
        ------------------------------------
        dka_tools_pkg.put_log_message(
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
    
    IF g_summary.loaded_rows != 0 OR p_reprise = 'Y' THEN
      -------------------------------------
      -- PHASE DE VALIDATION DES DONNEES --
      -------------------------------------
      dka_tools_pkg.put_log_message(
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
      dka_tools_pkg.put_log_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'PHASE DE CREATION DES DONNEES');
    
      -- Lancement du programme de chargement
      create_data(v_errbuf, v_retcode);
      IF v_retcode = 2 THEN
        p_errbuf  := v_errbuf;
        p_retcode := v_retcode;
        RAISE Erreur_Programme;
      END IF;
  
    END IF;
  
    ----------------------------------
    -- PHASE DE BILAN DU TRAITEMENT --
    ----------------------------------
  
    Report_Bilan(v_errbuf, v_retcode);
  
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      --RAISE Erreur_Programme;
    END IF;
  
    -------------------------
    -- PHASE DES ANOMALIES --
    -------------------------
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE DES ANOMALIES');
  
    print_errors;
  
    ---------------------------------------
    -- PHASE DE FIN DU TRAITEMENT MAITRE --
    ---------------------------------------
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
    ELSIF (g_summary.rejected_rows > 0) THEN
      p_errbuf  := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
      p_retcode := 1;
    ELSIF (g_summary.loaded_rows = 0) THEN
      p_errbuf  := 'ATTENTION : Aucun enregistrement chargé.';
      p_retcode := 1;
    ELSE
      p_errbuf  := 'Fin normale du traitement - Aucun rejet.';
      p_retcode := 0;
    END IF;
  
    dka_tools_pkg.put_log_message( p_errbuf);
    dka_tools_pkg.put_outdebug_message( CHR(10) || p_errbuf || CHR(10));
    output_end;
    dka_tools_pkg.put_log_message(
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'FIN DE L''INTERFACE');
  
  EXCEPTION
    WHEN Erreur_Programme THEN
      p_retcode := 2;
      p_errbuf  := v_errbuf;
      dka_tools_pkg.put_log_message( p_errbuf);
      dka_tools_pkg.put_outdebug_message( CHR(10) || p_errbuf);
      dka_tools_pkg.put_log_message(
                        TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure ' || v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
      dka_tools_pkg.put_outdebug_message(
                        '==> Fin de la procédure ' ||
                        v_current_program_unit ||
                        ' : EXCEPTION Erreur_Traitement ');
    WHEN OTHERS THEN
      fnd_concurrent.af_rollback;
      p_retcode := 2;
      dka_tools_pkg.put_log_message(
                        'Erreur technique sur le composant   : ' ||
                        'DKA_REPFNDRESP_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      dka_tools_pkg.put_outdebug_message(
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END main;

END DKA_REPFNDRESP_PKG;
/
SHOW ERRORS
EXIT
