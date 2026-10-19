CREATE OR REPLACE PACKAGE DKA_SRBRELBANC_CSP_PKG AS
     ------------------------------------------------------------------------
     -- $Id: DKA_SRBRELBANC_CSP_PKG.pks
     -- Capgemini
     -- Nom              : DKA_SRBRELBANC_CSP_PKG.pks
     -- Description      : Spécification du package DKA_SRBRELBANC_CSP_PKG
     -- Auteur           : Coudrier Benjamin
     -- Date de création : 25/08/2014
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
     --          pv_banque          Nom de la banque.
     --          pd_start_date      Date de début.
     --          pd_end_date      Date de fin.
     --          pv_code_opib      Code Opération Interbancaire.
     -----------------------------------------------------------------
     PROCEDURE main(pv_errbuf     OUT VARCHAR2,
                    pn_retcode    OUT NUMBER,
                    pv_banque     IN VARCHAR2,
                    pd_start_date IN VARCHAR2,
                    pd_end_date   IN VARCHAR2,
                    pv_code_opib  IN VARCHAR2,
					pv_flag_automatisation	IN VARCHAR2);


END DKA_SRBRELBANC_CSP_PKG; -- Spécification du package
/

SHOW ERRORS
EXIT;

