--------------------------------------------------------------------------------
-- $Id: XXEAI_IN_INVOICE_LINE_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_IN_INVOICE_LINE_TYP.sql
-- Description      : Création de l'objet XXEAI_IN_INVOICE_LINE_TYP
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

DROP TYPE XXEAI_IN_INVOICE_LINE_TYP
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_IN_INVOICE_LINE_TYP
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_IN_INVOICE_LINE_TYP IS
 OBJECT (FOLIO_ORACLE 			VARCHAR2(10),
         TACHE_PROJET           VARCHAR2(25),
        NATURE1				VARCHAR2(50),
        NATURE2				VARCHAR2(50),
        SOCIETE				VARCHAR2(25),
        REGION				VARCHAR2(25),
        COMPTE_LOCAL		VARCHAR2(25),
        TAX_RATE				NUMBER(15,2),
        DATE_FACTURE		DATE,
        REGIME_TVA			VARCHAR2(150)
         );
/


EXIT;

