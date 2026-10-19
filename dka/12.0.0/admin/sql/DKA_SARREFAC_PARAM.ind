---------------------------------------------------------------------------------------------- 
-- $$
-- CAPGEMINI
-- PROJET            : Hélios
-- NOM               : DKA_SARREFAC.ind
-- DESCRIPTION	     : Index des tables spécifiques DKA_SARREFAC
---
--- AUTEUR           : Xavier Descamps (CGEY)
--- DATE DE CREATION : 03/12/2001
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user DKA
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
---
--------------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX dka_sarrefac_param_U1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX dka_sarrefac_param_U1;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX dka_sarrefac_param_U1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE UNIQUE INDEX dka_sarrefac_param_U1 
ON dka.dka_sarrefac_param
(Orig_Transaction_Type );


EXIT;
