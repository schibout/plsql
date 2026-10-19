create or replace PACKAGE DKA_SAPFRSDUPLI_INIT_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_SAPFRSDUPLI_INIT_PKG.pks  $
-- Capgemini
-- Projet           : 
-- Nom              : DKA_SAPFRSDUPLI_INIT_PKG.pks
-- Description      : Spécification du package DKA_SAPFRSDUPLI_INIT_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 14/01/2020
-- Commentaires     : 
--------------------------------------------------------------------------------

  -------------------------------------------------------------------------------------
  --  Nom           : 
  --  Description   : 
  --
  --  PARAMETRES :  
  --
  --  VALEUR RETOURNEE : 
  -------------------------------------------------------------------------------------
    TYPE r_sites_creer IS RECORD
  ( NUM_LIGNE           NUMBER
  , NOM_FOURNISSEUR     VARCHAR2(240)
  , CODE_SITE           VARCHAR2(15)
  , UO_SITE             VARCHAR2(7)
  , CODE_ADRESSE        VARCHAR2(240)
  , LISTE_MSG           VARCHAR2(1000)
  );

    TYPE r_sites_attach IS RECORD
  ( NUM_LIGNE           NUMBER
  , NOM_FOURNISSEUR     VARCHAR2(240)
  , CODE_SITE           VARCHAR2(15)
  , UO_SITE             VARCHAR2(7)
  , CODE_ADRESSE        VARCHAR2(240)
  , LISTE_MSG           VARCHAR2(1000)
  );  

    TYPE r_sites_maj IS RECORD
  ( NUM_LIGNE           NUMBER
  , NOM_FOURNISSEUR     VARCHAR2(240)
  , CODE_ADRESSE        VARCHAR2(240)
  , CODE_SITE           VARCHAR2(15)
  , UO_SITE             VARCHAR2(7)  
  , LISTE_MSG           VARCHAR2(1000)
  ); 
  
      TYPE r_sites_valide IS RECORD
  ( NUM_LIGNE           NUMBER
  , NOM_FOURNISSEUR     VARCHAR2(240)
  , CODE_SITE           VARCHAR2(15)
  , UO_SITE             VARCHAR2(7)
  , CODE_ADRESSE        VARCHAR2(240)
  , LISTE_MSG           VARCHAR2(1000)
  );
    -- Type table des sites
  TYPE t_sites_creer IS TABLE OF r_sites_creer index by BINARY_INTEGER;
  TYPE t_sites_attach IS TABLE OF r_sites_attach index by BINARY_INTEGER;
  TYPE t_sites_maj IS TABLE OF r_sites_maj index by BINARY_INTEGER;
  TYPE t_sites_valide IS TABLE OF r_sites_valide index by BINARY_INTEGER;
  
  PROCEDURE VALIDATION_DONNEES(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) ;
  PROCEDURE LANCE_CHARGEMENT_FICHIER(pv_errbuf  IN OUT VARCHAR2,
                                     pn_retcode OUT NUMBER,
                                     p_fichier IN VARCHAR2);
  
  PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
               pn_retcode OUT NUMBER,
			   p_nom_fichier IN VARCHAR2) ;

END DKA_SAPFRSDUPLI_INIT_PKG;
/
SHOW ERRORS
EXIT