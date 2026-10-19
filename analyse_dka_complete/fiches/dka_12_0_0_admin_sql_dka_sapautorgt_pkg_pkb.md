# DKA_SAPAUTORGT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPAUTORGT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPAUTORGT_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1508 ; encodage : cp1252 (repli). SHA-256 : `91c21019e1a803ce3aa477a9d32cadee4ddf8f8564917edcbb2154e5f601cfbc`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `wait_program_end` | 136 |
| `launch_program_payment` | 285 |
| `launch_program_recalculate` | 486 |
| `main` | 685 |
| `delete_save_tables` | 827 |
| `is_date` | 846 |
| `recalculate` | 1292 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 158 |
| `fnd_concurrent_requests` | 176 |
| `fnd_concurrent_requests` | 178 |
| `AP_INV_SELECTION_CRITERIA_ALL` | 248 |
| `FND_CONC_REQ_SUMMARY_V` | 250 |
| `ap_payment_templates` | 321 |
| `ap_inv_selection_criteria_all` | 424 |
| `fnd_conc_req_summary_v` | 428 |
| `dka_sapautorgt_tmp` | 441 |
| `fnd_concurrent_requests` | 508 |
| `fnd_concurrent_requests` | 512 |
| `ap_invoices_all` | 703 |
| `Ap_Pay_Group` | 720 |
| `Ap_OU_Group` | 724 |
| `hr_all_organization_units` | 737 |
| `ap_invoices_all` | 748 |
| `ra_customer_trx_all` | 766 |
| `AP_INVOICES_ALL` | 770 |
| `ap_checks_all` | 775 |
| `all_tables` | 832 |
| `dual` | 858 |
| `dka_parameters` | 935 |
| `DKA_AR_REMB_AVOIR_LIST` | 940 |
| `DKA_AR_REMB_AVOIR_LIST` | 942 |
| `dka_ar_remboursement_avoirs` | 943 |
| `fnd_flex_value_sets` | 957 |
| `DKA.DKA_IEOAPSAT01_APIMP_LINE` | 1052 |
| `DKA.DKA_IEOAPSAT01_APIMP_HDR` | 1058 |
| `DKA.DKA_SAPAUTORGT_TMP` | 1064 |
| `ap_payment_templates` | 1118 |
| `gl_period_statuses` | 1161 |
| `DKA_AR_REMB_AVOIR_LIST` | 1230 |
| `Ap_Inv_Selection_Criteria_All` | 1311 |
| `fnd_concurrent_requests` | 1350 |
| `Ap_Inv_Selection_Criteria_All` | 1395 |
| `dka_sapautorgt_tmp` | 1403 |
| `dka_sapautorgt_tmp` | 1409 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_Concurrent.wait_for_request` | 198 |
| `Fnd_File.put_line` | 201 |
| `Fnd_File.put_line` | 207 |
| `Dka_Tools_Pkg.put_log_message` | 208 |
| `Fnd_File.put_line` | 213 |
| `Fnd_File.put_line` | 229 |
| `Fnd_File.put_line` | 231 |
| `Dka_Tools_Pkg.put_log_message` | 234 |
| `Dka_Tools_Pkg.put_log_message` | 267 |
| `Dka_Stransco_Pkg.etl_get_value_f` | 309 |
| `fnd_request.set_print_options` | 314 |
| `dka_tools_pkg.put_log_message` | 315 |
| `fnd_profile.value` | 315 |
| `dka_tools_pkg.put_log_message` | 317 |
| `fnd_request.submit_request` | 327 |
| `fnd_file.put_line` | 347 |
| `dka_tools_pkg.put_log_message` | 351 |
| `fnd_file.put_line` | 358 |
| `dka_tools_pkg.put_log_message` | 361 |
| `fnd_concurrent.wait_for_request` | 372 |
| `fnd_file.put_line` | 383 |
| `fnd_file.put_line` | 390 |
| `fnd_file.put_line` | 393 |
| `fnd_file.put_line` | 398 |
| `fnd_file.put_line` | 410 |
| `fnd_file.put_line` | 415 |
| `fnd_file.put_line` | 452 |
| `dka_tools_pkg.put_log_message` | 455 |
| `dka_tools_pkg.put_log_message` | 467 |
| `Dka_Stransco_Pkg.etl_get_value_f` | 518 |
| `fnd_request.set_print_options` | 523 |
| `dka_tools_pkg.put_log_message` | 524 |
| `fnd_profile.value` | 524 |
| `dka_tools_pkg.put_log_message` | 526 |
| `FND_REQUEST.SUBMIT_REQUEST` | 529 |
| `Fnd_File.put_line` | 543 |
| `Dka_Tools_Pkg.put_log_message` | 545 |
| `Fnd_File.put_line` | 549 |
| `Dka_Tools_Pkg.put_log_message` | 550 |
| `fnd_concurrent.wait_for_request` | 561 |
| `fnd_file.put_line` | 572 |
| `fnd_file.put_line` | 581 |
| `fnd_file.put_line` | 584 |
| `fnd_file.put_line` | 589 |
| `fnd_file.put_line` | 601 |
| `fnd_file.put_line` | 606 |
| `fnd_concurrent.wait_for_request` | 612 |
| `fnd_file.put_line` | 623 |
| `fnd_file.put_line` | 632 |
| `fnd_file.put_line` | 635 |
| `fnd_file.put_line` | 640 |
| `fnd_file.put_line` | 652 |
| `fnd_file.put_line` | 657 |
| `dka_tools_pkg.put_log_message` | 670 |
| `Ap_Invoices_utility_pkg.get_payment_status` | 711 |
| `Ap_Invoices_utility_pkg.get_approval_status` | 712 |
| `Ap_Invoices_utility_pkg.get_payment_status` | 712 |
| `ap_invoices_utility_pkg.get_payment_status` | 752 |
| `ap_invoices_utility_pkg.get_approval_status` | 753 |
| `ap_invoices_utility_pkg.get_payment_status` | 755 |
| `Dka_Tools_Pkg.put_log_message` | 899 |
| `Dka_Tools_Pkg.put_log_message` | 952 |
| `Dka_Tools_Pkg.put_log_message` | 976 |
| `Dka_Tools_Pkg.IS_BANK_HOLIDAY` | 977 |
| `Dka_Tools_Pkg.Get_Next_Working_Day` | 981 |
| `Dka_Tools_Pkg.put_log_message` | 986 |
| `Dka_Tools_Pkg.put_log_message` | 994 |
| `Dka_Tools_Pkg.Get_Next_Working_Day` | 998 |
| `Dka_Tools_Pkg.put_log_message` | 1002 |
| `Dka_Tools_Pkg.get_parameter` | 1011 |
| `Dka_Tools_Pkg.put_log_message` | 1016 |
| `Dka_Tools_Pkg.put_log_message` | 1020 |
| `Dka_Tools_Pkg.put_log_message` | 1030 |
| `Dka_Tools_Pkg.put_log_message` | 1035 |
| `Dka_Tools_Pkg.put_log_message` | 1040 |
| `Dka_Tools_Pkg.put_log_message` | 1051 |
| `Dka_Tools_Pkg.put_log_message` | 1057 |
| `Dka_Tools_Pkg.put_log_message` | 1063 |
| `fnd_profile.value` | 1083 |
| `fnd_profile.value` | 1084 |
| `fnd_profile.value` | 1085 |
| `fnd_global.apps_initialize` | 1093 |
| `Fnd_File.put_line` | 1110 |
| `Dka_Tools_Pkg.put_log_message` | 1111 |
| `Fnd_File.put_line` | 1123 |
| `Dka_Tools_Pkg.put_log_message` | 1124 |
| `Fnd_File.put_line` | 1145 |
| `Dka_Tools_Pkg.put_log_message` | 1146 |
| `fnd_global.apps_initialize` | 1203 |
| `Dka_Tools_Pkg.put_log_message` | 1276 |
| `Dka_Tools_Pkg.put_log_message` | 1379 |
| `fnd_profile.value` | 1382 |
| `fnd_profile.value` | 1383 |
| `fnd_profile.value` | 1384 |
| `Dka_Tools_Pkg.put_log_message` | 1389 |
| `fnd_global.apps_initialize` | 1390 |
| `Dka_Tools_Pkg.put_log_message` | 1424 |
| `fnd_concurrent.wait_for_request` | 1438 |
| `fnd_file.put_line` | 1449 |
| `fnd_file.put_line` | 1457 |
| `fnd_file.put_line` | 1460 |
| `fnd_file.put_line` | 1465 |
| `fnd_file.put_line` | 1477 |
| `fnd_file.put_line` | 1482 |
| `fnd_global.apps_initialize` | 1489 |
| `Dka_Tools_Pkg.put_log_message` | 1495 |
| `Dka_Tools_Pkg.put_log_message` | 1501 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `APXPBASL` | 327 |
| `APXRECLC` | 529 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 356, 548, 945, 1022, 1069, 1270 |
| when_others | 255, 264, 323, 433, 450, 464, 667, 861, 968, 1122, 1175, 1273, 1423, 1498 |
| suppression | 940 |
| truncate | 1071, 1072, 1073 |
| soumission | 327, 529 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_APXRECLC / DKA | `DKA_SAPAUTORGT_PKG.recalculate` | dka/12.0.0/admin/import/DKA_APXRECLC.prt:530 |
| DKA_SAPAUTORGT / DKA | `dka_sapautorgt_pkg.main` | dka/12.0.0/admin/import/DKA_SAPAUTORGT.prt:439 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
