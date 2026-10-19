CREATE OR REPLACE PACKAGE DKA_SAPINIT_HOLD_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SAPINIT_HOLD_PKG.pks 1490 2009-02-25 16:45:43Z CORP\viknab $
-- Capgemini
-- Projet           : Puissance4
-- Nom              : DKA_SAPINIT_HOLD_PKG.pkb
-- Description      : Spec du package DKA_SAPINIT_HOLD_PKG
-- Auteur           : Vincent Knab
-- Date de création : 29/12/2008
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
---2016/07/05 JJA Portage Helios R12
--------------------------------------------------------------------------------


PROCEDURE main(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER);

end;
/

show errors package DKA_SAPINIT_HOLD_PKG;

EXIT


