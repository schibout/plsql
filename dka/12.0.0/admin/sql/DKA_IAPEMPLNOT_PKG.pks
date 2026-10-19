CREATE OR REPLACE PACKAGE DKA_IAPEMPLNOT_PKG AS 
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_IAPEMPLNOT_PKG
  -- Description      : Spécifications du package DKA_IAPEMPLNOT_PKG
  -- Auteur           : F.DOUTRIAUX
  -- Date de création : 08/11/2011
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  --
  --------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : Pv_Errbuf         Sortie Message d'erreur
  --                    Pn_Retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE Main(Pv_Errbuf OUT VARCHAR2, Pn_Retcode OUT NUMBER);

END DKA_IAPEMPLNOT_PKG;
/
SHOW ERRORS PACKAGE DKA_IAPEMPLNOT_PKG;
EXIT
