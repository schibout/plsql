CREATE OR REPLACE PACKAGE DKA_SARPREL_ATTACH_PKG AS
  ------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SARPREL_ATTACH_PKG.pkb
  -- DESCRIPTION       : DKA_SARPREL_ATTACH_PKG package body :
  --
  -- AUTEUR           : Benjamin Coudrier (CAPGEMINI)
  -- DATE DE CREATION : 17/12/2013
  -- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ------------------------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale du stockage des avis de prélèvement
  --
  --
  --  PARAMETRES :
  --    pv_errbuf       Entrée/Sortie           message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------

  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER);

END DKA_SARPREL_ATTACH_PKG;
/
SHOW ERROR

EXIT
