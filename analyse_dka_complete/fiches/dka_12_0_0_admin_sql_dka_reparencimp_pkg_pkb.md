# DKA_REPARENCIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPARENCIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPARENCIMP_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1525 ; encodage : cp1252 (repli). SHA-256 : `5755ccdddccbcc68439bb6229e922c751e973991c8c7deef900f3a9c89757fd2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 99 |
| `output_header` | 191 |
| `Request_parameters` | 241 |
| `output_end` | 339 |
| `print_errors` | 367 |
| `Launch_Loader` | 434 |
| `validate_data` | 577 |
| `create_data` | 809 |
| `Report_Bilan` | 1201 |
| `set_recovery_mode` | 1274 |
| `purge_data` | 1307 |
| `main` | 1344 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DUAL` | 144 |
| `fnd_concurrent_requests` | 154 |
| `fnd_concurrent_programs` | 203 |
| `fnd_concurrent_requests` | 245 |
| `fnd_concurrent_requests` | 276 |
| `fnd_concurrent_requests` | 298 |
| `DKA_PROGRAM_MESSAGES` | 371 |
| `DKA_PROGRAM_MESSAGES` | 377 |
| `DKA_AR_RECEIPTS_TMP` | 510 |
| `DKA_AR_RECEIPTS_TMP` | 516 |
| `DKA_AR_RECEIPTS_TMP` | 581 |
| `OF` | 588 |
| `hr_operating_units` | 616 |
| `ar_receipt_method_accounts_all` | 653 |
| `AR_CUSTOMERS` | 698 |
| `DKA_AR_RECEIPTS_TMP` | 760 |
| `DKA_AR_RECEIPTS_TMP` | 773 |
| `DKA_AR_RECEIPTS_TMP` | 814 |
| `dka_ar_receipts_tmp` | 830 |
| `OF` | 838 |
| `ar_receipt_methods` | 911 |
| `DKA_AR_RECEIPTS_TMP` | 1144 |
| `DKA_AR_RECEIPTS_TMP` | 1149 |
| `DKA_AR_RECEIPTS_TMP` | 1280 |
| `DKA_AR_RECEIPTS_TMP` | 1312 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 109 |
| `fnd_profile.value` | 127 |
| `fnd_date.canonical_to_date` | 139 |
| `Fnd_File.put_line` | 147 |
| `Fnd_File.put_line` | 158 |
| `fnd_file.put_line` | 168 |
| `Fnd_File.put_line` | 215 |
| `Fnd_File.put_line` | 216 |
| `Fnd_File.put_line` | 218 |
| `Fnd_File.put_line` | 220 |
| `Fnd_File.put_line` | 223 |
| `Fnd_File.put_line` | 261 |
| `Fnd_File.put_line` | 262 |
| `Fnd_File.put_line` | 263 |
| `Fnd_File.put_line` | 264 |
| `Fnd_File.put_line` | 282 |
| `Fnd_File.put_line` | 285 |
| `Fnd_File.put_line` | 304 |
| `Fnd_File.put_line` | 307 |
| `Fnd_File.put_line` | 312 |
| `Fnd_File.put_line` | 315 |
| `Fnd_File.put_line` | 316 |
| `Fnd_File.put_line` | 345 |
| `Fnd_File.put_line` | 346 |
| `Fnd_File.put_line` | 349 |
| `fnd_file.put_line` | 383 |
| `fnd_file.put_line` | 384 |
| `fnd_file.put_line` | 386 |
| `fnd_file.put_line` | 388 |
| `fnd_file.put_line` | 389 |
| `Fnd_File.put_line` | 393 |
| `fnd_file.put_line` | 399 |
| `fnd_file.put_line` | 400 |
| `fnd_file.put_line` | 401 |
| `fnd_file.put_line` | 402 |
| `fnd_file.put_line` | 403 |
| `Fnd_File.put_line` | 407 |
| `Fnd_File.put_line` | 443 |
| `Fnd_File.put_line` | 446 |
| `fnd_file.put_line` | 450 |
| `fnd_file.put_line` | 451 |
| `fnd_file.put_line` | 452 |
| `fnd_request.set_print_options` | 457 |
| `Fnd_Request.submit_request` | 460 |
| `fnd_file.put_line` | 473 |
| `Fnd_File.put_line` | 477 |
| `Fnd_File.put_line` | 481 |
| `Fnd_File.put_line` | 483 |
| `Fnd_Concurrent.wait_for_request` | 488 |
| `Fnd_file.put_line` | 497 |
| `Fnd_File.put_line` | 503 |
| `Fnd_File.put_line` | 506 |
| `Fnd_File.put_line` | 518 |
| `Fnd_File.put_line` | 524 |
| `fnd_file.put_line` | 534 |
| `Fnd_File.put_line` | 540 |
| `Fnd_File.put_line` | 547 |
| `Fnd_File.put_line` | 555 |
| `Fnd_File.put_line` | 556 |
| `dka_rep_transco_pkg.get_transco` | 607 |
| `dka_tools_pkg.ins_prog_message` | 627 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 646 |
| `dka_tools_pkg.ins_prog_message` | 662 |
| `dka_tools_pkg.ins_prog_message` | 708 |
| `dka_tools_pkg.ins_prog_message` | 738 |
| `Fnd_File.put_line` | 787 |
| `Fnd_File.put_line` | 788 |
| `FND_PROFILE.VALUE` | 861 |
| `FND_PROFILE.VALUE` | 874 |
| `FND_PROFILE.VALUE` | 875 |
| `FND_PROFILE.VALUE` | 876 |
| `Fnd_File.put_line` | 881 |
| `Fnd_File.put_line` | 889 |
| `Fnd_File.put_line` | 891 |
| `Fnd_File.put_line` | 893 |
| `Fnd_File.put_line` | 914 |
| `Fnd_File.put_line` | 924 |
| `dka_tools_pkg.ins_prog_message` | 928 |
| `Fnd_File.put_line` | 942 |
| `ar_receipt_api_pub.Create_cash` | 945 |
| `Fnd_File.put_line` | 998 |
| `Fnd_File.put_line` | 999 |
| `Fnd_File.put_line` | 1002 |
| `Fnd_File.put_line` | 1009 |
| `FND_MSG_PUB.get` | 1018 |
| `Fnd_File.put_line` | 1022 |
| `dka_tools_pkg.ins_prog_message` | 1028 |
| `Fnd_File.put_line` | 1040 |
| `Fnd_File.put_line` | 1046 |
| `AR_RECEIPT_API_PUB.Create_Apply_on_acc` | 1051 |
| `Fnd_File.put_line` | 1097 |
| `Fnd_File.put_line` | 1098 |
| `Fnd_File.put_line` | 1101 |
| `Fnd_File.put_line` | 1103 |
| `FND_MSG_PUB.get` | 1113 |
| `Fnd_File.put_line` | 1117 |
| `dka_tools_pkg.ins_prog_message` | 1123 |
| `Fnd_File.put_line` | 1134 |
| `dka_tools_pkg.put_debug_message` | 1157 |
| `dka_tools_pkg.ins_prog_message` | 1160 |
| `Fnd_File.put_line` | 1180 |
| `Fnd_File.put_line` | 1181 |
| `Fnd_File.put_line` | 1205 |
| `fnd_file.put_line` | 1216 |
| `fnd_file.put_line` | 1217 |
| `fnd_file.put_line` | 1218 |
| `fnd_file.put_line` | 1220 |
| `fnd_file.put_line` | 1223 |
| `fnd_file.put_line` | 1226 |
| `fnd_file.put_line` | 1231 |
| `fnd_file.put_line` | 1234 |
| `fnd_file.put_line` | 1237 |
| `fnd_file.put_line` | 1241 |
| `fnd_file.put_line` | 1244 |
| `Fnd_File.put_line` | 1245 |
| `Fnd_File.put_line` | 1253 |
| `Fnd_File.put_line` | 1254 |
| `Fnd_File.put_line` | 1286 |
| `Fnd_File.put_line` | 1287 |
| `Fnd_File.Put_Line` | 1311 |
| `Fnd_File.Put_Line` | 1313 |
| `Fnd_File.put_line` | 1320 |
| `Fnd_File.put_line` | 1321 |
| `Fnd_File.put_line` | 1362 |
| `Fnd_File.put_line` | 1369 |
| `Fnd_File.put_line` | 1389 |
| `Fnd_File.put_line` | 1402 |
| `Fnd_File.put_line` | 1422 |
| `Fnd_File.put_line` | 1435 |
| `Fnd_File.put_line` | 1464 |
| `Fnd_File.put_line` | 1487 |
| `Fnd_File.put_line` | 1488 |
| `Fnd_File.put_line` | 1490 |
| `Fnd_File.put_line` | 1498 |
| `Fnd_File.put_line` | 1499 |
| `Fnd_File.put_line` | 1500 |
| `Fnd_File.put_line` | 1504 |
| `Fnd_File.put_line` | 1511 |
| `Fnd_File.put_line` | 1515 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPARENCIMP` | 460 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 480, 781, 1174 |
| rollback | 2 |
| when_others | 170, 210, 552, 625, 658, 704, 784, 920, 1156, 1177, 1250, 1283, 1317, 1508 |
| suppression | 1312 |
| soumission | 460 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPARENCIMP / DKA | `DKA_REPARENCIMP_PKG.Main` | dka/12.0.0/admin/import/DKA_REPARENCIMP.prt:455 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
