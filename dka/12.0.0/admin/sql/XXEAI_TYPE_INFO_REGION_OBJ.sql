--------------------------------------------------------------------------------
-- $Id: XXEAI_TYPE_INFO_REGION_OBJ.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_TYPE_INFO_REGION_OBJ.sql
-- Description      : Création de l'objet XXEAI_TYPE_INFO_REGION_OBJ
-- Auteur           : Hugues DESCROIZETTE
-- Date de création : 22/09/2016
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

DROP TYPE XXEAI_TYPE_INFO_REGION_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_TYPE_INFO_REGION_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_TYPE_INFO_REGION_OBJ IS
 OBJECT (CODE_ERREUR 					VARCHAR2(50),
         REGION                         VARCHAR2(50)
         );
/


EXIT;

