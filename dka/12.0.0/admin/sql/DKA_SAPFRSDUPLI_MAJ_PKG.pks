create or replace PACKAGE DKA_SAPFRSDUPLI_MAJ_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SAPFRSDUPLI_MAJ_PKG.pks  $
-- Capgemini
-- Projet           : 
-- Nom              : DKA_SAPFRSDUPLI_MAJ_PKG.pks
-- Description      : Spécification du package DKA_SAPFRSDUPLI_MAJ_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 08/07/2020
-- Commentaires     : 
--------------------------------------------------------------------------------
  TYPE r_sites_maj IS RECORD
  (NOM_FOURNISSEUR     VARCHAR2(240)
  , CODE_SITE           VARCHAR2(15)
  , UO_SITE             VARCHAR2(7)  
  , LISTE_MSG           VARCHAR2(1000)
  ); 
  
  TYPE t_sites_maj IS TABLE OF r_sites_maj index by BINARY_INTEGER;

  PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
                 pn_retcode OUT NUMBER) ;

END DKA_SAPFRSDUPLI_MAJ_PKG;
/
SHOW ERRORS
EXIT