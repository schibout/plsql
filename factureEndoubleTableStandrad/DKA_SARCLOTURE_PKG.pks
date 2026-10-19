---------------------------------------------------------------------------------------------------------------
-- CAPGEMINI
-- PROJET           : DALKIA Oracle Applications Helios
-- NOM              : DKA_IGLHYPERIONDR_REP.sql
-- DESCRIPTION      : Lancement automatique du traitement IHYPERION
---
--- AUTEUR           : Samir EL OUAHABI (CAPGEMINI)
--- DATE DE CREATION : 27/11/2020
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 27/01/2020 SELO DGE20190021 Gestion des comptes en quantité
---------------------------------------------------------------------------------------------------------------

set echo off
set heading off
set verify off
select 'Resultat= '||Directory_path
from all_directories
where directory_name like 'DKA_OUT_DIR';
set echo off

EXIT;