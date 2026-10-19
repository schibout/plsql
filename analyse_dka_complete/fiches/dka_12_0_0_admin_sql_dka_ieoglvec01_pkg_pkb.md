# DKA_IEOGLVEC01_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IEOGLVEC01_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IEOGLVEC01_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2710 ; encodage : utf-8. SHA-256 : `ee841276ab4e154854cb90b1ac1fd831425137e3e0a8d137ecd847f4a00b4577`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_message` | 68 |
| `put_out_header` | 177 |
| `get_instance_name` | 230 |
| `get_application_short_name` | 261 |
| `get_segment_num` | 293 |
| `get_qual_flex_value_set_id` | 336 |
| `get_qual_flex_value_set_name` | 385 |
| `get_qual_value_set_val_type` | 424 |
| `get_qual_flex_value_set_parent` | 462 |
| `get_cuf_attribute_num` | 500 |
| `get_cuf_attribute_value` | 565 |
| `get_cuf_attribute_value_dep` | 616 |
| `get_conso_code` | 668 |
| `get_partner_code` | 706 |
| `qualifier_exists` | 751 |
| `flex_value_set_name_exists` | 789 |
| `attribute_exists` | 829 |
| `attribute_exists_desc_flex` | 861 |
| `profile_option_exists` | 905 |
| `control_period_name` | 951 |
| `control_period_name` | 962 |
| `control_period_name` | 976 |
| `control_period_name` | 984 |
| `control_period_name` | 990 |
| `get_gl_period_end_date` | 1004 |
| `delete_dka_ieoglvec01_int` | 1046 |
| `delete_dka_ieoglvec01_int` | 1057 |
| `delete_dka_ieoglvec01_int` | 1063 |
| `delete_dka_ieoglvec01_int` | 1071 |
| `insert_dka_ieoglvec01_int` | 1089 |
| `insert_dka_ieoglvec01_int` | 1113 |
| `insert_dka_ieoglvec01_int` | 1509 |
| `insert_dka_ieoglvec01_int` | 1517 |
| `update_dka_ieoglvec01_int` | 1533 |
| `update_dka_ieoglvec01_int` | 1629 |
| `update_dka_ieoglvec01_int` | 1833 |
| `update_dka_ieoglvec01_int` | 1841 |
| `load_dka_ieoglvec01_int` | 1858 |
| `load_dka_ieoglvec01_int` | 1884 |
| `load_dka_ieoglvec01_int` | 1946 |
| `load_dka_ieoglvec01_int` | 1954 |
| `launch_request` | 1975 |
| `launch_request` | 1994 |
| `launch_request` | 2055 |
| `launch_request` | 2060 |
| `main` | 2077 |
| `control` | 2430 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 195 |
| `gl_ledgers` | 243 |
| `fnd_application` | 274 |
| `fnd_segment_attribute_values` | 307 |
| `gl_access_set_assignments` | 310 |
| `fnd_segment_attribute_values` | 350 |
| `gl_access_set_assignments` | 356 |
| `fnd_flex_value_sets` | 399 |
| `fnd_flex_value_sets` | 438 |
| `fnd_flex_value_sets` | 476 |
| `fnd_segment_attribute_values` | 515 |
| `gl_access_set_assignments` | 529 |
| `fnd_flex_values` | 586 |
| `fnd_flex_values` | 638 |
| `fnd_segment_attribute_types` | 765 |
| `FND_FLEX_VALUE_SETS` | 804 |
| `dual` | 843 |
| `fnd_descriptive_flexs` | 876 |
| `fnd_profile_options` | 919 |
| `dual` | 932 |
| `gl_period_statuses` | 968 |
| `gl_access_set_assignments` | 971 |
| `gl_period_statuses` | 1018 |
| `dka_ieoglvec01_int` | 1147 |
| `gl_ledgers` | 1170 |
| `fnd_flex_values` | 1185 |
| `fnd_flex_values` | 1191 |
| `dka_ieoglvec01_int` | 1215 |
| `gl_ledgers` | 1240 |
| `fnd_flex_values` | 1260 |
| `fnd_flex_values` | 1266 |
| `fnd_flex_values` | 1272 |
| `gl_period_statuses` | 1290 |
| `gl_period_statuses` | 1295 |
| `dka_ieoglvec01_int` | 1322 |
| `gl_ledgers` | 1347 |
| `fnd_flex_values` | 1363 |
| `fnd_flex_values` | 1369 |
| `dka_ieoglvec01_int` | 1394 |
| `gl_ledgers` | 1421 |
| `fnd_flex_values` | 1442 |
| `fnd_flex_values` | 1448 |
| `fnd_flex_values` | 1454 |
| `gl_period_statuses` | 1472 |
| `gl_period_statuses` | 1477 |
| `dka_ieoglvec01_int` | 1552 |
| `dka_ieoglvec01_int` | 1574 |
| `dka_ieoglvec01_int` | 1596 |
| `dka_ieoglvec01_int` | 1617 |
| `dka_ieoglvec01_int` | 1633 |
| `dka_ieoglvec01_int` | 1640 |
| `dka_ieoglvec01_int` | 1661 |
| `TABLE` | 1673 |
| `dka_ieoglvec01_int` | 1703 |
| `TABLE` | 1716 |
| `dka_ieoglvec01_int` | 1747 |
| `TABLE` | 1759 |
| `dka_ieoglvec01_int` | 1789 |
| `TABLE` | 1802 |
| `dka_ieoglvec01_int` | 1825 |
| `dka_ieoglvec01_conso_code_v` | 1876 |
| `dka_ieoglvec01_conso_code_v` | 2110 |
| `GL_LEDGERS` | 2114 |
| `dka_ieoglvec01_conso_code_v` | 2122 |
| `GL_LEDGERS` | 2127 |
| `gl_access_set_assignments` | 2140 |
| `GL_LEDGERS` | 2233 |
| `fnd_flex_values` | 2443 |
| `dka_ieoglvec01_conso_code_v` | 2455 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Message.set_name` | 103 |
| `Fnd_Message.set_token` | 108 |
| `Fnd_Message.set_token` | 113 |
| `Fnd_Message.set_token` | 118 |
| `Fnd_Message.set_token` | 123 |
| `Fnd_Message.set_token` | 128 |
| `Fnd_Message.set_token` | 133 |
| `Fnd_Message.set_token` | 138 |
| `Fnd_Message.set_token` | 143 |
| `Fnd_Message.set_token` | 148 |
| `Fnd_Message.set_token` | 153 |
| `Fnd_File.put_line` | 184 |
| `Fnd_File.put_line` | 185 |
| `Fnd_File.put_line` | 186 |
| `Fnd_File.put_line` | 187 |
| `Fnd_File.put_line` | 209 |
| `Fnd_File.put_line` | 210 |
| `Fnd_File.put_line` | 211 |
| `Fnd_File.put_line` | 212 |
| `Fnd_File.put_line` | 213 |
| `Fnd_File.put_line` | 214 |
| `Fnd_File.put_line` | 215 |
| `Fnd_File.put_line` | 216 |
| `FND_PROFILE.value` | 310 |
| `FND_PROFILE.value` | 357 |
| `FND_PROFILE.value` | 529 |
| `Fnd_Profile.VALUE` | 930 |
| `Fnd_File.put_line` | 962 |
| `FND_PROFILE.value` | 971 |
| `Fnd_File.put_line` | 976 |
| `Fnd_File.put_line` | 983 |
| `Fnd_File.put_line` | 984 |
| `Fnd_File.put_line` | 989 |
| `Fnd_File.put_line` | 990 |
| `Fnd_Profile.VALUE` | 1021 |
| `Fnd_File.put_line` | 1057 |
| `Fnd_File.put_line` | 1062 |
| `Fnd_File.put_line` | 1063 |
| `Fnd_File.put_line` | 1070 |
| `Fnd_File.put_line` | 1071 |
| `Fnd_File.put_line` | 1113 |
| `dka_ieoglvec01_pkg.get_qual_flex_value_set_name` | 1128 |
| `dka_ieoglvec01_pkg.get_qual_flex_value_set_name` | 1129 |
| `Fnd_File.put_line` | 1146 |
| `Fnd_File.put_line` | 1206 |
| `Fnd_File.put_line` | 1207 |
| `Fnd_File.put_line` | 1212 |
| `Fnd_File.put_line` | 1213 |
| `Fnd_File.put_line` | 1313 |
| `Fnd_File.put_line` | 1314 |
| `Fnd_File.put_line` | 1321 |
| `Fnd_File.put_line` | 1385 |
| `Fnd_File.put_line` | 1386 |
| `Fnd_File.put_line` | 1391 |
| `Fnd_File.put_line` | 1392 |
| `Fnd_File.put_line` | 1496 |
| `Fnd_File.put_line` | 1497 |
| `Fnd_File.put_line` | 1505 |
| `Fnd_File.put_line` | 1509 |
| `Fnd_File.put_line` | 1516 |
| `Fnd_File.put_line` | 1517 |
| `Fnd_File.put_line` | 1629 |
| `Fnd_File.put_line` | 1673 |
| `Fnd_File.put_line` | 1676 |
| `Fnd_File.put_line` | 1677 |
| `Fnd_File.put_line` | 1683 |
| `Fnd_File.put_line` | 1686 |
| `Fnd_File.put_line` | 1687 |
| `Fnd_File.put_line` | 1716 |
| `Fnd_File.put_line` | 1719 |
| `Fnd_File.put_line` | 1720 |
| `Fnd_File.put_line` | 1726 |
| `Fnd_File.put_line` | 1729 |
| `Fnd_File.put_line` | 1730 |
| `Fnd_File.put_line` | 1759 |
| `Fnd_File.put_line` | 1762 |
| `Fnd_File.put_line` | 1763 |
| `Fnd_File.put_line` | 1769 |
| `Fnd_File.put_line` | 1772 |
| `Fnd_File.put_line` | 1773 |
| `Fnd_File.put_line` | 1802 |
| `Fnd_File.put_line` | 1805 |
| `Fnd_File.put_line` | 1806 |
| `Fnd_File.put_line` | 1812 |
| `Fnd_File.put_line` | 1815 |
| `Fnd_File.put_line` | 1816 |
| `Fnd_File.put_line` | 1832 |
| `Fnd_File.put_line` | 1833 |
| `Fnd_File.put_line` | 1840 |
| `Fnd_File.put_line` | 1841 |
| `Fnd_File.put_line` | 1884 |
| `Fnd_File.put_line` | 1885 |
| `Fnd_File.put_line` | 1922 |
| `Fnd_File.put_line` | 1925 |
| `Fnd_File.put_line` | 1926 |
| `Fnd_File.put_line` | 1946 |
| `Fnd_File.put_line` | 1953 |
| `Fnd_File.put_line` | 1954 |
| `Fnd_File.put_line` | 1994 |
| `Fnd_Profile.VALUE` | 1996 |
| `Fnd_File.put_line` | 2000 |
| `Fnd_File.put_line` | 2003 |
| `fnd_request.submit_request` | 2004 |
| `Fnd_File.put_line` | 2017 |
| `Fnd_File.put_line` | 2024 |
| `Fnd_File.put_line` | 2025 |
| `Fnd_File.put_line` | 2029 |
| `fnd_request.submit_request` | 2030 |
| `Fnd_File.put_line` | 2043 |
| `Fnd_File.put_line` | 2050 |
| `Fnd_File.put_line` | 2051 |
| `Fnd_File.put_line` | 2055 |
| `Fnd_File.put_line` | 2061 |
| `FND_PROFILE.value` | 2117 |
| `FND_PROFILE.value` | 2130 |
| `FND_PROFILE.value` | 2141 |
| `Fnd_File.put_line` | 2163 |
| `Fnd_File.put_line` | 2165 |
| `Fnd_File.put_line` | 2168 |
| `Fnd_File.put_line` | 2169 |
| `Fnd_File.put_line` | 2213 |
| `Fnd_File.put_line` | 2214 |
| `Fnd_File.put_line` | 2215 |
| `Fnd_File.put_line` | 2217 |
| `Fnd_File.put_line` | 2218 |
| `Fnd_File.put_line` | 2219 |
| `Fnd_File.put_line` | 2300 |
| `Fnd_File.put_line` | 2301 |
| `Fnd_File.put_line` | 2306 |
| `Fnd_File.put_line` | 2316 |
| `fnd_concurrent.wait_for_request` | 2339 |
| `Fnd_File.put_line` | 2350 |
| `Fnd_File.put_line` | 2351 |
| `Fnd_File.put_line` | 2356 |
| `Fnd_File.put_line` | 2359 |
| `Fnd_File.put_line` | 2363 |
| `Fnd_File.put_line` | 2364 |
| `Fnd_File.put_line` | 2372 |
| `Fnd_File.put_line` | 2373 |
| `Fnd_File.put_line` | 2374 |
| `Fnd_File.put_line` | 2375 |
| `Fnd_File.put_line` | 2376 |
| `Fnd_File.put_line` | 2402 |
| `Fnd_File.put_line` | 2403 |
| `dka_ieoglvec01_pkg.get_qual_flex_value_set_id` | 2444 |
| `Fnd_File.put_line` | 2471 |
| `Fnd_Profile.VALUE` | 2471 |
| `Fnd_File.put_line` | 2476 |
| `Fnd_File.put_line` | 2477 |
| `Fnd_File.put_line` | 2479 |
| `Fnd_File.put_line` | 2480 |
| `Fnd_File.put_line` | 2481 |
| `Fnd_File.put_line` | 2482 |
| `Fnd_File.put_line` | 2483 |
| `Fnd_File.put_line` | 2484 |
| `Fnd_File.put_line` | 2489 |
| `Fnd_File.put_line` | 2490 |
| `Fnd_File.put_line` | 2494 |
| `Fnd_File.put_line` | 2497 |
| `Fnd_File.put_line` | 2503 |
| `Fnd_File.put_line` | 2506 |
| `Fnd_File.put_line` | 2513 |
| `Fnd_File.put_line` | 2516 |
| `Fnd_File.put_line` | 2522 |
| `Fnd_File.put_line` | 2526 |
| `Fnd_File.put_line` | 2533 |
| `Fnd_File.put_line` | 2536 |
| `Fnd_File.put_line` | 2542 |
| `Fnd_File.put_line` | 2545 |
| `Fnd_File.put_line` | 2553 |
| `Fnd_File.put_line` | 2554 |
| `Fnd_File.put_line` | 2556 |
| `Fnd_File.put_line` | 2557 |
| `Fnd_File.put_line` | 2558 |
| `Fnd_File.put_line` | 2559 |
| `Fnd_File.put_line` | 2560 |
| `Fnd_File.put_line` | 2566 |
| `Fnd_File.put_line` | 2570 |
| `Fnd_File.put_line` | 2578 |
| `Fnd_File.put_line` | 2579 |
| `Fnd_File.put_line` | 2580 |
| `Fnd_File.put_line` | 2581 |
| `Fnd_File.put_line` | 2582 |
| `Fnd_File.put_line` | 2583 |
| `Fnd_File.put_line` | 2584 |
| `Fnd_File.put_line` | 2585 |
| `Fnd_File.put_line` | 2586 |
| `Fnd_File.put_line` | 2588 |
| `Fnd_File.put_line` | 2589 |
| `Fnd_File.put_line` | 2590 |
| `Fnd_File.put_line` | 2591 |
| `Fnd_File.put_line` | 2592 |
| `Fnd_File.put_line` | 2593 |
| `Fnd_File.put_line` | 2594 |
| `Fnd_File.put_line` | 2595 |
| `Fnd_File.put_line` | 2597 |
| `Fnd_File.put_line` | 2598 |
| `Fnd_File.put_line` | 2599 |
| `Fnd_File.put_line` | 2600 |
| `Fnd_File.put_line` | 2601 |
| `Fnd_File.put_line` | 2602 |
| `Fnd_File.put_line` | 2604 |
| `Fnd_File.put_line` | 2605 |
| `Fnd_File.put_line` | 2606 |
| `Fnd_File.put_line` | 2607 |
| `Fnd_File.put_line` | 2608 |
| `Fnd_File.put_line` | 2609 |
| `Fnd_File.put_line` | 2612 |
| `Fnd_File.put_line` | 2613 |
| `Fnd_File.put_line` | 2614 |
| `Fnd_File.put_line` | 2615 |
| `Fnd_File.put_line` | 2616 |
| `Fnd_File.put_line` | 2618 |
| `Fnd_File.put_line` | 2619 |
| `Fnd_File.put_line` | 2620 |
| `Fnd_File.put_line` | 2621 |
| `Fnd_File.put_line` | 2622 |
| `Fnd_File.put_line` | 2624 |
| `Fnd_File.put_line` | 2625 |
| `Fnd_File.put_line` | 2626 |
| `Fnd_File.put_line` | 2627 |
| `Fnd_File.put_line` | 2628 |
| `Fnd_File.put_line` | 2634 |
| `Fnd_File.put_line` | 2635 |
| `Fnd_File.put_line` | 2642 |
| `Fnd_File.put_line` | 2647 |
| `Fnd_File.put_line` | 2649 |
| `Fnd_File.put_line` | 2652 |
| `Fnd_File.put_line` | 2662 |
| `Fnd_File.put_line` | 2663 |
| `Fnd_File.put_line` | 2664 |
| `Fnd_File.put_line` | 2665 |
| `Fnd_File.put_line` | 2666 |
| `Fnd_File.put_line` | 2673 |
| `Fnd_File.put_line` | 2674 |
| `Fnd_File.put_line` | 2679 |
| `Fnd_File.put_line` | 2681 |
| `Fnd_File.put_line` | 2684 |
| `Fnd_File.put_line` | 2689 |
| `Fnd_File.put_line` | 2690 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 2287 |
| rollback | 2409, 2414, 2696, 2701 |
| when_others | 161, 203, 985, 1066, 1512, 1671, 1681, 1714, 1724, 1757, 1767, 1800, 1810, 1836, 1920, 1949, 2058, 2305, 2315, 2412, 2569, 2699 |
| soumission | 2004, 2030 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IEOGLVEC01_CTRL / DKA | `dka_ieoglvec01_pkg.control` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_CTRL_F.prt:419 |
| DKA_IEOGLVEC01_CTRL / DKA | `dka_ieoglvec01_pkg.control` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_CTRL_F.prt:419 |
| DKA_IEOGLVEC01_CTRL / DKA | `dka_ieoglvec01_pkg.control` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_CTRL_US.prt:419 |
| DKA_IEOGLVEC01_CTRL / DKA | `dka_ieoglvec01_pkg.control` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_CTRL_US.prt:419 |
| DKA_IEOGLVEC01_MAIN / DKA | `dka_ieoglvec01_pkg.main` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_MAIN_F.prt:498 |
| DKA_IEOGLVEC01_MAIN / DKA | `dka_ieoglvec01_pkg.main` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_MAIN_F.prt:498 |
| DKA_IEOGLVEC01_MAIN / DKA | `dka_ieoglvec01_pkg.main` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_MAIN_US.prt:498 |
| DKA_IEOGLVEC01_MAIN / DKA | `dka_ieoglvec01_pkg.main` | dka/12.0.0/admin/import/DKA_IEOGLVEC01_MAIN_US.prt:498 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
