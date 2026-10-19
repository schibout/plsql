CREATE OR REPLACE PACKAGE APPS.DKA_SARLETTZERO_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SARLETTZERO_PKG.pks  $
-- Capgemini
-- Projet           : 
-- Nom              : DKA_SARLETTZERO_PKG.pks
-- Description      : Spécification du package DKA_SARLETTZERO_PKG
-- Auteur           : Zakaria BENDAOUD
-- Date de création : 18/08/2023
-- Commentaires     : 
--------------------------------------------------------------------------------

   PROCEDURE writeout(P_message IN VARCHAR2) ;

PROCEDURE reglement_lettrage(pv_errbuf  IN OUT VARCHAR2,
                           pn_retcode OUT NUMBER
                           );
 PROCEDURE extraction_reglement (
        pv_errbuf     IN OUT  VARCHAR2,
        pn_retcode    IN OUT  NUMBER,
        p_region      IN      VARCHAR2,
        vv_filename   OUT     VARCHAR2);
        
  PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER) ;
         

END DKA_SARLETTZERO_PKG;

/
SHOW ERRORS
EXIT