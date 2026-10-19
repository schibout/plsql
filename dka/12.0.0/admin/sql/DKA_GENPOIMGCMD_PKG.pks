SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_GENPOIMGCMD_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_GENPOIMGCMD_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    
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
-- V1.0    11/05/2017     YWA Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf       IN OUT  VARCHAR2,
                 p_retcode      OUT     NUMBER,
                 p_region      IN      VARCHAR2
                 );



END DKA_GENPOIMGCMD_PKG;
/
SHOW ERRORS
EXIT
