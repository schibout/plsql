----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPFRSIMP                                         -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 16/03/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPAPFRSIMP.prog                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise founisseur                  				 -
--              Fichier plat des contacts des sites fournisseur      -
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
INTO TABLE DKA_AP_REP_SUPP_SITES_CTCT_TMP
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(SEGMENT1          "RTRIM(LTRIM(:SEGMENT1))"
,VENDOR_SITE_CODE  "RTRIM(LTRIM(:VENDOR_SITE_CODE))"
,FIRST_NAME        "RTRIM(LTRIM(:FIRST_NAME))"
,MIDDLE_NAME       "RTRIM(LTRIM(:MIDDLE_NAME))"
,LAST_NAME         "RTRIM(LTRIM(:LAST_NAME))"
,PREFIX            "RTRIM(LTRIM(:PREFIX))"
,TITLE             "RTRIM(LTRIM(:TITLE))"
,AREA_CODE         "RTRIM(LTRIM(:AREA_CODE))"
,PHONE             "RTRIM(LTRIM(:PHONE))"
,CONTACT_NAME_ALT  "RTRIM(LTRIM(:CONTACT_NAME_ALT))"
,FIRST_NAME_ALT    "RTRIM(LTRIM(:FIRST_NAME_ALT))"
,LAST_NAME_ALT     "RTRIM(LTRIM(:LAST_NAME_ALT))"
,DEPARTMENT        "RTRIM(LTRIM(:DEPARTMENT))"
,EMAIL_ADDRESS     "RTRIM(LTRIM(:EMAIL_ADDRESS))"
,URL               "RTRIM(LTRIM(:URL))"
,ALT_AREA_CODE     "RTRIM(LTRIM(:ALT_AREA_CODE))"
,ALT_PHONE         "RTRIM(LTRIM(:ALT_PHONE))"
,FAX_AREA_CODE     "RTRIM(LTRIM(:FAX_AREA_CODE))"
,FAX               "RTRIM(LTRIM(:FAX))"
,LOGICAL_LINE_NUM                   SEQUENCE(MAX,1)
,CREATION_DATE                      SYSDATE
,CREATED_BY                         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                   SYSDATE
,LAST_UPDATED_BY                    CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                    CONSTANT '!LOAD_REQUEST_ID!'
,PROCESSED_REQUEST_ID                 CONSTANT '-1'

)

