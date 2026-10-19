--------------------------------------------------------------------------------
-- $Id: XXEAI_CST_FLUX_GL_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_CST_FLUX_GL_TYP.sql
-- Description      : Création de l'objet XXEAI_CST_FLUX_GL_OBJ
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
-- 02/01/2016 MEG artf2071034 : ajout application_name
--------------------------------------------------------------------------------


PROMPT ======================================
PROMPT Suppression des TYPES existants
PROMPT ======================================
PROMPT
PROMPT !!!*** NE PAS TENIR COMPTE DES MESSAGES INDIQUANT : ***!!!
PROMPT !!!***   ORA-04043: object XXXXXX does not exist    ***!!!
PROMPT

DROP TYPE XXEAI_CST_FLUX_GL_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_CST_FLUX_GL_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_CST_FLUX_GL_OBJ IS
 OBJECT (CODE_ERREUR 		  VARCHAR2(50),
         FOLIO_OA    		  VARCHAR2(4),
         STATUS  			    VARCHAR2(50),
		     CURRENCY_CODE	  VARCHAR2(15),
		     ACTUAL_FLAG		  VARCHAR2(1),
		     CATEGORY_NAME	  VARCHAR2(25),
		     SOURCE_NAME		  VARCHAR2(25),
         APPLICATION_NAME VARCHAR2(255)
         );
/


EXIT;

