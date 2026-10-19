-------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IPOCDEIVALUA_LOADER_HEAD.ctl
-- DESCRIPTION	    : Chargement de la table DKA_IPOCDE_HEADERS
--
-- AUTEUR           : A.AMENKOUR
-- DATE DE CREATION : /05/2020
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
INTO TABLE DKA_IPOCDE_HEADERS
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
UO	                             POSITION(1) "RTRIM(LTRIM(:UO))"
,PO_NUMBER	                     "RTRIM(LTRIM(:PO_NUMBER))"
,AMENDMENT_NUMBER	             "RTRIM(LTRIM(:AMENDMENT_NUMBER))"
,PO_STATUS	                      "RTRIM(LTRIM(:PO_STATUS))"
,SUPPLIER_NUMBER	              "RTRIM(LTRIM(:SUPPLIER_NUMBER))"
,SITE_SUPPLIER_NAME	             "RTRIM(LTRIM(:SITE_SUPPLIER_NAME))"
,IVALUA_SITE_SUPPLIER_ID         "RTRIM(LTRIM(:IVALUA_SITE_SUPPLIER_ID))"
,CURRENCY	                     "RTRIM(LTRIM(:CURRENCY))"
,DESCRIPTION	                 "RTRIM(LTRIM(:DESCRIPTION))"     
,AGENT_NUMBER	                 "RTRIM(LTRIM(:AGENT_NUMBER))"    
,URL_BDC	                     "RTRIM(LTRIM(:URL_BDC))"    
,PO_CREATION_DATE	             DATE  'DD/MM/YYYY HH24:MI:SS'   NULLIF (PO_CREATION_DATE= BLANKS)   
,DIRECT_PAYMENT	                 "REPLACE(:DIRECT_PAYMENT,CHR(13),'')"      
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'     
,STATUT	                         CONSTANT "NEW"         
,FILE_NAME	                     CONSTANT '!FILE_NAME!'   
,LINE_NUM	                     RECNUM   
,RECORD_ID	                     "DKA_IPOCDE_HEADERS_S.NEXTVAL" 
,LOADER_REQUEST_ID	             CONSTANT '!LOAD_REQUEST_ID!'
)

INTO TABLE DKA_IPOCDE_REPORTING_HEADERS
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
UO	                             POSITION(1) "RTRIM(LTRIM(:UO))"
,PO_NUMBER	                     "RTRIM(LTRIM(:PO_NUMBER))"
,AMENDMENT_NUMBER	             "RTRIM(LTRIM(:AMENDMENT_NUMBER))"
,PO_STATUS	                      "RTRIM(LTRIM(:PO_STATUS))"
,SUPPLIER_NUMBER	              "RTRIM(LTRIM(:SUPPLIER_NUMBER))"
,SITE_SUPPLIER_NAME	             "RTRIM(LTRIM(:SITE_SUPPLIER_NAME))"
,IVALUA_SITE_SUPPLIER_ID         "RTRIM(LTRIM(:IVALUA_SITE_SUPPLIER_ID))"
,CURRENCY	                     "RTRIM(LTRIM(:CURRENCY))"
,DESCRIPTION	                 "RTRIM(LTRIM(:DESCRIPTION))"     
,AGENT_NUMBER	                 "RTRIM(LTRIM(:AGENT_NUMBER))"    
,URL_BDC	                     "RTRIM(LTRIM(:URL_BDC))"    
,PO_CREATION_DATE	             DATE  'DD/MM/YYYY HH24:MI:SS'   NULLIF (PO_CREATION_DATE= BLANKS)      
,DIRECT_PAYMENT	                 "REPLACE(:DIRECT_PAYMENT,CHR(13),'')"    
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'     
,STATUT	                         CONSTANT "NEW"         
,FILE_NAME	                     CONSTANT '!FILE_NAME!'   
,LINE_NUM	                     RECNUM  
,LOADER_REQUEST_ID	             CONSTANT '!LOAD_REQUEST_ID!'
)

INTO TABLE DKA_IPOCDE_HIST_HEADERS
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
UO	                             POSITION(1) "RTRIM(LTRIM(:UO))"
,PO_NUMBER	                     "RTRIM(LTRIM(:PO_NUMBER))"
,AMENDMENT_NUMBER	             "RTRIM(LTRIM(:AMENDMENT_NUMBER))"
,PO_STATUS	                      "RTRIM(LTRIM(:PO_STATUS))"
,SUPPLIER_NUMBER	              "RTRIM(LTRIM(:SUPPLIER_NUMBER))"
,SITE_SUPPLIER_NAME	             "RTRIM(LTRIM(:SITE_SUPPLIER_NAME))"
,IVALUA_SITE_SUPPLIER_ID         "RTRIM(LTRIM(:IVALUA_SITE_SUPPLIER_ID))"
,CURRENCY	                     "RTRIM(LTRIM(:CURRENCY))"
,DESCRIPTION	                 "RTRIM(LTRIM(:DESCRIPTION))"     
,AGENT_NUMBER	                 "RTRIM(LTRIM(:AGENT_NUMBER))"    
,URL_BDC	                     "RTRIM(LTRIM(:URL_BDC))"    
,PO_CREATION_DATE	             DATE  'DD/MM/YYYY HH24:MI:SS'   NULLIF (PO_CREATION_DATE= BLANKS)      
,DIRECT_PAYMENT	                 "REPLACE(:DIRECT_PAYMENT,CHR(13),'')"    
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