-- Script de création d'indexes
-- Auteur: NSI
-- Date: 10/10/2016
----------------------------------------------------------------------------------------------------
--PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
--PROMPT SUPPRESSION DES INDEX                                                                          
--PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
DROP INDEX AP.DKA_AP_SUPPLIER_SITES_INT_N2;
DROP INDEX DKA.DKA_AP_REP_SUPP_SITES_TMP_N1;

--PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
--PROMPT CREATION DES INDEX                                                                          
--PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE INDEX AP.DKA_AP_SUPPLIER_SITES_INT_N2 ON AP.AP_SUPPLIER_SITES_INT (VENDOR_SITE_INTERFACE_ID) TABLESPACE APPS_TS_INTERFACE;

--PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
--PROMPT CREATION DES INDEX                                                                          
--PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE INDEX DKA.DKA_AP_REP_SUPP_SITES_TMP_N1 ON DKA.DKA_AP_REP_SUPP_SITES_TMP (PROCESSED_REQUEST_ID, SEGMENT1, VENDOR_SITE_CODE) TABLESPACE APPS_DKASPE_IDX;

EXIT;
