--------------------------------------------------------------------------------
-- $Id: XXEAI_INFO_INVOICE_HEADER_OBJ.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INFO_INVOICE_HEADER_OBJ.sql
-- Description      : Création de l'objet XXEAI_INFO_INVOICE_HEADER_OBJ
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
-- 
--------------------------------------------------------------------------------


PROMPT ======================================
PROMPT Suppression des TYPES existants
PROMPT ======================================
PROMPT
PROMPT !!!*** NE PAS TENIR COMPTE DES MESSAGES INDIQUANT : ***!!!
PROMPT !!!***   ORA-04043: object XXXXXX does not exist    ***!!!
PROMPT

DROP TYPE XXEAI_INFO_INVOICE_HEADER_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_INFO_INVOICE_HEADER_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_INFO_INVOICE_HEADER_OBJ IS
 OBJECT (CODE_ERREUR 					VARCHAR2(50),
         VENDOR_ID						NUMBER(15),
		 VENDOR_SITE_ID					NUMBER(15),
		 GLOBAL_ATTRIBUTE1				VARCHAR2(150),
		 PAY_GROUP_LOOKUP_CODE			VARCHAR2(25),
		 ACCTS_PAY_CODE_COMBINATION_ID	NUMBER(15),
		 DOC_CATEGORY_CODE				VARCHAR2(30), 
         ORG_ID                         NUMBER(15)
         );
/


EXIT;

