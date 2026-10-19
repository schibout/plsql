# DKA_IARPAFAC_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IARPAFAC_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 5609 ; encodage : cp1252 (repli). SHA-256 : `6923c4d929178fd2ae1e263957f2b5006a65ac0779da80d0fa8a38ce4ead52b2`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `init` | 186 |
| `update_request_id` | 261 |
| `update_tax_rate` | 319 |
| `update_group_id` | 386 |
| `get_millesim_batch_id` | 456 |
| `load_invoice_header` | 542 |
| `set_tax_equal_flag` | 724 |
| `create_ext_instrument` | 789 |
| `load_invoice_line` | 953 |
| `get_acct_area` | 1804 |
| `get_ar_gl_date` | 1999 |
| `get_ar_tax` | 2165 |
| `get_transaction_type` | 2283 |
| `get_ccid_ttc` | 2391 |
| `get_ccid_attributes_line` | 2601 |
| `get_ccid_tax` | 2977 |
| `get_ccid_surtaxe` | 3263 |
| `get_customer_info` | 3501 |
| `check_project` | 3769 |
| `run_import` | 4073 |
| `run_recyclage_rejections` | 4227 |
| `update_prlvt_invoice` | 4313 |
| `main` | 4405 |
| `main` | 5274 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ra_terms` | 214 |
| `dka_iarpafac_interface` | 272 |
| `dka_iarpafac_interface` | 330 |
| `zx_rates_b` | 333 |
| `dka_iarpafac_interface` | 404 |
| `dii.fmt_invoice_date` | 411 |
| `dka_iarpafac_interface` | 413 |
| `diittc.fmt_invoice_date` | 420 |
| `dii.fmt_invoice_date` | 420 |
| `ra_batch_sources_all` | 476 |
| `ra_interface_distributions_all` | 645 |
| `dka_iarpafac_interface` | 736 |
| `dka_iarpafac_interface` | 753 |
| `dka_iarpafac_interface` | 772 |
| `hz_cust_accounts` | 814 |
| `iby_debit_authorizations` | 826 |
| `ra_cust_trx_types_all` | 1062 |
| `gl_ledgers` | 1076 |
| `gl_ledgers` | 1376 |
| `GL_DAILY_RATES_V` | 1385 |
| `hz_cust_site_uses_all` | 1403 |
| `AR_RECEIPT_METHODS` | 1416 |
| `iby_pmt_instr_uses_all` | 1434 |
| `iby_pmt_instr_uses_all` | 1447 |
| `hz_cust_accounts` | 1460 |
| `dka_iarpafac_prelev_tmp` | 1478 |
| `ra_interface_lines_all` | 1521 |
| `ra_interface_distributions_all` | 1674 |
| `hr_operating_units` | 1831 |
| `pa_projects_all` | 1832 |
| `pa_tasks` | 1833 |
| `gl_period_statuses` | 2021 |
| `gl_code_combinations` | 2204 |
| `zx_accounts` | 2206 |
| `zx_rates_b` | 2208 |
| `hz_parties` | 2469 |
| `hz_parties` | 2755 |
| `gl_code_combinations` | 3077 |
| `zx_accounts` | 3080 |
| `gl_code_combinations` | 3082 |
| `zx_rates_b` | 3083 |
| `gl_code_combinations` | 3137 |
| `zx_accounts` | 3139 |
| `zx_rates_b` | 3141 |
| `fnd_flex_values_vl` | 3297 |
| `hz_cust_acct_sites_all` | 3524 |
| `hz_cust_acct_sites_all` | 3568 |
| `hz_cust_acct_sites_all` | 3655 |
| `PA_PROJECTS_ALL` | 3821 |
| `PA_TASKS` | 3822 |
| `HR_OPERATING_UNITS` | 3823 |
| `GL_LEDGERS` | 3824 |
| `pa_tasks` | 3891 |
| `pa_projects_all` | 3907 |
| `pa_tasks` | 3908 |
| `pa_tasks` | 3927 |
| `dka_iarpafac_prelev_tmp` | 4318 |
| `of` | 4320 |
| `RA_CUSTOMER_TRX_ALL` | 4334 |
| `dka_iarpafac_prelev_tmp` | 4345 |
| `RA_CUSTOMER_TRX_ALL` | 4354 |
| `dka_iarpafac_prelev_tmp` | 4363 |
| `dka_iarpafac_prelev_tmp` | 4369 |
| `fmt_invoice_date` | 4466 |
| `dka_iarpafac_interface` | 4471 |
| `fmt_invoice_date` | 4480 |
| `dka_iarpafac_interface` | 4495 |
| `dka_iarpafac_interface` | 4515 |
| `dka_iarpafac_interface` | 4543 |
| `ra_interface_lines_all` | 4565 |
| `dka_iarpafac_interface` | 4645 |
| `dka_iarpafac_prelev_tmp` | 4655 |
| `dka_iarpafac_interface` | 4684 |
| `DUAL` | 4716 |
| `gl_period_statuses` | 4728 |
| `dka_iarpafac_interface` | 4735 |
| `dka_iarpafac_interface` | 4743 |
| `Z` | 4748 |
| `dka_iarpafac_interface` | 4844 |
| `pa_projects_all` | 4858 |
| `dka_iarpafac_interface` | 4862 |
| `dka_iarpafac_interface` | 4870 |
| `dka_iarpafac_interface` | 5158 |
| `dka_iarpafac_interface` | 5369 |
| `dka_iarpafac_interface` | 5385 |
| `dka_iarpafac_interface` | 5430 |
| `dka_iarpafac_interface` | 5437 |
| `ra_batch_sources_all` | 5498 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.segment_size` | 163 |
| `Dka_Tools_Pkg.segment_size` | 164 |
| `Dka_Tools_Pkg.segment_size` | 166 |
| `Dka_Tools_Pkg.put_debug_message` | 192 |
| `Dka_Tools_Pkg.put_debug_message` | 205 |
| `Dka_Iclientifs_Pkg.init` | 225 |
| `Dka_Tools_Pkg.get_message` | 229 |
| `Dka_Tools_Pkg.put_outdebug_message` | 230 |
| `Dka_Tools_Pkg.put_debug_message` | 231 |
| `Dka_Tools_Pkg.ins_prog_message` | 233 |
| `Dka_Tools_Pkg.get_message` | 280 |
| `Dka_Tools_Pkg.put_outdebug_message` | 289 |
| `Dka_Tools_Pkg.ins_prog_message` | 291 |
| `Dka_Tools_Pkg.get_message` | 344 |
| `Dka_Tools_Pkg.put_outdebug_message` | 353 |
| `Dka_Tools_Pkg.ins_prog_message` | 355 |
| `Dka_Tools_Pkg.get_message` | 424 |
| `Dka_Tools_Pkg.put_outdebug_message` | 425 |
| `Dka_Tools_Pkg.ins_prog_message` | 427 |
| `Dka_Tools_Pkg.put_outdebug_message` | 487 |
| `Dka_Tools_Pkg.put_outdebug_message` | 488 |
| `Dka_Tools_Pkg.put_outdebug_message` | 489 |
| `Dka_Tools_Pkg.put_outdebug_message` | 490 |
| `Dka_Tools_Pkg.ins_prog_message` | 499 |
| `Dka_Tools_Pkg.get_message` | 512 |
| `Dka_Tools_Pkg.put_outdebug_message` | 513 |
| `Dka_Tools_Pkg.ins_prog_message` | 515 |
| `Dka_Tools_Pkg.put_debug_message` | 570 |
| `Dka_Tools_Pkg.put_debug_message` | 584 |
| `Dka_Tools_Pkg.put_debug_message` | 597 |
| `Dka_Tools_Pkg.put_debug_message` | 615 |
| `Dka_Tools_Pkg.put_debug_message` | 697 |
| `Dka_Tools_Pkg.get_message` | 702 |
| `Dka_Tools_Pkg.put_debug_message` | 703 |
| `Dka_Tools_Pkg.ins_prog_message` | 704 |
| `Fnd_File.put_line` | 818 |
| `Fnd_File.put_line` | 819 |
| `Fnd_File.put_line` | 842 |
| `Fnd_File.put_line` | 843 |
| `Fnd_File.put_line` | 846 |
| `Fnd_File.put_line` | 847 |
| `fnd_file.put_line` | 875 |
| `IBY_FNDCPT_TRXN_PUB.Create_Transaction_Extension` | 877 |
| `FND_MSG_PUB.GET` | 895 |
| `Dka_Tools_Pkg.put_log_message` | 904 |
| `Dka_Tools_Pkg.put_log_message` | 907 |
| `Dka_Tools_Pkg.put_log_message` | 910 |
| `Dka_Tools_Pkg.put_log_message` | 913 |
| `FND_MSG_PUB.GET` | 920 |
| `Dka_Tools_Pkg.put_debug_message` | 1035 |
| `Dka_Tools_Pkg.put_debug_message` | 1067 |
| `Dka_Tools_Pkg.put_debug_message` | 1080 |
| `Dka_Tools_Pkg.put_debug_message` | 1089 |
| `Dka_Tools_Pkg.put_debug_message` | 1107 |
| `DKA_PA_TOOLS_PKG.pa_check_transaction_data` | 1156 |
| `DKA_PA_TOOLS_PKG.pa_check_transaction_data` | 1168 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1182 |
| `Dka_Tools_Pkg.ins_prog_message` | 1184 |
| `DKA_PA_TOOLS_PKG.pa_check_transaction_data` | 1205 |
| `DKA_PA_TOOLS_PKG.pa_check_transaction_data` | 1217 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1231 |
| `Dka_Tools_Pkg.put_debug_message` | 1232 |
| `Dka_Tools_Pkg.ins_prog_message` | 1234 |
| `Dka_Tools_Pkg.put_debug_message` | 1393 |
| `fnd_file.put_line` | 1429 |
| `fnd_file.put_line` | 1452 |
| `fnd_file.put_line` | 1475 |
| `Dka_Tools_Pkg.put_debug_message` | 1519 |
| `Dka_Tools_Pkg.put_debug_message` | 1673 |
| `Dka_Tools_Pkg.put_debug_message` | 1771 |
| `Dka_Tools_Pkg.get_message` | 1776 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1777 |
| `Dka_Tools_Pkg.ins_prog_message` | 1778 |
| `Dka_Tools_Pkg.get_message` | 1838 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1852 |
| `Dka_Tools_Pkg.ins_prog_message` | 1854 |
| `Dka_Stransco_Pkg.get_value_f` | 1873 |
| `Dka_Tools_Pkg.get_message` | 1877 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1887 |
| `Dka_Tools_Pkg.ins_prog_message` | 1888 |
| `Dka_Tools_Pkg.get_message` | 1933 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1943 |
| `Dka_Tools_Pkg.put_debug_message` | 1944 |
| `Dka_Tools_Pkg.ins_prog_message` | 1946 |
| `Dka_Tools_Pkg.put_debug_message` | 1960 |
| `Dka_Tools_Pkg.get_message` | 1965 |
| `Dka_Tools_Pkg.put_outdebug_message` | 1966 |
| `Dka_Tools_Pkg.ins_prog_message` | 1967 |
| `Dka_Tools_Pkg.put_debug_message` | 2069 |
| `Dka_Tools_Pkg.put_debug_message` | 2070 |
| `Dka_Tools_Pkg.get_message` | 2076 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2080 |
| `Dka_Tools_Pkg.ins_prog_message` | 2082 |
| `Dka_Tools_Pkg.get_message` | 2096 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2097 |
| `Dka_Tools_Pkg.ins_prog_message` | 2099 |
| `Dka_Tools_Pkg.get_message` | 2113 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2118 |
| `Dka_Tools_Pkg.ins_prog_message` | 2120 |
| `Dka_Tools_Pkg.get_message` | 2134 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2135 |
| `Dka_Tools_Pkg.ins_prog_message` | 2137 |
| `Dka_Tools_Pkg.put_debug_message` | 2148 |
| `Dka_Tools_Pkg.put_debug_message` | 2216 |
| `Dka_Tools_Pkg.put_debug_message` | 2217 |
| `Dka_Tools_Pkg.get_message` | 2222 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2234 |
| `Dka_Tools_Pkg.ins_prog_message` | 2236 |
| `Dka_Tools_Pkg.get_message` | 2250 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2251 |
| `Dka_Tools_Pkg.ins_prog_message` | 2253 |
| `Dka_Stransco_Pkg.get_value_f` | 2308 |
| `Dka_Tools_Pkg.get_message` | 2320 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2332 |
| `Dka_Tools_Pkg.ins_prog_message` | 2333 |
| `Dka_Tools_Pkg.put_debug_message` | 2358 |
| `Dka_Tools_Pkg.get_message` | 2363 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2364 |
| `Dka_Tools_Pkg.ins_prog_message` | 2365 |
| `Dka_Stransco_Pkg.get_value_f` | 2448 |
| `Dka_Tools_Pkg.put_debug_message` | 2538 |
| `Dka_Tools_Pkg.get_message` | 2543 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2555 |
| `Dka_Tools_Pkg.ins_prog_message` | 2557 |
| `Dka_Tools_Pkg.get_message` | 2570 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2571 |
| `Dka_Tools_Pkg.ins_prog_message` | 2573 |
| `Dka_Spaautoaccounting_Pkg.uo_projet` | 2695 |
| `Dka_Spaautoaccounting_Pkg.cpt_groupe_couts` | 2719 |
| `Dka_Tools_Pkg.put_debug_message` | 2728 |
| `Dka_Tools_Pkg.put_debug_message` | 2729 |
| `Dka_Spaautoaccounting_Pkg.CPT_GROUPE_PRODUIT` | 2738 |
| `Dka_Tools_Pkg.put_debug_message` | 2741 |
| `Dka_Tools_Pkg.put_debug_message` | 2742 |
| `Dka_Spaautoaccounting_Pkg.centrefi` | 2785 |
| `Dka_Spaautoaccounting_Pkg.affaire` | 2795 |
| `Dka_Spaautoaccounting_Pkg.projetfi` | 2805 |
| `Dka_Tools_Pkg.put_debug_message` | 2831 |
| `Dka_Tools_Pkg.put_debug_message` | 2840 |
| `Dka_Tools_Pkg.put_debug_message` | 2852 |
| `DKA_AR_TOOLS_PKG.issurtaxeaccount` | 2879 |
| `Dka_Tools_Pkg.put_debug_message` | 2895 |
| `Dka_Tools_Pkg.put_debug_message` | 2908 |
| `Dka_Tools_Pkg.get_message` | 2918 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2930 |
| `Dka_Tools_Pkg.ins_prog_message` | 2932 |
| `Dka_Tools_Pkg.get_message` | 2946 |
| `Dka_Tools_Pkg.put_outdebug_message` | 2947 |
| `Dka_Tools_Pkg.ins_prog_message` | 2949 |
| `Dka_Tools_Pkg.put_debug_message` | 3093 |
| `Dka_Tools_Pkg.put_debug_message` | 3170 |
| `Dka_Tools_Pkg.put_debug_message` | 3185 |
| `Dka_Tools_Pkg.get_message` | 3203 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3215 |
| `Dka_Tools_Pkg.ins_prog_message` | 3217 |
| `Dka_Tools_Pkg.get_message` | 3231 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3232 |
| `Dka_Tools_Pkg.ins_prog_message` | 3234 |
| `Dka_Stransco_Pkg.get_value_f` | 3339 |
| `Dka_Tools_Pkg.put_debug_message` | 3418 |
| `Dka_Tools_Pkg.get_message` | 3436 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3448 |
| `Dka_Tools_Pkg.ins_prog_message` | 3450 |
| `Dka_Tools_Pkg.get_message` | 3464 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3465 |
| `Dka_Tools_Pkg.ins_prog_message` | 3467 |
| `Dka_Tools_Pkg.put_debug_message` | 3527 |
| `Dka_Tools_Pkg.get_message` | 3535 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3547 |
| `Dka_Tools_Pkg.ins_prog_message` | 3549 |
| `Dka_Tools_Pkg.put_debug_message` | 3576 |
| `Dka_Tools_Pkg.put_debug_message` | 3581 |
| `Dka_Tools_Pkg.get_message` | 3582 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3596 |
| `Dka_Tools_Pkg.ins_prog_message` | 3598 |
| `Dka_Tools_Pkg.get_message` | 3619 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3631 |
| `Dka_Tools_Pkg.ins_prog_message` | 3633 |
| `Dka_Tools_Pkg.put_debug_message` | 3664 |
| `Dka_Tools_Pkg.put_debug_message` | 3665 |
| `Dka_Tools_Pkg.put_debug_message` | 3666 |
| `Dka_Tools_Pkg.get_message` | 3669 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3683 |
| `Dka_Tools_Pkg.ins_prog_message` | 3685 |
| `Dka_Tools_Pkg.get_message` | 3700 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3711 |
| `Dka_Tools_Pkg.ins_prog_message` | 3713 |
| `Dka_Tools_Pkg.get_message` | 3730 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3731 |
| `Dka_Tools_Pkg.ins_prog_message` | 3733 |
| `Dka_Tools_Pkg.put_debug_message` | 3834 |
| `Dka_Tools_Pkg.put_debug_message` | 3838 |
| `DKA_PA_TOOLS_PKG.pa_get_code_z_refac` | 3842 |
| `Dka_Tools_Pkg.get_message` | 3858 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3868 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3869 |
| `Dka_Tools_Pkg.ins_prog_message` | 3872 |
| `Dka_Tools_Pkg.put_debug_message` | 3895 |
| `Dka_Tools_Pkg.put_debug_message` | 3901 |
| `Dka_Tools_Pkg.put_debug_message` | 3941 |
| `Dka_Tools_Pkg.get_message` | 3945 |
| `Dka_Tools_Pkg.put_outdebug_message` | 3957 |
| `Dka_Tools_Pkg.ins_prog_message` | 3959 |
| `Dka_Tools_Pkg.put_debug_message` | 3977 |
| `Dka_Tools_Pkg.get_message` | 4006 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4020 |
| `Dka_Tools_Pkg.ins_prog_message` | 4022 |
| `Dka_Tools_Pkg.get_message` | 4036 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4038 |
| `Dka_Tools_Pkg.ins_prog_message` | 4039 |
| `Dka_Tools_Pkg.put_debug_message` | 4093 |
| `Fnd_Stats.Gather_Table_Stats` | 4098 |
| `Fnd_Stats.Gather_Table_Stats` | 4104 |
| `Fnd_Request.submit_request` | 4138 |
| `Fnd_Date.date_to_canonical` | 4147 |
| `Fnd_Profile.Value` | 4170 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4176 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4181 |
| `Dka_Tools_Pkg.get_message` | 4190 |
| `Dka_Tools_Pkg.ins_prog_message` | 4192 |
| `Dka_Tools_Pkg.put_debug_message` | 4243 |
| `Fnd_Request.submit_request` | 4248 |
| `Fnd_Date.date_to_canonical` | 4258 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4286 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4289 |
| `Dka_Tools_Pkg.get_message` | 4297 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4298 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4383 |
| `Dka_Tools_Pkg.put_debug_message` | 4606 |
| `Dka_Tools_Pkg.put_debug_message` | 4607 |
| `fnd_file.put_line` | 4620 |
| `Fnd_Stats.Gather_Table_Stats` | 4629 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4689 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4690 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4691 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4692 |
| `fnd_file.put_line` | 4700 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4719 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4720 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4721 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4722 |
| `dka_tools_pkg.put_debug_message` | 4740 |
| `dka_tools_pkg.put_debug_message` | 4748 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4790 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4791 |
| `Dka_Tools_Pkg.put_debug_message` | 4806 |
| `Dka_Tools_Pkg.put_debug_message` | 4807 |
| `Dka_Tools_Pkg.put_debug_message` | 4808 |
| `Dka_Tools_Pkg.put_debug_message` | 4898 |
| `Dka_Tools_Pkg.get_message` | 4903 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4913 |
| `Dka_Tools_Pkg.ins_prog_message` | 4915 |
| `Dka_Tools_Pkg.put_debug_message` | 4936 |
| `Dka_Tools_Pkg.put_debug_message` | 4978 |
| `Dka_Tools_Pkg.get_message` | 5014 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5024 |
| `Dka_Tools_Pkg.ins_prog_message` | 5026 |
| `Dka_Tools_Pkg.put_debug_message` | 5081 |
| `Dka_Tools_Pkg.put_debug_message` | 5082 |
| `Dka_Tools_Pkg.put_debug_message` | 5144 |
| `Dka_Tools_Pkg.put_debug_message` | 5179 |
| `Dka_Tools_Pkg.put_debug_message` | 5181 |
| `Dka_Tools_Pkg.put_debug_message` | 5213 |
| `Dka_Tools_Pkg.put_debug_message` | 5214 |
| `Dka_Tools_Pkg.put_debug_message` | 5215 |
| `Dka_Tools_Pkg.put_debug_message` | 5225 |
| `Dka_Tools_Pkg.put_debug_message` | 5226 |
| `Dka_Tools_Pkg.put_debug_message` | 5227 |
| `Dka_Tools_Pkg.put_debug_message` | 5274 |
| `Dka_Tools_Pkg.get_message` | 5296 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5306 |
| `Dka_Tools_Pkg.ins_prog_message` | 5308 |
| `Dka_Tools_Pkg.get_message` | 5333 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5344 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5345 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5346 |
| `Dka_Tools_Pkg.ins_prog_message` | 5350 |
| `Dka_Tools_Pkg.put_debug_message` | 5391 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5392 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5417 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5420 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5423 |
| `Dka_Tools_Pkg.put_debug_message` | 5444 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5447 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5448 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5451 |
| `fnd_file.put_line` | 5465 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5468 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5471 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5472 |
| `Dka_Tools_Pkg.put_log_message` | 5484 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5493 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5494 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5517 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5528 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5529 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5530 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5531 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5532 |
| `Dka_Tools_Pkg.get_message` | 5535 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5536 |
| `Fnd_Concurrent.wait_for_request` | 5545 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5554 |
| `Dka_Tools_Pkg.put_debug_message` | 5558 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5560 |
| `Dka_Tools_Pkg.put_log_message` | 5567 |
| `Dka_Tools_Pkg.put_debug_message` | 5580 |
| `Dka_Tools_Pkg.put_debug_message` | 5581 |
| `Dka_Tools_Pkg.put_debug_message` | 5582 |
| `Dka_Tools_Pkg.put_outdebug_message` | 5588 |
| `Dka_Tools_Pkg.put_debug_message` | 5589 |
| `Dka_Tools_Pkg.ins_prog_message` | 5591 |

## Programmes soumis, littéraux détectés

| Élément | Ligne source |
|---|---:|
| `RAXMTR` | 4138 |
| `RAXMTR` | 4248 |

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 4182, 4290, 4679, 4758, 5376, 5395, 5452, 5569, 5574 |
| rollback | 5273, 5382, 5409, 5456 |
| when_others | 217, 227, 278, 342, 423, 510, 699, 817, 845, 934, 1419, 1451, 1773, 1962, 2132, 2248, 2360, 2485, 2569, 2771, 2945, 3092, 3229, 3462, 3727, 4034, 4188, 4295, 4380, 4878, 5271, 5397, 5407, 5454, 5533, 5584 |
| soumission | 4138, 4248 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IARPAFAC / DKA | `DKA_IARPAFAC_PKG.Main` | dka/12.0.0/admin/import/DKA_IARPAFAC.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
