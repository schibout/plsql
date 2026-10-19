# DKA_IPOGENCOM_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPOGENCOM_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2183 ; encodage : cp1252 (repli). SHA-256 : `94a5511da5900abdfc6e3dea43ce1f55b85757defd1181f5ee395fae09c5cc2f`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `print_log_message` | 73 |
| `recupere_numero_de_commande` | 101 |
| `verifie_existence_commande` | 128 |
| `verifie_approbation_contrat` | 160 |
| `genere_compte_commande` | 191 |
| `insere_entete_commande` | 496 |
| `insere_ligne_commande` | 609 |
| `insere_imputation_commande` | 718 |
| `modification_commande` | 833 |
| `create_line_location` | 1286 |
| `create_po_distribution` | 1442 |
| `insere_historisation_commande` | 1662 |
| `main` | 1770 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_headers_all` | 109 |
| `po_headers_all` | 135 |
| `po_headers_all` | 166 |
| `gl_sets_of_books` | 327 |
| `mtl_categories_kfv` | 332 |
| `po_line_types_all_v` | 337 |
| `dual` | 517 |
| `po_headers_all` | 522 |
| `hr_operating_units` | 531 |
| `gl_ledgers` | 542 |
| `po_headers_interface` | 550 |
| `dual` | 628 |
| `po_headers_all` | 633 |
| `hr_operating_units` | 641 |
| `gl_ledgers` | 651 |
| `mtl_units_of_measure` | 663 |
| `po_lines_interface` | 672 |
| `dual` | 746 |
| `pa_tasks` | 750 |
| `pa_projects_all` | 756 |
| `po_headers_all` | 762 |
| `po_distributions_interface` | 766 |
| `dka_contrat_sstr_imputation` | 884 |
| `dka_contrat_sstr_imputation` | 916 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 929 |
| `DKA_CONTRAT_SSTR_ARCHI` | 953 |
| `DKA_CONTRAT_SSTR` | 956 |
| `DKA_CONTRAT_SSTR` | 967 |
| `po_headers_all` | 1003 |
| `po_headers_archive_all` | 1022 |
| `PO_HEADERS_ALL` | 1045 |
| `PO_HEADERS_ARCHIVE_ALL` | 1053 |
| `PO_HEADERS_ALL` | 1060 |
| `PO_HEADERS_ARCHIVE_ALL` | 1068 |
| `DKA_CONTRAT_SSTR_ARCHI` | 1076 |
| `PO_HEADERS_ALL` | 1079 |
| `DKA_CONTRAT_SSTR` | 1098 |
| `DKA_CONTRAT_SSTR_ARCHI` | 1103 |
| `DKA_CONTRAT_SSTR` | 1108 |
| `po_headers_all` | 1137 |
| `PO_DISTRIBUTIONS_ALL` | 1159 |
| `PO_LINE_LOCATIONS_ALL` | 1174 |
| `po_headers_all` | 1196 |
| `PO_LINES_ALL` | 1249 |
| `po_line_locations_all` | 1309 |
| `po_line_types` | 1316 |
| `po_vendor_sites` | 1323 |
| `dual` | 1329 |
| `po_line_locations_all` | 1333 |
| `po_system_parameters` | 1422 |
| `gl_code_combinations` | 1503 |
| `gl_code_combinations` | 1518 |
| `po_distributions_all` | 1546 |
| `po_line_locations_all` | 1553 |
| `po_distributions_all` | 1567 |
| `PO_ACTION_HISTORY` | 1682 |
| `PO_ACTION_HISTORY` | 1684 |
| `PO_HEADERS_ALL` | 1690 |
| `PO_HEADERS_ALL` | 1696 |
| `PO_ACTION_HISTORY` | 1702 |
| `PO_ACTION_HISTORY` | 1706 |
| `DKA_CONTRAT_SSTR_IMPUTATION` | 1778 |
| `po_headers_all` | 1866 |
| `mtl_categories_kfv` | 1889 |
| `dka_contrat_sstr_imputation` | 1925 |
| `dka_contrat_sstr_imputation` | 1930 |
| `po_headers_all` | 2045 |
| `po_headers_ALL` | 2083 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_file.put_line` | 86 |
| `fnd_profile.VALUE` | 328 |
| `po_wf_build_account_init.start_workflow` | 349 |
| `wf_engine.getitemattrnumber` | 946 |
| `wf_engine.setitemattrnumber` | 972 |
| `wf_engine.setitemattrnumber` | 977 |
| `DKA_SPOCONTRAT_SSTR_PKG.get_ccid` | 1118 |
| `dka_spowfmaster_pkg.get_montant_presta_unit` | 1148 |
| `dka_spowfmaster_pkg.get_montant_presta_unit` | 1150 |
| `dka_spowfmaster_pkg.get_montant_imput` | 1153 |
| `dka_spowfmaster_pkg.get_montant_presta_unit` | 1207 |
| `dka_spowfmaster_pkg.get_montant_presta_unit` | 1209 |
| `dka_spowfmaster_pkg.get_montant_imput` | 1211 |
| `dka_spocontrat_sstr_pkg.get_ccid` | 1483 |
| `Dka_Tools_Pkg.get_code_combination_id` | 1521 |
| `fnd_profile.VALUE` | 1613 |
| `dka_tools_pkg.get_message` | 1830 |
| `dka_tools_pkg.get_message` | 1841 |
| `PO_PDOI_GRP.start_process` | 2053 |
| `dka_tools_pkg.get_message` | 2089 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 2019, 2021, 2078, 2101 |
| when_others | 113, 145, 177, 480, 593, 702, 816, 960, 1031, 1142, 1201, 1262, 1426, 1647, 1750, 2049, 2174 |
| workflow | 946, 972, 977 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
