# DKA_SPOCHARGE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOCHARGE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOCHARGE_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2303 ; encodage : cp1252 (repli). SHA-256 : `4ad98b9906fa909a6ca8a1c44a403335491deed614594bbee465dd6812197f59`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Create_PerEndAccruals` | 136 |
| `update_gl` | 1102 |
| `init` | 1227 |
| `run_prog_standard` | 1415 |
| `run_prog_comptabilisation` | 1791 |
| `main` | 2132 |
| `update_gl` | 2273 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `gl_ledgers` | 283 |
| `po_distributions` | 284 |
| `rcv_transactions` | 337 |
| `DKA_CST_PER_END_ACCRUALS_TEMP` | 523 |
| `DKA_CST_PER_END_ACCRUALS_TEMP` | 602 |
| `dka_cst_per_end_accruals_temp` | 605 |
| `DKA_CST_PER_END_ACCRUALS_TEMP` | 613 |
| `gl_period_statuses` | 673 |
| `gl_period_statuses` | 675 |
| `gl_code_combinations_kfv` | 703 |
| `gl_code_combinations_kfv` | 834 |
| `po_distributions` | 978 |
| `po_distributions` | 998 |
| `po_distributions` | 1006 |
| `dka_spocharge_errors` | 1011 |
| `po_headers_all` | 1117 |
| `fa_categories_vl` | 1154 |
| `fa_book_controls_sec` | 1156 |
| `gl_period_statuses` | 1171 |
| `gl_period_statuses` | 1173 |
| `gl_je_lines` | 1187 |
| `DKA.dka_spocharge_errors` | 1256 |
| `dka_spocharge_errors` | 1264 |
| `hr_operating_units` | 1449 |
| `gl_ledgers` | 1470 |
| `financials_system_parameters` | 1475 |
| `gl_period_statuses` | 1507 |
| `fnd_responsibility` | 1573 |
| `gl_period_statuses` | 1616 |
| `hr_organization_information` | 1633 |
| `DKA_CST_PER_END_ACCRUALS_TEMP` | 1826 |
| `fnd_responsibility` | 1847 |
| `fnd_application_vl` | 1870 |
| `fnd_application_vl` | 1876 |
| `xla_event_class_grps_vl` | 1882 |
| `xla_lookups` | 1889 |
| `xla_lookups` | 1896 |
| `xla_lookups` | 1906 |
| `gl_je_batches` | 1927 |
| `gl_period_statuses` | 1947 |
| `gl_period_statuses` | 1950 |
| `fnd_concurrent_requests` | 2086 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `FND_LOG.TEST` | 186 |
| `fnd_profile.value` | 195 |
| `DKA_SPAAUTOACCOUNTING_PKG.centrefi` | 280 |
| `DKA_SPAAUTOACCOUNTING_PKG.affaire` | 281 |
| `FND_API.Compatible_API_Call` | 393 |
| `FND_API.to_Boolean` | 401 |
| `po_tax_sv.get_tax` | 430 |
| `dka_tools_pkg.get_code_combination_id` | 706 |
| `dka_tools_pkg.get_code_combination_id` | 837 |
| `Dka_Tools_Pkg.put_log_message` | 996 |
| `Dka_Tools_Pkg.put_debug_message` | 1004 |
| `FND_LOG.STRING` | 1041 |
| `FND_MSG_PUB.Count_And_Get` | 1047 |
| `FND_API.To_Boolean` | 1050 |
| `FND_LOG.STRING` | 1061 |
| `FND_MSG_PUB.Count_And_Get` | 1066 |
| `FND_LOG.STRING` | 1075 |
| `FND_MSG_PUB.Check_Msg_Level` | 1080 |
| `FND_MSG_PUB.Add_Exc_Msg` | 1081 |
| `FND_MSG_PUB.Count_And_Get` | 1087 |
| `Dka_Tools_Pkg.put_debug_message` | 1167 |
| `Dka_Tools_Pkg.put_log_message` | 1179 |
| `Dka_Tools_Pkg.put_debug_message` | 1183 |
| `Dka_Tools_Pkg.put_log_message` | 1204 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1210 |
| `Dka_Tools_Pkg.put_debug_message` | 1211 |
| `Dka_Tools_Pkg.put_log_message` | 1255 |
| `Dka_Tools_Pkg.get_parameter` | 1373 |
| `Dka_Tools_Pkg.put_debug_message` | 1382 |
| `Dka_Tools_Pkg.put_debug_message` | 1386 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1394 |
| `Dka_Tools_Pkg.put_log_message` | 1395 |
| `fnd_profile.VALUE` | 1474 |
| `Dka_Tools_Pkg.put_log_message` | 1482 |
| `Dka_Tools_Pkg.put_log_message` | 1501 |
| `Dka_Tools_Pkg.put_log_message` | 1540 |
| `Dka_Tools_Pkg.put_log_message` | 1563 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1584 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1594 |
| `Fnd_Global.apps_initialize` | 1599 |
| `Fnd_Request.set_org_id` | 1603 |
| `Fnd_Request.submit_request` | 1672 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1688 |
| `Dka_Tools_Pkg.put_log_message` | 1697 |
| `Dka_Tools_Pkg.put_log_message` | 1715 |
| `Dka_Tools_Pkg.put_log_message` | 1717 |
| `Dka_Tools_Pkg.put_log_message` | 1722 |
| `Fnd_Concurrent.wait_for_request` | 1728 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1737 |
| `Dka_Tools_Pkg.put_debug_message` | 1743 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1747 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1763 |
| `Dka_Tools_Pkg.put_log_message` | 1766 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1771 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1776 |
| `Dka_Tools_Pkg.put_log_message` | 1831 |
| `Dka_Tools_Pkg.put_log_message` | 1855 |
| `Fnd_Global.apps_initialize` | 1860 |
| `Fnd_Request.set_org_id` | 1864 |
| `FND_REQUEST.set_options` | 1960 |
| `FND_REQUEST.add_layout` | 1967 |
| `Fnd_Request.submit_request` | 1975 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2033 |
| `Dka_Tools_Pkg.put_log_message` | 2037 |
| `Fnd_Concurrent.wait_for_request` | 2056 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2065 |
| `Dka_Tools_Pkg.put_debug_message` | 2071 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2075 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2102 |
| `Dka_Tools_Pkg.put_log_message` | 2109 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2119 |
| `Dka_Tools_Pkg.put_log_message` | 2145 |
| `Dka_Tools_Pkg.put_log_message` | 2173 |
| `Dka_Tools_Pkg.ins_prog_message` | 2175 |
| `DKA_TOOLS_PKG.put_log_message` | 2188 |
| `DKA_SPODISABLE_CALC_CAP_PKG.desactive_calcul_cap_sstr` | 2189 |
| `Dka_Tools_Pkg.put_log_message` | 2193 |
| `Dka_Tools_Pkg.ins_prog_message` | 2195 |
| `Dka_Spocharge_Pkg.run_prog_standard` | 2208 |
| `Dka_Tools_Pkg.put_log_message` | 2212 |
| `Dka_Spocharge_Pkg.run_prog_comptabilisation` | 2231 |
| `Dka_Tools_Pkg.put_log_message` | 2236 |
| `Dka_Tools_Pkg.put_log_message` | 2243 |
| `Dka_Spocharge_Pkg.update_gl` | 2262 |
| `Dka_Tools_Pkg.put_log_message` | 2267 |
| `Dka_Tools_Pkg.put_log_message` | 2282 |
| `Dka_Tools_Pkg.put_log_message` | 2289 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2294 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `CSTPEACR` | 1672 |
| `CSTCRACCRCV` | 1975 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1051, 1200, 1260, 1709, 2024 |
| rollback | 1057, 1070 |
| when_others | 987, 1069, 1207, 1391, 1532, 1580, 1716, 1772, 1852, 1937, 2115, 2291 |
| suppression | 602, 1264 |
| truncate | 1238 |
| soumission | 1672, 1975 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOCHARGE / DKA | `DKA_SPOCHARGE_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCHARGE_F.prt:477 |
| DKA_SPOCHARGE / DKA | `DKA_SPOCHARGE_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCHARGE_F.prt:477 |
| DKA_SPOCHARGE / DKA | `DKA_SPOCHARGE_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCHARGE_US.prt:477 |
| DKA_SPOCHARGE / DKA | `DKA_SPOCHARGE_PKG.main` | dka/12.0.0/admin/import/DKA_SPOCHARGE_US.prt:477 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
