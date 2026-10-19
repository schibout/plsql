--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : Contrôle de flux OA
-- Nom              : DKA_IGL_INTERFACE_EAI.tab
-- Description      : Script de création de la table contenant les request_id
--                    DKA_IGL_INTERFACE_EAI
-- Auteur           : B.COUDRIER (Capgemini)
-- Date de création : 09/10/2014
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- Password APPS
--                    2- Password DKA
--                    3- Tablespace des données pour le schéma EAI
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------


CONNECT DKA/&1

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA_IGL_INTERFACE_EAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_IGL_INTERFACE_EAI CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_IGL_INTERFACE_EAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_IGL_INTERFACE_EAI
(
  GROUP_ID                           	NUMBER,
  INTERFACE_RUN_ID                      NUMBER,
  SET_OF_BOOK_ID                        NUMBER,
  REQUEST_ID                       		NUMBER,
  STATUS                           		VARCHAR2(50),
  DATE_INSERTION						DATE
)
TABLESPACE &3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_IGL_INTERFACE_EAI TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&2

DROP SYNONYM DKA_IGL_INTERFACE_EAI;

CREATE SYNONYM DKA_IGL_INTERFACE_EAI FOR DKA.DKA_IGL_INTERFACE_EAI;

SHOW ERRORS
EXIT;