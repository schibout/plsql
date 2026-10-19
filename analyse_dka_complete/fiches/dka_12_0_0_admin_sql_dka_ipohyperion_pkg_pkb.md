# DKA_IPOHYPERION_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_IPOHYPERION_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1932 ; encodage : cp1252 (repli). SHA-256 : `554a424338cf75ba318654c0a96930cabda9bec60d3af71a7997deb9362fe3b1`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `p_put_debug_message` | 72 |
| `p_put_out_message` | 87 |
| `p_validate` | 104 |
| `p_check_directory` | 128 |
| `f_get_us_periode_name` | 156 |
| `f_get_DKCODE_region` | 184 |
| `p_extract_data` | 212 |
| `p_extract_data` | 630 |
| `p_extract_detail_sstr` | 645 |
| `p_extract_data` | 919 |
| `p_extract_data` | 1062 |
| `output_header` | 1081 |
| `output_end` | 1108 |
| `init_mail` | 1127 |
| `INIT` | 1168 |
| `write_boundary` | 1179 |
| `begin_attachment` | 1195 |
| `end_attachment` | 1236 |
| `envoi_avec_fichier` | 1256 |
| `edition_output_mail` | 1489 |
| `EDITION_OUTPUT_MAIL` | 1582 |
| `p_envoi_mail` | 1600 |
| `EDITION_OUTPUT_MAIL` | 1639 |
| `p_bilan` | 1667 |
| `p_bilan_detail_sstr` | 1717 |
| `main` | 1754 |
| `main_detail_sstr` | 1852 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `all_directories` | 132 |
| `gl_periods` | 168 |
| `dka_stransco_headers` | 190 |
| `po_distributions_all` | 263 |
| `fnd_flex_values` | 271 |
| `ap_invoice_distributions_all` | 278 |
| `po_headers_all` | 307 |
| `po_headers_all` | 331 |
| `po_headers_archive_all` | 338 |
| `dka_contrat_sstr_archi` | 342 |
| `fnd_flex_values` | 361 |
| `po_headers_all` | 407 |
| `po_headers_archive_all` | 419 |
| `DKA_SPO_CONTRAT_SSTR_IVALUA` | 444 |
| `fnd_flex_values` | 479 |
| `gl_periods` | 532 |
| `gl_periods` | 546 |
| `po_headers_all` | 666 |
| `po_headers_all` | 705 |
| `po_headers_archive_all` | 713 |
| `dka_contrat_sstr_archi` | 717 |
| `fnd_flex_values` | 741 |
| `po_headers_all` | 809 |
| `po_headers_archive_all` | 821 |
| `DKA_SPO_CONTRAT_SSTR_IVALUA` | 846 |
| `fnd_flex_values` | 887 |
| `gl_periods` | 938 |
| `gl_periods` | 944 |
| `v$database` | 1148 |
| `fnd_flex_value_sets` | 1280 |
| `all_directories` | 1394 |
| `fnd_flex_values_vl` | 1501 |
| `v$database` | 1518 |
| `fnd_application` | 1523 |
| `fnd_conc_req_summary_v` | 1529 |
| `gl_periods` | 1780 |
| `gl_period_statuses` | 1783 |
| `gl_periods` | 1872 |
| `gl_period_statuses` | 1875 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Fnd_File.put_line` | 91 |
| `DKA_SPOCUT_OFF_PKG.get_charge_theorique_imput` | 324 |
| `DKA_SPOCUT_OFF_PKG.get_charge_theorique_imput` | 327 |
| `DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.get_charge_theorique_imput` | 395 |
| `DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.get_charge_theorique_imput` | 400 |
| `fnd_file.put_line` | 509 |
| `fnd_file.put_line` | 521 |
| `fnd_file.put_line` | 536 |
| `fnd_file.put_line` | 539 |
| `fnd_file.put_line` | 550 |
| `fnd_file.put_line` | 557 |
| `fnd_file.put_line` | 579 |
| `fnd_file.put_line` | 587 |
| `fnd_file.put_line` | 615 |
| `DKA_SPOCUT_OFF_PKG.get_charge_theorique_imput` | 689 |
| `DKA_SPOCUT_OFF_PKG.get_charge_theorique_imput` | 692 |
| `DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.get_charge_theorique_imput` | 787 |
| `DKA_SPOCUT_OFF_SSTR_IVALUA_PKG.get_charge_theorique_imput` | 793 |
| `Dka_Tools_Pkg.put_log_message` | 919 |
| `Dka_Tools_Pkg.put_log_message` | 929 |
| `Dka_Tools_Pkg.put_log_message` | 948 |
| `Dka_Tools_Pkg.put_log_message` | 949 |
| `Dka_Tools_Pkg.put_log_message` | 958 |
| `Dka_Tools_Pkg.put_log_message` | 959 |
| `Dka_Tools_Pkg.put_log_message` | 963 |
| `Dka_Tools_Pkg.put_log_message` | 1055 |
| `Dka_Tools_Pkg.put_log_message` | 1057 |
| `Dka_Tools_Pkg.get_parameter` | 1137 |
| `Dka_Tools_Pkg.get_parameter` | 1150 |
| `Dka_Tools_Pkg.put_log_message` | 1165 |
| `Dka_Tools_Pkg.put_log_message` | 1169 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1292 |
| `Dka_Tools_Pkg.get_message` | 1293 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1299 |
| `Dka_Tools_Pkg.get_message` | 1301 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1307 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1311 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1316 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1319 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1325 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1330 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1336 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1349 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1390 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1398 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1401 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1406 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1421 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1430 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1432 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1439 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1441 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1444 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1446 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1448 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1450 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1452 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1454 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1457 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1458 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1461 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1471 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1475 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1513 |
| `fnd_profile.VALUE` | 1524 |
| `fnd_profile.VALUE` | 1541 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1550 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1552 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1554 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1556 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1563 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1567 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1569 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1571 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1573 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1574 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1577 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1584 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1610 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1614 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1623 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1630 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1636 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1641 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1643 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1646 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1648 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1651 |
| `Dka_Tools_Pkg.Put_Log_Message` | 1653 |
| `Fnd_File.put_line` | 1677 |
| `Fnd_File.put_line` | 1679 |
| `Fnd_File.put_line` | 1681 |
| `Fnd_File.put_line` | 1682 |
| `Fnd_File.put_line` | 1684 |
| `Fnd_File.put_line` | 1686 |
| `Fnd_File.put_line` | 1688 |
| `Fnd_File.put_line` | 1689 |
| `Fnd_File.put_line` | 1691 |
| `Fnd_File.put_line` | 1693 |
| `Fnd_File.put_line` | 1695 |
| `Fnd_File.put_line` | 1699 |
| `Fnd_File.put_line` | 1703 |
| `Fnd_File.put_line` | 1724 |
| `Fnd_File.put_line` | 1726 |
| `Fnd_File.put_line` | 1728 |
| `Fnd_File.put_line` | 1729 |
| `Fnd_File.put_line` | 1731 |
| `Fnd_File.put_line` | 1735 |
| `Fnd_File.put_line` | 1739 |
| `fnd_file.put_line` | 1772 |
| `fnd_file.put_line` | 1798 |
| `fnd_file.put_line` | 1805 |
| `fnd_file.put_line` | 1833 |
| `fnd_file.put_line` | 1838 |
| `Dka_Tools_Pkg.put_log_message` | 1866 |
| `Dka_Tools_Pkg.put_log_message` | 1890 |
| `Dka_Tools_Pkg.put_log_message` | 1896 |
| `fnd_file.put_line` | 1919 |
| `fnd_file.put_line` | 1924 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 628, 1060, 1167, 1473, 1533, 1580, 1650, 1793, 1834, 1885, 1920 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_IPOHYPERION / DKA | `DKA_IPOHYPERION_PKG.main` | dka/12.0.0/admin/import/DKA_IPOHYPERION.prt:418 |
| DKA_IPOHYPERION_DETAIL_SSTR / DKA | `DKA_IPOHYPERION_PKG.main_detail_sstr` | dka/12.0.0/admin/import/DKA_IPOHYPERION_DETAIL_SSTR.prt:418 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
