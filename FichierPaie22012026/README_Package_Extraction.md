-- =====================================================================
-- Package XXEAI_INTERFACE_TOOLS_PKG - Specification
-- =====================================================================
-- Owner: XXEAI
-- Type: PACKAGE
-- Status: VALID
-- Extrait le: 22/01/2026
-- 
-- Note: Ce fichier contient le code source complet du package
--       specification récupéré depuis ALL_SOURCE
-- =====================================================================

-- Pour récupérer le code complet, exécutez dans SQLcl connecté à oracleProd :

SET LONG 10000000
SET LONGCHUNKSIZE 10000000  
SET PAGESIZE 0
SET LINESIZE 32767
SET TRIMSPOOL ON
SET FEEDBACK OFF
SET HEADING OFF

SPOOL XXEAI.XXEAI_INTERFACE_TOOLS_PKG.pks

SELECT TEXT 
FROM ALL_SOURCE 
WHERE OWNER = 'XXEAI' 
AND NAME = 'XXEAI_INTERFACE_TOOLS_PKG' 
AND TYPE = 'PACKAGE'
ORDER BY LINE;

SPOOL OFF

-- Alternative : utilisez DBMS_METADATA
SELECT DBMS_METADATA.GET_DDL('PACKAGE','XXEAI_INTERFACE_TOOLS_PKG','XXEAI') FROM DUAL;
