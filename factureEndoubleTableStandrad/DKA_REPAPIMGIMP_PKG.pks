------------------------------------------------------------------------------------
-- $Id: DKA_RCV_TRANSACTIONS_TMP.ind $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_RCV_TRANSACTIONS_TMP.ind
-- DESCRIPTION       : Création des index de la table specifique DKA_RCV_TRANSACTIONS_TMP
---
--- AUTEUR           : Capgemini
--- DATE DE CREATION : 05/12/2016
--- DOC. ASSOCIEE    : 
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user schema
--                     en lui passant en paramètre :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- Password APPS
--                    2- Tablespace des index pour le schéma APPLSYSX
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
---
------------------------------------------------------------------------------------

CONNECT APPS/&1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_RCV_TRANSACTIONS_NU1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA.DKA_RCV_TRANSACTIONS_NU1;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_RCV_TRANSACTIONS_NU2
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA.DKA_RCV_TRANSACTIONS_NU2;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_RCV_TRANSACTIONS_NU3
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA.DKA_RCV_TRANSACTIONS_NU3;




PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_RCV_TRANSACTIONS_NU1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA.DKA_RCV_TRANSACTIONS_NU1        ON DKA.DKA_RCV_TRANSACTIONS_TMP ( Receipt_Num )  TABLESPACE &2; 

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_RCV_TRANSACTIONS_NU2
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA.DKA_RCV_TRANSACTIONS_NU2        ON DKA.DKA_RCV_TRANSACTIONS_TMP ( Parent_transaction_id  )  TABLESPACE &2;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_RCV_TRANSACTIONS_TMP_NU3
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA.DKA_RCV_TRANSACTIONS_NU3        ON DKA.DKA_RCV_TRANSACTIONS_TMP ( Po_Num, Po_Line_Num  )  TABLESPACE &2;



EXIT
