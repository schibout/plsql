# DKA_IEOMTL_CODARTINT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IEOMTL_CODARTINT_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 6256 ; encodage : cp1252 (repli). SHA-256 : `e48e17c202c02cd9234a6800cdbb4f9da1fc1e6a96610498476633e5c838d0ea`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `chgt_file_cod_artint` | 121 |
| `controle_nbr_enreg_file` | 815 |
| `control_format_codes` | 854 |
| `control_format_article` | 891 |
| `controle_unicite` | 944 |
| `delete_old_error_records` | 989 |
| `delete_obsolete_records` | 1079 |
| `reinit_statut` | 1170 |
| `controle_donnees` | 1257 |
| `init` | 2683 |
| `delete_complete_records` | 3003 |
| `get_inventory_item_id` | 3072 |
| `get_category_id` | 3117 |
| `get_item_category` | 3162 |
| `get_item_category_sec` | 3211 |
| `insert_assign_category_item` | 3263 |
| `launch_item_category` | 3704 |
| `alimentation_jeux_valeurs` | 3829 |
| `insert_items_interface` | 4824 |
| `launch_items_oi` | 5275 |
| `check_items_oi` | 5568 |
| `check_category_items_oi` | 5673 |
| `MAIN` | 5776 |
| `bilan` | 6109 |
| `check_code_isNumeric` | 6228 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `mtl_parameters` | 84 |
| `per_security_organizations` | 93 |
| `fnd_lobs` | 225 |
| `dka_ieomtl_system_items_tmp` | 643 |
| `DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 761 |
| `DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 771 |
| `dka_ieomtl_system_items_tmp` | 826 |
| `dual` | 863 |
| `dual` | 903 |
| `dual` | 913 |
| `dka_ieomtl_system_items_tmp` | 955 |
| `MTL_SYSTEM_ITEMS_INTERFACE` | 1008 |
| `DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 1010 |
| `MTL_SYSTEM_ITEMS_INTERFACE` | 1019 |
| `MTL_ITEM_CATEGORIES_INTERFACE` | 1025 |
| `DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 1027 |
| `MTL_ITEM_CATEGORIES_INTERFACE` | 1040 |
| `DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 1046 |
| `DKA.DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 1048 |
| `dka_ieomtl_system_items_tmp` | 1098 |
| `dka_ieomtl_system_items_tmp` | 1108 |
| `MTL_SYSTEM_ITEMS_INTERFACE` | 1116 |
| `dka_ieomtl_system_items_tmp` | 1124 |
| `MTL_ITEM_CATEGORIES_INTERFACE` | 1132 |
| `MTL_ITEM_REVISIONS_INTERFACE` | 1138 |
| `dka_ieomtl_system_items_tmp` | 1140 |
| `dka_ieomtl_system_items_tmp` | 1186 |
| `dka_ieomtl_system_items_tmp` | 1203 |
| `MTL_SYSTEM_ITEMS_INTERFACE` | 1212 |
| `dka_ieomtl_system_items_tmp` | 1220 |
| `MTL_ITEM_CATEGORIES_INTERFACE` | 1228 |
| `dka_ieomtl_system_items_tmp` | 1309 |
| `dka_ieomtl_system_items_tmp` | 1320 |
| `dka_ieomtl_error` | 1341 |
| `dka_ieomtl_error` | 1379 |
| `dka_ieomtl_error` | 1418 |
| `dka_ieomtl_error` | 1455 |
| `dka_ieomtl_error` | 1493 |
| `dka_ieomtl_error` | 1530 |
| `dka_ieomtl_error` | 1567 |
| `dka_ieomtl_error` | 1604 |
| `dual` | 1644 |
| `dka_ieomtl_error` | 1649 |
| `dual` | 1688 |
| `dka_ieomtl_error` | 1694 |
| `dual` | 1733 |
| `dka_ieomtl_error` | 1739 |
| `dual` | 1778 |
| `dka_ieomtl_error` | 1784 |
| `dual` | 1823 |
| `dka_ieomtl_error` | 1829 |
| `dual` | 1868 |
| `dka_ieomtl_error` | 1874 |
| `dual` | 1916 |
| `dka_ieomtl_error` | 1922 |
| `dual` | 1962 |
| `dka_ieomtl_error` | 1968 |
| `dual` | 2007 |
| `dka_ieomtl_error` | 2013 |
| `mtl_item_status` | 2054 |
| `dka_ieomtl_error` | 2062 |
| `mtl_units_of_measure_vl` | 2099 |
| `dka_ieomtl_error` | 2109 |
| `mtl_categories_v` | 2145 |
| `dka_ieomtl_error` | 2156 |
| `mtl_categories_v` | 2189 |
| `dka_ieomtl_error` | 2201 |
| `mtl_categories_v` | 2235 |
| `dka_ieomtl_error` | 2246 |
| `mtl_categories_v` | 2280 |
| `dka_ieomtl_error` | 2290 |
| `mtl_categories_v` | 2323 |
| `dka_ieomtl_error` | 2337 |
| `mtl_categories_v` | 2372 |
| `dka_ieomtl_error` | 2385 |
| `dual` | 2424 |
| `dka_ieomtl_error` | 2438 |
| `dka_ieomtl_error` | 2480 |
| `mtl_system_items_b` | 2532 |
| `MTL_PARAMETERS` | 2551 |
| `MTL_SYSTEM_ITEMS_B` | 2557 |
| `dka_ieomtl_system_items_tmp` | 2598 |
| `dka_ieomtl_system_items_tmp` | 2610 |
| `dka_ieomtl_system_items_tmp` | 2625 |
| `dka_ieomtl_system_items_tmp` | 2639 |
| `mtl_parameters` | 2726 |
| `per_security_profiles` | 2747 |
| `mtl_item_templates` | 2779 |
| `mtl_category_sets` | 2800 |
| `mtl_category_sets` | 2820 |
| `mtl_category_sets` | 2842 |
| `mtl_item_status` | 2861 |
| `mtl_item_status` | 2880 |
| `fnd_flex_value_sets` | 2898 |
| `fnd_flex_value_sets` | 2916 |
| `DKA_PARAMETERS` | 2935 |
| `DKA_PARAMETERS` | 2952 |
| `dka_ieomtl_system_items_tmp` | 2971 |
| `dka_ieomtl_system_items_tmp` | 2976 |
| `dka_ieomtl_error` | 3018 |
| `dka_ieomtl_system_items_tmp` | 3023 |
| `mtl_system_items_b` | 3084 |
| `mtl_categories` | 3129 |
| `mtl_item_categories` | 3176 |
| `mtl_item_categories` | 3226 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 3312 |
| `mtl_item_categories` | 3322 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 3329 |
| `dual` | 3348 |
| `dual` | 3354 |
| `dual` | 3360 |
| `dual` | 3366 |
| `dual` | 3372 |
| `dual` | 3379 |
| `mtl_item_categories_interface` | 3395 |
| `mtl_item_categories_interface` | 3465 |
| `mtl_item_categories_interface` | 3508 |
| `mtl_item_categories_interface` | 3554 |
| `mtl_item_categories_interface` | 3599 |
| `mtl_item_categories_interface` | 3643 |
| `mtl_item_categories_interface` | 3722 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 3735 |
| `dka_ieomtl_system_items_tmp` | 3887 |
| `dka_ieomtl_system_items_tmp` | 3923 |
| `fnd_flex_values_tl` | 3946 |
| `fnd_flex_values_vl` | 3955 |
| `dual` | 3976 |
| `fnd_flex_values` | 3979 |
| `fnd_flex_values_tl` | 4008 |
| `fnd_flex_values_tl` | 4048 |
| `fnd_flex_values_vl` | 4057 |
| `dual` | 4075 |
| `fnd_flex_values` | 4078 |
| `fnd_flex_values_tl` | 4107 |
| `fnd_flex_values_tl` | 4150 |
| `fnd_flex_values_vl` | 4159 |
| `dual` | 4178 |
| `fnd_flex_values` | 4181 |
| `fnd_flex_values_tl` | 4210 |
| `fnd_flex_values` | 4272 |
| `fnd_flex_value_norm_hierarchy` | 4286 |
| `dka_ieomtl_system_items_tmp` | 4304 |
| `dka_ieomtl_system_items_tmp` | 4313 |
| `fnd_flex_value_norm_hierarchy` | 4319 |
| `fnd_flex_value_norm_hierarchy` | 4357 |
| `dka_ieomtl_system_items_tmp` | 4375 |
| `dka_ieomtl_system_items_tmp` | 4384 |
| `fnd_flex_value_norm_hierarchy` | 4390 |
| `fnd_flex_value_norm_hierarchy` | 4441 |
| `dka_ieomtl_system_items_tmp` | 4459 |
| `dka_ieomtl_system_items_tmp` | 4468 |
| `fnd_flex_value_norm_hierarchy` | 4473 |
| `dual` | 4526 |
| `dual` | 4554 |
| `fnd_flex_values_tl` | 4564 |
| `fnd_flex_values_vl` | 4573 |
| `dual` | 4592 |
| `fnd_flex_values` | 4595 |
| `fnd_flex_values_tl` | 4624 |
| `dka_ieomtl_compl_tech` | 4668 |
| `dka_ieomtl_compl_tech` | 4725 |
| `dka_ieomtl_system_items_tmp` | 4775 |
| `dka_ieomtl_compl_tech` | 4781 |
| `dka_ieomtl_system_items_tmp` | 4838 |
| `dual` | 4877 |
| `dual` | 4883 |
| `dual` | 4889 |
| `dual` | 4895 |
| `DUAL` | 4923 |
| `mtl_system_items_interface` | 4928 |
| `DUAL` | 4993 |
| `mtl_system_items_interface` | 4999 |
| `DUAL` | 5074 |
| `mtl_system_items_interface` | 5080 |
| `MTL_SYSTEM_ITEMS_B` | 5148 |
| `DUAL` | 5164 |
| `mtl_system_items_interface` | 5170 |
| `dka_ieomtl_system_items_tmp` | 5232 |
| `dka_ieomtl_system_items_tmp` | 5239 |
| `mtl_system_items_interface` | 5301 |
| `dka_ieomtl_system_items_tmp` | 5336 |
| `dka_ieomtl_system_items_tmp` | 5450 |
| `dka_ieomtl_system_items_tmp` | 5583 |
| `MTL_SYSTEM_ITEMS` | 5587 |
| `dka_ieomtl_system_items_tmp` | 5598 |
| `dka_ieomtl_system_items_tmp` | 5611 |
| `MTL_SYSTEM_ITEMS_INTERFACE` | 5620 |
| `dka_ieomtl_system_items_tmp` | 5631 |
| `MTL_SYSTEM_ITEMS_INTERFACE` | 5640 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 5680 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 5687 |
| `MTL_ITEM_CATEGORIES` | 5699 |
| `MTL_ITEM_CATEGORIES` | 5710 |
| `MTL_ITEM_CATEGORIES` | 5720 |
| `MTL_ITEM_CATEGORIES` | 5730 |
| `MTL_ITEM_CATEGORIES` | 5740 |
| `MTL_ITEM_CATEGORIES_INTERFACE` | 5750 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 6119 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 6131 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 6143 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 6161 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 6166 |
| `DKA_IEOMTL_SYSTEM_ITEMS_TMP` | 6171 |
| `DUAL` | 6237 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 31 |
| `fnd_profile.value` | 32 |
| `fnd_profile.value` | 33 |
| `fnd_profile.value` | 34 |
| `fnd_gfm.get_file_id` | 213 |
| `Fnd_File.put_line` | 999 |
| `Fnd_File.put_line` | 1014 |
| `Fnd_File.put_line` | 1022 |
| `Fnd_File.put_line` | 1034 |
| `Fnd_File.put_line` | 1043 |
| `Fnd_File.put_line` | 1052 |
| `Fnd_File.put_line` | 1056 |
| `Fnd_File.put_line` | 1087 |
| `Fnd_File.put_line` | 1102 |
| `Fnd_File.put_line` | 1111 |
| `Fnd_File.put_line` | 1119 |
| `Fnd_File.put_line` | 1127 |
| `Fnd_File.put_line` | 1135 |
| `Fnd_File.put_line` | 1142 |
| `Fnd_File.put_line` | 1145 |
| `Fnd_File.put_line` | 1178 |
| `Fnd_File.put_line` | 1185 |
| `Fnd_File.put_line` | 1192 |
| `Fnd_File.put_line` | 1197 |
| `Fnd_File.put_line` | 1200 |
| `Fnd_File.put_line` | 1205 |
| `Fnd_File.put_line` | 1209 |
| `Fnd_File.put_line` | 1214 |
| `Fnd_File.put_line` | 1217 |
| `Fnd_File.put_line` | 1222 |
| `Fnd_File.put_line` | 1225 |
| `Fnd_File.put_line` | 1230 |
| `Fnd_File.put_line` | 1233 |
| `Fnd_File.put_line` | 1236 |
| `Fnd_File.put_line` | 1318 |
| `dka_tools_pkg.get_message` | 1338 |
| `dka_tools_pkg.get_message` | 1377 |
| `dka_tools_pkg.get_message` | 1416 |
| `dka_tools_pkg.get_message` | 1453 |
| `dka_tools_pkg.get_message` | 1491 |
| `dka_tools_pkg.get_message` | 1528 |
| `dka_tools_pkg.get_message` | 1565 |
| `dka_tools_pkg.get_message` | 1602 |
| `dka_tools_pkg.get_message` | 1648 |
| `dka_tools_pkg.get_message` | 1693 |
| `dka_tools_pkg.get_message` | 1738 |
| `dka_tools_pkg.get_message` | 1783 |
| `dka_tools_pkg.get_message` | 1828 |
| `dka_tools_pkg.get_message` | 1873 |
| `dka_tools_pkg.get_message` | 1921 |
| `dka_tools_pkg.get_message` | 1967 |
| `dka_tools_pkg.get_message` | 2012 |
| `dka_tools_pkg.get_message` | 2061 |
| `dka_tools_pkg.get_message` | 2108 |
| `dka_tools_pkg.get_message` | 2154 |
| `dka_tools_pkg.get_message` | 2197 |
| `dka_tools_pkg.get_message` | 2244 |
| `dka_tools_pkg.get_message` | 2288 |
| `dka_tools_pkg.get_message` | 2333 |
| `dka_tools_pkg.get_message` | 2381 |
| `dka_tools_pkg.get_message` | 2434 |
| `dka_tools_pkg.get_message` | 2476 |
| `Fnd_File.put_line` | 2654 |
| `Fnd_File.put_line` | 2655 |
| `Fnd_File.put_line` | 2661 |
| `dka_tools_pkg.get_message` | 2737 |
| `dka_tools_pkg.get_message` | 2755 |
| `fnd_profile.value` | 2764 |
| `dka_tools_pkg.get_message` | 2768 |
| `dka_tools_pkg.get_message` | 2787 |
| `dka_tools_pkg.get_message` | 2808 |
| `dka_tools_pkg.get_message` | 2827 |
| `dka_tools_pkg.get_message` | 2850 |
| `dka_tools_pkg.get_message` | 2869 |
| `dka_tools_pkg.get_message` | 2888 |
| `dka_tools_pkg.get_message` | 2906 |
| `dka_tools_pkg.get_message` | 2924 |
| `fnd_file.put_line` | 3008 |
| `fnd_file.put_line` | 3038 |
| `fnd_file.put_line` | 3043 |
| `Fnd_File.put_line` | 3343 |
| `DKA_IEOMTL_CODARTINT_PKG.get_category_id` | 3463 |
| `DKA_IEOMTL_CODARTINT_PKG.get_category_id` | 3506 |
| `DKA_IEOMTL_CODARTINT_PKG.get_category_id` | 3552 |
| `DKA_IEOMTL_CODARTINT_PKG.GET_ITEM_CATEGORY_SEC` | 3591 |
| `DKA_IEOMTL_CODARTINT_PKG.get_category_id` | 3597 |
| `DKA_IEOMTL_CODARTINT_PKG.get_item_category_sec` | 3636 |
| `DKA_IEOMTL_CODARTINT_PKG.get_category_id` | 3641 |
| `Fnd_File.put_line` | 3677 |
| `Fnd_File.put_line` | 3678 |
| `Fnd_File.put_line` | 3728 |
| `Fnd_Request.submit_request` | 3746 |
| `fnd_file.put_line` | 3759 |
| `fnd_file.put_line` | 3764 |
| `fnd_file.put_line` | 3767 |
| `fnd_file.put_line` | 3774 |
| `Fnd_Concurrent.wait_for_request` | 3777 |
| `Fnd_file.put_line` | 3780 |
| `fnd_file.put_line` | 3786 |
| `Fnd_File.put_line` | 3787 |
| `Fnd_File.put_line` | 3790 |
| `fnd_file.put_line` | 3796 |
| `Fnd_File.put_line` | 3799 |
| `Fnd_File.put_line` | 3800 |
| `Fnd_File.put_line` | 3807 |
| `Fnd_File.put_line` | 3936 |
| `Fnd_File.put_line` | 4250 |
| `Fnd_File.put_line` | 4251 |
| `Fnd_File.put_line` | 4252 |
| `Fnd_File.put_line` | 4253 |
| `Fnd_File.put_line` | 4254 |
| `Fnd_File.put_line` | 4255 |
| `Fnd_File.put_line` | 4256 |
| `Fnd_File.put_line` | 4257 |
| `Fnd_File.put_line` | 4258 |
| `Fnd_File.put_line` | 4703 |
| `Fnd_File.put_line` | 4711 |
| `Fnd_File.put_line` | 4712 |
| `Fnd_File.put_line` | 4713 |
| `Fnd_File.put_line` | 4714 |
| `Fnd_File.put_line` | 4796 |
| `Fnd_File.put_line` | 4799 |
| `Fnd_File.put_line` | 4802 |
| `Fnd_File.put_line` | 4869 |
| `Fnd_File.put_line` | 5134 |
| `Fnd_File.put_line` | 5250 |
| `Fnd_File.put_line` | 5251 |
| `Fnd_File.put_line` | 5252 |
| `fnd_stats.gather_table_stats` | 5254 |
| `fnd_file.put_line` | 5312 |
| `fnd_file.put_line` | 5357 |
| `fnd_request.submit_request` | 5373 |
| `fnd_file.put_line` | 5389 |
| `fnd_file.put_line` | 5394 |
| `fnd_file.put_line` | 5397 |
| `fnd_file.put_line` | 5405 |
| `Fnd_Concurrent.wait_for_request` | 5408 |
| `Fnd_file.put_line` | 5411 |
| `fnd_file.put_line` | 5417 |
| `Fnd_File.put_line` | 5418 |
| `Fnd_File.put_line` | 5421 |
| `fnd_file.put_line` | 5427 |
| `Fnd_File.put_line` | 5430 |
| `Fnd_File.put_line` | 5431 |
| `fnd_file.put_line` | 5461 |
| `fnd_request.submit_request` | 5477 |
| `fnd_file.put_line` | 5494 |
| `fnd_file.put_line` | 5499 |
| `fnd_file.put_line` | 5502 |
| `fnd_file.put_line` | 5510 |
| `Fnd_Concurrent.wait_for_request` | 5513 |
| `Fnd_file.put_line` | 5516 |
| `fnd_file.put_line` | 5522 |
| `Fnd_File.put_line` | 5523 |
| `Fnd_File.put_line` | 5526 |
| `fnd_file.put_line` | 5532 |
| `Fnd_File.put_line` | 5535 |
| `Fnd_File.put_line` | 5536 |
| `Fnd_File.put_line` | 5546 |
| `Fnd_File.put_line` | 5578 |
| `Fnd_File.put_line` | 5607 |
| `Fnd_File.put_line` | 5626 |
| `Fnd_File.put_line` | 5647 |
| `Fnd_File.put_line` | 5651 |
| `fnd_file.put_line` | 5656 |
| `Fnd_File.put_line` | 5678 |
| `Fnd_File.put_line` | 5754 |
| `fnd_file.put_line` | 5758 |
| `FND_FILE.PUT_LINE` | 5791 |
| `FND_FILE.PUT_LINE` | 5792 |
| `FND_FILE.PUT_LINE` | 5806 |
| `fnd_file.put_line` | 5814 |
| `FND_FILE.PUT_LINE` | 5827 |
| `fnd_file.put_line` | 5833 |
| `fnd_file.put_line` | 5860 |
| `FND_FILE.PUT_LINE` | 5876 |
| `DKA_IEOMTL_CODARTINT_PKG.CONTROLE_DONNEES` | 5880 |
| `FND_FILE.PUT_LINE` | 5889 |
| `FND_FILE.PUT_LINE` | 5896 |
| `FND_FILE.PUT_LINE` | 5909 |
| `FND_FILE.PUT_LINE` | 5914 |
| `FND_FILE.PUT_LINE` | 5929 |
| `FND_FILE.PUT_LINE` | 5946 |
| `FND_FILE.PUT_LINE` | 5958 |
| `DKA_IEOMTL_CODARTINT_PKG.check_items_oi` | 5962 |
| `FND_FILE.PUT_LINE` | 5972 |
| `FND_FILE.PUT_LINE` | 5997 |
| `DKA_IEOMTL_CODARTINT_PKG.check_items_oi` | 6001 |
| `FND_FILE.PUT_LINE` | 6012 |
| `FND_FILE.PUT_LINE` | 6028 |
| `FND_FILE.PUT_LINE` | 6044 |
| `FND_FILE.PUT_LINE` | 6053 |
| `FND_FILE.PUT_LINE` | 6059 |
| `Fnd_File.put_line` | 6087 |
| `Fnd_File.put_line` | 6088 |
| `Fnd_File.put_line` | 6089 |
| `Fnd_File.put_line` | 6090 |
| `fnd_file.put_line` | 6175 |
| `fnd_file.put_line` | 6176 |
| `fnd_file.put_line` | 6177 |
| `fnd_file.put_line` | 6178 |
| `fnd_file.put_line` | 6179 |
| `fnd_file.put_line` | 6180 |
| `fnd_file.put_line` | 6181 |
| `Fnd_File.put_line` | 6188 |
| `Fnd_File.put_line` | 6189 |
| `Fnd_File.put_line` | 6190 |
| `Fnd_File.put_line` | 6191 |
| `Fnd_File.put_line` | 6197 |
| `Fnd_File.put_line` | 6198 |
| `Fnd_File.put_line` | 6203 |
| `Fnd_File.put_line` | 6207 |
| `DKA_TOOLS_PKG.numeric_check` | 6235 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `INV_ITEM_CAT_ASSIGN_OI` | 3746 |
| `INCOIN` | 5373 |
| `INCOIN` | 5477 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 766, 777, 784, 1055, 1327, 2659, 3766, 5248, 5396, 5501, 5649, 5752 |
| transaction_autonome | 2689, 5781 |
| when_others | 266, 275, 284, 293, 302, 311, 320, 329, 338, 347, 356, 365, 374, 383, 392, 401, 410, 419, 428, 437, 446, 455, 464, 473, 482, 491, 500, 509, 518, 527, 536, 545, 554, 563, 572, 581, 590, 599, 608, 617, 626, 800, 915, 926, 1059, 1148, 1239, 1370, 1409, 1446, 1484, 1521, 1558, 1595, 1632, 1678, 1723, 1768, 1813, 1858, 1903, 1950, 1996, 2041, 2427, 2664, 2734, 2753, 2766, 2785, 2806, 2826, 2848, 2867, 2886, 2904, 2922, 2942, 2959, 2981, 3050, 3681, 3809, 4039, 4138, 4241, 4530, 4558, 4655, 4702, 4806, 5132, 5257, 5549, 5655, 5757, 6091, 6213, 6239 |
| suppression | 761, 771, 1008, 1025, 1046, 1138, 3018 |
| truncate | 209 |
| soumission | 3746, 5373, 5477 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IEOMTL_CODARTINT / DKA | `DKA_IEOMTL_CODARTINT_PKG.main` | dka/12.0.0/admin/import/DKA_IEOMTL_CODARTINT_PRG.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
