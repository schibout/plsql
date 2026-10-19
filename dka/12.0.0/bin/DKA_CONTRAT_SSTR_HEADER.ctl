--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_CONTRAT_SSTR_HEADER.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_CONTRAT_SSTR_HEADER_TMP
--
-- USAGE
--   DKA_CONTRAT_SSTR_HEADER.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    28/03/2016     RBE Creation
-- V2.0    18/08/2017     RBE Correctif artf2212570 : Ajout LATEST_EXTERNAL_FLAG
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_CONTRAT_SSTR_HEADER_TMP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
 DATA_TYPE                        CHAR              NULLIF (DATA_TYPE            = BLANKS)
,DOCUMENT_NUM                     CHAR              NULLIF (DOCUMENT_NUM         = BLANKS)
,TYPE_LOOKUP_CODE                 CHAR              NULLIF (TYPE_LOOKUP_CODE     = BLANKS)
,AGENT_NAME                       CHAR              NULLIF (AGENT_NAME           = BLANKS)
,VENDOR_NAME                      CHAR              NULLIF (VENDOR_NAME          = BLANKS)
,VENDOR_SITE_CODE                 CHAR              NULLIF (VENDOR_SITE_CODE     = BLANKS)
,SHIP_TO_LOCATION                 CHAR              NULLIF (SHIP_TO_LOCATION     = BLANKS)
,BILL_TO_LOCATION                 CHAR              NULLIF (BILL_TO_LOCATION     = BLANKS)
,PAYMENT_TERMS                    CHAR              NULLIF (PAYMENT_TERMS        = BLANKS)
,CURRENCY_CODE                    CHAR              NULLIF (CURRENCY_CODE        = BLANKS)
,RATE_DATE                        DATE 'YYYY/MM/DD' NULLIF (RATE_DATE            = BLANKS)
,START_DATE                       DATE 'YYYY/MM/DD' NULLIF (START_DATE           = BLANKS)
,END_DATE                         DATE 'YYYY/MM/DD' NULLIF (END_DATE             = BLANKS)
,BLANKET_TOTAL_AMOUNT             FLOAT EXTERNAL    NULLIF (BLANKET_TOTAL_AMOUNT = BLANKS) "REPLACE(:BLANKET_TOTAL_AMOUNT,',','.')"
,APPROVAL_STATUS                  CHAR              NULLIF (APPROVAL_STATUS      = BLANKS)
,APPROVED_FLAG                    CHAR              NULLIF (APPROVED_FLAG        = BLANKS)
,APPROVED_DATE                    DATE 'YYYY/MM/DD' NULLIF (APPROVED_DATE        = BLANKS)
,REVISION_NUM                     INTEGER EXTERNAL  NULLIF (REVISION_NUM         = BLANKS)
,COMMENTS                         CHAR              NULLIF (COMMENTS             = BLANKS)
,ATTRIBUTE4                       CHAR              NULLIF (ATTRIBUTE4           = BLANKS)
,ATTRIBUTE5                       CHAR              NULLIF (ATTRIBUTE5           = BLANKS)
,ATTRIBUTE13                      CHAR              NULLIF (ATTRIBUTE13          = BLANKS)
,ATTRIBUTE14                      CHAR              NULLIF (ATTRIBUTE14          = BLANKS)
,ATTRIBUTE15                      CHAR              NULLIF (ATTRIBUTE15          = BLANKS)
,SOCIETE                          CHAR              NULLIF (SOCIETE              = BLANKS)
,REGION                           CHAR              NULLIF (REGION               = BLANKS)
,REVISION_DATE                    DATE 'YYYY/MM/DD' NULLIF (REVISION_DATE        = BLANKS)
,LATEST_EXTERNAL_FLAG             CHAR              NULLIF (LATEST_EXTERNAL_FLAG = BLANKS)
,CREATION_DATE                    SYSDATE
,CREATED_BY                       CONSTANT '!USER_ID!'      
,LAST_UPDATE_DATE                 SYSDATE                   
,LAST_UPDATED_BY                  CONSTANT '!USER_ID!'      
,LOAD_REQUEST_ID                  CONSTANT '!LOAD_REQUEST_ID!'
,STATUT                           CONSTANT '-1'
)

--Fin
