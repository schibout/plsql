CREATE OR REPLACE PACKAGE BODY DKA_SARCLOTURE_PKG
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
-- 16/07/202	MSF	Affichage et gestion de l'erreur
--			ar_check_unposted_receipt_hist sortie du cursor
--- ---------- --- -------------------------------------------------------------------------
-- 13/01/2017  OBE Modification - artf2081747 - artf2081588
--------------------------------------------------------------------------------------------
-- 19/01/2017  OBE Modification - artf2086030
--------------------------------------------------------------------------------------------
-- 27/01/2017  OBE Modification - artf2086030 - Vidage de la table temporaire au début de la boucle
--------------------------------------------------------------------------------------------
-- 14/06/2017  OBE artf2172485 : SPE024 - Clôture AR - Ajout d'un contrôle supplementaire dans la clôture AR - Defect Bout_en_Bout_Helios_Ref #645
--------------------------------------------------------------------------------------------
-- 05/07/2017  NBO artf2190757 - SPE024 : Clôture AR ORA-06511: PL/SQL : curseur déjà ouvert - defect BeB 925
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
--     pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     pv_errbuf	varchar2
--     pd_start_date 	date
--     pd_end_date 	date
--     pd_period_name 	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE cherche_period ( pn_sob_id		IN OUT NUMBER,
			   pv_errbuf 		OUT VARCHAR2,
			   pd_start_date 	OUT DATE,
			   pd_end_date 		OUT DATE,
			   pv_period_name 	OUT VARCHAR2 ) 
IS
	vd_start_date DATE;
	vd_end_date DATE;
	vv_period_name VARCHAR2(30);
	vv_err VARCHAR2(400);

BEGIN	   

	pv_errbuf := NULL;
	
	-- Recherche de la première période en status ouvert
  
  --< OBE
  
	/*SELECT MIN(start_date), end_date, period_name 
	INTO vd_start_date, vd_end_date, vv_period_name
	FROM gl_period_statuses
	WHERE application_id = 222
	AND set_of_books_id = pn_sob_id
	AND closing_status = 'O'
	AND rownum = 1 
	GROUP BY start_date, end_date, period_name;*/
  
  SELECT START_DATE,
         END_DATE,
         PERIOD_NAME 
  INTO   vd_start_date,
         vd_end_date,
         vv_period_name
  FROM  gl_period_statuses  
  WHERE START_DATE IN (
                      --< OBE artf2086030
                    	/*SELECT MIN(gps.start_date)
                    	FROM gl_period_statuses gps
                    	WHERE gps.application_id = 222
                      AND gps.ledger_id = pn_sob_id
                    	AND gps.closing_status = 'O'*/
                      SELECT MIN(gps.start_date)
                    	FROM gl_period_statuses gps, GL_ACCESS_SET_LEDGERS gasl
                    	WHERE gps.application_id = 222
                      AND GASL.ACCESS_SET_ID = pn_sob_id
                      AND GASL.ledger_id = gps.ledger_id
                    	AND gps.closing_status = 'O'
                      --> OBE artf2086030
                    	)
	AND application_id = 222
	AND closing_status = 'O'
  AND rownum = 1
	;  
  
  --> OBE

	pd_start_date := vd_start_date;
	pd_end_date := vd_end_date;
	pv_period_name := vv_period_name;
	
	EXCEPTION
		WHEN OTHERS THEN
			vv_err := substr(SQLERRM,1,400);
			pv_errbuf := vv_err;
		
		
	
END;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHERCHE_NEXT_PERIOD
--  Description   : Recherche la période prochaine periode
--
--  PARAMETRES    :
--     pn_sob_id	number
--     pv_period_name	varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf	varchar2
--     pd_start_date 	date
--     pd_end_date 	date
--     pd_period_name 	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE cherche_next_period ( pn_sob_id		IN OUT NUMBER,
            pv_errbuf 		OUT VARCHAR2,
            pv_period_name 	IN VARCHAR2, -- OBE artf2086030
			   	 /*pd_start_date 		OUT DATE,  -- OBE artf2086030
			   	 pd_end_date 		OUT DATE,*/    -- OBE artf2086030
           pd_next_start_date 		 OUT DATE,
           pd_next_end_date 		   OUT DATE,
           pv_next_period_name  IN OUT VARCHAR2) 
IS
	vd_start_date DATE;
	vd_end_date DATE;
	vv_period_name VARCHAR2(30);
	vv_err VARCHAR2(400);

BEGIN	   

	pv_errbuf := NULL;
	
	-- Recherche de la première période en status ouvert
  --< OBE artf2086030
	/*SELECT start_date, end_date, period_name
	INTO vd_start_date, vd_end_date, vv_period_name
	FROM gl_period_statuses
	WHERE start_date IN ( SELECT end_date+1 
			      FROM gl_period_statuses
			      WHERE period_name = pv_period_name
			      AND application_id = 222
			      AND set_of_books_id = pn_sob_id )
	AND application_id = 222 
	AND set_of_books_id = pn_sob_id;*/
  
  SELECT DISTINCT start_date, end_date, period_name
	INTO vd_start_date, vd_end_date, vv_period_name
	FROM gl_period_statuses
	WHERE start_date IN ( SELECT end_date+1 
                        FROM gl_period_statuses 
                        WHERE period_name = pv_period_name
                        AND application_id = 222
                      )
	AND application_id = 222;
  

	--pd_start_date := vd_start_date;
	--pd_end_date := vd_end_date;
	--pv_period_name := vv_period_name;
  
  pd_next_start_date  := vd_start_date;
	pd_next_end_date    := vd_end_date;
	pv_next_period_name := vv_period_name;
  
  --> OBE artf2086030
	
	EXCEPTION
		WHEN OTHERS THEN
			vv_err := substr(SQLERRM,1,400);
			pv_errbuf := vv_err;	
	
END;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_unposted_items_gl
--  Description   : Recherche si toutes les factures sont postés ( module AR )
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
PROCEDURE ar_check_unposted_items_gl ( 	pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS
	
	vv_trx_number		 VARCHAR2(20);
	vd_trx_date		 DATE;
	vn_amount		 NUMBER;

	   
	CURSOR unposted_items_gl_cur IS 
   	SELECT  ct.trx_number,
   		trunc(ct.trx_date),
   		sum(gld.amount)
        FROM    ra_cust_trx_line_gl_dist_all gld,
                ra_customer_trx_all ct
        WHERE   gld.account_class = 'REC'
        AND   gld.latest_rec_flag='Y'
        AND   gld.account_set_flag = 'Y'
        AND   gld.gl_date BETWEEN pd_start_date
        		  AND pd_end_date                       
        AND   ct.customer_trx_id = gld.customer_trx_id
        AND   ct.complete_flag = 'Y'
--        AND   :control.accounting_method = 'ACCRUAL'
        AND    (gld.org_id IS NULL
        	OR gld.org_id IN (SELECT org_id
                		  FROM ar_system_parameters_All
                                  WHERE set_of_books_id = pn_sob_id                                                  
                                  AND ACCOUNTING_METHOD <> 'CASH')
               )
        AND    (ct.org_id IS NULL
        	OR ct.org_id IN (SELECT org_id
                		 FROM ar_system_parameters_All
                                 WHERE set_of_books_id = pn_sob_id
				)
                )
	GROUP BY ct.trx_number, trunc(ct.trx_date)
	ORDER BY ct.trx_number;

	
 BEGIN 
 
 	OPEN unposted_items_gl_cur;
 	
 	
 	FETCH unposted_items_gl_cur INTO vv_trx_number,
 					 vd_trx_date,
 					 vn_amount;
 	
 	IF unposted_items_gl_cur%FOUND THEN
 	
 		dka_tools_pkg.put_outdebug_message('===> Les factures sont postées : KO');--MSF
 		pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_RUN_AUTORULE');
      		dka_tools_pkg.put_outdebug_message(pv_errbuf);
      		dka_tools_pkg.put_outdebug_message('Facture : ' || vv_trx_number );
      		dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      		dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
      	
 	
 		LOOP
 	
 			FETCH unposted_items_gl_cur INTO vv_trx_number,
 							 vd_trx_date,
 							 vn_amount;
 							 
 			EXIT WHEN unposted_items_gl_cur%NOTFOUND;
      	
      			pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_RUN_AUTORULE');
      			dka_tools_pkg.put_outdebug_message(pv_errbuf);
      			dka_tools_pkg.put_outdebug_message('Facture : ' || vv_trx_number );
      			dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      			dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
      		    			      			
      		END LOOP;
      		
      		pv_status := 'KO';
      		      		
      	ELSE
      	
      		pv_status := 'OK';   	
      		
   	END IF;

  
  	CLOSE unposted_items_gl_cur;
  	
END ar_check_unposted_items_gl;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_unposted_adjustments
--  Description   : Recherche si tous les ajustements sont postés ( module AR )
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
PROCEDURE ar_check_unposted_adjustments ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS
	vv_trx_number		 VARCHAR2(20);
	vd_trx_date		 DATE;
	vn_amount		 NUMBER;
	vv_organisation		 VARCHAR2(20);

	   
	CURSOR unposted_adjustments_cur IS 
   	SELECT 	rct.trx_number,
   	    	trunc(rct.trx_date),
   		sum(adj.amount),
		hr.NAME
        FROM    ar_adjustments_all adj,
        	ra_customer_trx_all rct,
		hr_all_organization_units hr
        WHERE   adj.posting_control_id = -3
        AND     adj.gl_date  BETWEEN pd_start_date
                             AND pd_end_date
        AND     NVL(adj.postable,'Y') = 'Y'
        AND 	adj.customer_trx_id = rct.customer_trx_id
		and rct.org_id = hr.ORGANIZATION_ID
--        AND     :control.accounting_method = 'ACCRUAL'
  	AND    (adj.org_id IS NULL
                OR adj.org_id IN (SELECT org_id
        			  FROM ar_system_parameters_All
                                  WHERE set_of_books_id = pn_sob_id
                                  ) 
                )
        GROUP BY rct.trx_number, trunc(rct.trx_date),hr.NAME
        ORDER BY rct.trx_number; 

   
 BEGIN 
 
 	OPEN unposted_adjustments_cur;
 	
 	FETCH unposted_adjustments_cur INTO vv_trx_number,
 					 vd_trx_date,
 					 vn_amount,
 					 vv_organisation;
 							 
 	IF (unposted_adjustments_cur%FOUND) THEN
 	
	 	dka_tools_pkg.put_outdebug_message('===> Les ajustements factures sont postés KO');--MSF
	 	pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
 		dka_tools_pkg.put_outdebug_message(pv_errbuf);
      		dka_tools_pkg.put_outdebug_message('Société : ' || vv_organisation );
      		dka_tools_pkg.put_outdebug_message('Ajustement sur la facture : ' || vv_trx_number );
      		dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      		dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
 	
 		LOOP
 		
 			 			
 			FETCH unposted_adjustments_cur INTO vv_trx_number,
 							 vd_trx_date,
 							 vn_amount,
 							 vv_organisation;
 							 
 			EXIT WHEN unposted_adjustments_cur%NOTFOUND;
 	
 			pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
 			dka_tools_pkg.put_outdebug_message(pv_errbuf);
 			dka_tools_pkg.put_outdebug_message('Société : ' || vv_organisation );
      			dka_tools_pkg.put_outdebug_message('Ajustement sur la facture : ' || vv_trx_number );
      			dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      			dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
 			
      		
 		END LOOP;
 		
 		pv_status := 'KO';
   	
   	ELSE     	
      	
      		pv_status := 'OK';   	
      		
   	END IF;

	CLOSE unposted_adjustments_cur;
  
END ar_check_unposted_adjustments;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_unposted_distribution
--  Description   : Recherche si tous les réglements sont OK ( module AR )
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
PROCEDURE ar_check_unposted_distribution ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS
	vv_receipt_number	VARCHAR2(30);
	vd_receipt_date		DATE;
	vn_amount		NUMBER;

	   
	CURSOR unposted_distribution_cur IS 
   	SELECT  acr.receipt_number,
   		trunc(acr.receipt_date),
   		sum(amcd.amount)
        FROM    ar_misc_cash_distributions_all amcd,
        	ar_cash_receipts_all acr
        WHERE   amcd.posting_control_id = -3
        AND	amcd.cash_receipt_id = acr.cash_receipt_id
        AND     amcd.gl_date  BETWEEN pd_start_date
                         	AND pd_end_date
        AND    (amcd.org_id IS NULL
                 OR amcd.org_id IN (SELECT org_id
                               FROM ar_system_parameters_All
			       WHERE set_of_books_id = pn_sob_id
                              )
               )
        GROUP BY acr.receipt_number, trunc(acr.receipt_date)
        ORDER BY acr.receipt_number;
   
BEGIN 
 
 	OPEN unposted_distribution_cur;
 	
 	FETCH unposted_distribution_cur INTO vv_receipt_number,
 					     vd_receipt_date,
 					     vn_amount;
 	
 	IF unposted_distribution_cur%FOUND THEN
 	
 		pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
   		dka_tools_pkg.put_outdebug_message('===> Les réglements divers sont postés  KO');--MSF      	
   		dka_tools_pkg.put_outdebug_message(pv_errbuf);
      		dka_tools_pkg.put_outdebug_message('Réglement : ' || vv_receipt_number );
      		dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_receipt_date, 'DD/MM/RRRR' ));
      		dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
 		
 		LOOP
 		
 			FETCH unposted_distribution_cur INTO vv_receipt_number,
 						     vd_receipt_date,
 						     vn_amount;
 	
   		      	
   		      	EXIT WHEN unposted_distribution_cur%NOTFOUND;
   		      	
   		      	pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
   		      	dka_tools_pkg.put_outdebug_message(pv_errbuf);
      			dka_tools_pkg.put_outdebug_message('Réglement : ' || vv_receipt_number );
      			dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_receipt_date, 'DD/MM/RRRR' ));
      			dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
 			
      		
      		END LOOP;
      		
      		pv_status := 'KO';
      		     		      		
      	ELSE
      	
      		pv_status := 'OK';   	
      		
   	END IF;

  
  	CLOSE unposted_distribution_cur;
  	
END ar_check_unposted_distribution;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_unposted_gl_dist
--  Description   : Recherche si tous ??? ( module AR )
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
PROCEDURE ar_check_unposted_gl_dist ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS
	vv_trx_number	VARCHAR2(20);
	vd_trx_date	DATE;
	vn_amount	NUMBER;
	vv_organisation		 VARCHAR2(20);

	   
	CURSOR unposted_gl_dist_cur IS 
	SELECT 	ct.trx_number,
		trunc(ct.trx_date),
		sum(gl.amount),
		hr.NAME
        FROM    ra_customer_trx_all ct,
        	ra_cust_trx_line_gl_dist_all gl,
		hr_all_organization_units hr
	WHERE   gl.customer_trx_id = ct.customer_trx_id
        AND     ct.complete_flag = 'Y'
        AND     gl.account_set_flag = 'N'
		and ct.org_id = hr.ORGANIZATION_ID
        AND     gl.gl_date  BETWEEN pd_start_date
                           AND pd_end_date
        AND     gl.posting_control_id = -3
--	AND     :control.accounting_method = 'ACCRUAL'
        AND    (ct.org_id IS NULL
  		OR ct.org_id IN (SELECT org_id
                		 FROM ar_system_parameters_All
                                 WHERE set_of_books_id = pn_sob_id
                                )
               )
	AND    (gl.org_id IS NULL
                OR gl.org_id IN (SELECT org_id
        			 FROM ar_system_parameters_All
                                 WHERE set_of_books_id = pn_sob_id
				 AND ACCOUNTING_METHOD <> 'CASH')
		)
	GROUP BY ct.trx_number,
		 ct.trx_date,
		 hr.NAME
	ORDER BY ct.trx_number;
        
   
BEGIN 
 
 	OPEN unposted_gl_dist_cur;
 	
 	FETCH unposted_gl_dist_cur INTO vv_trx_number,
 					vd_trx_date,
 					vn_amount,
 					vv_organisation;
 	
 	
   	IF (unposted_gl_dist_cur%FOUND) THEN
   	
   		pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
		dka_tools_pkg.put_outdebug_message('===> Les revenus sont postés KO');--MSF
		dka_tools_pkg.put_outdebug_message(pv_errbuf);
		dka_tools_pkg.put_outdebug_message('Société : ' || vv_organisation );
      		dka_tools_pkg.put_outdebug_message('Facture : ' || vv_trx_number );
      		dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      		dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));      	   		
      	
      		LOOP
      		
      			FETCH unposted_gl_dist_cur INTO vv_trx_number,
 					vd_trx_date,
 					vn_amount,
 					vv_organisation;
 					
 			EXIT WHEN unposted_gl_dist_cur%NOTFOUND;
 			
      	   		pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
			dka_tools_pkg.put_outdebug_message(pv_errbuf);
			dka_tools_pkg.put_outdebug_message('Société : ' || vv_organisation );
      			dka_tools_pkg.put_outdebug_message('Facture : ' || vv_trx_number );
      			dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      			dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));      	   		
      			
      	   	END LOOP;
      	   	
      	   	pv_status := 'KO';
      		      		
      	ELSE
      	
      		pv_status := 'OK';   	
      		
   	END IF;
	
	CLOSE unposted_gl_dist_cur;
  
END ar_check_unposted_gl_dist;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_unposted_receivable
--  Description   : Recherche si tous ??? ( module AR )
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
PROCEDURE ar_check_unposted_receivable ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS


	vv_trx_number	VARCHAR2(20);
	vd_trx_date	DATE;

	
	
	   
	CURSOR unposted_receivable_cur IS 
	SELECT ct.trx_number,
	       trunc(ct.trx_date)
	FROM    ar_receivable_applications_all ra,
		ra_customer_trx_all ct
	WHERE   ra.posting_control_id = -3
	AND     ra.gl_date  BETWEEN pd_start_date
			    AND pd_end_date
	AND     NVL(ra.postable,'Y') = 'Y'
	AND     ra.customer_trx_id = ct.customer_trx_id
	--AND     ( :control.accounting_method = 'ACCRUAL'
	--          OR
	--                              ct.previous_customer_trx_id is null
	--           )
	AND    (ra.org_id IS NULL
		OR ra.org_id IN (SELECT org_id
        			 FROM ar_system_parameters_All
                        	 WHERE set_of_books_id = pn_sob_id
                        	)
		)
	AND    (ct.org_id IS NULL
		OR ct.org_id IN (SELECT org_id
        			FROM ar_system_parameters_All
                        	WHERE set_of_books_id = pn_sob_id
                        	)
		)
	ORDER BY ct.trx_number;        
   
BEGIN 
 	--dka_tools_pkg.put_outdebug_message('start_date '||pd_start_date);
	--dka_tools_pkg.put_outdebug_message('end_date '||pd_end_date);
	--dka_tools_pkg.put_outdebug_message('period_name '||pv_period_name);
	--dka_tools_pkg.put_outdebug_message('sob_id '||pn_sob_id);
 	OPEN unposted_receivable_cur;
 	
 	FETCH unposted_receivable_cur INTO vv_trx_number,
 					   vd_trx_date;
 	
 	
 	
   	IF (unposted_receivable_cur%FOUND) THEN

		pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
      		dka_tools_pkg.put_outdebug_message('===> Les avoirs sont postés KO');--MSF
      		dka_tools_pkg.put_outdebug_message(pv_errbuf);
      		dka_tools_pkg.put_outdebug_message('Facture : ' || vv_trx_number );
      		dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      	
      	
      		LOOP
      		
      			FETCH unposted_receivable_cur INTO vv_trx_number,
 						   vd_trx_date;
      			
      			EXIT WHEN unposted_receivable_cur%NOTFOUND;
      			
      			pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
      			dka_tools_pkg.put_outdebug_message(pv_errbuf);
      			dka_tools_pkg.put_outdebug_message('Facture : ' || vv_trx_number );
      			dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      	
      		
      		END LOOP;
      		
      		pv_status := 'KO';
      		      		
      	ELSE
      	
      		pv_status := 'OK';   	
      		
   	END IF;
	
	CLOSE unposted_receivable_cur;
  
END ar_check_unposted_receivable;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_unposted_receipt_hist
--  Description   : Recherche si tous ??? ( module AR )
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
PROCEDURE ar_check_unposted_receipt_hist ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS
	
	vv_receipt_number	VARCHAR2(30);
	vd_receipt_date		DATE;
	vn_amount		NUMBER;
	vv_organisation		 VARCHAR2(20);

	   
	CURSOR unposted_receipt_hist_cur IS 
	SELECT  acr.receipt_number,
		trunc(crh.trx_date),
		sum(crh.amount),
		hr.NAME
        FROM    ar_cash_receipt_history_all crh,
        	ar_cash_receipts_all acr,
		hr_all_organization_units hr
        WHERE	posting_control_id = -3
        AND	crh.cash_receipt_id = acr.cash_receipt_id
		and crh.org_id = hr.ORGANIZATION_ID
	AND     gl_date  BETWEEN pd_start_date
                         AND pd_end_date
	AND     postable_flag   = 'Y' 
        AND    (crh.org_id IS NULL
        	OR crh.org_id IN (SELECT org_id
                		  FROM ar_system_parameters_All
                                  WHERE set_of_books_id = pn_sob_id
				  )
		)
	GROUP BY acr.receipt_number,
		 trunc(crh.trx_date),hr.NAME
	ORDER BY acr.receipt_number;

BEGIN 
 
 	OPEN unposted_receipt_hist_cur;
 	
 	FETCH unposted_receipt_hist_cur INTO vv_receipt_number,
 					     vd_receipt_date,
 					     vn_amount,
 					     vv_organisation;
 	
 	
   	IF (unposted_receipt_hist_cur%FOUND) THEN
   	
   		pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
		dka_tools_pkg.put_outdebug_message(pv_errbuf);
		dka_tools_pkg.put_outdebug_message('===> Le cycle des réceptions KO');--MSF
		dka_tools_pkg.put_outdebug_message('Société : ' || vv_organisation );
	     	dka_tools_pkg.put_outdebug_message('Réglement : ' || vv_receipt_number );
      		dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_receipt_date, 'DD/MM/RRRR' ));
      		dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));      			
      	
      		LOOP 
      		--***********msf 16/07/02
      			FETCH unposted_receipt_hist_cur INTO vv_receipt_number,
 					     		vd_receipt_date,
 					     		vn_amount,
 					     		vv_organisation;
      			
      			EXIT WHEN unposted_receipt_hist_cur%NOTFOUND;
      		--***********msf 16/07/02	
      			pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_TRANS');
			dka_tools_pkg.put_outdebug_message(pv_errbuf);
			dka_tools_pkg.put_outdebug_message('Société : ' || vv_organisation );
	     		dka_tools_pkg.put_outdebug_message('Réglement : ' || vv_receipt_number );
      			dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_receipt_date, 'DD/MM/RRRR' ));
      			dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));      			
      				
      		END LOOP;
      		
      		pv_status := 'KO';
      		      		
      	ELSE
      	
      		pv_status := 'OK';   	
      		
   	END IF;
	
	CLOSE unposted_receipt_hist_cur;
  
END ar_check_unposted_receipt_hist;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_cash_receipts
--  Description   : Recherche si tous ??? ( module AR )
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
PROCEDURE ar_check_cash_receipts ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS
	
	vv_receipt_number	VARCHAR2(30);
	vd_receipt_date		DATE;
	vn_amount		NUMBER;

	   
	CURSOR cash_receipts_cur IS 
	SELECT 	icr.receipt_number,
		trunc(icr.receipt_date),
		sum(icr.amount)
	FROM    ar_interim_cash_receipts_all icr
        WHERE   icr.gl_date  BETWEEN pd_start_date
                             AND pd_end_date
	AND    (icr.org_id IS NULL
        	OR icr.org_id IN (SELECT org_id
                		  FROM ar_system_parameters_All
                                  WHERE set_of_books_id = pn_sob_id
				 )
                )
        GROUP BY icr.receipt_number,
        	 trunc(icr.receipt_date)
       	ORDER BY icr.receipt_number;



BEGIN 
 
 	OPEN cash_receipts_cur;
 	
 	FETCH cash_receipts_cur INTO vv_receipt_number,
 				     vd_receipt_date,
 				     vn_amount;
 	
 	
 	
   	IF (cash_receipts_cur%FOUND) THEN
      	
	      	pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_UNPOSTED_INTERIM');
      		dka_tools_pkg.put_outdebug_message('===> QuickCash KO');--MSF
      		dka_tools_pkg.put_outdebug_message(pv_errbuf);
      		dka_tools_pkg.put_outdebug_message('Réglement : ' || vv_receipt_number );
      		dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_receipt_date, 'DD/MM/RRRR' ));
      		dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
      		
      		LOOP
      			
      			FETCH cash_receipts_cur INTO vv_receipt_number,
 					     vd_receipt_date,
 					     vn_amount;
 			
      			
      			pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_UNPOSTED_INTERIM');
      			dka_tools_pkg.put_outdebug_message(pv_errbuf);
      			dka_tools_pkg.put_outdebug_message('Réglement : ' || vv_receipt_number );
      			dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_receipt_date, 'DD/MM/RRRR' ));
      			dka_tools_pkg.put_outdebug_message('Montant ' || to_char(vn_amount, '999G999G999G999D99' ));
      			
      			
      		END LOOP;
      		
      		pv_status := 'KO';
      		
      		      		
      	ELSE
      	
      		pv_status := 'OK';   	
      		
   	END IF;
	
	CLOSE cash_receipts_cur;
  
END ar_check_cash_receipts;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_unposted_transaction_hist
--  Description   : Recherche si tous ??? ( module AR )
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
PROCEDURE ar_check_unposted_transaction ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2)

IS
	vv_trx_number	VARCHAR2(20);
	vd_trx_date	DATE;
	vn_amount	NUMBER;

	   
	CURSOR unposted_transaction_hist_cur IS 
	SELECT  rct.trx_number,
		trunc(rct.trx_date)
	FROM    ar_transaction_history_all trh,
        	ra_customer_trx_all rct
        WHERE   trh.posting_control_id = -3
        AND	trh.customer_trx_id = rct.customer_trx_id
        AND     trh.gl_date  BETWEEN pd_start_date
        		     AND pd_end_date
	AND     trh.postable_flag   = 'Y' 
        AND    (trh.org_id IS NULL
        	OR trh.org_id IN (SELECT sp.org_id
                		  FROM ar_system_parameters_All sp
                                  WHERE sp.set_of_books_id = pn_sob_id)
                )
        ORDER BY rct.trx_number;

BEGIN 
 
 	OPEN unposted_transaction_hist_cur;
 	
 	FETCH unposted_transaction_hist_cur INTO vv_trx_number, 
 						 vd_trx_date;
 						 
 	
 		
    	
   	IF (unposted_transaction_hist_cur%FOUND) THEN
      	
      		pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_BR');
		dka_tools_pkg.put_outdebug_message('===> Détails de facturation KO');--MSF
		dka_tools_pkg.put_outdebug_message(pv_errbuf);
      		dka_tools_pkg.put_outdebug_message('Facture : ' || vv_trx_number );
      		dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      	
      		LOOP
      		
      			FETCH unposted_transaction_hist_cur INTO vv_trx_number, 
 						 vd_trx_date;
      			
      			EXIT WHEN unposted_transaction_hist_cur%NOTFOUND;
      			
      			pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_VAL_POST_BR');
      			dka_tools_pkg.put_outdebug_message(pv_errbuf);
      			dka_tools_pkg.put_outdebug_message('Facture : ' || vv_trx_number );
      			dka_tools_pkg.put_outdebug_message('Date : ' || to_char(vd_trx_date, 'DD/MM/RRRR' ));
      			
      		
      		END LOOP;
      		
      		pv_status := 'KO';
      		      		
      	ELSE
      	
      		pv_status := 'OK';   	
      		
   	END IF;
	
	CLOSE unposted_transaction_hist_cur;
  
END ar_check_unposted_transaction;


--< OBE artf2172485
-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_gl_transfer
--  Description   : Recherche si tous ??? ( module AR )
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
PROCEDURE ar_check_gl_transfer (pv_period_name 	IN VARCHAR2,
                                pn_sob_id 	IN NUMBER,
                                pv_errbuf 	OUT VARCHAR2,
                                pv_status 	OUT VARCHAR2)

IS

l_cannot_close_period BOOLEAN;
l_incomplete_events   BOOLEAN;

BEGIN 

    -- 05/07/2017  NBO artf2190757 - SPE024 : Clôture AR ORA-06511: PL/SQL : curseur déjà ouvert - defect BeB 925
    IF xla_period_close_exp_pkg.period_close_cur_header%ISOPEN THEN
      CLOSE xla_period_close_exp_pkg.period_close_cur_header;
    END IF;
   
    IF XLA_PERIOD_CLOSE_EXP_PKG.period_close_cur_evt%ISOPEN THEN
      CLOSE XLA_PERIOD_CLOSE_EXP_PKG.period_close_cur_evt;
    END IF; 
    -- Fin  05/07/2017  NBO artf2190757 - SPE024 : Clôture AR ORA-06511: PL/SQL : curseur déjà ouvert - defect BeB 925
  
    
    arp_xla_events.ar_xla_period_close
             (P_APPLICATION_ID => 222,
              P_LEDGER_ID => pn_sob_id,
              P_PERIOD_NAME => pv_period_name,
              P_CANNOT_CLOSE_PERIOD => l_cannot_close_period,
              P_INCOMPLETE_EVENTS => l_incomplete_events);

    IF (l_cannot_close_period) then

         pv_errbuf := dka_tools_pkg.get_message('AR','AR_SU_PENDING_GLTRANSFER','PERIOD_NAME',pv_period_name);
         dka_tools_pkg.put_outdebug_message(pv_errbuf);
         pv_status := 'KO';
    ELSE
         pv_status := 'OK';   
    END IF;    
    
  
END ar_check_gl_transfer;
--< OBE artf2172485


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

	vn_sob_id		NUMBER;
	vv_mesg			VARCHAR2(4000);
	vd_start_date		DATE;
	vd_end_date		DATE;
	vv_period_name		VARCHAR2(30) := NULL;
	vn_count		NUMBER := 0;
	vv_status		VARCHAR2(2);
	vn_period_num		NUMBER;
	test VARCHAR2(10);
	vv_responsibility_name VARCHAR2(50);
	vn_responsibility_id number;
	vn_application_id number;
  
  --< OBE artf2086030
  vv_next_period_name	    VARCHAR2(30);
	vd_next_start_date	    DATE;
	vd_next_end_date	      DATE;
  vn_ledger_id            NUMBER;
  --> OBE artf2086030

   --RBE
   vn_count_close         NUMBER:=0;
   vn_count_no_close      NUMBER:=0;

	rec_error		EXCEPTION;
	
	CURSOR cur_ledger_id (p_access_set_id IN NUMBER)  IS
	/*SELECT   gl.ledger_id AS ledger_id, gl.name 
	FROM     gl_access_set_assignments gasa, gl_ledgers gl
	WHERE    access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
	AND      gl.ledger_id = gasa.ledger_id
	AND      gl.ledger_category_code = 'PRIMARY';*/  
  --< OBE artf2086030
  SELECT GASL.ledger_id , gl.name
  FROM GL_ACCESS_SET_LEDGERS GASL ,GL_LEDGERS GL ,gl_period_statuses gps
  WHERE GASL.ACCESS_SET_ID = P_ACCESS_SET_ID
  AND  GASL.ledger_id = gl.ledger_id
  AND  gl.LEDGER_CATEGORY_CODE = 'PRIMARY'
  AND  GL.ledger_id = gps.ledger_id
  AND  gps.application_id = 222
  AND  gps.closing_status = 'O'
  AND  gps.period_name = vv_period_name
  --> OBE artf2086030
  ;

	
BEGIN


        dka_tools_pkg.put_debug_message ('main (+)');
        pv_errbuf     := NULL;
        pn_retcode    := 0;
	
  --< OBE
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'| DKA : Cloture de la période AR | Request ID : '||fnd_global.conc_request_id);
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'');
    
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'+ Début du traitement : '||TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'');
  --> OBE  

	--execute immediate 'truncate table dka.dka_sarcloture'; -- OBE
	
	vv_responsibility_name := 'TOUT_AR_ADMINISTRATEUR';
	SELECT fr.responsibility_id, fr.application_id
     INTO vn_responsibility_id, vn_application_id
     FROM fnd_responsibility fr
     WHERE fr.responsibility_key = vv_responsibility_name;
     --dka_tools_pkg.put_outdebug_message('-------------------------------------------'||'Responsabilité : '|| vn_responsibility_id || vn_application_id ); -- OBE
	 fnd_global.apps_initialize(fnd_global.user_id,vn_responsibility_id,vn_application_id);

	  
		
	dka_tools_pkg.put_debug_message ('+------------------------------------------------+');
	dka_tools_pkg.put_debug_message ('| Recherche de la première période ouverte');
	dka_tools_pkg.put_debug_message ('+------------------------------------------------+');
	
	
  --< OBE artf2086030
  
    vn_sob_id := fnd_profile.VALUE ('GL_ACCESS_SET_ID');
    Fnd_File.put_line (Fnd_File.LOG,'GL_ACCESS_SET_ID : '||TO_CHAR(vn_sob_id));

    --Fnd_File.put_line (Fnd_File.LOG,'Recherche de la première période ouverte');
    dka_sarcloture_pkg.cherche_period(vn_sob_id, vv_mesg,vd_start_date, vd_end_date, vv_period_name);
    

    -- Test si une période est ouverte
    IF vv_period_name IS NULL THEN
      Fnd_File.put_line (Fnd_File.LOG,'Il n''y a pas de période ouverte');
      Fnd_File.put_line (Fnd_File.OUTPUT,'Il n''y a pas de période ouverte');
      pn_retcode := 2;
      RETURN;
    END IF;  
    
    Fnd_File.put_line (Fnd_File.LOG,'Cloture de la période AR : ' || vv_period_name);

    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'| Période AR à clôturer : ' || vv_period_name);

    dka_sarcloture_pkg.cherche_next_period( vn_sob_id, vv_mesg,vv_period_name, vd_next_start_date, vd_next_end_date, vv_next_period_name );

    Fnd_File.put_line (Fnd_File.LOG,'Ouverture de la période AR : ' || vv_next_period_name);
    
    Fnd_File.put_line (Fnd_File.OUTPUT,'| Période AR à ouvrir   : ' || vv_next_period_name);
    Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
    Fnd_File.put_line (Fnd_File.OUTPUT,'');    
    
    
  --> OBE artf2086030
  
  
  
	FOR c_tmp in cur_ledger_id (vn_sob_id) -- OBE artf2086030
	LOOP
  
    DELETE dka_sarcloture; -- OBE
    
		vv_mesg := 'RECHERCHE DU SOB ID';
		--dka_tools_pkg.put_outdebug_message('RECHERCHE DU SOB ID'); -- OBE
    
		  vn_ledger_id := c_tmp.ledger_id;                                                                  -- OBE artf2086030
		--dka_sarcloture_pkg.cherche_period(vn_sob_id, vv_mesg,vd_start_date, vd_end_date, vv_period_name); -- OBE artf2086030
    
    
		--dka_tools_pkg.put_outdebug_message('ledger id: '||vn_sob_id); -- OBE
    --dka_tools_pkg.put_outdebug_message('====> Livre : '||c_tmp.name);
    dka_tools_pkg.put_outdebug_message ('+------------------------------------------------+');
		dka_tools_pkg.put_outdebug_message ('| Livre : ' || c_tmp.name);
		dka_tools_pkg.put_outdebug_message ('+------------------------------------------------+');

		
		
		--dka_tools_pkg.put_debug_message ('+------------------------------------------------+');
		--dka_tools_pkg.put_debug_message ('| Cloture de la période AR : ' || vv_period_name);
		--dka_tools_pkg.put_debug_message ('+------------------------------------------------+');

		-- Test si une période est ouverte
    --< OBE artf2086030
		/*IF vv_period_name IS NULL THEN
			vv_mesg := 'Il n''y a pas de période ouverte';
			RAISE rec_error;
		END IF;  */
    --> OBE artf2086030
			
		-- Test 1 :
		dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('test1');  -- OBE
		DKA_SARCLOTURE_PKG.ar_check_unposted_items_gl(vd_start_date, vd_end_date, vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		
		IF vv_status = 'KO' THEN
			
			DBMS_OUTPUT.PUT_LINE(vv_mesg);	
			dka_tools_pkg.put_outdebug_message('===> Les règles de factures sont postées : KO');
			--insert INTO dka_sarcloture VALUES(vn_sob_id, vv_period_name, '===> Les factures sont postées : KO', 'KO', vv_mesg);
      insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les règles de factures sont postées : KO', 'KO', vv_mesg); 
		ELSE
		
			--dka_tools_pkg.put_outdebug_message('===> Les factures sont postées OK');
      dka_tools_pkg.put_outdebug_message('===> Les règles de factures sont postées OK');
			--insert INTO dka_sarcloture VALUES(vn_sob_id, vv_period_name, '===> Les factures sont postées OK', 'OK', vv_mesg);
      insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les règles de factures sont postées OK', 'OK', vv_mesg);
		
		END IF;
		
		-- Test 2
		--dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('test2');
		DKA_SARCLOTURE_PKG.ar_check_unposted_adjustments(vd_start_date, vd_end_date, vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		IF vv_status = 'KO' THEN
		
			dka_tools_pkg.put_outdebug_message('===> Les ajustements factures sont postés KO');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les ajustements factures sont postés KO', 'KO', vv_mesg);
			
		ELSE
		
			dka_tools_pkg.put_outdebug_message('===> Les ajustements factures sont postés OK');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les ajustements factures sont postés OK', 'OK', vv_mesg);
			
		END IF;
		
		-- Test 3
		--dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('test3');
		DKA_SARCLOTURE_PKG.ar_check_unposted_distribution(vd_start_date, vd_end_date, vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		IF vv_status = 'KO' THEN
		
			dka_tools_pkg.put_outdebug_message('===> Les réglements divers sont postés  KO');--MSF
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les réglements divers sont postés  KO', 'KO', vv_mesg);
			
		ELSE
		
			dka_tools_pkg.put_outdebug_message('===> Les réglements divers sont postés OK');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les réglements divers sont postés OK', 'OK', vv_mesg);
			
		END IF;
		
		-- Test 4
		--dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('test4');
		DKA_SARCLOTURE_PKG.ar_check_unposted_gl_dist(vd_start_date, vd_end_date, vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		IF vv_status = 'KO' THEN
		
			dka_tools_pkg.put_outdebug_message('===> Les lignes de factures sont postées KO');--MSF
			--insert INTO dka_sarcloture VALUES(vn_sob_id, vv_period_name, '===> Les revenus sont postés KO', 'KO', vv_mesg);
      insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les lignes de factures sont postées KO', 'KO', vv_mesg);
			
		ELSE
		
			--dka_tools_pkg.put_outdebug_message('===> Les revenus sont postés OK');
      dka_tools_pkg.put_outdebug_message('===> Les lignes de factures sont postées OK');
			--insert INTO dka_sarcloture VALUES(vn_sob_id, vv_period_name, '===> Les revenus sont postés OK', 'OK', vv_mesg);
      insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les lignes de factures sont postées OK', 'OK', vv_mesg);
			
		END IF;
		
		-- Test 5
		--dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('test5');
		DKA_SARCLOTURE_PKG.ar_check_unposted_receivable(vd_start_date, vd_end_date, vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		IF vv_status = 'KO' THEN
		
			dka_tools_pkg.put_outdebug_message('===> Les avoirs sont postés KO');--MSF
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les avoirs sont postés KO', 'KO', vv_mesg);
			
		ELSE
		
			dka_tools_pkg.put_outdebug_message('===> Les avoirs sont postés OK');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Les avoirs sont postés OK', 'OK', vv_mesg);
		
		END IF;
		
		-- Test 6
		--dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('test6');
		DKA_SARCLOTURE_PKG.ar_check_unposted_receipt_hist(vd_start_date, vd_end_date, vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		IF vv_status = 'KO' THEN
		
			dka_tools_pkg.put_outdebug_message('===> Le cycle des réceptions KO');--MSF
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Le cycle des réceptions KO', 'KO', vv_mesg);
		
		ELSE
		
			dka_tools_pkg.put_outdebug_message('===> Le cycle des réceptions OK');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Le cycle des réceptions OK', 'OK', vv_mesg);
			
		END IF;
		
		-- Test 7
		--dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('test7');
		DKA_SARCLOTURE_PKG.ar_check_cash_receipts(vd_start_date, vd_end_date, vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		IF vv_status = 'KO' THEN
		
			dka_tools_pkg.put_outdebug_message('===> QuickCash KO');--MSF
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> QuickCash KO', 'KO', vv_mesg);
			
		ELSE
		
			dka_tools_pkg.put_outdebug_message('===> QuickCash OK');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> QuickCash OK', 'OK', vv_mesg);
			
		END IF;
		
		-- Test 8
		--dka_tools_pkg.put_outdebug_message('');
		--dka_tools_pkg.put_outdebug_message('test8');
		DKA_SARCLOTURE_PKG.ar_check_unposted_transaction(vd_start_date, vd_end_date, vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		IF vv_status = 'KO' THEN
		
			dka_tools_pkg.put_outdebug_message('===> Détails de facturation KO');--MSF
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Détails de facturation KO', 'KO', vv_mesg);
			
		ELSE
		
			dka_tools_pkg.put_outdebug_message('===> Détails de facturation OK');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Détails de facturation OK', 'OK', vv_mesg);
			
		END IF;
    
    --< OBE artf2172485
		-- Test 9
		DKA_SARCLOTURE_PKG.ar_check_gl_transfer(vv_period_name, vn_ledger_id, vv_mesg, vv_status );
		IF vv_status = 'KO' THEN
		
			dka_tools_pkg.put_outdebug_message('===> Transfert vers GL KO');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Transfert vers GL KO', 'KO', vv_mesg);
			
		ELSE
		
			dka_tools_pkg.put_outdebug_message('===> Transfert vers GL OK');
			insert INTO dka_sarcloture VALUES(vn_ledger_id, vv_period_name, '===> Transfert vers GL OK', 'OK', vv_mesg);
			
		END IF;    
    --> OBE artf2172485
		
		-- Fermeture de la période ouverte et ouverture de la suivante
		-- Si pas d'erreur
		SELECT COUNT(1)
		INTO vn_count
		FROM dka_sarcloture
		WHERE status = 'KO';
		
		IF vn_count = 0 THEN
		
			--dka_tools_pkg.put_outdebug_message('===> Fermeture de la période : ' || vv_period_name );
        dka_tools_pkg.put_outdebug_message('');
        Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
        Fnd_File.put_line (Fnd_File.OUTPUT,'| Fermeture de la période : ' || vv_period_name);
			-- Fermeture
			UPDATE gl_period_statuses
			SET closing_status ='C'
			WHERE application_id = 222
			--AND set_of_books_id = vn_sob_id
      AND ledger_id = c_tmp.ledger_id -- OBE artf2086030
			AND period_name = vv_period_name 
			AND start_date = vd_start_date
			AND end_date = vd_end_date;
			
			-- Ouverture de la suivante
			--dka_sarcloture_pkg.cherche_next_period(vn_sob_id, vv_mesg, vd_start_date, vd_end_date, vv_period_name ); -- OBE artf2086030
			--dka_tools_pkg.put_outdebug_message('===> Ouverture de la période : ' || vv_period_name );
      Fnd_File.put_line (Fnd_File.OUTPUT,'| Ouverture de la période : ' || vv_next_period_name);
      Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
      Fnd_File.put_line (Fnd_File.OUTPUT,'');      
			UPDATE gl_period_statuses
			SET closing_status ='O'
			WHERE application_id = 222
			--AND set_of_books_id = vn_sob_id
      AND ledger_id = c_tmp.ledger_id       -- OBE artf2086030
			AND period_name = vv_next_period_name -- OBE artf2086030
			AND start_date = vd_next_start_date   -- OBE artf2086030
			AND end_date = vd_next_end_date;      -- OBE artf2086030
      
      COMMIT;

      --RBE      
      vn_count_close := vn_count_close + 1;
		
		ELSE
			--MSF:18/07/02
			--**********************************
			/*dka_tools_pkg.put_outdebug_message('===> Fermeture en attente de la période : ' || vv_period_name );
			dka_tools_pkg.put_outdebug_message('===> Fermeture en attente de la période : ' || vn_sob_id );
			dka_tools_pkg.put_outdebug_message('===> Fermeture en attente de la période : ' || vd_start_date );
			dka_tools_pkg.put_outdebug_message('===> Fermeture en attente de la période : ' || vd_end_date );*/
      
      --< OBE artf2086030
      /*
      Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
      Fnd_File.put_line (Fnd_File.OUTPUT,'| Fermeture en attente de la période : ' || vv_period_name);
      Fnd_File.put_line (Fnd_File.OUTPUT,'| Livre                              : ' || c_tmp.name);
      Fnd_File.put_line (Fnd_File.OUTPUT,'| Date début                         : ' || vd_start_date);
      Fnd_File.put_line (Fnd_File.OUTPUT,'| Date fin                           : ' || vd_end_date);
      Fnd_File.put_line (Fnd_File.OUTPUT,'+-------------------------------------------------------+');
      
      
			-- Fermeture
			UPDATE gl_period_statuses
			SET closing_status ='W'
			WHERE application_id = 222
			AND set_of_books_id = vn_sob_id
			AND period_name = vv_period_name
			AND start_date = vd_start_date
			AND end_date = vd_end_date;
			
			
			select closing_status into test from gl_period_statuses WHERE application_id = 222
			AND set_of_books_id = vn_sob_id
			AND period_name = vv_period_name
			AND start_date = vd_start_date
			AND end_date = vd_end_date;
			
			dka_tools_pkg.put_outdebug_message('Le statut est : '|| test);
			vv_mesg := 'La période '||vv_period_name||' est fermée en attente';
			-- Ouverture de la suivante
			dka_sarcloture_pkg.cherche_next_period(vn_sob_id, vv_mesg, vd_start_date, vd_end_date, vv_period_name );
			dka_tools_pkg.put_outdebug_message('===> Ouverture de la période : ' || vv_period_name );
			UPDATE gl_period_statuses
			SET closing_status ='O'
			WHERE application_id = 222
			AND set_of_books_id = vn_sob_id
			AND period_name = vv_period_name
			AND start_date = vd_start_date
			AND end_date = vd_end_date;
			--**********************************
			COMMIT;
			RAISE rec_error;
      */
      
      
  		
  		Fnd_File.put_line (Fnd_File.OUTPUT,'ATTENTION : La période ' || vv_period_name || ' n''est pas fermée '); 
  		--Fnd_File.put_line (Fnd_File.OUTPUT,vv_mesg);
  		pn_retcode := 2;      
      COMMIT;
      
      --RBE      
      vn_count_no_close := vn_count_no_close + 1;

      --> OBE artf2086030
			
		END IF;
	END LOOP;

   --RBE   
   Fnd_File.put_line (Fnd_File.OUTPUT,'');
   Fnd_File.put_line (Fnd_File.OUTPUT,'Synthèse des Livres sélectionnés : ');
   Fnd_File.put_line (Fnd_File.OUTPUT,'');
   Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de livres Sélectionnés pour la Clôture AR : ' || TO_CHAR(vn_count_close + vn_count_no_close));
   Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de livres Clôturés     : ' || TO_CHAR(vn_count_close));
   Fnd_File.put_line (Fnd_File.OUTPUT,'Nombre de livres non Clôturés : ' || TO_CHAR(vn_count_no_close));
	
   IF pn_retcode = 2 THEN
      pv_errbuf := 'Traitement DKA_SARCLOTURE s''est terminé en Erreur. Tous les livres n''ont pas été traités';
   END IF;

        EXCEPTION
                WHEN rec_error THEN
                    pv_errbuf := vv_mesg;
        	    pn_retcode := 1;        
                WHEN OTHERS THEN
		    vv_mesg := vv_mesg || chr(10) || substr(SQLERRM,1,400);
                    pv_errbuf := vv_mesg;
        	    pn_retcode := 2;        


END;

    

END DKA_SARCLOTURE_PKG; -- Package body
/
SHOW ERRORS;
EXIT;
