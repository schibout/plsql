-- =====================================================================
-- Date de création : 10/04/2026
-- Auteur           : Samir CHIBOUT
-- Base de données  : Oracle EBS 12.2.13
--
-- PROBLÈME RÉSOLU  : Temps d'exécution excessif sur l'export des litiges AP
--
-- CHANGEMENTS PAR RAPPORT À SQL_Export_Gestion_Litiges.sql :
--   1. STRATÉGIE PRINCIPALE : filtre early sur les factures en litige.
--      Toutes les CTEs volumineuses sont restreintes au périmètre des
--      invoices/vendors identifiés dans hold_litige (au lieu de scanner
--      la totalité des tables AP). Eliminé le timeout ORA-17002.
--   2. PER_ALL_PEOPLE_F → filtre SYSDATE BETWEEN effective_start/end_date
--   3. AP_INV_APRVL_HIST_ALL → déduplication via ROW_NUMBER()
--   4. SELECT DISTINCT → supprimé
--   5. IBY_EXTERNAL_PAYEES_ALL → ajout filtre iepa.org_id = api.org_id
--   6. LITIGE_ACTIF → constante 'OUI'
--   7. COMPTABILISATION → un seul MAX(CASE WHEN)
--   8. vendor_balance, distributions_agg, attachments_exist →
--      filtrés sur les IDs du périmètre litige uniquement
-- =====================================================================
WITH
-- ─────────────────────────────────────────────────────────────────────
-- CTE 1 : Holds litige actifs (point d'entrée — périmètre minimal)
-- On commence ici pour réduire au maximum le volume traité par les CTEs
-- suivantes. ROW_NUMBER() élimine la duplication des commentaires refus.
-- ─────────────────────────────────────────────────────────────────────
 hold_litige AS (
    SELECT
        aha.invoice_id,
        aha.hold_lookup_code,
        aha.hold_reason,
        aha.hold_date,
        aha.held_by,
        aipha.approver_comments
      FROM
        ap_holds_all aha
          LEFT JOIN (
            SELECT
                invoice_id,
                approver_comments,
                ROW_NUMBER()
                OVER(PARTITION BY invoice_id
                     ORDER BY
                        creation_date DESC
                ) AS rn
              FROM
                ap_inv_aprvl_hist_all
             WHERE
                response = 'DKA_REFUSE_IVALUA'
        )            aipha ON aipha.invoice_id = aha.invoice_id
           AND aipha.rn = 1
     WHERE
        aha.release_reason IS NULL
           AND aha.hold_lookup_code LIKE '%itige%'
),
-- ─────────────────────────────────────────────────────────────────────
-- CTE 2 : IDs des factures en litige (servant de filtre pour les CTEs
-- volumineuses, évite les full scans sur AP_INVOICE_DISTRIBUTIONS_ALL,
-- FND_ATTACHED_DOCUMENTS et AP_PAYMENT_SCHEDULES_ALL)
-- ─────────────────────────────────────────────────────────────────────
 litige_invoice_ids AS (
    SELECT DISTINCT
        invoice_id
      FROM
        hold_litige
),
-- ─────────────────────────────────────────────────────────────────────
-- CTE 3 : IDs des fournisseurs concernés (restreint vendor_balance)
-- ─────────────────────────────────────────────────────────────────────
 litige_vendor_ids AS (
    SELECT DISTINCT
        vendor_id
      FROM
        ap_invoices_all
     WHERE
        invoice_id IN (
            SELECT
                invoice_id
              FROM
                litige_invoice_ids
        )
),
-- ─────────────────────────────────────────────────────────────────────
-- CTE 4 : Nombre de blocages actifs — restreint aux factures en litige
-- ─────────────────────────────────────────────────────────────────────
 holds_count AS (
    SELECT
        invoice_id,
        COUNT(hold_id) AS nb_blocages_restants
      FROM
        ap_holds_all
     WHERE
        release_reason IS NULL
           AND invoice_id IN (
            SELECT
                invoice_id
              FROM
                litige_invoice_ids
        )
     GROUP BY
        invoice_id
),
-- ─────────────────────────────────────────────────────────────────────
-- CTE 5 : Existence de pièces jointes — restreint aux factures en litige
-- ─────────────────────────────────────────────────────────────────────
 attachments_exist AS (
    SELECT DISTINCT
        pk1_value AS invoice_id_char
      FROM
        fnd_attached_documents
     WHERE
            entity_name = 'AP_INVOICES'
           AND pk1_value IN (
            SELECT
                to_char(invoice_id)
              FROM
                litige_invoice_ids
        )
),
-- ─────────────────────────────────────────────────────────────────────
-- CTE 6 : Agrégation distributions — restreint aux factures en litige
-- Remplace : SUM(amount) corrélé + double EXISTS posted_flag
-- ─────────────────────────────────────────────────────────────────────
 distributions_agg AS (
    SELECT
        invoice_id,
        SUM(amount) AS total_lignes,
        MAX(
            CASE
                WHEN posted_flag = 'N' THEN
                    1
                ELSE
                    0
            END
        )           AS has_unposted
      FROM
        ap_invoice_distributions_all
     WHERE
        invoice_id IN (
            SELECT
                invoice_id
              FROM
                litige_invoice_ids
        )
     GROUP BY
        invoice_id
),
-- ─────────────────────────────────────────────────────────────────────
-- CTE 7 : Solde fournisseur — restreint aux vendors en litige
-- Remplace : la sous-requête double imbriquée O(N×M)
-- Le périmètre est limité aux ~N vendors uniques (vs. tous les vendors)
-- ─────────────────────────────────────────────────────────────────────
 vendor_balance AS (
    SELECT
        api2.vendor_id,
        SUM(appsa2.amount_remaining) AS solde_compte_fournisseur
      FROM
             ap_invoices_all api2
          JOIN ap_payment_schedules_all appsa2 ON appsa2.invoice_id = api2.invoice_id
     WHERE
        api2.vendor_id IN (
            SELECT
                vendor_id
              FROM
                litige_vendor_ids
        )
     GROUP BY
        api2.vendor_id
),
-- ─────────────────────────────────────────────────────────────────────
-- CTE 8 : Employé actif (filtre SCD Type 2 — une ligne par personne)
-- ─────────────────────────────────────────────────────────────────────
 employe_actif AS (
    SELECT
        person_id,
        full_name
      FROM
        apps.per_all_people_f
     WHERE
        sysdate BETWEEN effective_start_date AND effective_end_date
)
SELECT
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
    emp.full_name                                       AS employe_creation_facture,
    api.wfapproval_status                               AS statut,
    api.attribute3                                      AS images_xerox,
    nvl(hc.nb_blocages_restants, 0)                     AS nb_blocages_facture_restants,
    'OUI'                                               AS litige_actif,
    CASE
        WHEN att.invoice_id_char IS NOT NULL THEN
            'OUI'
        ELSE
            'NON'
    END                                                 AS exist_image_facture,
    appsa.hold_flag                                     AS blocage_echeancier,
    api.invoice_amount                                  AS montant_ttc,
    dist.total_lignes                                   AS total_lignes,
    api.amount_paid                                     AS montant_regle,
    appsa.amount_remaining                              AS reste_du,
    vb.solde_compte_fournisseur                         AS solde_compte_fournisseur,
    api.pay_group_lookup_code                           AS type_reglement,
    CASE
        WHEN dist.has_unposted = 1 THEN
            'NON-COMPTABILISEE'
        ELSE
            'COMPTABILISEE'
    END                                                 AS comptabilisation,
    gcc.segment3                                        AS compte_collectif,
    gcc.segment5                                        AS code_partenaire,
    ieba.bank_account_name                              AS nom_compte_bancaire,
    ieba.bank_account_num                               AS numero_compte_bancaire,
    ieba.iban                                           AS iban,
    hl.hold_lookup_code                                 AS hold_lookup_code,
    CASE
        WHEN hl.hold_lookup_code <> hl.hold_reason THEN
            hl.hold_reason
        ELSE
            substr(hl.approver_comments, 1, 550)
    END                                                 AS motif_litige,
    to_char(hl.hold_date, 'DD/MM/YYYY')                 AS hold_date,
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
       AND iepa.org_id = api.org_id
      JOIN hold_litige                 hl ON hl.invoice_id = api.invoice_id
      LEFT JOIN ap_payment_schedules_all    appsa ON api.invoice_id = appsa.invoice_id
      LEFT JOIN apps.fnd_user               fu ON fu.user_id = api.created_by
      LEFT JOIN iby_ext_bank_accounts       ieba ON api.external_bank_account_id = ieba.ext_bank_account_id
      LEFT JOIN employe_actif               emp ON emp.person_id = fu.employee_id
      LEFT JOIN holds_count                 hc ON hc.invoice_id = api.invoice_id
      LEFT JOIN attachments_exist           att ON att.invoice_id_char = to_char(api.invoice_id)
      LEFT JOIN distributions_agg           dist ON dist.invoice_id = api.invoice_id
      LEFT JOIN vendor_balance              vb ON vb.vendor_id = api.vendor_id
      LEFT JOIN apps.fnd_user               fu2 ON fu2.user_id = hl.held_by
 WHERE
    appsa.amount_remaining <> 0
 ORDER BY    api.invoice_id