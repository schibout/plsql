# DKA_SPASINISTRE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPASINISTRE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPASINISTRE_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1505 ; encodage : cp1252 (repli). SHA-256 : `4877bcefbf09de71441e3f0a853a011fe47b05b15ebeec47c16f2d1675fb53c9`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 85 |
| `clear_spasinistre_tmp` | 315 |
| `get_sum_charges` | 346 |
| `pa_get_sum_event_revenue` | 407 |
| `process_active_tasks` | 465 |
| `create_output` | 861 |
| `gl_open_interface` | 938 |
| `main` | 1081 |
| `REVERSE` | 1210 |
| `main_extourne` | 1412 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_operating_units` | 126 |
| `pa_periods` | 147 |
| `gl_period_statuses` | 159 |
| `gl_period_statuses` | 164 |
| `DUAL` | 189 |
| `pa_cost_distribution_lines` | 360 |
| `pa_events` | 427 |
| `pa_projects` | 482 |
| `dka_spasinistre_tmp` | 704 |
| `dka_spasinistre_tmp` | 786 |
| `dka_spasinistre_tmp` | 874 |
| `DUAL` | 963 |
| `gl_interface` | 968 |
| `gl_interface` | 978 |
| `gl_interface_control` | 984 |
| `fnd_responsibility` | 1008 |
| `pa_projects_all` | 1237 |
| `dka_spasinistre_tmp` | 1314 |
| `dka_spasinistre_tmp` | 1331 |
| `dka_spasinistre_tmp` | 1345 |
| `dka_spasinistre_tmp` | 1370 |
| `dka_spasinistre_tmp` | 1388 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.VALUE` | 106 |
| `dka_tools_pkg.put_log_message` | 116 |
| `dka_tools_pkg.put_log_message` | 119 |
| `dka_tools_pkg.put_log_message` | 129 |
| `fnd_profile.VALUE` | 135 |
| `fnd_profile.VALUE` | 136 |
| `fnd_profile.VALUE` | 137 |
| `pa_utils.get_pa_end_date` | 151 |
| `dka_tools_pkg.put_log_message` | 153 |
| `dka_tools_pkg.put_log_message` | 192 |
| `dka_tools_pkg.get_parameter` | 193 |
| `dka_tools_pkg.get_parameter` | 202 |
| `dka_tools_pkg.put_log_message` | 205 |
| `dka_tools_pkg.get_parameter` | 215 |
| `dka_tools_pkg.get_parameter` | 224 |
| `dka_tools_pkg.get_parameter` | 233 |
| `dka_tools_pkg.get_parameter` | 242 |
| `dka_tools_pkg.get_parameter` | 251 |
| `dka_tools_pkg.get_parameter` | 260 |
| `dka_tools_pkg.get_parameter` | 269 |
| `dka_tools_pkg.get_parameter` | 278 |
| `dka_tools_pkg.get_parameter` | 287 |
| `dka_tools_pkg.put_debug_message` | 296 |
| `dka_tools_pkg.put_debug_message` | 321 |
| `dka_tools_pkg.put_debug_message` | 324 |
| `dka_tools_pkg.put_debug_message` | 381 |
| `dka_tools_pkg.put_debug_message` | 444 |
| `fnd_date.canonical_to_date` | 494 |
| `dka_tools_pkg.put_debug_message` | 518 |
| `dka_tools_pkg.put_debug_message` | 528 |
| `dka_tools_pkg.put_debug_message` | 537 |
| `dka_tools_pkg.put_debug_message` | 544 |
| `dka_tools_pkg.put_debug_message` | 549 |
| `dka_tools_pkg.put_debug_message` | 550 |
| `dka_tools_pkg.put_debug_message` | 551 |
| `dka_spasinistre_pkg.get_sum_charges` | 554 |
| `dka_tools_pkg.put_debug_message` | 556 |
| `dka_spasinistre_pkg.pa_get_sum_event_revenue` | 566 |
| `dka_tools_pkg.put_debug_message` | 594 |
| `dka_spasinistre_pkg.pa_get_sum_event_revenue` | 595 |
| `dka_tools_pkg.put_debug_message` | 607 |
| `dka_tools_pkg.put_debug_message` | 624 |
| `dka_spasinistre_pkg.pa_get_sum_event_revenue` | 625 |
| `dka_tools_pkg.put_debug_message` | 637 |
| `dka_tools_pkg.put_debug_message` | 652 |
| `dka_tools_pkg.put_debug_message` | 664 |
| `dka_pa_tools_pkg.pa_insert_event` | 670 |
| `dka_tools_pkg.put_debug_message` | 746 |
| `dka_pa_tools_pkg.pa_insert_event` | 752 |
| `dka_tools_pkg.put_debug_message` | 822 |
| `dka_tools_pkg.put_outdebug_message` | 828 |
| `dka_tools_pkg.put_outdebug_message` | 834 |
| `dka_tools_pkg.put_debug_message` | 837 |
| `dka_tools_pkg.put_debug_message` | 840 |
| `dka_tools_pkg.put_debug_message` | 843 |
| `dka_tools_pkg.put_debug_message` | 882 |
| `fnd_file.put_line` | 885 |
| `fnd_file.put_line` | 887 |
| `fnd_file.put_line` | 889 |
| `fnd_file.put_line` | 891 |
| `fnd_file.put_line` | 893 |
| `fnd_file.put_line` | 895 |
| `dka_tools_pkg.put_debug_message` | 896 |
| `fnd_file.put_line` | 909 |
| `fnd_file.put_line` | 915 |
| `fnd_file.put_line` | 917 |
| `fnd_file.put_line` | 919 |
| `dka_tools_pkg.put_debug_message` | 920 |
| `dka_tools_pkg.put_debug_message` | 1002 |
| `dka_tools_pkg.put_debug_message` | 1011 |
| `fnd_profile.initialize` | 1012 |
| `dka_tools_pkg.put_debug_message` | 1013 |
| `fnd_request.submit_request` | 1014 |
| `FND_PROFILE.VALUE` | 1023 |
| `fnd_concurrent.wait_for_request` | 1035 |
| `dka_tools_pkg.put_debug_message` | 1044 |
| `fnd_file.put_line` | 1045 |
| `dka_tools_pkg.put_debug_message` | 1053 |
| `fnd_file.put_line` | 1054 |
| `dka_tools_pkg.put_debug_message` | 1095 |
| `Fnd_File.put_line` | 1096 |
| `dka_spasinistre_pkg.init` | 1097 |
| `dka_tools_pkg.put_debug_message` | 1105 |
| `Fnd_File.put_line` | 1106 |
| `dka_spasinistre_pkg.clear_spasinistre_tmp` | 1107 |
| `dka_tools_pkg.put_debug_message` | 1126 |
| `Fnd_File.put_line` | 1127 |
| `dka_spasinistre_pkg.process_active_tasks` | 1128 |
| `dka_tools_pkg.put_debug_message` | 1149 |
| `dka_spasinistre_pkg.create_output` | 1150 |
| `dka_tools_pkg.put_debug_message` | 1169 |
| `dka_spasinistre_pkg.gl_open_interface` | 1170 |
| `dka_tools_pkg.put_debug_message` | 1258 |
| `dka_tools_pkg.put_debug_message` | 1259 |
| `dka_tools_pkg.put_debug_message` | 1264 |
| `dka_tools_pkg.put_debug_message` | 1280 |
| `dka_tools_pkg.put_debug_message` | 1281 |
| `dka_tools_pkg.put_debug_message` | 1282 |
| `dka_pa_tools_pkg.pa_insert_event` | 1284 |
| `dka_tools_pkg.put_debug_message` | 1323 |
| `dka_tools_pkg.put_outdebug_message` | 1328 |
| `dka_tools_pkg.put_outdebug_message` | 1342 |
| `dka_tools_pkg.put_debug_message` | 1356 |
| `dka_tools_pkg.put_debug_message` | 1357 |
| `dka_tools_pkg.put_debug_message` | 1368 |
| `dka_tools_pkg.put_debug_message` | 1386 |
| `dka_tools_pkg.put_debug_message` | 1426 |
| `dka_spasinistre_pkg.init` | 1427 |
| `dka_tools_pkg.put_debug_message` | 1438 |
| `dka_tools_pkg.put_debug_message` | 1441 |
| `dka_spasinistre_pkg.REVERSE` | 1442 |
| `dka_tools_pkg.put_debug_message` | 1453 |
| `dka_tools_pkg.put_debug_message` | 1456 |
| `dka_spasinistre_pkg.gl_open_interface` | 1457 |
| `dka_tools_pkg.put_debug_message` | 1468 |
| `dka_tools_pkg.put_debug_message` | 1471 |
| `dka_tools_pkg.put_debug_message` | 1472 |
| `dka_tools_pkg.put_debug_message` | 1473 |
| `dka_tools_pkg.put_debug_message` | 1474 |
| `dka_spasinistre_pkg.create_output` | 1475 |
| `dka_tools_pkg.put_debug_message` | 1486 |
| `dka_tools_pkg.put_outdebug_message` | 1494 |
| `dka_tools_pkg.put_debug_message` | 1500 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLLEZL` | 1014 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1033 |
| rollback | 827, 833, 1327, 1341, 1493, 1499 |
| when_others | 178, 298, 329, 446, 558, 830, 845, 922, 1062, 1189, 1338, 1377, 1495 |
| soumission | 1014 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPASINISTRE / DKA | `DKA_SPASINISTRE_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SPASINISTRE.prt:495 |
| DKA_SPASINISTRE_EXTOURNE / DKA | `DKA_SPASINISTRE_PKG.MAIN_EXTOURNE` | dka/12.0.0/admin/import/DKA_SPASINISTRE_EXTOURNE.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
