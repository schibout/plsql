--ORA_DONNEES_FACTURES_ANNEE_EN_COURS.csv

SELECT                                                        --ENTETE FACTURE
       aia.invoice_id
           id_et_facture,
       aia.org_id,
       (SELECT uo.name
          FROM apps.hr_organization_units uo
         WHERE aia.org_id = uo.organization_id)
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
       (SELECT apt.name
          FROM ap_terms_tl apt
         WHERE apt.term_id = aia.terms_id AND apt.language = 'F')
           payment_terms_name,
       NVL (aia.amount_paid, 0)
           montant_facture_regle,
       (SELECT MIN (TRUNC (apsa.due_date))
          FROM apps.ap_payment_schedules_all apsa
         WHERE apsa.invoice_id = aia.invoice_id)
           date_echeance,
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
           -- statut_validation_facture,  -- Abandon du Statut calculé - modifié le 21/04/2023 (Cédric/Aubert)
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
       (SELECT pt_aida.task_number
          FROM apps.pa_tasks pt_aida
         WHERE pt_aida.task_id = aida.task_id)
           tf_dist_fac,
       aila.expenditure_type
           type_depense_dist_fac,
       CASE WHEN aida.attribute7 IS NOT NULL THEN 'OUI' ELSE 'NON' END
           refac,
       (SELECT pt_aida_r.task_number
          FROM apps.pa_tasks pt_aida_r
         WHERE pt_aida_r.task_id = aida.attribute7)
           tf_dist_refac,
       gcc.segment3
           compte_local,
       (SELECT ffvv.description
          FROM fnd_flex_value_sets  ffvs
               JOIN fnd_flex_values_vl ffvv
                   ON     ffvs.flex_value_set_id = ffvv.flex_value_set_id
                      AND ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
         WHERE 1 = 1 AND ffvv.flex_value = gcc.segment3)
           desc_compte_local,
       gcc.segment4
           compte_analytique,
       (SELECT ffvv.description
          FROM fnd_flex_value_sets  ffvs
               JOIN fnd_flex_values_vl ffvv
                   ON     ffvs.flex_value_set_id = ffvv.flex_value_set_id
                      AND ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
         WHERE 1 = 1 AND ffvv.flex_value = gcc.segment4)
           desc_compte_analytique,
       TRUNC (aida.accounting_date)
           date_comptabilisation,                                    --A FINIR
       aida.last_update_date
           derniere_modif_dist_fac,
aia.creation_date date_creation_facture,
 IBY1.PAYMENT_METHOD_NAME mode_reglement_facture,
 statut.statut_facture statut_validation_facture -- Récupération du statut - modifié le 21/04/2023 (Cédric/Aubert)
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
        JOIN DKA_SAP_STATUT_FACTURE statut  -- pour Récupération du statut - modifié le 21/04/2023 (Cédric/Aubert)
	        ON aia.invoice_id = statut.invoice_id
 WHERE     1 = 1
       AND aia.invoice_type_lookup_code IN ('STANDARD', 'CREDIT')
       AND aia.cancelled_date IS NULL
       AND NVL (aila.cancelled_flag, 'N') = 'N'
       AND NVL (aida.cancelled_flag, 'N') = 'N'
       --AND TRUNC(AIA.LAST_UPDATE_DATE) BETWEEN :DATE_MIN AND :DATE_MAX
       AND (aia.last_update_date >=
           TO_DATE ('01/05/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS') OR aila.last_update_date >=
           TO_DATE ('01/05/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS') OR aida.last_update_date >=
           TO_DATE ('01/05/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'))
		AND (aia.last_update_date <
           TO_DATE ('01/09/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS') OR aila.last_update_date <
           TO_DATE ('01/09/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS') OR aida.last_update_date <
           TO_DATE ('01/09/2026 00:00:00', 'DD/MM/YYYY HH24:MI:SS'))
       AND aila.line_type_lookup_code <> 'TAX';