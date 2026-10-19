--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Nom              : DKA_SAPFRS_MAJ_HEADERS.tab
--                    DKA_SAPFRS_MAJ_HEADERS
-- Auteur           : Anas RAOUF (Capgemini)
-- Date de création : 23/12/2021
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


CONNECT DKA/&&2

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA_SAPFRS_MAJ_HEADERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_SAPFRS_MAJ_HEADERS CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_SAPFRS_MAJ_HEADERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_SAPFRS_MAJ_HEADERS
(
	 SEQ_ID              NUMBER(15),
	 VENDOR_ID           NUMBER(15),
	 LAST_UPDATE_DATE    DATE,
	 LAST_UPDATED_BY     NUMBER(15),
	 ACTION_TYPE         VARCHAR2(20),
	 ITEM                VARCHAR2(80),
	 OLD_ITEM_VALUE      VARCHAR2(250),
	 NEW_ITEM_VALUE      VARCHAR2(250)
)
TABLESPACE &&3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SAPFRS_MAJ_HEADERS TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&&1

DROP SYNONYM DKA_SAPFRS_MAJ_HEADERS;

CREATE SYNONYM DKA_SAPFRS_MAJ_HEADERS FOR DKA.DKA_SAPFRS_MAJ_HEADERS;

SHOW ERRORS
EXIT;