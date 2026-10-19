# DKA_IARRECSICM_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IARRECSICM_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IARRECSICM_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2068 ; encodage : cp1252 (repli). SHA-256 : `b31a9c3bc9711b87b597666182714c6ad9a632b930e02cec6ca8c3a174a97100`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `extraction_encours` | 186 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_lookup_values_vl` | 215 |
| `fnd_lookup_values_vl` | 231 |
| `ar_lookups` | 243 |
| `ar_lookups` | 248 |
| `AR_RECEIPT_METHODS` | 285 |
| `AR_RECEIPT_METHODS` | 289 |
| `ar_payment_schedules` | 296 |
| `fnd_lookup_values_vl` | 343 |
| `ar_lookups` | 347 |
| `ar_lookups` | 351 |
| `DKA_STRANSCO_HEADERS` | 372 |
| `gl_code_combinations` | 385 |
| `fnd_lookup_values_vl` | 399 |
| `AR_RECEIPT_METHODS` | 430 |
| `ar_payment_schedules` | 435 |
| `ar_cash_receipt_history_all` | 459 |
| `dka_iarrecsicm_encours_client` | 652 |
| `dka_iarrecsicm_encours_client` | 701 |
| `fnd_concurrent_requests` | 704 |
| `ar_receivable_applications_all` | 744 |
| `ar_receivable_applications_all` | 759 |
| `ar_adjustments_all` | 773 |
| `pa_projects_all` | 803 |
| `DKA_STRANSCO_HEADERS` | 813 |
| `ra_cust_trx_line_gl_dist_all` | 821 |
| `ra_cust_trx_line_gl_dist_all` | 825 |
| `DKA_STRANSCO_HEADERS` | 846 |
| `hz_customer_profiles` | 868 |
| `ra_cust_trx_line_gl_dist_all` | 902 |
| `dka_stransco_lines` | 904 |
| `hz_cust_accounts` | 972 |
| `hz_cust_acct_sites_all` | 1044 |
| `hz_cust_acct_sites_all` | 1104 |
| `ra_cust_trx_line_gl_dist_all` | 1186 |
| `ra_cust_trx_line_gl_dist_all` | 1206 |
| `fnd_document_sequences` | 1219 |
| `zx_lines` | 1269 |
| `dka_iarrecsicm_encours_client` | 1283 |
| `hz_cust_accounts` | 1480 |
| `hz_cust_accounts` | 1546 |
| `hz_cust_accounts_all` | 1604 |
| `hz_cust_acct_sites_all` | 1679 |
| `hz_cust_acct_sites_all` | 1735 |
| `dka_iarrecsicm_encours_client` | 1804 |
| `fnd_user` | 1933 |
| `dba_directories` | 1973 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 694 |
| `dka_tools_pkg.put_debug_message` | 699 |
| `dka_tools_pkg.put_debug_message` | 710 |
| `dka_tools_pkg.put_debug_message` | 718 |
| `dka_tools_pkg.put_debug_message` | 853 |
| `dka_tools_pkg.put_debug_message` | 855 |
| `dka_tools_pkg.put_debug_message` | 857 |
| `dka_tools_pkg.put_debug_message` | 1198 |
| `dka_tools_pkg.put_debug_message` | 1250 |
| `dka_stransco_pkg.etl_get_value_f` | 1254 |
| `dka_tools_pkg.put_debug_message` | 1260 |
| `dka_tools_pkg.put_debug_message` | 1278 |
| `dka_tools_pkg.put_debug_message` | 1436 |
| `dka_tools_pkg.put_debug_message` | 1442 |
| `dka_tools_pkg.put_debug_message` | 1466 |
| `dka_tools_pkg.put_debug_message` | 1468 |
| `dka_tools_pkg.put_debug_message` | 1470 |
| `dka_tools_pkg.put_debug_message` | 1497 |
| `dka_tools_pkg.put_debug_message` | 1921 |
| `dka_tools_pkg.put_debug_message` | 1927 |
| `dka_tools_pkg.put_debug_message` | 1928 |
| `fnd_profile.VALUE` | 1929 |
| `fnd_profile.VALUE` | 1934 |
| `dka_tools_pkg.put_debug_message` | 1936 |
| `dka_tools_pkg.put_debug_message` | 1940 |
| `dka_tools_pkg.put_debug_message` | 1949 |
| `dka_tools_pkg.put_log_message` | 1980 |
| `dka_tools_pkg.put_log_message` | 1985 |
| `dka_tools_pkg.put_log_message` | 1997 |
| `dka_tools_pkg.put_debug_message` | 2056 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 713, 1924 |
| when_others | 839, 875, 916, 994, 1074, 1137, 1195, 1247, 1493, 1633, 1712, 1768, 2059 |
| suppression | 701 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAR_ENCOURS_REC_SICM / DKA | `DKA_IARRECSICM_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_IAR_ENCOURS_REC_SICM.prt:419 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
