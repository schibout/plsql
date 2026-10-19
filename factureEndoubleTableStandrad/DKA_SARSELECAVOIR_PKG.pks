CREATE OR REPLACE PACKAGE DKA_SARSOLDEAVOIR_PKG IS
--------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SARSOLDEAVOIR_PKG
  -- Description      : ENTETE du package DKA_SARSOLDEAVOIR_PKG
  -- Auteur           : IKRAME BALKHITY
  -- Date de création : 29/05/2023
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
  --                    p_retcode        Sortie Code Retour de la procédure,
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
    TYPE tab_numavoir IS
        TABLE OF VARCHAR2(32767) INDEX BY PLS_INTEGER;
	PROCEDURE solde_avoirs_creat_remb (pv_errbuf     IN OUT VARCHAR2,
                                    pn_retcode    IN OUT NUMBER);

    PROCEDURE main (
        p_errbuf    IN OUT  VARCHAR2,
        p_retcode   OUT     NUMBER
    );

END DKA_SARSOLDEAVOIR_PKG;
/

SHOW ERRORS

EXIT