--------------------------------------------------------------------------------
-- $Id: DKA_ORGANISATION_V.vue 210 2008-03-18 15:46:15Z NORDEST\tbonduae $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_ORGANISATION_V.vue
-- Description      : Création de la vue DKA_ORGANISATION_V
-- Auteur           : A.Deltour (Capgemini)
-- Date de création : 14/04/2008
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--- 2016/09/02 JJA Portage Helios R12
--------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_ORGANISATION_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_ORGANISATION_V AS
SELECT HOU.ORGANIZATION_ID VALUE, SUBSTR(HOU.NAME, 1, 50) DESCRIPTION, HOU.ATTRIBUTE10 DIVISION
FROM HR_ALL_ORGANIZATION_UNITS HOU, HR_ORGANIZATION_INFORMATION_V HOI
WHERE HOU.ORGANIZATION_ID = HOI.ORGANIZATION_ID
AND HOI.ORG_INFORMATION2_MEANING = 'Oui'
AND ORG_INFORMATION1='OPERATING_UNIT'
AND SYSDATE BETWEEN NVL(HOU.DATE_FROM, SYSDATE) AND NVL(HOU.DATE_TO, SYSDATE)
ORDER BY HOU.ORGANIZATION_ID;
/

SHOW ERRORS VIEW DKA_ORGANISATION_V
EXIT
