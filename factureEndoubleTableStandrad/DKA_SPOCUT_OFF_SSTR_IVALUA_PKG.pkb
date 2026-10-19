CREATE OR REPLACE PACKAGE DKA_SAPAUTOVIR_PKG 
AS
------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SAPAUTOVIR_PKG.pks
-- DESCRIPTION       : Spécifique du package DKA_SAPAUTOVIR_PKG:
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 20/08/2013
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
	
----------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale
--
--
--  PARAMETRES :
--    p_errbuf   	Entrée/Sortie   Message d'erreur
--    p_retcode	Sortie			Code d'erreur
--  Valeurs possibles : 0=normal, 1=warning, 2=erreur
----------------------------------------------------------------------------

  PROCEDURE main (p_errbuf 	IN OUT 	VARCHAR2,
				  p_retcode 	OUT 	NUMBER);
				  
END DKA_SAPAUTOVIR_PKG;

/
SHOW ERRORS 

EXIT
