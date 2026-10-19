--------------------------------------------------------------------------------
-- $Id: DKA_SPOCUT_OFF_I.sql 364 2007-10-04 16:12:58Z NORDEST\viknab $
-- Capgemini
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOCUT_OFF_I.sql
-- DESCRIPTION       : Insertion dans la table des paramètres
--
--- AUTEUR           : T. BONDUAEUX
-- DATE DE CRÉATION  : 25/09/2007
-- DOC. ASSOCIÉE     : 
-- COMMENTAIRE       : À exécuter avec SQLPLUS sous l'utilisateur APPS
--------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Personne  Description
-- ---------- --------- --------------------------------------------------------
-- 19/12/2013    TB     Modif du taux de TVA à 20%
--------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DANS LA TABLE DKA_PARAMETERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

DELETE FROM DKA_PARAMETERS WHERE PROGRAM_CODE = 'SPOCUT_OFF';

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT INSERTION DANS LA TABLE DKA_PARAMETERS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

INSERT INTO DKA_PARAMETERS (
  PROGRAM_CODE,
  PARAMETER_NAME,
  DESCRIPTION,
  DATA_TYPE,
  VARCHAR2_VALUE,
  NUMBER_VALUE)
VALUES (
  'SPOCUT_OFF',
  'CPTE_CAP',
  'Compte local de CAP',
  'VARCHAR2',
  '408104',
  NULL);

INSERT INTO DKA_PARAMETERS (
  PROGRAM_CODE,
  PARAMETER_NAME,
  DESCRIPTION,
  DATA_TYPE,
  VARCHAR2_VALUE,
  NUMBER_VALUE)
VALUES (
  'SPOCUT_OFF',
  'CPTE_CCA',
  'Compte local de CCA',
  'VARCHAR2',
  '486004',
  NULL);

INSERT INTO DKA_PARAMETERS (
  PROGRAM_CODE,
  PARAMETER_NAME,
  DESCRIPTION,
  DATA_TYPE,
  VARCHAR2_VALUE,
  NUMBER_VALUE)
VALUES (
  'SPOCUT_OFF',
  'CPTE_TVA',
  'Compte local de TVA',
  'VARCHAR2',
  '445864',
  NULL);

INSERT INTO DKA_PARAMETERS (
  PROGRAM_CODE,
  PARAMETER_NAME,
  DESCRIPTION,
  DATA_TYPE,
  VARCHAR2_VALUE,
  NUMBER_VALUE)
VALUES (
  'SPOCUT_OFF',
  'TAUX_TVA',
  'Taux de TVA',
  'NUMBER',
  NULL,
  20);

COMMIT;

EXIT;