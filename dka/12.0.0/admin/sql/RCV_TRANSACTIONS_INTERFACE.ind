------------------------------------------------------------------------------------
-- $Id: RCV_TRANSACTIONS_INTERFACE.ind $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : RCV_TRANSACTIONS_INTERFACE.ind
-- DESCRIPTION       : Création des index de la table specifique RCV_TRANSACTIONS_INTERFACE
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
PROMPT CREATION DE INDEX DKA_RCV_TRX_INTERFACE_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA.DKA_RCV_TRX_INTERFACE_N1;




PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_RCV_TRX_INTERFACE_N1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA.DKA_RCV_TRX_INTERFACE_N1        ON PO.RCV_TRANSACTIONS_INTERFACE ( PARENT_INTERFACE_TXN_ID )  TABLESPACE &2; 





EXIT
