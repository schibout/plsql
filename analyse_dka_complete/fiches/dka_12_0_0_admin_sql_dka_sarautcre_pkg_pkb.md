# DKA_SARAUTCRE_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SARAUTCRE_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SARAUTCRE_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 4098 ; encodage : cp1252 (repli). SHA-256 : `0a018beea9d8ce53c42ad65aa436bd7a02a6754a284c3a3b1028edf0624d90a0`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 61 |
| `output_header` | 139 |
| `Request_parameters` | 189 |
| `GET_RECEIVABLES_TRX_ID` | 275 |
| `output_end` | 334 |
| `CONTROLE_EXISTENCE_COMPTE_UO` | 362 |
| `CONTROLE_EXISTENCE_COMPTE_SOC` | 408 |
| `RECUP_DONNEES_CCID` | 452 |
| `CREATION_COMPTES_UO` | 600 |
| `creation_comptes_soc` | 1117 |
| `verif_existence_seq` | 1629 |
| `affectation_sequence_uo` | 1692 |
| `affectation_sequence_soc` | 2078 |
| `creation_mode_reglt_uo` | 2449 |
| `creation_mode_reglt_soc` | 2733 |
| `creation_types_eve_uo` | 3020 |
| `creation_types_eve_soc` | 3234 |
| `main_sequence` | 3443 |
| `main_reglement` | 3606 |
| `main_comptes` | 3767 |
| `main_evenement` | 3942 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_concurrent_requests` | 102 |
| `fnd_concurrent_programs` | 151 |
| `fnd_concurrent_requests` | 193 |
| `fnd_concurrent_requests` | 224 |
| `fnd_concurrent_requests` | 246 |
| `AR_RECEIVABLES_TRX_ALL` | 287 |
| `dual` | 295 |
| `CE_BANK_ACCOUNTS` | 370 |
| `CE_BANK_ACCOUNTS` | 416 |
| `DKA_STRANSCO_HEADERS` | 470 |
| `HR_ORGANIZATION_UNITS` | 509 |
| `DKA_STRANSCO_HEADERS` | 554 |
| `HZ_PARTIES` | 631 |
| `HZ_PARTIES` | 637 |
| `xle_entity_profiles` | 651 |
| `FND_APPLICATION` | 659 |
| `gl_code_combinations` | 666 |
| `dual` | 711 |
| `ce_bank_accounts` | 716 |
| `HZ_PARTIES` | 1149 |
| `FND_APPLICATION` | 1155 |
| `HZ_PARTIES` | 1162 |
| `xle_entity_profiles` | 1176 |
| `gl_code_combinations` | 1187 |
| `dual` | 1230 |
| `ce_bank_accounts` | 1233 |
| `hr_operating_units` | 1332 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 1643 |
| `GL_SETS_OF_BOOKS` | 1710 |
| `FND_APPLICATION` | 1715 |
| `FND_DOC_SEQUENCE_CATEGORIES` | 1726 |
| `FND_DOCUMENT_SEQUENCES` | 1751 |
| `DUAL` | 1783 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 1788 |
| `DUAL` | 1839 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 1843 |
| `GL_SETS_OF_BOOKS` | 1886 |
| `FND_DOC_SEQUENCE_CATEGORIES` | 1892 |
| `FND_DOCUMENT_SEQUENCES` | 1915 |
| `DUAL` | 1949 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 1953 |
| `DUAL` | 2003 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 2007 |
| `GL_SETS_OF_BOOKS` | 2097 |
| `FND_APPLICATION` | 2102 |
| `FND_DOC_SEQUENCE_CATEGORIES` | 2113 |
| `FND_DOCUMENT_SEQUENCES` | 2138 |
| `DUAL` | 2172 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 2174 |
| `DUAL` | 2226 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 2228 |
| `FND_DOC_SEQUENCE_CATEGORIES` | 2272 |
| `FND_DOCUMENT_SEQUENCES` | 2295 |
| `DUAL` | 2325 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 2329 |
| `DUAL` | 2377 |
| `FND_DOC_SEQUENCE_ASSIGNMENTS` | 2381 |
| `AR_RECEIPT_CLASSES` | 2476 |
| `FND_APPLICATION` | 2481 |
| `DUAL` | 2486 |
| `AR_RECEIPT_METHODS` | 2489 |
| `FND_DOC_SEQUENCE_CATEGORIES` | 2521 |
| `ce_bank_acct_uses` | 2561 |
| `gl_code_combinations` | 2581 |
| `gl_code_combinations` | 2597 |
| `gl_code_combinations` | 2613 |
| `gl_code_combinations` | 2629 |
| `AR_RECEIPT_METHOD_ACCOUNTS_ALL` | 2650 |
| `AR_RECEIPT_CLASSES` | 2761 |
| `FND_APPLICATION` | 2766 |
| `DUAL` | 2771 |
| `AR_RECEIPT_METHODS` | 2774 |
| `FND_DOC_SEQUENCE_CATEGORIES` | 2806 |
| `ce_bank_acct_uses` | 2846 |
| `gl_code_combinations` | 2874 |
| `gl_code_combinations` | 2890 |
| `gl_code_combinations` | 2906 |
| `gl_code_combinations` | 2922 |
| `AR_RECEIPT_METHOD_ACCOUNTS_ALL` | 2937 |
| `hr_operating_units` | 3039 |
| `FND_APPLICATION` | 3044 |
| `GL_CODE_COMBINATIONS` | 3050 |
| `dual` | 3086 |
| `AR_RECEIVABLES_TRX_ALL` | 3095 |
| `AR_RECEIVABLES_TRX_ALL` | 3104 |
| `FND_DOC_SEQUENCE_CATEGORIES` | 3145 |
| `GL_CODE_COMBINATIONS` | 3253 |
| `hr_operating_units` | 3289 |
| `dual` | 3295 |
| `FND_APPLICATION` | 3306 |
| `AR_RECEIVABLES_TRX_ALL` | 3311 |
| `AR_RECEIVABLES_TRX_ALL` | 3318 |
| `FND_DOC_SEQUENCE_CATEGORIES` | 3358 |
| `hr_operating_units` | 3486 |
| `hr_operating_units` | 3493 |
| `hr_operating_units` | 3649 |
| `hr_operating_units` | 3656 |
| `hr_operating_units` | 3813 |
| `hr_operating_units` | 3819 |
| `hr_operating_units` | 3988 |
| `hr_operating_units` | 3995 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.put_log_message` | 73 |
| `fnd_profile.value` | 91 |
| `Dka_Tools_Pkg.put_log_message` | 95 |
| `Dka_Tools_Pkg.put_log_message` | 106 |
| `Dka_Tools_Pkg.put_log_message` | 116 |
| `Fnd_File.put_line` | 163 |
| `Fnd_File.put_line` | 164 |
| `Fnd_File.put_line` | 166 |
| `Fnd_File.put_line` | 168 |
| `Fnd_File.put_line` | 171 |
| `Fnd_File.put_line` | 209 |
| `Fnd_File.put_line` | 210 |
| `Dka_Tools_Pkg.put_log_message` | 211 |
| `Dka_Tools_Pkg.put_log_message` | 212 |
| `Fnd_File.put_line` | 230 |
| `Dka_Tools_Pkg.put_log_message` | 233 |
| `Fnd_File.put_line` | 252 |
| `Dka_Tools_Pkg.put_log_message` | 255 |
| `Fnd_File.put_line` | 260 |
| `Fnd_File.put_line` | 263 |
| `Dka_Tools_Pkg.put_log_message` | 264 |
| `Fnd_File.put_line` | 298 |
| `fnd_file.put_line` | 303 |
| `Fnd_File.put_line` | 308 |
| `fnd_file.put_line` | 311 |
| `Fnd_File.put_line` | 340 |
| `Fnd_File.put_line` | 341 |
| `Fnd_File.put_line` | 344 |
| `fnd_file.put_line` | 375 |
| `Dka_Tools_Pkg.put_log_message` | 383 |
| `Fnd_File.put_line` | 387 |
| `FND_FILE.PUT_LINE` | 420 |
| `Dka_Tools_Pkg.put_log_message` | 427 |
| `Fnd_File.put_line` | 431 |
| `fnd_file.put_line` | 482 |
| `fnd_file.put_line` | 485 |
| `fnd_file.put_line` | 524 |
| `fnd_file.put_line` | 533 |
| `fnd_file.put_line` | 564 |
| `fnd_file.put_line` | 567 |
| `Dka_Tools_Pkg.put_log_message` | 574 |
| `Fnd_File.put_line` | 578 |
| `Dka_Tools_Pkg.put_log_message` | 681 |
| `dka_tools_pkg.get_code_combination_id` | 687 |
| `FND_PROFILE.VALUE` | 768 |
| `FND_PROFILE.VALUE` | 769 |
| `FND_PROFILE.VALUE` | 771 |
| `FND_FILE.PUT_LINE` | 850 |
| `dka_tools_pkg.get_code_combination_id` | 854 |
| `FND_FILE.PUT_LINE` | 877 |
| `FND_FILE.PUT_LINE` | 898 |
| `dka_tools_pkg.get_code_combination_id` | 902 |
| `FND_FILE.PUT_LINE` | 925 |
| `FND_FILE.PUT_LINE` | 945 |
| `dka_tools_pkg.get_code_combination_id` | 948 |
| `FND_FILE.PUT_LINE` | 971 |
| `FND_FILE.PUT_LINE` | 990 |
| `dka_tools_pkg.get_code_combination_id` | 992 |
| `FND_FILE.PUT_LINE` | 1015 |
| `FND_FILE.PUT_LINE` | 1034 |
| `dka_tools_pkg.get_code_combination_id` | 1036 |
| `FND_FILE.PUT_LINE` | 1059 |
| `FND_FILE.PUT_LINE` | 1074 |
| `FND_FILE.PUT_LINE` | 1076 |
| `FND_FILE.PUT_LINE` | 1079 |
| `Dka_Tools_Pkg.put_log_message` | 1090 |
| `Fnd_File.put_line` | 1094 |
| `Dka_Tools_Pkg.put_log_message` | 1202 |
| `dka_tools_pkg.get_code_combination_id` | 1208 |
| `FND_PROFILE.VALUE` | 1285 |
| `FND_PROFILE.VALUE` | 1286 |
| `FND_PROFILE.VALUE` | 1288 |
| `FND_FILE.PUT_LINE` | 1352 |
| `FND_FILE.PUT_LINE` | 1369 |
| `dka_tools_pkg.get_code_combination_id` | 1374 |
| `FND_FILE.PUT_LINE` | 1398 |
| `FND_FILE.PUT_LINE` | 1417 |
| `dka_tools_pkg.get_code_combination_id` | 1419 |
| `FND_FILE.PUT_LINE` | 1442 |
| `FND_FILE.PUT_LINE` | 1461 |
| `dka_tools_pkg.get_code_combination_id` | 1463 |
| `FND_FILE.PUT_LINE` | 1486 |
| `FND_FILE.PUT_LINE` | 1505 |
| `dka_tools_pkg.get_code_combination_id` | 1507 |
| `FND_FILE.PUT_LINE` | 1530 |
| `FND_FILE.PUT_LINE` | 1549 |
| `dka_tools_pkg.get_code_combination_id` | 1551 |
| `FND_FILE.PUT_LINE` | 1574 |
| `FND_FILE.PUT_LINE` | 1588 |
| `FND_FILE.PUT_LINE` | 1590 |
| `FND_FILE.PUT_LINE` | 1593 |
| `Dka_Tools_Pkg.put_log_message` | 1602 |
| `Fnd_File.put_line` | 1606 |
| `Fnd_File.put_line` | 1653 |
| `fnd_File.put_line` | 1654 |
| `Fnd_File.put_line` | 1655 |
| `Dka_Tools_Pkg.put_log_message` | 1663 |
| `Fnd_File.put_line` | 1667 |
| `Dka_Tools_Pkg.put_log_message` | 1733 |
| `Fnd_File.put_line` | 1737 |
| `Dka_Tools_Pkg.put_log_message` | 1756 |
| `Fnd_File.put_line` | 1760 |
| `FND_PROFILE.VALUE` | 1810 |
| `FND_PROFILE.VALUE` | 1812 |
| `FND_PROFILE.VALUE` | 1813 |
| `Fnd_File.put_line` | 1816 |
| `Fnd_File.put_line` | 1817 |
| `FND_PROFILE.VALUE` | 1865 |
| `FND_PROFILE.VALUE` | 1867 |
| `FND_PROFILE.VALUE` | 1868 |
| `Fnd_File.put_line` | 1871 |
| `Fnd_File.put_line` | 1872 |
| `Dka_Tools_Pkg.put_log_message` | 1898 |
| `Fnd_File.put_line` | 1902 |
| `Dka_Tools_Pkg.put_log_message` | 1920 |
| `Fnd_File.put_line` | 1924 |
| `FND_PROFILE.VALUE` | 1975 |
| `FND_PROFILE.VALUE` | 1977 |
| `FND_PROFILE.VALUE` | 1978 |
| `Fnd_File.put_line` | 1981 |
| `Fnd_File.put_line` | 1982 |
| `FND_PROFILE.VALUE` | 2029 |
| `FND_PROFILE.VALUE` | 2031 |
| `FND_PROFILE.VALUE` | 2032 |
| `Fnd_File.put_line` | 2035 |
| `Fnd_File.put_line` | 2036 |
| `Dka_Tools_Pkg.put_log_message` | 2046 |
| `Fnd_File.put_line` | 2050 |
| `Fnd_File.put_line` | 2054 |
| `Dka_Tools_Pkg.put_log_message` | 2119 |
| `Fnd_File.put_line` | 2123 |
| `Dka_Tools_Pkg.put_log_message` | 2143 |
| `Fnd_File.put_line` | 2147 |
| `FND_PROFILE.VALUE` | 2196 |
| `FND_PROFILE.VALUE` | 2198 |
| `FND_PROFILE.VALUE` | 2199 |
| `Fnd_File.put_line` | 2202 |
| `Fnd_File.put_line` | 2203 |
| `FND_PROFILE.VALUE` | 2250 |
| `FND_PROFILE.VALUE` | 2252 |
| `FND_PROFILE.VALUE` | 2253 |
| `Fnd_File.put_line` | 2256 |
| `Fnd_File.put_line` | 2257 |
| `Dka_Tools_Pkg.put_log_message` | 2278 |
| `Fnd_File.put_line` | 2282 |
| `Dka_Tools_Pkg.put_log_message` | 2300 |
| `Fnd_File.put_line` | 2304 |
| `FND_PROFILE.VALUE` | 2351 |
| `FND_PROFILE.VALUE` | 2353 |
| `FND_PROFILE.VALUE` | 2354 |
| `Fnd_File.put_line` | 2357 |
| `Fnd_File.put_line` | 2358 |
| `FND_PROFILE.VALUE` | 2403 |
| `FND_PROFILE.VALUE` | 2405 |
| `FND_PROFILE.VALUE` | 2406 |
| `Fnd_File.put_line` | 2409 |
| `Fnd_File.put_line` | 2410 |
| `Dka_Tools_Pkg.put_log_message` | 2421 |
| `Fnd_File.put_line` | 2425 |
| `Fnd_File.put_line` | 2429 |
| `FND_PROFILE.VALUE` | 2507 |
| `FND_PROFILE.VALUE` | 2509 |
| `FND_PROFILE.VALUE` | 2510 |
| `FND_PROFILE.VALUE` | 2540 |
| `FND_PROFILE.VALUE` | 2542 |
| `FND_PROFILE.VALUE` | 2543 |
| `fnd_file.put_line` | 2575 |
| `fnd_file.put_line` | 2646 |
| `FND_PROFILE.VALUE` | 2676 |
| `FND_PROFILE.VALUE` | 2678 |
| `FND_PROFILE.VALUE` | 2679 |
| `Fnd_File.put_line` | 2690 |
| `Fnd_File.put_line` | 2691 |
| `fnd_file.put_line` | 2695 |
| `Dka_Tools_Pkg.put_log_message` | 2702 |
| `Fnd_File.put_line` | 2706 |
| `Fnd_File.put_line` | 2710 |
| `FND_PROFILE.VALUE` | 2792 |
| `FND_PROFILE.VALUE` | 2794 |
| `FND_PROFILE.VALUE` | 2795 |
| `FND_PROFILE.VALUE` | 2825 |
| `FND_PROFILE.VALUE` | 2827 |
| `FND_PROFILE.VALUE` | 2828 |
| `fnd_file.put_line` | 2861 |
| `fnd_file.put_line` | 2868 |
| `FND_PROFILE.VALUE` | 2963 |
| `FND_PROFILE.VALUE` | 2965 |
| `FND_PROFILE.VALUE` | 2966 |
| `Fnd_File.put_line` | 2977 |
| `Fnd_File.put_line` | 2978 |
| `fnd_file.put_line` | 2982 |
| `Dka_Tools_Pkg.put_log_message` | 2989 |
| `Fnd_File.put_line` | 2993 |
| `Fnd_File.put_line` | 2997 |
| `dka_tools_pkg.get_code_combination_id` | 3064 |
| `FND_PROFILE.VALUE` | 3135 |
| `FND_PROFILE.VALUE` | 3137 |
| `FND_PROFILE.VALUE` | 3138 |
| `FND_PROFILE.VALUE` | 3166 |
| `FND_PROFILE.VALUE` | 3168 |
| `FND_PROFILE.VALUE` | 3169 |
| `Fnd_File.put_line` | 3180 |
| `Fnd_File.put_line` | 3181 |
| `Fnd_File.put_line` | 3182 |
| `Fnd_File.put_line` | 3193 |
| `Fnd_File.put_line` | 3198 |
| `Dka_Tools_Pkg.put_log_message` | 3205 |
| `Fnd_File.put_line` | 3209 |
| `dka_tools_pkg.get_code_combination_id` | 3267 |
| `FND_PROFILE.VALUE` | 3349 |
| `FND_PROFILE.VALUE` | 3351 |
| `FND_PROFILE.VALUE` | 3352 |
| `FND_PROFILE.VALUE` | 3378 |
| `FND_PROFILE.VALUE` | 3380 |
| `FND_PROFILE.VALUE` | 3381 |
| `Fnd_File.put_line` | 3390 |
| `Fnd_File.put_line` | 3391 |
| `Fnd_File.put_line` | 3392 |
| `Fnd_File.put_line` | 3403 |
| `Fnd_File.put_line` | 3408 |
| `Dka_Tools_Pkg.put_log_message` | 3415 |
| `Fnd_File.put_line` | 3419 |
| `Dka_Tools_Pkg.put_log_message` | 3461 |
| `Dka_Tools_Pkg.put_log_message` | 3468 |
| `Dka_Tools_Pkg.put_log_message` | 3499 |
| `Dka_Tools_Pkg.put_log_message` | 3517 |
| `Dka_Tools_Pkg.put_log_message` | 3547 |
| `Fnd_File.put_line` | 3548 |
| `Dka_Tools_Pkg.put_log_message` | 3550 |
| `Dka_Tools_Pkg.put_log_message` | 3559 |
| `Fnd_File.put_line` | 3560 |
| `Dka_Tools_Pkg.put_log_message` | 3561 |
| `Fnd_File.put_line` | 3565 |
| `Fnd_File.put_line` | 3569 |
| `Dka_Tools_Pkg.put_log_message` | 3576 |
| `Fnd_File.put_line` | 3580 |
| `Fnd_File.put_line` | 3584 |
| `Dka_Tools_Pkg.put_log_message` | 3624 |
| `Dka_Tools_Pkg.put_log_message` | 3631 |
| `Dka_Tools_Pkg.put_log_message` | 3662 |
| `Dka_Tools_Pkg.put_log_message` | 3680 |
| `Dka_Tools_Pkg.put_log_message` | 3710 |
| `Fnd_File.put_line` | 3711 |
| `Dka_Tools_Pkg.put_log_message` | 3713 |
| `Dka_Tools_Pkg.put_log_message` | 3722 |
| `Fnd_File.put_line` | 3723 |
| `Dka_Tools_Pkg.put_log_message` | 3724 |
| `Fnd_File.put_line` | 3728 |
| `Fnd_File.put_line` | 3732 |
| `Dka_Tools_Pkg.put_log_message` | 3737 |
| `Fnd_File.put_line` | 3741 |
| `Fnd_File.put_line` | 3746 |
| `Dka_Tools_Pkg.put_log_message` | 3787 |
| `Dka_Tools_Pkg.put_log_message` | 3794 |
| `Dka_Tools_Pkg.put_log_message` | 3825 |
| `Dka_Tools_Pkg.put_log_message` | 3847 |
| `Dka_Tools_Pkg.put_log_message` | 3879 |
| `Fnd_File.put_line` | 3880 |
| `Dka_Tools_Pkg.put_log_message` | 3882 |
| `Dka_Tools_Pkg.put_log_message` | 3891 |
| `Fnd_File.put_line` | 3892 |
| `Dka_Tools_Pkg.put_log_message` | 3893 |
| `Fnd_File.put_line` | 3897 |
| `Fnd_File.put_line` | 3901 |
| `Fnd_File.put_line` | 3904 |
| `Dka_Tools_Pkg.put_log_message` | 3909 |
| `Fnd_File.put_line` | 3913 |
| `Fnd_File.put_line` | 3917 |
| `Fnd_File.put_line` | 3920 |
| `Dka_Tools_Pkg.put_log_message` | 3961 |
| `Dka_Tools_Pkg.put_log_message` | 3968 |
| `Dka_Tools_Pkg.put_log_message` | 4001 |
| `Dka_Tools_Pkg.put_log_message` | 4023 |
| `Dka_Tools_Pkg.put_log_message` | 4054 |
| `Fnd_File.put_line` | 4055 |
| `Dka_Tools_Pkg.put_log_message` | 4057 |
| `Dka_Tools_Pkg.put_log_message` | 4066 |
| `Fnd_File.put_line` | 4067 |
| `Dka_Tools_Pkg.put_log_message` | 4068 |
| `Fnd_File.put_line` | 4072 |
| `Dka_Tools_Pkg.put_log_message` | 4080 |
| `Fnd_File.put_line` | 4084 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 3544, 3707, 3876, 4051 |
| rollback | 2 |
| when_others | 118, 158, 306, 381, 425, 484, 532, 566, 572, 1087, 1599, 1661, 1731, 1754, 1896, 1918, 2043, 2117, 2141, 2276, 2298, 2418, 2573, 2699, 2858, 2986, 3063, 3202, 3266, 3412, 3573, 3734, 3906, 4077 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SARAUTCRE_COMPTE / DKA | `DKA_SARAUTCRE_PKG.MAIN_COMPTES` | dka/12.0.0/admin/import/DKA_SARAUTCRE_COMPTE.ldt:476 |
| DKA_SARAUTCRE_EVENEMENT / DKA | `DKA_SARAUTCRE_PKG.MAIN_EVENEMENT` | dka/12.0.0/admin/import/DKA_SARAUTCRE_EVENEMENT.ldt:476 |
| DKA_SARAUTCRE_REGLEMENT / DKA | `DKA_SARAUTCRE_PKG.MAIN_REGLEMENT` | dka/12.0.0/admin/import/DKA_SARAUTCRE_REGLEMENT.ldt:476 |
| DKA_SARAUTCRE_SEQUENCE / DKA | `DKA_SARAUTCRE_PKG.MAIN_SEQUENCE` | dka/12.0.0/admin/import/DKA_SARAUTCRE_SEQUENCE.ldt:476 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
