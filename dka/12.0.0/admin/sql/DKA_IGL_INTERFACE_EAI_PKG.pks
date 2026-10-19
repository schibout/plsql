CREATE OR REPLACE PACKAGE DKA_IGL_INTERFACE_EAI_PKG AS
     ------------------------------------------------------------------------
     -- $Id: DKA_IGL_INTERFACE_EAI_PKG.pks
     -- Capgemini
     -- Nom              : DKA_IGL_INTERFACE_EAI_PKG.pks
     -- Description      : Spécification du package DKA_IGL_INTERFACE_EAI_PKG
     -- Auteur           : Coudrier Benjamin
     -- Date de création : 07/10/2014
     -- Doc. associée    :
     -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
     ------------------------------------------------------------------------
     -- Historique
     -- Date       Qui Description
     -- ---------- --- ------------------------------------------------------

     -----------------------------------------------------------------
     --  NOM           : main
     --  DESCRIPTION   : Procédure principale du traitement
     --
     --  PARAMETRES   : pv_retcode            code retour out
     --                 pn_errbuf             description de l'erreur out
     -----------------------------------------------------------------
     PROCEDURE main(pv_errbuf     OUT VARCHAR2,
                    pn_retcode    OUT NUMBER);


END DKA_IGL_INTERFACE_EAI_PKG; -- Spécification du package
/

SHOW ERRORS
EXIT;

