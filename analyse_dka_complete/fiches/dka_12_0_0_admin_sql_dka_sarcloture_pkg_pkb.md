# DKA_SARCLOTURE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARCLOTURE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARCLOTURE_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1526 ; encodage : cp1252 (repli). SHA-256 : `943ef3b3a4b997cd1be7603e72b92c4372b33fc438f28bae7dd266489dda5d5a`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `cherche_period` | 58 |
| `cherche_next_period` | 142 |
| `ar_check_unposted_items_gl` | 215 |
| `ar_check_unposted_adjustments` | 321 |
| `ar_check_unposted_distribution` | 425 |
| `ar_check_unposted_gl_dist` | 519 |
| `ar_check_unposted_receivable` | 631 |
| `ar_check_unposted_receipt_hist` | 737 |
| `ar_check_cash_receipts` | 841 |
| `ar_check_unposted_transaction` | 936 |
| `ar_check_gl_transfer` | 1027 |
| `main` | 1083 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_period_statuses` | 92 |
| `gl_period_statuses` | 101 |
| `gl_period_statuses` | 175 |
| `gl_period_statuses` | 177 |
| `ra_cust_trx_line_gl_dist_all` | 233 |
| `ar_system_parameters_All` | 245 |
| `ar_system_parameters_All` | 251 |
| `ar_adjustments_all` | 340 |
| `ar_system_parameters_All` | 352 |
| `ar_misc_cash_distributions_all` | 442 |
| `ar_system_parameters_All` | 450 |
| `ra_customer_trx_all` | 538 |
| `ar_system_parameters_All` | 551 |
| `ar_system_parameters_All` | 557 |
| `ar_receivable_applications_all` | 650 |
| `ar_system_parameters_All` | 663 |
| `ar_system_parameters_All` | 669 |
| `ar_cash_receipt_history_all` | 757 |
| `ar_system_parameters_All` | 768 |
| `ar_interim_cash_receipts_all` | 859 |
| `ar_system_parameters_All` | 864 |
| `ar_transaction_history_all` | 952 |
| `ar_system_parameters_All` | 961 |
| `GL_ACCESS_SET_LEDGERS` | 1121 |
| `fnd_responsibility` | 1157 |
| `dka_sarcloture` | 1246 |
| `dka_sarcloture` | 1252 |
| `dka_sarcloture` | 1264 |
| `dka_sarcloture` | 1269 |
| `dka_sarcloture` | 1280 |
| `dka_sarcloture` | 1285 |
| `dka_sarcloture` | 1297 |
| `dka_sarcloture` | 1304 |
| `dka_sarcloture` | 1315 |
| `dka_sarcloture` | 1320 |
| `dka_sarcloture` | 1331 |
| `dka_sarcloture` | 1336 |
| `dka_sarcloture` | 1347 |
| `dka_sarcloture` | 1352 |
| `dka_sarcloture` | 1363 |
| `dka_sarcloture` | 1368 |
| `dka_sarcloture` | 1378 |
| `dka_sarcloture` | 1383 |
| `dka_sarcloture` | 1392 |
| `gl_period_statuses` | 1402 |
| `gl_period_statuses` | 1417 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_outdebug_message` | 270 |
| `dka_tools_pkg.get_message` | 271 |
| `dka_tools_pkg.put_outdebug_message` | 272 |
| `dka_tools_pkg.put_outdebug_message` | 273 |
| `dka_tools_pkg.put_outdebug_message` | 274 |
| `dka_tools_pkg.put_outdebug_message` | 275 |
| `dka_tools_pkg.get_message` | 286 |
| `dka_tools_pkg.put_outdebug_message` | 287 |
| `dka_tools_pkg.put_outdebug_message` | 288 |
| `dka_tools_pkg.put_outdebug_message` | 289 |
| `dka_tools_pkg.put_outdebug_message` | 290 |
| `dka_tools_pkg.put_outdebug_message` | 371 |
| `dka_tools_pkg.get_message` | 372 |
| `dka_tools_pkg.put_outdebug_message` | 373 |
| `dka_tools_pkg.put_outdebug_message` | 374 |
| `dka_tools_pkg.put_outdebug_message` | 375 |
| `dka_tools_pkg.put_outdebug_message` | 376 |
| `dka_tools_pkg.put_outdebug_message` | 377 |
| `dka_tools_pkg.get_message` | 389 |
| `dka_tools_pkg.put_outdebug_message` | 390 |
| `dka_tools_pkg.put_outdebug_message` | 391 |
| `dka_tools_pkg.put_outdebug_message` | 392 |
| `dka_tools_pkg.put_outdebug_message` | 393 |
| `dka_tools_pkg.put_outdebug_message` | 394 |
| `dka_tools_pkg.get_message` | 467 |
| `dka_tools_pkg.put_outdebug_message` | 468 |
| `dka_tools_pkg.put_outdebug_message` | 469 |
| `dka_tools_pkg.put_outdebug_message` | 470 |
| `dka_tools_pkg.put_outdebug_message` | 471 |
| `dka_tools_pkg.put_outdebug_message` | 472 |
| `dka_tools_pkg.get_message` | 483 |
| `dka_tools_pkg.put_outdebug_message` | 484 |
| `dka_tools_pkg.put_outdebug_message` | 485 |
| `dka_tools_pkg.put_outdebug_message` | 486 |
| `dka_tools_pkg.put_outdebug_message` | 487 |
| `dka_tools_pkg.get_message` | 579 |
| `dka_tools_pkg.put_outdebug_message` | 580 |
| `dka_tools_pkg.put_outdebug_message` | 581 |
| `dka_tools_pkg.put_outdebug_message` | 582 |
| `dka_tools_pkg.put_outdebug_message` | 583 |
| `dka_tools_pkg.put_outdebug_message` | 584 |
| `dka_tools_pkg.put_outdebug_message` | 585 |
| `dka_tools_pkg.get_message` | 596 |
| `dka_tools_pkg.put_outdebug_message` | 597 |
| `dka_tools_pkg.put_outdebug_message` | 598 |
| `dka_tools_pkg.put_outdebug_message` | 599 |
| `dka_tools_pkg.put_outdebug_message` | 600 |
| `dka_tools_pkg.put_outdebug_message` | 601 |
| `dka_tools_pkg.get_message` | 689 |
| `dka_tools_pkg.put_outdebug_message` | 690 |
| `dka_tools_pkg.put_outdebug_message` | 691 |
| `dka_tools_pkg.put_outdebug_message` | 692 |
| `dka_tools_pkg.put_outdebug_message` | 693 |
| `dka_tools_pkg.get_message` | 703 |
| `dka_tools_pkg.put_outdebug_message` | 704 |
| `dka_tools_pkg.put_outdebug_message` | 705 |
| `dka_tools_pkg.put_outdebug_message` | 706 |
| `dka_tools_pkg.get_message` | 788 |
| `dka_tools_pkg.put_outdebug_message` | 789 |
| `dka_tools_pkg.put_outdebug_message` | 790 |
| `dka_tools_pkg.put_outdebug_message` | 791 |
| `dka_tools_pkg.put_outdebug_message` | 792 |
| `dka_tools_pkg.put_outdebug_message` | 793 |
| `dka_tools_pkg.put_outdebug_message` | 794 |
| `dka_tools_pkg.get_message` | 805 |
| `dka_tools_pkg.put_outdebug_message` | 806 |
| `dka_tools_pkg.put_outdebug_message` | 807 |
| `dka_tools_pkg.put_outdebug_message` | 808 |
| `dka_tools_pkg.put_outdebug_message` | 809 |
| `dka_tools_pkg.put_outdebug_message` | 810 |
| `dka_tools_pkg.get_message` | 886 |
| `dka_tools_pkg.put_outdebug_message` | 887 |
| `dka_tools_pkg.put_outdebug_message` | 888 |
| `dka_tools_pkg.put_outdebug_message` | 889 |
| `dka_tools_pkg.put_outdebug_message` | 890 |
| `dka_tools_pkg.put_outdebug_message` | 891 |
| `dka_tools_pkg.get_message` | 900 |
| `dka_tools_pkg.put_outdebug_message` | 901 |
| `dka_tools_pkg.put_outdebug_message` | 902 |
| `dka_tools_pkg.put_outdebug_message` | 903 |
| `dka_tools_pkg.put_outdebug_message` | 904 |
| `dka_tools_pkg.get_message` | 978 |
| `dka_tools_pkg.put_outdebug_message` | 979 |
| `dka_tools_pkg.put_outdebug_message` | 980 |
| `dka_tools_pkg.put_outdebug_message` | 981 |
| `dka_tools_pkg.put_outdebug_message` | 982 |
| `dka_tools_pkg.get_message` | 991 |
| `dka_tools_pkg.put_outdebug_message` | 992 |
| `dka_tools_pkg.put_outdebug_message` | 993 |
| `dka_tools_pkg.put_outdebug_message` | 994 |
| `dka_tools_pkg.get_message` | 1059 |
| `dka_tools_pkg.put_outdebug_message` | 1060 |
| `dka_tools_pkg.put_debug_message` | 1136 |
| `Fnd_File.put_line` | 1141 |
| `Fnd_File.put_line` | 1142 |
| `Fnd_File.put_line` | 1143 |
| `Fnd_File.put_line` | 1144 |
| `Fnd_File.put_line` | 1146 |
| `Fnd_File.put_line` | 1147 |
| `Fnd_File.put_line` | 1148 |
| `Fnd_File.put_line` | 1149 |
| `fnd_global.apps_initialize` | 1160 |
| `dka_tools_pkg.put_debug_message` | 1164 |
| `dka_tools_pkg.put_debug_message` | 1165 |
| `dka_tools_pkg.put_debug_message` | 1166 |
| `fnd_profile.VALUE` | 1171 |
| `Fnd_File.put_line` | 1172 |
| `dka_sarcloture_pkg.cherche_period` | 1175 |
| `Fnd_File.put_line` | 1180 |
| `Fnd_File.put_line` | 1181 |
| `Fnd_File.put_line` | 1186 |
| `Fnd_File.put_line` | 1188 |
| `Fnd_File.put_line` | 1189 |
| `dka_sarcloture_pkg.cherche_next_period` | 1191 |
| `Fnd_File.put_line` | 1193 |
| `Fnd_File.put_line` | 1195 |
| `Fnd_File.put_line` | 1196 |
| `Fnd_File.put_line` | 1197 |
| `dka_tools_pkg.put_outdebug_message` | 1218 |
| `dka_tools_pkg.put_outdebug_message` | 1219 |
| `dka_tools_pkg.put_outdebug_message` | 1220 |
| `dka_tools_pkg.put_outdebug_message` | 1237 |
| `DKA_SARCLOTURE_PKG.ar_check_unposted_items_gl` | 1239 |
| `dka_tools_pkg.put_outdebug_message` | 1244 |
| `dka_tools_pkg.put_outdebug_message` | 1250 |
| `DKA_SARCLOTURE_PKG.ar_check_unposted_adjustments` | 1260 |
| `dka_tools_pkg.put_outdebug_message` | 1263 |
| `dka_tools_pkg.put_outdebug_message` | 1268 |
| `DKA_SARCLOTURE_PKG.ar_check_unposted_distribution` | 1276 |
| `dka_tools_pkg.put_outdebug_message` | 1279 |
| `dka_tools_pkg.put_outdebug_message` | 1284 |
| `DKA_SARCLOTURE_PKG.ar_check_unposted_gl_dist` | 1292 |
| `dka_tools_pkg.put_outdebug_message` | 1295 |
| `dka_tools_pkg.put_outdebug_message` | 1302 |
| `DKA_SARCLOTURE_PKG.ar_check_unposted_receivable` | 1311 |
| `dka_tools_pkg.put_outdebug_message` | 1314 |
| `dka_tools_pkg.put_outdebug_message` | 1319 |
| `DKA_SARCLOTURE_PKG.ar_check_unposted_receipt_hist` | 1327 |
| `dka_tools_pkg.put_outdebug_message` | 1330 |
| `dka_tools_pkg.put_outdebug_message` | 1335 |
| `DKA_SARCLOTURE_PKG.ar_check_cash_receipts` | 1343 |
| `dka_tools_pkg.put_outdebug_message` | 1346 |
| `dka_tools_pkg.put_outdebug_message` | 1351 |
| `DKA_SARCLOTURE_PKG.ar_check_unposted_transaction` | 1359 |
| `dka_tools_pkg.put_outdebug_message` | 1362 |
| `dka_tools_pkg.put_outdebug_message` | 1367 |
| `DKA_SARCLOTURE_PKG.ar_check_gl_transfer` | 1374 |
| `dka_tools_pkg.put_outdebug_message` | 1377 |
| `dka_tools_pkg.put_outdebug_message` | 1382 |
| `dka_tools_pkg.put_outdebug_message` | 1398 |
| `Fnd_File.put_line` | 1399 |
| `Fnd_File.put_line` | 1400 |
| `Fnd_File.put_line` | 1414 |
| `Fnd_File.put_line` | 1415 |
| `Fnd_File.put_line` | 1416 |
| `Fnd_File.put_line` | 1484 |
| `Fnd_File.put_line` | 1498 |
| `Fnd_File.put_line` | 1499 |
| `Fnd_File.put_line` | 1500 |
| `Fnd_File.put_line` | 1501 |
| `Fnd_File.put_line` | 1502 |
| `Fnd_File.put_line` | 1503 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1426, 1487 |
| when_others | 120, 195, 1513 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARCLOTURE / DKA | `dka_sarcloture_pkg.main` | dka/12.0.0/admin/import/DKA_SARCLOTURE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
