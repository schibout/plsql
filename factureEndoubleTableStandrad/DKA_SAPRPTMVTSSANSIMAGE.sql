SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(100);

DECLARE
	vv_uo	                       VARCHAR2 (20)   := '&&2';
	vv_org	                       VARCHAR2 (20)   := '&&3';
	
	l_return_status                VARCHAR2(1);
    l_msg_count                    NUMBER;
    l_msg_data                     VARCHAR2(240);
    l_count                        NUMBER;
    l_cash_receipt_id              NUMBER;
    l_msg_data_out                 VARCHAR2(240);
    l_mesg                         VARCHAR2(240);
    p_count                        NUMBER;
    vn_user_id                     VARCHAR2(240);
    vn_appl_id                     NUMBER;
    vn_resp_id                     NUMBER;
    vn_org_id                      NUMBER;
    v_return_status                VARCHAR2(30);
    vn_receipt_method              NUMBER;
    v_msg_count                    NUMBER;
    v_msg_data                     VARCHAR2(2000);
    v_attribute_rec                ar_receipt_api_pub.attribute_rec_type;
    v_cr_id                        NUMBER;
    v_commit                       VARCHAR2(1);
    l_message_api                  VARCHAR2(240);
    l_index                        NUMBER := 0;
    v_comments                     VARCHAR2(1900);
    vn_date_gl                     VARCHAR2(240);
    vv_new_num_reg                 VARCHAR2(240);
    vv_receipt_method_name         VARCHAR2(240);
    vv_party_id                    NUMBER;
    vv_party_site_id               NUMBER;
    vv_receivables_trx_id          NUMBER;
    vv_customer_trx_id             NUMBER;
    vv_cash_receipt_id             NUMBER;
    v_receipt_id                   ar_receivable_applications_all.cash_receipt_id%TYPE;
    v_receipt_number               ar_cash_receipts_all.receipt_number%TYPE;
    v_applied_payment_schedule_id  ar_receivable_applications_all.applied_payment_schedule_id%TYPE;
    v_msg_index_out                NUMBER(10);
    v_application_ref_type         ar_receivable_applications.application_ref_type%TYPE;
    v_application_ref_id           ar_receivable_applications.application_ref_id%TYPE;
    v_application_ref_num          ar_receivable_applications.application_ref_num%TYPE;
    v_secondary_application_ref_id ar_receivable_applications.secondary_application_ref_id%TYPE;
    v_receivable_application_id    ar_receivable_applications.receivable_application_id%TYPE;
    v_receivables_trx_id           ar_receivables_trx_all.receivables_trx_id%TYPE;
    vn_date                        VARCHAR2(24);
    vn_cptt                        NUMBER;
    pn_bank_account_num            VARCHAR2(240);
    pn_EXT_BANK_ACCOUNT_ID         NUMBER;
    vn_receipt_number              VARCHAR2(240);
    vn_amount                      number;
  
	vv_receipt_method_id           ar_receipt_methods.receipt_method_id%TYPE;
	vv_customer_id             ar_payment_schedules_all.customer_id%TYPE; 
	vv_customer_site_use_id      ar_payment_schedules_all.customer_site_use_id%TYPE;
	vv_org_id                  hr_operating_units.organization_id%TYPE;
	vv_gl_date                 DATE ;--ar_payment_schedules_all.gl_date%TYPE;
	vv_due_date              DATE;--ar_payment_schedules_all.due_date%TYPE;
	
	vv_errbuf                        VARCHAR2 (500) := NULL;
    vn_retcode                       NUMBER         := 0;
	
	vn_responsibility_id             NUMBER (20);
	vv_status						 VARCHAR2(20);
	vn_application_id                NUMBER (20);
	
	p_msg_data             VARCHAR2(32000);
    p_status               VARCHAR2(30);
    pn_status              VARCHAR2(30);
	


	  CURSOR c1 (p_uo IN VARCHAR2) IS
      SELECT dara.* 
	  FROM dka_ar_remboursement_avoirs dara , DKA_ARREMB_REPORTING dar
	  WHERE dara.num_avoir = dar.num_avoir
	  AND dara.uo = dar.uo
	  and dar.apply_flag = 'Y'
	  and dara.uo = p_uo;
	
BEGIN	

    DBMS_OUTPUT.PUT_LINE('vv_uo : ' || vv_uo);
	
	FOR rec in c1(vv_org) LOOP
	
	BEGIN
	
	SELECT rcta.customer_trx_id , rcta.org_id
	 INTO vv_customer_trx_id , vn_org_id
	 FROM ra_customer_trx_all       rcta,
		   ar_payment_schedules_all  ps,
		   ra_cust_trx_types_all   rctta
	 WHERE rcta.cust_trx_type_id = rctta.cust_trx_type_id
	 AND rcta.cust_trx_type_id = rctta.cust_trx_type_id
	 AND ps.customer_trx_id = rcta.customer_trx_id
	 AND ps.class = 'CM'
	 AND rctta.name in ('MAN_AVOIR', 'SI_AMONT_AVOIR')
	 AND rcta.attribute6 = 'OUI'
	 and rcta.trx_number = rec.num_avoir;
	EXCEPTION
	WHEN OTHERS THEN

	  DBMS_OUTPUT.PUT_LINE('ERROR customer_trx_id : ' || SQLERRM);
	  vv_customer_trx_id := null;
	  vn_org_id := null;
	
	END;
	
	DBMS_OUTPUT.PUT_LINE('+++++++++++++++++++++++++++++++++++++++');
	DBMS_OUTPUT.PUT_LINE('Traitement avoir : ' || rec.num_avoir);
	
	DBMS_OUTPUT.PUT_LINE('vv_customer_trx_id : ' || vv_customer_trx_id);
	DBMS_OUTPUT.PUT_LINE('vn_org_id : ' || vn_org_id);
	
	BEGIN
	
	SELECT DISTINCT hp.party_id, hps.party_site_id
	  INTO vv_party_id, vv_party_site_id
	  FROM hz_cust_accounts          hca,
		   ra_customer_trx_all       rcta,
		   ra_customer_trx_lines_all rctl,
		   ar_payment_schedules_all  ps,
		   hz_parties                hp,
		   hr_operating_units        hou,
		   xle_entity_profiles       xep,
		   hz_cust_site_uses_all     hcsua,
		   ar.hz_customer_profiles   hcp,
		   ar_collectors             ar,
		   hz_cust_acct_sites_all    hcasa,
		   hz_party_sites            hps
	 WHERE 1 = 1
	   AND rcta.bill_to_site_use_id = hcp.site_use_id
	   AND hca.party_id = hcp.party_id
	   AND hcasa.party_site_id = hps.party_site_id
	   AND ar.collector_id = hcp.collector_id
	   AND hcasa.cust_account_id = hca.cust_account_id
	   AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
	   AND hcp.cust_account_id = hca.cust_account_id
	   AND hcp.site_use_id = hcsua.site_use_id
	   AND hp.party_id = hca.party_id
	   AND hca.cust_account_id = rcta.bill_to_customer_id
	   AND rcta.customer_trx_id = rctl.customer_trx_id
	   AND rcta.org_id = hou.organization_id
	   AND hou.organization_id = hcsua.org_id
	   AND ps.customer_trx_id = rcta.customer_trx_id
	   AND xep.legal_entity_id = hou.default_legal_context_id
	   AND rcta.customer_trx_id = vv_customer_trx_id;
	   
	EXCEPTION
	WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE ('ERROR vv_party_id - vv_party_site_id : ' || SQLERRM);
	vv_party_id := null;
	vv_party_site_id := null;
	END;
	
	DBMS_OUTPUT.PUT_LINE('vv_party_id : ' || vv_party_id);
    DBMS_OUTPUT.PUT_LINE('vv_party_site_id : ' || vv_party_site_id);
    
	BEGIN
	SELECT receivables_trx_id , status
	  INTO vv_receivables_trx_id , vv_status
	  FROM ar_receivables_trx_all
	 WHERE org_id = vn_org_id
	   AND type = 'CM_REFUND';
	EXCEPTION
	WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE ('ERROR receivables_trx_id ' || SQLERRM);
	vv_receivables_trx_id := null;
	vv_status := null;
	END;
              
    DBMS_OUTPUT.PUT_LINE('vv_receivables_trx_id : ' || vv_receivables_trx_id);
	
	DBMS_OUTPUT.PUT_LINE('vv_status : ' || vv_status);
              
    BEGIN      
	  SELECT CASH_RECEIPT_ID
	  into vv_cash_receipt_id
	  FROM ar_cash_receipts_all
	  WHERE status <> 'REV'
	  and receipt_number = 'RBT_AVOIR_' || rec.num_avoir;
	
	EXCEPTION
	WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE ('ERROR vv_cash_receipt_id ' || SQLERRM);
	vv_cash_receipt_id := null;
	END;
	
	DBMS_OUTPUT.PUT_LINE('vv_cash_receipt_id : ' || vv_cash_receipt_id);
	
	BEGIN
	SELECT distinct eba.EXT_BANK_ACCOUNT_ID, eba.bank_account_num
	  INTO pn_EXT_BANK_ACCOUNT_ID, pn_bank_account_num
	  FROM hz_cust_accounts        ca,
		   iby_external_payers_all epa,
		   iby_pmt_instr_uses_all  piu,
		   iby_ext_bank_accounts   eba,
		   hz_parties              hp,
		   ra_customer_trx_all     rcta
	 WHERE 1 = 1
	   AND ca.cust_account_id = epa.cust_account_id
	   AND piu.ext_pmt_party_id = epa.ext_payer_id
	   AND piu.payment_function = 'CUSTOMER_PAYMENT'
	   AND eba.ext_bank_account_id = piu.instrument_id
	   AND ca.party_id = hp.party_id
	   AND nvl(piu.end_date, sysdate + 1) > sysdate
	   AND piu.start_date <= sysdate
	   AND rcta.bill_to_customer_id = ca.cust_account_id
	   AND epa.org_id = rcta.org_id
	   AND rcta.customer_trx_id = vv_customer_trx_id
	   AND eba.iban = rec.IBAN;
  

	EXCEPTION
	WHEN OTHERS THEN
	DBMS_OUTPUT.PUT_LINE ('ERROR pn_EXT_BANK_ACCOUNT_ID ' || SQLERRM);
	pn_EXT_BANK_ACCOUNT_ID := null;
	pn_bank_account_num := null;
	END;
	
	DBMS_OUTPUT.PUT_LINE('pn_bank_account_num : ' || pn_bank_account_num);
	DBMS_OUTPUT.PUT_LINE('pn_EXT_BANK_ACCOUNT_ID : ' || pn_EXT_BANK_ACCOUNT_ID);
	
	IF vv_status = 'A' THEN
	
	v_application_ref_id := null;
	v_application_ref_num := null;
	v_application_ref_type := null;
	v_secondary_application_ref_id := null;
	v_receivable_application_id := null;
	
	Ar_receipt_api_pub.Activity_application(
		P_Api_Version => 1.0,
		p_init_msg_list => FND_API.G_TRUE,
		p_commit => FND_API.G_TRUE,
		p_validation_level => FND_API.G_VALID_LEVEL_FULL,
		x_return_status => v_return_status,
		x_msg_count => v_msg_count,
		x_msg_data => p_msg_data,
		-- Receipt application parameters.
		p_cash_receipt_id => vv_cash_receipt_id,
		P_Receipt_Number => NULL,
		p_amount_applied => -rec.amt_non_sld,
		p_applied_payment_schedule_id => -8,
		p_receivables_trx_id => vv_receivables_trx_id,
		p_apply_date => SYSDATE,
		p_apply_gl_date => SYSDATE,
		-- ******* Global Flexfield parameters *******
		p_application_ref_type => v_application_ref_type,
		p_application_ref_id => v_application_ref_id,
		p_application_ref_num => v_application_ref_num,
		p_secondary_application_ref_id=> v_secondary_application_ref_id,
		p_receivable_application_id => v_receivable_application_id,
		p_val_writeoff_limits_flag => 'Y',
		p_netted_receipt_flag => 'N',
		p_pay_alone_flag => 'Y',
		p_payment_method_code          => 'EFT',
		p_pay_group_lookup_code        => 'RBTCLIENT',
		p_party_id => vv_party_id,
		p_Party_Site_Id => vv_party_site_id,
		P_Bank_Account_Id => pn_EXT_BANK_ACCOUNT_ID,
		p_org_id => vn_org_id,
		p_payment_priority => 1,
		p_terms_id => 10010
	);
	
	COMMIT;
	
		  IF v_msg_count IS NULL THEN--AND v_return_status = 'S'
		  
			
			DBMS_OUTPUT.PUT_LINE('Remboursement est OK pour : ' || rec.num_avoir);
			
			DBMS_OUTPUT.PUT_LINE('v_application_ref_id : ' || v_application_ref_id);
			DBMS_OUTPUT.PUT_LINE('v_application_ref_num : ' || v_application_ref_num );
			DBMS_OUTPUT.PUT_LINE('v_application_ref_type : ' ||v_application_ref_type );
			DBMS_OUTPUT.PUT_LINE('v_secondary_application_ref_id: ' ||v_secondary_application_ref_id);
			DBMS_OUTPUT.PUT_LINE('v_receivable_application_id: ' ||v_receivable_application_id);
			
			BEGIN
			  UPDATE DKA_ARREMB_REPORTING
			  SET activity_flag = 'Y'
			  WHERE num_avoir = rec.num_avoir
			  AND uo = rec.uo;
			  
			  COMMIT;
			  
			  EXCEPTION
			  WHEN OTHERS THEN
			  DBMS_OUTPUT.PUT_LINE('ERROR UPDATE activity_flag : ' || rec.num_avoir );
			  DBMS_OUTPUT.PUT_LINE('Erreur  : ' || SQLERRM);
			END;
			
			:ret_code := 'SUCCESS';
			
		  ELSIF v_return_status != 'S' THEN
                    
			BEGIN
			  UPDATE DKA_ARREMB_REPORTING
			  SET activity_flag = 'N'
			  WHERE num_avoir = rec.num_avoir
			  AND uo = rec.uo;
			  
			  COMMIT;
			  
			  EXCEPTION
			  WHEN OTHERS THEN
			  DBMS_OUTPUT.PUT_LINE('ERROR UPDATE activity_flag : ' || rec.num_avoir );
			  DBMS_OUTPUT.PUT_LINE('Erreur  : ' || SQLERRM);
			END;
			  
			  
			  
			  IF v_msg_count = 1 Then
			  DBMS_OUTPUT.PUT_LINE('p_msg_data : '|| p_msg_data);
			  ELSIF v_msg_count > 1 Then
			  FOR tst in 1..v_msg_count LOOP
			  p_msg_data := FND_MSG_PUB.Get(FND_MSG_PUB.G_NEXT,FND_API.G_FALSE);
			  DBMS_OUTPUT.PUT_LINE('v_msg_data (API : message number ' || tst || ' ) : ');
			  DBMS_OUTPUT.PUT_LINE(p_msg_data);
			
			  
			  END LOOP;
			  END IF;
			 
			DBMS_OUTPUT.PUT_LINE('p_msg_data : '|| p_msg_data);  
			DBMS_OUTPUT.PUT_LINE('v_return_status ' || v_return_status);
			DBMS_OUTPUT.PUT_LINE('v_msg_count ' || v_msg_count);

            :ret_code := 'WARNING';
			
          END IF;
	ELSE
	
	DBMS_OUTPUT.PUT_LINE('Erreur Type d''événement UO :' || rec.uo);
	DBMS_OUTPUT.PUT_LINE('ERROR ID EVENT : ' || vv_receivables_trx_id);
	
	:ret_code := 'WARNING';
	
	BEGIN
	  UPDATE DKA_ARREMB_REPORTING
	  SET activity_flag = 'E'
	  WHERE num_avoir = rec.num_avoir
	  AND uo = rec.uo;
	  
	  COMMIT;
	  
	  EXCEPTION
	  WHEN OTHERS THEN
	  DBMS_OUTPUT.PUT_LINE('ERROR UPDATE activity_flag : ' || rec.num_avoir );
	  DBMS_OUTPUT.PUT_LINE('Erreur  : ' || SQLERRM);
	END;
	
	END IF;
	
	END LOOP;
	
    
EXCEPTION
    WHEN OTHERS THEN
	     DBMS_OUTPUT.put_line (dbms_utility.format_error_backtrace());
         DBMS_OUTPUT.PUT_LINE (' ==> ERREUR : ' || SQLERRM);
         :ret_code := 'WARNING';
END;
/

COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code