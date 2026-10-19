# DKA_REPARCLIIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_REPARCLIIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_REPARCLIIMP_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 4447 ; encodage : cp1252 (repli). SHA-256 : `9f155db5bea3db57ae0d91f9b49de986a29f5d1895b0a08e8a6b839c6c706223`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 145 |
| `output_header` | 336 |
| `Request_parameters` | 386 |
| `output_end` | 484 |
| `print_errors` | 512 |
| `get_gl_id` | 606 |
| `Launch_Loader` | 837 |
| `validate_data` | 993 |
| `import_data` | 1501 |
| `import_data_bank` | 2658 |
| `Report_Bilan` | 3522 |
| `set_recovery_mode` | 3618 |
| `Launch_Loader_relation` | 3661 |
| `validate_data_relation` | 3805 |
| `import_data_relation` | 3965 |
| `generate_output_relation` | 4081 |
| `main` | 4168 |
| `main_relation` | 4361 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `FND_CONCURRENT_REQUESTS` | 179 |
| `fnd_concurrent_requests` | 299 |
| `fnd_concurrent_programs` | 348 |
| `fnd_concurrent_requests` | 390 |
| `fnd_concurrent_requests` | 421 |
| `fnd_concurrent_requests` | 443 |
| `DKA_CLIENTS_TMP` | 516 |
| `DKA_RECOUVREMENTS_TMP` | 524 |
| `DKA_CLIENTS_TMP` | 535 |
| `DKA_RECOUVREMENTS_TMP` | 543 |
| `gl_code_combinations` | 626 |
| `gl_code_combinations` | 672 |
| `gl_code_combinations` | 726 |
| `gl_code_combinations` | 773 |
| `DKA_CLIENTS_TMP` | 913 |
| `DKA_CLIENTS_TMP` | 919 |
| `DKA_RECOUVREMENTS_TMP` | 926 |
| `DKA_RECOUVREMENTS_TMP` | 932 |
| `DKA_CLIENTS_TMP` | 997 |
| `OF` | 1000 |
| `DKA_RECOUVREMENTS_TMP` | 1004 |
| `OF` | 1007 |
| `DKA_RECOUVREMENTS_TMP` | 1011 |
| `OF` | 1017 |
| `DKA_CLIENTS_TMP` | 1021 |
| `DKA_RECOUVREMENTS_TMP` | 1027 |
| `DKA_RECOUVREMENTS_TMP` | 1066 |
| `DKA_RECOUVREMENTS_TMP` | 1074 |
| `fnd_flex_values` | 1116 |
| `hr_operating_units` | 1186 |
| `AR_RECEIPT_METHODS` | 1219 |
| `AR_CUSTOMER_PROFILE_CLASSES_V` | 1256 |
| `DKA_CLIENTS_TMP` | 1282 |
| `DKA_CLIENTS_TMP` | 1297 |
| `DKA_RECOUVREMENTS_TMP` | 1303 |
| `ar_collectors` | 1333 |
| `hr_operating_units` | 1362 |
| `DKA_RECOUVREMENTS_TMP` | 1387 |
| `DKA_CLIENTS_TMP` | 1394 |
| `DKA_RECOUVREMENTS_TMP` | 1408 |
| `DKA_CLIENTS_TMP` | 1414 |
| `DKA_CLIENTS_TMP` | 1437 |
| `DKA_RECOUVREMENTS_TMP` | 1446 |
| `DKA_RECOUVREMENTS_TMP` | 1456 |
| `DKA_CLIENTS_TMP` | 1461 |
| `DKA_CLIENTS_TMP` | 1534 |
| `hr_operating_units` | 1540 |
| `DKA_CLIENTS_TMP` | 1557 |
| `dka_clients_tmp` | 1625 |
| `DKA_CLIENTS_TMP` | 1656 |
| `DKA_CUSTOMER_PROFILE` | 1666 |
| `RA_CUSTOMERS_INTERFACE_ALL` | 1762 |
| `RA_CUSTOMER_PROFILES_INT_ALL` | 1851 |
| `RA_CONTACT_PHONES_INT_ALL` | 1891 |
| `RA_CUST_PAY_METHOD_INT_ALL` | 2019 |
| `RA_CUSTOMER_PROFILES_INT_ALL` | 2072 |
| `DKA_CLIENTS_TMP` | 2099 |
| `DKA_RECOUVREMENTS_TMP` | 2107 |
| `RA_CUSTOMERS_INTERFACE_ALL` | 2127 |
| `RA_CUSTOMER_PROFILES_INT_ALL` | 2128 |
| `RA_CONTACT_PHONES_INT_ALL` | 2129 |
| `RA_CUST_PAY_METHOD_INT_ALL` | 2130 |
| `fnd_responsibility` | 2265 |
| `ra_customers_interface_all` | 2269 |
| `ra_customer_profiles_int_all` | 2270 |
| `ra_contact_phones_int_all` | 2271 |
| `ra_cust_pay_method_int_all` | 2272 |
| `ra_cust_receipt_methods` | 2472 |
| `ar_customers` | 2475 |
| `dka_clients_tmp` | 2481 |
| `RA_CUSTOMERS_INTERFACE_ALL` | 2517 |
| `DKA_CLIENTS_TMP` | 2520 |
| `RA_CUSTOMER_PROFILES_INT_ALL` | 2538 |
| `DKA_CLIENTS_TMP` | 2541 |
| `RA_CUSTOMER_BANKS_INT_ALL` | 2558 |
| `DKA_CLIENTS_TMP` | 2561 |
| `RA_CUST_PAY_METHOD_INT_ALL` | 2579 |
| `DKA_CLIENTS_TMP` | 2582 |
| `ra_contact_phones_int_all` | 2599 |
| `DKA_CLIENTS_TMP` | 2602 |
| `dka_clients_tmp` | 2677 |
| `hr_operating_units` | 2689 |
| `dka_clients_tmp` | 2713 |
| `hz_cust_accounts` | 2785 |
| `IBY_ACCOUNT_OWNERS` | 3028 |
| `DKA_CLIENTS_TMP` | 3110 |
| `hz_cust_acct_sites_all` | 3131 |
| `iby_external_payers_all` | 3163 |
| `hz_cust_accounts` | 3231 |
| `dka_program_messages` | 3262 |
| `DKA_CLIENTS_TMP` | 3288 |
| `DKA_CLIENTS_TMP` | 3296 |
| `hz_cust_accounts` | 3333 |
| `iby_debit_authorizations` | 3416 |
| `DKA_CLIENTS_TMP` | 3479 |
| `DKA_CLIENTS_TMP` | 3487 |
| `DKA_CLIENTS_TMP` | 3624 |
| `DKA_RECOUVREMENTS_TMP` | 3628 |
| `DKA_CLIENTS_REL_TMP` | 3737 |
| `DKA_CLIENTS_REL_TMP` | 3743 |
| `DKA_CLIENTS_REL_TMP` | 3809 |
| `dka_clients_rel_tmp` | 3843 |
| `dka_clients_rel_tmp` | 3852 |
| `dka_clients_rel_tmp` | 3858 |
| `hz_cust_accounts` | 3867 |
| `dka_clients_rel_tmp` | 3873 |
| `hz_cust_accounts` | 3882 |
| `dka_clients_rel_tmp` | 3888 |
| `hz_cust_accounts` | 3899 |
| `hz_cust_accounts` | 3912 |
| `dka_clients_rel_tmp` | 3925 |
| `dka_clients_rel_tmp` | 3933 |
| `dka_clients_rel_tmp` | 3985 |
| `hz_cust_acct_sites_all` | 3994 |
| `hz_cust_acct_sites_all` | 4005 |
| `dka_clients_rel_tmp` | 4054 |
| `dka_clients_rel_tmp` | 4060 |
| `dka_clients_rel_tmp` | 4096 |
| `dka_clients_rel_tmp` | 4112 |
| `dka_clients_rel_tmp` | 4119 |
| `dka_clients_rel_tmp` | 4128 |
| `dka_clients_rel_tmp` | 4137 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 154 |
| `fnd_profile.value` | 172 |
| `Dka_Tools_Pkg.get_parameter` | 204 |
| `Dka_Tools_Pkg.get_parameter` | 215 |
| `Dka_Tools_Pkg.get_parameter` | 226 |
| `Dka_Tools_Pkg.get_parameter` | 237 |
| `Dka_Tools_Pkg.get_parameter` | 248 |
| `Dka_Tools_Pkg.get_parameter` | 259 |
| `Dka_Tools_Pkg.get_parameter` | 270 |
| `Dka_Tools_Pkg.get_parameter` | 281 |
| `Fnd_File.put_line` | 292 |
| `Fnd_File.put_line` | 303 |
| `fnd_file.put_line` | 313 |
| `Fnd_File.put_line` | 360 |
| `Fnd_File.put_line` | 361 |
| `Fnd_File.put_line` | 363 |
| `Fnd_File.put_line` | 365 |
| `Fnd_File.put_line` | 368 |
| `Fnd_File.put_line` | 406 |
| `Fnd_File.put_line` | 407 |
| `Fnd_File.put_line` | 408 |
| `Fnd_File.put_line` | 409 |
| `Fnd_File.put_line` | 427 |
| `Fnd_File.put_line` | 430 |
| `Fnd_File.put_line` | 449 |
| `Fnd_File.put_line` | 452 |
| `Fnd_File.put_line` | 457 |
| `Fnd_File.put_line` | 460 |
| `Fnd_File.put_line` | 461 |
| `Fnd_File.put_line` | 490 |
| `Fnd_File.put_line` | 491 |
| `Fnd_File.put_line` | 494 |
| `fnd_file.put_line` | 563 |
| `fnd_file.put_line` | 564 |
| `fnd_file.put_line` | 565 |
| `fnd_file.put_line` | 566 |
| `fnd_file.put_line` | 567 |
| `Fnd_File.put_line` | 570 |
| `fnd_file.put_line` | 577 |
| `fnd_file.put_line` | 578 |
| `fnd_file.put_line` | 579 |
| `fnd_file.put_line` | 580 |
| `fnd_file.put_line` | 581 |
| `Fnd_File.put_line` | 584 |
| `Dka_Tools_Pkg.get_code_combination_id` | 648 |
| `Fnd_File.put_line` | 664 |
| `Dka_Tools_Pkg.get_code_combination_id` | 694 |
| `Fnd_File.put_line` | 710 |
| `Dka_Tools_Pkg.get_code_combination_id` | 749 |
| `Fnd_File.put_line` | 765 |
| `Dka_Tools_Pkg.get_code_combination_id` | 795 |
| `Fnd_File.put_line` | 811 |
| `Fnd_File.put_line` | 846 |
| `Fnd_File.put_line` | 849 |
| `fnd_file.put_line` | 853 |
| `fnd_file.put_line` | 854 |
| `fnd_file.put_line` | 855 |
| `fnd_request.set_print_options` | 860 |
| `Fnd_Request.submit_request` | 863 |
| `fnd_file.put_line` | 876 |
| `Fnd_File.put_line` | 880 |
| `Fnd_File.put_line` | 884 |
| `Fnd_File.put_line` | 886 |
| `Fnd_Concurrent.wait_for_request` | 891 |
| `Fnd_file.put_line` | 900 |
| `Fnd_File.put_line` | 906 |
| `Fnd_File.put_line` | 909 |
| `Fnd_File.put_line` | 921 |
| `Fnd_File.put_line` | 934 |
| `Fnd_File.put_line` | 940 |
| `fnd_file.put_line` | 950 |
| `Fnd_File.put_line` | 956 |
| `Fnd_File.put_line` | 963 |
| `Fnd_File.put_line` | 971 |
| `Fnd_File.put_line` | 972 |
| `FND_PROFILE.VALUE` | 1050 |
| `dka_tools_pkg.ins_prog_message` | 1124 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1139 |
| `dka_tools_pkg.ins_prog_message` | 1147 |
| `dka_tools_pkg.ins_prog_message` | 1163 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1178 |
| `dka_tools_pkg.ins_prog_message` | 1195 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1211 |
| `dka_tools_pkg.ins_prog_message` | 1227 |
| `dka_tools_pkg.ins_prog_message` | 1264 |
| `dka_tools_pkg.ins_prog_message` | 1341 |
| `DKA_REP_TRANSCO_PKG.get_transco` | 1354 |
| `dka_tools_pkg.ins_prog_message` | 1371 |
| `Fnd_File.put_line` | 1479 |
| `Fnd_File.put_line` | 1480 |
| `FND_PROFILE.VALUE` | 1711 |
| `FND_PROFILE.VALUE` | 1712 |
| `FND_PROFILE.VALUE` | 1713 |
| `Fnd_File.put_line` | 1715 |
| `dka_tools_pkg.ins_prog_message` | 1746 |
| `Fnd_File.put_line` | 1759 |
| `dka_tools_pkg.put_debug_message` | 2001 |
| `dka_tools_pkg.put_debug_message` | 2056 |
| `Fnd_File.put_line` | 2064 |
| `Fnd_File.put_line` | 2120 |
| `Fnd_File.put_line` | 2123 |
| `Fnd_Request.submit_request` | 2133 |
| `fnd_file.put_line` | 2151 |
| `Fnd_File.put_line` | 2154 |
| `Fnd_File.put_line` | 2161 |
| `Fnd_Concurrent.wait_for_request` | 2171 |
| `Fnd_File.put_line` | 2251 |
| `Fnd_File.put_line` | 2254 |
| `FND_GLOBAL.APPS_INITIALIZE` | 2287 |
| `Fnd_Request.submit_request` | 2294 |
| `fnd_file.put_line` | 2315 |
| `Fnd_File.put_line` | 2318 |
| `Fnd_File.put_line` | 2327 |
| `Fnd_Concurrent.wait_for_request` | 2333 |
| `Fnd_file.put_line` | 2336 |
| `Fnd_File.put_line` | 2341 |
| `Fnd_File.put_line` | 2344 |
| `Fnd_File.put_line` | 2349 |
| `fnd_file.put_line` | 2359 |
| `Fnd_File.put_line` | 2364 |
| `Fnd_Request.submit_request` | 2371 |
| `fnd_file.put_line` | 2389 |
| `Fnd_File.put_line` | 2392 |
| `Fnd_File.put_line` | 2399 |
| `Fnd_Concurrent.wait_for_request` | 2404 |
| `Fnd_file.put_line` | 2407 |
| `FND_GLOBAL.APPS_INITIALIZE` | 2500 |
| `dka_tools_pkg.ins_prog_message` | 2614 |
| `Fnd_File.put_line` | 2636 |
| `Fnd_File.put_line` | 2637 |
| `Fnd_File.put_line` | 2767 |
| `Fnd_File.put_line` | 2770 |
| `dka_tools_pkg.ins_prog_message` | 2794 |
| `iby_ext_bankacct_pub.check_bank_exist` | 2806 |
| `dka_tools_pkg.ins_prog_message` | 2824 |
| `iby_ext_bankacct_pub.check_bank_exist` | 2837 |
| `dka_tools_pkg.ins_prog_message` | 2855 |
| `dka_tools_pkg.ins_prog_message` | 2871 |
| `iby_ext_bankacct_pub.check_ext_bank_branch_exist` | 2888 |
| `dka_tools_pkg.ins_prog_message` | 2906 |
| `iby_ext_bankacct_pub.check_ext_bank_branch_exist` | 2919 |
| `dka_tools_pkg.ins_prog_message` | 2937 |
| `dka_tools_pkg.ins_prog_message` | 2953 |
| `iby_ext_bankacct_pub.check_ext_acct_exist` | 2992 |
| `dka_tools_pkg.ins_prog_message` | 3011 |
| `iby_ext_bankacct_pub.add_joint_account_owner` | 3038 |
| `dka_tools_pkg.ins_prog_message` | 3056 |
| `iby_ext_bankacct_pub.create_ext_bank_acct` | 3076 |
| `dka_tools_pkg.ins_prog_message` | 3093 |
| `dka_tools_pkg.ins_prog_message` | 3146 |
| `iby_fndcpt_setup_pub.set_payer_instr_assignment` | 3196 |
| `dka_tools_pkg.ins_prog_message` | 3215 |
| `dka_tools_pkg.ins_prog_message` | 3273 |
| `Fnd_File.put_line` | 3307 |
| `Fnd_File.put_line` | 3310 |
| `dka_tools_pkg.ins_prog_message` | 3374 |
| `dka_tools_pkg.ins_prog_message` | 3398 |
| `iby_debit_auth_pkg.Create_Debit_Authorization` | 3426 |
| `dka_tools_pkg.ins_prog_message` | 3464 |
| `Fnd_File.put_line` | 3502 |
| `Fnd_File.put_line` | 3503 |
| `Fnd_File.put_line` | 3526 |
| `fnd_file.put_line` | 3538 |
| `fnd_file.put_line` | 3539 |
| `fnd_file.put_line` | 3540 |
| `fnd_file.put_line` | 3541 |
| `fnd_file.put_line` | 3544 |
| `fnd_file.put_line` | 3547 |
| `fnd_file.put_line` | 3550 |
| `fnd_file.put_line` | 3553 |
| `fnd_file.put_line` | 3556 |
| `fnd_file.put_line` | 3559 |
| `fnd_file.put_line` | 3562 |
| `fnd_file.put_line` | 3565 |
| `fnd_file.put_line` | 3568 |
| `fnd_file.put_line` | 3571 |
| `fnd_file.put_line` | 3574 |
| `fnd_file.put_line` | 3577 |
| `fnd_file.put_line` | 3580 |
| `fnd_file.put_line` | 3585 |
| `fnd_file.put_line` | 3588 |
| `Fnd_File.put_line` | 3589 |
| `Fnd_File.put_line` | 3597 |
| `Fnd_File.put_line` | 3598 |
| `Fnd_File.put_line` | 3636 |
| `Fnd_File.put_line` | 3637 |
| `Fnd_File.put_line` | 3670 |
| `Fnd_File.put_line` | 3673 |
| `fnd_file.put_line` | 3677 |
| `fnd_file.put_line` | 3678 |
| `fnd_file.put_line` | 3679 |
| `fnd_request.set_print_options` | 3684 |
| `Fnd_Request.submit_request` | 3687 |
| `fnd_file.put_line` | 3700 |
| `Fnd_File.put_line` | 3704 |
| `Fnd_File.put_line` | 3708 |
| `Fnd_File.put_line` | 3710 |
| `Fnd_Concurrent.wait_for_request` | 3715 |
| `Fnd_file.put_line` | 3724 |
| `Fnd_File.put_line` | 3730 |
| `Fnd_File.put_line` | 3733 |
| `Fnd_File.put_line` | 3745 |
| `Fnd_File.put_line` | 3752 |
| `fnd_file.put_line` | 3762 |
| `Fnd_File.put_line` | 3768 |
| `Fnd_File.put_line` | 3775 |
| `Fnd_File.put_line` | 3783 |
| `Fnd_File.put_line` | 3784 |
| `fnd_profile.VALUE` | 3831 |
| `Fnd_File.put_line` | 3943 |
| `Fnd_File.put_line` | 3944 |
| `hz_cust_account_v2pub.create_cust_acct_relate` | 4034 |
| `fnd_msg_pub.get` | 4045 |
| `fnd_file.put_line` | 4074 |
| `fnd_file.put_line` | 4075 |
| `fnd_file.put_line` | 4102 |
| `fnd_file.put_line` | 4103 |
| `fnd_file.put_line` | 4106 |
| `fnd_file.put_line` | 4110 |
| `fnd_file.put_line` | 4114 |
| `fnd_file.put_line` | 4122 |
| `fnd_file.put_line` | 4131 |
| `fnd_file.put_line` | 4140 |
| `Fnd_File.put_line` | 4184 |
| `Fnd_File.put_line` | 4191 |
| `Fnd_File.put_line` | 4211 |
| `Fnd_File.put_line` | 4229 |
| `Fnd_File.put_line` | 4243 |
| `Fnd_File.put_line` | 4257 |
| `Fnd_File.put_line` | 4283 |
| `Fnd_File.put_line` | 4307 |
| `Fnd_File.put_line` | 4308 |
| `Fnd_File.put_line` | 4310 |
| `Fnd_File.put_line` | 4318 |
| `Fnd_File.put_line` | 4319 |
| `Fnd_File.put_line` | 4320 |
| `Fnd_File.put_line` | 4324 |
| `Fnd_File.put_line` | 4331 |
| `Fnd_File.put_line` | 4335 |
| `Fnd_File.put_line` | 4377 |
| `Fnd_File.put_line` | 4392 |
| `Fnd_File.put_line` | 4406 |
| `Fnd_File.put_line` | 4433 |
| `Fnd_File.put_line` | 4437 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `DKA_LOADER_REPARCLIIMP` | 863 |
| `FNDGTST` | 2133 |
| `RACUSTMA` | 2294 |
| `FNDGSCST` | 2371 |
| `DKA_LOADER_REPARRELCLIIMP` | 3687 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 883, 1473, 2117, 2157, 2321, 2395, 2498, 3496, 3707, 3847, 3862, 3877, 3892, 3929, 3936, 4066 |
| rollback | 2, 4052 |
| when_others | 315, 355, 647, 693, 748, 794, 968, 1082, 1122, 1192, 1224, 1261, 1338, 1368, 1476, 1741, 2055, 2628, 2633, 2788, 3139, 3384, 3457, 3499, 3594, 3633, 3780, 3940, 4071, 4145, 4328, 4430 |
| soumission | 863, 2133, 2294, 2371, 3687 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_REPARCLIIMP / DKA | `DKA_REPARCLIIMP_PKG.Main` | dka/12.0.0/admin/import/DKA_REPARCLIIMP.prt:438 |
| DKA_REPARRELCLIIMP / DKA | `DKA_REPARCLIIMP_PKG.Main_relation` | dka/12.0.0/admin/import/DKA_REPARRELCLIIMP.prt:438 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
