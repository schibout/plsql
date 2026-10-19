# DKA_IHREMP_GXP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IHREMP_GXP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IHREMP_GXP_PKG.pkb).

Famille proposée par convention de nommage : **RH / employés**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 7135 ; encodage : cp1252 (repli). SHA-256 : `2ac21a50366317539b53811cf47fdb9b1d455a2d944b55af463081f80af23ac0`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_time` | 82 |
| `log_message` | 95 |
| `out_message` | 112 |
| `init` | 126 |
| `purge_table_xxeai` | 249 |
| `insert_error` | 369 |
| `flag_traite` | 468 |
| `get_person_id` | 544 |
| `get_person_info` | 588 |
| `get_assign_info` | 644 |
| `get_supplier_info` | 742 |
| `get_supplier_site_info` | 784 |
| `get_currency_code` | 836 |
| `get_job_id` | 877 |
| `get_bank_info` | 931 |
| `get_info_compte_bank` | 986 |
| `get_info_acct_emp` | 1039 |
| `get_cpt_bank_emp` | 1093 |
| `get_period_gl` | 1164 |
| `is_EX_employee` | 1216 |
| `terminate_employee` | 1258 |
| `reactivate_employee` | 1383 |
| `creation_employe` | 1440 |
| `maj_employe` | 3070 |
| `daily_internal_updates` | 5549 |
| `affichage_fichier_sortie` | 6889 |
| `main` | 6965 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_terms` | 175 |
| `PER_JOB_GROUPS` | 182 |
| `xxeai_hr_people_int` | 191 |
| `per_all_people_f` | 194 |
| `xxeai_hr_bank_int_all` | 204 |
| `per_all_people_f` | 207 |
| `xxeai_hr_assignment_int` | 217 |
| `per_all_people_f` | 220 |
| `XXEAI_HR_PEOPLE_INT` | 257 |
| `XXEAI_HR_ASSIGNMENT_INT` | 261 |
| `XXEAI_HR_BANK_INT_ALL` | 262 |
| `XXEAI_HR_BANK_INT_ALL` | 263 |
| `XXEAI_HR_PEOPLE_INT` | 276 |
| `XXEAI_HR_ASSIGNMENT_INT` | 279 |
| `XXEAI_HR_BANK_INT_ALL` | 282 |
| `XXEAI_HR_PEOPLE_INT` | 287 |
| `XXEAI_HR_INT_ERRORS_ALL` | 290 |
| `XXEAI_HR_PEOPLE_INT` | 293 |
| `XXEAI_HR_PEOPLE_INT` | 295 |
| `XXEAI_HR_PEOPLE_INT` | 300 |
| `XXEAI_HR_PEOPLE_INT` | 306 |
| `XXEAI_HR_PEOPLE_INT` | 308 |
| `XXEAI_HR_PEOPLE_INT` | 313 |
| `XXEAI_HR_BANK_INT_ALL` | 319 |
| `XXEAI_HR_BANK_INT_ALL` | 321 |
| `XXEAI_HR_BANK_INT_ALL` | 325 |
| `XXEAI_HR_ASSIGNMENT_INT` | 329 |
| `XXEAI_HR_ASSIGNMENT_INT` | 331 |
| `XXEAI_HR_ASSIGNMENT_INT` | 335 |
| `XXEAI_HR_PEOPLE_INT` | 341 |
| `XXEAI_HR_ASSIGNMENT_INT` | 342 |
| `XXEAI_HR_BANK_INT_ALL` | 343 |
| `XXEAI_HR_INT_ERRORS_ALL` | 389 |
| `XXEAI_HR_PEOPLE_INT` | 421 |
| `XXEAI_HR_ASSIGNMENT_INT` | 423 |
| `XXEAI_HR_PEOPLE_INT` | 423 |
| `XXEAI_HR_BANK_INT_ALL` | 424 |
| `XXEAI_HR_PEOPLE_INT` | 424 |
| `XXEAI_HR_ASSIGNMENT_INT` | 427 |
| `XXEAI_HR_PEOPLE_INT` | 428 |
| `XXEAI_HR_ASSIGNMENT_INT` | 428 |
| `XXEAI_HR_BANK_INT_ALL` | 429 |
| `XXEAI_HR_ASSIGNMENT_INT` | 429 |
| `XXEAI_HR_BANK_INT_ALL` | 431 |
| `XXEAI_HR_PEOPLE_INT` | 432 |
| `XXEAI_HR_BANK_INT_ALL` | 432 |
| `XXEAI_HR_ASSIGNMENT_INT` | 433 |
| `XXEAI_HR_BANK_INT_ALL` | 433 |
| `XXEAI_HR_PEOPLE_INT` | 438 |
| `XXEAI_HR_ASSIGNMENT_INT` | 440 |
| `XXEAI_HR_BANK_INT_ALL` | 442 |
| `XXEAI_HR_PEOPLE_INT` | 482 |
| `XXEAI_HR_ASSIGNMENT_INT` | 497 |
| `XXEAI_HR_BANK_INT_ALL` | 511 |
| `per_all_people_f` | 556 |
| `per_all_people_f` | 597 |
| `per_all_people_f` | 699 |
| `ap_suppliers` | 755 |
| `ap_suppliers` | 801 |
| `gl_ledgers` | 848 |
| `per_jobs` | 891 |
| `per_jobs` | 899 |
| `CE_BANK_BRANCHES_V` | 946 |
| `IBY_EXT_BANK_ACCOUNTS` | 1002 |
| `iby_pmt_instr_uses_all` | 1055 |
| `iby_pmt_instr_uses_all` | 1102 |
| `gl_period_statuses` | 1182 |
| `per_person_types` | 1226 |
| `per_periods_of_service` | 1295 |
| `xxeai_hr_people_int` | 1447 |
| `xxeai_hr_people_int` | 1456 |
| `xxeai_hr_people_int` | 1462 |
| `XXEAI_HR_PEOPLE_INT` | 1743 |
| `XXEAI_HR_ASSIGNMENT_INT` | 1872 |
| `Employee` | 2032 |
| `Employee` | 2099 |
| `XXEAI_HR_BANK_INT_ALL` | 2517 |
| `iby_external_payees_all` | 2853 |
| `iby_external_payees_all` | 2878 |
| `iby_external_payees_all` | 2885 |
| `XXEAI_HR_PEOPLE_INT` | 3077 |
| `XXEAI_HR_PEOPLE_INT` | 3085 |
| `XXEAI_HR_PEOPLE_INT` | 3093 |
| `XXEAI_HR_PEOPLE_INT` | 3437 |
| `XXEAI_HR_ASSIGNMENT_INT` | 3608 |
| `Employee` | 3914 |
| `Employee` | 3981 |
| `du` | 4088 |
| `du` | 4103 |
| `XXEAI_HR_BANK_INT_ALL` | 4561 |
| `iby_external_payees_all` | 5034 |
| `iby_external_payees_all` | 5059 |
| `iby_external_payees_all` | 5066 |
| `ap_payment_schedules_all` | 5195 |
| `ap_invoices_all` | 5205 |
| `EMPLOYE` | 5226 |
| `employé` | 5229 |
| `XXEAI_HR_PEOPLE_INT` | 5287 |
| `EMPLOYE` | 5402 |
| `XXEAI_HR_PEOPLE_INT` | 5453 |
| `EMPLOYE` | 5498 |
| `per_all_assignments_f` | 5563 |
| `per_all_people_f` | 5582 |
| `per_all_assignments_f` | 5591 |
| `per_all_assignments_f` | 5602 |
| `ap_supplier_sites_all` | 5624 |
| `per_person_types` | 5634 |
| `per_person_types` | 5653 |
| `per_all_assignments_f` | 5667 |
| `Employee` | 5844 |
| `iby_external_payees_all` | 6405 |
| `iby_external_payees_all` | 6430 |
| `iby_external_payees_all` | 6437 |
| `Employee` | 6616 |
| `Employee` | 6689 |
| `XXEAI_HR_INT_ERRORS_ALL` | 6896 |
| `XXEAI_HR_PEOPLE_INT` | 6919 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_log_message` | 100 |
| `dka_tools_pkg.put_outdebug_message` | 115 |
| `fnd_profile.value` | 146 |
| `fnd_profile.value` | 147 |
| `fnd_profile.value` | 148 |
| `dka_tools_pkg.get_message` | 1762 |
| `dka_tools_pkg.get_message` | 1816 |
| `dka_tools_pkg.get_message` | 1831 |
| `dka_tools_pkg.get_message` | 1857 |
| `dka_tools_pkg.get_message` | 1883 |
| `dka_tools_pkg.get_message` | 1888 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 1900 |
| `dka_tools_pkg.get_message` | 1919 |
| `dka_tools_pkg.get_message` | 1933 |
| `dka_tools_pkg.get_message` | 1948 |
| `dka_gl_tools_pkg.get_legder_id` | 1958 |
| `dka_tools_pkg.get_message` | 1962 |
| `dka_tools_pkg.get_message` | 1975 |
| `dka_tools_pkg.get_message` | 1988 |
| `dka_tools_pkg.get_message` | 2058 |
| `dka_tools_pkg.get_message` | 2128 |
| `ap_vendor_pub_pkg.create_vendor` | 2192 |
| `fnd_msg_pub.get` | 2214 |
| `dka_tools_pkg.get_message` | 2222 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2241 |
| `dka_tools_pkg.get_message` | 2261 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2270 |
| `dka_tools_pkg.get_message` | 2291 |
| `ap_vendor_pub_pkg.create_vendor_site` | 2345 |
| `fnd_msg_pub.get` | 2367 |
| `dka_tools_pkg.get_message` | 2375 |
| `hz_location_v2pub.create_location` | 2392 |
| `fnd_msg_pub.get` | 2408 |
| `dka_tools_pkg.get_message` | 2416 |
| `hz_party_site_v2pub.create_party_site` | 2430 |
| `fnd_msg_pub.get` | 2449 |
| `dka_tools_pkg.get_message` | 2457 |
| `ap_vendor_pub_pkg.update_vendor_site` | 2474 |
| `fnd_msg_pub.get` | 2493 |
| `dka_tools_pkg.get_message` | 2501 |
| `dka_tools_pkg.get_message` | 2533 |
| `dka_tools_pkg.get_message` | 2557 |
| `IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT` | 2608 |
| `fnd_msg_pub.get` | 2635 |
| `dka_tools_pkg.get_message` | 2641 |
| `IBY_EXT_BANKACCT_PUB.check_bank_acct_owner` | 2666 |
| `IBY_EXT_BANKACCT_PUB.add_joint_account_owner` | 2691 |
| `fnd_msg_pub.get` | 2711 |
| `dka_tools_pkg.get_message` | 2717 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 2762 |
| `fnd_msg_pub.get` | 2783 |
| `dka_tools_pkg.get_message` | 2789 |
| `dka_tools_pkg.get_message` | 2891 |
| `dka_tools_pkg.get_message` | 2899 |
| `IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee` | 2914 |
| `fnd_msg_pub.get` | 2933 |
| `dka_tools_pkg.get_message` | 2948 |
| `IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee` | 2962 |
| `fnd_msg_pub.get` | 2983 |
| `dka_tools_pkg.get_message` | 2998 |
| `dka_tools_pkg.get_message` | 3460 |
| `dka_tools_pkg.get_message` | 3551 |
| `FND_USER_PKG.UpdateUser` | 3562 |
| `dka_tools_pkg.get_message` | 3569 |
| `dka_tools_pkg.get_message` | 3619 |
| `dka_tools_pkg.get_message` | 3624 |
| `dka_tools_pkg.get_message` | 3654 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 3663 |
| `dka_tools_pkg.get_message` | 3682 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 3691 |
| `dka_tools_pkg.get_message` | 3710 |
| `dka_gl_tools_pkg.get_legder_id` | 3719 |
| `dka_tools_pkg.get_message` | 3723 |
| `dka_tools_pkg.get_message` | 3739 |
| `dka_tools_pkg.get_message` | 3753 |
| `dka_tools_pkg.get_message` | 3768 |
| `dka_tools_pkg.get_message` | 3782 |
| `dka_tools_pkg.get_message` | 3800 |
| `dka_tools_pkg.get_message` | 3844 |
| `dka_tools_pkg.get_message` | 3940 |
| `dka_tools_pkg.get_message` | 4009 |
| `dka_tools_pkg.get_message` | 4058 |
| `dka_tools_pkg.get_message` | 4069 |
| `ap_vendor_pub_pkg.update_vendor` | 4089 |
| `fnd_msg_pub.get` | 4111 |
| `dka_tools_pkg.get_message` | 4119 |
| `dka_tools_pkg.get_message` | 4176 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 4185 |
| `dka_tools_pkg.get_message` | 4204 |
| `dka_tools_pkg.get_message` | 4216 |
| `dka_gl_tools_pkg.get_legder_id` | 4232 |
| `dka_tools_pkg.get_message` | 4236 |
| `dka_tools_pkg.get_message` | 4249 |
| `Dka_Tools_Pkg.get_code_combination_id` | 4258 |
| `dka_tools_pkg.get_message` | 4278 |
| `Dka_Tools_Pkg.get_code_combination_id` | 4287 |
| `dka_tools_pkg.get_message` | 4308 |
| `ap_vendor_pub_pkg.create_vendor_site` | 4362 |
| `fnd_msg_pub.get` | 4384 |
| `dka_tools_pkg.get_message` | 4392 |
| `hz_location_v2pub.create_location` | 4409 |
| `fnd_msg_pub.get` | 4425 |
| `dka_tools_pkg.get_message` | 4433 |
| `hz_party_site_v2pub.create_party_site` | 4447 |
| `fnd_msg_pub.get` | 4466 |
| `dka_tools_pkg.get_message` | 4474 |
| `ap_vendor_pub_pkg.update_vendor_site` | 4491 |
| `fnd_msg_pub.get` | 4510 |
| `dka_tools_pkg.get_message` | 4518 |
| `dka_tools_pkg.get_message` | 4577 |
| `dka_tools_pkg.get_message` | 4611 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 4620 |
| `dka_tools_pkg.get_message` | 4639 |
| `dka_tools_pkg.get_message` | 4651 |
| `dka_gl_tools_pkg.get_legder_id` | 4660 |
| `dka_tools_pkg.get_message` | 4664 |
| `dka_tools_pkg.get_message` | 4677 |
| `dka_tools_pkg.get_message` | 4694 |
| `IBY_EXT_BANKACCT_PUB.set_ext_bank_acct_dates` | 4733 |
| `fnd_msg_pub.get` | 4754 |
| `dka_tools_pkg.get_message` | 4760 |
| `IBY_EXT_BANKACCT_PUB.CREATE_EXT_BANK_ACCT` | 4803 |
| `fnd_msg_pub.get` | 4830 |
| `dka_tools_pkg.get_message` | 4836 |
| `IBY_EXT_BANKACCT_PUB.check_bank_acct_owner` | 4859 |
| `IBY_EXT_BANKACCT_PUB.add_joint_account_owner` | 4884 |
| `fnd_msg_pub.get` | 4904 |
| `dka_tools_pkg.get_message` | 4910 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 4953 |
| `fnd_msg_pub.get` | 4974 |
| `dka_tools_pkg.get_message` | 4980 |
| `dka_tools_pkg.get_message` | 5072 |
| `dka_tools_pkg.get_message` | 5080 |
| `IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee` | 5097 |
| `fnd_msg_pub.get` | 5116 |
| `dka_tools_pkg.get_message` | 5131 |
| `IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee` | 5145 |
| `fnd_msg_pub.get` | 5166 |
| `dka_tools_pkg.get_message` | 5181 |
| `dka_tools_pkg.get_message` | 5268 |
| `dka_tools_pkg.get_message` | 5366 |
| `FND_USER_PKG.UpdateUser` | 5378 |
| `dka_tools_pkg.get_message` | 5385 |
| `dka_tools_pkg.get_message` | 5466 |
| `DKA_PA_TOOLS_PKG.pa_get_info_task` | 5929 |
| `dka_gl_tools_pkg.get_legder_id` | 5960 |
| `Dka_Tools_Pkg.get_code_combination_id` | 5976 |
| `Dka_Tools_Pkg.get_code_combination_id` | 6000 |
| `ap_vendor_pub_pkg.create_vendor_site` | 6070 |
| `fnd_msg_pub.get` | 6092 |
| `hz_location_v2pub.create_location` | 6113 |
| `fnd_msg_pub.get` | 6129 |
| `hz_party_site_v2pub.create_party_site` | 6147 |
| `fnd_msg_pub.get` | 6166 |
| `ap_vendor_pub_pkg.update_vendor_site` | 6187 |
| `fnd_msg_pub.get` | 6206 |
| `IBY_EXT_BANKACCT_PUB.check_bank_acct_owner` | 6239 |
| `IBY_EXT_BANKACCT_PUB.add_joint_account_owner` | 6264 |
| `fnd_msg_pub.get` | 6284 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 6327 |
| `fnd_msg_pub.get` | 6348 |
| `IBY_DISBURSEMENT_SETUP_PUB.create_External_Payee` | 6463 |
| `fnd_msg_pub.get` | 6482 |
| `IBY_DISBURSEMENT_SETUP_PUB.Update_External_Payee` | 6508 |
| `fnd_msg_pub.get` | 6529 |
| `ap_vendor_pub_pkg.update_Vendor_Site` | 6749 |
| `fnd_msg_pub.get` | 6770 |
| `ap_vendor_pub_pkg.update_Vendor_Site` | 6819 |
| `fnd_msg_pub.get` | 6840 |
| `dka_tools_pkg.get_message` | 6924 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 345, 346, 446, 447, 3015, 3024, 5226, 5230, 5402, 5412, 5498, 5508, 5876, 5877 |
| rollback | 454, 1855, 3031, 3041, 3054, 3589, 4033, 4139, 4543, 5221, 5238, 5397, 5418, 5424, 5514, 5520, 5533, 5882, 5887, 6560, 6565, 6646, 6719, 6787, 6792, 6857, 6862 |
| transaction_autonome | 377 |
| when_others | 233, 352, 453, 527, 570, 626, 724, 766, 819, 860, 913, 965, 1017, 1075, 1142, 1199, 1241, 1366, 1425, 1830, 1854, 2056, 2126, 2889, 2897, 3033, 3053, 3567, 3938, 4007, 5070, 5078, 5234, 5383, 5420, 5516, 5532, 5871, 5884, 6441, 6446, 6562, 6643, 6716, 6789, 6859, 6872, 6946, 7123 |
| suppression | 276, 279, 282, 287, 290, 293, 306, 319, 329 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IHREMP_GXP / DKA | `DKA_IHREMP_GXP_PKG.main` | dka/12.0.0/admin/import/DKA_IHREMP_GXP.prt:485 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
