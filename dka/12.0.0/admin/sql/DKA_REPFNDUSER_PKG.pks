SET VERIFY OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

CREATE OR REPLACE PACKAGE DKA_REPFNDUSER_PKG IS
--------------------------------------------------------------------------------------------
-- FILENAME               
--    DKA_REPFNDUSER_PKG.pks  V1.0
--
-- AUTEUR
--    Capgemini
--
-- DESCRIPTION       
--    Création du package de l'interface specifique des utilisateurs
--
-- USAGE
--    A exécuter sous SqlPlus avec user APPS sans parametre
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

  /*
   *************************************************************************
   * PROCEDURE NAME : main
   *
   * DESCRIPTION
   *  Procédure principale du traitement de reprise des utilisateurs
   *
   * PARAMETERS
   * ==========
   * NAME              DESCRIPTION
  .* ----------------- ------------------------------------------------------
   * p_errbuf         Retour de message éventuel
   * p_retcode        Statut du traitement en sortie
   * p_reprise        Reprise du traitement (N = Chargement du fichier)
   ************************************************************************
   */
  PROCEDURE main(p_errbuf  IN OUT VARCHAR2,
                 p_retcode    OUT NUMBER,
                 p_reprise IN VARCHAR2);



END DKA_REPFNDUSER_PKG;
/
SHOW ERRORS
EXIT