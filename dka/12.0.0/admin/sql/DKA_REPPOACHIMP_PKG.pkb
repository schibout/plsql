SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_REPPOACHIMP_PKG IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_REPPOACHIMP_PKG.pkb  V1.0
  --
  -- AUTEUR
  --    Capgemini
  --
  -- DESCRIPTION
  --    Création du package de l'interface specifique des acheteurs
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
  -- V1.0    07/11/2016     OBE Creation
  ---------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  TYPE summary_typ IS RECORD(
    loaded_rows            NUMBER -- Nb de Lignes chargées en table spécifique
    ,
    inserted_rows          NUMBER
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
    g_summary.inserted_rows          := 0;
    g_summary.rejected_rows          := 0;
  
    -- Formatage de la date comptable
    --g_gl_date := TRUNC(fnd_date.canonical_to_date(p_gl_date));
  
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
  
  
  BEGIN
    
    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT,
                      'LISTE DES ANOMALIES :');
    fnd_file.put_line(fnd_file.OUTPUT,
                      '----------------------------------------');
    fnd_file.put_line(fnd_file.OUTPUT, 'Acheteur        Ligne    Message');
    fnd_file.put_line(fnd_file.OUTPUT, '------------    -----    -------');
  
    FOR msg IN cur_prog_mess LOOP

      Fnd_File.put_line(Fnd_File.output,
                        RPAD(msg.column_value, 12, ' ') || '    ' ||
                        RPAD(NVL(msg.table_id, ' '), 5, ' ') || '    ' ||
                        msg.message_text);
    END LOOP;
  
  
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
                                                      'DKA_LOADER_REPPOACHIMP' -- PROG
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
      
        UPDATE DKA_REP_ACHETEURS
           SET load_request_id = g_loader_request_id
         WHERE load_request_id IS NULL;
      
        SELECT COUNT(*)
          INTO g_summary.loaded_rows
          FROM DKA_REP_ACHETEURS
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
  
    CURSOR cur_acheteurs IS
      SELECT full_name, employee_number, rowid rid, logical_line_num
        FROM DKA_REP_ACHETEURS
       WHERE LOAD_REQUEST_ID =
             DECODE(g_loader_request_id,
                    -1,
                    load_request_id,
                    g_loader_request_id)
         AND STATUT IS NULL;
  
    v_flag_erreur       BOOLEAN := FALSE;
    l_agent_id          NUMBER;
  
  BEGIN
  
    FOR acheteur IN cur_acheteurs LOOP
      v_flag_erreur := FALSE;
    
      BEGIN
        IF acheteur.employee_number IS NOT NULL THEN
          select person_id into l_agent_id from per_all_people_f where full_name = acheteur.full_name and employee_number = acheteur.employee_number;
        ELSE
          select person_id into l_agent_id from per_all_people_f where full_name = acheteur.full_name;
        END IF;
        UPDATE DKA_REP_ACHETEURS SET AGENT_ID = l_agent_id, STATUT = 'OK' WHERE rowid = acheteur.rid;
      EXCEPTION
        WHEN OTHERS THEN
        Fnd_File.put_line (Fnd_File.LOG,substr('Impossible de retrouver l''ID de l''employé '||acheteur.full_name||'(matricule='||acheteur.employee_number||'). Erreur='||SQLERRM, 1, 400));
         dka_tools_pkg.ins_prog_message(
          g_request_id
         ,'DKA_REPPOACHIMP'
         ,'ETL'
         ,'DKA_REP_ACHETEURS'
         ,acheteur.logical_line_num
         ,'FULL_NAME'
         ,acheteur.employee_number
         ,'E'
         ,SUBSTR('Impossible de retrouver l''ID de l''employé '||acheteur.full_name||'(matricule='||acheteur.employee_number||'). Erreur='||SQLERRM, 1, 400)
         );         
        l_agent_id := null;
        UPDATE DKA_REP_ACHETEURS SET STATUT = 'KO' WHERE rowid = acheteur.rid;
        g_summary.rejected_rows := g_summary.rejected_rows + 1;
      END;
    
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
  
  CURSOR cur_acheteurs IS
    SELECT full_name, employee_number, rowid rid, agent_id, logical_line_num
      FROM DKA_REP_ACHETEURS
     WHERE LOAD_REQUEST_ID = DECODE(g_loader_request_id,
                                    -1,
                                    load_request_id,
                                    g_loader_request_id)
       AND STATUT = 'OK';
  
  TYPE t_acheteurs IS TABLE OF cur_acheteurs%ROWTYPE INDEX BY PLS_INTEGER;
  rec_acheteurs t_acheteurs;
  
  l_rowid     VARCHAR2(400);
  --l_agent_id  NUMBER;

  
  BEGIN
  
    
    OPEN cur_acheteurs;
    FETCH cur_acheteurs BULK COLLECT INTO rec_acheteurs;
    CLOSE cur_acheteurs;
    
    IF rec_acheteurs.count > 0 THEN
      FOR i in rec_acheteurs.FIRST .. rec_acheteurs.LAST LOOP
        BEGIN

              PO_AGENTS_PKG.Insert_Row(X_Rowid               => l_rowid,
                                       X_Agent_Id            => rec_acheteurs(i).agent_id,--l_agent_id,
                                       X_Last_Update_Date    => sysdate,
                                       X_Last_Updated_By     => g_user_id,
                                       X_Last_Update_Login   => -1,
                                       X_Creation_Date       => sysdate,
                                       X_Created_By          => g_user_id,
                                       X_Location_ID		     => null,
                                       X_Category_ID		     => null,
                                       X_Authorization_Limit => null,
                                       X_Start_Date_Active   => sysdate,
                                       X_End_Date_Active	   => null,
                                       X_Attribute_Category	 => null,
                                       X_Attribute1			     => null,
                                       X_Attribute2			     => null,
                                       X_Attribute3			     => null,
                                       X_Attribute4			     => null,
                                       X_Attribute5			     => null,
                                       X_Attribute6			     => null,
                                       X_Attribute7			     => null,
                                       X_Attribute8			     => null,
                                       X_Attribute9			     => null,
                                       X_Attribute10			   => null,
                                       X_Attribute11			   => null,
                                       X_Attribute12			   => null,
                                       X_Attribute13			   => null,
                                       X_Attribute14			   => null,
                                       X_Attribute15			   => null);
            UPDATE DKA_REP_ACHETEURS SET STATUT = 'TT' WHERE rowid = rec_acheteurs(i).rid;
            g_summary.inserted_rows := g_summary.inserted_rows + 1;
          --COMMIT;

          EXCEPTION
          WHEN OTHERS THEN
            Fnd_File.put_line (Fnd_File.LOG,'Erreur API pour employé '||rec_acheteurs(i).full_name||'(matricule='||rec_acheteurs(i).employee_number||'). Erreur='||SQLERRM);
            dka_tools_pkg.ins_prog_message(
              g_request_id
             ,'DKA_REPPOACHIMP'
             ,'ETL'
             ,'DKA_REP_ACHETEURS'
             ,rec_acheteurs(i).logical_line_num
             ,'FULL_NAME'
             ,rec_acheteurs(i).employee_number
             ,'E'
             ,'Erreur API pour employé '||rec_acheteurs(i).full_name||'(matricule='||rec_acheteurs(i).employee_number||'). Erreur='||SQLERRM
             );   
          UPDATE DKA_REP_ACHETEURS SET STATUT = 'KO' WHERE rowid = rec_acheteurs(i).rid;
          g_summary.rejected_rows := g_summary.rejected_rows + 1;
          --ROLLBACK;
        END;
      END LOOP;
    END IF;    

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
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''enregistrements chargés dans la table spécifique : ' ||
                      TO_CHAR(g_summary.loaded_rows));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''acheteurs créés                                  : ' ||
                      TO_CHAR(g_summary.inserted_rows));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre d''acheteurs KO                                     : ' ||
                      TO_CHAR(g_summary.rejected_rows));
  
    --fnd_file.put_line(fnd_file.OUTPUT,
                      --'Voir les sorties des traitements d''Open interface pour avoir plus de détails sur les enregistrements rejetés.');
  
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
  
    UPDATE DKA_REP_ACHETEURS SET STATUT = NULL WHERE STATUT = 'KO';
  
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
  
    Fnd_File.Put_Line(Fnd_File.LOG, '-> DKA_REP_ACHETEURS');
    DELETE FROM DKA_REP_ACHETEURS;
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
    
    IF g_summary.loaded_rows != 0 OR p_reprise = 'Y' THEN
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
    Fnd_File.put_line(Fnd_File.LOG,
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
                        'DKA_REPPOACHIMP_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END main;

END DKA_REPPOACHIMP_PKG;
/
SHOW ERRORS
EXIT
