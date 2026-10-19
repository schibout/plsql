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


--SAUVEGARDE
CREATE TABLE COM0001_INC0533175_TMP AS SELECT * FROM DKA.DKA_PROGRAM_MESSAGES;

--SUPPRESSION
DROP SYNONYM APPS.DKA_PROGRAM_MESSAGES;
DROP VIEW DKA.DKA_PROGRAM_MESSAGES#;
DROP TABLE DKA.DKA_PROGRAM_MESSAGES;

/
SHOW ERRORS;

EXIT
