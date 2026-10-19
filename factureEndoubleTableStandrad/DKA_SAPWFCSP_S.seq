--------------------------------------------------------------------------------
-- $Id$
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOCONTRAT_SSTR_I.sql
-- DESCRIPTION       : Insertion dans la table des paramètres
---
-- AUTEUR            : T. Bonduaeux
-- DATE DE CRÉATION  : 03/12/2007
-- DOC. ASSOCIÉE     : 
-- COMMENTAIRE       : À exécuter avec SQLPLUS sous l'utilisateur APPS
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Personne  Description
-- ---------- --------- --------------------------------------------------------
-- 03-Dec-07  tbonduae  Création
--------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DANS LA TABLE DKA_PARAMETERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

DELETE FROM DKA_PARAMETERS WHERE PROGRAM_CODE = 'DKA_SPOCONTRAT_SSTR';

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT INSERTION DANS LA TABLE DKA_PARAMETERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

INSERT INTO DKA_PARAMETERS (
  PROGRAM_CODE,
  PARAMETER_NAME,
  DESCRIPTION,
  DATA_TYPE,
  NUMBER_VALUE)
VALUES (
  'DKA_SPOCONTRAT_SSTR',
  'DUREE_MAX_CONTRAT',
  'Durée maximum d''un contrat (en mois)',
  'NUMBER',
  18);

COMMIT;

EXIT;