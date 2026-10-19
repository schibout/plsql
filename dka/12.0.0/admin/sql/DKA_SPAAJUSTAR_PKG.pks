CREATE OR REPLACE PACKAGE dka_spaajustar_pkg AS

--------------------------------------------------------------------------------------------
-- NOM           : DKA_SPACUTOFFAR_PKG.pks
-- DESCRIPTION   : DKA_SPACUTOFFAR_PKG package spec : spécifique CUTOFF AR->PA
---
--- AUTEUR           : Grégory VANACKERE
--- DATE DE CREATION : 04/03/2005
--- DOC. ASSOCIEE    :
---
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--  Fonction      : get_account_info
--  Description   : recherche des infos du du compte local (segment3) passé en paramètre
----------------------------------------------------------------------------------------
    FUNCTION get_account_info (
        pv_segment3               IN       VARCHAR2,
        pn_set_id                 IN       NUMBER        
    )
        RETURN VARCHAR2;
   
--------------------------------------------------------------------------------------------
--  Nom           : TRANSFER_FROM_AR_TO_PA
--  Description   : Transfert des écritures d'ajustements AR vers PA
--
--  PARAMETRES :
--    pv_errbuf       Sortie
--    pn_retcode      Sortie
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
--                         ou le code erreur ORA
----------------------------------------------------------------------------------------
PROCEDURE transfer_from_ar_to_pa (
    pv_errbuf                  IN OUT   VARCHAR2,
    pn_retcode                 IN OUT   NUMBER
);

END dka_spaajustar_pkg; -- Spécification du package
/
SHOW ERRORS
EXIT