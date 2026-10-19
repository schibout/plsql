----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_PO_HEADERS_PRINT_NIV1_V.vue
-- DESCRIPTION      : Création de la vue DKA_PO_HEADERS_PRINT_NIV1_V
--                    Vue de premier niveau (optimisation de la vue PO_HEADERS_PRINT_V)
--                    utlisee par la vue DKA_PO_HEADERS_PRINT_V pour edition du bon de commande
-- AUTEUR           : Bernard HANQUIER (CGEY)
-- DATE DE CREATION : 24/06/2003
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 10/12/2003 SRO Affichage des paranthèses du champ vendor_phone seulement si area_code est non null
-- ---------- --- -------------------------------------------------------------------------
-- 10/12/2003 SRO Ajout de 4 champs de la table po_vendor_sites_all pour les informations
--                de paiment et de livraison.
--------------------------------------------------------------------------------------------
-- 08/01/2004 SRO Modification d'accès des informations de paiement et de livraison au niveau
--                de la commande au lieu du niveau du site fournisseur.
--------------------------------------------------------------------------------------------
-- 10/05/2016 MEG Migration R12 : Mise en commentaire des Hints de la requete
--------------------------------------------------------------------------------------------
-- 01/03/2017 MEG Migration R12 : artf2109638: Ano dans le fichier PDF du bon de commande
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_PO_HEADERS_PRINT_NIV1_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW dka_po_headers_print_niv1_v (
    po_type,       --1
    po_num,
    revision_num,
    print_count,
    creation_date, --5
    printed_date,
    revised_date,
    effective_date,
    expiration_date,
    note_to_vendor, --10
    document_buyer_first_name,
    document_buyer_last_name,
    document_buyer_agent_id,
    document_buyer_attribute1,
    document_buyer_attribute4,
    document_buyer_attribute5,
    document_buyer_title,
    document_buyer_email_address,
    document_buyer_phone_number,
    amount_agreed,
    cancel_flag, --15
    confirming_order_flag,
    acceptance_required_flag, 
    acceptance_due_date,
    currency_code,
    currency_name, --20
    currency_conversion_rate,
    customer_num,
    vendor_num, 
    vendor_name, 
    vendor_address_line1,--25
    vendor_address_line2,
    vendor_address_line3,
    vendor_city, 
    vendor_state,
    vendor_postal_code,--30
    vendor_country,
    vendor_phone,
    vendor_fax_area_code,
    vendor_fax,
    vendor_contact_first_name, 
    vendor_contact_last_name,
    vendor_contact_phone,--35
    vendor_contact_prefix,
    bill_address_line1, 
    bill_address_line2,
    bill_address_line3,
    bill_city,--40
    bill_postal_code, 
    bill_country,
    bill_description,
    bill_telephone_number_1,
    bill_telephone_number_2, --45
    bill_location_code,
    attribute1,
    vendor_siTe_id,
    bill_to_location_id,
    ship_to_location_id, --50
    po_header_id,
    po_release_id,
    approved_flag,
    vendor_id,
    org_id,--55
    vendor_contact_id,
    last_update_date,
    last_updated_by,
    terms_id,
    payment_method_lookup_code, --60
    ship_via_lookup_code,
    freight_terms_lookup_code  
)
AS
    -- /*+ ordered use_nl(vn,pvs,pvc,lc2,lct2,fte2,fte3,pap,pp_fixe,fcc,fcct) */
    SELECT ph.type_lookup_code, --1
           ph.segment1,
           ph.revision_num,
           ph.print_count,
           ph.creation_date, --5
           ph.printed_date,
           ph.revised_date,
           ph.start_date,
           ph.end_date,
           ph.note_to_vendor,--10
           pap.first_name,
           pap.last_name,
           ph.agent_id,
           pap.attribute1,
           pap.attribute4,
           pap.attribute5,
           pap.title,
           pap.email_address,
           pp_fixe.phone_number,
           NVL (ph.blanket_total_amount, ''),
           ph.cancel_flag, --15
           ph.confirming_order_flag,
           ph.acceptance_required_flag, 
           ph.acceptance_due_date,
           fcc.currency_code,
           fcct.NAME,--20
           ph.rate,
           NVL (pvs.customer_num, vn.customer_num),
           vn.segment1,
           vn.vendor_name, 
           pvs.address_line1,--25
           pvs.address_line2,
           pvs.address_line3,
           pvs.city, 
           DECODE (pvs.state, NULL, DECODE (pvs.province, NULL, pvs.county, pvs.province), pvs.state), 
           pvs.zip,--30
           fte3.territory_short_name,
           DECODE (pvs.area_code, NULL, pvs.phone, '(' || pvs.area_code || ') ' || pvs.phone),
           pvs.fax_area_code,
           pvs.fax,
           pvc.first_name, 
           pvc.last_name, 
           '(' || pvc.area_code || ') ' || pvc.phone,--35
           pvc.prefix,
           lc2.address_line_1, 
           lc2.address_line_2, 
           lc2.address_line_3,
           lc2.town_or_city,--40
           lc2.postal_code, 
           fte2.territory_short_name,
           lct2.description,
           lc2.telephone_number_1,
           lc2.telephone_number_2,--45
           lct2.location_code,
           ph.attribute1,
           ph.vendor_site_id,
           ph.bill_to_location_id,
           ph.ship_to_location_id, --50
           ph.po_header_id, 
           TO_NUMBER (NULL),
           DECODE (ph.approved_flag, 'Y', 'Y', 'N'),
           ph.vendor_id, 
           ph.org_id,--55
           ph.vendor_contact_id,
           ph.last_update_date,
           ph.last_updated_by,
           ph.terms_id,
           pvs.payment_method_lookup_code, --60
           ph.ship_via_lookup_code,
           ph.freight_terms_lookup_code  
    FROM   
           po_headers ph,
           po_vendors vn,
           po_vendor_sites pvs,
           po_vendor_contacts pvc,
           hr_locations_all lc2,
           hr_locations_all_tl lct2,
           fnd_territories_tl fte2,
           fnd_territories_tl fte3,
           per_all_people_f pap,
           per_phones pp_fixe,
           fnd_currencies fcc,
           fnd_currencies_tl fcct
    WHERE  NVL (ph.user_hold_flag, 'N') = 'N'
           AND pvc.vendor_site_id(+) = pvs.vendor_site_id
           AND vn.vendor_id = ph.vendor_id
           AND pvs.vendor_site_id = ph.vendor_site_id
           AND ph.vendor_contact_id = pvc.vendor_contact_id(+)
           AND pap.person_id = ph.agent_id
           AND ph.agent_id = pp_fixe.parent_id(+)
           AND pp_fixe.phone_type(+) = 'W1'
           AND pp_fixe.parent_table(+)='PER_ALL_PEOPLE_F'
           AND trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
           AND lc2.location_id = ph.bill_to_location_id
           AND lc2.location_id = lct2.location_id
           AND lct2.language= USERENV ('LANG')
           AND ph.type_lookup_code IN ('STANDARD', 'BLANKET', 'CONTRACT', 'PLANNED')
           AND fcc.currency_code = ph.currency_code
           AND fcc.currency_code = fcct.currency_code
           AND fcct.LANGUAGE = USERENV ('LANG')
           AND lc2.country = fte2.territory_code(+)
           AND  fte2.LANGUAGE(+) = USERENV ('LANG')
           AND pvs.country = fte3.territory_code(+)
           AND  fte3.LANGUAGE(+) = USERENV ('LANG')
    UNION ALL
    -- /*+ ordered use_nl(pr, vn,pvs,pvc,pap,pp_fixe,lc2,lct2,fte2,fte3,fcc,fcct) */
    SELECT 'RELEASE',  --1
           ph.segment1,
           pr.revision_num,
           pr.print_count,
           pr.creation_date, --5
           pr.printed_date,
           pr.revised_date,
           TO_DATE (NULL),
           TO_DATE (NULL),
           ph.note_to_vendor,--10
           pap.first_name,
           pap.last_name,
           pr.agent_id,
           pap.attribute1,
           pap.attribute4,
           pap.attribute5,
           pap.title,
           pap.email_address,
           pp_fixe.phone_number,
           TO_NUMBER (NULL),
           pr.cancel_flag, --15
           '',
           pr.acceptance_required_flag, 
           pr.acceptance_due_date,
           fcc.currency_code,
           fcct.NAME,--20
           ph.rate,
           NVL (pvs.customer_num, vn.customer_num),
           vn.segment1, 
           vn.vendor_name,
           pvs.address_line1,--25
           pvs.address_line2,
           pvs.address_line3,
           pvs.city, 
           DECODE (pvs.state, NULL, DECODE (pvs.province, NULL, pvs.county, pvs.province), pvs.state),
           pvs.zip,--30
           fte3.territory_short_name,
           DECODE (pvs.area_code, NULL, pvs.phone, '(' || pvs.area_code || ') ' || pvs.phone),
           pvs.fax_area_code,
           pvs.fax,
           pvc.first_name, 
           pvc.last_name,
           '(' || pvc.area_code || ') ' || pvc.phone,--35
            pvc.prefix,
           lc2.address_line_1, 
           lc2.address_line_2,
           lc2.address_line_3,
           lc2.town_or_city,--40
           lc2.postal_code, 
           fte2.territory_short_name,
           lct2.description,
           lc2.telephone_number_1,
           lc2.telephone_number_2,--45
           lct2.location_code, 
           pr.attribute1,
           ph.vendor_site_id,
           ph.bill_to_location_id,
           ph.ship_to_location_id,--50
           ph.po_header_id,
           pr.po_release_id,
           DECODE (pr.approved_flag, 'Y', 'Y', 'N'), 
           ph.vendor_id,  
           ph.org_id,--55
           ph.vendor_contact_id,
           ph.last_update_date,
           ph.last_updated_by,
           pvs.terms_id,
           pvs.payment_method_lookup_code, --60
           pvs.ship_via_lookup_code,
           pvs.freight_terms_lookup_code  
    FROM   
           po_headers ph,
           po_releases pr,
           po_vendors vn,
           po_vendor_sites pvs,
           po_vendor_contacts pvc,
           per_all_people_f pap,
           per_phones pp_fixe,
           hr_locations_all lc2,
           hr_locations_all_tl lct2,
           fnd_territories_tl fte2,
           fnd_territories_tl fte3,
           fnd_currencies fcc,
           fnd_currencies_tl fcct
    WHERE  ph.type_lookup_code IN ('BLANKET', 'PLANNED')
           AND pvc.vendor_site_id(+) = pvs.vendor_site_id
           AND ph.po_header_id = pr.po_header_id
           AND vn.vendor_id = ph.vendor_id
           AND pvs.vendor_site_id = ph.vendor_site_id
           AND ph.vendor_contact_id = pvc.vendor_contact_id(+)
           AND pap.person_id = pr.agent_id
           AND ph.agent_id = pp_fixe.parent_id(+)
           AND pp_fixe.phone_type(+) = 'W1'
           AND pp_fixe.parent_table(+)='PER_ALL_PEOPLE_F'
           AND trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
           AND lc2.location_id = ph.bill_to_location_id
           AND lc2.location_id = lct2.location_id
           AND lct2.LANGUAGE(+) = USERENV ('LANG')
           AND fcc.currency_code = ph.currency_code
           AND fcc.currency_code = fcct.currency_code
           AND fcct.LANGUAGE = USERENV ('LANG')
           AND lc2.country = fte2.territory_code(+)
           AND fte2.LANGUAGE(+) = USERENV ('LANG')
           AND pvs.country = fte3.territory_code(+)
           AND fte3.LANGUAGE(+) = USERENV ('LANG');

EXIT;
