CREATE OR REPLACE PACKAGE DKA_SARCLOTURE_PKG
AS

----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SCLOPERIOD_PKG.pks
-- DESCRIPTION       : DKA_SCLOPERIOD_PKG package spec :
---
--- AUTEUR           : Ulrich VANDEWEGHE (CGEY)
--- DATE DE CREATION : 28/05/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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
PROCEDURE cherche_period ( pn_sob_id 		IN OUT NUMBER,
			   pv_errbuf 		OUT VARCHAR2,
			   pd_start_date 	OUT DATE,
			   pd_end_date 		OUT DATE,
			   pv_period_name 	OUT VARCHAR2 ) ;
			   
			   

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
           pv_next_period_name  IN OUT VARCHAR2) ;
			   	 			 

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
				 	pv_status 	OUT VARCHAR2);

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
				 	pv_status 	OUT VARCHAR2);


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
				 	pv_status 	OUT VARCHAR2);



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
				 	pv_status 	OUT VARCHAR2);


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
				 	pv_status 	OUT VARCHAR2);


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
				 	pv_status 	OUT VARCHAR2);


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
				 	pv_status 	OUT VARCHAR2);


-------------------------------------------------------------------------------------------------------------------
--  Nom           : ar_check_unposted_transaction
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
				 	pv_status 	OUT VARCHAR2);
				 	
				 	
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
		 pn_retcode 	OUT number	);
				 	
				 	
END DKA_SARCLOTURE_PKG; -- Package Spécif

/
SHOW ERRORS;
EXIT
