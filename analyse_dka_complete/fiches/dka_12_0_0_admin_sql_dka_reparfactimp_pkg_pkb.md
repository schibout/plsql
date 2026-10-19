# DKA_REPARFACTIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPARFACTIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPARFACTIMP_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2574 ; encodage : cp1252 (repli). SHA-256 : `e2f6b55be85f1b643918662f014370c6f3770735e3805be21b5582ea92b76aef`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 116 |
| `init_environement` | 208 |
| `wait_import` | 247 |
| `output_header` | 330 |
| `Request_parameters` | 383 |
| `output_end` | 473 |
| `Add_Message` | 503 |
| `get_organization_id` | 551 |
| `get_cust_acct_id` | 576 |
| `get_cust_site_use_id` | 600 |
| `Launch_Loader` | 639 |
| `validate_data` | 765 |
| `import_data` | 1468 |
| `Launch_OI` | 1988 |
| `Report_Bilan` | 2162 |
| `set_recovery_mode` | 2229 |
| `main` | 2273 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 169 |
| `fnd_responsibility` | 219 |
| `fnd_concurrent_programs` | 345 |
| `fnd_concurrent_requests` | 389 |
| `fnd_concurrent_requests` | 420 |
| `fnd_concurrent_requests` | 437 |
| `hr_operating_units` | 561 |
| `HZ_CUST_ACCOUNTS` | 584 |
| `HZ_CUST_SITE_USES_ALL` | 609 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 698 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 704 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 708 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 714 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 831 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 849 |
| `OF` | 860 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 882 |
| `OF` | 894 |
| `RA_BATCH_SOURCES_ALL` | 988 |
| `RA_CUST_TRX_TYPES_ALL` | 1020 |
| `RA_CUST_TRX_TYPES_ALL` | 1033 |
| `RA_CUST_TRX_TYPES_ALL` | 1045 |
| `RA_TERMS_VL` | 1087 |
| `PA_PROJECTS_ALL` | 1121 |
| `ZX_RATES_VL` | 1190 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 1314 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 1333 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 1339 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 1358 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 1366 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 1379 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 1395 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 1399 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 1411 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 1424 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 1428 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 1503 |
| `OF` | 1510 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 1519 |
| `OF` | 1532 |
| `ar_customers` | 1575 |
| `ra_cust_receipt_methods` | 1580 |
| `RA_INTERFACE_LINES_ALL` | 1599 |
| `RA_INTERFACE_DISTRIBUTIONS_ALL` | 1859 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 1949 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 1955 |
| `AR_AI_BATCH_SOURCE_V` | 2022 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 2180 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 2186 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 2239 |
| `DKA_DISTRIBUTIONS_FACTURE_TMP` | 2244 |
| `ra_interface_lines_all` | 2292 |
| `hr_operating_units` | 2293 |
| `DKA_ENTETE_LIGNES_FACTURE_TMP` | 2309 |
| `dual` | 2340 |
| `ra_batch_sources_all` | 2393 |
| `dka_entete_lignes_facture_tmp` | 2468 |
| `ra_customer_trx_all` | 2469 |
| `ar_payment_schedules_all` | 2475 |
| `ra_cust_trx_types_all` | 2477 |
| `ra_customer_trx_all` | 2491 |
| `ar_payment_schedules_all` | 2495 |
| `ra_batch_sources_all` | 2509 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 129 |
| `fnd_profile.value` | 145 |
| `Fnd_File.put_line` | 162 |
| `Fnd_File.put_line` | 174 |
| `fnd_file.put_line` | 183 |
| `fnd_global.apps_initialize` | 222 |
| `Fnd_File.put_line` | 223 |
| `Fnd_File.put_line` | 229 |
| `Fnd_File.put_line` | 233 |
| `Fnd_Concurrent.wait_for_request` | 263 |
| `Fnd_File.put_line` | 272 |
| `Fnd_File.put_line` | 279 |
| `Fnd_File.put_line` | 286 |
| `Fnd_File.put_line` | 298 |
| `Fnd_File.put_line` | 360 |
| `Fnd_File.put_line` | 361 |
| `Fnd_File.put_line` | 362 |
| `Fnd_File.put_line` | 363 |
| `Fnd_File.put_line` | 364 |
| `Fnd_File.put_line` | 405 |
| `Fnd_File.put_line` | 406 |
| `Fnd_File.put_line` | 407 |
| `Fnd_File.put_line` | 408 |
| `Fnd_File.put_line` | 425 |
| `Fnd_File.put_line` | 426 |
| `Fnd_File.put_line` | 442 |
| `Fnd_File.put_line` | 443 |
| `Fnd_File.put_line` | 446 |
| `Fnd_File.put_line` | 449 |
| `Fnd_File.put_line` | 450 |
| `Fnd_File.put_line` | 482 |
| `Fnd_File.put_line` | 483 |
| `Fnd_File.put_line` | 484 |
| `Fnd_File.put_line` | 515 |
| `Fnd_File.put_line` | 517 |
| `Fnd_File.put_line` | 519 |
| `Fnd_File.put_line` | 521 |
| `Fnd_File.put_line` | 527 |
| `Fnd_File.put_line` | 591 |
| `Fnd_File.put_line` | 617 |
| `Fnd_File.put_line` | 651 |
| `Fnd_File.put_line` | 652 |
| `fnd_file.put_line` | 655 |
| `fnd_file.put_line` | 656 |
| `fnd_file.put_line` | 657 |
| `fnd_request.set_print_options` | 662 |
| `Fnd_Request.submit_request` | 665 |
| `fnd_file.put_line` | 676 |
| `Fnd_File.put_line` | 679 |
| `Fnd_File.put_line` | 682 |
| `Fnd_File.put_line` | 683 |
| `Fnd_Concurrent.wait_for_request` | 686 |
| `Fnd_file.put_line` | 689 |
| `Fnd_File.put_line` | 695 |
| `Fnd_File.put_line` | 696 |
| `Fnd_File.put_line` | 720 |
| `fnd_file.put_line` | 728 |
| `Fnd_File.put_line` | 731 |
| `Fnd_File.put_line` | 737 |
| `Fnd_File.put_line` | 744 |
| `Fnd_File.put_line` | 745 |
| `Fnd_File.put_line` | 911 |
| `Fnd_File.put_line` | 912 |
| `dka_tools_pkg.ins_prog_message` | 945 |
| `dka_rep_transco_pkg.get_transco` | 958 |
| `dka_tools_pkg.ins_prog_message` | 974 |
| `dka_tools_pkg.ins_prog_message` | 999 |
| `dka_rep_transco_pkg.get_transco` | 1012 |
| `dka_tools_pkg.ins_prog_message` | 1061 |
| `dka_rep_transco_pkg.get_transco` | 1081 |
| `dka_tools_pkg.ins_prog_message` | 1097 |
| `dka_rep_transco_pkg.get_transco` | 1112 |
| `dka_tools_pkg.ins_prog_message` | 1134 |
| `dka_rep_transco_pkg.get_transco` | 1172 |
| `dka_tools_pkg.ins_prog_message` | 1209 |
| `DKA_REP_TRANSCO_PKG.get_cle_transco` | 1255 |
| `dka_tools_pkg.ins_prog_message` | 1285 |
| `Fnd_File.put_line` | 1393 |
| `Fnd_File.put_line` | 1439 |
| `Fnd_File.put_line` | 1447 |
| `Fnd_File.put_line` | 1448 |
| `Fnd_File.put_line` | 1535 |
| `Fnd_File.put_line` | 1536 |
| `DKA_AR_TOOLS_PKG.issurtaxeaccount` | 1845 |
| `Fnd_File.put_line` | 1960 |
| `Fnd_File.put_line` | 1966 |
| `Fnd_File.put_line` | 1967 |
| `Fnd_File.put_line` | 2004 |
| `Fnd_File.put_line` | 2005 |
| `fnd_file.put_line` | 2008 |
| `fnd_file.put_line` | 2009 |
| `fnd_file.put_line` | 2010 |
| `fnd_request.set_print_options` | 2015 |
| `fnd_file.put_line` | 2040 |
| `Fnd_File.put_line` | 2041 |
| `fnd_request.submit_request` | 2045 |
| `fnd_profile.value` | 2052 |
| `fnd_file.put_line` | 2088 |
| `Fnd_File.put_line` | 2092 |
| `Fnd_File.put_line` | 2099 |
| `Fnd_File.put_line` | 2100 |
| `Fnd_File.put_line` | 2136 |
| `Fnd_File.put_line` | 2143 |
| `Fnd_File.put_line` | 2144 |
| `Fnd_File.put_line` | 2169 |
| `fnd_file.put_line` | 2190 |
| `fnd_file.put_line` | 2191 |
| `fnd_file.put_line` | 2192 |
| `fnd_file.put_line` | 2194 |
| `fnd_file.put_line` | 2195 |
| `fnd_file.put_line` | 2197 |
| `fnd_file.put_line` | 2198 |
| `fnd_file.put_line` | 2200 |
| `fnd_file.put_line` | 2201 |
| `fnd_file.put_line` | 2204 |
| `Fnd_File.put_line` | 2205 |
| `Fnd_File.put_line` | 2213 |
| `Fnd_File.put_line` | 2214 |
| `Fnd_File.put_line` | 2253 |
| `Fnd_File.put_line` | 2254 |
| `Fnd_File.put_line` | 2322 |
| `Fnd_File.put_line` | 2328 |
| `fnd_date.canonical_to_date` | 2335 |
| `Fnd_File.put_line` | 2355 |
| `Fnd_File.put_line` | 2370 |
| `Fnd_File.put_line` | 2381 |
| `Fnd_File.put_line` | 2410 |
| `Fnd_File.put_line` | 2423 |
| `Fnd_File.put_line` | 2437 |
| `Fnd_File.put_line` | 2546 |
| `Fnd_File.put_line` | 2547 |
| `Fnd_File.put_line` | 2549 |
| `Fnd_File.put_line` | 2558 |
| `Fnd_File.put_line` | 2559 |
| `Fnd_File.put_line` | 2560 |
| `Fnd_File.put_line` | 2565 |
| `Fnd_File.put_line` | 2566 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_DKA_REPARFACTIMP` | 665 |
| `RAXMTR` | 2045 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 681, 1441, 2094, 2502, 2544 |
| rollback | 2 |
| when_others | 185, 234, 353, 567, 590, 616, 740, 1052, 1091, 1128, 1203, 1279, 1444, 1587, 1963, 2139, 2209, 2249, 2561 |
| soumission | 665, 2045 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPARFACTIMP / DKA | `DKA_REPARFACTIMP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPARFACTIMP.prt:520 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
