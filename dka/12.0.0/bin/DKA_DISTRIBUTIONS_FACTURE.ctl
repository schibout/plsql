-------------------------------------------------------------------------------
-- $Header$
-- FILE          :  DKA_DISTRIBUTIONS_FACTURE.ctl V1.0.0.0 
-- DESCRIPTION   :  reprise_entete_lignes_facture 
--
-- AUTHOR        :  R.AYMAZ
--
-- CREATION DATE :  14/04/2016
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
INTO TABLE DKA_DISTRIBUTIONS_FACTURE_TMP FIELDS TERMINATED BY '|'    
TRAILING NULLCOLS(
           TRX_ID                         INTEGER EXTERNAL NULLIF (TRX_ID= BLANKS)   
          ,TRX_NUMBER                     CHAR NULLIF (TRX_NUMBER= BLANKS)
          ,LINE_NUMBER                    INTEGER EXTERNAL NULLIF (LINE_NUMBER= BLANKS)
          ,ACCOUNT_CLASS                  CHAR NULLIF (ACCOUNT_CLASS= BLANKS) 
          ,GL_DATE                        DATE  'YYYY/MM/DD'   NULLIF (GL_DATE= BLANKS)
          ,PERCENT                        FLOAT EXTERNAL NULLIF (PERCENT=BLANKS) "REPLACE(:PERCENT,',','.')"
          ,DIST_AMOUNT                    FLOAT EXTERNAL NULLIF (DIST_AMOUNT=BLANKS) "REPLACE(:DIST_AMOUNT,',','.')"
          ,DIST_ACCT1                     CHAR NULLIF (DIST_ACCT1= BLANKS) 
          ,DIST_ACCT2                     CHAR NULLIF (DIST_ACCT2= BLANKS)  
          ,DIST_ACCT3                     CHAR NULLIF (DIST_ACCT3= BLANKS) 
          ,DIST_ACCT4                     CHAR NULLIF (DIST_ACCT4= BLANKS) 
          ,DIST_ACCT5                     CHAR NULLIF (DIST_ACCT5= BLANKS) 
          ,DIST_ACCT6                     CHAR NULLIF (DIST_ACCT6= BLANKS) 
          ,DIST_ACCT7                     CHAR NULLIF (DIST_ACCT7= BLANKS) 
          ,DIST_ACCT8                     CHAR NULLIF (DIST_ACCT8= BLANKS) 
          ,DIST_ACCT9                     CHAR NULLIF (DIST_ACCT9= BLANKS) 
          ,DIST_ACCT10                    CHAR NULLIF (DIST_ACCT10= BLANKS) 
          ,DIST_ATTRIBUTE1                CHAR NULLIF (DIST_ATTRIBUTE1= BLANKS) 
          ,DIST_ATTRIBUTE2                CHAR NULLIF (DIST_ATTRIBUTE2= BLANKS) 
          ,DIST_ATTRIBUTE3                CHAR NULLIF (DIST_ATTRIBUTE3= BLANKS)   
          ,DIST_ATTRIBUTE4                CHAR NULLIF (DIST_ATTRIBUTE4= BLANKS)  
          ,DIST_ATTRIBUTE5                CHAR NULLIF (DIST_ATTRIBUTE5= BLANKS) 
          ,DIST_ATTRIBUTE6                CHAR NULLIF (DIST_ATTRIBUTE6= BLANKS) 
          ,DIST_ATTRIBUTE7                CHAR NULLIF (DIST_ATTRIBUTE7= BLANKS) 
          ,DIST_ATTRIBUTE8                CHAR NULLIF (DIST_ATTRIBUTE8= BLANKS) 
          ,DIST_ATTRIBUTE9                CHAR NULLIF (DIST_ATTRIBUTE9= BLANKS) 
          ,DIST_ATTRIBUTE10               CHAR NULLIF (DIST_ATTRIBUTE10= BLANKS) 
          ,DIST_ATTRIBUTE11               CHAR NULLIF (DIST_ATTRIBUTE11= BLANKS) 
          ,DIST_ATTRIBUTE12               CHAR NULLIF (DIST_ATTRIBUTE12= BLANKS) 
          ,DIST_ATTRIBUTE13               CHAR NULLIF (DIST_ATTRIBUTE13= BLANKS) 
          ,DIST_ATTRIBUTE14               CHAR NULLIF (DIST_ATTRIBUTE14= BLANKS)   
          ,DIST_ATTRIBUTE15               CHAR NULLIF (DIST_ATTRIBUTE15= BLANKS) 
          ,CREATION_DATE                  SYSDATE 
          ,CREATED_BY                     CONSTANT '!USER_ID!'     
          ,LAST_UPDATE_DATE               SYSDATE                   
          ,LAST_UPDATED_BY                CONSTANT '!USER_ID!'     
          ,LOAD_REQUEST_ID                CONSTANT '!LOAD_REQUEST_ID!' 
          ,FLAG                           CONSTANT 'N'
)
