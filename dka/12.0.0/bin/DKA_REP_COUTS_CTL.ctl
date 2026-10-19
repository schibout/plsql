----------------------------------------------------------------------
-- PROGRAM : DKA_REPG_COUTS_CTL                                      -
-- AUTEUR  : B.Delattre / SOCIETE : CAPGEMINI                        -
-- DATE    : 07/07/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REP_COUTS_LOADER                                 -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise    de soldes GL                              -
--              Fichier plat des reprises de solde GL                -
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
INTO TABLE DKA_REP_COUTS_INTERFACE
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
(UNITE_OPERATIONNELLE        "RTRIM(LTRIM(:UNITE_OPERATIONNELLE))"
,CODE_PROJET                 "RTRIM(LTRIM(:CODE_PROJET))"
,NUMERO_DE_TACHE             "RTRIM(LTRIM(:NUMERO_DE_TACHE))"
,DATE_DERNIER_JOUR           "to_date(:DATE_DERNIER_JOUR,'yyyy/mm/dd')"
,DATE_DE_DEPENSE             "to_date(:DATE_DE_DEPENSE,'yyyy/mm/dd')"
,TYPE_DEPENSE                "RTRIM(LTRIM(:TYPE_DEPENSE))"
,REFERENCE_ORIG_TRANS        "RTRIM(LTRIM(:REFERENCE_ORIG_TRANS))"
,QUANTITY                    FLOAT EXTERNAL NULLIF (QUANTITY=BLANKS) "REPLACE(:QUANTITY,',','.')"
,CLASSE_TYPE_DEPENSE         "RTRIM(LTRIM(:CLASSE_TYPE_DEPENSE))"
,ORGANISATION_DEPENSE        "RTRIM(LTRIM(:ORGANISATION_DEPENSE))"
,COUT_DIRECT                 FLOAT EXTERNAL NULLIF (COUT_DIRECT=BLANKS) "REPLACE(:COUT_DIRECT,',','.')" 
,COUT_COMPLET                FLOAT EXTERNAL NULLIF (COUT_COMPLET=BLANKS) "REPLACE(:COUT_COMPLET,',','.')" 
,COUT_DIRECT_FONC            FLOAT EXTERNAL NULLIF (COUT_DIRECT_FONC=BLANKS) "REPLACE(:COUT_DIRECT_FONC,',','.')" 
,GL_DATE                     "to_date(:GL_DATE,'yyyy/mm/dd')"
,TRANSACTION_SOURCE          "RTRIM(LTRIM(:TRANSACTION_SOURCE))"
,EXPENDITURE_GROUP           "RTRIM(LTRIM(:EXPENDITURE_GROUP))"
,CLEF_COMPTA_CREDIT          "RTRIM(LTRIM(:CLEF_COMPTA_CREDIT))"
,CLEF_COMPTA_DEBIT           "RTRIM(LTRIM(:CLEF_COMPTA_DEBIT))"
,CREATION_DATE               SYSDATE
,CREATED_BY                  CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE            SYSDATE
,LAST_UPDATED_BY             CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID             CONSTANT '!LOAD_REQUEST_ID!'
,STATUS			             CONSTANT 'NEW'
)

