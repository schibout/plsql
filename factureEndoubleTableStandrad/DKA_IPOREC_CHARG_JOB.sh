-------------------------------------------------------------------------------
-- $Header$
-- FILE          :  DKA_SFNDUSER_ASSRESP.ctl V1.0.0.0 
-- DESCRIPTION   :  DKA Utilitaire de gestion des acces utilisateurs
--
-- AUTHOR        :  SEL
--
-- CREATION DATE :  16/09/2020
--
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             : 
-- Date                :
-- Author              :
-- Nature              :
--------------------------------------------------------------------------------

OPTIONS (SKIP=1) 
LOAD DATA
APPEND
INTO TABLE DKA_SFNDUSER_ASSRESP FIELDS TERMINATED BY ';'    TRAILING NULLCOLS(
USER_NAME	         CHAR   NULLIF (USER_NAME= BLANKS),
RESPONSIBILITY       CHAR   NULLIF (RESPONSIBILITY= BLANKS),
INACTIVE_DATE        DATE   'DD/MM/YYYY HH24:MI:SS' "REPLACE(:INACTIVE_DATE,CHR(13),'')",
CREATION_DATE        SYSDATE,
CREATED_BY           CONSTANT '!USER_ID!' ,
LAST_UPDATE_DATE     SYSDATE,
LAST_UPDATED_BY	     CONSTANT '!USER_ID!' ,
STATUT               CONSTANT "NEW",
RECORD_ID            "DKA_SFNDUSER_ASSRESP_S.NEXTVAL"
)
