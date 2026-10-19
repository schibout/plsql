SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_SARAUTENC_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_SARAUTENC_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package du traitement de création des encaissements clients pour le compte de
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
-- V1.0    09/08/2018     OBE Creation
---------------------------------------------------------------------------------------------


  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER);



END DKA_SARAUTENC_PKG;
/
SHOW ERRORS
EXIT