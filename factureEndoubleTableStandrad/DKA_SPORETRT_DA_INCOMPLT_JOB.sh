----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPFRSIMP                                        -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 16/03/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPAPFRSIMP.prog                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise founisseur                                   -
--              Fichier plat des banques fournisseur                 -
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
INTO TABLE DKA_AP_REP_SUPP_BANK_TMP
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(SEGMENT1                     "RTRIM(LTRIM(:SEGMENT1))"
,VENDOR_SITE_CODE             "RTRIM(LTRIM(:VENDOR_SITE_CODE))"
,BANK_NAME                    "RTRIM(LTRIM(:BANK_NAME))"
,BANK_NAME_ALT                "RTRIM(LTRIM(:BANK_NAME_ALT))"
,BANK_BRANCH_NAME             "RTRIM(LTRIM(:BANK_BRANCH_NAME))"
,BANK_BRANCH_NAME_ALT         "RTRIM(LTRIM(:BANK_BRANCH_NAME_ALT))"
,DESCRIPTION_BRANCH           "RTRIM(LTRIM(:DESCRIPTION_BRANCH))"
,ADDRESS_LINE1                "RTRIM(LTRIM(:ADDRESS_LINE1))"
,ADDRESS_LINE2                "RTRIM(LTRIM(:ADDRESS_LINE2))"
,ADDRESS_LINE3                "RTRIM(LTRIM(:ADDRESS_LINE3))"
,CITY                         "RTRIM(LTRIM(:CITY))"
,STATE                        "RTRIM(LTRIM(:STATE))"
,ZIP                          "RTRIM(LTRIM(:ZIP))"
,COUNTRY                      "RTRIM(LTRIM(:COUNTRY))"
,AREA_CODE                    "RTRIM(LTRIM(:AREA_CODE))"
,PHONE                        "RTRIM(LTRIM(:PHONE))"
,CONTACT_FIRST_NAME_B         "RTRIM(LTRIM(:CONTACT_FIRST_NAME_B))"
,CONTACT_LAST_NAME_B          "RTRIM(LTRIM(:CONTACT_LAST_NAME_B))"
,CONTACT_TITLE_B              "RTRIM(LTRIM(:CONTACT_TITLE_B))"
,BANK_NUM                     "RTRIM(LTRIM(:BANK_NUM))"
,BANK_NUMBER                  "RTRIM(LTRIM(:BANK_NUMBER))"
,ATTRIBUTE1                   "RTRIM(LTRIM(:ATTRIBUTE1))"
,ATTRIBUTE2_B                 "RTRIM(LTRIM(:ATTRIBUTE2_B))"
,ADDRESS_LINE4                "RTRIM(LTRIM(:ADDRESS_LINE4))"
,EFT_USER_NUMBER              "RTRIM(LTRIM(:EFT_USER_NUMBER))"
,EFT_SWIFT_CODE               "RTRIM(LTRIM(:EFT_SWIFT_CODE))"
,EDI_ID_NUMBER                "RTRIM(LTRIM(:EDI_ID_NUMBER))"
,BANK_BRANCH_TYPE             "RTRIM(LTRIM(:BANK_BRANCH_TYPE))"
,RFC_IDENTIFIER               "RTRIM(LTRIM(:RFC_IDENTIFIER))"
,BANK_ACCOUNT_NAME            "RTRIM(LTRIM(:BANK_ACCOUNT_NAME))"
,BANK_ACCOUNT_NAME_ALT        "RTRIM(LTRIM(:BANK_ACCOUNT_NAME_ALT))"
,BANK_ACCOUNT_NUM             "RTRIM(LTRIM(:BANK_ACCOUNT_NUM))"
,CURRENCY_CODE                "RTRIM(LTRIM(:CURRENCY_CODE))"
,DESCRIPTION_ACCOUNTS         "RTRIM(LTRIM(:DESCRIPTION_ACCOUNTS))"
,CONTACT_TITLE_ACCOUNTS       "RTRIM(LTRIM(:CONTACT_TITLE_ACCOUNTS))"
,CONTACT_AREA_CODE            "RTRIM(LTRIM(:CONTACT_AREA_CODE))"
,CONTACT_PHONE                "RTRIM(LTRIM(:CONTACT_PHONE))"
,CONTACT_FIRST_NAME_ACC       "RTRIM(LTRIM(:CONTACT_FIRST_NAME_ACC))"
,CONTACT_LAST_NAME_ACC        "RTRIM(LTRIM(:CONTACT_LAST_NAME_ACC))"
,BANK_ACCOUNT_TYPE            "RTRIM(LTRIM(:BANK_ACCOUNT_TYPE))"
,ACCOUNT_TYPE                 "RTRIM(LTRIM(:ACCOUNT_TYPE))"
,ATTRIBUTE2_ACC               "RTRIM(LTRIM(:ATTRIBUTE2_ACC))"
,ATTRIBUTE3                   "RTRIM(LTRIM(:ATTRIBUTE3))"
,ATTRIBUTE10                  "RTRIM(LTRIM(:ATTRIBUTE10))"
,CHECK_DIGITS                 "RTRIM(LTRIM(:CHECK_DIGITS))"
,ALLOW_MULTI_ASSIGNMENTS_FLAG "RTRIM(LTRIM(:ALLOW_MULTI_ASSIGNMENTS_FLAG))"
,AGENCY_LOCATION_CODE         "RTRIM(LTRIM(:AGENCY_LOCATION_CODE))"
,END_DATE                     DATE 'YYYY/MM/DD' NULLIF (END_DATE =BLANKS)
,IBAN_NUMBER                  "RTRIM(LTRIM(:IBAN_NUMBER))"
,START_DATE                     DATE 'YYYY/MM/DD' NULLIF (END_DATE =BLANKS)
,LOGICAL_LINE_NUM                   SEQUENCE(MAX,1)
,CREATION_DATE                      SYSDATE
,CREATED_BY                         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                   SYSDATE
,LAST_UPDATED_BY                    CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                    CONSTANT '!LOAD_REQUEST_ID!'
,PROCESSED_REQUEST_ID                 CONSTANT '-1'

)

