CREATE OR REPLACE PACKAGE BODY DKA_SARRGLTPRLV_CONFIRM_PKG AS

  ---------------------------------------------------------------------------------------------------------------
  -- NOM               : DKA_SARRGLTPRLV_CONFIRM_PKG.pkb
  -- DESCRIPTION       : Confirmation des lots de réglement AR
  ---
  --- AUTEUR           : Asma AMENKOUR
  --- DATE DE CREATION : 24/09/2019
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  ---------------------------------------------------------------------------------------------------------------
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  -- 24/09/2019   AAM Creation
  -- 25/06/2020   JWY INC0436342 - Correction d'un bug lorsque le lot est crée puis confirmé deux jours différents 
  -- 01/04/2022  SHA DPE20210039 - EDB326 - Automatisation des prélèvements clients - Création du règlement par UO-Client-Lieu
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  g_package VARCHAR2(30) := 'DKA_SARRGLTPRLV_CONFIRM_PKG';
  g_sqlerrm VARCHAR2(250) := NULL;
  g_retproc NUMBER := 0;

  g_user_id  NUMBER := fnd_global.USER_ID;
  g_login_id NUMBER := fnd_global.LOGIN_ID;

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
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  /*============================================================================*/
  /* Procedure         : writeout                                               */
  /* Description       : Ecriture dans fichier *.OUT                            */
  /* Parametres entree : P_message IN VARCHAR2 : message a ecrire               */
  /*                   : P_av      IN NUMBER   : Nb de saut de ligne avant      */
  /*                   : P_ap      IN NUMBER   : Nb de saut de ligne apres      */
  /* Parametres sortie : AUCUN                                                  */
  /* Remarques         :                                                        */
  /*============================================================================*/
  PROCEDURE writeout(P_message IN VARCHAR2) IS
    L_procedure VARCHAR2(30) := 'writeout';
    L_message   VARCHAR2(100);
  BEGIN
  
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);
    FND_FILE.PUT_LINE(FND_FILE.LOG, P_message);
  
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
  /* Fonction          : launch_prog_cofirm                                  */
  /* Description       : Lancer le programme 'AR_AUTORECAPI'   */
  /*============================================================================*/
  PROCEDURE launch_prog_confirm(p_batch_id IN NUMBER) IS
    l_procedure VARCHAR2(30) := 'launch_prog_confirm';
    l_message   VARCHAR2(2000);
  
    err_launch_request  EXCEPTION;
    err_request_warning EXCEPTION;
    err_request_error   EXCEPTION;
    l_application_code VARCHAR2(50) := 'AR';
    l_conc_program     VARCHAR2(50) := 'AR_AUTORECAPI';
  
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
                                                'RECEIPT',
                                                null,
                                                null,
                                                'N',
                                                'Y',
                                                'N', -- format_flag
                                                to_char(p_batch_id),
                                                'N',
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null,
                                                null);
  
    vn_traitement := vn_traitement + 1;
    vt_traitement(vn_traitement).request_id := vn_request_id;
    COMMIT;
  
    IF vn_request_id = 0 THEN
      DBMS_OUTPUT.PUT_LINE('Impossible de lancer le Traitement ');
    END IF;
  
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
    
  END launch_prog_confirm;
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
                 P_UO       IN VARCHAR2,
                 P_DATE     IN VARCHAR2) IS
    proc_err EXCEPTION;
    l_procedure VARCHAR2(40) := 'MAIN';
  
    vn_rglt NUMBER := 0;
  
    CURSOR cur_batch(p_due_date date) IS
      SELECT aba.batch_id,
             aba.org_id,
             aba.name,
             aba.BATCH_APPLIED_STATUS,
             aba.batch_date
        FROM ar_batches_all aba, ar_receipt_methods arm
       WHERE aba.type = 'CREATION'
         AND aba.BATCH_APPLIED_STATUS IN
             ('COMPLETED_CREATION', 'COMPLETED_FORMAT')
         AND aba.receipt_method_id = arm.receipt_method_id
         AND arm.name = 'PRELEVT'
         AND aba.batch_date <= p_due_date
         AND aba.ORG_ID = P_UO
       ORDER BY batch_id;
  
    CURSOR listeReglements(p_request_id number) IS
      SELECT distinct arca.cash_receipt_id , arca.customer_site_use_id
        FROM ar_cash_receipts_all    arca,
             ar_batches_all          aba,
             fnd_concurrent_requests fcr
       WHERE arca.creation_date > sysdate - 1
         AND arca.request_id = fcr.request_id
         AND fcr.argument7 = aba.batch_id
         AND fcr.request_id = p_request_id;
  
    gv_ref_date date;
    v_lieu_reglement hz_cust_site_uses_all.location%type;
    v_lieu_facture hz_cust_site_uses_all.location%type;
    v_site_use_id      hz_cust_site_uses_all.site_use_id%type;
	
  BEGIN
    Fnd_File.put_line(Fnd_File.LOG, 'Debut du traitement');
    gv_ref_date := to_date(p_date, 'YYYY/MM/DD HH24:MI:SS');
  
    Fnd_File.put_line(Fnd_File.LOG,
                      'Date de reference : ' ||
                      to_char(gv_ref_date, 'DD/MM/YYYY'));
  
    FOR rec_batch IN cur_batch(gv_ref_date) LOOP
    
      -- 25/06/2020   JWY INC0436342
      UPDATE AR_BATCHES_ALL
         SET BATCH_DATE        = trunc(sysdate),
             GL_DATE           = trunc(sysdate),
             last_update_date  = sysdate,
             last_updated_by   = g_user_id,
             last_update_login = g_login_id
       WHERE BATCH_ID = rec_batch.batch_id;
      
      vn_trt_a_lancer := vn_trt_a_lancer + 1;
    
      Fnd_File.put_line(Fnd_File.LOG,
                        'Lancement trt confirmation, batch_id : ' ||
                        rec_batch.batch_id);
    
      launch_prog_confirm(rec_batch.batch_id);
    
      writeout('TRAITEMENT ' || vn_request_id || ' : Lot ' ||
               rec_batch.name || '(id : ' || rec_batch.batch_id || ')');
    
      vn_trt_lances := vn_trt_lances + 1;
    END LOOP;
  
    -----------------------------------------------
    -- Attente de la fin de tous les traitements --
    -----------------------------------------------
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
                   ' termine en Warning ');
          vn_trt_warning := vn_trt_warning + 1;
        ELSIF vv_dstatus != 'NORMAL' THEN
          writeout('>>> Traitement ' || vt_traitement(vn_indice).request_id ||
                   ' termine en Erreur ');
          vn_trt_erreur := vn_trt_erreur + 1;
        END IF;
      END IF;
    
    END LOOP;
  
    -- Verification de la creation de règlements
    FOR vn_indice IN 1 .. vn_traitement LOOP
    
      vn_rglt := 0;
    
      FOR IC IN listeReglements(vt_traitement(vn_indice).request_id) LOOP
	    -- DEBUT SHA EDB326  
		
		BEGIN
		select distinct hcsua.site_use_id
         into   v_site_use_id 
		 from HZ_CUST_SITE_USES_ALL hcsua , ra_customer_trx_all rcta ,AR_RECEIVABLE_APPLICATIONS_ALL apsa 
         where hcsua.site_use_id = rcta.bill_to_site_use_id 
         and apsa.APPLIED_CUSTOMER_TRX_ID = rcta.CUSTOMER_TRX_ID
		 and apsa.cash_receipt_id = IC.cash_receipt_id; 
		  EXCEPTION WHEN OTHERS THEN
		  v_site_use_id := IC.customer_site_use_id ;
		  writeout(CHR(10) ||
                 'ERREUR : ECHEC DE LA RECUPARATION DU SITE_USE_ID SUR LES FACTURES DU REGLEMENT');

		  pn_retcode := 1;
		  
		END;
	    
		IF IC.customer_site_use_id != v_site_use_id then 
		Fnd_File.put_line(Fnd_File.LOG,'Correction du lieu '||IC.customer_site_use_id||' par '|| v_site_use_id || ' pour le cash_receipt_id '||IC.cash_receipt_id); 
        UPDATE ar_cash_receipts_all
           SET
		       customer_site_use_id = v_site_use_id ,
               last_update_date  = sysdate,
               last_updated_by   = g_user_id,
               last_update_login = g_login_id
         WHERE cash_receipt_id = IC.cash_receipt_id;
       
		END IF ;
		 -- FIN SHA EDB326
		UPDATE AR_PAYMENT_SCHEDULES_ALL
           SET DUE_DATE          = TRUNC(gv_ref_date),
               last_update_date  = sysdate,
               last_updated_by   = g_user_id,
               last_update_login = g_login_id
         WHERE cash_receipt_id = IC.cash_receipt_id;
      
        vn_rglt := vn_rglt + SQL%ROWCOUNT;
      END LOOP;
      
      IF (vn_rglt = 0) THEN
        writeout(CHR(10) ||
                 'ERREUR : Aucun règlement n''a été créé par le traitement ' || vt_traitement(vn_indice).request_id || '.');
        pn_retcode := 1;
      END IF;
    
    END LOOP;
  
    IF (vn_trt_warning > 0 OR vn_trt_erreur > 0) THEN
      Fnd_File.put_line(Fnd_File.LOG,
                        'Présence de traitements en erreur ou avertissement');
      pn_retcode := 1;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG, 'Procedure main : ' || SQLERRM);
      pn_retcode := 2;
      pv_errbuf  := SQLERRM(SQLCODE);
    
  END main;

END DKA_SARRGLTPRLV_CONFIRM_PKG;
/
SHOW ERROR
EXIT;
