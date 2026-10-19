--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_LOADER_REPFNDRESP.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_REP_RESP
--
-- USAGE
--   DKA_LOADER_REPFNDRESP.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    18/05/2017     OBE Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_REP_RESP
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(


  USER_NAME              CHAR  NULLIF (USER_NAME= BLANKS)
 ,RESPONSIBILITY_NAME    CHAR  NULLIF (RESPONSIBILITY_NAME= BLANKS)
 ,APPLICATION_NAME       CHAR  NULLIF (APPLICATION_NAME= BLANKS)
 ,START_DATE             DATE  'YYYY/MM/DD'  NULLIF (START_DATE= BLANKS)
 ,END_DATE               DATE  'YYYY/MM/DD'  NULLIF (END_DATE= BLANKS)
 ,LOGICAL_LINE_NUM       RECNUM
 ,CREATION_DATE          SYSDATE
 ,CREATED_BY             CONSTANT '!USER_ID!'
 ,LAST_UPDATE_DATE       SYSDATE
 ,LAST_UPDATED_BY        CONSTANT '!USER_ID!'
 ,LOAD_REQUEST_ID        CONSTANT '!LOAD_REQUEST_ID!'
)

--Fin