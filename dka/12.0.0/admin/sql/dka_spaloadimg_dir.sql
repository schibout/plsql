--------------------------------------------------------------------------------
-- $Id: dka_spaloadimg_dir.sql  
-- Capgemini
-- Projet           : HELIOS _ Migration R12
-- Nom              : dalkia_loadimg.dir et dalkia_moveimg.dir
-- Description      : Création du directory
-- Auteur           : Roshanak GHARAGOZLOU (Capgemini)
-- Date de création : 25/07/2016
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- login APPS
--                    2- password APPS
--                    3- valeur de la variable $REP_DATA
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 
--------------------------------------------------------------------------------

CONNECT &1/&2

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Creation du directory dalkia_loadimg
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
create or replace directory dalkia_loadimg as '&3/ALADIN_IN';

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Creation du directory dalkia_moveimg
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
create or replace directory dalkia_moveimg as '&3/traite/ALADIN_IN';

EXIT;