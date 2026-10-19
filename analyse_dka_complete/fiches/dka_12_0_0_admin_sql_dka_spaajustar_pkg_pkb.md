# DKA_SPAAJUSTAR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPAAJUSTAR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPAAJUSTAR_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1246 ; encodage : cp1252 (repli). SHA-256 : `d05a94a41e688889c1206215fe0cd75325aff7a6ea9ad009cb6ae252c498380b`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_param_varchar` | 55 |
| `init` | 88 |
| `get_account_info` | 166 |
| `get_contrep_ccid_f` | 208 |
| `get_org_id_f` | 256 |
| `get_burden_cost_f` | 284 |
| `ins_pa_expend_groups` | 336 |
| `ins_pa_expenditures` | 409 |
| `ins_pa_expend_items` | 479 |
| `ins_pa_cost_distrib_lines` | 691 |
| `transfer_from_ar_to_pa` | 835 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_flex_values_vl` | 177 |
| `pa_projects_all` | 265 |
| `pa_expenditure_groups_all` | 349 |
| `pa_expenditure_groups_all` | 357 |
| `DUAL` | 421 |
| `pa_expenditures_all` | 423 |
| `DUAL` | 502 |
| `pa_expenditure_items_all` | 504 |
| `pa_expenditure_comments` | 646 |
| `gl_periods` | 713 |
| `pa_cost_distribution_lines_all` | 721 |
| `ar_adjustments_all` | 881 |
| `ar_adjustments_all` | 922 |
| `gl_period_statuses` | 957 |
| `gl_access_set_assignments` | 961 |
| `gl_period_statuses` | 967 |
| `gl_access_set_assignments` | 972 |
| `AR_CASH_RECEIPTS_all` | 1060 |
| `ar_adjustments_all` | 1160 |
| `ar_adjustments_all` | 1162 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.get_parameter` | 63 |
| `dka_tools_pkg.get_flex_key_seg_value_set` | 100 |
| `dka_tools_pkg.GET_MESSAGE` | 190 |
| `Dka_Tools_Pkg.get_code_combination_id` | 222 |
| `fnd_profile.put` | 301 |
| `pa_cost_plus1.view_indirect_cost` | 307 |
| `fnd_profile.value` | 717 |
| `fnd_profile.value` | 889 |
| `fnd_profile.value` | 930 |
| `Dka_Tools_Pkg.put_outdebug_message` | 949 |
| `Dka_Tools_Pkg.put_log_message` | 950 |
| `Dka_Tools_Pkg.put_outdebug_message` | 951 |
| `Dka_Tools_Pkg.put_log_message` | 952 |
| `FND_PROFILE.value` | 962 |
| `FND_PROFILE.value` | 973 |
| `Dka_Tools_Pkg.put_log_message` | 980 |
| `Dka_Tools_Pkg.put_log_message` | 981 |
| `Dka_Tools_Pkg.put_outdebug_message` | 987 |
| `Dka_Tools_Pkg.put_log_message` | 988 |
| `Dka_Tools_Pkg.put_outdebug_message` | 989 |
| `Dka_Tools_Pkg.put_outdebug_message` | 990 |
| `dka_tools_pkg.put_debug_message` | 1005 |
| `dka_tools_pkg.put_debug_message` | 1007 |
| `Dka_Tools_Pkg.put_log_message` | 1029 |
| `dka_tools_pkg.put_debug_message` | 1032 |
| `dka_tools_pkg.put_debug_message` | 1044 |
| `dka_tools_pkg.put_debug_message` | 1047 |
| `dka_tools_pkg.put_debug_message` | 1067 |
| `dka_tools_pkg.put_debug_message` | 1077 |
| `dka_tools_pkg.put_debug_message` | 1097 |
| `fnd_profile.put` | 1120 |
| `Dka_Tools_Pkg.put_log_message` | 1125 |
| `dka_tools_pkg.put_debug_message` | 1126 |
| `dka_pa_tools_pkg.pa_insert_event` | 1127 |
| `dka_tools_pkg.put_debug_message` | 1160 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1169 |
| `dka_tools_pkg.put_debug_message` | 1178 |
| `Dka_Tools_Pkg.put_log_message` | 1191 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1192 |
| `Dka_Tools_Pkg.put_log_message` | 1204 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1205 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1221 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1222 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1223 |
| `Dka_Tools_Pkg.put_log_message` | 1224 |
| `Dka_Tools_Pkg.put_log_message` | 1225 |
| `Dka_Tools_Pkg.put_log_message` | 1226 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1211 |
| rollback | 1182, 1195, 1234, 1239 |
| when_others | 77, 155, 197, 245, 273, 325, 398, 468, 680, 814, 1193, 1237 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPAAJUSTAR_TRANSFER / DKA | `DKA_SPAAJUSTAR_PKG.transfer_from_ar_to_pa` | dka/12.0.0/admin/import/DKA_SPAAJUSTAR_TRANSFER.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
