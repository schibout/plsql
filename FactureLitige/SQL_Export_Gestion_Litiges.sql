SELECT DISTINCT
    api.invoice_id                                      AS invoice_id,
    api.source                                          AS source,
    api.attribute9                                      AS attribute9,
    substr(uo.name, 1, 3)                               AS region,
    substr(uo.name, 4, 4)                               AS code_societe,
    gll.name                                            AS societe,
    appsa.payment_method_code                           AS mode_reglement_facture,
    api.invoice_num                                     AS numero_facture,
    replace(api.description, ';', ' ')                  AS description_facture,
    api.doc_sequence_value                              AS numero_chrono,
    api.invoice_type_lookup_code                        AS type_facture,
    api.attribute13                                     AS no_commande_xerox,
    aps.vendor_name                                     AS fournisseur,
    aps.segment1                                        AS code_fournisseur,
    apss.vendor_site_code                               AS code_site,
    iepa.default_payment_method_code                    AS mode_reglement_site,
    apss.pay_site_flag                                  AS site_rglt,
    to_char(api.invoice_date, 'DD/MM/YYYY')             AS date_facture,
    to_char(appsa.due_date, 'DD/MM/YYYY')               AS date_echeance,
    appsa.payment_priority                              AS priorite_reglt,
    to_char(api.creation_date, 'DD/MM/YYYY HH24:MI:SS') AS date_creation_facture,
    fu.user_name                                        AS utilisateur_creation_facture,
    papf.full_name                                      AS employe_creation_facture,
    api.wfapproval_status                               AS statut,
    api.attribute3                                      AS images_xerox,
    (
        SELECT
            ( COUNT(hold_id) )
          FROM
            ap_holds_all
         WHERE
                invoice_id = api.invoice_id
               AND release_reason IS NULL
    )                                                   AS nb_blocages_facture_restants,
    CASE
        WHEN EXISTS (
            SELECT
                'X'
              FROM
                ap_holds_all
             WHERE
                    invoice_id = api.invoice_id
                   AND hold_lookup_code LIKE '%litige%'
                   AND release_reason IS NULL
        ) THEN
            'OUI'
        ELSE
            'NON'
    END                                                 AS litige_actif,
    CASE
        WHEN EXISTS (
            SELECT
                'X'
              FROM
                fnd_attached_documents fad
             WHERE
                    fad.pk1_value = to_char(api.invoice_id)
                   AND fad.entity_name = 'AP_INVOICES'
        ) THEN
            'OUI'
        ELSE
            'NON'
    END                                                 AS exist_image_facture,
    appsa.hold_flag                                     AS blocage_echeancier,
    api.invoice_amount                                  AS montant_ttc,
    (
        SELECT
            SUM(apid1.amount)
          FROM
            ap_invoice_distributions_all apid1
         WHERE
            api.invoice_id = apid1.invoice_id
    )                                                   AS total_lignes,
    api.amount_paid                                     AS montant_regle,
    appsa.amount_remaining                              AS reste_du,
    (
        SELECT
            SUM(appsa2.amount_remaining)
          FROM
            ap_payment_schedules_all appsa2
         WHERE
                1 = 1
               AND appsa2.invoice_id IN (
                SELECT
                    invoice_id
                  FROM
                    ap_invoices_all api2
                 WHERE
                    api.vendor_id = api2.vendor_id
            )
    )                                                   AS solde_compte_fournisseur,
    api.pay_group_lookup_code                           AS type_reglement,
    CASE
        WHEN EXISTS (
            SELECT
                'X'
              FROM
                ap_invoice_distributions_all apid
             WHERE
                    api.invoice_id = apid.invoice_id
                   AND apid.posted_flag = 'N'
        ) THEN
            'NON-COMPTABILISEE'
        WHEN NOT EXISTS (
            SELECT
                'X'
              FROM
                ap_invoice_distributions_all apid
             WHERE
                    api.invoice_id = apid.invoice_id
                   AND apid.posted_flag = 'N'
        ) THEN
            'COMPTABILISEE'
    END                                                 AS comptabilisation,
    gcc.segment3                                        AS compte_collectif,
    gcc.segment5                                        AS code_partenaire,
    ieba.bank_account_name                              AS nom_compte_bancaire,
    ieba.bank_account_num                               AS numero_compte_bancaire,
    ieba.iban                                           AS iban,
    aha.hold_lookup_code                                AS hold_lookup_code,
    CASE
        WHEN aha.hold_lookup_code <> aha.hold_reason THEN
            aha.hold_reason
        ELSE
            substr(aipha.approver_comments, 1, 550)
    END                                                 AS motif_litige,
    to_char(aha.hold_date, 'DD/MM/YYYY')                AS hold_date,
    fu2.user_name                                       AS user_name,
    replace(
        replace(fu2.description,
                chr(13),
                ''),
        '!',
        ''
    )                                                   AS description
  FROM
         ap_invoices_all api
      JOIN ap_suppliers                aps ON api.vendor_id = aps.vendor_id
      JOIN ap_supplier_sites_all       apss ON api.vendor_site_id = apss.vendor_site_id
      JOIN hr_organization_units       uo ON api.org_id = uo.organization_id
      JOIN gl_ledgers                  gll ON api.set_of_books_id = gll.ledger_id
      JOIN gl_code_combinations        gcc ON api.accts_pay_code_combination_id = gcc.code_combination_id
      JOIN iby.iby_external_payees_all iepa ON iepa.supplier_site_id = api.vendor_site_id
      LEFT JOIN ap_payment_schedules_all    appsa ON api.invoice_id = appsa.invoice_id
      LEFT JOIN apps.fnd_user               fu ON fu.user_id = api.created_by
      LEFT JOIN iby_ext_bank_accounts       ieba ON api.external_bank_account_id = ieba.ext_bank_account_id
      LEFT JOIN apps.per_all_people_f       papf ON papf.person_id = fu.employee_id
      JOIN ap_holds_all                aha ON aha.invoice_id = api.invoice_id
       AND aha.release_reason IS NULL
       AND aha.hold_lookup_code LIKE '%itige%'
      LEFT OUTER JOIN fnd_user                    fu2 ON fu2.user_id = aha.held_by
      LEFT OUTER JOIN ap_inv_aprvl_hist_all       aipha ON aipha.invoice_id = api.invoice_id
       AND aipha.response = 'DKA_REFUSE_IVALUA'
 WHERE
        1 = 1
       AND appsa.amount_remaining <> 0
 ORDER BY 1