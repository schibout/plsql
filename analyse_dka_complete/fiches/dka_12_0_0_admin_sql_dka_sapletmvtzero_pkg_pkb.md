# DKA_SAPLETMVTZERO_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPLETMVTZERO_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPLETMVTZERO_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1502 ; encodage : cp1252 (repli). SHA-256 : `5b83e51dd20c7e0498ce45c123261e4b1ab3738ec17bfae0bc7f907309e2b172`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 59 |
| `init_environement` | 118 |
| `wait_program_end` | 195 |
| `autoselect` | 322 |
| `Maj_Mouvements` | 391 |
| `Campagne_Lettrage` | 837 |
| `Identification_Factures` | 1125 |
| `Main` | 1311 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE_OPTIONS` | 138 |
| `fnd_concurrent_requests` | 214 |
| `fnd_concurrent_requests` | 232 |
| `fnd_concurrent_requests` | 234 |
| `Ap_Payment_Schedules_All` | 401 |
| `Ap_Invoices_All` | 404 |
| `OF` | 415 |
| `Ap_Invoices_All` | 434 |
| `Ap_Payment_Schedules_All` | 458 |
| `Dka_Ap_Lettrage_0_Tmp` | 460 |
| `Ap_Lookup_Codes` | 463 |
| `OF` | 467 |
| `Ap_Holds_ALL` | 479 |
| `Dka_Ap_Lettrage_0_Tmp` | 481 |
| `OF` | 483 |
| `AP_SUPPLIER_SITES_ALL` | 495 |
| `Dka_Ap_Lettrage_0_Tmp` | 497 |
| `OF` | 499 |
| `Ap_Payment_Schedules_All` | 530 |
| `Dka_Ap_Lettrage_0_Tmp` | 572 |
| `Dka_Ap_Lettrage_0_Tmp` | 603 |
| `Ap_Payment_Schedules_All` | 673 |
| `Ap_Lookup_Codes` | 676 |
| `Ap_Holds_all` | 723 |
| `Ap_Lookup_Codes` | 726 |
| `AP_SUPPLIER_SITES_ALL` | 772 |
| `dka_ap_lettrage_0_tmp` | 868 |
| `iby_pay_service_requests` | 878 |
| `ap_payment_templates` | 939 |
| `gl_period_statuses` | 960 |
| `Ap_Checks_All` | 1143 |
| `ap_inv_selection_criteria_all` | 1146 |
| `Po_Vendor_Sites_All` | 1160 |
| `Dka_Ap_Lettrage_0_Tmp` | 1162 |
| `OF` | 1165 |
| `Po_Vendor_Sites_All` | 1247 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 70 |
| `Fnd_File.put_line` | 91 |
| `Fnd_File.put_line` | 96 |
| `fnd_global.apps_initialize` | 166 |
| `Fnd_File.put_line` | 173 |
| `Fnd_Concurrent.wait_for_request` | 254 |
| `Fnd_File.put_line` | 257 |
| `Fnd_File.put_line` | 263 |
| `Fnd_File.put_line` | 264 |
| `Fnd_File.put_line` | 269 |
| `Fnd_File.put_line` | 285 |
| `Fnd_File.put_line` | 287 |
| `Fnd_File.put_line` | 290 |
| `Dka_Tools_Pkg.put_log_message` | 302 |
| `FND_REQUEST.SUBMIT_REQUEST` | 334 |
| `Fnd_File.put_line` | 351 |
| `Fnd_File.put_line` | 353 |
| `Fnd_File.put_line` | 359 |
| `Fnd_File.put_line` | 360 |
| `Ap_Invoices_Pkg.Get_Approval_Status` | 408 |
| `Ap_Invoices_Pkg.Get_Approval_Status` | 447 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 512 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 523 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 542 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 543 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 547 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 548 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 549 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 550 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 551 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 552 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 553 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 554 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 555 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 558 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 567 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 568 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 574 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 575 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 579 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 580 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 581 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 582 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 583 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 584 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 585 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 586 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 593 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 594 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 629 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 630 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 636 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 637 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 638 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 639 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 640 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 641 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 642 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 643 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 644 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 645 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 646 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 647 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 648 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 649 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 650 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 653 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 664 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 665 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 690 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 691 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 695 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 696 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 697 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 698 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 699 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 700 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 701 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 702 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 703 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 706 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 716 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 717 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 739 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 740 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 744 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 745 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 746 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 747 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 748 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 749 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 750 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 751 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 754 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 764 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 765 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 783 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 784 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 788 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 789 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 790 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 791 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 792 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 793 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 794 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 795 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 798 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 804 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 810 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 889 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 895 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 896 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 908 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 914 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 921 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 944 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 945 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 946 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 947 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 948 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 949 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 950 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 969 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 970 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 979 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 983 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 984 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 985 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 986 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 987 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 988 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 989 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 990 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 999 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1000 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1014 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1016 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1023 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1024 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1025 |
| `Fnd_File.put_line` | 1029 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1032 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1033 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1034 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1044 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1045 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1046 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1054 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1055 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1056 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1057 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1058 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1059 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1060 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1061 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1071 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1072 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1073 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1074 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1075 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1076 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1077 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1078 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1082 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1086 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1098 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1104 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1175 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1181 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1182 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1238 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1239 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1259 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1260 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1264 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1265 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1266 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1267 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1268 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1269 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1270 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1271 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1274 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1279 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1285 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1329 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1331 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1345 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1346 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1347 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1348 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1355 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1389 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1390 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1391 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1392 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1404 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1405 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1406 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1407 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1421 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1422 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1423 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1424 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1446 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1447 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1448 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1449 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1453 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1458 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1462 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1466 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1470 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1476 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1477 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1480 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1481 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1482 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1483 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1485 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1486 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1489 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1490 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1491 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1492 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1495 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1496 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `APXPBASL` | 334 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 358, 1433 |
| rollback | 1474, 1479, 1488 |
| when_others | 97, 174, 299, 546, 578, 635, 694, 743, 787, 807, 1070, 1101, 1263, 1282, 1487 |
| suppression | 572 |
| soumission | 334 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPLETMVTZERO / DKA | `DKA_SAPLETMVTZERO_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SAPLETMVTZERO.prt:403 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
