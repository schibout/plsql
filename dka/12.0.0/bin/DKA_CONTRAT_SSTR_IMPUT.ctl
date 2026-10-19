--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_CONTRAT_SSTR_IMPUT.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_CONTRAT_SSTR_IMPUT_TMP
--
-- USAGE
--   DKA_CONTRAT_SSTR_IMPUT.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    28/03/2016     RBE Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_CONTRAT_SSTR_IMPUT_TMP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
 DATA_TYPE                        CHAR              NULLIF (DATA_TYPE             = BLANKS)  
,DOCUMENT_NUM                     CHAR              NULLIF (DOCUMENT_NUM          = BLANKS)
,CONTRAT_IMPUTATION_ID            INTEGER EXTERNAL  NULLIF (CONTRAT_IMPUTATION_ID = BLANKS)
,PROJECT_CODE                     CHAR              NULLIF (PROJECT_CODE          = BLANKS)
,UNITE_OEUVRE                     INTEGER EXTERNAL  NULLIF (UNITE_OEUVRE          = BLANKS)
,LOCATION_CODE                    CHAR              NULLIF (LOCATION_CODE         = BLANKS)
,REVISION_NUM                     INTEGER EXTERNAL  NULLIF (REVISION_NUM          = BLANKS)
,EXPENDITURE_TYPE                 CHAR              NULLIF (EXPENDITURE_TYPE      = BLANKS)
,CCID_SEGMENT1                    CHAR              NULLIF (CCID_SEGMENT1         = BLANKS)
,CCID_SEGMENT2                    CHAR              NULLIF (CCID_SEGMENT2         = BLANKS)
,CCID_SEGMENT3                    CHAR              NULLIF (CCID_SEGMENT3         = BLANKS)
,CCID_SEGMENT4                    CHAR              NULLIF (CCID_SEGMENT4         = BLANKS)
,CCID_SEGMENT5                    CHAR              NULLIF (CCID_SEGMENT5         = BLANKS)
,CCID_SEGMENT6                    CHAR              NULLIF (CCID_SEGMENT6         = BLANKS)
,CCID_SEGMENT7                    CHAR              NULLIF (CCID_SEGMENT7         = BLANKS)
,CCID_SEGMENT8                    CHAR              NULLIF (CCID_SEGMENT8         = BLANKS)
,CCID_SEGMENT9                    CHAR              NULLIF (CCID_SEGMENT9         = BLANKS)
,CCID_SEGMENT10                   CHAR              NULLIF (CCID_SEGMENT10        = BLANKS)
,CREATION_DATE                    SYSDATE
,CREATED_BY                       CONSTANT '!USER_ID!'      
,LAST_UPDATE_DATE                 SYSDATE                   
,LAST_UPDATED_BY                  CONSTANT '!USER_ID!'      
,LOAD_REQUEST_ID                  CONSTANT '!LOAD_REQUEST_ID!'
,STATUT                           CONSTANT '-1'
)

--Fin