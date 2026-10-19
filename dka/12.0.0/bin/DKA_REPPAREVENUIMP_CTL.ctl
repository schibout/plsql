----------------------------------------------------------------------
-- PROGRAM : DKA_REPPAREVENUIMP                                      -
-- AUTEUR  : J.Pelat / SOCIETE : CAPGEMINI       				     -
-- DATE    : 29/04/16                                           	 -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPPAREVENUIMP_LOADER                            -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise des revenus              				 	 -
--              Fichier plat des reprises des revenus                -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.2                                        -
-- PROGRAMME MODIFIE LE :                                            -
-- PAR                  :                                            -
-- OBJET                :                                            -
--                                                                   -
----------------------------------------------------------------------
OPTIONS (SKIP=1)
LOAD DATA
APPEND
INTO TABLE DKA_REPPAREVENUIMP_TMP
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(SOCIETE 			"RTRIM(LTRIM(:SOCIETE))"
,REGION      		"RTRIM(LTRIM(:REGION))"
,CODE_PROJET      	"RTRIM(LTRIM(:CODE_PROJET))"	
,TYPE_EVENEMENT		"RTRIM(LTRIM(:TYPE_EVENEMENT))"
,DATE_EVENEMENT		DATE 'YYYY/MM/DD' NULLIF (DATE_EVENEMENT =BLANKS)
,MONTANT_REVENU		FLOAT EXTERNAL NULLIF (MONTANT_REVENU=BLANKS) "REPLACE(:MONTANT_REVENU,',','.')" 
,UNITE_OPE			"RTRIM(LTRIM(:REGION||:SOCIETE))"
,STATUS			    CONSTANT 'NEW'
,CREATION_DATE      SYSDATE
,CREATED_BY         CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE   SYSDATE
,LAST_UPDATED_BY    CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID    CONSTANT '!LOAD_REQUEST_ID!'
)

