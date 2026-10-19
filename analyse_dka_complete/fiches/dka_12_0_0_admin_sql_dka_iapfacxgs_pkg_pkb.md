# DKA_IAPFACXGS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPFACXGS_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 6648 ; encodage : utf-8. SHA-256 : `411a1852bcd42d5330960aa2d951585b288c0a550d8551a27a949c36b12eb7d5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init_gv_code` | 70 |
| `init_global_attribute_category` | 90 |
| `init_gn_term_id` | 112 |
| `transaction_type` | 141 |
| `Number_lines` | 162 |
| `shipments` | 188 |
| `get_id_br` | 221 |
| `get_num_br` | 244 |
| `get_packing_slip` | 267 |
| `get_num_ligne_br` | 290 |
| `get_code_tva` | 312 |
| `check_code_rejet` | 345 |
| `ajout_code_99` | 433 |
| `delete_processed_lines` | 457 |
| `reporte_erreur` | 476 |
| `insert_header` | 524 |
| `insert_line` | 1043 |
| `child_import` | 1811 |
| `import` | 4821 |
| `d` | 4888 |
| `control_double` | 4988 |
| `populate_xgs_tables` | 5187 |
| `populate_zci_tables` | 5677 |
| `populate_dsp_tables` | 6169 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_value_sets` | 74 |
| `dka_parameters` | 94 |
| `ap_terms` | 116 |
| `po_headers_all` | 167 |
| `po_lines_all` | 170 |
| `rcv_shipment_headers` | 202 |
| `fnd_flex_value_sets` | 384 |
| `dka_iapfacxgs_interface` | 459 |
| `dka_organisation_v` | 462 |
| `dka_iapfacxgs_reporting_all` | 483 |
| `dka_iapfacxgs_interface` | 503 |
| `ap_invoices_interface` | 555 |
| `ap_invoice_lines_interface` | 1088 |
| `AP_Invoices_interface` | 1653 |
| `ap_invoice_lines_interface` | 1663 |
| `AP_Invoices_interface` | 1677 |
| `po_distributions_all` | 1715 |
| `ap_invoices_interface` | 1744 |
| `ap_invoices_interface` | 1771 |
| `de` | 1776 |
| `ap_invoices_interface` | 1780 |
| `dka_iapfacxgs_interface` | 1854 |
| `dka_iapfacxgs_cde_valid_lig_v` | 1887 |
| `dka_iapfacxgs_cde_valid_lig_v` | 1925 |
| `ap_invoices_interface` | 1939 |
| `ap_interface_rejections` | 1946 |
| `AP_INVOICES_INTERFACE` | 1969 |
| `ap_invoices_interface` | 2113 |
| `ap_invoice_lines_interface` | 2117 |
| `ap_suppliers` | 2227 |
| `HZ_PARTY_SITES` | 2263 |
| `gl_period_statuses` | 2296 |
| `fnd_doc_sequence_assignments` | 2411 |
| `fnd_doc_sequence_assignments` | 2436 |
| `dka_iapfacxgs_cde_valid_lig_v` | 2468 |
| `dka_iapfacxgs_cde_valid_lig_v` | 2474 |
| `dual` | 2489 |
| `dka_iapfacxgs_cde_valid_lig_v` | 2492 |
| `dka_iapfacxgs_cde_valid_lig_v` | 2505 |
| `dka_iapfacxgs_cde_valid_lig_v` | 2539 |
| `dual` | 2580 |
| `dka_iapfacxgs_cde_valid_lig_v` | 2583 |
| `dka_iapfacxgs_cde_valid_lig_v` | 2601 |
| `ZX_RATES_B` | 2786 |
| `ZX_RATES_B` | 2825 |
| `ZX_RATES_B` | 2866 |
| `ZX_RATES_B` | 2907 |
| `ZX_RATES_B` | 2945 |
| `ZX_RATES_B` | 2983 |
| `ZX_RATES_B` | 3023 |
| `ZX_RATES_B` | 3061 |
| `po_headers_all` | 3117 |
| `po_vendors` | 3128 |
| `dka_iapfacxgs_interface` | 3193 |
| `DKA_IAPFACXGS_MTDISP` | 3199 |
| `ZX_RATES_B` | 3439 |
| `ZX_RATES_B` | 3479 |
| `dka_iapfacxgs_interface` | 3721 |
| `DKA_IAPFACXGS_MTDISP` | 3727 |
| `DKA_IAPFACXGS_MTDISP` | 3735 |
| `DKA_IAPFACXGS_MTDISP` | 3763 |
| `ap_invoices_interface` | 3976 |
| `ap_invoices_interface` | 3989 |
| `ap_invoices_interface` | 4003 |
| `ap_invoice_lines_interface` | 4191 |
| `ap_invoices_interface` | 4257 |
| `ap_suppliers` | 4299 |
| `pa_tasks` | 4362 |
| `pa_cost_dist_overrides` | 4394 |
| `ap_invoices_all` | 4464 |
| `AP_INVOICES_INTERFACE` | 4478 |
| `dka_iapfacxgs_interface` | 4503 |
| `dka_iapfacxgs_reporting_all` | 4533 |
| `dka_iapfacxgs_interface` | 4539 |
| `ap_invoices_interface` | 4562 |
| `ap_interface_rejections` | 4743 |
| `hr_operating_units` | 4855 |
| `per_security_organizations_v` | 4864 |
| `ap_invoices_interface` | 4871 |
| `DKA_IAPFACXGS_MTDISP` | 4925 |
| `dka_iapfacxgs_interface` | 5035 |
| `ap_invoices_all` | 5055 |
| `dka_iapfacxgs_interface` | 5091 |
| `DKA_IAPFACXGS_REPORTING_ALL` | 5107 |
| `DKA.DKA_IAPFACXGS_INT_HIST_HEADS` | 5122 |
| `ap_invoices_all` | 5141 |
| `dka_iapfacxgs_interface` | 5155 |
| `dka.dka_iapfacxgs_tmp` | 5244 |
| `dka.dka_iapfacxgs_tmp` | 5282 |
| `DKA_IAPFACXGS_INTERFACE` | 5347 |
| `DKA_IAPFACXGS_REPORTING_ALL` | 5429 |
| `DKA_IAPFACXGS_INT_HIST_LINES` | 5534 |
| `DKA_IAPFACXGS_INT_HIST_HEADS` | 5566 |
| `dka.dka_iapfaczci_tmp` | 5734 |
| `dka.dka_iapfaczci_tmp` | 5772 |
| `DKA_IAPFACXGS_INTERFACE` | 5838 |
| `DKA_IAPFACXGS_REPORTING_ALL` | 5920 |
| `DKA_IAPFACXGS_INT_HIST_LINES` | 6026 |
| `DKA_IAPFACXGS_INT_HIST_HEADS` | 6058 |
| `dka.dka_iapfacdsp_tmp` | 6226 |
| `dka.dka_iapfacdsp_tmp` | 6264 |
| `DKA_IAPFACXGS_INTERFACE` | 6329 |
| `DKA_IAPFACXGS_REPORTING_ALL` | 6411 |
| `DKA_IAPFACXGS_INT_HIST_LINES` | 6516 |
| `DKA_IAPFACXGS_INT_HIST_HEADS` | 6548 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_Tools_Pkg.add_error_stack` | 80 |
| `dka_Tools_Pkg.add_error_stack` | 82 |
| `dka_Tools_Pkg.add_error_stack` | 99 |
| `dka_Tools_Pkg.add_error_stack` | 101 |
| `dka_Tools_Pkg.add_error_stack` | 123 |
| `dka_Tools_Pkg.add_error_stack` | 125 |
| `dka_sarrefac_pkg.is_transaction_type_refac` | 143 |
| `dka_Tools_Pkg.add_error_stack` | 410 |
| `dka_Tools_Pkg.add_error_stack` | 412 |
| `dka_Tools_Pkg.add_error_stack` | 468 |
| `dka_Tools_Pkg.add_error_stack` | 470 |
| `dka_Tools_Pkg.add_error_stack` | 509 |
| `dka_Tools_Pkg.add_error_stack` | 511 |
| `dka_Tools_Pkg.add_error_stack` | 1026 |
| `dka_Tools_Pkg.add_error_stack` | 1029 |
| `dka_Tools_Pkg.put_log_message` | 1648 |
| `dka_Tools_Pkg.put_log_message` | 1649 |
| `dka_Tools_Pkg.put_log_message` | 1656 |
| `dka_Tools_Pkg.put_log_message` | 1657 |
| `dka_Tools_Pkg.add_error_stack` | 1685 |
| `dka_Tools_Pkg.add_error_stack` | 1689 |
| `dka_Tools_Pkg.add_error_stack` | 1692 |
| `dka_Tools_Pkg.add_error_stack` | 1699 |
| `dka_Tools_Pkg.add_error_stack` | 1702 |
| `dka_Tools_Pkg.put_log_message` | 1708 |
| `dka_Tools_Pkg.add_error_stack` | 1728 |
| `dka_Tools_Pkg.add_error_stack` | 1731 |
| `dka_Tools_Pkg.put_log_message` | 1737 |
| `dka_Tools_Pkg.add_error_stack` | 1752 |
| `dka_Tools_Pkg.add_error_stack` | 1755 |
| `dka_Tools_Pkg.put_log_message` | 1761 |
| `dka_Tools_Pkg.put_log_message` | 1776 |
| `dka_Tools_Pkg.put_log_message` | 1777 |
| `dka_Tools_Pkg.add_error_stack` | 1794 |
| `dka_Tools_Pkg.add_error_stack` | 1797 |
| `dka_Tools_Pkg.put_log_message` | 2185 |
| `dka_Tools_Pkg.put_log_message` | 2186 |
| `dka_Tools_Pkg.put_log_message` | 2193 |
| `dka_Tools_Pkg.put_log_message` | 2195 |
| `dka_Tools_Pkg.put_log_message` | 2197 |
| `dka_Tools_Pkg.put_log_message` | 2199 |
| `dka_Tools_Pkg.put_log_message` | 2247 |
| `dka_Tools_Pkg.put_log_message` | 2285 |
| `dka_Tools_Pkg.add_error_stack` | 2303 |
| `dka_Tools_Pkg.add_error_stack` | 2305 |
| `dka_Tools_Pkg.add_error_stack` | 2312 |
| `dka_Tools_Pkg.put_log_message` | 2427 |
| `dka_Tools_Pkg.put_log_message` | 2452 |
| `dka_Tools_Pkg.add_error_stack` | 2555 |
| `dka_Tools_Pkg.add_error_stack` | 2557 |
| `dka_Tools_Pkg.add_error_stack` | 2607 |
| `dka_Tools_Pkg.add_error_stack` | 2609 |
| `Dka_Tools_Pkg.Get_Parameter` | 2620 |
| `dka_Tools_Pkg.put_log_message` | 2631 |
| `dka_Tools_Pkg.put_log_message` | 2633 |
| `dka_tools_pkg.put_log_message` | 2665 |
| `dka_tools_pkg.put_log_message` | 2666 |
| `dka_Tools_Pkg.put_log_message` | 2800 |
| `dka_Tools_Pkg.put_log_message` | 2837 |
| `dka_Tools_Pkg.put_log_message` | 2880 |
| `dka_Tools_Pkg.put_log_message` | 2921 |
| `dka_Tools_Pkg.put_log_message` | 2957 |
| `dka_Tools_Pkg.put_log_message` | 2997 |
| `dka_Tools_Pkg.put_log_message` | 3037 |
| `dka_Tools_Pkg.put_log_message` | 3090 |
| `dka_Tools_Pkg.put_log_message` | 3092 |
| `po_headers_pkg_s2.po_total` | 3152 |
| `dka_Tools_Pkg.put_log_message` | 3187 |
| `dka_Tools_Pkg.put_log_message` | 3191 |
| `dka_Tools_Pkg.put_log_message` | 3195 |
| `dka_Tools_Pkg.put_log_message` | 3205 |
| `dka_Tools_Pkg.put_log_message` | 3210 |
| `dka_Tools_Pkg.put_log_message` | 3213 |
| `dka_Tools_Pkg.put_log_message` | 3224 |
| `dka_Tools_Pkg.put_log_message` | 3229 |
| `dka_Tools_Pkg.put_log_message` | 3232 |
| `dka_Tools_Pkg.put_log_message` | 3236 |
| `Dka_Tools_Pkg.Get_Parameter` | 3320 |
| `dka_Tools_Pkg.put_log_message` | 3331 |
| `Dka_Tools_Pkg.Get_Parameter` | 3334 |
| `dka_Tools_Pkg.put_log_message` | 3345 |
| `dka_Tools_Pkg.put_log_message` | 3453 |
| `dka_Tools_Pkg.put_log_message` | 3493 |
| `dka_Tools_Pkg.put_log_message` | 3556 |
| `po_headers_pkg_s2.po_total` | 3602 |
| `dka_Tools_Pkg.put_log_message` | 3628 |
| `dka_Tools_Pkg.put_log_message` | 3715 |
| `dka_Tools_Pkg.put_log_message` | 3718 |
| `dka_Tools_Pkg.put_log_message` | 3719 |
| `dka_Tools_Pkg.put_log_message` | 3723 |
| `dka_Tools_Pkg.put_log_message` | 3731 |
| `dka_Tools_Pkg.put_log_message` | 3734 |
| `dka_Tools_Pkg.put_log_message` | 3740 |
| `dka_Tools_Pkg.put_log_message` | 3743 |
| `dka_Tools_Pkg.put_log_message` | 3754 |
| `dka_Tools_Pkg.put_log_message` | 3759 |
| `dka_Tools_Pkg.put_log_message` | 3762 |
| `dka_Tools_Pkg.put_log_message` | 3775 |
| `dka_Tools_Pkg.put_log_message` | 3783 |
| `dka_Tools_Pkg.put_log_message` | 3811 |
| `dka_Tools_Pkg.put_log_message` | 3813 |
| `dka_Tools_Pkg.put_log_message` | 3915 |
| `dka_Tools_Pkg.put_log_message` | 4009 |
| `dka_Tools_Pkg.put_log_message` | 4063 |
| `dka_Tools_Pkg.put_log_message` | 4124 |
| `dka_Tools_Pkg.put_log_message` | 4134 |
| `dka_Tools_Pkg.put_log_message` | 4136 |
| `dka_Tools_Pkg.put_log_message` | 4138 |
| `dka_Tools_Pkg.put_log_message` | 4140 |
| `dka_Tools_Pkg.put_log_message` | 4142 |
| `dka_Tools_Pkg.put_log_message` | 4145 |
| `Dka_Tools_Pkg.Get_Parameter` | 4157 |
| `dka_Tools_Pkg.put_log_message` | 4168 |
| `Dka_Tools_Pkg.Get_Parameter` | 4171 |
| `dka_Tools_Pkg.put_log_message` | 4182 |
| `dka_Tools_Pkg.put_log_message` | 4204 |
| `dka_Tools_Pkg.put_log_message` | 4307 |
| `dka_pa_tools_pkg.get_project_info` | 4323 |
| `dka_pa_tools_pkg.pa_get_code_z_refac` | 4349 |
| `dka_Tools_Pkg.put_log_message` | 4450 |
| `dka_Tools_Pkg.put_log_message` | 4494 |
| `dka_Tools_Pkg.put_log_message` | 4514 |
| `dka_Tools_Pkg.put_log_message` | 4518 |
| `dka_Tools_Pkg.put_log_message` | 4523 |
| `dka_Tools_Pkg.put_log_message` | 4559 |
| `dka_Tools_Pkg.put_log_message` | 4587 |
| `DKA_AP_TOOLS_PKG.apply_fonction` | 4600 |
| `dka_Tools_Pkg.put_log_message` | 4609 |
| `dka_Tools_Pkg.put_log_message` | 4612 |
| `DKA_AP_TOOLS_PKG.apply_fonction` | 4620 |
| `dka_Tools_Pkg.put_log_message` | 4629 |
| `dka_Tools_Pkg.put_log_message` | 4632 |
| `dka_Tools_Pkg.put_log_message` | 4643 |
| `fnd_request.submit_request` | 4662 |
| `fnd_message.get` | 4687 |
| `dka_Tools_Pkg.put_outdebug_message` | 4688 |
| `fnd_concurrent.wait_for_request` | 4703 |
| `fnd_message.get` | 4714 |
| `dka_Tools_Pkg.put_log_message` | 4715 |
| `dka_Tools_Pkg.put_log_message` | 4718 |
| `dka_Tools_Pkg.put_log_message` | 4725 |
| `dka_Tools_Pkg.put_log_message` | 4727 |
| `dka_Tools_Pkg.put_log_message` | 4729 |
| `dka_Tools_Pkg.put_log_message` | 4736 |
| `dka_Tools_Pkg.put_log_message` | 4764 |
| `dka_Tools_Pkg.put_log_message` | 4768 |
| `dka_Tools_Pkg.put_log_message` | 4772 |
| `dka_Tools_Pkg.put_log_message` | 4777 |
| `dka_Tools_Pkg.put_outdebug_message` | 4783 |
| `dka_Tools_Pkg.put_log_message` | 4784 |
| `dka_Tools_Pkg.put_log_message` | 4789 |
| `dka_Tools_Pkg.put_log_message` | 4790 |
| `dka_Tools_Pkg.put_log_message` | 4793 |
| `dka_tools_pkg.print_error_stack` | 4799 |
| `dka_tools_pkg.clear_error_stack` | 4800 |
| `dka_Tools_Pkg.put_log_message` | 4802 |
| `dka_Tools_Pkg.put_log_message` | 4804 |
| `dka_Tools_Pkg.put_log_message` | 4807 |
| `dka_Tools_Pkg.put_log_message` | 4812 |
| `dka_Tools_Pkg.put_log_message` | 4845 |
| `fnd_profile.VALUE` | 4866 |
| `dka_Tools_Pkg.put_log_message` | 4880 |
| `dka_Tools_Pkg.put_log_message` | 4881 |
| `dka_Tools_Pkg.put_log_message` | 4888 |
| `dka_Tools_Pkg.put_log_message` | 4892 |
| `Fnd_Request.set_org_id` | 4902 |
| `dka_Tools_Pkg.put_log_message` | 4904 |
| `dka_Tools_Pkg.put_log_message` | 4908 |
| `dka_Tools_Pkg.put_log_message` | 4910 |
| `dka_Tools_Pkg.put_log_message` | 4914 |
| `dka_Tools_Pkg.put_log_message` | 4924 |
| `dka_Tools_Pkg.put_log_message` | 4927 |
| `dka_Tools_Pkg.put_log_message` | 4934 |
| `dka_Tools_Pkg.put_log_message` | 4939 |
| `dka_Tools_Pkg.put_log_message` | 4948 |
| `dka_Tools_Pkg.put_log_message` | 4953 |
| `dka_Tools_Pkg.put_log_message` | 4959 |
| `dka_Tools_Pkg.put_log_message` | 4964 |
| `dka_Tools_Pkg.put_log_message` | 4965 |
| `dka_Tools_Pkg.put_log_message` | 4971 |
| `dka_Tools_Pkg.put_log_message` | 4973 |
| `dka_Tools_Pkg.put_log_message` | 4976 |
| `dka_Tools_Pkg.put_log_message` | 4981 |
| `dka_Tools_Pkg.put_log_message` | 5044 |
| `dka_Tools_Pkg.put_log_message` | 5080 |
| `dka_Tools_Pkg.put_log_message` | 5089 |
| `dka_Tools_Pkg.add_error_stack` | 5165 |
| `dka_Tools_Pkg.add_error_stack` | 5167 |
| `dka_Tools_Pkg.put_log_message` | 5295 |
| `dka_tools_pkg.get_parameter` | 5302 |
| `dka_tools_pkg.get_parameter` | 5316 |
| `dka_Tools_Pkg.put_log_message` | 5333 |
| `dka_Tools_Pkg.put_log_message` | 5513 |
| `dka_Tools_Pkg.put_log_message` | 5518 |
| `dka_Tools_Pkg.put_log_message` | 5632 |
| `dka_Tools_Pkg.put_log_message` | 5634 |
| `dka_Tools_Pkg.put_log_message` | 5637 |
| `dka_Tools_Pkg.put_log_message` | 5642 |
| `dka_Tools_Pkg.put_log_message` | 5645 |
| `dka_Tools_Pkg.put_log_message` | 5655 |
| `dka_Tools_Pkg.put_log_message` | 5784 |
| `dka_tools_pkg.get_parameter` | 5791 |
| `dka_tools_pkg.get_parameter` | 5806 |
| `dka_Tools_Pkg.put_log_message` | 5823 |
| `dka_Tools_Pkg.put_log_message` | 6004 |
| `dka_Tools_Pkg.put_log_message` | 6009 |
| `dka_Tools_Pkg.put_log_message` | 6124 |
| `dka_Tools_Pkg.put_log_message` | 6126 |
| `dka_Tools_Pkg.put_log_message` | 6129 |
| `dka_Tools_Pkg.put_log_message` | 6134 |
| `dka_Tools_Pkg.put_log_message` | 6137 |
| `dka_Tools_Pkg.put_log_message` | 6147 |
| `dka_Tools_Pkg.put_log_message` | 6277 |
| `dka_tools_pkg.get_parameter` | 6284 |
| `dka_tools_pkg.get_parameter` | 6298 |
| `dka_Tools_Pkg.put_log_message` | 6315 |
| `dka_Tools_Pkg.put_log_message` | 6495 |
| `dka_Tools_Pkg.put_log_message` | 6500 |
| `dka_Tools_Pkg.put_log_message` | 6614 |
| `dka_Tools_Pkg.put_log_message` | 6616 |
| `dka_Tools_Pkg.put_log_message` | 6619 |
| `dka_Tools_Pkg.put_log_message` | 6624 |
| `dka_Tools_Pkg.put_log_message` | 6627 |
| `dka_Tools_Pkg.put_log_message` | 6637 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `APXIIMPT` | 4662 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 506, 3738, 3769, 4132, 4491, 4512, 4555, 4691, 4763, 4782, 4907, 5103, 5118, 5133 |
| rollback | 4711, 4720, 4796, 4813, 5659, 6151, 6641 |
| transaction_autonome | 477 |
| when_others | 79, 98, 122, 409, 467, 508, 1025, 1688, 1698, 1727, 1751, 1793, 2281, 2302, 2421, 2446, 2553, 2606, 2795, 2832, 2875, 2916, 2952, 2992, 3032, 3068, 3121, 3131, 3200, 3448, 3488, 3728, 4121, 4306, 4400, 4734, 4801, 4926, 4970, 5079, 5164, 5315, 5654, 5804, 6146, 6297, 6636 |
| suppression | 459, 4925 |
| soumission | 4662 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPFACXGS / DKA | `dka_iapfacxgs_pkg.import` | dka/12.0.0/admin/import/DKA_IAPFACXGS.prt:419 |
| DKA_POPULATE_DSP_TABLES / DKA | `DKA_IAPFACXGS_PKG.populate_dsp_tables` | dka/12.0.0/admin/import/DKA_POPULATE_DSP_TABLES.ldt:419 |
| DKA_POPULATE_XGS_TABLES / DKA | `DKA_IAPFACXGS_PKG.populate_xgs_tables` | dka/12.0.0/admin/import/DKA_POPULATE_XGS_TABLES.prt:419 |
| DKA_POPULATE_ZCI_TABLES / DKA | `DKA_IAPFACXGS_PKG.populate_zci_tables` | dka/12.0.0/admin/import/DKA_POPULATE_ZCI_TABLES.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
