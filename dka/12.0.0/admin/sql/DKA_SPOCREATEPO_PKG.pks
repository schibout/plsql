CREATE OR REPLACE PACKAGE dka_spocreatepo_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id$
  --
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : DKA_SPOWFMASTER_PKG.pks
  -- DESCRIPTION       : DKA_SPOCREATEPO_PKG package spec :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 13/09/2007
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 20/09/11   CDE DGE20110006 - Ajout de la procédure is_autocreation_authorized
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -------------------------------------------------------------------------------------
  --  Nom           : does_contract_exist
  --  Description   : Procédure de recherche du contrat lié à la DA.
  --
  --  PARAMETRES : paramètre standard workflow
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE does_contract_exist(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);
               
  -------------------------------------------------------------------------------------
  --  Nom           : is_autocreation_authorized
  --  Description   : Procédure de recherche si la DA Hors Catalogue peut être autocréée.
  --
  --  PARAMETRES : paramètre standard workflow
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE is_autocreation_authorized(itemtype  IN VARCHAR2,
                                itemkey   IN VARCHAR2,
                                actid     IN NUMBER,
                                funcmode  IN VARCHAR2,
                                resultout OUT NOCOPY VARCHAR2);

END dka_spocreatepo_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE dka_spocreatepo_pkg;
EXIT
