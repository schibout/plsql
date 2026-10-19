--------------------------------------------------------------------------------
-- $Id: DKA_IPOEXTRACTCDE_DIR.sql 174 2008-03-14 14:36:36Z NORDEST\jdequidt $ 
-- Capgemini
-- Projet           : HELIOS
-- Nom              : DKA_IPOEXTRACTCDE_DIR.dir
-- Description      : Création du directory
-- Auteur           : Jonathan Dequidt (Capgemini)
-- Date de création : 05/02/2008
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
-- 03/05/2016 BDE Modification du nom du directory "XXVE_IPOEXTRACTCDE_DIR" en DKA_IPOEXTRACTCDE_DIR
--------------------------------------------------------------------------------

CONNECT &1/&2

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT Creation du directory DKA_IPOEXTRACTCDE_DIR
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE DIRECTORY DKA_IPOEXTRACTCDE_DIR AS '&3';

EXIT;
