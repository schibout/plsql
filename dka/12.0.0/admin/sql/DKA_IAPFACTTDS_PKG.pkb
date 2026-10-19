CREATE OR REPLACE PACKAGE BODY DKA_IAPFACTTDS_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI AMS1
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_IAPFACTTDS_PKG.pks
  -- DESCRIPTION       : DKA_IAPFACTTDS_PKG package spec :
  ---
  --- AUTEUR       : Jerome WYCKAERT (JWYC)
  --- DATE DE CREATION : 24/07/2017
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --
  -- MODIFICATION
  --
  ---------------------------------------------------------------------------------------------------------------
  -- Version     : 1.1
  -- Date        : 23/11/2017 
  -- Auteur      : Maxime EGOT
  -- Description : HELIOS Migration R12
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_step VARCHAR2(100);

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : determination_statut_comm
  --  Description   : Procedure afin de determiner le statut et le commentaire de la facture placee en parametre

  --  PARAMETRES    :    pn_invoice_id   Entree           Identifiant de la facture
  --                     pn_fact_ok      Sortie           Flag indiquant si la facture peut-etre archivee
  --                     pv_errbuf       Entree/Sortie    message d'erreur
  --                     pn_retcode      Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION determination_statut_comm(pn_invoice_id IN NUMBER,
                                     pn_fact_ok    OUT NUMBER,
                                     pv_errbuf     IN OUT VARCHAR2,
                                     pn_retcode    OUT NUMBER) RETURN STATUS_COMMENT_TYP IS
  
    vv_proc      VARCHAR2(50) := 'determination_statut_comm';
    vs_stat_comm STATUS_COMMENT_TYP := NULL;
  
    vv_lookup_code       AP_INVOICES_ALL.PAY_GROUP_LOOKUP_CODE%TYPE;
    vv_pmtdir            VARCHAR2(1);
    vd_date_annulation   DATE;
    vn_held_by           NUMBER(15);
    vv_holder_num        VARCHAR2(30);
    vv_holder_name       VARCHAR2(240);
    vn_cpt_hold          NUMBER;
    vn_blocages_en_cours NUMBER;
    vd_due_date          DATE;
    vn_reglement_ok      NUMBER;
    vn_mt_regle          NUMBER;
    vd_check_date        DATE;
    vn_reglement_ok2     NUMBER;
    vv_assigned_num      VARCHAR2(30);
    vv_assigned_name     VARCHAR2(240);
  
  BEGIN
  
    DKA_TOOLS_PKG.put_debug_message('Facture : ' || pn_invoice_id);
    gv_step := '001 - Get Lookup Code';
  
    pn_fact_ok := 0;
  
    -- Recuperation de la classe de reglement afin de determiner s'il s'agit d'un paiement direct ou non
    SELECT PAY_GROUP_LOOKUP_CODE INTO vv_lookup_code FROM AP_INVOICES_ALL WHERE INVOICE_ID = pn_invoice_id;
  
    -- Alimentation du flag contenant le type de paiement, utilise par la suite pour determiner le commentaire
    IF vv_lookup_code = 'PMTDIR' THEN
      vv_pmtdir := 'D';
    ELSE
      vv_pmtdir := 'I';
    END IF;
  
    gv_step := '002 - Verification facture annulee';
  
    -- La facture est-elle annulee ?
    BEGIN
    
      SELECT CANCELLED_DATE
        INTO vd_date_annulation
        FROM AP_INVOICES_ALL
       WHERE INVOICE_ID = pn_invoice_id
         AND CANCELLED_DATE IS NOT NULL;
    
      vs_stat_comm.status  := 'BusinessReject';
      vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA',
                                                        'DKA_IAPFACTTDS_060_' || vv_pmtdir,
                                                        'DATE_ANNULATION',
                                                        to_char(vd_date_annulation, 'DD/MM/YYYY'));
    
      -- Mise à jour du flag permettant l'archivage de la facture
      pn_fact_ok := 1;
    
      RETURN vs_stat_comm;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
      
    END;
  
    -- La facture est-elle en litige ?
    BEGIN
    
      gv_step := '003 - Verification facture en litige';
    
      SELECT HELD_BY
        INTO vn_held_by
        FROM AP_HOLDS_ALL
       WHERE INVOICE_ID = pn_invoice_id
         AND LOWER(HOLD_LOOKUP_CODE) LIKE '%litige%'
         AND release_reason IS NULL
         AND ROWNUM = 1;
    
      SELECT USER_NAME INTO vv_holder_num FROM FND_USER WHERE USER_ID = vn_held_by;
    
      BEGIN
        SELECT FULL_NAME
          INTO vv_holder_name
          FROM PER_ALL_PEOPLE_F
         WHERE EMPLOYEE_NUMBER = vv_holder_num
           AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vv_holder_name := NULL;
      END;
    
      vs_stat_comm.status  := 'BusinessDisputed';
      vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA',
                                                        'DKA_IAPFACTTDS_040_' || vv_pmtdir,
                                                        'HOLD_BY',
                                                        nvl(vv_holder_name, vv_holder_num));
    
      RETURN vs_stat_comm;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        NULL;
    END;
  
    gv_step := '004 - Verification blocage paiement';
  
    -- La facture est-elle bloquee au paiement ?
    SELECT count(*)
      INTO vn_cpt_hold
      FROM AP_PAYMENT_SCHEDULES_ALL
     WHERE INVOICE_ID = pn_invoice_id
       AND hold_flag = 'Y';
  
    IF (vn_cpt_hold > 0) THEN
      vs_stat_comm.status  := 'BusinessDisputed';
      vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA', 'DKA_IAPFACTTDS_041_' || vv_pmtdir);
    
      RETURN vs_stat_comm;
    
    END IF;
  
    -- Recuperation du nombre de blocages
    gv_step := '005 - Verification nombre blocages';
  
    SELECT count(*)
      INTO vn_blocages_en_cours
      FROM AP_HOLDS_ALL
     WHERE INVOICE_ID = pn_invoice_id
       AND RELEASE_REASON IS NULL;
  
    IF (vn_blocages_en_cours > 0) THEN
    
      gv_step := '006 - Recuperation date echeance';
    
      -- Recuperation de la date d'echeance la plus grande
      SELECT MAX(DUE_DATE) INTO vd_due_date FROM AP_PAYMENT_SCHEDULES_ALL WHERE INVOICE_ID = pn_invoice_id;
    
      gv_step := '007 - Verification de l''echeance';
    
      -- Si la date est non echue ...
      IF (vd_due_date > trunc(sysdate - 0.5)) THEN
        gv_step := '007a - Facture non echue';
      
        vs_stat_comm.status  := 'BusinessDelivered';
        vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA',
                                                          'DKA_IAPFACTTDS_020_' || vv_pmtdir,
                                                          'DUE_DATE',
                                                          to_char(vd_due_date, 'DD/MM/YYYY'));
      
        RETURN vs_stat_comm;
      
        -- Sinon, la date est en cours
      ELSE
      
        gv_step := '007b - Facture en cours';
      
        BEGIN
        
          SELECT DISTINCT ASSIGNED_USER
            INTO vv_assigned_num
            FROM AP_HOLDS_ALL aha, WF_ITEM_ACTIVITY_STATUSES wias
           WHERE aha.INVOICE_ID = pn_invoice_id
             AND aha.ATTRIBUTE2 IS NOT NULL
             AND aha.RELEASE_REASON IS NULL
             AND wias.ITEM_TYPE = 'DKA_CSP'
             AND wias.ITEM_KEY = aha.ATTRIBUTE2
             AND wias.ACTIVITY_STATUS = 'NOTIFIED'
             AND substr(assigned_user, 1, 8) NOT IN ('SYSADMIN', 'FND_RESP');
        
          BEGIN
          
            SELECT FULL_NAME
              INTO vv_assigned_name
              FROM PER_ALL_PEOPLE_F
             WHERE EMPLOYEE_NUMBER = vv_assigned_num
               AND ROWNUM = 1;
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vv_assigned_name := vv_assigned_num;
          END;
        
          vs_stat_comm.status  := 'BusinessDelivered';
          vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA',
                                                            'DKA_IAPFACTTDS_031_' || vv_pmtdir,
                                                            'FULL_NAME',
                                                            vv_assigned_name);
        
          RETURN vs_stat_comm;
        
        EXCEPTIOn
          WHEN NO_DATA_FOUND THEN
            -- Facture sans notification
            vs_stat_comm.status  := 'BusinessDelivered';
            vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA', 'DKA_IAPFACTTDS_030_' || vv_pmtdir);
          
            RETURN vs_stat_comm;
          
          WHEN TOO_MANY_ROWS THEN
            -- Facture avec plusieurs notifications
            vs_stat_comm.status  := 'BusinessDelivered';
            vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA', 'DKA_IAPFACTTDS_032_' || vv_pmtdir);
          
            RETURN vs_stat_comm;
          
        END;
      
      END IF;
    
      -- pas de blocages
    ELSE
    
      gv_step := '007 - Verification reglements';
    
      /* On verifie s'il existe des reglements (totaux ou partiels) */
      SELECT COUNT(*)
        INTO vn_reglement_ok
        FROM AP_PAYMENT_SCHEDULES_ALL
       WHERE INVOICE_ID = pn_invoice_id
         AND PAYMENT_STATUS_FLAG != 'N';
    
      /* S'il n'y a pas encore de reglements ... =>   Valide BusinessAccept */
      IF (vn_reglement_ok = 0) THEN
      
        vs_stat_comm.status := 'BusinessAccept';
      
        IF (vv_pmtdir = 'I') THEN
        
          SELECT MAX(DUE_DATE) INTO vd_due_date FROM AP_PAYMENT_SCHEDULES_ALL WHERE INVOICE_ID = pn_invoice_id;
        
          vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA',
                                                            'DKA_IAPFACTTDS_050_' || vv_pmtdir,
                                                            'DUE_DATE',
                                                            to_char(vd_due_date, 'DD/MM/YYYY'));
        
        ELSE
          vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA', 'DKA_IAPFACTTDS_050_' || vv_pmtdir);
        END IF;
      
        RETURN vs_stat_comm;
      
        -- Paye BusinessPaid
      ELSE
      
        vs_stat_comm.status := 'BusinessPaid';
        IF (vv_pmtdir = 'D') THEN
          vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA', 'DKA_IAPFACTTDS_010_D');
        
        ELSE
        
          -- recuperer la date et le montant de reglement
          -- on peut regarder si la somme des AMOUNT_REMANING de la table AP_PAYMENT_SCHEDULES_ALL est = à 0
          -- Si oui, facture totalement reglee, si non, facture partiellement reglee
          SELECT SUM(GROSS_AMOUNT - AMOUNT_REMAINING)
            INTO vn_mt_regle
            FROM AP_PAYMENT_SCHEDULES_ALL
           WHERE INVOICE_ID = pn_invoice_id;
        
          BEGIN
          
            SELECT CHECK_DATE
              INTO vd_check_date
              FROM AP_CHECKS_ALL
             WHERE CHECK_ID = (SELECT MAX(CHECK_ID) FROM AP_INVOICE_PAYMENTS_ALL WHERE INVOICE_ID = pn_invoice_id);
          
            -- IF check date is null => rapproche par un acompte ???
          
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vd_check_date := NULL;
          END;
        
          IF (vd_check_date IS NULL) THEN
            vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA',
                                                              'DKA_IAPFACTTDS_011_I',
                                                              'PAYMENT_AMOUNT',
                                                              vn_mt_regle);
          
          ELSE
          
            vs_stat_comm.COMMENT := Dka_Tools_Pkg.get_message('DKA',
                                                              'DKA_IAPFACTTDS_010_I',
                                                              'PAYMENT_DATE',
                                                              to_char(vd_check_date, 'DD/MM/YYYY'),
                                                              'PAYMENT_AMOUNT',
                                                              vn_mt_regle);
          
          END IF;
        
        END IF;
      
        SELECT COUNT(*)
          INTO vn_reglement_ok2
          FROM AP_PAYMENT_SCHEDULES_ALL
         WHERE INVOICE_ID = pn_invoice_id
           AND PAYMENT_STATUS_FLAG != 'Y';
      
        /* Si tous les reglements sont complets ... */
        IF (vn_reglement_ok2 = 0) THEN
          -- Mise à jour du flag permettant l'archivage de la facture
          pn_fact_ok := 1;
        END IF;
      
        RETURN vs_stat_comm;
      
      END IF;
    
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
    
      pv_errbuf  := 'Erreur lors de "' || vv_proc || '" : ' || gv_step || ' : ' || SQLERRM;
      pn_retcode := 2;
    
  END;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : update_factures
  --  Description   : Procedure de mise à jour du statut/commentaire d'une facture dejà existante dans la table de travail

  --  PARAMETRES    :
  --                     pv_errbuf     Entree/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE update_factures(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    CURSOR liste_factures IS
      SELECT invoice_id FROM DKA_IAPFACTTDS_TAB;
  
    vv_proc           VARCHAR2(50) := 'update_factures';
    vs_status_comment STATUS_COMMENT_TYP;
  
    vn_fact_ok NUMBER;
    e_error_determ EXCEPTION;
  
  BEGIN
  
    DKA_TOOLS_PKG.put_debug_message('Mise à jour du statut des factures');
    gv_step := '001 - Boucle determination statut';
  
    FOR IC in liste_factures LOOP
      vs_status_comment := determination_statut_comm(IC.invoice_id, vn_fact_ok, pv_errbuf, pn_retcode);
    
      IF (pn_retcode != 0) THEN
        RAISE e_error_determ;
      END IF;
    
      UPDATE DKA_IAPFACTTDS_TAB
         SET NV_STATUT       = vs_status_comment.status,
             NV_COMMENTAIRE  = vs_status_comment.comment,
             FLAG_A_ARCHIVER = vn_fact_ok
       WHERE invoice_id = IC.invoice_id;
    
    END LOOP;
  
    gv_step := '002 - Mise à jour du FLAG_ENVOI';
  
    UPDATE DKA_IAPFACTTDS_TAB SET FLAG_ENVOI = 1 WHERE nvl(COMMENTAIRE, 'vide') != nvl(NV_COMMENTAIRE, 'vide');
  
  EXCEPTION
    WHEN e_error_determ THEN
      --DKA_TOOLS_PKG.put_debug_message(pv_errbuf);
      null;
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur lors de "' || vv_proc || '" : ' || gv_step || ' : ' || SQLERRM;
      pn_retcode := 2;
    
  END update_factures;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insert_factures
  --  Description   : Procedure d'ajout d'une nouvelle facture existante dans la table de travail

  --  PARAMETRES    :
  --                     pv_errbuf     Entree/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE insert_factures(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    vv_proc           VARCHAR2(50) := 'insert_factures';
    vd_dernier_envoi  DATE;
    vv_prefixe_xerox  VARCHAR2(10);
    vn_prefixe_length NUMBER;
    vv_err_msg        VARCHAR2(500);
    vn_retcode        NUMBER;
    vr_data           dka_parameters%ROWTYPE;
    e_error_param EXCEPTION;
  
  BEGIN
  
    DKA_TOOLS_PKG.put_debug_message('Insertion des nouvelles factures');
    gv_step := '001 - get_parameter';
  
    BEGIN
    
      dka_tools_pkg.get_parameter('DKA_IAPFACTTDS', 'DATE_DERNIERE_EXTRACTION', vr_data, vn_retcode, vv_err_msg);
      vd_dernier_envoi := vr_data.date_value;

      DKA_TOOLS_PKG.put_debug_message('Date d''extraction : ' || to_char(vd_dernier_envoi, 'DD/MM/YYYY HH24:MI:SS'));
    
      IF ((vn_retcode != 0) OR (vd_dernier_envoi is null)) THEN
        RAISE e_error_param;
      END IF;
    
      dka_tools_pkg.get_parameter('DKA_IAPFACTTDS', 'PREFIXE_IMAGE_XEROX', vr_data, vn_retcode, vv_err_msg);
      vv_prefixe_xerox := vr_data.varchar2_value;
    
      DKA_TOOLS_PKG.put_debug_message('Prefixe image Xerox : ' || vv_prefixe_xerox);
    
      vn_prefixe_length := length(vv_prefixe_xerox);
    
      IF ((vn_retcode != 0) OR (vv_prefixe_xerox is null)) THEN
        RAISE e_error_param;
      END IF;
    
    END;
  
    gv_step := '002 - insert';
  
    INSERT INTO DKA_IAPFACTTDS_TAB
      (REGION, NO_FOURNISSEUR, NUM_FACT, DATE_FACT, DATE_IMPORT, ORIGINE, INVOICE_ID, REFERENCE_LAD)
      SELECT gcc.segment2,
             pv.segment1,
             aia.invoice_num,
             aia.invoice_date,
             sysdate,
             DECODE(substr(aia.attribute3, 1, vn_prefixe_length), vv_prefixe_xerox, 1, 0), -- creer parametre pour les 2 premieres lettres
             aia.invoice_id,
             aia.attribute3
        FROM AP_invoices_all aia, gl_code_combinations gcc, po_vendors pv
       WHERE 1=1
       --AND aia.source = 'SCAN_XGS'
         AND (aia.source IN ('SCAN_XGS') OR (aia.source IN ('REPRISE') AND aia.attribute9 = 'XGS'))
         AND aia.creation_date > vd_dernier_envoi
         AND aia.vendor_id = pv.vendor_id
         AND gcc.code_combination_id = aia.accts_pay_code_combination_id
         AND aia.invoice_id not in (select invoice_id
                                      from DKA_IAPFACTTDS_TAB
                                    UNION
                                    select invoice_id from DKA_IAPFACTTDS_HIST);
  
    DKA_TOOLS_PKG.put_debug_message(SQL%ROWCOUNT || ' lignes inserees');
  
  EXCEPTION
    WHEN e_error_param THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur lors de la recuperation du parametre';
    
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur lors de "' || vv_proc || '" : ' || gv_step || ' : ' || SQLERRM;
    
  END insert_factures;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insert_factures
  --  Description   : Procedure pour deplacer les nouveaux status/commentaires du traitement precedent
  --                dans les colonnes courantes

  --  PARAMETRES    :
  --                     pv_errbuf     Entree/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE reinitialisation_statuts(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    vv_proc VARCHAR2(50) := 'reinitialisation_statuts';
  
  BEGIN
  
    DKA_TOOLS_PKG.put_debug_message('Reinitialisation des factures');
    gv_step := '001 - reinitialisation_statuts';
  
    UPDATE DKA_IAPFACTTDS_TAB
       SET STATUT = NV_STATUT, COMMENTAIRE = NV_COMMENTAIRE, FLAG_ENVOI = 0, NV_STATUT = NULL, NV_COMMENTAIRE = NULL;
  
    DKA_TOOLS_PKG.put_debug_message(SQL%ROWCOUNT || ' factures ont ete reinitialisees');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur lors de "' || vv_proc || '" : ' || gv_step || ' : ' || SQLERRM;
      pn_retcode := 2;
    
  END reinitialisation_statuts;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : archivage_factures
  --  Description   : Procedure d'archivage des factures totalement reglees ou annulees

  --  PARAMETRES    :
  --                     pv_errbuf     Entree/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE archivage_factures(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    vv_proc VARCHAR2(50) := 'archivage_factures';
  
  BEGIN
  
    DKA_TOOLS_PKG.put_debug_message('Archivage des factures');
    gv_step := '001 - Insert';
  
    INSERT INTO DKA_IAPFACTTDS_HIST
      SELECT REGION,
             NO_FOURNISSEUR,
             NUM_FACT,
             DATE_FACT,
             STATUT,
             DATE_IMPORT,
             COMMENTAIRE,
             ORIGINE,
             INVOICE_ID,
             REFERENCE_LAD,
             sysdate
        FROM DKA_IAPFACTTDS_TAB
       WHERE FLAG_A_ARCHIVER = 1;
  
    DKA_TOOLS_PKG.put_debug_message(SQL%ROWCOUNT || ' lignes ont ete archivees');
    gv_step := '002 / Delete';
  
    DELETE FROM DKA_IAPFACTTDS_TAB WHERE FLAG_A_ARCHIVER = 1;
  
    DKA_TOOLS_PKG.put_debug_message(SQL%ROWCOUNT || ' lignes ont ete suprimees de la table de travail');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur lors de "' || vv_proc || '" : ' || gv_step || ' : ' || SQLERRM;
      pn_retcode := 2;
    
  END archivage_factures;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : verif_factures_archivees
  --  Description   : Procedure qui verifie si il n'y a pas eu de modifications sur les factures archivees

  --  PARAMETRES    :
  --                     pv_errbuf     Entree/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE verif_factures_archivees(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    vv_proc             VARCHAR2(50) := 'verif_factures_archivees';
    vd_date_archivage   DATE;
    vn_lignes_modifiees NUMBER := 0;
  
    -- Recuperation des factures archivees ayant tout de meme ete modifiees depuis le dernier passage du traitement
    CURSOR factures_modifiees IS
      SELECT aia.invoice_id
        FROM ap_invoices_all aia
       WHERE 1 = 1
         AND (aia.source IN ('SCAN_XGS') OR (aia.source IN ('REPRISE') AND aia.attribute9 = 'XGS'))
         AND last_update_date > vd_date_archivage
         AND aia.invoice_id IN (SELECT invoice_id FROM dka_iapfacttds_hist);
  
  BEGIN
  
    DKA_TOOLS_PKG.put_debug_message('Verification des factures archivees');
    gv_step := '001 - Select';
  
    -- Recuperation de la date du dernier archivage
    SELECT MAX(DATE_ARCHIVAGE) INTO vd_date_archivage FROM DKA_IAPFACTTDS_HIST;
  
    FOR IC IN factures_modifiees LOOP
    
      gv_step := '002 - Insert (' || IC.invoice_id || ')';
    
      INSERT INTO DKA_IAPFACTTDS_TAB
        (REGION,
         NO_FOURNISSEUR,
         NUM_FACT,
         DATE_FACT,
         STATUT,
         DATE_IMPORT,
         COMMENTAIRE,
         ORIGINE,
         INVOICE_ID,
         REFERENCE_LAD)
        SELECT REGION,
               NO_FOURNISSEUR,
               NUM_FACT,
               DATE_FACT,
               STATUT,
               DATE_IMPORT,
               COMMENTAIRE,
               ORIGINE,
               INVOICE_ID,
               REFERENCE_LAD
          FROM DKA_IAPFACTTDS_HIST
         WHERE INVOICE_ID = IC.INVOICE_ID;
    
      gv_step := '002 - Delete (' || IC.invoice_id || ')';
    
      DELETE FROM DKA_IAPFACTTDS_HIST WHERE INVOICE_ID = IC.INVOICE_ID;
    
      vn_lignes_modifiees := vn_lignes_modifiees + SQL%ROWCOUNT;
    
    END LOOP;
  
    DKA_TOOLS_PKG.put_debug_message(vn_lignes_modifiees || ' lignes remises en table de travail');
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur lors de "' || vv_proc || '" : ' || gv_step || ' : ' || SQLERRM;
    
  END verif_factures_archivees;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : creation_fichier
  --  Description   : Procedure de creation du fichier de sortie

  --  PARAMETRES    :
  --                     pv_errbuf     Entree/Sortie    message d'erreur
  --                     pn_retcode    Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE creation_fichier(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    -- L¿extraction devra sortir les champs suivants (voir mapping du fichier §2.3.3), au format csv avec le separateur « | »
    -- Aucun entete de colonne ne sera ajoute à l¿extraction
    -- fichier de sortie : STATUTSFACTURES_YYYYMMDD.csv
  
    vv_proc VARCHAR2(50) := 'creation_fichier';
  
    Vv_Line       VARCHAR2(1000);
    vv_filename   VARCHAR2(50);
    vv_repertoire varchar2(64) := 'DKA_OUT_DIR';
    vn_nb_lignes  NUMBER;
    Vf_Myfile     Utl_File.File_Type;
  
    CURSOR selectLines IS
      SELECT * FROM DKA_IAPFACTTDS_TAB WHERE FLAG_ENVOI = 1;
  
  BEGIN
  
    gv_step     := '001 - Nom fichier';
    vv_filename := 'STATUTSFACTURES_' || to_char(sysdate, 'YYYYMMDD') || '.csv';
  
    DKA_TOOLS_PKG.put_debug_message('Generation du fichier de sortie : ' || vv_filename);
  
    SELECT count(*) INTO vn_nb_lignes FROM DKA_IAPFACTTDS_TAB WHERE FLAG_ENVOI = 1;
  
    IF vn_nb_lignes = 0 THEN
      pn_retcode := 1; -- VERIF AVERTISSEMENT/ERREUR 1/2
      pv_errbuf  := 'Fichier vide, pas de changements de statuts de facture';
      DKA_TOOLS_PKG.put_debug_message('Fichier vide');
    END IF;
  
    -- Ouverture du fichier
    Vf_Myfile := utl_file.fopen(vv_repertoire, vv_filename, 'W');
  
    FOR IC IN selectLines LOOP
    
      gv_step := '002 - Put_Line(' || IC.invoice_id || ')';
    
      Vv_Line := IC.REGION || '|' || IC.NO_FOURNISSEUR || '|' || REPLACE(REPLACE(IC.NUM_FACT, '|', ' '), chr(10), '') || '|' ||
                 TO_CHAR(IC.DATE_FACT, 'DD/MM/YYYY') || '|' || IC.NV_STATUT || '|' || IC.NV_COMMENTAIRE || '|' ||
                 IC.ORIGINE;
    
      Utl_File.Put_Line(Vf_Myfile, Vv_Line);
      Utl_File.Fflush(Vf_Myfile);
    
      -- Ecriture dans la sortie du traitement
      Fnd_File.put_line(Fnd_File.output, vv_line);
    
    END LOOP;
  
    DKA_TOOLS_PKG.put_debug_message('Fermeture du fichier');
  
    -- Fermeture du fichier de commandes
    gv_step := '003 - Close file';
    Utl_File.Fclose_All;
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf  := 'Erreur lors de "' || vv_proc || '" : ' || gv_step || ' : ' || SQLERRM;
    
  END creation_fichier;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procedure principale du traitement qui enchaînera l'ensemble
  --                  des autres procedures.
  --
  --  PARAMETRES    : pv_errbuf           Entree/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    vv_errbuf  VARCHAR2(300);
    vn_retcode NUMBER;
  
    e_error_main EXCEPTION;
  
  BEGIN
  
    ----- Initialisation des variables -----
    pv_errbuf  := NULL;
    pn_retcode := 0;
    gv_step    := 'DEBUT';
  
    /* Deplacement des nouveaux statuts/commentaires calcules lors du precedent traitement dans les colonnes courantes */
    reinitialisation_statuts(vv_errbuf, vn_retcode);
  
    IF vn_retcode != 0 THEN
    
      DKA_TOOLS_PKG.put_debug_message(vv_errbuf);
      pv_errbuf := 'Probleme au niveau de la reinitialisation des statuts';
      RAISE e_error_main;
    END IF;
  
    /* Archivage des factures totalement reglees ou annulees */
    archivage_factures(vv_errbuf, vn_retcode);
  
    IF vn_retcode != 0 THEN
    
      DKA_TOOLS_PKG.put_debug_message(vv_errbuf);
      pv_errbuf := 'Probleme au niveau de l\archivage';
      RAISE e_error_main;
    END IF;
  
    /* Verification des changements de statuts de factures archivees */
    verif_factures_archivees(vv_errbuf, vn_retcode);
  
    IF vn_retcode != 0 THEN
    
      DKA_TOOLS_PKG.put_debug_message(vv_errbuf);
      pv_errbuf := 'Probleme au niveau de la verification des factures archivees';
      RAISE e_error_main;
    END IF;
  
    /* Prise en compte des nouvelles factures dans la table de travail */
    insert_factures(vv_errbuf, vn_retcode);
  
    IF vn_retcode != 0 THEN
    
      DKA_TOOLS_PKG.put_debug_message(vv_errbuf);
      pv_errbuf := 'Probleme au niveau de l\insertion des nouvelles factures';
      RAISE e_error_main;
    END IF;
  
    /* Mise à jour du statut et du commentaire des factures existantes s'il y a eu du changement depuis le traitement precedent */
    update_factures(vv_errbuf, vn_retcode);
  
    IF vn_retcode != 0 THEN
    
      DKA_TOOLS_PKG.put_debug_message(vv_errbuf);
      pv_errbuf := 'Probleme au niveau de le la mise à jour des factures existantes';
      RAISE e_error_main;
    END IF;
  
    UPDATE DKA_PARAMETERS
       SET DATE_VALUE = SYSDATE
     WHERE PROGRAM_CODE = 'DKA_IAPFACTTDS'
       AND PARAMETER_NAME = 'DATE_DERNIERE_EXTRACTION';

    --COMMIT;

    DKA_TOOLS_PKG.put_debug_message('Les donnees ont ete sauvegardees');
  
    /* Creation du fichier à envoyer */
    creation_fichier(vv_errbuf, vn_retcode);
  
    IF vn_retcode = 1 THEN
      pv_errbuf := 'Le fichier genere est vide';
    
    ELSIF vn_retcode > 1 THEN
      pv_errbuf := 'Probleme lors de la creation du fichier';
      RAISE e_error_main;
    END IF;
  
    pn_retcode := vn_retcode;
    pv_errbuf  := vv_errbuf;
  
  EXCEPTION
  
    WHEN e_error_main THEN
      pn_retcode := vn_retcode;
      pv_errbuf  := vv_errbuf;
      ROLLBACK;
    WHEN OTHERS THEN
      pn_retcode := 2;
    
      pv_errbuf := 'Le traitement s''est termine en erreur (when others) :' || SQLERRM;
      ROLLBACK;
    
  END main;

END DKA_IAPFACTTDS_PKG;
/
SHOW ERRORS
EXIT;
