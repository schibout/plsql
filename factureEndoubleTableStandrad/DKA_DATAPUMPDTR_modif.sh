----------------------------------------------------------------------
-- PROGRAM : DKA_IPROJECT_ICENTREFIN_LOADER                          -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 19/09/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_IPROJECT_ICENTREFIN_LOADER.prog                  -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Import des projets dans PA                	         -
--              Fichier plat des taches                              -
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
INTO TABLE DKA_EAI_TACHE
FIELDS TERMINATED BY ";" optionally enclosed by '"'
TRAILING NULLCOLS
(ID                            INTEGER EXTERNAL  NULLIF (ID = BLANKS)                
,PROJECT_CODE                  "RTRIM(LTRIM(:PROJECT_CODE))"     
,TASK_CODE                     "RTRIM(LTRIM(:TASK_CODE))"              
,TASK_NAME                     "RTRIM(LTRIM(:TASK_NAME))"              
,DESCRIPTION                   "RTRIM(LTRIM(:DESCRIPTION))"            
,TASK_START_DATE               DATE 'DD/MM/YYYY' NULLIF (TASK_START_DATE =BLANKS)        
,TASK_ESTIMATED_END_DATE       DATE 'DD/MM/YYYY' NULLIF (TASK_ESTIMATED_END_DATE =BLANKS)
,TASK_CLOSING_DATE             DATE 'DD/MM/YYYY' NULLIF (TASK_CLOSING_DATE =BLANKS)
,TASK_COMPLETION_DATE          DATE 'DD/MM/YYYY' NULLIF (TASK_COMPLETION_DATE =BLANKS)   
,TASK_ATTRIBUTE	               "RTRIM(LTRIM(:TASK_ATTRIBUTE))"	     
,BILLED_TASK	               "RTRIM(LTRIM(:BILLED_TASK))"	        
,ASSET_CATEGORY	               "RTRIM(LTRIM(:ASSET_CATEGORY))"	     
,WORK_ESTIMATED_AMOUNT         FLOAT EXTERNAL NULLIF (WORK_ESTIMATED_AMOUNT=BLANKS)  "REPLACE(:WORK_ESTIMATED_AMOUNT,',','.')"
,SUBPROJECT_RELATIONSHIP       "RTRIM(LTRIM(:SUBPROJECT_RELATIONSHIP))"
,OA_STATUS                     "RTRIM(LTRIM(:OA_STATUS))"              
,OA_REJECTION_REASON           "RTRIM(LTRIM(:OA_REJECTION_REASON))"    
,OA_REQUEST_ID                 INTEGER EXTERNAL  NULLIF (OA_REQUEST_ID = BLANKS)          
,LAST_UPDATED_BY               INTEGER EXTERNAL  NULLIF (LAST_UPDATED_BY = BLANKS)        
,LAST_UPDATE_DATE              DATE 'DD/MM/YYYY' NULLIF (LAST_UPDATE_DATE =BLANKS)       
,CREATION_DATE                 DATE 'DD/MM/YYYY' NULLIF (CREATION_DATE =BLANKS)
		
)

