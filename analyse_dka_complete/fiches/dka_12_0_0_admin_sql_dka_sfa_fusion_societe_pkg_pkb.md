# DKA_SFA_FUSION_SOCIETE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SFA_FUSION_SOCIETE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SFA_FUSION_SOCIETE_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 4068 ; encodage : cp1252 (repli). SHA-256 : `5258caa9e85d4fca1b295f2addca2a45fb58fbef4b7ad17496a51537c72f5fa9`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `ctr_exist_livre_cpt` | 268 |
| `ctr_period_soc` | 296 |
| `ctr_ecriture_fa_impute` | 335 |
| `ctr_evt_sla_non_compta` | 379 |
| `ctr_mass_addition` | 406 |
| `ctr_list_projet_tache_actif` | 430 |
| `ctr_list_projet_tache_ferme` | 489 |
| `ctr_list_projet_cout` | 515 |
| `main_ctr` | 547 |
| `xxfa_accytddeprn_get_fnc` | 676 |
| `get_code_combination_id` | 776 |
| `submit_project` | 915 |
| `program_import_couts` | 991 |
| `wait_request` | 1157 |
| `main_export` | 1234 |
| `main_import` | 2069 |
| `print_errors` | 2786 |
| `main_control_insert` | 2823 |
| `insert_data_social` | 3363 |
| `insert_data_ifrs` | 3526 |
| `submit_fndrssub46` | 3657 |
| `submit_faimcp` | 3781 |
| `submit_fataxup` | 3863 |
| `main_import_fa` | 3946 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_stransco_lines` | 86 |
| `fa_asset_invoices` | 92 |
| `dka_stransco_lines` | 117 |
| `dka_stransco_lines` | 160 |
| `pa_projects_all` | 166 |
| `dka.dka_fa_projet_ferme` | 183 |
| `dka_stransco_lines` | 186 |
| `pa.pa_expenditure_items_all` | 222 |
| `pa.pa_project_asset_line_details` | 234 |
| `dka_stransco_lines` | 251 |
| `fa_book_controls` | 277 |
| `fa_deprn_periods` | 305 |
| `xla_ae_headers` | 343 |
| `xla_entity_events_v` | 387 |
| `fa_mass_additions` | 414 |
| `fa_asset_invoices` | 439 |
| `dka_stransco_lines` | 457 |
| `gl_access_set_assignments` | 813 |
| `gl_code_combinations` | 832 |
| `fnd_responsibility` | 927 |
| `fnd_responsibility` | 1008 |
| `pa_transaction_interface_all` | 1021 |
| `dka.dka_fa_projet_cout` | 1124 |
| `dka_stransco_lines` | 1242 |
| `fa_asset_invoices` | 1311 |
| `fa_asset_invoices` | 1316 |
| `fa_book_controls` | 1320 |
| `fa_books` | 1339 |
| `fa_deprn_periods` | 1344 |
| `fa_books` | 1349 |
| `fa_deprn_periods` | 1358 |
| `fa_asset_history` | 1365 |
| `fa_deprn_periods` | 1369 |
| `fa_deprn_detail` | 1398 |
| `fa.fa_retirements` | 1411 |
| `dka.dka_fa_fusion_immo` | 1600 |
| `dka.dka_fa_fusion_immo` | 1605 |
| `dka.dka_fa_fusion_immo` | 1606 |
| `dka.dka_fa_fusion_immo` | 1734 |
| `dka.dka_fa_projet_ferme` | 1859 |
| `dka.dka_fa_projet_ferme` | 1864 |
| `dka.dka_fa_projet_ferme` | 1865 |
| `dka.dka_fa_projet_ferme` | 1870 |
| `dka.dka_fa_projet_ferme` | 1924 |
| `dka.dka_fa_projet_cout` | 1980 |
| `dka.dka_fa_projet_cout` | 1985 |
| `dka.dka_fa_projet_cout` | 1986 |
| `dka.dka_fa_projet_cout` | 1995 |
| `dka.dka_fa_projet_ferme` | 2126 |
| `pa_projects_all` | 2131 |
| `dka.dka_eai_projet` | 2137 |
| `dka.dka_fa_projet_ferme` | 2197 |
| `dka.dka_eai_tache` | 2210 |
| `dka.dka_fa_projet_ferme` | 2229 |
| `dka.dka_fa_projet_ferme` | 2265 |
| `dka.dka_eai_projet` | 2270 |
| `dka.dka_fa_projet_ferme` | 2330 |
| `dka.dka_eai_tache` | 2343 |
| `dka.dka_fa_projet_ferme` | 2362 |
| `dka.dka_fa_projet_cout` | 2391 |
| `pa_projects_all` | 2395 |
| `dka_stransco_lines` | 2410 |
| `hr_operating_units` | 2427 |
| `hr_operating_units` | 2432 |
| `gl_code_combinations` | 2457 |
| `fnd_flex_value_sets` | 2463 |
| `fnd_flex_values` | 2478 |
| `fnd_flex_value_sets` | 2481 |
| `fnd_flex_values` | 2485 |
| `fnd_flex_value_sets` | 2489 |
| `fnd_flex_values` | 2529 |
| `fnd_flex_value_sets` | 2537 |
| `dual` | 2564 |
| `pa_transaction_interface_all` | 2572 |
| `dka.dka_fa_projet_cout` | 2725 |
| `dka.dka_fa_projet_cout` | 2745 |
| `dka_program_messages` | 2790 |
| `dka.dka_fa_fusion_immo` | 2830 |
| `fa_asset_invoices` | 2843 |
| `pa_projects_all` | 2860 |
| `dka_stransco_lines` | 2894 |
| `fa_asset_invoices` | 2899 |
| `pa_projects_all` | 2936 |
| `dka.dka_fa_projet_cout` | 2946 |
| `pa_expenditure_items_all` | 2955 |
| `pa_tasks` | 3046 |
| `fa_categories_vl` | 3076 |
| `dka.dka_fa_fusion_immo` | 3285 |
| `dka.dka_fa_fusion_immo` | 3321 |
| `dka.dka_fa_fusion_immo` | 3367 |
| `fa_additions` | 3372 |
| `fa_mass_additions` | 3377 |
| `dual` | 3395 |
| `fa_mass_additions` | 3401 |
| `fa_massadd_distributions` | 3473 |
| `dka.dka_fa_fusion_immo` | 3479 |
| `dka.dka_fa_fusion_immo` | 3531 |
| `fa_additions` | 3536 |
| `fa_mass_additions` | 3541 |
| `fa_book_controls` | 3565 |
| `fa_tax_interface` | 3576 |
| `dka.dka_fa_fusion_immo` | 3611 |
| `fa_mass_additions` | 3966 |
| `fa_mass_additions` | 3990 |
| `fa_category_books` | 3998 |
| `fa_book_controls` | 3999 |
| `fa_additions` | 4004 |
| `fa_books` | 4005 |
| `fa_book_controls` | 4007 |
| `fa_tax_interface` | 4034 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_outdebug_message` | 467 |
| `dka_tools_pkg.put_outdebug_message` | 468 |
| `dka_tools_pkg.put_outdebug_message` | 469 |
| `dka_tools_pkg.put_outdebug_message` | 472 |
| `dka_tools_pkg.put_outdebug_message` | 493 |
| `dka_tools_pkg.put_outdebug_message` | 494 |
| `dka_tools_pkg.put_outdebug_message` | 495 |
| `dka_tools_pkg.put_outdebug_message` | 498 |
| `dka_tools_pkg.put_outdebug_message` | 519 |
| `dka_tools_pkg.put_outdebug_message` | 520 |
| `dka_tools_pkg.put_outdebug_message` | 521 |
| `dka_tools_pkg.put_outdebug_message` | 527 |
| `dka_tools_pkg.put_log_message` | 557 |
| `dka_tools_pkg.put_outdebug_message` | 559 |
| `dka_tools_pkg.put_outdebug_message` | 560 |
| `dka_tools_pkg.put_outdebug_message` | 568 |
| `dka_tools_pkg.put_outdebug_message` | 573 |
| `dka_tools_pkg.put_outdebug_message` | 579 |
| `dka_tools_pkg.put_outdebug_message` | 584 |
| `dka_tools_pkg.put_outdebug_message` | 590 |
| `dka_tools_pkg.put_outdebug_message` | 595 |
| `dka_tools_pkg.put_outdebug_message` | 601 |
| `dka_tools_pkg.put_outdebug_message` | 606 |
| `dka_tools_pkg.put_outdebug_message` | 616 |
| `dka_tools_pkg.put_outdebug_message` | 625 |
| `dka_tools_pkg.put_outdebug_message` | 631 |
| `dka_tools_pkg.put_outdebug_message` | 638 |
| `dka_tools_pkg.put_outdebug_message` | 644 |
| `dka_tools_pkg.put_outdebug_message` | 650 |
| `fnd_flex_ext.get_combination_id` | 870 |
| `fnd_file.put_line` | 921 |
| `fnd_global.apps_initialize` | 933 |
| `fnd_request.submit_request` | 937 |
| `fnd_file.put_line` | 950 |
| `fnd_file.put_line` | 953 |
| `fnd_file.put_line` | 959 |
| `fnd_file.put_line` | 964 |
| `fnd_file.put_line` | 972 |
| `fnd_file.put_line` | 973 |
| `dka_tools_pkg.put_log_message` | 1032 |
| `dka_tools_pkg.put_log_message` | 1038 |
| `fnd_global.apps_initialize` | 1044 |
| `fnd_request.set_org_id` | 1051 |
| `fnd_request.submit_request` | 1053 |
| `dka_tools_pkg.put_log_message` | 1064 |
| `dka_tools_pkg.put_outdebug_message` | 1069 |
| `fnd_concurrent.wait_for_request` | 1077 |
| `dka_tools_pkg.put_log_message` | 1087 |
| `dka_tools_pkg.put_log_message` | 1094 |
| `dka_tools_pkg.put_outdebug_message` | 1097 |
| `dka_tools_pkg.put_log_message` | 1101 |
| `dka_tools_pkg.put_outdebug_message` | 1104 |
| `dka_tools_pkg.put_outdebug_message` | 1113 |
| `dka_tools_pkg.put_log_message` | 1114 |
| `dka_tools_pkg.put_log_message` | 1135 |
| `fnd_file.put_line` | 1169 |
| `fnd_concurrent.wait_for_request` | 1173 |
| `fnd_file.put_line` | 1182 |
| `fnd_file.put_line` | 1189 |
| `fnd_file.put_line` | 1195 |
| `fnd_file.put_line` | 1206 |
| `dka_sfa_fusion_societe_pkg.xxfa_accytddeprn_get_fnc` | 1293 |
| `dka_sfa_fusion_societe_pkg.xxfa_accytddeprn_get_fnc` | 1296 |
| `dka_tools_pkg.put_outdebug_message` | 1532 |
| `dka_tools_pkg.put_outdebug_message` | 1533 |
| `dka_tools_pkg.put_outdebug_message` | 1534 |
| `dka_tools_pkg.put_outdebug_message` | 1536 |
| `dka_tools_pkg.put_outdebug_message` | 1539 |
| `dka_tools_pkg.put_outdebug_message` | 1540 |
| `dka_tools_pkg.put_outdebug_message` | 1548 |
| `fnd_file.put_line` | 1595 |
| `dka_tools_pkg.put_outdebug_message` | 1658 |
| `dka_tools_pkg.put_debug_message` | 1842 |
| `dka_tools_pkg.put_outdebug_message` | 1856 |
| `dka_tools_pkg.put_outdebug_message` | 1976 |
| `dka_tools_pkg.put_outdebug_message` | 1977 |
| `dka_tools_pkg.put_outdebug_message` | 2031 |
| `dka_tools_pkg.put_outdebug_message` | 2034 |
| `dka_tools_pkg.put_outdebug_message` | 2035 |
| `dka_tools_pkg.put_outdebug_message` | 2036 |
| `dka_tools_pkg.put_outdebug_message` | 2037 |
| `dka_tools_pkg.put_outdebug_message` | 2038 |
| `dka_tools_pkg.put_outdebug_message` | 2048 |
| `dka_tools_pkg.put_outdebug_message` | 2049 |
| `dka_tools_pkg.put_outdebug_message` | 2050 |
| `dka_tools_pkg.put_outdebug_message` | 2051 |
| `dka_tools_pkg.put_outdebug_message` | 2052 |
| `dka_tools_pkg.put_outdebug_message` | 2102 |
| `dka_tools_pkg.put_outdebug_message` | 2103 |
| `dka_tools_pkg.put_outdebug_message` | 2104 |
| `dka_tools_pkg.put_outdebug_message` | 2105 |
| `dka_tools_pkg.put_outdebug_message` | 2107 |
| `dka_tools_pkg.put_outdebug_message` | 2108 |
| `dka_tools_pkg.put_outdebug_message` | 2201 |
| `dka_tools_pkg.put_outdebug_message` | 2334 |
| `dka_tools_pkg.put_outdebug_message` | 2386 |
| `dka_tools_pkg.put_outdebug_message` | 2387 |
| `dka_tools_pkg.put_outdebug_message` | 2389 |
| `dka_tools_pkg.put_outdebug_message` | 2398 |
| `dka_tools_pkg.put_outdebug_message` | 2422 |
| `fnd_file.put_line` | 2493 |
| `fnd_file.put_line` | 2518 |
| `fnd_file.put_line` | 2524 |
| `pa_utils.getweekending` | 2650 |
| `dka_tools_pkg.put_outdebug_message` | 2740 |
| `dka_tools_pkg.put_outdebug_message` | 2741 |
| `dka_tools_pkg.put_outdebug_message` | 2743 |
| `dka_tools_pkg.put_outdebug_message` | 2747 |
| `dka_tools_pkg.put_outdebug_message` | 2763 |
| `dka_tools_pkg.put_outdebug_message` | 2764 |
| `dka_tools_pkg.put_outdebug_message` | 2765 |
| `dka_tools_pkg.put_outdebug_message` | 2766 |
| `dka_tools_pkg.put_outdebug_message` | 2767 |
| `fnd_file.put_line` | 2795 |
| `fnd_file.put_line` | 2796 |
| `fnd_file.put_line` | 2797 |
| `fnd_file.put_line` | 2801 |
| `dka_tools_pkg.put_outdebug_message` | 2982 |
| `dka_tools_pkg.put_outdebug_message` | 2983 |
| `dka_tools_pkg.put_outdebug_message` | 2984 |
| `dka_tools_pkg.put_outdebug_message` | 2985 |
| `dka_tools_pkg.ins_prog_message` | 2992 |
| `dka_tools_pkg.ins_prog_message` | 3007 |
| `dka_tools_pkg.ins_prog_message` | 3023 |
| `dka_tools_pkg.ins_prog_message` | 3059 |
| `dka_tools_pkg.ins_prog_message` | 3086 |
| `fnd_flex_ext.get_combination_id` | 3115 |
| `dka_tools_pkg.ins_prog_message` | 3127 |
| `fnd_flex_ext.get_combination_id` | 3155 |
| `dka_tools_pkg.ins_prog_message` | 3167 |
| `dka_tools_pkg.ins_prog_message` | 3210 |
| `dka_tools_pkg.ins_prog_message` | 3260 |
| `dka_tools_pkg.put_outdebug_message` | 3340 |
| `dka_tools_pkg.put_outdebug_message` | 3341 |
| `dka_tools_pkg.put_outdebug_message` | 3342 |
| `dka_tools_pkg.put_outdebug_message` | 3343 |
| `dka_tools_pkg.put_outdebug_message` | 3344 |
| `fnd_file.put_line` | 3389 |
| `fnd_file.put_line` | 3487 |
| `fnd_file.put_line` | 3495 |
| `fnd_file.put_line` | 3504 |
| `fnd_file.put_line` | 3505 |
| `fnd_file.put_line` | 3557 |
| `fnd_file.put_line` | 3570 |
| `fnd_file.put_line` | 3626 |
| `fnd_file.put_line` | 3635 |
| `fnd_file.put_line` | 3636 |
| `fnd_file.put_line` | 3687 |
| `fnd_submit.set_request_set` | 3691 |
| `fnd_submit.submit_program` | 3699 |
| `fnd_submit.submit_program` | 3710 |
| `fnd_submit.submit_set` | 3720 |
| `fnd_file.put_line` | 3724 |
| `fnd_file.put_line` | 3728 |
| `fnd_file.put_line` | 3734 |
| `fnd_concurrent.wait_for_request` | 3738 |
| `fnd_file.put_line` | 3749 |
| `fnd_file.put_line` | 3758 |
| `fnd_file.put_line` | 3759 |
| `fnd_file.put_line` | 3795 |
| `fnd_request.submit_request` | 3799 |
| `fnd_file.put_line` | 3816 |
| `fnd_file.put_line` | 3820 |
| `fnd_file.put_line` | 3827 |
| `fnd_file.put_line` | 3832 |
| `fnd_file.put_line` | 3840 |
| `fnd_file.put_line` | 3841 |
| `fnd_file.put_line` | 3877 |
| `fnd_request.submit_request` | 3881 |
| `fnd_file.put_line` | 3896 |
| `fnd_file.put_line` | 3901 |
| `fnd_file.put_line` | 3909 |
| `fnd_file.put_line` | 3911 |
| `fnd_file.put_line` | 3916 |
| `fnd_file.put_line` | 3925 |
| `fnd_file.put_line` | 3926 |
| `dka_tools_pkg.put_outdebug_message` | 3954 |
| `dka_tools_pkg.put_outdebug_message` | 3955 |
| `dka_tools_pkg.put_outdebug_message` | 3956 |
| `dka_tools_pkg.put_outdebug_message` | 3957 |
| `fnd_file.put_line` | 3961 |
| `fnd_file.put_line` | 3984 |
| `fnd_file.put_line` | 4012 |
| `dka_tools_pkg.put_outdebug_message` | 4057 |
| `dka_tools_pkg.put_outdebug_message` | 4058 |
| `dka_tools_pkg.put_outdebug_message` | 4059 |
| `dka_tools_pkg.put_outdebug_message` | 4060 |
| `dka_tools_pkg.put_outdebug_message` | 4061 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_IPROJECT` | 937 |
| `PAXTRTRX` | 1053 |
| `FAIMCP` | 3799 |
| `FATAXUP` | 3881 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 956, 1068, 2040, 3493, 3624, 3732, 3824, 3905 |
| rollback | 668, 672, 2043, 2758, 3334, 4052 |
| when_others | 325, 667, 745, 894, 969, 1131, 1841, 2042, 2757, 3333, 3486, 3500, 3618, 3631, 3754, 3837, 3921, 4051 |
| suppression | 1606, 1865, 1986 |
| soumission | 937, 1053, 3799, 3881 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SFAFUSIONSOC / DKA | `DKA_SFA_FUSION_SOCIETE_PKG.main_ctr` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOC.prt:417 |
| DKA_SFAFUSIONSOCCTR / DKA | `dka_sfa_fusion_societe_pkg.main_control_insert` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOCCTR.prt:417 |
| DKA_SFAFUSIONSOCEXT / DKA | `dka_sfa_fusion_societe_pkg.main_export` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOCEXT.prt:417 |
| DKA_SFAFUSIONSOCIMP / DKA | `dka_sfa_fusion_societe_pkg.main_import` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOCIMP.prt:474 |
| DKA_SFAFUSIONSOCIMPIMMO / DKA | `dka_sfa_fusion_societe_pkg.main_import_fa` | dka/12.0.0/admin/import/DKA_SFAFUSIONSOCIMPIMMO.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
