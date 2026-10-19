--------------------------------------------------------------------------------
-- $Id: XXEAI_SOCIETE_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_SOCIETE_TYP.sql
-- Description      : Création de l'objet XXEAI_SOCIETE_OBJ
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

DROP TYPE XXEAI_SOCIETE_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_SOCIETE_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_SOCIETE_OBJ IS
 OBJECT (CODE_ERREUR 		VARCHAR2(50),
         CODE_SOCIETE		VARCHAR2(4)
         );
/


EXIT;

