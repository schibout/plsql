--------------------------------------------------------------------------------
-- $Id: XXEAI_SOCIETE_LST.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_SOCIETE_LST.sql
-- Description      : Création de l'objet XXEAI_SOCIETE_LST
-- Auteur           : Benjamin COUDRIER
-- Date de création : 19/08/2014
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- Login XXEAI
--                    2- Password XXEAI
--
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 
--------------------------------------------------------------------------------


PROMPT ======================================
PROMPT Suppression des TYPES existants
PROMPT ======================================
PROMPT
PROMPT !!!*** NE PAS TENIR COMPTE DES MESSAGES INDIQUANT : ***!!!
PROMPT !!!***   ORA-04043: object XXXXXX does not exist    ***!!!
PROMPT

DROP TYPE XXEAI_SOCIETE_LST
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_SOCIETE_LST
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_SOCIETE_LST IS
 OBJECT (CODE_ERREUR 		VARCHAR2(50),
         TAB_SOCIETE		XXEAI_SOCIETE_TAB
         );
/

SHOW ERRORS;
EXIT;

