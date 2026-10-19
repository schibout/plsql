--------------------------------------------------------------------------------
-- $Id: XXEAI_IN_LIGNE_MVT_AR_TYP.sql $
-- Capgemini
-- Projet           : Dalkia HELIOS
-- Nom              : XXEAI_IN_LIGNE_MVT_AR_TYP.sql
-- Description      : Création de l'objet XXEAI_IN_LIGNE_MVT_AR_TYP
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

DROP TYPE XXEAI_IN_LIGNE_MVT_AR_TYP
/

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L OBJET XXEAI_IN_LIGNE_MVT_AR_TYP
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE TYPE XXEAI_IN_LIGNE_MVT_AR_TYP IS
 OBJECT (
           COMPTE_LOCAL		VARCHAR2(25),
           SOUS_COMPTE    VARCHAR2(25),
           SIGNE          VARCHAR2(1),     -- + ou -
           DEBIT_CREDIT   VARCHAR2(1),     -- D ou C
           MONTANT        NUMBER
        );
/


EXIT;

