WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET TIMING ON;
SET PAGESIZE 100;
SET LINESIZE 500;
SET FEEDBACK ON;
PROMPT --- COUNT ---
SELECT COUNT(*) FROM (
--ORA_DONNEES_FACTURES_ANNEE_EN_COURS.csv

WITH
    params AS (
        SELECT DATE '2026-01-01' AS date_min, DATE '2026-05-01' AS date_max FROM dual
    ),
    apsa_min AS (
        SELECT apsa.invoice_id, MIN(TRUNC(apsa.due_date)) AS date_echeance
          FROM apps.ap_payment_schedules_all apsa
      GROUP BY apsa.invoice_id
    ),
    task_numbers AS (
        SELECT pt.task_id, pt.task_number
          FROM apps.pa_tasks pt
    ),
    flex_local AS (
        SELECT ffvv.flex_value, ffvv.description
          FROM fnd_flex_value_sets ffvs
               JOIN fnd_flex_values_vl ffvv
                   ON ffvs.flex_value_set_id = ffvv.flex_value_set_id
         WHERE ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
    ),
    flex_analytique AS (
        SELECT ffvv.flex_value, ffvv.description
          FROM fnd_flex_value_sets ffvs
               JOIN fnd_flex_values_vl ffvv
                   ON ffvs.flex_value_set_id = ffvv.flex_value_set_id
         WHERE ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
    )
SELECT                                                        --ENTETE FACTURE
       aia.invoice_id
           id_et_facture,
       aia.org_id,
       uo.name
           uo_facture,
       aia.gl_date gl_date_facture,
       aia.invoice_num
           numero_facture,
       --       AIA.DOC_SEQUENCE_VALUE
       --           NUM_SEQUENCE_FACTURE,
       CASE
           WHEN aia.source = 'Manual Invoice Entry' THEN 'SAISIE MANUELLE'
           WHEN aia.source IN ('AMONTS', 'SCAN_XGS') THEN 'AMONTS'
           WHEN aia.source = 'REFAC' THEN 'REFACTURATION'
           WHEN aia.source = 'REPRISE' THEN 'REPRISE'
           WHEN aia.source = 'SURTAXE' THEN 'SURTAXE'
           WHEN aia.source = 'FUSION' THEN 'FUSION SOCIETE'
           ELSE aia.source
       END
           source_facture,
       CASE
           WHEN aia.attribute9 IN ('CEE', 'CEG', 'CEC')
           THEN
               'CELERIS'
           WHEN aia.attribute9 = 'HAF'
           THEN
               'PIRENE'
           WHEN aia.attribute9 IN ('ECO', 'OSC', 'RPF')
           THEN
               ''
           WHEN aia.attribute9 IN ('GAZ',
                                   'HAC',
                                   'ING',
                                   'BIO')
           THEN
               'CID'
           WHEN aia.attribute9 = 'CYF'
           THEN
               'CITY'
           WHEN aia.attribute9 = 'DSP'
           THEN
               'IVALUA'
           WHEN aia.attribute9 = 'XGS'
           THEN
               'XEROX_TRADESHIFT'
           WHEN aia.attribute9 = 'VFF'
           THEN
               'DACAR'
           WHEN aia.attribute9 = 'NOT'
           THEN
               'NOTILUS'
           ELSE
               aia.attribute9
       END
           canal_facture,
       REPLACE (aia.description, '"', ' ')
           description_facture,
       aia.invoice_currency_code
           devise_facture,
       aia.invoice_type_lookup_code
           type_facture,
       TRUNC (aia.invoice_date)
           date_facture,
       --       AIA.ATTRIBUTE13
       --           NO_COMMANDE_CANAL,
       DECODE (aia.attribute9, 'DSP', 'Y', 'N')
           dsp_po_flip,
       DECODE (
           aia.attribute9,
           'DSP', DECODE (
                      INSTR (aia.attribute10, 'INV'),
                      0, '',
                      SUBSTR (aia.attribute10,
                              INSTR (aia.attribute10, 'INV'),
                              9)),
           '')
           id_facture_ivalua,
           aia.attribute10 nom_numerisation_facture,
       aia.vendor_id,
       aia.vendor_site_id,
       NVL (aia.invoice_amount, 0)
           montant_facture_ttc,
       NVL (aia.total_tax_amount, 0)
           montant_facture_tax,
       aia.pay_group_lookup_code
           type_reglement,
       DECODE (aia.pay_group_lookup_code, 'PMTDIR', 'OUI', 'NON')
           paiement_direct,
       aia.terms_id,
       apt.name
           payment_terms_name,
       NVL (aia.amount_paid, 0)
           montant_facture_regle,
       apsa.date_echeance,
       --       (SELECT COUNT (HOLD_ID)
       --          FROM AP_HOLDS_ALL
       --         WHERE INVOICE_ID = AIA.INVOICE_ID AND RELEASE_REASON IS NULL)
       --           NB_BLOCAGES_FACTURE_ACTIFS,
       --       CASE
       --           WHEN EXISTS
       --                    (SELECT 'X'
       --                       FROM AP_HOLDS_ALL
       --                      WHERE     INVOICE_ID = AIA.INVOICE_ID
       --                            AND HOLD_LOOKUP_CODE LIKE '%LITIGE%'
       --                            AND RELEASE_REASON IS NULL)
       --           THEN
       --               'OUI'
       --           ELSE
       --               'NON'
       --       END
       --           LITIGE_FACTURE_ACTIF,
       --       CASE
       --           WHEN EXISTS
       --                    (SELECT 'X'
       --                       FROM AP_HOLDS_ALL
       --                      WHERE     INVOICE_ID = AIA.INVOICE_ID
       --                            AND HOLD_LOOKUP_CODE = 'LINE VARIANCE'
       --                            AND RELEASE_REASON IS NULL)
       --           THEN
       --               'OUI'
       --           ELSE
       --               'NON'
       --       END
       --           FACTURE_DESEQUILIBREE,
       --       CASE
       --           WHEN 1 < (SELECT COUNT (*)
       --                       FROM AP_PAYMENT_SCHEDULES_ALL APPSA3
       --                      WHERE APPSA3.INVOICE_ID = AIA.INVOICE_ID)
       --           THEN
       --               'OUI'
       --           ELSE
       --               'NON'
       --       END
       --           ETALEMENT_ECHEANCIER,
       --       DECODE (AP_INVOICES_PKG.GET_POSTING_STATUS (AIA.INVOICE_ID),
       --               'Y', 'COMPTABILISEE',
       --               'N', 'NON COMPTABILISEE',
       --               'P', 'PARTIELLEMENT COMPTABILISEE',
       --               '')
       --           STATUT_COMPTA_FACTURE,
       -- CASE
        --    WHEN aia.cancelled_date IS NOT NULL
        --    THEN
        --        'ANNULEE'
        --    WHEN aia.wfapproval_status = 'NEEDS WFREAPPROVAL'
        --    THEN
        --        'A REVALIDEE'
        --    WHEN aia.wfapproval_status = 'WFAPPROVED'
        --    THEN
        --        'VALIDEE'
        --    ELSE
        --        aia.wfapproval_status
       -- END
           -- statut_validation_facture,  -- Abandon du Statut calculÃ© - modifiÃ© le 21/04/2023 (CÃ©dric/Aubert)
       CASE
           WHEN aia.payment_status_flag = 'N' THEN 'NON REGLEE'
           WHEN aia.payment_status_flag = 'P' THEN 'PARTIELLEMENT REGLEE'
           WHEN aia.payment_status_flag = 'Y' THEN 'TOTALEMENT REGLEE'
       END
           statut_reglement_facture,                                 --A FINIR
       aia.last_update_date
           derniere_modif_facture,
       --LIGNE FACTURE
       aila.line_number
           numero_ligne_fac,
       NVL (aila.quantity_invoiced, 0)
           quantite_ligne_fac,
       NVL (aila.unit_price, 0)
           prix_unitaire_ligne_fac,
       NVL (aila.amount, 0)
           montant_ligne_fac,
       NVL (aila.cancelled_flag, 'N')
           statut_ann_ligne_fac,
       REPLACE (aila.description, '"', ' ')
           description_ligne_fac,
       aila.line_type_lookup_code
           type_ligne_fac,
       aila.po_distribution_id
           id_dist_comm,
       aila.po_header_id
           id_et_commande,
       aila.po_line_id
           id_ligne_commande,
       aila.po_line_location_id
           id_ligne_livr_comm,
       --       AILA.PRODUCT_TYPE
       --           TYPE_PRODUIT,
       --       (SELECT PT_AILA.TASK_NUMBER
       --          FROM APPS.PA_TASKS PT_AILA
       --         WHERE PT_AILA.TASK_ID = AIA.TASK_ID)
       --           TF_LIGNE_FAC,
       --       AILA.EXPENDITURE_TYPE
       --           TYPE_DEPENSE_LIGNE_FAC,
       aila.last_update_date
           derniere_modif_ligne_fac,
       --DISTRIBUTION FACTURE
       aida.invoice_distribution_id
           id_dist_fac,
       aida.distribution_line_number
           numero_dist_fac,
       NVL (aida.quantity_invoiced, 0)
           quantite_dist_fac,
       NVL (aida.unit_price, 0)
           prix_unitaire_dist_fac,
       NVL (aida.amount, 0)
           montant_dist_fac,
       NVL (aida.cancellation_flag, 'N')
           statut_ann_dist_fac,
       REPLACE (aida.description, '"', ' ')
           description_dist_fac,
       aida.line_type_lookup_code
           type_dist_fac,
       pt_aida.task_number
           tf_dist_fac,
       aila.expenditure_type
           type_depense_dist_fac,
       CASE WHEN aida.attribute7 IS NOT NULL THEN 'OUI' ELSE 'NON' END
           refac,
       pt_aida_r.task_number
           tf_dist_refac,
       gcc.segment3
           compte_local,
       fl.description
           desc_compte_local,
       gcc.segment4
           compte_analytique,
       fa.description
           desc_compte_analytique,
       TRUNC (aida.accounting_date)
           date_comptabilisation,                                    --A FINIR
       aida.last_update_date
           derniere_modif_dist_fac,
aia.creation_date date_creation_facture,
 IBY1.PAYMENT_METHOD_NAME mode_reglement_facture,
 statut.statut_facture statut_validation_facture -- RÃ©cupÃ©ration du statut - modifiÃ© le 21/04/2023 (CÃ©dric/Aubert)
  FROM apps.ap_invoices_all  aia
        JOIN apps.hr_organization_units uo ON aia.org_id = uo.organization_id
        JOIN apps.ap_invoice_lines_all aila
            ON aila.invoice_id = aia.invoice_id
        JOIN apps.ap_invoice_distributions_all aida
            ON     aida.invoice_id = aila.invoice_id
            AND aida.invoice_line_number = aila.line_number
        JOIN apps.gl_code_combinations gcc
            ON gcc.code_combination_id = aida.dist_code_combination_id
	    JOIN  iby_payment_methods_tl iby1
            ON (IBY1.PAYMENT_METHOD_CODE = AIA.PAYMENT_METHOD_CODE and iby1.language = 'F')
        LEFT JOIN ap_terms_tl apt
            ON apt.term_id = aia.terms_id AND apt.language = 'F'
        LEFT JOIN apsa_min apsa
            ON apsa.invoice_id = aia.invoice_id
        LEFT JOIN task_numbers pt_aida
            ON pt_aida.task_id = aida.task_id
        LEFT JOIN task_numbers pt_aida_r
            ON pt_aida_r.task_id = aida.attribute7
        LEFT JOIN flex_local fl
            ON fl.flex_value = gcc.segment3
        LEFT JOIN flex_analytique fa
            ON fa.flex_value = gcc.segment4
        JOIN DKA_SAP_STATUT_FACTURE statut  -- pour RÃ©cupÃ©ration du statut - modifiÃ© le 21/04/2023 (CÃ©dric/Aubert)
	        ON aia.invoice_id = statut.invoice_id
        CROSS JOIN params p
 WHERE     1 = 1
       AND aia.invoice_type_lookup_code IN ('STANDARD', 'CREDIT')
       AND aia.cancelled_date IS NULL
       AND NVL (aila.cancelled_flag, 'N') = 'N'
       AND NVL (aida.cancelled_flag, 'N') = 'N'
       --AND TRUNC(AIA.LAST_UPDATE_DATE) BETWEEN :DATE_MIN AND :DATE_MAX
       AND ((aia.last_update_date >= p.date_min AND aia.last_update_date < p.date_max)
         OR (aila.last_update_date >= p.date_min AND aila.last_update_date < p.date_max)
         OR (aida.last_update_date >= p.date_min AND aida.last_update_date < p.date_max))
       AND aila.line_type_lookup_code <> 'TAX'
);
PROMPT --- SAMPLE ---
SELECT * FROM (
--ORA_DONNEES_FACTURES_ANNEE_EN_COURS.csv

WITH
    params AS (
        SELECT DATE '2026-01-01' AS date_min, DATE '2026-05-01' AS date_max FROM dual
    ),
    apsa_min AS (
        SELECT apsa.invoice_id, MIN(TRUNC(apsa.due_date)) AS date_echeance
          FROM apps.ap_payment_schedules_all apsa
      GROUP BY apsa.invoice_id
    ),
    task_numbers AS (
        SELECT pt.task_id, pt.task_number
          FROM apps.pa_tasks pt
    ),
    flex_local AS (
        SELECT ffvv.flex_value, ffvv.description
          FROM fnd_flex_value_sets ffvs
               JOIN fnd_flex_values_vl ffvv
                   ON ffvs.flex_value_set_id = ffvv.flex_value_set_id
         WHERE ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
    ),
    flex_analytique AS (
        SELECT ffvv.flex_value, ffvv.description
          FROM fnd_flex_value_sets ffvs
               JOIN fnd_flex_values_vl ffvv
                   ON ffvs.flex_value_set_id = ffvv.flex_value_set_id
         WHERE ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
    )
SELECT                                                        --ENTETE FACTURE
       aia.invoice_id
           id_et_facture,
       aia.org_id,
       uo.name
           uo_facture,
       aia.gl_date gl_date_facture,
       aia.invoice_num
           numero_facture,
       --       AIA.DOC_SEQUENCE_VALUE
       --           NUM_SEQUENCE_FACTURE,
       CASE
           WHEN aia.source = 'Manual Invoice Entry' THEN 'SAISIE MANUELLE'
           WHEN aia.source IN ('AMONTS', 'SCAN_XGS') THEN 'AMONTS'
           WHEN aia.source = 'REFAC' THEN 'REFACTURATION'
           WHEN aia.source = 'REPRISE' THEN 'REPRISE'
           WHEN aia.source = 'SURTAXE' THEN 'SURTAXE'
           WHEN aia.source = 'FUSION' THEN 'FUSION SOCIETE'
           ELSE aia.source
       END
           source_facture,
       CASE
           WHEN aia.attribute9 IN ('CEE', 'CEG', 'CEC')
           THEN
               'CELERIS'
           WHEN aia.attribute9 = 'HAF'
           THEN
               'PIRENE'
           WHEN aia.attribute9 IN ('ECO', 'OSC', 'RPF')
           THEN
               ''
           WHEN aia.attribute9 IN ('GAZ',
                                   'HAC',
                                   'ING',
                                   'BIO')
           THEN
               'CID'
           WHEN aia.attribute9 = 'CYF'
           THEN
               'CITY'
           WHEN aia.attribute9 = 'DSP'
           THEN
               'IVALUA'
           WHEN aia.attribute9 = 'XGS'
           THEN
               'XEROX_TRADESHIFT'
           WHEN aia.attribute9 = 'VFF'
           THEN
               'DACAR'
           WHEN aia.attribute9 = 'NOT'
           THEN
               'NOTILUS'
           ELSE
               aia.attribute9
       END
           canal_facture,
       REPLACE (aia.description, '"', ' ')
           description_facture,
       aia.invoice_currency_code
           devise_facture,
       aia.invoice_type_lookup_code
           type_facture,
       TRUNC (aia.invoice_date)
           date_facture,
       --       AIA.ATTRIBUTE13
       --           NO_COMMANDE_CANAL,
       DECODE (aia.attribute9, 'DSP', 'Y', 'N')
           dsp_po_flip,
       DECODE (
           aia.attribute9,
           'DSP', DECODE (
                      INSTR (aia.attribute10, 'INV'),
                      0, '',
                      SUBSTR (aia.attribute10,
                              INSTR (aia.attribute10, 'INV'),
                              9)),
           '')
           id_facture_ivalua,
           aia.attribute10 nom_numerisation_facture,
       aia.vendor_id,
       aia.vendor_site_id,
       NVL (aia.invoice_amount, 0)
           montant_facture_ttc,
       NVL (aia.total_tax_amount, 0)
           montant_facture_tax,
       aia.pay_group_lookup_code
           type_reglement,
       DECODE (aia.pay_group_lookup_code, 'PMTDIR', 'OUI', 'NON')
           paiement_direct,
       aia.terms_id,
       apt.name
           payment_terms_name,
       NVL (aia.amount_paid, 0)
           montant_facture_regle,
       apsa.date_echeance,
       --       (SELECT COUNT (HOLD_ID)
       --          FROM AP_HOLDS_ALL
       --         WHERE INVOICE_ID = AIA.INVOICE_ID AND RELEASE_REASON IS NULL)
       --           NB_BLOCAGES_FACTURE_ACTIFS,
       --       CASE
       --           WHEN EXISTS
       --                    (SELECT 'X'
       --                       FROM AP_HOLDS_ALL
       --                      WHERE     INVOICE_ID = AIA.INVOICE_ID
       --                            AND HOLD_LOOKUP_CODE LIKE '%LITIGE%'
       --                            AND RELEASE_REASON IS NULL)
       --           THEN
       --               'OUI'
       --           ELSE
       --               'NON'
       --       END
       --           LITIGE_FACTURE_ACTIF,
       --       CASE
       --           WHEN EXISTS
       --                    (SELECT 'X'
       --                       FROM AP_HOLDS_ALL
       --                      WHERE     INVOICE_ID = AIA.INVOICE_ID
       --                            AND HOLD_LOOKUP_CODE = 'LINE VARIANCE'
       --                            AND RELEASE_REASON IS NULL)
       --           THEN
       --               'OUI'
       --           ELSE
       --               'NON'
       --       END
       --           FACTURE_DESEQUILIBREE,
       --       CASE
       --           WHEN 1 < (SELECT COUNT (*)
       --                       FROM AP_PAYMENT_SCHEDULES_ALL APPSA3
       --                      WHERE APPSA3.INVOICE_ID = AIA.INVOICE_ID)
       --           THEN
       --               'OUI'
       --           ELSE
       --               'NON'
       --       END
       --           ETALEMENT_ECHEANCIER,
       --       DECODE (AP_INVOICES_PKG.GET_POSTING_STATUS (AIA.INVOICE_ID),
       --               'Y', 'COMPTABILISEE',
       --               'N', 'NON COMPTABILISEE',
       --               'P', 'PARTIELLEMENT COMPTABILISEE',
       --               '')
       --           STATUT_COMPTA_FACTURE,
       -- CASE
        --    WHEN aia.cancelled_date IS NOT NULL
        --    THEN
        --        'ANNULEE'
        --    WHEN aia.wfapproval_status = 'NEEDS WFREAPPROVAL'
        --    THEN
        --        'A REVALIDEE'
        --    WHEN aia.wfapproval_status = 'WFAPPROVED'
        --    THEN
        --        'VALIDEE'
        --    ELSE
        --        aia.wfapproval_status
       -- END
           -- statut_validation_facture,  -- Abandon du Statut calculÃ© - modifiÃ© le 21/04/2023 (CÃ©dric/Aubert)
       CASE
           WHEN aia.payment_status_flag = 'N' THEN 'NON REGLEE'
           WHEN aia.payment_status_flag = 'P' THEN 'PARTIELLEMENT REGLEE'
           WHEN aia.payment_status_flag = 'Y' THEN 'TOTALEMENT REGLEE'
       END
           statut_reglement_facture,                                 --A FINIR
       aia.last_update_date
           derniere_modif_facture,
       --LIGNE FACTURE
       aila.line_number
           numero_ligne_fac,
       NVL (aila.quantity_invoiced, 0)
           quantite_ligne_fac,
       NVL (aila.unit_price, 0)
           prix_unitaire_ligne_fac,
       NVL (aila.amount, 0)
           montant_ligne_fac,
       NVL (aila.cancelled_flag, 'N')
           statut_ann_ligne_fac,
       REPLACE (aila.description, '"', ' ')
           description_ligne_fac,
       aila.line_type_lookup_code
           type_ligne_fac,
       aila.po_distribution_id
           id_dist_comm,
       aila.po_header_id
           id_et_commande,
       aila.po_line_id
           id_ligne_commande,
       aila.po_line_location_id
           id_ligne_livr_comm,
       --       AILA.PRODUCT_TYPE
       --           TYPE_PRODUIT,
       --       (SELECT PT_AILA.TASK_NUMBER
       --          FROM APPS.PA_TASKS PT_AILA
       --         WHERE PT_AILA.TASK_ID = AIA.TASK_ID)
       --           TF_LIGNE_FAC,
       --       AILA.EXPENDITURE_TYPE
       --           TYPE_DEPENSE_LIGNE_FAC,
       aila.last_update_date
           derniere_modif_ligne_fac,
       --DISTRIBUTION FACTURE
       aida.invoice_distribution_id
           id_dist_fac,
       aida.distribution_line_number
           numero_dist_fac,
       NVL (aida.quantity_invoiced, 0)
           quantite_dist_fac,
       NVL (aida.unit_price, 0)
           prix_unitaire_dist_fac,
       NVL (aida.amount, 0)
           montant_dist_fac,
       NVL (aida.cancellation_flag, 'N')
           statut_ann_dist_fac,
       REPLACE (aida.description, '"', ' ')
           description_dist_fac,
       aida.line_type_lookup_code
           type_dist_fac,
       pt_aida.task_number
           tf_dist_fac,
       aila.expenditure_type
           type_depense_dist_fac,
       CASE WHEN aida.attribute7 IS NOT NULL THEN 'OUI' ELSE 'NON' END
           refac,
       pt_aida_r.task_number
           tf_dist_refac,
       gcc.segment3
           compte_local,
       fl.description
           desc_compte_local,
       gcc.segment4
           compte_analytique,
       fa.description
           desc_compte_analytique,
       TRUNC (aida.accounting_date)
           date_comptabilisation,                                    --A FINIR
       aida.last_update_date
           derniere_modif_dist_fac,
aia.creation_date date_creation_facture,
 IBY1.PAYMENT_METHOD_NAME mode_reglement_facture,
 statut.statut_facture statut_validation_facture -- RÃ©cupÃ©ration du statut - modifiÃ© le 21/04/2023 (CÃ©dric/Aubert)
  FROM apps.ap_invoices_all  aia
        JOIN apps.hr_organization_units uo ON aia.org_id = uo.organization_id
        JOIN apps.ap_invoice_lines_all aila
            ON aila.invoice_id = aia.invoice_id
        JOIN apps.ap_invoice_distributions_all aida
            ON     aida.invoice_id = aila.invoice_id
            AND aida.invoice_line_number = aila.line_number
        JOIN apps.gl_code_combinations gcc
            ON gcc.code_combination_id = aida.dist_code_combination_id
	    JOIN  iby_payment_methods_tl iby1
            ON (IBY1.PAYMENT_METHOD_CODE = AIA.PAYMENT_METHOD_CODE and iby1.language = 'F')
        LEFT JOIN ap_terms_tl apt
            ON apt.term_id = aia.terms_id AND apt.language = 'F'
        LEFT JOIN apsa_min apsa
            ON apsa.invoice_id = aia.invoice_id
        LEFT JOIN task_numbers pt_aida
            ON pt_aida.task_id = aida.task_id
        LEFT JOIN task_numbers pt_aida_r
            ON pt_aida_r.task_id = aida.attribute7
        LEFT JOIN flex_local fl
            ON fl.flex_value = gcc.segment3
        LEFT JOIN flex_analytique fa
            ON fa.flex_value = gcc.segment4
        JOIN DKA_SAP_STATUT_FACTURE statut  -- pour RÃ©cupÃ©ration du statut - modifiÃ© le 21/04/2023 (CÃ©dric/Aubert)
	        ON aia.invoice_id = statut.invoice_id
        CROSS JOIN params p
 WHERE     1 = 1
       AND aia.invoice_type_lookup_code IN ('STANDARD', 'CREDIT')
       AND aia.cancelled_date IS NULL
       AND NVL (aila.cancelled_flag, 'N') = 'N'
       AND NVL (aida.cancelled_flag, 'N') = 'N'
       --AND TRUNC(AIA.LAST_UPDATE_DATE) BETWEEN :DATE_MIN AND :DATE_MAX
       AND ((aia.last_update_date >= p.date_min AND aia.last_update_date < p.date_max)
         OR (aila.last_update_date >= p.date_min AND aila.last_update_date < p.date_max)
         OR (aida.last_update_date >= p.date_min AND aida.last_update_date < p.date_max))
       AND aila.line_type_lookup_code <> 'TAX'
) WHERE ROWNUM <= 5;
EXIT;
