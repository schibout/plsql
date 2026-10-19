----------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET           : Hélios
-- NOM              : DKA_SARREFAC_TRX_APPENDIX_V.vue
-- DESCRIPTION      : Création de la vue DKA_SARREFAC_TRX_APPENDIX_V
--
-- AUTEUR           : Xavier Descamps (CGEY)
-- DATE DE CREATION : 27/02/2002
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 04/02/2003 FLO Il faut mettre la date de la piece a la place de la date GL (sauf pour les pieces GL)
-- 12/12/2003 XD  Jointure externe pour retrouver l'utilsateur d'origine
-- 19/08/2004 STI Portage Specifique 2004 - Modification des champs suivants :
--                "segment4" en "segment5"
--                "ap_acct_segment2" en  "ap_acct_segment4"
--                "ap_acct_segment2_description" en "ap_acct_segment4_description"
-- 23/02/2017 YWA artf2102855 UNION ALL ==> UNION
-- 06/07/2018 RBE artf2840101 : SPE022 - Edition de refacturation
--------------------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SARREFAC_TRX_APPENDIX_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW dka_sarrefac_trx_appendix_v (
    customer_trx_id,
    customer_trx_line_id,
    line_number,
    pa_txn_type,
    pa_txn_id,
    orig_application_id,
    orig_txn_number,
    orig_sequence_number,
    orig_line_date,
    orig_general_account,
    orig_partner_code,
    orig_label,
    post_sell_general_acct_code,
    post_project_number,
    post_project_name,
    post_buy_general_acct_code,
    post_buy_group_acct_code,
    post_buy_group_acct_label,
    line_quantity,
    line_amount,
    user_name,
    task_number,
    task_name,
    project_desc
)
AS
    -- Lignes de type EXPENDITURE d'origine PA
    SELECT dsaai.ar_customer_trx_id customer_trx_id,
           dsaai.ar_customer_trx_line_id customer_trx_line_id,
           dsaai.ar_trx_line_number line_number,
           dsaai.ar_rctlgd_attribute14,
           TO_NUMBER (dsaai.ar_rctlgd_attribute15),
           275,
           pe.expenditure_group orig_txn_number,
           TO_NUMBER (NULL) orig_sequence_number,
           pei.expenditure_item_date orig_line_date,
           pcdl_gcc.segment3 orig_general_account,
           pcdl_gcc.segment5 orig_partner_code, 
           pec.expenditure_comment orig_label,
           dsaai.ar_acct_segment3 post_sell_general_acct_code,
           dsaai.ap_project_number post_project_number,
           dsaai.ap_project_name post_project_name,
           dsaai.ap_acct_segment3 post_buy_general_acct_code,
           dsaai.ap_acct_segment4 post_buy_group_acct_code, 
           dsaai.ap_acct_segment4_description post_buy_group_acct_label, 
           dsaai.ap_pa_quantity line_quantity,
           dsaai.ar_line_amount line_amount,
           NVL (pei.attribute9, fu.user_name),
           dsaai.ap_task_number,
           dsaai.ap_task_name,
           dsaai.ap_project_desc
    FROM   dka_sarrefac_ar_ap_invoices_v dsaai,
           pa_expenditure_items_all pei,
           pa_expenditures_all pe,
           pa_expenditure_comments pec,
           pa_cost_distribution_lines_all pcdl,
           gl_code_combinations pcdl_gcc,
           fnd_user fu
    WHERE      dsaai.ar_rctlgd_attribute14 = 'EXPENDITURE'
           -- Récupération de la ligne de dépense
           AND pei.expenditure_item_id = TO_NUMBER (dsaai.ar_rctlgd_attribute15)
           -- Limitation aux lignes d'origine PA
           AND pei.attribute_category = 'REFAC'
           -- Récupération du lot
           AND pe.expenditure_id = pei.expenditure_id
           -- Récupération du commentaire
           AND pec.expenditure_item_id(+) = pei.expenditure_item_id
           -- Récupération des infos de cout
           AND pcdl.expenditure_item_id = pei.expenditure_item_id
           AND pcdl_gcc.code_combination_id = pcdl.dr_code_combination_id
           AND fu.user_id (+) = pei.created_by
    UNION 
    -- Lignes de type EXPENDITURE d'origine AP
    SELECT dsaai.ar_customer_trx_id customer_trx_id,
           dsaai.ar_customer_trx_line_id customer_trx_line_id,
           dsaai.ar_trx_line_number line_number,
           dsaai.ar_rctlgd_attribute14,
           TO_NUMBER (dsaai.ar_rctlgd_attribute15),
           200,
           orig_ai.invoice_num orig_txn_number,
           orig_ai.doc_sequence_value orig_sequence_number,
           orig_ai.invoice_date orig_line_date,
           orig_aid_gcc.segment3 orig_general_account,
           orig_aid_gcc.segment5 orig_partner_code, 
           orig_pv.vendor_name orig_label,
           dsaai.ar_acct_segment3 post_sell_general_acct_code,
           dsaai.ap_project_number post_project_number,
           dsaai.ap_project_name post_project_name,
           dsaai.ap_acct_segment3 post_buy_general_acct_code,
           dsaai.ap_acct_segment4 post_buy_group_acct_code, 
           dsaai.ap_acct_segment4_description post_buy_group_acct_label, 
           dsaai.ap_pa_quantity line_quantity,
           dsaai.ar_line_amount line_amount,
           NVL (orig_aid.attribute9, fu.user_name),
           dsaai.ap_task_number,
           dsaai.ap_task_name,
           dsaai.ap_project_desc
    FROM   dka_sarrefac_ar_ap_invoices_v dsaai,
           pa_expenditure_items_all pei,
           pa_cost_distribution_lines_all pcdl,
           ap_invoices_all orig_ai,
           ap_invoice_distributions_all orig_aid,
           po_vendors orig_pv,
           gl_code_combinations orig_aid_gcc,
           fnd_user fu
    WHERE      dsaai.ar_rctlgd_attribute14 = 'EXPENDITURE'
           -- Récupération de la ligne de dépense
           AND pei.expenditure_item_id = TO_NUMBER (dsaai.ar_rctlgd_attribute15)
           -- Limitation aux lignes d'origine AP
           AND pei.attribute_category = 'AP_REFAC'
           AND pei.system_linkage_function IN ('VI', 'ER')
           -- Récupération de la facture AP d'origine
           AND pcdl.expenditure_item_id = pei.expenditure_item_id
           --AND orig_ai.invoice_id = TO_NUMBER (pcdl.system_reference2) -- RBE artf2840101
           AND orig_aid.invoice_id = orig_ai.invoice_id
           --AND orig_aid.distribution_line_number = TO_NUMBER (pcdl.system_reference3) -- RBE artf2840101
           AND pei.document_distribution_id = orig_aid.invoice_distribution_id -- RBE artf2840101
           AND orig_aid_gcc.code_combination_id = pcdl.dr_code_combination_id
           -- Récupération du fournisseur d'origine
           AND orig_pv.vendor_id = orig_ai.vendor_id
           AND fu.user_id (+) = orig_aid.created_by
    UNION 
    -- Lignes de type EXPENDITURE d'origine GL
    SELECT dsaai.ar_customer_trx_id customer_trx_id,
           dsaai.ar_customer_trx_line_id customer_trx_line_id,
           dsaai.ar_trx_line_number line_number,
           dsaai.ar_rctlgd_attribute14,
           TO_NUMBER (dsaai.ar_rctlgd_attribute15),
           101,
           gjh.NAME orig_txn_number,
           gjh.doc_sequence_value orig_sequence_number,
           gjl.effective_date orig_line_date,
           gjl_gcc.segment3 orig_general_account,
           gjl_gcc.segment5 orig_partner_code, 
           gjl.description orig_label,
           dsaai.ar_acct_segment3 post_sell_general_acct_code,
           dsaai.ap_project_number post_project_number,
           dsaai.ap_project_name post_project_name,
           dsaai.ap_acct_segment3 post_buy_general_acct_code,
           dsaai.ap_acct_segment4 post_buy_group_acct_code, 
           dsaai.ap_acct_segment4_description post_buy_group_acct_label, 
           dsaai.ap_pa_quantity line_quantity,
           dsaai.ar_line_amount line_amount,
           NVL (gjl.attribute9, fu.user_name),
           dsaai.ap_task_number,
           dsaai.ap_task_name,
           dsaai.ap_project_desc
    FROM   dka_sarrefac_ar_ap_invoices_v dsaai,
           pa_expenditure_items_all pei,
           pa_expenditures_all pe,
           pa_cost_distribution_lines_all pcdl,
           gl_je_headers gjh,
           gl_je_lines gjl,
           gl_period_statuses gps,
           gl_code_combinations gjl_gcc,
           fnd_user fu
    WHERE      dsaai.ar_rctlgd_attribute14 = 'EXPENDITURE'
           -- Récupération de la ligne de dépense
           AND pei.expenditure_item_id = TO_NUMBER (dsaai.ar_rctlgd_attribute15)
           -- Limitation aux lignes d'origine GL
           AND pei.attribute_category = 'GL_REFAC'
           -- Récupération du lot
           AND pe.expenditure_id = pei.expenditure_id
           -- Récupération des infos de cout
           AND pcdl.expenditure_item_id = pei.expenditure_item_id
           -- Récupération de la ligne GL
           --AND gjh.je_header_id = TO_NUMBER (SUBSTR (pei.attribute4, 1, (INSTR (pei.attribute4, '_') - 1)))
           AND gjh.je_header_id = TO_NUMBER (pei.attribute4)
           AND gjl.je_header_id = gjh.je_header_id
           --AND gjl.je_line_num = TO_NUMBER (SUBSTR (pei.attribute4, (INSTR (pei.attribute4, '_') + 1)))
		   AND gjl.je_line_num = TO_NUMBER (pei.attribute8)
           -- Récupération de la période
           AND gps.period_name = gjh.period_name
           AND gps.set_of_books_id = gjh.ledger_id
           AND gps.application_id = 101
           -- Récupération de la clé comptable d'origine
           AND gjl_gcc.code_combination_id = gjl.code_combination_id
           AND gjl.created_by = fu.user_id (+)
    UNION 
    -- Lignes de type EVENT d'origine AR
    SELECT dsaai.ar_customer_trx_id customer_trx_id,
           dsaai.ar_customer_trx_line_id customer_trx_line_id,
           dsaai.ar_trx_line_number line_number,
           dsaai.ar_rctlgd_attribute14,
           TO_NUMBER (dsaai.ar_rctlgd_attribute15),
           222,
           orig_rct.trx_number orig_txn_number,
           orig_rct.doc_sequence_value orig_sequence_number,
           orig_rct.trx_date orig_line_date,
           orig_rctlgd_gcc.segment3 orig_general_account,
           orig_rctlgd_gcc.segment5 orig_partner_code, 
           orig_rc.customer_name orig_label,
           dsaai.ar_acct_segment3 post_sell_general_acct_code,
           dsaai.ap_project_number post_project_number,
           dsaai.ap_project_name post_project_name,
           dsaai.ap_acct_segment3 post_buy_general_acct_code,
           dsaai.ap_acct_segment4 post_buy_group_acct_code, 
           dsaai.ap_acct_segment4_description post_buy_group_acct_label, 
           dsaai.ap_pa_quantity line_quantity,
           dsaai.ar_line_amount line_amount,
           NVL (orig_rct.attribute9, fu.user_name),
           dsaai.ap_task_number,
           dsaai.ap_task_name,
           dsaai.ap_project_desc
    FROM   dka_sarrefac_ar_ap_invoices_v dsaai,
           pa_events pe,
           ra_customer_trx_all orig_rct,
           ra_cust_trx_line_gl_dist_all orig_rctlgd,
           gl_code_combinations orig_rctlgd_gcc,
           ar_customers orig_rc,
           fnd_user fu
    WHERE      dsaai.ar_rctlgd_attribute14 = 'EVENT'
           -- Récupération de la ligne d'évenement
           AND pe.event_id = TO_NUMBER (dsaai.ar_rctlgd_attribute15)
           -- Limitation aux lignes d'origine AR
           AND pe.attribute_category = 'AR_REFAC'
           -- Récupération de la ligne de facture d'origine
           AND orig_rctlgd.cust_trx_line_gl_dist_id = TO_NUMBER (pe.attribute4)
           AND orig_rct.customer_trx_id = orig_rctlgd.customer_trx_id
           AND orig_rctlgd_gcc.code_combination_id = orig_rctlgd.code_combination_id
           AND orig_rc.customer_id = orig_rct.bill_to_customer_id
           AND fu.user_id (+) = orig_rct.created_by
    UNION 
    -- Lignes de type EVENT d'origine GL
    SELECT dsaai.ar_customer_trx_id customer_trx_id,
           dsaai.ar_customer_trx_line_id customer_trx_line_id,
           dsaai.ar_trx_line_number line_number,
           dsaai.ar_rctlgd_attribute14,
           TO_NUMBER (dsaai.ar_rctlgd_attribute15),
           101,
           gjh.NAME orig_txn_number,
           gjh.doc_sequence_value orig_sequence_number,
           gjl.effective_date orig_line_date,
           gjl_gcc.segment3 orig_general_account,
           gjl_gcc.segment5 orig_partner_code, 
           gjl.description orig_label,
           dsaai.ar_acct_segment3 post_sell_general_acct_code,
           dsaai.ap_project_number post_project_number,
           dsaai.ap_project_name post_project_name,
           dsaai.ap_acct_segment3 post_buy_general_acct_code,
           dsaai.ap_acct_segment4 post_buy_group_acct_code, 
           dsaai.ap_acct_segment4_description post_buy_group_acct_label, 
           dsaai.ap_pa_quantity line_quantity,
           dsaai.ar_line_amount line_amount,
           NVL (gjl.attribute9, fu.user_name),
           dsaai.ap_task_number,
           dsaai.ap_task_name,
           dsaai.ap_project_desc
    FROM   dka_sarrefac_ar_ap_invoices_v dsaai,
           pa_events pe,
           gl_je_headers gjh,
           gl_je_lines gjl,
           gl_period_statuses gps,
           gl_code_combinations gjl_gcc,
           fnd_user fu
    WHERE      dsaai.ar_rctlgd_attribute14 = 'EVENT'
           -- Récupération de la ligne d'évenement
           AND pe.event_id = TO_NUMBER (dsaai.ar_rctlgd_attribute15)
           -- Limitation aux lignes d'origine GL
           AND pe.attribute_category = 'GL_REFAC'
           -- Récupération de la ligne GL
           --AND gjh.je_header_id = TO_NUMBER (SUBSTR (pe.attribute5, 1, (INSTR (pe.attribute5, '_') - 1)))
           AND gjh.je_header_id = TO_NUMBER (pe.attribute5)
           AND gjl.je_header_id = gjh.je_header_id
           --AND gjl.je_line_num = TO_NUMBER (SUBSTR (pe.attribute5, (INSTR (pe.attribute5, '_') + 1)))
           AND gjl.je_line_num = TO_NUMBER (pe.attribute8)
           -- Récupération de la période
           AND gps.period_name = gjh.period_name
           AND gps.set_of_books_id = gjh.ledger_id
           AND gps.application_id = 101
           -- Récupération de la clé comptable d'origine
           AND gjl_gcc.code_combination_id = gjl.code_combination_id
           AND fu.user_id (+) = gjl.created_by;

SHOW ERROR

EXIT
/
