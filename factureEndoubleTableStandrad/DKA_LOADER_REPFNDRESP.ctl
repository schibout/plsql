-------------------------------------------------------------------------------
-- $Header$
-- FILE          :  DKA_RCV_HEADERS.ctl V1.0.0.0 
-- DESCRIPTION   :  reprise_entete_reception 
--
-- AUTHOR        :  R.AYMAZ
--
-- CREATION DATE :  28/03/2016
--
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             : 
-- Date                :
-- Author              :
-- Nature              :
--------------------------------------------------------------------------------

OPTIONS (SKIP=1 ) 
LOAD DATA
APPEND
INTO TABLE DKA_RCV_HEADERS_TMP FIELDS TERMINATED BY '|'    TRAILING NULLCOLS(
RECEIPT_NUM                       	INTEGER EXTERNAL NULLIF (RECEIPT_NUM= BLANKS)	  ,
SHIPMENT_NUM	                    INTEGER EXTERNAL NULLIF (SHIPMENT_NUM= BLANKS)	  ,
EXPECTED_RECEIPT_DATE	            DATE  'YYYY/MM/DD'   NULLIF (EXPECTED_RECEIPT_DATE= BLANKS),
VENDOR_NUM	                      	CHAR NULLIF (VENDOR_NUM= BLANKS),
VENDOR_SITE_CODE	                CHAR NULLIF (VENDOR_SITE_CODE= BLANKS),
EMPLOYEE_NAME	                    CHAR NULLIF (EMPLOYEE_NAME= BLANKS),
COMMENTS                          	CHAR NULLIF (COMMENTS= BLANKS),
BORDEREAU_NUM	                    CHAR NULLIF (BORDEREAU_NUM= BLANKS),
EXPEDITION_DATE	                  	DATE 'YYYY/MM/DD' NULLIF (EXPEDITION_DATE = BLANKS),
DOCUMENT_NUM	                    CHAR NULLIF (DOCUMENT_NUM= BLANKS),
SOCIETE								CHAR NULLIF (SOCIETE= BLANKS),
REGION								CHAR NULLIF (REGION= BLANKS),
FLAG                                CONSTANT '-1' ,  
CREATION_DATE                       SYSDATE ,
CREATED_BY                          CONSTANT '!USER_ID!' ,     
LAST_UPDATE_DATE                    SYSDATE  ,                 
LAST_UPDATED_BY                     CONSTANT '!USER_ID!' ,     
LOAD_REQUEST_ID                     CONSTANT '!LOAD_REQUEST_ID!' 
)
