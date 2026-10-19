-------------------------------------------------------------------------------
-- CAP GEMINI
-- Projet : DALKIA Oracle Applications
-- Auteur : J.Pelat
-- Date Création : 18/07/2016
-- Version livrables : 1.0
--------------------------------------------------------------------------------
-- NOM : DKA_SOCIETES_LEGALES.vue
-- DESCRIPTION : 
-- COMMENTAIRE : 
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SOCIETES_LEGALES
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CONNECT APPS/&2;

create or replace view DKA_SOCIETES_LEGALES as
select DISTINCT SUBSTR(hou.name,4,4) SOCIETE
  from PER_SECURITY_PROFILES      psp,
       PER_SECURITY_ORGANIZATIONS pso,
       HR_OPERATING_UNITS         hou
 where pso.SECURITY_PROFILE_ID  = psp.SECURITY_PROFILE_ID
   AND pso.ORGANIZATION_ID      = fnd_profile.value('ORG_ID')
   AND pso.ORGANIZATION_ID      = hou.ORGANIZATION_ID;

SHOW ERRORS

EXIT

    
    
  
