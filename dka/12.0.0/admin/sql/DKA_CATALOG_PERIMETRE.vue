---------------------------------------------------------------------------------------------------------------
-- $Id: DKA_CATALOG_PERIMETRE.vue $
-- CAP GEMINI 
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_CATALOG_PERIMETRE.vue
-- DESCRIPTION      : 
---
--- AUTEUR           : R. BELAYACHI (CAPGEMINI)
--- DATE DE CREATION : 22/01/2018
--- DOC. ASSOCIEE    :
--- COMMENTAIRE      : 
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------
CREATE OR REPLACE VIEW DKA_CATALOG_PERIMETRE 
AS
SELECT PERIMETRE,TRI FROM (
SELECT 'TOUT' PERIMETRE, 1 TRI 
FROM DUAL
WHERE FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')=(SELECT SECURITY_PROFILE_ID 
                                                          FROM PER_SECURITY_PROFILES_V 
                                                          WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')
UNION
SELECT DISTINCT SUBSTR(hou.NAME,1,3) PERIMETRE, 2 TRI 
FROM HR_OPERATING_UNITS HOU
WHERE FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')  = ( SELECT SECURITY_PROFILE_ID 
                                                            FROM PER_SECURITY_PROFILES_V 
                                                            WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')
UNION
SELECT SECURITY_PROFILE_NAME PERIMETRE, 2 TRI 
FROM PER_SECURITY_PROFILES_V
WHERE SECURITY_PROFILE_ID =  FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')
AND SECURITY_PROFILE_ID != (SELECT SECURITY_PROFILE_ID 
                            FROM PER_SECURITY_PROFILES_V 
                            WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')
UNION
SELECT hou.NAME PERIMETRE, 2 TRI 
FROM HR_OPERATING_UNITS HOU
WHERE FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL') = (SELECT SECURITY_PROFILE_ID 
                                                            FROM PER_SECURITY_PROFILES_V 
                                                            WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')
UNION
SELECT hou.NAME PERIMETRE, 2 TRI 
FROM HR_OPERATING_UNITS HOU,PER_SECURITY_PROFILES_V PSP
WHERE psp.SECURITY_PROFILE_ID =  FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')
AND psp.SECURITY_PROFILE_ID != (SELECT SECURITY_PROFILE_ID 
                                FROM PER_SECURITY_PROFILES_V 
                                WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')
AND hou.NAME LIKE PSP.SECURITY_PROFILE_NAME || '%'
)
ORDER BY TRI,PERIMETRE
;

exit;
/