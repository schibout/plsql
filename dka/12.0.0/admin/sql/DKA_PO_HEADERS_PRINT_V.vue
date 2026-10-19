----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_PO_HEADERS_PRINT_V.vue
-- DESCRIPTION      : Création de la vue DKA_PO_HEADERS_PRINT_V
--
-- AUTEUR           : Bernard HANQUIER (CGEY)
-- DATE DE CREATION : 28/02/2002
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 25/03/2002 BHA Ajout des numeros de telephone, fax et mobile
-- 09/04/2002 BHA Ajout mail acheteur
-- 23/04/2002 BHA Ajour du fax fournisseur
-- 12/06/2002 BHA Optimisation par ajout des clauses HINT
-- 24/06/2003 BHA Refonte totale pour optimisation du bon de commande et utilisation
--                du package DKA_SPOBON_PKG et de la vue dka_po_headers_print_niv1_v
-- 10/12/2003 SRO Ajout de 4 champs de la vue dka_po_headers_print_niv1_v pour les informations
--                de paiment et de livraison du site fournisseur
-- 07/05/2010 EMA Modification de la recherche des téléphone, fax et mobile
-- 10/05/2016 MEG Migration R12 : Mise en commentaire des Hints de la requete
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_PO_HEADERS_PRINT_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW dka_po_headers_print_v (
    po_type, --1
    po_num,
    po_num_print,
    revision_num,
    print_count, --5
    creation_date,
    printed_date,
    revised_date,
    effective_date,
    expiration_date,--10
    note_to_vendor,
    document_buyer_first_name,
    document_buyer_last_name,
    document_buyer_agent_id,
    document_buyer_attribute1, --15
    document_buyer_attribute4,
    document_buyer_attribute5,
    document_buyer_phone_number,
    amount_agreed,
    cancel_flag, --20
    confirming_order_flag,
    acceptance_required_flag,
    acceptance_due_date,
    currency_code,
    currency_name, --25
    currency_conversion_rate,
    customer_num,
    vendor_num,
    vendor_name,
    vendor_address_line1, --30
    vendor_address_line2,
    vendor_address_line3,
    vendor_city,
    vendor_state,
    vendor_postal_code, --35
    vendor_country,
    vendor_phone,
    vendor_contact_first_name,
    vendor_contact_last_name,
    vendor_contact_phone, --40
    vendor_contact_prefix,
    ship_description,
    ship_address_line1,
    ship_address_line2,
    ship_address_line3, --45
    ship_city,
    ship_country,
    bill_address_line1,
    bill_address_line2,
    bill_address_line3, --50
    bill_city,
    bill_postal_code,
    bill_country,
    bill_description,
    bill_telephone_number_1, --55
    bill_telephone_number_2,
    bill_location_code,
    attribute1,
    vendor_site_id,
    bill_to_location_id, --60
    ship_to_location_id,
    po_header_id,
    po_release_id,
    approved_flag,
    vendor_id, --65
    nb_site,
    horaires,
    comments,
    nb_date,
    date_liv,--70
    tel_fax,    
    mobile,
    annule,
    acheteur,
    email_acheteur,--75
    fax_fourn,
    nom_acheteur,
    prenom_acheteur,
    org_id,
    vendor_contact_id,--80
    last_update_date,
    last_updated_by,
    terms_id,
    payment_method_lookup_code, 
    ship_via_lookup_code,--85
    freight_terms_lookup_code
)
AS
    -- /*+ ordered use_nl(polla,hrla,hrlat,fl) */
    SELECT 
           php.po_type,--1
           php.po_num,
/*           document_buyer_attribute1 || php.po_num || DECODE (php.revision_num, '0', NULL,    '-V'
                                     || TO_CHAR (php.revision_num)) po_num_print,*/
           php.po_num || DECODE (php.revision_num, '0', NULL,    '-V'
                      || TO_CHAR (php.revision_num)) po_num_print,
           php.revision_num,
           php.print_count,--5
           php.creation_date,
           php.printed_date,
           php.revised_date,
           php.effective_date,
           php.expiration_date,--10
           php.note_to_vendor,
           php.document_buyer_first_name,
           php.document_buyer_last_name,
           php.document_buyer_agent_id,
           php.document_buyer_attribute1,--15
           php.document_buyer_attribute4,
           php.document_buyer_attribute5,
           php.document_buyer_phone_number,
           php.amount_agreed,
           php.cancel_flag, --20
           php.confirming_order_flag,
           php.acceptance_required_flag,
           php.acceptance_due_date,
           php.currency_code,
           php.currency_name, --25
           php.currency_conversion_rate,
           php.customer_num,
           php.vendor_num,
           php.vendor_name,
           php.vendor_address_line1, --30
           php.vendor_address_line2,
           php.vendor_address_line3,
           php.vendor_city,
           php.vendor_state,
           php.vendor_postal_code, --35
           php.vendor_country,
           'Tél: ' || php.vendor_phone vendor_phone,
           php.vendor_contact_first_name,
           php.vendor_contact_last_name,
           php.vendor_contact_phone, --40
           php.vendor_contact_prefix,
           DECODE (DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, hrlat.description, NULL) hrla_description,
           DECODE (DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, hrla.address_line_1, NULL) hrla_address_line1,
           DECODE (DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, hrla.address_line_2, 'Voir ci-dessous le détail des lignes de commande.') hrla_address_line2,
           DECODE (DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id), 1, hrla.address_line_3, NULL) hrla_address_line3, --45
           DECODE (
               DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id),
               1, hrla.postal_code || ' ' || hrla.town_or_city,
               NULL
           ) hrla_address_city,
           DECODE (
               DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id),
               1, DECODE (hrla.country, 'FR', NULL, fl.meaning),
               NULL
           ) hrla_address_country,
           php.bill_address_line1,
           php.bill_address_line2,
           php.bill_address_line3, --50
           php.bill_city,
           php.bill_postal_code,
           php.bill_country,
                       php.bill_description,
           php.bill_telephone_number_1, --55
           php.bill_telephone_number_2,
           php.bill_location_code,
           php.attribute1,
           php.vendor_site_id,
           php.bill_to_location_id, --60
           php.ship_to_location_id,
           php.po_header_id,
           php.po_release_id,
           php.approved_flag,
           php.vendor_id,--65
           DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id) nb_site,
           DECODE (
               DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id),
               1, DECODE (hrla.attribute2, NULL, NULL, 'Horaires : ' || hrla.attribute2),
               NULL
           ) hrla_address_horaires,
           DECODE (
               DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id),
               1, DECODE (hrla.attribute3, NULL, NULL, 'Divers: ' || hrla.attribute3),
               NULL
           ) hrla_address_comments,
           DKA_SPOBON_PKG.nb_promised_date (php.po_header_id) nb_date,
           DECODE (
               DKA_SPOBON_PKG.nb_promised_date (php.po_header_id),
               1, NVL (polla.promised_date, polla.need_by_date),
               NULL
           ) date_liv, --70
           DECODE (
               DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id),
               1,    DECODE (hrla.telephone_number_1, NULL, NULL, 'Tél: ' || hrla.telephone_number_1)
                  || DECODE (telephone_number_1, NULL, NULL, DECODE (telephone_number_2, NULL, NULL, ' - '))
                  || DECODE (hrla.telephone_number_2, NULL, NULL, 'Fax: ' || hrla.telephone_number_2),
               NULL
           ) hrla_tel_fax,
           DECODE (
               DKA_SPOBON_PKG.nb_ship_to_location_id (php.po_header_id),
               1,    DECODE (hrla.telephone_number_3, NULL, NULL, 'Mobile: ' || hrla.telephone_number_3),
               NULL
           ) hrla_mobile,
/*           DECODE (
               TO_CHAR (NVL (php.revision_num, 0)),
               '0', NULL,
               '1', 'CETTE COMMANDE ANNULE ET REMPLACE LA COMMANDE REFERENCE ' || document_buyer_attribute1 || php.po_num,
                  'CETTE COMMANDE ANNULE ET REMPLACE LA COMMANDE REFERENCE '
               || document_buyer_attribute1
               || php.po_num
               || '-V'
               || TO_CHAR (php.revision_num - 1)
           ) poh_annule,*/
           DECODE (
               TO_CHAR (NVL (php.revision_num, 0)),
               '0', NULL,
               '1', 'CETTE COMMANDE ANNULE ET REMPLACE LA COMMANDE REFERENCE ' || php.po_num,
                  'CETTE COMMANDE ANNULE ET REMPLACE LA COMMANDE REFERENCE '
               || php.po_num
               || '-V'
               || TO_CHAR (php.revision_num - 1)
           ) poh_annule,
           INITCAP (document_buyer_title) || ' ' || document_buyer_first_name || ' ' || document_buyer_last_name poh_acheteur,
           document_buyer_email_address, --75
              DECODE (
                  vendor_fax_area_code || vendor_fax,
                  NULL, NULL,
                  'Fax: ' || DECODE (vendor_fax_area_code, NULL, NULL, vendor_fax_area_code || ' ')
              )
           || vendor_fax, 
           document_buyer_last_name,
           document_buyer_first_name,
           php.org_id,
           php.vendor_contact_id,--80
           php.last_update_date,
           php.last_updated_by,
           php.terms_id,
           php.payment_method_lookup_code, 
           php.ship_via_lookup_code,--85
           php.freight_terms_lookup_code
    FROM   dka_po_headers_print_niv1_v php,
           po_line_locations_all polla,
           hr_locations_all hrla,
           hr_locations_all_tl hrlat,
           fnd_lookups fl
    WHERE      hrla.location_id = polla.ship_to_location_id
           AND fl.lookup_type = 'JEES_EURO_COUNTRY_CODES'
           AND fl.lookup_code = hrla.country
                      AND hrla.location_id = hrlat.location_id
           AND hrlat.LANGUAGE(+) = USERENV ('LANG')
           AND polla.line_location_id = (SELECT MIN (pll2.line_location_id)
                                         FROM   po_line_locations_all pll2
                                         WHERE  pll2.po_header_id = php.po_header_id);
                                         
EXIT;
