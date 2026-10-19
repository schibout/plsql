create or replace package DKA_SPOMAJCATKPI_PKG
AS

--------------------------------------------------------------------------------------------
-- $Id: $
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications (Helios R12)
-- NOM               : DKA_SPOMAJCATKPI_PKG.pks
-- DESCRIPTION       : DKA_SPOMAJCATKPI_PKG package specification :
---
--- AUTEUR           : N. BOUSSEKEYT (CAPGEMINI)
--- DATE DE CREATION : 01/03/2019
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure pour le traitement de mise des KPI catalogues
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--  pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
    PROCEDURE main(
        pv_errbuf       IN OUT   VARCHAR2,
        pn_retcode      OUT      NUMBER
    );

    
END DKA_SPOMAJCATKPI_PKG; -- Package spec
/
SHOW ERRORS;
EXIT;
