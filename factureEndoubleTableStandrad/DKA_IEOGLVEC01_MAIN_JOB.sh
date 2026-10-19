--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_LOADER_REPPOACHIMP.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_REP_ACHETEURS
--
-- USAGE
--   DKA_LOADER_REPPOACHIMP.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    07/11/2016     OBE Creation
---------------------------------------------------------------------------------------------
-- V1.1    21/12/2016     OBE Modification séparateur ';' par '|'
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_REP_ACHETEURS
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
FULL_NAME                        CHAR NULLIF (FULL_NAME= BLANKS)
,EMPLOYEE_NUMBER                 CHAR NULLIF (EMPLOYEE_NUMBER= BLANKS)
,STATUT                          CHAR NULLIF (STATUT= BLANKS)
,LOGICAL_LINE_NUM                RECNUM
,CREATION_DATE                   SYSDATE
,CREATED_BY                      CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE                SYSDATE
,LAST_UPDATED_BY                 CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                 CONSTANT '!LOAD_REQUEST_ID!'
)

--Fin