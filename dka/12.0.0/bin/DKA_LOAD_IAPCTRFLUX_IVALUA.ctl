-------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IAPCTRFLUX_IVALUA.ctl
-- DESCRIPTION	    : Chargement de la table DKA_IAPCTRFLUX_IVALUA_TMP
--
-- AUTEUR           : Mathieu TIABLIKOFF
-- DATE DE CREATION : 24/09/2020
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA
--                    en lui passant 3 parametres :
--                           1) Password APPS
--                           2) Tablespace des données pour schéma DKA
--                           3) Tablespace des index   pour schéma DKA
-------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--  
-------------------------------------------------------------------------------------------
LOAD DATA 
TRUNCATE
INTO TABLE DKA.DKA_IAPCTRFLUX_IVALUA_TMP
fields terminated by ";"
trailing nullcols
 ( DATE_ENVOI_YYYYMMDD  
 , COMPANY_VALUE 
 , NB_INVOICES_PROCESSED 
 , NB_INVOICES_REJECTED 
 , NB_TRA_FILE 
 , NB_PNC_FILE TERMINATED BY WHITESPACE
 )

