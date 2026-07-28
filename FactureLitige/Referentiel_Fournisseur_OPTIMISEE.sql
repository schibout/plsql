/* LISTE DES SITES FOURNISSEURS ACTIFS PAR REGION R12 */
-- =====================================================================
-- Referentiel_Fournisseur_OPTIMISEE.sql
-- =====================================================================
-- Date de création : 10/04/2026
-- Auteur           : GitHub Copilot
-- Base de données  : Oracle EBS 12.2.13
--
-- PROBLÈME RÉSOLU  : Temps d'exécution excessif sur le référentiel fournisseurs
--
-- CHANGEMENTS PAR RAPPORT À Referentiel_Fournisseur.sql :
--   1. SOUS-REQUÊTE CORRÉLÉE supprimée : le filtre OBJECT_VERSION_NUMBER = MAX(...)
--      sur IBY_EXTERNAL_PAYEES_ALL était ré-exécuté pour chaque ligne de l'outer
--      query. Remplacé par une CTE iepa_latest pré-agrégée (1 seul parcours).
--   2. JOINTURES MORTES supprimées : HL3 (ASU.SHIP_TO_LOCATION_ID) et HL4
--      (ASU.BILL_TO_LOCATION_ID) n'étaient jamais référencées dans le SELECT.
--   3. CONDITIONS WHERE constantes simplifiées :
--      - "NULL IS NULL AND x LIKE '%'" → toujours TRUE → supprimé
--      - "'Y' = 'N' AND ..." → toujours FALSE → branche OR supprimée
--      - "'Y' = 'Y' AND (date_cond)" → réduit aux seules conditions de date
--   4. Condition IEPA dupliquée dans FFVT2.LANGUAGE supprimée (était présente
--      deux fois dans la CTE ACCORD : dans le JOIN et dans le WHERE).
-- =====================================================================

WITH
-- ─────────────────────────────────────────────────────────────────────
-- CTE 1 : Codes accord (inchangée, sauf suppression du filtre LANGUAGE en double)
-- ─────────────────────────────────────────────────────────────────────
accord AS (
    SELECT DISTINCT
        ffv2.flex_value,
        ffvt2.description
    FROM
             applsys.fnd_flex_value_sets  ffvs2
        JOIN applsys.fnd_flex_values      ffv2  ON ffv2.flex_value_set_id  = ffvs2.flex_value_set_id
        JOIN applsys.fnd_flex_values_tl   ffvt2 ON ffvt2.flex_value_id     = ffv2.flex_value_id
                                               AND ffvt2.language           = 'F'
    WHERE
        ffvs2.flex_value_set_name = 'DKA_CODE_ACCORD'
),

-- ─────────────────────────────────────────────────────────────────────
-- CTE 2 : Version maximale par payee dans IBY
-- Remplace la sous-requête corrélée :
--   IEPA.OBJECT_VERSION_NUMBER = (SELECT MAX(...) FROM IBY_EXTERNAL_PAYEES_ALL
--                                  WHERE EXT_PAYEE_ID = IEPA.EXT_PAYEE_ID ...)
-- Cette CTE est calculée une seule fois et jointe sur EXT_PAYEE_ID.
-- ─────────────────────────────────────────────────────────────────────
iepa_latest AS (
    SELECT
        ext_payee_id,
        MAX(object_version_number) AS max_ovn
    FROM
        iby.iby_external_payees_all
    WHERE
        payment_function = 'PAYABLES_DISB'
    GROUP BY
        ext_payee_id
)

SELECT
    asu.segment1
    || '.'
    || haou.name
    || '.'
    || translate(translate(translate(translate(translate(assa.vendor_site_code, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                 "Clé",
    haou.name                                                                                                                                                              "OU",
    asu.segment1                                                                                                                                                           "Num. Fourn.",
    translate(translate(translate(translate(translate(asu.vendor_name, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                           "Nom",
    hp.party_number                                                                                                                                                        "Num Partie",
    decode(hp.status, 'A', 'Actif', 'I', 'Inactif', hp.status)                                                                                                           "Statut Partie",
    asp.segment1                                                                                                                                                           "Num Parent",
    asp.vendor_name                                                                                                                                                        "Nom Parent",
    asu.num_1099                                                                                                                                                           "Siren",
    asu.attribute1                                                                                                                                                         "Fourn. Serv.",
    asu.attribute3                                                                                                                                                         "Fourn. Combus.",
    asu.attribute4                                                                                                                                                         "Code Accord",
    accord.description                                                                                                                                                     "Nom Accord",
    asu.attribute6                                                                                                                                                         "Code surtaxe",
    asu.vendor_type_lookup_code                                                                                                                                            "Type",
    asu.minority_group_lookup_code                                                                                                                                         "Sous/type",
    asu.attribute2                                                                                                                                                         "Code Part.",
    asu.standard_industry_class                                                                                                                                            "Code NACE",
    asu."VAT_REGISTRATION_NUM#1"                                                                                                                                           "TVA Intracom",
    asu.federal_reportable_flag                                                                                                                                            "Honoraires",
    asu.type_1099                                                                                                                                                          "Code DAS2",
    flv1.meaning                                                                                                                                                           "Mode paiement",
    att1.name                                                                                                                                                              "Condition paiement",
    asu.end_date_active                                                                                                                                                    "Date fin",
    hps.party_site_number                                                                                                                                                  "Num Site Partie",
    hps.party_site_name                                                                                                                                                    "Nom Site Partie",
    decode(hps.status, 'A', 'Actif', 'I', 'Inactif', hps.status)                                                                                                         "Statut Site Partie",
    substr(haou.name, 1, 3)                                                                                                                                                "Etab",
    substr(haou.name, 4, 4)                                                                                                                                                "Sté",
    assa.vendor_site_id                                                                                                                                                    "ID Site",
    translate(translate(translate(translate(translate(assa.vendor_site_code, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                     "Code Site",
    translate(translate(translate(translate(translate(assa.vendor_site_code_alt, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                 "Autre code",
    translate(translate(translate(translate(translate(assa.address_lines_alt, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                    "Autre adresse",
    assa.attribute1                                                                                                                                                        "Siret",
    translate(translate(translate(translate(translate(assa.address_line1, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                        "Ligne adresse 1",
    translate(translate(translate(translate(translate(assa.address_line2, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                        "Ligne adresse 2",
    translate(translate(translate(translate(translate(assa.address_line3, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                        "Ligne adresse 3",
    translate(translate(translate(translate(translate(assa.address_line4, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                        "Ligne adresse 4",
    translate(translate(translate(translate(translate(assa.zip, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                                  "Code Postal",
    translate(translate(translate(translate(translate(assa.city, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                                 "Ville",
    translate(translate(translate(translate(translate(assa.county, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                               "Région",
    translate(translate(translate(translate(translate(assa.province, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                             "Province",
    translate(translate(translate(translate(translate(assa.state, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                                "Etat / Département",
    assa.attribute6                                                                                                                                                        "Code INSEE",
    assa.attribute6                                                                                                                                                        "Bureau distributeur",
    assa.country                                                                                                                                                           "Pays",
    assa.pay_site_flag                                                                                                                                                     "Site Rglt",
    assa.purchasing_site_flag                                                                                                                                              "Site Achat",
    decode(assa.supplier_notif_method, 'FAX', 'Fax', 'EMAIL', 'Mail', 'PRINT', 'Papier', null)                                                                            "Notif. Cde",
    assa.fax_area_code || ' ' || assa.fax                                                                                                                                  "Fax",
    assa.area_code || ' ' || assa.phone                                                                                                                                    "Tel",
    translate(translate(translate(translate(translate(assa.email_address, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                        "Mail commande",
    translate(translate(translate(translate(translate(iepa.remit_advice_email, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ')                   "Mail avis Paiement",
    flv.meaning                                                                                                                                                            "Mode paiement site",
    att.name                                                                                                                                                               "Condition paiement site",
    assa.pay_group_lookup_code                                                                                                                                             "Classe de reglement",
    assa.offset_tax_flag                                                                                                                                                   "TVA Intra",
    decode(assa.auto_tax_calc_flag, 'L', 'Ligne', 'T', 'Code TVA', 'N', 'Aucun', 'Y', 'En-tête', 'En-tête')                                                              "Niveau calcul",
    nvl(assa.attribute5, 'N')                                                                                                                                              "Factor",
    assa.attribute9                                                                                                                                                        "Four. Stratégique",
    hl1.location_code                                                                                                                                                      "Adresse Livraison",
    hl2.location_code                                                                                                                                                      "Adresse Facturation",
    decode(assa.match_option, 'P', 'Commande', 'R', 'Réception', assa.match_option)                                                                                       "Option rappro facture",
    to_date(assa.attribute12, 'YYYY/MM/DD HH24:MI:SS')                                                                                                                    "Extraction Xerox",
    gcc1.concatenated_segments                                                                                                                                             "Compte Fournisseur",
    gcc2.concatenated_segments                                                                                                                                             "Compte Acompte",
    gcc3.concatenated_segments                                                                                                                                             "Compte LCR",
    asu.creation_date                                                                                                                                                      "Date création Fourn.",
    fu4.user_name                                                                                                                                                          "Util. création Fourn.",
    fu4.description                                                                                                                                                        "Nom création Fourn.",
    asu.last_update_date                                                                                                                                                   "Date modif Fourn.",
    fu5.user_name                                                                                                                                                          "Util. Modif Fourn.",
    fu5.description                                                                                                                                                        "Nom modif Fourn.",
    hp.creation_date                                                                                                                                                       "Date création Partie",
    fu2.user_name                                                                                                                                                          "Util. création Partie",
    fu2.description                                                                                                                                                        "Nom création Partie",
    hp.last_update_date                                                                                                                                                    "Date modif Partie",
    fu3.user_name                                                                                                                                                          "Util. Modif Partie",
    fu3.description                                                                                                                                                        "Nom modif Partie",
    assa.creation_date                                                                                                                                                     "Date création site",
    fu1.user_name                                                                                                                                                          "Util. création site",
    fu1.description                                                                                                                                                        "Nom création site",
    assa.inactive_date                                                                                                                                                     "Fin site",
    assa.last_update_date                                                                                                                                                  "Dernière modif.",
    fu.user_name                                                                                                                                                           "Util. Modif site",
    fu.description                                                                                                                                                         "Nom modif site"
FROM
         apps.ap_supplier_sites_all         assa
    JOIN ar.hz_party_sites                  hps   ON hps.party_site_id     = assa.party_site_id
    JOIN ap.ap_suppliers                    asu   ON assa.vendor_id        = asu.vendor_id
    JOIN ar.hz_parties                      hp    ON hp.party_id           = asu.party_id
    JOIN hr.hr_all_organization_units       haou  ON haou.organization_id  = assa.org_id
    JOIN apps.gl_code_combinations_kfv      gcc1  ON gcc1.code_combination_id = assa.accts_pay_code_combination_id
    JOIN apps.gl_code_combinations_kfv      gcc2  ON gcc2.code_combination_id = assa.prepay_code_combination_id
    JOIN apps.gl_code_combinations_kfv      gcc3  ON gcc3.code_combination_id = assa.future_dated_payment_ccid
    JOIN ap.ap_terms_tl                     att   ON att.term_id           = assa.terms_id
                                                 AND att.language          = 'F'
    JOIN applsys.fnd_user                   fu    ON fu.user_id            = assa.last_updated_by
    JOIN applsys.fnd_user                   fu1   ON fu1.user_id           = assa.created_by
    JOIN applsys.fnd_user                   fu2   ON fu2.user_id           = hp.created_by
    JOIN applsys.fnd_user                   fu3   ON fu3.user_id           = hp.last_updated_by
    JOIN applsys.fnd_user                   fu4   ON fu4.user_id           = asu.created_by
    JOIN applsys.fnd_user                   fu5   ON fu5.user_id           = asu.last_updated_by
    -- IEPA : LEFT JOIN car certains sites n'ont pas de paramétrage de paiement IBY
    LEFT JOIN iby.iby_external_payees_all   iepa  ON iepa.org_id           = assa.org_id
                                                 AND iepa.payee_party_id   = asu.party_id
                                                 AND iepa.party_site_id    = assa.party_site_id
                                                 AND iepa.supplier_site_id = assa.vendor_site_id
                                                 AND iepa.payment_function = 'PAYABLES_DISB'
    -- CTE remplaçant la sous-requête corrélée MAX(OBJECT_VERSION_NUMBER)
    LEFT JOIN iepa_latest                   il    ON il.ext_payee_id       = iepa.ext_payee_id
    LEFT JOIN ap.ap_suppliers               asp   ON asp.vendor_id         = asu.parent_vendor_id
    LEFT JOIN applsys.fnd_lookup_values     flv1  ON flv1.lookup_code      = asu.payment_method_lookup_code
                                                 AND flv1.lookup_type      = 'PAYMENT METHOD'
                                                 AND flv1.language         = 'F'
    LEFT JOIN ap.ap_terms_tl                att1  ON att1.term_id          = asu.terms_id
                                                 AND att1.language         = 'F'
    LEFT JOIN accord                              ON accord.flex_value      = asu.attribute4
    LEFT JOIN hr.hr_locations_all           hl1   ON hl1.location_id       = assa.ship_to_location_id
    LEFT JOIN hr.hr_locations_all           hl2   ON hl2.location_id       = assa.bill_to_location_id
    LEFT JOIN applsys.fnd_lookup_values     flv   ON flv.lookup_code       = assa.payment_method_lookup_code
                                                 AND flv.lookup_type       = 'PAYMENT METHOD'
                                                 AND flv.language          = 'F'
WHERE
    -- Filtre type fournisseur
    (asu.vendor_type_lookup_code <> 'EMPLOYEE' OR asu.vendor_type_lookup_code IS NULL)
    -- Filtre fournisseurs actifs uniquement
    AND (asu.end_date_active IS NULL OR TRUNC(asu.end_date_active) >= TRUNC(SYSDATE))
    AND (assa.inactive_date  IS NULL OR TRUNC(assa.inactive_date)  >= TRUNC(SYSDATE))
    -- Filtre version IEPA : conserve uniquement la version la plus récente
    -- (OVN IS NULL = sites sans IEPA → exclus, comme dans la version originale)
    AND iepa.object_version_number = il.max_ovn
ORDER BY
    1, 2
