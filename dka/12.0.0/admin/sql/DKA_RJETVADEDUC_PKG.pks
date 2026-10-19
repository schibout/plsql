create or replace PACKAGE DKA_RJETVADEDUC_PKG AS

  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_RJETVADEDUC_PKG.pks
  -- DESCRIPTION       : DKA_RJETVADEDUC_PKG package spec :
  ---
  ---                   Ce package est utilisé par le report spécifique DKA_RJETVADEDUC
  ---
  --- AUTEUR           : Thierry BOUGAULT
  --- DATE DE CREATION : 18/02/2009
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : calcul_tva_cre
  --  Description   : procédure de calcul de la TVA CRE/M alimente la table DKA_RJETVADEDUC_CRE
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  ------------------------------------------------------------------------------------------------------------------------
  PROCEDURE calcul_tva_cre(cre_request_id IN NUMBER,
                           --pv_societe           IN      VARCHAR2,
                           --pv_region            IN      VARCHAR2,
                           pv_uo IN VARCHAR2,
                           --pv_dka_company_num   IN      VARCHAR2,
                           pv_ledger     IN VARCHAR2,
                           pd_start_date IN DATE,
                           pd_end_date   IN DATE,
                           Pv_Debug_Mode IN VARCHAR2,
                           pv_errbuf     IN OUT VARCHAR2,
                           pn_retcode    OUT NUMBER);

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : calcul_tva_deb
  --  Description   : procédure de calcul de la TVA DEB alimente la table DKA_RJETVADEDUC_DEB
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  ------------------------------------------------------------------------------------------------------------------------
  PROCEDURE calcul_tva_deb(deb_request_id IN NUMBER,
                           --pv_societe           IN      VARCHAR2,
                           --pv_region            IN      VARCHAR2,
                           pv_uo IN VARCHAR2,
                           --pv_dka_company_num   IN      VARCHAR2,
                           pv_ledger     IN VARCHAR2,
                           pd_start_date IN DATE,
                           pd_end_date   IN DATE,
                           Pv_Debug_Mode IN VARCHAR2,
                           pv_errbuf     IN OUT VARCHAR2,
                           pn_retcode    OUT NUMBER);
---------------------------------------------------------------------------------------------------------------
  --  Nom           : dka_check_codetva
  --  Description   : fonction de récupération du compte de tva : ajouté le 19/10/2018
  --                 //SFA artf3039248 : INC0253409 - Modification champ Etats de TVA déductible
  --------------------------------------------------------------------------------------------------------------
  function dka_check_codetva(p_tax_rate_code varchar2,
                            p_compte1                varchar2,
                            p_tax_line_id  number ,
                            p_organization_id number )
     return varchar2;

END DKA_RJETVADEDUC_PKG; -- Spécification du package
/
SHOW ERRORS
EXIT;