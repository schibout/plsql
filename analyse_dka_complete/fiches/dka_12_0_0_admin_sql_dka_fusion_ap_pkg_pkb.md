# DKA_FUSION_AP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSION_AP_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 9579 ; encodage : cp1252 (repli). SHA-256 : `1443de862b2e7d59b7625254e3dc38ce6c5d6c7eb9ec1a39212eb794cce0ac81`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `dka_print_debug_f` | 106 |
| `dka_verif_param` | 154 |
| `get_all_segments` | 210 |
| `dka_load_tab_category_f` | 319 |
| `dka_ctr_mvts` | 393 |
| `dka_ctr_fournisseur` | 473 |
| `dka_ctr_site_fournisseur` | 574 |
| `dka_ctr_rejets` | 645 |
| `dka_ctr_category_code_f` | 705 |
| `dka_ctr_doc_seq_ass_f` | 802 |
| `dka_ctr_doc_sequence_f` | 906 |
| `dka_ctr_pay_group_f` | 1026 |
| `dka_value_valid_f` | 1202 |
| `dka_ccid_valid_f` | 1379 |
| `dka_new_pay_ccid_f` | 1604 |
| `dka_ins_inv_interface_f` | 2101 |
| `dka_new_dist_ccid_f` | 2433 |
| `dka_new_tax_f` | 2953 |
| `dka_ins_inv_dist_int_f` | 3045 |
| `dka_ap_invoice_lines_int_f` | 3303 |
| `dka_delete_old_values_f` | 4010 |
| `dka_maj_blocage` | 4093 |
| `dka_ins_fusion_ap_invoice_f` | 4193 |
| `dka_new_asset_ccid_f` | 4282 |
| `dka_new_futur_pay_ccid_f` | 4540 |
| `dka_bank_charges_ccid_f` | 4803 |
| `dka_bank_errors_ccid_f` | 5068 |
| `dka_bank_cash_clearing_ccid_f` | 5333 |
| `dka_future_pay_ccid_f` | 5598 |
| `dka_upd_check_stocks_f` | 5855 |
| `dka_upd_bank_accounts_f` | 6018 |
| `dka_cptes_generiques_f` | 6156 |
| `main_ctr` | 6231 |
| `main_extract` | 6705 |
| `main_insert` | 7723 |
| `dka_reinit_ffv_f` | 7794 |
| `dka_reinit_ccid_f` | 7845 |
| `dka_update_inv_distributions_f` | 7891 |
| `dka_insert_hold_f` | 8084 |
| `main_post_fusion` | 8247 |
| `main_hold_no_cent` | 8312 |
| `dka_extract_images` | 8371 |
| `dka_ajout_lien` | 8503 |
| `main_rattchmt_images` | 8629 |
| `dka_liste_lettrage` | 8692 |
| `dka_insert_lettrage` | 8756 |
| `main_let_rec` | 8817 |
| `dka_maj_holds_all` | 8890 |
| `dka_maj_payment_schedules_all` | 8929 |
| `dka_maj_status_approb` | 8970 |
| `dka_liste_maj_lettrage` | 9008 |
| `main_let_maj` | 9136 |
| `dka_liste_mvt_lettrage` | 9204 |
| `main_let_mvt` | 9343 |
| `dka_annulation_wf` | 9396 |
| `dka_notification` | 9468 |
| `main_annul_workflow` | 9527 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_stransco_headers` | 170 |
| `gl_code_combinations` | 264 |
| `fnd_document_sequences` | 340 |
| `ap_supplier_sites_all` | 590 |
| `ap_supplier_sites_all` | 595 |
| `ap_invoices_interface` | 652 |
| `fnd_doc_sequence_categories` | 725 |
| `fnd_doc_sequence_assignments` | 828 |
| `fnd_document_sequences` | 936 |
| `po_lookup_codes` | 1118 |
| `fnd_id_flex_segments` | 1245 |
| `dka_fusion_ap_ffv` | 1283 |
| `FND_FLEX_VALUES` | 1299 |
| `fnd_flex_values` | 1305 |
| `FND_FLEX_VALUES` | 1312 |
| `gl_sets_of_books` | 1431 |
| `dka_fusion_ap_ccid` | 1474 |
| `GL_CODE_COMBINATIONS` | 1490 |
| `gl_code_combinations` | 1496 |
| `GL_CODE_COMBINATIONS` | 1503 |
| `dka_fusion_ap_inv_int` | 2205 |
| `zx_lines` | 2979 |
| `dka_fusion_ap_inv_lin_int` | 3124 |
| `ap_invoice_distributions_all` | 3392 |
| `ap_invoice_distributions_all` | 3553 |
| `zx_rates_b` | 3742 |
| `zx_rates_b` | 3757 |
| `dual` | 3773 |
| `zx_rates_b` | 3784 |
| `dual` | 3864 |
| `ap_invoices_all` | 4097 |
| `ap_hold_codes` | 4123 |
| `fnd_user` | 4130 |
| `ap_holds_all` | 4141 |
| `dka_fusion_ap_invoice` | 4216 |
| `ap_check_stocks_all` | 5870 |
| `OF` | 5872 |
| `ap_check_stocks_all` | 5956 |
| `dka_stransco_headers` | 6034 |
| `OF` | 6042 |
| `ap_bank_accounts_all` | 6092 |
| `dka_stransco_headers` | 6174 |
| `dka_stransco_headers` | 6269 |
| `dka_stransco_headers` | 6305 |
| `ap_payment_schedules_all` | 6543 |
| `hr_operating_units` | 6601 |
| `ap_invoice_lines_all` | 6747 |
| `dka_stransco_headers` | 6797 |
| `ap_invoice_distributions_all` | 6823 |
| `ap_invoice_lines_all` | 6937 |
| `dka_stransco_headers` | 6991 |
| `ap_invoice_distributions_all` | 7016 |
| `dual` | 7206 |
| `hr_operating_units` | 7232 |
| `ap_supplier_sites_all` | 7239 |
| `ap_supplier_sites_all` | 7246 |
| `hz_party_sites` | 7261 |
| `iby_ext_payee_relationships` | 7306 |
| `dual` | 7446 |
| `iby_ext_payee_relationships` | 7505 |
| `ap_invoices_interface` | 7743 |
| `dka_fusion_ap_inv_int` | 7744 |
| `ap_invoice_lines_interface` | 7750 |
| `dka_fusion_ap_inv_lin_int` | 7751 |
| `dka_fusion_ap_ffv` | 7803 |
| `fnd_flex_values` | 7813 |
| `dka_fusion_ap_ccid` | 7851 |
| `gl_code_combinations` | 7861 |
| `dka_fusion_ap_invoice` | 7895 |
| `ap_invoice_distributions_all` | 7903 |
| `OF` | 7907 |
| `ap_invoice_distributions_all` | 7916 |
| `OF` | 7922 |
| `ap_invoices_all` | 7969 |
| `ap_invoices_all` | 7976 |
| `ap_invoice_distributions_all` | 8018 |
| `ap_invoice_distributions_all` | 8025 |
| `dka_fusion_ap_invoice` | 8117 |
| `ap_holds_all` | 8146 |
| `dka_ap_invfus_attached_docs` | 8376 |
| `ap_invoices_all` | 8437 |
| `hr_all_organization_units` | 8438 |
| `ap_supplier_sites_all` | 8440 |
| `ap_suppliers` | 8442 |
| `fnd_attached_documents` | 8444 |
| `fnd_documents` | 8448 |
| `fnd_documents_tl` | 8450 |
| `fnd_document_datatypes` | 8454 |
| `dka_stransco_headers` | 8458 |
| `dka_stransco_lines` | 8460 |
| `dka_fusion_ap_invoice` | 8464 |
| `dka_ap_invfus_attached_docs` | 8541 |
| `dual` | 8568 |
| `fnd_attached_documents` | 8570 |
| `dka_ap_invfus_attached_docs` | 8648 |
| `dka_fusion_ap_lettrage` | 8700 |
| `dka_fusion_ap_lettrage` | 8764 |
| `ap_invoices_all` | 8777 |
| `ap_holds_all` | 8898 |
| `dka_fusion_ap_lettrage` | 8901 |
| `ap_payment_schedules_all` | 8937 |
| `dka_fusion_ap_lettrage` | 8942 |
| `ap_invoices_all` | 8978 |
| `dka_fusion_ap_lettrage` | 8980 |
| `dka_fusion_ap_lettrage` | 9022 |
| `dka_fusion_ap_lettrage` | 9037 |
| `dka_fusion_ap_lettrage` | 9052 |
| `ap_invoices_all` | 9226 |
| `ap_invoices_v` | 9258 |
| `wf_item_activity_statuses` | 9404 |
| `wf_notifications` | 9476 |
| `wf_notifications` | 9488 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 120 |
| `dka_tools_pkg.put_debug_message` | 133 |
| `dka_tools_pkg.put_outdebug_message` | 136 |
| `dka_tools_pkg.put_debug_message` | 182 |
| `dka_tools_pkg.put_outdebug_message` | 183 |
| `dka_tools_pkg.put_debug_message` | 372 |
| `dka_tools_pkg.put_outdebug_message` | 375 |
| `dka_tools_pkg.put_outdebug_message` | 436 |
| `dka_tools_pkg.put_outdebug_message` | 441 |
| `dka_tools_pkg.put_debug_message` | 455 |
| `dka_tools_pkg.put_outdebug_message` | 457 |
| `dka_tools_pkg.put_outdebug_message` | 519 |
| `dka_tools_pkg.get_code_combination_id` | 525 |
| `dka_tools_pkg.put_outdebug_message` | 543 |
| `dka_tools_pkg.put_outdebug_message` | 544 |
| `dka_tools_pkg.put_debug_message` | 555 |
| `dka_tools_pkg.put_outdebug_message` | 557 |
| `dka_tools_pkg.put_outdebug_message` | 599 |
| `dka_tools_pkg.put_outdebug_message` | 609 |
| `dka_tools_pkg.put_outdebug_message` | 617 |
| `dka_tools_pkg.put_debug_message` | 626 |
| `dka_tools_pkg.put_outdebug_message` | 628 |
| `dka_tools_pkg.put_outdebug_message` | 669 |
| `dka_tools_pkg.put_outdebug_message` | 672 |
| `dka_tools_pkg.put_debug_message` | 687 |
| `dka_tools_pkg.put_outdebug_message` | 688 |
| `dka_tools_pkg.put_outdebug_message` | 750 |
| `dka_tools_pkg.put_debug_message` | 778 |
| `dka_tools_pkg.put_outdebug_message` | 781 |
| `dka_tools_pkg.put_outdebug_message` | 838 |
| `dka_tools_pkg.put_debug_message` | 880 |
| `dka_tools_pkg.put_outdebug_message` | 885 |
| `dka_tools_pkg.put_outdebug_message` | 960 |
| `dka_tools_pkg.put_debug_message` | 996 |
| `dka_tools_pkg.put_outdebug_message` | 1001 |
| `dka_tools_pkg.put_outdebug_message` | 1174 |
| `dka_tools_pkg.put_outdebug_message` | 1182 |
| `dka_tools_pkg.put_outdebug_message` | 1184 |
| `fnd_profile.value` | 1248 |
| `dka_tools_pkg.put_outdebug_message` | 1357 |
| `dka_tools_pkg.put_outdebug_message` | 1360 |
| `fnd_profile.value` | 1432 |
| `dka_tools_pkg.put_outdebug_message` | 1564 |
| `dka_tools_pkg.put_outdebug_message` | 1572 |
| `dka_tools_pkg.put_outdebug_message` | 1671 |
| `dka_tools_pkg.get_code_combination_id` | 1951 |
| `dka_tools_pkg.get_code_combination_id` | 1969 |
| `dka_tools_pkg.get_code_combination_id` | 1988 |
| `dka_tools_pkg.put_outdebug_message` | 2038 |
| `dka_tools_pkg.put_outdebug_message` | 2040 |
| `dka_tools_pkg.put_outdebug_message` | 2078 |
| `dka_tools_pkg.put_outdebug_message` | 2086 |
| `fnd_profile.value` | 2348 |
| `fnd_profile.value` | 2349 |
| `dka_tools_pkg.put_outdebug_message` | 2386 |
| `dka_tools_pkg.put_outdebug_message` | 2389 |
| `dka_tools_pkg.get_code_combination_id` | 2795 |
| `dka_tools_pkg.get_code_combination_id` | 2813 |
| `dka_tools_pkg.get_code_combination_id` | 2832 |
| `dka_tools_pkg.put_outdebug_message` | 2882 |
| `dka_tools_pkg.put_outdebug_message` | 2885 |
| `dka_tools_pkg.put_outdebug_message` | 2923 |
| `dka_tools_pkg.put_outdebug_message` | 2933 |
| `dka_tools_pkg.put_outdebug_message` | 2995 |
| `dka_tools_pkg.put_outdebug_message` | 3027 |
| `dka_tools_pkg.put_outdebug_message` | 3030 |
| `fnd_profile.value` | 3244 |
| `fnd_profile.value` | 3247 |
| `dka_tools_pkg.put_outdebug_message` | 3281 |
| `dka_tools_pkg.put_outdebug_message` | 3284 |
| `ap_invoices_utility_pkg.get_prepay_amount_remaining` | 3485 |
| `ap_invoices_utility_pkg.get_prepay_amount_remaining` | 3630 |
| `dka_tools_pkg.put_outdebug_message` | 3990 |
| `dka_tools_pkg.put_outdebug_message` | 3995 |
| `dka_tools_pkg.put_outdebug_message` | 4076 |
| `dka_tools_pkg.put_outdebug_message` | 4078 |
| `dka_tools_pkg.put_outdebug_message` | 4164 |
| `dka_tools_pkg.put_outdebug_message` | 4176 |
| `dka_tools_pkg.put_outdebug_message` | 4177 |
| `dka_tools_pkg.put_outdebug_message` | 4255 |
| `dka_tools_pkg.put_outdebug_message` | 4262 |
| `dka_tools_pkg.get_code_combination_id` | 4483 |
| `dka_tools_pkg.put_outdebug_message` | 4502 |
| `dka_tools_pkg.put_outdebug_message` | 4504 |
| `dka_tools_pkg.put_outdebug_message` | 4516 |
| `dka_tools_pkg.put_outdebug_message` | 4520 |
| `dka_tools_pkg.get_code_combination_id` | 4744 |
| `dka_tools_pkg.put_outdebug_message` | 4763 |
| `dka_tools_pkg.put_outdebug_message` | 4765 |
| `dka_tools_pkg.put_outdebug_message` | 4777 |
| `dka_tools_pkg.put_outdebug_message` | 4781 |
| `dka_tools_pkg.get_code_combination_id` | 5008 |
| `dka_tools_pkg.put_outdebug_message` | 5027 |
| `dka_tools_pkg.put_outdebug_message` | 5031 |
| `dka_tools_pkg.put_outdebug_message` | 5043 |
| `dka_tools_pkg.put_outdebug_message` | 5047 |
| `dka_tools_pkg.get_code_combination_id` | 5273 |
| `dka_tools_pkg.put_outdebug_message` | 5292 |
| `dka_tools_pkg.put_outdebug_message` | 5296 |
| `dka_tools_pkg.put_outdebug_message` | 5308 |
| `dka_tools_pkg.put_outdebug_message` | 5312 |
| `dka_tools_pkg.get_code_combination_id` | 5538 |
| `dka_tools_pkg.put_outdebug_message` | 5557 |
| `dka_tools_pkg.put_outdebug_message` | 5561 |
| `dka_tools_pkg.put_outdebug_message` | 5573 |
| `dka_tools_pkg.put_outdebug_message` | 5577 |
| `dka_tools_pkg.get_code_combination_id` | 5801 |
| `dka_tools_pkg.put_outdebug_message` | 5820 |
| `dka_tools_pkg.put_outdebug_message` | 5824 |
| `dka_tools_pkg.put_outdebug_message` | 5836 |
| `dka_tools_pkg.put_outdebug_message` | 5840 |
| `fnd_profile.value` | 5978 |
| `fnd_profile.value` | 5979 |
| `dka_tools_pkg.put_outdebug_message` | 5990 |
| `dka_tools_pkg.put_outdebug_message` | 6000 |
| `dka_tools_pkg.put_outdebug_message` | 6001 |
| `fnd_profile.value` | 6102 |
| `fnd_profile.value` | 6103 |
| `dka_tools_pkg.put_outdebug_message` | 6130 |
| `dka_tools_pkg.put_outdebug_message` | 6139 |
| `dka_tools_pkg.put_outdebug_message` | 6140 |
| `dka_tools_pkg.put_outdebug_message` | 6215 |
| `dka_tools_pkg.put_outdebug_message` | 6216 |
| `fnd_client_info.set_org_context` | 6414 |
| `ap_invoices_utility_pkg.get_posting_status` | 6447 |
| `dka_tools_pkg.put_outdebug_message` | 6449 |
| `dka_tools_pkg.put_outdebug_message` | 6452 |
| `dka_tools_pkg.put_outdebug_message` | 6547 |
| `dka_tools_pkg.put_outdebug_message` | 6548 |
| `dka_tools_pkg.put_outdebug_message` | 6594 |
| `dka_tools_pkg.put_outdebug_message` | 6595 |
| `dka_tools_pkg.put_outdebug_message` | 6596 |
| `dka_tools_pkg.put_outdebug_message` | 6670 |
| `dka_tools_pkg.put_outdebug_message` | 6684 |
| `dka_tools_pkg.put_outdebug_message` | 6685 |
| `dka_tools_pkg.put_outdebug_message` | 6686 |
| `fnd_number.number_to_canonical` | 6737 |
| `fnd_number.number_to_canonical` | 6846 |
| `ap_invoices_utility_pkg.get_prepay_amount_remaining` | 6913 |
| `fnd_number.number_to_canonical` | 6927 |
| `ap_invoices_utility_pkg.get_prepay_amount_remaining` | 7028 |
| `fnd_number.number_to_canonical` | 7040 |
| `ap_invoices_utility_pkg.get_prepay_amount_remaining` | 7092 |
| `dka_tools_pkg.put_outdebug_message` | 7152 |
| `dka_tools_pkg.put_outdebug_message` | 7156 |
| `dka_tools_pkg.put_outdebug_message` | 7199 |
| `dka_tools_pkg.put_debug_message` | 7253 |
| `dka_tools_pkg.put_outdebug_message` | 7254 |
| `dka_tools_pkg.put_debug_message` | 7276 |
| `dka_tools_pkg.put_outdebug_message` | 7277 |
| `dka_tools_pkg.put_debug_message` | 7331 |
| `dka_tools_pkg.put_outdebug_message` | 7332 |
| `dka_tools_pkg.put_outdebug_message` | 7477 |
| `dka_tools_pkg.put_debug_message` | 7531 |
| `dka_tools_pkg.put_outdebug_message` | 7532 |
| `dka_tools_pkg.put_outdebug_message` | 7661 |
| `dka_tools_pkg.put_outdebug_message` | 7662 |
| `dka_tools_pkg.put_outdebug_message` | 7664 |
| `dka_tools_pkg.put_outdebug_message` | 7666 |
| `dka_tools_pkg.put_outdebug_message` | 7692 |
| `dka_tools_pkg.put_outdebug_message` | 7697 |
| `dka_tools_pkg.put_outdebug_message` | 7703 |
| `dka_tools_pkg.put_outdebug_message` | 7704 |
| `dka_tools_pkg.put_outdebug_message` | 7705 |
| `dka_tools_pkg.put_outdebug_message` | 7746 |
| `dka_tools_pkg.put_outdebug_message` | 7753 |
| `dka_tools_pkg.put_outdebug_message` | 7766 |
| `dka_tools_pkg.put_outdebug_message` | 7773 |
| `dka_tools_pkg.put_outdebug_message` | 7775 |
| `dka_tools_pkg.put_outdebug_message` | 7776 |
| `dka_tools_pkg.put_outdebug_message` | 7828 |
| `dka_tools_pkg.put_outdebug_message` | 7830 |
| `dka_tools_pkg.put_outdebug_message` | 7875 |
| `dka_tools_pkg.put_outdebug_message` | 7877 |
| `dka_tools_pkg.put_outdebug_message` | 7994 |
| `dka_tools_pkg.put_outdebug_message` | 8043 |
| `dka_tools_pkg.put_outdebug_message` | 8044 |
| `dka_tools_pkg.put_outdebug_message` | 8046 |
| `dka_tools_pkg.put_outdebug_message` | 8047 |
| `dka_tools_pkg.put_outdebug_message` | 8048 |
| `dka_tools_pkg.put_outdebug_message` | 8049 |
| `dka_tools_pkg.put_outdebug_message` | 8052 |
| `dka_tools_pkg.put_outdebug_message` | 8054 |
| `dka_tools_pkg.put_outdebug_message` | 8056 |
| `dka_tools_pkg.put_outdebug_message` | 8058 |
| `dka_tools_pkg.put_outdebug_message` | 8060 |
| `dka_tools_pkg.put_outdebug_message` | 8068 |
| `dka_tools_pkg.put_outdebug_message` | 8070 |
| `fnd_profile.value` | 8186 |
| `fnd_profile.value` | 8193 |
| `fnd_profile.value` | 8195 |
| `dka_tools_pkg.put_outdebug_message` | 8216 |
| `dka_tools_pkg.put_outdebug_message` | 8223 |
| `dka_tools_pkg.put_outdebug_message` | 8231 |
| `dka_tools_pkg.put_outdebug_message` | 8233 |
| `dka_tools_pkg.put_outdebug_message` | 8284 |
| `dka_tools_pkg.put_outdebug_message` | 8291 |
| `dka_tools_pkg.put_outdebug_message` | 8292 |
| `dka_tools_pkg.put_outdebug_message` | 8293 |
| `dka_tools_pkg.put_outdebug_message` | 8344 |
| `dka_tools_pkg.put_outdebug_message` | 8351 |
| `dka_tools_pkg.put_outdebug_message` | 8352 |
| `dka_tools_pkg.put_outdebug_message` | 8353 |
| `dka_tools_pkg.put_outdebug_message` | 8472 |
| `dka_tools_pkg.put_outdebug_message` | 8484 |
| `dka_tools_pkg.put_outdebug_message` | 8485 |
| `fnd_profile.value` | 8589 |
| `fnd_profile.value` | 8591 |
| `dka_tools_pkg.put_outdebug_message` | 8602 |
| `dka_tools_pkg.put_outdebug_message` | 8613 |
| `dka_tools_pkg.put_outdebug_message` | 8614 |
| `dka_tools_pkg.put_outdebug_message` | 8666 |
| `dka_tools_pkg.put_outdebug_message` | 8674 |
| `dka_tools_pkg.put_outdebug_message` | 8675 |
| `dka_tools_pkg.put_outdebug_message` | 8676 |
| `dka_tools_pkg.put_outdebug_message` | 8711 |
| `dka_tools_pkg.put_outdebug_message` | 8712 |
| `dka_tools_pkg.put_outdebug_message` | 8713 |
| `dka_tools_pkg.put_outdebug_message` | 8714 |
| `dka_tools_pkg.put_outdebug_message` | 8724 |
| `dka_tools_pkg.put_outdebug_message` | 8742 |
| `dka_tools_pkg.put_outdebug_message` | 8743 |
| `dka_tools_pkg.put_outdebug_message` | 8793 |
| `dka_tools_pkg.put_outdebug_message` | 8801 |
| `dka_tools_pkg.put_outdebug_message` | 8802 |
| `dka_tools_pkg.put_outdebug_message` | 8862 |
| `dka_tools_pkg.put_outdebug_message` | 8866 |
| `dka_tools_pkg.put_outdebug_message` | 8871 |
| `dka_tools_pkg.put_outdebug_message` | 8872 |
| `dka_tools_pkg.put_outdebug_message` | 8873 |
| `dka_tools_pkg.put_outdebug_message` | 8904 |
| `dka_tools_pkg.put_outdebug_message` | 8914 |
| `dka_tools_pkg.put_outdebug_message` | 8915 |
| `dka_tools_pkg.put_outdebug_message` | 8945 |
| `dka_tools_pkg.put_outdebug_message` | 8955 |
| `dka_tools_pkg.put_outdebug_message` | 8956 |
| `dka_tools_pkg.put_outdebug_message` | 8983 |
| `dka_tools_pkg.put_outdebug_message` | 8993 |
| `dka_tools_pkg.put_outdebug_message` | 8994 |
| `dka_tools_pkg.put_outdebug_message` | 9062 |
| `dka_tools_pkg.put_outdebug_message` | 9063 |
| `dka_tools_pkg.put_outdebug_message` | 9064 |
| `dka_tools_pkg.put_outdebug_message` | 9072 |
| `dka_tools_pkg.put_outdebug_message` | 9092 |
| `dka_tools_pkg.put_outdebug_message` | 9093 |
| `dka_tools_pkg.put_outdebug_message` | 9094 |
| `dka_tools_pkg.put_outdebug_message` | 9095 |
| `dka_tools_pkg.put_outdebug_message` | 9096 |
| `dka_tools_pkg.put_outdebug_message` | 9104 |
| `dka_tools_pkg.put_outdebug_message` | 9119 |
| `dka_tools_pkg.put_outdebug_message` | 9120 |
| `dka_tools_pkg.put_outdebug_message` | 9178 |
| `dka_tools_pkg.put_outdebug_message` | 9185 |
| `dka_tools_pkg.put_outdebug_message` | 9186 |
| `dka_tools_pkg.put_outdebug_message` | 9187 |
| `dka_tools_pkg.put_outdebug_message` | 9283 |
| `dka_tools_pkg.put_outdebug_message` | 9284 |
| `dka_tools_pkg.put_outdebug_message` | 9285 |
| `dka_tools_pkg.put_outdebug_message` | 9293 |
| `dka_tools_pkg.put_outdebug_message` | 9326 |
| `dka_tools_pkg.put_outdebug_message` | 9327 |
| `dka_tools_pkg.put_outdebug_message` | 9370 |
| `dka_tools_pkg.put_outdebug_message` | 9377 |
| `dka_tools_pkg.put_outdebug_message` | 9378 |
| `dka_tools_pkg.put_outdebug_message` | 9379 |
| `wf_engine.abortprocess` | 9432 |
| `dka_tools_pkg.put_outdebug_message` | 9434 |
| `dka_tools_pkg.put_outdebug_message` | 9440 |
| `dka_tools_pkg.put_outdebug_message` | 9442 |
| `dka_tools_pkg.put_outdebug_message` | 9453 |
| `dka_tools_pkg.put_outdebug_message` | 9454 |
| `dka_tools_pkg.put_outdebug_message` | 9491 |
| `dka_tools_pkg.put_outdebug_message` | 9497 |
| `dka_tools_pkg.put_outdebug_message` | 9499 |
| `dka_tools_pkg.put_outdebug_message` | 9510 |
| `dka_tools_pkg.put_outdebug_message` | 9511 |
| `dka_tools_pkg.put_outdebug_message` | 9558 |
| `dka_tools_pkg.put_outdebug_message` | 9566 |
| `dka_tools_pkg.put_outdebug_message` | 9567 |
| `dka_tools_pkg.put_outdebug_message` | 9568 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 6672, 6678, 7695, 8478 |
| rollback | 6687, 7698, 7706, 7767, 7777, 8285, 8294, 8345, 8354, 8667, 8677, 8864, 8874, 9179, 9188, 9371, 9380, 9559, 9569 |
| when_others | 131, 180, 295, 370, 453, 553, 624, 685, 776, 878, 994, 1180, 1355, 1562, 2076, 2384, 2921, 3025, 3279, 3987, 4074, 4173, 4253, 4514, 4775, 5041, 5306, 5571, 5834, 5997, 6136, 6213, 6682, 7251, 7274, 7329, 7529, 7701, 7771, 7826, 7873, 8066, 8228, 8289, 8349, 8481, 8611, 8672, 8739, 8798, 8869, 8910, 8951, 8989, 9116, 9183, 9323, 9375, 9438, 9449, 9495, 9506, 9564 |
| suppression | 8648 |
| workflow | 9432 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSAP_ANNUL_WF / DKA | `DKA_FUSION_AP_PKG.main_Annul_workflow` | dka/12.0.0/admin/import/DKA_FUSAP_ANNUL_WF.ldt:472 |
| DKA_FUSAP_BLOCAGE / DKA | `DKA_FUSION_AP_PKG.main_Hold_No_Cent` | dka/12.0.0/admin/import/DKA_FUSAP_BLOCAGE.ldt:477 |
| DKA_FUSAP_CONTROL / DKA | `DKA_FUSION_AP_PKG.Main_Ctr` | dka/12.0.0/admin/import/DKA_FUSAP_CONTROL.ldt:477 |
| DKA_FUSAP_EXTRACT / DKA | `DKA_FUSION_AP_PKG.Main_Extract` | dka/12.0.0/admin/import/DKA_FUSAP_EXTRACT.ldt:477 |
| DKA_FUSAP_IMAGES / DKA | `DKA_FUSION_AP_PKG.main_Rattchmt_Images` | dka/12.0.0/admin/import/DKA_FUSAP_IMAGES.ldt:494 |
| DKA_FUSAP_INSERT / DKA | `DKA_FUSION_AP_PKG.Main_Insert` | dka/12.0.0/admin/import/DKA_FUSAP_INSERT.ldt:477 |
| DKA_FUSAP_MAJ_LETTRAGE / DKA | `DKA_FUSION_AP_PKG.main_Let_Maj` | dka/12.0.0/admin/import/DKA_FUSAP_MAJ_LETTRAGE.ldt:477 |
| DKA_FUSAP_MVT_LETTRAGE / DKA | `DKA_FUSION_AP_PKG.main_Let_Mvt` | dka/12.0.0/admin/import/DKA_FUSAP_MVT_LETTRAGE.ldt:477 |
| DKA_FUSAP_POST / DKA | `DKA_FUSION_AP_PKG.Main_Post_Fusion` | dka/12.0.0/admin/import/DKA_FUSAP_POST.ldt:477 |
| DKA_FUSAP_REC_LETTRAGE / DKA | `DKA_FUSION_AP_PKG.main_Let_Rec` | dka/12.0.0/admin/import/DKA_FUSAP_REC_LETTRAGE.ldt:477 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
