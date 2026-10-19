# DKA_SGLCLOTURE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SGLCLOTURE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SGLCLOTURE_PKG.pkb).

Famille proposée par convention de nommage : **GL / comptabilité**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1401 ; encodage : cp1252 (repli). SHA-256 : `d048a0eb6b900e5d12cbd14ea4c74774ad23ff3736cb37fe946213c191ec06ae`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_configuration_id` | 48 |
| `get_legal` | 121 |
| `get_restit` | 177 |
| `period_to_close` | 235 |
| `period_to_open` | 343 |
| `CONSOLIDATION_RESTIT` | 410 |
| `open_next_period` | 558 |
| `CLOSE_PREVIOUS_PERIOD` | 707 |
| `wait_for_request` | 836 |
| `CLOSE_LEDGER` | 934 |
| `Bilan` | 1074 |
| `main` | 1199 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_ledger_configurations` | 59 |
| `gl_ledger_relationships` | 135 |
| `gl_ledger_relationships` | 190 |
| `gl_period_statuses` | 288 |
| `gl_period_statuses` | 292 |
| `gl_access_set_assignments` | 297 |
| `gl_access_set_assignments` | 307 |
| `gl_period_statuses` | 359 |
| `gl_period_statuses` | 362 |
| `gl_consolidation_v` | 433 |
| `GL_CONSOLIDATION_HISTORY` | 438 |
| `gl_period_statuses` | 584 |
| `gl_ledgers` | 599 |
| `gl_period_statuses` | 732 |
| `gl_period_statuses` | 1084 |
| `gl_access_set_assignments` | 1090 |
| `gl_ledger_relationships` | 1108 |
| `gl_ledger_relationships` | 1124 |
| `gl_ledger_relationships` | 1143 |
| `gl_ledger_relationships` | 1159 |
| `gl_access_set_assignments` | 1223 |
| `gl_period_statuses` | 1230 |
| `gl_ledger_relationships` | 1236 |
| `gl_access_set_assignments` | 1240 |
| `fnd_responsibility` | 1253 |
| `gl_access_sets` | 1294 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 56 |
| `dka_tools_pkg.put_debug_message` | 89 |
| `dka_tools_pkg.put_log_message` | 90 |
| `dka_tools_pkg.put_log_message` | 95 |
| `dka_tools_pkg.put_log_message` | 103 |
| `dka_tools_pkg.put_log_message` | 104 |
| `dka_tools_pkg.put_log_message` | 130 |
| `dka_tools_pkg.put_debug_message` | 143 |
| `dka_tools_pkg.put_log_message` | 144 |
| `dka_tools_pkg.put_log_message` | 151 |
| `dka_tools_pkg.put_log_message` | 157 |
| `dka_tools_pkg.put_debug_message` | 159 |
| `dka_tools_pkg.put_log_message` | 186 |
| `dka_tools_pkg.put_debug_message` | 198 |
| `dka_tools_pkg.put_log_message` | 199 |
| `dka_tools_pkg.put_log_message` | 205 |
| `dka_tools_pkg.put_log_message` | 212 |
| `dka_tools_pkg.put_debug_message` | 213 |
| `dka_tools_pkg.put_log_message` | 245 |
| `Fnd_Profile.VALUE` | 299 |
| `Fnd_Profile.VALUE` | 309 |
| `dka_tools_pkg.put_log_message` | 317 |
| `dka_tools_pkg.put_debug_message` | 322 |
| `dka_tools_pkg.put_log_message` | 353 |
| `dka_tools_pkg.put_debug_message` | 367 |
| `dka_tools_pkg.put_debug_message` | 374 |
| `dka_tools_pkg.put_debug_message` | 377 |
| `dka_tools_pkg.put_debug_message` | 382 |
| `dka_tools_pkg.put_log_message` | 390 |
| `dka_tools_pkg.put_log_message` | 430 |
| `fnd_request.submit_request` | 457 |
| `Fnd_Profile.VALUE` | 482 |
| `fnd_concurrent.wait_for_request` | 485 |
| `dka_tools_pkg.put_debug_message` | 498 |
| `dka_tools_pkg.put_debug_message` | 510 |
| `dka_tools_pkg.put_log_message` | 518 |
| `dka_tools_pkg.put_log_message` | 527 |
| `dka_tools_pkg.put_log_message` | 532 |
| `dka_tools_pkg.put_log_message` | 539 |
| `dka_tools_pkg.put_log_message` | 576 |
| `dka_tools_pkg.put_debug_message` | 592 |
| `dka_tools_pkg.put_debug_message` | 603 |
| `fnd_request.submit_request` | 608 |
| `dka_tools_pkg.put_debug_message` | 628 |
| `dka_tools_pkg.put_debug_message` | 633 |
| `dka_tools_pkg.put_debug_message` | 634 |
| `dka_tools_pkg.put_log_message` | 686 |
| `dka_tools_pkg.put_log_message` | 724 |
| `fnd_request.submit_request` | 740 |
| `dka_tools_pkg.put_debug_message` | 761 |
| `dka_tools_pkg.put_debug_message` | 766 |
| `dka_tools_pkg.put_debug_message` | 767 |
| `dka_tools_pkg.put_debug_message` | 809 |
| `dka_tools_pkg.put_log_message` | 811 |
| `dka_tools_pkg.put_log_message` | 816 |
| `dka_tools_pkg.put_log_message` | 848 |
| `dka_tools_pkg.put_debug_message` | 851 |
| `fnd_concurrent.wait_for_request` | 852 |
| `dka_tools_pkg.put_debug_message` | 864 |
| `dka_tools_pkg.put_debug_message` | 865 |
| `dka_tools_pkg.put_debug_message` | 870 |
| `dka_tools_pkg.put_debug_message` | 875 |
| `fnd_concurrent.wait_for_request` | 876 |
| `dka_tools_pkg.put_debug_message` | 888 |
| `dka_tools_pkg.put_debug_message` | 889 |
| `dka_tools_pkg.put_debug_message` | 894 |
| `dka_tools_pkg.put_log_message` | 913 |
| `dka_tools_pkg.put_log_message` | 945 |
| `dka_tools_pkg.put_debug_message` | 952 |
| `dka_tools_pkg.put_debug_message` | 971 |
| `dka_tools_pkg.put_debug_message` | 984 |
| `dka_tools_pkg.put_debug_message` | 1017 |
| `dka_tools_pkg.put_debug_message` | 1024 |
| `dka_tools_pkg.put_log_message` | 1048 |
| `dka_tools_pkg.put_log_message` | 1052 |
| `dka_tools_pkg.put_log_message` | 1053 |
| `Fnd_Profile.VALUE` | 1091 |
| `dka_tools_pkg.put_outdebug_message` | 1098 |
| `dka_tools_pkg.put_outdebug_message` | 1099 |
| `dka_tools_pkg.put_outdebug_message` | 1100 |
| `dka_tools_pkg.put_outdebug_message` | 1101 |
| `dka_tools_pkg.put_outdebug_message` | 1103 |
| `dka_tools_pkg.put_outdebug_message` | 1116 |
| `dka_tools_pkg.put_outdebug_message` | 1132 |
| `dka_tools_pkg.put_outdebug_message` | 1139 |
| `dka_tools_pkg.put_outdebug_message` | 1151 |
| `dka_tools_pkg.put_outdebug_message` | 1167 |
| `dka_tools_pkg.put_debug_message` | 1180 |
| `dka_tools_pkg.put_log_message` | 1182 |
| `Fnd_Profile.VALUE` | 1224 |
| `Fnd_Profile.VALUE` | 1241 |
| `dka_tools_pkg.put_debug_message` | 1255 |
| `fnd_global.apps_initialize` | 1258 |
| `Fnd_Profile.VALUE` | 1267 |
| `dka_tools_pkg.get_parameter` | 1282 |
| `dka_tools_pkg.put_debug_message` | 1292 |
| `dka_tools_pkg.put_debug_message` | 1318 |
| `dka_tools_pkg.put_outdebug_message` | 1332 |
| `dka_tools_pkg.put_outdebug_message` | 1337 |
| `dka_tools_pkg.put_debug_message` | 1340 |
| `dka_tools_pkg.put_debug_message` | 1341 |
| `dka_tools_pkg.put_debug_message` | 1343 |
| `dka_tools_pkg.put_debug_message` | 1346 |
| `dka_tools_pkg.put_debug_message` | 1351 |
| `dka_tools_pkg.put_debug_message` | 1356 |
| `dka_tools_pkg.put_debug_message` | 1357 |
| `dka_tools_pkg.put_debug_message` | 1358 |
| `dka_tools_pkg.put_debug_message` | 1367 |
| `dka_tools_pkg.put_log_message` | 1390 |
| `dka_tools_pkg.put_debug_message` | 1392 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `GLCCON` | 457 |
| `GLOOAP` | 608 |
| `GLOCPP` | 740 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 454, 483, 632, 765 |
| when_others | 101, 155, 210, 320, 386, 535, 688, 814, 912, 1050, 1118, 1134, 1153, 1169, 1178, 1388 |
| soumission | 457, 608, 740 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SGLCLOTURE / DKA | `DKA_SGLCLOTURE_PKG.MAIN` | dka/12.0.0/admin/import/DKA_SGLCLOTURE.prt:483 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
