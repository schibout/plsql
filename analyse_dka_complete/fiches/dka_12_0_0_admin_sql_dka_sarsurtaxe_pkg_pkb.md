# DKA_SARSURTAXE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARSURTAXE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARSURTAXE_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 5724 ; encodage : cp1252 (repli). SHA-256 : `6bb49d25cc2527dc1e3f03581cdcca96439898736eb08e1f893e0cad521945b2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 111 |
| `get_segment4` | 249 |
| `purge_dka_sarsurtaxe_tmp` | 295 |
| `insert_ar_invoices` | 332 |
| `insert_gl_invoices_gericco` | 568 |
| `insert_dka_sarsurtaxe_tmp` | 880 |
| `insert_ap_invoices_interface` | 951 |
| `get_vdr_account` | 968 |
| `insert_ap_inv_lines_interface` | 1344 |
| `insert_ap_inv_lines_int_tax` | 1918 |
| `load_ap_invoices_interfaces` | 2198 |
| `load_data` | 2434 |
| `main` | 2503 |
| `update_after_import_ap` | 2553 |
| `update_ra_cust_trx_line_gl_dis` | 2608 |
| `update_gl_je_lines_cuf` | 2655 |
| `purge_ap_invoices_interface` | 2701 |
| `launch_apprvl` | 2744 |
| `main2` | 2883 |
| `update_gl_je_lines` | 2935 |
| `load_ref_let` | 3031 |
| `main3` | 3260 |
| `insert_gl_interface_control` | 3304 |
| `insert_gl_interface` | 3381 |
| `launch_glxrcaut` | 3965 |
| `main4` | 4187 |
| `update_dka_sarsurtaxe_tmp` | 4416 |
| `main5` | 4457 |
| `insert_dka_sarsurtaxe_ctl_tmp` | 4484 |
| `controle_fournisseur_absent` | 4603 |
| `controle_fournisseur_doublon` | 4672 |
| `CTR_FOURNISSEUR_DOUBLON_TMP` | 4778 |
| `controle_site_frs_absent` | 4868 |
| `controle_facture_negative` | 4942 |
| `bilan_surtaxe` | 5027 |
| `main6` | 5121 |
| `main7` | 5203 |
| `launch_xlaaccpb` | 5325 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_stransco_headers` | 266 |
| `dka_sarsurtaxe_tmp_all` | 306 |
| `dka_sarsurtaxe_tmp` | 346 |
| `ra_customer_trx` | 407 |
| `ar_adjustments` | 427 |
| `po_vendors` | 472 |
| `po_vendor_sites` | 482 |
| `DKA_SARSURTAXE_TMP_ALL` | 516 |
| `PO_VENDORS` | 519 |
| `PO_VENDORS` | 527 |
| `dka_sarsurtaxe_tmp` | 581 |
| `gl_je_lines` | 638 |
| `po_vendor_sites` | 683 |
| `DUAL` | 895 |
| `gl_code_combinations` | 975 |
| `gl_code_combinations` | 1000 |
| `gl_access_sets` | 1011 |
| `AP_SUPPLIER_SITES_ALL` | 1019 |
| `po_vendor_sites_all` | 1113 |
| `ap_invoices_interface` | 1122 |
| `DUAL` | 1300 |
| `DUAL` | 1314 |
| `DUAL` | 1379 |
| `ap_invoice_lines_interface` | 1409 |
| `DUAL` | 1636 |
| `ap_invoice_lines_interface` | 1934 |
| `DUAL` | 2169 |
| `dka_sarsurtaxe_tmp` | 2216 |
| `dka_sarsurtaxe_tmp` | 2249 |
| `hr_operating_units` | 2292 |
| `dka_sarsurtaxe_tmp` | 2314 |
| `dka_sarsurtaxe_tmp` | 2358 |
| `dka_sarsurtaxe_tmp` | 2367 |
| `dka_sarsurtaxe_tmp` | 2376 |
| `dka_sarsurtaxe_tmp` | 2401 |
| `dka_sarsurtaxe_tmp` | 2446 |
| `dka_sarsurtaxe_tmp` | 2565 |
| `ap_lookup_codes` | 2568 |
| `ap_invoices_interface` | 2575 |
| `dka_sarsurtaxe_tmp` | 2579 |
| `ap_invoices_interface` | 2583 |
| `ra_cust_trx_line_gl_dist_all` | 2620 |
| `dka_sarsurtaxe_tmp` | 2622 |
| `dka_sarsurtaxe_tmp` | 2627 |
| `gl_je_lines` | 2667 |
| `dka_sarsurtaxe_tmp` | 2669 |
| `dka_sarsurtaxe_tmp` | 2676 |
| `ap_invoice_lines_interface` | 2713 |
| `ap_invoices_interface` | 2715 |
| `ap_invoices_interface` | 2718 |
| `fnd_lookups` | 2769 |
| `fnd_lookups` | 2776 |
| `dka_sarsurtaxe_tmp` | 2788 |
| `fnd_responsibility` | 2807 |
| `gl_je_lines_recon` | 2952 |
| `gl_je_headers` | 2959 |
| `gl_je_headers` | 2990 |
| `dka_sarsurtaxe_tmp` | 3005 |
| `dka_sarsurtaxe_tmp` | 3053 |
| `DUAL` | 3081 |
| `po_vendors` | 3142 |
| `gl_code_combinations` | 3152 |
| `dka_sarsurtaxe_tmp` | 3179 |
| `dka_sarsurtaxe_tmp` | 3187 |
| `dka_sarsurtaxe_tmp` | 3227 |
| `DUAL` | 3318 |
| `gl_je_sources` | 3323 |
| `DUAL` | 3332 |
| `gl_interface_control` | 3336 |
| `dka_sarsurtaxe_tmp` | 3351 |
| `gl_interface` | 3392 |
| `dka_sarsurtaxe_tmp` | 3652 |
| `gl_interface` | 3664 |
| `ap_invoices` | 3926 |
| `dka_sarsurtaxe_tmp` | 3932 |
| `gl_lookups` | 4002 |
| `GL_ACCESS_SETS` | 4009 |
| `dka_sarsurtaxe_tmp` | 4021 |
| `gl_ledgers` | 4038 |
| `gl_period_statuses` | 4046 |
| `gl_period_statuses` | 4055 |
| `gl_period_statuses` | 4074 |
| `gl_period_statuses` | 4082 |
| `fnd_flex_value_sets` | 4092 |
| `fnd_responsibility` | 4112 |
| `fnd_responsibility` | 4222 |
| `fnd_responsibility` | 4264 |
| `DUAL` | 4315 |
| `gl_je_batches` | 4320 |
| `GL_AUTOMATIC_POSTING_SETS` | 4352 |
| `dka_sarsurtaxe_tmp` | 4427 |
| `gl_je_lines_recon` | 4432 |
| `dka_sarsurtaxe_ctl_tmp` | 4501 |
| `ra_customer_trx` | 4544 |
| `ar_adjustments` | 4557 |
| `dka_sarsurtaxe_ctl_tmp` | 4616 |
| `po_vendors` | 4618 |
| `po_vendorS` | 4684 |
| `po_vendors` | 4707 |
| `PO_VENDORS` | 4789 |
| `dka_sarsurtaxe_ctl_tmp` | 4881 |
| `po_vendor_sites` | 4885 |
| `dka_sarsurtaxe_ctl_tmp` | 4956 |
| `po_vendor_sites` | 4962 |
| `dka_sarsurtaxe_tmp` | 5042 |
| `fnd_flex_value_sets` | 5211 |
| `fnd_concurrent_programs` | 5248 |
| `fnd_user` | 5267 |
| `fnd_concurrent_programs` | 5432 |
| `fnd_responsibility` | 5441 |
| `dka_sarsurtaxe_tmp` | 5458 |
| `gl_ledgers` | 5470 |
| `XLA_LOOKUPS` | 5489 |
| `XLA_LOOKUPS` | 5496 |
| `XLA_LOOKUPS` | 5503 |
| `XLA_LOOKUPS` | 5510 |
| `XLA_LOOKUPS` | 5517 |
| `XLA_LOOKUPS` | 5524 |
| `XLA_LOOKUPS` | 5531 |
| `XLA_LOOKUPS` | 5538 |
| `XLA_LOOKUPS` | 5544 |
| `XLA_LOOKUPS` | 5546 |
| `DUAL` | 5548 |
| `XLA_LOOKUPS` | 5550 |
| `xla_lookups` | 5552 |
| `fnd_application_tl` | 5554 |
| `fnd_application_tl` | 5556 |
| `XLA_LOOKUPS` | 5559 |
| `XLA_LOOKUPS` | 5562 |
| `XLA_LOOKUPS` | 5564 |
| `XLA_LOOKUPS` | 5566 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 121 |
| `Dka_Tools_Pkg.get_parameter` | 123 |
| `Fnd_File.put_line` | 134 |
| `Dka_Tools_Pkg.get_parameter` | 147 |
| `Fnd_File.put_line` | 156 |
| `Dka_Tools_Pkg.get_parameter` | 158 |
| `Fnd_File.put_line` | 167 |
| `Dka_Tools_Pkg.get_parameter` | 169 |
| `Fnd_File.put_line` | 178 |
| `Fnd_Profile.get` | 225 |
| `Fnd_File.put_line` | 226 |
| `Fnd_File.put_line` | 261 |
| `Fnd_File.put_line` | 304 |
| `Fnd_File.put_line` | 342 |
| `Fnd_File.put_line` | 343 |
| `DKA_AR_TOOLS_PKG.issurtaxeaccount` | 445 |
| `Fnd_File.put_line` | 512 |
| `Fnd_File.put_line` | 513 |
| `Fnd_File.put_line` | 578 |
| `Fnd_File.put_line` | 579 |
| `Fnd_Profile.VALUE` | 635 |
| `Pa_Utils.getorgname` | 658 |
| `Fnd_Profile.VALUE` | 658 |
| `DKA_AR_TOOLS_PKG.issurtaxeaccount` | 661 |
| `Fnd_File.put_line` | 890 |
| `Dka_Sarsurtaxe_Pkg.insert_ar_invoices` | 898 |
| `Fnd_File.put_line` | 904 |
| `Fnd_File.put_line` | 906 |
| `Fnd_Profile.VALUE` | 1015 |
| `Fnd_Flex_Ext.breakup_segments` | 1037 |
| `Fnd_Flex_Ext.get_combination_id` | 1043 |
| `Fnd_Flex_Keyval.validate_ccid` | 1061 |
| `Fnd_Flex_Ext.get_segs` | 1077 |
| `Fnd_File.put_line` | 1099 |
| `Fnd_File.put_line` | 1100 |
| `Fnd_File.put_line` | 1302 |
| `Fnd_File.put_line` | 1316 |
| `Fnd_File.put_line` | 1317 |
| `Fnd_File.put_line` | 1374 |
| `Dka_Sarsurtaxe_Pkg.get_segment4` | 1382 |
| `Fnd_File.put_line` | 1386 |
| `Dka_Tools_Pkg.get_code_combination_id` | 1393 |
| `Fnd_File.put_line` | 1394 |
| `Fnd_File.put_line` | 1638 |
| `Fnd_File.put_line` | 1929 |
| `Fnd_File.put_line` | 1932 |
| `Fnd_File.put_line` | 2171 |
| `Fnd_File.put_line` | 2296 |
| `Dka_Sarsurtaxe_Pkg.insert_ap_invoices_interface` | 2300 |
| `Dka_Sarsurtaxe_Pkg.insert_ap_inv_lines_interface` | 2329 |
| `Dka_Sarsurtaxe_Pkg.insert_ap_inv_lines_int_tax` | 2392 |
| `Fnd_File.put_line` | 2413 |
| `Fnd_File.put_line` | 2472 |
| `Dka_Sarsurtaxe_Pkg.load_ap_invoices_interfaces` | 2481 |
| `Fnd_File.put_line` | 2486 |
| `Fnd_File.put_line` | 2512 |
| `Dka_Sarsurtaxe_Pkg.init` | 2514 |
| `Fnd_File.put_line` | 2515 |
| `Dka_Sarsurtaxe_Pkg.purge_dka_sarsurtaxe_tmp` | 2517 |
| `Dka_Sarsurtaxe_Pkg.insert_dka_sarsurtaxe_tmp` | 2519 |
| `Dka_Sarsurtaxe_Pkg.load_data` | 2527 |
| `Fnd_File.put_line` | 2562 |
| `Fnd_File.put_line` | 2617 |
| `Fnd_File.put_line` | 2664 |
| `Fnd_File.put_line` | 2710 |
| `Fnd_File.put_line` | 2722 |
| `Fnd_File.put_line` | 2765 |
| `Fnd_File.put_line` | 2801 |
| `fnd_global.apps_initialize` | 2811 |
| `FND_PROFILE.VALUE` | 2811 |
| `Fnd_File.put_line` | 2814 |
| `fnd_request.submit_request` | 2816 |
| `Fnd_File.put_line` | 2841 |
| `Fnd_File.put_line` | 2843 |
| `Fnd_Concurrent.wait_for_request` | 2846 |
| `Fnd_File.put_line` | 2848 |
| `Fnd_File.put_line` | 2854 |
| `Fnd_File.put_line` | 2860 |
| `Fnd_File.put_line` | 2894 |
| `Dka_Sarsurtaxe_Pkg.init` | 2896 |
| `Dka_Sarsurtaxe_Pkg.update_after_import_ap` | 2898 |
| `Dka_Sarsurtaxe_Pkg.update_ra_cust_trx_line_gl_dis` | 2901 |
| `Dka_Sarsurtaxe_Pkg.update_gl_je_lines_cuf` | 2904 |
| `Fnd_File.put_line` | 2947 |
| `Fnd_File.put_line` | 2948 |
| `Fnd_File.put_line` | 2949 |
| `Fnd_File.put_line` | 3068 |
| `Fnd_File.put_line` | 3076 |
| `Dka_Sarsurtaxe_Pkg.get_segment4` | 3085 |
| `Fnd_File.put_line` | 3089 |
| `Dka_Tools_Pkg.get_code_combination_id` | 3095 |
| `Fnd_File.put_line` | 3112 |
| `Fnd_File.put_line` | 3158 |
| `Fnd_File.put_line` | 3163 |
| `Fnd_File.put_line` | 3166 |
| `Dka_Sarsurtaxe_Pkg.update_gl_je_lines` | 3169 |
| `Fnd_File.put_line` | 3176 |
| `Fnd_File.put_line` | 3184 |
| `Dka_Sarsurtaxe_Pkg.get_segment4` | 3197 |
| `Fnd_File.put_line` | 3200 |
| `Dka_Tools_Pkg.get_code_combination_id` | 3206 |
| `Fnd_File.put_line` | 3223 |
| `Fnd_File.put_line` | 3269 |
| `Dka_Sarsurtaxe_Pkg.load_ref_let` | 3278 |
| `Fnd_File.put_line` | 3326 |
| `Fnd_File.put_line` | 3327 |
| `Fnd_File.put_line` | 3334 |
| `Fnd_File.put_line` | 3388 |
| `Fnd_File.put_line` | 3389 |
| `Fnd_File.put_line` | 3998 |
| `fnd_profile.VALUE` | 4010 |
| `Fnd_File.put_line` | 4106 |
| `fnd_global.apps_initialize` | 4116 |
| `FND_PROFILE.VALUE` | 4116 |
| `Fnd_File.put_line` | 4118 |
| `fnd_request.submit_request` | 4121 |
| `FND_PROFILE.value` | 4127 |
| `Fnd_File.put_line` | 4144 |
| `Fnd_File.put_line` | 4146 |
| `Fnd_Concurrent.wait_for_request` | 4149 |
| `Fnd_File.put_line` | 4151 |
| `Fnd_File.put_line` | 4157 |
| `Fnd_File.put_line` | 4163 |
| `Fnd_File.put_line` | 4211 |
| `Fnd_File.put_line` | 4216 |
| `fnd_global.apps_initialize` | 4225 |
| `FND_PROFILE.VALUE` | 4225 |
| `Dka_Sarsurtaxe_Pkg.init` | 4233 |
| `Dka_Sarsurtaxe_Pkg.insert_gl_interface_control` | 4237 |
| `Dka_Sarsurtaxe_Pkg.insert_gl_interface` | 4238 |
| `Fnd_File.put_line` | 4239 |
| `Fnd_File.put_line` | 4241 |
| `Fnd_File.put_line` | 4258 |
| `fnd_global.apps_initialize` | 4268 |
| `FND_PROFILE.VALUE` | 4268 |
| `Fnd_Request.submit_request` | 4270 |
| `FND_PROFILE.value` | 4277 |
| `Fnd_File.put_line` | 4291 |
| `Fnd_File.put_line` | 4295 |
| `Fnd_File.put_line` | 4296 |
| `Fnd_Concurrent.wait_for_request` | 4298 |
| `Fnd_File.put_line` | 4300 |
| `Fnd_File.put_line` | 4306 |
| `Fnd_File.put_line` | 4310 |
| `Fnd_File.put_line` | 4317 |
| `Fnd_File.put_line` | 4337 |
| `fnd_request.submit_request` | 4355 |
| `FND_PROFILE.value` | 4361 |
| `Fnd_File.put_line` | 4369 |
| `Fnd_File.put_line` | 4371 |
| `Fnd_Concurrent.wait_for_request` | 4374 |
| `Fnd_File.put_line` | 4376 |
| `Fnd_File.put_line` | 4382 |
| `Fnd_File.put_line` | 4463 |
| `Dka_Sarsurtaxe_Pkg.update_dka_sarsurtaxe_tmp` | 4468 |
| `Fnd_File.put_line` | 4470 |
| `Dka_Tools_Pkg.put_debug_message` | 4498 |
| `Dka_Tools_Pkg.put_debug_message` | 4499 |
| `DKA_AR_TOOLS_PKG.issurtaxeaccount` | 4574 |
| `Dka_Tools_Pkg.put_debug_message` | 4581 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4634 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4640 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4645 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4646 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4652 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4722 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4729 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4737 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4744 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4750 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4751 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4757 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4806 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4812 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4813 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4817 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4904 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4910 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4916 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4917 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4922 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4988 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4995 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5001 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5002 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5007 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5066 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5068 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5083 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5101 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5137 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5142 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5143 |
| `Dka_Sarsurtaxe_Pkg.insert_dka_sarsurtaxe_ctl_tmp` | 5147 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5150 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5152 |
| `Dka_Sarsurtaxe_Pkg.controle_fournisseur_absent` | 5154 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5156 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5157 |
| `Dka_Sarsurtaxe_Pkg.controle_fournisseur_doublon` | 5159 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5161 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5162 |
| `Dka_Sarsurtaxe_Pkg.CTR_FOURNISSEUR_DOUBLON_TMP` | 5164 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5166 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5167 |
| `Dka_Sarsurtaxe_Pkg.controle_site_frs_absent` | 5169 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5171 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5172 |
| `Dka_Sarsurtaxe_Pkg.controle_facture_negative` | 5174 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5177 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5178 |
| `Dka_Sarsurtaxe_Pkg.bilan_surtaxe` | 5180 |
| `Fnd_File.put_line` | 5183 |
| `Fnd_File.put_line` | 5184 |
| `Fnd_File.put_line` | 5185 |
| `Fnd_File.put_line` | 5186 |
| `fnd_global.resp_id` | 5234 |
| `fnd_global.resp_appl_id` | 5235 |
| `fnd_global.apps_initialize` | 5272 |
| `Fnd_Profile.VALUE` | 5274 |
| `fnd_request.set_print_options` | 5278 |
| `Fnd_File.put_line` | 5282 |
| `Fnd_File.put_line` | 5284 |
| `Fnd_File.put_line` | 5289 |
| `Fnd_Request.submit_request` | 5290 |
| `Fnd_File.put_line` | 5302 |
| `Fnd_File.put_line` | 5304 |
| `dka_tools_pkg.put_debug_message` | 5424 |
| `fnd_global.apps_initialize` | 5448 |
| `dka_tools_pkg.put_debug_message` | 5452 |
| `dka_tools_pkg.put_debug_message` | 5466 |
| `dka_tools_pkg.put_debug_message` | 5476 |
| `dka_tools_pkg.put_debug_message` | 5483 |
| `fnd_profile.value` | 5554 |
| `fnd_profile.value` | 5556 |
| `fnd_profile.value` | 5570 |
| `fnd_profile.value` | 5571 |
| `Fnd_File.put_line` | 5599 |
| `FND_REQUEST.add_layout` | 5602 |
| `fnd_request.submit_request` | 5610 |
| `dka_tools_pkg.put_debug_message` | 5664 |
| `dka_tools_pkg.put_debug_message` | 5674 |
| `fnd_concurrent.wait_for_request` | 5688 |
| `dka_tools_pkg.put_outdebug_message` | 5696 |
| `dka_tools_pkg.put_debug_message` | 5700 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `APPRVL` | 2816 |
| `GLXRCAUT` | 4121 |
| `GLLEZL` | 4270 |
| `GLPAUTOP` | 4355 |
| `DKA_SARSURTAXE_RDF` | 5290 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 2844, 4147, 4294, 4307, 4372, 5299, 5681 |
| when_others | 228, 275, 309, 548, 707, 1305, 1886, 2175, 2415, 2587, 2633, 2682, 2724, 2863, 3011, 3240, 3360, 3945, 4166, 4392, 4437, 4584, 5252, 5712 |
| suppression | 306, 2713, 2718 |
| soumission | 2816, 4121, 4270, 4355, 5290, 5610 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_APPRVL / DKA | `dka_sarsurtaxe_pkg.launch_apprvl` | dka/12.0.0/admin/import/DKA_APPRVL.prt:419 |
| DKA_GLXRCAUT / DKA | `dka_sarsurtaxe_pkg.launch_glxrcaut` | dka/12.0.0/admin/import/DKA_GLXRCAUT.prt:419 |
| DKA_POSTMAN / DKA | `dka_sarsurtaxe_pkg.launch_xlaaccpb` | dka/12.0.0/admin/import/DKA_POSTMAN.prt:419 |
| DKA_SARSURTAXE_1 / DKA | `dka_sarsurtaxe_pkg.main` | dka/12.0.0/admin/import/DKA_SARSURTAXE_1.prt:404 |
| DKA_SARSURTAXE_2 / DKA | `dka_sarsurtaxe_pkg.main2` | dka/12.0.0/admin/import/DKA_SARSURTAXE_2.prt:404 |
| DKA_SARSURTAXE_3 / DKA | `dka_sarsurtaxe_pkg.main3` | dka/12.0.0/admin/import/DKA_SARSURTAXE_3.prt:403 |
| DKA_SARSURTAXE_4 / DKA | `dka_sarsurtaxe_pkg.main4` | dka/12.0.0/admin/import/DKA_SARSURTAXE_4.prt:404 |
| DKA_SARSURTAXE_5 / DKA | `dka_sarsurtaxe_pkg.main5` | dka/12.0.0/admin/import/DKA_SARSURTAXE_5.prt:404 |
| DKA_SARSURTAXE_6 / DKA | `dka_sarsurtaxe_pkg.main6` | dka/12.0.0/admin/import/DKA_SARSURTAXE_6.prt:420 |
| DKA_SARSURTAXE_7 / DKA | `dka_sarsurtaxe_pkg.main7` | dka/12.0.0/admin/import/DKA_SARSURTAXE_7.prt:438 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
