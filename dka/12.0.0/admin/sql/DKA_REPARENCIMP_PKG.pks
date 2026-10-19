SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_REPARENCIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_REPARENCIMP_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique des encaissements clients
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
-- V1.0    26/04/2016     OBE Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER,
                 p_gl_date    IN  VARCHAR2,
                 p_reprise    IN  VARCHAR2);



END DKA_REPARENCIMP_PKG;
/
SHOW ERRORS
EXIT