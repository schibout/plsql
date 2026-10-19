------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_OUT_DIR.sql
-- DESCRIPTION      : Script de création de la directory DKA_OUT_DIR
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 29/04/2014
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DIRECTORY DKA_OUT_DIR
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

CREATE OR REPLACE DIRECTORY DKA_OUT_DIR
AS '&&1';

EXIT;
