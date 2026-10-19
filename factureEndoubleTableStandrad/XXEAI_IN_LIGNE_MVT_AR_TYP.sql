--------------------------------------------------------------------------------
-- $Id: XXEAI_INFO_INVOICE_LINE_OBJ.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INFO_INVOICE_LINE_OBJ.sql
-- Description      : Création de l'objet XXEAI_INFO_INVOICE_LINE_OBJ
-- Auteur           : Benjamin COUDRIER
-- Date de création : 21/11/2014
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
-- 23/03/2017 YWA artf2126142 
--------------------------------------------------------------------------------


PROMPT ======================================
PROMPT Suppression des TYPES existants
PROMPT ======================================
PROMPT
PROMPT !!!*** NE PAS TENIR COMPTE DES MESSAGES INDIQUANT : ***!!!
PROMPT !!!***   ORA-04043: object XXXXXX does not exist    ***!!!
PROMPT

DROP TYPE XXEAI_INFO_INVOICE_LINE_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_INFO_INVOICE_LINE_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_INFO_INVOICE_LINE_OBJ IS
 OBJECT (CODE_ERREUR 					VARCHAR2(50),
         LINE_TYPE_LOOKUP_CODE			VARCHAR2(25),
		 DIST_CODE_COMBINATION_ID		NUMBER(15),
		 ATTRIBUTE_CATEGORY				VARCHAR2(150),
		 ATTRIBUTE1						VARCHAR2(150),
     ATTRIBUTE7						VARCHAR2(150),
		 PROJECT_ID						NUMBER(15),
		 TASK_ID						NUMBER(15),
		 EXPENDITURE_TYPE				VARCHAR2(30),
		 EXPENDITURE_ORGANIZATION_ID	NUMBER(15),
		 TAX_CODE						VARCHAR2(150)-- artf2126142 
         );
/


EXIT;

