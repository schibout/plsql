--------------------------------------------------------------------------------
-- $Id: supp_synonyms.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : supp_synonyms.sql
-- Description      : Suppression des synonymes inutiles
-- Auteur           : Nicolas BOUSSEKEYT
-- Date de création : 21/07/2017
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
-- 
--------------------------------------------------------------------------------


drop synonym apps.fa_invoice_tmp;
drop synonym apps.fa_tax_tmp;
drop view dka.FA_INVOICE_TMP#;
drop view dka.FA_TAX_TMP#;
drop synonym CAP_CONSULTATION.fa_invoice_tmp#;
drop synonym CAP_CONSULTATION.fa_tax_tmp#;
/

EXIT;