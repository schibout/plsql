SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_EMPJOBSIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_EMPJOBSIMP_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique de transcodification des fonctions des employés.
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
-- V1.0    03/10/2016     PBR Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf       IN    OUT VARCHAR2,
                 p_retcode            OUT NUMBER
                 );

END DKA_EMPJOBSIMP_PKG;
/
SHOW ERRORS
EXIT