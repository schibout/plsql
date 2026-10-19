# $Header$

# dbdrv: exec fnd bin FNDLOAD bin &phase=daa+52 checkfile:~PROD:~PATH:~FILE &ui_apps 0 Y UPLOAD @FND:patch/115/import/afmdmsg.lct @~PROD:~PATH/~FILE
LANGUAGE = "US"
LDRCONFIG = "afmdmsg.lct 120.2.12020000.1"

#Source Database HELMAS

#RELEASE_NAME 12.2.4

# -- Begin Entity Definitions -- 

DEFINE FND_NEW_MESSAGES
  KEY   APPLICATION_SHORT_NAME          VARCHAR2(50)
  KEY   MESSAGE_NAME                    VARCHAR2(30)
  CTX   OWNER                           VARCHAR2(4000)
  BASE  LAST_UPDATE_DATE                VARCHAR2(10)
  CTX   MESSAGE_NUMBER                  VARCHAR2(50)
  TRANS MESSAGE_TEXT                    VARCHAR2(2000)
  CTX   DESCRIPTION                     VARCHAR2(240)
  CTX   TYPE                            VARCHAR2(30)
  CTX   MAX_LENGTH                      VARCHAR2(50)
  CTX   CATEGORY                        VARCHAR2(10)
  CTX   SEVERITY                        VARCHAR2(10)
  CTX   FND_LOG_SEVERITY                VARCHAR2(50)
END FND_NEW_MESSAGES

# -- End Entity Definitions -- 


BEGIN FND_NEW_MESSAGES "DKA" "DKA_IPOCDE_VM01"
  OWNER = "AAMENKOUR"
  LAST_UPDATE_DATE = "2020/06/25"
  MESSAGE_NUMBER = "*NULL*"
  MESSAGE_TEXT =
 "La commande ne peut pas être mise à jour car elle n'est pas rattachée à la même unité opérationnelle dans Oracle (UO Oracle = &UO_ORACLE et UO iValua = &UO_IVALUA)."
  DESCRIPTION = "*NULL*"
  TYPE = "30_PCT_EXPANSION_PROMPT"
  MAX_LENGTH = "*NULL*"
  CATEGORY = "*NULL*"
  SEVERITY = "*NULL*"
  FND_LOG_SEVERITY = "*NULL*"
END FND_NEW_MESSAGES

BEGIN FND_NEW_MESSAGES "DKA" "DKA_IPOCDE_VM02"
  OWNER = "AAMENKOUR"
  LAST_UPDATE_DATE = "2020/06/25"
  MESSAGE_NUMBER = "*NULL*"
  MESSAGE_TEXT =
 "La commande ne peut pas être mise à jour car elle n'est pas rattachée au même fournisseur dans Oracle (Frs Oracle = &FRNS_ORACLE et Frs iValua = &FRNS_IVALUA)."
  DESCRIPTION = "*NULL*"
  TYPE = "30_PCT_EXPANSION_PROMPT"
  MAX_LENGTH = "*NULL*"
  CATEGORY = "*NULL*"
  SEVERITY = "*NULL*"
  FND_LOG_SEVERITY = "*NULL*"
END FND_NEW_MESSAGES

BEGIN FND_NEW_MESSAGES "DKA" "DKA_IPOCDE_VM03"
  OWNER = "AAMENKOUR"
  LAST_UPDATE_DATE = "2020/06/25"
  MESSAGE_NUMBER = "*NULL*"
  MESSAGE_TEXT =
 "La commande ne peut pas être mise à jour car elle n'est pas rattachée au même site fournisseur dans Oracle (Site frs Oracle = &SFRNS_ORACLE et Site frs iValua = &SFRNS_IVALUA)."
  DESCRIPTION = "*NULL*"
  TYPE = "30_PCT_EXPANSION_PROMPT"
  MAX_LENGTH = "*NULL*"
  CATEGORY = "*NULL*"
  SEVERITY = "*NULL*"
  FND_LOG_SEVERITY = "*NULL*"
END FND_NEW_MESSAGES

BEGIN FND_NEW_MESSAGES "DKA" "DKA_IPOCDE_VM04"
  OWNER = "AAMENKOUR"
  LAST_UPDATE_DATE = "2020/06/25"
  MESSAGE_NUMBER = "*NULL*"
  MESSAGE_TEXT =
 "La commande ne peut pas être mise à jour car elle n'a pas la même devise dans Oracle (Devise Oracle = &CURR_ORACLE et Devise iValua = &CURR_IVALUA)"
  DESCRIPTION = "*NULL*"
  TYPE = "30_PCT_EXPANSION_PROMPT"
  MAX_LENGTH = "*NULL*"
  CATEGORY = "*NULL*"
  SEVERITY = "*NULL*"
  FND_LOG_SEVERITY = "*NULL*"
END FND_NEW_MESSAGES

BEGIN FND_NEW_MESSAGES "DKA" "DKA_IPOCDE_VM05"
  OWNER = "AAMENKOUR"
  LAST_UPDATE_DATE = "2020/06/25"
  MESSAGE_NUMBER = "*NULL*"
  MESSAGE_TEXT =
 "La commande ne peut pas être mise à jour car elle est au statut : &STATUT"
  DESCRIPTION = "*NULL*"
  TYPE = "30_PCT_EXPANSION_PROMPT"
  MAX_LENGTH = "*NULL*"
  CATEGORY = "*NULL*"
  SEVERITY = "*NULL*"
  FND_LOG_SEVERITY = "*NULL*"
END FND_NEW_MESSAGES

BEGIN FND_NEW_MESSAGES "DKA" "DKA_IPOCDE_VM06"
  OWNER = "AAMENKOUR"
  LAST_UPDATE_DATE = "2020/06/25"
  MESSAGE_NUMBER = "*NULL*"
  MESSAGE_TEXT =
 "La ligne de frais ou d'article ne peut pas être mise à jour car elle est annulée ou fermée définitivement."
  DESCRIPTION = "*NULL*"
  TYPE = "30_PCT_EXPANSION_PROMPT"
  MAX_LENGTH = "*NULL*"
  CATEGORY = "*NULL*"
  SEVERITY = "*NULL*"
  FND_LOG_SEVERITY = "*NULL*"
END FND_NEW_MESSAGES

BEGIN FND_NEW_MESSAGES "DKA" "DKA_IPOCDE_VM07"
  OWNER = "AAMENKOUR"
  LAST_UPDATE_DATE = "2020/06/25"
  MESSAGE_NUMBER = "*NULL*"
  MESSAGE_TEXT =
 "La ligne de frais ou d'article ne peut pas être mise à jour car elle est partiellement ou totalement facturée."
  DESCRIPTION = "*NULL*"
  TYPE = "30_PCT_EXPANSION_PROMPT"
  MAX_LENGTH = "*NULL*"
  CATEGORY = "*NULL*"
  SEVERITY = "*NULL*"
  FND_LOG_SEVERITY = "*NULL*"
END FND_NEW_MESSAGES

BEGIN FND_NEW_MESSAGES "DKA" "DKA_IPOCDE_VM08"
  OWNER = "SHAHIOUI"
  LAST_UPDATE_DATE = "2022/03/21"
  MESSAGE_NUMBER = "*NULL*"
  MESSAGE_TEXT =
 "La ligne d'article ne peut pas être mise à jour car elle est partiellement ou totalement réceptionnée."
  DESCRIPTION = "*NULL*"
  TYPE = "30_PCT_EXPANSION_PROMPT"
  MAX_LENGTH = "*NULL*"
  CATEGORY = "*NULL*"
  SEVERITY = "*NULL*"
  FND_LOG_SEVERITY = "*NULL*"
END FND_NEW_MESSAGES
