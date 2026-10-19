CREATE OR REPLACE PACKAGE BODY dka_rep_int_tecpca_pkg IS
  --------------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_REP_EXT_TECPCA_PKG.pkb
  -- Description      : DKA_REP_EXT_TECPCA_PKG package body
  -- Auteur           : B.Delattre(Capgemini)
  -- Date de création : 26/04/2016
  -- Doc. associée    :
  -- Commentaire      : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 17/07/2016 JJA Ajout du paramètre date, mise en forme et correction
  -- 24/10/2016 NBO Optimisation des extractions
  -- 09/11/2016 NBO artf2042215 - Extraction des coûts PA - Transcodification et lignes à zéro
  -- 06/01/2017 NBO artf2076186 - defect #451 Extraction des coûts projet - Coût direct et coût complet alimenté avec la quantité pour DRW et DSW
  -- 18/01/2017 NBO artf2084393 - Extraction des coûts projet - Les données extraites ne sont pas filtrées par rapport à la date passée en paramétre
  --------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_printer          fnd_concurrent_requests.printer%TYPE;
  g_number_of_copies  fnd_concurrent_requests.number_of_copies%TYPE;
  g_loader_request_id fnd_concurrent_requests.request_id%TYPE;

  gv_statut_ok       VARCHAR2(20) := 'OK';
  gv_statut_new      VARCHAR2(20) := 'NEW';
  gv_statut_valid    VARCHAR2(20) := 'VALID';
  gv_statut_invalid  VARCHAR2(20) := 'INVALID';
  gv_statut_rejected VARCHAR2(20) := 'REJECTED';

  g_nb_event_nonvalide NUMBER := 0;

  g_nb_event_cree    NUMBER := 0;
  g_nb_event_charger NUMBER := 0;
  g_nb_event_rejete  NUMBER := 0;

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
  PROCEDURE launch_loader(p_errbuf       OUT VARCHAR2,
                          p_retcode      OUT NUMBER,
                          p_process_file IN VARCHAR2) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
    b_result     BOOLEAN;
  
  BEGIN
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Début Launch_Loader');
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Lancement de chargement du fichier dans la table d''interface spécifique : ');
  
    fnd_file.put_line(fnd_file.output, chr(10));
    fnd_file.put_line(fnd_file.output, 'CHARGEMENT DU FICHIER :');
    fnd_file.put_line(fnd_file.output, '----------------------');
    ------------------------------------------------------
    -- Lancement du traitement de chargement du fichier --
    ------------------------------------------------------
    -- Positionnement des options d'impression
    b_result := fnd_request.set_print_options(printer => gv_printer,
                                              copies  => g_number_of_copies);
    -- Lancement du traitement
    g_loader_request_id := fnd_request.submit_request('DKA' -- APPL
                                                     ,
                                                      'DKA_LOADER_REPINTTECPCA' -- PROG
                                                     ,
                                                      NULL -- PROGRAM_NAME
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                     ,
                                                      p_process_file);
  
    IF g_loader_request_id = 0 THEN
      p_retcode := 2;
      fnd_file.put_line(fnd_file.log,
                        'ERREUR : Le traitement de chargement du fichier a échoué' ||
                        chr(10) || 'PROGRAMME  : DKA_LOADER_REPFAIMOIMP'
                        --'FICHIER : ' || p_file_name || CHR(10)
                        );
      fnd_file.put_line(fnd_file.output,
                        '====> ERREUR : Le traitement de chargement du fichier a échoué');
    ELSE
      COMMIT;
      fnd_file.put_line(fnd_file.log,
                        '=> LOAD REQUEST ID= ' || g_loader_request_id);
      fnd_file.put_line(fnd_file.output,
                        '. Numéro du traitement de chargement du fichier : ' ||
                        g_loader_request_id);
    
      -- Attente de la fin du traitement
      IF NOT (fnd_concurrent.wait_for_request(g_loader_request_id,
                                              60,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        p_errbuf := v_message;
        fnd_file.put_line(fnd_file.log,
                          'ERREUR : Attente de la fin du programme de chargement du fichier dépassée : Fin du traitement' ||
                          chr(10) || 'MESSAGE : ' || v_message || chr(10));
      END IF;
    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        fnd_file.put_line(fnd_file.log,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        fnd_file.put_line(fnd_file.output,
                          '. Statut de fin : ' || v_phase || '/' ||
                          v_status);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        fnd_file.put_line(fnd_file.log,
                          'Fin du traitement de chargement en warning ' ||
                          g_loader_request_id);
        p_retcode := 1;
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        p_retcode := 2;
        p_errbuf  := 'ERREUR : Fin anormale du traitement de chargement : ' ||
                     v_message;
      
        fnd_file.put_line(fnd_file.log,
                          'ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id || chr(10) ||
                          'Phase/Statut : ' || v_dev_phase || '/' ||
                          v_dev_status || chr(10) || 'MESSAGE : ' ||
                          v_message || chr(10));
        fnd_file.put_line(fnd_file.output,
                          '===> ERREUR : Fin anormale du traitement de chargement ' ||
                          g_loader_request_id);
      END IF;
    
    END IF;
  
    SELECT COUNT(*)
      INTO g_nb_event_charger
      FROM dka.dka_maj_indicateurs_tecpca;
  
    fnd_file.put_line(fnd_file.log,
                      to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'Fin Launch_Loader');
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'LAUNCH_LOADER : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure Launch_Loader : EXCEPTION OTHERS ');
  END launch_loader;

  /*
   *************************************************************************
   * PROCEDURE NAME : validate_data
   *
   * DESCRIPTION
   *  Procédure de validation des données
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
  
    v_code_projet_new VARCHAR2(100);
    v_tache_new       VARCHAR2(100);
    lv_errmsg         VARCHAR2(1000);
    l_step            VARCHAR2(50);
    l_count           NUMBER;
  
    CURSOR cur_data IS
      SELECT dk.*, dk.ROWID rid
        FROM dka.dka_maj_indicateurs_tecpca dk
       WHERE nvl(status, gv_statut_new) IN
             (gv_statut_new, gv_statut_invalid);
  
  BEGIN
    fnd_file.put_line(fnd_file.log,
                      'validate_data : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
    p_retcode := 0;
  
    FOR rec_data IN cur_data LOOP
      -- Donnee a verifier
      --
    
      -- Transco de la clé comptable
      dka_rep_transco_pkg.get_transco(pv_transco_name => '014_PROJETS',
                                      pv_column_01    => rec_data.project_code_11,
                                      pv_out_01       => v_code_projet_new,
                                      pv_out_02       => v_tache_new);
    
      IF v_code_projet_new IS NOT NULL AND v_tache_new IS NOT NULL THEN
        UPDATE dka.dka_maj_indicateurs_tecpca
           SET project_code_12 = v_code_projet_new,
               task_code_12    = v_tache_new
         WHERE ROWID = rec_data.rid;
      ELSE
        lv_errmsg := 'Le code projet n''est pas dans la table de transco.';
      
        UPDATE dka.dka_maj_indicateurs_tecpca
           SET status = gv_statut_invalid, oa_error_message = lv_errmsg
         WHERE ROWID = rec_data.rid;
      
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
      
        UPDATE dka.dka_maj_indicateurs_tecpca
           SET status = gv_statut_invalid, oa_error_message = lv_errmsg
         WHERE ROWID = rec_data.rid;
      
        g_nb_event_nonvalide := g_nb_event_nonvalide + 1;
        continue;
      END IF;
    
      UPDATE dka.dka_maj_indicateurs_tecpca
         SET status = gv_statut_valid, oa_error_message = NULL
       WHERE ROWID = rec_data.rid;
      COMMIT;
    END LOOP; /* Rec_Social_Data IN Cur_Fiscal_Data */
  
    fnd_file.put_line(fnd_file.log,
                      'validate_data : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'validate_data : ' || SQLERRM;
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        l_step || '-' ||
                        'Fin de la procédure validate_data_fiscal : EXCEPTION OTHERS ');
  END validate_data;

  /*
   *************************************************************************
   * PROCEDURE NAME : import_data
   *
   * DESCRIPTION
   *  Insertion des données dans la table d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * p_errbuf            Retour de message éventuel
   * p_retcode           Statut du traitement en sortie
   ************************************************************************
   */

  PROCEDURE import_data(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS
  
    CURSOR cur_data IS
      SELECT dk.*,
             dk.ROWID rid,
             pt.task_id,
             -- RG4 : Tâche facturée ou calculé
             decode((SELECT COUNT(1)
                      FROM dka.dka_maj_indicateurs_tecpca tec2
                     WHERE tec2.project_code_12 = dk.project_code_12
                       AND tec2.task_code_12 = dk.task_code_12
                       AND substr(indicateur_tecpca, 1, 1) = 'Y'),
                    0,
                    'N',
                    'Y') est_facture,
             decode((SELECT COUNT(1)
                      FROM dka.dka_maj_indicateurs_tecpca tec2
                     WHERE tec2.project_code_12 = dk.project_code_12
                       AND tec2.task_code_12 = dk.task_code_12
                       AND substr(indicateur_tecpca, 2, 1) = 'Y'),
                    0,
                    'N',
                    'Y') est_calcule
        FROM dka.dka_maj_indicateurs_tecpca dk,
             pa_projects_all                pp,
             pa_tasks                       pt
       WHERE nvl(status, gv_statut_new) IN (gv_statut_valid)
         AND dk.project_code_12 = pp.segment1
         AND pp.project_id = pt.project_id
         AND dk.task_code_12 = pt.task_number;
  
    l_ligne VARCHAR2(150);
    l_step  VARCHAR2(50);
    l_error VARCHAR2(2000);
  
  BEGIN
    p_retcode := 0;
  
    fnd_file.put_line(fnd_file.log,
                      'import_data : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
    FOR rec_data IN cur_data LOOP
      l_ligne := rec_data.rid;
    
      BEGIN
        UPDATE pa_tasks
           SET attribute3 = rec_data.est_facture || rec_data.est_calcule
         WHERE task_id = rec_data.task_id;
      
        UPDATE dka.dka_maj_indicateurs_tecpca
           SET status = gv_statut_ok
         WHERE ROWID = l_ligne;
         
         g_nb_event_cree := g_nb_event_cree + 1;
      EXCEPTION
        WHEN OTHERS THEN
          l_error := SQLERRM;
        
          UPDATE dka.dka_maj_indicateurs_tecpca
             SET status = gv_statut_rejected, oa_error_message = l_error
           WHERE ROWID = l_ligne;
        
          g_nb_event_rejete := g_nb_event_rejete + 1;
      END;
    
    END LOOP;
  
    COMMIT;
  
    fnd_file.put_line(fnd_file.log,
                      'import_data : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'import_data : ' || SQLERRM || ':' || l_step || ':' ||
                   l_ligne;
    
      fnd_file.put_line(fnd_file.log, p_errbuf);
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'Fin de la procédure import_data : EXCEPTION OTHERS ');
  END import_data;

  /*
  *************************************************************************
  * PROCEDURE NAME : generate_output
  * 
  * DESCRIPTION
  *  Procï¿¿dure de gï¿¿nï¿¿ration du bilan du traitement 
  *
  * PARAMETERS
  * ==========
  * NAME                 DESCRIPTION
  .* -------------------- -------------------------------------------------
  * pv_errbuf            Retour de message ï¿¿ventuel
  * pn_retcode           Statut du traitement en sortie
  ************************************************************************
  */
  PROCEDURE generate_output(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode IN OUT NUMBER) IS
  
  BEGIN
  
    dka_tools_pkg.put_log_message('Debut generate_output');
  
    --------------------    
    -- Initialisation --
    --------------------  
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
    dka_tools_pkg.put_outdebug_message(chr(10));
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------BILAN-------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('. Nombre d''enregistrements chargees dans la table spécifique des revenus : ' ||
                                       to_char(g_nb_event_charger) ||
                                       chr(10));
    dka_tools_pkg.put_outdebug_message('. Nombre de tache mise à jour : ' ||
                                       to_char(g_nb_event_cree) || chr(10));
    dka_tools_pkg.put_outdebug_message('. Nombre de tache non valides : ' ||
                                       to_char(g_nb_event_nonvalide) ||
                                       chr(10));
    dka_tools_pkg.put_outdebug_message('. Nombre de tache rejetés: ' ||
                                       to_char(g_nb_event_rejete) ||
                                       chr(10));
  
    dka_tools_pkg.put_outdebug_message(chr(10));
    dka_tools_pkg.put_log_message('Fin Report_Bilan');
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'generate_output : ' || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      dka_tools_pkg.put_outdebug_message(to_char(SYSDATE,
                                                 'DD/MM/YYYY HH24:MI:SS') ||
                                         ' - Erreur: ' ||
                                         'Fin de la procï¿¿dure Report_Bilan : EXCEPTION OTHERS ');
  END generate_output;

  ------------------------------------------------------------------------------------
  -- Nom              : MAIN
  -- Description      : Procédure d'extraction dans un ficher plat des soldes GL
  --
  -- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
  --                    pn_retcode     Sortie Code Retour de la procédure
  --                                   '0' : Normal
  --                                   '1' : Avertissement
  --                                   '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  -- Description       :
  -- Valeurs possibles :
  ------------------------------------------------------------------------------------

  PROCEDURE main(p_err_buf      OUT VARCHAR2,
                 p_ret_code     OUT NUMBER,
                 p_process_file IN VARCHAR2,
                 p_load_mode    IN VARCHAR2,
                 p_use_mode     IN VARCHAR2) IS
    -- =============================================================================
    -- Name         : main
    -- Type         : Procedure
    -- Description  : Main procedure
    -- Author       : Nicolas Boussekeyt
    -- Updated by   : 
    -- Date Created : 01-12-2016
    -- Updated      : 
    -- Parameters   : p_err_buf  OUT VARCHAR2 - error messages 
    --                p_ret_code OUT NUMBER   - error code
    --                p_process_file IN NUMBER   - File to import
    --
    -- =============================================================================            
  BEGIN
    p_ret_code := 0;
  
    --g_duplicate_transaction := 0;
    --g_duplicate_invoice := 0;
  
    fnd_file.put_line(fnd_file.log,
                      'main : start : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
    IF (p_load_mode = 'Y') THEN
      ------------------------------------
      -- PHASE DE CHARGEMENT DU FICHIER --
      ------------------------------------
      fnd_file.put_line(fnd_file.log,
                        to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                        'PHASE DE CHARGEMENT DU FICHIER');
    
      -- Lancement du programme de chargement
      launch_loader(p_err_buf, p_ret_code, p_process_file);
    
    END IF;
  
    IF (p_ret_code = 0) THEN
      validate_data(p_err_buf, p_ret_code);
    END IF;
  
    IF (p_ret_code = 0 AND p_use_mode = 'Y') THEN
      import_data(p_err_buf, p_ret_code);
    END IF;
  
    IF (p_ret_code = 0 OR p_ret_code = 1) THEN
      generate_output(p_err_buf, p_ret_code);
    END IF;
  
    fnd_file.put_line(fnd_file.log,
                      'main : end : ' ||
                      to_char(SYSDATE, 'DD/MM/RRRR HH:MI:SS'));
  
  EXCEPTION
    WHEN OTHERS THEN
      p_ret_code := 2;
      p_err_buf  := 'MAIN : ' || SQLERRM;
  END main;

END dka_rep_int_tecpca_pkg;
/
SHOW ERRORS;
EXIT
