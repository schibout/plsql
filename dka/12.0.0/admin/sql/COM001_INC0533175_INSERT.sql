-------------------------------------------------------------------------------
-- CAP GEMINI
-- Projet : DALKIA Oracle Applications
-- Auteur : 
-- Date Création : 
-- Version livrables : 
--------------------------------------------------------------------------------
-- NOM : COM001_INC0533175_SAVE.sql
-- DESCRIPTION : 
-- COMMENTAIRE      : 
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 14/04/2021 SHA Script temporaire pour sauvegarde et suppression
--------------------------------------------------------------------------------------------

-- RE-INSERTION DES DONNEES DANS LA TABLE 
INSERT INTO DKA.DKA_PROGRAM_MESSAGES SELECT * FROM COM0001_INC0533175_TMP;

-- SUPPRESION DE LA TABLE TEMPORAIRE
DROP TABLE COM0001_INC0533175_TMP;
/
SHOW ERRORS;

EXIT
