----------------------------------------------------------------------
-- PROGRAM : DKA_REPGLCONTREPA_LOADER_CTL                  -
-- AUTEUR  : Y.WARID / SOCIETE : CAPGEMINI                           -
-- DATE    : 17/07/17                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPGLSOLDESIMP_CONTREPASSATION_LOADER            -
-- FONCTION   : Fichier de controle sql*loader                       -
--    programme de reprise des pièces en contrepassation automatique -
--              Fichier plat    des contrepassations                 -
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

OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_GL_CONTREPASSATION_TMP
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
,JGZZ_RECON_REF             "RTRIM(LTRIM(:JGZZ_RECON_REF))"
,CODE_FOLIO                 "RTRIM(LTRIM(:CODE_FOLIO))"
,FIC_IDENT                  "RTRIM(LTRIM(:FIC_IDENT))"
,JE_CATEGORY_NAME                 "RTRIM(LTRIM(:JE_CATEGORY_NAME))"
,REFERENCE4		         	"RTRIM(LTRIM(:REFERENCE4))"
,REFERENCE5		         	"RTRIM(LTRIM(:REFERENCE5))" 
,PERIOD_NAME                "RTRIM(LTRIM(:PERIOD_NAME))"
,ATTRIBUTE11                     "RTRIM(LTRIM(:ATTRIBUTE11))"
,ATTRIBUTE12             "RTRIM(LTRIM(:ATTRIBUTE12))"
,ATTRIBUTE13               "RTRIM(LTRIM(:ATTRIBUTE13))"
,ATTRIBUTE14                "RTRIM(LTRIM(:ATTRIBUTE14))"
,ATTRIBUTE15                "RTRIM(LTRIM(:ATTRIBUTE15))"
,CONTEXT3                   "RTRIM(LTRIM(:CONTEXT3))"
,CREATION_DATE          SYSDATE
,CREATED_BY             CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE       SYSDATE
,LAST_UPDATED_BY        CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID        CONSTANT '!LOAD_REQUEST_ID!'
)

