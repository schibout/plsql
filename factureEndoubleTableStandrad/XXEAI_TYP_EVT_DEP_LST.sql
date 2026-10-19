-------------------------------------------------------------------------------
-- Capgemini
-- Projet            : HELIOS R12
-- Auteur            : Nicolas BOUSSEKEYT
-- Date Création     : 24/01/2017
-- Version livrables : V01
--------------------------------------------------------------------------------
-- NOM         :  DKA_HZ_CUST_ACCT_SITES_ALL_N1.ind
-- DESCRIPTION : Script de création de l'index HZ_CUST_ACCT_SITES_ALL_N1 sur 
--               la table HZ_CUST_ACCT_SITES_ALL
-- COMMENTAIRE : 
--
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------
 
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LINDEX DKA_HZ_CUST_ACCT_SITES_ALL_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX AR.DKA_HZ_CUST_ACCT_SITES_ALL_N1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LINDEX DKA_HZ_CUST_ACCT_SITES_ALL_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX AR.DKA_HZ_CUST_ACCT_SITES_ALL_N1 
ON AR.HZ_CUST_ACCT_SITES_ALL (ATTRIBUTE3, ORG_ID);

EXIT
