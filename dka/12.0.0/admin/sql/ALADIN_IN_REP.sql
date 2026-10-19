--------------------------------------------------------------------------------
-- $Id: dka_spaloadimg_dir.sql  
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Description      : artf07147631 - Rapprochement des images facture
-- Auteur           : SELO
-- Date de création : 13/01/2020
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 
--------------------------------------------------------------------------------

set echo off
set heading off
set verify off
select 'Resultat= '||Directory_path
from all_directories
where directory_name like 'DALKIA_LOADIMG';
set echo off

EXIT;