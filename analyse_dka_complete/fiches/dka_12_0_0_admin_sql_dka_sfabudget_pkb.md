# DKA_SFABUDGET.pkb

Source : [dka/12.0.0/admin/sql/DKA_SFABUDGET.pkb](../../dka/12.0.0/admin/sql/DKA_SFABUDGET.pkb).

Famille proposée par convention de nommage : **FA / immobilisations**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 4757 ; encodage : cp1252 (repli). SHA-256 : `c543f6618dcc180e8861dbfd205dfcaadb89bac97db420a3a640d085b8872351`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `DKA_DEL_SFABUDGET_WORK` | 117 |
| `DKA_BOOK_PERIODS_CTR` | 149 |
| `DKA_BOOK_MAIN_CTR` | 202 |
| `DKA_MAIN_CTR` | 230 |
| `DKA_WAIT_FAGDA` | 265 |
| `DKA_SUBMIT_FAGDA` | 307 |
| `DKA_CTR_ALL_CCID` | 366 |
| `DKA_MAIN_FAGDA` | 424 |
| `DKA_WAIT_FAPROJ` | 531 |
| `DKA_SUBMIT_FAPROJ` | 585 |
| `DKA_FIRST_PERIODE` | 657 |
| `DKA_FIRST_PERIODE_NEW` | 689 |
| `DKA_MAIN_FAPROJ` | 722 |
| `DKA_INS_TRAITEMENT` | 799 |
| `DKA_INS_COMPL_AMORTIES` | 1113 |
| `DKA_GET_APPARTENANCE` | 1304 |
| `DKA_GET_CENTRE` | 1336 |
| `DKA_UPDATE_DATA` | 1491 |
| `DKA_UPDATE_IFRS_DATA` | 2137 |
| `DKA_AMORT_REEL` | 2483 |
| `DKA_INS_IMM_EXCEP` | 2604 |
| `DKA_MAIN_COPY_DATA` | 2813 |
| `DKA_MAIN_GEN_DATA` | 2993 |
| `DKA_REQUEST_DROP_TABLE` | 3072 |
| `DKA_MAIN_DROP_TABLE` | 3102 |
| `p_validate` | 3130 |
| `p_extr_data_hyperion` | 3155 |
| `p_extr_data_hyperion` | 3409 |
| `p_extr_data_hyperion_REG` | 3414 |
| `p_extr_data_hyperion_REG` | 3654 |
| `SEND_MSG` | 3669 |
| `p_extr_data_justif` | 3798 |
| `p_extract_data_cmd` | 3945 |
| `p_extr_data_justif_REG` | 3960 |
| `p_extract_data_cmd` | 4109 |
| `EDIT_REG_JUSTIF` | 4122 |
| `EDIT_REG_HYP` | 4165 |
| `DKA_UPDATE_NULL_DATA` | 4219 |
| `main` | 4354 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `Fa_Book_Controls` | 68 |
| `Fa_Calendar_Types` | 159 |
| `Fa_Books` | 377 |
| `Fa_Distribution_Accounts` | 392 |
| `Fa_Calendar_Periods` | 665 |
| `Fa_Calendar_Periods` | 698 |
| `FA_PROJ_INTERIM_REP` | 871 |
| `FA_PROJ_INTERIM_REP` | 903 |
| `FA_PROJ_INTERIM_REP` | 939 |
| `FND_FLEX_VALUE_SETS` | 973 |
| `DKA_SFABUDGET_WORK` | 980 |
| `DKA_SFABUDGET_WORK` | 1041 |
| `FA_ADDITIONS` | 1144 |
| `FA_PROJ_INTERIM_REP` | 1154 |
| `DKA_SFABUDGET_WORK` | 1172 |
| `DKA_SFABUDGET_WORK` | 1235 |
| `HR_ALL_ORGANIZATION_UNITS` | 1313 |
| `pa_projects_all` | 1316 |
| `per_org_structure_versions` | 1347 |
| `per_organization_structures` | 1350 |
| `hr_all_organization_units` | 1369 |
| `Dka_SFaBudget_Work` | 1521 |
| `OF` | 1551 |
| `DKA_SFABUDGET_WORK` | 1570 |
| `Dka_SFaBudget_Work` | 1620 |
| `OF` | 1647 |
| `FA_ADDITIONS` | 1681 |
| `pa_projects_all` | 1731 |
| `FND_FLEX_VALUE_SETS` | 1759 |
| `Dka_SFABUDGET_Work` | 1772 |
| `Fa_retirements` | 1803 |
| `fa_retirements` | 1820 |
| `fa_retirements` | 1832 |
| `fa_adjustments` | 1854 |
| `fa_retirements` | 1873 |
| `Dka_SFABUDGET_Work` | 1883 |
| `Dka_SFABUDGET_Work` | 1891 |
| `fa_adjustments` | 1901 |
| `FA_ADDITIONS` | 1919 |
| `fa_retirements` | 1939 |
| `Dka_SFABUDGET_Work` | 1948 |
| `Dka_SFABUDGET_Work` | 1953 |
| `Dka_SFABUDGET_Work` | 1957 |
| `Dka_SFABUDGET_Work` | 1962 |
| `Dka_SFABUDGET_Work` | 1966 |
| `FA_ADDITIONS` | 1994 |
| `Dka_SFABUDGET_Work` | 2011 |
| `Dka_SFABUDGET_Work` | 2021 |
| `fa_adjustments` | 2052 |
| `Dka_SFABUDGET_Work` | 2066 |
| `fa_retirements` | 2073 |
| `Dka_SFABUDGET_Work` | 2083 |
| `Dka_SFABUDGET_Work` | 2106 |
| `Dka_SFaBudget_Work` | 2167 |
| `Fa_Distribution_History` | 2180 |
| `OF` | 2183 |
| `FA_ADDITIONS` | 2211 |
| `FND_FLEX_VALUE_SETS` | 2286 |
| `Dka_SFABUDGET_Work` | 2299 |
| `Dka_SFABUDGET_Work` | 2321 |
| `Fa_retirements` | 2327 |
| `fa_retirements` | 2344 |
| `fa_retirements` | 2356 |
| `fa_adjustments` | 2378 |
| `fa_retirements` | 2397 |
| `Dka_SFABUDGET_Work` | 2407 |
| `Dka_SFABUDGET_Work` | 2415 |
| `fa_adjustments` | 2425 |
| `Dka_SFABUDGET_Work` | 2439 |
| `Dka_SFABUDGET_Work` | 2443 |
| `DKA_SFABUDGET_WORK` | 2496 |
| `fa_deprn_periods` | 2532 |
| `fa_deprn_summary` | 2547 |
| `fa_deprn_summary` | 2565 |
| `DKA_SFABUDGET_WORK` | 2570 |
| `fa_additions_b` | 2621 |
| `Dka_Sfabudget_Work` | 2652 |
| `FA_DEPRN_PERIODS` | 2673 |
| `FA_DEPRN_SUMMARY` | 2688 |
| `DKA_SFABUDGET_WORK` | 2703 |
| `dual` | 2826 |
| `DKA_SFABUDGET_WORK` | 2899 |
| `DKA_STRANSCO_LINES` | 2903 |
| `DKA_STRANSCO_HEADERS` | 2906 |
| `FA_ADDITIONS` | 2910 |
| `DKA_SFABUDGET_WORK` | 2958 |
| `DKA_SFABUDGET_WORK` | 2960 |
| `Dka_SFaBudget_Work` | 3032 |
| `DKA_SFABUDGET_WORK` | 3212 |
| `DKA_SFABUDGET_WORK` | 3232 |
| `DKA_SFABUDGET_WORK` | 3473 |
| `DKA_SFABUDGET_WORK` | 3494 |
| `DKA_SFABUDGET_WORK` | 3862 |
| `DKA_SFABUDGET_WORK` | 4026 |
| `DKA_SFABUDGET_WORK` | 4140 |
| `fnd_concurrent_requests` | 4157 |
| `fnd_user` | 4159 |
| `DKA_SFABUDGET_WORK` | 4183 |
| `fnd_concurrent_requests` | 4200 |
| `fnd_user` | 4202 |
| `DKA_SFABUDGET_WORK` | 4223 |
| `FA_ADDITIONS` | 4244 |
| `pa_projects_all` | 4261 |
| `DKA_SFABUDGET_WORK` | 4270 |
| `pa_projects_all` | 4279 |
| `DKA_SFABUDGET_WORK` | 4288 |
| `pa_projects_all` | 4297 |
| `DKA_SFABUDGET_WORK` | 4306 |
| `FA_ADDITIONS` | 4315 |
| `DKA_SFABUDGET_WORK` | 4335 |
| `DKA_SFABUDGET_WORK` | 4383 |
| `fnd_flex_values_tl` | 4388 |
| `dual` | 4407 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 124 |
| `dka_tools_pkg.put_outdebug_message` | 168 |
| `dka_tools_pkg.put_outdebug_message` | 170 |
| `dka_tools_pkg.put_outdebug_message` | 171 |
| `dka_tools_pkg.put_outdebug_message` | 174 |
| `dka_tools_pkg.put_outdebug_message` | 177 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 278 |
| `Fnd_Request.Submit_Request` | 314 |
| `dka_tools_pkg.put_outdebug_message` | 334 |
| `dka_tools_pkg.put_outdebug_message` | 335 |
| `dka_tools_pkg.put_log_message` | 340 |
| `dka_tools_pkg.put_log_message` | 429 |
| `dka_tools_pkg.put_log_message` | 430 |
| `dka_tools_pkg.put_log_message` | 431 |
| `dka_tools_pkg.put_log_message` | 447 |
| `dka_tools_pkg.put_log_message` | 449 |
| `dka_tools_pkg.put_log_message` | 450 |
| `dka_tools_pkg.put_log_message` | 481 |
| `dka_tools_pkg.put_log_message` | 482 |
| `dka_tools_pkg.put_log_message` | 483 |
| `dka_tools_pkg.put_log_message` | 484 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 544 |
| `dka_tools_pkg.put_outdebug_message` | 555 |
| `Fnd_Request.Submit_Request` | 595 |
| `dka_tools_pkg.put_outdebug_message` | 624 |
| `dka_tools_pkg.put_outdebug_message` | 625 |
| `dka_tools_pkg.put_log_message` | 630 |
| `dka_tools_pkg.put_log_message` | 729 |
| `dka_tools_pkg.put_log_message` | 730 |
| `dka_tools_pkg.put_log_message` | 731 |
| `dka_tools_pkg.put_log_message` | 770 |
| `dka_tools_pkg.put_log_message` | 771 |
| `dka_tools_pkg.put_log_message` | 772 |
| `fnd_profile.VALUE` | 1353 |
| `dka_tools_pkg.put_outdebug_message` | 1708 |
| `dka_tools_pkg.put_outdebug_message` | 1710 |
| `dka_tools_pkg.put_outdebug_message` | 1711 |
| `dka_tools_pkg.put_outdebug_message` | 1712 |
| `dka_tools_pkg.put_outdebug_message` | 1714 |
| `dka_tools_pkg.put_outdebug_message` | 1974 |
| `dka_tools_pkg.put_outdebug_message` | 1976 |
| `dka_tools_pkg.put_outdebug_message` | 1977 |
| `dka_tools_pkg.put_outdebug_message` | 1978 |
| `dka_tools_pkg.put_outdebug_message` | 2091 |
| `dka_tools_pkg.put_outdebug_message` | 2093 |
| `dka_tools_pkg.put_outdebug_message` | 2094 |
| `dka_tools_pkg.put_outdebug_message` | 2095 |
| `dka_tools_pkg.put_outdebug_message` | 2451 |
| `dka_tools_pkg.put_outdebug_message` | 2453 |
| `dka_tools_pkg.put_outdebug_message` | 2454 |
| `dka_tools_pkg.put_outdebug_message` | 2455 |
| `dka_tools_pkg.put_log_message` | 2507 |
| `dka_tools_pkg.put_log_message` | 2583 |
| `dka_tools_pkg.put_log_message` | 2657 |
| `dka_tools_pkg.put_log_message` | 2791 |
| `dka_tools_pkg.put_log_message` | 2819 |
| `dka_tools_pkg.put_log_message` | 2820 |
| `dka_tools_pkg.put_log_message` | 2821 |
| `dka_tools_pkg.put_log_message` | 2822 |
| `dka_tools_pkg.put_log_message` | 2850 |
| `dka_tools_pkg.put_log_message` | 2851 |
| `dka_tools_pkg.put_log_message` | 2852 |
| `dka_tools_pkg.put_log_message` | 2863 |
| `dka_tools_pkg.put_log_message` | 2864 |
| `dka_tools_pkg.put_log_message` | 2865 |
| `dka_tools_pkg.put_log_message` | 2886 |
| `dka_tools_pkg.put_log_message` | 2887 |
| `dka_tools_pkg.put_log_message` | 2888 |
| `dka_tools_pkg.put_log_message` | 2972 |
| `dka_tools_pkg.put_log_message` | 3040 |
| `dka_tools_pkg.put_outdebug_message` | 3042 |
| `dka_tools_pkg.put_log_message` | 3048 |
| `dka_tools_pkg.put_log_message` | 3049 |
| `dka_tools_pkg.put_log_message` | 3079 |
| `dka_tools_pkg.put_log_message` | 3136 |
| `dka_tools_pkg.put_log_message` | 3247 |
| `dka_tools_pkg.put_log_message` | 3379 |
| `Fnd_Request.submit_request` | 3389 |
| `dka_tools_pkg.put_log_message` | 3400 |
| `dka_tools_pkg.put_log_message` | 3403 |
| `dka_tools_pkg.put_log_message` | 3509 |
| `dka_tools_pkg.put_log_message` | 3623 |
| `Fnd_Request.submit_request` | 3634 |
| `dka_tools_pkg.put_log_message` | 3645 |
| `dka_tools_pkg.put_log_message` | 3648 |
| `dka_tools_pkg.put_log_message` | 3875 |
| `dka_tools_pkg.put_log_message` | 3905 |
| `Fnd_File.PUT_LINE` | 3926 |
| `dka_tools_pkg.put_log_message` | 3936 |
| `dka_tools_pkg.put_log_message` | 3939 |
| `dka_tools_pkg.put_log_message` | 4040 |
| `dka_tools_pkg.put_log_message` | 4070 |
| `dka_tools_pkg.put_log_message` | 4089 |
| `dka_tools_pkg.put_log_message` | 4092 |
| `Fnd_Request.submit_request` | 4095 |
| `Fnd_File.PUT_LINE` | 4149 |
| `Fnd_File.PUT_LINE` | 4192 |
| `dka_tools_pkg.put_log_message` | 4233 |
| `dka_tools_pkg.put_log_message` | 4234 |
| `dka_tools_pkg.put_log_message` | 4235 |
| `dka_tools_pkg.put_log_message` | 4236 |
| `dka_tools_pkg.put_log_message` | 4238 |
| `dka_tools_pkg.put_log_message` | 4412 |
| `dka_tools_pkg.put_log_message` | 4413 |
| `dka_tools_pkg.put_log_message` | 4414 |
| `dka_tools_pkg.put_log_message` | 4423 |
| `dka_tools_pkg.put_log_message` | 4424 |
| `dka_tools_pkg.put_log_message` | 4425 |
| `dka_tools_pkg.put_outdebug_message` | 4437 |
| `dka_tools_pkg.put_outdebug_message` | 4438 |
| `dka_tools_pkg.put_outdebug_message` | 4439 |
| `dka_tools_pkg.put_outdebug_message` | 4440 |
| `dka_tools_pkg.put_log_message` | 4445 |
| `dka_tools_pkg.put_log_message` | 4446 |
| `dka_tools_pkg.put_log_message` | 4447 |
| `dka_tools_pkg.put_outdebug_message` | 4460 |
| `dka_tools_pkg.put_outdebug_message` | 4461 |
| `dka_tools_pkg.put_outdebug_message` | 4462 |
| `dka_tools_pkg.put_outdebug_message` | 4463 |
| `dka_tools_pkg.put_log_message` | 4468 |
| `dka_tools_pkg.put_log_message` | 4469 |
| `dka_tools_pkg.put_log_message` | 4470 |
| `dka_tools_pkg.put_outdebug_message` | 4483 |
| `dka_tools_pkg.put_outdebug_message` | 4484 |
| `dka_tools_pkg.put_outdebug_message` | 4485 |
| `dka_tools_pkg.put_outdebug_message` | 4486 |
| `dka_tools_pkg.put_log_message` | 4491 |
| `dka_tools_pkg.put_log_message` | 4492 |
| `dka_tools_pkg.put_log_message` | 4493 |
| `dka_tools_pkg.put_log_message` | 4494 |
| `dka_tools_pkg.put_outdebug_message` | 4506 |
| `dka_tools_pkg.put_outdebug_message` | 4507 |
| `dka_tools_pkg.put_outdebug_message` | 4508 |
| `dka_tools_pkg.put_outdebug_message` | 4509 |
| `dka_tools_pkg.put_log_message` | 4523 |
| `dka_tools_pkg.put_log_message` | 4524 |
| `dka_tools_pkg.put_log_message` | 4525 |
| `Fnd_File.put_line` | 4549 |
| `Fnd_Concurrent.wait_for_request` | 4553 |
| `Fnd_file.put_line` | 4562 |
| `Fnd_File.put_line` | 4569 |
| `Fnd_File.put_line` | 4572 |
| `Fnd_File.put_line` | 4577 |
| `Fnd_File.put_line` | 4580 |
| `fnd_file.put_line` | 4589 |
| `Fnd_File.put_line` | 4594 |
| `Fnd_File.put_line` | 4622 |
| `Fnd_Concurrent.wait_for_request` | 4626 |
| `Fnd_file.put_line` | 4635 |
| `Fnd_File.put_line` | 4642 |
| `Fnd_File.put_line` | 4645 |
| `Fnd_File.put_line` | 4650 |
| `Fnd_File.put_line` | 4653 |
| `fnd_file.put_line` | 4662 |
| `Fnd_File.put_line` | 4667 |
| `Dka_Tools_Pkg.get_parameter` | 4674 |
| `Dka_Tools_Pkg.get_parameter` | 4681 |
| `dka_tools_pkg.put_outdebug_message` | 4726 |
| `dka_tools_pkg.put_outdebug_message` | 4727 |
| `dka_tools_pkg.put_outdebug_message` | 4728 |
| `dka_tools_pkg.put_outdebug_message` | 4729 |
| `dka_tools_pkg.put_outdebug_message` | 4743 |
| `dka_tools_pkg.put_outdebug_message` | 4744 |
| `dka_tools_pkg.put_outdebug_message` | 4745 |
| `dka_tools_pkg.put_outdebug_message` | 4746 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `FAGDA` | 314 |
| `FAPROJ` | 595 |
| `DKA_SFABUDGET_REG_HYP` | 3389 |
| `DKA_SFABUDGET_REG_HYP` | 3634 |
| `DKA_SFABUDGET_REG_JUST` | 4095 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 329, 619, 1087, 1278, 1283, 1988, 3397, 3642, 4104, 4716 |
| rollback | 4720, 4735 |
| when_others | 128, 183, 213, 248, 289, 348, 407, 514, 565, 639, 670, 705, 778, 1091, 1285, 1320, 1395, 1692, 1737, 1910, 1931, 1972, 2005, 2015, 2061, 2089, 2131, 2222, 2434, 2449, 2466, 2543, 2578, 2586, 2794, 2968, 2975, 3052, 3085, 3115, 3378, 3407, 3622, 3652, 3762, 3904, 3928, 3943, 4069, 4107, 4151, 4194, 4255, 4266, 4285, 4303, 4332, 4734 |
| soumission | 314, 595, 3389, 3634, 4095 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
