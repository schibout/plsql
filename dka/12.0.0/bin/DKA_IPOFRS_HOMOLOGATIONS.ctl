----------------------------------------------------------------------
-- PROGRAM : DKA_APIMPFRSIVALUA_LOADER                                        -
-- AUTEUR  : SHA / SOCIETE : CAPGEMINI                               -
-- DATE    : 08/05/2020                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_APIMPFRSIVALUA_LOADER.prog                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              import founisseur                  				 -
--              Fichier plat des sites fournisseurs                  -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.0                                        -
-- PROGRAMME MODIFIE LE :                                            -
-- PAR                  :                                            -
-- OBJET                :                                            -
--                                                                   -
----------------------------------------------------------------------
OPTIONS (ERRORS=0,SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_IPOFRS_HOMOLOGATIONS
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(
 NUM_FOURNISSEUR                    POSITION(1)"RTRIM(LTRIM(:NUM_FOURNISSEUR))"
,NOM_ADRESSE_SITE	                "RTRIM(LTRIM(:NOM_ADRESSE_SITE))"
,ID_IVALUA_SITE_FOURNISSEUR         "RTRIM(LTRIM(:ID_IVALUA_SITE_FOURNISSEUR))"
,PERIMETRE_HOMOLOGATION             "REPLACE( :PERIMETRE_HOMOLOGATION,CHR(13),'')" 
,CREATION_DATE				       	 SYSDATE
,CREATED_BY					       	 CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE			       	 SYSDATE
,LAST_UPDATED_BY 			       	 CONSTANT '!USER_ID!'
,STATUT             		       	 CONSTANT "NEW"
,FILE_NAME				             CONSTANT '!FILE_NAME!'
,LINE_NUM                            RECNUM
,RECORD_ID                           "DKA_IPOFRS_HOMOLO_S.NEXTVAL"
,REQUEST_ID                          CONSTANT '-1'
,LOADER_REQUEST_ID                   CONSTANT '!LOAD_REQUEST_ID!'
)

INTO TABLE DKA_IPOFRS_REPORTING_HOMOLOG
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(
 NUM_FOURNISSEUR                    POSITION(1)"RTRIM(LTRIM(:NUM_FOURNISSEUR))"
,NOM_ADRESSE_SITE	                "RTRIM(LTRIM(:NOM_ADRESSE_SITE))"
,ID_IVALUA_SITE_FOURNISSEUR         "RTRIM(LTRIM(:ID_IVALUA_SITE_FOURNISSEUR))"
,PERIMETRE_HOMOLOGATION             "REPLACE( :PERIMETRE_HOMOLOGATION,CHR(13),'')" 
,CREATION_DATE				       	 SYSDATE
,CREATED_BY					       	 CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE			       	 SYSDATE
,LAST_UPDATED_BY 			       	 CONSTANT '!USER_ID!'
,STATUT             		       	 CONSTANT "NEW"
,FILE_NAME				             CONSTANT '!FILE_NAME!'
,LINE_NUM                            RECNUM
,REQUEST_ID                          CONSTANT '-1'
,LOADER_REQUEST_ID                   CONSTANT '!LOAD_REQUEST_ID!'
)

INTO TABLE DKA_IPOFRS_HIST_HOMOLOGATIONS
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(
 NUM_FOURNISSEUR                    POSITION(1)"RTRIM(LTRIM(:NUM_FOURNISSEUR))"
,NOM_ADRESSE_SITE	                "RTRIM(LTRIM(:NOM_ADRESSE_SITE))"
,ID_IVALUA_SITE_FOURNISSEUR         "RTRIM(LTRIM(:ID_IVALUA_SITE_FOURNISSEUR))"
,PERIMETRE_HOMOLOGATION             "REPLACE( :PERIMETRE_HOMOLOGATION,CHR(13),'')" 
,CREATION_DATE				       	 SYSDATE
,CREATED_BY					       	 CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE			       	 SYSDATE
,LAST_UPDATED_BY 			       	 CONSTANT '!USER_ID!'
,STATUT             		       	 CONSTANT "NEW"
,FILE_NAME				             CONSTANT '!FILE_NAME!'
,LINE_NUM                            RECNUM
,REQUEST_ID                          CONSTANT '-1'
,LOADER_REQUEST_ID                   CONSTANT '!LOAD_REQUEST_ID!'
)

--FIN
