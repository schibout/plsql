--------------------------------------------------------------------------------
-- $Id: XXEAI_INFOS_BANQUE_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INFOS_BANQUE_TYP.sql
-- Description      : Création de l'objet XXEAI_INFOS_BANQUE_OBJ
-- Auteur           : Julien Jardez
-- Date de création : 19/05/2014
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

DROP TYPE XXEAI_INFOS_BANQUE_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_INFOS_BANQUE_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_INFOS_BANQUE_OBJ IS
 OBJECT (CODE_BANQUE VARCHAR2(30),
         CODE_BIC    VARCHAR2(12),
         NOM_BANQUE  VARCHAR2(60)
         );
/


EXIT;

