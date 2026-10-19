# DKA_PA_TOOLS_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_PA_TOOLS_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_PA_TOOLS_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2847 ; encodage : cp1252 (repli). SHA-256 : `0066b219fcea3fbba4352756a48dbd7a581a1f504ba101fc6413e6dd4073e0ef`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `pa_check_transaction_data` | 61 |
| `pa_aa_run_function_transaction` | 250 |
| `pa_insert_event` | 569 |
| `pa_get_info_task` | 2164 |
| `pa_get_code_z_refac` | 2251 |
| `get_project_info` | 2335 |
| `pa_run_accounting_rule` | 2395 |
| `get_centre_finance` | 2591 |
| `get_appart` | 2627 |
| `get_class_project` | 2663 |
| `get_parent_project` | 2690 |
| `pa_get_project_task` | 2722 |
| `pa_get_period` | 2788 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `pa_tasks` | 124 |
| `DUAL` | 143 |
| `pa_transaction_controls` | 147 |
| `pa_transaction_controls` | 163 |
| `pa_projects_all` | 182 |
| `pa_projects_all` | 212 |
| `pa_segment_rule_pairings` | 297 |
| `pa_rule_parameters` | 313 |
| `pa_function_transactions` | 326 |
| `pa_class_categories` | 367 |
| `pa_parameters` | 388 |
| `pa_class_categories` | 412 |
| `pa_parameters` | 433 |
| `pa_segment_value_lookups` | 472 |
| `gl_periods` | 645 |
| `pa_events` | 696 |
| `hr_all_organization_units` | 717 |
| `pa_projects` | 731 |
| `PA_PROJECTS` | 755 |
| `pa_events` | 768 |
| `pa_draft_revenues_all` | 952 |
| `pa_project_fundings` | 974 |
| `hr_operating_units` | 992 |
| `FND_CURRENCIES` | 1001 |
| `hr_all_organization_units` | 1014 |
| `pa_event_types` | 1024 |
| `DUAL` | 1040 |
| `pa_draft_revenues_all` | 1259 |
| `pa_draft_revenue_items` | 1345 |
| `pa_cust_event_rdl_all` | 1399 |
| `pa_distribution_warnings` | 1495 |
| `pa_lookups` | 1525 |
| `de` | 1530 |
| `pa_summary_project_fundings` | 1532 |
| `pa_summary_project_fundings` | 1533 |
| `pa_projects` | 1549 |
| `pa_tasks` | 1557 |
| `gl_interface` | 1566 |
| `gl_interface` | 1567 |
| `gl_interface` | 1845 |
| `gl_interface` | 1846 |
| `pa_projects_all` | 2214 |
| `pa_projects_all` | 2308 |
| `pa_projects_all` | 2354 |
| `pa_projects_all` | 2365 |
| `pa_rule_parameters` | 2427 |
| `pa_rules` | 2441 |
| `pa_rules` | 2460 |
| `pa_class_categories` | 2473 |
| `pa_parameters` | 2491 |
| `pa_class_categories` | 2506 |
| `pa_parameters` | 2525 |
| `pa_segment_value_lookups` | 2556 |
| `pa_cost_dist_overrides` | 2601 |
| `pa_cost_dist_overrides` | 2637 |
| `pa_project_classes` | 2669 |
| `pa_tasks` | 2695 |
| `pa.pa_tasks` | 2697 |
| `pa_projects` | 2741 |
| `pa_tasks` | 2751 |
| `pa_periods_all` | 2806 |
| `pa_periods_all` | 2821 |
| `pa_periods_all` | 2823 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_PROFILE.VALUE` | 39 |
| `FND_PROFILE.VALUE` | 40 |
| `Fnd_Profile.value` | 41 |
| `Fnd_Date.canonical_to_date` | 215 |
| `dka_tools_pkg.put_debug_message` | 436 |
| `dka_tools_pkg.put_debug_message` | 439 |
| `Dka_Tools_Pkg.put_debug_message` | 657 |
| `Dka_Tools_Pkg.get_parameter` | 665 |
| `Dka_Tools_Pkg.get_parameter` | 674 |
| `Dka_Tools_Pkg.get_parameter` | 683 |
| `Dka_Tools_Pkg.put_debug_message` | 705 |
| `Dka_Tools_Pkg.put_debug_message` | 735 |
| `Dka_Tools_Pkg.put_debug_message` | 739 |
| `Dka_Tools_Pkg.put_debug_message` | 962 |
| `Dka_Tools_Pkg.put_debug_message` | 982 |
| `Dka_Tools_Pkg.put_debug_message` | 1050 |
| `Dka_Tools_Pkg.put_debug_message` | 1052 |
| `Dka_Tools_Pkg.put_debug_message` | 1087 |
| `Dka_Tools_Pkg.get_code_combination_id` | 1114 |
| `Dka_Tools_Pkg.put_debug_message` | 1137 |
| `Dka_Tools_Pkg.put_debug_message` | 1153 |
| `Dka_Tools_Pkg.put_debug_message` | 1161 |
| `Dka_Tools_Pkg.put_debug_message` | 1195 |
| `Dka_Tools_Pkg.get_code_combination_id` | 1222 |
| `Dka_Tools_Pkg.put_debug_message` | 1245 |
| `Dka_Tools_Pkg.put_debug_message` | 1252 |
| `Dka_Tools_Pkg.put_debug_message` | 1342 |
| `Dka_Tools_Pkg.put_debug_message` | 1396 |
| `Dka_Tools_Pkg.put_debug_message` | 1492 |
| `Dka_Tools_Pkg.put_debug_message` | 1530 |
| `Dka_Tools_Pkg.put_debug_message` | 1544 |
| `Dka_Tools_Pkg.get_parameter` | 2276 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 230, 548, 2130, 2229, 2317, 2375, 2573, 2610, 2646, 2675, 2702, 2766, 2839 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
