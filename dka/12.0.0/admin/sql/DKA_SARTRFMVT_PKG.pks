SET VERIFY OFF;
DEFINE package_name = "DKA_SARTRFMVT";

CREATE OR REPLACE PACKAGE &&package_name
AS

----------------------------------------------------------------------------------------------
-- $$
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SARTRFMVT.pks
-- DESCRIPTION       : DKA_SARTRFMVT package spec :
---
--- AUTEUR           : Saloua HAHIOUI
--- DATE DE CREATION : 03/03/2020
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 
--------------------------------------------------------------------------------------------

PROCEDURE cherche_period ( pn_sob_id 		IN OUT NUMBER,
			   pv_errbuf 		OUT VARCHAR2,
			   pd_start_date 	OUT DATE,
			   pd_end_date 		OUT DATE,
			   pv_period_name 	OUT VARCHAR2 ) ;


PROCEDURE cherche_next_period (  	pn_sob_id		          IN OUT NUMBER,
                      				pv_errbuf 		   OUT VARCHAR2,
                      				pv_period_name      IN     VARCHAR2,
                      			   	pd_next_start_date    OUT DATE,
                      			   	pd_next_end_date 	   OUT DATE,
                      			   	pv_next_period_name   IN OUT VARCHAR2
                      		    ) ;			   


PROCEDURE main ( pv_errbuf	IN OUT varchar2,
		 pn_retcode 	OUT number	);
     
    

		 
END &&package_name; -- Package Spécif
/

SHOW ERRORS;
EXIT