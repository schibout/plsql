# DKA_ICLIENTIFS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_ICLIENTIFS_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3273 ; encodage : cp1252 (repli). SHA-256 : `c2145beec31274e599451f465446cad78f3f7df7d69420bbb6d875850b1d97ad`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `alim_oi` | 391 |
| `global_control` | 796 |
| `get_gl_id` | 1009 |
| `update_collectors` | 1124 |
| `update_site_gl_id` | 1248 |
| `init` | 1325 |
| `delete_duplicate_data` | 1557 |
| `show_rejected_records` | 1594 |
| `get_collector_from_cust_cdg` | 1670 |
| `rejected_lines_exist` | 1719 |
| `customer_exists` | 1753 |
| `address_exists` | 1783 |
| `Launch_OI` | 1822 |
| `pre_oi` | 1951 |
| `IN_OI` | 2311 |
| `post_OI` | 2339 |
| `pre_import_client` | 2914 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_ICLIENTIFS_INTERFACE` | 310 |
| `fnd_flex_values` | 315 |
| `DKA_ICLIENTIFS_INTERFACE` | 322 |
| `fnd_flex_values` | 327 |
| `DKA_ICLIENTIFS_INTERFACE` | 335 |
| `dka_ICLIENTIFS_COLLECTORS` | 341 |
| `hr_operating_units` | 349 |
| `dka_iclientifs_interface` | 354 |
| `hr_operating_units` | 359 |
| `dka_iclientifs_collectors` | 368 |
| `ra_customers_interface_all` | 402 |
| `dka_iclientifs_interface` | 404 |
| `ra_customers_interface_all` | 411 |
| `hz_customer_profiles` | 478 |
| `hr_operating_units` | 487 |
| `hz_customer_profiles` | 502 |
| `hr_operating_units` | 512 |
| `hr_operating_units` | 522 |
| `hz_cust_acct_sites_all` | 530 |
| `hr_operating_units` | 533 |
| `hz_customer_profiles` | 544 |
| `hr_operating_units` | 553 |
| `hz_customer_profiles` | 563 |
| `hr_operating_units` | 572 |
| `dka_iclientifs_interface` | 580 |
| `ra_customer_profiles_int_all` | 589 |
| `dka_iclientifs_interface` | 591 |
| `ra_customer_profiles_int_all` | 598 |
| `hz_customer_profiles` | 631 |
| `hr_operating_units` | 641 |
| `hr_operating_units` | 652 |
| `hz_cust_acct_sites_all` | 659 |
| `dka_iclientifs_interface` | 667 |
| `ra_customer_profiles_int_all` | 674 |
| `hr_operating_units` | 709 |
| `dka_iclientifs_interface` | 717 |
| `des` | 726 |
| `ra_customers_interface_all` | 727 |
| `hr_operating_units` | 765 |
| `dka_iclientifs_interface` | 771 |
| `dka_iclientifs_interface` | 802 |
| `dka_iclientifs_collectors` | 810 |
| `dka_iclientifs_interface` | 819 |
| `dka_iclientifs_interface` | 829 |
| `ar_lookups` | 837 |
| `dka_iclientifs_interface` | 845 |
| `dka_iclientifs_interface` | 856 |
| `dka_iclientifs_interface` | 867 |
| `dka_iclientifs_interface` | 874 |
| `hz_cust_accounts` | 879 |
| `dka_iclientifs_interface` | 885 |
| `dka_iclientifs_interface` | 892 |
| `hz_cust_acct_sites_all` | 897 |
| `dka_iclientifs_collectors` | 904 |
| `ar_collectors` | 911 |
| `dka_iclientifs_collectors` | 916 |
| `fnd_flex_values` | 924 |
| `dka_iclientifs_collectors` | 930 |
| `dka_iclientifs_interface` | 937 |
| `hz_cust_accounts` | 942 |
| `dka_iclientifs_interface` | 948 |
| `dka_iclientifs_interface` | 956 |
| `hz_cust_acct_sites_all` | 959 |
| `dka_iclientifs_interface` | 970 |
| `dka_iclientifs_collectors` | 977 |
| `dka_iclientifs_interface` | 980 |
| `gl_ledgers` | 1031 |
| `gl_ledgers` | 1072 |
| `dka_iclientifs_interface` | 1142 |
| `fnd_flex_values` | 1152 |
| `OF` | 1172 |
| `dka_iclientifs_interface` | 1205 |
| `hz_cust_site_uses_all` | 1215 |
| `hz_customer_profiles` | 1228 |
| `hr_operating_units` | 1255 |
| `hr_operating_units` | 1258 |
| `hr_operating_units` | 1261 |
| `hz_cust_acct_sites_all` | 1264 |
| `dka_iclientifs_interface` | 1294 |
| `hr_operating_units` | 1303 |
| `hz_cust_site_uses_all` | 1306 |
| `dka_iclientifs_interface` | 1564 |
| `dka_iclientifs_collectors` | 1577 |
| `hr_operating_units` | 1679 |
| `dka_iclientifs_collectors` | 1684 |
| `ar_collectors` | 1699 |
| `dka_iclientifs_interface` | 1725 |
| `dka_iclientifs_collectors` | 1734 |
| `hz_cust_accounts` | 1761 |
| `hz_cust_site_uses_all` | 1794 |
| `hr_operating_units` | 2012 |
| `dka_iclientifs_interface` | 2044 |
| `dka_iclientifs_interface` | 2117 |
| `dka_iclientifs_interface` | 2134 |
| `de` | 2145 |
| `hz_cust_acct_sites_all` | 2161 |
| `ar_customers` | 2164 |
| `hz_cust_acct_relate_all` | 2190 |
| `ar_customers` | 2195 |
| `ar_customers` | 2199 |
| `hz_cust_acct_relate_all` | 2207 |
| `ar_customers` | 2212 |
| `ar_customers` | 2216 |
| `hz_cust_site_uses_all` | 2232 |
| `hz_cust_acct_sites_all` | 2241 |
| `dka_iclientifs_collectors` | 2271 |
| `dka_iclientifs_interface` | 2274 |
| `dka_iclientifs_interface` | 2278 |
| `hz_cust_site_uses_all` | 2358 |
| `dka_iclientifs_interface` | 2364 |
| `fnd_flex_values` | 2372 |
| `hz_cust_site_uses_all` | 2392 |
| `dka_iclientifs_interface` | 2398 |
| `fnd_flex_values` | 2406 |
| `hz_cust_site_uses_all` | 2427 |
| `dka_iclientifs_interface` | 2432 |
| `fnd_flex_values` | 2439 |
| `hz_cust_acct_sites_all` | 2454 |
| `DKA_ICLIENTIFS_INTERFACE` | 2464 |
| `DKA_ICLIENTIFS_INTERFACE` | 2472 |
| `fnd_flex_values` | 2477 |
| `hz_cust_site_uses_all` | 2484 |
| `hz_locations` | 2489 |
| `dka_iclientifs_interface` | 2492 |
| `DKA_ICLIENTIFS_INTERFACE` | 2497 |
| `fnd_flex_values` | 2502 |
| `hz_cust_site_uses_all` | 2510 |
| `dka_iclientifs_collectors` | 2515 |
| `dka_iclientifs_interface` | 2518 |
| `fnd_flex_values` | 2525 |
| `hz_cust_site_uses_all` | 2534 |
| `hz_cust_acct_relate_all` | 2544 |
| `hz_cust_accounts` | 2548 |
| `fnd_flex_values` | 2555 |
| `hz_cust_acct_sites_all` | 2770 |
| `hz_cust_accounts_all` | 2773 |
| `hz_cust_acct_sites_all` | 2825 |
| `hz_cust_acct_sites_all` | 2844 |
| `hz_cust_acct_sites_all` | 2855 |
| `hz_cust_acct_relate_all` | 2869 |
| `hz_cust_acct_relate_all` | 2874 |
| `hz_cust_acct_sites_all` | 2885 |
| `dka_iclientifs_interface` | 2891 |
| `dka_iarpafac_interface` | 2918 |
| `hz_cust_acct_sites_all` | 2922 |
| `hz_cust_acct_sites_all` | 2933 |
| `dka_iclientifs_interface` | 2997 |
| `ra_customers_interface_all` | 3004 |
| `hz_cust_acct_sites_all` | 3063 |
| `hz_cust_acct_sites_all` | 3142 |
| `dka.dka_iclientifs_interface` | 3182 |
| `dka_iclientifs_collectors` | 3237 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_outdebug_message` | 393 |
| `dka_tools_pkg.put_outdebug_message` | 394 |
| `dka_tools_pkg.put_outdebug_message` | 399 |
| `Dka_Tools_Pkg.put_debug_message` | 409 |
| `dka_tools_pkg.put_outdebug_message` | 586 |
| `Dka_Tools_Pkg.put_debug_message` | 596 |
| `dka_tools_pkg.put_outdebug_message` | 673 |
| `dka_tools_pkg.put_outdebug_message` | 726 |
| `dka_tools_pkg.put_outdebug_message` | 782 |
| `dka_tools_pkg.put_outdebug_message` | 783 |
| `dka_tools_pkg.put_debug_message` | 799 |
| `dka_tools_pkg.put_debug_message` | 801 |
| `dka_tools_pkg.put_debug_message` | 808 |
| `dka_tools_pkg.put_debug_message` | 817 |
| `dka_tools_pkg.put_debug_message` | 827 |
| `dka_tools_pkg.put_debug_message` | 843 |
| `dka_tools_pkg.put_debug_message` | 854 |
| `dka_tools_pkg.put_debug_message` | 865 |
| `dka_tools_pkg.put_debug_message` | 883 |
| `dka_tools_pkg.put_debug_message` | 901 |
| `dka_tools_pkg.put_debug_message` | 914 |
| `dka_tools_pkg.put_debug_message` | 928 |
| `dka_tools_pkg.put_debug_message` | 946 |
| `dka_tools_pkg.put_debug_message` | 968 |
| `dka_tools_pkg.put_debug_message` | 979 |
| `dka_tools_pkg.put_debug_message` | 991 |
| `dka_tools_pkg.put_debug_message` | 1020 |
| `dka_tools_pkg.get_code_combination_id` | 1047 |
| `dka_tools_pkg.put_outdebug_message` | 1063 |
| `dka_tools_pkg.get_code_combination_id` | 1089 |
| `dka_tools_pkg.put_outdebug_message` | 1105 |
| `dka_tools_pkg.put_debug_message` | 1337 |
| `dka_tools_pkg.get_parameter` | 1343 |
| `dka_tools_pkg.get_parameter` | 1354 |
| `dka_tools_pkg.get_parameter` | 1365 |
| `dka_tools_pkg.get_parameter` | 1376 |
| `dka_tools_pkg.get_parameter` | 1387 |
| `dka_tools_pkg.get_parameter` | 1398 |
| `dka_tools_pkg.get_parameter` | 1409 |
| `dka_tools_pkg.get_parameter` | 1420 |
| `dka_tools_pkg.get_parameter` | 1431 |
| `dka_tools_pkg.get_parameter` | 1442 |
| `dka_tools_pkg.get_parameter` | 1453 |
| `dka_tools_pkg.get_parameter` | 1464 |
| `dka_tools_pkg.get_parameter` | 1475 |
| `dka_tools_pkg.get_parameter` | 1486 |
| `dka_tools_pkg.get_flex_key_seg_value_set` | 1503 |
| `dka_tools_pkg.get_flex_key_seg_value_set` | 1522 |
| `Dka_Tools_Pkg.put_debug_message` | 1573 |
| `Dka_Tools_Pkg.put_debug_message` | 1583 |
| `dka_tools_pkg.put_outdebug_message` | 1596 |
| `dka_tools_pkg.put_outdebug_message` | 1597 |
| `dka_tools_pkg.put_outdebug_message` | 1600 |
| `dka_tools_pkg.put_outdebug_message` | 1605 |
| `dka_tools_pkg.ins_prog_message` | 1611 |
| `dka_tools_pkg.put_outdebug_message` | 1623 |
| `dka_tools_pkg.put_outdebug_message` | 1624 |
| `dka_tools_pkg.put_outdebug_message` | 1626 |
| `dka_tools_pkg.put_outdebug_message` | 1627 |
| `dka_tools_pkg.put_outdebug_message` | 1631 |
| `dka_tools_pkg.put_outdebug_message` | 1636 |
| `dka_tools_pkg.ins_prog_message` | 1643 |
| `fnd_file.put_line` | 1834 |
| `fnd_file.put_line` | 1837 |
| `fnd_file.put_line` | 1841 |
| `fnd_file.put_line` | 1842 |
| `fnd_file.put_line` | 1844 |
| `fnd_request.submit_request` | 1850 |
| `fnd_file.put_line` | 1868 |
| `fnd_file.put_line` | 1871 |
| `fnd_file.put_line` | 1872 |
| `fnd_file.put_line` | 1876 |
| `fnd_file.put_line` | 1878 |
| `fnd_concurrent.wait_for_request` | 1883 |
| `fnd_file.put_line` | 1892 |
| `fnd_file.put_line` | 1898 |
| `fnd_file.put_line` | 1901 |
| `fnd_file.put_line` | 1906 |
| `fnd_file.put_line` | 1916 |
| `fnd_file.put_line` | 1922 |
| `fnd_file.put_line` | 1929 |
| `fnd_file.put_line` | 1937 |
| `fnd_file.put_line` | 1938 |
| `dka_tools_pkg.put_outdebug_message` | 1969 |
| `dka_tools_pkg.put_debug_message` | 1975 |
| `dka_tools_pkg.put_debug_message` | 1989 |
| `dka_tools_pkg.put_debug_message` | 1999 |
| `dka_tools_pkg.put_debug_message` | 2004 |
| `dka_tools_pkg.put_outdebug_message` | 2023 |
| `dka_tools_pkg.put_debug_message` | 2037 |
| `dka_tools_pkg.put_debug_message` | 2038 |
| `Dka_Tools_Pkg.put_debug_message` | 2039 |
| `dka_tools_pkg.put_debug_message` | 2091 |
| `dka_tools_pkg.put_debug_message` | 2105 |
| `dka_tools_pkg.put_debug_message` | 2145 |
| `dka_tools_pkg.put_debug_message` | 2174 |
| `dka_tools_pkg.put_debug_message` | 2180 |
| `dka_tools_pkg.put_debug_message` | 2202 |
| `dka_tools_pkg.put_debug_message` | 2220 |
| `dka_tools_pkg.put_log_message` | 2294 |
| `Fnd_File.put_line` | 2318 |
| `Fnd_File.put_line` | 2319 |
| `dka_tools_pkg.put_outdebug_message` | 2348 |
| `dka_tools_pkg.put_outdebug_message` | 2352 |
| `dka_tools_pkg.put_outdebug_message` | 2761 |
| `dka_tools_pkg.put_debug_message` | 2765 |
| `Dka_Tools_Pkg.PUT_OUTDEBUG_MESSAGE` | 2786 |
| `dka_tools_pkg.put_debug_message` | 2863 |
| `dka_tools_pkg.put_outdebug_message` | 2867 |
| `dka_tools_pkg.put_debug_message` | 2897 |
| `dka_tools_pkg.put_outdebug_message` | 2902 |
| `dka_tools_pkg.put_outdebug_message` | 2905 |
| `dka_tools_pkg.put_log_message` | 3246 |
| `dka_tools_pkg.put_log_message` | 3254 |
| `dka_tools_pkg.put_log_message` | 3267 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `RACUSTMA` | 1850 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 989, 1875, 2258 |
| when_others | 1046, 1088, 1547, 1586, 1704, 1764, 1798, 1934, 2179, 2291, 3264 |
| suppression | 402, 589, 2271, 2278 |
| soumission | 1850 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_ICLIENTIFS_1 / DKA | `dka_iclientifs_pkg.pre_oi` | dka/12.0.0/admin/import/DKA_ICLIENTIFS_1.prt:404 |
| DKA_ICLIENTIFS_2 / DKA | `dka_iclientifs_pkg.post_oi` | dka/12.0.0/admin/import/DKA_ICLIENTIFS_2.prt:404 |
| DKA_ICLIENTIFS_3 / DKA | `dka_iclientifs_pkg.IN_OI` | dka/12.0.0/admin/import/DKA_ICLIENTIFS_3.prt:419 |
| DKA_ICLIENTIFS_4 / DKA | `DKA_ICLIENTIFS_PKG.pre_import_client` | dka/12.0.0/admin/import/DKA_ICLIENTIFS_4.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
