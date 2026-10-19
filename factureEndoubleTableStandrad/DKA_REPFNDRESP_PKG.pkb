# $Header$
# $Id: DKA_SAPWFCSP.dpt 1668 2009-03-27 14:53:15Z CORP\viknab $

# 
LANGUAGE = "F"
LDRCONFIG = "DKA_XX_PARAM.lct"

#Source Database VU1OAP

# -- Begin Entity Definitions -- 

DEFINE DKA_PARAMETER
  KEY   PROGRAM_CODE                    VARCHAR2(50)
  KEY   PARAMETER_NAME                  VARCHAR2(50)
  BASE  DESCRIPTION                     VARCHAR2(255)
  BASE  TABLE_NAME                      VARCHAR2(100)
  BASE  COLUMN_NAME                     VARCHAR2(100)
  BASE  DATA_TYPE                       VARCHAR2(100)
  BASE  VARCHAR2_VALUE                  VARCHAR2(50)
  BASE  NUMBER_VALUE                    VARCHAR2(30)
  BASE  DATE_VALUE                      VARCHAR2(19)
  BASE  BOOLEAN_VALUE                   VARCHAR2(1)
END DKA_PARAMETER

# -- End Entity Definitions -- 

BEGIN DKA_PARAMETER "DKA_SAPWFCSP" "NB_JOURS_REL_MOTIF_TERRAIN"
  DESCRIPTION =
 "Timeout d'une notif terrain (en minutes) avant relance"
  DATA_TYPE = "NUMBER"
  NUMBER_VALUE = "14400"
END DKA_PARAMETER

BEGIN DKA_PARAMETER "DKA_SAPWFCSP" "NB_JOURS_REL_MOTIF_CSP"
  DESCRIPTION =
 "Timeout d'une notif CSP (en minutes) avant relance"
  DATA_TYPE = "NUMBER"
  NUMBER_VALUE = "7200"
END DKA_PARAMETER

BEGIN DKA_PARAMETER "DKA_SAPWFCSP" "METHODE"
  DESCRIPTION =
 "Périmetre d'intervention des déblocages"
  DATA_TYPE = "VARCHAR2"
  VARCHAR2_VALUE = "JOURNALIER"
END DKA_PARAMETER
