# DKA_IAPARGLCTRLFISCAL_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPARGLCTRLFISCAL_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPARGLCTRLFISCAL_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3555 ; encodage : cp1252 (repli). SHA-256 : `e6e1a009acfe257958cc5fe6da02c944525fcc892adc676719bd183f35e69176`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_time` | 118 |
| `translate_texte` | 131 |
| `insert_table_param` | 190 |
| `get_parameters` | 262 |
| `init` | 305 |
| `purge_table_tmp` | 738 |
| `insert_table_fact_ap_tmp` | 787 |
| `insert_table_rglt_ap_tmp` | 980 |
| `insert_table_fact_ar_tmp` | 1136 |
| `insert_table_rglt_ar_tmp` | 1326 |
| `insert_table_adju_ar_tmp` | 1670 |
| `insert_table_autr_gl_tmp` | 1829 |
| `insert_table_report_tmp` | 1985 |
| `insert_table_param` | 2328 |
| `write_output_file` | 2542 |
| `write_param_file` | 2701 |
| `affichage_fichier_sortie` | 2840 |
| `main` | 2897 |
| `writeout` | 3229 |
| `main_auto` | 3248 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `l_texte_transcode` | 152 |
| `dka_param_extract_fiscal` | 212 |
| `dka_param_extract_fiscal` | 222 |
| `gl_period_sets` | 333 |
| `fnd_flex_value_sets` | 347 |
| `fnd_flex_values_vl` | 356 |
| `xle_registrations` | 401 |
| `hr_operating_units` | 409 |
| `fnd_flex_value_sets` | 421 |
| `GL_LEDGER_RELATIONSHIPS` | 468 |
| `gl_ledgers` | 486 |
| `gl_periods` | 490 |
| `gl_periods` | 493 |
| `gl_periods` | 498 |
| `gl_periods` | 501 |
| `gl_periods` | 509 |
| `dual` | 544 |
| `fnd_flex_value_sets` | 695 |
| `fnd_flex_value_sets` | 707 |
| `dka.dka_param_extract_fiscal` | 752 |
| `dka_extract_fiscal` | 755 |
| `dka.dka_extract_fiscal` | 762 |
| `DKA_EXTRACT_FISCAL` | 806 |
| `dka_extract_fiscal` | 808 |
| `ap_checks_all` | 841 |
| `ap_checks_all` | 848 |
| `ap_checks_all` | 863 |
| `ap_invoice_distributions_all` | 869 |
| `gl_je_lines` | 883 |
| `DKA_EXTRACT_FISCAL` | 999 |
| `dka_extract_fiscal` | 1001 |
| `gl_je_lines` | 1040 |
| `DKA_EXTRACT_FISCAL` | 1155 |
| `dka_extract_fiscal` | 1157 |
| `ar_receivable_applications_all` | 1188 |
| `ar_receivable_applications_all` | 1191 |
| `ar_receivable_applications_all` | 1202 |
| `ar_receivable_applications_all` | 1205 |
| `gl_je_lines` | 1219 |
| `ar_payment_schedules_all` | 1272 |
| `DKA_EXTRACT_FISCAL` | 1345 |
| `dka_extract_fiscal` | 1347 |
| `ar_customers` | 1363 |
| `ar_customers` | 1369 |
| `ar_receivable_applications_all` | 1400 |
| `gl_je_lines` | 1418 |
| `DKA_EXTRACT_FISCAL` | 1689 |
| `dka_extract_fiscal` | 1691 |
| `gl_je_lines` | 1727 |
| `DKA_EXTRACT_FISCAL` | 1848 |
| `dka_extract_fiscal` | 1850 |
| `gl_je_lines` | 1881 |
| `DKA_EXTRACT_FISCAL` | 2010 |
| `dka_extract_fiscal` | 2016 |
| `gl_balances` | 2068 |
| `dka_extract_fiscal` | 2108 |
| `gl_balances` | 2160 |
| `dka_extract_fiscal` | 2198 |
| `gl_balances` | 2264 |
| `all_tab_columns` | 2385 |
| `dka_extract_fiscal` | 2413 |
| `dka_extract_fiscal` | 2422 |
| `dka_extract_fiscal` | 2431 |
| `dka_extract_fiscal` | 2441 |
| `dka_param_extract_fiscal` | 2459 |
| `DUAL` | 2486 |
| `dka_extract_fiscal` | 2550 |
| `dka_param_extract_fiscal` | 2709 |
| `DUAL` | 2789 |
| `GL_LEDGER_RELATIONSHIPS` | 3280 |
| `fnd_flex_value_sets` | 3288 |
| `fnd_flex_value_sets` | 3296 |
| `gl_ledgers` | 3307 |
| `fnd_flex_value_sets` | 3310 |
| `fnd_flex_value_sets` | 3318 |
| `GL_LEDGER_RELATIONSHIPS` | 3326 |
| `gl_periods` | 3355 |
| `gl_periods` | 3433 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 176 |
| `dka_tools_pkg.put_log_message` | 179 |
| `dka_tools_pkg.put_log_message` | 248 |
| `dka_tools_pkg.put_log_message` | 251 |
| `dka_tools_pkg.put_log_message` | 290 |
| `dka_tools_pkg.put_log_message` | 293 |
| `dka_tools_pkg.get_parameter` | 382 |
| `dka_tools_pkg.put_debug_message` | 533 |
| `dka_tools_pkg.put_debug_message` | 536 |
| `dka_tools_pkg.put_debug_message` | 599 |
| `dka_tools_pkg.put_debug_message` | 611 |
| `dka_tools_pkg.put_debug_message` | 620 |
| `dka_tools_pkg.put_debug_message` | 631 |
| `dka_tools_pkg.put_log_message` | 723 |
| `dka_tools_pkg.put_log_message` | 726 |
| `dka_tools_pkg.put_log_message` | 772 |
| `dka_tools_pkg.put_log_message` | 775 |
| `dka_tools_pkg.put_log_message` | 807 |
| `dka_tools_pkg.put_log_message` | 949 |
| `dka_tools_pkg.put_log_message` | 965 |
| `dka_tools_pkg.put_log_message` | 968 |
| `dka_tools_pkg.put_log_message` | 1000 |
| `dka_tools_pkg.put_log_message` | 1105 |
| `dka_tools_pkg.put_log_message` | 1121 |
| `dka_tools_pkg.put_log_message` | 1124 |
| `dka_tools_pkg.put_log_message` | 1156 |
| `dka_tools_pkg.put_log_message` | 1295 |
| `dka_tools_pkg.put_log_message` | 1311 |
| `dka_tools_pkg.put_log_message` | 1314 |
| `dka_tools_pkg.put_log_message` | 1346 |
| `dka_tools_pkg.put_log_message` | 1483 |
| `dka_tools_pkg.put_log_message` | 1499 |
| `dka_tools_pkg.put_log_message` | 1502 |
| `dka_tools_pkg.put_log_message` | 1690 |
| `dka_tools_pkg.put_log_message` | 1798 |
| `dka_tools_pkg.put_log_message` | 1814 |
| `dka_tools_pkg.put_log_message` | 1817 |
| `dka_tools_pkg.put_log_message` | 1849 |
| `dka_tools_pkg.put_log_message` | 1954 |
| `dka_tools_pkg.put_log_message` | 1970 |
| `dka_tools_pkg.put_log_message` | 1973 |
| `dka_tools_pkg.put_log_message` | 2012 |
| `dka_tools_pkg.put_log_message` | 2292 |
| `dka_tools_pkg.put_log_message` | 2313 |
| `dka_tools_pkg.put_log_message` | 2316 |
| `dka_tools_pkg.put_log_message` | 2527 |
| `dka_tools_pkg.put_log_message` | 2530 |
| `dka_tools_pkg.put_log_message` | 2643 |
| `dka_tools_pkg.put_log_message` | 2686 |
| `dka_tools_pkg.put_log_message` | 2689 |
| `dka_tools_pkg.put_log_message` | 2813 |
| `dka_tools_pkg.put_log_message` | 2824 |
| `dka_tools_pkg.put_log_message` | 2827 |
| `dka_tools_pkg.put_outdebug_message` | 2857 |
| `dka_tools_pkg.put_outdebug_message` | 2859 |
| `dka_tools_pkg.put_outdebug_message` | 2861 |
| `dka_tools_pkg.put_outdebug_message` | 2863 |
| `fnd_file.put_line` | 2868 |
| `dka_tools_pkg.put_log_message` | 2877 |
| `dka_tools_pkg.put_log_message` | 2880 |
| `dka_tools_pkg.put_log_message` | 2920 |
| `dka_tools_pkg.put_log_message` | 2921 |
| `dka_tools_pkg.put_log_message` | 2922 |
| `dka_tools_pkg.put_log_message` | 2924 |
| `dka_tools_pkg.put_log_message` | 2936 |
| `dka_tools_pkg.put_log_message` | 2937 |
| `dka_tools_pkg.put_log_message` | 2942 |
| `dka_tools_pkg.put_log_message` | 2943 |
| `dka_tools_pkg.put_log_message` | 2944 |
| `dka_tools_pkg.put_log_message` | 2946 |
| `dka_tools_pkg.put_log_message` | 2954 |
| `dka_tools_pkg.put_log_message` | 2955 |
| `dka_tools_pkg.put_log_message` | 2960 |
| `dka_tools_pkg.put_log_message` | 2961 |
| `dka_tools_pkg.put_log_message` | 2962 |
| `dka_tools_pkg.put_log_message` | 2964 |
| `dka_tools_pkg.put_log_message` | 2972 |
| `dka_tools_pkg.put_log_message` | 2973 |
| `dka_tools_pkg.put_log_message` | 2978 |
| `dka_tools_pkg.put_log_message` | 2979 |
| `dka_tools_pkg.put_log_message` | 2980 |
| `dka_tools_pkg.put_log_message` | 2982 |
| `dka_tools_pkg.put_log_message` | 2990 |
| `dka_tools_pkg.put_log_message` | 2994 |
| `dka_tools_pkg.put_log_message` | 3001 |
| `dka_tools_pkg.put_log_message` | 3005 |
| `dka_tools_pkg.put_log_message` | 3013 |
| `dka_tools_pkg.put_log_message` | 3017 |
| `dka_tools_pkg.put_log_message` | 3025 |
| `dka_tools_pkg.put_log_message` | 3037 |
| `dka_tools_pkg.put_log_message` | 3045 |
| `dka_tools_pkg.put_log_message` | 3049 |
| `dka_tools_pkg.put_log_message` | 3057 |
| `dka_tools_pkg.put_log_message` | 3060 |
| `dka_tools_pkg.put_log_message` | 3068 |
| `dka_tools_pkg.put_log_message` | 3071 |
| `dka_tools_pkg.put_log_message` | 3072 |
| `dka_tools_pkg.put_log_message` | 3077 |
| `dka_tools_pkg.put_log_message` | 3078 |
| `dka_tools_pkg.put_log_message` | 3079 |
| `dka_tools_pkg.put_log_message` | 3081 |
| `dka_tools_pkg.put_log_message` | 3089 |
| `dka_tools_pkg.put_log_message` | 3090 |
| `dka_tools_pkg.put_log_message` | 3095 |
| `dka_tools_pkg.put_log_message` | 3096 |
| `dka_tools_pkg.put_log_message` | 3097 |
| `dka_tools_pkg.put_log_message` | 3099 |
| `dka_tools_pkg.put_log_message` | 3107 |
| `dka_tools_pkg.put_log_message` | 3108 |
| `dka_tools_pkg.put_log_message` | 3113 |
| `dka_tools_pkg.put_log_message` | 3114 |
| `dka_tools_pkg.put_log_message` | 3115 |
| `dka_tools_pkg.put_log_message` | 3117 |
| `dka_tools_pkg.put_log_message` | 3125 |
| `dka_tools_pkg.put_log_message` | 3126 |
| `dka_tools_pkg.put_log_message` | 3131 |
| `dka_tools_pkg.put_log_message` | 3132 |
| `dka_tools_pkg.put_log_message` | 3133 |
| `dka_tools_pkg.put_log_message` | 3135 |
| `dka_tools_pkg.put_log_message` | 3143 |
| `dka_tools_pkg.put_log_message` | 3144 |
| `dka_tools_pkg.put_log_message` | 3150 |
| `dka_tools_pkg.put_log_message` | 3153 |
| `dka_tools_pkg.put_log_message` | 3158 |
| `dka_tools_pkg.put_log_message` | 3161 |
| `dka_tools_pkg.put_log_message` | 3166 |
| `dka_tools_pkg.put_log_message` | 3169 |
| `dka_tools_pkg.put_log_message` | 3174 |
| `dka_tools_pkg.put_log_message` | 3177 |
| `dka_tools_pkg.put_log_message` | 3182 |
| `dka_tools_pkg.put_log_message` | 3185 |
| `dka_tools_pkg.put_log_message` | 3190 |
| `dka_tools_pkg.put_log_message` | 3193 |
| `dka_tools_pkg.put_log_message` | 3198 |
| `dka_tools_pkg.put_log_message` | 3201 |
| `dka_tools_pkg.put_log_message` | 3206 |
| `dka_tools_pkg.put_log_message` | 3209 |
| `dka_tools_pkg.put_log_message` | 3214 |
| `dka_tools_pkg.put_log_message` | 3217 |
| `FND_FILE.PUT_LINE` | 3234 |
| `FND_REQUEST.submit_request` | 3365 |
| `DKA_TOOLS_PKG.put_log_message` | 3414 |
| `FND_REQUEST.submit_request` | 3442 |
| `DKA_TOOLS_PKG.put_log_message` | 3493 |
| `Fnd_Concurrent.wait_for_request` | 3506 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 955, 1111, 1301, 1489, 1804, 1960, 2298, 3373, 3454 |
| rollback | 962, 1118, 1308, 1496, 1811, 1967, 2310, 2524 |
| when_others | 173, 245, 287, 700, 712, 720, 769, 961, 1117, 1307, 1495, 1810, 1966, 2309, 2523, 2683, 2821, 2874, 3211, 3359, 3437, 3547 |
| suppression | 752, 762 |
| soumission | 3365, 3442 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPARGLCTRLFISCAL / DKA | `DKA_IAPARGLCTRLFISCAL_PKG.main` | dka/12.0.0/admin/import/DKA_IAPARGLCTRLFISCAL.prt:606 |
| DKA_IAPARGLCTRLFISCALAUTO / DKA | `DKA_IAPARGLCTRLFISCAL_PKG.main_auto` | dka/12.0.0/admin/import/DKA_IAPARGLCTRLFISCALAUTO.prt:477 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
