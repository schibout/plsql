SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_SAPEXTSTATFAC_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_SAPEXTSTATFAC_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique des acheteurs
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
-- V1.0    04/05/2017     OBE Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER);



END DKA_SAPEXTSTATFAC_PKG;
/
SHOW ERRORS
EXIT