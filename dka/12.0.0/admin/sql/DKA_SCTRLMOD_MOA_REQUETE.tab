--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : Automatisation extraction des SQLs du matin
-- Nom              : DKA_SCTRLMOD_MOA_REQUETE.tab
-- Description      : Script de création de la table d'interface 
--                    DKA_SCTRLMOD_MOA_REQUETE
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
PROMPT DROP DE LA TABLE DKA_SCTRLMOD_MOA_REQUETE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_SCTRLMOD_MOA_REQUETE CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_SCTRLMOD_MOA_REQUETE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_SCTRLMOD_MOA_REQUETE
(
  ENTITE	                   	VARCHAR2(10),
  MODULE    	                VARCHAR2(30),
  NUMERO						NUMBER(15),
  NOM_COURT                  	VARCHAR2(50),
  DESCRIPTION					VARCHAR2(250),
  COMMENTAIRE					VARCHAR2(1000),
  COLONNE						VARCHAR2(4000),
  REQUETE						VARCHAR2(4000)
)
TABLESPACE &3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_SCTRLMOD_MOA_REQUETE TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1

DROP SYNONYM DKA_SCTRLMOD_MOA_REQUETE;

CREATE SYNONYM DKA_SCTRLMOD_MOA_REQUETE FOR DKA.DKA_SCTRLMOD_MOA_REQUETE;

SHOW ERRORS
EXIT;