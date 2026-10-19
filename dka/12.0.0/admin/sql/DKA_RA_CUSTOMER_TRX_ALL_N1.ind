-------------------------------------------------------------------------------
-- Capgemini
-- Projet            : HELIOS R12
-- Auteur            : OUSSAMA BENHAYOUN
-- Date Création     : 27/04/2017
-- Version livrables : V01
--------------------------------------------------------------------------------
-- NOM         : DKA_RA_INTERFACE_LINES_N1.ind
-- DESCRIPTION : Script de création de l'index DKA_RA_CUSTOMER_TRX_ALL_N1 sur 
--               la table RA_CUSTOMER_TRX_ALL
-- COMMENTAIRE : 
--
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------
 
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LINDEX DKA_RA_CUSTOMER_TRX_ALL_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX AR.DKA_RA_CUSTOMER_TRX_ALL_N1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LINDEX DKA_RA_CUSTOMER_TRX_ALL_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX AR.DKA_RA_CUSTOMER_TRX_ALL_N1 
ON AR.RA_CUSTOMER_TRX_ALL (INTERFACE_HEADER_CONTEXT, INTERFACE_HEADER_ATTRIBUTE1, INTERFACE_HEADER_ATTRIBUTE2,
                           INTERFACE_HEADER_ATTRIBUTE3, INTERFACE_HEADER_ATTRIBUTE4, INTERFACE_HEADER_ATTRIBUTE5
                           );

EXIT
