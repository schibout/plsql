CREATE OR REPLACE PACKAGE BODY dka_spomajcatkpi_pkg AS

  --------------------------------------------------------------------------------------------
  -- $Id:  $
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications (Helios R12)
  -- NOM               : DKA_SPOMAJCATKPI_PKG.pkb
  -- DESCRIPTION       : DKA_SPOMAJCATKPI_PKG package body :
  ---
  --- AUTEUR           : R. BELAYACHI (CAPGEMINI)
  --- DATE DE CREATION : 01/03/2019
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  --------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 22/03/19   CD  Ajout MAJ statut pour lignes dans article interne
  --------------------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  gv_conc_program_id NUMBER := fnd_global.conc_program_id;
  gv_conc_request_id NUMBER := fnd_global.conc_request_id;
  gv_prog_appl_id    NUMBER := fnd_global.prog_appl_id;
  gv_resp_name       VARCHAR2(100) := fnd_global.resp_name;
  gv_user_id         NUMBER := fnd_global.user_id;

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PUBLIQUES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure pour le traitement de mise des KPI catalogues
  --
  --  PARAMETRES    :
  --  pv_errbuf                       Entrée/Sortie           retour de message eventuel
  --  pn_retcode                      Sortie                  status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  -------------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    CURSOR cur_kpi IS
      SELECT dsh.*, dsh.ROWID rid
        FROM dka_sicxrechcat_hist dsh
       WHERE dsh.statut = 'NEW'
         AND result_code_article_interne IS NOT NULL;
  
    CURSOR cur_catalog(p_org_id NUMBER, p_code_article_interne VARCHAR2, p_fournisseur VARCHAR2, p_marche VARCHAR2, p_ref_fourn_fab VARCHAR2, p_mots_cles VARCHAR2, p_fabricant VARCHAR2, p_rech_domaine VARCHAR2) IS
      SELECT v2.NAME magasin,
             v.organization_id,
             decode(p_code_article_interne, NULL, NULL, v.internal_item_num) code_article_interne,
             decode(p_fournisseur, NULL, NULL, v.supplier) fournisseur,
             --decode(p_ref_fourn_fab, NULL, NULL, v.supplier_part_num),
             --v.shopping_category marche,
             v.purchasing_category marche,
             --decode(p_ref_fourn_fab, NULL, NULL, v.manufacturer_part_num) ref_fourn_fab,
             v.manufacturer fabricant,
             uom.unit_of_measure,
             AVG(v.price) prix_moyen
    --         MIN(v.price) prix_minimum
        FROM (SELECT bq.inventory_item_id inventory_item_id,
                     msikfv.organization_id organization_id,
                     bq.source_type sourcetype,
                     bq.inventory_item_id itemid,
                     nvl(avtlp.description, bq.description) description,
                     decode(least(length(decode(1,
                                                1,
                                                nvl(avtlp.description,
                                                    bq.description))),
                                  25),
                            25,
                            substr(decode(1,
                                          1,
                                          nvl(avtlp.description,
                                              bq.description)),
                                   1,
                                   22) || '...',
                            decode(1,
                                   1,
                                   nvl(avtlp.description, bq.description))) truncateddescription,
                     avtlp.long_description long_description,
                     decode(least(length(avtlp.long_description), 180),
                            180,
                            substr(avtlp.long_description, 1, 177) || '...',
                            avtlp.long_description) truncatedlongdescription,
                     msikfv.concatenated_segments internal_item_num,
                     decode(bq.item_revision,
                            '-2',
                            to_char(NULL),
                            bq.item_revision) item_revision,
                     bq.po_header_id poheaderid,
                     decode(bq.merged_source_type,
                            'REQ_TEMPLATE',
                            nvl(bq.req_template_po_line_id, -2),
                            bq.po_line_id) polineid,
                     bq.document_number documentnumber,
                     bq.line_num documentlinenumber,
                     bq.req_template_name reqtemplatename,
                     bq.req_template_line_num reqtemplatelinenum,
                     decode(bq.order_type_lookup_code,
                            'AMOUNT',
                            1,
                            decode(bq.allow_price_override_flag, 'Y', 1, 0)) allowpriceoverrideflag,
                     bq.not_to_exceed_price amountlimit,
                     decode(bq.order_type_lookup_code, 'FIXED PRICE', 1, 0) isfixedprice,
                     decode(bq.order_type_lookup_code, 'QUANTITY', 0, 1) isfixedpriceoramountbased,
                     decode(bq.order_type_lookup_code,
                            'AMOUNT',
                            0,
                            decode(bq.allow_price_override_flag, 'Y', 0, 1)) isamountreadonly,
                     decode(bq.order_type_lookup_code, 'QUANTITY', 1, 0) isquantitybased,
                     bq.line_type_id linetypeid,
                     bq.po_category_id purchasingcategoryid,
                     bq.ip_category_id shoppingcategoryid,
                     mck.concatenated_segments purchasing_category,
                     bq.ip_category_name shopping_category,
                     muomtl.uom_code uomcode,
                     muomtl.unit_of_measure uomforcart,
                     muomtl.unit_of_measure_tl uom,
                     nvl(bq.suggested_quantity, 1) quantity,
                     bq.unit_price price,
                     decode(bq.order_type_lookup_code,
                            'AMOUNT',
                            nvl(bq.suggested_quantity * bq.unit_price, 1),
                            bq.amount) amount,
                     bq.currency_code currency,
                     decode(bq.supplier_id,
                            -2,
                            to_number(NULL),
                            bq.supplier_id) supplierid,
                     bq.supplier_site_id suppliersiteid,
                     bq.supplier_contact_id suppliercontactid,
                     'N' newsupplierflag,
                     bq.supplier supplier,
                     pvs.vendor_site_code supplier_site,
                     to_char(NULL) suppliercontactname,
                     to_char(NULL) suppliercontactphone,
                     to_char(NULL) suppliercontactfax,
                     to_char(NULL) suppliercontactemail,
                     decode(bq.supplier_part_num,
                            '##NULL##',
                            to_char(NULL),
                            bq.supplier_part_num) supplier_part_num,
                     decode(bq.supplier_part_auxid,
                            '##NULL##',
                            to_char(NULL),
                            bq.supplier_part_auxid) supplier_part_auxid,
                     avtlp.manufacturer manufacturer,
                     av.manufacturer_part_num manufacturer_part_num,
                     bq.buyer_id buyerid,
                     bq.rfq_required_flag rfqrequiredflag,
                     bq.negotiated_by_preparer_flag negotiatedbypreparerflag,
                     to_number(NULL) noncattemplateid,
                     to_char(NULL) attribute1,
                     to_char(NULL) attribute2,
                     to_char(NULL) attribute3,
                     to_char(NULL) attribute4,
                     to_char(NULL) attribute5,
                     to_char(NULL) attribute6,
                     to_char(NULL) attribute7,
                     to_char(NULL) attribute8,
                     to_char(NULL) attribute9,
                     to_char(NULL) attribute10,
                     to_char(NULL) attribute11,
                     to_char(NULL) attribute12,
                     to_char(NULL) attribute13,
                     to_char(NULL) attribute14,
                     to_char(NULL) attribute15,
                     av.thumbnail_image thumbnail_image,
                     av.picture picture,
                     avtlp.alias alias,
                     avtlp.comments comments,
                     av.availability availability,
                     av.lead_time lead_time,
                     av.supplier_url supplier_url,
                     av.manufacturer_url manufacturer_url,
                     av.attachment_url attachment_url,
                     bq.is_item_available isitemavailable,
                     decode(bq.is_item_available, 1, 0, 1) isitemnotavailable,
                     decode(nvl(bq.req_template_name, '-2'), '-2', 0, 1) isreqtemplate,
                     decode(bq.source_type,
                            'MASTER_ITEM',
                            decode(bq.item_type, 'PURCHASE', 0, 1),
                            'INTERNAL_TEMPLATE',
                            1,
                            decode(msikfv.internal_order_enabled_flag,
                                   'Y',
                                   1,
                                   0)) isinternallyorderable,
                     decode(bq.source_type,
                            'MASTER_ITEM',
                            decode(bq.item_type, 'INTERNAL', 0, 1),
                            'INTERNAL_TEMPLATE',
                            0,
                            1) ispurchasable,
                     decode(bq.source_type,
                            'MASTER_ITEM',
                            bq.item_type,
                            'INTERNAL_TEMPLATE',
                            'INTERNAL',
                            decode(msikfv.internal_order_enabled_flag,
                                   'Y',
                                   'BOTH',
                                   'PURCHASE')) itemtype,
                     bq.favorite_list_id favoritelistid,
                     bq.favorite_list_line_id favoritelistlineid,
                     to_number(NULL) contentzoneid,
                     av.unspsc unspsc,
                     to_number(NULL) hazardclassid,
                     'CATALOG' catalogtype,
                     'INTERNAL' catalogsource,
                     decode(substr(lower(thumbnail_image), 1, 7),
                            'http://',
                            0,
                            decode(substr(lower(thumbnail_image), 1, 8),
                                   'https://',
                                   0,
                                   1)) AS isthumbnailfile
                FROM (SELECT ctxh.inventory_item_id,
                             ctxh.po_line_id,
                             ctxh.req_template_name,
                             ctxh.req_template_line_num,
                             ctxh.org_id,
                             ctxh.LANGUAGE,
                             ctxh.source_type,
                             ctxh.purchasing_org_id,
                             ctxh.ip_category_id,
                             ctxh.ip_category_name,
                             ctxh.po_category_id,
                             ctxh.owning_org_id,
                             ctxh.supplier_id,
                             ctxh.supplier_part_num,
                             ctxh.supplier_part_auxid,
                             ctxh.supplier_site_id,
                             ctxh.item_type,
                             ctxh.item_revision,
                             ctxh.po_header_id,
                             ctxh.document_number,
                             ctxh.line_num,
                             ctxh.allow_price_override_flag,
                             ctxh.not_to_exceed_price,
                             ctxh.line_type_id,
                             ctxh.unit_meas_lookup_code,
                             ctxh.unit_price,
                             ctxh.amount,
                             ctxh.currency_code currency_code,
                             ctxh.rate_type,
                             ctxh.rate_date,
                             ctxh.rate,
                             ctxh.buyer_id,
                             ctxh.supplier_contact_id,
                             ctxh.rfq_required_flag,
                             ctxh.negotiated_by_preparer_flag,
                             ctxh.description,
                             ctxh.supplier,
                             ctxh.req_template_po_line_id,
                             ctxh.order_type_lookup_code,
                             ctxh.merged_source_type,
                             ctxh.global_agreement_flag,
                             ctxh.suggested_quantity,
                             1 AS is_item_available,
                             to_number(NULL) favorite_list_id,
                             to_number(NULL) favorite_list_line_id
                        FROM icx_cat_items_ctx_hdrs_tlp ctxh
                       WHERE icx_cat_util_pvt.is_item_valid_for_search(ctxh.source_type,
                                                                       ctxh.po_line_id,
                                                                       ctxh.req_template_name,
                                                                       ctxh.req_template_line_num,
                                                                       ctxh.po_category_id,
                                                                       ctxh.org_id) = 1
                        AND ctxh.org_id = p_org_id) bq,
                     po_system_parameters_all psp,
                     mtl_units_of_measure_tl muomtl,
                     icx_cat_attribute_values av,
                     icx_cat_attribute_values_tlp avtlp,
                     po_vendor_sites_all pvs,
                     mtl_categories_kfv mck,
                     mtl_system_items_kfv msikfv
               WHERE psp.org_id = msikfv.organization_id
                 AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(+)
                 AND bq.LANGUAGE = muomtl.LANGUAGE(+)
                 AND bq.inventory_item_id = av.inventory_item_id(+)
                 AND bq.owning_org_id = av.org_id(+)
                 AND bq.po_line_id = av.po_line_id(+)
                 AND bq.req_template_name = av.req_template_name(+)
                 AND bq.req_template_line_num = av.req_template_line_num(+)
                 AND bq.inventory_item_id = avtlp.inventory_item_id(+)
                 AND bq.owning_org_id = avtlp.org_id(+)
                 AND bq.po_line_id = avtlp.po_line_id(+)
                 AND bq.req_template_name = avtlp.req_template_name(+)
                 AND bq.req_template_line_num =
                     avtlp.req_template_line_num(+)
                 AND bq.LANGUAGE = avtlp.LANGUAGE(+)
                 AND bq.supplier_site_id = pvs.vendor_site_id(+)
                 AND bq.po_category_id = mck.category_id(+)
                 AND bq.inventory_item_id = msikfv.inventory_item_id(+)) v,
                            (SELECT ipc.external_source_key, icss.name, icss.store_id
                  FROM icx_por_category_order_map     ipc,
                       icx_cat_zone_secure_attributes icz,
                       icx_cat_store_contents         icsc,
                       icx_cat_content_zones_vl       iccz,
                       icx_cat_shop_stores_vl         icss
                 WHERE icz.ip_category_id = ipc.rt_category_id
                   AND icz.zone_id = icsc.content_id
                   AND iccz.zone_id = icsc.content_id
                   AND icz.securing_attribute = 'CATEGORY'
                   AND iccz.category_attribute_action_flag = 'INCLUDE'
                   AND icss.store_id = icsc.store_id
                   AND icss.name = p_rech_domaine
                UNION ALL
                SELECT ipc.external_source_key, icss.name, icss.store_id
                  FROM icx_por_category_order_map ipc,
                       icx_cat_store_contents     icsc,
                       icx_cat_content_zones_vl   iccz,
                       icx_cat_shop_stores_vl     icss
                 WHERE iccz.zone_id = icsc.content_id
                   AND iccz.category_attribute_action_flag = 'INCLUDE_ALL'
                   AND icss.store_id = icsc.store_id
                   AND icss.name = p_rech_domaine) v2,
             mtl_units_of_measure_tl uom
       WHERE v2.external_source_key = v.purchasingcategoryid
         AND v.organization_id = p_org_id
         AND v.internal_item_num =
             nvl(p_code_article_interne, v.internal_item_num)
         AND v.supplier = nvl(p_fournisseur, v.supplier)
         --AND v.shopping_category = nvl(p_marche, v.shopping_category)
         AND v.purchasing_category = nvl(p_marche, v.purchasing_category)
         AND (nvl(v.manufacturer_part_num, 'NULL') LIKE
             nvl(p_ref_fourn_fab, v.manufacturer_part_num) OR
             nvl(v.supplier_part_num, 'NULL') LIKE
             nvl(p_ref_fourn_fab, v.supplier_part_num) OR
             nvl(v.alias, 'NULL') LIKE nvl(p_ref_fourn_fab, v.alias))
         AND nvl(v.description, 'NULL') LIKE
             nvl(p_mots_cles, v.description)
         AND nvl(v.manufacturer, 'NULL') LIKE
             nvl(p_fabricant, nvl(v.manufacturer, 'NULL'))
         AND uom.uom_code = v.uomcode
         AND uom.LANGUAGE = 'F'
       GROUP BY v2.NAME,
                v.organization_id,
                decode(p_code_article_interne,
                       NULL,
                       NULL,
                       v.internal_item_num),
                decode(p_fournisseur, NULL, NULL, v.supplier),
                --decode(p_ref_fourn_fab, NULL, NULL, v.supplier_part_num),
                --v.shopping_category,
                v.purchasing_category,
                --decode(p_ref_fourn_fab, NULL, NULL, v.manufacturer_part_num),
                v.manufacturer,
                uom.unit_of_measure;
  
    vv_mesg            VARCHAR2(2000);
    l_rech_ref_frs_fab VARCHAR2(2000);
    l_rech_fabricant   VARCHAR2(2000);
    l_mots_cles        VARCHAR2(2000);
    l_prix_minimum     NUMBER;
  
  BEGIN
    vv_mesg := 'DEBUT';
  
    dka_tools_pkg.put_log_message('Lancement du calcul des KPIs');
  
    FOR rec_kpi IN cur_kpi LOOP
      vv_mesg := 'KPI';
    
      l_rech_ref_frs_fab := NULL;
      l_rech_fabricant   := NULL;
      l_mots_cles        := NULL;
    
      IF (rec_kpi.rech_ref_frs_fab IS NOT NULL) THEN
        l_rech_ref_frs_fab := '%' ||
                              REPLACE(rec_kpi.rech_ref_frs_fab, ' ', '%') || '%';
      
      END IF;
    
      IF (rec_kpi.rech_fabricant IS NOT NULL) THEN
        l_rech_fabricant := '%' ||
                            REPLACE(rec_kpi.rech_fabricant, ' ', '%') || '%';
      END IF;
    
      IF (rec_kpi.rech_mots_cles IS NOT NULL) THEN
        l_mots_cles := '%' || REPLACE(rec_kpi.rech_mots_cles, ' ', '%') || '%';
      END IF;
    
      dka_tools_pkg.put_log_message(rec_kpi.uo || '/' ||
                                    rec_kpi.rech_code_article_interne || '/' ||
                                    rec_kpi.rech_fournisseur || '/' ||
                                    rec_kpi.rech_marche || '/' ||
                                    l_rech_ref_frs_fab || '/' ||
                                    l_mots_cles || '/' || l_rech_fabricant);
    
      FOR rec_catalog IN cur_catalog(rec_kpi.uo,
                                     rec_kpi.result_code_article_interne,
                                     rec_kpi.rech_fournisseur,
                                     rec_kpi.rech_marche,
                                     l_rech_ref_frs_fab,
                                     l_mots_cles,
                                     l_rech_fabricant,
                                     rec_kpi.rech_domaine) LOOP
        vv_mesg := 'CATALOG';
        dka_tools_pkg.put_log_message('maj');
      
        SELECT MIN(v.price)
          INTO l_prix_minimum
          FROM (SELECT bq.inventory_item_id inventory_item_id,
                       msikfv.organization_id organization_id,
                       bq.source_type sourcetype,
                       bq.inventory_item_id itemid,
                       nvl(avtlp.description, bq.description) description,
                       decode(least(length(decode(1,
                                                  1,
                                                  nvl(avtlp.description,
                                                      bq.description))),
                                    25),
                              25,
                              substr(decode(1,
                                            1,
                                            nvl(avtlp.description,
                                                bq.description)),
                                     1,
                                     22) || '...',
                              decode(1,
                                     1,
                                     nvl(avtlp.description, bq.description))) truncateddescription,
                       avtlp.long_description long_description,
                       decode(least(length(avtlp.long_description), 180),
                              180,
                              substr(avtlp.long_description, 1, 177) || '...',
                              avtlp.long_description) truncatedlongdescription,
                       msikfv.concatenated_segments internal_item_num,
                       decode(bq.item_revision,
                              '-2',
                              to_char(NULL),
                              bq.item_revision) item_revision,
                       bq.po_header_id poheaderid,
                       decode(bq.merged_source_type,
                              'REQ_TEMPLATE',
                              nvl(bq.req_template_po_line_id, -2),
                              bq.po_line_id) polineid,
                       bq.document_number documentnumber,
                       bq.line_num documentlinenumber,
                       bq.req_template_name reqtemplatename,
                       bq.req_template_line_num reqtemplatelinenum,
                       decode(bq.order_type_lookup_code,
                              'AMOUNT',
                              1,
                              decode(bq.allow_price_override_flag, 'Y', 1, 0)) allowpriceoverrideflag,
                       bq.not_to_exceed_price amountlimit,
                       decode(bq.order_type_lookup_code, 'FIXED PRICE', 1, 0) isfixedprice,
                       decode(bq.order_type_lookup_code, 'QUANTITY', 0, 1) isfixedpriceoramountbased,
                       decode(bq.order_type_lookup_code,
                              'AMOUNT',
                              0,
                              decode(bq.allow_price_override_flag, 'Y', 0, 1)) isamountreadonly,
                       decode(bq.order_type_lookup_code, 'QUANTITY', 1, 0) isquantitybased,
                       bq.line_type_id linetypeid,
                       bq.po_category_id purchasingcategoryid,
                       bq.ip_category_id shoppingcategoryid,
                       mck.concatenated_segments purchasing_category,
                       bq.ip_category_name shopping_category,
                       muomtl.uom_code uomcode,
                       muomtl.unit_of_measure uomforcart,
                       muomtl.unit_of_measure_tl uom,
                       nvl(bq.suggested_quantity, 1) quantity,
                       bq.unit_price price,
                       decode(bq.order_type_lookup_code,
                              'AMOUNT',
                              nvl(bq.suggested_quantity * bq.unit_price, 1),
                              bq.amount) amount,
                       bq.currency_code currency,
                       decode(bq.supplier_id,
                              -2,
                              to_number(NULL),
                              bq.supplier_id) supplierid,
                       bq.supplier_site_id suppliersiteid,
                       bq.supplier_contact_id suppliercontactid,
                       'N' newsupplierflag,
                       bq.supplier supplier,
                       pvs.vendor_site_code supplier_site,
                       to_char(NULL) suppliercontactname,
                       to_char(NULL) suppliercontactphone,
                       to_char(NULL) suppliercontactfax,
                       to_char(NULL) suppliercontactemail,
                       decode(bq.supplier_part_num,
                              '##NULL##',
                              to_char(NULL),
                              bq.supplier_part_num) supplier_part_num,
                       decode(bq.supplier_part_auxid,
                              '##NULL##',
                              to_char(NULL),
                              bq.supplier_part_auxid) supplier_part_auxid,
                       avtlp.manufacturer manufacturer,
                       av.manufacturer_part_num manufacturer_part_num,
                       bq.buyer_id buyerid,
                       bq.rfq_required_flag rfqrequiredflag,
                       bq.negotiated_by_preparer_flag negotiatedbypreparerflag,
                       to_number(NULL) noncattemplateid,
                       to_char(NULL) attribute1,
                       to_char(NULL) attribute2,
                       to_char(NULL) attribute3,
                       to_char(NULL) attribute4,
                       to_char(NULL) attribute5,
                       to_char(NULL) attribute6,
                       to_char(NULL) attribute7,
                       to_char(NULL) attribute8,
                       to_char(NULL) attribute9,
                       to_char(NULL) attribute10,
                       to_char(NULL) attribute11,
                       to_char(NULL) attribute12,
                       to_char(NULL) attribute13,
                       to_char(NULL) attribute14,
                       to_char(NULL) attribute15,
                       av.thumbnail_image thumbnail_image,
                       av.picture picture,
                       avtlp.alias alias,
                       avtlp.comments comments,
                       av.availability availability,
                       av.lead_time lead_time,
                       av.supplier_url supplier_url,
                       av.manufacturer_url manufacturer_url,
                       av.attachment_url attachment_url,
                       bq.is_item_available isitemavailable,
                       decode(bq.is_item_available, 1, 0, 1) isitemnotavailable,
                       decode(nvl(bq.req_template_name, '-2'), '-2', 0, 1) isreqtemplate,
                       decode(bq.source_type,
                              'MASTER_ITEM',
                              decode(bq.item_type, 'PURCHASE', 0, 1),
                              'INTERNAL_TEMPLATE',
                              1,
                              decode(msikfv.internal_order_enabled_flag,
                                     'Y',
                                     1,
                                     0)) isinternallyorderable,
                       decode(bq.source_type,
                              'MASTER_ITEM',
                              decode(bq.item_type, 'INTERNAL', 0, 1),
                              'INTERNAL_TEMPLATE',
                              0,
                              1) ispurchasable,
                       decode(bq.source_type,
                              'MASTER_ITEM',
                              bq.item_type,
                              'INTERNAL_TEMPLATE',
                              'INTERNAL',
                              decode(msikfv.internal_order_enabled_flag,
                                     'Y',
                                     'BOTH',
                                     'PURCHASE')) itemtype,
                       bq.favorite_list_id favoritelistid,
                       bq.favorite_list_line_id favoritelistlineid,
                       to_number(NULL) contentzoneid,
                       av.unspsc unspsc,
                       to_number(NULL) hazardclassid,
                       'CATALOG' catalogtype,
                       'INTERNAL' catalogsource,
                       decode(substr(lower(thumbnail_image), 1, 7),
                              'http://',
                              0,
                              decode(substr(lower(thumbnail_image), 1, 8),
                                     'https://',
                                     0,
                                     1)) AS isthumbnailfile
                  FROM (SELECT ctxh.inventory_item_id,
                               ctxh.po_line_id,
                               ctxh.req_template_name,
                               ctxh.req_template_line_num,
                               ctxh.org_id,
                               ctxh.LANGUAGE,
                               ctxh.source_type,
                               ctxh.purchasing_org_id,
                               ctxh.ip_category_id,
                               ctxh.ip_category_name,
                               ctxh.po_category_id,
                               ctxh.owning_org_id,
                               ctxh.supplier_id,
                               ctxh.supplier_part_num,
                               ctxh.supplier_part_auxid,
                               ctxh.supplier_site_id,
                               ctxh.item_type,
                               ctxh.item_revision,
                               ctxh.po_header_id,
                               ctxh.document_number,
                               ctxh.line_num,
                               ctxh.allow_price_override_flag,
                               ctxh.not_to_exceed_price,
                               ctxh.line_type_id,
                               ctxh.unit_meas_lookup_code,
                               ctxh.unit_price,
                               ctxh.amount,
                               ctxh.currency_code currency_code,
                               ctxh.rate_type,
                               ctxh.rate_date,
                               ctxh.rate,
                               ctxh.buyer_id,
                               ctxh.supplier_contact_id,
                               ctxh.rfq_required_flag,
                               ctxh.negotiated_by_preparer_flag,
                               ctxh.description,
                               ctxh.supplier,
                               ctxh.req_template_po_line_id,
                               ctxh.order_type_lookup_code,
                               ctxh.merged_source_type,
                               ctxh.global_agreement_flag,
                               ctxh.suggested_quantity,
                               --score(1) relevance_score,
                               1 AS is_item_available,
                               to_number(NULL) favorite_list_id,
                               to_number(NULL) favorite_list_line_id
                          FROM icx_cat_items_ctx_hdrs_tlp ctxh
                         WHERE icx_cat_util_pvt.is_item_valid_for_search(ctxh.source_type,
                                                                         ctxh.po_line_id,
                                                                         ctxh.req_template_name,
                                                                         ctxh.req_template_line_num,
                                                                         ctxh.po_category_id,
                                                                         ctxh.org_id) = 1) bq,
                       po_system_parameters_all psp,
                       mtl_units_of_measure_tl muomtl,
                       icx_cat_attribute_values av,
                       icx_cat_attribute_values_tlp avtlp,
                       po_vendor_sites_all pvs,
                       mtl_categories_kfv mck,
                       mtl_system_items_kfv msikfv
                 WHERE psp.org_id = msikfv.organization_id
                   AND bq.unit_meas_lookup_code = muomtl.unit_of_measure(+)
                   AND bq.LANGUAGE = muomtl.LANGUAGE(+)
                   AND bq.inventory_item_id = av.inventory_item_id(+)
                   AND bq.owning_org_id = av.org_id(+)
                   AND bq.po_line_id = av.po_line_id(+)
                   AND bq.req_template_name = av.req_template_name(+)
                   AND bq.req_template_line_num =
                       av.req_template_line_num(+)
                   AND bq.inventory_item_id = avtlp.inventory_item_id(+)
                   AND bq.owning_org_id = avtlp.org_id(+)
                   AND bq.po_line_id = avtlp.po_line_id(+)
                   AND bq.req_template_name = avtlp.req_template_name(+)
                   AND bq.req_template_line_num =
                       avtlp.req_template_line_num(+)
                   AND bq.LANGUAGE = avtlp.LANGUAGE(+)
                   AND bq.supplier_site_id = pvs.vendor_site_id(+)
                   AND bq.po_category_id = mck.category_id(+)
                   AND bq.inventory_item_id = msikfv.inventory_item_id(+)) v,
               (SELECT ipc.external_source_key, icss.name, icss.store_id
                  FROM icx_por_category_order_map     ipc,
                       icx_cat_zone_secure_attributes icz,
                       icx_cat_store_contents         icsc,
                       icx_cat_content_zones_vl       iccz,
                       icx_cat_shop_stores_vl         icss
                 WHERE icz.ip_category_id = ipc.rt_category_id
                   AND icz.zone_id = icsc.content_id
                   AND iccz.zone_id = icsc.content_id
                   AND icz.securing_attribute = 'CATEGORY'
                   AND iccz.category_attribute_action_flag = 'INCLUDE'
                   AND icss.store_id = icsc.store_id
                   AND icss.NAME = rec_kpi.rech_domaine
                UNION ALL
                SELECT ipc.external_source_key, icss.name, icss.store_id
                  FROM icx_por_category_order_map ipc,
                       icx_cat_store_contents     icsc,
                       icx_cat_content_zones_vl   iccz,
                       icx_cat_shop_stores_vl     icss
                 WHERE iccz.zone_id = icsc.content_id
                   AND iccz.category_attribute_action_flag = 'INCLUDE_ALL'
                   AND icss.store_id = icsc.store_id
                   AND icss.NAME = rec_kpi.rech_domaine) v2,
               mtl_units_of_measure_tl uom
         WHERE v2.external_source_key = v.purchasingcategoryid
           AND v.organization_id = rec_kpi.uo
           AND v.internal_item_num = rec_kpi.result_code_article_interne
           AND uom.uom_code = v.uomcode
           AND uom.LANGUAGE = 'F';
      
        UPDATE dka_sicxrechcat_hist
           SET result_unite_de_mesure = decode(rec_catalog.code_article_interne,
                                               NULL,
                                               NULL,
                                               rec_catalog.unit_of_measure),
               result_prix_unitaire   = rec_catalog.prix_moyen,
               result_prix_minimum    = l_prix_minimum,
               last_update_date       = SYSDATE,
               last_updated_by        = gv_user_id,
               statut           = 'COMPLETE'
          WHERE ROWID = rec_kpi.rid;
      END LOOP;
    
      UPDATE dka_sicxrechcat_hist
         SET last_update_date = SYSDATE,
             last_updated_by  = gv_user_id,
             statut           = 'COMPLETE'
       WHERE ROWID = rec_kpi.rid;
    END LOOP;

    -- Passage du statut à COMPLETE pour toutes les articles non concernés par le calcul
    UPDATE dka_sicxrechcat_hist
       SET last_update_date = SYSDATE,
           last_updated_by  = gv_user_id,
           statut           = 'COMPLETE'
     WHERE statut = 'NEW'
       AND result_code_article_interne IS NULL;
  
    COMMIT;
  
    dka_tools_pkg.put_log_message('Fin du calcul des KPIs');
  
  EXCEPTION
    WHEN OTHERS THEN
      vv_mesg    := vv_mesg || chr(10) || substr(SQLERRM, 1, 400);
      pv_errbuf  := vv_mesg;
      pn_retcode := 2;
  END;

END dka_spomajcatkpi_pkg; -- Package body
/
SHOW ERRORS;
EXIT;
