------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_LOADAVR.sql
-- DESCRIPTION      : Script de création de la directory DKA_LOADAVR
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 13/08/2013
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DIRECTORY DKA_LOADAVR
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

CREATE OR REPLACE DIRECTORY DKA_LOADAVR
AS '&&1';

EXIT;
