----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_IARPAFAC_CUSTOMERS_V.vue
-- DESCRIPTION	    : Création de la vue DKA_IARPAFAC_CUSTOMERS_V
--
-- AUTEUR           : Xavier Descamps (CGEY)
-- DATE DE CREATION : 20/01/2004
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 06/10/2005 GV  Adaptation Phénix : ne plus utiliser la table hr_all_organization_units
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_IARPAFAC_CUSTOMERS_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_IARPAFAC_CUSTOMERS_V
(ref_anael,
 customer_name
)
AS
SELECT DISTINCT
       hcasa.attribute3,
       rc.customer_name
FROM hz_cust_acct_sites_all hcasa,
     ar_customers rc,
     hz_cust_site_uses_all hcsua
WHERE rc.customer_id = hcasa.cust_account_id
  AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
  AND hcasa.attribute3 IS NOT NULL
  AND hcasa.status = 'A'
UNION
SELECT '00000000',
       NULL
FROM dual;

SHOW ERROR

EXIT
