create or replace package DKA_SFAGENIMMO_PKG
AS

--------------------------------------------------------------------------------------------
-- $Id: DKA_SFAGENIMMO_PKG.pkb 2018-07-13 10:13:20Z $
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFAGENIMMO_PKG.pkb
-- DESCRIPTION       : DKA_SFAGENIMMO_PKG package body :
---
--- AUTEUR           : R. BELAYACHI (CAPGEMINI)
--- DATE DE CREATION : 13/07/2018
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

    PROCEDURE transfer_immo (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    );
    
    PROCEDURE auto_acquis (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    );

    PROCEDURE imput_acquis (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    );

    PROCEDURE copie_hvp (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    );

    PROCEDURE valider_immo (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pn_org_id    IN       VARCHAR2
    );
END DKA_SFAGENIMMO_PKG; -- Package spec
/
SHOW ERRORS;
EXIT;
