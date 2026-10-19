-------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : Dalkia Oracle Applications
-- NOM              : DKA_SARENCAIS_FILE_OUT_DIR.sql
-- DESCRIPTION      : Création du directory DKA_SARENCAIS_FILE_OUT_DIR
--
-- AUTEUR           : Benjamin COUDRIER
-- DATE DE CREATION : 21/08/2012
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : 
-------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
CREATE OR REPLACE DIRECTORY DKA_SARENCAIS_FILE_OUT_DIR
  AS '&&1';
EXIT 
