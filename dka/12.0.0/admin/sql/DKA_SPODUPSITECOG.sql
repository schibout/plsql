--------------------------------------------------------------------------------
-- $Id: DKA_SPODUPSITECOG.sql $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPODUPSITECOG.sql
-- DESCRIPTION       : Insertion dans la table des paramètres
--
--- AUTEUR           : R. BELAYACHI
-- DATE DE CRÉATION  : 22/01/2018
-- DOC. ASSOCIÉE     : 
-- COMMENTAIRE       : À exécuter avec SQLPLUS sous l'utilisateur APPS
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Personne  Description
-- ---------- --------- --------------------------------------------------------
-- 22/01/2018    RBE    Creation
--------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DANS LA TABLE DKA_PARAMETERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

DELETE FROM DKA_PARAMETERS 
WHERE PROGRAM_CODE = 'DKA_SPODUPSITECOG' 
AND PARAMETER_NAME = 'DATE_EXECUTION';

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT INSERTION DANS LA TABLE DKA_PARAMETERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

INSERT INTO DKA_PARAMETERS (
  PROGRAM_CODE,
  PARAMETER_NAME,
  DESCRIPTION,
  DATA_TYPE,
  VARCHAR2_VALUE,
  DATE_VALUE)
VALUES (
  'DKA_SPODUPSITECOG',
  'DATE_EXECUTION',
  'Date de derniere execution',
  'DATE',
  NULL,
  SYSDATE);

COMMIT;

EXIT;