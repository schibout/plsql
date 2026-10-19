# DKA_REPPAREVENUIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPPAREVENUIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPPAREVENUIMP_PKG.pkb).

Famille proposée par convention de nommage : **PA / projets**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1991 ; encodage : cp1252 (repli). SHA-256 : `508c83b12bd711f1213b11d2c0e78eced7925fa6ea7b3083796c0d0bf58c4054`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 138 |
| `init_environement` | 173 |
| `Launch_Loader` | 220 |
| `control_data` | 315 |
| `Transco_CodeProjet` | 459 |
| `Transco_Unite_Operationnelle` | 509 |
| `insert_event_spec` | 554 |
| `program_import_revenus` | 1347 |
| `Report_Bilan` | 1789 |
| `MAIN` | 1840 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_responsibility_tl` | 182 |
| `DKA_REPPAREVENUIMP_TMP` | 286 |
| `dka_repparevenuimp_tmp` | 324 |
| `dka_repparevenuimp_tmp` | 338 |
| `dka_repparevenuimp_tmp` | 344 |
| `pa_projects_all` | 354 |
| `dka_repparevenuimp_tmp` | 361 |
| `pa_projects_all` | 371 |
| `dka_repparevenuimp_tmp` | 379 |
| `PA_EVENT_TYPES` | 390 |
| `dka_repparevenuimp_tmp` | 396 |
| `pa_projects_all` | 407 |
| `pa_periods_all` | 412 |
| `DKA_REPPAREVENUIMP_TMP` | 420 |
| `dka_repparevenuimp_tmp` | 429 |
| `DKA_REPPAREVENUIMP_TMP` | 467 |
| `DKA_REPPAREVENUIMP_TMP` | 483 |
| `DKA_REPPAREVENUIMP_TMP` | 516 |
| `DKA_REPPAREVENUIMP_TMP` | 528 |
| `fnd_currencies` | 742 |
| `mtl_item_flexfields` | 869 |
| `pa_conversion_types_v` | 889 |
| `pa_conversion_types_v` | 899 |
| `pa_conversion_types_v` | 951 |
| `pa_conversion_types_v` | 961 |
| `pa_conversion_types_v` | 1011 |
| `pa_events` | 1091 |
| `DKA_REPPAREVENUIMP_TMP` | 1393 |
| `PA_PROJECTS_ALL` | 1438 |
| `DKA_REPPAREVENUIMP_TMP` | 1451 |
| `DKA_REPPAREVENUIMP_TMP` | 1472 |
| `DUAL` | 1529 |
| `PA_TASKS` | 1535 |
| `pa_periods` | 1546 |
| `pa_periods` | 1550 |
| `DKA_REPPAREVENUIMP_TMP` | 1729 |
| `DKA_REPPAREVENUIMP_TMP` | 1740 |
| `DKA_REPPAREVENUIMP_TMP` | 1754 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_log_message` | 142 |
| `Dka_Tools_Pkg.put_log_message` | 153 |
| `fnd_global.apps_initialize` | 188 |
| `dka_tools_pkg.put_outdebug_message` | 194 |
| `Dka_Tools_Pkg.put_log_message` | 233 |
| `Dka_Tools_Pkg.put_log_message` | 235 |
| `Dka_Tools_Pkg.put_log_message` | 236 |
| `Fnd_Request.submit_request` | 243 |
| `dka_tools_pkg.put_outdebug_message` | 255 |
| `Dka_Tools_Pkg.put_log_message` | 258 |
| `dka_tools_pkg.put_outdebug_message` | 259 |
| `Fnd_Concurrent.wait_for_request` | 261 |
| `Dka_Tools_Pkg.put_outdebug_message` | 265 |
| `dka_tools_pkg.put_outdebug_message` | 267 |
| `Dka_Tools_Pkg.put_log_message` | 271 |
| `Dka_Tools_Pkg.put_log_message` | 274 |
| `Dka_Tools_Pkg.put_outdebug_message` | 280 |
| `Dka_Tools_Pkg.put_log_message` | 288 |
| `Dka_Tools_Pkg.put_log_message` | 295 |
| `Dka_Tools_Pkg.put_outdebug_message` | 296 |
| `dka_rep_transco_pkg.get_transco` | 332 |
| `dka_tools_pkg.put_debug_message` | 418 |
| `dka_tools_pkg.put_log_message` | 440 |
| `Dka_Tools_Pkg.put_log_message` | 471 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 475 |
| `Dka_Tools_Pkg.put_log_message` | 480 |
| `Dka_Tools_Pkg.put_log_message` | 490 |
| `Dka_Tools_Pkg.put_log_message` | 520 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 521 |
| `Dka_Tools_Pkg.put_log_message` | 535 |
| `PA_MULTI_CURRENCY_BILLING.get_project_defaults` | 712 |
| `PA_MULTI_CURRENCY_BILLING.ROUND_TRANS_CURRENCY_AMT` | 753 |
| `PA_MULTI_CURRENCY_BILLING.ROUND_TRANS_CURRENCY_AMT` | 755 |
| `pa_billing_values.get_dflt_org` | 775 |
| `pa_billing_values.get_dflt_desc` | 786 |
| `pa_billing_validate.valid_proj_task_extn` | 803 |
| `pa_billing_validate.valid_organization` | 807 |
| `pa_billing_values.funding_level` | 818 |
| `pa_billing_seq.next_eventnum` | 847 |
| `pa_billing_validate.valid_organization` | 856 |
| `pa_multi_currency.is_user_rate_type_allowed` | 891 |
| `pa_multi_currency.is_user_rate_type_allowed` | 900 |
| `pa_multi_currency.is_user_rate_type_allowed` | 953 |
| `pa_multi_currency.is_user_rate_type_allowed` | 962 |
| `pa_currency.round_currency_amt` | 1173 |
| `pa_currency.round_currency_amt` | 1174 |
| `pa_currency.round_currency_amt` | 1175 |
| `pa_currency.round_currency_amt` | 1176 |
| `pa_currency.round_currency_amt` | 1177 |
| `pa_currency.round_currency_amt` | 1178 |
| `pa_currency.round_currency_amt` | 1179 |
| `pa_currency.round_currency_amt` | 1180 |
| `pa_currency.round_currency_amt` | 1181 |
| `pa_currency.round_currency_amt` | 1182 |
| `pa_billing_values.get_message` | 1233 |
| `pa_billing_values.get_message` | 1237 |
| `pa_billing_values.get_message` | 1241 |
| `pa_billing_values.get_message` | 1248 |
| `pa_billing_values.get_message` | 1252 |
| `pa_billing_values.get_message` | 1256 |
| `pa_billing_values.get_message` | 1260 |
| `pa_billing_values.get_message` | 1264 |
| `pa_billing_values.get_message` | 1268 |
| `pa_billing_values.get_message` | 1272 |
| `pa_billing_values.get_message` | 1276 |
| `pa_billing_values.get_message` | 1280 |
| `pa_billing_values.get_message` | 1284 |
| `pa_billing_values.get_message` | 1288 |
| `pa_billing_values.get_message` | 1292 |
| `pa_billing_values.get_message` | 1296 |
| `Dka_Tools_Pkg.put_log_message` | 1300 |
| `Dka_Tools_Pkg.put_log_message` | 1403 |
| `dka_tools_pkg.put_outdebug_message` | 1413 |
| `dka_tools_pkg.put_outdebug_message` | 1414 |
| `dka_tools_pkg.put_outdebug_message` | 1415 |
| `dka_tools_pkg.put_outdebug_message` | 1416 |
| `dka_tools_pkg.put_outdebug_message` | 1417 |
| `dka_tools_pkg.put_outdebug_message` | 1418 |
| `dka_tools_pkg.put_debug_message` | 1442 |
| `dka_tools_pkg.put_debug_message` | 1460 |
| `dka_tools_pkg.put_debug_message` | 1468 |
| `PA_INTERFACE_UTILS_PUB.Set_Global_Info` | 1516 |
| `dka_tools_pkg.put_debug_message` | 1531 |
| `dka_tools_pkg.put_debug_message` | 1566 |
| `dka_tools_pkg.get_code_combination_id` | 1569 |
| `dka_tools_pkg.put_debug_message` | 1589 |
| `dka_tools_pkg.get_code_combination_id` | 1592 |
| `dka_tools_pkg.put_debug_message` | 1610 |
| `dka_tools_pkg.put_debug_message` | 1613 |
| `dka_tools_pkg.put_debug_message` | 1614 |
| `dka_tools_pkg.put_debug_message` | 1615 |
| `dka_tools_pkg.put_debug_message` | 1621 |
| `dka_tools_pkg.put_debug_message` | 1622 |
| `dka_tools_pkg.put_debug_message` | 1627 |
| `dka_pa_tools_pkg.pa_insert_event` | 1667 |
| `dka_tools_pkg.put_outdebug_message` | 1751 |
| `Dka_Tools_Pkg.put_log_message` | 1771 |
| `Dka_Tools_Pkg.put_log_message` | 1796 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1804 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1805 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1806 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1807 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1808 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1809 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1810 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1812 |
| `Dka_Tools_Pkg.put_log_message` | 1813 |
| `Dka_Tools_Pkg.put_log_message` | 1820 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1821 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1872 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1873 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1874 |
| `Dka_Tools_Pkg.put_log_message` | 1880 |
| `Dka_Tools_Pkg.put_log_message` | 1895 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1941 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1943 |
| `Dka_Tools_Pkg.put_log_message` | 1947 |
| `Dka_Tools_Pkg.put_log_message` | 1948 |
| `Dka_Tools_Pkg.put_log_message` | 1949 |
| `Dka_Tools_Pkg.put_log_message` | 1950 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1951 |
| `Dka_Tools_Pkg.put_log_message` | 1958 |
| `Dka_Tools_Pkg.put_log_message` | 1959 |
| `Dka_Tools_Pkg.put_log_message` | 1960 |
| `Dka_Tools_Pkg.put_log_message` | 1961 |
| `Dka_Tools_Pkg.put_log_message` | 1962 |
| `Dka_Tools_Pkg.put_log_message` | 1963 |
| `Dka_Tools_Pkg.put_log_message` | 1964 |
| `Dka_Tools_Pkg.put_log_message` | 1965 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1966 |
| `Dka_Tools_Pkg.put_log_message` | 1973 |
| `Dka_Tools_Pkg.put_log_message` | 1974 |
| `Dka_Tools_Pkg.put_log_message` | 1975 |
| `Dka_Tools_Pkg.put_log_message` | 1976 |
| `Dka_Tools_Pkg.put_log_message` | 1977 |
| `Dka_Tools_Pkg.put_log_message` | 1978 |
| `Dka_Tools_Pkg.put_log_message` | 1979 |
| `Dka_Tools_Pkg.put_log_message` | 1980 |
| `Dka_Tools_Pkg.put_log_message` | 1981 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1982 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_REPPAREVENUIMP_LOADER` | 243 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 257, 434, 488, 534, 1690, 1946 |
| rollback | 1688, 1967, 1983 |
| when_others | 291, 437, 748, 1299, 1308, 1816, 1969 |
| soumission | 243 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPPAREVENUIMP / DKA | `DKA_REPPAREVENUIMP_PKG.MAIN` | dka/12.0.0/admin/import/DKA_REPPAREVENUIMP.prt:554 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
