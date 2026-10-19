CREATE OR REPLACE PACKAGE DKA_SGLCLOTURE_PKG AS
--------------------------------------------------------------------------------------------------------------- 
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SGLCLOTURE_PKG
-- DESCRIPTION       : Traitement de la cloture des périodes GL
---
--- AUTEUR           : Guillaume Chabrier
--- DATE DE CREATION : 11/06/2002
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--------------------------------------------------------------------------------------------------------------- 


--------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_CONFIGURATION_ID
--  Description   : Retourne l'id de configuration d'un livre primaire
--
--  PARAMETRES    :
--     pn_sob_id  number
--
--  VALEUR RETOURNEE :
--     pn_restit_id NUMBER
-------------------------------------------------------------------------------------------------------------------
	function get_configuration_id(
		pn_sob_id    IN NUMBER) 	return number;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_LEGAL
--  Description   : Recherche le livre légal associé à un livre primaire
--
--  PARAMETRES    :
--     pn_sob_id  number
--
--  VALEUR RETOURNEE :
--     pn_restit_id NUMBER
-------------------------------------------------------------------------------------------------------------------
   FUNCTION get_legal(pn_sob_id    IN NUMBER) RETURN NUMBER;
	
-------------------------------------------------------------------------------------------------------------------
--  Nom           : GET_RESTIT
--  Description   : Recherche le livre de type restit associé à un livre primaire
--
--  PARAMETRES    :
--     pn_sob_id  number
--
--  VALEUR RETOURNEE :
--     pn_restit_id NUMBER
--     pv_errbuf  varchar2
--     pn_retcode   number
-------------------------------------------------------------------------------------------------------------------
   FUNCTION get_restit(
    pn_sob_id    IN NUMBER) RETURN NUMBER;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_TO_CLOSE
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
PROCEDURE period_to_close (
	pv_period_name 	OUT VARCHAR2,
	pv_errbuf 		OUT VARCHAR2,
	pn_retcode           OUT NUMBER );
			   
			   
-------------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_TO_OPEN
--  Description   : Recherche la période suivante
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
PROCEDURE period_to_open       ( 
	  pv_period_name_close		IN VARCHAR2,
      pv_period_name_open  OUT   VARCHAR2,
      pv_errbuf        OUT      VARCHAR2,
      pn_retcode       OUT      NUMBER );	

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CONSOLIDATION_RESTIT
--  Description   : Recherche la période suivante
--
--  PARAMETRES    :
--	pv_period_to_close VARCHAR2,
--	pn_restit_id NUMBER,
--	pv_errbuf  IN OUT VARCHAR2,
--	pn_retcode    OUT NUMBER
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pd_start_date    date
--	pv_errbuf  IN OUT VARCHAR2,
--	pn_retcode    OUT NUMBER
-------------------------------------------------------------------------------------------------------------------
PROCEDURE CONSOLIDATION_RESTIT (pv_period_to_close VARCHAR2,
pn_restit_id NUMBER,
pv_errbuf  IN OUT VARCHAR2,
pn_retcode    OUT NUMBER);
	  
--------------------------------------------------------------------------------------------------------------- 
--  Nom           : open_next_period
--  Description   : 
--
--  PARAMETRES    :
-- 	        
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------	
PROCEDURE open_next_period (
	pn_sob_id       IN  NUMBER,
	pn_access_id IN       NUMBER,
	pv_period_name IN     VARCHAR2,
	pv_errbuf        OUT  VARCHAR2,
	pn_retcode         OUT  NUMBER);   	
	
							
-------------------------------------------------------------------------------------------------------------------
--  Nom           : CLOSE_PREVIOUS_PERIOD
--  Description   : Ouverture de la période suivante
--
--  PARAMETRES    :
--     pn_sob_id  number
--     pv_period_name   varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2

--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE CLOSE_PREVIOUS_PERIOD (
	pn_sob_id    IN    NUMBER,
	pv_period_name IN     VARCHAR2,
	pn_access_id     IN    NUMBER,
	pv_errbuf    IN OUT   VARCHAR2,
	pn_retcode   OUT      NUMBER
);

-------------------------------------------------------------------------------------------------------------------
--  Nom           : CLOSE_LEDGER
--  Description   : Cette Procédure enchaîne l'ensemble des autres procédures pour un livre primaire
--
--  PARAMETRES    :
--
-- pv_errbuf                       Entrée/Sortie           retour de message eventuel
--       pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
PROCEDURE CLOSE_LEDGER (pn_sob_id IN NUMBER, pn_access_id NUMBER,pn_access_id_legal NUMBER,pn_access_id_restit NUMBER,pv_period_to_close IN varchar2,pv_period_to_open IN varchar2, pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

--------------------------------------------------------------------------------------------------------------- 
--  Nom           : main
--  Description   : Procédure  principale qui enchaine le reste des procedures
--
--  PARAMETRES    :
-- 	        
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------	
PROCEDURE main (pv_errbuf  IN OUT VARCHAR2,
                pn_retcode    OUT NUMBER,pv_period_name IN VARCHAR2);
			
---------------------------------------------------------------------------------------------------------------
END DKA_SGLCLOTURE_PKG; -- Spécification du package
/
SHOW ERRORS;
EXIT;