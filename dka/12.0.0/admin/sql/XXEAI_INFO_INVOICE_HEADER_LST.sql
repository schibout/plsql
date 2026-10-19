--------------------------------------------------------------------------------
-- $Id: XXEAI_INFO_INVOICE_HEADER_LST.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INFO_INVOICE_HEADER_LST.sql
-- Description      : Création de l'objet XXEAI_INFO_INVOICE_HEADER_LST
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

DROP TYPE XXEAI_INFO_INVOICE_HEADER_LST
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_INFO_INVOICE_HEADER_LST
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_INFO_INVOICE_HEADER_LST IS
 OBJECT (CODE_ERREUR 			VARCHAR2(50),
         TAB_INVOICE_HEADER		XXEAI_INFO_INVOICE_HEADER_TAB
         );
/


EXIT;

