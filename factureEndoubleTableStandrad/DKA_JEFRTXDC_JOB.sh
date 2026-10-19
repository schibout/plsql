--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_LOADER_REPARCLIIMP_CLIENTS.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_CLIENTS_TMP
--
-- USAGE
--   DKA_LOADER_REPARCLIIMP_CLIENTS.ctl
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
INTO TABLE DKA_CLIENTS_REL_TMP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
RELATIONSHIP_TYPE_CODE   CHAR NULLIF (RELATIONSHIP_TYPE_CODE= BLANKS),
RELATED_CUSTOMER_NAME    CHAR NULLIF (RELATED_CUSTOMER_NAME= BLANKS),
RELATED_CUSTOMER_NUMBER  CHAR NULLIF (RELATED_CUSTOMER_NUMBER= BLANKS),
CUSTOMER_NAME            CHAR NULLIF (CUSTOMER_NAME= BLANKS),
CUSTOMER_NUMBER          CHAR NULLIF (CUSTOMER_NUMBER= BLANKS),
CUSTOMER_RECIPROCAL_FLAG CHAR NULLIF (CUSTOMER_RECIPROCAL_FLAG= BLANKS),
BILL_TO_FLAG	           CHAR NULLIF (BILL_TO_FLAG= BLANKS),
SHIP_TO_FLAG             CHAR NULLIF (SHIP_TO_FLAG= BLANKS),
STATUT                   CONSTANT 'NEW',
LOGICAL_LINE_NUM         RECNUM,
CREATION_DATE            SYSDATE,
CREATED_BY               CONSTANT '!USER_ID!',
LAST_UPDATE_DATE         SYSDATE,
LAST_UPDATED_BY          CONSTANT '!USER_ID!',
LOAD_REQUEST_ID          CONSTANT '!LOAD_REQUEST_ID!'
)

--Fin