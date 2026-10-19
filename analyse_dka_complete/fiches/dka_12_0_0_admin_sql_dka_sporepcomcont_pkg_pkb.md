# DKA_SPOREPCOMCONT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOREPCOMCONT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOREPCOMCONT_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1474 ; encodage : cp1252 (repli). SHA-256 : `7014231985701d1d27186ae0318aad51102ed5375c4b9964c6d25426dbf5df14`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `insert_rcv_headers` | 69 |
| `insert_rcv_transactions` | 133 |
| `reception_commandes` | 234 |
| `Main` | 448 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `rcv_headers_interface` | 79 |
| `rcv_transactions_interface` | 151 |
| `dka_po_com_cont_tmp` | 265 |
| `rcv_shipment_lines` | 276 |
| `po_interface_errors` | 285 |
| `po_interface_errors` | 396 |
| `DKA_PO_COM_CONT_TMP` | 495 |
| `DKA_PO_COM_CONT_TMP` | 518 |
| `dka_po_com_cont_qty_billed_tmp` | 534 |
| `FND_USER` | 543 |
| `dka_po_com_cont_tmp` | 558 |
| `dka_po_com_cont_tmp` | 562 |
| `DKA_PO_COM_CONT_TMP` | 620 |
| `PO_HEADERS_ALL` | 640 |
| `PO_HEADERS_ALL` | 673 |
| `dual` | 690 |
| `pa_projects_all` | 757 |
| `pa_tasks` | 779 |
| `pa_expenditure_types` | 797 |
| `per_people_f` | 844 |
| `hr_locations` | 867 |
| `dka_contrat_sstr_imputation` | 889 |
| `dka_contrat_sstr_imputation` | 891 |
| `dual` | 921 |
| `dual` | 925 |
| `DKA_PO_COM_CONT_TMP` | 951 |
| `DKA_PO_COM_CONT_TMP` | 959 |
| `po_headers_interface` | 976 |
| `po_lines_interface` | 1030 |
| `PO_DISTRIBUTIONS_INTERFACE` | 1078 |
| `dka_po_com_cont_qty_billed_tmp` | 1134 |
| `DKA_PO_COM_CONT_TMP` | 1152 |
| `DKA_PO_COM_CONT_TMP` | 1174 |
| `DKA_PO_COM_CONT_TMP` | 1182 |
| `DKA_PO_COM_CONT_TMP` | 1197 |
| `DKA_PO_COM_CONT_TMP` | 1198 |
| `DKA_PO_COM_CONT_TMP` | 1199 |
| `DKA_PO_COM_CONT_TMP` | 1200 |
| `DKA_PO_COM_CONT_TMP` | 1201 |
| `DUAL` | 1207 |
| `DKA_PO_COM_CONT_TMP` | 1215 |
| `dka_po_com_cont_qty_billed_tmp` | 1333 |
| `po_distributions_all` | 1367 |
| `po_line_locations_all` | 1372 |
| `dka_contrat_sstr` | 1380 |
| `po_headers_all` | 1382 |
| `po_headers_all` | 1388 |
| `dka_po_com_cont_tmp` | 1394 |
| `dka_contrat_sstr_archi` | 1398 |
| `po_headers_all` | 1400 |
| `po_headers_all` | 1407 |
| `dka_po_com_cont_tmp` | 1414 |
| `po_headers_interface` | 1421 |
| `po_headers_interface` | 1427 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_outdebug_message` | 112 |
| `Dka_Tools_Pkg.put_outdebug_message` | 214 |
| `Dka_Tools_Pkg.put_debug_message` | 298 |
| `dka_tools_pkg.put_debug_message` | 348 |
| `Fnd_Request.Submit_Request` | 349 |
| `dka_tools_pkg.put_outdebug_message` | 367 |
| `dka_tools_pkg.put_outdebug_message` | 368 |
| `fnd_concurrent.wait_for_request` | 374 |
| `Dka_Tools_Pkg.put_outdebug_message` | 403 |
| `Dka_Tools_Pkg.put_outdebug_message` | 404 |
| `Dka_Tools_Pkg.put_outdebug_message` | 405 |
| `Dka_Tools_Pkg.put_outdebug_message` | 406 |
| `Dka_Tools_Pkg.put_outdebug_message` | 407 |
| `Dka_Tools_Pkg.put_outdebug_message` | 415 |
| `Dka_Tools_Pkg.put_debug_message` | 420 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 526 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 536 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 537 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 538 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 539 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 546 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 554 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 555 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 556 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 568 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 571 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 575 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 576 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 624 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 629 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 632 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 650 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 655 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 658 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 661 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 680 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 716 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 734 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 735 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 737 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 749 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 763 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 769 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 772 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 787 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 790 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 809 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 812 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 857 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 860 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 875 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 878 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 905 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 908 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 955 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 973 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 974 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1023 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1074 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1150 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1166 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1167 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1170 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1171 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1178 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1179 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1230 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1231 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1232 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1233 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1234 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1235 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1238 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1240 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1241 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1242 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1243 |
| `fnd_request.submit_request` | 1250 |
| `dka_tools_pkg.put_debug_message` | 1283 |
| `Dka_tools_pkg.put_debug_message` | 1288 |
| `fnd_concurrent.wait_for_request` | 1290 |
| `fnd_concurrent.get_request_status` | 1299 |
| `Dka_tools_pkg.put_debug_message` | 1310 |
| `Dka_tools_pkg.put_debug_message` | 1317 |
| `Dka_tools_pkg.put_debug_message` | 1320 |
| `Dka_tools_pkg.put_debug_message` | 1431 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1433 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1434 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1435 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1452 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1453 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1454 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1457 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1461 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1462 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1463 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1464 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1467 |
| `Dka_Tools_Pkg.Put_Debug_Message` | 1468 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `RVCTP` | 349 |
| `POXPOPDOI` | 1250 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 344, 362, 570, 1191, 1279 |
| rollback | 1173, 1181 |
| when_others | 111, 213, 424, 660, 770, 788, 810, 858, 876, 906, 1177, 1460 |
| suppression | 534 |
| soumission | 349, 1250 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOREPCOMCONT_PKG / DKA | `DKA_SPOREPCOMCONT_PKG.main` | dka/12.0.0/admin/import/DKA_SPOREPCOMCONT_PKG.prt:405 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
