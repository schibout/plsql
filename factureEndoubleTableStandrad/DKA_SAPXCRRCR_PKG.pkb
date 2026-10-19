create or replace package body DKA_FUSION_AR_PKG is
  ----------------------------------------------------------------------------------------------
  --
  --
  -- NOM               : DKA_FUSION_AR_PKG.pkb
  -- DESCRIPTION       : Fusion des sociétés dans AR
  ---
  --- AUTEUR           : O.CLEMENT (CG)
  --- DATE DE CREATION : 08/2019
  --- DOC. ASSOCIEE    : Spécifications fonctionnelles (SPE094_FINANCES_SFD20190009)
  ---
  ----------------------------------------------------------------------------------------------
  --- NOM DU PROGRAMME :
  --- PARAMETRES       :
  ---
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------------
  --  Constantes globales
  ---------------------------------------------------------------------------------------------------------------
  -- Recherche dans les tables de transco
  cv_transco_fusion_societe    dka_stransco_headers.set_name%type := 'FUSION_SOCIETE_VERS_SOCIETE';
  cv_transco_compte_generique  dka_stransco_headers.set_name%type := 'FUSION_COMPTES_GEN';
  cv_fusion_type_mouvement     dka_stransco_headers.set_name%type := 'FUSION_TYPE_MOUVEMENT';
  cv_transco_gen_appli         dka_stransco_lines.param1_value%type := 'AR';
  cv_transc_cpte_local_client  dka_stransco_lines.param2_value%type := 'COMPTE LOCAL CLIENT';
  cv_transc_cpte_local_douteux dka_stransco_lines.param2_value%type := 'COMPTE LOCAL DOUTEUX';
  cv_transco_cpte_groupe       dka_stransco_lines.param2_value%type := 'COMPTE GROUPE';
  -- Code retour
  cn_ok      NUMBER := 0;
  cn_warning NUMBER := 1;
  cn_error   NUMBER := -2;
  cn_ctrl_ko NUMBER := 3;
  -- Flags
  cv_enable  VARCHAR2(1) := 'Y';
  cv_disable VARCHAR2(1) := 'N';
  -- Status
  cv_ARAA_status_applied   ar_receivable_applications_all.status%type := 'APP'; -- Réglement lettres
  cv_ARAA_status_unapplied ar_receivable_applications_all.status%type := 'UNAPP'; -- Réglement non lettre
  cv_ARAA_status_encom     ar_receivable_applications_all.status%type := 'ACC'; -- Réglement en compte
  cv_ARAA_status_unid      ar_receivable_applications_all.status%type := 'UNID'; -- Réglement non identifié
  cv_AAA_status_applied    ar_adjustments_all.status%type := 'A'; -- Ajustement
  cv_debug                 varchar2(1) := 'Y';
  -- Constantes de la table d'interface
  cn_gl_application_id fnd_application.application_id%type := 101; -- application GL

  -- Type de ligne
  cv_ligne_produit          ra_customer_trx_lines_all.line_type%type := 'REV'; -- Produit
  cv_ligne_taxe             ra_customer_trx_lines_all.line_type%type := 'TAX'; -- Taxe
  cv_ligne_rec              ra_customer_trx_lines_all.line_type%type := 'REC'; -- Rec
  g_user_id                 fnd_user.user_id%TYPE;
  cv_gl_id_flex_code        fnd_id_flex_segments.id_flex_code%type := 'GL#'; -- Clé comptable
  cv_reg_nul                ar_receipt_methods.name%type := '_RGLT_NUL';
  cv_bank_account           ap_bank_accounts_all.bank_account_name%type := '585000';
  cv_interface_line_context ra_interface_lines_all.interface_line_context%type := 'FUSION';
  cv_bank_name              ap_bank_branches.bank_name%type := 'TRESORERIE INTERNE';
  cv_account_type           ap_bank_accounts_all.account_type%type := 'INTERNAL';
  cv_cust_class_code_gr     hz_cust_accounts.customer_class_code%type := 'GROUPE';

  ---------------------------------------------------------------------------------------------------------------
  --  Variables globales
  ---------------------------------------------------------------------------------------------------------------
  vn_set_of_books_id           GL_SETS_OF_BOOKS.SET_OF_BOOKS_ID%TYPE;
  vn_org_id                    NUMBER(15);
  vv_interface_line_attribute5 RA_INTERFACE_LINES_ALL.Interface_Line_Attribute5%type;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : debug
  --  Description   : affichage d'un message d'erreur si l'option est demandée
  --
  --
  --  PARAMETRES    :
  --      pv_debug : mode debug ou pas
  --      pv_message message à  afficher
  ---------------------------------------------------------------------------------------------------------------
  Procedure debug(pv_debug VARCHAR, pv_message VARCHAR2) IS
  BEGIN
    IF pv_debug = cv_debug then
      dka_tools_pkg.put_outdebug_message(pv_message);
    end if;
  end debug;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : message
  --  Description   : affichage d'un message
  --
  --
  --  PARAMETRES    :
  --      pn_codret                   code de retour
  --      pv_message                  message à  afficher
  ---------------------------------------------------------------------------------------------------------------
  Procedure message(pn_codret IN OUT NUMBER, pv_message IN VARCHAR2) IS
  BEGIN
    dka_tools_pkg.put_outdebug_message(pv_message);
  EXCEPTION
    WHEN OTHERS THEN
      pn_codret := cn_error;
  END message;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : squelette_proc
  --  Description   : Squelette de procédure
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure squelette_proc(pn_codret IN OUT NUMBER,
                           pv_errbuf OUT VARCHAR2,
                           pv_debug  IN VARCHAR2) IS
  begin
    debug(pv_debug, 'procédure squelette_proc : début');
    pn_codret := cn_ok;
  
    debug(pv_debug, 'procédure squelette_proc : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure squelette_proc : Fin en erreur');
      debug(pv_debug, 'erreur dans squelette_proc');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end squelette_proc;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : initialisation
  --  Description   : procédure qui initialise toutes les variables globales/constantes et qui purge les tables
  --                d'interfaces et les tables temporaires
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure initialisation(pn_codret   IN OUT NUMBER,
                           pv_errbuf   OUT VARCHAR2,
                           pv_debug    IN VARCHAR2,
                           pb_controle IN BOOLEAN) IS
    vv_date_heure VARCHAR2(25);
    vv_sqlstmt    VARCHAR2(500);
  
  begin
    debug(pv_debug, 'procédure initialisation : début');
    pn_codret := cn_ok;
    -- Innitialisation des variables
    vn_set_of_books_id := FND_PROFILE.VALUE('GL_SET_OF_BKS_id');
    -- Organisation
    vn_org_id := FND_PROFILE.VALUE('ORG_ID');
    g_user_id := fnd_global.user_id;
    -- Historisation des tables temporaires avant la procédure de controle
    IF pb_controle THEN
      vv_date_heure := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');
      -- Historisation de la table DKA_AR_FUSION_REC_CTRL_TEMP
      vv_sqlstmt := 'CREATE TABLE DKA_AR_FUS_REC_' || vv_date_heure ||
                    ' AS SELECT * FROM DKA_AR_FUSION_REC_CTRL_TEMP';
      EXECUTE IMMEDIATE vv_sqlstmt;
      -- Historisation de la table DKA_AR_FUSION_INV_CTRL_TEMP
      vv_sqlstmt := 'CREATE TABLE DKA_AR_FUS_INV_' || vv_date_heure ||
                    ' AS SELECT * FROM DKA_AR_FUSION_INV_CTRL_TEMP';
      EXECUTE IMMEDIATE vv_sqlstmt;
      -- Historisation de la table DKA_AR_FUSION_GCC_TEMP
      vv_sqlstmt := 'CREATE TABLE DKA_AR_FUS_GCC_' || vv_date_heure ||
                    ' AS SELECT * FROM DKA_AR_FUSION_GCC_TEMP';
      EXECUTE IMMEDIATE vv_sqlstmt;
      -- Historisation de la table DKA_AR_FUSION_MVT_LETTRAGE_0
      vv_sqlstmt := 'CREATE TABLE DKA_AR_LETTR_0_' || vv_date_heure ||
                    ' AS SELECT * FROM DKA_AR_FUSION_MVT_LETTRAGE_0';
      EXECUTE IMMEDIATE vv_sqlstmt;
      -- Historisation de la table DKA_AR_FUSION_FFV_TEMP
      vv_sqlstmt := 'CREATE TABLE DKA_AR_FUS_FFV_' || vv_date_heure ||
                    ' AS SELECT * FROM DKA_AR_FUSION_FFV_TEMP';
      EXECUTE IMMEDIATE vv_sqlstmt;
    END IF;
  
    -- init de l'attribute5 :
    SELECT Max(to_char(end_date, 'YYYYMM'))
      INTO vv_interface_line_attribute5
      FROM gl_period_statuses gps, gl_ledgers gll
     WHERE closing_status = 'O'
       AND set_of_books_id = vn_set_of_books_id
       AND application_id = 222
       AND gps.ledger_id = gll.ledger_id
       AND gll.ledger_category_code = 'PRIMARY';
  
    -- purge des tables temporaires uniquement avant la procédure de controle
    IF pb_controle THEN
      delete from dka_ar_fusion_inv_ctrl_temp;
      delete from dka_ar_fusion_rec_ctrl_temp;
      delete from dka_ar_fusion_gcc_temp;
      delete from dka_ar_fusion_mvt_lettrage_0;
      delete from dka_ar_fusion_ffv_temp;
    END IF;
  
    debug(pv_debug, 'procédure initialisation : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure initialisation : Fin en erreur');
      debug(pv_debug,
            'erreur dans la purge des tables temproarires et d''interface');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
      debug(pv_debug, ' Procédure initialisation : Fin en erreur');
  end initialisation;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Site_Clients_Absorbante
  --  Description   : Site_Clients_Absorbante : Mise à  jour dans la table des sites clients pour l'UO ABSORBANTE
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure Site_Clients_Absorbante(pn_codret IN OUT NUMBER,
                                    pv_errbuf OUT VARCHAR2,
                                    pv_debug  IN VARCHAR2) IS
  
    cursor c_mvt is
    
      SELECT distinct dafict.TRX_NUMBER num_mouvement,
                      dafict.customer_trx_id,
                      dafict.BILL_TO_CUSTOMER_ID,
                      dafict.BILL_TO_SITE_USE_ID,
                      csu.ORIG_SYSTEM_REFERENCE,
                      dafict.org_id_absorbante
        FROM DKA_AR_FUSION_INV_CTRL_TEMP dafict,
             hz_cust_site_uses_all       csu,
             ar_customers                ar_cust,
             hz_cust_acct_sites_all      cas,
             hz_cust_accounts            ca
       where cas.cust_account_id = ca.cust_account_id
         AND ar_cust.customer_id = ca.cust_account_id
         AND csu.cust_acct_site_id = cas.cust_acct_site_id
         and ar_cust.CUSTOMER_ID = dafict.BILL_TO_CUSTOMER_ID
         and csu.org_id = dafict.ORG_ID_ABSORBee
         and csu.site_use_id = dafict.BILL_TO_SITE_USE_ID;
  
    cursor c_mvt_ante(p_customer_id           NUMBER,
                      p_orig_system_reference VARCHAR2,
                      p_org_id_absorbante     NUMBER) is
      SELECT distinct csu.CUST_ACCT_SITE_ID
      
        FROM hz_cust_site_uses_all  csu,
             ar_customers           ar_cust,
             hz_cust_acct_sites_all cas,
             hz_cust_accounts       ca
       where cas.cust_account_id = ca.cust_account_id
         AND ar_cust.customer_id = ca.cust_account_id
         AND csu.cust_acct_site_id = cas.cust_acct_site_id
         and ar_cust.CUSTOMER_ID = p_customer_id
         and csu.org_id = p_org_id_absorbante
         and csu.orig_system_reference = p_orig_system_reference;
  
    cursor c_site_controle is
      SELECT distinct dafict.TRX_NUMBER num_mouvement,
                      dafict.customer_trx_id,
                      ar_cust.CUSTOMER_NAME,
                      dafict.BILL_TO_CUSTOMER_ID,
                      dafict.BILL_TO_SITE_USE_ID,
                      csu.ORIG_SYSTEM_REFERENCE,
                      dafict.org_id_absorbante
        FROM DKA_AR_FUSION_INV_CTRL_TEMP dafict,
             hz_cust_site_uses_all       csu,
             ar_customers                ar_cust,
             hz_cust_acct_sites_all      cas,
             hz_cust_accounts            ca
       where cas.cust_account_id = ca.cust_account_id
         AND ar_cust.customer_id = ca.cust_account_id
         AND csu.cust_acct_site_id = cas.cust_acct_site_id
         and ar_cust.CUSTOMER_ID = dafict.BILL_TO_CUSTOMER_ID
         and csu.org_id = dafict.ORG_ID_ABSORBee
         and csu.CUST_ACCT_SITE_ID = dafict.BILL_TO_SITE_USE_ID
         and dafict.new_bill_to_site_use_id is null;
  
    rec_mvt           c_mvt%ROWTYPE;
    rec_mvt_ante      c_mvt_ante%ROWTYPE;
    rec_site_controle c_site_controle%ROWTYPE;
  begin
    debug(pv_debug, 'procédure Site_Clients_Absorbante : début');
    pn_codret := cn_ok;
    OPEN c_mvt;
    LOOP
      FETCH c_mvt
        INTO rec_mvt;
      EXIT WHEN c_mvt%NOTFOUND;
    
      for rec_mvt_ante in c_mvt_ante(rec_mvt.bill_to_customer_id,
                                     rec_mvt.ORIG_SYSTEM_REFERENCE,
                                     rec_mvt.org_id_absorbante) loop
      
        update DKA_AR_FUSION_INV_CTRL_TEMP dafict
           set dafict.new_bill_to_site_use_id = rec_mvt_ante.CUST_ACCT_SITE_ID
         where dafict.CUSTOMER_TRX_ID = rec_mvt.customer_trx_id;
      
      end loop;
    
    end loop;
    Close c_mvt;
  
    OPEN c_site_controle;
    LOOP
      FETCH c_site_controle
        INTO rec_site_controle;
      EXIT WHEN c_site_controle%NOTFOUND;
      pn_codret := cn_ctrl_ko;
      message(pn_codret,
              'Site Client manquant sur la société Absorbante  : ' ||
              rec_site_controle.customer_name || ' pour la référence : ' ||
              rec_site_controle.ORIG_SYSTEM_REFERENCE);
    end loop;
    close c_site_controle;
    debug(pv_debug, 'procédure Site_Clients_Absorbante : fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret,
              'Procédure Site_Clients_Absorbante : Fin en erreur');
      debug(pv_debug, 'erreur dans Site_Clients_Absorbante');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end Site_Clients_Absorbante;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : init_facture
  --  Description   : Recupération de la liste des factures (sans tenir compte des facttures réglées)
  --
  --
  --  PARAMETRES    :
  --      pv_debug  VARCHAR2    Indicateur de debug
  --  VALEUR RETOURNEE :
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE init_facture(pn_codret IN OUT NUMBER,
                         pv_errbuf OUT VARCHAR2,
                         pv_debug  IN VARCHAR2) IS
  BEGIN
    debug(pv_debug, 'Procédure Init_facture : Début');
  
    -- Factures et avoirs
    -- Lister les factures, avoirs et reliquats non comptabilisés avant la date de fusion
    INSERT INTO DKA_AR_FUSION_INV_CTRL_TEMP
      (batch_source_id,
       interface_line_attribute1,
       interface_line_attribute2,
       interface_line_attribute3,
       interface_line_attribute4,
       interface_line_attribute5,
       link_to_line_attribute1,
       link_to_line_attribute2,
       link_to_line_attribute3,
       link_to_line_attribute4,
       link_to_line_attribute5,
       invoice_currency_code,
       customer_trx_amount,
       cust_trx_type_id,
       term_id,
       bill_to_customer_id,
       bill_to_site_use_id,
       trx_date,
       trx_number,
       customer_trx_id,
       customer_trx_line_id,
       link_to_cust_trx_line_id,
       societe_absorbee,
       societe_absorbante,
       line_type,
       description,
       exchange_rate_type,
       exchange_rate,
       cust_trx_type_name,
       vat_tax_id,
       account_class,
       amount,
       percent,
       code_combination_id,
       orig_trx_type,
       collected_tax_ccid)
      SELECT rcta.batch_source_id,
             NVL(rctla.interface_line_attribute1,
                 NVL(rcta.interface_header_attribute1, rbsa.name)) || '_' ||
             To_Char(rcta.trx_date, 'YY'),
             NVL(rctla.interface_line_attribute2,
                 NVL(rcta.interface_header_attribute2, dsl.param1_value)),
             NVL(rctla.interface_line_attribute3,
                 NVL(rcta.interface_header_attribute3, rcta.trx_number)),
             NVL(rctla.interface_line_attribute4,
                 NVL(rcta.interface_header_attribute4, '1')),
             vv_interface_line_attribute5,
             DECODE(rctla.line_type,
                    'TAX',
                    NVL(rctla.interface_line_attribute1,
                        NVL(rcta.interface_header_attribute1, rbsa.name)) || '_' ||
                    To_Char(rcta.trx_date, 'YY'),
                    Null),
             DECODE(rctla.line_type,
                    'TAX',
                    NVL(rctla.interface_line_attribute2,
                        NVL(rcta.interface_header_attribute2,
                            dsl.param1_value)),
                    Null),
             DECODE(rctla.line_type,
                    'TAX',
                    NVL(rctla.interface_line_attribute3,
                        NVL(rcta.interface_header_attribute3, rcta.trx_number)),
                    Null),
             DECODE(rctla.line_type,
                    'TAX',
                    NVL(rctla.interface_line_attribute4,
                        NVL(rcta.interface_header_attribute4, '1')),
                    Null),
             DECODE(rctla.line_type,
                    'TAX',
                    vv_interface_line_attribute5,
                    Null),
             rcta.invoice_currency_code,
             rctla.extended_amount,
             rcta.cust_trx_type_id,
             rcta.term_id,
             rcta.bill_to_customer_id,
             rcta.bill_to_site_use_id,
             dsl.start_date,
             rcta.trx_number,
             rcta.customer_trx_id,
             rctla.customer_trx_line_id,
             rctla.link_to_cust_trx_line_id,
             dsl.param1_value,
             dsl.return_value,
             rctla.line_type,
             NVL(rctla.description,
                 'FUSION SOCIETE : ' || dsl.param1_value || ' par ' ||
                 dsl.return_value),
             nvl(rcta.exchange_rate_type, 'User'),
             nvl(rcta.exchange_rate,
                 decode(NVL(rcta.exchange_rate_type, 'User'),
                        'User',
                        1,
                        NULL)),
             rctta.name,
             rctla.vat_tax_id,
             rctlda.account_class,
             rctlda.amount,
             rctlda.percent,
             rctlda.code_combination_id,
             rctta.type,
             nvl(rctlda.collected_tax_ccid, '')
        FROM ra_cust_trx_line_gl_dist_all rctlda,
             gl_code_combinations         gcc,
             ra_customer_trx_all          rcta,
             ra_batch_sources_all         rbsa,
             ra_customer_trx_lines_all    rctla,
             ra_cust_trx_types_all        rctta,
             dka_stransco_lines           dsl,
             dka_stransco_headers         dsh,
             hr_operating_units           hou
       WHERE dsh.set_name = cv_transco_fusion_societe
         AND dsl.set_id = dsh.set_id
         AND dsl.enable = 'Y'
         AND rctlda.gl_posted_date < dsl.start_date
         and rcta.ORG_ID = rbsa.ORG_ID
         AND arp_bal_util.get_trx_balance(rcta.customer_trx_id, NULL) != '0'
         AND rctlda.code_combination_id = gcc.code_combination_id
         AND gcc.segment1 = substr(dsl.param1_value, 4, 4)
         AND rctlda.customer_trx_id = rcta.customer_trx_id
         AND rcta.batch_source_id = rbsa.batch_source_id
         AND rcta.cust_trx_type_id = rctta.cust_trx_type_id
         AND rctlda.customer_trx_line_id = rctla.customer_trx_line_id(+)
         AND hou.name = dsl.param1_value
         AND rcta.org_id = hou.organization_id;
  
    DECLARE
    
      CURSOR cur_lines IS
        SELECT customer_trx_id,
               interface_line_attribute1,
               interface_line_attribute2,
               interface_line_attribute3,
               interface_line_attribute4,
               interface_line_attribute5,
               link_to_line_attribute1,
               link_to_line_attribute2,
               link_to_line_attribute3,
               link_to_line_attribute4,
               link_to_line_attribute5,
               societe_absorbee,
               societe_absorbante,
               org_id_absorbee,
               org_id_absorbante,
               line_type,
               account_class
          FROM dka_ar_fusion_inv_ctrl_temp
         ORDER BY customer_trx_id,
                  nvl(link_to_cust_trx_line_id,
                      nvl(customer_trx_line_id, 0)),
                  nvl(link_to_cust_trx_line_id, 0)
           FOR UPDATE OF interface_line_attribute4, link_to_line_attribute1, link_to_line_attribute2, link_to_line_attribute3, link_to_line_attribute4, link_to_line_attribute5, org_id_absorbee, org_id_absorbante;
    
      rec_lines cur_lines%ROWTYPE;
    
      old_customer_trx_id          ra_customer_trx_all.customer_trx_id%TYPE := 0;
      old_line_type                ra_interface_lines_all.line_type%TYPE := 'AAAA';
      vn_interface_line_attribute4 NUMBER(15);
      vn_inter_line_attribute1_ht  VARCHAR2(240);
      vn_inter_line_attribute2_ht  VARCHAR2(240);
      vn_inter_line_attribute3_ht  VARCHAR2(240);
      vn_inter_line_attribute4_ht  NUMBER(15);
      vn_inter_line_attribute5_ht  VARCHAR2(240);
      vn_link_to_line_attribute1   VARCHAR2(240);
      vn_link_to_line_attribute2   VARCHAR2(240);
      vn_link_to_line_attribute3   VARCHAR2(240);
      vn_link_to_line_attribute4   NUMBER(15);
      vn_link_to_line_attribute5   VARCHAR2(240);
      vn_org_id_absorbee           NUMBER(15);
      vn_org_id_absorbante         NUMBER(15);
      vb_new_customer_trx          BOOLEAN;
    
    BEGIN
    
      OPEN cur_lines;
      LOOP
        FETCH cur_lines
          INTO rec_lines;
        EXIT WHEN cur_lines%NOTFOUND;
        IF rec_lines.customer_trx_id != old_customer_trx_id THEN
          vn_interface_line_attribute4 := 1;
          vb_new_customer_trx          := TRUE;
        ELSE
          IF vb_new_customer_trx THEN
            vn_interface_line_attribute4 := 1;
            vb_new_customer_trx          := FALSE;
          ELSE
            vn_interface_line_attribute4 := vn_interface_line_attribute4 + 1;
          END IF;
        END IF;
      
        IF rec_lines.line_type = 'LINE' THEN
          vn_inter_line_attribute1_ht := rec_lines.interface_line_attribute1;
          vn_inter_line_attribute2_ht := rec_lines.interface_line_attribute2;
          vn_inter_line_attribute3_ht := rec_lines.interface_line_attribute3;
          vn_inter_line_attribute4_ht := vn_interface_line_attribute4;
          vn_inter_line_attribute5_ht := rec_lines.interface_line_attribute5;
          vn_link_to_line_attribute1  := NULL;
          vn_link_to_line_attribute2  := NULL;
          vn_link_to_line_attribute3  := NULL;
          vn_link_to_line_attribute4  := NULL;
          vn_link_to_line_attribute5  := NULL;
        ELSIF rec_lines.line_type = 'TAX' THEN
          vn_link_to_line_attribute1  := vn_inter_line_attribute1_ht;
          vn_link_to_line_attribute2  := vn_inter_line_attribute2_ht;
          vn_link_to_line_attribute3  := vn_inter_line_attribute3_ht;
          vn_link_to_line_attribute4  := vn_inter_line_attribute4_ht;
          vn_link_to_line_attribute5  := vn_inter_line_attribute5_ht;
          vn_inter_line_attribute1_ht := NULL;
          vn_inter_line_attribute2_ht := NULL;
          vn_inter_line_attribute3_ht := NULL;
          vn_inter_line_attribute4_ht := NULL;
          vn_inter_line_attribute5_ht := NULL;
        ELSE
          vn_inter_line_attribute1_ht := NULL;
          vn_inter_line_attribute2_ht := NULL;
          vn_inter_line_attribute3_ht := NULL;
          vn_inter_line_attribute4_ht := NULL;
          vn_inter_line_attribute5_ht := NULL;
          vn_link_to_line_attribute1  := NULL;
          vn_link_to_line_attribute2  := NULL;
          vn_link_to_line_attribute3  := NULL;
          vn_link_to_line_attribute4  := NULL;
          vn_link_to_line_attribute5  := NULL;
        END IF;
        --          Récupération de l'org id de l'UO absorbée
        SELECT organization_id
          INTO vn_org_id_absorbee
          FROM hr_operating_units
         WHERE name = rec_lines.societe_absorbee;
        --          Récupération de l'org id de l'UO absorbante
        SELECT organization_id
          INTO vn_org_id_absorbante
          FROM hr_operating_units
         WHERE name = rec_lines.societe_absorbante;
      
        UPDATE dka_ar_fusion_inv_ctrl_temp
           SET interface_line_attribute4 = vn_interface_line_attribute4,
               link_to_line_attribute1   = vn_link_to_line_attribute1,
               link_to_line_attribute2   = vn_link_to_line_attribute2,
               link_to_line_attribute3   = vn_link_to_line_attribute3,
               link_to_line_attribute4   = vn_link_to_line_attribute4,
               link_to_line_attribute5   = vn_link_to_line_attribute5,
               org_id_absorbee           = vn_org_id_absorbee,
               org_id_absorbante         = vn_org_id_absorbante
         WHERE CURRENT OF cur_lines;
      
        old_customer_trx_id := rec_lines.customer_trx_id;
        old_line_type       := rec_lines.line_type;
      END LOOP;
      CLOSE cur_lines;
    
    END;
  
    debug(pv_debug, 'Procédure init_facture : Fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure init_facture : Fin en erreur');
      debug(pv_debug,
            'erreur dans récupération des numéros de factures/avoirs');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
      debug(pv_debug, ' Procédure init_facture : Fin en erreur');
  END init_facture;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : get_montant_reglement
  --  Description   : Recupération des montants des réglements
  --
  --
  --  PARAMETRES    :
  --      pv_debug               Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE get_montant_reglement(pn_codret IN OUT NUMBER,
                                  pv_errbuf OUT VARCHAR2,
                                  pv_debug  IN VARCHAR2) IS
  BEGIN
    debug(pv_debug, 'Procédure get_montant_reglement : Début');
  
    -- calcul des montant des réglements de chaque facture
    Update DKA_AR_FUSION_INV_CTRL_TEMP dafct
       set (dafct.receivable_amount_line, dafct.receivable_amount_tax) =
           (select sum(line_applied), sum(tax_applied)
              from ar_receivable_applications_all araa
             where araa.applied_customer_trx_id = dafct.customer_trx_id
               and araa.status = cv_ARAA_status_applied);
  
    debug(pv_debug, 'Procédure get_montant_reglement : Fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure get_montant_reglement : Fin en erreur');
      debug(pv_debug,
            'erreur dans récupération des montants des réglements des factures/avoirs');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
      debug(pv_debug, ' Procédure get_montant_reglement : Fin en erreur');
  END get_montant_reglement;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : get_montant_ajustement
  --  Description   : Recupération des montants des ajustements
  --
  --
  --  PARAMETRES    :
  --      pv_debug               Indicateur de debug
  --  VALEUR RETOURNEE :
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE get_montant_ajustement(pn_codret IN OUT NUMBER,
                                   pv_errbuf OUT VARCHAR2,
                                   pv_debug  IN VARCHAR2) IS
  BEGIN
    debug(pv_debug, 'Procédure get_montant_ajustement : Début');
  
    --  Récupération du montant des ajustements liés à  chaque facture
    Update DKA_AR_FUSION_INV_CTRL_TEMP dafct
       set (dafct.adjustment_amount) =
           (select sum(amount)
              from ar_adjustments_all aaa
             where aaa.customer_trx_id = dafct.customer_trx_id
               and aaa.status = cv_AAA_status_applied);
  
    debug(pv_debug, 'Procédure get_montant_ajustement : Fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret,
              'Procédure get_montant_ajustement : Fin en erreur');
      debug(pv_debug,
            'erreur dans récupération des montants des ajustements des réglements des factures/avoirs');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
      debug(pv_debug, ' Procédure get_montant_ajustement : Fin en erreur');
  END get_montant_ajustement;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : liste_reglement
  --  Description   : Recupération de la liste des réglements
  --
  --
  --  PARAMETRES    :
  --      pv_debug               Indicateur de debug
  --  VALEUR RETOURNEE :
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE liste_reglement(pn_codret IN OUT NUMBER,
                            pv_errbuf OUT VARCHAR2,
                            pv_debug  IN VARCHAR2) IS
  BEGIN
    debug(pv_debug, 'Procédure liste_reglement : Début');
  
    INSERT INTO DKA_AR_FUSION_REC_CTRL_TEMP
      (amount_applied,
       cash_receipt_id,
       amount,
       Receipt_number,
       receipt_date,
       Status,
       Set_of_books_id,
       Currency_code,
       Customer_site_use_id,
       Deposit_date,
       Pay_from_customer,
       Receipt_method_id,
       org_id,
       societe_absorbee,
       societe_absorbante,
       org_id_absorbee,
       org_id_absorbante,
       trx_number,
       customer_trx_id,
       cancelable,
       reversal_date)
      select sum(araa.amount_applied),
             acra.cash_receipt_id,
             acra.amount,
             acra.Receipt_number,
             acra.Receipt_date,
             acra.Status,
             acra.Set_of_books_id,
             acra.Currency_code,
             acra.Customer_site_use_id,
             acra.Deposit_date,
             acra.Pay_from_customer,
             acra.Receipt_method_id,
             acra.org_id,
             dsl.param1_value,
             dsl.return_value,
             hou1.organization_id,
             hou2.organization_id,
             NULL -- Pas de lettrage
            ,
             NULL,
             'O',
             dsl.start_date
        from ar_receivable_applications_all araa,
             ar_cash_receipts_all           acra,
             ar_receipt_methods             arm,
             dka_stransco_lines             dsl,
             dka_stransco_headers           dsh,
             hr_operating_units             hou1,
             hr_operating_units             hou2
       where dsh.set_name = cv_transco_fusion_societe
         and dsl.set_id = dsh.set_id
         and dsl.enable = cv_enable
         and arm.receipt_method_id = acra.receipt_method_id
         and substr(arm.name, 1, 4) = substr(dsl.param1_value, 4, 4)
         and araa.cash_receipt_id = acra.cash_receipt_id
         and araa.gl_posted_date < dsl.start_date
         and araa.status in (cv_ARAA_status_encom,
                             cv_ARAA_status_unapplied,
                             cv_ARAA_status_unid)
         and hou1.name = dsl.param1_value
         and hou2.name = dsl.return_value
         and hou1.organization_id = acra.org_id
       group by acra.cash_receipt_id,
                acra.amount,
                acra.Receipt_number,
                acra.Receipt_date,
                acra.Status,
                acra.Set_of_books_id,
                acra.Currency_code,
                acra.Customer_site_use_id,
                acra.Deposit_date,
                acra.Pay_from_customer,
                acra.Receipt_method_id,
                acra.org_id,
                dsl.param1_value,
                dsl.return_value,
                hou1.organization_id,
                hou2.organization_id,
                NULL,
                NULL,
                'N',
                dsl.start_date
      having sum(araa.amount_applied) <> 0
      UNION
      -- Par défaut et pour raison d'optimisation on considère dans un premier temps
      -- que tous les réglements lettrés ne sont pas annulables.
      select sum(araa.amount_applied),
             acra.cash_receipt_id,
             acra.amount,
             acra.Receipt_number,
             acra.Receipt_date,
             acra.Status,
             acra.Set_of_books_id,
             acra.Currency_code,
             acra.Customer_site_use_id,
             acra.Deposit_date,
             acra.Pay_from_customer,
             acra.Receipt_method_id,
             acra.org_id,
             dafict.societe_absorbee,
             dafict.societe_absorbante,
             dafict.org_id_absorbee,
             dafict.org_id_absorbante,
             dafict.trx_number,
             dafict.customer_trx_id,
             'N' -- Non annulable
            ,
             dsl.start_date
        from ar_receivable_applications_all araa,
             ar_cash_receipts_all acra,
             ar_receipt_methods arm,
             (select distinct customer_trx_id,
                              trx_number,
                              societe_absorbee,
                              societe_absorbante,
                              org_id_absorbee,
                              org_id_absorbante
                from DKA_AR_FUSION_INV_CTRL_TEMP) dafict,
             dka_stransco_lines dsl,
             dka_stransco_headers dsh
       where dafict.customer_trx_id = araa.applied_customer_trx_id
         and arm.receipt_method_id = acra.receipt_method_id
         and araa.cash_receipt_id = acra.cash_receipt_id
         and araa.status not in (cv_ARAA_status_encom,
                                 cv_ARAA_status_unapplied,
                                 cv_ARAA_status_unid)
         and dsl.return_value = dafict.societe_absorbante
         and dsl.PARAM1_VALUE = dafict.societe_absorbee
         and dsh.set_name = cv_transco_fusion_societe
         and dsl.set_id = dsh.set_id
         and dsl.enable = cv_enable
         and araa.gl_posted_date < dsl.start_date
       group by acra.cash_receipt_id,
                acra.amount,
                acra.Receipt_number,
                acra.Receipt_date,
                acra.Status,
                acra.Set_of_books_id,
                acra.Currency_code,
                acra.Customer_site_use_id,
                acra.Deposit_date,
                acra.Pay_from_customer,
                acra.Receipt_method_id,
                acra.org_id,
                dafict.societe_absorbee,
                dafict.societe_absorbante,
                dafict.org_id_absorbee,
                dafict.org_id_absorbante,
                dafict.trx_number,
                dafict.customer_trx_id,
                'N' -- Non annulable
               ,
                dsl.start_date
      having sum(araa.amount_applied) <> 0;
  
    DECLARE
      CURSOR cur_reglement IS
        SELECT reg.cash_receipt_id, reg.amount, reg1.amount_applied
          FROM (SELECT DISTINCT cash_receipt_id, amount
                  FROM dka_ar_fusion_rec_ctrl_temp dafrct) reg,
               (SELECT cash_receipt_id,
                       status,
                       SUM(amount_applied) amount_applied
                  FROM dka_ar_fusion_rec_ctrl_temp dafrct
                 GROUP BY cash_receipt_id, status) reg1
         WHERE reg.cash_receipt_id = reg1.cash_receipt_id
           and reg1.status <> 'APP'
           AND reg1.amount_applied >= 0
           AND (reg.amount - reg1.amount_applied) >= 0;
    
      rec_reglement cur_reglement%ROWTYPE;
    
    BEGIN
      OPEN cur_reglement;
      LOOP
        FETCH cur_reglement
          INTO rec_reglement;
        EXIT WHEN cur_reglement%NOTFOUND;
      
        update dka_ar_fusion_rec_ctrl_temp
           set cancelable = 'O'
         where cash_receipt_id = rec_reglement.cash_receipt_id;
      
      END LOOP;
      CLOSE cur_reglement;
    
    END;
    DECLARE
      CURSOR cur_reglement2 IS
        SELECT cash_receipt_id, receipt_method_id, org_id_absorbee
          FROM dka_ar_fusion_rec_ctrl_temp;
    
      rec_reglement2           cur_reglement2%ROWTYPE;
      v_REMIT_BANK_ACCT_USE_ID ar_receipt_method_accounts_all.REMIT_BANK_ACCT_USE_ID%type;
    
    BEGIN
      OPEN cur_reglement2;
      LOOP
        FETCH cur_reglement2
          INTO rec_reglement2;
        EXIT WHEN cur_reglement2%NOTFOUND;
      
        select REMIT_BANK_ACCT_USE_ID
          into v_REMIT_BANK_ACCT_USE_ID
          from ar_receipt_method_accounts_all
         where receipt_method_id = rec_reglement2.receipt_method_id
           and org_id = rec_reglement2.org_id_absorbee;
      
        update dka_ar_fusion_rec_ctrl_temp
           set Remittance_bank_account_id = v_REMIT_BANK_ACCT_USE_ID
         where cash_receipt_id = rec_reglement2.cash_receipt_id;
      
      END LOOP;
      CLOSE cur_reglement2;
    
    END;
  
    DECLARE
      CURSOR cur_date_gl IS
        SELECT distinct reversal_date FROM dka_ar_fusion_rec_ctrl_temp;
    
      rec_date_gl       cur_date_gl%ROWTYPE;
      vv_period_name    VARCHAR2(10);
      vv_closing_status VARCHAR2(5);
      vv_date_gl        VARCHAR2(12);
      v_errbuf          VARCHAR2(2500);
    BEGIN
      OPEN cur_date_gl;
      LOOP
        FETCH cur_date_gl
          INTO rec_date_gl;
        EXIT WHEN cur_date_gl%NOTFOUND;
      
        SELECT DISTINCT PERIOD_NAME, closing_status
          INTO vv_period_name, vv_closing_status
          FROM gl_period_statuses gps, gl_ledgers gll
         WHERE gps.application_id = 222
              -- AND closing_status = 'O'
           and rec_date_gl.reversal_date between gps.START_DATE and
               gps.end_date
           AND gps.ledger_id = gll.ledger_id
           AND gll.ledger_category_code = 'PRIMARY';
      
        IF vv_closing_status <> 'O' THEN
          SELECT DISTINCT max(gps.START_DATE)
            INTO vv_date_gl
            FROM gl_period_statuses gps, gl_ledgers gll
           WHERE gps.application_id = 222
             AND closing_status = 'O'
             AND gps.ledger_id = gll.ledger_id
             AND gll.ledger_category_code = 'PRIMARY';
        
          update dka_ar_fusion_rec_ctrl_temp
             set reversal_date = to_date(vv_date_gl, 'DD/MM/YY');
        END IF;
      
      END LOOP;
      CLOSE cur_date_gl;
    
   
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errbuf := SQLERRM;
        message(pn_codret, 'ERROR : ' || v_errbuf);
        message(pn_codret,
                'Aucune période AR trouvé pour la date de fusion : La date GL sera la date de début de la première période ouverte');
	
        SELECT DISTINCT max(gps.START_DATE)
          INTO vv_date_gl
          FROM gl_period_statuses gps, gl_ledgers gll
         WHERE gps.application_id = 222
           AND closing_status = 'O'
           AND gps.ledger_id = gll.ledger_id
           AND gll.ledger_category_code = 'PRIMARY';
      
	   
      WHEN TOO_MANY_ROWS THEN
        pv_errbuf := SQLERRM;
        message(pn_codret, 'ERROR : ' || v_errbuf);
        message(pn_codret,
                'Plusieurs périodes AR ouverte : La date GL sera la date de début de la première période ouverte');
	 
        SELECT DISTINCT max(gps.START_DATE)
          INTO vv_date_gl
          FROM gl_period_statuses gps, gl_ledgers gll
         WHERE gps.application_id = 222
           AND closing_status = 'O'
           AND gps.ledger_id = gll.ledger_id
           AND gll.ledger_category_code = 'PRIMARY';
    END;
      -- Vérification Statut Règlement : positionner le flag CANCELABLE à "N" si règlement déjà annulé
      update dka_ar_fusion_rec_ctrl_temp dafrct
         set dafrct.CANCELABLE = 'N'
       where dafrct.STATUS = 'REV';
    debug(pv_debug, 'Procédure liste_reglement : Fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure liste_reglement : Fin en erreur');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
      debug(pv_debug, ' Procédure liste_reglement : Fin en erreur');
  END liste_reglement;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : liste_facture
  --  Description   : Recupération de la liste des factures
  --
  --
  --  PARAMETRES    :
  --      pv_debug               Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE liste_facture(pn_codret IN OUT NUMBER,
                          pv_errbuf OUT VARCHAR2,
                          pv_debug  IN VARCHAR2) IS
  BEGIN
    debug(pv_debug, 'Procédure Liste_facture : Début');
    init_facture(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret <> cn_ok THEN
      debug(pv_debug, 'Procédure liste_facture : Fin en erreur');
      RETURN;
    END IF;
    -----------------------------------------------------------
    get_montant_reglement(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret <> cn_ok THEN
      debug(pv_debug, 'Procédure liste_facture : Fin en erreur');
      RETURN;
    END IF;
    -----------------------------------------------------------
    get_montant_ajustement(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret <> cn_ok THEN
      debug(pv_debug, 'Procédure liste_facture : Fin en erreur');
      RETURN;
    END IF;
  
    debug(pv_debug, 'Procédure liste_facture : Fin');
  END liste_facture;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : extraction
  --  Description   : Recupération de la liste des factures et réglements à  extraire
  --
  --
  --  PARAMETRES    :
  --      pv_debug               Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE extraction(pn_codret IN OUT NUMBER,
                       pv_errbuf OUT VARCHAR2,
                       pv_debug  IN VARCHAR2) IS
  BEGIN
    debug(pv_debug, 'Procédure extraction : Début');
    -- Extraction des mouvements non comptabilisés du périmètre
    liste_facture(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret <> cn_ok THEN
      debug(pv_debug, 'Procédure extraction : Fin en erreur');
      RETURN;
    END IF;
    -------------------------------------------------------------
    -- Extraction des règlements faisant partie du périmètre
    liste_reglement(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret <> cn_ok THEN
      debug(pv_debug, 'Procédure extraction : Fin en erreur');
      RETURN;
    END IF;
    COMMIT;
    debug(pv_debug, 'Procédure extraction : Fin');
  END extraction;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : existence_banque
  --  Description   : procédure qui contole l'existence des banques dans la société absorbante
  --                  à  partir des codes UO des sociétés fournies en paramètres du traitement
  --
  --  PARAMETRES    :
  --      pv_debug  IN VARCHAR2(1)    Indicateur de debug
  --  VALEUR RETOURNEE :
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  ---------------------------------------------------------------------------------------------------------------
  Procedure existence_banque(pn_codret IN OUT NUMBER,
                             pv_errbuf OUT VARCHAR2,
                             pv_debug  IN VARCHAR2) IS
    cursor c_bank is
      SELECT distinct cbb.bank_name || '-' || cbb.bank_branch_name || '-' ||
                      substr(dsl.return_value, 4, 4) ||
                      substr(cba.bank_account_name,
                             5,
                             length(cba.bank_account_name)) bank_account_num
        FROM CE_BANK_ACCOUNTS     cba,
             ce_bank_branches_v   cbb,
             dka_stransco_lines   dsl,
             dka_stransco_headers dsh
       WHERE cba.bank_branch_id = cbb.branch_party_id
         AND dsh.set_name = cv_transco_fusion_societe
         and dsl.set_id = dsh.set_id
         and dsl.enable = cv_enable
         AND substr(cba.bank_account_name, 1, 4) =
             substr(dsl.PARAM1_VALUE, 4, 4)
         AND substr(cba.bank_account_name, 6, 3) =
             substr(dsl.PARAM1_VALUE, 1, 3)
         AND not exists (SELECT null
                FROM ce_bank_accounts cba1
               WHERE substr(cba1.bank_account_name, 1, 4) =
                     substr(dsl.return_VALUE, 4, 4)
                 AND substr(cba1.bank_account_name, 6, 3) =
                     substr(dsl.return_VALUE, 1, 3));
  
    rec_bank   c_bank%rowtype;
    nb_erreurs NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure existence_banque : début');
    pn_codret := cn_ok;
    pv_errbuf := 'Controle existence banque';
    message(pn_codret, pv_errbuf);
    -- Parcours des banques pour controler l'existence des banques
    for rec_bank in c_bank loop
      pn_codret  := cn_ctrl_ko;
      nb_erreurs := nb_erreurs + 1;
      pv_errbuf  := 'Code banque inexistant : ' ||
                    rec_bank.bank_account_num;
      message(pn_codret, pv_errbuf);
    end loop;
  
    IF pn_codret = cn_ctrl_ko THEN
      debug(pv_debug, 'Des banques manquent dans la société absorbante.');
    END IF;
    debug(pv_debug, 'procédure existence_banque : fin');
    message(pn_codret, 'Fin controle existence banque');
    message(pn_codret, 'Nombre d''éléments en erreur : ' || nb_erreurs);
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure existence_banque : Fin en erreur');
      debug(pv_debug,
            'Erreur dans récupération des banques de la société absorbante');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end existence_banque;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : mode_reglement
  --  Description   : procédure qui controle l'existence des mode de réglement dans la société absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug  IN VARCHAR2(1)    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure mode_reglement(pn_codret IN OUT NUMBER,
                           pv_errbuf OUT VARCHAR2,
                           pv_debug  IN VARCHAR2) IS
  
    CURSOR cur_rma IS
      SELECT DISTINCT dafrct.societe_absorbante         soc_absorbante,
                      armaa.remit_bank_acct_use_id      compte,
                      dafrct.remittance_bank_account_id,
                      arm_new.receipt_method_id         new_receipt_method_id,
                      armaa.receipt_method_id,
                      arm_old.name,
                      arm_new.name                      nom_methode,
                      cba.bank_account_name             old_name,
                      cba_new.bank_account_name         new_name,
                      armaa_new.REMIT_BANK_ACCT_USE_ID
        FROM ar_receipt_method_accounts_all armaa,
             ar_receipt_method_accounts_all armaa_new,
             ar_receipt_methods             arm_new,
             ar_receipt_methods             arm_old,
             ce_bank_accounts               cba,
             ce_bank_acct_uses_all          cbau,
             ce_bank_accounts               cba_new,
             ce_bank_acct_uses_all          cbau_new,
             dka_ar_fusion_rec_ctrl_temp    dafrct
       WHERE armaa.receipt_method_id = dafrct.receipt_method_id
         AND armaa.remit_bank_acct_use_id =
             dafrct.remittance_bank_account_id
         AND arm_old.receipt_method_id = dafrct.receipt_method_id
         and cbau.BANK_ACCT_USE_ID = armaa.REMIT_BANK_ACCT_USE_ID
         and cbau.BANK_ACCOUNT_ID = cba.BANK_ACCOUNT_ID
         AND arm_new.NAME = substr(dafrct.societe_absorbante, 4, 4) ||
             substr(arm_old.NAME, 5, length(arm_old.name))
         and armaa_new.RECEIPT_METHOD_ID = arm_new.RECEIPT_METHOD_ID
         and cbau_new.BANK_ACCT_USE_ID = armaa_new.REMIT_BANK_ACCT_USE_ID
         and armaa_new.org_id = dafrct.ORG_ID_ABSORBANTE
         and cbau_new.BANK_ACCOUNT_ID = cba_new.BANK_ACCOUNT_ID
         and cba_new.BANK_ACCOUNT_NAME <>
             substr(dafrct.societe_absorbante, 4, 4) ||
             substr(cba.BANK_ACCOUNT_NAME, 5, length(cba.bank_account_name));
  
    -- Curseur sur les modes de règlement existant pour l'UO absorbée mais n'existant pas sur l'UO absorbante
    CURSOR cur_receipt_methods IS
      SELECT DISTINCT dafrct.societe_absorbante soc_absorbante,
                      substr(dafrct.societe_absorbante, 4, 4) ||
                      substr(arm.NAME, 5, length(arm.NAME)) new_name,
                      arm.NAME
        FROM ar_receipt_methods arm, dka_ar_fusion_rec_ctrl_temp dafrct
       WHERE arm.receipt_method_id = dafrct.receipt_method_id
         AND NOT EXISTS
       (SELECT NULL
                FROM ar_receipt_methods arm1
               WHERE arm1.NAME = substr(dafrct.societe_absorbante, 4, 4) ||
                     substr(arm.NAME, 5, length(arm.NAME)));
  
    CURSOR cur_receipt_acc IS
      select distinct dafrct.societe_absorbante
        from ar_receipt_methods arm, dka_ar_fusion_rec_ctrl_temp dafrct
       where arm.receipt_method_id = dafrct.receipt_method_id;
  
    rec_receipt_methods cur_receipt_methods%ROWTYPE;
    rec_receipt_acc     cur_receipt_acc%ROWTYPE;
    rec_rma             cur_rma%ROWTYPE;
    nb_erreurs          NUMBER(15) := 0;
    vn_receipt_method   NUmber(15) := 0;
  begin
    debug(pv_debug, 'procédure mode_reglement : début');
    pn_codret := cn_ok;
    message(pn_codret, 'Controle modes de règlement');
    -- Parcours des modes de réglement
    OPEN cur_receipt_methods;
    LOOP
      FETCH cur_receipt_methods
        INTO rec_receipt_methods;
      EXIT WHEN cur_receipt_methods%NOTFOUND;
      pn_codret  := cn_ctrl_ko;
      nb_erreurs := nb_erreurs + 1;
      pv_errbuf  := 'Mode de règlement inexistant : ' ||
                    rec_receipt_methods.new_name;
      message(pn_codret, pv_errbuf);
    
    END LOOP;
    CLOSE cur_receipt_methods;
    message(pn_codret,
            'Nombre de modes de règlement manquants : ' || nb_erreurs);
    nb_erreurs := 0;
    -- curseur sur les modes de paiement existant pour l'UO absorbée mais
    -- avec le compte de remise n'existe pas sur ce mode de paiement
    OPEN cur_rma;
    LOOP
      FETCH cur_rma
        INTO rec_rma;
      EXIT WHEN cur_rma%NOTFOUND;
      pn_codret  := cn_ctrl_ko;
      nb_erreurs := nb_erreurs + 1;
      pv_errbuf  := 'Compte de remise inexistant : ' || rec_rma.old_name;
      message(pn_codret, pv_errbuf);
      pv_errbuf := 'Pour le mode de règlement : ' || rec_rma.nom_methode;
      message(pn_codret, pv_errbuf);
    
    END LOOP;
    CLOSE cur_rma;
    -- récupération des nouveaux receipt_method_id dans la table temporaire
    update dka_ar_fusion_rec_ctrl_temp dafrct
       set new_receipt_method_id =
           (select arm.receipt_method_id
              from ar_receipt_methods arm, ar_receipt_methods arm1
             where arm.name = substr(dafrct.societe_absorbante, 4, 4) ||
                   substr(arm1.NAME, 5, length(arm1.NAME))
               and dafrct.receipt_method_id = arm1.receipt_method_id);
  
    OPEN cur_receipt_acc;
    LOOP
      FETCH cur_receipt_acc
        INTO rec_receipt_acc;
      EXIT WHEN cur_receipt_acc%NOTFOUND;
      Begin
        select arm.RECEIPT_METHOD_ID
          into vn_receipt_method
          from ar_receipt_methods arm
         where arm.name = substr(rec_receipt_acc.societe_absorbante, 4, 4) || '_' ||
               substr(rec_receipt_acc.societe_absorbante, 1, 3) ||
               '_FUSION';
      
        /*  update dka_ar_fusion_rec_ctrl_temp dafrct
          set new_receipt_method_id =
              (select arm.receipt_method_id
                 from ar_receipt_methods arm
                where arm.name =
                      substr(dafrct.societe_absorbante, 4, 4) ||
                      substr(dafrct.societe_absorbante, 1, 3) || '_FUSION')
        where dafrct.STATUS = 'ACC'
          and dafrct.SOCIETE_ABSORBANTE =
              rec_receipt_acc.societe_absorbante;*/
      EXCEPTION
        WHEN no_data_found THEN
          message(pn_codret,
                  'Mode de règlement En compte non paramétré : ' ||
                  substr(rec_receipt_acc.societe_absorbante, 4, 4) || '_' ||
                  substr(rec_receipt_acc.societe_absorbante, 1, 3) ||
                  '_FUSION');
          pn_codret := cn_ctrl_ko;
      end;
    END LOOP;
    CLOSE cur_receipt_acc;
    message(pn_codret,
            'Nombre de comptes de remise manquants : ' || nb_erreurs);
    message(pn_codret, 'Fin controle modes de règlement');
    debug(pv_debug, 'procédure mode_reglement : fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure mode_reglement : Fin en erreur');
      debug(pv_debug,
            'erreur dans récupération des mode de réglement de la société absorbante');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end mode_reglement;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : categories
  --  Description   : procédure qui controle l'existence des catégories dans la société absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug  IN VARCHAR2(1)    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure categories(pn_codret IN OUT NUMBER,
                       pv_errbuf OUT VARCHAR2,
                       pv_debug  IN VARCHAR2) IS
  
    CURSOR cur_categories IS
      SELECT DISTINCT dafrct.societe_absorbante soc_absorbante,
                      substr(dafrct.societe_absorbante, 4, 4) ||
                      substr(arm.NAME, 5, length(arm.NAME)) new_name
        FROM ar_receipt_methods arm, dka_ar_fusion_rec_ctrl_temp dafrct
       WHERE arm.receipt_method_id = dafrct.receipt_method_id
         AND NOT EXISTS
       (SELECT 'X'
                FROM fnd_doc_sequence_categories fdsc, fnd_application fa
               WHERE fa.application_short_name = 'AR'
                 AND fdsc.application_id = fa.application_id
                 AND fdsc.name = substr(dafrct.societe_absorbante, 4, 4) ||
                     substr(arm.name, 5, length(arm.NAME)));
  
    rec_categories cur_categories%ROWTYPE;
    nb_erreurs     NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure categories : début');
    pn_codret := cn_ok;
    message(pn_codret, 'Controle catégories');
    -- Parcours des categories
    OPEN cur_categories;
    LOOP
      FETCH cur_categories
        INTO rec_categories;
      EXIT WHEN cur_categories%NOTFOUND;
      pn_codret  := cn_ctrl_ko;
      nb_erreurs := nb_erreurs + 1;
      pv_errbuf  := 'Code catégorie inexistant : ' ||
                    rec_categories.new_name;
      message(pn_codret, pv_errbuf);
    
    END LOOP;
    CLOSE cur_categories;
    IF pn_codret = cn_ctrl_ko THEN
      debug(pv_debug,
            'Des catégories manquent dans la société absorbante.');
    END IF;
    message(pn_codret, 'Nombre de catégories manquantes : ' || nb_erreurs);
    message(pn_codret, 'Fin controle catégories');
    debug(pv_debug, 'procédure categories : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure categories : Fin en erreur');
      debug(pv_debug,
            'erreur dans récupération des categories de la société absorbante');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end categories;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : sequences
  --  Description   : procédure qui controle l'existence des séquences dans la société absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug  IN VARCHAR2(1)    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure sequences(pn_codret IN OUT NUMBER,
                      pv_errbuf OUT VARCHAR2,
                      pv_debug  IN VARCHAR2) IS
  
    CURSOR cur_sequences IS
      SELECT DISTINCT dafrct.societe_absorbante soc_absorbante,
                      substr(dafrct.societe_absorbante, 4, 4) ||
                      substr(arm.NAME, 5, length(arm.NAME)) new_name
        FROM ar_receipt_methods arm, dka_ar_fusion_rec_ctrl_temp dafrct
       WHERE arm.receipt_method_id = dafrct.receipt_method_id
         AND NOT EXISTS (SELECT 'X'
                FROM fnd_doc_sequence_assignments fdsa
               WHERE fdsa.category_code =
                     substr(dafrct.societe_absorbante, 4, 4) ||
                     substr(arm.name, 5, length(arm.NAME))
                 AND fdsa.method_code is null); -- MTIA a voir
  
    --Curseur des factures dont la catégorie n'est pas affectée à  une séquence en automatique
    CURSOR cur_seq_fact IS
      SELECT DISTINCT dafrct.cust_trx_type_name new_name,
                      rcta.set_of_books_id,
                      dafrct.trx_date,
                      dafrct.cust_trx_type_name
        FROM dka_ar_fusion_inv_ctrl_temp dafrct, ra_customer_trx_all rcta
       WHERE rcta.customer_trx_id = dafrct.customer_trx_id
         AND NOT EXISTS
       (SELECT 1
                FROM fnd_doc_sequence_assignments fdsa
               WHERE Fdsa.Application_Id = 222
                 AND Fdsa.Set_Of_Books_Id = rcta.set_of_books_id
                 AND TRUNC(dafrct.trx_date) >=
                     TRUNC(NVL(Fdsa.Start_Date, SYSDATE))
                 AND TRUNC(dafrct.trx_date) <=
                     TRUNC(NVL(Fdsa.End_Date, dafrct.trx_date))
                 AND fdsa.category_code = dafrct.cust_trx_type_name
                 AND fdsa.method_code = 'A');
  
    rec_sequences cur_sequences%ROWTYPE;
    rec_seq_fact  cur_seq_fact%ROWTYPE;
    nb_erreurs    NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure sequences : début');
    pn_codret := cn_ok;
    message(pn_codret, 'Controle séquences');
    -- Parcours des sequencees
    OPEN cur_sequences;
    LOOP
      FETCH cur_sequences
        INTO rec_sequences;
      EXIT WHEN cur_sequences%NOTFOUND;
      nb_erreurs := nb_erreurs + 1;
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Code séquence inexistant avec une affectation en manuelle : ' ||
                    rec_sequences.new_name;
      message(pn_codret, pv_errbuf);
    
    END LOOP;
    CLOSE cur_sequences;
    message(pn_codret,
            'Nombre de séquences manquantes en affectation manuelle : ' ||
            nb_erreurs);
    nb_erreurs := 0;
    -- Parcours des sequencees des factures
    debug(pv_debug, 'Affectation  liée aux factures :');
    OPEN cur_seq_fact;
    LOOP
    
      FETCH cur_seq_fact
        INTO rec_seq_fact;
      EXIT WHEN cur_seq_fact%NOTFOUND;
      nb_erreurs := nb_erreurs + 1;
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Affectation manquante : ' || rec_seq_fact.new_name;
      message(pn_codret, pv_errbuf);
    
    END LOOP;
    CLOSE cur_seq_fact;
    message(pn_codret,
            'Nombre d''affectations manquantes : ' || nb_erreurs);
    message(pn_codret, 'Fin controle séquences');
    IF pn_codret = cn_ctrl_ko THEN
      debug(pv_debug, 'Des séquences manquent dans la société absorbante.');
    END IF;
    debug(pv_debug, 'procédure sequences : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure sequences : Fin en erreur');
      debug(pv_debug,
            'erreur dans récupération des affectations de sequence de la société absorbante');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end sequences;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : edition de la lise des facture
  --  Description   : procédure qui sort la liste des factures/avoirs et la totalisation
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure edition_liste_facture(pn_codret IN OUT NUMBER,
                                  pv_errbuf OUT VARCHAR2,
                                  pv_debug  IN VARCHAR2) IS
    cursor c_liste_facture is
       select 1,
             rpad('Numéro', 30) || ' ' || rpad('Date', 10) || ' ' ||
             LPAD('Montant initial', 15) || ' ' ||
             LPAD('Montant réglement', 17) || ' ' || LPAD('Montant dû', 10) libelle
        FROM dual
      union
      select 2,
             rpad(dafict.trx_number, 30) || ' ' ||
             TO_CHAR(dafict.trx_date, 'DD/MM/YYYY') || ' ' ||
             LPAD(TO_CHAR(sum(dafict.customer_trx_amount),
                          '999999999990.00'),
                  17) || ' ' ||
             LPAD(TO_CHAR(NVL(dafict.adjustment_amount, 0) +
                          NVL(dafict.receivable_amount_line, 0) +
                          NVL(dafict.receivable_amount_tax, 0),
                          '999999999990.00'),
                  17) || ' ' ||
             LPAD(TO_CHAR(sum(dafict.customer_trx_amount) -
                          (NVL(dafict.adjustment_amount, 0) +
                           NVL(dafict.receivable_amount_line, 0) +
                           NVL(dafict.receivable_amount_tax, 0)),
                          '999999999990.00'),
                  17)
        from dka_ar_fusion_inv_ctrl_temp dafict
       group by dafict.trx_number,
                dafict.trx_date,
                nvl(dafict.adjustment_amount, 0) +
                nvl(dafict.receivable_amount_line, 0) +
                nvl(dafict.receivable_amount_tax, 0)
      union
      select 3,
             rpad('Total', 30) || ' ' || rpad(' ', 10) || ' ' ||
             LPAD(TO_CHAR(sum(dafict.customer_trx_amount),
                          '999999999990.00'),
                  21) || ' ' ||
             LPAD(TO_CHAR(sum(DECODE(dafict.line_type, NULL, NVL(dafict.adjustment_amount, 0) +
                              NVL(dafict.receivable_amount_line, 0) +
                              NVL(dafict.receivable_amount_tax, 0),0)),
                          '999999999990.00'),
                  17)|| ' ' ||
        LPAD(TO_CHAR(sum(dafict.customer_trx_amount)
        - sum(DECODE(dafict.line_type, NULL, NVL(dafict.adjustment_amount, 0) +
                              NVL(dafict.receivable_amount_line, 0) +
                              NVL(dafict.receivable_amount_tax, 0),0)),
                          '999999999990.00'),
                  17)
        from dka_ar_fusion_inv_ctrl_temp dafict
       group by 1, 2
       order by 1;
       
       
  
    rec_liste_facture c_liste_facture%rowtype;
    vv_retmsg         VARCHAR2(200);
  
  begin
    debug(pv_debug, 'procédure edition_liste_facture : début');
    select 'Edition Liste Factures' INTO vv_retmsg FROM dual;
    message(pn_codret, vv_retmsg);
    -- Parcours des factures pour les édditer
    for rec_liste_facture in c_liste_facture loop
      vv_retmsg := rec_liste_facture.libelle;
      message(pn_codret, vv_retmsg);
    end loop;
    select 'Fin de l''édition Liste Factures' INTO vv_retmsg FROM dual;
    message(pn_codret, vv_retmsg);
    debug(pv_debug, 'procédure edition_liste_facture : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure edition_liste_facture : Fin en erreur');
      debug(pv_debug, 'erreur dans récupération de la liste des factures');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end edition_liste_facture;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : edition de la liste des factures et avoir non compta
  --  Description   : procédure qui sort la liste des factures/avoirs non comptabilisés
  --                 et la totalisation
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure edition_liste_noncompta(pn_codret IN OUT NUMBER,
                                    pv_errbuf OUT VARCHAR2,
                                    pv_debug  IN VARCHAR2) IS
    cursor c_liste_noncompta is
      SELECT DISTINCT rpad(rcta.trx_number, 30) numero_piece,
                      TO_CHAR(rcta.trx_date, 'DD/MM/YYYY') date_piece,
                      sum(rctla.extended_amount) montant_piece
        FROM ra_cust_trx_line_gl_dist_all rctlda,
             hr_all_organization_units    houa,
             ra_customer_trx_lines_all    rctla,
             ra_customer_trx_all          rcta,
             ra_cust_trx_types_all        rctta,
             dka_stransco_lines           dsl,
             dka_stransco_headers         dsh
       WHERE dsh.set_name = cv_transco_fusion_societe
         and dsl.set_id = dsh.set_id -- tables de Transco sur les sociétés
         and dsl.enable = cv_enable
         and dsl.PARAM1_VALUE = houa.name
         and rcta.org_id = rctlda.org_id -- RG1
         and rcta.set_of_books_id = rctlda.set_of_books_id -- RG1
         and rcta.customer_trx_id = rctla.customer_trx_id -- RG1
         and rcta.org_id = rctla.org_id
         and rcta.set_of_books_id = rctla.set_of_books_id
         and rcta.cust_trx_type_id = rctta.cust_trx_type_id
         and rcta.org_id = houa.organization_id
            --  and rcta.set_of_books_id = vn_set_of_books_id
         and rcta.org_id = rctta.org_id
            --and nvl(rcta.INTERFACE_HEADER_CONTEXT, '1') <> 'FUSION'
         and rcta.set_of_books_id = rctta.set_of_books_id
         and rctla.customer_trx_line_id = rctlda.customer_trx_line_id -- RG1
         and rctla.customer_trx_id = rctlda.customer_trx_id
         and rctlda.gl_posted_date is null
       GROUP BY rcta.trx_number, rcta.trx_date
      having sum(rctla.extended_amount) <> 0
       order by 1;
  
    rec_liste_noncompta       c_liste_noncompta%rowtype;
    vv_retmsg                 VARCHAR2(200);
    Vn_montant_ajustement     number;
    Vn_receivable_amount_line number;
    Vn_receivable_amount_tax  number;
	Vn_total_facture          number := 0;
	Vn_total_reglement        number := 0;
	Vn_total_montant_du       number := 0;
  begin
    debug(pv_debug, 'procédure edition_liste_noncompta : début');
  
    select 'Edition des factures/avoirs non comptabilisés'
      INTO vv_retmsg
      FROM dual;
    message(pn_codret, vv_retmsg);
  
    select rpad('Numéro', 30) || ' ' || rpad('Date', 10) || ' ' ||
           LPAD('Montant facture/avoir', 21) || ' ' ||
           LPAD('Montant réglement', 17) || ' ' || LPAD('Montant dû', 10)
      INTO vv_retmsg
      FROM dual;
    message(pn_codret, vv_retmsg);
  
    -- Parcours des factures pour les éditer
    for rec_liste_noncompta in c_liste_noncompta loop
      BEGIN
        SELECT sum(amount)
          INTO Vn_montant_ajustement
          FROM ar_adjustments_all
         WHERE status = cv_AAA_status_applied
           AND customer_trx_id in
               (select customer_trx_id
                  from ra_customer_trx_all
                 where trx_number = rec_liste_noncompta.numero_piece);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          Vn_montant_ajustement := 0;
        WHEN OTHERS THEN
          pv_errbuf := SQLERRM;
          message(pn_codret, 'ERROR : ' || pv_errbuf);
      END;
    
      BEGIN
        SELECT sum(line_applied), sum(tax_applied)
          INTO Vn_receivable_amount_line, Vn_receivable_amount_tax
          FROM ar_receivable_applications_all
         WHERE status = cv_ARAA_status_applied
           AND customer_trx_id in
               (select customer_trx_id
                  from ra_customer_trx_all
                 where trx_number = rec_liste_noncompta.numero_piece);
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          Vn_receivable_amount_line := 0;
          Vn_receivable_amount_tax  := 0;
        WHEN OTHERS THEN
          pv_errbuf := SQLERRM;
          message(pn_codret, 'ERROR : ' || pv_errbuf);
      END;
	  Vn_total_facture := Vn_total_facture + rec_liste_noncompta.montant_piece;
		Vn_total_reglement := Vn_total_reglement 
		                      + NVL(Vn_montant_ajustement, 0)
							  + NVL(Vn_receivable_amount_line, 0)
							  + NVL(Vn_receivable_amount_tax, 0);
      vv_retmsg := rec_liste_noncompta.numero_piece || ' ' ||
                   rec_liste_noncompta.date_piece || ' ' ||
                   LPAD(TO_CHAR(rec_liste_noncompta.montant_piece,
                                '999999999990.00'),
                        21) || ' ' ||
                   LPAD(TO_CHAR(NVL(Vn_montant_ajustement, 0) +
                                NVL(Vn_receivable_amount_line, 0) +
                                NVL(Vn_receivable_amount_tax, 0),
                                '999999999990.00'),
                        17) || ' ' ||
                   LPAD(TO_CHAR(rec_liste_noncompta.montant_piece -
                                (NVL(Vn_montant_ajustement, 0) +
                                NVL(Vn_receivable_amount_line, 0) +
                                NVL(Vn_receivable_amount_tax, 0)),
                                '999999999990.00'),
                        16);
      message(pn_codret, vv_retmsg);
    end loop;
	select rpad('Totaux', 30) || ' ' || 
           LPAD('Montant facture/avoir', 21) || ' ' ||
           LPAD('Montant réglement', 17) || ' ' || LPAD('Montant dû', 10)
      INTO vv_retmsg
      FROM dual;
    message(pn_codret, vv_retmsg);
	Vn_total_montant_du := Vn_total_facture - Vn_total_reglement;
	 vv_retmsg := LPAD(TO_CHAR(Vn_total_facture,
                                '999999999990.00'),
                        51) || ' ' ||
                   LPAD(TO_CHAR(Vn_total_reglement,
                                '999999999990.00'),
                        17) || ' ' ||
                   LPAD(TO_CHAR(Vn_total_montant_du,
                                '999999999990.00'),
                        16);
	message(pn_codret, vv_retmsg);
    Select 'Fin de l''édition des factures/avoirs non comptabilisés'
      INTO vv_retmsg
      FROM dual;
    message(pn_codret, vv_retmsg);
  
    debug(pv_debug, 'procédure edition_liste_noncompta : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret,
              'Procédure edition_liste_noncompta : Fin en erreur');
      debug(pv_debug, 'erreur dans récupération de la liste des factures');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end edition_liste_noncompta;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : type_mvt
  --  Description   : procédure qui controle l'existence des types de mouvements dans la société absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure type_mvt(pn_codret IN OUT NUMBER,
                     pv_errbuf OUT VARCHAR2,
                     pv_debug  IN VARCHAR2) IS
    cursor c_type_mvt is
      SELECT distinct rctta.name name
        FROM ra_cust_trx_types_all       rctta,
             dka_ar_fusion_inv_ctrl_temp dafict
       WHERE rctta.cust_trx_type_id = dafict.cust_trx_type_id
         AND not exists
       (select null
                from ra_cust_trx_types_all rctta1
               where rctta1.name = rctta.name
                 and rctta1.org_id = dafict.org_id_absorbante);
    cursor c_config_mvt is
      SELECT distinct dsl.return_value name
        FROM dka_ar_fusion_inv_ctrl_temp dafict,
             dka_stransco_lines          dsl,
             dka_stransco_headers        dsh
       WHERE dsh.set_name = cv_fusion_type_mouvement -- table de transco des types de mouvement
         AND dsl.set_id = dsh.set_id
         and dsl.enable = 'Y'
         AND not exists
       (select null
                from ra_cust_trx_types_all     rctta,
                     hr_all_organization_units houa
               where dsl.return_value = rctta.name
                 and houa.name = dafict.SOCIETE_ABSORBANTE
                 and houa.organization_id = rctta.org_id);
  
    rec_type_mvt   c_type_mvt%rowtype;
    rec_config_mvt c_config_mvt%rowtype;
    nb_erreurs     NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure type_mvt : début');
    pn_codret := cn_ok;
    message(pn_codret, 'Controle types de mouvement');
    -- Parcours des type de mouvement
    for rec_type_mvt in c_type_mvt loop
      pn_codret  := cn_ctrl_ko;
      nb_erreurs := nb_erreurs + 1;
      pv_errbuf  := 'Type de mouvement inexistant : ' || rec_type_mvt.name;
      message(pn_codret, pv_errbuf);
    end loop;
    message(pn_codret,
            'Nombre de types de mouvement manquants : ' || nb_erreurs);
  
    IF pn_codret = cn_ctrl_ko THEN
      debug(pv_debug,
            'Des types de mouvement manquent dans la société absorbante.');
    END IF;
  
    -- Vérification de la configuration des types de mouvement en annulation dans
    -- la table de transcodification FUSION_TYPE_MOUVEMENT
    pn_codret  := cn_ok;
    nb_erreurs := 0;
    -- Parcours de la configuration des types de mouvement
    for rec_config_mvt in c_config_mvt loop
      pn_codret  := cn_ctrl_ko;
      nb_erreurs := nb_erreurs + 1;
      pv_errbuf  := 'Type de mouvement non configuré : ' ||
                    rec_config_mvt.name;
      message(pn_codret, pv_errbuf);
    end loop;
    message(pn_codret,
            'Configuration de types de mouvement manquantes : ' ||
            nb_erreurs);
    message(pn_codret, 'Fin controle types de mouvement');
    IF pn_codret = cn_ctrl_ko THEN
      debug(pv_debug, 'Des types de mouvement ne sont pas configurés.');
    END IF;
    -- récupération des noms dans la table temporaire
    UPDATE dka_ar_fusion_inv_ctrl_temp dafrct
       set cust_trx_type_name    =
           (select rctta.name
              from ra_cust_trx_types_all rctta
             where rctta.cust_trx_type_id = dafrct.cust_trx_type_id),
           new_cust_trx_type_name =
           (select rctta.name
              from ra_cust_trx_types_all rctta
             where rctta.cust_trx_type_id = dafrct.cust_trx_type_id);
  
    UPDATE dka_ar_fusion_inv_ctrl_temp dafrct
       set new_cust_trx_type_id =
           (select rctta.cust_trx_type_id
              from ra_cust_trx_types_all rctta
             where rctta.name = dafrct.new_cust_trx_type_name
               AND rctta.org_id = dafrct.org_id_absorbante);
    debug(pv_debug, 'procédure type_mvt : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure type_mvt : Fin en erreur');
      debug(pv_debug, 'erreur dans le contole des types de mouvements');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end type_mvt;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : origine_mvt
  --  Description   : procédure qui controle l'existence des origines de mouvements dans la société absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug                   Indicateur de debug
  --      pn_codret                  code de retour
  --      pv_errbuf                  Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure origine_mvt(pn_codret IN OUT NUMBER,
                        pv_errbuf OUT VARCHAR2,
                        pv_debug  IN VARCHAR2) IS
    cursor c_origine_mvt is
      SELECT distinct nvl((select rbsa.name
                            from ra_batch_sources_all      rbsa,
                                 hr_all_organization_units houa
                           where rbsa.name = 'FUSION'
                             and houa.name = dafrct.SOCIETE_ABSORBANTE
                             and rbsa.ORG_ID = houa.ORGANIZATION_ID),
                          'Non') Soc_absorbante,
                      nvl((select rbsa.name
                            from ra_batch_sources_all      rbsa,
                                 hr_all_organization_units houa
                           where rbsa.name = 'FUSION'
                             and houa.name = dafrct.SOCIETE_ABSORBEE
                             and rbsa.ORG_ID = houa.ORGANIZATION_ID),
                          'Non') Soc_absorbee
        FROM dka_ar_fusion_inv_ctrl_temp dafrct;
  
    rec_origine_mvt c_origine_mvt%rowtype;
    nb_erreurs      number(15) := 0;
  begin
    debug(pv_debug, 'procédure origine_mvt : début');
    pn_codret := cn_ok;
    message(pn_codret, 'Controle origine mouvement');
    -- Parcours des origines
    for rec_origine_mvt in c_origine_mvt loop
      pn_codret := cn_ctrl_ko;
      IF rec_origine_mvt.soc_absorbante <> 'FUSION' THEN
        pv_errbuf := 'Origine du mouvement FUSION inexistante sur la société absorbante';
      
        nb_erreurs := nb_erreurs + 1;
        message(pn_codret, pv_errbuf);
      
      END IF;
    
      IF rec_origine_mvt.soc_absorbee <> 'FUSION' THEN
        pv_errbuf := 'Origine du mouvement FUSION inexistante sur la société absorbée';
      
        nb_erreurs := nb_erreurs + 1;
        message(pn_codret, pv_errbuf);
      
      END IF;
    end loop;
    IF pn_codret = cn_ctrl_ko THEN
      debug(pv_debug,
            'Des origines de mouvement manquent dans la société absorbante.');
    END IF;
    message(pn_codret,
            'Nombre d''origines mouvement en erreur : ' || nb_erreurs);
    message(pn_codret, 'Fin controle origines mouvement');
    debug(pv_debug, 'procédure origine_mvt : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure origine_mvt : Fin en erreur');
      debug(pv_debug, 'erreur dans le controle des types de mouvements');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end origine_mvt;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : sites_clients
  --  Description   : procédure qui controle la présence des sites clients dans l'UO absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug  IN VARCHAR2(1)    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure sites_clients(pn_codret IN OUT NUMBER,
                          pv_errbuf OUT VARCHAR2,
                          pv_debug  IN VARCHAR2) IS
  
    -- CURSEUR
    CURSOR cur_sites_clients IS
      SELECT distinct address1 || ' ' || address2 || ' ' || address3 || ' ' ||
                      address4 || ' ' || city || ' ' || postal_code || ' ' ||
                      country adresse
        FROM hz_locations           hl,
             hz_party_sites         hpz,
             hz_cust_acct_sites_all hcasa,
             dka_stransco_headers   dsh,
             dka_stransco_lines     dsl,
             hr_operating_units     hou
       WHERE dsh.set_name = cv_transco_fusion_societe
         AND dsh.set_id = dsl.set_id
         AND dsl.PARAM1_VALUE = hou.name
         AND hcasa.org_id = hou.organization_id
         AND hpz.location_id = hl.location_id
         AND hpz.party_site_id = hcasa.party_site_id
         AND NOT EXISTS
       (SELECT 'X'
                FROM hz_locations           hl1,
                     hz_party_sites         hpz1,
                     hz_cust_acct_sites_all hcasa1,
                     dka_stransco_headers   dsh1,
                     dka_stransco_lines     dsl1,
                     hr_operating_units     hou1
               WHERE dsh1.set_name = cv_transco_fusion_societe
                 AND dsh1.set_id = dsl1.set_id
                 AND dsl1.return_value = hou1.name
                 AND hcasa1.org_id = hou1.organization_id
                 AND hpz1.location_id = hl1.location_id
                 AND hpz1.party_site_id = hcasa1.party_site_id);
  
    rec_sites_clients cur_sites_clients%rowtype;
    nb_erreurs        NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure sites_clients : début');
    pn_codret := cn_ok;
    message(pn_codret, 'Controle sites clients');
    -- Parcours des sites_clients
    OPEN cur_sites_clients;
    LOOP
      FETCH cur_sites_clients
        INTO rec_sites_clients;
      EXIT WHEN cur_sites_clients%NOTFOUND;
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Site inexistant : ' || rec_sites_clients.adresse;
      nb_erreurs := nb_erreurs + 1;
      message(pn_codret, pv_errbuf);
    
    END LOOP;
    CLOSE cur_sites_clients;
    IF pn_codret = cn_ctrl_ko THEN
      debug(pv_debug, 'Des sites manquent dans la société absorbante.');
    END IF;
    message(pn_codret,
            'Nombre de sites clients manquants : ' || nb_erreurs);
    message(pn_codret, 'Fin controle sites clients');
    debug(pv_debug, 'procédure sites_clients : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure sites_clients : Fin en erreur');
      debug(pv_debug,
            'erreur dans récupération des sites_clients de la société absorbante');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end sites_clients;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : prelevement
  --  Description   : procédure qui controle que tout prélèvement de l'UO absorbée est remis
  --                  en banque
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure prelevement(pn_codret IN OUT NUMBER,
                        pv_errbuf OUT VARCHAR2,
                        pv_debug  IN VARCHAR2) IS
    cursor c_prlvt is
      select distinct dafct.receipt_number num_encaissement, arc.name
        from dka_ar_fusion_rec_ctrl_temp dafct,
             ar_cash_receipts_all        acra,
             AR_CASH_RECEIPT_HISTORY_all CRH_CURRENT,
             ar_receipt_methods          arm,
             ar_receipt_classes          arc
       where dafct.cash_receipt_id = acra.cash_receipt_id
         and acra.receipt_method_id = arm.receipt_method_id
         and arm.receipt_class_id = arc.receipt_class_id
         and arc.RECEIPT_CLASS_ID = 1002 -- PRELEVEMENT
         and CRH_CURRENT.CASH_RECEIPT_ID = acra.CASH_RECEIPT_ID
         and CRH_CURRENT.CURRENT_RECORD_FLAG = 'Y'
         and acra.STATUS <> 'REMITTED';
  
    rec_prlvt  c_prlvt%rowtype;
    nb_erreurs NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure prélèvement : début');
    pn_codret := cn_ok;
    message(pn_codret, 'Controle prélèvements');
    -- On vérifie le statut du prélèvement qui doit àªtre remis en banque
    for rec_prlvt in c_prlvt loop
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Prélèvement non remis en banque : ' ||
                    rec_prlvt.num_encaissement;
      nb_erreurs := nb_erreurs + 1;
      message(pn_codret, pv_errbuf);
    end loop;
    message(pn_codret,
            'Nombre de prélèvements non remis en banque : ' || nb_erreurs);
    message(pn_codret, 'Fin controle prélèvements');
    if pn_codret = cn_ctrl_ko THEN
      debug(pv_debug, 'Des prélèvements n''ont pas été remis en banque');
    end if;
  
    debug(pv_debug, 'procédure prélèvement : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure code_tva : Fin en erreur');
      debug(pv_debug,
            'erreur dans le controle des prélèvements de lUO absorbée');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end prelevement;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : absorbee_absorbante
  --  Description   : procédure qui controle qu'il n'y a pas de mouvements en cours sur l'absorbée
  --                  avec l'absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure absorbee_absorbante(pn_codret IN OUT NUMBER,
                                pv_errbuf OUT VARCHAR2,
                                pv_debug  IN VARCHAR2) IS
    cursor c_mvt_abs is
      SELECT distinct dafict.TRX_NUMBER num_mouvement
        FROM DKA_AR_FUSION_INV_CTRL_TEMP dafict, dka_ar_fusion_gcc_temp gcc
       WHERE dafict.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID --and  customer_trx_id = 1231370
         and substr(gcc.SEGMENT5, 4, 4) =
             substr(dafict.SOCIETE_ABSORBANTE, 4, 4)
         and gcc.segment1 = substr(dafict.SOCIETE_ABSORBEE, 4, 4);
  
    cursor c_mvt_abs_absor is
      SELECT distinct dafict.TRX_NUMBER num_mouvement
        FROM DKA_AR_FUSION_INV_CTRL_TEMP dafict, dka_ar_fusion_gcc_temp gcc
       WHERE dafict.CODE_COMBINATION_ID = gcc.CODE_COMBINATION_ID --and  customer_trx_id = 1231370
         and substr(gcc.SEGMENT5, 4, 4) =
             substr(dafict.SOCIETE_ABSORBEE, 4, 4)
         and gcc.segment1 = substr(dafict.SOCIETE_ABSORBANTE, 4, 4);
  
    rec_mvt_abs       c_mvt_abs%rowtype;
    rec_mvt_abs_absor c_mvt_abs_absor%rowtype;
    nb_erreurs        NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure absorbee_absorbante : début');
    pn_codret := cn_ok;
    message(pn_codret,
            'Controle mouvements de l''absorbée vers l''absorbante');
    for rec_mvt_abs in c_mvt_abs loop
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Mouvement en cours sur l''absorbee avec l''absorbante :' ||
                    rec_mvt_abs.num_mouvement;
      nb_erreurs := nb_erreurs + 1;
      message(pn_codret, pv_errbuf);
    end loop;
    message(pn_codret,
            'Nombre de mouvements en cours sur l''absorbée avec l''absorbante : ' ||
            nb_erreurs);
    message(pn_codret,
            'Fin controle mouvements de l''absorbée vers l''absorbante');
    if pn_codret = cn_ctrl_ko then
      debug(pv_debug,
            'Des mouvements sont en cours sur l''absorbee avec l''absorbante');
    end if;
  
    nb_erreurs := 0;
    pn_codret  := cn_ok;
    message(pn_codret,
            'Controle mouvements de l''absorbante vers l''absorbée');
    for rec_mvt_abs_absor in c_mvt_abs_absor loop
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Mouvement en cours sur l''absorbante avec l''absorbée :' ||
                    rec_mvt_abs.num_mouvement;
      nb_erreurs := nb_erreurs + 1;
      message(pn_codret, pv_errbuf);
    end loop;
    message(pn_codret,
            'Nombre de mouvements en cours sur l''absorbante avec l''absorbée : ' ||
            nb_erreurs);
    message(pn_codret,
            'Fin controle mouvements de l''absorbante vers l''absorbée');
    if pn_codret = cn_ctrl_ko then
      debug(pv_debug,
            'Des mouvements sont en cours sur l''absorbante avec l''absorbée');
    end if;
  
    debug(pv_debug, 'procédure absorbee_absorbante : fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure absorbee_absorbante : Fin en erreur');
      debug(pv_debug,
            'erreur dans le controle des prélèvements de lUO absorbée');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end absorbee_absorbante;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : code_tva
  --  Description   : procédure qui controle l'existence des code TVA dans la société absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure code_tva(pn_codret IN OUT NUMBER,
                     pv_errbuf OUT VARCHAR2,
                     pv_debug  IN VARCHAR2) IS
  
    cursor cur_ctr_tva_absorbante is
      select z.TAX_RATE_CODE
        from dka_ar_fusion_inv_ctrl_temp dafict, zx_rates_b z
       where z.TAX_RATE_ID = dafict.VAT_TAX_ID
         AND NOT EXISTS
       (SELECT za.tax_account_entity_id,
                     za.internal_organization_id,
                     za.ledger_id,
                     za.tax_account_ccid,
                     za.non_rec_account_ccid,
                     za.interim_tax_ccid,
                     hrou.name,
                     gl.name as ledger_name
                FROM zx_accounts            za,
                     hr_operating_units     hrou,
                     gl_ledgers             gl,
                     fnd_id_flex_structures fifs
               WHERE ZA.INTERNAL_ORGANIZATION_ID = HROU.ORGANIZATION_ID
                 AND GL.LEDGER_ID = ZA.LEDGER_ID
                 AND sysdate BETWEEN nvl(date_from, sysdate) AND
                     nvl(date_to, sysdate)
                 AND FIFS.APPLICATION_ID = 101
                 AND FIFS.ID_FLEX_CODE = 'GL#'
                 AND FIFS.ID_FLEX_NUM = GL.CHART_OF_ACCOUNTS_ID
                 AND hrou.organization_id = dafict.ORG_ID_ABSORBANTE
                 and tax_account_entity_id = dafict.vat_tax_id);
  
    rec_ctr_tva_absorbante cur_ctr_tva_absorbante%ROWTYPE;
    nb_erreurs             NUMBER(15) := 0;
  
  begin
    debug(pv_debug, 'procédure code_tva : début');
    pn_codret := cn_ok;
  
    update dka_ar_fusion_inv_ctrl_temp dafrct
       set tax_code =
           (select avta.tax_rate_code
              from zx_rates_b avta
             where avta.TAX_RATE_ID = dafrct.vat_tax_id);
  
    for rec_ctr_tva_absorbante in cur_ctr_tva_absorbante loop
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Code TVA non existant sur l''UO Absorbante : ' ||
                    rec_ctr_tva_absorbante.tax_rate_code;
      nb_erreurs := nb_erreurs + 1;
      message(pn_codret, pv_errbuf);
    end loop;
  
    pv_errbuf := 'Nombre code TVA inexistant sur UO absorbante : ' ||
                 nb_erreurs;
    message(pn_codret, pv_errbuf);
    debug(pv_debug, 'procédure code_tva : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure code_tva : Fin en erreur');
      debug(pv_debug, 'erreur dans le controle des codes de TVA');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end code_tva;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : valeur_valide
  --  Description   : procédure qui contole si la valeur du segment est valide dans le jeu de valeur si elle
  --                n'est pas valide, on met à  jour la valeur afin qu'elle le soit et on mémorise les dates
  --                de validité qu'il y avait afin de les restaurer en fin de traitement.
  --
  --  PARAMETRES    :
  --      pn_codret     code retour
  --      pv_debug      Indicateur de debug
  --      pv_segment    Nom du segment
  --      pv_valeur     Valeur du segment
  --      pv_errbuf     Messagee d'erreur
  --  VALEUR RETOURNEE :
  --      Vrai si la valeur existe faux sinon
  ---------------------------------------------------------------------------------------------------------------
  FUNCTION valeur_valide(pn_codret  IN OUT NUMBER,
                         pv_debug   IN VARCHAR2,
                         pv_segment IN VARCHAR2,
                         pv_valeur  IN VARCHAR,
                         pv_errbuf  OUT VARCHAR2) RETURN BOOLEAN IS
  
    vv_message_flag      VARCHAR2(1);
    vr_ROWID             ROWID;
    cv_enabled_flag      fnd_flex_values.enabled_flag%TYPE;
    vd_start_date_active DATE;
    vd_end_date_active   DATE;
    vn_flex_value_set_id fnd_flex_value_sets.flex_value_set_id%TYPE;
  
  BEGIN
    vv_message_flag := 'S'; -- Select
    -- selection de la valeur dans le jeux de valeur et de sa palges de validité
    SELECT ffv.ROWID,
           ffv.enabled_flag,
           fFv.start_date_active,
           ffv.end_date_active,
           ffv.flex_value_set_id
      INTO vr_ROWID,
           cv_enabled_flag,
           vd_start_date_Active,
           vd_end_date_active,
           vn_flex_value_set_id
      FROM fnd_id_flex_segments fifs,
           gl_sets_of_books     gsob,
           fnd_flex_values      ffv
     WHERE Gsob.set_of_books_Id = vn_set_of_books_id
       AND fifs.application_id = cn_gl_application_id
       AND fifs.id_flex_code = cv_gl_id_flex_code
       AND fifs.id_flex_num = gsob.chart_of_accounts_id
       AND fifs.application_column_name = pv_segment
       AND ffv.flex_value_set_id = fifs.flex_value_set_id
       AND ffv.flex_value = pv_valeur
       AND NVL(decode(NVL(FFv.enabled_flag, cv_disable),
                      cv_disable,
                      '1',
                      NULL),
               NVL(ffv.start_date_active, ffv.end_date_active)) IS NOT NULL;
    -- Valeur non valide : Insertion dans la table historique et revalidation de la valeur
  
    -- insertion valeur
    vv_message_flag := 'I'; -- insert
    insert into dka_ar_fusion_ffv_temp
      (flex_value_set_id,
       flex_value,
       start_date_active,
       end_date_active,
       enabled_flag)
    values
      (vn_flex_value_set_id
       
      ,
       pv_valeur,
       vd_start_date_active,
       vd_end_date_active,
       cv_enabled_flag);
  
    vv_message_flag := 'U'; -- update
    update fnd_flex_values ffv
       set ffv.enabled_flag      = cv_enable,
           ffv.start_date_active = null,
           ffv.end_date_active   = null
     where rowid = vr_rowid;
  
    return true;
  exception
    when no_data_found then
      -- valeur valide : ok
      return true;
    when others then
      IF vv_message_flag = 'S' THEN
        pv_errbuf := 'Erreur dans la selection de la valeur ' || pv_valeur ||
                     ' dans le jeu de valeur lié au ' || pv_segment;
        message(pn_codret, pv_errbuf);
        debug(pv_debug, pv_errbuf);
      ELSIF vv_message_flag = 'I' THEN
        pv_errbuf := 'Erreur dans l''insertion de la valeur ' || pv_valeur ||
                     ' dans le jeu de valeur lié au ' || pv_segment;
        message(pn_codret, pv_errbuf);
        debug(pv_debug, pv_errbuf);
      ELSE
        pv_errbuf := 'Erreur dans l''activation de la valeur ' || pv_valeur ||
                     ' dans le jeu de valeur lié au ' || pv_segment;
        message(pn_codret, pv_errbuf);
        debug(pv_debug, pv_errbuf);
      END IF;
      return false;
  END valeur_valide;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : valeur_generique
  --  Description   : procédure qui recherche les comptes local/goupe dans la table de transco
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure valeur_generique(pn_codret           OUT NUMBER,
                             pv_errbuf           OUT VARCHAR2,
                             pv_debug            IN VARCHAR2,
                             pv_segment3         IN VARCHAR2,
                             pv_segment4         IN VARCHAR2,
                             pv_new_segment3     OUT VARCHAR2,
                             pv_new_segment4     OUT VARCHAR2,
                             pv_new_segment4_bis OUT VARCHAR2) IS
  BEGIN
    debug(pv_debug, 'procédure valeur_generique : début');
  
    select dsll.return_value, dslg.return_value, dslh.return_value
      into pv_new_segment3, pv_new_segment4, pv_new_segment4_bis
      from dka_stransco_headers dsh,
           dka_stransco_lines   dsll,
           dka_stransco_lines   dslg,
           dka_stransco_lines   dslh
     where dsh.set_name = cv_transco_compte_generique
       and dsll.set_id = dsh.set_id
       and upper(dsll.param1_value) = cv_transco_gen_appli
       and upper(dsll.param2_value) = cv_transc_cpte_local_client
       and dslg.set_id = dsh.set_id
       and upper(dslg.param1_value) = cv_transco_gen_appli
       and upper(dslg.param2_value) = cv_transco_cpte_groupe
       and dslh.set_id = dsh.set_id
       and upper(dslh.param1_value) = cv_transco_gen_appli
       and upper(dslh.param2_value) = cv_transc_cpte_local_douteux;
  
    debug(pv_debug, 'procédure valeur_generique : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure valeur_generique : Fin en erreur');
      debug(pv_debug, 'erreur dans la recupération des comptes génériques');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  END valeur_generique;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : creation_ccid
  --  Description   : procédure qui récuupère les CCID des sociétés absorbée
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure creation_ccid(pn_codret IN OUT NUMBER,
                          pv_errbuf OUT VARCHAR2,
                          pv_debug  IN VARCHAR2) IS
  begin
    debug(pv_debug, 'procédure creation_ccid : début');
    insert into dka_ar_fusion_gcc_temp
      (code_combination_id,
       segment1,
       segment2,
       segment3,
       segment4,
       segment5,
       segment6,
       segment7,
       segment8,
       segment9,
       segment10,
       segment11,
       segment12,
       enable_absorbee,
       old_start_date_active,
       old_end_date_active,
       societe_absorbante,
       account_class,
       line_type)
      select distinct dafrct.code_combination_id,
                      gcc.segment1,
                      gcc.segment2,
                      gcc.segment3,
                      gcc.segment4,
                      gcc.segment5,
                      gcc.segment6,
                      gcc.segment7,
                      gcc.segment8,
                      gcc.segment9,
                      gcc.segment10,
                      gcc.segment11,
                      gcc.segment12,
                      gcc.enabled_flag,
                      gcc.start_date_active,
                      gcc.end_date_active,
                      dafrct.societe_absorbante,
                      dafrct.account_class,
                      dafrct.line_type
        from gl_code_combinations gcc, dka_ar_fusion_inv_ctrl_temp dafrct
       where gcc.code_combination_id = dafrct.code_combination_id;
  
    insert into dka_ar_fusion_gcc_temp
      (code_combination_id,
       segment1,
       segment2,
       segment3,
       segment4,
       segment5,
       segment6,
       segment7,
       segment8,
       segment9,
       segment10,
       segment11,
       segment12,
       enable_absorbee,
       old_start_date_active,
       old_end_date_active,
       societe_absorbante,
       account_class,
       line_type)
      select distinct gcc.code_combination_id,
                      gcc.segment1,
                      gcc.segment2,
                      gcc.segment3,
                      gcc.segment4,
                      gcc.segment5,
                      gcc.segment6,
                      gcc.segment7,
                      gcc.segment8,
                      gcc.segment9,
                      gcc.segment10,
                      gcc.segment11,
                      gcc.segment12,
                      gcc.enabled_flag,
                      gcc.start_date_active,
                      gcc.end_date_active,
                      dafrct.societe_absorbante,
                      dafrct.account_class,
                      dafrct.line_type
        from gl_code_combinations gcc, dka_ar_fusion_inv_ctrl_temp dafrct
       where gcc.code_combination_id = dafrct.collected_tax_ccid
         and not exists
       (select '1'
                from dka_ar_fusion_gcc_temp d
               where d.code_combination_id = dafrct.collected_tax_ccid);
  
    debug(pv_debug, 'procédure creation_ccid : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure creation_ccid : Fin en erreur');
      debug(pv_debug, 'erreur dans le controle des codes de TVA');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end creation_ccid;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : init_nouveau_ccid
  --  Description   : procédure qui récuupère les CCID des sociétés absorbée
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure init_nouveau_ccid(pn_codret IN OUT NUMBER,
                              pv_errbuf OUT VARCHAR2,
                              pv_debug  IN VARCHAR2) IS
  
    cursor c_ccid is
      select distinct code_combination_id,
                      segment1,
                      segment2,
                      segment3,
                      segment4,
                      segment5,
                      segment6,
                      segment7,
                      segment8,
                      segment9,
                      segment10,
                      segment11,
                      segment12,
                      account_class,
                      line_type,
                      societe_absorbante
        from dka_ar_fusion_gcc_temp
       order by account_class;
  
    rec_ccid            c_ccid%rowtype;
    vn_new_ccid         gl_code_combinations.code_combination_id%type;
    vn_orig_ccid        gl_code_combinations.code_combination_id%type;
    vv_new_segment3     gl_code_combinations.segment3%type;
    vv_new_segment4     gl_code_combinations.segment4%type;
    vv_new_segment3_bis gl_code_combinations.segment3%type;
    vv_segment4         gl_code_combinations.segment4%type;
    v_errbuf            VARCHAR2(2500);
  begin
    debug(pv_debug, 'procédure init_nouveau_ccid : début');
    For rec_ccid in c_ccid loop
      if rec_ccid.account_class = cv_ligne_taxe or
         rec_ccid.account_class = cv_ligne_rec then
        -- vérification de la validité des valeurs dans les jeux de valeurs
        IF not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT1',
                             rec_ccid.segment1,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT2',
                             rec_ccid.segment2,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT3',
                             rec_ccid.segment3,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT4',
                             rec_ccid.segment4,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT5',
                             rec_ccid.segment5,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT6',
                             rec_ccid.segment6,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT7',
                             rec_ccid.segment7,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT8',
                             rec_ccid.segment8,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT9',
                             rec_ccid.segment9,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT10',
                             rec_ccid.segment10,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT11',
                             rec_ccid.segment11,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT12',
                             rec_ccid.segment12,
                             v_errbuf) THEN
          pn_codret := cn_warning;
          message(pn_codret,
                  'Erreur dans la vérification de la validité des valeurs ' ||
                  rec_ccid.segment1 || '/' || rec_ccid.segment2 || '/' ||
                  rec_ccid.segment3 || '/' || rec_ccid.segment4 || '/' ||
                  rec_ccid.segment5 || '/' || rec_ccid.segment6 || '/' ||
                  rec_ccid.segment7 || '/' || rec_ccid.segment8 || '/' ||
                  rec_ccid.segment9 || '/' || rec_ccid.segment10 || '/' ||
                  rec_ccid.segment11 || '/' || rec_ccid.segment12);
          RETURN;
        END IF;
        -- Controle de la validité de la ccombinaison dans la société absorbante
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(rec_ccid.societe_absorbante,
                                                                               4,
                                                                               4),
                                              pv_segment2            => rec_ccid.segment2,
                                              pv_segment3            => rec_ccid.segment3,
                                              pv_segment4            => rec_ccid.segment4,
                                              pv_segment5            => rec_ccid.segment5,
                                              pv_segment6            => rec_ccid.segment6,
                                              pv_segment7            => rec_ccid.segment7,
                                              pv_segment8            => rec_ccid.segment8,
                                              pv_segment9            => rec_ccid.segment9,
                                              pv_segment10           => rec_ccid.segment10,
                                              pv_segment11           => rec_ccid.segment11,
                                              pv_segment12           => rec_ccid.segment12,
                                              pn_code_combination_id => vn_new_ccid,
                                              pv_errbuf              => v_errbuf,
                                              pn_retcode             => pn_codret,
                                              pv_validation_flag     => cv_enable);
      
        if nvl(vn_new_ccid, 0) = 0 then
          -- probleme lors de la recherche du noouveau ccid
          message(pn_codret, v_errbuf);
          v_errbuf := 'Erreur lors de la recherche du ccid de la ligne de distribution - Cas1';
          message(pn_codret, v_errbuf);
          debug(pv_debug,
                'Erreur lors de la recherche du ccid de la ligne de distribution');
          debug(pv_debug, v_errbuf);
          pn_codret := cn_warning;
          message(pn_codret,
                  'Compte comptable à  créer manuellement pour ligne de taxe ');
          message(pn_codret,
                  vn_new_ccid || '/' ||
                  substr(rec_ccid.societe_absorbante, 4, 4) || '/' ||
                  rec_ccid.segment2 || '/' || rec_ccid.segment3 || '/' ||
                  rec_ccid.segment4 || '/' || rec_ccid.segment5 || '/' ||
                  rec_ccid.segment6 || '/' || rec_ccid.segment7 || '/' ||
                  rec_ccid.segment8 || '/' || rec_ccid.segment9 || '/' ||
                  rec_ccid.segment10 || '/' || rec_ccid.segment11 || '/' ||
                  rec_ccid.segment12);
          RETURN;
        end if;
      
      else
        -- = 'REV'
        valeur_generique(pn_codret,
                         pv_errbuf,
                         pv_debug,
                         rec_ccid.segment3,
                         rec_ccid.segment4,
                         vv_new_segment3,
                         vv_new_segment4,
                         vv_new_segment3_bis);
        if pn_codret = cn_error then
          debug(pv_debug,
                'Erreur dans la récupération des comptes local/groupe génériques.');
          RETURN;
        end if;
        if rec_ccid.line_type = 'CB' then
          vv_new_segment3 := vv_new_segment3_bis;
        end if;
        -- Controle de la validité de la ccombinaison dans la société absorbante
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(rec_ccid.societe_absorbante,
                                                                               4,
                                                                               4),
                                              pv_segment2            => rec_ccid.segment2,
                                              pv_segment3            => vv_new_segment3,
                                              pv_segment4            => vv_new_segment4,
                                              pv_segment5            => '0',
                                              pv_segment6            => '0',
                                              pv_segment7            => '0',
                                              pv_segment8            => '0',
                                              pv_segment9            => '0',
                                              pv_segment10           => '0',
                                              pv_segment11           => '0',
                                              pv_segment12           => '0',
                                              pn_code_combination_id => vn_new_ccid,
                                              pv_errbuf              => v_errbuf,
                                              pn_retcode             => pn_codret,
                                              pv_validation_flag     => cv_enable);
        if nvl(vn_new_ccid, 0) = 0 then
          -- probleme lors de la recherche du noouveau ccid
          message(pn_codret, v_errbuf);
          v_errbuf := 'Erreur lors de la recherche du ccid de la ligne de distribution - Cas2';
          message(pn_codret, v_errbuf);
          debug(pv_debug, v_errbuf);
          pn_codret := cn_warning;
          message(pn_codret,
                  'Compte comptable à  créer manuellement pour lignes produits');
          message(pn_codret,
                  vn_new_ccid || '/' ||
                  substr(rec_ccid.societe_absorbante, 4, 4) || '/' ||
                  rec_ccid.segment2 || '/' || vv_new_segment3 || '/' ||
                  vv_new_segment4 || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0');
        
          RETURN;
        end if;
      
        -- Controle de la validité de la ccombinaison dans la société absorbée
        dka_tools_pkg.get_code_combination_id(pv_segment1            => rec_ccid.segment1,
                                              pv_segment2            => rec_ccid.segment2,
                                              pv_segment3            => vv_new_segment3,
                                              pv_segment4            => vv_new_segment4,
                                              pv_segment5            => '0',
                                              pv_segment6            => '0',
                                              pv_segment7            => '0',
                                              pv_segment8            => '0',
                                              pv_segment9            => '0',
                                              pv_segment10           => '0',
                                              pv_segment11           => '0',
                                              pv_segment12           => '0',
                                              pn_code_combination_id => vn_orig_ccid,
                                              pv_errbuf              => v_errbuf,
                                              pn_retcode             => pn_codret,
                                              pv_validation_flag     => cv_enable);
      
        if nvl(vn_orig_ccid, 0) = 0 then
          -- probleme lors de la recherche du nouveau ccid
          message(pn_codret, v_errbuf);
          v_errbuf := 'Erreur lors de la recherche du ccid de la ligne de distribution - Cas3'; --SL
          message(pn_codret, v_errbuf);
          debug(pv_debug, v_errbuf);
          pn_codret := cn_warning;
          message(pn_codret,
                  'Compte comptable à  créer manuellement pour lignes produits');
          message(pn_codret,
                  vn_orig_ccid || '/' || rec_ccid.segment1 || '/' ||
                  rec_ccid.segment2 || '/' || vv_new_segment3 || '/' ||
                  vv_new_segment4 || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0' || '/' || '0');
          RETURN;
        end if;
      end if;
    end loop;
  
    debug(pv_debug, 'procédure init_nouveau_ccid : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || v_errbuf);
      message(pn_codret, 'Procédure init_nouveau_ccid : Fin en erreur');
      debug(pv_debug, 'erreur dans le controle des codes de TVA');
      debug(pv_debug, v_errbuf);
      pn_codret := cn_error;
  end init_nouveau_ccid;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : maj_nouveau_ccid
  --  Description   : procédure qui récuupère les CCID des sociétés absorbée
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure maj_nouveau_ccid(pn_codret IN OUT NUMBER,
                             pv_errbuf OUT VARCHAR2,
                             pv_debug  IN VARCHAR2) IS
  
    cursor c_ccid is
      select code_combination_id,
             segment1,
             segment2,
             segment3,
             segment4,
             segment5,
             segment6,
             segment7,
             segment8,
             segment9,
             segment10,
             segment11,
             segment12,
             enable_absorbee,
             old_start_date_active,
             old_end_date_active,
             account_class,
             line_type,
             societe_absorbante,
             new_combination_id,
             enable_absorbante,
             new_start_date_active,
             new_end_date_active
        from dka_ar_fusion_gcc_temp
         for update of new_combination_id, enable_absorbante, new_start_date_active, new_end_date_active, orig_combination_id;
  
    rec_ccid            c_ccid%rowtype;
    vn_new_ccid         gl_code_combinations.code_combination_id%type;
    vn_orig_ccid        gl_code_combinations.code_combination_id%type;
    vv_new_segment3     gl_code_combinations.segment3%type;
    vv_new_segment4     gl_code_combinations.segment4%type;
    vv_new_segment3_bis gl_code_combinations.segment3%type;
    vv_segment4         gl_code_combinations.segment4%type;
    v_errbuf            VARCHAR2(2500);
  begin
    debug(pv_debug, 'procédure init_nouveau_ccid : début');
    For rec_ccid in c_ccid loop
      if rec_ccid.account_class = cv_ligne_taxe or
         rec_ccid.account_class = cv_ligne_rec then
        -- vérification de la validité ddes valeurs dans les jeux de valeurs
        IF not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT1',
                             rec_ccid.segment1,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT2',
                             rec_ccid.segment2,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT3',
                             rec_ccid.segment3,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT4',
                             rec_ccid.segment4,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT5',
                             rec_ccid.segment5,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT6',
                             rec_ccid.segment6,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT7',
                             rec_ccid.segment7,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT8',
                             rec_ccid.segment8,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT9',
                             rec_ccid.segment9,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT10',
                             rec_ccid.segment10,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT11',
                             rec_ccid.segment11,
                             v_errbuf) OR
           not valeur_valide(pn_codret,
                             pv_debug,
                             'SEGMENT12',
                             rec_ccid.segment12,
                             v_errbuf) THEN
          pn_codret := cn_warning;
          --     RETURN;
        END IF;
        -- Controle de la validité de la ccombinaison dans la société absorbante
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(rec_ccid.societe_absorbante,
                                                                               4,
                                                                               4),
                                              pv_segment2            => rec_ccid.segment2,
                                              pv_segment3            => rec_ccid.segment3,
                                              pv_segment4            => rec_ccid.segment4,
                                              pv_segment5            => rec_ccid.segment5,
                                              pv_segment6            => rec_ccid.segment6,
                                              pv_segment7            => rec_ccid.segment7,
                                              pv_segment8            => rec_ccid.segment8,
                                              pv_segment9            => rec_ccid.segment9,
                                              pv_segment10           => rec_ccid.segment10,
                                              pv_segment11           => rec_ccid.segment11,
                                              pv_segment12           => rec_ccid.segment12,
                                              pn_code_combination_id => vn_new_ccid,
                                              pv_errbuf              => v_errbuf,
                                              pn_retcode             => pn_codret,
                                              pv_validation_flag     => cv_enable);
      
        if nvl(vn_new_ccid, 0) = 0 then
          -- probleme lors de la recherche du noouveau ccid
          message(pn_codret, v_errbuf);
          v_errbuf := 'Erreur lors de la recherche du ccid de la ligne de distribution - Cas1';
          message(pn_codret, v_errbuf);
          debug(pv_debug,
                'Erreur lors de la recherche du ccid de la ligne de distribution');
          debug(pv_debug, v_errbuf);
          pn_codret := cn_warning;
          --      RETURN;
        end if;
      
        if nvl(vn_new_ccid, 0) <> 0 then
          -- mise à  jour table temporaire avec le nouveau CCID
          update dka_ar_fusion_gcc_temp
             set new_combination_id    = vn_new_ccid,
                 orig_combination_id   = vn_orig_ccid,
                 enable_absorbante    =
                 (select enabled_flag
                    from gl_code_combinations
                   where code_combination_id = vn_new_ccid),
                 new_start_date_active =
                 (select start_date_active
                    from gl_code_combinations
                   where code_combination_id = vn_new_ccid),
                 new_end_date_active  =
                 (select start_date_active
                    from gl_code_combinations
                   where code_combination_id = vn_new_ccid)
           where current of c_ccid;
        end if;
      else
        -- = 'REV'
        valeur_generique(pn_codret,
                         pv_errbuf,
                         pv_debug,
                         rec_ccid.segment3,
                         rec_ccid.segment4,
                         vv_new_segment3,
                         vv_new_segment4,
                         vv_new_segment3_bis);
        if pn_codret = cn_error then
          debug(pv_debug,
                'Erreur dans la récupération des comptes local/groupe génériques.');
          RETURN;
        end if;
        if rec_ccid.line_type = 'CB' then
          vv_new_segment3 := vv_new_segment3_bis;
        end if;
        -- Controle de la validité de la ccombinaison dans la société absorbante
        dka_tools_pkg.get_code_combination_id(pv_segment1            => substr(rec_ccid.societe_absorbante,
                                                                               4,
                                                                               4),
                                              pv_segment2            => rec_ccid.segment2,
                                              pv_segment3            => vv_new_segment3,
                                              pv_segment4            => vv_new_segment4,
                                              pv_segment5            => '0',
                                              pv_segment6            => '0',
                                              pv_segment7            => '0',
                                              pv_segment8            => '0',
                                              pv_segment9            => '0',
                                              pv_segment10           => '0',
                                              pv_segment11           => '0',
                                              pv_segment12           => '0',
                                              pn_code_combination_id => vn_new_ccid,
                                              pv_errbuf              => v_errbuf,
                                              pn_retcode             => pn_codret,
                                              pv_validation_flag     => cv_enable);
        if nvl(vn_new_ccid, 0) = 0 then
          -- probleme lors de la recherche du noouveau ccid
          message(pn_codret, v_errbuf);
          v_errbuf := 'Erreur lors de la recherche du ccid de la ligne de distribution - Cas2';
          message(pn_codret, v_errbuf);
          debug(pv_debug, v_errbuf);
          pn_codret := cn_warning;
          --     RETURN;
        end if;
      
        -- Controle de la validité de la ccombinaison dans la société absorbée
        dka_tools_pkg.get_code_combination_id(pv_segment1            => rec_ccid.segment1,
                                              pv_segment2            => rec_ccid.segment2,
                                              pv_segment3            => vv_new_segment3,
                                              pv_segment4            => vv_new_segment4,
                                              pv_segment5            => '0',
                                              pv_segment6            => '0',
                                              pv_segment7            => '0',
                                              pv_segment8            => '0',
                                              pv_segment9            => '0',
                                              pv_segment10           => '0',
                                              pv_segment11           => '0',
                                              pv_segment12           => '0',
                                              pn_code_combination_id => vn_orig_ccid,
                                              pv_errbuf              => v_errbuf,
                                              pn_retcode             => pn_codret,
                                              pv_validation_flag     => cv_enable);
      
        if nvl(vn_orig_ccid, 0) = 0 then
          -- probleme lors de la recherche du noouveau ccid
          message(pn_codret, v_errbuf);
          v_errbuf := 'Erreur lors de la recherche du ccid de la ligne de distribution - Cas3'; --SL
          message(pn_codret, v_errbuf);
          debug(pv_debug, v_errbuf);
          pn_codret := cn_warning;
          --  RETURN;
        end if;
        if nvl(vn_orig_ccid, 0) <> 0 then
          -- mise à  jour table temporaire avec le nouveau CCID
          update dka_ar_fusion_gcc_temp
             set new_combination_id    = vn_new_ccid,
                 orig_combination_id   = vn_orig_ccid,
                 enable_absorbante    =
                 (select enabled_flag
                    from gl_code_combinations
                   where code_combination_id = vn_new_ccid),
                 new_start_date_active =
                 (select start_date_active
                    from gl_code_combinations
                   where code_combination_id = vn_new_ccid),
                 new_end_date_active  =
                 (select start_date_active
                    from gl_code_combinations
                   where code_combination_id = vn_new_ccid),
                 new_segment3          = vv_new_segment3,
                 new_segment4          = vv_new_segment4
           where current of c_ccid;
        end if;
      end if;
    end loop;
  
    debug(pv_debug, 'procédure maj_nouveau_ccid : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || v_errbuf);
      message(pn_codret, 'Procédure maj_nouveau_ccid : Fin en erreur');
      debug(pv_debug, v_errbuf);
      pn_codret := cn_error;
  end maj_nouveau_ccid;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : maj_ccid
  --  Description   : procédure qui valide les ccid des sociétés absorbée et absorbantes
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure maj_ccid(pn_codret IN OUT NUMBER,
                     pv_errbuf OUT VARCHAR2,
                     pv_debug  IN VARCHAR2) IS
  begin
    debug(pv_debug, 'procédure maj_ccid : début');
    --CCID sociétés absorbée
    update gl_code_combinations gcc
       set enabled_flag      = cv_enable,
           start_date_active = null,
           end_date_active   = null
     where exists
     (select null
              from dka_ar_fusion_gcc_temp dafft
             where --(
             gcc.code_combination_id = dafft.new_combination_id
          and decode(dafft.enable_absorbante,
                    cv_disable,
                    '1',
                    NVL(dafft.new_start_date_active,
                        dafft.new_end_date_active)) is not null);
    -- CCID société absorbante
    update gl_code_combinations gcc
       set enabled_flag      = cv_enable,
           start_date_active = null,
           end_date_active   = null
     where exists
     (select null
              from dka_ar_fusion_gcc_temp dafft
             where gcc.code_combination_id = dafft.code_combination_id
               and decode(dafft.enable_absorbee,
                          cv_disable,
                          '1',
                          NVL(dafft.old_start_date_active,
                              dafft.old_end_date_active)) is not null);
    debug(pv_debug, 'procédure maj_ccid : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure maj_ccid : Fin en erreur');
      debug(pv_debug, 'erreur dans l''activation des CCID');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end maj_ccid;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : combinaison
  --  Description   : procédure qui controle l'existence des combinaisons comptable dans la société absorbante
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure combinaison(pn_codret IN OUT NUMBER,
                        pv_errbuf OUT VARCHAR2,
                        pv_debug  IN VARCHAR2) IS
    nb_erreurs NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure combinaison : début');
    pn_codret := cn_ok;
    message(pn_codret, 'Controle de validité des valeurs de compte');
    creation_ccid(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_warning THEN
      debug(pv_debug, 'combinaison : Sortie après récupération des CCID');
      RETURN;
    END IF;
    init_nouveau_ccid(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_warning THEN
      debug(pv_debug, 'combinaison : Sortie après récupération des CCID');
      RETURN;
    END IF;
    message(pn_codret, 'Fin controle de validité des valeurs de compte');
    debug(pv_debug, 'procédure combinaison : fin');
  end combinaison;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : maj_fact_manuelle
  --  Description   : Etape à  effectuer à  la fin de l'étape 1 (après l'insertion
  --                  dans les tables de travail
  --
  --
  --  PARAMETRES    :
  --      pv_debug  IN VARCHAR2(1)    Indicateur de debug
  --  VALEUR RETOURNEE :
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  ---------------------------------------------------------------------------------------------------------------

  Procedure maj_fact_manuelle(pn_codret IN OUT NUMBER,
                              pv_errbuf OUT VARCHAR2,
                              pv_debug  IN VARCHAR2) IS
  
    vn_batch_source_id       ra_batch_sources_all.batch_source_id%TYPE;
    vn_batch_source_name     ra_batch_sources_all.name%TYPE;
    vn_new_batch_source_id   ra_batch_sources_all.batch_source_id%TYPE;
    vn_new_batch_source_name ra_batch_sources_all.name%TYPE;
    gv_name                  VARCHAR2(30) := 'FUSION';
    vv_status                VARCHAR2(10);
    nb_erreurs               NUMBER(15) := 0;
    Cursor Origine_Manuelle is --Recuperation des origines manuelles concernees par la fusion
      select distinct dafic.batch_source_id,
                      dafic.batch_source_name,
                      dafic.new_batch_source_name
        from DKA_AR_FUSION_INV_CTRL_TEMP dafic,
             ra_batch_sources_all        rbs,
             ra_batch_sources_all        rbs2
       where dafic.batch_source_id = rbs.batch_source_id
         and dafic.new_batch_source_name = rbs2.name
         and (rbs.batch_source_type = 'INV' or
             rbs2.batch_source_type = 'INV');
  
  Begin
    -- Verification de l'existance des origines de type Import
    --           si ce n'est pas le cas, il faut les créer
    debug(pv_debug, 'procédure maj_fact_manuelle : début');
    message(pn_codret, 'Controle origines de mouvement');
    pn_codret := cn_ok;
  
    For rec_origine in Origine_Manuelle loop
      begin
        select rbs.batch_source_id, rbs.name, rbs.status
          into vn_batch_source_id, vn_batch_source_name, vv_status
          from ra_batch_sources_all rbs
         where 1 = 1
           and rbs.name = rec_origine.batch_source_name || '_' || gv_name
           and rbs.batch_source_type = 'FOREIGN'
        -- and    rbs.status = 'A'
        ;
      
        IF vv_status != 'A' THEN
          debug(pv_debug,
                'L''origine ' || rec_origine.batch_source_name || '_' ||
                gv_name || ' doit àªtre réactivée');
          pn_codret := cn_ctrl_ko;
        END IF;
      
      exception
        when others then
          pn_codret := cn_ctrl_ko;
      end;
    
      begin
        select rbs.batch_source_id, rbs.name, rbs.status
          into vn_new_batch_source_id, vn_new_batch_source_name, vv_status
          from ra_batch_sources_all rbs
         where 1 = 1
           and rbs.name =
               rec_origine.new_batch_source_name || '_' || gv_name
           and rbs.batch_source_type = 'FOREIGN'
        --  and    rbs.status = 'A'
        
        ;
      
        IF vv_status != 'A' THEN
          debug(pv_debug,
                '!!!! L''origine ' || rec_origine.batch_source_name || '_' ||
                gv_name || ' doit àªtre réactivée');
          pn_codret := cn_ctrl_ko;
        END IF;
      exception
        when others then
          debug(pv_debug,
                'Origine Importé inexistante ou desactivée : ' ||
                rec_origine.new_batch_source_name || '_' || gv_name);
        
      end;
    
      update DKA_AR_FUSION_INV_CTRL_TEMP dafic1
         set dafic1.batch_source_id       = nvl(vn_batch_source_id,
                                                dafic1.batch_source_id),
             dafic1.batch_source_name     = nvl(vn_batch_source_name,
                                                dafic1.batch_source_name),
             dafic1.new_batch_source_name = nvl(vn_new_batch_source_name,
                                                dafic1.new_batch_source_name)
       where 1 = 1
         and (dafic1.batch_source_name = rec_origine.batch_source_name or
             dafic1.new_batch_source_name =
             rec_origine.new_batch_source_name);
    
    End loop;
    message(pn_codret, 'Fin controle origines de mouvement');
    debug(pv_debug, 'procédure maj_fact_manuelle : fin');
  exception
    when others then
      pn_codret := cn_ctrl_ko;
      pv_errbuf := SQLERRM;
      message(pn_codret, pv_errbuf);
  end maj_fact_manuelle;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : verif_reliquat
  --  Description   : Etape à  effectuer à  la fin de l'étape 1 (après l'insertion
  --                  dans les tables de travail
  --
  --
  --  PARAMETRES    :
  --      pv_debug  IN VARCHAR2(1)    Indicateur de debug
  --  VALEUR RETOURNEE :
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  ---------------------------------------------------------------------------------------------------------------

  Procedure verif_reliquat(pn_codret IN OUT NUMBER,
                           pv_errbuf OUT VARCHAR2,
                           pv_debug  IN VARCHAR2) IS
  
    cursor cur_reliquat IS
      SELECT trx_number
        FROM DKA_AR_FUSION_INV_CTRL_TEMP daic
       WHERE 1 = 1
         AND line_type = 'CB';
  
    rec_reliquat cur_reliquat%ROWTYPE;
    nb_erreurs   NUMBER(15) := 0;
  
  Begin
    -- Verification de l'existence de reliquat à  reprendre
    message(pn_codret, 'Controle reliquats');
    debug(pv_debug, 'procédure verif_reliquat : début');
    OPEN cur_reliquat;
    LOOP
      FETCH cur_reliquat
        INTO rec_reliquat;
      EXIT WHEN cur_reliquat%NOTFOUND;
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Présence de reliquat sur : ' ||
                    rec_reliquat.trx_number;
      nb_erreurs := nb_erreurs + 1;
      message(pn_codret, pv_errbuf);
    END LOOP;
    close cur_reliquat;
    message(pn_codret, 'Nombre de reliquats : ' || nb_erreurs);
    message(pn_codret, 'Fin controle présence de reliquats');
    debug(pv_debug, 'procédure verif_reliquat : fin');
  exception
    when others then
      pv_errbuf := SQLERRM;
      message(pn_codret, 'Erreur : ' || pv_errbuf);
  end verif_reliquat;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : encaissement
  --  Description   : procédure qui identifie les encaissements clients non lettrés avec un montant initial à  O
  --                  et un solde restant dà» non nul
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure encaissement(pn_codret IN OUT NUMBER,
                         pv_errbuf OUT VARCHAR2,
                         pv_debug  IN VARCHAR2) IS
    --
    cursor c_encaissement is
      select distinct dafrct.receipt_number num_encaissement
        from dka_ar_fusion_rec_ctrl_temp    dafrct,
             ar_receivable_applications_all araa
       where dafrct.customer_trx_id = araa.customer_trx_id
         and araa.status = cv_ARAA_status_unapplied
         and dafrct.amount != dafrct.amount_applied
         and dafrct.amount = 0;
    rec_encaissement c_encaissement%rowtype;
    nb_erreurs       NUMBER(15) := 0;
  begin
    debug(pv_debug, 'procédure encaissement : début');
    message(pn_codret, 'Controle encaissements');
    pn_codret := cn_ok;
    for rec_encaissement in c_encaissement loop
      pn_codret  := cn_ctrl_ko;
      pv_errbuf  := 'Encaissement client non lettré avec solde restant non nul' ||
                    rec_encaissement.num_encaissement;
      nb_erreurs := nb_erreurs + 1;
      message(pn_codret, pv_errbuf);
    end loop;
    if pn_codret = cn_ctrl_ko then
      debug(pv_debug,
            'Des encaissements clients non lettrés ont un solde restant non nul');
    end if;
    message(pn_codret,
            'Nombre d''encaissements clients non lettrés avec solde restant non nul : ' ||
            nb_erreurs);
    message(pn_codret, 'Fin controle encaissements');
    debug(pv_debug, 'procédure encaissement : fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure encaissement : Fin en erreur');
      debug(pv_debug,
            'erreur dans le controle des prélèvements de lUO absorbée');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end encaissement;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : reglt_part
  --  Description   : procédure qui identifie les règlements partiellement lettrés dans les UO absorbées
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure reglt_part(pn_codret IN OUT NUMBER,
                       pv_errbuf OUT VARCHAR2,
                       pv_debug  IN VARCHAR2) IS
    cursor c_reglt_part is
    /*      select dafrct.receipt_number       num_reglement,
                                                                     dafrct.receipt_method_id    mode_reglement,
                                                                     arm.name                    nom_reglement,
                                                                     dafrct.societe_absorbee     UO,
                                                                     dafrct.customer_site_use_id site_client,
                                                                     dafrct.amount               montant,
                                                                     dafrct.amount_applied       montant_lettre
                                                                from dka_ar_fusion_rec_ctrl_temp dafrct, ar_receipt_methods arm
                                                               where dafrct.amount_applied > 0
                                                                 and dafrct.amount != dafrct.amount_applied
                                                                 and dafrct.receipt_method_id = arm.receipt_method_id;
                                                        */
      select dafrct.receipt_number num_reglement,
             dafrct.cash_receipt_id,
             --dafrct.receipt_method_id mode_reglement,
             arm.name mode_reglement,
             dafrct.societe_absorbee UO,
             dafrct.customer_site_use_id site_client,
             dafrct.amount montant,
             dafrct.amount_applied montant_lettre,
             count(araa.status)
        from dka_ar_fusion_rec_ctrl_temp    dafrct,
             ar_receipt_methods             arm,
             ar_receivable_applications_all araa
       where araa.CASH_RECEIPT_ID = dafrct.CASH_RECEIPT_ID
         and araa.display = 'Y'
         and dafrct.receipt_method_id = arm.receipt_method_id
       group by dafrct.receipt_number,
                dafrct.cash_receipt_id,
                dafrct.receipt_method_id,
                arm.name,
                dafrct.societe_absorbee,
                dafrct.customer_site_use_id,
                dafrct.amount,
                dafrct.amount_applied
      having count(distinct araa.status) > 1;
  
    cursor c_reglt_detail(pn_cash_receipt_id NUMBER) is
      select araa.cash_receipt_id,
             araa.status,
             sum(araa.amount_applied) montant
        from ar_receivable_applications_all araa
       where araa.CASH_RECEIPT_ID = pn_cash_receipt_id
       group by araa.cash_receipt_id, araa.status;
  
    cursor c_reglt_registre is
      SELECT dafrct.receipt_number num_reglement,
             dafrct.cash_receipt_id,
             arm.name mode_reglement,
             dafrct.societe_absorbee UO,
             dafrct.customer_site_use_id site_client,
             dafrct.amount montant,
             sum(decode(app.status, 'ACC', app.acctd_amount_applied_from, 0)) on_account_amt_app,
             sum(decode(app.status,
                        'UNAPP',
                        app.acctd_amount_applied_from,
                        0)) unapplied_amt_app
        FROM dka_ar_fusion_rec_ctrl_temp    dafrct,
             ar_receipt_methods             arm,
             ar_receivable_applications_all app
       WHERE dafrct.receipt_method_id = arm.receipt_method_id
         AND app.status in ('ACC', 'UNAPP')
         AND dafrct.cash_receipt_id = app.cash_receipt_id
         AND nvl(app.confirmed_flag, 'Y') = 'Y'
       GROUP BY arm.name,
                dafrct.receipt_number,
                dafrct.cash_receipt_id,
                dafrct.societe_absorbee,
                dafrct.customer_site_use_id,
                dafrct.amount
      having sum(decode(app.status, 'ACC', app.acctd_amount_applied_from, 0)) != 0 or sum(decode(app.status, 'UNAPP', app.acctd_amount_applied_from, 0)) != 0;
    rec_reglt_registre   c_reglt_registre%rowtype;
    rec_reglt_part       c_reglt_part%rowtype;
    rec_reglt_detail     c_reglt_detail%rowtype;
    nb_erreurs           NUMBER(15) := 0;
    pn_montant_compte    NUMBER(15, 2) := 0;
    pn_montant_lettre    NUMBER(15, 2) := 0;
    pn_montant_unid      NUMBER(15, 2) := 0;
    pn_montant_unapplied NUMBER(15, 2) := 0;
  
  begin
    debug(pv_debug, 'procédure rglt_part : début');
    message(pn_codret, 'Controle règlements partiels');
    pn_codret := cn_ok;
    for rec_reglt_part in c_reglt_part loop
      pn_codret := cn_ctrl_ko;
      if nb_erreurs = 0 then
        pv_errbuf := 'Numero reglement/Mode_reglement/UO/site_client/montant/montant_lettre/Montant en compte/Montant non identifié/Montant non lettré';
        message(pn_codret, pv_errbuf);
      end if;
    
      for rec_reglt_detail in c_reglt_detail(rec_reglt_part.cash_receipt_id) loop
        iF rec_reglt_detail.status = cv_ARAA_status_encom then
          pn_montant_compte := rec_reglt_detail.montant;
        ELSIF rec_reglt_detail.status = cv_ARAA_status_applied then
          pn_montant_lettre := rec_reglt_detail.montant;
        ELSIF rec_reglt_detail.status = cv_ARAA_status_unid then
        
          pn_montant_unid := rec_reglt_detail.montant;
        ELsIF rec_reglt_detail.status = cv_ARAA_status_unapplied then
          pn_montant_unapplied := rec_reglt_detail.montant;
        
        end if;
      end loop;
    
      pv_errbuf := rec_reglt_part.num_reglement || '/' ||
                   rec_reglt_part.mode_reglement || '/' ||
                   rec_reglt_part.UO || '/' || rec_reglt_part.site_client || '/' ||
                   rec_reglt_part.montant || '/' || pn_montant_lettre || '/' ||
                   pn_montant_compte || '/' || pn_montant_unid || '/' ||
                   pn_montant_unapplied;
      message(pn_codret, pv_errbuf);
      nb_erreurs := nb_erreurs + 1;
    end loop;
    message(pn_codret,
            'Nombre de règlements partiels existant dans les UO absorbées : ' ||
            nb_erreurs);
    message(pn_codret, 'Fin controle règlements partiels');
    if pn_codret = cn_ctrl_ko then
      debug(pv_debug,
            'Des règlements partiellement lettrés existent dans les UO absorbées');
    end if;
    nb_erreurs := 0;
    for rec_reglt_registre in c_reglt_registre loop
      if nb_erreurs = 0 then
        pv_errbuf := 'Liste des règlements partiels selon l''état registre des règlements non lettrés';
        message(pn_codret, pv_errbuf);
        pv_errbuf := 'Numero reglement/Mode_reglement/UO/site_client/montant/montant_lettre/Montant en compte/Montant non identifié/Montant non lettré';
        message(pn_codret, pv_errbuf);
      end if;
    
      for rec_reglt_detail in c_reglt_detail(rec_reglt_registre.cash_receipt_id) loop
        iF rec_reglt_detail.status = cv_ARAA_status_encom then
          pn_montant_compte := rec_reglt_detail.montant;
        ELSIF rec_reglt_detail.status = cv_ARAA_status_applied then
          pn_montant_lettre := rec_reglt_detail.montant;
        ELSIF rec_reglt_detail.status = cv_ARAA_status_unid then
        
          pn_montant_unid := rec_reglt_detail.montant;
        ELsIF rec_reglt_detail.status = cv_ARAA_status_unapplied then
          pn_montant_unapplied := rec_reglt_detail.montant;
        
        end if;
      end loop;
      pv_errbuf := rec_reglt_registre.num_reglement || '/' ||
                   rec_reglt_registre.mode_reglement || '/' ||
                   rec_reglt_registre.UO || '/' ||
                   rec_reglt_registre.site_client || '/' ||
                   rec_reglt_registre.montant || '/' || pn_montant_lettre || '/' ||
                   rec_reglt_registre.on_account_amt_app || '/' ||
                   pn_montant_unid || '/' ||
                   rec_reglt_registre.unapplied_amt_app;
      message(pn_codret, pv_errbuf);
      nb_erreurs := nb_erreurs + 1;
    end loop;
    message(pn_codret,
            'Nombre de règlements partiels existant dans les UO absorbées : ' ||
            nb_erreurs);
    debug(pv_debug, 'procédure rglt_part : fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure reglt_part : Fin en erreur');
      debug(pv_debug,
            'erreur dans le controle des prélèvements de lUO absorbée');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end reglt_part;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : controle
  --  Description   : procédure qui effectue les controles avant d'effectuer la fusion
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure controle(pn_codret IN OUT NUMBER,
                     pv_errbuf OUT VARCHAR2,
                     pv_debug  IN VARCHAR2) IS
    vb_ctrl_ko BOOLEAN := FALSE;
  begin
    debug(pv_debug, 'procédure controle : début');
    --RG2 : Controle de l'existence des banques
    existence_banque(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après controle banque');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    --RG9 : Controle de l'existence des modes de règlement
    mode_reglement(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après controle mode de réglement');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG6 Controle de l'existence des catégories de séquence
    categories(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après controle categories');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG6 Controle de l'existence de séquences manuelles et automatiques
    sequences(pn_codret, pv_errbuf, pv_debug);
    -- Rq : le code retour "cn_ctrl_ko" permet d'enchaà®ner tous les controles avant de sortir
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après controle sequences');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG5 : Controle de l'existence des types de mouvements
    type_mvt(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug,
            'controle : Sortie après controle des types de mouvement');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG7 Controle d'existence des origines de mouvements
    origine_mvt(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après controle des origine');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- Controle d'existence des codes de TVA
    code_tva(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après controle des codes TVA');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG10 + RG18 : Controle de validité des valeurs de compte
    -- edition à  faire
    combinaison(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après controle des CCID');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG13 : Vérification des origines de type importé
    maj_fact_manuelle(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après maj factures manuelles');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG12 : Vérification de l'existence de reliquats
    verif_reliquat(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après verif reliquats');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG11 : Vérif sites clients
    sites_clients(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après verif sites clients');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    --   RG14 : Tout prélèvement de l'UO absorbée est remis en banque
    prelevement(pn_codret, pv_errbuf, pv_debug);
    if pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après vérif prélèvements');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    --   RG15 : Controle sur les mouvements en cours sur l'absorbee avec l'absorbante
    absorbee_absorbante(pn_codret, pv_errbuf, pv_debug);
    if pn_codret = cn_error then
      debug(pv_debug,
            'controle : sortie après verif mouvements absorbee vers absorbante');
      RETURN;
    elsif pn_codret = cn_ctrl_ko then
      vb_ctrl_ko := true;
    end if;
  
    --   RG16 : Controle sur les encaissements clients
    encaissement(pn_codret, pv_errbuf, pv_debug);
    if pn_codret = cn_error then
      debug(pv_debug, 'Controle : sortie après verif encaissement');
      return;
    elsif pn_codret = cn_ctrl_ko then
      vb_ctrl_ko := TRUE;
    end if;
    --   RG17 : Controle sur les règlements partiellement lettrés
    reglt_part(pn_codret, pv_errbuf, pv_debug);
    if pn_codret = cn_error then
      debug(pv_debug,
            'Controle : sortie après verif règlements partiellement lettrés');
      return;
    elsif pn_codret = cn_ctrl_ko then
      vb_ctrl_ko := TRUE;
    end if;
  
    Site_Clients_Absorbante(pn_codret, pv_errbuf, pv_debug);
    if pn_codret = cn_error then
      debug(pv_debug, 'Controle : sortie après verif Site client manquant');
      return;
    elsif pn_codret = cn_ctrl_ko then
      vb_ctrl_ko := TRUE;
    end if;
  
    IF vb_ctrl_ko THEN
      pn_codret := cn_warning;
    END IF;
  
    debug(pv_debug, 'procédure controle : fin');
  end controle;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : conv_reliquats
  --  Description   : Conversion de reliquats
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure conv_reliquats(pn_codret IN OUT NUMBER,
                           pv_errbuf OUT VARCHAR2,
                           pv_debug  IN VARCHAR2) IS
    cursor cur_reliquat IS
      SELECT trx_number
        FROM DKA_AR_FUSION_INV_CTRL_TEMP dafic
       WHERE 1 = 1
         AND line_type = 'CB';
    rec_reliquat cur_reliquat%ROWTYPE;
  begin
    debug(pv_debug, 'procédure conv_reliquats : début');
    pn_codret := cn_ok;
    OPEN cur_reliquat;
    LOOP
      FETCH cur_reliquat
        INTO rec_reliquat;
      EXIT WHEN cur_reliquat%NOTFOUND;
      update DKA_AR_FUSION_INV_CTRL_TEMP
         set line_type = 'LINE'
       where trx_number = rec_reliquat.trx_number
         and line_type = 'CB';
    END LOOP;
    close cur_reliquat;
    debug(pv_debug, 'procédure conv_reliquats : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure conv_reliquats : Fin en erreur');
      debug(pv_debug, 'erreur dans conv_reliquats');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end conv_reliquats;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : maj_montant
  --  Description   : mise à  jour des montants pour les factures partiellement réglées dont le règlement
  --                concerne plusieurs factures
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure maj_montant(pn_codret IN OUT NUMBER,
                        pv_errbuf OUT VARCHAR2,
                        pv_debug  IN VARCHAR2) IS
  
  begin
    debug(pv_debug, 'procédure maj_montant : début');
    pn_codret := cn_ok;
  
    UPDATE DKA_AR_FUSION_INV_CTRL_TEMP dafict
       SET dafict.customer_trx_amount =
           (SELECT decode(dafict.line_type,
                          'REC',
                          apsa.amount_due_remaining,
                          round(dafict1.amount * (apsa.amount_due_remaining /
                                apsa.amount_due_original),
                                2))
              FROM dka_ar_fusion_inv_ctrl_temp dafict1,
                   ar_payment_schedules_all    apsa
             WHERE dafict.customer_trx_id = dafict1.customer_trx_id
               AND dafict.customer_trx_line_id =
                   dafict1.customer_trx_line_id
               AND dafict1.line_type = dafict.line_type
               AND dafict1.customer_trx_id = apsa.customer_trx_id)
     WHERE dafict.customer_trx_id In
           (SELECT distinct dafict.customer_trx_id
              FROM dka_ar_fusion_inv_ctrl_temp dafict,
                   ar_payment_schedules_all    apsa
             WHERE apsa.amount_due_original <> apsa.amount_due_remaining
               AND dafict.customer_trx_id = apsa.customer_trx_id
               AND apsa.status <> 'CL');
  
    debug(pv_debug, 'procédure maj_montant : fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure maj_montant : Fin en erreur');
      debug(pv_debug, 'erreur dans l''activation des CCID');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end maj_montant;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : conv_avoir_facture
  --  Description   : Conversion des avoirs en facture et inversement
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure conv_avoir_facture(pn_codret IN OUT NUMBER,
                               pv_errbuf OUT VARCHAR2,
                               pv_debug  IN VARCHAR2) IS
  begin
    debug(pv_debug, 'procédure conv_avoir_facture : début');
    pn_codret := cn_ok;
  
    UPDATE DKA_AR_FUSION_INV_CTRL_TEMP dafict
       SET cancel_trx_type_id =
           (SELECT rctta.cust_trx_type_id
              FROM ra_cust_trx_types_all     rctta,
                   hr_all_organization_units houa
             WHERE rctta.ORG_ID = houa.organization_id
               and houa.name = dafict.SOCIETE_ABSORBEE
               and rctta.name =
                   (select dsl.return_value
                      from dka_stransco_lines dsl, dka_stransco_headers dsh
                     where dsh.set_name = cv_fusion_type_mouvement
                       AND dsl.set_id = dsh.set_id
                       and dsl.param1_value = dafict.cust_trx_type_name));
  
    debug(pv_debug, 'procédure conv_avoir_facture : fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure conv_avoir_facture : Fin en erreur');
      debug(pv_debug,
            'Erreur dans la récupération des types de factures pour l''anullation dans la société aborbée');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end conv_avoir_facture;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insertion_facture
  --  Description   : Insertion des factures/avoir
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure insertion_facture(pn_codret IN OUT NUMBER,
                              pv_errbuf OUT VARCHAR2,
                              pv_debug  IN VARCHAR2) IS
  
    v_errbuf   VARCHAR2(2500);
    vv_date_gl VARCHAR2(12);
  begin
    debug(pv_debug, 'procédure insertion_facture : début');
    pn_codret := cn_ok;
  
    -- Mise à  jour des montants pour les factures partiellement réglées
    maj_montant(pn_codret, v_errbuf, pv_debug);
    if pn_codret <> cn_ok THEN
      debug(pv_debug, 'insertion : Sortie après insertion facture/avoir');
      RETURN;
    END IF;
    -- Conversion des mouvements reliquats en mouvement de type facture
    conv_reliquats(pn_codret, v_errbuf, pv_debug);
    if pn_codret <> cn_ok THEN
      debug(pv_debug, 'conversion reliquats : sortie');
      RETURN;
    end if;
    -- pour sociétés absorbées, conversion des avoirs en facture et inversement
    conv_avoir_facture(pn_codret, v_errbuf, pv_debug);
    if pn_codret <> cn_ok THEN
      debug(pv_debug, 'insertion : Sortie après insertion facture/avoir');
      RETURN;
    END IF;
    -- mise à  jour des combinaisons comptables
    maj_nouveau_ccid(pn_codret, v_errbuf, pv_debug);
    if pn_codret <> cn_ok THEN
      debug(pv_debug, 'maj_nouveau_ccid fin');
      RETURN;
    END IF;
  
    DECLARE
      CURSOR cur_date_gl IS
        SELECT distinct trx_date FROM dka_ar_fusion_inv_ctrl_temp;
    
      rec_date_gl       cur_date_gl%ROWTYPE;
      vv_period_name    VARCHAR2(10);
      vv_closing_status VARCHAR2(5);
    
    BEGIN
      OPEN cur_date_gl;
      LOOP
        FETCH cur_date_gl
          INTO rec_date_gl;
        EXIT WHEN cur_date_gl%NOTFOUND;
      
        SELECT DISTINCT PERIOD_NAME, closing_status
          INTO vv_period_name, vv_closing_status
          FROM gl_period_statuses gps, gl_ledgers gll
         WHERE gps.application_id = 222
              -- AND closing_status = 'O'
           and rec_date_gl.trx_date between gps.START_DATE and gps.end_date
           AND gps.ledger_id = gll.ledger_id
           AND gll.ledger_category_code = 'PRIMARY';
      
        IF vv_closing_status <> 'O' THEN
          SELECT DISTINCT max(gps.START_DATE)
            INTO vv_date_gl
            FROM gl_period_statuses gps, gl_ledgers gll
           WHERE gps.application_id = 222
             AND closing_status = 'O'
             AND gps.ledger_id = gll.ledger_id
             AND gll.ledger_category_code = 'PRIMARY';
        
        END IF;
      
      END LOOP;
      CLOSE cur_date_gl;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_errbuf := SQLERRM;
        message(pn_codret, 'ERROR : ' || v_errbuf);
        message(pn_codret,
                'Aucune période AR trouvé pour la date de fusion : La date GL sera la date de début de la première période ouverte');
        SELECT DISTINCT max(gps.START_DATE)
          INTO vv_date_gl
          FROM gl_period_statuses gps, gl_ledgers gll
         WHERE gps.application_id = 222
           AND closing_status = 'O'
           AND gps.ledger_id = gll.ledger_id
           AND gll.ledger_category_code = 'PRIMARY'
           and rownum = 1;
      
      WHEN TOO_MANY_ROWS THEN
        v_errbuf := SQLERRM;
        message(pn_codret, 'ERROR : ' || v_errbuf);
        message(pn_codret,
                'Plusieurs périodes AR ouverte : La date GL sera la date de début de la première période ouverte');
        SELECT DISTINCT max(gps.START_DATE)
          INTO vv_date_gl
          FROM gl_period_statuses gps, gl_ledgers gll
         WHERE gps.application_id = 222
           AND closing_status = 'O'
           AND gps.ledger_id = gll.ledger_id
           AND gll.ledger_category_code = 'PRIMARY'
           and rownum = 1;
    END;
  
    INSERT INTO ra_interface_lines_all
      (interface_line_context,
       interface_line_attribute1,
       interface_line_attribute2,
       interface_line_attribute3,
       interface_line_attribute4,
       interface_line_attribute5,
       batch_source_name,
       line_type,
       description,
       currency_code,
       conversion_type,
       conversion_rate,
       amount,
       cust_trx_type_id,
       cust_trx_type_name,
       term_id,
       orig_system_bill_customer_id,
       orig_system_bill_address_id,
       link_to_line_context,
       link_to_line_attribute1,
       link_to_line_attribute2,
       link_to_line_attribute3,
       link_to_line_attribute4,
       link_to_line_attribute5,
       trx_date,
       gl_date,
       trx_number,
       tax_code,
       tax_rate_code,
       org_id,
       line_number,
       header_attribute_category,
       header_attribute1,
       header_attribute2,
       header_attribute3,
       header_attribute4)
      select -- pour société absorbante / on alimente avec les montants non soldés pour la recréation des mouvements non soldés
       cv_interface_line_context,
       dafict.new_cust_trx_type_name,
       substr(dafict.societe_absorbante, 4, 4),
       ltrim(substr(lpad(dafict.societe_absorbee || '_' ||
                         dafict.interface_line_attribute3,
                         240,
                         ' '),
                    -30)) --08/02/2007
      ,
       dafict.trx_date,
       dafict.interface_line_attribute4,
       
       'FUSION',
       dafict.line_type,
       dafict.description,
       dafict.invoice_currency_code,
       dafict.exchange_rate_type,
       dafict.exchange_rate,
       dafict.customer_trx_amount,
       case
         when dafict.new_cust_trx_type_name like 'DOUTEUX%' THEN
          null
         else
          dafict.new_cust_trx_type_id
       end,
       case
         when dafict.new_cust_trx_type_name like 'DOUTEUX%' THEN
          'SI_AMT_FACTURE'
         ELSE
          dafict.new_cust_trx_type_name
       end,
       dafict.term_id,
       dafict.bill_to_customer_id,
       dafict.new_bill_to_site_use_id,
       decode(dafict.line_type, 'TAX', cv_interface_line_context, Null),
       decode(dafict.line_type, 'TAX', dafict.new_cust_trx_type_name, Null),
       decode(dafict.line_type,
              'TAX',
              substr(dafict.societe_absorbante, 4, 4),
              Null),
       decode(dafict.line_type,
              'TAX',
              ltrim(substr(lpad(dafict.societe_absorbee || '_' ||
                                dafict.link_to_line_attribute3,
                                240,
                                ' '),
                           -30)),
              Null) -- 08/02/2007
      ,
       decode(dafict.line_type, 'TAX', dafict.trx_date, Null),
       decode(dafict.line_type, 'TAX', dafict.link_to_line_attribute4, Null),
       
       dafict.trx_date,
       nvl(to_date(vv_date_gl, 'DD/MM/YY'), dafict.trx_date),
       ltrim(substr(lpad(dafict.societe_absorbee || '_' ||
                         dafict.trx_number,
                         240,
                         ' '),
                    -20)) --08/02/2007
      ,
       decode(dafict.line_type, 'TAX', dafict.tax_code, Null),
       decode(dafict.line_type, 'TAX', dafict.tax_code, Null),
       org_id_absorbante,
       dafict.interface_line_attribute4,
       'FACTURATION',
       dafict.new_cust_trx_type_name,
       substr(dafict.societe_absorbante, 4, 4),
       ltrim(substr(lpad(dafict.societe_absorbee || '_' ||
                         dafict.interface_line_attribute3,
                         240,
                         ' '),
                    -30)),
       1
        from dka_ar_fusion_inv_ctrl_temp dafict, hz_cust_site_uses_all hcsu
       where dafict.bill_to_site_use_id = hcsu.site_use_id
         and dafict.line_type IN ('TAX', 'LINE')
      Union
      select -- Pour société absorbée / on alimente avec les données inverses pour leur annulation
       cv_interface_line_context,
       dafict.new_cust_trx_type_name,
       substr(dafict.societe_absorbee, 4, 4),
       ltrim(substr(lpad(dafict.societe_absorbante || '_' ||
                         dafict.interface_line_attribute3,
                         240,
                         ' '),
                    -30)),
       dafict.trx_date,
       dafict.interface_line_attribute4,
       
       'FUSION',
       dafict.line_type,
       dafict.description,
       dafict.invoice_currency_code,
       dafict.exchange_rate_type,
       dafict.exchange_rate,
       -1 * dafict.customer_trx_amount,
       dafict.cancel_trx_type_id,
       (select rctta.name
          from ra_cust_trx_types_all rctta
         where rctta.CUST_TRX_TYPE_ID = dafict.cancel_trx_type_id),
       dafict.term_id,
       dafict.bill_to_customer_id,
       hcsu.cust_acct_site_id,
       decode(dafict.line_type, 'TAX', cv_interface_line_context, Null),
       decode(dafict.line_type, 'TAX', dafict.new_cust_trx_type_name, Null),
       decode(dafict.line_type,
              'TAX',
              substr(dafict.societe_absorbee, 4, 4),
              Null),
       decode(dafict.line_type,
              'TAX',
              ltrim(substr(lpad(dafict.societe_absorbante || '_' ||
                                dafict.link_to_line_attribute3,
                                240,
                                ' '),
                           -30)),
              Null),
       decode(dafict.line_type, 'TAX', dafict.trx_date, Null),
       decode(dafict.line_type, 'TAX', dafict.link_to_line_attribute4, Null),
       
       dafict.trx_date,
       nvl(to_date(vv_date_gl, 'DD/MM/YY'), dafict.trx_date),
       ltrim(substr(lpad(dafict.societe_absorbante || '_' ||
                         dafict.trx_number,
                         240,
                         ' '),
                    -20)),
       decode(dafict.line_type, 'TAX', dafict.tax_code, Null),
       decode(dafict.line_type, 'TAX', dafict.tax_code, Null),
       org_id_absorbee,
       dafict.interface_line_attribute4,
       'FACTURATION',
       dafict.new_cust_trx_type_name,
       substr(dafict.societe_absorbee, 4, 4),
       ltrim(substr(lpad(dafict.societe_absorbante || '_' ||
                         dafict.interface_line_attribute3,
                         240,
                         ' '),
                    -30)),
       1
        from dka_ar_fusion_inv_ctrl_temp dafict, hz_cust_site_uses_all hcsu
       where dafict.bill_to_site_use_id = hcsu.site_use_id
         and dafict.line_type IN ('TAX', 'LINE');
  
    DECLARE
      CURSOR cur_dist IS
        SELECT dafict.interface_line_attribute1,
               dafict.interface_line_attribute2,
               dafict.interface_line_attribute3,
               dafict.interface_line_attribute4,
               dafict.interface_line_attribute5,
               dafict.new_cust_trx_type_name,
               dafict.trx_date,
               dafict.tax_code,
               dafict.account_class,
               dafict.amount,
               dafict.percent,
               dafgt.segment1,
               dafgt.segment2,
               dafgt.segment3,
               dafgt.segment4,
               dafgt.segment5,
               dafgt.segment6,
               dafgt.segment7,
               dafgt.segment8,
               dafgt.segment9,
               dafgt.segment10,
               dafgt.segment11,
               dafgt.segment12,
               dafgt.new_segment3,
               dafgt.new_segment4,
               dafict.societe_absorbee,
               dafict.societe_absorbante,
               dafict.ORG_ID_ABSORBEE,
               dafict.ORG_ID_ABSORBANTE,
               dafgt2.segment1                  collected_seg1,
               dafgt2.segment2                  collected_seg2,
               dafgt2.segment3                  collected_seg3,
               dafgt2.segment4                  collected_seg4,
               dafgt2.segment5                  collected_seg5,
               dafgt2.segment6                  collected_seg6,
               dafgt2.segment7                  collected_seg7,
               dafgt2.segment8                  collected_seg8,
               dafgt2.segment9                  collected_seg9,
               dafgt2.segment10                 collected_seg10,
               dafgt2.segment11                 collected_seg11,
               dafgt2.segment12                 collected_seg12,
               dafgt2.new_segment3              collected_new_segment3,
               dafgt2.new_segment4              collected_new_segment4
          FROM dka_ar_fusion_inv_ctrl_temp dafict,
               dka_ar_fusion_gcc_temp      dafgt,
               dka_ar_fusion_gcc_temp      dafgt2
         WHERE dafgt.code_combination_id = dafict.code_combination_id
           AND dafgt.account_class = dafict.account_class
           AND dafgt2.code_combination_id(+) = dafict.collected_tax_ccid
           AND dafgt2.line_type(+) = dafict.account_class
           and dafict.account_class <> 'REC';
    
      vc_segment1              ra_interface_distributions_all.segment1%TYPE;
      vc_segment2              ra_interface_distributions_all.segment2%TYPE;
      vc_segment3              ra_interface_distributions_all.segment3%TYPE;
      vc_segment4              ra_interface_distributions_all.segment4%TYPE;
      vc_segment5              ra_interface_distributions_all.segment5%TYPE;
      vc_segment6              ra_interface_distributions_all.segment6%TYPE;
      vc_segment7              ra_interface_distributions_all.segment7%TYPE;
      vc_segment8              ra_interface_distributions_all.segment8%TYPE;
      vc_segment9              ra_interface_distributions_all.segment9%TYPE;
      vc_segment10             ra_interface_distributions_all.segment10%TYPE;
      vc_segment11             ra_interface_distributions_all.segment11%TYPE;
      vc_segment12             ra_interface_distributions_all.segment12%TYPE;
      vc_interim_tax_segment1  ra_interface_distributions_all.interim_tax_segment1%TYPE;
      vc_interim_tax_segment2  ra_interface_distributions_all.interim_tax_segment2%TYPE;
      vc_interim_tax_segment3  ra_interface_distributions_all.interim_tax_segment3%TYPE;
      vc_interim_tax_segment4  ra_interface_distributions_all.interim_tax_segment4%TYPE;
      vc_interim_tax_segment5  ra_interface_distributions_all.interim_tax_segment5%TYPE;
      vc_interim_tax_segment6  ra_interface_distributions_all.interim_tax_segment6%TYPE;
      vc_interim_tax_segment7  ra_interface_distributions_all.interim_tax_segment7%TYPE;
      vc_interim_tax_segment8  ra_interface_distributions_all.interim_tax_segment8%TYPE;
      vc_interim_tax_segment9  ra_interface_distributions_all.interim_tax_segment9%TYPE;
      vc_interim_tax_segment10 ra_interface_distributions_all.interim_tax_segment10%TYPE;
      vc_interim_tax_segment11 ra_interface_distributions_all.interim_tax_segment11%TYPE;
      vc_interim_tax_segment12 ra_interface_distributions_all.interim_tax_segment12%TYPE;
    
      pn_retcode NUMBER(15);
    
      rec_dist cur_dist%ROWTYPE;
    
      PROCEDURE get_ccid_tax(pv_company_code  IN VARCHAR2,
                             pv_acct_area     IN VARCHAR2,
                             pn_org_id        IN NUMBER,
                             pv_tax_code      IN VARCHAR2,
                             pv_segment1      OUT VARCHAR2,
                             pv_segment2      OUT VARCHAR2,
                             pv_segment3      OUT VARCHAR2,
                             pv_segment4      OUT VARCHAR2,
                             pv_segment5      OUT VARCHAR2,
                             pv_segment6      OUT VARCHAR2,
                             pv_segment7      OUT VARCHAR2,
                             pv_segment8      OUT VARCHAR2,
                             pv_segment9      OUT VARCHAR2,
                             pv_segment10     OUT VARCHAR2,
                             pv_segment11     OUT VARCHAR2,
                             pv_segment12     OUT VARCHAR2,
                             pv_int_segment1  OUT VARCHAR2,
                             pv_int_segment2  OUT VARCHAR2,
                             pv_int_segment3  OUT VARCHAR2,
                             pv_int_segment4  OUT VARCHAR2,
                             pv_int_segment5  OUT VARCHAR2,
                             pv_int_segment6  OUT VARCHAR2,
                             pv_int_segment7  OUT VARCHAR2,
                             pv_int_segment8  OUT VARCHAR2,
                             pv_int_segment9  OUT VARCHAR2,
                             pv_int_segment10 OUT VARCHAR2,
                             pv_int_segment11 OUT VARCHAR2,
                             pv_int_segment12 OUT VARCHAR2,
                             pv_errbuf        IN OUT VARCHAR2,
                             pn_retcode       OUT NUMBER) IS
        vn_retcode_seg NUMBER;
        vv_errbuf      VARCHAR2(200);
        pn_tax         VARCHAR2(30);
      
      BEGIN
      
        pn_retcode := 0;
      
        SELECT tax_type
          INTO pn_tax
          FROM ar_vat_tax_all
         WHERE tax_code = pv_tax_code
           AND org_id = pn_org_id;
      
        IF pn_tax = 'DEFERRED' THEN
          BEGIN
            SELECT DECODE(gcc_interim.segment1,
                          'XXXX',
                          pv_company_code,
                          gcc_interim.segment1),
                   pv_acct_area,
                   gcc_interim.segment3,
                   gcc_interim.segment4,
                   gcc_interim.segment5,
                   gcc_interim.segment6,
                   gcc_interim.segment7,
                   gcc_interim.segment8,
                   gcc_interim.segment9,
                   gcc_interim.segment10,
                   gcc_interim.segment11,
                   gcc_interim.segment12,
                   DECODE(gcc_definitif.segment1,
                          'XXXX',
                          pv_company_code,
                          gcc_definitif.segment1),
                   pv_acct_area,
                   gcc_definitif.segment3,
                   gcc_definitif.segment4,
                   gcc_definitif.segment5,
                   gcc_definitif.segment6,
                   gcc_definitif.segment7,
                   gcc_definitif.segment8,
                   gcc_definitif.segment9,
                   gcc_definitif.segment10,
                   gcc_definitif.segment11,
                   gcc_definitif.segment12
              INTO pv_int_segment1,
                   pv_int_segment2,
                   pv_int_segment3,
                   pv_int_segment4,
                   pv_int_segment5,
                   pv_int_segment6,
                   pv_int_segment7,
                   pv_int_segment8,
                   pv_int_segment9,
                   pv_int_segment10,
                   pv_int_segment11,
                   pv_int_segment12,
                   pv_segment1,
                   pv_segment2,
                   pv_segment3,
                   pv_segment4,
                   pv_segment5,
                   pv_segment6,
                   pv_segment7,
                   pv_segment8,
                   pv_segment9,
                   pv_segment10,
                   pv_segment11,
                   pv_segment12
              FROM ar_vat_tax_all_b     avtab,
                   gl_code_combinations gcc_interim,
                   gl_code_combinations gcc_definitif
             WHERE avtab.interim_tax_ccid = gcc_interim.code_combination_id
               AND avtab.tax_account_id = gcc_definitif.code_combination_id
               AND tax_code = pv_tax_code
               AND org_id = pn_org_id;
          
          END;
        ELSE
          BEGIN
            pv_int_segment1  := NULL;
            pv_int_segment2  := NULL;
            pv_int_segment3  := NULL;
            pv_int_segment4  := NULL;
            pv_int_segment5  := NULL;
            pv_int_segment6  := NULL;
            pv_int_segment7  := NULL;
            pv_int_segment8  := NULL;
            pv_int_segment9  := NULL;
            pv_int_segment10 := NULL;
            pv_int_segment11 := NULL;
            pv_int_segment12 := NULL;
          
            SELECT DECODE(gcc.segment1,
                          'XXXX',
                          pv_company_code,
                          gcc.segment1),
                   pv_acct_area,
                   gcc.segment3,
                   gcc.segment4,
                   gcc.segment5,
                   gcc.segment6,
                   gcc.segment7,
                   gcc.segment8,
                   gcc.segment9,
                   gcc.segment10,
                   gcc.segment11,
                   gcc.segment12
              INTO pv_segment1,
                   pv_segment2,
                   pv_segment3,
                   pv_segment4,
                   pv_segment5,
                   pv_segment6,
                   pv_segment7,
                   pv_segment8,
                   pv_segment9,
                   pv_segment10,
                   pv_segment11,
                   pv_segment12
              FROM ar_vat_tax_all_b avtab, gl_code_combinations gcc
             WHERE avtab.tax_account_id = gcc.code_combination_id
               AND tax_code = pv_tax_code
               AND org_id = pn_org_id;
          END;
        END IF;
      
      END;
    
    BEGIN
    
      OPEN cur_dist;
      LOOP
        FETCH cur_dist
          INTO rec_dist;
        EXIT WHEN cur_dist%NOTFOUND;
      
        vc_segment1              := rec_dist.segment1;
        vc_segment2              := rec_dist.segment2;
        vc_segment3              := rec_dist.segment3;
        vc_segment4              := rec_dist.segment4;
        vc_segment5              := rec_dist.segment5;
        vc_segment6              := rec_dist.segment6;
        vc_segment7              := rec_dist.segment7;
        vc_segment8              := rec_dist.segment8;
        vc_segment9              := rec_dist.segment9;
        vc_segment10             := rec_dist.segment10;
        vc_segment11             := rec_dist.segment11;
        vc_segment12             := rec_dist.segment12;
        vc_interim_tax_segment1  := NULL;
        vc_interim_tax_segment2  := NULL;
        vc_interim_tax_segment3  := NULL;
        vc_interim_tax_segment4  := NULL;
        vc_interim_tax_segment5  := NULL;
        vc_interim_tax_segment6  := NULL;
        vc_interim_tax_segment7  := NULL;
        vc_interim_tax_segment8  := NULL;
        vc_interim_tax_segment9  := NULL;
        vc_interim_tax_segment10 := NULL;
        vc_interim_tax_segment11 := NULL;
        vc_interim_tax_segment12 := NULL;
      
        IF rec_dist.account_class = 'REV' THEN
          vc_segment1  := rec_dist.segment1;
          vc_segment2  := rec_dist.segment2;
          vc_segment3  := rec_dist.new_segment3;
          vc_segment4  := rec_dist.new_segment4;
          vc_segment5  := '0';
          vc_segment6  := '0';
          vc_segment7  := '0';
          vc_segment8  := '0';
          vc_segment9  := '0';
          vc_segment10 := '0';
          vc_segment11 := '0';
          vc_segment12 := '0';
        ELSIF rec_dist.account_class = 'TAX' THEN
        
          SELECT DECODE(rec_dist.segment1,
                        'XXXX',
                        vc_segment1,
                        rec_dist.segment1),
                 vc_segment2,
                 rec_dist.segment3,
                 rec_dist.segment4,
                 rec_dist.segment5,
                 rec_dist.segment6,
                 rec_dist.segment7,
                 rec_dist.segment8,
                 rec_dist.segment9,
                 rec_dist.segment10,
                 rec_dist.segment11,
                 rec_dist.segment12,
                 nvl(DECODE(rec_dist.collected_seg1,
                            'XXXX',
                            vc_segment1,
                            rec_dist.collected_seg1),
                     DECODE(rec_dist.segment1,
                            'XXXX',
                            vc_segment1,
                            rec_dist.segment1)),
                 vc_segment2,
                 nvl(rec_dist.collected_seg3, rec_dist.segment3),
                 nvl(rec_dist.collected_seg4, rec_dist.segment4),
                 nvl(rec_dist.collected_seg5, rec_dist.segment5),
                 nvl(rec_dist.collected_seg6, rec_dist.segment6),
                 nvl(rec_dist.collected_seg7, rec_dist.segment7),
                 nvl(rec_dist.collected_seg8, rec_dist.segment8),
                 nvl(rec_dist.collected_seg9, rec_dist.segment9),
                 nvl(rec_dist.collected_seg10, rec_dist.segment10),
                 nvl(rec_dist.collected_seg11, rec_dist.segment11),
                 nvl(rec_dist.collected_seg12, rec_dist.segment12)
            INTO vc_interim_tax_segment1,
                 vc_interim_tax_segment2,
                 vc_interim_tax_segment3,
                 vc_interim_tax_segment4,
                 vc_interim_tax_segment5,
                 vc_interim_tax_segment6,
                 vc_interim_tax_segment7,
                 vc_interim_tax_segment8,
                 vc_interim_tax_segment9,
                 vc_interim_tax_segment10,
                 vc_interim_tax_segment11,
                 vc_interim_tax_segment12,
                 vc_segment1,
                 vc_segment2,
                 vc_segment3,
                 vc_segment4,
                 vc_segment5,
                 vc_segment6,
                 vc_segment7,
                 vc_segment8,
                 vc_segment9,
                 vc_segment10,
                 vc_segment11,
                 vc_segment12
            FROM dual;
        
        END IF;
      
        INSERT INTO RA_INTERFACE_DISTRIBUTIONS_ALL
          (interface_line_context,
           interface_line_attribute1,
           interface_line_attribute2,
           interface_line_attribute3,
           interface_line_attribute4,
           interface_line_attribute5,
           account_class,
           amount,
           percent,
           segment1,
           segment2,
           segment3,
           segment4,
           segment5,
           segment6,
           segment7,
           segment8,
           segment9,
           segment10,
           segment11,
           segment12,
           org_id,
           interim_tax_segment1,
           interim_tax_segment2,
           interim_tax_segment3,
           interim_tax_segment4,
           interim_tax_segment5,
           interim_tax_segment6,
           interim_tax_segment7,
           interim_tax_segment8,
           interim_tax_segment9,
           interim_tax_segment10,
           interim_tax_segment11,
           interim_tax_segment12)
        VALUES
          (cv_interface_line_context,
           rec_dist.new_cust_trx_type_name,
           substr(rec_dist.societe_absorbante, 4, 4),
           ltrim(substr(lpad(rec_dist.societe_absorbee || '_' ||
                             rec_dist.interface_line_attribute3,
                             240,
                             ' '),
                        -30)), --08/02/2007
           
           rec_dist.trx_date,
           rec_dist.interface_line_attribute4,
           rec_dist.account_class,
           rec_dist.amount,
           rec_dist.percent,
           substr(rec_dist.societe_absorbante, 4, 4),
           vc_segment2,
           vc_segment3,
           vc_segment4,
           vc_segment5,
           vc_segment6,
           vc_segment7,
           vc_segment8,
           vc_segment9,
           vc_segment10,
           vc_segment11,
           vc_segment12,
           rec_dist.org_id_absorbante,
           DECODE(vc_interim_tax_segment1,
                  Null,
                  Null,
                  substr(rec_dist.societe_absorbante, 4, 4)),
           vc_interim_tax_segment2,
           vc_interim_tax_segment3,
           vc_interim_tax_segment4,
           vc_interim_tax_segment5,
           vc_interim_tax_segment6,
           vc_interim_tax_segment7,
           vc_interim_tax_segment8,
           vc_interim_tax_segment9,
           vc_interim_tax_segment10,
           vc_interim_tax_segment11,
           vc_interim_tax_segment12);
      
        INSERT INTO ra_interface_distributions_all
          (interface_line_context,
           interface_line_attribute1,
           interface_line_attribute2,
           interface_line_attribute3,
           interface_line_attribute4,
           interface_line_attribute5,
           account_class,
           amount,
           percent,
           segment1,
           segment2,
           segment3,
           segment4,
           segment5,
           segment6,
           segment7,
           segment8,
           segment9,
           segment10,
           segment11,
           segment12,
           org_id,
           interim_tax_segment1,
           interim_tax_segment2,
           interim_tax_segment3,
           interim_tax_segment4,
           interim_tax_segment5,
           interim_tax_segment6,
           interim_tax_segment7,
           interim_tax_segment8,
           interim_tax_segment9,
           interim_tax_segment10,
           interim_tax_segment11,
           interim_tax_segment12)
        VALUES
          (cv_interface_line_context,
           rec_dist.new_cust_trx_type_name,
           substr(rec_dist.societe_absorbee, 4, 4),
           ltrim(substr(lpad(rec_dist.societe_absorbante || '_' ||
                             rec_dist.interface_line_attribute3,
                             240,
                             ' '),
                        -30)),
           
           rec_dist.trx_date,
           rec_dist.interface_line_attribute4,
           rec_dist.account_class,
           -1 * rec_dist.amount,
           rec_dist.percent,
           substr(rec_dist.societe_absorbee, 4, 4),
           vc_segment2,
           vc_segment3,
           vc_segment4,
           vc_segment5,
           vc_segment6,
           vc_segment7,
           vc_segment8,
           vc_segment9,
           vc_segment10,
           vc_segment11,
           vc_segment12,
           rec_dist.org_id_absorbee,
           DECODE(vc_interim_tax_segment1,
                  Null,
                  Null,
                  substr(rec_dist.societe_absorbee, 4, 4)),
           vc_interim_tax_segment2,
           vc_interim_tax_segment3,
           vc_interim_tax_segment4,
           vc_interim_tax_segment5,
           vc_interim_tax_segment6,
           vc_interim_tax_segment7,
           vc_interim_tax_segment8,
           vc_interim_tax_segment9,
           vc_interim_tax_segment10,
           vc_interim_tax_segment11,
           vc_interim_tax_segment12);
      
      END LOOP;
      CLOSE cur_dist;
    
    END;
  
    debug(pv_debug, 'procédure insertion_facture : fin');
  EXCEPTION
    WHEN OTHERS THEN
      v_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || v_errbuf);
      message(pn_codret, 'Procédure insertion_facture : Fin en erreur');
      debug(pv_debug, 'erreur dans l''activation des CCID');
      debug(pv_debug, v_errbuf);
      pn_codret := cn_error;
  end insertion_facture;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insertion_reglement
  --  Description   : Insertion des réglements
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure insertion_reglement(pn_codret     IN OUT NUMBER,
                                pv_errbuf     OUT VARCHAR2,
                                pv_debug      IN VARCHAR2,
                                pv_simulation IN VARCHAR2) IS
  
    Cursor c_reglements IS
    
      Select dafrct.receipt_number receipt_number,
             dafrct.AMOUNT,
             dafrct.cash_receipt_id,
             dafrct.reversal_date reversal_date,
             dafrct.societe_absorbante societe_absorbante,
             dafrct.org_id_absorbee org_id_absorbee,
             dafrct.CURRENCY_CODE,
             dafrct.SOCIETE_ABSORBEE,
             dafrct.receipt_date,
             dafrct.pay_from_customer,
             dafrct.REMITTANCE_BANK_ACCOUNT_ID,
             dafrct.NEW_RECEIPT_METHOD_ID,
             dafrct.ORG_ID_ABSORBANTE,
             (select nvl(sum(araa.amount_applied), 0)
                from ar_receivable_applications_all araa
               where dafrct.cash_receipt_id = araa.cash_receipt_id
                 and araa.status = cv_ARAA_status_encom) as mtt_acc,
             (select nvl(sum(araa2.amount_applied), 0)
                from ar_receivable_applications_all araa2
               where dafrct.cash_receipt_id = araa2.cash_receipt_id
                 and araa2.status = cv_ARAA_status_unapplied) as mtt_unapp,
             (select nvl(sum(araa3.amount_applied), 0)
                from ar_receivable_applications_all araa3
               where dafrct.cash_receipt_id = araa3.cash_receipt_id
                 and araa3.status = cv_ARAA_status_applied) as mtt_app,
             (select nvl(sum(araa4.amount_applied), 0)
                from ar_receivable_applications_all araa4
               where dafrct.cash_receipt_id = araa4.cash_receipt_id
                 and araa4.status = cv_ARAA_status_unid) as mtt_unid
        from dka_ar_fusion_rec_ctrl_temp dafrct
       where dafrct.CANCELABLE = 'O';
  
    rec_reglement c_reglements%rowtype;
  
    v_return_status   VARCHAR2(30);
    vn_receipt_method NUMBER;
    v_msg_count       NUMBER;
    v_msg_data        VARCHAR2(2000);
    v_attribute_rec   AR_RECEIPT_API_PUB.attribute_rec_type;
    v_cr_id           number;
    v_commit          VARCHAR2(1);
    l_message_api     VARCHAR2(240);
    l_index           number := 0;
    v_comments        VARCHAR2(1900);
  
  BEGIN
    debug(pv_debug, 'procédure insertion_reglement : début');
    pn_codret := cn_ok;
    IF pv_simulation = 'Y' THEN
      v_commit := FND_API.G_FALSE;
    ELSE
      v_commit := FND_API.G_TRUE;
    END if;
    open c_reglements;
    loop
      fetch c_reglements
        into rec_reglement;
      exit when c_reglements%NOTFOUND;
      v_attribute_rec.attribute1 := rec_reglement.amount;
    
      BEGIN
        Select comments
          into v_comments
          from ar_cash_receipts_all acra
         where acra.cash_receipt_id = rec_reglement.cash_receipt_id;
      EXCEPTIOn
        WHEN NO_DATA_FOUND THEN
          v_comments := '';
      END;
    
      -- Pour les règlements non lettrés et non identifiés : appel de create_cash
      IF to_number(rec_reglement.mtt_acc) = 0 THEN
        ar_receipt_api_pub.Create_cash(p_api_version            => 1.0,
                                       p_init_msg_list          => FND_API.G_TRUE,
                                       p_commit                 => v_commit,
                                       p_validation_level       => FND_API.G_VALID_LEVEL_FULL,
                                       x_return_status          => v_return_status,
                                       x_msg_count              => v_msg_count,
                                       x_msg_data               => v_msg_data,
                                       p_usr_currency_code      => NULL,
                                       p_currency_code          => rec_reglement.currency_code,
                                       p_usr_exchange_rate_type => NULL,
                                       p_exchange_rate_type     => NULL,
                                       p_exchange_rate          => NULL,
                                       p_exchange_rate_date     => NULL,
                                       p_amount                 => rec_reglement.amount -
                                                                   rec_reglement.mtt_app,
                                       -- la variable receipt_number est limitée à  30 caractètres
                                       -- on stocke le numéro d'origine dans les commentaires au cas oà¹ receipt_number est tronqué
                                       p_receipt_number               => substr(rec_reglement.societe_absorbee || '_' ||
                                                                                rec_reglement.receipt_number,
                                                                                1,
                                                                                30),
                                       p_comments                     => rec_reglement.receipt_number ||
                                                                         ' - ' ||
                                                                         v_comments,
                                       p_receipt_date                 => rec_reglement.receipt_date,
                                       p_gl_date                      => rec_reglement.reversal_date,
                                       p_maturity_date                => rec_reglement.receipt_date,
                                       p_customer_id                  => rec_reglement.pay_from_customer,
                                       p_customer_bank_account_num    => NULL,
                                       p_customer_bank_account_name   => NULL,
                                       p_customer_receipt_reference   => 'SKM-API',
                                       p_override_remit_account_flag  => NULL,
                                       p_remittance_bank_account_id   => rec_reglement.REMITTANCE_BANK_ACCOUNT_ID,
                                       p_remittance_bank_account_num  => NULL,
                                       p_remittance_bank_account_name => NULL,
                                       p_deposit_date                 => sysdate,
                                       p_receipt_method_id            => rec_reglement.new_receipt_method_id,
                                       p_receipt_method_name          => NULL,
                                       p_org_id                       => rec_reglement.org_id_absorbante,
                                       p_called_from                  => 'pl/sql Script',
                                       p_attribute_rec                => v_attribute_rec,
                                       p_issuer_name                  => NULL,
                                       p_issue_date                   => NULL,
                                       p_issuer_bank_branch_id        => NULL,
                                       p_cr_id                        => v_cr_id);
        -- Si erreur renvoyée par l'API
        if (v_return_status != 'S') THEN
          pn_codret := cn_warning;
          message(pn_codret,
                  'Erreur création règlement sur : ' ||
                  rec_reglement.societe_absorbee || '_' ||
                  rec_reglement.receipt_number);
          IF v_msg_count = 1 then
            message(pn_codret, v_msg_data);
          ELSE
            for i in 1 .. v_msg_count LOOP
              fnd_msg_pub.get(p_msg_index     => i,
                              p_encoded       => 'F',
                              p_data          => l_message_api,
                              p_msg_index_out => l_index);
              message(pn_codret, l_message_api);
            END loop;
          end if;
        end if;
      END if;
    
      IF to_number(rec_reglement.mtt_acc) <> 0 and
         to_number(rec_reglement.mtt_acc) <> rec_reglement.amount THEN
      
        AR_RECEIPT_API_PUB.Create_Apply_on_acc(p_api_version      => 1.0,
                                               p_init_msg_list    => FND_API.G_TRUE,
                                               p_commit           => v_commit,
                                               p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                                               x_return_status    => v_return_status,
                                               x_msg_count        => v_msg_count,
                                               x_msg_data         => v_msg_data,
                                               p_currency_code    => rec_reglement.currency_code,
                                               p_amount           => rec_reglement.amount -
                                                                     rec_reglement.mtt_app,
                                               -- la variable receipt_number est limitée à  30 caractètres
                                               -- on stocke le numéro d'origine dans les commentaires au cas oà¹ receipt_number est tronqué
                                               p_receipt_number             => substr(rec_reglement.societe_absorbee || '_' ||
                                                                                      rec_reglement.receipt_number,
                                                                                      1,
                                                                                      30),
                                               p_amount_applied             => rec_reglement.mtt_acc,
                                               p_receipt_comments           => rec_reglement.receipt_number ||
                                                                               ' - ' ||
                                                                               v_comments,
                                               p_receipt_date               => rec_reglement.receipt_date,
                                               p_gl_date                    => rec_reglement.reversal_date,
                                               p_maturity_date              => rec_reglement.receipt_date,
                                               p_customer_receipt_reference => 'SKM-API',
                                               p_customer_id                => rec_reglement.pay_from_customer,
                                               p_receipt_method_id          => rec_reglement.new_receipt_method_id,
                                               p_attribute_rec              => v_attribute_rec,
                                               p_org_id                     => rec_reglement.org_id_absorbante,
                                               p_cr_id                      => v_cr_id,
                                               p_apply_date                 => rec_reglement.reversal_date,
                                               p_apply_gl_date              => rec_reglement.reversal_date);
      
        -- Si erreur renvoyée par l'API
        if (v_return_status != 'S') THEN
          pn_codret := cn_warning;
          message(pn_codret,
                  'Erreur création règlement sur : ' ||
                  rec_reglement.societe_absorbee || '_' ||
                  rec_reglement.receipt_number);
          IF v_msg_count = 1 then
            message(pn_codret, v_msg_data);
          ELSE
            for i in 1 .. v_msg_count LOOP
              fnd_msg_pub.get(p_msg_index     => i,
                              p_encoded       => 'F',
                              p_data          => l_message_api,
                              p_msg_index_out => l_index);
              message(pn_codret, l_message_api);
            END loop;
          end if;
        end if;
      END if;
    
      IF rec_reglement.amount = to_number(rec_reglement.mtt_acc) THEN
        Begin
          select distinct arm.RECEIPT_METHOD_ID
            into vn_receipt_method
            from ar_receipt_methods arm
           where arm.name = substr(rec_reglement.societe_absorbante, 4, 4) || '_' ||
                 substr(rec_reglement.societe_absorbante, 1, 3) ||
                 '_FUSION'
             and rownum = 1;
        
        Exception
          WHEN no_data_found THEN
            message(pn_codret,
                    'erreur dans récupération des mode de réglement de la société absorbante (En compte)');
          
        End;
        -- Pour les règlements en comptes : Appel de create_apply_on_acc
        AR_RECEIPT_API_PUB.Create_Apply_on_acc(p_api_version      => 1.0,
                                               p_init_msg_list    => FND_API.G_TRUE,
                                               p_commit           => v_commit,
                                               p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                                               x_return_status    => v_return_status,
                                               x_msg_count        => v_msg_count,
                                               x_msg_data         => v_msg_data,
                                               p_currency_code    => rec_reglement.currency_code,
                                               p_amount           => rec_reglement.amount,
                                               -- la variable receipt_number est limitée à  30 caractètres
                                               -- on stocke le numéro d'origine dans les commentaires au cas oà¹ receipt_number est tronqué
                                               p_receipt_number             => substr(rec_reglement.societe_absorbee || '_' ||
                                                                                      rec_reglement.receipt_number,
                                                                                      1,
                                                                                      30),
                                               p_amount_applied             => rec_reglement.mtt_acc,
                                               p_receipt_comments           => rec_reglement.receipt_number ||
                                                                               ' - ' ||
                                                                               v_comments,
                                               p_receipt_date               => rec_reglement.receipt_date,
                                               p_gl_date                    => rec_reglement.reversal_date,
                                               p_maturity_date              => rec_reglement.receipt_date,
                                               p_customer_receipt_reference => 'SKM-API',
                                               p_customer_id                => rec_reglement.pay_from_customer,
                                               p_receipt_method_id          => vn_receipt_method,
                                               p_attribute_rec              => v_attribute_rec,
                                               p_org_id                     => rec_reglement.org_id_absorbante,
                                               p_cr_id                      => v_cr_id,
                                               p_apply_date                 => rec_reglement.reversal_date,
                                               p_apply_gl_date              => rec_reglement.reversal_date);
        -- Si erreur renvoyée par l'API
        IF (v_return_status != 'S') THEN
          pn_codret := cn_warning;
          message(pn_codret,
                  'Erreur création règlement en compte : ' ||
                  rec_reglement.societe_absorbee || '_' ||
                  rec_reglement.receipt_number);
          IF v_msg_count = 1 then
            message(pn_codret, v_msg_data);
          ELSE
            for i in 1 .. v_msg_count LOOP
              fnd_msg_pub.get(p_msg_index     => i,
                              p_encoded       => 'F',
                              p_data          => l_message_api,
                              p_msg_index_out => l_index);
              message(pn_codret, l_message_api);
            END loop;
          
          END if;
        end if;
      END if;
    END loop;
    close c_reglements;
  
    debug(pv_debug, 'procédure insertion_reglement : fin');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure insertion_reglement : Fin en erreur');
      debug(pv_debug, 'erreur dans l''activation des CCID');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end insertion_reglement;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : maj_montant
  --  Description   : mise à  jour des montants pour les facture partiellement réglé dont le règlement
  --                concernent pluusieurs factures
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure maj_montant_dist(pn_codret IN OUT NUMBER,
                             pv_errbuf OUT VARCHAR2,
                             pv_debug  IN VARCHAR2) IS
  Begin
  
    message(pv_errbuf, 'Procédure maj_montant_dist : début');
  
    update ra_interface_distributions_all rid
       set rid.amount =
           (select amount
              from ra_interface_lines_all ril
             where 1 = 1
               and rid.interface_line_context = ril.interface_line_context
               and rid.interface_line_attribute1 =
                   ril.interface_line_attribute1
               and rid.interface_line_attribute2 =
                   ril.interface_line_attribute2
               and rid.interface_line_attribute3 =
                   ril.interface_line_attribute3
               and rid.interface_line_attribute4 =
                   ril.interface_line_attribute4
               and rid.interface_line_attribute5 =
                   ril.interface_line_attribute5)
     where rid.account_class != 'REC'
       and exists
     (select '1'
              from ra_interface_lines_all ril2
             where 1 = 1
               and rid.interface_line_context = ril2.interface_line_context
               and rid.interface_line_attribute1 =
                   ril2.interface_line_attribute1
               and rid.interface_line_attribute2 =
                   ril2.interface_line_attribute2
               and rid.interface_line_attribute3 =
                   ril2.interface_line_attribute3
               and rid.interface_line_attribute4 =
                   ril2.interface_line_attribute4
               and rid.interface_line_attribute5 =
                   ril2.interface_line_attribute5
               and rid.amount != ril2.amount);
  
    message(pv_errbuf, 'nb ligne maj :' || SQL%ROWCOUNT);
    debug(pv_debug, 'Procédure maj_montant_dist : fin');
  exception
    when others then
      pn_codret := cn_error;
      pv_errbuf := SQLERRM;
      message(pn_codret, pv_errbuf);
  end maj_montant_dist;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insertion
  --  Description   : procédure qui effectue l'insertion dans les tables d'interfaces et qui lance le traitement
  --                standard de centralisation
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure insertion(pn_codret     IN OUT NUMBER,
                      pv_errbuf     OUT VARCHAR2,
                      pv_debug      IN VARCHAR2,
                      pv_simulation IN VARCHAR2) IS
  begin
    debug(pv_debug, 'procédure insertion : début');
    pn_codret := cn_ok;
    insertion_facture(pn_codret, pv_errbuf, pv_debug);
    if pn_codret <> cn_ok THEN
      debug(pv_debug, 'insertion : Sortie après insertion facture/avoir');
      RETURN;
    END IF;
  
    insertion_reglement(pn_codret, pv_errbuf, pv_debug, pv_simulation);
    if pn_codret <> cn_ok THEN
      debug(pv_debug, 'insertion : Sortie après insertion reglement');
      RETURN;
    END IF;
  
    debug(pv_debug, 'procédure insertion : fin');
  end insertion;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : annulation
  --  Description   : Annulation des règlements sur l'UO absorbée
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure annulation(pn_codret     IN OUT NUMBER,
                       pv_errbuf     OUT VARCHAR2,
                       pv_debug      IN VARCHAR2,
                       pv_simulation IN VARCHAR2) IS
    Cursor c_reglements IS
      Select Distinct dafrct.receipt_number     receipt_number,
                      dafrct.cash_receipt_id    cash_receipt_id,
                      dafrct.reversal_date      reversal_date,
                      dafrct.societe_absorbante societe_absorbante,
                      dafrct.org_id_absorbee    org_id_absorbee
        from dka_ar_fusion_rec_ctrl_temp dafrct
       where dafrct.CANCELABLE = 'O';
  
    rec_reglement c_reglements%rowtype;
    -- Variables pour l'API d'annulation
    l_return_status VARCHAR2(1);
    l_msg_count     NUMBER;
    l_msg_data      VARCHAR2(240);
    v_commit        VARCHAR2(1);
    l_message_api   VARCHAR2(240);
    l_index         number := 0;
  begin
    debug(pv_debug, 'procédure annulation : début');
    pn_codret := cn_ok;
    IF pv_simulation = 'Y' THEN
      v_commit := FND_API.G_FALSE;
    ELSE
      v_commit := FND_API.G_TRUE;
    END if;
    -- Parcours des reglements à  transferer
    For rec_reglement in c_reglements loop
      -- Annulation du réglement dans la société absorbée
      message(pn_codret,
              'Annulation du réglement : ' || rec_reglement.receipt_number);
      AR_RECEIPT_API_PUB.reverse(p_api_version            => 1.0,
                                 p_init_msg_list          => FND_API.G_TRUE,
                                 p_commit                 => v_commit,
                                 p_validation_level       => FND_API.G_VALID_LEVEL_FULL,
                                 x_return_status          => l_return_status,
                                 x_msg_count              => l_msg_count,
                                 x_msg_data               => l_msg_data,
                                 p_receipt_number         => rec_reglement.receipt_number,
                                 p_cash_receipt_id        => rec_reglement.cash_receipt_id,
                                 p_reversal_date          => rec_reglement.reversal_date,
                                 p_reversal_category_name => 'Annuler règlements' --Type d'annulation.
                                ,
                                 p_reversal_reason_name   => 'Compte fermé' -- Raison de l'annulation.
                                ,
                                 p_reversal_comments      => 'FUSION vers ' ||
                                                             rec_reglement.societe_absorbante --code absorbante
                                ,
                                 p_org_id                 => rec_reglement.org_id_absorbee);
    
      if (l_return_status != 'S') THEN
        pn_codret := cn_warning;
        message(pn_codret,
                'Erreur API reverse sur : ' || rec_reglement.receipt_number);
      
        for i in 1 .. l_msg_count LOOP
          fnd_msg_pub.get(p_msg_index     => i,
                          p_encoded       => 'F',
                          p_data          => l_message_api,
                          p_msg_index_out => l_index);
          message(pn_codret, l_message_api);
        END loop;
      
      end if;
    
    end loop;
    debug(pv_debug, 'procédure annulation : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure annulation : Fin en erreur');
      debug(pv_debug, 'erreur dans annulation');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end annulation;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : maj_factures
  --  Description   : Mise à  jour du statut des factures/avoirs/reliquats en litige
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure maj_factures(pn_codret IN OUT NUMBER,
                         pv_errbuf OUT VARCHAR2,
                         pv_debug  IN VARCHAR2) IS
    -- Curseur des mouvements de l'absorbée recréés sur l'UO absorbante
    CURSOR cur_factures IS
      SELECT DISTINCT ltrim(substr(lpad(dafict.societe_absorbee || '_' ||
                                        rcta.trx_number,
                                        25,
                                        ' '),
                                   -20)) trx_number,
                      -- remplacement de dafict.societe_absorbante par dafict.societe_absorbee
                      rcta.customer_trx_id,
                      rcta.bill_to_customer_id,
                      csu.SITE_USE_ID,
                      rcta.trx_date,
                      rcta.attribute10,
                      Rcta.attribute11
        FROM ra_customer_trx_all         rcta,
             dka_ar_fusion_inv_ctrl_temp dafict,
             hz_cust_site_uses_all       csu
       WHERE rcta.customer_trx_id = dafict.customer_trx_id
         and csu.CUST_ACCT_SITE_ID = dafict.NEW_BILL_TO_SITE_USE_ID;
  
    -- Curseur des mouvements créés sur l'absorbante
    CURSOR cur_factures_creees(pv_trx_number          VARCHAR2,
                               pn_customer_trx_id     NUMBER,
                               pn_bill_to_customer_id NUMBER,
                               pn_bill_to_site_use_id NUMBER) IS
      SELECT *
        FROM ra_customer_trx_all rcta
       WHERE rcta.trx_number = pv_trx_number
         AND rcta.bill_to_customer_id = pn_bill_to_customer_id
         AND rcta.bill_to_site_use_id = pn_bill_to_site_use_id
         AND rcta.customer_trx_id <> pn_customer_trx_id
         FOR UPDATE OF rcta.trx_date;
  
    CURSOR cur_mvt_cb(pn_customer_trx_id NUMBER) is
    
      select rctta.type
        from ra_customer_trx_all rcta, ra_cust_trx_types_all rctta
       where rcta.CUST_TRX_TYPE_ID = rctta.CUST_TRX_TYPE_ID
         and rcta.CUST_TRX_TYPE_ID = pn_customer_trx_id
         and rctta.type = 'CB';
  
    rec_factures        cur_factures%ROWTYPE;
    rec_mvt_cb          cur_mvt_cb%ROWTYPE;
    rec_factures_creees cur_factures_creees%ROWTYPE;
    vb_trouve           BOOLEAN;
    vn_nombre           NUMBER;
  
    vn_nb_lus_customer_trx      NUMBER := 0;
    vn_nb_lus_payment_schedules NUMBER := 0;
    vn_nb_maj_customer_trx      NUMBER := 0;
    vn_nb_maj_payment_schedules NUMBER := 0;
    l_inv_trx_number            ra_customer_trx.trx_number%type;
  
    vd_new_due_date          ar_payment_schedules_all.due_date%TYPE;
    vd_new_dispute_date      ar_payment_schedules_all.dispute_date%TYPE;
    vn_new_amount_in_dispute ar_payment_schedules_all.amount_in_dispute%TYPE;
    vd_old_due_date          ar_payment_schedules_all.due_date%TYPE;
    vd_old_dispute_date      ar_payment_schedules_all.dispute_date%TYPE;
    vn_old_amount_in_dispute ar_payment_schedules_all.amount_in_dispute%TYPE;
  
  BEGIN
  
    message(pn_codret, 'Etape 4 : Post Fusion');
    pn_codret := cn_ok;
  
    declare
      cursor c_fact_cb is
        select rct.customer_trx_id,
               rct.cust_trx_type_id,
               rct.trx_number,
               rct.trx_date,
               rctt.cust_trx_type_id           new_cust_trx_type_id,
               rctt.type                       new_class,
               rct.interface_header_attribute1,
               rctt.name
          from DKA_AR_FUSION_INV_CTRL_TEMP dafict
          join ra_customer_trx_all rct
            on rct.interface_header_context = 'FUSION'
           and rct.interface_header_attribute1 = dafict.CUST_TRX_TYPE_NAME
           and rct.interface_header_attribute2 =
               substr(dafict.SOCIETE_ABSORBANTE, 4, 4)
           and rct.interface_header_attribute3 =
               dafict.SOCIETE_ABSORBEE || '_' || dafict.trx_number
        --  and rct.interface_header_attribute4 = 1
          join ar_payment_schedules_all aps
            on rct.customer_trx_id = aps.customer_trx_id
          left outer join ra_cust_trx_types_all rctt
            on case
                 when substr(rct.interface_header_attribute1, 10, 100) =
                      'DOUTEUX_GPE' then
                  'DOUTEUX GROUPE'
                 when rct.interface_header_attribute1 = 'DOUTEUX' then
                  'DOUTEUX'
                 else
                  dafict.CUST_TRX_TYPE_NAME
               end = rctt.name
           and rct.org_id = rctt.org_id
         where 1 = 1
           and dafict.ORIG_TRX_TYPE = 'CB'
           and aps.class <> 'CB';
    begin
    
      for r_row in c_fact_cb loop
        update ra_customer_trx_all rct
           set rct.cust_trx_type_id            = r_row.new_cust_trx_type_id,
               rct.interface_header_attribute4 = r_row.trx_date
         where rct.customer_trx_id = r_row.customer_trx_id;
      
        update ar_payment_schedules_all aps
           set aps.cust_trx_type_id = r_row.new_cust_trx_type_id,
               aps.class            = r_row.new_class
         where aps.customer_trx_id = r_row.customer_trx_id;
      
        message(pn_codret,
                '==> Mise à  jour Type Reliquat pour mouvement ' ||
                r_row.trx_number || ' du ' || r_row.trx_date);
      end loop;
    
    end;
  
    OPEN cur_factures;
    LOOP
      FETCH cur_factures
        INTO rec_factures;
      EXIT WHEN cur_factures%NOTFOUND;
      message(pn_codret,
              '==> Traitement de la facture ' || rec_factures.trx_number ||
              ' du ' || rec_factures.trx_date);
    
      vn_nb_lus_customer_trx := vn_nb_lus_customer_trx + SQL%ROWCOUNT;
    
      BEGIN
        SELECT apsa.due_date, apsa.dispute_date, apsa.amount_in_dispute
          INTO vd_new_due_date,
               vd_new_dispute_date,
               vn_new_amount_in_dispute
          FROM ar_payment_schedules_all apsa
         WHERE apsa.customer_trx_id = rec_factures.customer_trx_id;
      
        vn_nb_lus_payment_schedules := vn_nb_lus_payment_schedules +
                                       SQL%ROWCOUNT;
      
      END;
      l_inv_trx_number := null;
    
      OPEN cur_mvt_cb(rec_factures.customer_trx_id);
      LOOP
        FETCH cur_mvt_cb
          INTO rec_mvt_cb;
        EXIT WHEN cur_mvt_cb%NOTFOUND;
      
        SELECT MAX(ct.trx_number)
          INTO l_inv_trx_number
          FROM ra_customer_trx_all ct, ar_adjustments_all aa --anuj
         WHERE aa.chargeback_customer_trx_id = rec_factures.customer_trx_id
           and ct.org_id = aa.org_id
           AND aa.customer_trx_id = ct.customer_trx_id
           and ROWNUM = 1;
      END LOOP;
      CLOSE cur_mvt_cb;
    
      vb_trouve := FALSE;
      vn_nombre := 0;
      OPEN cur_factures_creees(rec_factures.trx_number,
                               rec_factures.customer_trx_id,
                               rec_factures.bill_to_customer_id,
                               rec_factures.site_use_id);
      LOOP
        FETCH cur_factures_creees
          INTO rec_factures_creees;
        EXIT WHEN cur_factures_creees%NOTFOUND;
        vb_trouve := TRUE;
        vn_nombre := vn_nombre + 1;
      
        IF l_inv_trx_number is not null THEN
          UPDATE ra_customer_trx_all rcta
             set rcta.comments = rcta.comments ||
                                 ' Mouvement origine Reliquat : ' ||
                                 l_inv_trx_number
           WHERE CURRENT OF cur_factures_creees;
        
        END IF;
      
        UPDATE ra_customer_trx_all rcta
           SET rcta.trx_date    = rec_factures.trx_date,
               rcta.attribute8 =
               (select amount
                  from RA_CUST_TRX_LINE_GL_DIST_all rctlgda
                 where rctlgda.CUSTOMER_TRX_ID =
                       rec_factures.customer_trx_id
                   and rctlgda.ACCOUNT_CLASS = 'REC'),
               rcta.attribute10 = rec_factures.attribute10,
               rcta.attribute11 = rec_factures.attribute11
         WHERE CURRENT OF cur_factures_creees;
      
        vn_nb_maj_customer_trx := vn_nb_maj_customer_trx + SQL%ROWCOUNT;
      
        BEGIN
          SELECT apsa.due_date, apsa.dispute_date, apsa.amount_in_dispute
            INTO vd_old_due_date,
                 vd_old_dispute_date,
                 vn_old_amount_in_dispute
            FROM ar_payment_schedules_all apsa
           WHERE apsa.customer_trx_id = rec_factures_creees.customer_trx_id;
        
          IF vd_new_due_date IS NOT NULL THEN
            message(pn_codret,
                    'Date échéance : ' || vd_old_due_date ||
                    ' remplacee par ' || vd_new_due_date);
          END IF;
          IF vd_new_dispute_date IS NOT NULL THEN
            message(pn_codret,
                    'Date du litige : ' || vd_old_dispute_date ||
                    ' remplacee par ' || vd_new_dispute_date);
          END IF;
          IF vn_new_amount_in_dispute IS NOT NULL THEN
            message(pn_codret,
                    'Montant en litige : ' || vn_old_amount_in_dispute ||
                    ' remplace par ' || vn_new_amount_in_dispute);
          END IF;
        
          UPDATE ar_payment_schedules_all apsa
             SET apsa.trx_date          = rec_factures.trx_date,
                 apsa.due_date          = vd_new_due_date,
                 apsa.dispute_date      = vd_new_dispute_date,
                 apsa.amount_in_dispute = vn_new_amount_in_dispute
           WHERE apsa.customer_trx_id = rec_factures_creees.customer_trx_id;
        
          vn_nb_maj_payment_schedules := vn_nb_maj_payment_schedules +
                                         SQL%ROWCOUNT;
        
        END;
      
      END LOOP;
      CLOSE cur_factures_creees;
    
      IF NOT vb_trouve THEN
        message(pn_codret,
                '+ ATTENTION :                                                         +');
        message(pn_codret,
                '+ Nouvelle facture non trouvée pour la facture : ' ||
                rpad(rec_factures.trx_number, 20, ' ') || ' +');
        pn_codret := cn_warning;
      END IF;
      IF vn_nombre > 1 THEN
        message(pn_codret,
                '+ ATTENTION :                                                                  +');
        message(pn_codret,
                '+ Plusieurs nouvelles factures trouvées pour la facture : ' ||
                rpad(rec_factures.trx_number, 20, ' ') || ' +');
        pn_codret := cn_warning;
      END IF;
    
    END LOOP;
    CLOSE cur_factures;
  
    message(pn_codret, 'Fin étape 4 Post Fusion');
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure maj_factures : Fin en erreur');
      debug(pv_debug, 'erreur dans maj_factures');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  END maj_factures;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : post_fusion
  --  Description   : Traitement de post fusion
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure post_fusion(pn_codret IN OUT NUMBER,
                        pv_errbuf OUT VARCHAR2,
                        pv_debug  IN VARCHAR2) IS
  
  begin
    debug(pv_debug, 'procédure post_fusion : début');
    pn_codret := cn_ok;
    debug(pv_debug, 'post_fusion : initialisation');
    initialisation(pn_codret, pv_errbuf, pv_debug, FALSE);
    if pn_codret <> cn_ok THEN
      debug(pv_debug, 'post_fusion : Sortie après initialisation');
      RETURN;
    END IF;
  
    maj_factures(pn_codret, pv_errbuf, pv_debug);
    if pn_codret <> cn_ok THEN
      debug(pv_debug, 'post_fusion : Sortie après maj_factures');
      RETURN;
    END IF;
  
    debug(pv_debug, 'procédure post_fusion : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure post_fusion : Fin en erreur');
      debug(pv_debug, 'erreur dans post_fusion');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end post_fusion;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Controle_client_groupe
  --  Description   : Controle des clients groupe
  --
  --
  --  PARAMETRES    :
  --      pv_debug               Indicateur de debug
  --  VALEUR RETOURNEE :
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE Controle_client_groupe(pn_codret IN OUT NUMBER,
                                   pv_errbuf OUT VARCHAR2,
                                   pv_debug  IN VARCHAR2) IS
  
    CURSOR cur_client_groupe IS
      SELECT distinct rc.customer_name,
                      rc.customer_number,
                      decode(rc.status,
                             'A',
                             'Actif',
                             'I',
                             'Inactif',
                             rc.status),
                      hca.customer_class_code,
                      rc.attribute1 code_partenaire
        FROM dka_ar_fusion_mvt_lettrage_0 dafml,
             hz_cust_accounts             hca,
             ra_customers                 rc
       WHERE 1 = 1
         AND rc.customer_id = dafml.bill_to_customer_id
         AND hca.cust_account_id = dafml.bill_to_customer_id
         AND rc.attribute1 is null
         AND hca.customer_class_code = cv_cust_class_code_gr;
  
    rec_client_groupe cur_client_groupe %ROWTYPE;
  
  BEGIN
  
    dka_tools_pkg.put_debug_message('Procédure Controle_client_groupe : Début');
  
    Dka_Tools_Pkg.put_outdebug_message(CHR(10) ||
                                       'LISTE DES CLIENTS GROUPE SANS CODE PARTENAIRE : ' ||
                                       CHR(10));
  
    OPEN cur_client_groupe;
  
    FETCH cur_client_groupe
      INTO rec_client_groupe;
    IF (cur_client_groupe%FOUND) THEN
    
      dka_tools_pkg.put_outdebug_message('Le client ' ||
                                         rec_client_groupe.customer_number ||
                                         ' - ' ||
                                         rec_client_groupe.customer_number ||
                                         'n''a pas de code partenaire');
      LOOP
        FETCH cur_client_groupe
          INTO rec_client_groupe;
        EXIT WHEN cur_client_groupe%NOTFOUND;
      
        dka_tools_pkg.put_outdebug_message('Le client ' ||
                                           rec_client_groupe.customer_number ||
                                           ' - ' ||
                                           rec_client_groupe.customer_number ||
                                           'n''a pas de code partenaire');
      
      END LOOP;
    ELSE
      Dka_Tools_Pkg.put_outdebug_message('Aucun client groupe incorrect' ||
                                         CHR(10));
    END IF;
  
    CLOSE cur_client_groupe;
  
    dka_tools_pkg.put_debug_message('Procédure Controle_client_groupe : Fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret,
              'Procédure Controle_client_groupe : Fin en erreur');
      debug(pv_debug, 'erreur du controle des clients groupe ');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
      debug(pv_debug, ' Procédure Controle_client_groupe : Fin en erreur');
  END Controle_client_groupe;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : liste_mvts
  --  Description   : Liste des mouvements à  lettrer sur l'UO absorbée
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure liste_mvts(pn_codret IN OUT NUMBER,
                       pv_errbuf OUT VARCHAR2,
                       pv_debug  IN VARCHAR2) IS
    v_count NUMBER := 0;
  begin
    debug(pv_debug, 'procédure liste_mvts : début');
    message(pn_codret,
            'Etape 5 : Liste des mouvements à  lettrer sur l''UO absorbée');
    pn_codret := cn_ok;
    -- Suppression des enregistrements dans la table temporaire avant rechargement
    Delete DKA_AR_FUSION_MVT_LETTRAGE_0;
  
    -- Chargement de la table temporaire avec les mouvements à  lettrer
    INSERT INTO DKA_AR_FUSION_MVT_LETTRAGE_0
      (societe_absorbee,
       societe_absorbante,
       bill_to_customer_id,
       bill_to_site_use_id,
       location,
       customer_trx_id,
       trx_number,
       status,
       class,
       amount_due_original,
       amount_due_remaining,
       acctd_amount_due_remaining,
       name_category,
       customer_id,
       customer_site_use_id,
       org_id,
       date_fusion)
      (SELECT dsl.param1_value, -- Société absorbée
              dsl.return_value, -- Société absorbante
              rct.bill_to_customer_id,
              rct.bill_to_site_use_id,
              hcsu.location,
              rct.customer_trx_id,
              rct.trx_number,
              aps.status,
              aps.class,
              aps.amount_due_original,
              aps.amount_due_remaining,
              aps.acctd_amount_due_remaining,
              rctt.name,
              aps.customer_id,
              aps.customer_site_use_id,
              hou.organization_id,
              dsl.start_date
         FROM ra_customer_trx_all      rct,
              ra_cust_trx_types_all    rctt,
              ar_payment_schedules_all aps,
              hz_cust_site_uses_all    hcsu,
              dka_stransco_lines       dsl,
              dka_stransco_headers     dsh,
              hr_operating_units       hou
        WHERE rct.customer_trx_id = aps.customer_trx_id
          and rct.bill_to_site_use_id = hcsu.site_use_id
          AND rct.cust_trx_type_id = rctt.cust_trx_type_id
          AND dsl.set_id = dsh.set_id
          AND dsh.set_name = cv_transco_fusion_societe
          AND dsl.enable = 'Y'
          AND rct.complete_flag = 'Y'
          AND aps.status <> 'CL'
          AND rct.org_id = hou.organization_id
          AND hou.name = dsl.PARAM1_VALUE
          AND EXISTS
        (SELECT rct1.bill_to_customer_id,
                      rct1.bill_to_site_use_id,
                      SUM(aps1.amount_due_original) amount_original,
                      SUM(aps1.amount_due_remaining) amount_remaining
                 FROM ra_customer_trx_all      rct1,
                      ra_cust_trx_types_all    rctt1,
                      ar_payment_schedules_all aps1,
                      dka_stransco_lines       dsl1,
                      dka_stransco_headers     dsh1,
                      hr_operating_units       hou1
                WHERE dsl1.set_id = dsh1.set_id
                  AND dsh1.set_name = cv_transco_fusion_societe
                  AND dsl1.enable = 'Y'
                  AND rct1.complete_flag = 'Y'
                  AND rct1.customer_trx_id = aps1.customer_trx_id
                  AND aps1.status <> 'CL'
                  AND rct1.org_id = hou1.organization_id
                  AND hou1.name = dsl1.PARAM1_VALUE
                  AND rct1.bill_to_customer_id = rct.bill_to_customer_id
                GROUP BY rct1.bill_to_customer_id, rct1.bill_to_site_use_id
               -- somme du solde dà» égale à  0
               HAVING SUM(aps1.amount_due_remaining) = 0));
    message(pn_codret,
            to_char(SQL%ROWCOUNT) ||
            ' lignes chargées en table DKA_AR_FUSION_MVT_LETTRAGE_0');
    -- Controle des clients groupe
    Controle_client_groupe(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret <> cn_ok THEN
      debug(pv_debug, 'Procédure main_pre_lettrage : Fin en erreur');
      RETURN;
    END IF;
  
    BEGIN
      select count(arm.receipt_method_id)
        into v_count
        FROM ar_receipt_methods             arm,
             ar_receipt_method_accounts_all armaa,
             dka_stransco_headers           dsh,
             dka_stransco_lines             dsl
       WHERE dsh.set_name = cv_transco_fusion_societe
         AND dsh.set_id = dsl.set_id
         and dsl.ENABLE = cv_enable
         AND arm.receipt_class_id = 1003
         AND arm.receipt_method_id = armaa.receipt_method_id
         AND arm.name like substr(dsl.PARAM1_VALUE, 4, 4) || '%585000';
    
      IF v_count = 0 THEN
        message(pn_codret,
                ' Mode de règlement inexistant sur la société absorbée (585000) pour lettrage à 0');
      END IF;
    
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        message(pn_codret,
                ' Erreur recherche Mode de règlement sur la société absorbée (585000) pour lettrage à 0');
      
    END;
    debug(pv_debug, 'procédure liste_mvts : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure liste_mvts : Fin en erreur');
      debug(pv_debug, 'erreur dans liste_mvts');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end liste_mvts;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : lettrage
  --  Description   : Lettrage à  0 sur l'UO absorbée
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure lettrage(pn_codret     IN OUT NUMBER,
                     pv_errbuf     OUT VARCHAR2,
                     pv_debug      IN VARCHAR2,
                     pv_simulation IN VARCHAR2) IS
    CURSOR cur_mvt_lettrer(pn_customer_site_use_id NUMBER) IS
    
      SELECT dafml.societe_absorbee,
             dafml.societe_absorbante,
             rct.customer_trx_id,
             rct.trx_number,
             dafml.amount_due_original,
             dafml.amount_due_remaining,
             dafml.acctd_amount_due_remaining,
             rct.bill_to_customer_id,
             rct.bill_to_site_use_id,
             dafml.org_id,
             dafml.date_fusion,
             dafml.class
        FROM ra_customer_trx_all rct, dka_ar_fusion_mvt_lettrage_0 dafml
       WHERE 1 = 1
         AND rct.customer_trx_id = dafml.customer_trx_id
         and rct.bill_to_site_use_id = pn_customer_site_use_id
       order by dafml.AMOUNT_DUE_REMAINING;
  
    CURSOR cur_rglt_0 IS
      select distinct customer_site_use_id,
                      dafml.customer_id,
                      org_id,
                      date_fusion,
                      societe_absorbee,
                      ar_cust.customer_name
        from dka_ar_fusion_mvt_lettrage_0 dafml, ar_customers ar_cust
       where dafml.customer_id = ar_cust.customer_id
       group by customer_site_use_id,
                dafml.customer_id,
                org_id,
                date_fusion,
                societe_absorbee,
                ar_cust.customer_name;
  
    CURSOR cur_rglt_crees IS
      select apsa.cash_receipt_id,
             dafml.customer_site_use_id,
             dafml.customer_id,
             dafml.customer_trx_id,
             dafml.trx_number,
             dafml.org_id,
             dafml.date_fusion,
             dafml.societe_absorbee,
             apsa.amount_applied,
             ar_cust.customer_name
        FROM ar_payment_schedules_all     apsa,
             dka_ar_fusion_mvt_lettrage_0 dafml,
             ar_customers                 ar_cust
       WHERE apsa.customer_id = dafml.customer_id
         and apsa.customer_site_use_id = dafml.customer_site_use_id
         and apsa.org_id = dafml.org_id
         and dafml.customer_id = ar_cust.customer_id
         AND apsa.status <> 'CL'
       GROUP BY dafml.customer_trx_id,
                dafml.trx_number,
                dafml.customer_site_use_id,
                dafml.customer_id,
                dafml.org_id,
                dafml.date_fusion,
                dafml.societe_absorbee,
                apsa.amount_applied,
                apsa.cash_receipt_id,
                ar_cust.customer_name;
    rec_mvt_lettrer     cur_mvt_lettrer %ROWTYPE;
    rec_rglt_0          cur_rglt_0 %ROWTYPE;
    rec_rglt_crees      cur_rglt_crees %ROWTYPE;
    v_return_status     VARCHAR2(30);
    v_msg_count         NUMBER;
    v_msg_data          VARCHAR2(2000);
    v_cr_id             NUMBER;
    v_receipt_method_id ar_receipt_methods.receipt_method_id%TYPE;
    VN_amount_applied   ar_payment_schedules_all.amount_applied%TYPE;
    vv_status           ar_cash_receipts_all.status%TYPE;
    vv_status_mvt       ar_cash_receipts_all.status%TYPE;
    vn_count            number;
    v_commit            VARCHAR2(1);
    l_message_api       VARCHAR2(240);
    l_index             number := 0;
  begin
    debug(pv_debug, 'procédure lettrage : début');
    pn_codret := cn_ok;
    IF pv_simulation = 'Y' THEN
      v_commit := FND_API.G_FALSE;
    ELSE
      v_commit := FND_API.G_TRUE;
    END if;
    OPEN cur_rglt_0;
    LOOP
      FETCH cur_rglt_0
        INTO rec_rglt_0;
      EXIT WHEN cur_rglt_0%NOTFOUND;
      -- Récupération du receipt_method_id pour le mode virement (*585000*)
      -- et le compte bancaire de trésorerie interne correspondant à  l'UO absorbée
      SELECT distinct arm.receipt_method_id
        INTO v_receipt_method_id
        FROM ar_receipt_methods arm, ar_receipt_method_accounts_all armaa
       WHERE armaa.org_id = rec_rglt_0.org_id
         AND arm.receipt_class_id = 1003
         AND arm.receipt_method_id = armaa.receipt_method_id
         AND arm.name like
             substr(rec_rglt_0.societe_absorbee, 4, 4) || '%585000'
       GROUP BY arm.receipt_method_id;
      -- Création des règlements à  0 par site client
      Ar_receipt_api_pub.Create_cash(p_api_version          => 1.0,
                                     p_init_msg_list        => FND_API.G_TRUE,
                                     p_commit               => v_commit,
                                     p_validation_level     => FND_API.G_VALID_LEVEL_FULL,
                                     x_return_status        => v_return_status,
                                     x_msg_count            => v_msg_count,
                                     x_msg_data             => v_msg_data,
                                     p_currency_code        => 'EUR',
                                     p_amount               => 0,
                                     p_receipt_number       => 'FUSION LETTRAGE A ZERO',
                                     p_receipt_date         => rec_rglt_0.date_fusion,
                                     p_gl_date              => rec_rglt_0.date_fusion,
                                     p_maturity_date        => rec_rglt_0.date_fusion,
                                     p_customer_id          => rec_rglt_0.customer_id,
                                     p_customer_site_use_id => rec_rglt_0.customer_site_use_id,
                                     p_receipt_method_id    => v_receipt_method_id,
                                     p_org_id               => rec_rglt_0.org_id,
                                     p_called_from          => 'pl/sql Script',
                                     p_cr_id                => v_cr_id);
      -- Gestion du code retour
      if (v_return_status != 'S') THEN
        message(pn_codret, 'Erreur Création règlement à  0 sur : ');
        pn_codret := cn_warning;
        pv_errbuf := rec_rglt_0.customer_site_use_id || '/' ||
                     rec_rglt_0.customer_name;
        message(pn_codret, pv_errbuf);
        IF v_msg_count = 1 then
          message(pn_codret, v_msg_data);
        ELSE
          for i in 1 .. v_msg_count LOOP
            fnd_msg_pub.get(p_msg_index     => i,
                            p_encoded       => 'F',
                            p_data          => l_message_api,
                            p_msg_index_out => l_index);
            message(pn_codret, l_message_api);
          END loop;
        end if;
      end if;
    
      OPEN cur_mvt_lettrer(rec_rglt_0.customer_site_use_id);
      LOOP
        FETCH cur_mvt_lettrer
          INTO rec_mvt_lettrer;
        EXIT WHEN cur_mvt_lettrer%NOTFOUND;
        -- Lettrage à  0
        Ar_receipt_api_pub.apply(p_api_version      => 1.0,
                                 p_init_msg_list    => FND_API.G_TRUE,
                                 p_validation_level => FND_API.G_VALID_LEVEL_FULL,
                                 x_return_status    => v_return_status,
                                 x_msg_count        => v_msg_count,
                                 x_msg_data         => v_msg_data,
                                 p_cash_receipt_id  => v_cr_id, --receipt_id du règlement à  0
                                 p_receipt_number   => 'FUSION LETTRAGE A ZERO',
                                 p_trx_number       => rec_mvt_lettrer.trx_number,
                                 p_customer_trx_id  => rec_mvt_lettrer.customer_trx_id,
                                 p_org_id           => rec_mvt_lettrer.org_id,
                                 p_commit           => v_commit,
                                 p_comments         => 'Lettrage a 0 pour fusion vers' ||
                                                       rec_mvt_lettrer.societe_absorbante);
      
        -- Gestion du code retour
        if (v_return_status != 'S') AND NVL(v_cr_id, 0) != 0 THEN
          message(pn_codret, 'Erreur Lettrage sur : ');
          pn_codret := cn_warning;
          pv_errbuf := rec_mvt_lettrer.trx_number || '/' ||
                       rec_mvt_lettrer.customer_trx_id || '/' ||
                       rec_rglt_0.customer_site_use_id || '/' ||
                       rec_rglt_0.customer_name || '/' || v_cr_id;
          message(pn_codret, pv_errbuf);
          IF v_msg_count = 1 then
            message(pn_codret, v_msg_data);
          ELSE
            for i in 1 .. v_msg_count LOOP
              fnd_msg_pub.get(p_msg_index     => i,
                              p_encoded       => 'F',
                              p_data          => l_message_api,
                              p_msg_index_out => l_index);
              message(pn_codret, l_message_api);
            END loop;
          end if;
        end if;
      END LOOP;
      CLOSE cur_mvt_lettrer;
    END LOOP;
    CLOSE cur_rglt_0;
    IF pv_simulation != 'Y' THEN
      OPEN cur_rglt_crees;
      LOOP
        FETCH cur_rglt_crees
          INTO rec_rglt_crees;
        EXIT WHEN cur_rglt_crees%NOTFOUND;
        BEGIN
          SELECT status
            INTO vv_status
            FROM ar_cash_receipts_all
           WHERE cash_receipt_id = rec_rglt_crees.cash_receipt_id;
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vv_status := NULL;
        END;
        IF vv_status = 'UNAPP' THEN
          BEGIN
            SELECT status
              INTO vv_status_mvt
              FROM ar_receivable_applications_all
             WHERE customer_trx_id = rec_rglt_crees.customer_trx_id;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vv_status_mvt := NULL;
          END;
          IF vv_status_mvt = 'UNAPP' THEN
            pn_codret := cn_warning;
            pv_errbuf := 'Règlement non lettré sur cash_receipt_id/trx_number/customer_trx_id/customer_site_use_id/nom_site';
            message(pn_codret, pv_errbuf);
            pv_errbuf := rec_rglt_crees.cash_receipt_id || '/' ||
                         rec_rglt_crees.trx_number || '/' ||
                         rec_rglt_crees.customer_trx_id || '/' ||
                         rec_rglt_crees.customer_site_use_id || '/' ||
                         rec_rglt_crees.customer_name;
            message(pn_codret, pv_errbuf);
          END IF;
        END IF;
      
        -- Si montant lettré à 0
        IF nvl(rec_rglt_crees.amount_applied, 0) = 0 and vv_status != 'REV' THEN
          pn_codret := cn_warning;
          pv_errbuf := 'Montant lettré à 0 pour trx_number/cust_trx_id/cust_site_use_id/nom_site';
          message(pn_codret, pv_errbuf);
          pv_errbuf := rec_rglt_crees.trx_number || '/' ||
                       rec_rglt_crees.customer_trx_id || '/' ||
                       rec_rglt_crees.customer_site_use_id || '/' ||
                       rec_rglt_crees.customer_name;
          message(pn_codret, pv_errbuf);
        END IF;
      
      END LOOP;
      CLOSE cur_rglt_crees;
    END IF;
    debug(pv_debug, 'procédure lettrage : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || pv_errbuf);
      message(pn_codret, 'Procédure lettrage : Fin en erreur');
      debug(pv_debug, 'erreur dans lettrage');
      debug(pv_debug, pv_errbuf);
      pn_codret := cn_error;
  end lettrage;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : edition
  --  Description   : Squelette de procédure
  --
  --
  --  PARAMETRES    :
  --      pv_debug                    Indicateur de debug
  --      pn_codret                   code de retour
  --      pv_errbuf                   Message d'erreur
  --  VALEUR RETOURNEE :
  ---------------------------------------------------------------------------------------------------------------
  Procedure edition(pn_codret IN OUT NUMBER,
                    pv_errbuf OUT VARCHAR2,
                    pv_debug  IN VARCHAR2) IS
    vb_ctrl_ko BOOLEAN := FALSE;
    v_errbuf   VARCHAR2(2500);
  begin
    debug(pv_debug, 'procédure edition : début');
    pn_codret := cn_ok;
    -- RG4 Totalisation des factures, avoirs et autres mouvements non comptabilisés
    --     et règlements
    edition_liste_facture(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug, 'controle : Sortie après edition liste des factures');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    -- RG3 : Lister les factures et avoirs, reliquats (tous mouvements) non comptabilisés
    edition_liste_noncompta(pn_codret, pv_errbuf, pv_debug);
    IF pn_codret = cn_error THEN
      debug(pv_debug,
            'controle : Sortie après edition liste non comptabilisés');
      RETURN;
    ELSIF pn_codret = cn_ctrl_ko THEN
      vb_ctrl_ko := TRUE;
    END IF;
  
    debug(pv_debug, 'procédure edition : fin');
  
  EXCEPTION
    WHEN OTHERS THEN
      v_errbuf := SQLERRM;
      message(pn_codret, 'ERROR : ' || v_errbuf);
      message(pn_codret, 'Procédure edition : Fin en erreur');
      debug(pv_debug, 'erreur dans edition');
      debug(pv_debug, v_errbuf);
      pn_codret := cn_error;
  end edition;

  ---------------------------------------------------------------------------------------------------------------
  --  NOM           : MAIN
  --  DESCRIPTION   : PROCEDURE PRINCIPALE (PUBLIQUE).
  --
  --
  --  PARAMETRES    :
  --      PV_DEBUG  IN VARCHAR2(1)    INDICATEUR DE DEBUG
  --      PV_SIMULATION               PARAMETRE SIMULATION (Y/N)
  --  VALEUR RETOURNEE :
  --      PN_CODRET                   CODE DE RETOUR
  --      PV_ERRBUF                   MESSAGE D'ERREUR
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE MAIN(PV_ERRBUF     OUT VARCHAR2,
                 PN_CODRET     OUT NUMBER,
                 PV_SIMULATION IN VARCHAR2,
                 PV_DEBUG      IN VARCHAR2 DEFAULT 'N'
                 
                 ) IS
  
  BEGIN
    DEBUG(PV_DEBUG, 'FUSION AR : DEBUT');
    PN_CODRET := CN_OK;
    --------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : INITIALISATION');
    INITIALISATION(PN_CODRET, PV_ERRBUF, PV_DEBUG, TRUE);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INITIALISATION');
      RETURN;
    END IF;
    --------------------------------------
    -- ETAPE 1 EXTRACTION ET CONTRELES   -
    --------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : EXTRACTION');
    EXTRACTION(PN_CODRET, PV_ERRBUF, PV_DEBUG);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES EXTRACTION');
      RETURN;
    END IF;
    EDITION(PN_CODRET, PV_ERRBUF, PV_DEBUG);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES EDITION');
      RETURN;
    END IF;
    CONTROLE(PN_CODRET, PV_ERRBUF, PV_DEBUG);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES CONTRELE');
      RETURN;
    END IF;
  
    --------------------------------------------------------------------------------------
    -- ETAPE 2 PROCESS DE FUSION : INSERTION DANS LES TABLES D'INTERFACE   -
    --------------------------------------------------------------------------------------
  
    INSERTION(PN_CODRET, PV_ERRBUF, PV_DEBUG, PV_SIMULATION);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INSERTION');
      RETURN;
    END IF;
  
    -----------------------------------------------------------------
    -- ETAPE 3 ANNULATION DES REGLEMENTS SUR L'UO ABSORBEE          -
    -----------------------------------------------------------------
    ANNULATION(PN_CODRET, PV_ERRBUF, PV_DEBUG, PV_SIMULATION);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES ANNULATION');
      RETURN;
    END IF;
  
    --------------------------------
    -- ETAPE 4 POST-FUSION
    --------------------------------
    POST_FUSION(PN_CODRET, PV_ERRBUF, PV_DEBUG);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES POST-FUSION');
      RETURN;
    END IF;
  
    ---------------------------------------
    --  ETAPE 5 LISTE DES MOUVEMENTS E LETTRER SUR L'UO ABSORBANTE
    ----------------------------------------
    LISTE_MVTS(PN_CODRET, PV_ERRBUF, PV_DEBUG);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES LISTE_MVTS');
      RETURN;
    END IF;
  
    --------------------------------------------
    --  ETAPE 6 LETTRAGE E 0 SUR L'UO ABSORBEE
    --------------------------------------------
    LETTRAGE(PN_CODRET, PV_ERRBUF, PV_DEBUG, PV_SIMULATION);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES LETTRAGE');
      RETURN;
    END IF;
  
    -- GESTION DU MODE SIMULATION
    IF PV_SIMULATION = 'N' THEN
      COMMIT;
    END IF;
  
    DEBUG(PV_DEBUG, 'FUSION AR : FIN');
  END MAIN;

  ---------------------------------------------------------------------------------------------------------------
  --  NOM           : CTR
  --  DESCRIPTION   : CONTRELE PRE-FUSION.
  --
  --
  --  PARAMETRES    :
  --      PV_DEBUG  IN VARCHAR2(1)    INDICATEUR DE DEBUG
  --  VALEUR RETOURNEE :
  --      PN_CODRET                   CODE DE RETOUR
  --      PV_ERRBUF                   MESSAGE D'ERREUR
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE CTR(PV_ERRBUF OUT VARCHAR2,
                PN_CODRET OUT NUMBER,
                PV_DEBUG  IN VARCHAR2 DEFAULT 'N') IS
  
  BEGIN
    DEBUG(PV_DEBUG, 'FUSION AR : DEBUT CONTRELE');
    PN_CODRET := CN_OK;
    --------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : INITIALISATION');
    INITIALISATION(PN_CODRET, PV_ERRBUF, PV_DEBUG, TRUE);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INITIALISATION');
      RETURN;
    END IF;
    -------------------------------------------------
    -- ETAPE 1 Extraction des factures et règlements
    ------------------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : EXTRACTION');
    EXTRACTION(PN_CODRET, PV_ERRBUF, PV_DEBUG);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES EXTRACTION');
      RETURN;
    END IF;
    --- Edition de la liste des factures
    EDITION(PN_CODRET, PV_ERRBUF, PV_DEBUG);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES EDITION');
      RETURN;
    END IF;
    ------------------------------------------------------------
    -- ETAPE 1 Controle sur les factures et règlements à  absorber
    -------------------------------------------------------------
    CONTROLE(PN_CODRET, PV_ERRBUF, PV_DEBUG);
    IF PN_CODRET <> CN_OK THEN
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES CONTRELE');
      RETURN;
    END IF;
  
    DEBUG(PV_DEBUG, 'FUSION AR : FIN CONTRELE');
  END CTR;

  ---------------------------------------------------------------------------------------------------------------
  --  NOM           : FUSION
  --  DESCRIPTION   : PROCESS DE FUSION.
  --
  --
  --  PARAMETRES    :
  --      PV_DEBUG  IN VARCHAR2(1)    INDICATEUR DE DEBUG
  --  VALEUR RETOURNEE :
  --      PN_CODRET                   CODE DE RETOUR
  --      PV_ERRBUF                   MESSAGE D'ERREUR
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE FUSION(PV_ERRBUF     OUT VARCHAR2,
                   PN_CODRET     OUT NUMBER,
                   PV_SIMULATION IN VARCHAR2,
                   PV_DEBUG      IN VARCHAR2 DEFAULT 'N') IS
    V_CODRET NUMBER(1);
    V_ERRBUF VARCHAR2(2500);
  BEGIN
    DEBUG(PV_DEBUG, 'FUSION AR : DEBUT FUSION');
    V_CODRET := CN_OK;
    --------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : INITIALISATION');
    INITIALISATION(V_CODRET, V_ERRBUF, PV_DEBUG, FALSE);
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INITIALISATION');
      RETURN;
    END IF;
    ------------------------------------------------------
    --  ETAPE 2 INSERTION DANS LES TABLES D'INTERFACE
    -------------------------------------------------------
    INSERTION(V_CODRET, V_ERRBUF, PV_DEBUG, PV_SIMULATION);
    -- GESTION DU MODE SIMULATION
    IF PV_SIMULATION = 'N' THEN
      COMMIT;
      maj_montant_dist(pn_codret, pv_errbuf, pv_debug);
      if pn_codret <> cn_ok THEN
        debug(pv_debug, 'insertion : Sortie après maj_montant_dist');
        RETURN;
      END IF;
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INSERTION');
      RETURN;
    END IF;
  
    DEBUG(PV_DEBUG, 'FUSION AR : FIN FUSION');
  END FUSION;

  ---------------------------------------------------------------------------------------------------------------
  --  NOM           : ANNULATION_REGLEMENTS
  --  DESCRIPTION   : ANNULATION DES REGLEMENTS SUR L'UO ABSORBEE.
  --
  --
  --  PARAMETRES    :
  --      PV_DEBUG  IN VARCHAR2(1)    INDICATEUR DE DEBUG
  --  VALEUR RETOURNEE :
  --      PN_CODRET                   CODE DE RETOUR
  --      PV_ERRBUF                   MESSAGE D'ERREUR
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE ANNULATION_REGLEMENTS(PV_ERRBUF     OUT VARCHAR2,
                                  PN_CODRET     OUT NUMBER,
                                  PV_SIMULATION IN VARCHAR2,
                                  PV_DEBUG      IN VARCHAR2 DEFAULT 'N') IS
    V_CODRET NUMBER(1);
    V_ERRBUF VARCHAR2(2500);
  BEGIN
    DEBUG(PV_DEBUG, 'FUSION AR : DEBUT ANNULATION_REGLEMENTS');
    V_CODRET := CN_OK;
    --------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : INITIALISATION');
    INITIALISATION(V_CODRET, V_ERRBUF, PV_DEBUG, FALSE);
    IF PN_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INITIALISATION');
      RETURN;
    END IF;
    -------------------------------------------------------
    -- ETAPE 3 ANNULATION DES REGLEMENTS SUR L'UO ABSORBEE
    -------------------------------------------------------
    ANNULATION(V_CODRET, V_ERRBUF, PV_DEBUG, PV_SIMULATION);
    -- GESTION DU MODE SIMULATION
    IF PV_SIMULATION = 'N' THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES ANNULATION');
      RETURN;
    END IF;
  
    DEBUG(PV_DEBUG, 'FUSION AR : FIN ANNULATION_REGLEMENTS');
  END ANNULATION_REGLEMENTS;

  ---------------------------------------------------------------------------------------------------------------
  --  NOM           : POST_FUSION_AR
  --  DESCRIPTION   : PROCESS DE POST FUSION.
  --
  --
  --  PARAMETRES    :
  --      PV_DEBUG  IN VARCHAR2(1)    INDICATEUR DE DEBUG
  --  VALEUR RETOURNEE :
  --      PN_CODRET                   CODE DE RETOUR
  --      PV_ERRBUF                   MESSAGE D'ERREUR
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE POST_FUSION_AR(PV_ERRBUF     OUT VARCHAR2,
                           PN_CODRET     OUT NUMBER,
                           PV_SIMULATION IN VARCHAR2,
                           PV_DEBUG      IN VARCHAR2 DEFAULT 'N') IS
    V_CODRET NUMBER(1);
    V_ERRBUF VARCHAR2(2500);
  BEGIN
    DEBUG(PV_DEBUG, 'FUSION AR : DEBUT POST_FUSION_AR');
    V_CODRET := CN_OK;
    --------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : INITIALISATION');
    INITIALISATION(V_CODRET, V_ERRBUF, PV_DEBUG, FALSE);
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INITIALISATION');
      RETURN;
    END IF;
  
    --------------------------------
    -- ETAPE 4 POST-FUSION
    --------------------------------
    POST_FUSION(V_CODRET, V_ERRBUF, PV_DEBUG);
    -- GESTION DU MODE SIMULATION
    IF PV_SIMULATION = 'N' THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES POST-FUSION');
      RETURN;
    END IF;
  
    DEBUG(PV_DEBUG, 'FUSION AR : FIN POST_FUSION_AR');
  END POST_FUSION_AR;

  ---------------------------------------------------------------------------------------------------------------
  --  NOM           : LISTE_MOUVEMENTS
  --  DESCRIPTION   : LISTE DES MOUVEMENTS E LETTRER SUR L'UO ABSORBANTE.
  --
  --
  --  PARAMETRES    :
  --      PV_DEBUG  IN VARCHAR2(1)    INDICATEUR DE DEBUG
  --  VALEUR RETOURNEE :
  --      PN_CODRET                   CODE DE RETOUR
  --      PV_ERRBUF                   MESSAGE D'ERREUR
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE LISTE_MOUVEMENTS(PV_ERRBUF OUT VARCHAR2,
                             PN_CODRET OUT NUMBER,
                             PV_DEBUG  IN VARCHAR2 DEFAULT 'N') IS
    V_CODRET NUMBER(1);
    V_ERRBUF VARCHAR2(2500);
  BEGIN
    DEBUG(PV_DEBUG, 'FUSION AR : DEBUT POST_FUSION_AR');
    V_CODRET := CN_OK;
    --------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : INITIALISATION');
    INITIALISATION(V_CODRET, V_ERRBUF, PV_DEBUG, FALSE);
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INITIALISATION');
      RETURN;
    END IF;
    -------------------------------------------------------
    --  ETAPE 5 : SELECTION DES MOUVEMENTS A LETTRER A ZERO
    -------------------------------------------------------
    LISTE_MVTS(V_CODRET, V_ERRBUF, PV_DEBUG);
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES LISTE_MOUVEMENTS-FUSION');
      RETURN;
    END IF;
  
    DEBUG(PV_DEBUG, 'FUSION AR : FIN LISTE_MOUVEMENTS');
  END LISTE_MOUVEMENTS;

  ---------------------------------------------------------------------------------------------------------------
  --  NOM           : LETTRAGE_ZERO
  --  DESCRIPTION   : LETTRAGE E 0 SUR L'UO ABSORBEE.
  --
  --
  --  PARAMETRES    :
  --      PV_DEBUG  IN VARCHAR2(1)    INDICATEUR DE DEBUG
  --  VALEUR RETOURNEE :
  --      PN_CODRET                   CODE DE RETOUR
  --      PV_ERRBUF                   MESSAGE D'ERREUR
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE LETTRAGE_ZERO(PV_ERRBUF     OUT VARCHAR2,
                          PN_CODRET     OUT NUMBER,
                          PV_SIMULATION IN VARCHAR2,
                          PV_DEBUG      IN VARCHAR2 DEFAULT 'N') IS
    V_CODRET NUMBER(1);
    V_ERRBUF VARCHAR2(2500);
  BEGIN
    DEBUG(PV_DEBUG, 'FUSION AR : DEBUT LETTRAGE_ZERO');
    V_CODRET := CN_OK;
    --------------------------------------
    DEBUG(PV_DEBUG, 'MAIN : INITIALISATION');
    INITIALISATION(V_CODRET, V_ERRBUF, PV_DEBUG, FALSE);
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES INITIALISATION');
      RETURN;
    END IF;
    -------------------------------------------------------
    --  ETAPE 6 : LETTRAGE A ZERO
    -------------------------------------------------------
    LETTRAGE(V_CODRET, V_ERRBUF, PV_DEBUG, PV_SIMULATION);
    -- GESTION DU MODE SIMULATION
    IF PV_SIMULATION = 'N' THEN
      COMMIT;
    ELSE
      ROLLBACK;
    END IF;
    IF V_CODRET <> CN_OK THEN
      PN_CODRET := V_CODRET;
      PV_ERRBUF := V_ERRBUF;
      DEBUG(PV_DEBUG, 'MAIN : SORTIE APRES LETTRAGE');
      RETURN;
    END IF;
  
    DEBUG(PV_DEBUG, 'FUSION AR : FIN LETTRAGE_ZERO');
  END LETTRAGE_ZERO;

END DKA_FUSION_AR_PKG;

/
SHOW ERRORS
EXIT