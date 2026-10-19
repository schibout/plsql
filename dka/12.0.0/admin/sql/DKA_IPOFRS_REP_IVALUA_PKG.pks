CREATE OR REPLACE PACKAGE DKA_IPOFRS_REP_IVALUA_PKG AS
  --------------------------------------------------------------------------------
  -- $Id: DKA_REPFOU_IVALUA.pks  $
  -- Capgemini
  -- Projet           :
  -- Nom              : DKA_IPOFRS_REP_IVALUA_PKG.pks
  -- Description      : Spécification du package DKA_IPOFRS_REP_IVALUA_PKG
  -- Auteur           : 
  -- Date de création : 
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

  PROCEDURE MAIN(pv_errbuf     IN OUT VARCHAR2,
                 pn_retcode    OUT NUMBER,
                 p_nom_fichier IN VARCHAR2,
                 p_maj         IN VARCHAR2);


  TYPE r_erreurs IS RECORD(
    supplier_number VARCHAR2(35),
    vendor_site_id  VARCHAR2(45),
    table_id        VARCHAR2(25),
    source          VARCHAR2(25),
    message_text    VARCHAR2(500));

  TYPE t_erreurs IS TABLE OF r_erreurs index by BINARY_INTEGER;


END DKA_IPOFRS_REP_IVALUA_PKG;
/
SHOW ERRORS
EXIT