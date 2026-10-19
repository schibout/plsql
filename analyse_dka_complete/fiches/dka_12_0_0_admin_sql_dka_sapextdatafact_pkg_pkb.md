# DKA_SAPEXTDATAFACT_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPEXTDATAFACT_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPEXTDATAFACT_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1326 ; encodage : cp1252 (repli). SHA-256 : `5551ca0ec21ae9f48d9a7073d6496e8ab53c9498bcce4968d2d4719ba1bca81c`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `output_header` | 44 |
| `output_end` | 97 |
| `extraction_datalake` | 128 |
| `main` | 1262 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_programs` | 59 |
| `ap_terms_tl` | 187 |
| `AP_INVOICES_ALL` | 236 |
| `dka_sextfacture_entete` | 338 |
| `dka_sextfacture_ligne` | 414 |
| `dka_sextreglement` | 463 |
| `dka_parameters` | 507 |
| `dka_parameters` | 513 |
| `dka_sextfacture_entete` | 528 |
| `fnd_concurrent_requests` | 531 |
| `dka_sextfacture_ligne` | 543 |
| `fnd_concurrent_requests` | 546 |
| `dka_sextreglement` | 558 |
| `fnd_concurrent_requests` | 561 |
| `dka_sextfacture_entete` | 598 |
| `dka_sextfacture_ligne` | 707 |
| `pa_projects_all` | 757 |
| `pa_tasks` | 762 |
| `pa_projects_all` | 774 |
| `pa_tasks` | 779 |
| `fnd_flex_value_sets` | 795 |
| `fnd_flex_values_vl` | 796 |
| `fnd_flex_value_sets` | 810 |
| `fnd_flex_values_vl` | 811 |
| `AP_INVOICE_LINES_ALL` | 821 |
| `dka_sextreglement` | 850 |
| `AP_CHECKS_ALL` | 894 |
| `dka_sextfacture_ligne` | 918 |
| `dba_directories` | 958 |
| `dba_directories` | 1053 |
| `dba_directories` | 1152 |
| `dka_parameters` | 1227 |
| `dka_parameters` | 1232 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 74 |
| `Fnd_File.put_line` | 75 |
| `Fnd_File.put_line` | 76 |
| `Fnd_File.put_line` | 77 |
| `Fnd_File.put_line` | 78 |
| `Fnd_File.put_line` | 104 |
| `Fnd_File.put_line` | 105 |
| `Fnd_File.put_line` | 106 |
| `AP_INVOICES_PKG.GET_APPROVAL_STATUS` | 181 |
| `dka_tools_pkg.put_debug_message` | 503 |
| `dka_tools_pkg.put_debug_message` | 526 |
| `dka_tools_pkg.put_debug_message` | 538 |
| `dka_tools_pkg.put_debug_message` | 553 |
| `dka_tools_pkg.put_debug_message` | 568 |
| `dka_tools_pkg.put_debug_message` | 581 |
| `dka_tools_pkg.put_log_message` | 590 |
| `dka_tools_pkg.put_log_message` | 698 |
| `dka_tools_pkg.put_log_message` | 705 |
| `dka_tools_pkg.put_log_message` | 843 |
| `dka_tools_pkg.put_log_message` | 905 |
| `dka_tools_pkg.put_debug_message` | 930 |
| `dka_tools_pkg.put_debug_message` | 932 |
| `dka_tools_pkg.put_debug_message` | 944 |
| `dka_tools_pkg.put_log_message` | 965 |
| `dka_tools_pkg.put_log_message` | 970 |
| `dka_tools_pkg.put_log_message` | 982 |
| `dka_tools_pkg.put_debug_message` | 1036 |
| `dka_tools_pkg.put_log_message` | 1060 |
| `dka_tools_pkg.put_log_message` | 1065 |
| `dka_tools_pkg.put_log_message` | 1077 |
| `dka_tools_pkg.put_debug_message` | 1136 |
| `dka_tools_pkg.put_log_message` | 1159 |
| `dka_tools_pkg.put_log_message` | 1164 |
| `dka_tools_pkg.put_log_message` | 1176 |
| `dka_tools_pkg.put_debug_message` | 1225 |
| `dka_tools_pkg.put_debug_message` | 1238 |
| `Fnd_File.put_line` | 1287 |
| `Fnd_File.put_line` | 1292 |
| `Fnd_File.put_line` | 1293 |
| `Fnd_File.put_line` | 1294 |
| `Fnd_File.put_line` | 1295 |
| `Fnd_File.put_line` | 1296 |
| `Fnd_File.put_line` | 1306 |
| `Fnd_File.put_line` | 1307 |
| `Fnd_File.put_line` | 1308 |
| `Fnd_File.put_line` | 1309 |
| `Fnd_File.put_line` | 1310 |
| `Fnd_File.put_line` | 1315 |
| `Fnd_File.put_line` | 1316 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 541, 556, 571, 701, 846, 909, 926, 1237 |
| when_others | 67, 518, 696, 841, 903, 922, 1241, 1311 |
| suppression | 528, 543, 558, 918 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SAPEXTDATAFACT / DKA | `DKA_SAPEXTDATAFACT_PKG.main` | dka/12.0.0/admin/import/DKA_SAPEXTDATAFACT.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
