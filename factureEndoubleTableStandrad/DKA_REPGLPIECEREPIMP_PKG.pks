----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : Hélios
-- NOM              : dka_sarrefac_orig_txn_rg_v.vue
-- DESCRIPTION	    : Création de la vue DKA_SARREFAC_ORIG_TXN_RG_V
--
-- AUTEUR           : Xavier Descamps (CGEY)
-- DATE DE CREATION : 05/12/2001
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SARREFAC_ORIG_TXN_RG_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_SARREFAC_ORIG_TXN_RG_V
        (
        ORIGINE,
        TYPE,
        DESCRIPTION
        )
        AS
        SELECT 'EVENT',
               pet.event_type,
               pet.description
        FROM pa_event_types pet
        UNION ALL
        SELECT 'EXPENDITURE',
               pet.expenditure_type,
               pet.description
        FROM pa_expenditure_types pet
        ;

SHOW ERROR

EXIT
