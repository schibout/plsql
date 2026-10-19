CREATE OR REPLACE PACKAGE BODY DKA_REP_COUTS_PKG IS
  ----------------------------------------------------------------------
  -- PROGRAM : DKA_REP_COUTS_PKG.sql                              -
  -- Version : 1.0                                                     -
  -- AUTEUR  : B.DELATTRE SOCIETE : CAPGEMINI                -
  -- DATE    : 07/07/16                                                -
  ----------------------------------------------------------------------
  -- APPELE PAR : Reprise COUTS Import                           -
  -- FONCTION   : SFD001                                               -
  --                                                                   -
  --                                                                   -
  ----------------------------------------------------------------------
  -- VERSION              :        1.1                                 -
  -- PROGRAMME MODIFIE LE :        28/10/16                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        Ajout des paramètres et des status  -
  --                                                                   -
  ----------------------------------------------------------------------
  -- VERSION              :        1.2                                 -
  -- PROGRAMME MODIFIE LE :        14/11/16                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2042228 - Import des coûts PA   - 
  -- Transcodification et commentaire de la ligne de dépense           -
  --                                                                   -
  ----------------------------------------------------------------------
  -- VERSION              :        1.3                                 -
  -- PROGRAMME MODIFIE LE :        16/11/16                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2045676: Problème sélection des -
  --                               coûts à importer
  --                                                                   -
  ----------------------------------------------------------------------
  -- VERSION              :        1.4                                 -
  -- PROGRAMME MODIFIE LE :        21/11/16                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2046950: Plantage de l'import   -
  --                               des coûts si CCID inexistante       -
  --                                                                   -
  ----------------------------------------------------------------------
  -- VERSION              :        1.5                                 -
  -- PROGRAMME MODIFIE LE :        25/11/16                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2049666 - Plantage de l'import  -
  -- des coûts si des CCID ne peuvent être créées                      -
  -- artf2049967 - Contrôle sur la société destinatrice des coûts
  -- artf2049975 - Détermination de l'UO cible pour les coûts
  ----------------------------------------------------------------------
  -- VERSION              :        1.6                                 -
  -- PROGRAMME MODIFIE LE :        30/11/16                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :         artf2052453: Import des coûts PA - 
  -- Prob marquage des lignes intégrées dans PA.
  --
  ----------------------------------------------------------------------
  -- VERSION              :        1.7                                 -
  -- PROGRAMME MODIFIE LE :        13/12/16                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :         artf2056618 - Import des coûts PA - 
  -- Ajouter MAJ de l'Attribute5 post intégration
  --
  ----------------------------------------------------------------------
  -- VERSION              :        1.8                                 -
  -- PROGRAMME MODIFIE LE :        31/01/17                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2092907 - RUN3 - Reprise des coûts - 
  -- Message 'La transco du projet n'existe pas.' à tors			   -
  --
  ----------------------------------------------------------------------
  -- VERSION              :        1.9                                 -
  -- PROGRAMME MODIFIE LE :        01/02/17                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2093925: RUN3 - Reprise des coûts - 
  -- Traitement en erreur
  --
  ----------------------------------------------------------------------
  -- VERSION              :        1.10                                 -
  -- PROGRAMME MODIFIE LE :        02/02/17                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2094233: RUN3 - Reprise des coûts 
  -- pb dans la màj des statuts de certaines lignes
  --
  ----------------------------------------------------------------------
  -- VERSION              :        1.11                                -
  -- PROGRAMME MODIFIE LE :        03/02/17                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2095187 - RUN3 - Reprises des coûts - Date erronée dans CUF ATTRIBUTE5 pour dépenses des tâches GT
  -- artf2095040 - RUN3 - Rerpise des coûts - Certaines lignes rejetées ne sont pas supprimées de l'OI
  -- artf2094959 - RUN3 - Reprise des coûts - Transco des types de dépense
  -- artf2094938 - RUN3 - Reprise des coûts - Coût complet doit être égal au coût direct pour les projets REFAC
  ----------------------------------------------------------------------
  -- VERSION              :        1.12                                -
  -- PROGRAMME MODIFIE LE :        02/03/17                            -
  -- PAR                  :        N. BOUSSEKEYT                       -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
  ----------------------------------------------------------------------
  -- VERSION              :        1.13                                -
  -- PROGRAMME MODIFIE LE :        13/11/17                            -
  -- PAR                  :        Maxime EGOT                         -
  -- NUM_ANOMALIE         :                                            -
  -- OBJET                :        artf2274428 : REPRISE_COUTS - IMPORT R12 - Modification de la description des depenses reprises 
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  g_user_id           fnd_user.user_id%TYPE;
  g_login_id          fnd_logins.login_id%TYPE;
  g_request_id        fnd_concurrent_requests.request_id%TYPE;
  g_loader_request_id fnd_concurrent_requests.request_id%TYPE;
  g_tempo             NUMBER;

  g_nb_couts_cree_oi NUMBER := 0;

  n_nb_couts_charger NUMBER := 0;

  g_nb_couts_cree NUMBER := 0;
  g_nb_couts_rejet NUMBER := 0;
  
  -- NBO 28/10/16 - Ajout des paramètres et des status
  gv_status_new VARCHAR2(50) := 'NEW';
  gv_status_valid VARCHAR2(50) := 'VALID';
  gv_status_invalid VARCHAR2(50) := 'INVALID';
  gv_status_reject VARCHAR2(50) := 'REJECTED';
  gv_status_ok VARCHAR2(50) := 'OK';
  
  gd_end_period DATE;

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
  PROCEDURE purge_data IS
    v_current_program_unit VARCHAR2(30);
  
  BEGIN
    v_current_program_unit := 'purge_data';
    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - début ' || v_current_program_unit);
  
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_REP_COUTS_INTERFACE';
    
    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  '-> REP_COUTS_INTERFACE : ' ||
                                  SQL%ROWCOUNT);
  
  END purge_data;

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
  .* ----------------- ------------------------------------------------------
  * pv_errbuf         Retour de message éventuel
  * pn_retcode        Statut du traitement en sortie
  ************************************************************************
  */
  -- NBO 28/10/16 - Ajout de la détermination de la période de chargement
  PROCEDURE init(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode IN OUT NUMBER,
                 pv_period  IN VARCHAR2) IS
  BEGIN
  
    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Debut init');
  
    ------------------------
    -- Variables globales --
    ------------------------
  
    g_login_id   := fnd_global.login_id;
    g_request_id := fnd_global.conc_request_id;
    g_tempo      := 20;
    g_user_id    := fnd_global.user_id;
    
    --Suppression des données précédentes
    --purge_data;
    
    -- NBO 28/10/16 - Ajout de la détermination de la période de chargement 
    SELECT end_date
       INTO gd_end_period
       FROM pa_periods
      WHERE period_name = pv_period;
    
    
    
    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Fin init');
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'INIT : ' || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE,
                                            'DD/MM/YYYY HH24:MI:SS') ||
                                    ' - ' ||
                                    'Fin de la procédure init : EXCEPTION :'||SQLERRM);
  END init;

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
  * -----------------  ------------------------------------------------------
  * p_directory        Répertoire du fichier
  * p_file_name        Nom du fichier à charger
  * pv_errbuf          Retour de message éventuel
  * pn_retcode         Statut du traitement en sortie
  *
  ************************************************************************
  */
  PROCEDURE Launch_Loader(pv_errbuf  IN OUT VARCHAR2,
                          pn_retcode IN OUT NUMBER,
                          pv_NomFich IN VARCHAR2) IS
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
  
  BEGIN
    v_message := '';
    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Debut Launch_Loader');  
    dka_tools_pkg.put_outdebug_message('');
    dka_tools_pkg.put_outdebug_message('CHARGEMENT DU FICHIER :');
  
    ------------------------------------------------------
    -- Lancement du traitement de chargement du fichier --
    ------------------------------------------------------
  
    -- Lancement du traitement
    g_loader_request_id := Fnd_Request.submit_request('DKA' -- APPL
                                                     ,
                                                      'DKA_REPCOUTS_IMP_LOADER' -- PROG
                                                     ,
                                                      NULL -- PROGRAM_NAME
                                                     ,
                                                      NULL -- START
                                                     ,
                                                      FALSE -- SUB_REQUEST
                                                     ,
                                                      pv_NomFich);
  
    IF g_loader_request_id = 0 THEN
      pn_retcode := 2;
      pv_errbuf  := 'ERREUR : Le traitement de chargement du fichier DKA_REP_COUTS_LOADER a échoué';
      dka_tools_pkg.put_outdebug_message('ERREUR : Le traitement de chargement du fichier DKA_REP_COUTS_LOADER a échoué ');
    ELSE
      COMMIT;
      dka_tools_pkg.put_log_message('=> LOAD REQUEST ID= ' ||
                                    g_loader_request_id);
      dka_tools_pkg.put_outdebug_message('Numéro du traitement de chargement du fichier : ' ||
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
        pn_retcode := 2;
        pv_errbuf  := 'ERREUR : Attente de la fin du programme de chargement du fichier DKA_REP_COUTS_LOADER dépassée : Fin du traitement';
        dka_tools_pkg.put_log_message('ERREUR : Attente de la fin du programme de chargement du fichier DKA_REP_COUTS_LOADER dépassée : Fin du traitement ' ||
                                      v_message);
      END IF;
    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        dka_tools_pkg.put_log_message('COMPLETION= ' || v_dev_phase || '/' ||
                                      v_dev_status);
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        dka_tools_pkg.put_outdebug_message('Fin du traitement de chargement en warning ' ||
                                      g_loader_request_id);
        pn_retcode := 1;
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        pn_retcode := 2;
        pv_errbuf  := 'ERREUR : Fin anormale du traitement de chargement : ' ||
                      g_loader_request_id;
        dka_tools_pkg.put_outdebug_message('ERREUR : Fin anormale du traitement de chargement ' ||
                                      g_loader_request_id || CHR(10) ||
                                      'Phase/Statut : ' || v_dev_phase || '/' ||
                                      v_dev_status || CHR(10) ||
                                      'MESSAGE : ' || v_message || CHR(10));
      END IF;
    END IF;
  
    SELECT count(*)
      INTO n_nb_couts_charger
      FROM DKA_REP_COUTS_INTERFACE
     where load_request_id = g_loader_request_id;
  
    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Fin Launch_Loader');
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'LAUNCH_LOADER : ' || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE,
                                            'DD/MM/YYYY HH24:MI:SS') ||
                                    ' - ' ||
                                    'Fin de la procédure Launch_Loader après EXCEPTION :'||SQLERRM);
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
  -- NBO 28/10/16 - Procédure de contrôle des données chargées
  PROCEDURE control_data(pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode IN OUT NUMBER) IS
    lv_errmsg      VARCHAR2(1000);
    l_count        NUMBER;
    lv_region_transco     VARCHAR(25);
    lv_code_projet        VARCHAR2(200);
    lv_numero_tache       VARCHAR2(200);
    lv_type_depense        VARCHAR2(200); 
    -- artf2046950: Plantage de l'import des coûts si CCID inexistante
    vn_ccid NUMBER;
  
    -- NBO 25/11/16 - artf2049975 - Détermination de l'UO cible pour les coûts
    CURSOR cur_tmp IS
      SELECT dka.* /*, hou.organization_id*/, dka.ROWID rid
        FROM dka_rep_couts_interface dka/*, hr_operating_units hou*/
       WHERE 1=1 --dka.unite_operationnelle = hou.NAME (+)
       AND dka.status IN (gv_status_new, gv_status_invalid);
       
    -- artf2046950: Plantage de l'import des coûts si CCID inexistante
    -- NBO 25/11/16 - artf2049975 - Détermination de l'UO cible pour les coûts
    CURSOR cur_ou IS
      SELECT DISTINCT hou.NAME unite_operationnelle
        FROM dka_rep_couts_interface dka, pa_projects_all pp, hr_operating_units hou
        -- NBO 25/11/16 - artf2049666 - Plantage de l'import  des coûts si des CCID ne peuvent être créées 
        WHERE dka.status IN (gv_status_valid)
        AND dka.projet_new = pp.segment1
        AND  pp.org_id = hou.organization_id;
  
  BEGIN
    
    -- NBO 14/11/16 - artf2042228 - Import des coûts PA - Transcodification et commentaire de la ligne de dépense
    DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '008_REGIONS',
                                    pv_column_01    => 'GFK',
                                    pv_out_01       => lv_region_transco);
    
    IF lv_region_transco IS NULL THEN
      lv_errmsg := 'La région de transco n''existe pas.';
      
      UPDATE dka_rep_couts_interface
         SET status = gv_status_invalid, error_message = lv_errmsg;
      RETURN;
    END IF;
  
    FOR rec_tmp IN cur_tmp LOOP
      /*dka_pa_tools_pkg.pa_get_period(lv_errbuf,
                                     ln_retcode,
                                     rec_tmp.date_de_depense,
                                     rec_tmp.gl_date,
                                     rec_tmp.organization_id,
                                     ld_start_date,
                                     ld_end_date,
                                     ld_pa_date,
                                     lv_period_name);
      IF ld_pa_date IS NULL THEN
        dka_tools_pkg.put_log_message(lv_errmsg);
        lv_errmsg := 'La date ' || rec_tmp.date_de_depense ||
                     ' n''est pas sur une période PA ouverte dans l''organisation ' ||
                     rec_tmp.unite_operationnelle;
      
        UPDATE dka_rep_couts_interface
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;
        continue;
      END IF;*/
      
      -- NBO 25/11/16 - artf2049967 - Contrôle sur la société destinatrice des coûts
      SELECT COUNT(1) INTO l_count
      FROM hr_operating_units hou
       WHERE substr(rec_tmp.unite_operationnelle,-4,4) = substr(hou.NAME,-4,4);
      
      IF l_count = 0 THEN
        lv_errmsg := 'L''OU n''existe pas.';
      
        UPDATE dka_rep_couts_interface
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;
        continue;
      END IF;
      
      IF rec_tmp.organisation_depense IS NULL THEN
        lv_errmsg := 'L''organisation de dépense est obligatoire.';
      
        UPDATE dka_rep_couts_interface
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;
        continue;
      END IF;
    
       -- NBO 14/11/16 - artf2042228 - Import des coûts PA - Transcodification et commentaire de la ligne de dépense
       DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '014_PROJETS',
                                      pv_column_01    => rec_tmp.code_projet,
                                      pv_out_01       => lv_code_projet,
                                      pv_out_02       => lv_numero_tache); --Recupération du nouveau code projet, et de la tache grâce à la fonction de transcodification

      -- 31/01/2017 NBO artf2092907 - RUN3 - Reprise des coûts - 
  	  -- Message 'La transco du projet n'existe pas.' à tors
      IF lv_code_projet = rec_tmp.code_projet AND lv_numero_tache IS NULL THEN
        lv_errmsg := 'La transco du projet n''existe pas.';
        --dka_tools_pkg.put_log_message(lv_code_projet||':'||rec_tmp.code_projet);
       
        UPDATE dka_rep_couts_interface
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;
        continue;
      ELSE
         UPDATE dka_rep_couts_interface
           SET projet_new = lv_code_projet,
               numero_de_tache = lv_numero_tache
         WHERE ROWID = rec_tmp.rid;
      END IF;
     
	  -- Contrôle de l'existence du projet
      SELECT COUNT(1)
        INTO l_count
        FROM pa_projects_all
       WHERE segment1 = lv_code_projet;
      
      IF l_count <> 1 THEN
        lv_errmsg := 'Le projet n''existe pas.';
      
        UPDATE dka_rep_couts_interface
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;
        continue;
      END IF;
      
      -- NBO 25/11/16 - artf2049967 - Contrôle sur la société destinatrice des coûts
      SELECT COUNT(1) INTO l_count
      FROM hr_operating_units hou,  pa_projects_all pp
       WHERE substr(rec_tmp.unite_operationnelle,-4,4) = substr(hou.NAME,-4,4)
       AND pp.segment1 = lv_code_projet
       AND pp.org_id = hou.organization_id;
      
      IF l_count = 0 THEN
        lv_errmsg := 'L''OU du projet est différente du fichier.';
      
        UPDATE dka_rep_couts_interface
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;
        continue;
      END IF;
      
	  -- NBO 03/02/17 artf2094959 - RUN3 - Reprise des coûts - Transco des types de dépense
      dka_rep_transco_pkg.get_transco ( pv_transco_name  => '012_EXPENDITURE_TYPES',
                                        pv_column_01 => rec_tmp.type_depense,
                                        pv_out_01 => lv_type_depense);

      UPDATE dka_rep_couts_interface
        SET type_depense_new = lv_type_depense
      WHERE ROWID = rec_tmp.rid;

      SELECT COUNT(1)
        INTO l_count
        FROM pa_expenditure_types
       --WHERE expenditure_type = rec_tmp.type_depense
       WHERE expenditure_type = lv_type_depense
         AND trunc(SYSDATE) BETWEEN nvl(start_date_active,sysdate) AND nvl(end_date_active,sysdate);
    
      IF l_count <> 1 THEN
        lv_errmsg := 'Le type de dépense est invalide.';
      
        UPDATE dka_rep_couts_interface
           SET status = gv_status_invalid, error_message = lv_errmsg
         WHERE ROWID = rec_tmp.rid;
        continue;
      END IF;
      
      UPDATE dka_rep_couts_interface
         SET status = gv_status_valid,
             error_message = null
       WHERE ROWID = rec_tmp.rid;
    
    END LOOP;
    
    -- artf2046950: Plantage de l'import des coûts si CCID inexistante
    FOR  rec_ou IN cur_ou LOOP
      dka_tools_pkg.get_code_combination_id(
                            pv_segment1 => substr(rec_ou.unite_operationnelle,-4),
                            pv_segment2 => substr(rec_ou.unite_operationnelle,1,3),
							-- NBO 01/02/17 - artf2093925: RUN3 - Reprise des coûts
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
                            pv_errbuf => pv_errbuf,
                            pn_retcode => pn_retcode,
                            pv_validation_flag => 'Y');
      dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || '  unite_operationnelle : ' || rec_ou.unite_operationnelle
      || ' vn_ccid : ' || vn_ccid);
      
      IF vn_ccid IS NULL THEN
        dka_tools_pkg.put_log_message(pv_errbuf);
        
        UPDATE dka_rep_couts_interface
         SET status = gv_status_invalid, error_message = pv_errbuf
       WHERE unite_operationnelle= rec_ou.unite_operationnelle;
      END IF;
    END LOOP;
    
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      dka_tools_pkg.put_log_message('control_data , SQLCODE : ' ||
                                    SQLCODE || 'SQLERRM : ' || SQLERRM);
    
  END;

  -------------------------------------------------------------------------------------
  --  Nom           : INSERT_PA_TRANSAC_INTERFAC_ALL
  --  Description   : Procédure d'insertion dans la table PA_TRANSACTION_INTERFACE_ALL
  --  PARAMETRES    :
  --
  --        pv_errbuf                 Sortie,
  --        pn_retcode                Sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: OK, 2: erreur ou le code  erreur ORA
  ------------------------------------------------------------------------------------
  PROCEDURE insert_pa_transac_interfac_all(
                                           
                                           pv_errbuf  IN OUT VARCHAR2,
                                           pn_retcode IN OUT NUMBER) IS
    -- NBO 28/10/16 - sélectionne les données valides pour insertion
    CURSOR cur_tmp IS
--      select * 
--      from dka_rep_couts_interface where status IN (gv_status_valid, gv_status_reject);
       -- NBO 14/11/16 - Récupére l'organisation de dépense du projet
	   -- NBO 03/02/17 - artf2094938 - RUN3 - Reprise des coûts - Coût complet doit être égal au coût direct pour les projets REFAC
       select dka.*, hou.name org_name, ppa.project_type  
      from dka_rep_couts_interface dka,
           pa_projects_all ppa,
           hr_all_organization_units hou
       -- NBO 16/11/16 - artf2045676: Problème sélection des coûts à importer
       where dka.status IN (gv_status_valid, gv_status_reject)
       and dka.projet_new = ppa.segment1
       and ppa.carrying_out_organization_id = hou.organization_id;
       
    vn_ccid   NUMBER;
	  vn_org_id NUMBER;
    -- NBO 25/11/16 - artf2049975 - Détermination de l'UO cible pour les coûts
    vv_ou VARCHAR2(100);
    lv_region_transco     VARCHAR(25);
    vv_errbuf VARCHAR2(1000);
    vn_retcode NUMBER;
    vv_attribute_category varchar2(50);
    -- NBO 03/02/17 - artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
    vv_attribute3 varchar2(50);
    vv_attribute5 varchar2(50);
  
  BEGIN
  dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || ' --insert_pa_transac_interfac_all (+)');
   -- dka_tools_pkg.put_log_message('Suppression des données de la table pa_transaction_interface_all');
    --delete from pa_transaction_interface_all;
    -- NBO - 16/11/16 - Supprime les rejets d'OI avant de reinsérer des lignes                              
    -- Supprime les lignes dans l'OI
    DELETE FROM pa_transaction_interface_all ptia 
     WHERE ROWID IN
         (SELECT ptia.ROWID
            FROM pa_transaction_interface_all ptia,
                 dka_rep_couts_interface      dka,
                 hr_operating_units           hou
           WHERE transaction_status_code = 'R'
             AND ptia.transaction_source = dka.transaction_source
             AND ptia.batch_name = dka.transaction_source
             AND dka.projet_new = ptia.project_number
             AND dka.numero_de_tache = ptia.task_number
			 -- 03/02/17 NBO - artf2095040 - RUN3 - Rerpise des coûts - Certaines lignes rejetées ne sont pas supprimées de l'OI
             --AND dka.type_depense = ptia.expenditure_type
             AND dka.type_depense_new = ptia.expenditure_type
             --AND hou.NAME = dka.unite_operationnelle
             AND ptia.orig_transaction_reference = dka.reference_orig_trans
             
             AND hou.organization_id = ptia.org_id);

   -- NBO 14/11/16 - artf2042228 - Import des coûts PA - Transcodification et commentaire de la ligne de dépense
   DKA_REP_TRANSCO_PKG.get_transco(pv_transco_name => '008_REGIONS',
                                    pv_column_01    => 'GFK',
                                    pv_out_01       => lv_region_transco);
    

    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || ' --Debut de la boucle');	

    FOR v_tmp IN cur_tmp LOOP
    
      --IF v_tmp.STATUS IN ('NEW','REJECTED') THEN

	    -- NBO 25/11/16 - artf2049975 - Détermination de l'UO cible pour les coûts
        --SELECT ORGANIZATION_ID 
        SELECT ORG_ID, HOU.NAME
        INTO vn_org_id, vv_ou 
        --FROM  HR_OPERATING_UNITS hou, 
        FROM PA_PROJECTS_ALL PP, HR_OPERATING_UNITS hou
        --WHERE  hou.NAME = v_tmp.unite_operationnelle
        WHERE  pp.SEGMENT1 = v_tmp.projet_new
        AND pp.org_id = hou.organization_id;

        
        dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || ' --v_tmp.unite_operationnelle:'|| vv_ou);
        
        -- NBO 25/11/16 - artf2049975 - Détermination de l'UO cible pour les coûts
        select code_combination_id into vn_ccid from gl_code_combinations 
        where SEGMENT2||SEGMENT1=vv_ou and segment3 = 'REP' and segment4='REP'
        and summary_flag = 'N' and enabled_flag = 'Y';

       -- dka_tools_pkg.get_code_combination_id(v_tmp.clef_compta_debit,
                                              -- vn_ccid,
                                              -- pv_errbuf,
                                              -- pn_retcode,
                                              -- 'Y');
       -- 13/12/16 NBO - artf2056618 - Import des coûts PA - Ajouter MAJ de l'Attribute5 post intégration                                              
        IF  v_tmp.numero_de_tache LIKE 'GT%' THEN
            vv_attribute_category := 'Global Data Elements';
			-- 03/02/17 NBO - artf2095187 - RUN3 - Reprises des coûts - Date erronée dans CUF ATTRIBUTE5 pour dépenses des tâches GT
            --vv_attribute5 := to_char(sysdate, 'RRRRMMDD');
            --vv_attribute5 := to_char(v_tmp.date_de_depense, 'RRRRMMDD');
            vv_attribute5 := to_char(gd_end_period, 'RRRRMMDD');
        ELSE
           vv_attribute_category := NULL;
           vv_attribute5 := NULL;
        END IF;
        
        -- NBO 03/02/17 - artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
        IF v_tmp.project_type = 'REFAC' THEN
           vv_attribute3 := 'MIGRATION_R12';
        ELSE
           vv_attribute3 := NULL;
        END IF;

        INSERT INTO pa_transaction_interface_all      
          (transaction_source,
           batch_name,
           expenditure_ending_date,
           employee_number,
           organization_name,
           expenditure_item_date,
           project_number,
           task_number,
           expenditure_type,
           non_labor_resource,
           non_labor_resource_org_name,
           quantity,
           raw_cost,
           expenditure_comment,
           transaction_status_code,
           transaction_rejection_code,
           expenditure_id,
           orig_transaction_reference,
           attribute_category,
           attribute1,
           attribute2,
           attribute3,
           attribute4,
           attribute5,
           attribute6,
           attribute7,
           attribute8,
           attribute9,
           attribute10,
           raw_cost_rate,
           interface_id,
           unmatched_negative_txn_flag,
           expenditure_item_id,
           org_id,
           dr_code_combination_id,
           cr_code_combination_id,
           cdl_system_reference1,
           cdl_system_reference2,
           cdl_system_reference3,
           gl_date,
           burdened_cost,
           burdened_cost_rate,
           system_linkage,
           txn_interface_id,
           user_transaction_source,
           created_by,
           creation_date,
           last_updated_by,
           last_update_date,
           receipt_currency_amount,
           receipt_currency_code,
           receipt_exchange_rate,
           denom_currency_code,
           denom_raw_cost,
           denom_burdened_cost,
           acct_rate_date,
           acct_rate_type,
           acct_exchange_rate,
           acct_raw_cost,
           acct_burdened_cost,
           acct_exchange_rounding_limit,
           project_currency_code,
           project_rate_date,
           project_rate_type,
           project_exchange_rate,
           orig_exp_txn_reference1,
           orig_exp_txn_reference2,
           orig_exp_txn_reference3,
           orig_user_exp_txn_reference,
           vendor_number,
           override_to_organization_name,
           reversed_orig_txn_reference,
           billable_flag,
           person_business_group_name)
        VALUES
          (v_tmp.TRANSACTION_SOURCE, --TRANSACTION_SOURCE,
           v_tmp.TRANSACTION_SOURCE, -- gv_transaction_source||' ' || pv_book_type_code ||' ' || pv_period ||' ' ||TRUNC (SYSDATE), --BATCH_NAME,
           -- NBO - 16/11/16 - Force la date de fin de lot PA
           pa_utils.GetWeekEnding(gd_end_period), --EXPENDITURE_ENDING_DATE,
           NULL, --EMPLOYEE_NUMBER,
           --v_tmp.organisation_depense, --ORGANIZATION_NAME,
           v_tmp.org_name, --ORGANIZATION_NAME,
           -- NBO 28/10/16 - change la date de dépense en date de fin de période
           --v_tmp.date_de_depense, --EXPENDITURE_ITEM_DATE,
           gd_end_period, --EXPENDITURE_ITEM_DATE, 
           --v_tmp.code_projet, --PROJECT_NUMBER,
           -- NBO 14/11/16 - artf2042228 - Import des coûts PA - Transcodification et commentaire de la ligne de dépense
           v_tmp.projet_new, --PROJECT_NUMBER,
           v_tmp.numero_de_tache, --TASK_NUMBER,
		   -- 03/02/17 NBO - artf2094959 - RUN3 - Reprise des coûts - Transco des types de dépense
           --v_tmp.type_depense, --EXPENDITURE_TYPE,
           v_tmp.type_depense_new, --EXPENDITURE_TYPE,
           NULL, --NON_LABOR_RESOURCE,
           NULL, --NON_LABOR_RESOURCE_ORG_NAME,
           v_tmp.quantity, --QUANTITY,
           v_tmp.cout_direct, --RAW_COST,
           -- NBO 14/11/16 - artf2042228 - Import des coûts PA - Transcodification et commentaire de la ligne de dépense
           'REPRISE projet ' || v_tmp.code_projet || ' ' || substr(v_tmp.unite_operationnelle,0,3), 
           'P', --TRANSACTION_STATUS_CODE,
           NULL, --TRANSACTION_REJECTION_CODE,
           NULL, --EXPENDITURE_ID,
           v_tmp.REFERENCE_ORIG_TRANS, --ORIG_TRANSACTION_REFERENCE,
           vv_attribute_category, --ATTRIBUTE_CATEGORY,
           NULL, --ATTRIBUTE1,
    	   -- NBO 03/02/17 - artf2045657 - Flaguer lignes de dépenses/événements sur les projets de refac
           NULL, --ATTRIBUTE2,
           --NULL, --ATTRIBUTE3,
           vv_attribute3, --ATTRIBUTE3,
           NULL, --ATTRIBUTE4,
           vv_attribute5, --ATTRIBUTE5,
           NULL, --ATTRIBUTE6,
           NULL, --ATTRIBUTE7,
           NULL, --ATTRIBUTE8,
           NULL, --ATTRIBUTE9,
           NULL, --ATTRIBUTE10,
           NULL, --RAW_COST_RATE,
           NULL, --INTERFACE_ID,
           'Y', --UNMATCHED_NEGATIVE_TXN_FLAG,
           NULL, --EXPENDITURE_ITEM_ID,
           vn_org_id, -- ORG_ID
           to_number(vn_ccid),-- vn_ccid, --DR_CODE_COMBINATION_ID,
           to_number(vn_ccid),--vn_ccid, --CR_CODE_COMBINATION_ID,
           NULL, --CDL_SYSTEM_REFERENCE1,
           NULL, --CDL_SYSTEM_REFERENCE2,
           NULL, --CDL_SYSTEM_REFERENCE3,
           -- NBO - 16/11/16 - Force la date GL à partir de la période en paramètre
           --v_tmp.gl_date, --GL_DATE,
           gd_end_period, --GL_DATE,
		   -- NBO 03/02/17 - artf2094938 - RUN3 - Reprise des coûts - Coût complet doit être égal au coût direct pour les projets REFAC
           DECODE(v_tmp.project_type,'REFAC', v_tmp.cout_direct, v_tmp.cout_complet), --BURDENED_COST,
           NULL, --BURDENED_COST_RATE,
           'PJ', --SYSTEM_LINKAGE,
           NULL, --TXN_INTERFACE_ID,
           NULL, --USER_TRANSACTION_SOURCE,
           g_user_id, --CREATED_BY,
           SYSDATE, --CREATION_DATE,
           g_user_id, --LAST_UPDATED_BY,
           SYSDATE, --LAST_UPDATE_DATE,
           NULL, --RECEIPT_CURRENCY_AMOUNT,
           NULL, --RECEIPT_CURRENCY_CODE,
           NULL, --RECEIPT_EXCHANGE_RATE,
           pa_currency.get_currency_code, --DENOM_CURRENCY_CODE,
           v_tmp.cout_direct, --DENOM_RAW_COST,
		   -- NBO 03/02/17 - artf2094938 - RUN3 - Reprise des coûts - Coût complet doit être égal au coût direct pour les projets REFAC
           DECODE(v_tmp.project_type,'REFAC', v_tmp.cout_direct, v_tmp.cout_complet), --DENOM_BURDENED_COST,
           NULL, --ACCT_RATE_DATE,
           NULL, --ACCT_RATE_TYPE,
           NULL, --ACCT_EXCHANGE_RATE,
           v_tmp.cout_direct, --ACCT_RAW_COST,
		   -- NBO 03/02/17 - artf2094938 - RUN3 - Reprise des coûts - Coût complet doit être égal au coût direct pour les projets REFAC
           DECODE(v_tmp.project_type,'REFAC', v_tmp.cout_direct, v_tmp.cout_complet), --ACCT_BURDENED_COST,
           NULL, --ACCT_EXCHANGE_ROUNDING_LIMIT,
           NULL, --PROJECT_CURRENCY_CODE,
           NULL, --PROJECT_RATE_DATE,
           NULL, --PROJECT_RATE_TYPE,
           NULL, --PROJECT_EXCHANGE_RATE,
           NULL, --ORIG_EXP_TXN_REFERENCE1,
           NULL, --ORIG_EXP_TXN_REFERENCE2,
           NULL, --ORIG_EXP_TXN_REFERENCE3,
           NULL, --ORIG_USER_EXP_TXN_REFERENCE,
           NULL, --VENDOR_NUMBER,
           NULL, --OVERRIDE_TO_ORGANIZATION_NAME,
           NULL, --REVERSED_ORIG_TXN_REFERENCE,
           NULL, --BILLABLE_FLAG,
           NULL --PERSON_BUSINESS_GROUP_NAME
           );
      --END IF;
    END LOOP;
	select count(*) into g_nb_couts_cree_oi from pa_transaction_interface_all;
	--DELETE FROM DKA_REP_COUTS_INTERFACE;
	--COMMIT;

  dka_tools_pkg.put_log_message('nombre enregistrements réussis dans la table d''interface pa_transaction_interface_all : ' ||g_nb_couts_cree_oi);  
	dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || ' --insert_pa_transac_interfac_all (-)');
    
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := SQLERRM;
      dka_tools_pkg.put_log_message('Procédure d''insertion terminéee en erreur , SQLCODE : ' ||
                                    SQLCODE || 'SQLERRM : ' || SQLERRM);
    
  END insert_pa_transac_interfac_all;

  /*=========================================================================*/
  /* PROCEDURE NAME :   program_import_couts
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
  /*=========================================================================*/
PROCEDURE program_import_couts(pv_errbuf  IN OUT VARCHAR2,
                               pn_retcode IN OUT NUMBER) IS

  v_phase      VARCHAR2(100);
  v_status     VARCHAR2(100);
  v_dev_phase  VARCHAR2(100);
  v_dev_status VARCHAR2(100);
  v_message    VARCHAR2(100);

  -- NBO 28/10/16 - Utilise la responsabilité TOUT_PA_ADMINISTRATEUR
  --récupération des différentes responsabilités pour lesquelles il faut lancer le traitement
  CURSOR cur_resp IS
    SELECT DISTINCT fr.responsibility_key,
                    fr.responsibility_id,
                    fr.application_id,
                    --fa.application_id,
                    --fa.application_short_name,
                    --fpov.profile_option_value org_id
                    hou.organization_id org_id,
                    hou.name org_name
      FROM fnd_responsibility fr,
           --          fnd_profile_options_vl fpo,
           --          fnd_profile_option_values fpov,
           dka_rep_couts_interface drci,
           pa_projects_all pp,
           --          fnd_application fa, 
           hr_operating_units hou
     WHERE fr.responsibility_key LIKE 'TOUT_PA_ADMINISTRATEUR'
          --         and fr.application_id = fa.application_id
          --         and substr(fr.responsibility_key, 1, length(drci.UNITE_OPERATIONNELLE)) = drci.UNITE_OPERATIONNELLE
          --         and fpov.level_value = fr.responsibility_id
          --         AND fpo.profile_option_id = fpov.profile_option_id
          --         AND fpo.profile_option_name = 'ORG_ID'
          --         AND fpov.profile_option_id = fpo.profile_option_id;
         -- NBO 25/11/16 - artf2049975 - Détermination de l'UO cible pour les coûts
         AND drci.projet_new = pp.segment1
         AND pp.org_id = hou.organization_id
         AND drci.status IN (gv_status_valid, gv_status_reject);
       --AND drci.unite_operationnelle = hou.NAME;

   -- NBO 28/10/16 - Sélectionne les lignes rejetés à flagger
   CURSOR cur_dka IS
    SELECT dka.ROWID rid, ptia.transaction_rejection_code
      FROM pa_transaction_interface_all ptia,
           dka_rep_couts_interface      dka,
           hr_operating_units           hou
     WHERE transaction_status_code = 'R'
       AND ptia.transaction_source = dka.transaction_source
       AND ptia.batch_name = dka.transaction_source
       -- NBO 14/11/16 - artf2042228 - Import des coûts PA - Transcodification et commentaire de la ligne de dépense
       AND dka.projet_new = ptia.project_number
       AND dka.numero_de_tache = ptia.task_number
       --AND dka.type_depense = ptia.expenditure_type
	   -- NBO 03/02/17 - artf2094959 - RUN3 - Reprise des coûts - Transco des types de dépense
       AND dka.type_depense_new = ptia.expenditure_type
       -- 02/02/17 - artf2094233: RUN3 - Reprise des coûts - pb dans la màj des statuts de certaines lignes
       --AND hou.NAME = dka.unite_operationnelle
       AND dka.reference_orig_trans = ptia.orig_transaction_reference
       AND hou.organization_id = ptia.org_id
       AND dka.status IN (gv_status_valid, gv_status_reject);

BEGIN
  dka_tools_pkg.put_log_message(to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                ' - ' ||
                                'Début de la procédure program_import_couts');
             
  FOR v_tmp IN cur_resp LOOP
  
    dka_tools_pkg.put_log_message(to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'positionnement de la resp :' ||
                                  v_tmp.responsibility_id || ' org_id:'|| v_tmp.org_id);
  
    fnd_global.apps_initialize(user_id      => g_user_id,
                               resp_id      => v_tmp.responsibility_id,
                               resp_appl_id => v_tmp.application_id);
  
    --MO_GLOBAL.INIT (p_appl_short_name => v_tmp.application_short_name);
  
    -- NBO 28/10/16 - Positionne l'org de la responsabilité
    fnd_request.set_org_id(v_tmp.org_id);
  
    g_request_id := fnd_request.submit_request('PA', --APPL
                                               'PAXTRTRX', --PROG
                                               NULL, --PROGRAM_NAME
                                               NULL, --START
                                               FALSE, --SUB_REQUEST
                                               'MIGRATION_R12' --Source           --ARGUMENT1
                                               );
  
    IF g_request_id = 0 THEN
      pn_retcode := 2;
      pv_errbuf  := 'ERREUR : Le traitement standard d''import des coûts s''est terminé en erreur.';
      dka_tools_pkg.put_log_message('ERREUR : Le traitement standard d''import des coûts s''est terminé en erreur.' ||
                                    chr(10) ||
                                    'PROGRAMME  : Importation des coûts ');
    ELSE
      COMMIT;
      dka_tools_pkg.put_outdebug_message('Numéro du traitement standard d''import des coûts pour la responsabilité ' ||
                                         v_tmp.responsibility_key || ' : ' ||
                                         g_request_id || ':' || v_tmp.org_name);
    
      --********************************************
      -- Wait for the concurrent program to complete
      --********************************************
      IF NOT (fnd_concurrent.wait_for_request(g_request_id,
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
      
        pv_errbuf := v_message;
        dka_tools_pkg.put_log_message('ERREUR : Attente de la fin du programme dépassée : Fin du traitement' ||
                                      chr(10) || 'MESSAGE : ' || v_message ||
                                      chr(10));
      END IF;
    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
      
        dka_tools_pkg.put_log_message('Request id :' || g_request_id ||
                                      'COMPLETION= ' || v_dev_phase || '/' ||
                                      v_dev_status);
        dka_tools_pkg.put_outdebug_message('Statut de fin : ' || v_phase || '/' ||
                                           v_status);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        dka_tools_pkg.put_log_message('Request id :' || g_request_id ||
                                      'COMPLETION= ' || v_dev_phase || '/' ||
                                      v_dev_status);
        dka_tools_pkg.put_outdebug_message('Fin du traitement standard d''import des coûts en WARNING. ' ||
                                           g_request_id);
        v_message  := 'ERREUR : Fin du traitement en WARNING : ' ||
                      v_message;
        pn_retcode := 1;
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
      
        pn_retcode := 2;
        pv_errbuf  := 'ERREUR : Fin anormale du traitement standard d''import des coûts';
        dka_tools_pkg.put_outdebug_message('ERREUR : Fin anormale du traitement ');
        dka_tools_pkg.put_log_message(g_request_id || chr(10) ||
                                      'Phase/Statut : ' || v_dev_phase || '/' ||
                                      v_dev_status || chr(10) ||
                                      'MESSAGE : ' || v_message || chr(10));
      END IF;
    END IF;
  END LOOP;

  SELECT COUNT(*)
    INTO g_nb_couts_rejet
    FROM pa_transaction_interface_all
   WHERE transaction_status_code = 'R'; -- Le champ TRANSACTION_STATUS_CODE vaut R si l'enregistrement a été rejetté 

  -- NBO 28/10/16 - Met à jour les flags pour les lignes en erreur
  FOR rec_dka IN cur_dka LOOP
    UPDATE dka_rep_couts_interface dka
       SET status        = gv_status_reject,
           error_message = rec_dka.transaction_rejection_code
     WHERE ROWID = rec_dka.rid;
  END LOOP;

  -- NBO 28/10/16 - Met à jour les flags pour les lignes OK
  UPDATE dka_rep_couts_interface dka
     SET status = gv_status_ok, error_message = NULL
   WHERE status IN (gv_status_valid, gv_status_reject) 
   -- NBO 30/11/16 - artf2052453: Import des coûts PA - Prob marquage des lignes intégrées dans PA.
     AND ROWID IN
         (SELECT dka.ROWID
            FROM dka_rep_couts_interface      dka,
            PA_EXPENDITURE_ITEMS_ALL pei
           WHERE pei.orig_transaction_reference = dka.reference_orig_trans
             AND pei.transaction_source = dka.transaction_source
             AND dka.status IN (gv_status_valid, gv_status_reject) );
  
  g_nb_couts_cree := g_nb_couts_cree_oi - g_nb_couts_rejet;

EXCEPTION
  WHEN OTHERS THEN
    pn_retcode := 2;
    pv_errbuf  := 'Exception déclenchée lors du lancement du traitement standard PAXTRTRX: ' ||
                  SQLERRM;
    dka_tools_pkg.put_log_message(to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' ||
                                  'Fin de la procédure program_import_couts : EXCEPTION OTHERS ');
END program_import_couts;

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
  PROCEDURE Report_Bilan(pv_errbuf IN OUT VARCHAR2, pn_retcode IN OUT NUMBER) IS
  CURSOR C1 is 
  Select transaction_rejection_code, expenditure_type, project_number, task_number
  from  pa_transaction_interface_all;
  BEGIN
    --program_import_couts
    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Debut Report_Bilan');
  
    --------------------
    -- Initialisation --
    --------------------
  
    pv_errbuf  := NULL;
    pn_retcode := 0;
  
      dka_tools_pkg.put_outdebug_message(CHR(10));
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------BILAN-------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans la table spécifique des coûts           : ' ||
                                  TO_CHAR(n_nb_couts_charger) || CHR(10));
  
    dka_tools_pkg.put_outdebug_message('   . Nombre d''enregistrements chargés dans l''OI des coûts             : ' ||
                                  TO_CHAR(g_nb_couts_cree_oi) || CHR(10));
    dka_tools_pkg.put_outdebug_message(' *Voir les sorties des traitements d''Open interface pour avoir plus de détails sur les enregistrements rejetés.');
    dka_tools_pkg.put_outdebug_message(CHR(10));
    dka_tools_pkg.put_outdebug_message('-----------------------------------------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('   . Nombre d''enregistrements chargé avec succés         : ' ||TO_CHAR(g_nb_couts_cree) || CHR(10));
  
    dka_tools_pkg.put_outdebug_message(CHR(10));

  
  
  IF g_nb_couts_rejet !=0 THEN 
  
    dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message('---------------------------------------------REJETS LORS DU LANCEMENT DU TRAITEMENT STANDARD ---------------------------------------------');
    dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message(RPAD('PROJECT_NUMBER',50,' ')||RPAD('TASK_NUMBER',40,' ')||RPAD('EXPENDITURE_TYPE',40,' ')||RPAD('TRANSACTION_REJECTION_CODE',40,' '));
    dka_tools_pkg.put_outdebug_message('-------------------------------------------------------------------------------------------------------------------------------------------------------');
    dka_tools_pkg.put_outdebug_message(chr(10));
   FOR v_tmp IN c1 LOOP
      dka_tools_pkg.put_outdebug_message(RPAD(v_tmp.project_number,50,' ')||RPAD(v_tmp.task_number,40,' ')||RPAD(v_tmp.expenditure_type,40,' ')||RPAD(v_tmp.transaction_rejection_code,40,' '));
    END LOOP;

        pn_retcode    := 1;    
    END IF;
    dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Fin Report_Bilan');
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'REPORT_BILAN : ' || SQLERRM;
      dka_tools_pkg.put_log_message(pv_errbuf);
      dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE,
                                                 'DD/MM/YYYY HH24:MI:SS') ||
                                         ' - ' ||
                                         'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan;

  /*=====================================================================================*/
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
  /*=====================================================================================*/

  -- NBO 28/10/16 - Ajout les paramètres de chargement
  PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode IN OUT NUMBER,
                 pv_NomFich IN VARCHAR2,
                 pv_chargement_f  IN VARCHAR2,
					       pv_chargement_oi IN VARCHAR2,
                 pv_period IN VARCHAR2) IS
  
    -- ========== VARIABLES ==========
    v_package        VARCHAR2(30) := 'DKA_REP_COUTS_PKG';
    v_nom_traitement VARCHAR2(200) := 'Import des coûts';
    v_sqlerrm        VARCHAR2(250) := NULL;
    v_procedure      VARCHAR2(30) := 'MAIN';
    v_message        VARCHAR2(500);
    v_exception      EXCEPTION;
  
  BEGIN
    ----------------------------------
    -- Début du Programme principal --
    ----------------------------------
  
    -- Initialisation des variables d'anomalies
    pn_retcode := 0;
    pv_errbuf  := NULL;
    v_message  := 'Début procédure MAIN';
  
    -- Initialisation de la sortie
  
    dka_tools_pkg.put_out_header;
  
    -- Entete fichier sortie
  
    dka_tools_pkg.put_outdebug_message('Libelle du login OA ' ||
                                       FND_GLOBAL.USER_NAME);
    dka_tools_pkg.put_outdebug_message('==========================================================================');
  dka_tools_pkg.put_outdebug_message('Nom du fichier :'||pv_NomFich);
  
  
  
	 dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Lancement de la procédure Main');
  
  
    ----------------------------------
    -- Initialisation des variables --
    ----------------------------------
    v_message := 'Init';
    dka_tools_pkg.put_log_message('Initialisation des variables');
    Init(pv_errbuf,pn_retcode, pv_period);
    IF pn_retcode = 2 THEN
      RAISE v_exception;
    END IF;
  
    -- Lancement du programme de chargement des fichiers
    IF pv_chargement_f = 'Y' THEN
      ----------------------------------------------------
      -- Suppression des données de la table spécifique --
      ----------------------------------------------------
      purge_data();
      -----------------------------
      -- Chargement des fichiers --
      -----------------------------
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      dka_tools_pkg.put_log_message('/* Chargement du fichiers plat */');
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      v_message := 'PHASE DE CHARGEMENT DU FICHIER';
      
      Launch_Loader(pv_errbuf, pn_retcode, pv_NomFich);
  
      IF pn_retcode = 2 THEN
        dka_tools_pkg.put_outdebug_message('Chargement des fichiers plat en erreur');
        RAISE v_exception;
      END IF;
      dka_tools_pkg.put_outdebug_message('Fin chargement des fichiers plat avec succés');
    END IF;
    
    -- Contrôle des données
    control_data(pv_errbuf, pn_retcode);
  
    --------------------------------------
    -- Chargement de la table interface --
    --------------------------------------
    IF pv_chargement_oi = 'Y' THEN
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      dka_tools_pkg.put_log_message('/* Chargement de la table interface */');
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      INSERT_PA_TRANSAC_INTERFAC_ALL(pv_errbuf, pn_retcode);
      
      IF pn_retcode = 2 THEN
        dka_tools_pkg.put_log_message('Fin du chargement de la table d''interface');
        RAISE v_exception;
      END IF;
      
      -- Lancement du traitement standard
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      dka_tools_pkg.put_log_message('/*Lancement du traitement standard pour toutes les sociétés*/');
      dka_tools_pkg.put_log_message('/*============================================================================================*/');
      program_import_couts(pv_errbuf, pn_retcode);
    
      IF pn_retcode = 2 THEN
        RAISE v_exception;
      END IF;
      dka_tools_pkg.put_log_message('Traitement des tables open interface');
    END IF;
   -- COMMIT; 
  
    ----------------------------------
    -- Phase de bilan du traitement --
    ----------------------------------
    Report_Bilan(pv_errbuf, pn_retcode);
  
    IF pn_retcode = 2 THEN
      RAISE v_exception;
    END IF;
  
    dka_tools_pkg.put_log_message(pv_errbuf);
    dka_tools_pkg.put_log_message(CHR(10) || pv_errbuf || CHR(10));
    dka_tools_pkg.put_log_message('==========================================================================');
    dka_tools_pkg.put_log_message('Programme terminé le : ' ||
                                  TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
  
    ----------------------------
    -- Gestion des exceptions --
    ----------------------------
	
		 dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Fin de la procédure Main');
  
  EXCEPTION
    WHEN v_exception THEN
      dka_tools_pkg.put_log_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_log_message('Package   : ' || v_package);
      dka_tools_pkg.put_log_message('Procédure : ' || v_procedure);
      dka_tools_pkg.put_log_message('Exception : OTHERS');
      dka_tools_pkg.put_log_message('Erreur     : ' || pv_errbuf);
      dka_tools_pkg.put_log_message('------------------------------------------------');
      dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE,
                                            'DD/MM/YYYY HH24:MI:SS') ||
                                    ' - ' || 'Fin de la procédure Maiin' ||
                                    v_procedure ||
                                    ' : EXCEPTION v_exception');
      dka_tools_pkg.put_log_message('=========================================================================');
      dka_tools_pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur.');
      ROLLBACK;
    
    WHEN OTHERS THEN
      v_sqlerrm  := SUBSTR(SQLERRM, 1, 200);
      pn_retcode := 2;
      pv_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc ' ||
                    v_package || '.' || v_procedure;
      dka_tools_pkg.put_log_message('-------------------- ERREUR --------------------');
      dka_tools_pkg.put_log_message('Package   : ' || v_package);
      dka_tools_pkg.put_log_message('Procédure : ' || v_procedure);
      dka_tools_pkg.put_log_message('Exception : OTHERS');
      dka_tools_pkg.put_log_message('Message   : ' || v_message);
      dka_tools_pkg.put_log_message(CHR(10) || pv_errbuf);
      dka_tools_pkg.put_log_message('Cause     : ' || v_sqlerrm);
      dka_tools_pkg.put_log_message('------------------------------------------------');
      dka_tools_pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      dka_tools_pkg.put_log_message('=========================================================================');
	  	 dka_tools_pkg.put_log_message(TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') ||
                                  ' - ' || 'Fin de la procédure Main');
  
      ROLLBACK;
    
  END main;

END DKA_REP_COUTS_PKG;
/
SHOW ERRORS;
EXIT
