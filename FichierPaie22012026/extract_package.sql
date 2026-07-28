-- =====================================================================
-- Script d'extraction du package XXEAI_INTERFACE_TOOLS_PKG
-- =====================================================================
-- Date : 22/01/2026
-- Description : Extrait le package spec (.pks) et body (.pkb) depuis
--               la base de données Oracle EBS vers des fichiers locaux
-- =====================================================================

SET LONG 10000000
SET LONGCHUNKSIZE 10000000
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET HEADING OFF
SET ECHO OFF
SET VERIFY OFF
SET TERMOUT OFF

-- Extraction du package specification
SPOOL XXEAI.XXEAI_INTERFACE_TOOLS_PKG.pks

SELECT TEXT 
FROM ALL_SOURCE 
WHERE OWNER = 'XXEAI' 
AND NAME = 'XXEAI_INTERFACE_TOOLS_PKG' 
AND TYPE = 'PACKAGE'
ORDER BY LINE;

SPOOL OFF

-- Extraction du package body  
SPOOL XXEAI.XXEAI_INTERFACE_TOOLS_PKG.pkb

SELECT TEXT 
FROM ALL_SOURCE 
WHERE OWNER = 'XXEAI' 
AND NAME = 'XXEAI_INTERFACE_TOOLS_PKG' 
AND TYPE = 'PACKAGE BODY'
ORDER BY LINE;

SPOOL OFF

SET TERMOUT ON
SET FEEDBACK ON
SET HEADING ON
PROMPT 
PROMPT Extraction terminée :
PROMPT - XXEAI.XXEAI_INTERFACE_TOOLS_PKG.pks (Package Specification)
PROMPT - XXEAI.XXEAI_INTERFACE_TOOLS_PKG.pkb (Package Body)
PROMPT
