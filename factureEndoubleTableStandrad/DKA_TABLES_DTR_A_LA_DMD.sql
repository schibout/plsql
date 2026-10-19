----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPFCTIMP_LOADER                                        -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 14/04/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPAPFCTIMP_LOADER.prog                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise lignes factures founisseurs                  		 -
--              Fichier plat des lignes factures fournisseurs        -
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
INTO TABLE DKA_AP_REP_LIGNES_FACTURE_TMP
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(VENDOR_NUM                          "RTRIM(LTRIM(:VENDOR_NUM))"
,INVOICE_NUM                         ":INVOICE_NUM"
,LINE_NUMBER                         "RTRIM(LTRIM(:LINE_NUMBER))"
,ACCOUNTING_DATE                     DATE 'YYYY/MM/DD' NULLIF (ACCOUNTING_DATE =BLANKS)
,AMOUNT                              FLOAT EXTERNAL NULLIF (AMOUNT=BLANKS) "REPLACE(:AMOUNT,',','.')"
,ASSETS_TRACKING_FLAG                "RTRIM(LTRIM(:ASSETS_TRACKING_FLAG))"
,ATTRIBUTE_CATEGORY                  "RTRIM(LTRIM(:ATTRIBUTE_CATEGORY))"
,ATTRIBUTE1                          "RTRIM(LTRIM(:ATTRIBUTE1))"
,ATTRIBUTE2                          "RTRIM(LTRIM(:ATTRIBUTE2))"
,ATTRIBUTE3                          "RTRIM(LTRIM(:ATTRIBUTE3))"
,ATTRIBUTE4                          "RTRIM(LTRIM(:ATTRIBUTE4))"
,ATTRIBUTE5                          "RTRIM(LTRIM(:ATTRIBUTE5))"
,ATTRIBUTE6                          "RTRIM(LTRIM(:ATTRIBUTE6))"
,ATTRIBUTE7                          "RTRIM(LTRIM(:ATTRIBUTE7))"
,ATTRIBUTE8                          "RTRIM(LTRIM(:ATTRIBUTE8))"
,ATTRIBUTE9                          "RTRIM(LTRIM(:ATTRIBUTE9))"
,ATTRIBUTE10                         "RTRIM(LTRIM(:ATTRIBUTE10))"
,ATTRIBUTE11                         "RTRIM(LTRIM(:ATTRIBUTE11))"
,ATTRIBUTE12                         "RTRIM(LTRIM(:ATTRIBUTE12))"
,ATTRIBUTE13                         "RTRIM(LTRIM(:ATTRIBUTE13))"
,ATTRIBUTE14                         "RTRIM(LTRIM(:ATTRIBUTE14))"
,ATTRIBUTE15                         "RTRIM(LTRIM(:ATTRIBUTE15))"
,DESCRIPTION                         "RTRIM(LTRIM(:DESCRIPTION))"
,DISTRIBUTION_SET_NAME               "RTRIM(LTRIM(:DISTRIBUTION_SET_NAME))"
,DIST_CODE_COMBINATION_1             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_1))"
,DIST_CODE_COMBINATION_2             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_2))"
,DIST_CODE_COMBINATION_3             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_3))"
,DIST_CODE_COMBINATION_4             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_4))"
,DIST_CODE_COMBINATION_5             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_5))"
,DIST_CODE_COMBINATION_6             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_6))"
,DIST_CODE_COMBINATION_7             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_7))"
,DIST_CODE_COMBINATION_8             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_8))"
,DIST_CODE_COMBINATION_9             "RTRIM(LTRIM(:DIST_CODE_COMBINATION_9))"
,DIST_CODE_COMBINATION_10            "RTRIM(LTRIM(:DIST_CODE_COMBINATION_10))"
,LINE_GROUP_NUMBER					 FLOAT EXTERNAL NULLIF (LINE_GROUP_NUMBER=BLANKS) "REPLACE(:LINE_GROUP_NUMBER,',','.')"
,EXPENDITURE_TYPE 					 "RTRIM(LTRIM(:EXPENDITURE_TYPE))"
,LINE_TYPE_LOOKUP_CODE               "RTRIM(LTRIM(:LINE_TYPE_LOOKUP_CODE))"
,PO_DISTRIBUTION_NUM                 "RTRIM(LTRIM(:PO_DISTRIBUTION_NUM))"
,PO_LINE_NUMBER                      "RTRIM(LTRIM(:PO_LINE_NUMBER))"
,PO_NUMBER                           "RTRIM(LTRIM(:PO_NUMBER))"
,PO_SHIPMENT_NUM                     "RTRIM(LTRIM(:PO_SHIPMENT_NUM))"
,PURCHASING_CATEGORY                 "RTRIM(LTRIM(:PURCHASING_CATEGORY))"
,QUANTITY_INVOICED                   FLOAT EXTERNAL NULLIF (QUANTITY_INVOICED=BLANKS) "REPLACE(:QUANTITY_INVOICED,',','.')"
,RECEIPT_LINE_NUMBER                 "RTRIM(LTRIM(:RECEIPT_LINE_NUMBER))"
,RECEIPT_NUMBER                      "RTRIM(LTRIM(:RECEIPT_NUMBER))"
,SHIP_TO_LOCATION_CODE               "RTRIM(LTRIM(:SHIP_TO_LOCATION_CODE))"
,CODE_TVA                            "RTRIM(LTRIM(:CODE_TVA))"
,TAX_TYPE 							 "RTRIM(LTRIM(:TAX_TYPE))"
,UNIT_PRICE                          FLOAT EXTERNAL NULLIF (UNIT_PRICE=BLANKS) "REPLACE(:UNIT_PRICE,',','.')"
,CODE_DAS2                           "RTRIM(LTRIM(:CODE_DAS2))"
,AWT_GROUP_NAME                      "RTRIM(LTRIM(:AWT_GROUP_NAME))"
,LOGICAL_LINE_NUM                   RECNUM
,CREATION_DATE                      SYSDATE
,CREATED_BY                         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                   SYSDATE
,LAST_UPDATED_BY                    CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                    CONSTANT '!LOAD_REQUEST_ID!'
,PROCESSED_REQUEST_ID               CONSTANT '-1'

)

