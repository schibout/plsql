WITH
    /* ── 1. Comptage des blocages actifs par facture (remplace sous-requête COUNT corrélée) ── */
    HOLDS_COUNT AS (
        SELECT /*+ MATERIALIZE */
               invoice_id,
               COUNT(hold_id) AS nb_blocages
          FROM ap_holds_all
         WHERE release_reason IS NULL
         GROUP BY invoice_id
    ),
    /* ── 2. Total des lignes de distribution par facture (remplace sous-requête SUM corrélée) ── */
    TOTAL_LIGNES AS (
        SELECT /*+ MATERIALIZE */
               invoice_id,
               SUM(amount) AS total_lignes
          FROM ap_invoice_distributions_all
         GROUP BY invoice_id
    ),
    /* ── 3. Statut de comptabilisation par facture (remplace deux EXISTS corrélés) ── */
    COMPTA_STATUS AS (
        SELECT /*+ MATERIALIZE */
               invoice_id,
               CASE
                   WHEN SUM(CASE WHEN posted_flag = 'N' THEN 1 ELSE 0 END) > 0
                   THEN 'NON-COMPTABILISEE'
                   ELSE 'COMPTABILISEE'
               END AS comptabilisation
          FROM ap_invoice_distributions_all
         GROUP BY invoice_id
    ),
    /* ── 4. Existence de documents attachés par facture (remplace EXISTS corrélé) ── */
    HAS_IMAGE AS (
        SELECT /*+ MATERIALIZE */
               TO_NUMBER(fad.pk1_value) AS invoice_id,
               'OUI'                    AS exist_image
          FROM fnd_attached_documents fad
         WHERE fad.entity_name = 'AP_INVOICES'
         GROUP BY TO_NUMBER(fad.pk1_value)
    ),
    /* ── 5. Solde total fournisseur (remplace la double sous-requête corrélée imbriquée) ── */
    SOLDE_FOURNISSEUR AS (
        SELECT /*+ MATERIALIZE */
               api2.vendor_id,
               SUM(appsa2.amount_remaining) AS solde_compte
          FROM ap_payment_schedules_all appsa2
               JOIN ap_invoices_all api2 ON api2.invoice_id = appsa2.invoice_id
         GROUP BY api2.vendor_id
    ),
    /* ── 6. per_all_people_f dédoublonné : dernière version par person_id ── */
    PEOPLE_CTE AS (
        SELECT /*+ MATERIALIZE */
               person_id,
               full_name
          FROM (
               SELECT person_id,
                      full_name,
                      ROW_NUMBER() OVER (PARTITION BY person_id
                                         ORDER BY effective_end_date DESC) AS rn
                 FROM apps.per_all_people_f
          )
         WHERE rn = 1
    ),
    /* ── 7. Un seul refus DKA_REFUSE_IVALUA par facture (dernier en date) ── */
    AIPHA_DEDUP AS (
        SELECT /*+ MATERIALIZE */
               invoice_id,
               approver_comments
          FROM (
               SELECT invoice_id,
                      approver_comments,
                      ROW_NUMBER() OVER (PARTITION BY invoice_id
                                         ORDER BY creation_date DESC) AS rn
                 FROM ap_inv_aprvl_hist_all
                WHERE response = 'DKA_REFUSE_IVALUA'
          )
         WHERE rn = 1
    ),
    /* ── 8. Un seul blocage litige actif par facture (dernier en date) ── */
    AHA_DEDUP AS (
        SELECT /*+ MATERIALIZE */
               invoice_id,
               hold_lookup_code,
               hold_reason,
               hold_date,
               held_by
          FROM (
               SELECT invoice_id,
                      hold_lookup_code,
                      hold_reason,
                      hold_date,
                      held_by,
                      ROW_NUMBER() OVER (PARTITION BY invoice_id
                                         ORDER BY hold_date DESC) AS rn
                 FROM ap_holds_all
                WHERE release_reason IS NULL
                  AND hold_lookup_code LIKE '%itige%'
          )
         WHERE rn = 1
    ),
    /* ── 9. IBY payee dédoublonné : un seul enregistrement par (site, OU) ── */
    IEPA_DEDUP AS (
        SELECT /*+ MATERIALIZE */
               supplier_site_id,
               org_id,
               default_payment_method_code
          FROM (
               SELECT supplier_site_id,
                      org_id,
                      default_payment_method_code,
                      ROW_NUMBER() OVER (PARTITION BY supplier_site_id, org_id
                                         ORDER BY ext_payee_id DESC) AS rn
                 FROM iby.iby_external_payees_all
                WHERE payment_function = 'PAYABLES_DISB'
                  AND org_type         = 'OPERATING_UNIT'
          )
         WHERE rn = 1
    )
SELECT
    api.invoice_id                                        AS invoice_id,
    api.source                                            AS source,
    api.attribute9                                        AS attribute9,
    SUBSTR(uo.name, 1, 3)                                 AS region,
    SUBSTR(uo.name, 4, 4)                                 AS code_societe,
    gll.name                                              AS societe,
    appsa.payment_method_code                             AS mode_reglement_facture,
    api.invoice_num                                       AS numero_facture,
    REPLACE(api.description, ';', ' ')                    AS description_facture,
    api.doc_sequence_value                                AS numero_chrono,
    api.invoice_type_lookup_code                          AS type_facture,
    api.attribute13                                       AS no_commande_xerox,
    aps.vendor_name                                       AS fournisseur,
    aps.segment1                                          AS code_fournisseur,
    apss.vendor_site_code                                 AS code_site,
    iepa.default_payment_method_code                      AS mode_reglement_site,
    apss.pay_site_flag                                    AS site_rglt,
    TO_CHAR(api.invoice_date, 'DD/MM/YYYY')               AS date_facture,
    TO_CHAR(appsa.due_date, 'DD/MM/YYYY')                 AS date_echeance,
    appsa.payment_priority                                AS priorite_reglt,
    TO_CHAR(api.creation_date, 'DD/MM/YYYY HH24:MI:SS')   AS date_creation_facture,
    fu.user_name                                          AS utilisateur_creation_facture,
    pc.full_name                                          AS employe_creation_facture,
    api.wfapproval_status                                 AS statut,
    api.attribute3                                        AS images_xerox,
    NVL(hc.nb_blocages, 0)                                AS nb_blocages_facture_restants,
    CASE
        WHEN LOWER(aha.hold_lookup_code) LIKE '%litige%' THEN 'OUI'
        ELSE 'NON'
    END                                                   AS litige_actif,
    NVL(hi.exist_image, 'NON')                           AS exist_image_facture,
    appsa.hold_flag                                       AS blocage_echeancier,
    api.invoice_amount                                    AS montant_ttc,
    tl.total_lignes                                       AS total_lignes,
    api.amount_paid                                       AS montant_regle,
    appsa.amount_remaining                                AS reste_du,
    sf.solde_compte                                       AS solde_compte_fournisseur,
    api.pay_group_lookup_code                             AS type_reglement,
    NVL(cs.comptabilisation, 'COMPTABILISEE')             AS comptabilisation,
    gcc.segment3                                          AS compte_collectif,
    gcc.segment5                                          AS code_partenaire,
    ieba.bank_account_name                                AS nom_compte_bancaire,
    ieba.bank_account_num                                 AS numero_compte_bancaire,
    ieba.iban                                             AS iban,
    aha.hold_lookup_code                                  AS hold_lookup_code,
    CASE
        WHEN aha.hold_lookup_code <> aha.hold_reason THEN aha.hold_reason
        ELSE SUBSTR(ad.approver_comments, 1, 550)
    END                                                   AS motif_litige,
    TO_CHAR(aha.hold_date, 'DD/MM/YYYY')                  AS hold_date,
    fu2.user_name                                         AS user_name,
    REPLACE(REPLACE(fu2.description, CHR(13), ''), '!', '') AS description
  FROM ap_invoices_all            api
       JOIN ap_suppliers           aps   ON aps.vendor_id   = api.vendor_id
       JOIN ap_supplier_sites_all  apss  ON apss.vendor_site_id = api.vendor_site_id
       JOIN hr_organization_units  uo    ON uo.organization_id  = api.org_id
       JOIN gl_ledgers             gll   ON gll.ledger_id        = api.set_of_books_id
       JOIN gl_code_combinations   gcc   ON gcc.code_combination_id = api.accts_pay_code_combination_id
       JOIN AHA_DEDUP              aha   ON aha.invoice_id   = api.invoice_id
       LEFT JOIN IEPA_DEDUP        iepa  ON iepa.supplier_site_id = api.vendor_site_id
                                       AND iepa.org_id            = api.org_id
       LEFT JOIN ap_payment_schedules_all appsa ON appsa.invoice_id       = api.invoice_id
                                               AND appsa.amount_remaining <> 0
       LEFT JOIN apps.fnd_user     fu    ON fu.user_id    = api.created_by
       LEFT JOIN iby_ext_bank_accounts ieba ON ieba.ext_bank_account_id = api.external_bank_account_id
       LEFT JOIN PEOPLE_CTE        pc    ON pc.person_id  = fu.employee_id
       LEFT JOIN apps.fnd_user     fu2   ON fu2.user_id   = aha.held_by
       LEFT JOIN AIPHA_DEDUP       ad    ON ad.invoice_id  = api.invoice_id
       LEFT JOIN HOLDS_COUNT       hc    ON hc.invoice_id  = api.invoice_id
       LEFT JOIN TOTAL_LIGNES      tl    ON tl.invoice_id  = api.invoice_id
       LEFT JOIN HAS_IMAGE         hi    ON hi.invoice_id  = api.invoice_id
       LEFT JOIN COMPTA_STATUS     cs    ON cs.invoice_id  = api.invoice_id
       LEFT JOIN SOLDE_FOURNISSEUR sf    ON sf.vendor_id   = api.vendor_id
 ORDER BY 1