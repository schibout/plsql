# DKA_IHREMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IHREMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IHREMP_PKG.pkb).

Famille proposée par convention de nommage : **RH / employés**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 8813 ; encodage : cp1252 (repli). SHA-256 : `5aa092b1d16b5625cdfe09483cf13631a7ee2a6b9829262d8dda724474d0cf62`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_time` | 106 |
| `log_message` | 119 |
| `out_message` | 136 |
| `init` | 150 |
| `get_value_from_set` | 334 |
| `purge_table_xxeai` | 364 |
| `insert_error` | 493 |
| `flag_traite` | 592 |
| `get_person_id` | 673 |
| `get_person_info` | 717 |
| `get_assign_info` | 773 |
| `get_supplier_info` | 948 |
| `get_supplier_site_info` | 990 |
| `get_currency_code` | 1042 |
| `get_job_id` | 1083 |
| `get_bank_info` | 1137 |
| `get_info_compte_bank` | 1192 |
| `get_info_acct_emp` | 1245 |
| `get_cpt_bank_emp` | 1301 |
| `get_period_gl` | 1373 |
| `is_EX_employee` | 1425 |
| `terminate_employee` | 1467 |
| `reactivate_employee` | 1602 |
| `creation_employe` | 1702 |
| `maj_employe` | 3549 |
| `daily_internal_updates` | 7178 |
| `affichage_fichier_sortie` | 8529 |
| `main` | 8624 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_terms` | 199 |
| `PER_JOB_GROUPS` | 206 |
| `xxeai_hr_people_int` | 214 |
| `per_all_people_f` | 217 |
| `xxeai_hr_bank_int_all` | 227 |
| `per_all_people_f` | 230 |
| `xxeai_hr_assignment_int` | 240 |
| `per_all_people_f` | 243 |
| `XXEAI_HR_BANK_INT_ALL` | 289 |
| `per_all_people_f` | 297 |
| `fnd_flex_value_sets` | 342 |
| `XXEAI_HR_PEOPLE_INT` | 372 |
| `XXEAI_HR_ASSIGNMENT_INT` | 376 |
| `XXEAI_HR_BANK_INT_ALL` | 377 |
| `XXEAI_HR_BANK_INT_ALL` | 378 |
| `XXEAI_HR_PEOPLE_INT` | 391 |
| `XXEAI_HR_ASSIGNMENT_INT` | 394 |
| `XXEAI_HR_BANK_INT_ALL` | 397 |
| `XXEAI_HR_PEOPLE_INT` | 402 |
| `XXEAI_HR_BANK_INT_ALL` | 406 |
| `XXEAI_HR_PEOPLE_INT` | 408 |
| `XXEAI_HR_INT_ERRORS_ALL` | 414 |
| `XXEAI_HR_PEOPLE_INT` | 417 |
| `XXEAI_HR_PEOPLE_INT` | 419 |
| `XXEAI_HR_PEOPLE_INT` | 424 |
| `XXEAI_HR_PEOPLE_INT` | 430 |
| `XXEAI_HR_PEOPLE_INT` | 432 |
| `XXEAI_HR_PEOPLE_INT` | 437 |
| `XXEAI_HR_BANK_INT_ALL` | 443 |
| `XXEAI_HR_BANK_INT_ALL` | 445 |
| `XXEAI_HR_BANK_INT_ALL` | 449 |
| `XXEAI_HR_ASSIGNMENT_INT` | 453 |
| `XXEAI_HR_ASSIGNMENT_INT` | 455 |
| `XXEAI_HR_ASSIGNMENT_INT` | 459 |
| `XXEAI_HR_PEOPLE_INT` | 465 |
| `XXEAI_HR_ASSIGNMENT_INT` | 466 |
| `XXEAI_HR_BANK_INT_ALL` | 467 |
| `XXEAI_HR_INT_ERRORS_ALL` | 513 |
| `XXEAI_HR_PEOPLE_INT` | 545 |
| `XXEAI_HR_ASSIGNMENT_INT` | 547 |
| `XXEAI_HR_PEOPLE_INT` | 547 |
| `XXEAI_HR_BANK_INT_ALL` | 548 |
| `XXEAI_HR_PEOPLE_INT` | 548 |
| `XXEAI_HR_ASSIGNMENT_INT` | 551 |
| `XXEAI_HR_PEOPLE_INT` | 552 |
| `XXEAI_HR_ASSIGNMENT_INT` | 552 |
| `XXEAI_HR_BANK_INT_ALL` | 553 |
| `XXEAI_HR_ASSIGNMENT_INT` | 553 |
| `XXEAI_HR_BANK_INT_ALL` | 555 |
| `XXEAI_HR_PEOPLE_INT` | 556 |
| `XXEAI_HR_BANK_INT_ALL` | 556 |
| `XXEAI_HR_ASSIGNMENT_INT` | 557 |
| `XXEAI_HR_BANK_INT_ALL` | 557 |
| `XXEAI_HR_PEOPLE_INT` | 562 |
| `XXEAI_HR_ASSIGNMENT_INT` | 564 |
| `XXEAI_HR_BANK_INT_ALL` | 566 |
| `XXEAI_HR_PEOPLE_INT` | 608 |
| `XXEAI_HR_ASSIGNMENT_INT` | 623 |
| `XXEAI_HR_BANK_INT_ALL` | 637 |
| `per_all_people_f` | 685 |
| `per_all_people_f` | 726 |
| `per_all_people_f` | 834 |
| `per_all_assignments_f` | 851 |
| `per_all_people_f` | 901 |
| `per_all_assignments_f` | 912 |
| `ap_suppliers` | 961 |
| `ap_suppliers` | 1007 |
| `gl_ledgers` | 1054 |
| `per_jobs` | 1097 |
| `per_jobs` | 1105 |
| `CE_BANK_BRANCHES_V` | 1152 |
| `IBY_EXT_BANK_ACCOUNTS` | 1208 |
| `iby_pmt_instr_uses_all` | 1262 |
| `iby_pmt_instr_uses_all` | 1310 |
| `gl_period_statuses` | 1391 |
| `per_person_types` | 1435 |
| `per_periods_of_service` | 1512 |
| `per_all_assignments_f` | 1656 |
| `per_all_assignments_f` | 1665 |
| `xxeai_hr_assignment_int` | 1737 |
| `xxeai_hr_assignment_int` | 1739 |
| `xxeai_hr_assignment_int` | 1744 |
| `xxeai_hr_assignment_int` | 1746 |
| `xxeai_hr_people_int` | 1749 |
| `xxeai_hr_people_int` | 1760 |
| `xxeai_hr_people_int` | 1767 |
| `XXEAI_HR_PEOPLE_INT` | 2069 |
| `XXEAI_HR_ASSIGNMENT_INT` | 2222 |
| `apps.fnd_flex_value_sets` | 2324 |
| `DUAL` | 2329 |
| `Employee` | 2504 |
| `Employee` | 2571 |
| `ap.ap_suppliers` | 2683 |
| `XXEAI_HR_BANK_INT_ALL` | 2955 |
| `iby_external_payees_all` | 3293 |
| `iby_external_payees_all` | 3318 |
| `iby_external_payees_all` | 3325 |
| `PER_PERIODS_OF_SERVICE` | 3494 |
| `PER_ALL_PEOPLE_F` | 3497 |
| `PER_ALL_PEOPLE_F` | 3500 |
| `PER_ALL_ASSIGNMENTS_F` | 3506 |
| `PER_ALL_PEOPLE_F` | 3509 |
| `PER_ADDRESSES` | 3512 |
| `PER_ALL_PEOPLE_F` | 3515 |
| `XXEAI_HR_PEOPLE_INT` | 3556 |
| `XXEAI_HR_PEOPLE_INT` | 3564 |
| `XXEAI_HR_PEOPLE_INT` | 3572 |
| `XXEAI_HR_BANK_INT_ALL` | 3581 |
| `XXEAI_HR_PEOPLE_INT` | 3584 |
| `XXEAI_HR_PEOPLE_INT` | 3957 |
| `per_all_people_f` | 4018 |
| `XXEAI_HR_ASSIGNMENT_INT` | 4177 |
| `Employee` | 4531 |
| `Employee` | 4612 |
| `du` | 4720 |
| `du` | 4735 |
| `ap_suppliers` | 4742 |
| `XXEAI_HR_BANK_INT_ALL` | 5161 |
| `iby_external_payees_all` | 5794 |
| `iby_external_payees_all` | 5819 |
| `iby_external_payees_all` | 5826 |
| `ap_payment_schedules_all` | 5955 |
| `ap_invoices_all` | 5965 |
| `EMPLOYE` | 5986 |
| `employé` | 5989 |
| `XXEAI_HR_PEOPLE_INT` | 6048 |
| `EMPLOYE` | 6176 |
| `XXEAI_HR_PEOPLE_INT` | 6228 |
| `EMPLOYE` | 6289 |
| `iby_external_payees_all` | 6984 |
| `iby_external_payees_all` | 7009 |
| `iby_external_payees_all` | 7016 |
| `ap_payment_schedules_all` | 7092 |
| `ap_invoices_all` | 7100 |
| `ap_payment_schedules_all` | 7105 |
| `ap_invoices_all` | 7114 |
| `per_all_assignments_f` | 7192 |
| `per_person_types` | 7202 |
| `per_all_people_f` | 7218 |
| `per_all_assignments_f` | 7227 |
| `per_person_types` | 7237 |
| `per_all_assignments_f` | 7245 |
| `ap_supplier_sites_all` | 7267 |
| `per_person_types` | 7273 |
| `per_person_types` | 7283 |
| `per_person_types` | 7298 |
| `per_person_types` | 7308 |
| `per_all_assignments_f` | 7320 |
| `pa_tasks` | 7324 |
| `per_person_types` | 7346 |
| `Employee` | 7514 |
| `iby_external_payees_all` | 8043 |
| `iby_external_payees_all` | 8068 |
| `iby_external_payees_all` | 8075 |
| `Employee` | 8256 |
| `Employee` | 8329 |
| `XXEAI_HR_INT_ERRORS_ALL` | 8536 |
| `XXEAI_HR_PEOPLE_INT` | 8559 |
| `XXEAI_HR_BANK_INT_ALL` | 8574 |
| `XXEAI_HR_PEOPLE_INT` | 8577 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 124 |
| `dka_tools_pkg.put_outdebug_message` | 139 |
| `fnd_profile.value` | 170 |
| `fnd_profile.value` | 171 |
| `fnd_profile.value` | 172 |
| `Dka_Tools_Pkg.get_parameter` | 256 |
| `Dka_Tools_Pkg.get_parameter` | 271 |
| `dka_tools_pkg.get_message` | 2100 |
| `dka_tools_pkg.get_message` | 2157 |
| `dka_tools_pkg.get_message` | 2179 |
| `dka_tools_pkg.get_message` | 2205 |
| `dka_tools_pkg.get_message` | 2234 |
| `dka_tools_pkg.get_message` | 2240 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 2257 |
| `dka_tools_pkg.get_message` | 2276 |
| `dka_tools_pkg.get_message` | 2290 |
| `dka_tools_pkg.get_message` | 2305 |
| `dka_gl_tools_pkg.get_legder_id` | 2430 |
| `dka_tools_pkg.get_message` | 2434 |
| `dka_tools_pkg.get_message` | 2447 |
| `dka_tools_pkg.get_message` | 2460 |
| `dka_tools_pkg.get_message` | 2530 |
| `dka_tools_pkg.get_message` | 2600 |
| `ap_vendor_pub_pkg.create_vendor` | 2664 |
| `fnd_msg_pub.get` | 2693 |
| `dka_tools_pkg.get_message` | 2701 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2720 |
| `dka_tools_pkg.get_message` | 2740 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2749 |
| `dka_tools_pkg.get_message` | 2770 |
| `ap_vendor_pub_pkg.create_vendor_site` | 2825 |
| `fnd_msg_pub.get` | 2847 |
| `dka_tools_pkg.get_message` | 2855 |
| `hz_location_v2pub.create_location` | 2872 |
| `fnd_msg_pub.get` | 2888 |
| `dka_tools_pkg.get_message` | 2896 |
| `ap_vendor_pub_pkg.Update_Vendor_Site` | 2912 |
| `fnd_msg_pub.get` | 2931 |
| `dka_tools_pkg.get_message` | 2939 |
| `dka_tools_pkg.get_message` | 2971 |
| `dka_tools_pkg.get_message` | 2995 |
| `IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT` | 3048 |
| `fnd_msg_pub.get` | 3075 |
| `dka_tools_pkg.get_message` | 3081 |
| `IBY_EXT_BANKACCT_PUB.check_bank_acct_owner` | 3106 |
| `IBY_EXT_BANKACCT_PUB.add_joint_account_owner` | 3131 |
| `fnd_msg_pub.get` | 3151 |
| `dka_tools_pkg.get_message` | 3157 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 3202 |
| `fnd_msg_pub.get` | 3223 |
| `dka_tools_pkg.get_message` | 3229 |
| `dka_tools_pkg.get_message` | 3331 |
| `dka_tools_pkg.get_message` | 3339 |
| `IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee` | 3354 |
| `fnd_msg_pub.get` | 3373 |
| `dka_tools_pkg.get_message` | 3388 |
| `IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee` | 3402 |
| `fnd_msg_pub.get` | 3423 |
| `dka_tools_pkg.get_message` | 3438 |
| `dka_tools_pkg.get_message` | 3980 |
| `dka_tools_pkg.get_message` | 4095 |
| `FND_USER_PKG.userExists` | 4113 |
| `FND_USER_PKG.UpdateUser` | 4116 |
| `dka_tools_pkg.get_message` | 4125 |
| `dka_tools_pkg.get_message` | 4188 |
| `dka_tools_pkg.get_message` | 4193 |
| `dka_tools_pkg.get_message` | 4231 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 4241 |
| `dka_tools_pkg.get_message` | 4260 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 4269 |
| `dka_tools_pkg.get_message` | 4288 |
| `dka_gl_tools_pkg.get_legder_id` | 4297 |
| `dka_tools_pkg.get_message` | 4301 |
| `dka_tools_pkg.get_message` | 4317 |
| `dka_tools_pkg.get_message` | 4331 |
| `dka_tools_pkg.get_message` | 4346 |
| `dka_tools_pkg.get_message` | 4360 |
| `dka_tools_pkg.get_message` | 4380 |
| `dka_tools_pkg.get_message` | 4429 |
| `dka_tools_pkg.get_message` | 4571 |
| `dka_tools_pkg.get_message` | 4640 |
| `dka_tools_pkg.get_message` | 4689 |
| `dka_tools_pkg.get_message` | 4701 |
| `ap_vendor_pub_pkg.Update_Vendor` | 4721 |
| `fnd_msg_pub.get` | 4752 |
| `dka_tools_pkg.get_message` | 4760 |
| `dka_tools_pkg.get_message` | 4817 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 4826 |
| `dka_tools_pkg.get_message` | 4845 |
| `dka_tools_pkg.get_message` | 4857 |
| `dka_gl_tools_pkg.get_legder_id` | 4873 |
| `dka_tools_pkg.get_message` | 4877 |
| `dka_tools_pkg.get_message` | 4890 |
| `Dka_Tools_Pkg.get_code_combination_id` | 4899 |
| `dka_tools_pkg.get_message` | 4919 |
| `Dka_Tools_Pkg.get_code_combination_id` | 4928 |
| `dka_tools_pkg.get_message` | 4949 |
| `ap_vendor_pub_pkg.create_vendor_site` | 5003 |
| `fnd_msg_pub.get` | 5025 |
| `dka_tools_pkg.get_message` | 5033 |
| `hz_location_v2pub.create_location` | 5051 |
| `fnd_msg_pub.get` | 5067 |
| `dka_tools_pkg.get_message` | 5075 |
| `ap_vendor_pub_pkg.Update_Vendor_Site` | 5091 |
| `fnd_msg_pub.get` | 5110 |
| `dka_tools_pkg.get_message` | 5118 |
| `dka_tools_pkg.get_message` | 5177 |
| `dka_tools_pkg.get_message` | 5211 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 5220 |
| `dka_tools_pkg.get_message` | 5239 |
| `dka_tools_pkg.get_message` | 5251 |
| `dka_gl_tools_pkg.get_legder_id` | 5260 |
| `dka_tools_pkg.get_message` | 5264 |
| `dka_tools_pkg.get_message` | 5277 |
| `dka_tools_pkg.get_message` | 5294 |
| `IBY_EXT_BANKACCT_PUB.set_ext_bank_acct_dates` | 5335 |
| `fnd_msg_pub.get` | 5356 |
| `dka_tools_pkg.get_message` | 5362 |
| `IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT` | 5407 |
| `fnd_msg_pub.get` | 5434 |
| `dka_tools_pkg.get_message` | 5440 |
| `IBY_EXT_BANKACCT_PUB.check_bank_acct_owner` | 5463 |
| `IBY_EXT_BANKACCT_PUB.add_joint_account_owner` | 5488 |
| `fnd_msg_pub.get` | 5508 |
| `dka_tools_pkg.get_message` | 5514 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 5557 |
| `fnd_msg_pub.get` | 5578 |
| `dka_tools_pkg.get_message` | 5584 |
| `IBY_EXT_BANKACCT_PUB.check_bank_acct_owner` | 5620 |
| `IBY_EXT_BANKACCT_PUB.add_joint_account_owner` | 5645 |
| `fnd_msg_pub.get` | 5665 |
| `dka_tools_pkg.get_message` | 5671 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 5713 |
| `fnd_msg_pub.get` | 5734 |
| `dka_tools_pkg.get_message` | 5740 |
| `dka_tools_pkg.get_message` | 5832 |
| `dka_tools_pkg.get_message` | 5840 |
| `IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee` | 5857 |
| `fnd_msg_pub.get` | 5876 |
| `dka_tools_pkg.get_message` | 5891 |
| `IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee` | 5905 |
| `fnd_msg_pub.get` | 5926 |
| `dka_tools_pkg.get_message` | 5941 |
| `dka_tools_pkg.get_message` | 6029 |
| `dka_tools_pkg.get_message` | 6130 |
| `FND_USER_PKG.userExists` | 6148 |
| `FND_USER_PKG.UpdateUser` | 6150 |
| `dka_tools_pkg.get_message` | 6159 |
| `dka_tools_pkg.get_message` | 6241 |
| `dka_tools_pkg.get_message` | 6494 |
| `dka_tools_pkg.get_message` | 6522 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 6531 |
| `dka_tools_pkg.get_message` | 6550 |
| `dka_tools_pkg.get_message` | 6562 |
| `dka_tools_pkg.get_message` | 6574 |
| `dka_gl_tools_pkg.get_legder_id` | 6582 |
| `dka_tools_pkg.get_message` | 6586 |
| `dka_tools_pkg.get_message` | 6599 |
| `dka_tools_pkg.get_message` | 6640 |
| `IBY_EXT_BANKACCT_PUB.set_ext_bank_acct_dates` | 6694 |
| `fnd_msg_pub.get` | 6715 |
| `dka_tools_pkg.get_message` | 6721 |
| `IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT` | 6763 |
| `fnd_msg_pub.get` | 6790 |
| `dka_tools_pkg.get_message` | 6796 |
| `IBY_EXT_BANKACCT_PUB.check_bank_acct_owner` | 6818 |
| `IBY_EXT_BANKACCT_PUB.add_joint_account_owner` | 6843 |
| `fnd_msg_pub.get` | 6863 |
| `dka_tools_pkg.get_message` | 6869 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 6902 |
| `fnd_msg_pub.get` | 6923 |
| `dka_tools_pkg.get_message` | 6929 |
| `dka_tools_pkg.get_message` | 7022 |
| `dka_tools_pkg.get_message` | 7030 |
| `IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee` | 7047 |
| `fnd_msg_pub.get` | 7068 |
| `dka_tools_pkg.get_message` | 7083 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 7601 |
| `dka_gl_tools_pkg.get_legder_id` | 7633 |
| `Dka_Tools_Pkg.get_code_combination_id` | 7649 |
| `Dka_Tools_Pkg.get_code_combination_id` | 7673 |
| `ap_vendor_pub_pkg.create_vendor_site` | 7743 |
| `fnd_msg_pub.get` | 7765 |
| `hz_location_v2pub.create_location` | 7787 |
| `fnd_msg_pub.get` | 7803 |
| `ap_vendor_pub_pkg.Update_Vendor_Site` | 7824 |
| `fnd_msg_pub.get` | 7843 |
| `IBY_EXT_BANKACCT_PUB.check_bank_acct_owner` | 7877 |
| `IBY_EXT_BANKACCT_PUB.add_joint_account_owner` | 7902 |
| `fnd_msg_pub.get` | 7922 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 7965 |
| `fnd_msg_pub.get` | 7986 |
| `IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee` | 8101 |
| `fnd_msg_pub.get` | 8120 |
| `IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee` | 8146 |
| `fnd_msg_pub.get` | 8167 |
| `ap_vendor_pub_pkg.Update_Vendor_Site` | 8389 |
| `fnd_msg_pub.get` | 8410 |
| `ap_vendor_pub_pkg.Update_Vendor_Site` | 8459 |
| `fnd_msg_pub.get` | 8480 |
| `dka_tools_pkg.get_message` | 8564 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 469, 470, 570, 571, 649, 650, 2407, 3455, 3464, 3518, 5986, 5990, 6176, 6186, 6289, 6299, 7149, 7152, 7547, 7548 |
| rollback | 578, 2203, 3471, 3481, 3533, 4151, 4157, 4663, 4779, 5142, 5980, 5999, 6170, 6192, 6199, 6306, 6313, 7136, 7144, 7161, 7553, 7558, 8198, 8203, 8286, 8359, 8427, 8432, 8497, 8502 |
| transaction_autonome | 501, 597 |
| when_others | 316, 476, 577, 656, 699, 755, 924, 930, 972, 1025, 1066, 1119, 1171, 1223, 1283, 1351, 1408, 1450, 1585, 1687, 2178, 2202, 2409, 2528, 2598, 3329, 3337, 3473, 3532, 4123, 4154, 4569, 4638, 5830, 5838, 5994, 6157, 6194, 6261, 6280, 6308, 6659, 6670, 7020, 7028, 7139, 7160, 7541, 7555, 8079, 8084, 8200, 8283, 8356, 8429, 8499, 8512, 8605, 8801 |
| suppression | 391, 394, 397, 402, 406, 414, 417, 430, 443, 453 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IHREMP_INTERFACE / DKA | `DKA_IHREMP_PKG.main` | dka/12.0.0/admin/import/DKA_IHREMP.prt:488 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
