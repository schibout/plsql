----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : Hélios
-- NOM               : DKA_SARREFAC.ind
-- DESCRIPTION	     : Index des tables spécifiques DKA_SARREFAC
---
--- AUTEUR           : Xavier Descamps (CGEY)
--- DATE DE CREATION : 18/07/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user DKA
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 11/08/2003 XD  Ajout index dka_sarrefac_ap_inv_interf_N1
--------------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX dka_sarrefac_trx_non_oa_soc_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX dka_sarrefac_trx_non_oa_soc_N1;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX dka_sarrefac_trx_non_oa_soc_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX dka_sarrefac_trx_non_oa_soc_N1
ON dka.dka_sarrefac_trx_non_oa_soc
(Trx_Number )
TABLESPACE &1;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT SUPPRESSION DE INDEX dka_sarrefac_ap_inv_interf_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX dka_sarrefac_ap_inv_interf_N1;


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX dka_sarrefac_ap_inv_interf_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX dka_sarrefac_ap_inv_interf_N1
ON dka.dka_sarrefac_ap_inv_interface
(Invoice_Num,
 Vendor_Id,
 Vendor_Site_Id,
 Invoice_Id,
 Line_Number )
TABLESPACE &1;


EXIT;
