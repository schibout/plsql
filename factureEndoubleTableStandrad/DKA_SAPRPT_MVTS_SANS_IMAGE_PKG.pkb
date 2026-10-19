--------------------------------------------------------------------------------
-- $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_AP_INV_LOBS.tab
-- Description      : Création de la table DKA_AP_INV_LOBS
-- Auteur           : H. Descroizette(Capgemini)
-- Date de création : 22/05/2016
-- Doc. associée    : 
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    $apps_pwd $dka_pwd $tablespace_data $tablespace_index
--                    1- Password APPS
--                    2- Password DKA
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 
--------------------------------------------------------------------------------
CONNECT APPS/&1
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA.DKA_AP_INV_LOBS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA.DKA_AP_INV_LOBS ;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA.DKA_AP_INV_LOBS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA.DKA_AP_INV_LOBS as select * from FND_LOBS where 1=0;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT DKA/&2
GRANT ALL ON DKA.DKA_AP_INV_LOBS TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&1
CREATE OR REPLACE SYNONYM DKA_AP_INV_LOBS FOR DKA.DKA_AP_INV_LOBS;

EXIT;
