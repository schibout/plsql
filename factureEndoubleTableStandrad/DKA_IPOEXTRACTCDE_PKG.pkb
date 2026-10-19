CREATE OR REPLACE PACKAGE DKA_OPEN_INTERFACE_AP_EAI_PKG AS
     ------------------------------------------------------------------------
     -- $Id: DKA_OPEN_INTERFACE_AP_EAI_PKG.pks
     -- Capgemini
     -- Nom              : DKA_OPEN_INTERFACE_AP_EAI_PKG.pks
     -- Description      : Spécification du package DKA_OPEN_INTERFACE_AP_EAI_PKG
     -- Auteur           : Coudrier Benjamin
     -- Date de création : 10/11/2014
     -- Doc. associée    :
     -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
     ------------------------------------------------------------------------
     -- Historique
     -- Date       Qui Description
     -- ---------- --- ------------------------------------------------------
     -- 30/11/2016 MEG artf2052652
     ------------------------------------------------------------------------
     
     -----------------------------------------------------------------
     --  NOM           : main
     --  DESCRIPTION   : Procédure principale du traitement
     --
     --  PARAMETRES   : pv_retcode            code retour out
     --                 pn_errbuf             description de l'erreur out
     -----------------------------------------------------------------
     PROCEDURE main(pv_errbuf     OUT VARCHAR2,
                    pn_retcode    OUT NUMBER,
                    pn_org_id     IN NUMBER);


END DKA_OPEN_INTERFACE_AP_EAI_PKG; -- Spécification du package
/
SHOW ERRORS
EXIT;
