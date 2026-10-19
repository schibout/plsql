-------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IPOCDEIVALUA_LOADER_LINES.ctl
-- DESCRIPTION	    : Chargement de la table DKA_IPOCDE_LINES
--
-- AUTEUR           : A.AMENKOUR
-- DATE DE CREATION : 15/05/2020
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      :Fichier de controle sql*loader                       -
--                   pour le chargement de la table de travail
-------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--  
-------------------------------------------------------------------------------------------

OPTIONS (ERRORS=0,SKIP=1)
LOAD DATA
--CHARACTERSET UTF8
APPEND
INTO TABLE DKA_IPOCDE_LINES
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
PO_NUMBER	                     POSITION(1) "RTRIM(LTRIM(:PO_NUMBER))"   
,IVALUA_LINE_ID	                 "RTRIM(LTRIM(:IVALUA_LINE_ID))"
,IVALUA_LINE_TYPE	             "RTRIM(LTRIM(:IVALUA_LINE_TYPE))"     
,UPDATED	                     "RTRIM(LTRIM(:UPDATED))"     
,LINE_DESCRIPTION	             "RTRIM(LTRIM(:LINE_DESCRIPTION))"     
,UOM	                         "RTRIM(LTRIM(:UOM))"    
,QUANTITY	                     "REPLACE(:QUANTITY,',','.')" 
,PRICE	                         "REPLACE(:PRICE,',','.')"     
,DELIVERY_ADDRESS_NAME	         "RTRIM(LTRIM(:DELIVERY_ADDRESS_NAME))"     
,DELIVERY_DATE	                 DATE  'DD/MM/YYYY'   NULLIF (DELIVERY_DATE= BLANKS)     
,SUPPLIER_ITEM_REFERENCE          "RTRIM(LTRIM(:SUPPLIER_ITEM_REFERENCE))"    
,PRODUCT_CODE	                 "RTRIM(LTRIM(:PRODUCT_CODE))"    
,CATEGORY	                     "RTRIM(LTRIM(:CATEGORY))"    
,CATALOG_PURCHASE	             "RTRIM(LTRIM(:CATALOG_PURCHASE))"   
,FINANCIAL_TASK	                 "RTRIM(LTRIM(:FINANCIAL_TASK))"   
,EXPENSE_TYPE	                 "RTRIM(LTRIM(:EXPENSE_TYPE))"     
,REQ_LINE	                     "RTRIM(LTRIM(:REQ_LINE))"     
,REQ_DESCRIPTION	             "RTRIM(LTRIM(:REQ_DESCRIPTION))"     
,REQUESTER	                     "RTRIM(LTRIM(:REQUESTER))"    
,SITE_DK_CODE	                 "REPLACE(:SITE_DK_CODE,CHR(13),'')"  
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'       
,STATUT	                         CONSTANT "NEW"     
,FILE_NAME	                     CONSTANT '!FILE_NAME!'  
,LINE_NUM	                     RECNUM
,RECORD_ID	                     "DKA_IPOCDE_LINES_S.NEXTVAL"   
,LOADER_REQUEST_ID	             CONSTANT '!LOAD_REQUEST_ID!'             
)

INTO TABLE DKA_IPOCDE_HIST_LINES
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
PO_NUMBER	                     POSITION(1) "RTRIM(LTRIM(:PO_NUMBER))"   
,IVALUA_LINE_ID	                 "RTRIM(LTRIM(:IVALUA_LINE_ID))"
,IVALUA_LINE_TYPE	             "RTRIM(LTRIM(:IVALUA_LINE_TYPE))"     
,UPDATED	                     "RTRIM(LTRIM(:UPDATED))"     
,LINE_DESCRIPTION	             "RTRIM(LTRIM(:LINE_DESCRIPTION))"     
,UOM	                         "RTRIM(LTRIM(:UOM))"    
,QUANTITY	                     "REPLACE(:QUANTITY,',','.')" 
,PRICE	                         "REPLACE(:PRICE,',','.')"      
,DELIVERY_ADDRESS_NAME	         "RTRIM(LTRIM(:DELIVERY_ADDRESS_NAME))"     
,DELIVERY_DATE	                 DATE  'DD/MM/YYYY'   NULLIF (DELIVERY_DATE= BLANKS)     
,SUPPLIER_ITEM_REFERENCE          "RTRIM(LTRIM(:SUPPLIER_ITEM_REFERENCE))"    
,PRODUCT_CODE	                 "RTRIM(LTRIM(:PRODUCT_CODE))"    
,CATEGORY	                     "RTRIM(LTRIM(:CATEGORY))"    
,CATALOG_PURCHASE	             "RTRIM(LTRIM(:CATALOG_PURCHASE))"   
,FINANCIAL_TASK	                 "RTRIM(LTRIM(:FINANCIAL_TASK))"   
,EXPENSE_TYPE	                 "RTRIM(LTRIM(:EXPENSE_TYPE))"     
,REQ_LINE	                     "RTRIM(LTRIM(:REQ_LINE))"     
,REQ_DESCRIPTION	             "RTRIM(LTRIM(:REQ_DESCRIPTION))"     
,REQUESTER	                     "RTRIM(LTRIM(:REQUESTER))"    
,SITE_DK_CODE	                 "REPLACE(:SITE_DK_CODE,CHR(13),'')" 
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'       
,STATUT	                         CONSTANT "NEW"     
,FILE_NAME	                     CONSTANT '!FILE_NAME!'  
,LINE_NUM	                     RECNUM   
,LOADER_REQUEST_ID	             CONSTANT '!LOAD_REQUEST_ID!'              
)

INTO TABLE DKA_IPOCDE_REPORTING_LINES
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
PO_NUMBER	                     POSITION(1) "RTRIM(LTRIM(:PO_NUMBER))"   
,IVALUA_LINE_ID	                 "RTRIM(LTRIM(:IVALUA_LINE_ID))"
,IVALUA_LINE_TYPE	             "RTRIM(LTRIM(:IVALUA_LINE_TYPE))"     
,UPDATED	                     "RTRIM(LTRIM(:UPDATED))"     
,LINE_DESCRIPTION	             "RTRIM(LTRIM(:LINE_DESCRIPTION))"     
,UOM	                         "RTRIM(LTRIM(:UOM))"    
,QUANTITY	                     "REPLACE(:QUANTITY,',','.')" 
,PRICE	                         "REPLACE(:PRICE,',','.')"      
,DELIVERY_ADDRESS_NAME	         "RTRIM(LTRIM(:DELIVERY_ADDRESS_NAME))"     
,DELIVERY_DATE	                 DATE  'DD/MM/YYYY'   NULLIF (DELIVERY_DATE= BLANKS)     
,SUPPLIER_ITEM_REFERENCE          "RTRIM(LTRIM(:SUPPLIER_ITEM_REFERENCE))"    
,PRODUCT_CODE	                 "RTRIM(LTRIM(:PRODUCT_CODE))"    
,CATEGORY	                     "RTRIM(LTRIM(:CATEGORY))"    
,CATALOG_PURCHASE	             "RTRIM(LTRIM(:CATALOG_PURCHASE))"   
,FINANCIAL_TASK	                 "RTRIM(LTRIM(:FINANCIAL_TASK))"   
,EXPENSE_TYPE	                 "RTRIM(LTRIM(:EXPENSE_TYPE))"     
,REQ_LINE	                     "RTRIM(LTRIM(:REQ_LINE))"     
,REQ_DESCRIPTION	             "RTRIM(LTRIM(:REQ_DESCRIPTION))"     
,REQUESTER	                     "RTRIM(LTRIM(:REQUESTER))"    
,SITE_DK_CODE	                 "REPLACE(:SITE_DK_CODE,CHR(13),'')" 
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'       
,STATUT	                         CONSTANT "NEW"     
,FILE_NAME	                     CONSTANT '!FILE_NAME!'  
,LINE_NUM	                     RECNUM   
,LOADER_REQUEST_ID	             CONSTANT '!LOAD_REQUEST_ID!'              
)

--Fin