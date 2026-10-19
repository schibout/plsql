------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DALKIA_LOADBDC.sql
-- DESCRIPTION      : Script de création de la directory DALKIA_LOADBDC
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 20/03/2007
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DIRECTORY DALKIA_LOADBDC
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

CREATE OR REPLACE DIRECTORY DALKIA_LOADBDC
AS '&&1';

EXIT;
