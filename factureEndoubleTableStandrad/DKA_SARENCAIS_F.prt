CREATE OR REPLACE PACKAGE DKA_SPODISABLE_CALC_CAP_PKG
AS

----------------------------------------------------------------------------
-- $Id: DKA_SPODISABLE_CALC_CAP_PKG.pks 195 2007-09-14 12:59:35Z NORDEST\jjardez $
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPODISABLE_CALC_CAP_PKG.pks
-- DESCRIPTION       : DKA_SPODISABLE_CALC_CAP_PKG package specifications
---
--- AUTEUR           : J. JARDEZ
--- DATE DE CREATION : 13/09/2007
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------
----------------------------------------------------------------------------

--------------------------------------------------------------------------------------
 --  Nom           : desactive_calcul_cap_sstr
 --  Description   : Procedure principale de desactivation du calcul des CAP
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
    PROCEDURE desactive_calcul_cap_sstr (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    );

END DKA_SPODISABLE_CALC_CAP_PKG;
/

SHOW ERRORS
EXIT

