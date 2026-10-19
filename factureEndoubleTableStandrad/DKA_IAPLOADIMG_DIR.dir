CREATE OR REPLACE PACKAGE dka_rep_int_tecpca_pkg IS
  --------------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_REP_EXT_TECPCA_PKG.pks
  -- Description      : DKA_REP_EXT_TECPCA_PKG package specifications
  -- Auteur           : B.Delattre(Capgemini)
  -- Date de création : 26/04/2016
  -- Doc. associée    :
  -- Commentaire      : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 08/04/2016 BDE Création du package pour migration R12
  -- 17/07/2016 JJA Ajout du paramètre date
  --------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : MAIN
  -- Description      : Proc�dure d'extraction dans un ficher plat des soldes GL
  --
  -- PARAMETRES       : pv_errbuf      Sortie Message d'erreur
  --                    pn_retcode     Sortie Code Retour de la procédure
  --                                   '0' : Normal
  --                                   '1' : Avertissement
  --                                   '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  -- Description       :
  -- Valeurs possibles :
  ------------------------------------------------------------------------------------

  PROCEDURE main(p_err_buf      OUT VARCHAR2,
                 p_ret_code     OUT NUMBER,
                 p_process_file IN VARCHAR2,
                 p_load_mode    IN VARCHAR2,
                 p_use_mode     IN VARCHAR2);

END dka_rep_int_tecpca_pkg;
/
SHOW ERRORS;
EXIT
