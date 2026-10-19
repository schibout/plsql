create or replace package DKA_SFADATAJ_PKG
AS

--------------------------------------------------------------------------------------------
-- $Id: DKA_SFADATAJ_PKG.pkb 271 2008-03-26 10:13:20Z NORDEST\jdequidt $
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFADATAJ_PKG.pkb
-- DESCRIPTION       : DKA_SFADATAJ_PKG package body :
---
--- AUTEUR           : R. BELAYACHI (CAPGEMINI)
--- DATE DE CREATION : 28/05/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

	-- EDB366 BNZ 20/07/2023
    PROCEDURE generer_comptes (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );
    -- artf3051477 SNIK 28/01/2019
    PROCEDURE calcul_values (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );
	
    PROCEDURE transfer_immo (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );

    PROCEDURE imput_acquis (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );

    PROCEDURE copie_hvp (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );

    PROCEDURE valider_immo (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );
END DKA_SFADATAJ_PKG; -- Package spec
/
SHOW ERRORS;
EXIT;
