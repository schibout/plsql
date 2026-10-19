# DKA_IEOAPSAT01_APIMP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IEOAPSAT01_APIMP_PKG.pkb).

Famille proposée par convention de nommage : **Autres / à qualifier**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2446 ; encodage : cp1252 (repli). SHA-256 : `0818412fb4dfc211abb1b7148a8b9ab3c5db93b21f6005076a7f18bdb8f7a15d`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `translate_text` | 48 |
| `create_ap_import_file` | 453 |
| `main` | 751 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `DKA_IEOAPSAT01_APIMP_HDR` | 461 |
| `DKA_IEOAPSAT01_APIMP_LINE` | 468 |
| `fnd_lookup_values_vl` | 474 |
| `to_char` | 561 |
| `to_char` | 586 |
| `DKA_IEOAPSAT01_APIMP_HDR` | 664 |
| `dka_sapautorgt_tmp` | 760 |
| `dka_sapautorgt_tmp` | 768 |
| `ap_checks_all` | 974 |
| `ap_checks_all` | 1126 |
| `ra_customer_trx_all` | 1181 |
| `AP_INVOICES_ALL` | 1185 |
| `fnd_lookup_values_vl` | 1222 |
| `fnd_flex_value_sets` | 1433 |
| `DUAL` | 1510 |
| `DKA_IEOAPSAT01_APIMP_HDR` | 1515 |
| `DUAL` | 1701 |
| `DKA_IEOAPSAT01_APIMP_LINE` | 1706 |
| `dka_sapautorgt_tmp` | 1861 |
| `fnd_flex_value_sets` | 1951 |
| `DUAL` | 2002 |
| `DKA_IEOAPSAT01_APIMP_HDR` | 2007 |
| `ra_customer_trx_all` | 2123 |
| `AP_INVOICES_ALL` | 2127 |
| `DUAL` | 2229 |
| `DKA_IEOAPSAT01_APIMP_LINE` | 2234 |
| `dka_sapautorgt_tmp` | 2389 |
| `DKA_IEOAPSAT01_APIMP_HDR` | 2403 |
| `DKA_IEOAPSAT01_APIMP_LINE` | 2406 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `dka_tools_pkg.put_debug_message` | 504 |
| `dka_tools_pkg.put_debug_message` | 511 |
| `dka_tools_pkg.put_debug_message` | 526 |
| `dka_tools_pkg.put_debug_message` | 531 |
| `dka_tools_pkg.put_debug_message` | 539 |
| `dka_tools_pkg.put_debug_message` | 556 |
| `dka_tools_pkg.put_debug_message` | 649 |
| `dka_tools_pkg.put_debug_message` | 653 |
| `dka_tools_pkg.put_debug_message` | 663 |
| `dka_tools_pkg.put_debug_message` | 670 |
| `dka_tools_pkg.put_debug_message` | 675 |
| `dka_tools_pkg.put_outdebug_message` | 678 |
| `dka_tools_pkg.put_outdebug_message` | 679 |
| `dka_tools_pkg.put_outdebug_message` | 684 |
| `dka_tools_pkg.put_debug_message` | 689 |
| `dka_tools_pkg.put_log_message` | 695 |
| `dka_tools_pkg.put_log_message` | 700 |
| `dka_tools_pkg.put_log_message` | 705 |
| `dka_tools_pkg.put_log_message` | 710 |
| `dka_tools_pkg.put_log_message` | 715 |
| `dka_tools_pkg.put_log_message` | 720 |
| `dka_tools_pkg.put_log_message` | 725 |
| `dka_tools_pkg.put_log_message` | 730 |
| `dka_tools_pkg.put_log_message` | 735 |
| `dka_tools_pkg.put_debug_message` | 1297 |
| `dka_tools_pkg.put_debug_message` | 1301 |
| `dka_tools_pkg.put_debug_message` | 1310 |
| `dka_tools_pkg.put_debug_message` | 1331 |
| `dka_tools_pkg.put_debug_message` | 1379 |
| `dka_tools_pkg.put_debug_message` | 1383 |
| `dka_tools_pkg.put_debug_message` | 1389 |
| `dka_tools_pkg.put_log_message` | 1399 |
| `dka_tools_pkg.put_debug_message` | 1406 |
| `dka_tools_pkg.put_debug_message` | 1428 |
| `dka_tools_pkg.put_debug_message` | 1456 |
| `dka_tools_pkg.put_debug_message` | 1505 |
| `dka_tools_pkg.put_debug_message` | 1513 |
| `fnd_profile.value` | 1546 |
| `fnd_profile.value` | 1548 |
| `fnd_profile.value` | 1550 |
| `dka_tools_pkg.put_debug_message` | 1577 |
| `dka_tools_pkg.put_debug_message` | 1587 |
| `dka_tools_pkg.put_debug_message` | 1593 |
| `dka_tools_pkg.put_debug_message` | 1620 |
| `dka_tools_pkg.put_debug_message` | 1641 |
| `DKA_TOOLS_PKG.Get_Next_Working_Day` | 1644 |
| `dka_tools_pkg.put_debug_message` | 1646 |
| `dka_tools_pkg.put_debug_message` | 1651 |
| `dka_tools_pkg.get_message` | 1652 |
| `dka_tools_pkg.put_debug_message` | 1658 |
| `dka_tools_pkg.get_message` | 1663 |
| `dka_tools_pkg.put_debug_message` | 1669 |
| `dka_tools_pkg.put_debug_message` | 1704 |
| `fnd_profile.value` | 1774 |
| `fnd_profile.value` | 1776 |
| `fnd_profile.value` | 1778 |
| `dka_tools_pkg.put_debug_message` | 1848 |
| `dka_tools_pkg.put_debug_message` | 1856 |
| `dka_tools_pkg.put_debug_message` | 1919 |
| `dka_tools_pkg.put_debug_message` | 1923 |
| `dka_tools_pkg.put_debug_message` | 1929 |
| `dka_tools_pkg.put_log_message` | 1933 |
| `dka_tools_pkg.put_debug_message` | 1940 |
| `dka_tools_pkg.put_debug_message` | 1946 |
| `dka_tools_pkg.put_debug_message` | 1974 |
| `dka_tools_pkg.put_debug_message` | 1997 |
| `dka_tools_pkg.put_debug_message` | 2005 |
| `fnd_profile.value` | 2036 |
| `fnd_profile.value` | 2038 |
| `fnd_profile.value` | 2040 |
| `dka_tools_pkg.put_debug_message` | 2065 |
| `dka_tools_pkg.put_debug_message` | 2075 |
| `dka_tools_pkg.put_debug_message` | 2081 |
| `dka_tools_pkg.put_debug_message` | 2106 |
| `dka_tools_pkg.put_debug_message` | 2111 |
| `DKA_TOOLS_PKG.Get_Next_Working_Day` | 2114 |
| `dka_tools_pkg.put_debug_message` | 2116 |
| `dka_tools_pkg.put_log_message` | 2139 |
| `dka_tools_pkg.put_debug_message` | 2149 |
| `dka_tools_pkg.get_message` | 2150 |
| `dka_tools_pkg.put_debug_message` | 2158 |
| `dka_tools_pkg.get_message` | 2162 |
| `dka_tools_pkg.put_debug_message` | 2173 |
| `dka_tools_pkg.get_message` | 2174 |
| `dka_tools_pkg.put_debug_message` | 2182 |
| `dka_tools_pkg.get_message` | 2186 |
| `dka_tools_pkg.put_debug_message` | 2199 |
| `dka_tools_pkg.put_debug_message` | 2232 |
| `fnd_profile.value` | 2302 |
| `fnd_profile.value` | 2304 |
| `fnd_profile.value` | 2306 |
| `dka_tools_pkg.put_debug_message` | 2376 |
| `dka_tools_pkg.put_debug_message` | 2384 |
| `dka_tools_pkg.put_debug_message` | 2402 |
| `dka_tools_pkg.put_debug_message` | 2414 |
| `dka_tools_pkg.put_outdebug_message` | 2417 |
| `dka_tools_pkg.put_outdebug_message` | 2418 |
| `dka_tools_pkg.put_debug_message` | 2421 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1868, 2410 |
| rollback | 2426, 2431, 2436 |
| when_others | 73, 732, 2138, 2434 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_CREATE_APIMPORT_FILE / DKA | `DKA_IEOAPSAT01_APIMP_PKG.CREATE_AP_IMPORT_FILE` | dka/12.0.0/admin/import/DKA_CREATE_APIMPORT_FILE.prt:504 |
| DKA_IEOAPSAT01_APIMP / DKA | `DKA_IEOAPSAT01_APIMP_PKG.main` | dka/12.0.0/admin/import/DKA_IEOAPSAT01_APIMP.prt:422 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
