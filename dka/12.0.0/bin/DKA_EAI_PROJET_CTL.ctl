----------------------------------------------------------------------
-- PROGRAM : DKA_IPROJECT_ICENTREFIN_LOADER                          -
-- AUTEUR  : YWA / SOCIETE : CAPGEMINI                               -
-- DATE    : 19/09/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_IPROJECT_ICENTREFIN_LOADER.prog                  -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Import des projets dans PA                	         -
--              Fichier plat des projets                              -
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
INTO TABLE DKA_EAI_PROJET
FIELDS TERMINATED BY ";" optionally enclosed by '"'
TRAILING NULLCOLS
(ID                             INTEGER EXTERNAL  NULLIF (ID = BLANKS)
 ,OPERATING_UNIT                "RTRIM(LTRIM(:OPERATING_UNIT))"
 ,PROJECT_CODE                  "RTRIM(LTRIM(:PROJECT_CODE))"   
 ,LIBELLE                       "RTRIM(LTRIM(:LIBELLE))"   
 ,PROJECT_TEMPLATE              "RTRIM(LTRIM(:PROJECT_TEMPLATE))" 
 ,PROJECT_START_DATE            DATE 'DD/MM/YYYY' NULLIF (PROJECT_START_DATE =BLANKS)
 ,PROJECT_CLOSING_DATE          DATE 'DD/MM/YYYY' NULLIF (PROJECT_CLOSING_DATE =BLANKS)
 ,PROJECT_COMPLETION_DATE       DATE 'DD/MM/YYYY' NULLIF (PROJECT_COMPLETION_DATE =BLANKS)
 ,PROJECT_TYPE                  "RTRIM(LTRIM(:PROJECT_TYPE))"
 ,ORGANIZATION_NAME             "RTRIM(LTRIM(:ORGANIZATION_NAME))"
 ,ORGANIZATION_START_DATE       DATE 'DD/MM/YYYY' NULLIF (ORGANIZATION_START_DATE =BLANKS)
 ,CODE_AFFAIRE                  "RTRIM(LTRIM(:CODE_AFFAIRE))"
 ,CODE_ACTIVITE                 "RTRIM(LTRIM(:CODE_ACTIVITE))"
 ,CODE_FILIERE                  "RTRIM(LTRIM(:CODE_FILIERE))"
 ,CODE_DESTINATION              "RTRIM(LTRIM(:CODE_DESTINATION))"
 ,OA_STATUS                     "RTRIM(LTRIM(:OA_STATUS))"
 ,OA_REJECTION_REASON           "RTRIM(LTRIM(:OA_REJECTION_REASON))"
 ,OA_ACTION_TYPE                "RTRIM(LTRIM(:OA_ACTION_TYPE))" 
 ,OA_REQUEST_ID                 INTEGER EXTERNAL  NULLIF (OA_REQUEST_ID = BLANKS)        
 ,LAST_UPDATED_BY               INTEGER EXTERNAL  NULLIF (LAST_UPDATED_BY = BLANKS)
 ,LAST_UPDATE_DATE              DATE 'DD/MM/YYYY' NULLIF (LAST_UPDATE_DATE =BLANKS)
 ,CREATION_DATE                 DATE 'DD/MM/YYYY' NULLIF (CREATION_DATE =BLANKS)

)

