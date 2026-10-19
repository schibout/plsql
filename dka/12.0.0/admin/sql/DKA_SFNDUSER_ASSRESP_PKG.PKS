CREATE OR REPLACE PACKAGE DKA_SFNDUSER_ASSRESP_PKG IS
--------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SFNDUSER_ASSRESP_PKG 
  -- Nom              : DKA_SFNDUSER_ASSRESP_PKG 
  -- Description      : Body du package DKA_SFNDUSER_ASSRESP_PKG ( IMPORT DES RECEPTIONS PO )
  -- Auteur           : SELO
  -- Date de création : 17/09/2020
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
 
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
  TYPE liste_user_desactive IS RECORD
  ( user_name         VARCHAR2(240)
   );
  PROCEDURE main(p_errbuf     IN    OUT VARCHAR2,
                 p_retcode          OUT NUMBER,
                 p_fichier    IN        VARCHAR2
                 );
 TYPE l_user IS TABLE OF liste_user_desactive index by BINARY_INTEGER;
END DKA_SFNDUSER_ASSRESP_PKG;
/
EXIT