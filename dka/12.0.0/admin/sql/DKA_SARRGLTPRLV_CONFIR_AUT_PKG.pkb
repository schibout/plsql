CREATE OR REPLACE PACKAGE BODY DKA_SARRGLTPRLV_CONFIR_AUT_PKG AS

  ---------------------------------------------------------------------------------------------------------------
  -- NOM               : DKA_SARRGLTPRLV_CONFIR_AUT_PKG.pkb
  -- DESCRIPTION       : Lancement du traitement confirmation des lots de réglement AR
  ---
  --- AUTEUR           : Asma AMENKOUR
  --- DATE DE CREATION : 01/10/2019
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  ---------------------------------------------------------------------------------------------------------------
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  -- 01/10/2019   AAM Creation

  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_conc_program_id NUMBER := Fnd_Global.conc_program_id;
  gv_conc_request_id NUMBER := Fnd_Global.conc_request_id;
  gv_prog_appl_id    NUMBER := Fnd_Global.prog_appl_id;
  gv_RESP_NAME       VARCHAR2(100) := fnd_global.RESP_NAME;
  g_package          VARCHAR2(50) := 'DKA_SARRGLTPRLV_CONFIRM_AUT_PKG';
  g_nom_traitement   FND_CONCURRENT_PROGRAMS_VL.USER_CONCURRENT_PROGRAM_NAME%TYPE;
  g_sqlerrm          VARCHAR2(250) := NULL;
  g_retproc          NUMBER := 0;

  vt_traitement mytable;

  vn_traitement        NUMBER := 0;
  vn_indice            NUMBER;
  vn_request_id        NUMBER(15);
  vv_rphase            VARCHAR2(80);
  vv_rstatus           VARCHAR2(80);
  vv_dphase            VARCHAR2(30);
  vv_dstatus           VARCHAR2(30);
  vv_message           VARCHAR2(240);
  vn_trt_a_lancer      NUMBER := 0;
  vn_trt_lances        NUMBER := 0;
  vn_trt_normal        NUMBER := 0;
  vn_trt_erreur        NUMBER := 0;
  vn_trt_warning       NUMBER := 0;
  vn_trt_avertissement NUMBER := 0;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- EXCEPTIONS
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
  e_date_error EXCEPTION;
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  /*============================================================================*/
  /* Procedure         : writeout                                               */
  /* Description       : Ecriture dans fichier *.OUT                            */
  /* Parametres entree : P_message IN VARCHAR2 : message a ecrire               */
  /* Parametres sortie : AUCUN                                                  */
  /* Remarques         :                                                        */
  /*============================================================================*/
  PROCEDURE writeout(P_message IN VARCHAR2) IS
    I           NUMBER := 0;
    L_procedure VARCHAR2(30) := 'writeout';
    L_message   VARCHAR2(100);
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
      Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || L_message);
      Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || G_sqlerrm);
  END writeout;
  /*============================================================================*/
  /* Fonction          : launch_prog_confirmation                                  */
  /* Description       : Lancer le programme 'DKA_ARLOTREG'   */
  /*============================================================================*/
  PROCEDURE launch_prog_confirmation(p_uo IN NUMBER, p_date IN VARCHAR2) IS
    l_procedure VARCHAR2(30) := 'launch_prog_confirmation';
    l_message   VARCHAR2(2000);
  
    err_launch_request  EXCEPTION;
    err_request_warning EXCEPTION;
    err_request_error   EXCEPTION;
    l_request_id       NUMBER;
    l_application_code VARCHAR2(50) := 'DKA';
    l_conc_program     VARCHAR2(50) := 'DKA_ARCONFIRMLOT';
    l_execute_code     BOOLEAN;
    l_req_interval     NUMBER := 30;
    l_req_max_wait     NUMBER := 999999;
    l_req_ret_code     NUMBER;
    l_req_phase        VARCHAR2(255);
    l_req_status       VARCHAR2(255);
    l_req_dev_phase    VARCHAR2(255);
    l_req_dev_status   VARCHAR2(255);
    l_req_message      VARCHAR2(255);
  
  BEGIN
    l_message := l_procedure || '- 01 - Debut';
    Fnd_File.put_line(Fnd_File.LOG, l_message);
  
    l_message := l_procedure || '- 02 - Submit Request';
    Fnd_File.put_line(Fnd_File.LOG, l_message);
    vn_request_id := FND_REQUEST.submit_request(l_application_code,
                                                l_conc_program,
                                                '',
                                                SYSDATE,
                                                FALSE,
                                                p_uo,
                                                p_date);
  
    vn_traitement := vn_traitement + 1;
    vt_traitement(vn_traitement).request_id := vn_request_id;
    COMMIT;
  
    IF vn_request_id = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Impossible de lancer le Traitement ');
    END IF;
  
    /*
    IF l_request_id != 0 THEN
        l_message := l_procedure||'- 03 - Attente fin traitement';
         dbms_output.put_line('v_request_id : ' || l_request_id);
        Fnd_File.put_line(Fnd_File.LOG,l_message);
        l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST( REQUEST_ID => l_request_id
                                                         , INTERVAL   => l_req_interval
                                                         , MAX_WAIT   => l_req_max_wait
                                                         , PHASE      => l_req_phase
                                                         , STATUS     => l_req_status
                                                         , DEV_PHASE  => l_req_dev_phase
                                                         , DEV_STATUS => l_req_dev_status
                                                         , MESSAGE    => l_req_message
                                                         );
    
        IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
            l_message := l_procedure||'- 04a - Traitement terminé en avertissement';
            RAISE err_request_warning;
        ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
            l_message := l_procedure||'- 04b - Traitement terminé en erreur';
            RAISE err_request_error;
        ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'NORMAL' THEN
            l_message := l_procedure||'- 04b - Traitement terminé normal';
            Fnd_File.put_line(Fnd_File.LOG,l_message);
        END IF;
    ELSE
        dbms_output.put_line('Erreur lors du lancement du traitement');
        l_message := l_procedure||'- 03 - Erreur lors du lancement du traitement';
        RAISE err_launch_request;
    END IF;
    l_message := l_procedure||'- xx - Fin';
    Fnd_File.put_line(Fnd_File.LOG,l_message);
    dbms_output.put_line('- xx - Fin');
    g_retproc := 0; */
  
  EXCEPTION
    WHEN err_request_warning THEN
      g_retproc := 1;
      g_sqlerrm := substr(sqlerrm, 1, 500);
      Fnd_File.put_line(Fnd_File.LOG,
                        '-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || g_package);
      Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || l_procedure);
      Fnd_File.put_line(Fnd_File.LOG, 'Exception : ERR_REQUEST_WARNING');
      Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || l_message);
      Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || g_sqlerrm);
      Fnd_File.put_line(Fnd_File.LOG,
                        '------------------------------------------------');
    WHEN err_request_error THEN
      g_retproc := 2;
      g_sqlerrm := substr(sqlerrm, 1, 500);
      Fnd_File.put_line(Fnd_File.LOG,
                        '-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || g_package);
      Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || l_procedure);
      Fnd_File.put_line(Fnd_File.LOG, 'Exception : ERR_REQUEST_ERROR');
      Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || l_message);
      Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || g_sqlerrm);
      Fnd_File.put_line(Fnd_File.LOG,
                        '------------------------------------------------');
    WHEN err_launch_request THEN
      g_retproc := 2;
      g_sqlerrm := substr(sqlerrm, 1, 500);
      Fnd_File.put_line(Fnd_File.LOG,
                        '-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || g_package);
      Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || l_procedure);
      Fnd_File.put_line(Fnd_File.LOG, 'Exception : ERR_LAUNCH_REQUEST');
      Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || l_message);
      Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || g_sqlerrm);
      dbms_output.put_line('Cause     : ' || g_sqlerrm);
      Fnd_File.put_line(Fnd_File.LOG,
                        '------------------------------------------------');
    WHEN OTHERS THEN
      g_retproc := 2;
      g_sqlerrm := substr(sqlerrm, 1, 500);
      Fnd_File.put_line(Fnd_File.LOG,
                        '-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || g_package);
      Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || l_procedure);
      Fnd_File.put_line(Fnd_File.LOG, 'Exception : OTHERS');
      Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || l_message);
      Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || g_sqlerrm);
      Fnd_File.put_line(Fnd_File.LOG,
                        '------------------------------------------------');
    
  END launch_prog_confirmation;
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER,
                 P_DATE     IN VARCHAR2
                 
                 ) IS
  
    CURSOR cur_uo(p_due_date date) IS
    /*   SELECT  distinct hou.name organisation,
                        rcta.ORG_ID
    
                 from hz_cust_accounts hca,
                      ra_customer_trx_all  rcta,
                      ar_payment_schedules_all ps,
                      hr_operating_units hou,
                      AR_RECEIPT_METHODS ARM,
                      HZ_PARTIES hp,
                      iby_fndcpt_tx_extensions extn,
                      -----------------------------
                      IBY_DEBIT_AUTHORIZATIONS ida
    
                 where 1                              = 1
                   AND hca.cust_account_id            = rcta.BILL_TO_CUSTOMER_ID
                   AND hp.PARTY_ID                     = hca.PARTY_ID
                   AND rcta.ORG_ID                    = hou.organization_id
                   AND ps.CUSTOMER_TRX_ID             =rcta.CUSTOMER_TRX_ID
                   AND ps.amount_due_remaining > 0
                   AND ARM.RECEIPT_METHOD_ID          = rcta.RECEIPT_METHOD_ID
                   AND ARM.NAME='PRELEVT'
                  ---------------------------debit authorisation-------------------
                   AND rcta.payment_trxn_extension_id = extn.TRXN_EXTENSION_ID
                   AND extn.DEBIT_AUTHORIZATION_ID    = ida.debit_authorization_id
    
                  ----------------------Parameters-------------------------
                   AND ps.DUE_DATE <= p_due_date
    
    
                 ORDER BY rcta.ORG_ID
                   ;
               */
      SELECT distinct aba.org_id, hou.name organisation
        FROM ar_batches_all     aba,
             hr_operating_units hou,
             ar_receipt_methods arm
       WHERE aba.type = 'CREATION'
         AND aba.BATCH_APPLIED_STATUS IN
             ('COMPLETED_CREATION', 'COMPLETED_FORMAT')
         AND aba.receipt_method_id = arm.receipt_method_id
         AND arm.name = 'PRELEVT'
         AND aba.batch_date <= p_due_date
         AND aba.org_id = hou.organization_id
       ORDER BY aba.org_id;
  
    v_request_id             NUMBER := 0;
    cv_line                  VARCHAR2(500);
    v_conc_program_name      fnd_concurrent_programs.concurrent_program_name%type;
    v_user_conc_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%type;
    gv_ref_date              date;
    vn_responsibility_id     NUMBER(15);
    vn_application_id        NUMBER(15);
    vn_user_id               NUMBER(15);
  
  BEGIN
  
    BEGIN
      gv_ref_date := to_date(p_date, 'YYYY/MM/DD HH24:MI:SS');
    
    EXCEPTION
      WHEN OTHERS THEN
        raise e_date_error;
    END;
  
    writeout('------ Lancement des traitements de création de lots de règlement ------' ||
             CHR(10));
  
    FOR rec_uo IN cur_uo(gv_ref_date) LOOP
      Fnd_File.put_line(Fnd_File.LOG, 'entree de la boucle');
      Fnd_File.put_line(Fnd_File.LOG, 'rec_uo.org_id :' || rec_uo.org_id);
    
      BEGIN
        SELECT fresp.responsibility_id, fresp.application_id
          INTO vn_responsibility_id, vn_application_id
          FROM fnd_responsibility_tl fresp
         WHERE 1 = 1
           AND fresp.responsibility_name like
               rec_uo.organisation || '_AR_ADMINISTRATEUR'
           AND fresp.language = 'F';
      END;
    
      vn_user_id := fnd_profile.value('user_id');
      Fnd_File.put_line(Fnd_File.LOG, 'user_id :' || vn_user_id);
      Fnd_File.put_line(Fnd_File.LOG,
                        'vn_application_id :' || vn_application_id);
    
      fnd_global.apps_initialize(vn_user_id,
                                 vn_responsibility_id,
                                 vn_application_id);
      MO_GLOBAL.INIT('AR');
    
      Fnd_File.put_line(Fnd_File.LOG,
                        'Lancement de traitement de confirmation des Lots');
    
      vn_trt_a_lancer := vn_trt_a_lancer + 1;
      launch_prog_confirmation(rec_uo.org_id, p_date);
    
      writeout('TRAITEMENT ' || vn_request_id || ' : UO ' ||
               rec_uo.organisation || '(id : ' || rec_uo.org_id || ')');
      vn_trt_lances := vn_trt_lances + 1;
    
    END LOOP;
  
    writeout(CHR(10) ||
             '------ Traitements en erreur / avertissement ------' ||
             CHR(10));
  
    FOR vn_indice IN 1 .. vn_traitement LOOP
      IF NOT Fnd_Concurrent.wait_for_request(vt_traitement(vn_indice).request_id,
                                             20,
                                             0,
                                             vv_rphase,
                                             vv_rstatus,
                                             vv_dphase,
                                             vv_dstatus,
                                             vv_message) THEN
        writeout(CHR(10) || '>>> Traitement ' || vt_traitement(vn_indice).request_id ||
                 ' termine en Warning');
      ELSE
        IF vv_dstatus = 'NORMAL' THEN
          --writeout ('>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
          vn_trt_normal := vn_trt_normal + 1;
        ELSIF vv_dstatus = 'WARNING' THEN
          writeout('>>> Traitement ' || vt_traitement(vn_indice).request_id ||
                   ' termine en Avertissement ');
          vn_trt_warning := vn_trt_warning + 1;
        ELSIF vv_dstatus != 'NORMAL' THEN
          writeout('>>> Traitement ' || vt_traitement(vn_indice).request_id ||
                   ' termine en Erreur ');
          vn_trt_erreur := vn_trt_erreur + 1;
        END IF;
      END IF;
    
      IF (vn_trt_warning > 0 OR vn_trt_erreur > 0) THEN
        pn_retcode := 1;
      END IF;
    END LOOP;
  
  EXCEPTION
    WHEN e_date_error THEN
      Fnd_File.put_line(Fnd_File.LOG,
                        'Problème avec la date saisie en paramètre "' ||
                        P_DATE || '" - ' || SQLERRM(SQLCODE));
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 2;
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 2;
    
  END main;

END DKA_SARRGLTPRLV_CONFIR_AUT_PKG;
/
SHOW ERROR
EXIT;
