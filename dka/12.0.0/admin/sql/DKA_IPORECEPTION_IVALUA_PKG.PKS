CREATE OR REPLACE PACKAGE DKA_IPORECEPTION_IVALUA_PKG IS
--------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_IPORECEPTION_IVALUA_PKG 
  -- Nom              : DKA_IPORECEPTION_IVALUA_PKG 
  -- Description      : Body du package DKA_IPORECEPTION_IVALUA_PKG ( IMPORT DES RECEPTIONS PO )
  -- Auteur           : SELO
  -- Date de création : 17/06/2020
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 23/03/2016 RAZ Création
  --------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------

  PROCEDURE main(p_errbuf     IN    OUT VARCHAR2,
                 p_retcode          OUT NUMBER,
                 p_reprise    IN        VARCHAR2
                 );

END DKA_IPORECEPTION_IVALUA_PKG;
/
EXIT