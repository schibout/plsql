# $Header$

# dbdrv: exec fnd bin FNDLOAD bin &phase=daa+51 checkfile:~PROD:~PATH:~FILE &ui_apps 0 Y UPLOAD @FND:patch/115/import/aflvmlu.lct @~PROD:~PATH/~FILE
LANGUAGE = "F"
LDRCONFIG = "aflvmlu.lct 115.19"

#Source Database VU2OAP

# -- Begin Entity Definitions -- 

DEFINE FND_LOOKUP_TYPE
  KEY   VIEW_APPSNAME                   VARCHAR2(50)
  KEY   LOOKUP_TYPE                     VARCHAR2(30)
  CTX   APPLICATION_SHORT_NAME          VARCHAR2(50)
  BASE  CUSTOMIZATION_LEVEL             VARCHAR2(1)
  CTX   OWNER                           VARCHAR2(4000)
  BASE  LAST_UPDATE_DATE                VARCHAR2(10)
  TRANS MEANING                         VARCHAR2(80)
  TRANS DESCRIPTION                     VARCHAR2(240)

  DEFINE FND_LOOKUP_VALUE
    KEY   LOOKUP_CODE                     VARCHAR2(30)
    BASE  ENABLED_FLAG                    VARCHAR2(1)
    BASE  START_DATE_ACTIVE               VARCHAR2(10)
    BASE  END_DATE_ACTIVE                 VARCHAR2(10)
    BASE  TERRITORY_CODE                  VARCHAR2(2)
    BASE  TAG                             VARCHAR2(30)
    BASE  ATTRIBUTE_CATEGORY              VARCHAR2(30)
    BASE  ATTRIBUTE1                      VARCHAR2(150)
    BASE  ATTRIBUTE2                      VARCHAR2(150)
    BASE  ATTRIBUTE3                      VARCHAR2(150)
    BASE  ATTRIBUTE4                      VARCHAR2(150)
    BASE  ATTRIBUTE5                      VARCHAR2(150)
    BASE  ATTRIBUTE6                      VARCHAR2(150)
    BASE  ATTRIBUTE7                      VARCHAR2(150)
    BASE  ATTRIBUTE8                      VARCHAR2(150)
    BASE  ATTRIBUTE9                      VARCHAR2(150)
    BASE  ATTRIBUTE10                     VARCHAR2(150)
    BASE  ATTRIBUTE11                     VARCHAR2(150)
    BASE  ATTRIBUTE12                     VARCHAR2(150)
    BASE  ATTRIBUTE13                     VARCHAR2(150)
    BASE  ATTRIBUTE14                     VARCHAR2(150)
    BASE  ATTRIBUTE15                     VARCHAR2(150)
    CTX   OWNER                           VARCHAR2(4000)
    BASE  LAST_UPDATE_DATE                VARCHAR2(10)
    TRANS MEANING                         VARCHAR2(80)
    TRANS DESCRIPTION                     VARCHAR2(240)
  END FND_LOOKUP_VALUE
END FND_LOOKUP_TYPE

# -- End Entity Definitions -- 


BEGIN FND_LOOKUP_TYPE "SQLAP" "AP_WFAPPROVAL_STATUS"
  APPLICATION_SHORT_NAME = "SQLAP"
  CUSTOMIZATION_LEVEL = "S"
  OWNER = "ORACLE"
  LAST_UPDATE_DATE = "2002/01/30"
  MEANING = "Statut d'approbation d'Oracle Payables"
  DESCRIPTION =
 "Statut d'approbation pour le processus de workflow d'approbation de facture"

  BEGIN FND_LOOKUP_VALUE "DKA_ATTENTE"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "En attente"
    DESCRIPTION = "En attente"
  END FND_LOOKUP_VALUE

  BEGIN FND_LOOKUP_VALUE "DKA_REFUSE"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Refus de reglement"
    DESCRIPTION = "Refus de reglement"
  END FND_LOOKUP_VALUE

  BEGIN FND_LOOKUP_VALUE "DKA_NOTIF_TRAITEE"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Notification traitée"
    DESCRIPTION = "Notification traitée"
  END FND_LOOKUP_VALUE
  
  BEGIN FND_LOOKUP_VALUE "DKA_APPROVE_OI"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Facture traitée (déblocage du blocage)"
    DESCRIPTION = "Facture traitée (déblocage du blocage)"
  END FND_LOOKUP_VALUE
  
  BEGIN FND_LOOKUP_VALUE "DKA_FOURN_CREE"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Création traitée"
    DESCRIPTION = "Création traitée"
  END FND_LOOKUP_VALUE    

  BEGIN FND_LOOKUP_VALUE "DKA_REFUS_CREATION"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Refus de création"
    DESCRIPTION = "Refus de création"
  END FND_LOOKUP_VALUE 

  BEGIN FND_LOOKUP_VALUE "DKA_APPROVE"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Validation"
    DESCRIPTION = "Validation"
  END FND_LOOKUP_VALUE 

  BEGIN FND_LOOKUP_VALUE "DKA_AUTRES"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Autres"
    DESCRIPTION = "Autres"
  END FND_LOOKUP_VALUE 
  
  BEGIN FND_LOOKUP_VALUE "DKA_FORWARD_OI"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Création fournisseur/site"
    DESCRIPTION = "Création fournisseur/site"
  END FND_LOOKUP_VALUE
  
  BEGIN FND_LOOKUP_VALUE "DKA_FORWARD"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Retransmettre"
    DESCRIPTION = "Retransmettre"
  END FND_LOOKUP_VALUE
  
  BEGIN FND_LOOKUP_VALUE "DKA_FORWARD_BAP"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/20"
    MEANING = "Imputation + BAP"
    DESCRIPTION = "Imputation + BAP"
  END FND_LOOKUP_VALUE

  BEGIN FND_LOOKUP_VALUE "DKA_SOUMIS"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/03/28"
    MEANING = "Soumis"
    DESCRIPTION = "Soumis"
  END FND_LOOKUP_VALUE
  
  BEGIN FND_LOOKUP_VALUE "DKA_APPROVE_ECART_PRIX"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/04/04"
    MEANING = "Facture traitée"
    DESCRIPTION = "Facture traitée"
  END FND_LOOKUP_VALUE
  
  BEGIN FND_LOOKUP_VALUE "DKA_REAFFECTATION"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/04/04"
    MEANING = "Réaffectation"
    DESCRIPTION = "Réaffectation"
  END FND_LOOKUP_VALUE
  
  BEGIN FND_LOOKUP_VALUE "DKA_REFUS"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/04/04"
    MEANING = "Mise en litige"
    DESCRIPTION = "Mise en litige"
  END FND_LOOKUP_VALUE

  BEGIN FND_LOOKUP_VALUE "DKA_SAISIE_RECEPT"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/04/04"
    MEANING = "Saisie réception sous SSP"
    DESCRIPTION = "Saisie réception sous SSP"
  END FND_LOOKUP_VALUE 

  BEGIN FND_LOOKUP_VALUE "DKA_ECART_QTY_ORD"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/04/04"
    MEANING = "Acceptation de l'écart"
    DESCRIPTION = "Acceptation de l'écart"
  END FND_LOOKUP_VALUE 

  BEGIN FND_LOOKUP_VALUE "DKA_FWD_AFFACTURAGE"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/04/04"
    MEANING = "Notificaton traitée - Réaffectation CSP anomalies"
    DESCRIPTION = "Notificaton traitée - Réaffectation CSP anomalies"
  END FND_LOOKUP_VALUE 

  BEGIN FND_LOOKUP_VALUE "DKA_ERR_RETRANSMIS"
    ENABLED_FLAG = "Y"
    OWNER = "CAPTECH"
    LAST_UPDATE_DATE = "2008/04/04"
    MEANING = "Retourner"
    DESCRIPTION = "Retourner"
  END FND_LOOKUP_VALUE 

END FND_LOOKUP_TYPE
