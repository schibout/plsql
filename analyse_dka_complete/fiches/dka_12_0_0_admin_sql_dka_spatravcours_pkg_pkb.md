# DKA_SPATRAVCOURS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPATRAVCOURS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPATRAVCOURS_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2028 ; encodage : cp1252 (repli). SHA-256 : `3741e5669d98d36f0cfdffe318c3b73356be365a567ce0109e0122fad7f95276`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 128 |
| `clear_spatravcours_tmp` | 472 |
| `maj_calcule` | 505 |
| `maj_facture` | 545 |
| `process_projects` | 635 |
| `create_output` | 1343 |
| `gl_open_interface` | 1433 |
| `main` | 1583 |
| `REVERSE` | 1706 |
| `main_reverse` | 1940 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_operating_units` | 167 |
| `gl_period_statuses` | 187 |
| `gl_period_statuses` | 191 |
| `pa_periods` | 216 |
| `DUAL` | 241 |
| `PA_TASKS` | 522 |
| `pa_tasks` | 555 |
| `pa_tasks` | 582 |
| `pa_projects` | 723 |
| `fnd_flex_values_vl` | 735 |
| `pa_events` | 798 |
| `pa_cost_distribution_lines` | 834 |
| `pa_expenditure_items_all` | 841 |
| `pa_expenditure_types` | 843 |
| `pa_projects` | 846 |
| `dka_spatravcours_tmp` | 970 |
| `dka_spatravcours_tmp` | 1034 |
| `dka_spatravcours_tmp` | 1120 |
| `dka_spatravcours_tmp` | 1186 |
| `dka_spatravcours_tmp` | 1253 |
| `dka_spatravcours_tmp` | 1357 |
| `DUAL` | 1465 |
| `gl_interface` | 1470 |
| `gl_interface` | 1481 |
| `gl_interface` | 1487 |
| `gl_interface_control` | 1495 |
| `fnd_responsibility` | 1518 |
| `pa_projects` | 1751 |
| `dka_spatravcours_tmp` | 1832 |
| `dka_spatravcours_tmp` | 1849 |
| `dka_spatravcours_tmp` | 1863 |
| `dka_spatravcours_tmp` | 1883 |
| `dka_spatravcours_tmp` | 1908 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 148 |
| `fnd_file.put_line` | 150 |
| `fnd_profile.VALUE` | 152 |
| `fnd_profile.VALUE` | 161 |
| `fnd_profile.VALUE` | 162 |
| `fnd_profile.VALUE` | 163 |
| `dka_tools_pkg.put_log_message` | 172 |
| `pa_utils.get_pa_end_date` | 232 |
| `dka_tools_pkg.put_debug_message` | 244 |
| `dka_tools_pkg.put_debug_message` | 246 |
| `dka_tools_pkg.put_debug_message` | 247 |
| `dka_tools_pkg.put_debug_message` | 250 |
| `dka_tools_pkg.get_parameter` | 251 |
| `dka_tools_pkg.put_debug_message` | 255 |
| `dka_tools_pkg.put_debug_message` | 256 |
| `dka_tools_pkg.get_parameter` | 264 |
| `dka_tools_pkg.put_debug_message` | 267 |
| `dka_tools_pkg.get_parameter` | 277 |
| `dka_tools_pkg.put_debug_message` | 280 |
| `dka_tools_pkg.get_parameter` | 289 |
| `dka_tools_pkg.put_debug_message` | 292 |
| `dka_tools_pkg.get_parameter` | 301 |
| `dka_tools_pkg.put_debug_message` | 304 |
| `dka_tools_pkg.get_parameter` | 313 |
| `dka_tools_pkg.put_debug_message` | 316 |
| `dka_tools_pkg.get_parameter` | 324 |
| `dka_tools_pkg.put_debug_message` | 327 |
| `dka_tools_pkg.get_parameter` | 336 |
| `dka_tools_pkg.put_debug_message` | 339 |
| `dka_tools_pkg.get_parameter` | 348 |
| `dka_tools_pkg.put_debug_message` | 351 |
| `dka_tools_pkg.get_parameter` | 360 |
| `dka_tools_pkg.put_debug_message` | 363 |
| `dka_tools_pkg.get_parameter` | 371 |
| `dka_tools_pkg.put_debug_message` | 374 |
| `dka_tools_pkg.get_parameter` | 382 |
| `dka_tools_pkg.put_debug_message` | 385 |
| `dka_tools_pkg.get_parameter` | 393 |
| `dka_tools_pkg.get_parameter` | 402 |
| `dka_tools_pkg.put_debug_message` | 405 |
| `dka_tools_pkg.get_parameter` | 413 |
| `dka_tools_pkg.put_debug_message` | 416 |
| `dka_tools_pkg.get_parameter` | 435 |
| `dka_tools_pkg.get_parameter` | 444 |
| `dka_tools_pkg.put_debug_message` | 453 |
| `dka_tools_pkg.put_debug_message` | 478 |
| `dka_tools_pkg.put_debug_message` | 481 |
| `dka_tools_pkg.put_debug_message` | 513 |
| `dka_tools_pkg.put_debug_message` | 577 |
| `fnd_date.canonical_to_date` | 721 |
| `fnd_date.canonical_to_date` | 868 |
| `dka_tools_pkg.put_debug_message` | 897 |
| `dka_tools_pkg.put_debug_message` | 898 |
| `dka_tools_pkg.put_outdebug_message` | 912 |
| `dka_tools_pkg.put_outdebug_message` | 920 |
| `dka_tools_pkg.put_outdebug_message` | 923 |
| `fnd_date.canonical_to_date` | 925 |
| `dka_tools_pkg.put_outdebug_message` | 938 |
| `dka_tools_pkg.put_outdebug_message` | 945 |
| `dka_pa_tools_pkg.pa_insert_event` | 949 |
| `dka_tools_pkg.put_outdebug_message` | 1009 |
| `dka_pa_tools_pkg.pa_insert_event` | 1013 |
| `dka_tools_pkg.put_outdebug_message` | 1087 |
| `dka_tools_pkg.put_outdebug_message` | 1094 |
| `dka_pa_tools_pkg.pa_insert_event` | 1098 |
| `dka_tools_pkg.put_outdebug_message` | 1160 |
| `dka_pa_tools_pkg.pa_insert_event` | 1164 |
| `dka_tools_pkg.put_outdebug_message` | 1227 |
| `dka_pa_tools_pkg.pa_insert_event` | 1231 |
| `fnd_date.canonical_to_date` | 1292 |
| `dka_tools_pkg.put_outdebug_message` | 1305 |
| `dka_tools_pkg.put_outdebug_message` | 1312 |
| `dka_tools_pkg.put_debug_message` | 1319 |
| `dka_tools_pkg.put_debug_message` | 1320 |
| `dka_tools_pkg.put_debug_message` | 1367 |
| `fnd_file.put_line` | 1374 |
| `fnd_file.put_line` | 1376 |
| `fnd_file.put_line` | 1378 |
| `fnd_file.put_line` | 1380 |
| `fnd_file.put_line` | 1382 |
| `fnd_file.put_line` | 1384 |
| `dka_tools_pkg.put_debug_message` | 1385 |
| `fnd_file.put_line` | 1400 |
| `fnd_file.put_line` | 1408 |
| `fnd_file.put_line` | 1410 |
| `fnd_file.put_line` | 1414 |
| `dka_tools_pkg.put_debug_message` | 1415 |
| `dka_tools_pkg.put_debug_message` | 1453 |
| `dka_tools_pkg.put_debug_message` | 1455 |
| `dka_tools_pkg.put_debug_message` | 1462 |
| `dka_tools_pkg.put_debug_message` | 1475 |
| `dka_tools_pkg.put_debug_message` | 1482 |
| `dka_tools_pkg.put_debug_message` | 1492 |
| `dka_tools_pkg.put_debug_message` | 1512 |
| `dka_tools_pkg.put_debug_message` | 1521 |
| `fnd_profile.initialize` | 1522 |
| `dka_tools_pkg.put_debug_message` | 1523 |
| `fnd_request.submit_request` | 1525 |
| `FND_PROFILE.VALUE` | 1533 |
| `fnd_concurrent.wait_for_request` | 1545 |
| `dka_tools_pkg.put_debug_message` | 1554 |
| `fnd_file.put_line` | 1555 |
| `dka_tools_pkg.put_outdebug_message` | 1600 |
| `dka_spatravcours_pkg.init` | 1601 |
| `dka_tools_pkg.put_outdebug_message` | 1613 |
| `dka_spatravcours_pkg.clear_spatravcours_tmp` | 1614 |
| `dka_tools_pkg.put_outdebug_message` | 1628 |
| `dka_spatravcours_pkg.maj_facture` | 1629 |
| `dka_tools_pkg.put_outdebug_message` | 1639 |
| `dka_spatravcours_pkg.process_projects` | 1640 |
| `dka_tools_pkg.put_outdebug_message` | 1651 |
| `dka_tools_pkg.put_outdebug_message` | 1652 |
| `dka_tools_pkg.put_outdebug_message` | 1653 |
| `dka_tools_pkg.put_outdebug_message` | 1654 |
| `dka_spatravcours_pkg.create_output` | 1656 |
| `dka_tools_pkg.put_outdebug_message` | 1667 |
| `dka_spatravcours_pkg.gl_open_interface` | 1668 |
| `dka_tools_pkg.put_outdebug_message` | 1684 |
| `dka_tools_pkg.put_outdebug_message` | 1690 |
| `dka_tools_pkg.put_debug_message` | 1775 |
| `dka_tools_pkg.put_outdebug_message` | 1776 |
| `dka_tools_pkg.put_outdebug_message` | 1796 |
| `dka_tools_pkg.put_outdebug_message` | 1797 |
| `dka_tools_pkg.put_debug_message` | 1800 |
| `dka_pa_tools_pkg.pa_insert_event` | 1802 |
| `dka_tools_pkg.put_debug_message` | 1841 |
| `dka_tools_pkg.put_outdebug_message` | 1847 |
| `dka_tools_pkg.put_outdebug_message` | 1861 |
| `dka_tools_pkg.put_debug_message` | 1874 |
| `dka_tools_pkg.put_debug_message` | 1875 |
| `dka_tools_pkg.put_outdebug_message` | 1898 |
| `dka_tools_pkg.put_outdebug_message` | 1923 |
| `dka_tools_pkg.put_outdebug_message` | 1954 |
| `dka_spatravcours_pkg.init` | 1955 |
| `dka_tools_pkg.put_outdebug_message` | 1967 |
| `dka_spatravcours_pkg.REVERSE` | 1968 |
| `dka_tools_pkg.put_outdebug_message` | 1980 |
| `dka_spatravcours_pkg.gl_open_interface` | 1982 |
| `dka_tools_pkg.put_outdebug_message` | 1994 |
| `dka_tools_pkg.put_outdebug_message` | 1995 |
| `dka_tools_pkg.put_outdebug_message` | 1996 |
| `dka_tools_pkg.put_outdebug_message` | 1997 |
| `dka_spatravcours_pkg.create_output` | 1998 |
| `dka_tools_pkg.put_outdebug_message` | 2016 |
| `dka_tools_pkg.put_outdebug_message` | 2022 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLLEZL` | 1525 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1543, 1900, 1925 |
| rollback | 1303, 1310, 1683, 1689, 1845, 1859, 1880, 1905, 2014, 2021 |
| when_others | 205, 224, 455, 489, 529, 619, 1308, 1322, 1417, 1563, 1685, 1856, 1902, 2017 |
| soumission | 1525 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPATRAVCOURS / DKA | `DKA_SPATRAVCOURS_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SPATRAVCOURS.prt:494 |
| DKA_SPATRAVCOURS_EXTOURNE / DKA | `DKA_SPATRAVCOURS_PKG.main_reverse` | dka/12.0.0/admin/import/DKA_SPATRAVCOURS_EXTOURNE.prt:421 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
