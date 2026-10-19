------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : dka_customers_pr_prov.vue
-- DESCRIPTION      : Création de la vue dka_customers_pr_prov
--
-- AUTEUR           : Julie VIEVILLE (Capgemini)
-- DATE DE CREATION : 23/09/2005
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------
-- 28/12/2005  TB  Modification de la condition 'DAOPCFF_PARTENAIRE'  
--			        	     par'DAOPCFF_COMPLEMENT'.
------------------------------------------------------------------------------------
-- 23/08/2016  OBE Migration R12
------------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE dka_customers_pr_prov
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
create or replace view dka_customers_pr_prov as
select ca.account_number  account_number
, substrb(party.party_name, 1, 50) Customer_Name
, ca.cust_account_id cust_account_id
from hz_cust_accounts ca, hz_parties party
where ca.party_id = party.party_id
--< OBE
/*union
select flex_value account_number
, ffvt.description customer_name
, ffv.flex_value_id cust_account_id
from FND_FLEX_VALUES_TL ffvt, FND_FLEX_VALUES ffv, fnd_flex_value_sets ffvs
where ffv.FLEX_VALUE_ID = ffvt.FLEX_VALUE_ID
and ffvt.LANGUAGE = userenv('LANG')
and ffv.flex_value_set_id = ffvs.flex_value_set_id
and flex_value_set_name like 'DAOPCCF_COMPLEMENT'
and flex_value like 'W%'
and enabled_flag ='Y'*/
--> OBE
order by 2,1;

/
SHOW ERRORS;
EXIT
