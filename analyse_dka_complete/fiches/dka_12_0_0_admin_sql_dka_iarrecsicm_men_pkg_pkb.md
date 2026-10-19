# DKA_IARRECSICM_MEN_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IARRECSICM_MEN_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IARRECSICM_MEN_PKG.pkb).

Famille proposée par convention de nommage : **AR / clients**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2166 ; encodage : cp1252 (repli). SHA-256 : `69d44009186eb9bc9bd979d5f675bb38026af757587a773ddac08182c86afc7e`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `extraction_encours` | 188 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `fnd_lookup_values_vl` | 221 |
| `fnd_lookup_values_vl` | 237 |
| `ar_lookups` | 249 |
| `ar_lookups` | 254 |
| `AR_RECEIPT_METHODS` | 291 |
| `AR_RECEIPT_METHODS` | 294 |
| `ar_payment_schedules` | 301 |
| `fnd_lookup_values_vl` | 351 |
| `ar_lookups` | 355 |
| `ar_lookups` | 359 |
| `DKA_STRANSCO_HEADERS` | 380 |
| `gl_code_combinations` | 393 |
| `fnd_lookup_values_vl` | 407 |
| `AR_RECEIPT_METHODS` | 438 |
| `ar_payment_schedules` | 443 |
| `ar_cash_receipt_history_all` | 467 |
| `dka_iarrecsicm_encours_client` | 663 |
| `dka_iarrecsicm_encours_client` | 714 |
| `fnd_concurrent_requests` | 717 |
| `gl_period_statuses` | 745 |
| `ar_receivable_applications_all` | 783 |
| `ar_receivable_applications_all` | 798 |
| `ar_adjustments_all` | 812 |
| `pa_projects_all` | 842 |
| `DKA_STRANSCO_HEADERS` | 852 |
| `ra_cust_trx_line_gl_dist_all` | 860 |
| `ra_cust_trx_line_gl_dist_all` | 864 |
| `DKA_STRANSCO_HEADERS` | 885 |
| `hz_customer_profiles` | 899 |
| `ra_cust_trx_line_gl_dist_all` | 934 |
| `dka_stransco_lines` | 936 |
| `hz_cust_accounts` | 1004 |
| `hz_cust_acct_sites_all` | 1075 |
| `hz_cust_acct_sites_all` | 1135 |
| `ra_cust_trx_line_gl_dist_all` | 1216 |
| `ra_cust_trx_line_gl_dist_all` | 1236 |
| `fnd_document_sequences` | 1249 |
| `zx_lines` | 1299 |
| `dka_iarrecsicm_encours_client` | 1313 |
| `hz_cust_accounts` | 1508 |
| `hz_cust_accounts` | 1572 |
| `hz_cust_accounts_all` | 1629 |
| `hz_cust_acct_sites_all` | 1702 |
| `hz_cust_acct_sites_all` | 1757 |
| `dka_iarrecsicm_encours_client` | 1825 |
| `fnd_user` | 1959 |
| `gl_periods` | 1975 |
| `PER_SECURITY_PROFILES_V` | 1978 |
| `dba_directories` | 2033 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 707 |
| `dka_tools_pkg.put_debug_message` | 712 |
| `dka_tools_pkg.put_debug_message` | 724 |
| `dka_tools_pkg.put_debug_message` | 757 |
| `dka_tools_pkg.put_debug_message` | 1228 |
| `dka_tools_pkg.put_debug_message` | 1280 |
| `dka_stransco_pkg.etl_get_value_f` | 1284 |
| `dka_tools_pkg.put_debug_message` | 1290 |
| `dka_tools_pkg.put_debug_message` | 1308 |
| `dka_tools_pkg.put_debug_message` | 1466 |
| `dka_tools_pkg.put_debug_message` | 1472 |
| `dka_tools_pkg.put_debug_message` | 1499 |
| `dka_tools_pkg.put_debug_message` | 1501 |
| `dka_tools_pkg.put_debug_message` | 1946 |
| `dka_tools_pkg.put_debug_message` | 1953 |
| `dka_tools_pkg.put_debug_message` | 1954 |
| `fnd_profile.VALUE` | 1955 |
| `fnd_profile.VALUE` | 1960 |
| `dka_tools_pkg.put_debug_message` | 1962 |
| `dka_tools_pkg.put_debug_message` | 1966 |
| `fnd_profile.value` | 1984 |
| `dka_tools_pkg.put_debug_message` | 1999 |
| `dka_tools_pkg.put_log_message` | 2040 |
| `dka_tools_pkg.put_log_message` | 2045 |
| `dka_tools_pkg.put_log_message` | 2057 |
| `fnd_file.put_line` | 2126 |
| `fnd_file.put_line` | 2135 |
| `dka_tools_pkg.put_debug_message` | 2154 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 727, 1949 |
| when_others | 751, 878, 906, 948, 1026, 1105, 1167, 1225, 1277, 1521, 1656, 1734, 1789, 2157 |
| suppression | 714 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAR_ENCOURS_REC_SICM_MEN / DKA | `DKA_IARRECSICM_MEN_PKG.Extraction_Encours` | dka/12.0.0/admin/import/DKA_IAR_ENCOURS_REC_SICM_MEN.prt:593 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
