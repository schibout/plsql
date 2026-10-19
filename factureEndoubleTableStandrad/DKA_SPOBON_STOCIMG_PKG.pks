CREATE OR REPLACE PACKAGE DKA_SPACLOTURE_PKG
AS

----------------------------------------------------------------------------------------------
-- $Id: DKA_SPACLOTURE_PKG.pks 271 2008-03-26 10:13:20Z NORDEST\jdequidt $
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPACLOTURE_PKG.pks
-- DESCRIPTION       : DKA_SPACLOTURE_PKG package spec :
---
--- AUTEUR           : Ulrich VANDEWEGHE (CGEY)
--- DATE DE CREATION : 28/05/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 21/03/2008 JDE CSP Portabilité Ajout de l'ORG_ID en paramètre
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
PROCEDURE cherche_period ( --pn_sob_id 		IN OUT NUMBER,
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
--     pv_period_name	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE cherche_next_period ( --pn_sob_id		IN OUT NUMBER,
				   pv_errbuf 		OUT VARCHAR2,
			   	 pd_start_date 		OUT DATE,
			   	 pd_end_date 		OUT DATE,
			   	 pv_period_name 	IN VARCHAR2,
			   	 pv_next_period_name 	IN OUT VARCHAR2  );			   

-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_transfer_to_ap
--  Description   : Recherche si toutes les factures sont transférées dans AP ( module PA )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--  pn_org_id number
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE pa_check_transfer_to_ap ( 	pd_start_date 	IN DATE,
				 	pd_end_date 	  IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_org_id       IN NUMBER,
				 	--pn_sob_id 	    IN NUMBER,
				 	pv_errbuf 	    OUT VARCHAR2,
				 	pv_status 	    OUT VARCHAR2);
				 	


-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_cost_transfer_to_ap
--  Description   : Recherche si tous les couts sont transférés dans AP ( module PA )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--  pn_org_id number
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE pa_check_cost_transfer_to_ap ( pd_start_date 	IN DATE,
				 	pd_end_date 	IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_org_id       IN NUMBER,
				 	--pn_sob_id 	IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2);
				 	

-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_cross_charge
--  Description   : Recherche si tous les charges sont dans GL ( module PA )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--  pn_org_id number
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE pa_check_cross_charge ( pd_start_date 	IN DATE,
				  pd_end_date 	IN DATE,
				  pv_period_name 	IN VARCHAR2,
				  pn_org_id       IN NUMBER,
				  --pn_sob_id 	IN NUMBER,
				  pv_errbuf 	OUT VARCHAR2,
				  pv_status 	OUT VARCHAR2);
				  
-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_draft_revenue
--  Description   : Recherche si tous ??? ( module PA )
--
--  PARAMETRES    :
--    	pd_start_date 	date
--    	pd_end_date 	date
--	pv_period_name 	varchar2
--  pn_org_id number
--	pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     	pv_errbuf	varchar2
--	pv_status	varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE pa_check_draft_revenue ( 
          pd_start_date 	IN DATE,
				 	pd_end_date 	  IN DATE,
				 	pv_period_name 	IN VARCHAR2,
				 	pn_org_id       IN NUMBER,
				 	pv_errbuf 	OUT VARCHAR2,
				 	pv_status 	OUT VARCHAR2);
				 	
-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_pm
--  Description   : Recherche si toutes les transactions dans Project Manufacturing sont OK
--
--  PARAMETRES    :
--      pd_start_date   date
--      pd_end_date     date
--      pv_period_name  varchar2
--      pn_org_id       number
--
--  VALEUR RETOURNEE :
--      pv_errbuf   varchar2
--      pv_status   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_cst_pm (
        pd_start_date    IN       DATE,
        pd_end_date      IN       DATE,
        pv_period_name   IN       VARCHAR2,
        pn_org_id        IN       NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pv_status        OUT      VARCHAR2
    );

-------------------------------------------------------------------------------------------------------------------
--  Nom           : pa_check_trans_uncosted
--  Description   : Recherche si tous les coûts des mouvements ont été imputés
--
--  PARAMETRES    :
--      pd_start_date   date
--      pd_end_date     date
--      pv_period_name  varchar2
--      pn_org_id       number
--
--  VALEUR RETOURNEE :
--      pv_errbuf   varchar2
--      pv_status   varchar2
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE pa_check_trans_uncosted (
        pd_start_date    IN       DATE,
        pd_end_date      IN       DATE,
        pv_period_name   IN       VARCHAR2,
        pn_org_id        IN       NUMBER,
        pv_errbuf        OUT      VARCHAR2,
        pv_status        OUT      VARCHAR2
    );

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
		 
		 
END DKA_SPACLOTURE_PKG; -- Package Spécif
/
SHOW ERRORS;
EXIT
