create or replace PACKAGE DKA_SAP_DEL_TAB_HISTORY_FOUR IS
--------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SAP_DEL_TAB_HISTORY_FOUR
  -- Nom              : DKA_SAP_DEL_TAB_HISTORY_FOUR
  -- Description      : ENTETE du package DKA_SAP_DEL_TAB_HISTORY_FOUR ( PURGE DES TABLES )
  -- Auteur           : SELO	
  -- Date de création : 21/12/2021
  -- Doc. associée    : 
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  
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
  --                    p_nbre_jours     Nombre de jours 
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
PROCEDURE main(p_errbuf     IN    OUT VARCHAR2,
                 p_retcode          OUT NUMBER--,
                -- p_nbre_jours   IN      NUMBER
                 );

END DKA_SAP_DEL_TAB_HISTORY_FOUR;
/
SHOW ERRORS
EXIT