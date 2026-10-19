--------------------------------------------------------------------------------
-- $Id: XXEAI_INVOICE_ID_TAB.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INVOICE_ID_TAB.sql
-- Description      : Création de l'objet XXEAI_INVOICE_ID_TAB
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

DROP TYPE XXEAI_INVOICE_ID_TAB
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_INVOICE_ID_TAB
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_INVOICE_ID_TAB IS TABLE OF XXEAI_INVOICE_ID;

/


EXIT;

