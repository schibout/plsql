------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SARG00C8_MAIL.sql
-- DESCRIPTION      : Script de création de la directory DKA_SARG00C8_MAIL
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
PROMPT CREATION DIRECTORY DKA_SARG00C8_MAIL
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ 

CREATE OR REPLACE DIRECTORY DKA_SARG00C8_MAIL
AS '&&1';

EXIT;
