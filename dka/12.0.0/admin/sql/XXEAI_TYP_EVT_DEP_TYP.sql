--------------------------------------------------------------------------------
-- $Id: XXEAI_TYP_EVT_DEP_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_TYP_EVT_DEP_TYP.sql
-- Description      : Création de l'objet XXEAI_TYP_EVT_DEP_OBJ
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

DROP TYPE XXEAI_TYP_EVT_DEP_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_TYP_EVT_DEP_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_TYP_EVT_DEP_OBJ IS
 OBJECT (CODE_ERREUR 		VARCHAR2(50),
         TYPE_DEP_EVT		VARCHAR2(150)
         );
/


EXIT;

