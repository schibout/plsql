# DKA_REP_COUTS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REP_COUTS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REP_COUTS_PKG.pkb).

Famille proposée par convention de nommage : **Fusion / reprise**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1346 ; encodage : cp1252 (repli). SHA-256 : `deb07986edc282258e153596b6f56924fe39f17efe48372d0402f68910cf38f2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `purge_data` | 152 |
| `init` | 184 |
| `Launch_Loader` | 243 |
| `control_data` | 356 |
| `insert_pa_transac_interfac_all` | 585 |
| `program_import_couts` | 897 |
| `Report_Bilan` | 1099 |
| `MAIN` | 1175 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `pa_periods` | 207 |
| `DKA_REP_COUTS_INTERFACE` | 323 |
| `dka_rep_couts_interface` | 370 |
| `dka_rep_couts_interface` | 378 |
| `dka_rep_couts_interface` | 394 |
| `hr_operating_units` | 423 |
| `dka_rep_couts_interface` | 429 |
| `dka_rep_couts_interface` | 438 |
| `dka_rep_couts_interface` | 456 |
| `dka_rep_couts_interface` | 461 |
| `pa_projects_all` | 470 |
| `dka_rep_couts_interface` | 476 |
| `hr_operating_units` | 484 |
| `dka_rep_couts_interface` | 492 |
| `dka_rep_couts_interface` | 503 |
| `pa_expenditure_types` | 509 |
| `dka_rep_couts_interface` | 517 |
| `dka_rep_couts_interface` | 523 |
| `dka_rep_couts_interface` | 556 |
| `dka_rep_couts_interface` | 596 |
| `pa_transaction_interface_all` | 623 |
| `pa_transaction_interface_all` | 626 |
| `PA_PROJECTS_ALL` | 660 |
| `gl_code_combinations` | 670 |
| `pa_transaction_interface_all` | 698 |
| `pa_transaction_interface_all` | 867 |
| `fnd_responsibility` | 917 |
| `pa_transaction_interface_all` | 940 |
| `pa_transaction_interface_all` | 1048 |
| `dka_rep_couts_interface` | 1053 |
| `dka_rep_couts_interface` | 1060 |
| `dka_rep_couts_interface` | 1066 |
| `pa_transaction_interface_all` | 1102 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 157 |
| `dka_tools_pkg.put_log_message` | 162 |
| `dka_tools_pkg.put_log_message` | 189 |
| `dka_tools_pkg.put_log_message` | 212 |
| `dka_tools_pkg.put_log_message` | 218 |
| `dka_tools_pkg.put_log_message` | 219 |
| `dka_tools_pkg.put_log_message` | 254 |
| `dka_tools_pkg.put_outdebug_message` | 256 |
| `dka_tools_pkg.put_outdebug_message` | 257 |
| `Fnd_Request.submit_request` | 264 |
| `dka_tools_pkg.put_outdebug_message` | 279 |
| `dka_tools_pkg.put_log_message` | 282 |
| `dka_tools_pkg.put_outdebug_message` | 284 |
| `Fnd_Concurrent.wait_for_request` | 288 |
| `dka_tools_pkg.put_log_message` | 298 |
| `dka_tools_pkg.put_log_message` | 303 |
| `dka_tools_pkg.put_outdebug_message` | 306 |
| `dka_tools_pkg.put_outdebug_message` | 313 |
| `dka_tools_pkg.put_log_message` | 326 |
| `dka_tools_pkg.put_log_message` | 333 |
| `dka_tools_pkg.put_log_message` | 334 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 387 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 445 |
| `dka_rep_transco_pkg.get_transco` | 499 |
| `dka_tools_pkg.get_code_combination_id` | 532 |
| `dka_tools_pkg.put_log_message` | 550 |
| `dka_tools_pkg.put_log_message` | 554 |
| `dka_tools_pkg.put_log_message` | 568 |
| `dka_tools_pkg.put_log_message` | 617 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 643 |
| `dka_tools_pkg.put_log_message` | 648 |
| `dka_tools_pkg.put_log_message` | 666 |
| `pa_utils.GetWeekEnding` | 777 |
| `dka_tools_pkg.put_log_message` | 871 |
| `dka_tools_pkg.put_log_message` | 872 |
| `dka_tools_pkg.put_log_message` | 879 |
| `dka_tools_pkg.put_log_message` | 959 |
| `dka_tools_pkg.put_log_message` | 965 |
| `fnd_global.apps_initialize` | 969 |
| `fnd_request.set_org_id` | 976 |
| `fnd_request.submit_request` | 978 |
| `dka_tools_pkg.put_log_message` | 989 |
| `dka_tools_pkg.put_outdebug_message` | 994 |
| `fnd_concurrent.wait_for_request` | 1001 |
| `dka_tools_pkg.put_log_message` | 1011 |
| `dka_tools_pkg.put_log_message` | 1018 |
| `dka_tools_pkg.put_outdebug_message` | 1021 |
| `dka_tools_pkg.put_log_message` | 1025 |
| `dka_tools_pkg.put_outdebug_message` | 1028 |
| `dka_tools_pkg.put_outdebug_message` | 1037 |
| `dka_tools_pkg.put_log_message` | 1038 |
| `dka_tools_pkg.put_log_message` | 1079 |
| `dka_tools_pkg.put_log_message` | 1105 |
| `dka_tools_pkg.put_outdebug_message` | 1115 |
| `dka_tools_pkg.put_outdebug_message` | 1116 |
| `dka_tools_pkg.put_outdebug_message` | 1117 |
| `dka_tools_pkg.put_outdebug_message` | 1118 |
| `dka_tools_pkg.put_outdebug_message` | 1121 |
| `dka_tools_pkg.put_outdebug_message` | 1123 |
| `dka_tools_pkg.put_outdebug_message` | 1124 |
| `dka_tools_pkg.put_outdebug_message` | 1125 |
| `dka_tools_pkg.put_outdebug_message` | 1126 |
| `dka_tools_pkg.put_outdebug_message` | 1128 |
| `dka_tools_pkg.put_outdebug_message` | 1134 |
| `dka_tools_pkg.put_outdebug_message` | 1135 |
| `dka_tools_pkg.put_outdebug_message` | 1136 |
| `dka_tools_pkg.put_outdebug_message` | 1137 |
| `dka_tools_pkg.put_outdebug_message` | 1138 |
| `dka_tools_pkg.put_outdebug_message` | 1139 |
| `dka_tools_pkg.put_outdebug_message` | 1141 |
| `dka_tools_pkg.put_log_message` | 1146 |
| `dka_tools_pkg.put_log_message` | 1153 |
| `dka_tools_pkg.put_log_message` | 1154 |
| `dka_tools_pkg.put_outdebug_message` | 1206 |
| `dka_tools_pkg.put_outdebug_message` | 1208 |
| `dka_tools_pkg.put_outdebug_message` | 1209 |
| `dka_tools_pkg.put_log_message` | 1213 |
| `dka_tools_pkg.put_log_message` | 1221 |
| `dka_tools_pkg.put_log_message` | 1236 |
| `dka_tools_pkg.put_log_message` | 1237 |
| `dka_tools_pkg.put_log_message` | 1238 |
| `dka_tools_pkg.put_outdebug_message` | 1244 |
| `dka_tools_pkg.put_outdebug_message` | 1247 |
| `dka_tools_pkg.put_log_message` | 1257 |
| `dka_tools_pkg.put_log_message` | 1258 |
| `dka_tools_pkg.put_log_message` | 1259 |
| `dka_tools_pkg.put_log_message` | 1263 |
| `dka_tools_pkg.put_log_message` | 1268 |
| `dka_tools_pkg.put_log_message` | 1269 |
| `dka_tools_pkg.put_log_message` | 1270 |
| `dka_tools_pkg.put_log_message` | 1276 |
| `dka_tools_pkg.put_log_message` | 1289 |
| `dka_tools_pkg.put_log_message` | 1290 |
| `dka_tools_pkg.put_log_message` | 1291 |
| `dka_tools_pkg.put_log_message` | 1292 |
| `dka_tools_pkg.put_log_message` | 1299 |
| `dka_tools_pkg.put_log_message` | 1304 |
| `dka_tools_pkg.put_log_message` | 1305 |
| `dka_tools_pkg.put_log_message` | 1306 |
| `dka_tools_pkg.put_log_message` | 1307 |
| `dka_tools_pkg.put_log_message` | 1308 |
| `dka_tools_pkg.put_log_message` | 1309 |
| `dka_tools_pkg.put_log_message` | 1310 |
| `dka_tools_pkg.put_log_message` | 1315 |
| `dka_tools_pkg.put_log_message` | 1316 |
| `dka_tools_pkg.put_log_message` | 1325 |
| `dka_tools_pkg.put_log_message` | 1326 |
| `dka_tools_pkg.put_log_message` | 1327 |
| `dka_tools_pkg.put_log_message` | 1328 |
| `dka_tools_pkg.put_log_message` | 1329 |
| `dka_tools_pkg.put_log_message` | 1330 |
| `dka_tools_pkg.put_log_message` | 1331 |
| `dka_tools_pkg.put_log_message` | 1332 |
| `dka_tools_pkg.put_log_message` | 1333 |
| `dka_tools_pkg.put_log_message` | 1335 |
| `dka_tools_pkg.put_log_message` | 1336 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_REPCOUTS_IMP_LOADER` | 264 |
| `PAXTRTRX` | 978 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 281, 562, 993 |
| rollback | 1318, 1339 |
| when_others | 215, 330, 565, 876, 1075, 1150, 1320 |
| suppression | 623 |
| truncate | 160 |
| soumission | 264, 978 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPCOUTS_IMP / DKA | `DKA_REP_COUTS_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPCOUTS_IMP.prt:594 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
