CREATE OR REPLACE PACKAGE DKA_SXLAACCPBAR_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications HELIOS
  -- NOM               : DKA_SAPCREATE_BLOCAGES_ALL_PKG.pks
  -- DESCRIPTION       : DKA_SAPCREATE_BLOCAGES_ALL_PKG package spec :
  ---
  --- AUTEUR       : Roshanak GHARAGOZLOU
  --- DATE DE CREATION : 25/08/2016
  --- DOC. ASSOCIEE    :
  --  COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  ---
  ---------------------------------------------------------------------------------------------------------------
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------
PROCEDURE main(pv_errbuf        IN  OUT VARCHAR2,
               pn_retcode           OUT NUMBER);
---------------------------------------------------------------------------------------------------------------

END DKA_SXLAACCPBAR_PKG;
/

SHOW ERRORS;

EXIT