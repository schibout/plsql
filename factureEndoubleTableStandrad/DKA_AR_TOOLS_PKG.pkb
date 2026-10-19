------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : SCTLFLUX_OUT_DIR.sql
-- DESCRIPTION      : Script de création de la directory SCTLFLUX_OUT_DIR
--
-- AUTEUR           : Benjamin COUDRIER
-- DATE DE CREATION : 21/10/2014
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++             
PROMPT CREATION DIRECTORY SCTLFLUX_OUT_DIR
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

CREATE OR REPLACE DIRECTORY SCTLFLUX_OUT_DIR
AS '&&1';

EXIT;
