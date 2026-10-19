create or replace PACKAGE DKA_SAPFRSDUPLI_MASSE_PKG IS
--------------------------------------------------------------------------------------------
-- F-- $$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SAPFRSDUPLI_MASSE_PKG.pkb
-- Description      : DKA_SAPFRSDUPLI_MASSE_PKG package body
-- Auteur           : S.HAHIOUI(Capgemini)
-- Date de création : 13/12/2019
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
 TYPE liste_erreur_dupli IS RECORD
  ( NOM_FICHIER         VARCHAR2(240)
  , NUM_LIGNE           NUMBER
  , NUM_FOURNISSEUR     VARCHAR2(240)
  , CODE_SITE           VARCHAR2(20)
  , UO_SITE             VARCHAR2(20)
  , CODE_ADRESSE         VARCHAR2(25)
  , MSG_ERREUR          VARCHAR2(1000)
  );
  
   TYPE liste_avertissement IS RECORD
  ( NOM_FICHIER         VARCHAR2(240)
  , NUM_LIGNE           NUMBER
  , NUM_FOURNISSEUR     VARCHAR2(240)
  , CODE_SITE           VARCHAR2(20)
  , UO_SITE             VARCHAR2(20)
  , CODE_ADRESSE         VARCHAR2(25)
  , MSG_ERREUR          VARCHAR2(1000)
  );

 TYPE l_erreur_dupli IS TABLE OF liste_erreur_dupli index by BINARY_INTEGER;
 TYPE l_avertissement IS TABLE OF liste_avertissement index by BINARY_INTEGER;

 PROCEDURE main( p_errbuf           OUT VARCHAR2,
                 p_retcode          OUT NUMBER
                 );



 END DKA_SAPFRSDUPLI_MASSE_PKG;
/
SHOW ERRORS
EXIT