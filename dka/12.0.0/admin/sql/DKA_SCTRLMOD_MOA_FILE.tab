--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : Automatisation extraction des SQLs du matin
-- Nom              : DKA_SCTRLMOD_MOA_FILE.tab
-- Description      : Script de création de la table d'interface des fichiers
--                    DKA_SCTRLMOD_MOA_FILE
-- Auteur           : Anas RAOUF (Capgemini)
-- Date de création : 26/11/2020
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- Password APPS
--                    2- Password DKA
--                    3- Tablespace des données pour le schéma DKA
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------


CONNECT DKA/&2

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA_SCTRLMOD_MOA_FILE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_SCTRLMOD_MOA_FILE CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_SCTRLMOD_MOA_FILE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_SCTRLMOD_MOA_FILE
(
  ENTITE	                   	VARCHAR2(10),
  MODULE    	                VARCHAR2(30),
  REQUEST_ID					NUMBER(30),
  FILE_NAME                  	VARCHAR2(60),
  NB_LINE						NUMBER,
  CREATED_BY					VARCHAR2(60),
  CREATION_DATE					DATE
)
TABLESPACE &3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SCTRLMOD_MOA_FILE TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1

DROP SYNONYM DKA_SCTRLMOD_MOA_FILE;

CREATE SYNONYM DKA_SCTRLMOD_MOA_FILE FOR DKA.DKA_SCTRLMOD_MOA_FILE;

SHOW ERRORS
EXIT;