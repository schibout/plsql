-------------------------------------------------------------------------------
-- Capgemini
-- Projet            : DALKIA Oracle Applications
-- Auteur            : Eric MATUSZEWSKI
-- Date Création     : 12/01/2007
-- Version livrables : V01
--------------------------------------------------------------------------------
-- NOM         : DKA_GL_JE_LINES_N1.ind
-- DESCRIPTION : Script de création de l'index DKA_GL_JE_LINES_N1 sur la table GL_JE_LINES
-- COMMENTAIRE : A exécuter sous SQLPLUS avec le user DKA
--               en lui passant 3 paramètres :
--                      1) Password DKA
--                      2) Password APPS
--                      3) Tablespace des données pour schéma DKA
--                      4) Tablespace des index   pour schéma DKA
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE L'INDEX DKA_GL_JE_LINES_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX DKA_GL_JE_LINES_N1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L'INDEX DKA_GL_JE_LINES_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX DKA_GL_JE_LINES_N1
ON GL.GL_JE_LINES (REFERENCE_3, DESCRIPTION)
TABLESPACE APPS_TS_TX_DATA
PCTFREE    10
INITRANS   11
MAXTRANS   255
STORAGE (INITIAL     100M
         NEXT        100M
         MINEXTENTS  1
         MAXEXTENTS  UNLIMITED
         PCTINCREASE 0);

EXIT
