# DKA_SARENCAIS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARENCAIS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARENCAIS_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2641 ; encodage : cp1252 (repli). SHA-256 : `1b83651b82b0969a65efae0437c062ccb79ebefc9314c19ea65caa773ed64dc5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 89 |
| `get_ap_payments` | 198 |
| `get_ar_period_date_f` | 411 |
| `get_customer_partner` | 457 |
| `check_periods` | 560 |
| `maj_data` | 627 |
| `ecarter_fact` | 734 |
| `insert_ar_transmission` | 941 |
| `insert_ar_interface` | 1073 |
| `populate_data` | 1454 |
| `run_import` | 1713 |
| `run_all_imports` | 1936 |
| `tieback` | 2060 |
| `output_status` | 2156 |
| `create_output` | 2429 |
| `exec_sarencais_mail` | 2462 |
| `main` | 2515 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dka_sarencais_tmp` | 213 |
| `gl_ledgers` | 334 |
| `ap_checks_all` | 339 |
| `fnd_flex_value_sets` | 379 |
| `gl_period_statuses` | 421 |
| `hz_cust_site_uses_all` | 473 |
| `hz_cust_site_uses_all` | 510 |
| `gl_period_statuses` | 573 |
| `gl_period_statuses` | 586 |
| `ar_payments_interface_all` | 651 |
| `ra_customers` | 666 |
| `ra_customer_trx_all` | 677 |
| `ra_customer_trx_all` | 690 |
| `ar_payments_interface_all` | 745 |
| `ar_payments_interface_all` | 768 |
| `dka_sarencais_tmp` | 951 |
| `ar_transmission_formats` | 966 |
| `DUAL` | 978 |
| `ar_transmissions_all` | 980 |
| `DUAL` | 1011 |
| `dka_sarencais_tmp` | 1095 |
| `dka_sarencais_tmp` | 1108 |
| `dka_sarencais_tmp` | 1166 |
| `ar_receipt_methods` | 1192 |
| `ar_payments_interface_all` | 1204 |
| `DUAL` | 1255 |
| `DUAL` | 1310 |
| `ar_payments_interface_all` | 1315 |
| `DUAL` | 1388 |
| `ar_payments_interface_all` | 1398 |
| `dka_sarencais_tmp` | 1403 |
| `ap_checks_all` | 1413 |
| `dka_sarencais_tmp` | 1417 |
| `dka_sarencais_tmp` | 1459 |
| `fnd_flex_value_sets` | 1538 |
| `ra_customer_trx_all` | 1581 |
| `hr_operating_units` | 1605 |
| `hz_cust_site_uses_all` | 1623 |
| `dka_sarencais_tmp` | 1655 |
| `hr_operating_units` | 1668 |
| `dka_sarencais_tmp` | 1678 |
| `dka_sarencais_tmp` | 1679 |
| `dka_sarencais_tmp` | 1680 |
| `ar_transmissions_all` | 1749 |
| `ar_transmission_formats` | 1756 |
| `ar_lockboxes_all` | 1775 |
| `fnd_doc_sequence_assignments` | 1800 |
| `fnd_responsibility` | 1821 |
| `dka_sarencais_tmp` | 1898 |
| `dka_sarencais_tmp` | 1916 |
| `ar_transmissions_all` | 1947 |
| `dka_sarencais_tmp` | 2068 |
| `ar_cash_receipts_all` | 2071 |
| `ar_cash_receipts_all` | 2079 |
| `dka_sarencais_tmp` | 2091 |
| `ar_cash_receipts_all` | 2094 |
| `ar_cash_receipts_all` | 2102 |
| `dka_sarencais_tmp` | 2114 |
| `ar_payments_interface_all` | 2118 |
| `ar_interim_cash_receipts_all` | 2127 |
| `dka_sarencais_tmp` | 2169 |
| `dka_sarencais_tmp` | 2186 |
| `ar_payments_interface_all` | 2254 |
| `ar_payments_interface_all` | 2283 |
| `ar_interim_cash_receipts_all` | 2350 |
| `fnd_concurrent_programs` | 2477 |
| `fnd_concurrent_requests` | 2494 |
| `ar_autocash_hierarchies` | 2563 |
| `ar_system_parameters_all` | 2569 |
| `ar_autocash_hierarchies` | 2610 |
| `ar_system_parameters_all` | 2618 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_debug_message` | 98 |
| `Dka_Tools_Pkg.get_parameter` | 103 |
| `Dka_Tools_Pkg.put_debug_message` | 109 |
| `Dka_Tools_Pkg.get_parameter` | 116 |
| `Dka_Tools_Pkg.put_debug_message` | 122 |
| `Dka_Tools_Pkg.get_parameter` | 129 |
| `Dka_Tools_Pkg.put_debug_message` | 135 |
| `Dka_Tools_Pkg.get_parameter` | 142 |
| `Dka_Tools_Pkg.put_debug_message` | 148 |
| `Dka_Tools_Pkg.get_parameter` | 155 |
| `Dka_Tools_Pkg.put_debug_message` | 161 |
| `Dka_Tools_Pkg.put_debug_message` | 169 |
| `Dka_Tools_Pkg.put_debug_message` | 204 |
| `Dka_Tools_Pkg.put_debug_message` | 209 |
| `Dka_Tools_Pkg.put_debug_message` | 387 |
| `Dka_Tools_Pkg.put_debug_message` | 389 |
| `Dka_Tools_Pkg.put_debug_message` | 392 |
| `Dka_Tools_Pkg.put_debug_message` | 569 |
| `Dka_Tools_Pkg.put_debug_message` | 597 |
| `Dka_Tools_Pkg.put_debug_message` | 600 |
| `dka_tools_pkg.put_debug_message` | 648 |
| `Fnd_File.put_line` | 711 |
| `dka_tools_pkg.put_debug_message` | 714 |
| `dka_tools_pkg.put_debug_message` | 779 |
| `Fnd_File.put_line` | 782 |
| `Fnd_File.put_line` | 784 |
| `Fnd_File.NEW_LINE` | 785 |
| `Fnd_File.put_line` | 791 |
| `Fnd_File.put_line` | 795 |
| `Fnd_File.NEW_LINE` | 917 |
| `dka_tools_pkg.put_debug_message` | 919 |
| `Dka_Tools_Pkg.put_debug_message` | 961 |
| `Dka_Tools_Pkg.put_debug_message` | 1017 |
| `Dka_Sarencais_Pkg.insert_ar_interface` | 1025 |
| `Dka_Tools_Pkg.put_debug_message` | 1043 |
| `Dka_Tools_Pkg.put_debug_message` | 1046 |
| `Dka_Tools_Pkg.put_debug_message` | 1145 |
| `Dka_Tools_Pkg.put_debug_message` | 1173 |
| `Dka_Tools_Pkg.put_debug_message` | 1201 |
| `Dka_Tools_Pkg.put_debug_message` | 1257 |
| `Dka_Tools_Pkg.put_debug_message` | 1272 |
| `Dka_Tools_Pkg.put_debug_message` | 1293 |
| `Dka_Tools_Pkg.put_debug_message` | 1302 |
| `Dka_Tools_Pkg.put_debug_message` | 1303 |
| `Dka_Tools_Pkg.put_debug_message` | 1390 |
| `Fnd_Profile.value` | 1391 |
| `Dka_Tools_Pkg.put_debug_message` | 1424 |
| `Dka_Tools_Pkg.put_debug_message` | 1432 |
| `Dka_Tools_Pkg.put_debug_message` | 1435 |
| `Dka_Tools_Pkg.put_debug_message` | 1491 |
| `Dka_Tools_Pkg.put_debug_message` | 1502 |
| `Dka_Sarencais_Pkg.check_periods` | 1505 |
| `Dka_Tools_Pkg.put_debug_message` | 1523 |
| `Dka_Tools_Pkg.get_code_societe` | 1526 |
| `Dka_Tools_Pkg.put_debug_message` | 1569 |
| `Dka_Tools_Pkg.put_debug_message` | 1608 |
| `Dka_Tools_Pkg.put_debug_message` | 1640 |
| `Dka_Tools_Pkg.put_debug_message` | 1683 |
| `Dka_Tools_Pkg.put_debug_message` | 1686 |
| `Dka_Tools_Pkg.put_debug_message` | 1742 |
| `Dka_Tools_Pkg.put_debug_message` | 1745 |
| `Dka_Tools_Pkg.put_debug_message` | 1752 |
| `Dka_Tools_Pkg.get_code_societe` | 1761 |
| `Dka_Tools_Pkg.put_debug_message` | 1770 |
| `Dka_Tools_Pkg.put_debug_message` | 1794 |
| `Dka_Tools_Pkg.put_debug_message` | 1816 |
| `Fnd_Global.apps_initialize` | 1825 |
| `Dka_Tools_Pkg.put_debug_message` | 1836 |
| `Fnd_Request.SUBMIT_REQUEST` | 1839 |
| `Dka_Tools_Pkg.put_debug_message` | 1872 |
| `Fnd_File.put_line` | 1878 |
| `Fnd_File.put_line` | 1880 |
| `Fnd_File.put_line` | 1882 |
| `Fnd_File.put_line` | 1886 |
| `Fnd_File.put_line` | 1888 |
| `Fnd_File.put_line` | 1890 |
| `Dka_Tools_Pkg.put_debug_message` | 1892 |
| `Fnd_File.put_line` | 1904 |
| `Fnd_File.put_line` | 1906 |
| `Fnd_File.put_line` | 1908 |
| `Fnd_File.put_line` | 1911 |
| `Fnd_File.put_line` | 1913 |
| `Fnd_File.put_line` | 1915 |
| `Dka_Tools_Pkg.put_debug_message` | 1921 |
| `Dka_Tools_Pkg.put_debug_message` | 1968 |
| `Dka_Sarencais_Pkg.run_import` | 1981 |
| `Dka_Tools_Pkg.put_debug_message` | 1992 |
| `Dka_Tools_Pkg.put_debug_message` | 2000 |
| `Dka_Tools_Pkg.put_debug_message` | 2003 |
| `Fnd_Concurrent.wait_for_request` | 2015 |
| `Dka_Tools_Pkg.put_debug_message` | 2023 |
| `Dka_Tools_Pkg.put_debug_message` | 2025 |
| `Dka_Tools_Pkg.put_debug_message` | 2031 |
| `Dka_Tools_Pkg.put_debug_message` | 2034 |
| `Dka_Tools_Pkg.put_debug_message` | 2038 |
| `Dka_Tools_Pkg.put_debug_message` | 2065 |
| `Dka_Tools_Pkg.put_debug_message` | 2087 |
| `Dka_Tools_Pkg.put_debug_message` | 2110 |
| `Dka_Tools_Pkg.put_debug_message` | 2134 |
| `Dka_Tools_Pkg.put_debug_message` | 2136 |
| `Dka_Tools_Pkg.put_debug_message` | 2139 |
| `Dka_Tools_Pkg.put_debug_message` | 2208 |
| `Fnd_File.put_line` | 2221 |
| `Fnd_File.put_line` | 2223 |
| `Fnd_File.put_line` | 2225 |
| `Fnd_File.put_line` | 2227 |
| `Fnd_File.put_line` | 2233 |
| `Fnd_File.put_line` | 2238 |
| `Fnd_File.put_line` | 2335 |
| `Fnd_File.put_line` | 2387 |
| `Fnd_File.put_line` | 2396 |
| `Fnd_File.put_line` | 2399 |
| `Fnd_File.put_line` | 2401 |
| `Fnd_File.put_line` | 2404 |
| `Fnd_File.put_line` | 2406 |
| `Dka_Tools_Pkg.put_debug_message` | 2407 |
| `Dka_Tools_Pkg.put_debug_message` | 2412 |
| `Dka_Tools_Pkg.put_debug_message` | 2436 |
| `Dka_Sarencais_Pkg.output_status` | 2438 |
| `Dka_Tools_Pkg.put_debug_message` | 2443 |
| `Dka_Tools_Pkg.put_debug_message` | 2446 |
| `Dka_Tools_Pkg.put_debug_message` | 2483 |
| `fnd_request.submit_request` | 2486 |
| `Dka_Tools_Pkg.put_debug_message` | 2525 |
| `Dka_Sarencais_Pkg.init` | 2528 |
| `Dka_Sarencais_Pkg.get_ap_payments` | 2536 |
| `Dka_Sarencais_Pkg.populate_data` | 2544 |
| `Dka_Sarencais_Pkg.insert_ar_transmission` | 2552 |
| `Dka_Sarencais_Pkg.run_all_imports` | 2577 |
| `Dka_Tools_Pkg.put_debug_message` | 2585 |
| `Dka_Sarencais_Pkg.tieback` | 2586 |
| `Dka_Sarencais_Pkg.create_output` | 2602 |
| `Dka_Tools_Pkg.put_debug_message` | 2634 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `ARLPLB` | 1839 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1427, 1901, 1919, 2011, 2499, 2560, 2574, 2623 |
| when_others | 171, 391, 431, 540, 599, 669, 716, 921, 1033, 1045, 1301, 1434, 1549, 1598, 1636, 1685, 1787, 1812, 1920, 2037, 2138, 2411, 2445, 2481, 2633 |
| soumission | 1839, 2486 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARENCAIS / DKA | `dka_sarencais_pkg.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_F.prt:419 |
| DKA_SARENCAIS / DKA | `dka_sarencais_pkg.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_F.prt:419 |
| DKA_SARENCAIS / DKA | `dka_sarencais_pkg.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_US.prt:419 |
| DKA_SARENCAIS / DKA | `dka_sarencais_pkg.main` | dka/12.0.0/admin/import/DKA_SARENCAIS_US.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
