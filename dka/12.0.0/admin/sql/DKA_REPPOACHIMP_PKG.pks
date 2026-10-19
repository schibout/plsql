SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_REPPOACHIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_REPPOACHIMP_PKG.pks  V1.0
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
-- V1.0    26/04/2016     OBE Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER,
                 p_reprise IN VARCHAR2);



END DKA_REPPOACHIMP_PKG;
/
SHOW ERRORS
EXIT