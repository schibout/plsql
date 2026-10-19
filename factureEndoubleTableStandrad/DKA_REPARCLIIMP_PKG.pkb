--------------------------------------------------------------------------------
-- $Id: XXEAI_CLE_COMPTABLE_CUF_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_CLE_COMPTABLE_CUF_TYP.sql
-- Description      : Création de l'objet XXEAI_CLE_COMPTABLE_CUF_OBJ
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

DROP TYPE XXEAI_CLE_COMPTABLE_CUF_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_CLE_COMPTABLE_CUF_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_CLE_COMPTABLE_CUF_OBJ IS
 OBJECT (CODE_ERREUR 		VARCHAR2(50),
         LEDGER_ID          NUMBER(15),
         SEGMENT1			VARCHAR2(25),
		 SEGMENT2			VARCHAR2(25),
		 SEGMENT3			VARCHAR2(25),
		 SEGMENT4			VARCHAR2(25),
		 SEGMENT5			VARCHAR2(25),
		 SEGMENT6			VARCHAR2(25),
		 SEGMENT7			VARCHAR2(25),
		 SEGMENT8			VARCHAR2(25),
		 SEGMENT9			VARCHAR2(25),
		 SEGMENT10			VARCHAR2(25),
		 SEGMENT11			VARCHAR2(25),
		 SEGMENT12			VARCHAR2(25),
		 CONTEXT3			VARCHAR2(150),
		 ATTRIBUTE11		VARCHAR2(150),
		 ATTRIBUTE17		VARCHAR2(150),
		 ATTRIBUTE12		VARCHAR2(150),
		 ATTRIBUTE13		VARCHAR2(150),
		 ATTRIBUTE14		VARCHAR2(150),
		 ATTRIBUTE15		VARCHAR2(150),
		 ATTRIBUTE18		VARCHAR2(150)
         );
/


EXIT;

