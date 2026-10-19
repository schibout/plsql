----------------------------------------------------------------------
-- PROGRAM : DKA_REPGLSOLDESIMP_CTL                                      -
-- AUTEUR  : J.Pelat & B.Delattre / SOCIETE : CAPGEMINI                               -
-- DATE    : 13/04/16                                           -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPGLSOLDESIMP_LOADER                                -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise    de soldes GL               				 -
--              Fichier plat des reprises de solde GL                 	-
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.1                                        -
-- PROGRAMME MODIFIE LE :                                            -
-- PAR                  :                                            -
-- OBJET                :                                            -
--                                                                   -
----------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 21/09/2016 JPE artf2002973 : Reprise des soldes GL  - Prise en compte écritures non lettrées
-- 26/10/2016 JLY artf2035373 : Description des lignes non lettrées - Import
-- 09/01/2017 OBE Modification - artf2069617

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_GL_REPSOLDE_TMP
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(CURRENCY_CODE				  "RTRIM(LTRIM(:CURRENCY_CODE))"
,SEGMENT1							  "RTRIM(LTRIM(:SEGMENT1))"
,SEGMENT2							  "RTRIM(LTRIM(:SEGMENT2))"
,SEGMENT3							  "RTRIM(LTRIM(:SEGMENT3))"
,SEGMENT4							  "RTRIM(LTRIM(:SEGMENT4))"
,SEGMENT5							  "RTRIM(LTRIM(:SEGMENT5))"
,SEGMENT6							  "RTRIM(LTRIM(:SEGMENT6))"
,SEGMENT7							  "RTRIM(LTRIM(:SEGMENT7))"
,SEGMENT8							  "RTRIM(LTRIM(:SEGMENT8))"
,SEGMENT9							  "RTRIM(LTRIM(:SEGMENT9))"
,SEGMENT10						  "RTRIM(LTRIM(:SEGMENT10))"
,ACCOUNTED_CR					  FLOAT EXTERNAL NULLIF (ACCOUNTED_CR=BLANKS) "REPLACE(:ACCOUNTED_CR,',','.')" 
,ACCOUNTED_DR					  FLOAT EXTERNAL NULLIF (ACCOUNTED_DR=BLANKS) "REPLACE(:ACCOUNTED_DR,',','.')" 
,ENTITE 							  "RTRIM(LTRIM(:ENTITE))"
,CREATION_DATE          SYSDATE
,CREATED_BY             CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE       SYSDATE
,LAST_UPDATED_BY        CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID        CONSTANT '!LOAD_REQUEST_ID!'
,JGZZ_RECON_REF         "RTRIM(LTRIM(:JGZZ_RECON_REF))"
,PERIODE		         	  "RTRIM(LTRIM(:PERIODE))"
,DESCRIPTION		        "SUBSTR(:DESCRIPTION, 1, 240)"
,UNIQ_KEY		         	  "RTRIM(LTRIM(:UNIQ_KEY))"
,ATTRIBUTE9		          "RTRIM(LTRIM(:ATTRIBUTE9))"
,ATTRIBUTE10		        "RTRIM(LTRIM(:ATTRIBUTE10))"
,USER_JE_CATEGORY_NAME	"RTRIM(LTRIM(:USER_JE_CATEGORY_NAME))"
,REFERENCE4		         	"RTRIM(LTRIM(:REFERENCE4))"
,REFERENCE5		         	"RTRIM(LTRIM(:REFERENCE5))"
)

