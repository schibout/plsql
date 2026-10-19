SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_REPARCLIIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_REPARCLIIMP_PKG.pks  V1.0
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
-- V1.0    10/05/2016     OBE Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER,
                 p_reprise    IN   VARCHAR2);

  PROCEDURE main_relation(p_errbuf  IN OUT VARCHAR2,
                 p_retcode OUT NUMBER,
                 p_reprise IN VARCHAR2);


END DKA_REPARCLIIMP_PKG;
/
SHOW ERRORS
EXIT
