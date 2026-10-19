--------------------------------------------------------------------------------
-- $Id: XXEAI_CST_FLUX_AP_OBJ.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_CST_FLUX_AP_OBJ.sql
-- Description      : Création de l'objet XXEAI_CST_FLUX_AP_OBJ
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
-- 22/01/2015 BCO DPE20150006 - Outils d’interface AP pour l’EAI – Problématiques de TVA
--------------------------------------------------------------------------------


PROMPT ======================================
PROMPT Suppression des TYPES existants
PROMPT ======================================
PROMPT
PROMPT !!!*** NE PAS TENIR COMPTE DES MESSAGES INDIQUANT : ***!!!
PROMPT !!!***   ORA-04043: object XXXXXX does not exist    ***!!!
PROMPT

DROP TYPE XXEAI_CST_FLUX_AP_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_CST_FLUX_AP_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_CST_FLUX_AP_OBJ IS
 OBJECT (CODE_ERREUR                VARCHAR2(50),
         INVOICE_CURRENCY_CODE      VARCHAR2(15),
         ATTRIBUTE9                 VARCHAR2(150),
         GLOBAL_ATTRIBURE_CATEGORY  VARCHAR2(150),
         SOURCE                     VARCHAR2(80),
         PAYMENT_CROSS_RATE_TYPE    VARCHAR2(30),
         PAYMENT_CROSS_RATE         NUMBER,
         PAYMENT_CURRENCY_CODE      VARCHAR2(15)
         );
/


EXIT;

