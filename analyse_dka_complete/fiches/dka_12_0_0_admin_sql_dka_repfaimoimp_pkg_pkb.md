# DKA_REPFAIMOIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPFAIMOIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPFAIMOIMP_PKG.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3277 ; encodage : cp1252 (repli). SHA-256 : `df914e91fd8845e55431d11584e445f2a1794515c6830890d3c9a15cd97f3859`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 92 |
| `output_header` | 172 |
| `request_parameters` | 222 |
| `output_end` | 320 |
| `print_errors` | 348 |
| `get_code_combination_id` | 392 |
| `duplicate_calisto_social` | 559 |
| `validate_data_social` | 794 |
| `validate_data_IFRS` | 1518 |
| `insert_data_social` | 1752 |
| `insert_data_IFRS` | 1932 |
| `update_data_IFRS` | 2095 |
| `wait_request` | 2268 |
| `submit_fndrssub46` | 2349 |
| `submit_faimcp` | 2473 |
| `submit_fataxup` | 2556 |
| `report_bilan` | 2640 |
| `launch_loader_immo` | 2715 |
| `main` | 2852 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 135 |
| `fnd_concurrent_programs` | 184 |
| `fnd_concurrent_requests` | 226 |
| `fnd_concurrent_requests` | 257 |
| `fnd_concurrent_requests` | 279 |
| `dka_program_messages` | 351 |
| `gl_access_set_assignments` | 433 |
| `gl_code_combinations` | 454 |
| `DKA_REP009_CALISTO_INTERFACE` | 564 |
| `fa_deprn_periods` | 589 |
| `DKA_REP009_INTERFACE` | 605 |
| `DKA_REP009_CALISTO_INTERFACE` | 742 |
| `DKA_REP009_CALISTO_INTERFACE` | 751 |
| `DKA_REP009_INTERFACE` | 804 |
| `fa_deprn_periods` | 875 |
| `fa_additions` | 892 |
| `fa_mass_additions` | 896 |
| `fa_book_controls` | 922 |
| `fa_categories_vl` | 956 |
| `fa_category_books` | 990 |
| `fa_methods` | 1020 |
| `gl_code_combinations` | 1184 |
| `pa_tasks` | 1312 |
| `DKA_REP009_INTERFACE` | 1445 |
| `DKA_REP009_INTERFACE` | 1475 |
| `DKA_REP009_CALISTO_INTERFACE` | 1528 |
| `DKA_REP009_INTERFACE` | 1606 |
| `DKA_REP009_INTERFACE` | 1624 |
| `fa_book_controls` | 1650 |
| `fa_methods` | 1678 |
| `DKA_REP009_CALISTO_INTERFACE` | 1699 |
| `DKA_REP009_CALISTO_INTERFACE` | 1709 |
| `DKA_REP009_INTERFACE` | 1756 |
| `fa_additions` | 1760 |
| `fa_mass_additions` | 1764 |
| `dual` | 1782 |
| `fa_book_controls` | 1788 |
| `fa_mass_additions` | 1796 |
| `fa_massadd_distributions` | 1871 |
| `DKA_REP009_INTERFACE` | 1877 |
| `DKA_REP009_CALISTO_INTERFACE` | 1937 |
| `fa_additions` | 1942 |
| `fa_mass_additions` | 1946 |
| `fa_book_controls` | 1970 |
| `fa_tax_interface` | 1994 |
| `DKA_REP009_CALISTO_INTERFACE` | 2038 |
| `DKA_REP009_CALISTO_INTERFACE` | 2100 |
| `fa_additions` | 2105 |
| `fa_tax_interface` | 2112 |
| `dka_rep009_interface` | 2116 |
| `fa_book_controls` | 2150 |
| `DKA_REP009_INTERFACE` | 2166 |
| `dual` | 2185 |
| `fa_tax_interface` | 2192 |
| `DKA_REP009_CALISTO_INTERFACE` | 2212 |
| `pa_project_assets_all` | 2892 |
| `fa_additions` | 2904 |
| `fa_books` | 2905 |
| `fa_distribution_history` | 2906 |
| `fa_asset_invoices` | 2907 |
| `pa_projects_all` | 2908 |
| `pa_tasks` | 2909 |
| `fa_mass_additions` | 3025 |
| `fa_mass_additions` | 3053 |
| `fa_category_books` | 3062 |
| `fa_book_controls` | 3063 |
| `fa_additions` | 3068 |
| `fa_books` | 3069 |
| `fa_book_controls` | 3071 |
| `fa_tax_interface` | 3135 |
| `DKA_REP009_INTERFACE` | 3187 |
| `pa_project_assets_all` | 3192 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 99 |
| `fnd_file.put_line` | 128 |
| `fnd_file.put_line` | 139 |
| `fnd_file.put_line` | 149 |
| `fnd_file.put_line` | 196 |
| `fnd_file.put_line` | 197 |
| `fnd_file.put_line` | 199 |
| `fnd_file.put_line` | 201 |
| `fnd_file.put_line` | 204 |
| `fnd_file.put_line` | 242 |
| `fnd_file.put_line` | 243 |
| `fnd_file.put_line` | 244 |
| `fnd_file.put_line` | 245 |
| `fnd_file.put_line` | 263 |
| `fnd_file.put_line` | 266 |
| `fnd_file.put_line` | 285 |
| `fnd_file.put_line` | 288 |
| `fnd_file.put_line` | 293 |
| `fnd_file.put_line` | 296 |
| `fnd_file.put_line` | 297 |
| `fnd_file.put_line` | 326 |
| `fnd_file.put_line` | 327 |
| `fnd_file.put_line` | 330 |
| `fnd_file.put_line` | 355 |
| `fnd_file.put_line` | 356 |
| `fnd_file.put_line` | 357 |
| `fnd_file.put_line` | 360 |
| `Fnd_Flex_Ext.get_combination_id` | 493 |
| `fnd_file.put_line` | 581 |
| `dka_tools_pkg.ins_prog_message` | 727 |
| `fnd_file.put_line` | 761 |
| `fnd_file.put_line` | 771 |
| `fnd_file.put_line` | 772 |
| `fnd_file.put_line` | 866 |
| `dka_tools_pkg.ins_prog_message` | 904 |
| `dka_tools_pkg.ins_prog_message` | 929 |
| `dka_rep_transco_pkg.get_transco` | 945 |
| `dka_tools_pkg.ins_prog_message` | 972 |
| `dka_tools_pkg.ins_prog_message` | 998 |
| `dka_rep_transco_pkg.get_transco` | 1014 |
| `dka_tools_pkg.ins_prog_message` | 1028 |
| `fnd_flex_ext.get_combination_id` | 1052 |
| `dka_tools_pkg.ins_prog_message` | 1064 |
| `fnd_flex_ext.get_combination_id` | 1089 |
| `dka_tools_pkg.ins_prog_message` | 1101 |
| `dka_rep_transco_pkg.get_cle_transco` | 1117 |
| `dka_rep_transco_pkg.get_transco` | 1139 |
| `dka_tools_pkg.ins_prog_message` | 1166 |
| `dka_tools_pkg.ins_prog_message` | 1192 |
| `dka_rep_transco_pkg.get_cle_transco` | 1216 |
| `dka_rep_transco_pkg.get_transco` | 1238 |
| `dka_tools_pkg.ins_prog_message` | 1265 |
| `dka_rep_transco_pkg.get_transco` | 1287 |
| `dka_tools_pkg.ins_prog_message` | 1297 |
| `dka_tools_pkg.ins_prog_message` | 1322 |
| `dka_tools_pkg.ins_prog_message` | 1343 |
| `dka_tools_pkg.ins_prog_message` | 1364 |
| `dka_tools_pkg.ins_prog_message` | 1384 |
| `dka_tools_pkg.ins_prog_message` | 1410 |
| `dka_tools_pkg.ins_prog_message` | 1430 |
| `fnd_file.put_line` | 1485 |
| `fnd_file.put_line` | 1495 |
| `fnd_file.put_line` | 1496 |
| `fnd_file.put_line` | 1588 |
| `dka_tools_pkg.ins_prog_message` | 1612 |
| `dka_tools_pkg.ins_prog_message` | 1631 |
| `dka_tools_pkg.ins_prog_message` | 1657 |
| `dka_rep_transco_pkg.get_transco` | 1672 |
| `dka_tools_pkg.ins_prog_message` | 1686 |
| `fnd_file.put_line` | 1719 |
| `fnd_file.put_line` | 1729 |
| `fnd_file.put_line` | 1730 |
| `fnd_file.put_line` | 1776 |
| `dka_tools_pkg.ins_prog_message` | 1887 |
| `fnd_file.put_line` | 1901 |
| `fnd_file.put_line` | 1910 |
| `fnd_file.put_line` | 1911 |
| `fnd_file.put_line` | 1962 |
| `fnd_file.put_line` | 1975 |
| `dka_tools_pkg.ins_prog_message` | 2049 |
| `fnd_file.put_line` | 2063 |
| `fnd_file.put_line` | 2072 |
| `fnd_file.put_line` | 2073 |
| `fnd_file.put_line` | 2142 |
| `fnd_file.put_line` | 2155 |
| `fnd_file.put_line` | 2172 |
| `dka_tools_pkg.ins_prog_message` | 2223 |
| `fnd_file.put_line` | 2237 |
| `fnd_file.put_line` | 2246 |
| `fnd_file.put_line` | 2247 |
| `fnd_file.put_line` | 2280 |
| `Fnd_Concurrent.wait_for_request` | 2284 |
| `Fnd_File.put_line` | 2293 |
| `Fnd_File.put_line` | 2300 |
| `Fnd_File.put_line` | 2307 |
| `Fnd_File.put_line` | 2319 |
| `fnd_file.put_line` | 2379 |
| `fnd_submit.set_request_set` | 2383 |
| `fnd_submit.submit_program` | 2391 |
| `fnd_submit.submit_program` | 2402 |
| `fnd_submit.submit_set` | 2412 |
| `fnd_file.put_line` | 2416 |
| `fnd_file.put_line` | 2421 |
| `fnd_file.put_line` | 2427 |
| `fnd_concurrent.wait_for_request` | 2431 |
| `fnd_file.put_line` | 2442 |
| `fnd_file.put_line` | 2450 |
| `fnd_file.put_line` | 2451 |
| `fnd_file.put_line` | 2487 |
| `fnd_request.submit_request` | 2491 |
| `fnd_file.put_line` | 2508 |
| `fnd_file.put_line` | 2513 |
| `fnd_file.put_line` | 2520 |
| `fnd_file.put_line` | 2525 |
| `fnd_file.put_line` | 2533 |
| `fnd_file.put_line` | 2534 |
| `fnd_file.put_line` | 2570 |
| `fnd_request.submit_request` | 2574 |
| `fnd_file.put_line` | 2589 |
| `fnd_file.put_line` | 2595 |
| `fnd_file.put_line` | 2603 |
| `fnd_file.put_line` | 2605 |
| `fnd_file.put_line` | 2610 |
| `fnd_file.put_line` | 2618 |
| `fnd_file.put_line` | 2619 |
| `fnd_file.put_line` | 2644 |
| `fnd_file.put_line` | 2655 |
| `fnd_file.put_line` | 2656 |
| `fnd_file.put_line` | 2657 |
| `fnd_file.put_line` | 2659 |
| `fnd_file.put_line` | 2662 |
| `fnd_file.put_line` | 2665 |
| `fnd_file.put_line` | 2668 |
| `fnd_file.put_line` | 2671 |
| `fnd_file.put_line` | 2674 |
| `fnd_file.put_line` | 2678 |
| `fnd_file.put_line` | 2679 |
| `fnd_file.put_line` | 2682 |
| `fnd_file.put_line` | 2683 |
| `fnd_file.put_line` | 2691 |
| `fnd_file.put_line` | 2692 |
| `fnd_file.put_line` | 2726 |
| `fnd_file.put_line` | 2729 |
| `fnd_file.put_line` | 2733 |
| `fnd_file.put_line` | 2734 |
| `fnd_file.put_line` | 2735 |
| `fnd_request.set_print_options` | 2740 |
| `fnd_request.submit_request` | 2743 |
| `fnd_file.put_line` | 2758 |
| `fnd_file.put_line` | 2763 |
| `fnd_file.put_line` | 2767 |
| `fnd_file.put_line` | 2769 |
| `fnd_concurrent.wait_for_request` | 2774 |
| `fnd_file.put_line` | 2783 |
| `fnd_file.put_line` | 2789 |
| `fnd_file.put_line` | 2792 |
| `fnd_file.put_line` | 2797 |
| `fnd_file.put_line` | 2807 |
| `fnd_file.put_line` | 2813 |
| `fnd_file.put_line` | 2820 |
| `fnd_file.put_line` | 2828 |
| `fnd_file.put_line` | 2829 |
| `fnd_file.put_line` | 2922 |
| `fnd_file.put_line` | 2929 |
| `fnd_file.put_line` | 2948 |
| `fnd_file.put_line` | 2971 |
| `fnd_file.put_line` | 2987 |
| `fnd_file.put_line` | 3002 |
| `fnd_file.put_line` | 3020 |
| `fnd_file.put_line` | 3047 |
| `fnd_file.put_line` | 3078 |
| `fnd_file.put_line` | 3095 |
| `fnd_file.put_line` | 3110 |
| `fnd_file.put_line` | 3128 |
| `fnd_file.put_line` | 3169 |
| `dka_tools_pkg.ins_prog_message` | 3176 |
| `fnd_file.put_line` | 3210 |
| `fnd_file.put_line` | 3218 |
| `fnd_file.put_line` | 3239 |
| `fnd_file.put_line` | 3240 |
| `fnd_file.put_line` | 3242 |
| `fnd_file.put_line` | 3250 |
| `fnd_file.put_line` | 3251 |
| `fnd_file.put_line` | 3252 |
| `fnd_file.put_line` | 3256 |
| `fnd_file.put_line` | 3263 |
| `fnd_file.put_line` | 3267 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `FAIMCP` | 2491 |
| `FATAXUP` | 2574 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 765, 1489, 1723, 1899, 2061, 2235, 2425, 2517, 2599, 2766 |
| rollback | 2 |
| when_others | 151, 191, 537, 724, 768, 1492, 1726, 1884, 1906, 2046, 2068, 2169, 2220, 2242, 2447, 2530, 2615, 2688, 2825, 3260 |
| soumission | 2491, 2574, 2743 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPFAIMOIMP / DKA | `DKA_REPFAIMOIMP_PKG.Main` | dka/12.0.0/admin/import/DKA_REPFAIMOIMP.prt:515 |
| DKA_REPFAIMOIMPCAL / DKA | `DKA_REPFAIMOIMP_PKG.Main_calisto` | dka/12.0.0/admin/import/DKA_REPFAIMOIMPCAL.prt:533 |
| DKA_REPFAIMOIMPSOC / DKA | `DKA_REPFAIMOIMP_PKG.Main_immo` | dka/12.0.0/admin/import/DKA_REPFAIMOIMPSOC.prt:533 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
