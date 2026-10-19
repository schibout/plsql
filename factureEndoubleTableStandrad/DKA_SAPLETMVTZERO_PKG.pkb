--------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM		  : DKA_TRACE_FOR_SOX.tab
-- DESCRIPTION	  : Script de création de la table DKA_TRACE_FOR_SOX.
--
-- AUTEUR	        : A.DELTOUR
-- DATE DE CREATION : 24/09/2007
-- DOC. ASSOCIEE    : 
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA
--                    en lui passant 3 paramètres :
--                           1) Password DKA
--                           2) Password APPS
--                           3) Tablespace des données pour schéma DKA
--                           
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------

CONNECT DKA/&1;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA_TRACE_FOR_SOX
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_TRACE_FOR_SOX CASCADE CONSTRAINTS ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_TRACE_FOR_SOX
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_TRACE_FOR_SOX
( REQUEST_ID                NUMBER,
  PROGRAM_SHORT_NAME        VARCHAR2(240),
  CREATED_BY                NUMBER,
  CREATION_DATE             DATE,
  LAST_UPDATE_DATE          DATE,
  LAST_UPDATED_BY           NUMBER,
  LAST_UPDATE_LOGIN         NUMBER,
  ACTION                    VARCHAR2(4000),
  ORG_ID                    NUMBER,             
  ATTRIBUTE1                VARCHAR2(240) ,
  ATTRIBUTE2                VARCHAR2(240),
  ATTRIBUTE3                VARCHAR2(240),
  ATTRIBUTE4                VARCHAR2(240),
  ATTRIBUTE5                VARCHAR2(240),
  ATTRIBUTE6                VARCHAR2(240),
  ATTRIBUTE7                VARCHAR2(240),
  ATTRIBUTE8                VARCHAR2(240),
  ATTRIBUTE9                VARCHAR2(240),
  ATTRIBUTE10               VARCHAR2(240),
  ATTRIBUTE11               VARCHAR2(240),
  ATTRIBUTE12               VARCHAR2(240),
  ATTRIBUTE13               VARCHAR2(240),
  ATTRIBUTE14               VARCHAR2(240),
  ATTRIBUTE15               VARCHAR2(240)
)
TABLESPACE &3
/
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_TRACE_FOR_SOX TO APPS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&2;

DROP SYNONYM DKA_TRACE_FOR_SOX;

CREATE SYNONYM DKA_TRACE_FOR_SOX FOR DKA.DKA_TRACE_FOR_SOX;

SHOW ERRORS;
EXIT;
