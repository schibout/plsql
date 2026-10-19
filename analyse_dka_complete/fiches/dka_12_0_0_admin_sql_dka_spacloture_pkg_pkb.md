# DKA_SPACLOTURE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPACLOTURE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPACLOTURE_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1804 ; encodage : cp1252 (repli). SHA-256 : `d2312a253ec082e14a223c76df2fc88729085748ba93e2b52940458ccefc3884`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `cherche_period` | 63 |
| `cherche_next_period` | 152 |
| `pa_check_transfer_to_ap` | 207 |
| `pa_check_cost_transfer_to_ap` | 501 |
| `pa_check_cross_charge` | 719 |
| `pa_check_draft_revenue` | 892 |
| `pa_check_cst_pm` | 1177 |
| `pa_check_trans_uncosted` | 1286 |
| `main` | 1384 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `PA_PERIODS_ALL` | 104 |
| `PA_PERIODS_ALL` | 107 |
| `PA_PERIODS_ALL` | 175 |
| `PA_PERIODS_ALL` | 177 |
| `AP_INVOICE_DISTRIBUTIONS_ALL` | 279 |
| `po_distributions` | 314 |
| `po_distributions_all` | 331 |
| `po_line_locations_all` | 339 |
| `ap_invoice_distributions_all` | 344 |
| `po_line_locations_all` | 353 |
| `AP_SELF_ASSESSED_TAX_DIST_ALL` | 365 |
| `po_distributions` | 391 |
| `po_distributions_all` | 408 |
| `po_line_locations_all` | 416 |
| `AP_SELF_ASSESSED_TAX_DIST_ALL` | 421 |
| `po_line_locations_all` | 430 |
| `pa_cost_exceptions_sum_v` | 635 |
| `pa_cc_exceptions_sum_v` | 806 |
| `pa_cc_dist_lines_all` | 817 |
| `pa_draft_invoice_Details_all` | 823 |
| `PA_DRAFT_REVENUES_ALL` | 1086 |
| `cst_pm_pending_txn_v` | 1198 |
| `gms_implementations_all` | 1212 |
| `pa_transaction_interface` | 1220 |
| `pa_expenditure_items_all` | 1310 |
| `PER_SECURITY_PROFILES_V` | 1413 |
| `PA_PERIODS_ALL` | 1420 |
| `dka_spacloture` | 1517 |
| `dka_spacloture` | 1526 |
| `dka_spacloture` | 1542 |
| `dka_spacloture` | 1551 |
| `dka_spacloture` | 1567 |
| `dka_spacloture` | 1576 |
| `dka_spacloture` | 1592 |
| `dka_spacloture` | 1601 |
| `dka_spacloture` | 1617 |
| `dka_spacloture` | 1626 |
| `dka_spacloture` | 1642 |
| `dka_spacloture` | 1651 |
| `dka_spacloture` | 1662 |
| `pa_periods_all` | 1671 |
| `pa_periods_all` | 1680 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.VALUE` | 120 |
| `dka_tools_pkg.get_message` | 453 |
| `dka_tools_pkg.put_outdebug_message` | 454 |
| `dka_tools_pkg.put_outdebug_message` | 455 |
| `dka_tools_pkg.put_outdebug_message` | 456 |
| `dka_tools_pkg.put_outdebug_message` | 457 |
| `dka_tools_pkg.put_outdebug_message` | 458 |
| `dka_tools_pkg.put_outdebug_message` | 459 |
| `dka_tools_pkg.put_outdebug_message` | 460 |
| `dka_tools_pkg.put_outdebug_message` | 470 |
| `dka_tools_pkg.put_outdebug_message` | 471 |
| `dka_tools_pkg.put_outdebug_message` | 472 |
| `dka_tools_pkg.put_outdebug_message` | 473 |
| `dka_tools_pkg.put_outdebug_message` | 474 |
| `dka_tools_pkg.put_outdebug_message` | 475 |
| `dka_tools_pkg.get_message` | 660 |
| `dka_tools_pkg.get_message` | 662 |
| `dka_tools_pkg.put_outdebug_message` | 664 |
| `dka_tools_pkg.put_outdebug_message` | 665 |
| `dka_tools_pkg.put_outdebug_message` | 666 |
| `dka_tools_pkg.put_outdebug_message` | 667 |
| `dka_tools_pkg.put_outdebug_message` | 668 |
| `dka_tools_pkg.put_outdebug_message` | 669 |
| `dka_tools_pkg.put_outdebug_message` | 670 |
| `dka_tools_pkg.put_outdebug_message` | 671 |
| `dka_tools_pkg.put_outdebug_message` | 687 |
| `dka_tools_pkg.put_outdebug_message` | 688 |
| `dka_tools_pkg.put_outdebug_message` | 689 |
| `dka_tools_pkg.put_outdebug_message` | 690 |
| `dka_tools_pkg.put_outdebug_message` | 691 |
| `dka_tools_pkg.put_outdebug_message` | 692 |
| `dka_tools_pkg.put_outdebug_message` | 693 |
| `dka_tools_pkg.get_message` | 844 |
| `dka_tools_pkg.put_outdebug_message` | 845 |
| `dka_tools_pkg.put_outdebug_message` | 846 |
| `dka_tools_pkg.put_outdebug_message` | 847 |
| `dka_tools_pkg.put_outdebug_message` | 848 |
| `dka_tools_pkg.put_outdebug_message` | 849 |
| `dka_tools_pkg.put_outdebug_message` | 850 |
| `dka_tools_pkg.put_outdebug_message` | 851 |
| `dka_tools_pkg.put_outdebug_message` | 861 |
| `dka_tools_pkg.put_outdebug_message` | 862 |
| `dka_tools_pkg.put_outdebug_message` | 863 |
| `dka_tools_pkg.put_outdebug_message` | 864 |
| `dka_tools_pkg.put_outdebug_message` | 865 |
| `dka_tools_pkg.put_outdebug_message` | 866 |
| `dka_tools_pkg.get_message` | 1122 |
| `dka_tools_pkg.get_message` | 1124 |
| `dka_tools_pkg.put_outdebug_message` | 1126 |
| `dka_tools_pkg.put_outdebug_message` | 1127 |
| `dka_tools_pkg.put_outdebug_message` | 1128 |
| `dka_tools_pkg.put_outdebug_message` | 1129 |
| `dka_tools_pkg.put_outdebug_message` | 1130 |
| `dka_tools_pkg.put_outdebug_message` | 1131 |
| `dka_tools_pkg.put_outdebug_message` | 1132 |
| `dka_tools_pkg.put_outdebug_message` | 1147 |
| `dka_tools_pkg.put_outdebug_message` | 1148 |
| `dka_tools_pkg.put_outdebug_message` | 1149 |
| `dka_tools_pkg.put_outdebug_message` | 1150 |
| `dka_tools_pkg.put_outdebug_message` | 1151 |
| `dka_tools_pkg.put_outdebug_message` | 1152 |
| `pa_exception_reasons_pub.get_exception_text` | 1219 |
| `dka_tools_pkg.get_message` | 1242 |
| `dka_tools_pkg.put_outdebug_message` | 1243 |
| `dka_tools_pkg.put_outdebug_message` | 1244 |
| `dka_tools_pkg.put_outdebug_message` | 1245 |
| `dka_tools_pkg.put_outdebug_message` | 1246 |
| `dka_tools_pkg.put_outdebug_message` | 1247 |
| `dka_tools_pkg.put_outdebug_message` | 1248 |
| `dka_tools_pkg.put_outdebug_message` | 1257 |
| `dka_tools_pkg.put_outdebug_message` | 1258 |
| `dka_tools_pkg.put_outdebug_message` | 1259 |
| `dka_tools_pkg.put_outdebug_message` | 1260 |
| `dka_tools_pkg.put_outdebug_message` | 1261 |
| `dka_tools_pkg.get_message` | 1336 |
| `dka_tools_pkg.put_outdebug_message` | 1337 |
| `dka_tools_pkg.put_outdebug_message` | 1338 |
| `dka_tools_pkg.put_outdebug_message` | 1339 |
| `dka_tools_pkg.put_outdebug_message` | 1340 |
| `dka_tools_pkg.put_outdebug_message` | 1341 |
| `dka_tools_pkg.put_outdebug_message` | 1342 |
| `dka_tools_pkg.put_outdebug_message` | 1343 |
| `dka_tools_pkg.put_outdebug_message` | 1344 |
| `dka_tools_pkg.put_outdebug_message` | 1355 |
| `dka_tools_pkg.put_outdebug_message` | 1356 |
| `dka_tools_pkg.put_outdebug_message` | 1357 |
| `dka_tools_pkg.put_outdebug_message` | 1358 |
| `dka_tools_pkg.put_outdebug_message` | 1359 |
| `dka_tools_pkg.put_outdebug_message` | 1360 |
| `dka_tools_pkg.put_outdebug_message` | 1361 |
| `FND_PROFILE.VALUE` | 1417 |
| `dka_tools_pkg.put_debug_message` | 1436 |
| `dka_tools_pkg.put_outdebug_message` | 1445 |
| `dka_tools_pkg.put_outdebug_message` | 1447 |
| `dka_tools_pkg.put_outdebug_message` | 1448 |
| `dka_tools_pkg.put_outdebug_message` | 1449 |
| `dka_tools_pkg.put_outdebug_message` | 1451 |
| `dka_tools_pkg.put_outdebug_message` | 1452 |
| `dka_tools_pkg.put_outdebug_message` | 1453 |
| `dka_tools_pkg.put_outdebug_message` | 1454 |
| `dka_tools_pkg.put_debug_message` | 1456 |
| `dka_tools_pkg.put_debug_message` | 1457 |
| `dka_tools_pkg.put_debug_message` | 1458 |
| `dka_spacloture_pkg.cherche_period` | 1471 |
| `dka_tools_pkg.put_outdebug_message` | 1472 |
| `dka_tools_pkg.put_outdebug_message` | 1474 |
| `dka_spacloture_pkg.cherche_next_period` | 1476 |
| `dka_tools_pkg.put_outdebug_message` | 1477 |
| `dka_tools_pkg.put_outdebug_message` | 1478 |
| `dka_tools_pkg.put_outdebug_message` | 1494 |
| `dka_tools_pkg.put_outdebug_message` | 1495 |
| `dka_tools_pkg.put_outdebug_message` | 1496 |
| `dka_tools_pkg.put_outdebug_message` | 1502 |
| `dka_tools_pkg.put_outdebug_message` | 1503 |
| `dka_tools_pkg.put_outdebug_message` | 1504 |
| `dka_spacloture_pkg.pa_check_transfer_to_ap` | 1510 |
| `dka_tools_pkg.put_outdebug_message` | 1515 |
| `dka_tools_pkg.put_outdebug_message` | 1524 |
| `dka_spacloture_pkg.pa_check_cross_charge` | 1536 |
| `dka_tools_pkg.put_outdebug_message` | 1540 |
| `dka_tools_pkg.put_outdebug_message` | 1549 |
| `dka_spacloture_pkg.pa_check_cost_transfer_to_ap` | 1561 |
| `dka_tools_pkg.put_outdebug_message` | 1565 |
| `dka_tools_pkg.put_outdebug_message` | 1574 |
| `dka_spacloture_pkg.pa_check_draft_revenue` | 1586 |
| `dka_tools_pkg.put_outdebug_message` | 1590 |
| `dka_tools_pkg.put_outdebug_message` | 1599 |
| `dka_spacloture_pkg.pa_check_cst_pm` | 1611 |
| `dka_tools_pkg.put_outdebug_message` | 1615 |
| `dka_tools_pkg.put_outdebug_message` | 1624 |
| `dka_spacloture_pkg.pa_check_trans_uncosted` | 1636 |
| `dka_tools_pkg.put_outdebug_message` | 1640 |
| `dka_tools_pkg.put_outdebug_message` | 1649 |
| `dka_tools_pkg.put_outdebug_message` | 1668 |
| `dka_tools_pkg.put_outdebug_message` | 1692 |
| `dka_tools_pkg.put_outdebug_message` | 1693 |
| `dka_tools_pkg.put_outdebug_message` | 1694 |
| `dka_tools_pkg.put_outdebug_message` | 1698 |
| `dka_tools_pkg.put_outdebug_message` | 1773 |
| `dka_tools_pkg.put_outdebug_message` | 1774 |
| `dka_tools_pkg.put_outdebug_message` | 1775 |
| `dka_tools_pkg.put_outdebug_message` | 1776 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1442, 1690 |
| when_others | 131, 186, 1794 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPACLOTURE / DKA | `dka_spacloture_pkg.main` | dka/12.0.0/admin/import/DKA_SPACLOTURE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
