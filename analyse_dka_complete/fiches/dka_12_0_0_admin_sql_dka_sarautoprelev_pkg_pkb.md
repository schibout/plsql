# DKA_SARAUTOPRELEV_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARAUTOPRELEV_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARAUTOPRELEV_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3361 ; encodage : utf-8. SHA-256 : `bc623d1364ac823b54f7bc57a5c9f9c9da2db4a384d07eba537fe5855c189915`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `delete_save_tables` | 86 |
| `is_date` | 104 |
| `init_params` | 177 |
| `get_printer_name` | 570 |
| `create_remit` | 939 |
| `create_remit_express` | 1078 |
| `INSERT_PRELEV` | 1338 |
| `INSERT_PRELEV_EXP` | 1623 |
| `CREATE_DDIMPORT` | 1902 |
| `MAIN` | 2544 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_tables` | 90 |
| `dual` | 114 |
| `fnd_user` | 585 |
| `dka_sarautoprelev_tmp` | 1350 |
| `fnd_conc_req_summary_v` | 1361 |
| `dka_sarautoprelev_tmp` | 1373 |
| `ar_remitted_receipts_format_v` | 1519 |
| `dka_sarautoprelev_tmp` | 1589 |
| `dka_sarautoprelev_tmp` | 1635 |
| `fnd_conc_req_summary_v` | 1646 |
| `dka_sarautoprelev_tmp` | 1658 |
| `ar_remitted_receipts_format_v` | 1804 |
| `dka_sarautoprelev_tmp` | 1869 |
| `dka_sarautoprelev_tmp` | 1971 |
| `fnd_lookup_values_vl` | 2026 |
| `DKA_SARAUTOPRELEV_STAT` | 2096 |
| `fnd_flex_value_sets` | 2104 |
| `fnd_flex_value_sets` | 2116 |
| `ar_payment_schedules_all` | 2232 |
| `to_char` | 2253 |
| `ar_cash_receipts` | 2350 |
| `DKA_SARAUTOPRELEV_TMP` | 2354 |
| `to_char` | 2379 |
| `ar_cash_receipts` | 2475 |
| `DKA_SARAUTOPRELEV_TMP` | 2509 |
| `fnd_flex_value_sets` | 2552 |
| `fnd_flex_values` | 2553 |
| `hr_operating_units` | 2554 |
| `gl_ledgers` | 2555 |
| `gl_access_set_assignments` | 2556 |
| `ar_cash_receipts` | 2611 |
| `ar_payment_schedules` | 2612 |
| `ar_cash_receipt_history` | 2613 |
| `ar_receipt_methods` | 2614 |
| `ar_receipt_classes` | 2615 |
| `ar_receipt_method_accounts_all` | 2616 |
| `ce_bank_acct_uses` | 2617 |
| `ce_bank_accounts` | 2618 |
| `ce_bank_branches_v` | 2619 |
| `ar_lookups` | 2634 |
| `ar_cash_receipts` | 2660 |
| `ar_payment_schedules` | 2661 |
| `ar_cash_receipt_history` | 2662 |
| `ar_receipt_methods` | 2663 |
| `ar_receipt_classes` | 2664 |
| `ar_receipt_method_accounts_all` | 2665 |
| `ce_bank_acct_uses` | 2666 |
| `ce_bank_accounts` | 2667 |
| `ce_bank_branches_v` | 2668 |
| `ar_lookups` | 2683 |
| `DKA.DKA_SARAUTOPRELEV_TMP` | 2803 |
| `DKA.DKA_SARAUTOPRELEV_EXP_STAT` | 2816 |
| `gl_period_statuses` | 2864 |
| `fnd_concurrent_programs` | 2885 |
| `DKA_SARAUTOPRELEV_STAT` | 2897 |
| `ar_payment_schedules_all` | 2936 |
| `ar_payment_schedules_all` | 2948 |
| `ar_payment_schedules_all` | 2992 |
| `fnd_concurrent_requests` | 3010 |
| `fnd_concurrent_programs` | 3011 |
| `DUAL` | 3048 |
| `DKA_SARAUTOPRELEV_EXP_STAT` | 3056 |
| `ar_payment_schedules_all` | 3079 |
| `fnd_concurrent_requests` | 3134 |
| `fnd_concurrent_programs` | 3135 |
| `ar_payment_schedules_all` | 3167 |
| `DKA_SARAUTOPRELEV_EXP_STAT` | 3170 |
| `fnd_concurrent_requests` | 3308 |
| `fnd_concurrent_programs` | 3309 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_log_message` | 159 |
| `dka_tools_pkg.get_parameter` | 182 |
| `Dka_Stransco_Pkg.etl_get_value_f` | 576 |
| `Fnd_Profile.value_specific` | 593 |
| `po_moac_utils_pvt.set_org_context` | 962 |
| `fnd_request.set_org_id` | 965 |
| `fnd_request.submit_request` | 968 |
| `fnd_date.date_to_canonical` | 974 |
| `fnd_date.date_to_canonical` | 995 |
| `fnd_date.date_to_canonical` | 996 |
| `DKA_TOOLS_PKG.put_log_message` | 1016 |
| `DKA_TOOLS_PKG.put_log_message` | 1022 |
| `DKA_TOOLS_PKG.put_log_message` | 1025 |
| `fnd_concurrent.wait_for_request` | 1031 |
| `DKA_TOOLS_PKG.put_log_message` | 1043 |
| `DKA_TOOLS_PKG.put_log_message` | 1047 |
| `DKA_TOOLS_PKG.put_log_message` | 1058 |
| `po_moac_utils_pvt.set_org_context` | 1102 |
| `fnd_request.set_org_id` | 1105 |
| `fnd_request.submit_request` | 1108 |
| `fnd_date.date_to_canonical` | 1114 |
| `fnd_date.date_to_canonical` | 1135 |
| `fnd_date.date_to_canonical` | 1136 |
| `DKA_TOOLS_PKG.put_log_message` | 1156 |
| `DKA_TOOLS_PKG.put_log_message` | 1162 |
| `DKA_TOOLS_PKG.put_log_message` | 1165 |
| `fnd_concurrent.wait_for_request` | 1171 |
| `DKA_TOOLS_PKG.put_log_message` | 1183 |
| `DKA_TOOLS_PKG.put_log_message` | 1187 |
| `DKA_TOOLS_PKG.put_log_message` | 1198 |
| `DKA_TOOLS_PKG.put_log_message` | 1353 |
| `dka_tools_pkg.get_message` | 1476 |
| `dka_tools_pkg.get_message` | 1481 |
| `DKA_TOOLS_PKG.put_log_message` | 1598 |
| `DKA_TOOLS_PKG.put_log_message` | 1599 |
| `DKA_TOOLS_PKG.put_log_message` | 1604 |
| `DKA_TOOLS_PKG.put_log_message` | 1638 |
| `dka_tools_pkg.get_message` | 1761 |
| `dka_tools_pkg.get_message` | 1766 |
| `DKA_TOOLS_PKG.put_log_message` | 1878 |
| `DKA_TOOLS_PKG.put_log_message` | 1879 |
| `DKA_TOOLS_PKG.put_log_message` | 1884 |
| `dka_tools_pkg.put_debug_message` | 2039 |
| `dka_tools_pkg.put_debug_message` | 2086 |
| `dka_tools_pkg.put_debug_message` | 2090 |
| `fnd_date.canonical_to_date` | 2127 |
| `dka_tools_pkg.put_debug_message` | 2130 |
| `Dka_Tools_Pkg.Get_Next_Working_Day` | 2135 |
| `Dka_Tools_Pkg.Get_Next_Working_Day` | 2140 |
| `dka_tools_pkg.put_debug_message` | 2143 |
| `dka_tools_pkg.put_debug_message` | 2145 |
| `dka_tools_pkg.put_debug_message` | 2159 |
| `dka_tools_pkg.put_debug_message` | 2173 |
| `dka_tools_pkg.put_debug_message` | 2183 |
| `dka_tools_pkg.put_debug_message` | 2186 |
| `dka_tools_pkg.put_debug_message` | 2202 |
| `dka_tools_pkg.put_debug_message` | 2216 |
| `dka_tools_pkg.put_debug_message` | 2221 |
| `Dka_Tools_Pkg.Get_Next_Working_Day` | 2236 |
| `dka_tools_pkg.put_debug_message` | 2239 |
| `dka_tools_pkg.put_debug_message` | 2241 |
| `dka_tools_pkg.put_debug_message` | 2484 |
| `dka_tools_pkg.put_debug_message` | 2493 |
| `dka_tools_pkg.put_debug_message` | 2496 |
| `dka_tools_pkg.put_debug_message` | 2504 |
| `dka_tools_pkg.put_debug_message` | 2507 |
| `dka_tools_pkg.put_debug_message` | 2516 |
| `dka_tools_pkg.put_debug_message` | 2523 |
| `DKA_TOOLS_PKG.put_log_message` | 2529 |
| `Fnd_Profile.VALUE` | 2562 |
| `Dka_Tools_Pkg.put_log_message` | 2794 |
| `Dka_Tools_Pkg.put_log_message` | 2799 |
| `Dka_Tools_Pkg.put_log_message` | 2812 |
| `DKA_TOOLS_PKG.put_log_message` | 2832 |
| `DKA_AR_TOOLS_PKG.alim_corresp_operations` | 2834 |
| `DKA_TOOLS_PKG.put_log_message` | 2837 |
| `fnd_date.date_to_canonical` | 2845 |
| `DKA_TOOLS_PKG.put_log_message` | 2851 |
| `po_moac_utils_pvt.set_org_context` | 2853 |
| `fnd_request.set_org_id` | 2858 |
| `DKA_TOOLS_PKG.put_log_message` | 2860 |
| `DKA_TOOLS_PKG.put_log_message` | 2874 |
| `DKA_TOOLS_PKG.put_log_message` | 2891 |
| `DKA_TOOLS_PKG.put_log_message` | 2907 |
| `fnd_request.set_print_options` | 2914 |
| `dka_tools_pkg.put_log_message` | 2917 |
| `dka_tools_pkg.put_debug_message` | 2919 |
| `dka_tools_pkg.put_debug_message` | 2920 |
| `dka_tools_pkg.put_debug_message` | 2921 |
| `dka_tools_pkg.put_debug_message` | 2925 |
| `DKA_TOOLS_PKG.put_log_message` | 2927 |
| `DKA_TOOLS_PKG.put_log_message` | 2932 |
| `DKA_TOOLS_PKG.put_log_message` | 2942 |
| `DKA_TOOLS_PKG.put_log_message` | 2953 |
| `dka_tools_pkg.put_log_message` | 2959 |
| `DKA_TOOLS_PKG.put_log_message` | 2964 |
| `DKA_TOOLS_PKG.put_log_message` | 2980 |
| `dka_tools_pkg.put_log_message` | 2983 |
| `dka_tools_pkg.put_log_message` | 2984 |
| `DKA_TOOLS_PKG.put_log_message` | 2988 |
| `DKA_TOOLS_PKG.put_log_message` | 3000 |
| `DKA_TOOLS_PKG.put_log_message` | 3005 |
| `DKA_TOOLS_PKG.put_log_message` | 3016 |
| `DKA_TOOLS_PKG.put_log_message` | 3024 |
| `dka_tools_pkg.put_log_message` | 3033 |
| `dka_tools_pkg.put_log_message` | 3034 |
| `DKA_TOOLS_PKG.put_log_message` | 3040 |
| `DKA_TOOLS_PKG.put_log_message` | 3050 |
| `DKA_TOOLS_PKG.put_log_message` | 3054 |
| `DKA_TOOLS_PKG.put_log_message` | 3077 |
| `DKA_TOOLS_PKG.put_log_message` | 3083 |
| `DKA_TOOLS_PKG.put_log_message` | 3086 |
| `DKA_TOOLS_PKG.put_log_message` | 3095 |
| `fnd_request.set_print_options` | 3102 |
| `dka_tools_pkg.put_log_message` | 3105 |
| `DKA_TOOLS_PKG.put_log_message` | 3109 |
| `DKA_TOOLS_PKG.put_log_message` | 3123 |
| `dka_tools_pkg.put_log_message` | 3126 |
| `dka_tools_pkg.put_log_message` | 3127 |
| `DKA_TOOLS_PKG.put_log_message` | 3140 |
| `DKA_TOOLS_PKG.put_log_message` | 3147 |
| `dka_tools_pkg.put_log_message` | 3156 |
| `dka_tools_pkg.put_log_message` | 3157 |
| `DKA_TOOLS_PKG.put_log_message` | 3164 |
| `DKA_TOOLS_PKG.put_log_message` | 3177 |
| `dka_tools_pkg.put_log_message` | 3181 |
| `DKA_TOOLS_PKG.put_log_message` | 3186 |
| `DKA_TOOLS_PKG.put_log_message` | 3195 |
| `DKA_TOOLS_PKG.put_log_message` | 3202 |
| `dka_tools_pkg.put_log_message` | 3207 |
| `fnd_request.submit_request` | 3208 |
| `DKA_TOOLS_PKG.put_log_message` | 3232 |
| `dka_tools_pkg.put_log_message` | 3236 |
| `dka_tools_pkg.put_log_message` | 3240 |
| `fnd_concurrent.wait_for_request` | 3241 |
| `dka_tools_pkg.put_log_message` | 3250 |
| `dka_tools_pkg.put_log_message` | 3253 |
| `Dka_Tools_Pkg.GET_NEXT_WORKING_DAY` | 3258 |
| `DKA_TOOLS_PKG.put_log_message` | 3262 |
| `dka_tools_pkg.put_log_message` | 3264 |
| `FND_REQUEST.SUBMIT_REQUEST` | 3265 |
| `fnd_date.date_to_canonical` | 3270 |
| `dka_tools_pkg.put_log_message` | 3273 |
| `DKA_TOOLS_PKG.put_log_message` | 3275 |
| `dka_tools_pkg.put_log_message` | 3277 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 3279 |
| `dka_tools_pkg.put_log_message` | 3287 |
| `dka_tools_pkg.put_log_message` | 3290 |
| `Dka_Stransco_Pkg.etl_get_value_f` | 3294 |
| `fnd_request.submit_request` | 3319 |
| `dka_tools_pkg.put_log_message` | 3329 |
| `fnd_request.submit_request` | 3330 |
| `DKA_TOOLS_PKG.put_log_message` | 3345 |
| `DKA_TOOLS_PKG.put_log_message` | 3352 |
| `DKA_TOOLS_PKG.put_log_message` | 3356 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `IBY_FC_CREATE_SETTLE_BATCHES` | 3208 |
| `DKA_CREATE_DDIMPORT_FILE` | 3265 |
| `FNDREPRINT` | 3319 |
| `FNDREPRINT` | 3330 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1017, 1157, 2362, 2940, 2996, 3087, 3175, 3239, 3276 |
| when_others | 117, 589, 1054, 1194, 1601, 1881, 2526, 2958, 3032, 3155, 3180, 3314, 3353 |
| truncate | 2808, 2821 |
| soumission | 968, 1108, 3208, 3265, 3319, 3330 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_CREATE_DDIMPORT_FILE / DKA | `DKA_SARAUTOPRELEV_PKG.CREATE_DDIMPORT` | dka/12.0.0/admin/import/DKA_CREATE_DDIMPORT_FILE_F.prt:458 |
| DKA_CREATE_DDIMPORT_FILE / DKA | `DKA_SARAUTOPRELEV_PKG.CREATE_DDIMPORT` | dka/12.0.0/admin/import/DKA_CREATE_DDIMPORT_FILE_F.prt:458 |
| DKA_CREATE_DDIMPORT_FILE / DKA | `DKA_SARAUTOPRELEV_PKG.CREATE_DDIMPORT` | dka/12.0.0/admin/import/DKA_CREATE_DDIMPORT_FILE_US.prt:458 |
| DKA_CREATE_DDIMPORT_FILE / DKA | `DKA_SARAUTOPRELEV_PKG.CREATE_DDIMPORT` | dka/12.0.0/admin/import/DKA_CREATE_DDIMPORT_FILE_US.prt:458 |
| DKA_SARAUTOPRELEV / DKA | `DKA_SARAUTOPRELEV_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARAUTOPRELEV_F.prt:460 |
| DKA_SARAUTOPRELEV / DKA | `DKA_SARAUTOPRELEV_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARAUTOPRELEV_F.prt:460 |
| DKA_SARAUTOPRELEV / DKA | `DKA_SARAUTOPRELEV_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARAUTOPRELEV_US.prt:460 |
| DKA_SARAUTOPRELEV / DKA | `DKA_SARAUTOPRELEV_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SARAUTOPRELEV_US.prt:460 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
