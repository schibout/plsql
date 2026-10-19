--------------------------------------------------------------------------------
-- $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_AP_INV_ATTACHED_DOCS.tab
-- Description      : Création de la table DKA_AP_INV_ATTACHED_DOCS
-- Auteur           : H. Descroizette(Capgemini)
-- Date de création : 22/05/2016
-- Doc. associée    : 
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    $apps_pwd $dka_pwd $tablespace_data $tablespace_index
--                    1- Password APPS
--                    2- Password DKA
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
CONNECT APPS/&1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA.DKA_AP_INV_ATTACHED_DOCS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA.DKA_AP_INV_ATTACHED_DOCS ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA.DKA_AP_INV_ATTACHED_DOCS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA.DKA_AP_INV_ATTACHED_DOCS (
  ORG_NAME                 VARCHAR2(240) not null,
  ORG_ID                   NUMBER(15),
  INVOICE_NUM              VARCHAR2(50) not null,
  INVOICE_ID               NUMBER(15) not null,
  VENDOR_ID                NUMBER(15) not null,
  VENDOR_NUM               VARCHAR2(30) not null,
  VENDOR_NAME              VARCHAR2(240) not null,
  VENDOR_SITE_ID           NUMBER(15),
  VENDOR_SITE_CODE         VARCHAR2(15) not null,
  INVOICE_TYPE_LOOKUP_CODE VARCHAR2(25),
  PAY_GROUP_LOOKUP_CODE    VARCHAR2(25),
  INVOICE_DATE             DATE,
  ATTACHED_DOCUMENT_ID     NUMBER not null,
  SEQ_NUM                  NUMBER not null,
  AUTOMATICALLY_ADDED_FLAG VARCHAR2(1) not null,
  STATUS                   VARCHAR2(30),
  DOCUMENT_ID              NUMBER not null,
  DATATYPE_ID              NUMBER not null,
  CATEGORY_ID              NUMBER not null,
  SECURITY_TYPE            NUMBER not null,
  SECURITY_ID              NUMBER,
  PUBLISH_FLAG             VARCHAR2(1) not null,
  IMAGE_TYPE               VARCHAR2(10),
  STORAGE_TYPE             NUMBER,
  USAGE_TYPE               VARCHAR2(1),
  START_DATE_ACTIVE        DATE,
  END_DATE_ACTIVE          DATE,
  DESCRIPTION              VARCHAR2(255),
  FILE_NAME                VARCHAR2(2048),
  MEDIA_ID                 NUMBER
);

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT DKA/&2
GRANT ALL ON DKA.DKA_AP_INV_ATTACHED_DOCS TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1
CREATE OR REPLACE SYNONYM DKA_AP_INV_ATTACHED_DOCS FOR DKA.DKA_AP_INV_ATTACHED_DOCS;

EXIT;
