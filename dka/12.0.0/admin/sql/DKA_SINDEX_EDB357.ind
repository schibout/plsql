------------------------------------------------------------------------------------
-- $Id: DKA_SPOFUSION_DISTRIBS_TMP.ind $
-- Capgemini
-- PROJET            : DALKIA
-- NOM               : DKA_SINDEX_EDB357.ind
-- DESCRIPTION       : Création des index pour l'EDB357
---
--- AUTEUR           : Anas RAOUF (Capgemini)
--- DATE DE CREATION : 29/11/2022
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
PROMPT SUPPRESSION DE INDEX FA.DKA_FA_TRANSACTION_HEADERS_N9 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX FA.DKA_FA_TRANSACTION_HEADERS_N9;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX DKA_FA_DEPRN_SUMMARY_N2 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX FA.DKA_FA_DEPRN_SUMMARY_N2 ;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++




PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_FA_TRANSACTION_HEADERS_N9 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX FA.DKA_FA_TRANSACTION_HEADERS_N9  ON FA.FA_TRANSACTION_HEADERS (TRANSACTION_HEADER_ID, EVENT_ID) TABLESPACE &2 ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_IPOCDE_REPORT_HEADERS_N1  
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX FA.DKA_FA_DEPRN_SUMMARY_N2 ON FA.FA_DEPRN_SUMMARY (EVENT_ID, ASSET_ID) TABLESPACE &2 ;
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


EXIT
