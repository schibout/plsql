------------------------------------------------------------------------------------
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_SARAUTOPRELEV_EXP_STAT.ind
---
--- AUTEUR           : Anas RAOUF (Capgemini)
--- DATE DE CREATION : 11/11/2024
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
PROMPT SUPPRESSION DE INDEX DKA.DKA_SARAUTOPRELEV_EXP_STAT_N9 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA.DKA_SARAUTOPRELEV_EXP_STAT_N9;


PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_SARAUTOPRELEV_EXP_STAT_N9 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA.DKA_SARAUTOPRELEV_EXP_STAT_N9  ON DKA.DKA_SARAUTOPRELEV_EXP_STAT (CASH_RECEIPT_ID) TABLESPACE &2 ;


EXIT
