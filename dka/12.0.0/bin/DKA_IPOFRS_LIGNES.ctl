----------------------------------------------------------------------
-- PROGRAM : DKA_APIMPFRSIVALUA                                        -
-- AUTEUR  : SHA / SOCIETE : CAPGEMINI                               -
-- DATE    : 08/05/20                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_APIMPFRSIVALUA.prog                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              import founisseur                  				 -
--              Fichier plat des societé sur lesqulles les sites fournisseurs devront être créé -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.0                                        -
-- PROGRAMME MODIFIE LE : 12/05/2022                                           -
-- PAR                  : Anas RAOUF                                          -
-- OBJET                : EDB330                                           -
--                                                                   -
----------------------------------------------------------------------
OPTIONS (ERRORS=0,SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_IPOFRS_LIGNES
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(
 NUM_FOURNISSEUR                POSITION(1)"RTRIM(LTRIM(:NUM_FOURNISSEUR))"
,NOM_ADRESSE_SITE	        	"RTRIM(LTRIM(:NOM_ADRESSE_SITE))"
,ID_IVALUA_SITE_FOURNISSEUR     "RTRIM(LTRIM(:ID_IVALUA_SITE_FOURNISSEUR))"
,PAYS             			    "RTRIM(LTRIM(:PAYS))"
,ADRESSE_LIGNE1	                 "RTRIM(LTRIM(:ADRESSE_LIGNE1))"
,ADRESSE_LIGNE2				    "RTRIM(LTRIM(:ADRESSE_LIGNE2))"
,ADRESSE_LIGNE3					"RTRIM(LTRIM(:ADRESSE_LIGNE3))"
,VILLE 			                "RTRIM(LTRIM(:VILLE))"
,REGION				            "RTRIM(LTRIM(:REGION))"
,CODE_POSTAL				    "RTRIM(LTRIM(:CODE_POSTAL))"
,STATUT_SITE_FOURNISSEUR        "RTRIM(LTRIM(:STATUT_SITE_FOURNISSEUR))"
,FONCTION_ACHATS                "RTRIM(LTRIM(:FONCTION_ACHATS))"
,FONCTION_REGLEMENT             "RTRIM(LTRIM(:FONCTION_REGLEMENT))"
,FONCTION_CARTE_ACHAT           "RTRIM(LTRIM(:FONCTION_CARTE_ACHAT))"
,COMPLEMENT_SIRET               "RTRIM(LTRIM(:COMPLEMENT_SIRET))"
,CODE_INSEE_COMMUNE             "RTRIM(LTRIM(:CODE_INSEE_COMMUNE))"
,BUREAU_DISTRIBUTEUR            "RTRIM(LTRIM(:BUREAU_DISTRIBUTEUR))"
,TELEPHONE                      "RTRIM(LTRIM(:TELEPHONE))"
,EMAIL_ACHAT                    "RTRIM(LTRIM(:EMAIL_ACHAT))"
,EMAIL_FINANCE                  "REPLACE( :EMAIL_FINANCE,CHR(13),'')"
,ECHEANCE	        			"RTRIM(LTRIM(:ECHEANCE))"
,CREATION_DATE			         SYSDATE
,CREATED_BY				         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE		         SYSDATE
,LAST_UPDATED_BY 		         CONSTANT '!USER_ID!'
,STATUT             	         CONSTANT "NEW"
,FILE_NAME				         CONSTANT '!FILE_NAME!'
,LINE_NUM                        RECNUM
,RECORD_ID                       "DKA_IPOFRS_LIGNES_S.NEXTVAL"
,REQUEST_ID                      CONSTANT '-1'
,LOADER_REQUEST_ID               CONSTANT '!LOAD_REQUEST_ID!'

)

INTO TABLE DKA_IPOFRS_REPORTING_LIGNES
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(
 NUM_FOURNISSEUR                POSITION(1)"RTRIM(LTRIM(:NUM_FOURNISSEUR))"
,NOM_ADRESSE_SITE	        	"RTRIM(LTRIM(:NOM_ADRESSE_SITE))"
,ID_IVALUA_SITE_FOURNISSEUR     "RTRIM(LTRIM(:ID_IVALUA_SITE_FOURNISSEUR))"
,PAYS             			    "RTRIM(LTRIM(:PAYS))"
,ADRESSE_LIGNE1	                 "RTRIM(LTRIM(:ADRESSE_LIGNE1))"
,ADRESSE_LIGNE2					"RTRIM(LTRIM(:ADRESSE_LIGNE2))"
,ADRESSE_LIGNE3					"RTRIM(LTRIM(:ADRESSE_LIGNE3))"
,VILLE 			                "RTRIM(LTRIM(:VILLE))"
,REGION				            "RTRIM(LTRIM(:REGION))"
,CODE_POSTAL				    "RTRIM(LTRIM(:CODE_POSTAL))"
,STATUT_SITE_FOURNISSEUR        "RTRIM(LTRIM(:STATUT_SITE_FOURNISSEUR))"
,FONCTION_ACHATS                "RTRIM(LTRIM(:FONCTION_ACHATS))"
,FONCTION_REGLEMENT             "RTRIM(LTRIM(:FONCTION_REGLEMENT))"
,FONCTION_CARTE_ACHAT           "RTRIM(LTRIM(:FONCTION_CARTE_ACHAT))"
,COMPLEMENT_SIRET               "RTRIM(LTRIM(:COMPLEMENT_SIRET))"
,CODE_INSEE_COMMUNE             "RTRIM(LTRIM(:CODE_INSEE_COMMUNE))"
,BUREAU_DISTRIBUTEUR            "RTRIM(LTRIM(:BUREAU_DISTRIBUTEUR))"
,TELEPHONE                      "RTRIM(LTRIM(:TELEPHONE))"
,EMAIL_ACHAT                    "RTRIM(LTRIM(:EMAIL_ACHAT))"
,EMAIL_FINANCE                  "REPLACE( :EMAIL_FINANCE,CHR(13),'')"
,CREATION_DATE			         SYSDATE
,CREATED_BY				         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE		         SYSDATE
,LAST_UPDATED_BY 		         CONSTANT '!USER_ID!'
,STATUT             	         CONSTANT "NEW"
,FILE_NAME				         CONSTANT '!FILE_NAME!'
,LINE_NUM                        RECNUM
,REQUEST_ID                      CONSTANT '-1'
,LOADER_REQUEST_ID               CONSTANT '!LOAD_REQUEST_ID!'
,ECHEANCE	        			"RTRIM(LTRIM(:ECHEANCE))"
)

INTO TABLE DKA_IPOFRS_HIST_LIGNES
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(
 NUM_FOURNISSEUR                POSITION(1)"RTRIM(LTRIM(:NUM_FOURNISSEUR))"
,NOM_ADRESSE_SITE	        	"RTRIM(LTRIM(:NOM_ADRESSE_SITE))"
,ID_IVALUA_SITE_FOURNISSEUR     "RTRIM(LTRIM(:ID_IVALUA_SITE_FOURNISSEUR))"
,PAYS             			    "RTRIM(LTRIM(:PAYS))"
,ADRESSE_LIGNE1	                 "RTRIM(LTRIM(:ADRESSE_LIGNE1))"
,ADRESSE_LIGNE2					"RTRIM(LTRIM(:ADRESSE_LIGNE2))"
,ADRESSE_LIGNE3					"RTRIM(LTRIM(:ADRESSE_LIGNE3))"
,VILLE 			                "RTRIM(LTRIM(:VILLE))"
,REGION				            "RTRIM(LTRIM(:REGION))"
,CODE_POSTAL				    "RTRIM(LTRIM(:CODE_POSTAL))"
,STATUT_SITE_FOURNISSEUR        "RTRIM(LTRIM(:STATUT_SITE_FOURNISSEUR))"
,FONCTION_ACHATS                "RTRIM(LTRIM(:FONCTION_ACHATS))"
,FONCTION_REGLEMENT             "RTRIM(LTRIM(:FONCTION_REGLEMENT))"
,FONCTION_CARTE_ACHAT           "RTRIM(LTRIM(:FONCTION_CARTE_ACHAT))"
,COMPLEMENT_SIRET               "RTRIM(LTRIM(:COMPLEMENT_SIRET))"
,CODE_INSEE_COMMUNE             "RTRIM(LTRIM(:CODE_INSEE_COMMUNE))"
,BUREAU_DISTRIBUTEUR            "RTRIM(LTRIM(:BUREAU_DISTRIBUTEUR))"
,TELEPHONE                      "RTRIM(LTRIM(:TELEPHONE))"
,EMAIL_ACHAT                    "RTRIM(LTRIM(:EMAIL_ACHAT))"
,EMAIL_FINANCE                  "REPLACE( :EMAIL_FINANCE,CHR(13),'')"
,CREATION_DATE			         SYSDATE
,CREATED_BY				         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE		         SYSDATE
,LAST_UPDATED_BY 		         CONSTANT '!USER_ID!'
,STATUT             	         CONSTANT "NEW"
,FILE_NAME				         CONSTANT '!FILE_NAME!'
,LINE_NUM                        RECNUM
,REQUEST_ID                      CONSTANT '-1'
,LOADER_REQUEST_ID               CONSTANT '!LOAD_REQUEST_ID!'
,ECHEANCE	        			"RTRIM(LTRIM(:ECHEANCE))"
)

--FIN

        
