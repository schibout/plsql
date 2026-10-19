CREATE OR REPLACE PACKAGE BODY DKA_PO_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_PO_TOOLS_PKG.pkb
-- DESCRIPTION       : DKA_PO_TOOLS_PKG package body : fonctions communes
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--  16/03/2016 JJA Portage Helios 2016
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);

-----------------------------------------------------------------
--  Nom           : XXXXX
--  Description   : Fonction XXXXXX
--
--  PARAMETRES :
--     pv_lookup_type     Entrée
--     pv_lookup_code     Entrée
--
--  VALEUR RETOURNEE :
--     Description       :  Signification du jeu de codes express
--     Valeurs possibles :
-----------------------------------------------------------------
    FUNCTION XXXXX (
        pv_lookup_type   IN   VARCHAR2,
        pv_lookup_code   IN   VARCHAR2
    )
        RETURN VARCHAR2
    IS
        
    BEGIN
        

        RETURN NULL;
    EXCEPTION
        WHEN OTHERS
        THEN
            RETURN NULL;
    END XXXXX;
	
	
	
---------------------------------------------------------------------------------------------------------------
--  Nom           : UPDATE_PERIOD_STATUSES
--  Description   : Permet de définir un nouveau statut de fermeture dans GL_PERIOD_STATUSES pour la période spécifiée
--
--  PARAMETRES    :
--     pn_sob_id	number
--     pv_period_name	varchar2
--     pn_application number
--     pv_closing_status varchar2
--	
--  VALEUR RETOURNEE :
--     pv_errbuf	varchar2
--     pd_period_name 	varchar2
---------------------------------------------------------------------------------------------------------------
PROCEDURE update_period_statuses(pn_sob_id         IN NUMBER,
                                 pv_period_name    IN VARCHAR2,
                                 pn_application    IN NUMBER,
                                 pv_closing_status IN VARCHAR2,
                                 pv_errbuf         OUT VARCHAR2,
                                 pn_retcode        OUT NUMBER)
IS
BEGIN	   

	UPDATE gl_period_statuses  gps
	SET    closing_status       = pv_closing_status
	WHERE  gps.application_id   = pn_application
    AND  gps.set_of_books_id  = pn_sob_id
    AND  gps.period_name      = pv_period_name; 
	
	COMMIT;
		
EXCEPTION
WHEN OTHERS THEN
pv_errbuf := substr(SQLERRM,1,250);
pn_retcode := 2;			
END;

    
END DKA_PO_TOOLS_PKG; -- Spécification du package
/

SHOW ERRORS
EXIT;

