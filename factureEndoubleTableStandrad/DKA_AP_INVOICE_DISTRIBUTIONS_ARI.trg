-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SARCLOTURE.tab
-- DESCRIPTION      : Création de la table DKA_SPACLOTURE
--
-- AUTEUR           : D.BOUCHA (CGEY)
-- DATE DE CREATION : 27/03/2002
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA
--                    en lui passant 3 paramètres :
--                           1) Password DKA
--                           2) Password APPS
--                           3) Tablespace des données pour schéma DKA
--                           4) Tablespace des index   pour schéma DKA
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------------------
-- 29/05/2002 XD  Colonne project_code : passage sur 7 caracteres
--------------------------------------------------------------------------------------------

CONNECT DKA/&&1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA_SARCLOTURE
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_SARCLOTURE ;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_SARCLOTURE
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_SARCLOTURE (	
				ledger_id 		NUMBER,
				period_name 	VARCHAR2(30),
				nom_test	VARCHAR2(250),
				status		VARCHAR2(2),
				message		VARCHAR2(4000)			
	                    )
TABLESPACE &&3 ;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SARCLOTURE TO APPS;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CONNECT APPS/&&2;

DROP SYNONYM DKA_SARCLOTURE;

CREATE SYNONYM DKA_SARCLOTURE FOR DKA.DKA_SARCLOTURE;

EXIT;                                                         