CREATE OR REPLACE PACKAGE DKA_SPORES_CONTRAT_PKG
AS

----------------------------------------------------------------------------
-- $Id: DKA_SPORES_CONTRAT_PKG.pks 153 2007-09-12 09:25:26Z NORDEST\jjardez $
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPORES_CONTRAT_PKG.pks
-- DESCRIPTION       : DKA_SPORES_CONTRAT_PKG package specifications
---
--- AUTEUR           : J. JARDEZ
--- DATE DE CREATION : 10/09/2006
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------
----------------------------------------------------------------------------

--------------------------------------------------------------------------------------
 --  Nom           : MAIN
 --  Description   : Procedure principale enchainant l'ensemble des autres procedures
 --
 --  PARAMETRES :
 --    pv_errbuf                   Entree/Sortie       retour de message eventuel
 --    pn_retcode                  Sortie          status du traitement en sortie
 --
 --  VALEUR RETOURNEE :
 --     Description       : code retour de validite
 --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
 --
 ----------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER,
        pv_mail_test IN VARCHAR2
    );

END DKA_SPORES_CONTRAT_PKG;
/

SHOW ERRORS
EXIT

