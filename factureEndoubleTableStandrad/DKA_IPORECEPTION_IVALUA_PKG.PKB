CREATE OR REPLACE PACKAGE APPS.DKA_SAPDEBAUTOSSTR
  IS
--------------------------------------------------------------------------------------------
-- F-- $$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SAPDEBAUTOSSTR
 
-- Description      : DKA_SAPDEBAUTOSSTR
 
-- Auteur           : Sara HOUSSAINI(Capgemini)
-- Date de création : 01/10/2024
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
 TYPE liste_erreur IS RECORD
 ( FACTURE             NUMBER
  , NUM_LIGNE           VARCHAR2(50)
  );
  
   TYPE liste_facture IS RECORD
  ( FACTURE             NUMBER
  , NUM_LIGNE           VARCHAR2(50)
  );


 TYPE l_erreur IS TABLE OF liste_erreur index by BINARY_INTEGER;
 TYPE l_facture IS TABLE OF liste_facture index by BINARY_INTEGER;

PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER
                   )
;


 END DKA_SAPDEBAUTOSSTR
 ;

/

SHOW ERRORS

EXIT
