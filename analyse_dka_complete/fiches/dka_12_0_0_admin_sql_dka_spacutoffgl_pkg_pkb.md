# DKA_SPACUTOFFGL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPACUTOFFGL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPACUTOFFGL_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3423 ; encodage : cp1252 (repli). SHA-256 : `317d7bf1a8700be8d060bf78adc8d43f644c85b00479382e489b30a1c9ababbb`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `put_line_log` | 138 |
| `put_line_out` | 153 |
| `get_param_varchar` | 168 |
| `init` | 199 |
| `get_account_info` | 319 |
| `get_je_category_info` | 390 |
| `get_project_info` | 414 |
| `get_expenditure_type_info` | 468 |
| `check_exist_event_type` | 504 |
| `get_calc_segment1_f` | 577 |
| `get_calc_segment2_f` | 602 |
| `get_calc_segment3_f` | 640 |
| `get_calc_segment4_f` | 790 |
| `get_calc_segment5_f` | 927 |
| `get_calc_segment6_f` | 950 |
| `get_calc_segment7_f` | 976 |
| `get_calc_segment8_f` | 1009 |
| `get_calc_segment9_f` | 1037 |
| `get_calc_segment10_f` | 1060 |
| `get_calc_segment11_f` | 1084 |
| `get_calc_segment12_f` | 1108 |
| `get_task_id_f` | 1130 |
| `get_task_id` | 1159 |
| `get_contrep_ccid_f` | 1188 |
| `get_org_id_f` | 1315 |
| `get_burden_cost_f` | 1341 |
| `ins_pa_expend_groups` | 1395 |
| `ins_pa_expenditures` | 1466 |
| `ins_pa_expend_items` | 1534 |
| `ins_pa_cost_distrib_lines` | 1748 |
| `controler_line_gl` | 1890 |
| `get_context_cuf` | 2643 |
| `transfer_from_gl_to_pa` | 2768 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_values_vl` | 335 |
| `fa_categories_vl` | 342 |
| `fa_book_controls_sec` | 345 |
| `fnd_flex_value_sets` | 360 |
| `gl_je_categories` | 398 |
| `pa_projects_all` | 433 |
| `pa_expenditure_types` | 477 |
| `pa_event_types` | 513 |
| `pa_tasks` | 1140 |
| `pa_tasks` | 1169 |
| `gl_code_combinations` | 1224 |
| `gl_code_combinations` | 1243 |
| `gl_sets_of_books` | 1293 |
| `dual` | 1298 |
| `hr_all_organization_units` | 1324 |
| `pa_expenditure_groups_all` | 1409 |
| `pa_expenditure_groups_all` | 1415 |
| `DUAL` | 1478 |
| `pa_expenditures_all` | 1479 |
| `DUAL` | 1558 |
| `pa_expenditure_items_all` | 1559 |
| `pa_expenditure_comments` | 1704 |
| `gl_periods` | 1769 |
| `pa_cost_distribution_lines_all` | 1774 |
| `fnd_flex_values_vl` | 2684 |
| `gl_je_headers` | 2852 |
| `gl_period_statuses` | 2860 |
| `fa_categories_vl` | 2888 |
| `fa_book_controls_sec` | 2890 |
| `GL_ACCESS_SET_LEDGERS` | 2925 |
| `gl_period_statuses` | 2967 |
| `gl_period_statuses` | 2969 |
| `gl_je_lines` | 3050 |
| `GL_DAILY_RATES` | 3134 |
| `GL_DAILY_RATES` | 3228 |
| `gl_je_lines` | 3279 |
| `gl_je_lines` | 3280 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 143 |
| `Fnd_File.put_line` | 158 |
| `Dka_Tools_Pkg.get_parameter` | 176 |
| `Dka_Tools_Pkg.get_flex_key_seg_value_set` | 223 |
| `Dka_Tools_Pkg.get_parameter` | 240 |
| `Dka_Tools_Pkg.get_parameter` | 290 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 373 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 451 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 487 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 523 |
| `dka_spaautoaccounting_pkg.uo_projet` | 622 |
| `dka_spaautoaccounting_pkg.CPT_LOCAL_COUTS` | 668 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 730 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 754 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 763 |
| `Dka_Spaautoaccounting_Pkg.run_cpt_groupe_couts_f` | 809 |
| `Dka_Spaautoaccounting_Pkg.run_cpt_groupe_produit_f` | 884 |
| `Dka_Spaautoaccounting_Pkg.centrefi` | 959 |
| `Dka_Spaautoaccounting_Pkg.affaire` | 991 |
| `Dka_Spaautoaccounting_Pkg.PROJETFI` | 1019 |
| `Fnd_Profile.put` | 1358 |
| `Fnd_Client_Info.set_org_context` | 1359 |
| `Pa_Cost_Plus1.view_indirect_cost` | 1363 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2009 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2028 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2062 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2069 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2081 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 2145 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2151 |
| `Dka_Gl_Tools_Pkg.gl_get_category_autorev_flag` | 2156 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2176 |
| `Dka_Sarrefac_Pkg.is_transaction_type_refac` | 2185 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2189 |
| `Dka_Sarrefac_Pkg.is_transaction_type_refac` | 2198 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2202 |
| `Dka_Pa_Tools_Pkg.pa_get_code_z_refac` | 2223 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2235 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2250 |
| `DKA_PA_TOOLS_PKG.pa_check_transaction_data` | 2267 |
| `DKA_PA_TOOLS_PKG.pa_check_transaction_data` | 2289 |
| `Dka_Gl_Tools_Pkg.gl_get_category_autorev_flag` | 2307 |
| `DKA_PA_TOOLS_PKG.pa_check_transaction_data` | 2325 |
| `DKA_PA_TOOLS_PKG.pa_check_transaction_data` | 2351 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2385 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2400 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2423 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2447 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2460 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2473 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2486 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2499 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2513 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2527 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2542 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 2556 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2591 |
| `Dka_Tools_Pkg.get_flex_key_seg_value_set` | 2698 |
| `fnd_profile.VALUE` | 2922 |
| `DKA_GL_TOOLS_PKG.period_gl_to_close` | 2936 |
| `fnd_profile.VALUE` | 2971 |
| `Dka_Tools_Pkg.put_debug_message` | 3029 |
| `Dka_Tools_Pkg.put_debug_message` | 3032 |
| `fnd_number.canonical_to_number` | 3048 |
| `Dka_Tools_Pkg.GET_MESSAGE` | 3077 |
| `Dka_Tools_Pkg.put_debug_message` | 3088 |
| `Dka_Tools_Pkg.put_debug_message` | 3121 |
| `Dka_Tools_Pkg.put_debug_message` | 3143 |
| `Dka_Tools_Pkg.put_debug_message` | 3151 |
| `Dka_Tools_Pkg.put_debug_message` | 3160 |
| `Dka_Tools_Pkg.put_debug_message` | 3170 |
| `Dka_Tools_Pkg.put_debug_message` | 3192 |
| `Dka_Tools_Pkg.put_debug_message` | 3213 |
| `Dka_Tools_Pkg.put_debug_message` | 3237 |
| `DKA_PA_TOOLS_PKG.pa_insert_event` | 3245 |
| `Dka_Tools_Pkg.put_debug_message` | 3279 |
| `Dka_Tools_Pkg.put_debug_message` | 3309 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 3385 |
| rollback | 3313, 3335, 3357, 3411, 3416 |
| when_others | 145, 160, 189, 309, 380, 404, 458, 494, 530, 589, 630, 779, 916, 939, 965, 998, 1026, 1049, 1072, 1096, 1120, 1148, 1177, 1305, 1331, 1385, 1456, 1524, 1738, 1867, 2625, 2750, 2980, 3141, 3235, 3355, 3414 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPACUTOFF_TRANSFER / DKA | `DKA_SPACUTOFFGL_PKG.transfer_from_gl_to_pa` | dka/12.0.0/admin/import/DKA_SPACUTOFF_TRANSFER.prt:420 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
