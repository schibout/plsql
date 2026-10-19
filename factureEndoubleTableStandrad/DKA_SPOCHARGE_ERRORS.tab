SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_FUSPOIMPCTRSSTR_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_FUSPOIMPCTRSSTR_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique d'import des contrats SSTR
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
-- V1.0    28/03/2016     RBE Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf     IN   OUT VARCHAR2,
                 p_retcode         OUT NUMBER
                 
                 );



END DKA_FUSPOIMPCTRSSTR_PKG;
/
SHOW ERRORS
EXIT