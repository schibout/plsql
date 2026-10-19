SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_REPARFACTIMP_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME
--    DKA_REPARFACTIMP_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION
--    Création du package de l'interface specifique d'import des factures clients
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
-- V1.0    28/03/2016     RAZ Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf       IN    OUT VARCHAR2,
                 p_retcode            OUT NUMBER,
                 p_gl_date      IN        VARCHAR2,
                 p_reprise      IN        VARCHAR2
                 );



END DKA_REPARFACTIMP_PKG;
/
SHOW ERRORS
EXIT