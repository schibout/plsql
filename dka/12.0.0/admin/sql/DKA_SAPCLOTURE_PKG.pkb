CREATE OR REPLACE PACKAGE BODY DKA_SAPCLOTURE_PKG
AS

--------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SCLOPERIOD_PKG.pkb
-- DESCRIPTION       : DKA_SCLOPERIOD_PKG package body :
---
--- AUTEUR           : Ulrich VANDEWEGHE (CGEY)
--- DATE DE CREATION : 28/05/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
-- 12/07/02	MSF	Message d'erreur; Controle des payement
--- ---------- --- -------------------------------------------------------------------------
--- 12/01/2009 EMA Conformément à l'EIS20080110a : Repousser les factures Open Interface au 
---                mois suivant lors de la clôture AP, les factures encore bloquées dans
---                l'Open Interface sont repoussées au dernier jour de la nouvelle période
---                ouverte.
--------------------------------------------------------------------------------------------
--- 10/08/2016 OBE Migration R12
--------------------------------------------------------------------------------------------
--- 09/01/2017 RBE Correction artf2076969
--- 20/03/2017 RBE Correction artf2121822
--- 14/04/2017 NBO artf2121822 - Cloture de la période AP - Impossible de transférer les écriture d'une période à l'autre
--------------------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHERCHE_PERIOD
--  Description   : Recherche la période à fermer pour une application
--
--  PARAMETRES    :
--    pn_application_id	number
--
--  VALEUR RETOURNEE :
--     pv_errbuf	varchar2
--     pd_start_date 	date
--     pd_end_date 	date
--     pd_period_name 	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE cherche_period ( pn_sob_id		  IN OUT NUMBER,
                  			   pv_errbuf 		     OUT VARCHAR2,
                  			   pd_start_date 	   OUT DATE,
                  			   pd_end_date 		   OUT DATE,
                  			   pv_period_name IN OUT VARCHAR2 ) 
IS
	vd_start_date DATE;
	vd_end_date DATE;
	vv_period_name VARCHAR2(30);
	vv_mesg VARCHAR2(4000);
BEGIN	   

	pv_errbuf := NULL;
	
	-- Recherche de la première période en status ouvert
  SELECT START_DATE,
         END_DATE,
         PERIOD_NAME 
  INTO   vd_start_date,
         vd_end_date,
         vv_period_name
  FROM  gl_period_statuses  
  WHERE START_DATE IN (
                    	SELECT MIN(gps.start_date)
                    	FROM gl_period_statuses gps, GL_ACCESS_SET_LEDGERS gasl
                    	WHERE gps.application_id = 200
                    	--AND set_of_books_id = pn_sob_id
                      --AND gps.ledger_id = pn_sob_id
                      AND GASL.ACCESS_SET_ID = pn_sob_id
                      AND GASL.ledger_id = gps.ledger_id
                    	AND gps.closing_status = 'O'
                    	)
	AND application_id = 200
	AND closing_status = 'O'
  AND rownum = 1
	;

	pd_start_date   :=  vd_start_date;
	pd_end_date     :=  vd_end_date;
	pv_period_name  :=  vv_period_name;
	
	EXCEPTION
		WHEN OTHERS THEN
			vv_mesg := substr(SQLERRM,1,400);
			pv_errbuf := vv_mesg;
		
		
	
END;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHERCHE_NEXT_PERIOD
--  Description   : Recherche la période prochaine periode
--
--  PARAMETRES    :
--     pn_sob_id	    number
--     pv_period_name	varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf	          varchar2
--     pd_next_start_date 	date
--     pd_next_end_date 	  date
--     pv_next_period_name	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE cherche_next_period (  pn_sob_id		        IN OUT NUMBER,
                      				   pv_errbuf 		           OUT VARCHAR2,
                      				   pv_period_name       IN     VARCHAR2,
                      			   	 pd_next_start_date 		 OUT DATE,
                      			   	 pd_next_end_date 		   OUT DATE,
                      			   	 pv_next_period_name  IN OUT VARCHAR2
                      		    ) 
IS
	vd_start_date DATE;
	vd_end_date DATE;
	vv_period_name VARCHAR2(30);
	vv_mesg VARCHAR2(4000);

BEGIN	   

	pv_errbuf := NULL;
	
	-- Recherche de la période suivante
	SELECT distinct start_date, end_date, period_name
	INTO vd_start_date, vd_end_date, vv_period_name
	FROM gl_period_statuses
	WHERE start_date IN ( SELECT end_date+1 
			      FROM gl_period_statuses 
			      WHERE period_name = pv_period_name
			      AND application_id = 200
			      --AND set_of_books_id = pn_sob_id 
			      )
	AND application_id = 200 
	--AND set_of_books_id = pn_sob_id
	;

	pd_next_start_date  := vd_start_date;
	pd_next_end_date    := vd_end_date;
	pv_next_period_name := vv_period_name;
	
	EXCEPTION
		WHEN OTHERS THEN
			vv_mesg := substr(SQLERRM,1,400);
			pv_errbuf := vv_mesg;	
	
END;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : AP_CHECK_TRANSFER_TO_GL
--  Description   : Recherche si tout est transféré dans GL pour la période ( module AP )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
/*
PROCEDURE ap_check_transfer_to_gl ( pd_start_date 	IN DATE,
			   	    pd_end_date 	IN DATE,
			   	    pv_period_name 	IN VARCHAR2,
			   	    pn_sob_id		IN NUMBER,
			   	    pv_errbuf 		OUT VARCHAR2,
			   	    pv_status		OUT VARCHAR2 ) 
IS

	vv_check_gl_transfer    VARCHAR2(1);

	CURSOR check_gl_tran_cur IS
  	SELECT 'X'
    	FROM ap_ae_headers_all 
  	WHERE period_name = pv_period_name
    	AND accounting_date BETWEEN  pd_start_date
                            AND  pd_end_date
    	AND gl_transfer_flag <> 'Y'
    	AND (org_id IS NULL
            OR
            org_id IN (SELECT org_id
                       FROM ap_system_parameters_all
                       WHERE set_of_books_id = pn_sob_id
                       OR secondary_set_of_books_id = pn_sob_id));

BEGIN


	OPEN check_gl_tran_cur;
	
  	FETCH check_gl_tran_cur INTO vv_check_gl_transfer;
  
  	IF (check_gl_tran_cur%FOUND) THEN
  	
     		pv_errbuf := dka_tools_pkg.get_message('SQLAP', 'AP_GL_UNTRANSFD_EXIST');
     		pv_status := 'KO';
     		--MSF:12/07/02
                --Fnd_File.put_line (Fnd_File.OUTPUT,pv_errbuf);    
     	ELSE
     	
     		pv_status := 'OK';	
     		
     	END IF;
     	
     	CLOSE check_gl_tran_cur;
     	
  
END AP_CHECK_TRANSFER_TO_GL;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : AP_CHECK_FUTURE_PMTS
--  Description   : Recherche si tout est réglé pour la période ( module AP )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE ap_check_future_pmts ( pd_start_date 	IN DATE,
				 pd_end_date 	IN DATE,
				 pv_period_name IN VARCHAR2,
				 pn_sob_id 	IN NUMBER,
				 pv_errbuf 	OUT VARCHAR2,
				 pv_status 	OUT VARCHAR2)
IS

	vv_unmat_fut_pmts    VARCHAR2(100);
		 
	CURSOR unmat_fut_pmts_cur IS
   	SELECT 	'X'
        FROM 	ap_checks_all c       	
    	WHERE c.future_pay_due_date IS NOT NULL
    	AND c.status_lookup_code = 'ISSUED'
    	AND c.future_pay_due_date BETWEEN pd_start_date
                               	  AND pd_end_date
    	AND (c.org_id IS NULL 
             OR
             c.org_id IN (SELECT org_id 
                    	  FROM ap_system_parameters_all
                    	  WHERE set_of_books_id = pn_sob_id
                          OR secondary_set_of_books_id = pn_sob_id))
    	AND rownum < 2;  -- Bug 1629095 
        -- Added the condition above to improve performance.
        
BEGIN
        
	OPEN unmat_fut_pmts_cur;
  	FETCH unmat_fut_pmts_cur INTO vv_unmat_fut_pmts;
  	
  	IF (unmat_fut_pmts_cur%found) THEN
  	
  		pv_errbuf := dka_tools_pkg.get_message('SQLAP', 'AP_UNMAT_FUT_PMTS_EXIST');
     		pv_status := 'KO';   		
     		--MSF:12/07/02
                --Fnd_File.put_line (Fnd_File.OUTPUT,pv_errbuf);    
     	ELSE
     		
     		pv_status := 'OK';
     		
     	END IF;
     		
     	CLOSE unmat_fut_pmts_cur;
  
END ap_check_future_pmts;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ap_check_unconfirmed_pmt_bat
--  Description   : Recherche si tout les lots de réglements sont OK ( module AP )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE ap_check_unconfirmed_pmt_bat( pd_start_date 	IN DATE,
				 pd_end_date 	IN DATE,
				 pv_period_name IN VARCHAR2,
				 pn_sob_id 	IN NUMBER,
				 pv_errbuf 	OUT VARCHAR2,
				 pv_status 	OUT VARCHAR2)
IS
     
	vv_var_check    VARCHAR2(100);
    
    	CURSOR CHK_CONFIRM IS
      	SELECT 'Unconfirmed Payment Batch exists for period'
        FROM   ap_inv_selection_criteria_all
       	WHERE  period_name = pv_period_name
        AND    status NOT IN ('CONFIRMED','CANCELED','QUICKCHECK')
        AND  (org_id is null
              OR
              org_id in (select org_id
                         from   ap_system_parameters_all
                         where  set_of_books_id = pn_sob_id
                         or     secondary_set_of_books_id = pn_sob_id
                         ));

BEGIN

       	-- Check if unconfirmed payment batches exist
       	OPEN CHK_CONFIRM;
       	
       	FETCH CHK_CONFIRM INTO  vv_var_check;
       	
       	IF CHK_CONFIRM%FOUND THEN
       	
          	pv_status := 'KO';
          	pv_errbuf := dka_tools_pkg.get_message('SQLAP', 'AP_UNCONFIRMED_PMT_BAT_EXISTS');
                --MSF:12/07/02
                --Fnd_File.put_line (Fnd_File.OUTPUT,pv_errbuf);    
       	ELSE
       	
       		pv_status := 'OK';
       	
       	END IF;
       	
        CLOSE chk_confirm;
         

END ap_check_unconfirmed_pmt_bat;

		
-------------------------------------------------------------------------------------------------------------------
--  Nom           : ap_check_unposted_invoices
--  Description   : Recherche si toutes les factures sont postées ( module AP )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE ap_check_unposted_invoices ( 	pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)
IS
		 
	vv_uo_name		VARCHAR2(100);
	vv_invoice_num     	VARCHAR2(50);
	vd_accounting_date	DATE;
	vn_amount		NUMBER;		 
	
	CURSOR unposted_inv_dists_cur IS
  	SELECT 	hou.name,
  		ai.invoice_num,
  		aid.accounting_date,
  		sum(aid.amount)
    	FROM 	ap_invoice_distributions_all aid,
    		ap_invoices_all ai,
    		hr_all_organization_units hou
  	WHERE period_name = pv_period_name
  	AND ai.invoice_id = aid.invoice_id
  	AND aid.org_id = hou.organization_id(+)
    	AND accounting_date BETWEEN pd_start_date
                            AND  pd_end_date
    	AND accrual_posted_flag = 'N'
    	AND (aid.org_id IS NULL 
       	     OR
             aid.org_id IN (SELECT org_id 
                    	FROM ap_system_parameters_all
                    	WHERE set_of_books_id = pn_sob_id
                        OR secondary_set_of_books_id = pn_sob_id
                       ))
        GROUP BY hou.name, ai.invoice_num, aid.accounting_date
        ORDER BY ai.invoice_num;

BEGIN

	OPEN unposted_inv_dists_cur;
	
  	FETCH unposted_inv_dists_cur INTO 	vv_uo_name,
  						vv_invoice_num,
  						vd_accounting_date,
  						vn_amount;
  	
  	IF (unposted_inv_dists_cur%found) THEN
  	
  	pv_errbuf := dka_tools_pkg.get_message('SQLAP', 'AP_SET_CANNOT_CLOSED_PERIOD');    		           
     			
     		Fnd_File.put_line (Fnd_File.OUTPUT,pv_errbuf);
     		Fnd_File.put_line (Fnd_File.OUTPUT,'UO : ' || vv_uo_name);
      		Fnd_File.put_line (Fnd_File.OUTPUT,'Facture : ' || vv_invoice_num );
      		Fnd_File.put_line (Fnd_File.OUTPUT,'Date : ' || to_char(vd_accounting_date, 'DD/MM/RRRR' ));
      		Fnd_File.put_line (Fnd_File.OUTPUT,'Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
      		     	
     		LOOP 
     		
     			FETCH unposted_inv_dists_cur INTO vv_uo_name,
     							  vv_invoice_num,
  							  vd_accounting_date,
  							  vn_amount;
  							  
  			EXIT WHEN unposted_inv_dists_cur%NOTFOUND;
  							  
     			-- Cannot change period status
     			pv_errbuf := dka_tools_pkg.get_message('SQLAP', 'AP_SET_CANNOT_CLOSED_PERIOD');    		           
     			Fnd_File.put_line (Fnd_File.OUTPUT,pv_errbuf);
     			Fnd_File.put_line (Fnd_File.OUTPUT,'UO : ' || vv_uo_name);
      			Fnd_File.put_line (Fnd_File.OUTPUT,'Facture : ' || vv_invoice_num );
      			Fnd_File.put_line (Fnd_File.OUTPUT,'Date : ' || to_char(vd_accounting_date, 'DD/MM/RRRR' ));
      			Fnd_File.put_line (Fnd_File.OUTPUT,'Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
      		
     		END LOOP;
     		
     		pv_status := 'KO';
     		
     	
     	ELSE
     		
     		pv_status := 'OK';
     	
     	END IF;
     	
     	CLOSE unposted_inv_dists_cur;
  
END ap_check_unposted_invoices;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ap_check_unposted_payments
--  Description   : Recherche si tous les payments sont postés ( module AP )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE ap_check_unposted_payments ( 	pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS
	vv_unposted_inv_pmts     VARCHAR2(100);

	CURSOR unposted_inv_pmts_cur IS
  	SELECT 	'X'
    	FROM ap_invoice_payments_all
  	WHERE period_name = pv_period_name
    	AND accounting_date BETWEEN pd_start_date
                            AND pd_end_date
    	AND posted_flag = 'N'
    	AND (org_id IS NULL
             OR
             org_id IN (SELECT org_id 
                        FROM ap_system_parameters_all
                    	WHERE (set_of_books_id = pn_sob_id
                     	      OR secondary_set_of_books_id = pn_sob_id
                     	      )
                    	AND (recon_accounting_flag = 'Y'
                             OR
                             recon_accounting_flag = 'N')
                   	AND nvl(when_to_account_pmt, 'ALWAYS') = 'ALWAYS'
                   	)
            )
  	UNION
  	SELECT 'Clearing or Maturity records not yet accounted'
    	FROM ap_payment_history_all p 
    	WHERE p.accounting_date BETWEEN pd_start_date
                            	AND pd_end_date
    	AND  p.posted_flag = 'N'
    	AND (p.org_id IS NULL 
             OR
             p.org_id IN (SELECT org_id 
                    	  FROM ap_system_parameters_all
                    	  WHERE (set_of_books_id = pn_sob_id
                                 OR secondary_set_of_books_id = pn_sob_id
                     		)
                    	  AND recon_accounting_flag = 'Y'
                    	  AND (nvl(when_to_account_pmt, 'ALWAYS') = 'ALWAYS'
                         	OR 
                               nvl(when_to_account_pmt, 'ALWAYS') = 'CLEARING ONLY'
                               )
                           )
            );

BEGIN

	OPEN unposted_inv_pmts_cur;
  
  	FETCH unposted_inv_pmts_cur INTO vv_unposted_inv_pmts;
  	
  	IF (unposted_inv_pmts_cur%found) THEN
  	
  		pv_status := 'KO';
		pv_errbuf := dka_tools_pkg.get_message('SQLAP', 'AP_SET_CANNOT_CLOSED_PERIOD');
     		--MSF:12/07/02
                --Fnd_File.put_line (Fnd_File.OUTPUT,pv_errbuf);    
     	ELSE
     	
     		pv_status := 'OK';
     		
     	END IF;
     	
     	CLOSE unposted_inv_pmts_cur;
  
END ap_check_unposted_payments;
*/

-------------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES    :
--	pv_errbuf                       Entrée/Sortie           retour de message eventuel
--    	pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
PROCEDURE main ( pv_errbuf	IN OUT varchar2,
		 pn_retcode 	OUT number	)
IS

	e_error		              EXCEPTION;
	vn_result	              NUMBER;
	vd_ref_date	            DATE;
	vv_mesg		              VARCHAR2(4000) := NULL;
	vn_sob_id	              NUMBER;
	vd_start_date	          DATE;
	vd_end_date	            DATE;
	vv_next_period_name	    VARCHAR2(30);
	vd_next_start_date	    DATE;
	vd_next_end_date	      DATE;
	vv_period_name	        VARCHAR2(30);
	vv_status	              VARCHAR2(2);
	vn_count	              NUMBER:= 0;
  --< OBE
  l_process_flag          VARCHAR2(2);
  l_message               VARCHAR2(200);
  v_user_id                NUMBER;                       
  v_resp_id                NUMBER;
  v_resp_appl_id           NUMBER;  
  v_org_id                 NUMBER;  
  --> OBE
  v_message                VARCHAR2(500);
  --- 14/04/2017 NBO artf2121822 - Cloture de la période AP - Impossible de transférer les écriture d'une période à l'autre
  xml_layout boolean;  
  vn_request_id     NUMBER;
  v_phase           VARCHAR2(100);
  v_status          VARCHAR2(100);
  v_dev_phase       VARCHAR2(100);
  v_dev_status      VARCHAR2(100);
  vn_tempo          NUMBER := 20; 
  vn_ledger_id      NUMBER;
  
  --< OBE
  CURSOR cur_ledger (p_access_set_id IN NUMBER) IS
    --RBE artf2076969
    SELECT GASL.ledger_id , gl.name
    FROM GL_ACCESS_SET_LEDGERS GASL ,GL_LEDGERS GL ,gl_period_statuses gps
    WHERE GASL.ACCESS_SET_ID = P_ACCESS_SET_ID
    AND  GASL.ledger_id = gl.ledger_id
    AND  gl.LEDGER_CATEGORY_CODE = 'PRIMARY'
    AND  GL.ledger_id = gps.ledger_id
    AND  gps.application_id = 200
    AND  gps.closing_status = 'O'
    AND  gps.period_name = vv_period_name
    ;
  --> OBE
  
BEGIN

    Fnd_File.put_line (Fnd_File.LOG,'main (+)');
    pv_errbuf     := NULL;
    pn_retcode    := 0;
        
    Fnd_File.put_line (Fnd_File.LOG,'+ Début du traitement : '||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'| DKA : Cloture de la période AP  ');
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'');
    
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'+ Début du traitement : '||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'');

    --< OBE

  
    v_user_id      := FND_PROFILE.VALUE('USER_ID');
    v_resp_id      := FND_PROFILE.VALUE('RESP_ID');    
    v_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');
    
    APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                    RESP_ID      => v_resp_id,
                                    RESP_APPL_ID => v_resp_appl_id
                                    );
    --mo_global.set_policy_context('S',v_org_id);  
     MO_GLOBAL.INIT('SQLAP');
  --> OBE
  
  --Fnd_File.put_line (Fnd_File.LOG,'v_user_id : '||TO_CHAR(v_user_id));
  --Fnd_File.put_line (Fnd_File.LOG,'v_resp_id : '||TO_CHAR(v_resp_id));
  --Fnd_File.put_line (Fnd_File.LOG,'v_resp_appl_id : '||TO_CHAR(v_resp_appl_id));
  --Fnd_File.put_line (Fnd_File.LOG,'v_org_id : '||TO_CHAR(v_org_id));
  
  vn_sob_id := fnd_profile.VALUE ('GL_ACCESS_SET_ID');
  Fnd_File.put_line (Fnd_File.LOG,'GL_ACCESS_SET_ID : '||TO_CHAR(vn_sob_id));

	Fnd_File.put_line (Fnd_File.LOG,'Recherche de la première période ouverte');
	--dka_sapcloture_pkg.cherche_period(vn_sob_id, vv_mesg,vd_start_date, vd_end_date, vv_period_name);
  dka_sapcloture_pkg.cherche_period(vn_sob_id, vv_mesg,vd_start_date, vd_end_date, vv_period_name);

	-- Test si une période est ouverte
	IF vv_period_name IS NULL THEN
		--vv_mesg := 'Il n''y a pas de période ouverte';
    Fnd_File.put_line (Fnd_File.LOG,'Il n''y a pas de période ouverte');
    Fnd_File.put_line (Fnd_File.OUTPUT,'Il n''y a pas de période ouverte');
    pn_retcode := 2;
    RETURN;
  END IF;
      
	Fnd_File.put_line (Fnd_File.LOG,'Cloture de la période AP : ' || vv_period_name);

  Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
	Fnd_File.put_line (Fnd_File.OUTPUT,'| Période AP à clôturer : ' || vv_period_name);

  dka_sapcloture_pkg.cherche_next_period( vn_sob_id, vv_mesg,vv_period_name, vd_next_start_date, vd_next_end_date, vv_next_period_name );

	Fnd_File.put_line (Fnd_File.LOG,'Ouverture de la période AP : ' || vv_next_period_name);
	
	Fnd_File.put_line (Fnd_File.OUTPUT,'| Période AP à ouvrir   : ' || vv_next_period_name);
	Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
	Fnd_File.put_line (Fnd_File.OUTPUT,'');
  		
  FOR ledger IN cur_ledger(vn_sob_id) LOOP -- OBE
  
  	vn_count := vn_count + 1 ;
  	
  	Fnd_File.put_line (Fnd_File.LOG,'+------------------------------------------------+');
  	Fnd_File.put_line (Fnd_File.LOG,'| Livre : '||ledger.name);
  	
  	--Fnd_File.put_line (Fnd_File.OUTPUT,'==>Livre : '||ledger.name);
    Fnd_File.put_line (Fnd_File.OUTPUT,'');
  	Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
  	Fnd_File.put_line (Fnd_File.OUTPUT,'| Livre : '||ledger.name);
  	Fnd_File.put_line (Fnd_File.OUTPUT,'+------------------------------+');
  	
  	--vv_mesg := 'RECHERCHE DU SOB ID';
  	--vn_sob_id := fnd_profile.VALUE ('GL_SET_OF_BKS_ID');
  	--dka_sapcloture_pkg.cherche_period(vn_sob_id, vv_mesg,vd_start_date, vd_end_date, vv_period_name);
    --dka_sapcloture_pkg.cherche_period(ledger.ledger_id, vv_mesg,vd_start_date, vd_end_date, vv_period_name);
  	
  	Fnd_File.put_line (Fnd_File.LOG,'Cloture de la période AP : ' || vv_period_name);
    --- 14/04/2017 NBO artf2121822 - Cloture de la période AP - Impossible de transférer les écriture d'une période à l'autre
    Fnd_File.put_line (Fnd_File.LOG,'Transfert vers la période AP : ' || vv_next_period_name);
  	 
    ap_period_close_pkg.process_period (ledger.ledger_id,
                                       NULL,
                                       vv_period_name,
                                       vd_start_date,
                                       vd_end_date,
                                       NULL,
                                       'PERIOD_CLOSE',
                                       NULL,
                                       l_process_flag,
                                       l_message);
 
	/*
	dka_sapcloture_pkg.ap_check_transfer_to_gl(vd_start_date, vd_end_date, vv_period_name, vn_sob_id, vv_mesg, vv_status );
	Fnd_File.put_line (Fnd_File.LOG,chr(10));
	Fnd_File.put_line (Fnd_File.LOG,'AP --> Contrôle du transfer vers GL ' || vv_status );
	IF vv_status = 'KO' THEN
		--MSF:12/07/02
                Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg);
                Fnd_File.put_line (Fnd_File.OUTPUT,'**********************************');
                Fnd_File.put_line (Fnd_File.OUTPUT,'');
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle du transfer vers GL : ', 'KO', vv_mesg );
	ELSE
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle du transfer vers GL : ', 'OK', NULL );
	END IF;
	
        dka_sapcloture_pkg.ap_check_future_pmts(vd_start_date, vd_end_date, vv_period_name, vn_sob_id, vv_mesg, vv_status );
        Fnd_File.put_line (Fnd_File.LOG,chr(10));
	Fnd_File.put_line (Fnd_File.LOG,'AP --> Contrôle des check future pmts ' || vv_status );
	IF vv_status = 'KO' THEN
		--MSF:12/07/02
                Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg);
                Fnd_File.put_line (Fnd_File.OUTPUT,'**********************************');
                Fnd_File.put_line (Fnd_File.OUTPUT,''); 
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des check future pmts ', 'KO', vv_mesg );
	ELSE
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des check future pmts ', 'OK', NULL );
	END IF;
	
	dka_sapcloture_pkg.ap_check_unconfirmed_pmt_bat(vd_start_date, vd_end_date, vv_period_name, vn_sob_id, vv_mesg, vv_status );
	Fnd_File.put_line (Fnd_File.LOG,chr(10));
	Fnd_File.put_line (Fnd_File.LOG,'AP --> Contrôle des lots de réglements ' || vv_status );
	IF vv_status = 'KO' THEN
		--MSF:12/07/02
                Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg); 
                Fnd_File.put_line (Fnd_File.OUTPUT,'**********************************');
                Fnd_File.put_line (Fnd_File.OUTPUT,''); 
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des lots de réglements ', 'KO', vv_mesg );
	ELSE
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des lots de réglements ', 'OK', NULL );
	END IF;

	dka_sapcloture_pkg.ap_check_unposted_invoices(vd_start_date, vd_end_date, vv_period_name, vn_sob_id, vv_mesg, vv_status );
	Fnd_File.put_line (Fnd_File.LOG,chr(10));
	Fnd_File.put_line (Fnd_File.LOG,'AP --> Contrôle des factures ' || vv_status );
	IF vv_status = 'KO' THEN
		--MSF:12/07/02
                Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg);
                Fnd_File.put_line (Fnd_File.OUTPUT,''); 
                Fnd_File.put_line (Fnd_File.OUTPUT,'**********************************');
                Fnd_File.put_line (Fnd_File.OUTPUT,'');
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des factures ', 'KO', vv_mesg );
	ELSE
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des factures ', 'OK', NULL );
	END IF;
  */
  --> OBE
--MSF: Controle des payement et pas les règlement **************************

/*	dka_sapcloture_pkg.ap_check_unposted_invoices(vd_start_date, vd_end_date, vv_period_name, vn_sob_id, vv_mesg, vv_status );
	Fnd_File.put_line (Fnd_File.LOG,chr(10));
	Fnd_File.put_line (Fnd_File.LOG,'AP --> Contrôle des réglements ' || vv_status );
	IF vv_status = 'KO' THEN
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des réglements ', 'KO', vv_mesg );
	ELSE
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des réglements ', 'OK', NULL );
	END IF;*/
  --< OBE
  /*
	dka_sapcloture_pkg.ap_check_unposted_payments(vd_start_date, vd_end_date, vv_period_name, vn_sob_id, vv_mesg, vv_status );
	Fnd_File.put_line (Fnd_File.LOG,chr(10));
	Fnd_File.put_line (Fnd_File.LOG,'AP --> Contrôle des payements ' || vv_status );
	IF vv_status = 'KO' THEN
		--MSF:12/07/02
                Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg);
                Fnd_File.put_line (Fnd_File.OUTPUT,'**********************************');
                Fnd_File.put_line (Fnd_File.OUTPUT,''); 
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des payements ', 'KO', vv_mesg );
	ELSE
		INSERT INTO dka_sapcloture VALUES
		( vv_period_name, 'AP --> Contrôle des payements ', 'OK', NULL );
	END IF;
  */
  --> OBE
--*****************************************************************
	-- Fermeture de la période ouverte et ouverture de la suivante
	-- Si pas d'erreur
	/*SELECT COUNT(1)
	INTO vn_count
	FROM dka_sapcloture
	WHERE status = 'KO';*/
	
    Fnd_File.put_line (Fnd_File.LOG,'process flag : ' || l_process_flag);
  
	  --IF vn_count = 0 THEN
    IF NVL(l_process_flag,'SS') = 'SS' THEN -- OBE
  	
  		Fnd_File.put_line (Fnd_File.LOG,'Fermeture de la période : ' || vv_period_name);
  		Fnd_File.put_line (Fnd_File.OUTPUT,'    * Fermeture de la période : ' || vv_period_name);
  		-- Fermeture
      BEGIN
        UPDATE gl_period_statuses
        SET closing_status ='C'
        WHERE application_id = 200
        --AND set_of_books_id = vn_sob_id
        AND ledger_id = ledger.ledger_id -- OBE
        AND period_name = vv_period_name
        AND start_date = vd_start_date
        AND end_date = vd_end_date;
    		
        COMMIT;
      EXCEPTION
            WHEN OTHERS THEN
                  vv_mesg := substr(SQLERRM,1,400);
                  vv_mesg := 'ATTENTION : la période n''a pas été fermés ' || vv_period_name || ' : ' || vv_mesg;
                  Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg); --RBE artf2076969
                  pn_retcode := 2;
                 --ROLLBACK; --RBE artf2076969
                 --RAISE e_error;
      END;
  		  
        --
        -- Modif EMA du 12/01/2009 :
        -- Les factures bloquées dans l'Open Interface sont repoussées au dernier jour de la nouvelle période ouverte.
        --
        BEGIN
            UPDATE ap_invoices_interface
            SET    gl_date = vd_next_end_date --vd_end_date --RBE artf2121822
            WHERE  status != 'PROCESSED'
            AND    source != 'REFAC'
            AND    org_id IN (SELECT org_id
                              FROM   ap_system_parameters_all
                              WHERE  set_of_books_id           = ledger.ledger_id--vn_sob_id  -- A verifier
                              OR     secondary_set_of_books_id = ledger.ledger_id--vn_sob_id
                              );
  
  
            Fnd_File.put_line (Fnd_File.OUTPUT,'');
            Fnd_File.put_line (Fnd_File.OUTPUT,'    * ' || SQL%ROWCOUNT || ' factures ont été repoussées sur la période ' || vv_next_period_name);
  
            COMMIT;
            
            Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
  
        EXCEPTION
            WHEN OTHERS THEN
                  vv_mesg := substr(SQLERRM,1,400);
                  vv_mesg := 'ATTENTION : les factures n''ont pas été repoussées sur la période ' || vv_next_period_name || ' : ' || vv_mesg;
                  Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg); --RBE artf2076969
                  pn_retcode := 2;
                 --ROLLBACK; --RBE artf2076969
                 --RAISE e_error;
        END;
        
  	ELSE
      
  		vv_mesg := 'ATTENTION : La période ' || vv_period_name || ' n''est pas fermée ';
  		Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg); --RBE artf2076969
  		v_message    := dka_tools_pkg.get_message ('SQLAP', l_message);
  		Fnd_File.put_line (Fnd_File.OUTPUT,v_message); --RBE artf2076969
  		pn_retcode := 2;
  		--RAISE e_error; --RBE artf2076969
  	END IF;
  --
  -- Fin modif EMA du 12/01/2009
  --
      
  END LOOP; -- OBE

  --RBE artf2076969
  IF vn_count = 0 THEn
    Fnd_File.put_line (Fnd_File.OUTPUT,'Ancun livre n''est trouvé.'); --RBE artf2076969
    pn_retcode := 1;
  END IF;

  Fnd_File.put_line (Fnd_File.OUTPUT,'');
  Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
  Fnd_File.put_line (Fnd_File.OUTPUT,'+ Fin du traitement : '||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
  Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    
EXCEPTION
WHEN e_error THEN
	pv_errbuf := vv_mesg;
	pn_retcode := 2;        
WHEN OTHERS	THEN
	pv_errbuf     := vv_mesg || chr(10) || SQLERRM;
	pn_retcode    := 2;
END;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : launch_xdodtexe
--  Description   : Procédure de lancement des états des mouvements non comptabilisés
--
--  PARAMETRES    :
--	pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------     

PROCEDURE launch_xdodtexe ( pv_errbuf	IN OUT varchar2,
                            pn_retcode 	OUT number	)
IS
  TYPE t_request_id IS TABLE OF PLS_INTEGER;
  va_request_id       t_request_id := t_request_id();
  vn_nb_traitements   PLS_INTEGER := 0;
  
  vv_nv_reporting   VARCHAR(10);
  vv_entity_name    VARCHAR(50);
  vn_ledger_id      NUMBER;
  vv_transferer     VARCHAR(1);
  vv_diagnostic     VARCHAR(1);
  vv_analyse        VARCHAR(1);
  vn_access_set_id  NUMBER;
  vn_request_id     NUMBER;
  vn_tempo          NUMBER := 20;

  v_phase           VARCHAR2(100);
  v_status          VARCHAR2(100);
  v_dev_phase       VARCHAR2(100);
  v_dev_status      VARCHAR2(100);
  v_message         VARCHAR2(100);  
  
  v_user_id                NUMBER;                       
  v_resp_id                NUMBER;
  v_resp_appl_id           NUMBER;
    --- 14/04/2017 NBO artf2121822 - Cloture de la période AP - Impossible de transférer les écriture d'une période à l'autre
  vd_start_date	          DATE;
	vd_end_date	            DATE;
	vv_next_period_name	    VARCHAR2(30);
	vd_next_start_date	    DATE;
	vd_next_end_date	      DATE;
	vv_period_name	        VARCHAR2(30);
  l_count NUMBER;


  xml_layout boolean;  
  
  CURSOR cur_ledger (p_access_set_id IN NUMBER) IS
  SELECT ledger_id
  FROM GL_ACCESS_SET_LEDGERS
  WHERE access_set_id = p_access_set_id
  ;

BEGIN

  Fnd_File.put_line(Fnd_File.LOG, 'Récupération du jeu de livre');  
  vn_access_set_id := fnd_profile.VALUE ('GL_ACCESS_SET_ID');
  Fnd_File.put_line (Fnd_File.LOG,'vn_access_set_id : '||TO_CHAR(vn_access_set_id));
  
    v_user_id      := FND_PROFILE.VALUE('USER_ID');
    v_resp_id      := FND_PROFILE.VALUE('RESP_ID');    
    v_resp_appl_id := FND_PROFILE.VALUE('RESP_APPL_ID');

    APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                    RESP_ID      => v_resp_id,
                                    RESP_APPL_ID => v_resp_appl_id
                                    );
     MO_GLOBAL.INIT('SQLAP');
     
    --- 14/04/2017 NBO artf2121822 - Cloture de la période AP - Impossible de transférer les écriture d'une période à l'autre
    Fnd_File.put_line (Fnd_File.LOG,'Recherche de la première période ouverte');
    dka_sapcloture_pkg.cherche_period(vn_access_set_id, v_message,vd_start_date, vd_end_date, vv_period_name);

    -- Test si une période est ouverte
    IF vv_period_name IS NULL THEN
      --vv_mesg := 'Il n''y a pas de période ouverte';
      Fnd_File.put_line (Fnd_File.LOG,'Il n''y a pas de période ouverte');
      Fnd_File.put_line (Fnd_File.OUTPUT,'Il n''y a pas de période ouverte');
      pn_retcode := 1;
      RETURN;
    END IF;
    
      Fnd_File.put_line (Fnd_File.LOG,'Cloture de la période AP : ' || vv_period_name);

    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'| Période AP à clôturer : ' || vv_period_name);

    dka_sapcloture_pkg.cherche_next_period( vn_access_set_id, v_message,vv_period_name, vd_next_start_date, vd_next_end_date, vv_next_period_name );

    Fnd_File.put_line (Fnd_File.LOG,'Ouverture de la période AP : ' || vv_next_period_name);
      

  FOR ledger IN cur_ledger (vn_access_set_id) LOOP

      Fnd_File.put_line(Fnd_File.LOG, 'Lancement de l''état des mouvements non comptabilisés. Livre : '||ledger.ledger_id); 
      
      SELECT lookup_code 
      INTO vv_nv_reporting
      FROM FND_LOOKUPS 
      WHERE LOOKUP_TYPE ='FND_MO_REPORTING_LEVEL'  
      AND lookup_code IN (1000, 3000) 
      AND rownum=1
      ;
      Fnd_File.put_line(Fnd_File.LOG, 'vv_nv_reporting : '||vv_nv_reporting); 
      
      BEGIN
        SELECT entity_name, ledger_id 
        INTO vv_entity_name, vn_ledger_id
        FROM FND_MO_REPORTING_ENTITIES_V 
        WHERE ledger_category_code = 'PRIMARY' 
        AND ledger_id = ledger.ledger_id
        AND ROWNUM = 1
        ;
      EXCEPTION
        WHEN OTHERS THEN
          vv_entity_name := NULL;
          vn_ledger_id  := NULL;
      END;
      Fnd_File.put_line(Fnd_File.LOG, 'vv_entity_name : '||vv_entity_name); 
      Fnd_File.put_line(Fnd_File.LOG, 'vn_ledger_id : '||vn_ledger_id); 
      
      SELECT lookup_code 
      INTO vv_transferer
      FROM fnd_lookups 
      WHERE lookup_type='YES_NO' 
    --- 14/04/2017 NBO artf2121822 - Cloture de la période AP - Impossible de transférer les écriture d'une période à l'autre
      AND lookup_code='Y'
      ;
      Fnd_File.put_line(Fnd_File.LOG, 'vv_transferer : '||vv_transferer); 
      
      SELECT lookup_code 
      INTO vv_diagnostic
      FROM fnd_lookups 
      WHERE lookup_type='YES_NO' 
      AND lookup_code='N'
      ;
      Fnd_File.put_line(Fnd_File.LOG, 'vv_diagnostic : '||vv_diagnostic); 
      
      SELECT lookup_code 
      INTO vv_analyse
      FROM fnd_lookups 
      WHERE lookup_type='YES_NO' 
      AND lookup_code='N'
      ;
      Fnd_File.put_line(Fnd_File.LOG, 'vv_analyse : '||vv_analyse); 

      --- 14/04/2017 NBO artf2121822 - Cloture de la période AP - Impossible de transférer les écriture d'une période à l'autre
      SELECT COUNT(1)
      INTO l_count
      FROM gl_period_statuses
      WHERE period_name = vv_period_name
       AND application_id = 200
       AND closing_status = 'O'
       AND set_of_books_id = vn_ledger_id ;
       
          
      APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                      RESP_ID      => v_resp_id,
                                      RESP_APPL_ID => v_resp_appl_id
                               );

       --- 14/04/2017 NBO artf2121822 - Cloture de la période AP - Impossible de transférer les écriture d'une période à l'autre
      IF vn_ledger_id IS NOT NULL AND l_count = 1 THEN
          Fnd_File.put_line (Fnd_File.LOG,'Ouverture de la période suivante : ' || vv_next_period_name);
          Fnd_File.put_line (Fnd_File.OUTPUT,'    * Ouverture de la période : ' || vv_next_period_name);
          UPDATE gl_period_statuses
          SET closing_status ='O'
          WHERE application_id = 200
          --AND set_of_books_id = vn_sob_id
          AND ledger_id = ledger.ledger_id -- OBE
          AND period_name = vv_next_period_name
          AND start_date = vd_next_start_date
          AND end_date = vd_next_end_date
          AND closing_status !='O';
  		
  		    COMMIT;
 
          xml_layout := FND_REQUEST.ADD_LAYOUT('SQLAP'
                                                ,'APXUATR_RTF'
                                                ,'fr'
                                                ,'FR'
                                                ,'RTF');
      
          vn_request_id          := Fnd_Request.submit_request (
                                         'SQLAP'                          -- APPL
                                        ,'APXUATR_XMLP'                         -- PROG
                                        ,NULL                             -- PROGRAM_NAME
                                        ,NULL                             -- START
                                        ,FALSE                            -- SUB_REQUEST
                                        ,TO_NUMBER(vv_nv_reporting)
                                        ,vn_ledger_id
                                        ,vn_ledger_id
                                        ,NULL
                                        ,NULL
                                        ,vv_period_name
                                        ,vv_transferer
                                        ,vv_next_period_name
                                        ,vv_diagnostic
                                        ,vv_analyse
                                        );
          IF vn_request_id = 0
          THEN
              pn_retcode    := 2;
              fnd_file.put_line(fnd_file.LOG, 'ERREUR : L''Etat des mouvements non comptabilisés a échoué' || CHR(10) ||
                                              'PROGRAMME  : APXUATR_XMLP' || CHR(10)
                                              );
              Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : L''Etat des mouvements non comptabilisés a échoué');
          ELSE
              COMMIT;
              Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || vn_request_id);            
              Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de l''Etat des mouvements non comptabilisés : ' || vn_request_id);  
              
              --Stockage des numéros de traitements
              va_request_id.extend;
              vn_nb_traitements := vn_nb_traitements + 1;
              va_request_id(vn_nb_traitements) := vn_request_id;
              
            END IF;

     ELSE
        IF ledger.ledger_id IS NULL THEN
           Fnd_File.put_line(Fnd_File.LOG, 'Aucune donnée pour le livre : '||ledger.ledger_id); 
        END IF;
        
        IF l_count != 1 THEN
           Fnd_File.put_line(Fnd_File.LOG, 'La période '||vv_period_name|| ' n''est pas ouverte'); 
        END IF;
     END IF;
      
  END LOOP;
  
  ------------
  
  -- Attente de la fin du traitement
  FOR i IN 1..vn_nb_traitements LOOP
    IF NOT (Fnd_Concurrent.wait_for_request (va_request_id(i), vn_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
    THEN                        
        pv_errbuf  := v_Message;
        Fnd_file.put_line(Fnd_file.log, 'request_id = '||va_request_id(i)||' ERREUR : Attente de la fin du programme de l''Etat des mouvements non comptabilisés : Fin du traitement' || CHR(10) ||
                                        'MESSAGE : ' || v_Message || CHR(10) );  
    END IF;
                 
    IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
    THEN          
        Fnd_File.put_line(Fnd_File.LOG, 'request_id = '||va_request_id(i)||'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
        Fnd_File.put_line(Fnd_File.OUTPUT, 'request_id = '||va_request_id(i)||'. Statut de fin : ' || v_phase || '/' || v_status);

    ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
    THEN
        Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de l''Etat des mouvements non comptabilisés en warning '|| va_request_id(i));
        pn_retcode    := 1;

    ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
    THEN
        pn_retcode := 1;--2;
        pv_errbuf  := 'ERREUR : Fin anormale du traitement de l''Etat des mouvements non comptabilisés : '||v_Message;

        fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de l''Etat des mouvements non comptabilisés '|| va_request_id(i)  || CHR(10) ||
                                        'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                        'MESSAGE : ' || v_message || CHR(10) );
        Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de l''Etat des mouvements non comptabilisés '||va_request_id(i));
    END IF;
  END LOOP;
  ------------

EXCEPTION
  WHEN OTHERS	THEN
    pv_errbuf     := SQLERRM;
    pn_retcode    := 2;

END;
        	
END DKA_SAPCLOTURE_PKG; -- Package body
/
SHOW ERRORS;
EXIT
