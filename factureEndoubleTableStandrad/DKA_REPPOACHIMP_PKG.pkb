--------------------------------------------------------------------------------
-- $Id: dka_IPOEXTRACTCDE_INTERFACE.tab 174 2008-03-14 14:36:36Z NORDEST\jdequidt $
-- Capgemini 
-- Projet           : HELIOS
-- Nom              : DKA_IPOEXTRACTCDE_INTERFACE.tab
-- Description      : Création de la table dka_IPOEXTRACTCDE_INTERFACE
-- Auteur           : Jonathan Dequidt (Capgemini)
-- Date de création : 25/01/2008
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur dka en 
--                    passant en paramètres
--                    1- Tablespace des idx pour le schéma dka

--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 03/05/2016 BDE   -Modification du nom de l'index (xxve_headers_n1) en dka_headers_n1
---------------------Modification du fichier XXVE_HEADERS_N1.idx en DKA_HEADERS_N1.idx
--------------------------------------------------------------------------------
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE L'INDEX DKA_HEADERS_N1 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
drop index dka_headers_n1;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE L'INDEX DKA_HEADERS_N1 
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
create index dka_headers_n1 on  po.po_headers_all  (   NVL(closed_code, 'OPEN') ) tablespace &1;


EXIT;
