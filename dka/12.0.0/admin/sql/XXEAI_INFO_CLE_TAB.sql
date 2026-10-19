--------------------------------------------------------------------------------
-- $Id: XXEAI_INFO_CLE_TAB.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INFO_CLE_TAB.sql
-- Description      : Création de l'objet XXEAI_INFO_CLE_TAB
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

DROP TYPE XXEAI_INFO_CLE_TAB
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_INFO_CLE_TAB
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_INFO_CLE_TAB IS TABLE OF XXEAI_INFO_CLE_TYP;

/


EXIT;

