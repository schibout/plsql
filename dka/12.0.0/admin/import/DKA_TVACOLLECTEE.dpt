# $Header: I:/developpement/CVSROOT/ETA030\040-\040TVA\040Collectée\040-\040état\040préparatoire/Automatisation\040ControlM/DKA_TVACOLLECTEE/load/DKA_TVACOLLECTEE.dpt,v 1.1.1.1 2004/06/25 15:02:09 flechene Exp $

# 
LANGUAGE = "US"
LDRCONFIG = "DKA_XX_PARAM.lct"

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

# Début ajout TB du 26/12/2006
BEGIN DKA_PARAMETER "DKA_GL_DECLAR_TVA" "CPTE_TVA_EXO"
  DESCRIPTION = "Liste des comptes de produits avec possible TVA exonérée"
  DATA_TYPE = "VARCHAR2"
  VARCHAR2_VALUE = "DKA_CPTE_PRDT_TVA_EXO"
END DKA_PARAMETER
# Fin ajout TB du 26/12/2006

BEGIN DKA_PARAMETER "DKA_TVACOLLECTEE" "AR_RESPONSIBILITY_KEY"
  DESCRIPTION = "Responsabilité de lancement des traitements AR"
  TABLE_NAME = ""
  COLUMN_NAME = ""
  DATA_TYPE = "VARCHAR2"
#  VARCHAR2_VALUE = "ARXXXX ADMINISTRATEUR" PHENIX 2004
# Début modification EMA du 12/07/2005
#  VARCHAR2_VALUE = "DK_RECEIVABLES_MANAGER" PHENIX 2004
  VARCHAR2_VALUE = "DKA_ETATS" PHENIX 2004
# Fin modification EMA du 12/07/2005
END DKA_PARAMETER
