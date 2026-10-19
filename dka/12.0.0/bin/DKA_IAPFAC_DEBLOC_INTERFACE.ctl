-------------------------------------------------------------------------------
-- $Header$
-- FILE          :  DKA_IAPFAC_DEBLOC_INTERFACE.ctl V1.0.0.0 
-- DESCRIPTION   :  Ivalua reception des commandes 
--
-- AUTHOR        :  SEL
--
-- CREATION DATE :  27/05/2020
--
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             : 
-- Date                :
-- Author              :
-- Nature              :
--------------------------------------------------------------------------------

OPTIONS (SKIP=1) 
LOAD DATA
APPEND
INTO TABLE DKA_IAPFAC_DEBLOC_INTERFACE FIELDS TERMINATED BY '|'    TRAILING NULLCOLS(
INVOICE_ID	         CHAR   NULLIF (INVOICE_ID= BLANKS),
IVALUA_PO_LINE_ID    CHAR   NULLIF (IVALUA_PO_LINE_ID= BLANKS),
HOLD_ID	             CHAR   NULLIF (HOLD_ID= BLANKS),
HOLD_CODE	         CHAR   NULLIF (HOLD_CODE  = BLANKS),
RESPONSE_CODE        CHAR   NULLIF (RESPONSE_CODE= BLANKS),
RESPONSE_DATE        DATE   'DD/MM/YYYY HH24:MI:SS'  NULLIF (RESPONSE_DATE= BLANKS),
COMMENTAIRE          CHAR(2000)   NULLIF (COMMENTAIRE= BLANKS),
CREATION_DATE	     SYSDATE,
CREATED_BY	         CONSTANT '!USER_ID!' , 
LAST_UPDATE_DATE	 SYSDATE,
LAST_UPDATED_BY	     CONSTANT '!USER_ID!' , 
STATUT	             CONSTANT "NEW",
FILE_NAME	         CONSTANT '!FILE_NAME!',
LINE_NUM	         RECNUM,
RECORD_ID            "DKA_IAPFAC_DEBLOC_INTER_S.NEXTVAL",
REQUEST_ID	         CONSTANT '-1',
LOADER_REQUEST_ID	 CONSTANT '!LOAD_REQUEST_ID!'
)
