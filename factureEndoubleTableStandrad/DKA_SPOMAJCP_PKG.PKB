CREATE OR REPLACE PACKAGE DKA_SAPWFCSPNTF_pkg AS
---------------------------------------------------------------------------------------------------------------
  -- $Id:  $
  --
  -- CAPGEMINI
  -- PROJET      : Helios
  -- NOM         : DKA_SAPWFCSPNTF_PKG.pks
  -- DESCRIPTION : DKA_SAPWFCSPNTF_PKG package spec :
  ---
  --- AUTEUR       : Nicolas BOUSSEKEYT (CAPGEMINI)
  --- DATE DE CREATION : 29/04/2019
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 17/04/2020 - MTIA - TASK0111380 - Besoin complémentaire à l'évolution EDB236 - Ajouter une ligne dans l'historique d'approbation
  --- ---------- --- --------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : lance le traitement d'annulation des workflows pour chaque facture ayant des notifications avec des factures OI ou AP
  --                geree par CSP
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------
  PROCEDURE main ( pv_errbuf     OUT VARCHAR2,
                   pn_retcode    IN OUT NUMBER);
                                    
END DKA_SAPWFCSPNTF_pkg; -- Spécification du package
/
SHOW ERROR PACKAGE DKA_SAPWFCSPNTF_PKG;
EXIT
