# DKA_IPOFRS_IVALUA_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPOFRS_IVALUA_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 4231 ; encodage : cp1252 (repli). SHA-256 : `ddcbc04f9f0006d6cbe624488d0b67e1389b4f4dbcc17015aebd40e5b0550b72`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `update_record_id` | 60 |
| `update_statut` | 138 |
| `delete_obsolete_records` | 190 |
| `purge_data` | 302 |
| `writeout` | 341 |
| `Report_Bilan` | 370 |
| `init` | 513 |
| `Launch_Loader` | 582 |
| `ins_prog_message` | 686 |
| `validate_data` | 743 |
| `import_data` | 2466 |
| `MAIN` | 3995 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_IPOFRS_ENTETES` | 67 |
| `DKA_IPOFRS_LIGNES` | 68 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 69 |
| `DKA_IPOFRS_REPORTING_ENTETES` | 75 |
| `DKA_IPOFRS_HIST_ENTETES` | 81 |
| `DKA_IPOFRS_REPORTING_LIGNES` | 92 |
| `DKA_IPOFRS_HIST_LIGNES` | 98 |
| `DKA_IPOFRS_REPORTING_HOMOLOG` | 108 |
| `DKA_IPOFRS_HIST_HOMOLOGATIONS` | 114 |
| `DKA_IPOFRS_ENTETES` | 144 |
| `DKA_IPOFRS_LIGNES` | 145 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 146 |
| `DKA_IPOFRS_REPORTING_ENTETES` | 151 |
| `DKA_IPOFRS_ENTETES` | 153 |
| `DKA_IPOFRS_ENTETES` | 157 |
| `DKA_IPOFRS_REPORTING_LIGNES` | 159 |
| `DKA_IPOFRS_LIGNES` | 161 |
| `DKA_IPOFRS_LIGNES` | 165 |
| `DKA_IPOFRS_REPORTING_HOMOLOG` | 167 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 169 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 173 |
| `DKA_IPOFRS_REPORTING_ENTETES` | 203 |
| `DKA_IPOFRS_ENTETES` | 207 |
| `DKA_IPOFRS_ENTETES` | 210 |
| `DKA_IPOFRS_REPORTING_lignes` | 215 |
| `DKA_IPOFRS_LIGNES` | 218 |
| `DKA_IPOFRS_LIGNES` | 221 |
| `DKA_IPOFRS_REPORTING_HOMOLOG` | 227 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 231 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 234 |
| `DKA_PROGRAM_MESSAGES` | 242 |
| `DKA_IPOFRS_ENTETES` | 250 |
| `DKA_IPOFRS_LIGNES` | 261 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 271 |
| `DKA_PROGRAM_MESSAGES` | 380 |
| `DKA_PROGRAM_MESSAGES` | 390 |
| `DKA_PROGRAM_MESSAGES` | 401 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 412 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 427 |
| `fnd_responsibility` | 546 |
| `DKA_IPOFRS_HIST_ENTETES` | 636 |
| `DKA_IPOFRS_HIST_LIGNES` | 640 |
| `DKA_IPOFRS_HIST_HOMOLOGATIONS` | 644 |
| `dka_program_messages` | 698 |
| `DKA_IPOFRS_ENTETES` | 805 |
| `DKA_IPOFRS_lignes` | 811 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 817 |
| `DKA_IPOFRS_ENTETES` | 874 |
| `ap_suppliers` | 880 |
| `FND_LOOKUP_VALUES` | 921 |
| `ap_suppliers` | 955 |
| `FND_LOOKUP_VALUES` | 1026 |
| `FND_LOOKUP_VALUES` | 1058 |
| `fnd_flex_value_sets` | 1194 |
| `fnd_flex_value_sets` | 1248 |
| `DKA_IPOFRS_ENTETES` | 1303 |
| `DKA_IPOFRS_ENTETES` | 1316 |
| `ap_suppliers` | 1358 |
| `DKA_IPOFRS_ENTETES` | 1372 |
| `FND_TERRITORIES_vl` | 1455 |
| `ap_suppliers` | 1654 |
| `DKA_IPOFRS_ENTETES` | 1664 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 1683 |
| `gl_code_combinations` | 1735 |
| `gl_code_combinations` | 1806 |
| `gl_code_combinations` | 1879 |
| `gl_code_combinations` | 1939 |
| `gl_code_combinations` | 2021 |
| `gl_code_combinations` | 2101 |
| `ap_terms` | 2168 |
| `DKA_IPOFRS_LIGNES` | 2195 |
| `DKA_IPOFRS_LIGNES` | 2209 |
| `ap_supplier_sites_all` | 2233 |
| `ap_supplier_sites_all` | 2254 |
| `DKA_IPOFRS_LIGNES` | 2273 |
| `hr_operating_units` | 2378 |
| `per_security_organizations` | 2384 |
| `per_security_profiles` | 2390 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 2420 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 2430 |
| `DKA_IPOFRS_ENTETES` | 2577 |
| `DKA_IPOFRS_lignes` | 2583 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 2589 |
| `ap_suppliers` | 2599 |
| `ap_suppliers` | 2610 |
| `DKA_IPOFRS_ENTETES` | 2697 |
| `ap.ap_suppliers` | 2723 |
| `DKA_IPOFRS_ENTETES` | 2727 |
| `ap_suppliers` | 2741 |
| `DKA_IPOFRS_ENTETES` | 2790 |
| `ap_suppliers` | 2802 |
| `hz_parties` | 2813 |
| `HZ_ORGANIZATION_PROFILES` | 2820 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 2839 |
| `gl_code_combinations` | 2890 |
| `gl_code_combinations` | 2960 |
| `gl_code_combinations` | 3032 |
| `gl_code_combinations` | 3091 |
| `gl_code_combinations` | 3173 |
| `gl_code_combinations` | 3253 |
| `ap_supplier_sites_all` | 3311 |
| `hr_operating_units` | 3317 |
| `DKA_IPOFRS_ENTETES` | 3325 |
| `hr_organization_units` | 3362 |
| `ap_terms` | 3373 |
| `ap_supplier_sites_all` | 3388 |
| `ap_supplier_sites_all` | 3399 |
| `DKA_IPOFRS_LIGNES` | 3412 |
| `ap_suppliers` | 3448 |
| `DKA_IPOFRS_LIGNES` | 3519 |
| `ap_supplier_sites_all` | 3545 |
| `hz_locations` | 3549 |
| `IBY_EXTERNAL_PAYEES_ALL` | 3559 |
| `IBY_EXTERNAL_PAYEES_ALL` | 3574 |
| `DKA_IPOFRS_LIGNES` | 3612 |
| `DKA_IPOFRS_LIGNES` | 3641 |
| `ap_supplier_sites_all` | 3668 |
| `ap_suppliers` | 3679 |
| `DKA_IPOFRS_LIGNES` | 3780 |
| `hz_party_sites` | 3809 |
| `hz_locations` | 3813 |
| `ap.ap_supplier_sites_all` | 3829 |
| `ap_suppliers` | 3842 |
| `DKA_IPOFRS_LIGNES` | 3848 |
| `fnd_logins` | 3869 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 3880 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 3956 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 3959 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 3965 |
| `DKA_SAPFRSDUPLI_MASSE_TMP` | 3968 |
| `DKA_IPOFRS_ENTETES` | 4020 |
| `DKA_IPOFRS_lignes` | 4026 |
| `DKA_IPOFRS_HOMOLOGATIONS` | 4032 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 25 |
| `Fnd_File.put_line` | 255 |
| `Fnd_File.put_line` | 266 |
| `Fnd_File.put_line` | 278 |
| `Fnd_File.put_line` | 279 |
| `Dka_Tools_Pkg.put_log_message` | 309 |
| `Dka_Tools_Pkg.put_log_message` | 324 |
| `FND_FILE.PUT_LINE` | 346 |
| `Fnd_File.put_line` | 352 |
| `Fnd_File.put_line` | 354 |
| `Fnd_File.put_line` | 355 |
| `Fnd_File.put_line` | 356 |
| `Fnd_File.put_line` | 357 |
| `Fnd_File.put_line` | 358 |
| `FND_GLOBAL.APPS_INITIALIZE` | 557 |
| `Fnd_File.put_line` | 604 |
| `Fnd_File.put_line` | 607 |
| `FND_REQUEST.submit_request` | 608 |
| `DKA_TOOLS_PKG.put_log_message` | 618 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 619 |
| `DKA_TOOLS_PKG.put_log_message` | 631 |
| `DKA_TOOLS_PKG.put_log_message` | 647 |
| `DKA_TOOLS_PKG.put_log_message` | 651 |
| `Fnd_File.put_line` | 652 |
| `DKA_TOOLS_PKG.put_log_message` | 663 |
| `Fnd_File.put_line` | 676 |
| `DKA_TOOLS_PKG.put_log_message` | 830 |
| `DKA_TOOLS_PKG.get_message` | 834 |
| `DKA_TOOLS_PKG.put_log_message` | 847 |
| `DKA_TOOLS_PKG.put_log_message` | 851 |
| `DKA_TOOLS_PKG.get_message` | 855 |
| `DKA_TOOLS_PKG.put_log_message` | 867 |
| `DKA_TOOLS_PKG.get_message` | 893 |
| `DKA_TOOLS_PKG.put_log_message` | 905 |
| `DKA_TOOLS_PKG.put_log_message` | 916 |
| `DKA_TOOLS_PKG.get_message` | 933 |
| `DKA_TOOLS_PKG.put_log_message` | 945 |
| `DKA_TOOLS_PKG.put_log_message` | 950 |
| `DKA_TOOLS_PKG.get_message` | 962 |
| `DKA_TOOLS_PKG.put_log_message` | 975 |
| `DKA_TOOLS_PKG.put_log_message` | 981 |
| `DKA_TOOLS_PKG.get_message` | 986 |
| `DKA_TOOLS_PKG.put_log_message` | 998 |
| `DKA_TOOLS_PKG.put_log_message` | 1005 |
| `DKA_TOOLS_PKG.get_message` | 1008 |
| `DKA_TOOLS_PKG.put_log_message` | 1020 |
| `DKA_TOOLS_PKG.get_message` | 1036 |
| `DKA_TOOLS_PKG.put_log_message` | 1048 |
| `DKA_TOOLS_PKG.put_log_message` | 1053 |
| `DKA_TOOLS_PKG.get_message` | 1068 |
| `DKA_TOOLS_PKG.put_log_message` | 1080 |
| `DKA_TOOLS_PKG.put_log_message` | 1085 |
| `DKA_TOOLS_PKG.get_message` | 1088 |
| `DKA_TOOLS_PKG.put_log_message` | 1100 |
| `DKA_TOOLS_PKG.get_message` | 1103 |
| `DKA_TOOLS_PKG.put_log_message` | 1115 |
| `DKA_TOOLS_PKG.put_log_message` | 1120 |
| `DKA_TOOLS_PKG.get_message` | 1123 |
| `DKA_TOOLS_PKG.put_log_message` | 1135 |
| `DKA_TOOLS_PKG.get_message` | 1138 |
| `DKA_TOOLS_PKG.put_log_message` | 1150 |
| `DKA_TOOLS_PKG.put_log_message` | 1155 |
| `DKA_TOOLS_PKG.get_message` | 1158 |
| `DKA_TOOLS_PKG.put_log_message` | 1170 |
| `DKA_TOOLS_PKG.get_message` | 1173 |
| `DKA_TOOLS_PKG.put_log_message` | 1185 |
| `DKA_TOOLS_PKG.put_log_message` | 1189 |
| `DKA_TOOLS_PKG.get_message` | 1209 |
| `DKA_TOOLS_PKG.put_log_message` | 1221 |
| `DKA_TOOLS_PKG.put_log_message` | 1226 |
| `DKA_TOOLS_PKG.get_message` | 1231 |
| `DKA_TOOLS_PKG.put_log_message` | 1243 |
| `DKA_TOOLS_PKG.get_message` | 1262 |
| `DKA_TOOLS_PKG.put_log_message` | 1275 |
| `DKA_TOOLS_PKG.get_message` | 1283 |
| `DKA_TOOLS_PKG.put_log_message` | 1296 |
| `DKA_TOOLS_PKG.put_log_message` | 1338 |
| `DKA_TOOLS_PKG.get_message` | 1341 |
| `DKA_TOOLS_PKG.put_log_message` | 1353 |
| `DKA_TOOLS_PKG.get_message` | 1386 |
| `DKA_TOOLS_PKG.put_log_message` | 1398 |
| `DKA_TOOLS_PKG.get_message` | 1405 |
| `DKA_TOOLS_PKG.put_log_message` | 1417 |
| `DKA_TOOLS_PKG.get_message` | 1421 |
| `DKA_TOOLS_PKG.put_log_message` | 1433 |
| `DKA_TOOLS_PKG.get_message` | 1437 |
| `DKA_TOOLS_PKG.put_log_message` | 1449 |
| `DKA_TOOLS_PKG.get_message` | 1460 |
| `DKA_TOOLS_PKG.put_log_message` | 1472 |
| `DKA_TOOLS_PKG.get_message` | 1480 |
| `DKA_TOOLS_PKG.put_log_message` | 1492 |
| `DKA_TOOLS_PKG.get_message` | 1496 |
| `DKA_TOOLS_PKG.put_log_message` | 1508 |
| `DKA_TOOLS_PKG.get_message` | 1513 |
| `DKA_TOOLS_PKG.put_log_message` | 1525 |
| `DKA_TOOLS_PKG.get_message` | 1530 |
| `DKA_TOOLS_PKG.put_log_message` | 1542 |
| `DKA_TOOLS_PKG.get_message` | 1546 |
| `DKA_TOOLS_PKG.put_log_message` | 1558 |
| `DKA_TOOLS_PKG.get_message` | 1564 |
| `DKA_TOOLS_PKG.put_log_message` | 1576 |
| `DKA_TOOLS_PKG.get_message` | 1579 |
| `DKA_TOOLS_PKG.put_log_message` | 1591 |
| `DKA_TOOLS_PKG.get_message` | 1598 |
| `DKA_TOOLS_PKG.put_log_message` | 1610 |
| `DKA_TOOLS_PKG.get_message` | 1613 |
| `DKA_TOOLS_PKG.put_log_message` | 1625 |
| `DKA_TOOLS_PKG.get_message` | 1631 |
| `DKA_TOOLS_PKG.put_log_message` | 1643 |
| `DKA_TOOLS_PKG.get_message` | 1693 |
| `DKA_TOOLS_PKG.get_message` | 1745 |
| `DKA_TOOLS_PKG.get_message` | 1764 |
| `DKA_TOOLS_PKG.get_message` | 1816 |
| `DKA_TOOLS_PKG.get_message` | 1835 |
| `DKA_TOOLS_PKG.get_message` | 1889 |
| `dka_tools_pkg.get_code_combination_id` | 1952 |
| `DKA_TOOLS_PKG.get_message` | 1974 |
| `DKA_TOOLS_PKG.put_log_message` | 1987 |
| `dka_tools_pkg.get_code_combination_id` | 2034 |
| `DKA_TOOLS_PKG.get_message` | 2056 |
| `DKA_TOOLS_PKG.put_log_message` | 2069 |
| `dka_tools_pkg.get_code_combination_id` | 2114 |
| `DKA_TOOLS_PKG.get_message` | 2136 |
| `DKA_TOOLS_PKG.put_log_message` | 2149 |
| `DKA_TOOLS_PKG.put_log_message` | 2161 |
| `DKA_TOOLS_PKG.get_message` | 2174 |
| `DKA_TOOLS_PKG.put_log_message` | 2187 |
| `DKA_TOOLS_PKG.get_message` | 2288 |
| `DKA_TOOLS_PKG.put_log_message` | 2300 |
| `DKA_TOOLS_PKG.get_message` | 2307 |
| `DKA_TOOLS_PKG.put_log_message` | 2320 |
| `DKA_TOOLS_PKG.get_message` | 2325 |
| `DKA_TOOLS_PKG.put_log_message` | 2337 |
| `DKA_TOOLS_PKG.get_message` | 2343 |
| `DKA_TOOLS_PKG.put_log_message` | 2355 |
| `DKA_TOOLS_PKG.get_message` | 2360 |
| `DKA_TOOLS_PKG.put_log_message` | 2372 |
| `DKA_TOOLS_PKG.get_message` | 2400 |
| `DKA_TOOLS_PKG.put_log_message` | 2412 |
| `Fnd_File.put_line` | 2448 |
| `Fnd_File.put_line` | 2449 |
| `ap_vendor_pub_pkg.create_vendor` | 2679 |
| `FND_MSG_PUB.get` | 2694 |
| `fnd_msg_pub.get` | 2705 |
| `ap_vendor_pub_pkg.update_vendor_public` | 2777 |
| `DKA_TOOLS_PKG.get_message` | 2848 |
| `DKA_TOOLS_PKG.get_message` | 2900 |
| `DKA_TOOLS_PKG.get_message` | 2918 |
| `DKA_TOOLS_PKG.get_message` | 2970 |
| `DKA_TOOLS_PKG.get_message` | 2988 |
| `DKA_TOOLS_PKG.get_message` | 3042 |
| `dka_tools_pkg.get_code_combination_id` | 3104 |
| `DKA_TOOLS_PKG.get_message` | 3126 |
| `DKA_TOOLS_PKG.put_log_message` | 3139 |
| `dka_tools_pkg.get_code_combination_id` | 3186 |
| `DKA_TOOLS_PKG.get_message` | 3208 |
| `DKA_TOOLS_PKG.put_log_message` | 3221 |
| `dka_tools_pkg.get_code_combination_id` | 3266 |
| `DKA_TOOLS_PKG.get_message` | 3288 |
| `DKA_TOOLS_PKG.put_log_message` | 3301 |
| `fnd_msg_pub.get` | 3332 |
| `DKA_TOOLS_PKG.put_log_message` | 3430 |
| `ap_vendor_pub_pkg.create_vendor_site` | 3501 |
| `fnd_msg_pub.get` | 3525 |
| `DKA_TOOLS_PKG.put_log_message` | 3538 |
| `IBY_DISBURSEMENT_SETUP_PUB.update_external_payee` | 3594 |
| `fnd_msg_pub.get` | 3619 |
| `DKA_TOOLS_PKG.put_log_message` | 3632 |
| `AP_VENDOR_PUB_PKG.UPDATE_VENDOR_SITE_PUBLIC` | 3761 |
| `fnd_msg_pub.get` | 3789 |
| `DKA_TOOLS_PKG.put_log_message` | 3803 |
| `fnd_msg_pub.get` | 3803 |
| `FND_REQUEST.submit_request` | 3910 |
| `DKA_TOOLS_PKG.put_log_message` | 3920 |
| `FND_CONCURRENT.WAIT_FOR_REQUEST` | 3921 |
| `DKA_TOOLS_PKG.put_log_message` | 3933 |
| `DKA_TOOLS_PKG.put_log_message` | 3938 |
| `DKA_TOOLS_PKG.put_log_message` | 3943 |
| `Fnd_File.put_line` | 3944 |
| `DKA_TOOLS_PKG.put_log_message` | 3950 |
| `Dka_Tools_Pkg.put_log_message` | 4045 |
| `Dka_Tools_Pkg.put_log_message` | 4046 |
| `Dka_Tools_Pkg.put_log_message` | 4047 |
| `Dka_Tools_Pkg.put_log_message` | 4048 |
| `Dka_Tools_Pkg.put_log_message` | 4049 |
| `Dka_Tools_Pkg.put_log_message` | 4060 |
| `Dka_Tools_Pkg.put_log_message` | 4061 |
| `Dka_Tools_Pkg.put_log_message` | 4062 |
| `Dka_Tools_Pkg.put_log_message` | 4063 |
| `Dka_Tools_Pkg.put_log_message` | 4084 |
| `Dka_Tools_Pkg.put_log_message` | 4085 |
| `Dka_Tools_Pkg.put_log_message` | 4086 |
| `Dka_Tools_Pkg.put_log_message` | 4087 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4094 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4097 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4184 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4186 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4193 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4194 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4195 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4196 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4197 |
| `Dka_Tools_Pkg.put_log_message` | 4198 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4199 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4200 |
| `Dka_Tools_Pkg.put_log_message` | 4201 |
| `Dka_Tools_Pkg.put_log_message` | 4202 |
| `Dka_Tools_Pkg.put_log_message` | 4203 |
| `Dka_Tools_Pkg.put_log_message` | 4204 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4211 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4212 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4213 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4214 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4215 |
| `Dka_Tools_Pkg.put_log_message` | 4216 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4217 |
| `Dka_Tools_Pkg.put_outdebug_message` | 4218 |
| `Dka_Tools_Pkg.put_log_message` | 4219 |
| `Dka_Tools_Pkg.put_log_message` | 4220 |
| `Dka_Tools_Pkg.put_log_message` | 4221 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 174, 281, 325, 616, 668, 1328, 2222, 2440, 2788, 3322, 3352, 3513, 3552, 3655, 3863, 3908, 3918, 3975, 4182 |
| rollback | 722, 4205, 4222 |
| when_others | 283, 327, 349, 552, 721, 1363, 1378, 1739, 1810, 1883, 1947, 2029, 2109, 2244, 2265, 2281, 2397, 2444, 2618, 2744, 2894, 2964, 3036, 3099, 3181, 3261, 3365, 3436, 3451, 3565, 3578, 3671, 3682, 3872, 3903, 4207 |
| suppression | 242, 636, 640, 644 |
| soumission | 608, 3910 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IPOFRS_IVALUA / DKA | `DKA_IPOFRS_IVALUA_PKG.main` | dka/12.0.0/admin/import/DKA_IPOFRS_IVALUA.prt:480 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
