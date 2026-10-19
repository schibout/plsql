----------------------------------------------------------------------
-- PROGRAM : DKA_IPROJECT_ICENTREFIN_LOADER                          -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 19/09/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_IPROJECT_ICENTREFIN_LOADER.prog                  -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Import des projets dans PA                	         -
--              Fichier plat des centre de finance                   -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.0                                        -
-- PROGRAMME MODIFIE LE :                                            -
-- PAR                  :                                            -
-- OBJET                :                                            -
--                                                                   -
----------------------------------------------------------------------
OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_EAI_ORGANISATION
FIELDS TERMINATED BY ";" optionally enclosed by '"'
TRAILING NULLCOLS
(ID	                        INTEGER EXTERNAL  NULLIF (ID = BLANKS)
,CENTRE_FINANCE	            "RTRIM(LTRIM(:CENTRE_FINANCE))"
,DESCRIPTION                "RTRIM(LTRIM(:DESCRIPTION))"
,START_DATE	                DATE 'DD/MM/YYYY' NULLIF (START_DATE =BLANKS)
,END_DATE	                DATE 'DD/MM/YYYY' NULLIF (END_DATE =BLANKS)
,ORG_PARENT	                "RTRIM(LTRIM(:ORG_PARENT))"
,OA_STATUS	                "RTRIM(LTRIM(:OA_STATUS))"
,OA_REJECTION_REASON        "RTRIM(LTRIM(:OA_REJECTION_REASON))"
,OA_REQUEST_ID	            INTEGER EXTERNAL  NULLIF (OA_REQUEST_ID = BLANKS)         
,LAST_UPDATED_BY	        INTEGER EXTERNAL  NULLIF (LAST_UPDATED_BY = BLANKS)
,LAST_UPDATE_DATE	        DATE 'DD/MM/YYYY' NULLIF (LAST_UPDATE_DATE =BLANKS)
,CREATION_DATE	            DATE 'DD/MM/YYYY' NULLIF (CREATION_DATE =BLANKS)

)

