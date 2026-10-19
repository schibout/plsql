-------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IAPFACDSP.ctl
-- DESCRIPTION	    : Chargement de la table DKA_IAPFACDSP_TMP
--
-- AUTEUR           : Mathieu TIABLIKOFF
-- DATE DE CREATION : 14/10/2020
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
INTO TABLE DKA.DKA_IAPFACDSP_TMP
fields terminated by ";"
trailing nullcols
 ( COLUMN1 
 , COLUMN2 
 , COLUMN3 
 , COLUMN4 
 , COLUMN5 		"substr(:COLUMN5,1,15)"
 , COLUMN6 
 , COLUMN7 
 , COLUMN8 
 , COLUMN9 
 , COLUMN10
 , COLUMN11
 , COLUMN12
 , COLUMN13
 , COLUMN14
 , COLUMN15
 , COLUMN16
 , COLUMN17
 , COLUMN18
 , COLUMN19
 , COLUMN20		"substr(:COLUMN20,1,4)"
 , COLUMN21
 , COLUMN22
 , COLUMN23
 , COLUMN24
 , COLUMN25
 , COLUMN26
 , COLUMN27 TERMINATED BY WHITESPACE
 )
