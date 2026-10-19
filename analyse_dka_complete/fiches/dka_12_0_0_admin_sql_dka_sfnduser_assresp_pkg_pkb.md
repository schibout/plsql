# DKA_SFNDUSER_ASSRESP_PKG.PKB

Source : [dka/12.0.0/admin/sql/DKA_SFNDUSER_ASSRESP_PKG.PKB](../../dka/12.0.0/admin/sql/DKA_SFNDUSER_ASSRESP_PKG.PKB).

Famille proposée par convention de nommage : **FND / administration**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1729 ; encodage : cp1252 (repli). SHA-256 : `eaecc58c1c170458a344ad444bade306de14e7f3eb3a5189cafc81357d332a09`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 94 |
| `Request_parameters` | 148 |
| `output_end` | 238 |
| `init` | 252 |
| `validate_data_group` | 354 |
| `validate_data` | 845 |
| `import_data` | 937 |
| `Launch_Loader` | 1283 |
| `Report_Bilan` | 1395 |
| `purge_data` | 1529 |
| `main` | 1571 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 109 |
| `fnd_concurrent_requests` | 154 |
| `fnd_concurrent_requests` | 185 |
| `fnd_concurrent_requests` | 202 |
| `fnd_concurrent_requests` | 318 |
| `dka.DKA_SFNDUSER_ASSRESP` | 402 |
| `OF` | 408 |
| `DKA_SFNDUSER_ASSRESP` | 438 |
| `fnd_user` | 444 |
| `DKA_SFNDUSER_ASSRESP` | 447 |
| `DKA_SFNDUSER_ASSRESP` | 466 |
| `fnd_responsibility_tl` | 477 |
| `DKA_SFNDUSER_ASSRESP` | 497 |
| `fnd_responsibility` | 506 |
| `DKA_SFNDUSER_ASSRESP` | 528 |
| `DKA_SFNDUSER_ASSRESP` | 551 |
| `fnd_user` | 559 |
| `fnd_user` | 569 |
| `DKA_SFNDUSER_ASSRESP` | 587 |
| `fnd_user` | 597 |
| `DKA_SFNDUSER_ASSRESP` | 623 |
| `fnd_user` | 635 |
| `fnd_user` | 654 |
| `DKA_SFNDUSER_ASSRESP` | 678 |
| `fnd_user` | 688 |
| `DKA_SFNDUSER_ASSRESP` | 716 |
| `fnd_user` | 728 |
| `DKA_SFNDUSER_ASSRESP` | 748 |
| `fnd_user` | 756 |
| `DKA_SFNDUSER_ASSRESP` | 787 |
| `DKA_SFNDUSER_ASSRESP` | 796 |
| `DKA_SFNDUSER_ASSRESP` | 807 |
| `dka.DKA_SFNDUSER_ASSRESP` | 890 |
| `DKA_SFNDUSER_ASSRESP` | 961 |
| `fnd_user` | 967 |
| `FND_USER_RESP_GROUPS_DIRECT` | 976 |
| `DKA_SFNDUSER_ASSRESP` | 980 |
| `FND_USER` | 992 |
| `DKA_SFNDUSER_ASSRESP` | 998 |
| `DKA_SFNDUSER_ASSRESP` | 1018 |
| `fnd_responsibility_tl` | 1029 |
| `FND_RESPONSIBILITY_TL` | 1041 |
| `DKA_SFNDUSER_ASSRESP` | 1065 |
| `DKA_SFNDUSER_ASSRESP` | 1085 |
| `fnd_responsibility_tl` | 1096 |
| `FND_USER_RESP_GROUPS_DIRECT` | 1103 |
| `FND_RESPONSIBILITY_TL` | 1121 |
| `DKA_SFNDUSER_ASSRESP` | 1145 |
| `DKA_SFNDUSER_ASSRESP` | 1164 |
| `FND_RESPONSIBILITY_TL` | 1177 |
| `DKA_SFNDUSER_ASSRESP` | 1201 |
| `DKA_SFNDUSER_ASSRESP` | 1207 |
| `DKA_SFNDUSER_ASSRESP` | 1225 |
| `FND_USER` | 1238 |
| `DKA_SFNDUSER_ASSRESP` | 1326 |
| `dka_program_messages` | 1400 |
| `fnd_user` | 1409 |
| `FND_USER_RESP_GROUPS_DIRECT` | 1418 |
| `DKA_SFNDUSER_ASSRESP` | 1423 |
| `DKA_SFNDUSER_ASSRESP` | 1447 |
| `DKA_SFNDUSER_ASSRESP` | 1453 |
| `DKA_SFNDUSER_ASSRESP` | 1457 |
| `dual` | 1462 |
| `DKA_SFNDUSER_ASSRESP` | 1542 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 124 |
| `Fnd_File.put_line` | 125 |
| `Fnd_File.put_line` | 126 |
| `Fnd_File.put_line` | 127 |
| `Fnd_File.put_line` | 128 |
| `Fnd_File.put_line` | 170 |
| `Fnd_File.put_line` | 171 |
| `Fnd_File.put_line` | 172 |
| `Fnd_File.put_line` | 173 |
| `Fnd_File.put_line` | 190 |
| `Fnd_File.put_line` | 191 |
| `Fnd_File.put_line` | 208 |
| `Fnd_File.put_line` | 215 |
| `Fnd_File.put_line` | 245 |
| `Fnd_File.put_line` | 246 |
| `Fnd_File.put_line` | 247 |
| `Fnd_File.put_line` | 267 |
| `Fnd_File.put_line` | 311 |
| `Fnd_File.put_line` | 323 |
| `fnd_file.put_line` | 330 |
| `Fnd_File.put_line` | 413 |
| `Fnd_File.put_line` | 414 |
| `dka_tools_pkg.get_message` | 424 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 426 |
| `dka_tools_pkg.get_message` | 452 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 454 |
| `dka_tools_pkg.get_message` | 483 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 485 |
| `dka_tools_pkg.get_message` | 514 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 516 |
| `dka_tools_pkg.get_message` | 537 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 539 |
| `dka_tools_pkg.get_message` | 573 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 575 |
| `dka_tools_pkg.get_message` | 609 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 611 |
| `dka_tools_pkg.get_message` | 664 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 666 |
| `dka_tools_pkg.get_message` | 702 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 704 |
| `dka_tools_pkg.get_message` | 734 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 736 |
| `dka_tools_pkg.get_message` | 773 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 775 |
| `fnd_file.put_line` | 802 |
| `Fnd_File.put_line` | 813 |
| `Fnd_File.put_line` | 821 |
| `Fnd_File.put_line` | 822 |
| `Fnd_File.put_line` | 896 |
| `Fnd_File.put_line` | 897 |
| `Fnd_File.put_line` | 905 |
| `Fnd_File.put_line` | 913 |
| `Fnd_File.put_line` | 914 |
| `fnd_profile.value` | 957 |
| `dka_tools_pkg.get_message` | 1005 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1007 |
| `FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT` | 1056 |
| `dka_tools_pkg.get_message` | 1072 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1074 |
| `FND_USER_RESP_GROUPS_API.UPDATE_ASSIGNMENT` | 1136 |
| `dka_tools_pkg.get_message` | 1151 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1153 |
| `dka_tools_pkg.get_message` | 1188 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1190 |
| `fnd_user_pkg.addresp` | 1206 |
| `dka_tools_pkg.get_message` | 1212 |
| `DKA_TOOLS_PKG.INS_PROG_MESSAGE` | 1214 |
| `Fnd_File.put_line` | 1248 |
| `Fnd_File.put_line` | 1255 |
| `Fnd_File.put_line` | 1256 |
| `Fnd_File.put_line` | 1296 |
| `Fnd_File.put_line` | 1297 |
| `Fnd_File.put_line` | 1299 |
| `Fnd_File.put_line` | 1300 |
| `Fnd_File.put_line` | 1301 |
| `fnd_request.set_print_options` | 1308 |
| `Fnd_Request.submit_request` | 1311 |
| `fnd_file.put_line` | 1323 |
| `Fnd_File.put_line` | 1331 |
| `Fnd_File.put_line` | 1332 |
| `Fnd_Concurrent.wait_for_request` | 1336 |
| `Fnd_file.put_line` | 1339 |
| `Fnd_File.put_line` | 1345 |
| `Fnd_File.put_line` | 1346 |
| `Fnd_File.put_line` | 1351 |
| `fnd_file.put_line` | 1359 |
| `Fnd_File.put_line` | 1362 |
| `Fnd_File.put_line` | 1363 |
| `Fnd_File.put_line` | 1369 |
| `Fnd_File.put_line` | 1376 |
| `Fnd_File.put_line` | 1377 |
| `Fnd_File.put_line` | 1438 |
| `Fnd_File.put_line` | 1467 |
| `Fnd_File.put_line` | 1468 |
| `Fnd_File.put_line` | 1469 |
| `fnd_file.put_line` | 1472 |
| `fnd_file.put_line` | 1473 |
| `fnd_file.put_line` | 1474 |
| `Fnd_File.put_line` | 1476 |
| `Fnd_File.put_line` | 1477 |
| `Fnd_File.put_line` | 1478 |
| `Fnd_File.put_line` | 1480 |
| `Fnd_File.put_line` | 1482 |
| `Fnd_File.put_line` | 1487 |
| `Fnd_File.put_line` | 1490 |
| `Fnd_File.put_line` | 1494 |
| `Fnd_File.put_line` | 1495 |
| `Fnd_File.put_line` | 1496 |
| `Fnd_File.put_line` | 1497 |
| `Fnd_File.put_line` | 1498 |
| `Fnd_File.put_line` | 1504 |
| `Fnd_File.put_line` | 1508 |
| `fnd_file.put_line` | 1510 |
| `Fnd_File.put_line` | 1511 |
| `Fnd_File.Put_Line` | 1541 |
| `Fnd_File.put_line` | 1551 |
| `Fnd_File.put_line` | 1552 |
| `Fnd_File.put_line` | 1593 |
| `Fnd_File.put_line` | 1600 |
| `Fnd_File.put_line` | 1617 |
| `Fnd_File.put_line` | 1635 |
| `Fnd_File.put_line` | 1696 |
| `Fnd_File.put_line` | 1697 |
| `Fnd_File.put_line` | 1699 |
| `Fnd_File.put_line` | 1706 |
| `Fnd_File.put_line` | 1707 |
| `Fnd_File.put_line` | 1708 |
| `Fnd_File.put_line` | 1709 |
| `Fnd_File.put_line` | 1714 |
| `Fnd_File.put_line` | 1715 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_SFNDUSER_ASSRESP_LOADER` | 1311 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 815, 907, 1233, 1249, 1327, 1330, 1691 |
| rollback | 805, 1259 |
| when_others | 117, 332, 451, 482, 512, 564, 607, 647, 700, 733, 769, 801, 818, 910, 1003, 1070, 1107, 1149, 1187, 1211, 1252, 1372, 1464, 1547, 1710 |
| suppression | 1326, 1542 |
| soumission | 1311 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SFNDUSER_ASSRESP / DKA | `DKA_SFNDUSER_ASSRESP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SFNDUSER_ASSRESP.prt:461 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
