CREATE OR REPLACE PACKAGE BODY DKA_SFAACCPB_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications HELIOS
  -- NOM               : DKA_SFAACCPB_PKG.pkb
  -- DESCRIPTION       : DKA_SFAACCPB_PKG package body :
  ---
  --- AUTEUR       : Roshanak GHARAGOZLOU
  --- DATE DE CREATION : 25/08/2016
  --- DOC. ASSOCIEE    :
  --  COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 29/11/16   NBO Liste les livres FA hors IFRS (TAX), Ajout du parametre SOB
  ---------------------------------------------------------------------------------------------------------------
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER, pn_sob IN NUMBER)
   IS
    vn_responsibility_id           NUMBER;
    vn_application_id              NUMBER;
    vv_fa_responsibility           VARCHAR2(100);
    vn_request_id                  NUMBER;
    vv_phase                       VARCHAR2(100);
    vv_status                      VARCHAR2(100);
    vv_dev_phase                   VARCHAR2(100);
    vv_dev_status                  VARCHAR2(100);
    va_request_ids                 pa_utils.IdTabTyp; ---Tableau
    vn_requests_cnt                NUMBER;
    vv_errbuf                      VARCHAR2(150);
    vn_prog_application_id         NUMBER;
    vv_prog_application_short_name VARCHAR2(50);
    vn_program_id                  NUMBER;
  
    --paramètres du traitement FAACCPB
    n_application                number;
    n_source_application         number;
    n_ledger                     number;
    v_process_category           varchar2(10);
    v_dummy0                     varchar2(10);
    d_end_date                   date;
    v_create_accounting_flag     varchar2(10);
    v_dummy1                     varchar2(10);
    v_accounting_mode            varchar2(10);
    v_dummy2                     varchar2(10);
    v_errors_only_flag           varchar2(10);
    v_report                     varchar2(20);
    v_transfer_to_gl_flag        varchar2(10);
    v_dummy3                     varchar2(10);
    v_gl_batch_name              varchar2(10);
    v_mixed_currency_precision   varchar2(10);
    v_post_to_gl                 varchar2(30);
    v_include_zero               varchar2(10);
    v_include_zero_flag          varchar2(10);
    v_request_id                 number;
    v_entity_id                  varchar2(10);
    v_application_name           varchar2(20);
    v_ledger_name                varchar2(50);
    v_process_category_n         varchar2(10);
    v_create_accounting          varchar2(10);
    v_accounting_mode_name       varchar2(30);
    v_errors_only                varchar2(10);
    v_report_level               varchar2(30);
    v_transfer_to_gl             varchar2(30);
    v_post_in_gl                 varchar2(10);
    n_secu_id_int_1              number;
    n_secu_id_int_2              number;
    n_secu_id_int_3              number;
    v_security_id_char_1         varchar2(10);
    v_security_id_char_2         varchar2(10);
    v_security_id_char_3         varchar2(10);
    v_valuation_method           varchar2(10);
    v_p_include_user_trx_id_flag varchar2(10);
    v_p_include_user_trx_id      varchar2(10);
    v_p_debug_flag               varchar2(10);
    v_p_user_id                  varchar2(10);
    v_p_scalable_flag            varchar2(10);
    v_p_launch_balance_program   varchar2(10);
    v_p_launch_bal_program       varchar2(10);
    n_concurrent_request_id      number;
    v_source_application_name    varchar2(20);
    --curseur sur tous les livres comptables primaires définis dans le jeu de livres affecté à la responsabilité via l¿option de profil 'GL: Jeu d'accès aux données'
    CURSOR cur_acess is
      SELECT gl.name livre, gl.ledger_id
        FROM gl_ledgers gl
       WHERE gl.ledger_id = pn_sob
         AND gl.ledger_category_code = 'PRIMARY';
  
    -- NBO - 29/11/16 - Liste les livres FA hors IFRS (TAX)
	CURSOR cur_book_type(p_ledger_id IN gl_ledgers.ledger_id%TYPE) IS
      SELECT fbc.BOOK_TYPE_CODE, fbc.BOOK_TYPE_NAME, fbc.book_class
        FROM fa_book_controls fbc
       WHERE 1 = 1
         AND fbc.SET_OF_BOOKS_ID = p_ledger_id
         AND nvl(fbc.DATE_INEFFECTIVE, trunc(sysdate)) >= trunc(sysdate) -- Les sociétés actifs
         AND fbc.book_type_code != 'REFERENCE'
      ;
  
  BEGIN
    pn_retcode           := 0;
    pv_errbuf            := NULL;
    vv_fa_responsibility := fnd_profile.value('RESP_NAME');
  
    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      RETURN;
    END IF;
    vn_requests_cnt             := 0;
    dka_tools_pkg.gv_debug_mode := 'Y';
    dka_tools_pkg.put_debug_message('Recuperation des identifiants programme');
    
    -- Récupération de l'id de l'application et de son nom court
    SELECT fcp.application_id,
           fa.application_short_name,
           fcp.concurrent_program_id
      INTO vn_prog_application_id,
           vv_prog_application_short_name,
           vn_program_id
      FROM fnd_concurrent_programs fcp, fnd_application fa
     WHERE fcp.concurrent_program_name = 'FAACCPB'
       AND fa.application_id = fcp.application_id;
  
    --récupération des variables nécessaires au lancement du traitement
    SELECT fr.responsibility_id, fr.application_id
      INTO vn_responsibility_id, vn_application_id
      FROM fnd_responsibility fr
     WHERE fr.responsibility_key = vv_fa_responsibility;
  
    -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
    fnd_global.apps_initialize(fnd_global.user_id,
                               vn_responsibility_id,
                               vn_application_id);
    dka_tools_pkg.put_debug_message('initialisation réussie sur la resp: ' ||
                                    vv_fa_responsibility || '   ' ||
                                    fnd_global.user_id || '   ' ||
                                    vn_responsibility_id || '   ' ||
                                    vn_application_id);
    
    dka_tools_pkg.put_debug_message('pn_sob = ' || pn_sob);
  
    FOR rec_livre IN cur_acess LOOP
    
      ----------------------------------
      -- Renseignement des paramètres --
      ----------------------------------
      -- Récupération des valeurs par défaut
      dka_tools_pkg.put_debug_message('Récupération des paramètres');
    
      SELECT lookup_code
        into v_accounting_mode
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_ACCOUNTING_ENTRY_STATUS'
         AND XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = rec_livre.ledger_id;
    
      SELECT lookup_code
        into v_transfer_to_gl_flag
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
         AND XLK.LOOKUP_CODE = XSO.SUBMIT_TRANSFER_TO_GL_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = rec_livre.ledger_id;
    
      SELECT lookup_code
        into v_report
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_REPORT_LEVEL'
         AND XLK.LOOKUP_CODE = XSO.SUMMARY_REPORT_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = rec_livre.ledger_id;
    
      SELECT MEANING
        into v_report_level
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_REPORT_LEVEL'
         AND XLK.LOOKUP_CODE = XSO.SUMMARY_REPORT_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = rec_livre.ledger_id;
    
      SELECT MEANING
        into v_transfer_to_gl
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
         AND XLK.LOOKUP_CODE = XSO.SUBMIT_TRANSFER_TO_GL_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = rec_livre.ledger_id;
    
      SELECT meaning
        into v_accounting_mode_name
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_ACCOUNTING_ENTRY_STATUS'
         AND XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = rec_livre.ledger_id;
    
      SELECT meaning
        into v_post_in_gl
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
         AND XLK.LOOKUP_CODE = XSO.SUBMIT_GL_POST_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = rec_livre.ledger_id;
    
      SELECT lookup_code
        into v_post_to_gl
        FROM XLA_LOOKUPS XLK, XLA_SUBLEDGER_OPTIONS_V XSO
       WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
         AND XLK.LOOKUP_CODE = XSO.SUBMIT_GL_POST_FLAG
         AND XSO.APPLICATION_ID = vn_application_id
         AND XSO.LEDGER_ID = rec_livre.ledger_id;
    
      SELECT MEANING
        into v_p_launch_bal_program
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'Y';
    
      SELECT lookup_code
        into v_create_accounting_flag
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'Y';
    
      SELECT 'Y'
        into v_dummy2
        FROM DUAL
       WHERE NVL(v_accounting_mode, 'F') = 'F';
    
      SELECT LOOKUP_CODE
        into v_errors_only_flag
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'N';
    
      SELECT meaning
        into v_p_include_user_trx_id
        FROM xla_lookups
       WHERE lookup_type = 'XLA_YES_NO'
         and lookup_code = 'N';
    
      SELECT application_name
        into v_source_application_name
        from fnd_application_tl
       where application_id = fnd_profile.value('resp_appl_id')
         and language = 'F';
    
      SELECT application_name
        into v_application_name
        from fnd_application_tl
       where application_id = fnd_profile.value('resp_appl_id')
         and language = 'F';
    
      SELECT lookup_code
        into v_include_zero_flag
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'N';
    
      SELECT MEANING
        into v_create_accounting
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'Y';
    
      SELECT MEANING
        into v_errors_only
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'N';
    
      SELECT MEANING
        into v_include_zero
        FROM XLA_LOOKUPS
       WHERE LOOKUP_TYPE = 'XLA_YES_NO'
         AND LOOKUP_CODE = 'N';
    
      v_ledger_name := rec_livre.livre;
    
      n_application                := fnd_profile.value('RESP_APPL_ID');
      n_source_application         := fnd_profile.value('RESP_APPL_ID');
      n_ledger                     := rec_livre.ledger_id;
      v_dummy0                     := 'Y';
      d_end_date                   := sysdate;
      v_process_category           := null;
      v_dummy1                     := 'Y';
      v_dummy3                     := 'Y';
      v_mixed_currency_precision   := null;
      v_gl_batch_name              := null;
      v_request_id                 := null;
      v_entity_id                  := null;
      v_process_category_n         := null;
      v_p_include_user_trx_id_flag := 'N';
      v_p_debug_flag               := 'N';
      v_p_user_id                  := fnd_global.user_id;
      v_p_scalable_flag            := 'N';
      n_secu_id_int_1              := null;
      n_secu_id_int_2              := null;
      n_secu_id_int_3              := null;
      v_security_id_char_1         := null;
      v_security_id_char_2         := null;
      v_security_id_char_3         := null;
      v_valuation_method           := null;
      v_p_launch_balance_program   := 'Y';
      n_concurrent_request_id      := null;

    
      ------------------------------------------------------------------------------------------------------------------------------------------------------
      --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST
      dka_tools_pkg.put_debug_message('Soumission du traitement appli = :' ||
                                      vv_prog_application_short_name ||
                                      ' short_name: ' || vn_program_id);
      FOR rec_type IN cur_book_type(rec_livre.ledger_id) LOOP
        vn_request_id := fnd_request.submit_request(vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT  'OFA'
                                                    'FAACCPB', --SHORT_NAME du TRAITEMENT
                                                    NULL, --PROGRAM_NAME
                                                    NULL, --START
                                                    FALSE, --SUB_REQUEST
                                                    rec_type.book_type_code,
                                                    n_application,
                                                    n_source_application,
                                                    v_dummy0,
                                                    n_ledger,
                                                    v_process_category, 
                                                    TO_CHAR(SYSDATE,'YYYY/MM/DD HH24:MI:SS'), 
                                                    v_create_accounting_flag,
                                                    v_dummy1,
                                                    v_accounting_mode,
                                                    v_dummy2,
                                                    v_errors_only_flag,
                                                    v_report,
                                                    v_transfer_to_gl_flag,
                                                    v_dummy3,
                                                    v_post_to_gl,
                                                    v_gl_batch_name, 
                                                    v_mixed_currency_precision,
                                                    v_include_zero_flag,
                                                    v_request_id,
                                                    v_entity_id,
                                                    v_source_application_name,
                                                    v_application_name,
                                                    v_ledger_name,
                                                    v_process_category_n,
                                                    v_create_accounting,
                                                    v_accounting_mode_name,
                                                    v_errors_only,
                                                    v_report_level,
                                                    v_transfer_to_gl,
                                                    v_post_in_gl,
                                                    v_include_zero,
                                                    v_security_id_char_1,
                                                    v_security_id_char_2,
                                                    v_security_id_char_3,
                                                    n_secu_id_int_1,
                                                    n_secu_id_int_2,
                                                    n_secu_id_int_3,
                                                    n_concurrent_request_id,
                                                    v_p_include_user_trx_id_flag,
                                                    v_p_include_user_trx_id,
                                                    v_p_debug_flag,
                                                    v_p_user_id,
                                                    v_p_scalable_flag);
      
        dka_tools_pkg.put_debug_message('Valeur de vn_request_id = ' || vn_request_id);
        IF vn_request_id IS NULL THEN
          pn_retcode := 1;
          pv_errbuf  := 'Le traitement d''approbation n''a pas pu être lancé pour la livre  ' ||
                         rec_livre.livre || ' Type de livre FA : ' ||rec_type.book_type_code;
        ELSE
          pn_retcode := 0;
          pv_errbuf  := 'Traitement d''approbation : ' ||
                        TO_CHAR(vn_request_id) || ' lancé sur la livre ' ||
                        rec_livre.livre || ' Type de livre FA : ' ||rec_type.book_type_code;
          dka_tools_pkg.put_debug_message(pv_errbuf);
        
          vn_requests_cnt := vn_requests_cnt + 1;
          va_request_ids(vn_requests_cnt) := vn_request_id;
        
        END IF;
      
        COMMIT;
      
      
    
      WHILE vn_requests_cnt > 0 LOOP
        IF NOT (fnd_concurrent.wait_for_request(va_request_ids(vn_requests_cnt),
                                                15,
                                                0,
                                                vv_phase,
                                                vv_status,
                                                vv_dev_phase,
                                                vv_dev_status,
                                                vv_errbuf)) THEN
          dka_tools_pkg.put_outdebug_message('Traitement numéro ' ||
                                             TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                             ' trop long ou tombé en erreur');
        ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
          dka_tools_pkg.put_debug_message('Traitement numéro ' ||
                                          TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                          ' correctement exécuté');
        END IF;
      
        vn_requests_cnt := vn_requests_cnt - 1;
      END LOOP;
      END LOOP; --rec_type
    END LOOP;--rec_livre
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 2;
    
  END main;
END DKA_SFAACCPB_PKG;
/
SHOW ERRORS
EXIT
