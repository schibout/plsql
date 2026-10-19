----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IARPAFAC_INTERFACE_V.vue
-- DESCRIPTION	    : Création de la vue DKA_IARPAFAC_INTERFACE_V
--
-- AUTEUR           : Xavier Descamps (CGEY)
-- DATE DE CREATION : 20/01/2004
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 06/10/2020 SEL  exclure les statut 'A', 'Z' et 'P' si req est null
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_IARPAFAC_INTERFACE_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_IARPAFAC_INTERFACE_V
AS
SELECT *
FROM  DKA_IARPAFAC_INTERFACE
WHERE oa_status not in ('A', 'Z', 'P') or (oa_status = 'P' and oa_request_id is not null);

SHOW ERROR

EXIT
