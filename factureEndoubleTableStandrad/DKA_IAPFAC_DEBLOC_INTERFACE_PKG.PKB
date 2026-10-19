CREATE OR REPLACE PACKAGE dka_sxxmailtva_pkg IS
  --------------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SRBFACTURE_PKG.pkb
  -- Description      : DKA_SRBFACTURE_PKG package body
  -- Auteur           : S.HAHIOUI(Capgemini)
  -- Date de création : 21/10/2019
  -- Doc. associée    :
  -- Commentaire      : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Version Qui Description
  -- ---------- ------- --- --------------------------------------------------------------
  -- 07/05/2021 1.1   NBO Correction suite au retour recette
  -- 17/05/2021 1.1   SHA Correction suite au retour recette
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Saloua HA
  -- Date              : 15/01/2021
  -- Remarques         :
  /*============================================================================*/
  PROCEDURE writeout(p_message IN VARCHAR2);

  /*=====================================================================================*/
  /* PROCEDURE NAME : main
  /*
  /* DESCRIPTION
  /*  Procédure principale de l'interface d'import des fournisseurs
  /*
  /* PARAMETERS
  /* ==========
  /* NAME              DESCRIPTION
  /* ----------------- ------------------------------------------------------
  /* p_errbuf         Retour de message éventuel
  /* p_retcode        Statut du traitement en sortie
  /*=====================================================================================*/

  PROCEDURE main(p_errbuf          OUT VARCHAR2,
                 p_retcode         OUT NUMBER,
                 p_regionseulement IN VARCHAR2);

END dka_sxxmailtva_pkg;
/
SHOW ERRORS
EXIT
