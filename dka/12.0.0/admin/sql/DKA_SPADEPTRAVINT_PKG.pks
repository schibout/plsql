CREATE OR REPLACE PACKAGE dka_spadeptravint_pkg AS

--------------------------------------------------------------------------------------------
-- NOM           : DKA_SPADEPTRAVINT_PKG.pks
-- DESCRIPTION   : DKA_SPADEPTRAVINT_PKG package spec : spécifique extraction de PA des dépenses
--                                                      des travaux internes pour la Garantie Totale
---
--- AUTEUR           : Grégory VANACKERE
--- DATE DE CREATION : 10/03/2006
--- DOC. ASSOCIEE    :
---
--------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date              Qui                       Description
--- 09/05/2016        ROSHANAK GHARAGOZLOU      Modifications suite à la migration R12   ---
---
--------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------------
--  Nom           : Main
--  Description   : Procédure principale
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
PROCEDURE main (
    pv_errbuf                  IN OUT   VARCHAR2,
    pn_retcode                 IN OUT   NUMBER
);

END dka_spadeptravint_pkg; -- Spécification du package
/

SHOW ERROR

EXIT;