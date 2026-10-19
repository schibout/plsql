# DKA_APFRSEXP_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_APFRSEXP_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_APFRSEXP_PKG.pkb).

Famille proposée par convention de nommage : **AP / fournisseurs**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1755 ; encodage : cp1252 (repli). SHA-256 : `8f891fcf97b0f8008bdef3ee006694c0163036dd338afdc5436083f70c46e706`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `Export_journalier` | 43 |
| `MAIN` | 175 |
| `Export_mensuel` | 1252 |
| `MAIN` | 1330 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `ap_supplier_sites_all` | 102 |
| `IBY_EXT_PAYEE_RELATIONSHIPS` | 108 |
| `po_vendors` | 124 |
| `ap_supplier_sites_all` | 134 |
| `po_vendor_contacts` | 143 |
| `IBY_EXT_PAYEE_RELATIONSHIPS` | 150 |
| `gl_code_combinations` | 247 |
| `gl_code_combinations` | 249 |
| `iby_ext_payee_relationships` | 257 |
| `hr_operating_units` | 261 |
| `ap_supplier_sites_all` | 265 |
| `hz_contact_points` | 287 |
| `hz_contact_points` | 305 |
| `hz_contact_points` | 323 |
| `po_vendor_contacts` | 447 |
| `ap_supplier_contacts` | 489 |
| `ap_supplier_sites_all` | 497 |
| `iby_ext_payee_relationships` | 501 |
| `ap_suppliers` | 506 |
| `gl_code_combinations` | 548 |
| `gl_code_combinations` | 550 |
| `iby_ext_payee_relationships` | 558 |
| `hr_operating_units` | 562 |
| `ap_supplier_sites_all` | 566 |
| `hz_contact_points` | 588 |
| `hz_contact_points` | 606 |
| `hz_contact_points` | 624 |
| `IBY_EXT_PAYEE_RELATIONSHIPS` | 644 |
| `ap_supplier_sites_all` | 751 |
| `iby_ext_payee_relationships` | 755 |
| `ap_suppliers` | 759 |
| `po_vendor_contacts` | 774 |
| `ap_supplier_contacts` | 817 |
| `gl_code_combinations` | 861 |
| `gl_code_combinations` | 863 |
| `iby_ext_payee_relationships` | 871 |
| `hr_operating_units` | 875 |
| `ap_supplier_sites_all` | 879 |
| `hz_contact_points` | 901 |
| `hz_contact_points` | 919 |
| `hz_contact_points` | 936 |
| `po_vendor_contacts` | 966 |
| `ap_supplier_sites_all` | 1053 |
| `iby_ext_payee_relationships` | 1057 |
| `ap_suppliers` | 1061 |
| `po_vendor_contacts` | 1076 |
| `ap_supplier_contacts` | 1130 |
| `po_vendors` | 1305 |
| `gl_code_combinations` | 1404 |
| `gl_code_combinations` | 1406 |
| `iby_ext_payee_relationships` | 1414 |
| `hr_operating_units` | 1418 |
| `ap_supplier_sites_all` | 1422 |
| `hz_contact_points` | 1444 |
| `hz_contact_points` | 1462 |
| `hz_contact_points` | 1480 |
| `po_vendor_contacts` | 1603 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 165 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 166 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 167 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 168 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 169 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 170 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 179 |
| `Dka_Tools_Pkg.put_log_message` | 194 |
| `Dka_Tools_Pkg.put_log_message` | 208 |
| `Dka_Tools_Pkg.put_log_message` | 216 |
| `Dka_Tools_Pkg.put_log_message` | 222 |
| `Dka_Tools_Pkg.put_log_message` | 363 |
| `Dka_Tools_Pkg.put_log_message` | 367 |
| `Dka_Tools_Pkg.put_log_message` | 375 |
| `Dka_Tools_Pkg.put_log_message` | 379 |
| `Dka_Tools_Pkg.put_log_message` | 387 |
| `Dka_Tools_Pkg.put_log_message` | 460 |
| `Dka_Tools_Pkg.put_log_message` | 469 |
| `Dka_Tools_Pkg.put_log_message` | 473 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 519 |
| `Dka_Tools_Pkg.put_log_message` | 678 |
| `Dka_Tools_Pkg.put_log_message` | 682 |
| `Dka_Tools_Pkg.put_log_message` | 690 |
| `Dka_Tools_Pkg.put_log_message` | 694 |
| `Dka_Tools_Pkg.put_log_message` | 702 |
| `Dka_Tools_Pkg.put_log_message` | 788 |
| `Dka_Tools_Pkg.put_log_message` | 797 |
| `Dka_Tools_Pkg.put_log_message` | 801 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 836 |
| `Dka_Tools_Pkg.put_log_message` | 981 |
| `Dka_Tools_Pkg.put_log_message` | 985 |
| `Dka_Tools_Pkg.put_log_message` | 993 |
| `Dka_Tools_Pkg.put_log_message` | 997 |
| `Dka_Tools_Pkg.put_log_message` | 1004 |
| `Dka_Tools_Pkg.put_log_message` | 1090 |
| `Dka_Tools_Pkg.put_log_message` | 1099 |
| `Dka_Tools_Pkg.put_log_message` | 1103 |
| `Dka_Tools_Pkg.put_log_message` | 1111 |
| `Dka_Tools_Pkg.put_log_message` | 1115 |
| `Dka_Tools_Pkg.put_log_message` | 1143 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1151 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1153 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1172 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1180 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1183 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1185 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1192 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1197 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1202 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1207 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1212 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1217 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1222 |
| `Dka_Tools_Pkg.put_debug_message` | 1228 |
| `Dka_Tools_Pkg.put_debug_message` | 1229 |
| `Dka_Tools_Pkg.put_debug_message` | 1230 |
| `Dka_Tools_Pkg.put_debug_message` | 1231 |
| `Dka_Tools_Pkg.put_debug_message` | 1232 |
| `Dka_Tools_Pkg.put_debug_message` | 1233 |
| `Dka_Tools_Pkg.put_debug_message` | 1234 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1235 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1236 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1237 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1318 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1319 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1320 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1321 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1322 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1323 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1324 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1325 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1336 |
| `Dka_Tools_Pkg.put_log_message` | 1351 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1364 |
| `Dka_Tools_Pkg.put_log_message` | 1371 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1379 |
| `Dka_Tools_Pkg.put_log_message` | 1520 |
| `Dka_Tools_Pkg.put_log_message` | 1524 |
| `Dka_Tools_Pkg.put_log_message` | 1532 |
| `Dka_Tools_Pkg.put_log_message` | 1536 |
| `Dka_Tools_Pkg.put_log_message` | 1543 |
| `Dka_Tools_Pkg.put_log_message` | 1616 |
| `Dka_Tools_Pkg.put_log_message` | 1625 |
| `Dka_Tools_Pkg.put_log_message` | 1629 |
| `Dka_Tools_Pkg.put_log_message` | 1654 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1661 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1663 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1682 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1690 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1693 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1695 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1702 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1707 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1712 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1717 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1722 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1727 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1732 |
| `Dka_Tools_Pkg.put_debug_message` | 1737 |
| `Dka_Tools_Pkg.put_debug_message` | 1738 |
| `Dka_Tools_Pkg.put_debug_message` | 1739 |
| `Dka_Tools_Pkg.put_debug_message` | 1740 |
| `Dka_Tools_Pkg.put_debug_message` | 1741 |
| `Dka_Tools_Pkg.put_debug_message` | 1742 |
| `Dka_Tools_Pkg.put_debug_message` | 1743 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1744 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1745 |
| `Dka_Tools_Pkg.Put_Outdebug_Message` | 1746 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 1158, 1668 |
| rollback | 1238, 1747 |
| when_others | 1223, 1733 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_APFRSEXP_JOUR / DKA | `DKA_APFRSEXP_PKG.Export_journalier` | dka/12.0.0/admin/import/DKA_APFRSEXP_JOUR.prt:419 |
| DKA_APFRSEXP_MENS / DKA | `DKA_APFRSEXP_PKG.Export_mensuel` | dka/12.0.0/admin/import/DKA_APFRSEXP_MENS.prt:482 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
