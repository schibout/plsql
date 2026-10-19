# DKA_SPOWFAG_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOWFAG_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOWFAG_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1903 ; encodage : cp1252 (repli). SHA-256 : `508f0b582940aa3be0843e07f6383aa6fe2019cce49d2404f0934b5afa3049f1`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `get_po_cp_segment3_value` | 78 |
| `get_po_cp_segment5_value` | 175 |
| `get_po_eca_segment1_value` | 354 |
| `get_po_eca_segment2_value` | 559 |
| `get_po_eca_segment3_value` | 761 |
| `get_po_eca_segment4_value` | 916 |
| `get_po_eca_segment5_value` | 1064 |
| `get_po_eca_segment6_value` | 1250 |
| `get_po_eca_segment7_value` | 1364 |
| `get_po_eca_segment8_value` | 1456 |
| `get_po_eca_segment9_value` | 1540 |
| `get_po_eca_segment10_value` | 1609 |
| `get_po_eca_segment11_value` | 1669 |
| `get_po_eca_segment12_value` | 1727 |
| `is_po_project_related` | 1784 |
| `is_project_type_invest` | 1819 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `hr_all_organization_units` | 483 |
| `hr_all_organization_units` | 700 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `PO_WF_DEBUG_PKG.insert_debug` | 91 |
| `wf_engine.GetItemAttrText` | 102 |
| `PO_WF_DEBUG_PKG.insert_debug` | 107 |
| `PO_WF_DEBUG_PKG.insert_debug` | 119 |
| `fnd_message.set_name` | 123 |
| `wf_engine.SetItemAttrText` | 124 |
| `wf_engine.SetItemAttrText` | 134 |
| `PO_WF_DEBUG_PKG.insert_debug` | 141 |
| `wf_core.context` | 150 |
| `PO_WF_DEBUG_PKG.insert_debug` | 191 |
| `wf_engine.GetItemAttrNumber` | 205 |
| `PO_WF_DEBUG_PKG.insert_debug` | 283 |
| `PO_WF_DEBUG_PKG.insert_debug` | 288 |
| `dka_spaautoaccounting_pkg.get_interco_fourn_f` | 294 |
| `PO_WF_DEBUG_PKG.insert_debug` | 297 |
| `fnd_message.set_name` | 304 |
| `wf_engine.SetItemAttrText` | 305 |
| `wf_engine.SetItemAttrText` | 314 |
| `PO_WF_DEBUG_PKG.insert_debug` | 321 |
| `wf_core.context` | 330 |
| `PO_WF_DEBUG_PKG.insert_debug` | 371 |
| `fnd_profile.value` | 417 |
| `wf_engine.GetItemAttrNumber` | 423 |
| `fnd_message.set_name` | 434 |
| `wf_engine.SetItemAttrText` | 435 |
| `PO_WF_DEBUG_PKG.insert_debug` | 497 |
| `fnd_message.set_name` | 501 |
| `wf_engine.SetItemAttrText` | 502 |
| `wf_engine.SetItemAttrText` | 520 |
| `PO_WF_DEBUG_PKG.insert_debug` | 527 |
| `wf_core.context` | 536 |
| `PO_WF_DEBUG_PKG.insert_debug` | 577 |
| `fnd_profile.value` | 627 |
| `wf_engine.GetItemAttrNumber` | 633 |
| `fnd_message.set_name` | 644 |
| `wf_engine.SetItemAttrText` | 645 |
| `PO_WF_DEBUG_PKG.insert_debug` | 705 |
| `fnd_message.set_name` | 710 |
| `wf_engine.SetItemAttrText` | 711 |
| `wf_engine.SetItemAttrText` | 725 |
| `PO_WF_DEBUG_PKG.insert_debug` | 731 |
| `wf_core.context` | 740 |
| `PO_WF_DEBUG_PKG.insert_debug` | 778 |
| `wf_engine.GetItemAttrNumber` | 791 |
| `PO_WF_DEBUG_PKG.insert_debug` | 796 |
| `fnd_message.set_name` | 800 |
| `wf_engine.SetItemAttrText` | 801 |
| `wf_engine.GetItemAttrText` | 813 |
| `PO_WF_DEBUG_PKG.insert_debug` | 819 |
| `fnd_message.set_name` | 823 |
| `wf_engine.SetItemAttrText` | 824 |
| `wf_engine.GetItemAttrNumber` | 836 |
| `PO_WF_DEBUG_PKG.insert_debug` | 841 |
| `fnd_message.set_name` | 845 |
| `wf_engine.SetItemAttrText` | 846 |
| `DKA_SPAAUTOACCOUNTING_PKG.cpt_local_couts` | 858 |
| `PO_WF_DEBUG_PKG.insert_debug` | 863 |
| `fnd_message.set_name` | 868 |
| `wf_engine.SetItemAttrText` | 869 |
| `wf_engine.SetItemAttrText` | 878 |
| `PO_WF_DEBUG_PKG.insert_debug` | 884 |
| `wf_core.context` | 893 |
| `PO_WF_DEBUG_PKG.insert_debug` | 935 |
| `wf_engine.GetItemAttrNumber` | 949 |
| `wf_engine.GetItemAttrText` | 984 |
| `wf_engine.GetItemAttrNumber` | 990 |
| `dka_spaautoaccounting_pkg.run_cpt_groupe_couts_f` | 1007 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1014 |
| `fnd_message.set_name` | 1019 |
| `wf_engine.SetItemAttrText` | 1020 |
| `wf_engine.SetItemAttrText` | 1029 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1035 |
| `wf_core.context` | 1044 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1080 |
| `wf_engine.GetItemAttrNumber` | 1093 |
| `wf_engine.GetItemAttrNumber` | 1100 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1178 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1183 |
| `dka_spaautoaccounting_pkg.code_interco` | 1189 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1194 |
| `fnd_message.set_name` | 1201 |
| `wf_engine.SetItemAttrText` | 1202 |
| `wf_engine.SetItemAttrText` | 1211 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1218 |
| `wf_core.context` | 1227 |
| `wf_engine.GetItemAttrNumber` | 1280 |
| `dka_spaautoaccounting_pkg.centrefi` | 1317 |
| `fnd_message.set_name` | 1321 |
| `wf_engine.SetItemAttrText` | 1322 |
| `wf_engine.SetItemAttrText` | 1329 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1335 |
| `wf_core.context` | 1343 |
| `wf_engine.GetItemAttrNumber` | 1392 |
| `dka_spaautoaccounting_pkg.affaire` | 1405 |
| `fnd_message.set_name` | 1410 |
| `wf_engine.SetItemAttrText` | 1411 |
| `wf_engine.SetItemAttrText` | 1420 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1426 |
| `wf_core.context` | 1435 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1469 |
| `wf_engine.GetItemAttrNumber` | 1481 |
| `dka_spaautoaccounting_pkg.projetfi` | 1487 |
| `fnd_message.set_name` | 1492 |
| `wf_engine.SetItemAttrText` | 1493 |
| `wf_engine.SetItemAttrText` | 1502 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1508 |
| `wf_core.context` | 1517 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1553 |
| `wf_engine.GetItemAttrNumber` | 1565 |
| `dka_spaautoaccounting_pkg.flux` | 1571 |
| `wf_engine.SetItemAttrText` | 1573 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1579 |
| `wf_core.context` | 1586 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1624 |
| `wf_engine.SetItemAttrText` | 1634 |
| `wf_core.context` | 1646 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1684 |
| `wf_engine.SetItemAttrText` | 1694 |
| `wf_core.context` | 1704 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1742 |
| `wf_engine.SetItemAttrText` | 1752 |
| `wf_core.context` | 1763 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1796 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1836 |
| `wf_engine.GetItemAttrNumber` | 1849 |
| `dka_spaautoaccounting_pkg.get_project_type_f` | 1860 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1880 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1888 |
| `PO_WF_DEBUG_PKG.insert_debug` | 1890 |
| `WF_CORE.context` | 1892 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| when_others | 149, 329, 535, 739, 892, 1043, 1226, 1342, 1434, 1516, 1585, 1645, 1703, 1762, 1885 |
| workflow | 94, 95, 102, 124, 134, 194, 195, 205, 305, 314, 374, 375, 423, 435, 502, 520, 581, 583, 633, 645, 711, 725, 781, 783, 791, 801, 813, 824, 836, 846, 869, 878, 938, 940, 949, 984, 990, 1020, 1029, 1083, 1084, 1093, 1100, 1202, 1211, 1270, 1272, 1280, 1322, 1329, 1382, 1384, 1392, 1411, 1420, 1472, 1473, 1481, 1493, 1502, 1556, 1557, 1565, 1573, 1627, 1628, 1634, 1687, 1688, 1694, 1745, 1746, 1752, 1841, 1842, 1849, 1854, 1865, 1872, 1874 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
