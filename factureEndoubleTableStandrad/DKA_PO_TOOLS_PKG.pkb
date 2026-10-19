--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : Contrôle de flux OA
-- Nom              : DKA_SCTLFLUX_EAI.tab
-- Description      : Script de création de la table d'interface 
--                    DKA_SCTLFLUX_EAI
-- Auteur           : B.COUDRIER (Capgemini)
-- Date de création : 03/10/2014
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


CONNECT DKA/&2

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA_SCTLFLUX_EAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_SCTLFLUX_EAI CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_SCTLFLUX_EAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_SCTLFLUX_EAI
(
  CODE_FOLIO                           	VARCHAR2(150),
  DATE_EXEC                        		VARCHAR2(10),
  NB_PIECE                              NUMBER,
  DEBIT                          		NUMBER,
  CREDIT                           		NUMBER,
  FICHIER								VARCHAR2(150),
  TRAITE                            	NUMBER,
  N_TRAITEMENT                          NUMBER,
  DATE_DEBUT							DATE,
  DATE_FIN                          	DATE,
  CREATED_BY                   			NUMBER,
  CREATION_DATE                         DATE
)
TABLESPACE &3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SCTLFLUX_EAI TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1

DROP SYNONYM DKA_SCTLFLUX_EAI;

CREATE SYNONYM DKA_SCTLFLUX_EAI FOR DKA.DKA_SCTLFLUX_EAI;

SHOW ERRORS
EXIT;