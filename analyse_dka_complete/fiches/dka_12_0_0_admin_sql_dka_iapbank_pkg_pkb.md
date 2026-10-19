# DKA_IAPBANK_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IAPBANK_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2541 ; encodage : cp1252 (repli). SHA-256 : `66dcf4f154e9796a617e399f2b3a47d9f0ecfb86645ff87461e16376867c3287`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `historize_file_tmp_gui` | 44 |
| `historize_file_tmp_etab` | 138 |
| `dka_chgt_file_situa_gui` | 235 |
| `dka_chgt_file_situa_etab` | 702 |
| `controle_nbr_enreg_file` | 1150 |
| `controle_coherence_file` | 1214 |
| `verif_end_guichet` | 1716 |
| `dka_date_fin_guichet` | 1795 |
| `simulation_insert_file` | 1841 |
| `delete_save_tables` | 1933 |
| `is_date` | 1952 |
| `main` | 2474 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `dual` | 55 |
| `DKA_IAPBANK_GUI_TMP` | 56 |
| `DKA_IAPBANK_GUI_TMP_HIST` | 66 |
| `DKA_IAPBANK_GUI_TMP` | 113 |
| `dual` | 150 |
| `DKA_IAPBANK_ETAB_TMP` | 151 |
| `DKA_IAPBANK_ETAB_TMP_HIST` | 162 |
| `DKA_IAPBANK_ETAB_TMP` | 209 |
| `fnd_lobs` | 330 |
| `fnd_lobs` | 378 |
| `fnd_lobs` | 388 |
| `DUAL` | 403 |
| `DKA_IAPBANK_GUI_TMP` | 607 |
| `fnd_lobs` | 791 |
| `fnd_lobs` | 838 |
| `fnd_lobs` | 843 |
| `DUAL` | 856 |
| `DKA_IAPBANK_ETAB_TMP` | 1059 |
| `DKA_IAPBANK_ETAB_TMP` | 1165 |
| `DKA_IAPBANK_GUI_TMP` | 1175 |
| `DKA_IAPBANK_ETAB_TMP` | 1241 |
| `DKA_IAPBANK_GUI_TMP` | 1269 |
| `DKA_IAPBANK_ERROR` | 1280 |
| `DKA_IAPBANK_ERROR` | 1332 |
| `DKA_IAPBANK_ERROR` | 1346 |
| `DKA_IAPBANK_ERROR` | 1362 |
| `DKA_IAPBANK_ERROR` | 1378 |
| `DKA_IAPBANK_ERROR` | 1404 |
| `DKA_IAPBANK_ERROR` | 1419 |
| `DKA_IAPBANK_ERROR` | 1435 |
| `DKA_IAPBANK_ERROR` | 1452 |
| `DKA_IAPBANK_ERROR` | 1469 |
| `DKA_IAPBANK_ERROR` | 1485 |
| `DKA_IAPBANK_ERROR` | 1501 |
| `DKA_IAPBANK_ERROR` | 1522 |
| `DKA_IAPBANK_ERROR` | 1538 |
| `DKA_IAPBANK_ERROR` | 1562 |
| `DKA_IAPBANK_ERROR` | 1583 |
| `DKA_IAPBANK_ERROR` | 1607 |
| `DKA_IAPBANK_ERROR` | 1627 |
| `DKA_IAPBANK_ERROR` | 1647 |
| `DKA_IAPBANK_ERROR` | 1667 |
| `DKA_IAPBANK_ERROR` | 1687 |
| `CE_BANK_BRANCHES_V` | 1728 |
| `DKA_IAPBANK_GUI_TMP` | 1737 |
| `DKA_IAPBANK_GUI_TMP` | 1810 |
| `DKA_IAPBANK_GUI_TMP` | 1878 |
| `all_tables` | 1938 |
| `dual` | 1960 |
| `HZ_PARTIES` | 2020 |
| `CE_BANK_BRANCHES_V` | 2032 |
| `IBY_EXT_BANK_ACCOUNTS` | 2086 |
| `dual` | 2141 |
| `hz_parties` | 2167 |
| `hz_contact_points` | 2195 |
| `hz_code_assignments` | 2234 |
| `HZ_PARTY_SITES` | 2270 |
| `DUAL` | 2347 |
| `ar.hz_dqm_sync_interface` | 2458 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 29 |
| `fnd_profile.value` | 30 |
| `fnd_profile.value` | 31 |
| `fnd_gfm.get_file_id` | 314 |
| `fnd_gfm.get_file_id` | 783 |
| `dka_tools_pkg.put_outdebug_message` | 1184 |
| `Dka_Tools_Pkg.get_message` | 1184 |
| `dka_tools_pkg.put_outdebug_message` | 1187 |
| `Dka_Tools_Pkg.get_message` | 1187 |
| `dka_tools_pkg.put_outdebug_message` | 1553 |
| `Dka_Tools_Pkg.get_message` | 1553 |
| `dka_tools_pkg.put_outdebug_message` | 1556 |
| `Dka_Tools_Pkg.get_message` | 1556 |
| `dka_tools_pkg.put_outdebug_message` | 1565 |
| `Dka_Tools_Pkg.get_message` | 1565 |
| `dka_tools_pkg.put_outdebug_message` | 1570 |
| `dka_tools_pkg.put_outdebug_message` | 1577 |
| `Dka_Tools_Pkg.get_message` | 1577 |
| `dka_tools_pkg.put_outdebug_message` | 1586 |
| `Dka_Tools_Pkg.get_message` | 1586 |
| `dka_tools_pkg.put_outdebug_message` | 1591 |
| `dka_tools_pkg.put_outdebug_message` | 1595 |
| `dka_tools_pkg.put_outdebug_message` | 1598 |
| `Dka_Tools_Pkg.get_message` | 1598 |
| `dka_tools_pkg.put_outdebug_message` | 1601 |
| `Dka_Tools_Pkg.get_message` | 1601 |
| `dka_tools_pkg.put_outdebug_message` | 1610 |
| `Dka_Tools_Pkg.get_message` | 1610 |
| `dka_tools_pkg.put_outdebug_message` | 1615 |
| `dka_tools_pkg.put_outdebug_message` | 1621 |
| `Dka_Tools_Pkg.get_message` | 1621 |
| `dka_tools_pkg.put_outdebug_message` | 1630 |
| `Dka_Tools_Pkg.get_message` | 1630 |
| `dka_tools_pkg.put_outdebug_message` | 1635 |
| `dka_tools_pkg.put_outdebug_message` | 1641 |
| `Dka_Tools_Pkg.get_message` | 1641 |
| `dka_tools_pkg.put_outdebug_message` | 1650 |
| `Dka_Tools_Pkg.get_message` | 1650 |
| `dka_tools_pkg.put_outdebug_message` | 1655 |
| `dka_tools_pkg.put_outdebug_message` | 1661 |
| `Dka_Tools_Pkg.get_message` | 1661 |
| `dka_tools_pkg.put_outdebug_message` | 1670 |
| `Dka_Tools_Pkg.get_message` | 1670 |
| `dka_tools_pkg.put_outdebug_message` | 1675 |
| `dka_tools_pkg.put_outdebug_message` | 1681 |
| `Dka_Tools_Pkg.get_message` | 1681 |
| `dka_tools_pkg.put_outdebug_message` | 1690 |
| `Dka_Tools_Pkg.get_message` | 1690 |
| `dka_tools_pkg.put_outdebug_message` | 1695 |
| `iby_ext_bankacct_pub.set_ext_bank_branch_end_date` | 1751 |
| `dka_tools_pkg.put_outdebug_message` | 1761 |
| `Dka_Tools_Pkg.get_message` | 1761 |
| `dka_tools_pkg.put_outdebug_message` | 1763 |
| `Dka_Tools_Pkg.get_message` | 1763 |
| `Dka_Tools_Pkg.get_message` | 1765 |
| `dka_tools_pkg.put_outdebug_message` | 1770 |
| `Dka_Tools_Pkg.get_message` | 1770 |
| `Dka_Tools_Pkg.put_log_message` | 1995 |
| `Dka_Tools_Pkg.put_log_message` | 2008 |
| `Dka_Tools_Pkg.put_log_message` | 2019 |
| `iby_ext_bankacct_pub.check_bank_exist` | 2040 |
| `dka_tools_pkg.put_debug_message` | 2056 |
| `iby_ext_bankacct_pub.check_ext_bank_branch_exist` | 2059 |
| `dka_tools_pkg.put_outdebug_message` | 2093 |
| `Dka_Tools_Pkg.get_message` | 2093 |
| `dka_tools_pkg.put_outdebug_message` | 2095 |
| `Dka_Tools_Pkg.get_message` | 2095 |
| `dka_tools_pkg.put_outdebug_message` | 2111 |
| `iby_ext_bankacct_pub.set_ext_bank_branch_end_date` | 2117 |
| `dka_tools_pkg.put_outdebug_message` | 2127 |
| `Dka_Tools_Pkg.get_message` | 2127 |
| `Dka_Tools_Pkg.get_message` | 2129 |
| `dka_tools_pkg.put_outdebug_message` | 2136 |
| `Dka_Tools_Pkg.get_message` | 2136 |
| `dka_tools_pkg.put_outdebug_message` | 2139 |
| `Dka_Tools_Pkg.get_message` | 2139 |
| `iby_ext_bankacct_pub.set_ext_bank_branch_end_date` | 2143 |
| `dka_tools_pkg.put_outdebug_message` | 2152 |
| `Dka_Tools_Pkg.get_message` | 2152 |
| `Dka_Tools_Pkg.get_message` | 2154 |
| `dka_tools_pkg.put_outdebug_message` | 2172 |
| `iby_ext_bankacct_pub.update_ext_bank` | 2179 |
| `dka_tools_pkg.put_outdebug_message` | 2188 |
| `Dka_Tools_Pkg.get_message` | 2188 |
| `Dka_Tools_Pkg.get_message` | 2190 |
| `dka_tools_pkg.put_outdebug_message` | 2201 |
| `dka_tools_pkg.put_outdebug_message` | 2249 |
| `iby_ext_bankacct_pub.update_ext_bank_branch` | 2254 |
| `dka_tools_pkg.put_outdebug_message` | 2263 |
| `Dka_Tools_Pkg.get_message` | 2263 |
| `Dka_Tools_Pkg.get_message` | 2265 |
| `dka_tools_pkg.put_outdebug_message` | 2275 |
| `hz_location_v2pub.update_location` | 2288 |
| `dka_tools_pkg.put_outdebug_message` | 2296 |
| `Dka_Tools_Pkg.get_message` | 2296 |
| `Dka_Tools_Pkg.get_message` | 2298 |
| `dka_tools_pkg.put_outdebug_message` | 2306 |
| `Dka_Tools_Pkg.get_message` | 2306 |
| `Dka_Tools_Pkg.get_message` | 2308 |
| `dka_tools_pkg.put_outdebug_message` | 2322 |
| `Dka_Tools_Pkg.get_message` | 2322 |
| `dka_tools_pkg.put_outdebug_message` | 2324 |
| `Dka_Tools_Pkg.get_message` | 2324 |
| `dka_tools_pkg.put_outdebug_message` | 2334 |
| `dka_tools_pkg.put_log_message` | 2342 |
| `iby_ext_bankacct_pub.create_ext_bank` | 2353 |
| `dka_tools_pkg.put_outdebug_message` | 2364 |
| `Dka_Tools_Pkg.get_message` | 2364 |
| `Dka_Tools_Pkg.get_message` | 2366 |
| `dka_tools_pkg.put_log_message` | 2369 |
| `iby_ext_bankacct_pub.create_ext_bank_branch` | 2377 |
| `dka_tools_pkg.put_outdebug_message` | 2387 |
| `Dka_Tools_Pkg.get_message` | 2387 |
| `Dka_Tools_Pkg.get_message` | 2389 |
| `dka_tools_pkg.put_log_message` | 2392 |
| `hz_location_v2pub.create_location` | 2405 |
| `dka_tools_pkg.put_outdebug_message` | 2413 |
| `Dka_Tools_Pkg.get_message` | 2413 |
| `Dka_Tools_Pkg.get_message` | 2415 |
| `dka_tools_pkg.put_log_message` | 2417 |
| `hz_party_site_v2pub.create_party_site` | 2424 |
| `dka_tools_pkg.put_outdebug_message` | 2433 |
| `Dka_Tools_Pkg.get_message` | 2433 |
| `Dka_Tools_Pkg.get_message` | 2435 |
| `Dka_Tools_Pkg.put_log_message` | 2437 |
| `dka_tools_pkg.put_outdebug_message` | 2451 |
| `Dka_Tools_Pkg.get_message` | 2451 |
| `Dka_Tools_Pkg.put_log_message` | 2480 |
| `dka_tools_pkg.put_outdebug_message` | 2481 |
| `dka_tools_pkg.put_outdebug_message` | 2482 |
| `dka_tools_pkg.put_outdebug_message` | 2483 |
| `Dka_Tools_Pkg.put_log_message` | 2488 |
| `dka_tools_pkg.put_outdebug_message` | 2492 |
| `dka_tools_pkg.put_outdebug_message` | 2493 |
| `dka_tools_pkg.put_outdebug_message` | 2494 |
| `dka_tools_pkg.put_outdebug_message` | 2495 |
| `Dka_Tools_Pkg.put_log_message` | 2500 |
| `dka_tools_pkg.put_outdebug_message` | 2503 |
| `dka_tools_pkg.put_outdebug_message` | 2504 |
| `dka_tools_pkg.put_outdebug_message` | 2505 |
| `dka_tools_pkg.put_outdebug_message` | 2506 |
| `dka_tools_pkg.put_outdebug_message` | 2512 |
| `dka_tools_pkg.put_outdebug_message` | 2513 |
| `dka_tools_pkg.put_outdebug_message` | 2515 |
| `dka_tools_pkg.put_outdebug_message` | 2517 |
| `dka_tools_pkg.put_outdebug_message` | 2519 |
| `Dka_Tools_Pkg.put_log_message` | 2524 |
| `Dka_Tools_Pkg.put_log_message` | 2531 |
| `Dka_Tools_Pkg.put_log_message` | 2535 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 115, 210, 675, 1125, 1340, 1354, 1370, 1384, 1412, 1427, 1443, 1462, 1477, 1493, 1530, 1546, 1776 |
| rollback | 1781 |
| when_others | 58, 117, 123, 154, 212, 219, 417, 427, 437, 447, 457, 467, 477, 487, 497, 507, 517, 527, 537, 547, 557, 567, 577, 587, 597, 687, 870, 880, 890, 900, 910, 920, 930, 940, 950, 960, 970, 980, 990, 1000, 1010, 1020, 1030, 1040, 1050, 1137, 1167, 1177, 1200, 1359, 1432, 1482, 1519, 1700, 1778, 1815, 1825, 1962, 2110, 2171, 2200, 2248, 2274, 2333, 2460, 2532 |
| suppression | 2458 |
| truncate | 311, 780, 1307 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IAPBANK_CTRL / DKA | `DKA_IAPBANK_PKG.main` | dka/12.0.0/admin/import/DKA_IAPBANK_CTRL.prt:460 |
| DKA_IAPBANK_CTRL / DKA | `DKA_IAPBANK_PKG.main` | dka/12.0.0/admin/import/DKA_IAPBANK_CTRL.prt:460 |
| DKA_IAPBANK_MAJ / DKA | `DKA_IAPBANK_PKG.main` | dka/12.0.0/admin/import/DKA_IAPBANK_MAJ.prt:460 |
| DKA_IAPBANK_MAJ / DKA | `DKA_IAPBANK_PKG.main` | dka/12.0.0/admin/import/DKA_IAPBANK_MAJ.prt:460 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
