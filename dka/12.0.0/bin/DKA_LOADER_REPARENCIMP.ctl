--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_LOADER_REPARENCIMP.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_AR_RECEIPTS_TMP
--
-- USAGE
--   DKA_LOADER_REPARENCIMP.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    26/04/2016     OBE Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_AR_RECEIPTS_TMP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
RECEIPT_NUMBER                  CHAR NULLIF (RECEIPT_NUMBER= BLANKS)
,CURRENCY_CODE                   CHAR NULLIF (CURRENCY_CODE= BLANKS)
,EXCHANGE_RATE_TYPE              CHAR NULLIF (EXCHANGE_RATE_TYPE= BLANKS)
,EXCHANGE_RATE                   CHAR NULLIF (EXCHANGE_RATE= BLANKS)
,EXCHANGE_DATE                   DATE  'YYYY/MM/DD' NULLIF (EXCHANGE_DATE= BLANKS)
,AMOUNT_NON_APPLIED              FLOAT EXTERNAL NULLIF (AMOUNT_NON_APPLIED= BLANKS) "REPLACE(:AMOUNT_NON_APPLIED,',','.')"
,RECEIPT_DATE                    DATE  'YYYY/MM/DD' NULLIF (RECEIPT_DATE= BLANKS)
,DUE_DATE                        DATE  'YYYY/MM/DD' NULLIF (DUE_DATE= BLANKS)
,GL_DATE                         DATE  'YYYY/MM/DD' NULLIF (GL_DATE= BLANKS)
,CUSTOMER_NAME                   CHAR NULLIF (CUSTOMER_NAME= BLANKS)
,CUSTOMER_NUMBER                 CHAR NULLIF (CUSTOMER_NUMBER= BLANKS)
,AMOUNT_ON_ACCOUNT               FLOAT EXTERNAL NULLIF (AMOUNT_ON_ACCOUNT= BLANKS) "REPLACE(:AMOUNT_ON_ACCOUNT,',','.')"
,RECEIPT_METHOD                  CHAR NULLIF (RECEIPT_METHOD= BLANKS)
,RECEIPT_AMOUNT                  FLOAT EXTERNAL NULLIF (RECEIPT_AMOUNT= BLANKS) "REPLACE(:RECEIPT_AMOUNT,',','.')"
,OPERATING_UNIT                  CHAR NULLIF (OPERATING_UNIT= BLANKS)
,COMMENTS                        CHAR NULLIF (COMMENTS= BLANKS)
,LOGICAL_LINE_NUM                RECNUM
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                 CONSTANT '!LOAD_REQUEST_ID!'
)

--Fin