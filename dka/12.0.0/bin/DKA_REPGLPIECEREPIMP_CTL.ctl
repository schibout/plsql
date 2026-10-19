----------------------------------------------------------------------
-- PROGRAM : DKA_REPGLPIECEREPIMP_CTL                                -
-- AUTEUR  : Redouane BELAYACHI / SOCIETE : CAPGEMINI                -
-- DATE    : 27/10/17                                                -
----------------------------------------------------------------------
-- APPELE PAR : DKA_REPGLPIECEREPIMP_LOADER                          -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Reprise des pièces répétitves                        -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.0                                        -
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
INTO TABLE DKA_REP_PIECES_TMP
--FIELDS TERMINATED BY ";" 
TRAILING NULLCOLS
(NOM_LOT                        CHAR TERMINATED BY ";"
,DESC_LOT                       CHAR TERMINATED BY ";"
,NOM_PIECE                      CHAR TERMINATED BY ";"
,TYPE_PIECE                     CHAR TERMINATED BY ";"
,FIN_PIECE                      DATE "DD/MM/YYYY" TERMINATED BY ";" 
,CUF_PIECE                      CHAR TERMINATED BY ";"
,NUM_LIGNE                      INTEGER EXTERNAL  TERMINATED BY ";" 
,CLE_OLD                        CHAR TERMINATED BY ";"
,DESC_LIGNE                     CHAR TERMINATED BY ";"
,PROJET_OLD                     CHAR TERMINATED BY ";"
,TYPE_DPSE_OLD                  CHAR TERMINATED BY ";"
,TYPE_EVT_OLD                   CHAR TERMINATED BY ";"
,NUM_LIG_FORM                   INTEGER EXTERNAL TERMINATED BY ";"
,OPER_FORM                      CHAR TERMINATED BY ";"
,MONTANT_FORM                   FLOAT EXTERNAL TERMINATED BY WHITESPACE "to_number(REPLACE(REPLACE(rtrim(:MONTANT_FORM),',','.'),' ',''))"
,CREATION_DATE                  SYSDATE
,CREATED_BY                     CONSTANT '!USER_ID!'
,LAST_UPDATE_DATE               SYSDATE
,LAST_UPDATED_BY                CONSTANT '!USER_ID!'
,LOAD_REQUEST_ID                CONSTANT '!LOAD_REQUEST_ID!'
,STATUT                         CONSTANT '-1'
)

