----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPFRSIMP                                        -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 16/03/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPAPFRSIMP.prog                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise founisseur                  				 -
--              Fichier plat des societé sur lesqulles les sites fournisseurs devront être créé -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.0                                        -
-- PROGRAMME MODIFIE LE :                                            -
-- PAR                  :                                            -
-- OBJET                :                                            -
--                                                                   -
----------------------------------------------------------------------
OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_DUP_SITE_FOURNISSEUR
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(SEGMENT1                          "RTRIM(LTRIM(:SEGMENT1))"
,VENDOR_SITE_CODE                  "RTRIM(LTRIM(:VENDOR_SITE_CODE))"
,SOCIETE                           "RTRIM(LTRIM(:SOCIETE))"
,LOGICAL_LINE_NUM                   SEQUENCE(MAX,1)
,CREATION_DATE                      SYSDATE
,CREATED_BY                         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                   SYSDATE
,LAST_UPDATED_BY                    CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                    CONSTANT '!LOAD_REQUEST_ID!'
,PROCESSED_REQUEST_ID                 CONSTANT '-1'
		
)

