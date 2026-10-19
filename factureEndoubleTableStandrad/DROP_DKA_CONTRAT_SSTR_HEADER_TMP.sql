-------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : Dalkia Oracle Applications
-- NOM              : DKA_APIMPORT_DIR.dir
-- DESCRIPTION      : Création du directory DKA_APIMPORT_DIR
--
-- AUTEUR           : J. JARDEZ
-- DATE DE CREATION : 19/07/2012
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : 
-------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
CREATE OR REPLACE DIRECTORY DKA_APIMPORT_DIR
  AS '&&1';
EXIT  