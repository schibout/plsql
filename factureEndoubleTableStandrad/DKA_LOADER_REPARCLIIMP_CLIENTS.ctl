----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPFRSIMP                                        -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 16/03/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPAPFRSIMP.prog                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise founisseur                                   -
--              Fichier plat des fournisseurs                       -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.0                                        -
-- PROGRAMME MODIFIE LE :                                            -
-- PAR                  :                                            -
-- OBJET                :                                            -
--                                                                   -
----------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------
-- 07/09/2017 RBE EDB071
------------------------------------------------------------------------------------
OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_AP_REP_SUPP_TMP
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(VENDOR_NAME                       "RTRIM(LTRIM(:VENDOR_NAME))"
,VENDOR_NAME_ALT                   "RTRIM(LTRIM(:VENDOR_NAME_ALT))"
,SEGMENT1                          "RTRIM(LTRIM(:SEGMENT1))"
,VENDOR_TYPE_LOOKUP_CODE           "RTRIM(LTRIM(:VENDOR_TYPE_LOOKUP_CODE))"
,SHIP_TO_LOCATION_CODE             "RTRIM(LTRIM(:SHIP_TO_LOCATION_CODE))"
,BILL_TO_LOCATION_CODE             "RTRIM(LTRIM(:BILL_TO_LOCATION_CODE))"
,FREIGHT_TERMS_LOOKUP_CODE         "RTRIM(LTRIM(:FREIGHT_TERMS_LOOKUP_CODE))"
,FOB_LOOKUP_CODE                   "RTRIM(LTRIM(:FOB_LOOKUP_CODE))"
,TERMS_NAME                        "RTRIM(LTRIM(:TERMS_NAME))"
,PAY_DATE_BASIS_LOOKUP_CODE        "RTRIM(LTRIM(:PAY_DATE_BASIS_LOOKUP_CODE))"
,PAY_GROUP_LOOKUP_CODE             "RTRIM(LTRIM(:PAY_GROUP_LOOKUP_CODE))"
,PAYMENT_PRIORITY                   FLOAT EXTERNAL NULLIF (PAYMENT_PRIORITY=BLANKS) "REPLACE(:PAYMENT_PRIORITY,',','.')"
,INVOICE_CURRENCY_CODE             "RTRIM(LTRIM(:INVOICE_CURRENCY_CODE))"
,PAYMENT_CURRENCY_CODE             "RTRIM(LTRIM(:PAYMENT_CURRENCY_CODE))"
,INVOICE_AMOUNT_LIMIT              FLOAT EXTERNAL NULLIF (INVOICE_AMOUNT_LIMIT=BLANKS) "REPLACE(:INVOICE_AMOUNT_LIMIT,',','.')"
,HOLD_ALL_PAYMENTS_FLAG            "RTRIM(LTRIM(:HOLD_ALL_PAYMENTS_FLAG))"
,HOLD_FUTURE_PAYMENTS_FLAG         "RTRIM(LTRIM(:HOLD_FUTURE_PAYMENTS_FLAG))"
,HOLD_REASON                       "RTRIM(LTRIM(:HOLD_REASON))"
,DISTRIBUTION_SET_NAME             "RTRIM(LTRIM(:DISTRIBUTION_SET_NAME))"
,NUM_1099                          "RTRIM(LTRIM(:NUM_1099))"
,TYPE_1099                         "RTRIM(LTRIM(:TYPE_1099))"
,ORGANIZATION_TYPE_LOOKUP_CODE     "RTRIM(LTRIM(:ORGANIZATION_TYPE_LOOKUP_CODE))"
,VAT_CODE                          "RTRIM(LTRIM(:VAT_CODE))"
,WOMEN_OWNED_FLAG                  "RTRIM(LTRIM(:WOMEN_OWNED_FLAG))"
,SMALL_BUSINESS_FLAG               "RTRIM(LTRIM(:SMALL_BUSINESS_FLAG))"
,STANDARD_INDUSTRY_CLASS           "RTRIM(LTRIM(:STANDARD_INDUSTRY_CLASS))"
,HOLD_FLAG                         "RTRIM(LTRIM(:HOLD_FLAG))"
,PURCHASING_HOLD_REASON            "RTRIM(LTRIM(:PURCHASING_HOLD_REASON))"
,HOLD_DATE                          DATE 'YYYY/MM/DD' NULLIF (HOLD_DATE =BLANKS)
,TERMS_DATE_BASIS                  "RTRIM(LTRIM(:TERMS_DATE_BASIS))"
,RECEIPT_REQUIRED_FLAG             "RTRIM(LTRIM(:RECEIPT_REQUIRED_FLAG))"
,ENFORCE_SHIP_TO_LOCATION_CODE     "RTRIM(LTRIM(:ENFORCE_SHIP_TO_LOCATION_CODE))"
,DAYS_EARLY_RECEIPT_ALLOWED        FLOAT EXTERNAL NULLIF (DAYS_EARLY_RECEIPT_ALLOWED=BLANKS) "REPLACE(:DAYS_EARLY_RECEIPT_ALLOWED,',','.')"
,DAYS_LATE_RECEIPT_ALLOWED         FLOAT EXTERNAL NULLIF (DAYS_LATE_RECEIPT_ALLOWED=BLANKS) "REPLACE(:DAYS_LATE_RECEIPT_ALLOWED,',','.')"
,ALLOW_SUBSTITUTE_RECEIPTS_FLAG    "RTRIM(LTRIM(:ALLOW_SUBSTITUTE_RECEIPTS_FLAG))"
,HOLD_UNMATCHED_INVOICES_FLAG      "RTRIM(LTRIM(:HOLD_UNMATCHED_INVOICES_FLAG))"
,EXCLUSIVE_PAYMENT_FLAG            "RTRIM(LTRIM(:EXCLUSIVE_PAYMENT_FLAG))"
,ALLOW_UNORDERED_RECEIPTS_FLAG     "RTRIM(LTRIM(:ALLOW_UNORDERED_RECEIPTS_FLAG))"
,AUTO_TAX_CALC_FLAG                "RTRIM(LTRIM(:AUTO_TAX_CALC_FLAG))"
,AUTO_TAX_CALC_OVERRIDE            "RTRIM(LTRIM(:AUTO_TAX_CALC_OVERRIDE))"
,STATE_REPORTABLE_FLAG             "RTRIM(LTRIM(:STATE_REPORTABLE_FLAG))"
,FEDERAL_REPORTABLE_FLAG           "RTRIM(LTRIM(:FEDERAL_REPORTABLE_FLAG))"
,ATTRIBUTE_CATEGORY                "RTRIM(LTRIM(:ATTRIBUTE_CATEGORY))"
,ATTRIBUTE1                        "RTRIM(LTRIM(:ATTRIBUTE1))"
,ATTRIBUTE2                        "RTRIM(LTRIM(:ATTRIBUTE2))"
,ATTRIBUTE3                        "RTRIM(LTRIM(:ATTRIBUTE3))"
,ATTRIBUTE4                        "RTRIM(LTRIM(:ATTRIBUTE4))"
,ATTRIBUTE5                        "RTRIM(LTRIM(:ATTRIBUTE5))"
,ATTRIBUTE6                        "RTRIM(LTRIM(:ATTRIBUTE6))"
,ATTRIBUTE7                        "RTRIM(LTRIM(:ATTRIBUTE7))"
,ATTRIBUTE8                        "RTRIM(LTRIM(:ATTRIBUTE8))"
,ATTRIBUTE9                        "RTRIM(LTRIM(:ATTRIBUTE9))"
,ATTRIBUTE10                       "RTRIM(LTRIM(:ATTRIBUTE10))"
,ATTRIBUTE11                       "RTRIM(LTRIM(:ATTRIBUTE11))"
,ATTRIBUTE12                       "RTRIM(LTRIM(:ATTRIBUTE12))"
,ATTRIBUTE13                       "RTRIM(LTRIM(:ATTRIBUTE13))"
,ATTRIBUTE14                       "RTRIM(LTRIM(:ATTRIBUTE14))"
,ATTRIBUTE15                       "RTRIM(LTRIM(:ATTRIBUTE15))"
,VAT_REGISTRATION_NUM              "RTRIM(LTRIM(:VAT_REGISTRATION_NUM))"
,AUTO_CALCULATE_INTEREST_FLAG      "RTRIM(LTRIM(:AUTO_CALCULATE_INTEREST_FLAG))"
,EXCLUDE_FREIGHT_FROM_DISCOUNT     "RTRIM(LTRIM(:EXCLUDE_FREIGHT_FROM_DISCOUNT))"
,TAX_REPORTING_NAME                "RTRIM(LTRIM(:TAX_REPORTING_NAME))"
,ALLOW_AWT_FLAG                    "RTRIM(LTRIM(:ALLOW_AWT_FLAG))"
,AWT_GROUP_NAME                    "RTRIM(LTRIM(:AWT_GROUP_NAME))"
,MATCH_OPTION                      "RTRIM(LTRIM(:MATCH_OPTION))"
,OFFSET_TAX_FLAG                   "RTRIM(LTRIM(:OFFSET_TAX_FLAG))"
,MINORITY_GROUP_LOOKUP_CODE        "RTRIM(LTRIM(:MINORITY_GROUP_LOOKUP_CODE))"
,ONE_TIME_FLAG                     "RTRIM(LTRIM(:ONE_TIME_FLAG))"              
,PAYMENT_METHOD_LOOKUP_CODE        "RTRIM(LTRIM(:PAYMENT_METHOD_LOOKUP_CODE))" 
,QTY_RCV_TOLERANCE                 FLOAT EXTERNAL NULLIF (QTY_RCV_TOLERANCE=BLANKS) "REPLACE(:QTY_RCV_TOLERANCE,',','.')"         
,QTY_RCV_EXCEPTION_CODE            "RTRIM(LTRIM(:QTY_RCV_EXCEPTION_CODE))"     
,RECEIPT_DAYS_EXCEPTION_CODE       "RTRIM(LTRIM(:RECEIPT_DAYS_EXCEPTION_CODE))"
,SOCIETE_MERE                      "RTRIM(LTRIM(:SOCIETE_MERE))"
,LOGICAL_LINE_NUM                   SEQUENCE(MAX,1)
,CREATION_DATE                      SYSDATE
,CREATED_BY                         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                   SYSDATE
,LAST_UPDATED_BY                    CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                    CONSTANT '!LOAD_REQUEST_ID!'
,PROCESSED_REQUEST_ID                 CONSTANT '-1'

)

