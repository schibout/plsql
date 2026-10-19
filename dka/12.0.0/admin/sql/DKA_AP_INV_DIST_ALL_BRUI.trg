CREATE OR REPLACE TRIGGER DKA_APPRVL_STS_LINES_BRI_BRU
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_APPROVAL_STATUS_LINES_BRI_BRU
-- DESCRIPTION	    : Alimentation du champ ATTRIBUTE3 de la table HR_ALL_ORGANIZATION_UNITS
--
-- AUTEUR           : GUILLAUME CHABRIER
-- DATE DE CREATION : 03/01/02
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------

BEFORE INSERT OR UPDATE
ON ap_invoice_distributions_all
FOR EACH ROW

BEGIN
--   'N' - Needs Reapproval
--   'T' - Tested
--   'A' - Approved
--   ''  - Never Approved
--   'X' - No Distributions Exist! --666401

   UPDATE HR_ALL_ORGANIZATION_UNITS haou
   SET    ATTRIBUTE3 = 'Y'
   WHERE  haou.organization_id = :new.org_id
   AND    nvl(:new.match_status_flag, '?') != 'A';


END;
/
SHOW ERRORS;
EXIT;




