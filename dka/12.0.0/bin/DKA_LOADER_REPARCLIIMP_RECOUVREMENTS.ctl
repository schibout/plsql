--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_LOADER_REPARCLIIMP_RECOUVREMENTS.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_RECOUVREMENTS_TMP
--
-- USAGE
--   DKA_LOADER_REPARCLIIMP_RECOUVREMENTS.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    06/05/2016     OBE Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_RECOUVREMENTS_TMP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
customer_number	                 CHAR NULLIF (customer_number= BLANKS)
,CDG				                     CHAR NULLIF (CDG= BLANKS)
,collector			                 CHAR NULLIF (collector= BLANKS)
,ETL_status			                 CHAR NULLIF (ETL_status= BLANKS)
,LOGICAL_LINE_NUM                RECNUM
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                 CONSTANT '!LOAD_REQUEST_ID!'
)

--Fin