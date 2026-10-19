--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : Automatisation extraction des SQLs du matin
-- Nom              : DKA_SAPCDE_CITY_TMP.tab
-- Description      : Script de création de la table temporaire
--                    DKA_SAPCDE_CITY_TMP
-- Auteur           : Anas RAOUF (Capgemini)
-- Date de création : 05/05/2021
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
PROMPT DROP DE LA TABLE DKA_SAPCDE_CITY_TMP
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_SAPCDE_CITY_TMP CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_SAPCDE_CITY_TMP
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_SAPCDE_CITY_TMP
(
	RECORD_ID                 NUMBER(30),
    LINE_NUMBER               VARCHAR2(30),
	UO_FACTURE                VARCHAR2(30),  
	INVOICE_NUM               VARCHAR2(40),  
	ORG_ID_FACT               NUMBER(30),  
	FOURN_FACT                VARCHAR2(240),  
	NUM_FOURN_FACT            VARCHAR2(30),  
    NUM_CMD                   VARCHAR2(70),
    UO_CMD                    VARCHAR2(30),
    FOURN_CMD                 VARCHAR2(240),
    NUM_FOURN_CMD             VARCHAR2(30),
    ORG_ID_CMD                NUMBER(30),
    STATUT                    VARCHAR2(20), 
	REQUEST_ID                NUMBER(30),
	CREATION_DATE             DATE,        
	CREATED_BY                NUMBER(30),   
	LAST_UPDATE_DATE          DATE,  
	LAST_UPDATED_BY           NUMBER(30)
)
TABLESPACE &3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SAPCDE_CITY_TMP TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1

DROP SYNONYM DKA_SAPCDE_CITY_TMP;

CREATE SYNONYM DKA_SAPCDE_CITY_TMP FOR DKA.DKA_SAPCDE_CITY_TMP;

SHOW ERRORS
EXIT;