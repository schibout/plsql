CREATE OR REPLACE PACKAGE DKA_SPOCLOTURE_PKG AS
--------------------------------------------------------------------------------------------------------------- 
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOCLOTURE_PKG
-- DESCRIPTION       : Traitement de la cloture des périodes PO
---
--- AUTEUR           : Guillaume Chabrier
--- DATE DE CREATION : 11/06/2002
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--------------------------------------------------------------------------------------------------------------- 
---------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_TO_CLOSE
--  Description   : Recherche la période à fermer pour une application
--
--  PARAMETRES    :
--     pn_sob_id	number
--
--  VALEUR RETOURNEE :
--     pv_errbuf	varchar2
--     pd_period_name 	varchar2
---------------------------------------------------------------------------------------------------------------
PROCEDURE period_to_close (pn_sob_id		IN OUT NUMBER,
			   pv_period_name_cl 	OUT    VARCHAR2,
			   pv_errbuf 		OUT    VARCHAR2,
			   pn_retcode           OUT    NUMBER );
---------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_TO_OPEN
--  Description   : Recherche la période suivante
--
--  PARAMETRES    :
--     pn_sob_id	number
--     pv_period_name	varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf	varchar2
--     pd_period_name 	varchar2
---------------------------------------------------------------------------------------------------------------
PROCEDURE period_to_open       ( pn_sob_id		IN OUT NUMBER,
                                 pv_period_name_cl      IN    VARCHAR2,
			   	 pv_period_name_op      OUT    VARCHAR2,
			   	 pd_start_date          OUT    DATE,
			   	 pd_end_date            OUT    DATE,
			   	 pv_errbuf 	        OUT    VARCHAR2,
			   	 pn_retcode             OUT    NUMBER );
--------------------------------------------------------------------------------------------------------------- 
--  Nom           : open_next_period
--  Description   : ouverture de la période suivante
--
--  PARAMETRES    :
-- 	        
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------	
PROCEDURE open_next_period (pn_sob_id         IN      NUMBER,
                            pv_period_name_op IN      VARCHAR2,
                            pd_start_date     IN      DATE,
                            pd_end_date       IN      DATE,
                            pv_errbuf         IN OUT  VARCHAR2,
                            pn_retcode           OUT  NUMBER);                            			   	 			  
--------------------------------------------------------------------------------------------------------------- 
--  Nom           : main
--  Description   : Procédure qui enchaine le reste des procedures
--
--  PARAMETRES    :
-- 	        
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------	
PROCEDURE main (pv_errbuf IN OUT  VARCHAR2,
                pn_retcode   OUT  NUMBER);                 
---------------------------------------------------------------------------------------------------------------
END DKA_SPOCLOTURE_PKG; -- Spécification du package
/
SHOW ERRORS;
EXIT;