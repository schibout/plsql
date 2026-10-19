--------------------------------------------------------------------------------
-- $Id: XXEAI_INFOS_BANQUE_TYP.sql $
-- Capgemini
-- Projet           : Dalkia
-- Nom              : XXEAI_INFOS_BANQUE_TYP.sql
-- Description      : Création de l'objet XXEAI_INFOS_BANQUE_OBJ
-- Auteur           : Julien Jardez
-- Date de création : 19/05/2014
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en parametres
--                    1- Login APPS
--                    2- Password APPS
--
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 08/09/2014 BCO DPE20140079 - Evolution appel de fonction Banque pour l'EAI
-- 02/12/2014 BCO DPE20140088 - Ajout des outils d'interface pour AP
-- 22/01/2014 BCO DPE20150006 - Outils d'interface AP pour l'EAI - Problématiques de TVA
-- 11/02/2015 BCO Ajout de droits sur le table DKA_IBDSOC_GENERAL_INFO
-- 22/06/2017 OBE artf2180340 : SPE182 - Droit en lecture sur DKA.DKA_IEOPAGTO01_TMP
--------------------------------------------------------------------------------

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT, INSERT, UPDATE, DELETE ON DKA.DKA_IBDAPPART_A00YH_TEMP TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT, INSERT, UPDATE, DELETE ON DKA.DKA_IBDAPPART_A00YH_TEMP TO XXEAI;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT, INSERT, UPDATE, DELETE ON DKA.DKA_IBDAPPART_INTERFACE TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT, INSERT, UPDATE, DELETE ON DKA.DKA_IBDAPPART_INTERFACE TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON DKA.DKA_PARAMETERS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON DKA.DKA_PARAMETERS TO XXEAI;

--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--PROMPT GRANT SELECT ON DKA.DKA_IBDSOC_GENERAL_INFO TO XXEAI
--PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--GRANT SELECT ON DKA.DKA_IBDSOC_GENERAL_INFO TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, INSERT, UPDATE ON DKA.DKA_ICLIENTIFS_COLLECTORS TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, INSERT, UPDATE ON DKA.DKA_ICLIENTIFS_COLLECTORS TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, INSERT, UPDATE ON DKA.DKA_ICLIENTIFS_INTERFACE TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, INSERT, UPDATE ON DKA.DKA_ICLIENTIFS_INTERFACE TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, INSERT, UPDATE ON DKA.DKA_IARPAFAC_INTERFACE TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, INSERT, UPDATE ON DKA.DKA_IARPAFAC_INTERFACE TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, INSERT, UPDATE ON DKA.DKA_EAI_PROJET TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, INSERT, UPDATE ON DKA.DKA_EAI_PROJET TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, INSERT, UPDATE ON DKA.DKA_EAI_TACHE TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, INSERT, UPDATE ON DKA.DKA_EAI_TACHE TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT, INSERT, UPDATE ON DKA.DKA_EAI_ORGANISATION TO XXEAI
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT, INSERT, UPDATE ON DKA.DKA_EAI_ORGANISATION TO XXEAI;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT GRANT SELECT ON DKA.DKA_IEOPAGTO01_TMP
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT SELECT ON DKA.DKA_IEOPAGTO01_TMP TO XXEAI;

EXIT;


