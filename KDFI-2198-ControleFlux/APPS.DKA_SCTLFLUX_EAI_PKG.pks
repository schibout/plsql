PACKAGE DKA_SCTLFLUX_EAI_PKG AS
     ------------------------------------------------------------------------
     -- $Id: DKA_SCTLFLUX_EAI_PKG.pks
     -- Capgemini
     -- Nom              : DKA_SCTLFLUX_EAI_PKG.pks
     -- Description      : Spécification du package DKA_SCTLFLUX_EAI_PKG
     -- Auteur           : Coudrier Benjamin
     -- Date de création : 22/10/2014
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
     --  PARAMETRES   :   pv_retcode               	Code retour.
     --                   pn_errbuf                	Description de l'erreur.
     --              	  pv_folio               	Folio.
     --              	  pn_traitement_reprise   	Numéro du traitement à rejouer.
     --              	  pd_date_reprise_de      	Date à reprendre à partir de.
     --              	  pd_date_reprise_a       	Date à reprendre jusqu'au.
     -----------------------------------------------------------------
     PROCEDURE main(pv_errbuf             OUT VARCHAR2,
                    pn_retcode            OUT NUMBER,
                    pv_folio              IN VARCHAR2,
                    pn_traitement_reprise IN NUMBER,
                    pd_date_reprise_de    IN VARCHAR2,
                    pd_date_reprise_a     IN VARCHAR2);

END DKA_SCTLFLUX_EAI_PKG; -- Spécification du package
