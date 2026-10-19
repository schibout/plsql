--------------------------------------------------------------------------------
-- $Id: XXEAI_TYP_EVT_DEP_LST.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_TYP_EVT_DEP_LST.sql
-- Description      : Création de l'objet XXEAI_TYP_EVT_DEP_LST
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

DROP TYPE XXEAI_TYP_EVT_DEP_LST
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_TYP_EVT_DEP_LST
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_TYP_EVT_DEP_LST IS
 OBJECT (CODE_ERREUR 		VARCHAR2(50),
         TAB_TYP_EVT_DEP	XXEAI_TYP_EVT_DEP_TAB
         );
/


EXIT;

