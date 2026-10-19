-------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SAPFRSDUPLI.ctl
-- DESCRIPTION	    : Chargement de la table DKA_SAPFRSDUPLI_INIT_TMP
--
-- AUTEUR           : A.AMENKOUR
-- DATE DE CREATION : 14/01/2020
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      :Fichier de controle sql*loader                       -
--                   pour le chargement de la table de travail
-------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--  
-------------------------------------------------------------------------------------------
OPTIONS (ERRORS=0,SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_SAPFRSDUPLI_INIT_TMP
FIELDS TERMINATED BY ";" 
TRAILING NULLCOLS
 ( VENDOR_NAME                "RTRIM(LTRIM(:VENDOR_NAME ))"         ,
   ADDRESS_CODE               "RTRIM(LTRIM(:ADDRESS_CODE ))"        ,
   VENDOR_SITE_CODE           "RTRIM(LTRIM(:VENDOR_SITE_CODE ))"    ,
   UO                         "RTRIM(LTRIM(:UO ))"                  ,
   VENDOR_SITE_CODE_REF       "RTRIM(LTRIM(:VENDOR_SITE_CODE_REF ))",
   UO_SITE_REF                "REPLACE(:UO_SITE_REF,CHR(13),'')"        , 
   STATUT                     CONSTANT "NEW"              ,
   LIGNE_NUM                  "DKA_LINE_NUMBER_S.nextval" ,
   CREATION_DATE              "SYSDATE",
   CREATED_BY                 "FND_GLOBAL.USER_ID",
   LAST_UPDATE_DATE           "SYSDATE",
   LAST_UPDATED_BY            "FND_GLOBAL.USER_ID"
 )
