# DKA_FUSPOIMPCTRSSTR_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_FUSPOIMPCTRSSTR_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2482 ; encodage : cp1252 (repli). SHA-256 : `34c4dfc3ef2a18ff38310992c7e13ef9b61b08f003af472b21e7d109dce334ad`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 87 |
| `output_header` | 187 |
| `Request_parameters` | 238 |
| `output_end` | 327 |
| `Add_Message` | 353 |
| `get_organization_id` | 398 |
| `validate_data` | 454 |
| `import_data` | 1400 |
| `Report_Bilan` | 2030 |
| `set_recovery_mode` | 2133 |
| `main` | 2334 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 150 |
| `fnd_concurrent_programs` | 202 |
| `fnd_concurrent_requests` | 244 |
| `fnd_concurrent_requests` | 274 |
| `fnd_concurrent_requests` | 291 |
| `HR_ORGANIZATION_UNITS` | 412 |
| `HR_ORGANIZATION_UNITS` | 419 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 498 |
| `HR_ORGANIZATION_UNITS` | 503 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 520 |
| `OF` | 525 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 541 |
| `OF` | 544 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 553 |
| `OF` | 556 |
| `PO_DOC_STYLE_HEADERS` | 576 |
| `per_people_f` | 598 |
| `PO_AGENTS_V` | 619 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 651 |
| `HR_LOCATIONS` | 685 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 704 |
| `AP_TERMS` | 725 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 747 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 768 |
| `per_people_f` | 807 |
| `PO_AGENTS_V` | 832 |
| `Po_Vendors` | 853 |
| `ap_suppliers` | 863 |
| `HR_LOCATIONS` | 901 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 920 |
| `AP_TERMS` | 944 |
| `rec_cur_header_histo` | 959 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 966 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 985 |
| `rec_cur_header_histo` | 1007 |
| `PO_HEADERS_ALL` | 1052 |
| `PER_ALL_PEOPLE_F` | 1083 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 1107 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 1120 |
| `HR_ORGANIZATION_UNITS` | 1150 |
| `HR_ORGANIZATION_UNITS` | 1154 |
| `HR_ORGANIZATION_UNITS` | 1161 |
| `PA_PROJECTS_ALL` | 1208 |
| `PA_TASKS` | 1248 |
| `HR_LOCATIONS` | 1278 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 1295 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 1310 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 1339 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 1347 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 1355 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 1409 |
| `HR_ORGANIZATION_UNITS` | 1414 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 1431 |
| `HR_ORGANIZATION_UNITS` | 1437 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 1454 |
| `HR_ORGANIZATION_UNITS` | 1459 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 1477 |
| `HR_ORGANIZATION_UNITS` | 1482 |
| `DUAL` | 1505 |
| `PO_HEADERS_ALL` | 1510 |
| `PO_AGENTS_V` | 1586 |
| `PO_HEADERS_ARCHIVE_ALL` | 1597 |
| `PO_HEADERS_ARCHIVE_ALL` | 1672 |
| `DKA_CONTRAT_SSTR` | 1687 |
| `DKA_CONTRAT_SSTR_ARCHI` | 1758 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 1837 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 1844 |
| `DKA_CONTRAT_SSTR_IMPUT_ARCHI` | 1890 |
| `PO_DISTRIBUTIONS_ALL` | 1929 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 1934 |
| `HR_ORGANIZATION_UNITS` | 1950 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 1968 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 1975 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 1982 |
| `po_headers_all` | 1988 |
| `PO_HEADERS_ALL` | 1991 |
| `po_headers_all` | 1998 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 2049 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 2056 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 2063 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 2070 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 2077 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 2084 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 2143 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 2158 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 2168 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 2182 |
| `HR_ORGANIZATION_UNITS` | 2187 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 2203 |
| `HR_ORGANIZATION_UNITS` | 2208 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 2224 |
| `HR_ORGANIZATION_UNITS` | 2229 |
| `DKA_SPOFUSION_SSTR_HEADERS_TMP` | 2245 |
| `HR_ORGANIZATION_UNITS` | 2250 |
| `DKA_SPOFUSION_SSTR_DETAIL_TMP` | 2266 |
| `HR_ORGANIZATION_UNITS` | 2271 |
| `DKA_SPOFUSION_SSTR_IMPUT_TMP` | 2287 |
| `HR_ORGANIZATION_UNITS` | 2292 |
| `HR_ORGANIZATION_UNITS` | 2357 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 98 |
| `fnd_profile.value` | 114 |
| `Fnd_File.put_line` | 143 |
| `Fnd_File.put_line` | 155 |
| `fnd_file.put_line` | 162 |
| `Fnd_File.put_line` | 215 |
| `Fnd_File.put_line` | 216 |
| `Fnd_File.put_line` | 217 |
| `Fnd_File.put_line` | 218 |
| `Fnd_File.put_line` | 219 |
| `Fnd_File.put_line` | 259 |
| `Fnd_File.put_line` | 260 |
| `Fnd_File.put_line` | 261 |
| `Fnd_File.put_line` | 262 |
| `Fnd_File.put_line` | 279 |
| `Fnd_File.put_line` | 280 |
| `Fnd_File.put_line` | 296 |
| `Fnd_File.put_line` | 297 |
| `Fnd_File.put_line` | 300 |
| `Fnd_File.put_line` | 303 |
| `Fnd_File.put_line` | 304 |
| `Fnd_File.put_line` | 332 |
| `Fnd_File.put_line` | 333 |
| `Fnd_File.put_line` | 334 |
| `Fnd_File.put_line` | 364 |
| `Fnd_File.put_line` | 366 |
| `Fnd_File.put_line` | 368 |
| `Fnd_File.put_line` | 370 |
| `Fnd_File.put_line` | 374 |
| `Fnd_File.put_line` | 566 |
| `Fnd_File.put_line` | 567 |
| `Fnd_File.put_line` | 631 |
| `Fnd_File.put_line` | 642 |
| `Fnd_File.put_line` | 678 |
| `Fnd_File.put_line` | 696 |
| `Fnd_File.put_line` | 717 |
| `Fnd_File.put_line` | 739 |
| `Fnd_File.put_line` | 743 |
| `Fnd_File.put_line` | 789 |
| `Fnd_File.put_line` | 802 |
| `Fnd_File.put_line` | 826 |
| `Fnd_File.put_line` | 827 |
| `Fnd_File.put_line` | 846 |
| `Fnd_File.put_line` | 959 |
| `Fnd_File.put_line` | 1007 |
| `dka_tools_pkg.get_code_combination_id` | 1178 |
| `Fnd_File.put_line` | 1367 |
| `Fnd_File.put_line` | 1378 |
| `Fnd_File.put_line` | 1379 |
| `Fnd_File.put_line` | 1500 |
| `Fnd_File.put_line` | 1506 |
| `Fnd_File.put_line` | 1508 |
| `Fnd_File.put_line` | 1590 |
| `Fnd_File.put_line` | 1593 |
| `Fnd_File.put_line` | 1755 |
| `Fnd_File.put_line` | 1839 |
| `Fnd_File.put_line` | 1841 |
| `Fnd_File.put_line` | 1886 |
| `Fnd_File.put_line` | 1887 |
| `Fnd_File.put_line` | 1988 |
| `Fnd_File.put_line` | 1998 |
| `Fnd_File.put_line` | 2004 |
| `Fnd_File.put_line` | 2011 |
| `Fnd_File.put_line` | 2012 |
| `Fnd_File.put_line` | 2037 |
| `fnd_file.put_line` | 2090 |
| `fnd_file.put_line` | 2091 |
| `fnd_file.put_line` | 2092 |
| `fnd_file.put_line` | 2094 |
| `fnd_file.put_line` | 2095 |
| `fnd_file.put_line` | 2096 |
| `fnd_file.put_line` | 2098 |
| `fnd_file.put_line` | 2099 |
| `fnd_file.put_line` | 2100 |
| `fnd_file.put_line` | 2102 |
| `fnd_file.put_line` | 2103 |
| `fnd_file.put_line` | 2104 |
| `fnd_file.put_line` | 2105 |
| `fnd_file.put_line` | 2106 |
| `fnd_file.put_line` | 2107 |
| `fnd_file.put_line` | 2109 |
| `Fnd_File.put_line` | 2110 |
| `Fnd_File.put_line` | 2118 |
| `Fnd_File.put_line` | 2119 |
| `Fnd_File.put_line` | 2313 |
| `Fnd_File.put_line` | 2314 |
| `Dka_Tools_Pkg.put_log_message` | 2377 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 2378 |
| `Fnd_File.put_line` | 2382 |
| `Fnd_File.put_line` | 2388 |
| `Fnd_File.put_line` | 2448 |
| `Fnd_File.put_line` | 2449 |
| `Fnd_File.put_line` | 2451 |
| `Fnd_File.put_line` | 2459 |
| `Fnd_File.put_line` | 2460 |
| `Fnd_File.put_line` | 2461 |
| `Fnd_File.put_line` | 2462 |
| `Fnd_File.put_line` | 2467 |
| `Fnd_File.put_line` | 2468 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 2445 |
| when_others | 164, 210, 580, 608, 624, 670, 689, 710, 729, 818, 837, 879, 888, 905, 928, 948, 1058, 1093, 1168, 1214, 1255, 1282, 1374, 2007, 2114, 2309, 2372, 2463 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_FUSPOIMPCTRSSTR / DKA | `DKA_FUSPOIMPCTRSSTR_PKG.main` | dka/12.0.0/admin/import/DKA_FUSPOIMPCTRSSTR.prt:417 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
