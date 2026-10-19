# DKA_REPPOCMDIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPPOCMDIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPPOCMDIMP_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3529 ; encodage : cp1252 (repli). SHA-256 : `ac648a3f46bb5b74f313fcdf7be96ad4ec68db21550b189030680cb4c2b86b5c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 113 |
| `output_header` | 212 |
| `ins_prog_message` | 255 |
| `Request_parameters` | 319 |
| `output_end` | 409 |
| `get_organization_id` | 443 |
| `print_errors` | 486 |
| `Launch_Loader` | 536 |
| `validate_data` | 685 |
| `import_data` | 1762 |
| `Launch_OI` | 2218 |
| `update_post_import` | 2509 |
| `Launch_report` | 2684 |
| `Report_Bilan` | 2795 |
| `set_recovery_mode` | 2882 |
| `post_OI` | 3056 |
| `main` | 3234 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 173 |
| `fnd_concurrent_programs` | 227 |
| `dka_program_messages` | 267 |
| `fnd_concurrent_requests` | 325 |
| `fnd_concurrent_requests` | 356 |
| `fnd_concurrent_requests` | 373 |
| `hr_operating_units` | 457 |
| `DKA_PROGRAM_MESSAGES` | 491 |
| `PO_HEADERS_TMP` | 606 |
| `PO_LINES_TMP` | 618 |
| `PO_DISTRIBUTIONS_TMP` | 630 |
| `PO_HEADERS_TMP` | 693 |
| `PO_LINES_TMP` | 700 |
| `OF` | 704 |
| `PO_DISTRIBUTIONS_TMP` | 715 |
| `OF` | 721 |
| `po_vendors` | 856 |
| `po_vendor_sites_all` | 882 |
| `HR_LOCATIONS_ALL` | 931 |
| `per_people_f` | 962 |
| `per_people_f` | 991 |
| `per_people_f` | 1004 |
| `AP_TERMS` | 1034 |
| `hr_locations` | 1063 |
| `mtl_categories_b` | 1113 |
| `po_units_of_measure_val_v` | 1159 |
| `dual` | 1189 |
| `hr_locations` | 1197 |
| `hr_operating_units` | 1247 |
| `pa_projects_all` | 1382 |
| `PA_PROJECTS_ALL` | 1426 |
| `pa_tasks` | 1458 |
| `per_all_people_f` | 1531 |
| `hr_locations` | 1566 |
| `PO_DISTRIBUTIONS_TMP` | 1591 |
| `PO_DISTRIBUTIONS_TMP` | 1615 |
| `PO_LINES_TMP` | 1633 |
| `PO_LINES_TMP` | 1649 |
| `PO_HEADERS_TMP` | 1683 |
| `PO_HEADERS_TMP` | 1705 |
| `PO_LINES_TMP` | 1711 |
| `PO_DISTRIBUTIONS_TMP` | 1717 |
| `PO_DOC_STYLE_HEADERS` | 1803 |
| `PO_HEADERS_INTERFACE` | 1826 |
| `PO_HEADERS_TMP` | 1910 |
| `PO_HEADERS_TMP` | 1918 |
| `PO_LINES_INTERFACE` | 1947 |
| `hr_locations` | 2026 |
| `PO_LINES_TMP` | 2037 |
| `PO_LINES_TMP` | 2047 |
| `PO_DISTRIBUTIONS_INTERFACE` | 2078 |
| `PO_DISTRIBUTIONS_TMP` | 2140 |
| `PO_DISTRIBUTIONS_TMP` | 2165 |
| `PO_HEADERS_INTERFACE` | 2241 |
| `fnd_responsibility` | 2303 |
| `PO_LINE_LOCATIONS_ALL` | 2532 |
| `PO_LINES_TMP` | 2534 |
| `PO_LINES_TMP` | 2561 |
| `PO_DISTRIBUTIONS_ALL` | 2588 |
| `PO_DISTRIBUTIONS_TMP` | 2590 |
| `PO_DISTRIBUTIONS_TMP` | 2623 |
| `PO_HEADERS_TMP` | 2813 |
| `PO_LINES_TMP` | 2818 |
| `PO_DISTRIBUTIONS_TMP` | 2823 |
| `PO_HEADERS_TMP` | 2891 |
| `PO_LINES_TMP` | 2903 |
| `PO_DISTRIBUTIONS_TMP` | 2915 |
| `po_interface_errors` | 3068 |
| `po_interface_errors` | 3080 |
| `po_interface_errors` | 3096 |
| `PO_HEADERS_TMP` | 3114 |
| `PO_HEADERS_INTERFACE` | 3119 |
| `PO_LINES_TMP` | 3128 |
| `PO_HEADERS_INTERFACE` | 3133 |
| `PO_DISTRIBUTIONS_TMP` | 3142 |
| `PO_HEADERS_INTERFACE` | 3147 |
| `PO_HEADERS_TMP` | 3382 |
| `PO_LINES_TMP` | 3388 |
| `PO_DISTRIBUTIONS_TMP` | 3394 |
| `PO_HEADERS_TMP` | 3403 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 125 |
| `fnd_profile.value` | 143 |
| `Fnd_File.put_line` | 166 |
| `Fnd_File.put_line` | 178 |
| `fnd_file.put_line` | 187 |
| `Fnd_File.put_line` | 242 |
| `Fnd_File.put_line` | 243 |
| `Fnd_File.put_line` | 244 |
| `Fnd_File.put_line` | 245 |
| `Fnd_File.put_line` | 246 |
| `Fnd_File.put_line` | 341 |
| `Fnd_File.put_line` | 342 |
| `Fnd_File.put_line` | 343 |
| `Fnd_File.put_line` | 344 |
| `Fnd_File.put_line` | 361 |
| `Fnd_File.put_line` | 362 |
| `Fnd_File.put_line` | 378 |
| `Fnd_File.put_line` | 379 |
| `Fnd_File.put_line` | 382 |
| `Fnd_File.put_line` | 385 |
| `Fnd_File.put_line` | 386 |
| `Fnd_File.put_line` | 418 |
| `Fnd_File.put_line` | 419 |
| `Fnd_File.put_line` | 420 |
| `fnd_file.put_line` | 505 |
| `fnd_file.put_line` | 506 |
| `fnd_file.put_line` | 507 |
| `fnd_file.put_line` | 508 |
| `fnd_file.put_line` | 509 |
| `Fnd_File.put_line` | 513 |
| `Fnd_File.put_line` | 549 |
| `Fnd_File.put_line` | 550 |
| `fnd_file.put_line` | 553 |
| `fnd_file.put_line` | 554 |
| `fnd_file.put_line` | 555 |
| `fnd_request.set_print_options` | 560 |
| `Fnd_Request.submit_request` | 563 |
| `fnd_file.put_line` | 575 |
| `Fnd_File.put_line` | 580 |
| `Fnd_File.put_line` | 583 |
| `Fnd_File.put_line` | 584 |
| `Fnd_Concurrent.wait_for_request` | 587 |
| `Fnd_file.put_line` | 590 |
| `Fnd_File.put_line` | 596 |
| `Fnd_File.put_line` | 597 |
| `Fnd_File.put_line` | 633 |
| `Fnd_File.put_line` | 634 |
| `Fnd_File.put_line` | 635 |
| `Fnd_File.put_line` | 639 |
| `Fnd_File.put_line` | 640 |
| `fnd_file.put_line` | 648 |
| `Fnd_File.put_line` | 651 |
| `Fnd_File.put_line` | 657 |
| `Fnd_File.put_line` | 664 |
| `Fnd_File.put_line` | 665 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 808 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 913 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 920 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1097 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1140 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1372 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1519 |
| `Fnd_File.put_line` | 1742 |
| `Fnd_File.put_line` | 1743 |
| `Fnd_File.put_line` | 1819 |
| `Fnd_File.put_line` | 1935 |
| `Fnd_File.put_line` | 2065 |
| `Fnd_File.put_line` | 2191 |
| `Fnd_File.put_line` | 2192 |
| `FND_PROFILE.VALUE` | 2248 |
| `Fnd_File.put_line` | 2252 |
| `Fnd_File.put_line` | 2253 |
| `fnd_file.put_line` | 2256 |
| `fnd_file.put_line` | 2257 |
| `fnd_file.put_line` | 2258 |
| `fnd_file.put_line` | 2263 |
| `fnd_file.put_line` | 2264 |
| `FND_GLOBAL.APPS_INITIALIZE` | 2308 |
| `Fnd_Request.set_org_id` | 2315 |
| `fnd_file.put_line` | 2323 |
| `fnd_file.put_line` | 2324 |
| `fnd_request.set_print_options` | 2334 |
| `Fnd_Request.submit_request` | 2337 |
| `Fnd_File.put_line` | 2370 |
| `Fnd_File.put_line` | 2376 |
| `Fnd_File.put_line` | 2377 |
| `fnd_file.put_line` | 2419 |
| `fnd_file.put_line` | 2420 |
| `fnd_file.put_line` | 2421 |
| `Fnd_File.put_line` | 2426 |
| `Fnd_Concurrent.wait_for_request` | 2430 |
| `Fnd_file.put_line` | 2439 |
| `Fnd_File.put_line` | 2445 |
| `Fnd_File.put_line` | 2448 |
| `Fnd_File.put_line` | 2453 |
| `Fnd_File.put_line` | 2456 |
| `fnd_file.put_line` | 2466 |
| `Fnd_File.put_line` | 2471 |
| `Fnd_File.put_line` | 2479 |
| `Fnd_File.put_line` | 2486 |
| `Fnd_File.put_line` | 2487 |
| `Fnd_File.put_line` | 2521 |
| `Fnd_File.put_line` | 2522 |
| `fnd_file.put_line` | 2525 |
| `fnd_file.put_line` | 2526 |
| `fnd_file.put_line` | 2527 |
| `fnd_file.put_line` | 2531 |
| `fnd_file.put_line` | 2587 |
| `Fnd_File.put_line` | 2655 |
| `Fnd_File.put_line` | 2662 |
| `Fnd_File.put_line` | 2663 |
| `Fnd_File.put_line` | 2696 |
| `Fnd_File.put_line` | 2697 |
| `fnd_file.put_line` | 2700 |
| `fnd_file.put_line` | 2701 |
| `fnd_file.put_line` | 2702 |
| `fnd_request.set_print_options` | 2707 |
| `Fnd_Request.submit_request` | 2710 |
| `fnd_file.put_line` | 2723 |
| `Fnd_File.put_line` | 2727 |
| `Fnd_File.put_line` | 2730 |
| `Fnd_File.put_line` | 2731 |
| `Fnd_Concurrent.wait_for_request` | 2734 |
| `Fnd_file.put_line` | 2737 |
| `Fnd_File.put_line` | 2743 |
| `Fnd_File.put_line` | 2744 |
| `Fnd_File.put_line` | 2748 |
| `fnd_file.put_line` | 2756 |
| `Fnd_File.put_line` | 2759 |
| `Fnd_File.put_line` | 2765 |
| `Fnd_File.put_line` | 2772 |
| `Fnd_File.put_line` | 2773 |
| `Fnd_File.put_line` | 2802 |
| `fnd_file.put_line` | 2827 |
| `fnd_file.put_line` | 2828 |
| `fnd_file.put_line` | 2829 |
| `fnd_file.put_line` | 2830 |
| `fnd_file.put_line` | 2831 |
| `fnd_file.put_line` | 2832 |
| `fnd_file.put_line` | 2834 |
| `fnd_file.put_line` | 2835 |
| `fnd_file.put_line` | 2836 |
| `fnd_file.put_line` | 2838 |
| `fnd_file.put_line` | 2839 |
| `fnd_file.put_line` | 2840 |
| `fnd_file.put_line` | 2842 |
| `fnd_file.put_line` | 2843 |
| `fnd_file.put_line` | 2844 |
| `fnd_file.put_line` | 2846 |
| `fnd_file.put_line` | 2847 |
| `fnd_file.put_line` | 2850 |
| `fnd_file.put_line` | 2853 |
| `Fnd_File.put_line` | 2854 |
| `Fnd_File.put_line` | 2862 |
| `Fnd_File.put_line` | 2863 |
| `Fnd_File.put_line` | 2933 |
| `Fnd_File.put_line` | 2934 |
| `Fnd_File.put_line` | 3211 |
| `Fnd_File.put_line` | 3212 |
| `Fnd_File.put_line` | 3256 |
| `Fnd_File.put_line` | 3262 |
| `Fnd_File.put_line` | 3298 |
| `Fnd_File.put_line` | 3318 |
| `Fnd_File.put_line` | 3343 |
| `Fnd_File.put_line` | 3359 |
| `Fnd_File.put_line` | 3379 |
| `Fnd_File.put_line` | 3423 |
| `Fnd_File.put_line` | 3424 |
| `Fnd_File.put_line` | 3431 |
| `Fnd_File.put_line` | 3475 |
| `Fnd_File.put_line` | 3501 |
| `Fnd_File.put_line` | 3502 |
| `Fnd_File.put_line` | 3504 |
| `Fnd_File.put_line` | 3512 |
| `Fnd_File.put_line` | 3513 |
| `Fnd_File.put_line` | 3514 |
| `Fnd_File.put_line` | 3515 |
| `Fnd_File.put_line` | 3520 |
| `Fnd_File.put_line` | 3521 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPPOCMDIMP` | 563 |
| `POXPOPDOI` | 2337 |
| `POXPIERR` | 2710 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 582, 1728, 1735, 2184, 2372, 2477, 2729, 3204 |
| rollback | 2, 299 |
| when_others | 189, 235, 298, 660, 861, 893, 936, 969, 1011, 1039, 1067, 1121, 1164, 1201, 1253, 1386, 1433, 1465, 1542, 1570, 1738, 1807, 2187, 2318, 2482, 2658, 2768, 2858, 2929, 3207, 3408, 3516 |
| soumission | 563, 2337, 2710 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPPOCMDIMP / DKA | `DKA_REPPOCMDIMP_PKG.main` | dka/12.0.0/admin/import/DKA_REPPOCMDIMP.prt:514 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
