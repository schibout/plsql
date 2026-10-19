----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPFCTIMP_LOADER                                  -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 14/04/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPAPFCTIMP_LOADER.prog                          -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise factures founisseurs                  		   -
--              Fichier plat des entete factures fournisseurs        -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.1                                        -
-- PROGRAMME MODIFIE LE : 26/10/2016                                 -
-- PAR                  : Maxime EGOT                                -
-- OBJET                : artf2034435                                -
--                                                                   -
----------------------------------------------------------------------
OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_AP_REP_ENTETE_FACTURE_TMP
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(INVOICE_NUM                          ":INVOICE_NUM"
,INVOICE_TYPE_LOOKUP_CODE             "RTRIM(LTRIM(:INVOICE_TYPE_LOOKUP_CODE))"
,INVOICE_DATE                         DATE 'YYYY/MM/DD' NULLIF (INVOICE_DATE =BLANKS)
,PO_NUMBER                            "RTRIM(LTRIM(:PO_NUMBER))"
,VENDOR_NUM                           "RTRIM(LTRIM(:VENDOR_NUM))"
,VENDOR_SITE_CODE                     "RTRIM(LTRIM(:VENDOR_SITE_CODE))"
,INVOICE_AMOUNT                       FLOAT EXTERNAL NULLIF (INVOICE_AMOUNT=BLANKS) "REPLACE(:INVOICE_AMOUNT,',','.')"
,INVOICE_CURRENCY_CODE                "RTRIM(LTRIM(:INVOICE_CURRENCY_CODE))"
,EXCHANGE_RATE                        FLOAT EXTERNAL NULLIF (EXCHANGE_RATE=BLANKS) "REPLACE(:EXCHANGE_RATE,',','.')"
,EXCHANGE_RATE_TYPE                   "RTRIM(LTRIM(:EXCHANGE_RATE_TYPE))"
,EXCHANGE_DATE                        DATE 'YYYY/MM/DD' NULLIF (EXCHANGE_DATE =BLANKS)
,TERMS_NAME                           "RTRIM(LTRIM(:TERMS_NAME))"
,DESCRIPTION                          "RTRIM(LTRIM(:DESCRIPTION))"
,AWT_GROUP_NAME                       "RTRIM(LTRIM(:AWT_GROUP_NAME))"
,ATTRIBUTE_CATEGORY                   "RTRIM(LTRIM(:ATTRIBUTE_CATEGORY))"
,ATTRIBUTE1                           "RTRIM(LTRIM(:ATTRIBUTE1))"
,ATTRIBUTE2                           "RTRIM(LTRIM(:ATTRIBUTE2))"
,ATTRIBUTE3                           "RTRIM(LTRIM(:ATTRIBUTE3))"
,ATTRIBUTE4                           "RTRIM(LTRIM(:ATTRIBUTE4))"
,ATTRIBUTE5                           "RTRIM(LTRIM(:ATTRIBUTE5))"
,ATTRIBUTE6                           "RTRIM(LTRIM(:ATTRIBUTE6))"
,ATTRIBUTE7                           "RTRIM(LTRIM(:ATTRIBUTE7))"
,ATTRIBUTE8                           "RTRIM(LTRIM(:ATTRIBUTE8))"
,ATTRIBUTE9                           "RTRIM(LTRIM(:ATTRIBUTE9))"
,ATTRIBUTE10                          "RTRIM(LTRIM(:ATTRIBUTE10))"
,ATTRIBUTE11                          "RTRIM(LTRIM(:ATTRIBUTE11))"
,ATTRIBUTE12                          "RTRIM(LTRIM(:ATTRIBUTE12))"
,ATTRIBUTE13                          "RTRIM(LTRIM(:ATTRIBUTE13))"
,ATTRIBUTE14                          "RTRIM(LTRIM(:ATTRIBUTE14))"
,ATTRIBUTE15                          "RTRIM(LTRIM(:ATTRIBUTE15))"
,SOURCE                               "RTRIM(LTRIM(:SOURCE))"
,DOC_CATEGORY_CODE                    "RTRIM(LTRIM(:DOC_CATEGORY_CODE))"
,VOUCHER_NUM                          "RTRIM(LTRIM(:VOUCHER_NUM))"
,PAYMENT_METHOD_LOOOKUP_CODE          "RTRIM(LTRIM(:PAYMENT_METHOD_LOOOKUP_CODE))"
,PAY_GROUP_LOOKUP_CODE                "RTRIM(LTRIM(:PAY_GROUP_LOOKUP_CODE))"
,GOODS_RECEIVED_DATE                  DATE 'YYYY/MM/DD' NULLIF (GOODS_RECEIVED_DATE =BLANKS)
,INVOICE_RECEIVED_DATE                DATE 'YYYY/MM/DD' NULLIF (INVOICE_RECEIVED_DATE =BLANKS)
,GL_DATE                              DATE 'YYYY/MM/DD' NULLIF (GL_DATE =BLANKS)
,ACCTS_PAY_CODE_COMBINATION_1         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_1))"
,ACCTS_PAY_CODE_COMBINATION_2         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_2))"
,ACCTS_PAY_CODE_COMBINATION_3         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_3))"
,ACCTS_PAY_CODE_COMBINATION_4         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_4))"
,ACCTS_PAY_CODE_COMBINATION_5         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_5))"
,ACCTS_PAY_CODE_COMBINATION_6         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_6))"
,ACCTS_PAY_CODE_COMBINATION_7         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_7))"
,ACCTS_PAY_CODE_COMBINATION_8         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_8))"
,ACCTS_PAY_CODE_COMBINATION_9         "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_9))"
,ACCTS_PAY_CODE_COMBINATION_10        "RTRIM(LTRIM(:ACCTS_PAY_CODE_COMBINATION_10))"
,AMOUNT_APPLICABLE_TO_DISCOUNT        FLOAT EXTERNAL NULLIF (AMOUNT_APPLICABLE_TO_DISCOUNT=BLANKS) "REPLACE(:AMOUNT_APPLICABLE_TO_DISCOUNT,',','.')"
,TERMS_DATE                           DATE 'YYYY/MM/DD' NULLIF (TERMS_DATE =BLANKS)
,PAYMENT_PRIORITY                     FLOAT EXTERNAL NULLIF (PAYMENT_PRIORITY=BLANKS) "REPLACE(:PAYMENT_PRIORITY,',','.')"
,REMIT_TO_SUPPLIER_NAME               "RTRIM(LTRIM(:REMIT_TO_SUPPLIER_NAME))"
,REMIT_TO_SUPPLIER_SITE               "RTRIM(LTRIM(:REMIT_TO_SUPPLIER_SITE))"
,REMIT_TO_SUPPLIER_NUM                "RTRIM(LTRIM(:REMIT_TO_SUPPLIER_NUM))"
,BANK_NAME                            "RTRIM(LTRIM(:BANK_NAME))"
,BANK_BRANCH_NAME                     "RTRIM(LTRIM(:BANK_BRANCH_NAME))"
,BANK_ACCOUNT_NAME                    "RTRIM(LTRIM(:BANK_ACCOUNT_NAME))"
,BANK_ACCOUNT_NUM                     "RTRIM(LTRIM(:BANK_ACCOUNT_NUM))"
,MONTANT_INITAL                       FLOAT EXTERNAL NULLIF (MONTANT_INITAL=BLANKS) "REPLACE(:MONTANT_INITAL,',','.')"
,TAX_AMOUNT                           FLOAT EXTERNAL NULLIF (TAX_AMOUNT=BLANKS) "REPLACE(:TAX_AMOUNT,',','.')"
,PAYMENT_CURRENCY_CODE                "RTRIM(LTRIM(:PAYMENT_CURRENCY_CODE))"
,LOGICAL_LINE_NUM                     RECNUM
,CREATION_DATE                        SYSDATE
,CREATED_BY                           CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                     SYSDATE
,LAST_UPDATED_BY                      CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                      CONSTANT '!LOAD_REQUEST_ID!'
,PROCESSED_REQUEST_ID                 CONSTANT '-1'
,BANK_NUMBER                          "RTRIM(LTRIM(:BANK_NUMBER))"
,BANK_NUM                             "RTRIM(LTRIM(:BANK_NUM))"
,PERIOD_GL                            "RTRIM(LTRIM(:PERIOD_GL))"
,HOLD_FLAG                            "RTRIM(LTRIM(:HOLD_FLAG))"
)
