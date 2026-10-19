# DKA_SAPFRSDUP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SAPFRSDUP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SAPFRSDUP_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 3003 ; encodage : cp1252 (repli). SHA-256 : `1350732f8a209dfb2680378a4bac65562507a58beacd4efebd77087be19385aa`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `CONTROLE_SITE_FOURNISSEUR` | 50 |
| `writeout` | 489 |
| `writelog` | 516 |
| `DUPLICATION_SITE_FOURNISSEUR` | 567 |
| `COMPARE_VALUE` | 1675 |
| `MAJ_SITE_FOURNISSEUR` | 1861 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DUAL` | 87 |
| `AP_SUPPLIER_SITES_ALL` | 119 |
| `IBY_EXTERNAL_PAYEES_ALL` | 128 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 135 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 150 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 162 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 174 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 186 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 198 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 212 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 226 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 240 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 254 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 268 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 279 |
| `gl_code_combinations` | 293 |
| `gl_code_combinations` | 298 |
| `gl_code_combinations` | 303 |
| `gl_code_combinations` | 309 |
| `ap_suppliers` | 320 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 333 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 348 |
| `FND_TERRITORIES` | 366 |
| `DKA_STRANSCO_LINES` | 375 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 390 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 400 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 410 |
| `FND_FLEX_VALUE_SETS` | 422 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 431 |
| `hr_operating_units` | 663 |
| `per_security_organizations` | 669 |
| `per_security_profiles` | 675 |
| `hr_operating_units` | 689 |
| `per_security_organizations` | 697 |
| `per_security_profiles` | 703 |
| `HZ_PARTIES` | 730 |
| `dual` | 761 |
| `ap_supplier_sites_all` | 771 |
| `dka_sapfrsdupli_error_tmp` | 778 |
| `iby_external_payees_all` | 798 |
| `dka_sapfrsdupli_error_tmp` | 806 |
| `ap_supplier_sites_all` | 827 |
| `dka_sapfrsdupli_error_tmp` | 838 |
| `ap_supplier_sites_all` | 875 |
| `IBY_EXT_PARTY_PMT_MTHDS` | 928 |
| `ap_suppliers` | 944 |
| `dka_sapfrsdupli_error_tmp` | 956 |
| `gl_code_combinations` | 996 |
| `dka_sapfrsdupli_error_tmp` | 1028 |
| `gl_code_combinations` | 1063 |
| `dka_sapfrsdupli_error_tmp` | 1096 |
| `gl_code_combinations` | 1131 |
| `dka_sapfrsdupli_error_tmp` | 1162 |
| `gl_ledgers` | 1185 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 1202 |
| `FINANCIALS_SYSTEM_PARAMS_ALL` | 1219 |
| `dka_sapfrsdupli_error_tmp` | 1402 |
| `IBY_EXTERNAL_PAYEES_ALL` | 1425 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 1479 |
| `dka_sapfrsdupli_error_tmp` | 1542 |
| `dka_sapfrsdupli_error_tmp` | 1584 |
| `dka_sapfrsdupli_error_tmp` | 1610 |
| `dka_sapfrsdupli_error_tmp` | 1625 |
| `ap_supplier_sites_all` | 1732 |
| `ap_supplier_sites_all` | 1786 |
| `ap_supplier_sites_all` | 1792 |
| `ap_supplier_sites_all` | 1794 |
| `ap_supplier_sites_all` | 1955 |
| `ap_supplier_sites_all` | 1974 |
| `iby_ext_bank_accounts` | 1995 |
| `DUAL` | 2013 |
| `ap_supplier_sites_all` | 2019 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2026 |
| `IBY_EXTERNAL_PAYEES_ALL` | 2042 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2049 |
| `IBY_EXT_PARTY_PMT_MTHDS` | 2063 |
| `ap_supplier_sites_all` | 2111 |
| `ap_supplier_sites_all` | 2125 |
| `ap_supplier_sites_all` | 2140 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2165 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2198 |
| `ap_supplier_sites_all` | 2212 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2227 |
| `gl_code_combinations` | 2286 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2318 |
| `gl_code_combinations` | 2357 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2390 |
| `gl_code_combinations` | 2430 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2462 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2599 |
| `ap_supplier_sites_all` | 2616 |
| `AP_CHECKS_ALL` | 2623 |
| `AP_CHECKS_ALL` | 2627 |
| `IBY_EXTERNAL_PAYEES_ALL` | 2640 |
| `IBY_EXT_PARTY_PMT_MTHDS` | 2681 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2705 |
| `iby_ext_bank_accounts` | 2729 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2797 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2859 |
| `iby_ext_bank_accounts` | 2883 |
| `iby_ext_bank_accounts` | 2895 |
| `DKA_SAPFRSDUPLI_ERROR_TMP` | 2950 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 30 |
| `fnd_file.put_line` | 370 |
| `fnd_file.put_line` | 384 |
| `FND_FILE.PUT_LINE` | 494 |
| `Fnd_File.put_line` | 500 |
| `Fnd_File.put_line` | 502 |
| `Fnd_File.put_line` | 503 |
| `Fnd_File.put_line` | 504 |
| `Fnd_File.put_line` | 505 |
| `Fnd_File.put_line` | 506 |
| `fnd_file.put_line` | 528 |
| `fnd_file.put_line` | 531 |
| `fnd_file.put_line` | 535 |
| `Fnd_File.put_line` | 868 |
| `dka_tools_pkg.get_code_combination_id` | 1007 |
| `dka_tools_pkg.get_code_combination_id` | 1075 |
| `dka_tools_pkg.get_code_combination_id` | 1141 |
| `ap_vendor_pub_pkg.create_vendor_site` | 1382 |
| `fnd_msg_pub.get` | 1399 |
| `IBY_DISBURSEMENT_SETUP_PUB.update_external_payee` | 1462 |
| `fnd_file.put_line` | 1492 |
| `iby_disbursement_setup_pub.set_payee_instr_assignment` | 1521 |
| `fnd_msg_pub.get` | 1539 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2295 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2366 |
| `Dka_Tools_Pkg.get_code_combination_id` | 2439 |
| `AP_VENDOR_PUB_PKG.UPDATE_VENDOR_SITE` | 2582 |
| `fnd_msg_pub.get` | 2597 |
| `IBY_DISBURSEMENT_SETUP_PUB.update_external_payee` | 2688 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 2778 |
| `fnd_msg_pub.get` | 2796 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 2840 |
| `fnd_msg_pub.get` | 2858 |
| `IBY_DISBURSEMENT_SETUP_PUB.Set_Payee_Instr_Assignment` | 2931 |
| `fnd_msg_pub.get` | 2949 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 443, 1394, 1640, 2633, 2983 |
| when_others | 369, 383, 429, 497, 538, 776, 804, 836, 884, 935, 949, 1002, 1069, 1137, 1191, 1208, 1225, 1431, 2024, 2047, 2070, 2119, 2132, 2147, 2218, 2290, 2361, 2434, 2645, 2742 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
