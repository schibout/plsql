----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPFCTIMP_LOADER                                        -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 14/04/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPAPFCTIMP_LOADER.prog                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise blocages factures founisseurs                  		 -
--              Fichier plat des blocages factures fournisseurs        -
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
INTO TABLE DKA_AP_REP_BLOCAGES_TMP
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(VENDOR_NUM                       "RTRIM(LTRIM(:VENDOR_NUM))"
,INVOICE_NUM                      ":INVOICE_NUM"
,HOLD_LOOKUP_CODE                 "RTRIM(LTRIM(:HOLD_LOOKUP_CODE))"
,HELD_BY                          "RTRIM(LTRIM(:HELD_BY))"
,HOLD_DATE                        DATE 'YYYY/MM/DD' NULLIF (HOLD_DATE =BLANKS)
,HOLD_REASON                      "RTRIM(LTRIM(:HOLD_REASON))"
,RELEASE_LOOKUP_CODE              "RTRIM(LTRIM(:RELEASE_LOOKUP_CODE))"
,RELEASE_REASON                   "RTRIM(LTRIM(:RELEASE_REASON))"
,CREATION_DATE                    DATE 'YYYY/MM/DD' NULLIF (CREATION_DATE =BLANKS)
,STATUS_FLAG                      "RTRIM(LTRIM(:STATUS_FLAG))"
,HOLD_REASON_REPRISE              "RTRIM(LTRIM(:HOLD_REASON_REPRISE))"
,LOGICAL_LINE_NUM                   RECNUM
,CREATION_DATE_R                      SYSDATE
,CREATED_BY                         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                   SYSDATE
,LAST_UPDATED_BY                    CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                    CONSTANT '!LOAD_REQUEST_ID!'
,PROCESSED_REQUEST_ID                 CONSTANT '-1'

)

