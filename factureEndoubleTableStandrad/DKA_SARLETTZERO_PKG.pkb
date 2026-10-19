create or replace 
PACKAGE                                    DKA_IPO_SSTR_IVALUA_PKG
AS
--------------------------------------------------------------------------------
-- Capgemini
-- Projet           :
-- Nom              : DKA_IPO_SSTR_IVALUA_PKG.pks
-- Description      : interface entrante des contrat SSTR depuis ivalua vers Oracle
-- Auteur           : Kaltoum HANNACH
-- Date de création : 08/10/2024
-- Commentaires     :
--------------------------------------------------------------------------------

  TYPE r_doublons IS RECORD
  ( NUM_CONTRAT           DKA_IPOCTR_SSTR_IVALUA.NUM_CONTRAT%Type
  ,VERSION_CONTRAT        DKA_IPOCTR_SSTR_IVALUA.VERSION_CONTRAT%Type
  ,VERSION_COMMANDE         DKA_IPOCTR_SSTR_IVALUA.VERSION_COMMANDE%Type
  ,NUM_COMMANDE              DKA_IPOCTR_SSTR_IVALUA.NUM_COMMANDE%Type
  , ivalua_line_id        VARCHAR2(30)
  , nom_table             VARCHAR2(100)
  );

  TYPE t_doublons IS TABLE OF r_doublons index by BINARY_INTEGER;

  TYPE r_erreurs IS RECORD
  (  NUM_CONTRAT      DKA_IPOCTR_SSTR_IVALUA.NUM_CONTRAT%Type
  ,VERSION_CONTRAT        DKA_IPOCTR_SSTR_IVALUA.VERSION_CONTRAT%Type
  ,VERSION_COMMANDE         DKA_IPOCTR_SSTR_IVALUA.VERSION_COMMANDE%Type
  ,NUM_COMMANDE              DKA_IPOCTR_SSTR_IVALUA.NUM_COMMANDE%Type
  , file_name         VARCHAR2(100)
  , line_num          VARCHAR2(25)
  , source            VARCHAR2(25)
  , ivalua_line_id    Number
  , message_text      VARCHAR2(500)
  );

  TYPE t_erreurs IS TABLE OF r_erreurs index by BINARY_INTEGER;


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

  
END DKA_IPO_SSTR_IVALUA_PKG;
/
SHOW ERRORS
EXIT