# $Header$

# dbdrv: exec fnd bin FNDLOAD bin &phase=daa+64 checkfile:~PROD:~PATH:~FILE &ui_apps 0 Y UPLOAD @FND:patch/115/import/afcprset.lct @~PROD:~PATH/~FILE
LANGUAGE = "US"
LDRCONFIG = "afcprset.lct 120.3.12020000.2"

#Source Database HELMAS

#RELEASE_NAME 12.2.4

# -- Begin Entity Definitions -- 

DEFINE REQ_SET_LINKS
  KEY   APPLICATION_SHORT_NAME          VARCHAR2(50)
  KEY   REQUEST_SET_NAME                VARCHAR2(30)
  BASE  RSET                            REFERENCES REQ_SET
  CTX   OWNER                           VARCHAR2(4000)
  BASE  START_STAGE_NAME                VARCHAR2(30)
  BASE  LAST_UPDATE_DATE                VARCHAR2(10)

  DEFINE STAGE_LINKS
    KEY   STAGE_NAME                      VARCHAR2(30)
    CTX   OWNER                           VARCHAR2(4000)
    BASE  SUCCESS_LINK                    VARCHAR2(30)
    BASE  WARNING_LINK                    VARCHAR2(30)
    BASE  ERROR_LINK                      VARCHAR2(30)
    BASE  LAST_UPDATE_DATE                VARCHAR2(10)
  END STAGE_LINKS
END REQ_SET_LINKS

DEFINE REQ_SET
  KEY   APPLICATION_SHORT_NAME          VARCHAR2(50)
  KEY   REQUEST_SET_NAME                VARCHAR2(30)
  CTX   OWNER                           VARCHAR2(4000)
  BASE  ALLOW_CONSTRAINTS_FLAG          VARCHAR2(1)
  BASE  PRINT_TOGETHER_FLAG             VARCHAR2(1)
  BASE  START_DATE_ACTIVE               VARCHAR2(11)
  BASE  START_STAGE_NAME                VARCHAR2(30)
  BASE  END_DATE_ACTIVE                 VARCHAR2(11)
  BASE  CONCURRENT_PROGRAM_NAME         VARCHAR2(30)
  BASE  OWNER_USER_NAME                 VARCHAR2(100)
  BASE  PRINTER                         VARCHAR2(30)
  BASE  PRINT_STYLE                     VARCHAR2(30)
  BASE  RECALC_PARAMETERS               VARCHAR2(1)
  TRANS USER_REQUEST_SET_NAME           VARCHAR2(240)
  TRANS DESCRIPTION                     VARCHAR2(240)
  BASE  LAST_UPDATE_DATE                VARCHAR2(10)

  DEFINE STAGE
    KEY   STAGE_NAME                      VARCHAR2(30)
    CTX   OWNER                           VARCHAR2(4000)
    BASE  CRITICAL                        VARCHAR2(1)
    BASE  OUTCOME                         VARCHAR2(1)
    BASE  ALLOW_CONSTRAINTS_FLAG          VARCHAR2(1)
    BASE  DISPLAY_SEQUENCE                VARCHAR2(50)
    BASE  FUNCTION_APPLICATION            VARCHAR2(50)
    BASE  FUNCTION                        VARCHAR2(30)
    BASE  SUCCESS_LINK                    VARCHAR2(30)
    BASE  WARNING_LINK                    VARCHAR2(30)
    BASE  ERROR_LINK                      VARCHAR2(30)
    BASE  CONCURRENT_PROGRAM_NAME         VARCHAR2(30)
    TRANS USER_STAGE_NAME                 VARCHAR2(240)
    TRANS DESCRIPTION                     VARCHAR2(240)
    BASE  LAST_UPDATE_DATE                VARCHAR2(10)

    DEFINE STAGE_PROG
      KEY   SEQUENCE                        VARCHAR2(50)
      CTX   OWNER                           VARCHAR2(4000)
      BASE  PROGRAM_APPLICATION             VARCHAR2(50)
      BASE  PROGRAM_NAME                    VARCHAR2(30)
      BASE  NLS_LANGUAGE                    VARCHAR2(30)
      BASE  NLS_TERRITORY                   VARCHAR2(30)
      BASE  CRITICAL                        VARCHAR2(1)
      BASE  NUMBER_OF_COPIES                VARCHAR2(50)
      BASE  PRINTER                         VARCHAR2(30)
      BASE  PRINT_STYLE                     VARCHAR2(30)
      BASE  SAVE_OUTPUT_FLAG                VARCHAR2(1)
      BASE  LAST_UPDATE_DATE                VARCHAR2(10)

      DEFINE PROG_ARGS
        KEY   DESC_FLEX_APPL                  VARCHAR2(50)
        KEY   DESC_FLEX_NAME                  VARCHAR2(50)
        KEY   COL_NAME                        VARCHAR2(30)
        CTX   OWNER                           VARCHAR2(4000)
        BASE  DISPLAY_FLAG                    VARCHAR2(1)
        BASE  INSERT_FLAG                     VARCHAR2(1)
        BASE  UPDATE_FLAG                     VARCHAR2(1)
        BASE  DEFAULT_TYPE                    VARCHAR2(1)
        BASE  DEFAULT_VALUE                   VARCHAR2(2000)
        BASE  SHARED_PARAMETER_NAME           VARCHAR2(30)
        BASE  LAST_UPDATE_DATE                VARCHAR2(10)
      END PROG_ARGS
    END STAGE_PROG
  END STAGE
END REQ_SET

# -- End Entity Definitions -- 


BEGIN REQ_SET "DKA" "DKA_SJTGLDATAJ"
  OWNER = "MTIABLIK"
  ALLOW_CONSTRAINTS_FLAG = "N"
  PRINT_TOGETHER_FLAG = "N"
  START_DATE_ACTIVE = "2005/07/06"
  START_STAGE_NAME = "STAGE10"
  RECALC_PARAMETERS = "N"
  USER_REQUEST_SET_NAME = "DKA : Prise en compte des données GL du jour J"
  DESCRIPTION = "Prise en compte des données GL du jour J"
  LAST_UPDATE_DATE = "2018/08/12"

  BEGIN STAGE "STAGE10"
    OWNER = "ARAOUF"
    CRITICAL = "Y"
    OUTCOME = "C"
    ALLOW_CONSTRAINTS_FLAG = "N"
    DISPLAY_SEQUENCE = "10"
    FUNCTION_APPLICATION = "FND"
    FUNCTION = "FNDRSSTE"
    SUCCESS_LINK = "STAGE20"
    WARNING_LINK = "STAGE20"
    ERROR_LINK = "STAGE20"
    USER_STAGE_NAME = "DKA : Posting GL"
    DESCRIPTION = "Sélectionne automatique les lots à imputer"
    LAST_UPDATE_DATE = "2021/02/10"
  
    BEGIN STAGE_PROG "1"
      OWNER = "ARAOUF"
      PROGRAM_APPLICATION = "DKA"
      PROGRAM_NAME = "DKA_SGLIMPUTATION"
      CRITICAL = "Y"
      NUMBER_OF_COPIES = "0"
      SAVE_OUTPUT_FLAG = "Y"
      LAST_UPDATE_DATE = "2021/02/10"
    
    END STAGE_PROG
    
  END STAGE
  
  BEGIN STAGE "STAGE20"
    OWNER = "ORACLE12.2.4"
    CRITICAL = "N"
    OUTCOME = "C"
    ALLOW_CONSTRAINTS_FLAG = "N"
    DISPLAY_SEQUENCE = "20"
    FUNCTION_APPLICATION = "FND"
    FUNCTION = "FNDRSSTE"
    USER_STAGE_NAME = "DKA : Traitement de tranfert des écritures GL vers PA"
    DESCRIPTION = "Transfert des écritures GL sur projet vers PA"
    LAST_UPDATE_DATE = "2016/10/17"
  
    BEGIN STAGE_PROG "10"
      OWNER = "ORACLE12.2.4"
      PROGRAM_APPLICATION = "DKA"
      PROGRAM_NAME = "DKA_SPACUTOFF_TRANSFER"
      CRITICAL = "Y"
      NUMBER_OF_COPIES = "0"
      SAVE_OUTPUT_FLAG = "Y"
      LAST_UPDATE_DATE = "2016/10/17"
    
    END STAGE_PROG
    
  END STAGE
  
END REQ_SET

BEGIN REQ_SET_LINKS "DKA" "DKA_SJTGLDATAJ"
  RSET = "DKA" "DKA_SJTGLDATAJ"
  OWNER = "MTIABLIK"
  START_STAGE_NAME = "STAGE10"
  LAST_UPDATE_DATE = "2018/08/12"

  BEGIN STAGE_LINKS "STAGE10"
    OWNER = "ARAOUF"
    SUCCESS_LINK = "STAGE20"
    WARNING_LINK = "STAGE20"
    ERROR_LINK = "STAGE20"
    LAST_UPDATE_DATE = "2021/02/10"
  END STAGE_LINKS
  
  BEGIN STAGE_LINKS "STAGE20"
    OWNER = "ORACLE12.2.4"
    LAST_UPDATE_DATE = "2016/10/17"
  END STAGE_LINKS
  
END REQ_SET_LINKS

