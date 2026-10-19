SET VERIFY OFF;
DEFINE package_name = "DKA_SAPCLOTURE_PKG";

CREATE OR REPLACE PACKAGE &&package_name
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
--- 09/01/2017 RBE Correction artf2076969
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
			   pv_period_name 	IN OUT VARCHAR2 ) ;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CHERCHE_NEXT_PERIOD
--  Description   : Recherche la période prochaine periode
--
--  PARAMETRES    :
--     pn_sob_id	number
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
                      		    ) ;			   

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
			   	    pv_status		OUT VARCHAR2 ) ;
			   
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
				 pv_status 	OUT VARCHAR2);
				
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
				 pv_status 	OUT VARCHAR2);


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
PROCEDURE ap_check_unposted_invoices ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name IN VARCHAR2,
				 	pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2);


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
				 	pv_status 	OUT VARCHAR2);
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
		 pn_retcode 	OUT number	);
     
     
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
                            pn_retcode 	OUT number	);     
		 
		 
END &&package_name; -- Package Spécif
/

SHOW ERRORS;
EXIT