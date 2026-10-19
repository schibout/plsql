--------------------------------------------------------------------------------
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_SOCIETE_EXTRACT_FISCALE.vue
-- Description      : Création de la vue DKA_SOCIETE_EXTRACT_FISCALE
-- Auteur           : S.EL OUAHABI (Capgemini)
-- Date de création : 15/05/2020
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--
--------------------------------------------------------------------------------
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SOCIETE_EXTRACT_FISCALE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

create or replace view soc_dka as
select gl.short_name FLEX_VALUE,gl.ledger_id, gl.name DESCRIPTION
from gl_access_set_norm_assign_v gasn, gl_ledger_sets_v gls, 
     gl_ledger_set_norm_assign_v glsna, gl_ledgers gl, fnd_flex_value_sets sets, fnd_flex_values val
where gasn.ledger_id = gls.ledger_id(+)
   AND gls.ledger_id = glsna.ledger_set_id(+)
   AND gl.ledger_id = decode(glsna.ledger_id, NULL, gasn.ledger_id, glsna.ledger_id)
   AND ledger_category_code = 'PRIMARY'
   AND gasn.access_set_id = fnd_profile.value('GL_ACCESS_SET_ID')
   AND sets.flex_value_set_id = val.flex_value_set_id
   AND gl.short_name = val.flex_value
   AND val.enabled_flag = 'Y'
   AND SYSDATE BETWEEN NVL(val.start_date_active, SYSDATE) AND NVL(val.end_date_active, SYSDATE)
   AND val.summary_flag = 'N'
   AND val.VALUE_CATEGORY = 'DAOPCCF_STE'
 ORDER BY gl.short_name;														
/																	
SHOW ERRORS VIEW DKA_SOCIETE_EXTRACT_FISCALE
EXIT