--------------------------------------------------------------------------------------------
-- FILENAME
--   DKA_LOADER_REPINTTECPCA.ctl   V1.0
--
-- AUTEUR
--   Capgemini
--
-- DESCRIPTION
--   Chargement de la table temporaire DKA.DKA_MAJ_INDICATEURS_TECPCA
--
-- USAGE
--
-- NOTES
--
---------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------
-- Version   Date         Qui Description
---------- -------------- --- ---------------------------------------------------------------
-- V1.0    27/02/2017     NBO Creation
---------------------------------------------------------------------------------------------

OPTIONS (SKIP=1)
LOAD DATA
TRUNCATE
INTO TABLE DKA.DKA_MAJ_INDICATEURS_TECPCA
FIELDS TERMINATED BY '|'
TRAILING NULLCOLS
(
  PROJECT_CODE_11               CHAR NULLIF (PROJECT_CODE_11= BLANKS),
  INDICATEUR_TECPCA             CHAR NULLIF (INDICATEUR_TECPCA= BLANKS),
  PROJECT_CODE_12               CHAR NULLIF (PROJECT_CODE_12= BLANKS),
  TASK_CODE_12                  CHAR NULLIF (TASK_CODE_12= BLANKS),
  STATUS                        CONSTANT 'NEW',
  OA_ERROR_MESSAGE              CHAR NULLIF (OA_ERROR_MESSAGE= BLANKS))
  
--Fin