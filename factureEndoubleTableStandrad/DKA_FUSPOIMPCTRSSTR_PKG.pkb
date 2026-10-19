----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : Hélios
-- NOM              : DKA_SARREFAC_AR_AP_INVOICES_V.vue
-- DESCRIPTION      : Création de la vue DKA_SARREFAC_AR_AP_INVOICES_V
--
-- AUTEUR           : Xavier Descamps (CGEY)
-- DATE DE CREATION : 25/02/2002
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 11/03/2002 XD  Correction du lien avec la facture AP
-- 20/11/2003 XD  Lien avec AP : utilisation de l'attribute13 de AP au lieu du numéro de ligne
-- 19/08/2004 STI Portage PHENIX 204 modification des champs 'ap_acct_segment2' en 'ap_acct_segment4' et 'ap_acct_segment2_description' en 'ap_acct_segment4_description'
--                Suppression des tables hr_all_organization_units
--                Société AR = 4 premiers caracteres du type de mouvement
--                Société AP = 4 premiers caracteres du type de piece
--                Segment2 devient segment4
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SARREFAC_AR_AP_INVOICES_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW dka_sarrefac_ar_ap_invoices_v (ar_trx_number,
                                                      ar_customer_trx_id,
                                                      ar_customer_trx_line_id,
                                                      ar_cust_trx_line_gl_dist_id,
                                                      ar_trx_line_number,
                                                      ar_line_amount,
                                                      ar_code_combination_id,
                                                      ar_acct_segment3,
                                                      ar_rctlgd_attribute14,
                                                      ar_rctlgd_attribute15,
                                                      ap_invoice_id,
                                                      ap_distribution_line_number,
                                                      ap_code_combination_id,
                                                      ap_acct_segment3,
                                                      -- ap_acct_segment2, -- PHENIX 2004
                                                      -- ap_acct_segment2_description, -- PHENIX 2004
                                                      ap_acct_segment4,               -- PHENIX 2004
                                                      ap_acct_segment4_description,   -- PHENIX 2004
                                                      ap_pa_quantity,
                                                      ap_project_id,
                                                      ap_project_number,
                                                      ap_project_name,
                                                      ap_task_id,
                                                      ap_task_number,
                                                      ap_task_name,
                                                      ap_project_desc
                                                     ) AS
  SELECT rct.trx_number, rct.customer_trx_id, rctl.customer_trx_line_id,
         rctlgd.cust_trx_line_gl_dist_id, rctl.line_number, rctl.extended_amount,
         rctlgd.code_combination_id, rctlgd_gcc.segment3, rctlgd.attribute14, rctlgd.attribute15,
         ai.invoice_id, aid.distribution_line_number, aid.dist_code_combination_id,
         aid_gcc.segment3, aid_gcc.segment4,                         -- aid_gcc.segment2 PHENIX 2004
         ffv.description,
         DECODE (pet.unit_of_measure, 'EUR', NULL, aid.pa_quantity) pa_quantity, pp.project_id,
         pp.segment1, pp.NAME, pt.task_id, pt.task_number, pt.task_name task_name, substr(pp.description,1,30)
    FROM ra_customer_trx_all rct,
         ra_cust_trx_types_all rctt,
         ra_customer_trx_lines_all rctl,
         ra_cust_trx_line_gl_dist_all rctlgd,
         gl_code_combinations rctlgd_gcc,
         ar_customers rc,
         po_vendors pv,
         ap_invoices_all ai,
         ap_invoice_distributions_all aid,
         ap_invoice_lines_all ail,
         gl_code_combinations aid_gcc,
         pa_projects_all pp,
         pa_tasks pt,
         pa_expenditure_types pet,
         gl_ledgers gsob,
         fnd_id_flex_segments fifs,
         fnd_flex_values_vl ffv,
         gl_access_set_assignments gasa
   WHERE 1 = 1
     AND rct.customer_trx_id = rctl.customer_trx_id
     AND rctl.line_type = 'LINE'
     -- Récupération des lignes de facture AR de Refac
     AND rctlgd.customer_trx_id = rctl.customer_trx_id
     AND rctlgd.customer_trx_line_id = rctl.customer_trx_line_id
     AND rctlgd.account_set_flag = 'N'
     AND rctlgd.account_class = 'REV'
     AND rctlgd_gcc.code_combination_id = rctlgd.code_combination_id
     -- Récupération de l'org_id de AP
     AND rc.customer_id = rct.bill_to_customer_id
     ---AND SUBSTR (ai.doc_category_code, 1, 4) = rc.attribute1
     -- Récupération du fournisseur
     AND rct.cust_trx_type_id = rctt.cust_trx_type_id
     ---AND pv.attribute2 = SUBSTR (rctt.NAME, 1, 4)
     AND ai.vendor_id = pv.vendor_id
     -- Récupération de la ligne de facture AP de Refac
     AND ai.invoice_num = rct.trx_number
     AND aid.invoice_id = ai.invoice_id
     AND ail.invoice_id = ai.invoice_id
     AND aid.INVOICE_LINE_NUMBER = ail.line_number
     --AND aid.distribution_line_number = TO_NUMBER (rctlgd.attribute13)
     --AND aid.attribute13 = rctlgd.attribute13
     AND ail.attribute13 = rctlgd.attribute13
     AND aid_gcc.code_combination_id = aid.dist_code_combination_id
     -- Récupération du projet
     AND pp.project_id = aid.project_id
     -- Récupération de la tâche
     AND pt.task_id = aid.task_id
     -- Récupération du type de dépense
     AND pet.expenditure_type = aid.expenditure_type
     -- Récupération du libellé du segment4 AP
     AND gasa.access_set_id =  Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
     AND gsob.name = 'OPERATIONNEL'
     AND gsob.ledger_id = gasa.ledger_id
     AND fifs.application_id = 101
     AND fifs.id_flex_code = 'GL#'
     AND fifs.id_flex_num = gsob.chart_of_accounts_id
     AND fifs.segment_num = 4 -- = 2 PHENIX 2004
     AND ffv.flex_value_set_id = fifs.flex_value_set_id
     AND ffv.flex_value = aid_gcc.segment4
/

SHOW ERROR

EXIT
