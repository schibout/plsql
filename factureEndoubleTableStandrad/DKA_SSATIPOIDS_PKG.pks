CREATE OR REPLACE PACKAGE BODY DKA_SARRGLTPRLV_CREATION_PKG AS

  ---------------------------------------------------------------------------------------------------------------
  -- NOM               : DKA_SARRGLTPRLV_CREATION_PKG.pkb
  -- DESCRIPTION       : creation des lots de réglement AR
  ---
  --- AUTEUR           : Asma AMENKOUR
  --- DATE DE CREATION : 12/09/2019
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  ---------------------------------------------------------------------------------------------------------------
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  -- 12/09/2019  AAM Creation
  -- 25/06/2020  JWY INC0436342 - Ajout d'une restriction pour ne pas prendre en compte les factures qui font déjà partie d'un lot
  -- 14/07/2021  ARA TASK0147719 - SPE219 - Problème sur le champ DKA_ARLOTREG_TMP.STATUS
  -- 01/04/2022  SHA DPE20210039 - EDB326 - Automatisation des prélèvements clients - Création du règlement par UO-Client-Lieu
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_conc_request_id NUMBER := Fnd_Global.conc_request_id;
  g_package          VARCHAR2(30) := 'DKA_SARRGLTPRLV_CREATION_PKG';
  g_sqlerrm          VARCHAR2(250) := NULL;
  g_retproc          NUMBER := 0;

  vt_traitement mytable;

  vn_traitement  NUMBER := 0;
  vn_indice      NUMBER;
  vv_rphase      VARCHAR2(80);
  vv_rstatus     VARCHAR2(80);
  vv_dphase      VARCHAR2(30);
  vv_dstatus     VARCHAR2(30);
  vv_message     VARCHAR2(240);
  vn_trt_normal  NUMBER := 0;
  vn_trt_erreur  NUMBER := 0;
  vn_trt_warning NUMBER := 0;

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- EXCEPTIONS
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  e_bank_error   EXCEPTION;
  e_prelev_error EXCEPTION;
  e_class_error  EXCEPTION;
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
  ------------------------------------------------------------------------------------
  --  Nom           : DKA_SORTIE_TRAITEMENT
  --  Description   : Ecrit dans la sortie du traitement
  --

  --
  ------------------------------------------------------------------------------------
  PROCEDURE DKA_SORTIE_TRAITEMENT IS
    vn_lots_ok NUMBER := 0;
    vn_lots_ko NUMBER := 0;
  BEGIN

    SELECT count(*)
      INTO vn_lots_ok
      FROM DKA_ARLOTREG_TMP
     WHERE REQUEST_ID = gv_conc_request_id
       AND status = 'OK';

    SELECT count(*)
      INTO vn_lots_ko
      FROM DKA_ARLOTREG_TMP
     WHERE REQUEST_ID = gv_conc_request_id
       AND status = 'KO';
	 

    IF (vn_lots_ok > 0) THEN

      --Statistiques
      writeout('                                             ');
      writeout('Liste des lots crées :');
      writeout('                                             ');
      writeout(RPAD('Organisation', 25) || RPAD('N° client', 30) ||
               RPAD('Nom Client', 50) || RPAD('Lieu', 35)|| -- SHA EDB326
			   RPAD('nom du lot', 35));
      writeout(RPAD('------------', 25) || RPAD('---------', 30) ||
               RPAD('----------', 50) || RPAD('----------', 35)|| -- SHA EDB326
			   RPAD('----------', 35));
      FOR rec_ok IN (SELECT *
                       from DKA_ARLOTREG_TMP
                      where status = 'OK'
                        AND REQUEST_ID = gv_conc_request_id) LOOP
        writeout(RPAD(rec_ok.organisation, 25) ||
                 RPAD(rec_ok.num_client, 30) ||
                 RPAD(rec_ok.nom_client, 50) ||
				 RPAD(rec_ok.lieu, 35) ||
                 RPAD(rec_ok.batch_name, 35));
      END LOOP;

    END IF;

    IF (vn_lots_ko > 0) THEN

      writeout('                                             ');
      writeout('Liste des clients pour lesquelles les lots créés sont vides :');
      writeout('                                             ');
      writeout(RPAD('Organisation', 25) || RPAD('N° client', 30) ||
               RPAD('Nom Client', 50) || RPAD('Lieu', 35)|| -- SHA EDB326
			   RPAD('nom du lot', 35));
      writeout(RPAD('------------', 25) || RPAD('---------', 30) ||
               RPAD('----------', 50) || RPAD('----------', 35)|| -- SHA EDB326
			   RPAD('----------', 35));
      FOR rec_ko IN (SELECT count(batch_id),
                            organisation,
                            num_client,
                            nom_client,
                            batch_name,
                            lieu
                       from DKA_ARLOTREG_TMP
                      where status = 'KO'
                        AND REQUEST_ID = gv_conc_request_id
                      group by organisation,
                               num_client,
                               nom_client,
							   lieu,
                               batch_name) LOOP
        writeout(RPAD(rec_ko.organisation, 25) ||
                 RPAD(rec_ko.num_client, 30) ||
                 RPAD(rec_ko.nom_client, 50) ||
				 RPAD(rec_ko.lieu, 35) ||
                 RPAD(rec_ko.batch_name, 35));
      END LOOP;

    END IF;

  END DKA_SORTIE_TRAITEMENT;
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

    CURSOR cur_fac_eligible(p_due_date date,
                            p_party_id NUMBER,
                            p_code_rum VARCHAR2,
							p_location VARCHAR2) IS
      SELECT hca.ACCOUNT_NUMBER,
             hp.PARTY_NAME,
             rcta.trx_number num_facture,
             TO_CHAR(rcta.TRX_DATE, 'DD/MM/YYYY') TRX_DATE,
             hou.name organisation,
             TO_CHAR(ps.GL_DATE, 'DD/MM/YYYY') GL_DATE,
             ps.amount_due_remaining,
             ps.DUE_DATE DUE_DATE,
             ARM.name mode_reg,
             ida.authorization_reference_number,
             NVL(rcta.ATTRIBUTE5, 'OUI') reg_automatic,
             rcta.ORG_ID

        from hz_cust_accounts         hca,
             ra_customer_trx_all      rcta,
             ar_payment_schedules_all ps,
             hr_operating_units       hou,
             AR_RECEIPT_METHODS       ARM,
             HZ_PARTIES               hp,
             iby_fndcpt_tx_extensions extn,
			 hz_cust_site_uses_all hcsua,
             -----------------------------
             IBY_DEBIT_AUTHORIZATIONS ida

       where 1 = 1
         AND hca.cust_account_id = rcta.BILL_TO_CUSTOMER_ID
         AND hp.PARTY_ID = hca.PARTY_ID
         AND rcta.ORG_ID = hou.organization_id
         AND ps.CUSTOMER_TRX_ID = rcta.CUSTOMER_TRX_ID
         AND ps.amount_due_remaining != 0
         AND ARM.RECEIPT_METHOD_ID = rcta.RECEIPT_METHOD_ID
         AND ARM.NAME = 'PRELEVT'
         AND ps.selected_for_receipt_batch_id IS NULL -- 25/06/2020   JWY INC0436342
            ---------------------------debit authorisation-------------------
         AND rcta.payment_trxn_extension_id = extn.TRXN_EXTENSION_ID
         AND extn.DEBIT_AUTHORIZATION_ID = ida.debit_authorization_id
            ------------------------------------------------------------
         AND NVL(rcta.ATTRIBUTE5, 'OUI') = 'OUI'
         AND HP.PARTY_ID = p_party_id
         AND ida.authorization_reference_number = p_code_rum
            ----------------------Parameters-------------------------
         AND ps.DUE_DATE <= p_due_date
         AND rcta.ORG_ID = P_UO
		 AND hcsua.site_use_id = rcta.bill_to_site_use_id
         AND hcsua.location = p_location
       ORDER BY rcta.trx_number;

    CURSOR cur_client_rlgt(p_due_date date) IS
       SELECT hp.party_id,
             ida.authorization_reference_number,
             rcta.org_id,
             hou.name organisation,
             hca.ACCOUNT_NUMBER,
             hp.PARTY_NAME,
             hcsua.location -- SHA EDB326
        from hz_cust_accounts         hca,
             ra_customer_trx_all      rcta,
             ar_payment_schedules_all ps,
             hr_operating_units       hou,
             AR_RECEIPT_METHODS       ARM,
             HZ_PARTIES               hp,
             iby_fndcpt_tx_extensions extn,
             IBY_DEBIT_AUTHORIZATIONS ida, 
             hz_cust_site_uses_all    hcsua  -- SHA EDB326
       where 1 = 1
         AND hca.cust_account_id = rcta.BILL_TO_CUSTOMER_ID
         AND hp.PARTY_ID = hca.PARTY_ID
         AND rcta.ORG_ID = hou.organization_id
         AND ps.CUSTOMER_TRX_ID = rcta.CUSTOMER_TRX_ID
         AND ps.amount_due_remaining != 0
         AND ARM.RECEIPT_METHOD_ID = rcta.RECEIPT_METHOD_ID
         AND ARM.NAME = 'PRELEVT'
         AND hcsua.site_use_id = rcta.bill_to_site_use_id -- SHA EDB326
         AND ps.selected_for_receipt_batch_id IS NULL -- 25/06/2020   JWY INC0436342		 
            ---------------------------debit authorisation-------------------
         AND rcta.payment_trxn_extension_id = extn.TRXN_EXTENSION_ID
         AND extn.DEBIT_AUTHORIZATION_ID = ida.debit_authorization_id
            ----------------------Parameters-------------------------
         AND ps.DUE_DATE <= p_due_date
         AND rcta.ORG_ID =  P_UO
         AND NVL(rcta.ATTRIBUTE5, 'OUI') = 'OUI'
         
       GROUP BY hp.party_id,
                ida.authorization_reference_number,
                rcta.org_id,
                hou.Name,
                hca.ACCOUNT_NUMBER,
                hp.PARTY_NAME,
                hcsua.location -- SHA EDB326
      HAVING sum(ps.amount_due_remaining) > 0;

    CURSOR cur_client_rlgt_neg(p_due_date date) IS
      SELECT hca.ACCOUNT_NUMBER,
             hp.PARTY_NAME,
             sum(ps.amount_due_remaining) total,
			 hcsua.location -- SHA EDB326 
        from hz_cust_accounts         hca,
             ra_customer_trx_all      rcta,
             ar_payment_schedules_all ps,
             hr_operating_units       hou,
             AR_RECEIPT_METHODS       ARM,
             HZ_PARTIES               hp,
             iby_fndcpt_tx_extensions extn,
             IBY_DEBIT_AUTHORIZATIONS ida,
             hz_cust_site_uses_all    hcsua  -- SHA EDB326
       where 1 = 1
         AND hca.cust_account_id = rcta.BILL_TO_CUSTOMER_ID
         AND hp.PARTY_ID = hca.PARTY_ID
         AND rcta.ORG_ID = hou.organization_id
         AND ps.CUSTOMER_TRX_ID = rcta.CUSTOMER_TRX_ID
         AND ps.amount_due_remaining != 0
         AND ARM.RECEIPT_METHOD_ID = rcta.RECEIPT_METHOD_ID
         AND ARM.NAME = 'PRELEVT'
         AND ps.selected_for_receipt_batch_id IS NULL -- 25/06/2020   JWY INC0436342
		 AND hcsua.site_use_id = rcta.bill_to_site_use_id -- SHA EDB326
            ---------------------------debit authorisation-------------------
         AND rcta.payment_trxn_extension_id = extn.TRXN_EXTENSION_ID
         AND extn.DEBIT_AUTHORIZATION_ID = ida.debit_authorization_id
            ----------------------Parameters-------------------------
         AND ps.DUE_DATE <= p_due_date
         AND rcta.ORG_ID = P_UO
         AND NVL(rcta.ATTRIBUTE5, 'OUI') = 'OUI'
       GROUP BY hca.ACCOUNT_NUMBER, hp.party_name, hcsua.location -- SHA EDB326
      HAVING sum(ps.amount_due_remaining) <= 0;

    v_customer             HZ_PARTIES.PARTY_NAME%type := NULL;
    v_uo                   hr_operating_units.name%type := NULL;
    v_request_id           NUMBER := 0;
    v_batch_applied_status VARCHAR2(300) := NULL;
    v_batch_id             AR_BATCHES_ALL.BATCH_ID%type;
    v_batch_name           AR_BATCHES_ALL.NAME%type;
    gv_ref_date            date;
    v_banque_UO_exist      varchar2(1);
    vn_rglt                NUMBER := 0;
	v_status			   varchar2(4) := NULL; -- ARA
    v_RECEIPT_METHOD_ID    AR_RECEIPT_METHODS.RECEIPT_METHOD_ID%type;
    v_RECEIPT_CLASS_ID     AR_RECEIPT_CLASSES.RECEIPT_CLASS_ID %type;
    v_SET_OF_BOOKS_ID      HR_OPERATING_UNITS.SET_OF_BOOKS_ID%type;
  BEGIN

    gv_ref_date := to_date(p_date, 'YYYY/MM/DD HH24:MI:SS');

    --Vérification de l'existence banque de remise sur l'unité opérationnelle
    BEGIN
      SELECT 1 --CEA.BANK_ACCOUNT_NAME
        INTO v_banque_UO_exist
        FROM AR_RECEIPT_METHODS             arm,
             ar_receipt_method_accounts_all arma,
             CE_BANK_ACCT_USES_ALL          cbaua,
             CE_BANK_ACCOUNTS               CEA
       WHERE ARM.NAME = 'PRELEVT'
         AND ARM.receipt_method_id = ARMA.receipt_method_id
         AND arma.primary_flag = 'Y'
         AND arma.REMIT_BANK_ACCT_USE_ID = cbaua.BANK_ACCT_USE_ID
         AND cbaua.BANK_ACCOUNT_ID = CEA.bank_account_id
         AND arma.org_id = P_UO;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE e_bank_error;
    END;

    FOR clients_rglt_negatif IN cur_client_rlgt_neg(gv_ref_date) LOOP
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        'Avertissement : Somme des mouvements négative ou nulle sur le lieu '||clients_rglt_negatif.location||' du  client ' ||
                        clients_rglt_negatif.account_number || '(' ||
                        clients_rglt_negatif.party_name || ') - Montant ' ||
                        clients_rglt_negatif.total);
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 1;

    END LOOP;

    ---Extraction de RECEIPT_METHOD_ID
    BEGIN
      SELECT RECEIPT_METHOD_ID
        INTO v_RECEIPT_METHOD_ID
        FROM AR_RECEIPT_METHODS
       WHERE NAME = 'PRELEVT';
    EXCEPTION
      WHEN OTHERS THEN
        raise e_prelev_error;
    END;
    ---Extraction de RECEIPT_CLASS_ID
    BEGIN
      SELECT RECEIPT_CLASS_ID
        INTO v_RECEIPT_CLASS_ID
        FROM AR_RECEIPT_CLASSES
       WHERE CREATION_METHOD_CODE = 'AUTOMATIC'
	   and   NAME ='PRELEVEMENT';  --SHA EDB326 Suite à la modification de mostafa ouaden
    EXCEPTION
      WHEN OTHERS THEN
        raise e_class_error;
    END;

    ---Extraction de v_SET_OF_BOOKS_ID
    BEGIN
      SELECT set_of_books_id
        INTO v_SET_OF_BOOKS_ID
        FROM HR_OPERATING_UNITS
       WHERE organization_id = P_UO;
    END;

    FOR IC IN cur_client_rlgt(gv_ref_date) LOOP

      vn_traitement := 0;

      ---Création du batch
      Fnd_File.put_line(Fnd_File.LOG, 'UO : new batch');
      v_batch_id   := AR_BATCHES_S.nextval;
      v_batch_name := DKA_AR_BATCHES_S.nextval;
      Fnd_File.put_line(Fnd_File.LOG, 'v_batch_id' || v_batch_id);

      insert into AR_BATCHES_ALL
        (BATCH_ID,
         LAST_UPDATED_BY,
         LAST_UPDATE_DATE,
         CREATED_BY,
         CREATION_DATE,
         NAME,
         BATCH_DATE,
         GL_DATE,
         TYPE,
         BATCH_SOURCE_ID,
         BATCH_APPLIED_STATUS,
         CURRENCY_CODE,
         RECEIPT_METHOD_ID,
         RECEIPT_CLASS_ID,
         SET_OF_BOOKS_ID,
         ORG_ID)
      values
        (v_batch_id,
         fnd_profile.value('user_id'),
         sysdate,
         fnd_profile.value('user_id'),
         sysdate,
         v_batch_name,
         TRUNC(SYSDATE), --gv_ref_date,
         TRUNC(SYSDATE),
         'CREATION',
         1,
         'STARTED_CREATION',
         'EUR',
         v_RECEIPT_METHOD_ID,
         v_RECEIPT_CLASS_ID,
         v_SET_OF_BOOKS_ID,
         IC.ORG_ID);
      COMMIT;

      INSERT INTO DKA_ARLOTREG_TMP
        (ORG_ID,
         ORGANISATION,
         NUM_CLIENT,
         NOM_CLIENT,
         STATUS,
         BATCH_ID,
         BATCH_NAME,
         REQUEST_ID,
		 lieu)
      VALUES
        (IC.ORG_ID,
         IC.organisation,
         IC.ACCOUNT_NUMBER,
         IC.PARTY_NAME,
         NULL,
         v_batch_id,
         v_batch_name,
         gv_conc_request_id,
		 IC.location);

      Fnd_File.put_line(Fnd_File.LOG,
                        'Le lot ayant l''id' || v_batch_id ||
                        'a été bien crée');
      dbms_output.put_line('Le lot ayant l''id' || v_batch_id ||
                           'a été bien crée');

      FOR rec_fac_eligible IN cur_fac_eligible(gv_ref_date,
                                               IC.party_id,
                                               IC.authorization_reference_number,
											   IC.location) LOOP

        Fnd_File.put_line(Fnd_File.LOG,
                          'Affectation des factues au batch crée');
        Fnd_File.put_line(Fnd_File.LOG,
                          'facture n° : ' || rec_fac_eligible.num_facture);

        --Affectation des factues au batch crée
        ARP_PROCESS_BOE.create_auto_batch_conc_req(p_create_flag          => 'Y',
                                                   p_approve_flag         => 'N',
                                                   p_format_flag          => 'N',
                                                   p_batch_id             => v_batch_id,
                                                   p_due_date_low         => NULL,
                                                   p_due_date_high        => gv_ref_date,
                                                   p_trx_date_low         => NULL,
                                                   p_trx_date_high        => NULL,
                                                   p_trx_number_low       => rec_fac_eligible.num_facture,
                                                   p_trx_number_high      => rec_fac_eligible.num_facture,
                                                   p_document_number_low  => NULL,
                                                   p_document_number_high => NULL,
                                                   p_customer_number_low  => rec_fac_eligible.ACCOUNT_NUMBER,
                                                   p_customer_number_high => rec_fac_eligible.ACCOUNT_NUMBER,
                                                   p_customer_name_low    => NULL,
                                                   p_customer_name_high   => NULL,
                                                   p_customer_id          => NULL,
                                                   p_location_low         => IC.location,
                                                   p_location_high        => IC.location,
                                                   p_site_use_id          => NULL,
                                                   p_billing_number_low   => NULL,
                                                   p_billing_number_high  => NULL,
                                                   p_request_id           => v_request_id,
                                                   p_batch_applied_status => v_batch_applied_status,
                                                   p_module_name          => NULL,
                                                   p_module_version       => NULL,
                                                   p_bank_account_low     => NULL,
                                                   p_bank_account_high    => NULL);
        COMMIT;

        vn_traitement := vn_traitement + 1;
        vt_traitement(vn_traitement).request_id := v_request_id;

        Fnd_File.put_line(Fnd_File.LOG, 'UO : receipts attatched');
        v_customer := rec_fac_eligible.PARTY_NAME;
        v_uo       := rec_fac_eligible.organisation;
        dbms_output.put_line('v_request_id : ' || v_request_id);

      END LOOP;

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
            --   writeout ('>>> Traitement '||vt_traitement(vn_indice).request_id||' termine normalement');
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

      SELECT count(*)
        into vn_rglt
        FROM ar_batches_all           aba,
             ra_customer_trx_all      rcta,
             ar_payment_schedules_all apsa,
             hr_operating_units       hou
       WHERE aba.batch_id = apsa.selected_for_receipt_batch_id
         AND apsa.customer_trx_id = rcta.customer_trx_id
         AND aba.org_id = hou.organization_id
         AND aba.batch_id = v_batch_id;

      IF (vn_rglt = 0) THEN
	  
		v_status := 'KO';
		
        IF (nvl(pn_retcode, 0) = 0) THEN
          pn_retcode := 1;
        END IF;
		
	  --ARA 
	  ELSIF (vn_rglt > 0) THEN
	  
		v_status := 'OK';
		
      END IF;

      UPDATE DKA_ARLOTREG_TMP
         SET status = v_status -- vn_rglt ARA
       WHERE batch_id = v_batch_id
         AND request_id = gv_conc_request_id;

      IF (vn_trt_warning > 0 OR vn_trt_erreur > 0) THEN
        pn_retcode := 1;
      END IF;

    END LOOP;

    Fnd_File.put_line(Fnd_File.LOG,
                      'Appel à la procedure de sortie de traitemnt');
    DKA_SORTIE_TRAITEMENT;
  EXCEPTION
    WHEN e_bank_error THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        'Aucune banque de remise n''est paramétrée sur cette unité opérationnelle');
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 1;
    WHEN e_prelev_error THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        'Le mode de reglement PRELEVT n''existe pas');
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 2;
    WHEN e_class_error THEN
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,
                        'La classe de règlement AUTOMATIC n''existe pas');
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 2;
    WHEN OTHERS THEN
      pv_errbuf  := SQLERRM(SQLCODE);
      pn_retcode := 2;
  END main;

END DKA_SARRGLTPRLV_CREATION_PKG;
/
SHOW ERROR
EXIT;
