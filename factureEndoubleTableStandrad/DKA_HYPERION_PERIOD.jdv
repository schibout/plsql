
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_PERIMETRE.VUE
  -- Nom              : DKA_PERIMETRE.VUE
  -- Description      : Création des vues
  -- Auteur           : SHA
  -- Date de création : 27/07/2020
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 


create or replace VIEW DKA_PERIMETRE AS 
SELECT name FROM (
SELECT
     'ALL' as name
     FROM DUAL
WHERE FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')=(SELECT SECURITY_PROFILE_ID 
                                                          FROM PER_SECURITY_PROFILES_V 
                                                          WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')
UNION
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
AND FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')=(SELECT SECURITY_PROFILE_ID 
                                                          FROM PER_SECURITY_PROFILES_V 
                                                          WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')
UNION
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
AND ffv.flex_value = (SELECT SECURITY_PROFILE_NAME FROM PER_SECURITY_PROFILES_V WHERE SECURITY_PROFILE_ID = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL'))
UNION
SELECT   name  FROM (SELECT NAME 
FROM HR_OPERATING_UNITS hou
    ,PER_SECURITY_ORGANIZATIONS pso
WHERE hou.organization_id = pso.organization_id
AND pso.security_profile_id = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL'))
)
ORDER BY name
;
exit;
/