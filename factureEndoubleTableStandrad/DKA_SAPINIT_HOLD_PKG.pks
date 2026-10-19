--------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM		  : DKA_CONTROLE_REFAC.tab
-- DESCRIPTION	  : Script de création de la table DKA_CONTROLE_REFAC.
--
-- AUTEUR	        : E.MATUSZEWSKI
-- DATE DE CREATION : 29/11/2006
-- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA
--                    en lui passant 4 paramètres :
--                           1) Password DKA
--                           2) Password APPS
--                           3) Tablespace des données pour schéma DKA
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------

CONNECT DKA/&1;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA_CONTROLE_REFAC (owner=DKA)
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_CONTROLE_REFAC CASCADE CONSTRAINTS ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_CONTROLE_REFAC
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_CONTROLE_REFAC
(
  TRANSACTION_SOURCE    VARCHAR2(240),
  FROM_ORG_ID           NUMBER(15),
  FROM_ORG_NAME         VARCHAR2(150),
  FROM_ORG_NAME_PROJECT VARCHAR2(150),
  TO_ORG_ID             NUMBER(15),
  TO_ORG_NAME           VARCHAR2(240),
  TO_ORG_NAME_PROJECT   VARCHAR2(240),
  FROM_PROJECT_ID       NUMBER(15),
  FROM_TASK_ID          NUMBER(15),
  TO_PROJECT_ID         NUMBER(15),
  TO_TASK_ID            NUMBER(15),
  FROM_ACCT_CENTER      VARCHAR2(150),
  TO_ACCT_CENTER        VARCHAR2(150),
  CREATE_AP_DATA_FLAG   VARCHAR2(150),
  CREATE_AR_DATA_FLAG   VARCHAR2(150),
  EXPENDITURE_ITEM_ID   NUMBER,
  EVENT_ID              NUMBER,
  DESCRIPTION           VARCHAR2(240),
  PA_CR_CCID            NUMBER(15),
  PA_DR_CCID            NUMBER(15),
  QUANTITY              NUMBER(22,5),
  ORIG_TRANSACTION_DATE DATE,
  GL_DATE               DATE,
  ORIG_TRANSACTION_TYPE VARCHAR2(150),
  AR_EVENT_TYPE         VARCHAR2(150),
  AP_EXPENDITURE_TYPE   VARCHAR2(150),
  AMOUNT                NUMBER(22,5)
)
TABLESPACE &3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_CONTROLE_REFAC TO APPS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&2;

DROP SYNONYM DKA_CONTROLE_REFAC;

CREATE SYNONYM DKA_CONTROLE_REFAC FOR DKA.DKA_CONTROLE_REFAC;

SHOW ERRORS;
EXIT;

