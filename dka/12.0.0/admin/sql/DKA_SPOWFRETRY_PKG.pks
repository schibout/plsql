SET VERIFY OFF;
DEFINE package_name = "DKA_SPOWFRETRY_PKG";

CREATE OR REPLACE PACKAGE &&package_name
AS
--------------------------------------------------------------------------------
-- $Id$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SPOWFRETRY_PKG.pks
-- Description      : Spécification du package DKA_SPOWFRETRY_PKG
-- Auteur           : Jardez Julien
-- Date de création : 28/11/2011
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 -------------------------------------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : procédure principale
 --
 --  PARAMETRES    :
 --    pv_errbuf        varchar2
 --    pn_retcode       varchar2
 -------------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf  OUT VARCHAR2,
                 pn_retcode OUT NUMBER
                 );


END &&package_name;
/
SHOW ERRORS;

EXIT;
