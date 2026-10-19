--------------------------------------------------------------------------------
-- $Id: XXEAI_IN_INVOICE_HEADER_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_IN_INVOICE_HEADER_TYP.sql
-- Description      : Création de l'objet XXEAI_IN_INVOICE_HEADER_TYP
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

DROP TYPE XXEAI_IN_INVOICE_HEADER_TYP
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_IN_INVOICE_HEADER_TYP
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_IN_INVOICE_HEADER_TYP IS
 OBJECT (FOLIO                  VARCHAR2(10),
         ID_FRS_EXT             VARCHAR2(150),
         UO                     VARCHAR2(25),
         TACHE_PROJET_FINANCE   VARCHAR2(25),
         DATE_FACTURE           DATE
         );
/


EXIT;

