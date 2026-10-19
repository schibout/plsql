--------------------------------------------------------------------------------
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_XLA_ENTITE.vue
-- Description      : Création de la vue DKA_XLA_ENTITE
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
PROMPT CREATION DE LA VUE DKA_XLA_ENTITE
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

create or replace view dka_xla_entite as
select distinct XEP.NAME, XEP.LEGAL_ENTITY_IDENTIFIER, XEP.LEGAL_ENTITY_ID
 from   XLE_ENTITY_PROFILES XEP, GL_ACCESS_SET_LEDGERS AC, GL_LEDGERS L, hr_operating_units ou
 where  AC.ACCESS_SET_ID=fnd_profile.value('GL_ACCESS_SET_ID')
  AND L.LEDGER_ID = AC.LEDGER_ID
  and TRANSACTING_ENTITY_FLAG='Y'
  and LEGAL_ENTITY_ID  = ou.default_legal_context_id
  and ou.set_of_books_id=l.ledger_id
  ORDER BY XEP.NAME;
/													
SHOW ERRORS VIEW DKA_SOCIETE_EXTRACT_FISCALE
EXIT