--------------------------------------------------------------------------------
-- $Id: XXEAI_IN_TYP_EVT_DEP_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_IN_TYP_EVT_DEP_TYP.sql
-- Description      : Création de l'objet XXEAI_IN_TYP_EVT_DEP_TYP
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

DROP TYPE XXEAI_IN_TYP_EVT_DEP_TYP
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_IN_TYP_EVT_DEP_TYP
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_IN_TYP_EVT_DEP_TYP IS
 OBJECT (FOLIO				VARCHAR2(10),
		 NATURE1 			VARCHAR2(50),
         NATURE2			VARCHAR2(50),
		 COMPTE_LOCAL		VARCHAR2(25)
         );
/


EXIT;

