----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI 
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DkaExtractBlob_Proc.sql
-- DESCRIPTION       : DkaExtractBlob_Proc.sql procedure :
--                     Export d'un blob
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 06/08/2013
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 06/08/2013 JJA DPE20130064 : Avenant : commande XML
---                Export d'un blob
--------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE Dka_ExportBlob (p_file  IN  VARCHAR2,
                                            p_blob  IN  BLOB)
AS LANGUAGE JAVA 
NAME 'DkaExtractBlob.ExportBlob(java.lang.String, oracle.sql.BLOB)';
/

SHOW ERRORS;

EXIT

