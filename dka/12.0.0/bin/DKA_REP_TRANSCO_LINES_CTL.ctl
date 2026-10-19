----------------------------------------------------------------------
-- PROGRAM : DKA_REPAPFRSIMP                                         -
-- AUTEUR  : JJA / SOCIETE : CAPGEMINI                               -
-- DATE    : 14/04/16                                                -
----------------------------------------------------------------------
-- APPELE PAR : /                                                    -
-- FONCTION   : Fichier de controle sql*loader                       -
--              Transcodification                           				 -
--                                                                   -
----------------------------------------------------------------------
-- Version              : 1.0                                        -
-- PROGRAMME MODIFIE LE :                                            -
-- PAR                  :                                            -
-- OBJET                :                                            -
--                                                                   -
----------------------------------------------------------------------
LOAD DATA
APPEND
INTO TABLE DKA_REP_TRANSCO_LINES
FIELDS TERMINATED BY "|" 
TRAILING NULLCOLS
( TRANSCO_NAME      "RTRIM(LTRIM(:TRANSCO_NAME))",
  COLUMN_01         "RTRIM(LTRIM(:COLUMN_01))",
  COLUMN_02         "RTRIM(LTRIM(:COLUMN_02))",
  COLUMN_03         "RTRIM(LTRIM(:COLUMN_03))",
  COLUMN_04         "RTRIM(LTRIM(:COLUMN_04))",
  COLUMN_05         "RTRIM(LTRIM(:COLUMN_05))",
  COLUMN_06         "RTRIM(LTRIM(:COLUMN_06))",
  COLUMN_07         "RTRIM(LTRIM(:COLUMN_07))",
  COLUMN_08         "RTRIM(LTRIM(:COLUMN_08))",
  COLUMN_09         "RTRIM(LTRIM(:COLUMN_09))",
  COLUMN_10         "RTRIM(LTRIM(:COLUMN_10))",
  COLUMN_11         "RTRIM(LTRIM(:COLUMN_11))",
  COLUMN_12         "RTRIM(LTRIM(:COLUMN_12))",
  OUT_01            "RTRIM(LTRIM(:OUT_01))",
  OUT_02            "RTRIM(LTRIM(:OUT_02))",
  OUT_03            "RTRIM(LTRIM(:OUT_03))",
  OUT_04            "RTRIM(LTRIM(:OUT_04))",
  OUT_05            "RTRIM(LTRIM(:OUT_05))",           
  OUT_06            "RTRIM(LTRIM(:OUT_06))",
  OUT_07            "RTRIM(LTRIM(:OUT_07))",
  OUT_08            "RTRIM(LTRIM(:OUT_08))",
  OUT_09            "RTRIM(LTRIM(:OUT_09))",
  OUT_10            "RTRIM(LTRIM(:OUT_10))",
  OUT_11            "RTRIM(LTRIM(:OUT_11))",
  OUT_12            "RTRIM(LTRIM(:OUT_12))",
  TRANSCO_LINE_ID   "DKA_REP_TRANSCO_LINES_S.nextval",
  START_DATE_ACTIVE SYSDATE,
  ENABLED_FLAG      CONSTANT 'Y',
  CREATION_DATE     SYSDATE,
  CREATED_BY        CONSTANT '-1',
  LAST_UPDATE_DATE  SYSDATE,
  LAST_UPDATED_BY   CONSTANT '-1',
  LAST_UPDATE_LOGIN CONSTANT '-1'		
)          
