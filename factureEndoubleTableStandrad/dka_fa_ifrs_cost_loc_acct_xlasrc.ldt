CREATE OR REPLACE PACKAGE dka_spowfapprv_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SPOWFAPPRV_PKG.pks 352 2007-10-02 14:19:00Z NORDEST\viknab $
  --
  -- CAPGEMINI
  -- PROJET      : DALKIA Oracle Applications
  -- NOM         : dka_spowfapprv_pkg.pks
  -- DESCRIPTION       : dka_spowfapprv_pkg package spec :
  ---
  --- AUTEUR       : Nicolas Boussekeyt (CAPGEMINI)
  --- DATE DE CREATION : 04/09/2007
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  ---
  --- 24/12/2009 SRO Ajout de la procedure alim_description_contrat_sstr
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
  --  Nom           : register_doc_submitted
  --  Description   : 
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE register_doc_submitted(itemtype  IN VARCHAR2,
                                   itemkey   IN VARCHAR2,
                                   actid     IN NUMBER,
                                   funcmode  IN VARCHAR2,
                                   resultout OUT NOCOPY VARCHAR2);


  -------------------------------------------------------------------------------------
  --  Nom           : alim_description_contrat_sstr
  --  Description   : alimenter dans le cas de contrat de sous-traitance la description 
  --  du contrat et dans le cas des commandes annuelles de sous-traitance celle du contrat
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE alim_description_contrat_sstr (itemtype  IN VARCHAR2,
                                          itemkey   IN VARCHAR2,
                                          actid     IN NUMBER,
                                          funcmode  IN VARCHAR2,
                                          resultout OUT NOCOPY VARCHAR2);
                                          
  -------------------------------------------------------------------------------------
  --  Nom           : PO_NEW_COMMUNICATION
  --  Description   : Court-circuite le wf en mode PDF
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------                                          
  PROCEDURE PO_NEW_COMMUNICATION (itemtype IN VARCHAR2,
                                  itemkey IN VARCHAR2,
                                  actid IN NUMBER,
                                  funcmode IN VARCHAR2,
                                  resultout OUT NOCOPY VARCHAR2);

END dka_spowfapprv_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE dka_spowfapprv_pkg;
EXIT
