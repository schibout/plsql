CREATE OR REPLACE PACKAGE DKA_FA_TOOLS_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_FA_TOOLS_PKG.pks
-- DESCRIPTION       : DKA_FA_TOOLS_PKG package spec : fonctions communes
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
        RETURN VARCHAR2;

    
END DKA_FA_TOOLS_PKG; -- Spécification du package
/

SHOW ERRORS
EXIT;

