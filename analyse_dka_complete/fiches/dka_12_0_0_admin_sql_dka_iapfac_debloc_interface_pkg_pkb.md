# DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB

Source : [dka/12.0.0/admin/sql/DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB](../../dka/12.0.0/admin/sql/DKA_IAPFAC_DEBLOC_INTERFACE_PKG.PKB).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2912 ; encodage : cp1252 (repli). SHA-256 : `b58248bcd0dc58a510c651bcfcc524370403f42d18b04053e4b09431636feba9`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 94 |
| `Request_parameters` | 148 |
| `output_end` | 243 |
| `Add_Message` | 271 |
| `get_organization_id` | 307 |
| `GET_VENDOR_SITE_ID` | 338 |
| `init` | 386 |
| `validate_data_group` | 488 |
| `validate_data` | 1238 |
| `trt_data` | 1387 |
| `Launch_Loader` | 2247 |
| `Report_Bilan` | 2421 |
| `purge_data` | 2564 |
| `Rec_enreg_remp` | 2635 |
| `main` | 2691 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 109 |
| `fnd_concurrent_requests` | 154 |
| `fnd_concurrent_requests` | 188 |
| `fnd_concurrent_requests` | 205 |
| `ap_invoices_all` | 294 |
| `hr_operating_units` | 320 |
| `AP_SUPPLIERS` | 349 |
| `fnd_concurrent_requests` | 452 |
| `dka.DKA_IAPFAC_DEBLOC_INTERFACE` | 542 |
| `OF` | 548 |
| `ap_invoices_all` | 565 |
| `ap_invoices_all` | 574 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 596 |
| `ap_invoices_all` | 605 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 625 |
| `ap_holds_all` | 636 |
| `ap_holds_all` | 646 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 668 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 698 |
| `ap_invoices_all` | 706 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 725 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 749 |
| `DKA_STRANSCO_LINES` | 757 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 785 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 808 |
| `ap_holds_all` | 817 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 837 |
| `ap_holds_all` | 847 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 868 |
| `ap_holds_all` | 876 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 897 |
| `ap_holds_all` | 905 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 932 |
| `ap_holds_all` | 940 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 960 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 984 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1023 |
| `ap_holds_all` | 1034 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1066 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1090 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1109 |
| `ap_holds_all` | 1119 |
| `ap_holds_all` | 1128 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1149 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1172 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1192 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1199 |
| `dka.DKA_IAPFAC_DEBLOC_INTERFACE` | 1287 |
| `dka.DKA_IAPFAC_DEBLOC_INTERFACE` | 1297 |
| `OF` | 1302 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1321 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1346 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1425 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1436 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1448 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1460 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1471 |
| `FND_USER` | 1481 |
| `ap_holds_all` | 1492 |
| `AP_HOLD_CODES_V` | 1495 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1516 |
| `ap_invoices_all` | 1523 |
| `fnd_lookup_values_vl` | 1527 |
| `dual` | 1547 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1570 |
| `ap_holds_all` | 1575 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1599 |
| `ap_holds_all` | 1607 |
| `ap_invoices_all` | 1618 |
| `AP_INVOICE_LINES_ALL` | 1625 |
| `ap_invoices_all` | 1629 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1647 |
| `fnd_user` | 1652 |
| `dual` | 1670 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1692 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1699 |
| `ap_invoices_all` | 1716 |
| `DKA_STRANSCO_LINES` | 1722 |
| `ap_holds_all` | 1733 |
| `AP_HOLD_CODES_V` | 1747 |
| `ap_holds_all` | 1768 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1791 |
| `ap_invoices_all` | 1799 |
| `fnd_lookup_values_vl` | 1802 |
| `dual` | 1822 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1845 |
| `ap_holds_all` | 1850 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1863 |
| `ap_invoices_all` | 1882 |
| `fnd_lookup_values_vl` | 1885 |
| `dual` | 1905 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1928 |
| `ap_holds_all` | 1934 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 1948 |
| `ap_invoices_all` | 1967 |
| `fnd_lookup_values_vl` | 1970 |
| `dual` | 1992 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2013 |
| `ap_holds_all` | 2018 |
| `dual` | 2040 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2081 |
| `ap_holds_all` | 2087 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2099 |
| `ap_invoices_all` | 2119 |
| `fnd_lookup_values_vl` | 2122 |
| `dual` | 2142 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2163 |
| `ap_holds_all` | 2169 |
| `ap_holds_all` | 2183 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2201 |
| `DKA_IAPFAC_DEBLOC_HIST_INTERF` | 2311 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2312 |
| `fnd_new_messages` | 2322 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2331 |
| `DKA_IAPFAC_DEBLOC_REPOR_INTERF` | 2341 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2342 |
| `fnd_new_messages` | 2352 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2360 |
| `DKA_IAPFAC_DEBLOC_HIST_INTERF` | 2363 |
| `dka_program_messages` | 2426 |
| `dka_program_messages` | 2437 |
| `DKA_IAPFAC_DEBLOC_REPOR_INTERF` | 2462 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2464 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2468 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2478 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2484 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2490 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2496 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2500 |
| `dual` | 2507 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2580 |
| `dka_program_messages` | 2609 |
| `DKA_IAPFAC_DEBLOC_REPOR_INTERF` | 2644 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2647 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2654 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2657 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2707 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2778 |
| `DKA_IAPFAC_DEBLOC_HIST_INTERF` | 2809 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2810 |
| `DKA_IAPFAC_DEBLOC_REPOR_INTERF` | 2812 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2813 |
| `DKA_IAPFAC_DEBLOC_INTERFACE` | 2815 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 124 |
| `Fnd_File.put_line` | 125 |
| `Fnd_File.put_line` | 126 |
| `Fnd_File.put_line` | 127 |
| `Fnd_File.put_line` | 128 |
| `Fnd_File.put_line` | 170 |
| `Fnd_File.put_line` | 171 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 174 |
| `Fnd_File.put_line` | 194 |
| `Fnd_File.put_line` | 195 |
| `Fnd_File.put_line` | 211 |
| `Fnd_File.put_line` | 212 |
| `Fnd_File.put_line` | 219 |
| `Fnd_File.put_line` | 223 |
| `Fnd_File.put_line` | 250 |
| `Fnd_File.put_line` | 251 |
| `Fnd_File.put_line` | 252 |
| `Fnd_File.put_line` | 288 |
| `Fnd_File.put_line` | 290 |
| `Fnd_File.put_line` | 301 |
| `Fnd_File.put_line` | 401 |
| `Fnd_File.put_line` | 445 |
| `Fnd_File.put_line` | 457 |
| `fnd_file.put_line` | 464 |
| `Fnd_File.put_line` | 553 |
| `Fnd_File.put_line` | 554 |
| `dka_tools_pkg.get_message` | 582 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 584 |
| `dka_tools_pkg.get_message` | 611 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 613 |
| `dka_tools_pkg.get_message` | 654 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 656 |
| `dka_tools_pkg.get_message` | 684 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 686 |
| `dka_tools_pkg.get_message` | 711 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 713 |
| `dka_tools_pkg.get_message` | 735 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 737 |
| `dka_tools_pkg.get_message` | 771 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 773 |
| `dka_tools_pkg.get_message` | 794 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 796 |
| `dka_tools_pkg.get_message` | 823 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 825 |
| `dka_tools_pkg.get_message` | 854 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 856 |
| `dka_tools_pkg.get_message` | 883 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 885 |
| `dka_tools_pkg.get_message` | 918 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 920 |
| `dka_tools_pkg.get_message` | 946 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 948 |
| `dka_tools_pkg.get_message` | 970 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 972 |
| `dka_tools_pkg.get_message` | 1009 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1011 |
| `dka_tools_pkg.get_message` | 1052 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1054 |
| `dka_tools_pkg.get_message` | 1076 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1078 |
| `dka_tools_pkg.get_message` | 1095 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1097 |
| `dka_tools_pkg.get_message` | 1135 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1137 |
| `dka_tools_pkg.get_message` | 1158 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1160 |
| `dka_tools_pkg.get_message` | 1178 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1180 |
| `Fnd_File.put_line` | 1206 |
| `Fnd_File.put_line` | 1214 |
| `Fnd_File.put_line` | 1215 |
| `Fnd_File.put_line` | 1307 |
| `Fnd_File.put_line` | 1308 |
| `dka_tools_pkg.get_message` | 1332 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1334 |
| `Fnd_File.put_line` | 1355 |
| `Fnd_File.put_line` | 1363 |
| `Fnd_File.put_line` | 1364 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1504 |
| `ap_workflow_pkg.insert_history_table` | 1550 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1558 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1587 |
| `Fnd_File.put_line` | 1613 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1635 |
| `ap_workflow_pkg.insert_history_table` | 1672 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1680 |
| `Fnd_File.put_line` | 1767 |
| `Fnd_File.put_line` | 1772 |
| `Fnd_File.put_line` | 1773 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1779 |
| `Fnd_File.put_line` | 1794 |
| `Fnd_File.put_line` | 1795 |
| `ap_workflow_pkg.insert_history_table` | 1825 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1833 |
| `ap_workflow_pkg.insert_history_table` | 1908 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1916 |
| `ap_workflow_pkg.insert_history_table` | 1995 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 2001 |
| `wf_engine.createprocess` | 2047 |
| `wf_engine.setitemattrnumber` | 2051 |
| `wf_engine.setitemattrnumber` | 2055 |
| `wf_engine.startprocess` | 2061 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 2069 |
| `ap_workflow_pkg.insert_history_table` | 2145 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 2151 |
| `Fnd_File.put_line` | 2213 |
| `Fnd_File.put_line` | 2220 |
| `Fnd_File.put_line` | 2221 |
| `Fnd_File.put_line` | 2259 |
| `Fnd_File.put_line` | 2260 |
| `Fnd_File.put_line` | 2263 |
| `Fnd_File.put_line` | 2264 |
| `fnd_request.set_print_options` | 2270 |
| `Fnd_Request.submit_request` | 2273 |
| `fnd_file.put_line` | 2284 |
| `Fnd_File.put_line` | 2290 |
| `Fnd_File.put_line` | 2292 |
| `Fnd_Concurrent.wait_for_request` | 2297 |
| `Fnd_file.put_line` | 2300 |
| `Fnd_File.put_line` | 2306 |
| `Fnd_File.put_line` | 2307 |
| `Fnd_File.put_line` | 2334 |
| `Fnd_File.put_line` | 2336 |
| `Fnd_File.put_line` | 2366 |
| `Fnd_File.put_line` | 2368 |
| `Fnd_File.put_line` | 2374 |
| `fnd_file.put_line` | 2382 |
| `Fnd_File.put_line` | 2385 |
| `fnd_stats.gather_table_stats` | 2392 |
| `Fnd_File.put_line` | 2395 |
| `Fnd_File.put_line` | 2402 |
| `Fnd_File.put_line` | 2403 |
| `Fnd_File.put_line` | 2455 |
| `Fnd_File.put_line` | 2512 |
| `Fnd_File.put_line` | 2513 |
| `Fnd_File.put_line` | 2514 |
| `fnd_file.put_line` | 2517 |
| `fnd_file.put_line` | 2518 |
| `fnd_file.put_line` | 2519 |
| `fnd_file.put_line` | 2520 |
| `Fnd_File.put_line` | 2522 |
| `Fnd_File.put_line` | 2523 |
| `Fnd_File.put_line` | 2524 |
| `Fnd_File.put_line` | 2535 |
| `Fnd_File.put_line` | 2536 |
| `Fnd_File.put_line` | 2537 |
| `fnd_file.put_line` | 2541 |
| `Fnd_File.put_line` | 2542 |
| `Fnd_File.Put_Line` | 2576 |
| `Fnd_File.Put_Line` | 2579 |
| `Fnd_File.Put_Line` | 2584 |
| `Fnd_File.Put_Line` | 2608 |
| `Fnd_File.put_line` | 2619 |
| `Fnd_File.put_line` | 2620 |
| `Fnd_File.Put_Line` | 2642 |
| `Fnd_File.put_line` | 2672 |
| `Fnd_File.put_line` | 2673 |
| `Fnd_File.put_line` | 2720 |
| `Fnd_File.put_line` | 2727 |
| `Fnd_File.put_line` | 2744 |
| `Fnd_File.put_line` | 2762 |
| `dka_tools_pkg.get_message` | 2798 |
| `Fnd_File.put_line` | 2801 |
| `Fnd_File.put_line` | 2803 |
| `Fnd_File.put_line` | 2804 |
| `Fnd_File.put_line` | 2806 |
| `fnd_file.put_line` | 2817 |
| `Fnd_File.put_line` | 2824 |
| `Fnd_File.put_line` | 2881 |
| `Fnd_File.put_line` | 2882 |
| `Fnd_File.put_line` | 2884 |
| `Fnd_File.put_line` | 2891 |
| `Fnd_File.put_line` | 2893 |
| `Fnd_File.put_line` | 2900 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_IAPFAC_DEBLOC_LOADER` | 2273 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1208, 1357, 1551, 1580, 1673, 1705, 1826, 1855, 1869, 1909, 1939, 1954, 1996, 2025, 2065, 2092, 2105, 2146, 2174, 2193, 2207, 2214, 2289, 2816, 2880 |
| rollback | 2224 |
| when_others | 117, 295, 359, 466, 568, 580, 609, 639, 652, 709, 769, 821, 852, 881, 916, 945, 1051, 1122, 1134, 1211, 1327, 1360, 1501, 1555, 1584, 1612, 1632, 1677, 1707, 1776, 1830, 1858, 1871, 1913, 1943, 1956, 1998, 2028, 2067, 2095, 2107, 2149, 2178, 2195, 2209, 2217, 2316, 2326, 2346, 2356, 2398, 2472, 2509, 2615, 2668, 2784, 2896 |
| suppression | 2331, 2360, 2363, 2580, 2609, 2654, 2809, 2812, 2815 |
| soumission | 2273 |
| workflow | 2047, 2051, 2055, 2061 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
