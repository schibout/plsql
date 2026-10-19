# DKA_SARFACMAN_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARFACMAN_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARFACMAN_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3142 ; encodage : cp1252 (repli). SHA-256 : `9d246582331ae5f5373a65545695e4b7e346e5a0f45f8207c6fafc7d2685d25f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_select_record_group` | 89 |
| `init` | 128 |
| `get_acct_combination` | 355 |
| `events_status_rejection` | 807 |
| `events_type_rejection` | 865 |
| `purge_sarfacman_tmp` | 910 |
| `insert_sarfacman_tmp` | 944 |
| `get_societe` | 1077 |
| `create_output` | 1122 |
| `get_code_saisie` | 1259 |
| `get_attribute_category` | 1299 |
| `amount_sign` | 1389 |
| `get_code_partenaire` | 1433 |
| `get_code_partenaire_desc` | 1497 |
| `get_dr_code_combination_id` | 1538 |
| `get_burden_cost_f` | 1670 |
| `get_task_id_f` | 1721 |
| `get_org_id_f` | 1751 |
| `ins_pa_expend_groups` | 1779 |
| `ins_pa_expenditures` | 1852 |
| `ins_pa_expend_items` | 1921 |
| `ins_pa_cost_distrib_lines` | 2131 |
| `insert_pa_events` | 2276 |
| `insert_pa_expenditures` | 2494 |
| `get_data_for_refaccuf` | 2762 |
| `main` | 3055 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dual` | 448 |
| `pa_segment_rule_pairings` | 508 |
| `pa_segment_rule_pairings_all` | 639 |
| `pa_segment_rule_pairings_all` | 667 |
| `pa_segment_rule_pairings_all` | 694 |
| `pa_projects_all` | 831 |
| `pa_event_types` | 882 |
| `dka_sarfacman_tmp` | 955 |
| `ra_customer_trx_all` | 1015 |
| `FND_CURRENCIES` | 1037 |
| `pa_projects_all` | 1092 |
| `dka_sarfacman_tmp` | 1145 |
| `fnd_flex_values` | 1340 |
| `hz_cust_accounts` | 1457 |
| `gl_sets_of_books` | 1506 |
| `gl_code_combinations` | 1582 |
| `dual` | 1600 |
| `gl_code_combinations` | 1603 |
| `gl_ledgers` | 1649 |
| `HR_OPERATING_UNITS` | 1650 |
| `pa_tasks` | 1731 |
| `hr_all_organization_units` | 1760 |
| `pa_expenditure_groups_all` | 1792 |
| `pa_expenditure_groups_all` | 1800 |
| `DUAL` | 1863 |
| `pa_expenditures_all` | 1865 |
| `DUAL` | 1942 |
| `pa_expenditure_items_all` | 1944 |
| `pa_expenditure_comments` | 2086 |
| `HR_OPERATING_UNITS` | 2151 |
| `gl_periods` | 2157 |
| `pa_cost_distribution_lines_all` | 2162 |
| `dka_sarfacman_tmp` | 2316 |
| `dka_sarfacman_tmp` | 2407 |
| `ra_cust_trx_line_gl_dist_all` | 2412 |
| `dka_sarfacman_tmp` | 2437 |
| `dka_sarfacman_tmp` | 2457 |
| `dka_sarfacman_tmp` | 2534 |
| `dka_sarfacman_tmp` | 2671 |
| `ra_cust_trx_line_gl_dist_all` | 2676 |
| `dka_sarfacman_tmp` | 2701 |
| `dka_sarfacman_tmp` | 2722 |
| `pa_projects_all` | 2834 |
| `hr_operating_units` | 2861 |
| `HR_OPERATING_UNITS` | 2879 |
| `fnd_flex_values` | 2911 |
| `pa_projects_all` | 2932 |
| `pa_tasks` | 2944 |
| `DUAL` | 2962 |
| `DUAL` | 2974 |
| `DUAL` | 2975 |
| `DUAL` | 2979 |
| `DUAL` | 2980 |
| `DUAL` | 2983 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_debug_message` | 137 |
| `FND_PROFILE.VALUE` | 138 |
| `Dka_Tools_Pkg.get_parameter` | 141 |
| `Dka_Tools_Pkg.get_parameter` | 150 |
| `Dka_Tools_Pkg.get_parameter` | 159 |
| `Dka_Tools_Pkg.get_parameter` | 168 |
| `Dka_Tools_Pkg.get_parameter` | 177 |
| `Dka_Tools_Pkg.get_parameter` | 186 |
| `Dka_Tools_Pkg.get_parameter` | 195 |
| `Dka_Tools_Pkg.get_parameter` | 204 |
| `Dka_Tools_Pkg.get_parameter` | 213 |
| `Dka_Tools_Pkg.get_parameter` | 222 |
| `Dka_Tools_Pkg.get_parameter` | 231 |
| `Dka_Tools_Pkg.get_parameter` | 240 |
| `Dka_Tools_Pkg.get_parameter` | 248 |
| `Fnd_Profile.VALUE` | 261 |
| `Dka_Tools_Pkg.get_parameter` | 289 |
| `Dka_Tools_Pkg.get_parameter` | 298 |
| `Dka_Tools_Pkg.get_parameter` | 306 |
| `Dka_Tools_Pkg.get_parameter` | 314 |
| `Dka_Tools_Pkg.get_parameter` | 322 |
| `Dka_Tools_Pkg.put_debug_message` | 332 |
| `Dka_Sarfacman_Pkg.get_data_for_refaccuf` | 420 |
| `Dka_Tools_Pkg.get_message` | 458 |
| `Dka_Pa_Tools_Pkg.pa_check_transaction_data` | 462 |
| `DKA_SPAAUTOACCOUNTING_PKG.societe_projet` | 484 |
| `DKA_SPAAUTOACCOUNTING_PKG.uo_projet` | 485 |
| `Dka_Tools_Pkg.segment_size` | 488 |
| `Dka_Tools_Pkg.segment_size` | 489 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 502 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 513 |
| `DKA_SPAAUTOACCOUNTING_PKG.run_cpt_groupe_couts_f` | 541 |
| `Dka_Spaautoaccounting_Pkg.run_cpt_groupe_produit_f` | 548 |
| `dka_spaautoaccounting_pkg.get_task_template_f` | 560 |
| `dka_spaautoaccounting_pkg.centrefi` | 620 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 646 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 673 |
| `Dka_Pa_Tools_Pkg.pa_run_accounting_rule` | 700 |
| `Dka_Tools_Pkg.get_code_combination_id` | 743 |
| `Dka_Tools_Pkg.put_debug_message` | 922 |
| `Dka_Tools_Pkg.put_debug_message` | 953 |
| `Dka_Tools_Pkg.put_log_message` | 1052 |
| `Dka_Tools_Pkg.get_code_societe` | 1096 |
| `Fnd_File.put_line` | 1162 |
| `Fnd_File.put_line` | 1164 |
| `Fnd_File.put_line` | 1166 |
| `Fnd_File.put_line` | 1168 |
| `Fnd_File.put_line` | 1170 |
| `Fnd_File.put_line` | 1172 |
| `Dka_Tools_Pkg.put_log_message` | 1173 |
| `Fnd_File.put_line` | 1190 |
| `Fnd_File.put_line` | 1205 |
| `Fnd_File.put_line` | 1206 |
| `Fnd_File.put_line` | 1208 |
| `Fnd_File.put_line` | 1210 |
| `Fnd_File.put_line` | 1212 |
| `Dka_Tools_Pkg.get_flex_key_seg_value_set` | 1318 |
| `Fnd_Profile.VALUE` | 1509 |
| `Dka_Tools_Pkg.put_log_message` | 1663 |
| `Fnd_Profile.put` | 1687 |
| `Pa_Cost_Plus1.view_indirect_cost` | 1693 |
| `Dka_Sarfacman_Pkg.events_status_rejection` | 2345 |
| `Dka_Sarfacman_Pkg.events_type_rejection` | 2353 |
| `Dka_Sarfacman_Pkg.get_dr_code_combination_id` | 2361 |
| `Dka_Pa_Tools_Pkg.pa_insert_event` | 2378 |
| `Dka_Tools_Pkg.put_log_message` | 2418 |
| `Dka_Tools_Pkg.put_log_message` | 2419 |
| `Dka_Tools_Pkg.put_log_message` | 2420 |
| `Dka_Tools_Pkg.put_log_message` | 2429 |
| `Dka_Tools_Pkg.put_log_message` | 2431 |
| `Dka_Tools_Pkg.put_log_message` | 2432 |
| `Dka_Tools_Pkg.put_log_message` | 2433 |
| `Dka_Tools_Pkg.put_log_message` | 2448 |
| `Dka_Tools_Pkg.put_log_message` | 2450 |
| `Dka_Tools_Pkg.put_log_message` | 2451 |
| `Dka_Tools_Pkg.put_log_message` | 2452 |
| `Dka_Sarfacman_Pkg.get_dr_code_combination_id` | 2571 |
| `Dka_Tools_Pkg.put_log_message` | 2612 |
| `Dka_Tools_Pkg.put_log_message` | 2620 |
| `Dka_Tools_Pkg.put_log_message` | 2629 |
| `Dka_Tools_Pkg.put_log_message` | 2648 |
| `Dka_Tools_Pkg.put_log_message` | 2682 |
| `Dka_Tools_Pkg.put_log_message` | 2683 |
| `Dka_Tools_Pkg.put_log_message` | 2684 |
| `Dka_Tools_Pkg.put_log_message` | 2693 |
| `Dka_Tools_Pkg.put_log_message` | 2695 |
| `Dka_Tools_Pkg.put_log_message` | 2696 |
| `Dka_Tools_Pkg.put_log_message` | 2697 |
| `Dka_Tools_Pkg.put_log_message` | 2712 |
| `Dka_Tools_Pkg.put_log_message` | 2714 |
| `Dka_Tools_Pkg.put_log_message` | 2715 |
| `Dka_Tools_Pkg.put_log_message` | 2716 |
| `Dka_Sarfacman_Pkg.init` | 2815 |
| `Dka_Tools_Pkg.get_message` | 2849 |
| `Dka_Tools_Pkg.get_message` | 2851 |
| `Dka_Tools_Pkg.get_flex_key_seg_value_set` | 2903 |
| `Dka_Tools_Pkg.get_message` | 3004 |
| `Dka_Tools_Pkg.get_message` | 3006 |
| `Dka_Tools_Pkg.get_message` | 3008 |
| `Dka_Tools_Pkg.get_message` | 3010 |
| `Dka_Tools_Pkg.get_message` | 3013 |
| `Dka_Tools_Pkg.get_message` | 3015 |
| `Dka_Tools_Pkg.put_log_message` | 3066 |
| `Dka_Sarfacman_Pkg.init` | 3067 |
| `Dka_Tools_Pkg.put_log_message` | 3076 |
| `Dka_Sarfacman_Pkg.purge_sarfacman_tmp` | 3077 |
| `Dka_Tools_Pkg.put_log_message` | 3086 |
| `Dka_Sarfacman_Pkg.insert_sarfacman_tmp` | 3087 |
| `Dka_Tools_Pkg.put_log_message` | 3096 |
| `Dka_Sarfacman_Pkg.insert_pa_events` | 3097 |
| `Dka_Tools_Pkg.put_log_message` | 3107 |
| `Dka_Sarfacman_Pkg.insert_pa_expenditures` | 3108 |
| `Dka_Tools_Pkg.put_log_message` | 3118 |
| `Dka_Sarfacman_Pkg.create_output` | 3119 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1053, 2416, 2441, 2461, 2680, 2705, 2726 |
| rollback | 2428, 2447, 2692, 2711 |
| when_others | 111, 334, 783, 844, 891, 924, 1056, 1104, 1233, 1280, 1370, 1415, 1479, 1519, 1659, 1710, 1740, 1768, 1841, 1910, 2120, 2255, 2443, 2469, 2707, 2735, 2883, 2918, 3031, 3133 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARFACMAN / DKA | `dka_sarfacman_pkg.main` | dka/12.0.0/admin/import/DKA_SARFACMAN.prt:482 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
