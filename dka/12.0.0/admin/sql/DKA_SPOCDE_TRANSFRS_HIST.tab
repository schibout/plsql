--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : EDB286
-- Nom              : DKA_SPOCDE_TRANSFRS_HIST.tab
-- Description      : Script de création de la table d'interface 
--                    DKA_SPOCDE_TRANSFRS_HIST
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
PROMPT DROP DE LA TABLE DKA_SPOCDE_TRANSFRS_HIST
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_SPOCDE_TRANSFRS_HIST CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_SPOCDE_TRANSFRS_HIST
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_SPOCDE_TRANSFRS_HIST
(
	RECORD_ID                 NUMBER(30), 
	PO_HEADER_ID              NUMBER(30),  
	OLD_VENDOR_ID             NUMBER(30),  
	OLD_VENDOR_SITE_ID        NUMBER(30),  
	NEW_VENDOR_ID             NUMBER(30),  
	NEW_VENDOR_SITE_ID        NUMBER(30),  
	STATUT                    VARCHAR2(20), 
	EXTRACTED_DATE            DATE,
	CREATION_DATE             DATE,        
	CREATED_BY                NUMBER(30),   
	LAST_UPDATE_DATE          DATE,  
	LAST_UPDATED_BY           NUMBER(30)
)
TABLESPACE &3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SPOCDE_TRANSFRS_HIST TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1

DROP SYNONYM DKA_SPOCDE_TRANSFRS_HIST;

CREATE SYNONYM DKA_SPOCDE_TRANSFRS_HIST FOR DKA.DKA_SPOCDE_TRANSFRS_HIST;

SHOW ERRORS
EXIT;