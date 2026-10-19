SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_REPFAIMOIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_REPFAIMOIMP_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique des fournisseurs et sites
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
-- V1.0    23/03/2016     OBE Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf       IN OUT VARCHAR2,
                 p_retcode      OUT NUMBER,
                 p_file_social  IN VARCHAR2,
                 p_file_calisto IN VARCHAR2,
                 p_load_file    IN VARCHAR2,
                 p_load_OI      IN VARCHAR2,
                 p_launch_OI    IN VARCHAR2);

END DKA_REPFAIMOIMP_PKG;
/
SHOW ERRORS
EXIT
