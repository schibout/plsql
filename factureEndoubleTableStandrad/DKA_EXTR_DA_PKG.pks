--------------------------------------------------------------------------------
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_DAS2_ENTITE.vue
-- Description      : Création de la vue DKA_DAS2_ENTITE
-- Auteur           : S.EL OUAHABI (Capgemini)
-- Date de création : 21/05/2020
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--
--------------------------------------------------------------------------------
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_DAS2_ENTITE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

create or replace view dka_das2_entite as
select distinct rel.balancing_segment_value, re.entity_name
from ap_reporting_entity_lines_all rel, ap_reporting_entities_all re, hr_operating_units ou  , GL_ACCESS_SET_LEDGERS AC, GL_LEDGERS L
 where re.tax_entity_id = rel.tax_entity_id
 and re.org_id =ou.organization_id
 and AC.ACCESS_SET_ID=fnd_profile.value('GL_ACCESS_SET_ID')
  AND L.LEDGER_ID = AC.LEDGER_ID
   and ou.set_of_books_id=l.ledger_id
   order by re.entity_name;
/													
SHOW ERRORS VIEW DKA_SOCIETE_EXTRACT_FISCALE
EXIT