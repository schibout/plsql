CREATE OR REPLACE PACKAGE DKA_CGA_AUTO_PKG AS
------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : dka_CGA_AUTO_pkg.pks
-- DESCRIPTION       : dka_CGA_AUTO_pkg package specification :
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 16/10/2019
-- COMMENTAIRE      : 
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
-- 16/10/2019 SCH CREATION Automatisation 
------------------------------------------------------------------------------------------

PROCEDURE AUTO_CGA(pv_errbuf             IN OUT VARCHAR2,
                   pn_retcode            IN OUT NUMBER,
				   P_ORG_ID 			 IN 	NUMBER);

END DKA_CGA_AUTO_PKG;
/
SHOW ERRORS
EXIT