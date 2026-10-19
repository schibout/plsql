create or replace PACKAGE DKA_FUSGLCTRLPR_PKG IS
--------------------------------------------------------------------------------------------
-- F-- $$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_FUSGLCTRLPR_PKG.pkb
-- Description      : DKA_FUSGLCTRLPR_PKG package body
-- Auteur           : S.HAHIOUI(Capgemini)
-- Date de création : 11/10/2019
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

 PROCEDURE main(p_errbuf     IN    OUT VARCHAR2,
                p_retcode          OUT NUMBER
             
               );
 END DKA_FUSGLCTRLPR_PKG;
/
SHOW ERRORS
EXIT