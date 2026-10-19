# DKA_REPAPFCTIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPAPFCTIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPAPFCTIMP_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2735 ; encodage : cp1252 (repli). SHA-256 : `df51b0557f4473ec497694ab8b772074aaf84abe0c11051ff4c04ffa8300932b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 155 |
| `init_environement` | 237 |
| `Launch_Loader` | 319 |
| `Report_Bilan` | 421 |
| `program_import_factures` | 485 |
| `purge_data` | 665 |
| `insert_ap_invoices_interface` | 733 |
| `insert_ap_invoice_lines_intrf` | 769 |
| `insert_ap_holds_all` | 806 |
| `validate_factures` | 843 |
| `validate_lignes_factures` | 908 |
| `check_holds` | 963 |
| `MAIN` | 1002 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility` | 278 |
| `dka_ap_rep_entete_facture_tmp` | 388 |
| `dka_ap_rep_lignes_facture_tmp` | 390 |
| `dka_ap_rep_blocages_tmp` | 392 |
| `ap_invoices_interface` | 541 |
| `ap_invoices_interface` | 549 |
| `ap_interface_rejections` | 576 |
| `ap_interface_rejections` | 597 |
| `dka_ap_rep_entete_facture_tmp` | 674 |
| `ap_invoices_interface` | 677 |
| `dka_ap_rep_lignes_facture_tmp` | 687 |
| `ap_invoices_interface` | 690 |
| `ap_interface_rejections` | 696 |
| `ap_invoices_interface` | 698 |
| `ap_invoice_lines_interface` | 701 |
| `ap_invoices_interface` | 703 |
| `ap_invoices_interface` | 706 |
| `ap_invoices_interface` | 740 |
| `ap_invoice_lines_interface` | 775 |
| `ap_holds_all` | 812 |
| `dka_ap_rep_entete_facture_tmp` | 860 |
| `dka_ap_rep_entete_facture_tmp` | 875 |
| `dka_ap_rep_lignes_facture_tmp` | 925 |
| `dka_ap_rep_lignes_facture_tmp` | 940 |
| `ap_holds_all` | 975 |
| `dka_ap_rep_entete_facture_tmp` | 1090 |
| `dka_ap_rep_lignes_facture_tmp` | 1093 |
| `dka_ap_rep_blocages_tmp` | 1096 |
| `dka_ap_rep_entete_facture_tmp` | 1105 |
| `gl_period_statuses` | 1222 |
| `DKA_AP_REP_ENTETE_FACTURE_TMP` | 1228 |
| `hr_operating_units` | 1246 |
| `ap_suppliers` | 1303 |
| `ap_supplier_sites_all` | 1340 |
| `gl_period_statuses` | 1470 |
| `ce_bank_branches_v` | 1647 |
| `ce_bank_branches_v` | 1654 |
| `ce_bank_branches_v` | 1664 |
| `ce_bank_branches_v` | 1672 |
| `ce_bank_branches_v` | 1680 |
| `iby_ext_bank_accounts` | 1772 |
| `zx_rates_b` | 1891 |
| `dka_ap_rep_entete_facture_tmp` | 2000 |
| `dka_ap_rep_entete_facture_tmp` | 2016 |
| `dka_ap_rep_lignes_facture_tmp` | 2023 |
| `dka_ap_rep_blocages_tmp` | 2061 |
| `zx_rates_b` | 2176 |
| `dka_ap_rep_lignes_facture_tmp` | 2189 |
| `ap_invoices_interface` | 2345 |
| `PER_SECURITY_ORGANIZATIONS_V` | 2348 |
| `ap_invoices_all` | 2415 |
| `ap_suppliers` | 2416 |
| `dka_ap_rep_blocages_tmp` | 2426 |
| `dka_ap_rep_blocages_tmp` | 2445 |
| `dka_ap_rep_blocages_tmp` | 2472 |
| `fnd_user` | 2493 |
| `dka_ap_rep_blocages_tmp` | 2529 |
| `dka_ap_rep_blocages_tmp` | 2549 |
| `dka_ap_rep_blocages_tmp` | 2571 |
| `dka_ap_rep_blocages_tmp` | 2585 |
| `dka_ap_rep_entete_facture_tmp` | 2617 |
| `ap_invoices_interface` | 2622 |
| `ap_payment_schedules_all` | 2632 |
| `dka_ap_rep_entete_facture_tmp` | 2660 |
| `dka_ap_rep_lignes_facture_tmp` | 2666 |
| `dka_ap_rep_blocages_tmp` | 2672 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 166 |
| `fnd_profile.value` | 186 |
| `Fnd_File.put_line` | 207 |
| `Fnd_File.put_line` | 214 |
| `Fnd_File.put_line` | 245 |
| `fnd_global.apps_initialize` | 283 |
| `Fnd_File.put_line` | 288 |
| `Fnd_File.put_line` | 292 |
| `Fnd_File.put_line` | 296 |
| `Fnd_File.put_line` | 330 |
| `Fnd_File.put_line` | 332 |
| `Fnd_File.put_line` | 333 |
| `Fnd_File.put_line` | 334 |
| `Fnd_Request.submit_request` | 340 |
| `Fnd_File.put_line` | 347 |
| `Fnd_File.put_line` | 351 |
| `Fnd_File.put_line` | 355 |
| `Fnd_File.put_line` | 356 |
| `Fnd_Concurrent.wait_for_request` | 358 |
| `Fnd_File.put_line` | 361 |
| `Fnd_File.put_line` | 367 |
| `Fnd_File.put_line` | 373 |
| `Fnd_File.put_line` | 381 |
| `Fnd_File.put_line` | 394 |
| `Fnd_File.put_line` | 401 |
| `Fnd_File.put_line` | 402 |
| `Fnd_File.put_line` | 428 |
| `Fnd_File.put_line` | 437 |
| `Fnd_File.put_line` | 438 |
| `Fnd_File.put_line` | 439 |
| `Fnd_File.put_line` | 440 |
| `Fnd_File.put_line` | 441 |
| `Fnd_File.put_line` | 442 |
| `Fnd_File.put_line` | 443 |
| `Fnd_File.put_line` | 444 |
| `Fnd_File.put_line` | 445 |
| `Fnd_File.put_line` | 446 |
| `Fnd_File.put_line` | 447 |
| `Fnd_File.put_line` | 449 |
| `Fnd_File.put_line` | 450 |
| `Fnd_File.put_line` | 451 |
| `Fnd_File.put_line` | 452 |
| `Fnd_File.put_line` | 453 |
| `Fnd_File.put_line` | 454 |
| `Fnd_File.put_line` | 455 |
| `Fnd_File.put_line` | 457 |
| `Fnd_File.put_line` | 459 |
| `Fnd_File.put_line` | 466 |
| `Fnd_File.put_line` | 467 |
| `Fnd_File.put_line` | 499 |
| `fnd_request.submit_request` | 500 |
| `Fnd_File.put_line` | 516 |
| `Fnd_File.put_line` | 519 |
| `Fnd_File.put_line` | 523 |
| `Fnd_Concurrent.wait_for_request` | 528 |
| `Fnd_File.put_line` | 531 |
| `Fnd_File.put_line` | 537 |
| `Fnd_File.put_line` | 556 |
| `Fnd_File.put_line` | 557 |
| `Fnd_File.put_line` | 562 |
| `Fnd_File.put_line` | 563 |
| `Fnd_File.put_line` | 564 |
| `Fnd_File.put_line` | 565 |
| `Fnd_File.put_line` | 566 |
| `Fnd_File.put_line` | 567 |
| `Fnd_File.put_line` | 617 |
| `Fnd_File.put_line` | 631 |
| `Fnd_File.put_line` | 640 |
| `Fnd_File.put_line` | 647 |
| `Fnd_File.put_line` | 671 |
| `Fnd_File.put_line` | 699 |
| `Fnd_File.put_line` | 704 |
| `Fnd_File.put_line` | 709 |
| `Fnd_File.put_line` | 713 |
| `Fnd_File.put_line` | 739 |
| `Fnd_File.put_line` | 744 |
| `Fnd_File.put_line` | 748 |
| `Fnd_File.put_line` | 749 |
| `Fnd_File.put_line` | 774 |
| `Fnd_File.put_line` | 780 |
| `Fnd_File.put_line` | 811 |
| `Fnd_File.put_line` | 816 |
| `Fnd_File.put_line` | 817 |
| `Fnd_File.put_line` | 821 |
| `Fnd_File.put_line` | 822 |
| `Fnd_File.put_line` | 856 |
| `Fnd_File.put_line` | 921 |
| `Fnd_File.put_line` | 971 |
| `Fnd_File.put_line` | 981 |
| `Fnd_File.put_line` | 1129 |
| `Fnd_File.put_line` | 1138 |
| `Fnd_File.put_line` | 1139 |
| `Fnd_File.put_line` | 1140 |
| `Fnd_File.put_line` | 1141 |
| `Fnd_File.put_line` | 1142 |
| `Fnd_File.put_line` | 1143 |
| `Fnd_File.put_line` | 1146 |
| `Fnd_File.put_line` | 1147 |
| `Fnd_File.put_line` | 1148 |
| `Fnd_File.put_line` | 1149 |
| `Fnd_File.put_line` | 1150 |
| `Fnd_File.put_line` | 1151 |
| `Fnd_File.put_line` | 1154 |
| `Fnd_File.put_line` | 1155 |
| `Fnd_File.put_line` | 1156 |
| `Fnd_File.put_line` | 1157 |
| `Fnd_File.put_line` | 1158 |
| `Fnd_File.put_line` | 1159 |
| `Fnd_File.put_line` | 1160 |
| `Fnd_File.put_line` | 1161 |
| `Fnd_File.put_line` | 1162 |
| `Fnd_File.put_line` | 1168 |
| `Fnd_File.put_line` | 1169 |
| `Fnd_File.put_line` | 1170 |
| `Fnd_File.put_line` | 1171 |
| `Fnd_File.put_line` | 1181 |
| `Fnd_File.put_line` | 1184 |
| `Fnd_File.put_line` | 1195 |
| `Fnd_File.put_line` | 1198 |
| `Fnd_File.put_line` | 1199 |
| `Fnd_File.put_line` | 1200 |
| `Fnd_File.put_line` | 1201 |
| `Fnd_File.put_line` | 1207 |
| `Fnd_File.put_line` | 1210 |
| `Fnd_File.put_line` | 1212 |
| `Fnd_File.put_line` | 1213 |
| `Fnd_File.put_line` | 1214 |
| `Fnd_File.put_line` | 1215 |
| `Fnd_File.put_line` | 1216 |
| `Fnd_File.put_line` | 1217 |
| `fnd_date.canonical_to_date` | 1223 |
| `dka_rep_transco_pkg.get_transco` | 1233 |
| `dka_rep_transco_pkg.get_transco` | 1395 |
| `dka_rep_transco_pkg.get_transco` | 1437 |
| `dka_rep_transco_pkg.get_transco` | 1443 |
| `fnd_date.canonical_to_date` | 1471 |
| `dka_rep_transco_pkg.get_cle_transco_f` | 1490 |
| `iby_security_pkg.get_hash` | 1773 |
| `iby_security_pkg.get_hash` | 1774 |
| `dka_rep_transco_pkg.get_transco` | 1876 |
| `dka_rep_transco_pkg.get_transco` | 1932 |
| `Dka_Tools_Pkg.get_code_combination_id` | 1953 |
| `Fnd_File.put_line` | 2006 |
| `dka_rep_transco_pkg.get_transco` | 2152 |
| `dka_rep_transco_pkg.get_transco` | 2210 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2267 |
| `Fnd_File.put_line` | 2322 |
| `Fnd_File.put_line` | 2324 |
| `Fnd_File.put_line` | 2334 |
| `Fnd_File.put_line` | 2335 |
| `Fnd_File.put_line` | 2336 |
| `Fnd_File.put_line` | 2337 |
| `Fnd_File.put_line` | 2338 |
| `fnd_profile.value` | 2349 |
| `Fnd_File.put_line` | 2357 |
| `Fnd_File.put_line` | 2373 |
| `Fnd_File.put_line` | 2375 |
| `Fnd_File.put_line` | 2388 |
| `Fnd_File.put_line` | 2390 |
| `Fnd_File.put_line` | 2404 |
| `Fnd_File.put_line` | 2405 |
| `Fnd_File.put_line` | 2406 |
| `Fnd_File.put_line` | 2407 |
| `Fnd_File.put_line` | 2468 |
| `Fnd_File.put_line` | 2523 |
| `Fnd_File.put_line` | 2574 |
| `Fnd_File.put_line` | 2575 |
| `Fnd_File.put_line` | 2576 |
| `Fnd_File.put_line` | 2577 |
| `Fnd_File.put_line` | 2578 |
| `Fnd_File.put_line` | 2579 |
| `Fnd_File.put_line` | 2589 |
| `Fnd_File.put_line` | 2602 |
| `Fnd_File.put_line` | 2604 |
| `Fnd_File.put_line` | 2612 |
| `Fnd_File.put_line` | 2613 |
| `Fnd_File.put_line` | 2614 |
| `Fnd_File.put_line` | 2615 |
| `Fnd_File.put_line` | 2640 |
| `Fnd_File.put_line` | 2689 |
| `Fnd_File.put_line` | 2690 |
| `Fnd_File.put_line` | 2691 |
| `Fnd_File.put_line` | 2692 |
| `Fnd_File.put_line` | 2693 |
| `Fnd_File.put_line` | 2700 |
| `Fnd_File.put_line` | 2701 |
| `Fnd_File.put_line` | 2702 |
| `Fnd_File.put_line` | 2703 |
| `Fnd_File.put_line` | 2704 |
| `Fnd_File.put_line` | 2705 |
| `Fnd_File.put_line` | 2706 |
| `Fnd_File.put_line` | 2707 |
| `Fnd_File.put_line` | 2708 |
| `Fnd_File.put_line` | 2709 |
| `Fnd_File.put_line` | 2710 |
| `Fnd_File.put_line` | 2717 |
| `Fnd_File.put_line` | 2718 |
| `Fnd_File.put_line` | 2719 |
| `Fnd_File.put_line` | 2720 |
| `Fnd_File.put_line` | 2721 |
| `Fnd_File.put_line` | 2722 |
| `Fnd_File.put_line` | 2723 |
| `Fnd_File.put_line` | 2724 |
| `Fnd_File.put_line` | 2725 |
| `Fnd_File.put_line` | 2726 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_REPAPFCTIMP_LOADER` | 340 |
| `APXIIMPT` | 500 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 354, 522, 2688 |
| rollback | 2711, 2727 |
| when_others | 215, 297, 397, 462, 747, 783, 820, 866, 882, 931, 947, 984, 1278, 1318, 1362, 1503, 1684, 1687, 1690, 1693, 1778, 1907, 1971, 2012, 2067, 2195, 2433, 2440, 2452, 2480, 2496, 2536, 2557, 2593, 2643, 2713 |
| suppression | 696, 701, 706 |
| soumission | 340, 500 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPAPFCTIMP / DKA | `DKA_REPAPFCTIMP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPAPFCTIMP.prt:596 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
