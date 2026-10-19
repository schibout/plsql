SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_FUSPOMAJPFTF_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_FUSPOMAJPFTF_PKG.pks  V1.0
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
-- V1.0    06/09/2019     SEL Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf       IN OUT  VARCHAR2,
                 p_retcode      OUT     NUMBER,
				 p_org_id       IN      Number
                 );



END DKA_FUSPOMAJPFTF_PKG;
/
SHOW ERRORS
EXIT
