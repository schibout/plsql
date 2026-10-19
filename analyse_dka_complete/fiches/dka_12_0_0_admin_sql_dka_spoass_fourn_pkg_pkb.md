# DKA_SPOASS_FOURN_PKG.pkb

Source : [dka/12.0.0/admin/sql/DKA_SPOASS_FOURN_PKG.pkb](../../dka/12.0.0/admin/sql/DKA_SPOASS_FOURN_PKG.pkb).

Famille proposée par convention de nommage : **PO / achats**. Cette étiquette nécessite la lecture fonctionnelle du traitement.

**Nature de la fiche : extraction statique automatique, pas une spécification métier validée.** Les références sont des occurrences dans le texte hors commentaires SQL ; les chaînes et SQL dynamique peuvent créer des faux positifs ou des dépendances manquantes. Aucune exécution du composant.

Lignes : 1320 ; encodage : cp1252 (repli). SHA-256 : `a35930473b92eba6a5f6f288c2ca6c516a9f7aaab27075967981805692e361a5`.

## Sous-programmes déclarés (sur les PKB : inclut privés et doublons déclaration/définition)

| Élément | Ligne source |
|---|---:|
| `main_1` | 55 |
| `writeout` | 194 |
| `get_UO` | 212 |
| `main_2` | 237 |
| `main_3` | 803 |
| `main_4` | 1020 |

## Triggers déclarés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Objets SQL candidats (CTE et alias possibles)

| Élément | Ligne source |
|---|---:|
| `po_vendors` | 82 |
| `po_vendor_sites_all` | 92 |
| `hr_operating_units` | 95 |
| `po_requisition_lines_all` | 99 |
| `po_headers_all` | 103 |
| `ap_invoices_all` | 108 |
| `ap_checks_all` | 113 |
| `hr_operating_units` | 216 |
| `po_vendor_sites_all` | 321 |
| `hr_operating_units` | 324 |
| `ap_invoices_all` | 346 |
| `ap_checks_all` | 351 |
| `po_vendor_sites_all` | 390 |
| `hr_operating_units` | 393 |
| `po_vendor_sites_all` | 407 |
| `hr_operating_units` | 410 |
| `po_vendor_sites_all` | 413 |
| `hr_operating_units` | 416 |
| `po_vendor_sites_all` | 422 |
| `hr_operating_units` | 424 |
| `FND_PROFILE_OPTIONS_VL` | 461 |
| `gl_period_statuses` | 487 |
| `xLA_CONTROL_BALANCES` | 579 |
| `hr_operating_units` | 585 |
| `po_vendors` | 852 |
| `po_vendor_sites_all` | 860 |
| `ap_supplier_sites_all` | 1051 |
| `PER_SECURITY_ORGANIZATIONS` | 1058 |
| `PER_SECURITY_PROFILES` | 1060 |
| `ap_supplier_sites_all` | 1068 |
| `ap_supplier_sites_all` | 1079 |
| `ap_supplier_sites_all` | 1095 |
| `ap_supplier_sites_all` | 1126 |
| `ap_supplier_sites_all` | 1218 |
| `ap_suppliers` | 1252 |
| `ap_supplier_sites_all` | 1289 |
| `ap_supplier_sites_all` | 1301 |

## Références de forme appel package.membre

| Élément | Ligne source |
|---|---:|
| `fnd_profile.value` | 32 |
| `dka_tools_pkg.put_log_message` | 119 |
| `fnd_date.canonical_to_date` | 133 |
| `dka_tools_pkg.put_log_message` | 137 |
| `ap_vendor_pub_pkg.update_Vendor_Site` | 139 |
| `fnd_msg_pub.get` | 158 |
| `Fnd_File.put_line` | 167 |
| `dka_tools_pkg.put_log_message` | 168 |
| `dka_tools_pkg.put_log_message` | 177 |
| `dka_tools_pkg.put_log_message` | 178 |
| `dka_tools_pkg.put_log_message` | 182 |
| `dka_tools_pkg.put_log_message` | 183 |
| `FND_FILE.PUT_LINE` | 199 |
| `dka_tools_pkg.put_log_message` | 500 |
| `dka_tools_pkg.put_log_message` | 501 |
| `dka_tools_pkg.put_log_message` | 504 |
| `dka_tools_pkg.put_log_message` | 505 |
| `dka_tools_pkg.put_log_message` | 569 |
| `dka_tools_pkg.put_log_message` | 574 |
| `dka_tools_pkg.put_log_message` | 587 |
| `ap_vendor_pub_pkg.update_Vendor_Site` | 595 |
| `fnd_msg_pub.get` | 616 |
| `dka_tools_pkg.put_log_message` | 622 |
| `dka_tools_pkg.put_log_message` | 630 |
| `dka_tools_pkg.put_log_message` | 644 |
| `dka_tools_pkg.put_log_message` | 656 |
| `ap_vendor_pub_pkg.update_Vendor_Site` | 658 |
| `fnd_msg_pub.get` | 678 |
| `dka_tools_pkg.put_log_message` | 684 |
| `dka_tools_pkg.put_log_message` | 692 |
| `dka_tools_pkg.put_log_message` | 705 |
| `dka_tools_pkg.put_log_message` | 717 |
| `ap_vendor_pub_pkg.update_Vendor_Site` | 719 |
| `fnd_msg_pub.get` | 740 |
| `dka_tools_pkg.put_log_message` | 746 |
| `dka_tools_pkg.put_log_message` | 756 |
| `dka_tools_pkg.put_log_message` | 765 |
| `dka_tools_pkg.put_log_message` | 774 |
| `dka_tools_pkg.put_log_message` | 775 |
| `dka_tools_pkg.put_log_message` | 783 |
| `dka_tools_pkg.put_log_message` | 784 |
| `dka_tools_pkg.put_log_message` | 926 |
| `dka_tools_pkg.put_log_message` | 939 |
| `ap_vendor_pub_pkg.update_vendor` | 943 |
| `fnd_msg_pub.get` | 963 |
| `dka_tools_pkg.put_log_message` | 975 |
| `dka_tools_pkg.put_log_message` | 989 |
| `dka_tools_pkg.put_log_message` | 990 |
| `dka_tools_pkg.put_log_message` | 997 |
| `dka_tools_pkg.put_log_message` | 998 |
| `dka_tools_pkg.put_log_message` | 1155 |
| `ap_vendor_pub_pkg.update_Vendor_Site` | 1157 |
| `fnd_msg_pub.get` | 1176 |
| `dka_tools_pkg.put_log_message` | 1181 |
| `dka_tools_pkg.put_log_message` | 1203 |
| `ap_vendor_pub_pkg.update_Vendor_Site` | 1205 |
| `fnd_msg_pub.get` | 1230 |
| `dka_tools_pkg.put_log_message` | 1235 |
| `ap_vendor_pub_pkg.update_vendor` | 1241 |
| `fnd_msg_pub.get` | 1264 |
| `dka_tools_pkg.put_log_message` | 1271 |

## Programmes soumis, littéraux détectés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Fichiers référencés

Aucune occurrence détectée ; ne prouve pas une absence fonctionnelle.

## Transactions, erreurs et orchestration

| Marqueur | Lignes |
|---|---|
| commit | 977, 1279 |
| when_others | 179, 469, 503, 780, 994, 1295 |

## Programmes concurrents reliés par définition FND

| Programme | Point d’entrée | Définition |
|---|---|---|
| DKA_SPOFOUR_DESAC / DKA | `DKA_SPOASS_FOURN_PKG.main_3` | dka/12.0.0/admin/import/DKA_SPOFOUR_DESAC.prt:419 |
| DKA_SPOFOUR_NONMV / DKA | `DKA_SPOASS_FOURN_PKG.main_1` | dka/12.0.0/admin/import/DKA_SPOFOUR_NONMV.prt:518 |
| DKA_SPOFOUR_OBS / DKA | `DKA_SPOASS_FOURN_PKG.main_2` | dka/12.0.0/admin/import/DKA_SPOFOUR_OBS.prt:523 |
| DKA_SPOSTFNS_DESACT / DKA | `DKA_SPOASS_FOURN_PKG.main_4` | dka/12.0.0/admin/import/DKA_SPOSTFNS_DESACT.prt:655 |

## À établir par recette / analyse métier

Entrée réelle et propriétaire de données ; paramètres de lancement ; unité de reprise et clés d’idempotence ; effets des commits ; transitions de statut ; résultat métier attendu ; version effectivement déployée. Le silence de l’extracteur ne vaut pas preuve d’absence.
