--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : EDB286 
-- Nom              : DKA_EXPCDE_IVALUA_FILE.tab
-- Description      : Script de création de la table d'interface contenant les noms des fichiers à envoyer
--                    DKA_EXPCDE_IVALUA_FILE
-- Auteur           : Anas RAOUF (Capgemini)
-- Date de création : 04/01/2021
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
PROMPT DROP DE LA TABLE DKA_EXPCDE_IVALUA_FILE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_EXPCDE_IVALUA_FILE CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_EXPCDE_IVALUA_FILE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_EXPCDE_IVALUA_FILE
(
	FILE_NAME            VARCHAR2(60),
	NB_LINE              NUMBER,
	CREATED_BY           VARCHAR2(60), 
	CREATION_DATE        DATE
)
TABLESPACE &3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_EXPCDE_IVALUA_FILE TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1

DROP SYNONYM DKA_EXPCDE_IVALUA_FILE;

CREATE SYNONYM DKA_EXPCDE_IVALUA_FILE FOR DKA.DKA_EXPCDE_IVALUA_FILE;

SHOW ERRORS
EXIT;