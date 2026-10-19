# DKA_SPO_REQAPPRV_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPO_REQAPPRV_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPO_REQAPPRV_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 2173 ; encodage : cp1252 (repli). SHA-256 : `cee22071aaf078cd42cf51b12c7d291846b36f55c2d8ab1b25b06920218e6427`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `decode_result` | 23 |
| `get_range_limit_sql` | 50 |
| `get_flex_where_sql` | 60 |
| `check_category_limit` | 94 |
| `check_item_limit` | 212 |
| `check_location_limit` | 330 |
| `get_range_limit_sql` | 444 |
| `check_account_limit` | 638 |
| `get_flex_where_sql` | 754 |
| `get_range_exists_sql` | 898 |
| `check_account_exists` | 1049 |
| `decode_result` | 1167 |
| `check_doc_total_limit` | 1209 |
| `authority_checks_setup` | 1342 |
| `id` | 1559 |
| `authority_check` | 1662 |
| `init_env` | 2020 |
| `GET_NB_APPROVER` | 2045 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_req_distributions_all` | 81 |
| `po_control_rules` | 366 |
| `po_req_distributions_ALL` | 378 |
| `po_control_rules` | 995 |
| `po_control_rules` | 1261 |
| `po_req_distributions_ALL` | 1273 |
| `mtl_default_sets_view` | 1389 |
| `financials_system_params_all` | 1456 |
| `po_requisition_headers_all` | 1460 |
| `PER_ALL_ASSIGNMENTS_F` | 1488 |
| `per_assignment_status_types` | 1495 |
| `PER_ALL_ASSIGNMENTS_F` | 1517 |
| `po_control_functions` | 1549 |
| `po_requisition_headers_all` | 2028 |
| `PO_REQUISITION_HEADERS_ALL` | 2075 |
| `per_jobs` | 2093 |
| `PER_JOBS` | 2135 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `po_calculatereqtotal_pvt.get_req_dist_total` | 73 |
| `PO_LOG.proc_begin` | 118 |
| `PO_LOG.proc_begin` | 119 |
| `PO_LOG.proc_begin` | 120 |
| `PO_LOG.proc_begin` | 121 |
| `PO_LOG.proc_begin` | 122 |
| `PO_LOG.proc_begin` | 123 |
| `PO_LOG.proc_begin` | 124 |
| `PO_LOG.proc_begin` | 125 |
| `PO_LOG.proc_begin` | 126 |
| `PO_LOG.proc_begin` | 127 |
| `PO_LOG.proc_begin` | 128 |
| `PO_LOG.proc_begin` | 129 |
| `PO_LOG.stmt` | 156 |
| `PO_LOG.stmt` | 169 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 181 |
| `PO_LOG.exc` | 183 |
| `PO_LOG.proc_end` | 190 |
| `PO_LOG.proc_end` | 191 |
| `PO_LOG.proc_end` | 192 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 200 |
| `PO_LOG.exc` | 202 |
| `PO_LOG.proc_end` | 203 |
| `PO_LOG.proc_end` | 204 |
| `PO_LOG.proc_begin` | 236 |
| `PO_LOG.proc_begin` | 237 |
| `PO_LOG.proc_begin` | 238 |
| `PO_LOG.proc_begin` | 239 |
| `PO_LOG.proc_begin` | 240 |
| `PO_LOG.proc_begin` | 241 |
| `PO_LOG.proc_begin` | 242 |
| `PO_LOG.proc_begin` | 243 |
| `PO_LOG.proc_begin` | 244 |
| `PO_LOG.proc_begin` | 245 |
| `PO_LOG.proc_begin` | 246 |
| `PO_LOG.proc_begin` | 247 |
| `PO_LOG.stmt` | 274 |
| `PO_LOG.stmt` | 287 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 299 |
| `PO_LOG.exc` | 301 |
| `PO_LOG.proc_end` | 308 |
| `PO_LOG.proc_end` | 309 |
| `PO_LOG.proc_end` | 310 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 318 |
| `PO_LOG.exc` | 320 |
| `PO_LOG.proc_end` | 321 |
| `PO_LOG.proc_end` | 322 |
| `PO_LOG.proc_begin` | 350 |
| `PO_LOG.proc_begin` | 351 |
| `PO_LOG.proc_begin` | 352 |
| `PO_LOG.proc_begin` | 353 |
| `PO_LOG.proc_begin` | 354 |
| `PO_LOG.proc_begin` | 355 |
| `PO_LOG.proc_begin` | 356 |
| `PO_LOG.proc_begin` | 357 |
| `PO_LOG.proc_begin` | 358 |
| `PO_LOG.proc_begin` | 359 |
| `PO_LOG.proc_begin` | 360 |
| `PO_LOG.proc_begin` | 361 |
| `po_calculatereqtotal_pvt.get_req_dist_total` | 370 |
| `PO_LOG.stmt` | 408 |
| `PO_LOG.proc_end` | 421 |
| `PO_LOG.proc_end` | 422 |
| `PO_LOG.proc_end` | 423 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 431 |
| `PO_LOG.exc` | 433 |
| `PO_LOG.proc_end` | 434 |
| `PO_LOG.proc_end` | 435 |
| `PO_LOG.proc_begin` | 474 |
| `PO_LOG.proc_begin` | 475 |
| `PO_LOG.proc_begin` | 476 |
| `PO_LOG.proc_begin` | 477 |
| `PO_LOG.proc_begin` | 478 |
| `PO_LOG.stmt` | 541 |
| `PO_LOG.stmt` | 542 |
| `PO_LOG.stmt` | 543 |
| `PO_LOG.stmt` | 567 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 607 |
| `PO_LOG.exc` | 609 |
| `PO_LOG.proc_end` | 616 |
| `PO_LOG.proc_end` | 617 |
| `PO_LOG.proc_end` | 618 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 626 |
| `PO_LOG.exc` | 628 |
| `PO_LOG.proc_end` | 629 |
| `PO_LOG.proc_end` | 630 |
| `PO_LOG.proc_begin` | 661 |
| `PO_LOG.proc_begin` | 662 |
| `PO_LOG.proc_begin` | 663 |
| `PO_LOG.proc_begin` | 664 |
| `PO_LOG.proc_begin` | 665 |
| `PO_LOG.proc_begin` | 666 |
| `PO_LOG.proc_begin` | 667 |
| `PO_LOG.proc_begin` | 668 |
| `PO_LOG.proc_begin` | 669 |
| `PO_LOG.proc_begin` | 670 |
| `PO_LOG.proc_begin` | 671 |
| `PO_LOG.proc_begin` | 672 |
| `PO_LOG.stmt` | 699 |
| `PO_LOG.stmt` | 712 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 724 |
| `PO_LOG.exc` | 726 |
| `PO_LOG.proc_end` | 733 |
| `PO_LOG.proc_end` | 734 |
| `PO_LOG.proc_end` | 735 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 743 |
| `PO_LOG.exc` | 745 |
| `PO_LOG.proc_end` | 746 |
| `PO_LOG.proc_end` | 747 |
| `PO_LOG.proc_begin` | 784 |
| `PO_LOG.proc_begin` | 785 |
| `PO_LOG.stmt` | 827 |
| `PO_LOG.stmt` | 828 |
| `PO_LOG.stmt` | 829 |
| `PO_LOG.stmt` | 830 |
| `FND_FLEX_KEY_API.set_session_mode` | 836 |
| `FND_FLEX_KEY_API.find_flexfield` | 841 |
| `FND_FLEX_KEY_API.find_structure` | 843 |
| `FND_FLEX_KEY_API.get_segments` | 847 |
| `FND_FLEX_KEY_API.find_segment` | 863 |
| `PO_LOG.proc_end` | 876 |
| `PO_LOG.proc_end` | 877 |
| `PO_LOG.proc_end` | 878 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 886 |
| `PO_LOG.exc` | 888 |
| `PO_LOG.proc_end` | 889 |
| `PO_LOG.proc_end` | 890 |
| `PO_LOG.proc_begin` | 925 |
| `PO_LOG.proc_begin` | 926 |
| `PO_LOG.proc_begin` | 927 |
| `PO_LOG.proc_begin` | 928 |
| `PO_LOG.proc_begin` | 929 |
| `PO_LOG.stmt` | 952 |
| `PO_LOG.stmt` | 953 |
| `PO_LOG.stmt` | 977 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 1017 |
| `PO_LOG.exc` | 1019 |
| `PO_LOG.proc_end` | 1026 |
| `PO_LOG.proc_end` | 1027 |
| `PO_LOG.proc_end` | 1028 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 1036 |
| `PO_LOG.exc` | 1038 |
| `PO_LOG.proc_end` | 1039 |
| `PO_LOG.proc_end` | 1040 |
| `PO_LOG.proc_begin` | 1072 |
| `PO_LOG.proc_begin` | 1073 |
| `PO_LOG.proc_begin` | 1074 |
| `PO_LOG.proc_begin` | 1075 |
| `PO_LOG.proc_begin` | 1076 |
| `PO_LOG.proc_begin` | 1077 |
| `PO_LOG.proc_begin` | 1078 |
| `PO_LOG.proc_begin` | 1079 |
| `PO_LOG.proc_begin` | 1080 |
| `PO_LOG.proc_begin` | 1081 |
| `PO_LOG.proc_begin` | 1082 |
| `PO_LOG.proc_begin` | 1083 |
| `PO_LOG.stmt` | 1110 |
| `PO_LOG.stmt` | 1123 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 1135 |
| `PO_LOG.exc` | 1137 |
| `PO_LOG.proc_end` | 1144 |
| `PO_LOG.proc_end` | 1145 |
| `PO_LOG.proc_end` | 1146 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 1154 |
| `PO_LOG.exc` | 1156 |
| `PO_LOG.proc_end` | 1157 |
| `PO_LOG.proc_end` | 1158 |
| `PO_LOG.proc_begin` | 1179 |
| `PO_LOG.proc_begin` | 1180 |
| `PO_LOG.proc_begin` | 1181 |
| `PO_LOG.proc_end` | 1199 |
| `PO_LOG.proc_end` | 1200 |
| `PO_LOG.proc_begin` | 1230 |
| `PO_LOG.proc_begin` | 1231 |
| `PO_LOG.proc_begin` | 1232 |
| `PO_LOG.proc_begin` | 1233 |
| `PO_LOG.proc_begin` | 1234 |
| `PO_LOG.proc_begin` | 1235 |
| `PO_LOG.proc_begin` | 1236 |
| `PO_LOG.proc_begin` | 1237 |
| `PO_LOG.proc_begin` | 1238 |
| `PO_LOG.proc_begin` | 1239 |
| `PO_LOG.proc_begin` | 1240 |
| `PO_LOG.proc_begin` | 1241 |
| `PO_LOG.stmt` | 1254 |
| `po_calculatereqtotal_pvt.get_req_dist_total` | 1265 |
| `PO_LOG.stmt` | 1308 |
| `PO_LOG.proc_end` | 1320 |
| `PO_LOG.proc_end` | 1321 |
| `PO_LOG.proc_end` | 1322 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 1330 |
| `PO_LOG.exc` | 1332 |
| `PO_LOG.proc_end` | 1333 |
| `PO_LOG.proc_end` | 1334 |
| `PO_LOG.proc_begin` | 1375 |
| `PO_LOG.proc_begin` | 1376 |
| `PO_LOG.proc_begin` | 1377 |
| `PO_LOG.proc_begin` | 1378 |
| `PO_LOG.proc_begin` | 1379 |
| `PO_LOG.proc_begin` | 1380 |
| `PO_LOG.stmt` | 1394 |
| `PO_DOCUMENT_ACTION_UTIL.get_employee_info` | 1402 |
| `fnd_message.get_string` | 1426 |
| `PO_EMPLOYEES_SV.get_employee_name` | 1434 |
| `PO_LOG.stmt` | 1444 |
| `PO_LOG.stmt` | 1445 |
| `PO_LOG.stmt` | 1473 |
| `PO_LOG.stmt` | 1474 |
| `PO_LOG.stmt` | 1475 |
| `PO_LOG.stmt` | 1476 |
| `fnd_message.get_string` | 1505 |
| `fnd_message.get_string` | 1530 |
| `PO_LOG.stmt` | 1539 |
| `PO_LOG.stmt` | 1540 |
| `fnd_message.get_string` | 1560 |
| `PO_LOG.stmt` | 1566 |
| `PO_LOG.stmt` | 1616 |
| `PO_LOG.stmt` | 1617 |
| `PO_LOG.stmt` | 1618 |
| `PO_LOG.stmt` | 1619 |
| `PO_LOG.stmt` | 1620 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 1627 |
| `PO_LOG.exc` | 1629 |
| `PO_LOG.stmt` | 1632 |
| `PO_LOG.proc_end` | 1639 |
| `PO_LOG.proc_end` | 1640 |
| `PO_LOG.proc_end` | 1641 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 1649 |
| `PO_LOG.exc` | 1651 |
| `PO_LOG.proc_end` | 1652 |
| `PO_LOG.proc_end` | 1653 |
| `PO_LOG.proc_begin` | 1687 |
| `PO_LOG.proc_begin` | 1688 |
| `PO_LOG.proc_begin` | 1689 |
| `PO_LOG.proc_begin` | 1690 |
| `PO_LOG.proc_begin` | 1691 |
| `PO_LOG.proc_begin` | 1692 |
| `fnd_message.get_string` | 1775 |
| `PO_LOG.stmt` | 1781 |
| `fnd_message.get_string` | 1811 |
| `PO_LOG.stmt` | 1817 |
| `fnd_message.get_string` | 1841 |
| `PO_LOG.stmt` | 1847 |
| `fnd_message.get_string` | 1877 |
| `PO_LOG.stmt` | 1883 |
| `fnd_message.get_string` | 1913 |
| `PO_LOG.stmt` | 1919 |
| `fnd_message.get_string` | 1949 |
| `PO_LOG.stmt` | 1955 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 1965 |
| `PO_LOG.exc` | 1967 |
| `PO_LOG.stmt` | 1971 |
| `PO_LOG.proc_end` | 1989 |
| `PO_LOG.proc_end` | 1990 |
| `PO_LOG.proc_end` | 1991 |
| `PO_LOG.proc_end` | 1992 |
| `PO_DOCUMENT_ACTION_PVT.error_msg_append` | 2001 |
| `PO_LOG.exc` | 2003 |
| `PO_LOG.proc_end` | 2004 |
| `PO_LOG.proc_end` | 2005 |
| `PO_LOG.stmt` | 2067 |
| `PO_LOG.stmt` | 2120 |
| `PO_LOG.stmt` | 2121 |
| `PO_LOG.stmt` | 2122 |
| `PO_LOG.stmt` | 2123 |
| `PO_LOG.stmt` | 2124 |
| `PO_LOG.stmt` | 2125 |
| `PO_LOG.stmt` | 2163 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 198, 316, 429, 624, 741, 884, 1034, 1152, 1328, 1647, 1998, 2084, 2100, 2151, 2161 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
