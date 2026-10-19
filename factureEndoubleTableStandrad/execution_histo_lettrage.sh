--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_LOADER_REPFNDUSER.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA_REP_USERS
--
-- USAGE
--   DKA_LOADER_REPFNDUSER.ctl
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    03/03/2017     JJA Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_REP_USERS
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
  USER_NAME              CHAR    NULLIF (USER_NAME= BLANKS)
 ,DESCRIPTION            CHAR    NULLIF (DESCRIPTION= BLANKS)
 ,EMAIL_ADDRESS          CHAR    NULLIF (EMAIL_ADDRESS= BLANKS)
 ,FAX                    CHAR    NULLIF (FAX= BLANKS)
 ,EMPLOYEE_NUMBER        CHAR    NULLIF (EMPLOYEE_NUMBER= BLANKS)
 ,PARTY_ID               INTEGER NULLIF (PARTY_ID= BLANKS)
 ,PASSWORD_LIFESPAN_DAYS INTEGER NULLIF (PASSWORD_LIFESPAN_DAYS= BLANKS)
 ,OWNER                  CHAR    NULLIF (OWNER= BLANKS)
 ,PASSWORD               CHAR    NULLIF (PASSWORD= BLANKS)
 ,USER_ID                INTEGER NULLIF (USER_ID= BLANKS)
 ,STATUS                 CHAR    NULLIF (STATUS= BLANKS)
 ,MESSAGE                CHAR    NULLIF (MESSAGE= BLANKS)
 ,LOGICAL_LINE_NUM       RECNUM
 ,CREATION_DATE          SYSDATE
 ,CREATED_BY             CONSTANT '!USER_ID!'
 ,LAST_UPDATE_DATE       SYSDATE
 ,LAST_UPDATED_BY        CONSTANT '!USER_ID!'
 ,LOAD_REQUEST_ID        CONSTANT '!LOAD_REQUEST_ID!'
)

--Fin