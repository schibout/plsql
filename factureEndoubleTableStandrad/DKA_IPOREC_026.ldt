-------------------------------------------------------------------------------
-- $Header$
-- FILE          :  DKA_EMPJOBSIMP.ctl V1.0.0.0 
-- DESCRIPTION   :  DKA : Transcodification des fonctions des employés - Loader
--
-- AUTHOR        :  P BAUDOUR
--
-- CREATION DATE :  03/10/2016
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
INTO TABLE DKA_EMPLOYEE_JOBS_TMP FIELDS TERMINATED BY ';'    
TRAILING NULLCOLS(

           EMPLOYEE_NUMBER                CHAR NULLIF (EMPLOYEE_NUMBER= BLANKS)
          ,NAME                           CHAR NULLIF (NAME= BLANKS)
          ,CREATION_DATE                  SYSDATE 
          ,CREATED_BY                     CONSTANT '!USER_ID!'     
          ,LAST_UPDATE_DATE               SYSDATE   
          ,LOAD_REQUEST_ID                CONSTANT '!LOAD_REQUEST_ID!'          
          ,LAST_UPDATED_BY                CONSTANT '!USER_ID!'     
           
)
