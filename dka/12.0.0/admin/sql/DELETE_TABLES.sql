-------------------------------------------------------------------------------------
-- Capgemini
-- PROJET           : Dalkia Oracle Applications
-- NOM              : DKA_SARSURTAXE_TMP_POLICY.sql
-- DESCRIPTION      : Création de policy dka_sarsurtaxe_tmp
--
-- AUTEUR           : Oussama BENHAYOUN
-- DATE DE CREATION : 06/03/2017
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : 
-------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------
--
-------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DES TABLES SPECIFIQUES
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CONNECT APPS/&1;

DROP TABLE DKA.DKA_SARSURTAXE_TMP_ALL;
DROP SYNONYM APPS.DKA_SARSURTAXE_TMP_ALL;
DROP VIEW DKA.DKA_SARSURTAXE_TMP_ALL#;
DROP VIEW DKA_SARSURTAXE_TMP;

DROP TABLE DKA.DKA_SARSURTAXE_CTL_TMP_ALL;
DROP SYNONYM APPS.DKA_SARSURTAXE_CTL_TMP_ALL;
DROP VIEW DKA.DKA_SARSURTAXE_CTL_TMP_ALL#;
DROP VIEW DKA_SARSURTAXE_CTL_TMP;

EXIT 
