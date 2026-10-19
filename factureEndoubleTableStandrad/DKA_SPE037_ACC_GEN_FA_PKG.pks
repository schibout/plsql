create or replace PACKAGE DKA_IPOCDE_IVALUA_PKG
AS
--------------------------------------------------------------------------------
-- $Id: DKA_IPOCDE_IVALUA_PKG.pks  $
-- Capgemini
-- Projet           :
-- Nom              : DKA_IPOCDE_IVALUA_PKG.pks
-- Description      : Spécification du package DKA_IPOCDE_IVALUA_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 21/05/2020
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


  PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
               pn_retcode OUT NUMBER,
               p_recyclage IN VARCHAR2) ;

  TYPE r_doublons IS RECORD
  ( po_number           VARCHAR2(15)
  , ivalua_line_id      VARCHAR2(30) 
  , nom_table               VARCHAR2(100) 
  );
  
  TYPE t_doublons IS TABLE OF r_doublons index by BINARY_INTEGER;
   
  TYPE r_erreurs IS RECORD
  ( po_number         VARCHAR2(35)
  , file_name         VARCHAR2(100) 
  , line_num          VARCHAR2(25) 
  , source            VARCHAR2(25) 
  , ivalua_line_id    VARCHAR2(30) 
  , message_text      VARCHAR2(500)  
  );
   
  TYPE t_erreurs IS TABLE OF r_erreurs index by BINARY_INTEGER;

  TYPE r_approbation IS RECORD
  ( UO            VARCHAR2(35)
  , commande      VARCHAR2(35) 
  , statut        VARCHAR2(50) 
  );
  
  TYPE t_approbation IS TABLE OF r_approbation index by BINARY_INTEGER;  
  
END DKA_IPOCDE_IVALUA_PKG;

/
SHOW ERRORS
EXIT