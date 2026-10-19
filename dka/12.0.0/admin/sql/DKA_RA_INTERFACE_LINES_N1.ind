-------------------------------------------------------------------------------
-- Capgemini
-- Projet            : DALKIA Oracle Applications
-- Auteur            : Eric MATUSZEWSKI
-- Date Création     : 01/02/2008
-- Version livrables : V01
--------------------------------------------------------------------------------
-- NOM         : DKA_RA_INTERFACE_LINES_N1.ind
-- DESCRIPTION : Script de création de l'index DKA_RA_INTERFACE_LINES_N1 sur 
--               la table RA_INTERFACE_LINES_ALL
-- COMMENTAIRE : 
--
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------
 
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LINDEX DKA_RA_INTERFACE_LINES_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX AR.DKA_RA_INTERFACE_LINES_N1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LINDEX DKA_RA_INTERFACE_LINES_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX AR.DKA_RA_INTERFACE_LINES_N1
ON AR.RA_INTERFACE_LINES_ALL (INTERFACE_LINE_CONTEXT, INTERFACE_LINE_ATTRIBUTE1, INTERFACE_LINE_ATTRIBUTE2, 
                              INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4, INTERFACE_LINE_ATTRIBUTE5, REQUEST_ID)
PCTFREE    10
INITRANS   11
MAXTRANS   255
STORAGE
  (INITIAL     8M
   NEXT        8M
   MINEXTENTS  1
   MAXEXTENTS  UNLIMITED
   PCTINCREASE 0);

EXIT
