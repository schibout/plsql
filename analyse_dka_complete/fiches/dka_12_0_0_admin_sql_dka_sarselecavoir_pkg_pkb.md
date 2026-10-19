# DKA_SARSELECAVOIR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARSELECAVOIR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARSELECAVOIR_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1414 ; encodage : cp1252 (repli). SHA-256 : `40f132daaa2f4a3a5fc0fd4f7afa5fca34c5991efec6ee55f9812efdab612dd6`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `out_msg` | 83 |
| `log_msg` | 100 |
| `init` | 123 |
| `INIT` | 164 |
| `write_boundary` | 178 |
| `begin_attachment` | 197 |
| `end_attachment` | 244 |
| `check_value_set` | 261 |
| `SEND_MSG` | 333 |
| `writeout` | 488 |
| `sortie_traitement` | 514 |
| `extraction_avoir_nonsold` | 544 |
| `main` | 879 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 136 |
| `v$database` | 149 |
| `fnd_flex_value_sets` | 283 |
| `fnd_flex_values` | 285 |
| `iby_external_payers_all` | 566 |
| `hz_cust_accounts` | 594 |
| `hz_cust_accounts` | 613 |
| `hz_cust_accounts` | 640 |
| `hr_all_organization_units` | 680 |
| `dka_ar_remboursement_avoirs` | 801 |
| `dka_ar_remboursement_avoirs` | 852 |
| `fnd_flex_value_sets` | 922 |
| `CTE` | 933 |
| `fnd_flex_value_sets` | 943 |
| `CTE` | 954 |
| `fnd_concurrent_requests` | 964 |
| `dka_ar_remb_avoirs_hist` | 967 |
| `dka_ar_remboursement_avoirs` | 990 |
| `fnd_concurrent_requests` | 993 |
| `dka_ar_remb_avoirs_hist` | 997 |
| `dka_ar_remboursement_avoirs` | 1020 |
| `dka_ar_remboursement_avoirs` | 1031 |
| `fnd_concurrent_requests` | 1033 |
| `dka_ar_rembours_avoirs_tmp` | 1036 |
| `fnd_concurrent_requests` | 1038 |
| `dka_ar_remboursement_avoirs` | 1042 |
| `dka_ar_rembours_avoirs_tmp` | 1044 |
| `fnd_concurrent_programs_tl` | 1073 |
| `hr_operating_units` | 1093 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 88 |
| `fnd_file.put_line` | 110 |
| `dka_tools_pkg.get_parameter` | 141 |
| `dka_tools_pkg.get_parameter` | 152 |
| `dka_tools_pkg.put_log_message` | 161 |
| `dka_tools_pkg.put_log_message` | 168 |
| `fnd_file.put_line` | 362 |
| `fnd_file.put_line` | 377 |
| `fnd_file.put_line` | 392 |
| `fnd_file.put_line` | 397 |
| `fnd_file.put_line` | 432 |
| `fnd_file.put_line` | 494 |
| `fnd_file.put_line` | 499 |
| `fnd_file.put_line` | 500 |
| `fnd_file.put_line` | 501 |
| `fnd_file.put_line` | 502 |
| `fnd_file.put_line` | 503 |
| `fnd_file.put_line` | 504 |
| `dka_tools_pkg.put_debug_message` | 723 |
| `dka_tools_pkg.put_log_message` | 741 |
| `dka_tools_pkg.put_log_message` | 769 |
| `dka_tools_pkg.put_log_message` | 860 |
| `dka_tools_pkg.put_debug_message` | 1027 |
| `dka_tools_pkg.put_debug_message` | 1048 |
| `dka_tools_pkg.get_parameter` | 1054 |
| `fnd_file.put_line` | 1057 |
| `dka_tools_pkg.put_debug_message` | 1096 |
| `dka_tools_pkg.put_log_message` | 1101 |
| `dka_tools_pkg.put_log_message` | 1102 |
| `dka_tools_pkg.put_log_message` | 1103 |
| `fnd_file.put_line` | 1104 |
| `fnd_file.put_line` | 1105 |
| `fnd_file.put_line` | 1107 |
| `fnd_file.put_line` | 1108 |
| `fnd_file.put_line` | 1109 |
| `fnd_file.put_line` | 1111 |
| `fnd_file.put_line` | 1112 |
| `fnd_file.put_line` | 1114 |
| `dka_tools_pkg.put_log_message` | 1120 |
| `fnd_file.put_line` | 1137 |
| `fnd_file.put_line` | 1157 |
| `fnd_file.put_line` | 1167 |
| `dka_tools_pkg.put_log_message` | 1179 |
| `fnd_file.put_line` | 1184 |
| `fnd_file.put_line` | 1222 |
| `fnd_file.put_line` | 1223 |
| `fnd_file.put_line` | 1230 |
| `fnd_file.put_line` | 1231 |
| `dka_tools_pkg.put_log_message` | 1237 |
| `dka_tools_pkg.put_log_message` | 1239 |
| `dka_tools_pkg.put_log_message` | 1247 |
| `dka_tools_pkg.put_log_message` | 1248 |
| `dka_tools_pkg.put_debug_message` | 1252 |
| `dka_tools_pkg.put_log_message` | 1255 |
| `dka_tools_pkg.put_log_message` | 1256 |
| `fnd_file.put_line` | 1257 |
| `fnd_file.put_line` | 1258 |
| `fnd_file.put_line` | 1260 |
| `fnd_file.put_line` | 1261 |
| `fnd_file.put_line` | 1262 |
| `fnd_file.put_line` | 1263 |
| `fnd_file.put_line` | 1264 |
| `fnd_file.put_line` | 1265 |
| `dka_tools_pkg.put_log_message` | 1271 |
| `dka_tools_pkg.get_parameter` | 1275 |
| `fnd_file.put_line` | 1278 |
| `fnd_file.put_line` | 1296 |
| `fnd_file.put_line` | 1316 |
| `fnd_file.put_line` | 1326 |
| `fnd_file.put_line` | 1341 |
| `fnd_file.put_line` | 1379 |
| `fnd_file.put_line` | 1380 |
| `fnd_file.put_line` | 1387 |
| `fnd_file.put_line` | 1388 |
| `dka_tools_pkg.put_log_message` | 1394 |
| `dka_tools_pkg.put_log_message` | 1396 |
| `dka_tools_pkg.put_log_message` | 1404 |
| `dka_tools_pkg.put_log_message` | 1405 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 843, 1023, 1051 |
| rollback | 1242, 1399 |
| when_others | 163, 456, 496 |
| suppression | 1031, 1036, 1042, 1044 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARSELECAVOIR / DKA | `DKA_SARSELECAVOIR_PKG.main` | dka/12.0.0/admin/import/DKA_SARSELECAVOIR.prt:534 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
