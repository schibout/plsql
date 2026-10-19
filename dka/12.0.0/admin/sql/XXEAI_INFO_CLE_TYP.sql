--------------------------------------------------------------------------------
-- $Id: XXEAI_INFO_CLE_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INFO_CLE_TYP.sql
-- Description      : Création de l'objet XXEAI_INFO_CLE_TYP
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
-- 04/07/2023 ARA pbm rejet OAE021 dans la GDR par les procédures stockées
--------------------------------------------------------------------------------


PROMPT ======================================
PROMPT Suppression des TYPES existants
PROMPT ======================================
PROMPT
PROMPT !!!*** NE PAS TENIR COMPTE DES MESSAGES INDIQUANT : ***!!!
PROMPT !!!***   ORA-04043: object XXXXXX does not exist    ***!!!
PROMPT

DROP TYPE XXEAI_INFO_CLE_TYP force;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_INFO_CLE_TYP
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_INFO_CLE_TYP FORCE IS
 OBJECT (FOLIO                  VARCHAR2(10),
         SOCIETE                VARCHAR2(4),
         REGION                 VARCHAR2(25),
         CENTRE_FINANCE         VARCHAR2(25),
         DATE_COMPTABLE         DATE,
         COMPTE_LOCAL           VARCHAR2(25),
         CODE_AFFAIRE           VARCHAR2(25),
         TACHE_PROJET_FINANCE   VARCHAR2(25),
         TYPE_DEP_EVT           VARCHAR2(150),
         --QUANTITE               NUMBER
		 QUANTITE               VARCHAR2(80)
         );
/


EXIT;

