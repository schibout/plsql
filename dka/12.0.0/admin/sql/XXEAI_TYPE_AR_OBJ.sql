--------------------------------------------------------------------------------
-- $Id: XXEAI_TYPE_AR_OBJ.sql $
-- Capgemini
-- Projet           : Dalkia HELIOS
-- Nom              : XXEAI_TYPE_AR_OBJ.sql
-- Description      : Création de l'objet XXEAI_TYPE_AR_OBJ
-- Auteur           : Hugues DESCROIZETTE
-- Date de création : 20/09/2016
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
-- 20/09/2016 HDE 5.6.1	Fonctionnalité 16 : Déterminer les type et numero de ligne et le type de mouvement AR
--------------------------------------------------------------------------------


PROMPT ======================================
PROMPT Suppression des TYPES existants
PROMPT ======================================
PROMPT
PROMPT !!!*** NE PAS TENIR COMPTE DES MESSAGES INDIQUANT : ***!!!
PROMPT !!!***   ORA-04043: object XXXXXX does not exist    ***!!!
PROMPT

DROP TYPE XXEAI_TYPE_AR_OBJ
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_TYPE_AR_OBJ
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_TYPE_AR_OBJ IS
 OBJECT (
          CODE_ERREUR    VARCHAR2(50),         -- Code Erreur
          LINE_TYPE      VARCHAR2(25),         -- Type de ligne
          LINE_NUM       NUMBER(15),           -- Numéro de ligne
          TYPE_MVT       VARCHAR2(50)          -- Type de mouvement
        );
/


EXIT;

