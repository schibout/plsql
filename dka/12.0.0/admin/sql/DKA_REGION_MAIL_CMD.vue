  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_REGION_MAIL_CMD.VUE
  -- Nom              : DKA_REGION_MAIL_CMD.VUE
  -- Description      : Création des vues
  -- Auteur           : Anas RAOUF
  -- Date de création : 06/05/2021
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 
CREATE OR REPLACE VIEW DKA_REGION_MAIL_CMD AS
SELECT ffv.flex_value as name
FROM fnd_flex_value_sets ffvs ,
     fnd_flex_values     ffv  
where 
       ffv.flex_value_set_id = ffvs.flex_value_set_id
AND flex_value_set_name = 'DAOPCCF_UO'
and ffv.flex_value != 'REF'
and ffv.enabled_flag = 'Y'
and ffv.summary_flag = 'N'
and nvl(ffv.start_date_active,SYSDATE) <= SYSDATE
and nvl(ffv.end_date_active,SYSDATE)       >= SYSDATE
AND ffv.flex_value = (SELECT SECURITY_PROFILE_NAME FROM PER_SECURITY_PROFILES_V 
WHERE SECURITY_PROFILE_ID = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL'));
EXIT;
/