-------------------------------------------------------------------------------------
-- $Id: DKA_SARAUTOPRELEV_DIR.sql 34 2008-08-05 12:53:03Z tbonduae $
-- Capgemini
-- PROJET           : Dalkia Oracle Applications
-- NOM              : DKA_SARAUTOPRELEV_DIR.sql
-- DESCRIPTION      : Création de la directory DKA_SARAUTOPRELEV_DIR
--
-- AUTEUR           : C. Trochu (Capgemini)
-- DATE DE CREATION : 10/07/2008
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : 
-------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------
--
-------------------------------------------------------------------------------------
CREATE OR REPLACE DIRECTORY DKA_SARAUTOPRELEV_DIR
  AS '&&1';
EXIT  
