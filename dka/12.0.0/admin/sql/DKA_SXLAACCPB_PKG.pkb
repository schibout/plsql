/*<TOAD_FILE_CHUNK>*/
CREATE OR REPLACE PACKAGE BODY DKA_SXLAACCPB_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET            : DALKIA HELIOS Oracle Applications
  -- NOM         : DKA_SXLAACCPB_PKG.pkb
  -- DESCRIPTION       :
  ---
  --- AUTEUR       : Bastien Delattre (BDE)
  --- DATE DE CREATION : 31/05/2016
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  ---------------------------------------------------------------------------------------------------------------
  --- Date       Qui Description
  --- 16/11/2016 MEG artf2044568 : SPE001 - DKA : Comptabilisation AP
  --  24/11/2016 NBO SPE001 - defect 388 Prise en compte des données AP du jour en erreur  
  --  30/05/2017 OBE artf2161941 : SPE0001 : Prise en compte AP du jour - Sous traitement créer une comptabilisation
  ---------------------------------------------------------------------------------------------------------------
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  
  

/* 
FUNCTION get_create_accounting_lookup(pn_application_id NUMBER, pn_ledger_id NUMBER, pv_code_param VARCHAR2) RETURN VARCHAR2 IS

v_default_value VARCHAR2(100);

BEGIN
	dka_tools_pkg.put_debug_message('application : '||pn_application_id ||' pn_ledger_id: '||pn_ledger_id||' pv_code_param '||pv_code_param);
  SELECT lookup_code 
  into v_default_value
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = pv_code_param
    AND    XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
    AND   XSO.APPLICATION_ID = pn_application_id
    AND   XSO.LEDGER_ID          = pn_ledger_id;
    dka_tools_pkg.put_debug_message('la valeur retournée est : '||v_default_value );

  return v_default_value;
EXCEPTION
    WHEN OTHERS
        THEN
					  dka_tools_pkg.put_debug_message(sqlerrm );

            return null;
END get_create_accounting_lookup;
  
  FUNCTION get_create_accounting_meaning(pn_application_id NUMBER, pn_ledger_id NUMBER, pv_code_param VARCHAR2) RETURN VARCHAR2 IS

v_default_value VARCHAR2(100);

BEGIN
	dka_tools_pkg.put_debug_message('application : '||pn_application_id ||' pn_ledger_id: '||pn_ledger_id||' pv_code_param '||pv_code_param);

  SELECT MEANING 
  into v_default_value
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = pv_code_param
    AND    XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
    AND   XSO.APPLICATION_ID = pn_application_id
    AND   XSO.LEDGER_ID          = pn_ledger_id;
  dka_tools_pkg.put_debug_message('la valeur retournée est : '||v_default_value );
  return v_default_value;
EXCEPTION
    WHEN OTHERS
        THEN
			  dka_tools_pkg.put_debug_message(sqlerrm );

            return null;
END get_create_accounting_meaning;

FUNCTION get_create_accounting_lookup(pn_application_id NUMBER, pn_ledger_id NUMBER, pv_code_param VARCHAR2) RETURN VARCHAR2 IS

v_default_value VARCHAR2(100);

BEGIN
	dka_tools_pkg.put_debug_message('application : '||pn_application_id ||' pn_ledger_id: '||pn_ledger_id||' pv_code_param '||pv_code_param);
  SELECT lookup_code 
  into v_default_value
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = pv_code_param
    AND    XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
    AND   XSO.APPLICATION_ID = pn_application_id
    AND   XSO.LEDGER_ID          = pn_ledger_id;
    dka_tools_pkg.put_debug_message('la valeur retournée est : '||v_default_value );

  return v_default_value;
EXCEPTION
    WHEN OTHERS
        THEN
					  dka_tools_pkg.put_debug_message(sqlerrm );

            return null;
END get_create_accounting_lookup;
   */
  
  
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
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER)
  
   IS
    vn_responsibility_id NUMBER;
    vn_application_id    NUMBER;
    vv_ap_responsibility VARCHAR2(100);
    rec_param            dka_parameters%ROWTYPE;
    vn_request_layout    BOOLEAN;
    vn_request_id        NUMBER;
    vn_approval_org_id   NUMBER;
    vv_phase             VARCHAR2(100);
    vv_status            VARCHAR2(100);
    vv_dev_phase         VARCHAR2(100);
    vv_dev_status        VARCHAR2(100);
    va_request_ids       pa_utils.IdTabTyp; ---Tableau
    vn_requests_cnt      NUMBER;
    vv_errbuf            VARCHAR2(150);
    vv_parameter         dka_parameters.parameter_name%TYPE;
  vn_prog_application_id NUMBER;
    vv_prog_application_short_name VARCHAR2(50);
    vn_program_id        NUMBER;
    --curseur sur le regroupement de factures avec status d'approbation NULL (jamais approuvé)
  
  
  
  
  --paramètres du traitement XLAACCPB
  n_application number;
  n_source_application number;
  n_ledger number;
  v_process_category varchar2(10);
  v_dummy0    varchar2(10);
  d_end_date date;
  v_create_accounting_flag varchar2(10);
  v_dummy1 varchar2(10);
  v_accounting_mode varchar2(10);
  v_dummy2 varchar2(10);
  v_errors_only_flag varchar2(10);
  v_report varchar2(20);
  v_transfer_to_gl_flag varchar2(10);
  v_dummy3 varchar2(10);
  v_gl_batch_name varchar2(10);
  v_mixed_currency_precision varchar2(10);
  v_post_to_gl varchar2(30);
  v_include_zero varchar2(10);
  v_include_zero_flag varchar2(10);
  v_request_id number;
  v_entity_id varchar2(10);
  n_source_application_name varchar2(10);
  v_application_name varchar2(10);
  v_ledger_name varchar2(50);
  v_process_category_n varchar2(10);
  v_create_accounting varchar2(10);
  v_accounting_mode_name varchar2(30);
  v_errors_only varchar2(10);
  v_report_level varchar2(30);
  v_transfer_to_gl varchar2(30);
  v_post_in_gl varchar2(10);
  n_secu_id_int_1 number;
  n_secu_id_int_2 number;
  n_secu_id_int_3 number;
  v_security_id_char_1 varchar2(10);
  v_security_id_char_2 varchar2(10);
  v_security_id_char_3 varchar2(10);
  v_valuation_method varchar2(10);
  v_p_include_user_trx_id_flag varchar2(10);
  v_p_include_user_trx_id varchar2(10);
  v_p_debug_flag varchar2(10);
  v_p_user_id varchar2(10);
  v_p_scalable_flag varchar2(10);
  v_p_launch_balance_program varchar2(10);
  v_p_launch_bal_program varchar2(10);
  n_concurrent_request_id number;
  v_source_application_name varchar2(20);
  v_gl_date DATE; -- OBE artf2161941
  
  
  
    CURSOR cur_approval IS
      /*SELECT DISTINCT aia.org_id, 
                      hou.NAME, 
                      set_of_books_id, 
                      concat(concat(concat(gln.name, ' ('), gln.short_name), ')') ledger_description
        FROM ap_invoices_all aia, hr_all_organization_units hou, gl_ledger_names_v gln
       WHERE aia.org_id = hou.organization_id
         AND aia.set_of_books_id = gln.ledger_id;*/
      SELECT gl.ledger_id set_of_books_id, gl.NAME,
             concat(concat(concat(gl.NAME, ' ('), gl.short_name), ')') ledger_description
        FROM gl_ledgers gl
       WHERE EXISTS (SELECT 1
                FROM xla_events xe
                JOIN xla.xla_transaction_entities xte ON xe.entity_id =
                                                         xte.entity_id
                                                     AND xe.application_id =
                                                         xte.application_id
               WHERE xe.application_id = 200
                 AND xte.ledger_id = gl.ledger_id
                 AND nvl(xe.process_status_code, 'U') <> 'P');

  
  BEGIN
    pn_retcode   := 0;
    pv_errbuf    := NULL;
    vv_parameter := 'AP_RESPONSIBILITY_KEY';
  
    -- Récupération des parametres utilisés par le traitement
    dka_tools_pkg.get_parameter('SXLAACCPB',
                                vv_parameter,
                                rec_param,
                                pn_retcode,
                                pv_errbuf);
    IF pn_retcode != 0 THEN
      pn_retcode := 1;
      RETURN;
    END IF;
    vn_requests_cnt := 0;
    dka_tools_pkg.put_debug_message('Recuperation des identifiants programme');
  
    
  -- Récupération de l'id de l'application et de son nom court
  SELECT fcp.application_id,
           fa.application_short_name,
           fcp.concurrent_program_id
      INTO vn_prog_application_id,
           vv_prog_application_short_name,
           vn_program_id
      FROM fnd_concurrent_programs fcp, fnd_application fa
     WHERE fcp.concurrent_program_name = 'XLAACCPB'
       AND fa.application_id = fcp.application_id;
  

  
    FOR rec_approval IN cur_approval LOOP
  
  
      
    -- Ici on forme le nom de la responsabilité    
    --vn_approval_org_id   := rec_approval.org_id;
    -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
    --vv_ap_responsibility := rec_approval.name || '_' ||
    vv_ap_responsibility := 'TOUT_' ||
                rec_param.varchar2_value;      

    --récupération des variables nécessaires au lancement du traitement
    SELECT fr.responsibility_id, fr.application_id
    INTO vn_responsibility_id, vn_application_id
    FROM fnd_responsibility fr
    WHERE fr.responsibility_key = vv_ap_responsibility; 
    
    
    -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
    fnd_global.apps_initialize(fnd_global.user_id,
                 vn_responsibility_id,
                 vn_application_id);
                 
    -- NBO 24/11/16 - SPE001 - defect 388 Prise en compte des données AP du jour en erreur
    --fnd_request.set_org_id(rec_approval.org_id);
    
    dka_tools_pkg.put_debug_message('initialisation réussie sur la resp:' || vv_ap_responsibility||'   '||fnd_global.user_id ||
                 '   '||vn_responsibility_id ||
                 vn_application_id);
-----------------------------------------------------------------------------------------------------------------------------------------------------    
    --Récupération des valeurs par défaut des paramètres du traitement standard.
	  
	
  
	
	--v_accounting_mode:=get_create_accounting_lookup(vn_application_id,rec_approval.set_of_books_id,'XLA_ACCOUNTING_ENTRY_STATUS');
	--v_transfer_to_gl_flag:=get_create_accounting_lookup(vn_application_id,rec_approval.set_of_books_id,'XLA_YES_NO');
	--v_accounting_mode_name:=get_create_accounting_meaning(vn_application_id,rec_approval.set_of_books_id,'XLA_ACCOUNTING_ENTRY_STATUS');
    --v_report_level:=get_create_accounting_meaning(vn_application_id,rec_approval.set_of_books_id,'XLA_REPORT_LEVEL');
    --v_transfer_to_gl:=get_create_accounting_meaning(vn_application_id,rec_approval.set_of_books_id,'XLA_YES_NO');
    --v_post_in_gl:=get_create_accounting_meaning(vn_application_id,rec_approval.set_of_books_id,'XLA_YES_NO');
	
	-- Récupération des valeurs par défaut 
  dka_tools_pkg.put_debug_message('Récupération des paramètres');
  
	
	SELECT lookup_code 
	into v_accounting_mode
	FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO 
	WHERE XLK.LOOKUP_TYPE = 'XLA_ACCOUNTING_ENTRY_STATUS'
    AND    XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
    AND   XSO.APPLICATION_ID = vn_application_id
    AND   XSO.LEDGER_ID = rec_approval.set_of_books_id;
	
	SELECT lookup_code into v_transfer_to_gl_flag
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
    AND    XLK.LOOKUP_CODE = XSO.SUBMIT_TRANSFER_TO_GL_FLAG
    AND   XSO.APPLICATION_ID = vn_application_id
    AND   XSO.LEDGER_ID = rec_approval.set_of_books_id;
	
	SELECT lookup_code into v_report
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = 'XLA_REPORT_LEVEL'
    AND    XLK.LOOKUP_CODE = XSO.SUMMARY_REPORT_FLAG
	AND   XSO.APPLICATION_ID = vn_application_id
    AND   XSO.LEDGER_ID = rec_approval.set_of_books_id;

	SELECT MEANING into v_report_level
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = 'XLA_REPORT_LEVEL'
    AND    XLK.LOOKUP_CODE = XSO.SUMMARY_REPORT_FLAG
	AND   XSO.APPLICATION_ID = vn_application_id
    AND   XSO.LEDGER_ID = rec_approval.set_of_books_id;

	SELECT MEANING into v_transfer_to_gl
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
    AND    XLK.LOOKUP_CODE = XSO.SUBMIT_TRANSFER_TO_GL_FLAG
	AND   XSO.APPLICATION_ID = vn_application_id
    AND   XSO.LEDGER_ID = rec_approval.set_of_books_id;
	
	SELECT meaning into v_accounting_mode_name
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = 'XLA_ACCOUNTING_ENTRY_STATUS'
    AND    XLK.LOOKUP_CODE = XSO.ACCOUNTING_MODE_CODE
	AND   XSO.APPLICATION_ID = vn_application_id
    AND   XSO.LEDGER_ID = rec_approval.set_of_books_id;
 
	SELECT meaning into v_post_in_gl
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
    AND    XLK.LOOKUP_CODE = XSO.SUBMIT_GL_POST_FLAG
	AND   XSO.APPLICATION_ID = vn_application_id
    AND   XSO.LEDGER_ID = rec_approval.set_of_books_id;
    
	
	SELECT lookup_code into v_post_to_gl
    FROM XLA_LOOKUPS  XLK, XLA_SUBLEDGER_OPTIONS_V   XSO
    WHERE XLK.LOOKUP_TYPE = 'XLA_YES_NO'
    AND    XLK.LOOKUP_CODE = XSO.SUBMIT_GL_POST_FLAG
	AND   XSO.APPLICATION_ID = vn_application_id
    AND   XSO.LEDGER_ID = rec_approval.set_of_books_id;
	
	
    --v_report:=get_create_accounting_lookup(vn_application_id,rec_approval.set_of_books_id,'XLA_REPORT_LEVEL');
	--v_report:='N';
   -- v_post_to_gl:=get_create_accounting_lookup(vn_application_id,rec_approval.set_of_books_id,'XLA_YES_NO');

    
    SELECT MEANING into v_p_launch_bal_program FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'Y';
	SELECT lookup_code into v_create_accounting_flag FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'Y';
	SELECT 'Y' into v_dummy2 FROM DUAL WHERE NVL(v_accounting_mode,'F') = 'F';
    SELECT LOOKUP_CODE into v_errors_only_flag FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'N';
	SELECT meaning into v_p_include_user_trx_id FROM xla_lookups WHERE lookup_type ='XLA_YES_NO' and lookup_code ='N';
    SELECT application_name into v_source_application_name from fnd_application_tl where application_id=fnd_profile.value('resp_appl_id') and language='F';
    SELECT application_name into v_application_name from fnd_application_tl where application_id=fnd_profile.value('resp_appl_id') and language='F';
	
	--SELECT 'Y' into v_dummy3 FROM DUAL WHERE v_transfer_to_gl_flag = 'Y';
    SELECT lookup_code into v_include_zero_flag FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'N';
    SELECT name into v_ledger_name from gl_ledgers where ledger_id=rec_approval.set_of_books_id;
    SELECT MEANING into v_create_accounting FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'Y';
    SELECT MEANING into v_errors_only FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'N';
    SELECT MEANING into v_include_zero FROM XLA_LOOKUPS WHERE LOOKUP_TYPE = 'XLA_YES_NO' AND LOOKUP_CODE = 'N';
    
    
    n_application:= fnd_profile.value('RESP_APPL_ID');
    n_source_application:=fnd_profile.value('RESP_APPL_ID');
    n_ledger:=rec_approval.set_of_books_id;
    v_dummy0:='Y';
    d_end_date:=sysdate;
    v_process_category:=null;
    v_dummy1:='Y';
	  v_dummy3:='Y';
    v_mixed_currency_precision:=null;
    v_gl_batch_name:=null;
    v_request_id:=null;
    v_entity_id:=null;
    v_process_category_n:=null;
    v_p_include_user_trx_id_flag:='N';
    v_p_debug_flag:='N';
    v_p_user_id :=fnd_global.user_id;
    v_p_scalable_flag:='N';
    v_p_launch_balance_program :='Y';
    n_secu_id_int_1:=null;
    n_secu_id_int_2:=null;
    n_secu_id_int_3:=null;
    v_security_id_char_1 :=null;
    v_security_id_char_2 :=null;
    v_security_id_char_3 :=null;
    v_valuation_method:=null;
    v_p_launch_balance_program:='Y';
    n_concurrent_request_id :=null;
    
    --< OBE artf2161941
    SELECT end_date
    INTO v_gl_date
    FROM gl_period_statuses
    WHERE 1=1
    AND TRUNC(sysdate) BETWEEN TRUNC(start_date) AND TRUNC(end_date)
    AND ledger_id      = n_ledger
    AND application_id = 200 ;    
    --> OBE artf2161941    
  
  
 ------------------------------------------------------------------------------------------------------------------------------------------------------    
    --lancement du traitement à l'aide de la fonction FND_REQUEST.SUBMIT_REQUEST
    dka_tools_pkg.put_debug_message ('Soumission du traitement appli = :'||vv_prog_application_short_name ||' short_name: '||vn_program_id);
	
 -- Ajout du template
  vn_request_layout := FND_REQUEST.add_layout('XLA',
                                              'XLAACCPB02',
                                              'fr',
                                              'FR',
                                              'PDF');
                                            
  IF vn_request_layout THEN
    
    vn_request_id    := fnd_request.submit_request (
                              vv_prog_application_short_name, --APPLICATION PROPRIETAIRE DU TRAITEMENT
                              'XLAACCPB', --SHORT_NAME du TRAITEMENT
                              rec_approval.ledger_description, --DESCRIPTION
                              NULL, --START
                              FALSE, --SUB_REQUEST
                              n_application, 
                              n_source_application, 
                              v_dummy0, 
                              n_ledger, 
                              v_process_category, -- Process Category , 
                              TO_CHAR(v_gl_date,'YYYY/MM/DD HH24:MI:SS'), --TO_CHAR (SYSDATE, 'YYYY/MM/DD HH24:MI:SS'), --ARGUMENT6 -- OBE artf2161941
                              v_create_accounting_flag, 
                              v_dummy1, 
                              v_accounting_mode, 
                              v_dummy2, 
                              v_errors_only_flag, 
                              v_report, 
                              v_transfer_to_gl_flag, 
                              v_dummy3, 
                              v_post_to_gl, 
                              v_gl_batch_name, -- GL Batch Name, 
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
                              v_valuation_method, 
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
                              v_p_scalable_flag, 
                              v_p_launch_balance_program, 
                              v_p_launch_bal_program
                          );
              
     dka_tools_pkg.put_debug_message('Valeur de vn_request_id = '||vn_request_id );
        IF vn_request_id IS NULL THEN
          pn_retcode := 1;
          pv_errbuf  := 'Le traitement d''approbation n''a pas pu être lancé pour la société  ' || rec_approval.name;
        ELSE
          pn_retcode := 0;
          pv_errbuf  := 'Traitement d''approbation : ' ||
                        TO_CHAR(vn_request_id) || ' lancé sur la société ' ||
                        rec_approval.name;
          dka_tools_pkg.put_log_message(pv_errbuf);
        
          vn_requests_cnt := vn_requests_cnt + 1;
          va_request_ids(vn_requests_cnt) := vn_request_id;
        
        END IF;
      
        COMMIT;
    
  END IF;
      
    END LOOP;
  
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
        dka_tools_pkg.put_log_message('Traitement numéro ' ||
                                        TO_CHAR(va_request_ids(vn_requests_cnt)) ||
                                        ' correctement exécuté');
      END IF;
      vn_requests_cnt := vn_requests_cnt - 1;
    
    END LOOP;

  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM(SQLCODE);
    --dka_tools_pkg.put_debug_message('ERROR_STACK: ' || DBMS_UTILITY.FORMAT_ERROR_STACK);
    --dka_tools_pkg.put_debug_message('ERROR_BACKTRACE: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);

      pn_retcode := 2;
    
  END main;
  --------------------------------------------------------------------------------------------------------------
END DKA_SXLAACCPB_PKG;
/
/*<TOAD_FILE_CHUNK>*/
SHOW ERROR
EXIT;
