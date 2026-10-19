CREATE OR REPLACE PACKAGE DKA_SAPPOST_APPRO_MVT_PKG
AS
--------------------------------------------------------------------------------
-- $Id$
-- Capgemini
-- Projet           : Puissance4
-- Nom              : DKA_SAPPOST_APPRO_MVT_PKG.pks
-- Description      : Spécification du package DKA_SAPPOST_APPRO_MVT_PKG
-- Auteur           : Thomas Bonduaeux
-- Date de création : 28/01/2008
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--
--------------------------------------------------------------------------------



--------------------------------------------------------------------------------
--  Nom           : respond_sysadmin_notif
--  Description   : Répond automatiquement aux notifications
--                  DKA_MSG_SYSADMIN
--
--  Parametres    : pn_retcode    code de retour
--                  pv_errbuf     message d'erreur
--------------------------------------------------------------------------------
PROCEDURE respond_sysadmin_notif(pv_errbuf  OUT NOCOPY VARCHAR2,
                                 pn_retcode OUT NOCOPY NUMBER);

END DKA_sappost_appro_mvt_pkg;
/
SHOW ERROR PACKAGE DKA_SAPPOST_APPRO_MVT_PKG
EXIT
