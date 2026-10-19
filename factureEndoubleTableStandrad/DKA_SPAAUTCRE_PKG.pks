SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_SARAUTCRE_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_SARAUTCRE_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package du traitement de création des sociérés
--
-- USAGE
--    A exécuter sous SqlPlus avec user APPS sans paramètre
--
-- NOTES
--
-- PARAMETERS
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    11/10/2019     OCL Creation
---------------------------------------------------------------------------------------------


 PROCEDURE main_evenement(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER,
				 pv_unite_ope IN NUMBER);

 PROCEDURE main_reglement(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER,
				 pv_unite_ope IN NUMBER);
				 
 PROCEDURE main_sequence(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER,
				 pv_unite_ope IN NUMBER);

PROCEDURE main_comptes(p_errbuf IN OUT VARCHAR2,
                       p_retcode OUT NUMBER,
					   pv_unite_ope IN NUMBER);


END DKA_SARAUTCRE_PKG;
/
SHOW ERRORS
EXIT