-------------------------------------------------------------------------------
-- $Header$

-- FILE          :  DKA_RCV_TRANSACTIONS.ctl V1.0.0.0 
-- DESCRIPTION   :  reprise_ligne_receptions  
--
-- AUTHOR        :  R.AYMAZ
--
-- CREATION DATE :  28/03/2016
--
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             : 
-- DATE "YYYY/MM/DD", "YYYY/MM/DD",               :
-- Author              :
-- Nature              :
--------------------------------------------------------------------------------
OPTIONS (SKIP=1) 
LOAD DATA
APPEND
INTO TABLE DKA_RCV_TRANSACTIONS_TMP 
FIELDS TERMINATED BY '|'    
TRAILING NULLCOLS(
     TRANSACTION_TYPE	                CHAR NULLIF (TRANSACTION_TYPE= BLANKS),
     RECEIPT_NUM	                    INTEGER EXTERNAL NULLIF (RECEIPT_NUM= BLANKS),
     TRANSACTION_DATE	                DATE 'YYYY/MM/DD' NULLIF (TRANSACTION_DATE = BLANKS),
     QUANTITY	                        FLOAT EXTERNAL NULLIF (QUANTITY=BLANKS) "REPLACE(:QUANTITY,',','.')" ,
     UNIT_OF_MESURE	                  CHAR NULLIF (UNIT_OF_MESURE= BLANKS),
     CATEGORY_SEG2	                  CHAR NULLIF (CATEGORY_SEG2= BLANKS),
     CATEGORY_SEG3	                  CHAR NULLIF (CATEGORY_SEG3= BLANKS),
     CATEGORY_SEG4	                  CHAR NULLIF (CATEGORY_SEG4= BLANKS),
     CATEGORY_SEG5	                  CHAR NULLIF (CATEGORY_SEG5= BLANKS),
     VENDOR_NUM	                      CHAR NULLIF (VENDOR_NUM= BLANKS),
     VENDOR_SITE_CODE	                CHAR NULLIF (VENDOR_SITE_CODE= BLANKS),
     SHIP_TO_LOCATION	                CHAR NULLIF (SHIP_TO_LOCATION= BLANKS),
     PO_NUM	                          CHAR NULLIF (PO_NUM= BLANKS),
     PO_LINE_NUM                      INTEGER EXTERNAL NULLIF (PO_LINE_NUM= BLANKS),
     PO_SHIP_LINE_NUM	                INTEGER EXTERNAL NULLIF (PO_SHIP_LINE_NUM= BLANKS),
     PO_DIST_NUM	                    INTEGER EXTERNAL NULLIF (PO_DIST_NUM= BLANKS),
     DELIVER_TO_PERSON	              CHAR NULLIF (DELIVER_TO_PERSON= BLANKS),
     DELIVER_TO_LOCATION	            CHAR NULLIF (DELIVER_TO_LOCATION= BLANKS),
     EMPLOYEE_NAME                    CHAR NULLIF (EMPLOYEE_NAME= BLANKS),
     ITEM_DESCRIPTION                 CHAR NULLIF (ITEM_DESCRIPTION= BLANKS),
     UOM_CODE                         CHAR NULLIF (UOM_CODE= BLANKS),
     PRIMARY_QTY	                    FLOAT EXTERNAL NULLIF (PRIMARY_QTY=BLANKS) "REPLACE(:PRIMARY_QTY,',','.')" ,
     PRIMARY_UOM                      CHAR NULLIF (PRIMARY_UOM= BLANKS),
     PO_UNIT_PRICE                    FLOAT EXTERNAL NULLIF (PO_UNIT_PRICE=BLANKS) "REPLACE(:PO_UNIT_PRICE,',','.')",
     CURRENCY_CODE	                  CHAR NULLIF (CURRENCY_CODE= BLANKS),
     CURR_CONV_RATE	                  INTEGER EXTERNAL NULLIF (CURR_CONV_RATE= BLANKS),
     CURR_CONV_DATE                   DATE 'YYYY/MM/DD' NULLIF (CURR_CONV_DATE= BLANKS),
     INSPECTION	                      CHAR NULLIF (INSPECTION= BLANKS),
     DEST_TYPE_CODE	                  CHAR NULLIF (DEST_TYPE_CODE= BLANKS),
     VENDOR_ITEM_NUM	                CHAR NULLIF (VENDOR_ITEM_NUM= BLANKS),
     LOCATION_CODE	                  CHAR NULLIF (LOCATION_CODE= BLANKS),
     COMMENTS	                        CHAR NULLIF (COMMENTS= BLANKS),
     DESTINATION_CONTEXT              CHAR NULLIF (DESTINATION_CONTEXT= BLANKS),
     --QUANTITY_SHIPPED	                FLOAT EXTERNAL NULLIF (QUANTITY_SHIPPED=BLANKS) "REPLACE(:QUANTITY_SHIPPED,',','.')" ,
     TRANSACTION_ID                   INTEGER EXTERNAL NULLIF (TRANSACTION_ID= BLANKS),
     INTERFACE_TRANSACTION_ID         CONSTANT '-1',
     PARENT_TRANSACTION_ID            INTEGER EXTERNAL NULLIF (PARENT_TRANSACTION_ID= BLANKS),
	 SOCIETE						  CHAR NULLIF (SOCIETE= BLANKS),
     REGION							  CHAR NULLIF (REGION= BLANKS),
     FLAG                             CONSTANT '-1' , 
     CREATION_DATE                    SYSDATE ,
     CREATED_BY                       CONSTANT '!USER_ID!' ,     
     LAST_UPDATE_DATE                 SYSDATE  ,                 
     LAST_UPDATED_BY                  CONSTANT '!USER_ID!' ,     
     LOAD_REQUEST_ID                  CONSTANT '!LOAD_REQUEST_ID!' 
)
