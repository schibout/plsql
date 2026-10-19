# DKA_IMPTRECPO_PKG.PKB

Source : [dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB](../../dka/12.0.0/admin/sql/DKA_IMPTRECPO_PKG.PKB).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2396 ; encodage : cp1252 (repli). SHA-256 : `56986c5009ea6b3e38c14ee184933b76743ffdc8ebaa569a02a30229d2b7f6e0`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 96 |
| `Request_parameters` | 149 |
| `output_end` | 239 |
| `Add_Message` | 267 |
| `get_organization_id` | 348 |
| `GET_VENDOR_SITE_ID` | 379 |
| `update_region_societe` | 422 |
| `init` | 480 |
| `validate_data` | 591 |
| `import_data` | 1165 |
| `Launch_OI` | 1631 |
| `Launch_Loader` | 1815 |
| `Report_Bilan` | 1934 |
| `set_recovery_mode` | 2002 |
| `init_status_oi` | 2037 |
| `purge_data` | 2162 |
| `main` | 2211 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 111 |
| `fnd_concurrent_requests` | 155 |
| `fnd_concurrent_requests` | 186 |
| `fnd_concurrent_requests` | 203 |
| `dka_program_messages` | 293 |
| `hr_operating_units` | 361 |
| `AP_SUPPLIERS` | 390 |
| `dka.DKA_RCV_HEADERS_TMP` | 431 |
| `po_headers_all` | 433 |
| `po_headers_all` | 437 |
| `dka.DKA_RCV_TRANSACTIONS_TMP` | 441 |
| `po_headers_all` | 443 |
| `po_headers_all` | 447 |
| `fnd_concurrent_requests` | 542 |
| `dka.DKA_RCV_HEADERS_TMP` | 623 |
| `OF` | 628 |
| `dka.DKA_RCV_TRANSACTIONS_TMP` | 634 |
| `OF` | 639 |
| `DKA_RCV_TRANSACTIONS_TMP` | 650 |
| `hr_operating_units` | 651 |
| `DKA_RCV_TRANSACTIONS_TMP` | 654 |
| `po_headers_all` | 656 |
| `DKA_RCV_TRANSACTIONS_TMP` | 661 |
| `po_lines_all` | 663 |
| `DKA_RCV_TRANSACTIONS_TMP` | 668 |
| `po_line_locations_all` | 670 |
| `DKA_RCV_TRANSACTIONS_TMP` | 677 |
| `po_distributions_all` | 679 |
| `apps.PER_ALL_PEOPLE_F` | 722 |
| `PO_VENDOR_SITES_ALL` | 735 |
| `po_distributions_all` | 804 |
| `PO_VENDOR_SITES_ALL` | 916 |
| `po_line_locations_all` | 947 |
| `HR_LOCATIONS_ALL` | 982 |
| `PO_DISTRIBUTIONS_ALL` | 989 |
| `PO_LINE_LOCATIONS_ALL` | 1003 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1041 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1057 |
| `DKA_RCV_HEADERS_TMP` | 1078 |
| `DKA_RCV_HEADERS_TMP` | 1086 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1095 |
| `DKA_RCV_HEADERS_TMP` | 1106 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1108 |
| `DKA_RCV_HEADERS_TMP` | 1122 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1124 |
| `DKA_RCV_HEADERS_TMP` | 1181 |
| `OF` | 1185 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1191 |
| `OF` | 1196 |
| `dual` | 1213 |
| `dual` | 1228 |
| `DUAL` | 1235 |
| `rcv_headers_interface` | 1238 |
| `DUAL` | 1295 |
| `rcv_transactions_interface` | 1298 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1432 |
| `DKA_RCV_HEADERS_TMP` | 1585 |
| `rcv_headers_interface` | 1668 |
| `DKA_RCV_HEADERS_TMP` | 1876 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1882 |
| `DKA_RCV_HEADERS_TMP` | 1953 |
| `DKA_RCV_TRANSACTIONS_TMP` | 1959 |
| `DKA_RCV_HEADERS_TMP` | 2012 |
| `DKA_RCV_TRANSACTIONS_TMP` | 2017 |
| `rcv_headers_interface` | 2045 |
| `rcv_shipment_headers` | 2048 |
| `rcv_shipment_headers` | 2059 |
| `rcv_shipment_headers` | 2064 |
| `rcv_shipment_lines` | 2065 |
| `Rcv_Headers_Interface` | 2072 |
| `rcv_shipment_headers` | 2074 |
| `dka_rcv_headers_tmp` | 2086 |
| `rcv_transactions_interface` | 2095 |
| `dka_rcv_transactions_tmp` | 2126 |
| `DKA_RCV_HEADERS_TMP` | 2174 |
| `DKA_RCV_TRANSACTIONS_TMP` | 2180 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 126 |
| `Fnd_File.put_line` | 127 |
| `Fnd_File.put_line` | 128 |
| `Fnd_File.put_line` | 129 |
| `Fnd_File.put_line` | 130 |
| `Fnd_File.put_line` | 171 |
| `Fnd_File.put_line` | 172 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 174 |
| `Fnd_File.put_line` | 191 |
| `Fnd_File.put_line` | 192 |
| `Fnd_File.put_line` | 208 |
| `Fnd_File.put_line` | 209 |
| `Fnd_File.put_line` | 212 |
| `Fnd_File.put_line` | 215 |
| `Fnd_File.put_line` | 216 |
| `Fnd_File.put_line` | 246 |
| `Fnd_File.put_line` | 247 |
| `Fnd_File.put_line` | 248 |
| `Fnd_File.put_line` | 278 |
| `Fnd_File.put_line` | 280 |
| `Fnd_File.put_line` | 282 |
| `Fnd_File.put_line` | 284 |
| `Fnd_File.put_line` | 290 |
| `Fnd_File.Put_Line` | 429 |
| `Fnd_File.Put_Line` | 452 |
| `Fnd_File.put_line` | 459 |
| `Fnd_File.put_line` | 460 |
| `Fnd_File.put_line` | 495 |
| `fnd_date.canonical_to_date` | 533 |
| `Fnd_File.put_line` | 535 |
| `Fnd_File.put_line` | 547 |
| `Dka_Tools_Pkg.get_parameter` | 553 |
| `fnd_file.put_line` | 566 |
| `Fnd_File.put_line` | 644 |
| `Fnd_File.put_line` | 645 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 965 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 971 |
| `fnd_file.put_line` | 1117 |
| `Fnd_File.put_line` | 1134 |
| `Fnd_File.put_line` | 1142 |
| `Fnd_File.put_line` | 1143 |
| `fnd_file.put_line` | 1440 |
| `fnd_file.put_line` | 1591 |
| `Fnd_File.put_line` | 1598 |
| `Fnd_File.put_line` | 1605 |
| `Fnd_File.put_line` | 1606 |
| `Fnd_File.put_line` | 1651 |
| `Fnd_File.put_line` | 1652 |
| `fnd_file.put_line` | 1655 |
| `fnd_file.put_line` | 1656 |
| `fnd_file.put_line` | 1657 |
| `fnd_stats.gather_table_stats` | 1660 |
| `fnd_stats.gather_table_stats` | 1661 |
| `fnd_request.set_print_options` | 1673 |
| `fnd_request.submit_request` | 1677 |
| `fnd_file.put_line` | 1689 |
| `Fnd_File.put_line` | 1691 |
| `Fnd_File.put_line` | 1696 |
| `Fnd_File.put_line` | 1697 |
| `Fnd_Concurrent.wait_for_request` | 1756 |
| `Fnd_file.put_line` | 1759 |
| `Fnd_File.put_line` | 1765 |
| `Fnd_File.put_line` | 1766 |
| `Fnd_File.put_line` | 1770 |
| `fnd_file.put_line` | 1778 |
| `Fnd_File.put_line` | 1781 |
| `Fnd_File.put_line` | 1785 |
| `Fnd_File.put_line` | 1792 |
| `Fnd_File.put_line` | 1793 |
| `Fnd_File.put_line` | 1827 |
| `Fnd_File.put_line` | 1828 |
| `fnd_file.put_line` | 1831 |
| `fnd_file.put_line` | 1832 |
| `fnd_file.put_line` | 1833 |
| `fnd_request.set_print_options` | 1838 |
| `Fnd_Request.submit_request` | 1841 |
| `fnd_file.put_line` | 1852 |
| `Fnd_File.put_line` | 1855 |
| `Fnd_File.put_line` | 1858 |
| `Fnd_File.put_line` | 1859 |
| `Fnd_Concurrent.wait_for_request` | 1862 |
| `Fnd_file.put_line` | 1865 |
| `Fnd_File.put_line` | 1871 |
| `Fnd_File.put_line` | 1872 |
| `Fnd_File.put_line` | 1888 |
| `fnd_file.put_line` | 1896 |
| `Fnd_File.put_line` | 1899 |
| `fnd_stats.gather_table_stats` | 1905 |
| `fnd_stats.gather_table_stats` | 1906 |
| `Fnd_File.put_line` | 1908 |
| `Fnd_File.put_line` | 1915 |
| `Fnd_File.put_line` | 1916 |
| `Fnd_File.put_line` | 1941 |
| `fnd_file.put_line` | 1963 |
| `fnd_file.put_line` | 1964 |
| `fnd_file.put_line` | 1965 |
| `fnd_file.put_line` | 1967 |
| `fnd_file.put_line` | 1968 |
| `fnd_file.put_line` | 1971 |
| `fnd_file.put_line` | 1972 |
| `fnd_file.put_line` | 1974 |
| `fnd_file.put_line` | 1975 |
| `fnd_file.put_line` | 1977 |
| `Fnd_File.put_line` | 1978 |
| `Fnd_File.put_line` | 1986 |
| `Fnd_File.put_line` | 1987 |
| `Fnd_File.put_line` | 2028 |
| `Fnd_File.put_line` | 2029 |
| `Fnd_File.Put_Line` | 2043 |
| `Fnd_File.Put_Line` | 2137 |
| `Fnd_File.Put_Line` | 2138 |
| `Fnd_File.put_line` | 2146 |
| `Fnd_File.put_line` | 2147 |
| `Fnd_File.Put_Line` | 2170 |
| `Fnd_File.Put_Line` | 2177 |
| `Fnd_File.Put_Line` | 2179 |
| `Fnd_File.Put_Line` | 2183 |
| `Fnd_File.put_line` | 2191 |
| `Fnd_File.put_line` | 2192 |
| `Fnd_File.put_line` | 2232 |
| `Fnd_File.put_line` | 2238 |
| `Fnd_File.put_line` | 2256 |
| `Fnd_File.put_line` | 2270 |
| `Fnd_File.put_line` | 2330 |
| `Fnd_File.put_line` | 2368 |
| `Fnd_File.put_line` | 2369 |
| `Fnd_File.put_line` | 2371 |
| `Fnd_File.put_line` | 2379 |
| `Fnd_File.put_line` | 2380 |
| `Fnd_File.put_line` | 2381 |
| `Fnd_File.put_line` | 2382 |
| `Fnd_File.put_line` | 2387 |
| `Fnd_File.put_line` | 2388 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `RVCTP` | 1677 |
| `DKA_LOADER_REPRECPOIMP` | 1841 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 687, 1136, 1599, 1695, 1857, 2140, 2365 |
| rollback | 1120, 1609 |
| when_others | 119, 400, 455, 568, 728, 741, 823, 922, 954, 985, 997, 1010, 1116, 1139, 1439, 1590, 1602, 1788, 1911, 1982, 2024, 2143, 2187, 2383 |
| suppression | 2174, 2180 |
| soumission | 1677, 1841 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IMPTRECPO / DKA | `DKA_IMPTRECPO_PKG.MAIN` | dka/12.0.0/admin/import/DKA_IMPTRECPO.prt:455 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
