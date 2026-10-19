CREATE OR REPLACE PACKAGE BODY DKA_IPOFRS_REP_IVALUA_PKG IS
  --------------------------------------------------------------------------------
  -- $Id: DKA_REPFOU_IVALUA.pkb  $
  -- Capgemini
  -- Projet           :
  -- Nom              : DKA_IPOFRS_REP_IVALUA_PKG.pks
  -- Description      : Corps du package DKA_IPOFRS_REP_IVALUA_PKG
  -- Auteur           : 
  -- Date de création : 
  -- Commentaires     :
  --------------------------------------------------------------------------------
  g_package         VARCHAR2(30) := 'DKA_IPOFRS_REP_IVALUA';
  g_sqlerrm         VARCHAR2(500) := NULL;
  g_retproc         NUMBER := 0;
  g_user            NUMBER := fnd_profile.value('USER_ID');
  g_request_id      NUMBER := fnd_global.conc_request_id;
  gv_description    VARCHAR2(250);
  gn_category_id    NUMBER;
  gn_default_value1 NUMBER;
  gn_default_value2 NUMBER;
  gv_datatype_name  VARCHAR2(30) := 'WEB_PAGE';
  gn_datatype_id    NUMBER;

  gn_batch_id             NUMBER;
  g_enreg_a_traite_entete NUMBER := 0;
  g_enreg_entete_rejete1  NUMBER := 0;
  g_enreg_entete_rejete2  NUMBER := 0;
  g_enreg_entete_succes   NUMBER := 0;
  g_enreg_a_traite_line   NUMBER := 0;

  g_enreg_line_rejete2 NUMBER := 0;
  g_enreg_line_succes  NUMBER := 0;
  g_enreg_ligne_rejet  NUMBER := 0;
  g_statut_fin         VARCHAR2(50);
  g_tab_erreurs        t_erreurs;

  g_erreurs NUMBER := 0;

  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              : 21/05/2020
  -- Remarques         :
  /*============================================================================*/
  PROCEDURE writeout(P_message IN VARCHAR2) IS
    L_procedure VARCHAR2(30) := 'writeout';
    v_etape     VARCHAR2(100);
  BEGIN
  
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);
  
  EXCEPTION
    WHEN OTHERS THEN
      G_retproc := 1;
      G_sqlerrm := SUBSTR(SQLERRM, 1, 200);
      Fnd_File.put_line(Fnd_File.LOG,
                        '-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || G_package);
      Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || L_procedure);
      Fnd_File.put_line(Fnd_File.LOG, 'Exception : OTHERS');
      Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || v_etape);
      Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || G_sqlerrm);
  END writeout;
  /*==============================================================================*/
  -- Procedure         : SORTIE_TRAITEMENT
  -- Description       : Procédure pour purger les tables de tarvail
  -- Parametres entree : p_request_id
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              : 03/06/2020
  -- Remarques         :
  /*=================================================================================*/

  /*============================================================================*/
  /* Fonction          : entete_de_sortie                                      */
  /* Description       : entete de la sortie                 */
  /*                                                                            */
  /* Parametres entree : nom de fichier                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE entete_de_sortie(p_nom_fichier IN VARCHAR2, p_maj IN VARCHAR2) IS
  
    l_procedure VARCHAR2(30) := 'entete_de_sortie';
    l_message   VARCHAR2(2000);
  
  BEGIN
    writeout('+-------------------------------------------------------------------------+');
    writeout('COMPTE-RENDU DU TRAITEMENT « DKA : Mise à jour des sites fournisseurs repris dans IVALUA »');
    writeout('Traitement n° : ' || g_request_id);
    writeout('Programme lancé le : ' ||
             to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('PARAMETRES : ');
    writeout('------------');
    writeout('Nom du fichier : ' || p_nom_fichier);
    writeout('Effectuer les mises à jours  ?:' || p_maj);
    writeout('                                                                           ');
    writeout('                                                                           ');
  END entete_de_sortie;

  /*==============================================================================*/
  -- Procedure         : SORTIE_TRAITEMENT
  -- Description       : Procédure pour purger les tables de tarvail
  -- Parametres entree : p_request_id
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 03/06/2020
  -- Remarques         :
  /*=================================================================================*/
  PROCEDURE SORTIE_TRAITEMENT IS
    l_procedure       VARCHAR2(30) := 'sortie_traitement';
    l_message         VARCHAR2(2000);
    v_supplier_number AP_SUPPLIERS.SEGMENT1%TYPE;
    v_vendor_site_id  DKA_IPOFRS_MAJ_SITES_REPRIS.vendor_site_id%TYPE;
  
    CURSOR cur_err_mess IS
      SELECT dih.supplier_number,
             dih.vendor_site_id,
             dpm.source,
             dpm.table_id,
             dpm.message_text
        FROM DKA_PROGRAM_MESSAGES dpm, DKA_IPOFRS_MAJ_SITES_REPRIS dih
       WHERE dpm.REQUEST_ID = g_request_id
         AND dih.record_id = dpm.table_id;
  
  BEGIN
    writeout('                                                                ');
    writeout('                                                                ');
    writeout('SYNTHESE DES ACTIONS :');
    writeout('--------------------');
    writeout('Nombre d''enregistrements à traiter              : ' ||
             g_enreg_a_traite_entete);
    writeout('Nombre d''enregistrements traités avec succès    : ' ||
             g_enreg_entete_succes);
    writeout('Nombre d''enregistrements rejetés                : ' ||
             g_enreg_entete_rejete1);
    writeout('                                                                          ');
  
    FOR rec_erreur IN cur_err_mess LOOP
      g_erreurs := g_erreurs + 1;
      g_tab_erreurs(g_erreurs).supplier_number := rec_erreur.supplier_number;
      g_tab_erreurs(g_erreurs).vendor_site_id := rec_erreur.vendor_site_id;
      g_tab_erreurs(g_erreurs).table_id := rec_erreur.table_id;
      g_tab_erreurs(g_erreurs).source := rec_erreur.source;
      g_tab_erreurs(g_erreurs).message_text := rec_erreur.message_text;
    END LOOP;
    IF g_tab_erreurs.count > 0 THEN
      writeout('LISTE DES REJETS :');
      writeout('------------------');
    
      FOR i IN g_tab_erreurs.first .. g_tab_erreurs.last LOOP
        l_message := RPAD('FOURNISSEUR : ' ||
                          NVL(g_tab_erreurs(i).supplier_number, ' '),
                          35,
                          ' ') ||
                     RPAD(' / VENDOR_SITE_ID : ' ||
                          NVL(g_tab_erreurs(i).vendor_site_id, ' '),
                          35,
                          ' ') || ' : ' ||
                     RPAD(g_tab_erreurs(i).message_text, 450);
        writeout(l_message);
      END LOOP;
    ELSE
      writeout('Aucune ligne en rejet');
    END IF;
  
    writeout('                                                                          ');
    writeout('                                                                          ');
  END SORTIE_TRAITEMENT;
  /*============================================================================*/
  /* Fonction          : fin_de_sortie                                      */
  /* Description       : fin de la sortie                 */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE fin_de_sortie IS
  
    l_procedure VARCHAR2(30) := 'fin_de_sortie';
    l_message   VARCHAR2(2000);
  
  BEGIN
    writeout('');
    writeout('');
  
    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('Programme terminé le : ' ||
             to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    writeout('                                                                           ');
    writeout('+-------------------------------------------------------------------------+');
  END fin_de_sortie;
  /*==============================================================================*/
  -- Procedure         : PURGE_TABLE
  -- Description       : Procédure pour purger les tables de tarvail
  -- Parametres entree : p_request_id
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              : 21/05/2020
  -- Remarques         :
  /*=================================================================================*/
  PROCEDURE PURGE_TABLE(p_request_id IN NUMBER) IS
  BEGIN
    DELETE FROM DKA_IPOFRS_MAJ_SITES_REPRIS
     WHERE LOADER_REQUEST_ID = p_request_id;
  
    COMMIT;
  END PURGE_TABLE;

  /*==============================================================================*/
  -- Procedure         : LANCE_CHARGEMENT_FICHIER
  -- Description       : Procédure pour lancer le cahrgement des tables de tarvail
  -- Parametres entree : AUCUN
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              : 18/05/2020
  -- Remarques         :
  /*=================================================================================*/
  PROCEDURE LANCE_CHARGEMENT_FICHIER(pv_errbuf     IN OUT VARCHAR2,
                                     pn_retcode    OUT NUMBER,
                                     p_nom_fichier IN VARCHAR2) IS
  
    l_procedure        VARCHAR2(30) := 'LANCE_CHARGEMENT_FICHIER';
    l_message          VARCHAR2(2000);
    l_request_id       NUMBER;
    l_application_code VARCHAR2(50) := 'DKA';
    l_conc_program     VARCHAR2(50) := 'DKA_IPOFRS_REP_IVALUA_LOADER';
    l_execute_code     BOOLEAN;
    l_req_interval     NUMBER := 30;
    l_req_max_wait     NUMBER := 999999;
    l_req_ret_code     NUMBER;
    l_req_phase        VARCHAR2(255);
    l_req_status       VARCHAR2(255);
    l_req_dev_phase    VARCHAR2(255);
    l_req_dev_status   VARCHAR2(255);
    l_status           VARCHAR2(255);
    l_req_message      VARCHAR2(255);
  
    v_record_id DKA_IPOCDE_LINES.record_id%TYPE;
    vf_errbuf   VARCHAR2(500);
    vf_retcode  NUMBER;
  BEGIN
    l_message := l_procedure || '- 01 - Debut';
    Fnd_File.put_line(Fnd_File.LOG, l_message);
  
    l_message := l_procedure || '- 02 - Submit Request';
    Fnd_File.put_line(Fnd_File.LOG, l_message);
    l_request_id := FND_REQUEST.submit_request(l_application_code,
                                               l_conc_program,
                                               '',
                                               SYSDATE,
                                               FALSE,
                                               p_nom_fichier);
  
    COMMIT;
    IF l_request_id != 0 THEN
      l_message := l_procedure || ' - 03 - Attente fin traitement';
      DKA_TOOLS_PKG.put_log_message(l_message);
      l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST(REQUEST_ID => l_request_id,
                                                        INTERVAL   => l_req_interval,
                                                        MAX_WAIT   => l_req_max_wait,
                                                        PHASE      => l_req_phase,
                                                        STATUS     => l_req_status,
                                                        DEV_PHASE  => l_req_dev_phase,
                                                        DEV_STATUS => l_req_dev_status,
                                                        MESSAGE    => l_req_message);
    
      IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
        l_status  := 'Avertissement';
        l_message := l_procedure ||
                     ' - 04a - Traitement terminé en avertissement';
        DKA_TOOLS_PKG.put_log_message(l_message);
        pn_retcode := 1;
      ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
        l_status  := 'Erreur';
        l_message := l_procedure || ' - 04b - Traitement terminé en erreur';
        DKA_TOOLS_PKG.put_log_message(l_message);
        pn_retcode := 2;
      ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'NORMAL' THEN
        l_status  := 'Normal';
        l_message := l_procedure || ' - 04b - Traitement terminé normal';
        DKA_TOOLS_PKG.put_log_message(l_message);
        Fnd_File.put_line(Fnd_File.LOG, l_message);
        pn_retcode := 0;
      
        IF vf_retcode = 2 THEN
          pn_retcode := 2;
        END IF;
      
        BEGIN
          UPDATE DKA_IPOFRS_MAJ_SITES_REPRIS set request_id = g_request_id;
        
        EXCEPTION
          WHEN OTHERS THEN
            l_message := l_procedure ||
                         ' - 03 - Avertissement lors de mise à jour du request_id dans la table temporaire';
            DKA_TOOLS_PKG.put_log_message(l_message);
            DBMS_OUTPUT.PUT_LINE(l_message);
            pn_retcode := 1;
        END;
      END IF;
    ELSE
      l_message := l_procedure ||
                   ' - 03 - Erreur lors du lancement du traitement';
      DKA_TOOLS_PKG.put_log_message(l_message);
      DBMS_OUTPUT.PUT_LINE(l_message);
      pn_retcode := 2;
    
    END IF;
    COMMIT;
    writeout('CHARGEMENT DU FICHIER :');
    writeout('-----------------------');
    writeout('. Numéro du traitement de chargement du fichier : ' ||
             l_request_id);
    writeout('. Statut de fin : Terminé/' || l_status);
    writeout('                                                                           ');
    writeout('                                                                           ');
  
  END LANCE_CHARGEMENT_FICHIER;
  /*============================================================================*/
  -- Procedure         : PURGE_DONNEE_TRAITEE
  -- Description       : préparer les donneés de la table de tarvail
  -- Parametres entree :
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              : 21/05/2020
  -- Remarques         :
  /*===============================================================================*/
  PROCEDURE PURGE_DONNEE(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    v_procedure VARCHAR2(30) := 'PURGE_DONNEE_TRAITEE';
    v_etape     VARCHAR2(500);
    v_message   VARCHAR2(500) := null;
  
  BEGIN
    DKA_TOOLS_PKG.put_log_message('Purge des enregistrements précédemment traités avec succès par l''interface des tables d''intefaces');
  
    DELETE FROM DKA_IPOFRS_MAJ_SITES_REPRIS;
    DELETE FROM DKA_PROGRAM_MESSAGES
     WHERE PROG_NAME = 'DKA_IPOFRS_REP_IVALUA';
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      v_message  := 'ERROR lors de la préparation des données' || SQLERRM;
      pn_retcode := 1;
      DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                     'DKA_IPOFRS_REP_IVALUA',
                                     'PURGE_DONNEE_TRAITEE',
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     'E',
                                     v_message);
  END PURGE_DONNEE;
  /*============================================================================*/
  -- Procedure         : PREPARATION_DONNEE
  -- Description       : préparer les donneés de la table de tarvail
  -- Parametres entree :
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              : 21/05/2020
  -- Remarques         :
  /*===============================================================================*/

  PROCEDURE CONTROLE_DONNEE(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode OUT NUMBER) IS
  
    v_procedure             VARCHAR2(30) := 'PREPARATION_DONNEE';
    v_etape                 VARCHAR2(500);
    v_message               VARCHAR2(500) := null;
    l_message               VARCHAR2(2000);
    l_validated             boolean;
    v_vendor_site_id        AP_SUPPLIER_SITES_ALL.vendor_site_id%TYPE;
    v_segment1              AP_SUPPLIERS.segment1%TYPE;
    v_count_vendor_site_id  NUMBER;
    v_count_ivalua_site_id  NUMBER;
    v_existance_site_uo_ref NUMBER;
    CURSOR donnee_a_controler IS
      SELECT * FROM DKA_IPOFRS_MAJ_SITES_REPRIS WHERE STATUT IN ('NEW');
  
  BEGIN
  
    FOR rec_a_controler IN donnee_a_controler LOOP
    
      l_validated             := true;
      v_count_vendor_site_id  := 0;
      v_count_ivalua_site_id  := 0;
      v_existance_site_uo_ref := 0;
      --   g_enreg_a_traite_entete := g_enreg_a_traite_entete + 1;
    
      if rec_a_controler.supplier_number is null then
        l_message := DKA_TOOLS_PKG.get_message('DKA', 'DKA_IPOFRS_REPR_003');
        DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                       'DKA_IPOFRS_REP_IVALUA',
                                       'CONTROLE',
                                       'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                       rec_a_controler.record_id,
                                       null,
                                       null,
                                       'E',
                                       l_message);
      
        l_validated := false;
      
      End if;
    
      if rec_a_controler.vendor_site_id is null then
        l_message := DKA_TOOLS_PKG.get_message('DKA', 'DKA_IPOFRS_REPR_004');
        DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                       'DKA_IPOFRS_REP_IVALUA',
                                       'CONTROLE',
                                       'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                       rec_a_controler.record_id,
                                       null,
                                       null,
                                       'E',
                                       l_message);
        /*   writeout('Fournisseur : ' || rec_a_controler.SUPPLIER_NUMBER ||
        ' / VENDOR_SITE_ID : ' || rec_a_controler.VENDOR_SITE_ID ||
        ' : ' || l_message);*/
        l_validated := false;
      
      End if;
    
      if rec_a_controler.ivalua_site_supplier_id is null then
        l_message := DKA_TOOLS_PKG.get_message('DKA', 'DKA_IPOFRS_REPR_005');
        DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                       'DKA_IPOFRS_REP_IVALUA',
                                       'CONTROLE',
                                       'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                       rec_a_controler.record_id,
                                       null,
                                       null,
                                       'E',
                                       l_message);
        /*writeout('Fournisseur : ' || rec_a_controler.SUPPLIER_NUMBER ||
        ' / VENDOR_SITE_ID : ' || rec_a_controler.VENDOR_SITE_ID ||
        ' : ' || l_message);*/
        l_validated := false;
      
      End if;
    
      BEGIN
        if rec_a_controler.supplier_number is not null then
          SELECT segment1
            into v_segment1
            from ap_suppliers ap
           where ap.segment1 = rec_a_controler.supplier_number;
        end if;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_message := DKA_TOOLS_PKG.get_message('DKA',
                                                 'DKA_IPOFRS_REPR_006',
                                                 'SUPPLIER_NUMBER',
                                                 rec_a_controler.supplier_number);
          DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                         'DKA_IPOFRS_REP_IVALUA',
                                         'CONTROLE',
                                         'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                         rec_a_controler.record_id,
                                         null,
                                         null,
                                         'E',
                                         l_message);
          /*  writeout('Fournisseur : ' || rec_a_controler.SUPPLIER_NUMBER ||
          ' / VENDOR_SITE_ID : ' ||
          rec_a_controler.VENDOR_SITE_ID || ' : ' || l_message);*/
          l_validated := false;
        
      END;
    
      BEGIN
        v_vendor_site_id := null;
        IF rec_a_controler.vendor_site_id is not null THEN
          SELECT vendor_site_id
            into v_vendor_site_id
            from ap_supplier_sites_all apsa
           where apsa.vendor_site_id = rec_a_controler.vendor_site_id;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_message := DKA_TOOLS_PKG.get_message('DKA',
                                                 'DKA_IPOFRS_REPR_007',
                                                 'VENDOR_SITE_ID',
                                                 rec_a_controler.vendor_site_id);
          DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                         'DKA_IPOFRS_REP_IVALUA',
                                         'CONTROLE',
                                         'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                         rec_a_controler.record_id,
                                         null,
                                         null,
                                         'E',
                                         l_message);
        
          l_validated := false;
        
      END;
    
      BEGIN
        IF rec_a_controler.vendor_site_id is not null and
           v_vendor_site_id is not null THEN
          SELECT vendor_site_id
            into v_vendor_site_id
            from ap_supplier_sites_all apsa, hr_all_organization_units houa
           where apsa.vendor_site_id = rec_a_controler.vendor_site_id
             and houa.organization_id = apsa.ORG_ID
             and houa.name = 'REF9999';
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_message := DKA_TOOLS_PKG.get_message('DKA',
                                                 'DKA_IPOFRS_REPR_008',
                                                 'VENDOR_SITE_ID',
                                                 rec_a_controler.vendor_site_id);
          DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                         'DKA_IPOFRS_REP_IVALUA',
                                         'CONTROLE',
                                         'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                         rec_a_controler.record_id,
                                         null,
                                         null,
                                         'E',
                                         l_message);
          /* writeout('Fournisseur : ' || rec_a_controler.SUPPLIER_NUMBER ||
          ' / VENDOR_SITE_ID : ' ||
          rec_a_controler.VENDOR_SITE_ID || ' : ' || l_message);*/
          l_validated := false;
        
      END;
    
      BEGIN
        IF rec_a_controler.vendor_site_id is not null and
           v_vendor_site_id is not null THEN
          SELECT vendor_site_id
            into v_segment1
            from ap_supplier_sites_all apsa, ap_suppliers ap
           where ap.VENDOR_ID = apsa.vendor_id
             and ap.segment1 = rec_a_controler.supplier_number
             and apsa.vendor_site_id = rec_a_controler.vendor_site_id;
        END IF;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          l_message := DKA_TOOLS_PKG.get_message('DKA',
                                                 'DKA_IPOFRS_REPR_009',
                                                 'VENDOR_SITE_ID',
                                                 rec_a_controler.vendor_site_id,
                                                 'SUPPLIER_NUMBER',
                                                 rec_a_controler.supplier_number);
          DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                         'DKA_IPOFRS_REP_IVALUA',
                                         'CONTROLE',
                                         'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                         rec_a_controler.record_id,
                                         null,
                                         null,
                                         'E',
                                         l_message);
          /* writeout('Fournisseur : ' || rec_a_controler.SUPPLIER_NUMBER ||
          ' / VENDOR_SITE_ID : ' ||
          rec_a_controler.VENDOR_SITE_ID || ' : ' || l_message);*/
          l_validated := false;
      END;
    
      SELECT count(*)
        into v_count_vendor_site_id
        from DKA_IPOFRS_MAJ_SITES_REPRIS
       where vendor_site_id = rec_a_controler.vendor_site_id;
    
      if v_count_vendor_site_id > 1 then
        l_message := DKA_TOOLS_PKG.get_message('DKA',
                                               'DKA_IPOFRS_REPR_010',
                                               'VENDOR_SITE_ID',
                                               rec_a_controler.vendor_site_id);
        DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                       'DKA_IPOFRS_REP_IVALUA',
                                       'CONTROLE',
                                       'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                       rec_a_controler.record_id,
                                       null,
                                       null,
                                       'E',
                                       l_message);
        /* writeout('Fournisseur : ' || rec_a_controler.SUPPLIER_NUMBER ||
        ' / VENDOR_SITE_ID : ' || rec_a_controler.VENDOR_SITE_ID ||
        ' : ' || l_message);*/
        l_validated := false;
      END IF;
    
      SELECT count(*)
        into v_count_ivalua_site_id
        from DKA_IPOFRS_MAJ_SITES_REPRIS
       where ivalua_site_supplier_id =
             rec_a_controler.ivalua_site_supplier_id;
    
      if v_count_ivalua_site_id > 1 then
        l_message := DKA_TOOLS_PKG.get_message('DKA',
                                               'DKA_IPOFRS_REPR_011',
                                               'IVALUA_SITE_SUPPLIER_ID',
                                               rec_a_controler.ivalua_site_supplier_id);
        DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                       'DKA_IPOFRS_REP_IVALUA',
                                       'CONTROLE',
                                       'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                       rec_a_controler.record_id,
                                       null,
                                       null,
                                       'E',
                                       l_message);
        /*writeout('Fournisseur : ' || rec_a_controler.SUPPLIER_NUMBER ||
        ' / VENDOR_SITE_ID : ' || rec_a_controler.VENDOR_SITE_ID ||
        ' : ' || l_message);*/
        l_validated := false;
      END IF;
    
      SELECT count(*)
        into v_existance_site_uo_ref
        from ap_supplier_sites_all apsa, hr_all_organization_units houa
       where apsa.vendor_site_id <> rec_a_controler.vendor_site_id
         and houa.organization_id = apsa.ORG_ID
         and houa.name = 'REF9999'
         and apsa.attribute4 = rec_a_controler.ivalua_site_supplier_id;
    
      if v_existance_site_uo_ref <> 0 then
        l_message := DKA_TOOLS_PKG.get_message('DKA',
                                               'DKA_IPOFRS_REPR_012',
                                               'IVALUA_SITE_SUPPLIER_ID',
                                               rec_a_controler.ivalua_site_supplier_id);
        DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                       'DKA_IPOFRS_REP_IVALUA',
                                       'CONTROLE',
                                       'DKA_IPOFRS_MAJ_SITES_REPRIS',
                                       rec_a_controler.record_id,
                                       null,
                                       null,
                                       'E',
                                       l_message);
        /*writeout('Fournisseur : ' || rec_a_controler.SUPPLIER_NUMBER ||
        ' / VENDOR_SITE_ID : ' || rec_a_controler.VENDOR_SITE_ID ||
        ' : ' || l_message);*/
        l_validated := false;
      End if;
    
      if l_validated = false then
      
        update DKA_IPOFRS_MAJ_SITES_REPRIS
           set statut           = 'REJECTED',
               request_id       = g_request_id,
               LAST_UPDATED_BY  = g_user,
               LAST_UPDATE_date = sysdate
         where record_id = rec_a_controler.record_id;
      
        pn_retcode := 1;
      
        --  g_enreg_entete_rejete1 := g_enreg_entete_rejete1 + 1;
      
      ELSE
      
        update DKA_IPOFRS_MAJ_SITES_REPRIS
           set statut           = 'VALIDATED',
               request_id       = g_request_id,
               LAST_UPDATED_BY  = g_user,
               LAST_UPDATE_date = sysdate
         where record_id = rec_a_controler.record_id;
        --   g_enreg_entete_succes := g_enreg_entete_succes + 1;
      
      END IF;
    END LOOP;
  
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      v_message  := 'ERROR lors de la préparation des données' || SQLERRM;
      pn_retcode := 1;
      DKA_TOOLS_PKG.ins_prog_message(g_request_id,
                                     'DKA_IPOFRS_REP_IVALUA',
                                     'PREPARATION_DONNEE',
                                     NULL,
                                     NULL,
                                     NULL,
                                     NULL,
                                     'E',
                                     v_message);
    
  END CONTROLE_DONNEE;

  /*============================================================================*/
  -- Procedure         : DETERMINATION_ACTION
  -- Description       : déterminer les action à effectuer sur chaque donnee de la
  --                     table de tarvail
  -- Parametres entree :
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              : 21/05/2020
  -- Remarques         :
  /*===============================================================================*/
  PROCEDURE MAJ_REFERENTIEL(pv_errbuf  IN OUT VARCHAR2,
                            pn_retcode OUT NUMBER) IS
  
    v_procedure VARCHAR2(30) := 'DETERMINATION_ACTION';
    v_etape     VARCHAR2(500);
    v_message   VARCHAR2(500) := null;
  
    CURSOR c_donne_ligne_maj IS
      SELECT * FROM DKA_IPOFRS_MAJ_SITES_REPRIS WHERE statut = 'VALIDATED';
  
  BEGIN
    v_etape := 'Mise à jour du site fournisseur';
    DKA_TOOLS_PKG.put_log_message(v_etape);
  
    FOR rec_donne_ligne_maj IN c_donne_ligne_maj LOOP
      BEGIN
        UPDATE AP_SUPPLIER_SITES_ALL APSA
           SET ATTRIBUTE4       = rec_donne_ligne_maj.IVALUA_SITE_SUPPLIER_ID,
               LAST_UPDATE_DATE = SYSDATE,
               LAST_UPDATED_BY  = g_user
         WHERE apsa.vendor_site_id = rec_donne_ligne_maj.vendor_site_id;
      
        UPDATE DKA_IPOFRS_MAJ_SITES_REPRIS
           set statut           = 'COMPLETE',
               request_id       = g_request_id,
               LAST_UPDATED_BY  = g_user,
               LAST_UPDATE_date = sysdate
         where record_id = rec_donne_ligne_maj.record_id;
      
      EXCEPTION
        WHEN OTHERS THEN
          v_etape := 'Erreur lors de mise à jour du site fournisseur';
          DKA_TOOLS_PKG.put_log_message(v_etape);
          UPDATE DKA_IPOFRS_MAJ_SITES_REPRIS
             set statut           = 'UPDATE_REJECTED',
                 request_id       = g_request_id,
                 LAST_UPDATED_BY  = g_user,
                 LAST_UPDATE_date = sysdate
           where record_id = rec_donne_ligne_maj.record_id;
        
      END;
    END LOOP;
    COMMIT;
  END MAJ_REFERENTIEL;
  /*============================================================================*/
  -- Procedure         : VALIDATION_DONNEES
  -- Description       : valider les données de la table de tarvail
  -- Parametres entree :
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              : 22/05/2020
  -- Remarques         :
  /*===============================================================================*/
  PROCEDURE BILAN(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    CURSOR C_DONNEE_RG501 IS
      SELECT AP.SEGMENT1, APSA.VENDOR_SITE_ID
        FROM AP_SUPPLIERS              AP,
             AP_SUPPLIER_SITES_ALL     APSA,
             HR_ALL_ORGANIZATION_UNITS HOUA
       WHERE AP.VENDOR_ID = APSA.VENDOR_ID
         AND apsa.ATTRIBUTE4 IS NULL
         and apsa.org_id = houa.organization_id
         and houa.name = 'REF9999'
       ORDER BY AP.SEGMENT1, APSA.VENDOR_SITE_ID;
  
    CURSOR C_DONNEE_RG502 IS
      SELECT AP.SEGMENT1, APSA.ATTRIBUTE4, apsa.vendor_site_id
        FROM AP_SUPPLIERS              AP,
             AP_SUPPLIER_SITES_ALL     APSA,
             HR_ALL_ORGANIZATION_UNITS HOUA
       WHERE AP.VENDOR_ID = APSA.VENDOR_ID
         AND apsa.org_id = houa.organization_id
         and houa.name = 'REF9999'
         AND 1 < (select count(distinct vendor_site_id)
                    from AP_SUPPLIER_SITES_ALL     APS,
                         HR_ALL_ORGANIZATION_UNITS HOU
                   where aps.attribute4 = apsa.attribute4
                     and aps.org_id = hou.organization_id
                     and hou.name = 'REF9999')
       order by APSA.ATTRIBUTE4, AP.SEGMENT1, apsa.vendor_site_id;
  
    v_procedure   VARCHAR2(30) := 'VALIDATION_DONNEES';
    v_etape       VARCHAR2(500);
    v_message     VARCHAR2(500) := null;
    l_message     VARCHAR2(2000);
    v_count_RG501 NUMBER := 0;
    V_count_RG502 NUMBER := 0;
  
  BEGIN
    writeout('BILAN :');
    writeout('-------');
    BEGIN
      select count(*)
        into v_count_RG501
        from (SELECT AP.SEGMENT1, APSA.VENDOR_SITE_ID
                FROM AP_SUPPLIERS              AP,
                     AP_SUPPLIER_SITES_ALL     APSA,
                     HR_ALL_ORGANIZATION_UNITS HOUA
               WHERE AP.VENDOR_ID = APSA.VENDOR_ID
                 AND apsa.ATTRIBUTE4 IS NULL
                 and apsa.org_id = houa.organization_id
                 and houa.name = 'REF9999');
    EXCEPTION
      WHEN OTHERS THEN
      
        v_etape := 'Erreur récupération nombre anomalie RG501';
        DKA_TOOLS_PKG.put_log_message(v_etape);
        v_count_RG501 := 0;
    END;
  
    writeout('SITES FOURNISSEURS SANS ID IVALUA : ' || V_count_RG501);
    FOR rec_donnee_RG501 IN C_DONNEE_RG501 LOOP
    
      l_message := RPAD('FOURNISSEUR : ' ||
                        NVL(to_char(rec_donnee_RG501.SEGMENT1), ' '),
                        35,
                        ' ') ||
                   RPAD(' / VENDOR_SITE_ID : ' ||
                        NVL(to_char(rec_donnee_RG501.vendor_site_id), ' '),
                        45,
                        ' ');
      writeout(l_message);
    END LOOP;
  
    writeout(' ');
  
    BEGIN
      select count(*)
        into V_count_RG502
        from (SELECT AP.SEGMENT1, APSA.ATTRIBUTE4, apsa.vendor_site_id
                FROM AP_SUPPLIERS              AP,
                     AP_SUPPLIER_SITES_ALL     APSA,
                     HR_ALL_ORGANIZATION_UNITS HOUA
               WHERE AP.VENDOR_ID = APSA.VENDOR_ID
                 AND apsa.org_id = houa.organization_id
                 and houa.name = 'REF9999'
                 AND 1 < (select count(distinct vendor_site_id)
                            from AP_SUPPLIER_SITES_ALL     APS,
                                 HR_ALL_ORGANIZATION_UNITS HOU
                           where aps.attribute4 = apsa.attribute4
                             and aps.org_id = hou.organization_id
                             and hou.name = 'REF9999'));
    
    EXCEPTION
      WHEN OTHERS THEN
        v_etape := 'Erreur récupération nombre anomalie RG502';
        DKA_TOOLS_PKG.put_log_message(v_etape);
        V_count_RG502 := 0;
    END;
  
    writeout('SITES FOURNISSEURS AVEC ID IVALUA NON UNIQUE : ' ||
             V_count_RG502);
    FOR rec_donnee_RG502 IN C_DONNEE_RG502 LOOP
    
      l_message := RPAD('FOURNISSEUR : ' ||
                        NVL(to_char(rec_donnee_RG502.segment1), ' '),
                        35,
                        ' ') ||
                   RPAD(' / VENDOR_SITE_ID : ' ||
                        NVL(to_char(rec_donnee_RG502.vendor_site_id), ' '),
                        35,
                        ' ') ||
                   RPAD(' / ID IVALUA : ' ||
                        NVL(to_char(rec_donnee_RG502.ATTRIBUTE4), ' '),
                        35,
                        ' ');
      writeout(l_message);
    END LOOP;
  
    writeout(' ');
  
    IF V_count_RG501 <> 0 or V_count_RG502 <> 0 THEN
      pn_retcode := 1;
    END IF;
  
  END BILAN;
  /*======================================================================================================*/
  --  Nom           : INIT_SEQUENCE
  --  Description   : Procédure pour initialiser la sequence
  --  DATE          : 18/06/2020
  /*=========================================================================================================*/
  PROCEDURE INIT_SEQUENCE IS
  BEGIN
    execute immediate 'drop sequence DKA.DKA_IPOFRS_MAJ_SITES_REPRIS_S';
    execute immediate 'CREATE SEQUENCE DKA.DKA_DKA_IPOFRS_MAJ_SITES_REPRIS_S INCREMENT BY 1';
  
  END;

  /*============================================================================*/
  -- Procedure         : ENREGISTREMENT_COMPTEUR
  -- Description       : 
  -- Parametres entree :
  -- Parametres sortie : AUCUN
  -- Auteur            : 
  -- Date              :
  -- Remarques         :
  /*===============================================================================*/
  PROCEDURE ENREGISTREMENT_COMPTEUR(pv_errbuf  IN OUT VARCHAR2,
                                    pn_retcode OUT NUMBER) IS
  
    v_procedure VARCHAR2(30) := 'ENREGISTREMENT_COMPTEUR';
    v_etape     VARCHAR2(500);
    v_message   VARCHAR2(500) := null;
  
  BEGIN
  
    g_enreg_a_traite_entete := 0;
    g_enreg_entete_succes   := 0;
    g_enreg_entete_rejete1  := 0;
  
    SELECT COUNT(*)
      INTO g_enreg_a_traite_entete
      FROM DKA_IPOFRS_MAJ_SITES_REPRIS
      where request_id = g_request_id;
  
    SELECT COUNT(*)
      INTO g_enreg_entete_succes
      FROM DKA_IPOFRS_MAJ_SITES_REPRIS
     WHERE STATUT in ('VALIDATED', 'COMPLETE')
     and request_id = g_request_id;
  
    SELECT COUNT(*)
      INTO g_enreg_entete_rejete1
      FROM DKA_IPOFRS_MAJ_SITES_REPRIS
     WHERE STATUT = 'REJECTED'
     and request_id = g_request_id;
     
  END;
  /*======================================================================================================*/
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 26/05/2020
  /*=========================================================================================================*/
  PROCEDURE MAIN(pv_errbuf     IN OUT VARCHAR2,
                 pn_retcode    OUT NUMBER,
                 p_nom_fichier IN VARCHAR2,
                 p_maj         IN VARCHAR2) IS
  
    v_package        VARCHAR2(30) := 'DKA_IPOFRS_REP_IVALUA_PKG';
    v_nom_traitement VARCHAR2(200) := 'Reprises des fournisseurs';
    v_procedure      VARCHAR2(30) := 'MAIN';
    v_sqlerrm        VARCHAR2(250) := NULL;
    v_message        VARCHAR2(500);
    v_phase          VARCHAR2(500);
    v_etape          VARCHAR2(500);
    vf_errbuf        VARCHAR2(500);
    vf_retcode       NUMBER;
    v_exeption EXCEPTION;
  BEGIN
    v_phase := 'PHASE Préliminaire';
    DKA_TOOLS_PKG.put_log_message(v_phase);
  
    entete_de_sortie(p_nom_fichier, p_maj);
    IF p_nom_fichier is not null THEN
      PURGE_DONNEE(vf_errbuf, vf_retcode);
      IF vf_retcode = 1 THEN
        pn_retcode := 1;
      END IF;
    END IF;
  
    IF p_nom_fichier is not null THEN
      v_phase := 'PHASE chargement des tables de travail';
      DKA_TOOLS_PKG.put_log_message(v_phase);
      DBMS_OUTPUT.PUT_LINE(v_phase);
      LANCE_CHARGEMENT_FICHIER(vf_errbuf, vf_retcode, p_nom_fichier);
      IF vf_retcode = 2 THEN
        Dka_Tools_Pkg.put_outdebug_message('Chargement des fichiers en erreur');
        v_message  := 'Erreur lors du chargement des fichiers. Voir la sortie du traitement de chargement pour plus d''informations';
        pn_retcode := 2;
        RAISE v_exeption;
      END IF;
    END IF;
  
    v_phase := 'PHASE Controle des données';
    DKA_TOOLS_PKG.put_log_message(v_phase);
    CONTROLE_DONNEE(vf_errbuf, vf_retcode);
  
    IF vf_retcode = 1 THEN
      pn_retcode := 1;
    END IF;
  
    IF P_mAJ = 'OUI' THEN
      v_phase := 'PHASE Mise à jour';
      DKA_TOOLS_PKG.put_log_message(v_phase);
      MAJ_REFERENTIEL(vf_errbuf, vf_retcode);
      IF vf_retcode = 1 THEN
        pn_retcode := 1;
      END IF;
    END IF;
  
    --Calcul des compteurs après traitement des données.
    ENREGISTREMENT_COMPTEUR(vf_errbuf, vf_retcode);
    IF vf_retcode = 1 THEN
      pn_retcode := 1;
    END IF;
  
    SORTIE_TRAITEMENT;
  
    IF P_mAJ = 'OUI' THEN
      v_phase := 'PHASE Bilan après mise à jour';
      DKA_TOOLS_PKG.put_log_message(v_phase);
      BILAN(vf_errbuf, vf_retcode);
      IF vf_retcode = 1 THEN
        pn_retcode := 1;
      END IF;
    END IF;
  
    IF pn_retcode = 2 THEN
      pv_errbuf    := 'ATTENTION : Erreur bloquante : ' || pv_errbuf;
      g_statut_fin := 'Erreur';
    ELSIF (pn_retcode = 1) THEN
      pv_errbuf    := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
      pn_retcode   := 1;
      g_statut_fin := 'Avertissement';
    ELSE
      pv_errbuf    := 'Fin normale du traitement - Aucun rejet.';
      pn_retcode   := 0;
      g_statut_fin := 'Fin normale';
    END IF;
  
    writeout(pv_errbuf);
    fin_de_sortie;
  EXCEPTION
    WHEN v_exeption THEN
      --p_retcode := 2;
      --p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
      Dka_Tools_Pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      Dka_Tools_Pkg.put_outdebug_message('Package   : ' || v_package);
      Dka_Tools_Pkg.put_outdebug_message('Procédure : ' || v_procedure);
      Dka_Tools_Pkg.put_outdebug_message('Message   : ' || v_message);
      Dka_Tools_Pkg.put_log_message('Cause     : ' || pv_errbuf);
      Dka_Tools_Pkg.put_outdebug_message('------------------------------------------------');
      Dka_Tools_Pkg.put_outdebug_message(TO_CHAR(SYSDATE,
                                                 'DD/MM/YYYY HH24:MI:SS') ||
                                         ' - ' || 'Fin de la procédure ' ||
                                         v_procedure ||
                                         ' : EXCEPTION v_exeption ');
      Dka_Tools_Pkg.put_log_message('==> Fin de la procédure ' ||
                                    v_procedure ||
                                    ' : EXCEPTION v_exeption ');
      Dka_Tools_Pkg.put_log_message('=========================================================================');
      Dka_Tools_Pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      Dka_Tools_Pkg.put_log_message('=========================================================================');
      ROLLBACK;
    
    WHEN OTHERS THEN
      v_sqlerrm  := SUBSTR(SQLERRM, 1, 200);
      pn_retcode := 2;
      pv_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc ' ||
                    v_package || '.' || v_procedure;
      Dka_Tools_Pkg.put_outdebug_message('-------------------- ERREUR --------------------');
      Dka_Tools_Pkg.put_outdebug_message('Package   : ' || v_package);
      Dka_Tools_Pkg.put_outdebug_message('Procédure : ' || v_procedure);
      Dka_Tools_Pkg.put_outdebug_message('Exception : OTHERS');
      Dka_Tools_Pkg.put_outdebug_message('Message   : ' || v_message);
      Dka_Tools_Pkg.put_log_message(CHR(10) || pv_errbuf);
      Dka_Tools_Pkg.put_outdebug_message('Cause     : ' || v_sqlerrm);
      Dka_Tools_Pkg.put_outdebug_message('------------------------------------------------');
      Dka_Tools_Pkg.put_log_message('=========================================================================');
      Dka_Tools_Pkg.put_log_message('Traitement ' || v_nom_traitement ||
                                    ' terminé en erreur         ');
      Dka_Tools_Pkg.put_log_message('=========================================================================');
      ROLLBACK;
    
  END MAIN;

END DKA_IPOFRS_REP_IVALUA_PKG;
/
SHOW ERRORS
EXIT