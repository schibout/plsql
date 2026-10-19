# DKA_FUSPOIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSPOIMP_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3776 ; encodage : cp1252 (repli). SHA-256 : `93a4b9b10b20021683786727d9c87cc431a10894b8c10c4783190aabd60864ce`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 88 |
| `output_header` | 185 |
| `ins_prog_message` | 228 |
| `Request_parameters` | 284 |
| `output_end` | 374 |
| `get_organization_id` | 408 |
| `print_errors` | 451 |
| `Launch_Loader` | 493 |
| `validate_data` | 589 |
| `import_data` | 1529 |
| `Launch_OI` | 2026 |
| `update_post_import` | 2261 |
| `Launch_report` | 2554 |
| `Report_Bilan` | 2665 |
| `set_recovery_mode` | 2880 |
| `post_OI` | 3142 |
| `main` | 3539 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 146 |
| `fnd_concurrent_programs` | 200 |
| `dka_program_messages` | 240 |
| `fnd_concurrent_requests` | 290 |
| `fnd_concurrent_requests` | 321 |
| `fnd_concurrent_requests` | 338 |
| `hr_operating_units` | 422 |
| `DKA_PROGRAM_MESSAGES` | 456 |
| `DKA_SPOFUSION_HEADERS_TMP` | 597 |
| `HR_ORGANIZATION_UNITS` | 603 |
| `DKA_SPOFUSION_LINES_TMP` | 621 |
| `OF` | 625 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 636 |
| `OF` | 642 |
| `HR_ORGANIZATION_UNITS` | 727 |
| `po_vendors` | 775 |
| `DKA_SPOFUSION_HEADERS_TMP` | 801 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 856 |
| `per_people_f` | 888 |
| `per_people_f` | 901 |
| `per_people_f` | 914 |
| `AP_TERMS` | 946 |
| `hr_locations` | 975 |
| `mtl_categories_b` | 1010 |
| `po_units_of_measure_val_v` | 1051 |
| `po_units_of_measure_val_v` | 1077 |
| `po_line_types` | 1079 |
| `hr_locations` | 1107 |
| `hr_operating_units` | 1151 |
| `dual` | 1181 |
| `pa_projects_all` | 1186 |
| `PA_PROJECTS_ALL` | 1215 |
| `dual` | 1247 |
| `pa_tasks` | 1251 |
| `per_all_people_f` | 1292 |
| `hr_locations` | 1331 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 1356 |
| `hr_organization_units` | 1378 |
| `DKA_SPOFUSION_LINES_TMP` | 1396 |
| `hr_organization_units` | 1411 |
| `DKA_SPOFUSION_HEADERS_TMP` | 1445 |
| `DKA_SPOFUSION_HEADERS_TMP` | 1472 |
| `DKA_SPOFUSION_LINES_TMP` | 1478 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 1484 |
| `PO_DOC_STYLE_HEADERS` | 1543 |
| `PO_HEADERS_INTERFACE` | 1566 |
| `DKA_SPOFUSION_HEADERS_TMP` | 1652 |
| `HR_ORGANIZATION_UNITS` | 1659 |
| `DKA_SPOFUSION_HEADERS_TMP` | 1678 |
| `HR_ORGANIZATION_UNITS` | 1685 |
| `PO_LINES_INTERFACE` | 1723 |
| `hr_locations` | 1803 |
| `MTL_SYSTEM_ITEMS_B` | 1812 |
| `DKA_SPOFUSION_LINES_TMP` | 1818 |
| `DKA_SPOFUSION_LINES_TMP` | 1833 |
| `HR_ORGANIZATION_UNITS` | 1842 |
| `PO_DISTRIBUTIONS_INTERFACE` | 1873 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 1936 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 1958 |
| `HR_ORGANIZATION_UNITS` | 1967 |
| `PO_HEADERS_INTERFACE` | 2049 |
| `HR_ORGANIZATION_UNITS` | 2055 |
| `fnd_responsibility` | 2095 |
| `PO_LINE_LOCATIONS_ALL` | 2287 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2289 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2307 |
| `HR_ORGANIZATION_UNITS` | 2324 |
| `PO_LINE_LOCATIONS_ALL` | 2338 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2340 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2359 |
| `HR_ORGANIZATION_UNITS` | 2377 |
| `PO_DISTRIBUTIONS_ALL` | 2391 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2393 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2418 |
| `HR_ORGANIZATION_UNITS` | 2442 |
| `PO_DISTRIBUTIONS_ALL` | 2455 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2457 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2482 |
| `HR_ORGANIZATION_UNITS` | 2507 |
| `po_headers_all` | 2673 |
| `HR_ORGANIZATION_UNITS` | 2681 |
| `po_headers_all` | 2707 |
| `HR_ORGANIZATION_UNITS` | 2715 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2731 |
| `HR_ORGANIZATION_UNITS` | 2736 |
| `DKA_SPOFUSION_LINES_TMP` | 2751 |
| `HR_ORGANIZATION_UNITS` | 2756 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 2771 |
| `HR_ORGANIZATION_UNITS` | 2776 |
| `po_headers_all` | 2792 |
| `HR_ORGANIZATION_UNITS` | 2800 |
| `DKA_SPOFUSION_HEADERS_TMP` | 2889 |
| `HR_ORGANIZATION_UNITS` | 2902 |
| `DKA_SPOFUSION_LINES_TMP` | 2918 |
| `HR_ORGANIZATION_UNITS` | 2931 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 2945 |
| `HR_ORGANIZATION_UNITS` | 2958 |
| `PO_DISTRIBUTIONS_INTERFACE` | 2978 |
| `PO_HEADERS_INTERFACE` | 2980 |
| `HR_ORGANIZATION_UNITS` | 2987 |
| `po_line_locations_interface` | 3010 |
| `PO_HEADERS_INTERFACE` | 3012 |
| `HR_ORGANIZATION_UNITS` | 3019 |
| `PO_LINES_INTERFACE` | 3039 |
| `PO_HEADERS_INTERFACE` | 3041 |
| `HR_ORGANIZATION_UNITS` | 3048 |
| `PO_HEADERS_INTERFACE` | 3068 |
| `PO_HEADERS_INTERFACE` | 3070 |
| `HR_ORGANIZATION_UNITS` | 3077 |
| `PO_INTERFACE_ERRORS` | 3102 |
| `PO_HEADERS_INTERFACE` | 3105 |
| `po_interface_errors` | 3154 |
| `HR_ORGANIZATION_UNITS` | 3164 |
| `po_interface_errors` | 3183 |
| `HR_ORGANIZATION_UNITS` | 3200 |
| `po_interface_errors` | 3215 |
| `HR_ORGANIZATION_UNITS` | 3234 |
| `po_interface_errors` | 3251 |
| `HR_ORGANIZATION_UNITS` | 3269 |
| `DKA_SPOFUSION_HEADERS_TMP` | 3285 |
| `PO_HEADERS_INTERFACE` | 3291 |
| `HR_ORGANIZATION_UNITS` | 3298 |
| `DKA_SPOFUSION_LINES_TMP` | 3315 |
| `PO_HEADERS_INTERFACE` | 3320 |
| `HR_ORGANIZATION_UNITS` | 3331 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 3348 |
| `PO_HEADERS_INTERFACE` | 3353 |
| `HR_ORGANIZATION_UNITS` | 3364 |
| `DKA_SPOFUSION_HEADERS_TMP` | 3384 |
| `PO_HEADERS_ALL` | 3389 |
| `HR_ORGANIZATION_UNITS` | 3395 |
| `DKA_SPOFUSION_LINES_TMP` | 3410 |
| `DKA_SPOFUSION_HEADERS_TMP` | 3415 |
| `HR_ORGANIZATION_UNITS` | 3422 |
| `DKA_SPOFUSION_DISTRIBS_TMP` | 3434 |
| `DKA_SPOFUSION_HEADERS_TMP` | 3439 |
| `HR_ORGANIZATION_UNITS` | 3446 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 100 |
| `fnd_profile.value` | 118 |
| `Fnd_File.put_line` | 139 |
| `Fnd_File.put_line` | 151 |
| `fnd_file.put_line` | 160 |
| `Fnd_File.put_line` | 215 |
| `Fnd_File.put_line` | 216 |
| `Fnd_File.put_line` | 217 |
| `Fnd_File.put_line` | 218 |
| `Fnd_File.put_line` | 219 |
| `Fnd_File.put_line` | 306 |
| `Fnd_File.put_line` | 307 |
| `Fnd_File.put_line` | 308 |
| `Fnd_File.put_line` | 309 |
| `Fnd_File.put_line` | 326 |
| `Fnd_File.put_line` | 327 |
| `Fnd_File.put_line` | 343 |
| `Fnd_File.put_line` | 344 |
| `Fnd_File.put_line` | 347 |
| `Fnd_File.put_line` | 350 |
| `Fnd_File.put_line` | 351 |
| `Fnd_File.put_line` | 383 |
| `Fnd_File.put_line` | 384 |
| `Fnd_File.put_line` | 385 |
| `fnd_file.put_line` | 462 |
| `fnd_file.put_line` | 463 |
| `fnd_file.put_line` | 464 |
| `fnd_file.put_line` | 465 |
| `fnd_file.put_line` | 466 |
| `Fnd_File.put_line` | 470 |
| `Fnd_File.put_line` | 506 |
| `Fnd_File.put_line` | 507 |
| `fnd_file.put_line` | 510 |
| `fnd_file.put_line` | 511 |
| `fnd_file.put_line` | 512 |
| `fnd_file.put_line` | 517 |
| `Fnd_File.put_line` | 522 |
| `Fnd_File.put_line` | 525 |
| `Fnd_File.put_line` | 526 |
| `Fnd_Concurrent.wait_for_request` | 529 |
| `Fnd_file.put_line` | 532 |
| `Fnd_File.put_line` | 538 |
| `Fnd_File.put_line` | 539 |
| `Fnd_File.put_line` | 543 |
| `Fnd_File.put_line` | 544 |
| `fnd_file.put_line` | 552 |
| `Fnd_File.put_line` | 555 |
| `Fnd_File.put_line` | 561 |
| `Fnd_File.put_line` | 568 |
| `Fnd_File.put_line` | 569 |
| `Fnd_File.put_line` | 722 |
| `Fnd_File.put_line` | 849 |
| `Fnd_File.put_line` | 852 |
| `Fnd_File.put_line` | 1509 |
| `Fnd_File.put_line` | 1510 |
| `Fnd_File.put_line` | 1559 |
| `Fnd_File.put_line` | 1706 |
| `Fnd_File.put_line` | 1711 |
| `Fnd_File.put_line` | 1861 |
| `Fnd_File.put_line` | 1866 |
| `Fnd_File.put_line` | 1986 |
| `Fnd_File.put_line` | 1999 |
| `Fnd_File.put_line` | 2000 |
| `FND_PROFILE.VALUE` | 2072 |
| `Fnd_File.put_line` | 2076 |
| `Fnd_File.put_line` | 2077 |
| `fnd_file.put_line` | 2080 |
| `fnd_file.put_line` | 2081 |
| `fnd_file.put_line` | 2082 |
| `fnd_file.put_line` | 2087 |
| `fnd_file.put_line` | 2088 |
| `FND_GLOBAL.APPS_INITIALIZE` | 2100 |
| `Fnd_Request.set_org_id` | 2107 |
| `fnd_file.put_line` | 2115 |
| `fnd_file.put_line` | 2116 |
| `fnd_request.set_print_options` | 2124 |
| `Fnd_Request.submit_request` | 2127 |
| `Fnd_File.put_line` | 2156 |
| `Fnd_File.put_line` | 2162 |
| `Fnd_File.put_line` | 2163 |
| `fnd_file.put_line` | 2171 |
| `fnd_file.put_line` | 2172 |
| `fnd_file.put_line` | 2173 |
| `Fnd_File.put_line` | 2178 |
| `Fnd_Concurrent.wait_for_request` | 2182 |
| `Fnd_file.put_line` | 2191 |
| `Fnd_File.put_line` | 2197 |
| `Fnd_File.put_line` | 2200 |
| `Fnd_File.put_line` | 2205 |
| `Fnd_File.put_line` | 2208 |
| `fnd_file.put_line` | 2218 |
| `Fnd_File.put_line` | 2223 |
| `Fnd_File.put_line` | 2231 |
| `Fnd_File.put_line` | 2238 |
| `Fnd_File.put_line` | 2239 |
| `Fnd_File.put_line` | 2273 |
| `Fnd_File.put_line` | 2274 |
| `fnd_file.put_line` | 2277 |
| `fnd_file.put_line` | 2278 |
| `fnd_file.put_line` | 2279 |
| `fnd_file.put_line` | 2283 |
| `Fnd_File.put_line` | 2525 |
| `Fnd_File.put_line` | 2532 |
| `Fnd_File.put_line` | 2533 |
| `Fnd_File.put_line` | 2566 |
| `Fnd_File.put_line` | 2567 |
| `fnd_file.put_line` | 2570 |
| `fnd_file.put_line` | 2571 |
| `fnd_file.put_line` | 2572 |
| `fnd_request.set_print_options` | 2577 |
| `Fnd_Request.submit_request` | 2580 |
| `fnd_file.put_line` | 2593 |
| `Fnd_File.put_line` | 2597 |
| `Fnd_File.put_line` | 2600 |
| `Fnd_File.put_line` | 2601 |
| `Fnd_Concurrent.wait_for_request` | 2604 |
| `Fnd_file.put_line` | 2607 |
| `Fnd_File.put_line` | 2613 |
| `Fnd_File.put_line` | 2614 |
| `Fnd_File.put_line` | 2618 |
| `fnd_file.put_line` | 2626 |
| `Fnd_File.put_line` | 2629 |
| `Fnd_File.put_line` | 2635 |
| `Fnd_File.put_line` | 2642 |
| `Fnd_File.put_line` | 2643 |
| `Fnd_File.put_line` | 2696 |
| `fnd_file.put_line` | 2814 |
| `fnd_file.put_line` | 2815 |
| `fnd_file.put_line` | 2816 |
| `fnd_file.put_line` | 2818 |
| `fnd_file.put_line` | 2819 |
| `fnd_file.put_line` | 2820 |
| `fnd_file.put_line` | 2822 |
| `fnd_file.put_line` | 2825 |
| `fnd_file.put_line` | 2826 |
| `fnd_file.put_line` | 2827 |
| `fnd_file.put_line` | 2828 |
| `fnd_file.put_line` | 2830 |
| `Fnd_File.put_line` | 2860 |
| `Fnd_File.put_line` | 2861 |
| `Fnd_File.Put_Line` | 2977 |
| `Fnd_File.Put_Line` | 3006 |
| `Fnd_File.Put_Line` | 3009 |
| `Fnd_File.Put_Line` | 3035 |
| `Fnd_File.Put_Line` | 3037 |
| `Fnd_File.Put_Line` | 3064 |
| `Fnd_File.Put_Line` | 3067 |
| `Fnd_File.Put_Line` | 3094 |
| `Fnd_File.Put_Line` | 3097 |
| `Fnd_File.Put_Line` | 3107 |
| `Fnd_File.put_line` | 3114 |
| `Fnd_File.put_line` | 3115 |
| `Fnd_File.put_line` | 3123 |
| `Fnd_File.put_line` | 3124 |
| `Fnd_File.put_line` | 3516 |
| `Fnd_File.put_line` | 3517 |
| `Fnd_File.put_line` | 3558 |
| `Fnd_File.put_line` | 3564 |
| `Fnd_File.put_line` | 3584 |
| `Fnd_File.put_line` | 3594 |
| `Fnd_File.put_line` | 3611 |
| `Fnd_File.put_line` | 3630 |
| `Fnd_File.put_line` | 3674 |
| `Fnd_File.put_line` | 3675 |
| `Fnd_File.put_line` | 3682 |
| `Fnd_File.put_line` | 3725 |
| `Fnd_File.put_line` | 3747 |
| `Fnd_File.put_line` | 3748 |
| `Fnd_File.put_line` | 3750 |
| `Fnd_File.put_line` | 3758 |
| `Fnd_File.put_line` | 3759 |
| `Fnd_File.put_line` | 3760 |
| `Fnd_File.put_line` | 3761 |
| `Fnd_File.put_line` | 3766 |
| `Fnd_File.put_line` | 3767 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `POXPOPDOI` | 2127 |
| `POXPIERR` | 2580 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 524, 1495, 1502, 1992, 2158, 2599, 3458, 3509 |
| rollback | 2, 264 |
| when_others | 162, 208, 263, 564, 780, 832, 864, 895, 923, 951, 979, 1018, 1056, 1085, 1111, 1157, 1191, 1222, 1258, 1307, 1335, 1505, 1547, 1702, 1857, 1982, 1995, 2110, 2234, 2528, 2638, 2856, 3110, 3119, 3512, 3762 |
| suppression | 2978, 3010, 3039, 3068, 3102 |
| soumission | 2127, 2580 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSPOIMP / DKA | `DKA_FUSPOIMP_PKG.main` | dka/12.0.0/admin/import/DKA_FUSPOIMP.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
