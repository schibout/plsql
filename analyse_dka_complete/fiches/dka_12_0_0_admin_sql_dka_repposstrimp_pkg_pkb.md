# DKA_REPPOSSTRIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPPOSSTRIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPPOSSTRIMP_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2439 ; encodage : cp1252 (repli). SHA-256 : `312ef307a238f135625f6dee9ec3e95dee8a87abb87b3d687979f2188a6aa477`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 91 |
| `output_header` | 195 |
| `Request_parameters` | 248 |
| `output_end` | 338 |
| `Add_Message` | 368 |
| `get_organization_id` | 415 |
| `get_segment_categ` | 464 |
| `Launch_Loader` | 515 |
| `validate_data` | 656 |
| `import_data` | 1600 |
| `Report_Bilan` | 2073 |
| `set_recovery_mode` | 2176 |
| `purge_data` | 2235 |
| `main` | 2289 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 156 |
| `fnd_concurrent_programs` | 210 |
| `fnd_concurrent_requests` | 254 |
| `fnd_concurrent_requests` | 285 |
| `fnd_concurrent_requests` | 302 |
| `hr_operating_units` | 429 |
| `dual` | 483 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 576 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 582 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 588 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 594 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 600 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 606 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 701 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 711 |
| `OF` | 714 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 729 |
| `OF` | 731 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 740 |
| `OF` | 742 |
| `PO_DOC_STYLE_HEADERS` | 761 |
| `per_people_f` | 783 |
| `PO_AGENTS_V` | 802 |
| `Po_Vendors` | 844 |
| `HR_LOCATIONS` | 870 |
| `HR_LOCATIONS` | 889 |
| `AP_TERMS` | 909 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 944 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 961 |
| `per_people_f` | 994 |
| `PO_AGENTS_V` | 1013 |
| `Po_Vendors` | 1054 |
| `Po_Vendors` | 1062 |
| `HR_LOCATIONS` | 1119 |
| `HR_LOCATIONS` | 1138 |
| `AP_TERMS` | 1158 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 1197 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 1212 |
| `PO_HEADERS_ALL` | 1247 |
| `PO_HEADERS_ALL` | 1278 |
| `PO_HEADERS_TMP` | 1289 |
| `PER_ALL_PEOPLE_F` | 1325 |
| `PER_PEOPLE_F` | 1334 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 1360 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 1370 |
| `PA_PROJECTS_ALL` | 1406 |
| `PA_TASKS` | 1426 |
| `HR_LOCATIONS` | 1451 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 1506 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 1517 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 1546 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 1552 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 1558 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 1609 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 1619 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 1626 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 1632 |
| `DUAL` | 1646 |
| `PO_HEADERS_ALL` | 1648 |
| `PO_HEADERS_ARCHIVE_ALL` | 1724 |
| `DKA_CONTRAT_SSTR` | 1807 |
| `DKA_CONTRAT_SSTR_ARCHI` | 1876 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 1952 |
| `DKA_CONTRAT_SSTR_IMPUT_ARCHI` | 1991 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 2030 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 2035 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 2040 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 2092 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 2099 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 2106 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 2113 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 2120 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 2127 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 2186 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 2199 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 2206 |
| `DKA_CONTRAT_SSTR_HEADER_TMP` | 2247 |
| `DKA_CONTRAT_SSTR_DETAIL_TMP` | 2253 |
| `DKA_CONTRAT_SSTR_IMPUT_TMP` | 2259 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 104 |
| `fnd_profile.value` | 120 |
| `Fnd_File.put_line` | 149 |
| `Fnd_File.put_line` | 161 |
| `fnd_file.put_line` | 170 |
| `Fnd_File.put_line` | 225 |
| `Fnd_File.put_line` | 226 |
| `Fnd_File.put_line` | 227 |
| `Fnd_File.put_line` | 228 |
| `Fnd_File.put_line` | 229 |
| `Fnd_File.put_line` | 270 |
| `Fnd_File.put_line` | 271 |
| `Fnd_File.put_line` | 272 |
| `Fnd_File.put_line` | 273 |
| `Fnd_File.put_line` | 290 |
| `Fnd_File.put_line` | 291 |
| `Fnd_File.put_line` | 307 |
| `Fnd_File.put_line` | 308 |
| `Fnd_File.put_line` | 311 |
| `Fnd_File.put_line` | 314 |
| `Fnd_File.put_line` | 315 |
| `Fnd_File.put_line` | 347 |
| `Fnd_File.put_line` | 348 |
| `Fnd_File.put_line` | 349 |
| `Fnd_File.put_line` | 379 |
| `Fnd_File.put_line` | 381 |
| `Fnd_File.put_line` | 383 |
| `Fnd_File.put_line` | 385 |
| `Fnd_File.put_line` | 391 |
| `Fnd_File.put_line` | 527 |
| `Fnd_File.put_line` | 528 |
| `fnd_file.put_line` | 531 |
| `fnd_file.put_line` | 532 |
| `fnd_file.put_line` | 533 |
| `fnd_request.set_print_options` | 538 |
| `Fnd_Request.submit_request` | 541 |
| `fnd_file.put_line` | 552 |
| `Fnd_File.put_line` | 555 |
| `Fnd_File.put_line` | 558 |
| `Fnd_File.put_line` | 559 |
| `Fnd_Concurrent.wait_for_request` | 562 |
| `Fnd_file.put_line` | 565 |
| `Fnd_File.put_line` | 571 |
| `Fnd_File.put_line` | 572 |
| `Fnd_File.put_line` | 611 |
| `fnd_file.put_line` | 619 |
| `Fnd_File.put_line` | 622 |
| `Fnd_File.put_line` | 628 |
| `Fnd_File.put_line` | 635 |
| `Fnd_File.put_line` | 636 |
| `Fnd_File.put_line` | 751 |
| `Fnd_File.put_line` | 752 |
| `dka_rep_transco_pkg.get_transco` | 822 |
| `dka_rep_transco_pkg.get_transco` | 929 |
| `dka_rep_transco_pkg.get_transco` | 1032 |
| `dka_rep_transco_pkg.get_transco` | 1178 |
| `dka_rep_transco_pkg.get_transco` | 1397 |
| `dka_rep_transco_pkg.get_transco` | 1469 |
| `dka_rep_transco_pkg.get_cle_transco_f` | 1474 |
| `Fnd_File.put_line` | 1568 |
| `Fnd_File.put_line` | 1579 |
| `Fnd_File.put_line` | 1580 |
| `Fnd_File.put_line` | 1638 |
| `Fnd_File.put_line` | 1639 |
| `Fnd_File.put_line` | 2047 |
| `Fnd_File.put_line` | 2054 |
| `Fnd_File.put_line` | 2055 |
| `Fnd_File.put_line` | 2080 |
| `fnd_file.put_line` | 2132 |
| `fnd_file.put_line` | 2133 |
| `fnd_file.put_line` | 2134 |
| `fnd_file.put_line` | 2136 |
| `fnd_file.put_line` | 2137 |
| `fnd_file.put_line` | 2138 |
| `fnd_file.put_line` | 2140 |
| `fnd_file.put_line` | 2141 |
| `fnd_file.put_line` | 2142 |
| `fnd_file.put_line` | 2144 |
| `fnd_file.put_line` | 2145 |
| `fnd_file.put_line` | 2146 |
| `fnd_file.put_line` | 2147 |
| `fnd_file.put_line` | 2148 |
| `fnd_file.put_line` | 2149 |
| `fnd_file.put_line` | 2151 |
| `Fnd_File.put_line` | 2152 |
| `Fnd_File.put_line` | 2160 |
| `Fnd_File.put_line` | 2161 |
| `Fnd_File.put_line` | 2218 |
| `Fnd_File.put_line` | 2219 |
| `Fnd_File.Put_Line` | 2243 |
| `Fnd_File.Put_Line` | 2250 |
| `Fnd_File.Put_Line` | 2252 |
| `Fnd_File.Put_Line` | 2256 |
| `Fnd_File.Put_Line` | 2258 |
| `Fnd_File.Put_Line` | 2262 |
| `Fnd_File.put_line` | 2270 |
| `Fnd_File.put_line` | 2271 |
| `Fnd_File.put_line` | 2308 |
| `Fnd_File.put_line` | 2314 |
| `Fnd_File.put_line` | 2332 |
| `Fnd_File.put_line` | 2346 |
| `Fnd_File.put_line` | 2411 |
| `Fnd_File.put_line` | 2412 |
| `Fnd_File.put_line` | 2414 |
| `Fnd_File.put_line` | 2422 |
| `Fnd_File.put_line` | 2423 |
| `Fnd_File.put_line` | 2424 |
| `Fnd_File.put_line` | 2425 |
| `Fnd_File.put_line` | 2430 |
| `Fnd_File.put_line` | 2431 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPPOSSTRIMP` | 541 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 557, 2408 |
| rollback | 2 |
| when_others | 172, 218, 492, 631, 765, 791, 807, 854, 874, 893, 913, 1002, 1018, 1072, 1081, 1123, 1142, 1162, 1251, 1283, 1299, 1330, 1344, 1410, 1431, 1455, 1490, 1575, 2050, 2156, 2214, 2266, 2426 |
| suppression | 2247, 2253, 2259 |
| soumission | 541 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPPOSSTRIMP / DKA | `DKA_REPPOSSTRIMP_PKG.main` | dka/12.0.0/admin/import/DKA_REPPOSSTRIMP.prt:480 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
