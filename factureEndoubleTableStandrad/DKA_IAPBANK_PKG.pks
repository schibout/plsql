--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Nom              : DKA_SAPFRS_MAJ_HEADERS_S.seq
-- Description      : Script de création de la sequence
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

CONNECT &&1/&&2                                                                              


--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA SEQUENCE DKA_SAPFRS_MAJ_HEADERS_S
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP SEQUENCE DKA_SAPFRS_MAJ_HEADERS_S;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA SEQUENCE DKA_SAPFRS_MAJ_HEADERS_S
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 
CREATE SEQUENCE DKA_SAPFRS_MAJ_HEADERS_S INCREMENT BY 1
START WITH 1;       
 GRANT ALL ON DKA_SAPFRS_MAJ_HEADERS TO &&3; 


                                                                                                    
EXIT;