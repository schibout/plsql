SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE BODY DKA_SAPEXTSTATFAC_PKG IS
  --------------------------------------------------------------------------------------------
  -- FILENAME
  --    DKA_SAPEXTSTATFAC_PKG.pkb  V1.0
  --
  -- AUTEUR
  --    Capgemini
  --
  -- DESCRIPTION
  --    Création du package du traitement d'extraction du statut des factures fournisseurs 
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
  -- V1.0    04/05/2017     OBE Creation
  ---------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  TYPE summary_typ IS RECORD(
    loaded_rows            NUMBER -- Nb de Lignes chargées en table spécifique
    ,
    inserted_rows          NUMBER
    ,
    updated_rows          NUMBER -- Nb de lignes rejetées en table spécifique
    );

  g_summary summary_typ;

  g_user_id              fnd_user.user_id%TYPE;
  g_login_id             fnd_logins.login_id%TYPE;
  g_org_id               hr_all_organization_units.organization_id%TYPE;
  g_request_id           fnd_concurrent_requests.request_id%TYPE;
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
    g_summary.updated_rows          := 0;
  
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
  
  CURSOR cur_invoices IS
    SELECT *
      FROM AP_INVOICES_ALL 
       ;
  
  
  vv_status        VARCHAR2(50);
  vv_status_trans  VARCHAR2(50);
  vv_exist         VARCHAR2(1);
  
  BEGIN
  
      Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début create_data');

      FOR rec in cur_invoices LOOP


         vv_status := ap_invoices_utility_pkg.get_approval_status(rec.invoice_id,rec.invoice_amount,rec.payment_status_flag,rec.invoice_type_lookup_code);
         
         BEGIN
           SELECT meaning
           INTO vv_status_trans
           FROM FND_LOOKUP_VALUES_VL
           WHERE lookup_type = 'NLS TRANSLATION' 
           AND lookup_code = vv_status;
         EXCEPTION
          WHEN NO_DATA_FOUND THEN
             SELECT meaning
             INTO vv_status_trans
             FROM FND_LOOKUP_VALUES_VL
             WHERE lookup_code = vv_status
             AND ROWNUM = 1;
         END
         ;
          
          BEGIN
            
            -- Si facture déjà existante dans la table, mise à jour de la ligne avec le nouveau statut.
            SELECT 'Y'
            INTO vv_exist
            FROM DKA_SAP_STATUT_FACTURE
            WHERE INVOICE_ID = rec.invoice_id
            ;
            
            UPDATE DKA_SAP_STATUT_FACTURE
            SET STATUT_FACTURE = vv_status_trans
               ,LAST_UPDATE_DATE = sysdate
               ,LAST_UPDATED_BY = g_login_id
            WHERE INVOICE_ID = rec.invoice_id
            ;
            
            g_summary.updated_rows := g_summary.updated_rows + 1; 
    
            
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
                  
                  -- Sinon, insertion d'une nouvelle ligne.
                  
                  INSERT INTO DKA_SAP_STATUT_FACTURE
                  (INVOICE_ID
                  ,INVOICE_NUM
                  ,ORG_ID
                  ,STATUT_FACTURE
                  ,CREATION_DATE
                  ,CREATED_BY
                  ,LAST_UPDATE_DATE
                  ,LAST_UPDATED_BY
                  )VALUES
                  (rec.invoice_id
                  ,rec.invoice_num
                  ,rec.org_id
                  ,vv_status_trans
                  ,sysdate
                  ,g_login_id
                  ,sysdate
                  ,g_login_id
                  )
                  ;
                  
                  g_summary.inserted_rows := g_summary.inserted_rows + 1; 

          END;
             

        
      END LOOP;    

    COMMIT;
  
        Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin create_data');
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
                      '   . Nombre de lignes créées                                    : ' ||
                      TO_CHAR(g_summary.inserted_rows));
    fnd_file.put_line(fnd_file.OUTPUT,
                      '   . Nombre de lignes mises à jour                              : ' ||
                      TO_CHAR(g_summary.updated_rows));
  
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
  

    ----------------------------------
    -- PHASE DE BILAN DU TRAITEMENT --
    ----------------------------------
  
    Report_Bilan(v_errbuf, v_retcode);
  
    IF v_retcode = 2 THEN
      p_errbuf  := v_errbuf;
      p_retcode := v_retcode;
      --RAISE Erreur_Programme;
    END IF;
  
  
    ---------------------------------------
    -- PHASE DE FIN DU TRAITEMENT MAITRE --
    ---------------------------------------
    IF p_retcode = 2 THEN
      p_errbuf := 'ATTENTION : Erreur bloquante : ' || p_errbuf;
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
                        'DKA_SAPEXTSTATFAC_PKG.' || v_current_program_unit ||
                        CHR(10) || 'A retourné     : ' || SQLERRM);
      Fnd_File.put_line(Fnd_File.Output,
                        CHR(10) ||
                        '==> Erreur technique (voir journal du traitement)' ||
                        CHR(10));
      p_errbuf := SQLERRM;
  END main;

END DKA_SAPEXTSTATFAC_PKG;
/
SHOW ERRORS
EXIT
