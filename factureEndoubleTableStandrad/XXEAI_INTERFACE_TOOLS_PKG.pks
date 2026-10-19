CREATE OR REPLACE PACKAGE DKA_SAPPRELAUTORB_PKG IS
  --------------------------------------------------------------------------------------------
  -- F-- $$
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_SRBFACTURE_PKG.pkb
  -- Description      : DKA_SRBFACTURE_PKG package body
  -- Auteur           : S.HAHIOUI(Capgemini)
  -- Date de création : 30/12/2020
  -- Doc. associée    :
  -- Commentaire      : à exécuter sous SQLPLUS avec l'utilisateur APPS
  ---------------------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  ---------------------------------------------------------------------------------------------
  -- Date           Qui Description
  -- -------------- --- ---------------------------------------------------------------
  ------------------------------------------------------------------------------------
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
  ---------------------------------------------------------------------------------------------
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  /*
  *************************************************************************
  * PROCEDURE NAME : main
  * 
  * DESCRIPTION
  *  Procédure principale
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  * p_errbuf          Retour de message éventuel
  * p_retcode         Statut du traitement en sortie
  ************************************************************************
  */

  PROCEDURE main(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER);

  /*
  *************************************************************************
  * PROCEDURE NAME : main2
  * 
  * DESCRIPTION
  *  Procédure principale
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  * p_errbuf          Retour de message éventuel
  * p_retcode         Statut du traitement en sortie
  ************************************************************************
  */

  PROCEDURE main2(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER);

  /*=====================================================================================
  * PROCEDURE NAME : main_crea_reg
  *
  * DESCRIPTION
  *  Procédure principale de création du règlement
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  * p_errbuf         Retour de message éventuel
  * p_retcode        Statut du traitement en sortie
  *=====================================================================================*/
  PROCEDURE MAIN_CREA_REG(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER);

  /*=====================================================================================
  * PROCEDURE NAME : MAIN_COMPTA
  *
  * DESCRIPTION
  *  Procédure principale de création du règlement
  *
  * PARAMETERS
  * ==========
  * NAME              DESCRIPTION
  * ----------------- ------------------------------------------------------
  * p_errbuf         Retour de message éventuel
  * p_retcode        Statut du traitement en sortie
  *=====================================================================================*/
  PROCEDURE MAIN_COMPTA(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER);

/*=====================================================================================
 * PROCEDURE NAME : main6
 *
 * DESCRIPTION
 *  Procédure principale de mise à jour des ref RB
 *
 * PARAMETERS
 * ==========
 * NAME              DESCRIPTION
 * ----------------- ------------------------------------------------------
 * p_errbuf         Retour de message éventuel
 * p_retcode        Statut du traitement en sortie
 *=====================================================================================*/
 PROCEDURE MAIN6( p_errbuf           OUT VARCHAR2,
 p_retcode          OUT NUMBER
 );
 

END DKA_SAPPRELAUTORB_PKG;
/
SHOW ERRORS
EXIT
