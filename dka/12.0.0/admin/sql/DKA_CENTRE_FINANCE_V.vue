--------------------------------------------------------------------------------
-- $Id: DKA_CENTRE_FINANCE_V.vue $
-- Capgemini
-- Projet           : Etat DKA : KPI Contribution de la codification articles internes
-- Nom              : DKA_CENTRE_FINANCE_V.vue
-- Description      : Création de la vue DKA_CENTRE_FINANCE_V
-- Auteur           : F.siham
-- Date de création : 08/04/2019
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
 
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--
--------------------------------------------------------------------------------
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_CENTRE_FINANCE_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE VIEW DKA_CENTRE_FINANCE_V 
AS SELECT
    VAL.FLEX_VALUE,
	VAL.description
FROM
    FND_FLEX_VALUE_SETS SETS,
    FND_FLEX_VALUES_VL VAL
WHERE
    SETS.FLEX_VALUE_SET_ID = VAL.FLEX_VALUE_SET_ID
    AND VAL.ENABLED_FLAG = 'Y'
    AND VAL.SUMMARY_FLAG = 'N'
    AND SETS.FLEX_VALUE_SET_NAME = 'DAOPCCF_CENTREFI'
    ORDER  BY 1;													
/													
SHOW ERRORS VIEW DKA_CENTRE_FINANCE_V
EXIT
