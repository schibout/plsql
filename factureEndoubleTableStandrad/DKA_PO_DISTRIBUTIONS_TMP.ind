SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_REPGLPIECEREPIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_REPGLPIECEREPIMP_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique d'import des pièces répétitives
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
-- V1.0    27/10/2017     RBE Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf       IN   OUT VARCHAR2,
                 p_retcode           OUT NUMBER,
                 p_load_file    IN       VARCHAR2,
                 p_insert_oa    IN       VARCHAR2
                 );



END DKA_REPGLPIECEREPIMP_PKG;
/
SHOW ERRORS
EXIT