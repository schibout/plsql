--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_REPPOCMDIMP.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire PO_HEADERS_TMP
--
-- USAGE
--   DKA_REPPOCMDIMP.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    22/03/2016     OBE Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
--CHARACTERSET UTF8
APPEND
INTO TABLE PO_HEADERS_TMP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
DOCUMENT_NUM                    CHAR NULLIF (DOCUMENT_NUM= BLANKS)
,TYPE_LOOKUP_CODE                CHAR NULLIF (TYPE_LOOKUP_CODE= BLANKS)
,CURRENCY_CODE                   CHAR NULLIF (CURRENCY_CODE= BLANKS)
,AGENT_NAME                      CHAR NULLIF (AGENT_NAME= BLANKS)
,VENDOR_NAME                     CHAR NULLIF (VENDOR_NAME= BLANKS)
,VENDOR_SITE_CODE                CHAR NULLIF (VENDOR_SITE_CODE= BLANKS)
,VENDOR_CONTACT                  CHAR NULLIF (VENDOR_CONTACT= BLANKS)
,SHIP_TO_LOCATION                CHAR NULLIF (SHIP_TO_LOCATION= BLANKS)
,BILL_TO_LOCATION                CHAR NULLIF (BILL_TO_LOCATION= BLANKS)
,COMMENTS                        CHAR NULLIF (COMMENTS= BLANKS)
,SOCIETE                         CHAR NULLIF (SOCIETE= BLANKS)
,REGION                          CHAR NULLIF (REGION= BLANKS)
,PAYMENT_TERMS                   CHAR NULLIF (PAYMENT_TERMS= BLANKS)
,APPROVAL_STATUS                 CHAR NULLIF (APPROVAL_STATUS= BLANKS)
,APPROVAL_DATE                   DATE  'YYYY/MM/DD'   NULLIF (APPROVAL_DATE =BLANKS)
,REVISION_NUM                    INTEGER EXTERNAL NULLIF (REVISION_NUM= BLANKS)
,NOTE_TO_VENDOR                  CHAR NULLIF (NOTE_TO_VENDOR= BLANKS)
,NOTE_TO_RECEIVER                CHAR NULLIF (NOTE_TO_RECEIVER= BLANKS)
,ATTRIBUTE_CATEGORY              CHAR NULLIF (ATTRIBUTE_CATEGORY= BLANKS)
,ATTRIBUTE1                      CHAR NULLIF (ATTRIBUTE1= BLANKS)
,ATTRIBUTE2                      CHAR NULLIF (ATTRIBUTE2= BLANKS)
,ATTRIBUTE6                      CHAR NULLIF (ATTRIBUTE6= BLANKS)
,ATTRIBUTE8                      CHAR NULLIF (ATTRIBUTE8= BLANKS)
,ATTRIBUTE12                     CHAR NULLIF (ATTRIBUTE12= BLANKS)
,ATTRIBUTE13                     CHAR NULLIF (ATTRIBUTE13= BLANKS)
,ATTRIBUTE14                     CHAR NULLIF (ATTRIBUTE14= BLANKS)
,AMOUNT_INIT                     FLOAT EXTERNAL NULLIF (AMOUNT_INIT= BLANKS)
,LOGICAL_LINE_NUM                RECNUM
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                 CONSTANT '!LOAD_REQUEST_ID!'
)

--Fin